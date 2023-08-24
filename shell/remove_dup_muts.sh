#!/bin/sh
# Purpose - remove duplicate SNP Mutations within Haplogroups, in a JSON file
#
# Author:  A.Robers 2023-08-01
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

SED="sed -E" ; gsed --version 2>/dev/null 1>/dev/null && SED="gsed -E"
location=$(dirname $0)
fileName="YDNA_MINI_Haplogrp_Tree.json"
perlScript="$location/perl_snippets/ydna_remove_dup_mutations.pl"

if [ "$1" != "" -a -f "$1" ]
then 
  fileName=$1
else
  echo "Error - no JSON file specified"
  exit 1
fi

echo $fileName
echo $perlScript

grep posStart $fileName > tmp_all_muts
$SED -E -i -e 's/^[ ]*\{"posStart":"//' -e 's/","a.*$//' tmp_all_muts 
sort tmp_all_muts | uniq -d > dup_posStart-$fileName
wc -l dup_posStart-$fileName

export fileName
echo "Running perl $perlScript"
perl $perlScript

echo "Testing the JSON, via a 'python3 -m json.tool $fileName'"
python3 -m json.tool $fileName >/dev/null
echo "RC - $?"

rm -f dup_posStart-$fileName
