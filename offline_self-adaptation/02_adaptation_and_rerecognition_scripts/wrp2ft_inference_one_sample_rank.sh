#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

if [[ $# != 7 ]]
then
    echo "$0 <AUDIO_PATH> <CHKP_PATH> <OUTPUT_DIR> <MODEL> <LORA_RANK> <LORA_ALPHA> <LANGUAGE>" >&2
    exit 1
fi

APTH=$1
CHKP=$2
ODIR=$3; mkdir -p $ODIR
MODL=$4
RANK=$5
ALPH=$6
LANG=$7

source /home/jausanjo/tools/espnet/tools/venv/bin/activate

python scripts/reco_ft_rank.py $APTH $CHKP $ODIR $MODL $RANK $ALPH $LANG

deactivate
