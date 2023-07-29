my @lines = `cat $ENV{YDNA_TRUNK_MERGED}`;
my $ln;
my @dupHaplo = ();
my @sortedDupHaplo = ();
my %haplogroups = {};
my $lnCnt=$#lines;
my $dupCnt=0; 
my $suffCnt=0; 
my $found=0;
my $uniqDup=0;

foreach my $line (@lines){
  $line=~s/^,*([^,]+)/\1/;
  $line=~s/\n//;
  if (exists $haplogroups{$line}) {
    $dupCnt++;
    $haplogroups{$line}++;
    if ( $haplogroups{$line} == 2) {
      push(@dupHaplo, $line);
    }
  } else {
    $haplogroups{$line}=1;
  }
}
@sortedDupHaplo=sort @dupHaplo;
$uniqDup=1+$#sortedDupHaplo;
print "\nDuplicates: $dupCnt - Unique Duplicates: $uniqDup\n";

foreach my $dup (@sortedDupHaplo){
    print "suffixing duplicate instancess of \"$dup\" with a \"@\"\n";
    $found=0;
    foreach my $line (@lines){
      $ln=$line;
      $ln=~s/\n//;
      $haplo=$ln;
      $haplo=~s/^,*([^,]+)/\1/;
      if ( $haplo eq $dup ) {
        if ($found == 1) {
          $ln=~s/^(.*[^,]+)/\1@/;
          $line=$ln;
          $suffCnt++;
        } else { $found = 1; }
      }
    }
}
open(FH, ">", "$ENV{YDNA_TRUNK_MERGED}") or die $!; 
foreach (@lines) { print FH "$_\n"; } close(FH); 
print STDERR "Suffixed: $suffCnt\n"; 
