#!/usr/local/bin/perl

# Script used to generate:
# - the makefile_darep files, one for each simulator solver
#   makefile_darep is based on makefile, that has to be defined

use strict;
use warnings;
use feature 'say';
#use File::Spec; #  to get full path of the argument
use Path::Tiny;                 #  to get full path of the argument
use Getopt::Std;                # to parse switches with arguments
use File::Slurp qw( read_file write_file edit_file_lines ); #  Simple and Efficient Reading/Writing/Modifying of Complete Files
use XML::LibXML::Reader; # to load big xml files, for which libxml fails
use XML::Normalize::LibXML qw(trim); # to remove whitespace occuring at beginning or end of string 
use File::Find::Rule; # to find all the subdirectories of a given directory that match a pattern

use constant false => 0;
use constant true  => 1;

# directory where is darep code
my $DAREPDIRNAME="darep";

# get the absolute and relative path of the script (relative path is based on the current directory)
my $MYPATH = path($0)->absolute;
my $MYRPATH = path($0)->relative;
# get the absolute and relative path of the directory where is the script (relative path is based on the current directory)
my $BIN = path($MYPATH)->parent;
my $RBIN = path($BIN)->relative;
my $MYNAME = path($MYPATH)->basename;

# where is all the stuff
# absolute path
my $BASEDIR=path($BIN)->parent(2); # bin/../../
# relative path (relative path is based on the current directory)
my $RBASEDIR=path($BASEDIR)->relative;

# check BASEDIR: it is assumed that directory bin, where is this script, is located in ${BASEDIR}/${DAREPDIRNAME}
if ( ! -e "${BASEDIR}/${DAREPDIRNAME}/bin/${MYNAME}" ) {
    die "Ops! Base directory not correctly defined: ${BASEDIR}"
}

# set darep parameters
#

# extension for Join-Based Replication (DAREP)
my $DAREPACRO="DAREP";             # Join-Based Replication acronym
my $SANDAREPEXT="SAN${DAREPACRO}"; # SAN extension
my $DRSVDAREPEXT="DRSV${DAREPACRO}"; # dependency-related place/state-variable extension

# project path
my $PROJECT="${BASEDIR}";
# project relative path
my $RPROJECT="${RBASEDIR}";
# project name
my $PROJECTNAME=path($PROJECT)->basename;

# darep directory path
my $DAREP="${PROJECT}/${DAREPDIRNAME}";
# input ${DAREPDIRNAME}
my $INPUTPAR="${DAREP}/input";
# DAREP bin
my $DAREPBIN="${BIN}";


# help based on here document approach
sub help {
    my $message = qq{
Usage: $0 [-h] [-s <solvername>] [xmlinputfilename]
 -h (optional argument): help info.
 -s (optional argument)
 <inputxmlfile> (optional argument): the path, local to the directory ${DAREP}/input, of the input xml file. It cannot be a full global path. If omitted, the last current input file is used.

This script generates:
   - one makefile_darep file for each simulator solver, 
     if option -s is omitted, or 
   - only makefile_darep file for <solvername>, with option -s.
       };
    print STDERR $message;
    exit 1
}


################## main #############################

# declare the perl command line flags/options we want to allow
my %options=();
# If \%optsis specified the $opt_ variables are not set
#our($opt_s);
if ( !getopts("hfs:", \%options) ) {
    help();
    die
}
my $fflag=false;
my $sflag=false;
my $sarg="";
if ($options{h}) {
    help();
} elsif ($options{f}) {
    $fflag=true;
} elsif ($options{s}) {
    $sflag=true;
    $sarg=$options{s};
}
    
if ( @ARGV > 1 ) {
    say STDERR "Ops! Too many arguments!";
    help();
    exit 1
}


# file where is saved the path of the last current input file
my $CURRXMLDAREPEPINPUTPATH="${DAREP}/current.txt";

# darep input xml file, path relative to the input darep directory
my $RXMLDAREPEPINPUT;
if ( @ARGV == 1 ) {
    $RXMLDAREPEPINPUT="$ARGV[0]";
    # debug info
    #say STDERR "$RXMLDAREPEPINPUT";
}


# if no input file you can use last current input file
if ( ! defined ${RXMLDAREPEPINPUT} ) {
    say "No input file. Use current last input file:";
    if ( -f ${CURRXMLDAREPEPINPUTPATH} ) {
        # darep input xml file, path relative to the input darep directory
        $RXMLDAREPEPINPUT=read_file($CURRXMLDAREPEPINPUTPATH);
        chomp $RXMLDAREPEPINPUT;
        say STDERR $RXMLDAREPEPINPUT;
    } else { # current file not found
        say STDERR "Current  file not found. Bye!";
        exit 1;
    }
}
# debug info
#say STDERR "RXMLDAREPEPINPUT: " . $RXMLDAREPEPINPUT;


# no input file, dont use last current file: then exit
# check if input file is defined
if (  ! defined ${RXMLDAREPEPINPUT} ) {
    say STDERR "Ops! Input file is not defined.";
    help();
    exit 1;
}

# check relative path
if (  path($RXMLDAREPEPINPUT)->is_absolute ) {
    say STDERR "Ops! Input file name cannot be a global path: ${RXMLDAREPEPINPUT}";
    help();
    exit 1;
}

# darep input xml file, absolute path
my $XMLDAREPEPINPUT="${INPUTPAR}/${RXMLDAREPEPINPUT}";
# debug info
#say STDERR $XMLDAREPEPINPUT;

# check input xml file
if( ! -f  "$XMLDAREPEPINPUT" ) {
    say STDERR "Ops! Input xml file not found: $XMLDAREPEPINPUT";
    help();
    exit 1
}

# load darep input file
my $xmldarepin = 'XML::LibXML::Reader'->new( location => $XMLDAREPEPINPUT )
    or die "Can't open file: $XMLDAREPEPINPUT\n";

# chek darep input
# my $xmldarep="";
if( $xmldarepin->nextElement('darepinput') ) { 
    # $xmldarep = $xmldarepinput->copyCurrentNode(1);
} else {
    die "Node not found: darepinput\n";
}

# get the name of the template SAN from input xml file
# using perl XML::LibXML::Reader
my $sandarep="";
if( $xmldarepin->nextElement('SANDAREP') ) { 
    $sandarep = $xmldarepin->copyCurrentNode(1);
} else {
    die "Node not found: SANDAREP\n";
}
# SAN template name
my $TEMPLATESANNAME = trim($sandarep->findvalue('name'));
# debug info
#say STDERR "TEMPLATESANNAME: $TEMPLATESANNAME";

# check empty SAN template name
if( $TEMPLATESANNAME eq "" ) {
    say STDERR "Ops! SAN template not defined in input file!";
    help();
    exit 1
}

# get the number of SAN template replicas
my $NREPS = trim($sandarep->findvalue('replicasNumber'));
# maximum index of replicas, the index starts from 0: nreps-1
my $NREPSM1=$NREPS-1;
# debug info
#say STDERR "$NREPSM1";


# solvers dir
my $SOLVER="${PROJECT}/Solver";
#say ${SOLVER};
    
# makefile
my $MAKEFILENAME="makefile";
    
# makefile_darep
my $MAKEFILEDAREPNAME="${MAKEFILENAME}_${DAREPDIRNAME}";

# debug extension
my $DEBUGEXT="_debug";
    
# make list for PROJECTLIBS
my $PROJECTLIBSANDAREPS="";
foreach my $sanind ( 0..$NREPSM1 ) { # for each template SAN replica i
    $PROJECTLIBSANDAREPS.=" -l${TEMPLATESANNAME}${SANDAREPEXT}${sanind}SAN"
}

# make list for PROJECTLIBS_debug
my $PROJECTLIBDEBSANDAREPS="";
foreach my $sanind ( 0..$NREPSM1 ) { # for each template SAN replica i
    $PROJECTLIBDEBSANDAREPS.=" -l${TEMPLATESANNAME}${SANDAREPEXT}${sanind}SAN${DEBUGEXT}"
}

# make list for clean_sub_dirs
my $CLEANSANDAREPS="";
foreach my $sanind ( 0..$NREPSM1 ) { # for each template SAN replica i
    $CLEANSANDAREPS .= "\tcd ../../Atomic/${TEMPLATESANNAME}${SANDAREPEXT}${sanind}/ \&\& \$(MAKE) clean\n";
}
#say "CLEANSANDAREPS: $CLEANSANDAREPS";

# make list for submodels opt and submodels debug
my $SUBOPTDEBSANDAREPS="";
foreach my $sanind ( 0..$NREPSM1 ) { # for each template SAN replica i
    $SUBOPTDEBSANDAREPS .= "\t\@echo \"NEW_SUBMODEL_LIB:\[${TEMPLATESANNAME}${SANDAREPEXT}${sanind}\]\"\n\tcd ../../Atomic/${TEMPLATESANNAME}${SANDAREPEXT}${sanind}/ \&\& \$(MAKE) \$(\@F)\n";
}
#say "SUBOPTDEBSANDAREPS: $SUBOPTDEBSANDAREPS";

my @SIMSOLVERS=();
my @NOSIMSOLVERS=();
if ( $sflag eq true )  {                        # consider only input solver
    push @SIMSOLVERS, "${SOLVER}/$sarg";
} else {            # consider all solver simulator
    # get simulation solvers based on the row: MAINLIB=-lsimMain
    @SIMSOLVERS = File::Find::Rule->directory()
        ->maxdepth(1)
        ->exec( sub{
                    my $file="${SOLVER}/$_/${MAKEFILENAME}";
                    if ( -f "${file}" ) {
                        #say "*** ${file}";
                        open(my $fh, '<:encoding(UTF-8)', ${file}) or die "Could not open file '$file' $!";
                        my $found=false;
                        while (<$fh>) {
                            if ( $_ =~ /MAINLIB=-lsimMain/ ) {
                                $found=true;
                                last;
                            }
                        }
                        close($fh);
                        if ( $found ) {
                            #say "*** found!";
                            return $_
                        }
                    }
                } )->in( ${SOLVER} );
    #say @SIMSOLVERS;

    # get not matching simulation solvers
    @NOSIMSOLVERS = File::Find::Rule->directory()
        ->maxdepth(1)
        ->exec( sub{
                    my $file="${SOLVER}/$_/${MAKEFILENAME}";
                    my $found=false;
                    if ( -f "${file}" ) {
                        #say "*** ${file}";
                        open(my $fh, '<:encoding(UTF-8)', ${file}) or die "Could not open file '$file' $!";
                        while (<$fh>) {
                            if ( $_ =~ /MAINLIB=-lsimMain/ ) {
                                $found=true;
                                last;
                            }
                        }
                        close($fh);
                    }
                    if ( !$found && "$_" ne "." ) {
                        #say "*** found!";
                        return $_
                    }
                } )->in( ${SOLVER} );
    #say STDERR @NOSIMSOLVERS;

} 

foreach (@SIMSOLVERS) { # for each solver for which makefile is defined
   #$solvername =~ s/.*\/(.*$)/$1/; # get solver name
   #my $solvername = $_;
   #say $solvername;

    my $makefile="$_/${MAKEFILENAME}";
    #say "makefile: $makefile";

    my $makefiledarep="$_/${MAKEFILEDAREPNAME}";
    #say "makefiledarep: $makefiledarep";

    # generate new makefile
    my $newcontent="";
    open(my $fh, '<:encoding(UTF-8)', ${makefile}) or die "Could not open file '$makefile' $!";
    while(<$fh>) {
        if( $_ =~ /^\s*PROJECTLIBS=/ ) {
            #say "--- $_";
            $_ =~  s/\s*-l${TEMPLATESANNAME}${SANDAREPEXT}[0-9]+SAN//g; # remove SANDAREP
            chomp $_;
            $_ .= "${PROJECTLIBSANDAREPS}\n";
            #say "+++ $_";
        }
        if( $_ =~ /^\s*PROJECTLIBS${DEBUGEXT}=/ ) {
            #say "--- $_";
            $_ =~  s/\s*-l${TEMPLATESANNAME}${SANDAREPEXT}[0-9]+SAN${DEBUGEXT}//g; # remove SANDAREP
            chomp $_;
            $_ .= "${PROJECTLIBDEBSANDAREPS}\n";
            #say "+++ $_";
        }
        if( $_ =~ /^\s*clean_sub_dirs:/ ) {
            $_ .= "$CLEANSANDAREPS";
            #say "$_";
        }
        if( $_ =~ /^\s*cd \.\.\/\.\.\/Atomic\/${TEMPLATESANNAME}${SANDAREPEXT}[0-9]+\/\s+\&\&\s+\$\(MAKE\)\s+clean/ ) { # skip
            $_ = "";
            #say "******"
        }
        if( $_ =~ /^\s*SUBMODELS\/opt SUBMODELS\/debug:/ ) {
            $_ .= "$SUBOPTDEBSANDAREPS";
            #say "$_";
        }
        if( $_ =~ /^\s*\@echo \"NEW_SUBMODEL_LIB:\[${TEMPLATESANNAME}${SANDAREPEXT}[0-9]+\]\"/ ) { # skip
            $_ = "";
            #say "******"
        }
        if( $_ =~ /^\s*cd \.\.\/\.\.\/Atomic\/${TEMPLATESANNAME}${SANDAREPEXT}[0-9]+\/\s+\&\&\s+\$\(MAKE\)\s+\$\(\@F\)/ ) { # skip
            $_ = "";
            #say "******"
        }
        $newcontent .= $_;
    }
    close($fh);
    # write makefile darep
    write_file($makefiledarep, \$newcontent);

}


if ( @NOSIMSOLVERS >0 ) {
    say STDERR "Ops! Missing makefile, makefile_darep cannot be generated for following solvers: ";
    foreach (@NOSIMSOLVERS) {
        say STDERR "   $_";
    }
    say STDERR "Generate makefiles using GUI.";
    say STDERR "Then relaunch this script.";
}
