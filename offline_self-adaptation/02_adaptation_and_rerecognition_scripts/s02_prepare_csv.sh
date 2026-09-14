#!/bin/bash

set -e

export LC_ALL=C.UTF-8

for MODEL in "espnet/owsm_ctc_v3.1_1B" "espnet/owsm_ctc_v3.2_ft_1B" "espnet/owsm_ctc_v4_1B"
do
VMOD=$(echo $MODEL | awk -F'_' '{print $3}')
# baseline_chunked.$VMOD is the directory with the transcriptions
if [[ ! -e baseline_chunked.$VMOD ]]
then
    ln -s <path/to/transcriptions> .
fi

for TASK in LHCP-2020 LHCP-2022
do
for SET in dev test
do
    DCSV=csv_train/$VMOD/$TASK/$SET; mkdir -p $DCSV
    for VID in audio/$TASK/$SET/*
    do
        echo "Preparing $VID ..."
        SNAME=$(basename $VID)
        SNUM=0
        for SPL in $VID/*
        do
            if [[ $(echo "$(soxi -D $SPL) >= 2.0" | bc) -eq 1 ]]
            then
                SNUMP=$(printf '%03d' $SNUM)
                if [[ -f baseline_chunked.$VMOD/$TASK/$SET/$SNAME/$SNAME.$SNUMP.txt ]]
                then
                    TXT=$(cat baseline_chunked.$VMOD/$TASK/$SET/$SNAME/$SNAME.$SNUMP.txt)
                    echo "$SPL|$TXT|$TXT" 
                fi
            fi
            SNUM=$((SNUM+1))

        done > $DCSV/$SNAME.csv
    done
done
done

done
