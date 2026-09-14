#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

mkdir -p lists
for TASK in LHCP-2020 LHCP-2022
do
DIR=raw/$TASK; mkdir -p $DIR

for SET in  dev test
do
    mkdir -p wavs/$TASK/$SET
    find $DIR/$SET/ -name '*.mp4' |
        while read MP4
        do
            NAME=`basename $MP4 .mp4`
            ffmpeg -i "$MP4" -ar 16k -ac 1 wavs/$TASK/$SET/$NAME.wav < /dev/null
        done
    find wavs/$TASK/$SET -name '*.wav' | sort > lists/audios_${TASK}_${SET}.lst
done
done
