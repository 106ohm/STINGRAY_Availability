plot "<cat Results_results.csv| grep 'Experiment 1,Mean,T0,' | awk -F, '{print $6}'",\
     "<cat Results_results.csv| grep 'Experiment 1,Mean,DP,' | awk -F, '{print $6}'",\
     "<cat Results_results.csv| grep 'Experiment 1,Mean,T_0,' | awk -F, '{print $6}'",\
     "<cat Results_results.csv| grep 'Experiment 1,Mean,HOn_0,' | awk -F, '{print $6}'"
