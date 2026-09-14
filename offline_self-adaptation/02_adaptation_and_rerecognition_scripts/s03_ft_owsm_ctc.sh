#!/bin/bash

set -e

export LC_ALL=C.UTF-8

mkdir -p logs_ft

LANG='eng'

for MODEL in "espnet/owsm_ctc_v3.1_1B" "espnet/owsm_ctc_v3.2_ft_1B" "espnet/owsm_ctc_v4_1B"
do
VMOD=$(echo $MODEL | awk -F'_' '{print $3}')

for LR in 0.003
do

cat <<EOF |
4 8
8 16
16 32
32 64
64 128
128 256
EOF
while read RANK ALPHA
do

for TASK in LHCP-2020 LHCP-2022
do
    for SET in dev test
    do
        cat lists/samples_${TASK}_${SET}.lst |
            while read SPL
            do

NAME=ft.${VMOD}.${SPL}.lr$LR.r$RANK.a$ALPHA.${TASK}.${SET}

    scripts/wrp_ft_minim_rank.sh \
        csv_train/$VMOD/$TASK/$SET/${SPL}.csv \
        csv_valid/$TASK/$SET/$SPL.csv  \
        exp.$VMOD/lr$LR.r$RANK.a$ALPHA/$TASK/$SPL \
        $MODEL \
        $LR \
        $RANK $ALPHA \
        conf/ft_owsm_ctc_osa.yaml \
        $LANG


done # SPL
done # SET
done # TASK
done # RANK ALPHA 
done # LR
done # MODEL
