#!/usr/bin/perl

$sep = "\#%%%%\#";
$sep2 = "\#%%%%%\#";

sub evalString {
    $_ = shift @_;
    $_ =~ s/"/$sep/g;
    $_ =~ s/\\/$sep2/g;
    $_ = eval qq/"$_"/;
    $_ =~ s/$sep/"/g;
    $_ =~ s/$sep2/\\/g;
#    $_ =~ s/\r//sg;
#    $_ =~ s/\A(\r|\n)+//;
#    $_ =~ s/(\r|\n)+\Z//;
    return $_;
}


$USAGETXT="<Project name> <Reward model name> <Reward model template name> <Performance variable template name> <imin> <imax>\nThis script generates, in the Reward directory of the project, a reward model file .pvm, including <imax>-<imin>+1 new performance variables based on the input performance variable template file. Each new performance variable is obtained as a function of i=<imin>,...,<imax>, by replacing  with the value of i each occurrence of \${i} in the template.\n";

if ($#ARGV != 5) {
    print "Usage: $0 $USAGETXT";
    exit(0);
}

$ProjectName = $ARGV[0];
$RewardName = $ARGV[1];
$RewardNameT = $ARGV[2];
$VarNameT=$ARGV[3];
$imin = $ARGV[4];
$imax = $ARGV[5];

$MOBIUS_PROJECT = $ENV{'MOBIUS_PROJECT'};

$pvmfile="$RewardName-auto.pvm";

$destdir="$MOBIUS_PROJECT/$ProjectName/Reward/$RewardName";
$dest="$destdir/$pvmfile";

if ($imin>$imax) {
    print "Invalid index range: ${imin} > ${imax}.\n";
    print "Usage: $0 $USAGETXT";
    exit(0);
}

if (! -e "$MOBIUS_PROJECT/$ProjectName") {
    print "Project not found: ${ProjectName}.\n";
    print "Usage: $USAGETXT";
    exit(0);
}

if (! -e "$destdir") {
    print "Reward not found: ${RewardName}.\n";
    print "Usage: $0 $USAGETXT";
    exit(0);
}

if (! -e "$RewardNameT") {
    print "Template not found: ${ReardNameT}.\n";
    print "Usage: $0 $USAGETXT";
    exit(0);
}

if (! -e "$VarNameT") {
    print "Template not found: ${VarNameT}.\n";
    print "Usage: $0 $USAGETXT";
    exit(0);
}

open(T, "<${RewardNameT}");
binmode(T);
$T_pvmAll = join("", <T>);
close(T);

open(T, "<${VarNameT}");
binmode(T);
$T_eachpvmi = join("", <T>);
close(T);

$ALL_PVM=();
$ALL_PVMi=();

for($i=$imin; $i<=$imax; ++$i) {
	$ALL_PVMi.="\n";
	$ALL_PVMi.=&evalString($T_eachpvmi);
}

$ALL_PVM=&evalString($T_pvmAll);

# get NumVars
$count=$imax-$imin+1;
if($ALL_PVM =~ /<int id="NumVars">(\d+)<\/int>/) {
	$count=$count+$1;
}

# update NumVars
$ALL_PVM =~ s/<int id="NumVars">(\d+)<\/int>/<int id="NumVars">$count<\/int>/g;

# save output file
mkdir("$destdir", 0755) || skip;
open (OUT, ">$dest");
binmode(OUT);
print OUT $ALL_PVM;
close OUT;

print "\nGenerated reward file: $dest\n";
