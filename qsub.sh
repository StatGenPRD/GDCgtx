#!/bin/bash
LABEL=$1
EMAIL=$2
WORKSPACE=$3


rm -f $WORKSPACE/gtx.err $WORKSPACE/gtx.out

qsub -N $LABEL -q dl580 -b y -m e -M $EMAIL -l mt=3G \
-e $WORKSPACE/gtx.err \
-o $WORKSPACE/gtx.out \
-i /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/tableinput.R \
/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/qsub_Rcall.sh \
$WORKSPACE
