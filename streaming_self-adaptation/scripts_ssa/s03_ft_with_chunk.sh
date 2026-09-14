#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

if [[ $# != 10 ]]
then
    echo "$0 <train_csv> <valid_csv> <outdir> <model> <learning_rate> <lora_rank> <lora_alpha> <total_epochs> <conf.yaml> <lang>" >&2
    exit 1
fi

TCSV=$1
VCSV=$2
ODIR=$3; mkdir -p $3
MODL=$4
LR=$5
RANK=$6
ALPH=$7
EPOCH=$8
CONF=$9
LANG=${10}

source /home/jausanjo/tools/espnet/tools/venv/bin/activate

python scripts/ft_ssa.py $TCSV $VCSV $ODIR $MODL $LR $RANK $ALPH $EPOCH $CONF $LANG

deactivate
