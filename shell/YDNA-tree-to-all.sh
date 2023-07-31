#!/bin/bash
#
# Purpose: Attempt to combine and convert the ISOGG YDNA files from https://isogg.org/tree/index.html
# 
# Note: 
#   - Source Google sheets have a growing collection of comments / annotations, along with some unhelpful / incosistent foratting, that needs to be removed, as will blow the script
#   - the 'get_YDNA_trees.sh' and 'get_YDNA_rsid.sh' scrpts will attempt to download, strip and merge the ISOGG sheets into something usable by this script.
#   - AncestryDNA v2 + 23AndMe v5 appear to use the Build 37 positions
#   - TAKES and age - as made up as I ran into each inconsistency in the file, and processed in a manner the issue could be coded around (Needs a rewrite in Perl / Python)
#
#   - Output JSON mutation type:
# type 0     - transitions    - upper case (e.g., G->A)
# type 3     - deletions      - “del” 
# type 4     - insertions     - "ins"
#
# Author:  A.Robers 2023-07-24
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

# ------------
# Set to 0 to disable
DEBUG_RESTORE_INPUT=0    # DEBUGGING ONLY
DEBUG_MISSING_MUTES=0    # DEBUGGING ONLY
DEBUG_MERGE_FILES=1
DEBUG_TO_ANON=1
DEBUG_TO_JSON=1
# ------------
SED="gsed -E"                                              ; export SED

THIS_SCRIPT_NAME=$(basename $0)
THIS_DIR_NAME=$(dirname $0)
THIS_LIB_NAME="$(dirname $0)/DNA_HELPER_LIB.sh"
# ------------
BUILD=37
YDNA_SNPS="YDNA_SNPS.csv"
YDNA_RSIDS="YDNA_rsid_names-Build$BUILD.txt"
YDNA_MUTS="YDNA_rsid_mutations-Build$BUILD.csv"
YDNA_HAPGRP_MUTS="YDNA_HAPGRP_muts-Build$BUILD.csv"        ; export YDNA_HAPGRP_MUTS
YDNA_HAPGRP_MUTS_TMP="YDNA_HAPGRP_muts-Build$BUILD.tmp"    ; export YDNA_HAPGRP_MUTS_TMP
YDNA_RSID_MUTS="YDNA_rsid_muts-Build$BUILD.csv"
YDNA_BASE="YDNA_ISOGG_Haplogrp_Tree"
YDNA_HAPLOGRPS="$YDNA_BASE.haplogrps.txt"                  ; export YDNA_HAPLOGRPS
YDNA_TRUNK="$YDNA_BASE.TRUNK.csv"
YDNA_TRUNK_NESTED="$YDNA_BASE.Haplos.nested.csv"           ; export YDNA_TRUNK_NESTED
YDNA_TRUNK_MERGED="$YDNA_BASE.merged.csv"                  ; export YDNA_TRUNK_MERGED
YDNA_TRUNK_MERGED_TMP="$YDNA_BASE.merged.csv.tmp"
YDNA_TRUNK_MERGED_SAVED="$YDNA_TRUNK_MERGED.bak"

HAPLOS_JSON="$YDNA_BASE.json"
HAPLO_PAT="[a-zA-Z0-9~@-]+,"
PROC_HAPLO_CNT=0
# ----------------------------------

# CSV to JSON function
source $THIS_LIB_NAME

###################
# MAIN
###################

if [ $DEBUG_RESTORE_INPUT -ne 0 ]
then
  echo "-------------------"
  echo "Restore input files"
  if [ -f "$YDNA_TRUNK_MERGED_SAVED" -a -s "$YDNA_TRUNK_MERGED_SAVED" ]
  then
     cp $YDNA_TRUNK_MERGED_SAVED  $YDNA_TRUNK_MERGED || (echo "Error restore of $YDNA_TRUNK_MERGED_SAVED to $YDNA_TRUNK_MERGED failed"; exit 2)
     echo "Restored: $YDNA_TRUNK_MERGED_SAVED to  $YDNA_TRUNK_MERGED"
  else
     echo "Backup missing: $YDNA_TRUNK_MERGED_SAVED"
     echo
  fi
  echo "-------------------"
fi

if [ $DEBUG_MISSING_MUTES -ne 0 ]
then
  echo "Check if lacking mutations:"
  perl -e 'my @lines=`cat $ENV{YDNA_HAPLOGRPS}`; my @mutes=`cat $ENV{YDNA_HAPGRP_MUTS}`; my $cnt=0; my $foundCnt=0; my $diffCnt=0; my $tweakCnt=0; my $missing=1; my $lnCnt=$#lines+1; my $baseHaplo; sub check_mutes($) { my $checkHaplo; ($checkHaplo) = @_; foreach my $mut (@mutes) { if ( $mut =~ m/^$checkHaplo,/ ) { $foundCnt++; $missing=0; last; } } } foreach my $line (@lines) { $line=~s/\n//; $cnt++; print STDERR "Checking : $cnt    of $lnCnt  -  Found: $foundCnt  -   Missing: $diffCnt\r"; $baseHaplo=$line; $baseHaplo=~s/@//g; if ( $baseHaplo ne $line ) { print STDERR "\nProcessing duplicate: $line\n";} $missing=1; check_mutes $baseHaplo; if ( $missing == 1 ) { if ( $baseHaplo =~ m/ or / ) { $try1=$baseHaplo; $try1=~s/ or .*$//; check_mutes $try1; if ( $missing == 1 ) { $try2=$baseHaplo; $try2=~s/^.* or //; check_mutes $try2; } if ( $missing == 0 ) { $tweakCnt++; } } if ( $missing == 1 ) { $diffCnt++; print STDERR "\nError - missing mutations: $line\n"; } } } print STDERR "\nFound: $foundCnt\nTweaked: $tweakCnt\nMissing: $diffCnt\n";'
  echo -----------------
fi

if [ $DEBUG_MERGE_FILES -ne 0 ]
then 
  # Merge Haplogroup tree list with the mutations
  if [ -f "$YDNA_TRUNK_MERGED" -a -s "$YDNA_TRUNK_MERGED" -a -f "$YDNA_HAPGRP_MUTS" -a -s "$YDNA_HAPGRP_MUTS" ]
  then
    cnt=0
    found=0
    dups=0
    rm -f "$YDNA_TRUNK_MERGED.tmp"
    cp $YDNA_TRUNK_MERGED $YDNA_TRUNK_NESTED
    echo "-------------------"
    echo "Checking nesting dosen't increase by more than one - takes a while !!!!"

    perl -e 'my @lines=`cat $ENV{YDNA_TRUNK_NESTED}`; my $lineLen=0; my $lastLen=0; my $lastLn=""; my $nestCnt=0; my $fillCnt=0; my $lnCnt=$#lines+1; my $ln, $newLn, $cmd; foreach my $line (@lines) { $nestCnt++; print STDERR "Checking: $nestCnt    of $lnCnt\r"; $ln=$line; $ln=~s/^([,]*)[^,].*$/\1/; $lineLen=$#ln+1; $diff=$lineLen-$lastLen; if ( $diff >  1 ) { printf "Error: line: $nestCnt - $lastLen - $lineLen\n$lastLn\n$line\n---------\n"; if ( $diff == 2 ) { $fillCnt++; $newLn=substr $line, 1, -1; print "inserting between  - $newLn\n"; $cmd = "$ENV{SED} -i -e \"/$lastLn/a $newLn\" $ENV{YDNA_TRUNK_NESTED}"; print "$cmd\n"; system($cmd); } } $lastLn=$line; $lastLen=$lineLen; } print STDERR "Checked: $nestCnt\nBack filled: $fillCnt\n";'

    echo "nesting checked"
    echo "-------------------"
    echo "merging the haplogroup tree with the mutations files - takes a while"

    perl -e 'my @lines = `cat $ENV{YDNA_TRUNK_MERGED}`; my @mutes=`cat $ENV{YDNA_HAPGRP_MUTS}`; my $lnCnt=$#lines+1; my $cnt=0; my $dupCnt=0; my $tweakCnt=0; my $missCnt=0; my $updCnt=0; my $missing=1; my $thisHaploGrp, $baseHaplo, $mutsLn; $ln; sub check_mutes($) { my $checkHaplo; ($checkHaplo) = @_; foreach my $mut (@mutes) { if ( $mut =~ m/^$checkHaplo,/ ) { $foundCnt++; $missing=0; $mutsLn=$mut; $mutsLn=~s/^[^,]*,//; $mutsLn=~s/\n//; last; } } } foreach my $line (@lines) { $ln=$line; $cnt++; print STDERR "Joining: $cnt  of $lnCnt\r"; $thisHaploGrp=$ln; $thisHaploGrp=~s/^,*//; $thisHaploGrp=~s/,.*$//; $thisHaploGrp=~s/\n//; $baseHaplo=$thisHaploGrp; $baseHaplo=~s/@//g; if ( $thisHaploGrp ne $baseHaplo) {$dupCnt++; print STDERR "Processing duplicate: $thisHaploGrp : $baseHaplo\n";} $missing=1; check_mutes $baseHaplo; if ( $missing == 1 ) { if ( $baseHaplo =~ m/ or / ) { $try1=$baseHaplo; $try1=~s/ or .*$//; check_mutes $try1; if ( $missing == 1 ) { $try2=$baseHaplo; $try2=~s/^.* or //; check_mutes $try2; } if ( $missing == 0 ) { $tweakCnt++; } } if ( $missing == 1 ) { $diffCnt++; print STDERR "\nError - missing mutations for: $line\n"; } } if ( $missing == 0 ) { $ln=~s/^(,*[^,]+).*$/\1/; $ln=~s/\n/,/; $line=$ln.$mutsLn; $updCnt++; } else { $missCnt++; } } open(FH, ">", "$ENV{YDNA_HAPGRP_MUTS_TMP}") or die $!; foreach (@lines) { print FH "$_\n"; } close(FH); print STDERR "Joined: $cnt\nDuplicates: $dupCnt\n"; print STDERR "\nRead: $cnt\nMatched and updated: $updCnt\nHad to tweak to match: $tweakCnt\nMissing a mutation: $missCnt\nDuplicates encountered: $dupCnt\n";'

    $SED -i -e '/^$/d' $YDNA_HAPGRP_MUTS_TMP 
    mv $YDNA_HAPGRP_MUTS_TMP $YDNA_TRUNK_MERGED
    echo "-------------------"
  fi
fi

if [ $DEBUG_TO_ANON -ne 0 ]
then
  anon=$(cat $YDNA_TRUNK_MERGED | egrep -n -v -E  '^,*[^,]+'| wc -l) ; ((anon+=0))
  echo "Anonymous Haplogroups - $anon"
  if [ "$anon" -ne 0 ]
  then
    echo "-------------------"
    echo fix anonymous haplogroups
    while read lnNUM
    do
      start=$lnNUM; ((start-=1)); 
      end=$lnNUM;  ((end+=1));
      echo $lnNum:$start:$end
      lookup=$($SED -n -e "$start,$start p" $YDNA_TRUNK_MERGED | $SED -e 's/^,*//'  -e 's/,.*$//')
      if [ "$lookup" != "" ]
      then 
        cnt=$(grep -c "$lookup," $YDNA_HAPGRP_MUTS); ((cna+=0))
        lln=$(grep -n "$lookup," $YDNA_HAPGRP_MUTS | cut -d: -f 1); ((ln+=0))
        echo $lookup - $cnt - $lln
        lstart=$lln; ((lstart+=0))
        found=$($SED -n -e "$lstart,$lstart p" $YDNA_HAPGRP_MUTS | $SED -e 's/^,*//'  -e 's/,.*$//')
        if [ "$found" != "$lookup" ]
        then
          echo $SED -i -e '$lnNUM,$lnNUM s/$/$found/' $YDNA_TRUNK_MERGED
        else
          echo "WARNING: Duplicate Haplogroup - $lookup"
        fi
      fi
    done < <(cat $YDNA_TRUNK_MERGED | egrep -n -v -E '^,+[^,]+' | cut -d: -f 1)
  fi
fi

# No mutation for
echo "-------------------"
echo "No defining mutations for:"
egrep -v ']$' "$YDNA_TRUNK_MERGED"
echo "fixing mutationless haplogroups"
$SED -i -e '/[],]$/! s/$/,/' "$YDNA_TRUNK_MERGED"

if [ $DEBUG_TO_JSON -ne 0 ]
then
  if [ -f "$YDNA_TRUNK_MERGED" -a -s "$YDNA_TRUNK_MERGED" ]
  then
    echo "-------------------"
    echo converting to JSON
    ls -l "$YDNA_TRUNK_MERGED"
    #Count leading commas (,) to work out the maximim depth of the tree
    MAX_DEPTH=0
    ((MAX_DEPTH+=0+$($SED -e "s/[^,].*$//g" "$YDNA_TRUNK_MERGED" | sort | uniq | tail -1 | wc -c)))

    HAPLOGRPS=$(cat "$YDNA_TRUNK_MERGED" | wc -l)
    echo "HAPLOGRPS=$HAPLOGRPS - MAX_DEPTH=$MAX_DEPTH"

    if [ $MAX_DEPTH -ne 0 -a "$YDNA_TRUNK_MERGED" != "" ]
    then
      # Stop Bash's array logic blowin up on encountering a SPACE
      cp $YDNA_TRUNK_MERGED  $YDNA_TRUNK_MERGED_TMP
      $SED -i -e 's/[ ]+/§/g' $YDNA_TRUNK_MERGED 
      # Produce JSON file
      echo "{\"ISOGG-YDNA-BUILD-$BUILD\":[" > "$HAPLOS_JSON"
      to_JSON_array "START" "END" "0" "$HAPLOGRPS" "$MAX_DEPTH" "$YDNA_TRUNK_MERGED" "$HAPLOS_JSON" "$HAPLO_PAT" "$PROC_HAPLO_CNT"
      echo ']}' >> "$HAPLOS_JSON"
      echo "Written: $PROC_HAPLO_CNT"

      #Tidy - remove blank lines, empty "children" arrays, and add some other new lines
      $SED -i -e 's/§/ /g' -e '/^$/d' -e 's/\n//g' -e 's/,{2,}/,/g' -e 's/"children":[][]{2,}//g' -e 's/[[:space:],]+([]}])/\1/g' -e 's/]/]\n/g' -e 's/\{/\n{/g'  "$HAPLOS_JSON" 
      echo "SED retrun code $?"
      echo "checking JSON with a: python -m json.tool YDNA_ISOGG_Haplogrp_Tree.json > /dev/null"
      python -m json.tool YDNA_ISOGG_Haplogrp_Tree.json > /dev/null
      echo "PYTHON retrun code $?"
      mv $YDNA_TRUNK_MERGED_TMP $YDNA_TRUNK_MERGED
   fi
  else
    echo "No FILE $YDNA_TRUNK_MERGED"
  fi 
fi 
echo "----------- Done ------------"

#----------
