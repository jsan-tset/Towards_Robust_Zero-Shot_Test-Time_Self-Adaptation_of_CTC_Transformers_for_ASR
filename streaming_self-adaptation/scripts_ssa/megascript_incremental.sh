#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

INI_TIME=$(date +%s.%N)

ii(){
    echo "[ii] - $1"
}
iii(){
    echo "  \`-> $1"
}
METHOD=incremental

if [[ $# != 8 ]]
then
    echo "$0 <model> <rank> <max_epoch_per_ft> <lr> <chunk_size> <sample:wav> <out_dir> <language>"
    exit 1
fi

MODEL=$1
LORA_RANK=$2
LORA_ALPHA=$((LORA_RANK * 2))
EPOCH=$3
LR=$4
CHUNK_SIZE=$5
FILE=$6
OUTDIR=$7
LANG=$8

if [[ $OUTDIR == "" ]]
then
    OUTDIR="."
fi

# Params
CONTEXT_LEN=4
CONTEXT_L=4
CONTEXT_R=4

ITER=0

VMOD=$(echo $MODEL | awk -F'_' '{print $3}')
SPL_NAME=$(basename $FILE .wav)
EXP_NAME=$METHOD.$VMOD.ep$EPOCH.chsize$CHUNK_SIZE.lr$LR.r$LORA_RANK.$SPL_NAME
CONF_FILE=conf/ft_owsm_ctc_lora_minim.yaml
LOG_FILE=$EXP_NAME.$METHOD.log

# Directories
DIR_COMM=$METHOD.$VMOD/ep$EPOCH.chsize$CHUNK_SIZE.lr$LR.r$LORA_RANK
DIR_AUDIO_CHUNK=$OUTDIR/chunked_audio/$DIR_COMM
DIR_ADAPT_HYP=$OUTDIR/out_txt_adapt/$DIR_COMM
DIR_CSV=$OUTDIR/csv_adapt/$DIR_COMM/$SPL_NAME
DIR_HYP=$OUTDIR/out_hyp/$DIR_COMM/$SPL_NAME
DIR_EXP=$OUTDIR/exps/$DIR_COMM/$SPL_NAME; mkdir -p $DIR_EXP
DIR_LST=$OUTDIR/lists/$DIR_COMM; mkdir -p $DIR_LST
DIR_LOG=$OUTDIR/logs/$DIR_COMM; mkdir -p $DIR_LOG

DBG=false

{
# Step 0 - Delete previous experiment, if exist
if [[ -d $DIR_EXP ]]
then
    rm -rf $DIR_EXP
    mkdir -p $DIR_EXP
    rm -rf $DIR_CSV 
fi

# Step 0.5 -> If file_duration <= chunk_size --> only reco
#
SPL_DUR=$(soxi -D $FILE)
if [ $(echo "$SPL_DUR <= $CHUNK_SIZE" | bc) -eq 1 ]; then
	ii "S0.5 Reco full sample: $FIRST_CHUNK"
	iii "Using base model"
	#ACTUAL_CHUNK=$(head -n1 $DIR_LST/$SPL_NAME/${SPL_NAME}_chunked_audios.lst)
	#CHUNK_NAME=$(basename $ACTUAL_CHUNK .wav)
	if ! $DBG; then
	scripts/s01_batched_inference_first_chunk.sh $FILE \
						     $DIR_ADAPT_HYP \
						     $DIR_HYP \
						     $MODEL \
						     $CONTEXT_LEN \
						     0 \
						     0 \
						     $LANG
	fi
else # almost all the script



# Step 1 - Chop samples
# New data:
#  - audios of CHUNK_SIZE size
#  - list of chunked audios at DIR_LST/SPL/SPL_chunked_audios.lst
ii "S01 Choping files"
if ! $DBG; then
scripts/s00_chop_samples.sh $FILE \
                            $CHUNK_SIZE \
                            $CONTEXT_L \
                            $CONTEXT_R \
                            $DIR_AUDIO_CHUNK \
                            $DIR_LST
fi

# Step 2 - Reco first chunk
# New data:
#  - chunk transcription at DIR_HYP
#  - segmented chunk transcription (for training) at DIR_ADAPT_HYP
ii "S02 Reco first chunk: $FIRST_CHUNK"
iii "Using base model"
ACTUAL_CHUNK=$(head -n1 $DIR_LST/$SPL_NAME/${SPL_NAME}_chunked_audios.lst)
CHUNK_NAME=$(basename $ACTUAL_CHUNK .wav)
if ! $DBG; then
scripts/s01_batched_inference_first_chunk.sh $ACTUAL_CHUNK \
                                             $DIR_ADAPT_HYP \
                                             $DIR_HYP \
                                             $MODEL \
                                             $CONTEXT_LEN \
                                             0 \
                                             $CONTEXT_R \
					     $LANG
fi

# Step 3 - Prepare CSV for train
# New data:
#  - segmented audios for the given chunk
#  - csv for adapta at DIR_CSV/SPL
ii "S03 Preparing first chunk CSV for adaptation"
if ! $DBG; then
scripts/s02_subchop_and_prepare_adapt_csv.sh $ACTUAL_CHUNK \
                                             $CONTEXT_LEN \
                                             $DIR_ADAPT_HYP \
                                             $DIR_CSV
fi

# Step 4 - Adapt model with first chunk data
# New data:
#  - checkpoints at DIR_EXP/CHUNK_NAME/finetune/Xepoch.pth
ii "S04 Adapt model with first chunk"
if ! $DBG; then
scripts/s03_ft_with_chunk.sh $DIR_CSV/$SPL_NAME/$CHUNK_NAME.csv \
                             $DIR_CSV/$SPL_NAME/$CHUNK_NAME.csv \
                             $DIR_EXP/$CHUNK_NAME \
                             $MODEL \
                             $LR $LORA_RANK $LORA_ALPHA \
                             $EPOCH \
                             $CONF_FILE \
			     $LANG
fi
if [[ $EPOCH -gt 1 ]]
then
    iii "Delete innecesari checkpoints"
    scripts/del_extra_chkp.sh $DIR_EXP/$CHUNK_NAME $EPOCH
fi

echo "STARTING ITERATIVE"
PREV_CHUNK_NAME=$CHUNK_NAME
for CHUNK in $(tail -n+2 $DIR_LST/$SPL_NAME/${SPL_NAME}_chunked_audios.lst | head -n-1)
do
    ACTUAL_CHUNK=$CHUNK
    CHUNK_NAME=$(basename $ACTUAL_CHUNK .wav)
    ITER=$((ITER + 1))
    ii "Iteration $ITER"

    # Step 5 - Reco chunk with adapted model
    # New data:
    #  - chunk transcription at DIR_HYP
    #  - segmented chunk transcription (for training) at DIR_ADAPT_HYP
    ii "S05 Reco chunk with adapted model"
    iii "Using prev ${EPOCH}epoch.pth"
    if ! $DBG; then
    scripts/s04_reco_with_ft_chunk.sh $ACTUAL_CHUNK \
                                      $DIR_EXP/$PREV_CHUNK_NAME/finetune/${EPOCH}epoch.pth \
                                      $DIR_ADAPT_HYP \
                                      $DIR_HYP \
                                      $MODEL \
                                      $LORA_RANK $LORA_ALPHA \
                                      $CONTEXT_LEN \
                                      $CONTEXT_L \
                                      $CONTEXT_R \
				      $LANG
    fi

    # Step 6 - Prepare CSV for train
    # New data:
    #  - segmented audios for the given chunk
    #  - list of segmented audios at DIR_LST/SPL/SPL_<T_INI>-<T_END>_segmented_audios.lst
    #  - csv for adapta at DIR_CSV/SPL
    ii "S06 Preparing new-chunk CSV for adaptation"
    if ! $DBG; then
    scripts/s02_subchop_and_prepare_adapt_csv.sh $ACTUAL_CHUNK \
                                                 $CONTEXT_LEN \
                                                 $DIR_ADAPT_HYP \
                                                 $DIR_CSV
    iii "Merging CSVs into incremental.csv"
    cat $DIR_CSV/$SPL_NAME/$SPL_NAME* > $DIR_CSV/$SPL_NAME/incremental_iter$ITER.csv
    fi

    # Step 7 - Adapt model with new chunk data
    # New data:
    #  - checkpoints at DIR_EXP/CHUNK_NAME/finetune/Xepoch.pth
    ii "S07 Adapt model with new chunk"
    iii "Objective ${EPOCH}epoch.pth"
    if ! $DBG; then
    scripts/s03_ft_with_chunk.sh $DIR_CSV/$SPL_NAME/incremental_iter$ITER.csv \
                                 $DIR_CSV/$SPL_NAME/incremental_iter$ITER.csv \
                                 $DIR_EXP/$CHUNK_NAME \
                                 $MODEL \
                                 $LR $LORA_RANK $LORA_ALPHA \
                                 $EPOCH \
                                 $CONF_FILE \
				 $LANG
    fi
    if [[ $EPOCH -gt 1 ]]
    then
        iii "Delete innecesari checkpoints"
        scripts/del_extra_chkp.sh $DIR_EXP/$CHUNK_NAME $EPOCH
    fi

    PREV_CHUNK_NAME=$CHUNK_NAME
done

# CHECK IF THERE IS MORE THAN ONE CHUNK (SAMPLE LENGTH < CHUNK_SIZE)
if [[ $(wc -l < $DIR_LST/$SPL_NAME/${SPL_NAME}_chunked_audios.lst) -gt 1 ]]
then
    ITER=$((ITER + 1))
    ACTUAL_CHUNK=$(tail -n1 $DIR_LST/$SPL_NAME/${SPL_NAME}_chunked_audios.lst)
    CHUNK_NAME=$(basename $ACTUAL_CHUNK .wav)
    ii "Iteration $ITER. FINAL"

    # Step 5 - Reco chunk with adapted model
    # New data:
    #  - chunk transcription at DIR_HYP
    #  - segmented chunk transcription (for training) at DIR_ADAPT_HYP
    ii "S08 Reco last chunk with adapted model."
    if ! $DBG; then
    scripts/s04_reco_with_ft_chunk.sh $ACTUAL_CHUNK \
                                      $DIR_EXP/$PREV_CHUNK_NAME/finetune/${EPOCH}epoch.pth \
                                      $DIR_ADAPT_HYP \
                                      $DIR_HYP \
                                      $MODEL \
                                      $LORA_RANK $LORA_ALPHA \
                                      $CONTEXT_LEN \
                                      $CONTEXT_L \
                                      0 \
				      $LANG
    fi

#else
#   # Nothing!
fi
fi

ii "Collapsing hypothesis..."
#cat $DIR_HYP/*.txt > $DIR_HYP/full.hyp
awk '{printf("%s ",$0)} END {print ""}' $DIR_HYP/*.txt > $DIR_HYP/full.hyp
scripts/postprohyp.sh $DIR_HYP/full.hyp

ii "Deleting chunks dir to optimize space"
find $DIR_AUDIO_CHUNK -type d -name $SPL_NAME |
    while read l
    do
        rm -r $l
    done

echo "That's all, folks!"
printf  "EXECUTION TIME: %.2f s\n" $(echo "$(date +%s.%N) - $INI_TIME" | bc)

} > $DIR_LOG/$LOG_FILE
