      Subroutine find_regions()
      implicit none
INCLUDE(common/dft_parameters)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_module_comm) 

      integer iatm,jatm,latm,latm2,latm3,lreg
      REAL xt,yt,zt,ra2,ra,distance
      REAL ra_list(max_atom,max_atom)
      integer num_atom
      logical assign(max_atom)
      integer iatom,buff_num

      REAL Rnear,Rbuff

      integer num_area
      integer num_atom_area(50)
      integer list_atom_area(50,max_atom)
      integer area_buff_num(50)
      integer area_buff_list(50,max_atom)

      Rnear=20.0d0
      Rbuff=30.0d0
      do latm=1,natoms
         assign(latm)=.false.
      enddo
c
c Calc distance array
      do iatm=1,natoms
        do jatm=1,natoms
          xt=atom_c(iatm,1)-atom_c(jatm,1)
          yt=atom_c(iatm,2)-atom_c(jatm,2)
          zt=atom_c(iatm,3)-atom_c(jatm,3)
          ra2=xt*xt+yt*yt+zt*zt
          ra=sqrt(ra2)
          ra_list(iatm,jatm)=ra
        enddo
      enddo
c
c Find regions and atoms within them
      num_area=0 
      do latm=1,natoms
        if(.not.assign(latm)) then
          num_area=num_area+1
          num_atom=0
c
          do latm2=1,natoms
            if(ra_list(latm,latm2).lt.Rnear.and.
     &      (.not.assign(latm2))) then
              num_atom=num_atom+1
              assign(latm2)=.true.
              list_atom_area(num_area,num_atom)=latm2
            endif
          enddo
          num_atom_area(num_area)=num_atom
        endif
      enddo
c
c Find buffer atoms
      do lreg=1,num_area
        buff_num=0
        do latm=1,natoms
          assign(latm)=.false.
        enddo
        do latm=1,num_atom_area(num_area)
          iatom=list_atom_area(lreg,latm)
          do latm2=1,natoms
            distance=ra_list(iatom,latm2)
            if(distance.gt.Rnear.and.distance.lt.Rbuff.and.
     &         (.not.assign(latm2))) then
              buff_num=buff_num+1
              area_buff_list(lreg,buff_num)=latm2
              assign(latm2)=.true.
            endif
          enddo
        enddo
        area_buff_num(lreg)=buff_num
      enddo
      
      write(6,10)
      write(6,20)
      write(6,30)
      write(6,40) num_area
      do lreg=1,num_area
        write(6,50) lreg,num_atom_area(lreg)
        write(6,60) area_buff_num(lreg)
      enddo
c     do lreg=1,num_area
c       do latm=1,num_atom_area(lreg)
c         write(6,*) lreg,list_atom_area(lreg,latm)
c       enddo
c     enddo
10    format(1x)
20    format(1x,'    Atom Based Subsystem Solver   ')
30    format(1x,'----------------------------------')
40    format(1x,'Number of regions:                ',i2)
50    format(1x,'Region ',i2,', no of atoms:       ',i2)
60    format(1x,'       ',2x,'  no of buffer atoms:',i2)
      return
      end
      subroutine ver_dft_geometry(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/dft/geometry.m,v $
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
