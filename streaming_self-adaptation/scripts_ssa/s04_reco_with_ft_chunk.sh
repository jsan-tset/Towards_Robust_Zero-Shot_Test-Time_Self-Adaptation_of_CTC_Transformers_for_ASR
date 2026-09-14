#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

if [[ $# != 11 ]]
then
    echo "$0 <AUDIO_PATH> <CHKP_PATH> <ODIR_ADAPT_SAMPLES> <ODIR_HYP> <MODEL> <LORA_RANK> <LORA_ALPHA> <CONTEXT_LEN> <CONTEXT_LEFT> <CONTEXT_RIGHT> <LANG>" >&2
    exit 1
fi

APTH=$1
CHKP=$2
ODIR_ADAPT=$3; mkdir -p $ODIR_ADAPT
ODIR_HYP=$4; mkdir -p $ODIR_HYP
MODL=$5
RANK=$6
ALPH=$7
CONT=$8
CON_L=$9
CON_R=${10}
LANG=${11}

source /home/jausanjo/tools/espnet/tools/venv/bin/activate

python scripts/reco_ft_ssa.py $APTH $CHKP $ODIR_ADAPT $ODIR_HYP $MODL $RANK $ALPH $CONT $CON_L $CON_R $LANG

deactivate
