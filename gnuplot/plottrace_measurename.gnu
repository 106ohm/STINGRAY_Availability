#guiseed=31415 (seed for GUI)
#clseed=187704482 (seed for command line)

# get single measure for a given number of batches
# awk -v name="WTleDP_1" -F, 'BEGIN{pattern="^Experiment 1,Mean," name}FNR==NR && /^Experiment 1,Result Type,Name,Start Time,End Time,Mean,/{base=FNR; next} FNR==NR && $0~pattern && foundn!=1{pvidnumber=FNR-base-1; foundn=1; next}FNR!=NR && $1==pvidnumber{print $2; next}' Results_results.csv trace1.csv

# get single measure for a given number of batches, printing also measure number
# awk -v name="WTleDP_1" -F, 'BEGIN{pattern="^Experiment 1,Mean," name}FNR==NR && /^Experiment 1,Result Type,Name,Start Time,End Time,Mean,/{base=FNR; next} FNR==NR && $0~pattern && foundn!=1{pvidnumber=FNR-base-1; foundn=1; next}FNR!=NR && $1==pvidnumber{printf"%s: %s: %s\n", name, pvidnumber, $2; next}' Results_results.csv trace1.csv

# get range of measures
# awk -v name="T0" -v nofm=289 -F, 'BEGIN{pattern="^Experiment 1,Mean," name}FNR==NR && /^Experiment 1,Result Type,Name,Start Time,End Time,Mean,/{base=FNR; next} FNR==NR && $0~pattern && foundn!=1{pvidnumber=FNR-base-1; foundn=1; next}FNR!=NR && $1>=pvidnumber && $1<=pvidnumber+nofm-1{print $2; next}' Results_results.csv trace2.csv 

# get range of measures for a given number of batches, based on variable names
#
# batches=2
# measurename="T0"
# numberofmeasures=289
# plot "<awk -v name=".measurename." -v nofm=".numberofmeasures." -F, 'BEGIN{pattern=\"^Experiment 1,Mean,\" name}FNR==NR && /^Experiment 1,Result Type,Name,Start Time,End Time,Mean,/{base=FNR; next} FNR==NR && $0~pattern && foundn!=1{pvidnumber=FNR-base-1; foundn=1; next}FNR!=NR && $1>=pvidnumber && $1<=pvidnumber+nofm-1{print $2; next}' Results_results.csv trace2.csv"

# get range of measures for a given number of batches, based on variable names
#
batches=10
measurename1="T_0"
measurename2="T0"
measurename3="DP"
numberofmeasures=289
resultsfile="Results_results.csv"
tracefile="Results_Exp1_N".batches."_s187704482_cicala.local_ascii.csv"

set term wxt title 'my title' 0
plot for [i=1:batches] "<awk -v  name=".measurename1." -v nofm=".numberofmeasures." -F, -f ../../awk/mean.awk ".resultsfile." ".tracefile." " using i, \
     for [i=1:batches] "<awk -v name=".measurename2." -v nofm=".numberofmeasures." -F, -f ../../awk/mean.awk ".resultsfile." ".tracefile." " using i, \
     for [i=1:batches] "<awk -v name=".measurename3." -v nofm=".numberofmeasures." -F, -f ../../awk/mean.awk ".resultsfile." ".tracefile." " using i

print measurename
set term wxt title 'my title' 1
plot for [i=1:batches] "<awk -v name=".measurename." -v nofm=".numberofmeasures." -F, -f ../../awk/mean.awk ".resultsfile." ".tracefile." " using i