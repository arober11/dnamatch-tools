#!/bin/perl
#
# Purpose: reformat a DNA Haplogroyp CSV into JSON and a tree csv file
# 
# Input:  Haplogroup, RSID, chromosome, hg192_POSi,nhg38_POSi, Ancestral, Derived, Parent_Y_Haplo_GRP, Alt_Labels, Notes 
# Output:  FJ - JSON file
#          FT - nested CSV file
#

my $root="HomoErectus";
my $FI="YHaplogroups-GeneticHomeland-stub.csv";
my $jsonFile="YHaplogroups-GeneticHomeland-stub.json";
my $treeFile="YHaplogroups-GeneticHomeland-stub-nested.csv";
my @lines=`cat $FI`;
my $cnt=1;

sub indent_kids($$$) {
  $cnt++;
  if($cnt > $#lines) {
    print "ERROR !!!! $cnt \n\n";
    continue;
  }
  local ($parent, $indent, $linei, $childCnt, $hasKids);
  ($parent, $childCnt, $indent) = @_;
  
  foreach my $ln (@lines){
    if ($ln =~ m/^$parent,/ ) {
      $line=$ln;
      last;
    }
  }
  chop $line;
  local @values = split(',', $line);
  local $rsid=$values[1];
  local $posStart=$values[3];
  local $ancestral=$values[5];
  local $desendant=$values[6];
  local $alias=$values[8];
  local $type=0;
  local $pref="";
  if ($desendant !~ m/[ACGT]/ ) {
    if ($desendant =~ m/del|d/) { $type=3; }
    if ($desendant =~ m/ins|i/) { $type=4; }
  }
  if ($rsid ne "") { $rsid=",\"rsid\":\"$rsid\""; }
  if ($childCnt != 0){ $pref=','; }

  print FT ("$indent$parent\n");
  print FJ ("$pref\{\"haplogroup\":\"$parent\",\"mutations\":[{\"posStart\":\"$posStart\",\"ancestral\":\"$ancestral\",\"descendant\":\"$desendant\",\"type\":\"$type\",\"display\":\"$ancestral$posStart$desendant\",\"label\":\"$parent\",\"alias\":\"$alias\"$rsid,\"optional\":\"N\"}]\n");


  $hasKids=0;
  foreach $line (@lines){
    if ($line =~ m/,$parent,/ and not $line =~ m/^$parent,/) {
      $hasKids=1;
      last;
    }
  }
 
  if ($hasKids){ 
    print FJ (",\"children\":[");
    $childCnt=0;
    foreach $line (@lines){
      if ($line =~ m/,$parent,/ and not $line =~ m/^$parent,/ ) {
        local $kid=$line;
        $kid=~s/,.*$//;
        chop $kid;
        indent_kids("$kid", $childCnt, ",$indent");
        $childCnt++;
      }
    }
    print FJ ("]");  # End of Children
  }
  print FJ ("}\n");  # End of Haplogroup
}

open(FJ, ">", "$jsonFile") or die $!;
open(FT, ">", "$treeFile") or die $!;
print FJ ("{\"PLAY-YDNA-FILE\":[\n");
indent_kids("$root", 0, "");
print FJ ("]}\n");
close(FJ);
close(FT);
