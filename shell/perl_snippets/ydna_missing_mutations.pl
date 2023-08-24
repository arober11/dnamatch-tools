my @lines=`cat $ENV{YDNA_HAPLOGRPS}`;
my @mutes=`cat $ENV{YDNA_HAPGRP_MUTS}`;
my $cnt=0;
my $foundCnt=0;
my $diffCnt=0;
my $tweakCnt=0;
my $missing=1;
my $lnCnt=$#lines+1;
my $baseHaplo;
my $try;

sub check_mutes($) {
  my $checkHaplo;
  ($checkHaplo) = @_;
  foreach my $mut (@mutes) { 
    if ( $mut =~ m/^$checkHaplo,/ ) { 
      $foundCnt++;
      $missing=0;
      last;
    }
  }
}

foreach my $line (@lines) { 
  $line=~s/\n//;
  $cnt++;
  print STDERR "Checking : $cnt    of $lnCnt  -  Found: $foundCnt  -   Missing: $diffCnt\r";
  $baseHaplo=$line; 
  $baseHaplo=~s/@//g;
  if ( $baseHaplo ne $line ) { print STDERR "\nProcessing duplicate: $line\n";}
  $missing=1;
  check_mutes $baseHaplo;
  if ( $missing == 1 ) {
    if ( $baseHaplo =~ m/[ _]or[ _]/ ) {
      $try=$baseHaplo;
      $try=~s/[ _]or[ _].*$//;
      check_mutes $try;
      if ( $missing == 1 ) {
        $try=$baseHaplo;
        $try=~s/^.*[ _]or[ _]//;
        check_mutes $try;
      } 
    } 
    if ( $missing == 0 ) { 
      $tweakCnt++; 
    } else {
      $diffCnt++;
      print STDERR "\nError - missing mutations: $line\n";
    }
  }
}
print STDERR "\nFound: $foundCnt\nTweaked: $tweakCnt\nMissing: $diffCnt\n";
