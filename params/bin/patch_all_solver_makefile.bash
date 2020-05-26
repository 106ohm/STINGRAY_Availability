#!/bin/bash

# define the patch to fix makefile of each solver:
#   missing USERDEFLIBNAME_debug and USERDEFLIBNAME_trace

function main () {

    AWK="/usr/local/bin/gawk"
    AWKFILENAME="progfile_patch_solver_makefile.awk"
    
    # the absolute project path where is all the stuff, three directories above the script:
    # 3       2       1   0
    # basedir/params/bin/<script>
    BASEDIR=$(scriptancestorpath 3)

    SOLVER="${BASEDIR}/Solver"
    AWKFILE="${BASEDIR}/params/bin/${AWKFILENAME}"
    
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
    
}

# get the i-th ancestor path of the script that calls this function (the currently running script)
# i=0: for the path of the script,
# i=1: for the directory where is the script,
# i=2: for the directory including the directory corresponding to i=1,
# etc...
# $1: level of the ancestor path (from the end of the path)
scriptancestorpath () {
    [[ $1 -lt 0 ]] && { echo "Ops! Input less than 0: $1"; exit 1; }
    local THEPATH="$(cd "$(dirname "$0")"; pwd)/$(basename "$0")"
    i=1
    while [[  $i -le ${1} && "${THEPATH}" != "/" ]]; do
        THEPATH="$(cd "$(dirname "$THEPATH")"; pwd)"
        let i=i+1 
    done
    #    echo "depth: $i"
    echo "${THEPATH}"
}


main "$@"
