my @lines = `cat $ENV{YDNA_HAPGRP_MUTS}`;
my $haploGrp="*";
my $thisHaploGrp;
my $cnt=0;
foreach my $ln (@lines) {
  $cnt++; 
  $thisHaploGrp=$ln;
  $thisHaploGrp=~s/^([^,]+),.*/\1/;
  chop $thisHaploGrp;
  chop $ln;
  chop $ln;
  $ln=~s/.$/,\"optional\":\"/; 
  if ($haploGrp eq "*"){ 
    print "$ln"."N\"\}";
  } else { 
    if ($thisHaploGrp ne $haploGrp) { 
      print "]\n"."$ln"."N\"\}";
    } else { 
      $ln =~ s/^[^{]*({.*)/\1Y"}/; 
      print ",$ln"; 
    } 
  } 
  $haploGrp=$thisHaploGrp; 
} 
print "]\n";
