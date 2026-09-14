#!/bin/bash

set -e

export LC_ALL=C.UTF-8

mkdir -p logs

for MODEL in "espnet/owsm_ctc_v3.1_1B" "espnet/owsm_ctc_v3.2_ft_1B" "espnet/owsm_ctc_v4_1B"
do
VMOD=$(echo $MODEL | awk -F'_' '{print $3}')
    for RANK in 64 #16 8 4
    do
    for MAX_EP in {1..7}
    do
    for LR in 0.003 
    do
    for CHUNK in 90 150 300 600
    do

        #for TASK in LHCP-2022
        for TASK in LHCP-2020 LHCP-2022
        do
		LANG=eng # NOTE <-- Important!
        for SET in dev #test
        do
        for WAV in `<lhcp-lists/audios_${TASK}_$SET.lst`
        do

    SAMPLE=$(basename $WAV .wav)
    NAME=inc_testing.${VMOD}.r$RANK.ep$MAX_EP.lr$LR.cs$CHUNK.$SET.$SAMPLE
    if [[ ! -e out_hyp/incremental.$VMOD/ep$MAX_EP.chsize$CHUNK.lr$LR.r$RANK/$SAMPLE/full.hyp.post.clean ]]
    then
        scripts/megascript_incremental.sh $MODEL \
            $RANK $MAX_EP $LR $CHUNK \
            $WAV $LANG

    fi

        done
        done
        done

    done
    done
    done
    done
done
