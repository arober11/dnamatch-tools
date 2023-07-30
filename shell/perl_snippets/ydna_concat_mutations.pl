my @lines = `cat $ENV{YDNA_HAPGRP_MUTS}`;
my $haploGrp="*";
my $thisHaploGrp;
my $cnt=0;
foreach my $ln (@lines) { 
  $cnt++; 
  $thisHaploGrp=$ln; 
  $thisHaploGrp=~s/^([^,]+),.*$/\1/; 
  chop $ln; 
  chop $ln; 
  if ($haploGrp eq "*"){ 
    print "$ln"; 
  } else { 
    if ($thisHaploGrp ne $haploGrp) { 
      print "]\n$ln";
    } else { 
      $ln =~ s/^[^{]*({[^}]*})/\1/; 
      print ",$ln"; 
    }
  } 
  $haploGrp=$thisHaploGrp; 
} 
print "]\n";

