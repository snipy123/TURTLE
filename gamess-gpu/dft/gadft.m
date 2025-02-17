_IF(ga)
c---- memory counting routines -----------------------------------------
c
      Subroutine memreq_dft_invdiag(g_A, g_cdinv, n)

      implicit none
c      
      integer geom,basis
      integer g_a   ! [input]
      integer g_cdinv ! [output]
      integer n

      REAL t_start, t_end

c
#include "mafdecls.fh"
#include "global.fh"

      logical pg_create_cnt, pg_destroy_cnt
      integer incr_memory2

INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/gmempara)
INCLUDE(../m4/common/vcore)
INCLUDE(../m4/common/parcntl)
c
      integer luout

      integer myproc,nproc,i,j,g_tmp2
      integer lev,iev,ltmp,itmp
      REAL toll,THRESHOLD
      parameter (toll=1.d-6,THRESHOLD=1.D-9)
      character*7 fnm
      character*18 snm
c
      data fnm/"gadft.m"/
      data snm/"memreq_dft_invdiag"/

      luout = iwr

c     call walltime(t_start)
c     write(6,*)'enter inv diag'
c
      myproc=ga_nodeid()
      nproc=ga_nnodes()
c     call ga_sync
      if (.not. pg_create_cnt(0, n, n, 'ga_temp2', n, 1, g_tmp2))
     &   call caserr('error creating ga_temp2')
c
      iev = incr_memory2(n,'d',fnm,snm,'evals')
      itmp = incr_memory2(n,'d',fnm,snm,'itmp')
c     
C     diag

c     call walltime(t_end)
c     write(6,*)'start diag',me,t_end-t_start
c     t_start = t_end

c     call ga_sync
_IF(diag_parallel)
      if (n.le.idpdiag) then
        call memreq_ga_diag_std_seq(g_A,g_tmp2,Q(iev),n)
      else
        call memreq_ga_diag_std(Q(1),Q(1),g_A,g_tmp2,
     +                          Q(iev),n)
      endif
_ELSE
      call caserr2('memreq_dft_invdiag: no parallel diag available')
_ENDIF

C     check on eigenvalues

c     call walltime(t_end)
c     write(6,*)'complete diag',myproc,t_end-t_start
c     t_start = t_end


c     do i=0,n-1
c       if(abs(Q(iev+i)).lt.toll) then
c         if(me.eq.0) write(LuOut,*) ' GAFACT - singular eigenvalue',i
c         call flush(LuOut)
c         if (abs(Q(iev+i)).lt.THRESHOLD) then
c            now we really need to do something.
c            if (Q(iev+i).lt.0.0d0) then
c               Q(iev+i)=-1.0d0/THRESHOLD
c            else
c               Q(iev+i)=+1.0d0/THRESHOLD
c            endif
c         else
c            Q(iev+i)=1.d0/Q(iev+i)
c         endif
c       else
c         Q(iev+i)=1.d0/Q(iev+i)
c       endif 
c     enddo

C     (U * sigma^-1)


c     call walltime(t_end)
c     write(6,*)'done invert',myproc,t_end-t_start
c     t_start = t_end


c     do i=myproc+1,n,nproc
c       call ga_get(g_tmp2,1,n,i,i,Q(itmp),1)
c       do j=0,n-1
c         Q(itmp+j)=Q(itmp+j)*Q(iev+i-1)
c       enddo
c       call ga_put(g_A,1,n,i,i,Q(itmp),1)
c     enddo


c     call walltime(t_end)
c     write(6,*)'done put',myproc,t_end-t_start
c     t_start = t_end

c     call ga_sync

C     (U * sigma^-1) * U(transp) 
      
c     call ga_dgemm('N','T',n,n,n,1.d0,g_A,g_tmp2,0.d0,g_cdinv)


c     call walltime(t_end)
c     write(6,*)'done dgemm',myproc,t_end-t_start
c     t_start = t_end

      call decr_memory2(itmp,'d',fnm,snm,'itmp')
      call decr_memory2(iev,'d',fnm,snm,'evals')

c     call ga_SYNC

      if (.not. pg_destroy_cnt(g_tmp2))
     &   call caserr('memreq_dft_invdiag: could not destroy g_tmp2')

c     call walltime(t_end)
c     write(6,*)'final',myproc,t_end-t_start
c     t_start = t_end

      return
      end
c
c-----------------------------------------------------------------------
c
_IF(diag_parallel)
      Subroutine memreq_ga_diag_std(memory_fp,memory_int,g_A, g_cdinv,
     &                              eval, n)

      implicit none
c      
      integer g_a   ! [input]
      integer g_cdinv ! [output]
      integer n
      integer memory_int(*)
      REAL memory_fp(*)
      REAL eval

      REAL t_start, t_end

c
#include "mafdecls.fh"
#include "global.fh"

      logical pg_create_cnt, pg_destroy_cnt
      integer incr_memory2
      integer allocate_memory2
      integer push_memory_estimate
      integer pop_memory_estimate
      integer memory_overhead

INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/gmempara)
c
      integer luout

      integer myproc,nproc,i,j,g_tmp2,proc
      integer mycol,myelem,mypanel
      integer elemz,pan,npan,iproc,ipan,ik,k
      integer lev,iev,ltmp,itmp
      logical oactive
      REAL toll,THRESHOLD
      parameter (toll=1.d-6,THRESHOLD=1.D-9)
      integer iptr, irsize, iisize, ihis, ihz, iha, ihls, ihma, ihmz
      integer isize, rsize, ptr_size
      integer iphma, iphmz, iphls, iphis
      character*7 fnm
      character*18 snm
c
      integer elem, istart, iend
      elem(istart,iend,n)=((iend-istart+1)*(2*n-istart-iend+2))/2
c
      data fnm/"gadft.m"/
      data snm/"memreq_ga_diag_std"/

      luout = iwr

      myproc=ga_nodeid()
      nproc=ga_nnodes()
c
c     guess memory requirements for ga_diag_std
c
      pan = 1                   !panel size
      npan = n/pan
      proc = min(n/30,nproc)
      oactive = myproc.lt.proc
      if (oactive) then
         ihma = incr_memory2(n,'i',fnm,snm,'mapa')
         ihmz = incr_memory2(n,'i',fnm,snm,'mapz')
         ihls = incr_memory2(proc,'i',fnm,snm,'list')
c
         iphma = allocate_memory2(n,'i',fnm,snm,'mapa')
         iphmz = allocate_memory2(n,'i',fnm,snm,'mapz')
         iphls = allocate_memory2(n,'i',fnm,snm,'list')
         call ga_list_nodeid(memory_int(iphls),proc)
c
c        determine distribution of a,b, and z
c
         mypanel = 0            ! number of panels at given processor
         mycol   = 0            ! number of columns at given processor
         myelem  = 0            ! number of elements at given processor
c
c        allocate first half of the panels - forwards
c
         do ipan = 1, npan/2
            iproc = mod(ipan -1, proc)
            istart = (ipan - 1)*pan + 1
            iend   = istart + pan - 1
            do k = istart, iend
               memory_int(iphma+k-1) = memory_int(iphls+iproc)
               memory_int(iphmz+k-1) = memory_int(iphls+iproc)
            enddo
            if(iproc .eq. myproc)then
               myelem = myelem + elem(istart,iend,n)
               mypanel = mypanel+1
            endif
         enddo
c
c        allocate second half of the panels - backwards
c
         ik = 1                 !ik is used to forward number processors
         do ipan =   npan-1, npan/2 +1 , -1
            ik = ik+1
            iproc = mod(ik -1, proc)
            istart = (ipan - 1)*pan + 1
            iend   = istart + pan - 1
            do k = istart, iend
               memory_int(iphma+k-1) = memory_int(iphls+iproc)
               memory_int(iphmz+k-1) = memory_int(iphls+iproc)
            enddo
            if(iproc .eq. myproc)then
               myelem = myelem + elem(istart,iend,n)
               mypanel = mypanel+1
            endif
         enddo
c
c***     actually, there is one more panel left for the mismatch
c
         iproc  = 0             !processor 0 gets the mismatch panel
         istart = (npan - 1)*pan + 1
         iend   = n
         do k = istart, iend
            memory_int(iphma+k-1) = memory_int(iphls+iproc)
            memory_int(iphmz+k-1) = memory_int(iphls+iproc)
         enddo
         mycol = mypanel * pan
         if(iproc .eq. myproc)then
            myelem = myelem + elem(istart,iend,n)
            mycol  = mycol + iend - istart + 1
         endif
         elemz = mycol * n
c
         iha = incr_memory2(myelem,'d',fnm,snm,'ha')
         ihz = incr_memory2(elemz,'d',fnm,snm,'hz')
         ihis = incr_memory2(6*n,'i',fnm,snm,'his')
         iphis = allocate_memory2(6*n,'i',fnm,snm,'his')
         call fmemreq(1,n,memory_int(iphma),memory_int(iphma),
     &                memory_int(iphmz),isize,rsize,
     &                ptr_size,memory_int(iphis))
         call free_memory2(iphis,'i',fnm,snm,'his')
         call decr_memory2(ihis,'i',fnm,snm,'his')
c
c        guess memory requirements for pdspev (based on GA routines)
c
         iisize = incr_memory2(isize,'i',fnm,snm,'isize')
         irsize = incr_memory2(rsize,'d',fnm,snm,'rsize')
         iptr = incr_memory2(ptr_size,'d',fnm,snm,'ptrsze')
         call decr_memory2(iptr,'d',fnm,snm,'ptrsze')
         call decr_memory2(irsize,'d',fnm,snm,'rsize')
         call decr_memory2(iisize,'i',fnm,snm,'isize')
c
c        end of pdspev
c
         call decr_memory2(ihz,'d',fnm,snm,'hz')
         call decr_memory2(iha,'d',fnm,snm,'ha')
         call free_memory2(iphls,'i',fnm,snm,'list')
         call free_memory2(iphmz,'i',fnm,snm,'mapz')
         call free_memory2(iphma,'i',fnm,snm,'mapa')
         call decr_memory2(ihls,'i',fnm,snm,'list')
         call decr_memory2(ihmz,'i',fnm,snm,'mapz')
         call decr_memory2(ihma,'i',fnm,snm,'mapa')
      endif
c
      return
      end
_ENDIF
c
c  =============================================================
c
      subroutine memreq_ga_diag_std_seq(g_a,  g_v, evals, n)
      implicit none
#include "mafdecls.fh"
#include "global.fh"
      integer g_a               ! Matrix to diagonalize
      integer g_v               ! Global matrix to return evecs
      double precision evals(*) ! Local array to return evals
c
      integer n, ierr
      integer l_fv1, k_fv1, l_fv2, k_fv2
      integer l_a, k_a,  l_v, k_v
      integer dim1, dim2, type, me
      logical status
      integer incr_memory
c
c
c     Solve the standard eigen-value problem returning
c     all eigen-vectors and values in ascending order
c
c     The input matrices may be destroyed
c
c     call ga_check_handle(g_a, 'ga_diag_std a')
c     call ga_check_handle(g_v, 'ga_diag_std v')
c     call ga_sync()
c
c     Only process 0 does the diag
c
c     call ga_inquire(g_a, type, dim1, dim2)
c     if(dim1.ne.dim2)
c    $  call ga_error('ga_diag_std_seq: nonsquare matrix ',0)
 
c     n = dim1
      me = ga_nodeid()
      if (me .eq. 0) then
c
c     allocate scratch space
c     
         l_a = incr_memory(n*n,'d')
         l_v = incr_memory(n*n,'d')
         l_fv1 = incr_memory(n,'d')
         l_fv2 = incr_memory(n,'d')
c     
c     Fill local arrays from global arrays
c     
c        call ga_get(g_a, 1, n, 1, n, dbl_mb(k_a), n)
c     
c        call rs(n, n, dbl_mb(k_a),  evals, 1,
c    $        dbl_mb(k_v), dbl_mb(k_fv1), dbl_mb(k_fv2), ierr)
c
c     
c     Shove eigen-vectors back into global array
c     
c        call ga_put(g_v, 1, n, 1, n, dbl_mb(k_v), n)
c     
c     Free scratch space
c     
         call decr_memory(l_fv2,'d')
         call decr_memory(l_fv1,'d')
         call decr_memory(l_v,'d')
         call decr_memory(l_a,'d')
      endif
c     
c     Broadcast the eigenvalues to all processes
c
c     call ga_brdcst(32500, evals, 
c    $               ma_sizeof(MT_DBL,n,MT_BYTE), 0)
c     call ga_sync()
c
      end
c
c  =================== Global Array Utilities ==================
c
      subroutine dft_invert(g_A, g_cdinv, n)
      implicit none
c
c     Returns the inverse of the matrix A contained in g_A
c     in the array g_cdinv.
c
c     The routine uses either a Choleski decomposition if 
c     available (relies on the Global Arrays being build with
c     ScaLAPACK) or it uses the old dumb and inefficient diag
c     based approach.
c
INCLUDE(../m4/common/parcntl)
INCLUDE(../m4/common/iofile)
#include "global.fh"
c
c
c     Input
c
      integer g_A ! the matrix to invert
      integer n   ! the dimension of the matrix
c
c     Output
c
      integer g_cdinv ! the inverse of the matrix A
c
c     Local
c
      integer istatus ! status from ga_spd_invert
c
c     Code
c
      if (ipinvmode.eq.INV_CHOLESKY) then
        call ga_copy(g_A,g_cdinv)
        istatus = ga_spd_invert(g_cdinv)
        if (istatus.ne.0) then
          write(iwr,*)ga_nodeid()," *** ga_spd_invert failed ",istatus
          call caserr("dft_invert: ga_spd_invert failed")
        endif
      else if (ipinvmode.eq.INV_DIAG) then
        call dft_invdiag(g_A, g_cdinv, n)
      else
        call caserr('dft_invert: invalid ipinvmode')
      endif
      end
c
c-----------------------------------------------------------------------
c
      subroutine dft_invdiag(g_A, g_cdinv, n)

      implicit none
c      
      integer geom,basis
      integer g_a   ! [input]
      integer g_cdinv ! [output]
      integer n

      REAL t_start, t_end

c
#include "mafdecls.fh"
#include "global.fh"

      logical pg_create_inf, pg_destroy_inf
      integer allocate_memory2
      integer push_memory_estimate, push_memory_count
      integer pop_memory_estimate,  pop_memory_count
      integer memory_overhead
      integer imemestimate, imemusage
      integer imemcount, imemest, nmemest
      logical omemok, opg_root

INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/gmempara)
INCLUDE(../m4/common/vcore)
INCLUDE(../m4/common/parcntl)
cINCLUDE(common/dft_invdiag_mem)
c
c
      integer luout

      integer me,nproc,i,j,g_tmp2,nb
      integer lev,iev,ltmp,itmp,icnt
      REAL toll,THRESHOLD
      parameter (toll=1.d-6,THRESHOLD=1.D-9)
      integer iptr, irsize, iisize, ihis, ihz, iha, ihls, ihma, ihmz
      character*7 fnm
      character*11 snm
      data fnm/"gadft.m"/
      data snm/"dft_invdiag"/
      data omemok/.false./
_IF(debug)
      omemok = .false.
_ENDIF
      if (.not.omemok) then
         imemcount = push_memory_estimate()
         call memreq_dft_invdiag(g_A, g_cdinv, n)
         imemestimate = pop_memory_estimate(imemcount)
         imemcount = push_memory_count()
      endif


      luout = iwr

      call walltime(t_start)
c     write(6,*)'enter inv diag'
c
      me=ga_nodeid()
      nproc=ga_nnodes()
      call ga_sync
      if (.not. pg_create_inf(0, n, n, 'ga_temp2', n, 1, g_tmp2,
     &                        fnm,snm,IGMEM_NORMAL)) 
     &   call caserr('error creating ga_temp2')
c
      iev = allocate_memory2(n,'d',fnm,snm,'evals')
      itmp = allocate_memory2(n,'d',fnm,snm,'itmp')
c     
C     diag

      call walltime(t_end)
c     write(6,*)'start diag',me,t_end-t_start
      t_start = t_end

      call ga_sync
ccc#if defined(PARALLEL_DIAG)         
_IF(diag_parallel)
c
c     guess memory requirements for ga_diag_std
c
      imemest = push_memory_estimate()
      if (n.le.idpdiag) then
        call memreq_ga_diag_std_seq(g_A,g_tmp2,Q(iev),n)
      else
        call memreq_ga_diag_std(Q(1),Q(1),g_A,g_tmp2,
     +                          Q(iev),n)
      endif
      nmemest = pop_memory_estimate(imemest)
      if (nmemest.ne.0) then
         nmemest = nmemest - memory_overhead()
         ihis = allocate_memory2(nmemest,"d",fnm,snm,"his")
         call free_memory2(ihis,"d",fnm,snm,"his")
      endif
c
c     end of ga_diag_stv (if we get here we should be able to run the 
c                         call)
c
      nb = 0
      if (n.le.idpdiag) then
        call ga_diag_std_seq(g_A,g_tmp2,Q(iev))
      else if (ipdiagmode.eq.IDIAG_PEIGS) then
        call ga_diag_std(g_A,g_tmp2,Q(iev))
      else if (ipdiagmode.eq.IDIAG_PDSYEV) then
        call ga_pdsyev(g_A,g_tmp2,Q(iev),nb)
      else if (ipdiagmode.eq.IDIAG_PDSYEVX) then
        call ga_pdsyevx(g_A,g_tmp2,Q(iev),nb)
      else if (ipdiagmode.eq.IDIAG_PDSYEVD) then
        call ga_pdsyevd(g_A,g_tmp2,Q(iev),nb)
      else if (ipdiagmode.eq.IDIAG_PDSYEVR) then
_IF(pdsyevr)
        call ga_pdsyevr(g_A,g_tmp2,Q(iev),nb)
_ELSE 
        call caserr
     +       ("dft_invdiag: ga_pdsyevr not included in this build")
_ENDIF
      else
        call caserr("dft_invdiag: invalid parallel diag specified")
      endif

_ELSE
      call caserr('dft_invdiag: no parallel diag available')
_ENDIF
ccc#else
ccc      call ga_diag_std_seq(g_A,g_tmp2,DBl_MB(iev))
ccc#endif

C     check on eigenvalues

      call walltime(t_end)
c     write(6,*)'complete diag',me,t_end-t_start
      t_start = t_end


      do i=0,n-1
        if(abs(Q(iev+i)).lt.toll) then
          if(me.eq.0) write(LuOut,*) ' GAFACT - singular eigenvalue',i
          call flush(LuOut)
          if (abs(Q(iev+i)).lt.THRESHOLD) then
c            now we really need to do something.
             if (Q(iev+i).lt.0.0d0) then
                Q(iev+i)=-1.0d0/THRESHOLD
             else
                Q(iev+i)=+1.0d0/THRESHOLD
             endif
          else
             Q(iev+i)=1.d0/Q(iev+i)
          endif
        else
          Q(iev+i)=1.d0/Q(iev+i)
        endif 
      enddo

C     (U * sigma^-1)


      call walltime(t_end)
c     write(6,*)'done invert',me,t_end-t_start
      t_start = t_end


      do i=me+1,n,nproc
        call ga_get(g_tmp2,1,n,i,i,Q(itmp),1)
        do j=0,n-1
          Q(itmp+j)=Q(itmp+j)*Q(iev+i-1)
        enddo
        call ga_put(g_A,1,n,i,i,Q(itmp),1)
      enddo


      call walltime(t_end)
c     write(6,*)'done put',me,t_end-t_start
      t_start = t_end

      call ga_sync

C     (U * sigma^-1) * U(transp) 
      
      call ga_dgemm('N','T',n,n,n,1.d0,g_A,g_tmp2,0.d0,g_cdinv)

      call walltime(t_end)
c     write(6,*)'done dgemm',me,t_end-t_start
      t_start = t_end

      call free_memory2(itmp,'d',fnm,snm,'itmp')
      call free_memory2(iev,'d',fnm,snm,'evals')

      call ga_sync

      if (.not. pg_destroy_inf(g_tmp2,'ga_temp2',fnm,snm)) 
     &   call caserr('dft_invdiag: could not destroy g_tmp2')

      call walltime(t_end)
c     write(6,*)'final',me,t_end-t_start
      t_start = t_end

      if (.not.omemok) then
         imemusage = pop_memory_count(imemcount)
         if (imemusage.eq.imemestimate) omemok = .true.
         if (opg_root().and.(.not.omemok)) then
            write(*,*)'*** estimated memory usage = ',imemestimate,
     &                ' words'
            write(*,*)'*** actual    memory usage = ',imemusage,
     &                ' words'
            write(*,*)'*** WARNING: the memory usage estimates for ',
     &                'jfit_invdiag seem to be incorrect'
         endif
      endif

      return
      end

      subroutine ver_dft_gadft(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/dft/gadft.m,v $
     +     "/
      data revision /
     +     "$Revision: 5774 $"
     +      /
      data date /
     +     "$Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $"
     +     /
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
_ELSE
      Subroutine dft_invdiag(g_A, g_cdinv, n)
      call caserr('dft_invdiag missing')
      return
      end
_ENDIF

