#!/bin/bash
#
# Purpose:Attempt to combine and convert the ISOGG YDNA files from https://isogg.org/tree/index.html
# 
# Note: 
#   - Source Google sheets have a growing collection of comments / annotations, along with some unhelpful / incosistent foratting, that needs to be removed, as will blow the script
#   - the 'get_YDNA_trees.sh' will attempt to download, strip and merge the ISOGG sheets into something usable by this script.
#
# Author:  A.Robers 2023-07-24
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

# ------------
# Set to 0 to disable
DEBUG_DOWNLOAD_FILES=0
DEBUG_STRIP_FILES=1
DEBUG_TIDY_FILES=1
DEBUG_MISSING_MUTES=0   # Not Needed
DEBUG_REMOVE_DUP=1
# ------------
SED="gsed -E"

THIS_SCRIPT_NAME=$(basename $0)
THIS_DIR_NAME=$(dirname $0)
THIS_LIB_NAME="$(dirname $0)/DNA_HELPER_LIB.sh"
# ------------
BUILD=37
YDNA_SNPS="YDNA_SNPS.csv"
YDNA_RSIDS="YDNA_rsid_names-Build$BUILD.txt"
YDNA_MUTS="YDNA_rsid_mutations-Build$BUILD.csv"
YDNA_HAPGRP_MUTS="YDNA_HAPGRP_muts-Build$BUILD.csv"
YDNA_HAPGRP_MUTS_TMP="YDNA_HAPGRP_muts-Build$BUILD.tmp"
YDNA_RSID_MUTS="YDNA_rsid_muts-Build$BUILD.csv"
YDNA_BASE="YDNA_ISOGG_Haplogrp_Tree"
YDNA_HAPLOGRPS="$YDNA_BASE.haplogrps.txt"
YDNA_TRUNK="$YDNA_BASE.TRUNK.csv"
YDNA_TRUNK_NESTED="$YDNA_BASE.Haplos.nested.csv"
YDNA_TRUNK_MERGED="$YDNA_BASE.merged.csv"
YDNA_HAPGRP_A="$YDNA_BASE.A.csv"
YDNA_HAPGRP_B="$YDNA_BASE.B.csv"
YDNA_HAPGRP_C="$YDNA_BASE.C.csv"
YDNA_HAPGRP_D="$YDNA_BASE.D.csv"
YDNA_HAPGRP_E="$YDNA_BASE.E.csv"
YDNA_HAPGRP_F="$YDNA_BASE.F.csv"
YDNA_HAPGRP_G="$YDNA_BASE.G.csv"
YDNA_HAPGRP_H="$YDNA_BASE.H.csv"
YDNA_HAPGRP_I="$YDNA_BASE.I.csv"
YDNA_HAPGRP_J="$YDNA_BASE.J.csv"
YDNA_HAPGRP_K="$YDNA_BASE.K.csv"
YDNA_HAPGRP_L="$YDNA_BASE.L.csv"
YDNA_HAPGRP_M="$YDNA_BASE.M.csv"
YDNA_HAPGRP_N="$YDNA_BASE.N.csv"
YDNA_HAPGRP_O="$YDNA_BASE.O.csv"
YDNA_HAPGRP_P="$YDNA_BASE.P.csv"
YDNA_HAPGRP_Q="$YDNA_BASE.Q.csv"
YDNA_HAPGRP_R="$YDNA_BASE.R.csv"
YDNA_HAPGRP_S="$YDNA_BASE.S.csv"
YDNA_HAPGRP_T="$YDNA_BASE.T.csv"
# ----------------------------------

function download_files {

# Obtain latest ISOGG YDNA Haplogroup Google sheets

# SNPS
# COLS: Name,Subgroup Name,Alternate Names,rs numbers,Build 37 Number,Build 38 Number,Mutation Info
wget https://docs.google.com/spreadsheets/d/1UY26FvLE3UmEmYFiXgOy0uezJi_wOut-V5TD0a_6-bE/export?format=csv#gid=193439206 -O "$YDNA_SNPS"

# Haplogroups:	
# Haplogroup - TRUNK 
echo Downloading - "$YDNA_TRUNK"
wget https://docs.google.com/spreadsheets/d/1Y0GXjhazYa46u0EpPA9b0Y0RVWuh5lDzww_o979mbjQ/export?format=csv#gid=1904113265 -O "$YDNA_TRUNK"
# Haplogroup - A 
echo Downloading - "$YDNA_HAPGRP_A"
wget https://docs.google.com/spreadsheets/d/12EwwUDZbwbVx_LswB0PSCS49Zrnb0jnuMS3PWf4gcss/export?format=csv#gid=0 -O "$YDNA_HAPGRP_A"
# Haplogroup - B
echo Downloading - "$YDNA_HAPGRP_B"
wget https://docs.google.com/spreadsheets/d/1Pe_sTKuN4dfEQ92BD5Tm2CZinoOXnDKPIR1KAMkj12Y/export?format=csv#gid=1432592773 -O "$YDNA_HAPGRP_B"
# Haplogroup - C
echo Downloading - "$YDNA_HAPGRP_C"
wget  https://docs.google.com/spreadsheets/d/1XTMjVnybYFfj4mL1UwzDACTy9fZoJdCbENwdfvKWETQ/export?format=csv#gid=928240711 -O "$YDNA_HAPGRP_C"
# Haplogroup - D
echo Downloading - "$YDNA_HAPGRP_D"
wget https://docs.google.com/spreadsheets/d/1QBUFZl03X92qNN61lQ8VtIKwbBMeuBzvqXQ47IQPBps/export?format=csv#gid=437997455 -O "$YDNA_HAPGRP_D"
# Haplogroup - E
echo Downloading - "$YDNA_HAPGRP_E"
wget https://docs.google.com/spreadsheets/d/1CoAiWmAyEj6mKyQ9ATuEc7_Z_mxC2-gjU5JYkMkkRcE/export?format=csv#gid=i149564181 -O "$YDNA_HAPGRP_E"
# Haplogroup - F
echo Downloading - "$YDNA_HAPGRP_F"
wget https://docs.google.com/spreadsheets/d/1rETfmdGlcVwW1uQFjOx3BczkBuTivALcRD2YpxskjsI/export?format=csv#gid=375536220 -O "$YDNA_HAPGRP_F"
# Haplogroup - G
echo Downloading - "$YDNA_HAPGRP_G"
wget https://docs.google.com/spreadsheets/d/111Iqo0vRt-sr8MJT7pavKQ0qoWxYSc1P7hnMRq3GijU/export?format=csv#gid=0 -O "$YDNA_HAPGRP_G"
# Haplogroup - H
echo Downloading - "$YDNA_HAPGRP_H"
wget https://docs.google.com/spreadsheets/d/1N8C_6XmFohea_U_LUj7SfoJE8i-HuXFraCDqduapxvQ/export?format=csv#gid=262668195 -O "$YDNA_HAPGRP_H"
# Haplogroup - I
echo Downloading - "$YDNA_HAPGRP_I"
wget https://docs.google.com/spreadsheets/d/1TH2aUkqHUV8coChJOCxGeXMg6QdyRTPthWOpW8IyCJE/export?format=csv#gid=198726360 -O "$YDNA_HAPGRP_I"
# Haplogroup - J
echo Downloading - "$YDNA_HAPGRP_J"
wget https://docs.google.com/spreadsheets/d/1CODtnxuvXZp1uxbJY53KUy0uT3ranaqE7N-nuqpAX-E/export?format=csv#gid=1603190133 -O "$YDNA_HAPGRP_J"
# Haplogroup - K
echo Downloading - "$YDNA_HAPGRP_K"
wget https://docs.google.com/spreadsheets/d/1Hdb2M_V0JXcNsCOnM9IWA0yJiIesQpI_GnacTwbw_JM/export?format=csv#gid=0 -O "$YDNA_HAPGRP_K"
# Haplogroup - L
echo Downloading - "$YDNA_HAPGRP_L"
wget https://docs.google.com/spreadsheets/d/1CVvTDEzl1h0NvYgouk5K_D-JskoqUt2NBgQ2BqXA5U0/export?format=csv#gid=441543865 -O "$YDNA_HAPGRP_L"
# Haplogroup - M
echo Downloading - "$YDNA_HAPGRP_M"
wget https://docs.google.com/spreadsheets/d/1SqGHOX7gHToHTn_wr6mWkxh-ymL7RYxIyRs9SnI1bIg/export?format=csv#gid=0 -O "$YDNA_HAPGRP_M"
# Haplogroup - N
echo Downloading - "$YDNA_HAPGRP_N"
wget https://docs.google.com/spreadsheets/d/1ju7oNjHjMrgMUB1xXmr0EaaL-RctJJ8FreUPM2DzuBY/export?format=csv#gid=692817756 -O "$YDNA_HAPGRP_N"
# Haplogroup - O
echo Downloading - "$YDNA_HAPGRP_O"
wget https://docs.google.com/spreadsheets/d/1ZeJnMPDMQ1TjwP2QGyayfULPosn0Qdxc9ozWZJ_pDWE/export?format=csv#gid=57047053 -O "$YDNA_HAPGRP_O"
# Haplogroup - P
echo Downloading - "$YDNA_HAPGRP_P"
wget https://docs.google.com/spreadsheets/d/1YEiLNcXDm1-n_oULL9QSl6AvyO4jJLTG5zVki5IhBUk/export?format=csv#gid=0 -O "$YDNA_HAPGRP_P"
# Haplogroup - Q
echo Downloading - "$YDNA_HAPGRP_Q" 
wget https://docs.google.com/spreadsheets/d/1bcVNnQ5y4tkY5NL4SuxSTO4ofR1ymh_1Joc9DgCYnoY/export?format=csv#gid=1268900795 -O "$YDNA_HAPGRP_Q"
# Haplogroup - R
echo Downloading - "$YDNA_HAPGRP_R"
wget https://docs.google.com/spreadsheets/d/1JvXoBCBBk42DIF7BYPaLsQ1jojN3etgDR8pByaTRnq4/export?format=csv#gid=1078904281 -O "$YDNA_HAPGRP_R"
# Haplogroup - S
echo Downloading - "$YDNA_HAPGRP_S"
wget https://docs.google.com/spreadsheets/d/1C0z-2d0I3TwwV5fdSfa850_hTwM55Ne3YX5iJH6bQoQ/export?format=csv#gid=0 -O "$YDNA_HAPGRP_S"
# Haplogroup - T
echo Downloading - "$YDNA_HAPGRP_T"
wget https://docs.google.com/spreadsheets/d/1u3cF3HCCzrxuJdmpsIQQF4NRhN4l82shPyGfVhSRMUQ/export?format=csv#gid=2049772122 -O "$YDNA_HAPGRP_T"

}

function strip_tree_files () {
  # Remove embeded comments from data and outut a list of Haplogroups

  local INFILE="$1"
  local OUTFILE="tree.$1"

  #echo $INFILE
  dos2unix $INFILE 2>&1 >/dev/null
  $SED -i -e 's/[ ]+,/,/g' -e 's/,[ ]+/,/g' $INFILE # remove spaces before or after a comma
  $SED -i -e 's/,,Fami,,/,,,,/g' $INFILE            # delete the comment "Fami" next to a Haplogroup
  $SED -i -e '/^,+$/d' $INFILE                      # delete lines only containing commas 
  $SED -i -e '/^$/d' $INFILE                        # delete blank lines
  $SED -i -e 's/[ \t\r]+$//' $INFILE                # delete tailing whitespace

  # Remove various comments, and notes writen on the tree  (order important!!!!)
  grep 'A0000=Denisovan'                            $INFILE 2>&1 >/dev/null && $SED -i -e '1,/A0000=Denisovan/d' $INFILE 
  grep 'Contact Person'                             $INFILE 2>&1 >/dev/null && $SED -i -e '1,/Contact Person/d' $INFILE 
  grep 'Link to Haplogroup'                         $INFILE 2>&1 >/dev/null && $SED -i -e '1,/Link to Haplogroup/d' $INFILE 
  grep 'confirmatory evidence is not yet available' $INFILE 2>&1 >/dev/null && $SED -i -e '1,/confirmatory evidence is not yet available/d' $INFILE 
  grep 'MUTATION INFORMATION'                       $INFILE 2>&1 >/dev/null && $SED -i -e '/MUTATION INFORMATION/,$d' $INFILE 
  grep 'NOTES'                                      $INFILE 2>&1 >/dev/null && $SED -i -e '/NOTES/,$d' $INFILE 
  grep 'Caveats for the information'                $INFILE 2>&1 >/dev/null && $SED -i -e '/Caveats for the information/,$d' $INFILE 
  grep 'D2 is listed as D0 in the 2019 Haber'       $INFILE 2>&1 >/dev/null && $SED -i -e '/D2 is listed as D0 in the 2019 Haber/,$d' $INFILE 
  grep 'The listed'                                 $INFILE 2>&1 >/dev/null && $SED -i -e '/The listed/,$d' $INFILE 
  $SED -i -e '/K items here/d'                      $INFILE
  $SED -i -e '/used in several studies/d'           $INFILE
  $SED -i -e '/just below--click on /d'             $INFILE

  #Tidy a few Lines
  $SED -i -e 's/[ ]+~/~/'                 $INFILE   # Remove spaces before a ~
  $SED -i -e 's/[^,]*TREE MOVES[^,]*,/,/' $INFILE   # Remove a comment
  $SED -i -e 's/ [ ]+/ /g'                $INFILE   # Remove douple spacing
  $SED -i -e 's/ \[[^]]* [^]]*\][ ,]*//'  $INFILE   # Remove comments in square brackets ([]) eg. [these may instead be at M8 tree level], [H2 formerly called F3], [maybe L333]
  $SED -i -e 's/[ \t]+"/"/g'              $INFILE   # Remove spaces before a double quote 

  #Tweak a few names to match those used in the TRUNK
  $SED -i -e 's/D2\*/D2/'                 $INFILE 

  #Join some split lines
  grep '^CTS6605/M2214'                   $INFILE 2>&1 >/dev/null && $SED -i -e "/^N,/N;s/\n//" $INFILE

  # Output only the haplogroup names
  $SED -e 's/^(,*[^,]+),.*$/\1/'          $INFILE | egrep -E "[A-Za-z0-9]" > $OUTFILE
}

function indent_tree_files {

  # Indent to match TRUNK

  local INFILE="$1"
  local OUTFILE="tree.$1"
  local topLn=`head -1 $INFILE` 
  local lastLn=`tail -1 $INFILE` 
  local trunkLn=""
  local indent=0
  local needIndent=0
  local currIndent=0
  local intentStr=""
  TRUNK_FL="tree.$YDNA_TRUNK"

  startGRP=$(echo $topLn | $SED -e 's/^,*//g')
  currIndent=$(echo $topLn | $SED -e 's/^(,*)[^,].*/\1/g' | wc -c )
  ((currIndent-=1))
  trunkLn=$(egrep -e "^$startGRP|,$startGRP$|,$startGRP[ ,]" $TRUNK_FL)
  if [ "$trunkLn" = ""  ]
  then 
    echo "$topLn:---:$lastLn"
    echo "Error : No match - $INFILE - $startGRP - $TRUNK_FL !!!"
  fi
  needIndent=$(echo $trunkLn | $SED -e 's/^(,*)[^,].*/\1/g' | wc -c )
  ((needIndent-=1))

  indent=$currIndent
  while [ $indent -lt $needIndent ]
  do
    intentStr="$intentStr,"
    ((indent+=1))
  done
  $SED -e "s/^/$intentStr/" $INFILE > $INFILE.tmp
}

function merge_tree_files {

  # Merge two files at a specified locaion

  fl1="$1"
  fl2="$2"
  mergeLn="$3"

  echo "+++ $fl1 - $fl2 - $mergeLn +++"
  if [ ! -f "$fl1" -o ! -f "$fl2" ]
  then
    echo "No Files !!!!"
    exit 8
  fi
 
  cp "$fl1" "$fl1.cpy1"
  cp "$fl1" "$fl1.cpy2"
  $SED -i -e "/^$mergeLn/,\$d" "$fl1.cpy1"
  $SED -i -e "1,/^$mergeLn/d" "$fl1.cpy2"
  cat "$fl2"              >> "$fl1.cpy1"
  while read delLn
  do
    grep "^$delLn" $fl1.cpy1 && $SED -i -e '/^$delLn/d' $fl1.cpy2
  done < <(cat $fl1.cpy2)
  cat $fl1.cpy2 >> $fl1.cpy1
  mv  $fl1.cpy1 $fl1
  rm -f $fl1.cpy2
}

# CSV to JSON function
source $THIS_LIB_NAME

###################
# MAIN
###################

if [ $DEBUG_DOWNLOAD_FILES -ne 0 ]
then
 download_files
fi

if [ $DEBUG_STRIP_FILES -ne 0 ]
then
  while read flName
  do
    strip_tree_files $flName
  done < <(ls $YDNA_HAPGRP_A $YDNA_HAPGRP_B $YDNA_HAPGRP_C $YDNA_HAPGRP_D  $YDNA_HAPGRP_E $YDNA_HAPGRP_F $YDNA_HAPGRP_G $YDNA_HAPGRP_H $YDNA_HAPGRP_I $YDNA_HAPGRP_J $YDNA_HAPGRP_K $YDNA_HAPGRP_L $YDNA_HAPGRP_M $YDNA_HAPGRP_N $YDNA_HAPGRP_O $YDNA_HAPGRP_P $YDNA_HAPGRP_Q $YDNA_HAPGRP_R $YDNA_HAPGRP_S $YDNA_HAPGRP_T $YDNA_TRUNK)
fi

if [ $DEBUG_TIDY_FILES -ne 0 ]
then
  # Tidy Trunk 
  # - Delete any lines not containing some text
  #$SED -i -e '/,[A-Z][A-Z]+$/d' tree.$YDNA_TRUNK 

  echo "------------------"
  echo ": $YDNA_TRUNK"
  echo "------------------"
  cat tree.$YDNA_TRUNK
  echo "------------------"
  echo "cheching TRUNK"
  echo
  while read branch
  do
    node=$(echo $branch | $SED -e 's/^,*//g')
    if egrep ",$node$|^$node$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv 2>&1 > /dev/null
    then
     tst=$(echo $node | $SED -e 's/[][]//g')
     if [ "$node" != "$tst" ]
     then
       if ! egrep -F "$node" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv
       then
         if egrep ",$tst$|^$tst$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv 2>&1 > /dev/null
         then
           rep=$(echo $node | $SED -e 's/[][]/[][]/g')
           $SED -i -e "s/$rep$/$tst/" "tree.$YDNA_BASE.TRUNK.csv"
         fi
       fi
     fi
    else
      try1=$(echo $node | $SED -e 's/ \[/ or /' -e 's/\]//')
      try2=$(echo $node | $SED -e 's/ [[].*$//')
      try3=$(echo $node | $SED -e 's/^[^ ]* [[](.*)$/\1/' -e 's/[]]//')
      try4=$(echo $node | $SED -e 's/[][]//g')
      tst=$(echo $node | $SED -e 's/[][]/[][]/')
      rep=$node
      if [ "$node" != "$try1" ] 
      then
        if ! egrep ",$try1$|^$try2$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv 2>&1 > /dev/null
        then 
          if ! egrep ",$try2$|^$try2$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv 2>&1 > /dev/null
          then
            if ! egrep ",$try3$|^$try3$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv 2>&1 > /dev/null
            then
              if ! egrep ",$try3$|^$try3$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv 2>&1 > /dev/null
              then
                echo "not found - $node #### try1:$try1 ### try2:$try2 ### try3:$try3 ### try4:$try4 - deleting"
                $SED -i -e "/$tst$/d" "tree.$YDNA_BASE.TRUNK.csv"
              fi
            else
              rep=$try3
            fi
          else
            rep=$try2
          fi
        else
          rep=$try1
        fi
      else
        echo "not found - $node"
      fi
      if [ "$rep" != "$node" ]
      then
        $SED -i -e "s/$tst$/$rep/" "tree.$YDNA_BASE.TRUNK.csv"
      fi
    fi
  done < <(cat "tree.$YDNA_BASE.TRUNK.csv")

  echo "------------------"
  echo "Altering TRUNK to better match files"
  cat tree.$YDNA_TRUNK
  echo "------------------"
  echo "Seeing if the first line of the split files has a haplogroup names ithat occurs (exactly) in the TRUNK, or failing that one of the other files"
  hap=""
  flNam=""
  while read line
  do
    if [ ${#line} -lt 20 -a ${#line} -ne 0 ]
    then
      hap="$line"
      egrep "^$hap$|,$hap$" "tree.$YDNA_BASE.TRUNK.csv"
      if ! egrep "^$hap$|,$hap$" "tree.$YDNA_BASE.TRUNK.csv" 2>&1 > /dev/null
      then
         echo "Needs Fixing - $flNam - $hap"
         tst=$(egrep "^$hap or |,$hap or " "tree.$YDNA_BASE.TRUNK.csv" | $SED -e 's/^,*//g')
         if [ "$tst" != "" ]
         then
           echo has an alternate name - $tst : $hap : $flNam
           $SED -i -e "1,1s/$hap/$tst/g" "$flNam"
         fi
      fi
    else
      flNam=$line
    fi
  done < <(head -1 tree.$YDNA_HAPGRP_A tree.$YDNA_HAPGRP_B tree.$YDNA_HAPGRP_C tree.$YDNA_HAPGRP_D tree.$YDNA_HAPGRP_E tree.$YDNA_HAPGRP_F tree.$YDNA_HAPGRP_G tree.$YDNA_HAPGRP_H tree.$YDNA_HAPGRP_I tree.$YDNA_HAPGRP_J tree.$YDNA_HAPGRP_K tree.$YDNA_HAPGRP_L tree.$YDNA_HAPGRP_M tree.$YDNA_HAPGRP_N tree.$YDNA_HAPGRP_O tree.$YDNA_HAPGRP_P tree.$YDNA_HAPGRP_Q tree.$YDNA_HAPGRP_R tree.$YDNA_HAPGRP_S tree.$YDNA_HAPGRP_T | $SED -e 's/==> //' -e 's/ <==//')
  echo "------------------"
  echo "aligning the indentation between files"
  echo

  #Indent tree files to match trunk
  while read flName
  do
    indent_tree_files $flName
  done < <(ls tree.$YDNA_HAPGRP_A tree.$YDNA_HAPGRP_B tree.$YDNA_HAPGRP_C tree.$YDNA_HAPGRP_D tree.$YDNA_HAPGRP_E tree.$YDNA_HAPGRP_F tree.$YDNA_HAPGRP_G tree.$YDNA_HAPGRP_H tree.$YDNA_HAPGRP_I tree.$YDNA_HAPGRP_J tree.$YDNA_HAPGRP_K tree.$YDNA_HAPGRP_L tree.$YDNA_HAPGRP_M tree.$YDNA_HAPGRP_N tree.$YDNA_HAPGRP_O tree.$YDNA_HAPGRP_P tree.$YDNA_HAPGRP_Q tree.$YDNA_HAPGRP_R tree.$YDNA_HAPGRP_S tree.$YDNA_HAPGRP_T)

  #remove nesting from tree files
  echo "------------------"
  echo removing nesting
  nesting=1
  changed=0
  while [ $nesting -eq 1 ]
  do
    while read trunkLn
    do
      matchFL=$(grep -H "^$trunkLn$" tree.$YDNA_BASE*.tmp|head -1|cut -d: -f1)
      infiles=$(grep -H "^$trunkLn$" tree.$YDNA_BASE*.tmp|wc -l)
      ((infiles+=0))
      if [ $infiles -eq 2 ]
      then
        nestedFL=$(grep -H "^$trunkLn$" tree.$YDNA_BASE*.tmp|tail -1|cut -d: -f1)
        merge_tree_files $matchFL $nestedFL $trunkLn
        rm -f $nestedFL
        changed=1
      fi 
    done < <(cat tree.$YDNA_TRUNK)
    if [ $changed -eq 0 ]
    then
      nesting=0
      cp tree.$YDNA_TRUNK $YDNA_TRUNK_MERGED
      echo -----------------------
      while read trunkLn
      do
        tmpFLS=$(ls tree.$YDNA_BASE.*.tmp 2>/dev/null | wc -l )
        ((tmpFLS+=0))
        if [ $tmpFLS -eq 0 ]
        then
          break
        fi 
        matchFL=$(grep -H "^$trunkLn$" tree.$YDNA_BASE*.tmp|head -1|cut -d: -f1)
        infiles=$(grep -H "^$trunkLn$" tree.$YDNA_BASE*.tmp|wc -l)
        ((infiles+=0))
        if [ $infiles -eq 1 ]
        then
          merge_tree_files $YDNA_TRUNK_MERGED $matchFL $trunkLn
          rm -f $matchFL
        fi 
      done < <(cat tree.$YDNA_TRUNK)
    fi
    changed=0
  done
  rm -f tree.$YDNA_BASE* $YDNA_BASE*.csv-e
fi

echo -----------------
echo $YDNA_TRUNK_MERGED
ls -l $YDNA_TRUNK_MERGED
wc -l $YDNA_TRUNK_MERGED
echo -----------------


echo "Checking nesting dose not increase by more than one - TAKES A WHILE !!!!!"
last=0;
lastLn="";
nestCnt=0;
while read line
do
  ((nestCnt+=1));
  ln=$(echo $line| $SED -e 's/^([,]*)[^,].*/\1/')
  lineLn=${#ln}
  diff=$((lineLn-last))
  if [ $diff -gt 1 ]
  then
    printf "Error: ln: $nestCnt - $last - $lineLn\n$lastLn\n$line\n---------\n"
    if [ $diff -eq 2 ]
    then
        echo "removing a comma"
        $SED -i -e "/$line/ s/^,//" $YDNA_TRUNK_MERGED
        echo "Return code: $?"
    fi
  fi
  last=$lineLn
  lastLn=${line:1}
done < <(cat $YDNA_TRUNK_MERGED)


if [ $DEBUG_REMOVE_DUP -ne 0 ]
then
  echo "Check if any Duplicates:"
  while read dup
  do
    echo $dup
    echo "suffixing duplicate instancess with a '@'"
    $SED -e "s/(,*$dup$)/\1@/" $YDNA_TRUNK_MERGED > $YDNA_TRUNK_MERGED.dup.tmp
    $SED -z -e "s/(,*$dup)@$/\1/" $YDNA_TRUNK_MERGED.dup.tmp > $YDNA_TRUNK_MERGED
  done < <(cat $YDNA_TRUNK_MERGED | $SED -e 's/^,+//' | sort | uniq -d)
  echo -----------------
  cat $YDNA_TRUNK_MERGED | $SED -e 's/^,+//' > $YDNA_HAPLOGRPS
  lines=$(cat $YDNA_HAPLOGRPS | wc -l); ((lines+=0))
fi

if [ $DEBUG_MISSING_MUTES -ne 0 ]
then
  echo "Check if lacking mutations:"
  cnt=0
  found=0
  diff=0
  while read haplo
  do
    ((cnt+=1))
    >&2 echo -n -e "\\rJoining: $cnt    of $lines - diff: $diff"
    if (egrep "^$haplo," "$YDNA_HAPGRP_MUTS" >/dev/null)
    then
      ((found+=1))
    else 
      ((diff+=1)) 
      echo "Error - not found: $haplo" >&2
    fi 
  done < <(cat $YDNA_HAPLOGRPS)
  echo >&2
  echo "Checked: $cnt" >&2
  Found: $found
  echo -----------------
fi
echo
echo "ALL DONE  -- you may now want to run YDNA-tree-to-all.sh"
################# END ##################