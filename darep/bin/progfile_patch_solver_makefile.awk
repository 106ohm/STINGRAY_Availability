
/USERDEFLIBNAME=/ && !/# fixed/ {
    printf("USERDEFLIBNAME= -ldarep # fixed\nUSERDEFLIBNAME_debug= -ldarep_debug\nUSERDEFLIBNAME_trace= -ldarep_trace\n")
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
