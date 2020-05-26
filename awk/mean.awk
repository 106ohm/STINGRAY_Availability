# get mean values from traces
#
# input vars:
# name: name of PV
# nofm: number of measures for each PV
#
# input files:
# csv results file obtained with gui
# csv ascii file obtained with mobius command line option -a 
#
# Usage:
#   awk -v name="T0" -v nofm=289 -f ../../awk/mean.awk Results_results.csv Results_Exp9_N10000_s187704482_bradipo_ascii.csv
#
BEGIN{
#    printf "PV name: %s\n", name
#    printf "number of measures for each PV: %s\n", nofm
    FS = ","
    pattern="^Experiment 1,Mean," name ","
}
FNR==NR && /^Experiment 1,Result Type,Name,Start Time,End Time,Mean,/ {
    base=FNR; next
}
FNR==NR && $0~pattern && foundn!=1 {
    pvidnumber=FNR-base-1; foundn=1; next
}
FNR!=NR && $1>=pvidnumber && $1<=pvidnumber+nofm-1 { # each batch on different column
    mvalues[$1]=mvalues[$1] " " $2; next
}
END{ # sort by key (pv id number)
# [ https://stackoverflow.com/questions/2458346/sort-an-associative-array-in-awk ]
    # copy indices
    j = 1
    for (i in mvalues) {
        ksorted[j] = i+0    # index value becomes element value as number
        j++
    }
    n = asort(ksorted)    # index values are now sorted
    for (i=1; i<=n; i++){
        print mvalues[ksorted[i]] # Access original array via sorted indices
    }
}
