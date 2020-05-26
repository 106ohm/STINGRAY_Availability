
# get min and max for T0 from traces
# comma separator is defined in minmax.awk, otherwise use option "-F,"
awk -v name="T0" -v nofm=289 -f ../../awk/minmax.awk Results_results.csv Results_Exp9_N10000_s187704482_bradipo_ascii.csv

# get mean values for T0 from traces
# comma separator is defined in mean.awk, otherwise use option "-F,"
awk -v name="T0" -v nofm=289 -f ../../awk/mean.awk Results_results.csv Results_Exp9_N10000_s187704482_bradipo_ascii.csv

