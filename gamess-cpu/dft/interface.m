c
c  CCP1 DFT API
c
c  Active functions
c  ================
c
c  CD_defaults
c
c      Set the internal flags in the DFT code to their default 
c      values. Should be called before any other CCP1 DFT function
c
c
c  CD_init
c
c      initialisation. Must be called after the molecular
c      geometry and AO basis set has been established, and after the
c      control data has been provided.
c
c
c
c
c  CD_energy
c
c      Energy and fock matrix construction.
c
c   CD_set_2e()
c   CD_reset_2e()
c
c  Switch on/off the modifications to the two-electron integral
c  routines.
c
c
c  CD_forces
c
c     Force evaluation
c
c  Control Functions
c  =================
c
c  These functions should be called after CD_defaults, and before 
c  CD_init  
c  They modify the type of calculation that is to be performed.
c
c    integer function CD_2e_store(imemory)
c    integer function CD_request()
c    integer function CD_hfexon()
c    integer function CD_ldaon
c    integer function CD_becke88on
c    integer function CD_corroff
c    integer function CD_vwnon
c    integer function CD_vwnrpaon
c    integer function CD_lypon
c    integer function CD_pz81on
c    integer function CD_p86on
c    integer function CD_bp86on
c    integer function CD_b3lypon
c    integer function CD_hcthon
c    integer function CD_b97_1on
c    integer function CD_b97_2on
c    integer function CD_b97on
c    integer function CD_mix
c    integer function CD_set_weight
c    integer function CD_gradquad(switch)
c    integer function CD_screen
c    integer function CD_lebedevon(gtyp,nang)
c    integer function CD_euleron(nradial)
c    integer function CD_gausslon(gtyp,theta,phi)
c    integer function CD_radial_zones(nzns,nang(*),bnd(*))
c    integer function CD_MHL_ang_prune(gtyp)
c    integer function CD_conv_prune_on()
c    integer function CD_gridscale(factor)
c    integer function CD_jmulton
c    integer function CD_pener(itol)
c    integer function CD_over(itol)
c    integer function CD_schwarz(itol)
c    integer function CD_pole(itol)
c    integer function CD_accuracy(igrid,level)
c    integer function CD_warn(igrid,tol)
c    integer function CD_defaults_old
c    integer function CD_import_geom(natom,nelec,coords,atomicno)

c
c  Enquiry functions
c  =================
c
c  These functions may be called from the main code and may ne
c  used to make decisions based on the internal data structures
c  of the DFT module.
c
c  They should not be called before CD_init
c
c   CD_active  
c      true if this is a DFT calculation. Note that this doesn't give
c      any information on the exact point in the calculation, ie it
c      will return true even when the main code is in the guess routines
c      etc
c
c  Fock builder control options
c
c      These options must be used if the 2-electron integral part of the
c      main code is providing part of the fock matrix
c
c      Note that until CD_set_2e() is called these will return values
c      corresponding to a HF calculation.
c
c    CD_2e - A switch to test if a modified fock builder is in operation
c      if this returns .false. the mainline code can skip tests on the 
c      following control functions to save time.  However, in this case 
c      the functions will return sensible values for a HF calculation
c      anyway.
c
C    logical function CD_HF_exchange
c    real*8  CD_HF_exchange_weight
c    logical function CD_HF_coulomb
c    logical function CD_HF_coulomb_deriv
c    
c    logical function CD_request_multstate
c
c      logical function IL_test4(p1,p2,q1,q2,ip12_list)
c      logical function IL_test4c(q2x,fac1,fac2, ic)
c      logical function IL_list4(p1,p2,q1,q2,bi_on)
c      logical function IL_Bielectronic(p1,p2,q1)
c      logical function IL_Bielec2(p1,p2,q1,q2)
c      REAL function exad_find(shel)
c      REAL function IL_shlove_tol()
c
c    subroutine CD_print_joboptions
c    
c    integer function CD_debug
c     valid keywords:
c      all
c      ksmatrix
c      timing
c      density
c      forces 
c      memory
c      tr, nr, jfit, norm
c      aobasis, jbasis, kbasis
c      control
c    
c      The default is none
c    
c    integer function CD_set_print_level(level)
c    logical CD_check_print(level)
c    logical function CD_HF_exchange
c    real*8  CD_HF_exchange_weight
c    logical function CD_HF_coulomb
c    logical function CD_HF_coulomb_deriv
c
c
c  ====== Additional API functions ============
c
c  These interface functions are not called from within
c  gamess, but are used internaly in the DFT code, they may
c  be of value in generating future interfaces
c
c      CD_update_geom
c           store an new geometry
c
c General CCP DFT api
c

      integer function CD_import_geom(atomno,nelec,coords,atomicno)
      implicit none
INCLUDE(common/dft_parameters)
      REAL coords(3,*)
      integer atomicno(*)
      integer atomno,nelec,latm
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_dunlap)
INCLUDE(../m4/common/errcodes)
      if (atomno.gt.max_atom) then
         call gamerr('*** CD_import_geom: atomno.gt.max_atom',
     &        ERR_NO_CODE, ERR_FIXED_DIMENSION, ERR_SYNC, ERR_NO_SYS)
      endif
      do latm=1,atomno
         if (atomicno(latm).lt.0.or.atomicno(latm).gt.118) then
            call caserr(
     &              '*** CD_import_geom: atomic number out of range')
         endif
      enddo
      natoms=atomno
      nelectrons=nelec
      iauto_cnt=0
      do latm=1,natoms
        atom_c(latm,1) = coords(1,latm)
        atom_c(latm,2) = coords(2,latm)
        atom_c(latm,3) = coords(3,latm)
        ian(latm)      = atomicno(latm)
      enddo
      cd_import_geom = 0
      idunlap_called = 0
      return
      end
c
      integer function CD_update_geom(coords)
      implicit none
INCLUDE(common/dft_parameters)
      REAL coords(3,*)
      integer latm
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_dunlap)
      iauto_cnt = 0
      do latm=1,natoms
        atom_c(latm,1) = coords(1,latm)
        atom_c(latm,2) = coords(2,latm)
        atom_c(latm,3) = coords(3,latm)
      enddo
      cd_update_geom = 0
      idunlap_called = 0
      return
      end

c     integer function CD_defaults (return type defined in ccpdft.hf77)

      function CD_defaults(iout)

      implicit none
      integer iout
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_xc)
INCLUDE(common/dft_iofile)
INCLUDE(common/dft_intctl)
INCLUDE(common/dft_dunlap)
c
      integer null_memory
c
c temp fix to get print level API parameters
c
INCLUDE(common/ccpdft.hf77)

      integer i, j, it
c
c  default mode is disabled
c
      ccpdft_sw  = .false.
      active_sw  = .false.
      dft2e_sw   = .false.
c
c for debugging, exits after KS build to
c avoid modifying dumpfile
c
      abort_sw = .false.
c
c default function is BLYP
c
      if (CD_set_functional('blyp').ne.0) then
         call caserr("CD_defaults messed up")
      endif
C *
C *Default module switches
C *
      jfit_sw     = .false.
      jfitg_sw    = .false.
      jown_sw     = .false.
      cmm_sw      = .false.
      kqua_sw     = .true.
      kfit_sw     = .false.
      kown_sw     = .false.
      rks_sw  = .true.
      mult_sw     = .false.
C *
C * Other switches
C *
      optim_sw = .false.
c     above is used in global.m to allocate space for basis function
c     hessian
      triangle_sw = .false.
c     above is used in the gradient fit
C *
C *Default grid options
C *
      grid_generation = 1
      ngtypes = 0
      do i = 1, max_atom
         gtype_num(i) = DFT_UNDEF
      enddo
c     clear no. grid points for all rows
      do i = 1, 7
         radnpt_row(i) = DFT_UNDEF
         angnpt_row(i) = DFT_UNDEF
      enddo
      do it = 1, max_grids
         do i = 0, max_gtype
            psitol(i,it)             = dble(DFT_UNDEF)
            warntol(i,it)            = dble(DFT_UNDEF)
            radm_num(i,it)           = dble(DFT_UNDEF)
            grid_scale(i,it)         = dble(DFT_UNDEF)
            grid_atom_radius(i,it)   = dble(DFT_UNDEF)
            weight_atom_radius(i,it) = dble(DFT_UNDEF)
            prune_atom_radius(i,it)  = dble(DFT_UNDEF)
            screen_atom_radius(i,it) = dble(DFT_UNDEF)
            do j = 1, maxradzn-1
               bnd_radzn(j,i,it)        = dble(DFT_UNDEF)
               angpt_radzn_num(j,i,it)  = DFT_UNDEF
               phipt_radzn_num(j,i,it)  = DFT_UNDEF
               thetpt_radzn_num(j,i,it) = DFT_UNDEF
            enddo
            angpt_radzn_num(maxradzn,i,it)  = DFT_UNDEF
            phipt_radzn_num(maxradzn,i,it)  = DFT_UNDEF
            thetpt_radzn_num(maxradzn,i,it) = DFT_UNDEF
            radzones_num(i,it)     = DFT_UNDEF
            ang_prune_scheme(i,it) = DFT_UNDEF
            rad_grid_scheme(i,it)  = DFT_UNDEF
            ang_grid_scheme(i,it)  = DFT_UNDEF
            radpt_num(i,it)        = DFT_UNDEF
            gaccu_num(i,it)        = DFT_UNDEF
         enddo
         weight_scheme(it) = DFT_UNDEF
c        test against density on grid batch
         rhotol(it) = dble(DFT_UNDEF)
c        test for an individual density matrix element
         dentol(it) = dble(DFT_UNDEF)
c        test against the weight of a grid point
         wghtol(it) = dble(DFT_UNDEF)
      enddo ! it
      gaccu_num(0,G_KS)  = GACC_MEDIUM
      gaccu_num(0,G_CPKS)= GACC_LOW
      rad_scale_scheme   = SC_MK
      conv_prune_sw      = .false.
      gradwght_sw        = .false.
      sort_points_sw     = .true.
      ignore_accuracy_sw = .false.
c
c     Still under development, but will be enabled by default
c     as part of "quadrature medium"
c
      screen_sw = .true.
c
c     Multipole code accuracy
c
      poleexp_num=4
      over_tol=6
      pener_tol=6
      schwarz_tol=-1
      tttt2=log(0.1d0)*dble(pener_tol)-1.5d0*log(2.0d0)
c
c     Settings for Dunlap Coulomb fit storage
c     The large values for the "pointers" aim triggering a segmentation
c     fault if one tries to use an uninitialised "pointer" by accident.
c
      ocfit_sw       = .false.
      icfit_pt       = null_memory()
      iite2c_stored  = null_memory()
      iite3c_stored  = null_memory()
      ite2c_store    = null_memory()
      ite3c_store    = null_memory()
      ncfit          = 0
      nte2c_shl      = 0
      nte3c_shl      = 0
      nte2c_int      = 0
      nte3c_int      = 0
      idunlap_called = 0
c
c     2-electron integral and derivative integral accuracy
c
c     0 denotes values set locally from _dft versions
c
      icut_dft  = 9
      itol_dft  = 20
      icutd_dft = 10
      itold_dft = 20

      icut_2c = 0  
      itol_2c = 0
      icutd_2c = 0
      itold_2c = 0
      icut_3c = 0 
      itol_3c = 0
      icutd_3c = 0
      itold_3c = 0
      icut_4c = 0
      itol_4c = 0
      icutd_4c = 0
      itold_4c = 0
c
c     print control
c
      do i=1,MAX_DEBUG
        print_sw(i) = .false.
      enddo
      debug_sw = .false.
c
c     print stack
c
      print_stack_depth = 1
      current_print_level(1) = PRINT_DEFAULT
c
c     output stream
c
      iwr = iout

      CD_defaults=0
      return
      end

c
c  Functions to set the internal state of the DFT code
c               ======================

c
c  CD_init - start DFT calculation
c  by this point all settings should have been made
c
      function CD_init(memory_fp,iout)

      implicit none

INCLUDE(common/ccpdft.hf77)
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_xc)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_intctl)
      REAL memory_fp(*)
      integer iout
      integer matrix_pt
      integer allocate_memory

      integer ao_tag,jf_tag,kf_tag
      integer ierror

      integer i

      logical opg_root

      logical rhf_sw, opshell_sw

_IF(taskfarm)
      character*10 ch_gnodeid
      character*132,optdft_filename
      integer global_nodeid, len
_ENDIF

      rhf_sw = .true.
      opshell_sw = .false.

      if (.not. active_sw) then
        CD_init = 0
        return
      endif

      if ((jfit_sw.or.jfitg_sw).and.CD_has_HF_exchange()) then
        CD_init = 1
        if (opg_root()) then
          write(6,*)"Selected coulomb fitting with a hybrid functional "
     &             ,"this does not bring any performance benefits."
          write(6,*)"The exact exchange of the hybrid functional ",
     &              "forces all 4-centre 2-electron integrals to be ",
     &              "calculated anyway."
          write(6,*)"Suggest you turn off the coulomb fitting!"
        endif
        call caserr(
     &  "combination of jfit/jfitg AND hybrid functional makes no sense"
     &  )
      endif
        
c
c  set default tolerances for integral codes
c  if the user hasnt explicit set them
c
      if(icut_2c .eq. 0)icut_2c = icut_dft
      if(itol_2c .eq. 0)itol_2c = itol_dft
      if(icut_3c .eq. 0)icut_3c = icut_dft
      if(itol_3c .eq. 0)itol_3c = itol_dft
      if(icut_4c .eq. 0)icut_4c = icut_dft
      if(itol_4c .eq. 0)itol_4c = itol_dft
      if(icutd_2c .eq. 0)icutd_2c = icutd_dft
      if(itold_2c .eq. 0)itold_2c = itold_dft
      if(icutd_3c .eq. 0)icutd_3c = icutd_dft
      if(itold_3c .eq. 0)itold_3c = itold_dft
      if(icutd_4c .eq. 0)icutd_4c = icutd_dft
      if(itold_4c .eq. 0)itold_4c = itold_dft
C 
C Write out basis sets, if requested.
c
c !!! Need to set these tags more carefully 
c
      ao_tag = 1
      jf_tag = 2
      kf_tag = 3
      if(.not.jfit_sw)kf_tag = 2
      if(.not.jfit_sw)jf_tag = -1
      if(.not.kfit_sw)kf_tag = -1

      call order_fill
ccc      call initialise_basis
c
c  initialisation of basis set library
c
      call BL_init

      call interface_gamess(rhf_sw,opshell_sw,ao_tag,iout)

      if (grid_generation.eq.1) then
         call grid_init_gen1
      else if (grid_generation.eq.2) then
         call grid_init_gen2
      else
         call caserr2('CD_init: invalid grid_generation')
      endif
      call grid_sane_check(ao_tag,iout)

      if(opg_root())then
        in_ch=30
_IF(taskfarm)
      write(ch_gnodeid,'(i10)')global_nodeid()

      do i=1,10
         if(ch_gnodeid(i:i).ne.' ') then
            len=i
            go to 1110
         endif
      enddo

 1110 optdft_filename='options.dft.'//ch_gnodeid(len:10)

        open(unit=in_ch,file=optdft_filename,status='unknown',
     &       form='formatted')
_ELSE
        open(unit=in_ch,file='options.dft',status='unknown',
     &       form='formatted')
_ENDIF

      endif

      call basis_library(iout)
      if(opg_root())close(unit=in_ch)
c
c   internal conistency of options
c
      do i=1,max_grids
      if( .not. screen_sw .and.  (weight_scheme(i).eq. WT_SSFSCR) )then
         if(opg_root())write(6,*)'Warning - screening has not been selec
     +ted'
         if(opg_root())write(6,*)'   therefore non-screened weight schem
     +e selected'
         weight_scheme(i) = WT_SSF
      endif
      enddo
c
c normalise coulomb fitting basis
c
      if(jfit_sw) then
        matrix_pt=allocate_memory(BL_basis_size(2),'d')
        call basis_norm(memory_fp,memory_fp(matrix_pt))
        call free_memory(matrix_pt,'d')
      endif
C 
C Write out basis sets, if requested.
c
c !!! Need to set these tags more carefully 
c
      ao_tag = 1
      jf_tag = 2
      kf_tag = 3
      if(.not.jfit_sw)kf_tag = 2
      if(.not.jfit_sw)jf_tag = -1
      if(.not.kfit_sw)kf_tag = -1

      if(opg_root() .and. print_sw(DEBUG_AOBAS))then
         ierror=BL_write_basis(ao_tag,iout)
      endif

      if(opg_root() .and. print_sw(DEBUG_JBAS))then
         if(jfit_sw)then
            ierror=BL_write_basis(jf_tag,iout)
         else
            write(6,*)'warning: debug jbas: No J fitting basis in use'
         endif
      endif
      if(opg_root() .and. print_sw(DEBUG_KBAS))then
         if(kfit_sw)then
            ierror=BL_write_basis(kf_tag,iout)
         else
            write(6,*)'warning: debug kbas: No K fitting basis in use'
         endif
      endif
c
c     fill basato if needed for multipole calculation
c
      call basato_fill(ao_tag)
      CD_init = 0

      return
      end


      integer function CD_request()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      ccpdft_sw = .true.
      active_sw = .true.
      CD_request = 0
      return
      end      
c
c CD_is_rks - Are we using Restricted Kohn Sham mode?
c
      logical function CD_is_rks()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      CD_is_rks=rks_sw
      return
      end
c
c CD_rks - Restricted Kohn Sham mode
c
      integer function CD_rks()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      rks_sw  = .true.
      CD_rks=0
      return
      end
c
c CD_uks - Unrestricted Kohn Sham mode
c
      integer function CD_uks()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      rks_sw  = .false.
      CD_uks=0
      return
      end
c
c CD_4c2eon: Switch on explicit coulomb calculation
c
      integer function CD_4c2eon()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      jfit_sw  = .false.
      jfitg_sw  = .false.
      jown_sw  = .false.
      CD_4c2eon=0
      return
      end
c
c CD_jfiton: Switch on coulomb fitting
c
      integer function CD_jfiton(omem)
      implicit none
      logical omem
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_dunlap)
      jfit_sw  = .true.
      jown_sw  = .true.
      ocfit_sw = omem
      CD_jfiton=0
      return
      end
c
c CD_jfitoff: Switch off coulomb fitting
c
      integer function CD_jfitoff()
      implicit none
      logical omem
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_dunlap)
      jfit_sw  = .false.
      CD_jfitoff=0
      return
      end
c
c CD_is_jfiton: Enquire whether Jfit is on
c
      logical function CD_is_jfiton()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_dunlap)
      CD_is_jfiton = jfit_sw
      return
      end
c
c CD_is_jfitmem: Enquire whether Jfit is the memory for storing 
c                3-centre integrals.
c
      logical function CD_is_jfitmem()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_dunlap)
      CD_is_jfitmem = ocfit_sw
      return
      end
c
c CD_jfitgon: Switch on coulomb fitting for the gradient
c
      integer function CD_jfitgon()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      jfitg_sw  = .true.
      jown_sw  = .true.
      CD_jfitgon=0
      return
      end
c
C CD_jfit_init1: Allocate storage for Schwarz data and 
c                fitting coefficients as appropriate.
c
      integer function CD_jfit_init1()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mbasis)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_dunlap)
c
c     local variables
c
_IF(ma)
c     integer MT_DBL
c     parameter (MT_DBL = 1013)
_ENDIF
      integer nnodes, cd_tag, ao_tag, ii, jj, icnt
      integer mem_avail, ohdmem
      character*11 fnm
      character*13 snm
c
c     Functions 
c
      integer lenwrd, allocate_memory2, igmem_max_memory
      external lenwrd, allocate_memory2, igmem_max_memory
      integer memory_overhead
      external memory_overhead
_IF(parallel)
      integer ipg_nnodes
      external ipg_nnodes
_ENDIF
      data fnm/"interface.m"/
      data snm/"CD_jfit_init1"/
c
      CD_jfit_init1 = 0
      ohdmem = memory_overhead()
      ao_tag = bset_tags(1)
      cd_tag = bset_tags(2)
      if (jfit_sw.and.ocfit_sw) then
_IF(parallel)
         nnodes    = ipg_nnodes()
_ELSE
         nnodes    = 1
_ENDIF
_IF(ga)
         nte2c_shl = 0 
_ELSE
c
c        Static load-balancing does not provide a round-robin
c        distribution of shell pairs. The reason is that for ii,kk
c        shell pairs the ii indeces are distributed rather than the
c        ii,kk. So we need to calculate the largest partial triangle
c        that can be obtained by picking out every nnodes-th column.
c
         nte2c_shl = 0
         do jj = 0, nnodes-1
           icnt = 0
           do ii = 1+jj, nshell(cd_tag), nnodes
             icnt = icnt + ii
           enddo
           nte2c_shl = max(nte2c_shl,icnt)
         enddo
_ENDIF
c
         nte3c_shl = nshell(ao_tag)*(nshell(ao_tag)+1)/2
         nte3c_shl = (nte3c_shl+nnodes-1)/nnodes
         nte3c_shl = nte3c_shl*nshell(cd_tag)
c
         ncfit     = totbfn(bset_tags(2))
c
         mem_avail = igmem_max_memory() 
     +               - nte2c_shl - nte3c_shl 
     +               - ncfit - 3*ohdmem
c
         if (mem_avail.ge.0) then
_IFN(ga)
            iite2c_stored = allocate_memory2(nte2c_shl,'i',fnm,snm,
     +                      "iite2c")
_ENDIF
            iite3c_stored = allocate_memory2(nte3c_shl,'i',fnm,snm,
     +                      "iite3c")
            icfit_pt      = allocate_memory2(ncfit,'d',fnm,snm,"icfit")
c
         else
c
c...        Return the number of words lacking to complete successfully
c
            CD_jfit_init1 = -mem_avail+0
         endif
      endif
      end
c
c CD_jfit_clean1: The clean-up counter part of CD_jfit_init1.
c
      integer function CD_jfit_clean1()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_dunlap)
      integer null_memory
      character*11 fnm
      character*14 snm
      data fnm/"interface.m"/
      data snm/"CD_jfit_clean1"/
      CD_jfit_clean1 = 0
      if (jfit_sw.and.ocfit_sw) then
         call free_memory2(icfit_pt,'d',fnm,snm,"icfit")
         call free_memory2(iite3c_stored,'i',fnm,snm,"iite3c")
_IF(ga)
         call post_fit()
_ELSE
         call free_memory2(iite2c_stored,'i',fnm,snm,"iite2c")
_ENDIF
         icfit_pt      = null_memory()
         iite3c_stored = null_memory()
         iite2c_stored = null_memory()
         ncfit         = 0
         nte2c_shl     = 0
         nte3c_shl     = 0
      endif
      end
c
c CD_jfit_init2: Allocate storage for the Coulomb matrix and the
c                2- and 3-centre integrals as appropriate. Passed
c                down is currently available memory. This is the 
c                remaining memory after taking away the amount of memory
c                required by the SCF program. We still need to subtract
c                the memory required by the various parts of the DFT 
c                code. The unit of memory is a word (REAL).
c
      integer function CD_jfit_init2(imem_avail,imem_required,iout)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mbasis)
INCLUDE(common/dft_dunlap)
INCLUDE(common/dft_xc)
c
_IF(ma)
c     integer MT_DBL
c     parameter (MT_DBL = 1013)
_ENDIF
c
c     Parameters
c
      integer imem_avail, imem_required
      integer iout
c
c     Functions
c
      integer  BL_basis_size, BL_num_types, BL_get_atom_type, lenwrd
      external BL_basis_size, BL_num_types, BL_get_atom_type, lenwrd
c
      integer  max_array
      external max_array
c
      integer  allocate_memory2, ipg_nnodes, ipg_nodeid
      external allocate_memory2, ipg_nnodes, ipg_nodeid
c
      integer  memory_overhead, null_memory
      external memory_overhead, null_memory
c
      integer  num_3c_ints
      external num_3c_ints
_IF(ma)
c     integer  MA_sizeof_overhead
c     external MA_sizeof_overhead
_ENDIF
c
c     Local variables
c
      integer maxmem, curmem, ohdmem
      integer ao_tag, cd_tag, kf_tag, ltri
c
      integer n_iscr, n_iscrb
      integer nvqr, nschwarz_cd, nschwarz_ao, n_tr, n_nr
      integer nnodes, n_g2c, n_g2cinv, n_gtmp, n_gtmp2
      integer n_lev, n_ltmp, n_hma, n_hmz, n_myelem, n_his, n_node
      integer n_elemz, n_isize, n_rsize, n_ptrsze
      integer n_null, n_iso, n_gout, n_scratch, n_index, n_iiso
      integer n_nprm, n_angm, n_hyb, n_ctre, n_pstr, n_alp, n_cc
      integer n_s, n_expons, n_d, n_e, n_f, n_sigma
      integer nbuff
      integer n_apts, n_awts, n_prpt, n_prwt
      integer n_bfnval, n_bfngval, n_bfnhess, n_bfnuse, n_bfnpnum
      integer n_bfnpide
      integer n_cent, n_alpha, n_coco
      integer n_ra2_val, n_ra2_comp, n_wt, n_xc_ept, n_xc_vpt, n_xc_dvpt
      integer n_rho, n_grho
      integer n_gwt, n_ishll, n_iwrk2, n_iwrk3, n_iwrk1
      integer n_fitmat, n_ckfit, n_indx, n_abfnval
      integer ntot, n2e, n3e
      integer lenw
c
      integer max_pr, max_angm
      integer idum, i
      integer mxp
      integer latm, atom_num, atmt, inmtyp
      integer xbfn_num
c
      character*11 fnm
      character*13 snm
      data fnm/"interface.m"/
      data snm/"CD_jfit_init2"/
c
      CD_jfit_init2 = 0
      maxmem = 0
      curmem = 0
      lenw = lenwrd()
_IF(parallel)
      nnodes = ipg_nnodes()
_ELSE
      nnodes = 1
_ENDIF
      ohdmem = memory_overhead()
      if (jfit_sw.and.ocfit_sw) then
c
c        First we need to establish how much memory there will be
c        left for the 2- and 3-centre integrals.
c        (My approach is that I simply walk through the call tree
c         of CD_energy and count the memory allocated (in words))
c
         ao_tag = 1
         ltri = ((BL_basis_size(ao_tag)+1)*BL_basis_size(ao_tag))/2
         n_iscr = ltri + ohdmem
         if (rks_sw) then
            curmem = curmem + n_iscr
         else
            curmem = curmem + 2*n_iscr
         endif
         maxmem = max(maxmem,curmem)
c
c        call jfit_dunlap
c
            ao_tag      = bset_tags(1)
            cd_tag      = bset_tags(2)
            nvqr        = totbfn(cd_tag)**2 + ohdmem
            nschwarz_cd = nshell(cd_tag)  + ohdmem
            nschwarz_ao = nshell(ao_tag)**2 + ohdmem
            n_tr        = totbfn(cd_tag) + ohdmem
            n_nr        = totbfn(cd_tag) + ohdmem
c
            curmem = curmem + n_tr
            curmem = curmem + n_nr
c           fitting coefficients now stored in resident memory
_IFN(ga)
            curmem = curmem + nvqr
_ENDIF
            curmem = curmem + nschwarz_cd
            maxmem = max(maxmem,curmem)
_IFN(ga)
c           call jfit_ivform
c
               n_null = 1 + ohdmem
               n_iso  = nshell(2) + ohdmem
               n_gout = 50625 + ohdmem
               curmem = curmem + n_null
               curmem = curmem + n_iso
               curmem = curmem + n_gout
               maxmem = max(maxmem,curmem)
               curmem = curmem - n_gout
               curmem = curmem - n_iso
c
               if (.true.) then ! invert_sw = .false.
c                 call matPack_drv
c
                  n_scratch = totbfn(cd_tag)**2 + ohdmem
                  n_index   = (2*totbfn(cd_tag)+lenw-1)/lenw
     +                      + ohdmem
                  curmem    = curmem + n_scratch 
                  curmem    = curmem + n_index 
                  maxmem    = max(maxmem,curmem)
                  curmem    = curmem - n_index
                  curmem    = curmem - n_scratch
c
c                 return matPack_drv
               endif
c
               curmem = curmem - n_null
c
c           return jfit_ivform
_ELSE
c           call pre_fit
c
c              I am not sure how the GA's allocate matrices but for the
c              next matrices the following sizes seem to be an upper
c              bound to the memory requirements
c
               n_g2c    = totbfn(cd_tag)*((totbfn(cd_tag)+nnodes-1)
     +                    /nnodes) + ohdmem
               n_g2cinv = totbfn(cd_tag)*((totbfn(cd_tag)+nnodes-1)
     +                    /nnodes) + ohdmem
               n_gtmp   = totbfn(cd_tag)*((totbfn(cd_tag)+nnodes-1)
     +                    /nnodes) + ohdmem
               n_iiso   = nshell(2) + ohdmem
               n_gout   = 50625 + ohdmem
               curmem = curmem + n_g2c
               curmem = curmem + n_g2cinv
               curmem = curmem + n_gtmp
               curmem = curmem + n_iiso
               curmem = curmem + n_gout
               maxmem = max(maxmem,curmem)
               curmem = curmem - n_gout
               curmem = curmem - n_iiso
c
c              call dft_invdiag
c
                  n_gtmp2 = totbfn(cd_tag)*(totbfn(cd_tag)+nnodes-1)
     +                      /nnodes + ohdmem
                  n_lev   = totbfn(cd_tag) + ohdmem
                  n_ltmp  = totbfn(cd_tag) + ohdmem
                  curmem = curmem + n_gtmp2
                  curmem = curmem + n_lev
                  curmem = curmem + n_ltmp
                  maxmem = max(maxmem,curmem)
c
c                 call ga_diag_std
c
                     n_hma    = (totbfn(cd_tag)+lenw-1)/lenw
     +                        + ohdmem
                     n_hmz    = (totbfn(cd_tag)+lenw-1)/lenw
     +                        + ohdmem
                     n_node   = (nnodes+lenw-1)/lenw
     +                        + ohdmem
                     n_myelem = ((totbfn(cd_tag)+nnodes-1)/nnodes)
     +                        * totbfn(cd_tag) + ohdmem
                     n_elemz  = ((totbfn(cd_tag)+nnodes-1)/nnodes)
     +                        * totbfn(cd_tag) + ohdmem
                     n_his    = 6*totbfn(cd_tag) + ohdmem
                     curmem   = curmem + n_hma
                     curmem   = curmem + n_hmz
                     curmem   = curmem + n_node
                     curmem   = curmem + n_myelem
                     curmem   = curmem + n_elemz
                     curmem   = curmem + n_his
                     maxmem   = max(maxmem,curmem)
                     curmem   = curmem - n_his
c
c                    Actually we should determine how much memory pdspev
c                    needs as is done in fmemreq. However this gets to 
c                    rather complicated therefore we assume that the 
c                    following size (based on a little experiment) are
c                    about right
c
                     n_isize  = (40*totbfn(cd_tag)+lenw-1)/lenw
     +                        + ohdmem
                     n_rsize  = ((4*totbfn(cd_tag)+nnodes-1)/nnodes)
     +                        * totbfn(cd_tag) + ohdmem
                     n_ptrsze = int(2.5*totbfn(cd_tag)+1)
     +                        + ohdmem
                     curmem   = curmem + n_isize
                     curmem   = curmem + n_rsize
                     curmem   = curmem + n_ptrsze
                     maxmem   = max(maxmem,curmem)
                     curmem   = curmem - n_ptrsze
                     curmem   = curmem - n_rsize
                     curmem   = curmem - n_isize
c
                     curmem   = curmem - n_elemz
                     curmem   = curmem - n_myelem
                     curmem   = curmem - n_node
                     curmem   = curmem - n_hmz
                     curmem   = curmem - n_hma
c
c                 return ga_diag_std
c
                  curmem = curmem - n_ltmp
                  curmem = curmem - n_lev
                  curmem = curmem - n_gtmp2
c
c              return dft_invdiag
c
               curmem = curmem - n_gtmp
c
c           return pre_fit
_ENDIF
            n_iso  = nshell(2)+ohdmem
            n_gout = 50625+ohdmem
            curmem = curmem + nschwarz_ao
            curmem = curmem + n_iso
            curmem = curmem + n_gout
            maxmem = max(maxmem,curmem)
            curmem = curmem - n_gout
            curmem = curmem - n_iso
c
c           call intPack_drv (expand_sw.and.oe1c_int_sw.eq..true.)
c
               n_nprm = (num_bset*maxi_shlA+lenw-1)/lenw+ohdmem
               n_angm = (num_bset*maxi_shlA+lenw-1)/lenw+ohdmem
               n_hyb  = (num_bset*maxi_shlA+lenw-1)/lenw+ohdmem
               n_ctre = (num_bset*maxi_shlA+lenw-1)/lenw+ohdmem
               n_pstr = (num_bset*maxi_shlA+lenw-1)/lenw+ohdmem
               n_alp  = num_bset*maxi_primA+ohdmem
               n_cc   = num_bset*maxi_primA+ohdmem
               curmem = curmem + n_nprm
               curmem = curmem + n_angm
               curmem = curmem + n_hyb
               curmem = curmem + n_ctre
               curmem = curmem + n_pstr
               curmem = curmem + n_alp
               curmem = curmem + n_cc
               maxmem = max(maxmem,curmem)
c
               call scratch_size(2,max_pr,max_angm)
               n_s     = max_pr+ohdmem
               n_expons= max_pr+ohdmem
               n_d     = max_pr*max_angm**2+ohdmem
               n_e     = max_pr*max_angm**2+ohdmem
               n_f     = max_pr*max_angm**2+ohdmem
               n_sigma = max_pr+ohdmem
               curmem  = curmem + n_s
               curmem  = curmem + n_expons
               curmem  = curmem + n_d
               curmem  = curmem + n_e
               curmem  = curmem + n_f
               curmem  = curmem + n_sigma
               maxmem  = max(maxmem,curmem)
               curmem  = curmem - n_sigma
               curmem  = curmem - n_f
               curmem  = curmem - n_e
               curmem  = curmem - n_d
               curmem  = curmem - n_expons
               curmem  = curmem - n_s
c
               curmem = curmem - n_cc
               curmem = curmem - n_alp
               curmem = curmem - n_pstr
               curmem = curmem - n_ctre
               curmem = curmem - n_hyb
               curmem = curmem - n_angm
               curmem = curmem - n_nprm
c
c           return intPack_drv
c
_IF(ga)
            nbuff = totbfn(cd_tag)+ohdmem
            curmem = curmem + nbuff
            maxmem = max(maxmem,curmem)
            curmem = curmem - nbuff
_ELSE
_ENDIF
_IF(ga)
            nbuff = totbfn(cd_tag)+ohdmem
            curmem = curmem + nbuff
            maxmem = max(maxmem,curmem)
            curmem = curmem - nbuff
_ELSE
_ENDIF
            n_iso  = nshell(2)+ohdmem
            n_gout = 50625+ohdmem
            curmem = curmem + n_iso
            curmem = curmem + n_gout
            maxmem = max(maxmem,curmem)
            curmem = curmem - n_gout
            curmem = curmem - n_iso
_IF(ga)
            nbuff = totbfn(cd_tag)+ohdmem
            curmem = curmem + nbuff
            maxmem = max(maxmem,curmem)
            curmem = curmem - nbuff
_ELSE
_ENDIF
            curmem = curmem - nschwarz_ao
            curmem = curmem - nschwarz_cd
_IFN(ga)
            curmem = curmem - nvqr
_ENDIF
            curmem = curmem - n_nr
            curmem = curmem - n_tr
c
c        return jfit_dunlap
c
         if (rks_sw) then
            curmem = curmem - n_iscr
         else
            curmem = curmem - 2*n_iscr
         endif 
c
         if (kqua_sw.or.kfit_sw) then
            idum   = max_array(angpt_radzn_num(1,1,1),maxradzn*ngtypes*
     &                                                max_grids)
            n_apts = 3 * idum + ohdmem
            n_awts = idum + ohdmem
            idum   = max_array(radpt_num(1,1),ngtypes*max_grids)
            n_prpt = ngtypes * idum + ohdmem
            n_prwt = ngtypes * idum + ohdmem
            curmem = curmem + n_apts
            curmem = curmem + n_awts
            curmem = curmem + n_prpt
            curmem = curmem + n_prwt
            maxmem = max(maxmem,curmem)
         endif
c
         if (kqua_sw) then
            mxp = 300
            n_iscr = ltri+ohdmem
            if (rks_sw) then
               n_iscrb = 0
            else
               n_iscrb = ltri
            endif
            n_bfnval  = mxp*BL_basis_size(ao_tag)+ohdmem
            n_bfngval = mxp*3*BL_basis_size(ao_tag)+ohdmem
            if (optim_sw) then
               n_bfnhess = mxp*6*BL_basis_size(ao_tag)+ohdmem
            else
               n_bfnhess = 6+ohdmem
            endif
            n_bfnuse  = (BL_basis_size(ao_tag)+lenw-1)/lenw
     +                + ohdmem
            n_bfnpnum = (BL_basis_size(ao_tag)+lenw-1)/lenw
     +                + ohdmem
            n_bfnpide = (90+lenw-1)/lenw+ohdmem
            curmem = curmem + n_iscr
            curmem = curmem + n_iscrb
            curmem = curmem + n_bfnval
            curmem = curmem + n_bfngval
            curmem = curmem + n_bfnhess
            curmem = curmem + n_bfnuse
            curmem = curmem + n_bfnpnum
            curmem = curmem + n_bfnpide
            maxmem = max(maxmem,curmem)
c
            n_nprm = (maxi_basA+lenw-1)/lenw+ohdmem
            n_angm = (maxi_basA+lenw-1)/lenw+ohdmem
            n_pstr = (maxi_basA+lenw-1)/lenw+ohdmem
            n_cent = (maxi_basA+lenw-1)/lenw+ohdmem
            n_alpha= maxi_primA+ohdmem
            n_coco = maxi_primA+ohdmem
            curmem = curmem + n_nprm
            curmem = curmem + n_angm
            curmem = curmem + n_pstr
            curmem = curmem + n_cent
            curmem = curmem + n_alpha
            curmem = curmem + n_coco
            maxmem = max(maxmem,curmem)
c
            n_ra2_val  = mxp*natoms*2+ohdmem
            n_ra2_comp = mxp*natoms*3+ohdmem
            n_wt       = mxp+ohdmem
            n_xc_ept   = mxp+ohdmem
            n_xc_vpt   = mxp*2+ohdmem
            n_xc_dvpt  = mxp*2*3+ohdmem
            n_rho      = mxp*2+ohdmem
            n_grho     = mxp*2*3+ohdmem
            curmem = curmem + n_ra2_val
            curmem = curmem + n_ra2_comp
            curmem = curmem + n_wt
            curmem = curmem + n_xc_ept
            curmem = curmem + n_xc_vpt
            curmem = curmem + n_xc_dvpt
            curmem = curmem + n_rho
            curmem = curmem + n_grho
            maxmem = max(maxmem,curmem)
c
c           call exquad
c
               inmtyp  = 0
               do latm=1,ngtypes
                  inmtyp = inmtyp + radpt_num(latm,G_KS)
               enddo
               n_ishll = inmtyp + ohdmem
               n_iwrk2 = mxp + ohdmem
               if (gradwght_sw) then
                  if (weight_scheme(G_KS).eq.WT_BECKE.or.
     +                weight_scheme(G_KS).eq.WT_MHL.or.
     +                weight_scheme(G_KS).eq.WT_SSF) then
                     n_gwt = 3*ngridcentres*mxp + ohdmem
                  else
c
c                    I hope 100 near atoms is enough for most cases...
c
                     n_gwt = 3*100*mxp + ohdmem
                  endif
               else
                  n_gwt = 0
               endif
               curmem = curmem + n_ishll
               curmem = curmem + n_iwrk2
               curmem = curmem + n_gwt
               maxmem = max(maxmem,curmem)
c
               if (weight_scheme(G_KS).eq.WT_SSFSCR) then
                  n_iwrk3 = (mxp+lenw-1)/lenw+ohdmem
               else if (weight_scheme(G_KS).eq.WT_MHL4SSFSCR) then
                  n_iwrk3 = (mxp+lenw-1)/lenw+ohdmem
               else if (weight_scheme(G_KS).eq.WT_MHL8SSFSCR) then
                  n_iwrk3 = (mxp+lenw-1)/lenw+ohdmem
               else
                  n_iwrk3 = 0
               endif
               curmem = curmem + n_iwrk3
               maxmem = max(maxmem,curmem)
               curmem = curmem - n_iwrk3
c
               if (screen_sw) then
                  n_iwrk1 = mxp*100 +ohdmem
c                 assuming 100 active basis functions is a reasonable
c                 upper limit during the numerical quadrature.
               else
                  n_iwrk1 = BL_basis_size(ao_tag)+ohdmem
               endif
               curmem = curmem + n_iwrk1
               maxmem = max(maxmem,curmem)
               curmem = curmem - n_iwrk1
c
c               if (grad_sw) then
c                  call caserr('CD_jfit_init2: screw up 1')
c               endif
c
               curmem = curmem - n_gwt
               curmem = curmem - n_iwrk2
               curmem = curmem - n_ishll
c
c           return exquad
c
            curmem = curmem - n_grho
            curmem = curmem - n_rho
            curmem = curmem - n_xc_dvpt
            curmem = curmem - n_xc_vpt
            curmem = curmem - n_xc_ept
            curmem = curmem - n_wt
            curmem = curmem - n_ra2_comp
            curmem = curmem - n_ra2_val
c
            curmem = curmem - n_coco
            curmem = curmem - n_alpha
            curmem = curmem - n_cent
            curmem = curmem - n_pstr
            curmem = curmem - n_angm
            curmem = curmem - n_nprm
c
            curmem = curmem - n_bfnpide
            curmem = curmem - n_bfnpnum
            curmem = curmem - n_bfnuse
            curmem = curmem - n_bfnhess
            curmem = curmem - n_bfngval
            curmem = curmem - n_bfnval
c
            curmem = curmem - n_iscrb
            curmem = curmem - n_iscr
c
         endif
c
         if (kfit_sw) then
            n_iscr = ltri+ohdmem
            xbfn_num = BL_basis_size(kf_tag)**2
            n_fitmat = xbfn_num+ohdmem
            n_ckfit  = BL_basis_size(kf_tag)+ohdmem
            n_indx   = (BL_basis_size(kf_tag)+lenw-1)/lenw
     +               + ohdmem
            n_bfnval = BL_basis_size(ao_tag)+ohdmem
            n_abfnval= BL_basis_size(kf_tag)+ohdmem
            curmem = curmem + n_iscr
            curmem = curmem + n_fitmat
            curmem = curmem + n_ckfit
            curmem = curmem + n_indx
            curmem = curmem + n_bfnval
            curmem = curmem + n_abfnval
            maxmem = max(maxmem,curmem)
            curmem = curmem - n_abfnval
            curmem = curmem - n_bfnval
            curmem = curmem - n_indx
            curmem = curmem - n_ckfit
            curmem = curmem - n_fitmat
            curmem = curmem - n_iscr
         endif
c
         curmem = curmem - n_prwt
         curmem = curmem - n_prpt
         curmem = curmem - n_awts
         curmem = curmem - n_apts
_IF(ga)
c
c        In fact these 2 global arrays are never deallocated
c
         curmem = curmem - n_g2cinv
         curmem = curmem - n_g2c
_ENDIF
c
         if (curmem.ne.0) call caserr('CD_jfit_init2: screw up 2')
c
c        After recent changes we assume that we have the memory
c        requirements right. But we do need to account for the 
c        overheads associated with the 2 memory blocks we are 
c        going to allocate a few lines from this point.
c        
cDEBUG
c        if (imem_required.ne.maxmem) then
c           write(*,*)'*** old and new memory estimates do not match'
c           write(*,*)'imem_required = ',imem_required
c           write(*,*)'maxmem        = ',maxmem       
c        else
c           write(*,*)'imem_required = ',imem_required
c           write(*,*)'maxmem        = ',maxmem
c        endif
cDEBUG
cNEW
         maxmem = imem_required
cNEW
         maxmem = maxmem + 2*ohdmem
c
         ntot = imem_avail - maxmem
c
         if (ntot.ge.2) then
_IF(ga)
            n2e  = 0
_ELSE
            n2e  = (totbfn(cd_tag)+1)*totbfn(cd_tag)/2
_ENDIF
            n3e  = num_3c_ints()
c
c           Calculate the local memory requirement given that the total
c           list of 3-centre integrals is distributed. 
c
            n3e  = (n3e+ipg_nnodes()-1)/ipg_nnodes()
            ntot = min(ntot,n2e+n3e)
_IF(ga)
            nte2c_int = 0
_ELSE
            nte2c_int = int(dble(ntot)*dble(n2e)/(n2e+n3e))
            nte2c_int = max(1,min(ntot-1,nte2c_int))
_ENDIF
            nte3c_int = ntot-nte2c_int
c
            if (ipg_nodeid().eq.0) then
_IFN(ga)
              write(iout,'(" allocate ",i12," words locally for",
     +                     " 2-centre integrals")') nte2c_int
_ENDIF
              write(iout,'(" allocate ",i12," words locally for",
     +                     " 3-centre integrals")') nte3c_int
            endif
_IF(ga)
            ite2c_store = null_memory()
_ELSE
            ite2c_store = allocate_memory2(nte2c_int,'d',fnm,snm,
     +                    "ite2c")
_ENDIF
            ite3c_store = allocate_memory2(nte3c_int,'d',fnm,snm,
     +                    "ite3c")
            if(ite2c_store.eq.0.or.
     +         ite3c_store.eq.0) then
               call caserr('CD_jfit_init2: Huh? Out of memory???')
            endif
         else
c
c...        Return the number of words lacking to complete successfully
c
            CD_jfit_init2 = -ntot+2
         endif
      endif
      end 
c
c CD_jfit_clean2: The clean-up counter part of CD_jfit_init2
c
      integer function CD_jfit_clean2()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_dunlap)
c
      integer null_memory
      external null_memory
c 
      character*11 fnm
      character*14 snm
      data fnm/"interface.m"/
      data snm/"CD_jfit_clean2"/
c
      CD_jfit_clean2 = 0
      if (jfit_sw.and.ocfit_sw) then
          if (
_IFN(ga)
     +        ite2c_store.eq.null_memory().or.
     +        ite2c_store.eq.0            .or.
     +        nte2c_int  .eq.0            .or.
_ENDIF
     +        ite3c_store.eq.null_memory().or.
     +        ite3c_store.eq.0            .or.
     +        nte3c_int  .eq.0) then
             call caserr(
     +          'CD_jfit_clean2: what ever happened to CD_jfit_init2?')
          endif
          call free_memory2(ite3c_store,'d',fnm,snm,"ite3c")
_IFN(ga)
          call free_memory2(ite2c_store,'d',fnm,snm,"ite2c")
_ENDIF
          ite2c_store = null_memory()
          ite3c_store = null_memory()
          nte2c_int   = 0
          nte3c_int   = 0
      endif
      end


      integer function CD_xcfiton()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      kqua_sw  =.false.
      kfit_sw  =.true. 
      kown_sw  =.true.
      CD_xcfiton=0
      return
      end

      integer function CD_abort()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      abort_sw=.true.
      CD_abort=0
      return
      end
 

      integer function CD_screen(oscr,p3,p4,p5)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_xc)
      REAL p3,p4,p5
      logical oscr
c
c enable screening in xc quadrature
c
      screen_sw = oscr
      if(p3.gt.0.0d0)dentol(G_KS) = p3
      if(p4.gt.0.0d0)rhotol(G_KS) = p4
      if(p5.gt.0.0d0)wghtol(G_KS) = p5
      CD_screen=0
      return
      end


      integer function CD_warn(igrid,tol)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_xc)
      REAL tol
      integer igrid
c
c enable screening in xc quadrature
c
      if(tol.gt.0.0d0)warntol(igrid,G_KS) = tol
      if(tol.gt.0.0d0)warntol(igrid,G_CPKS) = tol
      CD_warn=0
      return
      end


c
c integral tolerances
c
      integer function CD_inttol(nc,p1,p2,p3,p4)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_intctl)
      integer nc
      integer p1,p2,p3,p4
      logical o2c, o3c, o4c
      CD_inttol = 1
      o2c = .false.
      o3c = .false.
      o4c = .false.
      if(nc .eq. 0)then
         o2c = .true.
         o3c = .true.
         o4c = .true.
      else if(nc .eq. 2)then
         o2c = .true.
         o3c = .false.
         o4c = .false.
      elseif(nc .eq. 3)then
         o2c = .false.
         o3c = .true.
         o4c = .false.
      elseif(nc .eq. 4)then
         o2c = .false.
         o3c = .false.
         o4c = .true.
      else
         return
      endif

      if(o2c)then
         if(p1.ne.0)itol_2c  = p1
         if(p2.ne.0)icut_2c  = p2
         if(p3.ne.0)itold_2c = p3
         if(p4.ne.0)icutd_2c = p4
      endif
      if(o3c)then
         if(p1.ne.0)itol_3c  = p1
         if(p2.ne.0)icut_3c  = p2
         if(p3.ne.0)itold_3c = p3
         if(p4.ne.0)icutd_3c = p4
      endif
      if(o4c)then
         if(p1.ne.0)itol_4c  = p1
         if(p2.ne.0)icut_4c  = p2
         if(p3.ne.0)itold_4c = p3
         if(p4.ne.0)icutd_4c = p4
      endif
      CD_inttol=0
      return
      end

      integer function CD_debug(string)
      implicit none
      character string*(*)
      character *8 zprint, idstring
      logical opg_root     
      integer i
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)

      CD_debug = 0
      zprint=idstring(string,'ksmatrix,forces,timing,control,'//
     &     'tr,nr,norm,density,jfit,aobasis,jbasis,kbasis,all,'//
     &     'memory,quadratu,quad,parallel,rhs,lhs,dksm,dksmx,hessian')

      if(zprint.eq.'ksmatrix')then
         print_sw(DEBUG_KSMATRIX) = .true.
      elseif(zprint.eq.'tr')then
         print_sw(DEBUG_TR) = .true.
      elseif(zprint.eq.'nr')then
         print_sw(DEBUG_NR) = .true.
      elseif(zprint.eq.'norm')then
         print_sw(DEBUG_NORM) = .true.
      elseif(zprint.eq.'density')then
         print_sw(DEBUG_DENSITY) = .true.
      elseif(zprint.eq.'jfit')then
         print_sw(DEBUG_JFIT) = .true.
      elseif(zprint.eq.'aobasis')then
         print_sw(DEBUG_AOBAS) = .true.
      elseif(zprint.eq.'jbasis')then
         print_sw(DEBUG_JBAS) = .true.
      elseif(zprint.eq.'kbasis')then
         print_sw(DEBUG_KBAS) = .true.
      elseif(zprint.eq.'forces')then
         print_sw(DEBUG_FORCES) = .true.
      elseif(zprint.eq.'timing')then
         print_sw(DEBUG_TIMING) = .true.
      elseif(zprint.eq.'control')then
         print_sw(DEBUG_CONTROL) = .true.
      elseif(zprint.eq.'memory')then
         print_sw(DEBUG_MEMORY) = .true.
         call gmem_set_debug(.true.)
      elseif(zprint.eq.'quadratu'.or.
     &       zprint.eq.'quad')then
         print_sw(DEBUG_QUAD) = .true.
      elseif(zprint.eq.'parallel')then
         print_sw(DEBUG_PARALLEL) = .true.
      elseif(zprint.eq.'rhs')then
         print_sw(DEBUG_CHF_RHS) = .true.
      elseif(zprint.eq.'lhs')then
         print_sw(DEBUG_CHF_LHS) = .true.
      elseif(zprint.eq.'dksm')then
         print_sw(DEBUG_CHF_DKSM) = .true.
      elseif(zprint.eq.'dksmx')then
         print_sw(DEBUG_DKSM_EXP) = .true.
      elseif(zprint.eq.'hessian')then
         print_sw(DEBUG_HESS) = .true.
      elseif(zprint.eq.'all')then
         do i=1,MAX_DEBUG
            print_sw(i) = .true.
         enddo
      elseif(zprint.eq.'ambig')then
         if(opg_root())write(6,*)'ambigous print keyword',string
         CD_debug = -1
      else
         CD_debug = 1
      endif
      if(opg_root())write(6,*)'debug print selected',zprint
      return
      end


      integer function CD_psitol(igrid,psitol1)
      implicit none
      integer igrid
      REAL    psitol1
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      CD_psitol = 1
      if (igrid.lt.0.or.igrid.gt.ngtypes) return
      CD_psitol = 2
      if (psitol1.lt.0.0d0.and.psitol1.ne.dble(DFT_UNDEF)) return
      psitol(igrid,G_KS) = psitol1
      CD_psitol = 0
      return
      end

      
      integer function CD_set_weight(string)
      implicit none
      character string*(*)
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      character *8 zwght, idstring

      CD_set_weight = 0
      zwght=idstring(string,
     +'becke,beckescr,ssf,ssfscr,mhl,mhlscr,mhl4ssf,mhl8ssf')
      if(zwght .eq. 'becke')then
         weight_scheme(G_KS) = WT_BECKE
      elseif(zwght .eq. 'beckescr')then
         weight_scheme(G_KS) = WT_BECKESCR
      elseif(zwght .eq. 'ssf')then
         weight_scheme(G_KS) = WT_SSF
      elseif(zwght .eq. 'ssfscr')then
         weight_scheme(G_KS) = WT_SSFSCR
      elseif(zwght .eq. 'mhl')then
         weight_scheme(G_KS) = WT_MHL
      elseif(zwght .eq. 'mhlscr')then
         weight_scheme(G_KS) = WT_MHLSCR
      elseif(zwght .eq. 'mhl4ssf') then
         weight_scheme(G_KS) = WT_MHL4SSFSCR
      elseif(zwght .eq. 'mhl8ssf') then
         weight_scheme(G_KS) = WT_MHL8SSFSCR
      else
         call caserr('cdft weight directive invalid')
         CD_set_weight = 1
      endif
      if(zwght .eq. 'becke')then
         weight_scheme(G_CPKS) = WT_BECKE
      elseif(zwght .eq. 'beckescr')then
         weight_scheme(G_CPKS) = WT_BECKESCR
      elseif(zwght .eq. 'ssf')then
         weight_scheme(G_CPKS) = WT_SSF
      elseif(zwght .eq. 'ssfscr')then
         weight_scheme(G_CPKS) = WT_SSFSCR
      elseif(zwght .eq. 'mhl')then
         weight_scheme(G_CPKS) = WT_MHL
      elseif(zwght .eq. 'mhlscr')then
         weight_scheme(G_CPKS) = WT_MHLSCR
      elseif(zwght .eq. 'mhl4ssf') then
         weight_scheme(G_CPKS) = WT_MHL4SSFSCR
      elseif(zwght .eq. 'mhl8ssf') then
         weight_scheme(G_CPKS) = WT_MHL8SSFSCR
      else
         call caserr('cdft weight directive invalid')
         CD_set_weight = 1
      endif
c
      end

      integer function CD_gradquad(switch)
      implicit none
      logical switch
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)

      gradwght_sw = switch
      CD_gradquad = 0
      return
      end

      integer function CD_sortpoints(switch)
      implicit none
      logical switch
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)

      sort_points_sw = switch
      CD_sortpoints = 0
      return
      end

      integer function CD_set_ignore_accuracy(switch)
      implicit none
      logical switch
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)

      ignore_accuracy_sw = switch
      CD_set_ignore_accuracy = 0
      return
      end

      logical function CD_ignore_accuracy()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)

      CD_ignore_accuracy = ignore_accuracy_sw
      return
      end

c
c CD_set_print_level - controls 
c
      integer function CD_set_print_level(level)
      implicit none
      integer level
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      current_print_level(print_stack_depth) = level
      CD_set_print_level = 0
      end
c
c string comparison function
c returns best match, truncated to 8 chars
c function is limited to 50 test values
c
      character *8 function idstring(test,valid)
      implicit none
      character test*(*)
      character valid*(*)
c
c     This subroutine tries to match the string in test with any of
c     the strings in valid. If the a match is found the matching
c     string from valid is returned. If no matches are found the 
c     string 'nomatch' is returned, otherwise 'ambig' is returned.
c
c     The strings are matched in a 2 step proces.
c     The string test matches a string in valid if
c     1) test is a substring of 1 and only 1 string in valid OR
c     2) test exactly equals 1 and 1 only string in valid.
c
      integer maxkey
      parameter(maxkey=50)
      character*8 key(maxkey)
      integer i, n, length, nkey, istart
      integer nmatch, omatch, imatch
      character comma*1
      data comma/','/
c
c     store valid keys
c
      length = len(valid)
      istart = 1
      nkey = 0
      i = 1
      do while (istart .le. length)
         if (i .eq. length+1 .or. valid(i:i) .eq. comma)then
            nkey = nkey + 1
            if (nkey.gt.maxkey) call caserr(
     +         'character*8 function idstring: nkey exceeds maxkey')
            key(nkey) = valid(istart:i-1)
            istart = i + 1
            i = istart
         else
            i = i + 1
         endif
      enddo
c
c     check input keyword
c     1) Substring matching
c
      n =  min(8,len(test))
      nmatch = 0
      do i = 1,nkey
         if(test(1:n) .eq. key(i)(1:n))then
            nmatch = nmatch + 1
            imatch = i
         endif
      enddo
      if(nmatch.eq.0)then
         idstring='nomatch'
         return
      else if(nmatch.eq.1)then
         idstring=key(imatch)
         return
      endif
c
c     2) Exact matching
c
      nmatch = 0
      do i = 1,nkey
         if(test(1:n) .eq. key(i)(1:n) .and. n .le. 8) then
            if (key(i)(n+1:n+1).eq.' ') then
               nmatch = nmatch + 1
               imatch = i
            endif
         endif
      enddo
      if (nmatch.eq.1) then
         idstring = key(imatch)
      else
         idstring = 'ambig'
      endif
      return
      end

      integer function CD_gridscale(gtyp,factor)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      REAL factor
      integer gtyp
      CD_gridscale=1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
      CD_gridscale=2
      if (factor.le.0.0d0) return
      grid_scale(gtyp,G_KS) = factor
      CD_gridscale=0
      return
      end

      integer function CD_gridatomradius(gtyp,radius)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      REAL radius
      integer gtyp
      CD_gridatomradius=1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
      CD_gridatomradius=2
      if (radius.le.0.0d0) return
      grid_atom_radius(gtyp,G_KS) = radius
      CD_gridatomradius=0
      return
      end

      integer function CD_weightatomradius(gtyp,radius)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      REAL radius
      integer gtyp
      CD_weightatomradius=1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
      CD_weightatomradius=2
      if (radius.le.0.0d0) return
      weight_atom_radius(gtyp,G_KS) = radius
      CD_weightatomradius=0
      return
      end


      integer function CD_pruneatomradius(gtyp,radius)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      REAL radius
      integer gtyp
      CD_pruneatomradius=1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
      CD_pruneatomradius=2
      if (radius.le.0.0d0) return
      prune_atom_radius(gtyp,G_KS) = radius
      CD_pruneatomradius=0
      return
      end


      integer function CD_screenatomradius(gtyp,radius)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      REAL radius
      integer gtyp
      CD_screenatomradius=1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
      CD_screenatomradius=2
      if (radius.le.0.0d0) return
      screen_atom_radius(gtyp,G_KS) = radius
      CD_screenatomradius=0
      return
      end


      integer function CD_euleron(gtyp,nradial)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      integer nradial,i,gtyp
      CD_euleron=1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
      rad_grid_scheme(gtyp,G_KS) = RG_EML
      radpt_num(gtyp,G_KS)       = nradial
      CD_euleron=0
      return
      end

c     integer function CD_defaults_old() (return type defined 
c                                         in ccpdft.hf77)
      function CD_defaults_old()
      implicit none
      integer ierror, i
INCLUDE(common/ccpdft.hf77)
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_xc)  
C *
C * old default grid options, SG1 grid, no screening
C *
      grid_generation = 1
      do i=1,max_grids
         gaccu_num(0,i)        = GACC_SG1
         ang_prune_scheme(0,i) = AP_SG1a
         conv_prune_sw         = .false.
c        weight_scheme         = DFT_UNDEF
         gradwght_sw           = .false.
c        no screening
         screen_sw             = .false.
         psitol(0,i)           = 1.0d-7
         dentol(i)             = 1.0d-10
         rhotol(i)             = 1.0d-10
         wghtol(i)             = 1.0d-20
      enddo
      sort_points_sw= .true.
      ignore_accuracy_sw=.false.
c
      CD_defaults_old= 0
      return
      end

      integer function CD_create_grid()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
c
c     Adds the stuff for a new grid and returns the number
c
c     As the arrays should have been properly initialised in CD_defaults
c     the only action needed is to increase the number of grids.
c
      CD_create_grid = -1
      if (ngtypes.ge.max_gtype) then
         write(6,*)'limit on # grid types   =',max_gtype
         write(6,*)'new number of grid types=',ngtypes+1
         call caserr('too many atom grid types')
      endif
c
      ngtypes = ngtypes + 1
      CD_create_grid = ngtypes
c
      return
      end


      integer function CD_clone_grid(igrid)
      implicit none
      integer igrid
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
c
c     Creates a new grid with the same settings as the grid igrid, and
c     returns the number of this new grid.
c
      integer i,it
c
      CD_clone_grid = -1
      if (ngtypes.ge.max_gtype) then
         write(6,*)'limit on # grid types   =',max_gtype
         write(6,*)'new number of grid types=',ngtypes+1
         call caserr('too many atom grid types')
      endif
      if (igrid.lt.0.or.igrid.gt.ngtypes) then
         write(6,*)'valid grid numbers:',0,' to',ngtypes
         write(6,*)'igrid = ',igrid
         call caserr('grid number out of range')
      endif
c
      ngtypes = ngtypes + 1
      do it=1,max_grids
         psitol(ngtypes,it) = psitol(igrid,it)
         radm_num(ngtypes,it) = radm_num(igrid,it)
         grid_scale(ngtypes,it) = grid_scale(igrid,it)
         do i = 1,maxradzn-1
            bnd_radzn(i,ngtypes,it) = bnd_radzn(i,igrid,it)
            angpt_radzn_num(i,ngtypes,it)  = angpt_radzn_num(i,igrid,it)
            phipt_radzn_num(i,ngtypes,it)  = phipt_radzn_num(i,igrid,it)
            thetpt_radzn_num(i,ngtypes,it) = thetpt_radzn_num
     &                                       (i,igrid,it)
         enddo
         i=maxradzn
         angpt_radzn_num(i,ngtypes,it) = angpt_radzn_num(i,igrid,it)
         phipt_radzn_num(i,ngtypes,it)  = phipt_radzn_num(i,igrid,it)
         thetpt_radzn_num(i,ngtypes,it) = thetpt_radzn_num(i,igrid,it)
         radzones_num(ngtypes,it) = radzones_num(igrid,it)
         ang_prune_scheme(ngtypes,it) = ang_prune_scheme(igrid,it)
         rad_grid_scheme(ngtypes,it) = rad_grid_scheme(igrid,it)
         ang_grid_scheme(ngtypes,it) = ang_grid_scheme(igrid,it)
         radpt_num(ngtypes,it) = radpt_num(igrid,it)
         gaccu_num(ngtypes,it) = gaccu_num(igrid,it)
      enddo
      CD_clone_grid = ngtypes
c
      return
      end


      integer function CD_assign_grid(iatom,gridtype)
      implicit none
      integer iatom, gridtype
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)
c
c     Assigns a grid type to a particular atom in the geometry
c
c     Note that gridtype 0 is used here for point charges. I.e. it is
c     used to designate that a centre has no grid. This usage should
c     not be confused with gridtype 0 in the grid input handling where
c     it refers to the generic grid.
c
      CD_assign_grid=-1
      if(iatom.le.0.or.iatom.gt.natoms) then
         write(6,*)'Atom label      = ',iatom
         write(6,*)'Number of atoms = ',natoms
         call caserr('Atom label out of range')
         return
      endif
      if(gridtype.lt.0.or.gridtype.gt.ngtypes) then
         write(6,*)'Grid type            = ',gridtype
         write(6,*)'Number of grid types = ',ngtypes
         call caserr('Grid type out of range')
         return
      endif
      gtype_num(iatom)=gridtype
      CD_assign_grid=0
      return
      end
      

      integer function CD_logon(gtyp,nradial,mradial)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
c
c     Return codes:
c     0 - succes
c     1 - gridtype out of range              - no data stored
c     2 - number of grid point out of range  - # grid points ignored
c     3 - exponent out of range              - exponent ignored
c
      integer nradial, gtyp
      REAL mradial
      CD_logon = 1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
      CD_logon=0
      rad_grid_scheme(gtyp,G_KS) = RG_MK
      if (mradial.gt.0.0d0) then
         radm_num(gtyp,G_KS)     = mradial
      else
         CD_logon=3
      endif
      if (nradial.gt.0) then
         radpt_num(gtyp,G_KS)    = nradial
      else
         CD_logon=2
      endif
      return
      end

      integer function CD_ang_npoints_row(irow,nangular)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      integer irow, nangular
      CD_ang_npoints_row = 1
      if (irow.lt.1.or.irow.gt.7) return
      CD_ang_npoints_row = 2
      if (nangular.lt.1) return
      angnpt_row(irow) = nangular
      CD_ang_npoints_row = 0
      return
      end

      integer function CD_rad_npoints_row(irow,nradial)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      integer irow, nradial
      CD_rad_npoints_row = 1
      if (irow.lt.1.or.irow.gt.7) return
      CD_rad_npoints_row = 2
      if (nradial.lt.1) return
      radnpt_row(irow) = nradial
      CD_rad_npoints_row = 0
      return
      end

      integer function CD_lebedevon(gtyp,nzns,nang,bnd)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm) 
      integer gtyp, nzns, nang(nzns)
      REAL bnd(nzns-1)
      integer maxleb
      logical ofound
      integer i,j
c
c     Set the angular grid type to select the Lebedev grids.
c     Stores the number of grid points for each radial zone.
c     If there is more than 1 radial zone then the angular pruning
c     type is set to select manual pruning.
c
      parameter (maxleb=32)
      integer leba(maxleb)
      data leba/6,14,26,38,50,74,86,110,146,170,194,230,266,302,350,434,
     1          590,770,974,1202,1454,1730,2030,2354,2702,3074,3470,
     1          3890,4334,4802,5294,5810/
c
      CD_lebedevon = 1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
c
      CD_lebedevon = 2
      if (nzns.le.0.or.maxradzn.lt.nzns) return
c
      CD_lebedevon = 3
      if (nzns.gt.1.and.bnd(1).lt.0.0d0) return
c
      CD_lebedevon = 4
      do i = 2, nzns-1
         if (bnd(i).le.bnd(i-1)) return
      enddo
c
      CD_lebedevon = 5 
      do j = 1, nzns
         ofound = .false.
         do i = 1, maxleb
            ofound=ofound.or.(leba(i).eq.nang(j))
         enddo
         if (.not.ofound) then
            write(6,*)'Could not find Lebedev grid of size ',nang(j)
            write(6,*)'Only the following Lebedev grids are ',
     +                'available:'
            do i = 1, maxleb
               write(6,*)leba(i),' points'
            enddo
            return
         endif
      enddo
c
      ang_grid_scheme(gtyp,G_KS) = AG_LEB
      radzones_num(gtyp,G_KS) = nzns
      do i = 1, nzns
         angpt_radzn_num(i,gtyp,G_KS) = nang(i)
      enddo
      do i = 1, radzones_num(gtyp,G_KS)-1
         bnd_radzn(i,gtyp,G_KS) = bnd(i)
      enddo
      if (nzns.gt.1) ang_prune_scheme(gtyp,G_KS) = AP_RADZONE
c
      CD_lebedevon=0 
      return
      end
     
      integer function CD_gausslon(gtyp,nzns,ntheta,nphi,bnd)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      integer gtyp, nzns
      integer ntheta(nzns), nphi(nzns)
      REAL bnd(nzns-1)
      integer i
c
c     Set the angular grid type to select the Gauss-Legendre grids.
c     Stores the number of grid points for each radial zone.
c     If there is more than 1 radial zone then the angular pruning
c     type is set to select manual pruning.
c
      CD_gausslon = 1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
c
      CD_gausslon = 2
      if (nzns.le.0.or.maxradzn.lt.nzns) return
c
      CD_gausslon = 3
      if (nzns.gt.1.and.bnd(1).lt.0.0d0) return
c
      CD_gausslon = 4
      do i = 2, nzns-1
         if (bnd(i).le.bnd(i-1)) return
      enddo
c
      ang_grid_scheme(gtyp,G_KS) = AG_LEG
      radzones_num(gtyp,G_KS) = nzns
      do i = 1, nzns
         angpt_radzn_num(i,gtyp,G_KS)  = ntheta(i)*nphi(i)
         thetpt_radzn_num(i,gtyp,G_KS) = ntheta(i)
         phipt_radzn_num(i,gtyp,G_KS)  = nphi(i)
      enddo
      do i = 1, radzones_num(gtyp,G_KS)-1
         bnd_radzn(i,gtyp,G_KS) = bnd(i)
      enddo
      if (nzns.gt.1) ang_prune_scheme(gtyp,G_KS) = AP_RADZONE
c
      CD_gausslon=0
      return
      end


      integer function CD_MHL_ang_prune(gtyp,flag)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      character*(*) flag
      integer gtyp
c
      CD_MHL_ang_prune = 1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
c
      if (flag.eq.'off'.or.flag.eq.'no') then
         ang_prune_scheme(gtyp,G_KS) = AP_RADZONE
         CD_MHL_ang_prune = 0
      else if (flag.eq.'on'.or.flag.eq.'yes') then
         ang_prune_scheme(gtyp,G_KS) = AP_MHL
         CD_MHL_ang_prune = 0
      else
         CD_MHL_ang_prune = 1
      endif
      return
      end

      integer function CD_auto_ang_prune(gtyp,flag)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      character*(*) flag
      integer gtyp
c
      CD_auto_ang_prune = 1
      if (gtyp.lt.0.or.gtyp.gt.ngtypes) return
c
      if (flag.eq.'off'.or.flag.eq.'no') then
         ang_prune_scheme(gtyp,G_KS) = AP_RADZONE
         CD_auto_ang_prune = 0
      else if (flag.eq.'on'.or.flag.eq.'yes') then
         ang_prune_scheme(gtyp,G_KS) = AP_AUTO
         CD_auto_ang_prune = 0
      else
         CD_auto_ang_prune = 1
      endif
      return
      end

      integer function CD_conv_prune_on()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      conv_prune_sw = .true.
      CD_conv_prune_on = 1
      return
      end
c
c Functions to determine the state of the DFT code
c              ===================
c
c  CD_active : true if we are performing a DFT calculation
c
      logical function CD_active()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      CD_active = active_sw
      return
      end
c
      logical function CD_HF_exchange()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      logical CD_has_HF_exchange
      external CD_has_HF_exchange
c
c     This routine informs the Hartree-Fock integral
c     drivers whether the exchange terms should be 
c     evaluated.
c
c     Returns .true. if the current functional requires
c     a non-zero fraction of Hartree-Fock (exact) exchange
c     and the DFT contributions are turned on. 
c     Returns .false. otherwise. 
c
c     This function has been modified for debug purposes 
c     such that if abort_sw is .true. the function always
c     returns .false. to avoid wasting time on calculating
c     the 2-electron integrals.
c
      if(.not. dft2e_sw)then
         CD_HF_exchange = .true.
      else if(abort_sw)then
         CD_HF_exchange = .false.
      else
         CD_HF_exchange = CD_has_HF_exchange()
      endif
      return
      end


      REAL function CD_HF_exchange_weight()
      implicit none
      logical CD_2e, CD_has_HF_exchange
      REAL    CD_has_HF_exchange_weight
      external CD_2e, CD_has_HF_exchange_weight, CD_has_HF_exchange
c
c     Returns the fraction of Hartree-Fock exchange
c     required by the current functional. 
c
c     The function returns 1.0 if the DFT contributions
c     have been temporarily turned off, e.g. in the atomic
c     density guess.
c
      if (.not. CD_2e()) then
         CD_HF_exchange_weight = 1.0d0
      else if (CD_has_HF_exchange()) then
         CD_HF_exchange_weight = CD_has_HF_exchange_weight()
      else
         CD_HF_exchange_weight = 0.0d0
      endif
      return
      end
c
c  CD_HF_coulomb : true when the host code should
c  compute the full coulomb energy/fock matrix using 2e ints
c  This is disabled when abort_sw set, since we won't have
c  any use for the resultant fock matrix
c
      logical function CD_HF_coulomb()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      if (.not. dft2e_sw) then
         CD_HF_coulomb = .true.
      else if(abort_sw)then
         CD_HF_coulomb = .false.
      else
         CD_HF_coulomb = .not. jfit_sw
      endif
      return
      end
c
c  CD_HF_coulomb_deriv : true when the host code should
c  compute the full coulomb derivatives using 2e ints
c
      logical function CD_HF_coulomb_deriv()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      if (.not. dft2e_sw) then
         CD_HF_coulomb_deriv = .true.
      else
         CD_HF_coulomb_deriv =  .not. jfitg_sw
      endif
      return
      end
c
c  CD_jfit_incore : true if we requested to compute the coulomb energy
c  using the Dunlap fitting procedure and we want to store the integrals
c  in main memory.
c
      logical function CD_jfit_incore()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_dunlap)
      CD_jfit_incore = jfit_sw.and.ocfit_sw
      return
      end
c
c see above
c
      logical function CD_2e()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      CD_2e = dft2e_sw
      return 
      end
c
c only activate DFT options if we are running a DFT calculation
c
      integer function CD_set_2e()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      dft2e_sw = active_sw
      CD_set_2e = 0
      return
      end

      integer function CD_reset_2e()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      dft2e_sw = .false.
      CD_reset_2e = 0
      return
      end

c
c  logical function CD_check_print(level)
c  
c   Checks if output at the specified verbosity level
c   has been activated.
c
      logical function CD_check_print(level)
      implicit none
      integer level
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      logical opg_root
      if(.not.opg_root())then
c
c  output only from node 0
c
         CD_check_print = .false.
      else
         CD_check_print = level .le.
     &        current_print_level(print_stack_depth)
      endif

      end

      integer function CD_jmulton()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      mult_sw=.true.
      jfit_sw=.false.
      jown_sw=.false.
      CD_jmulton=0
      return
      end
c
      logical function CD_request_multstate()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      CD_request_multstate=mult_sw
      return
      end
c
      subroutine CD_print_joboptions(iout)
      implicit none
      integer iout

INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_xc)
INCLUDE(common/dft_intctl)
      integer i
      write(iout,5)
      write(iout,10)
      write(iout,20)
      if(abort_sw)write(iout,21)
      write(iout,5)
c
c Coulomb
      write(iout,30)
      write(iout,40)
      if(jfit_sw) then
        write(iout,60)
      elseif(mult_sw) then
        write(iout,55)
        write(iout,56) over_tol
        write(iout,57) pener_tol
        write(iout,58) poleexp_num
      else
        write(iout,50)
      endif
      if(jfitg_sw) then
        write(iout,61)
      else
        write(iout,51)
      endif
c
c Exchange/Correlation
c
      call xcfunc_print(iout)

      if(jfit_sw .or. jfitg_sw) then
         write(iout,122)
         write(iout,123)2,itol_2c,icut_2c,itold_2c,icutd_2c
         write(iout,123)3,itol_3c,icut_3c,itold_3c,icutd_3c
c         write(iout,123)4,itol_4c,icut_4c,itold_4c,icutd_3c
      endif
 122  format(/,1x,'2-Electron integral accuracy parameters',/,
     & 1x,'---------------------------------------',/,
     & 1x,' Centres  Integral        Derivative  ',/,
     & 1x,'          -------------   ------------',/,
     & 1x,'          itol    icut    itol   icut')
 123  format(1x,i5,5x,4(i4,3x))
c
c quadrature grid
c
      if(kqua_sw) then
        write(iout,5)
        write(iout,130)
        write(iout,140)
        call print_atmgrid(G_KS,iout)
        if(screen_sw)then
           write(iout,*)'Tolerance on density matrix elements    = ',
     &                  dentol(G_KS)
           write(iout,*)'Tolerance on maximum density in a batch = ',
     &                  rhotol(G_KS)
           write(iout,*)'Tolerance on weight of a grid point     = ',
     &                  wghtol(G_KS)
        else
           write(iout,*)'No screening to be used'
        endif
        if(weight_scheme(G_KS) .eq. WT_BECKE)then
           write(iout,*)'Becke weights'
        else if(weight_scheme(G_KS) .eq. WT_BECKESCR)then
           write(iout,*)'Becke weights with screening'
        else if(weight_scheme(G_KS) .eq. WT_SSF)then
           write(iout,*)'Stratmann/Scuseria/Frisch weights'
        else if(weight_scheme(G_KS) .eq. WT_SSFSCR)then
           write(iout,*)
     &    'Stratmann/Scuseria/Frisch weights with screening'
        else if(weight_scheme(G_KS) .eq. WT_MHL)then
           write(iout,*)'Murray/Handy/Laming weights'
        else if(weight_scheme(G_KS) .eq. WT_MHLSCR)then
           write(iout,*)'Murray/Handy/Laming weights with screening'
        else if(weight_scheme(G_KS) .eq. WT_MHL4SSFSCR) then
           write(iout,*)
     &    'Murray/Handy/Laming 4 Stratmann/Scuseria/Frisch weights'
        else if(weight_scheme(G_KS) .eq. WT_MHL8SSFSCR) then
           write(iout,*)
     &    'Murray/Handy/Laming 8 Stratmann/Scuseria/Frisch weights'
        endif
        if(gradwght_sw) then
           write(iout,*)'Evaluation of gradients including gradients ',
     &                  'of quadrature weights and points'
        else
           write(iout,*)'Evaluation of gradients without the gradients',
     &                  ' of the quadrature'
        endif
      endif
      if(kfit_sw) then
        write(iout,200)
        write(iout,210)
        write(iout,220)
      endif

 5    format(1x)
10    format(1x,'CCP1 DFT Job Options          ')
20    format(1x,'==============================')
 21   format(1x,'*** job will abort after first KS matrix build ***'/,
     &       1x,'*** explicit 2e integral terms will be skipped ***')
30    format(1x,'Coulomb')
40    format(1x,'-------')
50    format(1x,'Four centre integrals used')
55    format(1x,'Using Multipole Approximation')
56    format(1x,'Shell overlap tolerance:      ',i2)
57    format(1x,'Coulomb penetration tolerance:',i2)
58    format(1x,'Level of multipole expansion :',i2)
60    format(1x,'Using Dunlap fit')
 51   format(1x,'Four centre integrals used for derivatives')
 61   format(1x,'Using Dunlap fit for derivatives')
70    format(1x,'Exchange/Correlation')
80    format(1x,'--------------------')
 88   format(1x,'HF exchange used weight=',f8.5)
 89   format(1x,'HF exchange used')
 90   format(1x,'Dirac exchange used')
 91   format(1x,'Dirac exchange used weight=',f8.5)
 100  format(1x,'Becke88 exchange used')
 101  format(1x,'Becke88 exchange used weight=',f8.5)
 102  format(1x,'Becke88 gradient correction for exchange used')
 103  format(1x,'Becke88 gradient correction for exchange used weight=',
     +f8.5)
 110  format(1x,'VWN correlation used')
 111  format(1x,'VWN correlation used weight=',f8.5)
 115  format(1x,'RPA VWN correlation used')
 116  format(1x,'RPA VWN correlation used weight=',f8.5)
 117  format(1x,'RPA VWN1 correlation used')
 118  format(1x,'RPA VWN1 correlation used weight=',f8.5)
 120  format(1x,'LYP correlation used')
 121  format(1x,'LYP correlation used weight=',f8.5)
 124  format(1x,'P86 correlation used')
 125  format(1x,'P86 correlation used weight=',f8.5)
130   format(1x,'Quadrature Grid')
140   format(1x,'---------------')
c150  format(1x,'SG1 grid used')
c160  format(1x,'Lebedev angular grid used')
c170  format(1x,'Gauss Legendre angular grid used')
c180  format(1x,'Number of angular pts/atom:',i6)
c190  format(1x,'Number of radial pts/atom in row ',i1,':',i6)
200   format(1x,'XC Auxiliary Fit')
210   format(1x,'----------------')
220   format(1x,'Number of sample pts/atom:',i4)
c230  format(1x,'Euler-MacLaurin radial grid used')
c240  format(1x,'Logarithmic radial grid used')
      return
      end

      subroutine CD_print_dftresults(all_sw,verbose_sw,iout)
      implicit none
INCLUDE(common/dft_api)
      logical all_sw,verbose_sw
      integer iout
      write(iout,5)
      write(iout,10)
      write(iout,20)
      if(verbose_sw) then
        write(iout,50) totDen
        write(iout,60) XC_energy
        write(iout,80) J_energy
      endif
      if(all_sw) then
         if(dabs(beta_Den) .gt. 1.0d-20)then
            write(iout,30) alpha_Den
            write(iout,40) beta_Den
            write(iout,50) totDen
         else
            write(iout,51) totDen
         endif
         write(iout,60) XC_energy
         if(dabs(lmult) .gt. 1.0d-20)then
            write(iout,70) lmult
         endif
         if(dabs(J_energy) .gt. 1.0d-20)then
            write(iout,80) J_energy
         endif
         write(iout,90) totPts
      endif
 5    format(1x)
10    format(1x,'CCP Dft Results This Iteration')
20    format(1x,'==============================')
30    format(1x,'Alpha Density:        ',f14.8)
40    format(1x,'Beta Density:         ',f14.8)
c50    format(1x,'Total Density:        ',f14.8)
c51    format(1x,'Integrated Density:   ',f14.8)
c60    format(1x,'XC energy:            ',f14.8)
50    format(1x,'Integrated Density:   ',e28.16)
51    format(1x,'Integrated Density:   ',e28.16)
60    format(1x,'XC energy:            ',e28.16)
70    format(1x,'Lagrange Mult:        ',f14.8)
80    format(1x,'Total Coulomb energy: ',f14.8)
90    format(1x,'Total number of pts:  ',i10)
      return
      end
c
c  Eventually will repalce above routine to allow main code
c  to print results in a more sensible fashion
c
      subroutine CD_get_dftresults(nquad,alpha_quad,beta_quad)
      implicit none
      integer nquad
      REAL alpha_quad,beta_quad
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_api)
INCLUDE(common/dft_module_comm)
      nquad = totPts
      if (rks_sw) then
         alpha_quad = totDen
         beta_quad  = 0.0d0
      else
         alpha_quad = alpha_den
         beta_quad = beta_den
      endif
      end
c
c Various API's for integral tests
c

c
c combined test to check if we can skip integral
c generation for shell quartet
c
      logical function IL_test4(p1,p2,q1,q2,ip12_list)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      integer ip12_list(*)
      integer p1,p2,q1,q2
      logical IL_Bielectronic
c     logical IL_Bielec2
      if(.not. active_sw)goto 1
      if (.not. mult_sw)goto 1
c     if(ip12_list(q1).eq.1)goto 1
c     if(ip12_list(q2).eq.1)goto 1
      if(IL_Bielectronic(p1,p2,q1))goto 1
      if(IL_Bielectronic(p1,p2,q2))goto 1
      if(IL_Bielectronic(q1,q2,p1))goto 1
      if(IL_Bielectronic(q1,q2,p2))goto 1
c     if(IL_Bielec2(q1,q2,p1,p2))goto 1
      IL_test4 = .false.
      return
 1    continue
      IL_test4 = .true.
      return
      end
c
c first stage test store i/j indices
c
      subroutine IL_test4a(p1x,p2x)
      implicit none
INCLUDE(common/test4)      
      integer p1x,p2x

INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_parameters)
INCLUDE(../m4/common/nshel)
INCLUDE(common/dft_module_comm)
INCLUDE(common/basato.hf77)

      p1=p1x
      p2=p2x

      x1=xl(1,p1)
      y1=xl(2,p1)
      z1=xl(3,p1)

      x2=xl(1,p2)
      y2=xl(2,p2)
      z2=xl(3,p2)

      x12=x2-x1
      y12=y2-y1
      z12=z2-z1
      ex2=exad(p2)
      ex1=exad(p1)

      dddd12=ex1+ex2
      fa2=ex2/dddd12
      dddd12=dddd12*0.5d0
      fat=fa2*ex1*0.5d0

      rsq12=x12*x12+y12*y12+z12*z12
      xx12=fat*rsq12 + tttt2
      yy12= 1.0d-4 - rsq12

      xp=x12*fa2
      yp=y12*fa2
      zp=z12*fa2

      x812=xp+x1
      y812=yp+y1
      z812=zp+z1

      end
c
c second stage of test, add third shell and test it
c
      subroutine IL_test4b(q1x)
      implicit none
INCLUDE(common/test4)      
      integer q1x

INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_parameters)
INCLUDE(../m4/common/nshel)
INCLUDE(common/dft_module_comm)
INCLUDE(common/basato.hf77)
      q1 = q1x
c
c- q_atom needed below here
c  need dddddd, xy,y8,z8, xx, yy
c
      x3=xl(1,q1)
      y3=xl(2,q1)
      z3=xl(3,q1)

      x9=x3-x812
      y9=y3-y812
      z9=z3-z812
      zz=x9*x9+y9*y9+z9*z9
      zz4=zz*4.0d0
      ex3=exad(q1)

      ex9=1.0d0/(ex3+dddd12)
      fat1=ex3*dddd12*ex9
      vsq=max((0.75d0*log(fat1*ex9)-xx12)/fat1,yy12)
      if((vsq.lt.0.0d0).or.(zz.gt.vsq)) then
         l123 = .false.
      else
         l123 = .true.
      endif

      end
c
c final stage of test, generate logical result and factors
c
c for performance reasons this routine should not be called unless
c the multipole code is active
c
      logical function IL_test4c(q2x,fac1,fac2, ic)
      implicit none
INCLUDE(common/test4)      

INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_parameters)
INCLUDE(../m4/common/nshel)
INCLUDE(common/dft_module_comm)
INCLUDE(common/basato.hf77)

      integer q2x
      logical bi_on(4)
      integer ic(3)
      REAL fac1, fac2

      REAL dddddd, xx, yy, x8, y8, z8

c     logical il_bielectronic

      q2=q2x

      x4=xl(1,q2)
      y4=xl(2,q2)
      z4=xl(3,q2)

      x9=x4-x812
      y9=y4-y812
      z9=z4-z812

      zz=x9*x9+y9*y9+z9*z9
      zz4=zz*4.0d0
      ex4=exad(q2)
      ex9=1.0d0/(ex4+dddd12)
      fat1=ex4*dddd12*ex9
      vsq=max((0.75d0*log(fat1*ex9)-xx12)/fat1,yy12)
      if((vsq.lt.0.0d0).or.(zz.gt.vsq)) then
         l124 = .false.
      else
         l124 = .true.
      endif
c
c gaussian product for centres q1,q2
c
      x12=x4-x3
      y12=y4-y3
      z12=z4-z3

      dddddd=ex3+ex4
      fa2=ex4/dddddd
      dddddd=dddddd*0.5d0
      fat=fa2*ex3*0.5d0

      rsq12=x12*x12+y12*y12+z12*z12
      xx=fat*rsq12 + tttt2
      yy= 1.0d-4 - rsq12

      xp=x12*fa2
      yp=y12*fa2
      zp=z12*fa2

      x8=xp+x3
      y8=yp+y3
      z8=zp+z3
c
c penetration factors for p1, p2 with (q1,q2)
c
      x9=x1-x8
      y9=y1-y8
      z9=z1-z8

      zz=x9*x9+y9*y9+z9*z9
      zz4=zz*4.0d0
      ex9=1.0d0/(ex1+dddddd)
      fat1=ex1*dddddd*ex9
      vsq=max((0.75d0*log(fat1*ex9)-xx)/fat1,yy)
      if((vsq.lt.0.0d0).or.(zz.gt.vsq)) then
         l341 = .false.
      else
         l341 = .true.
      endif

      x9=x2-x8
      y9=y2-y8
      z9=z2-z8

      zz=x9*x9+y9*y9+z9*z9
      zz4=zz*4.0d0
      ex9=1.0d0/(ex2+dddddd)
      fat1=ex2*dddddd*ex9
      vsq=max((0.75d0*log(fat1*ex9)-xx)/fat1,yy)
      if((vsq.lt.0.0d0).or.(zz.gt.vsq)) then
         l342 = .false.
      else
         l342 = .true.
      endif

      bi_on(1)=l123
      bi_on(2)=l124
      bi_on(3)=l341
      bi_on(4)=l342

c      if( (bi_on(1) .neqv. il_bielectronic(p1,p2,q1)) .or.
c     &   ( bi_on(2) .neqv. il_bielectronic(p1,p2,q2)) .or.
c     &   ( bi_on(3) .neqv. il_bielectronic(q1,q2,p1)) .or.
c     &   ( bi_on(4) .neqv. il_bielectronic(q1,q2,p2)))then
c         write(6,*)'problem',l123,l124, l341, l342,
c     &        il_bielectronic(p1,p2,q1),
c     &        il_bielectronic(p1,p2,q2),
c     &        il_bielectronic(q1,q2,p1),
c     &        il_bielectronic(q1,q2,p2)
c      endif

      fac1=1.0d0
      fac2=1.0d0
      if(.not.bi_on(1))fac1=fac1-0.5d0
      if(.not.bi_on(2))fac1=fac1-0.5d0
      if(.not.bi_on(3))fac2=fac2-0.5d0
      if(.not.bi_on(4))fac2=fac2-0.5d0
c
c return value and 
c statistics for different permutation strategies
c
      if(bi_on(1))ic(1)=ic(1)+1
      if(bi_on(2).or.bi_on(1))ic(2)=ic(2)+1

      IL_test4c = .false.

      if(bi_on(2).or.bi_on(1) .or.bi_on(3).or.
     &     bi_on(4) )then
         ic(3)=ic(3)+1
         IL_test4c = .true.
      endif

      end

      logical function IL_list4(p1,p2,q1,q2,bi_on)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      logical bi_on(4)
      integer p1,p2,q1,q2
      if(.not. active_sw)goto 1

      if (.not. mult_sw)goto 1
c     write(6,*) 'ilt:',bi_on(1),bi_on(2),bi_on(3),bi_on(4)
      if(bi_on(1))goto 1
      if(bi_on(2))goto 1
      if(bi_on(3))goto 1
      if(bi_on(4))goto 1
      IL_list4 = .false.
      return
 1    continue
      IL_list4 = .true.
      return
      end
      
      logical function IL_Bielectronic(p1,p2,q1)
      implicit none
      integer p1,p2,q1
INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_parameters)
INCLUDE(../m4/common/nshel)
INCLUDE(common/dft_module_comm)
INCLUDE(common/basato.hf77)
      REAL xpold,ypold,zpold
      REAL x1old,y1old,z1old
      REAL x22old,y22old,z22old
      REAL x8,y8,z8,x9,y9,z9
      REAL ex2old,ex1old,dddddd,fa2old,ex8,ex9
      REAL rsqold,xx,yy,zz,zz4
      REAL fat1,fatold,vsq

c     integer p1_atom,p2_atom,q_atom
c     REAL x21old,y21old,z21old
c     REAL tttttt2
c     REAL exad_find
      
      if (.not. mult_sw)then
         IL_Bielectronic = .true.
         return
      endif
c     if((p1.gt.259).or.(p2.gt.259).or.(q1.gt.259)) then
c       write(6,*) 'error',p1,p2,q1
c       stop
c     endif
      x1old=xl(1,p1)
      y1old=xl(2,p1)
      z1old=xl(3,p1)
      x22old=xl(1,p2)-x1old
      y22old=xl(2,p2)-y1old
      z22old=xl(3,p2)-z1old
      ex2old=exad(p2)
      ex1old=exad(p1)
c     ex2old=exad_find(p2)
c     ex1old=exad_find(p1)
      dddddd=ex1old+ex2old
      fa2old=ex2old/dddddd
      dddddd=dddddd*0.5d0
      fatold=fa2old*ex1old*0.5d0

      rsqold=x22old*x22old+y22old*y22old+z22old*z22old
      xx=fatold*rsqold+tttt2
      yy=1.0d-4-rsqold

      xpold=x22old*fa2old
      ypold=y22old*fa2old
      zpold=z22old*fa2old

      x8=xpold+x1old
      y8=ypold+y1old
      z8=zpold+z1old
c
c- q_atom needed below here
c  need dddddd, xy,y8,z8, xx, yy
c
      x9=xl(1,q1)-x8
      y9=xl(2,q1)-y8
      z9=xl(3,q1)-z8


      zz=x9*x9+y9*y9+z9*z9
      zz4=zz*4.0d0
c     ex8=exad_find(q1)
      ex8=exad(q1)

      ex9=1.0d0/(ex8+dddddd)
      fat1=ex8*dddddd*ex9
      vsq=max((0.75d0*log(fat1*ex9)-xx)/fat1,yy)
      if((vsq.lt.0.0d0).or.(zz.gt.vsq)) then
        IL_Bielectronic=.false.
      else
        IL_Bielectronic=.true.
      endif

      return
      end

      logical function IL_Bielec2(p1,p2,q1,q2)
      implicit none
      integer p1,p2,q1,q2
INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_parameters)
INCLUDE(../m4/common/nshel)
INCLUDE(common/dft_module_comm)
INCLUDE(common/basato.hf77)
      REAL xpold,ypold,zpold
      REAL x1old,y1old,z1old,x22old,y22old,z22old
c     REAL x21old,y21old,z21old
      REAL x8,y8,z8,x9,y9,z9
      REAL ex2old,ex1old,dddddd,fa2old,ex8,ex9
      REAL rsqold,xx,yy,zz,zz4
      REAL fat1,fatold,vsq

      if (.not. mult_sw)then
         IL_Bielec2 = .true.
         return
      endif

      x1old=xl(1,p1)
      y1old=xl(2,p1)
      z1old=xl(3,p1)
      x22old=xl(1,p2)-x1old
      y22old=xl(2,p2)-y1old
      z22old=xl(3,p2)-z1old
      ex2old=exad(p2)
      ex1old=exad(p1)
      dddddd=ex1old+ex2old
      fa2old=ex2old/dddddd
      dddddd=dddddd*0.5d0
      fatold=fa2old*ex1old*0.5d0
      rsqold=x22old*x22old+y22old*y22old+z22old*z22old
      xx=fatold*rsqold+tttt2
      yy=1.0d-4-rsqold
      xpold=x22old*fa2old
      ypold=y22old*fa2old
      zpold=z22old*fa2old
      x8=xpold+x1old
      y8=ypold+y1old
      z8=zpold+z1old
c
c q dependence
      x9=xl(1,q1)-x8
      y9=xl(2,q1)-y8
      z9=xl(3,q1)-z8
      zz=x9*x9+y9*y9+z9*z9
      zz4=zz*4.0d0
      ex8=exad(q1)
      ex9=1.0d0/(ex8+dddddd)
      fat1=ex8*dddddd*ex9
      vsq=max((0.75d0*log(fat1*ex9)-xx)/fat1,yy)
      if((vsq.lt.0.0d0).or.(zz.gt.vsq)) then
        IL_Bielec2=.false.
      else
        IL_Bielec2=.true.
        return
      endif

      x9=xl(1,q2)-x8
      y9=xl(2,q2)-y8
      z9=xl(3,q2)-z8
      zz=x9*x9+y9*y9+z9*z9
      zz4=zz*4.0d0
      ex8=exad(q2)
      ex9=1.0d0/(ex8+dddddd)
      fat1=ex8*dddddd*ex9
      vsq=max((0.75d0*log(fat1*ex9)-xx)/fat1,yy)
      if((vsq.lt.0.0d0).or.(zz.gt.vsq)) then
        IL_Bielec2=.false.
      else
        IL_Bielec2=.true.
      endif
      return
      end
 
      subroutine IL_shell_ilist(shl1,shl2,int_list)
      implicit none
INCLUDE(common/basato.hf77)
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_mol_info)

      integer shl1,shl2,int_list(*)

      REAL xpold,ypold,zpold
      REAL x1old,y1old,z1old,x22old,y22old,z22old
c     REAL x21old,y21old,z21old
      REAL x8,y8,z8,x9,y9,z9
      REAL ex2old,ex1old,dddddd,fatold,fa2old
      REAL rsqold,xx,yy,zz,zz4
      REAL fat1,vsq
      REAL ex8,ex9

      integer latm,lq1,i
      if((.not.active_sw).or.(.not.mult_sw)) return
      x1old  = xl(1,shl1)
      y1old  = xl(2,shl1)
      z1old  = xl(3,shl1)
      x22old = xl(1,shl2)-x1old
      y22old = xl(2,shl2)-y1old
      z22old = xl(3,shl2)-z1old
      ex2old = exad(shl2)
      ex1old = exad(shl1)
      dddddd = ex1old+ex2old
      fa2old = ex2old/dddddd
      dddddd = dddddd*0.5d0
      fatold = fa2old*ex1old*0.5d0

      rsqold = x22old*x22old+y22old*y22old+z22old*z22old
      xx     = fatold*rsqold+tttt2
      yy     = 1.0d-4-rsqold

      xpold  = x22old*fa2old
      ypold  = y22old*fa2old
      zpold  = z22old*fa2old
      x8     = xpold+x1old
      y8     = ypold+y1old
      z8     = zpold+z1old
      i=1 
      do latm=1,natoms
        x9=xa(1,latm)-x8
        y9=xa(2,latm)-y8
        z9=xa(3,latm)-z8
        zz=x9*x9+y9*y9+z9*z9
        zz4=zz*4.0d0
        do lq1=nshpri(latm),nshpri(latm+1)-1 
          ex8=exad(lq1)
          ex9=1.0d0/(ex8+dddddd)
          fat1=ex8*dddddd*ex9
          vsq=max((0.75d0*log(fat1*ex9)-xx)/fat1,yy)
          if((vsq.lt.0.0d0).or.(zz.gt.vsq)) then
            int_list(i)=0
          else
            int_list(i)=1 
          endif
          i=i+1
        enddo
      enddo
      return
      end

      REAL function exad_find(shel)
      implicit none
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/nshel)
      integer shel
      integer lprm
      integer pfirst,qfirst
      REAL ex1,ex2,ex_min
      pfirst=kstart(shel)
      ex1=ex(pfirst)
      qfirst=pfirst 
      do lprm=1,kng(shel)
         ex2=ex(qfirst)
         ex_min=min(ex1,ex2)
         qfirst=qfirst+1
      enddo
      exad_find=ex_min
      return
      end

      REAL function IL_shlove_tol()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      IL_shlove_tol=log(0.1d0)*over_tol
      return
      end
c
c tolerences for integral driver
c
      integer function CD_pener(itol)
      integer itol
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      pener_tol=itol
      tttt2=log(0.1d0)*dble(pener_tol)-1.5d0*log(2.0d0)
      CD_pener=0
      end
c
      integer function CD_over(itol)
      integer itol
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      over_tol=itol
      CD_over=0
      end
c
      integer function CD_schwarz(itol)
      integer itol
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      if(itol.ge.0) then
         schwarz_tol=itol
         CD_schwarz=0
      else
         CD_schwarz=1
      endif
      end
c
      integer function CD_pole(itol)
      integer itol
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      polexp_num=itol
      CD_pole=0
      end

      integer function CD_generation(igen)
      implicit none
      integer igen
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
      CD_generation = 1
      if (igen.lt.1.or.igen.gt.2) return
      grid_generation = igen
      CD_generation = 0
      return
      end

      function CD_accuracy(igrid,level)
      implicit none
      integer igrid
      character*4 level
INCLUDE(common/ccpdft.hf77)
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_xc)
c
      CD_accuracy = 1
      if (igrid.lt.0.or.igrid.gt.ngtypes) return
c
      CD_accuracy = 2
      if (grid_generation.eq.1) then
         CD_accuracy = 3
         if (level(1:3).eq.'low') then
            gaccu_num(igrid,G_KS) = GACC_LOW
         else if (level(1:4).eq.'medi') then
            gaccu_num(igrid,G_KS) = GACC_MEDIUM
         else if (level(1:4).eq.'high') then
            gaccu_num(igrid,G_KS) = GACC_HIGH
         else if (level(1:4).eq.'very') then
            gaccu_num(igrid,G_KS) = GACC_VERYHIGH
         else if (level(1:3).eq.'ref') then
            gaccu_num(igrid,G_KS) = GACC_REF
         else if (level(1:3).eq.'sg1') then
            gaccu_num(igrid,G_KS) = GACC_SG1
         else 
c
c           Sorry, it doesn't get much more accurate than that !!!
c
            return
         endif
      else if (grid_generation.eq.2) then
         CD_accuracy = 3
         if (level(1:3).eq.'low') then
            gaccu_num(igrid,G_KS) = GACC_LOW
         else if (level(1:4).eq.'lome') then
            gaccu_num(igrid,G_KS) = GACC_LOWMEDIUM
         else if (level(1:4).eq.'medi') then
            gaccu_num(igrid,G_KS) = GACC_MEDIUM
         else if (level(1:4).eq.'mehi') then
            gaccu_num(igrid,G_KS) = GACC_MEDIUMHIGH
         else if (level(1:4).eq.'high') then
            gaccu_num(igrid,G_KS) = GACC_HIGH
         else if (level(1:3).eq.'ref') then
            gaccu_num(igrid,G_KS) = GACC_REF
         else if (level(1:3).eq.'sg1') then
            gaccu_num(igrid,G_KS) = GACC_SG1
         else 
c
c           Sorry, it doesn't get much more accurate than that !!!
c
            return
         endif
      else
c
c        Incorrect setting of the grid_generation
c
         return
      endif
      CD_accuracy = 0
c
      return
      end


      function CD_radscale_scheme(scheme)
      implicit none
      character*4 scheme
INCLUDE(common/ccpdft.hf77)
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_xc)
c
      CD_radscale_scheme = 1
c
      if (scheme(1:2).eq.'mk') then
         rad_scale_scheme = SC_MK
      else if (scheme(1:4).eq.'gam1') then
         rad_scale_scheme = SC_GAM1
      else if (scheme(1:4).eq.'gam2') then
         rad_scale_scheme = SC_GAM2
      else
c
c        Sorry, no other scale schemes available
c
         return
      endif
      CD_radscale_scheme = 0
c
      return
      end
c
c  $Author: hvd $ $Revision: 5905 $ $Date: 2009-03-25 18:43:06 +0100 (Wed, 25 Mar 2009) $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/dft/interface.m,v $
c
      subroutine ver_dft_interface(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/dft/interface.m,v $
     +     "/
      data revision /
     +     "$Revision: 5905 $"
     +      /
      data date /
     +     "$Date: 2009-03-25 18:43:06 +0100 (Wed, 25 Mar 2009) $"
     +     /
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
