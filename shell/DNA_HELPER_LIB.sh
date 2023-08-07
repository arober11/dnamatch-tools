# Convert a Haplogroup CSV file to JSON format
function to_JSON_array2() {
  thisDir=$(basename $0)
  perl $thisDir/perl_snippets/DNA_csv_to_json.pl "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" 
}

function to_JSON_array () {
  local LOC_FROM="$1"
  local LOC_TO="$2"
  local LOC_COL1=$3
  HAPLOGRPS=$4
  MAX_DEPTH=$5
  FILE_CSV=$6
  HAPLOS_JSON=$7
  HAPLO_PAT=$8
  PROC_HAPLO_CNT=$9

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

  if [ $MAX_DEPTH -lt $LOC_COL1 ]
  then
    echo "Error: DEPTHE EXCEDED !!!!! $LOC_COL1 -gt MAX_DEPTH=$MAX_DEPTH"
    exit 6
  fi

#echo "$@ - COL1=$LOC_COL1 - COL2=$LOC_COL2 - P1=$LOC_P1 - P2=$LOC_P2 - FROM=$LOC_FROM - TO=$LOC_TO - PAT=$HAPLO_PAT - $LOC_SEARCH"
#echo "$SED -e '$LOC_P1' -e '$LOC_P2' '$FILE_CSV' | egrep \"$LOC_SEARCH\" | cut -d, -f\"$LOC_COL2\""
#echo "$SED -e '$LOC_P1' -e '$LOC_P2' '$FILE_CSV' | egrep \"$LOC_SEARCH\" | $SED -e \"s/^,*[^,]*,//\""
#echo Lines between = $($SED -e "$LOC_P1" -e "$LOC_P2" "$FILE_CSV" | wc -l  )

  # sed lists the whole file when patterns are empty
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
#if [ $TST_DEPTH -gt $THIS_DEPTH ]
#then
#((THIS_DEPTH+=1))
#echo "$TST_DEPTH -gt $THIS_DEPTH"
    to_JSON_array "${LOC_toFromArray[$LOC_i]}" "$LOC_P4" "$LOC_COL2" "$HAPLOGRPS" "$MAX_DEPTH" "$FILE_CSV" "$HAPLOS_JSON" "$HAPLO_PAT" "$PROC_HAPLO_CNT"
#fi
#echo "Backup:  $TST_DEPTH -gt $THIS_DEPTH"
    echo -n "}," >> "$HAPLOS_JSON"
    ((LOC_i+=1))
  done
  if [ "$LOC_FROM" != "START" ]
  then
    echo -n "]" >> "$HAPLOS_JSON"
  fi
}
