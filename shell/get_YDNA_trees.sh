#!/bin/bash
#
# Purpose:Attempt to download, combine, and convert the ISOGG YDNA files from https://isogg.org/tree/index.html
#
#   - Outputs: 
#     - YDNA_ISOGG_Haplogrp_Tree.A.csv through YDNA_ISOGG_Haplogrp_Tree.T.csv and YDNA_ISOGG_Haplogrp_Tree.TRUK.csv
#       -- downloaded Google sheets
#       -- with notes, comments and severl inconsistencies removed.
#     - YDNA_ISOGG_Haplogrp_Tree.haplogrps.txt       - list of YDNA haplogroup names use, e.g.d
#      Y
#      A0000
#      A000-T
#      A000
#      A000a
#      A000b
#      A000b1
#      A00-T
#      A00-T~
#      A00
#      ...
#     - YDNA_ISOGG_Haplogrp_Tree.TRUNK.csv           - haplogroup names and mutations indented to reflect tree structure, e.g.
#      Y,Root (Y-Adam),,,,,,,,,,,,,,,,,,,,,,
#      ,A0000,A8864,,,,,,,,,,,,,,,,,,,,,
#      ,A000-T,A8835,,,,,,,,,,,,,,,,,,,,,
#      ,,A000,A10805,,,,,,,,,,,,,,,,,,,,
#      ,,A00-T,PR2921,,,,,,,,,,,,,,,,,,,,
#      ,,,A00,AF6/L1284,,,,,,,,,,,,,,,,,,,
#      ,,,A0-T,L1085,,,,,,,,,,,,,,,,,,,
#      ,,,,A0,CTS2809.1/L991.1,,,,,,,,,,,,,,,,,,
#      ,,,,A1,P305,,,,,,,,,,,,,,,,,,
#      ,,,,,A1b,P108,,,,,,,,,,,,,,,,,
#      ...
#     - YDNA_ISOGG_Haplogrp_Tree.merged.csv          - haplogroup names indented to reflect tree structure, e.g.
#      Y
#      ,A0000
#      ,A000-T
#      ,,A000
#      ,,,A000a
#      ,,,A000b
#      ,,,,A000b1
#      ,,A00-T
#      ,,A00-T~
#      ,,,A00
#      ,,,,A00a
#      ,,,,A00b
#      ,,,,A00c
#      ,,,A0-T
#
# Notes: 
#   - Source Google sheets have a growing collection of comments / annotations, along with some unhelpful / incosistent foratting, that needs to be removed, 
#     as will blow the script
#   - Output JSON mutation type:
#    type 0     - transitions    - upper case (e.g., G->A)
#    type 3     - deletions      - “del”
#    type 4     - insertions     - "ins"
#   - the 'YDNA-tree-to-all.sh' script will attempt to convert the output from this script and the 'get_YDNA_rsid.sh' script into a single JSON file
#
# Author:  A.Robers 2023-07-24
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

# ------------
# Set to 0 to disable
DEBUG_DOWNLOAD_FILES=1
DEBUG_STRIP_FILES=1
DEBUG_TIDY_FILES=1
DEBUG_REMOVE_DUP=1
# ------------
SED="sed -E" ; gsed --version  2>&1 > /dev/null && SED="gsed -E" ; export SED

THIS_SCRIPT_NAME=$(basename $0)
THIS_DIR_NAME=$(dirname $0)
THIS_LIB_NAME="$(dirname $0)/DNA_HELPER_LIB.sh"
# ------------
BUILD=37
YDNA_BASE="YDNA_ISOGG_Haplogrp_Tree"
YDNA_HAPLOGRPS="$YDNA_BASE.haplogrps.txt"           ; export YDNA_HAPLOGRPS
YDNA_TRUNK="$YDNA_BASE.TRUNK.csv"
YDNA_TRUNK_NESTED="$YDNA_BASE.Haplos.nested.csv"    ; export YDNA_TRUNK_NESTED
YDNA_TRUNK_MERGED="$YDNA_BASE.merged.csv"           ; export YDNA_TRUNK_MERGED
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
  $SED -i -e 's/ [[]([A-Za-z0-9~]+)[]]([,~])/_or_\1\2/' -e 's/ or /_or_/' $INFILE    # Standardise ALTERNATE haplogroup names 

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
        if ! egrep ",$try1$|^$try2$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv  2>&1 > /dev/null
        then 
          if ! egrep ",$try2$|^$try2$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv  2>&1 > /dev/null
          then
            if ! egrep ",$try3$|^$try3$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv  2>&1 > /dev/null
            then
              if ! egrep ",$try4$|^$try4$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv  2>&1 > /dev/null
              then
                if (echo $node | egrep '~$')
                then
                  try5=$(echo $try1 | $SED -e 's/~$//g')
                  try6=$(echo $try2 | $SED -e 's/~$//g')
                  try7=$(echo $try3 | $SED -e 's/~$//g')
                  try8=$(echo $try4 | $SED -e 's/~$//g')
                  if ! egrep ",$try5$|^$try5$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv  2>&1 > /dev/null
                  then
                    if ! egrep ",$try6$|^$try6$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv  2>&1 > /dev/null
                    then
                      if ! egrep ",$try7$|^$try7$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv  2>&1 > /dev/null
                      then
                        if ! egrep ",$try8$|^$try3$" tree.YDNA_ISOGG_Haplogrp_Tree.?.csv  2>&1 > /dev/null
                        then
                          echo "NEITHER node or PARENT found - $node #### try1:$try1 ### try2:$try2 ### try3:$try3 ### try4:$try4 #### try5:$try5 ### try6:$try6 ### try7:$try7 ### try8:$try8 - deleting"
                          $SED -i -e "/$node$/d" "tree.$YDNA_BASE.TRUNK.csv"
                        else
                          echo "PARENT found '$try5' but not '$node' - trunk more detailed than branch" 
                          rep="$try8~"
                        fi 
                      else
                        echo "PARENT found '$try5' but not '$node'  - trunk more detailed than branch" 
                        rep="$try7~"
                      fi
                    else
                      echo "PARENT found '$try5' but not '$node'  - trunk more detailed than branch" 
                      rep="$try6~"
                    fi
                  else
                    echo "PARENT found '$try5' but not '$node'  - trunk more detailed than branch" 
                    rep="$try5~"
                  fi
                else
                  echo "not found - $node #### try1:$try1 ### try2:$try2 ### try3:$try3 ### try4:$try4 - deleting"
                  $SED -i -e "/$node$/d" "tree.$YDNA_BASE.TRUNK.csv"
                fi
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
  echo "Seeing if the first line of the split files has a haplogroup names that occurs (exactly) in the TRUNK, or failing that one of the other files"
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
         tst=$(egrep "^${hap}_or_|,${hap}_or_" "tree.$YDNA_BASE.TRUNK.csv" | $SED -e 's/^,*//g')
         if [ "$tst" != "" ]
         then
           echo "  - has an alternate name - $tst : $hap : $flNam"
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

  #joining tree files
  echo "------------------"
  echo joining tree files
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

echo "Checking nesting dose not increase by more than one level"

perl -e 'my @lines=`cat $ENV{YDNA_TRUNK_MERGED}`; my $lineLen=0; my $lastLen=0; my $lastLn=""; my $nestCnt=0; my $fillCnt=0; my $lnCnt=$#lines+1; my $ln, $newLn, $cmd; foreach my $line (@lines) { $nestCnt++; print STDERR "Checking: $nestCnt    of $lnCnt\r"; $ln=$line; $ln=~s/^([,]*)[^,].*$/\1/; $lineLen=$#ln+1; $diff=$lineLen-$lastLen; if ( $diff >  1 ) { printf "Error: line: $nestCnt - $lastLen - $lineLen\n$lastLn\n$line\n---------\n"; if ( $diff == 2 ) { $fillCnt++; print "removing a comma\n"; $cmd = "$ENV{SED} -i -e \"/^$line/ s/^,//\" $ENV{YDNA_TRUNK_MERGED}"; system($cmd);}i } $lastLn=$line; $lastLen=$lineLen; } print STDERR "Checked: $nestCnt\nBack filled: $fillCnt\n";'

if [ $DEBUG_REMOVE_DUP -ne 0 ]
then
  echo "Check if any Duplicates:"
  #perl -e 'my @lines = `cat $ENV{YDNA_TRUNK_MERGED}`; my $ln; my @dupHaplo = (); my @sortedDupHaplo = (); my %haplogroups = {}; my $lnCnt=$#lines; my $dupCnt=0; my $suffCnt=0; my $found=0; my $uniqDup=0; foreach my $line (@lines){ $line=~s/^,*([^,]+)/\1/; $line=~s/\n//; if (exists $haplogroups{$line}) { $dupCnt++; $haplogroups{$line}++; if ( $haplogroups{$line} == 2) { push(@dupHaplo, $line); } } else { $haplogroups{$line}=1; } } @sortedDupHaplo=sort @dupHaplo; $uniqDup=1+$#sortedDupHaplo; print "\nDuplicates: $dupCnt - Unique Duplicates: $uniqDup\n"; foreach my $dup (@sortedDupHaplo){ print "suffixing duplicate instancess of \"$dup\" with a \"@\"\n"; $found=0; foreach my $line (@lines){ $ln=$line; $ln=~s/\n//; $haplo=$ln; $haplo=~s/^,*([^,]+)/\1/; if ( $haplo eq $dup ) { if ($found == 1) { $ln=~s/^(.*[^,]+)/\1@/; $line=$ln; $suffCnt++; } else { $found = 1; } } } } open(FH, ">", "$ENV{YDNA_TRUNK_MERGED}") or die $!; foreach (@lines) { print FH "$_\n"; } close(FH); print STDERR "Suffixed: $suffCnt\n";'
  echo -----------------
  cat $YDNA_TRUNK_MERGED | $SED -e 's/^,+//' > $YDNA_HAPLOGRPS
  lines=$(cat $YDNA_HAPLOGRPS | wc -l); ((lines+=0))
fi

echo
echo "ALL DONE  -- you may now want to run YDNA-tree-to-all.sh"
################# END ##################
