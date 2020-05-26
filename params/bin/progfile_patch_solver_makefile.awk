
/USERDEFLIBNAME=/ && !/# fixed/ {
    n=split($0,libname," ")
    lflagsd=""
    for(i=2; i<=n; i++ ) {
        flagsd=flagsd " "libname[i]"_debug"
        flagst=flagst " "libname[i]"_trace"
    }
    printf("%s # fixed\nUSERDEFLIBNAME_debug=%s\nUSERDEFLIBNAME_trace=%s\n", $0, flagsd, flagst)
    next
}

/TARGET=/ && $0!~/-l\$\(SIMLIB_debug\)/ && $0!~/-l\$\(SIMLIB_trace\)/ {
    gsub(/\$\(USERDEFLIBNAME\) \$\(PROJECTLIBS\) \$\(USERDEFLIBNAME\)/,"$(PROJECTLIBS) $(USERDEFLIBNAME)")
    print
    next
}

/TARGET=/ && /-l\$\(SIMLIB_debug\)/ {
    gsub(/\$\(USERDEFLIBNAME\) \$\(PROJECTLIBS_debug\) \$\(USERDEFLIBNAME\)/,"$(PROJECTLIBS_debug) $(USERDEFLIBNAME_debug)")
    print
    next
}

/TARGET=/ && /-l\$\(SIMLIB_trace\)/ {
    gsub(/\$\(USERDEFLIBNAME\) \$\(PROJECTLIBS_debug\) \$\(USERDEFLIBNAME\)/,"$(PROJECTLIBS_debug) $(USERDEFLIBNAME_trace)")
    print
    next
}
{print}
