
##############################################################################
#
# to generate user defined libraries: darep and darep_debug
#
##############################################################################

# the library dir name
DAREPLIBDIRNAME=darep
# the library name
DAREPLIBNAME=darep

LIB_FILES = $(DAREPLIBNAME).cpp

OBJS=$(LIB_FILES:%.cpp=%.o)   

#include common Makefile for default targets
include ../../Makefile.project
include $(MOBIUSROOT)/Cpp/BaseClasses/Makefile.common

#ifeq ($(UNAME), Darwin)
#	INCLUDE_DIR = -I/usr/local/lib/ParadisEO/include/paradiseo/eo -I/sw/lib/gcc4.9/lib/gcc/x86_64-apple-darwin14.1.0/4.9.2/include
#       override macosx_CC=/sw/bin/g++-fsf-4.9
#        override macosx_OCFLAGS=-v -Wall -Wno-write-strings -Wno-missing-declarations -m64 -std=c++11 -Wno-reorder -Wno-c++11-compat-deprecated-writable-strings -I../../../ -I/sw/include
#        override macosx_LINK_FLAGS=-std=c++11 -L/sw/lib
#else
#       INCLUDE_DIR     = -I/opt/local/include/lpsolve
#       override linux_CC=g++-4.8
#        override linux_OCFLAGS=-v -Wall -m64 -std=c++11 -I../../../
#        override linux_LINK_FLAGS=
#endif


#print_vars:
#	echo $(PLATFORM)$(FORCE_ARCH)$(TYPE)

#$(info INCLUDE_DIR="$(USERINCLUDE)")
#$(info INCLUDE_DIR="$(INCLUDE_DIR)")

all: opt
opt: $(ROOTDIR)/lib/$(PLATFORM)$(FORCE_ARCH)/lib$(DAREPLIBNAME).a
normal debug trace: $(ROOTDIR)/lib/$(PLATFORM)$(FORCE_ARCH)/lib$(DAREPLIBNAME)_debug.a

$(ROOTDIR)/lib/$(PLATFORM)$(FORCE_ARCH)/lib$(DAREPLIBNAME).a: FORCE
	$(MAKE) lib TARGET=lib$(DAREPLIBNAME).a OBJS="$(OBJS)" USERINCLUDE="$(USERINCLUDE) $(INCLUDE_DIR)" TYPE="" ROOTLIBDIR="."

$(ROOTDIR)/lib/$(PLATFORM)$(FORCE_ARCH)/lib$(DAREPLIBNAME)_debug.a: FORCE
	$(MAKE) lib TARGET=lib$(DAREPLIBNAME)_debug.a OBJS="$(OBJS)" USERINCLUDE="$(USERINCLUDE) $(INCLUDE_DIR)" TYPE="_debug" ROOTLIBDIR="."

clean_sub_dirs:


##########################################################################
#
# to generate test program
#
##########################################################################

TEST_FILE_NAME=test
# darep compiler flags
CFLAG_TEST= -DTEST
#CFLAG_OPT= -m64 -O0 -ggdb -fno-omit-frame-pointer
#CFLAG_OPT= -O3 -fprefetch-loop-arrays --param simultaneous-prefetches=8
#CFLAG_OPT= -Ofast
CFLAG_OPT= -O3
CFLAG_DEBUG= -DDEBUG -g
CFLAGS= -std=c++11 -msse4.2 -mtune=native -DMOBIUS_LITTLE_ENDIAN -Wall -Wno-\#pragma-messages -Wno-write-strings -Wno-missing-declarations -Wno-reorder -Wno-c++11-compat-deprecated-writable-strings
CFLAGS+= $(DAREP_INCLUDE) $(COMMON_INCLUDE) $(OMP_INCLUDE)
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

# use CC mode
test: TYPE="" 
test: $(TEST_FILE_NAME).cpp $(LIB_FILES)
	$(CC) $(TEST_FILE_NAME).cpp $(CFLAG_OPT) $(CFLAG_TEST) $(CFLAGS) $(LIB_FILES) $(LFLAGS) -o $(TEST_FILE_NAME)$(TYPE) 

# use CC debug mode
test_debug: TYPE="_debug" 
test_debug: $(TEST_FILE_NAME).cpp $(LIB_FILES)
	$(CC) $(TEST_FILE_NAME).cpp $(CFLAG_DEBUG) $(CFLAG_TEST) $(CFLAGS) $(LIB_FILES) $(LFLAGS) -o $(TEST_FILE_NAME)$(TYPE)

clean: cleant
cleant:
	rm -rf $(TEST_FILE_NAME) $(TEST_FILE_NAME)_debug $(TEST_FILE_NAME)*.dSYM
