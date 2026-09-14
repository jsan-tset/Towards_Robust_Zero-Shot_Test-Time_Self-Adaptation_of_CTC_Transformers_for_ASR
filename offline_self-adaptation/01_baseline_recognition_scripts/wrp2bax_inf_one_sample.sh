#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

if [[ $# != 4 ]]
then
    echo "$0 <AUDIO_PATH> <OUTPUT_DIR> <MODEL> <LANG>" >&2
    exit 1
fi

APTH=$1
ODIR=$2
MODL=$3
LANG=$4

source /home/jausanjo/tools/espnet/tools/venv/bin/activate

python scripts/batched_inference_one_sample.py $APTH $ODIR $MODL $LANG

deactivate
