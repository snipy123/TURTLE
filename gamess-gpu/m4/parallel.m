
c  $Author: jmht $
c  $Date: 2013-05-27 14:27:44 +0200 (Mon, 27 May 2013) $
c  $Locker:  $
c  $Revision: 6287 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/parallel.m,v $
c  $State: Exp $
c  
c ======================================================================
c
c  ** pg_begin : initialise parallel processing
c
      subroutine pg_begin
      implicit none
_IF(_AND(ga,mpi))
c
c     This is similar to the static load-balancing MPI implementation
c     except:
c     - we use global arrays as well
c     - we use a global array for the global counter
c
      include 'mpif.h'
INCLUDE(common/parcntl)
c
c     Note there is no guarantee that standard MPI variables and constants
c     will not be promoted. Therefore all MPI related variables need to be
c     copied to local variables of the appropriate type for the MPI 
c     interface.
c
INCLUDE(common/mpidata)
INCLUDE(common/mpistatus)
c
c     Locally all variables to be passed to MPI routines are declared
c     of type MPIINT or MPILOG and end in _mpi.
c
      integer icode
c
c     GA+MPI version
c
      MPIINT ierr_mpi, maxabs_mpi
      MPIINT icomm_gamess_mpi, icomm_workers_mpi
      MPILOG olog_mpi
      integer ierr
      integer n
      integer dummy
      logical test_verb
      external maxabs

_IF(chemshell)
c     Note GA+MPI version not yet checked for compatibility
c     with split communicators
      integer gamess_chemsh_comm
      external gamess_chemsh_comm
      MPI_COMM_GAMESS=gamess_chemsh_comm()
_ELSEIF(charmm)
      MPI_COMM_GAMESS=MPI_COMM_WORLD
_ELSEIF(taskfarm)
      call get_communicator(MPI_COMM_GAMESS)
c     MPI_COMM_GAMESS=comm
_ELSE
      MPI_COMM_GAMESS=MPI_COMM_WORLD
      call MPI_INIT(ierr_mpi)
      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('init',ierr)
_ENDIF
* For newscf need to set up a BLACS context
_IF(newscf)
_IF(chemshell)
c Assign BLACS context from communicator passed from ChemShell
c Do not call blacs_get as it can only get MPI world
      blacs_context = MPI_COMM_GAMESS
_ELSEIF(taskfarm)
      call get_context( blacs_context )
_ELSE
      call blacs_get( dummy, 0, blacs_context )
_ENDIF
_ENDIF
_IF(taskfarm)
      is_farm = .True.
_ELSE
      is_farm = .False.
_ENDIF
      mpisnd = -1
      mpircv = -1

      call push_verb(1)
c
c     create an new MPI_MAXABS handle for use in pg_dgop
c
      olog_mpi = .true.
      call MPI_op_create(maxabs,olog_mpi,maxabs_mpi,ierr_mpi)
      MPI_MAXABS = maxabs_mpi
      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('mpi_op_create mpi_maxabs',ierr)
*
*  Still need the workers communicator in certain cases - I.J.B.
*
      icomm_gamess_mpi = MPI_COMM_GAMESS
      Call MPI_comm_dup( icomm_gamess_mpi, icomm_workers_mpi, ierr_mpi )
      MPI_COMM_WORKERS = icomm_workers_mpi
      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('comm_dup',ierr)

      call pg_init
      ga_initted = .false.

c     if(test_verb(1))then
c        write(6,*)'static lb: worker started'
c     endif

_ELSEIF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
INCLUDE(common/mpistatus)
      integer icode
      external maxabs
_IF(dynamic)
c
c  this version assumes a process has been set aside for
c  global index serving
c
      MPIINT maxabs_mpi
      MPIINT istat_mpi(MPI_STATUS_SIZE), integer_mpi
      MPIINT ierr_mpi, ierr1_mpi, ierr2_mpi, ierr4_mpi
      MPIINT ifrom_mpi
      logical more
      integer ierr1, ierr2, ierr3, ierr4, ierr, n, nw, i, k, iw, ifrom
      Integer me, ic

      logical debug
_IF(debug)
      data debug/.true./
_ELSE
      data debug/.false./
_ENDIF(debug)

      integer linfo
      parameter(linfo=2*max_processors)
      integer info(2,0:max_processors - 1)

      MPIINT union_membership_number_mpi( 0:max_processors - 2 )
      MPIINT all_group_mpi, the_union_mpi ! i.e. a group of workers
      MPIINT i1_mpi, i971_mpi, i972_mpi, iany_source_mpi
      MPIINT linfo_mpi, iw_mpi, n_mpi, me_mpi, nm1_mpi
      MPIINT icomm_gamess_mpi, icomm_workers_mpi
      MPILOG log_mpi

      logical test_verb

_IF(chemshell)
      integer gamess_chemsh_comm
      external gamess_chemsh_comm
      MPI_COMM_GAMESS=gamess_chemsh_comm()
_ELSEIF(charmm)
      MPI_COMM_GAMESS=MPI_COMM_WORLD
_ELSE
      call MPI_INIT(ierr_mpi)
      MPI_COMM_GAMESS=MPI_COMM_WORLD
      call push_verb(1)
_ENDIF

      mpisnd = -1
      mpircv = -1

      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('init',ierr)
*
*  Need to know how big the job is to set up the secondary
* communicator - I.J.B.
*
      icomm_gamess_mpi = MPI_COMM_GAMESS
      call mpi_comm_size( icomm_gamess_mpi, n_mpi , ierr1_mpi)
      call mpi_comm_rank( icomm_gamess_mpi, me_mpi, ierr2_mpi)
      If( ierr1_mpi .NE. 0 .OR .ierr2_mpi .NE. 0 ) Then
         call caserr( 'bad initialisation' )
      End If
      n  = n_mpi
      me = me_mpi

cjmht This can never work on less than two processors so let the poor user
c     know rather than have them wait around forever. We need to set 
c     MPI_COMM_WORKERS as this is used in ipg_nodeid (called by gamerr)
      If( n .LE. 1 ) Then
         MPI_COMM_WORKERS=MPI_COMM_GAMESS
         Call caserr( 'Dynamic MPI code requires > 1 processor to run' )
      End If
      
*
*  Set up The MPI_COMM_WORKERS communicator - I.J.B.
*
      Do i = 0, n - 2
         union_membership_number_mpi( i ) = i
      End Do

cjmht - This was MPI_comm_world, but I am sure this should be MPI_COMM_GAMESS
      icomm_gamess_mpi = MPI_COMM_GAMESS
      Call MPI_comm_group( icomm_gamess_mpi, all_group_mpi, ierr_mpi )
      If( ierr_mpi .NE. 0 ) Then
         Call caserr( 'bad initialisation of MPI_COMM_WORKERS' )
      End If

      nm1_mpi = n-1
      Call MPI_group_incl( all_group_mpi, nm1_mpi,
     +                     union_membership_number_mpi,
     +                     the_union_mpi, ierr_mpi )
      If( ierr_mpi .NE. 0 ) Then
         Call caserr( 'bad initialisation of MPI_COMM_WORKERS' )
      End If

      icomm_gamess_mpi = MPI_COMM_GAMESS
      Call MPI_comm_create( icomm_gamess_mpi , the_union_mpi, 
     +                      icomm_workers_mpi, ierr_mpi )
      MPI_COMM_WORKERS = icomm_workers_mpi
      If( ierr_mpi .NE. 0 ) Then
         Call caserr( 'bad initialisation of MPI_COMM_WORKERS' )
      End If
c
c  first we must ensure that the communicators are
c  correct

      nw = n - 1
      If( me .NE. nw ) Then
         icomm_workers_mpi = MPI_COMM_WORKERS
         call mpi_comm_rank( icomm_workers_mpi, iw_mpi, ierr2_mpi )
         iw = iw_mpi
      End If
      ierr4     = 0
      ierr4_mpi = ierr4


      If( me .EQ. nw ) Then
         do i = 0,max_processors - 1
            do k=1,2
               info(k,i) = 0
            enddo
         enddo

         if(debug)write(6,*)'i am the global counter'
         if(debug)write(6,*)'there are ',n-1,' workers'
c
c simple global counter
c icode = 1  counter request
c         2  serve an index
c         3  close down
c
         ic = 0
         more = .true.
         do while (more)
c
c   wait for a message from any node ...
c  
            if(debug)write(6,*)'post rcv 971'
_IF(i8)
            integer_mpi = MPI_INTEGER8
_ELSE
            integer_mpi = MPI_INTEGER4
_ENDIF
            i1_mpi = 1
            i971_mpi = 971
            i972_mpi = 972
            iany_source_mpi = MPI_ANY_SOURCE
            icomm_gamess_mpi = MPI_COMM_GAMESS
            call mpi_recv(icode ,i1_mpi, integer_mpi, iany_source_mpi,
     &           i971_mpi,icomm_gamess_mpi,istat_mpi,ierr_mpi)
            ifrom = istat_mpi( MPI_source )
            ierr = ierr_mpi
            if(debug)write(6,*)'get code ',icode,' from ',ifrom
c
c   act on it
c
            if (ierr.ne.0)then
               call pg_errmsg('recv',ierr)
            else if (icode.eq.-1)then
c
c  counter reset
c
               ic = 0
*               call debugp('pg_dlbreset: global counter reset')
               ifrom_mpi = ifrom
               icomm_gamess_mpi = MPI_COMM_GAMESS
               call mpi_send(icode ,i1_mpi, integer_mpi, ifrom_mpi,
     &              i972_mpi,icomm_gamess_mpi,ierr_mpi)

            else if (icode.eq.-2)then
c
c  end of while loop
c
               more = .false.
            else if (icode.eq.-3)then
c
c  stats call
c
               linfo_mpi = linfo
               ifrom_mpi = ifrom
               icomm_gamess_mpi = MPI_COMM_GAMESS
               call MPI_SEND(info,linfo,integer_mpi, ifrom_mpi,i972_mpi,
     &              icomm_gamess_mpi,ierr_mpi)
               ierr = ierr_mpi
               if (ierr.ne.0) call pg_errmsg('send',ierr)

            else
c
c  increment and send
c
               ic = ic + 1
               ifrom_mpi = ifrom
               icomm_gamess_mpi = MPI_COMM_GAMESS
               call MPI_SEND(ic,i1_mpi,integer_mpi, ifrom_mpi,i972_mpi,
     &              icomm_gamess_mpi,ierr_mpi)
               ierr = ierr_mpi
               if (ierr.ne.0) call pg_errmsg('send',ierr)
               info(1,ifrom) = info(1,ifrom) + 1
               info(2,ifrom) = info(2,ifrom) + icode
c
c  then skip chunked parameters
c
               ic = ic + icode - 1
               if(debug)write(6,*)'send index ',ic,' icode was',icode,
     &              'next ic',ic
            endif
         enddo

         icode = 0
         call MPI_FINALIZE(ierr_mpi)
         call exitc(0)

      else if(ierr4 .eq. 0)then
c
c normal worker process 
c
        if(test_verb(1))then
            if(debug)write(6,*)'dynamic lb: worker started'
        endif
      else
         call caserr('bad worker initialisation')
      endif
_ELSEIF(dynamic_mpi2)
c
c MPI2 dynamic balancing version
c
      MPIINT maxabs_mpi
      MPIINT iprovided_mpi, ierr_mpi, comm_mpi
      MPIINT icomm_gamess_mpi, icomm_workers_mpi
      MPIINT ithread_mult_mpi
      integer ierr
      integer n
      integer iprovided
      logical test_verb

_IF(chemshell)
      integer gamess_chemsh_comm
      external gamess_chemsh_comm
      MPI_COMM_GAMESS=gamess_chemsh_comm()
_ELSEIF(charmm)
      MPI_COMM_GAMESS=MPI_COMM_WORLD
_ELSEIF(taskfarm)
      call get_communicator(MPI_COMM_GAMESS)
_ELSE
      MPI_COMM_GAMESS=MPI_COMM_WORLD
      ithread_mult_mpi = MPI_THREAD_MULTIPLE
      call MPI_INIT_THREAD(ithread_mult_mpi,iprovided_mpi,ierr_mpi)
      if (iprovided_mpi.eq.ithread_mult_mpi) then
        call create_thread
      endif
      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('init',ierr)
_ENDIF

      mpisnd = -1
      mpircv = -1

      call push_verb(1)

*  Still need the workers communicator in certain cases - I.J.B.
*
      icomm_gamess_mpi = MPI_COMM_GAMESS
      Call MPI_comm_dup( icomm_gamess_mpi, icomm_workers_mpi, ierr_mpi )
      MPI_COMM_WORKERS = icomm_workers_mpi
      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('comm_dup',ierr)

      if(test_verb(1))then
         write(6,*)'MPI2 dynamic lb: worker started'
      endif

*Need to initialize the counter
      Call init_nxtval_mpi2

_ELSE
c
c MPI static load balancing version
c
      MPIINT ierr_mpi, maxabs_mpi
      MPIINT icomm_gamess_mpi, icomm_workers_mpi
      MPILOG log_mpi
      integer ierr
      integer n
      integer dummy
      logical test_verb

_IF(chemshell)
      integer gamess_chemsh_comm
      external gamess_chemsh_comm
      MPI_COMM_GAMESS=gamess_chemsh_comm()
_ELSEIF(charmm)
      MPI_COMM_GAMESS=MPI_COMM_WORLD
_ELSEIF(taskfarm)
      call get_communicator(MPI_COMM_GAMESS)
_ELSE
      MPI_COMM_GAMESS=MPI_COMM_WORLD
      call MPI_INIT(ierr_mpi)
      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('init',ierr)
_ENDIF

* For newscf need to set up a BLACS context
_IF(newscf)
_IF(chemshell)
c Assign BLACS context from communicator passed from ChemShell
c Do not call blacs_get as it can only get MPI world
      blacs_context = MPI_COMM_GAMESS
_ELSEIF(taskfarm)
      call get_context( blacs_context )
_ELSE
      call blacs_get( dummy, 0, blacs_context )
_ENDIF
_ENDIF
_IF(taskfarm)
      is_farm = .True.
_ELSE
      is_farm = .False.
_ENDIF
      mpisnd = -1
      mpircv = -1

      call push_verb(1)

*  Still need the workers communicator in certain cases - I.J.B.
*
      icomm_gamess_mpi = MPI_COMM_GAMESS
      Call MPI_comm_dup( icomm_gamess_mpi, icomm_workers_mpi, ierr_mpi )
      MPI_COMM_WORKERS = icomm_workers_mpi
      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('comm_dup',ierr)

c     if(test_verb(1))then
c        write(6,*)'static lb: worker started'
c     endif

_ENDIF
c
c     create an new MPI_MAXABS handle for use in pg_dgop
c
      log_mpi = .true.
      call MPI_op_create(maxabs,log_mpi,maxabs_mpi,ierr_mpi)
      MPI_MAXABS = maxabs_mpi
      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('mpi_op_create mpi_maxabs',ierr)
_ELSEIF(tcgmsg)
INCLUDE(common/parcntl)
_IF(tcgmsg-mpi)
c paul hack
      include 'mpif.h'
INCLUDE(common/mpidata)
      MPIINT ierr_mpi
      MPIINT icomm_gamess_mpi, icomm_workers_mpi
      integer ierr
c paul hack
_ENDIF(tcgmsg-mpi)
      logical opg_root
      odebugp = .false.
      call debugp('pg_begin')
_IFN(chemshell,charmm,taskfarm)
      call PBEGINF
_ENDIF
_IF(tcgmsg-mpi)
c paul hack

      MPI_COMM_GAMESS=MPI_COMM_WORLD

      icomm_gamess_mpi = MPI_COMM_GAMESS
      Call MPI_comm_dup( icomm_gamess_mpi, icomm_workers_mpi, ierr_mpi )
      MPI_COMM_WORKERS = icomm_workers_mpi

      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('comm_dup',ierr)
c paul hack
_ENDIF(tcgmsg-mpi)
      ga_initted = .false.
_ELSEIF(pvm)
	call caserr('pvm')
_ENDIF

c - other node parameters

      call pg_init

      return
      end

_IF(ga,ma)
      subroutine  guk_ma_init(size)
      implicit none
      integer size
#include "mafdecls.fh"
c
c     Initialise the MA library by allocating a heap of memory of
c     'size' numbers of the datatype MT_DBL. 
c     No handle is returned, instead memory is allocated using the
c     MA_alloc_get function, which returns an index into one of the 
c     arrays stored in the mbc_int, mbd_double etc, common blocks
c     that are included wtih mafdecls.fh
c
      MA_LOGICAL value
      MA_INTEGER i1, i2, i3
      call debugp('guk_ma_init')
      i1 = MT_DBL
      i2 = 1
      i3 = size
      if(.not.ma_initialized()) then
        value = ma_init(i1,i2,i3)
        if(.not.value)call caserr('ma init')
      endif
      return
      end
_ENDIF(ga,ma)
c
c ======================================================================
c
c subroutine pg_ga_begin : intialise GA storage
c
c  allocate memory for globals arrays. For machines without data servers
c  this is postponed till after initj to allow the memory to be set in
c  the input file
c
      subroutine  pg_ga_begin(size)
      implicit none
INCLUDE(common/parcntl)
INCLUDE(common/sizes)
INCLUDE(common/gmemdata)
      integer size
_IF(ga)
      integer ipg_nodeid, ipg_nnodes
_IFN(chemshell)
      if( .not. ga_initted) then
         call debugp('pg_ga_begin')
         call guk_ma_init(size) 
         call ga_initialize()
      endif
_ENDIF
      call set_nodinf
      if (.not. ga_initted) then
        call pg_dlbcreate
      endif
      ga_initted = .true.
_ENDIF
      igamem_totsize = 0
      return
      end
c
c this is to evade name clash between nnodes in common/nodinf
c and the tcgmsg function
c
      subroutine set_nodinf
      implicit none
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
      integer ipg_nodeid, ipg_nnodes
      mpid = 0
      minode = ipg_nodeid()
      mihost = 0
      nnodes = ipg_nnodes()
      nodscr = 1
      return
      end
c
c ========================================================================
c
c   pg_init: set parameters needed for  node process
c 

      subroutine pg_init
      implicit none
c
INCLUDE(common/sizes)
INCLUDE(common/parallel)
INCLUDE(common/parcntl)
      integer ipg_nnodes
_IF(ga)
_IFN(t3d,ipsc,rs6000)
      integer nn, id, nodeid, nnodes
_ENDIF
_ENDIF
c
      call set_nodinf
c
      call debugp('pg_init')
c
c use parallel diag for n > num nodes
      idpdiag = max(ipg_nnodes(),200)
c use PeIGS by default (except when the newscf F90 module
c is available with ScaLAPACK)
_IF(_AND(newscf,scalapack))
      ipdiagmode = IDIAG_PDSYEV
_ELSE
      ipdiagmode = IDIAG_PEIGS
_ENDIF(newscf)
c
c
c   Inversion algorithm
chvd
c     choose the old method by default for now until the new method 
c     has been suitably tested.
c     ipinvmode  = INV_CHOLESKY
      ipinvmode  = INV_DIAG
chvd
c
c use parallel linear algebra for n > 200
      idpdiis = 200
c
c    note that the ga orthog routine causes problems in
c    geometry optimisations .. this is now disabled in
c    start as a function of runtype until this is rationalised
       idporth = 200
c
       idpmult2 = 200
c aim for 40 chunks per scf
       ntchnk = 40
c limit on chunk size
       limchnk = -1
c dont do parallel tests
       iptest = 0
c
c I/O mode default is node zero i/o 
c screening out of parts of SCF to reduce comms
c is supressed pending further work
c
      ipiomode = IO_NZ
c
c dynamic lb counter
      icount_dlb = 0
c
c print parameter
c 
c 1 = root times
c 2 = all node times
c 3 = ga sizes
c
      iparapr = 1
c
      return
      end
c
c =================================================================
c
c  pg_pproc : print node information
c
_IF(parallel)
      subroutine pg_pproc
      implicit none
      character*30 host, user, mach
      character*7  diag
      character*8  invert
      integer  ibuff(91), liw, if, il, i, ipid, lenwrd
      REAL fac
      logical opg_root
      integer ipg_nnodes
      integer ipg_nodeid
INCLUDE(common/iofile)
INCLUDE(common/parcntl)
_IF(taskfarm)
      integer global_nodeid
      external global_nodeid
_ENDIF
_IF(ipsc)
      if(opg_root())then
        write(iwr,1001)
 1001   format(/40x,'++++++++++++++++++++++++++++++++++++++++')
        write(iwr,1000)ipg_nnodes()
 1000   format(
     +  40x, 'Intel IPSC/860 implementation on ',i5,' nodes'/
     +  40x,40('+')/)
      endif
_ELSEIF(t3e)
      if(opg_root()) then
        write(iwr,1001)
 1001   format(/40x,'++++++++++++++++++++++++++++++++++++++++')
        write(iwr,1000)ipg_nnodes()
 1000   format(
     +  40x,'Cray T3E implementation on ',i5,' nodes'/
     +  40x,40('+')/)
      endif
_ELSEIF(t3d)
      if(opg_root())then
        write(iwr,1001)
 1001   format(/40x,'++++++++++++++++++++++++++++++++++++++++')
        write(iwr,1000)ipg_nnodes()
 1000   format(
     +  40x,'Cray T3D implementation on ',i5,' nodes'/
     +  40x,40('+')/)
      endif
_ELSEIF(ksr)
      if(opg_root())then
        write(iwr,1001)
 1001   format(/40x,'++++++++++++++++++++++++++++++++++++++++')
        write(iwr,1000)ipg_nnodes()
 1000   format(
     +  40x,'KSR implementation on ',i5,' nodes'/
     +  40x,40('+')/)
      endif
_ELSE
      mach=
_IF1(x)     *'CONVEX  version 8.0'
_IF1(a)     *'ALLIANT version 8.0'
_IF1(s)     *'  SUN   version 8.0'
_IF1(p)     *'APOLLO  version 8.0'
_IF1(g)     *'  SGI   version 8.0'
_IF1(b)     *'HP-9000 version 8.0'
_IF1(d)     *'  DEC   version 8.0'
_IF1(r)     *'RS-6000 version 8.0'
_IF1(t)     *' TITAN  version 8.0'
_IF1(c)     *'UNICOS  version 8.0'
_IF1(k)     *' KSR-2  version 8.0'
_IF1(G)     *'Generic version 8.0'
c
c cluster
c
      call hostcc(host,30)
      call namcc(user,30)
      call pidcc(ipid)
      call getload(fac)
      liw = 8/lenwrd()

      if(opg_root())then
         write(iwr,1000)
         write(iwr,1001)ipid,host(1:12),user(1:12),mach,fac
         do 10 i=1,ipg_nnodes()-1
            call pg_rcv(100,ibuff,91*liw,il,i,if,1)
            call pg_rcv(100,fac,8,il,i,if,1)
            call itoch(ibuff(1),host)
            call itoch(ibuff(31),user)
            call itoch(ibuff(61),mach)
            ipid=ibuff(91)
         write(iwr,1002)i,ipid,host(1:12),user(1:12),mach,fac
   10    continue
      else
         call chtoi(ibuff(1),host)
         call chtoi(ibuff(31),user)
         call chtoi(ibuff(61),mach)
         ibuff(91)=ipid
         call pg_snd(100,ibuff,91*liw,0,1)
         call pg_snd(100,fac,8,0,1)
      endif
_IF(_AND(ga,mpi))
 1000 format(/,/,40x,'GA/MPI parallel implementation - ',
     &  'node information:',/,40x,50('-'),/,/
_ELSEIF(mpi)
 1000 format(/,/,40x,'MPI parallel implementation - ',
     &  'node information:',/,40x,47('-'),/,/
_ELSEIF(ga,secd)
 1000 format(/,/,40x,'TCGMSG/GA-Tools parallel implementation - ',
     & 'node information:',/,40x,58('-'),/,/
_ELSEIF(tcgmsg)
 1000 format(//,40x,'TCGMSG parallel implementation - ',
     & 'node information:',/,40x,50('-'),//
_ELSE
 1000 format(//,40x,'node information',/,40x,16('-'),//
_ENDIF
     & 40x,'node     pid   hostname     user           version',/)
 1001 format(40x,'root',i8,3x,a12,1x,a12,1x,a30,f6.2)
 1002 format(40x,   i4 ,i8,3x,a12,1x,a12,1x,a30,f6.2)
_ENDIF

      if(opg_root())then
         write(iwr,*)
         write(iwr,*)
         if(iparapr.eq.0)write(iwr,1018)
 1018    format(40x,'supress print of timing information')
         if(iparapr.eq.1)write(iwr,1019)
 1019    format(40x,'print timings for root node')
         if(iparapr.eq.2)write(iwr,1021)
 1021    format(40x,'print timings for all nodes')

_IF(diag_parallel)
         if(idpdiag.eq.99999999)then
            write(iwr,1022)
 1022       format(40x,'use serial jacobi diagonaliser')
         else
            diag = "ERROR"
            if      (ipdiagmode.eq.IDIAG_PEIGS) then
              diag = "peigs"
            else if (ipdiagmode.eq.IDIAG_PDSYEV) then
              diag = "pdsyev"
            else if (ipdiagmode.eq.IDIAG_PDSYEVX) then
              diag = "pdsyevx"
            else if (ipdiagmode.eq.IDIAG_PDSYEVD) then
              diag = "pdsyevd"
            else if (ipdiagmode.eq.IDIAG_PDSYEVR) then
              diag = "pdsyevr"
            endif
            write(iwr,1023)diag,idpdiag
 1023       format(40x,'use the ',a7,' parallel diagonaliser for ',
     &                 'matrices size',i5,' and above')
         endif
_ENDIF

_IF(ga)
         if(idpdiis.eq.99999999)then
            write(iwr,1026)
 1026       format(40x,'use serial diis solver')
         else
            write(iwr,1027)idpdiis
 1027       format(40x,'use parallel diis solver for matrices',
     &           i5,' and above')
         endif

         if(idpmult2.eq.99999999)then
            write(iwr,1028)
 1028       format(40x,'use serial mult2 ')
         else
            write(iwr,1029)idpmult2
 1029       format(40x,'use parallel mult2 for matrices',
     &           i5,' and above')
         endif

         if(idporth.eq.99999999)then
            write(iwr,1034)
 1034       format(40x,'use serial orthog. ')
         else
            write(iwr,1035)idporth
 1035       format(40x,'use parallel orthog. for matrices',
     &           i5,' and above')
         endif

         invert = "ERROR"
         if (ipinvmode.eq.INV_CHOLESKY) then
           invert = "cholesky"
         else if (ipinvmode.eq.INV_DIAG) then
           if      (ipdiagmode.eq.IDIAG_PEIGS) then
             invert = "peigs"
           else if (ipdiagmode.eq.IDIAG_PDSYEV) then
             invert = "pdsyev"
           else if (ipdiagmode.eq.IDIAG_PDSYEVX) then
             invert = "pdsyevx"
           else if (ipdiagmode.eq.IDIAG_PDSYEVD) then
             invert = "pdsyevd"
           else if (ipdiagmode.eq.IDIAG_PDSYEVR) then
             invert = "pdsyevr"
           endif
         endif
         write(iwr,1040)invert
 1040    format(40x,'use the parallel ',a8,' algorithm for ',
     &              'matrix inversion')
_ENDIF
         write(iwr,1024)ntchnk
 1024    format(40x,'chunk size based on ',i6,' tasks/SCF cycle')

         if(limchnk.ne.-1)write(iwr,1025)limchnk
 1025    format(40x,'chunk size limit is ',i5)

         if(ipiomode.eq.IO_NZ)then
            write(iwr,1031)
         else if(ipiomode.eq.IO_NZ_S)then
            write(iwr,1032)
         else if(ipiomode.eq.IO_A)then
            write(iwr,1033)
         endif
 1031    format(40x,'i/o will be routed through node 0')
 1032   format(40x,'i/o will be routed through node 0, minimise comms',
     &        ' by master/slave model',/,40x
_IF(ga)
     &        ,'NB - this will reduce use of parallel linear algebra')
_ELSE
     &        )
_ENDIF
 1033    format(40x,'each node will maintain a copy of ed3,ed7 ')

      endif
      end
_ELSE
c serial stub
      subroutine pg_pproc
      end
_ENDIF 
c
c========================================================================
c
c  ** pg_end(code)
c
c  orderly closedown of the GAMESS-UK process, returning the code
c  to the OS
c
c  also handles input and out units if needed
c
c  in standalone mode this is called at the end of the job
c  in the chemshell/charmm cases this is deferred until the 
c  shutdown of the controlling processes
c
      subroutine pg_end(code)
      implicit none
      integer code
INCLUDE(common/iofile)
_IF(_AND(ga,mpi))
      include 'mpif.h'
INCLUDE(common/mpidata)
INCLUDE(common/parcntl)
      integer ierr
      MPIINT ierr_mpi
      integer icode, i
      if(ga_initted)then
c
c       First clear up global counter then close down global arrays
c
        call pg_dlbdestroy
        call ga_terminate
        ga_initted = .false.
      endif
_IF(taskfarm)
c
      call taskerrc(code)
_ELSE
c non-taskfarmed code
c      write(6,*)'pg_end calling  mpi_finalize'
      call MPI_FINALIZE(ierr_mpi)
_ENDIF(taskfarm)
c
_ELSEIF(mpi,charmmpar)
      include 'mpif.h'
INCLUDE(common/mpidata)
      MPIINT ierr_mpi, iprovided_mpi, i_mpi, n_mpi, nm1_mpi
      MPIINT icomm_gamess_mpi
      integer ierr, iprovided
      integer icode, i
_IF(taskfarm)
c
      call taskerrc(code)
_ELSE
c non-taskfarmed code
_IF(dynamic)
      MPIINT istat_mpi(MPI_STATUS_SIZE) 
      MPIINT i1_mpi, i971_mpi, i972_mpi
      MPIINT integer_mpi, linfo_mpi
      integer n, linfo, nw
      parameter (linfo=2*max_processors)
      integer info(2,0:max_processors - 1)
_IF(i8)
      integer_mpi = MPI_INTEGER8
_ELSE
      integer_mpi = MPI_INTEGER4
_ENDIF
      icomm_gamess_mpi = MPI_COMM_GAMESS
      call MPI_COMM_RANK(icomm_gamess_mpi,i_mpi,ierr_mpi)
      call MPI_COMM_SIZE(icomm_gamess_mpi,n_mpi,ierr_mpi)
      i = i_mpi
      n = n_mpi
      nw = n - 1

c     write(6,*)'pg_end',i,n

      if(i.eq.0)then
         if(n.ne.nw)then
            icode = -3
            i1_mpi = 1
            nm1_mpi = n-1
            i971_mpi = 971
            i972_mpi = 972
            linfo_mpi = linfo
            icomm_gamess_mpi = MPI_COMM_GAMESS
            call MPI_SEND(icode,i1_mpi,integer_mpi, nm1_mpi, 
     &           i971_mpi, icomm_gamess_mpi,ierr_mpi) 
            call mpi_recv(info ,linfo_mpi, integer_mpi, nm1_mpi,
     &           i972_mpi,icomm_gamess_mpi,istat_mpi,ierr_mpi)
c           write(6,*)'task allocation stats (node,#allocation,#tasks)'
            do i = 0, nw-1
c              write(6,*)i,info(1,i),info(2,i)
            enddo
            icode = -2
            call MPI_SEND(icode,i1_mpi,integer_mpi, nm1_mpi, 
     &           i971_mpi, icomm_gamess_mpi,ierr_mpi) 
         endif
      endif

c     write(6,*)'pg_end calling mpi_finalize',i,ierr

      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('finalize',ierr)
_ELSEIF(dynamic_mpi2)
*MPI2 dynamic version should destroy windows
      Call finalize_nxtval_mpi2 
      Call MPI_Query_thread(iprovided_mpi,ierr_mpi)
      if (iprovided_mpi.eq.MPI_THREAD_MULTIPLE) then
        call destroy_thread
      endif
_ENDIF
c      write(6,*)'pg_end calling  mpi_finalize'
      call MPI_FINALIZE(ierr_mpi)
_ENDIF(taskfarm)

_ELSEIF(tcgmsg)
_IF(ga)
INCLUDE(common/parcntl)
      if(ga_initted)then
        call ga_terminate
      endif
_ENDIF
      call debugp('pg_end')
      call pend
_ELSE
c    nothing specific needed for serial code
_ENDIF
c
c Default behaviour is to use the C wrapper for exit
c
c      write(6,*)'Exiting code',code
      close(iwr)
      call exitc(code)
      end
c
c========================================================================
c
c  ** opg_root() : return .true. for root process
c
      logical function opg_root()
      opg_root = ipg_nodeid() .eq. 0
      return
      end

      logical function oroot()
      oroot = ipg_nodeid() .eq. 0
      return
      end
c
c=======================================================================
c
_IF(mpi)
      subroutine getranks(irankworld,irankgamess,irankworkers)
      implicit none
      integer irankworld,irankgamess,irankworkers
      include 'mpif.h'
INCLUDE(common/mpidata)
      integer ierr
      MPIINT ierr_mpi,irankworld_mpi,irankgamess_mpi,irankworkers_mpi
      MPIINT icomm_world_mpi, icomm_gamess_mpi, icomm_workers_mpi
      icomm_world_mpi = MPI_COMM_WORLD
      icomm_gamess_mpi = MPI_COMM_GAMESS
      icomm_workers_mpi = MPI_COMM_WORKERS
      call MPI_COMM_RANK(icomm_world_mpi,irankworld_mpi,ierr_mpi)
      ierr = ierr_mpi
      if(ierr .ne. 0)call pg_errmsg('getranks: comm_world',ierr)
      call MPI_COMM_RANK(icomm_gamess_mpi,irankgamess_mpi,ierr_mpi)
      ierr = ierr_mpi
      if(ierr .ne. 0)call pg_errmsg('getranks: comm_gamess',ierr)
      call MPI_COMM_RANK(icomm_workers_mpi,irankworkers_mpi,ierr_mpi)
      ierr = ierr_mpi
      if(ierr .ne. 0)call pg_errmsg('getranks: comm_workers',ierr)
      irankworld = irankworld_mpi
      irankgamess = irankgamess_mpi
      irankworkers = irankworkers_mpi
      end
c
      subroutine getcomms(icommworld,icommgamess,icommworkers)
c     Convenience function for passing the communicators to the C code
      implicit none
      integer icommworld,icommgamess,icommworkers
      include 'mpif.h'
INCLUDE(common/mpidata)
      icommworld=  MPI_COMM_WORLD
      icommgamess= MPI_COMM_GAMESS
      icommworkers=MPI_COMM_WORKERS
      end
_ENDIF
c
c========================================================================
c
c ** ipg_nodeid() : return index (0 - (nnodes-1)) for the 
c                   current process
c
      integer function ipg_nodeid()
      implicit none
_IF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
      integer ierr
      logical test_verb
      MPIINT ipg_nodeid_mpi, ierr_mpi
      MPIINT icomm_workers_mpi

      icomm_workers_mpi = MPI_COMM_WORKERS
      call MPI_COMM_RANK(icomm_workers_mpi,ipg_nodeid_mpi,ierr_mpi)
      ipg_nodeid = ipg_nodeid_mpi
      ierr       = ierr_mpi
      if(ierr .ne. 0)call pg_errmsg('comm_rank',ierr)

_ELSEIF(tcgmsg)
_IF(ga)
INCLUDE(common/parcntl)    
      MA_INTEGER  ga_nodeid, nodeid
      if(ga_initted)then
         ipg_nodeid = ga_nodeid()
      else
         ipg_nodeid = nodeid()
      endif
_ELSE
      MA_INTEGER nodeid
      ipg_nodeid = nodeid()
_ENDIF
_ELSEIF(charmmpar)
      integer lmnod
      ipg_nodeid = lmnod()
_ELSEIF(nx)
      integer mynode
      ipg_nodeid = mynode()
_ELSE
      ipg_nodeid = 0
_ENDIF
      return
      end

_IF(taskfarm)
c
c========================================================================
c
c ** global_nodeid() : return index (0 - (nnodes-1)) for the 
c     current process within MPI_COMM_WORLD _not_ MPI_COMM_GAMESS
c
      integer function global_nodeid()
      implicit none
_IF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
      integer ierr
      MPIINT global_nodeid_mpi, ierr_mpi
      MPIINT icomm_world_mpi

      icomm_world_mpi = MPI_COMM_WORLD
      call MPI_COMM_RANK(icomm_world_mpi,global_nodeid_mpi,ierr_mpi)
      global_nodeid = global_nodeid_mpi
      ierr = ierr_mpi
      if(ierr .ne. 0)call pg_errmsg('comm_rank',ierr)
      return
      end
_ENDIF
_ENDIF
c
c========================================================================
c
c ** ipg_nnodes() : return number of nodes
c

      integer function ipg_nnodes()
      implicit none
_IF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
      integer ierr
      MPIINT ipg_nnodes_mpi, ierr_mpi
      MPIINT icomm_workers_mpi
      icomm_workers_mpi = MPI_COMM_WORKERS
      call MPI_COMM_SIZE(icomm_workers_mpi,ipg_nnodes_mpi,ierr_mpi)
      ipg_nnodes = ipg_nnodes_mpi
      ierr = ierr_mpi
      if(ierr .ne. 0)call pg_errmsg('comm_size',ierr)
_ELSEIF(tcgmsg)
_IF(ga)
INCLUDE(common/parcntl)    
      MA_INTEGER ga_nnodes, nnodes
      if(ga_initted)then
        ipg_nnodes = ga_nnodes()
      else
        ipg_nnodes = nnodes()
      endif
_ELSE
      MA_INTEGER nnodes
      ipg_nnodes = nnodes()
_ENDIF
_ELSEIF(charmmpar)
      integer lnnod
      ipg_nnodes = lnnod()
_ELSEIF(nx)
      integer numnodes
      ipg_nnodes = numnodes()
_ELSE
      ipg_nnodes = 1
_ENDIF
      return
      end
c
c========================================================================
c
c  static load balancing functions
c
      function oipsci()
      implicit REAL  (a-h,o-z)
      logical oipsci
_IF(parallel)
INCLUDE(common/parallel)
c
c...   decide  if we should process this integral batch
c...   called from jkin70 (integs) etc.
c
       icount_slb = icount_slb + 1
       oipsci = mod(icount_slb,ipg_nnodes()).ne.ipg_nodeid()
_ELSE
       oipsci = .false.
_ENDIF
       end
c
c========================================================================
c
       function  iipsci()
c
c...   initialise
c
_IF(parallel)
INCLUDE(common/parallel)
       icount_slb = 0
_ENDIF
       iipsci = 0
       return
       end


c
c=======================================================================
c
      subroutine maxabs(iin,iinout,n_mpi,itype_mpi)
      implicit none
c
c     This routine computes
c
c        dinout(i) = max(abs(dinout(i)),abs(din(i))), i=1,n
c
c     This routine is used in MPI_ALLREDUCE to implement the 'absmax'
c     function in the MPI implementation of pg_dgop.
c
      MPIINT n_mpi, itype_mpi
      MPIINT icomm_world_mpi
      integer iin(n_mpi), iinout(n_mpi)
_IF(mpi)
      include 'mpif.h'
c
      MPIINT ierr_mpi
      if (itype_mpi.eq.MPI_INTEGER4) then
        call imaxabs4(iin,iinout,n_mpi)
      elseif (itype_mpi.eq.MPI_INTEGER8) then
        call imaxabs8(iin,iinout,n_mpi)
      elseif (itype_mpi.eq.MPI_DOUBLE_PRECISION) then
        call dmaxabs(iin,iinout,n_mpi)
      else
        icomm_world_mpi = MPI_COMM_WORLD
        call MPI_ABORT(icomm_world_mpi,itype_mpi,ierr_mpi)
      endif
_ELSE
      call caserr("unexpected use of subroutine maxabs")
_ENDIF
      return
      end
c
c=======================================================================
c
      subroutine dmaxabs(din,dinout,n_mpi)
      implicit none
c
c     This routine computes
c
c        dinout(i) = max(abs(dinout(i)),abs(din(i))), i=1,n
c
c     This routine is used in MPI_ALLREDUCE to implement the 'absmax'
c     function in the MPI implementation of pg_dgop.
c
      MPIINT n_mpi
      REAL din(n_mpi), dinout(n_mpi)
c
      integer i
      do i = 1, n_mpi
        dinout(i) = max(abs(dinout(i)),abs(din(i)))
      enddo
      end
c
c=======================================================================
c
      subroutine imaxabs4(iin,iinout,n_mpi)
      implicit none
c
c     This routine computes
c
c        iinout(i) = max(abs(iinout(i)),abs(iin(i))), i=1,n
c
c     This routine is used in MPI_ALLREDUCE to implement the 'absmax'
c     function in the MPI implementation of pg_igop.
c
      MPIINT n_mpi
      integer*4 iin(n_mpi), iinout(n_mpi)
c
      integer i
      do i = 1, n_mpi
        iinout(i) = max(abs(iinout(i)),abs(iin(i)))
      enddo
      end
c
c=======================================================================
c
      subroutine imaxabs8(iin,iinout,n_mpi)
      implicit none
c
c     This routine computes
c
c        iinout(i) = max(abs(iinout(i)),abs(iin(i))), i=1,n
c
c     This routine is used in MPI_ALLREDUCE to implement the 'absmax'
c     function in the MPI implementation of pg_igop.
c
      MPIINT n_mpi
      integer*8 iin(n_mpi), iinout(n_mpi)
c
      integer i
      do i = 1, n_mpi
        iinout(i) = max(abs(iinout(i)),abs(iin(i)))
      enddo
      end
c
c=======================================================================
c
c  ** subroutine pg_dgop : double precision global sum
c
c     Double Global OPeration.
c     x(1:n) is a vector present on each process. ggop 'sums'
c     x accross all nodes using the commutative operator op.
c     The result is broadcast to all nodes. Supported operations
c
c     include '+', '*', 'max', 'min', 'absmax', 'absmin'.
c
      subroutine pg_dgop(TYPE, X, N, OP)
      implicit none
      integer TYPE, N
      REAL X(N)
      character*(*) OP     
      character*10 fnm
      character*7  snm
      data fnm/'parallel.m'/
      data snm/'pg_dgop'/
INCLUDE(common/gmempara)
INCLUDE(common/timeperiods)
_IF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
      logical test_verb
      integer igmem_alloc_inf, iwork
c
INCLUDE(common/vcore)
*IJB - make sure space allocated for buffer doesn't get too big -
*      do gsum in 512k chunks
      Integer max_len_buf
      Parameter( max_len_buf = 2 ** 16 )
      Integer start, finish, this_len, buf_len, ierr
      MPIINT buf_len_mpi, iop_mpi, ierr_mpi, this_len_mpi
      MPIINT idouble_precision_mpi
      MPIINT icomm_workers_mpi
      REAL dumtim, dclock
      external dclock
c
      if(test_verb(2))write(6,*)'dgop type=',type,' length=',n

      call start_time_period(TP_DGOP)
      dumtim = dclock()

      if(op .eq. '+')then
         iop_mpi = MPI_SUM
      elseif(op .eq. 'max')then
         iop_mpi = MPI_MAX
      elseif(op .eq. 'min')then
         iop_mpi = MPI_MIN
      elseif(op .eq. 'absmax')then
         iop_mpi = MPI_MAXABS
      else
         write(6,*)op
         call pg_errmsg('unsupported op',-1)
      endif
c
      if(test_verb(2))write(6,*)'dgop type=',type,' length=',n
c
      buf_len = Min( n, max_len_buf )
      buf_len_mpi = buf_len
      iwork = igmem_alloc_inf(buf_len,fnm,snm,'iwork',IGMEM_DEBUG)

      start = 1

      Do While( start .LE. n )

         finish   = Min( n, start + buf_len - 1 )
         this_len = finish - start + 1
         this_len_mpi = this_len
         idouble_precision_mpi = MPI_DOUBLE_PRECISION

         icomm_workers_mpi = MPI_COMM_WORKERS
         call MPI_ALLREDUCE (x( start ),Q(iwork), this_len_mpi,
     &        idouble_precision_mpi,
     &        iop_mpi, icomm_workers_mpi, ierr_mpi)

         ierr = ierr_mpi

         if(ierr .ne. 0)call pg_errmsg('all_reduce',ierr)

         call dcopy( this_len, Q(iwork), 1, x( start ), 1 )

         start = finish + 1

      End Do
      
      call gmem_free_inf(iwork,fnm,snm,'iwork')

*     tgoptm = tgoptm + (dclock()-dumtim)
      call end_time_period(TP_DGOP)
_ELSEIF(tcgmsg)
      MA_INTEGER type8, n8
INCLUDE(common/parcntl)
      if(n.eq.0)return
      call start_time_period(TP_DGOP)
      n8=n
      type8=type
_IF(ga)
      if(ga_initted)then
        call ga_dgop(TYPE8, X, N8, OP)
      else
_ENDIF
c - synchs for benefit of sp2
      call pg_synch(101)
      call dgop(TYPE8, X, N8, OP)
      call pg_synch(102)
_IF(ga)
      endif
_ENDIF
      call end_time_period(TP_DGOP)

_ELSEIF(charmmpar)
c
c use charmm routine for the sum, otherwise
c use the simple binary tree implementation
c
      call start_time_period(TP_DGOP)
      if(op .eq. '+')then
         call gcomb(x,n)
      else
         call dbintree(x,n,op)
      endif
      call end_time_period(TP_DGOP)
_ELSEIF(nx)
      integer igmem_alloc_inf
      iwork = igmem_alloc_inf(n,fnm,snm,'iwork',IGMEM_DEBUG)
      call start_time_period(TP_DGOP)
      call gdsum(x,n,Q(iwork))
      call end_time_period(TP_DGOP)
      call gmem_free_inf(iwork,fnm,snm,'iwork')
_ELSE
c Use simple binary tree
      integer ipg_nnodes
      if (ipg_nnodes().le.1) return
      call dbintree(x,n,op)
_ENDIF
      return
      end
      integer function memreq_pg_dgop(N,OP)
      implicit none
c
c     work out the memory requirements for pg_dgop
c
      integer  icount, igmem_push_estimate, igmem_pop_estimate
      integer  igmem_incr
      external igmem_incr
      integer N, iwork
      character*(*) OP
      character*10 fnm
      character*14 snm
      data fnm/'parallel.m'/
      data snm/'memreq_pg_dgop'/
INCLUDE(common/gmempara)
INCLUDE(common/timeperiods)
_IF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
      logical test_verb
c
INCLUDE(common/vcore)
      Integer max_len_buf, buf_len
      Parameter( max_len_buf = 2 ** 16 )
c
      icount = igmem_push_estimate()
c
      buf_len = Min( n, max_len_buf )
      iwork = igmem_incr(buf_len)
      call gmem_decr(iwork)

c      if(ierr .ne. 0)call pg_errmsg('all_reduce',ierr)
_ELSEIF(tcgmsg)
      MA_INTEGER type8, n8
INCLUDE(common/parcntl)
      icount = igmem_push_estimate()
      n8=n
c     type8=type
_IF(ga)
c     if(ga_initted)then
c       call ga_dgop(TYPE8, X, N8, OP)
c     else
_ENDIF
c - synchs for benefit of sp2
c     call pg_synch(101)
c     call dgop(TYPE8, X, N8, OP)
c     call pg_synch(102)
_IF(ga)
c     endif
_ENDIF

_ELSEIF(charmmpar)
c
c use charmm routine for the sum, otherwise
c use the simple binary tree implementation
c
      icount = igmem_push_estimate()
      call start_time_period(TP_DGOP)
      if(op .eq. '+')then
c        call gcomb(x,n)
      else
c        call dbintree(x,n,op)
         iwork = igmem_incr(n)
         call gmem_decr(iwork)
      endif
      call end_time_period(TP_DGOP)
_ELSEIF(nx)
      icount = igmem_push_estimate()
      iwork  = igmem_incr(n)
c     call gdsum(x,n,Q(iwork))
      call gmem_decr(iwork)
_ELSE
c Use simple binary tree
      integer ipg_nnodes
      memreq_pg_dgop = 0
      if (ipg_nnodes().le.1) return
      icount = igmem_push_estimate()
c     call dbintree(x,n,op)
      iwork = igmem_incr(n)
      call gmem_decr(iwork)
_ENDIF
      memreq_pg_dgop = igmem_pop_estimate(icount)
      return
      end
c
c  Binary Tree implementation of global ops
c  Real*8 version
c
      subroutine dbintree(x,n,op)
      implicit none
      character*(*) OP
      integer n
      REAL x(*)

INCLUDE(common/gmempara)
INCLUDE(common/vcore)
      integer n1, n2, n3, me, nproc, iwork, type, nret, ndfm
      integer igmem_alloc_inf, ipg_nodeid, ipg_nnodes
      external igmem_alloc_inf, ipg_nodeid, ipg_nnodes

      character*10 fnm
      character*8 snm

      data fnm/'parallel.m'/
      data snm/'dbintree'/

      type = 1021

      me = ipg_nodeid()
      nproc = ipg_nnodes()
      iwork = igmem_alloc_inf(n,fnm,snm,'iwork',IGMEM_DEBUG)
      n1 = 2*me+1
      n2 = 2*me+2
      n3 = (me-1)/2
   
      if (n2.lt.nproc) then
         call pg_rcv(type,Q(iwork),n*8,nret,n2,ndfm,1) 
         if(nret.ne.n*8)call pg_errmsg('dbl gop msg err',-1)
         call ddoop(n, op, x, Q(iwork))
      endif
      if (n1.lt.nproc) then
         call pg_rcv(type,Q(iwork),n*8,nret,n1,ndfm,1)
         if(nret.ne.n*8)call pg_errmsg('dbl gop msg err',-1)
         call ddoop(n, op, x, Q(iwork))
      endif
      if (me.ne.0) call pg_snd(type, x, n*8, n3, 1)
      call pg_brdcst(type, x, 8*n, 0)
   
      call gmem_free_inf(iwork,fnm,snm,'iwork')
      end

      subroutine ddoop(n, op, x, work)
      implicit none
      integer n
      REAL x(n), work(n)
      character *(*) op
      integer i
c
c     REAL  Do Op ... do the operation for pg_dgop
c
      if (op .eq. '+') then
        do 10 i = 1,n
          x(i) = x(i) + work(i)
10      continue
      else if (op .eq. '*') then
	do 20 i = 1,n
	  x(i) = x(i) * work(i)
20      continue
      else if (op .eq. 'max') then
	do 30 i = 1,n
	  x(i) = max(x(i), work(i))
30      continue
      else if (op .eq. 'min') then
	do 40 i = 1,n
	  x(i) = min(x(i), work(i))
40      continue
      else if (op .eq. 'absmax') then
	do 50 i = 1,n
	  x(i) = max(abs(x(i)), abs(work(i)))
50      continue
      else if (op .eq. 'absmin') then
	do 60 i = 1,n
	  x(i) = min(abs(x(i)), abs(work(i)))
60      continue
      else
         call pg_errmsg('bad dgop',-1)
      endif
      end
c========================================================================
c
c  ** subroutine pg_igop : integer global sum
c
c     Integer Global OPeration.
c     x(1:n) is a vector present on each process. ggop 'sums'
c     x accross all nodes using the commutative operator op.
c     The result is broadcast to all nodes. Supported operations
c     include '+', '*', 'max', 'min', 'absmax', 'absmin'.
c
      subroutine pg_igop(TYPE, X, N, OP)
      implicit none
      integer TYPE, N
      integer X(N)
      character*(*) OP     
INCLUDE(common/gmempara)
INCLUDE(common/timeperiods)
      character*10 fnm
      character*7  snm
      data fnm/'parallel.m'/
      data snm/'pg_igop'/
_IF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
INCLUDE(common/vcore)
      integer iwork, igmem_alloc_inf, ierr
      Integer i
      logical test_verb
      integer lenwrd
      external lenwrd
      REAL dumtim, dclock
      external dclock
      MPIINT iop_mpi, integer_mpi, n_mpi, ierr_mpi
      MPIINT icomm_workers_mpi
c
      call start_time_period(TP_DGOP)

      if(op .eq. '+')then
         iop_mpi = MPI_SUM
      elseif(op .eq. 'max')then
         iop_mpi = MPI_MAX
      elseif(op .eq. 'min')then
         iop_mpi = MPI_MIN
      elseif(op .eq. 'absmax')then
         iop_mpi = MPI_MAXABS
      else
         write(6,*)op
         call pg_errmsg('unsupported op',-1)
      endif
c
      if(test_verb(2))write(6,*)'igop type=',type,' length=',n

      iwork = igmem_alloc_inf((n-1)/lenwrd() + 1,fnm,snm,'iwork',
     &                        IGMEM_DEBUG)

_IF(i8)
      integer_mpi = MPI_INTEGER8
_ELSE
      integer_mpi = MPI_INTEGER4
_ENDIF
      n_mpi = n
      icomm_workers_mpi = MPI_COMM_WORKERS
      if (n_mpi.ne.n) then
        write(*,*)'pg_igop: no. data elements out of range'
        call MPI_ABORT(icomm_workers_mpi,iop_mpi,ierr_mpi)
      endif
      call MPI_ALLREDUCE (x,Q(iwork),n_mpi,integer_mpi,
     &     iop_mpi, icomm_workers_mpi, ierr_mpi)
      ierr = ierr_mpi
      if(ierr .ne. 0)call pg_errmsg('all_reduce',ierr)
c
c copy result back - MPI leaves it in work
c
      call icopy(n,Q(iwork),1,x,1)

      call gmem_free_inf(iwork,fnm,snm,'iwork')

      call end_time_period(TP_DGOP)
_ELSEIF(tcgmsg)

      MA_INTEGER type8, n8
      MA_INTEGER ibuff(4096)
      integer first, last, ii
INCLUDE(common/parcntl)

      if(n.eq.0)return
      call start_time_period(TP_DGOP)
      type8=type

      do first=1,n,4096
         last = min(n,first + 4095)
         n8 = (last - first + 1)
         do ii = 1, n8
            ibuff(ii) = x(first+ii-1)
         enddo
_IF(ga)
         if(ga_initted)then
            call ga_igop(type8, ibuff, N8, OP)
         else
_ENDIF
           call pg_synch(101)
           call igop(TYPE8, ibuff, N8, OP)
           call pg_synch(102)
_IF(ga)
         endif
_ENDIF
         do ii = 1, n8
            x(first+ii-1) = ibuff(ii)
         enddo
      enddo
      call end_time_period(TP_DGOP)
_ELSEIF(charmmpar)
      call start_time_period(TP_DGOP)
      if(op .eq. '+')then
         call igcomb(x,n)
      else
         call ibintree(x,n,op)
      endif
      call end_time_period(TP_DGOP)
_ELSEIF(nx)
INCLUDE(common/vcore)
      integer iwork, igmem_alloc_inf
      integer lenwrd
      external lenwrd, igmem_alloc_inf
      iwork = igmem_alloc_inf((n-1)/lenwrd() + 1,fnm,snm,'iwork',
     &                        IGMEM_DEBUG)
      call start_time_period(TP_DGOP)
      call gisum(x,n,Q(iwork))
      call end_time_period(TP_DGOP)
      call gmem_free_inf(iwork,fnm,snm,'iwork')
_ELSE
      integer ipg_nnodes
      if (ipg_nnodes().le.1) return
      call ibintree(x,n,op)
_ENDIF
      return
      end
      integer function memreq_pg_igop(N, OP)
      implicit none
c
c     Work out the memory requirements for pg_igop
c     integer TYPE
c     integer X(N)
      integer N
      character*(*) OP     
INCLUDE(common/gmempara)
INCLUDE(common/timeperiods)
      character*10 fnm
      character*14 snm
      data fnm/'parallel.m'/
      data snm/'memreq_pg_igop'/
      integer icount, iwork
      integer igmem_pop_estimate, igmem_push_estimate, igmem_incr
      integer lenwrd
      external lenwrd
_IF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
INCLUDE(common/vcore)
      Integer i, iop
      logical test_verb
c
      icount = igmem_push_estimate()
      if(op .eq. '+')then
         iop = MPI_SUM
      elseif(op .eq. 'max')then
         iop = MPI_MAX
      elseif(op .eq. 'min')then
         iop = MPI_MIN
      elseif(op .eq. 'absmax')then
         iop = MPI_MAXABS
      else
         write(6,*)op
         call pg_errmsg('unsupported op',-1)
      endif
c
c     if(test_verb(2))write(6,*)'igop type=',type,' length=',n

      iwork = igmem_incr((n-1)/lenwrd() + 1)

c     call MPI_ALLREDUCE (x,Q(iwork),n,MPI_INTEGER,
c    &     iop, MPI_COMM_WORKERS, ierr)

c      if(ierr .ne. 0)call pg_errmsg('all_reduce',ierr)
c
c copy result back - MPI leaves it in work
c
c     call icopy(n,Q(iwork),1,x,1)

      call gmem_decr(iwork)
_ELSEIF(tcgmsg)

      MA_INTEGER type8, n8
      MA_INTEGER ibuff(4096)
      integer first, last, ii
INCLUDE(common/parcntl)

      icount = igmem_push_estimate()
c     if(n.eq.0)return
c     type8=type

c     do first=1,n,4096
c        last = min(n,first + 4095)
c        n8 = (last - first + 1)
c        do ii = 1, n8
c           ibuff(ii) = x(first+ii-1)
c        enddo
_IF(ga)
c        if(ga_initted)then
c           call ga_igop(type8, ibuff, N8, OP)
c        else
_ENDIF
c          call pg_synch(101)
c          call igop(TYPE8, ibuff, N8, OP)
c          call pg_synch(102)
_IF(ga)
c        endif
_ENDIF
c        do ii = 1, n8
c           x(first+ii-1) = ibuff(ii)
c        enddo
c     enddo
_ELSEIF(charmmpar)
      icount = igmem_push_estimate()
      if(op .eq. '+')then
c        call igcomb(x,n)
      else
c        call ibintree(x,n,op)
         iwork=igmem_incr((n-1)/lenwrd() + 1)
         call gmem_decr(iwork)
      endif
_ELSEIF(nx)
INCLUDE(common/vcore)
      icount = igmem_push_estimate()
      iwork = igmem_incr((n-1)/lenwrd() + 1)
c     call gisum(x,n,Q(iwork))
      call gmem_decr(iwork)
_ELSE
      integer ipg_nnodes
      memreq_pg_igop = 0
      if (ipg_nnodes().le.1) return
      icount = igmem_push_estimate()
c     call ibintree(x,n,op)
      iwork=igmem_incr((n-1)/lenwrd() + 1)
      call gmem_decr(iwork)
_ENDIF
      memreq_pg_igop = igmem_pop_estimate(icount)
      return
      end
c
c
c simple binary tree implementation
c Integer version
c
      subroutine ibintree(x,n,op)
      implicit none
      integer x(*), n
      character*(*) op

INCLUDE(common/gmempara)
INCLUDE(common/vcore)
      integer n1, n2, n3, me, nproc, liw, iwork, type, nret, ndfm

      integer igmem_alloc_inf, ipg_nodeid, ipg_nnodes
      external igmem_alloc_inf, ipg_nodeid, ipg_nnodes

      integer lenwrd
      external lenwrd

      character*10 fnm
      character*8  snm

      data fnm/'parallel.m'/
      data snm/'ibintree'/
c
      me = ipg_nodeid()
      nproc = ipg_nnodes()
      n1 = 2*me+1
      n2 = 2*me+2
      n3 = (me-1)/2
      type = 1022

      liw = 8/lenwrd()

      iwork = igmem_alloc_inf((n-1)/lenwrd() + 1,fnm,snm,'iwork',
     &                        IGMEM_DEBUG)

      if (n2.lt.nproc) then
         call pg_rcv(type,Q(iwork),n*liw,nret,n2,ndfm,1)
         if(nret.ne.n*liw)call pg_errmsg('int gop msg err',-1)
         call ddoop(n, op, x, Q(iwork))
      endif
      if (n1.lt.nproc) then
         call pg_rcv(type,Q(iwork),n*liw,nret,n1,ndfm,1)
         if(nret.ne.n*liw)call pg_errmsg('int gop msg err',-1)
         call idoop(n, op, x, Q(iwork))
      endif
      if (me.ne.0) call pg_snd(type, x, n*liw, n3, 1)
      call pg_brdcst(type, x, n*liw, 0)
      call gmem_free_inf(iwork,fnm,snm,'iwork')
      end

      subroutine idoop(n, op, x, work)
      implicit none
      integer n
      integer x(n), work(n)
      character *(*) op
      integer i
c
c     integer Do Op ... do the operation for pg_igop
c
      if (op .eq. '+') then
        do 10 i = 1,n
          x(i) = x(i) + work(i)
10      continue
      else if (op .eq. '*') then
        do 20 i = 1,n
          x(i) = x(i) * work(i)
20      continue
      else if (op .eq. 'max') then
	do 30 i = 1,n
	  x(i) = max(x(i), work(i))
30      continue
      else if (op .eq. 'min') then
	do 40 i = 1,n
	  x(i) = min(x(i), work(i))
40      continue
      else if (op .eq. 'absmax') then
	do 50 i = 1,n
	  x(i) = max(iabs(x(i)), iabs(work(i)))
50      continue
      else if (op .eq. 'absmin') then
	do 60 i = 1,n
	  x(i) = min(iabs(x(i)), iabs(work(i)))
60      continue
      else
         call pg_errmsg('bad igop',-1)
      endif
      end
c========================================================================
c
c ** pg_brdcst : byte-wise broadcast
c
      subroutine pg_brdcst(TYPE, BUF, LENBUF, IFROM)
      implicit none
      INTEGER TYPE    
      INTEGER LENBUF  
      INTEGER IFROM   
_IF(mpi,tcgmsg-mpi)
INCLUDE(common/timeperiods)
      include 'mpif.h'
INCLUDE(common/mpidata)
      MPIINT ierr_mpi,lenbuf_mpi,ifrom_mpi,ibyte_mpi
      MPIINT icomm_workers_mpi
      integer ierr, maxmpi, LLENBUF, IIBUF
      logical*1  buf(*)
      integer ipg_nodeid
      parameter (maxmpi = 2**31-1)
      call start_time_period(TP_BCAST)
      LLENBUF = LENBUF
      IIBUF = 1
      ifrom_mpi = IFROM
      ibyte_mpi = MPI_BYTE
10      lenbuf_mpi = min(LLENBUF,maxmpi)
        icomm_workers_mpi = MPI_COMM_WORKERS
        call MPI_BCAST (buf(IIBUF),lenbuf_mpi,ibyte_mpi,ifrom_mpi,
     1                  icomm_workers_mpi,ierr_mpi) 
        ierr = ierr_mpi
        if(ierr.ne.0)call pg_errmsg('brdcst',ierr)
        LLENBUF = LLENBUF - lenbuf_mpi
        IIBUF = IIBUF + lenbuf_mpi
        if (LLENBUF.gt.0) go to 10
      call end_time_period(TP_BCAST)
_ELSEIF(tcgmsg)
      integer buf(*)
c      BYTE BUF(LENBUF)
INCLUDE(common/timeperiods)
INCLUDE(common/parcntl)
      MA_INTEGER type8, lenbuf8, ifrom8
      call start_time_period(TP_BCAST)
      type8=type
      lenbuf8=lenbuf
      ifrom8=ifrom
_IF(ga)
      if(ga_initted)then
        call ga_brdcst(TYPE8, BUF, LENBUF8, IFROM8)
      else
_ENDIF
        call brdcst(TYPE8, BUF, LENBUF8, IFROM8)
_IF(ga)
      endif
_ENDIF
      call end_time_period(TP_BCAST)

_ELSEIF(charmmpar)
INCLUDE(common/timeperiods)
      integer buf(*)
      call start_time_period(TP_BCAST)
      if(ifrom.eq.0) then
         call psnd8(buf,lenbuf/8)
      else
         call pg_errmsg('ifrom must be zero',-1)
      endif
      call end_time_period(TP_BCAST)
_ELSEIF(nx)
      byte buf(*)
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
INCLUDE(common/timeperiods)
      integer mynode
      call start_time_period(TP_BCAST)
      if(mynode().eq.ifrom)then
         call csend(type,buf,lenbuf,-1,mpid)
      else
         call crecv(type,buf,lenbuf)
      endif
      call end_time_period(TP_BCAST)
_ELSE
c no op
      integer buf(*)
_ENDIF
      return 
      end
c
c========================================================================
c
c     subroutine pg_synch : synchronisation
c
      subroutine pg_synch(code)
      implicit none
      integer code
_IF(_AND(ga,mpi))
c
c     GA synch ensures that all MPI AND GA communications have finished
c
      MA_INTEGER code8
      code8 = code
      call ga_sync
_ELSEIF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
      integer ierr, isync
      MPIINT ierr_mpi, icomm_workers_mpi
c  NB - isync is not used here
      logical test_verb
      if(test_verb(2))write(6,*)'barrier'

      icomm_workers_mpi = MPI_COMM_WORKERS
      call MPI_BARRIER(icomm_workers_mpi,ierr_mpi)
      ierr = ierr_mpi
      if(ierr.ne.0)call pg_errmsg('barrier',ierr)
_ELSEIF(tcgmsg)
      MA_INTEGER code8
INCLUDE(common/parcntl)
      call debugp('synch')
      code8=code
_IF(ga)

      if(ga_initted)then
        call ga_sync(code8)
      else
        write(6,*)'non GA sync'
_ENDIF
        call synch(code8)
_IF(ga)
      endif
_ENDIF

_ELSEIF(charmmpar)
      call psync
_ELSEIF(nx)
      call gsync
_ENDIF
      return
      end
c
c ======================================================================
c
c  ** taskinfodata : load balancing initialisation
c
      block data taskinfodata
INCLUDE(common/taskinfo)
      data ichi /1/
      data ichl /1/
      data nleft /0/
      data itaskl /0/
      end
c
c =====================================================================
c
      subroutine pg_eig_solve( nrow, a , q, e )
_IF(ga)
      implicit none
c
c     This routine selects the specified ScaLAPACK diagonalizer and
c     drives it through the Global Array interface. This implies that
c     the matrix first needs to transferred into a Global Array, and
c     that the result must be re-replicated from a Global Array.
c
c     This subroutine is used only when the newscf f90 module is not
c     included in the built. If the newscf is built then it will
c     drive the diagonalization routines directly through the ScaLAPACK
c     libraries without going anywhere near the Global Arrays.
c
c     In: nrow: the dimension of the problem.
c     In:  A  : an symmetric and replicated matrix stored in triangular 
c               form.
c     Out: Q  : a square and replicated matrix to store the eigenvectors
c               in columns.
c     Out: E  : a vector listing the eigenvalues in ascending order,
c               each eigenvalue E(i) corresponds to the eigenvector
c               Q(1:nrow,i)
c
INCLUDE(common/parcntl)
INCLUDE(common/timeperiods)
#include "mafdecls.fh"

      REAL a,q,e
 
      integer g_a, g_q, nrow, ione, i, ind, me, nb

      MA_INTEGER g_a8, g_q8, nb8, j8, nrow8, ione8

      dimension a(*),q(*),e(*)

      MA_INTEGER ga_nodeid
      logical  pg_create, pg_destroy
      external pg_create, ga_nodeid, pg_destroy

      me    = ga_nodeid()

      call ga_sync

      ione  =  1
      if (.not. pg_create(MT_DBL, nrow, nrow, 'matA', ione, ione,
     &                    g_a)) 
     &          call caserr('pg_create failed for matA')
      if (.not. pg_create(MT_DBL, nrow, nrow, 'matQ', ione, ione,
     &                    g_q))
     &          call caserr('pg_create failed for matQ')
c
c     Fill g_a       
c
      call load_ga_from_triangle(g_a,a,nrow)
c
c     Call interface to scalapack eigensolver
c
      nb = 0
      if      (ipdiagmode.eq.IDIAG_PEIGS) then
        call start_time_period(TP_PEIGS)
        call ga_diag_std( g_a, g_q, e )
        call end_time_period(TP_PEIGS)
      else if (ipdiagmode.eq.IDIAG_PDSYEV) then
        call start_time_period(TP_PDSYEV)
        call ga_pdsyev( g_a, g_q, e, nb )
        call end_time_period(TP_PDSYEV)
      else if (ipdiagmode.eq.IDIAG_PDSYEVX) then
        call start_time_period(TP_PDSYEVX)
        call ga_pdsyevx( g_a, g_q, e, nb )
        call end_time_period(TP_PDSYEVX)
      else if (ipdiagmode.eq.IDIAG_PDSYEVD) then
        call start_time_period(TP_PDSYEVD)
        call ga_pdsyevd( g_a, g_q, e, nb )
        call end_time_period(TP_PDSYEVD)
      else if (ipdiagmode.eq.IDIAG_PDSYEVR) then
_IF(pdsyevr)
        call start_time_period(TP_PDSYEVR)
        call ga_pdsyevr( g_a, g_q, e, nb )
        call end_time_period(TP_PDSYEVR)
_ELSE
        call caserr(
     +       "pg_scalapack_eig: ga_pdsyevr not included in this build")
_ENDIF
      else
        call caserr("pg_scalapack_eig: unknown solver")
      endif
c
c     Fill q from g_q
c
      call load_square_from_ga(q,g_q,nrow)
c
      if (.not. pg_destroy(g_a))
     $     call caserr('pg_destroy failed for matA')     
      if (.not. pg_destroy(g_q))
     $     call caserr('pg_destroy failed for matQ')     
_ELSE
      call caserr
     $     ("pg_scalapack_eig: no GAs so no GA ScaLAPACK interfaces")
_ENDIF
      end
c
c =====================================================================
c
c  ** pg_dlbcreate : create the global array for the nxtval counter and
c                    initialise the counter.
c
      subroutine pg_dlbcreate
      implicit none
_IF(_AND(ga,mpi))
#include "mafdecls.fh"
      MA_LOGICAL ga_create
      MA_INTEGER itype, idim, ichunk, inxtval
INCLUDE(common/taskinfo)
      itype  = MT_INT
      idim   =  1
      ichunk = -1
      if (.not.ga_create(itype,idim,idim,'g_nxtval',ichunk,ichunk,
     +                   inxtval)) then
        call caserr("Could not create g_nxtval")
      endif
      g_nxtval = inxtval
      call pg_dlbreset
_ENDIF
      end
c
c =====================================================================
c
c  ** pg_dlbdestroy : destroy the global array for the nxtval counter
c
      subroutine pg_dlbdestroy
      implicit none
_IF(_AND(ga,mpi))
      MA_LOGICAL ga_destroy
      MA_INTEGER inxtval
INCLUDE(common/taskinfo)
      inxtval = g_nxtval
      if (.not.ga_destroy(inxtval)) then
        call caserr("Could not destroy g_nxtval")
      endif
_ENDIF
      end
c
c =====================================================================
c
c  ** pg_dlbchunk : set chunk size
c
      subroutine pg_dlbchunk(ichunk,prnt)
c
c  set up initial chunck size 
c  must be called with the same value from all nodes.
c  this determines the first index of the loop counter
c
      implicit none
INCLUDE(common/taskinfo)
INCLUDE(common/iofile)
      integer ichunk
      logical prnt
_IF(parallel)
      logical opg_root
      if(opg_root() .and. prnt)write(iwr,*)'p: set chunk size',ichunk
_ENDIF
      ichi = ichunk
      ichl = ichunk
      end
c
c ====================================================================
c
c  ** pg_dlbreset : reset global and local counters
c
      subroutine pg_dlbreset
c
c     reset the task allocation code
c
      implicit none
INCLUDE(common/taskinfo)
INCLUDE(common/parallel)
_IF(_AND(ga,mpi))
      MA_INTEGER ione, inxtval
      ione = 1
c
c     Use a global operation here for the implied synchronisation
c     The synchronisation is limited to the processor group g_nxtval
c     is defined on.
c
      inxtval = g_nxtval
      call ga_fill(inxtval,ione)
      nleft = 0
      itaskl = 0
      icount_dlb = 0
_ELSEIF(mpi)
INCLUDE(common/mpidata)
c
c  reset the task allocation code
c
_IF(dynamic)
      integer n,i,ierr,icode,idum
      integer ipg_nodeid
      logical opg_root
      include 'mpif.h'
      MPIINT istat_mpi(MPI_STATUS_SIZE)
      MPIINT integer_mpi, i1_mpi, i971_mpi, i972_mpi, n_mpi, ierr_mpi
      MPIINT icomm_gamess_mpi
      integer ipg_nnodes
_ELSEIF(dynamic_mpi2)
      integer ipg_nnodes
      external ipg_nnodes
      integer nxtval_mpi2
      external nxtval_mpi2
      integer n8
      integer idum
_ENDIF
      call debugp('pg_dlbreset #')
_IF(dynamic)
      n = ipg_nnodes()
      i = ipg_nodeid()
      call pg_synch(100)
_IF(i8)
      integer_mpi = MPI_INTEGER8
_ELSE
      integer_mpi = MPI_INTEGER4
_ENDIF
      i1_mpi = 1
      n_mpi  = n
      i971_mpi = 971
      i972_mpi = 972
      if(opg_root())then
         icode = -1
         icomm_gamess_mpi = MPI_COMM_GAMESS
         call MPI_SEND(icode,i1_mpi,integer_mpi, n_mpi, 
     &        i971_mpi,icomm_gamess_mpi,ierr_mpi) 
         call mpi_recv(idum ,i1_mpi,integer_mpi, n_mpi,
     &        i972_mpi,icomm_gamess_mpi,istat_mpi,ierr_mpi)
      endif
      call pg_synch(101)
_ELSEIF(dynamic_mpi2)
      n8 = - ipg_nnodes()
      idum = nxtval_mpi2( n8 )
_ENDIF
      icount_dlb = 0
      nleft=0
      itaskl=0      

_ELSEIF(tcgmsg)
      integer idum, ipg_nnodes
      MA_INTEGER n8, nxtval
      external nxtval
      call debugp('pg_dlbreset #')
      n8 = -ipg_nnodes()
      idum = nxtval(n8)
      nleft=0
      itaskl=0
      icount_dlb = 0
_ELSEIF(nx)
      common/nodin2/mcount,itask,ichunk
c to placate implicit none....
      integer gtask, ircvts
      external gtask
      logical ohand
      common/handle/ohand
      data ohand/.false./
      logical opg_root
      call gsync
c check if init????
      if(.not.ohand)then
         if(opg_root())call hrecv(3215,ircvts,4,gtask)
         ohand = .true.
      endif
_ELSE
      nleft=0
      itaskl=0
      icount_dlb = 0
_ENDIF
      return
      end
c
c ====================================================================
c
c  ** pg_dlbfin : end dlb section
c
      subroutine pg_dlbfin
      implicit none
INCLUDE(common/taskinfo)
_IF(_AND(ga,mpi))
c
c     Wacky approach to ensure it affects all processors that share 
c     g_nxtval but no others.
c
      MA_INTEGER ione, inxtval
      ione = 1
      inxtval = g_nxtval
      call ga_scale(inxtval,ione)
_ELSE
      call pg_synch(999)
_ENDIF
      call debugp('pg_dlbfin')
      end
c
c ====================================================================
c
c  ** ipg_dlbtask() :  get a global index
c
      integer function ipg_dlbtask()
      implicit none
INCLUDE(common/timeperiods)
INCLUDE(common/taskinfo)
_IF(_AND(ga,mpi))
      MA_INTEGER ga_read_inc, ione, ichi8, inxtval
      ione = 1

      call debugp('pg_dlbtask')

      if(nleft .gt. 0 )then
         nleft = nleft - 1
         itaskl = itaskl + 1
      else
c
c        we count from 1 in steps of ichi
c
         call start_time_period(TP_NXTVAL)
         ichi8 = ichi
         inxtval = g_nxtval
         itaskl = ga_read_inc(inxtval,ione,ione,ichi8)
         call end_time_period(TP_NXTVAL)
         nleft = ichi - 1
      endif
      ipg_dlbtask = itaskl
_ELSEIF(mpi)
INCLUDE(common/mpidata)
      integer n,i,ierr,icode
      integer ipg_nnodes, ipg_nodeid
      logical opg_root
      include 'mpif.h'

      MPIINT istat_mpi(MPI_STATUS_SIZE)
      MPIINT ierr_mpi,i1_mpi,i971_mpi,i972_mpi,integer_mpi
      MPIINT n_mpi,icode_mpi
      MPIINT icomm_gamess_mpi

_IF(dynamic_mpi2)
      integer nxtval_mpi2
      external nxtval_mpi2
      integer itsk_mpi2
      integer n8
_ENDIF

      call debugp('pg_dlbtask')

      n = ipg_nnodes()
      i = ipg_nodeid()

_IF(dynamic)
c
c  MPI:  master/slave model
c
c  send local chunck parameter to reserve ichi indices
c
      if(nleft .gt. 0 )then
         nleft = nleft - 1
         itaskl = itaskl + 1
c         write(6,*)'##node',i,': locally allocate index',itaskl,
c     &        ' nleft ',nleft
      else
         icode = ichi
         call start_time_period(TP_NXTVAL)
         i1_mpi = 1
_IF(i8)
         integer_mpi = MPI_INTEGER8
_ELSE
         integer_mpi = MPI_INTEGER4
_ENDIF
         n_mpi = n
         i971_mpi = 971
         i972_mpi = 972
         icomm_gamess_mpi = MPI_COMM_GAMESS
         call MPI_SEND(icode,i1_mpi,integer_mpi, n_mpi, 
     &        i971_mpi,icomm_gamess_mpi,ierr_mpi) 
         call mpi_recv(itaskl,i1_mpi,integer_mpi, n_mpi,
     &        i972_mpi,icomm_gamess_mpi,istat_mpi,ierr_mpi)
         call end_time_period(TP_NXTVAL)
         ierr = ierr_mpi
         if(ierr .ne. 0)call pg_errmsg('nxtask:recv',ierr)
         nleft = ichi - 1
c         write(6,*)'##node',i,': fetch index',itaskl
      endif
      ipg_dlbtask = itaskl
_ELSEIF(dynamic_mpi2)
      if(nleft .gt. 0 )then
         nleft = nleft - 1
         itaskl = itaskl + 1
      else
c
c we count from 1, mpi2 implementation from 0

         call start_time_period(TP_NXTVAL)
         n8 = n
         itsk_mpi2 = nxtval_mpi2(n8)
         call end_time_period(TP_NXTVAL)
         itaskl = itsk_mpi2*ichi + 1
         nleft = ichi - 1
         if(opg_root())then
c            write(6,*)'##node',i,': fetch index',itaskl
         endif
      endif
      ipg_dlbtask = itaskl
_ELSE
c
c MPI with static (round-robin) scheme
c
      if(itaskl.eq.0)then
         itaskl = i+1
      else
         itaskl = itaskl + n
      endif
      ipg_dlbtask = itaskl
_ENDIF
_ELSEIF(tcgmsg)
      integer n,i
      integer ipg_nnodes, ipg_nodeid
      logical opg_root
      integer itsk_tcg
ctfp
      MA_INTEGER nxtval, n8

      call debugp('pg_dlbtask')

      n = ipg_nnodes()
      i = ipg_nodeid()

      if(nleft .gt. 0 )then
         nleft = nleft - 1
         itaskl = itaskl + 1
      else
c
c we count from 1, tcgmsg from 0 

         call start_time_period(TP_NXTVAL)
         n8 = n
         itsk_tcg = nxtval(n8)
         call end_time_period(TP_NXTVAL)
         itaskl = itsk_tcg*ichi + 1
         nleft = ichi - 1
         if(opg_root())then
c            write(6,*)'##node',i,': fetch index',itaskl
         endif
      endif
      ipg_dlbtask = itaskl
_ELSEIF(charmmpar)
      integer n,i
      integer ipg_nnodes, ipg_nodeid
c
c static (round-robin) scheme
c
      n = ipg_nnodes()
      i = ipg_nodeid()

      if(itaskl.eq.0)then
         itaskl = i+1
      else
         itaskl = itaskl + n
      endif
      ipg_dlbtask = itaskl
_ELSEIF(nx)
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
c     integer n,i
c     logical opg_root
      integer gtask, iflop, ichka1, itsk_ipsc, irecv
      external gtask
c
      if(nleft .gt. 0 )then
         nleft = nleft - 1
         itaskl = itaskl + 1
c         if(opg_root())then
c            write(6,*)'##node',i,': locally allocate index',itaskl,
c     &           ' nleft ',nleft
c         endif
      else
         call start_time_period(TP_NXTVAL)
         ichka1 = irecv(3216,itsk_ipsc,4)
         call csend(3215,iflop,4,0,mpid)
         call msgwait(ichka1)
         call end_time_period(TP_NXTVAL)
         itaskl = itsk_ipsc*ichi + 1
         nleft = ichi - 1
c         if(opg_root())then
c            write(6,*)'##node',i,': fetch index',itaskl
c         endif
      endif
      ipg_dlbtask = itaskl
_ELSE
c
c serial version
c
      if(itaskl.eq.0)then
         itaskl = 1
      else
         itaskl = itaskl + 1
      endif
      ipg_dlbtask = itaskl
_ENDIF
      end
c
c ====================================================================
c
c   ** ipg_dblpush :  get a global index
c
c            push the last index back for re-use, for use when a task 
c            is not used (as at the end of a load-balanced loop)
c
      subroutine pg_dlbpush
      implicit none
INCLUDE(common/taskinfo)
      integer ipg_nnodes
      call debugp('pg_dlbpush *')
_IF(_AND(ga,mpi))
      nleft = nleft + 1
      itaskl = itaskl - 1
_ELSEIF(mpi)
_IF(dynamic)
c
c decrement local batch counter
c
      nleft = nleft + 1
      itaskl = itaskl - 1
_ELSEIF(dynamic_mpi2)
      nleft = nleft + 1
      itaskl = itaskl - 1
_ELSE
c
c no chunking - back-set round-robin scheme
c
      itaskl = itaskl - ipg_nnodes()
_ENDIF
_ELSEIF(charmmpar)
c
c copy serial mpi algorithm
c no chunking - back-set round-robin scheme
c
      itaskl = itaskl - ipg_nnodes()
_ELSE
c
c tcgmsg and serial 
c
      nleft = nleft + 1
      itaskl = itaskl - 1
_ENDIF
      end

_IF(ipsc)
_IF(nx)
c ====================================================================
c
c ** fgtask : fortran part of intel interrupt processor
c 
      subroutine fgtask(ireqn)
      implicit integer(a-z)
c
      external gtask
      common/nodin2/mcount,itask,ichunk
      common/nodinf/mpid,minode,mihost,ldim,nnodes
c
c      print *,'node ',ireqn,' given task ',itask
      call csend(3216,itask,4,ireqn,mpid)
      call hrecv(3215,rcvtk,4,gtask)
c
      itask=itask+1
      return
      end
_ENDIF
_ENDIF
c
      subroutine pg_dlbtest
      implicit none
INCLUDE(common/parallel)
INCLUDE(common/iofile)
      REAL tot, tester
      integer ipg_nodeid
      integer ipg_dlbtask
      integer i, niter, next

      tot = 0.0d0
      niter=10

      call pg_dlbreset
      next = ipg_dlbtask()

      do i = 1,niter
         icount_dlb = icount_dlb+1
         if(icount_dlb .eq. next)then
            write(6,*)'task',next,'on node',ipg_nodeid()
            tot = tot + dble(icount_dlb)
c
c check push of indices
c
            next = ipg_dlbtask() 
            call pg_dlbpush

            next = ipg_dlbtask()
         endif
      enddo

      call pg_dgop(1010,tot,1,'+')
      tester= dble(niter*(niter+1)/2)
      if(dabs(tot - tester).lt.1.0d-10)then
         write(iwr,*)'test passed',tot
      else
         write(iwr,*)'test failed',tot,tester
      endif
      call pg_dlbpush

      write(iwr,*)'all done',ipg_nodeid()

      end
c
c ======================================================================
c
c ** pg_err : parallel error handling 
c   
c   should only get here on a parallel system with 
c   an asynchronous error
c
c   code : numerical error code
c
      subroutine pg_err(code)
      implicit none
      integer code
_IF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
      integer ierr
      MPIINT ierr_mpi, icode_mpi
      MPIINT icomm_gamess_mpi
_ENDIF
_IF(ga,tcgmsg)
      MA_INTEGER code8
_ENDIF
_IF(altix)
c special case for altix .. ? dont trust ga_error ?
      call abort('Aborting by FORCE - have a nice day ...')
_ENDIF
_IF(_AND(ga,mpi))
      code8 = code
      call ga_error("Fatal error in GAMESS-UK",code8)
_ELSEIF(mpi)
      write(6,*) ' PG_ERR INVOKED, code = ', code
      icode_mpi = code
      icomm_gamess_mpi = MPI_COMM_GAMESS
      call mpi_abort(icomm_gamess_mpi,icode_mpi,ierr_mpi)
      ierr = ierr_mpi
      write(6,*) ' RETURN from mpi_abort',ierr
_ELSEIF(tcgmsg)
_IF(_AND(rs6000,_NOT(bluegene)))
c
c to avoid ambiguous messages under AIX a special routine has been 
c available
c
      call pexitc(code)
_ELSEIF(ga)
      code8 = code
      call ga_error("Fatal error in GAMESS-UK",code8)
_ELSE
c
c error handling by TCGMSG function
c
      code8 = code
      call parerr(code8)
_ENDIF
c
_ELSEIF(charmmpar)
      CALL WRNDIE(-5,'<GUKINI>','Fatal Error in GAMESS-UK')
_ELSE
c
c serial implementations, generally use C exit routine
c
      call exitc(code)
_ENDIF
      end
      subroutine pg_errmsg(s,i)
      implicit none
INCLUDE(common/iofile)
      integer ipg_nodeid, i, me
      character s*(*)
      character tmp*100
      me=ipg_nodeid()
      write(6,*)'******* fatal error on node',me,' code =',i
      tmp = 'Fatal parallel error: '//s
      call caserr(tmp)
c      write(6,*)'       ',s
c      if (iwr .ne. 6)then
c         write(iwr,*)'******* fatal error on node',me,' code =',i
c         write(iwr,*)'       ',s
c      endif
c      call pg_err(i)
      return
      end
c     **just mpi-sync for now** 
c     **either using ga (tcgmsg-mpi) or straight mpi
c ======================================================================
c
c ** pg_snd_rcv : snd/rcv bytewise message
c
      subroutine pg_sndrcv(TYPES, BUFS, LENBUFS, NODE, 
     1                     TYPE, BUF, LENBUF, LENMES, NODESEL, NODEFROM)
      implicit none
      INTEGER TYPES, TYPE      
      INTEGER LENBUFS, LENBUF    
      INTEGER NODE      
      INTEGER BUFS(*), BUF(*)   
      INTEGER LENMES, NODESEL, NODEFROM, ifrom   

      INTEGER ierr
      integer*4 ierr_4,types_4,lenbufs_4,node_4,type_4,lenbuf_4
      integer*4 ifrom_4
      logical test_verb
_IF(mpi)
      include 'mpif.h'
INCLUDE(../m4/common/mpistatus)
INCLUDE(../m4/common/mpidata)
      MPIINT ierr_mpi,itypes_mpi,lenbufs_mpi,node_mpi
      MPIINT itype_mpi,lenbuf_mpi
      MPIINT ifrom_mpi, ibyte_mpi, icomm_gamess_mpi
      MPIINT istat_mpi(MPI_STATUS_SIZE)

      ifrom_mpi = nodesel
      if (nodesel.eq.-1) ifrom_mpi = MPI_ANY_SOURCE
      if(test_verb(2))then
         write(6,*)'pg_sndrcv to',node,' from ',ifrom_mpi
      endif

      itypes_mpi = types
      lenbufs_mpi = lenbufs
      node_mpi = node
      itype_mpi = type
      lenbuf_mpi = lenbuf
      ifrom_mpi = nodesel
      ibyte_mpi = MPI_BYTE
      icomm_gamess_mpi = MPI_COMM_GAMESS
      if (lenbufs_mpi.ne.lenbufs) then
        write(*,*)'pg_sndrcv: lenbufs overflow'
        call caserr('pg_sndrcv: lenbufs overflow')
      endif
      if (lenbuf_mpi.ne.lenbuf) then
        write(*,*)'pg_sndrcv: lenbuf overflow'
        call caserr('pg_sndrcv: lenbuf overflow')
      endif
      call MPI_SENDRECV (BUFS,LENBUFS_mpi,ibyte_mpi,NODE_mpi,
     &                   itypes_mpi,
     &                   BUF,LENBUF_mpi,ibyte_mpi,ifrom_mpi,
     &                   itype_mpi,
     &                   icomm_gamess_mpi,istat_mpi,ierr_mpi)
      ierr = ierr_mpi
      if (ierr.ne.0) call pg_errmsg('sndrcv',ierr)
***      call MPI_GET_SOURCE(stat,nodefrom)
      nodefrom = istat_mpi( MPI_source )
      lenbuf_4 = lenbuf
_ELSEIF(ga)
      types_4 = types
      lenbufs_4 = lenbufs
      node_4 = node
      type_4 = type
      lenbuf_4 = lenbuf
      ifrom_4 = nodesel
      call sendrecv (TYPES_4,BUFS,LENBUFS_4,NODE_4,TYPE_4,BUF,
     &               LENBUF_4,ifrom_4)
      NODEFROM = ifrom_4
_ENDIF 
c
c     fix up as we don't get the true length yet
c
      lenmes = lenbuf_4
c
      return
      end
c
c ======================================================================
c
c ** pg_snd : snd bytewise message
c
      subroutine pg_snd(TYPE, BUF, LENBUF, NODE, SYNC)
      implicit none
      INTEGER TYPE      
      INTEGER LENBUF    
      INTEGER NODE      
      INTEGER SYNC      
_IF(mpi)
      integer buf(*)

      integer ierr
      include 'mpif.h'
      logical test_verb
      MPIINT lenbuf_mpi,ibyte_mpi,node_mpi,itype_mpi,ierr_mpi
      MPIINT icomm_gamess_mpi
      MPIINT isnd_mpi
INCLUDE(common/mpistatus)
INCLUDE(common/mpidata)

      if(test_verb(2))then
         write(6,*)'pg_snd to',node
      endif

      lenbuf_mpi = lenbuf
      ibyte_mpi  = MPI_BYTE
      node_mpi   = node
      itype_mpi  = type

      icomm_gamess_mpi = MPI_COMM_GAMESS
      if (lenbuf_mpi.ne.lenbuf) then
        ierr_mpi = 100
        write(*,*)'pg_snd: no. data elements out of range'
        call MPI_ABORT(icomm_gamess_mpi,ierr_mpi,ierr_mpi)
      endif

      if(sync.eq.1) then
        call MPI_SEND(buf,lenbuf_mpi,ibyte_mpi, node_mpi, itype_mpi,
     &       icomm_gamess_mpi,ierr_mpi)
      else
        if (mpisnd.ne.-1) call caserr('previous send not finished')
        call MPI_ISEND(buf,lenbuf_mpi,ibyte_mpi, node_mpi, itype_mpi,
     &       icomm_gamess_mpi,isnd_mpi,ierr_mpi)
        mpisnd = isnd_mpi
      end if

      ierr = ierr_mpi
      if (ierr.ne.0) call pg_errmsg('send',ierr)
_ELSEIF(tcgmsg)
      integer  BUF(*)  
      MA_INTEGER type8, node8, sync8, lenbuf8
INCLUDE(common/parcntl)    
      integer ga_id_to_msg_id, to
_IF(ga)
      if(ga_initted)then
        to =  ga_id_to_msg_id(node)
      else
        to=node
      endif
_ELSE
      to = node
_ENDIF
      type8=type
      node8=node
      sync8=sync
      lenbuf8=lenbuf
      call snd(TYPE8, BUF, LENBUF8, NODE8, SYNC8)
_ELSEIF(charmmpar)
      integer buf(*)
      if(sync.ne.1)call pg_errmsg('async',0)
      call gsenmap(node,type,buf,lenbuf)
_ELSEIF(nx)
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
      BYTE BUF(LENBUF)  
      call csend(type,buf,lenbuf,node,mpid)
_ELSE
      integer buf(*)
      call caserr('pg_snd')
_ENDIF
      return
      end
c
c ======================================================================
c
c ** pg_rcv : receive bytewise message
c
      SUBROUTINE pg_rcv(TYPE, BUF, LENBUF, LENMES, NODESEL, 
     &     NODEFROM, SYNC)
      implicit none
      INTEGER TYPE      
      INTEGER LENBUF     
c      BYTE BUF(LENBUF)   
      integer BUF(*)   
      INTEGER LENMES     
      INTEGER NODESEL    
      INTEGER NODEFROM   
      INTEGER SYNC       
      
_IF(mpi)
      include 'mpif.h'
      MPIINT istat_mpi(MPI_STATUS_SIZE)
      MPIINT ifrom_mpi,lenbuf_mpi,ibyte_mpi,itype_mpi,ircv_mpi
      MPIINT icomm_gamess_mpi
      MPIINT ierr_mpi
INCLUDE(common/mpistatus)
INCLUDE(common/mpidata)
      integer ierr
      logical test_verb
      integer ifrom

      if(test_verb(2))then
         write(6,*)'pg_rcv from',ifrom
      endif

      ifrom = nodesel
      if (nodesel.eq.-1) ifrom = MPI_ANY_SOURCE

      ifrom_mpi = ifrom
      lenbuf_mpi = lenbuf
      ibyte_mpi  = MPI_BYTE
      itype_mpi  = type
      icomm_gamess_mpi = MPI_COMM_GAMESS
 
      if (sync.eq.1) then
        call mpi_recv(buf ,lenbuf_mpi, ibyte_mpi, ifrom_mpi,
     &       itype_mpi,icomm_gamess_mpi,istat_mpi,ierr_mpi)
      else 
        if (mpircv.ne.-1) call caserr('previous receive not finished')
        call mpi_irecv(buf, lenbuf_mpi, ibyte_mpi, ifrom_mpi,
     &       itype_mpi,icomm_gamess_mpi,ircv_mpi, ierr_mpi)
        mpircv = ircv_mpi
      end if

      ierr = ierr_mpi
      if (ierr.ne.0) call pg_errmsg('recv',ierr)

      if (sync.eq.1) then
        nodefrom = istat_mpi( MPI_source )
      else
        nodefrom = -1
      end if

c fix up as we don't get the true length yet
      lenmes = lenbuf


_ELSEIF(tcgmsg)
INCLUDE(common/parcntl)    

      MA_INTEGER ga_nnodes
      integer ga_id_to_msg_id, iii
      MA_INTEGER isel, ifrom
      MA_INTEGER type8, sync8, lenbuf8, lenmes8

      isel = NODESEL
      if(nodesel.ne.-1)then
_IF(ga)
      if(ga_initted)then
         isel =  ga_id_to_msg_id(nodesel)
      else
         isel = nodesel
      endif
_ELSE
         isel =  nodesel
_ENDIF
      endif
      type8 = type
      lenbuf8=lenbuf
      sync8=sync
      call rcv(TYPE8, BUF, LENBUF8, LENMES8, isel, ifrom, SYNC8)
      lenmes=lenmes8
_IF(ga)
      if(ga_initted)then

      NODEFROM = -999
      do iii = 0,ga_nnodes()-1
         if(ga_id_to_msg_id(iii) .eq. ifrom)then
            NODEFROM = iii
         endif
      enddo
      if(NODEFROM .eq. -999)call caserr('node mapping error')
      else
        NODEFROM = ifrom
      endif
_ELSE
      NODEFROM = ifrom
_ENDIF
_ELSEIF(charmmpar)
      if(sync.ne.1)call pg_errmsg('async',0)
      if(nodesel.eq.-1)call pg_errmsg('any source',0)
      call grecmap(nodesel,type,buf,lenbuf)
      lenmes = lenbuf
_ELSEIF(nx)
c
c nb nodesel isnt implemented - perhaps should
c concoct suitable type
c
      call crecv(type,buf,lenbuf)
      lenmes = lenbuf
_ELSE
      call caserr('pg_rcv')
_ENDIF
      return
      end
c========================================================================
c
c ** pg_wait  : checks completion of asynchronous send and receive. See notes!
c       notes : - only asynchronous for tcgmsg if supported
c               - mpi checks communcation by status information,
c                 while tcgmsg checks by node. This may give
c                 problems when implementing.
      subroutine pg_wait(inode,imode)
      implicit none
      integer inode,imode
INCLUDE(../m4/common/timeperiods)
_IF(mpi)
      include 'mpif.h'
INCLUDE(common/mpidata)
INCLUDE(common/mpistatus)
      MPIINT istat_mpi(MPI_STATUS_SIZE), ierr_mpi
      MPIINT ircv_mpi, isnd_mpi
      integer ierr
      call start_time_period(TP_WAIT)
      if (imode.eq.0) then 
        isnd_mpi = mpisnd
        call MPI_WAIT(isnd_mpi,istat_mpi,ierr_mpi)
        mpisnd = -1
      else
        ircv_mpi = mpircv
        call MPI_WAIT(ircv_mpi,istat_mpi,ierr_mpi)
        mpircv = -1
      end if 
      ierr = ierr_mpi
      if (ierr.ne.0) call pg_errmsg('wait',ierr)
      call end_time_period(TP_WAIT)
_ELSEIF(tcgmsg)
      MA_INTEGER inode8
      inode8 = inode
      call start_time_period(TP_WAIT)
      call WAITCOM(inode8)
      call end_time_period(TP_WAIT)
_ELSE
c trap not implemented
      call caserr('pg_wait')
_ENDIF
      return
      end


_IF(ga)
_IF(t3d)
c
c currently seems to be missing
c
      integer function ga_id_to_msg_id(id)
      implicit none
      integer id
      ga_id_to_msg_id = id      
      end
_ELSEIFN(ipsc)
c
c for newer ga (eg currently on SP2 and challenge but not DL iPSC)
c
      integer function ga_id_to_msg_id(id)
      implicit none
      integer id
      integer iflag, list
      integer ipg_nnodes, iii
      common/nodeids/list(0:511)
      MA_INTEGER list8(0:511),nodes8
      save iflag
      data iflag/0/
      if(iflag .eq.0)then
c
c determine mapping list from tcgmsg
c
         nodes8 = ipg_nnodes()
         call ga_list_nodeid(list8,nodes8)
         do iii = 0,nodes8-1
            list(iii) = list8(iii)  
         enddo
         iflag = 1
      endif
      ga_id_to_msg_id = list(id)
      return
      end
_ENDIF
_ENDIF

c
c>>>>>>>>>>>>>>>>> old file below here <<<<<<<<<<<<<<<<<<<<<
c
c  should discontinue using these stubs, so as to 
c  help restrict the calls to the intel code, but the
c  parallel i/o "uses" them so heavily they are kept 
c
c - except dclock, as it is so widely used, now in machscf.m
c
_IFN(ipsc)
_IF(parallel)
      function isend()
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      call caserr('*** invalid isend call')
      isend = 0
      return
      end
      function irecv()
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      call caserr('*** invalid irecv call')
      irecv = 0
      return
      end
      function iwrite()
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      call caserr('*** invalid iwrite call')
      iwrite = 0
      return
      end
_IFN(charmm)
c 
c name clash with charmm
c - we assume it won't get called from gamess
c
      function iread()
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      call caserr('*** invalid iread call')
      iread = 0
      return
      end
_ENDIF
      function iowt()
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      call caserr('*** invalid iowt call')
      iowt = 0
      return
      end
      subroutine synget()
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      entry synput
      entry msgw
      entry cprob
      call caserr('*** invalid comms subroutine')
      return
      end
_IFN(chemshell)
c these two clash with parallel parts of DL_POLY, for a parallel build 
c they should not be needed now that calls in machscf are screened out 
c by m4 processing 
      subroutine crecv()
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      call caserr('*** invalid crecv call')
      return
      end
      subroutine csend(ityp,buffer,lenbuf,nodes,mpid)
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension buffer(*)
      call caserr('invalid csend call')
      return
      end
_ENDIF

      function infocount()
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      call caserr('*** invalid infocount call')
      infocount = 0
      return
      end
_ENDIF
_ENDIF
c
c  utility routines
c
c test cpu availability - this seems to work quite well for 
c IBM SP2 nodes - poorer for HP700. probably some tuning
c of the sample period is required
c
      subroutine getload(fac)
      implicit none
      REAL dumdum
      common/foolery/dumdum
      REAL buf(3),w0,c0,w,c, fac
      integer i
      call gms_cputime(buf)
      c0 = buf(1)
      call walltime(w0)
      dumdum=0.0d0
      do i = 1,10000000
         dumdum=dumdum+sqrt(dble(i))
      enddo
      call gms_cputime(buf)
      c = buf(1)-c0
      call walltime(w)
      w = w -w0
      fac = c / w
      return
      end

      subroutine chtoi(i,s)
      integer i(*)
      character s*(*)
      ilen=len(s)
      do 10 ii = 1,ilen
        i(ii)=ichar(s(ii:ii))
10    continue
      return
      end
      subroutine itoch(i,s)
      integer i(*)
      character s*(*)
      ilen=len(s)
      do 10 ii = 1,ilen
        s(ii:ii)=char(i(ii))
10    continue
      return
      end

c  simple internal write fix (needed for apollo)
      subroutine intwrt(s,ip,iv,ic,otrunc)
      character cc(8)*(1), num(9)*(1), s*(*)
      logical otrunc
      otrunc=.false.
      do 10 iii=1,8
 10         cc(iii)='0'
      do 11 iii=1,9
 11      num(iii)=char(iii+ichar('1')-1)
      itmp=iv
      im=100000000
      itest=itmp/im
      if(itest.ne.0)then
         otrunc=.true.
         itmp=itmp-im*itest
      endif
      im=im/10
      do 20 iii=1,8
         itest=itmp/im
         if(itest.ne.0)then
            if(iii.le.8-ic)then
               otrunc=.true.
            else
               cc(iii)=num(itest)
            endif
         endif
         itmp=itmp-itest*im
 20      im=im/10
      do 30 iii=1,ic
 30      s(ip+iii:ip+iii)=cc(8-ic+iii)
      ip=ip+ic
      return
      end
c
c ======================================================================
c  control of error messages
c

      block data verbodat
      implicit none
      integer iverb, ilevel
      common/verbo/iverb(100),ilevel
      data iverb/100*0/
      data ilevel/0/
      end

      subroutine push_verb(i)
      implicit none
      integer iverb, ilevel
      common/verbo/iverb(100),ilevel
      integer i
      ilevel = ilevel + 1
      if(ilevel.eq.101)then
         call pg_errmsg('recursion gone mad',-1)
      endif
      iverb(ilevel)=i
      return
      end

      subroutine pop_verb
      implicit none
      integer iverb, ilevel
      common/verbo/iverb(100),ilevel
      ilevel = ilevel -1
      if(ilevel.le.0)then
         call pg_errmsg('pop_verb gone mad',-1)
      endif
      return
      end
c
      logical function test_verb(i)
      implicit none
      integer i
      integer iverb, ilevel
      common/verbo/iverb(100),ilevel
      if(ilevel.eq.0)then
         call pg_errmsg('bad initialisation or pop_verb error',-1)
      endif
      test_verb = i.le.iverb(ilevel)
      return
      end
c
      integer function get_verb()
      implicit none
      integer iverb, ilevel
      common/verbo/iverb(100),ilevel
      get_verb = iverb(ilevel)
      return
      end
_IF(ga)
c
c  i4->i8 conversion mappings
c
c    Always used, but generally perform no function.
c    Currently (July 98) they are important on DEC running OSF
c    Also SGI platforms depending on build flags (but not
c    the SGI_N32 build)
c
c    Note in one case (ga_locate_region) there is an extra argument.
c
      subroutine pg_get(tag,i1,i2,i3,i4,buff,i5)
      implicit none
      integer i1,i2,i3,i4,i5,tag
      MA_INTEGER i1_8,i2_8,i3_8,i4_8,i5_8,tag_8
      REAL buff
      i1_8 = i1
      i2_8 = i2
      i3_8 = i3
      i4_8 = i4
      i5_8 = i5
      tag_8=tag
      call ga_get(tag_8,i1_8,i2_8,i3_8,i4_8,buff,i5_8)
      return
      end
 
      subroutine pg_put(tag,i1,i2,i3,i4,buff,i5)
      implicit none
      integer i1,i2,i3,i4,i5,tag
      MA_INTEGER i1_8,i2_8,i3_8,i4_8,i5_8,tag_8
      REAL buff
      i1_8 = i1
      i2_8 = i2
      i3_8 = i3
      i4_8 = i4
      i5_8 = i5
      tag_8 = tag
      call ga_put(tag_8,i1_8,i2_8,i3_8,i4_8,buff,i5_8)
      return
      end
      
      subroutine pg_acc(tag,i1,i2,i3,i4,buff,i5,fact)
      implicit none
      integer i1,i2,i3,i4,i5,tag
      MA_INTEGER i1_8,i2_8,i3_8,i4_8,i5_8,tag_8
      REAL buff, fact
      i1_8 = i1
      i2_8 = i2
      i3_8 = i3
      i4_8 = i4
      i5_8 = i5
      tag_8 = tag
      call ga_acc(tag_8,i1_8,i2_8,i3_8,i4_8,buff,i5_8,fact)
      return
      end
      
      subroutine pg_error(s,i)
      implicit none
      character s*(*)
      integer i
      MA_INTEGER i8
      i8=i
      call ga_error(s,i8)
      return
      end
      
      logical function pg_create_cnt(type,dim1,dim2,array_name,
     &     chunk1, chunk2, tag)
      implicit none
#include "mafdecls.fh"
INCLUDE(common/iofile)
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
      integer type, dim1, dim2, chunk1, chunk2, tag, ltag, id, i
      integer ipg_nodeid, ipg_nnodes, igmem_overhead
      logical opg_root
      integer nnodes, maxmem
      MA_INTEGER type_8, dim1_8, dim2_8, chunk1_8, chunk2_8, tag_8
      character*(*)  array_name
      MA_LOGICAL  ga_create, ga_destroy, ga_uses_ma
c
c     This routine is supposed to only count how much memory a global
c     array is going to use. If ga_uses_ma we use the maximum amount
c     over all processors
c
      nnodes = ipg_nnodes()
      dim1_8 = dim1
      dim2_8 = dim2
      chunk1_8 = chunk1
      chunk2_8 = chunk2
      type_8=MT_DBL

      pg_create_cnt = ga_create(type_8, dim1_8, dim2_8, array_name, 
     &     chunk1_8, chunk2_8, tag_8)
      do ltag=1,mxheap
         if (igamatsize(ltag).eq.0) goto 10
      enddo
 10   continue
      if (ltag.lt.1.or.ltag.gt.mxheap.or.igamatsize(ltag).ne.0) then
         if (opg_root()) then
            write(iwr,620)tag,mxheap
 620        format(1x,'The current handle is ',i6,
     &                ' the maximum value is ',i6,/,
     &             1x,'You should expect some strange behaviour')
         endif
      else
         if (ga_uses_ma()) then
            maxmem = 0
            do id = 0, nnodes-1
               call ga_distribution(tag_8,id,dim1_8,dim2_8,
     &                              chunk1_8,chunk2_8)
               maxmem = max(maxmem,(dim2_8-dim1_8)*(chunk2_8-chunk1_8)
     &                              + igmem_overhead())
            enddo
            igamatsize(ltag) = maxmem
            do i=0,numestimate
               itotsize(i) = itotsize(i) + igamatsize(ltag)
               imaxsize(i) = max(imaxsize(i),itotsize(i))
            enddo
         else
            igamatsize(ltag) = dim1*dim2
            igatotsize       = igatotsize + igamatsize(ltag)
            igamaxsize       = max(igamaxsize,igatotsize)
         endif
      endif
      tag = ltag
      pg_create_cnt = ga_destroy(tag_8)

      return
      end

      logical function pg_create(type,dim1,dim2,array_name,
     &     chunk1, chunk2, tag)
      implicit none
#include "mafdecls.fh"
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer type, dim1, dim2, chunk1, chunk2, tag, ltag, id, i
      integer ipg_nodeid, ipg_nnodes, igmem_overhead
      integer nnodes
      logical opg_root
      MA_INTEGER type_8, dim1_8, dim2_8, chunk1_8, chunk2_8, tag_8
      character*(*)  array_name
      MA_LOGICAL  ga_create, ga_uses_ma
      integer maxmem

      nnodes = ipg_nnodes()
      dim1_8 = dim1
      dim2_8 = dim2
      chunk1_8 = chunk1
      chunk2_8 = chunk2
      type_8=MT_DBL

      pg_create = ga_create(type_8, dim1_8, dim2_8, array_name, 
     &     chunk1_8, chunk2_8, tag_8)
      tag = tag_8
      ltag = tag+1001
      if (ltag.lt.1.or.ltag.gt.mxheap) then
         if (opg_root()) then
            write(iwr,620)tag,mxheap
 620        format(1x,'The current handle is ',i6,
     &                ' the maximum value is ',i6,/,
     &             1x,'You should expect some strange behaviour')
         endif
      else
         if (ga_uses_ma()) then
            maxmem = 0
            do id = 0, nnodes-1
               call ga_distribution(tag_8,id,dim1_8,dim2_8,
     &                              chunk1_8,chunk2_8)
               maxmem = max(maxmem,(dim2_8-dim1_8)*(chunk2_8-chunk1_8)
     &                              + igmem_overhead())
            enddo
            igamem_size(ltag) = maxmem
            do i=0,numcount
               igmem_totsize(i) = igmem_totsize(i) + igamem_size(ltag)
               igmem_maxsize(i) = max(igmem_maxsize(i),
     &                                 igmem_totsize(i))
            enddo
         else
            igamem_size(ltag) = dim1*dim2
            igamem_totsize   = igamem_totsize + igamem_size(ltag)
            igamem_maxsize   = max(igamem_maxsize,igamem_totsize)
         endif
      endif

      return
      end

      logical function pg_create_inf(type,dim1,dim2,array_name,
     &     chunk1, chunk2, tag, file_name, subr_name, priority)
      implicit none
#include "mafdecls.fh"
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer type, dim1, dim2, chunk1, chunk2, tag, priority, ltag, id
      integer i, nnodes, maxmem
      integer ipg_nodeid, ipg_nnodes, igmem_overhead
      logical opg_root
      MA_INTEGER type_8, dim1_8, dim2_8, chunk1_8, chunk2_8, tag_8, id_8
      character*(*)  array_name, file_name, subr_name
      MA_LOGICAL  ga_create, ga_uses_ma

      nnodes = ipg_nnodes()

      dim1_8 = dim1
      dim2_8 = dim2
      chunk1_8 = chunk1
      chunk2_8 = chunk2
      type_8=MT_DBL

      if (opg_root().and.priority.le.igmem_print) then
         write(iwr,600)dim1*dim2,file_name,subr_name,array_name
 600     format(1x,'allocating GA of ',i10,' words in file ',a16,
     &             ' routine ',a16,' named ',a16)
      endif
      pg_create_inf = ga_create(type_8, dim1_8, dim2_8, array_name, 
     &     chunk1_8, chunk2_8, tag_8)
      tag = tag_8
      ltag = tag+1001

      if (ltag.lt.1.or.ltag.gt.mxheap) then
         if (opg_root()) then
            write(iwr,620)tag,mxheap
 620        format(1x,'The current handle is ',i6,
     &                ' the maximum value is ',i6,/,
     &             1x,'You should expect some strange behaviour')
         endif
      else
         igamem_priority(ltag) = priority
         zgamem_arrnam(ltag)   = array_name
         if (ga_uses_ma()) then
            maxmem = 0
            do id = 0, nnodes-1
               id_8 = id
               call ga_distribution(tag_8,id_8,dim1_8,dim2_8,
     &                              chunk1_8,chunk2_8)
               maxmem = max(maxmem,(dim2_8-dim1_8)*(chunk2_8-chunk1_8)
     &                              + igmem_overhead())
            enddo
            igamem_size(ltag) = maxmem
            do i=0,numcount
               igmem_totsize(i) = igmem_totsize(i) + igamem_size(ltag)
               igmem_maxsize(i) = max(igmem_maxsize(i),
     &                                igmem_totsize(i))
            enddo
         else
            igamem_size(ltag) = dim1*dim2
            igamem_totsize    = igamem_totsize + igamem_size(ltag)
            igamem_maxsize    = max(igamem_maxsize,igamem_totsize)
         endif
      endif

      return
      end

      subroutine pg_distribution(tag, node, i1, i2, i3, i4)
      implicit none
      integer tag, node, i1, i2, i3, i4
      MA_INTEGER tag_8, node_8, i1_8,  i2_8,  i3_8,  i4_8

      tag_8 = tag
      node_8 = node
      call ga_distribution(tag_8, node_8, i1_8, i2_8, i3_8, i4_8)
      i1 = i1_8
      i2 = i2_8
      i3 = i3_8
      i4 = i4_8
      return
      end

      logical function pg_destroy_cnt(handle)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
      integer handle
      integer ltag, i
      MA_INTEGER handle_8
      MA_LOGICAL ga_uses_ma
      handle_8 = handle
      ltag = handle 
      if (ltag.lt.1.or.ltag.gt.mxheap) then
      else
         if (ga_uses_ma()) then
            do i=0,numestimate
               itotsize(i) = itotsize(i) - igamatsize(ltag)
            enddo
         else
            igatotsize = igatotsize - igamatsize(ltag)
         endif
      endif
      igamatsize(ltag) = 0
      pg_destroy_cnt = .true.
      return
      end

      logical function pg_destroy(handle)
      implicit none
INCLUDE(common/gmemdata)
      integer handle, i
      integer ltag
      MA_INTEGER handle_8
      MA_LOGICAL ga_destroy, ga_uses_ma
      handle_8 = handle
      ltag = handle + 1001
      if (ltag.lt.1.or.ltag.gt.mxheap) then
      else
         if (ga_uses_ma()) then
            do i=0,numcount
               igmem_totsize(i)  = igmem_totsize(i) - igamem_size(ltag)
            enddo
         else
            igamem_totsize = igamem_totsize - igamem_size(ltag)
         endif
      endif
      pg_destroy = ga_destroy(handle_8) 
      return
      end

      logical function pg_destroy_inf(handle, array_name, file_name, 
     &                                subr_name)
      implicit none
      integer handle
      logical opg_root
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer len, priority, size, ltag, i
      MA_INTEGER handle_8
      MA_LOGICAL ga_destroy, ga_uses_ma
      character*(*) array_name, file_name, subr_name

      handle_8 = handle
      ltag = handle+1001

      if (ltag.lt.1.or.ltag.gt.mxheap) then
      else
         priority = igamem_priority(ltag)
         size     = igamem_size(ltag)
         call strtrm(array_name,len)
         len = min(len,16)
         if (array_name(1:len).ne.zgamem_arrnam(ltag)(1:len)) then
            if (opg_root()) then
               write(iwr,*)'WARNING: freeing GA ',array_name,
     &                     ' but was expecting ',
     &                     zgamem_arrnam(ltag)
            endif
         endif

         if (opg_root().and.priority.le.igmem_print) then
            write(iwr,600)size,file_name,subr_name,array_name,
     &                    igamem_totsize
 600        format(1x,'releasing GA of  ',i10,' words in file ',a16,
     &            ' routine ',a16,' named ',a16,i12)
         endif
         if (ga_uses_ma()) then
            do i=0,numcount
               igmem_totsize(i) = igmem_totsize(i) - size
            enddo
         else
            igamem_totsize = igamem_totsize - size
         endif
      endif

      pg_destroy_inf = ga_destroy(handle_8)
      return
      end
c
c  NOTE extra argument - work array must be allocated in 
c  calling procedure
c
      logical function pg_locate_region(handle, 
     &     ilo, ihi, jlo, jhi, map, np, map_8)

      implicit none
      integer handle, ilo,ihi,jlo,jhi,map(5,*),np

      MA_INTEGER handle_8,ilo_8,ihi_8,jlo_8,jhi_8,np_8, map_8(5,*)
      MA_LOGICAL ga_locate_region
      logical result
      integer i,j

      handle_8 = handle
      ilo_8 = ilo
      ihi_8 = ihi
      jlo_8 = jlo
      jhi_8 = jhi

      result = ga_locate_region(handle_8,
     &     ilo_8,ihi_8,jlo_8,jhi_8,map_8,np_8)

      pg_locate_region = result
      if(.not.result)return

      np = np_8
      do i=1,np
         do j = 1,5
            map(j,i)=map_8(j,i)
         enddo
      enddo

      return
      end

      subroutine pg_zero(handle)
      implicit none
      integer handle
      MA_INTEGER handle_8
      handle_8 = handle
      call ga_zero(handle_8)
      return
      end

      subroutine pg_dscal_patch(handle1,ix1,ix2,iy1,iy2,fac)
      implicit none
      integer handle1,ix1,ix2,iy1,iy2
      MA_INTEGER handle1_8,ix1_8,ix2_8,iy1_8,iy2_8
      REAL fac
      handle1_8 = handle1
      ix1_8 = ix1
      ix2_8 = ix2
      iy1_8 = iy1
      iy2_8 = iy2
      call ga_dscal_patch(handle1_8,ix1_8,ix2_8,iy1_8,iy2_8,fac)
      return
      end

      REAL function pg_ddot(handle1,handle2)
      implicit none
      integer handle1, handle2
      MA_INTEGER handle1_8, handle2_8
      REAL ga_ddot
_IF(hp700)
      REAL `vec_$ddot'
_ELSEIF(cray,t3d)
      REAL `sdot'
_ELSE
      REAL ddot
_ENDIF
      REAL temp
      integer ilo, ihi, jlo, jhi, ipg_nodeid,igmem_alloc_inf
      integer ibuff1, ibuff2, nx, ny
INCLUDE(common/gmempara)
INCLUDE(common/vcore)
      character*10 fnm
      character*7  snm
      data fnm/'parallel.m'/
      data snm/'pg_ddot'/
      if(handle1 .eq. handle2)then
         call pg_distribution(handle1, ipg_nodeid(), ilo, ihi, jlo, jhi)
         nx = ihi - ilo + 1
         ny = jhi - jlo + 1
         ibuff1 = igmem_alloc_inf(nx*ny,fnm,snm,'ibuff1',IGMEM_DEBUG)
         ibuff2 = igmem_alloc_inf(nx*ny,fnm,snm,'ibuff2',IGMEM_DEBUG)
         call pg_get(handle1,ilo, ihi, jlo, jhi,Q(ibuff1),nx)
         call pg_get(handle2,ilo, ihi, jlo, jhi,Q(ibuff2),nx)
         temp = ddot(nx*ny,Q(ibuff1),1,Q(ibuff2),1)
         call pg_dgop(2001,temp,1,'+')
         pg_ddot = temp
         call gmem_free_inf(ibuff2,fnm,snm,'ibuff2')
         call gmem_free_inf(ibuff1,fnm,snm,'ibuff1')
      else
         handle1_8 = handle1
         handle2_8 = handle2
         pg_ddot =  ga_ddot(handle1_8, handle2_8)
      endif
      return
      end
c
c specially extended to cover case where handle1 = handle3 for diis
c solver
c
      subroutine pg_dadd(fac1,handle1,fac2,handle2,handle3) 
      implicit none
      integer handle1, handle2, handle3
      MA_INTEGER handle1_8, handle2_8, handle3_8
      REAL fac1, fac2

      integer ilo, ihi, jlo, jhi, ipg_nodeid,igmem_alloc_inf
      integer ibuff1, ibuff2, nx, ny, iii
INCLUDE(common/gmempara)
INCLUDE(common/vcore)
      character*10 fnm
      character*7  snm
      data fnm/'parallel.m'/
      data snm/'pg_dadd'/

      if(handle1 .eq. handle3)then
         call pg_distribution(handle1, ipg_nodeid(), ilo, ihi, jlo, jhi)
         nx = ihi - ilo + 1
         ny = jhi - jlo + 1
         ibuff1 = igmem_alloc_inf(nx*ny,fnm,snm,'ibuff1',IGMEM_DEBUG)
         ibuff2 = igmem_alloc_inf(nx*ny,fnm,snm,'ibuff2',IGMEM_DEBUG)
         call pg_get(handle1,ilo, ihi, jlo, jhi,Q(ibuff1),nx)
         call pg_get(handle2,ilo, ihi, jlo, jhi,Q(ibuff2),nx)
         do iii = 1,nx*ny
            Q(ibuff1 + iii - 1) = 
     &           Q(ibuff1 + iii - 1)*fac1 +
     &           Q(ibuff2 + iii - 1)*fac2
         enddo
         call pg_put(handle1,ilo, ihi, jlo, jhi,Q(ibuff1),nx)
         call gmem_free_inf(ibuff2,fnm,snm,'ibuff2')
         call gmem_free_inf(ibuff1,fnm,snm,'ibuff1')
         call pg_synch(2002)
      else
         handle1_8 = handle1
         handle2_8 = handle2
         handle3_8 = handle3
         call ga_dadd(fac1,handle1_8,fac2,handle2_8,handle3_8) 
      endif
      return
      end

      subroutine pg_print(handle)
      implicit none
      integer handle
      MA_INTEGER handle_8
      handle_8 = handle
      call ga_print(handle_8)
      return
      end

      subroutine pg_inquire(handle, type, nx, ny)
      implicit none
      integer handle, type, nx, ny
      MA_INTEGER handle_8, type_8, nx_8, ny_8
      handle_8 = handle
      call ga_inquire(handle_8,type_8,nx_8,ny_8)
      type = type_8
      nx = nx_8
      ny = ny_8
      return
      end

      subroutine pg_dgemm(x1,x2,n1,n2,n3,fac1,
     &     handle1, handle2, fac2, handle3)
      REAL fac1, fac2
      character*1 x1,x2
      integer n1,n2,n3
      integer handle1, handle2, handle3
      MA_INTEGER handle1_8, handle2_8, handle3_8
      MA_INTEGER n1_8, n2_8, n3_8

      n1_8 = n1
      n2_8 = n2
      n3_8 = n3
      handle1_8 = handle1
      handle2_8 = handle2
      handle3_8 = handle3

      call ga_dgemm(x1,x2,n1_8,n2_8,n3_8,fac1,
     &     handle1_8, handle2_8, fac2, handle3_8)

      return
      end

      subroutine pg_diag(handle1,handle2,handle3,e)
      integer handle1, handle2, handle3 
      MA_INTEGER handle1_8, handle2_8, handle3_8
      MA_INTEGER n1_8, n2_8, n3_8
      real*8 e(*)

      handle1_8 = handle1
      handle2_8 = handle2
      handle3_8 = handle3

      call ga_diag(handle1_8,handle2_8,handle3_8,e)

      return
      end

_ENDIF
c
c                        Memory allocation routines
c
c  These routines return offsets to dynamically allocated 
c  memory addresses. 
c
c  the addresses returned by igmem_alloc(size) may be used in one
c  of two ways:
c
c     i) they may be resolved as references into the core array
c        directly (core is as passed from mains to master):
c
c            subroutine junk(core,....)
c            real*8 core(*)
c            ....
c            i10 = igmem_alloc(n*n)
c            do i=1,n*n
c               core(i10 + i - 1) = funct(i)
c            enddo
c
c    ii) they may be considered as references into the common/vcore/qq
c        array when offset by ivoff (stored in common/vcoreoff/)
c
c        This offset is incorporated into the source during m4 processing
c        if the macro Q() is used.
c
c   gmem_set(q) 
c
c   gmem_set is called once at the start of the run to establish the
c   relationship between the core array (generally denoted q) which is
c   passed to the driver routines, and specific arrays in common 
c
c   The exact function on the routine depends on the underlying mechanism
c   used to obtain the memory.
c
c   GA-tools
c
c   When the GA tools are used the offset between the q(1) and the dbl_mb
c   array is stored (in real*8 words) as iqoff.
c
c   UNIX-memory:
c
c   When memory is being allocated dynamically from the OS, the 
c
c   When the gmem_routines are simply allocating memory from the GAMESS-UK 
c   stack, via getscm the offset between the qq array in vcore
c
      block data gmem_null_blockdata
      implicit none
INCLUDE(common/gmemnull)
      integer null
      parameter(null=2**27+2**26+2**25)
      data igmem_null_pt/null/
      end

c     ****f* memory/gmem_null_initialise
c
c     NAME
c
c       gmem_null_initialise - initialises the null "pointer"
c
c     SOURCE
c
      subroutine gmem_null_initialise(q)
      implicit none
      REAL q(*)
INCLUDE(common/gmemnull)
INCLUDE(common/gmempara)
      integer igmem_alloc_inf
      character *10 fnm
      character *20 snm
      integer*8 inan
      REAL dnan
      equivalence(inan,dnan)
      data fnm/"parallel.m"/
      data snm/"gmem_null_initialise"/
      igmem_null_pt = igmem_alloc_inf(1,fnm,snm,"null",IGMEM_DEBUG)
      inan = -1
      q(igmem_null_pt) = dnan
      dnan = q(igmem_null_pt)
      igmem_nan = inan
      end
c     ******

      integer function igmem_null()
      implicit none
INCLUDE(common/gmemnull)
_IF(debug)
INCLUDE(common/vcore)
      integer*8 inan
      REAL dnan
      equivalence(inan,dnan)
      dnan = Q(igmem_null_pt)
      if (inan.ne.igmem_nan) then
         write(*,*)'*** inan      = ',inan,dnan
         write(*,*)'*** igmem_nan = ',igmem_nan
         call caserr("igmem_null: data at null pointer changed")
      endif
_ENDIF
      igmem_null = igmem_null_pt
      return
      end

      subroutine gmem_null_finalise(q)
      implicit none
      REAL q(*)
INCLUDE(common/gmemnull)
      integer igmem_alloc_inf
      character *10 fnm
      character *18 snm
      integer*8 inan
      REAL dnan
      equivalence(inan,dnan)
      data fnm/"parallel.m"/
      data snm/"gmem_null_finalise"/
      dnan = q(igmem_null_pt)
      if (inan.ne.igmem_nan) then
         write(*,*)'*** inan      = ',inan
         write(*,*)'*** igmem_nan = ',igmem_nan
         call caserr("gmem_null_finalise: data at null pointer changed")
      endif
      call gmem_free_inf(igmem_null_pt,fnm,snm,"null")
      end

      subroutine gmem_set(q)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
INCLUDE(common/vcore)
      REAL q(*)
      integer i
c
c
_IF(ma)
#include "mafdecls.fh"
_IF(64bitpointers)
c
c  in the MA-case we will need to know the offset between
c  the gamess core and the dbl_mb array tha MA returns its
c  addresses with respect to
c
_ELSE
      call gmem_c_pointer_diff(q(1),dbl_mb(1),iqoff)
_ENDIF
_ENDIF
c
c now compute ivoff
c
      call gmem_c_pointer_diff(q(1),qq(1),ivoff)
      ogmem_alloced_all = .false.
      numheap = 0
      igmem_count = 0
      igmem_totsize(0) = 0
      igmem_maxsize(0) = 0
      igamem_totsize = 0
      igamem_maxsize = 0
      numcount = 0
      itotsize(0) = 0
      imaxsize(0) = 0
      numestimate = 0
      numchunk = 0
      do i=1,mxheap
         igamatsize(i)=0
      enddo
      return
      end


      subroutine gmem_usage(itotsize,num)
      implicit none
INCLUDE(common/gmemdata)
      integer itotsize, num
      num = numheap
      itotsize = igmem_totsize(0)
      return
      end

      integer function igmem_overhead()
      implicit none
c
c     The number of extra words of memory used to allocate a chunk
c     of memory.
c
_IF(ma)
#include "mafdecls.fh"
      igmem_overhead = MA_sizeof_overhead(MT_DBL)
_ELSEIF(dynamic_memory)
      igmem_overhead = 0
_ELSE
      igmem_overhead = 4
_ENDIF
      return
      end
c
c     A bunch of utility routines for the purpose of calculating
c     memory usage of the code.
c
      integer function igmem_count_max()
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
      igmem_count_max = imaxsize(0)
      return
      end

      integer function igmem_count_current()
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
      igmem_count_current = itotsize(0)
      return
      end

      block data gmem_data_count
      implicit none
INCLUDE(common/gmemdata)
      data igmem_count /0/
      data numheap /0/
      data igmem_size /mxheap*0/
      data igmem_totsize /mxcount*0,0/
      data igmem_maxsize /mxcount*0,0/
      data igamem_size /mxheap*0/
      data igamem_totsize /0/
      data igamem_maxsize /0/
      end

      block data gmem_data_estimate
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
      data numchunk /0/
      data numestimate /0/
      data ichunksize /mxheap*0/
      data itotsize /mxcount*0,0/
      data imaxsize /mxcount*0,0/
      data igamatsize /mxheap*0/
      data igatotsize /0/
      data igamaxsize /0/
      end

      integer function igmem_incr(nsize)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
      integer igmem_overhead
      integer nsize, i
c
      if (numchunk.lt.0) then
         call caserr('igmem_incr: numchunk corrupted')
      endif
      if (numchunk.ge.mxheap) then
         write(*,*)'Too many memory chunk: you want to use ',
     &             numchunk+1,' but the maximum is ',mxheap
         call caserr('Too many memory chunks')
      endif
      numchunk = numchunk + 1
      ichunksize(numchunk) = nsize + igmem_overhead()
      do i=0,numestimate
         itotsize(i) = itotsize(i) + ichunksize(numchunk)
         imaxsize(i) = max(imaxsize(i),itotsize(i))
      enddo
      igmem_incr = numchunk
c
      return
      end

      subroutine gmem_decr(ichunk)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
      integer igmem_overhead
      integer ichunk, i
c
      if (ichunk.ne.numchunk) then
         write(*,*)'Non stack memory: you want to decrease ',ichunk,
     &             'but the current chunk is ',numchunk
         call caserr('Non stack memory counting')
      endif
      do i=0,numestimate
         itotsize(i) = itotsize(i) - ichunksize(numchunk)
      enddo
      numchunk = numchunk - 1
      if (numchunk.lt.0) then
         call caserr('gmem_decr: numchunk corrupted')
      endif
c
      return
      end
c
c **********************************************************************
c * igmem_push_estimate: create a new memory estimate counter
c *
c *   Return the handle of a new memory estimate counter
c *
c **********************************************************************

      integer function igmem_push_estimate()
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
INCLUDE(common/iofile)
      if (numestimate.lt.mxcount) then
         numestimate=numestimate+1
         itotsize(numestimate)=0
         imaxsize(numestimate)=0
         igmem_push_estimate=numestimate
      else
         write(iwr,*)'numestimate is ',numestimate,' mxcount is ',
     &               mxcount
         call caserr(
     &'igmem_push_estimate: no more memory estimate counters available')
      endif
      return
      end
c
c **********************************************************************
c * igmem_pop_estimate(ihandle): destroy a memory estimate counter
c *
c *   ihandle: the handle of the toplevel estimate counter
c *
c *   Return the maximum memory estimate counter
c *
c **********************************************************************

      integer function igmem_pop_estimate(ihandle)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
INCLUDE(common/iofile)
      integer ipg_nodeid
      integer ihandle
c
      if (numestimate.eq.ihandle) then
         if (itotsize(numestimate).ne.0) then
            write(iwr,*)ipg_nodeid(),' WARNING: current memory ',
     &      ' estimate counter ',numestimate,' is not zero!!!'
            write(iwr,*)ipg_nodeid(),' WARNING:',
     &      ' estimate counter ',numestimate,' is ',
     &      itotsize(numestimate)
         endif
         igmem_pop_estimate=imaxsize(numestimate)
         itotsize(numestimate)=0
         imaxsize(numestimate)=0
         numestimate=numestimate-1
      else
         write(iwr,*)'numestimate is ',numestimate,' ihandle is ',
     &               ihandle
         call caserr(
     &        'igmem_pop_estimate: out of stack order destruction')
      endif
      return
      end
c
c **********************************************************************
c * igmem_get_estimate(ihandle): get the current value of the estimated
c *                              memory usage
c *
c *   ihandle: the handle of the estimate counter
c *
c *   Return the current memory estimate counter
c *
c **********************************************************************

      integer function igmem_get_estimate(ihandle)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
INCLUDE(common/iofile)
      integer ipg_nodeid
      integer ihandle
c
      if (numestimate.ge.ihandle.and.ihandle.ge.0) then
         if (itotsize(numestimate).lt.0) then
            write(iwr,*)ipg_nodeid(),' WARNING: current memory ',
     &      ' estimate counter ',ihandle,' is ',itotsize(ihandle)
         endif
         igmem_get_estimate=itotsize(ihandle)
      else
         write(iwr,*)'numestimate is ',numestimate,' ihandle is ',
     &               ihandle
         call caserr(
     &        'igmem_get_estimate: ihandle out of range')
      endif
      return
      end
c
c **********************************************************************
c * igmem_max_estimate(ihandle): get the maximum value of the estimated
c *                              memory usage
c *
c *   ihandle: the handle of the estimate counter
c *
c *   Return the maximum memory estimate counter
c *
c **********************************************************************

      integer function igmem_max_estimate(ihandle)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmemcount)
INCLUDE(common/iofile)
      integer ipg_nodeid
      integer ihandle
c
      if (numestimate.ge.ihandle.and.ihandle.ge.0) then
         if (imaxsize(numestimate).lt.0) then
            write(iwr,*)ipg_nodeid(),' WARNING: current memory ',
     &      ' estimate counter ',ihandle,' is ',imaxsize(ihandle)
         endif
         igmem_max_estimate=imaxsize(ihandle)
      else
         write(iwr,*)'numestimate is ',numestimate,' ihandle is ',
     &               ihandle
         call caserr(
     &        'igmem_max_estimate: ihandle out of range')
      endif
      return
      end

c
c **********************************************************************
c * igmem_push_usage: create a new memory usage counter
c *
c *   Return the handle of a new memory counter
c *
c **********************************************************************

      integer function igmem_push_usage()
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      if (numcount.lt.mxcount) then
         numcount=numcount+1
         igmem_totsize(numcount)=0
         igmem_maxsize(numcount)=0
         igmem_push_usage=numcount
      else
         write(iwr,*)'numcount is ',numcount,' mxcount is ',mxcount
         call caserr(
     &        'igmem_push_usage: no more memory counters available')
      endif
      return
      end
c
c **********************************************************************
c * igmem_pop_usage(ihandle): destroy a memory usage counter
c *
c *   ihandle: the handle of the toplevel counter
c *
c *   Return the maximum memory usage counter
c *
c **********************************************************************

      integer function igmem_pop_usage(ihandle)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer ipg_nodeid
      integer ihandle
c
      if (numcount.eq.ihandle) then
         if (igmem_totsize(numcount).ne.0) then
            write(iwr,*)ipg_nodeid(),' WARNING: current memory usage ',
     &      ' counter ',numcount,' is not zero!!!'
         endif
         igmem_pop_usage=igmem_maxsize(numcount)
         igmem_totsize(numcount)=0
         igmem_maxsize(numcount)=0
         numcount=numcount-1
      else
         write(iwr,*)'numcount is ',numcount,' ihandle is ',ihandle
         call caserr(
     &        'igmem_pop_usage: out of stack order destruction')
      endif
      return
      end
c
c **********************************************************************
c * igmem_get_usage(ihandle): get the current value of the memory usage
c *
c *   ihandle: the handle of the usage counter
c *
c *   Return the current memory usage counter
c *
c **********************************************************************

      integer function igmem_get_usage(ihandle)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer ipg_nodeid
      integer ihandle
c
      if (numcount.ge.ihandle.and.ihandle.ge.0) then
         if (igmem_totsize(numcount).lt.0) then
            write(iwr,*)ipg_nodeid(),' WARNING: current memory ',
     &      ' usage counter ',ihandle,' is ',igmem_totsize(ihandle)
         endif
         igmem_get_usage=igmem_totsize(ihandle)
      else
         write(iwr,*)'numcount is ',numcount,' ihandle is ',
     &               ihandle
         call caserr(
     &        'igmem_get_usage: ihandle out of range')
      endif
      return
      end
c
c **********************************************************************
c * igmem_max_usage(ihandle): get the maximum value of the memory usage
c *
c *   ihandle: the handle of the usage counter
c *
c *   Return the maximum memory usage counter
c *
c **********************************************************************

      integer function igmem_max_usage(ihandle)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer ipg_nodeid
      integer ihandle
c
      if (numcount.ge.ihandle.and.ihandle.ge.0) then
         if (igmem_maxsize(numcount).lt.0) then
            write(iwr,*)ipg_nodeid(),' WARNING: maximum memory ',
     &      ' usage counter ',ihandle,' is ',igmem_maxsize(ihandle)
         endif
         igmem_max_usage=igmem_maxsize(ihandle)
      else
         write(iwr,*)'numcount is ',numcount,' ihandle is ',
     &               ihandle
         call caserr(
     &        'igmem_max_usage: ihandle out of range')
      endif
      return
      end
c
c **********************************************************************
c * igmem_alloc_inf(size,filename,subname,varid,priority) :  allocate 
c *    a segment of memory
c *
c *    New style interface to the memory subsystem. 
c *    This routine delegates the real work to ogmem_alloc_kernel.
c *
c *        size     - size of memory segment                     (input)
c *        filename - name of the file from which 
c *                   the call was made                          (input)
c *        subname  - name of the subroutine from which 
c *                   the call is made                           (input)
c *        varid    - mnemonic identifier of the data structure
c *                   for which the memory is allocated          (input)
c *        priority - how important is it for a user to know 
c *                   the size of this memory segment            (input)
c *
c **********************************************************************

      integer function igmem_alloc_inf(size,filename,subname,varid,
     &                                 priority)
c
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer size
      logical ogmem_alloc_kernel
      integer igmem_max_memory
      integer igmem_overhead
      integer i
      logical opg_root
      logical osuccess
      integer result
      integer maxmem
      character*(*) filename,subname,varid
      integer priority
c
      igmem_alloc_inf = 0
      osuccess = ogmem_alloc_kernel(size,varid,result)
      igmem_size(numheap) = size + igmem_overhead()
      do i=0,numcount
         igmem_totsize(i) = igmem_totsize(i) + igmem_size(numheap)
         igmem_maxsize(i) = max(igmem_maxsize(i),igmem_totsize(i))
      enddo
c
      if (opg_root().and.priority.le.igmem_print) then
         write(iwr,600)size,filename,subname,varid,result,
     &                 igmem_totsize(0)
 600     format(1x,'allocating ',i16,' words in file ',a16,
     &            ' routine ',a16,' for ',a16,' address ',2i12)
      endif
      if (opg_root().and.priority.ge.0) then
         call caserr('Illegal value for priority: are you using common/g
     &mempara allright?')
      endif
c
      if (.not.osuccess) then
         maxmem = igmem_max_memory()
         if (opg_root()) then
            call ma_summarize_allocated_blocks
            write(iwr,610)size,maxmem
         endif
 610     format(1x,'Memory allocation of ',i16,' words failed.',/,
     &          1x,'Only ',i16,' words available.')
         call caserr('memory ran out')
      endif
c
      igmem_priority(numheap)=priority
      zgmem_varid(numheap)   =varid
c
      igmem_alloc_inf = result
      return
      end


c **********************************************************************
c * igmem_alloc_all_inf(size,filename,subname,varid,priority) :  
c *    allocate all memory available
c *
c *    New style interface to the memory subsystem. 
c *    This routine delegates the real work to ogmem_alloc_all_kernel.
c *
c *        size     - size of memory segment                    (output)
c *        filename - name of the file from which
c *                   the call was made                          (input)
c *        subname  - name of the subroutine from which
c *                   the call is made                           (input)
c *        varid    - mnemonic identifier of the data structure
c *                   for which the memory is allocated          (input)
c *        priority - how important is it for a user to know
c *                   the size of this memory segment            (input)
c *
c **********************************************************************

      integer function igmem_alloc_all_inf(size,filename,subname,varid,
     &                                     priority)
c
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer size,i
      logical ogmem_alloc_all_kernel
      integer igmem_max_memory
      integer igmem_overhead
      logical opg_root
      logical osuccess
      integer result
      integer maxmem
      character*(*) filename,subname,varid
      integer priority
c
      ogmem_alloced_all = .true.
      igmem_alloc_all_inf = 0
c
      if (opg_root().and.priority.le.igmem_print) then
         write(iwr,600)filename,subname,varid
 600     format(1x,'allocating    all remaining words in file ',a16,
     &            ' routine ',a16,' for ',a16)
      endif
c
      osuccess = ogmem_alloc_all_kernel(size,varid,result)
      igmem_size(numheap) = size + igmem_overhead()
      do i=0,numcount
         igmem_totsize(i) = igmem_totsize(i) + igmem_size(numheap)
c        igmem_maxsize(i) = max(igmem_maxsize(i),igmem_totsize(i))
      enddo
      if (opg_root().and.priority.ge.0) then
         call caserr('Illegal value for priority: are you using common/g
     &mempara allright?')
      endif
c
      if (.not.osuccess.or.size.le.0) then
         maxmem = igmem_max_memory()
         if (opg_root()) then
            call ma_summarize_allocated_blocks
            write(iwr,610)maxmem
         endif
 610     format(1x,'Memory allocation of all remaining words failed.',/,
     &          1x,'Only ',i16,' words available.')
         call caserr('memory ran out')
      endif
c
      igmem_priority(numheap)=priority
      zgmem_varid(numheap)   =varid
c
      igmem_alloc_all_inf = result
      return
      end


c **********************************************************************
c *
c *   gmem_free_set(ilow,ihigh) : free all memory chunks between and
c *                               including addresses ilow and ihigh.
c *
c *    This routine is meant to lift the burden to deallocate all
c *    memory chunks explicitly. This burden turned out to be a 
c *    significant obstacle to the take up of the dynamic memory 
c *    management.
c *
c *        ilow    - the lowest address of the memory chunks you
c *                  want to free                                (input)
c *        ihigh   - the highest address of the memory chunks you
c *                  want to free                                (input)
c *
c **********************************************************************

      subroutine gmem_free_set(ilow,ihigh)
      implicit none
      integer ilow, ihigh
INCLUDE(common/gmemdata)
INCLUDE(common/gmempara)
      integer ix, ixhigh, ixlow, iq_h
c
      ixhigh = numheap
      ixlow  = numheap
      do ix = numheap,1,-1
         if (iq_heap(ix).ge.ihigh) ixhigh = ix
         if (iq_heap(ix).ge.ilow)  ixlow  = ix
      enddo
      call gmem_free(ihigh)
      do ix = ixhigh-1, ixlow+1, -1
         iq_h =iq_heap(ix)
         call gmem_free(iq_h)
      enddo
      if (ihigh.ne.ilow) call gmem_free(ilow)
      end

c **********************************************************************
c *
c *  gmem_free_inf(iq,filename,subname,varid) : free memory at offset iq
c *
c *    New style interface to the memory subsystem. 
c *    This routine delegates the real work to gmem_free_kernel.
c *
c *        iq       - the offset of the memory chunk             (input)
c *        filename - name of the file from which
c *                   the call was made                          (input)
c *        subname  - name of the subroutine from which
c *                   the call is made                           (input)
c *        varid    - mnemonic identifier of the data structure
c *                   for which the memory is allocated          (input)
c *
c *    Although varid is stored when the allocate is done the user
c *    expected to enter it again. This ensures that varid is a string
c *    the user can search for in the source to find matching allocates
c *    and frees.
c *
c **********************************************************************

      subroutine gmem_free_inf(iq,filename,subname,varid)
      implicit none
c
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer iq
      integer igmem_overhead
      logical opg_root
      integer ix, priority, len, size, i
      character*(*) filename,subname,varid
c
      priority=igmem_priority(numheap)
      size    =igmem_size(numheap)
      call strtrm(varid,len)
      len = min(len,16)
      if (varid(1:len).ne.zgmem_varid(numheap)(1:len)) then
         if (opg_root()) then
            write(iwr,*)'WARNING: freeing ',varid,' but was expecting ',
     &                  zgmem_varid(numheap)
         endif
      endif
c
      if (opg_root().and.priority.le.igmem_print) then
         write(iwr,600)size-igmem_overhead(),filename,subname,varid,
     &                 igmem_totsize(0)
 600     format(1x,'releasing  ',i16,' words in file ',a16,
     &            ' routine ',a16,' for ',a16,i12)
      endif
      do i=0,numcount
         igmem_totsize(i) = igmem_totsize(i) - size
      enddo
c
c     if (opg_root().and.ogmem_debug) then
c        do ix = numheap,1,-1
c           if (iq.eq.iq_heap(ix)) then
c              write(iwr,*)'free memory handle= ',itag_heap(ix)
c              goto 100
c           endif
c        enddo
c     endif
 100  continue
      call gmem_free_kernel(iq)
      end


c
c **********************************************************************
c * igmem_alloc(size) :  allocate a segment of memory
c *
c *    Old style interface to the memory subsystem. All calls to this
c *    routine should eventually be replaced by calls to 
c *    igmem_alloc_inf. This routine delegates the real work to 
c *    ogmem_alloc_kernel.
c *
c *                size - size of memory segment (input)
c *
c **********************************************************************

      integer function igmem_alloc(size)
c
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmempara)
INCLUDE(common/iofile)
      integer size, i
      logical ogmem_alloc_kernel
      integer igmem_max_memory
      integer igmem_overhead
      logical opg_root
      logical osuccess
      integer result
      integer maxmem
      character*30 tag
c
      igmem_alloc = 0
      write(tag,610)numheap+1
 610  format('gamess_',i3.3)
      osuccess = ogmem_alloc_kernel(size,tag,result)
      igmem_size(numheap) = size + igmem_overhead()
      do i=0,numcount
         igmem_totsize(i) = igmem_totsize(i) + igmem_size(numheap)
         igmem_maxsize(i) = max(igmem_maxsize(i),igmem_totsize(i))
      enddo
      zgmem_varid(numheap) = ' '
c
      if (.not.osuccess) then
         maxmem = igmem_max_memory()
         if (opg_root()) then
            call ma_summarize_allocated_blocks
            write(iwr,600)size,maxmem
         endif
 600     format(1x,'Memory allocation of ',i16,' words failed.',/,
     &          1x,'Only ',i16,' words available.')
         call caserr('memory ran out')
      endif
c
      if (opg_root().and.IGMEM_DEBUG.le.igmem_print) then
         write(iwr,620)tag,size,itag_heap(numheap),iq_heap(numheap),
     &                 igmem_totsize(0)
 620     format(1x,'allocate ',a10,' size=',i8,' handle= ',i8,
     &          ' gamess address=',i12,i12)
      endif
c
      igmem_alloc = result
      return
      end


c **********************************************************************
c * igmem_alloc_all(size) :  allocate all memory available
c *
c *    Old style interface to the memory subsystem. All calls to this
c *    routine should eventually be replaced by calls to 
c *    igmem_alloc_all_inf. This routine delegates the real work to 
c *    ogmem_alloc_all_kernel.
c *
c *                size - size of memory segment (output)
c *
c **********************************************************************

      integer function igmem_alloc_all(size)
c
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/gmempara)
INCLUDE(common/iofile)
      integer size, i
      logical ogmem_alloc_all_kernel
      integer igmem_max_memory
      integer igmem_overhead
      logical opg_root
      logical osuccess
      integer result
      integer maxmem
      integer lentag
      character*30 tag
      tag = 'all_remaining_memory'
c
      ogmem_alloced_all = .true.
      igmem_alloc_all = 0
      osuccess = ogmem_alloc_all_kernel(size,tag,result)
      igmem_size(numheap) = size + igmem_overhead()
      do i=0,numcount
         igmem_totsize(i) = igmem_totsize(i) + igmem_size(numheap)
      enddo
      zgmem_varid(numheap) = ' '
c
      if (.not.osuccess.or.size.le.0) then
         maxmem = igmem_max_memory()
         if (opg_root()) then
            call ma_summarize_allocated_blocks
            write(iwr,600)maxmem
         endif
 600     format(1x,'Memory allocation of all remaining words failed.',/,
     &          1x,'Only ',i16,' words available.')
         call caserr('memory ran out')
      endif
c
      call strtrm(tag,lentag)
      if (opg_root().and.IGMEM_DEBUG.le.igmem_print) then
         write(iwr,610)tag(1:lentag),size,itag_heap(numheap),
     &                 iq_heap(numheap)
 610     format(1x,'allocate ',a20,' size=',i14,' handle=',i8,
     &               ' gamess address=',i8)
      endif
c
      igmem_alloc_all = result
      return
      end


c **********************************************************************
c *
c *   gmem_free(iq) : free memory at offset iq
c *
c *    Old style interface to the memory subsystem. All calls to this
c *    routine should eventually be replaced by calls to
c *    gmem_free_inf. This routine delegates the real work to
c *    gmem_free_kernel.
c *
c **********************************************************************

      subroutine gmem_free(iq)
      implicit none
c
INCLUDE(common/gmemdata)
INCLUDE(common/gmempara)
INCLUDE(common/iofile)
      integer iq
      logical opg_root
      integer ix
      integer i
      character *30 tag
c
      do i=0,numcount
         igmem_totsize(i) = igmem_totsize(i) - igmem_size(numheap)
      enddo
      if (opg_root().and.IGMEM_DEBUG.le.igmem_print) then
         do ix = numheap,1,-1
            if (iq.eq.iq_heap(ix)) then
               write(tag,610)ix
 610           format('gamess_',i3.3)
               write(iwr,600)tag,itag_heap(ix),iq
 600           format(1x,'free     ',a10,' handle= ',i8,
     &                ' gamess address=',i12,i12)
               goto 100
            endif
         enddo
      endif
 100  continue
      call gmem_free_kernel(iq)
      end


c **********************************************************************
c * ogmem_alloc_kernel(size,tag,offset) :  allocate a segment of memory 
c *
c *    This routine does the real work and never prints any 
c *    diagnostics. This routine should NEVER be called directly
c *    from an application.
c *    The return value is .true. if the allocation was successful
c *
c *                size - size of memory segment (input)
c *                tag  - name of memory segment (input)
c *                offset - offset to memory allocated (output)
c *
c **********************************************************************

      logical function ogmem_alloc_kernel(size,tag,offset)

      implicit none
INCLUDE(common/gmemdata)
_IF(ma)
#include "mafdecls.fh"
      MA_INTEGER size_8, type_8, itag_8, iq_8
INCLUDE(common/vcore)
_ELSEIF(dynamic_memory)
INCLUDE(common/vcore)
_ELSE
INCLUDE(common/vcore)
INCLUDE(common/segm)
       integer i10, need, loc10, loccm,  loadcm
_ENDIF
INCLUDE(common/iofile)
      logical osuccess, opg_root
      integer ipg_nodeid
      external ipg_nodeid
      character tag*(*)
      integer size, offset
      integer igmem_null

_IF(64bitpointers)
      integer*8 iq64
      common/pointer64/iq64
_ENDIF
c
      ogmem_alloc_kernel = .false.
      osuccess = .false.
      numheap = numheap + 1

      if (numheap.gt.mxheap) then
         write(iwr,600)ipg_nodeid(),numheap,mxheap
 600     format(1x,'PROC ',i6,': current number of memory chunks ',i6,
     &             ' exceeds maximum of ',i6,/,
     &          1x,'Please change mxheap in gmemdata and recompile.')
         call caserr("numheap exceeds mxheap in memory allocation")
      endif

_IF(ma)
      type_8 = MT_DBL
      size_8 = size
c MA tools wont allow zero allocation
      if(size_8.eq.0)size_8=1
      osuccess = ma_alloc_get(
     &     type_8,
     &     size_8,
     &     tag,
     &     itag_8,
     &     iq_8)
      itag_heap(numheap) = itag_8
c
c  store as the GAMESS-UK core
c	
_IF(64bitpointers)
      iq_heap(numheap) = iq_8 - iq64 + 1
_ELSE
      iq_heap(numheap) = iq_8 - iqoff
_ENDIF
c
_ELSEIF(dynamic_memory)
c
c handle is actually the exact memory address relative to 
c the vcore qq array. eventually, it may differ from
c iq_heap because of the need to ensure correct allignment
c
      call mallocc2(qq(1),qq(2),size,iq_heap(numheap),
     &     itag_heap(numheap))
c
      osuccess = (iq_heap(numheap) .ne. 0)
c
_ELSE
c
c implementation in terms of GAMESS-UK stack
c
c  based on model code...
c      length=n*n           
c      call cmem(loadcm  sets loadcm to top of core  (ntotly)
c      call setscm(i10)  get address of next scm bloc
c            k of core (ntotly + 1)
c      last=i10+length      !  
c      loc10=loccm()        !   ( returns ntotly )
c      need=loc10+length    !   
c      call setc(need)      !
c
c
c get current top of core
      call cmem(loadcm) 
c
c return address of the nect scm block of core
      call setscm(i10)
c
c loccm currently always returns ntotly
      loc10 = loccm()
c
c new top address, allowing 4 words for guards
      need = loc10 + size + 4

      if(oprintm) then
         write(iwr,*) 'loadcm ',loadcm,
     &        ' loc10 ',loc10,' i10 ',i10
      endif

      if(need.gt.nmaxly)then
         numheap = numheap - 1
         return
c        write(iwr,200) size, nmaxly-loc10-4
c200     format(1x,'memory allocation error: need',i10,' avail ',i10)
c        call caserr('memory ran out')
      endif

      call setc(need) 
c
c  determine stored offset (following MA convention)
c
      iq_heap(numheap) = i10 + 2
c
c  allocate a tag for tracing 
c
      igmem_count = igmem_count+1
      itag_heap(numheap) = igmem_count
c
c the gamess allocator as currently implemented uses a single
c physical stack - so the address allocated is 1 greater than 
c the "loadcm" value used to free the data. We use this
c assumption, so check for changes that may invalidate it
c
      if(i10 .ne. loadcm+1)call caserr('addressing error')
c
c define values of guards
c
      iqoff=0

      Q(iq_heap(numheap)-iqoff-2) = size
      Q(iq_heap(numheap)-iqoff-1) = 111.0d0
      Q(iq_heap(numheap)-iqoff+size) = 222.0d0
      Q(iq_heap(numheap)-iqoff+size+1) = size
c
      osuccess = .true.
c
_ENDIF
c
      if (osuccess) then
         offset = iq_heap(numheap) 
         if (ogmem_nanify) then
            call gmem_nanify(Q(offset),size)
         endif
         if (ogmem_debug) then
            call gmem_check_guards('gmem_alloc')
         endif
      else 
         numheap = numheap - 1
         offset = igmem_null()
      endif
      ogmem_alloc_kernel = osuccess
c
      return
      end

      function igmem_max_memory ()
c
      implicit none
      integer igmem_max_memory
      logical ogmem_alloc_all_kernel
      integer nmaxly, ioff
      logical osuccess
      logical osave_nanify
      character*30 tag
      data tag/"igmem_max_memory"/
INCLUDE(common/gmemdata)
c
c     determine total memory currently available, and use
c     this in deriving data storage. Note that the allocation
c     and subsequent freeing may be inefficient.
c
_IF(ma)
#include "mafdecls.fh"
c
      MA_INTEGER type_8, size_8, itag_8, iq_8
c
      type_8 = MT_DBL
      size_8 = ma_inquire_avail(type_8)
      igmem_max_memory = size_8
_ELSE
      osave_nanify = ogmem_nanify
      ogmem_nanify = .false.
      osuccess = ogmem_alloc_all_kernel(nmaxly,tag,ioff)
      ogmem_nanify = osave_nanify
      if (osuccess) then
         igmem_max_memory = nmaxly
         call gmem_free_kernel(ioff)
      else
         igmem_max_memory = 0
      endif
_ENDIF
c
      return
      end


c **********************************************************************
c *
c * ogmem_alloc_all_kernel(size,tag,offset) :  allocate all memory 
c *                                            available
c *
c *    This routine does the real work and never prints any 
c *    diagnostics. This routine should NEVER be called directly
c *    from an application.
c *    The return value is .true. if the allocation was successful
c *
c *                size - size of memory segment (output)
c *                tag  - name of memory segment (input)
c *                offset - offset to memory allocated (output)
c *
c **********************************************************************

      logical function ogmem_alloc_all_kernel(size,tag,offset)

      implicit none
INCLUDE(common/gmemdata)
      integer size, offset
      character tag*(*)
      integer lentag
      logical osuccess
      logical opg_root
      integer igmem_null

_IF(ma)
#include "mafdecls.fh"
c
      MA_INTEGER type_8, size_8, itag_8, iq_8
c
INCLUDE(common/vcore)

_IF(64bitpointers)
      integer*8 iq64
      common/pointer64/iq64
_ENDIF

      osuccess = .false.
      ogmem_alloc_all_kernel = osuccess
      size = 0
      offset = igmem_null()

      numheap = numheap + 1

      type_8 = MT_DBL
      size_8 = ma_inquire_avail(type_8)
      osuccess = ma_alloc_get(
     &     type_8,
     &     size_8,
     &     tag,
     &     itag_8,
     &     iq_8)
      itag_heap(numheap) = itag_8

_IF(64bitpointers)
      iq_heap(numheap) = iq_8 - iq64 + 1
_ELSE
      iq_heap(numheap) = iq_8 - iqoff
_ENDIF
      size = size_8

_ELSEIF(dynamic_memory)
      igmem_alloc_all_kernel = 0
      call caserr('gmem func not available')
_ELSE
c
c  GAMESS-UK stack implementation
c
INCLUDE(common/vcore)
INCLUDE(common/segm)
INCLUDE(common/iofile)
      integer loadcm, i10, loc10, loccm, need
c
c  based on model code...
c      length=n*n           
c      call cmem(loadcm  sets loadcm to top of core  (ntotly)
c      call setscm(i10)  get address of next scm bloc
c            k of core (ntotly + 1)
c      last=i10+length      !  
c      loc10=loccm()        !   ( returns ntotly )
c      need=loc10+length    !   
c      call setc(need)      !
c
      osuccess = .false.
      ogmem_alloc_all_kernel = osuccess
      size = 0
      offset = igmem_null()

      numheap = numheap + 1

c get current top of core
      call cmem(loadcm)   

c return address of the nect scm block of core
      call setscm(i10)

c loccm currently always returns ntotly
      loc10 = loccm()
c
c work out available size allowing 4 words for guards
      size = nmaxly - i10 - 4 + 1
      need = nmaxly

      if(size.lt.0)then
c        write(iwr,200)
c200     format(1x,'memory allocation error: gmem_alloc_all but no',
c    +        ' core remains')
c        call caserr('memory ran out')
         numheap = numheap - 1
         return
      endif

      call setc(need) 
c
c  determine stored offset (following MA convention
c
c      write(6,*)'gamess addr',i10
      iq_heap(numheap) = i10 + 2
c
c  allocate a tag for tracing 
c
      igmem_count = igmem_count+1
      itag_heap(numheap) = igmem_count
c
c the gamess allocator as currently implemented uses a single
c physical stack - so the address allocated is 1 greater than 
c the "loadcm" value used to free the data. We use this
c assumption, so check for changes that may invalidate it
c
      if(i10 .ne. loadcm+1) call caserr('addressing error')
c
c define values of guards
c
      iqoff=0

      Q(iq_heap(numheap)-iqoff-2) = size
      Q(iq_heap(numheap)-iqoff-1) = 111.0d0
      Q(iq_heap(numheap)-iqoff+size) = 222.0d0
      Q(iq_heap(numheap)-iqoff+size+1) = size
c
      osuccess = .true.
c
_ENDIF
c
      if (osuccess) then
         offset = iq_heap(numheap)
         if (ogmem_nanify) then
            call gmem_nanify(Q(offset),size)
         endif
      else
         numheap = numheap - 1
      endif
      ogmem_alloc_all_kernel = osuccess
c
      return
      end

c **********************************************************************
c *
c *   gmem_free_kernel(iq) : free memory at offset iq
c *
c *    This routine does the real work and does not print any 
c *    information. The routine does trigger an error exit if it
c *    finds the memory corrupted. This routine should NEVER be called 
c *    directly from an application.
c *
c **********************************************************************

      subroutine gmem_free_kernel(iq)
      implicit none
c
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer igmem_null
_IF(ma)
c
c decls to replace include of "mafdecls.h"
c
      MA_INTEGER itag_8
      MA_LOGICAL ma_free_heap
_ELSEIF(dynamic_memory)
INCLUDE(common/vcore)
      integer istat
_ELSE
INCLUDE(common/vcore)
      integer loadcm, size
_ENDIF
c
      logical ostat, opg_root
      integer iq, ix
      ostat = .true.
      if (ogmem_debug) then
         call gmem_check_guards('gmem_free')
      endif
      do  ix = numheap,1,-1
         if(iq.eq. iq_heap(ix))then
            if(ix .ne. numheap) then
               write(iwr,600)ix,numheap
               write(iwr,610)iq_heap(ix),iq_heap(numheap)
               call caserr('non-stack memory')
            endif
600         format('You want to free memory chunk ',i3,
     +             ' but the top of stack is memory chunk ',i3)
610         format('The indeces are ',i8,' and ',i8,' respectively.')
_IF(ma)
            itag_8 = itag_heap(ix)
            ostat = ma_free_heap(itag_8)
_ELSEIF(dynamic_memory)
            call freec(qq(1),itag_heap(ix),istat)
            ostat = istat .eq. 0
_ELSE
c
c implementation in terms of GAMESS-UK stack
c
c check guards
c
            size = nint(Q(iq_heap(ix)-2))
            if(ogmem_debug)then
               call gmem_check_guards(' gmem_free ')

               write(6,*)size,Q(iq_heap(ix)-1)
               write(6,*)nint(Q(iq_heap(ix)+size+1)),
     &              Q(iq_heap(ix)+size)
            endif

            if(size.lt.0.or.
     &           Q(iq_heap(ix)-1).ne.111.0d0)then
               write(iwr,100)itag_heap(ix),iq_heap(ix)
 100           format(1x,'problem with lower guard, memory handle',i7,
     &                ' address',i7)
               call caserr('problem with memory guard')
            endif

            if(nint(Q(iq_heap(ix)+size+1)) .ne. size .or.
     &           Q(iq_heap(ix)+size).ne.222.0d0)then
               write(iwr,101)itag_heap(ix),iq_heap(ix)
 101           format(1x,'problem with upper guard, memory handle',i7,
     &                ' address',i7)
               call caserr('problem with memory guard')
            endif

            loadcm = iq_heap(ix) - 3
            call setc( loadcm )
_ENDIF
c           if(opg_root() .and. ogmem_debug)
c    &           write(6,*)'free memory handle= ',itag_heap(ix)
            numheap = numheap - 1
            if (.not.ostat)call caserr('problem freeing memory ')
            iq = igmem_null()
            return
         endif
      enddo

      if(opg_root())write(6,*)'attempt to free address= ',iq

      call caserr('gmem_free - bad address')
      end
c
c  - allocate a reserved region
c
      integer function igmem_reserve_region(size)
      implicit none
INCLUDE(common/gmemdata)
_IF(ma)
#include "mafdecls.fh"
      MA_INTEGER size_8, type_8, itag_8, iq_8
      logical ostat
_ELSE
INCLUDE(common/vcore)
_ENDIF
      integer size
      logical opg_root
      character tag*30

      nresreg = nresreg + 1
      if(nresreg.gt.mxresreg)call 
     &     caserr('too many reserved memory regions requested')

      numheap = numheap + 1
      write(tag,100)nresreg
 100  format('reserve_',i3.3)

_IF(ma)
      type_8 = MT_DBL
      size_8 = size
      ostat = ma_alloc_get(
     &     type_8,
     &     size_8,
     &     tag,
     &     itag_8,
     &     iq_8)
      itag_heap(numheap) = itag_8
      iq_heap(numheap) = iq_8 - iqoff
      if (.not.ostat)call caserr('allocating heap ')
_ELSE
      call caserr('gmem func unavailable')
_ENDIF
c
      iadr(0,nresreg) = iq_heap(numheap) - 1
      isize(nresreg) = size
      nres(nresreg) = 0
      igmem_reserve_region = nresreg
      if(opg_root()  .and. ogmem_debug)then
         write(6,*)'reserve region tag=',tag(1:10),
     &        'base address =',iadr(0,nresreg) + 1,' size=',size
      endif
      return
      end

      subroutine gmem_free_region(ires)
      implicit none

INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
_IF(ma)
c
c replacements for include "mafdecls.h"
c
      MA_LOGICAL ma_free_heap
      MA_INTEGER tag_8
      logical ostat
_ELSE
INCLUDE(common/vcore)
_ENDIF
      integer ires
      logical opg_root
      integer iq, ix
      if(ires.ne.nresreg)call 
     &     caserr('bad gmem_free_region call')

      iq = iadr(0,nresreg) + 1

      do  ix = 1,numheap
         if(iq.eq. iq_heap(ix) )then
            if(ix .ne. numheap)then
               write(iwr,600)ix,numheap
               write(iwr,610)iq_heap(ix),iq_heap(numheap)
               call caserr('non-stack memory')
            endif
600         format('You want to free memory chunk ',i3,
     +             ' but the top of stack is memory chunk ',i3)
610         format('The indeces are ',i8,' and ',i8,' respectively.')
_IF(ma)
      tag_8 = itag_heap(ix)
            ostat = ma_free_heap(tag_8)
_ELSE
      call caserr('gmem func unavailable')
_ENDIF
            if(opg_root()  .and. ogmem_debug)
     &           write(6,*)'free reserver handle= ',itag_heap(ix)
            numheap = numheap - 1
cccc
            nresreg = nresreg - 1
cccc
            return
         endif
      enddo
      call caserr('gmem_free - bad address')
      end
c
      integer function igmem_alloc_reserved(ires,size)
      implicit none
INCLUDE(common/gmemdata)
      integer size, nleft, ires
      logical opg_root
c
c check space..
c
      if(ires.lt.0.or.ires.gt.nresreg)call 
     &     caserr('bad reserved memory region index')

      nleft = isize(ires) - ( iadr(nres(ires),ires) - 
     &     iadr(0,ires) )
      if(nleft . lt . size)call 
     &     caserr('reserved memory region too small')
      nres(ires) = nres(ires) + 1
      if(nres(ires) .gt. mxressect)call
     &     caserr('too many sections from reserved region')
      iadr(nres(ires),ires) = iadr(nres(ires) - 1,ires) + size
      igmem_alloc_reserved = iadr(nres(ires) - 1,ires) + 1
      if(opg_root()  .and. ogmem_debug)then
        write(6,*)'mem from reserved region=',ires,'index=',nres(ires),
     &        'address=',igmem_alloc_reserved
      endif
      return
      end

      subroutine gmem_free_reserved(ires,i)
      implicit none
INCLUDE(common/gmemdata)
      logical opg_root
      integer ires, i
      if(ires.lt.0.or.ires.gt.nresreg)call 
     &     caserr('bad reserved memory region index')
      if(opg_root()  .and. ogmem_debug)then
         write(6,*)'free mem from reserved region=',ires,
     &        'index=',nres(ires),
     &        'address=',iadr(nres(ires) - 1,ires) + 1
         if(iadr(nres(ires) - 1,ires) .ne. i - 1)call
     &        caserr('non-stack gmem_free_reserved call')
      endif
      nres(ires) = nres(ires) - 1
      return
      end
_IFN(ma)
      subroutine ma_summarize_allocated_blocks
      return
      end
_ENDIF

c
c **********************************************************************
c *
c *   gmem_nanify(core,size) : set contents of core to NaN.
c *
c *   This routine sets the contents of the a real memory segment to
c *   NaN. This is to be used only for debugging purposes so as to test
c *   for failures to initialise data properly.
c *
c **********************************************************************
c
      subroutine gmem_nanify(core,size)
      implicit none
c
c     Input/Output
c
      integer size
      REAL core(size)
c
c     Local
c
      integer iunk(2),i
      REAL junk
      equivalence(junk,iunk(1))
c
      iunk(1) = -1
      iunk(2) = -1
      do i = 1, size
         core(i) = junk
      enddo
      end

c ********************************************************************
c *
c * gmem_check_guards :  checks guards without freeing memory
c *
c *  
c *
c ********************************************************************

      subroutine gmem_check_guards(text)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/vcore)
INCLUDE(common/iofile)
      character*(*) text

_IF(ma)
      logical MA_verify_allocator_stuff, ostat
      write(iwr,*)'checking memory guards ',text
      ostat = MA_verify_allocator_stuff()
_ELSEIF(dynamic_memory)
      write(iwr,*)'checking memory guards not available ',text
_ELSE
      integer ix, size
      write(iwr,*)'checking memory guards numheap=',numheap,text
      do  ix = 1,numheap

         size = nint(Q(iq_heap(ix)-2))
         if(ogmem_debug)then
cc            write(6,*)size,Q(iq_heap(ix)-1)
cc            write(6,*)nint(Q(iq_heap(ix)+size+1)),
cc     &           Q(iq_heap(ix)+size)
         endif
 
         if(size.lt.0.or.
     &        Q(iq_heap(ix)-1).ne.111.0d0)then
            write(iwr,100)itag_heap(ix),iq_heap(ix)
 100        format(1x,'problem with lower guard, memory handle',i7,
     &             ' address',i7)
         endif
 
         if(nint(Q(iq_heap(ix)+size+1)) .ne. size .or.
     &        Q(iq_heap(ix)+size).ne.222.0d0)then
            write(iwr,101)itag_heap(ix),iq_heap(ix)
 101        format(1x,'problem with upper guard, memory handle',i7,
     &             ' address',i7)
         endif
         
      enddo
_ENDIF
      return
      end

      subroutine gmem_summarize(filename,subrname,tag,ipriority)
      implicit none
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer ipriority
      character *(*) filename,subrname,tag
      integer i
      logical opg_root
      external opg_root
c
      if (opg_root().and.ipriority.le.igmem_print) then
         write(iwr,600)filename,subrname,tag,numheap,igmem_totsize(0)
 600     format(//,
     &          1x,'gmem_summarize',/,
     &          1x,'==============',/,
     &          1x,'in file=',a16,' routine=',a16,' tag=',a16,/,
     &          1x,'on stack are ',i8,' chunks totalling ',i8,' words:')
         do i=numheap,1,-1
            write(iwr,630)i,iq_heap(i),itag_heap(i),igmem_size(i),
     &                    zgmem_varid(i)
 630        format(1x,'chunk=',i3,' address=',i8,' handle=',i8,
     &                ' size=',i8,' name=',a16)
         enddo

         call gmem_highwater(ipriority)
      endif
      end

      subroutine gmem_highwater(ipriority)
      implicit none
_IF(ga)
#include "mafdecls.fh"
_ENDIF
INCLUDE(common/gmemdata)
INCLUDE(common/iofile)
      integer ipriority
      integer i
      logical opg_root
      external opg_root
_IF(ga)
      MA_LOGICAL ga_uses_ma
_ENDIF
c
      if (opg_root().and.ipriority.le.igmem_print) then
         write(iwr,600)
 600     format(/,
     &          1x,'Memory high water mark',/,
     &          1x,'======================',/)
         if (ogmem_alloced_all) then
            write(iwr,605)
         endif
         write(iwr,610)igmem_maxsize(0)
_IF(ga)
         if (.not.ga_uses_ma()) then
            write(iwr,620)igamem_maxsize
         endif
_ENDIF
         if (igmem_totsize(0).ne.0) then
            write(iwr,630)igmem_totsize(0)
         endif
_IF(ga)
         if (.not.ga_uses_ma().and.igamem_totsize.ne.0) then
            write(iwr,640)igamem_totsize
         endif
_ENDIF
 605     format(1x,'*** accurate heap memory high water mark not ',
     &             'available',
     &        /,1x,'*** allocation of ALL memory occurred at ',
     &             'some point',/,
     &          1x,'*** the high water mark below excludes such ',
     &             'allocations',/)
 610     format(1x,'heap memory high water mark = ',i12,' words')
 620     format(1x,'GA   memory high water mark = ',i12,
     &             ' words overall')
 630     format(1x,'*** heap not cleared ',i12,' words remain',
     &             ' allocated')
 640     format(1x,'*** GAs  not cleared ',i12,' words remain',
     &             ' allocated')

      endif
      end
c
c     Set the nanify flag
c
      subroutine gmem_set_nanify(flag)
      implicit none
      logical flag
INCLUDE(common/gmemdata)
      ogmem_nanify = flag
      end
c
c controls memory debug print
c
      subroutine gmem_set_debug(flag)
      implicit none
      logical flag
INCLUDE(common/gmemdata)
INCLUDE(common/gmempara)
      ogmem_debug = .false.
      if (flag) then
        igmem_print = IGMEM_DEBUG
      else 
        igmem_print = IGMEM_NORMAL
      endif
      end
c
      subroutine gmem_set_quiet(flag)
      implicit none
      logical flag
INCLUDE(common/gmemdata)
INCLUDE(common/gmempara)
      ogmem_debug = .false.
      if (flag) then
        igmem_print = IGMEM_QUIET
      else 
        igmem_print = IGMEM_NORMAL
      endif
      end
c
      subroutine memtest(q,nmaxly)
      implicit none
      REAL q(*)
      REAL small
      integer i, iq, iq2, nmaxly, itest

      integer igmem_alloc_inf
      external igmem_alloc_inf

INCLUDE(common/gmempara)  
INCLUDE(common/vcore)  
      character*10 fnm
      character*7  snm

      data fnm/'parallel.m'/
      data snm/'memtest'/

      small = 0.0001d0
c
c test passed q
c
c      write(6,*)'test q'
c      do i=1, nmaxly
c         q(i) = 99.0d0
c      enddo
c      do i=1, nmaxly
c         if(dabs(q(i) - 99.0d0) .gt. small)write(6,*)q(i)
c      enddo
c

      call gmem_set_debug(.true.)

      itest = (nmaxly - 100) / 2
      write(6,*)'allocate',itest
      iq = igmem_alloc_inf(itest,fnm,snm,'iq',IGMEM_DEBUG)
      write(6,*)'allocate',itest
      iq2 = igmem_alloc_inf(itest,fnm,snm,'iq2',IGMEM_DEBUG)

      write(6,*)'test q(iq)', iq, iq2
      do i=1, itest
         q(iq+i-1) = 99.0d0
      enddo
      do i=1, itest
         if(dabs(q(iq+i-1) - 99.0d0) .gt. small)write(6,*)q(i)
      enddo
          
      call gmem_free_inf(iq2,fnm,snm,'iq2')
      call gmem_free_inf(iq,fnm,snm,'iq')

      itest = nmaxly - 100

      write(6,*)'test Q(iq)',itest

      iq = igmem_alloc_inf(itest,fnm,snm,'iq',IGMEM_DEBUG)

      do i=1, itest
         Q(iq+i-1) = 99.0d0
      enddo
      do i=1, itest
         if(dabs(Q(iq+i-1) - 99.0d0) .gt. small)
     &        write(6,*)Q(iq+i-1)
      enddo

      call gmem_free_inf(iq,fnm,snm,'iq')

      end
      subroutine debugp(s)
      implicit none
      character s*(*)
INCLUDE(common/parcntl)
      integer ipg_nodeid
      if(odebugp)then
         write(6,*)'PAR:',ipg_nodeid(),s
      endif
      end
_IF(ga_ci_build)
      subroutine getmyminmax(myminb,mymaxb)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/ga_file)
INCLUDE(common/disktl)
#include "mafdecls.fh"
      iga_to_use = ga_file_unit_to_ga( numcz )
      call pg_distribution(ga_file_handle(iga_to_use),ipg_nodeid(),
     1 il,ih,jl,jh)
      myminb = (il-1)/ga_file_block + 1
      mymaxb = ih/ga_file_block
      return
      end

      subroutine gczips(iblkf,iblkt,oc,iwr,conf,icblok)
c works only for ga-file ...
c      add up a c/z-vector and scatter it over the nodes
c      partial vector at iblkf, compact result at iblkt
c       if (.not.oc) do not add just compact on each node (for c)
c      in nw return # words written
c      kind of getcz action
c      *note* the n-2 c/z vectors are singlet/triplet adjacent on node
c
      implicit REAL  (a-h,o-z)
      dimension conf(*)
INCLUDE(common/sizes)
INCLUDE(common/prnprn)
      parameter (nbuf=511*5)
      common /scra/ buf(nbuf),work(nbuf)
INCLUDE(common/disktl)
      common/nodinf/mpid,minode,mihost,ldim,nnodes,nodscr,maxnod(16)
      common/noddav/nwips,iblock1,iblock2,nwords,nread
INCLUDE(common/cntrl)
INCLUDE(common/ga_file)
      common/remc_ed19/idblok,ipoint,idiagoff
#include "mafdecls.fh"
      MA_INTEGER il8,ih8,jl8,jh8,ind8,ld8,ga_fh8
c
       logical oipsci,oc,omode
c
      if(odebug(40)) write(iwr,*)' entered gczips'
      ibl = iblkt
      ibbb=iblkf
c
c ... c-vector omode = .true.
c
      omode = .false.
      if (iblkf.eq.index(26)) omode = .true.
      iga_to_use = ga_file_unit_to_ga( numcz )
      call pg_distribution(ga_file_handle(iga_to_use),ipg_nodeid(),
     1 il,ih,jl,jh)
      myminb = (il-1)/ga_file_block + 1
      mymaxb = ih/ga_file_block
      ga_fh8 = ga_file_handle(iga_to_use)
      il8 = il
      ih8 = ih
      jl8 = jl
      jh8 = jh
      call ga_access(ga_fh8,il8,ih8,jl8,jh8,ind8,ld8)
      ld  = ld8
      ind = ind8
      call distrcz(dbl_mb(ind),ld,il,ih,jl,jh,ibbb,myminb,mymaxb,
     1 conf(ipoint),omode,ibl,oc,icblok)
      call ga_release_update(ga_fh8,il8,ih8,jl8,jh8)
      return
      end

      subroutine dczips(iconf,iblkf,iblkt,iwr)
c works only for ga-file ...
c      add up a c/z-vector and scatter it over the nodes
c      partial vector at iblkf, compact result at iblkt
c       if (.not.oc) do not add just compact on each node (for c)
c      in nw return # words written
c      kind of getcz action
c      *note* the n-2 c/z vectors are singlet/triplet adjacent on node
c
      implicit REAL  (a-h,o-z)
      REAL iconf
      dimension iconf(*)
INCLUDE(common/sizes)
INCLUDE(common/prnprn)
      parameter (nbuf=511*5)
      common /scra/ buf(nbuf),work(nbuf)
INCLUDE(common/disktl)
      common/nodinf/mpid,minode,mihost,ldim,nnodes,nodscr,maxnod(16)
      common/noddav/nwips,iblock1,iblock2,nwords,nread
INCLUDE(common/cntrl)
INCLUDE(common/ga_file)
      common/remc_ed19/nnblok,ipoint,idiagoff
#include "mafdecls.fh"
c
      MA_INTEGER ga_fh8,id8,il8,ih8,jl8,jh8,ind8,ld8
       logical oipsci,oc,omode
c
      if(odebug(40)) write(iwr,*)' entered dczips'
      ibl = iblkt
      ibbb=iblkf
c
c ... c-vector omode = .true.
c
      omode = .false.
      if (iblkf.eq.index(26)) omode = .true.
      iga_to_use = ga_file_unit_to_ga( numcz )
      call pg_distribution(ga_file_handle(iga_to_use),ipg_nodeid(),
     1 il,ih,jl,jh)
      myminb = (il-1)/ga_file_block + 1
      mymaxb = ih/ga_file_block
      ga_fh8 = ga_file_handle(iga_to_use)
      il8 = il
      ih8 = ih
      jl8 = jl
      jh8 = jh
      call ga_access(ga_fh8,il8,ih8,jl8,jh8,ind8,ld8)
      ld  = ld8
      ind = ind8
      call czdumpga(dbl_mb(ind),ld,il,ih,jl,jh,ibbb,myminb,mymaxb,
     1 iconf(ipoint),omode,ibl)
      call ga_release_update(ga_fh8,il8,ih8,jl8,jh8)
      return
      end
_ENDIF
      subroutine ver_parallel(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/parallel.m,v $
     +     "/
      data revision /"$Revision: 6287 $"/
      data date /"$Date: 2013-05-27 14:27:44 +0200 (Mon, 27 May 2013) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
