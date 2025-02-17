c
c Basis set API
c
c      subroutine BL_init   
c
c      integer function BL_clear_basis_set(tag)
c
c           clear all atom type definition for the specified basis
c
c      integer function BL_create_atomtag(tag,atomic_number)
c
c           create a new basis atom type and return the integer tag
c
c      integer function BL_find_atomtag(tag,atomic_number)
c
c           return the basis type tag for the a atomic number
c           returns 0 if none exists
c
c      logical function BL_atomtyp_exist(tag,atomic_number)
c
c           as above - just returns true/false
c
c      integer function BL_import_shell(tag,atom_id,nprims,ang,
c
c
c
c      integer function BL_maxang_on_atom(tag,atom)
c
c
c
c      integer function BL_write_basis(tag,iout)
c
c
c      integer function BL_get_atom_type(tag,atom)
c           get the atom type for a specific atom
c
c      integer function BL_assign_types_by_z
c           assign all atoms using the atomic number
c
c      integer function BL_num_sets    
c           return the number of stored basis sets
c
c      integer function BL_summarise
c           Summary data on all sets, mainly for debugging
c
c
      integer function BL_summarise()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)

      integer BL_num_sets 
      integer BL_maxang_on_atom
      integer BL_get_atom_type

      integer i, tag, itype

      write(6,*)'Basis Set Summary'
      write(6,*)'=================='
      write(6,*)'There are ',BL_num_sets(),' sets'
      do i = 1,natoms

c      &        Ashl(tag,BL_get_atom_type(tag,i)),

         write(6,100)i,
     &        (BL_get_atom_type(tag,i),
     &        BL_maxang_on_atom(tag,i),
     &        Aprm(tag,BL_get_atom_type(tag,i)),
     &        Abfn(tag,BL_get_atom_type(tag,i)),
     &        tag=1,BL_num_sets())
 100     format(1x,i3,4(3x,4i4))
      enddo
      BL_summarise = 0
      return
      end

      subroutine BL_init
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      integer i, j
      num_bset=0
c
c This is used to trap unassigned atom types
c as this assignment is no longer done on the fly
c
      do i = 1,max_atom
         do j = 1, max_tag
            atom_tag(j,i)=-999
         enddo
      enddo
      return
      end

      logical function BL_atomtyp_exist(tag,atomic_number)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      integer tag,atomic_number,ltyp

      BL_atomtyp_exist=.false.
      if(num_types(tag).ne.0)then
         do ltyp=1,num_types(tag)
            if(atm_typ(tag,ltyp).eq.atomic_number) then
               BL_atomtyp_exist=.true.
            endif
         enddo
      endif
      return
      end
C
c Note that any explicitly set types will be 
c left unchanged
c
      integer function BL_assign_type(tag,atomno,type)

INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)

      integer tag, atomno, type

      if(tag.le.0 .or. tag.gt.max_tag)then
         call caserr('BL_assign_type: basis tag out of range')
      endif
      if(atomno.le.0 .or. atomno.gt.natoms)then
         call caserr('BL_assign_type: atom index out of range')
      endif

      if(type.lt.0 .or. type.gt.num_types(tag))then
         write(*,*)'BL_assign_type: basis set tag      = ',tag
         write(*,*)'BL_assign_type: num types in basis = ',
     +              num_types(tag)
         write(*,*)'BL_assign_type: atom number        = ',atomno
         write(*,*)'BL_assign_type: atom type          = ',type
         call caserr('BL_assign_type: type index out of range')
      endif

c     write(6,*)'assign',tag,atomno,type
      atom_tag(tag,atomno) = type

      BL_assign_type = 0
      return
      end

      integer function BL_assign_types_by_z(tag)
      implicit none

      integer atyp, ltyp, tag, latm
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)

      if (tag.le.0 .or. tag.gt.max_tag) then
         call caserr('BL_assign_types_by_z: tag out of range')
      endif

      BL_assign_types_by_z = 0
      do latm=1,natoms

         atyp = -1
         do ltyp=1,num_types(tag)
            if(ian(latm).eq.atm_typ(tag,ltyp)) then
               atyp = ltyp
c              write(6,*)'assign',tag,latm,atyp
            endif
         enddo
         if(atyp .eq. -1)then
c           write(6,*)'warning: no function in basis set ',tag,
c    &           'for z=',ian(latm)
c
c return an error if the atom was not a dummy
c
            if(ian(latm) .gt. 0)BL_assign_types_by_z = -1
            atom_tag(tag,latm) = 0
         else
            atom_tag(tag,latm) = atyp
         endif
      enddo
      return
      end

      integer function BL_basis_size(tag)
      implicit none
      integer tag
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      if(tag.le.0 .or. tag.gt.max_tag)then
         call caserr('BL_basis_size: basis tag out of range')
      endif
      BL_basis_size = totbfn(tag)
      end

      integer function BL_max_shell_count()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      integer i
      BL_max_shell_count = 0
      do i = 1,num_bset
         BL_max_shell_count = max(BL_max_shell_count,totshl(i))
      enddo
      end

      integer function BL_get_atom_type(tag,atom)

      implicit none

INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)

      integer tag, atom
      if(tag.le.0 .or. tag.gt.max_tag)then
         call caserr('BL_get_atom_type: basis tag out of range')
      endif
      if(atom.le.0 .or. atom.gt.natoms)then
         call caserr('BL_get_atom_type: atom index out of range')
      endif
      if(atom_tag(tag,atom).eq.-999)then
         write(6,*)'problem',tag,atom
         call caserr('basis lib: atom types not assigned')
      endif
      BL_get_atom_type = atom_tag(tag,atom)
      return
      end
c
      integer function BL_clear_basis_set(tag)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      integer tag
      if(tag.le.0 .or. tag.gt.max_tag)then
         call caserr('BL_clear_basis_set: basis tag out of range')
      endif
      num_types(tag)=0
      atm_typ(tag,1)=-1
      BL_clear_basis_set = 0
      end

      integer function BL_find_atomtag(tag,atomic_number)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      integer tag,atomic_number
      integer i
      do i = 1, num_types(tag)
         if(atm_typ(tag,i) .eq. atomic_number)then
            BL_find_atomtag = i
         endif
      enddo
      BL_find_atomtag = 0
      return
      end

      integer function BL_create_atomtag(tag,atomic_number)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      integer tag,atomic_number
      integer newtype

      num_types(tag)=num_types(tag)+1

      if(num_types(tag) .gt. max_atype)then
         write(6,*)'basis tag',tag
         write(6,*)'atomic number',atomic_number
         write(6,*)'limit on types',max_atype
         call caserr('too many atom basis types')
      endif

      newtype=num_types(tag)
      atm_typ(tag,newtype)=atomic_number

      num_shl(tag,newtype)=0
      Aprm(tag,newtype)=0

      BL_create_atomtag=newtype
      return
      end
C
C
      integer function BL_import_shell(tag,atom_id,nprims,ang,
     &                                 hyb,expo,ccs,ccp,
     &                                 ccd,ccf,ccg)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
C
      integer tag,atom_id,nprims,ang,hyb
      REAL expo(*),ccs(*),ccp(*),ccd(*),ccf(*),ccg(*)
C
      integer lprm,ploc,newshl
C
      if(tag.le.0 .or. tag.gt.max_tag)then
         call caserr('BL_import_shell: basis tag out of range')
      endif
      if(atom_id.le.0 .or. atom_id.gt.max_atype)then
         call caserr('BL_import_shell: type index out of range')
      endif
      if (num_shl(tag,atom_id).ge.max_shel)then 
         call caserr(
     +      'BL_import_shell: maximum number of shells exceeded')
      endif
      if (Aprm(tag,atom_id)+nprims.gt.max_prm) then
         call caserr(
     +      'BL_import_shell: maximum number of primitives exceeded')
      endif
      num_shl(tag,atom_id)=num_shl(tag,atom_id)+1

      newshl=num_shl(tag,atom_id)
      nprim(tag,atom_id,newshl)  = nprims
      angmom(tag,atom_id,newshl) = ang
      hybrid(tag,atom_id,newshl) = hyb
      ploc                       = Aprm(tag,atom_id)+1
      pstart(tag,atom_id,newshl) = ploc
      do lprm=1,nprims
        alpha(tag,atom_id,ploc)=expo(lprm)
        cont_coeff(tag,atom_id,ploc,1)=ccs(lprm)
        cont_coeff(tag,atom_id,ploc,2)=ccp(lprm)
        cont_coeff(tag,atom_id,ploc,3)=ccd(lprm)
        cont_coeff(tag,atom_id,ploc,4)=ccf(lprm)
        cont_coeff(tag,atom_id,ploc,5)=ccg(lprm)
        ploc=ploc+1
      enddo
      Aprm(tag,atom_id)=Aprm(tag,atom_id)+nprims
      BL_import_shell=0
      return
      end
C
      integer function BL_maxang_on_atom(tag,centre)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      integer tag,centre
      integer ltyp,la,lshl
      integer BL_get_atom_type

      ltyp=BL_get_atom_type(tag,centre)
      la=0
      if(ltyp .ne. 0)then
         do lshl=1,num_shl(tag,ltyp)
            la=max(la,angmom(tag,ltyp,lshl))
         enddo
      endif
      BL_maxang_on_atom=la
      return
      end
C
C
      integer function BL_write_basis(tag,iout)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      integer tag, iout
      integer ltyp,lshl,lprm
      integer atom,ploc
      REAL expo,c1,c2
      integer ll,lh
      if(tag.le.0 .or. tag.gt.max_tag)then
         call caserr('BL_write_basis: basis tag out of range')
      endif
      write(iout,10)
      if(tag.ne.-1) then
      do ltyp=1,num_types(tag)
         atom=atm_typ(tag,ltyp)
         do lshl=1,num_shl(tag,ltyp)
            ploc=pstart(tag,ltyp,lshl)
            lh     = hybrid(tag,ltyp,lshl)
            ll     = angmom(tag,ltyp,lshl)
            do lprm=1,nprim(tag,ltyp,lshl)
               expo=alpha(tag,ltyp,ploc)
               if(ll.eq.1 .and. lh .eq. 1)then
                  c1=cont_coeff(tag,ltyp,ploc,1)
                  write(iout,20) atom,lshl,ploc,'s ',expo,c1
               else if(ll.eq.2 .and. lh .eq. 2)then
                  c1=cont_coeff(tag,ltyp,ploc,2)
                  write(iout,20) atom,lshl,ploc,'p ',expo,c1
               else if(ll.eq.3 .and. lh .eq. 3)then
                  c1=cont_coeff(tag,ltyp,ploc,3)
                  write(iout,20) atom,lshl,ploc,'d ',expo,c1
               else if(ll.eq.4 .and. lh .eq. 4)then
                  c1=cont_coeff(tag,ltyp,ploc,4)
                  write(iout,20) atom,lshl,ploc,'f ',expo,c1
               else if(ll.eq.5 .and. lh .eq. 5)then
                  c1=cont_coeff(tag,ltyp,ploc,5)
                  write(iout,20) atom,lshl,ploc,'g ',expo,c1
               else if(ll.eq.2 .and. lh .eq. 1)then
                  c1=cont_coeff(tag,ltyp,ploc,1)
                  c2=cont_coeff(tag,ltyp,ploc,2)
                  write(iout,20) atom,lshl,ploc,'sp',expo,c1,c2
               else
                  write(iout,*)'angmom=',ll,'hybrid=',lh
                  call caserr('unrecognised shell type')
               endif
               ploc=ploc+1
            enddo
            write(iout,*)' '
         enddo
      enddo
      endif
      BL_write_basis=0
 10   format(1x,' At No',2x,'Shell',3x,'Prim.',12x,
     &     'Expon.',4x,'Coefficients')
 20   format(2x,i2,4x,i3,5x,i3,3x,a2,3(2x,f14.6))
      return
      end

      integer function BL_num_sets()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      BL_num_sets = num_bset
      return
      end

      integer function BL_num_types(tag)
      implicit none
      integer tag
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      if(tag.le.0 .or. tag.gt.max_tag)then
         call caserr('BL_num_types: basis tag out of range')
      endif
      BL_num_types = num_types(tag)
      return
      end

      subroutine basis_library(iout)
C ***********************************************************
C *Description:
C *Fills up the basis array with selected basis set.
C ***********************************************************
C ***********************************************************
C *Declarations
C *
      integer iout
C *Parameters                        
INCLUDE(common/dft_parameters)
C *In variables 
INCLUDE(common/dft_module_comm)
C *Out variables 
INCLUDE(common/dft_basis)
C *Scratch space and pointers

C *Functions

C *End declarations
C ********************************************************
      if(debug_sw) write(6,*) 'Entering basis_library'
      if(kown_sw.or.jown_sw) call read_inputfile(iout)
c     list_b='list.basis'
c     file_b='lib.basis'
      
C *
C *Open list to see if basis is contained within
C *
c     open(unit=bas_ch,file=list_b,status='unknown',form=formatted)
c     read(bas_ch,*) bsets_num
c     do lb=1,bsets_num
c       read(bas_ch,*) bset
c       if(bset(1:4).eq.bset_sel(1:4) found = .true.
c     enddo
c     close bas_ch
c     if (found) then
C *
C *Open basis set library and retreive basis set
C *
c       open(unit=bas_ch,file=file_b,status='unknown',form=formatted')
c       close bas_ch
c     else
c       write(6,*) 'Basis set not found'
c     endif        
      return
      end
      subroutine read_inputfile(iout)
C ******************************************************************
C *Description:                                                    *
C *Reads basis set from input file.
C *
C *Format input file should take
C *-----------------------------
C *
C * Keyword (either aobasis, kbasis or jbasis)
C * Number of unique centres
C * Number of shells on centre
C * Number of primitives in shell
C * Angular momentum of shell
C
C * Primitive exponent
C * Contraction coefficient
C ******************************************************************
      implicit none
C ******************************************************************
C *Declarations                                                    *
C *
      integer iout
C *Parameters
INCLUDE(common/dft_parameters) 
C *In variables
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_order_info)
INCLUDE(common/dft_mol_info)
C *Out variables
INCLUDE(common/dft_basis)

C *Local variables
      character*4 char_tmp
      integer lbset,ltyp,lshl,lprm
      integer nbasis_sets,nprm_count
      integer liw
      integer ibuff(4)
      logical print,sp_sw
      integer ierror,atom_id,atomno,angm,hybr,nshells
      integer nprims,type_num
      REAL expo(10),cs(10),cp(10),cd(10),cf(10),cg(10),c
       
c *Functions
      logical opg_root
      integer lenwrd

INCLUDE(common/dft_basis_api)    

C *End declarations                                             *
C ***************************************************************
     
      if(debug_sw) write(6,*) 'Entered read_inputfile'
      nbasis_sets=1
      if(jfit_sw) then
        if (nbasis_sets.ge.max_tag) then
           call caserr('No basis sets exceeds max_tag')
        endif
        nbasis_sets=nbasis_sets+1
        bset_tags(nbasis_sets)=nbasis_sets
      endif
      if(kfit_sw) then
        if (nbasis_sets.ge.max_tag) then
           call caserr('No basis sets exceeds max_tag')
        endif
        nbasis_sets=nbasis_sets+1
        bset_tags(nbasis_sets)=nbasis_sets
      endif

      do lbset=2,nbasis_sets

         ierror = BL_clear_basis_set(lbset)

         if(opg_root())then
 1000       format(a4)
            read(in_ch,1000) char_tmp
            call chtoi(ibuff(1),char_tmp)
         endif
         liw=8/lenwrd()
         call pg_brdcst(100,ibuff,4*liw,0)
         if(.not.opg_root())call itoch(ibuff(1),char_tmp)

         if(char_tmp(1:4).ne.'jbas') then
            if(char_tmp.ne.'kbas') then
               write(out_ch,*) 
     &              'You have not specified which basis this is.'
               write(out_ch,*) 
     &              'Use aobasis, jbasis or kbasis to specify.'
               call caserr('basis file error  - no basis type key')
            endif
         endif
         if(opg_root())read(in_ch,*) type_num
         call pg_brdcst(101,type_num,liw,0)

         do ltyp=1,type_num
           if(opg_root())read(in_ch,*) atomno
           if(opg_root())read(in_ch,*) nshells
           call pg_brdcst(102,atomno,liw,0)
           call pg_brdcst(103,nshells,liw,0)
           atom_id=BL_create_atomtag(lbset,atomno)
           if(nshells.gt.max_shel) then
              call caserr('basis file error - too many shells')
           endif
           do lshl=1,nshells
             if(opg_root())read(in_ch,*) nprims
             if(opg_root())read(in_ch,*) angm
             if(opg_root())read(in_ch,*) hybr
             call pg_brdcst(104,nprims,liw,0)
             call pg_brdcst(105,angm,liw,0)
             call pg_brdcst(106,hybr,liw,0)
             sp_sw = (angm-hybr.eq.1)
             nprm_count=0
             do lprm=1,nprims
               nprm_count=nprm_count+1
               if(nprm_count .gt. 10)
     +        call caserr('basis_library: too many prims in a shell, lim
     +it here is 10')
               cs(nprm_count)=1.0d0
               cp(nprm_count)=1.0d0
               cd(nprm_count)=1.0d0
               cf(nprm_count)=1.0d0
               cg(nprm_count)=1.0d0
               if(opg_root()) then
                  read(in_ch,*) expo(nprm_count),c
               endif
               call pg_brdcst(107,expo(nprm_count),8,0)
               call pg_brdcst(108,c,8,0)
               if(angm.eq.1) cs(nprm_count)=c
               if(angm.eq.2) cp(nprm_count)=c
               if(angm.eq.3) cd(nprm_count)=c
               if(angm.eq.4) cf(nprm_count)=c
               if(angm.eq.5) cg(nprm_count)=c
             enddo
             ierror=BL_import_shell(lbset,atom_id,nprims,angm,hybr,
     &            expo,cs,cp,cd,cf,cg)
           enddo 
        enddo
        print = (char_tmp .eq. 'jbas' .and. print_sw(DEBUG_JBAS))
     &       .or. (char_tmp .eq. 'kbas' .and. print_sw(DEBUG_KBAS))

        ierror = BL_assign_types_by_z(lbset)
        call checkin_basis(lbset, print)
        if(opg_root())ierror=BL_write_basis(lbset,iout)
      enddo
      if(debug_sw) write(6,*) 'Leaving read_inputfile'
      return
      end


C This source file contains utilities and interface routines for handling
C the basis set include files.

C Level 1 routines - used for initialising and handling the basis sets

      subroutine checkin_basis(tag,print)
c
C Check in a basis set
c Also copies to mbasis for hondo integral routines
c
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      integer tag
      integer ltyp,Abfn_num
      integer tot_nshl,tot_bafn,tot_nprm
      logical print
c
      integer ao_tag
      parameter(ao_tag=1)

      do ltyp=1,num_types(tag)
        Abfn(tag,ltyp)=Abfn_num(tag,ltyp)
      enddo

      call totshl_num(tot_nshl,tag,print)
      call totbfn_num(tot_bafn,tag,print)
      call totprm_num(tot_nprm,tag,print) 

      totshl(tag)=tot_nshl
      totbfn(tag)=tot_bafn
      totprm(tag)=tot_nprm
      
      maxi_shlA  = max(size_shlA, totshl(tag))
      maxi_basA  = max(size_basA, totbfn(tag))
      maxi_primA = max(size_primA,totprm(tag))

      size_shlA  = size_shlA  + totshl(tag)
      size_basA  = size_basA  + totbfn(tag)
      size_primA = size_primA + totprm(tag)
      
      num_bset = num_bset + 1 

      maxi_shlA  = maxi_shlA * num_bset
      maxi_basA  = maxi_basA * num_bset
      maxi_primA = maxi_primA * num_bset

      call nshelx_fill(tag)

      call list_basis_functions(tag)

      if (tag.eq.ao_tag) call find_num_grid_centres

      return
      end

      subroutine initialise_basis
C Initialise basis set include file. 
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
      integer lbas,ltyp,lprm
      do lbas=1,max_tag
        totshl(lbas)=0
        totbfn(lbas)=0
        totprm(lbas)=0
        num_types(lbas)=0
        do ltyp=1,max_atype
          atm_typ(lbas,ltyp)=0
          Aprm(lbas,ltyp)=0
          do lprm=1,max_prm
            cont_coeff(lbas,ltyp,lprm,1)=1.0d0
            cont_coeff(lbas,ltyp,lprm,2)=1.0d0
            cont_coeff(lbas,ltyp,lprm,3)=1.0d0
            cont_coeff(lbas,ltyp,lprm,4)=1.0d0
            cont_coeff(lbas,ltyp,lprm,5)=1.0d0
          enddo
        enddo
      enddo

      size_shlA  = 0
      size_basA  = 0
      size_primA = 0

      return
      end

C Level 2 routines used by level 1 routines
C
      function Abfn_num(tag,ltyp)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis) 
INCLUDE(common/dft_order_info)
      integer tag,ltyp
      integer Abfn_num
      integer lshl,lbfn
      Abfn_num=0
      do lshl=1,num_shl(tag,ltyp)
        do lbfn=hybrid(tag,ltyp,lshl),angmom(tag,ltyp,lshl)
          Abfn_num=Abfn_num+bf_num(lbfn)
        enddo
      enddo
      return
      end

      subroutine totbfn_num(nbasfn,tag,print)
C *******************************************************************
C *Description:                                                     *
C *For a given tag works out the total number of bfns in system.    *
C *******************************************************************
C *******************************************************************
C *Declarations
C *
C *Parameters 
INCLUDE(common/dft_parameters)
C *In variables 
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_order_info)
      integer tag
      logical print
C *Out variables
      integer nbasfn
C* Functions
      integer BL_get_atom_type
      logical opg_root
C *Local variables
      integer latm,lshl,lbfn
      integer atyp
      logical print_sw
C *End declarations 
C ****************************************************************** 
      nbasfn=0

      print_sw = print .and. opg_root()

      if(print_sw)write(6,*)'basis total for basis=',tag

      do latm=1,natoms

         atyp=BL_get_atom_type(tag,latm)

         if(atyp .ne. 0) then
         if(print_sw)write(6,*)'  atom ',latm, 'type ',atyp, 'shell ',
     &           num_shl(tag,atyp)

          do lshl=1,num_shl(tag,atyp)
             do lbfn=hybrid(tag,atyp,lshl),angmom(tag,atyp,lshl)
                nbasfn=nbasfn+bf_num(lbfn)
             enddo
             if(print_sw)
     &   write(6,*)'    shell ',lshl, 'hybrid',hybrid(tag,atyp,lshl),
     &        'angmom ',angmom(tag,atyp,lshl),'bf_num ',(bf_num(lbfn),
     &        lbfn=hybrid(tag,atyp,lshl),angmom(tag,atyp,lshl)),
     &        '   running tot',nbasfn
            enddo
         endif
      enddo
      return
      end

      subroutine totprm_num(tot_nprm,tag,print)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)
cps
INCLUDE(common/dft_order_info)

      integer tot_nprm,tag
      logical print
c
      integer latm,atyp,lshl,lbfn
      logical print_sw
C* Functions
      integer BL_get_atom_type
      logical opg_root
      tot_nprm=0

      print_sw = print .and. opg_root()

      if(print_sw)write(6,*)'primitive total for basis=',tag

      do latm=1,natoms

        atyp=BL_get_atom_type(tag,latm)
        if(atyp .ne. 0) then

        do lshl=1,num_shl(tag,atyp)

cps??? need to include all components here???

            do lbfn=hybrid(tag,atyp,lshl),angmom(tag,atyp,lshl)
               tot_nprm=tot_nprm + nprim(tag,atyp,lshl) * bf_num(lbfn)
            enddo

cps           tot_nprm=tot_nprm + nprim(tag,atyp,lshl)

            if(print_sw)write(6,*)'    shell ',lshl, 
     &           nprim(tag,atyp,lshl),
     &           '   running tot',tot_nprm

        enddo
        endif
      enddo
      return
      end

      subroutine totshl_num(tot_nshl,tag,print)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)
      integer tot_nshl,tag
      logical print
      integer latm,atyp
C* Functions
      integer BL_get_atom_type
      logical opg_root
      tot_nshl=0
      if(opg_root() .and. print)
     &     write(6,*)'Shell count for basis ',tag
      do latm=1,natoms
        atyp=BL_get_atom_type(tag,latm)
        if(atyp .ne. 0)then
           tot_nshl=tot_nshl+num_shl(tag,atyp)
           if(opg_root() .and. print)
     &          write(6,*)'  atom ',latm,'shells ',num_shl(tag,atyp)
        else
           if(opg_root() .and. print)
     &          write(6,*)'  atom ',latm,'no shells '
        endif
      enddo
      return
      end


C The following are routines which expand basis sets to data structures
C which can be used by the CCP1 DFT module

      subroutine expand_toshells(nprim_e,angmom_e,hybrid_e,
     &                           centre_e,pstart_e,
     &                           alpha_e,cont_coeff_e)
C *****************************************************************
C *Description: 
C *Expands the include file basis_cont_inf for use by intPack
C ******************************************************************
C ******************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)
C *Out variables
      integer nprim_e(num_bset,*)
      integer angmom_e(num_bset,*)
      integer hybrid_e(num_bset,*)
      integer centre_e(num_bset,*)
      integer pstart_e(num_bset,*)
      REAL alpha_e(num_bset,*)
      REAL cont_coeff_e(num_bset,*)

C* Functions
      integer BL_get_atom_type

C *Local variables
      integer lbse,latm,lshl
      integer count,pcount,pcount2
      integer nprm_count
      integer Anum,Hnum
      integer atag
      logical sptest_sw
C *End declarations
C *****************************************************************

C Loop over basis sets
      do lbse=1,num_bset
        count=0
        pcount=0
        nprm_count=0
c        write(6,*) 'Expanding basis set ',lbse
C Loop over atoms
        do latm=1,natoms

          atag=BL_get_atom_type(lbse,latm)

          if(atag .ne. 0)then

          pcount2=0
cc          write(6,*) 'Atom number ',latm,' has tag',atag
C Loop over shells on each atom centre
          do lshl=1,num_shl(lbse,atag)
            Anum = angmom(lbse,atag,lshl)
            Hnum = hybrid(lbse,atag,lshl)

c
c Is this shell an sp type?
            sptest_sw=(Anum.ne.Hnum)

            if(sptest_sw) then
              count=count+1
              nprim_e(lbse,count)  = nprim(lbse,atag,lshl)
              angmom_e(lbse,count) = Hnum  ! shell has the lower index
              hybrid_e(lbse,count) = Hnum  ! 
              centre_e(lbse,count) = latm
              pstart_e(lbse,count) = pcount+1
              nprm_count           = nprm_count+nprim_e(lbse,count) 
              do lprm=1,nprim_e(lbse,count)
                pcount                   = pcount + 1
                pcount2                  = pcount2 + 1
c      write(6,*)'assig s alpha',pcount,pcount2,alpha(lbse,atag,pcount2)
                alpha_e(lbse,pcount)     = alpha(lbse,atag,pcount2)
                cont_coeff_e(lbse,pcount)= 
     &            cont_coeff(lbse,atag,pcount2,Hnum)
              enddo
c
c reset primitive counter to copy same primitives again
c
            pcount2 = pcount2 - nprim_e(lbse,count)

            endif
c
c just do a normal shell
c
            count=count+1

            nprim_e(lbse,count)  = nprim(lbse,atag,lshl)
            angmom_e(lbse,count) = angmom(lbse,atag,lshl)
c            hybrid_e(lbse,count) = hybrid(lbse,atag,lshl)
cps  make this expanded shell a p shell
            hybrid_e(lbse,count) = angmom(lbse,atag,lshl)
c
            centre_e(lbse,count) = latm
            pstart_e(lbse,count) = pcount+1
            nprm_count           = nprm_count+nprim_e(lbse,count)

ccc      write(6,*) 'Shell:', nprim_e(lbse,count),angmom_e(lbse,count),
ccc     &hybrid_e(lbse,count),centre_e(lbse,count),pstart_e(lbse,count)

C Loop over primitives in shell
            do lprm=1,nprim_e(lbse,count)
              pcount                   = pcount + 1
              pcount2                  = pcount2 + 1
              alpha_e(lbse,pcount)     = alpha(lbse,atag,pcount2)
              cont_coeff_e(lbse,pcount)= 
     &            cont_coeff(lbse,atag,pcount2,Anum)

c      write(6,*)'assign alpha',pcount,pcount2,alpha(lbse,atag,pcount2)

ccc              write(6,*) alpha_e(lbse,pcount),cont_coeff_e(lbse,pcount)
            enddo
          enddo
          endif
        enddo
      enddo
c     stop
      return
      end
      subroutine expand_tobasisfns(nprim_e,angmom_e,pstart_e,centre_e,
     &                             alpha_e,cont_coeff_e)
C ******************************************************************
C *Description:
C *Expands basis sets to a basis function description.
C *  @@ only works for basis set 1
C ******************************************************************
      implicit none
C ******************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_basis)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_order_info)
C *Out variables
      integer nprim_e(num_bset,*)
      integer angmom_e(num_bset,*)
      integer pstart_e(num_bset,*)
      integer centre_e(num_bset,*)
      REAL alpha_e(num_bset,*)
      REAL cont_coeff_e(num_bset,*)

C *Local variables
      integer lbse,latm,lshl,laco,lprm,atag 
      integer nbas_c,prm_c,prm_c2
      integer nprm,l,n,f
      integer compl(5)
C *End declarations
C ***************************************************************
      data compl/1,3,6,10,15/

      do lbse=1,1
        prm_c = 0
        nprm  = 1
        nbas_c = 0
c       write(6,*) 'Basis:',lbse
        do latm=1,natoms

          atag=BL_get_atom_type(lbse,latm)

          if(atag .ne. 0)then

          prm_c2 = 0
          do lshl=1,num_shl(lbse,atag) 
            l = angmom(lbse,atag,lshl)
            n = nprim(lbse,atag,lshl)
            f = bf_start(l)
            do laco=1,compl(l)
              nbas_c = nbas_c +1
              nprim_e(lbse,nbas_c)  = n
              angmom_e(lbse,nbas_c) = f
              pstart_e(lbse,nbas_c) = nprm
              centre_e(lbse,nbas_c) = latm
              f=f+1
            enddo

            nprm = nprm + n
            do lprm=1,n
              prm_c  = prm_c  + 1
              prm_c2 = prm_c2 + 1
              alpha_e(lbse,prm_c)      = alpha(lbse,atag,prm_c2)
              cont_coeff_e(lbse,prm_c) = cont_coeff(lbse,atag,prm_c2,l)
            enddo

          enddo
          endif
        enddo
        do latm=1,totbfn(lbse)
c     write(6,*) 'Func:',latm,pstart_e(lbse,latm),nprim_e(lbse,latm)
        enddo
c       write(6,*) 'SIzes:',lbse,nbas_c,num_bset
      enddo 
      return
      end
      subroutine fit_norm(intwr_sw,lbse,shl_c)
      implicit none
INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_mbasis)
      logical intwr_sw
      integer lbse,shl_c
      integer k1,k2
      integer lig,ljg
      REAL ee,fac
      REAL dums,dump,dumd,dumf,dumg
      REAL facs,facp,facd,facf,facg
      REAL pt5,pt75,pt187,pt6562
      REAL pi32,toll
      data pi32 /5.56832799683170d0/
      data toll/1.0d-10/
      data pt187,pt6562 /1.875d+00,6.5625d+00/
      data pt5,pt75 /0.5d0,0.75d0/
      k1=kstart(lbse,shl_c)
      k2=(k1+kng(lbse,shl_c))-1
      facs = 0.0d0
      facp = 0.0d0
      facd = 0.0d0
      facf = 0.0d0
      facg = 0.0d0
      do lig=k1,k2
        do ljg=k1,lig
          ee = ex_m(lbse,lig) + ex_m(lbse,ljg)
          fac = ee*sqrt(ee)
          dums = cs(lbse,lig)*cs(lbse,ljg)/fac
          dump = pt5*cp(lbse,lig)*cp(lbse,ljg)/(ee*fac)
          dumd = pt75*cd(lbse,lig)*cd(lbse,ljg)/(ee**2*fac)
          dumf = pt187*cf(lbse,lig)*cf(lbse,ljg)/(ee**3*fac)
          dumg = pt6562*cg(lbse,lig)*cg(lbse,ljg)/(ee**4*fac)
          if (lig.ne.ljg) then
            dums = dums+dums
            dump = dump+dump
            dumd = dumd+dumd
            dumf = dumf+dumf
            dumg = dumg+dumg
          endif
          facs = facs+dums
          facp = facp+dump
          facd = facd+dumd
          facf = facf+dumf
          facg = facg+dumg
        enddo
      enddo 
      do lig = k1,k2
        if(facs.gt.toll) cs(lbse,lig)=cs(lbse,lig)/dsqrt(facs*pi32)
        if(facp.gt.toll) cp(lbse,lig)=cp(lbse,lig)/dsqrt(facp*pi32)
        if(facd.gt.toll) cd(lbse,lig)=cd(lbse,lig)/dsqrt(facd*pi32)
        if(facf.gt.toll) cf(lbse,lig)=cf(lbse,lig)/dsqrt(facf*pi32)
        if(facg.gt.toll) cg(lbse,lig)=cg(lbse,lig)/dsqrt(facg*pi32)
        if(intwr_sw) then
          write(6,*) 'Normalised Contraction Coefficients'
          write(6,*) 'Cs:',cs(lbse,lig)
          write(6,*) 'Cp:',cp(lbse,lig)
          write(6,*) 'Cd:',cd(lbse,lig)
          write(6,*) 'Cf:',cf(lbse,lig)
          write(6,*) 'Cg:',cg(lbse,lig)
        endif
      enddo 
      return
      end    
      subroutine nshelx_fill(lbas)
C ******************************************************************
C *Description:                                                    *
C *Fill GAMESS common block mbasis with fitting basis function info*
C 
C  Now called once per basis set on basis set checkin
c
C ******************************************************************
      implicit none
C *****************************************************************
C *Declarations
C *Parameters
INCLUDE(common/dft_parameters)
INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_module_comm)
C *Out variables
INCLUDE(common/dft_mbasis)
C * Function
      integer BL_get_atom_type
      logical opg_root
C *Local variables
      integer lbas,ltyp,latm,lshl,lprm
      integer shl_c,prm_c,loc_p
      integer l,h,hyb,p,loc,tloc,nprm
      integer pmin(5),pmax(5)
      integer ploc(5)
      logical intwr_sw,norm_sw

C *End declarations
C ****************************************************************

      data pmin/1,2,5,11,21/
      data pmax/1,4,10,20,35/
      data ploc/1,3,6,10,15/
c
c normalisation now done elsewhere
c
      norm_sw = .false.
C *
C *Set the following switch to true for debug information
C * - since we don't have a record of what they are for
C *   we'll print all of them
c
      intwr_sw = print_sw(DEBUG_AOBAS) .or. print_sw(DEBUG_JBAS)
     &     .or. print_sw(DEBUG_KBAS)

      if(intwr_sw .and. opg_root()) then
         write(6,*) 'Filling up GAMESS common block mbasis......'
         write(6,*) 'Number of basis sets:',num_bset
         write(6,*) 'Number of atoms:     ',natoms
      endif

c     if(lbas.gt.1) norm_sw = .true.

      if(intwr_sw) then
         write(6,*) 'Basis set number:    ',lbas
         write(6,*) 'Number of atom types:',num_types(lbas)
         write(6,*) 'Number of primitives:',totprm(lbas)
      endif
      do lprm=1,totprm(lbas)
         cs(lbas,lprm)=1.0d0
         cp(lbas,lprm)=1.0d0
         cd(lbas,lprm)=1.0d0
         cf(lbas,lprm)=1.0d0
         cg(lbas,lprm)=1.0d0
      enddo
      nbasfn(lbas)=0
      shl_c = 0
      prm_c = 0
      tloc  = 1
      nprm  = 1
C     *
C     *Loop over atoms
C     *
      do latm=1,natoms
         ltyp = BL_get_atom_type(lbas,latm)
         if(ltyp .ne. 0)then
            loc_p=1
            do lshl=1,num_shl(lbas,ltyp)
               shl_c=shl_c+1
c     
c     error checking
c     
               if(shl_c.gt.maxishl) then
                  write(6,*) 'Arrays in dft_mbasis too small for ',
     &                 shl_c,' shells. Increase size of maxishl'
                  stop
               endif
               l                  = angmom(lbas,ltyp,lshl)
               h                  = hybrid(lbas,ltyp,lshl)
               hyb = l - h
               p                  = nprim (lbas,ltyp,lshl)
               if(hyb.eq.0)then
                  kmin(lbas,shl_c)   = pmin(l)
                  loc                = ploc(l)
               else if(hyb.eq.1)then
                  kmin(lbas,shl_c)   = pmin(h)
c     @@ this would be wrong for an spd shell
                  loc                = ploc(l) + ploc(h)
               else
                  call caserr('nshelx_fill: unimplemented shell type')
               endif
               kmax(lbas,shl_c)   = pmax(l)
               nbasfn(lbas)       = nbasfn(lbas) + loc
               katom(lbas,shl_c)  = latm
               kng(lbas,shl_c)    = p
               ktype(lbas,shl_c)  = l
               kloc(lbas,shl_c)   = tloc
               tloc               = tloc+loc 
               kstart(lbas,shl_c) = nprm
               nprm               = nprm+p
               if(intwr_sw) then
                  write(6,*) 'Katom:',katom(lbas,shl_c)
                  write(6,*) 'Kng:  ',kng(lbas,shl_c)
                  write(6,*) 'Ktype:',ktype(lbas,shl_c)
                  write(6,*) 'Kmin: ',kmin(lbas,shl_c)
                  write(6,*) 'Kmax: ',kmax(lbas,shl_c)
                  write(6,*) 'Kloc: ',kloc(lbas,shl_c)
                  write(6,*) 'Kstar:',kstart(lbas,shl_c)
               endif
               do lprm=1,p
                  prm_c=prm_c+1
                  if(prm_c.gt.maxiprm) then
                     write(6,*)'Arrays in dft_mbasis too small for ',
     &                    prm_c,' primitives. Increase size of maxiprm'
                     stop
                  endif
                  ex_m(lbas,prm_c)   = alpha(lbas,ltyp,loc_p)
                  cs(lbas,prm_c) =
     &                 cont_coeff(lbas,ltyp,loc_p,1)
                  cp(lbas,prm_c) =
     &                 cont_coeff(lbas,ltyp,loc_p,2)
                  cd(lbas,prm_c) =
     &                 cont_coeff(lbas,ltyp,loc_p,3)
                  cf(lbas,prm_c) =
     &                 cont_coeff(lbas,ltyp,loc_p,4)
                  cg(lbas,prm_c) = 
     &                 cont_coeff(lbas,ltyp,loc_p,5)
                  loc_p=loc_p+1
                  if(intwr_sw) then
                     write(6,*) 'Ex:',ex_m(lbas,prm_c)
                     write(6,*) 'cs:',cs(lbas,prm_c)
                     write(6,*) 'cp:',cp(lbas,prm_c)
                     write(6,*) 'cd:',cd(lbas,prm_c)
                     write(6,*) 'cf:',cf(lbas,prm_c)
                     write(6,*) 'cg:',cg(lbas,prm_c)
                  endif
               enddo
            enddo
         endif
      enddo 
      nshell(lbas)=shl_c
      if(intwr_sw)write(6,*) 'Number of shells:',nshell(lbas)
      return
      end

      subroutine write_basis_set(bas_tag)
C     ****************************************************************
C     *Description:
C     *Writes a given basis set to the out channel.
C     ****************************************************************
      implicit none
C     ****************************************************************
C     *Declarations
C     *
C     *Parameters
INCLUDE(common/dft_parameters)
C     *In variables
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_module_comm)
      integer bas_tag
C     *Local variables
      integer ntyp,lshl
C     *End declarations
C     ****************************************************************
      out_ch=6
      write(out_ch,1000)
      write(out_ch,*) 'Number of distinct atom types:',
     &     num_types(bas_tag)
      write(out_ch,*) 'Number of basis functions    :',
     &     totbfn(bas_tag)
      write(out_ch,1010)
      do ntyp=1,num_types(bas_tag)
         do lshl=1,num_shl(bas_tag,ntyp)
            write(out_ch,1020) ntyp,lshl,nprim(bas_tag,ntyp,lshl),
     &           angmom(bas_tag,ntyp,lshl),
     &           hybrid(bas_tag,ntyp,lshl)
         enddo
      enddo

 1000 format(1x,'*******************************************************
     &********************',1x)
1010  format(1x,'Atm type    Shell no.   Prim no.   Ang Mom.   Hyb no.')
1020  format(1x,i2,9x,i2,11x,i2,9x,i2,10x,i2)
      return
      end 

      subroutine list_basis_functions(tag)

      implicit none

INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_basis)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_module_comm)

      integer tag

      integer latm, ltyp, loc_p, shl_c, l, h, hyb, p, lshl
      integer tloc, nprm, kmin, kmax, loc
      integer pmin(5),pmax(5)
      integer ploc(5)
      character *2 type(0:4), lab

      data pmin/1,2,5,11,21/
      data pmax/1,4,10,20,35/
      data ploc/1,3,6,10,15/
      data type/'s','p','d','f','g'/


      shl_c = 0
      tloc  = 1
      nprm  = 1

*     write(6,*)'shell list for basis # ',tag
*     write(6,*)'========================='

*     write(6,*)'shell  first  atom atom shell  nprm'
*     write(6,*)'        bfn        type type       '
*     write(6,*)'-----------------------------------'

      do latm=1,natoms
         ltyp = BL_get_atom_type(tag,latm)
         if(ltyp .ne. 0)then
            loc_p=1
            do lshl=1,num_shl(tag,ltyp)
               shl_c=shl_c+1
               l                  = angmom(tag,ltyp,lshl)
               h                  = hybrid(tag,ltyp,lshl)
               p                  = nprim (tag,ltyp,lshl)
               kmax  = pmax(l)
               hyb = l - h
               if(hyb.eq.0)then
                  kmin  = pmin(l)
                  loc   = ploc(l)
                  lab   = type(l)
               else if(hyb.eq.1)then
                  kmin  = pmin(h)
c @@ this would be wrong for an spd shell
                  loc   = ploc(l) + ploc(h)
                  lab = 'sp'
               else
                  call caserr('nshelx_fill: unimplemented shell type')
               endif
*              write(6,100)shl_c, tloc, latm, atom_tag(tag,latm),
*    &              lab, p
               tloc               = tloc+loc
*100           format(1x,4i6,2x,a2,i6)
            enddo
         endif
      enddo
      end

      subroutine basis_norm(memory_fp,matrix)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_memory_info)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_order_info)
INCLUDE(common/dft_mbasis)
      REAL memory_fp(*), matrix(*)
      integer tag
      REAL fact, factp
      integer ltyp,lshl,lprm,lhyb,lang,nprm,ang,loc,loc1
      integer atyp1, latm, ltyp2

      integer active_atom, lshl_at

      integer BL_get_atom_type

      logical opg_root
      logical out_sw
      integer hyb

      logical osp
      out_sw = print_sw(DEBUG_NORM) .and. opg_root()

      tag=2
      nprm=1
c
      call te_norm_2c(memory_fp,matrix)

C *
C *Normalize the Basis data set used in integ_te2c_rep and 
C *integ_te3c_rep
C *
      do lshl=1,nshell(tag)
         loc=kloc(tag,lshl)

c         write(6,*)'lshl,loc',lshl,loc,fact,kmin(tag,lshl),
c     &        kmax(tag,lshl)

         osp = (kmax(tag,lshl) - kmin(tag,lshl) +1 .eq. 4)

         if(osp)then

            fact=abs(matrix(loc))
            factp=abs(matrix(loc+1))
            loc = loc + 4

            fact=1.0d0/sqrt(fact)
            factp=1.0d0/sqrt(factp)

            do lprm=1,kng(tag,lshl)
               cs(tag,nprm)=cs(tag,nprm)*fact
               cp(tag,nprm)=cp(tag,nprm)*factp
               if(out_sw)then
                  write(6,*) 'Norm:',lshl,cs(tag,nprm),fact
                  write(6,*) 'Norm:',lshl,cp(tag,nprm),fact
               endif
               nprm=nprm+1
            enddo

         else
            
            fact=matrix(loc)
            do lang=kmin(tag,lshl),kmax(tag,lshl)
               fact=min(fact,matrix(loc))
c              write(6,*) 'Lang:',lang,loc,1.0d0/sqrt(matrix(loc))
               loc=loc+1
            enddo
            fact=1.0d0/sqrt(fact)
     
c           write(6,*) 'Fact:',lshl,fact
            ang=ktype(tag,lshl)
c           write(6,*)'ang,kng',ang, kng(tag,lshl)

            do lprm=1,kng(tag,lshl)

               if(ang.eq.1) cs(tag,nprm)=cs(tag,nprm)*fact
               if(ang.eq.2) cp(tag,nprm)=cp(tag,nprm)*fact
               if(ang.eq.3) cd(tag,nprm)=cd(tag,nprm)*fact
               if(ang.eq.4) cf(tag,nprm)=cf(tag,nprm)*fact
               if(ang.eq.5) cg(tag,nprm)=cg(tag,nprm)*fact

               if(out_sw)then
                  if(ang.eq.1) write(6,*) 'Norm:',lshl,cs(tag,nprm),fact
                  if(ang.eq.2) write(6,*) 'Norm:',lshl,cp(tag,nprm),fact
                  if(ang.eq.3) write(6,*) 'Norm:',lshl,cd(tag,nprm),fact
                  if(ang.eq.4) write(6,*) 'Norm:',lshl,cf(tag,nprm),fact
                  if(ang.eq.5) write(6,*) 'Norm:',lshl,cg(tag,nprm),fact
               endif
               nprm=nprm+1
            enddo

         endif
      enddo 
C *
C *Normalise the basis data set used in other CCP1 DFT routines
C *

c     write(6,*)'num_types',num_types(tag)
      do ltyp=1,num_types(tag)

         atyp1 = atm_typ(tag,ltyp)

c        write(6,*)'OUTER LOOP',ltyp, atyp1

         loc=1
         nprm=1

         active_atom  = -1  ! will address an atom of the correct type

         do lshl=1,nshell(tag)
           
            latm=katom(tag,lshl)
            ltyp2 = BL_get_atom_type(tag,latm)

c           write(6,*)'SHELL LOOP',lshl,latm,ltyp2

            loc1=kloc(tag,lshl)
c           write(6,*)'check_loc',loc,loc1

            fact=matrix(loc)
            osp = (kmax(tag,lshl) - kmin(tag,lshl) +1 .eq. 4)
            if(osp)then
               factp = matrix(loc+1)
               loc=loc+4
            else
               do lang=kmin(tag,lshl),kmax(tag,lshl)
                  fact=min(fact,matrix(loc))
c                 write(6,*) 'Lang:',lang,loc,1.0d0/sqrt(matrix(loc))
                  loc=loc+1
               enddo
            endif

            if(ltyp .eq. ltyp2 )then
c
c  We need to pick one atom of this type, so choose the
c  first
c
               if(active_atom .eq. -1)then
                  active_atom = latm
                  lshl_at = 0   ! counter on shells on this atom
               endif

               if(latm .ne. active_atom)then
c                  write(6,*)'shell is on wrong atom'
               else

                  lshl_at = lshl_at + 1

c                  write(6,*)'normalising for shell',ltyp,
c     &                 lshl,lshl_at,fact

                  if(osp)then

                     fact=1.0d0/sqrt(fact)
                     factp=1.0d0/sqrt(factp)

                     do lprm=1,nprim(tag,ltyp,lshl_at)
                        cont_coeff(tag,ltyp,nprm,1)
     &                       =cont_coeff(tag,ltyp,nprm,1)*fact
                        if(out_sw)
     &                       write(6,*) 'CCP_CC:',tag,ltyp,nprm,1,
     &                       cont_coeff(tag,ltyp,nprm,1),fact
                        cont_coeff(tag,ltyp,nprm,2)
     &                       =cont_coeff(tag,ltyp,nprm,2)*factp
                        if(out_sw)
     &                       write(6,*) 'CCP_CC:',tag,ltyp,nprm,2,
     &                       cont_coeff(tag,ltyp,nprm,2),fact
                        nprm=nprm+1
                     enddo

                  else

                     fact=1.0d0/sqrt(fact)

                     ang=angmom(tag,ltyp2,lshl_at)
                     hyb=hybrid(tag,ltyp2,lshl_at)

                     do lprm=1,nprim(tag,ltyp,lshl_at)
                        do lhyb=hyb,ang
                           cont_coeff(tag,ltyp,nprm,lhyb)
     &                          =cont_coeff(tag,ltyp,nprm,lhyb)*fact
                           if(out_sw)
     &                          write(6,*) 'CCP_CC:',tag,ltyp,nprm,lhyb,
     &                          cont_coeff(tag,ltyp,nprm,lhyb),fact
                        enddo
                        nprm=nprm+1
                     enddo

                  endif


               endif
            endif
         enddo

         if(active_atom .eq. -1)then
            write(6,*)'Warning: Redundant fitting basis set', ltyp
         endif

      enddo

      return
      end

      subroutine basis_norm_new(memory_fp,matrix)
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(../m4/common/sizes)
INCLUDE(common/dft_memory_info)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_order_info)
INCLUDE(common/dft_mbasis)
      REAL memory_fp(*), matrix(*)
      integer tag
      REAL fact, factp
      integer ltyp,lshl,lprm,lhyb,lang,nprm,ang,loc,loc1
      integer atyp1, latm, ltyp2,i

      integer active_atom, lshl_at

      integer BL_get_atom_type

      logical opg_root
      logical out_sw
      integer hyb

      logical osp

      out_sw = print_sw(DEBUG_NORM) .and. opg_root()

      tag=2
      nprm=1
c
      call te_norm_2c(memory_fp,matrix)

      write(6,*)'Normalisation integrals'
      do i = 1,nbasfn(tag)
         write(6,*)matrix(i)
      enddo

C *
C *Normalize the Basis data set used in integ_te2c_rep and integ_te3c_rep
C *
      write(6,*)'tag',tag
      do lshl=1,nshell(tag)
         loc=kloc(tag,lshl)

C        write(6,*)'lshl,loc',lshl,loc,fact,kmin(tag,lshl),
C    &        kmax(tag,lshl)

         osp = (kmax(tag,lshl) - kmin(tag,lshl) +1 .eq. 4)

         if(osp)then

            fact=abs(matrix(loc))
            factp=abs(matrix(loc+1))
            loc = loc + 4

            fact=1.0d0/sqrt(fact)
            factp=1.0d0/sqrt(factp)

            do lprm=1,kng(tag,lshl)
               cs(tag,nprm)=cs(tag,nprm)*fact
               cp(tag,nprm)=cp(tag,nprm)*factp
               if(out_sw)then
                  write(6,*) 'Norm:',lshl,cs(tag,nprm),fact
                  write(6,*) 'Norm:',lshl,cp(tag,nprm),fact
               endif
               nprm=nprm+1
            enddo

         else
            
         fact=abs(matrix(loc))
         do lang=kmin(tag,lshl),kmax(tag,lshl)
            if(abs(matrix(loc)).gt.1.0d-05) then
               fact=min(fact,matrix(loc))
            endif
            write(6,*) 'Lang:',lang,loc,1.0d0/sqrt(matrix(loc))
            loc=loc+1
         enddo
         fact=1.0d0/sqrt(fact)
     
c       write(6,*) 'Fact:',lshl,fact
        ang=ktype(tag,lshl)
        write(6,*)'ang,kng',ang, kng(tag,lshl)

        do lprm=1,kng(tag,lshl)

          if(ang.eq.1) cs(tag,nprm)=cs(tag,nprm)*fact
          if(ang.eq.2) cp(tag,nprm)=cp(tag,nprm)*fact
          if(ang.eq.3) cd(tag,nprm)=cd(tag,nprm)*fact
          if(ang.eq.4) cf(tag,nprm)=cf(tag,nprm)*fact
          if(ang.eq.5) cg(tag,nprm)=cg(tag,nprm)*fact

          if(out_sw)then
          if(ang.eq.1) write(6,*) 'Norm:',lshl,cs(tag,nprm),fact
          if(ang.eq.2) write(6,*) 'Norm:',lshl,cp(tag,nprm),fact
          if(ang.eq.3) write(6,*) 'Norm:',lshl,cd(tag,nprm),fact
          if(ang.eq.4) write(6,*) 'Norm:',lshl,cf(tag,nprm),fact
          if(ang.eq.5) write(6,*) 'Norm:',lshl,cg(tag,nprm),fact
          endif
          nprm=nprm+1
        enddo

        endif
      enddo 
C *
C *Normalise the basis data set used in other CCP1 DFT routines
C *

      write(6,*)'num_types',num_types(tag)
      do ltyp=1,num_types(tag)

         atyp1 = atm_typ(tag,ltyp)

         write(6,*)'OUTER LOOP',ltyp, atyp1

         loc=1
         nprm=1

         active_atom  = -1  ! will address an atom of the correct type

         do lshl=1,nshell(tag)
           
            latm=katom(tag,lshl)
            ltyp2 = BL_get_atom_type(tag,latm)

            write(6,*)'SHELL LOOP',lshl,latm,ltyp2

            loc1=kloc(tag,lshl)
            write(6,*)'check_loc',loc,loc1

            fact=abs(matrix(loc))

            osp = (kmax(tag,lshl) - kmin(tag,lshl) +1 .eq. 4)
            if(osp)then
               factp = abs(matrix(loc+1))
               loc=loc+4
            else
               do lang=kmin(tag,lshl),kmax(tag,lshl)
                  if(abs(matrix(loc)).gt.1.0d-05) then
                     fact=min(fact,matrix(loc))
                  endif
                  write(6,*) 'Lang:',lang,loc,1.0d0/sqrt(matrix(loc))
                  loc=loc+1
               enddo
            endif

            if(ltyp .eq. ltyp2 )then
c
c  We need to pick one atom of this type, so choose the
c  first
c
               if(active_atom .eq. -1)then
                  active_atom = latm
                  lshl_at = 0   ! counter on shells on this atom
               endif

               if(latm .ne. active_atom)then
                  write(6,*)'shell is on wrong atom'
               else

                  lshl_at = lshl_at + 1

                  write(6,*)'normalising for shell',ltyp,
     &                 lshl,lshl_at,fact

                  if(osp)then

                     fact=1.0d0/sqrt(fact)
                     factp=1.0d0/sqrt(factp)

                     do lprm=1,nprim(tag,ltyp,lshl_at)
                        cont_coeff(tag,ltyp,nprm,1)
     &                       =cont_coeff(tag,ltyp,nprm,1)*fact
                        if(out_sw)
     &                       write(6,*) 'CCP_CC:',tag,ltyp,nprm,1,
     &                       cont_coeff(tag,ltyp,nprm,1),fact
                        cont_coeff(tag,ltyp,nprm,2)
     &                       =cont_coeff(tag,ltyp,nprm,2)*factp
                        if(out_sw)
     &                       write(6,*) 'CCP_CC:',tag,ltyp,nprm,2,
     &                       cont_coeff(tag,ltyp,nprm,2),fact
                        nprm=nprm+1
                     enddo

                  else

                  fact=1.0d0/sqrt(fact)

                  ang=angmom(tag,ltyp2,lshl_at)
                  hyb=hybrid(tag,ltyp2,lshl_at)

                  do lprm=1,nprim(tag,ltyp,lshl_at)
                     do lhyb=hyb,ang
                        cont_coeff(tag,ltyp,nprm,lhyb)
     &                       =cont_coeff(tag,ltyp,nprm,lhyb)*fact
                        if(out_sw)
     &                       write(6,*) 'CCP_CC:',tag,ltyp,nprm,lhyb,
     &                       cont_coeff(tag,ltyp,nprm,lhyb),fact
                     enddo
                     nprm=nprm+1
                  enddo

                  endif


               endif
            endif
         enddo

         if(active_atom .eq. -1)then
            write(6,*)'Warning: Redundant fitting basis set', ltyp
         endif

      enddo

      return
      end
      subroutine ver_dft_basis(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/dft/basis.m,v $
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
