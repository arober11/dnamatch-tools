#!/bin/bash
#
# Purpose: Obtain the latest ISOGG YDNA SNP list and extract the rsid names
# 
# Note: AncestryDNA v2 + 23AndMe v5 appear to use the Build 37 positions
#
# type 0     - transitions    - upper case (e.g., G->A)
# type 3     - deletions      - “del” 
# type 4     - insertions     - "ins"
#
# Author:  A.Robers 2023-07-24
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

BUILD=37

YDNA_SNPS="YDNA_SNPS.csv"
YDNA_RSIDS="YDNA_rsid_names-Build$BUILD.txt"
YDNA_MUTS="YDNA_rsid_mutations-Build$BUILD.csv"
YDNA_HAPGRP_MUTS="YDNA_HAPGRP_muts-Build$BUILD.csv"
YDNA_RSID_MUTS="YDNA_rsid_muts-Build$BUILD.csv"
SED="gsed -E"

# Obtain latest Google sheet
# COLS: Name,Subgroup Name,Alternate Names,rs numbers,Build 37 Number,Build 38 Number,Mutation Info
wget https://docs.google.com/spreadsheets/d/1UY26FvLE3UmEmYFiXgOy0uezJi_wOut-V5TD0a_6-bE/export?format=csv#gid=193439206 -O "$YDNA_SNPS"


if [ -f "$YDNA_SNPS" ]
then
  dos2unix $YDNA_SNPS 
  rm -f $YDNA_RSIDS $YDNA_MUTS $YDNA_HAPGRP_MUTS $YDNA_RSID_MUTS
  $SED -e '/->/!d' -e 's/^[[:space:]]+//g' -e '/^$/d' -e 's/->/,/' $YDNA_SNPS | perl -F, -ane '$name="$F[0]-$F[1]-$F[2]" ; $name =~ s/[-]+$// ; $type=0 ; $rsid= "" ; if ($F[3] ne "") { $rsid="\"rsid\":\"$F[3]\""; } $F[7] =~ s/\n//g ; $descendant=$F[7] ; if($descendant =~ /^del/){$descendant="";$type=3;} if($descendant =~ /^ins/){$descendant="";$type=4;} print "$name,mutations\":[{\"posStart\":\"$F[4]\",\"ancestral\":\"$F[6]\",\"descendant\":\"$descendant\",\"type\":\"$type\",\"display\":\"$F[6]$F[4]$F[7]\",$rsid}]\n";' > $YDNA_HAPGRP_MUTS
  cut -s -d, -f1,4,7 $YDNA_SNPS   | $SED -e 's/^[[:space:]]+//g' -e '/^$/d' -e '/^,/d' -e '/,,/d' | grep 'rs' | sed 's/,/ /g' | perl -ane 'print "$F[1],$F[2],$F[0]\n"' | sort -k 1,3 -u > $YDNA_RSID_MUTS
  cut -s -d, -f1   $YDNA_RSID_MUTS | sort -u > $YDNA_RSIDS
  cut -s -d, -f1,2 $YDNA_RSID_MUTS | sort -k1,2 -u > $YDNA_MUTS
else
  echo "Error: No file"
  exit 1
fi

while read file 
do
  wc -l $file
done < <(ls $YDNA_SNPS $YDNA_RSIDS $YDNA_MUTS $YDNA_RSID_MUTS $YDNA_HAPGRP_MUTS)

