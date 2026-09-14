#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

mkdir -p logs

for TASK in LHCP-2020 LHCP-2022
do
    for SET in dev test
    do
        for MODEL in "espnet/owsm_ctc_v3.1_1B" "espnet/owsm_ctc_v3.2_ft_1B" "espnet/owsm_ctc_v4_1B"
        do
        VMOD=$(echo $MODEL | awk -F'_' '{print $3}')
            NAME=R_ctc_${TASK}_${SET}.$VMOD
                scripts/wrp2bax_inf.sh lists/audios_${TASK}_${SET}.lst baseline_out.$VMOD $MODEL
        done
    done
done
