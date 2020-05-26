#!/usr/local/bin/perl
#
# - on MacOSX use /opt/local/bin/perl5.26:
#   sudo ln -s /opt/local/bin/perl5.26 /usr/local/bin/perl
# -on linux use /usr/bin/perl:
#   sudo ln -s /usr/bin/perl /usr/local/bin/perl
#
# You can use same path /usr/local/bin/gawk on both systems, as follow:
#  - on MacOSX, add the symbolic link /usr/local/bin/gawk -> /sw/bin/awk, as follow:
#     cd /usr/local/bin; sudo ln -s /sw/bin/awk gawk
#  - on Linux, add the symbolic link /usr/local/bin/gawk -> /usr/bin/gawk, as follow:
#     cd /usr/local/bin; sudo ln -s /usr/bin/awk gawk


# Script used to generate darep models and data structures

use strict;
use warnings;
use feature 'say';
#use File::Spec; #  to get full path of the argument
use Path::Tiny; #  to get full path of the argument
use Getopt::Std; # to parse switches with arguments
use File::Touch; # touch command
use File::Cat; # cat command
use IO::Prompter; # to prompt message and read input
use File::Slurp qw( read_file write_file edit_file_lines ); #  Simple and Efficient Reading/Writing/Modifying of Complete Files
use Config; # to detect os type
use if ($^O eq 'linux'), 'Linux::Distribution' => qw(distribution_name distribution_version); # to detect a Linux distribution
use XML::LibXML::Reader; # to load big xml files, for which libxml fails
use XML::Normalize::LibXML qw(trim); # to remove whitespace occuring at beginning or end of string 
use File::Find::Rule; # to find all the subdirectories of a given directory that match a pattern
use File::Path qw(remove_tree); # to remove a list of directories
use Text::Xslate; # Template engine much faster than any other template engines.
use Text::Xslate::Syntax::Kolon; # Template engine, to use Kolon format
use XML::Entities; # Decode strings with XML entities (to decode special chars)
#use XML::LibXML::PrettyPrint 0.001 qw(print_xml);

#use Config;
#my $osname = "$Config{osname}\n";
#my $osname = $^O;

use constant false => 0;
use constant true  => 1;

# directory where is darep code
my $DAREPDIRNAME="darep";

# OS type
my $OSTYPE = "$Config{osname}";
# set xqilla path based on OS
my $LIB="lib";
# set xqilla path based on OS
if ( $OSTYPE eq 'linux' && Linux::Distribution->new->distribution_name() eq 'suse' ) {
    $LIB="lib64";
}
#my $XQILLA="/usr/local/${LIB}/xqilla/bin/xqilla";

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
    say STDERR "Ops! Base directory not correctly defined: ${BASEDIR}";
    exit 1;
}

# debug info
#say STDERR "MYPATH: $MYPATH";
#say STDERR "\$0: $0";
#say STDERR "XQILLA: $XQILLA";
#say STDERR "MYNAME: $MYNAME";
#say STDERR "BIN: $BIN";
#say STDERR "RBIN: $RBIN";
#say STDERR "MYPATH: $MYPATH";
#say STDERR "MYRPATH: $MYRPATH";
#say STDERR "BASEDIR: $BASEDIR";
#say STDERR "RBASEDIR: $RBASEDIR";

# set darep parameters
#

# extension for Join-Based Replication (DAREP)
my $DAREPACRO="DAREP"; # Join-Based Replication acronym
my $SANDAREPEXT="SAN${DAREPACRO}";     # SAN extension
my $DRSVDAREPEXT="DRSV${DAREPACRO}"; # dependency-related place/state-variable extension

# project path
my $PROJECT="${BASEDIR}";
# project relative path
my $RPROJECT="${RBASEDIR}";
# project name
my $PROJECTNAME=path($PROJECT)->basename;

# debug info
#say STDERR "PROJECT: " . $PROJECT;
#say STDERR "RPROJECT: " . $RPROJECT;
#say STDERR "PROJECTNAME: " . $PROJECTNAME;

# Atomic
my $ATOMIC="${PROJECT}/Atomic";
# Atomic relative path
my $RATOMIC="${RPROJECT}/Atomic";

# Composed
my $COMPOSED="${PROJECT}/Composed";
# composed model ext
my $COMPOSEDMODELEXT="cmp";

# darep directory path
my $DAREP="${PROJECT}/${DAREPDIRNAME}";
# input ${DAREPDIRNAME}
my $INPUTPAR="${DAREP}/input";
# DAREP bin
my $DAREPBIN="${BIN}";
# xquery ${DAREPDIRNAME}
my $XQUERY="${DAREP}/xquery";
# xquery bin
my $XQUERYBIN="${XQUERY}/bin";
# xquery output ${DAREPDIRNAME}
my $XQUERYAUTO="${DAREP}/xquery/auto";
# prj file
my $PRJFILE="${PROJECT}/${PROJECTNAME}.prj";
# cpp directory
my $DAREPCPP="${DAREP}/c++";
# cpp templates directory
my $CPPTEMPLATES="${DAREPCPP}/templates"; # absolute path
my $LCPPTEMPLATES="c++/templates"; # path local to DAREP
# automatic cpp files
my $CPPAUTO="${DAREP}/c++/auto";
# composed cmp templates directory
my $CMPTEMPLATES="${DAREP}/composed/templates"; # absolute path
my $LCMPTEMPLATES="composed/templates"; # path local to DAREP
# automatically generated file .h where are C++ declarations of spacenames and data structures for DAREP
my $CPPDAREPIN="${CPPAUTO}/darep_in.h";
# automatically generated file .h where are C++ definitions of spacenames and data structures for DAREP
my $CPPDAREPDEFIN="${CPPAUTO}/darep_def_in.h";

# xml for cpp template files
#######################################
# template darep_in
my $CPPTDAREPIN="${LCPPTEMPLATES}/cpp_darep_in.tmpl";
# template darep_in_san
my $CPPTDAREPINSAN="${LCPPTEMPLATES}/cpp_darep_in_san.tmpl";
# template darep_in_drsv
my $CPPTDAREPINDRSV="${LCPPTEMPLATES}/cpp_darep_in_drsv.tmpl";
# template darep_in_dummydrsv
my $CPPTDAREPINDUMMYDRSV="${LCPPTEMPLATES}/cpp_darep_in_dummydrsv.tmpl";
# template darep_in_get_drstatevar
my $CPPTDAREPINGETDRSTATEVAR="${LCPPTEMPLATES}/cpp_darep_in_get_drstatevar.tmpl";
# template darep_in_def_drstatevar
my $CPPTDAREPINDEFDRSTATEVAR="${LCPPTEMPLATES}/cpp_darep_in_def_drstatevar.tmpl";
# template darep_def_in
my $CPPTDAREPDEFIN="${LCPPTEMPLATES}/cpp_darep_def_in.tmpl";
# template darep_def_in_san
my $CPPTDAREPDEFINSAN="${LCPPTEMPLATES}/cpp_darep_def_in_san.tmpl";
# template custom_init_SAN for the custom initialization code
my $CPPTCUSTOMINITSAN="${LCPPTEMPLATES}/cpp_custom_init_SAN.tmpl";
# template customize_SAN_h to get the c++ file included in custom initialization code
my $CPPTCUSTOMIZESANH="${LCPPTEMPLATES}/cpp_customize_SAN_h.tmpl";
# template to include the list of DRSV names
my $CPPTLISTDRSVNAMESSAN="${LCPPTEMPLATES}/cpp_listdrsvnames_SAN.tmpl";
# template to include the customized list of DRSV names, based on the actual used DRSV
my $CPPTLISTCUSTOMDRSVNAMESSAN="${LCPPTEMPLATES}/cpp_listcustomdrsvnames_SAN.tmpl";
# template to include the list of global indexes of replicas of DASVs
my $CPPPARAMSREPINDT="${LCPPTEMPLATES}/cpp_replicaindexes.tmpl";

# xml for composed cmp template files
#######################################
# template cmp model
my $COMPOSEDCMPT="${LCMPTEMPLATES}/cmp.tmpl";
# template shared object
my $SHAREDOBJECTT="${LCMPTEMPLATES}/sharedobject.tmpl";
# template composed atomic
my $COMPOSEDATOMICT="${LCMPTEMPLATES}/composedatomic.tmpl";
# template join-san edge
my $COMPOSEDATOMICEDGET="${LCMPTEMPLATES}/edge.tmpl";
# template composed for prj file
my $COMPOSEDPRJT="${LCMPTEMPLATES}/prjcomp.tmpl";

# xquery files
#######################################
# to get template san name
my $XQUERY_SANNAME="${XQUERY}/sanname.xquery";
# to make SANs
my $XQUERY_SANREP="${XQUERY}/sanrep.xquery";
# to update prj file for atomic models
my $XQUERY_PRJSAN="${XQUERY}/prjsan.xquery";
# to update prj file for composed model
my $XQUERY_PRJCMP="${XQUERY}/prjcmp.xquery";
# to remove exceeding san
my $XQUERY_PRJ_REMEXCEEDSAN="${XQUERY}/prjremexcedingsan.xquery";
# to make join
my $XQUERY_JOIN="${XQUERY}/join.xquery";
# to make C++ code: customize SAN .h files
my $XQUERY_CPPCUSTOMIZESAN="${XQUERY}/cppcustomizesan.xquery";
# to make C++ code: darep_in.h
my $XQUERY_CPPDAREPIN="${XQUERY}/cppdarepin.xquery";
# to make C++ code: darep_def_in.h
my $XQUERY_CPPDAREPDEFIN="${XQUERY}/cppdarepdefin.xquery";
# to make composed darep model using perl
my $XQUERY_PERL_COMPOSEDCMPMODEL="${XQUERY}/bin/composedcmpmodel.pl";

# debug info
#say STDERR "$XQUERY_PERL_COMPOSEDCMPMODEL";

#
# end set darep parameters

# help based on here document approach
sub help {
    my $message = qq{
This script generates the darep models and the C++ data structures.
      Usage: $0 [-h] [-f] [<inputxmlfile>]
            -f (optional argument): force script to answer yes to all prompts.
            -h (optional argument): help info.
            <inputxmlfile> (optional argument):         the path, local to the directory ${DAREP}/input, of the input xml file. It must not be a full global path. If omitted, the last current input file is used. 
            Examples of erroneous and correct input paths, considering the input file <${DAREP}/input/scenario1/input.xml>
            $0 ./input/scenario1/input.xml   (erroneous input path)
            $0 ./scenario1/input.xml   (correct path, relative to the directory ${DAREP}/input)
        };
    print STDERR $message;
    exit 1
}


# get the template SAN name, get by input xml file
#
# using XQILLA
#
#my $cmd="${XQILLA} -u ${XQUERY_SANNAME} -i $XMLDAREPEPINPUT";
#my $cmd=q(${XQILLA} -u <(echo 'for $myn in ./darepinput/SANDAREP/name return fn:normalize-space(fn:string($myn))' ) -i $XMLDAREPEPINPUT);
#$TEMPLATESANNAME=`echo \"$cmd\" | /bin/bash -s`;
#chomp $TEMPLATESANNAME;
#
# using perl XML::LibXML::Reader
#
# load darep input file
#my $xmldarepin = 'XML::LibXML::Reader'->new( location => $XMLDAREPEPINPUT )
#    or die "Can't open file: $XMLDAREPEPINPUT\n";
#my $pattern = XML::LibXML::Pattern->new('/darepinput/SANDAREP/name');
#if( $xmldarepin->nextPatternMatch($pattern) ) { 
#    $TEMPLATESANNAME = trim($xmldarepin->readInnerXml());
#} else {
#    die "Node not found: $pattern\n";
#}
#
# using perl XML::LibXML
#
# load darep input file
#my $xmldarepin = 'XML::LibXML'->load_xml( location => $XMLDAREPEPINPUT )
#    or die "Can't open file: $XMLDAREPEPINPUT\n";
#$TEMPLATESANNAME = trim($xmldarepin->findvalue('/darepinput/SANDAREP/name'));


# get the number of instances of the SAN template
#
# using XQILLA
#
#my $cmd="${XQILLA} -u <(echo 'fn:number(./darepinput/SANDAREP/replicasNumber)' ) -i $XMLDAREPEPINPUT";
#$NREPS=`echo \"$cmd\" | /bin/bash -s`;
#chomp $NREPS;
#
# using perl XML::LibXML
#
#$NREPS=trim($xmldarepin->findvalue('/darepinput/SANDAREP/replicasNumber'));


# perl function
# make $_[0]+1 directories having path $_[1]${i}, for $i=0..$_[0] 
# $_[0]: number of directories minus one
# $_[1]: the base path of the directories
sub makedirs {
    foreach ( 0..$_[0] ) { 
        my $sandestdir=$_[1] . $_;
        if ( ! -d $sandestdir ) {
            mkdir $sandestdir
        }
    }
}


#
# perl function
# remove exceeding SAN<ext><i> from prj file

# using XQILLA
#
#my $cmd="${XQILLA} -u ${XQUERY_PRJ_REMEXCEEDSAN} -v tsannameext ${TEMPLATESANNAMEEXT} -v nreps ${NREPS} -i ${PRJFILE}";

# remove exceeding SAN replicas (i>=nreps) from prj file
# using perl XML::LibXML, version 0
#
# $_[0]: prj file path
# $_[1]: template SAN name with darep ext
# $_[2]: number of SAN replicas
# $_[3]: template SAN name
sub removesanexceedprj_loadsave_v0 {
    my ($PRJFILE, $TEMPLATESANNAMEEXT, $NREPS, $TEMPLATESANNAME) = @_;
    my $removed = false;
    my $xmlprj = 'XML::LibXML'->load_xml( location => $PRJFILE )
        or die "Can't open file: $PRJFILE\n";
    for my $atomicmodel ($xmlprj->findnodes('/models:Project/atomic')) {
        my $atomicmodelname=trim($atomicmodel->findvalue('@key'));
        (my $baseatomicmodelname = $atomicmodelname) =~ s/[0-9]+$//;
        if ( $baseatomicmodelname=$TEMPLATESANNAMEEXT ) { # if darep san
            if ( $atomicmodelname =~ m/[\D]*(\d+)$/ ) { # if indexed SAN
                if ( $1>=$NREPS ) { # san exceeding index $1
                    $atomicmodel->unbindNode; # remove node
                    $removed = true;
                }
            }
        }
        # debug info
        #say STDERR $atomicmodel;
        #say STDERR "atomicmodelname: $atomicmodelname";
        #say STDERR $baseatomicmodelname;
        #say STDERR "i: $1";
    }
    $xmlprj->toFile($PRJFILE);  # update prj file
    if( $removed ) {
        say "*** Removed from prj file the exceeding replicas of SAN template: ${TEMPLATESANNAME}";
    }
}

# remove exceeding SAN replicas (i>=nreps) from prj file
# using perl XML::LibXML, version 1
#
# $_[0]: prj file path
# $_[1]: template SAN name with darep ext
# $_[2]: number of SAN replicas
# $_[3]: template SAN name
sub removesanexceedprj_loadsave_v1 {
    my ($PRJFILE, $TEMPLATESANNAMEEXT, $NREPS, $TEMPLATESANNAME) = @_;
    my $removed = false;
    my $xmlprj = 'XML::LibXML'->load_xml( location => $PRJFILE )
        or die "Can't open file: $PRJFILE\n";
    for my $atomicmodel ($xmlprj->findnodes('/models:Project/atomic')) {
        if( trim($atomicmodel->findvalue('@key')) =~ m/^\s*${TEMPLATESANNAMEEXT}([0-9]+)\s*$/ and $1>=$NREPS ) { # if darep san and san exceeding index $1
            $atomicmodel->unbindNode; # remove node
            # debug info
            #say STDERR $atomicmodel;
            #say STDERR "atomicmodelname: " . trim($atomicmodel->findvalue('@key'));
        }
    }
    $xmlprj->toFile($PRJFILE);  # update prj file
    say "*** Removed from prj file (if any) the exceeding replicas of SAN template: ${TEMPLATESANNAME}";
}

# remove exceeding SAN replicas (i>=nreps) from prj file
# using perl XML::LibXML, current version
#
# $_[0]: prj file path
# $_[1]: template SAN name with darep ext
# $_[2]: number of SAN replicas
# $_[3]: template SAN name
sub removesanexceedprj_loadsave {
    my ($PRJFILE, $TEMPLATESANNAMEEXT, $NREPS, $TEMPLATESANNAME) = @_;
    my $removed = false;
    my $xmlprj = 'XML::LibXML'->load_xml( location => $PRJFILE )
        or die "Can't open file: $PRJFILE\n";
    for my $atomicmodel ($xmlprj->findnodes(
        qq{/models:Project/atomic[
                 \@key = concat("$TEMPLATESANNAMEEXT", number(substring-after(\@key, "$TEMPLATESANNAMEEXT"))) and 
                 number(substring-after(\@key, "$TEMPLATESANNAMEEXT"))>="$NREPS"
                                 ]
           }
       )) {
        $atomicmodel->unbindNode; # remove node
        # debug info
        #say STDERR $atomicmodel;
        #say STDERR "atomicmodelname: " . trim($atomicmodel->findvalue('@key'));
    }
    $xmlprj->toFile($PRJFILE);  # update prj file
    say "*** Removed from prj file (if any) the exceeding replicas of SAN template: ${TEMPLATESANNAME}";
}


# remove exceeding SAN replicas (i>=nreps) from prj file
# using perl XML::LibXML, working on already loaded file
#
# $_[0]: reference to prj loaded file
# $_[1]: template SAN name with darep ext
# $_[2]: number of SAN replicas
# $_[3]: template SAN name
sub removesanexceedprj {
    my ($xmlprj_ref, $TEMPLATESANNAMEEXT, $NREPS, $TEMPLATESANNAME) = @_;
    my $removed = false;
    for my $atomicmodel (${$xmlprj_ref}->findnodes(
        qq{/models:Project/atomic[
                 \@key = concat("$TEMPLATESANNAMEEXT", number(substring-after(\@key, "$TEMPLATESANNAMEEXT"))) and 
                 number(substring-after(\@key, "$TEMPLATESANNAMEEXT"))>="$NREPS"
                                 ]
           }
       )) {
        $atomicmodel->unbindNode; # remove node
        # debug info
        #say STDERR $atomicmodel;
        #say STDERR "atomicmodelname: " . trim($atomicmodel->findvalue('@key'));
    }
    say "*** Removed from prj file (if any) the exceeding replicas of SAN template: ${TEMPLATESANNAME}";
}


# add replicas SAN<ext><i> to prj file
# using perl XML::LibXML, working on already loaded file
#
# $_[0]: reference to prj loaded file
# $_[1]: template SAN name
# $_[2]: SAN darep ext
# $_[3]: number of SAN replicas
sub addsanrepsprj {
    my ($xmlprj_ref, $TEMPLATESANNAME, $SANDAREPEXT, $NREPS) = @_;
    my $prjroot = ${$xmlprj_ref}->findnodes('/models:Project')->[0];
    my $atomicmodel = $prjroot->findnodes(
        qq(atomic[ \@key = "$TEMPLATESANNAME" ] ) )->[0];
    foreach my $i (0..($NREPS-1)) { # for each SAN index
        my $sandarepname = $TEMPLATESANNAME . $SANDAREPEXT . $i;
        if( $prjroot->findnodes(
            qq(atomic[ \@key = "$sandarepname" ] ) )->size()==0
        ) { # add not existing SAN<ext><i> node
            my $tatomicmodel = $atomicmodel->cloneNode(1); # a copy of the template SAN node
            # rename @key to SAN<ext><i>
            $tatomicmodel->setAttribute( 'key', $sandarepname );
            # rename value/@name to SAN<ext><i>
            $tatomicmodel->findnodes('value')->[0]->setAttribute( 'name', $sandarepname );
            # insert new SAN<ext><i> node
            $prjroot->insertBefore( $tatomicmodel, $atomicmodel );
        } # else skip already existing SAN<ext><i>
    } # for each replica
    
    say "*** Updated prj file with replicas of SAN template: ${TEMPLATESANNAME}.";
}


# add composed model to prj file
# using perl XML::LibXML, working on already loaded prj file
#
# $_[0]: reference to prj loaded file
# $_[1]: reference to composed prj string
# $_[2]: composed model name
sub addcmpprj {
    my ($xmlprj_ref, $prjcompstr_ref, $COMPOSEDMODELNAME) = @_;
    my $prjroot = ${$xmlprj_ref}->findnodes('/models:Project')->[0];
    # get last atomic model
    my $lastatomicmodel = $prjroot->findnodes('atomic[last()]')->[0];
    # get new node, no_blanks => 1 remove whitespace-only text nodes
    my $newNode = XML::LibXML->load_xml(string => ${$prjcompstr_ref},
                                    no_blanks => 1)->findnodes('/composed')->[0]; 

    if( $prjroot->findnodes(
        qq( composed[\@key="$COMPOSEDMODELNAME"] ) )->size() == 0
    ) { # add not existing composed node after last atomic model
        $prjroot->insertAfter( $newNode, $lastatomicmodel );
    } # else skip already existing composed node
    
    say "*** Updated prj file with with composed file: ${COMPOSEDMODELNAME}.";
}


# perl sub equivalent of the -pi command line options of one-liner Perl.
#
# update input file, merging broken lines included in <string>...</string> tags,
# removing starting and ending blanks,
# i.e., remove string breaks from <string>...</string> tags
#
my $strv=0;
sub removecodebreaks {
    if(/<string/){
        s/[\t]*\n$//g;
        $strv=1;
    } else {
        if($strv==1){
            s/^[\t]*//g;
            s/[\t]*\n$//g;
        } 
    }
    #print;
    if(/<\/string>/){
        #print "\n";
        $_ .="\n";
        $strv=0;
    }
}

################## main #############################

# declare the perl command line flags/options we want to allow
my %options=();
if ( !getopts("hf", \%options) ) {
    help();
    die
}
my $fflag=false;
if ($options{h}) {
    help();
} elsif ($options{f}) {
    $fflag=true;
}
;

# check if xqilla command exists
#if ( ! -x "${XQILLA}" ) {
#    say STDERR "Ops! XQILLA command path not found: ${XQILLA}";
#    exit 1
#}

if ( @ARGV > 1 ) {
    say STDERR "Ops! Too many arguments!";
    help();
    exit 1
}

# file where is saved the path of the last current input file
my $CURRXMLDAREPEPINPUTPATH="${DAREP}/current.txt";
if ( ! -f "${CURRXMLDAREPEPINPUTPATH}" ) {
    touch(${CURRXMLDAREPEPINPUTPATH});
}

# darep input xml file, path relative to the input darep directory
my $RXMLDAREPEPINPUT;
if ( @ARGV == 1 ) {
    $RXMLDAREPEPINPUT="$ARGV[0]";
    # debug info
    #say STDERR "$RXMLDAREPEPINPUT";
}

# if no input file you can use last current input file
if ( ! defined ${RXMLDAREPEPINPUT} ) {
    say "No input file. Current last input file:";
    cat(${CURRXMLDAREPEPINPUTPATH}, \*STDOUT);
    my $response="n";
    if ( $fflag ) {
        say "\nContinue, using current last input file? [Y/n]y";
        $response = "y";
    } else {
        $response = prompt "\nContinue, using current last input file? [Y/n]", -stdio;
    }
    if ( $response =~ /y/i or $response eq '' ) {
        # set current input file
        if ( -f ${CURRXMLDAREPEPINPUTPATH} ) {
            # darep input xml file, path relative to the input darep directory
            $RXMLDAREPEPINPUT=read_file($CURRXMLDAREPEPINPUTPATH);
            chomp $RXMLDAREPEPINPUT;
            if( $RXMLDAREPEPINPUT eq "" ) {
                say STDERR "Ops! Current last input file is not defined, empty file: $CURRXMLDAREPEPINPUTPATH\nPlease use <inputxmlfile>.\n";
                exit 1;
            }
        }
    } else {
        # if no, continue whithout input file
        say STDERR "Bye!";
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

# save path of current file
write_file($CURRXMLDAREPEPINPUTPATH, \$RXMLDAREPEPINPUT) ;

# templates files init
my $tx = Text::Xslate->new(
    path => $DAREP,
    cache_dir => "$ENV{HOME}/.xslate_cache",
    cache => 1,
    syntax => 'Text::Xslate::Syntax::Kolon',
    type => 'text'
    );


# load templates
#######################

# make c++ code for SAN replicas
###################################

# load into a string the template file for the c++ code where appears the list of the DRSV names
$tx->load_file($CPPTLISTDRSVNAMESSAN);
# load cpp_customize_SAN template file into a string
$tx->load_file($CPPTCUSTOMIZESANH);
# variables for the c++ templates ($CPPTLISTDRSVNAMESSAN, $CPPTCUSTOMIZESANH) including code with the list of names
my %vars_cpp_listdrsvnames = (
     TEMPLATESANNAME => "",
     sanind => "",
     drsvname => "",
     drsvrepnames => ""
    );

# load into a string the template file for the c++ code where appears the customized list of the DRSV names
$tx->load_file($CPPTLISTCUSTOMDRSVNAMESSAN);
my %vars_cpp_listcustomdrsvnames = (
     TEMPLATESANNAME => "",
     sanind => "",
     drsvname => "",
     customdrsvrepnames => ""
    );

# load cpp_custom_init_SAN template file into a string
$tx->load_file($CPPTCUSTOMINITSAN);
# variables for template to get code for SAN custom initialization
my %vars_cpp_custominitsan = (
    sandarepname     => "",
    cpplistdrsvnames => ""
    );
# my $drsvrepnames="";

# make c++ code
###################################

# load into a string the template file for the c++ file darep_in.h
$tx->load_file($CPPTDAREPIN);
# variables for the c++ template CPPTDAREPIN
my %vars_cpp_darepin = (
    sannamespaces => "",
    listreplicaindexes => ""
);
my $cppsannamespaces="";

# load into a string the C++ template file CPPTDAREPINSAN
$tx->load_file($CPPTDAREPINSAN);
# variables for template
my %vars_cpp_darepin_san = (
    TEMPLATESANNAME => "",
    drsvnamespaces => "",
    NREPS => 0,
    getdrsvstatevars => "",
    defdrsvstatevars => ""
);

# load into a string the C++ template file CPPTDAREPINDRSV
$tx->load_file($CPPTDAREPINDRSV);
# variables for template
my %vars_cpp_darepin_drsv = (
    drsvname => "",
    drsvnamespace => "",
    TEMPLATESANNAME => "",
    maxdeps => 0,
    drsvtype => ""
);
# maximum number of replicas of the dependency-related state variable (DRSV) S occurring in each SAN replica, each replica of the DRSV S is shared with the corresponding SAN replica
my $maxdeps=0;

# load into a string the C++ template file CPPTDAREPINDUMMYDRSV
$tx->load_file($CPPTDAREPINDUMMYDRSV);
# variables for template
my %vars_cpp_darepin_dummydrsv = (
    drsvname => "",
    drsvtype => ""
);

# load into a string the C++ template file CPPTDAREPINGETDRSTATEVAR
$tx->load_file($CPPTDAREPINGETDRSTATEVAR);
# variables for template
my %vars_cpp_darepin_getdrstatevar = (
    drsvname => "",
    drsvnamespace => "",
    drsvtype => ""
);

# load into a string the C++ template file CPPTDAREPINDEFDRSTATEVAR
$tx->load_file($CPPTDAREPINDEFDRSTATEVAR);
# variables for template: %vars_cpp_darepin_getdrstatevar

# load into a string the template file for the c++ file darep_def_in.h
$tx->load_file($CPPTDAREPDEFIN);
# variables for the c++ template CPPTDAREPDEFIN
my %vars_cpp_darepdefin = (
    sandefnamespaces => ""
);
my $cppsandefnamespaces="";

# load into a string the C++ template file CPPTDAREPDEFINSAN
$tx->load_file($CPPTDAREPDEFINSAN);
# variables for template
my %vars_cpp_darepdefin_san = (
    TEMPLATESANNAME => "",
    dummydrsvs => ""
);


# load cpp_replicaindexes template file into a string
$tx->load_file($CPPPARAMSREPINDT);
# variables for the c++ template
my %vars_cpp_replica_ind = (
    tsanname => "",
    drsvdarepname => "",
    drsvname => "",
    listabsrepind => ""
    );

# make the composed cmp file
#############################

# load composed cmp template file into a string
$tx->load_file($COMPOSEDCMPT);
# variables for cmpt template
my $COMPOSEDMODELNAME="";
my $DAREPNODENAME="";
my $sharinginfosize="";
my $newsharedobjs="";
my $composedatomicobjects="";
my $composedatomicedges="";


# load shared object template file
$tx->load_file($SHAREDOBJECTT);
# variables for sharedobject template
my %vars_sharedobject = (
    drsvnewsharedobjname => "",
    fapstrings => "" 
    );
my $drsvnewsharedobjname="";
#my $fapstrings="";

# load composed atomic template file into a string
$tx->load_file($COMPOSEDATOMICT);
# load join-san edge template file into a string
$tx->load_file($COMPOSEDATOMICEDGET);
# variable to evaluate in composedatomicobjects and edge templates
my %vars_composedatomicobjectedge = (
    DAREPNODENAME => "",
    sandarepname => "",
    xpos => 0
    );
my $sandarepname=""; # name of SAN instance
my $xpos=0;

# load composed template file for prj
$tx->load_file($COMPOSEDPRJT);

# load prj file
my $xmlprj = 'XML::LibXML'->load_xml( location => $PRJFILE,
                                    no_blanks => 1 ) # whitespace-only text nodes are removed
    or die "Can't open file: $PRJFILE\n";

# load darep input file
my $xmldarepin = 'XML::LibXML::Reader'->new( location => $XMLDAREPEPINPUT )
    or die "Can't open file: $XMLDAREPEPINPUT\n";

# chek darep input
# my $xmldarep="";
if( $xmldarepin->nextElement('darepinput') ) { 
    # $xmldarep = $xmldarepinput->copyCurrentNode(1);
} else {
    say STDERR "Node not found: darepinput\n";
    exit 1;
}


# get composed model name
if( $xmldarepin->nextElement('darepcomposedname') ) { 
    $COMPOSEDMODELNAME = trim($xmldarepin->copyCurrentNode(1)->to_literal);
} else {
    say STDERR "Node not found: darepcomposedname\n";
    exit 1;
}

# composed model dir
my $COMPOSEDMODEL="${COMPOSED}/${COMPOSEDMODELNAME}";
# composed model cmp file
my $COMPOSEDMODELCMP="${COMPOSED}/${COMPOSEDMODELNAME}/${COMPOSEDMODELNAME}.${COMPOSEDMODELEXT}";
# c++ composed model files
my $COMPOSEDMODELCPP="${COMPOSED}/${COMPOSEDMODELNAME}/${COMPOSEDMODELNAME}RJ.cpp";
my $COMPOSEDMODELH="${COMPOSED}/${COMPOSEDMODELNAME}/${COMPOSEDMODELNAME}RJ.h";

# get composed model node name
if( $xmldarepin->nextElement('darepnodename') ) { 
    $DAREPNODENAME = trim($xmldarepin->copyCurrentNode(1)->to_literal);
} else {
    say STDERR "Node not found: darepnodename\n";
    exit 1;
}

# set vars for the template
$vars_composedatomicobjectedge{'DAREPNODENAME'}=$DAREPNODENAME;

# the number of shared objects
$sharinginfosize=0;

# to make composed cmp file
# the list of new shared objects
#############################
# FullAccessPathStrings of each NewSharedObjName (drsv)
my @fapstrings_of_newsharedobjs;
# indexes of each FullAccessPathString of each NewSharedObjName (drsv)
my @fapstringind_of_newsharedobjs;
# the global index of the DRSV, considering all the DRSV used in all SAN (excluding duplicated)
my $gdrsvind=0;

# the list of template names used in darep
my @templatesannames=();
# to check whether template name is unique
my %templatesanseen;
# the index of the current template name
my $templatesannameind=0;
# list of number of replicas of each template SAN
my @templatesannreps=();

# to avoid reinitialization of fapstringind_of_newsharedobjs when repeated name of drsv occur in different template san
my %gdrsvinit;
# the global index of each DRSV name
my %gdrsvindname;
# array including all drsv names (excluding repetitions)
my @gdrsvnames=();
# the list of number of replicas for each drsv
my @gdrsvmrep=();

# the initialization of the arrays for global indexes ID: one array for each different topology
my $listreplicaindexes="";

# the list of templates
# get composed model node name
if( $xmldarepin->nextElement('SANDAREPS') ) { 
} else {
    say STDERR "Node not found: darepnodename\n";
    exit 1;
}

# get the name of the template SAN from input xml file
# using perl XML::LibXML::Reader
my $sandarep="";
# check the node SANDAREP
if( $xmldarepin->nextElement('SANDAREP') ) { 
} else {
    say STDERR "Node not found: SANDAREP\n";
    exit 1;
}
do {                          # for each SANDAREP
    my $cppdrsvnamespaces = "";
    my $dummydrsvs = "";
    my $cppgetdrsvstatevars = "";
    my $cppdefdrsvstatevars = "";

    # get the node SANDAREP
    $sandarep = $xmldarepin->copyCurrentNode(1);

    # SAN template name
    my $TEMPLATESANNAME = trim($sandarep->findvalue('name'));
    # check unique template san name
    if( ! $templatesanseen{$TEMPLATESANNAME} ) {
        $templatesanseen{$TEMPLATESANNAME}=1;
    } else {
        say STDERR "Ops! Repeated template SAN name: $TEMPLATESANNAME\n";
        exit 1;
    }
    # debug info
    # say STDERR "TEMPLATESANNAME: $TEMPLATESANNAME";
        
    # check empty SAN template name
    if ( $TEMPLATESANNAME eq "" ) {
        say STDERR "Ops! SAN template not defined in input file!";
        help();
        exit 1
    }

    # add item to list of names of template SAN
    push @templatesannames, $TEMPLATESANNAME;

    # template SAN dir
    my $TEMPLATESANDIR="${ATOMIC}/${TEMPLATESANNAME}";

    # template SAN name with darep ext
    my $TEMPLATESANNAMEEXT="${TEMPLATESANNAME}${SANDAREPEXT}";
    # template SAN dir with ext
    my $TEMPLATESANDIREXT="${ATOMIC}/${TEMPLATESANNAMEEXT}";

    # xml template SAN file, relative path
    my $XMLTEMPLATESAN="${RATOMIC}/${TEMPLATESANNAME}/${TEMPLATESANNAME}.san";

    # base name for the file .h included in customize SAN
    my $CUSTOMIZESANHBASE="customize_${TEMPLATESANNAME}${SANDAREPEXT}";

    # get the number of SAN template replicas
    my $NREPS = trim($sandarep->findvalue('replicasNumber'));
    # maximum index of replicas, the index starts from 0: nreps-1
    my $NREPSM1=$NREPS-1;
    # debug info
    #say STDERR "$NREPSM1";
    
    # add item to list of number of replicas associated to each template SAN
    push @templatesannreps, $NREPS;

    # the XML declaration of template SAN: a processing instruction at first row that identifies the document as being XML (first row of the SAN file).
    (my $XMLSANDECLARATION)=path($XMLTEMPLATESAN)->lines( { count => 1 } );

    # create destination SAN folders, for each SAN
    # the index of SAN replicas starts from 0
    makedirs(${NREPSM1},"${TEMPLATESANDIREXT}");

    # debug info
    #say STDERR $PRJFILE;

    # remove destination SAN folders for i>=$NREPS
    #
    my $match=qr/^${TEMPLATESANNAMEEXT}([0-9]+)$/;
    my @TOREMSANFOLDES = File::Find::Rule->directory()->exec( sub{ if($_=~/$match/){return ($1>=$NREPS)}} )->in( ${ATOMIC} );
    if ( @TOREMSANFOLDES ) {    # SAN directories to remove
        say "Directories for exceeding DAREP SAN:";
        say foreach @TOREMSANFOLDES;
        say "Above listed directories will be removed.";
        my $response="n";
        if ( $fflag ) {
            say "Are you sure? [y/N]y";
            $response = "y";
        } else {
            $response = prompt "Are you sure? [y/N]", -stdio;
        }
        if ( $response =~ /n/i or $response eq '' ) {
            # Otherwise continue without remove them
            say "Above listed files have not been removed.";
        } else {
            #if yes, then remove files
            # remove SAN directories
            remove_tree(@TOREMSANFOLDES, {safe => true} );
            say "Removed all above listed files.";

            # remove exceeding SAN replicas (i>=nreps) from prj file
            # using XQILLA:
            #system("echo \"$cmd\" | /bin/bash -s`");
            # using perl XML::LibXML
            removesanexceedprj(\$xmlprj, $TEMPLATESANNAMEEXT, $NREPS, $TEMPLATESANNAME);
        }
    } else { # no exceeding SAN directory found, then remove the exceeding SAN from prj file
        # remove exceeding SAN replicas (i>=nreps) from prj file
        # using XQILLA:
        #system("echo \"$cmd\" | /bin/bash -s`");
        # using perl XML::LibXML
        removesanexceedprj(\$xmlprj, $TEMPLATESANNAMEEXT, $NREPS, $TEMPLATESANNAME);
    }


    # remove code breaks from template SAN model
    edit_file_lines \&removecodebreaks, ${XMLTEMPLATESAN};

    # make:
    #    - the instances of SAN template (the index of SAN replicas starts from 0)
    #    - the C++ code
    #    - the composed cmp file
    #############################

    # load template san file, used to generate SAN replicas
    my $tsandoc = 'XML::LibXML'->load_xml( location => $XMLTEMPLATESAN )
        or die "Can't open file: $XMLTEMPLATESAN\n";

    # the drsv based on the same topology
    # my $drsvnode;
    if ( $xmldarepin->nextElement('topology') ) {
        # $drsvnode = $xmldarepin->copyCurrentNode(1);
    } else {
        say STDERR "Node not found: topology\n";
        exit 1;
    }

    # c++ code the customize SAN file
    # one entry for each replica of the template SAN
    # each entry includes the code for all drsv
    my @cppcodeh=();

    # code listing DRSV names of all DRSV associated to each replica, one replica for each entry of the array
    my @cpplistdrsvnames=();

    #my $hh=0; # dbg
    #my $drsvname=""; # dbg
    #my $drsvtype=""; # dbg
    my @drsvnames=();        # array including all drsv names in current template san
    my @drsvtypes=();        # array including all drsv types in current template san
    my %drsvseen;            # to avoid repetition of DRSV names in a template san
    # for each topology
    my @tsan=();             # to copy loaded file doc of each replica
    my @csan=();             # for root class of each replica
    do {                        # for each topology
        #    my $h=0; # dbg
        # the number of replicas of the DRSV associated to the topology
        my $MDRSVREPS=0;
        if ( $xmldarepin->nextElement('replicasNumber') ) {
            $MDRSVREPS = trim($xmldarepin->copyCurrentNode(1)->to_literal);
        } else {
            say STDERR "Node not found: replicasNumber.\n";
            exit 1;
        }
        # debug info
        # say STDERR "MDRSVREPS: $MDRSVREPS";

        # the dependency related state variable drsvs related to the topology
        # list of drsv
        my $drsvs="";
        if ( $xmldarepin->nextElement('drsvs') ) {
            $drsvs = $xmldarepin->copyCurrentNode(1);
        } else {
            say STDERR "Node not found: drsvs.\n";
            exit 1;
        }

        my $drsvtopmin=$#drsvnames+1; # minimum index for drsv in the current topology
        # make list of drsv info
        foreach my $drsvinfo ($drsvs->findnodes('./drsv')) { # for each drsv in the current topology
            my $drsvname="";
            # add item to list of names of drsv
            if ( $drsvinfo->findnodes('name')->size()>0 ) {
                $drsvname=$drsvinfo->findvalue('name');
                # check unique drsv name in a template san
                if (! $drsvseen{$drsvname}) {
                    push @drsvnames, $drsvname;
                    $drsvseen{$drsvname}=1; # add new item
                } else {
                    say STDERR "Ops! Repeated DRSV name in template SAN $TEMPLATESANNAME: $drsvname\n";
                    exit 1;
                }
                # say STDERR "name: " . $drsvnames[$#drsvnames];
            } else {
                say STDERR "Node not found: name\n";
                exit 1;
            }
        
            # add item to list of types of drsv
            if ( $drsvinfo->findnodes('type')->size()>0 ) {
                push @drsvtypes, XML::Entities::decode('all',trim($drsvinfo->findvalue('type'))); # decode special chars
                # say STDERR "type: " . $drsvtypes[$#drsvtypes];
            } else {
                say STDERR "Node not found: type\n";
                exit 1;
            }

            # check if variables for newsharedobjs are already initialized
            if (! $gdrsvinit{$drsvname}) { # first time drsv found
                # say STDERR "drsvname: $drsvname";
                # say STDERR "gdrsvind: $gdrsvind";
                # say STDERR "MDRSVREPS: $MDRSVREPS";

                # to make composed cmp file
                # the list of new shared objects
                #############################
                # reset lists
                # FullAccessPathStrings of each NewSharedObjName (drsv)
                @{$fapstrings_of_newsharedobjs[$gdrsvind]}= ("") x $MDRSVREPS; # $MDRSVREPS cols, current row
                # indexes of each FullAccessPathString of each NewSharedObjName (drsv)
                @{$fapstringind_of_newsharedobjs[$gdrsvind]} = (0) x $MDRSVREPS; # $MDRSVREPS cols, current row
                # say STDERR "********* MDRSVREPS: $MDRSVREPS, fapstrings_of_newsharedobjs[$gdrsvind][2]= $fapstrings_of_newsharedobjs[$gdrsvind][2]";
                # say STDERR "********* MDRSVREPS: $MDRSVREPS, fapstringind_of_newsharedobjs[$gdrsvind][2]= $fapstringind_of_newsharedobjs[$gdrsvind][2]";

                $gdrsvinit{$drsvname}=1; # set global index of drsv name
                $gdrsvindname{$drsvname}=$gdrsvind; # global index of drsv name
                # update the global index of the DRSV
                $gdrsvind++;
                
                # add item to global list of names of drsv
                push @gdrsvnames, $drsvname;
                # add item to global list of number of replicas of drsv
                push @gdrsvmrep, $MDRSVREPS;
                # update the number of shared DRSV replicas
                $sharinginfosize+=$MDRSVREPS;
            }

        }                      # for each drsv in the current topology
        my $drsvtopmax=$#drsvnames; # maximum index for drsv in the current topology
        # say "*** drsv range for current topology: $drsvtopmin, $drsvtopmax";
    
        # the deps elements of the node: topology
        # my $drsvdeps;
        # name of DRSV instance;
        my $drsvrepname="";
        if ( ! $xmldarepin->nextSiblingElement('deps') ) { # at least one node deps
            say STDERR "Ops! Node <deps>...</deps> not found at ??? in:\n<SANDAREP>\n<name>$TEMPLATESANNAME</name>\n<topology>\n$drsvs\n ???\n</topology>\n</SANDAREP>\n";
            exit 1;
        }
        # list of list of global deps indexes: one list of deps for each replica: {{depslist},...,{depslist}}
        my $drsvrepindscsv="";
        do {           # for each SAN replica: i^th replica of the SAN
            #   1. make xml code
            #   2. update c++ code

            # make xml code:
            #  get a copy of the template SAN file
            #  for the dependency-shared Place:
            #    - get the place used as template to generate the Placej to be added
            #    - get the parent of the element class place Placej, i.e, the node class where the Placej is to be added
            #    - get the edge used as template to generate the Placej-related edges to be added
            #    - get the parent of the element class edge, i.e, the node class where the Placej-related edge is to be added
            ##############################################

            # get info from xml input darep file
            my $drsvdeps = $xmldarepin->copyCurrentNode(1); # node deps
            # deps/ind: SAN replica index i
            my $sanind=trim($drsvdeps->findvalue('./ind'));
            # the name of the SAN instance
            $sandarepname = $TEMPLATESANNAME . $SANDAREPEXT . $sanind; 
            # debug info
            # say STDERR "deps/ind: " . $sanind;
            # say STDERR "name of SAN instance: " . $sandarepname;

            # get a copy of the doc used as template SAN for i^th replica
            if ( ! defined $tsan[$sanind] ) {
                $tsan[$sanind] = $tsandoc->cloneNode(1); # copy loaded file doc
                $csan[$sanind] = $tsan[$sanind]->findnodes('/class[@id="Mobius.AtomicModels.San.SanInterface"]')->[0]; # root class

                # rename SAN template to SAN<ext><i>
                my $modelname = $csan[$sanind]->findnodes('//string[@id="ModelName"]')->[0]; # the node to update
                $modelname->removeChildNodes(); # remove the value
                $modelname->appendText($sandarepname); # assign new value
                # debug info
                #say STDERR "new modelname for replica $sanind: " . $modelname ;
                #say STDERR $tsan[$sanind]->toString;

                # update the index
                # replace Index() with i on the i^th replica of the SAN template
                my $match = "${SANDAREPEXT}::${TEMPLATESANNAME}::Index()"; # for contains()
                foreach ( $csan[$sanind]->findnodes(qq(//string[contains(text(),"$match")])) ) { # for each string node containing the Index()
                    my $match = "${SANDAREPEXT}::${TEMPLATESANNAME}::Index" . '\(\)'; # for s///g
                    ( my $newvalue = $_->textContent ) =~ s/$match/$sanind/g;
                    $_->removeChildNodes();    # remove the value
                    $_->appendText($newvalue); # assign new value
                }
            }

            # for each SAN replica
            my $drsvrepindscsvi="{";

            # for each drsv
            my $drsvrepnames="";
            my @drsvrepinds=(); # the absolute indexes of deps
            # debug info
            # say STDERR "drsvtopmin: $drsvtopmin";
            # say STDERR "drsvtopmax: $drsvtopmax";
            for my $drsvind ($drsvtopmin .. $drsvtopmax) { # for each drsv in the current topology
                # name of drsv
                my $drsvname = $drsvnames[$drsvind];
                # global index of drsv name
                my $gdrsvind=$gdrsvindname{$drsvname};
                
                # type of drsv
                # my $drsvtype = $drsvtypes[$drsvind];

                # check if node for the dependency-shared Place exists on the template SAN
                # it is one of the nodes:
                #    Mobius.AtomicModels.San.PlacePanelObject (for plain places), or 
                #    Mobius.AtomicModels.San.ExtendedPlacePanelObject is the parent Mobius.AtomicModels.San.PlacePanelObject (for extended places),
                if ( ! defined $csan[$sanind]->findnodes(qq(//class[\@id="Mobius.AtomicModels.San.PlacePanelObject" and class/class/string[\@id="Name" and text()="$drsvname"]]))->[0] ) {
                    say STDERR "Ops! Node for DRSV not found on the template SAN.\nDRSV: ${drsvname}\nTemplate SAN: ${TEMPLATESANNAME}";
                    exit 1
                }

                # make c++ code for SAN replicas
                ###################################

                # variables for the c++ templates ($CPPTLISTDRSVNAMESSAN, $CPPTCUSTOMIZESANH) including code with the list of names
                $vars_cpp_listdrsvnames{'TEMPLATESANNAME'} = $TEMPLATESANNAME;
                $vars_cpp_listdrsvnames{'drsvname'}        = $drsvname;

                # variables for the c++ template $CPPTLISTCUSTOMDRSVNAMESSAN including code with the custom list of names
                $vars_cpp_listcustomdrsvnames{'TEMPLATESANNAME'} = $TEMPLATESANNAME;
                $vars_cpp_listcustomdrsvnames{'drsvname'}        = $drsvname;

        
                # make c++ code
                ###################################
        
                # make the composed cmp file
                #############################
        
                my $maxdepsi=0; # reset number of shared DRSV replicas for replica i
        
                # the node for the DRSV place
                #
                # this node is the template used to generate the Placej to be added, 
                # it is one of the nodes:
                #    Mobius.AtomicModels.San.PlacePanelObject (for plain places), or 
                #    Mobius.AtomicModels.San.ExtendedPlacePanelObject is the parent Mobius.AtomicModels.San.PlacePanelObject (for extended places),
                # it is removed from the resulting SAN replicas, where it is replaced by the new generated Placej
                my $place = $csan[$sanind]->findnodes(qq(//class[\@id="Mobius.AtomicModels.San.PlacePanelObject" and class/class/string[\@id="Name" and text()="$drsvname"]]))->[0];
                if ( ! defined $place ) {
                    say STDERR "Ops! Node for DRSV not found on the template SAN.\nDRSV: ${drsvname}\nTemplate SAN: ${TEMPLATESANNAME}";
                    exit 1
                }
                # check if the place is an extended place
                if ( $place->findnodes('../../class[@id="Mobius.AtomicModels.San.ExtendedPlacePanelObject"]')->size()>0 ) {
                    $place = $place->parentNode; # extended place
                }                                # else plain place
                # debug info
                # say STDERR "$place";
        
                # the node Mobius.BaseClasses.BasePanelClass that is parent of the element class place: it represents the node where the Placej is to be added
                my $sanbpc = $place->parentNode;
                # debug info
                # say STDERR "$sanbpc";

                # x position of node place
                #my $placeypos=$place->findvalue('.//point[@id="CenterPoint"]/int[@id="y"]'); # a value
    
                # remove the node place used as template
                $place->unbindNode;
    
                # the nodes edge used as template: edge starting or ending with dependency-shared Place
                # each template node is used to generate the Placej-related edge to be added,
                # each template node is removed from the resulting SAN replicas
                my @dsplaceedges = $csan[$sanind]->findnodes(qq(//class[\@id="Mobius.BaseClasses.BaseEdgeClass" and (./string[\@id="StartVertex"]/text()="$drsvname" or ./string[\@id="FinishVertex"]/text()="$drsvname")]));

                # the node Mobius.BaseClasses.BasePanelClass that is parent of the element class edge: it represents the node where the Placej-related edge is to be added
                my $sanbpcedgeparent="";
                if ( @dsplaceedges > 0 ) {
                    $sanbpcedgeparent = $dsplaceedges[0]->parentNode; # the parent of an edge node
                }
                #        ++$h; # dbg
                #        say STDERR "***************** $h: $sanind: $drsvname"; # dbg
            
                # remove the nodes edge used as template
                foreach ( @dsplaceedges ) {
                    $_->unbindNode;
                }

                # deps/dep
                my $drsvdep;
                # deps/dep/ind: DRSV replica index
                my $drsvrepind="";
                my @depsinds=$drsvdeps->findnodes('./dep/ind');
                if ( $drsvind == $drsvtopmin ) { # the first variable of the topology
                    foreach (@depsinds) { # for each DRSV replica j in deps
                        $drsvrepind = trim($_->to_literal); # the global index j of the DRSV replica
                        $drsvrepindscsvi .= ($drsvrepindscsvi eq "{") ? $drsvrepind : "," . $drsvrepind;
                    }
        
                    # closing curly bracket for deps
                    $drsvrepindscsvi.="}";
        
                    # update the list adding the deps of the replica
                    $drsvrepindscsv.=($drsvrepindscsv eq "") ? $drsvrepindscsvi : "," . $drsvrepindscsvi;
                }               # the first variable of the topology

                $drsvrepind="";
                foreach (@depsinds) { # for each DRSV replica j in deps
                    $maxdepsi++; # update number of shared DRSV replicas in replica i
                    $drsvrepind = trim($_->to_literal); # the global index j of the DRSV replica
                    # the name of the DRSV (place) instance
                    $drsvrepname = $drsvname . $DRSVDAREPEXT . $drsvrepind;
                    # debug info
                    #say STDERR "drsvname: $drsvrepname";
        
                    # make xml code for i^th replica
                    ###################################
        
                    # make all the dependency-shared Places Place<ext><j> associated to replica i,
                    # based on each basic dependency-shared Place, that will be removed
                    #
                    # make Places Place<ext><j>: based on the list Deps()
                    #
                    # the node Mobius.AtomicModels.San.PlacePanelObject, that is parent of placename, represents the Placej to be added and renamed
            
                    # the new node: it is a clone of the basic node
                    my $tplace = $place->cloneNode(1); # a copy of the template node
                    # update the name of the DRSV (place) instance
                    my $tplacename = $tplace->findnodes('./class/class//string[@id="Name"]')->[0];
                    $tplacename->removeChildNodes(); # remove the value
                    $tplacename->appendText($drsvrepname); # assign new value
                    #
                    # update the position x of the DRSV (place) instance
                    #$placeypos+=15;
                    #my $tplaceypos = $tplace->findnodes('.//point[@id="CenterPoint"]/int[@id="y"]')->[0]; # a node
                    #$tplaceypos->removeChildNodes(); # remove the value
                    #$tplaceypos->appendText($placeypos); # assign new value
                    #
                    # add the new node instance
                    #$sanbpc->addChild($tplace); # add new node instance
                    #$sanbpc->insertAfter($tplace, $place); # add new node instance after $place
                    $sanbpc->appendChild($tplace); # add new node instance
            
                    # make and add all the edges involving the dependency-shared Places Place<ext><j> associated to replica i,
                    # based on the basic edge, that will be removed
                    #
                    foreach ( @dsplaceedges ) { # for each DRSV-related edge
                        # the new edge: it is a clone of the basic node
                        my $tedge = $_->cloneNode(1);
                        # rename the new edge nodes
                        foreach ( $tedge->findnodes(qq(./string[(\@id="StartVertex" or \@id="FinishVertex") and text()="$drsvname"])) ) {
                            $_->removeChildNodes(); # remove the value
                            $_->appendText($drsvrepname); # assign new value
                        }
                        # add the new edge node instance
                        $sanbpcedgeparent->appendChild($tedge); # insert new node instance
                    }

                    # make c++ code for i^th replica
                    ###################################
        
                    # generate the list of names of DRSV for replica i
                    $drsvrepnames .=  ", " . $drsvrepname;
                    push @drsvrepinds, $drsvrepind;
            
                    # to make composed cmp file
                    # make the list of the shared dependency related state variables, including for each place the list of atomic models sharing the place, i.e., 
                    # the list of new shared objects
                    #
                    # new item of FullAccessPathStrings: SANi -> DRSVj
                    #            say "******** fapstrings_of_newsharedobjs[$gdrsvind][$drsvrepind]: $fapstrings_of_newsharedobjs[$gdrsvind][$drsvrepind]"; # dbg
                    $fapstrings_of_newsharedobjs[$gdrsvind][$drsvrepind] .= "\n" . '<string id="' . $fapstringind_of_newsharedobjs[$gdrsvind][$drsvrepind] . '">' . $sandarepname . '-&gt;' . $drsvrepname . '</string>';
                    # current number of items and index for new item
                    $fapstringind_of_newsharedobjs[$gdrsvind][$drsvrepind]++; 
                    # say STDERR "deps/dep/ind: " . $drsvrepind;
                    # say STDERR "name of DRSV instance: " . $drsvname;
                    # say STDERR "deps/dep: " . $xmldarepin->nodePath();
                    # say STDERR "fapstrings_of_newsharedobjs[$gdrsvind][$drsvrepind] (${drsvname}): \n" . $fapstrings_of_newsharedobjs[$gdrsvind][$drsvrepind];

                }               # for each DRSV replica j in deps

                if ( $maxdeps<$maxdepsi ) { 
                    $maxdeps=$maxdepsi; # update the maximum number of shared DRSV replicas
                }
        
                #debug info
                #say STDERR $tsan[$sanind]->toString;

                # made xml code for i^th replica
                ###################################

                # update the c++ code on the i^th replica of the SAN template
                #############################################################

                # evaluate the template to get code listing DRSV names
                $drsvrepnames =~ s/^, //;
                $vars_cpp_listdrsvnames{'sanind'}=$sanind;
                $vars_cpp_listdrsvnames{'drsvrepnames'}=$drsvrepnames;
                my $cpplistdrsvnamesi = $tx->render($CPPTLISTDRSVNAMESSAN, \%vars_cpp_listdrsvnames);
                $cpplistdrsvnames[$sanind] .= $cpplistdrsvnamesi;
                # reset for next replica
                $drsvrepnames = "";

                # update the deps:
                #   - replace SANDAREP::SANNAME::myDRSV->Deps(j) with SANDAREP::SANNAME::rep(i).myDRSV()->Deps(j) on the i^th replica of the SAN template
                #   - include in each string, where there is a call to deps(), a dummy function having for arguments the list of names of dependency related places, i.e.,
                #     include a function with arguments the list of names of dependency related places into the c++ code of each primitive where the commands SANDAREP::SANNAME::myDRSV->Deps(j) or SANDAREP::SANNAME::myDRSV->Deps() are used, on the i^th replica of the SAN template
                $match = "${SANDAREPEXT}::${TEMPLATESANNAME}::${drsvname}->Deps("; # for contains()
                foreach my $indstring ( $csan[$sanind]->findnodes(qq(//string[contains(text(),"$match")])) ) { # for each string node containing the Index()
                    # replace reference to deps()
                    my $newvalue = $indstring->textContent;
                    my $match = "${SANDAREPEXT}::${TEMPLATESANNAME}::${drsvname}-" . '>Deps\(([^\)]*)\)'; # for s///g
                    my $matchnotnumber = "${SANDAREPEXT}::${TEMPLATESANNAME}::${drsvname}-" . '>Deps\(\s*([^0-9]+|)\s*\)'; # to match DRSV at position given by no number: e.g., Deps() or Deps(h)
                    if ( $indstring->textContent =~ m/$matchnotnumber/ ) { # found reference to DRSV at position given by an item different from a number, like Deps() or Deps(not_a_number), then a complete list with DRSV names has to be included
                        # replace method
                        $newvalue =~ s/$match/${SANDAREPEXT}::${TEMPLATESANNAME}::rep($sanind)\.${drsvname}\(\)->Deps\($1\)/g;
                        # include dummy function with DRSV names as arguments
                        if ( $newvalue =~ /;/ ) { # statements
                            $newvalue = $cpplistdrsvnamesi . '\n\n' . $newvalue;
                        } else { # expression
                            $newvalue = $cpplistdrsvnamesi . '\n\n return ' . $newvalue . ';';
                        }
                    } else { # found reference to DRSV at position given by a number
                        my $matchnumber = "${SANDAREPEXT}::${TEMPLATESANNAME}::${drsvname}-" . '>Deps\(\s*([0-9]+)\s*\)'; # to match DRSV at position given by a number: e.g., 0 or 3
                        # get numbers used like arguments in Deps()
                        my @matches = $indstring->textContent =~ m/$matchnumber/g;
                        # get the list of DRSV names corresponding to the numbers used in Deps()
                        my $customdrsvrepnames = "";
                        my @seen=();
                        foreach my $customdrsvreppos (@matches) { # for each pos
                            if ( ! defined $seen[$customdrsvreppos] ) { # found new pos
                                # the name of the DRSV (place) instance
                                my $customdrsvrepname = $drsvname . $DRSVDAREPEXT . $drsvrepinds[$customdrsvreppos];
                                # generate the list of names of DRSV for replica i
                                $customdrsvrepnames .=  ", " . $customdrsvrepname;

                                $seen[$customdrsvreppos]=1; 
                            }   # skip duplicated pos
                        }       # for each drsv pos
            
                        # evaluate the template to get code custom listing DRSV names
                        $customdrsvrepnames =~ s/^, //;
                        $vars_cpp_listcustomdrsvnames{'sanind'}=$sanind;
                        $vars_cpp_listcustomdrsvnames{'customdrsvrepnames'}=$customdrsvrepnames;
                        my $cpplistcustomdrsvnamesi = $tx->render($CPPTLISTCUSTOMDRSVNAMESSAN, \%vars_cpp_listcustomdrsvnames);

                        # replace method
                        $newvalue =~ s/$match/${SANDAREPEXT}::${TEMPLATESANNAME}::rep($sanind)\.${drsvname}\(\)->Deps\($1\)/g;
                        # include dummy function with DRSV names as arguments
                        if ( $newvalue =~ /;/ ) { # statements
                            $newvalue = $cpplistcustomdrsvnamesi . '\n\n' . $newvalue;
                        } else { # expression
                            $newvalue = $cpplistcustomdrsvnamesi . '\n\n return ' . $newvalue . ';';
                        }
                    }
                    $indstring->removeChildNodes(); # remove the value
                    $indstring->appendText($newvalue); # assign new value
                }               # for each string including Deps

                # make C++ code
                ###################################
        
                # generate the customize SAN file, one for each replica of the template SAN
                $cppcodeh[$sanind] .= $tx->render($CPPTCUSTOMIZESANH, \%vars_cpp_listdrsvnames); # evaluate the template to get the code to be included into the file .h for the current drsv

            }                  # for each drsv in the current topology

        } while ( $xmldarepin->nextSiblingElement('deps') ); # for each SAN replica: i^th replica of the SAN

        # name of the first DRSV related to the topology
        my $firstdrsvname="";
        # drsv name extended with darep ext
        my $drsvdarepname = "";
        if ( $drsvtopmax-$drsvtopmin>=0 ) {
            $firstdrsvname = $drsvnames[$drsvtopmin];
            $drsvdarepname = $firstdrsvname . $DAREPACRO; # set drsv name extended with darep ext
        } else {
            say STDERR "Ops! DRSV not found.\n";
            exit 1;
        }
        
        # evaluate the template to get code listing DRSV indexes for the current topology
        $vars_cpp_replica_ind{'tsanname'}=$TEMPLATESANNAME;
        $vars_cpp_replica_ind{'drsvdarepname'}=$drsvdarepname;
        $vars_cpp_replica_ind{'drsvname'}=$firstdrsvname;
        $vars_cpp_replica_ind{'listabsrepind'}=$drsvrepindscsv;
        $listreplicaindexes .= "\n" . $tx->render($CPPPARAMSREPINDT, \%vars_cpp_replica_ind);
    
    } while ( $xmldarepin->nextSiblingElement('topology') ); # for each topology

    # debug info
    # say STDERR '$#tsan: ' . $#tsan;
        
    foreach my $sanind ( 0..$#tsan ) { # for each template SAN replica i
        my $SANREPBASENAME="${TEMPLATESANNAMEEXT}${sanind}";
        # evaluate the template to get code for SAN custom initialization
        $vars_cpp_custominitsan{'sandarepname'}=$SANREPBASENAME;
        $vars_cpp_custominitsan{'cpplistdrsvnames'}=$cpplistdrsvnames[$sanind];
        my $cppcustominitsan = $tx->render($CPPTCUSTOMINITSAN, \%vars_cpp_custominitsan);
        # update the custom initialization
        my $custominit = $csan[$sanind]->findnodes('//string[@id="CustomInitialization"]')->[0]; # the node to update
        my $oldvalue=$custominit->textContent;
        $custominit->removeChildNodes(); # remove the value
        $custominit->appendText($cppcustominitsan . "\n" . $oldvalue); # assign new value
        # debug info
        # say STDERR "$SANREPBASENAME: $SANREPBASENAME";
        #say STDERR $custominit->toString;
    
        # make the SAN replica file
        #
        my $SANREPI = "$TEMPLATESANDIREXT${sanind}/${SANREPBASENAME}.san";
        # If setTagCompression is defined and not '0' empty tags are displayed as open and closing tags rather than the shortcut. For example the empty tag foo will be rendered as <foo></foo> rather than <foo/>. [ http://search.cpan.org/dist/XML-LibXML/lib/XML/LibXML/Parser.pod ]
        local $XML::LibXML::setTagCompression = 1; # replace self-closing tags with empty elements
        # the XML declaration is not omitted during serialization
        local $XML::LibXML::skipXMLDeclaration = 0; 
        $tsan[$sanind]->toFile($SANREPI, 1);

        # make c++ file
        if ( ! -d $CPPAUTO ) {
            mkdir $CPPAUTO
        }
        write_file( "$CPPAUTO/${CUSTOMIZESANHBASE}${sanind}.h", \$cppcodeh[$sanind] );
    } # for each template SAN replica i

    # add replicas to prj file

    say "*** Generated instances of SAN template: ${TEMPLATESANNAME}";

    # add replicas to prj file
    addsanrepsprj(\$xmlprj, $TEMPLATESANNAME, $SANDAREPEXT, $NREPS);

    # make C++ code
    ###################################

    # remove exceeding files used in the field customize of each SAN replicas for i>=$NREPS
    $match=qr/^${CUSTOMIZESANHBASE}([0-9]+)\.h$/;
    my @TOREMCPPCUSTOMIZESAN = File::Find::Rule->file()->exec( sub{ if($_=~/$match/){return ($1>=$NREPS)}} )->in( ${CPPAUTO} );
    #say STDERR "NREPS: $NREPS";
    #say STDERR "CUSTOMIZESANHBASE: ${CUSTOMIZESANHBASE}";
    #say STDERR "TOREMCPPCUSTOMIZESAN: @TOREMCPPCUSTOMIZESAN";
    if ( @TOREMCPPCUSTOMIZESAN ) { # cpp files .h to remove
        say "Removing C++ files:";
        say foreach @TOREMCPPCUSTOMIZESAN;
        unlink @TOREMCPPCUSTOMIZESAN; # remove list of files
        say "Removed all above listed C++ exceeding files.";
    }

    # make the C++ file darep_in.h
    # the c++ code defining the objects, grouped in namespaces, required for each SAN template: a sequence of namespace declarations
    for my $drsvind (0 .. $#drsvnames) { # for each DRSV
        # name of drsv
        my $drsvname = $drsvnames[$drsvind];
        # type of drsv
        my $drsvtype = $drsvtypes[$drsvind];
                
    
        #    ++$hh; # dbg
        #    say STDERR "***************** $hh: $drsvname: $drsvtype"; # dbg

    
        # variables for C++ template file CPPTDAREPINGETDRSTATEVAR
        my $drsvnamespace="${drsvname}${DAREPACRO}";
        $vars_cpp_darepin_getdrstatevar{'drsvname'}      = $drsvname;
        $vars_cpp_darepin_getdrstatevar{'drsvnamespace'} = $drsvnamespace;
        $vars_cpp_darepin_getdrstatevar{'drsvtype'}      = $drsvtype;
    
        # make the code defining namespaces and declaration of pointers to dummy object for each DRSV
        # variables for C++ template file CPPTDAREPINDRSV
        $vars_cpp_darepin_drsv{'drsvname'}        = $drsvname;
        $vars_cpp_darepin_drsv{'drsvnamespace'}   = $drsvnamespace;
        $vars_cpp_darepin_drsv{'TEMPLATESANNAME'} = $TEMPLATESANNAME;
        $vars_cpp_darepin_drsv{'drsvtype'}        = $drsvtype;
        $vars_cpp_darepin_drsv{'maxdeps'}=${maxdeps};
        $cppdrsvnamespaces .= $tx->render($CPPTDAREPINDRSV, \%vars_cpp_darepin_drsv);

        # make the code defining pointers to dummy object for each DRSV
        # variables for C++ template file CPPTDAREPINDUMMYDRSV
        $vars_cpp_darepin_dummydrsv{'drsvname'}        = $drsvname;
        $vars_cpp_darepin_dummydrsv{'drsvtype'}        = $drsvtype;
        $dummydrsvs .= $tx->render($CPPTDAREPINDUMMYDRSV, \%vars_cpp_darepin_dummydrsv);

        # make the code defining the member functions to get the value of DRSTATEVAR, one function for each DRSV
        $cppgetdrsvstatevars .= $tx->render($CPPTDAREPINGETDRSTATEVAR, \%vars_cpp_darepin_getdrstatevar);
    
        # make the code defining the data members DRSTATEVAR, one memeber for each DRSV
        $cppdefdrsvstatevars .= $tx->render($CPPTDAREPINDEFDRSTATEVAR, \%vars_cpp_darepin_getdrstatevar);
    }

    # variables for template C++ template file CPPTDAREPDEFINSAN
    $vars_cpp_darepdefin_san{'TEMPLATESANNAME'} = $TEMPLATESANNAME;
    $vars_cpp_darepdefin_san{'dummydrsvs'} = $dummydrsvs;
        
    # make code defining namespace declaration for each SAN template
    # variables for C++ template CPPTDAREPINSAN
    $vars_cpp_darepin_san{'TEMPLATESANNAME'} = $TEMPLATESANNAME;
    $vars_cpp_darepin_san{'NREPS'}           = $NREPS;
    $vars_cpp_darepin_san{'drsvnamespaces'}=${cppdrsvnamespaces};
    $vars_cpp_darepin_san{'getdrsvstatevars'}=${cppgetdrsvstatevars};
    $vars_cpp_darepin_san{'defdrsvstatevars'}=${cppdefdrsvstatevars};
    $cppsannamespaces .= $tx->render($CPPTDAREPINSAN, \%vars_cpp_darepin_san);

    #
    # making the C++ file darep_in.h

    # make the C++ file darep_def_in.h
    # the c++ code defining the objects, grouped in namespaces, required for each SAN template: a sequence of namespace declarations

    # make code defining namespace declaration for each SAN template
    $cppsandefnamespaces .= $tx->render($CPPTDAREPDEFINSAN, \%vars_cpp_darepdefin_san);

    # output info
    say "*** Generated C++ code for SAN template: $TEMPLATESANNAME";

    # made C++ code
    ###################################

} while ( $xmldarepin->nextSiblingElement('SANDAREP') ); # for each SANDAREP


# making the C++ file darep_in.h
#

# get final code by replacing in template the list of actual spacename declarations for SAN
$vars_cpp_darepin{'sannamespaces'}=${cppsannamespaces};
$vars_cpp_darepin{'listreplicaindexes'}=${listreplicaindexes};
write_file( $CPPDAREPIN, $tx->render($CPPTDAREPIN, \%vars_cpp_darepin) );
# debug info
#say $tx->render($CPPTDAREPIN, \%vars_cpp_darepin);

#
# made the C++ file darep_in.h

# making the C++ file darep_def_in.h
#
# get final code by replacing in template the list of actual spacename declarations for SAN
$vars_cpp_darepdefin{'sandefnamespaces'}=${cppsandefnamespaces};
write_file( $CPPDAREPDEFIN, $tx->render($CPPTDAREPDEFIN, \%vars_cpp_darepdefin) );
# debug info
#say $tx->render($CPPTDAREPDEFIN, \%vars_cpp_darepdefin);

#
# made the C++ file darep_def_in.h

# to make composed cmp file
# make the list of the non dependency-related state variables shared among all template SAN, including for each place the list of atomic models sharing the place, i.e., 
# the list of new shared objects
my $sharedallsan="";
my %nondrsvseen; # to check repeated nondrsv names
my %nondrsvspecsanseen; # to check repeated nondrsv names shared with specific san
my @nondrsvnamessharedall=(); # list of names of nondrsv shared among all SAN
if( $xmldarepin->nextElement('sharedAllSAN') ) { # check tag for non DRSV shared among all template SAN
    $sharedallsan = $xmldarepin->copyCurrentNode(1);
} else {
    say STDERR "Node not found: sharedAllSAN\n";
    exit 1;
}
# sharedAllSAN/sv: non DRSV shared among all template SAN
foreach my $sv ($sharedallsan->findnodes('./sv')) {
    my $nondrsvname=trim($sv->to_literal);
    # debug info
    #say STDERR "nondrsvname: $nondrsvname";
    if( $gdrsvinit{$nondrsvname} ) { # check name
        say STDERR "Ops! Place name for nondrsv shared among all san is already used for drsv: ${nondrsvname}";
        exit 1;
    }
    if( ! $nondrsvseen{$nondrsvname}) { # check unique nondrsv name
        push @nondrsvnamessharedall, $nondrsvname;
        $nondrsvseen{$nondrsvname}=1; # add new item
    } else {
        say STDERR "Ops! Place name for nondrsv shared among all san is already used for nondrsv: ${nondrsvname}";
        exit 1;
    }
}

# log info
#foreach my $nondrsvname (@nondrsvnamessharedall) { # for each nondrsv shared among all SAN
#    say STDERR "nondrsvname: $nondrsvname";
#}


# to make composed cmp file
# make the list of the non dependency-related state variables shared among specific template SAN, including for each place the list of atomic models sharing the place, i.e., 
# the list of new shared objects
my %nondrsvsharedspecsanname; # for each san name the list of nondrsv names shared with the specific san
my $sharednondrsvsan="";
if( $xmldarepin->nextElement('sharedSAN') ) { # check tag for non DRSV shared among specific template SAN
    $sharednondrsvsan = $xmldarepin->copyCurrentNode(1); # the combination of shared nondrsv and san
} else {
    say STDERR "Node not found: sharedSAN\n";
    exit 1;
}

foreach my $sharednondrsvspecsan ($sharednondrsvsan->findnodes('./shared')) { # for each combination of nondrsv shared with specific san
    my @nondrsvnamessharedspec=(); # list of names of nondrsv shared among specific SAN
    foreach my $sharedsvspecsan ($sharednondrsvspecsan->findnodes('./sv')) { # for each sv shared with specific san
        my $nondrsvname=trim($sharedsvspecsan->to_literal);
        if( $gdrsvinit{$nondrsvname} ) { # check name
            say STDERR "Ops! Place name for nondrsv shared among specific san is already used for drsv: ${nondrsvname}.";
            exit 1;
        }
        if( ! $nondrsvseen{$nondrsvname}) { # check unique nondrsv name
            push @nondrsvnamessharedspec, $nondrsvname;
            $nondrsvseen{$nondrsvname}=1; # add new item
            $nondrsvspecsanseen{$nondrsvname}=1; # add new items
        } else {
            say STDERR "Ops! Place name for nondrsv shared among specific san is already used for nondrsv: ${nondrsvname}.";
            exit 1;
        }
    # log info
    # say STDERR "nondrsvname: $nondrsvname";
    } # for each sv shared with specific san
    foreach my $sharedsanspecsan ($sharednondrsvspecsan->findnodes('./san')) { # for each specific san shared with nondrsv
        my $nondrsvsanname=trim($sharedsanspecsan->to_literal);
        if( ! $templatesanseen{$nondrsvsanname} ) {
            say STDERR "Ops! No template SAN with this name: $nondrsvsanname\n";
            exit 1;
        }
        push @{$nondrsvsharedspecsanname{$nondrsvsanname}}, @nondrsvnamessharedspec;
        # log info
        # say STDERR "nondrsvsanname: $nondrsvsanname";
        # say STDERR "size of array nondrsvsharedspecsanname{$nondrsvsanname}: " . @{$nondrsvsharedspecsanname{$nondrsvsanname}};
    }
} # for each combination of nondrsv shared with specific san

# log info
#foreach my $nondrsvsanname (keys %nondrsvsharedspecsanname) {
#    foreach my $nondrsvname (@{$nondrsvsharedspecsanname{$nondrsvsanname}}) {
#        say STDERR "nondrsvsanname: $nondrsvsanname, nondrsvname: $nondrsvname";
#    }
#}

# make composed cmp file
###################################

# check if Composed dir exists
if ( ! -d ${COMPOSED} ) { # not found composed model directory
    say STDERR "Ops! Directory not found: ${COMPOSED}\n";
    # make the Composed directory
    mkdir(${COMPOSED}); 
}

# check if composed model already exists
if ( -d ${COMPOSEDMODEL} ) { # found composed model directory
    say "Ops! Composed model already exists:";
    say "${COMPOSEDMODEL}";
    say "Above listed existing composed model will be overwritten.";
    my $response="n";
    if ( $fflag ) {
	say "Are you sure? [y/N]y";
	$response = "y";
    } else {
        $response = prompt "Are you sure? [y/N]", -stdio;
    }
    if( $response =~ /n/i or $response eq '' ) {
        say "Already existing composed model has not been overwritten: ${COMPOSEDMODEL}";
        say "Please use a different name for new composed model.";
	exit 1;
    } else {
        #if yes, then remove files
        # remove SAN directories
        if ( -e ${COMPOSEDMODELCMP} ) {
            unlink ${COMPOSEDMODELCMP} or warn "Could not unlink ${COMPOSEDMODELCMP}: $!";
        }
        if ( -e ${COMPOSEDMODELCPP} ) {
            unlink ${COMPOSEDMODELCPP} or warn "Could not unlink ${COMPOSEDMODELCPP}: $!";
        }
        if ( -e ${COMPOSEDMODELH}) {
            unlink ${COMPOSEDMODELH} or warn "Could not unlink ${COMPOSEDMODELH}: $!" ;
        }
        say "Removed already existing composed model.";
    }
} else { # composed model directory not found
    # make the composed model directory
    mkdir($COMPOSEDMODEL); 
}

# make the list of newsharedobjects for drsv
for my $drsvind  (0 .. $#gdrsvnames) { # for each DRSV
    # name of drsv
    my $drsvname = $gdrsvnames[$drsvind];
    # type of drsv
    # my $drsvtype = $gdrsvtypes[$drsvind];
    
    # number of replicas of DRSV
    my $MREPS = $gdrsvmrep[$drsvind];

    foreach my $i (0..($MREPS-1)) { # for each DRSV replica index
        
        # string listing newsharedobjects
        #
        # if( $fapstringind_of_newsharedobjs[$drsvind][i]>0 ) 
        # $sharinginfosize++;
        $drsvnewsharedobjname = $drsvname . $DRSVDAREPEXT . $i;
        # say STDERR "fapstrings: \n" . $fapstrings;
        # set vars for the template
        $vars_sharedobject{'drsvnewsharedobjname'}=$drsvnewsharedobjname;
        $vars_sharedobject{'fapstrings'}=$fapstrings_of_newsharedobjs[$drsvind][$i];
        # evaluate the template
        $newsharedobjs .= $tx->render($SHAREDOBJECTT, \%vars_sharedobject);
        
    }  # for each DRSV replica index
} # for each DRSV

# make the list of composedatomicobjects and composedjoinsanedges
# make the list of newsharedobjects for nondrsv shared among all SAN
# make the list of newsharedobjects for nondrsv shared among specific SAN
my @fapstrings_of_nondrsvsharedall=("") x scalar(@nondrsvnamessharedall); # the list of newsharedobjects for each nondrsv shared among all SAN
my @fapstringind_of_nondrsvsharedall=(0) x scalar(@nondrsvnamessharedall); # indexes of each FullAccessPathString of each NewSharedObjName (nondrsv)
my %fapstrings_of_nondrsvsharedspec=map { $_ => "" } (keys %nondrsvspecsanseen); # the list of newsharedobjects for each nondrsv shared among specific SAN
my %fapstringind_of_nondrsvsharedspec=map { $_ => 0 } (keys %nondrsvspecsanseen); # indexes of each FullAccessPathString of each NewSharedObjName (nondrsv)
foreach my $templatesannameind (0..$#templatesannames) { # for each template SAN index
    # name of template SAN
    my $TEMPLATESANNAME = $templatesannames[$templatesannameind];

    # number of replicas of template SAN
    my $NREPS = $templatesannreps[$templatesannameind];

    foreach my $i (0..($NREPS-1)) { # for each template SAN replica index
        # string listing composedatomicobjects
        #
        # the name of the SAN instance
        $sandarepname = $TEMPLATESANNAME . $SANDAREPEXT . $i;
        #$xpos += ($i+1)*100;
        $xpos += 100;
        # set vars for the template
        $vars_composedatomicobjectedge{'sandarepname'} = $sandarepname;
        $vars_composedatomicobjectedge{'xpos'} = $xpos;
        # evaluate the template
        $composedatomicobjects .= $tx->render($COMPOSEDATOMICT, \%vars_composedatomicobjectedge);
        
        # string listing composedjoinsanedges
        #
        # the name of the SAN instance
        # $sandarepname = $TEMPLATESANNAME . $SANDAREPEXT . $i; # already defined above
        #$xpos += ($i+1)*100;
        #$xpos += 100; # already updated above
        # evaluate the template
        $composedatomicedges .= $tx->render($COMPOSEDATOMICEDGET, \%vars_composedatomicobjectedge);

        # nondrsv shared among all SAN
        my $nondrsvind=0;
        foreach my $nondrsvname (@nondrsvnamessharedall) { # for each nondrsv shared among all SAN

            $fapstrings_of_nondrsvsharedall[$nondrsvind] .= "\n" . '<string id="' . $fapstringind_of_nondrsvsharedall[$nondrsvind] . '">' . $sandarepname . '-&gt;' . $nondrsvname . '</string>';
            # say STDERR "fapstrings_of_nondrsvsharedall[$nondrsvind]: " . $fapstrings_of_nondrsvsharedall[$nondrsvind];
            # say STDERR "fapstringind_of_nondrsvsharedall[$nondrsvind]: $fapstringind_of_nondrsvsharedall[$nondrsvind]";
            $fapstringind_of_nondrsvsharedall[$nondrsvind]++;
            $nondrsvind++; # new index
        }

        # nondrsv shared among specific SAN
        foreach my $nondrsvname (@{$nondrsvsharedspecsanname{$TEMPLATESANNAME}}) { # for each nondrsv shared among the specific SAN
            # log info
            # say STDERR "nondrsvname: $nondrsvname";
            $fapstrings_of_nondrsvsharedspec{$nondrsvname} .= "\n" . '<string id="' . $fapstringind_of_nondrsvsharedspec{$nondrsvname}. '">' . $sandarepname . '-&gt;' . $nondrsvname . '</string>';
            # say STDERR "fapstrings_of_nondrsvsharedspec{$nondrsvname}: " . $fapstrings_of_nondrsvsharedspec{$nondrsvname};
            # say STDERR "fapstringind_of_nondrsvsharedspec{$nondrsvname}: $fapstringind_of_nondrsvsharedspec{$nondrsvname}";
            $fapstringind_of_nondrsvsharedspec{$nondrsvname}++;
        }
    } # for each template SAN replica index
} # for each template SAN index
# say STDERR "newsharedobjects: \n" . $newsharedobjs;


# make the list of newsharedobjects for nondrsv shared among all san
my $nondrsvind=0;
foreach my $nondrsvname (@nondrsvnamessharedall) { # for each nondrsv shared among all SAN
        # string listing newsharedobjects
        #
        # set vars for the template
        $vars_sharedobject{'drsvnewsharedobjname'}=$nondrsvname;
        $vars_sharedobject{'fapstrings'}=$fapstrings_of_nondrsvsharedall[$nondrsvind];
        # evaluate the template
        $newsharedobjs .= $tx->render($SHAREDOBJECTT, \%vars_sharedobject);
        $nondrsvind++; # new index
        $sharinginfosize++;
} # for each nondrsv shared among all SAN

# make the list of newsharedobjects for nondrsv shared among specific san
foreach my $nondrsvname (keys %fapstrings_of_nondrsvsharedspec) { # for each nondrsv shared among specific SAN
        # string listing newsharedobjects
        #
        # set vars for the template
        $vars_sharedobject{'drsvnewsharedobjname'}=$nondrsvname;
        $vars_sharedobject{'fapstrings'}=$fapstrings_of_nondrsvsharedspec{$nondrsvname};
        # evaluate the template
        $newsharedobjs .= $tx->render($SHAREDOBJECTT, \%vars_sharedobject);
        $nondrsvind++; # new index
        $sharinginfosize++;
} # for each nondrsv shared among all SAN

# generated the list of new shared objects
#############################

# say STDERR $COMPOSEDMODELNAME;
# say STDERR $DAREPNODENAME;

# variables to evaluate in cmpt template
my %vars_compcmp = ( 
    COMPOSEDMODELNAME => $COMPOSEDMODELNAME,
    DAREPNODENAME => $DAREPNODENAME,
    sharinginfosize => $sharinginfosize,
    newsharedobjs => $newsharedobjs,
    composedatomicobjects => $composedatomicobjects,
    composedatomicedges => $composedatomicedges   
    );
# evaluate template and save to file
my $cmpdoc = XML::LibXML->load_xml(string => $tx->render($COMPOSEDCMPT, \%vars_compcmp),
                                   no_blanks => 1); # remove blank nodes: option to get xml pretty format
local $XML::LibXML::setTagCompression = 1; # replace self-closing tags with empty elements
# the XML declaration is not omitted during serialization
local $XML::LibXML::skipXMLDeclaration = 0; 
# debug info
#say STDERR "COMPOSEDMODELCMP: $COMPOSEDMODELCMP";
$cmpdoc->toFile($COMPOSEDMODELCMP, 1);
#write_file( \*STDOUT, $tx->render($COMPOSEDCMPT, \%vars_compcmp) ) ;
#write_file( $COMPOSEDMODELCMP, $tx->render($COMPOSEDCMPT, \%vars_compcmp) ) ;

# output info
say "*** Generated composed model: ${COMPOSEDMODELNAME}";

# add composed model node to prj file
#
# variable to evaluate in template for composed prj
my %vars_prjcomp = ( 
    COMPOSEDMODELNAME => $COMPOSEDMODELNAME
);
# evaluate template and save to string
my $prjcompstr = $tx->render($COMPOSEDPRJT, \%vars_prjcomp);
# add composed model string to prj file
addcmpprj(\$xmlprj, \$prjcompstr, $COMPOSEDMODELNAME);

# made composed cmp file
###################################

# update prj file
local $XML::LibXML::setTagCompression = 1; # replace self-closing tags with empty elements
# the XML declaration is not omitted during serialization
local $XML::LibXML::skipXMLDeclaration = 0;
$xmlprj->toFile($PRJFILE, 1);
