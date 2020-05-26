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

# replace JBR with DAREP in all bash files
find . -name "*\.bash" -type f -exec grep -l 'JBR' {} \; -exec perl -p -i$BAK -e 's/JBR/DAREP/g;' {} \;

# replace JBR with DAREP in all awk files
find . -name "*\.awk" -type f -exec grep -l 'JBR' {} \; -exec perl -p -i$BAK -e 's/JBR/DAREP/g;' {} \;

# replace JBR with DAREP in all xquery files
find . -name "*\.xquery" -type f -exec grep -l 'JBR' {} \; -exec perl -p -i$BAK -e 's/JBR/DAREP/g;' {} \;

# replace JBR with DAREP in all xml files
find . -name "*\.xml" -type f -exec grep -l 'JBR' {} \; -exec perl -p -i$BAK -e 's/JBR/DAREP/g;' {} \;

# replace JBR with DAREP in all san files
find . -name "*\.san" -type f -exec grep -l 'JBR' {} \; -exec perl -p -i$BAK -e 's/JBR/DAREP/g;' {} \;

# replace JBR with DAREP in all pvm files
find . -name "*\.pvm" -type f -exec grep -l 'JBR' {} \; -exec perl -p -i$BAK -e 's/JBR/DAREP/g;' {} \;

# replace JBR with DAREP in all prj files
find . -name "*\.prj" -type f -exec grep -l 'JBR' {} \; -exec perl -p -i$BAK -e 's/JBR/DAREP/g;' {} \;

# replace JBR with DAREP in all cpp files
find . -name "*\.cpp" -type f -exec grep -l 'JBR' {} \; -exec perl -p -i$BAK -e 's/JBR/DAREP/g;' {} \;

# replace JBR with DAREP in all h files
find . -name "*\.h" -type f -exec grep -l 'JBR' {} \; -exec perl -p -i$BAK -e 's/JBR/DAREP/g;' {} \;

# replace jbrep with darep in all files
find . -type f \( -name "*" ! -name "replace-JBR-edit-perl.sh*" \) -exec grep -l 'jbrep' {} \; -exec perl -p -i$BAK -e 's/jbrep/darep/g;' {} \;

# replace jbr with darep in all files
find . -type f \( -name "*" ! -name "replace-JBR-edit-perl.sh*" \) -exec grep -l 'jbr' {} \; -exec perl -p -i$BAK -e 's/jbr/darep/g;' {} \;
