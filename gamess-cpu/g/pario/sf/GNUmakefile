# GNU make file for Shared Files library
#
# Jarek Nieplocha, Aug  1 1996
#

 LIB_DISTRIB = ../../lib
     LIBRARY = libpario.a
LIBRARY_SHARED= libpario.so
 LIB_TARGETS = *.x *.p
         OBJ = sf_fortran.o shared.files.o
     HEADERS = sf.h sf.fh
INCDIR = ../../include
LIB_INCLUDES = -I$(INCDIR)


ifndef OLD_GA
include ../../armci/config/makecoms.h
endif
include ../makefile.h
include ../../config/makefile.h
include ../../config/makelib.h

COPT=-g
FOPT=-g
# a rule to build excutables: the filetype of an executable must be .x
# for example, foo.x corresponds to either foo.f or foo.F or foo.c
#
%.x : %.o $(FULL_LIBRARY_PATH)  $(EXTRA)
	if [ -f $(basename $@).c ]; then\
		$(LINK.c) $(CLDOPT) -o $@ $< $(FULL_LIBRARY_PATH) $(LIBS) $(CLIBS);\
	else\
		$(LINK.f) $(FOPT_REN) $(FLDOPT) -o $@ $< $(FULL_LIBRARY_PATH) $(LIBS) $(FLIBS);\
	fi

# *.p file is required for tcgmsg `parallel' command to run your program
%.p:
	echo "`whoami` `hostname` 4 `pwd`/$* ." > $@

$(patsubst %,$(FULL_LIBRARY_PATH)(%),shared.files.o): sf.h coms.h
$(patsubst %,$(FULL_LIBRARY_PATH)(%),fortran.o):      sf.h
