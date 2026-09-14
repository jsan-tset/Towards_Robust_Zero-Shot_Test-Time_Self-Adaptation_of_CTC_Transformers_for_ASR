#!/bin/bash

set -e

export LC_ALL=C.UTF-8

mkdir -p lists

for TASK in LHCP-2020 LHCP-2022
do
for SET in dev test
do
    FLIST=lists/audios_${TASK}_$SET.lst
    find wavs/$TASK/${SET}/ -name '*.wav' | sort  > $FLIST

    
    while read f
    do
        F_LEN=$(soxi -D $f)
        FNAME=$(basename $f .wav)
        ODIR=audio/$TASK/$SET/$FNAME; mkdir -p $ODIR

        sox $f $ODIR/${FNAME}_00000.00-00026.00.wav trim 0 26

        for T_INI in $(seq 18 22 ${F_LEN%.*})
        do
            T_END=$(($T_INI + 30))

            if [[ $(echo "$T_END > $F_LEN" | bc) -ne 0 ]]
            then
                FOUT=$(echo "$ODIR/$FNAME $T_INI $F_LEN" | awk '{printf("%s_%08.2f-%08.2f.wav", $1, $2, $3)}')
                sox $f $FOUT trim $T_INI
            else
                FOUT=$(echo "$ODIR/$FNAME $T_INI $T_END" | awk '{printf("%s_%08.2f-%08.2f.wav", $1, $2, $3)}')
                sox $f $FOUT trim $T_INI 30
            fi
        done
    done < $FLIST

done
done
