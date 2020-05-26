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
    PROJECTNAME=`basename "${PROJECT}"`

    # projects dir
    PROJECTS=$(ancestorpath 1 ${PROJECT})

    # Atomic
    ATOMIC="${PROJECT}/Atomic"

    # solvers dir
    SOLVERS="${PROJECT}/Solver"

    # prj file
    PRJFILE="${PROJECT}/${PROJECTNAME}.prj"

    # darep directory path
    DAREP="${PROJECT}/${DAREPDIRNAME}"
    # input ${DAREPDIRNAME}
    INPUTPAR="${DAREP}/input"


    ################## main #############################

    # check command path
    checkcmdpath "${RSYNC}"

    E_BADARGS=1
    while getopts ":p:s:i:h" opt; do
        case $opt in
	    p)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-d was triggered! Parameter: $OPTARG" >&2
                    pflag="$OPTARG"
                fi
	        ;;
	    s)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-d was triggered! Parameter: $OPTARG" >&2
                    sflag="$OPTARG"
                fi
	        ;;
	    i)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-d was triggered! Parameter: $OPTARG" >&2
                    iflag="$OPTARG"
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

    if [ -z "$pflag" ]; then
        SOURCEPROJECTNAME="${PROJECTNAME}_copy"
    else
        SOURCEPROJECTNAME="${pflag}"
    fi

    if [ -z "$sflag" ]; then
        SOLVERNAME="ms_varn_delta1"
    else
        SOLVERNAME="${sflag}"
    fi

    if [ -z "$iflag" ]; then
        PATTERN="*"
    else
        PATTERN="${iflag}"
    fi

    # source of the results
    SOURCESOLVER="${PROJECTS}/${SOURCEPROJECTNAME}/Solver/${SOLVERNAME}"

    # destination dir
    DESTSOLVER="${SOLVERS}/${SOLVERNAME}"

    # check the source solver 
    if [ ! -d "$SOURCESOLVER" ]; then
        echo "Ops! Source solver not found: ${SOURCESOLVER}"
        exit -1;
    fi

    # check the source solver 
    if [ ! -d "$DESTSOLVER" ]; then
        echo "Ops! Destination solver not found: ${SOURCESOLVER}"
        exit -1;
    fi

    # copy the solver
    #echo "${SOURCEPROJECTNAME}:${SOLVERNAME} -> ${PROJECTNAME}:${SOLVERNAME}"
    #echo "copy: ${SOURCESOLVER} -> ${DESTSOLVER}"
    echo "from project: ${SOURCEPROJECTNAME}"
    echo "to project: ${PROJECTNAME}"
    echo "solver: ${SOLVERNAME}"
    ${RSYNC} -auv  --include="${PATTERN}" --exclude="*" "${SOURCESOLVER}/" "${DESTSOLVER}"

} # main


# help based on here document approach
function help {
    cat << EOF

Usage: $0 [-h] [-p <projectname>] [-s <solvername>] [-i <pattern>]
  -p <projectname> (optional argument): project from which copy the results (<current_project_name>_copy by default).
  -s <solvername> (optional argument): name of the solver from which copy the results and name of the solver into copy the results (ms_varn_delta1 by default).
  -i <pattern> (optional argument): pattern of the files to copy;
              if the option is omitted, all files are considered. 
  -h (optional argument): help info. 
To copy the files (results) from the solver of the project to the same solver of the current project, 
skipping files which exist on the destination and have a modified time that is newer than the source file (-u option of rsync).
Example: 
	 getresultsfromrun.bash -p parallelWorkingStations_darep_n1000_ndeps1 -s ms_varn_ndeps1 -i "*_4.txt"
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
