#!/bin/bash
# Rough File state on an AncestryDNA, or 23ANDME raw file
#
# Author:  A.Robers 2020-01-05
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

start=`date +%s`
INFILE="AncestryDNA.txt"
DELIM=""
SNPS=0
NOCALLS=0
CALLS=0

function guess_deliminator {
  DELIM=""

  head -15 "$1" | egrep "TAB-separated|TAB delimited" > /dev/null
  if [ $? -ne 0 ]
  then
    head "$1" | egrep  -v "\#|\/|\*" | egrep "\," > /dev/null
    if [ $? -ne 0 ]
    then
      DELIM="-d' '"
    else
      DELIM="-d,"
    fi
  fi
}

echo

if [ $# -gt 2 ]
then
  echo "Usage:   `basename $0` <rawfile[.txt|.csv]> [,]"
  echo
  echo "Purpose: Reports SNP counts, per chromosome, with a count of calls, and no calls."
  echo
  echo "defaults: "
  echo "  rawfile = $INFILE"
  echo "  deliminator  = tab (AncestryDNA)"
  echo 
  echo "Nb: To use the with a FTDNA raw file, sepcify a deliminator of ',' withoug (the quotes)."
  echo
  exit 1
fi

if [ $# -gt 0 ]
then 
  INFILE=$1
fi

if [ ! -f $INFILE ]
then
  echo "Error: Not raw file - $INFILE"
  exit 2
fi

if [ $# = 2 ]
then
  DELIM="-d$2"
else
  guess_deliminator "$INFILE"
fi

echo "SNPs per chromosome"
echo "Chromosome,CNT"
while read chrCNT
do
 CNT=$(echo $chrCNT | cut -d' ' -f1 )
 CHR=$(echo $chrCNT | cut -d' ' -f2 )
 echo $CHR,$CNT
 ((SNPS+=CNT))
done < <( egrep -v "#|\/|\*|,0,0,--|[0-9],0,0|RSID," $INFILE | egrep -vi "^rsid|^i" | cut $DELIM -f2 |  uniq -c | sed -e 's/[[:space:]]\{1,\}/ /g' -e 's/^ //' ) 
echo SNPS,$SNPS 

echo
echo "No Calls per chromosome"
echo "Chromosome,CNT"
while read chrCNT
do
 CNT=$(echo $chrCNT | cut -d' ' -f1 )
 CHR=$(echo $chrCNT | cut -d' ' -f2 )
 echo $CHR,$CNT
 ((NOCALLS+=CNT))
done < <( egrep "\t0\t|--" $INFILE | egrep -v "#|\/|\*|,0,0,--|[0-9],0,0|RSID," | grep -vi "^rsid|^i" | cut $DELIM -f2 | uniq -c | sed -e 's/[[:space:]]\{1,\}/ /g' -e 's/^ //' ) 
echo NOCALLS,$NOCALLS 

echo
echo "Calls per chromosome"
echo "Chromosome,CNT"
while read chrCNT
do
 CNT=$(echo $chrCNT | cut -d' ' -f1 )
 CHR=$(echo $chrCNT | cut -d' ' -f2 )
 echo $CHR,$CNT
 ((CALLS+=CNT))
done < <( egrep -v "\t0\t|--" $INFILE | egrep -v "#|\/|\*|,0,0,--|[0-9],0,0|RSID," | egrep -vi "^rsid|^i" | cut $DELIM -f2 |  uniq -c | sed -e 's/[[:space:]]\{1,\}/ /g' -e 's/^ //' ) 
echo CALLS,$CALLS 

echo
echo PCT_CALL,$(echo "scale=3;$CALLS*100/$SNPS"| bc)%
echo PCT_NOCALL,$(echo "scale=3;$NOCALLS*100/$SNPS"| bc)%
