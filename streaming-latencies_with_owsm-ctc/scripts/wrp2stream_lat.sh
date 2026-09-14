#!/bin/bash

set -xe

export LC_ALL=C.UTF-8
    
if [[ $# != 8 ]]
then
    echo "$0 <audio_path> <odir_hyp> <model> <audio_buffer_size:float:seconds> <step:float:seconds> <la:float:seconds> <lla_shift:float:seconds> <language:eng|spa|cat>"
    exit 1
fi

AUDIO_PATH=$1
ODIR_HYP=$2
MODEL=$3
BUFF=$4
STEP=$5
LA=$6
LLA_SHIFT=$7
LANG=$8

source /home/jausanjo/tools/espnet/tools/venv/bin/activate

time python3 scripts/streaming_inference_lat.py $AUDIO_PATH $ODIR_HYP $MODEL $BUFF $STEP $LA $LLA_SHIFT $LANG

deactivate
