# Convert a Haplogroup CSV }le to JSON format
# Note -just a rewrite of a BASH script
#
# Author:  A.Robers 2023-08-02
# License: GPLv3. See accompanying LICENSE file.
# No warranty. You are responsible for your use of this program.

#use strict;
use warnings;
use Data::Dumper;

my ($FILE_CSV, $HAPLOS_JSON, $HAPLO_PAT, $LABEL)  = @ARGV;
my $convertedCNT = 0;
my $haploGrpCNT = 0;
my $maxDEPTH = 0;
my @csvFile;
my @csvFileTMP;
my ($FI, $FD);
my $DEBUG=0;

##############
sub to_JSON_array ($$$);
sub to_JSON_array ($$$) {
  local ($from, $to, $col1) = @_;

  local $col2=$col1+1;
  local $i=0;
  local $found=0;
  local @halopGrpArray=();
  local @mutArray=();
  local $nextBranch;

  if ( $from ne 'START' ){
    print $FD ',"children":[';
  } else {
    $found = 1;
  }

  local $search="^,{$col1}$HAPLO_PAT";

  if ( $maxDEPTH < $col1 ) {
    print STDERR "Error: DEPTH EXCEDED !!!!! $col1 -gt maxDEPTH=$maxDEPTH\n";
    exit 6;
  }

if ( $DEBUG ) {print ("\nto_JSON_array ($from, $to, $col1); - '$search' - CSV-lines: $#csvFile - found: $found - haplo: $#halopGrpArray - mutat: $#mutArray\n" );}
  @csvFileTMP=@csvFile;
  foreach my $ln (@csvFile) {

     #Skip lines before the wanted line
     if ( ! $found ){
       if ($ln !~ m/,$from,|^$from,/ ) { 
         shift(@csvFileTMP);
         next; 
       } 
       $found = 1; 
if ( $DEBUG ) {print ("$found:  m/,$from,|^$from,/ - $ln \n");}
     }

     #Skip all lines after
     if ($to ne 'END' and $ln =~ m/^$to,|,$to,/) { last; } 

     if ($ln =~ m/$search/){
       $mutation=  $ln;
       $mutation=~ s/^,*//;
       $haploGrp=  $mutation;
       $haploGrp=~ s/,.*$//; 
       push @halopGrpArray, $haploGrp;
       $mutation=~ s/^[^,]*,//;
       push @mutArray, $mutation;
       #if ( $convertedCNT < 16 ) { $DEBUG = 1; } else { $DEBUG = 0; }
     }
  }
  @csvFile=@csvFileTMP;
if ( $DEBUG ) {
  print ("haplo: $#halopGrpArray - mutat: $#mutArray - found: $found\n" );
  print "-----\n",Dumper(@halopGrpArray),"~~~~~~~\n";
  print "-----\n",Dumper(@mutArray),"~~~~~~~\n";
}
  # use for loop to read all values and indexes
  foreach my $haploGrp (@halopGrpArray) {
    $convertedCNT++;

    $| = 1;
    print STDERR "\rProcessing: $convertedCNT of $haploGrpCNT - $haploGrp          ";
    if ( $convertedCNT > $haploGrpCNT ) {
      print STDERR "\n\nError -convertedCNT = $convertedCNT -gt haploGrpCNT = $haploGrpCNT -  Something went wrong\n";
      exit 4;
    }
    if ( $haploGrp ne ${halopGrpArray[$i]} ) {
      print "\n\nError $haploGrp <> ${halopGrpArray[$i]} - Something went wrong";
      exit 5;
    }

    my $muts="";
    if ( $i > -1 and $mutArray[$i] ) {
      $muts="$muts,$mutArray[$i]" ;
    }
    if ( $i > 0) { print $FD ",";}
    print $FD "{\"haplogroup\":\"${halopGrpArray[$i]}\"$muts";

    # nextBranch =  Next Haplogroup at level, or UP a level
    local $nextPos=$i+1;
if ( $DEBUG ) {print("nextPos: $nextPos - i: $i - halopGrpArray: $#halopGrpArray\n");}
    if ( $nextPos <= $#halopGrpArray ) {
      $nextBranch = "$halopGrpArray[$nextPos]";
    } else {
      $nextBranch = $to;
      local $col0=$col1;
      if ( $col0 > 1 ) { 
        $col0--; 
        $nextBranch = "^,{0,$col0}[^,]+";
      }
    }

    to_JSON_array ($halopGrpArray[$i], $nextBranch, $col2);
    print $FD "}";
if ( $DEBUG ) {print ("Back - haplo: $#halopGrpArray - mutat: $#mutArray - found: $found - i: $i - halopGrpArray: $#halopGrpArray\n" );}
    $i++;
  }
  if ( $from ne 'START' ) {
    print $FD "]";
  }
}

##### Main #####

print ("\n€€€€€€€€\nFILE_CSV: $FILE_CSV\nHAPLOS_JSON: $HAPLOS_JSON\nLABEL: $LABEL\nPAT: $HAPLO_PAT\n");

open($FI, "<", "$FILE_CSV") or die $!;
open($FD, ">", "$HAPLOS_JSON") or die $!; 

#Read the CSV file into an array
chomp(@csvFile = <$FI>);
$haploGrpCNT=$#csvFile + 1;
print("Lines in CSV file: $haploGrpCNT\n");
close $FI;

foreach my $line (@csvFile) {
  my $ln=$line;
  $ln =~ s/[^,].*$//;       # Ignore all but the leading comma
  my $cnt = $ln =~ tr/,//;  # Count the commas replace with nothing
  if ( $cnt > $maxDEPTH ) { $maxDEPTH = $cnt; }
}
$maxDEPTH++;                # One more than the commas
print("MAXDEPTH = $maxDEPTH\n");

#Convert the file to JSON format
if ($maxDEPTH > 0 ) {
  print $FD "{\"$LABEL\":[\n";
  to_JSON_array ('START', 'END', 0);
  print $FD "]}\n";
}
print STDERR ("\n");
close $FD;
