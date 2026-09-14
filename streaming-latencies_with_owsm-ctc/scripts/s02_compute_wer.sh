#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

mkdir -p logs_wer

for MODEL in "espnet/owsm_ctc_v4_1B"
do
VMOD=$(echo $MODEL | awk -F'_' '{print $3}')
cat <<EOF |
0.56 0.40
0.56 0.48
EOF
while read STEP LA
do
for TASK in LHCP-2020
do
for SET in dev #test
do
LLA_SHIFT=0.0
ODIR=results/$VMOD/$TASK.$SET; mkdir -p $ODIR

    if [[ ! -e $ODIR/tmp/res_$VMOD.$TASK.$SET.STEP$STEP.LA$LA.LLA_SHIFT$LLA_SHIFT.txt.COMPLETED ]]
    then
    LANGUAGE='en' # <-- NOTE NOTE

    DHYP=out_hyp/$TASK.$SET
    LIST=lhcp-lists/samples_${TASK}_$SET.lst
    NAME=wer.$VMOD.$TASK.$SET.STEP${STEP}.LA${LA}.LLA_SHIFT$LLA_SHIFT

    scripts/wer_with_qsub.sh \
    $VMOD $TASK $SET $LIST $STEP $LA $DHYP $ODIR $LANGUAGE $LLA_SHIFT
    
    fi
done
done
done
done
