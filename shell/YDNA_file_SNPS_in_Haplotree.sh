#!/bin/bash
# Rough lookup of which YDNA SNPS in a genotype file are in a YDNA Haplotree SNP list.
# Should work for AncestryDNA, myHeritage, FTDNA, or 23ANDME raw files
#
# Author:  A.Robers 2020-01-05
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

start=`date +%s`
INFILE1="DNA1.txt"
INFILE2="YDNA_HAPGRP-Build37.SNP_Positions_used.txt"
DELIM=""

SED="sed -E" ; gsed --version 2>/dev/null 1>/dev/null && SED="gsed -E"
#----------------------------------------

function guess_deliminator {
  DELIM=""

  head -15 "$1" | egrep "TAB-separated|TAB delimited" 1>/dev/null
  if [ $? -ne 0 ]
  then
    head "$1" | egrep  -v "\#|\/|\*" | egrep "\," 1>/dev/null
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
  egrep "\t24\t|\tY\t|,24,|,Y," "$1" | $SED -e "s/--/0/" -e "s/AA/A/" -e "s/CC/C/" -e "s/TT/T/" -e "s/GG/G/" > "$2"
}

function YDNA_extract_SNPS {
  cut $DELIM -f3 "$1" | sort -nu > "$2"
}

function YDNA_extract_CALLS {
  echo cut $DELIM -f3,4 "$1" : sort -nu : $SED -e 's/[\t ]+/,/' - "$2"
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
  echo "Usage:   `basename $0` <rawfile1[.txt|.csv]> [<YDNA-tree-Build-##_SNP_Positions_used.txt>]"
  echo
  echo "Purpose: lookup YDNA calls from an autosomal DNA file and a published YDNA haplotree"
  echo
  echo "defaults: "
  echo "  rawfile  = $INFILE1"                                   - genotyped call file, as offered by AncestryDNA, 23AndMe, FTDNA, ...
  echo "  treefile = $INFILE2" - numeric list of the YDNA SNP positions found in tree e.g.
  echo "                        10000350"
  echo "                        10000477"
  echo "                        10000888"
  echo "                        10001590"
  echo "                        10001720"
  echo "                        10002452"
  echo "                        ..."
  echo "outputs: "
  echo "  rawfile-YDNA-snps = <rawfile1>_YDNA           - YDNA data as it appeared in the rawfile"
  echo "  rawfile-YDNA-snps = <rawfile1>_YDNA.SNPS.txt  - YDNA SNP list from the rawfile"
  echo "  rawfile-YDNA-snps = <rawfile1>_YDNA.SNPS.csv  - YDNA SNP calls from the rawfile"
  echo
  echo "See: get_YDNA_rsid.sh for obtaining the SNP position list"
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

echo -----------------
ls -l $INFILE1 $INFILE2
echo -----------------

grep '[^0-9]' "$INFILE2" 2>/dev/null 1>/dev/null
if [ ! -s "$INFILE2" -o $? -eq 0 ]
then
  usage
  echo "Error - $INFILE2 contains no list of YDNA HAPLOGRP SNP positions, or some non-numeric data"
  exit 5
fi

YDNA_extract_and_convert_NOCALLS $INFILE1 $INFILE1_YDNA

if [ ! -s "$INFILE1_YDNA" ]
then
  usage
  echo "Error - $INFILE1 contains no SNP calls"
  rm -f $INFILE1_YDNA 
  exit 6
fi

guess_deliminator $INFILE1
YDNA_extract_SNPS $INFILE1_YDNA $INFILE1_SNPS 

grep '[^0-9]' "$INFILE1_SNPS" 2>/dev/null 1>/dev/null
if [ ! -s "$INFILE1_SNPS" -o $? -eq 0 ]
then
  usage
  echo "Error - $INFILE1 contains no or nonumeric SNP positions"
  echo "File - $INFILE1_SNPS"
  grep '[^0-9]' "$INFILE1_SNPS" | head
  grep '[^0-9]' "$INFILE1_SNPS" 2>/dev/null 1>/dev/null
  echo RC: $?
  rm -f $INFILE1_YDNA $INFILE1_SNPS
  exit 7
fi

YDNA_extract_CALLS $INFILE1_YDNA $INFILE1_CALL 
egrep -E -v '^\d+,[actgACTGI0-dD]+$' -e '/^$/d' "$INFILE1_CALL" 2>/dev/null 1>/dev/null
if [ ! -s "$INFILE1_CALL" -o $? -eq 0 ]
then
  usage
  echo "Error - $INFILE1 contains no or nonumeric SNP positions or valid calls"
  egrep -E -v '^\d+,[actgACTGI0-dD]+$' -e '/^$/d' "$INFILE1_CALL" | head
  egrep -E -v '^\d+,[actgACTGI0-dD]+$' -e '/^$/d' "$INFILE1_CALL" 2>/dev/null 1>/dev/null
  echo RC: $?
  rm -f $INFILE1_YDNA $INFILE1_SNPS $INFILE1_CALL
  exit 8
fi

diff $INFILE1_SNPS $INFILE2 1>/dev/null
if [ $? -eq 0 ]
then
  echo "WARNING: files contain identical YDNA SNPS !!!"
  echo
fi

inHaploTree "$INFILE1_SNPS" "$INFILE2"
notInHaploTree "$INFILE1_SNPS" "$INFILE2"

rm -f "$INFILE1_YDNA" "$INFILE1_SNPS" 
exit 0
