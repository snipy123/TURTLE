QMLIBS = \
	../../../lib/QM/libQM.a \
	../../../lib/Container/libContainer.a \
	../../../lib/Math/libMath.a \
	../../common/libCommon.a \
	../../../../m4/libdiesel.a

STDLIBS = -lfl

APP = diag

INCS += -I/usr/include

-include ../../../Makefile.conf
include ../../../Makefile.common


main.o:	main.cc $(QMLIBS) *.h Compiled.h ../../../Configured.h

$(APP): 	$(QMLIBS) $(OBJECTS) main.o
	$(LD) $(LDFLAGS) -o $@ main.o $(OBJECTS) $(QMLIBS) $(STDLIBS)




