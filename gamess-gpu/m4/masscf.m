c*module masscf  *deck masscf
      subroutine masscf(q,total_energy)
c
c     masscf driver based on emp23
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
cfix
      logical orest
      dimension q(*),array(10)
c
INCLUDE(common/segm)
      common/maxlen/maxq
INCLUDE(common/timez)
INCLUDE(common/cigrad)
c
      logical lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis
      common/scfblk/engy,etot,ehf,sh1(2),sh2(2),gap1(2),gap2(2),
     1              d12,d13,d23,canna,cannb,cannc,fx,fy,fz,
     2              lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis,
     3              ncyc,ischm,lockm,maxit,nconv,npunch,lokcyc
c
INCLUDE(common/vectrn)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/atmol3)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
INCLUDE(common/mapper)
c
      common/junke/maxt,ires,ipass,nteff,
     1     npass1,npass2,lentrixx,nbuck,mloww,mhi,ntri,iacc,iontrn
c
INCLUDE(common/prnprn)
INCLUDE(common/restrj)
INCLUDE(common/cslosc)
INCLUDE(common/mp2grad_pointers)
INCLUDE(common/timeperiods)
INCLUDE(common/cntl2)
INCLUDE(common/global)
INCLUDE(common/nshel)
INCLUDE(common/sortp)
c
INCLUDE(common/mp2grd)
INCLUDE(common/cntl1)
INCLUDE(common/disp)
c
c     /symtry/ added for length of iso array nw196(5)
c
INCLUDE(common/symtry)
c
c     /scra7/ needed to read 1e- ints (h1e)
c
INCLUDE(common/scra7)
c     MASSCF common blocks 
      parameter (mxnoro=20, mxfrz=20)
      logical fcore,osrso
      common /masinp/ toleng,acurcy_mas,damp_mas,mxpn,mxit,maxmas,
     *       norot,nrotab(2,mxnoro),nfrz,mofrz(mxfrz),fcore,osrso
      common /output_f/ nprint_f, noput_f(5)
INCLUDE(common/fccwfn)
      integer ncore_f,nact_f,nels_f
      common /fccwfn2 / ncore_f,nact_f,nels_f
c
      common /symmol/ group,complex,igroup,naxis,ilabmo,abel
      data c1/8hc1      /
      parameter (mxatm=2000, mxsh=5000)
      common /symtry_f/ mapshl(mxsh,48),mapctr(mxatm,48),
     *                t(432),invt_f(48),nt_f
_IF(chemshell, charmm)
      external  mp2grad_pointers_init
      external  global_init
      external  mp2grd_init
_ENDIF
c
c     need /bufb/ for symmetry labels
c
      common/bufb/mmmm(65),isymao(maxorb),isymmo(maxorb)
c
      logical                                     goparr,dskwrk,maswrk
      common /par   / me,master,nproc,ibtyp,iptim,goparr,dskwrk,maswrk
c
      logical opg_root
      character *8 hfsc
      data m1,m10,m13,m16/1,10,13,16/
      data hfsc/'hfscf'/
c
c     ormas keywords
c
      data detwrd,ormwrd/8hdet     ,8hormas   /
c
c     masscf convergence stuff
c
      logical dmping,cvging,cvged
      parameter (cvgtol=5.0d-03, dmptol=0.2d+00, ten=1.0d+01,
     *           ten7=1.0d-07, pt2=0.2d+00, twopt2=2.2d+00,
     *           zero=0.0d+00, two=2.0d+00, half=0.5d+00)
c
c     flag for 1st full-NR iter
c
      logical first_fnr
      common /flag_fnr/ first_fnr
      character*10 charwall
c
      first_fnr = .true.
      opg_grad = .true.
c
c     evaluate integrals
c
      if (opass2) then
       if(nopk.eq.0.or.nopk.ne.nopkr.or.iofsym.eq.1.or.
     +    iofrst.ne.iofsym) then
        write (iwr,6020)
        opass2 = .false.
       endif
      endif
      nopk = 1
      iofsym = 0
      isecvv = isect(8)
      itypvv = 8
      nconv = max(nconv,7)
cfix
      orest = .false.
      call timit(3)
      t1 = tim
c
c     calculate hf energy
c
c     call integ(q)
c
c     call revise
c     call scfrun(q)
c
c     allow for incomplete scf i.e. maxcyc exceeded
c
      if (irest.ge.2) then
       orest = .true.
      else
       irest = 5
      endif
      call revise
      call timit(3)
      timscf = tim - t1
      mprest = max(1,mprest)
      call revise
cfix
      if (cpulft(0).lt.timscf.or.orest) then
         write (iwr,6010) mprest
         call parclenms('restart job')
      endif
c
 1000 continue
      if(opg_root()) then 
       write(iwr,6030)
       write(iwr,6040) cpulft(1) ,charwall()
      endif
c
c     schwarz inequality test
c
      mp2grad_schw = igmem_alloc( nshell*(nshell+1)/2 )
      if (oschw) then
       if (nopk.ne.1) then
         i10 = igmem_alloc(151875)
       else
         i10 = igmem_alloc(50625)
       end if
       call coulmb(q(mp2grad_schw),q(i10))
       call gmem_free(i10)
      else
         call dcopy( nshell*(nshell+1)/2 
     &        ,0.0d0, 0, q(mp2grad_schw), 1)
         dlnmxs = 0.0d0
      end if
c
      na = ncore_f + nact_f 
c
      call set41
c
c     convergence parameters
c
      iter   = 0
      emc    = zero
      emc0   = zero
      sqcdf  = zero
      de     = zero
      deavg  = zero
      epslon = ten7
      dmping = .false.
      cvging = .false.
      cvged  = .false.
      tollag = acurcy_mas
c
c     refinements for geometry optimization
c
c     if(runtyp.eq.optmze  .and.  nevals.gt.0) then
c        grms = ddot(3*nat,egrad,1,egrad,1)
c        grms = sqrt(grms/(3*nat))
c                              cfact =  1.0d+00
c        if(grms.gt.0.005d+00) cfact =  2.5d+00
c        if(grms.gt.0.020d+00) cfact = 10.0d+00
c        if(grms.gt.0.100d+00) cfact = 20.0d+00
c        tollag = cfact*tollag
c        toleng = cfact*toleng
c     end if
c
c        frozen orbital runs do not lead to a symmetric lagrangian
c        so the convergence test should only be on the energy.
c
      if(fcore  .or.  nfrz.ne.0  .or. norot.ne.0) then
         tolng2=toleng*ten*ten
         tollg2=ten*ten
      else
         tolng2=toleng*ten*ten
         tollg2=tollag*two
      end if
c
c     set up MO info
c     memory chunk needs to be num*num for this module
c
      natr = (nact_f*nact_f+nact_f)/2
      idm1 = igmem_alloc(natr)
      lvec = num*num
      ivec = igmem_alloc(lvec)
      liso = nw196(5) 
      iiso = igmem_alloc(liso)
      iscr=igmem_alloc(num)
      call getq(q(ivec),q(iscr),q(iscr),num,num,m1,m1,m1,mouta,scftyp)
      call tdown(q(ivec),ilifq,q(ivec),ilifq,num)
      call put_mo_coeffs2( q(ivec) ,num*num)
      call gmem_free(iscr)
      call masscf_mos(q(ivec),q(iiso))

c
c     get 1e- AO integrals here to avoid i/o in main loop
c
      lh1e = (num*num+num)/2
      ih1e = igmem_alloc(lh1e)
      call rdedx(q(ih1e),lh1e,ibl7f,num8)
c
c     create distributed data structures
c
      call tran_alloc(na, num-na, num )
c
c     interface between gamess codes
c
      call cp_uk_us()
c
c     initialize ormas code
c
c     make a separate copy of the symmetry labels for full-NR
c     because ORMAS will modify its labels
c
      molab_orm = igmem_alloc(num)
      molab_fnr = igmem_alloc(num)
c
c     get symmetry labels from /bufb/
c
      call dcopy(num,isymmo,1,q(molab_orm),1) 
      call dcopy(num,isymmo,1,q(molab_fnr),1) 
c
c     initialize ormas, switch off symmetry for srso
c
      if (osrso) then
        group_sv  = group
        igroup_sv = igroup
        naxis_sv  = naxis
        nt_sv     = nt_f
        group  = c1
        igroup = 1
        naxis  = 1
        nt_f   = 1
      end if
      call fcinput(nprint_f,detwrd,ormwrd,q,q(molab_orm))
      call defcci_init(nprint_f,q,q(molab_orm))
c
c     restore symmetry information, if necessary
c
      if (osrso) then
        group  = group_sv
        igroup = igroup_sv
        naxis  = naxis_sv
        nt_f   = nt _sv
      end if
c
c     begin masscf iterations
c
      do while (.not.cvged .and.iter.lt.maxmas)
        iter = iter + 1
        call masscf_zero_dd
c
c       transformation
c
    1   call masscf_tran(q,q(ivec),q(iiso))
c
c       CI calc followed full-NR orbital update
c
        call masfnr(ncore_f,nels_f,nact_f,emasscf,sqcdf,
     *       q,q(ivec),q(ih1e),q(molab_orm),q(molab_fnr),
     *       demax,irotmx,jrotmx,q(idm1))
c
c     convergence test
c
      emc0 = emc
      emc  = emasscf
      etot = emasscf
      de0  = de
      de   = emc-emc0
      if (iter.eq.1) deavg=zero
      if (iter.eq.2) deavg= abs(de)
      if (iter.ge.3) deavg=( abs(de)+ abs(de0)+pt2*deavg)/twopt2
      epslon=epslon/ten
      if (abs(de).le.acurcy_mas) epslon=ten7
      if (epslon.lt.ten7) epslon=ten7
      cvging=abs(de).lt.cvgtol .and. damp_mas.lt.dmptol
      if (dmping.and.     cvging                 ) damp_mas=zero
      if (dmping.and..not.cvging.and.damp_mas.eq.zero) damp_mas=dmptol
      if (iter.gt.2.and..not.cvging) call ntndmp(de,de0,deavg,damp_mas)
      if (.not.dmping.and.damp_mas.gt.zero) dmping=.true.
      cvged = cvging .and. ( 
     &( abs(de).lt.tolng2 .and. demax.lt.tollag ) .or.
     &( abs(de).lt.toleng .and. demax.lt.tollg2 ) .or.
     &( abs(de).lt.tolng2 .and. demax.lt.5*tollag 
     &                    .and. sqcdf.lt.1.0d-11 ) )
c
c     1st fullNR iter done
c
      first_fnr = .false.
c
      if (maswrk.and.iter.eq.1) write(iwr,9030)
      ihart = int(abs(de))
      if(de.le.zero) then
        dele=de+ihart
      else
        dele=de-ihart
      end if
      if (maswrk) write(iwr,9040) iter,emasscf,dele,demax,
     *                irotmx,jrotmx,sqcdf,damp_mas 
c
      end do ! while .not.converged
c
      if ((iter.eq.maxmas) .and. (.not.cvged)) then
        if (maswrk) write(iwr,*)'masscf failed to converge'
      else
        if (maswrk) write(iwr,*)'masscf converged'
      end if
c
c     free ormas memory, unless srso
c
      call defcci_end(iwr,nprint_f,q)
c
c     free labels,1e- ints,mo vecs,iso memory
c
      call gmem_free(molab_fnr)
      call gmem_free(molab_orm)
      call gmem_free(ih1e)
c
c     free distributed data structures
c
      call tran_free()
c
      call gmem_free(iiso)
c
c     transform 1-particle density 'dm1' to ao basis and output
c     ok, provided we dont need 'vec' any more.
c
c     iwrk = igmem_alloc(num*num)
c     iden = igmem_alloc(num*num)
c     call aoden1(q(ivec),q(idm1),q(iwrk),q(iden),ncore_f,nact_f,num)
c     call gmem_free(iden)
c     call gmem_free(iwrk)
c
      call gmem_free(ivec)
      call gmem_free(idm1)
      call gmem_free(mp2grad_schw)
c
      return
 9040 format(1x,i3,f19.9,f13.9,f10.6,2i5,1p,e10.3,0p,f9.4)
 9030 format(/1x,'iter',5x,'total energy',6x,'del(e)',
     *        2x,'lagrangian asymmetry',3x,'sqcdf',
     *        3x,'damp')
 6010 format (//'insufficient time , restart parameter =',i5)
 6020 format(/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/
     + 1x,'= integrals must NOT be in supermatrix form ='/
     + 1x,'=        requested bypass is ignored        ='/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/)
 6030 format(/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/
     + 1x,'=    Multiple Active Space SCF (MASSCF)     ='/
     + 1x,'=       written by Graham D Fletcher        ='/
     + 1x,'= based on ORMAS, originally developed for  ='/
     + 1x,'= GAMESS, Iowa State University, Ames, Iowa ='/
     + 1x,'=        written by Joseph Ivanic           ='/
c    + 1x,'= and MCSCF, originally developed for HONDO ='/
c    + 1x,'=        written by Michel Dupuis           ='/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/)
 6040 format(1x,'commence masscf energy evaluation at', 
     +       f10.2,' seconds',a10,' wall')
      end
c*module masscf  *deck masfnr
      subroutine masfnr(ncore_f,nels_f,nact_f,emasscf,sqcdf,
     *                  q,vec,h1e,molab_orm,molab_fnr,
     *                  demax,irotmx,jrotmx,dm1)
      implicit  REAL (a-h,o-z)
c
      parameter (mxatm=2000, mxrt=100, mxao=8192, mxsh=5000)
c
      common /infoa_f/ nat,ich,mul,num,nqmt,ne,na,nb,
     *                zan(mxatm),c(3,mxatm),ian(mxatm)
      common /enrgys/ enucr,eelct,etot,sz,szz,ecore,escf,eerd,e1,e2,
     *                ven,vee,epot,ekin,estate(mxrt),statn,edft(2)
      common /detwfn/ wstate(mxrt),spins(mxrt),crit,prttol,s,sz_f,
     *                grpdet,stsym,glist,
     *                nflgdm(mxrt),iwts(mxrt),ncorsv,ncor,nact,norb,
     *                na_f,nb_f,k,kst,iroot,ipures,maxw1,niter,maxp,nci,
     *                igpdet,kstsym
INCLUDE(common/fccwfn)
      common /ijpair/ ia(mxao)
      logical                                     goparr,dskwrk,maswrk
      common /par   / me,master,nproc,ibtyp,iptim,goparr,dskwrk,maswrk
c
      parameter (mxnoro=20, mxfrz=20)
      logical fcore,osrso
      common /masinp/ toleng,acurcy_mas,damp_mas,mxpn,mxit,maxmas,
     *       norot,nrotab(2,mxnoro),nfrz,mofrz(mxfrz),fcore,osrso
c
c     after aprdmp2, isymmo() contains orbital labels
c
INCLUDE(common/sizes)
INCLUDE(common/atmol3)
      common/bufb/mmmm(65),isymao(maxorb),isymmo(maxorb)
INCLUDE(common/scra7)
INCLUDE(common/iofile)
INCLUDE(common/mapper)
INCLUDE(common/dump3)
      dimension q(*),vec(*),h1e(*),molab_orm(*),molab_fnr(*),dm1(*)
c
c     flag for 1st masscf iter
c
      logical first_fnr
      common /flag_fnr/ first_fnr
c
      parameter (half=0.5d+00)
      parameter (zero=0.0d+00)
c
      logical  clabel,fors
      logical  some,out,dbug
c
c     compute the core fock operator and energy
c
c     distinct names
c
      nbf  = num
      nmos = nqmt
c
c     occupied orbitals must include all active orbitals
c     this may be greater than in the reference wfn
c
      nocc = ncore_f + nact_f
c
c     dependent parameters
c
      nbsq = nbf*nbf
      nbtr = (nbf*nbf+nbf)/2
      nmtr = (nmos*nmos+nmos)/2
      natr = (nact_f*nact_f+nact_f)/2
c
c     check limit on ia() index array
c
      if (natr.gt.mxao) 
     &call caserr('masfnr: nact too big for index array, ia')
c
c     data structure lengths
c
      lhamo = nmtr
      lfcor = nmtr
      lwork = nbsq
      lfcci = natr
c
      call valfm(loadfm)
      ihamo = loadfm + 1            !  1-el integrals over mos
      ifcor = ihamo  + lhamo        !  core Fock operator 
      iwork = ifcor  + lfcor        !  workspace, msg buff
      ifcci = iwork  + lwork        ! active Fcore block for CI
      last  = ifcci  + lfcci
      need1 = last   - loadfm
      call getfm(need1)
c 
      call tftri(q(ihamo), h1e , vec ,q(iwork)
     *,          nmos,nbf,nbf)
c
c     form 2-el core fock operator in parallel
c
      call fcoddi(nmos,nocc, ncore_f ,q(ifcor),q(iwork))
c
c     sum 1-el and 2-el terms of core fock matrix
c
      call daxpy(lhamo,1.0d+00,q(ihamo),1,q(ifcor),1)
c
c     compute frozen core energy, /enrgys/...ecore...
c
      ecore = zero
      ihii = ihamo - 1
      ifii = ifcor - 1
      do i = 1, ncore_f
        ihii = ihii + i
        ifii = ifii + i
        ecore = ecore + q(ihii) + q(ifii)
      end do
c
c     save active elements of core Fock operator to ihamo for CI
c
      ij = ifcci
      do i = ncore_f+1, ncore_f + nact_f
        do j = ncore_f+1, i
          ijn = ia(i) + j
          ijf = (ifcor-1) + ijn
          q(ij) = q(ijf)
          ij = ij + 1
        end do
      end do
c
      nat4 = (natr*natr+natr)/2
      ldm2 = nat4
c
      call valfm(loadfm)
      idm2  = loadfm + 1
      last  = idm2   + ldm2 
      need2 = last   - loadfm
      call getfm(need2)
c
c     ormas-ci calculation obtaining 1,2-particle densities
c
      nprint = 7
c       call moden12(dm1,q(idm2),nact_f)
c     else
        clabel = .true.
        call defcci(nprint,clabel,0,1,0,0,
     *     q,q(ifcci), molab_orm(ncore_f+1) ,dm1,q(idm2))
c     end if
c 
c     full-NR orbital update follows
c
      fors   = .false.
      if ( nspace.eq.1      .and. 
     *    mini(1).eq.nels_f .and. 
     *    maxi(1).eq.nels_f .and. 
     *    mnum(1).eq.nact_f) 
     &fors   = .true. 
c
c     log/debug settings
c
      prtl   = 1.0d-09
      some   = maswrk .and. nprint.ne.-5 .and. first_fnr
      out    = .false.
      dbug   = .false.
c
c     derived lengths
c
      mxtr = (mxpn*mxpn+mxpn)/2
      nvsq = nvir*nvir 
      mxsq = mxpn*mxpn 
c       
c     data structure lengths
c      
      lihes = nmos*nocc
      lirot = nmos*nocc
      llagn = nmos*nocc
      lfval = nmtr
      lbuff = nbsq             ! safety
      ldmtx = mxtr
      lsdmx = mxtr
      lsdvc = mxsq
      lsdei = mxpn
      lsdws = mxpn*8
      lsdin = mxpn
c
      call valfm(loadfm) 
      iirot = loadfm + 1       ! index of rotations to optimize
      iihes = iirot  + lirot   ! index of non-redundant rotations
      ilagn = iihes  + lihes   ! lagrangian 
      ifval = ilagn  + llagn   ! valence fock matrix 
      ibuff = ifval  + lfval   ! message, i/o buffer 
      idmtx = ibuff  + lbuff   ! davidson matrix
      isdmx = idmtx  + ldmtx   ! small diag matrix
      isdvc = isdmx  + lsdmx   ! small diag vectors
      isdei = isdvc  + lsdvc   ! small diag eigenvalues
      isdws = isdei  + lsdei   ! small diag workspace
      isdin = isdws  + lsdws   ! small diag index
      last  = isdin  + lsdin
      need3 = last   - loadfm
      call getfm(need3) 
c
c     get non-redundant index
c
      call ntnpar(nrot,q(iihes), molab_fnr ,
     *            nmos,nocc,ncore_f,
     *            fors,dbug)
c
c     compute 1-el (core-hamiltonian) energy
c
      call chnrgy(ncore_f,nact,q(ihamo),dm1,e1el)
c
c     form valence fock operator in parallel
c
      call fvaddi(nmos,ncore_f,nact,dm1,q(ifval),q(ibuff))
c
c     form lagrangian, total energy
c
      emasscf = 0.0d+00
      call lagddi(nmos,ncore_f,nocc
     *,           dm1,q(idm2),q(ifcor),q(ifval)
     *,           q(ibuff),q(ilagn),emasscf)

      emasscf = emasscf + e1el*half + enucr
c
c     get lagrangian asymmetry, use it to determine which
c     rotations need optimizing...create a new index for
c     these (irot), adjust number of rotations (nrot).
c
c     demax,irotmx,jrotmx are used in convergence criteria
c
      nskip = 0
      if (fcore) nskip = ncore_f
      call ntnrot(demax,irotmx,jrotmx,
     *            q(ilagn),q(iirot),q(iihes),
     *            nrot,nmos,nocc,nskip,acurcy_mas,some,out)
c
c     allocations dependent on nrot
c
      ltvec = mxpn*(nrot+1)
      lprod = mxpn*(nrot+1)
      ldiah = nrot+1 
      lcvec = nrot+1
c
      call valfm(loadfm) 
      idiah = loadfm + 1       ! diagonal of augmented hessian
      itvec = idiah  + ldiah   ! trial vectors
      iprod = itvec  + ltvec   ! trial vector products
      icvec = iprod  + lprod   ! correction vector
c     last  = icvec  + lcvec
      ieig  = icvec  + lcvec
      ivec2 = ieig + num
      last  = ivec2  + num*num
      need4 = last   - loadfm
      call getfm(need4) 
c
c     diagonal elements of the augmented hessian
c
      call diaddi(nmos,ncore_f,nocc,nrot
     *,           dm1,q(idm2),q(ifcor),q(ifval)
     *,           q(ilagn),q(iirot),q(ibuff),q(idiah))
c
c     find the lowest root of the augmented hessian using
c     davidson method. contributions to the hessian are multiplied
c     by elements of the trial vector and summed directly to the
c     product-vector. in the parallel call to ntndvd, the storage
c     address of the augmented hessian is set to 'dummy'.
c
      call ntndvd(dummy
     *,           q(idiah),q(itvec),q(iprod),q(icvec),q(idmtx)
     *,           q(isdmx),q(isdvc),q(isdei),q(isdws),q(isdin)
     *,           ia,nrot+1,mxpn,acurcy_mas,mxit,out,dbug,prtl
     *,           nmos,ncore_f,nocc,nrot
     *,           dm1,q(idm2),q(ifcor),q(ifval)
     *,           q(ilagn),q(iirot),q(ibuff))
c
c     'tvec' now contains the rotation parameters
c
c     lengsfield's empirical fudging
c     sqcdf is used in the convergence criteria
c     'lagn' is workspace
c
      itemp = iprod
      call ntnlef(q(itvec),q(itemp),q(ilagn),q(iirot)
     *,           nrot,nmos,nocc,out,sqcdf)
c
c     ntnlef puts rotation parameters in 'lagn'
c
      irotp = ilagn
c
c     update orbitals
c
      iumat = iwork
      itemp = ifval
      call ntntrf(nbf,nmos,nocc,ncore_f,fcore,damp_mas,
     *            q(irotp), vec ,q(iumat),q(itemp),q(ibuff))
c
c     save new orbitals
c
      call put_mo_coeffs( vec ,num*num)
      do i=1,num
       q(ieig+i-1)=0.0d0
      enddo
c     print *,'remco vectors'
c     call prsq(vec,num,num,num)
c
      isovl = igmem_alloc(num*num)
      call  anorm(q(isovl),q)
      call gmem_free(isovl)
      call tback(q(ivec2),ilifq,vec,ilifq,num)
      call gvbsav(q(ivec2),q(ieig),mouta,num,ibl3ea)
c
      call retfm(need4)
      call retfm(need3)
c
      call retfm(need2)
      call retfm(need1)
c
      return
      end
c
c*module masscf  *deck tran_alloc
      subroutine tran_alloc(no, nv, nb)
c
c     special version of alloc_ga2 for masscf 
c     omitting the zero_ga and hardwiring the 
c     4 principle integral classes
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
INCLUDE(common/global)
INCLUDE(common/iofile)
INCLUDE(common/parcntl)
INCLUDE(common/mp2grd)
INCLUDE(common/gmempara)
      logical pg_create_inf
      character *14 fnm
      character *9 snm
      data fnm/'masscf.m'/
      data snm/'tran_alloc'/
c
      nov = no*nv
      nbo = nb*no
      noo = no*(no+1)/2
      nooo = noo*no
      nvv = nv*nv
      ntri = nb*(nb+1)/2
      nsq = nb*nb
      mynode = ipg_nodeid()
      g_vvvo=-1
c
      call pg_synch(99)
c
capr - change here
c      if(opg_root())then
c        write(6,*)'need ',nsq*noo2
c        call ma_summarize_allocated_blocks
c      endif
c
c     [VO|VO]
c
      if (pg_create_inf(0,nsq,noo,'vovo',nsq,1,g_vovo,fnm,snm,
     +                  IGMEM_NORMAL)) then
         call pg_distribution(g_vovo, mynode, ilo, ihi, jlo, jhi)
         if(iparapr.eq.3)
     +      write(iwr,918) g_vovo, mynode, ilo, ihi, jlo, jhi
        il_vovo = ilo
        ih_vovo = ihi
        jl_vovo = jlo
        jh_vovo = jhi
      else
         call pg_error('**GA error** failed to create GA ',g_vovo)
      end if
c      if(opg_root())then
c        write(6,*)'need ',noo2*nov
c        call ma_summarize_allocated_blocks
c      endif
c
c     [VO|OO]
c
      if (pg_create_inf(0,nv,nooo,'vooo',nv,1,g_vooo,fnm,snm,
     +                  IGMEM_NORMAL)) then
         call pg_distribution(g_vooo, mynode, ilo, ihi, jlo, jhi)
         if(iparapr.eq.3)
     +   write(iwr,918)  g_vooo, mynode, ilo, ihi, jlo, jhi
         il_vooo = ilo
         ih_vooo = ihi
         jl_vooo = jlo
         jh_vooo = jhi
      else
         call pg_error('**GA error** failed to create GA ',g_vooo)
      end if
c      if(opg_root())then
c        write(6,*)'need ',noo2*ntri
c        call ma_summarize_allocated_blocks
c      endif
c
c     [VV|OO]
c
      if (pg_create_inf(0,ntri,noo,'vvoo',ntri,1,g_vvoo,fnm,snm,
     +                  IGMEM_NORMAL)) then
         call pg_distribution(g_vvoo, mynode, ilo, ihi, jlo, jhi)
         if(iparapr.eq.3)
     +   write(iwr,918)  g_vvoo, mynode, ilo, ihi, jlo, jhi
         il_vvoo = ilo
         ih_vvoo = ihi
         jl_vvoo = jlo
         jh_vvoo = jhi
      else
         call pg_error('**GA error** failed to create GA ',g_vvoo)
      end if
c      if(opg_root())then
c        write(6,*)'need',noo2*noo2
c        call ma_summarize_allocated_blocks
c      endif
c
c     [OO|OO]
c
      if (pg_create_inf(0,noo,noo,'oooo',noo,1,g_oooo,fnm,snm,
     +                  IGMEM_NORMAL)) then
         call pg_distribution(g_oooo, mynode, ilo, ihi, jlo, jhi)
         if(iparapr.eq.3)
     +   write(iwr,918)  g_oooo, mynode, ilo, ihi, jlo, jhi
         il_oooo = ilo
         ih_oooo = ihi
         jl_oooo = jlo
         jh_oooo = jhi
      else
         call pg_error('**GA error** failed to create GA ',g_oooo)
      end if
      return
918   format(1x,'GA: distribution of GA [',1i6,'] to node ',1i4/
     +       1x,'GA: ilo =',1i6,3x,'ihi =',1i6,3x,
     +              'jlo =',1i6,3x,'jhi =',1i6)
      end
c
c*module masscf  *deck tran_free
      subroutine tran_free()
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
INCLUDE(common/global)
      character *14 fnm
      character *9 snm
      data fnm/'masscf.m'/
      data snm/'tran_free'/
c
      call delete_ga_inf(g_oooo,'oooo',fnm,snm)
      call delete_ga_inf(g_vvoo,'vvoo',fnm,snm)
      call delete_ga_inf(g_vooo,'vooo',fnm,snm)
      call delete_ga_inf(g_vovo,'vovo',fnm,snm)
      return
      end
c
c*module masscf  *deck masscf_mos
      subroutine masscf_mos(vec,iso)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      REAL vec
      dimension vec(*), iso(*)
INCLUDE(common/sizes)
INCLUDE(common/fsymas)
INCLUDE(common/modj)
INCLUDE(common/cslosc)
INCLUDE(common/symtry)
INCLUDE(common/nshel)
INCLUDE(common/atmol3)
INCLUDE(common/prints)
INCLUDE(common/scra7)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/mapper)
INCLUDE(common/timez)
INCLUDE(common/infoa)
INCLUDE(common/scfopt)
INCLUDE(common/restar)
INCLUDE(common/segm)
      common/diisd/st(210),cdiis(20),rdiis(19),derror,sdiis(20),
     + iposit(20),nsti(2),ondiis,junkj
INCLUDE(common/runlab)
      common/restri/jjfile(63),lds(508),isect(508),ldsect(508)
INCLUDE(common/psscrf)
INCLUDE(common/timeperiods)
INCLUDE(common/global)
INCLUDE(common/vcore)
INCLUDE(common/ijlab)
INCLUDE(common/mp2grad_pointers)
INCLUDE(common/tran)
INCLUDE(common/machin)
INCLUDE(common/harmon)
INCLUDE(common/direc)
      common/bufb/mmmm(65),isymao(maxorb),isymmo(maxorb)
      common/junkc/zjob(29)
_IF(parallel)
      common/nodeio/ids48(maxlfn),idr48(maxlfn),oputpp(maxlfn)
     + , maxio(maxlfn),oswed3(maxlfn)
_ENDIF
INCLUDE(common/mp2grd)
INCLUDE(common/disp)
c
      data zrhf,zscf/'rhf','scf'/
      data dzero,two,pt5/0.0d0,2.0d0,0.5d0/
      data yblnk,yav/' ',' av'/
      data done,pt2,twopt2 /1.0d0,0.2d0,2.2d0/
      data dmptlc/1.0d-2/
      data igs/5/
      data m29,m51/29,51/
      out = nprint .eq. 5
_IF(parallel)
      oswed3(4) = .true.
      oswed3(8) = .true.
_ENDIF
      call start_time_period(TP_APRDMP2_I)
c
c     generate mo symmetries 
c     (/bufb/...isymmo is used in sym_mo_ints)
c     vec is workspace
c
      call secget(isect(490),m51,iblk51)
      nav = lenwrd()
      call readi(mmmm,mach(13)*nav,iblk51,idaf)
      call secget(mouta,3,iblk51)
      call rdchr(zjob,m29,iblk51,idaf)
      call symvec(vec,isymao,isymmo,num,num,iblk51)
c
c     restore vectors
c     - the memory chunk needs to be num*num for this module
c
      call get_mo_coeffs(vec,num*num)
      if (newbas0.ne.newbas1) then
c
c     clear non-existent vectors and make their eigenvalues biggg
c
         call vclr(vec(i10+newbas0*num),1,(newbas1-newbas0)*num)
      end if
c
c     flag shells to compute - should hardwire independent of input..
c
      call spchck
      call debut(zrhf)
c
c     restore iso array
c
      call rdedx(iso,nw196(5),ibl196(5),idaf)
c
      call end_time_period(TP_APRDMP2_I)
      return
      end
c
c*module masscf  *deck masscf_tran
      subroutine masscf_tran(q,vec,iso)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      REAL q,vec
      dimension q(*),vec(*),iso(*)
INCLUDE(common/sizes)
INCLUDE(common/fsymas)
INCLUDE(common/modj)
INCLUDE(common/cslosc)
INCLUDE(common/symtry)
INCLUDE(common/nshel)
INCLUDE(common/atmol3)
INCLUDE(common/prints)
INCLUDE(common/scra7)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/mapper)
INCLUDE(common/timez)
INCLUDE(common/infoa)
INCLUDE(common/scfopt)
INCLUDE(common/restar)
INCLUDE(common/segm)
      common/diisd/st(210),cdiis(20),rdiis(19),derror,sdiis(20),
     + iposit(20),nsti(2),ondiis,junkj
INCLUDE(common/runlab)
      common/restri/jjfile(63),lds(508),isect(508),ldsect(508)
INCLUDE(common/psscrf)
INCLUDE(common/timeperiods)
INCLUDE(common/global)
INCLUDE(common/vcore)
INCLUDE(common/ijlab)
INCLUDE(common/mp2grad_pointers)
INCLUDE(common/tran)
INCLUDE(common/machin)
INCLUDE(common/harmon)
INCLUDE(common/direc)
      common/bufb/mmmm(65),isymao(maxorb),isymmo(maxorb)
      common/junkc/zjob(29)
_IF(parallel)
      common/nodeio/ids48(maxlfn),idr48(maxlfn),oputpp(maxlfn)
     + , maxio(maxlfn),oswed3(maxlfn)
_ENDIF
INCLUDE(common/mp2grd)
INCLUDE(common/disp)
c
c     flag for 1st full-NR iteration
c
      character*10 charwall
      logical first_fnr
      common /flag_fnr/ first_fnr
c
      data zrhf,zscf/'rhf','scf'/
      data dzero,two,pt5/0.0d0,2.0d0,0.5d0/
      data yblnk,yav/' ',' av'/
      data done,pt2,twopt2 /1.0d0,0.2d0,2.2d0/
      data dmptlc/1.0d-2/
      data igs/5/
      data m29,m51/29,51/
c
      out = nprint .eq. 5
      if (.not.first_fnr) nprint = -5
_IF(parallel)
      oswed3(4) = .true.
      oswed3(8) = .true.
_ENDIF
      call start_time_period(TP_APRDMP2)
c
      nocc=na
      nvir=num-nocc
      nvec=num
      if(nprint.ne.-5) write(iwr,9349) cpulft(1) ,charwall()
c
      mxshl=4
      do i=1,nshell
         if(ktype(i).eq.3) then
          mxshl = max(mxshl,6)
         else if(ktype(i).eq.4) then
          mxshl = max(mxshl,10)
         else if(ktype(i).eq.5) then
          mxshl = max(mxshl,15)
         else
         endif
      enddo
      l50 = mxshl**4 
      i50 = igmem_alloc(l50)
      l60 = mxshl*mxshl*num*nocc 
      i60 = igmem_alloc(l60)
      l80 = max(num*num,num*mxshl*mxshl)
      i80 = igmem_alloc(l80)
      l90 = max(num*num,num*mxshl*mxshl)
      i90 = igmem_alloc(l90)
      mxshlt=mxshl*mxshl
c
      call aprm1234( q(mp2grad_schw) ,iso,
     &     Q(i50),nshell,
     &     vec ,Q(i60),Q(i80),
     &     Q(i90),
     &     na,nvir,num,nvec,mxshl)
c
c  debug check of global arrays
c      call chk_ga2(na,num-na,num)
c
      call gmem_free(i90)
      call gmem_free(i80)
      call gmem_free(i60)
      call gmem_free(i50)
      call end_time_period(TP_APRDMP2)
****
c     call chk_ga_tools
c     write (6,*) 'end of aprdmp2'
c     call wrtmat_ga('(VO|OO)  ',g_vooo)
****
      return
c
 9349 format(/1x,
     + 'commence GA-based integral transformation at ',
     +  f9.2,' seconds',a10,' wall')
      end
c
c*module masscf  *deck masscf_zero_dd
      subroutine masscf_zero_dd
c
c     separate place to zero GA's
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/global)
c
c     initialize global arrays to zero
c     each orbital update step
c
cgdf  use pg_zero??
c
      call pg_synch(99)
      call zero_ga(g_vovo,il_vovo,ih_vovo,jl_vovo,jh_vovo)
      call zero_ga(g_vooo,il_vooo,ih_vooo,jl_vooo,jh_vooo)
      call zero_ga(g_vvoo,il_vvoo,ih_vvoo,jl_vvoo,jh_vvoo)
      call zero_ga(g_oooo,il_oooo,ih_oooo,jl_oooo,jh_oooo)
      call pg_synch(99)
      return
      end
c
c*module masscf  *deck masscf_input
      subroutine masscf_input
      implicit REAL  (a-h,o-z)
      logical got_ncore
      logical got_nact
      logical got_nels
      logical got_nspace
      logical got_mnum
      logical got_mini
      logical got_maxi
      logical got_end
      logical got_nstate
      logical got_norot
      logical got_nfrz
c
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/machin)
INCLUDE(common/iofile)
INCLUDE(common/work)
c
c     full-NR parameters (convergence settings)
c
c     8. toleng = criterion on the total energy convergence
c     9. acurcy_mas = NR and rotation convergence
c    10. damp_mas = dampening factor for convergence (0 or 1/5)
c    11,12. norot,nrotab  = number,list of user-input rotations 
c                           to freeze, resp.
c    13,14. nfrz,mofrz = number,list of user-input mos to freeze
c    15. mxpn   = max size of iterative subspace for solving
c                 NR equations via Davidson method in NTNDVD
c    16. mxit   = max no. iterations for solving
c                 NR equations via Davidson method in NTNDVD
c    17. maxmas = max. no. masscf iterations
c    18. fcore  = flag to freeze all core orbitals
c
      parameter (mxnoro=20, mxfrz=20)
      logical fcore,osrso
      common /masinp/ toleng,acurcy_mas,damp_mas,mxpn,mxit,maxmas,
     *       norot,nrotab(2,mxnoro),nfrz,mofrz(mxfrz),fcore,osrso
      common /output_f/ nprint_f, noput_f(5)
c
c     ormas parameters set here
c     for defining the state,
c    19. wstate = state averaging weights
c    20. nstate = number of ci states requested
c    21. kstsym = state symmetry selection ('symstate')
c    22. iroot  = root of ci problem
c     convergence settings,
c    23. crit   = ci diagonalization criterion
c    24. kst    = number of vectors kept from 1st ci solution
c                 as guesses for the next masscf ci step ('keepvec')
c    25. maxp   = max. no. of davidson expansion vectors
c    26. maxw1  = size of initial ci guess matrix ('ciguess')
c    27. niter  = max. no. of ci iters ('iterci')
c
c     single-reference-second-order (srso) method,
c    28. osrso  = flag for srso calc
c
      parameter (mxrt=100)
      common /detwfn/ wstate(mxrt),spins(mxrt),crit,prttol,s_f,sz,
     *                grpdet,stsym,glist,
     *                nflgdm(mxrt),iwts(mxrt),ncorsv,ncor,nact_f,
     *                norb,na_f,nb_f,nstate,kst,iroot,ipures,
     *                maxw1,niter,maxp,nci,igpdet,kstsym
INCLUDE(common/fccwfn)
c
      integer ncore,nact,nels
      common /fccwfn2 / ncore,nact,nels
c
INCLUDE(common/direc)
c
      integer mxcore, mxorb, mxnels
c     data mxcore, mxorb, mxnels / 200, 512, 256 /
      data mxcore, mxorb, mxnels / 800, 2048, 1024 /
c
      character *4 test, ytext(29)
      integer loop, locatc

      data ytext /
     *  'ncor', 'nact', 'nels', 'nspa', 'norb', 'mine', 
     *  'maxe', 'tole', 'acur', 'damp', 'noro', 'rota', 
     *  'nfrz', 'mofr', 'mxpn', 'mxit', 'maxm', 'fcor', 
     *  'wsta', 'nsta', 'syms', 'root', 'crit', 'keep', 
     *  'maxp', 'cigu', 'iter', 'srso',
     *  ' ' /
c
c     masscf input defaults
c
      nspace = 0
      ncore  = 0
      nact   = 0
      nels   = 0
c
c     full-NR input defaults
c
      toleng      =  1.0d-10
      acurcy_mas  =  1.0d-05
      damp_mas    =  0.0d+00
      norot       =    0
      nfrz        =    0
      mxpn        =   10
      mxit        =   50
      maxmas      =   50
      fcore       = .false.
c
c     ormas input defaults
c
      call vclr(wstate,1,mxrt)
      wstate(1)   =  1.0d+00
      nstate      =    1
      kstsym      =    1
      iroot       =    1
      crit        =  1.0d-05
      kst         =    1
      maxp        =   10
      maxw1       =  300
      niter       =  100
c
      osrso = .false.
c
      got_ncore = .false.
      got_nact  = .false.
      got_nels  = .false.
      got_nspace= .false.
      got_mnum  = .false.
      got_mini  = .false.
      got_maxi  = .false.
      got_end   = .false.
      got_nstate= .false.
      got_norot = .false.
      got_nfrz  = .false.
c
    2 call input
    3 call inpa4(test)
      k = locatc(ytext,29,test)
      if (k.ne.0) go to 100
      if (test .eq. 'end') then
         got_end   = .true.
         go to 80
      else
         call caserr2(
     *        'unrecognised or out-of-order directive in MASSCF input')
      endif
c
100   go to (10, 20, 30, 40, 50, 60, 70,
     *      105,110,120,130,140,150,160,170,180,190,
     *      200,210,220,230,240,250,260,270,280,290,
     *      300,  2), k
c
c     = ncore =
10    call inpi(ncore)
      if (osrso) then
        write(iwr,9000)'ncore'
        ncore = ncore_srso
      else if (ncore.le.0.or.ncore.gt.mxcore) then
        call caserr('invalid value for ncore')
      else
        got_ncore = .true.
      end if
      go to 3
c     = nact =
20    call inpi(nact)
      if (osrso) then
        write(iwr,9000)'nact'
        nact = nact_srso
      else if (nact.lt.0 .or. nact.gt.mxorb) then
        call caserr('invalid value for nact')
      else
        got_nact  = .true.
      end if
      go to 3
c     = nels =
30    call inpi(nels)
      if (osrso) then
        write(iwr,9000)'nels'
        nels = nels_srso
      else if(nels.lt.0.or.nels.gt.mxnels) then
        call caserr('invalid value for nels')
      else
        got_nels  = .true.
      end if
      go to 3
c     = nspace =
40    call inpi(nspace)
      if (osrso) then
        write(iwr,9000)'nspace'
        nspace = nspace_srso
      else if(nspace.lt.0.or.nspace.gt.50) then
        call caserr('invalid value for nspace')
      else
        got_nspace = .true.
      end if
      go to 3
c     = norb =
50    if (osrso) write(iwr,9000)'norb'
      if (.not.got_nspace) then
        call caserr('attempt to define active spaces before nspace')
      else 
        do loop = 1, nspace
          call inpi(mnum(loop))
        enddo
        got_mnum = .true.
      end if
      go to 3
c     = mine =
60    if (osrso) write(iwr,9000)'mine'
      if (.not.got_nspace) then
        call caserr('attempt to define active spaces before nspace')
      else
        do loop = 1, nspace
          call inpi(mini(loop))
        enddo
        got_mini = .true.
      end if
      go to 3
c     = maxe =
70    if (osrso) write(iwr,9000)'maxe'
      if (.not.got_nspace) then
        call caserr('attempt to define active spaces before nspace')
      else
        do loop = 1, nspace
          call inpi(maxi(loop))
        enddo
        got_maxi = .true.
      end if
      go to 3
c
c     extra input options
c
c     = toleng      =
  105 call inpf(toleng)
      if(toleng.le.0.0d+00)
     & call caserr('invalid value for toleng')
      go to 3
c     = acurcy_mas  =
  110 call inpf(acurcy_mas)
      if(acurcy_mas.le.0.0d+00)
     & call caserr('invalid value for acurcy')
      go to 3
c     = damp_mas    =
  120 call inpf(damp_mas)
      if(damp_mas.le.0.0d+00)
     & call caserr('invalid value for damp')
      go to 3
c     = norot       =
  130 call inpi(norot)
      if(norot.le.0.or.norot.gt.mxnoro) 
     & call caserr('invalid value for norot')
      got_norot = .true.
      go to 3
c     = nrotab      =
  140 if (.not.got_norot)
     & call caserr('attempt to define frozen rotations before norot')
      do loop = 1, norot
       call inpi(nrotab(1,loop))
       call inpi(nrotab(2,loop))
      enddo
      go to 3
c     = nfrz        =
  150 call inpi(nfrz)
      if(nfrz.le.0.or.nfrz.gt.mxfrz) 
     & call caserr('invalid value for nfrz')
      got_nfrz = .true.
      go to 3
c     = mofrz       =
  160 if (.not.got_nfrz)
     & call caserr('attempt to define frozen orbitals before nfrz')
      do loop = 1, nfrz
       call inpi(mofrz(loop))
      enddo
      go to 3
c     = mxpn        =
  170 call inpi(mxpn)
      if(mxpn.le.0) call caserr('invalid value for mxpn')
      go to 3
c     = mxit        =
  180 call inpi(mxit)
      if(mxit.le.0) call caserr('invalid value for mxit')
      go to 3
c     = maxmas      =
  190 call inpi(maxmas)
      if(maxmas.le.0) call caserr('invalid value for maxmas')
      go to 3
c     = fcore       =
  200 fcore = .true.
      go to 3
c     = wstate      =
  210 if (.not.got_nstate)
     & call caserr('attempt to define wstate before nstate')
      do loop = 1, nstate
       call inpf(wstate(loop))
      enddo
      go to 3
c     = nstate      =
  220 call inpi(nstate)
      if(nstate.le.0.or.nstate.gt.mxrt)
     + call caserr('invalid value for nstate')
      got_nstate = .true.
      go to 3
c     = kstsym      =
  230 call inpi(kstsym)
      if(kstsym.le.0.or.kstsym.gt.20)
     + call caserr('invalid value for symstate')
      go to 3
c     = iroot       =
  240 call inpi(iroot)
      if(iroot.lt.0) call caserr('invalid value for root')
c
c     input 0,1... for ground,1st excited... more intuitive?
c
      iroot = iroot + 1
      go to 3
c     = crit        =
  250 call inpf(crit)
      if(crit.le.0.0d+00) call caserr('invalid value for crit')
      go to 3
c     = kst         =
  260 call inpi(kst)
      if(kst.le.0) call caserr('invalid value for keepvec')
      go to 3
c     = maxp        =
  270 call inpi(maxp)
      if(maxp.le.0) call caserr('invalid value for maxp')
      go to 3
c     = maxw1       =
  280 call inpi(maxw1)
      if(maxw1.le.0) call caserr('invalid value for ciguess')
      go to 3
c     = niter       =
  290 call inpi(niter)
      if(niter.le.0) call caserr('invalid value for iterci')
      go to 3
c     = srso        =
  300 osrso = .true.
c
c     set nspace,ncore,nels,nact accordingly
c
      nspace_srso = 1
      ncore_srso  = nb
      nels_srso   = na - nb
      nact_srso   = nels_srso
c
      if (got_nspace) write(iwr,9000)'nspace'
      if (got_ncore)  write(iwr,9000)'ncore'
      if (got_nels)   write(iwr,9000)'nels'
      if (got_nact)   write(iwr,9000)'nact'
      nspace = nspace_srso
      ncore  = ncore_srso
      nels   = nels_srso
      nact   = nact_srso
      got_nspace = .true.
      got_ncore  = .true.
      got_nels   = .true.
      got_nact   = .true.
      go to 3
c
80    continue
c
c     error,exit conditions
c     the bare minimum is to give ncore,nels,nact
c
      if (.not.(got_ncore.and.got_nact.and.got_nels)) then
        call caserr('end before ncore,nact,nels all given')
c
c     set nspace if not given (needed later)
c
      else if (.not.got_nspace) then
        nspace  = 1
        got_nspace = .true.
      end if
c
c     to get here we must have nspace,ncore,nact,nels
c     either we have a single space calc,
c
      if (nspace.eq.1) then
c
c       set mnum,mini,maxi for single active space, and exit
c
        mnum(1) = nact
        mini(1) = nels
        maxi(1) = nels 
        go to 90
      else
c
c     ...or, it is a multispace calc, 
c        so check we have mnum,mini,maxi before exit
c
        if (.not.(got_mnum.and.got_mini.and.got_maxi)) then
          call caserr('multispace calc needs norb,mine,maxe')
        else
          go to 90
        end if
      end if
c
      go to 2
c
   90 continue
c
c     note the first orbital in each space 
c
      msta(1) = ncore + 1
      do j = 2, nspace + 1
        msta(j) = msta(j-1) + mnum(j-1)
      end do
c
c     finally, ensure kst and maxp are big enough
c
      kst = max(nstate,kst)
      maxp = max(maxp,2*kst)
      return
 9000 format(/,1x,'srso calc ignores input of ',1a6,/)
      end
c*module masscf  *deck ntndmp
      subroutine ntndmp(de,dep,deavg,damp)
c
      implicit  REAL (a-h,o-z)
c
      parameter (zero=0.0d+00, two=2.0d+00, four=4.0d+00,
     *           pt25=2.5d-01, pt5=5.0d-01, pt2=0.2d-01,
     *           fac=1.6d+01)
c
      if( de.gt.zero) go to 400
      if(dep.gt.zero) go to 300
      if( de.gt. dep) go to 200
c
c     ----- de < 0. , dep < 0. , de < dep -----
c
      if( abs(de).lt.two*deavg) go to 110
      damp=fac* max(damp,deavg)
      return
  110 if( abs(de).gt.pt5*deavg) return
      damp=damp/fac
      return
  200 continue
c
c     ----- de < 0. , dep < 0. , de > dep -----
c
      if(de.gt.pt25*dep) go to 210
      damp=(de/dep)**2* max(damp,deavg)
      return
  210 damp=damp/fac
      return
  300 continue
c
c     ----- de < 0. , dep > 0. -----
c
      damp=four* max(damp,deavg)
      if(-de.gt.deavg) damp=damp*fac
      if(-de+dep.ge.deavg) return
      damp=damp/fac
      return
  400 continue
      if(dep.gt.zero) go to 500
c
c     ----- de > 0. , dep < 0. -----
c
      damp=four* max(damp,deavg)
      if(de.gt.pt5*deavg) damp=damp*fac
      if(de-dep.ge.pt2*deavg) return
      damp=damp/fac
      return
  500 continue
c
c     ----- de > 0. , dep > 0. -----
c
      damp=four* max(damp,deavg)
      if(de.lt.four*dep) go to 510
      damp=fac* max(damp,deavg)
      return
  510 if(de.gt.pt25*dep) go to 520
      damp=damp/fac
      return
  520 damp=(de/dep)**2* max(damp,deavg)
      return
      end
c*module masscf  *deck ntnpar
      subroutine ntnpar(nrot,ic,labmo,
     *                  norb,norbs,ncorbs,fors,dbug)
c
      implicit  REAL (a-h,o-z)
c
      logical fors,corcor,actact,actcor,vircor
      logical dbug
c
      dimension ic(norb,norbs),labmo(norbs)
c
      common /iofile_f/ ir,iw,ip,ijko,ijkt,idaf,nav,ioda(950)
c
      parameter (mxnoro=20, mxfrz=20)
      logical fcore,osrso
      common /masinp/ toleng,acurcy_mas,damp_mas,mxpn,mxit,maxmas,
     *       norot,nrotab(2,mxnoro),nfrz,mofrz(mxfrz),fcore,osrso
c
c     ----- initialize orbital rotation parameter array -----
c     zero elements of -ic- indicate redundant rotations, or
c     variational parameters which are not to be optimized.
c     -norot- allows for user input of ignorable rotations.
c
c     use of symmetry to eliminate rotations can be very effective.
c     for this we need the mo irrrep symmetry labels from -trfsym-
c
      nrot=0
      do 230 i=1,norb
         labi = labmo(i)
         do 202 ifrz=1,nfrz
            if(i.eq.mofrz(ifrz)) go to 230
  202    continue
         jmax=min(i,norbs)
         do 220 j=1,jmax
            ic(i,j)=0
            if(i.le.norbs) ic(j,i)=0
c
            if(j.eq.i)                          go to 220
c
            corcor=(i.le.ncorbs)                .and.
     *             (j.le.ncorbs)
            if(corcor)                          go to 220
c
            actact=(i.gt.ncorbs.and.i.le.norbs) .and.
     *             (j.gt.ncorbs.and.j.le.norbs)
            if(fors.and.actact)                 go to 220
c
c              orbitals of different symmetry should not mix
c
            if(labi.ne.labmo(j))                go to 220
c
            actcor=(i.gt.ncorbs.and.i.le.norbs) .and.
     *             (j.le.ncorbs)
            vircor=(i.gt.norbs)                 .and.
     *             (j.le.ncorbs)
            if(fcore.and.(actcor.or.vircor))    go to 220
c
c              next two loops check for rotations or mos frozen by user
c
            do 210 inorot=1,norot
               ii=nrotab(1,inorot)
               jj=nrotab(2,inorot)
               if(ii.eq.i.and.jj.eq.j) go to 220
  210       continue
c
            do 212 ifrz=1,nfrz
               if(j.eq.mofrz(ifrz)) go to 220
  212       continue
c
c             found an orbital rotation that must be optimized
c
            nrot=nrot+1
            ic(i,j)=nrot
            if(i.le.norbs) ic(j,i)=nrot
c
  220    continue
  230 continue
      nrot2=(nrot*(nrot+1))/2
c
      if(.not.dbug) return
      write(iw,9999)
      do 300 i=1,norb
         write(iw,9998) (ic(i,j),j=1,norbs)
  300 continue
      return
c
 9999 format(1x,'orbital pair rotation parameters = ')
 9998 format(10x,40i3)
      end
c*module masscf  *deck ntnrot
      subroutine ntnrot(demax,irotmx,jrotmx,e,irot,ic,nrot,norb,norbs,
     *                  nskip,acurcy,some,out)
c
      implicit  REAL (a-h,o-z)
c
      logical some,out
c
      dimension e(norbs,norb),irot(norbs,norb),ic(norb,norbs)
c
      common /iofile_f/ ir,iw,ip,ijko,ijkt,idaf,nav,ioda(950)
c
      parameter (zero=0.0d+00)
c
c     ----- get lagrangian asymmetry -----
c     demax is max asym, -ic- holds rotations being optimized.
c     the traditional default for -tol- was 1d-8, for many years.
c
      tol = max(1.0d-09,1.0d-03*acurcy)
      do 100 i=1,norb
      do 100 j=1,norbs
  100 irot(j,i)=0
      nrot=0
      demax=zero
      do 220 i=2+nskip,norb
         jmax=min(i-1,norbs)
         do 210 j=1+nskip,jmax
            dum=e(j,i)
            if(i.le.norbs) dum=dum-e(i,j)
            dum= abs(dum)
            if(dum.gt.demax) then
               irotmx=i
               jrotmx=j
               demax=dum
            end if
            irot(j,i)=0
            if(i.le.norbs) irot(i,j)=0
            if(dum.lt.tol) go to 210
            ij=ic(i,j)
            if(ij.eq.0) then
               if(some) write(iw,9996) dum,i,j
            else
               nrot=nrot+1
               irot(j,i)=nrot
               if(i.le.norbs) irot(i,j)=nrot
            end if
  210    continue
  220 continue
      if(some) write(iw,9997) nrot
c
      if(.not.out) return
      write(iw,9999)
      do 300 i=1,norb
         write(iw,9998) (irot(j,i),j=1,norbs)
  300 continue
      return
c
 9999 format(' orbital pair rotation parameters = ')
 9998 format(10x,40i3)
 9997 format(' number of independent orbital rotation parameters = ',i5)
 9996 format(1x,'grad=',1p,e14.6,0p,' for orb. rotation i,j=',
     *          2i5,' exceeds tolerance.')
      end
c
c*module masscf  *deck ntntrf
      subroutine ntntrf(num,norb,norbs,ncorbs,fcore,damp,s,v,u,t,wrk)
c
      implicit  REAL (a-h,o-z)
c
      logical first,fcore
c
      dimension s(norbs,norb),v(num,num),u(norb,norb),t(norb)
      dimension wrk(num,num)
c
      common /iofile_f/ ir,iw,ip,ijko,ijkt,idaf,nav,ioda(950)
c
      parameter (zero=0.0d+00, one=1.0d+00, two=2.0d+00,
     *           rotmax=0.2d+00)
c
c     ----- approximate orbital transformation -----
c
c          s      = rotation parameters
c          u      = exp(s) expanded to second order
c          u      = i + s * ( i + s/2 ) + ...
c
c     note - if any of the s(i,j) is greater than 0.2 in absolute
c     value, expand exp(s) to first order only.
c
      first=.false.
      do 120 i=2,norb
         jmax=min(i-1,norbs)
         do 110 j=1,jmax
            if( abs(s(j,i)).lt.rotmax) go to 110
            first=.true.
  110    continue
  120 continue
c
      call vclr(u,1,norb*norb)
      do 210 i=1,norb
         u(i,i)=one
  210 continue
      if(first) go to 300
c
      fac=one/two
      fac=fac/(one+damp)
      do 250 i=2,norb
         jmax=min(i-1,norbs)
         do 240 j=1,jmax
            dum=s(j,i)*fac
            u(i,j)= dum
            u(j,i)=-dum
  240    continue
  250 continue
c
  300 continue
c
c     original 'v' renamed 'wrk', next 20-odd lines
c
      do 320 i=1,norb
         do 310 j=1,norb
            wrk(i,j)=zero
  310    continue
  320 continue
c
      fac=one/(one+damp)
      do 360 i=2,norb
         jmax=min(i-1,norbs)
         do 350 j=1,jmax
            dum=s(j,i)*fac
            do 340 k=1,norb
               wrk(j,k)=wrk(j,k)-dum*u(i,k)
               wrk(i,k)=wrk(i,k)+dum*u(j,k)
  340       continue
  350    continue
  360 continue
c
      do 390 i=1,norb
         do 380 j=1,norb
            u(i,j)=wrk(i,j)
            wrk(i,j)=zero
  380    continue
         u(i,i)=u(i,i)+one
  390 continue
c
c     ----- option to freeze core orbitals -----
c     this is to make doubly certain u doesn't rotate core orbs,
c     these parts of the matrix are prbably zero/one already.
c
      if(fcore) then
         do 420 i=1,ncorbs
            do 410 j=1,norb
               u(i,j)=zero
               u(j,i)=zero
  410       continue
            u(i,i)=one
  420    continue
      end if
c
c     ----- orthonormalize the transformation matrix -----
c
      do 560 i=1,norb
         dum=zero
         do 510 k=1,norb
            dum=dum+u(k,i)*u(k,i)
  510    continue
         dum= one/ sqrt(dum)
         do 520 k=1,norb
            u(k,i)=u(k,i)*dum
  520    continue
         if(i.eq.norb) go to 560
         i1=i+1
         do 550 j=i1,norb
            dum=zero
            do 530 k=1,norb
               dum=dum+u(k,i)*u(k,j)
  530       continue
            do 540 k=1,norb
               u(k,j)=u(k,j)-dum*u(k,i)
  540       continue
  550    continue
  560 continue
c
c     ----- rotate the orbitals -v- by transformation -u- -----
c
      do 650 i=1,num
         do 630 j=1,norb
            dum=zero
            do 620 k=1,norb
               dum=dum+v(i,k)*u(k,j)
  620       continue
            t(j)=dum
  630    continue
         do 640 j=1,norb
            v(i,j)=t(j)
  640    continue
  650 continue
c
      return
      end
c*module masscf  *deck fvaddi
      subroutine fvaddi(nmos,ncor,nact,dval,fval,buff)
c
c ----------------------------------------------------------------------
c
c  newton-raphson mcscf. called from newton (mcscf.src).
c  construct the valence fock operator directly in the mo basis
c  from transformed integrals stored in the ddi arrays.
c
c  symbols:
c           nmos = total number of mos
c           ncor = number of core mos
c           nact = number of active mos
c           dval = 1-el density spanning active indices
c           fval = valence fock operator in the mo basis
c           buff = a message buffer
c
c  integrals need at least two active indices in the formula
c  fval(ij) = sum_over_kl{dval(kl)*[(ij|kl)-1/2(ik|jl)]}, k,l active,
c  i,j general. fval,dval stored in triangular form.
c
c ----------------------------------------------------------------------
c
      implicit  REAL  (a-h,o-z)
      parameter (mxao=8192, zero=0.0d+00, half=0.5d+00)
      logical inj
      REAL   fval(*),dval(*),buff(*)
      integer ddi_np, ddi_me, a,b,ab,ba,ai
      common /ijpair/ ia(mxao)
c
      integer         d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb
      logical         ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
      common /trfdms/ d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb,
     *                ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
c
      ncp1 = ncor + 1
      nocc = ncor + nact
      nvir = nmos - nocc
      nmtr = (nmos*nmos+nmos)/2
      notr = (nocc*nocc+nocc)/2
      nvtr = (nvir*nvir+nvir)/2
      nvsq = nvir*nvir
      call dcopy(nmtr,zero,0,fval,1)
      call ddi_nproc(ddi_np, ddi_me)
c
c  (oo|oo) class
c
      call ddi_distrib(d_oooo,ddi_me,ilo,ihi,jlo,jhi)
      do i = 1, nocc
        do j = 1, i
          ijcol = ia(i) + j
          if ((ijcol.ge.jlo).and.(ijcol.le.jhi)) then
            call ddi_get(d_oooo,1,notr,ijcol,ijcol,buff)
            ij = ijcol
c
c  coulomb terms
c
            do k = 1, nact
              kn = k + ncor
              do l = 1, nact
                ln = l + ncor
                kl   = ia(max(k,l))   + min(k,l)
                kln  = ia(max(kn,ln)) + min(kn,ln)
                fval(ij) = fval(ij)   + dval(kl)*buff(kln)
              end do
            end do
c
c  exchange terms
c
            if (i.gt.ncor) then
              in = i - ncor
              do k = ncp1, nocc
                kn = k - ncor
                ikn = ia(max(in,kn)) + min(in,kn)
                dik = half*dval(ikn)
                do l = 1, j
                  jl = ia(j) + l
                  kl = ia(max(k,l)) + min(k,l)
                  fval(jl) = fval(jl) - dik*buff(kl)
                end do
              end do
              if ((j.gt.ncor).and.(j.ne.i)) then
                jn = j - ncor
                do k = ncp1, nocc
                  kn = k - ncor
                  jkn = ia(max(jn,kn)) + min(jn,kn)
                  djk = half*dval(jkn)
                  do l = 1, i
                    il = ia(i) + l
                    kl = ia(max(k,l)) + min(k,l)
                    fval(il) = fval(il) - djk*buff(kl)
                  end do
                end do
              end if
            end if
          end if  ! local
        end do  ! j
      end do  ! i
c
c  (vo|oo) class
c
      call ddi_distrib(d_vooo,ddi_me,ilo,ihi,jlo,jhi)
c
c  coulomb terms (vo|aa)
c
      do i = ncp1, nocc
        in = i - ncor
        do j = ncp1, i
          jn = j - ncor
          ijn = ia(in) + jn
          dij = dval(ijn)
          if (i.ne.j) dij = dij + dij
          ijcol = ia(i) + j
          do k = 1, nocc
            ijkcol = (ijcol-1)*nocc + k
            if ((ijkcol.ge.jlo).and.(ijkcol.le.jhi)) then
              call ddi_get(d_vooo,1,nvir,ijkcol,ijkcol,buff)
              do a = 1, nvir
                na = a + nocc
                ka = ia(na) + k
                fval(ka) = fval(ka) + dij*buff(a)
              end do
            end if  ! local
          end do  ! k
        end do  ! j
      end do  ! i
c
c  exchange terms (va|ao)
c
      do i = 1, nocc
        do j = ncp1, nocc
          jn = j - ncor
          ijcol = ia(max(i,j)) + min(i,j)
          do k = ncp1, nocc
            kn = k - ncor
            ijkcol = (ijcol-1)*nocc + k
            if ((ijkcol.ge.jlo).and.(ijkcol.le.jhi)) then
              call ddi_get(d_vooo,1,nvir,ijkcol,ijkcol,buff)
              jkn = ia(max(jn,kn)) + min(jn,kn)
              djk = half*dval(jkn)
              do a = 1, nvir
                na = a + nocc
                ai = ia(na) + i
                fval(ai) = fval(ai) - djk*buff(a)
              end do
            end if  ! local
          end do  ! k
        end do  ! j
      end do  ! i
c
c  (vv|aa) class - coulomb terms
c
      call ddi_distrib(d_vvoo,ddi_me,ilo,ihi,jlo,jhi)
      do i = 1, nact
        in = i + ncor
        do j = 1, i
          ij = ia(i) + j
          jn = j + ncor
          ijcol = ia(in) + jn
          if ((ijcol.ge.jlo).and.(ijcol.le.jhi)) then
            call ddi_get(d_vvoo,1,nvtr,ijcol,ijcol,buff)
            dij = dval(ij)
            if (i.ne.j) dij = dij + dij
            do a = 1, nvir
              na = a + nocc
              do b = 1, a
                ab   = ia(a) + b
                nb   = b + nocc
                nab  = ia(na) + nb
                fval(nab) = fval(nab) + dij*buff(ab)
              end do
            end do
          end if  ! local
        end do  ! j
      end do  ! i
c
c  (va|va) class - exchange terms
c
      call ddi_distrib(d_vovo,ddi_me,ilo,ihi,jlo,jhi)
      do i = 1, nact
        in = i + ncor
        do j = 1, i
          ij = ia(i) + j
          jn = j + ncor
          ijcol = ia(in) + jn
          inj = i.ne.j
          if ((ijcol.ge.jlo).and.(ijcol.le.jhi)) then
            call ddi_get(d_vovo,1,nvsq,ijcol,ijcol,buff)
            dij = half*dval(ij)
            do a = 1, nvir
              na = a + nocc
              do b = 1, a
                ab   = (a-1)*nvir + b
                nb   = b + nocc
                nab  = ia(na) + nb
                fval(nab) = fval(nab) - dij*buff(ab)
              end do
            end do
            if (inj) then
              do a = 1, nvir
                na = a + nocc
                do b = 1, a
                  ba   = (b-1)*nvir + a
                  nb   = b + nocc
                  nab  = ia(na) + nb
                  fval(nab) = fval(nab) - dij*buff(ba)
                end do
              end do
            end if
          end if  ! local
        end do  ! j
      end do  ! i
c
c  globally sum the valence fock matrix
c
      call ddi_gsumf( 2520, fval, nmtr )
      return
      end
c*module masscf  *deck chnrgy
      subroutine chnrgy(ncor,nact,hamo,opdm,ecor)
c
c -----------------------------------------------------------------
c
c  compute the 1-el (or core-hamiltonian) energy
c
c  symbols:
c           ncor = number of core mos
c           nact = number of active mos
c           hamo = 1-el core hamiltonian integrals
c           opdm = 1-el density spanning active indices
c           ecor = 1-el 'core' energy
c
c -----------------------------------------------------------------
c
      implicit  REAL  (a-h,o-z)
      parameter (mxao=8192, zero=0.0d+00, two=2.0d+00)
       REAL  hamo(*),opdm(*)
      common /ijpair/ ia(mxao)
c
      ecor = zero
      ii = 0
      do i = 1, ncor
        ii = ii + i
        ecor = ecor + two*hamo(ii)
      end do
c
      do i = 1, nact
        in = i + ncor
        do j = 1, nact
          jn   = j + ncor
          ij   = ia(max(i,j))   + min(i,j)
          ijn  = ia(max(in,jn)) + min(in,jn)
          ecor = ecor + opdm(ij)*hamo(ijn)
        end do
      end do
      return
      end
c*module masscf  *deck lagddi
      subroutine lagddi(nmos,ncor,nocc
     *,                 opdm,tpdm,fcor,fval
     *,                 buff,lagn,energy)
c
c -----------------------------------------------------------------
c
c  newton-raphson mcscf. called from subroutine newton.
c  compute the lagrangian matrix and the mcscf energy.
c  see motecc-90 (escom), page 293, eqns (b.71-75).
c  to make use of parallel transformation (tranddi), core and
c  active mo indices are subsets of the occupied mo list.
c  tranddi is called from subroutine trfmcx.
c
c  symbols:
c     nmos = total number of mos
c     ncor = number of core mos
c     nocc = number of occupied mos
c     opdm = 1-el density spanning active indices
c     tpdm = 2-el density spanning active indices
c     fcor = core fock operator
c     fval = valence fock operator
c     buff = message buffer
c     lagn = lagrangian matrix  [output]
c     energy  = mcscf energy [output]
c
c -----------------------------------------------------------------
c
      implicit  REAL  (a-h,o-z)
      parameter (mxao=8192)
      parameter (zero=0.0d+00, half=0.5d+00, two=2.0d+00)
      logical inj
      integer ddi_np,ddi_me, a,an
       REAL   opdm(*),tpdm(*),fcor(*),fval(*)
       REAL   lagn(nocc,*),buff(*)
      common /ijpair/ ia(mxao)
c
      integer         d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb
      logical         ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
      common /trfdms/ d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb,
     *                ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
c
      ncp1 = ncor + 1
      nvir = nmos - nocc
      notr = (nocc*nocc+nocc)/2
      call ddi_nproc(ddi_np,ddi_me)
c
c  1-el terms of the lagrangian
c
      call dcopy(nmos*nocc,zero,0,lagn,1)
      do m = 1, nmos
        if (mod(m,ddi_np).eq.ddi_me) then
c
c  1. l(mi) = 2*(fc(mi) + fv(mi)),  i core, m general
c
          do i = 1, ncor
            im = ia(max(i,m)) + min(i,m)
            ff = fcor(im) + fval(im)
            lagn(i,m) = lagn(i,m) + two*ff
          end do
c
c  2. l(mi) = sum_j  d(ij)*fc(mj),  i,j valence, m general
c
          do i = ncp1, nocc
            id = i - ncor
            do j = ncp1, nocc
              jd = j - ncor
              ijd = ia(max(id,jd)) + min(id,jd)
              mj = ia(max(m,j)) + min(m,j)
              lagn(i,m) = lagn(i,m) + fcor(mj)*opdm(ijd)
            end do
          end do
c
        end if  !  parallel
      end do
c
c  2-el terms of the lagrangian
c
c ----------- contributions from (oo|oo) type integrals -----------
c
      call ddi_distrib(d_oooo,ddi_me,ilo,ihi,jlo,jhi)
c
c  (active-core|**) terms
c
      do i = ncp1, nocc
        do j = 1, ncor
          ij = ia(max(i,j)) + min(i,j)
          if ((ij.ge.jlo).and.(ij.le.jhi)) then
            call ddi_get(d_oooo,1,notr,ij,ij,buff)
c
c  1. l(jm) <- d(im|kl)*(ij|kl), j core
c
            id = i - ncor
            do k = ncp1, nocc
              kd = k - ncor
              do l = ncp1, nocc
                ld = l - ncor
                kl  = ia(max(k ,l )) + min(k ,l )
                kld = ia(max(kd,ld)) + min(kd,ld)
                eri = buff(kl)
                do m = ncp1, nocc
                  md = m - ncor
                  imd = ia(max(id,md)) + min(id,md)
                  imkld = ia(max(imd,kld)) + min(imd,kld)
                  lagn(m,j) = lagn(m,j) + tpdm(imkld)*eri
                end do
              end do
            end do
          end if  ! local
        end do  ! j
      end do  ! i
c
c  (active-active|**) terms
c
      do i = ncp1, nocc
        do j = ncp1, i
          ij = ia(max(i,j)) + min(i,j)
          if ((ij.ge.jlo).and.(ij.le.jhi)) then
            call ddi_get(d_oooo,1,notr,ij,ij,buff)
c
c  2. l(km) <- d(ij|lm)*(ij|kl)
c
            inj = i.ne.j
            id = i - ncor
            jd = j - ncor
            ijd = ia(max(id,jd)) + min(id,jd)
            do k = ncp1, nocc
              do l = ncp1, nocc
                ld = l - ncor
                kl = ia(max(k,l)) + min(k,l)
                eri = buff(kl)
                if (inj) eri = eri*two
                do m = ncp1, nocc
                  md = m - ncor
                  lmd = ia(max(ld,md)) + min(ld,md)
                  ijlmd = ia(max(ijd,lmd)) + min(ijd,lmd)
                  lagn(m,k) = lagn(m,k) + tpdm(ijlmd)*eri
                end do
              end do
            end do
          end if  ! local
        end do  ! j
      end do  ! i
c
c ----------- contributions from (vo|oo) type integrals -----------
c
      call ddi_distrib(d_vooo,ddi_me,ilo,ihi,jlo,jhi)
c
c  (active-active|active-virtual)
c
      do i = ncp1, nocc
        do j = ncp1, i
          ij = ia(max(i,j)) + min(i,j)
          do k = ncp1, nocc
            ijk = (ij-1)*nocc + k
            if ((ijk.ge.jlo).and.(ijk.le.jhi)) then
              call ddi_get(d_vooo,1,nvir,ijk,ijk,buff)
c
c  3. l(al) <- d(ij|kl)*(ak|ij)
c
              inj = i.ne.j
              id = i - ncor
              jd = j - ncor
              kd = k - ncor
              ijd = ia(max(id,jd)) + min(id,jd)
              do a = 1, nvir
                eri = buff(a)
                if (inj) eri = eri*two
                an = a + nocc
                do l = ncp1, nocc
                  ld = l - ncor
                  kld = ia(max(kd,ld)) + min(kd,ld)
                  ijkld = ia(max(ijd,kld)) + min(ijd,kld)
                  lagn(l,an) = lagn(l,an) + tpdm(ijkld)*eri
                end do
              end do
            end if  ! local
          end do  ! k
        end do  ! j
      end do  ! i
c
c  globally sum lagrangian
c
      call ddi_gsumf(2290,lagn,nmos*nocc)
c
c  compute mcscf energy
c
      energy = zero
      do i = 1, nocc
        energy = energy + lagn(i,i)
      end do
      energy = energy*half
      return
      end
c*module masscf  *deck diaddi
      subroutine diaddi(nmos,ncor,nocc,nrot
     *,                 opdm,tpdm,fcor,fval
     *,                 lagn,irot,buff,diah)
c
c -----------------------------------------------------------------
c
c  newton-raphson mcscf. called from subroutine newton.
c  compute the diagonal elements of the augmented hessian matrix
c  so that we can apply level shifting to them.
c  see motecc-90 (escom), page 293, eqns (b.71-75).
c  see yarkony, chem. phys. lett, volume 77, page 634.
c  to make use of parallel transformation (tranddi), core and
c  active mo indices are subsets of the occupied mo list.
c  tranddi is called from subroutine trfmcx.
c
c  symbols:
c     nmos = total number of mos
c     ncor = number of core mos
c     nocc = number of occupied mos
c     nrot = number of rotations to be optimized
c     opdm = 1-el density spanning active indices
c     tpdm = 2-el density spanning active indices
c     fcor = core fock operator
c     fval = valence fock operator
c     lagn = lagrangian matrix
c     irot = index of rotations to be optimized
c     buff = message buffer
c     diah = diagonal elements of the augmented hessian [output]
c
c -----------------------------------------------------------------
c
      implicit  REAL  (a-h,o-z)
      parameter (zero=0.0d+00, two=2.0d+00, four=4.0d+00, six=6.0d+00)
      parameter (hshift=0.5d+00)
      parameter (mxao=8192)
      logical inj
      integer irot(nocc,*), ddi_np,ddi_me, a,aa,ar
       REAL   opdm(*),tpdm(*),fcor(*),fval(*)
       REAL   lagn(nocc,*),buff(*),diah(*)
      common /ijpair/ ia(mxao)
c
      integer         d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb
      logical         ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
      common /trfdms/ d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb,
     *                ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
c
      ncp1 = ncor + 1
      nvir = nmos - nocc
      notr = (nocc*nocc+nocc)/2
      nvtr = (nvir*nvir+nvir)/2
      nvsq = nvir*nvir
      call ddi_nproc(ddi_np,ddi_me)
      call dcopy(nrot,zero,0,diah,1)
c
c  1-el terms of the augmented hessian
c
      do i = 1, nmos
        if (mod(i,ddi_np).eq.ddi_me) then
          ii = ia(i) + i
c
c  1. h(ij|ij) <- 2*( fcor(ii) + fval(ii) ), j core, i not core
c
          if (i.gt.ncor) then
            fac = two*( fcor(ii) + fval(ii) )
            do j = 1, ncor
              jir = irot(j,i)
              if (jir.ne.0) diah(jir) = diah(jir) + fac
            end do
          end if
c
c  2. h(ij|ij) <- d(jj)*fcor(ii), j valence, i general
c
          do j = ncp1, nocc
            jir = irot(j,i)
            if (jir.ne.0) then
              jd = j - ncor
              jjd = ia(jd) + jd
              djj = opdm(jjd)
              diah(jir) = diah(jir) + djj*fcor(ii)
            end if
          end do
          if (i.gt.ncor.and.i.le.nocc) then
            id = i - ncor
            do j = ncp1, nocc
              jir = irot(j,i)
              if (jir.ne.0) then
                jd = j - ncor
                ijd = ia(max(id,jd)) + min(id,jd)
                dij = opdm(ijd)
                ij = ia(max(i,j)) + min(i,j)
                diah(jir) = diah(jir) - dij*fcor(ij)
              end if
            end do
          end if
c
c  3. lagrangian term (undocumented?)
c
            do j = 1, nocc
              jir = irot(j,i)
              fac = lagn(j,j)
              if (i.ne.j) fac = -fac
              if (jir.ne.0) diah(jir) = diah(jir) + fac
            end do
        end if   !  parallel
      end do
c
c  2-el terms of the augmented hessian
c
c ------------ contributions from (oo|oo) integrals -----------
c
      call ddi_distrib(d_oooo,ddi_me,ilo,ihi,jlo,jhi)
c
c  (active-core|active-core) terms
c
      do i = ncp1, nocc
        do j = 1, ncor
          ij = ia(i) + j
          if ((ij.ge.jlo).and.(ij.le.jhi)) then
            call ddi_get(d_oooo,1,notr,ij,ij,buff)
c
c  1. h(ij|ij) <- 6(ij|ij), j core
c
            ijr = irot(i,j)
            if (ijr.ne.0)
     *      diah(ijr) = diah(ijr) + six*buff(ij)
c
c  2. h(ij|ij) <- -6*d(ik)*(ij|jk), j core
c
            ijr = irot(i,j)
            if (ijr.ne.0) then
              id = i - ncor
              do k = ncp1, nocc
                jk = ia(k) + j
                eri = buff(jk)
                kd = k - ncor
                ikd = ia(max(id,kd)) + min(id,kd)
                dik = opdm(ikd)
                fac = -dik*eri
                diah(ijr) = diah(ijr) + six*fac
              end do
            end if
c
c  3. h(jk|jk) <- 2*d(ik|kl)*(ij|jl), j core
c
            id = i - ncor
            do k = ncp1, nocc
              jkr = irot(k,j)
              if (jkr.ne.0) then
                kd = k - ncor
                ikd = ia(max(id,kd)) + min(id,kd)
                do l = ncp1, nocc
                  jl = ia(l) + j
                  eri = buff(jl)
                  ld = l - ncor
                  kld = ia(max(kd,ld)) + min(kd,ld)
                  ikkld = ia(max(ikd,kld)) + min(ikd,kld)
                  dikkl = tpdm(ikkld)
                  fac = dikkl*eri
                  diah(jkr) = diah(jkr) + two*fac
                end do
              end if
            end do
c
c  end of distribution loops
c
          end if   ! local
        end do  ! j
      end do  ! i
c
c  (active-active|**) terms
c
      do i = ncp1, nocc
        do j = ncp1, i
          ij = ia(i) + j
          if ((ij.ge.jlo).and.(ij.le.jhi)) then
            call ddi_get(d_oooo,1,notr,ij,ij,buff)
c
c  4. h(ik|ik) <- -2*(ii|kk), k core
c
            if (i.eq.j) then
              do k = 1, ncor
                ikr = irot(i,k)
                if (ikr.ne.0) then
                  kk = ia(k) + k
                  diah(ikr) = diah(ikr) - two*buff(kk)
                end if
              end do
            end if
c
c  5. h(ik|ik) <- 2*d(ij)*(ij|kk), k core
c
            inj = i.ne.j
            id = i - ncor
            jd = j - ncor
            ijd = ia(max(id,jd)) + min(id,jd)
            do k = 1, ncor
              kk = ia(k) + k
              eri = buff(kk)*two
              dij = opdm(ijd)
              fac = dij*eri
              ikr = irot(i,k)
              if (ikr.ne.0) diah(ikr) = diah(ikr) + fac
              if (inj) then
                jkr = irot(j,k)
                if (jkr.ne.0) diah(jkr) = diah(jkr) + fac
              end if
            end do
c
c  6. h(lk|lk) <- d(ll|ij)*(kk|ij), k core
c
            id = i - ncor
            jd = j - ncor
            ijd = ia(id) + jd
            inj = i.ne.j
            do k = 1, ncor
              kk = ia(k) + k
              eri = buff(kk)
              if (inj) eri = eri*two
              do l = ncp1, nocc
                klr = irot(l,k)
                if (klr.ne.0) then
                  ld = l - ncor
                  lld = ia(ld) + ld
                  ijlld = ia(max(ijd,lld)) + min(ijd,lld)
                  dijll = tpdm(ijlld)
                  diah(klr) = diah(klr) + dijll*eri
                end if
              end do
            end do
c
c  7. h(lk|lk) <- d(ll|ij)*(kk|ij)
c
            id = i - ncor
            jd = j - ncor
            ijd = ia(id) + jd
            inj = i.ne.j
            do k = ncp1, nocc
              kk = ia(k) + k
              eri = buff(kk)
              if (inj) eri = eri*two
              do l = ncp1, nocc
                klr = irot(k,l)
                if (klr.ne.0) then
                  ld = l - ncor
                  lld = ia(ld) + ld
                  ijlld = ia(max(ijd,lld)) + min(ijd,lld)
                  dijll = tpdm(ijlld)
                  fac = dijll*eri
                  diah(klr) = diah(klr) + fac
                end if
              end do
            end do
c
c  8. h(ik|ik) <- 2*d(jk|kl)*(ij|il)
c
            id = i - ncor
            jd = j - ncor
            inj = i.ne.j
            do k = ncp1, nocc
              ikr = irot(i,k)
              if (ikr.ne.0) then
                kd = k - ncor
                jkd = ia(max(jd,kd)) + min(jd,kd)
                do l = ncp1, nocc
                  il = ia(max(i,l)) + min(i,l)
                  eri = buff(il)
                  ld = l - ncor
                  kld = ia(max(kd,ld)) + min(kd,ld)
                  jkkld = ia(max(jkd,kld)) + min(jkd,kld)
                  djkkl = tpdm(jkkld)
                  fac = djkkl*eri
                  diah(ikr) = diah(ikr) + fac*two
                end do
              end if
            end do
            if (inj) then
              do k = ncp1, nocc
                jkr = irot(j,k)
                if (jkr.ne.0) then
                  kd = k - ncor
                  ikd = ia(max(id,kd)) + min(id,kd)
                  do l = ncp1, nocc
                    jl = ia(max(j,l)) + min(j,l)
                    eri = buff(jl)
                    ld = l - ncor
                    kld = ia(max(kd,ld)) + min(kd,ld)
                    ikkld = ia(max(ikd,kld)) + min(ikd,kld)
                    dikkl = tpdm(ikkld)
                    fac = dikkl*eri
                    diah(jkr) = diah(jkr) + fac*two
                  end do
                end if
              end do
            end if
c
c  9. h(ij|ij) <- -2*d(kl|ij)*(kl|ij)
c
            ijr = irot(i,j)
            if (ijr.ne.0) then
              id = i - ncor
              jd = j - ncor
              ijd = ia(id) + jd
              do k = ncp1, nocc
                kd = k - ncor
                do l = ncp1, k
                  kl = ia(max(k,l)) + min(k,l)
                  eri = buff(kl)
                  if (k.ne.l) eri = eri*two
                  ld = l - ncor
                  kld = ia(kd) + ld
                  ijkld = ia(max(ijd,kld)) + min(ijd,kld)
                  dijkl = tpdm(ijkld)
                  fac = -dijkl*eri
                  diah(ijr) = diah(ijr) + fac*two
                end do
              end do
            end if
c
c  10. h(ik|ik) <- -4*d(il|jk)*(kl|ij)
c
            id = i - ncor
            jd = j - ncor
            do k = ncp1, i-1
              ikr = irot(i,k)
              if (ikr.ne.0) then
                kd = k - ncor
                jkd = ia(max(jd,kd)) + min(jd,kd)
                do l = ncp1, nocc
                  kl = ia(max(k,l)) + min(k,l)
                  eri = buff(kl)
                  ld = l - ncor
                  ild = ia(max(id,ld)) + min(id,ld)
                  iljkd = ia(max(ild,jkd)) + min(ild,jkd)
                  diljk = tpdm(iljkd)
                  fac = -diljk*eri
                  diah(ikr) = diah(ikr) + fac*four
                end do
              end if
            end do
            if (i.ne.j) then
              do k = ncp1, j-1
                jkr = irot(j,k)
                if (jkr.ne.0) then
                  kd = k - ncor
                  ikd = ia(max(id,kd)) + min(id,kd)
                  do l = ncp1, nocc
                    kl = ia(max(k,l)) + min(k,l)
                    eri = buff(kl)
                    ld = l - ncor
                    jld = ia(max(jd,ld)) + min(jd,ld)
                    ikjld = ia(max(ikd,jld)) + min(ikd,jld)
                    dikjl = tpdm(ikjld)
                    fac = -dikjl*eri
                    diah(jkr) = diah(jkr) + fac*four
                  end do
                end if
              end do
            end if
c
c  end of distribution loops
c
          end if   ! local
        end do  ! j
      end do  ! i
c
c ------------ contributions from (vv|oo) integrals -----------
c
      call ddi_distrib(d_vvoo,ddi_me,ilo,ihi,jlo,jhi)
c
c  (virtual-virtual|core-core) term
c
      do i = 1, ncor
        ii = ia(i) + i
        if ((ii.ge.jlo).and.(ii.le.jhi)) then
          call ddi_get(d_vvoo,1,nvtr,ii,ii,buff)
c
c  11. h(ai|ai) <- -2*(aa|ii), i core
c
          do a = 1, nvir
            aa = ia(a) + a
            ar = a + nocc
            iar = irot(i,ar)
            if (iar.ne.0)
     *      diah(iar) = diah(iar) - two*buff(aa)
          end do
        end if   ! local
      end do   !  i
c
c  (virtual-virtual|active-active) term
c
      do i = ncp1, nocc
        do j = ncp1, i
          ij = ia(i) + j
          if ((ij.ge.jlo).and.(ij.le.jhi)) then
            call ddi_get(d_vvoo,1,nvtr,ij,ij,buff)
c
c  12. h(ak|ak) <- d(kk|ij)*(aa|ij)
c
            inj = i.ne.j
            id = i - ncor
            jd = j - ncor
            ijd = ia(id) + jd
            do a = 1, nvir
              aa = ia(a) + a
              ar = a + nocc
              eri = buff(aa)
              if (inj) eri = eri*two
              do k = ncp1, nocc
                kar = irot(k,ar)
                if (kar.ne.0) then
                  kd = k - ncor
                  kkd = ia(kd) + kd
                  ijkkd = ia(max(ijd,kkd)) + min(ijd,kkd)
                  dijkk = tpdm(ijkkd)
                  diah(kar) = diah(kar) + dijkk*eri
                end if
              end do
            end do
c
c  end of distribution loops
c
          end if   ! local
        end do   !  j
      end do   !  i
c
c ------------ contributions from (vo|vo) integrals -----------
c
      call ddi_distrib(d_vovo,ddi_me,ilo,ihi,jlo,jhi)
c
c  (virtual-core|virtual-core) term
c
      do i = 1, ncor
        ii = ia(i) + i
        if ((ii.ge.jlo).and.(ii.le.jhi)) then
          call ddi_get(d_vovo,1,nvsq,ii,ii,buff)
c
c  13. h(ai|ai) <- 6*(ai|ai), i core
c
          do a = 1, nvir
            aa = (a-1)*nvir + a
            ar = a + nocc
            iar = irot(i,ar)
            if (iar.ne.0)
     *      diah(iar) = diah(iar) + six*buff(aa)
          end do
        end if   ! local
      end do   !  i
c
c  (virtual-active|virtual-active) term
c
      do i = ncp1, nocc
        do j = ncp1, i
          ij = ia(i) + j
          if ((ij.ge.jlo).and.(ij.le.jhi)) then
            call ddi_get(d_vovo,1,nvsq,ij,ij,buff)
c
c  14. h(ak|ak) <- 2*d(ik|jk)*(ai|aj)
c
            inj = i.ne.j
            id = i - ncor
            jd = j - ncor
            do a = 1, nvir
              aa = (a-1)*nvir + a
              ar = a + nocc
              eri = buff(aa)*two
              if (inj) eri = eri*two
              do k = ncp1, nocc
                kar = irot(k,ar)
                if (kar.ne.0) then
                  kd = k - ncor
                  ikd = ia(max(id,kd)) + min(id,kd)
                  jkd = ia(max(jd,kd)) + min(jd,kd)
                  ikjkd = ia(max(ikd,jkd)) + min(ikd,jkd)
                  dikjk = tpdm(ikjkd)
                  diah(kar) = diah(kar) + dikjk*eri
                end if
              end do
            end do
c
c  end of distribution loops
c
          end if   ! local
        end do   !  j
      end do   !  i
c
c  globally sum diagonal elements
c
      call ddi_gsumf(2289,diah,nrot)
c
c  double elements of diagonal
c
      call dscal(nrot,two,diah,1)
c
c  b. lengsfield's level shifting
c
      do i = 1, nrot
        if (diah(i).le.zero) diah(i) = hshift
      end do
c
c  move elements forward one place
c
      do i = nrot, 1, -1
        diah(i+1) = diah(i)
      end do
c
c  first element is arbitrary but should be zeroed
c
      diah(1) = zero
      return
      end
c*module masscf  *deck ahpddi
      subroutine ahpddi(nmos,ncor,nocc,nrot
     *,                 opdm,tpdm,fcor,fval
     *,                 lagn,irot,diah,buff,tvec,prod)
c
c -----------------------------------------------------------------
c
c  newton-raphson mcscf. called from subroutine ntndvd.
c  compute the product of the augmented hessian with the trial vector.
c  see motecc-90 (escom), page 293, eqns (b.71-75).
c  see yarkony, chem. phys. lett, volume 77, page 634.
c  to make use of parallel transformation (tranddi), core and
c  active mo indices are subsets of the occupied mo list.
c  tranddi is called from subroutine trfmcx.
c
c  symbols:
c     nmos = total number of mos
c     ncor = number of core mos
c     nocc = number of occupied mos
c     nrot = number of rotations
c     opdm = 1-el density spanning active indices
c     tpdm = 2-el density spanning active indices
c     fcor = core fock operator
c     fval = valence fock operator
c     lagn = lagrangian matrix
c     irot = index of rotations
c     diah = diagonal elements of augmented hessian
c     tvec = trial vector of davidson solver
c     buff = message buffer
c     prod = product vector of davidson solver [output]
c
c -----------------------------------------------------------------
c
      implicit  REAL  (a-h,o-z)
      parameter (mxao=8192)
      parameter (half=0.5d+00, two=2.0d+00, four=4.0d+00, eight=8.0d+00)
      logical inj,ink,jnk,kel,lej,anb, bench
      integer irot(nocc,*), ddi_np,ddi_me, a,ar,b,br,ab,ba
       REAL   opdm(*),tpdm(*),fcor(*),fval(*)
       REAL   lagn(nocc,*),diah(*),buff(*),tvec(*),prod(*)
      common /ijpair/ ia(mxao)
c
      integer         d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb
      logical         ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
      common /trfdms/ d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb,
     *                ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
c
      ncp1 = ncor + 1
      nvir = nmos - nocc
      notr = (nocc*nocc+nocc)/2
      nvtr = (nvir*nvir+nvir)/2
      nvsq = nvir*nvir
      call ddi_nproc(ddi_np,ddi_me)
c
      bench = ddi_me.eq.0   !  switch for benchmark timing
      bench = .false.
      ichanl = 6            !  can be unique to a process
c
c  1-el contributions to product
c
      call dcopy(nrot+1,0.0d+00,0,prod,1)
      do m = 1, nmos
        if (mod(m,ddi_np).eq.ddi_me) then
c
c  1. hess(im|in) = 2*( fcor(mn) + fval(mn) ), i core, m,n not core
c
          if (m.gt.ncor) then
            do n = ncp1, m
              mn = ia(m) + n
              fac = two*( fcor(mn) + fval(mn) )
              do i = 1, ncor
                imr = irot(i,m)
                inr = irot(i,n)
                if (imr.ne.0.and.inr.ne.0) then
                  if (imr.ne.inr) then
                    ix = imr + 1
                    jx = inr + 1
                    prod(ix) = prod(ix) + fac*tvec(jx)
                    prod(jx) = prod(jx) + fac*tvec(ix)
                  end if
                end if
              end do
            end do
          end if
c
c  2. h(im|jn) = opdm(ij)*fcor(mn), i,j valence, m,n general
c
          do n = 1, m
            mn = ia(m) + n
            do i = ncp1, nocc
              imr = irot(i,m)
              if (imr.ne.0) then
                do j = ncp1, i
                  jnr = irot(j,n)
                  if (jnr.ne.0) then
                    if (imr.ne.jnr) then
                      id = i - ncor
                      jd = j - ncor
                      ijd = ia(id) + jd
                      dij = opdm(ijd)
                      fac = dij*fcor(mn)
                      if (m.eq.n) fac = fac*half
                      if (i.eq.j) fac = fac*half
                      if (m.lt.i) fac = -fac
                      if (n.lt.j) fac = -fac
                      ix = imr + 1
                      jx = jnr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end if
                end do
              end if
            end do
            do i = ncp1, nocc
              inr = irot(i,n)
              if (inr.ne.0) then
                do j = ncp1, i
                  jmr = irot(j,m)
                  if (jmr.ne.0) then
                    if (inr.ne.jmr) then
                      id = i - ncor
                      jd = j - ncor
                      ijd = ia(id) + jd
                      dij = opdm(ijd)
                      fac = dij*fcor(mn)
                      if (m.eq.n) fac = fac*half
                      if (i.eq.j) fac = fac*half
                      if (n.lt.i) fac = -fac
                      if (m.lt.j) fac = -fac
                      ix = inr + 1
                      jx = jmr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end if
                end do
              end if
            end do
          end do
c
c  lagrangian contributions
c
          do j = 1, nocc
c
c  3. row-column of augmented hessian
c
            jmr = irot(j,m)
            if (jmr.ne.0) then
              fac = lagn(j,m)
              if (j.gt.m) fac = -fac
              ix = 1
              jx = jmr + 1
              prod(ix) = prod(ix) + fac*tvec(jx)
              prod(jx) = prod(jx) + fac*tvec(ix)
            end if
c
c  4. (undocumented)
c
            do k = 1, nmos
              if (m.le.nocc.or.k.le.nocc) then
                if (m.le.nocc) mkr = irot(m,k)
                if (m.gt.nocc) mkr = irot(k,m)
                if (mkr.ne.0) then
                  jkr = irot(j,k)
                  if (jkr.ne.0) then
                    if (mkr.ne.jkr) then
                      fac = lagn(j,m)*0.5d+00
                      if (k.gt.m) fac = -fac
                      if (k.lt.j) fac = -fac
                      ix = mkr + 1
                      jx = jkr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end if
                end if
              end if
            end do
          end do
        end if   !  parallel
      end do   ! m
c
      if (bench) then
        write(ichanl,9000) 'one-elec'
        call timit(1)
      end if
c
c  2-el contributions to product
c
      call ddi_dlbreset()
      call ddi_dlbnext(mytask)
      loctsk = 0
c
c ----------- contributions from (oo|oo) type integrals -----------
c
      call ddi_distrib(d_oooo,ddi_me,ilo,ihi,jlo,jhi)
c
c  (active-core|**) types
c
      do i = ncp1, nocc
        do j = 1, ncor
          ij = ia(max(i,j)) + min(i,j)
          loctsk = loctsk + 1
          if (loctsk.eq.mytask) then
            call ddi_get(d_oooo,1,notr,ij,ij,buff)
c
c  1. h(ij|kl) <- 8*(ij|kl), j,l core
c
            ijr = irot(i,j)
            if (ijr.ne.0) then
              do k = ncp1, i
                mx = j
                if (i.ne.k) mx = ncor
                do l = 1, mx
                  klr = irot(k,l)
                  if (klr.ne.0) then
                    if (ijr.ne.klr) then
                      kl = ia(max(k,l)) + min(k,l)
                      eri = buff(kl)
                      fac = eight*eri
                      ix = ijr + 1
                      jx = klr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end if
                end do
              end do
            end if
c
c  2. h(il|jk) <- -2*(ij|kl), j,l core
c
            do k = i, nocc
              mx = j
              if (i.ne.k) mx = ncor
              jkr = irot(j,k)
              if (jkr.ne.0) then
                do l = 1, mx
                  ilr = irot(i,l)
                  if (ilr.ne.0) then
                    if (jkr.ne.ilr) then
                      kl = ia(max(k,l)) + min(k,l)
                      eri = buff(kl)
                      fac = -two*eri
                      ix = jkr + 1
                      jx = ilr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end if
                end do
              end if
            end do
c
c  3. h(jk|lm) <- -4*d(ik)*(ij|lm), j,m core
c
            id = i - ncor
            do k = ncp1, nocc
              kd = k - ncor
              ikd = ia(max(id,kd)) + min(id,kd)
              jkr = irot(k,j)
              if (jkr.ne.0) then
                dik = four*opdm(ikd)
                do l = ncp1, k
                  mx = j
                  if (k.ne.l) mx = ncor
                  do m = 1, mx
                    lmr = irot(l,m)
                    if (lmr.ne.0) then
                      if (jkr.ne.lmr) then
                        lm  = ia(max(l,m)) + min(l,m)
                        eri = buff(lm)
                        fac = -dik*eri
                        ix = jkr + 1
                        jx = lmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end do
              end if
            end do
c
c  4. h(il|jk) <- d(km)*(ij|lm), j,l core
c
            do k = ncp1, nocc
              if (i.le.k) then
                kd = k - ncor
                jkr = irot(k,j)
                if (jkr.ne.0) then
                  mx = j
                  if (i.ne.k) mx = ncor
                  do l = 1, mx
                    ilr = irot(i,l)
                    if (ilr.ne.0) then
                      if (jkr.ne.ilr) then
                        do m = ncp1, nocc
                          lm = ia(max(l,m)) + min(l,m)
                          eri = buff(lm)
                          md = m - ncor
                          kmd = ia(max(kd,md)) + min(kd,md)
                          dkm = opdm(kmd)
                          fac = dkm*eri
                          ix = jkr + 1
                          jx = ilr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end do
                      end if
                    end if
                  end do
                end if
              end if
            end do
c
c  5. h(ij|kl) <- -4*d(km)*(ij|lm), j,l core
c
            ijr = irot(i,j)
            if (ijr.ne.0) then
              do k = ncp1, i
                kd = k - ncor
                mx = j
                if (i.ne.k) mx = ncor
                do m = ncp1, nocc
                  md = m - ncor
                  kmd = ia(max(kd,md)) + min(kd,md)
                  dkm = opdm(kmd)*four
                  do l = 1, mx
                    klr = irot(k,l)
                    if (klr.ne.0) then
                      if (ijr.ne.klr) then
                        lm  = ia(max(l,m)) + min(l,m)
                        eri = buff(lm)
                        fac = -dkm*eri
                        ix = ijr + 1
                        jx = klr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end do
              end do
            end if
c
c  6. h(jk|lm) <- d(il)*(ij|km), j,m core
c
            id = i - ncor
            do k = ncp1, nocc
              jkr = irot(k,j)
              if (jkr.ne.0) then
                do l = ncp1, k
                  ld = l - ncor
                  ild = ia(max(id,ld)) + min(id,ld)
                  dil = opdm(ild)
                  mx = j
                  if (k.ne.l) mx = ncor
                  do m = 1, mx
                    lmr = irot(l,m)
                    if (lmr.ne.0) then
                      if (jkr.ne.lmr) then
                        km = ia(max(k,m)) + min(k,m)
                        eri = buff(km)
                        fac = dil*eri
                        ix = jkr + 1
                        jx = lmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end do
              end if
            end do
c
c  7. h(jk|ln) <- 2*d(ik|lm)*(ij|mn), j,n core
c
            id = i - ncor
            do k = ncp1, nocc
              kd = k - ncor
              ikd = ia(max(id,kd)) + min(id,kd)
              jkr = irot(k,j)
              if (jkr.ne.0) then
                do l = ncp1, k
                  ld = l - ncor
                  mx = j
                  if (k.ne.l) mx = ncor
                  do m = ncp1, nocc
                    md = m - ncor
                    lmd = ia(max(ld,md)) + min(ld,md)
                    iklmd = ia(max(ikd,lmd)) + min(ikd,lmd)
                    diklm = tpdm(iklmd)*two
                    do n = 1, mx
                      lnr = irot(l,n)
                      if (lnr.ne.0) then
                        if (jkr.ne.lnr) then
                          mn = ia(max(m,n)) + min(m,n)
                          eri = buff(mn)
                          fac = diklm*eri
                          ix = jkr + 1
                          jx = lnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end do
              end if
            end do
c
c  8. h(ij|kl) <- 4*d(lm)*(ij|km), j core
c
            id = i - ncor
            ijr = irot(i,j)
            if (ijr.ne.0) then
              do k = ncp1, nocc
                do l = ncp1, k-1
                  klr = irot(k,l)
                  if (klr.ne.0) then
                    if (ijr.ne.klr) then
                      ld = l - ncor
                      do m = ncp1, nocc
                        km = ia(max(k,m)) + min(k,m)
                        eri = buff(km)
                        md = m - ncor
                        lmd = ia(max(ld,md)) + min(ld,md)
                        dlm = opdm(lmd)*four
                        fac = dlm*eri
                        ix = ijr + 1
                        jx = klr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end do
                    end if
                  end if
                end do
              end do
            end if
c
c  9. h(jm|kl) <- -d(il)*(ij|km), j core
c
            id = i - ncor
            do k = ncp1, nocc
              do l = ncp1, k-1
                klr = irot(k,l)
                if (klr.ne.0) then
                  ld = l - ncor
                  ild = ia(max(id,ld)) + min(id,ld)
                  dil = opdm(ild)
                  do m = ncp1, nocc
                    jmr = irot(j,m)
                    if (jmr.ne.0) then
                      if (klr.ne.jmr) then
                        km = ia(max(k,m)) + min(k,m)
                        eri = buff(km)
                        fac = -dil*eri
                        ix = klr + 1
                        jx = jmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end if
              end do
            end do
c
c  10. h(il|jk) <- -d(lm)*(ij|km), j core
c
            do k = ncp1, nocc
              jkr = irot(k,j)
              if (jkr.ne.0) then
                do l = ncp1, i-1
                  ld = l - ncor
                  ilr = irot(i,l)
                  if (ilr.ne.0) then
                    if (jkr.ne.ilr) then
                      do m = ncp1, nocc
                        km  = ia(max(k,m)) + min(k,m)
                        eri = buff(km)
                        md = m - ncor
                        lmd = ia(max(ld,md)) + min(ld,md)
                        dlm = opdm(lmd)
                        fac = -dlm*eri
                        ix = jkr + 1
                        jx = ilr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end do
                    end if
                  end if
                end do
              end if
            end do
c
c  11. h(kl|ij) <- -4*d(km)*(ij|lm),  j core
c
            id = i - ncor
            ijr = irot(i,j)
            if (ijr.ne.0) then
              do k = ncp1, nocc
                kd = k - ncor
                do l = ncp1, k-1
                  klr = irot(k,l)
                  if (klr.ne.0) then
                    if (ijr.ne.klr) then
                      do m = ncp1, nocc
                        lm = ia(max(l,m)) + min(l,m)
                        eri = buff(lm)
                        md = m - ncor
                        kmd = ia(max(kd,md)) + min(kd,md)
                        dkm = opdm(kmd)*four
                        fac = -dkm*eri
                        ix = ijr + 1
                        jx = klr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end do
                    end if
                  end if
                end do
              end do
            end if
c
c  12. h(jm|kl) <- d(ik)*(ij|lm), j core
c
            id = i - ncor
            do k = ncp1, nocc
              kd = k - ncor
              ikd = ia(max(id,kd)) + min(id,kd)
              dik = opdm(ikd)
              do l = ncp1, k-1
                klr = irot(k,l)
                if (klr.ne.0) then
                  do m = ncp1, nocc
                    jmr = irot(m,j)
                    if (jmr.ne.0) then
                      if (klr.ne.jmr) then
                        lm = ia(max(l,m)) + min(l,m)
                        eri = buff(lm)
                        fac = dik*eri
                        ix = klr + 1
                        jx = jmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end if
              end do
            end do
c
c  13. h(im|jn) <- -d(kl|mn)*(ij|kl), j core
c
            do k = ncp1, nocc
              kd = k - ncor
              do l = ncp1, nocc
                ld = l - ncor
                kld = ia(max(kd,ld)) + min(kd,ld)
                kl = ia(max(k,l)) + min(k,l)
                eri = buff(kl)
                do m = ncp1, i-1
                  md = m - ncor
                  imr = irot(i,m)
                  if (imr.ne.0) then
                    do n = ncp1, nocc
                      jnr = irot(n,j)
                      if (jnr.ne.0) then
                        if (imr.ne.jnr) then
                          nd = n - ncor
                          mnd = ia(max(md,nd)) + min(md,nd)
                          klmnd = ia(max(kld,mnd)) + min(kld,mnd)
                          dklmn = tpdm(klmnd)
                          fac = -dklmn*eri
                          ix = imr + 1
                          jx = jnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end if
                end do
              end do
            end do
c
c  14. h(kl|jn) <- -2*d(in|lm)*(ij|km), j core
c
            id = i - ncor
            do k = ncp1, nocc
              do l = ncp1, k-1
                ld = l - ncor
                klr = irot(k,l)
                if (klr.ne.0) then
                  do m = ncp1, nocc
                    md = m - ncor
                    lmd = ia(max(ld,md)) + min(ld,md)
                    km = ia(max(k,m)) + min(k,m)
                    eri = buff(km)*two
                    do n = ncp1, nocc
                      jnr = irot(n,j)
                      if (jnr.ne.0) then
                        if (klr.ne.jnr) then
                          nd = n - ncor
                          ind = ia(max(id,nd)) + min(id,nd)
                          inlmd = ia(max(ind,lmd)) + min(ind,lmd)
                          dinlm = tpdm(inlmd)
                          fac = -dinlm*eri
                          ix = klr + 1
                          jx = jnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end if
              end do
            end do
c
c  15. h(kl|jn) <- 2*d(km|in)*(ij|lm), j core
c
            id = i - ncor
            do k = ncp1, nocc
              kd = k - ncor
              do l = ncp1, k-1
                klr = irot(k,l)
                if (klr.ne.0) then
                  do m = ncp1, nocc
                    md = m - ncor
                    kmd = ia(max(kd,md)) + min(kd,md)
                    lm = ia(max(l,m)) + min(l,m)
                    eri = buff(lm)*two
                    do n = ncp1, nocc
                      jnr = irot(n,j)
                      if (jnr.ne.0) then
                        if (klr.ne.jnr) then
                          nd = n - ncor
                          ind = ia(max(id,nd)) + min(id,nd)
                          kmind = ia(max(kmd,ind)) + min(kmd,ind)
                          dkmin = tpdm(kmind)
                          fac = dkmin*eri
                          ix = klr + 1
                          jx = jnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end if
              end do
            end do
c
c  end distribution loops
c
            call ddi_dlbnext(mytask)
          end if  ! dlb
        end do  ! j
      end do  ! i
c
c  (active-active|**) types
c
      do i = ncp1, nocc
        do j = ncp1, i
          ij = ia(max(i,j)) + min(i,j)
          loctsk = loctsk + 1
          if (loctsk.eq.mytask) then
            call ddi_get(d_oooo,1,notr,ij,ij,buff)
c
c  16. h(ik|jl) <- -2*(ij|kl), k,l core
c
            inj = i.ne.j
            do k = 1, ncor
              ikr = irot(i,k)
              if (ikr.ne.0) then
                mx = k
                if (inj) mx = ncor
                do l = 1, mx
                  jlr = irot(j,l)
                  if (jlr.ne.0) then
                    if (ikr.ne.jlr) then
                      kl = ia(max(k,l)) + min(k,l)
                      eri = buff(kl)
                      fac = -two*eri
                      ix = ikr + 1
                      jx = jlr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end if
                end do
              end if
            end do
c
c  17. h(kl|jm) <- d(ik)*(ij|lm), l,m core
c
            id = i - ncor
            jd = j - ncor
            inj = i.ne.j
            do k = ncp1, nocc
              kd = k - ncor
              ink = i.ne.k
              jnk = j.ne.k
              if (j.le.k) then
                ikd = ia(max(id,kd)) + min(id,kd)
                dik = opdm(ikd)
                do l = 1, ncor
                  klr = irot(k,l)
                  if (klr.ne.0) then
                    mx = l
                    if (jnk) mx = ncor
                    do m = 1, mx
                      jmr = irot(j,m)
                      if (jmr.ne.0) then
                        if (klr.ne.jmr) then
                          lm = ia(max(l,m)) + min(l,m)
                          eri = buff(lm)
                          fac = dik*eri
                          ix = klr + 1
                          jx = jmr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end if
                end do
              end if
              if (inj.and.(i.le.k)) then
                jkd = ia(max(jd,kd)) + min(jd,kd)
                djk = opdm(jkd)
                do l = 1, ncor
                  klr = irot(k,l)
                  if (klr.ne.0) then
                    mx = l
                    if (ink) mx = ncor
                    do m = 1, mx
                      imr = irot(i,m)
                      if (imr.ne.0) then
                        if (klr.ne.imr) then
                          lm = ia(max(l,m)) + min(l,m)
                          eri = buff(lm)
                          fac = djk*eri
                          ix = klr + 1
                          jx = imr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end if
                end do
              end if
            end do   !  k
c
c  19. h(ik|lm) <- d(jl)*(ij|km), k,m core
c
            id = i - ncor
            jd = j - ncor
            inj = i.ne.j
            do k = 1, ncor
              ikr = irot(i,k)
              if (ikr.ne.0) then
                do l = ncp1, i
                  ld = l - ncor
                  jld = ia(max(jd,ld)) + min(jd,ld)
                  djl = opdm(jld)
                  mx = k
                  if (i.ne.l) mx = ncor
                  do m = 1, mx
                    lmr = irot(l,m)
                    if (lmr.ne.0) then
                      if (ikr.ne.lmr) then
                        km = ia(max(k,m)) + min(k,m)
                        eri = buff(km)
                        fac = djl*eri
                        ix = ikr + 1
                        jx = lmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end do
              end if
              if (inj) then
                jkr = irot(j,k)
                if (jkr.ne.0) then
                  do l = ncp1, j
                    ld = l - ncor
                    ild = ia(max(id,ld)) + min(id,ld)
                    dil = opdm(ild)
                    mx = k
                    if (j.ne.l) mx = ncor
                    do m = 1, mx
                      lmr = irot(l,m)
                      if (lmr.ne.0) then
                        if (jkr.ne.lmr) then
                          km = ia(max(k,m)) + min(k,m)
                          eri = buff(km)
                          fac = dil*eri
                          ix = jkr + 1
                          jx = lmr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end if
              end if
            end do   !  k
c
c  20. h(kl|mn) <- d(ij|km)*(ij|ln), l,n core
c
            id = i - ncor
            jd = j - ncor
            ijd = ia(max(id,jd)) + min(id,jd)
            inj = i.ne.j
            do k = ncp1, nocc
              kd = k - ncor
              do l = 1, ncor
                klr = irot(k,l)
                if (klr.ne.0) then
                  do m = ncp1, k
                    md = m - ncor
                    kmd = ia(max(kd,md)) + min(kd,md)
                    ijkmd = ia(max(ijd,kmd)) + min(ijd,kmd)
                    dijkm = tpdm(ijkmd)
                    if (inj) dijkm = dijkm*two
                    mx = l
                    if (k.ne.m) mx = ncor
                    do n = 1, mx
                      mnr = irot(m,n)
                      if (mnr.ne.0) then
                        if (klr.ne.mnr) then
                          ln = ia(max(l,n)) + min(l,n)
                          eri = buff(ln)
                          fac = dijkm*eri
                          ix = klr + 1
                          jx = mnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end if
              end do
            end do
c
c  21. h(ik|lm) <- d(jl)*(ij|km), k core
c
            id = i - ncor
            jd = j - ncor
            inj = i.ne.j
            do k = 1, ncor
              ikr = irot(i,k)
              if (ikr.ne.0) then
                do l = ncp1, nocc
                  ld = l - ncor
                  jld = ia(max(jd,ld)) + min(jd,ld)
                  djl = opdm(jld)
                  do m = ncp1, l-1
                    lmr = irot(l,m)
                    if (lmr.ne.0) then
                      if (ikr.ne.lmr) then
                        km = ia(max(k,m)) + min(k,m)
                        eri = buff(km)
                        fac = djl*eri
                        ix = ikr + 1
                        jx = lmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end do   !  l
              end if
              if (inj) then
                jkr = irot(j,k)
                if (jkr.ne.0) then
                  do l = ncp1, nocc
                    ld = l - ncor
                    ild = ia(max(id,ld)) + min(id,ld)
                    dil = opdm(ild)
                    do m = ncp1, l-1
                      lmr = irot(l,m)
                      if (lmr.ne.0) then
                        if (jkr.ne.lmr) then
                          km = ia(max(k,m)) + min(k,m)
                          eri = buff(km)
                          fac = dil*eri
                          ix = jkr + 1
                          jx = lmr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end if
              end if
            end do   !  k
c
c  22. h(kl|mn) <- d(ij|km)*(ij|ln), n core
c
            id = i - ncor
            jd = j - ncor
            ijd = ia(max(id,jd)) + min(id,jd)
            inj = i.ne.j
            do k = ncp1, nocc
              kd = k - ncor
              do l = ncp1, k-1
                klr = irot(k,l)
                if (klr.ne.0) then
                  do m = ncp1, nocc
                    md = m - ncor
                    kmd = ia(max(kd,md)) + min(kd,md)
                    ijkmd = ia(max(ijd,kmd)) + min(ijd,kmd)
                    dijkm = tpdm(ijkmd)
                    if (inj) dijkm = dijkm*two
                    do n = 1, ncor
                      mnr = irot(m,n)
                      if (mnr.ne.0) then
                        if (klr.ne.mnr) then
                          ln = ia(max(l,n)) + min(l,n)
                          eri = buff(ln)
                          fac = dijkm*eri
                          ix = klr + 1
                          jx = mnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end if
              end do
            end do
c
c  23. h(im|ln) <- 2*d(jm|kn)*(ij|kl)
c
            id = i - ncor
            jd = j - ncor
            inj = i.ne.j
            do k = ncp1, nocc
              kd = k - ncor
              do l = ncp1, i
                kl = ia(max(k,l)) + min(k,l)
                eri = buff(kl)*two
                do m = ncp1, i-1
                  imr = irot(i,m)
                  if (imr.ne.0) then
                    md = m - ncor
                    jmd = ia(max(jd,md)) + min(jd,md)
                    mx = l-1
                    if (l.eq.i) mx = m
                    do n = ncp1, mx
                      lnr = irot(l,n)
                      if (lnr.ne.0) then
                        if (imr.ne.lnr) then
                          nd = n - ncor
                          knd = ia(max(kd,nd)) + min(kd,nd)
                          jmknd = ia(max(jmd,knd)) + min(jmd,knd)
                          djmkn = tpdm(jmknd)
                          fac = djmkn*eri
                          ix = imr + 1
                          jx = lnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end if
                end do
              end do
            end do
            if (inj) then
              do k = ncp1, nocc
                kd = k - ncor
                do l = ncp1, j
                  kl = ia(max(k,l)) + min(k,l)
                  eri = buff(kl)*two
                  lej = l.eq.j
                  do m = ncp1, j-1
                    jmr = irot(j,m)
                    if (jmr.ne.0) then
                      md  = m - ncor
                      imd = ia(max(id,md)) + min(id,md)
                      mx = l-1
                      if (lej) mx = m
                      do n = ncp1, mx
                        lnr = irot(l,n)
                        if (lnr.ne.0) then
                          if (jmr.ne.lnr) then
                            nd = n - ncor
                            knd = ia(max(kd,nd)) + min(kd,nd)
                            imknd = ia(max(imd,knd)) + min(imd,knd)
                            dimkn = tpdm(imknd)
                            fac = dimkn*eri
                            ix = jmr + 1
                            jx = lnr + 1
                            prod(ix) = prod(ix) + fac*tvec(jx)
                            prod(jx) = prod(jx) + fac*tvec(ix)
                          end if
                        end if
                      end do
                    end if
                  end do
                end do
              end do
            end if
c
c  24. h(km|ln) <- d(ij|mn)*(ij|kl)
c
            id = i - ncor
            jd = j - ncor
            ijd = ia(max(id,jd)) + min(id,jd)
            inj = i.ne.j
            do k = ncp1, nocc
              do l = ncp1, k
                kl = ia(max(k,l)) + min(k,l)
                eri = buff(kl)
                if (inj) eri = eri*two
                kel = k.eq.l
                do m = ncp1, k-1
                  kmr = irot(k,m)
                  if (kmr.ne.0) then
                    md = m - ncor
                    mx = l-1
                    if (kel) mx = m
                    do n = ncp1, mx
                      lnr = irot(l,n)
                      if (lnr.ne.0) then
                        if (kmr.ne.lnr) then
                          nd = n - ncor
                          mnd = ia(max(md,nd)) + min(md,nd)
                          ijmnd = ia(max(ijd,mnd)) + min(ijd,mnd)
                          dijmn = tpdm(ijmnd)
                          fac = dijmn*eri
                          ix = kmr + 1
                          jx = lnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end if
                end do
              end do
            end do
c
c  25. h(kl|mn) <- d(ij|km)*(ij|ln)
c
            id = i - ncor
            jd = j - ncor
            ijd = ia(max(id,jd)) + min(id,jd)
            inj = i.ne.j
            do k = ncp1, nocc
              kd = k - ncor
              do l = ncp1, k-1
                klr = irot(k,l)
                if (klr.ne.0) then
                  do m = ncp1, k
                    md = m - ncor
                    kmd = ia(max(kd,md)) + min(kd,md)
                    ijkmd = ia(max(ijd,kmd)) + min(ijd,kmd)
                    dijkm = tpdm(ijkmd)
                    if (inj) dijkm = dijkm*two
                    mx = m-1
                    if (k.eq.m) mx = l
                    do n = ncp1, mx
                      mnr = irot(m,n)
                      if (mnr.ne.0) then
                        if (klr.ne.mnr) then
                          ln = ia(max(l,n)) + min(l,n)
                          eri = buff(ln)
                          fac = dijkm*eri
                          ix = klr + 1
                          jx = mnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end if
              end do
            end do
c
c  26. h(jk|ln) <- 2*d(ik|lm)*(ij|mn)
c
            id = i - ncor
            jd = j - ncor
            inj = i.ne.j
            do k = ncp1, nocc
              kd = k - ncor
              if (j.lt.k) then
                jkr = irot(k,j)
                if (jkr.ne.0) then
                  ikd = ia(max(id,kd)) + min(id,kd)
                  do l = ncp1, k
                    ld = l - ncor
                    mx = l-1
                    if (l.eq.k) mx = j
                    do m = ncp1, nocc
                      md = m - ncor
                      lmd = ia(max(ld,md)) + min(ld,md)
                      iklmd = ia(max(ikd,lmd)) + min(ikd,lmd)
                      diklm = tpdm(iklmd)*two
                      do n = ncp1, mx
                        lnr = irot(l,n)
                        if (lnr.ne.0) then
                          if (jkr.ne.lnr) then
                            mn = ia(max(m,n)) + min(m,n)
                            eri = buff(mn)
                            fac = diklm*eri
                            ix = jkr + 1
                            jx = lnr + 1
                            prod(ix) = prod(ix) + fac*tvec(jx)
                            prod(jx) = prod(jx) + fac*tvec(ix)
                          end if
                        end if
                      end do
                    end do
                  end do
                end if
              end if
              if (inj.and.(i.lt.k)) then
                ikr = irot(i,k)
                if (ikr.ne.0) then
                  jkd = ia(max(jd,kd)) + min(jd,kd)
                  do l = ncp1, k
                    ld = l - ncor
                    mx = l-1
                    if (l.eq.k) mx = i
                    do m = ncp1, nocc
                      md = m - ncor
                      lmd = ia(max(ld,md)) + min(ld,md)
                      jklmd = ia(max(jkd,lmd)) + min(jkd,lmd)
                      djklm = tpdm(jklmd)*two
                      do n = ncp1, mx
                        lnr = irot(l,n)
                        if (lnr.ne.0) then
                          if (ikr.ne.lnr) then
                            mn = ia(max(m,n)) + min(m,n)
                            eri = buff(mn)
                            fac = djklm*eri
                            ix = ikr + 1
                            jx = lnr + 1
                            prod(ix) = prod(ix) + fac*tvec(jx)
                            prod(jx) = prod(jx) + fac*tvec(ix)
                          end if
                        end if
                      end do
                    end do
                  end do
                end if
              end if
            end do   !  k
c
c  27. h(kl|mn) <- -d(ij|kn)*(ij|lm)
c
            id = i - ncor
            jd = j - ncor
            ijd = ia(max(id,jd)) + min(id,jd)
            inj = i.ne.j
            do k = ncp1, nocc
              kd = k - ncor
              do l = ncp1, k-1
                klr = irot(k,l)
                if (klr.ne.0) then
                  do m = ncp1, k
                    lm = ia(max(l,m)) + min(l,m)
                    eri = buff(lm)
                    if (inj) eri = eri*two
                    mx = m-1
                    if (k.eq.m) mx = l
                    do n = ncp1, mx
                      mnr = irot(m,n)
                      if (mnr.ne.0) then
                        if (klr.ne.mnr) then
                          nd = n - ncor
                          knd = ia(max(kd,nd)) + min(kd,nd)
                          ijknd = ia(max(ijd,knd)) + min(ijd,knd)
                          dijkn = tpdm(ijknd)
                          fac = -dijkn*eri
                          ix = klr + 1
                          jx = mnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end if
              end do
            end do
c
c  28.  h(jk|ln) <- -2*d(ik|mn)*(ij|lm)
c
            id = i - ncor
            jd = j - ncor
            inj = i.ne.j
            do k = ncp1, nocc
              kd = k - ncor
              if (j.lt.k) then
                jkr = irot(k,j)
                if (jkr.ne.0) then
                  ikd = ia(max(id,kd)) + min(id,kd)
                  do l = ncp1, k
                    mx = l-1
                    if (k.eq.l) mx = j
                    do m = ncp1, nocc
                      md = m - ncor
                      lm = ia(max(l,m)) + min(l,m)
                      eri = buff(lm)*two
                      do n = ncp1, mx
                        lnr = irot(l,n)
                        if (lnr.ne.0) then
                          if (jkr.ne.lnr) then
                            nd = n - ncor
                            mnd = ia(max(md,nd)) + min(md,nd)
                            ikmnd = ia(max(ikd,mnd)) + min(ikd,mnd)
                            dikmn = tpdm(ikmnd)
                            fac = -dikmn*eri
                            ix = jkr + 1
                            jx = lnr + 1
                            prod(ix) = prod(ix) + fac*tvec(jx)
                            prod(jx) = prod(jx) + fac*tvec(ix)
                          end if
                        end if
                      end do
                    end do
                  end do
                end if
              end if
              if (inj.and.(i.lt.k)) then
                ikr = irot(k,i)
                if (ikr.ne.0) then
                  jkd = ia(max(jd,kd)) + min(jd,kd)
                  do l = ncp1, k
                    mx = l-1
                    if (k.eq.l) mx = i
                    do m = ncp1, nocc
                      md = m - ncor
                      lm = ia(max(l,m)) + min(l,m)
                      eri = buff(lm)*two
                      do n = ncp1, mx
                        lnr = irot(l,n)
                        if (lnr.ne.0) then
                          if (ikr.ne.lnr) then
                            nd = n - ncor
                            mnd = ia(max(md,nd)) + min(md,nd)
                            jkmnd = ia(max(jkd,mnd)) + min(jkd,mnd)
                            djkmn = tpdm(jkmnd)
                            fac = -djkmn*eri
                            ix = ikr + 1
                            jx = lnr + 1
                            prod(ix) = prod(ix) + fac*tvec(jx)
                            prod(jx) = prod(jx) + fac*tvec(ix)
                          end if
                        end if
                      end do
                    end do
                  end do
                end if
              end if
            end do   !  k
c
c  29. h(kl|mn) <- -d(ij|lm)*(ij|kn)
c
            id = i - ncor
            jd = j - ncor
            ijd = ia(max(id,jd)) + min(id,jd)
            inj = i.ne.j
            do k = ncp1, nocc
              do l = ncp1, k-1
                ld = l - ncor
                klr = irot(k,l)
                if (klr.ne.0) then
                  do m = ncp1, k
                    md = m - ncor
                    lmd = ia(max(ld,md)) + min(ld,md)
                    ijlmd = ia(max(ijd,lmd)) + min(ijd,lmd)
                    dijlm = tpdm(ijlmd)
                    if (inj) dijlm = dijlm*two
                    mx = m-1
                    if (k.eq.m) mx = l
                    do n = ncp1, mx
                      mnr = irot(m,n)
                      if (mnr.ne.0) then
                        if (klr.ne.mnr) then
                          kn = ia(max(k,n)) + min(k,n)
                          eri = buff(kn)
                          fac = -dijlm*eri
                          ix = klr + 1
                          jx = mnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end if
              end do
            end do
c
c  30. h(ik|ln) <- -2*d(jk|lm)*(ij|mn)
c
            id = i - ncor
            jd = j - ncor
            inj = i.ne.j
            do k = ncp1, i-1
              ikr = irot(i,k)
              if (ikr.ne.0) then
                kd = k - ncor
                jkd = ia(max(jd,kd)) + min(jd,kd)
                do l = ncp1, i
                  ld = l - ncor
                  mx = l-1
                  if (l.eq.i) mx = k
                  do m = ncp1, nocc
                    md = m - ncor
                    lmd = ia(max(ld,md)) + min(ld,md)
                    jklmd = ia(max(jkd,lmd)) + min(jkd,lmd)
                    djklm = tpdm(jklmd)*two
                    do n = ncp1, mx
                      lnr = irot(l,n)
                      if (lnr.ne.0) then
                        if (ikr.ne.lnr) then
                          mn = ia(max(m,n)) + min(m,n)
                          eri = buff(mn)
                          fac = -djklm*eri
                          ix = ikr + 1
                          jx = lnr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end do
                end do
              end if
            end do
            if (inj) then
              do k = ncp1, j-1
                jkr = irot(j,k)
                if (jkr.ne.0) then
                  kd = k - ncor
                  ikd = ia(max(id,kd)) + min(id,kd)
                  do l = ncp1, j
                    ld = l - ncor
                    mx = l-1
                    if (l.eq.j) mx = k
                    do m = ncp1, nocc
                      md = m - ncor
                      lmd = ia(max(ld,md)) + min(ld,md)
                      iklmd = ia(max(ikd,lmd)) + min(ikd,lmd)
                      diklm = tpdm(iklmd)*two
                      do n = ncp1, mx
                        lnr = irot(l,n)
                        if (lnr.ne.0) then
                          if (jkr.ne.lnr) then
                            mn = ia(max(m,n)) + min(m,n)
                            eri = buff(mn)
                            fac = -diklm*eri
                            ix = jkr + 1
                            jx = lnr + 1
                            prod(ix) = prod(ix) + fac*tvec(jx)
                            prod(jx) = prod(jx) + fac*tvec(ix)
                          end if
                        end if
                      end do
                    end do
                  end do
                end if
              end do
            end if
c
c  end distribution loops
c
            call ddi_dlbnext(mytask)
          end if  ! dlb
        end do  ! j
      end do  ! i
c
      if (bench) then
        write(ichanl,9000) '(oo|oo)'
        call timit(1)
      end if
c
c ----------- contributions from (vo|oo) type integrals -----------
c
c  note: all these hessian elements are off-diagonal
c
      call ddi_distrib(d_vooo,ddi_me,ilo,ihi,jlo,jhi)
c
c  (active-core|core-virtual)
c
      do i = ncp1, nocc
        do j = 1, ncor
          ij = ia(max(i,j)) + min(i,j)
          do k = 1, ncor
            ijk = (ij-1)*nocc + k
            loctsk = loctsk + 1
            if (loctsk.eq.mytask) then
              call ddi_get(d_vooo,1,nvir,ijk,ijk,buff)
c
c  31. h(ak|ij) <- 8*(ak|ij), j,k core
c
              ijr = irot(i,j)
              if (ijr.ne.0) then
                do a = 1, nvir
                  ar = a + nocc
                  kar = irot(k,ar)
                  if (kar.ne.0) then
                    eri = buff(a)
                    fac = eight*eri
                    ix = ijr + 1
                    jx = kar + 1
                    prod(ix) = prod(ix) + fac*tvec(jx)
                    prod(jx) = prod(jx) + fac*tvec(ix)
                  end if
                end do
              end if
c
c  32. h(aj|ik) <- -2*(aj|ik), j,k core
c
              ikr = irot(i,k)
              if (ikr.ne.0) then
                do a = 1, nvir
                  ar = a + nocc
                  jar = irot(j,ar)
                  if (jar.ne.0) then
                    eri = buff(a)
                    fac = -two*eri
                    ix = ikr + 1
                    jx = jar + 1
                    prod(ix) = prod(ix) + fac*tvec(jx)
                    prod(jx) = prod(jx) + fac*tvec(ix)
                  end if
                end do
              end if
c
c  33. h(ak|lj) <- -4*d(il)*(ak|ij), j,k core
c
              id = i - ncor
              do a = 1, nvir
                eri = buff(a)
                ar = a + nocc
                kar = irot(k,ar)
                if (kar.ne.0) then
                  do l = ncp1, nocc
                    jlr = irot(l,j)
                    if (jlr.ne.0) then
                      ld = l - ncor
                      ild = ia(max(id,ld)) + min(id,ld)
                      dil = four*opdm(ild)
                      fac = -dil*eri
                      ix = kar + 1
                      jx = jlr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                end if
c
c  34. h(aj|lk) <- d(il)*(ak|ij), j,k core
c
                jar = irot(j,ar)
                if (jar.ne.0) then
                  do l = ncp1, nocc
                    klr = irot(l,k)
                    if (klr.ne.0) then
                      ld = l - ncor
                      ild = ia(max(id,ld)) + min(id,ld)
                      dil = opdm(ild)
                      fac = dil*eri
                      ix = jar + 1
                      jx = klr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                end if
              end do   !  a
c
c  end distribution loops
c
              call ddi_dlbnext(mytask)
            end if  ! dlb
          end do  ! k
        end do  ! j
      end do  ! i
c
c  (core-core|active-virtual)
c
      do i = 1, ncor
        do j = 1, i
          ij = ia(max(i,j)) + min(i,j)
          do k = ncp1, nocc
            ijk = (ij-1)*nocc + k
            loctsk = loctsk + 1
            if (loctsk.eq.mytask) then
              call ddi_get(d_vooo,1,nvir,ijk,ijk,buff)
              inj = i.ne.j
c
c  35. h(ai|jk) <- -2*(ak|ij), i,j core
c
              jkr = irot(k,j)
              if (jkr.ne.0) then
                do a = 1, nvir
                  ar = a + nocc
                  iar = irot(i,ar)
                  if (iar.ne.0) then
                    eri = buff(a)
                    fac = -two*eri
                    ix = jkr + 1
                    jx = iar + 1
                    prod(ix) = prod(ix) + fac*tvec(jx)
                    prod(jx) = prod(jx) + fac*tvec(ix)
                  end if
                end do
              end if
              if (inj) then
                ikr = irot(k,i)
                if (ikr.ne.0) then
                  do a = 1, nvir
                    ar = a + nocc
                    jar = irot(j,ar)
                    if (jar.ne.0) then
                      eri = buff(a)
                      fac = -two*eri
                      ix = ikr + 1
                      jx = jar + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                end if
              end if
c
c  36. h(ai|lj) <- d(kl)*(ak|ij), i,j core
c
              kd = k - ncor
              do a = 1, nvir
                eri = buff(a)
                ar = a + nocc
                iar = irot(i,ar)
                if (iar.ne.0) then
                  do l = ncp1, nocc
                    ljr = irot(l,j)
                    if (ljr.ne.0) then
                      ld = l - ncor
                      kld = ia(max(kd,ld)) + min(kd,ld)
                      dkl = opdm(kld)
                      fac = dkl*eri
                      ix = iar + 1
                      jx = ljr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                end if
                if (inj) then
                  jar = irot(j,ar)
                  if (jar.ne.0) then
                    do l = ncp1, nocc
                      lir = irot(l,i)
                      if (lir.ne.0) then
                        ld = l - ncor
                        kld = ia(max(kd,ld)) + min(kd,ld)
                        dkl = opdm(kld)
                        fac = dkl*eri
                        ix = jar + 1
                        jx = lir + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end do
                  end if
                end if
              end do   !  a
c
c  end distribution loops
c
              call ddi_dlbnext(mytask)
            end if  ! dlb
          end do  ! k
        end do  ! j
      end do  ! i
c
c  (active-active|core-virtual)
c
      do i = ncp1, nocc
        do j = ncp1, i
          ij = ia(max(i,j)) + min(i,j)
          do k = 1, ncor
            ijk = (ij-1)*nocc + k
            loctsk = loctsk + 1
            if (loctsk.eq.mytask) then
              call ddi_get(d_vooo,1,nvir,ijk,ijk,buff)
c
c  37. h(ak|il) <- 4*d(jl)*(ak|ij), k core
c
              inj = i.ne.j
              id = i - ncor
              jd = j - ncor
              do a = 1, nvir
                eri = buff(a)*four
                ar = a + nocc
                kar = irot(k,ar)
                if (kar.ne.0) then
                  do l = ncp1, i-1
                    ilr = irot(i,l)
                    if (ilr.ne.0) then
                      ld = l - ncor
                      jld = ia(max(jd,ld)) + min(jd,ld)
                      djl = opdm(jld)
                      fac = djl*eri
                      ix = kar + 1
                      jx = ilr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                  if (inj) then
                    do l = ncp1, j-1
                      jlr = irot(j,l)
                      if (jlr.ne.0) then
                        ld = l - ncor
                        ild = ia(max(id,ld)) + min(id,ld)
                        dil = opdm(ild)
                        fac = dil*eri
                        ix = kar + 1
                        jx = jlr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end do
                  end if
                end if
              end do   !  a
c
c  38. h(ak|jl) <- -4*d(il)*(ak|ij), k core
c
              inj = i.ne.j
              id = i - ncor
              jd = j - ncor
              do a = 1, nvir
                eri = buff(a)*four
                ar = a + nocc
                kar = irot(k,ar)
                if (kar.ne.0) then
                  do l = j+1, nocc
                    jlr = irot(l,j)
                    if (jlr.ne.0) then
                      ld = l - ncor
                      ild = ia(max(id,ld)) + min(id,ld)
                      dil = opdm(ild)
                      fac = -dil*eri
                      ix = kar + 1
                      jx = jlr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                  if (inj) then
                    do l = i+1, nocc
                      ilr = irot(l,i)
                      if (ilr.ne.0) then
                        ld = l - ncor
                        jld = ia(max(jd,ld)) + min(jd,ld)
                        djl = opdm(jld)
                        fac = -djl*eri
                        ix = kar + 1
                        jx = ilr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end do
                  end if
                end if
              end do   !  a
c
c  39. h(al|ik) <- -d(jl)*(ak|ij), k core
c
              inj = i.ne.j
              id = i - ncor
              jd = j - ncor
              ikr = irot(i,k)
              if (ikr.ne.0) then
                do a = 1, nvir
                  eri = buff(a)
                  ar = a + nocc
                  do l = ncp1, nocc
                    lar = irot(l,ar)
                    if (lar.ne.0) then
                      ld = l - ncor
                      jld = ia(max(jd,ld)) + min(jd,ld)
                      djl = opdm(jld)
                      fac = -djl*eri
                      ix = ikr + 1
                      jx = lar + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                end do
              end if
              if (inj) then
                jkr = irot(j,k)
                if (jkr.ne.0) then
                  do a = 1, nvir
                    eri = buff(a)
                    ar = a + nocc
                    do l = ncp1, nocc
                      lar = irot(l,ar)
                      if (lar.ne.0) then
                        ld = l - ncor
                        ild = ia(max(id,ld)) + min(id,ld)
                        dil = opdm(ild)
                        fac = -dil*eri
                        ix = jkr + 1
                        jx = lar + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end do
                  end do
                end if
              end if
c
c  40. h(al|km) <- -d(ij|lm)*(ak|ij), k core
c
              inj = i.ne.j
              id = i - ncor
              jd = j - ncor
              ijd = ia(max(id,jd)) + min(id,jd)
              do a = 1, nvir
                eri = buff(a)
                if (inj) eri = eri*two
                ar = a + nocc
                do l = ncp1, nocc
                  ld = l - ncor
                  lar = irot(l,ar)
                  if (lar.ne.0) then
                    do m = ncp1, nocc
                      kmr = irot(m,k)
                      if (kmr.ne.0) then
                        md = m - ncor
                        lmd = ia(max(ld,md)) + min(ld,md)
                        ijlmd = ia(max(ijd,lmd)) + min(ijd,lmd)
                        dijlm = tpdm(ijlmd)
                        fac = -dijlm*eri
                        ix = lar + 1
                        jx = kmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end do
                  end if
                end do
              end do
c
c  end distribution loops
c
              call ddi_dlbnext(mytask)
            end if  ! dlb
          end do  ! k
        end do  ! j
      end do  ! i
c
c  (active-core|active-virtual)
c
      do i = ncp1, nocc
        do j = 1, ncor
          ij = ia(max(i,j)) + min(i,j)
          do k = ncp1, nocc
            ijk = (ij-1)*nocc + k
            loctsk = loctsk + 1
            if (loctsk.eq.mytask) then
              call ddi_get(d_vooo,1,nvir,ijk,ijk,buff)
c
c  41. h(aj|il) <- -d(kl)*(ak|ij), j core
c
              id = i - ncor
              kd = k - ncor
              do a = 1, nvir
                eri = buff(a)
                ar = a + nocc
                jar = irot(j,ar)
                if (jar.ne.0) then
                  do l = ncp1, i-1
                    ilr = irot(i,l)
                    if (ilr.ne.0) then
                      ld = l - ncor
                      kld = ia(max(kd,ld)) + min(kd,ld)
                      dkl = opdm(kld)
                      fac = -dkl*eri
                      ix = jar + 1
                      jx = ilr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
c
c  42. h(aj|kl) <- -d(il)*(ak|ij), j core
c
                  do l = ncp1, k-1
                    klr = irot(k,l)
                    if (klr.ne.0) then
                      ld = l - ncor
                      ild = ia(max(id,ld)) + min(id,ld)
                      dil = opdm(ild)
                      fac = -dil*eri
                      ix = jar + 1
                      jx = klr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                end if
              end do   !  a
c
c  43. h(aj|il) <- d(kl)*(ak|ij), j core
c
              id = i - ncor
              kd = k - ncor
              do a = 1, nvir
                eri = buff(a)
                ar = a + nocc
                jar = irot(j,ar)
                if (jar.ne.0) then
                  do l = i+1, nocc
                    ilr = irot(l,i)
                    if (ilr.ne.0) then
                      ld = l - ncor
                      kld = ia(max(kd,ld)) + min(kd,ld)
                      dkl = opdm(kld)
                      fac = dkl*eri
                      ix = jar + 1
                      jx = ilr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
c
c  44. h(aj|kl) <- d(il)*(ak|ij), j core
c
                  do l = k+1, nocc
                    klr = irot(l,k)
                    if (klr.ne.0) then
                      ld = l - ncor
                      ild = ia(max(id,ld)) + min(id,ld)
                      dil = opdm(ild)
                      fac = dil*eri
                      ix = jar + 1
                      jx = klr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                end if
              end do   !  a
c
c  45. h(al|ij) <- 4*d(kl)*(ak|ij), j core
c
              kd = k - ncor
              ijr = irot(i,j)
              if (ijr.ne.0) then
                do a = 1, nvir
                  eri = buff(a)*four
                  ar = a + nocc
                  do l = ncp1, nocc
                    lar = irot(l,ar)
                    if (lar.ne.0) then
                      ld = l - ncor
                      kld = ia(max(kd,ld)) + min(kd,ld)
                      dkl = opdm(kld)
                      fac = dkl*eri
                      ix = ijr + 1
                      jx = lar + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                end do
              end if
c
c  46. h(al|kj) <- -d(il)*(ak|ij), j core
c
              id = i - ncor
              kjr = irot(k,j)
              if (kjr.ne.0) then
                do a = 1, nvir
                  eri = buff(a)
                  ar = a + nocc
                  do l = ncp1, nocc
                    lar = irot(l,ar)
                    if (lar.ne.0) then
                      ld = l - ncor
                      ild = ia(max(id,ld)) + min(id,ld)
                      dil = opdm(ild)
                      fac = -dil*eri
                      ix = kjr + 1
                      jx = lar + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end do
                end do
              end if
c
c  47. h(al|jm) <- -2*d(kl|im)*(ak|ij), j core
c
              id = i - ncor
              kd = k - ncor
              do a = 1, nvir
                eri = buff(a)*two
                ar = a + nocc
                do l = ncp1, nocc
                  lar = irot(l,ar)
                  if (lar.ne.0) then
                    ld = l - ncor
                    kld = ia(max(kd,ld)) + min(kd,ld)
                    do m = ncp1, nocc
                      jmr = irot(m,j)
                      if (jmr.ne.0) then
                        md = m - ncor
                        imd = ia(max(id,md)) + min(id,md)
                        klimd = ia(max(kld,imd)) + min(kld,imd)
                        dklim = tpdm(klimd)
                        fac = -dklim*eri
                        ix = lar + 1
                        jx = jmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end do
                  end if
                end do
              end do
c
c  end distribution loops
c
              call ddi_dlbnext(mytask)
            end if  ! dlb
          end do  ! k
        end do  ! j
      end do  ! i
c
c  (active-active|active-virtual)
c
      do i = ncp1, nocc
        do j = ncp1, i
          ij = ia(max(i,j)) + min(i,j)
          do k = ncp1, nocc
            ijk = (ij-1)*nocc + k
            loctsk = loctsk + 1
            if (loctsk.eq.mytask) then
              call ddi_get(d_vooo,1,nvir,ijk,ijk,buff)
c
c  48. h(al|im) <- 2*d(kl|jm)*(ak|ij)
c
              inj = i.ne.j
              id = i - ncor
              jd = j - ncor
              kd = k - ncor
              do a = 1, nvir
                eri = buff(a)*two
                ar = a + nocc
                do l = ncp1, nocc
                  lar = irot(l,ar)
                  if (lar.ne.0) then
                    ld = l - ncor
                    kld = ia(max(kd,ld)) + min(kd,ld)
                    do m = ncp1, i-1
                      imr = irot(i,m)
                      if (imr.ne.0) then
                        md = m - ncor
                        jmd = ia(max(jd,md)) + min(jd,md)
                        kljmd = ia(max(kld,jmd)) + min(kld,jmd)
                        dkljm = tpdm(kljmd)
                        fac = dkljm*eri
                        ix = lar + 1
                        jx = imr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end do
c
c  49. h(al|jm) <- -2*d(kl|im)*(ak|ij)
c
                    do m = j+1, nocc
                      jmr = irot(j,m)
                      if (jmr.ne.0) then
                        md = m - ncor
                        imd = ia(max(id,md)) + min(id,md)
                        klimd = ia(max(kld,imd)) + min(kld,imd)
                        dklim = tpdm(klimd)
                        fac = -dklim*eri
                        ix = lar + 1
                        jx = jmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end do
c
c  50. h(al|jm) <- 2*d(kl|im)*(ak|ij)
c
                    if (inj) then
                      do m = ncp1, j-1
                        jmr = irot(j,m)
                        if (jmr.ne.0) then
                          md = m - ncor
                          imd = ia(max(id,md)) + min(id,md)
                          klimd = ia(max(kld,imd)) + min(kld,imd)
                          dklim = tpdm(klimd)
                          fac = dklim*eri
                          ix = lar + 1
                          jx = jmr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end do
c
c  51. h(al|mi) <- -2*d(kl|jm)*(ak|ij)
c
                      do m = i+1, nocc
                        imr = irot(i,m)
                        if (imr.ne.0) then
                          md = m - ncor
                          jmd = ia(max(jd,md)) + min(jd,md)
                          kljmd = ia(max(kld,jmd)) + min(kld,jmd)
                          dkljm = tpdm(kljmd)
                          fac = -dkljm*eri
                          ix = lar + 1
                          jx = imr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end do
                    end if
                  end if
                end do   !  l
              end do   !  a
c
c  52. h(al|km) <- d(lm|ij)*(ak|ij)
c
              inj = i.ne.j
              id = i - ncor
              jd = j - ncor
              ijd = ia(max(id,jd)) + min(id,jd)
              do a = 1, nvir
                eri = buff(a)
                if (inj) eri = eri*two
                ar = a + nocc
                do l = ncp1, nocc
                  lar = irot(l,ar)
                  if (lar.ne.0) then
                    ld = l - ncor
                    do m = ncp1, k-1
                      kmr = irot(k,m)
                      if (kmr.ne.0) then
                        md = m - ncor
                        lmd = ia(max(ld,md)) + min(ld,md)
                        ijlmd = ia(max(ijd,lmd)) + min(ijd,lmd)
                        dijlm = tpdm(ijlmd)
                        fac = dijlm*eri
                        ix = lar + 1
                        jx = kmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end do
c
c  53. h(al|mk) <- -d(lm|ij)*(ak|ij)
c
                    do m = k+1, nocc
                      kmr = irot(k,m)
                      if (kmr.ne.0) then
                        md = m - ncor
                        lmd = ia(max(ld,md)) + min(ld,md)
                        ijlmd = ia(max(ijd,lmd)) + min(ijd,lmd)
                        dijlm = tpdm(ijlmd)
                        fac = -dijlm*eri
                        ix = lar + 1
                        jx = kmr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end do
                  end if
                end do    !  l
              end do    !  a
c
c  end distribution loops
c
              call ddi_dlbnext(mytask)
            end if  ! dlb
          end do  ! k
        end do  ! j
      end do  ! i
c
      if (bench) then
        write(ichanl,9000) '(vo|oo)'
        call timit(1)
      end if
c
c ----------- contributions from (vv|oo) type integrals -----------
c
      call ddi_distrib(d_vvoo,ddi_me,ilo,ihi,jlo,jhi)
c
c  (virtual-virtual|core-core)
c
      do i = 1, ncor
        do j = 1, i
          ij = ia(max(i,j)) + min(i,j)
          loctsk = loctsk + 1
          if (loctsk.eq.mytask) then
            call ddi_get(d_vvoo,1,nvtr,ij,ij,buff)
c
c  54. h(ai|bj) <- -2*(ab|ij), i,j core
c
            do a = 1, nvir
              ar = a + nocc
              iar = irot(i,ar)
              if (iar.ne.0) then
                do b = 1, a
                  br = b + nocc
                  jbr = irot(j,br)
                  if (jbr.ne.0) then
                    if (iar.ne.jbr) then
                      ab = ia(max(a,b)) + min(a,b)
                      eri = buff(ab)
                      fac = -two*eri
                      ix = iar + 1
                      jx = jbr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end if
                end do
              end if
            end do
            if (i.ne.j) then
              do a = 1, nvir
                ar = a + nocc
                jar = irot(j,ar)
                if (jar.ne.0) then
                  do b = 1, a-1
                    br = b + nocc
                    ibr = irot(i,br)
                    if (ibr.ne.0) then
                      if (jar.ne.ibr) then
                        ab = ia(max(a,b)) + min(a,b)
                        eri = buff(ab)
                        fac = -two*eri
                        ix = jar + 1
                        jx = ibr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end if
              end do
            end if
c
c  end distribution loops
c
            call ddi_dlbnext(mytask)
          end if  ! dlb
        end do  ! j
      end do  ! i
c
c  (virtual-virtual|active-core)
c
      do i = ncp1, nocc
        do j = 1, ncor
          ij = ia(max(i,j)) + min(i,j)
          loctsk = loctsk + 1
          if (loctsk.eq.mytask) then
            call ddi_get(d_vvoo,1,nvtr,ij,ij,buff)
c
c  55. h(ak|bj) <- -d(ik)*(ab|ij), j core
c
            id = i - ncor
            do a = 1, nvir
              ar = a + nocc
              do b = 1, a
                br = b + nocc
                jbr = irot(j,br)
                if (jbr.ne.0) then
                  ab = ia(max(a,b)) + min(a,b)
                  eri = buff(ab)
                  do k = ncp1, nocc
                    kar = irot(k,ar)
                    if (kar.ne.0) then
                      if (jbr.ne.kar) then
                        kd = k - ncor
                        ikd = ia(max(id,kd)) + min(id,kd)
                        dik = opdm(ikd)
                        fac = -dik*eri
                        ix = jbr + 1
                        jx = kar + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end if
              end do
            end do
            do a = 1, nvir
              ar = a + nocc
              jar = irot(j,ar)
              if (jar.ne.0) then
                do b = 1, a-1
                  br = b + nocc
                  ab = ia(max(a,b)) + min(a,b)
                  eri = buff(ab)
                  do k = ncp1, nocc
                    kbr = irot(k,br)
                    if (kbr.ne.0) then
                      if (jar.ne.kbr) then
                        kd = k - ncor
                        ikd = ia(max(id,kd)) + min(id,kd)
                        dik = opdm(ikd)
                        fac = -dik*eri
                        ix = jar + 1
                        jx = kbr + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end do
              end if
            end do
c
c  end distribution loops
c
            call ddi_dlbnext(mytask)
          end if  ! dlb
        end do  ! j
      end do  ! i
c
c  (virtual-virtual|active-active)
c
      do i = ncp1, nocc
        do j = ncp1, i
          ij = ia(max(i,j)) + min(i,j)
          loctsk = loctsk + 1
          if (loctsk.eq.mytask) then
            call ddi_get(d_vvoo,1,nvtr,ij,ij,buff)
c
c  56. h(ak|bl) <- d(ij|kl)*(ab|ij)
c
            inj = i.ne.j
            id = i - ncor
            jd = j - ncor
            ijd = ia(max(id,jd)) + min(id,jd)
            do a = 1, nvir
              ar = a + nocc
              do b = 1, a
                br = b + nocc
                ab = ia(max(a,b)) + min(a,b)
                eri = buff(ab)
                if (inj) eri = eri*two
                anb = a.ne.b
                do k = ncp1, nocc
                  kar = irot(k,ar)
                  if (kar.ne.0) then
                    kd = k - ncor
                    mx = k
                    if (anb) mx = nocc
                    do l = ncp1, mx
                      lbr = irot(l,br)
                      if (lbr.ne.0) then
                        if (kar.ne.lbr) then
                          ld = l - ncor
                          kld = ia(max(kd,ld)) + min(kd,ld)
                          ijkld = ia(max(ijd,kld)) + min(ijd,kld)
                          dijkl = tpdm(ijkld)
                          fac = dijkl*eri
                          ix = kar + 1
                          jx = lbr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end if
                end do
              end do
            end do
c
c  end distribution loops
c
            call ddi_dlbnext(mytask)
          end if  ! dlb
        end do  ! j
      end do  ! i
c
      if (bench) then
        write(ichanl,9000) '(vv|oo)'
        call timit(1)
      end if
c
c ----------- contributions from (vo|vo) type integrals -----------
c
      call ddi_distrib(d_vovo,ddi_me,ilo,ihi,jlo,jhi)
c
c  (virtual-core|virtual-core)
c
      do i = 1, ncor
        do j = 1, i
          ij = ia(max(i,j)) + min(i,j)
          loctsk = loctsk + 1
          if (loctsk.eq.mytask) then
            call ddi_get(d_vovo,1,nvsq,ij,ij,buff)
c
c  57. h(ai|bj) <- 8*(ai|bj) -2*(aj|bi), i,j core
c
            inj = i.ne.j
            do a = 1, nvir
              ar = a + nocc
              iar = irot(i,ar)
              if (iar.ne.0) then
                mx = a
                if (inj) mx = nvir
                do b = 1, mx
                  br = b + nocc
                  jbr = irot(j,br)
                  if (jbr.ne.0) then
                    if (iar.ne.jbr) then
                      ab = (b-1)*nvir + a
                      ba = (a-1)*nvir + b
                      eri1 = buff(ab)*eight
                      eri2 = buff(ba)*two
                      fac = eri1 - eri2
                      ix = iar + 1
                      jx = jbr + 1
                      prod(ix) = prod(ix) + fac*tvec(jx)
                      prod(jx) = prod(jx) + fac*tvec(ix)
                    end if
                  end if
                end do
              end if
            end do
c
c  end distribution loops
c
            call ddi_dlbnext(mytask)
          end if  ! dlb
        end do  ! j
      end do  ! i
c
c  (virtual-active|virtual-core)
c
      do i = ncp1, nocc
        do j = 1, ncor
          ij = ia(max(i,j)) + min(i,j)
          loctsk = loctsk + 1
          if (loctsk.eq.mytask) then
            call ddi_get(d_vovo,1,nvsq,ij,ij,buff)
c
c  58. h(ak|bj) <- 4*d(ik)*(ai|bj) -d(ik)*(aj|bi), j core
c
            id = i - ncor
            do a = 1, nvir
              ar = a + nocc
              do b = 1, nvir
                br = b + nocc
                jbr = irot(j,br)
                if (jbr.ne.0) then
                  ab = (b-1)*nvir + a
                  ba = (a-1)*nvir + b
                  eri1 = buff(ab)*four
                  eri2 = buff(ba)
                  do k = ncp1, nocc
                    kar = irot(k,ar)
                    if (kar.ne.0) then
                      if (jbr.ne.kar) then
                        kd = k - ncor
                        ikd = ia(max(id,kd)) + min(id,kd)
                        dik = opdm(ikd)
                        fac = dik*(eri1-eri2)
                        ix = jbr + 1
                        jx = kar + 1
                        prod(ix) = prod(ix) + fac*tvec(jx)
                        prod(jx) = prod(jx) + fac*tvec(ix)
                      end if
                    end if
                  end do
                end if
              end do
            end do
c
c  end distribution loops
c
            call ddi_dlbnext(mytask)
          end if  ! dlb
        end do  ! j
      end do  ! i
c
c  (virtual-active|virtual-active)
c
      do i = ncp1, nocc
        do j = ncp1, i
          ij = ia(max(i,j)) + min(i,j)
          loctsk = loctsk + 1
          if (loctsk.eq.mytask) then
            call ddi_get(d_vovo,1,nvsq,ij,ij,buff)
c
c  59. h(ak|bl) <- 2*d(ik|jl)*(ai|bj)
c
            id = i - ncor
            jd = j - ncor
            do a = 1, nvir
              ar = a + nocc
              do b = 1, a
                br = b + nocc
                ab = (b-1)*nvir + a
                eri = buff(ab)*two
                anb = a.ne.b
                do k = ncp1, nocc
                  kar = irot(k,ar)
                  if (kar.ne.0) then
                    kd = k - ncor
                    ikd = ia(max(id,kd)) + min(id,kd)
                    mx = k
                    if (anb) mx = nocc
                    do l = ncp1, mx
                      lbr = irot(l,br)
                      if (lbr.ne.0) then
                        if (kar.ne.lbr) then
                          ld = l - ncor
                          jld = ia(max(jd,ld)) + min(jd,ld)
                          ikjld = ia(max(ikd,jld)) + min(ikd,jld)
                          dikjl = tpdm(ikjld)
                          fac = dikjl*eri
                          ix = kar + 1
                          jx = lbr + 1
                          prod(ix) = prod(ix) + fac*tvec(jx)
                          prod(jx) = prod(jx) + fac*tvec(ix)
                        end if
                      end if
                    end do
                  end if
                end do
              end do
            end do
            if (i.ne.j) then
              do a = 1, nvir
                ar = a + nocc
                do b = 1, a
                  br = b + nocc
                  ba = (a-1)*nvir + b
                  eri = buff(ba)*two
                  anb = a.ne.b
                  do k = ncp1, nocc
                    kar = irot(k,ar)
                    if (kar.ne.0) then
                      kd = k - ncor
                      jkd = ia(max(jd,kd)) + min(jd,kd)
                      mx = k
                      if (anb) mx = nocc
                      do l = ncp1, mx
                        lbr = irot(l,br)
                        if (lbr.ne.0) then
                          if (kar.ne.lbr) then
                            ld = l - ncor
                            ild = ia(max(id,ld)) + min(id,ld)
                            iljkd = ia(max(ild,jkd)) + min(ild,jkd)
                            diljk = tpdm(iljkd)
                            fac = diljk*eri
                            ix = kar + 1
                            jx = lbr + 1
                            prod(ix) = prod(ix) + fac*tvec(jx)
                            prod(jx) = prod(jx) + fac*tvec(ix)
                          end if
                        end if
                      end do
                    end if
                  end do
                end do
              end do
            end if
c
c  end distribution loops
c
            call ddi_dlbnext(mytask)
          end if  ! dlb
        end do  ! j
      end do  ! i
c
      if (bench) then
        write(ichanl,9000) '(vo|vo)'
        call timit(1)
      end if
c
c  globally sum the product vector
c
      call ddi_gsumf(2294,prod,nrot+1)
c
c  double product vector
c
      call dscal(nrot+1,two,prod,1)
c
c  contribution from diagonal elements of hessian
c
      do i = 1, nrot+1
        prod(i) = prod(i) + diah(i)*tvec(i)
      end do
      call ddi_dlbreset()
      return
9000  format(' ..... done with ',a8,' contributions .....')
      end
c*module masscf  *deck ntndvd
      subroutine ntndvd(h,hd,v,w,t
     *,                 aa,a,vec,eig,wrk,iwrk, ia
     *,                 nwks,mxxpan,cvgtol,maxit
     *,                 out,dbug,prttol
     *,                 nmos,ncor,nocc,nrot
     *,                 opdm,tpdm,fcor,fval,lagn,irot,buff)
      implicit  REAL  (a-h,o-z)
INCLUDE(common/restar)
c
c     data for parallel call computing the augmented hessian on 
c     the fly is nmos,ncor,nocc,nrot,opdm,tpdm,fcor,fval,lagn,
c     irot,buff: these arguments are not used by the serial version.
c
      logical cvged,out,dbug,part1,goparr,dskwrk,maswrk
c
      common /iofile_f/ ir,iw,ip,ijko,ijkt,idaf,nav,ioda(950)
      common /par   / me,master,nproc,ibtyp,iptim,goparr,dskwrk,maswrk
c
      dimension h(1),hd(1), v(nwks,1),w(nwks,1),t(nwks)
      dimension aa(1),a(1),vec(mxxpan,1),eig(1),wrk(*),iwrk(*)
      dimension ia(1), kcoef(6),coefk(6)
c
      integer irot(nocc,*)
      REAL   opdm(*),tpdm(*),fcor(*),fval(*),lagn(*),buff(*)
c
      data zero,one /0.0d+00,1.0d+00/
      data tol      /1.0d-09/
c
c     ----- davidson's method modified to diagonalize -----
c                 the augmented hessian matrix
c
c        only one root and a thresold very strong ( 1.0d-9 )
c
c        minimum of expansions is one et maximum default 50
c
c        maximum number of iterations 200 (maxdia in nuton )
c
c     ----- generate trial expansion vector set -----
c
      thres=tol*tol
c
      kstat = 1
      v(1   ,kstat)=one
      do 10 iwks=2,nwks
   10 v(iwks,kstat)=zero
c
      if(dbug) write(iw,9996) kstat,(iwks,v(iwks,1),iwks=1,nwks)
c
      do 20 i=1,mxxpan
      do 20 j=1,i
      ij=ia(i)+j
   20 aa(ij)=zero
c
c     ----- start iteration -----
c
      if(dbug) write(iw,9998)
      iter=0
      nxpan0=1
  100 continue
      iter=iter+1
      if(iter.gt.maxit) go to 9000
      if(out) write(iw,9997) iter,nxpan0
      nvec=nxpan0-1
      if(nxpan0.gt.mxxpan) go to 700
  110 continue
c
c     ----- calculate w = h * v for new expansion vectors -----
c
c     parallel w = h * v, without storing augmented hessian (h)
c
      call ahpddi(nmos,ncor,nocc,nrot
     *,           opdm,tpdm,fcor,fval
     *,           lagn,irot,hd,buff
     *,           v(1,nxpan0),w(1,nxpan0))
c
c     ----- calculate new triangular part of interaction matrix -----
c
      dumij=zero
      do 120 iwks=1,nwks
  120 dumij=dumij+v(iwks,nxpan0)*w(iwks,nxpan0)
      ij=ia(nxpan0)+nxpan0
      aa(ij)=dumij
c
c     ----- calculate new band of interaction matrix -----
c
      if(nvec.eq.0) go to 200
c
      do 170 j=1,nvec
      dumij=zero
      do 160 iwks=1,nwks
  160 dumij=dumij+v(iwks,nxpan0)*w(iwks,j)
      ij=ia(nxpan0)+j
      aa(ij)=dumij
  170 continue
c
c     ----- solve (nxpan0*nxpan0) eigenvalue problem -----
c
  200 continue
      ndum=(nxpan0*(nxpan0+1))/2
      do 210 idum=1,ndum
  210 a(idum)=aa(idum)
      if(dbug) call prtri_f(a,nxpan0)
c
      call gldiag_f(nxpan0,nxpan0,nxpan0,a,wrk,eig,vec,ierr,iwrk)
c
      if(out) write(iw,9988) eig(1)
c
c     ----- form correction vectors -----
c
      do 310 iwks=1,nwks
  310 t(iwks)=zero
      part1=.true.
  320 continue
c
      eigk=eig(1)
      do 360 i=1,nxpan0
      aik=vec(i,1)
      if(part1) aik=-aik*eigk
      do 350 iwks=1,nwks
  350 t(iwks)=t(iwks)+aik*v(iwks,i)
  360 continue
c
      do 380 i=1,nxpan0
      do 380 iwks=1,nwks
      dum=v(iwks,i)
      v(iwks,i)=w(iwks,i)
  380 w(iwks,i)=dum
      if(.not.part1) go to 390
      part1=.false.
      go to 320
  390 continue
c
c     ----- check convergence -----
c
      cvg=zero
      cvged=.true.
      dum=zero
      do 410 iwks=1,nwks
  410 dum=dum+t(iwks)*t(iwks)
      dum= sqrt(dum)
      if(out) write(iw,9989) dum
      if(dum.gt.cvg)  cvg=dum
      cvged=cvged.and.(dum.lt.cvgtol)
      if(dbug) write(iw,9995) iter,cvg,eig(1)
      nvec=nxpan0
      if(cvged) go to 700
c
      if(iter.eq.1) go to 460
      eigk=eig(1)
      dum=zero
      do 430 iwks=1,nwks
      denom=eigk-hd(iwks)
      if( abs(denom).lt.tol) denom=tol
      t(iwks)=t(iwks)/denom
  430 dum=dum+t(iwks)*t(iwks)
      dum=one/ sqrt(dum)
      do 440 iwks=1,nwks
  440 t(iwks)=t(iwks)*dum
c
  460 continue
c
c     ----- orthogonalize correction vectors and expansion vectors -----
c     ----- update set of expansion vectors                        -----
c
      do 550 i=1,nxpan0
      dumik=zero
      do 530 iwks=1,nwks
  530 dumik=dumik+t(iwks)*v(iwks,i)
      do 540 iwks=1,nwks
  540 t(iwks)=t(iwks)-dumik*v(iwks,i)
  550 continue
c
      ivec = 0
      dum=zero
      do 610 iwks=1,nwks
  610 dum=dum+t(iwks)*t(iwks)
      if(dum.lt.thres) go to 670
      dum=one/ sqrt(dum)
      do 620 iwks=1,nwks
  620 t(iwks)=t(iwks)*dum
c
      ivec = 1
c
  670 if(out) write(iw,9991) ivec
c
      if(ivec.eq.0) write(iw,9990)
c
c     ----- end of cycle -----
c
      nxpan0 = nxpan0+1
      do 680 iwks=1,nwks
  680 v(iwks,nxpan0)=t(iwks)
      if(dbug) write(iw,9996) nxpan0,(iwks,v(iwks,nxpan0),iwks=1,nwks)
      go to 100
c
c     ----- re-orthonormalize expansion coefficient matrix -----
c
  700 continue
      dumij=zero
      do 710 k=1,nvec
  710 dumij=dumij+vec(k,1)*vec(k,1)
      dumij=one/ sqrt(dumij)
      do 740 k=1,nvec
  740 vec(k,1)=vec(k,1)*dumij
c
c     ----- get approximate or converged -ci- vectors -----
c
      part1=.true.
  800 continue
      do 810 iwks=1,nwks
  810 t(iwks)=zero
c
      do 830 ivec=1,nvec
      aik=vec(ivec,1)
      do 820 iwks=1,nwks
  820 t(iwks)=t(iwks)+aik*v(iwks,ivec)
  830 continue
c
      if(cvged) go to 900
c
c     ----- if .not.cvged, use vectors as new expansion vectors -----
c
      if(.not.part1) go to 870
      do 850 ivec=1,nvec
      do 850 iwks=1,nwks
  850 v(iwks,ivec)=w(iwks,ivec)
c
      if(dbug) write(iw,9996) kstat,(iwks,t(iwks),iwks=1,nwks)
      do 860 iwks=1,nwks
  860 w(iwks,1)=t(iwks)
      part1=.false.
      go to 800
c
  870 continue
      do 880 iwks=1,nwks
      v(iwks,1)=w(iwks,1)
  880 w(iwks,1)=t(iwks)
c
      aa(1)=eig(1)
      nxpan0=1
      ivec=1
      if(out) write(iw,9987)
      go to 110
c
c     ----- print final vectors ----
c
  900 continue
c     if(dbug) write(iw,9993)   eig(1)
c9993 format(/,1x,'first root eigenvalue  = ',f18.9,/,1x,10(1h-),
c    1 8x,6(1h-))
      ncoef=0
      do 910 iwks=1,nwks
      v(iwks,1)=t(iwks)
      dum=v(iwks,1)
      if( abs(dum).lt.prttol) go to 910
      ncoef=ncoef+1
      kcoef(ncoef)=iwks
      coefk(ncoef)=dum
      if(ncoef.lt.6) go to 910
      if(dbug) write(iw,9992) (kcoef(k),coefk(k),k=1,ncoef)
      ncoef=0
  910 continue
      if(ncoef.eq.0) go to 920
      if(dbug) write(iw,9992) (kcoef(k),coefk(k),k=1,ncoef)
      ncoef=0
  920 continue
c
      return
 9000 continue
      write(iw,9994) cvg, cvgtol
      return
 9998 format(/,' iter.    max.dev.    state energies ',/,
     1       '        state norm(d)                ')
 9997 format(' iteration ',i3,' with ',i3,' expansion vectors.')
 9996 format(' expansion vectors ',i3,/,(6(i5,f15.8)) )
 9995 format(i4  ,f12.8, f17.9)
 9994 format(' excessive number of iterations in -ntndvd-',
     1 ' during augmented hessian matrix diagonalization. stop',/,
     2 ' cvg = ',e12.4,' cvgtol = ',e12.4)
 9992 format(1x,6(i7,f14.7))
 9991 format(i3,' vector(s) added to expansion set.')
 9990 format(' no vectors added to the expansion set in -ntndvd- ',/,
     1 ' even though diagonalization not converged to requested',
     2 ' threshold.',/,' increase convergence threshold, in',/,
     3 ' namelist $newton - stop')
 9989 format(' convergence check for state  is = ',f15.8)
 9988 format(' first root  eigenvalue = ',f17.9)
 9987 format(' .... expansion vectors reset .... ')
      end
c*module masscf  *deck ntnlef
      subroutine ntnlef(v,b,e,irot,nrot,norb,norbs,out,sqcdf)
c
c     ----- b. lengsfield's empirical fudging -----
c
      implicit  REAL  (a-h,o-z)
      logical out
      dimension v(*),e(norbs,*),b(*),irot(norbs,*)
      common /iofile_f/ ir,iw,ip,ijko,ijkt,idaf,nav,ioda(950)
      parameter (zero=0.0d+00, pt5=0.5d+00,
     *           test=0.5d+00, test1=0.1d+00)
c
      testv =test
      testv1=test1
      testv2= sqrt(test)
      c1=v(1)
      if( abs(c1).gt.testv2) go to 340
      c1sq=c1**2
c
  300 continue
      c2sq=zero
      do 310 i=1,nrot
         c2=v(i+1)
         if( abs(c2).lt.testv1) go to 310
         c2sq=c2sq+c2**2
  310 continue
      if(out) write(iw,9994) c1sq,c2sq,testv1
      if(c1sq+c2sq.gt.testv) go to 320
      testv1=testv1*pt5
      if(out) write(iw,9993)
      go to 300
c
  320 continue
      v(1)= sign(testv2,v(1))
      scale= sqrt((c1sq+c2sq-testv)/c2sq)
      do 330 i=1,nrot
         c2=v(i+1)
         if( abs(c2).lt.testv1) go to 330
         v(i+1)=c2*scale
  330 continue
c
  340 continue
      if(v(1).gt.zero) go to 360
      do 350 i=1,nrot+1
         v(i)=-v(i)
  350 continue
c
  360 continue
      sqcdf=zero
      do 370 i=1,nrot
         dum=v(i+1)
         sqcdf=sqcdf+dum*dum
         b(i)=dum
  370 continue
      if(out) write(iw,9995) sqcdf
c
c     ----- construct rotation parameters in -e- -----
c
      do 420 ix=1,norb
         do 410 ig=1,norbs
            e(ig,ix)=zero
            ib=irot(ig,ix)
            if(ib.eq.0) go to 410
            val=b(ib)
            if(ig.gt.ix) val=-val
            e(ig,ix)=val
  410    continue
  420 continue
c
      return
 9993 format(' testv1 reduced by factor of 2. ')
 9994 format(' vector fixup used. c1sq = ',f10.8,' c2sq = ',f10.8,
     1 ' testv1 = ',f7.3)
 9995 format(' sqcdf = ',e20.4)
      end
c*module masscf  *deck fcoddi
      subroutine fcoddi(nmos,nocc,ncor,fcor,buff)
c
c ----------------------------------------------------------------------
c
c  mcscf and ci. called from trfmcx.
c  construct the 2-el terms of the core fock operator directly in the
c  mo basis from transformed integrals stored in the ddi arrays,
c  where core and active indices are subsets of the occupied mo range.
c
c  symbols:
c     nmos = number of molecular orbitals
c  (note nmos may not equal the number of basis functions)
c     nocc = number of occupied orbitals
c     ncor = number of core orbitals
c     fcor = core fock operator in the mo basis
c     buff = a message buffer for two-electron integrals
c
c  integrals need at least two core indices in the formula
c  fcor(ij) = sum_over_k{[2(ij|kk)-(ik|jk)]}, k core, i,j general.
c  fcor stored in triangular form.
c
c ----------------------------------------------------------------------
c
      implicit  REAL (a-h,o-z)
      parameter ( two = 2.0d+00 )
      parameter ( mxao=8192 )
       REAL  fcor(*),buff(*)
      integer ddi_np, ddi_me, a,b,ab
c
      integer         d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb
      logical         ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
      common /trfdms/ d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb,
     *                ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
c
c  pair-index initialized in tranddi
c
      common /ijpair/ ia(mxao)
c
      nvir = nmos - nocc
      nmtr = (nmos*nmos+nmos)/2
      notr = (nocc*nocc+nocc)/2
      nvtr = (nvir*nvir+nvir)/2
      nvsq = nvir*nvir
      call dcopy(nmtr,0.0d+00,0,fcor,1)
      call ddi_nproc(ddi_np, ddi_me)
c
c  (oo|oo) class
c
      call ddi_distrib(d_oooo,ddi_me,ilo,ihi,jlo,jhi)
      do i = 1, nocc
        do j = 1, i
          ijcol = ia(i) + j
          if ((ijcol.ge.jlo).and.(ijcol.le.jhi)) then
            call ddi_get(d_oooo,1,notr,ijcol,ijcol,buff)
            ij = ijcol
c
c  coulomb terms
c
            do k = 1, ncor
              kk = ia(k) + k
              fcor(ij) = fcor(ij) + two*buff(kk)
            end do
c
c  exchange terms
c
            if (j.le.ncor) then
              do k = 1, i
                ik = ia(i) + k
                jk = ia(max(j,k)) + min(j,k)
                fcor(ik) = fcor(ik) - buff(jk)
              end do
            end if
            if (i.ne.j) then
              if (i.le.ncor) then
                do k = 1, j
                  ik = ia(i) + k
                  jk = ia(max(j,k)) + min(j,k)
                  fcor(jk) = fcor(jk) - buff(ik)
                end do
              end if
            end if
          end if  ! local
        end do
      end do
c
c  (vo|oo) class
c
      call ddi_distrib(d_vooo,ddi_me,ilo,ihi,jlo,jhi)
c
c  coulomb terms
c
      do i = 1, ncor
        iicol = ia(i) + i
        do j = 1, nocc
          iijcol = (iicol-1)*nocc + j
          if ((iijcol.ge.jlo).and.(iijcol.le.jhi)) then
            call ddi_get(d_vooo,1,nvir,iijcol,iijcol,buff)
            do a = 1, nvir
              na = a + nocc
              ja = ia(na) + j
              fcor(ja) = fcor(ja) + two*buff(a)
            end do
          end if
        end do
      end do
c
c  exchange terms
c
      do i = 1, ncor
        do j = 1, nocc
          ijcol  = ia(max(i,j)) + min(i,j)
          ijicol = (ijcol-1)*nocc + i
          if ((ijicol.ge.jlo).and.(ijicol.le.jhi)) then
            call ddi_get(d_vooo,1,nvir,ijicol,ijicol,buff)
            do a = 1, nvir
              na = a + nocc
              ja = ia(na) + j
              fcor(ja) = fcor(ja) - buff(a)
            end do
          end if
        end do
      end do
c
c  (vv|cc) class - coulomb terms
c
      call ddi_distrib(d_vvoo,ddi_me,ilo,ihi,jlo,jhi)
      do i = 1, ncor
        iicol = ia(i) + i
        if ((iicol.ge.jlo).and.(iicol.le.jhi)) then
          call ddi_get(d_vvoo,1,nvtr,iicol,iicol,buff)
          do a = 1, nvir
            na  = a + nocc
            do b = 1, a
              nb  = b + nocc
              nab = ia(na) + nb
              ab  = ia(a) + b
              fcor(nab) = fcor(nab) + two*buff(ab)
            end do
          end do
        end if
      end do
c
c  (vc|vc) class - exchange terms
c
      call ddi_distrib(d_vovo,ddi_me,ilo,ihi,jlo,jhi)
      do i = 1, ncor
        iicol = ia(i) + i
        if ((iicol.ge.jlo).and.(iicol.le.jhi)) then
          call ddi_get(d_vovo,1,nvsq,iicol,iicol,buff)
          do a = 1, nvir
            na  = a + nocc
            do b = 1, a
              nb  = b + nocc
              nab = ia(na) + nb
              ab  = (a-1)*nvir + b
              fcor(nab) = fcor(nab) - buff(ab)
            end do
          end do
        end if
      end do
c
c  globally sum 2-el core fock matrix (+ sync)
c
      call ddi_gsumf( 2520, fcor, nmtr )
      return
      end
c*module masscf  *deck gldiag
      subroutine gldiag_f(ldvect,nvect,n,h,wrk,eig,vector,ierr,iwrk)
c
      implicit  REAL  (a-h,o-z)
c
      logical goparr,dskwrk,maswrk, maswrk_sv
c
      dimension h(*),wrk(n,8),eig(n),vector(ldvect,nvect),iwrk(n)
c
      common /iofile_f/ ir,iw,ip,ijk,ipk,idaf,nav,ioda(950)
      common /machsw/ kdiagg,icorfl,ixdr
      common /par   / me,master,nproc,ibtyp,iptim,goparr,dskwrk,maswrk
c
c     ----- general routine to diagonalize a symmetric matrix -----
c     if kdiag = 1, use evvrsp
c     100 added to kdiag forces diagonalising only on master and
c     broadcasting the results on slaves (useful for mixed node clusters
c     and/or for clusters with charges acrued by cpu time).
c
c           n      = dimension (order) of matrix to be solved
c           ldvect = leading dimension of vector
c           nvect  = number of vectors desired
c           h      = matrix to be diagonalized
c           wrk    = n*8 w.p. real words of scratch space
c           eig    = eigenvalues  (output)
c           vector = eigenvectors (output)
c           ierr   = error flag (output)
c           iwrk   = n integer words of scratch space
c
c        traditional runs with -kdiag- will have ldiag=0 and kdiag same.
c        adding 100 to kdiag before calling this will result in the
c        diagonalization occuring entirely on the master node.
c
      kdiag=mod(kdiagg,100)
      ldiag=kdiagg/100
c
      if(ldiag.eq.0.or.maswrk) then
         ierr = 0
c
c         ----- use steve elbert's routine -----
c
         if(kdiag.le.1 .or. kdiag.gt.3) then
            lenh = (n*n+n)/2
            korder =0
c
c           use maswrk to ignore errors unimportant in full-NR
c
            maswrk_sv = maswrk
            maswrk = .false.
            call evvrsp(iw,n,nvect,lenh,ldvect,h,wrk,iwrk,eig,vector
     *                 ,korder,ierr)
            maswrk = maswrk_sv 
         end if
      endif
c
c        broadcast the results
cgdf  goparr test not needed if masscf assumed parallel
c
      if(ldiag.ne.0.and.goparr) then
         call ddi_bcast(2421,'i',ierr,1,master)
         call ddi_bcast(2421,'f',eig,n,master)
         call ddi_bcast(2421,'f',vector,ldvect*nvect,master)
      endif
c
      return
      end
c
c*module masscf  *deck tftri
      subroutine tftri(h,f,t,wrk,m,n,ldt)
c
      implicit  REAL (a-h,o-z)
c
      dimension h(*),f(*),t(ldt,m),wrk(n)
c
      logical goparr,dskwrk,maswrk,nxt,parr
c
      common /par   / me,master,nproc,ibtyp,iptim,goparr,dskwrk,maswrk
c
      parameter (mxseq=150, mxrows=5)
      parameter (zero=0.0d+00, small=1.0d-11)
c
c     ----- transform the triangular matrix f using vectors t -----
c                      h = t-dagger * f * t
c     the order of the triangular matrices h and f are m and n.
c
c     ----- initialization for parallel work -----
c
      nxt = ibtyp.eq.1
      ipcount = me - 1
      next  = -1
      l2cnt = 0
      parr = goparr  .and.  n.gt.mxseq
c
      if(parr) then
         m2 = (m*m+m)/2
         call vclr(h,1,m2)
      end if
c
      ij = 0
      do 310 j = 1,m,mxrows
         jjmax = min(m,j+mxrows-1)
c
c     ----- go parallel! -----
c
         if(parr) then
            if (nxt) then
               l2cnt = l2cnt + 1
               if (l2cnt.gt.next) call ddi_dlbnext(next)
               if (next.ne.l2cnt) then
                  do 010 jj=j,jjmax
                     ij = ij + jj
  010             continue
                  go to 310
               end if
            else
               ipcount = ipcount + 1
               if (mod(ipcount,nproc).ne.0) then
                  do 020 jj=j,jjmax
                     ij = ij + jj
  020             continue
                  go to 310
               end if
            end if
         end if
c
c             first calculate t-dagger times -f-, a row at a time
c
         do 300 jj=j,jjmax
            ik = 0
            do 140 i = 1,n
               im1 = i-1
               dum = zero
               tdum = t(i,jj)
               if (im1.gt.0) then
                  do 100 k = 1,im1
                     ik = ik+1
                     wrk(k) = wrk(k)+f(ik)*tdum
                     dum = dum+f(ik)*t(k,jj)
  100             continue
               end if
               ik = ik+1
               wrk(i) = dum+f(ik)*tdum
  140       continue
c
c             then take that row times every column in -t-
c
            do 200 i = 1,jj
               ij = ij+1
               hij = ddot(n,t(1,i),1,wrk,1)
               if(abs(hij).lt.small) hij=zero
               h(ij)=hij
  200       continue
  300    continue
  310 continue
c
      if(parr) then
         call ddi_gsumf(520,h,m2)
         if(nxt) call ddi_dlbreset
      end if
c
      return
      end
c*module masscf  *deck prtri
      subroutine prtri_f(d,n)
c
      implicit  REAL (a-h,o-z)
c
      logical goparr,dskwrk,maswrk
c
      dimension d(*)
c
      common /iofile_f/ ir,iw,ip,is,ipk,idaf,nav,ioda(950)
      common /output_f/ nprint,itol,icut,normf,normp,nopk
      common /par   / me,master,nproc,ibtyp,iptim,goparr,dskwrk,maswrk
c
c     ----- print symmetric matrix -d- of dimension -n- -----
c
      if (maswrk) then
      max = 5
      if (nprint .eq. 6) max = 10
      mm1 = max-1
      do 120 i0=1,n,max
         il = min(n,i0+mm1)
         write(iw,9008)
         write(iw,9028) (i,i=i0,il)
         write(iw,9008)
         il = -1
         do 100 i=i0,n
            il=il+1
            j0=i0+(i*i-i)/2
            jl=j0+min(il,mm1)
            write(iw,9048) i,(d(j),j=j0,jl)
  100    continue
  120 continue
      end if
      return
 9008 format(1x)
 9028 format(6x,10(4x,i4,4x))
 9048 format(i5,1x,10f12.7)
      end
      subroutine ver_masscf(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/masscf.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
c*module masscf  *deck advanc
c     ---------------------------------------------
      subroutine advanc(con,nele,norb)
c     ---------------------------------------------
      implicit double precision(a-h,o-z)
      integer con(*)
c     
      if (con(nele).eq.norb) then  
         do 50 i=nele-1,1,-1
            if (con(i+1)-con(i).gt.1) then
               con(i) = con(i) + 1
               do 40 j=i+1,nele
                  con(j) = con(j-1) + 1
   40          continue
               return
            endif
   50    continue
      endif   
c     
         con(nele) = con(nele)+1
c     
      return
      end
c*module masscf  *deck rdci12
      subroutine rdci12(x2,ncore,m1,m2,m4,wk)
c
      implicit double precision(a-h,o-z)
c
      dimension x2(m4),wk(*)
c
      common /iofile_f/ ir,iw,ip,is,ipk,idaf,nav,ioda(950)
      logical goparr,dskwrk,maswrk
      common /par   / me,master,nproc,ibtyp,iptim,goparr,dskwrk,maswrk
      common /pcklab/ labsiz
c
c     ddi array handles
c
      integer         d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb
      logical         ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
      common /trfdms/ d_oooo,d_vooo,d_vvoo,d_vovo,d_vvvo,d_vvvv,
     *                d_ooooab,d_oooobb,d_voooab,d_voooba,d_vooobb,
     *                d_vvooab,d_vvooba,d_vvoobb,d_vovoab,d_vovobb,
     *                d_u,d_ub,d_e,d_eb,
     *                ndoooo,ndvooo,ndvvoo,ndvovo,ndvvvo,ndvvvv,ndcore,
     *                ndvvooba,ndvvooab,ndvvoobb,ndvovoab,ndvovobb,
     *                ndvoooba,ndvoooab,ndvooobb,ndooooab,ndoooobb
c
c     -- read 2 e- transformed integrals into replicated memory --
c     only integrals in the active space, between ncore and ncore+m1
c     are returned in x1 and x2 arrays.
c
      call vclr(x2,1,m4)
c
c     obtain the two electron integrals from distributed memory.
c
      call ddi_distrib(d_oooo,me,ilo,ihi,jlo,jhi)
      nact = m1
      nocc = nact + ncore
      notr = (nocc*nocc+nocc)/2
      do i = 1, nact
        in = i + ncore
        do j = 1, i
          jn = j + ncore
          ij = (i*i-i)/2 + j
          ijn = (in*in-in)/2 + jn
          if ((ijn.ge.jlo).and.(ijn.le.jhi)) then
            call ddi_get(d_oooo,1,notr,ijn,ijn,wk)
            do k = 1, nact
              kn = k + ncore
              do l = 1, k
               ln = l + ncore
                kl = (k*k-k)/2 + l
                if (ij.ge.kl) then
                  kln = (kn*kn-kn)/2 + ln
                  ijkl = (ij*ij-ij)/2 + kl
                  x2(ijkl) = wk(kln)
                end if
              end do
            end do
          end if ! local stripe
        end do ! j
      end do ! i
c
c     global sum also acts as a sync
c
      call ddi_gsumf(2500,x2,m4)
      return
      end
c*module masscf  *deck c1det
      subroutine c1det(moirp,lmolab,l0)
      dimension moirp(l0),lmolab(l0)
      data leta/4ha   /
c
c         force orbital symmetry assignment to c1 point group
c
      do i=1,l0
         moirp(i) = 1
         lmolab(i) = leta
      end do
      return
      end
c*module masscf  *deck detgrp
      subroutine detgrp(grpdet,labmo,lbabel,ptgrp,lbirrp,syirrp,
     *                  nsym,nirrp,l1,nact,ncorsv)
c
      implicit double precision (a-h,o-z)
c
      logical goparr,dskwrk,maswrk,abel
c
      parameter (mxsh=5000, mxgrps=13, mxatm=2000)
c
      dimension labmo(l1),lbabel(nact),lbirrp(12)
      integer   syirrp(12)
      dimension groups(mxgrps),nsyms(mxgrps),nirrps(mxgrps),
     *          isymrp(12,mxgrps)
      integer   symrep(12,mxgrps),symb
c
      common /iofile_f/ ir,iw,ip,ijk,ipk,idaf,nav,ioda(950)
      common /par   / me,master,nproc,ibtyp,iptim,goparr,dskwrk,maswrk
      common /symblk/ nirred,nsalc,nsalc2,nsalc3,nsafmo
      common /symmol/ group,complex,igroup,naxis,ilabmo,abel
      common /symqmt/ irplab(14),irpnum(14),irpdim(14),irpdeg(14)
      common /symtry_f/ mapshl(mxsh,48),mapctr(mxatm,48),
     *                t(432),invt(48),nt
c
      data groups/8hc1      ,8hci      ,8hcs      ,8hc2      ,
     *            8hc2v     ,8hc2h     ,8hd2      ,8hd2h     ,
     *            8hcinfv   ,8hdinfh   ,8hd4h     ,8hd4      ,
     *            8hc4v     /
      data nirrps/1,2,2,2,4,4,4,8,5,10,12,6,6/
      data nsyms /1,2,2,2,4,4,4,8,4, 8, 8,4,4/
c                        c1
      data  symrep(1,1)       /4ha   /
      data  isymrp(1,1)       /1/
c                        ci
      data (symrep(i,2),i=1,2)/4hag  ,4hau  /
      data (isymrp(i,2),i=1,2)/1,2/
c                        cs
      data (symrep(i,3),i=1,2)/4ha'  ,4ha'' /
      data (isymrp(i,3),i=1,2)/1,2/
c                        c2
      data (symrep(i,4),i=1,2)/4ha   ,4hb   /
      data (isymrp(i,4),i=1,2)/1,2/
c                        c2v
      data (symrep(i,5),i=1,4)/4ha1  ,4ha2  ,4hb1  ,4hb2  /
      data (isymrp(i,5),i=1,4)/1,2,3,4/
c                        c2h
      data (symrep(i,6),i=1,4)/4hag  ,4hbu  ,4hbg  ,4hau  /
      data (isymrp(i,6),i=1,4)/1,2,3,4/
c                        d2
      data (symrep(i,7),i=1,4)/4ha   ,4hb1  ,4hb2  ,4hb3  /
      data (isymrp(i,7),i=1,4)/1,2,3,4/
c                        d2h
      data (symrep(i,8),i=1,8)/4hag  ,4hb1g ,4hb2g ,4hb3g ,
     *                         4hau  ,4hb1u ,4hb2u ,4hb3u /
      data (isymrp(i,8),i=1,8)/1,2,3,4,5,6,7,8/
c
c           note that cinfv and dinfh don't work now
c
c                        cinfv
      data (symrep(i,9),i=1,5)/4hsig ,4hpix ,4hpiy ,4hdelx,4hdely/
      data (isymrp(i,9),i=1,5)/1,3,4,1,2/
c                        dinfh
      data (symrep(i,10),i=1,10)/4hsigg,4hsigu,4hpiux,4hpiuy,4hpigx,
     *                           4hpigy,4h dgx,4h dgy,4h dux,4h duy/
      data (isymrp(i,10),i=1,10)/1,6,8,7,3,4,1,2,6,5/
c                        d4h
c         michel's symmetry code generate egy before egx
      data (symrep(i,11),i=1,12)/4ha1g ,4ha2g ,4hb1g ,4hb2g ,
     *                           4ha1u ,4ha2u ,4hb1u ,4hb2u ,
     *                           4heg  ,4heg  ,4heu  ,4heu  /
      data (isymrp(i,11),i=1,12)/1,2,1,2, 5,6,5,6, 4,3,8,7/
c                        d4
      data (symrep(i,12),i=1,6) /4ha1  ,4ha2  ,4hb1  ,4hb2  ,
     *                           4he   ,4he   /
      data (isymrp(i,12),i=1,6) /1,2,1,2, 4,3/
c                        c4v
      data (symrep(i,13),i=1,6) /4ha1  ,4ha2  ,4hb1  ,4hb2  ,
     *                           4he   ,4he   /
      data (isymrp(i,13),i=1,6) /1,2,1,2, 3,4/
c
c     assign the orbitals a symmetry label -lbabel- under
c     the highest possible abelian subgroup.  only a
c     handful of the non-abelian groups will downshift.
c
c     -igroup- is a pointer into the following table, from $data:
c     data grp /c1   ,cs   ,ci   ,cn   ,s2n  ,cnh  ,
c    *          cnv  ,dn   ,dnh  ,dnd  ,cinfv,dinfh,t
c    *          th   ,td   ,o    ,oh   ,i    ,ih   /
c     -igrp- is a pointer into -groups- table, local to this routine:
c
      igrp=1
      if(igroup.eq.3) igrp=2
      if(igroup.eq.2) igrp=3
      if(igroup.eq.4  .and.  naxis.eq.2) igrp=4
      if(igroup.eq.7  .and.  naxis.eq.2) igrp=5
      if(igroup.eq.6  .and.  naxis.eq.2) igrp=6
      if(igroup.eq.8  .and.  naxis.eq.2) igrp=7
      if(igroup.eq.9  .and.  naxis.eq.2) igrp=8
      if(igroup.eq.6  .and.  naxis.eq.4) igrp=11
      if(igroup.eq.8  .and.  naxis.eq.4) igrp=12
      if(igroup.eq.7  .and.  naxis.eq.4) igrp=13
      if(nt.eq.1  .or.  ilabmo.eq.0) igrp=1
      if(grpdet.eq.groups(1)) igrp=1
c
      ptgrp= groups(igrp)
c
cgdf  dbg 06.03.08
c     hard to follow. nsym is passed in to be set but not used 
c     (for dimensioning or otherwise) in this routine. 
c     why, when it has been set elsewhere?
c     interestingly, the value of nsym in both cases ultimately 
c     depends on that of igroup in /symmol/, though the code 
c     yields nsym=2 in one case and nsym=1 in the other.
c     i wonder which is the more 'correct'?
c     commenting this out seems to work for masscf, though 
c     this should be left here for future reference?
c
c     nsym = nsyms(igrp)
c
      nirrp= nirrps(igrp)
      do 100 i=1,nirrp
         lbirrp(i) = isymrp(i,igrp)
         syirrp(i) = symrep(i,igrp)
  100 continue
c
c        all orbitals are the same symmetry in c1, or unsupported group.
c
      if(igrp.eq.1) then
         do 200 i=1,nact
            lbabel(i) = 1
  200    continue
         return
      end if
c
c        obtain active orbital symmetry labels in point group of $data
c
c     ----- map these labels onto the highest abelian subgroup -----
c
      nerr=0
      nerr2=0
      ipart=0
      irrep=0
c
      do 360 k=1,nact
         symb=labmo(k+ncorsv)
         do 310 irp=1,nirred
            if(symb.eq.irplab(irp)) then
               irrep = irp
               go to 320
            end if
  310    continue
c
         nerr=nerr+1
         lbabel(k)=0
         if(maswrk) write(iw,9050) ncorsv+k,symb
         go to 360
c
  320    continue
         idim = irpdim(irrep)
         if(idim.gt.1) then
            ipart=ipart+1
            ioff =ipart-1
         else
            ioff=0
         end if
         do 340 i=1,nirrp
            if(symb.eq.symrep(i,igrp)) then
               lbabel(k)=isymrp(i+ioff,igrp)
               if(ipart.eq.idim) ipart=0
               go to 360
            end if
  340    continue
c
         nerr2=nerr2+1
         if(maswrk) write(iw,9055) k,symb,groups(igrp)
         lbabel(k)=0
c
  360 continue
c
      if(nerr2.gt.0) then
         if(maswrk) write(iw,*) 'confusion with groups in -detgrp-'
         call abrt
      end if
c
      return
c
 9050 format(1x,'mo=',i5,' has illegal symmetry label ',a4)
 9055 format(1x,'mo=',i5,' has a symmetry label ',a4,
     *          ' unknown in group ',a8)
      end
c*module masscf  *deck wtdm12
      subroutine wtdm12(dm1,dm2,lbabel,
     *                  m1,m2,m4,wrk,nocc2,ncore,cutoff)
c
      implicit double precision (a-h,o-z)
c
      parameter (mxao=8192)
c
      logical ieqj,keql,goparr,dskwrk,maswrk
c
      dimension dm1(m2),dm2(m4),lbabel(m1),wrk(nocc2)
      dimension mult8(8),lkupsm(64)
c
      common /ijpair/ ia(mxao)
      common /iofile_f/ ir,iw,ip,is,ijkt,idaf,nav,ioda(950)
      common /par   / me,master,nproc,ibtyp,iptim,goparr,dskwrk,maswrk
c
      parameter (half=0.5d+00, two=2.0d+00)
c
      data mult8/0,8,16,24,32,40,48,56/
      data lkupsm/1,2,3,4,5,6,7,8,
     *            2,1,4,3,6,5,8,7,
     *            3,4,1,2,7,8,5,6,
     *            4,3,2,1,8,7,6,5,
     *            5,6,7,8,1,2,3,4,
     *            6,5,8,7,2,1,4,3,
     *            7,8,5,6,3,4,1,2,
     *            8,7,6,5,4,3,2,1/
c
      thrsh = 1.0d+01*cutoff
c
      do 50 i=1,m1
         if(lbabel(i).eq.0) then
            ibad = i+ncore
            if(maswrk) write(iw,9000) ibad
            call abrt
         end if
   50 continue
c
      call dscal(m2,     half,dm1,1)
      call dscal(m4,half*half,dm2,1)
c
      small = 1.0d-07
      nerr = 0
      ij = 0
      do 110 i=1,m1
         isym = lbabel(i)
         do 100 j=1,i
            ij = ij+1
            ijmul = mult8(isym)+lbabel(j)
            ijsym = lkupsm(ijmul)
            if(ijsym.ne.1) then
               if(abs(dm1(ij)).lt.thrsh) then
                  dm1(ij) = 0.0d+00
               else
                  ibad = i+ncore
                  jbad = j+ncore
                  if(maswrk) write(iw,9010) ibad,jbad,dm1(ij)
                  if(maswrk) write(iw,9030)
                  call abrt
               end if
            end if
  100    continue
         dm1(ij) = dm1(ij) + dm1(ij)
         if(dm1(ij).lt.small) then
            if(maswrk) write(iw,9040) i,dm1(ij)
            nerr=nerr+1
         end if
  110 continue
c
      if(nerr.gt.0) then
         if(maswrk) write(iw,*) 'check your active space carefully.'
         if(maswrk) write(iw,*) 'the 1st order density matrix is:'
         call prtri(dm1,m1)
         call abrt
      end if
c
cjmht - n was uninitialised. Not sure if this the right place to do it though.
      n=0
      do 280 i = 1,m1
         isym = lbabel(i)
         do 260 j = 1,i
            ieqj = i.eq.j
            ijmul = mult8(isym)+lbabel(j)
            ijsym = lkupsm(ijmul)
            do 240 k = 1,i
               lmax = k
               if(k.eq.i) lmax = j
               ijkmul = mult8(ijsym)+lbabel(k)
               ijksym = lkupsm(ijkmul)
               do 220 l = 1,lmax
                  keql=k.eq.l
                  n = n+1
                  val = dm2(n)
c
                  if(ieqj)                val=val+val
                  if(keql)                val=val+val
                  if(i.eq.k .and. j.eq.l) val=val+val

cgdf  10.05.07    keep symmetrized dm2
                  if (abs(val).lt.cutoff) then
                    dm2(n) = 0.0d+00
                  else 
                    dm2(n) = val
                  end if

                  if(abs(val).lt.cutoff) go to 220
c
c      only totally symmetric direct product should be nonzero elements
c
                  lsym = lbabel(l)
                  if(lsym.ne.ijksym) then
                     if(abs(val).lt.thrsh) go to 220
                     ibad = i+ncore
                     jbad = j+ncore
                     kbad = k+ncore
                     lbad = l+ncore
                     if(maswrk) write(iw,9020) ibad,jbad,kbad,lbad,val
                     if(maswrk) write(iw,9030)
                     call abrt
                  end if
  220          continue
  240       continue
  260    continue
  280 continue
c
cgdf  keep this
c     generate mo density over all orbitals, including core
c
c     call vclr(wrk,1,nocc2)
c     ii = 0
c     do 300 i=1,ncore
c        ii = ii+i
c        wrk(ii) = two
c 300 continue
c     do 320 i=1,m1
c        iv = ia(i)
c        ic = ia(i+ncore)
c        do 310 j=1,i
c            ijv = iv + j
c            ijc = ic + j + ncore
c            wrk(ijc) = dm1(ijv)
c 310    continue
c 320 continue
c
      return
c
 9000 format(1x,'unable to sift density matrix, orbital',i5,
     *          ' has unknown symmetry.')
 9010 format(/1x,'inaccurate 1st order density matrix element found,'/
     *       1x,'gamma(',2i5,')=',e20.10,' found, it should be zero'/
     *       1x,'by symmetry.')
 9020 format(/1x,'inaccurate 2nd order density matrix element found,'/
     *       1x,'gamma(',4i5,')=',e20.10,' found, it should be zero'/
     *       1x,'by symmetry.')
 9030 format(/1x,'loss of symmetry in the density matrix may be due to'/
     *       1x,'    unsymmetrical orbitals: check $vec group,'/
     *       1x,'         adjust $guess tolz=1.0d-5 tole=1.0d-04'/
     *       1x,'    or, unsymmetrical ci root: $det cvgtol=5.0d-06')
 9040 format(1x,'***** error: active orbital',i3,
     *          ' has very small occupation number=',1p,e13.6)
      end
c*module masscf  *deck binom6
c     ------------------------
      subroutine binom6(ifa,n)
c     ------------------------
c
      implicit double precision(a-h,o-z)
      integer ifa(0:n,0:n)
c
c     returns all binomial numbers (i,j) for i=0,n and j=0,i in fa .
c     the binomial number (i,j) is stored in ifa(i,j)
c
      do 13 ii=0,n
         ifa(ii,0)  = 1
         ifa(ii,ii) = 1
   13 continue
c
      do 113 iy = 1, n
         do 114 ix = 1, (iy-1)
            ifa(iy,ix) = ifa(iy-1,ix-1) + ifa(iy-1,ix)
  114    continue
  113 continue
c
      return
      end
c
c*module masscf  *deck tran
c     ------------------------------------------------------
      subroutine tran_f(ci,nci,maxp,ef,ip,ec,kst)
c     ------------------------------------------------------
      implicit double precision(a-h,o-z)
      dimension ci(nci,ip),ef(maxp,kst),ec(*)
c
      do 14 ii=1,nci
         do 16 jj=1,kst
            ec(jj) = 0.0d+00
            do 18 kk=1,ip
               ec(jj) = ec(jj) + ci(ii,kk)*ef(kk,jj)
   18       continue
   16    continue
         do 17 ki=1,kst
            ci(ii,ki) = ec(ki)
   17    continue
   14 continue
c
      return
      end
c
c*module masscf  *deck mosypr
c     -----------------------------------
      subroutine mosypr(lmolab,ncor,nact)
c     -----------------------------------
      implicit double precision(a-h,o-z)
      dimension lmolab(ncor+nact)
      common /iofile_f/ ir,iw,ip,is,ijkt,idaf,nav,ioda(950)
c
      if(ncor.gt.0) write(iw,9070) (lmolab(i),i=1,ncor)
      if(nact.gt.0) write(iw,9080) (lmolab(i+ncor),i=1,nact)
c
 9070 format(/1x,'    core=',10(1x,a4,1x)/(10x,10(1x,a4,1x)))
 9080 format(/1x,'  active=',10(1x,a4,1x)/(10x,10(1x,a4,1x)))
c
      return
      end
c
c*module masscf  *deck gajasw
c     ------------------------------------
      subroutine gajasw(lmoirp,num,grpdet)
c     ------------------------------------
      implicit double precision(a-h,o-z)
      dimension lmoirp(num)
      data c2h,d2,d2h/8hc2h     ,8hd2      ,8hd2h     /
c
c        note that the daf record that saves the orbital labels
c        for the ci code is private to the ci code, so this
c        translation does not affect anything else.
c
c        see routine symbol for gamess' assignment of integers
c        see routine gtab for jakal's desired labels
c
c        the orbital symmetry code in gamess assigns c2h orbitals
c        by the following: 1,2,3,4 = ag,au,bu,bg.  however, the
c        the determinant code wants the order 1,2,3,4=ag,bg,bu,au
c
c
      if(grpdet.eq.c2h) then
         do i=1,num
            modi=lmoirp(i)
            if (lmoirp(i).eq.2) modi=4
            if (lmoirp(i).eq.4) modi=2
            lmoirp(i)=modi
         end do
      end if
c        the orbital symmetry code in gamess assigns d2 orbitals
c        by the following: 1,2,3,4 = a,b1,b3,b2.  however, the
c        the determinant code wants the order 1,2,3,4=a,b1,b2,b3
c
      if(grpdet.eq.d2) then
         do i=1,num
            modi=lmoirp(i)
            if (lmoirp(i).eq.3) modi=4
            if (lmoirp(i).eq.4) modi=3
            lmoirp(i)=modi
         end do
      end if
c
c        the orbital symmetry code in gamess assigns d2h orbitals
c        by: 1,2,3,4,5,6,7,8 = ag, au,b3u,b3g,b1g,b1u,b2u,b2g
c        we need 1,2,3,...,8 = ag,b1g,b2g,b3g,au ,b1u,b2u,b3u
c
      if(grpdet.eq.d2h) then
         do i=1,num
            modi=lmoirp(i)
            if (lmoirp(i).eq.2) modi=5
            if (lmoirp(i).eq.3) modi=8
            if (lmoirp(i).eq.5) modi=2
            if (lmoirp(i).eq.8) modi=3
            lmoirp(i)=modi
         end do
      end if
c
      return
      end
c
c*module masscf  *deck gtab
c     -----------------------------------------------------
      subroutine gtab(idsym,isym1,itab,iele,ista,iscr,icha)
c     -----------------------------------------------------
c
c     routine to return table such that i x itab(i) = isym1
c     where i is an irreducible representation.
c     idsym  specifies the point group.
c     isym1  desired symmetry
c
c     convention for idsym,isym1, and itab
c
c     point group  idsym  irred rep isym1  sym operations used
c   -----------------------------------------------------------
c        ci          1       ag       1        i
c                            au       2
c
c        cs          1       a'       1      (sigma)h
c                            a''      2
c
c        c2          1       a        1       c2
c                            b        2
c
c        d2          2       a        1       c2(z)
c                            b1       2       c2(y)
c                            b2       3
c                            b3       4
c
c        c2v         2       a1       1       c2
c                            a2       2       (sigma)v(xz)
c                            b1       3
c                            b2       4
c
c        c2h         2       ag       1       i
c                            bg       2       (sigma)h
c                            bu       3
c                            au       4
c
c        d2h         3       ag       1       (sigma)(xy)
c                            b1g      2       (sigma)(xz)
c                            b2g      3       (sigma)(yz)
c                            b3g      4
c                            au       5
c                            b1u      6
c                            b2u      7
c                            b3u      8
c
c
      implicit double precision(a-h,o-z)
      dimension iele(3),ista(3),icha(34)
      dimension iscr(3)
      dimension itab(*)
      call getdata(iele,ista,icha)
c      data (iele(i),i=1,3) /2,4,8/
c      data (ista(i),i=1,3) /1,3,11/
c      data (icha(i),i=1,34) /1,-1,1,1,1,-1,-1,1,-1,-1,
c     *   1,1,1,1,-1,-1,-1,1,-1,-1,-1,1,-1,-1,-1,-1,1,1,
c     *   1,-1,1,1,1,-1/
c
      ist = ista(idsym)
      iel = iele(idsym)
      call gtab1(icha(ist),iel,idsym,isym1,itab,iscr)
      return
      end
c
c*module masscf  *deck gtab1
c     ----------------------------------------------------
      subroutine gtab1(icha,iel,idi,isym1,itab,iscr)
c     ----------------------------------------------------
      implicit double precision(a-h,o-z)
      dimension iscr(3)
      dimension icha(idi,iel)
      dimension itab(iel)
c
      do 34 ii=1,iel
         do 45 jj=1,iel
            do 77 kk=1,idi
               iscr(kk) = icha(kk,ii)*icha(kk,jj)
               if (iscr(kk).ne.icha(kk,isym1)) goto 45
   77       continue
            itab(ii) = jj
            goto 34
   45    continue
   34 continue
c
      return
      end
c
c*module masscf  *deck gmul
c     -------------------------------------------------
      subroutine gmul(idsym,imul,iele,ista,iscr,icha)
c     -------------------------------------------------
c
c     routine to return multiplication table ixj = imul(i,j)
c     where i,j are irreducible representations.
c     idsym  specifies the point group.
c
c     convention for idsym,i,j and imul
c
c     point group  idsym  irred rep  i,j  sym operation used
c   -----------------------------------------------------------
c        ci          1       ag       1        i
c                            au       2
c
c        cs          1       a'       1      (sigma)h
c                            a''      2
c
c        c2          1       a        1       c2
c                            b        2
c
c        d2          2       a        1       c2(z)
c                            b1       2       c2(y)
c                            b2       3
c                            b3       4
c
c        c2v         2       a1       1       c2
c                            a2       2       (sigma)v(xz)
c                            b1       3
c                            b2       4
c
c        c2h         2       ag       1       i
c                            bg       2       (sigma)h
c                            bu       3
c                            au       4
c
c        d2h         3       ag       1       (sigma)(xy)
c                            b1g      2       (sigma)(xz)
c                            b2g      3       (sigma)(yz)
c                            b3g      4
c                            au       5
c                            b1u      6
c                            b2u      7
c                            b3u      8
c
c
      implicit double precision(a-h,o-z)
      dimension iele(3),ista(3),icha(34)
      dimension iscr(3)
      dimension imul(*)
      call getdata(iele,ista,icha)
c      data (iele(i),i=1,3) /2,4,8/
c      data (ista(i),i=1,3) /1,3,11/
c      data (icha(i),i=1,34) /1,-1,1,1,1,-1,-1,1,-1,-1,
c     *   1,1,1,1,-1,-1,-1,1,-1,-1,-1,1,-1,-1,-1,-1,1,1,
c     *   1,-1,1,1,1,-1/
c
      ist = ista(idsym)
      iel = iele(idsym)
      call gmul1(icha(ist),iel,idsym,imul,iscr)
      return
      end
c
c*module masscf  *deck mul1
c     ----------------------------------------------------
      subroutine gmul1(icha,iel,idi,imul,iscr)
c     ----------------------------------------------------
      implicit double precision(a-h,o-z)
      dimension iscr(idi)
      dimension icha(idi,iel)
      dimension imul(iel,iel)
c
      do 34 ii=1,iel
         do 45 jj=1,iel
            do 77 kk=1,idi
               iscr(kk) = icha(kk,ii)*icha(kk,jj)
   77       continue
            do 88 kl=1,iel
               do 99 lk=1,idi
                  if (iscr(lk).ne.icha(lk,kl)) goto 88
   99          continue
               imul(ii,jj) = kl
               goto 45
   88       continue
   45    continue
   34 continue
c
      return
      end
c
c*module masscf  *deck getsym1
c     -------------------------------------------------
      subroutine getsym1(iw,icon,nact,nele,ibo,idsym,isym,
     *    iele,ista,iscr,icha)
c     -------------------------------------------------
c
c     routine to return symmetry for a single spin space function.
c     icon(i) contains orbital occupied by electron i.
c     nact    no. of orbitals.
c     nele    no. of electrons.
c     ibo(i) contains symmetry of orbital i.
c     idsym  specifies the point group.
c     isym   returns the symmetry(irreducible rep) of the icon.
c
c     convention for ibo, idsym and isym.
c
c     point group  idsym  irred rep  isym  sym operation used
c   -----------------------------------------------------------
c        ci          1       ag       1        i
c                            au       2
c
c        cs          1       a'       1      (sigma)h
c                            a''      2
c
c        c2          1       a        1       c2
c                            b        2
c
c        d2          2       a        1       c2(z)
c                            b1       2       c2(y)
c                            b2       3
c                            b3       4
c
c        c2v         2       a1       1       c2
c                            a2       2       (sigma)v(xz)
c                            b1       3
c                            b2       4
c
c        c2h         2       ag       1       i
c                            bg       2       (sigma)h
c                            bu       3
c                            au       4
c
c        d2h         3       ag       1       (sigma)(xy)
c                            b1g      2       (sigma)(xz)
c                            b2g      3       (sigma)(yz)
c                            b3g      4
c                            au       5
c                            b1u      6
c                            b2u      7
c                            b3u      8
c
c
      implicit double precision(a-h,o-z)
      dimension iele(3),ista(3),icha(34),iscr(3)
      dimension icon(nele),ibo(nact)
      call getdata(iele,ista,icha)
c
      ist = ista(idsym)
      iel = iele(idsym) 
      call sym(iw,icon,nact,nele,ibo,icha(ist),idsym,iel,isym,iscr)
      return
      end
c
c*module masscf  *deck sym
c     ---------------------------------------------------------
      subroutine sym(iw,icon,nact,nele,ibo,icha,idi,iel,isym,iscr)
c     ---------------------------------------------------------
      implicit double precision(a-h,o-z)
      dimension ibo(nact),icon(nele)
      dimension iscr(3)
      dimension icha(idi,iel)
c
      do 7 kk=1,idi
         iscr(kk) = 1
    7 continue
      do 13 ii=1,nele
         ia = icon(ii)
         do 20 jj=1,idi
            iscr(jj) = iscr(jj)*icha(jj,ibo(ia))
   20    continue
   13 continue
c
      do 56 ii=1,iel
         do 89 jj=1,idi
            if (iscr(jj).ne.icha(jj,ii)) goto 56
   89    continue
         isym = ii
         return
   56 continue
c
      write(iw,*) 'element not identified'
      return
      end
c
c*module masscf  *deck getdata
c     ----------------------------------
      subroutine getdata(iele,ista,icha)
c     ----------------------------------
      implicit double precision(a-h,o-z)
      dimension iele(3),ista(3),icha(34)
      iele(1) = 2
      iele(2) = 4
      iele(3) = 8
c
      ista(1) = 1
      ista(2) = 3
      ista(3) = 11
c
      icha(1) = 1
      icha(2) = -1
      icha(3) = 1
      icha(4) = 1
      icha(5) = 1
      icha(6) = -1
      icha(7) = -1
      icha(8) = 1
      icha(9) = -1
      icha(10) = -1
      icha(11) = 1
      icha(12) = 1
      icha(13) = 1
      icha(14) = 1
      icha(15) = -1
      icha(16) = -1
      icha(17) = -1
      icha(18) = 1
      icha(19) = -1
      icha(20) = -1
      icha(21) = -1
      icha(22) = 1
      icha(23) = -1
      icha(24) = -1
      icha(25) = -1
      icha(26) = -1
      icha(27) = 1
      icha(28) = 1
      icha(29) = 1
      icha(30) = -1
      icha(31) = 1
      icha(32) = 1
      icha(33) = 1
      icha(34) = -1
      return
      end
c
c*module masscf  *deck mempri
c    ---------------------------------------------------------------
      subroutine mempri(ifa,na,nb,nact,nsym,iprmem)
c    ---------------------------------------------------------------
      implicit double precision(a-h,o-z)
      dimension ifa(0:nact,0:nact)
      nalp = ifa(nact,na)
      nblp = ifa(nact,nb)
      iprmem = 3*na + 43 + nalp*3 + nblp*3 + (nsym+1)*2 +
     *       nsym*3 + nsym*nsym
      return
      end
c
c*module masscf  *deck prici1
c    ---------------------------------------------------------------
      subroutine prici1(iw,ifa,na,nb,ncor,norb,ci,nci,iob,
     *                  iop,crit,num,idsym,isym1,nsym,iwrk,imem)
c    ---------------------------------------------------------------
      implicit double precision(a-h,o-z)
      dimension ifa(0:norb-ncor,0:norb-ncor),ci(nci)
      dimension iwrk(imem)
      dimension iob(norb-ncor)
      character*102 cona,conb
c
      call prici2(iw,ifa,na,nb,ncor,norb,ci,nci,iwrk(1),iwrk(na+1),
     *        cona,conb,iop,crit,num,iob,iwrk(2*na+1),imem-2*na,
     *       idsym,isym1,nsym)
      return
      end
c
c*module masscf  *deck prici2
c     -----------------------------------------------------------
      subroutine prici2(iw,ifa,na,nb,ncor,norb,ci,nci,iacon,ibcon,
     *                 cona,conb,iop,crit,num,iob,isyd,msyd,
     *            idsym,isym1,nsym)
c     -----------------------------------------------------------
      implicit double precision(a-h,o-z)
      logical goparr,dskwrk,maswrk
      dimension ifa(0:norb-ncor,0:norb-ncor),ci(*)
      dimension iacon(na),ibcon(na)
      dimension isyd(msyd),iob(norb-ncor)
      common /par   / me,master,nproc,ibtyp,iptim,goparr,dskwrk,maswrk
      character*102 cona,conb
c
c    this subroutine prints out required part of the determinantal
c    wavefunction specified by the coefficients in ci.
c
c   should be compiled with the aldec ci code as it needs the subroutine
c   advanc to run properly.
c
c    ifa contains binomial coefficients, should be returned intact
c    from subroutine detci
c    na, nb are numbers of active alpha and beta electrons respectively
c    ncor is number of core orbitals
c    norb is total number of orbitals
c    ci contains the ci coefficients, this is somewhat destroyed, so
c    your best bet is to copy the vectors.  if you can do the ci
c    in the first place then you have enough spare space to copy all
c    vectors, trust me.  note that you need the space to store a.b in
c    a ci.
c    iacon, ibcon are scratch integer arrays
c    cona, conb are characters.  at the moment it is dimensioned
c    for a maximum of 100 active orbitals.  if anytime soon someone
c    does a bigger ci then you have to do character*(nact+2) where
c    nact is number of active orbitals.
c    iop is a choice paramter
c      iop=1 prints out the largest (num) ci coefs with determinants.
c      iop=2 prints out all dets with ci coeff larger than crit
c    crit and num are explained above.
c    isyd = integer array with the symmetry information.  this is
c    obtained with subroutine symwrk where isyd contains all the
c    arrays consecutively in one big one.  one can also use the
c    integer array returned from detci but starting at 'isst' where
c    isst is returned from memci, see memci for more details.
c    nsym = 2**(idsym) where idsym determines the point group, see
c    symwrk.f, subroutine gtab for convention.  nsym = total number
c    of irreducible representations.
c    nalp,nblp are numbers of alpha and beta space functions
c
      nact = norb - ncor
      if(nact.gt.100) then
         if(maswrk) write(iw,*)
     *      'prici2: too many active orbitals to print ci vector'
         return
      end if
      nalp = ifa(nact,na)
      nblp = ifa(nact,nb)
c
      iz0 = 0
      iz1 = iz0 + (na+43)
      iz2 = iz1 + nalp
      iz3 = iz2 + nblp
      iz4 = iz3 + nsym
      iz5 = iz4 + nsym
      iz6 = iz5 + nsym
      iz7 = iz6 + nsym*nsym
      iz8 = iz7 + nalp
      iz9 = iz8 + nblp
      iz10 = iz9 + nsym+1
      iz11 = iz10 + nsym+1
      iz12 = iz11 + nalp
      iztot = iz12 + nblp
c
      if (msyd.lt.iztot) then
         if(maswrk) write(iw,*) 'not enough memory for printing'
         call abrt
      endif
c
      call symwrk(iw,iob,nact,na,nb,idsym,isym1,nsym,nalp,nblp,
     *      isyd(iz0+1),
     *     isyd(iz1+1),isyd(iz2+1),isyd(iz3+1),isyd(iz4+1),
     *     isyd(iz5+1),
     *     isyd(iz6+1),isyd(iz7+1),isyd(iz8+1),isyd(iz9+1),
     *     isyd(iz10+1),
     *     isyd(iz11+1),isyd(iz12+1))
c
      nact = norb-ncor
      do ii=1,nact+2
         cona(ii:ii) = ' '
         conb(ii:ii) = ' '
      enddo
c
      if (iop.eq.1) then
c
c  set up the table
c
         ia = (nact+2)/2 - 2
         if (ia.le.0) ia = 1
         cona(ia:ia+4) = 'alpha'
         conb(ia:ia+4) = 'beta '
         if(maswrk) write(iw,'(4a)') cona(1:nact+2),'|',
     *                               conb(1:nact+2),'| coefficient'
         do 45 ii=1,nact+2
            cona(ii:ii) = '-'
   45    continue
         if(maswrk) write(iw,'(4a)') cona(1:nact+2),'|',
     *                               cona(1:nact+2),'|------------'
c
      do 3000 kjk=1,num
c
         ici = 0
         ipos = -1
         pmax = 0.0d+00
c
         do 413 ijk=1,nalp
c   do 313 kji=1,nblp
         isa1 = isyd(iz1 + ijk)
            do 313 kji = isyd(iz10 + isa1),isyd(iz10 + isa1 + 1)-1
               nend = isyd(iz12 + kji)
c
               ici = ici + 1
               if (abs(ci(ici)).gt.pmax) then
                  inda = ijk
                  indb = nend
                  ipos = ici
                  pmax = abs(ci(ici))
               endif
  313       continue
  413    continue
         if (ipos.eq.-1) goto 3000
c
c   now to print out the determinant
c
      do 50 ii=1,na
         iacon(ii) = ii
   50 continue
      do 40 ii=1,nb
         ibcon(ii) = ii
   40 continue
      do 67 ii=1,inda-1
         call advanc(iacon,na,nact)
   67 continue
      do 77 ii=1,indb-1
         call advanc(ibcon,nb,nact)
   77 continue
c
      cona(1:1) = ' '
      conb(1:1) = ' '
      do ii=2,nact+1
         cona(ii:ii) = '0'
         conb(ii:ii) = '0'
      enddo
c
      do 82 ii=1,na
         cona(iacon(ii)+1:iacon(ii)+1) = '1'
   82 continue
      do 92 ii=1,nb
         conb(ibcon(ii)+1:ibcon(ii)+1) = '1'
   92 continue
c
      cona(nact+2:nact+2) = ' '
      conb(nact+2:nact+2) = ' '
      if(maswrk) write(iw,'(4a,f10.7)') cona(1:nact+2),'|',
     *                                  conb(1:nact+2),'|  ',ci(ipos)
      ci(ipos) = 0.0d+00
c
 3000 continue
c
      else
c
c  set up the table
c
         ia = (nact+2)/2 - 2
         if (ia.le.0) ia = 1
         cona(ia:ia+4) = 'alpha'
         conb(ia:ia+4) = 'beta '
         if(maswrk) write(iw,'(4a)') cona(1:nact+2),'|',
     *                               conb(1:nact+2),'| coefficient'
         do 47 ii=1,nact+2
            cona(ii:ii) = '-'
   47    continue
         if(maswrk) write(iw,'(4a)') cona(1:nact+2),'|',
     *                               cona(1:nact+2),'|------------'
c
      do 4000 kjk=1,nci
c
         ici = 0
         do 113 ii=1,na
            iacon(ii) = ii
  113    continue
         pmax = 0.0d+00
c
         do 415 ijk=1,nalp
            isa1 = isyd(iz1 + ijk)
c
            do 18 ii=1,nb
               ibcon(ii) = ii
   18       continue
c
            do 315 kji = isyd(iz10 + isa1),isyd(iz10+isa1+1)-1
               nend = isyd(iz12 + kji)
c
               ici = ici + 1
               if (abs(ci(ici)).gt.pmax) then
                  inda = ijk
                  indb = nend
                  ipos = ici
                  pmax = abs(ci(ici))
               endif
c
  315       continue
  415    continue
c
c  check if is bigger than crit
c
      if (abs(ci(ipos)).ge.crit) then
c
c   now to print out the determinant
c
      do 150 ii=1,na
         iacon(ii) = ii
  150 continue
      do 140 ii=1,nb
         ibcon(ii) = ii
  140 continue
      do 167 ii=1,inda-1
         call advanc(iacon,na,nact)
  167 continue
      do 177 ii=1,indb-1
         call advanc(ibcon,nb,nact)
  177 continue
c
      cona(1:1) = ' '
      conb(1:1) = ' '
      do ii=2,nact+1
         cona(ii:ii) = '0'
         conb(ii:ii) = '0'
      enddo
c
      do 182 ii=1,na
         cona(iacon(ii)+1:iacon(ii)+1) = '1'
  182 continue
      do 192 ii=1,nb
         conb(ibcon(ii)+1:ibcon(ii)+1) = '1'
  192 continue
c
      cona(nact+2:nact+2) = ' '
      conb(nact+2:nact+2) = ' '
      if(maswrk) write(iw,'(4a,f10.7)') cona(1:nact+2),'|',
     *                                  conb(1:nact+2),'|  ',ci(ipos)
      ci(ipos) = 0.0d+00
c
      goto 4000
      endif
      return
c
 4000 continue
c
      endif
c
      return
      end
c
c*module masscf  *deck rede00
c     ---------------------------------------------------
      subroutine rede00(iacon1,iacon2,na,ia,igel,jj,iper)
c     ---------------------------------------------------
      implicit double precision(a-h,o-z)
      dimension iacon1(na),iacon2(na)
c
      if (igel.ge.ia) then
c
         do 100 ii=1,(ia-1)
            iacon2(ii) = iacon1(ii)
  100    continue
         do 200 ii=ia,(igel-1)
            iacon2(ii) = iacon1(ii+1)
  200    continue
         iacon2(igel) = jj
         do 300 ii=igel+1,na
            iacon2(ii) = iacon1(ii)
  300    continue
         iper = igel-ia
c
      else
c
         do 500 ii=1,igel
            iacon2(ii) = iacon1(ii)
  500    continue
         iacon2(igel+1) = jj
         do 600 ii=igel+2,ia
            iacon2(ii) = iacon1(ii-1)
  600    continue
         do 700 ii=ia+1,na
            iacon2(ii) = iacon1(ii)
  700    continue
         iper = (ia-igel-1)
c
      endif
c
      return
      end
c*module masscf  *deck stfase
      subroutine stfase(a,lda,n,m)
      implicit double precision (a-h,o-z)
      parameter (zero=0.0d+00)
      dimension a(lda,m)
c
c        set the phase of each column of a matrix so the largest
c        element is positive
c
      do 140 i = 1,m
         large = idamax(n,a(1,i),1)
         if(large.le.0) large=1
         if(large.gt.n) large=1
         if (a(large,i) .lt. zero) then
            do 120 j = 1,n
               a(j,i) = -a(j,i)
  120       continue
         end if
  140 continue
      return
      end
c*module masscf  *deck symwrk
c     --------------------------------------------------------
      subroutine symwrk(iw,ibo,nact,na,nb,idsym,isym1,nsym,
     *     nalp,nblp,icon,isyma,isymb,icoa,icob,itab,
     *     imul,ispa,ispb,isas,isbs,isac,isbc)
c     --------------------------------------------------------
      implicit double precision(a-h,o-z)
      dimension icon(*)
      dimension ispa(nalp),ispb(nblp),icoa(nsym),icob(nsym)
      dimension isyma(nalp),isymb(nblp),itab(nsym)
      dimension isas(nsym+1),isbs(nsym+1)
      dimension isac(nalp),isbc(nblp)
      dimension imul(nsym,nsym)
      dimension ibo(nact)
c
c     code to return symmetry data for ci calculation.
c
c     ibo   : ibo(i) is symmetry of orbital i, see gtab for info
c     nact  : no. of active orbitals
c     na    : no. of active alpha electrons
c     nb    : no. of active beta electrons
c     idsym : which point group, see gtab for convention
c     isym1 : which irreducible representation, see gtab for conv.
c     nsym  : nsym = 2**(idsym)
c     nalp  : number of alpha space functions
c     nblp  : number of beta space functions
c     all remaining arrays are used for ci,density,and mcscf routines.
c
      call gtab(idsym,isym1,itab,icon(1),icon(4),icon(7),icon(10))
      call gmul(idsym,imul,icon(1),icon(4),icon(7),icon(10))
c
      do 13 ii=1,nsym
         isas(ii) = 0
         isbs(ii) = 0
         icoa(ii) = 0
         icob(ii) = 0
   13 continue
c
      do 23 ii=1,nb
         icon(ii) = ii
   23 continue
c
      do 43 ib=1,nblp
         call getsym1(iw,icon(1),nact,nb,ibo,idsym,isym,
     *    icon(na+1),icon(na+4),icon(na+7),icon(na+10))
         isymb(ib) = isym
         icob(isym) = icob(isym) + 1
         ispb(ib) = icob(isym)
         call advanc(icon,nb,nact)
   43 continue
c
      do 33 ii=1,na
         icon(ii) = ii
   33 continue
c
      nci = 0
      do 53 ia=1,nalp
         call getsym1(iw,icon(1),nact,na,ibo,idsym,isym,
     *   icon(na+1),icon(na+4),icon(na+7),icon(na+10))
         isyma(ia) = isym
         icoa(isym) = icoa(isym) + 1
         ispa(ia) = nci
         nci = nci + icob(itab(isym))
         call advanc(icon,na,nact)
   53 continue
c
      isas(1) = 1
      isbs(1) = 1
      isas(nsym+1) = nalp + 1
      isbs(nsym+1) = nblp + 1
c
      do 63 ii=2,nsym
         isas(ii) = isas(ii-1) + icoa(itab(ii-1))
         isbs(ii) = isbs(ii-1) + icob(itab(ii-1))
   63 continue
c
      do 73 ii=1,nsym
         icoa(ii) = 0
         icob(ii) = 0
   73 continue
c
      do 83 ia=1,nalp
         nsa = isyma(ia)
         icoa(nsa) = icoa(nsa) + 1
         isac(isas(itab(nsa))+icoa(nsa)-1) = ia
   83 continue
c
      do 93 ib=1,nblp
         nsa = isymb(ib)
         icob(nsa) = icob(nsa) + 1
         isbc(isbs(itab(nsa))+icob(nsa)-1) = ib
   93 continue
c
      return
      end 
c*module masscf  *deck aoden1
      subroutine aoden1(vec,dm1,wrk,den,ncore,nact,num)
      implicit REAL (a-h,o-z)
INCLUDE(common/scra7)
INCLUDE(common/iofile)
      dimension vec(*),dm1(*),wrk(*),den(num,*)
c
c     transform dm1 to ao basis and output
c     input dm1 is over the 'active' mos only
c
      call vclr(den,1,num*num)
      do i = 1, ncore
        den(i,i) = 2.0d+00
      end do
      nocc = ncore + nact
      ij = 0
      do i = ncore+1, nocc
        do j = i, nocc
          ij = ij + 1
          den(i,j) = dm1(ij)
          den(j,i) = den(i,j)
        end do
      end do
      call tfsqc(vec,den,wrk,nocc,num,num)
c
c     tfsqc output is in 'vec'
c
cgdf  need zscftp='mcscf' or incl. masscf with 'mcscf', etc
c     see (anala) hfprop,dipole,denhf
c
      call sq2tr(vec,wrk,num)
      l2 = (num*num+num)/2

cgdf  need secini,get?
c     not sure which block,section,type..??
c     call wrt3(wrk,l2,iblock,num8)
      return
      end 
c
c     copy symmetric square matrix to triangle
c
      subroutine sq2tr(sq,tr,n)
      implicit REAL (a-h,o-z)
      dimension sq(n,*), tr(*)
c
      k = 0
      do i = 1 , n
        do j = 1 , i
          k = k + 1
          tr(k) = sq(i,j)
        end do
      end do
      return
      end 
