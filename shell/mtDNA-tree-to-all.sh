#!/bin/bash
# Extract the mtDNA Haplogroup names as a text file, the unique mutations from the Revised Cambridge / Sapien sequence, and reformat the Webpage to both a CSV and JSON file
# Source page: https://www.phylotree.org/builds/mtDNA_tree_Build_17.zip
#
# Requires: perl +  GNU sed + GNE egrep
#
# Notes: 
# - Partially hacked together on MacOS 10.13.6 using the bundeled POSIX (BSD), rather than GNU utilites, but hit issues with the mixed ASCII, UTF-8 and HTML escape chars in the source HTML file, now tweaked so use the GNU variants of sed and egrep.
# -- An abort with a count error will likley be down to an unexpected, escaped character in the HTML
# - Novel convention - The Tree contains ANONYMOUS precursor mutations, to a set of one or more Haplogroups, that have no haplogroup label themselves eg. 
# -- Parent Haplogroup: H2a1 [ G951A  C16354T] 
#    -- Precursor: [T146C!]   
#       -- Child: H2a1n [G4659A]
# To simplify downstream scripts the ANONYMOUS precursor mutation sets are given a hybrid label comprised of their parent and first chile with a "@" delimitor inserted, eg.  
# H2a1 to H2a1n precursor set will be labelled "H2a1@n" in the CSV and JSON output files.
#
# - To make the JSON more rearable there are numerous beautifiers, like:
#    python -m json.tool mtDNA-tree-Build-*.json
# -
# Author:  A.Robers 2023-07-05
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.
 
#--------------
DEPTH=""
POS=0
MAX_DEPTH=0
HAPLOGRPS=0
PROC_HAPLO_CNT=0
HAPLO_PAT="[a-zA-Z0-9'±]+,"
MUT_PAT="[^ACDTGacdtg!]"    #Last character of a MUTATION
SED="gsed -E"
#--------------
#FILE="~/Downloads/mtDNA?tree?Build?17.htm"
FILE="mtDNA-tree-Build-17.htm"
FILE_NAME=$(basename $FILE | $SED -e 's/[.].*$//')
FILE_LIST_CSV="$FILE_NAME.mutList.csv"
FILE_CSV="$FILE_NAME.csv"
FILE_MUT="$FILE_NAME.mutations.txt"
HAPLOS_FILE="$FILE_NAME.Haplogroups.txt"
HAPLOS_MUTS="$FILE_NAME.Haplogroup_mutations.csv"
HAPLOS_SNPS="$FILE_NAME.SNP_Positions_used.txt"
HAPLOS_JSON="$FILE_NAME.json"

####################################################################

function expand_mutation () {
# Input - Mutation
#
# Format:
# (source: Behar et al. 2012 - https://www.cell.com/ajhg/fulltext/S0002-9297(12)00146-2 )
#
# type 0     - transitions    - upper case (e.g., G73A)
# type 1     - transversions  - lower case (e.g., A73t)
# type 2     - heteroplasmies - IUPAC code and capital letters (e.g., G73R)
# type 3     - deletions      - “d” after the deleted nucleotide position (e.g., T15944d)
# type 4     - insertions     - indicated by a dot followed by the position number and type of inserted nucleotide(s) (e.g.,
#                    - 5899.1C ,
#                    - 5899.2C for a subsequent C insertion, abbreviated as 5899.1CC when occurring on the same branch
#                    - 5899.1Cd reversion of an earlier inserrtion
# type 5     - insertions at an unknown point after eg. 573.XC  
# type +100  - reversion      -  exclamation mark (!) at the end of a labeled position denotes a reversion to the ancestral state e.g.
#                                 (e.g. A1234T! = type 100,  C1234G!!! - type 300)
# type +1000 - parentheses wrapped e.g. (A1234T!!)  = type 1200

  local mutation=$(echo $1| $SED -e 's/"//g')
  local ancestral="${mutation:0:1}"
  local descendant="${mutation: -1}"
  local posStart=$(echo $mutation| $SED -e 's/^[^0-9]*([0-9]+).*$/\1/')
  local posEnd=$posStart
  local type=0
  local matches=0
  local extra=""

  matches=$(echo $mutation | egrep -e '-')
  if [ ${#matches} -ne 0 ]
  then
    posEnd=$(echo $mutation| $SED -e 's/^[^-]*-([0-9]+).*/\1/')
    extra=",\"posEnd\":\"$posEnd\""
  fi

  # type 1000 - parentheses
  if [[ "$ancestral" == "(" ]]
  then
    mutation=$(echo $mutation| $SED -e 's/[)(]//g')
    type=1000
    ancestral="${mutation:0:1}"
    descendant="${mutation: -1}"
  fi

  # type 100 - reversions
  if [[ $descendant == "!" ]]
  then
    marks=$(echo $mutation | $SED -e 's/^[^!]*([!]+).*/\1/')
    mutation=$(echo $mutation| $SED -e 's/[!]//g')
    ((type+=100*${#marks}))
    descendant="${mutation: -1}"
  fi

  # type 4 / 5  - insertions
  matches=$(echo $mutation | egrep -e '\.[X0-9]')
  if [ ${#matches} -ne 0 ]
  then
    ((type+=4))
    ancestral=""
    descendant=$(echo $mutation | $SED -e 's/^[^.]+[.][X0-9]+([A-Za-z]+)$/\1/')
    matches=$(echo $mutation | egrep "\.X")
    if [ ${#matches} -ne 0 ]
    then
      ((type+=1))
    fi
  fi

  # type 3 - deletions
  if [[ $descendant == "d" ]]
  then
    ((type+=3))
    descendant=""
  fi

  # type 2 - heteroplasmies
  if [ "$descendant" = "r" -o "$descendant" == "R" ]
  then
    ((type+=2))
    descendant=""
  fi

  # type 1 - transversions
  matches=$(echo $descendant | egrep -e "[actg]$")
  if [ ${#matches} -ne 0 ]
  then
    ((type+=1))
  fi

  echo "{\"posStart\":\"$posStart\"$extra,\"ancestral\":\"$ancestral\",\"descendant\":\"$descendant\",\"type\":\"$type\",\"display\":$1}"
}

function to_JSON_array () {
  local LOC_FROM="$1"
  local LOC_TO="$2"
  local LOC_COL1=$3

  local LOC_COL2=1
  local haploGRP=""
  local LOC_CD=0
  local LOC_P1=""
  local LOC_P2=""
  local LOC_i=0
  local LOC_KIDS=0
  local LOC_toFromArray=()
  local LOC_mutatiions_Array=()

  if [ "$LOC_FROM" != "START" ]
  then
    LOC_P1="0,/,$LOC_FROM,|^$LOC_FROM,/d"
    ((LOC_COL2=LOC_COL1+1))
    echo -n ',"children":[' >> "$HAPLOS_JSON"
  fi

  if [ "$LOC_TO" != "END" ]
  then
    LOC_P2="/$LOC_TO,/,$ d"
  fi

  local LOC_SEARCH="^,{$LOC_COL1}$HAPLO_PAT"

#echo "$@ - COL1=$LOC_COL1 - COL2=$LOC_COL2 - P1=$LOC_P1 - P2=$LOC_P2 - FROM=$LOC_FROM - TO=$LOC_TO - PAT=$HAPLO_PAT - $LOC_SEARCH"
#echo "$SED -e '$LOC_P1' -e '$LOC_P2' '$FILE_CSV' | egrep \"$LOC_SEARCH\" | cut -d, -f\"$LOC_COL2\""
#echo "$SED -e '$LOC_P1' -e '$LOC_P2' '$FILE_CSV' | egrep \"$LOC_SEARCH\" | $SED -e \"s/^,*[^,]*,//\""
#echo Lines between = $($SED -e "$LOC_P1" -e "$LOC_P2" "$FILE_CSV" | wc -l  ) 

  if [ $MAX_DEPTH -lt $LOC_COL1 ]
  then
    echo "Error: DEPTHE EXCEDED !!!!! $LOC_COL1 -gt MAX_DEPTH=$MAX_DEPTH"
    exit 6
  fi 

  LOC_toFromArray=($($SED -e "$LOC_P1" -e "$LOC_P2" "$FILE_CSV" | egrep "$LOC_SEARCH" | cut -d, -f"$LOC_COL2"))
  LOC_mutatiions_Array=($($SED -e "$LOC_P1" -e "$LOC_P2" "$FILE_CSV" | egrep "$LOC_SEARCH" | $SED -e "s/^,*[^,]*,//"))
  LOC_KIDS=${#LOC_toFromArray[@]}

  # use for loop to read all values and indexes
  for haploGrp in "${LOC_toFromArray[@]}"
  do
    ((PROC_HAPLO_CNT+=1))
    >&2 echo -n -e "\\rProcessing: $PROC_HAPLO_CNT of $HAPLOGRPS - $haploGrp                  "
    if [ $PROC_HAPLO_CNT -gt $HAPLOGRPS ]
    then
      echo "Error -PROC_HAPLO_CNT = $PROC_HAPLO_CNT -gt HAPLOGRPS = $HAPLOGRPS -  Something went wrong"
      exit 4
    fi
    if [ $haploGrp != ${LOC_toFromArray[$LOC_i]} ]
    then
      echo "Error $haploGrp != ${LOC_toFromArray[$LOC_i]} - Something went wrong"
      exit 5
    fi

    echo -n '{"haplogroup":' >> "$HAPLOS_JSON"
    echo -n "\"${LOC_toFromArray[$LOC_i]}\"," >> "$HAPLOS_JSON"
    echo -n "${LOC_mutatiions_Array[$LOC_i]}" >> "$HAPLOS_JSON"

    local LOC_COL0=$LOC_COL1
    if [ $LOC_COL0 -gt 0 ]
    then
      ((LOC_COL0-=1))
    fi
    local LOC_P4="^,{0,$LOC_COL0}[^,]+"
    local LOC_NEXT_POS=$LOC_i
    ((LOC_NEXT_POS+=1))
    if [ "$LOC_NEXT_POS" -lt "$LOC_KIDS" ]
    then
      LOC_P4="${LOC_toFromArray[$LOC_NEXT_POS]}"
    fi 
    to_JSON_array "${LOC_toFromArray[$LOC_i]}" "$LOC_P4" "$LOC_COL2" 
    echo -n "}," >> "$HAPLOS_JSON"
    ((LOC_i+=1)) 
  done
  if [ "$LOC_FROM" != "START" ]
  then
    echo -n "]" >> "$HAPLOS_JSON"
  fi
}

function fill_in_precursors {
  if [ "$1" -gt 0 -a -f "$FILE.$1" ]
  then
    local TMP_CNT=$1
    ((TMP_CNT+=1))
    ((FL_CNT+=2))
    cat "$FILE.$1" | $SED -e '/,±,"mutations":/N;s/\n/§/' | perl -pe 's/§\n/§/' > "$FILE.$TMP_CNT"
    cat "$FILE.$TMP_CNT" | $SED -E -e 's/^(,*)(±{1,},"mutations"[^§]*§)(,*)([^,]*)(.*)$/\1\4\2\3\4\5/g' -e 's/([a-z0-9])±,/±\1,/'| perl -pe 's/§/\n/' | $SED -e '/^[[:space:]]*$/d' > "$FILE.$FL_CNT"
  else
    echo "ERROR: File does not exist - $FILE.$1"
  fi
}

function set_anon_cnt {
    ((ANON_CNT=0+$(grep '±,' $FILE.$FL_CNT | wc -l)))
}
##################################################

if [ $# -gt 1 -o $# -eq 1 -a ! -f "$1" -o $# -eq 0 -a ! -f "$FILE" ]
then
  echo "Usage:   $(basename $0) [<mtDNA-tree-Build-##.htm>]"
  echo
  echo "Purpose: Extract the mtDNA Haplogroup names as a text file and the assosiated mutations from the Revised Cambridge / Sapienb sequence as a JSON file"
  echo "          - Source file:  https://www.phylotree.org/builds/mtDNA_tree_Build_17.zip"
  echo
  echo "defaults: "
  echo "  Input-mtDNA-tree-Build-file  = $FILE"
  echo "  output-Haplogroup-Names-file = $HAPLOS_FILE"
  echo "  output-Haplogroup-Mutiaions  = $HAPLOS_MUTS"
  echo "  output-mtDNA-Haplogroup-JSON = $HAPLOS_JSON" 
  echo
  exit 1
else
  echo "SOURCE FILE: $(ls -l ./$FILE)"
  echo "Now go have a cup of coffee or something stronger, as may take 15+ mins !!!!"
fi

# Produce CSV file
if [ -f "$FILE" -a -s "$FILE" ]
then
  #Remove non-ASCII characters
  ( export LC_ALL=C; tr -d '\200-\277' < "$FILE" | tr '\300-\377' '[?*]' > "$FILE.1")
  #Remove the lines before the TABLE (<table ... >)  AND Blank the table row style ellements (<tr ...... >)
  cat "$FILE.1" | $SED -n '/^<table.*$/,$p' | $SED -e 's/<tr class=[^>]*/<tr/' > "$FILE.2"
  #Blank the table cell style elements (<td .... > )
  cat "$FILE.2" | $SED -e "s/<td [^>]*/<td/" > "$FILE.3"
  #Convertc HTML non-blank-space, quot ast, , midast,   characters
  cat "$FILE.3" | $SED -e "s/\&nbsp;//" -e "s/\&quot;/'/" -e "s/\&midast;/*/" -e "s/\&ast;/*/" > "$FILE.4"
  #Change table cell sepetators (<td> </td>) into commas, and remove the row terminators </tr>
  cat "$FILE.4" | $SED -e "s:</td>:,:" -e "s:<td>,:,:" -e "s:</tr>::" > "$FILE.5"
  #Remove all Microsoft style line breaks (Carriage Return + New Line [\r\n])
  cat "$FILE.5" | tr -d "\r\n" > "$FILE.6"
  #Delete Reference Links "<a>.*</a>
  cat "$FILE.6" | $SED -e "s:<td><a[^<]*><span[^<]*</span>:<td><a>:g" -e "s:<td><a>[^<]*</a>:,:g" > "$FILE.7"
  #Convert NEW Table Row (<tr>) into a NEW LINE
  cat "$FILE.7" | perl -pe 's:<tr>:\n:g' > "$FILE.8"
  # Delete the lines starting <table  AND remove all HTML tags, trailing commas and SPACES
  cat "$FILE.8" | $SED -e "/^<table /d" -e "s:<[^>]*>::g" -e "s:,[ ]*:,:g" -e "s:,*$::"g -e "s:,[A-Z0-9]*[^ACDTGacdtg!]$::" -e "s:,*$::" > "$FILE.9"
  # Remove leading spaces, and delete the lined before the first Haplogroup "L0"
  cat "$FILE.9" | perl -pe 's:^[\s]*::' | $SED -n '/L0.*$/,$p' | $SED -e 's/^ //' > "$FILE.10"
  #Remove double spacing
  cat "$FILE.10" | $SED -e "s/$/§/" | perl -pe 's/[ ]+/ /g' | perl -pe 's/§/\n/g' > "$FILE.11"
  #Wrap Mutations in JSON Array Syntax 
  cat "$FILE.11" | perl -pe 's/,([^,]+)\n$/,"mutations":["$1"]§/' | perl -pe 's/§/\n/g' | $SED -e 's/ /","/g' -e '/^[[:space:]]*$/d' > "$FILE.12"
  #Mark ANONYMOUS precursor sets with a "±" 
  cat "$FILE.12" | $SED -e 's/,,"mut/,±,"mut/' > "$FILE.13"
  FL_CNT=13
  set_anon_cnt $FL_CNT
  echo "Anonymous mutation sets - $ANON_CNT"
  while [ $ANON_CNT -ne 0 ]
  do
    fill_in_precursors $FL_CNT
    set_anon_cnt $FL_CNT
    if [ $ANON_CNT -gt 0 ]
    then
      fill_in_precursors $FL_CNT
      set_anon_cnt $FL_CNT
      if [ $ANON_CNT -gt 0 ]
      then
        ((TMP_CNT=FL_CNT+1))
        cat "$FILE.$FL_CNT" | $SED -e 's/±±,/±,/g' > $FILE.$TMP_CNT
        #echo "removed ±± from $FILE.$TMP_CNT"
        ((FL_CNT=TMP_CNT))
      fi
    fi
  done
  # Change all '±' to '@' to satisfy Python's 7-bit ASCII fixation
  $SED -i -e 's/±/@/g' $FILE.$FL_CNT

  # Count unique mutations by type
  gsed -E -e "s/^,+//" -e "s/^[^,]+,//" -e "s/^[ ]+//" -e "s/[ ]+$//" -e "/^$/d" $FILE.11 | perl -pe 's/ /\n/g' | sort -u > $FILE_MUT
  echo "Unique Mutations: $(wc -l $FILE_MUT )" 
  echo "Mutation types"
  echo "Suffixes / downstream"
  while read mut ; do   echo "${mut: -1}"; done < <(cat $FILE_MUT) | sort | uniq -c
  echo "----------------------"
  echo "Prefixes / ancestors"
  while read mut ; do   echo "${mut:0:1}"; done < <(cat $FILE_MUT) | sort | uniq -c
  echo "----------------------"

  #expand the JSON mutations Arrays
  ((TMP_CNT=FL_CNT+1)) 
  PROC_MUTS_CNT=0
  while read haploGRP
  do
    pref=$(echo $haploGRP | $SED -e "s/^([^\[]*\[).*/\1/" )
    mutList=$(echo $haploGRP | $SED -e "s/^[^\[]*\[(.*)\]/\1/" )
    >&2 echo -n -e "\\rExpanding: $PROC_MUTS_CNT    "
    suff="]"
    spacer=""
    expandList=""
    while read mut
    do 
      expandedMutation=$(expand_mutation $mut)
      expandList="$expandList$spacer$expandedMutation"
      spacer=","
      ((PROC_MUTS_CNT+=1))
    done < <(echo $mutList | perl -pe 's/,/\n/g' )
    echo $pref$expandList$suff 
  done < <(cat $FILE.$FL_CNT ) > $FILE.$TMP_CNT
  echo >&2
  echo "Expanded: $PROC_MUTS_CNT" >&2

  mv "$FILE.$FL_CNT" "$FILE_LIST_CSV"
  mv "$FILE.$TMP_CNT" "$FILE_CSV"
  ((FL_CNT=TMP_CNT))
  find . -type f -name "$FILE.[0-9]*" -exec rm {} +
fi

###################
#  Stats
if [ -f "$FILE_LIST_CSV" -a -s "$FILE_LIST_CSV" -a -f "$FILE_CSV" -a -s "$FILE_CSV" ]
then
  #Count how many HAPLOGTPS are in the CSV file
  HAPLOGRPS=$(wc -l "$FILE_CSV"| $SED -e "s/^[[:space:]]*//" | cut -d' ' -f 1 )
  ((HAPLOGRPS+=0))

  #Count leading commas (,) to work out the maximim depth of the tree
  ((MAX_DEPTH+=0+$($SED -e "s/[^,].*$//g" "$FILE_CSV" | sort | uniq | tail -1 | wc -c)))

  echo "HAPLOGRPS=$HAPLOGRPS - MAX_DEPTH=$MAX_DEPTH"

  cat "$FILE_LIST_CSV" | $SED -e 's/^,*//' -e 's/"mutations"://' > "$HAPLOS_MUTS"
  echo "Haplos: $(wc -l $HAPLOS_MUTS)"

  # Extract the mtDNA Haplogroup names
  cat "$FILE_LIST_CSV" | $SED -e  "s/^[,]*([^,]+).*/\1/" > "$HAPLOS_FILE"
  echo "Haplos: $(wc -l $HAPLOS_FILE)"

  # Extract the mtDNA SNP Positions used
  cat "$FILE_CSV" | $SED -e 's/^[^\[]+\[\{//' -e 's/"posStart":"//g' -e 's/","[^\}]+\}//g' -e s'/,\{/,/g' -e 's/\]//' -e 's/[A-Za-z]//g' |  perl -pe 's/,/\n/g' | sort -un > $HAPLOS_SNPS
  echo "UNIQ SNP start postions: $(wc -l $HAPLOS_SNPS)"
fi

###################
# Produce JSON file
if [ -f "$FILE_CSV" -a -s "$FILE_CSV" ]
then
  echo '{"mt-MRCA(RSRS)":[' > "$HAPLOS_JSON"
  to_JSON_array "START" "END" "0" 
  echo "]}" >> "$HAPLOS_JSON"
  echo "Written: $PROC_HAPLO_CNT"

  #Tidy - remove blank lines, empty "children" arrays, and add some other new lines
  cat "$HAPLOS_JSON" | tr -d "\n" | $SED -e 's/"children":\[\]//g' -e "s/,[[:space:]]+}/}/g" -e "s/,[[:space:]]*\]/]/g" -e 's/]/]\n/g' > "$HAPLOS_JSON.tmp"
  mv "$HAPLOS_JSON.tmp" "$HAPLOS_JSON"
else
  echo "No FILE $FILE_CSV"
fi

2>&1 echo
echo
#####################################
