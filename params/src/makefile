
##############################################################################
#
# to generate user defined libraries: params and params_debug
#
##############################################################################

# the library dir name
PARAMSLIBDIRNAME=params
# the library name
PARAMSLIBNAME=params

# the darep library dir name
DAREPLIBDIRNAME=darep
# the darep library name
DAREPLIBNAME=darep
# the darep src library path
DAREPSRC=$(ROOTDIR)/$(DAREPLIBDIRNAME)/c++
# source cpp file names of darep
DAREPLIB_FILES = $(DAREPLIBNAME).cpp

LIB_FILES = $(PARAMSLIBNAME).cpp

# list of files to compile for params, darep, control, state and matpower
OBJS=$(LIB_FILES:%.cpp=%.o) $(DAREPLIB_FILES:%.cpp=%.o) 

#include common Makefile for default targets
include ../../Makefile.project
include $(MOBIUSROOT)/Cpp/BaseClasses/Makefile.common

#$(info OBJS="$(OBJS)")
#$(info OBJECTDIR="$(OBJECTDIR)")
#$(info LIB_FILES="$(LIB_FILES)")

#print_vars:
#	echo $(PLATFORM)$(FORCE_ARCH)$(TYPE)

all: opt
opt: $(ROOTDIR)/lib/$(PLATFORM)$(FORCE_ARCH)/lib$(PARAMSLIBNAME).a
normal debug trace: $(ROOTDIR)/lib/$(PLATFORM)$(FORCE_ARCH)/lib$(PARAMSLIBNAME)_debug.a

$(ROOTDIR)/lib/$(PLATFORM)$(FORCE_ARCH)/lib$(PARAMSLIBNAME).a: FORCE
	$(MAKE) lib TARGET=lib$(PARAMSLIBNAME).a OBJS="$(OBJS)" USERINCLUDE="$(USERINCLUDE) $(INCLUDE_DIR)" TYPE="" ROOTLIBDIR="."

$(ROOTDIR)/lib/$(PLATFORM)$(FORCE_ARCH)/lib$(PARAMSLIBNAME)_debug.a: FORCE
	$(MAKE) lib TARGET=lib$(PARAMSLIBNAME)_debug.a OBJS="$(OBJS)" USERINCLUDE="$(USERINCLUDE) $(INCLUDE_DIR)" TYPE="_debug" ROOTLIBDIR="."

clean_sub_dirs:


# build darep cpp and c files
$(OBJECTDIR)/%.o: $(DAREPSRC)/%.cpp
	$(CC) $(CXXFLAGS) $(OPT) $(FORCE_ARCH) -MMD -D MOBIUSROOT=\"$(MOBIUSROOT)\" $(INCLUDES) $(USERINCLUDE) -c $(DAREPSRC)/$*.cpp -o $@


##########################################################################
#
# to generate test program
#
##########################################################################

# static darep lib basename path
DAREPLIB=$(ROOTDIR)/lib/$(PLATFORM)$(FORCE_ARCH)/lib$(DAREPLIBNAME)

TEST_FILE_NAME=test
# control compiler flags
CFLAG_TEST= -DTEST -DSANFUNC -DDAREP  
#CFLAG_OPT= -m64 -O0 -ggdb -fno-omit-frame-pointer
#CFLAG_OPT= -O3 -fprefetch-loop-arrays --param simultaneous-prefetches=8
#CFLAG_OPT= -Ofast
CFLAG_OPT= -O3
CFLAG_DEBUG= -DDEBUG -g
CFLAGS= -std=c++11 -msse4.2 -mtune=native -DMOBIUS_LITTLE_ENDIAN -Wall -Wno-\#pragma-messages -Wno-write-strings -Wno-missing-declarations -Wno-reorder -Wno-c++11-compat-deprecated-writable-strings
#CFLAGS+= $(OCFLAGS_PROJ) $(USERINCLUDE)
CFLAGS+= $(PARAMS_INCLUDE) $(DAREP_INCLUDE) $(COMMON_INCLUDE)

LFLAGS=
LFLAGS+= $(DAREP_LIB) $(COMMON_LIB)

# set final flags for each os release
UNAME=$(shell uname -s)
ifeq ($(UNAME), Darwin) # macosx
	CC= $(macosx_CC)	
	CFLAGS+= -DMAC
else ifeq ($(UNAME), Linux) # linux os
	CC=$(linux_CC) 
else # default: macosx
	CC= $(macosx_CC)	
	CFLAGS+= -DMAC
endif

test: TYPE=""
test: $(TEST_FILE_NAME).cpp $(LIB_FILES) $(DAREPSRC)/$(DAREPLIB_FILES) 
	$(CC) $(TEST_FILE_NAME).cpp $(CFLAG_OPT) $(CFLAG_TEST) $(CFLAGS) $(INCLUDES) $(USERINCLUDE) $(LIB_FILES) $(DAREPSRC)/$(DAREPLIB_FILES) $(LFLAGS) -o $(TEST_FILE_NAME)$(TYPE)

test_debug: TYPE="_debug"
test_debug: $(TEST_FILE_NAME).cpp $(LIB_FILES) $(DAREPSRC)/$(DAREPLIB_FILES) 
	$(CC) $(TEST_FILE_NAME).cpp $(CFLAG_DEBUG) $(CFLAG_TEST) $(CFLAGS) $(INCLUDES) $(USERINCLUDE) $(LIB_FILES) $(DAREPSRC)/$(DAREPLIB_FILES) $(LFLAGS) -o $(TEST_FILE_NAME)$(TYPE)

clean: cleant
cleant:
	rm -rf $(TEST_FILE_NAME) $(TEST_FILE_NAME)_debug $(TEST_FILE_NAME).dSYM
