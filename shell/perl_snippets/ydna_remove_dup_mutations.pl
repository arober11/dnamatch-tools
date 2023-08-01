my $fileName="$ENV{fileName}";
my $dupFlName="dup_posStart-$fileName";

my @lines=`cat $fileName`;
my @dups=`cat $dupFlName`;
my $dupCnt=0;
my $delCnt=0; 

my $lastLn="";
my $lnCnt=$#lines+1;
my $dpCnt=$#dups+1;
my $lastLnNum, $look, $cmd, $tmpLn;

print STDERR "Lines: $lnCnt\nDups: $dpCnt\n";

foreach my $dup (@dups) { 
  $dupCnt++;
  $dup+=0;
  $lastLn="";
  $look="\"posStart\":\"$dup\"";
  print STDERR "$dupCnt - Pos: $dup - $look\n";
  $lastLnNum=0;
foreach my $line (@lines) {
      if ( $line =~ m/$look/ ) {
        if ( $lastLn =~ m/$look/ ) {
          print "Removing duplicate  - $lastLn\n";
          $tmpLn=substr $lastLn, 1, -3;
          $cmd = "gsed -E -i -e '$lastLnNum,$lastLnNum s/$tmpLn/DDDDDDDDDDDDDD/' $fileName";
          system($cmd);
          $delCnt++;
        } 
      }
  $lastLn=$line;
  $lastLnNum++;
  }
}
$cmd = "gsed -E -i -e '/DDDDDDDDDDDDDD/d' $fileName";
print "$cmd\n";
system($cmd);
print STDERR "Checked: $dupCnt\nRemoved: $delCnt\n";
