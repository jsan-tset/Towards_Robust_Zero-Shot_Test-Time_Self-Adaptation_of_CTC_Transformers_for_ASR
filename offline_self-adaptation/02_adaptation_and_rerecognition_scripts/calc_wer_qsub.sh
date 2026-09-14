#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

SRC=/home/jausanjo/asr-scripts/wer++

VMOD=$1
TASK=$2
SET=$3
LR=$4
RANK=$5
ALPHA=$6
EP=$7
ODIR_RES=$8

{
cat lists/samples_${TASK}_${SET}.lst | sort -V |
    while read SPL
    do

    HYP=BB_out_hyp.$VMOD/lr$LR.r$RANK.a$ALPHA/$TASK/$SET/$SPL.ep$EP.txt.post.clean
    REF=ref/$TASK/$SET/$SPL.ref
    AUX=$($SRC/wer++.py $HYP $REF 2> /dev/null | grep "WER")
    echo "$SPL $AUX" 

    done 
} > $ODIR_RES/res_$VMOD.$TASK.$SET.lr$LR.r$RANK.a$ALPHA.ep$EP.txt 

ALLHYP=BB_out_hyp.$VMOD/lr$LR.r$RANK.a$ALPHA/$TASK/$SET/all.ep$EP.txt.post.clean
ALLREF=ref/${TASK}/${SET}/all.ref
if [[ $(wc -l < $ALLHYP) -ne $(wc -l < lists/samples_${TASK}_${SET}.lst) ]]
then
    AUX="Number of hyp missmatch references!"
    echo "$AUX"  >> $ODIR_RES/res_$VMOD.$TASK.$SET.lr$LR.r$RANK.a$ALPHA.ep$EP.txt
else
    AUX=$($SRC/wer++.py $ALLHYP $ALLREF 2> /dev/null | grep "WER")
    echo "$OVERALL $AUX"  >> $ODIR_RES/res_$VMOD.$TASK.$SET.lr$LR.r$RANK.a$ALPHA.ep$EP.txt
fi
