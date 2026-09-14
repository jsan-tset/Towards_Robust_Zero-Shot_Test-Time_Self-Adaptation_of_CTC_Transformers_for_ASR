#!/bin/bash

set -e

export LC_ALL=C.UTF-8

if [[ $# != 0 ]]
then
    echo "$0 <>"
    exit 1
fi

for MODEL in "espnet/owsm_ctc_v4_1B"
do
VMOD=$(echo $MODEL | awk -F'_' '{print $3}')
for TASK in LHCP-2020 #LHCP-2022
do
for SET in dev #test
do
DOUT=latencies/$TASK.$SET; mkdir -p $DOUT
TTL_WDS=$(wc -w < ref/$TASK/$SET/all.ref)
LLA_SHIFT=0.0

for D in out_hyp_lat_pinx/$TASK.$SET/reco.$VMOD.*
do 
    if [[ $(ls -l $D/*.lat | wc -l) -eq 14 ]]
    then 
        echo "$D"
    fi
done | sed 's/^.*\(STEP.*\.LLA\)./\1/' | sed -e 's/STEP//' -e 's/.LLASHIFT0.0//' -e 's/.LA/ /' > step_la_completed.txt

cat step_la_completed.txt |
while read STEP LA
do

    NAME=reco.$VMOD.STEP$STEP.LA$LA.LLA_SHIFT$LLA_SHIFT
    echo "$TASK.$SET/$NAME"
    DLAT=out_hyp_lat_pinx/$TASK.$SET/$NAME
    if [[ ! -e $DOUT/$NAME.tlat ]]
    then

    if [[ $(wc -l < ref/$TASK/$SET/all.ref) != $(ls -l $DLAT/*.lat | wc -l) ]]
    then
        echo "ERR # files -> $TASK.$SET/$NAME : $(wc -l < ref/$TASK/$SET/all.ref) != $(ls -l $DLAT/*.lat | wc -l)"
        continue
    fi
    for LAT in $DLAT/*.lat
        do
        python3 scripts/compute_latencies.py $LAT word > ${LAT/.lat/.lat.winfo}
        tail -n1 ${LAT/.lat/.lat.winfo}
    done | awk -F'+=' '{tm+=$1; tsd+=$2} {print $0} END{print "##########################\n"'$STEP'" "'$LA'" "tm/NR" "tsd/NR}' > $DOUT/$NAME.wlat
    for LAT in $DLAT/*.lat
        do
        python3 scripts/compute_latencies.py $LAT token > ${LAT/.lat/.lat.tinfo}
        tail -n1 ${LAT/.lat/.lat.tinfo}
    done | awk -F'+=' '{tm+=$1; tsd+=$2} {print $0} END{print "##########################\n"'$STEP'" "'$LA'" "tm/NR" "tsd/NR}' > $DOUT/$NAME.tlat
    fi

done
done
done
done

tail -qn1 latencies/LHCP-2020.dev/reco.v4.STEP*.wlat > plots/exp_latencies_pinxo/lat_word_data.txt
tail -qn1 latencies/LHCP-2020.dev/reco.v4.STEP*.tlat > plots/exp_latencies_pinxo/lat_token_data.txt
python3 scripts/plot_heatmap_latencies.py plots/exp_latencies_pinxo/lat_word_data.txt word
python3 scripts/plot_heatmap_latencies.py plots/exp_latencies_pinxo/lat_token_data.txt token
