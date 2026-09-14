#!/bin/bash

set -xe

export LC_ALL=C.UTF-8

SRC=/home/jausanjo/asr-scripts/wer++

if [[ $# != 10 ]]
then
    echo "$0 <VMOD> <TASK> <SET> <SPL_LIST> <STEP> <LA> <HYPDIR> <ODIR> <LANG:en|es|ca>> <LLA_SHIFT>"
    exit 1
fi

VMOD=$1
TASK=$2
SET=$3
LIST=$4
STEP=$5
LA=$6
DHYP=$7
ODIR_RES=$8
LANG=$9
LLA_SHIFT=${10}

OFILE=res_$VMOD.$TASK.$SET.STEP$STEP.LA$LA.LLA_SHIFT$LLA_SHIFT.txt
mkdir -p $ODIR_RES/tmp

cat $LIST | sort -V |
while read SPL
do
    OHYP=$DHYP/reco.$VMOD.STEP$STEP.LA$LA.LLA_SHIFT$LLA_SHIFT/$SPL.txt

    scripts/postprohyp.sh $OHYP $LANG

    HYP=$OHYP.post.clean
    REF=ref/$TASK/$SET/$SPL.ref
    AUX=$($SRC/wer++.py $HYP $REF 2> /dev/null | grep "WER")
    ORIGWER=$(grep $SPL ../06_OWSM_LHCP_video/results/$TASK.$SET.$VMOD.txt | awk {'print $3'})
    NEWWER=$(echo $AUX | awk {'print $2'})
    RELUPG=$(echo "($ORIGWER - $NEWWER)/$ORIGWER * 100" | bc -lq | xargs printf "%.2f\n")
    if (( $(echo "$RELUPG < 0" | bc -l) ))
    then
        echo "$SPL 0 $AUX | Rel.Upg. $RELUPG (OWER $ORIGWER)" 
    else
        echo "$SPL 1 $AUX | Rel.Upg. $RELUPG (OWER $ORIGWER)" 
    fi

done > $ODIR_RES/$OFILE

ALLREF=ref/${TASK}/${SET}/all.ref
NUMSPL=$(wc -l < $ALLREF)
if [[ $(wc -l < $ODIR_RES/$OFILE) -ne $NUMSPL ]]
then
    AUX="Number of hyp missmatch references!"
    echo "$AUX"  >> $ODIR_RES/$OFILE
else
    #AUX=$($SRC/wer++.py $ALLHYP $ALLREF 2> /dev/null | grep "WER")
    AUX=$(./scripts/compute_total_wer.sh $ODIR_RES/$OFILE)
    NEWWER=$(echo $AUX | awk {'print $2'})
    ORIGWER=$(grep "$VMOD/$TASK/$SET" ../06_OWSM_LHCP_video/results/overall_wers.txt | awk {'print $3'})
    RELUPG=$(echo "($ORIGWER - $NEWWER)/$ORIGWER * 100" | bc -lq | xargs printf "%.2f\n")
    IMPR=$(awk '{sum+=$2}END{print sum}' $ODIR_RES/$OFILE)
    EFF=$(awk 'BEGIN{printf "%5.2f", '$IMPR' / '$NUMSPL' * 100}')
    INCRE=$(awk 'BEGIN{printf "%4.2f", '$NEWWER' - '$ORIGWER'}')
    MAGICNUM=$(awk 'BEGIN{printf "%4.2f", '$STEP' / 2 + '$LA'}')
    echo "$AUX | Rel.Upg. $RELUPG (OWER $ORIGWER) | Eff. $EFF ($IMPR/$NUMSPL) | Incre.($INCRE) | $OFILE [ Lat.Teo.$MAGICNUM ]"  >> $ODIR_RES/$OFILE
    touch $ODIR_RES/tmp/$OFILE.COMPLETED
fi
