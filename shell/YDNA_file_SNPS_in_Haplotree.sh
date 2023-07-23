#!/bin/bash
# Rough lookup of which YDNA SNPS in a genotype file are in a YDNA Haplotree SNP list.
# Should work for AncestryDNA, myHeritage, FTDNA, or 23ANDME raw files
#
# Author:  A.Robers 2020-01-05
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

start=`date +%s`
INFILE1="DNA1.txt"
INFILE2="YDNA-tree-Build-XX.SNP_Positions_used.txt"
DELIM=""
#----------------------------------------

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
echo "DELIM=$DELIM"
}

function YDNA_extract_and_convert_NOCALLS {
  egrep "\t24\t|\tY\t|,24," "$1" | sed -e "s/--/0/" -e "s/AA/A/" -e "s/CC/C/" -e "s/TT/T/" -e "s/GG/G/" > "$2"
}

function YDNA_extract_SNPS {
  cut $DELIM -f3 "$1" | sort -nu > "$2"
}

function YDNA_extract_CALLS {
  cut $DELIM -f3,4 "$1" | sort -nu | gsed -e 's/[	 ]+/,/' > "$2"
}

function inHaploTree {
  cp $1 $1.tmp
  cat $2 >> $1.tmp
  echo
  echo "SNPS found in Haplotree" 
  sort -n $1.tmp | uniq -d
  echo
  echo "Count of SNPS common to the Haplotree: $(sort -n $1.tmp | uniq -d | wc -l)"
  rm -f $1.tmp
}

function notInHaploTree {
  cp $1 $1.tmp
  cat $2 >> $1.tmp
  sort -n $1.tmp | uniq -d > $1.tmp.uniq
  cat $1 >> $1.tmp.uniq
  echo
  echo "SNPS NOT found in Haplotree"
  sort -n $1.tmp.uniq | uniq -u
  echo
  echo "Count of SNPS NOT common to the Haplotree: $(sort -n $1.tmp.uniq | uniq -u | wc -l)"
  rm -f $1.tmp $1.tmp.uniq
}

#----------------------------------------

if [ $# -eq 0 -o ! -f "$1" -o $# -gt 1 -a ! -f "$2" -o $# -eq 1 -a ! -f "$INFILE2" ]
then
  echo
  echo "Usage:   `basename $0` <rawfile1[.txt|.csv]> [<YDNA-tree-Build-##_SNP_Positions_used.txt>]"
  echo
  echo "Purpose: lookup YDNA calls from an autosomal DNA file and a published YDNA haplotree"
  echo
  echo "defaults: "
  echo "  rawfile  = $INFILE1"
  echo "  treefile = $INFILE2"
  echo
  echo "outputs: "
  echo "  rawfile-YDNA-snps = <rawfile1>_YDNA           - YDNA data as it appeared in the rawfile"
  echo "  rawfile-YDNA-snps = <rawfile1>_YDNA.SNPS.txt  - YDNA SNP list from the rawfile"
  echo "  rawfile-YDNA-snps = <rawfile1>_YDNA.SNPS.csv  - YDNA SNP calls from the rawfile"

  if [ $# -gt 0 -a ! -f "$1" ]
  then
    echo "Error: No valid raw file specified - $1"
    exit 2
  fi

  if [ $# -gt 1 -a ! -f "$2" ]
  then
    echo "Error: No valid YDNA SNP file specified - $2"
    exit 3
  fi

  if [ $# -eq 1 -a ! -f "$INFILE2" ]
  then
    echo "Error: default YDNA SNP file not found - $INFILE2"
    ls -l "$INFILE2"
    exit 4
  fi
  
  exit 1
fi

INFILE1="$1"
INFILE1_YDNA="`basename $INFILE1`_YDNA"
INFILE1_SNPS="`basename $INFILE1`_YDNA.SNPS.txt"
INFILE1_CALL="`basename $INFILE1`_YDNA.SNPS.csv"
if [ $# -gt 1 ]
then
  INFILE2="$2"
fi

grep -v '^\d*$' "$INFILE2" 2>&1 >/dev/null
if [ ! -s "$INFILE2" -o $? -eq 0 ]
then
  echo "Error - $INFILE2 contains no list of YDNA HAPLOGRP SNP positions, or some non-numeric data"
  exit 5
fi

YDNA_extract_and_convert_NOCALLS $INFILE1 $INFILE1_YDNA

if [ ! -s "$INFILE1_YDNA" ]
then
  echo "Error - $INFILE1 contains no SNP calls"
  rm -f $INFILE1_YDNA 
  exit 6
fi

guess_deliminator $INFILE1
YDNA_extract_SNPS $INFILE1_YDNA $INFILE1_SNPS 

egrep -v '^\d*$' "$INFILE1_SNPS" 2>&1 >/dev/null
if [ ! -s "$INFILE1_SNPS" -o $? -eq 0 ]
then
  echo "Error - $INFILE1 contains no or nonumeric SNP positions"
  grep -v '^\d*$' "$INFILE1_SNPS"
  echo RC: $?
  rm -f $INFILE1_YDNA $INFILE1_SNPS
  exit 7
fi

YDNA_extract_CALLS $INFILE1_YDNA $INFILE1_SNPS 
egrep -E -v '^\d+,[actgACTGI0-]+$' "$INFILE1_CALL" 2>&1 >/dev/null
if [ ! -s "$INFILE1_CALL" -o $? -eq 0 ]
then
  echo "Error - $INFILE1 contains no or nonumeric SNP positions or valid calls"
  grep -v '^\d*$' "$INFILE1_SNPS"
  echo RC: $?
  rm -f $INFILE1_YDNA $INFILE1_SNPS $INFILE1_CALL
  exit 8
fi

diff $INFILE1_SNPS $INFILE2 > /dev/null
if [ $? -eq 0 ]
then
  echo "WARNING: files contain identical YDNA SNPS !!!"
  echo
fi

inHaploTree "$INFILE1_SNPS" "$INFILE2"
notInHaploTree "$INFILE1_SNPS" "$INFILE2"

#rm -f "$INFILE1_YDNA" "$INFILE1_SNPS" 
exit 0
