#!/bin/bash

set -e

export LC_ALL=C.UTF-8

mkdir -p logs_reco

LANG='eng'

for MODEL in "espnet/owsm_ctc_v3.2_ft_1B" "espnet/owsm_ctc_v3.2_ft_1B" "espnet/owsm_ctc_v4_1B"
do
VMOD=$(echo $MODEL | awk -F'_' '{print $3}')

for TASK in LHCP-2020 LHCP-2022
do
    for SET in dev test
    do

for EP in {1..5}
do

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

cat lists/samples_${TASK}_${SET}.lst |
    while read SPL
    do

NAME=R.${VMOD}.${SPL}.lr$LR.r$RANK.a$ALPHA.${TASK}.${SET}.e$EP
echo $NAME
    scripts/wrp2ft_inference_one_sample_rank.sh \
    wavs/$TASK/$SET/$SPL.wav \
    exp.$VMOD/lr$LR.r$RANK.a$ALPHA/$TASK/$SPL/finetune/${EP}epoch.pth \
    out_hyp.$VMOD/lr$LR.r$RANK.a$ALPHA \
    $MODEL \
    $RANK $ALPHA \
    $LANG

done

done
done
done
done

done
done
