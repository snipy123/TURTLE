c
c  $Author: hvd $ $Revision: 5733 $ $Date: 2008-10-06 23:36:09 +0200 (Mon, 06 Oct 2008) $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/dft/xc_fit.m,v $
c
      subroutine exfit(ao_tag,natyp,kf_tag,nff,
     &                 apts,awpt,prpt,prwt,
     &                 fitmat,CKfit,indx,
     &                 bfn_val,abfn_val,
     &                 adens,bdens,kma,kmb,
     &                 memory_int,memory_fp,extwr_sw)
C ****************************************************************************
C *Description:								     *
C *Generate exchange/correlation contribution using auxiliary fitting        *
C ****************************************************************************
      implicit none
C ****************************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_module_comm)
INCLUDE(common/dft_basis_cont_inf)
INCLUDE(common/dft_basis)
      integer ao_tag,natyp,kf_tag,nff
      logical extwr_sw
      REAL adens(*),bdens(*)
C *Out variables
      REAL kma(*),kmb(*),xc_energy
C *Scratch space and pointers
      integer memory_int(*)
      REAL memory_fp(*)
      REAL apts(3,*),awpt(*)
      REAL prpt(natyp,*)
      REAL prwt(natyp,*)
      REAL fitmat(nff,*)
      REAL CKfit(*)
      integer indx(*)
      REAL bfn_val(*),abfn_val(*)
      REAL bfng_val(3),bfn_hess(6)
      integer scr_pt
C *Local variables
      integer latm,lrad,lang,latm2,atmt,atom_num,i
      integer lxci,lxcj
      integer nradpt_num(10),nang
      integer bfn_num
      REAL wi,what
      REAL dij(max_atom,max_atom),ra2_val(max_atom,2)
      REAL ra2_comp(max_atom,3)
      REAL pcorr(3),wt,rpt,rwt,alph,alph3
      REAL atom_xce(max_atom),atom_den(max_atom,2)
      REAL alpha_den,beta_den
      REAL xc_ept
      REAL xc_vpt(2),xc_dvpt(3,2)
      REAL rho(2),grho(3,2)
      REAL xp,yp,zp,xt,yt,zt
      REAL totden,totxce,dummy,rho2
C *Functions
      REAL sg1rad
      integer allocate_memory

C *
C *Clean arrays and variables
C *
      write(6,*) 'IN XCFIT',nff
c     xc_energy = 0.0d0
      dummy     = 0.0d0
      totden    = 0.0d0
      totxce    = 0.0d0
      alpha_den = 0.0d0
      beta_den  = 0.0d0
C *
C *Build up radial and angular sample grid points
C *
      if(lege_sw) 
     &   call glegend(thetpt_num,phipt_num,angupt_num,apts,awpt)
      if(lebe_sw) call lebedev(angupt_num,apts,awpt,extwr_sw)
      call premac(natyp,radpt_num,nradpt_num,prpt,prwt) 
C *
C *Calculate inter atom distance array
C *
      call dijcalc(dij)
C *
C *Calcs
C *
      nang=angupt_num
      do latm=1,natoms
        atmt             = atom_tag(ao_tag,latm)
        atom_num         = ian(latm)
        alph             = sg1rad(atom_num,extwr_sw)
        alph3            = alph**3
        atom_den(latm,1) = 0.0d0
        atom_den(latm,2) = 0.0d0
        atom_xce(latm)   = 0.0d0
        do lrad=1,nradpt_num(atmt)
          rpt=alph*prpt(atmt,lrad)
          rwt=alph3*prwt(atmt,lrad)
          if(sg1_sw) call sg1_select(rpt,alph,atom_num,nang,apts,awpt)
c
          do lang=1,nang
            pcorr(1)=apts(1,lang)*rpt+atom_c(latm,1)
            pcorr(2)=apts(2,lang)*rpt+atom_c(latm,2)
            pcorr(3)=apts(3,lang)*rpt+atom_c(latm,3)
            wt=awpt(lang)*rwt
            do latm2=1,natoms
              ra2_comp(latm2,1)=pcorr(1)-atom_c(latm2,1)
              ra2_comp(latm2,2)=pcorr(2)-atom_c(latm2,2)
              ra2_comp(latm2,3)=pcorr(3)-atom_c(latm2,3)
              ra2_val(latm2,1)=ra2_comp(latm2,1)*ra2_comp(latm2,1)+
     &                         ra2_comp(latm2,2)*ra2_comp(latm2,2)+
     &                         ra2_comp(latm2,3)*ra2_comp(latm2,3)
              ra2_val(latm2,2)=sqrt(ra2_val(latm2,1))
            enddo
C *
C *Compute weight according to modified becke weight partitioning
C *
            call beckewt_xfit(dij,ra2_val,pcorr,latm,wt)
            xp=pcorr(1)
            yp=pcorr(2)
            zp=pcorr(3)
C *
C *Evaluate ao basis functions at sample point
C *
            call bas_val_xfit(ao_tag,
     &                   .true.,.false.,.false.,
     &                   ra2_comp,ra2_val,wt,
     &                   bfn_val,bfng_val,bfn_hess)
C *
C *Calculate rho 
C *
            call den_val_xfit(rks_sw,.false.,adens,bdens,1,
     &                   bfn_val,bfng_val,bfn_hess,
     &                   rho,grho)
C *
C *Evaluate functional at grid point
C *
            call ecfunc_xfit(rho,grho,wt,
     &                  xc_ept,xc_vpt,xc_dvpt)
C *
C *Evaluate fitting basis functions at sample point
C *
            call auxval(kf_tag,ra2_comp,ra2_val,abfn_val)
C *
C *Form fitting matrices
C *
            do lxci=1,nff
              wi=abfn_val(lxci)*wt
c             write(6,*) 'auxval:',abfn_val(lxci)
              CKfit(lxci)=CKfit(lxci)+rho(1)*wi
              do lxcj=1,nff
                fitmat(lxci,lxcj)=fitmat(lxci,lxcj)+abfn_val(lxcj)*wi
              enddo
            enddo

C *
C *Perform various sums for output
C *
            atom_den(latm,1)=atom_den(latm,1)+rho(1)*wt
            atom_den(latm,2)=atom_den(latm,2)+rho(2)*wt
            atom_xce(latm)=atom_xce(latm)+xc_ept*wt
          enddo 
        enddo
      enddo
C *
C *Form fitting coefficients
C *
      scr_pt=allocate_memory(nff,'d')
      write(6,*) 'Before call to mats'
      call gmem_check_guards
      call mat_ludcmp(fitmat,nff,memory_fp(scr_pt),indx,what)
      write(6,*) 'Between calls'
      call gmem_check_guards
      call mat_lubksb(fitmat,nff,indx,CKfit)
      write(6,*) 'After call to mats'
      call gmem_check_guards
      call free_memory(scr_pt,'d')
      write(6,*) 'Number of xfit basis functions:',nff
      do latm=1,nff
        write(6,*) 'KFit:',CKfit(latm)
      enddo
C*
C* Form KS matrix
C*
      write(6,*) 'Entering o3driver'
      call caserr('update with phils o3driver')
      call o3driver(ao_tag,kf_tag,memory_int,memory_fp,CKfit,kma,kmb)

      write(6,*) 'Leaving o3driver' 
      do latm=1,natoms
        alpha_den = alpha_den+atom_den(latm,1)
        beta_den  = beta_den+atom_den(latm,2)
        totden    = totden+atom_den(latm,1)
        totxce    = totxce+atom_xce(latm)
      enddo
      XC_energy=totxce
      write(6,*) 'XC_energy',XC_energy
      write(6,*) 'Leaving xcfit'
      return
      end
      subroutine beckewt_xfit(dij,ra2_val,pcorr,latm,wt)
C *****************************************************************************
C *Description:								      *
C *Calculates Becke weight at point                                           *
C *****************************************************************************
      implicit none
C *****************************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_mol_info)
      REAL ra2_val(max_atom,2)
      REAL dij(max_atom,max_atom)
      REAL pcorr(3)
      integer latm
C *In/out variables
      REAL wt
C *Local variables
      integer i,j,n
      REAL radi,radj,ratij,uij,aij,fk,sk,tbeckewt
      REAL beckew(max_atom),rpi,rpj,xt,yt,zt
C *Functions
      REAL srad
C *End declarations                                                           *
C *****************************************************************************
      do 10 i=1,natoms
         sk=1.0d0
         do 20 j=1,natoms
            if(j.eq.i) goto 20
            radi=srad(ian(i))
            radj=srad(ian(j))
            ratij=radi/radj
            uij=(ratij-1.0d0)/(ratij+1.0d0)
            aij=uij/((uij*uij)-1.0d0)
            if(abs(aij).gt.0.5d0)aij=0.5d0*abs(aij)/aij
            uij=(ra2_val(i,2)-ra2_val(j,2))/dij(i,j)
            fk=uij+aij*(1.0d0-(uij*uij))
            fk=1.5d0*fk-0.5d0*fk*fk*fk
            fk=1.5d0*fk-0.5d0*fk*fk*fk
            fk=1.5d0*fk-0.5d0*fk*fk*fk
            sk=sk*0.5d0*(1.0d0-fk)
 20      continue
         beckew(i)=sk
 10   continue
      tbeckewt=0.0d0
      do 30 n=1,natoms
         tbeckewt=tbeckewt+beckew(n)
 30   continue
      wt=wt*(beckew(latm)/tbeckewt)
      return
      end
      subroutine bas_val_xfit(tag,local_sw,gradient_sw,hessian_sw,
     &                   ra2_comp,ra2_val,wt,
     &                   bfn_val,bfng_val,bfn_hess)
C *****************************************************************************
C *Description:								      *
C *Calculate value of basis functions at at point			      *
C *****************************************************************************
      implicit none
C *****************************************************************************
C *Declarations
C *
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_numbers)
INCLUDE(common/dft_basis_cont_inf)
INCLUDE(common/dft_basis)
INCLUDE(common/dft_mol_info)
INCLUDE(common/dft_order_info)
      REAL ra2_comp(max_atom,3)
      REAL ra2_val(max_atom,2)
      REAL wt
      integer tag
      logical local_sw,gradient_sw,hessian_sw
C *Out variables							      *
      REAL bfn_val(*)
      REAL bfng_val(3,*)
      REAL bfn_hess(6,*)
C *Local variables							      *
      integer lcent,lshl,lprm,lhyb,lbas
      integer num_cent
      integer bpos,bfnum,bfn,blo
      integer nshells,centre,nprm,ploc,ll,lh
      REAL tol
      REAL xd,yd,zd,ra2,xx,yy,zz,xy,xz,yz
      REAL alp,cc,expo,cexpo,wexpo,texpo
      REAL talp,talpe,cctalpe,t1
      REAL bval,bvalgx,bvalgy,bvalgz
      REAL cexpox,cexpoy,cexpoz
      REAL falpe2e,hvalgx,hvalgy,hvalgz
      REAL norm_fac
      integer hxx,hyy,hzz,hxy,hxz,hyz
      integer px,py,pz,dxx,dyy,dzz,dxy,dxz,dyz
      REAL g,dg,ddg
      REAL dgu,ddgu
      REAL gx,gy,gz
      REAL gr,gxr,gyr,gzr
      REAL dgx,dgy,dgz
      REAL dgxx,dgyy,dgzz,dgxy,dgxz,dgyz
      REAL dgxxr,dgyyr,dgzzr,dgxyr,dgxzr,dgyzr
      REAL dgxxx,dgxxy,dgxxz,dgxyy,dgyyy
      REAL dgyyz,dgxzz,dgyzz,dgzzz,dgxyz
      REAL ddgx,ddgy,ddgz
      REAL ddgxxx,ddgxxy,ddgxxz,ddgxyy,ddgxyz,ddgxzz,ddgyyy
      REAL ddgyyz,ddgyzz,ddgzzz
      REAL ddgxxxx,ddgxxxy,ddgxxxz,ddgxxyy,ddgxxyz,ddgxxzz
      REAL ddgxyyy,ddgxyyz,ddgxyzz,ddgxzzz,ddgyyyy,ddgyyyz
      REAL ddgyyzz,ddgyzzz,ddgzzzz
C *End declarations							      *
C *****************************************************************************
C 
C Clean arrays
C 
      rt3=dsqrt(3.0d0)
      hxx=1
      hyy=2
      hzz=3
      hxy=4
      hxz=5
      hyz=6
      call aclear_dp(bfn_val,totbfn(tag),0.0d0)
      bpos  = 0
      bfnum = 0
      tol   = 1.0d-60
      num_cent=natoms
C *
C *Hessian for first derivatives
C *
      if(hessian_sw) then
        call aclear_dp(bfng_val,3*totbfn(tag),0.0d0)
        call aclear_dp(bfn_hess,6*totbfn(tag),0.0d0)
        bfn=1
        do lcent=1,num_cent
           centre  = atom_tag(tag,lcent)
           nshells = num_shl(tag,centre)
           ra2     = ra2_val(lcent,1)
           xd      = ra2_comp(lcent,1)
           yd      = ra2_comp(lcent,2)
           zd      = ra2_comp(lcent,3)
           ra2     = xd*xd+yd*yd+zd*zd
           xx      = xd*xd
           xy      = xd*yd
           xz      = xd*zd
           yy      = yd*yd
           yz      = yd*zd
           zz      = zd*zd
           ploc    = 0
           do lshl=1,nshells
             nprm   = nprim(tag,centre,lshl)
             lh     = hybrid(tag,centre,lshl)
             ll     = angmom(tag,centre,lshl)
C
C loop over primitives in shell
             do lprm=1,nprm
               ploc    = ploc + 1
               blo     = bfn
               bpos    = 0
               alp     = alpha(tag,centre,ploc)
               expo    = exp(-alp*ra2)
               talp    = -2.0d0*alp
               dgu     = talp*expo
               ddgu    = 4.0d0*alp*alp
C
C loop over hybrid angular momentum numbers e.g. sp shells
                 do lhyb=lh,ll
                   cc      = cont_coeff(tag,centre,ploc,lhyb)
                   g       = expo*cc
                   dg      = dgu*cc
                   ddg     = ddgu*g
C
C Basis function values
C
C S functions
      if(lhyb.eq.1) then
        bfn_val(blo) = bfn_val(blo) + g
        bfng_val(1,blo) = bfng_val(1,blo) + dg*xd
        bfng_val(2,blo) = bfng_val(2,blo) + dg*yd
        bfng_val(3,blo) = bfng_val(3,blo) + dg*zd
c
c
        ddgx = ddg*xd
        ddgy = ddg*yd
        ddgz = ddg*zd
        bfn_hess(hxx,blo) = bfn_hess(hxx,blo) + dg + xd*ddgx
        bfn_hess(hyy,blo) = bfn_hess(hyy,blo) + dg + yd*ddgy
        bfn_hess(hzz,blo) = bfn_hess(hzz,blo) + dg + zd*ddgz
        bfn_hess(hxy,blo) = bfn_hess(hxy,blo) + xd*ddgy
        bfn_hess(hxz,blo) = bfn_hess(hxz,blo) + xd*ddgz
        bfn_hess(hyz,blo) = bfn_hess(hyz,blo) + yd*ddgz
        blo = blo+1
        bpos= bpos+1
      endif  
C
C Px
      if(lhyb.eq.2) then
        px=blo
        py=blo+1
        pz=blo+2
        bfn_val(px) = bfn_val(px) + g*xd
        bfn_val(py) = bfn_val(py) + g*yd
        bfn_val(pz) = bfn_val(pz) + g*zd
        bfng_val(1,px) = bfng_val(1,px) + g + xx*dg
        bfng_val(2,px) = bfng_val(2,px) +     xy*dg
        bfng_val(3,px) = bfng_val(3,px) +     xz*dg
        bfng_val(1,py) = bfng_val(1,py) +     xy*dg
        bfng_val(2,py) = bfng_val(2,py) + g + yy*dg
        bfng_val(3,py) = bfng_val(3,py) +     yz*dg
        bfng_val(1,pz) = bfng_val(1,pz) +     xz*dg
        bfng_val(2,pz) = bfng_val(2,pz) +     yz*dg
        bfng_val(3,pz) = bfng_val(3,pz) + g + zz*dg
c
c
        dgx  = dg*xd
        dgy  = dg*yd
        dgz  = dg*zd
        ddgx = ddg*xd
        ddgy = ddg*yd
        ddgz = ddg*zd
        ddgxxx = ddgx*xx
        ddgxxy = ddgx*xy
        ddgxxz = ddgx*xz
        ddgxyy = ddgx*yy
        ddgxyz = ddgx*yz
        ddgxzz = ddgx*zz
        ddgyyy = ddgy*yy
        ddgyyz = ddgy*yz
        ddgyzz = ddgy*zz
        ddgzzz = ddgz*zz
C
        bfn_hess(hxx,px) = bfn_hess(hxx,px) +3.d0*dgx + ddgxxx
        bfn_hess(hyy,px) = bfn_hess(hyy,px) +     dgx + ddgxyy
        bfn_hess(hzz,px) = bfn_hess(hzz,px) +     dgx + ddgxzz
        bfn_hess(hxy,px) = bfn_hess(hxy,px) +     dgy + ddgxxy
        bfn_hess(hxz,px) = bfn_hess(hxz,px) +     dgz + ddgxxz
        bfn_hess(hyz,px) = bfn_hess(hyz,px) +           ddgxyz
C
        bfn_hess(hxx,py) = bfn_hess(hxx,py) +     dgy + ddgxxy
        bfn_hess(hyy,py) = bfn_hess(hyy,py) +3.d0*dgy + ddgyyy
        bfn_hess(hzz,py) = bfn_hess(hzz,py) +     dgy + ddgyzz
        bfn_hess(hxy,py) = bfn_hess(hxy,py) +     dgx + ddgxyy
        bfn_hess(hxz,py) = bfn_hess(hxz,py) +           ddgxyz
        bfn_hess(hyz,py) = bfn_hess(hyz,py) +     dgz + ddgyyz
C
        bfn_hess(hxx,pz) = bfn_hess(hxx,pz) +     dgz + ddgxxz
        bfn_hess(hyy,pz) = bfn_hess(hyy,pz) +     dgz + ddgyyz
        bfn_hess(hzz,pz) = bfn_hess(hzz,pz) +3.d0*dgz + ddgzzz
        bfn_hess(hxy,pz) = bfn_hess(hxy,pz) +           ddgxyz
        bfn_hess(hxz,pz) = bfn_hess(hxz,pz) +     dgx + ddgxzz
        bfn_hess(hyz,pz) = bfn_hess(hyz,pz) +     dgy + ddgyzz
        bpos = bpos+3
        blo  = blo+3
      endif 
C
C D functions
      if(lhyb.eq.3) then
        dxx=blo
        dyy=blo+1
        dzz=blo+2
        dxy=blo+3
        dxz=blo+4
        dyz=blo+5

        gr = g*rt3
        gx = g*xd
        gy = g*yd
        gz = g*zd
        gxr = gx*rt3
        gyr = gy*rt3
        gzr = gz*rt3
        dgxx  = dg*xx
        dgyy  = dg*yy
        dgzz  = dg*zz
        dgxy  = dg*xy
        dgxz  = dg*xz
        dgyz  = dg*yz

        dgxxr = dgxx*rt3
        dgyyr = dgyy*rt3
        dgzzr = dgzz*rt3
        dgxyr = dgxy*rt3
        dgxzr = dgxz*rt3
        dgyzr = dgyz*rt3

        dgxxx = dgxx*xd
        dgxxy = dgxx*yd
        dgxxz = dgxx*zd
        dgxyy = dgxy*yd
        dgyyy = dgyy*yd
        dgyyz = dgyy*zd
        dgxzz = dgxz*zd
        dgyzz = dgyz*zd
        dgzzz = dgzz*zd
        dgxyz = dgxy*zd
        bfn_val(dxx) = bfn_val(dxx) + g*xx
        bfn_val(dyy) = bfn_val(dyy) + g*yy
        bfn_val(dzz) = bfn_val(dzz) + g*zz
        bfn_val(dxy) = bfn_val(dxy) + g*xy*rt3
        bfn_val(dxz) = bfn_val(dxz) + g*xz*rt3
        bfn_val(dyz) = bfn_val(dyz) + g*yz*rt3
        bfng_val(1,dxx) = bfng_val(1,dxx) + 2.d0*gx + dgxxx
        bfng_val(2,dxx) = bfng_val(2,dxx) +          dgxxy
        bfng_val(3,dxx) = bfng_val(3,dxx) +          dgxxz
        bfng_val(1,dyy) = bfng_val(1,dyy) +          dgxyy
        bfng_val(2,dyy) = bfng_val(2,dyy) + 2.d0*gy + dgyyy
        bfng_val(3,dyy) = bfng_val(3,dyy) +          dgyyz
        bfng_val(1,dzz) = bfng_val(1,dzz) +          dgxzz
        bfng_val(2,dzz) = bfng_val(2,dzz) +          dgyzz
        bfng_val(3,dzz) = bfng_val(3,dzz) + 2.d0*gz + dgzzz
        bfng_val(1,dxy) = bfng_val(1,dxy) +    gyr + dgxxy*rt3
        bfng_val(2,dxy) = bfng_val(2,dxy) +    gxr + dgxyy*rt3
        bfng_val(3,dxy) = bfng_val(3,dxy) +          dgxyz*rt3
        bfng_val(1,dxz) = bfng_val(1,dxz) +    gzr + dgxxz*rt3
        bfng_val(2,dxz) = bfng_val(2,dxz) +          dgxyz*rt3
        bfng_val(3,dxz) = bfng_val(3,dxz) +    gxr + dgxzz*rt3
        bfng_val(1,dyz) = bfng_val(1,dyz) +          dgxyz*rt3
        bfng_val(2,dyz) = bfng_val(2,dyz) +    gzr + dgyyz*rt3
        bfng_val(3,dyz) = bfng_val(3,dyz) +    gyr + dgyzz*rt3

        ddgxxxx = ddg*xx*xx
        ddgxxxy = ddg*xx*xy
        ddgxxxz = ddg*xx*xz
        ddgxxyy = ddg*xx*yy
        ddgxxyz = ddg*xx*yz
        ddgxxzz = ddg*xx*zz
        ddgxyyy = ddg*xy*yy
        ddgxyyz = ddg*xy*yz
        ddgxyzz = ddg*xy*zz
        ddgxzzz = ddg*xz*zz
        ddgyyyy = ddg*yy*yy
        ddgyyyz = ddg*yy*yz
        ddgyyzz = ddg*yy*zz
        ddgyzzz = ddg*yz*zz
        ddgzzzz = ddg*zz*zz
        bfn_hess(hxx,dxx) = bfn_hess(hxx,dxx)+g+g+5.d0*dgxx + ddgxxxx
        bfn_hess(hyy,dxx) = bfn_hess(hyy,dxx)+        dgxx + ddgxxyy
        bfn_hess(hzz,dxx) = bfn_hess(hzz,dxx)+        dgxx + ddgxxzz
        bfn_hess(hxy,dxx) = bfn_hess(hxy,dxx)+   dgxy+dgxy + ddgxxxy
        bfn_hess(hyz,dxx) = bfn_hess(hyz,dxx)+               ddgxxyz
        bfn_hess(hxz,dxx) = bfn_hess(hxz,dxx)+   dgxz+dgxz + ddgxxxz
c       write(6,*) 'X:',xd
c       write(6,*) 'Y:',yd
c       write(6,*) 'Z:',zd
c       write(6,*) 'G:',g
c       write(6,*) 'DG:',dg
c       write(6,*) 'DDG:',ddg
c       write(6,*) 'dgxx',dgxx
c       write(6,*) 'dgxy',dgxy
c       write(6,*) 'dgxz',dgxz
c       write(6,*) 'dgyy',dgyy
c       write(6,*) 'dgyz',dgyz
c       write(6,*) 'dgzz',dgzz
c       write(6,*)'ddgxxxx ',ddg*xx*xx
c       write(6,*)'ddgxxxy ',ddg*xx*xy
c       write(6,*)'ddgxxxz ',ddg*xx*xz
c       write(6,*)'ddgxxyy ',ddg*xx*yy
c       write(6,*)'ddgxxyz ',ddg*xx*yz
c       write(6,*)'ddgxxzz ',ddg*xx*zz
c       write(6,*)'ddgxyyy ',ddg*xy*yy
c       write(6,*)'ddgxyyz ',ddg*xy*yz
c       write(6,*)'ddgxyzz ',ddg*xy*zz
c       write(6,*)'ddgxzzz ',ddg*xz*zz
c       write(6,*)'ddgyyyy ',ddg*yy*yy
c       write(6,*)'ddgyyyz ',ddg*yy*yz
c       write(6,*)'ddgyyzz ',ddg*yy*zz
c       write(6,*)'ddgyzzz ',ddg*yz*zz
c       write(6,*)'ddgzzzz ',ddg*zz*zz
c       write(6,*) 'HXX:',bfn_hess(1,dxx)
c       write(6,*) 'HYY:',bfn_hess(2,dxx)
c       write(6,*) 'HZZ:',bfn_hess(3,dxx)
c       write(6,*) 'HXY:',bfn_hess(4,dxx)
c       write(6,*) 'HYZ:',bfn_hess(5,dxx)
c       write(6,*) 'HXZ:',bfn_hess(6,dxx)
c       stop

C
        bfn_hess(hxx,dyy) = bfn_hess(hxx,dyy)+        dgyy + ddgxxyy
        bfn_hess(hyy,dyy) = bfn_hess(hyy,dyy)+g+g+5.d0*dgyy + ddgyyyy
        bfn_hess(hzz,dyy) = bfn_hess(hzz,dyy)+        dgyy + ddgyyzz
        bfn_hess(hxy,dyy) = bfn_hess(hxy,dyy)+   dgxy+dgxy + ddgxyyy
        bfn_hess(hyz,dyy) = bfn_hess(hyz,dyy)+   dgyz+dgyz + ddgxyyz
        bfn_hess(hxz,dyy) = bfn_hess(hxz,dyy)+               ddgxyyz
C
c       write(6,*) 'YY'
c       write(6,*) 'HXX:',bfn_hess(1,dyy)
c       write(6,*) 'HYY:',bfn_hess(2,dyy)
c       write(6,*) 'HZZ:',bfn_hess(3,dyy)
c       write(6,*) 'HXY:',bfn_hess(4,dyy)
c       write(6,*) 'HYZ:',bfn_hess(5,dyy)
c       write(6,*) 'HXZ:',bfn_hess(6,dyy)
c       
        bfn_hess(hxx,dzz) = bfn_hess(hxx,dzz)+        dgzz + ddgxxzz
        bfn_hess(hyy,dzz) = bfn_hess(hyy,dzz)+        dgzz + ddgyyzz
        bfn_hess(hzz,dzz) = bfn_hess(hzz,dzz)+g+g+5.d0*dgzz + ddgzzzz
        bfn_hess(hxy,dzz) = bfn_hess(hxy,dzz)+               ddgxyzz
        bfn_hess(hyz,dzz) = bfn_hess(hyz,dzz)+   dgyz+dgyz + ddgyzzz
        bfn_hess(hxz,dzz) = bfn_hess(hxz,dzz)+   dgxz+dgxz + ddgxzzz
c       write(6,*) 'ZZ'
c       write(6,*) 'HXX:',bfn_hess(1,dzz)
c       write(6,*) 'HYY:',bfn_hess(2,dzz)
c       write(6,*) 'HZZ:',bfn_hess(3,dzz)
c       write(6,*) 'HXY:',bfn_hess(4,dzz)
c       write(6,*) 'HYZ:',bfn_hess(5,dzz)
c       write(6,*) 'HXZ:',bfn_hess(6,dzz)

C
        bfn_hess(hxx,dxy) = bfn_hess(hxx,dxy)+  3.d0*dgxyr + ddgxxxy*rt3
        bfn_hess(hyy,dxy) = bfn_hess(hyy,dxy)+  3.d0*dgxyr + ddgxyyy*rt3
        bfn_hess(hzz,dxy) = bfn_hess(hzz,dxy)+       dgxyr + ddgxyzz*rt3
        bfn_hess(hxy,dxy) = bfn_hess(hxy,dxy)+gr+dgxxr+dgyyr+ddgxxyy*rt3
        bfn_hess(hyz,dxy) = bfn_hess(hyz,dxy)+       dgxzr + ddgxyyz*rt3
     +    
        bfn_hess(hxz,dxy) = bfn_hess(hxz,dxy)+       dgyzr + ddgxxyz*rt3
c       write(6,*) 'XY'
c       write(6,*) 'HXX:',bfn_hess(1,dxy)
c       write(6,*) 'HYY:',bfn_hess(2,dxy)
c       write(6,*) 'HZZ:',bfn_hess(3,dxy)
c       write(6,*) 'HXY:',bfn_hess(4,dxy)
c       write(6,*) 'HYZ:',bfn_hess(5,dxy)
c       write(6,*) 'HXZ:',bfn_hess(6,dxy)

C
        bfn_hess(hxx,dxz) = bfn_hess(hxx,dxz)+ 3.d0*dgxzr  + ddgxxxz*rt3
        bfn_hess(hyy,dxz) = bfn_hess(hyy,dxz)+      dgxzr  + ddgxyyz*rt3
        bfn_hess(hzz,dxz) = bfn_hess(hzz,dxz)+ 3.d0*dgxzr  + ddgxzzz*rt3
        bfn_hess(hxy,dxz) = bfn_hess(hxy,dxz)+      dgyzr  + ddgxxyz*rt3
        bfn_hess(hyz,dxz) = bfn_hess(hyz,dxz)+      dgxyr  + ddgxyzz*rt3
        bfn_hess(hxz,dxz) = bfn_hess(hxz,dxz)+gr+dgxxr+dgzzr+ddgxxzz*rt3
c       write(6,*) 'XZ'
c       write(6,*) 'HXX:',bfn_hess(1,dxz)
c       write(6,*) 'HYY:',bfn_hess(2,dxz)
c       write(6,*) 'HZZ:',bfn_hess(3,dxz)
c       write(6,*) 'HXY:',bfn_hess(4,dxz)
c       write(6,*) 'HYZ:',bfn_hess(5,dxz)
c       write(6,*) 'HXZ:',bfn_hess(6,dxz)

C
        bfn_hess(hxx,dyz) = bfn_hess(hxx,dyz)+      dgyzr  + ddgxxyz*rt3
        bfn_hess(hyy,dyz) = bfn_hess(hyy,dyz)+ 3.d0*dgyzr  + ddgyyyz*rt3
        bfn_hess(hzz,dyz) = bfn_hess(hzz,dyz)+ 3.d0*dgyzr  + ddgyzzz*rt3
        bfn_hess(hxy,dyz) = bfn_hess(hxy,dyz)+      dgxzr  + ddgxyyz*rt3
        bfn_hess(hyz,dyz) = bfn_hess(hyz,dyz)+gr+dgyyr+dgzzr+ddgyyzz*rt3
        bfn_hess(hxz,dyz) = bfn_hess(hxz,dyz)+      dgxyr  + ddgxyzz*rt3
c       write(6,*) 'YZ:'
c       write(6,*) 'HXX:',bfn_hess(1,dyz)
c       write(6,*) 'HYY:',bfn_hess(2,dyz)
c       write(6,*) 'HZZ:',bfn_hess(3,dyz)
c       write(6,*) 'HXY:',bfn_hess(4,dyz)
c       write(6,*) 'HYZ:',bfn_hess(5,dyz)
c       write(6,*) 'HXZ:',bfn_hess(6,dyz)
c       stop

        bpos=bpos+6
        blo =blo+1
      endif 
                  enddo
                enddo
            bfn=bfn+bpos
          enddo
        enddo
      endif
c     stop
C *
C *Gradient corrected functionals
C *
      if(gradient_sw) then
        call aclear_dp(bfng_val,3*totbfn(tag),0.0d0)
        bfn=1
        do lcent=1,num_cent
           centre = atom_tag(tag,lcent)
           nshells = num_shl(tag,centre)
           ra2    = ra2_val(lcent,1)
           xd     = ra2_comp(lcent,1)
           yd     = ra2_comp(lcent,2)
           zd     = ra2_comp(lcent,3)
           xx     = xd*xd
           xy     = xd*yd
           xz     = xd*zd
           yy     = yd*yd
           yz     = yd*zd
           zz     = zd*zd
           ploc   = 0
           do lshl=1,nshells
             nprm   = nprim(tag,centre,lshl)
             lh     = hybrid(tag,centre,lshl)
             ll     = angmom(tag,centre,lshl)
C
C loop over primitives in shell
             do lprm=1,nprm
               ploc   = ploc + 1
               blo    = bfn
               bpos   = 0
               alp    = alpha(tag,centre,ploc)
               expo   = exp(-alp*ra2)
               talp   = -2.0d0*alp
               dgu    = talp*expo
C
C loop over hybrid angular momentum numbers e.g. sp shells
               do lhyb=lh,ll
                 cc = cont_coeff(tag,centre,ploc,lhyb)
                 g  = expo*cc
                 dg = dgu*cc
C 
C Basis function values
C
C S functions
      if(lhyb.eq.1) then
        bfn_val(blo) = bfn_val(blo) + g
        bfng_val(1,blo) = bfng_val(1,blo) + dg*xd
        bfng_val(2,blo) = bfng_val(2,blo) + dg*yd
        bfng_val(3,blo) = bfng_val(3,blo) + dg*zd
        blo=blo+1
        bpos=bpos+1
      endif
C
C P functions
      if(lhyb.eq.2) then
        px=blo
        py=blo+1
        pz=blo+2
        bfn_val(px) = bfn_val(px)  + g*xd
        bfn_val(py) = bfn_val(py)  + g*yd
        bfn_val(pz) = bfn_val(pz)  + g*zd
        bfng_val(1,px) = bfng_val(1,px) + g + xx*dg
        bfng_val(2,px) = bfng_val(2,px) +     xy*dg
        bfng_val(3,px) = bfng_val(3,px) +     xz*dg
        bfng_val(1,py) = bfng_val(1,py) +     xy*dg
        bfng_val(2,py) = bfng_val(2,py) + g + yy*dg
        bfng_val(3,py) = bfng_val(3,py) +     yz*dg
        bfng_val(1,pz) = bfng_val(1,pz) +     xz*dg
        bfng_val(2,pz) = bfng_val(2,pz) +     yz*dg
        bfng_val(3,pz) = bfng_val(3,pz) + g + zz*dg
        bpos=bpos+3
        blo=blo+3
      endif
C
C D Functions
      if(lhyb.eq.3) then
        dxx=blo
        dyy=blo+1
        dzz=blo+2
        dxy=blo+3
        dxz=blo+4
        dyz=blo+5

        gx = g*xd
        gy = g*yd
        gz = g*zd
        gxr = gx*rt3
        gyr = gy*rt3
        gzr = gz*rt3
        dgxxx = dg*xx*xd
        dgxxy = dg*xx*yd
        dgxxz = dg*xx*zd
        dgxyy = dg*xy*yd
        dgyyy = dg*yy*yd
        dgyyz = dg*yy*zd
        dgxzz = dg*xz*zd
        dgyzz = dg*yz*zd
        dgzzz = dg*zz*zd
        dgxyz = dg*xy*zd
        bfn_val(dxx) = bfn_val(dxx) + g*xx
        bfn_val(dyy) = bfn_val(dyy) + g*yy
        bfn_val(dzz) = bfn_val(dzz) + g*zz
        bfn_val(dxy) = bfn_val(dxy) + g*xy*rt3
        bfn_val(dxz) = bfn_val(dxz) + g*xz*rt3
        bfn_val(dyz) = bfn_val(dyz) + g*yz*rt3
        bfng_val(1,dxx) = bfng_val(1,dxx) + 2.0d0*gx + dgxxx
        bfng_val(2,dxx) = bfng_val(2,dxx) +          dgxxy
        bfng_val(3,dxx) = bfng_val(3,dxx) +          dgxxz
        bfng_val(1,dyy) = bfng_val(1,dyy) +          dgxyy
        bfng_val(2,dyy) = bfng_val(2,dyy) + 2.0d0*gy + dgyyy         
        bfng_val(3,dyy) = bfng_val(3,dyy) +          dgyyz
        bfng_val(1,dzz) = bfng_val(1,dzz) +          dgxzz
        bfng_val(2,dzz) = bfng_val(2,dzz) +          dgyzz
        bfng_val(3,dzz) = bfng_val(3,dzz) + 2.0d0*gz + dgzzz
        bfng_val(1,dxy) = bfng_val(1,dxy) +    gyr + dgxxy*rt3
        bfng_val(2,dxy) = bfng_val(2,dxy) +    gxr + dgxyy*rt3
        bfng_val(3,dxy) = bfng_val(3,dxy) +          dgxyz*rt3
        bfng_val(1,dxz) = bfng_val(1,dxz) +    gzr + dgxxz*rt3
        bfng_val(2,dxz) = bfng_val(2,dxz) +          dgxyz*rt3
        bfng_val(3,dxz) = bfng_val(3,dxz) +    gxr + dgxzz*rt3
        bfng_val(1,dyz) = bfng_val(1,dyz) +          dgxyz*rt3
        bfng_val(2,dyz) = bfng_val(2,dyz) +    gzr + dgyyz*rt3
        bfng_val(3,dyz) = bfng_val(3,dyz) +    gyr + dgyzz*rt3
        bpos=bpos+6
        blo =blo+6
      endif
              enddo
            enddo
            bfn=bfn+bpos
          enddo
        enddo
      endif
c     stop
C *
C *Local functional only
C *
      if (local_sw) then
        bfn=1
        do lcent=1,num_cent
           centre = atom_tag(tag,lcent)
           nshells = num_shl(tag,centre)
           ra2    = ra2_val(lcent,1)
           xd     = ra2_comp(lcent,1)
           yd     = ra2_comp(lcent,2)
           zd     = ra2_comp(lcent,3)
           ploc   = 0
           do lshl=1,nshells
             nprm   = nprim(tag,centre,lshl)
             lh     = hybrid(tag,centre,lshl)
             ll     = angmom(tag,centre,lshl)
C
C loop over primitives in shell
             do lprm=1,nprm
               blo   = bfn
               bpos  = 0
               ploc  = ploc + 1
               alp   = alpha(tag,centre,ploc)
               expo  = exp(-alp*ra2)
C
C loop over hybrid angular momentum numbers e.g. sp shells 
               do lhyb=lh,ll
                 cc = cont_coeff(tag,centre,ploc,lhyb)
                 g  = expo*cc
C
C Basis function values
C
C S functions
      if(lhyb.eq.1) then
        bfn_val(blo) = bfn_val(blo) + g
        bpos=bpos+1
        blo =blo+1
      endif
C
C P functions
      if(lhyb.eq.2) then
        px=blo
        py=blo+1
        pz=blo+2
        bfn_val(px) = bfn_val(px)  + g*xd
        bfn_val(py) = bfn_val(py)  + g*yd
        bfn_val(pz) = bfn_val(pz)  + g*zd
        bpos=bpos+3
        blo =blo+3
      endif
C
C D Functions
      if(lhyb.eq.3) then
        dxx=blo
        dyy=blo+1
        dzz=blo+2
        dxy=blo+3
        dxz=blo+4
        dyz=blo+5
        xx     = xd*xd
        xy     = xd*yd
        xz     = xd*zd
        yy     = yd*yd
        yz     = yd*zd
        zz     = zd*zd
        bfn_val(dxx) = bfn_val(dxx) + g*xx
        bfn_val(dyy) = bfn_val(dyy) + g*yy
        bfn_val(dzz) = bfn_val(dzz) + g*zz
        bfn_val(dxy) = bfn_val(dxy) + g*xy*rt3
        bfn_val(dxz) = bfn_val(dxz) + g*xz*rt3
        bfn_val(dyz) = bfn_val(dyz) + g*yz*rt3
        bpos=bpos+6
        blo =blo+6
      endif
             enddo
           enddo
           bfn=bfn+bpos
          enddo
        enddo
      endif
      return
      end
      subroutine den_val_xfit(rks_sw,hessian_sw,adens,bdens,tag,
     &                   bfn_val,bfng_val,bfn_hess,
     &                   rho,grho)
C *****************************************************************************
C *Description:								      *
C *Calculate density and grad density at a point                              *
C *****************************************************************************
      implicit none
C *****************************************************************************
C *Declarations
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_basis_cont_inf)
INCLUDE(common/dft_basis)
      logical rks_sw,hessian_sw
      REAL adens(*),bdens(*)
      REAL bfn_val(*),bfng_val(3,*),bfn_hess(6,*)
      integer tag
C *Out variables
      REAL rho(2),grho(3,2)
C *Local variables
      integer ialpha,beta
      integer lbasi,lbasj,aibas,ajbas
      REAL T(2),P(2)
      integer maxa,mina,ijbas_pos
      REAL fac,eps_prim
C *End declarations
C **********************************************************************
      ialpha = 1
      beta  = 2
      rho(ialpha)    = 0.0d0
      grho(1,ialpha) = 0.0d0
      grho(2,ialpha) = 0.0d0
      grho(3,ialpha) = 0.0d0
      eps_prim=1.0d-15
      fac=2.0d0
C
C Calculate rho and grad rho
      if(rks_sw) then
C
C Closed Shell
        do lbasi=1,totbfn(tag)
          T(ialpha)  = 0.0d0
          do lbasj=1,totbfn(tag)
c
c get value of density matrix element for the ith and jth basis function
c
            maxa=max(lbasi,lbasj)
            mina=min(lbasi,lbasj)
            ijbas_pos=(((maxa*maxa)-maxa)/2)+mina
            P(ialpha)=fac*adens(ijbas_pos)
c
c
c         if(Palpha.gt.eps_prim) Talpha=Talpha+Palpha*bfn_val(lbasj)
            T(ialpha)    = T(ialpha)    +P(ialpha)*bfn_val(lbasj)
          enddo
          rho(ialpha)=rho(ialpha)+bfn_val(lbasi)*T(ialpha)
          grho(1,ialpha)=grho(1,ialpha)+bfng_val(1,lbasi)*T(ialpha)
          grho(2,ialpha)=grho(2,ialpha)+bfng_val(2,lbasi)*T(ialpha)
          grho(3,ialpha)=grho(3,ialpha)+bfng_val(3,lbasi)*T(ialpha)
        enddo
        rho(ialpha)=rho(ialpha)*0.5d0
      else
C
C  Open Shell
        write(6,*) 'Not ready for open shell'
        stop
      endif
      return
      end
      subroutine ecfunc_xfit(rho,grho,wt,xc_ept,xc_vpt,xc_dvpt)
C *****************************************************************************
C *Description:								      *
C *Evaluate exchange correlation functional at a point                        *
C *****************************************************************************
      implicit none
C *****************************************************************************
C *Declarations
C *
C *In variables
INCLUDE(common/dft_module_comm)
      integer ifunc,ishell
      REAL rho(2),grho(3,2),wt
C *Out variables
      REAL xc_ept
      REAL xc_vpt(2),xc_dvpt(3,2)
C *Local variables
      integer alpha,beta
      REAL xc_ecorr,xc_vcorr(2),xc_vdcorr(3,2)
      REAL gama,gamb
C *End declarations							      *
C *****************************************************************************
C *Initialise variables
C *
      alpha              = 1
      beta               = 2 
      xc_ept             = 0.0d0
      xc_vpt(alpha)      = 0.0d0
      xc_vpt(beta)       = 0.0d0
      xc_dvpt(1,alpha)   = 0.0d0
      xc_dvpt(2,alpha)   = 0.0d0
      xc_dvpt(3,alpha)   = 0.0d0
      xc_dvpt(1,beta)    = 0.0d0
      xc_dvpt(2,beta)    = 0.0d0
      xc_dvpt(3,beta)    = 0.0d0
      xc_ecorr           = 0.0d0
      xc_vcorr(alpha)    = 0.0d0
      xc_vcorr(beta)     = 0.0d0
      xc_vdcorr(1,alpha) = 0.0d0
      xc_vdcorr(2,alpha) = 0.0d0
      xc_vdcorr(3,alpha) = 0.0d0
      xc_vdcorr(1,beta)  = 0.0d0
      xc_vdcorr(2,beta)  = 0.0d0
      xc_vdcorr(3,beta)  = 0.0d0
      
C *
C *Choose functional
C *
      if(lda_sw) call ueg(rho,xc_ept,xc_vpt,lda_wght)
      if(vwn_sw) call xc_vwn(rks_sw,rho,xc_ecorr,xc_vcorr,vwn_wght)
      if(vwnrpa_sw) call xc_vwnrpa(rks_sw,rho,xc_ecorr,xc_vcorr,vwnr
     +pa_wght)
      if(gradcorr_sw) then

        gama  =  (grho(1,alpha)*grho(1,alpha)+
     &            grho(2,alpha)*grho(2,alpha)+
     &            grho(3,alpha)*grho(3,alpha))

        gamb  =  (grho(1,beta)*grho(1,beta)+
     &            grho(2,beta)*grho(2,beta)+
     &            grho(3,beta)*grho(3,beta))

        if(becke88_sw) call becke88(rks_sw,rho,grho,gama,gamb,
     &       xc_ept,xc_vpt,xc_dvpt,becke88_wght,
     &       becke88_lda_sw)

        if(lyp_sw) call xc_lyp(rks_sw,rho,grho,gama,gamb,
     &       xc_ecorr,xc_vcorr,xc_vdcorr,lyp_wght)

        xc_dvpt(1,alpha) = (xc_dvpt(1,alpha)+xc_vdcorr(1,alpha))*wt
        xc_dvpt(2,alpha) = (xc_dvpt(2,alpha)+xc_vdcorr(2,alpha))*wt
        xc_dvpt(3,alpha) = (xc_dvpt(3,alpha)+xc_vdcorr(3,alpha))*wt

      endif
      xc_ept         =  xc_ept        + xc_ecorr
      xc_vpt(alpha)  = (xc_vpt(alpha) + xc_vcorr(alpha))*wt
C *
C *End calculation of functional at point
C *********************************************************************
      return
      end
      subroutine auxval(tag,ra2_comp,ra2_val,abfn_val)
C **********************************************************************
C *Description:							       *
C *Calculates the value of auxiliary fitting functions at a grid point.*
C *Uses spherical gaussians or cartesian gaussians                     *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
INCLUDE(common/dft_basis)
INCLUDE(common/dft_basis_api)
INCLUDE(common/dft_mol_info)
cINCLUDE(common/dft_module_comm)
      integer tag
      REAL ra2_comp(3,*),ra2_val(2,*)
C *Out variables
      REAL abfn_val(*)
C *Local variables
      integer num_cent
      integer lcent,lshl,lprm,lhyb,lcomp
      REAL xa,ya,za,ra2,poly(max_ang,60)
      integer centre,nshells,ploc,nprm,lh,ll,ltarg
      integer bfn,blo,bpos,comp(max_ang),nocomp
      REAL alp,expo
c
      logical cartesian_sw,spherical_sw
C *End declarations                                                    *
C **********************************************************************
      cartesian_sw=.true.
      spherical_sw=.false.
      num_cent=natoms
      bfn=1
      do lcent=1,num_cent
        centre = atom_tag(tag,lcent)
        nshells = num_shl(tag,centre)
        xa  = ra2_comp(lcent,1)
        ya  = ra2_comp(lcent,2)
        za  = ra2_comp(lcent,3)
        ra2 = ra2_val(lcent,1)
        ploc = 0
        ltarg = BL_maxang_on_atom(tag,lcent)-1
        if(cartesian_sw) call cval(xa,ya,za,ltarg,comp,poly)
        if(spherical_sw) call sval(xa,ya,za,ra2,ltarg,poly)
        do lshl=1,nshells
          nprm   = nprim(tag,centre,lshl)
          lh     = hybrid(tag,centre,lshl)
          ll     = angmom(tag,centre,lshl)
C
C loop over primitives in shell
          do lprm=1,nprm
            blo   = bfn
            bpos  = 0
            ploc  = ploc + 1
            alp   = alpha(tag,centre,ploc)
            expo  = exp(-alp*ra2)
c           write(6,*) 'EXPO:',expo,poly(1,1),ltarg,comp(1)
C
C loop over hybrid angular momentum numbers e.g. sp shells
            do lhyb=lh,ll
              nocomp=comp(lhyb)
C
C Basis function values
              do lcomp=1,nocomp
                abfn_val(blo)=abfn_val(blo)+poly(lhyb,nocomp)*expo
              enddo
              blo=blo+nocomp
              bpos=bpos+nocomp
            enddo
          enddo
          bfn=bfn+bpos
        enddo
      enddo
      return
      end        
      subroutine sval(xa,ya,za,ra2,ltarg,poly)
C **********************************************************************
C *Description:							       *
C *Calculate value of spherical gaussian at a point                    *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations 
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
      REAL xa,ya,za,ra2
      integer ltarg
C *Out variables
      REAL poly(max_ang,60)
C *Local variables
      REAL a,b,mterm
C *End declarations
C **********************************************************************
      a=1.0d0
      b=1.0d0
      poly(1,1)=1.0d0
C      
C P Functions
      if (ltarg.eq.2) then
        poly(2,1)=za*a

        call caserr('UNDEF')
        mterm=0.0d0

        poly(2,2)=mterm*(xa*a-ya*b)
        poly(2,3)=mterm*(xa*a+ya*b) 
C
C D Functions
      else if(ltarg.eq.3) then
        poly(3,1)=(3.0d0*za*poly(2,1))/4.0d0
        poly(3,2)=(3.0d0*za*poly(2,2))/2.0d0
        poly(3,3)=(3.0d0*za*poly(2,3))/2.0d0
        poly(3,4)=(3.0d0*(xa*poly(2,2)-ya*poly(2,3)))
        poly(3,5)=(3.0d0*(xa*poly(2,2)+ya*poly(2,3)))
      endif
      return
      end
      subroutine cval(xa,ya,za,ltarg,comp,poly)
C **********************************************************************
C *Description:							       *
C *Value of cartesian gaussian function at a point (very basic)	       *
C **********************************************************************
      implicit none
C **********************************************************************
C *Declarations
C *Parameters
INCLUDE(common/dft_parameters)
C *In variables
      REAL xa,ya,za
      integer ltarg
C *Out variables
      integer comp(max_ang)
      REAL poly(max_ang,60)
C *Local variables
      integer lt1,lt2,lt3,i,j,k,nocomp
C *End declarations
C **********************************************************************
C
C S functions
      poly(1,1)=1.0d0
C
C hit target angular momentum
      do lt1=0,ltarg
        nocomp=0
        do lt2=lt1,0,-1
          do lt3=lt1-lt2,0,-1
            i = lt2
            j = lt3
            k = lt1 - (lt2+lt3)
            nocomp=nocomp+1
            poly(ltarg,nocomp)=(xa**i)*(ya**j)*(za*k) 
          enddo
        enddo
        comp(lt1+1)=nocomp
      enddo
      return
      end
