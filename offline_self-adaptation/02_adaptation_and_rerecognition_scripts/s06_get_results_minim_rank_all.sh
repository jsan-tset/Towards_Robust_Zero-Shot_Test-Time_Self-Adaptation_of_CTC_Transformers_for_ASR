#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

# This scripts only computes WER metric

RES=results; mkdir -p $RES
mkdir -p logs_wer

for MODEL in "espnet/owsm_ctc_v3.2_ft_1B" "espnet/owsm_ctc_v3.2_ft_1B" "espnet/owsm_ctc_v4_1B"
do
VMOD=$(echo $MODEL | awk -F'_' '{print $3}')

for TASK in LHCP-2020 LHCP-2022
do
for SET in dev test
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

for EP in {1..5}
do
        scripts/calc_wer_qsub.sh \
        $VMOD $TASK $SET $LR $RANK $ALPHA $EP $RES

done 
done
done
done
done

done
