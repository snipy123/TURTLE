c---- memory counting routines -----------------------------------------
c
c  Coulomb fit gradient
c
      subroutine memreq_jfitg(memory_fp, memory_int)
      implicit none
c
c arguments
c      
      REAL memory_fp(*)         ! Core memory
      integer memory_int(*)     ! Core memory

INCLUDE(common/dft_parameters)  ! hard dimensions for dft commons

INCLUDE(common/dft_api)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_memory_info)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis_cont_inf)
INCLUDE(common/dft_mbasis)
INCLUDE(common/dft_dunlap)

INCLUDE(../m4/common/symtry)      ! for iso
INCLUDE(../m4/common/iofile)      ! to access idaf

     
C Scratch space and pointers
      integer iso_pt,tr_pt,nr_pt, schwarz_ao, schwarz_cd, nsh
      integer gout_pt

      integer ntmp,n2c,n3c
      integer nnodes
c
c Local variables
c
      integer lbasf,i,j,col,ico
      integer ao_tag,cd_tag,cdbf_num
      integer ncentres,ao_basfn,tot_basfn
      integer max_shells,tot_prm
      integer size_required,size_freed
      REAL iVn_sum,sum1,sum2,lambda,t_lambdan
      REAL e_coul,e_self,rho
      integer basi,basj,bask,basl,imode
      REAL dum(2)
      REAL adens,bdens,grad
      integer iiso
      character*8 zrhf
_IF(ga)
      integer ilo, ihi, jlo, jhi, ibuff, iproc
      integer ilod, ihid, jlod, jhid
      integer ipg_nodeid
_ELSE
      integer vqr_pt
_ENDIF
c
c Functions
c
      integer incr_memory, lenwrd, null_memory
      integer ipg_nnodes
_IF(single)
      REAL sdot
_ELSEIF(hp700)
      REAL `vec_$ddot'
_ELSE
      REAL ddot
_ENDIF

      integer matrix_pt
      logical opg_root

      integer idum, cd_4c2eon, cd_jfitgon

INCLUDE(../m4/common/errcodes)
_IF(ga)
INCLUDE(common/dft_dunlap_ga)
_ENDIF

      if(debug_sw .and. opg_root()) write(6,*) 'Entering Jfit_dunlap.f',
     &     num_bset

      potential_sw = .false.
      dunlap_sw = .true.
      e_coul   = 0.0d0
      rho      = 0.0d0

      ao_tag=bset_tags(1)
      cd_tag=bset_tags(2)

      cdbf_num=totbfn(cd_tag)
      ao_basfn=totbfn(ao_tag)
c
c     Storage for Schwarz integrals
c
      if (schwarz_tol.ge.0.and.
     &    ((idunlap_called.eq.0.and.ocfit_sw).or.
     &     (.not.ocfit_sw))) then
         schwarz_ao = incr_memory((nshell(ao_tag)+1)*
     &                             nshell(ao_tag)/2,'d')
         schwarz_cd = incr_memory(nshell(cd_tag),'d')
      else
         schwarz_ao = null_memory()
         schwarz_cd = null_memory()
      endif
c
c     Fit coefs
c
      if (ocfit_sw) then
c        The fitting coefficients are stored in the memory arranged by
c        CD_jfit_init1.
      else
         icfit_pt = incr_memory(cdbf_num,'d')
      endif
      tot_basfn=cdbf_num*ao_basfn
c
c     If we did not keep the fitting coefficients from the SCF
c     or if we restarted the calculation at the gradient evaluation
c     then we need to reconstruct the fitting coefficients. 
c     Otherwise we skip to the gradient evaluation straight away.
c
      if (.not.ocfit_sw.or.idunlap_called.eq.0) then
c
c        Tr
c
         tr_pt   = incr_memory(cdbf_num,'d')
c
c        Nr
c
         nr_pt   = incr_memory(cdbf_num,'d')
c
c        Vqr (2c2e integrals)
c
_IFN(ga)
         size_required=cdbf_num*cdbf_num
         vqr_pt  = incr_memory(size_required,'d')
_ENDIF

C *End memory allocation
C **********************************************************************
C *
C *Obtain fitting coefficients for the density
C *
C *
C *Calculate 2 centre 2 electron repulsion integrals and invert matrix
C *

_IF(ga)
c
c Now the GAs are available we should keep the fitting coefficients in
c memory as well and skip this whole section
c
c     call caserr('GA fit gradients not ready')
c
         if (idunlap_called.eq.0) then
c
c Allocate GAs and load with 2c and inverse 2c integrals
c
            call memreq_pre_fit(memory_fp(schwarz_cd),memory_fp,
     &                          cdbf_num)
         endif
_ELSE
         call memreq_Jfit_iVform(memory_int,
     &                    memory_fp,
     &                    cdbf_num,
     &                    .true.,
     &                    memory_fp(vqr_pt),
     &                    memory_fp(schwarz_cd))
_ENDIF

C *
C *Form the tr matrix
C *
c        call aclear_dp(memory_fp(tr_pt),cdbf_num,0.0d0)

         nsh    = BL_max_shell_count()
         iso_pt = incr_memory(nsh,'d')

         gout_pt=incr_memory(50625,'d')
c        call aclear_dp(memory_fp(gout_pt),50625,0.0d0)
         
         if (schwarz_tol.ge.0.and.
     &      ((idunlap_called.eq.0.and.ocfit_sw).or.
     &       (.not.ocfit_sw))) then
c           call coulmb(memory_fp(schwarz_ao),memory_fp(gout_pt))
c           call te2c_rep_schwarz(cd_tag,memory_fp(gout_pt),
c    &                         memory_fp(schwarz_cd))
         endif

         basi = ao_tag
         basj = ao_tag
         bask = cd_tag
         basl = -1

         imode = 4

c        if (.not.ocfit_sw) then
c           call jkint_dft(memory_fp(iso_pt),
c    &           memory_fp(gout_pt),nsh,
c    &           basi, basj, bask, basl,
c    &           imode,adens,bdens,memory_fp(tr_pt),dum,
c    &           memory_fp(schwarz_ao),
c    &           memory_fp(schwarz_cd))
c        else if (idunlap_called.eq.0) then
c           call jkint_dft_cntgen(memory_fp(iso_pt),
c    &           memory_fp(gout_pt),nsh,
c    &           basi, basj, bask, basl,
c    &           imode,adens,bdens,memory_fp(tr_pt),dum,
c    &           memory_fp(schwarz_ao),
c    &           memory_fp(schwarz_cd),
c    &           memory_fp(ite3c_store),nte3c_int,
c    &           memory_int(iite3c_stored),nte3c_shl,
c    &           memory_fp(ite2c_store),nte2c_int,
c    &           memory_int(iite2c_stored),nte2c_shl)
c        else
c           call caserr('jfitg: logically impossible to get here!')
c        endif

         call decr_memory(gout_pt,'d')
         call decr_memory(iso_pt,'d')

c        idunlap_called = idunlap_called + 1


C *
C *Form 1 centre integral array from fitting functions, ie nr
C *
c        call aclear_dp(memory_fp(nr_pt),cdbf_num-1,0.0d0)

         call memreq_intPack_drv(memory_int,
     &                    memory_fp, 
     &                    memory_fp(icfit_pt),
     &                    .true.,.false.,
     &                    .true.,
     &                    .false.,.false.,
     &                    .false.,.false.,
     &                    .false.,
     &                    memory_fp(nr_pt)) 
C *
C *Calculate Langrange Multiplier lambda
C *
         col  = 0
         sum1 = 0.0d0
         sum2 = 0.0d0

_IF(ga)
         ibuff = incr_memory(cdbf_num,'d')
         iproc = ipg_nodeid()
c        call ga_distribution(g_2cinv, iproc, ilod, ihid, jlod, jhid)
c        do lbasf=ilod,ihid
            ilo = lbasf
            ihi = lbasf
            jlo = 1
            jhi = cdbf_num
c           call pg_get(g_2cinv,ilo,ihi,jlo,jhi,
c    &           memory_fp(ibuff),1)
c           ivn_sum=ddot(cdbf_num,memory_fp(ibuff)
c    &           ,1,memory_fp(nr_pt),1)
c           sum1=sum1+ivn_sum*memory_fp(tr_pt+lbasf-1)
c           sum2=sum2+ivn_sum*memory_fp(nr_pt+lbasf-1)
c        enddo
         call decr_memory(ibuff,'d')
c        call pg_dgop(2001,sum1,1,'+')
c        call pg_dgop(2002,sum2,1,'+')
_ELSE
c        do lbasf=0,cdbf_num-1
c           iVn_sum=ddot(cdbf_num,memory_fp(vqr_pt+col)
c    &      ,1,memory_fp(nr_pt),1)
            col=col+cdbf_num
c           sum1=sum1+iVn_sum*memory_fp(tr_pt+lbasf)
c           sum2=sum2+iVn_sum*memory_fp(nr_pt+lbasf)
c        enddo
_ENDIF
c        lambda=(nelectrons-sum1)/sum2

C *
C *api entry point
C
c        lmult=lambda

C *
C *Calculate fitting coefficients themselves
C *
c        call aclear_dp(memory_fp(icfit_pt),cdbf_num,0.0d0)
_IF(ga)
         ibuff = incr_memory(cdbf_num,'d')
         iproc = ipg_nodeid()
c        call ga_distribution(g_2cinv, iproc, ilod, ihid, jlod, jhid)
c        do lbasf=ilod,ihid

c           t_lambdan=memory_fp(tr_pt+lbasf-1) +
c    &           lambda*memory_fp(nr_pt+lbasf-1)
            ilo = lbasf
            ihi = lbasf
            jlo = 1
            jhi = cdbf_num
c           call pg_get(g_2cinv,ilo,ihi,jlo,jhi,
c    &           memory_fp(ibuff),1)

c           call daxpy(cdbf_num,t_lambdan
c    &           ,memory_fp(ibuff),1
c    &           ,memory_fp(icfit_pt),1)
c        enddo
         call decr_memory(ibuff,'d')
c        call pg_dgop(2003,memory_fp(icfit_pt),cdbf_num,'+')
_ELSE
         col = 0
c        do lbasf=0,cdbf_num-1
c           t_lambdan=memory_fp(tr_pt+lbasf)+
c    &                lambda*memory_fp(nr_pt+lbasf)
c           call daxpy(cdbf_num,t_lambdan
c    &           ,memory_fp(vqr_pt+col),1
c    &           ,memory_fp(icfit_pt),1)
            col=col+cdbf_num
c        enddo
_ENDIF

C 
C Calculate matrix elements and energy
c 
_IFN(ga)
         call decr_memory(vqr_pt,'d')
_ENDIF
         call decr_memory(nr_pt,'d')
         call decr_memory(tr_pt,'d')
      endif
c
c NB should be redundant as symmetry is not used, but array is
c still referenced
c
      nsh  = max(nw196(5),BL_max_shell_count())
      iiso = incr_memory(nsh,'d')
c     call rdedx(memory_fp(iiso),nw196(5),ibl196(5),idaf)
      zrhf = 'rhf'
c
c This is the 4-centre force evaluation used for
c checking
c
c      call jkder_dft(zrhf,memory_fp,memory_fp(iiso),nshell(1),
c     &     ao_tag, ao_tag, ao_tag, ao_tag,
c     &     adens,bdens,memory_fp(icfit_pt),dum,grad)
c

c
c 2 centre term
c
      if (.not.ocfit_sw) then
         call memreq_jkder_dft(zrhf,memory_fp,memory_fp(iiso),nsh,
     &        cd_tag, -1, cd_tag, -1,
     &        adens,bdens,memory_fp(icfit_pt),dum,grad,
     &        memory_fp(schwarz_ao),memory_fp(schwarz_cd))
      else if (idunlap_called.eq.0) then
         call caserr('Jfitg needs jfit to be run first')
      else 
         call memreq_jkder_dft_genuse(zrhf,memory_fp,memory_fp(iiso),
     &        nsh, cd_tag, -1, cd_tag, -1,
     &        adens,bdens,memory_fp(icfit_pt),dum,grad,
     &        memory_int(iite3c_stored),nte3c_shl,
     &        memory_int(iite2c_stored),nte2c_shl)
      endif
c
c 3 centre term
c
      if (.not.ocfit_sw) then
         call memreq_jkder_dft(zrhf,memory_fp,memory_fp(iiso),nsh,
     &        ao_tag, ao_tag, cd_tag, -1,
     &        adens,bdens,memory_fp(icfit_pt),dum,grad,
     &        memory_fp(schwarz_ao),memory_fp(schwarz_cd))
      else if (idunlap_called.eq.0) then
         call caserr('Jfitg needs jfit to be run first')
      else 
         call memreq_jkder_dft_genuse(zrhf,memory_fp,memory_fp(iiso),
     &        nsh, ao_tag, ao_tag, cd_tag, -1,
     &        adens,bdens,memory_fp(icfit_pt),dum,grad,
     &        memory_int(iite3c_stored),nte3c_shl,
     &        memory_int(iite2c_stored),nte2c_shl)
      endif

      call decr_memory(iiso,'d')


      if (ocfit_sw) then
c        Fitting coefficient memory taken care of by CD_jfit_clean1
      else
         call decr_memory(icfit_pt,'d')
      endif
      if (schwarz_tol.ge.0.and.
     &    ((idunlap_called.eq.1.and.ocfit_sw).or.
     &     (.not.ocfit_sw))) then
         call decr_memory(schwarz_cd,'d')
         call decr_memory(schwarz_ao,'d')
      endif

      return

      end
c
c---- the routines that do the real work -------------------------------
c
c  Coulomb fit gradient
c
      subroutine jfitg(memory_fp, memory_int, adens, bdens, grad, iout)
      implicit none
c
c arguments
c      
      integer iout              ! Unit for standard out.
      REAL memory_fp(*)         ! Core memory
      integer memory_int(*)     ! Core memory
      REAL adens(*), bdens(*)   ! Density matrix     (in)
      REAL grad(3,*)            ! Accumulated forces (in/out)

INCLUDE(common/dft_parameters)  ! hard dimensions for dft commons

INCLUDE(common/dft_api)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_memory_info)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis_cont_inf)
INCLUDE(common/dft_mbasis)
INCLUDE(common/dft_dunlap)

INCLUDE(../m4/common/symtry)      ! for iso
INCLUDE(../m4/common/iofile)      ! to access idaf

     
C Scratch space and pointers
      integer iso_pt,tr_pt,nr_pt, schwarz_ao, schwarz_cd, nsh
      integer gout_pt

      integer ntmp,n2c,n3c
      integer nnodes
c
c Local variables
c
      integer lbasf,i,j,col,ico
      integer ao_tag,cd_tag,cdbf_num
      integer ncentres,ao_basfn,tot_basfn
      integer max_shells,tot_prm
      integer size_required,size_freed
      REAL iVn_sum,sum1,sum2,lambda,t_lambdan
      REAL e_coul,e_self,rho
      integer basi,basj,bask,basl,imode
      REAL dum(2)
      integer iiso
      character*8 zrhf
c
      integer push_memory_count,    pop_memory_count
      integer push_memory_estimate, pop_memory_estimate
      integer imemcount, imemusage, imemestimate
c
_IF(ga)
      integer ilo, ihi, jlo, jhi, ibuff, iproc
      integer ilod, ihid, jlod, jhid
      integer ipg_nodeid
_ELSE
      integer vqr_pt
_ENDIF
c
c Functions
c
      integer allocate_memory, lenwrd, null_memory
      integer ipg_nnodes
_IF(single)
      REAL sdot
_ELSEIF(hp700)
      REAL `vec_$ddot'
_ELSE
      REAL ddot
_ENDIF

      integer matrix_pt
      logical opg_root

      integer idum, cd_4c2eon, cd_jfitgon

INCLUDE(../m4/common/timeperiods)
INCLUDE(../m4/common/errcodes)
_IF(ga)
INCLUDE(common/dft_dunlap_ga)
_ENDIF
      imemcount = push_memory_count()

      if(debug_sw .and. opg_root()) write(iout,*) 
     &     'Entering Jfit_dunlap.f',num_bset

      call start_time_period(TP_DFT_JFITG)

      potential_sw = .false.
      dunlap_sw = .true.
      e_coul   = 0.0d0
      rho      = 0.0d0

      ao_tag=bset_tags(1)
      cd_tag=bset_tags(2)

      cdbf_num=totbfn(cd_tag)
      ao_basfn=totbfn(ao_tag)
c
c     Storage for Schwarz integrals
c
      if (schwarz_tol.ge.0.and.
     &    ((idunlap_called.eq.0.and.ocfit_sw).or.
     &     (.not.ocfit_sw))) then
         schwarz_ao = allocate_memory((nshell(ao_tag)+1)*
     &                                 nshell(ao_tag)/2,'d')
         schwarz_cd = allocate_memory(nshell(cd_tag),'d')
      else
         schwarz_ao = null_memory()
         schwarz_cd = null_memory()
      endif
c
c     Fit coefs
c
      if (ocfit_sw) then
c        The fitting coefficients are stored in the memory arranged by
c        CD_jfit_init1.
      else
         icfit_pt = allocate_memory(cdbf_num,'d')
      endif
      tot_basfn=cdbf_num*ao_basfn
c
c     If we did not keep the fitting coefficients from the SCF
c     or if we restarted the calculation at the gradient evaluation
c     then we need to reconstruct the fitting coefficients. 
c     Otherwise we skip to the gradient evaluation straight away.
c
      if (.not.ocfit_sw.or.idunlap_called.eq.0) then
c
c        Tr
c
         tr_pt   = allocate_memory(cdbf_num,'d')
c
c        Nr
c
         nr_pt   = allocate_memory(cdbf_num,'d')
c
c        Vqr (2c2e integrals)
c
_IFN(ga)
         size_required=cdbf_num*cdbf_num
         vqr_pt  = allocate_memory(size_required,'d')
_ENDIF

C *End memory allocation
C **********************************************************************
C *
C *Obtain fitting coefficients for the density
C *
         if(debug_sw .and. opg_root()) then
           write(iout,*)
           if(triangle_sw) write(iout,*) 'Using triangle matrices'
           write(iout,*) 'Number of fitting basis functions :',cdbf_num
           write(iout,*) 'AO matrix size                    :',ao_basfn
           write(iout,*) 'Matrix size                       :',tot_basfn
         endif
C *
C *Calculate 2 centre 2 electron repulsion integrals and invert matrix
C *

         call start_time_period(TP_DFT_JFITG_VFORM)


_IF(ga)
c
c Now the GAs are available we should keep the fitting coefficients in
c memory as well and skip this whole section
c
c     call caserr('GA fit gradients not ready')
c
         if (idunlap_called.eq.0) then
c
c Allocate GAs and load with 2c and inverse 2c integrals
c
            call start_time_period(TP_DFT_JFIT_VFORM)
            call pre_fit(memory_fp(schwarz_cd),memory_fp,cdbf_num)
            call end_time_period(TP_DFT_JFIT_VFORM)
         endif
_ELSE
         call Jfit_iVform(memory_int,
     &                    memory_fp,
     &                    cdbf_num,
     &                    .true.,
     &                    memory_fp(vqr_pt),
     &                    memory_fp(schwarz_cd))
_ENDIF
         call end_time_period(TP_DFT_JFITG_VFORM)

         if(print_sw(DEBUG_MEMORY))then
            if(opg_root())write(6,*)'check guards after ivform'
            call gmem_check_guards
         endif

C *
C *Form the tr matrix
C *
         call aclear_dp(memory_fp(tr_pt),cdbf_num,0.0d0)

         call start_time_period(TP_DFT_JFITG_TR)

         nsh    = BL_max_shell_count()
         iso_pt = allocate_memory(nsh,'d')

         gout_pt=allocate_memory(50625,'d')
         call aclear_dp(memory_fp(gout_pt),50625,0.0d0)
         
         if (schwarz_tol.ge.0.and.
     &      ((idunlap_called.eq.0.and.ocfit_sw).or.
     &       (.not.ocfit_sw))) then
            call coulmb_dft(memory_fp(schwarz_ao),memory_fp(gout_pt),
     &                      ao_tag)
            call te2c_rep_schwarz(cd_tag,memory_fp(gout_pt),
     &                         memory_fp(schwarz_cd))
            if(print_sw(DEBUG_MEMORY))then
               if(opg_root())write(6,*)'check guards after coulmb'
               call gmem_check_guards
            endif
         endif

         basi = ao_tag
         basj = ao_tag
         bask = cd_tag
         basl = -1

         imode = 4

         if (.not.ocfit_sw) then
            call jkint_dft(memory_fp(iso_pt),
     &           memory_fp(gout_pt),nsh,
     &           basi, basj, bask, basl,
     &           imode,adens,bdens,memory_fp(tr_pt),dum,
     &           memory_fp(schwarz_ao),
     &           memory_fp(schwarz_cd))
         else if (idunlap_called.eq.0) then
            call jkint_dft_cntgen(memory_fp(iso_pt),
     &           memory_fp(gout_pt),nsh,
     &           basi, basj, bask, basl,
     &           imode,adens,bdens,memory_fp(tr_pt),dum,
     &           memory_fp(schwarz_ao),
     &           memory_fp(schwarz_cd),
     &           memory_fp(ite3c_store),nte3c_int,
     &           memory_int(iite3c_stored),nte3c_shl,
     &           memory_fp(ite2c_store),nte2c_int,
     &           memory_int(iite2c_stored),nte2c_shl)
         else
            call caserr('jfitg: logically impossible to get here!')
         endif

         call free_memory(gout_pt,'d')
         call free_memory(iso_pt,'d')

         if(print_sw(DEBUG_MEMORY))then
            if(opg_root())write(iout,*)'check guards after tr'
            call gmem_check_guards
         endif

         if(opg_root() .and. print_sw(DEBUG_TR))then
            do ico=0,cdbf_num-1
               write(iout,*) 'Tr Vector:',ico+1,memory_fp(tr_pt+ico)
            enddo
         endif

         idunlap_called = idunlap_called + 1

         call end_time_period(TP_DFT_JFITG_TR)

C *
C *Form 1 centre integral array from fitting functions, ie nr
C *
         call aclear_dp(memory_fp(nr_pt),cdbf_num-1,0.0d0)

         call start_time_period(TP_DFT_JFITG_NR)

         call intPack_drv(memory_int,
     &                    memory_fp, 
     &                    memory_fp(icfit_pt),
     &                    .true.,.false.,
     &                    .true.,
     &                    .false.,.false.,
     &                    .false.,.false.,
     &                    .false.,
     &                    memory_fp(nr_pt)) 

         call end_time_period(TP_DFT_JFITG_NR)


         if(print_sw(DEBUG_MEMORY))then
            if(opg_root())write(iout,*)'check guards after nr'
            call gmem_check_guards
         endif

         if(opg_root() .and. print_sw(DEBUG_NR))then
            do ico=0,cdbf_num-1
               write(iout,*) 'nr:',ico+1,memory_fp(nr_pt+ico)
            enddo
         endif
C *
C *Calculate Langrange Multiplier lambda
C *
         col  = 0
         sum1 = 0.0d0
         sum2 = 0.0d0

         call start_time_period(TP_DFT_JFITG_COEF)
_IF(ga)
         ibuff = allocate_memory(cdbf_num,'d')
         iproc = ipg_nodeid()
         call ga_distribution(g_2cinv, iproc, ilod, ihid, jlod, jhid)
         do lbasf=ilod,ihid
            ilo = lbasf
            ihi = lbasf
            jlo = 1
            jhi = cdbf_num
            call pg_get(g_2cinv,ilo,ihi,jlo,jhi,
     &           memory_fp(ibuff),1)
            ivn_sum=ddot(cdbf_num,memory_fp(ibuff)
     &           ,1,memory_fp(nr_pt),1)
            sum1=sum1+ivn_sum*memory_fp(tr_pt+lbasf-1)
            sum2=sum2+ivn_sum*memory_fp(nr_pt+lbasf-1)
         enddo
         call free_memory(ibuff,'d')
         call pg_dgop(2001,sum1,1,'+')
         call pg_dgop(2002,sum2,1,'+')
_ELSE
         do lbasf=0,cdbf_num-1
            iVn_sum=ddot(cdbf_num,memory_fp(vqr_pt+col)
     &      ,1,memory_fp(nr_pt),1)
            col=col+cdbf_num
            sum1=sum1+iVn_sum*memory_fp(tr_pt+lbasf)
            sum2=sum2+iVn_sum*memory_fp(nr_pt+lbasf)
c           write(iout,*) 'iVn_sum:',iVn_sum,'SUMS',sum1,sum2
         enddo
_ENDIF
         lambda=(nelectrons-sum1)/sum2

C *
C *api entry point
C
         lmult=lambda

         if(print_sw(DEBUG_MEMORY))then
            if(opg_root())write(iout,*)'check guards after lambda'
            call gmem_check_guards
         endif
C *
C *Calculate fitting coefficients themselves
C *
         call aclear_dp(memory_fp(icfit_pt),cdbf_num,0.0d0)
_IF(ga)
         ibuff = allocate_memory(cdbf_num,'d')
         iproc = ipg_nodeid()
         call ga_distribution(g_2cinv, iproc, ilod, ihid, jlod, jhid)
         do lbasf=ilod,ihid

            t_lambdan=memory_fp(tr_pt+lbasf-1) +
     &           lambda*memory_fp(nr_pt+lbasf-1)
            ilo = lbasf
            ihi = lbasf
            jlo = 1
            jhi = cdbf_num
            call pg_get(g_2cinv,ilo,ihi,jlo,jhi,
     &           memory_fp(ibuff),1)

            call daxpy(cdbf_num,t_lambdan
     &           ,memory_fp(ibuff),1
     &           ,memory_fp(icfit_pt),1)
         enddo
         call free_memory(ibuff,'d')
         call pg_dgop(2003,memory_fp(icfit_pt),cdbf_num,'+')
_ELSE
         col = 0
         do lbasf=0,cdbf_num-1
            t_lambdan=memory_fp(tr_pt+lbasf)+
     &                lambda*memory_fp(nr_pt+lbasf)
            call daxpy(cdbf_num,t_lambdan
     &           ,memory_fp(vqr_pt+col),1
     &           ,memory_fp(icfit_pt),1)
            col=col+cdbf_num
         enddo
_ENDIF

         call end_time_period(TP_DFT_JFITG_COEF)

         if(print_sw(DEBUG_MEMORY))then
            if(opg_root())write(iout,*)'check guards after fit'
            call gmem_check_guards
         endif
C 
C Calculate matrix elements and energy
c 
         if(opg_root() .and. print_sw(DEBUG_JFIT))then
            write(iout,*)'Cfit:'
            do col=0,cdbf_num-1
               write(iout,101)memory_fp(icfit_pt+col)
 101           format(1x,f16.5)
            enddo
         endif

         if(print_sw(DEBUG_MEMORY))then
            if(opg_root())write(iout,*)'check guards after energy'
            call gmem_check_guards
         endif

_IFN(ga)
         call free_memory(vqr_pt,'d')
_ENDIF
         call free_memory(nr_pt,'d')
         call free_memory(tr_pt,'d')
      endif
c
c NB should be redundant as symmetry is not used, but array is
c still referenced
c
      nsh  = max(nw196(5),BL_max_shell_count())
      iiso = allocate_memory(nsh,'d')
      call rdedx(memory_fp(iiso),nw196(5),ibl196(5),idaf)
      zrhf = 'rhf'
c
c This is the 4-centre force evaluation used for
c checking
c
c      call jkder_dft(zrhf,memory_fp,memory_fp(iiso),nshell(1),
c     &     ao_tag, ao_tag, ao_tag, ao_tag,
c     &     adens,bdens,memory_fp(icfit_pt),dum,grad)
c

      if(opg_root() .and. print_sw(DEBUG_FORCES) )then
         write(iout,*) 'Forces before coulomb:'
         write(iout,*) 
     &        'atom         de/dx             de/y          de/dz'
         do i=1,natoms
            write(iout,1000)i,(grad(j,i),j=1,3)
         enddo
 1000    format(i3,3f16.8)
      endif
c
c 2 centre term
c
      call start_time_period(TP_DFT_JFITG_2C)
      if (.not.ocfit_sw) then
         call jkder_dft(zrhf,memory_fp,memory_fp(iiso),nsh,
     &        cd_tag, -1, cd_tag, -1,
     &        adens,bdens,memory_fp(icfit_pt),dum,grad,
     &        memory_fp(schwarz_ao),memory_fp(schwarz_cd))
      else if (idunlap_called.eq.0) then
         call caserr('Jfitg needs jfit to be run first')
      else 
         call jkder_dft_genuse(zrhf,memory_fp,memory_fp(iiso),
     &        nsh, cd_tag, -1, cd_tag, -1,
     &        adens,bdens,memory_fp(icfit_pt),dum,grad,
     &        memory_int(iite3c_stored),nte3c_shl,
     &        memory_int(iite2c_stored),nte2c_shl)
      endif

      if(opg_root() .and. print_sw(DEBUG_FORCES) )then
         write(iout,*) 'Forces after 2c:'
         write(iout,*) 
     &        'atom         de/dx             de/y          de/dz'
         do i=1,natoms
            write(iout,1000)i,(grad(j,i),j=1,3)
         enddo
      endif
      call end_time_period(TP_DFT_JFITG_2C)
c
c 3 centre term
c
      call start_time_period(TP_DFT_JFITG_3C)
      if (.not.ocfit_sw) then
         call jkder_dft(zrhf,memory_fp,memory_fp(iiso),nsh,
     &        ao_tag, ao_tag, cd_tag, -1,
     &        adens,bdens,memory_fp(icfit_pt),dum,grad,
     &        memory_fp(schwarz_ao),memory_fp(schwarz_cd))
      else if (idunlap_called.eq.0) then
         call caserr('Jfitg needs jfit to be run first')
      else 
         call jkder_dft_genuse(zrhf,memory_fp,memory_fp(iiso),
     &        nsh, ao_tag, ao_tag, cd_tag, -1,
     &        adens,bdens,memory_fp(icfit_pt),dum,grad,
     &        memory_int(iite3c_stored),nte3c_shl,
     &        memory_int(iite2c_stored),nte2c_shl)
      endif

      if(opg_root() .and. print_sw(DEBUG_FORCES) )then
         write(iout,*) 'Forces after 3c:'
         write(iout,*) 
     &        'atom         de/dx             de/y          de/dz'
         do i=1,natoms
            write(iout,1000)i,(grad(j,i),j=1,3)
         enddo
      endif

      call free_memory(iiso,'d')
      call end_time_period(TP_DFT_JFITG_3C)


      call end_time_period(TP_DFT_JFITG)

      if (ocfit_sw) then
c        Fitting coefficient memory taken care of by CD_jfit_clean1
      else
         call free_memory(icfit_pt,'d')
      endif
      if (schwarz_tol.ge.0.and.
     &    ((idunlap_called.eq.1.and.ocfit_sw).or.
     &     (.not.ocfit_sw))) then
         call free_memory(schwarz_cd,'d')
         call free_memory(schwarz_ao,'d')
      endif

      imemusage = pop_memory_count(imemcount)
      imemcount = push_memory_estimate()
      call memreq_jfitg(memory_fp,memory_int)
      imemestimate = pop_memory_estimate(imemcount)
      if (opg_root().and.imemusage.ne.imemestimate) then
         write(iout,*)'*** estimated memory usage = ',imemestimate,
     &                ' words'
         write(iout,*)'*** actual    memory usage = ',imemusage   ,
     &                ' words'
         write(iout,*)'*** WARNING: the memory usage estimates for ',
     &                'jfitg seem to be incorrect'
      endif

      return

      end

      subroutine ver_dft_jfitg(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/dft/jfitg.m,v $
     +     "/
      data revision /
     +     "$Revision: 5919 $"
     +      /
      data date /
     +     "$Date: 2009-03-31 15:11:24 +0200 (Tue, 31 Mar 2009) $"
     +     /
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
