my @lines = `cat $ENV{YDNA_HAPGRP_MUTS}`;
my $haploGrp="*";
my $thisHaploGrp;
my $opt;
my $cnt=0;
my $lp="";
foreach my $ln (@lines) {
  $cnt++; 
  $thisHaploGrp=$ln;
  $thisHaploGrp=~s/^([^,]+),.*/\1/;
  if ($thisHaploGrp =~ m/~$/) {
    $opt="Y";
  } else {
    $opt="N";
  }
  chop $thisHaploGrp;
  chop $ln;
  chop $ln;
  $ln=~s/.$/,\"optional\":\"/; 
  if ($haploGrp eq "*"){ 
    print "$ln$opt\"\}";
    print STDERR "$lp";
  } else { 
    if ($thisHaploGrp ne $haploGrp) { 
      print "]\n"."$ln$opt\"\}";
      if ($opt eq "N") {
        print STDERR "$lp";
      }
    } else { 
      $ln =~ s/^[^{]*({.*)/\1Y"}/; 
      print ",$ln"; 
    } 
  } 
  $haploGrp=$thisHaploGrp; 
} 
print "]\n";
