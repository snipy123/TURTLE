c---- memory counting routines -----------------------------------------
      integer function CD_memreq_energy_ao(memory_fp,memory_int,iout)
C **********************************************************************
C *Description:                                                        *
C *Form the Kohn-Sham matrix using a variety of methods.               *
C *                                                                    *
C * The switches for various methods                                   *
C * ---------------------------------                                  *
C *                                                                    *
C * Jfit_dun -        Fit the Coulomb potential using Dunlaps method   *
C * K_fit    -        Use linear least squares fit to form K matrix    *
C * K_quad   -        Use quadrature to form K matrix                  *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *
C *Parameters

INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis_api)
INCLUDE(../m4/common/statis)

c for basis set max values
INCLUDE(common/dft_basis)
c
C In variables
c
      integer iout
INCLUDE(common/dft_api)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)

C *Scratch space and pointers
      integer memory_int(*)
      REAL memory_fp(*)
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,prpt_ct,prwt_ct
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer abfnval_pt,fitmat_pt,indx_pt,ckfit_pt
      integer bfnuse_pt,bfnpnum_pt,bfnpide_pt
      integer nprm_pt,angm_pt,pstr_pt,cent_pt,alpa_pt,coco_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
c     integer xc_ept_pt, xc_vpt_pt, xc_dvpt_pt
      integer rho_pt, grho_pt
      integer mxp
C *Out variables
      REAL energy
      REAL sma
      REAL dum
C *Local variables
      integer ao_tag,kf_tag,ao_bas,i,iscr,iscrb,ltri
      REAL xc_tracep
      integer xbfn_num
      integer idum
      integer null
      integer iestimate

C *Functions
      integer null_memory
      integer allocate_memory2
      logical opg_root
      REAL tracep      
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate
      integer incr_memory
      integer ig

      character *8 fnm
      character *19 snm
      data fnm/"global.m"/
      data snm/"CD_memreq_energy_ao"/
C *End declarations
C **********************************************************************
c
c hardwired in for now
      ao_tag=1
      kf_tag=2
      ig    =G_KS
      null  = null_memory()
      iestimate = push_memory_estimate()
c
      ao_bas=((BL_basis_size(ao_tag)+1)*BL_basis_size(ao_tag))/2
      ltri = ao_bas

C **********************************************************************
C *Form the J matrix
C *
      if(jfit_sw) then
         kf_tag = 3
         iscr = incr_memory(ltri,'d')
         if( .not. rks_sw)then
            iscrb = incr_memory(ltri,'d')
         endif
         call memreq_Jfit_dunlap(memory_fp,memory_int,dum,dum,dum,dum)
         if (.not.rks_sw) then
            call decr_memory(iscrb,'d')
         endif
         call decr_memory(iscr,'d')
      elseif(mult_sw) then
         iscr = incr_memory(ltri,'d')
c        call memreq_JDriver
         call decr_memory(iscr,'d')
      endif
C *
C *Form the K matrix
C *
      if(kqua_sw.or.kfit_sw) then
         idum   =max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
         apts_pt=incr_memory(3*idum,'d')
         awts_pt=incr_memory(idum,'d')
         idum   =max_array(radpt_num(1,ig),ngtypes)
         prpt_ct=incr_memory(ngtypes*idum,'d')
         prwt_ct=incr_memory(ngtypes*idum,'d')
         prpt_pt=allocate_memory2(ngtypes*idum,'d',fnm,snm,"prpt_pt")
         prwt_pt=allocate_memory2(ngtypes*idum,'d',fnm,snm,"prwt_pt")
      endif
      if(kqua_sw) then
c
c largest size for batches of integration points
c
         mxp=200

         bfnuse_pt  = incr_memory(BL_basis_size(ao_tag),'i')
         bfnpnum_pt = incr_memory(BL_basis_size(ao_tag),'i')
         bfnpide_pt = incr_memory(90,'i')

C *
C * Set 3 - Expand basis set to basis function arrays
C *

c        nprm_pt=incr_memory(maxi_basA,'i')
c        angm_pt=incr_memory(maxi_basA,'i')
c        pstr_pt=incr_memory(maxi_basA,'i')
c        cent_pt=incr_memory(maxi_basA,'i')
c        alpa_pt=incr_memory(maxi_primA,'d')
c        coco_pt=incr_memory(maxi_primA,'d')

c       call expand_tobasisfns

        ra2_val_pt = incr_memory(mxp*natoms*2,'d')
        ra2_comp_pt = incr_memory(mxp*natoms*3,'d')
        rho_pt = incr_memory(mxp*2,'d')
        grho_pt = incr_memory(mxp*2*3,'d')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       0,                               ! no npert
     &       .false.,
     &       memory_fp(prpt_pt),
     &       memory_fp(prwt_pt),
     &       .true., .true., .false.,
     &       .false.,.false.,.false.,.false.,.false.,
     &       mxp,.true.,.false.,0.0d0,iout)

        call decr_memory(grho_pt,'d')
        call decr_memory(rho_pt,'d')
        call decr_memory(ra2_comp_pt,'d')
        call decr_memory(ra2_val_pt,'d')

c       call decr_memory(coco_pt,'d')
c       call decr_memory(alpa_pt,'d')
c       call decr_memory(cent_pt,'i')
c       call decr_memory(pstr_pt,'i')
c       call decr_memory(angm_pt,'i')
c       call decr_memory(nprm_pt,'i')

        call decr_memory(bfnpide_pt,'i')
        call decr_memory(bfnpnum_pt,'i')
        call decr_memory(bfnuse_pt,'i')

      endif
C
C     Obtain the Kohn-Sham matrix by fitting using an 
c     auxiliary basis set
C
      if(kfit_sw) then
        iscr = incr_memory(ltri,'d')
        xbfn_num   = BL_basis_size(kf_tag)*BL_basis_size(kf_tag)
        fitmat_pt  = incr_memory(xbfn_num,'d')
        ckfit_pt   = incr_memory(BL_basis_size(kf_tag),'d')
        indx_pt    = incr_memory(BL_basis_size(kf_tag),'i')
        bfnval_pt  = incr_memory(BL_basis_size(ao_tag),'d')
        abfnval_pt = incr_memory(BL_basis_size(kf_tag),'d')
c       call exfit(ao_tag,BL_num_types(ao_tag),
c    &             kf_tag,BL_basis_size(kf_tag),
c    &             memory_fp(apts_pt),
c    &             memory_fp(awts_pt),
c    &             memory_fp(prpt_pt),
c    &             memory_fp(prwt_pt),
c    &             memory_fp(fitmat_pt),
c    &             memory_fp(ckfit_pt),
c    &             memory_int(indx_pt),
c    &             memory_fp(bfnval_pt),
c    &             memory_fp(abfnval_pt),
c    &             adenm,bdenm,kma,kmb,
c    &             memory_int,memory_fp,extwr_sw)
        call decr_memory(abfnval_pt,'d')
        call decr_memory(bfnval_pt,'d')
        call decr_memory(indx_pt,'i')
        call decr_memory(ckfit_pt,'d')
        call decr_memory(fitmat_pt,'d')
        call decr_memory(iscr,'d')
      endif
C *
C *Return to SCF code
c
      call free_memory2(prwt_pt,'d',fnm,snm,"prwt_pt")
      call free_memory2(prpt_pt,'d',fnm,snm,"prpt_pt")
      call decr_memory(prwt_ct,'d')
      call decr_memory(prpt_ct,'d')
      call decr_memory(awts_pt,'d')
      call decr_memory(apts_pt,'d')
      CD_memreq_energy_ao = pop_memory_estimate(iestimate)
      return
      end
c
c-----------------------------------------------------------------------
c
      integer function CD_memreq_energy_mo(
     &     nvec,naocc,nbocc,
     &     memory_int,memory_fp,iout)

C **********************************************************************
C *Description:                                                        *
C *Form the Kohn-Sham matrix using a variety of methods.               *
C *                                                                    *
C * The switches for various methods                                   *
C * ---------------------------------                                  *
C *                                                                    *
C * Jfit_dun -        Fit the Coulomb potential using Dunlaps method   *
C * K_fit    -        Use linear least squares fit to form K matrix    *
C * K_quad   -        Use quadrature to form K matrix                  *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis_api)
INCLUDE(../m4/common/statis)

c for basis set max values
INCLUDE(common/dft_basis)
c
C In variables
c
      integer nvec,naocc,nbocc
      integer iout

INCLUDE(common/dft_api)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)

C *Scratch space and pointers
      integer memory_int(*)
      REAL memory_fp(*)
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,prpt_ct,prwt_ct
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer abfnval_pt,fitmat_pt,indx_pt,ckfit_pt
      integer bfnuse_pt,bfnpnum_pt,bfnpide_pt
      integer nprm_pt,angm_pt,pstr_pt,cent_pt,alpa_pt,coco_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
c     integer xc_ept_pt, xc_vpt_pt, xc_dvpt_pt
      integer rho_pt, grho_pt
      integer mxp
C *Out variables
      REAL energy
      REAL sma
C *Local variables
      integer ao_tag,kf_tag,ao_bas,i,iscr,iscrb,ltri
      REAL xc_tracep
      integer xbfn_num
      integer idum
      integer null
      integer ig
      integer iestimate

C *Functions
      integer null_memory
      integer incr_memory
      integer allocate_memory2
      logical opg_root
      REAL tracep      
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate

      character *8 fnm
      character *19 snm
      data fnm/"global.m"/
      data snm/"CD_memreq_energy_mo"/
C *End declarations
C **********************************************************************
c
c hardwired in for now
      ao_tag=1
      kf_tag=2
      ig    =G_KS
      null  = null_memory()
      iestimate=push_memory_estimate()
c
      if(debug_sw) write(6,*) 'Entering CD_memreq_energy_mo'
      if (kfit_sw.or.jfit_sw.or.mult_sw) then
         call caserr("CD_memreq_energy_mo: cannot handle fitting yet")
      endif

      ao_bas=((BL_basis_size(ao_tag)+1)*BL_basis_size(ao_tag))/2
      ltri = ao_bas

c     if(opg_root() .and. print_sw(DEBUG_DENSITY))then
c        write(6,*)'** Input Density **'
c        call prtri(adenm,BL_basis_size(ao_tag))
c     endif

C **********************************************************************
C *Form the J matrix
C *
c
c ps - kma gets cleared in here, although apparently
c      not explicitly - so the aclear is redundant
c

      if(jfit_sw) then
c        kf_tag = 3
c        iscr = incr_memory(ltri,'d')
c        call aclear_dp(memory_fp(iscr),ltri,0.0d0)
c        if( .not. rks_sw)then
c           iscrb = incr_memory(ltri,'d')
c           call aclear_dp(memory_fp(iscrb),ltri,0.0d0)
c        endif
c        call Jfit_dunlap(memory_fp,memory_int,
c    &        memory_fp(iscr),memory_fp(iscrb),
c    &        adenm,bdenm,iout)

c        if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
c          write(6,*)'** Vcoul **'
c          call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
c        endif
c
c sum in Vcoul
c
c        if (.not.rks_sw) then
c           call daxpy(ltri,1.0d0,memory_fp(iscrb),1,kmb,1)
c           call decr_memory(iscrb,'d')
c        endif
c        call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
c        call decr_memory(iscr,'d')

      elseif(mult_sw) then
c        iscr = incr_memory(ltri,'d')
c        call aclear_dp(memory_fp(iscr),ltri,0.0d0)
c        write(6,*) 'Off to JDriver'
c        call JDriver(ao_tag,adenm,bdenm,memory_fp(iscr),kmb)
c        J_energy=tracep(adenm,memory_fp(iscr),BL_basis_size(ao_tag))
c        J_energy=J_energy*0.5d0
c        if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
c           write(6,*)'** Vcoul **'
c           call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
c        endif
c        write(6,*) 'J_energy:',J_energy
c
c sum in Vcoul
c
c        call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
c        call decr_memory(iscr,'d')

      endif
c
c add timings for gamess analysis
c
      if(jfit_sw.or.mult_sw) then
         call timana(4)
         call cpuwal(begin,ebegin)
      endif

C * 
C *Form the K matrix
C *
      if(kqua_sw.or.kfit_sw) then
C *
C *Allocate memory into needed blocks
C *
C * Set 1 - Arrays used in grid generation
C *
C * Pointer             Length                  Array
C * apts_pt             3*max(angupt_num)       apts
C * awts_pt             max(angupt_num)         awts
C * prpt_pt             max(radpt_num)          prpt
C * prwt_pt             max(radpt_num)          prwt
C *
         idum   =max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
         apts_pt=incr_memory(3*idum,'d')
         awts_pt=incr_memory(idum,'d')
         idum   =max_array(radpt_num(1,ig),ngtypes)
         prpt_ct=incr_memory(ngtypes*idum,'d')
         prwt_ct=incr_memory(ngtypes*idum,'d')
         prpt_pt=allocate_memory2(ngtypes*idum,'d',fnm,snm,'prpt_pt')
         prwt_pt=allocate_memory2(ngtypes*idum,'d',fnm,snm,'prwt_pt')

      endif
C *
C * Set 2 - Arrays used in numerical quadrature
C *
C * Pointer             Length                  Array
C * bfnval_pt           
C * bfngval_pt          

      if(kqua_sw) then

c
c largest size for batches of integration points
c
         mxp=200

         iscr = incr_memory(ltri,'d')
c        call aclear_dp(memory_fp(iscr),ltri,0.0d0)

         if( .not. rks_sw)then
            iscrb = incr_memory(ltri,'d')
c           call aclear_dp(memory_fp(iscrb),ltri,0.0d0)
         endif

         bfnuse_pt  = incr_memory(BL_basis_size(ao_tag),'i')
         bfnpnum_pt = incr_memory(BL_basis_size(ao_tag),'i')
         bfnpide_pt = incr_memory(90,'i')

C *
C * Set 3 - Expand basis set to basis function arrays
C *
C * Pointer                Length                        Array
C * nprm_pt
C * angm_pt
C * pstr_pt
C * alpa_pt
C * coco_pt
C *
c       write(6,*) 'maxi_basA:',maxi_basA
c       write(6,*) 'maxi_primA:',maxi_primA

c        nprm_pt=incr_memory(maxi_basA,'i')
c        angm_pt=incr_memory(maxi_basA,'i')
c        pstr_pt=incr_memory(maxi_basA,'i')
c        cent_pt=incr_memory(maxi_basA,'i')
c        alpa_pt=incr_memory(maxi_primA,'d')
c        coco_pt=incr_memory(maxi_primA,'d')

c       call expand_tobasisfns(memory_int(nprm_pt),
c    &                         memory_int(angm_pt),
c    &                         memory_int(pstr_pt),
c    &                         memory_int(cent_pt),
c    &                         memory_fp(alpa_pt),
c    &                         memory_fp(coco_pt))

        ra2_val_pt = incr_memory(mxp*natoms*2,'d')
        ra2_comp_pt = incr_memory(mxp*natoms*3,'d')
        rho_pt = incr_memory(mxp*2,'d')
        grho_pt = incr_memory(mxp*2*3,'d')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       0,                               ! no npert
     &       .false.,
     &       memory_fp(prpt_pt),
     &       memory_fp(prwt_pt),
     &       .true., .true., .false.,
     &       .false.,.false.,.false.,.false.,.false.,
     &       mxp,.false.,.true.,0.0d0,iout)

        call decr_memory(grho_pt,'d')
        call decr_memory(rho_pt,'d')
        call decr_memory(ra2_comp_pt,'d')
        call decr_memory(ra2_val_pt,'d')

c       call decr_memory(coco_pt,'d')
c       call decr_memory(alpa_pt,'d')
c       call decr_memory(cent_pt,'i')
c       call decr_memory(pstr_pt,'i')
c       call decr_memory(angm_pt,'i')
c       call decr_memory(nprm_pt,'i')

        call decr_memory(bfnpide_pt,'i')
        call decr_memory(bfnpnum_pt,'i')
        call decr_memory(bfnuse_pt,'i')
c
c print Vxc
c
cc         xc_tracep=tracep(adenm,memory_fp(iscr),totbfn(ao_tag))
cc         write(6,*)'Trace product XC energy',xc_tracep

c
c       sum in Vxc
c
c       call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
c       if(.not. rks_sw)then
c          call daxpy(ltri,1.0d0,memory_fp(iscrb),1,kmb,1)
c       endif

        if(.not. rks_sw)then
           call decr_memory(iscrb,'d')
        endif
        call decr_memory(iscr,'d')

      endif
C
C     Obtain the Kohn-Sham matrix by fitting using an 
c     auxiliary basis set
C
      if(kfit_sw) then
        iscr = incr_memory(ltri,'d')
c       call aclear_dp(memory_fp(iscr),ltri,0.0d0)
        xbfn_num   = BL_basis_size(kf_tag)*BL_basis_size(kf_tag)
        fitmat_pt  = incr_memory(xbfn_num,'d')
        ckfit_pt   = incr_memory(BL_basis_size(kf_tag),'d')
        indx_pt    = incr_memory(BL_basis_size(kf_tag),'i')
        bfnval_pt  = incr_memory(BL_basis_size(ao_tag),'d')
        abfnval_pt = incr_memory(BL_basis_size(kf_tag),'d')
c       call exfit(ao_tag,BL_num_types(ao_tag),
c    &             kf_tag,BL_basis_size(kf_tag),
c    &             memory_fp(apts_pt),
c    &             memory_fp(awts_pt),
c    &             memory_fp(prpt_pt),
c    &             memory_fp(prwt_pt),
c    &             memory_fp(fitmat_pt),
c    &             memory_fp(ckfit_pt),
c    &             memory_int(indx_pt),
c    &             memory_fp(bfnval_pt),
c    &             memory_fp(abfnval_pt),
c    &             adenm,bdenm,kma,kmb,
c    &             memory_int,memory_fp,extwr_sw)
        call decr_memory(abfnval_pt,'d')
        call decr_memory(bfnval_pt,'d')
        call decr_memory(indx_pt,'i')
        call decr_memory(ckfit_pt,'d')
        call decr_memory(fitmat_pt,'d')
c
c       print Vxc
c
c
c       sum in Vxc
c
c       do i = 1,ltri
c         kma(i) = kma(i) + memory_fp(iscr+i-1)
c       enddo
        call decr_memory(iscr,'d')
      endif


c      write(6,*) 'Fock mat'
c      call prtri(kma,BL_basis_size(ao_tag))

C *
C *Return to SCF code
c
      energy=J_energy+XC_energy

      call free_memory2(prwt_pt,'d',fnm,snm,'prwt_pt')
      call free_memory2(prpt_pt,'d',fnm,snm,'prpt_pt')
      call decr_memory(prwt_ct,'d')
      call decr_memory(prpt_ct,'d')
      call decr_memory(awts_pt,'d')
      call decr_memory(apts_pt,'d')
c
c output intermediate timings if requested
c
      CD_memreq_energy_mo = pop_memory_estimate(iestimate)

      end
c
c-----------------------------------------------------------------------
c
      integer function CD_memreq_energy(
     &     nvec,naocc,nbocc,
     &     memory_int,memory_fp,iout)

C **********************************************************************
C *Description:                                                        *
C *Form the Kohn-Sham matrix using a variety of methods.               *
C *                                                                    *
C * The switches for various methods                                   *
C * ---------------------------------                                  *
C *                                                                    *
C * Jfit_dun -        Fit the Coulomb potential using Dunlaps method   *
C * K_fit    -        Use linear least squares fit to form K matrix    *
C * K_quad   -        Use quadrature to form K matrix                  *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis_api)
INCLUDE(../m4/common/statis)

c for basis set max values
INCLUDE(common/dft_basis)
c
C In variables
c
      integer nvec,naocc,nbocc
      integer iout

INCLUDE(common/dft_api)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)

C *Scratch space and pointers
      integer memory_int(*)
      REAL memory_fp(*)
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,prpt_ct,prwt_ct
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer abfnval_pt,fitmat_pt,indx_pt,ckfit_pt
      integer bfnuse_pt,bfnpnum_pt,bfnpide_pt
      integer nprm_pt,angm_pt,pstr_pt,cent_pt,alpa_pt,coco_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
c     integer xc_ept_pt, xc_vpt_pt, xc_dvpt_pt
      integer rho_pt, grho_pt
      integer mxp
C *Out variables
      REAL energy
      REAL sma
      REAL dum
C *Local variables
      integer ao_tag,kf_tag,ao_bas,i,iscr,iscrb,ltri
      REAL xc_tracep
      integer xbfn_num
      integer idum,ig
      integer null
      integer iestimate

C *Functions
      integer null_memory
      integer incr_memory
      integer allocate_memory2
      logical opg_root
      REAL tracep      
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate

      character *8 fnm
      character *16 snm
      data fnm/"global.m"/
      data snm/"CD_memreq_energy"/
C *End declarations
C **********************************************************************
c
c hardwired in for now
      ao_tag=1
      kf_tag=2
      ig    =G_KS
      null  = null_memory()
      iestimate=push_memory_estimate()
c
      if(debug_sw) write(6,*) 'Entering CD_memreq_energy'
      if (kfit_sw.or.jfit_sw.or.mult_sw) then
         call caserr("CD_memreq_energy: cannot handle fitting yet")
      endif

      ao_bas=((BL_basis_size(ao_tag)+1)*BL_basis_size(ao_tag))/2
      ltri = ao_bas

C **********************************************************************
C *Form the J matrix
C *
c
c ps - kma gets cleared in here, although apparently
c      not explicitly - so the aclear is redundant
c

      if(jfit_sw) then
         kf_tag = 3
         iscr = incr_memory(ltri,'d')
c        call aclear_dp(memory_fp(iscr),ltri,0.0d0)
         if( .not. rks_sw)then
            iscrb = incr_memory(ltri,'d')
c           call aclear_dp(memory_fp(iscrb),ltri,0.0d0)
         endif
         call memreq_Jfit_dunlap(memory_fp,memory_int,dum,dum,dum,dum)
c
c sum in Vcoul
c
         if (.not.rks_sw) then
c           call daxpy(ltri,1.0d0,memory_fp(iscrb),1,kmb,1)
            call decr_memory(iscrb,'d')
         endif
c        call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
         call decr_memory(iscr,'d')

      elseif(mult_sw) then
         iscr = incr_memory(ltri,'d')
c        call aclear_dp(memory_fp(iscr),ltri,0.0d0)
         write(6,*) 'Off to JDriver'
c        call JDriver(ao_tag,adenm,bdenm,memory_fp(iscr),kmb)
c        J_energy=tracep(adenm,memory_fp(iscr),BL_basis_size(ao_tag))
c        J_energy=J_energy*0.5d0
         write(6,*) 'J_energy:',J_energy
c
c sum in Vcoul
c
c        call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
         call decr_memory(iscr,'d')

      endif
c
c add timings for gamess analysis
c
      if(jfit_sw.or.mult_sw) then
         call timana(4)
         call cpuwal(begin,ebegin)
      endif

C * 
C *Form the K matrix
C *
      if(kqua_sw.or.kfit_sw) then
C *
C *Allocate memory into needed blocks
C *
C * Set 1 - Arrays used in grid generation
C *
C * Pointer             Length                  Array
C * apts_pt             3*max(angupt_num)       apts
C * awts_pt             max(angupt_num)         awts
C * prpt_pt             max(radpt_num)          prpt
C * prwt_pt             max(radpt_num)          prwt
C *
         idum   =max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
         apts_pt=incr_memory(3*idum,'d')
         awts_pt=incr_memory(idum,'d')
         idum   =max_array(radpt_num(1,ig),ngtypes)
         prpt_ct=incr_memory(ngtypes*idum,'d')
         prwt_ct=incr_memory(ngtypes*idum,'d')
         prpt_pt=allocate_memory2(ngtypes*idum,'d',fnm,snm,'prpt_pt')
         prwt_pt=allocate_memory2(ngtypes*idum,'d',fnm,snm,'prwt_pt')

      endif
C *
C * Set 2 - Arrays used in numerical quadrature
C *
C * Pointer             Length                  Array
C * bfnval_pt           
C * bfngval_pt          

      if(kqua_sw) then

c
c largest size for batches of integration points
c
         mxp=200

         iscr = incr_memory(ltri,'d')
c        call aclear_dp(memory_fp(iscr),ltri,0.0d0)

         if( .not. rks_sw)then
            iscrb = incr_memory(ltri,'d')
c           call aclear_dp(memory_fp(iscrb),ltri,0.0d0)
         endif

         bfnuse_pt  = incr_memory(BL_basis_size(ao_tag),'i')
         bfnpnum_pt = incr_memory(BL_basis_size(ao_tag),'i')
         bfnpide_pt = incr_memory(90,'i')

C *
C * Set 3 - Expand basis set to basis function arrays
C *
C * Pointer                Length                        Array
C * nprm_pt
C * angm_pt
C * pstr_pt
C * alpa_pt
C * coco_pt
C *
c       write(6,*) 'maxi_basA:',maxi_basA
c       write(6,*) 'maxi_primA:',maxi_primA

c        nprm_pt=incr_memory(maxi_basA,'i')
c        angm_pt=incr_memory(maxi_basA,'i')
c        pstr_pt=incr_memory(maxi_basA,'i')
c        cent_pt=incr_memory(maxi_basA,'i')
c        alpa_pt=incr_memory(maxi_primA,'d')
c        coco_pt=incr_memory(maxi_primA,'d')

c       call expand_tobasisfns(memory_int(nprm_pt),
c    &                         memory_int(angm_pt),
c    &                         memory_int(pstr_pt),
c    &                         memory_int(cent_pt),
c    &                         memory_fp(alpa_pt),
c    &                         memory_fp(coco_pt))

        ra2_val_pt = incr_memory(mxp*natoms*2,'d')
        ra2_comp_pt = incr_memory(mxp*natoms*3,'d')
        rho_pt = incr_memory(mxp*2,'d')
        grho_pt = incr_memory(mxp*2*3,'d')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       0,                               ! no npert
     &       .false.,
     &       memory_fp(prpt_pt),
     &       memory_fp(prwt_pt),
     &       .true., .true., .false.,
     &       .false.,.false.,.false.,.false.,.false.,
     &       mxp,.true.,.true.,0.0d0,iout)

        call decr_memory(grho_pt,'d')
        call decr_memory(rho_pt,'d')
        call decr_memory(ra2_comp_pt,'d')
        call decr_memory(ra2_val_pt,'d')

c       call decr_memory(coco_pt,'d')
c       call decr_memory(alpa_pt,'d')
c       call decr_memory(cent_pt,'i')
c       call decr_memory(pstr_pt,'i')
c       call decr_memory(angm_pt,'i')
c       call decr_memory(nprm_pt,'i')

        call decr_memory(bfnpide_pt,'i')
        call decr_memory(bfnpnum_pt,'i')
        call decr_memory(bfnuse_pt,'i')
c
c print Vxc
c
cc         xc_tracep=tracep(adenm,memory_fp(iscr),totbfn(ao_tag))
cc         write(6,*)'Trace product XC energy',xc_tracep

c
c       sum in Vxc
c
        if(.not. rks_sw)then
           call decr_memory(iscrb,'d')
        endif
        call decr_memory(iscr,'d')

      endif
C
C     Obtain the Kohn-Sham matrix by fitting using an 
c     auxiliary basis set
C
      if(kfit_sw) then
        iscr = incr_memory(ltri,'d')
        call aclear_dp(memory_fp(iscr),ltri,0.0d0)
        xbfn_num   = BL_basis_size(kf_tag)*BL_basis_size(kf_tag)
        fitmat_pt  = incr_memory(xbfn_num,'d')
        ckfit_pt   = incr_memory(BL_basis_size(kf_tag),'d')
        indx_pt    = incr_memory(BL_basis_size(kf_tag),'i')
        bfnval_pt  = incr_memory(BL_basis_size(ao_tag),'d')
        abfnval_pt = incr_memory(BL_basis_size(kf_tag),'d')
c       call exfit(ao_tag,BL_num_types(ao_tag),
c    &             kf_tag,BL_basis_size(kf_tag),
c    &             memory_fp(apts_pt),
c    &             memory_fp(awts_pt),
c    &             memory_fp(prpt_pt),
c    &             memory_fp(prwt_pt),
c    &             memory_fp(fitmat_pt),
c    &             memory_fp(ckfit_pt),
c    &             memory_int(indx_pt),
c    &             memory_fp(bfnval_pt),
c    &             memory_fp(abfnval_pt),
c    &             adenm,bdenm,kma,kmb,
c    &             memory_int,memory_fp,extwr_sw)
        call decr_memory(abfnval_pt,'d')
        call decr_memory(bfnval_pt,'d')
        call decr_memory(indx_pt,'i')
        call decr_memory(ckfit_pt,'d')
        call decr_memory(fitmat_pt,'d')
c
c       print Vxc
c
c
c       sum in Vxc
c
        call decr_memory(iscr,'d')
      endif


c      write(6,*) 'Fock mat'
c      call prtri(kma,BL_basis_size(ao_tag))

C *
C *Return to SCF code
c
c     energy=J_energy+XC_energy

      call free_memory2(prwt_pt,'d',fnm,snm,'prwt_pt')
      call free_memory2(prpt_pt,'d',fnm,snm,'prpt_pt')
      call decr_memory(prwt_ct,'d')
      call decr_memory(prpt_ct,'d')
      call decr_memory(awts_pt,'d')
      call decr_memory(apts_pt,'d')
c
c output intermediate timings if requested
c
c
c     exit code if requested
c
      CD_memreq_energy = pop_memory_estimate(iestimate)

      end

C **********************************************************************
c
c   integer function CD_memreq_forces_ao - Driver for Force evaluation
c
c    Arguments:
c
c     coords,        I   current coordinates
c     adenm,         I   alpha or total density 
c     bdenm,         I   beta density, not used.
c     memory_int,    S   base for dynamic memory allocation (integer)
c     memory_fp,     S   base for dynamic memory allocation (real*8)
c     grad,         I/O  gradient 
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_memreq_forces_ao(coords,adenm,bdenm,
     &     memory_int,memory_fp,grad,extwr_sw,iout)
      implicit none

C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters) 
C *In variables
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
      REAL coords(3,*)
      REAL adenm(*),bdenm(*)
      integer memory_int(*)
      REAL memory_fp(*)
      logical extwr_sw
      integer iout
C *Out variables
      REAL grad(3,*)      
C *Local variables
      integer prpt_ct,prwt_ct
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
c     integer bfnuse_pt
      integer ao_tag
      integer ra2_val_pt, ra2_comp_pt, wt_pt
c     integer xc_ept_pt, xc_vpt_pt, xc_dvpt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum,ig
      integer null
      REAL dummy
      integer iestimate

C *Functions
      integer null_memory
      integer incr_memory
      integer allocate_memory2
      logical opg_root
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate

      character *8 fnm
      character *19 snm
      data fnm/"global.m"/
      data snm/"CD_memreq_forces_ao"/
C *End declarations
      iestimate = push_memory_estimate()
c
C    ===== Store current coordinates ====
c
c     idum = CD_update_geom(coords)
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      ig    =G_KS
      ao_tag=1

      if(jfitg_sw) then 
         call memreq_Jfitg(memory_fp,memory_int)
      endif

C *
C *Form the gradients due to the exchange-correlation part
C *
      if(kqua_sw) then
c
c length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = incr_memory(3*idum,'d')
        awts_pt = incr_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_ct = incr_memory(ngtypes*idum,'d')
        prwt_ct = incr_memory(ngtypes*idum,'d') 
        prpt_pt = allocate_memory2(ngtypes*idum,'d',fnm,snm,'prpt_pt')
        prwt_pt = allocate_memory2(ngtypes*idum,'d',fnm,snm,'prwt_pt') 

        ra2_val_pt = incr_memory(mxp*natoms*2,'d')
        ra2_comp_pt = incr_memory(mxp*natoms*3,'d')
        rho_pt = incr_memory(mxp*2,'d')
        grho_pt = incr_memory(mxp*2*3,'d')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       0,                               ! no npert
     &       .false.,
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       .false., .false., .true.,
     &       .false.,.false.,.false.,.false.,.false.,
     &       mxp,.true.,.false.,0.0d0,iout)

        call decr_memory(grho_pt,'d')
        call decr_memory(rho_pt,'d')
        call decr_memory(ra2_comp_pt,'d')
        call decr_memory(ra2_val_pt,'d')
        call free_memory2(prwt_pt,'d',fnm,snm,'prwt_pt')
        call free_memory2(prpt_pt,'d',fnm,snm,'prpt_pt')
        call decr_memory(prwt_ct,'d')
        call decr_memory(prpt_ct,'d')
        call decr_memory(awts_pt,'d')
        call decr_memory(apts_pt,'d')
      endif

      cd_memreq_forces_ao = pop_memory_estimate(iestimate)

      return
      end

C **********************************************************************
c
c   integer function CD_memreq_chf_rhs_mo - Driver for evaluation of the
c                                    CHF right-hand-sides
c
c    Arguments:
c
c     memory_int     S   base for dynamic memory allocation (integer)
c     memory_fp      S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     chf_pert_atms  I   for each perturbation the associated atom
c     nvec           I   number of vectors
c     naocc          I   number of occupied alpha vectors
c     nbocc          I   number of occupied beta  vectors
c     avec           I   alpha vectors
c     bvec           I   beta  vectors
c     sa_mo          I   derivative alpha overlap matrices
c     sb_mo          I   derivative beta  overlap matrices
c     ba_mo         I/O  alpha rhs matrices
c     bb_mo         I/O  beta  rhs matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_memreq_chf_rhs_mo(memory_int,memory_fp,npert,
     &     chf_pert_atms,nvec,naocc,nbocc,avec,bvec,sa_mo,sb_mo,
     &     ba_mo,bb_mo,extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter(ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter(ig=G_CPKS)
      integer npert
      integer chf_pert_atms(npert)
      integer nvec, naocc, nbocc
c     REAL avec(totbfn(ao_tag),nvec)
c     REAL bvec(totbfn(ao_tag),nvec)
      REAL avec(*)
      REAL bvec(*)
      REAL sa_mo(nvec*(nvec+1)/2,npert)
      REAL sb_mo(nvec*(nvec+1)/2,npert)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL ba_mo(naocc,nvec-naocc,npert)
      REAL bb_mo(nbocc,nvec-naocc,npert)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, nao
      integer null
      integer iestimate, prpt_ct, prwt_ct
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer incr_memory
      integer allocate_memory2
      logical opg_root
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate
c
      character*8 fnm
      character*20 snm
      data fnm,snm/'global.m','CD_memreq_chf_rhs_mo'/
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      null = null_memory()
      iestimate = push_memory_estimate()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = incr_memory(3*idum,'d')
        awts_pt = incr_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_ct = incr_memory(ngtypes*idum,'d')
        prwt_ct = incr_memory(ngtypes*idum,'d') 
        prpt_pt = allocate_memory2(ngtypes*idum,'d',fnm,snm,'prpt_pt')
        prwt_pt = allocate_memory2(ngtypes*idum,'d',fnm,snm,'prwt_pt') 

        ra2_val_pt = incr_memory(mxp*natoms*2,'d')
        ra2_comp_pt = incr_memory(mxp*natoms*3,'d')
        rho_pt = incr_memory(mxp*2,'d')
        grho_pt = incr_memory(mxp*2*3,'d')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       npert,
     &       .true.,
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       .false., .false., .false.,
     &       .false.,.true.,.false.,.false.,.false.,
     &       mxp,.false.,.true.,0.0d0,iout)

        call decr_memory(grho_pt,'d')
        call decr_memory(rho_pt,'d')
        call decr_memory(ra2_comp_pt,'d')
        call decr_memory(ra2_val_pt,'d')
        call decr_memory(prwt_ct,'d')
        call decr_memory(prpt_ct,'d')
        call free_memory2(prwt_pt,'d',fnm,snm,'prwt_pt')
        call free_memory2(prpt_pt,'d',fnm,snm,'prpt_pt')
        call decr_memory(awts_pt,'d')
        call decr_memory(apts_pt,'d')
      endif

      cd_memreq_chf_rhs_mo = pop_memory_estimate(iestimate)

      return
      end

C **********************************************************************
c
c   integer function CD_memreq_chf_lhs_mo - Driver for evaluation of the
c                                    CHF left-hand-sides
c
c    Arguments:
c
c     memory_int     S   base for dynamic memory allocation (integer)
c     memory_fp      S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     chf_pert_atms  I   for each perturbation the associated atom
c     geometric_sw   I   true if considering geometric perturbations
c     nvec           I   number of vectors
c     naocc          I   number of occupied alpha vectors
c     nbocc          I   number of occupied beta  vectors
c     avec           I   alpha vectors
c     bvec           I   beta  vectors
c     ua_mo          I   derivative alpha density matrices
c     ub_mo          I   derivative beta  density matrices
c     ga_mo         I/O  alpha lhs matrices
c     gb_mo         I/O  beta  lhs matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_memreq_chf_lhs_mo(memory_int,memory_fp,npert,
     &     chf_pert_atms,geometric_sw,nvec,naocc,nbocc,avec,bvec,
     &     ua_mo,ub_mo,ga_mo,gb_mo,extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_CPKS)
      integer npert
      integer chf_pert_atms(npert)
      logical geometric_sw
      integer nvec, naocc, nbocc
c     REAL avec(totbfn(ao_tag),nvec)
c     REAL bvec(totbfn(ao_tag),nvec)
      REAL avec(*)
      REAL bvec(*)
      REAL ua_mo(naocc,nvec-naocc,npert)
      REAL ub_mo(nbocc,nvec-nbocc,npert)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL ga_mo(naocc,nvec-naocc,npert)
      REAL gb_mo(nbocc,nvec-nbocc,npert)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum
      integer null, nao
      integer prpt_ct,prwt_ct,iestimate
c
c     Functions:
c
      integer null_memory
      integer incr_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      null = null_memory()
      iestimate = push_memory_estimate()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = incr_memory(3*idum,'d')
        awts_pt = incr_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_ct = incr_memory(ngtypes*idum,'d')
        prwt_ct = incr_memory(ngtypes*idum,'d') 
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = incr_memory(mxp*natoms*2,'d')
        ra2_comp_pt = incr_memory(mxp*natoms*3,'d')
        rho_pt = incr_memory(mxp*2,'d')
        grho_pt = incr_memory(mxp*2*3,'d')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       npert,
     &       geometric_sw,
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       .false., .false., .false.,
     &       .false.,.false.,.true.,.false.,.false.,
     &       mxp,.false.,.true.,0.0d0,iout)

        call decr_memory(grho_pt,'d')
        call decr_memory(rho_pt,'d')
        call decr_memory(ra2_comp_pt,'d')
        call decr_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call decr_memory(prwt_ct,'d')
        call decr_memory(prpt_ct,'d')
        call decr_memory(awts_pt,'d')
        call decr_memory(apts_pt,'d')
      endif

      cd_memreq_chf_lhs_mo = pop_memory_estimate(iestimate)

      return
      end

C **********************************************************************
c
c   integer function CD_memreq_chf_dksm_mo - Driver for evaluation of the
c                                     perturbed Kohn-Sham matrices 
c
c    Arguments:
c
c     memory_int     S   base for dynamic memory allocation (integer)
c     memory_fp      S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     chf_pert_atms  I   for each perturbation the associated atom
c     nvec           I   number of vectors
c     naocc          I   number of occupied alpha vectors
c     nbocc          I   number of occupied beta  vectors
c     avec           I   alpha vectors
c     bvec           I   beta  vectors
c     da_mo          I   perturbed alpha density
c     db_mo          I   perturbed beta  density
c     fa_mo         I/O  alpha perturbed Kohn-Sham matrices
c     fb_mo         I/O  beta  perturbed Kohn-Sham matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_memreq_chf_dksm_mo(memory_int,memory_fp,npert,
     &     chf_pert_atms,nvec,naocc,nbocc,avec,bvec,da_mo,db_mo,
     &     fa_mo,fb_mo,extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_CPKS)
      integer npert
      integer chf_pert_atms(npert)
      integer nvec, naocc, nbocc
c     REAL avec(totbfn(ao_tag),nvec)
c     REAL bvec(totbfn(ao_tag),nvec)
      REAL avec(*)
      REAL bvec(*)
      REAL da_mo(nvec*(nvec+1)/2,npert)
      REAL db_mo(nvec*(nvec+1)/2,npert)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL fa_mo(nvec*(nvec+1)/2,npert)
      REAL fb_mo(nvec*(nvec+1)/2,npert)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, nao
      integer null
      integer iestimate, prpt_ct, prwt_ct
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer incr_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      null = null_memory()
      iestimate = push_memory_estimate()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = incr_memory(3*idum,'d')
        awts_pt = incr_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_ct = incr_memory(ngtypes*idum,'d')
        prwt_ct = incr_memory(ngtypes*idum,'d') 
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = incr_memory(mxp*natoms*2,'d')
        ra2_comp_pt = incr_memory(mxp*natoms*3,'d')
        rho_pt = incr_memory(mxp*2,'d')
        grho_pt = incr_memory(mxp*2*3,'d')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       npert,
     &       .true.,
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       .false., .false., .false.,
     &       .false.,.false.,.false.,.true.,.false.,
     &       mxp,.false.,.true.,0.0d0,iout)

        call decr_memory(grho_pt,'d')
        call decr_memory(rho_pt,'d')
        call decr_memory(ra2_comp_pt,'d')
        call decr_memory(ra2_val_pt,'d')
        call decr_memory(prwt_ct,'d')
        call decr_memory(prpt_ct,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call decr_memory(awts_pt,'d')
        call decr_memory(apts_pt,'d')
      endif

      cd_memreq_chf_dksm_mo = pop_memory_estimate(iestimate)

      return
      end

C **********************************************************************
c
c   integer function CD_memreq_dksm_exp_ao - Driver for evaluation of the
c                                     explicit derivatives of the 
c                                     Kohn-Sham matrix with respect
c                                     to the nuclear coordinates.
c
c    Arguments:
c
c     memory_int,    S   base for dynamic memory allocation (integer)
c     memory_fp,     S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     adenm,         I   alpha density or total density 
c     bdenm,         I   beta  density or not used
c     fxa_ao        I/O  alpha explicit derivative Kohn-Sham matrices
c     fxb_ao        I/O  beta  explicit derivative Kohn-Sham matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_memreq_dksm_exp_ao(memory_int,memory_fp,npert,
     &     adenm,bdenm,fxa_ao,fxb_ao,
     &     extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
c     parameter (ig=G_CPKS)
c     Looks like we have to do the explicit derivatives of the
c     KS-matrix more accurate. If we don't we have trouble with
c     ScF3 (par_10). Eg.
c
c     ig=G_CPKS            ig=G_KS              force
c     freq    intensity    freq    intensity    freq
c      36.26  117.85701     36.97  116.41320     37.4119
c     139.43   13.17162    140.48   13.09114    140.6961
c     149.38   14.59725    149.05   14.41116    145.9012
c     567.20     .12104    578.89     .13537    578.7009
c     661.31  252.38760    675.71  258.97621    675.2153
c     665.91  253.48479    679.89  260.19754    678.9972
c
      parameter (ig=G_KS)
c
      integer npert
c     REAL adenm(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2)
c     REAL bdenm(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2)
      REAL adenm(*)
      REAL bdenm(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
c     REAL fxa_ao(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2,npert)
c     REAL fxb_ao(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2,npert)
      REAL fxa_ao(*)
      REAL fxb_ao(*)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, nao
      integer null
      integer iestimate, prpt_ct, prwt_ct
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer incr_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      iestimate = push_memory_estimate()
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = incr_memory(3*idum,'d')
        awts_pt = incr_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_ct = incr_memory(ngtypes*idum,'d')
        prwt_ct = incr_memory(ngtypes*idum,'d') 
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = incr_memory(mxp*natoms*2,'d')
        ra2_comp_pt = incr_memory(mxp*natoms*3,'d')
        rho_pt = incr_memory(mxp*2,'d')
        grho_pt = incr_memory(mxp*2*3,'d')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       npert,
     &       .true.,
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
c    &       .false., .false., .false.,
cDEBUG
     &       .true., .false., .false.,
cDEBUG
     &       .true.,.false.,.false.,.false.,.false.,
     &       mxp,.true.,.false.,0.0d0,iout)

        call decr_memory(grho_pt,'d')
        call decr_memory(rho_pt,'d')
        call decr_memory(ra2_comp_pt,'d')
        call decr_memory(ra2_val_pt,'d')
        call decr_memory(prwt_ct,'d')
        call decr_memory(prpt_ct,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call decr_memory(awts_pt,'d')
        call decr_memory(apts_pt,'d')
      endif

      cd_memreq_dksm_exp_ao = pop_memory_estimate(iestimate)

      return
      end
C **********************************************************************
c
c   integer function CD_memreq_dksm_exp_mo - Driver for evaluation of 
c                                     the explicit derivatives of the 
c                                     Kohn-Sham matrix with respect
c                                     to the nuclear coordinates.
c
c    Arguments:
c
c     memory_int,    S   base for dynamic memory allocation (integer)
c     memory_fp,     S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     adenm,         I   alpha density or total density 
c     bdenm,         I   beta  density or not used
c     fxa_mo        I/O  alpha explicit derivative Kohn-Sham matrices
c     fxb_mo        I/O  beta  explicit derivative Kohn-Sham matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_memreq_dksm_exp_mo(memory_int,memory_fp,npert,
     &     nvec,naocc,nbocc,avec,bvec,fxa_mo,fxb_mo,
     &     extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_CPKS)
      integer nvec, naocc, nbocc
      integer npert
c     REAL avec(totbfn(ao_tag),nvec)
c     REAL bvec(totbfn(ao_tag),nvec)
      REAL avec(*)
      REAL bvec(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL fxa_mo(nvec*(nvec+1)/2,npert)
      REAL fxb_mo(nvec*(nvec+1)/2,npert)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, nao
      integer null
      integer iestimate, prpt_ct, prwt_ct
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer incr_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      iestimate = push_memory_estimate()
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = incr_memory(3*idum,'d')
        awts_pt = incr_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_ct = incr_memory(ngtypes*idum,'d')
        prwt_ct = incr_memory(ngtypes*idum,'d') 
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = incr_memory(mxp*natoms*2,'d')
        ra2_comp_pt = incr_memory(mxp*natoms*3,'d')
        rho_pt = incr_memory(mxp*2,'d')
        grho_pt = incr_memory(mxp*2*3,'d')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       npert,
     &       .true.,
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
c    &       .false., .false., .false.,
cDEBUG
     &       .true., .false., .false.,
cDEBUG
     &       .true.,.false.,.false.,.false.,.false.,
     &       mxp,.false.,.true.,0.0d0,iout)

        call decr_memory(grho_pt,'d')
        call decr_memory(rho_pt,'d')
        call decr_memory(ra2_comp_pt,'d')
        call decr_memory(ra2_val_pt,'d')
        call decr_memory(prwt_ct,'d')
        call decr_memory(prpt_ct,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call decr_memory(awts_pt,'d')
        call decr_memory(apts_pt,'d')
      endif

      cd_memreq_dksm_exp_mo = pop_memory_estimate(iestimate)

      return
      end
C **********************************************************************
c
c   integer function CD_memreq_hess_ao - Driver for evaluation of the
c                                 explicit 2nd derivative of the 
c                                 exchange-correlation energy with 
c                                 respect to the nuclear coordinates.
c
c    Arguments:
c
c     memory_int,    S   base for dynamic memory allocation (integer)
c     memory_fp,     S   base for dynamic memory allocation (real*8)
c     adenm,         I   alpha density or total density 
c     bdenm,         I   beta  density or not used
c     hess          I/O  hessian matrix
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_memreq_hess_ao(memory_int,memory_fp,
     &     adenm,bdenm,hess,
     &     extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_KS)
c     REAL adenm(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2)
c     REAL bdenm(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2)
      REAL adenm(*)
      REAL bdenm(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL hess(3*natoms,3*natoms)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, npert, nao
      integer null
      integer iestimate, prpt_ct, prwt_ct
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer incr_memory2
      integer allocate_memory2
      logical opg_root
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate
c
c     Code:
c
      iestimate = push_memory_estimate()
      nao = BL_basis_size(ao_tag)
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        npert=3*natoms
        mxp=200

        idum       = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt    = incr_memory2(3*idum,'d','global.m',
     &                                'CD_hess_ao','apts')
        awts_pt    = incr_memory2(idum,'d','global.m','CD_hess_ao',
     &                               'awts')
        idum       = max_array(radpt_num(1,ig),ngtypes)
        prpt_ct    = incr_memory2(ngtypes*idum,'d','global.m',
     &                                'CD_hess_ao','prpt')
        prwt_ct    = incr_memory2(ngtypes*idum,'d','global.m',
     &                                'CD_hess_ao','prwt') 
        prpt_pt    = allocate_memory2(ngtypes*idum,'d','global.m',
     &                                'CD_hess_ao','prpt')
        prwt_pt    = allocate_memory2(ngtypes*idum,'d','global.m',
     &                                'CD_hess_ao','prwt') 

        ra2_val_pt  = incr_memory2(mxp*natoms*2,'d','global.m',
     &                                 'CD_hess_ao','ra2_val')
        ra2_comp_pt = incr_memory2(mxp*natoms*3,'d','global.m',
     &                                 'CD_hess_ao','ra2_comp')
        rho_pt  = incr_memory2(mxp*2,'d','global.m','CD_hess_ao',
     &                             'rho')
        grho_pt = incr_memory2(mxp*2*3,'d','global.m','CD_hess_ao',
     &                             'grho')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       npert,                           ! no perturbations
     &       .true.,
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       .false., .false., .false.,
     &       .false.,.false.,.false.,.false.,.true.,
     &       mxp,.true.,.false.,0.0d0,iout)

        call decr_memory2(grho_pt,'d','global.m','CD_hess_ao','grho')
        call decr_memory2(rho_pt,'d','global.m','CD_hess_ao','rho')
        call decr_memory2(ra2_comp_pt,'d','global.m','CD_hess_ao',
     &                    'ra2_comp')
        call decr_memory2(ra2_val_pt,'d','global.m','CD_hess_ao',
     &                    'ra2_val')
        call decr_memory2(prwt_ct,'d','global.m','CD_hess_ao','prwt')
        call decr_memory2(prpt_ct,'d','global.m','CD_hess_ao','prpt')
        call free_memory2(prwt_pt,'d','global.m','CD_hess_ao','prwt')
        call free_memory2(prpt_pt,'d','global.m','CD_hess_ao','prpt')
        call decr_memory2(awts_pt,'d','global.m','CD_hess_ao','awts')
        call decr_memory2(apts_pt,'d','global.m','CD_hess_ao','apts')
      endif

      cd_memreq_hess_ao = pop_memory_estimate(iestimate)

      return
      end
C **********************************************************************
c
c   integer function CD_memreq_hess_mo - Driver for evaluation of the
c                                 explicit 2nd derivative of the 
c                                 exchange-correlation energy with 
c                                 respect to the nuclear coordinates.
c
c    Arguments:
c
c     memory_int,    S   base for dynamic memory allocation (integer)
c     memory_fp,     S   base for dynamic memory allocation (real*8)
c     adenm,         I   alpha density or total density 
c     bdenm,         I   beta  density or not used
c     hess          I/O  hessian matrix
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_memreq_hess_mo(memory_int,memory_fp,
     &     nvec,naocc,nbocc,avec,bvec,hess,
     &     extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_KS)
      integer nvec,naocc,nbocc
c     REAL avec(totbfn(ao_tag),nvec)
c     REAL bvec(totbfn(ao_tag),nvec)
      REAL avec(*)
      REAL bvec(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL hess(3*natoms,3*natoms)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, npert, nao
      integer null
      integer iestimate, prpt_ct, prwt_ct
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer incr_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
      integer push_memory_estimate, pop_memory_estimate
c
c     Code:
c
      iestimate = push_memory_estimate()
      nao = BL_basis_size(ao_tag)
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        npert=3*natoms
        mxp=200

        idum       = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt    = incr_memory(3*idum,'d')
        awts_pt    = incr_memory(idum,'d')
        idum       = max_array(radpt_num(1,ig),ngtypes)
        prpt_ct    = incr_memory(ngtypes*idum,'d')
        prwt_ct    = incr_memory(ngtypes*idum,'d') 
        prpt_pt    = allocate_memory(ngtypes*idum,'d')
        prwt_pt    = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = incr_memory(mxp*natoms*2,'d')
        ra2_comp_pt = incr_memory(mxp*natoms*3,'d')
        rho_pt = incr_memory(mxp*2,'d')
        grho_pt = incr_memory(mxp*2*3,'d')

        call memreq_exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       npert,                           ! no perturbations
     &       .true.,
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       .false., .false., .false.,
     &       .false.,.false.,.false.,.false.,.true.,
     &       mxp,.false.,.true.,0.0d0,iout)

        call decr_memory(grho_pt,'d')
        call decr_memory(rho_pt,'d')
        call decr_memory(ra2_comp_pt,'d')
        call decr_memory(ra2_val_pt,'d')
        call decr_memory(prwt_ct,'d')
        call decr_memory(prpt_ct,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call decr_memory(awts_pt,'d')
        call decr_memory(apts_pt,'d')
      endif

      cd_memreq_hess_mo = pop_memory_estimate(iestimate)

      return
      end
c---- the routines that do the real work -------------------------------
      integer function CD_energy_ao(
     &     coords,
     &     kma,kmb,adenm,bdenm,energy,
     &     memory_int,memory_fp,extwr_sw,accuracy, iout
_IF(debug_S)
     &     ,sma
_ENDIF
     &     )

C **********************************************************************
C *Description:                                                        *
C *Form the Kohn-Sham matrix using a variety of methods.               *
C *                                                                    *
C * The switches for various methods                                   *
C * ---------------------------------                                  *
C *                                                                    *
C * Jfit_dun -        Fit the Coulomb potential using Dunlaps method   *
C * K_fit    -        Use linear least squares fit to form K matrix    *
C * K_quad   -        Use quadrature to form K matrix                  *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis_api)
INCLUDE(../m4/common/statis)

c for basis set max values
INCLUDE(common/dft_basis)
c
C In variables
c
      REAL coords(3,*), accuracy
      REAL kma(*),kmb(*),adenm(*),bdenm(*)
      logical extwr_sw
      integer iout

INCLUDE(common/dft_api)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)

C *Scratch space and pointers
      integer memory_int(*)
      REAL memory_fp(*)
      integer apts_pt,awts_pt,prpt_pt,prwt_pt
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer abfnval_pt,fitmat_pt,indx_pt,ckfit_pt
      integer bfnuse_pt,bfnpnum_pt,bfnpide_pt
      integer nprm_pt,angm_pt,pstr_pt,cent_pt,alpa_pt,coco_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
c     integer xc_ept_pt, xc_vpt_pt, xc_dvpt_pt
      integer rho_pt, grho_pt
      integer mxp
C *Out variables
      REAL energy
      REAL sma
C *Local variables
      integer ao_tag,kf_tag,ao_bas,i,iscr,iscrb,ltri
      REAL xc_tracep
      integer xbfn_num
      integer idum
      integer null
      integer imemcount, imemusage, imemestimate
      logical omemok
      save omemok

C *Functions
      integer null_memory
      integer allocate_memory2
      integer push_memory_count,    pop_memory_count
c     integer push_memory_estimate, pop_memory_estimate
      logical opg_root
      REAL tracep      
      integer cd_update_geom
      integer cd_memreq_energy_ao
      integer max_array
      integer ig
c
      character *8 fnm
      character *12 snm
      data fnm/"global.m"/
      data snm/"CD_energy_ao"/
      data omemok/.false./

C *End declarations
C **********************************************************************
c
c hardwired in for now
      ao_tag=1
      kf_tag=2
      ig    =G_KS
      null  = null_memory()
c
c     create a memory usage counter for check at the end
c
_IF(debug)
      omemok = .false.
_ENDIF
      if (.not.omemok) then
         imemestimate = CD_memreq_energy_ao(memory_fp,memory_int,iout)
         imemcount = push_memory_count()
      endif
c
      if(debug_sw) write(6,*) 'Entering CD_energy_ao'
      ao_bas=((BL_basis_size(ao_tag)+1)*BL_basis_size(ao_tag))/2
      ltri = ao_bas

      if(opg_root() .and. print_sw(DEBUG_DENSITY))then
         write(6,*)'** Input Density **'
         call prtri(adenm,BL_basis_size(ao_tag))
      endif

C **********************************************************************
C *Form the J matrix
C *
c
c ps - kma gets cleared in here, although apparently
c      not explicitly - so the aclear is redundant
c

      if(jfit_sw) then
         kf_tag = 3
         iscr = allocate_memory2(ltri,'d',fnm,snm,'iscr')
         call aclear_dp(memory_fp(iscr),ltri,0.0d0)
         if( .not. rks_sw)then
            iscrb = allocate_memory2(ltri,'d',fnm,snm,'iscrb')
            call aclear_dp(memory_fp(iscrb),ltri,0.0d0)
         endif
         call Jfit_dunlap(memory_fp,memory_int,
     &        memory_fp(iscr),memory_fp(iscrb),
     &        adenm,bdenm,iout)

         if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
           write(6,*)'** Vcoul **'
           call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
         endif
c
c sum in Vcoul
c
         if (.not.rks_sw) then
            call daxpy(ltri,1.0d0,memory_fp(iscrb),1,kmb,1)
            call free_memory2(iscrb,'d',fnm,snm,'iscrb')
         endif
         call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
         call free_memory2(iscr,'d',fnm,snm,'iscr')

      elseif(mult_sw) then
         iscr = allocate_memory2(ltri,'d',fnm,snm,'iscr')
         call aclear_dp(memory_fp(iscr),ltri,0.0d0)
         write(6,*) 'Off to JDriver'
         call JDriver(ao_tag,adenm,bdenm,memory_fp(iscr),kmb)
         J_energy=tracep(adenm,memory_fp(iscr),BL_basis_size(ao_tag))
         J_energy=J_energy*0.5d0
         if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
            write(6,*)'** Vcoul **'
            call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
         endif
         write(6,*) 'J_energy:',J_energy
c
c sum in Vcoul
c
         call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
         call free_memory2(iscr,'d',fnm,snm,'iscr')

      endif
c
c add timings for gamess analysis
c
      if(jfit_sw.or.mult_sw) then
         call timana(4)
         call cpuwal(begin,ebegin)
      endif

C * 
C *Form the K matrix
C *
      if(kqua_sw.or.kfit_sw) then
C *
C *Allocate memory into needed blocks
C *
C * Set 1 - Arrays used in grid generation
C *
C * Pointer             Length                  Array
C * apts_pt             3*max(angupt_num)       apts
C * awts_pt             max(angupt_num)         awts
C * prpt_pt             max(radpt_num)          prpt
C * prwt_pt             max(radpt_num)          prwt
C *
         idum   =max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
         apts_pt=allocate_memory2(3*idum,'d',fnm,snm,'apts_pt')
         awts_pt=allocate_memory2(idum,'d',fnm,snm,'awts_pt')
         idum   =max_array(radpt_num(1,ig),ngtypes)
         prpt_pt=allocate_memory2(ngtypes*idum,'d',fnm,snm,'prpt_pt')
         prwt_pt=allocate_memory2(ngtypes*idum,'d',fnm,snm,'prwt_pt')

      endif
C *
C * Set 2 - Arrays used in numerical quadrature
C *
C * Pointer             Length                  Array
C * bfnval_pt           
C * bfngval_pt          

      if(kqua_sw) then

c
c largest size for batches of integration points
c
         mxp=200

         bfnuse_pt  = allocate_memory2(BL_basis_size(ao_tag),'i',
     &                                 fnm,snm,'bfnuse_pt')
         bfnpnum_pt = allocate_memory2(BL_basis_size(ao_tag),'i',
     &                                 fnm,snm,'bfnpnum_pt')
         bfnpide_pt = allocate_memory2(90,'i',
     &                                 fnm,snm,'bfnpide_pt')
C *
C * Set 3 - Expand basis set to basis function arrays
C *
C * Pointer                Length                        Array
C * nprm_pt
C * angm_pt
C * pstr_pt
C * alpa_pt
C * coco_pt
C *
c       write(6,*) 'maxi_basA:',maxi_basA
c       write(6,*) 'maxi_primA:',maxi_primA

c        nprm_pt=allocate_memory(maxi_basA,'i')
c        angm_pt=allocate_memory(maxi_basA,'i')
c        pstr_pt=allocate_memory(maxi_basA,'i')
c        cent_pt=allocate_memory(maxi_basA,'i')
c        alpa_pt=allocate_memory(maxi_primA,'d')
c        coco_pt=allocate_memory(maxi_primA,'d')
         nprm_pt=null_memory()
         angm_pt=null_memory()
         pstr_pt=null_memory()
         cent_pt=null_memory()
         alpa_pt=null_memory()
         coco_pt=null_memory()

c       call expand_tobasisfns(memory_int(nprm_pt),
c    &                         memory_int(angm_pt),
c    &                         memory_int(pstr_pt),
c    &                         memory_int(cent_pt),
c    &                         memory_fp(alpa_pt),
c    &                         memory_fp(coco_pt))

        ra2_val_pt = allocate_memory2(mxp*natoms*2,'d',fnm,snm,
     &                                'ra2_val_pt')
        ra2_comp_pt = allocate_memory2(mxp*natoms*3,'d',fnm,snm,
     &                                'ra2_comp_pt')
        rho_pt = allocate_memory2(mxp*2,'d',fnm,snm,'rho_pt')
        grho_pt = allocate_memory2(mxp*2*3,'d',fnm,snm,'grho_pt')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       memory_int(null),                ! no chf_pert_atms
     &       0,                               ! no npert
     &       .false.,
     &       memory_fp(apts_pt),
     &       memory_fp(awts_pt),
     &       memory_fp(prpt_pt),
     &       memory_fp(prwt_pt),
     &       memory_fp(null),memory_fp(null), ! no avec,bvec
     &       adenm,bdenm,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       kma,kmb,
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .true., .true., .false.,
     &       .false.,.false.,.false.,.false.,.false.,
     &       mxp,.true.,.false.,extwr_sw,accuracy,iout,sma)

        call free_memory2(grho_pt,'d',fnm,snm,'grho_pt')
        call free_memory2(rho_pt,'d',fnm,snm,'rho_pt')
        call free_memory2(ra2_comp_pt,'d',fnm,snm,'ra2_comp_pt')
        call free_memory2(ra2_val_pt,'d',fnm,snm,'ra2_val_pt')

c       call free_memory(coco_pt,'d')
c       call free_memory(alpa_pt,'d')
c       call free_memory(cent_pt,'i')
c       call free_memory(pstr_pt,'i')
c       call free_memory(angm_pt,'i')
c       call free_memory(nprm_pt,'i')

        call free_memory2(bfnpide_pt,'i',fnm,snm,'bfnpide_pt')
        call free_memory2(bfnpnum_pt,'i',fnm,snm,'bfnpnum_pt')
        call free_memory2(bfnuse_pt,'i',fnm,snm,'bfnuse_pt')
c
c print Vxc
c
        if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then

           if(rks_sw)then
              write(6,*)'** Vxc **'
              call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
           else
              write(6,*)'** Vxc alpha **'
              call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
              write(6,*)'** Vxc beta **'
              call prtri(memory_fp(iscrb),BL_basis_size(ao_tag))
           endif
        endif

cc         xc_tracep=tracep(adenm,memory_fp(iscr),totbfn(ao_tag))
cc         write(6,*)'Trace product XC energy',xc_tracep

      endif
C
C     Obtain the Kohn-Sham matrix by fitting using an 
c     auxiliary basis set
C
      if(kfit_sw) then
        iscr = allocate_memory2(ltri,'d',fnm,snm,'iscr')
        call aclear_dp(memory_fp(iscr),ltri,0.0d0)
        xbfn_num   = BL_basis_size(kf_tag)*BL_basis_size(kf_tag)
        fitmat_pt  = allocate_memory2(xbfn_num,'d',fnm,snm,'fitmat_pt')
        ckfit_pt   = allocate_memory2(BL_basis_size(kf_tag),'d',
     &                                fnm,snm,'ckfit_pt')
        indx_pt    = allocate_memory2(BL_basis_size(kf_tag),'i',
     &                                fnm,snm,'indx_pt')
        bfnval_pt  = allocate_memory2(BL_basis_size(ao_tag),'d',
     &                                fnm,snm,'bfnval_pt')
        abfnval_pt = allocate_memory2(BL_basis_size(kf_tag),'d',
     &                                fnm,snm,'abfnval_pt')
        call exfit(ao_tag,BL_num_types(ao_tag),
     &             kf_tag,BL_basis_size(kf_tag),
     &             memory_fp(apts_pt),
     &             memory_fp(awts_pt),
     &             memory_fp(prpt_pt),
     &             memory_fp(prwt_pt),
     &             memory_fp(fitmat_pt),
     &             memory_fp(ckfit_pt),
     &             memory_int(indx_pt),
     &             memory_fp(bfnval_pt),
     &             memory_fp(abfnval_pt),
     &             adenm,bdenm,kma,kmb,
     &             memory_int,memory_fp,extwr_sw)
        call free_memory2(abfnval_pt,'d',fnm,snm,'abfnval_pt')
        call free_memory2(bfnval_pt,'d',fnm,snm,'bfnval_pt')
        call free_memory2(indx_pt,'i',fnm,snm,'indx_pt')
        call free_memory2(ckfit_pt,'d',fnm,snm,'ckfit_pt')
        call free_memory2(fitmat_pt,'d',fnm,snm,'fitmat_pt')
c
c       print Vxc
c
        if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
           write(6,*)'** Vxc **'
           call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
        endif
c
c       sum in Vxc
c
        do i = 1,ltri
          kma(i) = kma(i) + memory_fp(iscr+i-1)
        enddo
        call free_memory2(iscr,'d',fnm,snm,'iscr')
      endif


c      write(6,*) 'Fock mat'
c      call prtri(kma,BL_basis_size(ao_tag))

C *
C *Return to SCF code
c
      energy=J_energy+XC_energy

      call free_memory2(prwt_pt,'d',fnm,snm,'prwt_pt')
      call free_memory2(prpt_pt,'d',fnm,snm,'prpt_pt')
      call free_memory2(awts_pt,'d',fnm,snm,'awts_pt')
      call free_memory2(apts_pt,'d',fnm,snm,'apts_pt')
c
c output intermediate timings if requested
c
      if(print_sw(DEBUG_TIMING))then
         call list_time_periods(.false.,.false.)
      endif
c
c     check memory usage
c
      if (.not.omemok) then
         imemusage = pop_memory_count(imemcount)
         if (imemusage.ge.0.9d0*imemestimate.and.
     &       imemusage.le.imemestimate) omemok = .true.
         if (opg_root().and.(.not.omemok)) then
            write(iout,*)'*** estimated memory usage = ',imemestimate,
     &                   ' words'
            write(iout,*)'*** actual    memory usage = ',imemusage   ,
     &                   ' words'
            write(iout,*)'*** WARNING: the memory usage estimates for ',
     &                   'CD_energy_ao seem to be incorrect'
         endif
      endif
c
c     exit code if requested
c
      if(abort_sw)then
         if(opg_root())then
            write(6,*)'EXIT REQUESTED'
            call list_time_periods(.false.,.false.)
            call CD_print_dftresults(.true.,.false.,iout)
         endif
         call pg_end
         call exitc(0)
      endif

      CD_energy_ao = 0

      end
c
c-----------------------------------------------------------------------
c
      integer function CD_energy_mo(
     &     nvec,naocc,nbocc,
     &     coords,
     &     kma,kmb,avec,bvec,energy,
     &     memory_int,memory_fp,extwr_sw,accuracy, iout
_IF(debug_S)
     &     ,sma
_ENDIF
     &     )

C **********************************************************************
C *Description:                                                        *
C *Form the Kohn-Sham matrix using a variety of methods.               *
C *                                                                    *
C * The switches for various methods                                   *
C * ---------------------------------                                  *
C *                                                                    *
C * Jfit_dun -        Fit the Coulomb potential using Dunlaps method   *
C * K_fit    -        Use linear least squares fit to form K matrix    *
C * K_quad   -        Use quadrature to form K matrix                  *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis_api)
INCLUDE(../m4/common/statis)

c for basis set max values
INCLUDE(common/dft_basis)
c
C In variables
c
      integer nvec,naocc,nbocc
      REAL coords(3,*), accuracy
      REAL kma(*),kmb(*),avec(*),bvec(*)
      logical extwr_sw
      integer iout

INCLUDE(common/dft_api)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)

C *Scratch space and pointers
      integer memory_int(*)
      REAL memory_fp(*)
      integer apts_pt,awts_pt,prpt_pt,prwt_pt
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer abfnval_pt,fitmat_pt,indx_pt,ckfit_pt
      integer bfnuse_pt,bfnpnum_pt,bfnpide_pt
      integer nprm_pt,angm_pt,pstr_pt,cent_pt,alpa_pt,coco_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
c     integer xc_ept_pt, xc_vpt_pt, xc_dvpt_pt
      integer rho_pt, grho_pt
      integer mxp
C *Out variables
      REAL energy
      REAL sma
C *Local variables
      integer ao_tag,kf_tag,ao_bas,i,iscr,iscrb,ltri
      REAL xc_tracep
      integer xbfn_num
      integer idum
      integer null
      integer ig
      integer imemcount, imemusage, imemestimate
      logical omemok
      save omemok

C *Functions
      integer null_memory
      integer allocate_memory
      integer push_memory_count,    pop_memory_count
      integer push_memory_estimate, pop_memory_estimate
      logical opg_root
      REAL tracep      
      integer cd_update_geom
      integer cd_memreq_energy_mo
      integer max_array
c
      data omemok/.false./

C *End declarations
C **********************************************************************
c
c hardwired in for now
      ao_tag=1
      kf_tag=2
      ig    =G_KS
      null  = null_memory()
c
c     create a memory usage counter for check at the end
c
_IF(debug)
      omemok=.false.
_ENDIF
      if (.not.omemok) then
         imemestimate = CD_memreq_energy_mo(nvec,naocc,nbocc,
     &                              memory_int,memory_fp,iout)
         imemcount = push_memory_count()
      endif
c
      if(debug_sw) write(6,*) 'Entering CD_energy_mo'
      if (kfit_sw.or.jfit_sw.or.mult_sw) then
         call caserr("CD_energy_mo: cannot handle fitting yet")
      endif

      ao_bas=((BL_basis_size(ao_tag)+1)*BL_basis_size(ao_tag))/2
      ltri = ao_bas

c     if(opg_root() .and. print_sw(DEBUG_DENSITY))then
c        write(6,*)'** Input Density **'
c        call prtri(adenm,BL_basis_size(ao_tag))
c     endif

C **********************************************************************
C *Form the J matrix
C *
c
c ps - kma gets cleared in here, although apparently
c      not explicitly - so the aclear is redundant
c

      if(jfit_sw) then
         kf_tag = 3
         iscr = allocate_memory(ltri,'d')
         call aclear_dp(memory_fp(iscr),ltri,0.0d0)
         if( .not. rks_sw)then
            iscrb = allocate_memory(ltri,'d')
            call aclear_dp(memory_fp(iscrb),ltri,0.0d0)
         endif
c        call Jfit_dunlap(memory_fp,memory_int,
c    &        memory_fp(iscr),memory_fp(iscrb),
c    &        adenm,bdenm,iout)

         if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
           write(6,*)'** Vcoul **'
           call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
         endif
c
c sum in Vcoul
c
         if (.not.rks_sw) then
            call daxpy(ltri,1.0d0,memory_fp(iscrb),1,kmb,1)
            call free_memory(iscrb,'d')
         endif
         call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
         call free_memory(iscr,'d')

      elseif(mult_sw) then
         iscr = allocate_memory(ltri,'d')
         call aclear_dp(memory_fp(iscr),ltri,0.0d0)
         write(6,*) 'Off to JDriver'
c        call JDriver(ao_tag,adenm,bdenm,memory_fp(iscr),kmb)
c        J_energy=tracep(adenm,memory_fp(iscr),BL_basis_size(ao_tag))
         J_energy=J_energy*0.5d0
         if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
            write(6,*)'** Vcoul **'
            call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
         endif
         write(6,*) 'J_energy:',J_energy
c
c sum in Vcoul
c
         call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
         call free_memory(iscr,'d')

      endif
c
c add timings for gamess analysis
c
      if(jfit_sw.or.mult_sw) then
         call timana(4)
         call cpuwal(begin,ebegin)
      endif

C * 
C *Form the K matrix
C *
      if(kqua_sw.or.kfit_sw) then
C *
C *Allocate memory into needed blocks
C *
C * Set 1 - Arrays used in grid generation
C *
C * Pointer             Length                  Array
C * apts_pt             3*max(angupt_num)       apts
C * awts_pt             max(angupt_num)         awts
C * prpt_pt             max(radpt_num)          prpt
C * prwt_pt             max(radpt_num)          prwt
C *
         idum   =max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
         apts_pt=allocate_memory(3*idum,'d')
         awts_pt=allocate_memory(idum,'d')
         idum   =max_array(radpt_num(1,ig),ngtypes)
         prpt_pt=allocate_memory(ngtypes*idum,'d')
         prwt_pt=allocate_memory(ngtypes*idum,'d')

      endif
C *
C * Set 2 - Arrays used in numerical quadrature
C *
C * Pointer             Length                  Array
C * bfnval_pt           
C * bfngval_pt          

      if(kqua_sw) then

c
c largest size for batches of integration points
c
         mxp=200

         iscr = allocate_memory(ltri,'d')
         call aclear_dp(memory_fp(iscr),ltri,0.0d0)

         if( .not. rks_sw)then
            iscrb = allocate_memory(ltri,'d')
            call aclear_dp(memory_fp(iscrb),ltri,0.0d0)
         endif

         bfnuse_pt  = allocate_memory(BL_basis_size(ao_tag),'i')
         bfnpnum_pt = allocate_memory(BL_basis_size(ao_tag),'i')
         bfnpide_pt = allocate_memory(90,'i')

C *
C * Set 3 - Expand basis set to basis function arrays
C *
C * Pointer                Length                        Array
C * nprm_pt
C * angm_pt
C * pstr_pt
C * alpa_pt
C * coco_pt
C *
c       write(6,*) 'maxi_basA:',maxi_basA
c       write(6,*) 'maxi_primA:',maxi_primA

c        nprm_pt=allocate_memory(maxi_basA,'i')
c        angm_pt=allocate_memory(maxi_basA,'i')
c        pstr_pt=allocate_memory(maxi_basA,'i')
c        cent_pt=allocate_memory(maxi_basA,'i')
c        alpa_pt=allocate_memory(maxi_primA,'d')
c        coco_pt=allocate_memory(maxi_primA,'d')
         nprm_pt=null_memory()
         angm_pt=null_memory()
         pstr_pt=null_memory()
         cent_pt=null_memory()
         alpa_pt=null_memory()
         coco_pt=null_memory()

c       call expand_tobasisfns(memory_int(nprm_pt),
c    &                         memory_int(angm_pt),
c    &                         memory_int(pstr_pt),
c    &                         memory_int(cent_pt),
c    &                         memory_fp(alpa_pt),
c    &                         memory_fp(coco_pt))

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       memory_int(null),                ! no chf_pert_atms
     &       0,                               ! no npert
     &       .false.,
     &       memory_fp(apts_pt),
     &       memory_fp(awts_pt),
     &       memory_fp(prpt_pt),
     &       memory_fp(prwt_pt),
     &       avec,bvec,
     &       memory_fp(null),memory_fp(null), ! no adenm,bdenm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(iscr),memory_fp(iscrb),
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .true., .true., .false.,
     &       .false.,.false.,.false.,.false.,.false.,
     &       mxp,.false.,.true.,extwr_sw,accuracy,iout,sma)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')

c       call free_memory(coco_pt,'d')
c       call free_memory(alpa_pt,'d')
c       call free_memory(cent_pt,'i')
c       call free_memory(pstr_pt,'i')
c       call free_memory(angm_pt,'i')
c       call free_memory(nprm_pt,'i')

        call free_memory(bfnpide_pt,'i')
        call free_memory(bfnpnum_pt,'i')
        call free_memory(bfnuse_pt,'i')
c
c print Vxc
c
        if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then

           if(rks_sw)then
              write(6,*)'** Vxc **'
              call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
           else
              write(6,*)'** Vxc alpha **'
              call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
              write(6,*)'** Vxc beta **'
              call prtri(memory_fp(iscrb),BL_basis_size(ao_tag))
           endif
        endif

cc         xc_tracep=tracep(adenm,memory_fp(iscr),totbfn(ao_tag))
cc         write(6,*)'Trace product XC energy',xc_tracep

c
c       sum in Vxc
c
        call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
        if(.not. rks_sw)then
           call daxpy(ltri,1.0d0,memory_fp(iscrb),1,kmb,1)
        endif

        if(.not. rks_sw)then
           call free_memory(iscrb,'d')
        endif
        call free_memory(iscr,'d')

      endif
C
C     Obtain the Kohn-Sham matrix by fitting using an 
c     auxiliary basis set
C
      if(kfit_sw) then
        iscr = allocate_memory(ltri,'d')
        call aclear_dp(memory_fp(iscr),ltri,0.0d0)
        xbfn_num   = BL_basis_size(kf_tag)*BL_basis_size(kf_tag)
        fitmat_pt  = allocate_memory(xbfn_num,'d')
        ckfit_pt   = allocate_memory(BL_basis_size(kf_tag),'d')
        indx_pt    = allocate_memory(BL_basis_size(kf_tag),'i')
        bfnval_pt  = allocate_memory(BL_basis_size(ao_tag),'d')
        abfnval_pt = allocate_memory(BL_basis_size(kf_tag),'d')
c       call exfit(ao_tag,BL_num_types(ao_tag),
c    &             kf_tag,BL_basis_size(kf_tag),
c    &             memory_fp(apts_pt),
c    &             memory_fp(awts_pt),
c    &             memory_fp(prpt_pt),
c    &             memory_fp(prwt_pt),
c    &             memory_fp(fitmat_pt),
c    &             memory_fp(ckfit_pt),
c    &             memory_int(indx_pt),
c    &             memory_fp(bfnval_pt),
c    &             memory_fp(abfnval_pt),
c    &             adenm,bdenm,kma,kmb,
c    &             memory_int,memory_fp,extwr_sw)
        call free_memory(abfnval_pt,'d')
        call free_memory(bfnval_pt,'d')
        call free_memory(indx_pt,'i')
        call free_memory(ckfit_pt,'d')
        call free_memory(fitmat_pt,'d')
c
c       print Vxc
c
        if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
           write(6,*)'** Vxc **'
           call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
        endif
c
c       sum in Vxc
c
        do i = 1,ltri
          kma(i) = kma(i) + memory_fp(iscr+i-1)
        enddo
        call free_memory(iscr,'d')
      endif


c      write(6,*) 'Fock mat'
c      call prtri(kma,BL_basis_size(ao_tag))

C *
C *Return to SCF code
c
      energy=J_energy+XC_energy

      call free_memory(prwt_pt,'d')
      call free_memory(prpt_pt,'d')
      call free_memory(awts_pt,'d')
      call free_memory(apts_pt,'d')
c
c output intermediate timings if requested
c
      if(print_sw(DEBUG_TIMING))then
         call list_time_periods(.false.,.false.)
      endif
c
c     check memory usage
c
      if (.not.omemok) then
         imemusage = pop_memory_count(imemcount)
         if (imemusage.ge.0.9d0*imemestimate.and.
     &       imemusage.le.imemestimate) omemok = .true.
         if (opg_root().and.(.not.omemok)) then
            write(iout,*)'*** estimated memory usage = ',imemestimate,
     &                   ' words'
            write(iout,*)'*** actual    memory usage = ',imemusage   ,
     &                   ' words'
            write(iout,*)'*** WARNING: the memory usage estimates for ',
     &                   'CD_energy_mo seem to be incorrect'
         endif
      endif
c
c     exit code if requested
c
      if(abort_sw)then
         if(opg_root())then
            write(6,*)'EXIT REQUESTED'
            call list_time_periods(.false.,.false.)
            call CD_print_dftresults(.true.,.false.,iout)
         endif
         call pg_end
         call exitc(0)
      endif

      CD_energy_mo = 0

      end
c
c-----------------------------------------------------------------------
c
      integer function CD_energy(
     &     nvec,naocc,nbocc,
     &     coords,
     &     kma,kmb,avec,bvec,adenm,bdenm,energy,
     &     memory_int,memory_fp,extwr_sw,accuracy, iout
_IF(debug_S)
     &     ,sma
_ENDIF
     &     )

C **********************************************************************
C *Description:                                                        *
C *Form the Kohn-Sham matrix using a variety of methods.               *
C *                                                                    *
C * The switches for various methods                                   *
C * ---------------------------------                                  *
C *                                                                    *
C * Jfit_dun -        Fit the Coulomb potential using Dunlaps method   *
C * K_fit    -        Use linear least squares fit to form K matrix    *
C * K_quad   -        Use quadrature to form K matrix                  *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis_api)
INCLUDE(../m4/common/statis)

c for basis set max values
INCLUDE(common/dft_basis)
c
C In variables
c
      integer nvec,naocc,nbocc
      REAL coords(3,*), accuracy
      REAL kma(*),kmb(*),avec(*),bvec(*),adenm(*),bdenm(*)
      logical extwr_sw
      integer iout

INCLUDE(common/dft_api)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)

C *Scratch space and pointers
      integer memory_int(*)
      REAL memory_fp(*)
      integer apts_pt,awts_pt,prpt_pt,prwt_pt
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer abfnval_pt,fitmat_pt,indx_pt,ckfit_pt
      integer bfnuse_pt,bfnpnum_pt,bfnpide_pt
      integer nprm_pt,angm_pt,pstr_pt,cent_pt,alpa_pt,coco_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
c     integer xc_ept_pt, xc_vpt_pt, xc_dvpt_pt
      integer rho_pt, grho_pt
      integer mxp
C *Out variables
      REAL energy
      REAL sma
C *Local variables
      integer ao_tag,kf_tag,ao_bas,i,iscr,iscrb,ltri
      REAL xc_tracep
      integer xbfn_num
      integer idum,ig
      integer null
      integer imemcount, imemusage, imemestimate
      logical omemok
      save omemok

C *Functions
      integer null_memory
      integer allocate_memory
      integer push_memory_count,    pop_memory_count
      integer push_memory_estimate, pop_memory_estimate
      logical opg_root
      REAL tracep      
      integer cd_update_geom
      integer cd_memreq_energy
      integer max_array
c
      data omemok/.false./

C *End declarations
C **********************************************************************
c
c hardwired in for now
      ao_tag=1
      kf_tag=2
      ig    =G_KS
      null  = null_memory()
c
c     create a memory usage counter for check at the end
c
_IF(debug)
      omemok=.false.
_ENDIF
      if (.not.omemok) then
         imemestimate = CD_memreq_energy(nvec,naocc,nbocc,
     &                           memory_int,memory_fp,iout)
         imemcount = push_memory_count()
      endif
c
      if(debug_sw) write(6,*) 'Entering CD_energy'
      if (kfit_sw.or.jfit_sw.or.mult_sw) then
         call caserr("CD_energy: cannot handle fitting yet")
      endif

      ao_bas=((BL_basis_size(ao_tag)+1)*BL_basis_size(ao_tag))/2
      ltri = ao_bas

      if(opg_root() .and. print_sw(DEBUG_DENSITY))then
         write(6,*)'** Input Density **'
         call prtri(adenm,BL_basis_size(ao_tag))
      endif

C **********************************************************************
C *Form the J matrix
C *
c
c ps - kma gets cleared in here, although apparently
c      not explicitly - so the aclear is redundant
c

      if(jfit_sw) then
         kf_tag = 3
         iscr = allocate_memory(ltri,'d')
         call aclear_dp(memory_fp(iscr),ltri,0.0d0)
         if( .not. rks_sw)then
            iscrb = allocate_memory(ltri,'d')
            call aclear_dp(memory_fp(iscrb),ltri,0.0d0)
         endif
         call Jfit_dunlap(memory_fp,memory_int,
     &        memory_fp(iscr),memory_fp(iscrb),
     &        adenm,bdenm,iout)

         if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
           write(6,*)'** Vcoul **'
           call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
         endif
c
c sum in Vcoul
c
         if (.not.rks_sw) then
            call daxpy(ltri,1.0d0,memory_fp(iscrb),1,kmb,1)
            call free_memory(iscrb,'d')
         endif
         call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
         call free_memory(iscr,'d')

      elseif(mult_sw) then
         iscr = allocate_memory(ltri,'d')
         call aclear_dp(memory_fp(iscr),ltri,0.0d0)
         write(6,*) 'Off to JDriver'
         call JDriver(ao_tag,adenm,bdenm,memory_fp(iscr),kmb)
         J_energy=tracep(adenm,memory_fp(iscr),BL_basis_size(ao_tag))
         J_energy=J_energy*0.5d0
         if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
            write(6,*)'** Vcoul **'
            call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
         endif
         write(6,*) 'J_energy:',J_energy
c
c sum in Vcoul
c
         call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
         call free_memory(iscr,'d')

      endif
c
c add timings for gamess analysis
c
      if(jfit_sw.or.mult_sw) then
         call timana(4)
         call cpuwal(begin,ebegin)
      endif

C * 
C *Form the K matrix
C *
      if(kqua_sw.or.kfit_sw) then
C *
C *Allocate memory into needed blocks
C *
C * Set 1 - Arrays used in grid generation
C *
C * Pointer             Length                  Array
C * apts_pt             3*max(angupt_num)       apts
C * awts_pt             max(angupt_num)         awts
C * prpt_pt             max(radpt_num)          prpt
C * prwt_pt             max(radpt_num)          prwt
C *
         idum   =max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
         apts_pt=allocate_memory(3*idum,'d')
         awts_pt=allocate_memory(idum,'d')
         idum   =max_array(radpt_num(1,ig),ngtypes)
         prpt_pt=allocate_memory(ngtypes*idum,'d')
         prwt_pt=allocate_memory(ngtypes*idum,'d')

      endif
C *
C * Set 2 - Arrays used in numerical quadrature
C *
C * Pointer             Length                  Array
C * bfnval_pt           
C * bfngval_pt          

      if(kqua_sw) then

c
c largest size for batches of integration points
c
         mxp=200

         iscr = allocate_memory(ltri,'d')
         call aclear_dp(memory_fp(iscr),ltri,0.0d0)

         if( .not. rks_sw)then
            iscrb = allocate_memory(ltri,'d')
            call aclear_dp(memory_fp(iscrb),ltri,0.0d0)
         endif

         bfnuse_pt  = allocate_memory(BL_basis_size(ao_tag),'i')
         bfnpnum_pt = allocate_memory(BL_basis_size(ao_tag),'i')
         bfnpide_pt = allocate_memory(90,'i')

C *
C * Set 3 - Expand basis set to basis function arrays
C *
C * Pointer                Length                        Array
C * nprm_pt
C * angm_pt
C * pstr_pt
C * alpa_pt
C * coco_pt
C *
c       write(6,*) 'maxi_basA:',maxi_basA
c       write(6,*) 'maxi_primA:',maxi_primA

c        nprm_pt=allocate_memory(maxi_basA,'i')
c        angm_pt=allocate_memory(maxi_basA,'i')
c        pstr_pt=allocate_memory(maxi_basA,'i')
c        cent_pt=allocate_memory(maxi_basA,'i')
c        alpa_pt=allocate_memory(maxi_primA,'d')
c        coco_pt=allocate_memory(maxi_primA,'d')
         nprm_pt=null_memory()
         angm_pt=null_memory()
         pstr_pt=null_memory()
         cent_pt=null_memory()
         alpa_pt=null_memory()
         coco_pt=null_memory()

c       call expand_tobasisfns(memory_int(nprm_pt),
c    &                         memory_int(angm_pt),
c    &                         memory_int(pstr_pt),
c    &                         memory_int(cent_pt),
c    &                         memory_fp(alpa_pt),
c    &                         memory_fp(coco_pt))

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       memory_int(null),                ! no chf_pert_atms
     &       0,                               ! no npert
     &       .false.,
     &       memory_fp(apts_pt),
     &       memory_fp(awts_pt),
     &       memory_fp(prpt_pt),
     &       memory_fp(prwt_pt),
     &       avec,bvec,
     &       adenm,bdenm,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(iscr),memory_fp(iscrb),
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .true., .true., .false.,
     &       .false.,.false.,.false.,.false.,.false.,
     &       mxp,.true.,.true.,extwr_sw,accuracy,iout,sma)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')

c       call free_memory(coco_pt,'d')
c       call free_memory(alpa_pt,'d')
c       call free_memory(cent_pt,'i')
c       call free_memory(pstr_pt,'i')
c       call free_memory(angm_pt,'i')
c       call free_memory(nprm_pt,'i')

        call free_memory(bfnpide_pt,'i')
        call free_memory(bfnpnum_pt,'i')
        call free_memory(bfnuse_pt,'i')
c
c print Vxc
c
        if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then

           if(rks_sw)then
              write(6,*)'** Vxc **'
              call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
           else
              write(6,*)'** Vxc alpha **'
              call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
              write(6,*)'** Vxc beta **'
              call prtri(memory_fp(iscrb),BL_basis_size(ao_tag))
           endif
        endif

cc         xc_tracep=tracep(adenm,memory_fp(iscr),totbfn(ao_tag))
cc         write(6,*)'Trace product XC energy',xc_tracep

c
c       sum in Vxc
c
        call daxpy(ltri,1.0d0,memory_fp(iscr),1,kma,1)
        if(.not. rks_sw)then
           call daxpy(ltri,1.0d0,memory_fp(iscrb),1,kmb,1)
        endif

        if(.not. rks_sw)then
           call free_memory(iscrb,'d')
        endif
        call free_memory(iscr,'d')

      endif
C
C     Obtain the Kohn-Sham matrix by fitting using an 
c     auxiliary basis set
C
      if(kfit_sw) then
        iscr = allocate_memory(ltri,'d')
        call aclear_dp(memory_fp(iscr),ltri,0.0d0)
        xbfn_num   = BL_basis_size(kf_tag)*BL_basis_size(kf_tag)
        fitmat_pt  = allocate_memory(xbfn_num,'d')
        ckfit_pt   = allocate_memory(BL_basis_size(kf_tag),'d')
        indx_pt    = allocate_memory(BL_basis_size(kf_tag),'i')
        bfnval_pt  = allocate_memory(BL_basis_size(ao_tag),'d')
        abfnval_pt = allocate_memory(BL_basis_size(kf_tag),'d')
        call exfit(ao_tag,BL_num_types(ao_tag),
     &             kf_tag,BL_basis_size(kf_tag),
     &             memory_fp(apts_pt),
     &             memory_fp(awts_pt),
     &             memory_fp(prpt_pt),
     &             memory_fp(prwt_pt),
     &             memory_fp(fitmat_pt),
     &             memory_fp(ckfit_pt),
     &             memory_int(indx_pt),
     &             memory_fp(bfnval_pt),
     &             memory_fp(abfnval_pt),
     &             adenm,bdenm,kma,kmb,
     &             memory_int,memory_fp,extwr_sw)
        call free_memory(abfnval_pt,'d')
        call free_memory(bfnval_pt,'d')
        call free_memory(indx_pt,'i')
        call free_memory(ckfit_pt,'d')
        call free_memory(fitmat_pt,'d')
c
c       print Vxc
c
        if(opg_root() .and. print_sw(DEBUG_KSMATRIX) )then
           write(6,*)'** Vxc **'
           call prtri(memory_fp(iscr),BL_basis_size(ao_tag))
        endif
c
c       sum in Vxc
c
        do i = 1,ltri
          kma(i) = kma(i) + memory_fp(iscr+i-1)
        enddo
        call free_memory(iscr,'d')
      endif


c      write(6,*) 'Fock mat'
c      call prtri(kma,BL_basis_size(ao_tag))

C *
C *Return to SCF code
c
      energy=J_energy+XC_energy

      call free_memory(prwt_pt,'d')
      call free_memory(prpt_pt,'d')
      call free_memory(awts_pt,'d')
      call free_memory(apts_pt,'d')
c
c output intermediate timings if requested
c
      if(print_sw(DEBUG_TIMING))then
         call list_time_periods(.false.,.false.)
      endif
c
c     check memory usage
c
      if (.not.omemok) then
         imemusage = pop_memory_count(imemcount)
         if (imemusage.ge.0.9d0*imemestimate.and.
     &       imemusage.le.imemestimate) omemok = .true.
         if (opg_root().and.(.not.omemok)) then
            write(iout,*)'*** estimated memory usage = ',imemestimate,
     &                   ' words'
            write(iout,*)'*** actual    memory usage = ',imemusage   ,
     &                   ' words'
            write(iout,*)'*** WARNING: the memory usage estimates for ',
     &                   'CD_energy seem to be incorrect'
         endif
      endif
c
c     exit code if requested
c
      if(abort_sw)then
         if(opg_root())then
            write(6,*)'EXIT REQUESTED'
            call list_time_periods(.false.,.false.)
            call CD_print_dftresults(.true.,.false.,iout)
         endif
         call pg_end
         call exitc(0)
      endif

      CD_energy = 0

      end

C **********************************************************************
c
c   integer function CD_forces_ao - Driver for Force evaluation
c
c    Arguments:
c
c     coords,        I   current coordinates
c     adenm,         I   alpha or total density 
c     bdenm,         I   beta density, not used.
c     memory_int,    S   base for dynamic memory allocation (integer)
c     memory_fp,     S   base for dynamic memory allocation (real*8)
c     grad,         I/O  gradient 
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_forces_ao(coords,adenm,bdenm,
     &     memory_int,memory_fp,grad,extwr_sw,iout)
      implicit none

C **********************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters) 
C *In variables
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
      REAL coords(3,*)
      REAL adenm(*),bdenm(*)
      integer memory_int(*)
      REAL memory_fp(*)
      logical extwr_sw
      integer iout
C *Out variables
      REAL grad(3,*)      
C *Local variables
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
c     integer bfnuse_pt
      integer ao_tag
      integer ra2_val_pt, ra2_comp_pt, wt_pt
c     integer xc_ept_pt, xc_vpt_pt, xc_dvpt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum,ig
      integer null
      REAL dummy
      integer imemcount, imemusage, imemestimate
      logical omemok
      save omemok

C *Functions
      integer null_memory
      integer allocate_memory
      integer push_memory_count,    pop_memory_count
      integer push_memory_estimate, pop_memory_estimate
      logical opg_root
      integer cd_update_geom
      integer cd_memreq_forces_ao
      integer max_array
c
      data omemok/.false./

C *End declarations
c
C    ===== Store current coordinates ====
c
c     idum = CD_update_geom(coords)
c
_IF(debug)
      omemok=.false.
_ENDIF
      if (.not.omemok) then
         imemestimate = CD_memreq_forces_ao(coords,adenm,bdenm,
     &          memory_int,memory_fp,grad,extwr_sw,iout)
         imemcount = push_memory_count()
      endif
c
      if(opg_root() .and. print_sw(DEBUG_FORCES) )then
         write(6,*) 'Forces before DFT:'
         write(6,*) 
     &        'atom         de/dx             de/y          de/dz'
         do i=1,natoms
            write(6,1000)i,(grad(j,i),j=1,3)
         enddo
 1000    format(i3,3f16.8)
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      ig    =G_KS
      ao_tag=1

      if(jfitg_sw) then 
         call Jfitg(memory_fp,memory_int,adenm,bdenm,grad)
      endif

C *
C *Form the gradients due to the exchange-correlation part
C *
      if(kqua_sw) then
c
c length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = allocate_memory(3*idum,'d')
        awts_pt = allocate_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       memory_int(null),                ! no chf_pert_atms
     &       0,                               ! no npert
     &       .false.,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       memory_fp(null),memory_fp(null), ! no avec,bvec
     &       adenm,bdenm,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       grad,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .false., .false., .true.,
     &       .false.,.false.,.false.,.false.,.false.,
     &       mxp,.true.,.false.,extwr_sw,0.0d0,iout,dummy)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call free_memory(awts_pt,'d')
        call free_memory(apts_pt,'d')
      endif

      if(opg_root() .and. print_sw(DEBUG_FORCES) )then
         write(6,*) 'Forces after DFT:'
         write(6,*) 
     &        'atom         de/dx             de/y          de/dz'
         do i=1,natoms
            write(6,1000)i,(grad(j,i),j=1,3)
         enddo
      endif
c
c     check memory usage
c
      if (.not.omemok) then
         imemusage = pop_memory_count(imemcount)
         if (imemusage.ge.0.9d0*imemestimate.and.
     &       imemusage.le.imemestimate) omemok = .true.
         if (opg_root().and.(.not.omemok)) then
            write(iout,*)'*** estimated memory usage = ',imemestimate,
     &                   ' words'
            write(iout,*)'*** actual    memory usage = ',imemusage   ,
     &                   ' words'
            write(iout,*)'*** WARNING: the memory usage estimates for ',
     &                   'CD_forces_ao seem to be incorrect'
         endif
      endif
      cd_forces_ao = 0

      return
      end

C **********************************************************************
c
c   integer function CD_chf_rhs_ao - Driver for evaluation of the
c                                    CHF right-hand-sides
c
c    Arguments:
c
c     memory_int     S   base for dynamic memory allocation (integer)
c     memory_fp      S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     chf_pert_atms  I   for each perturbation the associated atom
c     adenm          I   alpha density matrix
c     bdenm          I   beta  density matrix
c     sa_ao          I   derivative alpha overlap matrices
c     sb_ao          I   derivative beta  overlap matrices
c     ba_ao         I/O  alpha rhs matrices
c     bb_ao         I/O  beta  rhs matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_chf_rhs_ao(memory_int,memory_fp,npert,
     &     chf_pert_atms,adenm,bdenm,sa_ao,sb_ao,
     &     ba_ao,bb_ao,extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter(ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter(ig=G_CPKS)
      integer npert
      integer chf_pert_atms(npert)
c     REAL adenm(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2)
c     REAL bdenm(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2)
c     REAL sa_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
c     REAL sb_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
      REAL adenm(*)
      REAL bdenm(*)
      REAL sa_ao(*)
      REAL sb_ao(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
c     REAL ba_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
c     REAL bb_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
      REAL ba_ao(*)
      REAL bb_ao(*)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, nao, naot
      integer null
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      naot = nao*nao
      if(opg_root() .and. print_sw(DEBUG_CHF_RHS) )then
         write(iout,*)'CD_chf_rhs_ao: alpha density'
         write(iout,*)
         call prtri(adenm,nao)
         if (.not.rks_sw) then
            write(iout,*)'CD_chf_rhs_ao: beta density'
            write(iout,*)
            call prtri(bdenm,nao)
         endif
         do i=1,npert
            write(iout,*)'CD_chf_rhs_ao: alpha perturbed overlap',i
            write(iout,*)
            call prsqm(sa_ao((i-1)*naot+1),nao,nao,nao,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_rhs_ao: beta perturbed overlap',i
               write(iout,*)
               call prsqm(sb_ao((i-1)*naot+1),nao,nao,nao,iout)
            enddo
         endif
         write(iout,*) 'CD_chf_rhs_mo: RHS matrices before DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_rhs_ao: alpha ',i
            write(iout,*)
            call prsqm(ba_ao((i-1)*naot+1),nao,nao,nao,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_rhs_ao: beta ',i
               write(iout,*)
               call prsqm(bb_ao((i-1)*naot+1),nao,nao,nao,iout)
            enddo
         endif
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = allocate_memory(3*idum,'d')
        awts_pt = allocate_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       chf_pert_atms,
     &       npert,
     &       .true.,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       memory_fp(null),memory_fp(null), ! no alpha/beta vectors
     &       adenm,bdenm,
     &       sa_ao,sb_ao,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       memory_fp(null),                 ! no gradient
     &       ba_ao,bb_ao,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .false., .false., .false.,
     &       .false.,.true.,.false.,.false.,.false.,
     &       mxp,.true.,.false.,extwr_sw,0.0d0,iout,dummy)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call free_memory(awts_pt,'d')
        call free_memory(apts_pt,'d')
      endif

      if(opg_root() .and. print_sw(DEBUG_CHF_RHS) )then
         write(iout,*) 'CD_chf_rhs_ao: RHS matrices after DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_rhs_ao: alpha ',i
            write(iout,*)
            call prsqm(ba_ao((i-1)*naot+1),nao,nao,nao,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_rhs_ao: beta ',i
               write(iout,*)
               call prsqm(bb_ao((i-1)*naot+1),nao,nao,nao,iout)
            enddo
         endif
      endif

      cd_chf_rhs_ao = 0

      return
      end


C **********************************************************************
c
c   integer function CD_chf_rhs_mo - Driver for evaluation of the
c                                    CHF right-hand-sides
c
c    Arguments:
c
c     memory_int     S   base for dynamic memory allocation (integer)
c     memory_fp      S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     chf_pert_atms  I   for each perturbation the associated atom
c     nvec           I   number of vectors
c     naocc          I   number of occupied alpha vectors
c     nbocc          I   number of occupied beta  vectors
c     avec           I   alpha vectors
c     bvec           I   beta  vectors
c     sa_mo          I   derivative alpha overlap matrices
c     sb_mo          I   derivative beta  overlap matrices
c     ba_mo         I/O  alpha rhs matrices
c     bb_mo         I/O  beta  rhs matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_chf_rhs_mo(memory_int,memory_fp,npert,
     &     chf_pert_atms,nvec,naocc,nbocc,avec,bvec,sa_mo,sb_mo,
     &     ba_mo,bb_mo,extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter(ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter(ig=G_CPKS)
      integer npert
      integer chf_pert_atms(npert)
      integer nvec, naocc, nbocc
      REAL avec(*)
      REAL bvec(*)
      REAL sa_mo(nvec*(nvec+1)/2,npert)
      REAL sb_mo(nvec*(nvec+1)/2,npert)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL ba_mo(naocc,nvec-naocc,npert)
      REAL bb_mo(nbocc,nvec-naocc,npert)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, nao
      integer null
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      if(opg_root() .and. print_sw(DEBUG_CHF_RHS) )then
         write(iout,*)'CD_chf_rhs_mo: alpha vectors'
         write(iout,*)
         call prsqm(avec,nao,nvec,nao,iout)
         if (.not.rks_sw) then
            write(iout,*)'CD_chf_rhs_mo: beta vectors'
            write(iout,*)
            call prsqm(bvec,nao,nvec,nao,iout)
         endif
         do i=1,npert
            write(iout,*)'CD_chf_rhs_mo: alpha perturbed overlap',i
            write(iout,*)
            call prtri(sa_mo(1,i),nvec)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_rhs_mo: beta perturbed overlap',i
               write(iout,*)
               call prtri(sb_mo(1,i),nvec)
            enddo
         endif
         write(iout,*) 'CD_chf_rhs_mo: RHS matrices before DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_rhs_mo: alpha ',i
            write(iout,*)
            call prsqm(ba_mo(1,1,i),naocc,nvec-naocc,naocc,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_rhs_mo: beta ',i
               write(iout,*)
               call prsqm(bb_mo(1,1,i),nbocc,nvec-nbocc,nbocc,iout)
            enddo
         endif
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = allocate_memory(3*idum,'d')
        awts_pt = allocate_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       chf_pert_atms,
     &       npert,
     &       .true.,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       avec,bvec,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta density
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       sa_mo,sb_mo,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       ba_mo,bb_mo,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .false., .false., .false.,
     &       .false.,.true.,.false.,.false.,.false.,
     &       mxp,.false.,.true.,extwr_sw,0.0d0,iout,dummy)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call free_memory(awts_pt,'d')
        call free_memory(apts_pt,'d')
      endif

      if(opg_root() .and. print_sw(DEBUG_CHF_RHS) )then
         write(iout,*) 'CD_chf_rhs_mo: RHS matrices after DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_rhs_mo: alpha ',i
            write(iout,*)
            call prsqm(ba_mo(1,1,i),naocc,nvec-naocc,naocc,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_rhs_mo: beta ',i
               write(iout,*)
               call prsqm(bb_mo(1,1,i),nbocc,nvec-nbocc,nbocc,iout)
            enddo
         endif
      endif

      cd_chf_rhs_mo = 0

      return
      end

C **********************************************************************
c
c   integer function CD_chf_lhs_ao - Driver for evaluation of the
c                                    CHF left-hand-sides
c
c    Arguments:
c
c     memory_int     S   base for dynamic memory allocation (integer)
c     memory_fp      S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     chf_pert_atms  I   for each perturbation the associated atom
c     geometric_sw   I   true if considering geometric perturbations
c     adenm          I   alpha density
c     bdenm          I   beta  density
c     ua_ao          I   derivative alpha density matrices
c     ub_ao          I   derivative beta  density matrices
c     ga_ao         I/O  alpha lhs matrices
c     gb_ao         I/O  beta  lhs matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_chf_lhs_ao(memory_int,memory_fp,npert,
     &     chf_pert_atms,geometric_sw,adenm,bdenm,
     &     ua_ao,ub_ao,ga_ao,gb_ao,extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_CPKS)
      integer npert
      integer chf_pert_atms(npert)
      logical geometric_sw
c     REAL adenm(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2)
c     REAL bdenm(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2)
c     REAL ua_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
c     REAL ub_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
      REAL adenm(*)
      REAL bdenm(*)
      REAL ua_ao(*)
      REAL ub_ao(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
c     REAL ga_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
c     REAL gb_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
      REAL ga_ao(*)
      REAL gb_ao(*)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum
      integer null, nao, naot
      integer imemcount, imemusage, imemestimate
      logical omemok
      save omemok
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
      integer CD_memreq_chf_lhs_ao
      integer push_memory_count, pop_memory_count
c
      data omemok/.false./
c
c     Code:
c
_IF(debug)
      omemok=.false.
_ENDIF
      if (.not.omemok) then
c        imemestimate = CD_memreq_chf_lhs_ao(memory_fp,memory_int,iout)
         imemestimate = 0
         imemcount = push_memory_count()
      endif
c
      nao = BL_basis_size(ao_tag)
      naot = nao*nao
      if(opg_root() .and. print_sw(DEBUG_CHF_LHS) )then
         write(iout,*)'CD_chf_lhs_ao: alpha density'
         write(iout,*)
         call prtri(adenm,nao)
         if (.not.rks_sw) then
            write(iout,*)'CD_chf_lhs_ao: beta density'
            write(iout,*)
            call prtri(bdenm,nao)
         endif
         do i=1,npert
            write(iout,*)'CD_chf_lhs_ao: alpha perturbed density',i
            write(iout,*) 
            call prsqm(ua_ao((i-1)*naot+1),nao,nao,nao,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_lhs_ao: beta perturbed density',i
               write(iout,*) 
               call prsqm(ub_ao((i-1)*naot+1),nao,nao,nao,iout)
            enddo
         endif
         write(iout,*) 'CD_chf_lhs_ao: LHS matrices before DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_lhs_ao: alpha ',i
            write(iout,*) 
            call prsqm(ga_ao((i-1)*naot+1),nao,nao,nao,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_lhs_ao: beta ',i
               write(iout,*) 
               call prsqm(gb_ao((i-1)*naot+1),nao,nao,nao,iout)
            enddo
         endif
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = allocate_memory(3*idum,'d')
        awts_pt = allocate_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       chf_pert_atms,
     &       npert,
     &       geometric_sw,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       memory_fp(null),memory_fp(null), ! no alpha/beta vectors
     &       adenm,bdenm,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       ua_ao,ub_ao,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       ga_ao,gb_ao,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .false., .false., .false.,
     &       .false.,.false.,.true.,.false.,.false.,
     &       mxp,.true.,.false.,extwr_sw,0.0d0,iout,dummy)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call free_memory(awts_pt,'d')
        call free_memory(apts_pt,'d')
      endif

      if(opg_root() .and. print_sw(DEBUG_CHF_LHS) )then
         write(iout,*) 'CD_chf_lhs_ao: LHS matrices after DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_lhs_ao: alpha ',i
            write(iout,*) 
            call prsqm(ga_ao((i-1)*naot+1),nao,nao,nao,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_lhs_ao: beta ',i
               write(iout,*) 
               call prsqm(gb_ao((i-1)*naot+1),nao,nao,nao,iout)
            enddo
         endif
      endif
c
c     check memory usage
c
      if (.not.omemok) then
         imemusage = pop_memory_count(imemcount)
         if (imemusage.ge.0.9d0*imemestimate.and.
     &       imemusage.le.imemestimate) omemok = .true.
         if (opg_root().and.(.not.omemok)) then
            write(iout,*)'*** estimated memory usage = ',imemestimate,
     &                   ' words'
            write(iout,*)'*** actual    memory usage = ',imemusage   ,
     &                   ' words'
            write(iout,*)'*** WARNING: the memory usage estimates for ',
     &                   'CD_chf_lhs_ao seem to be incorrect'
         endif
      endif
c
      cd_chf_lhs_ao = 0

      return
      end


C **********************************************************************
c
c   integer function CD_chf_lhs_mo - Driver for evaluation of the
c                                    CHF left-hand-sides
c
c    Arguments:
c
c     memory_int     S   base for dynamic memory allocation (integer)
c     memory_fp      S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     chf_pert_atms  I   for each perturbation the associated atom
c     geometric_sw   I   true if considering geometric perturbations
c     nvec           I   number of vectors
c     naocc          I   number of occupied alpha vectors
c     nbocc          I   number of occupied beta  vectors
c     avec           I   alpha vectors
c     bvec           I   beta  vectors
c     ua_mo          I   derivative alpha density matrices
c     ub_mo          I   derivative beta  density matrices
c     ga_mo         I/O  alpha lhs matrices
c     gb_mo         I/O  beta  lhs matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_chf_lhs_mo(memory_int,memory_fp,npert,
     &     chf_pert_atms,geometric_sw,nvec,naocc,nbocc,avec,bvec,
     &     ua_mo,ub_mo,ga_mo,gb_mo,extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_CPKS)
      integer npert
      integer chf_pert_atms(npert)
      logical geometric_sw
      integer nvec, naocc, nbocc
      REAL avec(*)
      REAL bvec(*)
      REAL ua_mo(naocc,nvec-naocc,npert)
      REAL ub_mo(nbocc,nvec-nbocc,npert)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL ga_mo(naocc,nvec-naocc,npert)
      REAL gb_mo(nbocc,nvec-nbocc,npert)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum
      integer null, nao
      integer imemcount, imemusage, imemestimate
      logical omemok
      save omemok
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
      integer CD_memreq_chf_lhs_mo
      integer push_memory_count, pop_memory_count
c
      data omemok/.false./
c
c     Code:
c
_IF(debug)
      omemok=.false.
_ENDIF
      if (.not.omemok) then
         imemestimate = CD_memreq_chf_lhs_mo(memory_int,memory_fp,npert,
     &        chf_pert_atms,geometric_sw,nvec,naocc,nbocc,avec,bvec,
     &        ua_mo,ub_mo,ga_mo,gb_mo,extwr_sw,iout)
         imemcount = push_memory_count()
      endif
c
      nao = BL_basis_size(ao_tag)
      if(opg_root() .and. print_sw(DEBUG_CHF_LHS) )then
         write(iout,*)'CD_chf_lhs_mo: alpha vectors'
         write(iout,*)
         call prsqm(avec,nao,nvec,nao,iout)
         if (.not.rks_sw) then
            write(iout,*)'CD_chf_lhs_mo: beta vectors'
            write(iout,*)
            call prsqm(bvec,nao,nvec,nao,iout)
         endif
         do i=1,npert
            write(iout,*)'CD_chf_lhs_mo: alpha perturbed density',i
            write(iout,*) 
            call prsqm(ua_mo(1,1,i),naocc,nvec-naocc,naocc,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_lhs_mo: beta perturbed density',i
               write(iout,*) 
               call prsqm(ub_mo(1,1,i),nbocc,nvec-nbocc,nbocc,iout)
            enddo
         endif
         write(iout,*) 'CD_chf_lhs_mo: LHS matrices before DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_lhs_mo: alpha ',i
            write(iout,*) 
            call prsqm(ga_mo(1,1,i),naocc,nvec-naocc,naocc,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_lhs_mo: beta ',i
               write(iout,*) 
               call prsqm(gb_mo(1,1,i),nbocc,nvec-nbocc,nbocc,iout)
            enddo
         endif
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = allocate_memory(3*idum,'d')
        awts_pt = allocate_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       chf_pert_atms,
     &       npert,
     &       geometric_sw,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       avec,bvec,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta density
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       ua_mo,ub_mo,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       ga_mo,gb_mo,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .false., .false., .false.,
     &       .false.,.false.,.true.,.false.,.false.,
     &       mxp,.false.,.true.,extwr_sw,0.0d0,iout,dummy)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call free_memory(awts_pt,'d')
        call free_memory(apts_pt,'d')
      endif

      if(opg_root() .and. print_sw(DEBUG_CHF_LHS) )then
         write(iout,*) 'CD_chf_lhs_mo: LHS matrices after DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_lhs_mo: alpha ',i
            write(iout,*) 
            call prsqm(ga_mo(1,1,i),naocc,nvec-naocc,naocc,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_lhs_mo: beta ',i
               write(iout,*) 
               call prsqm(gb_mo(1,1,i),nbocc,nvec-nbocc,nbocc,iout)
            enddo
         endif
      endif
c
c     check memory usage
c
      if (.not.omemok) then
         imemusage = pop_memory_count(imemcount)
         if (imemusage.ge.0.9d0*imemestimate.and.
     &       imemusage.le.imemestimate) omemok = .true.
         if (opg_root().and.(.not.omemok)) then
            write(iout,*)'*** estimated memory usage = ',imemestimate,
     &                   ' words'
            write(iout,*)'*** actual    memory usage = ',imemusage   ,
     &                   ' words'
            write(iout,*)'*** WARNING: the memory usage estimates for ',
     &                   'CD_chf_lhs_mo seem to be incorrect'
         endif
      endif
c
      cd_chf_lhs_mo = 0

      return
      end

C **********************************************************************
c
c   integer function CD_chf_dksm_ao - Driver for evaluation of the
c                                     perturbed Kohn-Sham matrices 
c
c    Arguments:
c
c     memory_int     S   base for dynamic memory allocation (integer)
c     memory_fp      S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     chf_pert_atms  I   for each perturbation the associated atom
c     adenm          I   alpha density
c     bdenm          I   beta  density
c     da_ao          I   perturbed alpha density
c     db_ao          I   perturbed beta  density
c     fa_ao         I/O  alpha perturbed Kohn-Sham matrices
c     fb_ao         I/O  beta  perturbed Kohn-Sham matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_chf_dksm_ao(memory_int,memory_fp,npert,
     &     chf_pert_atms,adenm,bdenm,da_ao,db_ao,
     &     fa_ao,fb_ao,extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_CPKS)
      integer npert
      integer chf_pert_atms(npert)
c     REAL adenm(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2)
c     REAL bdenm(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2)
c     REAL da_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
c     REAL db_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
      REAL adenm(*)
      REAL bdenm(*)
      REAL da_ao(*)
      REAL db_ao(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
c     REAL fa_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
c     REAL fb_ao(totbfn(ao_tag),totbfn(ao_tag),npert)
      REAL fa_ao(*)
      REAL fb_ao(*)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, nao, naot
      integer null
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      naot = nao*nao
      if(opg_root() .and. print_sw(DEBUG_CHF_DKSM) )then
         write(iout,*)'CD_chf_dksm_ao: alpha vectors'
         write(iout,*)
         call prtri(adenm,nao)
         if (.not.rks_sw) then
            write(iout,*)'CD_chf_dksm_ao: beta vectors'
            write(iout,*)
            call prtri(bdenm,nao)
         endif
         do i=1,npert
            write(iout,*)'CD_chf_dksm_ao: alpha perturbed density',i
            write(iout,*) 
            call prsqm(da_ao((i-1)*naot+1),nao,nao,nao,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_dksm_ao: beta perturbed density',i
               write(iout,*) 
               call prsqm(db_ao((i-1)*naot+1),nao,nao,nao,iout)
            enddo
         endif
         write(iout,*) 'CD_chf_dksm_ao: Perturbed Kohn-Sham matrices ',
     &                 'before DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_dksm_ao: alpha perturbed KS',i
            write(iout,*) 
            call prsqm(fa_ao((i-1)*naot+1),nao,nao,nao,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_dksm_ao: beta perturbed KS',i
               write(iout,*) 
               call prsqm(fb_ao((i-1)*naot+1),nao,nao,nao,iout)
            enddo
         endif
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = allocate_memory(3*idum,'d')
        awts_pt = allocate_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       chf_pert_atms,
     &       npert,
     &       .true.,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       memory_fp(null),memory_fp(null), ! no alpha/beta vectors
     &       adenm,bdenm,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       da_ao,db_ao,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       fa_ao,fb_ao,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .false., .false., .false.,
     &       .false.,.false.,.false.,.true.,.false.,
     &       mxp,.true.,.false.,extwr_sw,0.0d0,iout,dummy)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call free_memory(awts_pt,'d')
        call free_memory(apts_pt,'d')
      endif

      if(opg_root() .and. print_sw(DEBUG_CHF_DKSM) )then
         write(iout,*) 'CD_chf_dksm_ao: Perturbed Kohn-Sham matrices ',
     &                 'after DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_dksm_ao: alpha perturbed KS',i
            write(iout,*) 
            call prsqm(fa_ao((i-1)*naot+1),nao,nao,nao,iout)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_dksm_ao: beta perturbed KS',i
               write(iout,*) 
               call prsqm(fb_ao((i-1)*naot+1),nao,nao,nao,iout)
            enddo
         endif
      endif

      cd_chf_dksm_ao = 0

      return
      end


C **********************************************************************
c
c   integer function CD_chf_dksm_mo - Driver for evaluation of the
c                                     perturbed Kohn-Sham matrices 
c
c    Arguments:
c
c     memory_int     S   base for dynamic memory allocation (integer)
c     memory_fp      S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     chf_pert_atms  I   for each perturbation the associated atom
c     nvec           I   number of vectors
c     naocc          I   number of occupied alpha vectors
c     nbocc          I   number of occupied beta  vectors
c     avec           I   alpha vectors
c     bvec           I   beta  vectors
c     da_mo          I   perturbed alpha density
c     db_mo          I   perturbed beta  density
c     fa_mo         I/O  alpha perturbed Kohn-Sham matrices
c     fb_mo         I/O  beta  perturbed Kohn-Sham matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_chf_dksm_mo(memory_int,memory_fp,npert,
     &     chf_pert_atms,nvec,naocc,nbocc,avec,bvec,da_mo,db_mo,
     &     fa_mo,fb_mo,extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_CPKS)
      integer npert
      integer chf_pert_atms(npert)
      integer nvec, naocc, nbocc
      REAL avec(*)
      REAL bvec(*)
      REAL da_mo(nvec*(nvec+1)/2,npert)
      REAL db_mo(nvec*(nvec+1)/2,npert)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL fa_mo(nvec*(nvec+1)/2,npert)
      REAL fb_mo(nvec*(nvec+1)/2,npert)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, nao
      integer null
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      if(opg_root() .and. print_sw(DEBUG_CHF_DKSM) )then
         write(iout,*)'CD_chf_dksm_mo: alpha vectors'
         write(iout,*)
         call prsqm(avec,nao,nvec,nao,iout)
         if (.not.rks_sw) then
            write(iout,*)'CD_chf_dksm_mo: beta vectors'
            write(iout,*)
            call prsqm(bvec,nao,nvec,nao,iout)
         endif
         do i=1,npert
            write(iout,*)'CD_chf_dksm_mo: alpha perturbed density',i
            write(iout,*) 
            call prtri(da_mo(1,i),nvec)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_dksm_mo: beta perturbed density',i
               write(iout,*) 
               call prtri(db_mo(1,i),nvec)
            enddo
         endif
         write(iout,*) 'CD_chf_dksm_mo: Perturbed Kohn-Sham matrices ',
     &                 'before DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_dksm_mo: alpha perturbed KS',i
            write(iout,*) 
            call prtri(fa_mo(1,i),nvec)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_dksm_mo: beta perturbed KS',i
               write(iout,*) 
               call prtri(fb_mo(1,i),nvec)
            enddo
         endif
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = allocate_memory(3*idum,'d')
        awts_pt = allocate_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       chf_pert_atms,
     &       npert,
     &       .true.,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       avec,bvec,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta density
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       da_mo,db_mo,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       fa_mo,fb_mo,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .false., .false., .false.,
     &       .false.,.false.,.false.,.true.,.false.,
     &       mxp,.false.,.true.,extwr_sw,0.0d0,iout,dummy)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call free_memory(awts_pt,'d')
        call free_memory(apts_pt,'d')
      endif

      if(opg_root() .and. print_sw(DEBUG_CHF_DKSM) )then
         write(iout,*) 'CD_chf_dksm_mo: Perturbed Kohn-Sham matrices ',
     &                 'after DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_chf_dksm_mo: alpha perturbed KS',i
            write(iout,*) 
            call prtri(fa_mo(1,i),nvec)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_chf_dksm_mo: beta perturbed KS',i
               write(iout,*) 
               call prtri(fb_mo(1,i),nvec)
            enddo
         endif
      endif

      cd_chf_dksm_mo = 0

      return
      end

C **********************************************************************
c
c   integer function CD_dksm_exp_ao - Driver for evaluation of the
c                                     explicit derivatives of the 
c                                     Kohn-Sham matrix with respect
c                                     to the nuclear coordinates.
c
c    Arguments:
c
c     memory_int,    S   base for dynamic memory allocation (integer)
c     memory_fp,     S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     adenm,         I   alpha density or total density 
c     bdenm,         I   beta  density or not used
c     fxa_ao        I/O  alpha explicit derivative Kohn-Sham matrices
c     fxb_ao        I/O  beta  explicit derivative Kohn-Sham matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_dksm_exp_ao(memory_int,memory_fp,npert,
     &     adenm,bdenm,fxa_ao,fxb_ao,
     &     extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
c     parameter (ig=G_CPKS)
c     Looks like we have to do the explicit derivatives of the
c     KS-matrix more accurate. If we don't we have trouble with
c     ScF3 (par_10). Eg.
c
c     ig=G_CPKS            ig=G_KS              force
c     freq    intensity    freq    intensity    freq
c      36.26  117.85701     36.97  116.41320     37.4119
c     139.43   13.17162    140.48   13.09114    140.6961
c     149.38   14.59725    149.05   14.41116    145.9012
c     567.20     .12104    578.89     .13537    578.7009
c     661.31  252.38760    675.71  258.97621    675.2153
c     665.91  253.48479    679.89  260.19754    678.9972
c
      parameter (ig=G_KS)
c
      integer npert
      REAL adenm(*)
      REAL bdenm(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
c     REAL fxa_ao(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2,npert)
c     REAL fxb_ao(totbfn(ao_tag)*(totbfn(ao_tag)+1)/2,npert)
      REAL fxa_ao(*)
      REAL fxb_ao(*)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, nao, naot
      integer null
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      naot = nao*(nao+1)/2
      if(opg_root() .and. print_sw(DEBUG_DKSM_EXP) )then
         write(iout,*)'CD_dksm_exp_ao: alpha density matrix'
         write(iout,*) 
         call prtri(adenm,nao)
         if (.not.rks_sw) then
            write(iout,*)'CD_dksm_exp_ao: beta density matrix'
            write(iout,*) 
            call prtri(bdenm,nao)
         endif
         write(iout,*)'CD_dksm_exp_ao: Explicit derivative Kohn-Sham ',
     &                'matrices before DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_dksm_exp_ao: alpha dKS',i
            write(iout,*) 
            call prtri(fxa_ao(naot*(i-1)+1),nao)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_dksm_exp_ao: beta dKS',i
               write(iout,*) 
               call prtri(fxb_ao(naot*(i-1)+1),nao)
            enddo
         endif
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = allocate_memory(3*idum,'d')
        awts_pt = allocate_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       memory_int(null),                ! no chf_pert_atms
     &       npert,
     &       .true.,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       memory_fp(null),memory_fp(null), ! no avec,bvec
     &       adenm,bdenm,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       fxa_ao,fxb_ao,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
c    &       .false., .false., .false.,
cDEBUG
     &       .true., .false., .false.,
cDEBUG
     &       .true.,.false.,.false.,.false.,.false.,
     &       mxp,.true.,.false.,extwr_sw,0.0d0,iout,dummy)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call free_memory(awts_pt,'d')
        call free_memory(apts_pt,'d')
      endif

      if(opg_root() .and. print_sw(DEBUG_DKSM_EXP) )then
         write(iout,*)'CD_dksm_exp_ao: Explicit derivative Kohn-Sham ',
     &                'matrices after DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_dksm_exp_ao: alpha dKS',i
            write(iout,*) 
            call prtri(fxa_ao(naot*(i-1)+1),nao)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_dksm_exp_ao: beta dKS',i
               write(iout,*) 
               call prtri(fxb_ao(naot*(i-1)+1),nao)
            enddo
         endif
      endif

      cd_dksm_exp_ao = 0

      return
      end
C **********************************************************************
c
c   integer function CD_dksm_exp_mo - Driver for evaluation of the
c                                     explicit derivatives of the 
c                                     Kohn-Sham matrix with respect
c                                     to the nuclear coordinates.
c
c    Arguments:
c
c     memory_int,    S   base for dynamic memory allocation (integer)
c     memory_fp,     S   base for dynamic memory allocation (real*8)
c     npert          I   number of perturbations
c     adenm,         I   alpha density or total density 
c     bdenm,         I   beta  density or not used
c     fxa_mo        I/O  alpha explicit derivative Kohn-Sham matrices
c     fxb_mo        I/O  beta  explicit derivative Kohn-Sham matrices
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_dksm_exp_mo(memory_int,memory_fp,npert,
     &     nvec,naocc,nbocc,avec,bvec,fxa_mo,fxb_mo,
     &     extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_CPKS)
      integer nvec, naocc, nbocc
      integer npert
      REAL avec(*)
      REAL bvec(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL fxa_mo(nvec*(nvec+1)/2,npert)
      REAL fxb_mo(nvec*(nvec+1)/2,npert)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, nao
      integer null
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      if(opg_root() .and. print_sw(DEBUG_DKSM_EXP) )then
         write(iout,*)'CD_dksm_exp_mo: alpha vectors'
         write(iout,*) 
         call prsqm(avec,nao,nvec,nao,iout)
         if (.not.rks_sw) then
            write(iout,*)'CD_dksm_exp_mo: beta vectors'
            write(iout,*) 
            call prsqm(bvec,nao,nvec,nao,iout)
         endif
         write(iout,*)'CD_dksm_exp_mo: Explicit derivative Kohn-Sham ',
     &                'matrices before DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_dksm_exp_mo: alpha dKS',i
            write(iout,*) 
            call prtri(fxa_mo(1,i),nvec)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_dksm_exp_mo: beta dKS',i
               write(iout,*) 
               call prtri(fxb_mo(1,i),nvec)
            enddo
         endif
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        mxp=200

        idum    = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt = allocate_memory(3*idum,'d')
        awts_pt = allocate_memory(idum,'d')
        idum    = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt = allocate_memory(ngtypes*idum,'d')
        prwt_pt = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       memory_int(null),                ! no chf_pert_atms
     &       npert,
     &       .true.,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       avec,bvec,
     &       memory_fp(null),memory_fp(null), ! no adenm,bdenm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       fxa_mo,fxb_mo,
     &       memory_fp(null),                 ! no hessian
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
c    &       .false., .false., .false.,
cDEBUG
     &       .true., .false., .false.,
cDEBUG
     &       .true.,.false.,.false.,.false.,.false.,
     &       mxp,.false.,.true.,extwr_sw,0.0d0,iout,dummy)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call free_memory(awts_pt,'d')
        call free_memory(apts_pt,'d')
      endif

      if(opg_root() .and. print_sw(DEBUG_DKSM_EXP) )then
         write(iout,*)'CD_dksm_exp_mo: Explicit derivative Kohn-Sham ',
     &                'matrices after DFT:'
         write(iout,*) 
         do i=1,npert
            write(iout,*)'CD_dksm_exp_mo: alpha dKS',i
            write(iout,*) 
            call prtri(fxa_mo(1,i),nvec)
         enddo
         if (.not.rks_sw) then
            do i=1,npert
               write(iout,*)'CD_dksm_exp_mo: beta dKS',i
               write(iout,*) 
               call prtri(fxb_mo(1,i),nvec)
            enddo
         endif
      endif

      cd_dksm_exp_mo = 0

      return
      end
C **********************************************************************
c
c   integer function CD_hess_ao - Driver for evaluation of the
c                                 explicit 2nd derivative of the 
c                                 exchange-correlation energy with 
c                                 respect to the nuclear coordinates.
c
c    Arguments:
c
c     memory_int,    S   base for dynamic memory allocation (integer)
c     memory_fp,     S   base for dynamic memory allocation (real*8)
c     adenm,         I   alpha density or total density 
c     bdenm,         I   beta  density or not used
c     hess          I/O  hessian matrix
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_hess_ao(memory_int,memory_fp,
     &     adenm,bdenm,hess,
     &     extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_KS)
      REAL adenm(*)
      REAL bdenm(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL hess(3*natoms,3*natoms)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, npert, nao
      integer null
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer allocate_memory2
      logical opg_root
      integer cd_update_geom
      integer max_array
      character *8  fnm
      character *10 snm
      data fnm/"global.m"/
      data snm/"CD_hess_ao"/
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      if(opg_root() .and. print_sw(DEBUG_HESS) )then
         write(iout,*)'CD_hess_ao: alpha density matrix'
         write(iout,*) 
         call prtri(adenm,nao)
         if (.not.rks_sw) then
            write(iout,*)'CD_hess_ao: beta density matrix'
            write(iout,*) 
            call prtri(bdenm,nao)
         endif
         write(iout,*) 'CD_hess_ao: Hessian matrix before DFT:'
         write(iout,*) 
         call prsqm(hess,3*natoms,3*natoms,3*natoms,iout)
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        npert=3*natoms
        mxp=200

        idum       = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt    = allocate_memory2(3*idum,'d',fnm,snm,'apts')
        awts_pt    = allocate_memory2(idum,'d',fnm,snm,'awts')
        idum       = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt    = allocate_memory2(ngtypes*idum,'d',fnm,snm,'prpt')
        prwt_pt    = allocate_memory2(ngtypes*idum,'d',fnm,snm,'prwt') 

        ra2_val_pt  = allocate_memory2(mxp*natoms*2,'d',fnm,snm,
     &                                 'ra2_val')
        ra2_comp_pt = allocate_memory2(mxp*natoms*3,'d',fnm,snm,
     &                                 'ra2_comp')
        rho_pt  = allocate_memory2(mxp*2,'d',fnm,snm,'rho')
        grho_pt = allocate_memory2(mxp*2*3,'d',fnm,snm,'grho')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       0,0,0,                           ! no nvec,naocc,nbocc
     &       memory_int(null),                ! no chf_pert_atms
     &       npert,                           ! no perturbations
     &       .true.,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       memory_fp(null),memory_fp(null), ! no avec,bvec
     &       adenm,bdenm,
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       hess,
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .false., .false., .false.,
     &       .false.,.false.,.false.,.false.,.true.,
     &       mxp,.true.,.false.,extwr_sw,0.0d0,iout,dummy)

        call free_memory2(grho_pt,'d',fnm,snm,'grho')
        call free_memory2(rho_pt,'d',fnm,snm,'rho')
        call free_memory2(ra2_comp_pt,'d',fnm,snm,
     &                    'ra2_comp')
        call free_memory2(ra2_val_pt,'d',fnm,snm,
     &                    'ra2_val')
        call free_memory2(prwt_pt,'d',fnm,snm,'prwt')
        call free_memory2(prpt_pt,'d',fnm,snm,'prpt')
        call free_memory2(awts_pt,'d',fnm,snm,'awts')
        call free_memory2(apts_pt,'d',fnm,snm,'apts')
      endif

      if(opg_root() .and. print_sw(DEBUG_HESS) )then
         write(iout,*) 'CD_hess_ao: Hessian matrix after DFT:'
         write(iout,*) 
         call prsqm(hess,3*natoms,3*natoms,3*natoms,iout)
      endif

      cd_hess_ao = 0

      return
      end
C **********************************************************************
c
c   integer function CD_hess_mo - Driver for evaluation of the
c                                 explicit 2nd derivative of the 
c                                 exchange-correlation energy with 
c                                 respect to the nuclear coordinates.
c
c    Arguments:
c
c     memory_int,    S   base for dynamic memory allocation (integer)
c     memory_fp,     S   base for dynamic memory allocation (real*8)
c     adenm,         I   alpha density or total density 
c     bdenm,         I   beta  density or not used
c     hess          I/O  hessian matrix
c     extwr_sw       I   switch for output in quadrature
c
C **********************************************************************

      integer function CD_hess_mo(memory_int,memory_fp,
     &     nvec,naocc,nbocc,avec,bvec,hess,
     &     extwr_sw,iout)
      implicit none
c
c     Parameters:
c
INCLUDE(common/dft_parameters) 
      integer ao_tag
      parameter (ao_tag=1)
c
c     Inputs:
c
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_basis)
      integer ig
      parameter (ig=G_KS)
      integer nvec,naocc,nbocc
      REAL avec(*)
      REAL bvec(*)
      logical extwr_sw
      integer iout
c
c     Outputs:
c
      REAL hess(3*natoms,3*natoms)
c
c     Workspace:
c
      integer memory_int(*)
      REAL memory_fp(*)
c
c     Local:
c
      integer apts_pt,awts_pt,prpt_pt,prwt_pt,i,j
      integer bfnval_pt,bfngval_pt,bfnhess_pt
      integer ra2_val_pt, ra2_comp_pt, wt_pt
      integer rho_pt, grho_pt
      integer mxp
      integer idum, npert, nao
      integer null
      REAL dummy
c
c     Functions:
c
      integer null_memory
      integer allocate_memory
      logical opg_root
      integer cd_update_geom
      integer max_array
c
c     Code:
c
      nao = BL_basis_size(ao_tag)
      if(opg_root() .and. print_sw(DEBUG_HESS) )then
         write(iout,*)'CD_hess_mo: alpha vectors'
         write(iout,*) 
         call prsqm(avec,nao,nvec,nao,iout)
         if (.not.rks_sw) then
            write(iout,*)'CD_hess_mo: beta vectors'
            write(iout,*) 
            call prsqm(bvec,nao,nvec,nao,iout)
         endif
         write(iout,*) 'CD_hess_mo: Hessian matrix before DFT:'
         write(iout,*) 
         call prsqm(hess,3*natoms,3*natoms,3*natoms,iout)
      endif
      null = null_memory()
c
C    ===== Form the gradients due to the coulomb part   =====
c          (only available for coulomb fit at the moment)
c
      if (kqua_sw) then
c
c       length of work arrays over quadrature points
c
        npert=3*natoms
        mxp=200

        idum       = max_array(angpt_radzn_num(1,1,ig),maxradzn*ngtypes)
        apts_pt    = allocate_memory(3*idum,'d')
        awts_pt    = allocate_memory(idum,'d')
        idum       = max_array(radpt_num(1,ig),ngtypes)
        prpt_pt    = allocate_memory(ngtypes*idum,'d')
        prwt_pt    = allocate_memory(ngtypes*idum,'d') 

        ra2_val_pt = allocate_memory(mxp*natoms*2,'d')
        ra2_comp_pt = allocate_memory(mxp*natoms*3,'d')
        rho_pt = allocate_memory(mxp*2,'d')
        grho_pt = allocate_memory(mxp*2*3,'d')

        call exquad(memory_fp,memory_int,
     &       ig,
     &       ao_tag,
     &       BL_basis_size(ao_tag),
     &       nvec,naocc,nbocc,
     &       memory_int(null),                ! no chf_pert_atms
     &       npert,                           ! no perturbations
     &       .true.,
     &       memory_fp(apts_pt),memory_fp(awts_pt),
     &       memory_fp(prpt_pt),memory_fp(prwt_pt),
     &       avec,bvec,
     &       memory_fp(null),memory_fp(null), ! no adenm,bdenm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO S
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO u
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO P
     &       memory_fp(null),memory_fp(null), ! no alpha/beta KS matrix
     &       memory_fp(null),                 ! no gradient
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO rhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO lhs
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm
     &       memory_fp(null),memory_fp(null), ! no alpha/beta AO dksm_x
     &       memory_fp(null),memory_fp(null), ! no alpha/beta MO dksm_x
     &       hess,
     &       memory_fp(ra2_val_pt),
     &       memory_fp(ra2_comp_pt),
     &       memory_fp(rho_pt),
     &       memory_fp(grho_pt),
     &       .false., .false., .false.,
     &       .false.,.false.,.false.,.false.,.true.,
     &       mxp,.false.,.true.,extwr_sw,0.0d0,iout,dummy)

        call free_memory(grho_pt,'d')
        call free_memory(rho_pt,'d')
        call free_memory(ra2_comp_pt,'d')
        call free_memory(ra2_val_pt,'d')
        call free_memory(prwt_pt,'d')
        call free_memory(prpt_pt,'d')
        call free_memory(awts_pt,'d')
        call free_memory(apts_pt,'d')
      endif

      if(opg_root() .and. print_sw(DEBUG_HESS) )then
         write(iout,*) 'CD_hess_mo: Hessian matrix after DFT:'
         write(iout,*) 
         call prsqm(hess,3*natoms,3*natoms,3*natoms,iout)
      endif

      cd_hess_mo = 0

      return
      end
      subroutine aclear_dp(array,n,value)
C **********************************************************************
C *Description:                                                        *
C *Set array to value. Double precision version.                       *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations                                                        *
C *                                                                    *
C *In variables
      integer n
      REAL value
C *In/out variables                                                    *
      REAL array(*)
C *Local variables                                                     *
      integer i, m, mp1
C *End declarations                                                    *
C **********************************************************************
      m = mod(n,7)
      if( m .eq. 0 ) go to 40
      do 30 i = 1,m
        array(i) = value
   30 continue
      if( n .lt. 7 ) return
   40 mp1 = m + 1
      do 50 i = mp1,n,7
        array(i)     = value
        array(i + 1) = value
        array(i + 2) = value
        array(i + 3) = value
        array(i + 4) = value
        array(i + 5) = value
        array(i + 6) = value
   50 continue
      return
      end
      subroutine aclear_int(array,num_elements,value)
C **********************************************************************
C *Description:                                                        * 
C *Set array to value. Integer version.                                *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations                                                        *
C *                                                                    *
C *In variables
      integer num_elements
      integer value
C *In/out variables                                                    *
      integer array(num_elements)
C *Local variables                                                     *
      integer counter
C *End declarations                                                    *
C **********************************************************************
      do counter=1,num_elements
        array(counter)=value
      enddo
      return
      end
      subroutine acopy_dp(array1,array2,num_elements)
C **********************************************************************
C *Description:                                                        *
C *Copy one array into another                                         *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations                                                        *
C *                                                                    *
C *In variables
      integer num_elements
      REAL array1(num_elements)
C *In/out variables                                                    *
      REAL array2(num_elements)
C *Local variables                                                     *
      integer counter
C *End declarations                                                    *
C **********************************************************************
      do counter=1,num_elements
        array2(counter)=array1(counter)
      enddo
      return
      end
      subroutine text_process(input_channel,tot)
C **********************************************************************
C *Description:                                                        *
C *
C **********************************************************************

      return
      end
      function dij2(acoords,bcoords)
C **********************************************************************
C *Description:                                                        *
C *Calculate distance vector (Rab2) between two points.                *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations                                                        *
C *                                                                    *
C *In variables                                                        *
      REAL acoords(3),bcoords(3)
C *Out function                                                        *
      REAL dij2
C *Local variables                                                     *
      REAL rx,ry,rz
C *End declarations                                                    *
C **********************************************************************
      rx=(acoords(1)-bcoords(1))
      ry=(acoords(2)-bcoords(2))
      rz=(acoords(3)-bcoords(3))
      dij2=rx*rx+ry*ry+rz*rz
      return
      end

      function max_array(array,nelements)
      implicit none
      integer array(*)
      integer nelements
      integer max_array
      integer itmp1,lele
      itmp1=0
      do lele=1,nelements
        itmp1=max(array(lele),itmp1)
      enddo
      max_array=itmp1
      return
      end
      function read_command(in_ch,ival,rval,end_sw)
C **********************************************************************
C *Description:                                                        *
C *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations                                                        *
C *                                                                    *
C *In variables                                                        *
      integer in_ch
C *Out function                                                        *
      character*4 read_command
      logical end_sw
      integer ival
      REAL rval
C *Local variables
      integer ptr
      character*100 charc
C *End declarations                                                    *
C **********************************************************************
      ptr=0 
      read(in_ch,*)charc
      if(charc(1:3).eq.'end'.or.charc(1:3).eq.'END') end_sw=.true.
C      write(6,*) charc
C5     ptr=ptr+1
C      if(charc(ptr:ptr).eq.' ') goto 10
C      goto 5
C10    continue 
      read_command=charc(1:4)
      return
      end
      subroutine ztoname(iz,yname)
      implicit none
      integer iz
      character*4 yname
      character*4 periodic_table(0:118)
      data periodic_table /
     +     'BQ',
     1     'H' ,'He',
     2     'Li','Be','B ','C' ,'N' ,'O' ,'F' ,'Ne',
     3     'Na','Mg','Al','Si','P ','S ','Cl','Ar',
     4     'K' ,'Ca','Sc','Ti','V' ,'Cr','Mn','Fe','Co','Ni','Cu','Zn',
     4     'Ga','Ge','As','Se','Br','Kr',
     5     'Rb','Sr','Y' ,'Zr','Nb','Mo','Tc','Ru','Rh','Pd','Ag','Cd',
     5     'In','Sn','Sb','Te','I' ,'Xe',
     6     'Cs','Ba','La','Ce','Pr','Nd','Pm','Sm','Eu','Gd','Tb','Dy',
     6     'Ho','Er','Tm','Yb','Lu','Hf','Ta','W' ,'Re','Os','Ir','Pt',
     6     'Au','Hg','Tl','Pb','Bi','Po','At','Rn',
     7     'Fr','Ra','Ac','Th','Pa','U' ,'Np','Pu','Am','Cm','Bk','Cf',
     7     'Es','Fm','Md','No','Lr','Unq','Unp','Unh','Uns','Uno','Une',
     7     ' ',' ',' ',' ',' ',' ',' ',' ',' '/
      if (0.le.iz.and.iz.le.118) then
         yname = periodic_table(iz)
      else
         yname = ' '
      endif
      end
      subroutine ccpdft_banner(iout)
C **********************************************************************
C *Description:                                                        *        
C *Write out CCP1 DFT banner                                           *
C **********************************************************************
      implicit none
      integer iout
C **********************************************************************
C *Formats
1000  format(2x,'*******************************************************
     +',
     &'**********************')
1010  format(2x,'**** CCP1 DFT MODULE - GAMESS VERSION                  
     +',
     &'                  ****')
1020  format(2x,'****                                                   
     +',
     &'                  ****')
1030  format(2x,'**** Huub van Dam, CCLRC Daresbury Laboratory         
     +',
     &'                  ****') 
C *End formats
C **********************************************************************
      write(iout,1000)
      write(iout,1010)
      write(iout,1020)
      write(iout,1030)
      write(iout,1000)
      return
      end
c
c  $Author: hvd $ $Revision: 5919 $ $Date: 2009-03-31 15:11:24 +0200 (Tue, 31 Mar 2009) $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/dft/global.m,v $
c
      subroutine ver_dft_global(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/dft/global.m,v $
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
