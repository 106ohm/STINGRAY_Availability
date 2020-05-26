#!//bin/bash
##################

# Substitute a word or whatever, editing in-place (and keeping a .bak file)
# 
# perl -i.bak -p -e 's/xyz\.rice\.edu/abc.rice.edu/ig' *.html

# remove hex char 00A0
# perl -i_20051007 -p -e 's/\xA0//g' *.html

# Substitute ``a.bondavalli@dsi.unifi.it'' with ``bondavalli@unifi.it'' in all html files
# find . -name "*\.html" -type f -exec grep -l -P 'a.bondavalli@dsi.unifi.it' {} \; -exec perl -p -i$BAK -e 's/a\.bondavalli\@dsi\.unifi\.it/bondavalli\@unifi\.it/g;' {} \;

# keeping a .bak file (only for matched files)
BAK=`date +%y%m%d%H%M`
BAK="_$BAK"

# add SIMTYPE to all batch files
#
# uncomment all below 

find . -name "batch_*\.sh" -type f -exec grep -l 'sh' {} \; -exec perl -p -i$BAK -e 's/########### MAIN CODE ##############/\n# Simulation Type (1 = Terminating[default] 0 = Steady State)\nSIMTYPE="0"\n\n########### MAIN CODE ##############/g;' {} \;

find . -name "batch_*\.sh" -type f -exec grep -l 'sh' {} \; -exec perl -p -i$BAK -e 's/-N\${BATCHES}/-N\${BATCHES} -t\${SIMTYPE}/g;' {} \;
