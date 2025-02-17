c
c  $Author: jvl $
c  $Date: 2014-09-15 17:31:14 +0200 (Mon, 15 Sep 2014) $
c  $Locker:  $
c  $Revision: 6296 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/vb/vbtran.m,v $
c  $State: Exp $
c  $Log: not supported by cvs2svn $
c  Revision 1.37  2007/09/25 10:35:51  jvl
c  Fixed pg_sndrcv (call to sendrecv which calls MPI_Sendrecv) because of
c  integer*8/integer*4 type mismatch (for big endians), which lead to
c  checksum error.
c  /marcin
c
c  Revision 1.36  2007/07/04 12:37:56  jvl
c  Introducing new VB switch - VBMO, first step to separate output file for molden.
c  Now, upon request, separate file with VB orbitals (with proper format) can be created,
c  called out.vbmo.<title_from_VBMO_switch>. Check vbin.m comment/GAMESS manual for more.
c  Major bugfixes of dimensions in makepsi0 subroutine:
c   - serial + CORE XX
c   - parallel + bigger basis set than 6-31g + CORE switch
c  Minor changes in igmem_alloc_inf names.
c  /marcin
c
c  Revision 1.35  2007/03/20 14:49:31  jvl
c  Pretty major overhaul of the VB code
c  say 50% is now dynamic using igmem_alloc and, oh wonder,
c  all the examples are still checking out OK, including a new resonating
c  super hybrid. (will follow)
c
c  Revision 1.34  2007/03/15 14:03:11  jvl
c  update super hybrid oprion in vb (ignore ao per atom)
c  added damping
c  clean up
c
c  Revision 1.33  2006/04/27 19:26:58  jvl
c  Upon finding that the orthogonalisations in VB are inconsistent
c  a cleanup was started, which is no way fnished.
c  natorb is doing all sort of non related stuff and makepsi0 calls natorb
c  which is stupid, also frozen core gradients, which are rather trivial
c  for VB should be properly added, etc. but we have to do some work again
c
c  Revision 1.32  2006/04/18 16:35:34  jvl
c  - added basis option to allow Vb to be run in anothr basis.
c  - cleaned up various bits of VB, like core partitioning
c  - adapted get1e
c
c  Revision 1.31  2006/01/13 17:56:48  jmht
c  Merging in changes from the release branch
c
c  Revision 1.30  2005/09/23 14:34:56  jmht
c  This checkin merges in the changes on the branch "release-7-0" back into the
c  development branch.
c
c  There are a number of changes to the way that the code is
c  configured. The configure script has been largely re-written and uses
c  the GNU config.guess script to determine the "GNU-triple" specifying
c  architecture of the machine. With names based on this there are then a number of
c  Machine-specific (MK) files stored in the config directory that hold
c  the compiler- and build-specific information for the different builds.
c  The MK files are inserted into Makefile.in in m4 to create the
c  final Makefile for the build. Makefile.in in m4 has also been
c  substantially changed to reflect this.
c
c  An couple of additional directories for validating the parallel code
c  have also been added. These are:
c
c  GAMESS-UK/examples/parallel_GAs and GAMESS-UK/examples/parallel_MPI
c
c
c  The large number of files in this checkin is largely due to the calls
c  to the intrinsic functions max0 and min0 being replaced with calls to
c  max and min.
c
c  The remaining larger changes are summarised below, with the log message for
c  the change being listed, together with the file where the change took
c  place (although obviously a single change can affect a number of files).
c
c  m4/analg.m:
c  Numerous changes to rationalise the current level of analysis and
c  printing when running "property atoms". This now includes generation of
c  properties in both global and principal axis, particularly for the
c  second moments and quadrupoles, plus modified field gradient O/P.
c  Results have been checked against the corresponding O/P from prop1e
c  (the code that is limited to s,p,d functions). - mfg
c
c  m4/basis.m:
c  We need to check on overflow of various arrays due to a job exceeding
c  the parameters in sizes BEFORE we call preharm. Otherwise the chances are
c  that the job dies with an obscure error message in preharm instead of
c  informing the user that her job exceeds the dimensions... - jvl
c
c  m4/c.m:
c  a significant re-working of this file in the hope that it will prove
c  a better starting point for moving around all the machines.
c  The use of memalign has been removed (as has the copy of the routine).
c  getmem will check if alignment is good and will exit(-1) with a
c  message if not, so we should soon find if it memalign was actually
c  needed
c  Declarations of malloc have been removed and a more standard set
c  of #includes introduced. It should be easier to maintain these.
c  Some ipsc and dec specific code has been removed -psh
c
c  m4/cphf.m:
c  Remco had discovered a bug that caused calculations with
c     dft
c     runtype hessian
c  and
c     runtype hessian
c     dft
c  to give different results. This has been fixed now by:
c  a) controling the selection of the CPHF solver in a different way, before
c     the logical scalar was used, now CD_active() is used directly
c  b) the invokation of CD_gradquad(.true.) for hessian calculations has been
c     put in a different location to ensure it is always invoked for hessian
c     jobs.
c
c  - hvd
c
c
c  m4/ga.m:
c  Fixed bug 23: The timing errors were caused by the subroutines wrt3_ga
c  and rdedx_ga exiting without call end_time_period. This happened in
c  the "special case for ed19 c/z vectors". Fixed this by replacing the
c  return statement with goto 999, and adding a corresponding continue
c  statement just before the end_time_period calls. - hvd
c
c  This is a fix for the bug that was causing problems when restarting ga jobs from
c  a dumpfile on disk. For zero word writes, a return statement had been added in wrt3_ga
c  and rdedx_ga as this was needed for ed16 under the CI code. Unfortunately this meant that the
c  block counter wasn't updated for zero length blocks when reading in a dumpfile, causing all
c  blocks following an empty block to be displaced by one. The fix is just to make the return
c  statement for zero word writes conditional to ed19. - jmht
c
c
c  m4/guess.m:
c  Got the *definite* version of atoms; the charge is concentrated in the
c  highest (open) shell, as described in the paper -jvl
c
c  corrected nattempt to uswe charge and spin simulaneously in atdens.
c  is not needed and now forbidden - jvl
c
c  The message "error in atom scf" is most often triggered by forgetting
c  to specify an ECP with an ECP basis set, or by making a mistake in the
c  basis set input. This is not very clear from the error message
c  however, therefore I have added some text to guide the user in finding
c  the likely cause of the error. - hvd
c
c  m4/index.m:
c  replace the explicit zora reads by zora calls in index4 and tran4
c  and restricted usage to (reommended) atomic zora
c  also added an sgmata_255 in index4 allthough th resulting fock matrix
c  seems to be ignored - jvl
c
c  m4/integb_lib.m:
c  An attempt to trap faulty ECP directives. This traps sillies like
c      PSEUDO STRSC
c  which does not mean anything to the code, but upto now the STRSC string
c  was silently ignored. This would confuse users as they would think they had
c  clearly specified which ECP they wanted. Now the code prints the acceptable
c  forms of the initial ECP card and stops. Hopefully this will trigger the
c  inexperienced user to read the manual (one can always hope). -hvd
c
c  machscf.m:
c  disable global array file system by default on all platforms.
c  there are still bugs in this code so we are disabling it until
c  it is fixed and then we'll discuss if it should be re-enabled
c  for specific platforms. - psh
c
c  mains.m:
c  added a list of M4 keywords to the build information that is
c  incorporated in the executable.
c  This is not printed by default (unlike the date/user of the build)
c  but can be obtained by including the "keys" directive. The idea is
c  that it should help us work out exactly which options are active
c  for a particular build. - psh
c
c  A number of changes were made to the calculations of frequencies
c  to achieve more consistent results among different parts of the code.
c  The main changes are:
c  1) Initialise the physical constants in common/funcon/ from the values
c     stored in common/phycon/ to ensure better consistency.
c     (subroutine pacini [master.m])
c  2) Calculate conversion factors from physical constants where needed.
c     (subroutine iranal [anale.m], subroutine rotcon [optim.m],
c      subroutine dr2fre [sec2e.m])
c  3) Use repeated modified Gramm-Schmidt orthonormalisation instead of
c     less accurate modified Gramm-Schmidt or even Gramm-Schmidt.
c     (subroutine prjfco [anale.m], subroutine vibfrq [optim.m])
c  4) Applying the projection to remove translational and rotational
c     coordinates to the mass weighted force constant matrix instead
c     of the normal force constant matrix.
c     (subroutine prjfcm [anale.m])
c  5) Modified the subroutine mofi [optim.m] so that it now returns
c     the centre-of-mass, the moments of inertia, and the eigenvectors
c     of the moments of inertia tensor.
c  6) Use subroutine mofi to compute the moments of inertia where needed.
c     (subroutine vibfrq [optim.m], subroutine thermo [optim.m]) - hvd
c
c
c  m4/newutil3:
c  newutil3 option (ie selecting additional blas-like routines by individual
c  names rather than based on the machine) is now the adopted mechanism.
c  The code corresponding to the old way of doing it has been removed. - psh
c
c  Revision 1.29.2.1  2005/07/19 06:52:20  wab
c
c  min0/max0 changes (see m4 checkin)
c
c  Revision 1.29  2005/05/11 22:37:33  jvl
c  made paralleol vb - I8 completer + few checks and better errormessages
c  sendrecv introduced to avoid race conditions (added to ga-stuff really)
c
c  Revision 1.28  2005/04/22 15:17:53  jvl
c  4-indexd parallel using mpi_sndrcv ; So parallel VB only for MPI
c
c  Revision 1.27  2005/04/22 11:07:55  jvl
c  All vb criteria are now in common vbcri and may be set
c  in the input. Also their defaults are now consistent
c
c  Revision 1.26  2005/03/27 23:29:59  jvl
c  last(??) fix for i8 VB; packed arrays are REAL now; however i*2 and i*4 is used
c  so or something like a CRAY more work might be needed; not too bad though
c
c  Revision 1.25  2005/03/25 23:28:34  jvl
c  changes to allow i8 VB; bit of nasty addressing imnvolved
c
c  Revision 1.24  2005/03/07 14:08:09  jvl
c  - made sure that hybrids and core work => change small to any
c    (in old small calculations cores would be OK for hybrids (within small)
c    now for bigger calculations this is not the case anymore
c  - tightened critor and orthogonalisation criteria. 10**-10 is not good enough
c    anymore => 10**-14 or 15
c
c  Revision 1.23  2005/02/05 18:04:26  wab
c
c  Number of changes here - largely cosmetic that appeared when building
c  the code on the Alpha. Joop I'm sure none of these will effect the
c  correct running of the code.  Note that one of the examples in
c  examples/vb, c2h2, fails on the Alpha, both before and after these
c  changes. Have you seen this problem before?
c
c  segmentation violation diagnostic is as follows:
c
c  forrtl: severe (174): SIGSEGV, segmentation fault occurred
c     0: __FINI_00_remove_gp_range [0x3ff81a1fec8]
c     1: __FINI_00_remove_gp_range [0x3ff81a294a4]
c     2: __FINI_00_remove_gp_range [0x3ff800d0cac]
c     3: normt_ [vbscf.f: 4416, 0x1214bfc40]
c     4: hybmak_ [vbin.f: 6583, 0x121467ad0]
c     5: vbfirst_ [vbin.f: 8399, 0x121473248]
c     6: vbscf_ [vbscf.f: 1219, 0x1214b47a0]
c     7: vb_ [vbin.f: 1279, 0x1214521a0]
c     8: vbstart_ [vbin.f: 1035, 0x121451f94]
c     9: hfscf_ [master.f: 1848, 0x1205441e0]
c    10: scfgvb_ [master.f: 8240, 0x12054a050]
c    11: driver_ [master.f: 6542, 0x120548274]
c    12: gamess_ [mains.f: 236, 0x1201149f8]
c    13: main [for_main.c: 203, 0x120f6d1fc]
c    14: __start [0x120114888]
c
c  Let me know whether you've seen this on other machines, and whether the vb code
c  has been tested on the Alpha before I try and determine what is causing this.
c
c  1. all explicit specifications of "real*8" replaced with REAL in line
c  with the rest of the code.
c
c  2. subroutine scale renamed to scalev - name clash with common block in
c  mopac - although as far as I can tell the routine is never invoked.  By
c  way of interest, there are currently 176 such routines in the code ..
c  more on that later perhaps.
c
c  3. in servec.m "call prtrs(s,ndims)" corrected to "call prtrs(s,ndims,iwr)"
c
c  4.  in vbdens.m - iwr not defined in routine mkld1d2 - iwr added to argument
c  list here and in the calling routine (natorbt)
c
c  5. in vbmatre.m there is an attempt to use the syntax ..
c
c          call vberr('texta','textb')
c
c  where texta and textb have been split from the intended single character
c  string because of limitations in line width. I dont thing this will
c  work as intended, so have revised the original text to reflect the intended
c  message in a single text string.
c
c  6. single precision constant coverted to double precision.
c
c  Revision 1.22  2004/08/19 17:19:10  jvl
c  Solvation stuff added to vb. Remco Havenith and Jeroen Engelberts
c
c  Revision 1.21  2003/10/31 12:26:08  jvl
c  fixed a bug in transformvb. dimension of kvec was wrong (in case mos more
c  than aos). JJE
c
c  Revision 1.20  2003/02/28 10:58:36  jvl
c  Fixed bug in subroutine makepsi0. Lowered vbscf.m deck from -O3 to -O2
c  for sgi systems (JJE).
c
c  Revision 1.19  2003/02/18 17:17:18  jvl
c  A lot of changes, in general:
c  - In vbci the call to bsmat for natural orbitals is no longer necessary
c  - The suboptions pert and fock for optimise in scf are implemented
c  - The subroutine vbscf is completely restructured and is more logical
c  - Addition of the makepsi0, which uses a small extra 2-electron,
c    transformation
c    JJE - 18 feb 2003
c
c  Revision 1.18  2002/11/25 15:25:31  jvl
c  There was a restriction to 500000 words for 4-index. Not very relevant
c  and causing multipass mode, which unfortunately crashes in parallel runs.
c  Eliminated restriction and added error-message for multi-pass in parallel
c
c  Revision 1.17  2002/11/18 17:35:29  jvl
c  Modifications to add servec, in VB
c  putqvb is now just interface to putq, rdistr requires maximum dimension
c  schmids has 'norm' keyword to denote, if a normalisation is required
c  and few other routines made more straightforward.
c
c  Revision 1.16  2002/10/15 15:15:50  jvl
c  blksiz had changed, so now properly included
c  alse enlarged VB dimensions
c
c  Revision 1.15  2002/09/05 14:49:03  jvl
c  Little endian problem fixed for 2-electron integral index arrays (JJE).
c
c  Revision 1.14  2002/05/28 15:07:50  jvl
c  General cleanup
c  got rid of all fortran-files (now part of ed7 is used)
c  handle 3 more common's through include
c  make vector sections in vb more logical
c  added print parameter to getqvb
c  ....
c
c  Revision 1.13  2002/02/10 21:07:02  jvl
c  cleaned up printing and made comparison ci/scf possible
c
c  Revision 1.12  2002/01/13 21:33:07  jvl
c   a vadd paul missed + debug change
c
c  Revision 1.11  2001/10/15 15:32:43  jvl
c  major parallel overhaul; makes asynchronous switchable
c  no luck yet however ...........
c
c  Revision 1.10  2001/09/13 21:31:17  jvl
c  since it proved impossible to use the message length as eof indicator, now mword=-1 serves this purpose
c  this requires a few changes .....
c
c  Revision 1.9  2001/07/03 14:13:19  jvl
c  fixed a few bugs in parallel code and allowed non-usage of peigss in vb
c  (i.e. peigss specifies if peigas is to be used in vb)
c
c  Revision 1.8  2001/06/27 15:28:49  jvl
c  Changed vector printing
c  fixed various bugs (related to getin2)
c  added frozen en frozen hybrids options (experimental)
c
c  Revision 1.7  2001/06/21 16:38:22  jvl
c  added super hybrid option (experimental and perhaps useless) and a bit of cleaning up
c
c  Revision 1.6  2001/06/18 07:46:36  jvl
c  Serial version bugfix with labels in getin2
c
c  Revision 1.4  2001/06/12 12:21:20  jvl
c  - Removed several bugs
c  - Improved parallel 4-index transformation including changes in getin2
c  - Added timing for VB routines
c
c  Revision 1.3  2001/02/08 14:34:39  jvl
c  Adapted parallelisation for GAMESS-UK.
c  An MPI and GA version have been created
c
c  Revision 1.2  2000/03/31 14:18:28  jvl
c  Changed vnorm to vnrm
c  Changed get1e to use getmat
c  Changed scopy to icopy
c  Improved on information about titles
c  Fokke Dijkstra
c
c  Revision 1.1  2000/02/16 12:20:48  jvl
c  adding vb files to gamess repository
c
c Revision 1.12  1998/02/25  14:32:19  fokke
c bugfix .
c
c Revision 1.11  1998/02/25  13:05:08  fokke
c added get1e for gamess6, new keyword gamess5 uses gamess5 dumpfile
c
c Revision 1.10  1998/02/16  14:22:44  fokke
c added counter process to parallel implementation
c added output of energies and interactions of single determinants
c
c Revision 1.9  1997/07/01  13:53:32  fokke
c Changed getin2 for DEC
c
c Revision 1.8  1997/05/30  11:10:21  fokke
c Changed icopy to icopy and removed variables icopy
c
c Revision 1.7  1997/05/22  12:53:09  joop
c changed imove to icopy
c
c Revision 1.7  1997/05/22  12:53:09  joop
c changed imove to icopy
c
c Revision 1.6  1997/05/22  11:31:48  joop
c Added include macro.cpp
c
c Revision 1.5  1997/05/21  11:36:03  joop
c some fixes (21-5-97) FD
c
c Revision 1.4  1997/01/02  16:21:22  joop
c MPI changes for SGI + 1 bugfix
c
c Revision 1.3  1996/11/01  14:05:15  joop
c rcs info + tran(c) sortio
c
      subroutine initra
c
      implicit REAL  (a-h,o-z), integer   (i-n)
INCLUDE(../m4/common/sizes)
c
c
c..   initialise variables for vb 4-index transformation
c..   ** called from vbin **
c..   the main purpose of this routine is to contain all 4-index common
c..   blocks and to explain them and the origin of the program
c
c...  *****************************************************************
c...  **   the  vb-4index is derived from the atmol3 4-index         **
c...  **   cyber205 version / may 1987   (joop v. lenthe / utrecht)  **
c...  **   changed subroutines :                                     **
c...  **     tranin  : was main-program / now input processor for    **
c...  **               vb, called vbin and heavily changed           **
c...  **     shcbld  : changed corbld , leaving h/s matrices in core **
c...  **     mult1   : the transformation matrices q are argument    **
c...  **               common blocks removed from mult1              **
c...  **     index4  : called with vectors (q) as argument           **
c...  **   all symmetry adaption has been removed                    **
c...  **   disp option removed / curt option retained                **
c...  **   common blocks are cleaned up and changed                  **
c...  **   more formal parameters used instead of common             **
c...  *****************************************************************
c..
c=======================================================================
c
INCLUDE(common/splice)
c
c     dxyz : mixing factor for x,y,z comp. of dipole into 1-elec-int.
c     ncore :  orbitals frozen
c     ncore_i : first # or orbitals frozen (to be ignore in conf/hybrid)
c     mapcie / mapiee : labels of core and active orbitals resp.
c
c=======================================================================
c
INCLUDE(common/tractlt)
c     common /tractlt/ scri,iprint,nbasis,ncol,nsa,ncurt,lenact,lenbas,
c    *                num3,iblkq,ionsec,nbsort,isecdu
c
c     iprint : if > 0 give intermediate print
c     nbasis/ncol :  ao's resp. mo's
c     nsa   :  active orbitals (total)
c     ncurt :  active orbitals for which all integrals are needed
c     lenact : nsa*(nsa+1)/2  / lenbas : nbasis*(nbasis+1)/2
c     num3/iblkq : dataset and block number for dumpfile
c     ionsec : section-number for 1-electron integrals
c     nbsort :  blocks in sort-file buffer
c     isecdu : default section for vb-dump (not used now)
c
c=======================================================================
c
INCLUDE(common/basisvb)
c...  common for basis change in VB
c     common/basisvb/corebas,isecbas,nbasbas,ncolbas,isbass
c
c     corebas : core for internal basis
c     isecbas : section for internal basis (if 0 no internal basis)
c     nbasbas : nbasis of internal basis
c     ncolbas : # vectors in internal basis (= then nbasis)
c     isbass  : backup for isecbas
c     sections are made on ed7 (kscra7vb) for s,t and h integrals
c
c=======================================================================
c
INCLUDE(../m4/common/blksiz)
      common/bufvi1/nwbnwb,lnklnk,gout(12286),idumi1,idumi11
c
c     blksiz for sort-file-blocking ( nsz =  blocks ) / see setbf
c     bufv buffer for sort-file (24-blocks max.)
c
c=======================================================================
c
      common/junke/maxt,ires,ipass,nteff,npass1,npass2,
     *             nbuck,mloww,mhi,ntri,iacc
      common/jokex/masterd,iix,jjx,jfile,junit,jblock,kfile,kunit,kkblok
c     master renamed to masterd to avoid conflicts with cndx40
c
c     commons for use in 2-electron transofrmation part
c     e.g. multi-pass sorting (ipass,npass1,npass2,mloww,mhi)
c          bucketing (nbuck,maxt,ires,nteff,ntri)
c          index-range and labels (master,iix,jjx)
c          dataset-info (jfile .. kkblok)
c     iacc : accuracy factor for calc1 and calc2
c
c======================================================================
c
INCLUDE(../m4/common/mapper)
c
c     iky(i) = i*(i-1)/2      (used in triangles)
c
c=======================================================================
c
INCLUDE(common/ffile)
c     common /ffile/ core,pot_nuc,nfil,nofil(20),iblvb(20),lblvb(20),iblhs
c
c     final 4-index-results are saved in
c     core  : effective nuclear repulsion
c     pot_nuc : real nuclear repulsion
c     nfil .. lbl : 2-electron integral files
c     all set just after call of tran
c=======================================================================
c
c
      common/disc/isell(5),ipos(32)
      common/discc/ ied(16)
      character*4 ied
c
c     atmol io-info
c     ipos(1..16) : positions of the 16 atmol datasets
c     ied : names of atmol datasets (ed0 ... mt7)
c
c=======================================================================
c
c     part of atmol free format io system (work is really longer)
c     jrec : pointer (number) of field to be read  - 1
c     jump :  fields on the current card
c
c=======================================================================
c
c     common/blkin/param(19),gitle(10),evalue(256),occ(257),
c    *             nbas,newb,ncoll,ivalue,ioccc
c
c     common used to read atmol info into in various ways
c     above form is the vectors info-block (544 words)
c     also occurring
c       -- 2-electron-integral block --
c         common/blkin/gin(340),gij(170),mword
c       -- 1-electron-integral block --
c     common/blkin/potnuc,ppx,ppy,ppz,s(72),t(72),h(72),
c    *             xxx(72),yyy(72),zzz(72),iin(72),icount
c
c=======================================================================
c
      common/scra/ibuk(3400),itxktx4(2,2550)
c            or (in tdown)
c*    common/scra/xa(256),
c*   *            ilifc(256),ntran(256),itran(600),ctran(600),iftran
      common/scrp/ ijkl(2,8190)
c*    common/scrp/nwbuck(1500),itx(3400),ktx(3400),gtx(3400)
c*    common/scrp/ijkl205(680)
c
c     scratch commons for sort-routines use elsewhere allowed)
c     scrp also used in vbin for temporary input-storage
c
      common/stak/btri,mlow,nstack,iblock,mstack
      common/commun/mark(1500),ibase(1500),ibasen(1500)
c
c     commons for use in bucketing (sort routines)
c
c======================================================================
c
c
c     gamess/atmol io-info. print-flag set to false
c
c======================================================================
      common/charsort/sortname(2),scratch,zout
      character*44 sortname,scratch
      character*8 zout
INCLUDE(../m4/common/cndx40)
c
c...   /splice/
c
      dxyz(1)  = 0
      dxyz(2)  = 0
      dxyz(3)  = 0
c
c...   /tractlt/
c
      nsa = 0
c     ncurt = 999999
      ncurt = -1
      iprint = 0
c     ionsec = 492
      nbsort = 10
c     
c...  /basisvb/
c
      isecbas = 0
      isbass = 0
c
c...   /junke/  from  cndx40
c
      iacc = 12
c...   in line with an scf criterium of 10**-6
      npass1=npas41
      npass2=npas42
c
c
c...   /mapper/
c
c...   /charsort/
c
       sortname(1)='sort'
c
      return
      end
c
      subroutine transformvb(s,h,vect)
c
      implicit REAL (a-h,o-z), integer (i-n)
c
c...  control routine for 2-index and 4-index integral transformations
c...  if ncore > 0, the active orb are orthogonalised against the core
c
c...  s      resulting overlap integrals over active orbitals
c...  h      resulting 1-electron integrals
c...  vect   orbitals in order frozen,active,virtual
c...  qq     working area, dynamicly allocated
c
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/vcore)
c
      dimension s(*),h(*),vect(*)
c
INCLUDE(common/tractlt)
INCLUDE(common/splice)
c
c... for dynamic memory allocation debugging purpose, contains IGMEM_ vars.
INCLUDE(../m4/common/gmemdata)
INCLUDE(../m4/common/gmempara)
c
INCLUDE(../m4/common/files)
c
INCLUDE(common/ffile)
INCLUDE(../m4/common/restri)
INCLUDE(../m4/common/iofile)
INCLUDE(common/vbcri)
c
      logical new2el
      common/new2el/ new2el
c
      dimension nnfils(2),nblks(20,2)
c
c...  reserve space for incore sort
c
      if (iprint.ge.50) call whtps
*
            kmaxmem = igmem_max_memory()
      if (incsort) then
         mmsort = igmem_max_memory()*2.7/3 - 100
         ksort = igmem_alloc_inf(mmsort,'vbtran.m','transformvb',
     &                          'ksort',IGMEM_DEBUG)
         nnsort = mmsort
         maxsort = 0
         if (iprint.ge.50) 
     &   write(iwr,*) ' incore sorting : ','adres ',ksort,
     &             ' total sortspace ',mmsort,
     &             ' sorting ',nsz,' blocks',
     &             ' size of a sortbuffer ',512,' # buffers ',nnsort
      end if  
c

      if ( new2el ) then
        n2int = setintpos(nactiv,nsa)
      else
        n2int = setintpos(nsa,nsa)
      end if
c
      kmaxmem = igmem_max_memory()
      kmemscr = kmaxmem/10
      kscr    = igmem_alloc_inf(kmemscr,'vbtran.m','transformvb','kscr',
     &                          IGMEM_DEBUG)
      iflop = lchbas(vect,Q(kscr),ncol,'external')
      call gmem_free_inf(kscr,'vbtran.m','transformvb','kscr')
c
      if (iprint.ge.20000) then
         write(iwr,'(a)') ' occupied orbitals upon entering subr tran'
         call prvc(vect,ncol,nbasis,vect,'o','l')
      end if
c
c...  save n4file,n6file,n4last,n6last (are changed in index4)
c
      nnfils(1) = n4file
      nnfils(2) = n6file
      do 10 i=1,20
         nblks(i,1) = n4last(i)
         nblks(i,2) = n6last(i)
10    continue

c
      kvec = igmem_alloc_inf(ncol*nbasis,'vbtran.m','transformvb',
     &                       'kvec',IGMEM_DEBUG)
      ktvec = igmem_alloc_inf(nsa*nbasis,'vbtran.m','transformvb',
     &                        'ktvec',IGMEM_DEBUG) 
c
c...  copy orbitals
c
      call vclr(Q(kvec),1,ncol*nbasis)
      call vclr(Q(ktvec),1,nsa*nbasis)
      call dcopy(ncol*nbasis,vect,1,Q(kvec),1)

      if (ncore.gt.0) then
c
c...     orthogonalise subtlely if ncore > 0
c
         ksao = igmem_alloc_inf(lenbas,'vbtran.m','transformvb','ksao',
     &                          IGMEM_DEBUG)
         kscr = igmem_alloc_inf(lenbas*2,'vbtran.m','transformvb',
     &                          'kscr',IGMEM_DEBUG)
c
c...     get ao metric
c
         call get1e(Q(ksao),dummy,'s',Q(ksao))
c
c...     schmidt core orbitals
c
         call normvc(Q(kvec),Q(ksao),Q(kscr),
     &               nbasis,ncore,cridep)
c
c...     schmidt other orbitals onto core orbitals
c
         call schmids(Q(kvec+ncore*nbasis),Q(kvec),
     &                Q(ksao),Q(kscr),
     &                nsa,ncore,nbasis,cridep,'norm')
         call gmem_free_inf(kscr,'vbtran.m','transformvb','kscr')
         call gmem_free_inf(ksao,'vbtran.m','transformvb','ksao')
c
      end if
c
c...  dump vectors to ed7
c
      kvb7_transvb = kscra7vb('kvb7_transvb',(ncore+nsa)*nbasis,'r','n')
      if (kvb7_transvb.lt.0) call caserr('kvb7_transvb not init')
      kvb7_transvb = kscra7vb('kvb7_transvb',(ncore+nsa)*nbasis,'r','w')
      call wrt3(Q(kvec),(ncore+nsa)*nbasis,kvb7_transvb,num8)
c
c...  transpose active orbitals
c
      call dagger(nbasis,nsa,Q(kvec+ncore*nbasis),
     &            nbasis,Q(ktvec),nsa)
c
c...  4-index transformation
c
      kmaxmem = igmem_max_memory() - 100
      kscr = igmem_alloc_inf(kmaxmem,'vbtran.m','transformvb',
     &                           'kscr',IGMEM_DEBUG)
      call ind4vb(Q(kvec+ncore*nbasis),
     &            Q(ktvec),Q(kscr),kmemscr)
      call gmem_free_inf(kscr,'vbtran.m','transformvb','kscr')
c
c...  2-index transformation (including frozen core)
c
      ksao = igmem_alloc_inf(max(lenact,lenbas),'vbtran.m',
     &                       'transformvb','ksao',IGMEM_DEBUG)
c
      kx1 = igmem_alloc_inf(lenbas,'vbtran.m','transformvb','kx1',
     &                      IGMEM_DEBUG)
c
c...  lenact is changed to max(lenact,lenbas) (anthony)
c
      kx3 = igmem_alloc_inf(lenbas,'vbtran.m','transformvb','kx3',
     &                      IGMEM_DEBUG)
      kx2 = igmem_alloc_inf(max(lenbas,nsa*(nbasis+nsa)),'vbtran.m',
     &                      'transformvb','kx2',IGMEM_DEBUG)
c	call gmem_check_guards('voor shcbld')

      call shcbld(Q(ksao),h,Q(kvec),
     &            Q(ktvec),Q(kx2),
     &            Q(kx3),Q(kx1))
      call dcopy(lenact,Q(ksao),1,s,1)
 
      call gmem_free_inf(kx2,'vbtran.m','transformvb','kx2')
      call gmem_free_inf(kx3,'vbtran.m','transformvb','kx3')
      call gmem_free_inf(kx1,'vbtran.m','transformvb','kx1')
      call gmem_free_inf(ksao,'vbtran.m','transformvb','ksao')
c
c...  pass information on final mainfile on
c
      nfil = n6file
      do 20 i=1,20
         nofil(i) = n6tape(i)
         iblvb(i) = n6blk(i)
         lblvb(i) = n6last(i)
20    continue
c
c...  save h and s-matrices on the dumpfile
c
      call secput(isect(431),431,2*lensec(lenact),iblhs)
      call wrt3(h,lenact,iblhs,num3)
      call wrt3s(s,lenact,num3)

      call clredx
      if (iprint.gt.100) call whtps
c
c...  restore n4file,n6file,n4last,n6last
c
      n4file = nnfils(1)
      n6file = nnfils(2)
      do 30 i=1,20
         n4last(i) = nblks(i,1)
         n6last(i) = nblks(i,2)
30    continue
c
      if (iprint.ge.20000) then
         write(iwr,'(a)') ' occupied orbitals upon leaving subr tran'
         call prvc(Q(kvec),ncol,nbasis,Q(kvec),'o','l')
      end if
c
      kmaxmem = igmem_max_memory()
      kmemscr = kmaxmem/10
      kscr    = igmem_alloc_inf(kmemscr,'vbtran.m','transformvb','kscr',
     &                          IGMEM_DEBUG)
      iflop = lchbas(vect,qq(kvec),ncol,'internal')

      call gmem_free_inf(kscr,'vbtran.m','transformvb','kscr')
      call gmem_free_inf(ktvec,'vbtran.m','transformvb','ktvec')
      call gmem_free_inf(kvec,'vbtran.m','transformvb','kvec')
*
      if (incsort)
     +   call gmem_free_inf(ksort,'vbtran.m','transformvb','ksort')
*
      return
      end

c***********************************************************************
      subroutine transcvb(qq,nkk,gin)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c
      dimension qq(*),gin(*)
c
c...   move block to processing area    called from calc1/calc2
c...   in future (on nos/ve) may work directly on sort-common
c
      common/junke/maxt,ires,ipass,nteff,npass1,npass2,
     *             nbuck,mloww,mhi,ntri,iacc
INCLUDE(common/c8_16vb)
INCLUDE(common/tractlt)
c**
INCLUDE(../m4/common/blksiz)
INCLUDE(../m4/common/iofile)
c***
      dimension ijkl(2,8192)
      call unpack(gin(nsz340+1),n16_32,ijkl,nkk*2)
c***
      do 43 iword =1,nkk
          qq( (ijkl(1,iword)-mloww)*lenbas+ijkl(2,iword) ) = gin(iword)
43    continue
c
      return
      end
      subroutine calc1vb(r,scr,qq,hh,qvec,qtvec)
c
      implicit REAL  (a-h,p-z) , integer   (i-n), logical (o)
c
c
      dimension r(*),scr(*),hh(*)
      dimension qq(*),qvec(*),qtvec(*)
c
c...   processes sorted mainfile
c...   to produce integrals of the form (i j/r s)
c...   on secondary mainfile
c
INCLUDE(common/c8_16vb)
INCLUDE(../m4/common/iofile)
      common/scrp/ijkL205(680)
      common/junke/maxt,ires,ipass,nteff,npass1,npass2,
     *             nbuck,mloww,mhi,ntri,iacc
      common/jokex/master,iix,jjx,jfile,junit,jblock,kfile,kunit,kkblok
INCLUDE(common/tractlt)
      common/bufvi1/nki1,mki1,gini1(12286),idumi1,idumi11
      common/bufvo1/nko1,mko1,gino1(12286),idumo1,idumo11
c
      common/blkin/gout(340),gijout(170),mword,mdumm(3)
      common/commun/mark(1500)
      common/stak/btri,mlow,nstack,iblock,mstack
INCLUDE(../m4/common/blksiz)
c
INCLUDE(common/vbparr)
c
      nav = nipw()
      mword=0
      small=10.0d0**(-iacc)
      call stopbk
_IF(parallel)
c
c... number nodes from 1 to nnodes (no zero)
c
      me  = ipg_nodeid()
      me1 = me + 1
   
      nnodes = ipg_nnodes()
_ELSE
      me = 0
      me1 = 1
      nnodes = 1
_ENDIF
      idid = 0
c
      do 3 nround=1,nbuck/nnodes
c
        ido = (nround-1)*nnodes + me1
c
        do i=idid+1,ido-1
          mhigh = mloww + ntri
          if (mhigh.gt.mhi) mhigh = mhi
          mtri = mhigh - mloww
          master = master + mtri
          mloww =  mhigh
        end do 
        idid = ido
        mhigh = mloww + ntri 
        if (mhigh.gt.mhi) mhigh = mhi
        mtri = mhigh - mloww
        mloww=mloww+1
        nsize=mtri*lenbas
        call vclr(qq,1,nsize)
c
_IF(parallel)
c....    only sync mpi for now ....
        if (sync.eq.0) call caserr('nosync not allowed')
        do 2 i=1,nnodes-1
c
c... initialise communication info
c
          iread = i + me1
          if (iread.gt.nnodes) iread = iread - nnodes
          isend = iread - 1
          iread = iread + (nround-1)*nnodes
          iget = nnodes + me1 - i
          if (iget.gt.nnodes) iget = iget - nnodes
          iget = iget - 1
c
c... select row to work on
c
          iblo = mark(iread)
          if (iblo.eq.9999999) iblo = 9999998
          ibli = 0
c
c... read output buffer 1
c
1         if (iblo.ne.9999999) then
            if (iblo.eq.9999998) then
              nko1=0
              mko1=9999999
            else
              call rdbakvb(iblo,nko1)
            end if
          end if
c
c... send output buffer 1 and receive input buffer 1
c
          if (iblo.ne.9999999.and.check.eq.1) 
     1       call check32(mko1,gino1,nsz340*nav+nko1,
     2                    gino1(nsz340+(nko1+1)/nav+1),'calc')
c
          if (iblo.ne.9999999.and.ibli.ne.9999999) then
             call pg_sndrcv(10*isend+1, nko1, (nsz340+(nko1+3)/nav+1)*8,
     1                      isend, 
     1                      10*me+1, nki1, 12288*8, lm, iget, nodefrom)
            iblo = mko1
          else if (iblo.ne.9999999) then
            call pg_snd(10*isend+1,nko1,(nsz340+(nko1+3)/nav+1)*8,
     1                  isend,sync)
            iblo = mko1
          else if (ibli.ne.9999999) then
            call pg_rcv(10*me+1,nki1,12288*8,lm,iget,nodefrom,sync)
          endif
c
          if (ibli.ne.9999999) then
            if (check.eq.1) call check32(mki1,gini1,nsz340*nav+nki1,
     1                              gini1(nsz340+(nki1+1)/nav+1),'test')
            ibli = mki1
            call transcvb(qq,nki1,gini1)
          end if
c
c... check if all done 
c
          if ((ibli.ne.9999999).or.(iblo.ne.9999999)) goto 1
2       continue
_ENDIF
c
c...   do own blocks 
c
        ibli=mark(ido)
888     if (ibli.ne.9999999) then
          call rdbakvb(ibli,nki1)
          call transcvb(qq,nki1,gini1)
          ibli=mki1
          go to 888
        end if
c
c... do transformation on own rows
c... compute integrals of the form (i j/k l)
c
        map=1
        do 777 itri=1,mtri
          master=master+1
c
c...    compute integrals of the form (i j/r s)
c...    master=iky(r)+s
c
c...    decide on curtail option
c
          if (ncurt.gt.0) then
            call curt1(qq(map),r,scr,hh,nbasis,nsa,ncurt,qvec)
          else
            call mult1(qq(map),r,scr,nsa,nbasis,nsa,qvec,qtvec)
          end if
c
c...    write (i j/r s) integrals to intermediate mainfile
c
          do 1009 kb=1,lenact
             if (dabs(r(kb)).ge.small) then
                mword=mword+1
                gout(mword)=r(kb)
                ijkl205(mword)=kb
                ijkl205(n340+mword)=master
                if (mword.eq.n340) call outblk
             end if
1009      continue
776       map=map+lenbas
777     continue
3     mloww = mhigh
c
      if (mword.ge.1) call outblk
c
_IF(parallel)
c...  extra effort to make sure multipass parallel is the same on all nodes
      if (npass1.gt.1) master = mhi
_ENDIF
c
      return
      end

      subroutine calc2vb(r,v,qq,hh,qvec,qtvec)
c
      implicit REAL  (a-h,p-z) , integer   (i-n), logical (o)
c
c
c...   processes sorted secondary mainfile
c...   to produce integrals of the form (i j/k l)
c...   on final mainfile
c
      dimension r(*),v(*),qq(*),hh(*),qvec(*),qtvec(*)
c
INCLUDE(../m4/common/sizes)
INCLUDE(common/c8_16vb)
INCLUDE(../m4/common/iofile)
      common/scrp/ijkl205(680)
      common/junke/maxt,ires,ipass,nteff,npass1,npass2,
     *             nbuck,mloww,mhi,ntri,iacc
      common/jokex/master,iix,jjx,jfile,junit,jblock,kfile,kunit,kkblok
INCLUDE(common/tractlt)
      common/bufvi1/nki1,mki1,gini1(12286),idumi1,idumi11
      common/bufvo1/nko1,mko1,gino1(12286),idumo1,idumo11
      common/blkin/gout(340),gijout(170),mword,mdumm(3)
      common/commun/mark(1500)
      common/stak/btri,mlow,nstack,iblock,mstack
INCLUDE(../m4/common/blksiz)
c
      dimension koos(4)
c
INCLUDE(common/vbparr)
c
      acc1=10.0d0**(-iacc)
      mword=0
      nav = nipw()
c
      call stopbk
_IF(parallel)
c
c... number nodes from 1 to nnodes (no zero)
c
      me  = ipg_nodeid()
      me1 = me + 1
      nnodes = ipg_nnodes()
_ELSE
      me  = 0
      me1 = 1
      nnodes = 1
_ENDIF
      idid = 0
c
      do 3 nround=1,nbuck/nnodes
c
        ido = (nround-1)*nnodes + me1
c
        do i=idid+1,ido-1
          mhigh = mloww + ntri
          if (mhigh.gt.mhi) mhigh = mhi
          mtri = mhigh - mloww
          mloww =  mhigh
          do itri=1,mtri
            jjx=jjx+1
            if (jjx.gt.iix) then
              iix=iix+1
              jjx=1
            end if
          end do
        end do
        idid = ido
        mhigh = mloww + ntri
        if (mhigh.gt.mhi) mhigh = mhi
        mtri = mhigh - mloww
        mloww=mloww+1
        nsize=mtri*lenbas
        call vclr(qq,1,nsize)
c
_IF(parallel)
        do 2 i=1,nnodes-1
c
c... initialise communication info
c
          iread = i + me1
          if (iread.gt.nnodes) iread = iread - nnodes
          isend = iread - 1
          iread = iread + (nround-1)*nnodes
          iget = nnodes + me1 - i
          if (iget.gt.nnodes) iget = iget - nnodes
          iget = iget - 1
c
c... select row to work on
c
          iblo = mark(iread)
          if (iblo.eq.9999999) iblo = 9999998
          ibli = 0
c
c... read output buffer 1
c
1         if (iblo.ne.9999999) then
            if (iblo.eq.9999998) then
              nko1=0
              mko1=9999999
            else
              call rdbakvb(iblo,nko1)
            end if
          end if
c
c... send output buffer 1 and receive input buffer 1
c
          if (iblo.ne.9999999.and.check.eq.1) 
     1       call check32(mko1,gino1,nsz340*nav+nko1,
     2                    gino1(nsz340+(nko1+1)/nav+1),'calc')

c
          if (iblo.ne.9999999.and.ibli.ne.9999999) then
             call pg_sndrcv(10*isend+1, nko1, (nsz340+(nko1+3)/nav+1)*8,
     1                      isend,
     1                      10*me+1, nki1, 12288*8, lm, iget, nodefrom)
            iblo = mko1
          else if (iblo.ne.9999999) then
            call pg_snd(10*isend+1,nko1,(nsz340+(nko1+3)/nav+1)*8,
     1                  isend,sync)
            iblo = mko1
          else if (ibli.ne.9999999) then
            call pg_rcv(10*me+1,nki1,12288*8,lm,iget,nodefrom,sync)
          endif
c
          if (ibli.ne.9999999) then
            if (check.eq.1) call check32(mki1,gini1,nsz340*nav+nki1,
     1                              gini1(nsz340+(nki1+1)/nav+1),'test')
            ibli = mki1
            call transcvb(qq,nki1,gini1)
          end if
c
c... check if all done
c
          if ((ibli.ne.9999999).or.(iblo.ne.9999999)) goto 1
2       continue
_ENDIF
c
c...   do own blocks
c
        ibli=mark(ido)
888     if (ibli.ne.9999999) then
          call rdbakvb(ibli,nki1)
          call transcvb(qq,nki1,gini1)
          ibli=mki1
          go to 888
        end if
c
c...   compute integrals of the form (i j/k l)
c
        map=1
        do 777 itri=1,mtri
c...
           if (ncurt.gt.0) then
              call curt2(qq(map),v,hh,acc1,nbasis,nsa,ncurt,iix,jjx,
     *                    qvec)
           else
c...
              call mult1(qq(map),r,v,iix,nbasis,nsa,qvec,qtvec)
              if (n8_16.eq.8) then
                 mword1=jjx+iix*256
              else
                 mword1=jjx+iix*65536
              end if
              m=0
              do 1009 k=1,iix
                 last=k
		 if (n8_16.eq.8) then
		    k4096=k*256
		 else
		    k4096=k*65536
		 end if
                 if(k.eq.iix) last=jjx
                 do 1009 j=1,last
                    m=m+1
c...    (i j/k l) now in r(m)
                    if (dabs(r(m)).ge.acc1) then
                       mword=mword+1
                       kb=j+k4096
                       gout(mword)=r(m)
                       ijkl205(mword)=mword1
                       ijkl205(n340+mword)=kb
                       if (mword.eq.n340) call outbll
                    end if
1009          continue
           end if
c...
776        jjx=jjx+1
           if (jjx.gt.iix) then
              iix=iix+1
              jjx=1
           end if
           map=map+lenbas
777     continue
c
3     mloww=mhigh
c
      if (mword.ge.1) call outbll
c
_IF(parallel)
      if (npass2.gt.1) then
c...  extra effort to make sure multipass parallel is the same on all nodes
         mword1=jjx+iix*65536
         call pg_igop(3003,mword1,1,'max')
         iix = mword1/65536
         jjx = mword1-iix*65536
      end if
_ENDIF
c
      return
      end
      subroutine curt1(qq,r,x,hh,nbasis,nactiv,ncurt,q)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c
c     subroutine to perform first part of restricted 4-index
c
c      r = (partial) q(transp.)*qq*q
c            curtail         option
c     j. verbeek / j.h. v. lenthe  1985
c
c     qq nbasis*(nbasis+1)/2       integral-triangle
c     r  nactiv*(nactiv+1)/2       result
c     q  nbasis*nactiv             vectors
c     hh nbasis**2                 scratch squared h-matrix
c     x  nbasis*nactiv             intermediate scratch
c
      dimension hh(*),q(*),r(*),x(*),qq(*)
c
INCLUDE(../m4/common/sizes) 
INCLUDE(../m4/common/mapper)
c
c...  zeroise x- and r matrices / square h
c
      call vclr(x,1,nbasis*nactiv)
      call vclr(r,1,nactiv*(nactiv+1)/2)
      call square(hh,qq,nbasis,nbasis)
c
c...  transformation of 1st index : i=1,ncurt
c
      call mxmb(hh,1,nbasis,q,1,nbasis,x,1,nbasis,nbasis,nbasis,ncurt)
c
c...  transformation of 2cnd index : j=i,nactiv
c
      ki = 1
      do 100 i=1,ncurt
         kj = (i-1)*nbasis + 1
         do 10 j=i,nactiv
         ip = iky(j) + i
         r(ip) = ddot(nbasis,x(ki),1,q(kj),1)
10       kj = kj + nbasis
100   ki = ki + nbasis
c
      return
      end
      subroutine curt2(qq,x,hh,small,nbasis,nactiv,ncurt,iix,jjx,q)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c
      dimension qq(*),q(*),x(*),hh(*)
c
c...  this routine transformes the third and fourth index in a
c...  restricted 4-index ("curt") and prepares output of integrals
c...  j. verbeek / j.h. v. lenthe  (utrecht,1985)
c
INCLUDE(../m4/common/sizes) 
INCLUDE(common/c8_16vb) 
      common/scrp/ijkl205(680)
INCLUDE(../m4/common/restri)
      common/blkin/gout(340),gijout(170),mword,mdumm(3)
c
      if (jjx.gt.ncurt) return
c
c...  form square h-matrix (in hh) and zeroise x-matrix
c
      call square(hh,qq,nbasis,nbasis)
      call vclr(x,1,nbasis*nactiv)
c
      ist = (jjx-1)*nbasis + 1
      idi = nactiv - jjx + 1
      if (n8_16.eq.8) then
         mword1=jjx+iix*256
      else
         mword1=jjx+iix*65536
      end if
c
c...  transformation of 3rd index according to "curt"  k=i,nactiv
c
      call mxmb(hh,1,nbasis,q(ist),1,nbasis,x,1,nbasis,
     *          nbasis,nbasis,idi)
c
      kk = 1
      do 100 k=jjx,nactiv
         lmin = k
         if (k.eq.jjx) lmin = iix
         iqs = (lmin-1)*nbasis + 1
         do 10 l=lmin,nactiv
            r = ddot(nbasis,x(kk),1,q(iqs),1)
            if (dabs(r).lt.small) go to 10
            mword = mword + 1
            gout(mword) = r
            if (n8_16.eq.8) then
               l4096=l*256
            else
               l4096=l*65536
            end if
            kb = k + l4096
            ijkl205(mword) = max(mword1,kb)
            ijkl205(n340+mword) = min(mword1,kb)
            if (mword.eq.n340) call outbll
10       iqs = iqs + nbasis
100   kk = kk + nbasis
c
      return
      end
c***********************************************************************
      subroutine get1e(e,core,type,q)
c
      implicit REAL  (a-h,p-z) , integer   (i-n), logical (o)
c
      dimension e(*),q(*)
      character*1 type
c
c...
c...   get 1-electron integrals from dumpfile for VB
c...   type determines the type of integrals retrieved
c...   i.e. s,h,x,y,z,t,h+x+y+z  (dipole directive)
c...   h always gives dipole ints if dxyz ne 0 as with point charges
c...   pure h never required
c...   v => h-t
c...   all other info is taken from /tractl/ and /splice/
c...   adapted to provide ints in the isecbas basis if needed
c...
      dimension ostf(6),charge(6) 
      common/blkin/potnuc,ppx,ppy,ppz,pint(508)
INCLUDE(common/tractlt)
INCLUDE(common/splice)
INCLUDE(common/basisvb)
INCLUDE(../m4/common/psscrf)
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/infoa)
      dimension dscrc(3,maxat),dscr(maxat)
c
      lentri=nbasis*(nbasis+1)/2                                                      
      if (isecbas.ne.0) then
         if (opssc) call caserr('PCM and =basis= not done')
c...     get ints from internal basis instead
         k7sbas = kscra7vb('k7sbas',lentri,'r','r')
         if (type.eq.'s') call rdedx(e,lentri,k7sbas,num8)
         k7tbas = kscra7vb('k7tbas',lentri,'r','r')
         if (type.eq.'t') call rdedx(e,lentri,k7tbas,num8)
         k7hbas = kscra7vb('k7hbas',lentri,'r','r')
         if (type.eq.'h') call rdedx(e,lentri,k7hbas,num8)
         if (type.eq.'v') then
            call rdedx(q,lentri,k7tbas,num8)
            do i=1,lentri
               e(i) = e(i) - q(i)
            end do
         end if
         core = corebas
         return
      end if
c
      do i=1,6
         ostf(i) = .false.
      end do
c
      if (type.eq.'s') ostf(1) = .true.
      if (type.eq.'t') ostf(2) = .true.
      if (type.eq.'h'.or.type.eq.'v') ostf(3) = .true.
      if (type.eq.'x') ostf(4) = .true.
      if (type.eq.'y') ostf(5) = .true.
      if (type.eq.'z') ostf(6) = .true.
c 
      call getmat(e,e,e,e,e,e,charge,nbasis,ostf,ionsec)
c
      if (type.eq.'v') then
         ostf(3) = .false.
         ostf(2) = .true.
         call getmat(q,q,q,q,q,q,charge,nbasis,ostf,ionsec)
         do i=1,lentri
            e(i) = e(i) - q(i)
         end do
      end if
c        
      do i=1,3 
         ostf(i) = .false.
      end do
      core = charge(1)
c
      if ((dxyz(1).ne.0.0d0.or.dxyz(2).ne.0.0d0.or.dxyz(3).ne.0.0d0) 
     1    .and.(type.eq.'h'.or.type.eq.'v')) then
         do 10 i=1,3
            ostf(i+2) = .false.
            ostf(i+3) = .true.
            call getmat(q,q,q,q,q,q,charge,nbasis,ostf,ionsec)
            do j=1,lentri
               e(j)=e(j) + dxyz(i)*q(j)
            end do
            core = core + dxyz(i)*charge(i+1)
10       continue
      end if
c...   PCM
      if (opssc) then
          call mod1ed(dscrc,dscr,0)
          core= denuc(nat,dscr,dscrc,itotbq,iwr)
      endif
c
      return
      end

c***********************************************************************
      subroutine getin2(g)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c...
c...   get 2-electron integrals in core for vb
c...     *first stupid symmetry-less version  **
c...     integrals are read from final-mainfile from 4-index
c...     first integral = (00/00) !!!
c... 
c...  For the parallel versions all integrals are gathered at the root
c...  and then broadcasted. We check if all blocks are received because
c...  of mpi (?) problems .... mdumm contains block-no (order is checked)
c...
       dimension g(*)
c...
INCLUDE(common/c8_16vb)
INCLUDE(common/tractlt)
INCLUDE(common/ffile)
      common/blkin/gin(510),mword,mdumm(3)
      common /posit/ iky(3)
      common /scra/ ij(2,340),kl(2,340)
INCLUDE(../m4/common/iofile)
_IF(parallel)
      logical oroot, ocomplete, osend
      dimension blkbuf(512)
c....   sync = 1=> synchronous // 0 => asynchronous
INCLUDE(common/vbparr)
_ENDIF
_IF(linux)
      external fget
_ENDIF 
c
      nav = nipw()
c
c...  clear integral-array
c
      call vclr(g,1,n2int+1)
c
c...   start loop over mainfile blocks
c
      do 20115 ifile=1,nfil
_IF(parallel)
c
c... root receives integrals from other nodes and unpacks them
c
        i511 = 8*(340 + 170 + 2/nav)
        me = ipg_nodeid()
        ncpu = ipg_nnodes()
        if (oroot()) then 
          do 20112 nid = 1,ncpu-1
c
             lb = 0
c
             ocomplete =.false.
             m = -1
20110        if (m.ne.0) then
               call pg_rcv(nid,blkbuf,i511,lm,nid,nodefrom,sync)
               if (ocomplete) then
c...       process input block
                 call izero(mword*2,ij,1)
                 call izero(mword*2,kl,1)
                 call unpack(gin(n340+1),n8_16,ij,n340*2)
                 call unpack(gin(n340+1+n340/(32/n8_16)),n8_16,
     1                       kl,n340*2)
                 do 11 l=1,mword
_IF(littleendian)
                   index = intpos(ij(2,l),ij(1,l),kl(2,l),kl(1,l)) + 1
_ELSE
                   index = intpos(ij(1,l),ij(2,l),kl(1,l),kl(2,l)) + 1
_ENDIF
                   g(index) = gin(l)
11               continue
               end if
               if (sync.eq.0) call pg_wait(nid,1)
               ocomplete = .true.
               call dcopy(i511/8,blkbuf,1,gin,1)
               lb = lb + 1
               if (check.eq.1) call check32(lb,gin,nav*i511/8-1,mdumm,
     1                                       'test')
c              if (lb.ne.mdumm) then
c                 print *,' lb ',lb,' ne lb in block ',mdumm
c                 call caserr('order or drop proble in getin2')
c              end if
               m=i511
c...              mword = -1 signals eof
               if (mword.eq.-1) then
                  m = 0
               end if
               goto 20110
             end if
20112     continue
c
c... nodes read integrals from file and send them to root 
c
        else
          m = -1
          osend = .false.
          lb  = iblvb(ifile)
          if (lb.eq.lblvb(ifile)) then
            m=0
          else
            iunit=nofil(ifile)
            call search(iblvb(ifile),iunit)
          end if

20113     if (m.ne.0) call fget(gin,m,iunit)
          if (osend.and.sync.eq.0) call pg_wait(0,0)
c...         mword -1 signals EOF
          if (m.eq.0) mword = -1
          mdumm = lb - iblvb(ifile) + 1
          if (check.eq.1) call check32(mdumm,gin,nav*i511/8-1,mdumm,
     1                                 'calc')
          call dcopy(i511/8,gin,1,blkbuf,1)
          call pg_snd(me,blkbuf,i511,0,sync)
          osend = .true.
          if (m.ne.0) then
            lb = lb + 1 
c           if (lb.ne.lblvb(ifile)) goto 20113
            goto 20113
          end if
          if (osend.and.sync.eq.0) call pg_wait(0,0)
        end if
c
c... root reads its own integrals as last step
c
        if (oroot()) then
_ENDIF
          lb  = iblvb(ifile)
          if (lb.eq.lblvb(ifile)) go to 20116
          iunit=nofil(ifile)
          call search(iblvb(ifile),iunit)
c...
20114     call fget(gin,m,iunit)
c...
          if (m.ne.0) then
c...       process input block
             call izero(mword*2,ij,1)
             call unpack(gin(n340+1),n8_16,ij,n340*2)
             call izero(mword*2,kl,1)
             call unpack(gin(n340+1+n340/(32/n8_16)),n8_16,kl,n340*2)
             do 22 l=1,mword
_IF(littleendian)
               index = intpos(ij(2,l),ij(1,l),kl(2,l),kl(1,l)) + 1
_ELSE
               index = intpos(ij(1,l),ij(2,l),kl(1,l),kl(2,l)) + 1
_ENDIF
               g(index) = gin(l)
22           continue
             lb=lb+1
             g(1) = 0.0d0
             if (lb.ne.lblvb(ifile)) go to 20114
          end if
20116     continue
_IF(parallel)
        end if
_ENDIF
20115 continue
_IF(parallel)
      call pg_brdcst(7,g,8*(n2int+1),0)
_ENDIF
      return
      end

      module ikyg
_INCLUDE(common/turtleparam)
_INCLUDE(../m4/common/sizes)
c      save ikyiky,nocc,nocc1,lbase
      integer ikyiky(mxorbvb*(mxorbvb+1)/2),nocc,nocc1,lbase
      integer iky(maxorb)
c!$acc declare create(ikyiky,iky,nocc,nocc1,lbase)
      end module

c*******************************************************************************
      integer function intpos(ii,jj,kk,ll)
c
      use ikyg
      implicit none
c!$acc routine
c
c     determine position in closely packed  2-el integral array
c     used in VB
c
c     1111
c     1
c     2111  2121
c     2     3
c     2211  2221 2222
c     4      5    6
c     3111  3121 3122 3131
c     7     8     9    10
c     3211  3221 3222 3231 3232
c     11    12   13    14   15     
c     3311  3321 3322 3331 3332  3333
c     16    17    18
c     4111  4121 4122 4131 4132  4133 4141
c     19    20    21  22    23         24
c     4211  4221 4222 4231 4132  4233 4241 4242
c     25     26  27   28    29         30   31      
c     4311  4321 4322 4331 4332  4333 4341 4342 4343
c     32    33    34                             
c     4411  4421 4422 4431 4432  4433 4441 4443 4443 4444
c     35    36    37                    
c     5111  5121 5122 5131 5132  5133 5141 5142 5143 5144  5151
c      x     x    x    x    x          x    x               x
c     5211  5221 5222 5231 5132  5233 5241 5242 5243 5244  5251 5252
c      x     x    x    x    x          x    x               x    x
c     5311  5321 5322 5331 5332  5333 5341 5342 5343 5344  5351 5352 5353
c      x     x    x                                       
c     5411  5421 5422 5431 5432  5433 5441 5443 5443 5444  5451 5452 5453 5454
c      x     x    x
c     5511  5521 5522 5531 5532  5533 5541 5543 5543 5544  5551 5552 5553 5554 5555
c      x     x    x
c
c_INCLUDE(common/turtleparam)
c_INCLUDE(../m4/common/sizes)
c_INCLUDE(../m4/common/mapper)
_INCLUDE(../m4/common/iofile)
c
      integer ii,jj,kk,ll,setintpos,nscf,nbasis
c
c     save ikyiky,nocc,nocc1,lbase
c     integer ikyiky(mxorbvb*(mxorbvb+1)/2),nocc,nocc1,lbase
      integer i,j,k,l,ij,ijkl,ibase,icnt,itemp,jtemp
c

      icnt = 0
      if ( ii .le. nocc ) icnt = icnt + 1
      if ( jj .le. nocc ) icnt = icnt + 1
      if ( kk .le. nocc ) icnt = icnt + 1
      if ( ll .le. nocc ) icnt = icnt + 1

      i = max(ii,jj)
      j = min(ii,jj)
      k = max(kk,ll)
      l = min(kk,ll)
      if (k.gt.i .or. ( k.eq.i .and. l.gt.j) ) then
        itemp = i
        i = k
        k = itemp
        jtemp = j
        j = l
        l = jtemp
      end if
      ij = iky(i)+j

      if (k.le.nocc) then
        ijkl = ikyiky(ij)+iky(k)+l
      else if (j.le.nocc .and. l.le.nocc) then
        ijkl = ikyiky(ij)+lbase+nocc*(k-nocc1)+l
      else
        ijkl = 0
      end if

c     if ( icnt .le. 1 .and. ijkl .gt. 0 ) then
c       write(iwr,'(a,4I4,a,4I4,a,I10)') 
c    &  ' 2el integral with 3 or more virt. indexes:',
c    &  ii,jj,kk,ll,' => ',i,j,k,l,' = ',ijkl
c     end if

c     if ( icnt .gt. 1 .and. ijkl .eq. 0 ) then
c       write(iwr,'(a,4I4,a,4I4,a,I10)') 
c    &  ' 2el integral with 2 or less virt. indexes:',
c    &  ii,jj,kk,ll,' => ',i,j,k,l,' = ',ijkl
c     end if


      intpos = ijkl
c
      return
      end
c
      integer function setintpos(nscf,nbasis)
      use ikyg
      implicit none
      integer nscf,nbasis
c
      integer i,j,k,l,ij,ibase,ijkl

c
c...  initialise intpos
c
      nocc = nscf
      if ( nscf .le. 0 ) then
        nocc = nbasis
      end if

      nocc1 = nocc+1
      lbase = nocc*(nocc+1)/2
c
      ij = 0
      ibase = 0
      do i=1,nbasis
         iky(i) = ij
         do j=1,i
            k = i 
            l = k
            if (k.eq.i) l=j
            ij = ij + 1
            ikyiky(ij) = ibase
            ijkl = iky(k)+l
            if (k.le.nocc) then
              ijkl = iky(k)+l
            else if (j.le.nocc) then
              ijkl = lbase+nocc*(k-nocc1)+l
            else
              ijkl = lbase
            end if
            ibase = ibase + ijkl
         end do
      end  do

c!$acc update device (ikyiky,iky,nocc,nocc1,lbase)
      setintpos = ibase
c       
      return
      end

c*******************************************************************************

      subroutine ind4vb(qv,qt,q,lword)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c
c...   qv contains active vectors / qt contains the transposed ones
c...   q is workspace   (of length lword)
c
c...   control routine for the 4-index transformation routines
c...   calls  sort1,calc1,sort2,calc2
c
      dimension  qv(*),qt(*),q(*)
INCLUDE(../m4/common/sizes) 
INCLUDE(common/c8_16vb)
c
INCLUDE(../m4/common/blksiz)
INCLUDE(common/tractlt)
      common/disc/isel(5),ipos(32)
      common/junke/maxt,ires,ipass,nteff,npass1,npass2,
     *             nbuck,mloww,mhi,ntri,iacc
      common/jokex/master,iix,jjx,jfile,junit,jblock,kfile,kunit,kkblok
INCLUDE(../m4/common/mapper)
INCLUDE(../m4/common/files)
      common/blkin/gout(512)
      common/commun/mark(1500),ibase(1500),ibasen(1500)
INCLUDE(../m4/common/iofile)
      save ipassp
      data ipassp/0/
c
      old=cpulft(1)
      if (iprint.gt.10) write(iwr,401)old
401   format(//,' start of 4-index transformation at',f12.3,' secs')
c...
      nsz = nbsort
      nsz512 = nsz*512
      if (n8_16.eq.8) then
         nsz170 = (nsz512-2)/3
         nsz340 = nsz170+nsz170
      else if (n8_16.eq.16) then
         nsz170 = (nsz512-2)/2
         nsz340 = nsz170
      else
         call vberr('unexpected n8_16')
      end if
c
      iix = 1
      jjx = 1
      master = 0
      jfile = 1
      junit = n4tape(jfile)
      jblock = n4blk(jfile)
      kfile = 1
      kunit = n6tape(kfile)
      kkblok = n6blk(kfile)
c....
c...   core partitioning
c...
      iv= lenact
      niqq= iv + max(nsa,nbasis)*nbasis + nsa*nsa
      ihh = niqq
      if (ncurt.gt.0) niqq = niqq + nbasis*nbasis
c...
      if (niqq.gt.lword) call vberr('insufficient core in index4 ')
c...
      call ibasgn(1500,0,nsz340,ibase)
      call ibasgn(1500,0,nsz170,ibasen)
      maxt=(lword-niqq)/lenbas
c***    check
      nword=lword
      nword=(nword/3)*2
      ires=nword/nsz340
      if (ires.lt.1.or.maxt.lt.1) call vberr('insufficent core index4')
      if (ires.gt.1500) ires=1500
c...   determine min. no. of passes for sort1/calc1
102   nteff = (lenbas-1)/npass1+1
      if (((nteff-1)/ires).ge.maxt) then
         npass1=npass1+1
         goto 102
      end if
      if (npass1.ge.lenbas) npass1 = lenbas
      if (iprint.gt.10)  write(iwr,204) '1 ',npass1
_IF(parallel)
c     if (npass1.gt.1) call caserr('parallel multi-pass .. nono')
_ENDIF
c
c...   start calculation
c
      do 1 ipass=1,npass1
c
c... sort
c
         call sort1vb(q,q(nword+1))
         top = cpulft(1)
         if (iprint.gt.10) write(iwr,2222) '1 ',ipass,top
2222     format(/' end of sort',a2,'pass',i6,' at ',f12.3,' secs')
c
c... calc
c
         call calc1vb(q,q(iv+1),q(niqq+1),q(ihh+1),qv,qt)
         top = cpulft(1)
         if (iprint.gt.10) write(iwr,2223) '1 ',ipass,top
2223     format(/' end of calc',a2,'pass',i6,' at ',f12.3,' secs')
c.....
1     continue
c...   complete secondary mainfile  with endfile block
      call search(jblock,junit)
      call put(gout,0,junit)
c
      n4file=jfile
      n4last(jfile) = jblock+1
      if (iprint.gt.10) then
         write(iwr,4007)
4007     format(/' status of secondary mainfile')
         call filprn(jfile,n4blk,n4last,n4tape)
      end if
c
c...   determine min. no. of passes for sort2/calc2
c
202   nteff = (lenact-1)/npass2+1
      if (((nteff-1)/ires).ge.maxt) then
         npass2=npass2+1
         goto 202
      end if
      if (npass2.ge.lenact)  npass2 = lenact
      if (iprint.gt.10) write(iwr,204) '2 ',npass2
204   format(/' no. of sort',a2,'passes=',i4)
      if ((npass1.gt.1.or.npass2.gt.1).and.iprint.le.5.and.ipassp.eq.0) 
     1   then
         ipassp = 1
         write(iwr,205) ' *** multipass 4-index - passes ',
     1                npass1,npass2,' ***'
205   format(a,2i6,a)
      end if
c
c...    start calculation
c
      do 2 ipass=1,npass2
c
c... sort
c
         call sort2vb(q(1),q(nword+1))
         top=cpulft(1)
         if (iprint.gt.10) write(iwr,2222) '2 ',ipass,top
c
c... calc
c
         call calc2vb(q(1),q(iv+1),q(niqq+1),q(ihh+1),qv,qt)
         top = cpulft(1)
         if (iprint.gt.10) write(iwr,2223) '2 ',ipass,top
c.....
2     continue
c...   complete final mainfile  with endfile block
      call search(kkblok,kunit)
      call put(gout,0,kunit)
c
      n6file = kfile
      n6last(kfile) = kkblok+1
c
      call clredx
c
      if (iprint.gt.10) then
         top=cpulft(1)
         write(iwr,300)top
300      format(//' end of 4-index transformation at',
     *          f12.3,' secs'//
     *          ' status of final mainfile')
         call filprn(n6file,n6blk,n6last,n6tape)
      end if
c
      return
      end
      function isort1vb(itri,ktri,gtri)
c
c...   help in sorting  (sort1)
c...   copy integrals needed with indices to gtri/itri/ktri
c...   once straight and once transposed
c...   integrals are produced by gamess, so atmblk parameters used
c
      implicit REAL (a-h,o-z)
INCLUDE(../m4/common/sizes) 
      dimension itri(680),ktri(680),gtri(680)
      common/blkin/gin(510),mword,mdum(3)
INCLUDE(../m4/common/mapper)
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/atmblk)
      common/junke/maxt,ires,ipass,nteff,npass1,npass2,
     *             nbuck,mloww,mhi,ntri,iacc
c**********************************
       common /scra/ ijkl4(4,340)
_IF1(iv)       iv not  catered for in vb (cf index4)
       call izero(mword*4,ijkl4,1)   
       call unpack(gin(num2e+1),lab816,ijkl4,numlab)
c**********************************
      n=0
      do 1 loop=1,mword
_IF(littleendian)
         j = ijkl4(1,loop)
         i = ijkl4(2,loop)
         l = ijkl4(3,loop)
         k = ijkl4(4,loop)
_ELSE
c**********************************
         i = ijkl4(1,loop)
         j = ijkl4(2,loop)
         k = ijkl4(3,loop)
         l = ijkl4(4,loop)
_ENDIF
c**********************************
      itx=iky(i)+j
      ktx=iky(k)+l
      gtx=gin(loop)
      if(mloww.ge.itx.or.mhi.lt.itx)goto 2
      n=n+1
      itri(n)=itx
      ktri(n)=ktx
      gtri(n)=gtx
2     if(mloww.ge.ktx.or.mhi.lt.ktx.or.itx.eq.ktx)goto 1
      n=n+1
      itri(n)=ktx
      ktri(n)=itx
      gtri(n)=gtx
1     continue
      isort1vb=n
      return
      end
      function isort2vb(itri,ktri,gtri)
c
c...  similar to isort1,but for sort2 (so no transpose)
c
      implicit REAL (a-h,o-z) , integer(i-n)
      dimension itri(340),ktri(340),gtri(340)
INCLUDE(common/c8_16vb)
      common/blkin/gin(510),mword,mdumm(3)
      common/junke/maxt,ires,ipass,nteff,npass1,npass2,
     *             nbuck,mloww,mhi,ntri,iacc
INCLUDE(../m4/common/iofile)
c******
ckoos
ckoos      common /scra/ ijkl2(2,340)
      common /scra/ ijij(340),klkl(340)
      call unpack(gin(n340+1),n16_32,ijij,mword*2)
      call unpack(gin(n340+1+n340/(32/n8_16)),n16_32,klkl,mword*2)
c******
      n=0
      do 1 loop=1,mword
ckoos    ij = ijkl2(1,loop)
ckoos    kl = ijkl2(2,loop)
         ij = ijij(loop)
         kl = klkl(loop)
         if (mloww.ge.ij.or.mhi.lt.ij) goto 1
         n=n+1
         gtri(n)=gin(loop)
         itri(n)=ij
         ktri(n)=kl
1     continue
      isort2vb=n
      return
      end
      subroutine jsort1vb
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c...  packer and bucket selector for stacker (integral sorting)
c
INCLUDE(../m4/common/iofile)
INCLUDE(common/c8_16vb)
      common/stak/btri,mlow,nstack,iblock,mstack
      common/scra/ibuk(3400),itxktx4
      common/scrp/nwbuck(1500),itx(3400),ktx(3400),gtx(3400)
      integer*2 itxktx2(2,3400)
      integer*4 itxktx4(2,2550)
      equivalence(itxktx2,itxktx4)
c
      mstack=1
      if  (n16_32.eq.16) then
         do i=1,nstack
            ibuk(i)=(itx(i)-mlow)*btri+1
c           itxktx(i)=shift(itx(i),16).or.ktx(i)
            itxktx2(1,i) = itx(i)
            itxktx2(2,i) = ktx(i)
         end do
      else
         do i=1,nstack
            ibuk(i)=(itx(i)-mlow)*btri+1
            itxktx4(1,i) = itx(i)
            itxktx4(2,i) = ktx(i)
         end do
      end if
c
      return
      end
      subroutine ksort1vb(g,nij,nij8)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c...  fill buckets for stacker
c...  packing was done by jsort1vb
c***   various local mods to get the fortran going (jvl,1987)
c***    can be made more efficient
c
INCLUDE(common/c8_16vb)
      dimension g(*),nij(*),nij8(*)
c
INCLUDE(../m4/common/iofile)
      common/stak/btri,mlow,nstack,iblock,mstack
INCLUDE(../m4/common/blksiz)
      common/scra/ibuk(3400),itxktx(3400)
      common/scrp/nwbuck(1500),itx(3400),ktx(3400),gtx(3400)
      common/commun/mark(1500),ibase(1500),ibasen(1500)
c
      integer*4 nij,itxktx
      integer*8 nij8,itxktx8(2550)
      equivalence(itxktx,itxktx8)
c
1     ibuck = ibuk(mstack)
      ibub  = ibase(ibuck)
c     ibun  = ibasen(ibuck)
c.....ibun is not necessary on a 32 bit integer operating sys.
      nwb   = nwbuck(ibuck) + 1
      nwbuck(ibuck) = nwb
      g(ibub+nwb) = gtx(mstack)
      if  (n16_32.eq.16) then
         nij(ibub+nwb) = itxktx(mstack)
      else
         nij8(ibub+nwb) = itxktx8(mstack)
      endif
      if (nwb.eq.nsz340) return
      mstack=mstack+1
      if(mstack.le.nstack)goto 1
      return
      end
      subroutine mult1(h,r,x,nactiv,nbasis,nsa,q,qt)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c
c..    2-index transformation  h(triangle nbasis) => r(triangle nactiv)
c..    q and qt contain vectors and transposed vectors
c..    x is scratch array of length nactiv*nbasis + nactiv**2
c..    nsa is needed in cases whre you do'nt need all actives (calc2)
c
      dimension h(*),r(*),x(*),q(*),qt(*)
c
c... scale diagonal of   h   by   0.5
c
      do 1 i=1,nbasis
1     h(i*(i+1)/2) = h(i*(i+1)/2)*0.5d0
      nacnba = nsa*nbasis
c
c...   choose algoritm
c
      if(nbasis/2.lt.nactiv) then
c...
c... algorithm 2    use when nbasis/2 lt nactiv
c...
c...      zeroize nactiv*nbasis x matrix and nactiv*nactiv y matrix
         call vclr(x,1,nacnba+nactiv*nactiv)
c...      form x = q(dagger) * h(triangle)
         call mxmtturtle(qt,nsa,h,x,nactiv,nactiv,nbasis)
c...      form y = x * q
         call mxmb(x,1,nactiv,q,1,nbasis,x(nacnba+1),1,nactiv,
     *             nactiv,nbasis,nactiv)
c...      r(triangle) = y + y(dagger)
         call symm1(r,x(nacnba+1),nactiv)
c...
      else
c...
c...      algorithm  1  --  use when nbasis/2 ge nactiv
c...
c...      zeroize nactiv*nbasis x matrix
         call vclr(x,1,nacnba)
c...      form h(triangle) * q
         n=1
         l=1
         do 200 loop=1,nactiv
            m=1
            do 201 moop=1,nbasis
               call daxpy(moop,q(n),h(m),1,x(l),1)
               n=n+1
201         m=m+moop
200      l=l+nbasis
c...      r(triangle)=q(dagger)*x + x(dagger) * q
         m=1
         n=1
         do 300 loop=1,nactiv
            l=1
            do 301 moop=1,loop
             r(m)=ddot(nbasis,q(n),1,x(l),1)+ddotx(nbasis,q(l),1,x(n),
     *1)

               m=m+1
301         l=l+nbasis
300      n=n+nbasis
      end if
c...
      return
      end
      subroutine outblk
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(common/c8_16vb)
c
c
c...   output integrals to intermediate mainfile (from calc1)
c
      common/scrp/ijkl205(680)
INCLUDE(../m4/common/files)
      common/jokex/master,iix,jjx,jfile,junit,jblock,kfile,kunit,kkblok
      common/blkin/gout(510),mword,mdumm(3)
      common/disc/isel(5),ipos(32)
c
      if (ipos(junit).ne.jblock) call search(jblock,junit)
c
      call pack(gout(n340+1),n16_32,ijkl205,n340*2)
      call put(gout(1),511,junit)
      mword=0
      jblock=jblock+1
c
      if (jblock.eq.n4last(jfile)) then
c...      change channel
         jfile=jfile+1
         if (jfile.gt.n4file)
     *    call vberr(' too many sfile units needed in outblk ')
         junit=n4tape(jfile)
         jblock=n4blk(jfile)
      end if
c
      return
      end
      subroutine outbll
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
INCLUDE(../m4/common/sizes)
INCLUDE(common/c8_16vb)
c
c
c..    output integrals to final mainfile (from calc2)
c
INCLUDE(../m4/common/files)
      common/jokex/master,iix,jjx,jfile,junit,jblock,kfile,kunit,kkblok
      common/blkin/gout(510),mword,mdumm(3)
      common/scrp/ijkl205(680)
      common/disc/isel(5),ipos(32)
c
      if (ipos(kunit).ne.kkblok) call search(kkblok,kunit)
c
      call pack(gout(n340+1),n16_32,ijkl205,n340*2)
      call put(gout(1),511,kunit)
      mword = 0
      kkblok = kkblok+1
c
      if (kkblok.eq.n6last(kfile)) then
c...    end of this tape / take next one
        kfile = kfile + 1
        if (kfile.gt.n6file)
     *    call vberr(' too many ffile units needed in outbll ')
        kunit = n6tape(kfile)
        kkblok = n6blk(kfile)
      end if
c
      return
      end
      subroutine sgmatvb(fock,p)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c*******************************************************************
c**             sgmat      taken from scf                         **
c**     requires a few changes (back) in calling routines         **
c**    originally crayscs (old atmol cray scf - 1982)             **
c**    modernised and adapted to  i1,j1,k1,l1,i2,j2,k2,l2 pack    **
c**    for nos/ve  / joop van lenthe   january 1987               **
c*******************************************************************
c...   integrals are produced by gamess, so atmblk parameters used
INCLUDE(../m4/common/sizes) 
      dimension p(*),fock(*)
      common/blkin/gg(510),mword,mdumm(3)
INCLUDE(../m4/common/mapper)
INCLUDE(../m4/common/atmblk)
c*********
      common /scra/ ijkl(4,340)
      call izero(mword*4,ijkl,1)
      call unpack(gg(num2e+1),lab816,ijkl,mword*4)
c*********
_IF(littleendian)
      do 6000 iw=1,mword
         j = ijkl(1,iw)
         i = ijkl(2,iw)
         l = ijkl(3,iw)
         k = ijkl(4,iw)
_ELSE
      do 6000 iw=1,mword
         i = ijkl(1,iw)
         j = ijkl(2,iw)
         k = ijkl(3,iw)
         l = ijkl(4,iw)
_ENDIF
c*********
         gik=gg(iw)
         g2=gik+gik
         g4=g2+g2
         ikyi=iky(i)
         ikyj=iky(j)
         ikyk=iky(k)
         ik=ikyi+k
         il=ikyi+l
         ij=ikyi+j
         jk=ikyj+k
         jl=ikyj+l
         kl=ikyk+l
         aij=g4*p(kl)+fock(ij)
         fock(kl)=g4*p(ij)+fock(kl)
         fock(ij)=aij
c... exchange
         gil=gik
         if(i.eq.k.or.j.eq.l)gik=g2
         if(j.eq.k)gil=g2
         if(j.ge.k)goto 1
         jk=ikyk+j
         if(j.ge.l)goto 1
         jl=iky(l)+j
1        ajk=fock(jk)-gil*p(il)
         ail=fock(il)-gil*p(jk)
         aik=fock(ik)-gik*p(jl)
         fock(jl)=fock(jl)-gik*p(ik)
         fock(jk)=ajk
         fock(il)=ail
6000  fock(ik)=aik
c
      return
      end
      subroutine shcbld(s,h,qv,qvt,x2,x3,x1)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c...
c...   build s and (frozen-core) h-matrix for vb
c...   sets core and pot_nuc in /ffile/
c...   modification of corbld (atmol-4-index)
c...   s must be dimensioned big enough to hold ao-basis s-matrix
c...   qv must be hold all the vectors qvt the transposed active vectors
c...   x1(triangle) / x2(triangle or  nsa*(nbasis+nsa) / x3(triangle)
c...
INCLUDE(../m4/common/sizes)
INCLUDE(common/turtleparam)
      dimension s(*),h(*),qv(*),qvt(*),x1(*),x2(*),x3(*)
c...
INCLUDE(common/tractlt)
INCLUDE(../m4/common/mapper)
INCLUDE(../m4/common/files)
INCLUDE(common/ffile)
INCLUDE(common/splice)
INCLUDE(common/scftvb)
      common/blkin/gg(340),gmij(170),mword,mdumm(3)
INCLUDE(../m4/common/iofile)
_IF(linux)
      external fget
_ENDIF 
      do i=1,maxorb
         iky(i) = i*(i-1)/2
      end do
c
c...    read s and (modified) h integrals from dumpfile
c
      call get1e(s,dummy,'s',s)
      call get1e(x3,core,'h',x1)
c
      pot_nuc = core
c...    s -matrix and suitably modified h-matrix are now in s and x3
      if(ncore.ne.0) then
c...     build frozen-core density-matrix
         call vclr(x1,1,lenbas)
         do 2 k=1,ncore
            mm = (k-1) * nbasis
            m=0
            do 2 i=1,nbasis
               top= qv(mm+i)
               x2(i)=top
               call daxpy(i,top,x2,1,x1(m+1),1)
2        m=m+i
         do 3 i=1,nbasis
3        x1(iky(i+1)) = x1(iky(i+1))*0.5d0
c ...    core rho(density matrix) in x1
         top=ddot(lenbas,x1,1,x3,1)
c...     build core fock operator
         call vclr(x2,1,lenbas)
         do 20113 i=1,n2file
            lbl=n2blk(i)
            if (lbl.eq.n2last(i)) go to 20113
            iunit=n2tape(i)
            call search(n2blk(i),iunit)
68          call fget(gg,k,iunit)
            if (k.ne.0) then
               call sgmatvb(x2,x1)
               lbl=lbl+1
               if (lbl.ne.n2last(i)) go to 68
            end if
20113    continue
c
_IF(parallel)
         call pg_dgop(24,x2,lenbas,'+')
_ENDIF
         call vadd(x3,1,x2,1,x3,1,lenbas)
         top=ddot(lenbas,x1,1,x3,1)+top
         core=top+top+core
      end if
c....
c....    transform (modified) h-matrix
c....
        call mult1(x3,h,x2,nsa,nbasis,nsa,qv(nbasis*ncore+1),qvt)
c....
c....    transform s-matrix
c....
        call fmove(s,x3,lenbas)
        call mult1(x3,s,x2,nsa,nbasis,nsa,qv(nbasis*ncore+1),qvt)

c	call gmem_check_guards('shcbld na mult1 ')
c....
      if (iprint.gt.10) then
         write(iwr,600) cpulft(1),core
600      format(/' end of 2-index transformation at',f14.4,' seconds',
     *          /'  the effective nuclear repulsion is ',e20.13)
      end if
c....
      return
      end
      subroutine sort1vb(g,nij)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
INCLUDE(../m4/common/sizes)
c
c
c...   sorts mainfile --- so that for a
c...   given rs comb. al pq combs. available
c
       REAL g(*),nij(*)
c
INCLUDE(common/tractlt)
INCLUDE(../m4/common/blksiz)
      common/junke/maxt,ires,ipass,nteff,npass1,npass2,
     *             nbuck,mloww,mhi,ntri,iacc
      common/jokex/master,iix,jjx,jfile,junit,jblock,kfile,kunit,kkblok
      common/scrp/nwbuck(1500),itx(3400),ktx(3400),gtx(3400)
      common/stak/btri,mlow,nstack,iblock,mstack
      common/bufvi1/nwbnwb,lnklnk,gout(12286),idumi1,idumi11
      common/commun/mark(1500),ibase(1500),ibasen(1500)
INCLUDE(../m4/common/files)
INCLUDE(../m4/common/iofile)
      common/blkin/gin(340),gij(170),mword,mdumm(3)
_IF(linux)
      external fget
_ENDIF 
c
c...   determine base and limit triangles for this pass
c
      mloww=master
      mhi=master+nteff
      mlow=mloww+1
      if(mhi.gt.lenbas)mhi=lenbas
      mtri=mhi-mlow
c
c...   determine minimum no. of bucks.
c
      nbuck=ires
400   ntri=mtri/nbuck
      if (ntri.lt.maxt) then
         nbuck=nbuck-1
         if (nbuck.gt.0) go to 400
      end if
      nbuck=nbuck+1
_IF(parallel)
      nbuck = (1+nbuck/ipg_nnodes())*ipg_nnodes()
      if (ipg_nnodes().eq.1) nbuck = max(nbuck,3)
_ENDIF
      ntri=mtri/nbuck+1
      btri=ntri
      btri=1.000000001d0/btri
c...   ntri=max. no. of triangles controlled by 1 bucket
c...   nbuck=number of buckets
      call setsto(nbuck,9999999,mark)
      call setsto(nbuck,0,nwbuck)
      nstack=0
c...   iblock for nos/ve starts at 1
      iblock= 1
      nwbnwb=nsz340
c...   start loop over mainfile blocks
      do 20113 ifile=1,n2file
         lbl=n2blk(ifile)
         if (lbl.eq.n2last(ifile)) go to 20113
         iunit=n2tape(ifile)
         call search(n2blk(ifile),iunit)
20110    call fget(gin,m,iunit)
           if (m.eq.0) go to 20113
c...     process input block
           nnn=isort1vb(itx(nstack+1),ktx(nstack+1),gtx(nstack+1))
           nstack=nstack+nnn
c...       2721 leaves enough space for an integral record (more for 16 bits packing)
           if(nstack.ge.2721)call stacker(g,nij)
           lbl=lbl+1
         if (lbl.ne.n2last(ifile)) go to 20110
20113 continue
c...   mainfile now swept ---- now clear up output
      if (nstack.ne.0) call stacker(g,nij)
      do 7 ibuck=1,nbuck
         nwb=nwbuck(ibuck)
         if (nwb.gt.0) then
            call stopbk
            nwbnwb=nwb
            lnklnk=mark(ibuck)
            call fmove(g(ibase(ibuck)+1),gout,nwb)
            call fmove(nij(ibasen(ibuck)+1),gout(nsz340+1),nsz170)
ci4         call icopy(2*nsz170,nij(ibase(ibuck)+1),1,
ci4  +                 gout(nsz340+1),1)
            call sttoutvb(iblock)
            mark(ibuck)=iblock
            iblock=iblock+nsz
         end if
7     continue
c
      return
      end
      subroutine sort2vb(g,nij)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c
c...   sorts secondary mainfile ---so that
c...   for a given ij comb. all rs combs. available
c
INCLUDE(../m4/common/sizes) 
      REAL g(*),nij(*)
INCLUDE(../m4/common/blksiz)
INCLUDE(../m4/common/mapper)
      common/junke/maxt,ires,ipass,nteff,npass1,npass2,
     *             nbuck,mloww,mhi,ntri,iacc
      common/jokex/master,iix,jjx,jfile,junit,jblock,kfile,kunit,kkblok
      common/scrp/nwbuck(1500),itx(3400),ktx(3400),gtx(3400)
      common/stak/btri,mlow,nstack,iblock,mstack
      common/bufvi1/nwbnwb,lnklnk,gout(12286),idumi1,idumi11
INCLUDE(common/tractlt)
      common/blkin/gin(340),gij(170),mword,mdumm(3)
      common/commun/mark(1500),ibase(1500),ibasen(1500)
INCLUDE(../m4/common/files)
INCLUDE(../m4/common/iofile)
_IF(linux)
      external fget
_ENDIF 
c
c...   determine base and limit triangles for this pass
c
      mlow=iky(iix)+jjx
      mloww=mlow-1
      mhi=mloww+nteff
      if (mhi.gt.lenact) mhi=lenact
      mtri=mhi-mlow
c...   determine minimum no. of bucks.
      nbuck=ires
400   ntri=mtri/nbuck
      if(ntri.lt.maxt) then
         nbuck=nbuck-1
         if (nbuck.ne.0) go to 400
      end if
      nbuck=nbuck+1
_IF(parallel)
      nbuck = (1+nbuck/ipg_nnodes())*ipg_nnodes()
_ENDIF
      ntri=mtri/nbuck+1
      btri=ntri
      btri=1.000000001d0/btri
c...   ntri=max. no. of triangles controlled by 1 bucket
c...   nbuck=number of buckets
      call setsto(nbuck,9999999,mark)
      call setsto(nbuck,0,nwbuck)
      nstack=0
c     iblock=0      for 205     1 for nosve
      iblock = 1
      nwbnwb=nsz340
c
c...   start loop over secondary mainfile blocks
c
      do 20113 ifile=1,n4file
         iunit = n4tape(ifile)
         lbl = n4blk(ifile)
         call search(n4blk(ifile),iunit)
20110    call fget(gin,m,iunit)
         if (m.ne.0) then
c...   process input block
            nnn=isort2vb(itx(nstack+1),ktx(nstack+1),gtx(nstack+1))
            nstack=nstack+nnn
            if (nstack.ge.3061) call stacker(g,nij)
            lbl=lbl+1
            if (lbl.ne.n4last(iunit)) go to 20110
         end if
20113 continue
c...   secondary mainfile now swept   -   clear up output
      if (nstack.ne.0) call stacker(g,nij)
      do 7 ibuck=1,nbuck
         nwb=nwbuck(ibuck)
         if (nwb.ne.0) then
            call stopbk
            nwbnwb=nwb
            lnklnk=mark(ibuck)
            call fmove(g(ibase(ibuck)+1),gout,nwb)
            call fmove(nij(ibasen(ibuck)+1),gout(nsz340+1),nsz170)
ci4         call icopy(2*nsz170,nij(ibase(ibuck)+1),1,
ci4  +                 gout(nsz340+1),1)
            call sttoutvb(iblock)
            mark(ibuck)=iblock
            iblock=iblock+nsz
         end if
7     continue
c
      return
      end
      subroutine stacker(g,nij)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
c...   process integrals in sorting
      REAL g(*),nij(*)
c
      common/stak/btri,mlow,nstack,iblock,mstack
      common/scrp/nwbuck(1500),itx(3400),ktx(3400),gtx(3400)
INCLUDE(../m4/common/blksiz)
      common/bufvi1/nwbnwb,lnklnk,gout(12286),idumi1,idumi11
      common/commun/mark(1500),ibase(1500),ibasen(1500)
      common/scra/ibu(3400),itxktx(3400)
INCLUDE(../m4/common/iofile)
c
      call jsort1vb
c
3     call ksort1vb(g,nij,nij)
      if (mstack.le.nstack) then
         ibuck=ibu(mstack)
         call stopbk
         lnklnk=mark(ibuck)
         call fmove(g(ibase(ibuck)+1),gout,nsz340)
         call fmove(nij(ibasen(ibuck)+1),gout(nsz340+1),nsz170)
ci4         call fmove(nij(ibase(ibuck)+1),gout(nsz340+1),nsz170)
         call sttoutvb(iblock)
         nwbuck(ibuck)=0
         mark(ibuck)=iblock
         iblock=iblock+nsz
         mstack=mstack+1
         if (mstack.le.nstack) go to 3
      end if
c
      nstack=0
c
      return
      end
      subroutine rdbakvb(iblock,gin)
c
c...   read sort_file record
c
      implicit REAL (a-h,o-z)
c
      dimension gin(*)
c
INCLUDE(../m4/common/blksiz)
c**      common/stak/btri,mlow,nstack,iblock,mstack
      common /disc/ isel,iselr,iselw,irep
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/vcore)
INCLUDE(common/tractlt)
c
      if (incsort) then
         call fmove(Q(ksort+nsz512*(iblock-1)),gin,nsz512)
      else
         call srchcc(nsort,iblock,irep)
         if (irep.ne.0) call ioerr('rdbakvb',iblock,'search error at ')
         call getccn(nsort,gin,nsz,irep)
         if (irep.ne.0) call ioerr('rdbakvb',iblock,'error at ')
      endif
c
      return
      end
      subroutine sttoutvb(iblock)
c
c     write sortfile record
c
      implicit REAL (a-h,o-z)
c**      common/stak/btri,mlow,nstack,iblock,mstack
INCLUDE(../m4/common/blksiz)
      common /bufvi1/ gout(12288)
      common /disc/ isel,iselr,iselw,irep
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/vcore)
INCLUDE(common/tractlt)
c
      if (incsort) then
         call fmove(gout,Q(ksort+nsz512*(iblock-1)),nsz512)
         maxsort = max0(maxsort,iblock)
      else
         call srchcc(nsort,iblock,irep)
         if (irep.ne.0) call ioerr('sttoutvb',iblock,'search error at ')
         call putccn(nsort,gout,nsz,irep)
         if (irep.ne.0) call ioerr('sttoutvb',iblock,'error at ')
      endif
c
cFD to make gamess aware of lenght sortfile
c
      nslen = nslen + nsz
      return
      end
