#doc  Makefile settings for Global Array build on commodity clusters
#doc  with Intel64 processors using the Intel compiler 13 and Intel MPI (13.1.0)
#doc
#doc adds exception for helfey
#doc
#doc  Options:
#doc  mpiwrap - use mpif90 etc to compile and do not manually set path to libs & includes
#doc  infiniband - build for INFINIBAND switch. Default library locations:
#doc              libvapi.a:     /opt/ibgd/driver/infinihost/lib64
#doc              lib*mpi.a:     /opt/MPI/intel8/mvapich/0.9.5/lib 
#doc
#doc  mkl - build against Intel MKL library - NOT AVAILABLE WITH I8
#doc  scalapack - link to external scalapack library - NOT AVAILABLE WITH I8
#doc  mkl_scalapack - build with Intel MKL BLAS and ScaLAPACK
#doc  newscf - build distributed scf driver - NOT AVAILABLE WITH i8
#doc  vdw - use vanderwaals terms
#doc  datain - read input from a file named "datain" as opposed to stdin
#doc  debug - add debugging information to the executable
#
# DEFAULT OPTIONS
#dopt ga mpi ci peigs drf zora vb vdw nbo dl-find mpiwrap mkl_scalapack infiniband i8
#opt debug datain masscf 
#
# ================ M4 Processing options
#

# Machine-specific options 
MACHINE_KEY=G
MACHOPT=linux,pclinux,littleendian,cio,unix,upck-equiv,opteron,helfey

IXOR32=ieor($$1,$$2)
IOR64=ior($$1,$$2)
IXOR64=ieor($$1,$$2)

#--#if mkl_scalapack#
# 
# Using both the MKL BLAS snd BLACS/ScaLAPACK
SCALAPACK_HOME=${SURFSARA_MKL_ROOT}
SCALAPACK_LIB=-L$(SURFSARA_MKL_LIB) $(SURFSARA_MKL_LIB)/libmkl_blas95_ilp64.a -lmkl_scalapack_ilp64 -lmkl_intel_ilp64 -lmkl_sequential -lmkl_core -lmkl_blacs_intelmpi_ilp64 -lpthread -lm
BLASOPT=,blas
#
# #--#else#
#
#---#if mkl#
# -lguide is used to pick the threading library for dynamic linking
LIBBLAS= -L$(SURFSARA_MKL_LIB) $(SURFSARA_MKL_LIB)/libmkl_blas95_lp64.a -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lpthread -lm
BLASOPT=,blas
#---#endif mkl#
#
#---#if scalapack#
# include ScaLAPACK in the build
SPCKDIR=/usr/local/lib64
SCALAPACK_LIB=${SPCKDIR}/libscalapack.a ${SPCKDIR}/blacsF77init_MPI-LINUX-0.a ${SPCKDIR}/blacs_MPI-LINUX-0.a
#---#endif scalapack#
#--#endif mkl_scalapack#

#--#if mpiwrap#
MPI_INCLUDE=
MPI_LIB=
LIBMPI =
# IC_INCLUDE is the include required
# to build against the interconnect
IC_INCLUDE=
LIB_EXTRA=-L/usr/lib64 -libverbs
#--#else#
MPI_INCLUDE=/usr/local/mpich-INTEL864/include
MPI_LIB=/usr/local/mpich-INTEL864/lib 
LIBMPI =  -L$(MPI_LIB) -lmpich -lfmpich
#---#if myrinet#
# MPI and GM Locations for MYRINET switch
GM_INCLUDE=/opt/gm/2.0.19/include
IC_INCLUDE=-I${GM_INCLUDE}
GM_LIB=/opt/gm/2.0.19/lib64
LIB_EXTRA=-L$(GM_LIB) -lgm
#
#---#elseif infiniband openib#
#
# MPI Locations for INFINIBAND switch
IB_INCLUDE=/usr/include/infiniband
IC_INCLUDE=-I${IB_INCLUDE}
IB_LIB=/usr/lib64
LIB_EXTRA= -L${IB_LIB} -lvapi -libverbs
#---#endif#
#--#endif mpiwrap#


# The following two GA-flags are actually used in other (non-GA) places
# as well. So just set the bastards.
GA_TARGET=LINUX64
GA_F77_DEFS = -traditional
# PEIGS definitions
PEIGS_TARGET_CPU_PAR=x86_64

#--#if ga#
# GA definitions & MPI and Switch library locations
# Change below to compile the GA's with a different c-compiler
#GA_CC = gcc
#
#---#if myrinet#
#
GA_VERSION_PAR= GA_VERSION=SHMEM ARMCI_NETWORK=GM GM_INCLUDE=${GM_INCLUDE} GM_LIB=${GM_LIB} MPI_INCLUDE=${MPI_INCLUDE} MPI_LIB=${MPI_LIB} LIBMPI=" ${LIBMPI} "
#
#---#elseif infiniband openib#
#
GA_VERSION_PAR= GA_VERSION=SHMEM ARMCI_NETWORK=OPENIB IB_INCLUDE=${IB_INCLUDE} MPI_INCLUDE=${MPI_INCLUDE} MPI_LIB=${MPI_LIB} LIBMPI=" ${LIBMPI} "
#
#---#else#
#
# Default sockets version
GA_VERSION_PAR= GA_VERSION=SHMEM MPI_INCLUDE=${MPI_INCLUDE} MPI_LIB=${MPI_LIB} LIBMPI=" ${LIBMPI} "
LIB_EXTRA=-lpthread
#
#---#endif#
#--#endif ga#


#
# ===============  Compiler Options
#
#--#if mpiwrap#
FC = mpiifort
LD =  mpiifort
FC90 = mpiifort
CC = mpiicc
CXX= mpiicpc
FINC =-I$(SURFSARA_MKL_INCLUDE)/intel64/ilp64 -I$(SURFSARA_MKL_INCLUDE)
#--#else#
FC = ifort 
LD = ifort 
FC90 = ifort
CC=  icc -no-gcc
CXX = icc
FINC = -I${MPI_INCLUDE} ${IC_INCLUDE}
#--#endif#

#--#if i8#
FFLAGSI8 = -i8
CFLAGSI8 = -DLONG_INTEGER -DEXT_INT
# Added linux64 to get tst1s extracted from direct.m
# jmht - don't think this is actually needed, but have left it.
I8_M4_OPT=,i8,linux64
#--#else#
FFLAGSI8=
CFLAGSI8= -DSTD_INT
I8_M4_OPT=,i8drct,64bitpointers
#--#endif i8#

FFLAGSTMP = -c ${FFLAGSI8} ${FINC}
# -std=c99 - might need this if int64_t can't be found
CFLAGSTMP = -c ${CFLAGSI8}  ${FINC}

# Taken the load map generation out. With the intel 11.x compilers if the file
# load.map does not exist the loader skips to do something fancy to the next file on
# the line. Typically that means that mains.o gets corrupted after which the link
# stage fatally fails. If you touch load.map before attempting linking everything
# is fine!
#LDFLAGSTMP= -Wl,-Map load.map ${LDSCORE}
LDFLAGSTMP= ${LDSCORE}


#--#if debug#
FFLAGSV  = ${FFLAGSTMP} -g
FFLAGSS  = ${FFLAGSTMP} -g
FFLAGSN  = ${FFLAGSTMP} -g
FFLAGSN0 =  ${FFLAGSTMP} -g 
CFLAGS   = ${CFLAGSTMP}  -g
LDFLAGS  = ${LDFLAGSTMP} -g 
#--#else# 
FFLAGSV  = ${FFLAGSTMP} -O3 -m64 -xAVX -mp1 -warn nousage -unroll -ip -ftz -vec-report0 -mcmodel=medium
FFLAGSS  = ${FFLAGSTMP} -O2 -m64 -xAVX -mp1 -warn nousage -ip -ftz -vec-report0 -mcmodel=medium
FFLAGSN  = ${FFLAGSTMP} -O1 -m64 -xAVX -mp1 -warn nousage -ip -ftz -vec-report0 -mcmodel=medium
FFLAGSN0 = ${FFLAGSTMP} -O0 -m64 -xAVX -mp1 -warn nousage -ftz -mcmodel=medium
CFLAGS   = ${CFLAGSTMP} -mp1 -m64 -mcmodel=medium -xAVX
LDFLAGS  = ${LDFLAGSTMP} -mcmodel=medium
#--#endif#


# Put the link line together
BL_LIB = ${SCALAPACK_LIB} ${LIBBLAS} ${LIBMPI} ${LIB_EXTRA}

# M4 Options 
OPTIONS=${MACHOPT}${I8_M4_OPT}${BLASOPT}

#
# ===============  Additional Files 
#
#--#if i8#
# jmht - don't think this is actually needed, but have left it.
EXTRAI8= tst1s.o helfey.o gethes.o
EXTRA= $(EXTRAI8)
#--#else#
EXTRAI8=
EXTRA=gethes.o helfey.o
#--#endif#

EXTRA_MP2= mkmakw.o mpmakw.o umpe3a.o umpe3b.o aprq34d.o mcdab_ga.o
EXTRA_DFT = jkint_dft.o jkder_dft.o

#
# ===============  Compiler Exceptions
#
# jmht - don't think this is actually needed, but have left it.
tst1s.o:	direct.m
	cat ../utilities/gener.m direct.m | $(M4) -DGEN_EXTRACTFILE=tst1s $(M4OPTS) > tst1s.f
	$(FC) $(FFLAGSN) tst1s.f 

gethes.o:	casb.m
	cat ../utilities/gener.m casb.m | $(M4) -DGEN_EXTRACTFILE=gethes $(M4OPTS) > gethes.f
	$(FC) $(FFLAGSN) gethes.f

rpa.o:	rpa.f
	$(FC) $(FFLAGSN) $*.f

mrdci5.o:	mrdci5.f
	$(FC) $(FFLAGSN) $*.f

helfey.o:       drv1e.m
	cat ../utilities/gener.m drv1e.m | $(M4) -DGEN_EXTRACTFILE=helfey $(M4OPTS) > helfey.f
	$(FC) $(FFLAGSN) helfey.f

mkmakw.o:	drvmp.m
	cat ../utilities/gener.m drvmp.m | $(M4) -DGEN_EXTRACTFILE=mkmakw $(M4OPTS) > mkmakw.f
	$(FC) $(FFLAGSS) mkmakw.f

mpmakw.o:	secmp2.m
	cat ../utilities/gener.m secmp2.m | $(M4) -DGEN_EXTRACTFILE=mpmakw $(M4OPTS) > mpmakw.f
	$(FC) $(FFLAGSS) mpmakw.f

umpe3a.o:	mp3.m
	cat ../utilities/gener.m mp3.m | $(M4) -DGEN_EXTRACTFILE=umpe3a $(M4OPTS) > umpe3a.f
	$(FC) $(FFLAGSS) umpe3a.f

umpe3b.o:	mp3.m
	cat ../utilities/gener.m mp3.m | $(M4) -DGEN_EXTRACTFILE=umpe3b $(M4OPTS) > umpe3b.f
	$(FC) $(FFLAGSS) umpe3b.f

check0a.o:	newmrd5.m
	cat ../utilities/gener.m newmrd5.m | $(M4) -DGEN_EXTRACTFILE=check0a $(M4OPTS) > check0a.f
	$(FC) $(FFLAGSN) check0a.f
aprq34d.o:	mp2_parallel.m
	cat ../utilities/gener.m mp2_parallel.m | $(M4) -DGEN_EXTRACTFILE=aprq34d $(M4OPTS) > aprq34d.f
	$(FC) $(FFLAGSS) aprq34d.f

mcdab_ga.o:	mp2_parallel.m
	cat ../utilities/gener.m mp2_parallel.m | $(M4) -DGEN_EXTRACTFILE=mcdab_ga $(M4OPTS) > mcdab_ga.f
	$(FC) $(FFLAGSS) mcdab_ga.f

#
#  ========== DFT Exceptions ===============
#
jkint_dft.o:	integ2e.m
	cat ../utilities/gener.m  integ2e.m | $(M4) -DGEN_EXTRACTFILE=jkint_dft $(M4OPTS) $(SNGL) > jkint_dft.f
	$(FC) $(FFLAGSN) jkint_dft.f
#
jkder_dft.o:	deriv2e.m
	cat ../utilities/gener.m  deriv2e.m | $(M4) -DGEN_EXTRACTFILE=jkder_dft $(M4OPTS) $(SNGL) > jkder_dft.f
	$(FC) $(FFLAGSN) jkder_dft.f

