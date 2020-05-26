#!/bin/bash

# ***
# install perl modules for darep
# ***

function main () {

    # bash library, path local to script dir
    loadlib "../lib/lib.bash" 

    # darep config files
    loadconfig

    # the absolute project path where is all the stuff, three directories above the script:
    # 3          2               1   0
    # ${BASEDIR}/${DAREPDIRNAME}/bin/<script>
    PROJECT=$(scriptancestorpath 3)


    ################## main #############################

    # check command path
    checkcmdpath "${PERL}"

    E_BADARGS=1
    while getopts ":h" opt; do
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

    if [ $# -gt 0 ];then
        echo "Ops! Too many arguments!"
        help
        exit $E_BADARGS
    fi

    if [ "$hflag" ]; then
        help
        exit $E_BADARGS
    fi

    # [ https://grantm.github.io/perl-libxml-by-example/installation.html ]
    # to compile and install a version of XML::LibXML directly from CPAN, 
    # you must first install both the libxml2 library and the header files 
    # for linking against the library. 
    # The easiest way to do this is to use your distribution's packages. 
    # For example on Debian:distribution: 
    sudo apt-get install libxml2 libxml2-dev

    # install perl modules
    sudo $PERL -MCPAN -e 'install CPAN'
    sudo $PERL -MCPAN -e 'load CPAN'
    sudo $PERL -MCPAN -e 'install YAML::XS'
    sudo $PERL -MCPAN -e 'install inc::latest'
    sudo $PERL -MCPAN -e 'install Data::MessagePack'
    sudo $PERL -MCPAN -e 'install File::Copy::Recursive'
    sudo $PERL -MCPAN -e 'install Test::Exception'
    sudo $PERL -MCPAN -e 'install Test::LeakTrace'
    sudo $PERL -MCPAN -e 'install Test::Output'
    sudo $PERL -MCPAN -e 'install Text::Xslate'
    sudo $PERL -MCPAN -e 'install Path::Tiny'
    sudo $PERL -MCPAN -e 'install File::Touch'
    sudo $PERL -MCPAN -e 'install File::Cat'
    sudo $PERL -MCPAN -e 'install IO::Prompter'
    sudo $PERL -MCPAN -e 'install File::Slurp'
    sudo $PERL -MCPAN -e 'install XML::LibXML'
    sudo $PERL -MCPAN -e 'install XML::LibXML::Reader'
    sudo $PERL -MCPAN -e 'install Linux::Distribution'
    sudo $PERL -MCPAN -e 'install XML::Normalize::LibXML'
    sudo $PERL -MCPAN -e 'install File::Find::Rule'
    sudo $PERL -MCPAN -e 'install XML::Entities'
    sudo $PERL -MCPAN -e 'install Sort::Naturally'
    
} # main


# help based on here document approach
function help {
    cat << EOF

This script install perl modules for darep.

Usage: $0 [-h]
  -h (optional argument): help info.
EOF
    exit $E_BADARGS
}

# bash function
# filter input standard to xml pretty format
function xmlprettyformat (){
    # filter and next remove first line added by xmllint
    xmllint --format - | perl -lne 'print unless $. == 1'
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
