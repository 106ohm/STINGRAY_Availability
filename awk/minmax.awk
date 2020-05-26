# get min and max values from traces
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
#   awk -v name="T0" -v nofm=289 -f ../../awk/minmax.awk Results_results.csv Results_Exp9_N10000_s187704482_bradipo_ascii.csv
#
BEGIN{
    FS = ","
    min=100
    max=-100
    pattern="^Experiment 1,Mean," name
}
FNR==NR && /^Experiment 1,Result Type,Name,Start Time,End Time,Mean,/ {
    base=FNR; next
}
FNR==NR && $0~pattern && foundn!=1 {
    pvidnumber=FNR-base-1; foundn=1; next
}
FNR!=NR && $1>=pvidnumber && $1<=pvidnumber+nofm-1 {
    if($2<min){min=$2}else if($2>max){max=$2}; next
}
END{
    printf"min:%s\nmax:%s\n", min, max
}
