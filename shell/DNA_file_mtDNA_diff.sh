#!/bin/bash
# Rough mtDNA diff between AncestryDNA, myHeritage, FTDNA, or 23ANDME raw files
#
# Author:  A.Robers 2020-01-05
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

start=`date +%s`
INFILE1="DNA1.txt"
INFILE2="DNA2.txt"
DELIM=""
DELIM1=""
DELIM2=""
MISSING=0
SED="sed -E" ; gsed --version 2>/dev/null 1>/dev/null && SED="gsed -E"

echo

if [ $# -lt 2 -o ! -f "$1" -o ! -f "$2" ]
then
  echo "Usage:   `basename $0` <rawfile1[.txt|.csv]> <rawfile2[.txt|.csv]> [M|Missing]"
  echo
  echo "Purpose: Diff the mtDNA calls between two DNA files."
  echo
  echo "Opions - [M|Missing]  - List SNPS in one file but not the other"
  echo
  echo "defaults: "
  echo "  rawfile = $INFILE1"
  echo "          = $INFILE2"
  echo

  if [ $# -gt 0 -a ! -f "$1" ]
  then
    echo "Error: Not raw file - $1"
    exit 2
  fi

  if [ $# -gt 1 -a ! -f "$2" ]
  then
    echo "Error: Not raw file - $2"
    exit 2
  fi

  exit 1
fi

if [ "M" == "$3" -o "Missing" == "$3" ]
then
  MISSING=1
  echo "Missing SET"
fi

INFILE1="$1"
INFILE1_mtDNA="`basename $INFILE1`.mtDNA"
INFILE2="$2"
INFILE2_mtDNA="`basename $INFILE2`.mtDNA"

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

function mtDNA_extract_and_convert_NOCALLS {
  #Also ignore heades and comments
  egrep -v "#|\/|\*|RSID,|,0,0,--" "$1" | egrep "\t26\t|\tMT\t|,26,|,MT," | $SED -e "s/--/0/" -e "s/AA/A/" -e "s/CC/C/" -e "s/TT/T/" -e "s/GG/G/" > "$2" 
}

mtDNA_extract_and_convert_NOCALLS $INFILE1 $INFILE1_mtDNA
mtDNA_extract_and_convert_NOCALLS $INFILE2 $INFILE2_mtDNA

if [ ! -s "$INFILE1_mtDNA" ]
then
  echo "Error - $INFILE1 contains no mtDNA calls"
  rm -f "$INFILE1_mtDNA" "$INFILE2_mtDNA"
  exit 3
fi

if [ ! -s "$INFILE2_mtDNA" ]
then
  echo "Error - $INFILE2 contains no mtDNA calls"
  rm -f "$INFILE1_mtDNA" "$INFILE2_mtDNA"
  exit 3
fi

diff $INFILE1_mtDNA $INFILE2_mtDNA > /dev/null
if [ $? -eq 0 ]
then
  echo "WARNING: files contain identical mtDNA calls and formatting !!!"
  echo
fi

function delDups {
  while read delDUP
  do
     $SED -i -n "/$delDUP/{:a;n;p;ba};p" $INFILE
  done < <( cut $DELIM -f3 $INFILE | sort -n | uniq -d )
  
  DUP_SNPS=$(cut $DELIM -f3 $INFILE | sort -n | uniq -d | wc -l )
  ((DUP_SNPS+=0))
  if [ $DUP_SNPS -ne 0 ] 
  then
    delDups
  fi 
}

function countCalls {

  SNPS=0
  NOCALLS=0
  CALLS=0
  INFILE="$1"

  echo "mtDNA SNPs - $1"

  DUP_SNPS=$(cut $DELIM -f3 $INFILE | sort -n | uniq -d | wc -l )
  ((DUP_SNPS+=0))
  echo DUP_SNPS,$DUP_SNPS
  if [ $DUP_SNPS -ne 0 ] 
  then
    delDups
  fi 

  while read chrCNT
  do
   CNT=$(echo $chrCNT | cut -d' ' -f1 )
   CHR=$(echo $chrCNT | cut -d' ' -f2 )
   ((SNPS+=CNT))
  done < <( cut $DELIM -f3 $INFILE | uniq -c | $SED -e 's/[[:space:]]{1,}/ /g' -e 's/^ //' ) 
  echo UNIQ_SNPS,$SNPS 

  while read chrCNT
  do
   CNT=$(echo $chrCNT | cut -d' ' -f1 )
   CHR=$(echo $chrCNT | cut -d' ' -f2 )
   ((NOCALLS+=CNT))
  done < <( egrep "(\t0|,0$|--)" $INFILE | cut $DELIM -f3 | uniq -c | $SED -e 's/[[:space:]]{1,}/ /g' -e 's/^ //' ) 
  echo NOCALLS,$NOCALLS 

  while read chrCNT
  do
   CNT=$(echo $chrCNT | cut -d' ' -f1 )
   CHR=$(echo $chrCNT | cut -d' ' -f2 )
   ((CALLS+=CNT))
  done < <( egrep -v "(\t0|,0$|--)" $INFILE | cut $DELIM -f3 | uniq -c | $SED -e 's/[[:space:]]{1,}/ /g' -e 's/^ //' ) 
  echo CALLS,$CALLS 

  echo PCT_CALL,$(echo "scale=3;$CALLS*100/$SNPS"| bc)%
  echo PCT_NOCALL,$(echo "scale=3;$NOCALLS*100/$SNPS"| bc)%
  echo
}

function diffCALLS {

  DIFFS=0
  MATCH=0
  MISS=0
  DNAFL1="$1"
  DNAFL2="$2"
  local DELIM1=$3
  local DELIM2=$4

  echo
  echo "Difference in CALLS between $1 and $2"

  while read chrCNT
  do
    RSID="$( echo $chrCNT | cut -d, -f1 )"
    POS="$( echo $chrCNT | cut -d, -f2 )"
    CALL1="$( echo $chrCNT | cut -d, -f3 )"
    CALL2="$( egrep "\t$POS\t| $POS |,$POS,|$RSID[	 ,]" "$DNAFL2" | head -1 | cut $DELIM2 -f4 | $SED -e 's/[[:space:]]{1,}//g' -e 's/^ //' -e '/^0/d' )"
    # 'head -1 ' needed as AncestryDNA v3 use both:
    #  - rs193302985 AND rs527236043 for position 15043 on Chromosone 26 (mtDNA)
    #  While a 23AndMe V5 file has 1,757 duplicate mtDNA entries, under different rsid labels.
    if [ -z "$CALL2" ]
    then
        ((MISS+=1))
        if [ $MISSING -eq 1 ]
        then
          echo "$RSID [$POS] - missing in: $DNAFL2" 
          echo "entries in $DNAFL1 :"
          egrep "\t$POS\t| $POS |,$POS,|$RSID" "$DNAFL1"
          echo "entries in $DNAFL2 :"
          egrep "\t$POS\t| $POS |,$POS,|$RSID" "$DNAFL2"
          echo -------
        fi
    else
      if [ "$CALL1" != "$CALL2" ]
      then
        echo "$RSID [$POS] - differs :$CALL1:$CALL2:"
        echo "entries in $DNAFL1 :"
        egrep "\t$POS\t| $POS |,$POS,|$RSID" "$DNAFL1"
        echo "entries in $DNAFL2 :"
        egrep "\t$POS\t| $POS |,$POS,|$RSID" "$DNAFL2"
        echo -------
        ((DIFFS+=1))
      else
        ((MATCH+=1))
      fi
    fi
  done < <( egrep -v "(\t0|,0$|--)" "$DNAFL1" | cut $DELIM1 -f 1,3,4 | $SED -e 's/[[:space:]]{1,}/,/g' -e 's/^ //' )
  echo
  echo "Differences: $DIFFS"
  echo "Matches:     $MATCH"
  echo "Missing:     $MISS"
}

guess_deliminator $INFILE1
DELIM1="$DELIM"
countCalls "$INFILE1_mtDNA"
guess_deliminator $INFILE2
DELIM2="$DELIM"
countCalls "$INFILE2_mtDNA"
diffCALLS  "$INFILE1_mtDNA" "$INFILE2_mtDNA" "$DELIM1" "$DELIM2"
diffCALLS  "$INFILE2_mtDNA" "$INFILE1_mtDNA" "$DELIM2" "$DELIM1"

rm -f "$INFILE1_mtDNA" "$INFILE2_mtDNA"
exit 0
