#!/bin/bash

function main () {

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
    PROJECTNAME=`basename "${PROJECT}"`

    # Atomic
    ATOMIC="${PROJECT}/Atomic"

    # prj file
    PRJFILE="${PROJECT}/${PROJECTNAME}.prj"

    # darep directory path
    DAREP="${PROJECT}/${DAREPDIRNAME}"
    # input ${DAREPDIRNAME}
    INPUTPAR="${DAREP}/input"

    # the temporary batch file including the mobius-shell commands to resave
    MSHELLRESAVE="${DAREP}/.resave.mshell"

    ################## main #############################

    # check command path
    checkcmdpath "${MSHELL}"

    E_BADARGS=1
    while getopts ":d:h" opt; do
        case $opt in
	    d)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-d was triggered! Parameter: $OPTARG" >&2
                    dflag="$OPTARG"
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



    if [ -z "$dflag" ]; then
        export DISPLAY=":3"
    else
        export DISPLAY="${dflag}"
    fi

    # make temporary file including mobius-shell commands to resave
    cat << EOF > ${MSHELLRESAVE}
open ${PROJECTNAME} 
resave
exit
EOF

    # mobius shell: resave
    ${MSHELL} -s ${MSHELLRESAVE}

    # remove mobius-shell temporary file
    rm -f ${MSHELLRESAVE}

    # output info
    echo "*** resave done: ${PROJECTNAME}"

} # main


# help based on here document approach
function help {
    cat << EOF

Usage: $0 [-h] [-d <display>]
  -d <display> (optional argument): the value <display>, used to set the  environment variable DISPLAY, is the display where is open the mobius gui, the mobius shell is based on (default: :0)
  -h (optional argument): help info. 
To generate the C++ source code and the files makefile for the current project, i.e., to execute the GUI command ``resave''.
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
