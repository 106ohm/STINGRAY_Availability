#!/bin/bash

function main() {

    # bash library, path local to script dir
    loadlib "../lib/lib.bash" 

    # darep config files
    loadconfig

    # the absolute project path where is all the stuff, three directories above the script:
    # 3          2               1   0
    # ${BASEDIR}/${DAREPDIRNAME}/bin/<script>
    PROJECT=$(scriptancestorpath 3)
    # check if basedir contains darep/bin
    checkmergedpaths "${PROJECT}" "${DAREPDIRNAME}/bin"

    # project name
    PROJECTNAME=$(basename "${PROJECT}")

    # projects dir
    PROJECTS=$(ancestorpath 1 ${PROJECT})

    # prj file
    PRJFILE="${PROJECT}/${PROJECTNAME}.prj"


    ################## main #############################


    # check command path
    checkcmdpath "${PERL}"

    # check command path
    checkcmdpath "${RSYNC}"

    E_BADARGS=1
    while getopts ":e:fh" opt; do
        case $opt in
	    e)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-d was triggered! Parameter: $OPTARG" >&2
                    eflag="$OPTARG"
                fi
	        ;;
	    f)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-h was triggered! Parameter: $OPTARG" >&2
                    fflag=1
                fi
	        ;;
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

    if [ $# -gt 0 ]; then
        echo "Ops! Too many arguments!"
        help
        exit $E_BADARGS
    fi

    if [ "$hflag" ]; then
        help
        exit $E_BADARGS
    fi


    if [ -z "$eflag" ]; then
        PROJECTCOPYNAME="${PROJECTNAME}_copy"
    else
        PROJECTCOPYNAME="${PROJECTNAME}${eflag}"
    fi

    # destination dir
    PROJECTCOPYDIR="${PROJECTS}/${PROJECTCOPYNAME}"

    # prj file of project copy
    OLDPRJFILECOPYNAME="${PROJECTNAME}.prj"
    OLDPRJFILECOPY="${PROJECTCOPYDIR}/${PROJECTNAME}.prj"
    PRJFILECOPYNAME="${PROJECTCOPYNAME}.prj"
    PRJFILECOPY="${PROJECTCOPYDIR}/${PRJFILECOPYNAME}"

    # check destination of project copy
    if [ -d "$PROJECTCOPYDIR" ]; then
        PROJECTCOPYDIRFOUND="y"
    else
        PROJECTCOPYDIRFOUND="n"
    fi

    
    # if destination project with the same name already exists, it can be backupped and then replaced
    if [ "${PROJECTCOPYDIRFOUND}" == "y" ]; then
        echo "Ops! Project with the same name already exists: ${PROJECTCOPYNAME}"
        echo "Project will be backupped and replaced: ${PROJECTCOPYNAME}"
        if [ "$fflag" ]; then
            echo "Are you sure? [y/N]"
	    response="y"
        else
            read -r -p "Are you sure? [y/N]" response
        fi
        case "$response" in
	    [yY][eE][sS]|[yY]) 
                # Backup the existing project and continue
	        DATE=$(date "+%Y%m%d%H%M%S")
	        BKEXT="-DAREP-${DATE}.bk"
	        echo "bk: ${PROJECTCOPYNAME} -> ${PROJECTCOPYNAME}${BKEXT}"
	        mv "${PROJECTCOPYDIR}" "${PROJECTCOPYDIR}${BKEXT}"
                ;;
	    *)
                # Otherwise exit
	        exit $E_BADARGS;
                ;;
        esac    
    fi

    # copy the project
    echo "copy: ${PROJECTNAME} -> ${PROJECTCOPYNAME}"
    #echo "copy: ${PROJECT} -> ${PROJECTCOPYDIR}"
    #
    # The trailing slash '/' on the source avoids creating an additional directory level at the destination
    #
    #${RSYNC} --exclude '.bzr' -av "${PROJECT}/" "${PROJECTCOPYDIR}"
    ${RSYNC} --exclude '.bzr' -a "${PROJECT}/" "${PROJECTCOPYDIR}"

    # rename prj file of project copy
    #echo "mv: ${OLDPRJFILECOPYNAME} -> ${PRJFILECOPYNAME}"
    mv "${OLDPRJFILECOPY}" "${PRJFILECOPY}"

    # the XML declaration of template SAN: a processing instruction at first row that identifies the document as being XML (first row of the SAN file).
    XMLDECLARATION=$(awk '{print $0; exit}' "${PRJFILECOPY}")

    # update prj file
    ${PERL} -MGetopt::Long -MXML::LibXML -e '
     use strict;
     use warnings;
     use feature "say";

     # parse arguments
     my $PRJFILECOPY;
     my $PROJECTCOPYNAME;
     GetOptions("PRJFILECOPY=s"       => \$PRJFILECOPY,  # string
                 "PROJECTCOPYNAME=s"   => \$PROJECTCOPYNAME)         # string
     or die("Error in command line arguments\n");

     my $xmlprj = XML::LibXML->load_xml( location => $PRJFILECOPY,
                                    no_blanks => 1 ) # whitespace-only text nodes are removed
     or die "Cannot open file: $PRJFILECOPY\n";
     # get attribute
     my $name = $xmlprj->findnodes(qq(/models:Project/\@name))->[0]; 
     # set new value: the new project name
     $name->setValue($PROJECTCOPYNAME);
     # update prj file
     local $XML::LibXML::setTagCompression = 1; # replace self-closing tags with empty elements
     # the XML declaration is not omitted during serialization
     local $XML::LibXML::skipXMLDeclaration = 0;
     $xmlprj->toFile($PRJFILECOPY, 1);
' -- --PRJFILECOPY="$PRJFILECOPY" --PROJECTCOPYNAME="$PROJECTCOPYNAME"

    # output info
    echo "*** Original project copied to: ${PROJECTCOPYNAME}"

} # main


# help based on here document approach
function help {
    cat << EOF

Usage: $0 [-h] [-f] [-e <ext>]
  -e <ext> (optional argument): the name of the copied project is obtained by adding the extension  <ext> to the original project name (default: add _copy to the name of the original project)
  -f (optional argument): force script to answer yes to all prompts (automatic backup of destination project)
  -h (optional argument): help info. 
To make a copy of the current project. Each copy can be used to run darep model with a different input file.
EOF
    exit $E_BADARGS
}


# bash function
# filter input standard to xml pretty format
# On OpenSUSE xmllint is provided by package: libxml2-tools
# On Ubuntu xmllint is provided by package: libxml2-utils
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
