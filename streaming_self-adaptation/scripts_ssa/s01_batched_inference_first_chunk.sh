#!/bin/bash

set -e

export LC_ALL=C.UTF-8

if [[ $# != 8 ]]
then 
    echo "$0 <audio_path> <odir_adapt_samples> <odir_hyp> <model> <context_len> <context_left> <context_right> <lang>"
    exit 1
fi

AUDIO_PATH=$1
ODIR_ADAPT=$2
ODIR_HYP=$3
MODEL=$4
CONTEXT=$5
CONLEFT=$6
CONRIGHT=$7
LANG=$8

source /home/jausanjo/tools/espnet/tools/venv/bin/activate

python3 scripts/batched_inference_enhanced.py $AUDIO_PATH $ODIR_ADAPT $ODIR_HYP $MODEL $CONTEXT $CONLEFT $CONRIGHT $LANG

deactivate
