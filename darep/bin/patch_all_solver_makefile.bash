#!/bin/bash

# define the patch to fix makefile of each solver:
#   missing USERDEFLIBNAME_debug and USERDEFLIBNAME_trace

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

    # AWK file name
    AWKFILENAME="progfile_patch_solver_makefile.awk"

    # the Solver path
    SOLVER="${PROJECT}/Solver"

    # where is the script
    BIN=$(scriptancestorpath 1)

    # awk file name
    AWKFILE="${BIN}/${AWKFILENAME}"

    
    SOLVERS=$(ls -A1 "${SOLVER}" | grep -v -E "^\." | awk '{gsub(" ","",$0); printf"%s ",$0}')
    FIXEDSOLVERS=""
    NOTFOUNDSOLVERS=""

    if [ ! -f "${AWKFILE}" ]; then
        echo "Ops! Fileprog not found: ${AWKFILE}"
        exit
    fi

    for i in ${SOLVERS}; do
        SOLVERi="${SOLVER}/${i}"
        makefilei="${SOLVERi}/makefile"
        tmpmakefilei="${SOLVERi}/._makefile"

        if [ -s "${makefilei}" ]; then
	    echo "Fixing makefile: ${makefilei}"
	    rm -f "${tmpmakefilei}"
	    ${AWK} -f "${AWKFILE}" ${makefilei} > ${tmpmakefilei}
	    rm -f "${makefilei}"
	    mv "${tmpmakefilei}" "${makefilei}"
	    FIXEDSOLVERS="${FIXEDSOLVERS}\n\t${SOLVERi}"
        fi
    done

    echo ""
    for i in ${SOLVERS}; do
        SOLVERi="${SOLVER}/${i}"
        makefilei="${SOLVERi}/makefile"
        tmpmakefilei="${SOLVERi}/._makefile"

        if [ ! -s "${makefilei}" ]; then
	    echo "*** Ops! makefile not found or empty: ${makefilei}"
	    echo "Please, using Mobius GUI or Mobius shell, generate makefile for solver: ${i}"
	    echo ""
	    NOTFOUNDSOLVERS="${NOTFOUNDSOLVERS}\n\t${SOLVERi}"
        fi
    done

    if [ -n "${FIXEDSOLVERS}" ]; then 
        echo -e "Fixed makefile for each solver: ${FIXEDSOLVERS}"
    fi
    echo ""
    if [ -n "${NOTFOUNDSOLVERS}" ]; then 
        echo -e "*** Not found makefiles for solvers: ${NOTFOUNDSOLVERS}"
        echo "*** Using Mobius GUI or Mobius shell, generate makefile for above listed solvers."
    fi
    echo ""


} # main


# help based on here document approach
function help {
    cat << EOF

Usage: $0 [-h]
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
