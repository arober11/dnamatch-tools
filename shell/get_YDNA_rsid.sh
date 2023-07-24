#!/bin/bash
#
# Purpose: Obtain the latesti ISOGG YDNA SNP list and extract the rsid names
#
# Author:  A.Robers 2023-07-24
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

BUILD=38

YDNA_SNPS="YDNA_SNPS.csv"
YDNA_RSIDS="YDNA_rsid_names-Build$BUILD.txt"
YDNA_MUTS="YDNA_rsid_mutations-Build$BUILD.csv"
YDNA_HAPGRP_MUTS="YDNA_HAPGRP_rsid_muts-Build$BUILD.csv"
SED="gsed -E"

wget https://docs.google.com/spreadsheets/d/1UY26FvLE3UmEmYFiXgOy0uezJi_wOut-V5TD0a_6-bE/export?format=csv#gid=193439206 -O "$YDNA_SNPS"

if [ -f "$YDNA_SNPS" ]
then
  dos2unix $YDNA_SNPS 
  cut -s -d, -f1,4,7 $YDNA_SNPS   | $SED -e 's/^[[:space:]]+//g' -e '/^$/d' -e '/^,/d' -e '/,,/d' | grep 'rs' | sed 's/,/ /g' | perl -ane 'print "$F[1],$F[2],$F[0]\n"' | sort -k 1,3 -u > $YDNA_HAPGRP_MUTS
  cut -s -d, -f1   $YDNA_HAPGRP_MUTS | sort -u > $YDNA_RSIDS
  cut -s -d, -f1,2 $YDNA_HAPGRP_MUTS | sort -k1,2 -u > $YDNA_MUTS
else
  echo "Error: No file"
  exit 1
fi

while read file 
do
  wc -l $file
done < <(ls $YDNA_SNPS $YDNA_RSIDS $YDNA_MUTS $YDNA_HAPGRP_MUTS)
