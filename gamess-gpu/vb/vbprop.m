c
c  $Author: jvl $
c  $Date: 2013-03-07 12:50:35 +0100 (Thu, 07 Mar 2013) $
c  $Locker:  $
c  $Revision: 6279 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/vb/vbprop.m,v $
c  $State: Exp $
c  $Log: vbprop.m,v $
c  Revision 1.7  2007/10/18 16:45:34  jvl
c  Problem with clearing nodes on Huygens fixed (inside subroutine vberr).
c  Some cosmetic changes.
c  Hopefully everything works :)
c  /marcin
c
c  Revision 1.4  2007/09/07 15:52:04  mrdj
c  changed d comment to CC
c
c  Revision 1.3  2007/03/20 14:49:31  jvl
c  Pretty major overhaul of the VB code
c  say 50% is now dynamic using igmem_alloc and, oh wonder,
c  all the examples are still checking out OK, including a new resonating
c  super hybrid. (will follow)
c
c  Revision 1.2  2007/02/20 15:21:16  jvl
c  The array atomao (hybrid per ao) made the hybrid code a lot simpler.
c  Unfortunately now we need the possibility to let an ao belong to two hybrids.

c  Further some restrictions were removed; now resomating BLW may be used (:-))
c
c  Revision 1.1  2006/12/13 21:56:08  rwa
c  First check in of the experimental VB response property code.
c
c
      subroutine vbprop(q)
      implicit REAL (a-h,o-z)
      dimension q(*)
c
c  second order response property evaluation
c
      dimension igroup(5,2)
INCLUDE(../m4/common/sizes)
INCLUDE(common/c8_16vb)
INCLUDE(common/tractlt)
INCLUDE(common/ffile)
INCLUDE(common/scftvb)
INCLUDE(common/turtleparam)
INCLUDE(common/vbproper)
INCLUDE(common/brill)
INCLUDE(common/twice)
INCLUDE(common/infato)
INCLUDE(common/splice)
INCLUDE(../m4/common/restri)
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/mapper)
      common/restrr/
     + gx,gy,gz,rspace(21),tiny,tit(2),scale,ropt,vibsiz
      logical oadd,ochatao
_IF(parallel)
      dimension iskip(maxex)
_ENDIF
      data thresh1/1.0d-12/
      ind(i,j)=max0(i,j)*(max0(i,j)-1)/2+min0(i,j)
c
 6001 format(//1x,80('-'),//)
      write(iwr,6001)
      write(iwr,5990)
 5990 format(/20x,48('*'),
     &/20x,'*** VB second order response property module ***',
     &/20x,48('*'),/)
      if (ovbci) write(iwr,5991)
 5991 format(/20x,48('*'),
     &/20x,'*** VBCI response only ***',
     &/20x,48('*'),/)
      if (ovbci2) write(iwr,5992) ndubbel
 5992 format(/20x,48('*'),
     &/20x,'*** VBCI + doubly occupieds: ',(I4),
     &/20x,48('*'),/)
      orunprop=.true.
      if (omag) ocomplex=.true.
      call init_mem_vbprop
      nsaold=nsa
      dfac=1.0d0
      if (ocomplex) dfac=-1.0d0
 6000 format(/1x,
     +'commence VB second order response properties at ',
     + f8.2,' seconds')
      write(iwr,6000) cpulft(1)
c
      call wr15vb(nelec,nalfa,nconf,ndets,nstruc,maxdet,maxstr,
     &            nwpack,ncoeff,imax,ndum11,ndoub,'read')
c
      indetps=igmem_alloc(nstruc)
      icoeff=igmem_alloc(ncoeff)
      ijdets=igmem_alloc(nelec*ncoeff)
      call printmem(nstruc+ncoeff+nelec*ncoeff)
      if (odebug) then
       write(iwr,*)'remco nstruc',nstruc,ndets,nelec,maxdet,ncoeff
      endif
c
      ijunk=igmem_alloc(nconf)
      ijunk2=igmem_alloc(nconf)
      ijunk3=igmem_alloc(nelec*maxdet)
      iidetps=igmem_alloc(ncoeff)
      call printmem(2*nconf+ncoeff+nelec*maxdet)
      call getwave2(q,q(indetps),q(iidetps),q(icoeff),q(ijunk),
     &        q(ijdets),q(ijunk2),q(ijunk3),nstruc,nconf,nelec)
      call ordermo(ncoeff,q(ijdets),q(icoeff),nelec,nalfa)
      call gmem_free(iidetps)
      call gmem_free(ijunk3)
      call gmem_free(ijunk2)
      call gmem_free(ijunk)
      call printmem(-(2*nconf+ncoeff+nelec*maxdet))
c
      call secget(isect(79),79,ib)
      call rdedx(igroup,3,ib,idaf)
c
c     call get1e(q,potn,'a',q(lenbas+1))
c
      nelec2=igroup(2,1)
c
      nocc=nsa
      ldet=igroup(1,1)
      ni=ldet
cjvl     kl=igroup(1,1)*nelec2/4  jeroenowitch ??
      kl=(igroup(1,1)*nelec2-1)/(64/n8_16)+1
      i1=igmem_alloc(igroup(1,1))
      i2=igmem_alloc(kl)
      i3=igmem_alloc(igroup(1,1)*nelec)
      i4=igmem_alloc(igroup(1,1)*nelec)
      ijunk1=igmem_alloc(ldet)
      ijunk2=igmem_alloc(ldet*nelec)
      call printmem(igroup(1,1)*(1+2*nelec)+kl+ldet+ldet*nelec)
      if (ovbci2) then
      call getwave3(q(ijunk1),q(i2),q(ijunk2),q(i4),igroup,
     &nelec2,nelec,ndoub,nalfa)
      else
      call getwave(q(ijunk1),q(i2),q(ijunk2),q(i4),igroup,
     &nelec2,nelec,ndoub,nalfa)
      endif
      call ordermo(ldet,q(ijunk2),q(ijunk1),nelec,nalfa)
      mdet=ldet
c     call printwave(ldet,q(ijunk1),q(ijunk2),nelec)
      call checkpsi0(mdet,q(ijunk1),q(ijunk2),q(i4),nelec,
     *nalfa,ldet,q(i1),q(i3))
      call gmem_free(ijunk2)
      call gmem_free(ijunk1)
      call gmem_free(i4)
      call printmem(-(ldet*nelec+ldet+igroup(1,1)*nelec))
      if (odebug) call printwave(ldet,q(i1),q(i3),nelec)
c
      if (ncore.ne.0) call caserr('All orbitals should be optimised')
      if (ncore.ne.0) then 
         write(iwr,6111) ncore
 6111 format(/10x,47('*'),/10x,'ncore .ne. 0 but',i3,' You might generat
     &e nonsense'/10x,47('*'))
c        ncore_old=ncore
c        ncore=0
      endif
      maxvirt = nbasis
      kvec=igmem_alloc(nbasis*nocc+nbasis*maxvirt)
c       print *,'remco isecv',isecv
      call printmem(nbasis*nocc+nbasis*maxvirt)
      call getqvb(q(kvec),nbasis,nocc,isecv,'print')
      if (ovbci2) then
         maxvec=nocc+maxvirt
         call vbfirst(q(kvec),maxvec)
      endif
      if (odebug) call prvc(q(kvec),nocc,nbasis,q(kvec),'v','l')
      kvirt=kvec+nbasis*nocc
cold      call virtual(q(kvec),q(kvirt),nocc,ncore,nvirt,maxvirt,q)
      call virtual(q(kvec),q(kvirt),
     1             nbasis,ncore,nocc,nvirt,maxvirt,q)
c     print *,'remco na virtual',ipg_nodeid()
c
        nactiv=nsa
c
         nmo = nscf
         nao = nbasis
         naomo = nao + nmo
c
c
           ksao = igmem_alloc(nbasis*(nbasis+1)/2)
           kvcopy = igmem_alloc(nbasis*(nbasis+nactiv+ncore))
           kiocvi = igmem_alloc(2*2*nactiv + 2*ncore)
           kiset = igmem_alloc(nbasis)
           kiact = igmem_alloc(nactiv)
           kidoc = igmem_alloc(nactiv)
           kisoc = igmem_alloc(nactiv)
           kivir = igmem_alloc(nbasis)
           nam = nbasis + nscf
           khmoao = igmem_alloc(nam*(nam+1)/2)
           kiex2 = igmem_alloc(nactiv*(nbasis+1))
      mem=nbasis*(nbasis+1)/2+nbasis*(nbasis+nactiv+ncore)+2*2*nactiv 
     & + 2*ncore+3*nactiv+2*nbasis+nam*(nam+1)/2+nactiv*(nbasis+1)
      call printmem(mem)
c          call redorb( q(ksao),q(kvec+ncore*nbasis),q(kvcopy),
c    &     q(kvec),q(kiocvi),
c    &     q(kiset),q(kiact),q(kidoc),q(kisoc),q(kivir),
c    &     q(khmoao),q(kiex2),nbasis,q)
c     print *,'remco na redorb',ipg_nodeid()
      call gmem_free(kiex2)
      call gmem_free(khmoao)
      call gmem_free(kivir)
      call gmem_free(kisoc)
      call gmem_free(kidoc)
      call gmem_free(kiact)
      call gmem_free(kiset)
      call gmem_free(kiocvi)
      call gmem_free(kvcopy)
      call gmem_free(ksao)
      call printmem(-mem)
c     print *,'remco na freeing',ipg_nodeid()
      write(iwr,6001)
 6002 format(/10x,12('*'),/10x,'eigenvectors'/10x,12('*'))
      write(iwr,6002)
      norb=nsa+nvirt+ncore
      nsa=norb
      lenact=norb*(norb+1)/2
      do i=1,nvirt
         do j=1,nbasis
            q(kvirt-1+(i-1)*nbasis+j)=q(kvirt-1+(nscf+i-1)*nbasis+j)
         enddo
      enddo
      call prsq(q(kvec),norb,nbasis,nbasis)
      write(iwr,6001)
      ismat=igmem_alloc(lenact)
      ihmat=igmem_alloc(lenact)
      call printmem(2*lenact)
      ncol=norb
c
c
      ncore_old=ncore
      ncore=0
c     call transformvb(q(ismat),q(ihmat),q(kvec),q)
      call transformvb(q(ismat),q(ihmat),q(kvec))
      write(iwr,*)'remco after transformvb'
      ncore=ncore_old

      if (lenact*(lenact+1)/2.ne.n2int) 
     1    call caserr('new2 correct for prop ?? - check')
      call printmem(n2int+1)
      igmat=igmem_alloc(n2int+1)
      call getin2(q(igmat))
      call clredx

       if (odebug) then
	write(iwr,*) 'overlap matrix'
      call prtri(q(ismat),norb)
	write(iwr,*)'h-matrix'
      call prtri(q(ihmat),norb)
c     call prtri(q(igmat),lenact)
       endif
c
c remove core orbitals
c
      mem=norb+1+16*ldet*ldet+1+16*ldet*ldet+1+3*((nelec**2+1)**2)+
     & 10*norb+6+2*(nelec+1)
      call printmem(mem)
      iortho=igmem_alloc(norb+1)
      idetcomb=igmem_alloc(16*ldet*ldet+1)
      idettot=igmem_alloc(16*ldet*ldet+1)
      iscr1=igmem_alloc((nelec**2+1)**2)
      iscr2=igmem_alloc((nelec**2+1)**2)
      iscr3=igmem_alloc((nelec**2+1)**2)
      ig=igmem_alloc(10*norb+6)
      icp=igmem_alloc(nelec+1)
      jcp=igmem_alloc(nelec+1)
         nbeta = nelec - nalfa
         nnnnn = nalfa ** 2 + nbeta ** 2
         nwwww = nnnnn
         nxxxx = (nalfa * (nalfa-1) / 2)**2 +
     &           (nbeta * (nbeta-1) / 2)**2
         nnnnn = nnnnn + nxxxx * 2
         nwwww = nwwww + nxxxx
         nxxxx = (nalfa**2)*(nbeta**2)
         nnnnn = nnnnn + nxxxx * 2
         nwwww = nwwww + nxxxx
      kword = nnnnn + 1
      iweight=igmem_alloc(kword)
      iipos=igmem_alloc(kword)
      call printmem(2*kword)

      ilk=max0(nbasis,ncol)
      ilk=ilk*(ilk+1)/2
      ill=nalfa**2+(nelec-nalfa)**2 + 1
      is=igmem_alloc(ill)
      ig2=igmem_alloc(ilk*(ilk+1)/2)
      idetps=igmem_alloc(ldet*8)
      iscrreorb=igmem_alloc(8*ldet*nelec)
      mem=ill+ilk*(ilk+1)/2+ldet*8+8*ldet*nelec
      call printmem(mem)
      call vclr(q(iweight),1,kword)
      call vclr(q(iipos),1,kword)
c
      call sym1(q(ismat),norb,q(iortho),northo,'noprint')
c
c
c allocate space for excited vector
c
      i21=igmem_alloc(ldet*8)
      i31=igmem_alloc(ldet*nelec*8)
      i41=igmem_alloc(ldet*8)
      i51=igmem_alloc(ldet*nelec*8)
      mem=2*(ldet*8+ldet*nelec*8)
      call printmem(mem)
      call setqig(q(ig))
c
c get property integrals
c
 6009 format(/1x,
     +'commence property gradient evaluation at ',
     + f8.2,' seconds')
      write(iwr,6009) cpulft(1)
      ix=igmem_alloc(lenact)
      iy=igmem_alloc(lenact)
      iz=igmem_alloc(lenact)
      ix2=igmem_alloc(nbasis*(nbasis+1)/2)
      iy2=igmem_alloc(nbasis*(nbasis+1)/2)
      iz2=igmem_alloc(nbasis*(nbasis+1)/2)
      mem=3*lenact+3*(nbasis*(nbasis+1)/2)
      call printmem(mem)
      if (opol) then
         call get1e(q(ix2),dummy,'x',q(ix2))
         call get1e(q(iy2),dummy,'y',q(iy2))
         call get1e(q(iz2),dummy,'z',q(iz2))
         call remtrans2(q(ix2),q(ix),q(kvec),nbasis,ncol)
         call remtrans2(q(iy2),q(iy),q(kvec),nbasis,ncol)
         call remtrans2(q(iz2),q(iz),q(kvec),nbasis,ncol)
      elseif(omag) then
         nx=nbasis*(nbasis+1)/2
         gx=0.0
         gy=0.0
         gz=0.0
         i100 = igmem_alloc(nx)
         i101 = igmem_alloc(nbasis*nbasis)
         i102 = igmem_alloc(nbasis)
      mem=nx+nbasis*nbasis+nbasis
      call printmem(mem)
         call amints(q(ix2),q(iy2),q(iz2),q(i100),q(i101),q(i102),
     &               .false.)
         call skwtr(q(ix),q(ix2),q(kvec),q(i102),iky,ncol,nbasis,nbasis)
         call skwtr(q(iy),q(iy2),q(kvec),q(i102),iky,ncol,nbasis,nbasis)
         call skwtr(q(iz),q(iz2),q(kvec),q(i102),iky,ncol,nbasis,nbasis)
         call gmem_free(i102)
         call gmem_free(i101)
         call gmem_free(i100)
      call printmem(-mem)
      endif
      if (odebug) then
        write(iwr,*)'1-el integrals'
        write(iwr,*) 'x-integs'
        call prtri(q(ix),ncol)
        write(iwr,*)'y-integs'
        call prtri(q(iy),ncol)
        write(iwr,*) 'z-integs'
        call prtri(q(iz),ncol)
      endif
      call gmem_free(iz2)
      call gmem_free(iy2)
      call gmem_free(ix2)
      call printmem(-3*(nbasis*(nbasis+1)/2))
c
c form property vector orbital stuff and excitation patterns
c
      kpdet=nstruc
      nsin=2*norb**2
      if (ovbci) nsin=0
      ibx=igmem_alloc(nsin+kpdet)
      iby=igmem_alloc(nsin+kpdet)
      ibz=igmem_alloc(nsin+kpdet)
      call printmem(3*(nsin+kpdet))
c
c     
      call fillidetps(q(idetps),ldet)
      if (odebug) call printwave(ldet,q(i1),q(i3),nelec)
      call reorb(q(i3),ldet,nelec,nalfa,q(iortho),q(iscrreorb),q(i1),
     &                                          q(idetps),ldet)
            call prop_hatham(dd,ds,q(icp),q(jcp),q(ismat),q(ix),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet,ldet,q(i3),
     &             q(i3),q(i1),q(i1),q(idetcomb),q(idettot))
_IF(parallel)
      call pg_dgop(100,dd,1,'+')
      call pg_dgop(101,ds,1,'+')
_ENDIF
      x0=dd/ds
            call prop_hatham(dd,ds,q(icp),q(jcp),q(ismat),q(iy),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet,ldet,q(i3),
     &             q(i3),q(i1),q(i1),q(idetcomb),q(idettot))
_IF(parallel)
      call pg_dgop(100,dd,1,'+')
      call pg_dgop(101,ds,1,'+')
_ENDIF
      y0=dd/ds 
            call prop_hatham(dd,ds,q(icp),q(jcp),q(ismat),q(iz),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet,ldet,q(i3),
     &             q(i3),q(i1),q(i1),q(idetcomb),q(idettot))
_IF(parallel)
      call pg_dgop(100,dd,1,'+')
      call pg_dgop(101,ds,1,'+')
_ENDIF
      z0=dd/ds
      if (odebug) write(iwr,*)'remco x0',x0,y0,z0
c     
c
c
      do ifr1=1,nscf
         iex_prop(1,ifr1)=ifr1
         nex_prop(ifr1)=0
      enddo
c
      itest=0
      ia=1
      istart=1
      if (super) istart=nscf+1
      if (odebug) write(iwr,*)'super::',super
      if (ovbci) goto 112
      do ifr1=1,nscf
         ib=1
         do ito1=istart,norb
            if (ifr1.eq.ito1) goto 101
            if (ofrzmo(ifr1)) goto 101
            if (ovbci2) then
               if ((ifr1.gt.ndubbel).and.(ito1.gt.ndubbel).and.
     *             (ito1.le.nscf)) goto 101
            endif
            call create_exc(ldet,q(i1),q(i3),q(i21),q(i31),
     *      nelec,ifr1,ito1,ldet2,nalfa)
            call dcopy(ldet,q(i1),1,q(i41),1)
            call dcopy(ldet*nelec,q(i3),1,q(i51),1)
            ldet3=ldet
            if (ldet2.eq.0) goto 101
            itest=itest+1
      call fillidetps(q(idetps),ldet2)
      call reorb(q(i31),ldet2,nelec,nalfa,q(iortho),q(iscrreorb),q(i21),
     &                                          q(idetps),ldet2)
      call fillidetps(q(idetps),ldet3)
      call reorb(q(i51),ldet3,nelec,nalfa,q(iortho),q(iscrreorb),q(i41),
     &                                          q(idetps),ldet3)
            call prop_hatham(dd,ds,q(icp),q(jcp),q(ismat),q(ix),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &             q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
            q(ibx+ia-1)=dfac*2*(dd-x0*ds)
            call prop_hatham(dd,ds,q(icp),q(jcp),q(ismat),q(iy),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &             q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
            q(iby+ia-1)=dfac*2*(dd-y0*ds)
            call prop_hatham(dd,ds,q(icp),q(jcp),q(ismat),q(iz),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &             q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
            q(ibz+ia-1)=dfac*2*(dd-z0*ds)
c
_IFN(parallel)
            if ((dabs(q(ibx+ia-1)).gt.thresh1).or.(dabs(q(iby+ia-1))
     &           .gt.thresh1).or.(dabs(q(ibz+ia-1)).gt.thresh1).or.
     &            onosym) then
_ENDIF
               oadd=.true.
               if (hybry) then
c check whether this excitation is allowed
                  call abmax(q(kvec+(nbasis*(ifr1-1))),nbasis,1,
     1                       'sq',1,am,iatom)
c                 iatom=0
c                 do jhybrid=1,natom
c                    ithere=locati(ifr1,iacat(1,jhybrid),nacat(jhybrid))
c                    if (ithere.ne.0) iatom=jhybrid
c                 enddo
                  if (iatom.eq.0) call vberr('hybrid error')
                  call abmax(q(kvec+(nbasis*(ito1-1))),nbasis,1,
     1                       'sq',1,am,jatom)
c                 jatom=atomao(im)
       if (odebug) then
         write(iwr,*)'iatom::',iatom,jatom,ochatao(iatom,jatom,'common')
         if (ochatao(iatom,jatom,'common')) then
         write(iwr,*)'testing hybrid excitation',ifr1,'->',ito1,
     & q(ibx+ia-1),
     & q(iby+ia-1),q(ibz+ia-1),q(ihmat+ind(ifr1,ito1)-1)
           endif
       endif
                  if (.not.ochatao(iatom,jatom,'common')) then
c apparently not in hybrid definition
c symmetry or not?
                    if (dabs(q(ihmat+ind(ifr1,ito1)-1)).gt.thresh1) then
c apparently not excluded by symmetry ...  
                       oadd=.false.
                    endif
                  endif
               endif
c  print *,'hybrids',iatom,jatom,oadd  oflop = ochatao(iatom,jatom,'print')
               if (oadd) then
                  ib=ib+1
                  ia=ia+1
                  iex_prop(ib,ifr1)=ito1
                  nex_prop(ifr1)=nex_prop(ifr1)+1
               endif
_IFN(parallel)
            endif
_ENDIF
c
101         continue
         enddo
      enddo
c
_IF(parallel)
c
c check symmetry 
c
      msin=ia-1
      call pg_dgop(200,q(ibx),msin,'+')
      call pg_dgop(201,q(iby),msin,'+')
      call pg_dgop(202,q(ibz),msin,'+')
      kbx=igmem_alloc(msin)
      kby=igmem_alloc(msin)
      kbz=igmem_alloc(msin)
      call printmem(3*(msin))
      call dcopy(msin,q(ibx),1,q(kbx),1)
      call dcopy(msin,q(iby),1,q(kby),1)
      call dcopy(msin,q(ibz),1,q(kbz),1)
      ia=0
      ib=0
      do ifri=1,nscf
         ifr1=iex_prop(1,ifri)
         ilast=nex_prop(ifri)
         nskip=0
         do itoi=1,ilast
            ito1=iex_prop(1+itoi,ifri)
            ib=ib+1
            if ((dabs(q(kbx+ib-1)).gt.thresh1).or.(dabs(q(kby+ib-1))
     &           .gt.thresh1).or.(dabs(q(kbz+ib-1)).gt.thresh1).or.
     &            onosym) then
               ia=ia+1
               q(ibx+ia-1)=q(kbx+ib-1)
               q(iby+ia-1)=q(kby+ib-1)
               q(ibz+ia-1)=q(kbz+ib-1)
            else
               nskip=nskip+1
               iskip(nskip)=ito1
            endif
         enddo
         inge=0
         do ilse=1,ilast
            lies=iex_prop(1+ilse,ifri)
            ithere=locati(lies,iskip,nskip)
            if (ithere.eq.0) then
               inge=inge+1
               iex_prop(1+inge,ifri)=iex_prop(1+ilse,ifri)
            endif
         enddo
         nex_prop(ifri)=nex_prop(ifri)-nskip
      enddo
      call gmem_free(kbz)
      call gmem_free(kby)
      call gmem_free(kbx)
      call printmem(-3*(msin))
_ENDIF
c
_IF(parallel)
112   if (odebug)
     &write(iwr,*)'remco excitations. tested:',itest,' selected:',ia
_ELSE
112   if (odebug)
     &write(iwr,*)'remco excitations. tested:',itest,' selected:',ia-1
_ENDIF
      nsin=0
      write(iwr,601)
601   format(1x,/,'         ====================== ',
     1          /,'          Property excitations',
     2          /,'         ====================== '/)
602     format('       mo',i3,' ==>',15i4,/,(16x,15i4))
      do i=1,nscf
        if (nex_prop(i).gt.0) then
           write(iwr,602) (iex_prop(j,i),j=1,nex_prop(i)+1)
        endif
        nsin=nsin+nex_prop(i)
      end do 
c
      do kkdeti=1,kpdet
         call dcopy(ldet,q(i1),1,q(i41),1)
         call dcopy(ldet*nelec,q(i3),1,q(i51),1)
         ldet3=ldet
         call takecideriv(kkdeti,q(indetps),q(icoeff),q(ijdets),
     &                    ldet2,q(i31),q(i21),nelec)
      call fillidetps(q(idetps),ldet2)
      call reorb(q(i31),ldet2,nelec,nalfa,q(iortho),q(iscrreorb),q(i21),
     &                                          q(idetps),ldet2)
      call fillidetps(q(idetps),ldet3)
      call reorb(q(i51),ldet3,nelec,nalfa,q(iortho),q(iscrreorb),q(i41),
     &                                          q(idetps),ldet3)
            call prop_hatham(dd,ds,q(icp),q(jcp),q(ismat),q(ix),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &             q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
            q(ibx+nsin+kkdeti-1)=dfac*2*(dd-x0*ds)
            call prop_hatham(dd,ds,q(icp),q(jcp),q(ismat),q(iy),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &             q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
            q(iby+nsin+kkdeti-1)=dfac*2*(dd-y0*ds)
            call prop_hatham(dd,ds,q(icp),q(jcp),q(ismat),q(iz),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &             q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
            q(ibz+nsin+kkdeti-1)=dfac*2*(dd-z0*ds)
      enddo
c
      write(iwr,6010) cpulft(1)
      write(iwr,6001)
_IF(parallel)
      call pg_dgop(102,q(ibx+nsin),kpdet,'+')
      call pg_dgop(103,q(iby+nsin),kpdet,'+')
      call pg_dgop(104,q(ibz+nsin),kpdet,'+')
_ENDIF
c
c
c
c
c double excitations <psi(ia)|H|psi(jb)
c
 6003 format(/1x,
     +'commence orbital hessian evaluation at ',
     + f8.2,' seconds')
      write(iwr,6003) cpulft(1)
      icih=igmem_alloc(nsin*(nsin+1)/2)
c
      call printmem(nsin*(nsin+1)/2)
      call fillidetps(q(idetps),ldet)
      call reorb(q(i3),ldet,nelec,nalfa,q(iortho),q(iscrreorb),q(i1),
     &                                          q(idetps),ldet)
      call hathad(dd,ds,q(icp),q(jcp),q(ismat),q(ihmat),
     &            q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &            q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &            nelec,q(iortho),northo,nbody,ldet,q(i3),q(i1),
     &            q(idetcomb),q(idettot))
_IF(parallel)
      call pg_dgop(105,dd,1,'+')
      call pg_dgop(106,ds,1,'+')
_ENDIF
      e0=dd/ds
      dnorm=ds
c normalise gradient vector
      do i=1,nsin+kpdet
         q(ibx+i-1)=q(ibx+i-1)/dnorm
         q(iby+i-1)=q(iby+i-1)/dnorm
         q(ibz+i-1)=q(ibz+i-1)/dnorm
      enddo
c
 6004 format(/1x,'E0 = ',f20.8,' au (electronic energy);',' norm: ',
     & f20.8) 
      write(iwr,6001)
      write(iwr,6004) e0,dnorm
      write(iwr,6001)
c
      dtest=0.0d0
      if (ouncoupled) then
         ide=igmem_alloc(nsin)
         idx=igmem_alloc(nsin)
         idy=igmem_alloc(nsin)
         idz=igmem_alloc(nsin)
         call dcopy(nsin,q(ibx),1,q(idx),1)   
         call dcopy(nsin,q(iby),1,q(idy),1)   
         call dcopy(nsin,q(ibz),1,q(idz),1)   
      endif
      ia=0
      do ifri=1,nscf
         ifr1=iex_prop(1,ifri)
         do itoi=1,nex_prop(ifri)
            ito1=iex_prop(1+itoi,ifri)
            ia=ia+1
            call create_exc(ldet,q(i1),q(i3),q(i21),q(i31),
     *      nelec,ifr1,ito1,ldet2,nalfa)
            jb=0
            do ifrj=1,nscf
               ifr2=iex_prop(1,ifrj)
               do itoj=1,nex_prop(ifrj)
                  ito2=iex_prop(1+itoj,ifrj)
                  jb=jb+1
                  if (jb.le.ia) then
                  call create_exc(ldet,q(i1),q(i3),q(i41),
     *            q(i51),nelec,ifr2,ito2,ldet3,nalfa)
      call fillidetps(q(idetps),ldet2)
      call reorb(q(i31),ldet2,nelec,nalfa,q(iortho),q(iscrreorb),q(i21),
     &                                          q(idetps),ldet2)
                  if (ia.eq.jb) then
c diagonal element
      call hathad(dd,ds,q(icp),q(jcp),q(ismat),q(ihmat),
     &            q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &            q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &            nelec,q(iortho),northo,nbody,ldet2,q(i31),q(i21),
     &            q(idetcomb),q(idettot))
                    if (ouncoupled) then
                       q(ide+ia-1)=e0-2.0*(dd-ds*e0)
                    endif
                  else
      call fillidetps(q(idetps),ldet3)
      call reorb(q(i51),ldet3,nelec,nalfa,q(iortho),q(iscrreorb),q(i41),
     &                                          q(idetps),ldet3)
               call hatham(dd,ds,q(icp),q(jcp),q(ismat),q(ihmat),
     &                  q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &                  q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &                  nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &                  q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
                  endif
                  q(icih+ind(ia,jb)-1)=(2.0d0*(dd-ds*e0))/dnorm
                  endif
               enddo
            enddo
         enddo
      enddo
c     write(iwr,*)'remco <psi(ia)|H-E0|psi(jb)>'
c     call prtri(q(icih),nsin)
c
c double excitations <psi(0)|H|psi(iajb)>
c
      kscr=igmem_alloc(8*nelec)
      call printmem(8*nelec)
      ia=0
      do ifri=1,nscf
         ifr1=iex_prop(1,ifri)
         do itoi=1,nex_prop(ifri)
            ito1=iex_prop(1+itoi,ifri)
            ia=ia+1
c
            jb=0
            do ifrj=1,nscf
               ifr2=iex_prop(1,ifrj)
               do itoj=1,nex_prop(ifrj)
                  ito2=iex_prop(1+itoj,ifrj)
                  jb=jb+1
                  if (jb.le.ia) then
                  call create_exc(ldet,q(i1),q(i3),q(i21),
     *            q(i31),nelec,ifr1,ito1,ldet2,nalfa)
                  call create_exc(ldet2,q(i21),q(i31),q(i41),
     *            q(i51),nelec,ifr2,ito2,ldet3,nalfa)
c
                  call dcopy(ldet,q(i1),1,q(i21),1)
                  call dcopy(ldet*nelec,q(i3),1,q(i31),1)
                  ldet2=ldet
      call fillidetps(q(idetps),ldet2)
      call reorb(q(i31),ldet2,nelec,nalfa,q(iortho),q(iscrreorb),q(i21),
     &                                          q(idetps),ldet2)
      call fillidetps(q(idetps),ldet3)
      call reorb(q(i51),ldet3,nelec,nalfa,q(iortho),q(iscrreorb),q(i41),
     &                                          q(idetps),ldet3)
               call hatham(dd,ds,q(icp),q(jcp),q(ismat),q(ihmat),
     &                  q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &                  q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &                  nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &                  q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
c       write(iwr,'(A,2F10.5,4I3)')'remco <psi(0)|H-E0|psi(iajb)>',
c    &            dd,ds,
c    &            ifr1,ito1+nocc,ifr2,ito2+nocc
                  q(icih+ind(ia,jb)-1)=q(icih+ind(ia,jb)-1)
     &                                 +(2.0d0*dfac*(dd-e0*ds))/dnorm
                  endif
               enddo
            enddo
         enddo
      enddo
c     write(iwr,*)'remco na doubles'
      call gmem_free(kscr)
      call printmem(-8*nelec)
c     call prtri(q(icih),nsin)
c
c single excitations <psi(0)|H|psi(ia)><psi(0)|psi(jb)>+<psi(0)|H|psi(jb)><psi(0)|psi(ia)>
c
c     icih2=igmem_alloc(nsin*(nsin+1)/2)
c     icis2=igmem_alloc(nsin*(nsin+1)/2)
c     ia=0
c     call prtri(q(ismat),nbasis)
c     call prtri(q(ihmat),nbasis)
c     call prtri(q(igmat+1),nbasis*(nbasis+1)/2)
c     print *,'remco q(igmat)',q(igmat)
c     do ifri=1,nscf
c        ifr1=iex_prop(1,ifri)
c        do itoi=1,nex_prop(ifri)
c           ito1=iex_prop(1+itoi,ifri)
c           ia=ia+1
c           call create_exc(ldet,q(i1),q(i3),q(i21),q(i31),
c    *      nelec,ifr1,ito1,ldet2,nalfa)
c           call dcopy(ldet,q(i1),1,q(i41),1)
c           call dcopy(ldet*nelec,q(i3),1,q(i51),1)
c           ldet3=ldet
c     call fillidetps(q(idetps),ldet2)
c     call reorb(q(i31),ldet2,nelec,nalfa,q(iortho),q(iscrreorb),q(i21),
c    &                                          q(idetps),ldet2)
c     call fillidetps(q(idetps),ldet3)
c     call reorb(q(i51),ldet3,nelec,nalfa,q(iortho),q(iscrreorb),q(i41),
c    &                                          q(idetps),ldet3)
c           call hatham(dd,ds,q(icp),q(jcp),q(ismat),q(ihmat),
c    &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
c    &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
c    &             nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
c    &             q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
c           q(icih2+ia-1)=dd-e0*ds
c           q(icis2+ia-1)=ds
c        enddo
c     enddo
c
c generate final 2nd derivative matrix
c
c     ia=0
c     do ifri=1,nscf
c        ifr1=iex_prop(1,ifri)
c        do itoi=1,nex_prop(ifri)
c           ito1=iex_prop(1+itoi,ifri)
c           ia=ia+1
c           jb=0
c           do ifrj=1,nscf
c              ifr2=iex_prop(1,ifrj)
c              do itoj=1,nex_prop(ifrj)
c                 ito2=iex_prop(1+itoj,ifrj)
c                 jb=jb+1
c                 if (jb.le.ia) then
c                 q(icih+ind(ia,jb)-1)=q(icih+ind(ia,jb)-1)
c    & -4.0d0*(q(icih2+ia-1)*q(icis2+jb-1)+
c    &         q(icih2+jb-1)*q(icis2+ia-1))
c                 dtest=max(dtest,dabs(q(icih2+ia-1)*q(icis2+jb-1)
c    &                  +q(icih2+jb-1)*q(icis2+ia-1)))
c                 endif
c              enddo
c           enddo
c        enddo
c     enddo
c     call prtri(q(icih),nsin)
c
c calculate the CI derivatives for a matrix
c 
 6005 format(/1x,
     +'commence CI hessian evaluation at ',
     + f8.2,' seconds')
      write(iwr,6005) cpulft(1)
      kkdet=nstruc
      icicih=igmem_alloc(kkdet*(kkdet+1)/2)
c     icicih2=igmem_alloc(kkdet)
c     icicis2=igmem_alloc(kkdet)
      ihamil=igmem_alloc(kkdet*(kkdet+1)/2)
      ioverlap=igmem_alloc(kkdet*(kkdet+1)/2)
      call printmem(-8*nelec)
c
c <phi(n)|H-E|phi_m>
c
c q(i1) ci coeff psi_0
c q(i3) determinanten psi_0
c ci coeff nieuwe toestanden q(i41) en q(i21)
c determinanten nieuwe toestanden q(i51) en q(i31)
c volgorde ldet3, ldet2
c
      ia=0
      do kkdeti=1,kkdet
         do kkdetj=1,kkdeti
            ia=ind(kkdeti,kkdetj)
            call takecideriv(kkdeti,q(indetps),q(icoeff),q(ijdets),
     &                       ldet3,q(i51),q(i41),nelec)
            call takecideriv(kkdetj,q(indetps),q(icoeff),q(ijdets),
     &                       ldet2,q(i31),q(i21),nelec)
      call fillidetps(q(idetps),ldet2)
      call reorb(q(i31),ldet2,nelec,nalfa,q(iortho),q(iscrreorb),q(i21),
     &                                          q(idetps),ldet2)
      call fillidetps(q(idetps),ldet3)
      call reorb(q(i51),ldet3,nelec,nalfa,q(iortho),q(iscrreorb),q(i41),
     &                                          q(idetps),ldet3)
       if (kkdeti.eq.kkdetj) then
      call hathad(dd,ds,q(icp),q(jcp),q(ismat),q(ihmat),
     &            q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &            q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &            nelec,q(iortho),northo,nbody,ldet2,q(i31),q(i21),
     &            q(idetcomb),q(idettot))
                  else
            call hatham(dd,ds,q(icp),q(jcp),q(ismat),q(ihmat),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &             q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
       endif
            q(icicih+ia-1)=(2.0d0*(dd-ds*e0))/dnorm
            q(ihamil+ia-1)=dd
            q(ioverlap+ia-1)=ds
         enddo
      enddo
c     do kkdeti=1,kkdet
c        call dcopy(ldet,q(i1),1,q(i41),1)
c        call dcopy(ldet*nelec,q(i3),1,q(i51),1)
c        ldet3=ldet
c        call takecideriv(kkdeti,q(indetps),q(icoeff),q(ijdets),
c    &                    ldet2,q(i31),q(i21),nelec)
c     call fillidetps(q(idetps),ldet2)
c     call reorb(q(i31),ldet2,nelec,nalfa,q(iortho),q(iscrreorb),q(i21),
c    &                                          q(idetps),ldet2)
c     call fillidetps(q(idetps),ldet3)
c     call reorb(q(i51),ldet3,nelec,nalfa,q(iortho),q(iscrreorb),q(i41),
c    &                                          q(idetps),ldet3)
c        call hatham(dd,ds,q(icp),q(jcp),q(ismat),q(ihmat),
c    &          q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
c    &          q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
c    &          nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
c    &          q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
c        q(icicih2+kkdeti-1)=dd-ds*e0
c        q(icicis2+kkdeti-1)=ds
c     enddo
c     do kkdeti=1,kkdet
c        do kkdetj=1,kkdeti
c            ia=ind(kkdeti,kkdetj)
c            q(icicih+ia-1)=q(icicih+ia-1)-4.0d0*q(icicih2+kkdeti-1)*
c    &       q(icicis2+kkdetj-1)-4.0d0*q(icicih2+kkdetj-1)*
c    &       q(icicis2+kkdeti-1)
c            ddq1=q(icicih2+kkdeti-1)*q(icicis2+kkdetj-1)
c            ddq2=q(icicih2+kkdetj-1)*q(icicis2+kkdeti-1)
c            dtest=max(dtest,dabs(ddq1))
c            dtest=max(dtest,dabs(ddq2))
c        enddo
c     enddo
c     print *,'remco sec. deriv matrix of ci-coef'
c     call prtri(q(icicih),kkdet)
c       call diagmat(q,q(icicih),kkdet)
c
c calculated mixed components for a matrix
c
      icimixh=igmem_alloc(nsin*kkdet)
c
 6006 format(/1x,
     +'commence orbital/CI hessian evaluation at ',
     + f8.2,' seconds')
      write(iwr,6006) cpulft(1)
      ia=0
      do ifri=1,nscf
         ifr1=iex_prop(1,ifri)
         do itoi=1,nex_prop(ifri)
            ito1=iex_prop(1+itoi,ifri)
            ia=ia+1
            call create_exc(ldet,q(i1),q(i3),q(i21),q(i31),
     *      nelec,ifr1,ito1,ldet2,nalfa)
            do kkdeti=1,kkdet
               call takecideriv(kkdeti,q(indetps),q(icoeff),q(ijdets),
     &                          ldet3,q(i51),q(i41),nelec)
      call fillidetps(q(idetps),ldet2)
      call reorb(q(i31),ldet2,nelec,nalfa,q(iortho),q(iscrreorb),q(i21),
     &                                          q(idetps),ldet2)
      call fillidetps(q(idetps),ldet3)
      call reorb(q(i51),ldet3,nelec,nalfa,q(iortho),q(iscrreorb),q(i41),
     &                                          q(idetps),ldet3)
               call hatham(dd,ds,q(icp),q(jcp),q(ismat),q(ihmat),
     &                  q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &                  q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &                  nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &                  q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
               q(icimixh+kkdet*(ia-1)+kkdeti-1)=(2*(dd-ds*e0))/dnorm
            enddo
         enddo
      enddo
      do kkdeti=1,kkdet
         ia=0
         do ifri=1,nscf
             ifr1=iex_prop(1,ifri)
             do itoi=1,nex_prop(ifri)
                 ito1=iex_prop(1+itoi,ifri)
                 ia=ia+1
                 call takecideriv(kkdeti,q(indetps),q(icoeff),q(ijdets),
     &                            ldet3,q(i51),q(i41),nelec)
                 call create_exc(ldet3,q(i41),q(i51),q(i21),q(i31),
     &           nelec,ifr1,ito1,ldet2,nalfa)
                 call dcopy(ldet,q(i1),1,q(i41),1)
                 call dcopy(ldet*nelec,q(i3),1,q(i51),1)
                 ldet3=ldet
      call fillidetps(q(idetps),ldet2)
      call reorb(q(i31),ldet2,nelec,nalfa,q(iortho),q(iscrreorb),q(i21),
     &                                          q(idetps),ldet2)
      call fillidetps(q(idetps),ldet3)
      call reorb(q(i51),ldet3,nelec,nalfa,q(iortho),q(iscrreorb),q(i41),
     &                                          q(idetps),ldet3)
               call hatham(dd,ds,q(icp),q(jcp),q(ismat),q(ihmat),
     &                  q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &                  q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &                  nelec,q(iortho),northo,nbody,ldet2,ldet3,q(i31),
     &                  q(i51),q(i21),q(i41),q(idetcomb),q(idettot))
               q(icimixh+kkdet*(ia-1)+kkdeti-1)=
     &         q(icimixh+kkdet*(ia-1)+kkdeti-1)+
     &                                   (2*dfac*(dd-ds*e0))/dnorm
             enddo
         enddo
      enddo
c     do kkdeti=1,kkdet
c        ia=0
c        do ifri=1,nscf
c            ifr1=iex_prop(1,ifri)
c            do itoi=1,nex_prop(ifri)
c                ito1=iex_prop(1+itoi,ifri)
c                ia=ia+1
c              q(icimixh+kkdet*(ia-1)+kkdeti-1)=
c    &         q(icimixh+kkdet*(ia-1)+kkdeti-1)
c    &        -4*(q(icicih2+kkdeti-1)*q(icis2+ia-1))
c    &        -4*(q(icih2+ia-1)*q(icicis2+kkdeti-1))
c              ddq1=q(icicih2+kkdeti-1)*q(icis2+ia-1)
c              ddq2=q(icih2+ia-1)*q(icicis2+kkdeti-1)
c              dtest=max(dtest,dabs(ddq1))
c              dtest=max(dtest,dabs(ddq2))
c            enddo
c        enddo
c     enddo
c
c     print *,'remco sec. deriv matrix of mixed block'
c     call prsq(q(icimixh),nsin,kkdet,kkdet)
c     iamat=igmem_alloc((nsin+kkdet)*(nsin+kkdet))
c     ndimamat=nsin+kkdet
c     call symamat(q(iamat),ndimamat,q(icih),nsin,q(icicih),
c    &             kkdet,q(icimixh))
c     print *,'remco complete a-matrix'
c     call prsq(q(iamat),ndimamat,ndimamat,ndimamat)
c        itriangle=igmem_alloc(ndimamat*(ndimamat+1)/2)
c      call fillmatrix(q(iamat),q(itriangle),ndimamat)
c     call diagmat(q,q(itriangle),ndimamat)
c        call gmem_free(itriangle)
c     call gmem_free(iamat)
c
c  transform ci stuff to orthogonal complement
c
c     if (dabs(dtest).gt.1.0-d7.or.odebug) then
c        write(iwr,2012) dtest
c2012 format(/1x,' ** WARNING -- max brill element ',e10.4)
c     endif
c
_IF(parallel)
      ll1=kkdet*(kkdet+1)/2
      ll2=nsin*(nsin+1)/2
      ll3=nsin*kkdet
      call pg_dgop(105,q(ihamil),ll1,'+')
      call pg_dgop(106,q(ioverlap),ll1,'+')
      call pg_dgop(107,q(icicih),ll1,'+')
      call pg_dgop(108,q(icih),ll2,'+')
      call pg_dgop(109,q(icimixh),ll3,'+')
_ENDIF
      junk2=igmem_alloc(kkdet*kkdet)
      junk3=igmem_alloc(kkdet)
       imumu=max(kkdet*2,(kkdet*(kkdet)+(kkdet)*(kkdet)))
      junk4=igmem_alloc(kkdet*kkdet+kkdet*(kkdet+1)/2+imumu)
      if (odebug) then
         write(iwr,*)'hamiltonian matrix'
         call prtri(q(ihamil),kkdet)
         write(iwr,*)'overlap matrix'
         call prtri(q(ioverlap),kkdet)
      endif
      call jacobs(q(ihamil),kkdet,q(ioverlap),q(junk2),q(junk3),2,
     &            1.0d-20,q(junk4))
 6007 format(/1x,' ** eigenvalues and eigenvectors of H-matrix **',/)
      write(iwr,6001)
      write(iwr,6007) 
      call prvc(q(junk2),kkdet,kkdet,q(junk3),'v','l')
      write(iwr,6001)
c     print *,'remco eigenvectors'
c     call prsq(q(junk2),kkdet,kkdet,kkdet)
c     print *,'remco eigenvalues'
c     do i=1,kkdet
c       print *,q(junk3+i-1)
c     enddo
      call gmem_free(junk4)
      call gmem_free(junk3)
c transform icicih
      junk3=igmem_alloc(kkdet*(kkdet-1))
      junk4=igmem_alloc((kkdet-1)*kkdet/2)
      junk5=igmem_alloc(kkdet*(kkdet-1)+(kkdet-1)*(kkdet-1))
      call formdagger(q(junk2+kkdet),q(junk3),kkdet,kkdet-1)
c      print *,'remco dagger'
c      call prsq(q(junk3),kkdet,kkdet-1,kkdet-1)
      call mult11(q(icicih),q(junk4),q(junk5),kkdet-1,kkdet,
     &            q(junk2+kkdet),q(junk3))
      do i=1,kkdet*(kkdet-1)/2
         q(icicih+i-1)=q(junk4+i-1)
      enddo
c      print *,'remco transformed g'
c      call prtri(q(icicih),kkdet-1)
      call gmem_free(junk5)
      call gmem_free(junk4)
c transform icimixh  
      junk4=igmem_alloc((kkdet-1)*nsin)
      do i=1,nsin
         call transformmix(q(icimixh+kkdet*(i-1)),q(junk4+(kkdet-1)*
     &                     (i-1)),q(junk3),kkdet-1,kkdet)
      enddo
      call vclr(q(icimixh),1,nsin*kkdet)
      do i=1,nsin*(kkdet-1)
         q(icimixh+i-1)=q(junk4+i-1)
      enddo
      call gmem_free(junk4)
      kpdet=kkdet
      kkdet=kkdet-1
c
c
c form complete a-matrix
c
      iamat=igmem_alloc((nsin+kkdet)*(nsin+kkdet))
      ndimamat=nsin+kkdet
      call symamat(q(iamat),ndimamat,q(icih),nsin,q(icicih),
     &             kkdet,q(icimixh))
 6008 format(/1x,
     +'construction of hessian complete at ',
     + f8.2,' seconds')
      write(iwr,6008) cpulft(1)
      write(iwr,6001)
      if (odebug) then
        write(iwr,*)'remco complete a-matrix'
        call prsq(q(iamat),ndimamat,ndimamat,ndimamat)
      endif
      call flush(iwr)
c
c diagonalisation of a-matrix
c
c        itriangle=igmem_alloc(ndimamat*(ndimamat+1)/2)
c      call fillmatrix(q(iamat),q(itriangle),ndimamat)
c     call diagmat(q,q(itriangle),ndimamat)
c        call gmem_free(itriangle)
c
c
c
c     transform property CI stuff to orthogonal complement basis
c
      junk4=igmem_alloc(kkdet)
      call transformmix(q(ibx+nsin),q(junk4),
     &                  q(junk3),kkdet,kpdet)
      do i=1,kkdet
         q(ibx+nsin+i-1)=q(junk4+i-1)
      enddo
      call transformmix(q(iby+nsin),q(junk4),
     &                  q(junk3),kkdet,kpdet)
      do i=1,kkdet
         q(iby+nsin+i-1)=q(junk4+i-1)
      enddo
      call transformmix(q(ibz+nsin),q(junk4),
     &                  q(junk3),kkdet,kpdet)
      do i=1,kkdet
         q(ibz+nsin+i-1)=q(junk4+i-1)
      enddo
      call gmem_free(junk4)   
c
 6010 format(/1x,
     +'construction of property gradient complete at ',
     + f8.2,' seconds')
c     write(iwr,6010) cpulft(1)

c 
c ... remove redundancies from q(iamat), q(ibx), q(iby), and q(ibz)
c
         itriangle=igmem_alloc(ndimamat*(ndimamat+1)/2)
       call fillmatrix(q(iamat),q(itriangle),ndimamat)
        imatrix=igmem_alloc(ndimamat*(ndimamat+1)/2)
        iveckk=igmem_alloc(ndimamat*ndimamat)
        ieigkk=igmem_alloc(ndimamat)
        iscr1kk=igmem_alloc(ndimamat+1)
        iscr2kk=igmem_alloc(ndimamat*2)
c
       call jacodiag(q(itriangle),ndimamat,q(iveckk),q(ieigkk),
     &               q(iscr1kk),q(iscr2kk))
c      call prsq(q(iveckk),ndimamat,ndimamat,ndimamat)
       nzero=0
       ilast=0
       ifirst=0
       nneg=0
       do i=1,ndimamat
         if (q(ieigkk+i-1).lt.-1.0d-8) nneg=nneg+1
         if (dabs(q(ieigkk+i-1)).lt.1.0d-8) then
            nzero=nzero+1
            if (nzero.eq.1) then
               ifirst=i
               ilast=i
            else
               ilast=i
            endif
         endif
       enddo
       izz=ilast
       do i=ifirst-1,1,-1
           do j=1,ndimamat
             q(iveckk+ndimamat*(izz-1)+j-1)=q(iveckk+ndimamat*(i-1)+j-1)
           enddo
           izz=izz-1
       enddo
       if (nneg.gt.0) then
          write(iwr,6011) nneg
          call prvc(q(iveckk),nneg,ndimamat,q(ieigkk),'v','l')
       endif
 6011 format(/1x,' ** WARNING -- hessian has ',i5,
     &           ' negative eigenvalues'/)
       if (nzero.gt.0.and..not.oignore) then
 6012 format(/1x,' ** WARNING -- removing ',i5,' zero eigenvalues')
      write(iwr,6012) nzero
       call fillmatrix(q(iamat),q(itriangle),ndimamat)
c     
      junkred3=igmem_alloc(ndimamat*(ndimamat-nzero))
      junkred4=igmem_alloc((ndimamat-nzero)*(ndimamat-nzero+1)/2)
      junkred5=igmem_alloc(ndimamat*(ndimamat-nzero)+
     &                  (ndimamat-nzero)*(ndimamat-nzero))
      call formdagger(q(iveckk+ndimamat*nzero),q(junkred3),ndimamat,
     &ndimamat-nzero)
c      print *,'remco dagger'
c      call prsq(q(junkred3),kkdet,kkdet-1,kkdet-1)
      call mult11(q(itriangle),q(junkred4),q(junkred5),ndimamat-nzero,
     &            ndimamat,
     &            q(iveckk+nzero*ndimamat),q(junkred3))
      do i=1,(ndimamat-nzero)*(ndimamat-nzero+1)/2
         q(itriangle+i-1)=q(junkred4+i-1)
      enddo
       call symfill(q(itriangle),q(iamat),ndimamat-nzero)
      call gmem_free(junkred5)
      call gmem_free(junkred4)

      junkred4=igmem_alloc(ndimamat)
      call transformmix(q(ibx),q(junkred4),
     &                  q(junkred3),ndimamat-nzero,ndimamat)
      do i=1,ndimamat-nzero
         q(ibx+i-1)=q(junkred4+i-1)
      enddo
      call transformmix(q(iby),q(junkred4),
     &                  q(junkred3),ndimamat-nzero,ndimamat)
      do i=1,ndimamat-nzero
         q(iby+i-1)=q(junkred4+i-1)
      enddo
      call transformmix(q(ibz),q(junkred4),
     &                  q(junkred3),ndimamat-nzero,ndimamat)
      do i=1,ndimamat-nzero
         q(ibz+i-1)=q(junkred4+i-1)
      enddo
      ndimamat=ndimamat-nzero
      call gmem_free(junkred4)
       call gmem_free(junkred3)
      endif
       call gmem_free(iscr2kk)
       call gmem_free(iscr1kk)
       call gmem_free(ieigkk)
       call gmem_free(iveckk)
       call gmem_free(imatrix)

         call gmem_free(itriangle)
      if (odebug) then
        write(iwr,*)'remco complete a-matrix'
        call prsq(q(iamat),ndimamat,ndimamat,ndimamat)
        do i=1,ndimamat
           write(iwr,'(a,3F20.8)')'bmat x y z',q(ibx+i-1),
     &  q(iby+i-1),q(ibz+i-1)
      enddo
      endif
      write(iwr,6001)
      call flush(iwr)

c
c solve linear equations
c
 6015 format(/1x,
     +'commence solution of linear equations at ',
     + f8.2,' seconds')
      write(iwr,6015) cpulft(1)
      ilx=igmem_alloc(ndimamat)
      ily=igmem_alloc(ndimamat)
      ilz=igmem_alloc(ndimamat)
      iaa=igmem_alloc(ndimamat*ndimamat)
      iwk1=igmem_alloc(ndimamat)
      iwk2=igmem_alloc(ndimamat)
      call f04atf(q(iamat),ndimamat,q(ibx),ndimamat,q(ilx),q(iaa),
     1 ndimamat,q(iwk1),q(iwk2),ifail)
      if (ifail.ne.0) then
          write(iwr,*)'f04atf x failed',ifail
      endif
      call f04atf(q(iamat),ndimamat,q(iby),ndimamat,q(ily),q(iaa),
     1 ndimamat,q(iwk1),q(iwk2),ifail)
      if (ifail.ne.0) then
          write(iwr,*)'f04atf y failed',ifail
      endif
      call f04atf(q(iamat),ndimamat,q(ibz),ndimamat,q(ilz),q(iaa),
     1 ndimamat,q(iwk1),q(iwk2),ifail)
      if (ifail.ne.0) then
          write(iwr,*)'f04atf z failed',ifail
      endif
      call gmem_free(iwk2)
      call gmem_free(iwk1)
      call gmem_free(iaa)
      if (odebug) then
         do i=1,ndimamat
           write(iwr,'(a,3F20.8)')'xmat x y z',q(ilx+i-1),
     &       q(ily+i-1),q(ilz+i-1)
         enddo
         call flush(iwr)
      endif
c
      if (ovbci2) then
         write(iwr,6022)
 6022 format (//
     +   30x,'**********************************'/
     +   30x,'*     VBCI contributions         *'/
     +   30x,'**********************************'/)
          write(iwr,'(A)')
     +' struc     xx         xy         xz         yy         yz       
     +  zz'
      do i=nsin+1,ndimamat
          write(iwr,'(I5,6F11.4)')i-nsin+1,
     +  q(ilx-1+i)*q(ibx-1+i),
     +  q(ilx-1+i)*q(iby-1+i),
     +  q(ilx-1+i)*q(ibz-1+i),
     +  q(ily-1+i)*q(iby-1+i),
     +  q(ily-1+i)*q(ibz-1+i),
     +  q(ilz-1+i)*q(ibz-1+i)
      enddo
      write(iwr,6001)
      endif
      xxpol=1.0d0*ddot(ndimamat,q(ilx),1,q(ibx),1)
      yypol=1.0d0*ddot(ndimamat,q(ily),1,q(iby),1)
      zzpol=1.0d0*ddot(ndimamat,q(ilz),1,q(ibz),1)
      xypol=1.0d0*ddot(ndimamat,q(ilx),1,q(iby),1)
      xzpol=1.0d0*ddot(ndimamat,q(ilx),1,q(ibz),1)
      yzpol=1.0d0*ddot(ndimamat,q(ily),1,q(ibz),1)
c
c... print out results
c
      write(iwr,6001)
 6030 format (//
     +   30x,'**********************************'/
     +   30x,'* static second order properties *'/
     +   30x,'**********************************'/)
 6060 format (/10x,a1,3f15.7)
 6070 format (//10x,'========================='/
     +          10x,'= polarizability tensor ='/
     +          10x,'========================='//
     +          10x,'in atomic units (bohr**3)'//
     +              18x,a1,14x,a1,14x,a1)
 6075 format (//10x,'=============================================='/
     +          10x,'= magnetisability tensor (paramagnetic part) ='/
     +          10x,'=============================================='//
     +          10x,'in atomic units (bohr**3)'//
     +              18x,a1,14x,a1,14x,a1)
      write(iwr,6030)
      if (opol) then
         write(iwr,6070)'x','y','z'
      elseif (omag) then
         write(iwr,6075)'x','y','z'
      endif
      write(iwr,6060)'x',xxpol,xypol,xzpol
      write(iwr,6060)'y',xypol,yypol,yzpol
      write(iwr,6060)'z',xzpol,yzpol,zzpol
      if (ouncoupled) then
 6031 format (//
     +   30x,'***********************************'/
     +   30x,'* static uncoupled polarisability *'/
     +   30x,'***********************************'/)
         xxpolu=0.0d0
         yypolu=0.0d0
         zzpolu=0.0d0
         xypolu=0.0d0
         xzpolu=0.0d0
         yzpolu=0.0d0
         do i=1,nsin
            xxpolu=xxpolu+(q(idx+i-1)*q(idx+i-1))/q(ide+i-1)
            xypolu=xypolu+(q(idx+i-1)*q(idy+i-1))/q(ide+i-1)
            xzpolu=xzpolu+(q(idx+i-1)*q(idz+i-1))/q(ide+i-1)
            yzpolu=yzpolu+(q(idy+i-1)*q(idz+i-1))/q(ide+i-1)
            yypolu=yypolu+(q(idy+i-1)*q(idy+i-1))/q(ide+i-1)
            zzpolu=zzpolu+(q(idz+i-1)*q(idz+i-1))/q(ide+i-1)
         enddo
         write(iwr,6031)
         write(iwr,6070)'x','y','z'
         write(iwr,6060)'x',xxpolu,xypolu,xzpolu
         write(iwr,6060)'y',xypolu,yypolu,yzpolu
         write(iwr,6060)'z',xzpolu,yzpolu,zzpolu
 6032 format (//
     +   30x,'*******************'/
     +   30x,'* matrix elements *'/
     +   30x,'*******************'/)
         write(iwr,6032)
         write(iwr,6034)
         ia=0
 6033 format(I5,' --> ',I5,4F10.5)
 6034 format('   excitation   delta E      x          y         z',/,
     +'---------------------------------------------------------')
         do ifri=1,nscf
            ifr=iex_prop(1,ifri)
            do itoi=1,nex_prop(ifri)
                ito=iex_prop(1+itoi,ifri)
                ia=ia+1
                write(iwr,6033)ifr,ito,q(ide+ia-1),q(idx+ia-1),
     +                          q(idy+ia-1),q(idz+ia-1)
            enddo
         enddo
      endif
      if (omag) then
 6080 format (//10x,'============================================='/
     +          10x,'= magnetisability tensor (diamagnetic part) ='/
     +          10x,'============================================='//
     +          10x,'in atomic units (bohr**3)'//
     +              18x,a1,14x,a1,14x,a1)
      nx=nbasis*(nbasis+1)/2
      iqu1=igmem_alloc(nx)
      iqu2=igmem_alloc(nx)
      iqu3=igmem_alloc(nx)
      iqu4=igmem_alloc(nx)
      iqu5=igmem_alloc(nx)
      iqu6=igmem_alloc(nx)
      iqu7=igmem_alloc(nx)
      call qmints(q(iqu1),q(iqu2),q(iqu3),q(iqu4),q(iqu5),q(iqu6))
c
      call dcopy(nx,q(iqu1),1,q(iqu7),1)
      call vclr(q(iqu1),1,nx)
      call remtrans2(q(iqu7),q(iqu1),q(kvec),nbasis,ncol)
      call dcopy(nx,q(iqu2),1,q(iqu7),1)
      call vclr(q(iqu2),1,nx)
      call remtrans2(q(iqu7),q(iqu2),q(kvec),nbasis,ncol)
      call dcopy(nx,q(iqu3),1,q(iqu7),1)
      call vclr(q(iqu3),1,nx)
      call remtrans2(q(iqu7),q(iqu3),q(kvec),nbasis,ncol)
      call dcopy(nx,q(iqu4),1,q(iqu7),1)
      call vclr(q(iqu4),1,nx)
      call remtrans2(q(iqu7),q(iqu4),q(kvec),nbasis,ncol)
      call dcopy(nx,q(iqu5),1,q(iqu7),1)
      call vclr(q(iqu5),1,nx)
      call remtrans2(q(iqu7),q(iqu5),q(kvec),nbasis,ncol)
      call dcopy(nx,q(iqu6),1,q(iqu7),1)
      call vclr(q(iqu6),1,nx)
      call remtrans2(q(iqu7),q(iqu6),q(kvec),nbasis,ncol)
      if (odebug) then
         write(iwr,*)'quadrupole integrals xx,yy,zz,xy,xz,yz'
         call prtri(q(iqu1),ncol)
         call prtri(q(iqu2),ncol)
         call prtri(q(iqu3),ncol)
         call prtri(q(iqu4),ncol)
         call prtri(q(iqu5),ncol)
         call prtri(q(iqu6),ncol)
      endif
c
      ocomplex=.false.
      call fillidetps(q(idetps),ldet)
      iresdd=igmem_alloc(6)
      iresds=igmem_alloc(6)
      call reorb(q(i3),ldet,nelec,nalfa,q(iortho),q(iscrreorb),q(i1),
     &                                          q(idetps),ldet)
            call prop_hatham(q(iresdd),q(iresds),q(icp),q(jcp),
     &             q(ismat),q(iqu1),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet,ldet,q(i3),
     &             q(i3),q(i1),q(i1),q(idetcomb),q(idettot))
      call fillidetps(q(idetps),ldet)
      call reorb(q(i3),ldet,nelec,nalfa,q(iortho),q(iscrreorb),q(i1),
     &                                          q(idetps),ldet)
            call prop_hatham(q(iresdd+1),q(iresds+1),q(icp),q(jcp),
     &             q(ismat),q(iqu2),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet,ldet,q(i3),
     &             q(i3),q(i1),q(i1),q(idetcomb),q(idettot))
      call fillidetps(q(idetps),ldet)
      call reorb(q(i3),ldet,nelec,nalfa,q(iortho),q(iscrreorb),q(i1),
     &                                          q(idetps),ldet)
            call prop_hatham(q(iresdd+2),q(iresds+2),q(icp),q(jcp),
     &             q(ismat),q(iqu3),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet,ldet,q(i3),
     &             q(i3),q(i1),q(i1),q(idetcomb),q(idettot))
      call fillidetps(q(idetps),ldet)
      call reorb(q(i3),ldet,nelec,nalfa,q(iortho),q(iscrreorb),q(i1),
     &                                          q(idetps),ldet)
            call prop_hatham(q(iresdd+3),q(iresds+3),q(icp),q(jcp),
     &             q(ismat),q(iqu4),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet,ldet,q(i3),
     &             q(i3),q(i1),q(i1),q(idetcomb),q(idettot))
      call fillidetps(q(idetps),ldet)
      call reorb(q(i3),ldet,nelec,nalfa,q(iortho),q(iscrreorb),q(i1),
     &                                          q(idetps),ldet)
            call prop_hatham(q(iresdd+4),q(iresds+4),q(icp),q(jcp),
     &             q(ismat),q(iqu5),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet,ldet,q(i3),
     &             q(i3),q(i1),q(i1),q(idetcomb),q(idettot))
      call fillidetps(q(idetps),ldet)
      call reorb(q(i3),ldet,nelec,nalfa,q(iortho),q(iscrreorb),q(i1),
     &                                          q(idetps),ldet)
            call prop_hatham(q(iresdd+5),q(iresds+5),q(icp),q(jcp),
     &             q(ismat),q(iqu6),
     &             q(igmat+1),q(ig),q(iipos),q(iweight),nalfa,
     &             q(iscr1),q(iscr2),q(iscr3),q(is),q(ig2),
     &             nelec,q(iortho),northo,nbody,ldet,ldet,q(i3),
     &             q(i3),q(i1),q(i1),q(idetcomb),q(idettot))
_IF(parallel)
      ll4=6
      call pg_dgop(110,q(iresdd),ll4,'+')
      call pg_dgop(111,q(iresds),ll4,'+')
_ENDIF
      dxx=q(iresdd)/q(iresds)
      dyy=q(iresdd+1)/q(iresds+1)
      dzz=q(iresdd+2)/q(iresds+2)
      dxy=q(iresdd+3)/q(iresds+3)
      dxz=q(iresdd+4)/q(iresds+4)
      dyz=q(iresdd+5)/q(iresds+5)
      call gmem_free(iresds)
      call gmem_free(iresdd)
c
      call gmem_free(iqu7)
      call gmem_free(iqu6)
      call gmem_free(iqu5)
      call gmem_free(iqu4)
      call gmem_free(iqu3)
      call gmem_free(iqu2)
      call gmem_free(iqu1)
      xxdi=-0.25d0*(dyy+dzz)
      yydi=-0.25d0*(dxx+dzz)
      zzdi=-0.25d0*(dyy+dxx)
      xydi=0.25d0*dxy
      yzdi=0.25d0*dyz
      xzdi=0.25d0*dxz
c
      write(iwr,6080)'x','y','z'
      write(iwr,6060)'x',xxdi,xydi,xzdi
      write(iwr,6060)'y',xydi,yydi,yzdi
      write(iwr,6060)'z',xzdi,yzdi,zzdi
 6085 format (//10x,'=========================='/
     +          10x,'= magnetisability tensor ='/
     +          10x,'=========================='//
     +          10x,'in atomic units (bohr**3)'//
     +              18x,a1,14x,a1,14x,a1)
      xxpol=xxpol+xxdi
      yypol=yypol+yydi
      zzpol=zzpol+zzdi
      xypol=xypol+xydi
      yzpol=yzpol+yzdi
      xzpol=xzpol+xzdi
      write(iwr,6085)'x','y','z'
      write(iwr,6060)'x',xxpol,xypol,xzpol
      write(iwr,6060)'y',xypol,yypol,yzpol
      write(iwr,6060)'z',xzpol,yzpol,zzpol
      endif
c
c
 6014 format(///1x,
     +'calculation of second order VB response properties complete at ',
     + f8.2,' seconds')
      write(iwr,6014) cpulft(1)
      write(iwr,6001)
      call flush(iwr)
      call gmem_free(ilz)
      call gmem_free(ily)
      call gmem_free(ilx)
c
      call gmem_free(iamat)
c release memory      
      call gmem_free(junk3)
      call gmem_free(junk2)
c
      call gmem_free(icimixh)
      call gmem_free(ioverlap)
      call gmem_free(ihamil)
c     call gmem_free(icicis2)
c     call gmem_free(icicih2)
      call gmem_free(icicih)
c     call gmem_free(icis2)
c     call gmem_free(icih2)
c
      if (ouncoupled) then
         call gmem_free(idz)
         call gmem_free(idy)
         call gmem_free(idx)
         call gmem_free(ide)
      endif
      call gmem_free(icih)
      call gmem_free(ibz)
      call gmem_free(iby)
      call gmem_free(ibx)
      call gmem_free(iz)
      call gmem_free(iy)
      call gmem_free(ix)
      call gmem_free(i51)
      call gmem_free(i41)
      call gmem_free(i31)
      call gmem_free(i21)
      call gmem_free(iscrreorb)
      call gmem_free(idetps)
      call gmem_free(ig2)
      call gmem_free(is)
      call gmem_free(iipos)
      call gmem_free(iweight)
      call gmem_free(jcp)
      call gmem_free(icp)
      call gmem_free(ig)
      call gmem_free(iscr3)
      call gmem_free(iscr2)
      call gmem_free(iscr1)
      call gmem_free(idettot)
      call gmem_free(idetcomb)
      call gmem_free(iortho)
      call gmem_free(igmat)
      call gmem_free(ihmat)
      call gmem_free(ismat)
      call gmem_free(kvec)
      call gmem_free(i3)
      call gmem_free(i2)
      call gmem_free(i1)
      call gmem_free(ijdets)
      call gmem_free(icoeff)
      call gmem_free(indetps)
c
      nsa=nsaold
      return
      end

      subroutine setqig(ig)
      implicit REAL (a-h,o-z)
      dimension ig(*)
      ig(1) = 0
      ig(2) = 0
      ig(3) = 0
      ig(4) = 0
      ig(5) = 1
      return
      end

      subroutine printwave(ldet,ci,idet,nelec)
      implicit REAL (a-h,o-z)
INCLUDE(../m4/common/iofile)
      dimension ci(*),idet(nelec,*)
      write(iwr,*)'remco in printwave'
      do i=1,ldet
        write(iwr,'(A,I5,A,F10.5)')'Det',i,' coef',ci(i)
        write(iwr,'(30I3)')(idet(il,i),il=1,nelec)
      enddo
      call flush(6)
      return
      end

      subroutine getwave(ci,pack,idet,idet2,igroup,nel,nelec,
     *ndub,nalfa)
      implicit REAL (a-h,o-z)
INCLUDE(common/c8_16vb)
INCLUDE(../m4/common/restri)
INCLUDE(../m4/common/iofile)
      dimension ci(*),pack(*),idet(*),igroup(5,*),idet2(*)
      call secget(isect(79),79,ib)
      ib=ib+1
      kl=(igroup(1,1)*nel-1)/(64/n8_16) + 1
      call rdedx(ci,igroup(1,1),ib,idaf)
      ib=ib+lensec(igroup(1,1))
      call rdedx(pack,kl,ib,idaf)
      nl=igroup(1,1)*nel
      call unpack(pack,n8_16,idet2,nl)
      nbeta=nelec-nalfa
      is_nel=1
      is_nelec=1
      do i=1,igroup(1,1)
         do j=1,ndub
            idet(is_nelec)=j
            is_nelec=is_nelec+1
         enddo
         naf=nalfa-ndub
         do j=1,naf
            idet(is_nelec)=idet2(is_nel)+ndub
            is_nelec=is_nelec+1
            is_nel=is_nel+1
         enddo
         do j=1,ndub
            idet(is_nelec)=j
            is_nelec=is_nelec+1
         enddo
         naf=nbeta-ndub
         do j=1,naf
            idet(is_nelec)=idet2(is_nel)+ndub
            is_nelec=is_nelec+1
            is_nel=is_nel+1
         enddo
      enddo
      return
      end

      subroutine getwave3(ci,pack,idet,idet2,igroup,nel,nelec,
     *ndub,nalfa)
      implicit REAL (a-h,o-z)
INCLUDE(common/c8_16vb)
INCLUDE(../m4/common/restri)
INCLUDE(../m4/common/iofile)
      dimension ci(*),pack(*),idet(*),igroup(5,*),idet2(*)
      call secget(isect(79),79,ib)
      ib=ib+1
      kl=(igroup(1,1)*nel-1)/(64/n8_16) + 1
      call rdedx(ci,igroup(1,1),ib,idaf)
      ib=ib+lensec(igroup(1,1))
      call rdedx(pack,kl,ib,idaf)
      nl=igroup(1,1)*nel
      call unpack(pack,n8_16,idet,nl)
      return
      end


      subroutine create_exc(ndet,coeff,idet,bcoeff,ibdet,nelec,
     *ifr,ito,nb,nalfa)
      implicit REAL (a-h,o-z)
      dimension idet(nelec,*),ibdet(nelec,*)
      dimension bcoeff(*),coeff(*)
      dimension dsign(2)
c     call dcopy(ndet,coeff,1,bcoeff,1)
c      print *,'remco in create',(bcoeff(i),i=1,ndet)
      nb=0
      it=0
      is=it
      do 80 k=1,ndet
          call bcreat2(idet(1,k),nelec,nalfa,ibdet(1,nb+1),nbb,
     &                ifr,ito,dsign)
          l = nb
77        if (l.lt.nb+nbb) then
             l = l + 1
             do 65 m=1,nb
                isignq = isame(ibdet(1,m),ibdet(1,l),
     &                   ibdet(1,nb+nbb+1),nelec,nalfa)
                if (isignq.ne.0) then
                   bcoeff(is+m) = bcoeff(is+m)
c    &             + isignq * coeff(k) * iflip(ifr,ito)
     &             + isignq * coeff(k) * dsign(l-nb)
                   l = l - 1
                   nbb = nbb - 1
                   if (l.lt.nb+nbb) then
                      do 63 n=1,nelec
 63                   ibdet(n,l+1) = ibdet(n,l+2)
                   end if
                   go to 77
               end if
65           continue
             it = it + 1
             bcoeff(it) = coeff(k) * dsign(l-nb) 
             go to 77
          end if
          nb = nb + nbb
80    continue
      call ordermo(nb,ibdet,bcoeff,nelec,nalfa)
      return
      end

      subroutine bubble_sort(idata,icount,nperm)
      implicit REAL (a-h,o-z)
      dimension idata(icount)
c
      ipass = 1
      nperm=0
 1    continue
      isorted = 1
      do 2 i = 1,icount-ipass
        if(idata(i) .gt. idata(i+1)) then
          itemp = idata(i)
          idata(i) = idata(i+1)
          idata(i+1) = itemp
          isorted = 0
          nperm=nperm+1
        endif
 2    continue
      ipass = ipass +1
      if(isorted .eq. 0) goto 1 
      return
      end

      subroutine ordermo(nb,ibdet,ci,nelec,nalfa)
      implicit REAL (a-h,o-z)
      dimension ibdet(nelec,*),ci(nb)
      nbeta=nelec-nalfa
      do idet=1,nb
c     write(iwr,'(a20,I2,F10.7,10I2)')"in ordermo start",
c    &idet,ci(idet),(ibdet(jj,idet),jj=1,nelec)
         dsign=1.0d0
         np=0
         call bubble_sort(ibdet(1,idet),nalfa,npa)
         call bubble_sort(ibdet(nalfa+1,idet),nbeta,npb)
         dsign=(-1.0)**(npa+npb)
         ci(idet)=dsign*ci(idet)
c     write(iwr,'(a20,I2,F10.7,10I2)')"in ordermo end",
c    &idet,ci(idet),np,(ibdet(jj,idet),jj=1,nelec)
      enddo
      return
      end

      subroutine bcreat2(idet,nelec,nalfa,ibdet,nbb,
     &                ifr,ito,dsign)
      implicit REAL (a-h,o-z)
INCLUDE(../m4/common/iofile)
      dimension idet(nelec,*),ibdet(nelec,*)
      dimension dsign(2)
      logical oan,oncreat
c
c     print *,'remco input det',(idet(jj,1),jj=1,nelec)
c     print *,'remco',ifr,ito
      dsign(1)=1.0d0
      dsign(2)=1.0d0
      nbb=0
c alpha excitation
      do i=1,nelec
         ibdet(i,nbb+1)=idet(i,1)
      enddo
      oan=.false.
      oncreat=.false.
      do i=1,nalfa
         if (ibdet(i,nbb+1).eq.ifr) then
c there is one to annihilate
            if (oan) then
               write(iwr,*) 'remco ifr',ifr,ito
      write(iwr,*)'remco det alpha',(ibdet(jj,nbb+1),jj=1,nalfa)
               call caserr('error in annihilation')
            endif
            ian=i
            oan=.true.
         endif
         if (ibdet(i,nbb+1).eq.ito) then
            oncreat=.true.
         endif
      enddo
      if (oan.and..not.oncreat) then
c
         nbb=nbb+1
         if (ian.ne.1) then
            ih=ibdet(ian,nbb)
            ibdet(ian,nbb)=ibdet(1,nbb)
            ibdet(1,nbb)=ih
            dsign(nbb)=-dsign(nbb)
         endif
         ibdet(1,nbb)=ito
      endif
c
c beta excitation
c
      do i=1,nelec
         ibdet(i,nbb+1)=idet(i,1)
      enddo
      oan=.false.
      oncreat=.false.
      do i=nalfa+1,nelec
         if (ibdet(i,nbb+1).eq.ifr) then
c there is one to annihilate
            if (oan) then
               write(iwr,*)'remco ifr',ifr,ito
      write(iwr,*)'remco det beta',(ibdet(jj,nbb+1),jj=nalfa+1,nelec)
               call caserr('error in annihilation')
            endif
            ian=i
            oan=.true.
         endif
         if (ibdet(i,nbb+1).eq.ito) then
            oncreat=.true.
         endif
      enddo
      if (oan.and..not.oncreat) then
c 
         nbb=nbb+1
         if (ian.ne.1) then
            ih=ibdet(ian,nbb)
            ibdet(ian,nbb)=ibdet(1,nbb)
            ibdet(1,nbb)=ih
            dsign(nbb)=-dsign(nbb)
         endif
         ibdet(1,nbb)=ito
         if (ian.ne.1) then
            ih=ibdet(ian,nbb)
            ibdet(ian,nbb)=ibdet(1,nbb)
            ibdet(1,nbb)=ih
            dsign(nbb)=-dsign(nbb)
         endif
      endif
      return
      end

      subroutine prop_hatham(detcomb,dettot,icp,jcp,supers,superh,
     &                  superg,ig,ipos,weight,nalfa,scr1,scr2,scr3,s,g,
     &                  nelec,iortho,northo,nbody,ndeti,ndetj,idet,jdet,
     &                  trani,tranj,scr4,scr5)
      implicit REAL   (a-h,o-z) ,  integer   (i-n)
c.....
c.....in this routine the matrix elements between the determinants as
c.....defined in idet and jdet are calculated and at the same time
c.....are processed to yield the total matrix-element
c.....
      dimension icp(*),jcp(*),supers(*),
     &          superg(*),superh(*),ig(*),ipos(*),weight(*),scr1(*),
     &          scr2(*),scr3(*),s(*),g(*),iortho(*),idet(*),jdet(*),
     &          trani(*),tranj(*),scr4(*),scr5(*)
      common /vblimit/ nsing,ifix,jfix,kfix,lfix,
     &               is1,is2,is3,is4,nrectan,ialfa,is01,is02
INCLUDE(../m4/common/iofile)
_IF(parallel)
INCLUDE(common/parinf)
_ENDIF
      ii = 1
      jj = 1
      call vclr(scr4,1,ndetj)
      call vclr(scr5,1,ndetj)
      do 40 i=1,ndeti
c.....
c.....   copies of the determinants must be made because of the pivot
c.....   search that can cause parity changes
c.....
         do 30 j=1,ndetj
_IF(parallel)
_IFN(parstruc)
            icounter = icounter + 1
            if (ido.lt.icounter) ido = ipg_dlbtask()
c         write(iwr,*) 'i have to do determinant',ido,' am at ',icounter
            if (ido.ne.icounter) then
               jj = jj + nelec
               go to 30
            end if
_ENDIF
_ENDIF
            do 20 k=1,nelec
               jcp(k) = jdet(k+jj-1)
               icp(k) = idet(k+ii-1)
20          continue
c.....
c.....      find the blocking structure of this matrix element
c.....
            call symblo(icp,jcp,nelec,nalfa,iortho,northo,supers,
     &                                          ipos,dprod,nbody,ig,s)
c           call sillyy(nelec,nalfa,ig,nbody,icp,jcp,supers)
            if (nsing.le.2) then
               call prop_matre3(detcomb,dettot,icp,jcp,
     &                     supers,superh,superg,
     &                     ig,nbody,nelec,
     &                     ipos,weight,nalfa,dprod,
     &                     scr1,scr2,scr3,s,g)
c              call sillyy(nelec,nalfa,ig,nbody,icp,jcp,supers)
               scr4(j) = scr4(j) + detcomb * trani(i)
               scr5(j) = scr5(j) + dettot * trani(i)
            end if
            it = it + 1
            jj = jj + nelec
30       continue
         ii = ii + nelec
         jj = 1
40    continue
      detcomb = ddot(ndetj,scr4,1,tranj,1)
      dettot  = ddot(ndetj,scr5,1,tranj,1)
      return
      end

      subroutine prop_matre3(value,det,ir,ic,supers,superh,superg,ig,
     &          nblock,
     &          nelec,ipos,w,nalfa,dprod,scr1,scr2,scr3,s,g)
c
      implicit REAL   (a-h,o-z) , integer   (i-n)
c
c.....
c.....in this routine the matrix element is calculated
c.....three main cases are distinguished : nsing=0,1,2, where nsing
c.....denotes the number of singularities in the s-matrix.
c.....in singular cases the number of rectangular blocks is determinant
c.....for the algorithm chosen. the (symbolic) blocking structure of
c.....the matrix element is contained in the common-block /vblimit
c.....nsing is the number of singularities. i/j/k/lfix indicate rows
c.....(i/j) and columns (k/l) of zeros in the overlap-matrix. is1 to is4
c.....are the block-numbers of the singular (rectangular) blocks in the
c.....overlap-matrix. nrectan is the number of them. ialfa is the number
c.....of blocks corresponding to electrons with alpha spin.
c.....the array ig(5,nblock) contains
c.....
c.....       ig(1,i) :   rows in i-th block
c.....       ig(2,i) :   cols in i-th block
c.....       ig(3,i) :  first row-number of i-th block
c.....       ig(4,i) :  first col-number of i-th block
c.....       ig(5,i) :  adress of the first element of block  i in s
c.....
      logical equal
c.....
c.....dimension arrays : = nelec
c.....
      dimension ir(*),ic(*)
c.....
c.....                   = nelec**2
c.....
      dimension s(*)
c.....
c.....                   = 5 * nblock
c.....
      dimension ig(5,*)
c.....
c.....                   = (nelec*(nelec-1)/2)**2
c.....
      dimension ipos(*),w(*),scr1(*),scr2(*),scr3(*),g(*)
c.....
c.....integral supermatrices
c.....
      dimension superg(*),superh(*),supers(*)
      external iparity
c.....
INCLUDE(common/vblimit)
      common /stats_vb/ noccurr(35)
INCLUDE(../m4/common/iofile)
INCLUDE(common/turtleparam)
INCLUDE(common/vbproper)
c.....
c     for debugging, determinants are give via symblo
c     in common /detcop/
CC    k2 = nelec**2+1
CC    call matre2(valu2,supers,superh,superg,
CC   &            w,w(k2),nelec,nalfa,
CC   &            scr1,scr3,g,det2)
c     value = valu2
c     det   = det2
c     return
c.....
c     print *,'nalfa nbeta',nalfa,nelec-nalfa,nelec
c     write(iwr,'(A3,20I3)') 'ir ',(ir(j),j=1,nelec)
c     write(iwr,'(A3,20I3)') 'ic ',(ic(j),j=1,nelec)
c     do i=1,nalfa
c       write(iwr,'(10F12.8)') (s(j+(i-1)*nalfa),j=1,nalfa)
c     end do
c     print *
c     do i=1,nelec-nalfa
c       write(iwr,'(10F12.8)') (s(j+(i-1)*nelec-nalfa),j=1,nelec-nalfa)
c     end do 
c     print *
      value  = 0.0d0
      det    = 0.0d0
      if (nsing.eq.0) then
c.....
         icase = 1
c.....
c
c        x x x . . . . . . . . .
c        x x x . . . . . . . . .
c        x x x . . . . . . . . .
c        . . . x x x . . . . . .
c        . . . x x x . . . . . .
c        . . . x x x . . . . . .
c        . . . . . . x x x . . .
c        . . . . . . x x x . . .
c        . . . . . . x x x . . .
c        . . . . . . . . . x x x
c        . . . . . . . . . x x x
c        . . . . . . . . . x x x
c
c.....
c.....   no singularities, therefore a straightforward calculation
c.....
         det = dprod
c.....
c.....   one-electron contribution per block
c.....
         do 10 i=1,nblock
            call cik( s(ig(5,i)), w(ig(5,i)), scr1,scr2,ig(1,i))
10       continue
         nt = ig(5,nblock) + ig(1,nblock) * ig(1,nblock)
         n1 = nt - 1
c.....
c.....   two electron contribution involving one block at a time
c.....
c         do 20 i=1,nblock
c            call cikjl(w(nt),ig(1,i),w(ig(5,i)))
c            ii  = ig(1,i)*(ig(1,i)-1)/2
c            nt  = nt + ii * ii
c20       continue
c         n2a = nt - n1  - 1
c         call wmix(w(nt),w,nblock,ig,n2b)
c         nt  = nt  + n2b - 1
c         n2  = n2a + n2b
c.....
c.....   now determine integral addresses
c.....
          call pik_prop(ipos,ir,ic,ig,nblock,g)
c         n   = n1 + 1
c         call pikjl(ipos(n),ipos(n2+n),ir,ic,ig,nblock)
c.....
c.....   mixed contributions
c.....
c         n = n + n2a
c         call gmix(ipos(n),ipos(n2+n),ir,ic,ig,nblock,ialfa)
         call gather_prop(n1 ,g ,superh,ipos  )
c         call gather(2*(n2a+n2b),g(n1+1),superg,ipos(n1+1))
c         call subvec(g(n1+1),g(n1+1),g(nt+1),nt-n1)
c        value = ddot(nt,g,1,w,1) * dprod
         value = ddot(n1,g,1,w,1) * dprod
c.....
      else if (nsing.eq.1) then
c.....
         if (nrectan.eq.0) then
c.....
            if (ifix.eq.0) then
c.....
               icase = 2
c.....
c
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . 0 0 0 . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
               call c00( s(ig(5,is0)),ig(1,is0),w )
               n1 = ig(1,is0) * ig(1,is0)
               n  = n1 + 1
c.....
c.....         two electron part involving "true" second order cofactors
c.....         of the singular block
c.....
c               call c0000(ig(1,is0),w(n),scr1,scr2,scr3,s(ig(5,is0)))
c               n2a = (ig(1,is0) * (ig(1,is0)-1) / 2)
c               n2a = n2a * n2a
c               n   = n + n2a
c.....
c.....         mixed contributions involving the singular block always
c.....
c               iscr = 1
c               do 60 i=1,nblock
c                  if(i.ne.is0) then
c                     call cik(s(ig(5,i)),scr1(iscr),scr2,scr3,ig(1,i))
c                     iscr = iscr + ig(1,i) * ig(1,i)
c                  end if
c60             continue
c               call wmix0(w(n),w,n1,scr1,iscr-1,n2b)
c               nt = n + n2b
                call p00_prop( ipos,ir(ig(3,is0)),ic(ig(4,is0)),
     &                        ig(1,is0),g)
c               n  = n1 + 1
c               call p0000(ipos(n),ipos(nt),ir(ig(3,is0)),ic(ig(4,is0)),
c     &                                                        ig(1,is0))
c               call gmix0(ipos(n+n2a),ipos(nt+n2a),ir,ic,ig,nblock,is0,
c     &                                                            ialfa)
               call gather_prop(n1         ,g   ,superh,ipos   )
c               call gather(2*(n2a+n2b),g(n),superg,ipos(n))
c               call subvec(g(n),g(n),g(nt),n2a+n2b)
c              value  = ddot(nt-1,g,1,w,1) * dprod
               value  = ddot(n1,g,1,w,1) * dprod
c.....
            else
c.....
               icase = 3
c.....
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . . . . . . . . . .
c              . . . . x x . . . . . .
c              . . . . x x . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
c.....         for one-electron part just one integral
c.....
               ipar = iparity(ig)
               irf     = ir(ifix)
               icf     = ic(kfix)
               ipos(1) = max0(irf,icf)*(max0(irf,icf)-1)/2+min0(irf,icf)
               w(1)    = 1.0d0
c.....
c.....         second order cofactors are first order really
c.....
c               do 50 i=1,nblock
c                  call cik( s(ig(5,i)),w(ig(5,i)+1),scr1,scr2,ig(1,i))
c50             continue
c.....
c               n = ig(5,nblock) + ig(1,nblock) * ig(1,nblock)
c               call pik00(ipos(2),ipos(n+1),ir,ic,ifix,kfix,ig,
c     &                                               nblock,nalfa,ialfa)
                if (ocomplex) then
                   if (irf.lt.icf) then
                      ds=-1.0d0
                   else
                      ds=1.0d0
                   endif
                else
                   ds=1.0d0
                endif
               g(1) = ds*superh(ipos(1))
c               call gather(2*(n-1),g(2),superg,ipos(2))
c               call subvec(g(2),g(2),g(n+1),n-1)
c               value = ddot(n,g,1,w,1) * dprod * ipar
               value=g(1)*dprod*ipar
            end if
c.....
         else if(nrectan.eq.1) then
c.....
            if (ifix.ne.0) then
c.....
               icase = 4
c.....
c              x x x . . . . . . . . .
c              x x x . . . . . . . . .
c              . . . x x x . . . . . .
c              . . . x x x . . . . . .
c              . . . x x x . . . . . .
c              . . . . . . . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
               ipar = iparity(ig)
c.....
c.....         one electron part involves those choices of k that make
c.....         the singular block become square
c.....
               call c0k( s(ig(5,is1)),ig(2,is1),w )
               n1 = ig(2,is1)
               n  = n1 + 1
c.....
c.....         two electron part involving "true" second order cofactors
c.....         of the singular block
c.....
c               call c0kjl(ig(2,is1),w(n),scr1,scr2,scr3,s(ig(5,is1)))
c               n2a = (ig(2,is1) * (ig(2,is1)-1) / 2) * ig(1,is1)
c               n   = n + n2a
c.....
c.....         mixed contributions involving the rectangle always
c.....
c               iscr = 1
c               do 67 i=1,nblock
c                  if(i.ne.is1) then
c                     call cik(s(ig(5,i)),scr1(iscr),scr2,scr3,ig(1,i))
c                     iscr = iscr + ig(1,i) * ig(1,i)
c                  end if
c67             continue
c               call wmix0(w(n),w,ig(2,is1),scr1,iscr-1,n2b)
c               nt = n + n2b
                call p0k_prop( ipos,ir(ifix),ic(ig(4,is1)),ig(2,is1),g)
c               n  = n1 + 1
c               call p0kjl(ipos(n),ipos(nt),ir(ifix),ir(ig(3,is1)),
c     &                                             ic(ig(4,is1)),ig,is1)
c               call gmix0k(ipos(n+n2a),ipos(nt+n2a),ir,ifix,ic,ig,
c     &                                         nblock,nalfa,ialfa,is1)
               call gather_prop(ig(2,is1)  ,g   ,superh,ipos   )
c               call gather(2*(n2a+n2b),g(n),superg,ipos(n))
c               call subvec(g(n),g(n),g(nt),n2a+n2b)
c              value  = ddot(nt-1,g,1,w,1) * dprod * ipar
               value  = ddot(n1,g,1,w,1) * dprod * ipar
c.....
            else
c.....
               icase = 5
c.....
c
c              x x . . . . . . . . . .
c              x x . . . . . . . . . .
c              x x . . . . . . . . . .
c              . . x x x . . . . . . .
c              . . x x x . . . . . . .
c              . . x x x . . . . . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . x x x . . .
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c              . . . . . . . . . x x x
c
c.....
               ipar = iparity(ig)
c.....
c.....         one electron part involves those choices of i that make
c.....         the singular block become square
c.....
               call ci0t( s(ig(5,is1)),ig(1,is1),w )
               n1 = ig(1,is1)
               n  = n1 + 1
c.....
c.....         two electron part involving "true" second order cofactors
c.....         of the singular block
c.....
c               call ci0jl(ig(1,is1),w(n),scr1,scr2,scr3,s(ig(5,is1)))
c               n2a = (ig(1,is1) * (ig(1,is1)-1) / 2) * ig(2,is1)
c               n   = n + n2a
c.....
c.....         mixed contributions involving the rectangle always
c.....
c               iscr = 1
c               do 70 i=1,nblock
c                  if(i.ne.is1) then
c                     call cik(s(ig(5,i)),scr1(iscr),scr2,scr3,ig(1,i))
c                     iscr = iscr + ig(1,i) * ig(1,i)
c                  end if
c70             continue
c               call wmix0(w(n),w,ig(1,is1),scr1,iscr-1,n2b)
c               nt = n + n2b
                call pi0_prop( ipos,ir(ig(3,is1)),ig(1,is1),ic(kfix),g)
c               n  = n1 + 1
c               call pi0jl(ipos(n),ipos(nt),ic(kfix),ir(ig(3,is1)),
c     &                                             ic(ig(4,is1)),ig,is1)
c               call gmixi0(ipos(n+n2a),ipos(nt+n2a),ir,ic,kfix,ig,
c     &                                         nblock,nalfa,ialfa,is1)
               call gather_prop(ig(1,is1)  ,g   ,superh,ipos   )
c               call gather(2*(n2a+n2b),g(n),superg,ipos(n))
c               call subvec(g(n),g(n),g(nt),n2a+n2b)
c              value  = ddot(nt-1,g,1,w,1) * dprod * ipar
               value  = ddot(n1,g,1,w,1) * dprod * ipar
c.....
            end if
c.....
         else
c.....
c.....      as far as the singly singular cases are concerned the only
c.....      possibilty left is two rectangular blocks. make sure is1
c.....      always refers to the one that has more rows than columns
c.....
c
c           x x x . . . . . . . . .         x x x . . . . . . . . .
c           x x x . . . . . . . . .         x x x . . . . . . . . .
c           x x x . . . . . . . . .         . . . x x x . . . . . .
c           x x x . . . . . . . . .         . . . x x x . . . . . .
c           . . . x x x . . . . . .         . . . x x x . . . . . .
c           . . . x x x . . . . . .         . . . x x x . . . . . .
c           . . . . . . x x x . . .    or   . . . . . . x x x . . .
c           . . . . . . x x x . . .         . . . . . . x x x . . .
c           . . . . . . x x x . . .         . . . . . . x x x . . .
c           . . . . . . . . . x x x         . . . . . . . . . x x x
c           . . . . . . . . . x x x         . . . . . . . . . x x x
c           . . . . . . . . . x x x         . . . . . . . . . x x x
c
c.....
            icase = 6
c.....
            if (ig(1,is1).lt.ig(2,is1)) then
               iii = is1
               is1 = is2
               is2 = iii
               end if
            ipar = iparity(ig)
c.....
c.....      one electron part
c.....
            ist = ig(1,is1) + ig(2,is2) + 1
            call ci0t(s(ig(5,is1)),ig(1,is1),w             )
            call c0k(s(ig(5,is2)),ig(2,is2),w(ig(1,is1)+1))
            call wmix0(w(ist),w(ig(1,is1)+1),ig(2,is2),
     &                        w             ,ig(1,is1),n1)
c.....
c.....      second order cofactors of first rectangle
c.....
c            n    = ist + n1
c            n2a  = ig(1,is1) * (ig(1,is1)-1) * ig(2,is1) / 2
c            iscr = n + n2a * ig(2,is2)
c            call ci0jl(ig(1,is1),w(iscr),scr1,scr2,scr3,s(ig(5,is1)))
c            call wmix0(w(n),w(ig(1,is1)+1),ig(2,is2),
c     &                      w(iscr       ),n2a,nn)
c            n2a = n2a * ig(2,is2)
c            n   = n + nn
cc.....
c.....      second order cofactors of second rectangle
c.....
c            n2b  = ig(2,is2) * (ig(2,is2)-1) * ig(1,is2) / 2
c            iscr = n + n2b * ig(1,is1)
c            call c0kjl(ig(2,is2),w(iscr),scr1,scr2,scr3,s(ig(5,is2)))
c            call wmix0(w(n),w             ,ig(1,is1),
c     &                      w(iscr)       ,n2b,nn)
c            n2b = n2b * ig(1,is1)
c            n   = n + nn
cc.....
cc.....      mixed part, involving the two rectangles always
c.....
c            iscr = 1
c            do 80 i=1,nblock
c               if(i.ne.is1.and.i.ne.is2) then
c                  call cik( s(ig(5,i)),scr1(iscr),scr2,scr3,ig(1,i))
c                  iscr = iscr + ig(1,i) * ig(1,i)
c               end if
c80          continue
c            call wmix0(w(n),w(ist),n1,scr1,iscr-1,n2c)
c            nt = n1 + n2a + n2b + n2c
            call pab_prop(ipos,ir(ig(3,is1)),ig(1,is1),
     &                    ic(ig(4,is2)),ig(2,is2),g)
c            call pabaa(ipos(n1+1),ipos(nt+1),ir(ig(3,is1)),ig(1,is1),
c     &                         ic(ig(4,is1)),ir(ig(3,is2)),
c     &                         ic(ig(4,is2)),              ig(2,is2))
c            n = n1 + n2a + n2b + 1
c            call gmixab(ipos(n),ipos(nt+n2a+n2b+1),ir,ic,ig,nblock,
c     &                                                  ialfa,is1,is2)
            call gather_prop(n1,g,superh,ipos)
c            call gather(2*(nt-n1),g(n1+1),superg,ipos(n1+1))
c            call subvec(g(n1+1),g(n1+1),g(nt+1),nt-n1)
c           value = ddot(nt,g,1,w(ist),1) * dprod * ipar
            value = ddot(n1,g,1,w(ist),1) * dprod * ipar
c.....
         end if
c.....
      endif
      return
      end
   
      subroutine takecideriv(nzdet,ndetps,coeff,jdets,kdet,mdet,dtrani,
     &                       nelec)
      implicit REAL (a-h,o-z)
      dimension jdets(nelec,*),coeff(*),mdet(nelec,*),dtrani(*)
      dimension ndetps(*)
c
      kdet=ndetps(nzdet)
      ioff=0
      do ii=1,nzdet-1
         ioff=ioff+ndetps(ii)
      enddo
      do ii=1,ndetps(nzdet)
         dtrani(ii)=coeff(ioff+ii)
         do jj=1,nelec
            mdet(jj,ii)=jdets(jj,ioff+ii)
         enddo
      enddo
      return
      end
      
      subroutine fillmatrix(a,b,n)
      implicit REAL (a-h,o-z)
      dimension a(n,n),b(*)
      ind(i,j)=max0(i,j)*(max0(i,j)-1)/2+min0(i,j)
      do  i=1,n
         do j=1,i
            b(ind(i,j))=a(i,j)
         enddo
      enddo
      end

      subroutine symamat(amat,ndimamat,orb,nsin,cig,
     &             ldet,orbci)
      implicit REAL (a-h,o-z)
      dimension amat(ndimamat,ndimamat)
      dimension orb(*),cig(*),orbci(ldet,nsin)
      ind(i,j)=max0(i,j)*(max0(i,j)-1)/2+min0(i,j)
      do i=1,nsin
         do j=1,i
            amat(i,j)=orb(ind(i,j))
         enddo
      enddo
      do i=1,ldet
         do j=1,i
            amat(i+nsin,j+nsin)=cig(ind(i,j))
         enddo
      enddo
      do i=1,ldet
         do j=1,nsin
            amat(i+nsin,j)=orbci(i,j)
         enddo
      enddo
      do i=1,ndimamat
         do j=i+1,ndimamat
            amat(i,j)=amat(j,i)
         enddo
      enddo
      return
      end

      subroutine formdagger(a,adag,nold,nnew)
      implicit REAL (a-h,o-z)
      dimension a(nold,nnew),adag(nnew,nold)
      do i=1,nold
         do j=1,nnew
            adag(j,i)=a(i,j)
         enddo
      enddo
      return
      end
      subroutine transformmix(a,b,c,ndimnew,ndimold)
      implicit REAL (a-h,o-z)
      dimension a(ndimold),b(ndimnew),c(ndimnew,ndimold)
      do i=1,ndimnew
         b(i)=0.0d0
         do j=1,ndimold
            b(i)=b(i)+c(i,j)*a(j)
         enddo
      enddo
      return
      end

      subroutine diagmat(q,a,ndimensie)
      implicit REAL (a-h,o-z)
INCLUDE(../m4/common/iofile)
      dimension q(*),a(*)
c
c diagonalisation of a-matrix
c
        imatrix=igmem_alloc(ndimensie*(ndimensie+1)/2)
        iveckk=igmem_alloc(ndimensie*ndimensie)
        ieigkk=igmem_alloc(ndimensie)
        iscr1kk=igmem_alloc(ndimensie+1)
        iscr2kk=igmem_alloc(ndimensie*2)
c
        nelem=ndimensie*(ndimensie+1)/2
        call dcopy(nelem,a,1,q(imatrix),1)
       call jacodiag(q(imatrix),ndimensie,q(iveckk),q(ieigkk),
     &               q(iscr1kk),q(iscr2kk))
       call prsq(q(iveckk),ndimensie,ndimensie,ndimensie)
       do i=1,ndimensie
         write(iwr,*) q(ieigkk+i-1)
       enddo
c
       call gmem_free(iscr2kk)
       call gmem_free(iscr1kk)
       call gmem_free(ieigkk)
       call gmem_free(iveckk)
       call gmem_free(imatrix)
       return
       end
       subroutine symfill(triangle,amat,ndim)
       implicit REAL (a-h,o-z)
       dimension triangle(*),amat(ndim,ndim)
      ind(i,j)=max0(i,j)*(max0(i,j)-1)/2+min0(i,j)
      do i=1,ndim
         do j=1,ndim
            amat(i,j)=triangle(ind(i,j))
         enddo
      enddo
      return
      end
    
      subroutine fillidetps(idetps,ldet)
      implicit REAL (a-h,o-z)
      dimension idetps(ldet)
      do i=1,ldet
         idetps(i)=i
      enddo
      return
      end

      subroutine remtrans2(dao,dmo,v,num,ncol)
      implicit REAL (a-h,o-z)
      dimension dao(*),dmo(*),v(num,ncol)
c
      lind(i,j)=(max(i,j)*(max(i,j)-1))/2+min(i,j)
c       
      call vclr(dmo,1,ncol*(ncol+1)/2)
      do i=1,ncol
         do j=1,i
            do nu=1,num
               do mu=1,num
                  dmo(lind(i,j))=dmo(lind(i,j))+
     *             v(nu,i)*v(mu,j)*dao(lind(mu,nu))
c     print *,'remco..',i,j,mu,nu
c     print *,'remco..',v(nu,i),v(mu,j),dao(lind(mu,nu))
               enddo
            enddo
          enddo
      enddo
c     write(iwr,'(A)')'Transformed integrals'
c     call prtri(dmo,num)
      return
      end

      subroutine getwave2(q,ndetps,idetps,coeff,junk,jdets,junk2,junk3,
     &                    nstruc,nconf,nelec,nalpha,isp,isignp)
      implicit REAL (a-h,o-z)
INCLUDE(common/c8_16vb)      
INCLUDE(../m4/common/iofile)      
      dimension ndetps(*),idetps(*),coeff(*),junk(*)
      dimension jdets(nelec,*),junk2(*),junk3(nelec,*),q(*)
      dimension isp(*),isignp(*)
c
      call readis(ndetps,nstruc,num8)
      ndettot=0
      do i=1,nstruc
         ndettot=ndettot+ndetps(i)
      enddo
      call readis(idetps,ndettot,num8)
c     print *,'remco ndettot',ndettot
c     print *,'remco idetps',(idetps(kk),kk=1,ndettot)
      call reads(coeff,ndettot,num8)
c     print *,'remco coeff',(coeff(kk),kk=1,ndettot)
      call readis(junk,nconf,num8)
c     print *,'remco igroup(1)',(junk(kk),kk=1,nconf)
      nwords=0
      do i=1,nconf
         nwords=nwords+(junk(i)*nelec-1)/(64/n8_16)+1
      enddo
      call readis(junk2,nconf,num8)
c     print *,'remco igroup(2)',(junk2(kk),kk=1,nconf)
      ipacdet=igmem_alloc(nwords)
      call reads(q(ipacdet),nwords,num8)
      indexdet=1
      kstruc=0
      lstruc=0
      it=1
      do i=1,nconf
         call izero(nelec*junk(i),junk3,1)
         call unpack(q(ipacdet+it-1),n8_16,junk3,nelec*junk(i))
         it=it+(junk(i)*nelec-1)/(64/n8_16)+1
         do j=1,junk2(i)
            kstruc=kstruc+1
c           print *,'remco structure',kstruc
            do k=1,ndetps(kstruc)
               ioff=idetps(k+lstruc)
c           print *,'remco dets',coeff(k+lstruc),idetps(k+lstruc)
               do l=1,nelec
                  jdets(l,indexdet)=junk3(l,ioff)
               enddo
               indexdet=indexdet+1
            enddo
            lstruc=lstruc+ndetps(kstruc)
         enddo
      enddo
      call gmem_free(ipacdet)
c
c     ili=1
c     do i=1,nstruc
c        print *,'structure ',i
c        print *,' # dets ',ndetps(i)
c        do j=ili,ili+ndetps(i)-1
c           print *,coeff(j),(jdets(k,j),k=1,nelec)
c        enddo
c        ili=ili+ndetps(i)
c     enddo
      return
      end

      subroutine vbpropdriver(q)
      implicit REAL (a-h,o-z)
      dimension q(*)
INCLUDE(common/turtleparam)
INCLUDE(common/vbproper)
      logical oboth
      oboth=opol.and.omag
      if (oboth) then
         omag=.false.
         call vbprop(q)
         omag=.true.
         opol=.false.
      endif
      call vbprop(q)
      return
      end

      subroutine gather_prop(n,r,a,map)
c     
      implicit REAL (a-h,o-z), integer (i-n)
      dimension r(n),a(*),map(n) 
c
      do 10 loop=1,n
   10 r(loop) = r(loop)*a(map(loop))
c     
      return
      end   

      subroutine pik_prop(ipos,ir,ic,ig,nblock,g)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
      dimension ir(*),ic(*),ipos(*),ig(5,*),g(*)
      common /posit/ iky(3)
INCLUDE(common/turtleparam)
INCLUDE(common/vbproper)
      ind(i,j) = iky(max0(i,j)) + min0(i,j)
      n = 0
      do 30 m=1,nblock
         do 20 k=ig(4,m),ig(4,m)+ig(2,m)-1
            do 10 i=ig(3,m),ig(3,m)+ig(1,m)-1
               n       = n + 1
               g(n)=1.0d0
               if (ocomplex) then
                  if (ir(i).lt.ic(k)) g(n)=-1.0d0
               endif
               ipos(n) = ind(ir(i),ic(k))
10          continue
20       continue
30    continue
      return
      end
      subroutine p00_prop(ipos,ir,ic,ndim,g)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
      dimension ir(*),ic(*),ipos(*),g(*)
      common /posit/ iky(3)
INCLUDE(common/turtleparam)
INCLUDE(common/vbproper)
      ind(i,j) = iky(max0(i,j)) + min0(i,j)
      n = 0
      do 20 k=1,ndim
         do 10 i=1,ndim
            n       = n + 1
            g(n)=1.0d0
            if (ocomplex) then
               if (ir(i).lt.ic(k)) g(n)=-1.0d0
            endif
            ipos(n) = ind(ir(i),ic(k))
10       continue
20    continue
      return
      end
      subroutine p0k_prop(ipos,ir,ic,nc,g)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
      dimension ic(*),ipos(*),g(*)
      common /posit/ iky(3)
INCLUDE(common/turtleparam)
INCLUDE(common/vbproper)
      ind(i,j) = iky(max0(i,j)) + min0(i,j)
      do 10 k=1,nc
         g(k)=1.0d0
         if (ocomplex) then
           if (ir.lt.ic(k)) g(k)=-1.0d0
         endif
         ipos(k) = ind(ir,ic(k))
10    continue
      return
      end
      subroutine pi0_prop(ipos,ir,nr,ic,g)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
      dimension ir(*),ipos(*),g(*)
      common /posit/ iky(3)
INCLUDE(common/turtleparam)
INCLUDE(common/vbproper)
      ind(i,j) = iky(max0(i,j)) + min0(i,j)
      do 10 i=1,nr
         g(i)=1.0d0
         if (ocomplex) then
           if (ir(i).lt.ic) g(i)=-1.0d0
         endif
         ipos(i) = ind(ir(i),ic)
10    continue
      return
      end
      subroutine pab_prop(ipos,ir,nr,ic,nc,g)
c
      implicit REAL  (a-h,o-z) , integer   (i-n)
c
      dimension ir(*),ic(*),ipos(*),g(*)
      common /posit/ iky(3)
INCLUDE(common/turtleparam)
INCLUDE(common/vbproper)
      ind(i,j) = iky(max0(i,j)) + min0(i,j)
      n = 0
      do 20 k=1,nc
         do 10 i=1,nr
            n = n + 1
            g(n)=1.0d0
            if (ocomplex) then
              if (ir(i).lt.ic(k)) g(n)=-1.0d0
            endif
            ipos(n) = ind(ir(i),ic(k))
10       continue
20    continue
      return
      end

      subroutine init_mem_vbprop
      common/vbpropmem/memavail,memuse
      memavail=igmem_max_memory()
      memuse=0
      if (ipg_nodeid().eq.0) then
      write(6,'(A,3I15)')' *** INFO on memory: ',memavail,memreq,
     1memuse
      endif
      return
      end

      subroutine printmem(memreq)
      common/vbpropmem/memavail,memuse
      memuse=memuse+memreq
      memavail=memavail-memreq
      if (ipg_nodeid().eq.0) then
      write(6,'(A,3I15)')' *** INFO on memory: ',memavail,memreq,
     1memuse
      endif
      return
      end
