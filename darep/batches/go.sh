#!/bin/bash

function main() {

    # bash library, path local to script dir
    loadlib "../lib/lib.bash" 
    
    # darep config files
    loadconfig

    # basic project variables are set in function varinit
    varinit

    # delta
    DELTA="1"
    # my solver
    SOLVER="${SOLVERSDIR}/ms_varn_delta${DELTA}"

    # batch arguments: <n_reps> <exp_number> <delta> <split>
    #
    timeu.sh -o ${SOLVER}/a_result_1000_1.txt -e ${SOLVER}/a_error_1000_1.txt -t ${SOLVER}/a_time_1000_1.txt "./batch_scenario_varn_delta.sh 10   1 ${DELTA} false"
    timeu.sh -o ${SOLVER}/a_result_1000_2.txt -e ${SOLVER}/a_error_1000_2.txt -t ${SOLVER}/a_time_1000_2.txt "./batch_scenario_varn_delta.sh 100  2 ${DELTA} false"
    timeu.sh -o ${SOLVER}/a_result_1000_3.txt -e ${SOLVER}/a_error_1000_3.txt -t ${SOLVER}/a_time_1000_3.txt "./batch_scenario_varn_delta.sh 1000 3 ${DELTA} false"


    # delta
    DELTA="7"
    # my solver
    SOLVER="${SOLVERSDIR}/ms_varn_delta${DELTA}"
    
    # batch arguments: <n_reps> <exp_number> <delta> <split>
    #
    timeu.sh -o ${SOLVER}/a_result_1000_1.txt -e ${SOLVER}/a_error_1000_1.txt -t ${SOLVER}/a_time_1000_1.txt "./batch_scenario_varn_delta.sh 10   1 ${DELTA} false"
    timeu.sh -o ${SOLVER}/a_result_1000_2.txt -e ${SOLVER}/a_error_1000_2.txt -t ${SOLVER}/a_time_1000_2.txt "./batch_scenario_varn_delta.sh 100  2 ${DELTA} false"
    timeu.sh -o ${SOLVER}/a_result_1000_3.txt -e ${SOLVER}/a_error_1000_3.txt -t ${SOLVER}/a_time_1000_3.txt "./batch_scenario_varn_delta.sh 1000 3 ${DELTA} false"


    # delta
    DELTA="50"
    # my solver
    SOLVER="${SOLVERSDIR}/ms_varn_delta${DELTA}"
    
    # batch arguments: <n_reps> <exp_number> <delta> <split>
    #
    timeu.sh -o ${SOLVER}/a_result_1000_2.txt -e ${SOLVER}/a_error_1000_2.txt -t ${SOLVER}/a_time_1000_2.txt "./batch_scenario_varn_delta.sh 100  2 ${DELTA} false"
    timeu.sh -o ${SOLVER}/a_result_1000_3.txt -e ${SOLVER}/a_error_1000_3.txt -t ${SOLVER}/a_time_1000_3.txt "./batch_scenario_varn_delta.sh 1000 3 ${DELTA} false"

    # delta
    DELTA="74"
    # my solver
    SOLVER="${SOLVERSDIR}/ms_varn_delta${DELTA}"
    
    # batch arguments: <n_reps> <exp_number> <delta> <split>
    #
    timeu.sh -o ${SOLVER}/a_result_1000_2.txt -e ${SOLVER}/a_error_1000_2.txt -t ${SOLVER}/a_time_1000_2.txt "./batch_scenario_varn_delta.sh 100  2 ${DELTA} false"
    timeu.sh -o ${SOLVER}/a_result_1000_3.txt -e ${SOLVER}/a_error_1000_3.txt -t ${SOLVER}/a_time_1000_3.txt "./batch_scenario_varn_delta.sh 1000 3 ${DELTA} false"


    # nreps
    NREPS="100"
    # delta
    DELTA="10"
    # my solver
    SOLVER="${SOLVERSDIR}/ms_vark_n${NREPS}_delta${DELTA}"
    
    # batch arguments: <n_reps> <delta> <split>
    ./batch_scenario_vark_n_delta.sh ${NREPS} ${DELTA} false

    # nreps
    NREPS="1000"
    # delta
    DELTA="10"
    # my solver
    SOLVER="${SOLVERSDIR}/ms_vark_n${NREPS}_delta${DELTA}"
    
    # batch arguments: <n_reps> <delta> <split>
    ./batch_scenario_vark_n_delta.sh ${NREPS} ${DELTA} false
    

    # delta
    DELTA="148"
    # my solver
    SOLVER="${SOLVERSDIR}/ms_varn_delta${DELTA}"
    
    # batch arguments: <n_reps> <exp_number> <delta> <split>
    #
    timeu.sh -o ${SOLVER}/a_result_1000_3.txt -e ${SOLVER}/a_error_1000_3.txt -t ${SOLVER}/a_time_1000_3.txt "./batch_scenario_varn_delta.sh 1000 3 ${DELTA} true"

exit

    # delta
    DELTA="749"
    # my solver
    SOLVER="${SOLVERSDIR}/ms_varn_delta${DELTA}"
    
    # batch arguments: <n_reps> <exp_number> <delta> <split>
    #
 #   timeu.sh -o ${SOLVER}/a_result_1000_3.txt -e ${SOLVER}/a_error_1000_3.txt -t ${SOLVER}/a_time_1000_3.txt "./batch_scenario_varn_delta.sh 1000 3 ${DELTA} true"


    # delta
    DELTA="370"
    # my solver
    SOLVER="${SOLVERSDIR}/ms_varn_delta${DELTA}"
    
    # batch arguments: <n_reps> <exp_number> <delta> <split>
    #
    #timeu.sh -o ${SOLVER}/a_result_1000_3.txt -e ${SOLVER}/a_error_1000_3.txt -t ${SOLVER}/a_time_1000_3.txt "./batch_scenario_varn_delta.sh 1000 3 ${DELTA} true"
 

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
    [[ -e "${LIB}" ]] && . "${LIB}" || { echo "Ops! Bash lib not found: ${LIB}"; exit 1; }
}


main "$@"
