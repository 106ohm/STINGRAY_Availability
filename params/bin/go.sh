#!/bin/bash

# params library
function main () {

    # the absolute project path where is all the stuff, three directories above the script:
    # 2       1   0
    # basedir/bin/<script>
    BASEDIR=$(scriptancestorpath 2)

    # name of the basedir
    BASENAME=$(basename "${BASEDIR}")

    # input options 
    getarguments "$@"

    # params
    PARAMS="${BASEDIR}"
    # params bin
    PARAMSBIN="${PARAMS}/bin"
    # params src
    PARAMSSRC="${BASEDIR}/src"

    echo "params: generating library ..."
        
    # make library
    pushd "${PARAMSSRC}"
    make clean
    make opt
    make debug
    popd
        
    # make test
    pushd "${PARAMSSRC}"
    make cleant
    make test
    make test_debug
    popd
}       

# get arguments of the script
getarguments () {

    E_BADARGS=1
    while getopts ":hdmlt" opt; do
        case $opt in
	    d)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-d was triggered! Parameter: $OPTARG" >&2
                    dflag=1
                fi
	        ;;
	    m)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-d was triggered! Parameter: $OPTARG" >&2
                    mflag=1
                fi
	        ;;
	    l)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-d was triggered! Parameter: $OPTARG" >&2
                    lflag=1
                fi
	        ;;
	    t)
                if [ "${OPTARG:0:1}" = "-" ]; then
                    echo "Ops! Invalid parameter \"${OPTARG}\" provided for agurment \"-${opt}!\"" 1>&2
                    hflag=1
                else
		    #               echo "-d was triggered! Parameter: $OPTARG" >&2
                    tflag=1
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
    
    # the help
    if [ $hflag ];then
        help
        exit $E_BADARGS
    fi

    # check number of input args
    if [ $# -gt 1 ];then
        echo "Ops! Too many arguments!"
        help
        exit $E_BADARGS
    fi

    # input m file
    INPUTMFILE="$1"

}


# check default input file names from current files
# $1: DAREPCURRENTM, path of the file that include the path of the matpower default current input file m used to generate xml file
# $2: DAREPCURRENT, path of the file that include the path of the darep default current input file xml
# $3: MATPOWERCURRENT, path of the file that include the path of the matpower default current input file m
# $4: STATECURRENTM, path of the file that include the path of the matpower default current input file spg used to generate spg file
# $5: STATECURRENT, path of the file that include the path of the params default current input file spg
checkcurrent () {
    local DAREPCURRENTM="$1"
    local DAREPCURRENT="$2"
    local MATPOWERCURRENT="$3"
    local STATECURRENTM="$4"
    local STATECURRENT="$5"

    mxmlfile=$(cat "${DAREPCURRENTM}")
    xmlfile=$(cat "${DAREPCURRENT}")
    mfile=$(cat "${MATPOWERCURRENT}")
    mspgfile=$(cat "${STATECURRENTM}")
    spgfile=$(cat "${STATECURRENT}")

    # check empty current file for matpower to darep
    if [[ "$mxmlfile" == "" ]]; then
        echo "Ops! Empty current file: ${DAREPCURRENTM}"
        echo "Please, run matpowerdarep script with the input <mfile>."
        exit 1
    fi
    # check empty current file for darep
    if [[ "$xmlfile" == "" ]]; then
        echo "Ops! Empty current file: ${DAREPCURRENT}"
        echo "Please, run darep script with the input <inputxmlfile>."
        exit 1
    fi
    # check empty current file for matpower
    if [[ "$mfile" == "" ]]; then
        echo "Ops! Empty current file: ${MATPOWERCURRENT}"
        echo "Please, run matpower script with the input <mfile>."
        exit 1
    fi
    # check empty current file for matpower to params
    if [[ "$mspgfile" == "" ]]; then
        echo "Ops! Empty current file: ${STATECURRENTM}"
        echo "Please, run params script with the input <spgfile>."
        exit 1
    fi
    # check empty current file for params
    if [[ "$spgfile" == "" ]]; then
        echo "Ops! Empty current file: ${STATECURRENT}"
        echo "Please, run params script with the input <spgfile>."
        exit 1
    fi

    # get basename: the/full/path/basename.ext -> basename
    bmxmlfile="${mxmlfile##*/}"
    bmxmlfile="${bmxmlfile%.*}"
    bxmlfile="${xmlfile##*/}"
    bxmlfile="${bxmlfile%.*}"
    bmfile="${mfile##*/}"
    bmfile="${bmfile%.*}"
    bmspgfile="${mspgfile##*/}"
    bmspgfile="${bmspgfile%.*}"
    bspgfile="${spgfile##*/}"
    bspgfile="${bspgfile%.*}"

    # equality Comparison 
    if [[ "$bmxmlfile" == "$bspgfile"  && "$bxmlfile" == "$bspgfile" && "$bmfile" == "$bspgfile" && "$bmspgfile" == "$bspgfile" ]]; then
        echo "Checked basenames of the input files of all libraries."
        echo "Input file: ${mfile}" 
    else
        echo "Ops! Different basenames for input files of each library (darep, matpower and params):"
        echo "matpower to darep:  $mxmlfile"
        echo "darep:    $xmlfile"
        echo "matpower: $mfile"
        echo "matpower to params:   $mspgfile"
        echo "params:   $spgfile"
        echo "Please, use the same basename for the input files of all libraries."
        exit 1;

    fi
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


# help based on here document approach
function help {
    cat << EOF

This script generates, in the order:
 1. the C++ data structures of the user defined libraries from which params depends (darep and control) and recursively of all other user defined dependencies,
 2. the control library, and
 3. the test executables.
If the optional <inputmfile> is omitted, the last current input file is used.
Steps 1., 2. or 3., or a combination of them, can be enabled using the options -d, -l or -t, respectively. 

Usage: $0 [-h] [-d] [-m] [-l] [-t] [<inputmfile>]
  - <inputmfile> (optional argument): the path, local to the directory input/matpower, of the input .m file. It must not be a full global path. If omitted, the last current input file is used. 
  -d (optional argument): generate recursively only the C++ data structures for all user defined dependencies.
  -m (optional argument): no action (use data structures generated by state).
  -l (optional argument): generate only the library.
  -t (optional argument): generate only the test executables.
  -h (optional argument): help info.

Examples:
            $0 ./input/matpower/scenario1/input.m   (erroneous input path)
            $0 ./scenario1/input.m   (correct path, relative to the directory input/matpower)
EOF
    exit $E_BADARGS
}

main "$@"

