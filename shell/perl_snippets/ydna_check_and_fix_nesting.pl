my @lines=`cat $ENV{YDNA_TRUNK_NESTED}`;
my $lineLen=0;
my $lastLen=0;
my $lastLn="";
my $nestCnt=0; 
my $fillCnt=0; 
my $lnCnt=$#lines;
my $ln, $newLn, $cmd;

foreach my $line (@lines) { 
      $nestCnt++;
      print STDERR "Checking: $nestCnt    of $lnCnt\r";
      $ln=$line;
      $ln=~s/^([,]*)[^,].*$/\1/;
      $lineLen=$#ln;
      $diff=$lineLen-$lastLen;
      if ( $diff >  1 ) { 
        printf "Error: line: $nestCnt - $lastLen - $lineLen\n$lastLn\n$line\n---------\n";
        if ( $diff == 2 ) {
          $fillCnt++;
          $newLn=substr $line, 1, -1;
          print "inserting between  - $newLn\n";
          $cmd = "$ENV{SED} -i -e '/$lastLn/a $newLn' $ENV{YDNA_TRUNK_NESTED}";
          print "$cmd\n";
          system($cmd);
        }
     }
$lastLn=$line;
$lastLen=$lineLen;
}
print STDERR "Checked: $nestCnt\nBack filled: $fillCnt\n";
