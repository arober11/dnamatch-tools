#!/bin/bash
# Rough duplicate rsid name finder in AncestryDNA, myHeritage, FTDNA, or 23ANDME raw files
#
# Author:  A.Robers 2020-01-05
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

DELIM=""

echo

if [ $# -ne 1 -o ! -f "$1" -o ! -s "$1" ]
then
  echo "Usage:   `basename $0` <rawfile1[.txt|.csv]> "
  echo
  echo "Purpose: Identify the duplicate RSID names in a Genotype file."
  echo
  exit 1
fi

INFILE="$1"
FILE_NAME="`basename $INFILE`"
DELIM=""
DUPCNT=0

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

function chromo_extract {
  egrep "\t$1\t| $1 |,$1," "$INFILE" > "$FILE_NAME.$1"
}

function print_dups {
  CNT=0
  while read chromoPOS
  do
    egrep " $chromoPOS |,$chromoPOS,|\t$chromoPOS\t" $FILE_NAME.$CHROMO | cut $DELIM -f1,2,3
    echo
    ((CNT+=1))
  done < <( cat $FILE_NAME.$CHROMO | cut $DELIM -f 3 | sort | uniq -d )
  echo "DUPLICATES for Chromosome $CHROMO = $CNT"
  ((DUPCNT+=CNT))
}

guess_deliminator "$INFILE"
echo "DELIM=$DELIM"

while read CHROMO
do
  echo "Cheking Chromosome: $CHROMO" 
  chromo_extract $CHROMO
  print_dups $CHROMO
  echo
  rm -f "$FILE_NAME.$CHROMO"
done < <(egrep -v "#|\/|\*|,0,0,--|[0-9],0,0|RSID," "$INFILE" | cut $DELIM -f2 | sort -n | uniq )
echo "Total Duplicates = $DUPCNT"

