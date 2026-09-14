#!/bin/bash

set -e

export LC_ALL=C.UTF-8

SCR=~/asr-scripts/asr-scripts/lm/prepro

for MODEL in "espnet/owsm_ctc_v3.2_ft_1B" "espnet/owsm_ctc_v3.2_ft_1B" "espnet/owsm_ctc_v4_1B"
do
VMOD=$(echo $MODEL | awk -F'_' '{print $3}')

for TASK in LHCP-2020 LHCP-2022
do
    for SET in test
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

for TXT in out_hyp.$VMOD/lr$LR.r$RANK.a$ALPHA/$TASK/$SET/*.txt
do
    source /home/jausanjo/pyth_envs/prepro/bin/activate
    cat $TXT | $SCR/prepro_am.sh en > $TXT.post
    deactivate

    HYP=$TXT.post.clean
    sed -e 's/<oov>//g' -e 's/ uh / /g' -e 's/ um / /g' $TXT.post | sed -e 's/ uh / /g' -e 's/ um / /g' > $HYP
done

for EP in {1..5}
do
for HYP in $(find out_hyp.$VMOD/lr$LR.r$RANK.a$ALPHA/$TASK/$SET/[0-9]*ep$EP.txt.post.clean | sort -V)
do
    cat $HYP
done > out_hyp.$VMOD/lr$LR.r$RANK.a$ALPHA/$TASK/$SET/all.ep$EP.txt.post.clean
done

done
done
done
done

done
