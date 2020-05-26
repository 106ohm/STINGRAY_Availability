###############
# bash library
###############


######################################
### functions 
######################################

# get the absolute path of the script that calls this function (the currently running script)
scriptpath () {
    echo "$(cd "$(dirname "$0")"; pwd)/$(basename "$0")"
}

# get the absolute path of the directory where is the script that calls this function (the currently running script)
scriptdir () {
    echo "$(cd "$(dirname "$0")"; pwd)"
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


# get the absolute path of the file where is defined this function (this lib file)
libpath () {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)/$(basename "${BASH_SOURCE[0]}")"
}


# get the absolute path of the directory where is the file that defines this lib function
libdir () {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
}

# get the i-th ancestor path of the input path (e.g., /the/in/put/pa/th)
# i=0: for the input path (/the/in/put/pa/th),
# i=1: for the part of input path preceeding the last slash '/' character (/the/in/put/pa),
# i=2: for the part of input path preceeding the 2nd last slash '/' characters (the//in/put),
# etc...
# $1: level of the ancestor path (from the end of the path)
# $2: input path
ancestorpath () {
    [[ $1 -lt 0 ]] && { echo "Ops! Input less than 0: $1"; exit 1; }
    local THEPATH="$(cd "$(dirname "$2")"; pwd)/$(basename "$2")"
    i=1
    while [[  $i -le ${1} && "${THEPATH}" != "/" ]]; do
        THEPATH="$(cd "$(dirname "$THEPATH")"; pwd)"
        let i=i+1 
    done
#    echo "depth: $i"
    echo "${THEPATH}"
}


# [ https://stackoverflow.com/questions/3915040/bash-fish-command-to-print-absolute-path-to-a-file ]
# absolute path of input path
# $1: path of directory or file
abspath() {
    local THEPATH="$1"
    local PARENT=$(dirname "${THEPATH}")
    if [ -e "${THEPATH}" ]; then # the path must exist
        if [ -d "${THEPATH}" ]; then # directory path
            echo "$(cd "${THEPATH}"; pwd -P)"
        else # file path
            echo "$(cd ${PARENT}; pwd -P;)/$(basename ${THEPATH})"
        fi
    else # path not found
        echo "Ops! File not found: $THEPATH"
    fi
}

# check if input command path exists
# $1: input cmd path
checkcmdpath() {
    if [ ! -e "${1}" ]; then # path does not exist
        echo "Ops! Command path not found: ${1}"
        exit 127
    else # path exists
        if [ ! -x "${1}" ]; then # path is not executable
            echo "Ops! Command is not executable: ${1}"
            exit 126
        fi
    fi
}

# check if input path exists
# $1: input path
checkpath() {
    if [ ! -e "${1}" ]; then # path does not exist
        echo "Ops! Element not found: ${1}"
        exit 1
    fi
}


# check if input dir path exists
# $1: input dir path
checkdirpath() {
    if [ ! -e "${1}" ]; then # path does not exist
        echo "Ops! Directory not found: ${1}"
        exit 1
    fi
}


# check if the $1/$2 exists
# $1: path of directory
# $2: path of directory or file
checkmergedpaths() {
    if [[ ! -e "${1}/${2}" ]]; then
        echo "Ops! Element not found: ${1}/${2}"
        exit 1
    fi
}

# get OS info: arch, distr, ...
getosinfo() {
    # set os
    # local HOST=$(uname -n)
    local ARCH=""
    local DISTR=""
    # get arch
    if [ "$(uname -s)" == "Darwin" ]; then
	ARCH="macosx"
        DISTR=$(sw_vers -productVersion)
    else
	ARCH="linux"
        DISTR=$(lsb_release -si)
    fi
    echo "${ARCH} ${DISTR}"
}


# load config files, based on OS
loadconfig() {
    local CONF="bash.conf"
    local MACOSXCONF="bash_macosx.conf"
    local LINUXCONF="bash_linux.conf"
    local ETC="$(abspath "$(libdir)/../etc")"
    echo "Load darep bash config files:"
    echo "${ETC}/${CONF}"
    . ${ETC}/${CONF}
    if [[ $(uname) == "Linux" ]]; then
        echo "${ETC}/${LINUXCONF}"
        . ${ETC}/${LINUXCONF}
    else
        echo "${ETC}/${MACOSXCONF}"
        . ${ETC}/${MACOSXCONF}
    fi
}


# set variables
#
varinit() {

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

    # darep dir (absolute path)
    DAREP="${PROJECTS}/${PROJECTNAME}/${DAREPDIRNAME}"

    # params dir (absolute path)
    PARAMS="${PROJECTS}/${PROJECTNAME}/${PARAMSDIRNAME}"

    # Atomic directory
    ATOMICSDIR="${PROJECT}/Atomic"

    # Composed directory
    COMPOSEDSDIR="${PROJECT}/Composed"

    # Reward directory
    REWARDSDIR="${PROJECT}/Reward"

    # Study directory
    STUDIESDIR="${PROJECT}/Study"

    # solver directory
    SOLVERSDIR="${PROJECT}/Solver"
    
    # check solver
    checkdirpath "${SOLVERSDIR}"
}
#
### set variables


######################################
### end functions 
######################################
