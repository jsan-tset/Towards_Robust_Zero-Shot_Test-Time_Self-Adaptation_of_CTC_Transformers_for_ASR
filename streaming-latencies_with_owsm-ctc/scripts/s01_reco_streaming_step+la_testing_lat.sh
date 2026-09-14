#!/bin/bash

set -e

export LC_ALL=C.UTF-8

mkdir -p logs

LANG="eng"
cat <<EOF |
0.56 0.40
0.56 0.48
EOF
while read STEP LA
do
for TASK in LHCP-2020 
do
for SET in dev #test
do
LLA_SHIFT=0.0
for WAV in `<lhcp-lists/audios_${TASK}_$SET.lst`
do

for MODEL in "espnet/owsm_ctc_v4_1B"
do
VMOD=$(echo $MODEL | awk -F'_' '{print $3}')

    SAMPLE=$(basename $WAV .wav)
    NAME=reco.${VMOD}.STEP$STEP.LA$LA.LLA_SHIFT$LLA_SHIFT
    NAMESPL=$NAME.$SAMPLE
    ODIR_HYP=out_hyp_lat/$TASK.$SET/$NAME
    BUFFER_SIZE=0.1


    if [[ ! -e $ODIR_HYP/$SAMPLE.txt ]]
    then

        scripts/wrp2stream_lat.sh $WAV \
            $ODIR_HYP $MODEL \
            $BUFFER_SIZE \
            $STEP $LA $LLA_SHIFT $LANG

    fi

done
done

done
done

done
#done
#done
