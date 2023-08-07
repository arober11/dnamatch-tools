#!/bin/bash
#
# Purpose: Download the latest ISOGG YDNA SNP list, 
#          Correct for a few anomalies in the list,
#          Extract the rsid names, mutation names and the Build 37 SNP positions to a series of files:
#            - YDNA_SNPS.csv - downloaded file with any:
#               -- '#REF!' swapped for C1a2b1b2 
#               -- A9832,2 swapped for A9832.2
#               -- ; removed
#               -- 'Notes' blanked
#               -- Haplogroup names with a spave between the name and a '~' suffix removed
#               -- 'Freq. Mut. SNP in ' removed from Haplogroup names
#            - Outputs: 
#              -- YDNA_SNPS.csv                               - Downloaded file with above alterations
#              -- YDNA_rsid_mutations-Build37.csv             - list of rsid names in file, e.g.
#                rs,numbers
#                rs1000104620,G->A
#                rs1000104755,C->A
#                ...
#              -- YDNA_rsid_muts-Build37.csv                  - list of rsids, with mutation and mutation name used, e.g.
#                rs,numbers,Name
#                rs1000104620,G->A,Z12464
#                rs1000104755,C->A,FGC1864
#                rs1000104755,C->A,Y2087
#                ...
#              -- YDNA_HAPGRP-Build37.SNP_Positions_used.txt  - list of Y chromosome, build 37, range expanded, positions used, e.g.
#                10000350
#                10000477
#                10000888
#                ...
#              -- YDNA_HAPGRP_muts-Build37.csv                - list of muations use in a hybrid CSV and JSON format, eg.
#                 A,"mutations":[{"posStart":"14814060","ancestral":"G","descendant":"C","type":"0","display":"G14814060C","label":"M171","alias":"CTS10804","optional":"N"},
#                                {"posStart":"21868776","ancestral":"A","descendant":"C","type":"0","display":"A21868776C","label":"M59","alias":"CTS1816","optional":"Y"},
#                                {"posStart":"6851661","ancestral":"C","descendant":"T","type":"0","display":"C6851661T","label":"L1100","alias":"V1143","optional":"Y"}]
#                 A0,"mutations":[{"posStart":"14001289","ancestral":"G", ...
#              -- YDNA_HAPGRP_muts-Build37.json               - above file in just JSON format, e.g.
#                 [{"haploGrp":"A","mutations":[{"posStart":"14814060","ancestral":"G","descendant":"C","type":"0","display":"G14814060C","label":"M171","alias":"CTS10804","optional":"N"},
#                                               {"posStart":"21868776","ancestral":"A","descendant":"C","type":"0","display":"A21868776C","label":"M59","alias":"CTS1816","optional":"Y"},
#                                               {"posStart":"6851661","ancestral":"C","descendant":"T","type":"0","display":"C6851661T","label":"L1100","alias":"V1143","optional":"Y"}]}
#                 ...
#                 ]
# 
# Notes: 
#      - AncestryDNA v2 + 23AndMe v5 appear to use the Build 37 positions
#      - Mutation code types output
#       type 0     - transitions    - upper case (e.g., G->A)
#       type 3     - deletions      - “del” 
#       type 4     - insertions     - "ins"
#
# Author:  A.Robers 2023-07-24
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

BUILD=37

YDNA_SNPS="YDNA_SNPS.csv"
YDNA_RSIDS="YDNA_rsid_names-Build$BUILD.txt"
YDNA_MUTS="YDNA_rsid_mutations-Build$BUILD.csv"
YDNA_HAPGRP_SNPS_POS="YDNA_HAPGRP-Build$BUILD.SNP_Positions_used.txt"
YDNA_HAPGRP_MUTS="YDNA_HAPGRP_muts-Build$BUILD.csv"     ; export YDNA_HAPGRP_MUTS
YDNA_HAPGRP_MUTS_TMP="YDNA_HAPGRP_muts-Build$BUILD.tmp"
YDNA_HAPGRP_MUTS_JSON="YDNA_HAPGRP_muts-Build$BUILD.json"
YDNA_RSID_MUTS="YDNA_rsid_muts-Build$BUILD.csv"
SED="gsed -E"

# Obtain latest Google sheet
# COLS: Name,Subgroup Name,Alternate Names,rs numbers,Build 37 Number,Build 38 Number,Mutation Info
wget https://docs.google.com/spreadsheets/d/1UY26FvLE3UmEmYFiXgOy0uezJi_wOut-V5TD0a_6-bE/export?format=csv#gid=193439206 -O "$YDNA_SNPS"
echo "Downloaded: $YDNA_SNPS"

if [ -f "$YDNA_SNPS" ]
then
  dos2unix $YDNA_SNPS 
  rm -f $YDNA_RSIDS $YDNA_MUTS $YDNA_HAPGRP_MUTS $YDNA_RSID_MUTS

  #Tidy a couple of Haplogroup names
  $SED -i -e 's/#REF!/C1a2b1b2/' -e 's/^"A9832,2"/A9832.2/' -e 's/^",//' -e 's/["]//g' -e 's/; /-/g' -e 's/[ ]*\(Notes\)//' -e 's/ ~/~/g' -e 's/Freq. Mut. SNP in //' $YDNA_SNPS
  echo "Tidied: $YDNA_SNPS"

  #Remove square brackets
  #$SED -i -e 's/(,[^ ]+) [[]([A-Za-z0-9~]+)[]](~*,)/\1-\2\3/' -e 's/[[]([A-Za-z0-9 ]*)[]]/#\1#/' -e $YDNA_SNPS

  # Extract the SNP positions used
  cut -s -d, -f5   $YDNA_SNPS | sort -u | $SED -e 's/[-: ]/\n/g' > $YDNA_HAPGRP_SNPS_POS
  while read range
  do
    start=$(echo $range | $SED -e 's/\.\./,/' |  cut -d, -f1)
    end=$(echo $range | $SED -e 's/\.\./,/' |  cut -d, -f2)
    if [ $start -gt $end ] 
    then
      echo "ERROR: invalidi SNP range: $range"
    else
      vals=""
      for ((i=$start; i<=$end; i++))
      do
        vals="$vals$i\n"
      done
      range=$(echo $range | sed 's/\./\\./g')
      $SED -i -e "s/$range/$vals/" $YDNA_HAPGRP_SNPS_POS
    fi
  done < <(grep '\.\.' $YDNA_HAPGRP_SNPS_POS)
  $SED -i -e '/^$/d' -e '/[0-9]+/!d' $YDNA_HAPGRP_SNPS_POS
  sort -u $YDNA_HAPGRP_SNPS_POS > $YDNA_HAPGRP_SNPS_POS.tmp
  mv $YDNA_HAPGRP_SNPS_POS.tmp $YDNA_HAPGRP_SNPS_POS
  echo "Written: $YDNA_HAPGRP_SNPS_POS"

  #Stick the columns in a JSON like structure and sort on haplogroup name
  $SED -e '/->/!d' -e 's/^[[:space:]]+//g' -e '/^$/d' -e 's/->/,/' $YDNA_SNPS | perl -F, -ane '$names="$F[0]" ; $names =~ s/[-]+$// ; $type=0 ; $rsid= "" ; if ($F[2] ne "") { $alias=",\"alias\":\"$F[2]\""; } if ($F[3] ne "") { $rsid=",\"rsid\":\"$F[3]\""; } $F[7] =~ s/\n//g ; $descendant=$F[7] ; if($descendant =~ /^del/){ $descendant="";$type=3; } if($descendant =~ /^ins/){ $descendant="";$type=4; } print "$F[1],\"mutations\":[{\"posStart\":\"$F[4]\",\"ancestral\":\"$F[6]\",\"descendant\":\"$descendant\",\"type\":\"$type\",\"display\":\"$F[6]$F[4]$F[7]\",\"label\":\"$names\"$alias$rsid}]\n";' | sort -t, -k1 | $SED -e 's/\t//g' > $YDNA_HAPGRP_MUTS
  echo "Written: $YDNA_HAPGRP_MUTS"
  # For the mutations with an rsid name,  print with the associated mutation name, and change, in rsid Order
  cut -s -d, -f1,4,7 $YDNA_SNPS | $SED -e 's/^[[:space:]]+//g' -e '/^$/d' -e '/^,/d' -e '/,,/d' | grep 'rs' | sed 's/,/ /g' | perl -ane 'print "$F[1],$F[2],$F[0]\n"' | sort -t, -k1,3 -u > $YDNA_RSID_MUTS
  echo "Written: $YDNA_RSID_MUTS"
  # Extract just the RSID numbers
  cut -s -d, -f1   $YDNA_RSID_MUTS | sort -u > $YDNA_RSIDS
  echo "Written: $YDNA_RSIDS"
  # Extract the RSID numbers and mutation names
  cut -s -d, -f1,2 $YDNA_RSID_MUTS | sort -t, -k1,2 -u > $YDNA_MUTS
  echo "Written: $YDNA_MUTS"
else
  echo "Error: No file"
  exit 1
fi

# Merge the mutations for a haplogroup into a single line
perl -e 'my @lines = `cat $ENV{YDNA_HAPGRP_MUTS}`; my $haploGrp="*"; my $thisHaploGrp; my $opt; my $cnt=0; foreach my $ln (@lines) { $cnt++; $thisHaploGrp=$ln; $thisHaploGrp=~s/^([^,]+),.*/\1/; if ($thisHaploGrp =~ m/~$/) { $opt="Y"; } else { $opt="N"; } chop $thisHaploGrp; chop $ln; chop $ln; $ln=~s/.$/,\"optional\":\"/; if ($haploGrp eq "*"){ print "$ln$opt\"\}"; } else { if ($thisHaploGrp ne $haploGrp) { print "]\n"."$ln$opt\"\}"; } else { $ln =~ s/^[^{]*({.*)/\1Y"}/; print ",$ln"; } } $haploGrp=$thisHaploGrp; } print "]\n";' > $YDNA_HAPGRP_MUTS_TMP

mv $YDNA_HAPGRP_MUTS_TMP $YDNA_HAPGRP_MUTS
echo "Written: $YDNA_HAPGRP_MUTS"

# Convert to an anonymous JSON array  ( can validate with something like: ' python -m json.tool YDNA_HAPGRP_muts-Build37.json ' )
gsed -E -e 's/^/,{"haploGrp":"/' -e 's/(,"mutations")/"\1/' -e 's/$/}/' $YDNA_HAPGRP_MUTS > $YDNA_HAPGRP_MUTS_JSON
gsed -E -i -e '1,1s/^,/[/' $YDNA_HAPGRP_MUTS_JSON
echo ']' >> $YDNA_HAPGRP_MUTS_JSON
echo "Written: $YDNA_HAPGRP_MUTS_JSON"

while read file 
do
  wc -l $file
done < <(ls $YDNA_SNPS $YDNA_RSIDS $YDNA_MUTS $YDNA_RSID_MUTS $YDNA_HAPGRP_MUTS)

