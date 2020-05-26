#!/bin/bash

function main() {

    # bash library, path local to script dir
    loadlib "../lib/lib.bash" 

    # darep config files
    loadconfig

    # number of replicas
    NREPS="10"
    # dependecies for each replica
    DELTA="7"
    # darep scenario extension
    SCEEXT="_n${NREPS}_delta${DELTA}"

    # darep model setting
    TEMPLATESANNAME="SAN"
    COMPOSEDMODELNAME="Comp"
    JMODELNAME="SANSANDAREP"
    PLACENAME="Demand_A"
    PLACETYPE="ExtendedPlace<double>"
    # split the resulting composed model cpp file
    #SPLITRJ="true"
    SPLITRJ="true"
    # use a copy of the project for evaluations 
    MKRUNCOPY="false"

    # solver name
    #SOLVERNAME="ms_vark_n100_delta10"
    #SOLVERNAME="ms${SCEEXT}"
    SOLVERNAME="ms"

    # batch file name, depending on the scenario
    #BATCHNAME="batch_time_vark_n${NREPS}_delta${DELTA}.sh"
    BATCHNAME="batch_time_varn_delta7.sh"
    #BATCHNAME="batch_time_vardelta_n${NREPS}.sh"

    # solve for cpu times

    #EXPS=$(seq $MINEXP $MAXEXP)
    EXPS="1"
    #EXPS="1 2 3 4 5 6 7 8 9 10"

    # array of numbers of batches for each experiment
    BATCHES="1000"

    # set extensions for makefile and simulator command
    if [ ${SPLITRJ} == "true" ]; then
        MKEXTDAREP="_darep"
        MKEXT="_split"
        SIMEXT="_split"
    else
        MKEXTDAREP="_darep"
        MKEXT="_darep"
        SIMEXT=""
    fi

    ########### MAIN CODE ##############

    MYDIR="$PWD"

    # basic project variables are set in function varinit
    varinit

    # For each different experiment that requires a different setting for n and delta, perform the following steps:
    
    # 1.  close Mobius GUI before generating darep models
    echo "step 1 ..."
    
    # 2.  set the running project: 
    #       - the original project PROJECTNAME, or 
    #       - an automatically-generated copy of the original project PROJECTNAME, named using a name extension that identifies the solver(s) to evaluate, e.g., _n1000_delta999:
    echo "step 2 ..."
    if [ "${MKRUNCOPY}" == "true" ]; then # generate copy
        ${DAREP}/bin/mkrunningproj.bash -f -e ${SCEEXT}
        COPYEDPROJECTNAME="${PROJECTNAME}${SCEEXT}"
        COPYEDPROJECT="${PROJECTS}/${COPYEDPROJECTNAME}"
        RUNNINGPROJECT="${COPYEDPROJECT}"
    else # use original
        RUNNINGPROJECT="${PROJECT}"
    fi
    # set running solver directory
    RUNNINGSOLVERDIR="${RUNNINGPROJECT}/Solver/${SOLVERNAME}"
    
    # 3. move into the running project, i.e., 
    #    all the commands in the steps
    #    from 4 to 11 are referred to the
    #    running project
    # check running project
    echo "step 3 ..."
    checkdirpath "${RUNNINGPROJECT}"
    cd "${RUNNINGPROJECT}"

    # 4. generate the DAREP xml input file corresponding to the setting for n and delta, using a name extension that identifies the setting to be used, e.g., _n1000_delta999, resulting in the file input_n1000_delta999.xml:
    echo "step 4 ..."
    ${RUNNINGPROJECT}/${DAREPDIRNAME}/bin/inputxml.bash -s "${TEMPLATESANNAME}" -c "${COMPOSEDMODELNAME}" -j "${JMODELNAME}" -p "${PLACENAME}" -t "${PLACETYPE}" -n "${NREPS}" -d "${DELTA}" -e "${SCEEXT}" -f
    
    # 5. generate the darep models and the C++ data structures and the corresponding library for a setting of n and delta:
    echo "step 5 ..."
    checkcmdpath "${PERL}"
    ${RUNNINGPROJECT}/${DAREPDIRNAME}/bin/darep.pl -f input${SCEEXT}.xml
    
    # 6. generate the the C++ data structures for the paramters of the model (params):
    echo "step 6 ..."
    ${RUNNINGPROJECT}/${PARAMSDIRNAME}/bin/params.pl -f input${SCEEXT}.xml
    
    # 7.  generate the files makefile and cpp, using:
    #        - gui command resave, or
    #        - manually mobius shell (with linux, on MacOSX mobius shell does not work), with mobius shell on linux perform the following steps:
    #          setenv DISPLAY :3
    #          rlwrap /usr/share/mobius-2.5/mobius-shell.sh -c
    #          Mobius> open projectnameendingwith_n1000_delta999
    #          Mobius> resave
    #        - automatic script based on batch commands to mobius shell:
    #
    echo "step 7 ..."
    # generate makefile_darep for the solver
    ${RUNNINGPROJECT}/${DAREPDIRNAME}/bin/solvermakefile.pl -s ${SOLVERNAME} input${SCEEXT}.xml
    # clean current project
    cd ${RUNNINGSOLVERDIR} 
    echo "Cleaning ..."
    make -j 4 -f "makefile${MKEXTDAREP}" clean
    # resave
    ${RUNNINGPROJECT}/${DAREPDIRNAME}/bin/resaveproject.bash
    
    # 8. split the resulting composed model cpp file:
    #    you can skip this step if the resulting composed model cpp file is not so big file
    echo "step 8 ..."
    if [ "${SPLITRJ}" == "true" ]; then
        ${RUNNINGPROJECT}/${DAREPDIRNAME}/bin/splitrj.bash "${COMPOSEDMODELNAME}"
        # clean composed model
        cd "${RUNNINGPROJECT}/Composed/${COMPOSEDMODELNAME}"
        make -j 4 -f "makefile${MKEXT}" clean
    fi

    # 9. generate DAREP lib:
    echo "step 9 ..."
    echo "Generating darep library ..."
    cd ${RUNNINGPROJECT}/${DAREPDIRNAME}/${DAREPCPPDIRNAME}
    make clean
    make opt
    make

   # 10. generate the solver, compiling all the models, using:
    #       - gui command resave, or
    #       - by command line, with the commands:
    #             make opt (makefile is generated at step 7):
    echo "step 10 ..."
    # move into the running solver
    RUNNINGSOLVERDIR="${RUNNINGPROJECT}/Solver/${SOLVERNAME}"
    cd ${RUNNINGSOLVERDIR} 
    echo "Solver simulator: ${RUNNINGSOLVERDIR}"
    echo "Generating ..."
    make -j 4 -f "makefile${MKEXT}" opt
    
    # 11.  run the experiment(s), using:
    #        - the executable generated at step 9. with the experiment(s) corresponding to the setting of n and delta, e.g., n=1000, delta=999.
    #        - a batch file defined in batches directory:
    echo "step 11 ..."
    # in the batch make is disabled (simulator already generated at step 10)
    BATCH="${RUNNINGPROJECT}/${BATCHESDIRNAME}/${BATCHNAME}"
    # before running, sets the values of EXPS,BATCHES in the batch script
    setvarf "${BATCH}" EXPS BATCHES
    echo "${BATCH} ${MKEXT} ${SIMEXT}"
    eval ${BATCH} ${MKEXT} ${SIMEXT}

    # 12. if a copy of the original project has been used, then copy the results from the solver of the copied project to the solver of the original project (notice that below path ${DAREP} is referred to the original project):
    echo "step 12 ..."
    if [ "${MKRUNCOPY}" == "true" ]; then # used copy
        ${DAREP}/bin/getresultsfromrun.bash -p "${COPYEDPROJECTNAME}" -s "${SOLVERNAME}" 
    fi
    
    # original dir
    cd "$MYDIR"
}


# assign current value to all input variables of the input list $2 found in input file $1
# $1: file path
# $2: space separed variable names
setvarf() {
    local FILE="$1"
    local VARS="${@:2}"
    for var in ${VARS}
    do
        varvalue=${!var}
        echo "$var=$varvalue"
        perl -p -i".bk" -e "s/^\s*${var}\s*=.+/$var=$varvalue/g;" ${FILE}
    done
    
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
