#!/bin/bash
# Rough lookup of which mtDNA SNPS in a genotype file are in a mtDNA Haplotree SNP list.
# Should work for AncestryDNA, myHeritage, FTDNA, or 23ANDME raw files
#
# Author:  A.Robers 2020-01-05
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

start=`date +%s`
INFILE1="DNA1.txt"
INFILE2="mtDNA-tree-Build-17.SNP_Positions_used.txt"
DELIM=""
SED="sed -E" ; gsed --version  2>&1 > /dev/null && SED="gsed -E"
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

function mtDNA_extract_and_convert_NOCALLS {
  egrep "\t26\t|\tMT\t|,26,|,MT," "$1" | $SED -e "s/--/0/" -e "s/AA/A/" -e "s/CC/C/" -e "s/TT/T/" -e "s/GG/G/" > "$2"
}

function mtDNA_extract_SNPS {
  echo cut $DELIM -f3 "$1" | sort -nu > "$2"
  cut $DELIM -f3 "$1" | sort -nu > "$2"
}

function mtDNA_extract_CALLS {
  cut $DELIM -f3,4 "$1" | sort -nu | $SED -e 's/[\t ]+/,/' > "$2"
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

function usage {
  echo
  echo "Usage:   `basename $0` <rawfile1[.txt|.csv]> [<mtDNA-tree-Build-##_SNP_Positions_used.txt>]"
  echo
  echo "Purpose: lookup mtDNA calls from an autosomal DNA file and a published mtDNA haplotree"
  echo
  echo "defaults: "
  echo "  rawfile  = $INFILE1"                                   - genotyped call file, as offered by AncestryDNA, 23AndMe, FTDNA, ...
  echo "  treefile = $INFILE2" - numeric list of the mtDNA SNP positions foung in tree e.g.
  echo "                        10"
  echo "                        16"
  echo "                        26"
  echo "                        41"
  echo "                        42"
  echo "                        44"
  echo "                        47"
  echo "                        53"
  echo "                        54"
  echo "                        ..."
  echo "outputs: "
  echo "  rawfile-mtDNA-snps = <rawfile1>_mtDNA           - mtDNA data as it appeared in the rawfile"
  echo "  rawfile-mtDNA-snps = <rawfile1>_mtDNA.SNPS.txt  - mtDNA SNP list from the rawfile"
  echo "  rawfile-mtDNA-snps = <rawfile1>_mtDNA.SNPS.csv  - mtDNA SNP calls from the rawfile"
  echo
}

#----------------------------------------

if [ $# -eq 0 -o ! -f "$1" -o $# -gt 1 -a ! -f "$2" -o $# -eq 1 -a ! -f "$INFILE2" ]
then
  usage
  if [ $# -gt 0 -a ! -f "$1" ]
  then
    echo "Error: No valid raw file specified - $1"
    exit 2
  fi

  if [ $# -gt 1 -a ! -f "$2" ]
  then
    echo "Error: No valid mtDNA SNP file specified - $2"
    exit 3
  fi

  if [ $# -eq 1 -a ! -f "$INFILE2" ]
  then
    echo "Error: default mtDNA SNP file not found - $INFILE2"
    ls -l "$INFILE2"
    exit 4
  fi
  
  exit 1
fi

INFILE1="$1"
INFILE1_mtDNA="`basename $INFILE1`_mtDNA"
INFILE1_SNPS="`basename $INFILE1`_mtDNA.SNPS.txt"
INFILE1_CALL="`basename $INFILE1`_mtDNA.SNPS.csv"
if [ $# -gt 1 ]
then
  INFILE2="$2"
fi

grep -v '^\d*$' "$INFILE2" 2>&1 >/dev/null
if [ ! -s "$INFILE2" -o $? -eq 0 ]
then
  usage
  echo "Error - $INFILE2 contains no list of mtDNA HAPLOGRP SNP positions, or some non-numeric data"
  exit 5
fi

mtDNA_extract_and_convert_NOCALLS $INFILE1 $INFILE1_mtDNA

if [ ! -s "$INFILE1_mtDNA" ]
then
  usage
  echo "Error - $INFILE1 contains no SNP calls"
  rm -f $INFILE1_mtDNA 
  exit 6
fi

guess_deliminator $INFILE1
mtDNA_extract_SNPS $INFILE1_mtDNA $INFILE1_SNPS 

egrep -v '^\d*$' "$INFILE1_SNPS" 2>&1 >/dev/null
if [ ! -s "$INFILE1_SNPS" -o $? -eq 0 ]
then
  usage
  echo "Error - $INFILE1 contains no or nonumeric SNP positions"
  grep -v '^\d*$' "$INFILE1_SNPS"
  echo RC: $?
  rm -f $INFILE1_mtDNA $INFILE1_SNPS
  exit 7
fi

mtDNA_extract_CALLS $INFILE1_mtDNA $INFILE1_CALL 
egrep -E -v '^\d+,[actgACTGI0-dD]+$' -e '/^$/d' "$INFILE1_CALL" 2>&1 >/dev/null
if [ ! -s "$INFILE1_CALL" -o $? -eq 0 ]
then
  usage
  echo "Error - $INFILE1 contains no or nonumeric SNP positions or valid calls"
  egrep -E -v '^\d+,[actgACTGI0-dD]+$' -e '/^$/d' "$INFILE1_CALL" | head
  egrep -E -v '^\d+,[actgACTGI0-dD]+$' -e '/^$/d' "$INFILE1_CALL" 2>&1 >/dev/null
  echo RC: $?
  rm -f $INFILE1_mtDNA $INFILE1_SNPS $INFILE1_CALL
  exit 8
fi

diff $INFILE1_SNPS $INFILE2 > /dev/null
if [ $? -eq 0 ]
then
  echo "WARNING: files contain identical mtDNA SNPS !!!"
  echo
fi

inHaploTree "$INFILE1_SNPS" "$INFILE2"
notInHaploTree "$INFILE1_SNPS" "$INFILE2"

#rm -f "$INFILE1_mtDNA" "$INFILE1_SNPS" 
exit 0
