c---- memory counting routines -----------------------------------------
_IF(ga)
c **********************************************************************
c pre_fit : compute quantities that are needed each SCF cycle
c          
c  allocate global arrays (if not already allocated)
c  compute 2-centre integrals and invert V matrix
c
c **********************************************************************

      subroutine memreq_pre_fit(schwarz_cd,memory_fp, ncd)
      implicit none

INCLUDE(common/dft_parameters)
INCLUDE(common/dft_dunlap_ga)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_dunlap)
INCLUDE(common/dft_mbasis)        ! for nshell(1)
INCLUDE(common/dft_basis)         ! for bset_tags(2)

      integer ncd
      REAL schwarz_cd(*)          !  actually empty at this point
      REAL memory_fp(*)
      integer i

c local variables
      integer basi, basj, bask, basl, imode
      integer gout_pt, iiso
      REAL dum
      character*9  fnm
      character*14 snm

C *Functions
      integer incr_memory2
      logical pg_create_cnt, pg_destroy_cnt

      external  dft_dunlap_ga_data

      data fnm/'coulomb.m'/
      data snm/'memreq_pre_fit'/
 
      if(g_2c_cnt .eq. -1)then

         if (.not. pg_create_cnt(0,ncd,ncd,'2c ints',0,ncd,
     &        g_2c_cnt )) then
            call pg_error('failed to create 2c integral GA ',i)
         end if

         if (.not. pg_create_cnt(0,ncd,ncd,'2-c inv',0,ncd,
     &        g_2cinv_cnt )) then
            call pg_error('failed to create inverse 2c integral GA ',i)
         end if

      endif
      if (.not. pg_create_cnt(0,ncd,ncd,'temp',0,ncd,
     &    g_tmp_cnt )) then
         call pg_error('failed to create temp GA ',i)
      end if
c
c NB iso should be redundant as symmetry is not used, but array is
c still referenced - dummmy array is built in jkint
c
      iiso = incr_memory2(nshell(2),'d',fnm,snm,'iiso')
      gout_pt=incr_memory2(50625,'d',fnm,snm,'gout')
c     call aclear_dp(memory_fp(gout_pt),50625,0.0d0)
      basi = 2
      basj = -1
      bask = 2
      basl = -1

      imode = 61

c     call jkint_dft(memory_fp(iiso),
c    &     memory_fp(gout_pt),nshell(basi),
c    &     basi, basj, bask, basl,
c    &     imode,dum,dum, dum, dum, dum, dum)

      call decr_memory2(gout_pt,'d',fnm,snm,'gout')
      call decr_memory2(iiso,'d',fnm,snm,'iiso')

c     call ga_copy(g_2c,g_tmp)

      call memreq_dft_invdiag(g_2c, g_2cinv, ncd)

c     call ga_copy(g_tmp,g_2c)

      if (.not. pg_destroy_cnt(g_tmp_cnt)) call caserr(
     &   'pre_fit: could not destroy g_tmp')

      end
      subroutine memreq_post_fit
c
c     This routine is meant to clean up the memory allocated in the
c     pre_fit routine.
c
INCLUDE(common/dft_dunlap_ga)
c
c...  Local variables
c
      integer i
c
c...  Functions
c
      logical  pg_destroy_cnt
      external pg_destroy_cnt
c
c...  Code
c
      if (g_2c_cnt .ne. -1) then
         if (.not. pg_destroy_cnt(g_2c_cnt)) call pg_error(
     &       'memreq_post_fit: could not destroy g_2c_cnt',i)
         if (.not. pg_destroy_cnt(g_2cinv_cnt)) call pg_error(
     &       'memreq_post_fit: could not destroy g_2cinv_cnt',i)
         g_2c_cnt    = -1
         g_2cinv_cnt = -1
      endif
c
      end
_ENDIF
      subroutine memreq_jfit_dunlap(memory_fp,
     &                              memory_int,
     &                              kma,kmb,adens,bdens)
C **********************************************************************
C *Description:                                                        *
C *Generate J matrix using Dunlap fitting method                       *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_api)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_memory_info)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis_cont_inf)
INCLUDE(common/dft_dunlap)
      REAL kma(*),kmb(*),adens(*),bdens(*)
C *Scratch space and pointer
      integer memory_int(*)
      REAL memory_fp(*)
      integer tr_pt,nr_pt,schwarz_cd,schwarz_ao
C *Local variables
      integer lbasf,col,ico
      integer ao_tag,cd_tag,cdbf_num
      integer ao_basfn,tot_basfn
      integer size_required
      REAL ivn_sum,sum1,sum2,lambda,t_lambdan
      REAL e_coul,e_self,rho
      integer ntmp,n2c,n3c
      integer nnodes
_IF(ga)
      integer ilo, ihi, jlo, jhi, ibuff, iproc
      integer ilod, ihid, jlod, jhid
      integer ipg_nodeid
_ELSE
      integer vqr_pt
_ENDIF


c for testing jkint
      integer iso_pt, gout_pt, nsh
      REAL dum
INCLUDE(common/dft_mbasis)
      integer basi, basj, bask, basl, imode

C *Functions
      integer incr_memory, lenwrd, null_memory
      integer ipg_nnodes
_IF(single)
      REAL sdot
_ELSEIF(hp700)
      REAL `vec_$ddot'
_ELSE
      REAL ddot
_ENDIF

      logical opg_root
C *
C *End declarations
C **********************************************************************
C *
INCLUDE(../m4/common/errcodes)
INCLUDE(../m4/common/restar)
_IF(ga)
INCLUDE(common/dft_dunlap_ga)
_ENDIF
      if(debug_sw .and. opg_root()) write(6,*) 'Entering jfit_dunlap.f',
     &     num_bset

      potential_sw = .false.
      dunlap_sw = .true.
      e_coul   = 0.0d0
      rho      = 0.0d0
      ao_tag=bset_tags(1)
      cd_tag=bset_tags(2)
C **********************************************************************
C *Allocate memory into needed blocks                             
C *
C * Set 1 - Arrays used in forming kohn-sham matrix and energy
C *
C * Pointer             Length                  Memory type
C * tr_pt					double
C * nr_pt					double
C * vqr_pt					double
C * cfit_pt					double
      cdbf_num=totbfn(cd_tag)
      ao_basfn=totbfn(ao_tag)

      tr_pt   = incr_memory(cdbf_num,'d')
      nr_pt   = incr_memory(cdbf_num,'d')
      if (ocfit_sw) then
c        the fitting coefficients have to survive between the scf and
c        gradient calculation. Therefore they are stored in the space
c        allocated by CD_jfit_init1.
      else
         icfit_pt = incr_memory(cdbf_num,'d')
      endif
_IFN(ga)
      size_required=cdbf_num*cdbf_num
      vqr_pt  = incr_memory(size_required,'d')
_ENDIF
      if (schwarz_tol.ge.0.and.
     &    ((idunlap_called.eq.0.and.ocfit_sw).or.
     &     (.not.ocfit_sw))) then
         schwarz_cd = incr_memory(nshell(cd_tag),'d')
      else
         schwarz_cd = null_memory()
      endif

C *End memory allocation
C **********************************************************************
C *
C *Obtain fitting coefficients for the density
C *
      tot_basfn=cdbf_num*ao_basfn
C *
C *Calculate 2 centre 2 electron repulsion integrals and invert matrix
C *

_IFN(ga)
      call memreq_jfit_ivform(memory_int,
     &                        memory_fp,
     &                        cdbf_num,
     &                        .true.,
     &                        memory_fp(vqr_pt),
     &                        memory_fp(schwarz_cd))
_ELSE
      if (idunlap_called.eq.0) then
c
c Allocate GAs and load with 2c and inverse 2c integrals
c 
         call memreq_pre_fit(memory_fp(schwarz_cd),memory_fp,cdbf_num)
      endif
_ENDIF

C *
C *Form the tr matrix
C *
c
         if (schwarz_tol.ge.0.and.
     &       ((idunlap_called.eq.0.and.ocfit_sw).or.
     &        (.not.ocfit_sw))) then
            schwarz_ao = incr_memory((nshell(ao_tag)+1)*
     &                                nshell(ao_tag)/2,'d')
         else
            schwarz_ao = null_memory()
         endif

         nsh = BL_max_shell_count()
         iso_pt = incr_memory(nsh,'d')

         gout_pt=incr_memory(50625,'d')
c        call aclear_dp(memory_fp(gout_pt),50625,0.0d0)
         
         if (schwarz_tol.ge.0.and.
     &       ((idunlap_called.eq.0.and.ocfit_sw).or.
     &        (.not.ocfit_sw))) then
c           call coulmb(memory_fp(schwarz_ao),memory_fp(gout_pt))
c           call te2c_rep_schwarz(cd_tag,memory_fp(gout_pt),
c    &                            memory_fp(schwarz_cd))
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
c           call jkint_dft_genuse(memory_fp(iso_pt),
c    &           memory_fp(gout_pt),nsh,
c    &           basi, basj, bask, basl,
c    &           imode,adens,bdens,memory_fp(tr_pt),dum,
c    &           memory_fp(ite3c_store),nte3c_int,
c    &           memory_int(iite3c_stored),nte3c_shl,
c    &           memory_fp(ite2c_store),nte2c_int,
c    &           memory_int(iite2c_stored),nte2c_shl)
c        endif


         call decr_memory(gout_pt,'d')
         call decr_memory(iso_pt,'d')

c
C *
C *Form 1 centre integral array from fitting functions, ie nr
C *
      call memreq_intPack_drv(memory_int,
     &                        memory_fp, 
     &                        memory_fp(icfit_pt),
     &                        .true.,.false.,
     &                        .true.,
     &                        .false.,.false.,
     &                        .false.,.false.,
     &                        .false.,
     &                        memory_fp(nr_pt)) 

C *
C *Calculate Lagrange Multiplier lambda
C *
      col  = 0
      sum1 = 0.0d0
      sum2 = 0.0d0

_IF(ga)
      ibuff = incr_memory(cdbf_num,'d')
      iproc = ipg_nodeid()
c     call ga_distribution(g_2cinv, iproc, ilod, ihid, jlod, jhid)
c     do lbasf=ilod,ihid
         ilo = lbasf
         ihi = lbasf
         jlo = 1
         jhi = cdbf_num
c        call pg_get(g_2cinv,ilo,ihi,jlo,jhi,
c    &        memory_fp(ibuff),1)
c        ivn_sum=ddot(cdbf_num,memory_fp(ibuff)
c    &        ,1,memory_fp(nr_pt),1)
c        sum1=sum1+ivn_sum*memory_fp(tr_pt+lbasf-1)
c        sum2=sum2+ivn_sum*memory_fp(nr_pt+lbasf-1)
c     enddo
      call decr_memory(ibuff,'d')
c     call pg_dgop(2001,sum1,1,'+')
c     call pg_dgop(2002,sum2,1,'+')
_ELSE
c     do lbasf=0,cdbf_num-1
c       ivn_sum=ddot(cdbf_num,memory_fp(vqr_pt+col)
c    & ,1,memory_fp(nr_pt),1)
c       write(6,*) 'ivn_sum:',ivn_sum
        col=col+cdbf_num
c       sum1=sum1+ivn_sum*memory_fp(tr_pt+lbasf)
c       sum2=sum2+ivn_sum*memory_fp(nr_pt+lbasf)
c     enddo
_ENDIF
c     lambda=(nelectrons-sum1)/sum2

C *
C *api entry point
c     lmult=lambda


C *
C *Calculate fitting coefficients themselves
C *
c     call aclear_dp(memory_fp(icfit_pt),cdbf_num,0.0d0)
_IF(ga)
      ibuff = incr_memory(cdbf_num,'d')
      iproc = ipg_nodeid()
c     call ga_distribution(g_2cinv, iproc, ilod, ihid, jlod, jhid)
c     do lbasf=ilod,ihid

c        t_lambdan=memory_fp(tr_pt+lbasf-1) + 
c    &        lambda*memory_fp(nr_pt+lbasf-1)
         ilo = lbasf
         ihi = lbasf
         jlo = 1
         jhi = cdbf_num
c        call pg_get(g_2cinv,ilo,ihi,jlo,jhi,
c    &        memory_fp(ibuff),1)

c        call daxpy(cdbf_num,t_lambdan
c    &           ,memory_fp(ibuff),1
c    &           ,memory_fp(icfit_pt),1)
c     enddo
      call decr_memory(ibuff,'d')
c     call pg_dgop(2003,memory_fp(icfit_pt),cdbf_num,'+')
_ELSE
      col = 0
c     do lbasf=0,cdbf_num-1
c       t_lambdan=memory_fp(tr_pt+lbasf)+lambda*memory_fp(nr_pt+lbasf)
c       call daxpy(cdbf_num,t_lambdan
c    &           ,memory_fp(vqr_pt+col),1
c    &           ,memory_fp(icfit_pt),1)
        col=col+cdbf_num
c     enddo
_ENDIF


C *
C *Calculate matrix elements and energy
C *
C *Potential
C *

         nsh = BL_max_shell_count()
         iso_pt = incr_memory(nsh,'d')

         gout_pt=incr_memory(50625,'d')
c        call aclear_dp(memory_fp(gout_pt),50625,0.0d0)

         basi = ao_tag
         basj = ao_tag
         bask = cd_tag
         basl = -1

         imode = 3

c        if (.not.ocfit_sw) then
c           call jkint_dft(memory_fp(iso_pt),
c    &           memory_fp(gout_pt),nsh,
c    &           basi, basj, bask, basl,
c    &           imode,memory_fp(icfit_pt),dum,kma,kmb,
c    &           memory_fp(schwarz_ao),
c    &           memory_fp(schwarz_cd))
c        else
c           call jkint_dft_genuse(memory_fp(iso_pt),
c    &           memory_fp(gout_pt),nsh,
c    &           basi, basj, bask, basl,
c    &           imode,memory_fp(icfit_pt),dum,kma,kmb,
c    &           memory_fp(ite3c_store),nte3c_int,
c    &           memory_int(iite3c_stored),nte3c_shl,
c    &           memory_fp(ite2c_store),nte2c_int,
c    &           memory_int(iite2c_stored),nte2c_shl)
c        endif

         call decr_memory(gout_pt,'d')
         call decr_memory(iso_pt,'d')

C *
C * Energy
C *
_IF(ga)
      ibuff = incr_memory(cdbf_num,'d')
      iproc = ipg_nodeid()
c     call ga_distribution(g_2c, iproc, ilod, ihid, jlod, jhid)
c     do lbasf=ilod,ihid
         ilo = lbasf
         ihi = lbasf
         jlo = 1
         jhi = cdbf_num
c        call pg_get(g_2c,ilo,ihi,jlo,jhi,
c    &        memory_fp(ibuff),1)
c        e_coul = e_coul + ddot(cdbf_num,memory_fp(ibuff)
c    &        ,1,memory_fp(icfit_pt),1) *
c    &           memory_fp(icfit_pt+lbasf-1)
c     enddo
      call decr_memory(ibuff,'d')
c     call pg_dgop(2001,e_coul,1,'+')
_ELSE
      call memreq_jfit_ivform(memory_int,
     &                        memory_fp,
     &                        cdbf_num,
     &                        .false.,
     &                        memory_fp(vqr_pt),
     &                        memory_fp(schwarz_cd))

      col=0
c     do lbasf=0,cdbf_num-1
c        e_coul=e_coul+ddot(cdbf_num,memory_fp(icfit_pt)
c    &      ,1,memory_fp(vqr_pt+col),1)*
c    &       memory_fp(icfit_pt+lbasf)
         col=col+cdbf_num
c     enddo
_ENDIF

c     e_self   = ddot(cdbf_num,memory_fp(tr_pt)
c    &  ,1,memory_fp(icfit_pt),1) 
c     e_coul   = e_self - (e_coul*0.5d0)
c     rho      = ddot(cdbf_num,memory_fp(icfit_pt)
c    &    ,1,memory_fp(nr_pt),1)
C *
C *api entry point
C *
C *Free used memory
C *
      if (schwarz_tol.ge.0.and.
     &    ((idunlap_called.eq.0.and.ocfit_sw).or.
     &     (.not.ocfit_sw))) then
         call decr_memory(schwarz_ao,'d')
         call decr_memory(schwarz_cd,'d')
      endif
_IFN(ga)
      call decr_memory(vqr_pt,'d')
_ENDIF
      if (ocfit_sw) then
c        the memory for the fitting coefficients will be released by
c        CD_jfit_clean1
      else 
         call decr_memory(icfit_pt,'d')
      endif
      call decr_memory(nr_pt,'d')
      call decr_memory(tr_pt,'d')

C *
C **********************************************************************
      return
      end
_IFN(ga)
      subroutine memreq_jfit_ivform(memory_int,memory_fp,
     &               cdbf_num,invert_sw,v_mat,schwarz_cd)
C **********************************************************************
C *Description:	                                                       *
C *Form the matrix V-1. For use with Dunlap Coulomb fit.               *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_memory_info)
INCLUDE(common/dft_dunlap)

c temp
INCLUDE(../m4/common/symtry)      ! for iso
INCLUDE(../m4/common/iofile)      ! to access idaf
INCLUDE(common/dft_mbasis)        ! for nshell(1)
INCLUDE(common/dft_basis)         ! for bset_tags(2)

      integer cdbf_num
      logical invert_sw
C *Scratch space and pointers
      integer memory_int(*)
      REAL memory_fp(*)
      integer null_pt
c      integer nte3c_int, nte3c_shl, nte2c_int, nte2c_shl
c      REAL te3c_store(nte3c_int), te2c_store(nte2c_int)
c      REAL ite3c_stored(nte3c_shl), ite2c_stored(nte2c_shl)
C *Out variables
      REAL v_mat(cdbf_num,cdbf_num) 
c     this line gives compilation errors under g77 (invalid ref to nshell)
c     REAL schwarz_cd(nshell(bset_tags(2)))
      REAL schwarz_cd(*)
C *Local variables
      integer li,lj
      integer cd_basfn

      integer basi, basj, bask, basl
      integer imode
      integer iiso, gout_pt
      REAL dum

C *Functions
      integer incr_memory
C *End declarations
C **********************************************************************
C **********************************************************************
C *Allocate scratch space for integrals
C *
C * Pointer		Length				Memory type
C * null_pt		1				double
C *
      cd_basfn = cdbf_num*cdbf_num
c     null_pt  = incr_memory(1,'d')
C *
C *Calculate 2 centre 2 electron repulsion integrals
C *
c
c NB should be redundant as symmetry is not used, but array is
c still referenced - dummmy array is built in jkint
c

         iiso = incr_memory(nshell(2),'d')
         gout_pt=incr_memory(50625,'d')
c        call aclear_dp(memory_fp(gout_pt),50625,0.0d0)
c        call aclear_dp(v_mat,cd_basfn,0.0d0)
         basi = 2
         basj = -1
         bask = 2
         basl = -1

         imode = 6

c        if (.not.ocfit_sw) then
c           call jkint_dft(memory_fp(iiso),
c    &           memory_fp(gout_pt),nshell(2),
c    &           basi, basj, bask, basl,
c    &           imode,v_mat,dum, dum, dum, dum, schwarz_cd)
c        else if (idunlap_called.eq.0) then
c           call jkint_dft_cntgen(memory_fp(iiso),
c    &           memory_fp(gout_pt),nshell(2),
c    &           basi, basj, bask, basl,
c    &           imode,v_mat,dum, dum, dum, dum, schwarz_cd,
c    &           memory_fp(ite3c_store), nte3c_int, 
c    &           memory_int(iite3c_stored), nte3c_shl,
c    &           memory_fp(ite2c_store), nte2c_int, 
c    &           memory_int(iite2c_stored), nte2c_shl)
c        else
c           call jkint_dft_genuse(memory_fp(iiso),
c    &           memory_fp(gout_pt),nshell(2),
c    &           basi, basj, bask, basl,
c    &           imode,v_mat,dum, dum, dum,
c    &           memory_fp(ite3c_store), nte3c_int, 
c    &           memory_int(iite3c_stored), nte3c_shl,
c    &           memory_fp(ite2c_store), nte2c_int, 
c    &           memory_int(iite2c_stored), nte2c_shl)
c        endif

c        do li=1,cdbf_num
c           do lj=1,li
c              v_mat(lj,li)=v_mat(li,lj)
c           enddo
c        enddo

         call decr_memory(gout_pt,'d')
         call decr_memory(iiso,'d')

      if(invert_sw) then
C *
C *Invert matrix
C *
        call memreq_matPack_drv(memory_int,
     &                          memory_fp,
     &                          .false.,.true.,
     &                          .false.,.false.,
     &                          cdbf_num,v_mat)
      endif

c     do li=1,cdbf_num
c       do lj=1,li
c         v_mat(lj,li)=v_mat(li,lj)
c       enddo
c     enddo

c     call decr_memory(null_pt,'d')
      return
      end
_ENDIF
c---- the routines that do the real work -------------------------------
_IF(ga)
c **********************************************************************
c pre_fit : compute quantities that are needed each SCF cycle
c          
c  allocate global arrays (if not already allocated)
c  compute 2-centre integrals and invert V matrix
c
c **********************************************************************
      block data dft_dunlap_ga_data
      implicit none
INCLUDE(common/dft_dunlap_ga)
      data g_2c,g_2cinv/-1,-1/
      data g_2c_cnt,g_2cinv_cnt/-1,-1/
      end

      subroutine pre_fit(schwarz_cd,memory_fp, ncd)
      implicit none

INCLUDE(common/dft_parameters)
INCLUDE(common/dft_dunlap_ga)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_dunlap)
INCLUDE(common/dft_mbasis)        ! for nshell(1)
INCLUDE(common/dft_basis)         ! for bset_tags(2)
INCLUDE(../m4/common/gmempara)

INCLUDE(../m4/common/timeperiods)
      character *9 fnm
      character *7 snm

      integer ncd
      REAL schwarz_cd(*)          !  actually empty at this point
      REAL memory_fp(*)
      integer i

c local variables
      integer basi, basj, bask, basl, imode
      integer gout_pt, iiso
      REAL dum

C *Functions
      integer allocate_memory2
      logical pg_create_inf, pg_destroy_inf

      external  dft_dunlap_ga_data

      data fnm/'coulomb.m'/
      data snm/'pre_fit'/
 
      if(g_2c .eq. -1)then

         if (.not. pg_create_inf(0,ncd,ncd,'2c ints',0,ncd,
     &        g_2c,fnm,snm,IGMEM_NORMAL )) then
            call pg_error('failed to create 2c integral GA ',i)
         end if

         if (.not. pg_create_inf(0,ncd,ncd,'2-c inv',0,ncd,
     &        g_2cinv,fnm,snm,IGMEM_NORMAL )) then
            call pg_error('failed to create inverse 2c integral GA ',i)
         end if

      endif
      if (.not. pg_create_inf(0,ncd,ncd,'temp',0,ncd,
     &    g_tmp,fnm,snm,IGMEM_NORMAL )) then
         call pg_error('failed to create temp GA ',i)
      end if
c
c NB iso should be redundant as symmetry is not used, but array is
c still referenced - dummmy array is built in jkint
c
      iiso = allocate_memory2(nshell(2),'d',fnm,snm,'iiso')
      gout_pt=allocate_memory2(50625,'d',fnm,snm,'gout')
      call aclear_dp(memory_fp(gout_pt),50625,0.0d0)
      basi = 2
      basj = -1
      bask = 2
      basl = -1

      imode = 61

      call jkint_dft(memory_fp(iiso),
     &     memory_fp(gout_pt),nshell(basi),
     &     basi, basj, bask, basl,
     &     imode,dum,dum, dum, dum, dum, dum)

      call free_memory2(gout_pt,'d',fnm,snm,'gout')
      call free_memory2(iiso,'d',fnm,snm,'iiso')

      call start_time_period(TP_DFT_JFIT_INV)

      call ga_copy(g_2c,g_tmp)

c      call pg_print(g_2c)
      call dft_invert(g_2c, g_2cinv, ncd)
c      call pg_print(g_2cinv)

      call ga_copy(g_tmp,g_2c)

c      call ga_dgemm('n','n', ncd, ncd, ncd, 1.0d0,
c     & g_2c, g_2cinv, 0.0d0, g_tmp)
c      call ga_print(g_tmp)

      if (.not. pg_destroy_inf(g_tmp,'temp',fnm,snm)) call caserr(
     &   'pre_fit: could not destroy g_tmp')

      call end_time_period(TP_DFT_JFIT_INV)

      end
      subroutine post_fit
c
c     This routine is meant to clean up the memory allocated in the
c     pre_fit routine.
c
INCLUDE(common/dft_dunlap_ga)
INCLUDE(../m4/common/gmempara)
c
c...  Local variables
c
      integer i
      character *9 fnm
      character *8 snm
c
c...  Functions
c
      logical  pg_destroy_inf
      external pg_destroy_inf
c
c...  Data
c
      data fnm/'coulomb.m'/
      data snm/'post_fit'/
c
c...  Code
c
      if (g_2c .ne. -1) then
         if (.not. pg_destroy_inf(g_2c,'2c ints',fnm,snm)) 
     &       call pg_error('post_fit: could not destroy g_2c',i)
         if (.not. pg_destroy_inf(g_2cinv,'2-c inv',fnm,snm)) 
     &       call pg_error('post_fit: could not destroy g_2cinv',i)
         g_2c    = -1
         g_2cinv = -1
      endif
c
      end
_ENDIF
      subroutine jfit_dunlap(memory_fp,
     &                       memory_int,
     &                       kma,kmb,adens,bdens,iout)
C **********************************************************************
C *Description:                                                        *
C *Generate J matrix using Dunlap fitting method                       *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_api)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_memory_info)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis_cont_inf)
INCLUDE(common/dft_dunlap)
      REAL kma(*),kmb(*),adens(*),bdens(*)
      integer iout
C *Scratch space and pointer
      integer memory_int(*)
      REAL memory_fp(*)
      integer tr_pt,nr_pt,schwarz_cd,schwarz_ao
C *Local variables
      integer lbasf,col,ico
      integer ao_tag,cd_tag,cdbf_num
      integer ao_basfn,tot_basfn
      integer size_required
      REAL ivn_sum,sum1,sum2,lambda,t_lambdan
      REAL e_coul,e_self,rho
      integer ntmp,n2c,n3c
      integer nnodes
      integer push_memory_count,    pop_memory_count
      integer push_memory_estimate, pop_memory_estimate
      integer imemcount, imemusage, imemestimate
      logical omemok
      save omemok

      character*9  fnm
      character*11 snm

_IF(ga)
      integer ilo, ihi, jlo, jhi, ibuff, iproc
      integer ilod, ihid, jlod, jhid
      integer ipg_nodeid
_ELSE
      integer vqr_pt
_ENDIF


c for testing jkint
      integer iso_pt, gout_pt, nsh
      REAL dum
INCLUDE(common/dft_mbasis)
      integer basi, basj, bask, basl, imode

C *Functions
      integer allocate_memory2, lenwrd, null_memory
      external allocate_memory2, null_memory
      integer ipg_nnodes
_IF(single)
      REAL sdot
_ELSEIF(hp700)
      REAL `vec_$ddot'
_ELSE
      REAL ddot
_ENDIF

      logical opg_root
C *
C *End declarations
C **********************************************************************
C *
INCLUDE(../m4/common/timeperiods)
INCLUDE(../m4/common/errcodes)
INCLUDE(../m4/common/restar)
_IF(ga)
INCLUDE(common/dft_dunlap_ga)
_ENDIF
      data fnm/'coulomb.m'/
      data snm/'jfit_dunlap'/
      data omemok/.false./
_IF(debug)
      omemok = .false.
_ENDIF
      if (.not.omemok) then
         imemcount = push_memory_estimate()
         call memreq_jfit_dunlap(memory_fp,memory_int,
     &        kma,kmb,adens,bdens)
         imemestimate = pop_memory_estimate(imemcount)
         imemcount = push_memory_count()
      endif
      if(debug_sw .and. opg_root()) write(6,*) 'Entering jfit_dunlap.f',
     &     num_bset
      call start_time_period(TP_DFT_JFIT)

      potential_sw = .false.
      dunlap_sw = .true.
      e_coul   = 0.0d0
      rho      = 0.0d0
      ao_tag=bset_tags(1)
      cd_tag=bset_tags(2)
C **********************************************************************
C *Allocate memory into needed blocks                             
C *
C * Set 1 - Arrays used in forming kohn-sham matrix and energy
C *
C * Pointer             Length                  Memory type
C * tr_pt					double
C * nr_pt					double
C * vqr_pt					double
C * cfit_pt					double
      cdbf_num=totbfn(cd_tag)
      if (opg_root().and.nprint.ne.-5) then
        write(iout,12345) cdbf_num
      endif
      ao_basfn=totbfn(ao_tag)

      tr_pt   = allocate_memory2(cdbf_num,'d',fnm,snm,'tr')
      nr_pt   = allocate_memory2(cdbf_num,'d',fnm,snm,'nr')
      if (ocfit_sw) then
c        the fitting coefficients have to survive between the scf and
c        gradient calculation. Therefore they are stored in the space
c        allocated by CD_jfit_init1.
      else
         icfit_pt = allocate_memory2(cdbf_num,'d',fnm,snm,'icfit')
      endif
_IFN(ga)
      size_required=cdbf_num*cdbf_num
      vqr_pt  = allocate_memory2(size_required,'d',fnm,snm,'vqr')
_ENDIF
      if (schwarz_tol.ge.0.and.
     &    ((idunlap_called.eq.0.and.ocfit_sw).or.
     &     (.not.ocfit_sw))) then
         schwarz_cd = allocate_memory2(nshell(cd_tag),'d',fnm,snm,
     &                                'schwarz_cd')
      else
         schwarz_cd = null_memory()
      endif

C *End memory allocation
C **********************************************************************
C *
C *Obtain fitting coefficients for the density
C *
      tot_basfn=cdbf_num*ao_basfn
      if(debug_sw .and. opg_root()) then
        write(iout,*)
        if(triangle_sw) write(iout,*) 'Using triangle matrices'
        write(iout,12345) cdbf_num
        write(iout,*) 'AO matrix size                    :',ao_basfn
        write(iout,*) 'Matrix size                       :',tot_basfn
      endif
C *
C *Calculate 2 centre 2 electron repulsion integrals and invert matrix
C *

_IFN(ga)
      call start_time_period(TP_DFT_JFIT_VFORM)
      call jfit_ivform(memory_int,
     &                 memory_fp,
     &                 cdbf_num,
     &                 .true.,
     &                 memory_fp(vqr_pt),
     &                 memory_fp(schwarz_cd))
c     &                 memory_fp(ite3c_store),nte3c_int,
c     &                 memory_fp(iite3c_stored),nte3c_shl,
c     &                 memory_fp(ite2c_store),nte2c_int,
c     &                 memory_fp(iite2c_stored),nte2c_shl)

      call end_time_period(TP_DFT_JFIT_VFORM)

      if(print_sw(DEBUG_MEMORY))then
         if(opg_root())write(iout,*)'check guards after ivform'
         call gmem_check_guards
      endif
_ELSE
      if (idunlap_called.eq.0) then
c
c Allocate GAs and load with 2c and inverse 2c integrals
c 
         call start_time_period(TP_DFT_JFIT_VFORM)
         call pre_fit(memory_fp(schwarz_cd),memory_fp,cdbf_num)
         call end_time_period(TP_DFT_JFIT_VFORM)
      endif
_ENDIF

C *
C *Form the tr matrix
C *
      call aclear_dp(memory_fp(tr_pt),cdbf_num,0.0d0)

      if (idunlap_called.eq.0) then
         call start_time_period(TP_DFT_JFIT_TR_INIT)
      else 
         call start_time_period(TP_DFT_JFIT_TR)
      endif

      if(.false.)then

         call intPack_drv(memory_int,
     &        memory_fp,
     &        adens,
     &        .false.,.false.,
     &        .false.,
     &        .false.,potential_sw,
     &        .false.,dunlap_sw,
     &        .true.,
     &        memory_fp(tr_pt))

         if(print_sw(DEBUG_MEMORY))then
            if(opg_root())write(iout,*)'check guards after tr'
            call gmem_check_guards
         endif

         if(opg_root() .and. print_sw(DEBUG_TR))then
            do ico=0,cdbf_num-1
               write(iout,*) 'Tr Vector:',ico+1,memory_fp(tr_pt+ico)
            enddo
         endif

      else
c
         if (schwarz_tol.ge.0.and.
     &       ((idunlap_called.eq.0.and.ocfit_sw).or.
     &        (.not.ocfit_sw))) then
            schwarz_ao = allocate_memory2((nshell(ao_tag)+1)*
     &                   nshell(ao_tag)/2,'d',fnm,snm,'schwarz_ao')
         else
            schwarz_ao = null_memory()
         endif

         nsh = BL_max_shell_count()
         iso_pt = allocate_memory2(nsh,'d',fnm,snm,'iso')

         gout_pt=allocate_memory2(50625,'d',fnm,snm,'gout')
         call aclear_dp(memory_fp(gout_pt),50625,0.0d0)
         
         if (schwarz_tol.ge.0.and.
     &       ((idunlap_called.eq.0.and.ocfit_sw).or.
     &        (.not.ocfit_sw))) then
            call coulmb_dft(memory_fp(schwarz_ao),memory_fp(gout_pt),
     &                      ao_tag)
            call te2c_rep_schwarz(cd_tag,memory_fp(gout_pt),
     &                            memory_fp(schwarz_cd))
            if(print_sw(DEBUG_MEMORY))then
               if(opg_root())write(iout,*)'check guards after coulmb'
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
            call jkint_dft_genuse(memory_fp(iso_pt),
     &           memory_fp(gout_pt),nsh,
     &           basi, basj, bask, basl,
     &           imode,adens,bdens,memory_fp(tr_pt),dum,
     &           memory_fp(ite3c_store),nte3c_int,
     &           memory_int(iite3c_stored),nte3c_shl,
     &           memory_fp(ite2c_store),nte2c_int,
     &           memory_int(iite2c_stored),nte2c_shl)
         endif


         if(print_sw(DEBUG_MEMORY))then
            if(opg_root())write(6,*)'check guards after jkint_dft 4'
            call gmem_check_guards
         endif
         call free_memory2(gout_pt,'d',fnm,snm,'gout')
         call free_memory2(iso_pt,'d',fnm,snm,'iso')

         if(opg_root() .and. print_sw(DEBUG_TR))then
            do ico=0,cdbf_num-1
               write(iout,*) 'Tr Vector:',ico+1,memory_fp(tr_pt+ico)
            enddo
         endif

      endif

      if (idunlap_called.eq.0) then
         call end_time_period(TP_DFT_JFIT_TR_INIT)
      else 
         call end_time_period(TP_DFT_JFIT_TR)
      endif
c
      idunlap_called = idunlap_called + 1

C *
C *Form 1 centre integral array from fitting functions, ie nr
C *
      call aclear_dp(memory_fp(nr_pt),cdbf_num-1,0.0d0)

      call start_time_period(TP_DFT_JFIT_NR)

      call intPack_drv(memory_int,
     &                 memory_fp, 
     &                 memory_fp(icfit_pt),
     &                 .true.,.false.,
     &                 .true.,
     &                 .false.,.false.,
     &                 .false.,.false.,
     &                 .false.,
     &                 memory_fp(nr_pt)) 

      call end_time_period(TP_DFT_JFIT_NR)

      if(print_sw(DEBUG_MEMORY))then
         if(opg_root())write(6,*)'check guards after nr'
         call gmem_check_guards
      endif

      if(opg_root() .and. print_sw(DEBUG_NR))then
        do ico=0,cdbf_num-1
          write(iout,*) 'nr:',ico+1,memory_fp(nr_pt+ico)
        enddo
      endif
C *
C *Calculate Lagrange Multiplier lambda
C *
      col  = 0
      sum1 = 0.0d0
      sum2 = 0.0d0

      call start_time_period(TP_DFT_JFIT_COEF)

_IF(ga)
      ibuff = allocate_memory2(cdbf_num,'d',fnm,snm,'ibuff')
      iproc = ipg_nodeid()
      call ga_distribution(g_2cinv, iproc, ilod, ihid, jlod, jhid)
      do lbasf=ilod,ihid
         ilo = lbasf
         ihi = lbasf
         jlo = 1
         jhi = cdbf_num
         call pg_get(g_2cinv,ilo,ihi,jlo,jhi,
     &        memory_fp(ibuff),1)
         ivn_sum=ddot(cdbf_num,memory_fp(ibuff)
     &        ,1,memory_fp(nr_pt),1)
         sum1=sum1+ivn_sum*memory_fp(tr_pt+lbasf-1)
         sum2=sum2+ivn_sum*memory_fp(nr_pt+lbasf-1)
      enddo
      call free_memory2(ibuff,'d',fnm,snm,'ibuff')
      call pg_dgop(2001,sum1,1,'+')
      call pg_dgop(2002,sum2,1,'+')
_ELSE
      do lbasf=0,cdbf_num-1
        ivn_sum=ddot(cdbf_num,memory_fp(vqr_pt+col)
     & ,1,memory_fp(nr_pt),1)
c       write(iout,*) 'ivn_sum:',ivn_sum
        col=col+cdbf_num
        sum1=sum1+ivn_sum*memory_fp(tr_pt+lbasf)
        sum2=sum2+ivn_sum*memory_fp(nr_pt+lbasf)
      enddo
_ENDIF
      lambda=(nelectrons-sum1)/sum2

C *
C *api entry point
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
      ibuff = allocate_memory2(cdbf_num,'d',fnm,snm,'ibuff2')
      iproc = ipg_nodeid()
      call ga_distribution(g_2cinv, iproc, ilod, ihid, jlod, jhid)
      do lbasf=ilod,ihid

         t_lambdan=memory_fp(tr_pt+lbasf-1) + 
     &        lambda*memory_fp(nr_pt+lbasf-1)
         ilo = lbasf
         ihi = lbasf
         jlo = 1
         jhi = cdbf_num
         call pg_get(g_2cinv,ilo,ihi,jlo,jhi,
     &        memory_fp(ibuff),1)

         call daxpy(cdbf_num,t_lambdan
     &           ,memory_fp(ibuff),1
     &           ,memory_fp(icfit_pt),1)
      enddo
      call free_memory2(ibuff,'d',fnm,snm,'ibuff2')
      call pg_dgop(2003,memory_fp(icfit_pt),cdbf_num,'+')
_ELSE
      col = 0
      do lbasf=0,cdbf_num-1
        t_lambdan=memory_fp(tr_pt+lbasf)+lambda*memory_fp(nr_pt+lbasf)
        call daxpy(cdbf_num,t_lambdan
     &           ,memory_fp(vqr_pt+col),1
     &           ,memory_fp(icfit_pt),1)
        col=col+cdbf_num
      enddo
_ENDIF


      call end_time_period(TP_DFT_JFIT_COEF)

      if(print_sw(DEBUG_MEMORY))then
         if(opg_root())write(iout,*)'check guards after fit'
         call gmem_check_guards
      endif
C *
C *Calculate matrix elements and energy
C *
C *Potential
C *
      call start_time_period(TP_DFT_JFIT_KSMAT)

      if(.false.)then

         call intPack_drv(memory_int,
     &        memory_fp,
     &        memory_fp(icfit_pt),
     &        .false.,.true.,
     &        .false.,
     &        .false.,potential_sw,
     &        .false.,dunlap_sw,
     &        .true.,
     &        kma)

      else

         nsh = BL_max_shell_count()
         iso_pt = allocate_memory2(nsh,'d',fnm,snm,'iso2')

         gout_pt=allocate_memory2(50625,'d',fnm,snm,'gout2')
         call aclear_dp(memory_fp(gout_pt),50625,0.0d0)

         basi = ao_tag
         basj = ao_tag
         bask = cd_tag
         basl = -1

         imode = 3

         if (.not.ocfit_sw) then
            call jkint_dft(memory_fp(iso_pt),
     &           memory_fp(gout_pt),nsh,
     &           basi, basj, bask, basl,
     &           imode,memory_fp(icfit_pt),dum,kma,kmb,
     &           memory_fp(schwarz_ao),
     &           memory_fp(schwarz_cd))
         else
            call jkint_dft_genuse(memory_fp(iso_pt),
     &           memory_fp(gout_pt),nsh,
     &           basi, basj, bask, basl,
     &           imode,memory_fp(icfit_pt),dum,kma,kmb,
     &           memory_fp(ite3c_store),nte3c_int,
     &           memory_int(iite3c_stored),nte3c_shl,
     &           memory_fp(ite2c_store),nte2c_int,
     &           memory_int(iite2c_stored),nte2c_shl)
         endif

         call free_memory2(gout_pt,'d',fnm,snm,'gout2')
         call free_memory2(iso_pt,'d',fnm,snm,'iso2')

         if(print_sw(DEBUG_MEMORY))then
            if(opg_root())write(6,*)'check guards after pot'
            call gmem_check_guards
         endif

         call end_time_period(TP_DFT_JFIT_KSMAT)

      endif
C *
C * Energy
C *
      call start_time_period(TP_DFT_JFIT_ENERGY)
_IF(ga)
      ibuff = allocate_memory2(cdbf_num,'d',fnm,snm,'ibuff3')
      iproc = ipg_nodeid()
      call ga_distribution(g_2c, iproc, ilod, ihid, jlod, jhid)
      do lbasf=ilod,ihid
         ilo = lbasf
         ihi = lbasf
         jlo = 1
         jhi = cdbf_num
         call pg_get(g_2c,ilo,ihi,jlo,jhi,
     &        memory_fp(ibuff),1)
         e_coul = e_coul + ddot(cdbf_num,memory_fp(ibuff)
     &        ,1,memory_fp(icfit_pt),1) *
     &           memory_fp(icfit_pt+lbasf-1)
      enddo
      call free_memory2(ibuff,'d',fnm,snm,'ibuff3')
      call pg_dgop(2001,e_coul,1,'+')
_ELSE
      call jfit_ivform(memory_int,
     &                 memory_fp,
     &                 cdbf_num,
     &                 .false.,
     &                 memory_fp(vqr_pt),
     &                 memory_fp(schwarz_cd))
c    &                 memory_fp(ite3c_store),nte3c_int,
c    &                 memory_int(iite3c_stored),nte3c_shl,
c    &                 memory_fp(ite2c_store),nte2c_int,
c    &                 memory_int(iite2c_stored),nte2c_shl)

      col=0
      do lbasf=0,cdbf_num-1
         e_coul=e_coul+ddot(cdbf_num,memory_fp(icfit_pt)
     &      ,1,memory_fp(vqr_pt+col),1)*
     &       memory_fp(icfit_pt+lbasf)
         col=col+cdbf_num
      enddo
_ENDIF

      e_self   = ddot(cdbf_num,memory_fp(tr_pt)
     &  ,1,memory_fp(icfit_pt),1) 
      e_coul   = e_self - (e_coul*0.5d0)
      rho      = ddot(cdbf_num,memory_fp(icfit_pt)
     &    ,1,memory_fp(nr_pt),1)
C *
C *api entry point
C *
      J_energy = e_coul

      call end_time_period(TP_DFT_JFIT_ENERGY)

      if(opg_root() .and. print_sw(DEBUG_JFIT))then
        do col=0,cdbf_num-1
          if(opg_root())write(iout,*) 'cfit:',memory_fp(icfit_pt+col)
        enddo
      endif

      if(print_sw(DEBUG_MEMORY))then
         if(opg_root())write(iout,*)'check guards after energy'
         call gmem_check_guards
      endif
C *
C *Free used memory
C *
      if (schwarz_tol.ge.0.and.
     &    ((idunlap_called.eq.1.and.ocfit_sw).or.
     &     (.not.ocfit_sw))) then
         call free_memory2(schwarz_ao,'d',fnm,snm,'schwarz_ao')
         call free_memory2(schwarz_cd,'d',fnm,snm,'schwarz_cd')
      endif
_IFN(ga)
      call free_memory2(vqr_pt,'d',fnm,snm,'vqr')
_ENDIF
      if (ocfit_sw) then
c        the memory for the fitting coefficients will be released by
c        CD_jfit_clean1
      else 
         call free_memory2(icfit_pt,'d',fnm,snm,'icfit')
      endif
      call free_memory2(nr_pt,'d',fnm,snm,'nr')
      call free_memory2(tr_pt,'d',fnm,snm,'tr')

      call end_time_period(TP_DFT_JFIT)

      if (.not.omemok) then
         imemusage = pop_memory_count(imemcount)
         if (imemusage.ge.0.9d0*imemestimate.and.
     &       imemusage.le.imemestimate) omemok = .true.
         if (opg_root().and.(.not.omemok)) then
            write(*,*)'*** estimated memory usage = ',imemestimate,
     &                ' words'
            write(*,*)'*** actual    memory usage = ',imemusage   ,
     &                ' words'
            write(*,*)'*** WARNING: the memory usage estimates for ',
     &                'jfit_dunlap seem to be incorrect'
         endif
      endif
C *
C **********************************************************************
      return
12345 format(/1x,'Number of fitting basis functions :',i4)
      end
_IFN(ga)
      subroutine jfit_ivform(memory_int,memory_fp,
     &               cdbf_num,invert_sw,v_mat,schwarz_cd)
c     &               te3c_store, nte3c_int, ite3c_stored, nte3c_shl,
c     &               te2c_store, nte2c_int, ite2c_stored, nte2c_shl)
C **********************************************************************
C *Description:	                                                       *
C *Form the matrix V-1. For use with Dunlap Coulomb fit.               *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_memory_info)
INCLUDE(common/dft_dunlap)

c temp
INCLUDE(../m4/common/symtry)      ! for iso
INCLUDE(../m4/common/iofile)      ! to access idaf
INCLUDE(common/dft_mbasis)        ! for nshell(1)
INCLUDE(common/dft_basis)         ! for bset_tags(2)

      integer cdbf_num
      logical invert_sw
C *Scratch space and pointers
      integer memory_int(*)
      REAL memory_fp(*)
      integer null_pt
c      integer nte3c_int, nte3c_shl, nte2c_int, nte2c_shl
c      REAL te3c_store(nte3c_int), te2c_store(nte2c_int)
c      REAL ite3c_stored(nte3c_shl), ite2c_stored(nte2c_shl)
C *Out variables
      REAL v_mat(cdbf_num,cdbf_num) 
c     this line gives compilation errors under g77 (invalid ref to nshell)
c     REAL schwarz_cd(nshell(bset_tags(2)))
      REAL schwarz_cd(*)
C *Local variables
      integer li,lj
      integer cd_basfn

      integer basi, basj, bask, basl
      integer imode
      integer iiso, gout_pt
      REAL dum

C *Functions
      integer allocate_memory
      integer null_memory
C *End declarations
C **********************************************************************
C **********************************************************************
C *Allocate scratch space for integrals
C *
C * Pointer		Length				Memory type
C * null_pt		1				double
C *
      cd_basfn = cdbf_num*cdbf_num
C *
C *Calculate 2 centre 2 electron repulsion integrals
C *
      if(.false.)then

         null_pt  = allocate_memory(1,'d')
c -1 removed
c         call aclear_dp(v_mat,cd_basfn-1,0.0d0)

         call aclear_dp(v_mat,cd_basfn,0.0d0)
         call intPack_drv(memory_int,
     &        memory_fp,
     &        memory_fp(null_pt),
     &        .false.,.false.,
     &        .false.,
     &        potential_sw,.false.,
     &        dunlap_sw,.false.,
     &        .false.,
     &        v_mat)

         do li=1,cdbf_num
            do lj=1,li
               v_mat(lj,li)=v_mat(li,lj)
c               write(6,*) 'V_MAT:',li,lj,v_mat(li,lj)
            enddo
         enddo

         call free_memory(null_pt,'d')

      else
c
c NB should be redundant as symmetry is not used, but array is
c still referenced - dummmy array is built in jkint
c

         null_pt = null_memory()
         iiso = allocate_memory(nshell(2),'d')
         gout_pt=allocate_memory(50625,'d')
         call aclear_dp(memory_fp(gout_pt),50625,0.0d0)
         call aclear_dp(v_mat,cd_basfn,0.0d0)
         basi = 2
         basj = -1
         bask = 2
         basl = -1

         imode = 6

         if (.not.ocfit_sw) then
            call jkint_dft(memory_fp(iiso),
     &           memory_fp(gout_pt),nshell(2),
     &           basi, basj, bask, basl,
     &           imode,v_mat,
     &           memory_fp(null_pt),
     &           memory_fp(null_pt),
     &           memory_fp(null_pt),
     &           memory_fp(null_pt),
     &           schwarz_cd)
         else if (idunlap_called.eq.0) then
            call jkint_dft_cntgen(memory_fp(iiso),
     &           memory_fp(gout_pt),nshell(2),
     &           basi, basj, bask, basl,
     &           imode,v_mat,
     &           memory_fp(null_pt),
     &           memory_fp(null_pt),
     &           memory_fp(null_pt),
     &           memory_fp(null_pt), schwarz_cd,
     &           memory_fp(ite3c_store), nte3c_int, 
     &           memory_int(iite3c_stored), nte3c_shl,
     &           memory_fp(ite2c_store), nte2c_int, 
     &           memory_int(iite2c_stored), nte2c_shl)
         else
            call jkint_dft_genuse(memory_fp(iiso),
     &           memory_fp(gout_pt),nshell(2),
     &           basi, basj, bask, basl,
     &           imode,v_mat,
     &           memory_fp(null_pt),
     &           memory_fp(null_pt),
     &           memory_fp(null_pt),
     &           memory_fp(ite3c_store), nte3c_int, 
     &           memory_int(iite3c_stored), nte3c_shl,
     &           memory_fp(ite2c_store), nte2c_int, 
     &           memory_int(iite2c_stored), nte2c_shl)
         endif

         do li=1,cdbf_num
            do lj=1,li
               v_mat(lj,li)=v_mat(li,lj)
c               write(6,*) 'V_MAT:',li,lj,v_mat(li,lj)
            enddo
         enddo

         call free_memory(gout_pt,'d')
         call free_memory(iiso,'d')

      endif

      if(invert_sw) then
C *
C *Invert matrix
C *
        call matPack_drv(memory_int,
     &                   memory_fp,
     &                   .false.,.true.,
     &                   .false.,.false.,
     &                   cdbf_num,v_mat)
      endif

      do li=1,cdbf_num
        do lj=1,li
          v_mat(lj,li)=v_mat(li,lj)
c     write(6,*) 'iV_MAT:',li,lj,v_mat(li,lj)
        enddo
      enddo

      return
      end
_ENDIF
      subroutine ver_dft_coulomb(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/dft/coulomb.m,v $
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

