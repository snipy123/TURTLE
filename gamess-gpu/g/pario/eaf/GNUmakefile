#$Id: GNUmakefile,v 1.1.1.3 2007-10-30 10:14:10 jmht Exp $

          OBJ = eaf.o eaf_f2c.o
      LIBRARY = libpario.a
LIBRARY_SHARED= libpario.so
  LIB_DISTRIB = ../../lib
      HEADERS = eaf.fh eaf.h
  LIB_DEFINES = -DEAF_STATS
  LIB_TARGETS = test.x
       INCDIR = ../../include
 LIB_INCLUDES = -I$(INCDIR)

ifndef OLD_GA
include ../../armci/config/makecoms.h
endif
include ../makefile.h
include ../../config/makefile.h
include ../../config/makelib.h

test.x:	test.o $(FULL_LIBRARY_PATH)
	$(LINK.f) $(FLDOPT) -o $@ test.o $(FULL_LIBRARY_PATH) $(LIBS) $(FLIBS)
