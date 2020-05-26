#!/usr/bin/perl

$USAGETXT="<Project name> <Reward model name> <Performance variable name>\nThis script generates in the current directory the templates for input reward model and performance variable.\n";
if ($#ARGV != 2) {
  print "Usage: $0 ${USAGETXT}";
  exit(0);
}

$ProjectName = $ARGV[0];
$RewardName = $ARGV[1];
$VarName = $ARGV[2];

$MOBIUS_PROJECT = $ENV{'MOBIUS_PROJECT'};

$all_PVMi="\$ALL_PVMi";

$indir="$MOBIUS_PROJECT/$ProjectName/Reward";
$destdir=$ENV{'PWD'};;
$dest1="$destdir/${RewardName}-template.pvm";
$dest2="$destdir/${RewardName}-template-${VarName}.pvm";

if (! -e "$MOBIUS_PROJECT/$ProjectName") {
  print "Project not found: $ProjectName.\n";
  print "Usage: $0 ${USAGETXT}";
  exit(0);
}

if (! -e "$indir/$RewardName") {
  print "Reward model not found: $RewardName.\n";
  print "Usage: $0 ${USAGETXT}";
  exit(0);
}


if (! -e "$indir/$RewardName/$RewardName.pvm") {
  print "Reward model not found: $RewardName.\n";
  print "Usage: $0 ${USAGETXT}";
  exit(0);
}


open(T, "<$indir/$RewardName/$RewardName.pvm");
binmode(T);
$T_pvmAll = join("", <T>);
close(T);

$pvm=$T_pvmAll;
$pvmi="";
while ( $pvm =~ /(<class id="Mobius.RewardModels.pvs.VariableInfo">\s*<int id="ClassVersion">\d+<\/int>\s*<string id="Name">${VarName}<\/string>[\w\W]+<\/class>)/ ) {
  $pvm=$1;
  $pvmi=$1;
  $pvm =~ s/<\/class>$//;
}
if ( $pvmi eq "" ) {
  print "\nPerformance variable ${varName} is not defined\n";
  print "Usage: $0 ${USAGETXT}";
  exit(0);
}

mkdir("$destdir", 0755) || skip;
open (OUT, ">$dest2");
binmode(OUT);
print OUT $pvmi;
close OUT;

print "\nGenerated template: $dest2";

$T_pvmAll =~ s/<\/class>(\s+)<string id="TopModelName">/<\/class>\1${all_PVMi}\n\t\t\t<string id="TopModelName">/g;

mkdir("$destdir", 0755) || skip;
open (OUT, ">$dest1");
binmode(OUT);
print OUT $T_pvmAll;
close OUT;

print "\nGenerated template: $dest1\n\n";

