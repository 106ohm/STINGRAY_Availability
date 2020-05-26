#!/bin/bash

# Script based on one-liner perl command, used to generate:
# - the <composedname>RJ_func<i>.cpp files, 
#   each file defines the function func<i>() with the 
#   code corresponding to the //Shared variable <i> 
#   copied from the input file <composedname>RJ.cpp
# - the <composedname>RJ_split.cpp file, where each code 
#   corresponding to the //Shared variable <i>
#   has been replaced with the call to function func<i>()
# - the <composedname>RJ_split.h file, where each function func<i>() 
#   is declared
# - the makefile_split file used to compile the new 
#   files <composedname>RJ_func<i>.cpp included in the library 
#   for the composed model
# - the makefile_split files, one for each simulator solver, used 
#   to generate the simulator solvers based on the splitted 
#   composed model source file
#
# where the name of the composed model <composedname> 
# is the input file.
#

function main() {
    
    # bash library, path local to script dir
    loadlib "../lib/lib.bash" 

    # darep config files
    loadconfig


    ################## main #############################

    # check command path
    checkcmdpath "${PERL}"

    # the absolute project path where is all the stuff, three directories above the script:
    # 3          2               1   0
    # ${BASEDIR}/${DAREPDIRNAME}/bin/<script>
    PROJECT=$(scriptancestorpath 3)
    # check if basedir contains darep/bin
    checkmergedpaths "${PROJECT}" "${DAREPDIRNAME}/bin"

    E_BADARGS=1
    while getopts ":s:j:h" opt; do
        case $opt in
	    h)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-h was triggered! Parameter: $OPTARG" >&2
                    hflag=1
                fi
	        ;;
	    \?)
	        echo "Ops! Invalid option: -$OPTARG" >&2
		hflag=1
		E_BADARGS=65
		;;
	    :)
	        echo "Option -$OPTARG requires an argument." >&2
		hflag=1
		E_BADARGS=65
		;;
        esac
    done

    shift $(($OPTIND - 1))

    if [ -n "$hflag" ]; then
        help
        exit $E_BADARGS
    fi

    if [ $# -gt 1 ]; then
        echo "Ops! Too many arguments!"
        help
        exit $E_BADARGS
    fi

    if [ $# -lt 1 ]; then
        echo "Ops! No input file!"
        help
        exit $E_BADARGS
    fi

    # name of the composed model
    COMPOSEDMODELNAME="$1"

    # split extesion
    SPLITEXT="_split"

    # composed model directory
    COMPOSEDMODELDIR="${PROJECT}/Composed/${COMPOSEDMODELNAME}"

    # RJ.cpp file
    RJCPP="${PROJECT}/Composed/${COMPOSEDMODELNAME}/${COMPOSEDMODELNAME}RJ.cpp"

    if [ ! -e "${RJCPP}" ]; then
        echo "Ops! No cpp file: ${RJCPP}"
        echo "First save composed model using mobius shell or GUI."
        exit $E_BADARGS
    fi

    # RJ.h file
    RJHBASE="${COMPOSEDMODELNAME}RJ"
    RJHNAME="${RJHBASE}.h"
    RJH="${COMPOSEDMODELDIR}/${RJHNAME}"

    # RJ_split.cpp file
    RJSPLITCPP="${COMPOSEDMODELDIR}/${COMPOSEDMODELNAME}RJ${SPLITEXT}.cpp"

    # RJ_split.h file
    RJSPLITHBASE="${COMPOSEDMODELNAME}RJ${SPLITEXT}"
    RJSPLITHNAME="${RJSPLITHBASE}.h"
    RJSPLITH="${COMPOSEDMODELDIR}/${RJSPLITHNAME}"

    # the output _func file start with
    read -r -d '' FUNCBEGIN <<'EOF'
#include "Composed/<: $compmodel :>/<: $compmodel :>RJ<: $splitext :>.h"

void <: $compmodel :>RJ::func<: $i :>(void) {
EOF

    # the output _func file end with
    FUNCEND="}"

    # darep makefile
    MAKEFILENAME="makefile_darep"
    
    MAKEFILE="${COMPOSEDMODELDIR}/makefile"

    # makefile_split
    MAKEFILESPLITNAME="makefile${SPLITEXT}"
    MAKEFILESPLIT="${COMPOSEDMODELDIR}/${MAKEFILESPLITNAME}"

    # remove all old <composedmodelname>RJ_func<i>.cpp files, for each <i> (because exceeding files for i>=nreps are not overwrite by the new files)
    #
    ${PERL} -MGetopt::Long -MFile::Find::Rule -e '
     use strict;
     use warnings;
     use feature "say";

     # parse arguments
     my $COMPOSEDMODELNAME;
     my $COMPOSEDMODELDIR;
     GetOptions("COMPOSEDMODELNAME=s"      => \$COMPOSEDMODELNAME,  # string
                "COMPOSEDMODELDIR=s"       => \$COMPOSEDMODELDIR)   # string
     or die("Error in command line arguments\n");

     my $match=qr/^${COMPOSEDMODELNAME}RJ_func([0-9]+).cpp$/;
     my @TOREMFILES = File::Find::Rule->file()->name( $match )->in( ${COMPOSEDMODELDIR} );
     foreach my $file ( @TOREMFILES ) {
         unlink $file or warn "Could not unlink $file: $!";
     }
' -- --COMPOSEDMODELNAME="${COMPOSEDMODELNAME}" --COMPOSEDMODELDIR="${COMPOSEDMODELDIR}"

    # generate:
    #    <composedmodelname>RJ_func<i>.cpp files for each <i>
    #    <composedmodelname>RJ_split.cpp file
    #    <composedmodelname>RJ_split.h file
    #    makefile_split file
    #
    ${PERL} -MText::Xslate -MText::Xslate::Syntax::Kolon -ne 'BEGIN{
  # for func

   $composedmodeldir='"'""${COMPOSEDMODELDIR}""'"';
   $splitext='"${SPLITEXT}"';
   $compmodel='"${COMPOSEDMODELNAME}"';
   $funcbtemplate='"'""${FUNCBEGIN}""'"';
   $funce='"'""${FUNCEND}""'"';
   $skipfunc=1; # true

   # for split cpp
   $rjhname='"'""${RJHNAME}""'"';
   $rjh='"'""${RJH}""'"';
   $rjsplithname='"'""${RJSPLITHNAME}""'"';
   my $outrjsplitcpp='"'""${RJSPLITCPP}""'"';
   open $fhsplitcpp, ">", $outrjsplitcpp or die $!;

   # for split h
   $rjhbase='"'""${RJHBASE}""'"';
   $rjsplithbase='"'""${RJSPLITHBASE}""'"';
   $funcdec="private:\n";

   # for makefile_split
   $rjsplithbase='"'""${RJSPLITHBASE}""'"';
   $rjobj=${rjhbase} . ".o";
   my $rjsplitobj=${rjsplithbase} . ".o";
   $funcobjs=${rjsplitobj};

   # templates file
   my %vpath = (
      "funcbegin.tx" => '"'""${FUNCBEGIN}""'"',
      );
   $tx = Text::Xslate->new(
          path => \%vpath,
          cache_dir => "$ENV{HOME}/.xslate_cache",
          cache => 1,
          syntax => "Text::Xslate::Syntax::Kolon",
          type => "text"
         );
   # variables for the template
   %vars_funcbegin = (
          compmodel => $compmodel,
          splitext  => $splitext,
          i         => ""
        );
}
          my $line=$_;
          if( $line =~ /\/\/Shared variable/ && ((split(/\s+/, $line))[3] % 4)==0  ){
              $skipfunc=0; # false 
              if( defined $fhfunc ) {
                print $fhfunc "\n" . $funce;
                close $fhfunc;
              }
              $i=(split(/\s+/, $line))[3];
              my $outrjfunc=$composedmodeldir . "/" . $compmodel . "RJ_func" . ${i} . ".cpp";
              $vars_funcbegin{"i"}=$i;
              $funcb=$tx->render("funcbegin.tx", \%vars_funcbegin);
              open $fhfunc, ">", $outrjfunc or die $!;
              print $fhfunc $funcb . "\n";

              # for split cpp
              my $callfunc="func" . ${i} . "();";
              print $fhsplitcpp $line;
              print $fhsplitcpp $callfunc . "\n";

              # for split h: list of function declarations
              $funcdec.="void func" . ${i} ."(void);\n";

              # for makefile split
              $funcobjs.=" " . $rjhbase . "_func" . ${i} . ".o";
          } else { 
           if( $line =~ /\}/ && ((split(/\s+/, $line))[3] % 4)==0 ){
            if( $closedcb==1 ){
              print $fhfunc $funce . "\n";
              close $fhfunc;
              $skipfunc=1; # true
            } else { 
              $closedcb=1; 
            }
           }
           if( $line !~ /\}/ && $line !~ /^[[:space:]]*$/ ) { 
            if( $closedcb==1 ){ 
              $closedcb=0; 
            }
           }
           if( $skipfunc == 0 ) { 
              if( defined $fhfunc ) {
                 print $fhfunc $line;
              } 
           } else { # for split cpp
              $line =~ s/Composed\/${compmodel}\/${rjhname}/Composed\/${compmodel}\/${rjsplithname}/g if $. == 1;
              print $fhsplitcpp $line;
           }
         }
    END{
       # for split cpp
       close $fhsplitcpp;

       # for split h
       open my $fhrjh, "<", $rjh or die "Could not open file ${rjh} $!";
       my $outrjsplith='"'""${RJSPLITH}""'"';
       open my $fhsplith, ">", $outrjsplith or die "Could not open file $outrjsplith $!";
       while (my $row = <$fhrjh>) {
          #chomp $row;
          $row =~ s/${rjhbase}/${rjsplithbase}/g if( $. == 1 || $. == 2 );
          $row =~ s/\}/${funcdec}\n\}/g;
          print $fhsplith "$row";
       }
       close $fhrjh;
       close $fhsplith;

       # for makefile_split
       my $makefile='"'""${MAKEFILE}""'"';
       open my $fhmakefile, "<", $makefile or die "Could not open file ${rjh} $!";
       my $outmakefilesplit='"'""${MAKEFILESPLIT}""'"';
       open my $fhmakefilesplit, ">", $outmakefilesplit or die "Could not open file $outmakefilesplit $!";
       while (my $row = <$fhmakefile>) {
          #chomp $row;
          $row =~ s/OBJS=${rjobj}/OBJS=${funcobjs}\n/g if $. == 1;
          $row =~ s/lib${rjhbase}\.a/lib${rjsplithbase}\.a/g;
          $row =~ s/lib${rjhbase}_debug\.a/lib${rjsplithbase}_debug\.a/g;
          print $fhmakefilesplit "$row";
       }
       close $fhmakefile;
       close $fhmakefilesplit;       
    }
         ' "${RJCPP}"

    # generate makefile_split for each solver
    #

    # solvers dir
    SOLVER="${PROJECT}/Solver"

    # get simulation solvers based on the row: MAINLIB=-lsimMain
    SIMSOLVERS=$(find "${SOLVER}" -name "${MAKEFILENAME}" -exec grep -l "MAINLIB=-lsimMain" {} \; | awk -F'/' 'BEGIN{OFS="/"}NF{NF--};1')

    echo "Generated makefiles for split:";
    # generate makefile_split for each solver
    echo "${SIMSOLVERS}" | awk -v mf="${MAKEFILENAME}" '{printf"%s/%s\n", $0, mf}' | xargs -n1 ${PERL} -ne 'BEGIN{
   $splitext='"${SPLITEXT}"';
   $compmodel='"${COMPOSEDMODELNAME}"';
   $rjhbase='"'""${RJHBASE}""'"';
   $rjsplithbase='"'""${RJSPLITHBASE}""'"';
   $makefilesplitname='"'""${MAKEFILESPLITNAME}""'"';

   my $solverdir="$ARGV[0]"; # file path
   $solverdir =~ s/(.*)\/.*$/$1/; # get solver path

   $solvername="${solverdir}"; # file path
   $solvername =~ s/.*\/(.*$)/$1/; # get solver name

   my $outmakefilesplit="${solverdir}/${makefilesplitname}";
   open $fhmakefilesplit, ">", $outmakefilesplit or die "Could not open file $outmakefilesplit $!";
   say STDOUT "$outmakefilesplit";
}

my $row=$_;
$row =~ s/-l${rjhbase}/-l${rjsplithbase}/g;
$row =~ s/cd \.\.\/\.\.\/Composed\/${compmodel}\/ \&\& \$\(MAKE\) clean/cd \.\.\/\.\.\/Composed\/${compmodel}\/ \&\& \$\(MAKE\) -f ${makefilesplitname} clean/g;
$row =~ s/cd \.\.\/\.\.\/Composed\/${compmodel}\/ \&\& \$\(MAKE\) \$\(\@F\)/cd \.\.\/\.\.\/Composed\/${compmodel}\/ \&\& \$\(MAKE\) -f ${makefilesplitname} \$\(\@F\)/g;
$row =~ s/${solvername}Sim/${solvername}${splitext}Sim/g;
print $fhmakefilesplit "$row"; 
'

    # get simulation solvers based on the row: MAINLIB=-lsimMain
    NOSIMSOLVERS=$(find "${SOLVER}" -mindepth 1 -maxdepth 1 -type d '!' -exec test -e "{}/${MAKEFILENAME}" ';' -print | awk -F'/' '{printf"   %s\n", $NF}')

    if [ -n "${NOSIMSOLVERS}" ]; then
          echo "Ops! Missing makefile_darep, makefile_split cannot be generated for following solvers: "
          echo "${NOSIMSOLVERS}"
          echo "Run command darep/bin/solvermakefile.pl to generate darep makefiles."
          echo "Then relaunch this script."
    fi
} # main

# help based on here document approach
function help {
    cat <<EOF

Usage: $0 [-h] <composedmodelname>
  -h (optional argument): help info.

This script, in order to reduce the memory occupation and 
cpu times during compilation, splits the cpp composed 
model file in multiple cpp files.
In particular, based on one-liner perl command, the script generates:
- the <composedname>RJ_func<i>.cpp files, 
  each file defines the function func<i>() with the 
  code corresponding to the //Shared variable <i> 
  copied from the input file <composedname>RJ.cpp
- the <composedname>RJ_split.cpp file, where each code 
  corresponding to the //Shared variable <i>
  has been replaced with the call to function func<i>()
- the <composedname>RJ_split.h file, where each function func<i>() 
  is declared
- the makefile_split file used to compile the new 
  files <composedname>RJ_func<i>.cpp included in the library 
  for the composed model
- the makefile_split files, one for each simulator solver, used 
  to generate the simulator solvers based on the splitted 
  composed model source file

where the name of the composed model <composedname> 
is the input file.
EOF
    exit $E_BADARGS
}


# load bash lib file:
# source the file <scriptdir>/$1
# $1: local-to-script-dir library file path 
function loadlib {
    # the absolute path of the directory where is this script
    local SCRIPTDIR=$(cd "$(dirname "$BASH_SOURCE")"; pwd)
    
    # the path of the library
    local LIB="${SCRIPTDIR}/$1"

    # load lib file if exists, otherwise exit
    [[ -e "${LIB}" ]] && . "${LIB}" || { echo "Ops! Bash lib not found: ${LIB}"; exit -1; }
}


main "$@"
