my @lines = `cat $ENV{YDNA_TRUNK_MERGED}`; 
my @mutes=`cat $ENV{YDNA_HAPGRP_MUTS}`; 
my $lnCnt=$#lines+1;
my $cnt=0;
my $dupCnt=0; 
my $tweakCnt=0;
my $missCnt=0;
my $updCnt=0;
my $missing=1;
my $thisHaploGrp, $baseHaplo, $mutsLn; $ln; 

sub check_mutes($) {
  my $checkHaplo;
  ($checkHaplo) = @_;
  foreach my $mut (@mutes) { 
    if ( $mut =~ m/^$checkHaplo,/ ) { 
      $foundCnt++;
      $missing=0;
      $mutsLn=$mut; 
      $mutsLn=~s/^[^,]*,//;
      $mutsLn=~s/\n//;
      last;
    }
  }
}

foreach my $line (@lines) { 
  $ln=$line; 
  $cnt++;
  print STDERR "Joining: $cnt  of $lnCnt\r"; 
  $thisHaploGrp=$ln; 
  $thisHaploGrp=~s/^,*//; 
  $thisHaploGrp=~s/,.*$//; 
  $thisHaploGrp=~s/\n//; 
  $baseHaplo=$thisHaploGrp; 
  $baseHaplo=~s/@//g; 
  if ( $thisHaploGrp ne $baseHaplo) {$dupCnt++; print STDERR "Processing duplicate: $thisHaploGrp : $baseHaplo\n";} 
  $missing=1;
  check_mutes $baseHaplo;
  if ( $missing == 1 ) {
    if ( $baseHaplo =~ m/[ _]or[ _]/ ) {
      $try1=$baseHaplo;
      $try1=~s/[ _]or[ _].*$//;
      check_mutes $try1;
      if ( $missing == 1 ) {
        $try2=$baseHaplo;
        $try2=~s/^.*[ _]or[ _]//;
        check_mutes $try2;
      } 
      if ( $missing == 0 ) { $tweakCnt++; }
    }
    if ( $missing == 1 ) {
      $diffCnt++;
      print STDERR "\nError - missing mutations for: $line\n";
    }
  }
  if ( $missing == 0 ) {
    $ln=~s/^(,*[^,]+).*$/\1/;
    $ln=~s/\n/,/;
    $line=$ln.$mutsLn;
    $updCnt++;
  } else { $missCnt++; }
}
open(FH, ">", "$ENV{YDNA_HAPGRP_MUTS_TMP}") or die $!; 
foreach (@lines) { print FH "$_\n"; } close(FH); 
print STDERR "Joined: $cnt\nDuplicates: $dupCnt\n"; 

print STDERR "\nRead: $cnt\nMatched and updated: $updCnt\nHad to tweak to match: $tweakCnt\nMissing a mutation: $missCnt\nDuplicates encountered: $dupCnt\n";
