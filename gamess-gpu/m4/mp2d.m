c 
c  $Author: jmht $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mp2d.m,v $
c  $State: Exp $
c  
      subroutine mpdtr (amat,vec,d1,nsa)
c
c    a 2-index transformation routine
c
      implicit REAL  (a-h,o-z)
      dimension amat(nsa*nsa),vec(nsa*nsa),d1(nsa*nsa)
c
      n2 = nsa*nsa
c
      call vclr(d1,1,n2)
      call mxmb(vec,1,nsa,amat,1,nsa,d1,1,nsa,nsa,nsa,nsa)
c
      call vclr(amat,1,n2)
      call mxmb(vec,1,nsa,d1,nsa,1,amat,nsa,1,nsa,nsa,nsa)
c
c
      return
      end
      subroutine mpdbtr(ifield,q,maxq)
c
c     part of back transformation of density matrix
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common/mpdfil/mpfile(3),istrmj,istrmk,istrma,ifile1
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/nshel)
INCLUDE(common/atmblk)
INCLUDE(common/symtry)
      dimension q(maxq)
      logical dpres, gpres
      dpres = .false.
      fpres = .false.
      gpres = .false.
      do 20 i = 1 , nshell
         dpres = dpres .or. ktype(i).eq.3
         fpres = fpres .or. ktype(i).eq.4
         gpres = gpres .or. ktype(i).eq.5
 20   continue
      i0 = 1
      iv = i0 + nw196(5)
      call rdedx(q(i0),nw196(5),ibl196(5),ifild)
c     ibw = 1
      ifw = mpfile(ifield)
      ntri = ncoorb*(ncoorb+1)/2
      isec = isect(8)
      itype = 0
      call secget(isec,itype,isec8)
      isec8 = isec8 + mvadd
      call rdedx(q(iv),ncoorb*ncoorb,isec8,ifild)
      ib = iv + ncoorb*ncoorb
      iff = ib + ncoorb*ncoorb
      irr = iff + ncoorb*ncoorb
      ima = irr + ncoorb*ncoorb
      lma = ima + ncoorb*ncoorb
      itop = ima + ncoorb*ncoorb
c
      call mpds1(q(i0),nshell,
     +  q(ib),q(iff),q(ima),q(lma),ncoorb,ifield,icount)
c     mmaxq = maxq - ncoorb*ncoorb - nw196(5)
      call mpsrt0(ifw,istrmj,ntri,icount,q(iv),q(iv),maxq-nw196(5))
      call rdedx(q(iv),ncoorb*ncoorb,isec8,ifild)
      iy = iv + ncoorb*ncoorb
      iu = iy + ntri
      npert = 3
      iff = iu + ncoorb*ncoorb*npert
      iff1 = iff + ncoorb*ncoorb
      id = iff1 + ncoorb*ncoorb
      ih = id + ncoorb*ncoorb
      iwks = ih + npert*ncoorb*ncoorb
      iff2 = iwks + ncoorb*ncoorb
      ib = iff2 + ncoorb*ncoorb
      itop = ib + 16*ntri
      if (dpres) itop = ib + 36*ntri
      if (fpres) itop = ib + 100*ntri
      if (gpres) itop = ib + 225*ntri
      if (itop.ge.(maxq-nw196(5))) then
         write (iwr,6010) maxq , itop
         call caserr('not enough core')
      end if
c
      cut = 10.0d0**(-icut)
      call rdedx(q(iu),ncoorb*ncoorb*npert,mpblk(6),ifile1)
      call rdedx(q(iy),ntri,mpblk(10),ifile1)
      call rdedx(q(ih),ncoorb*ncoorb*npert,mpblk(12),ifile1)
      call mpds2(q(i0),nshell,
     +  q(iv),q(iy),q(iu),q(iff),q(iff1),q(id),
     +  q(ib),ifield,ntri,nocca,nvirta,ncoorb,ifw,q(ih),q(iwks),
     +  cut)
c
      return
 6010 format (/1x,'insufficient core available'/1x,'core available ',
     +        i10/1x,'core required  ',i10)
      end
      subroutine mp2dmd(q,iq)
c
c-------------------------------------------------------------------
c
c     analytic mp2 dipole moment derivatives.
c
c     theory in chem. phys. vol 114 , page 9 , 1987
c
c------------------------------------------------------------------
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common/mpdfil/mpfile(3),istrmj,istrmk,istrma,ifile1
      logical lstop,skipp
      common/small/eigs(maxorb)
      dimension skipp(100)
INCLUDE(common/atmblk)
INCLUDE(common/nshel)
INCLUDE(common/infoa)
c
INCLUDE(common/cigrad)
      common/maxlen/maxq
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/cndx40)
c
      dimension q(*),iq(*)
c
      character*10 charwall
c
      character *8 polmp2
      data polmp2/'polariza'/
c
      dum = cpulft(1)
      write (iwr,6010) dum ,charwall()
      call timit(3)
c
c    set up files for tpdm
c
      call secget(isect(9),9,isec9)
      nocc = nocca
c     nuoc = nvirta
c     norbs = ncoorb
c     ndep = nab + nij
c     m100 = 70 + lenint(60)
c     m103 = 103
c     ityp = 0
      mn = nocca*nvirta
      nij = nocca*(nocca+1)/2
      nab = nvirta*(nvirta+1)/2
      nat3 = nat*3
      ntri = ncoorb*(ncoorb+1)/2
c
c
c    set up blocks for ed0 for
c    1) gradient matrix (n3n,n3n)
c    2) t1 (nij,nab)
c    3) t2 (nij,nab)
c    4) e (ncoorb)
c    5) eder(ncoorb,ncoorb,n3n)
c    6) u(ncoorb,ncoorb,n3n)
c    7) y(ncoorb,ncoorb)
c    8) w(ncoorb,ncoorb)
c    9) w2(ncoorb,ncoorb)
c    10) ytrans(ntri)
c    11) fus(ncoorb,ncoorb,3)
c    12) h(ncoorb,ncoorb,3)
c
      npert = 3
      mpblk(1) = 1
      mpblk(2) = mpblk(1) + lensec(nat3*nat3)
      mpblk(3) = mpblk(2) + lensec(nij*nab)
      mpblk(4) = mpblk(3) + lensec(nij*nab)
      mpblk(5) = mpblk(4) + lensec(ncoorb)
      mpblk(6) = mpblk(5) + lensec(ncoorb*ncoorb*npert)
      mpblk(7) = mpblk(6) + lensec(ncoorb*ncoorb*npert)
      mpblk(8) = mpblk(7) + lensec(ncoorb*ncoorb)
      mpblk(9) = mpblk(8) + lensec(ncoorb*ncoorb)
      mpblk(10) = mpblk(9) + lensec(ncoorb*ncoorb)
      mpblk(11) = mpblk(10) + lensec(ntri)
      mpblk(12) = mpblk(11) + lensec(ncoorb*ncoorb*npert)
      ifile1 = 1
      call wrt3z(mpblk(8),ifile1,mpblk(12))
      mpfile(1) = 20
      mpfile(2) = 21
      mpfile(3) = 22
      mpstrm(8) = 20
      mpstrm(5) = 18
      mpstrm(7) = 19
c
      istrmj = mpstrm(5)
      istrmk = mpstrm(7)
      istrma = mpstrm(8)
      ifile1 = 1
      call revise
      call mpsrtj(q,iq,ncoorb,kblk(1),nufile(1),mpstrm(5))
      ipss = 1
      call mpsrtk(q,iq,ncoorb,kblk(1),nufile(1),mpstrm(7),ipss)
      i0 = igmem_alloc_all(maxq)
      call chfcls(q(i0),maxq)
      call gmem_free(i0)
c
      dum = cpulft(1)
      write (iwr,6020) dum ,charwall()
      call timit(3)
c
c   read in eigenvalues
c
      i1 = 1 + ncoorb
      i2 = i1 + ncoorb*ncoorb
      i3 = i2 + ncoorb*ncoorb
      i4 = i3 + ncoorb*ncoorb
      i5 = i4 + ncoorb*ncoorb
      i6 = i5 + ncoorb*ncoorb
      i7 = i6 + ncoorb*ncoorb
      itop = i7 + nocca*nvirta
      if (itop.gt.maxq) then
         write (iwr,6030) maxq , itop
         call caserr(' not enough core')
      end if
      i0 = igmem_alloc(ncoorb)
      i1 = igmem_alloc(ncoorb*ncoorb)
      i2 = igmem_alloc(ncoorb*ncoorb)
      i3 = igmem_alloc(ncoorb*ncoorb)
      i4 = igmem_alloc(ncoorb*ncoorb)
      i5 = igmem_alloc(ncoorb*ncoorb)
      i6 = igmem_alloc(ncoorb*ncoorb)
      i7 = igmem_alloc(nocca*nvirta)
      call rdedx(q(i0),ncoorb,isec9,ifild)
      call mpdmky(q(i2),q(i3),q(i0),ncoorb,q(i4),q(i5),nocca,
     +  mpblk(7),nvirta,q(i6),mpblk(8),iblks,ifils,q(i7),mn,mpstrm(5),
     +  mpstrm(7),ifile1)
      call gmem_free(i7)
      call gmem_free(i6)
      call gmem_free(i5)
      call gmem_free(i4)
      call gmem_free(i3)
      call gmem_free(i2)
      call gmem_free(i1)
      call gmem_free(i0)
c
      m9 = 9
      ieps = igmem_alloc(mn)
      call secget(isect(9),m9,isec9)
      call rdedx(eigs,ncoorb,isec9,ifild)
      do 30 iaa = nocca + 1 , ncoorb
         do 20 i = 1 , nocca
            iai = (iaa-nocca-1)*nocca + i + ieps-1
            q(iai) = 1.0d0/(eigs(iaa)-eigs(i))
 20      continue
 30   continue
      np = 1
      npstar = 0
      skipp(1) = .false.
      lstop = .false.
c
c------------------------------------------------------------
c
c     solve set of simultaneous equations for
c     z-matrix
c
      call chfdrv(q(ieps),lstop,skipp)
      call gmem_free(ieps)
c
      iy  = igmem_alloc(ncoorb*ncoorb)
      iz  = igmem_alloc(nocca*nvirta)
      iww = igmem_alloc(ncoorb*ncoorb)
      ia1 = igmem_alloc(ncoorb*ncoorb)
      ia2 = igmem_alloc(ncoorb*ncoorb)
      ie  = igmem_alloc(ncoorb)
      iblz = iblks + lensec(mn)
      call rdedx(q(ie),ncoorb,isec9,ifild)
c
      call mkdmkw(q(iy),q(iz),q(iww),mpblk(7),iblz,mpblk(8),q(ia1),
     +  q(ia2),nocca,nvirta,ncoorb,ifils,q(ie),mpstrm(5),mpstrm(7),
     +  ifile1)
c
      call gmem_free(ie)
      call gmem_free(ia2)
      call gmem_free(ia1)
      call gmem_free(iww)
      call gmem_free(iz)
      call gmem_free(iy)
c
      dum = cpulft(1)
      write (iwr,6040) dum ,charwall()
      call timit(3)
c
c
c     nxij = ncoorb*(ncoorb+1)/2
      ncore = 0
      ncact = nsa4
      nvr = 0
      ntot = ncore + ncact + nvr
      nupact = ncore + ncact
      m0 = 0
      call secget(isect(103),m0,iblok)
      call wrt3(cigr,lds(isect(103)),iblok,ifild)
c
      it = 1
      it1 = it + ncoorb*ncoorb
      iwks = it1 + ncoorb*ncoorb
      iff = iwks + ncoorb*ncoorb
      ia1 = iff + ncoorb*ncoorb
      ia2 = ia1 + ncoorb*ncoorb
      ie = ia2 + ncoorb*ncoorb
      ieps = ie + ncoorb
      ifus = ieps + npert*ncoorb*ncoorb
      ih = ifus + npert*ncoorb*ncoorb
      iu = ih + npert*ncoorb*ncoorb
      iy = iu + npert*ncoorb*ncoorb
      iww = iy + ncoorb*ncoorb
      itop = iww + ncoorb*ncoorb
      if (itop.ge.maxq) then
         write(iwr,6050)maxq,ireq
         call caserr('not enough core for mpdmkc')
      end if
c
cjmht It's much safer to use iy as calculated here to calculate future
c     memory requirements as, if we use the ma library and i8, these values
c     do not behave predictably, so we save the value here
      mem_iy=iy
c
      it1  = igmem_alloc(ncoorb*ncoorb)
      it   = igmem_alloc(ncoorb*ncoorb)
      iff  = igmem_alloc(ncoorb*ncoorb)
      ia1  = igmem_alloc(ncoorb*ncoorb)
      ia2  = igmem_alloc(ncoorb*ncoorb)
      ie   = igmem_alloc(ncoorb*ncoorb)
      ieps = igmem_alloc(npert*ncoorb*ncoorb)
      ifus = igmem_alloc(npert*ncoorb*ncoorb)
      ih   = igmem_alloc(npert*ncoorb*ncoorb)
      iu   = igmem_alloc(npert*ncoorb*ncoorb)
      iy   = igmem_alloc(ncoorb*ncoorb)
      iwks = igmem_alloc(ncoorb*ncoorb)
      iww  = igmem_alloc(ncoorb*ncoorb)
c
      call secget(isect(9),9,isec9)
      call rdedx(q(ie),ncoorb,isec9,ifild)
      call rdedx(q(iy),ncoorb*ncoorb,mpblk(7),ifile1)
      call rdedx(q(iww),ncoorb*ncoorb,mpblk(8),ifile1)
      call rdedx(q(ieps),ncoorb*ncoorb*npert,mpblk(5),ifile1)
      call rdedx(q(iu),ncoorb*ncoorb*npert,mpblk(6),ifile1)
c
      call mpdmkc(q(it),q(it1),q(iff),q(ia1),q(ia2),q(ie),q(iwks),
     +  q(ieps),q(ifus),q(ih),q(iu),q(iy),q(iww),nocca,nvirta,ncoorb,
     +  mpstrm(5),mpstrm(7))
c
      call wrt3(q(ifus),npert*ncoorb*ncoorb,mpblk(11),ifile1)
      call wrt3(q(ih),npert*ncoorb*ncoorb,mpblk(12),ifile1)
c
      call gmem_free(iww)
      call gmem_free(iwks)
c
      if (runtyp.eq.polmp2) then
cjmht    idx = iy
         call gmem_free(iy)
         np = 0
         maxp = 3
         do 40 i = 1 , maxp
            if (ione(i+3).ne.0) np = np + 1
 40      continue
         npert = 3
c    >>>> note should eventually be npert = np to get
c    >>>> quadrupole perturbations as well
c
         npdim = max(npert,9)
cjmht    ipoll = idx + ntri*npert
         ipoll = mem_iy + ntri*npert
         ipollb = ipoll + npdim*npdim
         ireq = ipoll + npdim*npdim
         if (ireq.gt.maxq) then
            write (iwr,6050) maxq , ireq
            call caserr('insufficient core for mpdpol')
         end if
         idx    = igmem_alloc(ntri*npert)
         ipoll  = igmem_alloc(npdim*npdim)
         ipollb = igmem_alloc(npdim*npdim)
c
c    mp2 polarisabilities
c
         call mpdpol(q(ifus),q(ih),q(iu),q(idx),q(ipoll),q(ipollb),ntri
     +  ,npert,npdim)
c
         call gmem_free(ipollb)
         call gmem_free(ipoll)
         call gmem_free(idx)
c
         call delfil(istrmj)
         call delfil(istrmk)
c
         call gmem_free(iu)
         call gmem_free(ih)
         call gmem_free(ifus)
         call gmem_free(ieps)
         call gmem_free(ie)
         call gmem_free(ia2)
         call gmem_free(ia1)
         call gmem_free(iff)
         call gmem_free(it)
         call gmem_free(it1)
c
         return
      end if
c
c     solve three sets of equations as defined in equation (26)
c     of the paper
c
      call mpdchf(q,q(ifus),q(iff),q(ih))
c
      dum = cpulft(1)
      write (iwr,6060) dum ,charwall()
      call timit(3)
      call wrt3(q(ih),npert*ncoorb*ncoorb,mpblk(12),ifile1)
      ntri = ncoorb*(ncoorb+1)/2
c
c              mp2 fields
c
      iwtr = igmem_alloc(ntri)
      call mpd1pd(q(ifus),q(ih),q(it),q(it1),q(ia1),q(iwtr),q(iy),
     +  isecdd,isecll,ntri,q(ie),mpstrm(5),mpstrm(7),ifile1)
      call gmem_free(iwtr)
c      call delfil(istrma)
c
      dum = cpulft(1)
      write (iwr,6070) dum ,charwall()
      call timit(3)
c
      m0 = 0
      call secget(isect(8),m0,isec8)
      isec8 = isec8 + mvadd
      call rdedx(q(iy),ncoorb*ncoorb,isec8,ifild)
      call rdedx(q(iu),npert*ncoorb*ncoorb,mpblk(6),ifile1)
      call rdedx(q(ieps),npert*ncoorb*ncoorb,mpblk(5),ifile1)
      call mpd2pd(q(it),q(iu),q(ieps),q(iff),q(it1),q(ia1),q(ia2),q(ie)
     +  ,nocca,nvirta,ncoorb,q(iy))
c
      call gmem_free(iy)
      call gmem_free(iu)
      call gmem_free(ih)
      call gmem_free(ifus)
      call gmem_free(ieps)
      call gmem_free(ie)
      call gmem_free(ia2)
      call gmem_free(ia1)
      call gmem_free(iff)
      call gmem_free(it)
      call gmem_free(it1)
c
c     now have 3 tpdms on files mpfile(1,2,3)
c
      do 50 ifield = 1 , 3
c
         call delfil(istrmj)
         call delfil(istrmk)
         ifbjmn = mpfile(ifield)
         ifmnbj = mpfile(ifield)
         nov = nocca*nvirta
         ntri = ncoorb*(ncoorb+1)/2
c        n2 = ncoorb*ncoorb
         i0  = igmem_alloc_all(maxa)
         ii0 = lenrel(i0-1)+1
         call mpsrt0(ifbjmn,ifmnbj,nov,ntri,q(i0),iq(ii0),maxa)
         call gmem_free(i0)
         ivec = igmem_alloc(ncoorb*ncoorb)
         iff  = igmem_alloc(ncoorb*ncoorb)
         iff1 = igmem_alloc(ncoorb*ncoorb)
         id   = igmem_alloc(nocca*nvirta)
         call mpdtr2(q(ivec),q(iff),q(iff1),q(id),nocca,nvirta,ncoorb,
     +  ifield,ifild,mvadd,isect(8))
         call gmem_free(id)
         call gmem_free(iff1)
         call gmem_free(iff)
         call gmem_free(ivec)
c
         i0  = igmem_alloc_all(maxa)
         ii0 = lenrel(i0-1)+1
         call mpsrt0(istrmj,istrmk,ntri,ntri,q(i0),iq(ii0),maxa)
         call mpdbtr(ifield,q(i0),maxa)
         call gmem_free(i0)
         dum = cpulft(1)
         write (iwr,6080) ifield , dum ,charwall()
         call timit(3)
c
 50   continue
      call revise
c
      call revind
      call delfil(istrmj)
      call delfil(istrmk)
c
      return
 6010 format (/1x,'commence evaluation of mp2 contribution at ',f8.2,
     +        ' seconds',a10,' wall')
 6020 format (/1x,'initial sorting complete at ',f8.2,' seconds',
     +        a10,' wall')
 6030 format (/' insufficient core for mpdmky : have ',
     +  i8,' real words, need ',i8,' real words')
 6040 format (/1x,'construction of initial z-matrix complete at',f8.2,
     +        ' seconds',a10,' wall')
 6050 format (/1x,'insufficent core for mpdpol'/1x,'core available ',
     +        i10/1x,'core required  ',i10/)
 6060 format (/1x,'chf equations completed at ',f8.2,' seconds'
     +        ,a10,' wall')
 6070 format (/1x,'field-dependent one-particle terms complete',1x,f8.2,
     +        ' seconds',a10,' wall')
 6080 format (/1x,'back transformation (component',i3,') completed at',
     +        f8.2,' seconds',a10,' wall')
      end
      subroutine mpdbt1(d,v,w,y)
c
c     back transforms 1-particle density matrix for mp2
c     dipole derivatives
c
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/sizes)
INCLUDE(common/common)
INCLUDE(common/cndx41)
c
INCLUDE(common/atmblk)
INCLUDE(common/infoa)
      dimension d(nx,3),v(num,ncoorb),w(nx),y(num)
c
c     read three sets of perturbed scf density matrices
c
      ltri = ncoorb*(ncoorb+1)/2
      m = 0
      call secget(isect(31),m,isec31)
      call search(isec31,ifild)
      do 20 i = 1 , 3
         call reads(d(1,i),ltri,ifild)
 20   continue
c
c     read vectors
c
      m = 0
      call secget(isect(8),m,iblok)
      call rdedx(v,num*ncoorb,iblok+mvadd,ifild)
c
c     back transform to ao basis
c
      do 30 i = 1 , 3
         call dcopy(ltri,d(1,i),1,w,1)
         call demoao(w,d(1,i),v,y,num,ncoorb,num)
 30   continue
c
c     add mp2 correction to field derivative density matrices
c
      isecd1 = isect(105)
      call secget(isecd1,isecd1,iblok)
      call search(iblok,ifild)
      do 50 i = 1 , 3
         call reads(w,nx,ifild)
         do 40 j = 1 , nx
            d(j,i) = d(j,i) + w(j)
 40      continue
 50   continue
      return
      end
      subroutine mpdsym(ncoorb,ff1,ff2,ff,ifield)
      implicit REAL  (a-h,o-z)
      common/mpdfil/mpfile(3),istrmj,istrmk,istrma,ifile1
      dimension ff1(ncoorb*ncoorb),ff2(ncoorb*ncoorb),
     1  ff(ncoorb*ncoorb)
      ifort1 = istrmj
      ifort2 = istrmk
      ifortw = mpfile(ifield)
      call rewedz(ifort1)
      call rewedz(ifort2)
      call rewedz(ifortw)
      nsq = ncoorb*ncoorb
      do 30 i = 1 , nsq
         call rdedz(ff1,ncoorb*ncoorb,ifort1)
         call rdedz(ff2,ncoorb*ncoorb,ifort2)
         do 20 j = 1 , nsq
            ff(j) = 0.5d0*(ff1(j)+ff2(j))
 20      continue
         call wtedz(ff,ncoorb*ncoorb,ifortw)
 30   continue
      return
      end
      subroutine mpdtr2(vec,ff,ff1,d,nocca,nvirta,ncoorb,
     1  ifield,ifild,mvadd,isecv)
      implicit REAL  (a-h,o-z)
      common/mpdfil/mpfile(3),istrmj
      dimension vec(ncoorb*ncoorb),ff(ncoorb*ncoorb),
     1  ff1(ncoorb*ncoorb),d(nocca*nvirta)
c
      ifortw = istrmj
      ifortr = mpfile(ifield)
      call rewedz(ifortr)
      call rewedz(ifortw)
      m0 = 0
      call secget(isecv,m0,isec8)
      isec8 = isec8 + mvadd
      call rdedx(vec,ncoorb*ncoorb,isec8,ifild)
      iv1 = ncoorb*nocca + 1
      ntri = ncoorb*(ncoorb+1)/2
c
      do 20 ijkl = 1 , ntri
         call rdedz(d,nocca*nvirta,ifortr)
         call vclr(ff1,1,ncoorb*ncoorb)
         call mxmb(vec(iv1),1,ncoorb,d,nocca,1,ff1,1,ncoorb,ncoorb,
     +             nvirta,nocca)
         call vclr(ff,1,ncoorb*ncoorb)
         call mxmb(vec,1,ncoorb,ff1,ncoorb,1,ff,ncoorb,1,ncoorb,nocca,
     +             ncoorb)
c
         call symm1b(ff1,ff,ncoorb,ntrii)
         call wtedz(ff1,ntrii,ifortw)
 20   continue
      return
      end
      subroutine mpds1(iso,nshels,b,ff,mapb,lmap,
     +                 ncoorb,ifield,icount)
c
      implicit REAL  (a-h,o-z)
      logical lmap
INCLUDE(common/sizes)
      common/mpdfil/mpfile(3),istrmj,istrmk,istrma,ifile1
      dimension b(ncoorb*ncoorb),ff(ncoorb*ncoorb),
     +          mapb(ncoorb*ncoorb),lmap(ncoorb*ncoorb)
      dimension m0(48),iso(nshels,*)
INCLUDE(common/nshel)
INCLUDE(common/symtry)
      logical ijump,jjump
c
      ntri = ncoorb*(ncoorb+1)/2
      ifort = mpfile(ifield)
      ifort1 = istrmj
      ifort2 = istrmk
      call rewedz(ifort)
      call rewedz(ifort1)
      call rewedz(ifort2)
c
c
      icount = 0
      do 90 ii = 1 , nshell
         mini = kmin(ii)
         maxi = kmax(ii)
         loci = kloc(ii) - mini
         ijump = .false.
         do 30 it = 1 , nt
            id = iso(ii,it)
            ijump = ijump .or. id.gt.ii
            m0(it) = id
 30      continue
         do 80 jj = 1 , ii
            minj = kmin(jj)
            maxj = kmax(jj)
            locj = kloc(jj) - minj
            jjump = .false.
            do 50 it = 1 , nt
               id = m0(it)
               jd = iso(jj,it)
               jjump = jjump .or. jd.gt.ii
               if (jd.gt.id) then
                  nd = id
                  id = jd
                  jd = nd
               end if
               jjump = jjump .or. (id.eq.ii .and. jd.gt.jj)
 50         continue
            do 70 i = mini , maxi
               i1 = (loci+i-1)*ncoorb
               do 60 j = minj , maxj
                  icount = icount + 1
                  mapb(icount) = i1 + locj + j
                  lmap(icount) = ijump .or. jjump
 60            continue
 70         continue
 80      continue
 90   continue
c
c
      do 130 ijkl = 1 , ntri
         call rdedz(b,ntri,ifort1)
         call rdedz(ff,ntri,ifort2)
         do 100 j = 1 , ntri
            b(j) = 0.5d0*(b(j)+ff(j))
 100     continue
         call squr(b,ff,ncoorb)
         do 110 i = 1 , icount
            b(i) = ff(mapb(i))
 110     continue
         do 120 i = 1 , icount
            if (lmap(i)) b(i) = 0.0d0
 120     continue
         call wtedz(b,icount,ifort)
 130  continue
      return
      end
      subroutine mpds2(iso,nshels,vec,y,u,ff,ff1,d,b,
     + ipf,ntri,nocca,
     + nvirta,ncoorb,ifw,h,wks,cut)
c
      implicit REAL  (a-h,o-z)
      dimension vec(ncoorb*ncoorb),ff(ncoorb,ncoorb),
     1 ff1(ncoorb,ncoorb),y(ntri),u(ncoorb,ncoorb,3),
     2 d(ncoorb,ncoorb),b(ntri,*),h(ncoorb,ncoorb,3),
     3 wks(ncoorb,ncoorb)
      dimension m0(48),iso(nshels,*)
INCLUDE(common/sizes)
INCLUDE(common/mapper)
INCLUDE(common/nshel)
INCLUDE(common/symtry)
INCLUDE(common/atmblk)
      common/blkin/g(510),nint,length
      common/crio/last(40)
      common/mpdfil/mpfile(3),istrmj,istrmk,istrma,ifile1
_IFN1(iv)      common/craypk/labout(1360)
_IF1(iv)      common/craypk/labij(340),labkl(340)
      logical ijump,jjump,lab,labc
      data mzero/0/
      ind(i,j) = iky(max(i,j)) + min(i,j)
c
_IFN1(civ)      call izero(1360,labout,1)
_IF1(iv)      call setsto(680,0,labij)
_IF1(c)      call szero(labout,1360)
      iv1 = ncoorb*nocca + 1
      nocc1 = nocca + 1
      ifort = istrmj
      call vclr(ff1,1,ncoorb*ncoorb)
      call mxmb(vec(iv1),1,ncoorb,u(nocc1,1,ipf),1,ncoorb,ff1,1,ncoorb,
     +          ncoorb,nvirta,nocca)
      call vclr(ff,1,ncoorb*ncoorb)
      call mxmb(ff1,1,ncoorb,vec,ncoorb,1,ff,1,ncoorb,ncoorb,nocca,
     +          ncoorb)
      call symm1c(ff,ncoorb)
c
c
      call vclr(wks,1,ncoorb*ncoorb)
      call mxmb(vec,1,ncoorb,h(1,1,ipf),1,ncoorb,wks,1,ncoorb,ncoorb,
     +          ncoorb,ncoorb)
      call vclr(ff1,1,ncoorb*ncoorb)
      call mxmb(wks,1,ncoorb,vec,ncoorb,1,ff1,1,ncoorb,ncoorb,ncoorb,
     +          ncoorb)
      call symm1c(ff1,ncoorb)
c
      call vclr(wks,1,ncoorb*ncoorb)
      call mxmb(vec,1,ncoorb,vec,ncoorb,1,wks,1,ncoorb,ncoorb,nocca,
     +          ncoorb)
c
      call squr(y,d,ncoorb)
      call rewedz(ifort)
      call delfil(ifw)
      call rewedz(ifw)
      nint = 0
c
c
      do 180 ii = 1 , nshell
         ijump = .false.
         do 30 it = 1 , nt
            id = iso(ii,it)
            ijump = ijump .or. id.gt.ii
            m0(it) = id
 30      continue
         iceni = katom(ii)
         do 170 jj = 1 , ii
            if (.not.(ijump)) then
               jjump = .false.
               do 50 it = 1 , nt
                  id = m0(it)
                  jd = iso(jj,it)
                  jjump = jjump .or. jd.gt.ii
                  if (jd.gt.id) then
                     nd = id
                     id = jd
                     jd = nd
                  end if
                  jjump = jjump .or. (id.eq.ii .and. jd.gt.jj)
 50            continue
            end if
            mini = kmin(ii)
            minj = kmin(jj)
            maxi = kmax(ii)
            maxj = kmax(jj)
            loci = kloc(ii) - mini
            locj = kloc(jj) - minj
            lab = katom(jj).eq.iceni
c
            ntimes = (maxi-mini+1)*(maxj-minj+1)
            imax = loci + maxi
            do 60 itimes = 1 , ntimes
c
               call rdedz(b(1,itimes),ntri,ifort)
c
c
 60         continue
            if (.not.(ijump .or. jjump)) then
               icount = 0
               do 100 i = mini , maxi
                  do 90 j = minj , maxj
                     icount = icount + 1
                     i1 = loci + i
                     j1 = locj + j
                     ikl = 0
                     do 80 k1 = 1 , imax
                        do 70 l1 = 1 , k1
                           ikl = ikl + 1
                           b(ikl,icount) = b(ikl,icount)
     +                        + 2.0d0*(d(i1,j1)*ff(k1,l1)+d(k1,l1)
     +                        *ff(i1,j1))
     +                        - 0.5d0*(d(i1,k1)*ff(j1,l1)+d(i1,l1)
     +                        *ff(j1,k1)+d(j1,k1)*ff(i1,l1)+d(j1,l1)
     +                        *ff(i1,k1)) + ff1(i1,j1)*wks(k1,l1)
     +                        + ff1(k1,l1)*wks(i1,j1)
     +                        - (ff1(i1,k1)*wks(j1,l1)+ff1(i1,l1)
     +                        *wks(j1,k1)+ff1(j1,k1)*wks(i1,l1)
     +                        +ff1(j1,l1)*wks(i1,k1))*0.25d0
 70                     continue
 80                  continue
 90               continue
 100           continue
               do 160 kk = 1 , ii
                  labc = lab .and. katom(kk).eq.iceni
                  maxll = kk
                  if (kk.eq.ii) maxll = jj
                  do 150 ll = 1 , maxll
                     if (.not.(labc .and. katom(ll).eq.iceni)) then
                        mink = kmin(kk)
                        minl = kmin(ll)
                        maxk = kmax(kk)
                        maxl = kmax(ll)
                        lock = kloc(kk) - mink
                        locl = kloc(ll) - minl
                        icount = 0
                        do 140 i = mini , maxi
                           i1 = loci + i
                           do 130 j = minj , maxj
                              j1 = locj + j
                              icount = icount + 1
                              do 120 k = mink , maxk
                                 k1 = lock + k
                                 do 110 l = minl , maxl
                                    l1 = locl + l
c
c
c
                                    ikl = ind(k1,l1)
                                    val = b(ikl,icount)
c
c
c
c
                                    if (dabs(val).gt.cut) then
                                       nint = nint + 1
                                       g(nint) = val
_IFN1(iv)                                       labout(4*nint-3) = i1
_IFN1(iv)                                       labout(4*nint-2) = j1
_IFN1(iv)                                       labout(4*nint-1) = k1
_IFN1(iv)                                       labout(4*nint) = l1
_IF1(iv)                                     labij(nint) = j1 + i4096(i1)
_IF1(iv)                                     labkl(nint) = l1 + i4096(k1)
                                       if (nint.eq.num2e) then
_IFN1(iv)                                  call pack(g(num2e+1),lab816,
_IFN1(iv)     +                                      labout,numlab)
_IF1(iv)                                     call pak4v(labij,g(num2e+1))
                                         call put(g,m511,ifw)
                                         last(ifw) = last(ifw) + 512
                                         nint = 0
_IFN1(civ)                                 call izero(1360,labout,1)
_IF1(iv)                                    call setsto(680,0,labij)
                                       end if
                                    end if
c
 110                             continue
 120                          continue
 130                       continue
 140                    continue
                     end if
 150              continue
 160           continue
            end if
 170     continue
 180  continue
c
      if (nint.ne.0) then
_IFN1(iv)         call pack(g(num2e+1),lab816,labout,numlab)
_IF1(iv)         call pak4v(labij,g(num2e+1))
         call put(g,m511,ifw)
         nint = 0
      end if
      call put(g,mzero,ifw)
      last(ifw) = last(ifw) + 512
      return
      end
      subroutine symm1c(amat,n)
      implicit REAL  (a-h,o-z)
      dimension amat(n,n)
c
      do 30 i = 1 , n
         do 20 j = 1 , i
            amat(i,j) = (amat(i,j)+amat(j,i))*0.5d0
            amat(j,i) = amat(i,j)
 20      continue
 30   continue
c
      return
      end
      subroutine mpd2pd(t,u,eps,ff,ff1,a1,a2,e,nocca,nvirta,ncoorb,
     1   vec)
c
c----------------------------------two particle density matrix---
c
c    this forms the three field-dependent two-particle density
c    matrices , in the m.o. basis , defined in equation (27)
c    of the dipole derivatives paper
c
c----------------------------------------------------------------
      implicit REAL  (a-h,o-z)
      common/mpdfil/mpfile(3),istrmj,istrmk,istrma,ifile1
      dimension t(ncoorb,ncoorb),u(ncoorb,ncoorb,3),vec(ncoorb*ncoorb),
     1   eps(ncoorb,ncoorb,3),ff(ncoorb,ncoorb),ff1(ncoorb,ncoorb),
     2   e(ncoorb),a1(ncoorb,ncoorb),a2(ncoorb,ncoorb)
      nocc1 = nocca + 1
      norbs = ncoorb
      call rewedz(mpfile(1))
      call rewedz(mpfile(2))
      call rewedz(mpfile(3))
      call vclr(t,1,norbs*norbs)
      ifint1 = istrmj
      ifint2 = istrmk
      call rewedz(ifint1)
      call rewedz(ifint2)
      do 100 ib = 1 , norbs
         do 90 j = 1 , ib
            call rdedz(a1,ncoorb*ncoorb,ifint1)
            call rdedz(a2,ncoorb*ncoorb,ifint2)
            if (ib.gt.nocca) then
               if (j.le.nocca) then
c                 ibj = ib*(ib-1)/2 + j
                  ebj = e(ib) - e(j)
                  do 30 ia = nocc1 , norbs
                     do 20 i = 1 , nocca
                        t(i,ia) = -4.0d0*(a1(i,ia)+a1(i,ia)-a2(i,ia))
     +                            /(ebj+e(ia)-e(i))
 20                  continue
 30               continue
                  do 50 k = 1 , nocca
                     do 40 i = 1 , nocca
                        t(i,k) = -4.0d0*(a1(i,k)+a1(i,k)-a2(i,k))
 40                  continue
 50               continue
                  do 70 ia = nocc1 , norbs
                     do 60 ic = nocc1 , norbs
                        t(ic,ia) = -4.0d0*(a1(ic,ia)+a1(ic,ia)-a2(ic,ia)
     +                             )
 60                  continue
 70               continue
c
c..........loop over fields
c
                  do 80 ipf = 1 , 3
                     call mpdmkg(t,u,eps,ff,e,ipf,nocca,nocc1,norbs,
     +  nvirta,ff1,ebj,vec)
 80               continue
               end if
            end if
 90      continue
 100  continue
      return
      end
      subroutine mpd1pd(fus,h,vec,wks,wks2,wtr,y,isecdd,isecll,ntri,e,
     1  istrmj,istrmk,ifile1)
c
c-------------------------one particle density matrices in ao basis
c
c     final formation and transformation to the a.o. basis of
c     the 1-particle effective density matrices which multiply
c     the dipole derivative integrals, the derivative
c     1-electron hamiltonian, and the derivative overlap integrals
c
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/common)
INCLUDE(common/cndx41)
c
INCLUDE(common/atmblk)
c
      dimension fus(ncoorb,ncoorb,3),h(ncoorb,ncoorb,3),
     1 vec(ncoorb*ncoorb),wks(ncoorb,ncoorb),y(ncoorb*ncoorb),
     2 wtr(ntri),e(ncoorb),wks2(ncoorb,ncoorb)
c
      m9 = 9
      call secget(isect(9),m9,isec9)
      call rdedx(e,ncoorb,isec9,ifild)
      isecd1 = isecdd + 4
c     m0 = 0
      call rdedx(y,ncoorb*ncoorb,mpblk(7),ifile1)
      isecv = isect(8)
      itypv = 0
      call secget(isecv,itypv,isec8)
      isec8 = isec8 + mvadd
      call rdedx(vec,ncoorb*ncoorb,isec8,ifild)
      call mpdtr(y,vec,wks,ncoorb)
      ipiq = 0
      do 30 ip = 1 , ncoorb
         do 20 iq = 1 , ip
            ipiq = ipiq + 1
            ipq = (iq-1)*ncoorb + ip
            iqp = (ip-1)*ncoorb + iq
            wtr(ipiq) = (y(ipq)+y(iqp))*0.5d0
 20      continue
 30   continue
c
c
c     the array just transformed to the a.o. basis is that
c     which will multiply the dipole derivative integrals
c     equation (8)
      call secput(isecdd,isecdd,lensec(ntri),iblkd1)
      call wrt3(wtr,ntri,iblkd1,ifild)
      call wrt3(wtr,ntri,mpblk(10),ifile1)
      lds(isecdd) = ntri
c
      npert = 3
      call secput(isecd1,isecd1,npert*lensec(ntri),iblkdd)
      call revind
      lds(isecd1) = npert*ntri
c
      call rdedx(h,npert*ncoorb*ncoorb,mpblk(12),ifile1)
      call mpdtr(h(1,1,1),vec,wks,ncoorb)
      call mpdtr(h(1,1,2),vec,wks,ncoorb)
      call mpdtr(h(1,1,3),vec,wks,ncoorb)
      ipiq = 0
      do 50 ip = 1 , ncoorb
         do 40 iq = 1 , ip
            ipiq = ipiq + 1
            wtr(ipiq) = (h(ip,iq,1)+h(iq,ip,1))*0.5d0
 40      continue
 50   continue
c
      call wrt3(wtr,ntri,iblkdd,ifild)
      ipiq = 0
      do 70 ip = 1 , ncoorb
         do 60 iq = 1 , ip
            ipiq = ipiq + 1
            wtr(ipiq) = (h(ip,iq,2)+h(iq,ip,2))*0.5d0
 60      continue
 70   continue
c
      call wrt3s(wtr,ntri,ifild)
      ipiq = 0
      do 90 ip = 1 , ncoorb
         do 80 iq = 1 , ip
            ipiq = ipiq + 1
            wtr(ipiq) = (h(ip,iq,3)+h(iq,ip,3))*0.5d0
 80      continue
 90   continue
c
      call wrt3s(wtr,ntri,ifild)
c
c     the 3 arrays just formed and transformed to the a.o. basis
c     are those which multiply the derivative 1-electron
c     hamiltonian - equation (27)
c
c      now form the derivative lagrangian style matrices which
c      multiply the derivative overlap terms
c      also equation (27)
c
c
c
c
c
c        now form the complete lagrangian
      call secput(isecll,isecll,npert*lensec(ntri),iblkll)
      lds(isecll) = npert*ntri
c
      call revind
c
      call rdedx(h,npert*ncoorb*ncoorb,mpblk(12),ifile1)
      call rdedx(fus,npert*ncoorb*ncoorb,mpblk(11),ifile1)
      do 110 j = 1 , nocca
         do 100 i = 1 , nocca
            fus(i,j,1) = -0.5d0*fus(i,j,1)
            fus(i,j,2) = -0.5d0*fus(i,j,2)
            fus(i,j,3) = -0.5d0*fus(i,j,3)
 100     continue
 110  continue
      do 130 ib = nocca + 1 , ncoorb
         do 120 ia = nocca + 1 , ncoorb
            fus(ia,ib,1) = -0.5d0*fus(ia,ib,1)
            fus(ia,ib,2) = -0.5d0*fus(ia,ib,2)
            fus(ia,ib,3) = -0.5d0*fus(ia,ib,3)
 120     continue
 130  continue
      do 150 i = 1 , nocca
         do 140 ia = nocca + 1 , ncoorb
            fus(ia,i,1) = -fus(i,ia,1) - h(ia,i,1)*e(i)
            fus(ia,i,2) = -fus(i,ia,2) - h(ia,i,2)*e(i)
            fus(ia,i,3) = -fus(i,ia,3) - h(ia,i,3)*e(i)
            fus(i,ia,1) = 0.0d0
            fus(i,ia,2) = 0.0d0
            fus(i,ia,3) = 0.0d0
 140     continue
 150  continue
c
c       now the a matrix bit
      call rewedz(istrmj)
      call rewedz(istrmk)
c
      do 190 k = 1 , nocca
         do 180 j = 1 , k
            call rdedz(wks,ncoorb*ncoorb,istrmj)
            call rdedz(wks2,ncoorb*ncoorb,istrmk)
            zz1 = 0.0d0
            zz2 = 0.0d0
            zz3 = 0.0d0
            do 170 i = 1 , nocca
               do 160 ia = nocca + 1 , ncoorb
                  aaa = wks(ia,i)*4.0d0 - wks2(ia,i) - wks2(i,ia)
                  zz1 = zz1 - 0.5d0*h(ia,i,1)*aaa
                  zz2 = zz2 - 0.5d0*h(ia,i,2)*aaa
                  zz3 = zz3 - 0.5d0*h(ia,i,3)*aaa
 160           continue
 170        continue
            fus(k,j,1) = fus(k,j,1) + zz1
            fus(k,j,2) = fus(k,j,2) + zz2
            fus(k,j,3) = fus(k,j,3) + zz3
            if (k.ne.j) fus(j,k,1) = fus(j,k,1) + zz1
            if (k.ne.j) fus(j,k,2) = fus(j,k,2) + zz2
            if (k.ne.j) fus(j,k,3) = fus(j,k,3) + zz3
 180     continue
 190  continue
c
c
      call mpdtr(fus(1,1,1),vec,wks,ncoorb)
      call mpdtr(fus(1,1,2),vec,wks,ncoorb)
      call mpdtr(fus(1,1,3),vec,wks,ncoorb)
      ipiq = 0
      do 210 ip = 1 , ncoorb
         do 200 iq = 1 , ip
            ipiq = ipiq + 1
            wtr(ipiq) = (fus(ip,iq,1)+fus(iq,ip,1))*0.5d0
 200     continue
 210  continue
c
      call wrt3(wtr,ntri,iblkll,ifild)
      ipiq = 0
      do 230 ip = 1 , ncoorb
         do 220 iq = 1 , ip
            ipiq = ipiq + 1
            wtr(ipiq) = (fus(ip,iq,2)+fus(iq,ip,2))*0.5d0
 220     continue
 230  continue
c
      call wrt3s(wtr,ntri,ifild)
      ipiq = 0
      do 250 ip = 1 , ncoorb
         do 240 iq = 1 , ip
            ipiq = ipiq + 1
            wtr(ipiq) = (fus(ip,iq,3)+fus(iq,ip,3))*0.5d0
 240     continue
 250  continue
c
      call wrt3s(wtr,ntri,ifild)
c
c     the arrays wtr are the ones defined in equation (27)
c
      return
      end
      subroutine mpdchf(q,fus,ff,h)
c
c     constructs 3 set of r.h.s. for field dependent z-matrix
c
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/common)
INCLUDE(common/cndx41)
c
      common/mpdfil/mpfile(3),istrmj,istrmk,istrma,ifile1
c
      dimension q(*)
      dimension fus(ncoorb,ncoorb,3),ff(ncoorb*ncoorb),
     1  h(ncoorb,ncoorb,3)
c
      nocc1 = nocca + 1
      norbs = ncoorb
      mn = nocca*nvirta
      iblrhs = iblks
c
c........loop over fields
c
      do 40 ipf = 1 , 3
         do 30 ia = nocc1 , norbs
            do 20 i = 1 , nocca
               iai = (ia-nocca-1)*nocca + i
               ff(iai) = fus(ia,i,ipf) - fus(i,ia,ipf)
 20         continue
 30      continue
         call wrt3(ff,mn,iblrhs,ifils)
         iblrhs = iblrhs + lensec(mn)
 40   continue
c
c
      call mpdslv(q)
      npert = 3
      call rdedx(h,norbs*norbs*npert,mpblk(12),ifile1)
      iblz = iblrhs
c
c........loop over fields again
c
c    combine z and h terms to give the field dependent y-matrix
c    defined in equation (27)
c
c
      do 70 ipf = 1 , 3
         call rdedx(ff,mn,iblz,ifils)
         iblz = iblz + lensec(mn)
         do 60 ia = nocc1 , norbs
            do 50 i = 1 , nocca
               iai = (ia-nocca-1)*nocca + i
               h(ia,i,ipf) = ff(iai)
 50         continue
 60      continue
 70   continue
      call delfil(nofile(1))
      return
      end
      subroutine lagbak(da,dc,v,e,y)
c
c     backtransform lagrangian type contribution to mp2 dipole
c     moment derivatives
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
c
INCLUDE(common/common)
INCLUDE(common/cndx41)
c
INCLUDE(common/infoa)
INCLUDE(common/mapper)
INCLUDE(common/atmblk)
      dimension da(nx,3),dc(nx),v(num,ncoorb),e(num),y(num)
c
c     get eigenvalues and eigenvectors
c
      ltri = ncoorb*(ncoorb+1)/2
      call secget(isect(9),9,iblok)
      call rdedx(e,ncoorb,iblok,ifild)
      call secget(isect(8),8,iblok)
      call rdedx(v,num*ncoorb,iblok+mvadd,ifild)
c
c     construct 3 field-derivative scf lagrangians in mo basis
c     and transform to ao
c
      do 60 k = 1 , 3
c
c     need occ-occ block of derivative fock operator
c
         mk69 = k + 69
         call secget(isect(k+69),mk69,iblmm)
         call rdedx(da(1,k),ltri,iblmm,ifild)
         call vclr(dc,1,ltri)
         ij = 0
         do 30 i = 1 , nocc
            do 20 j = 1 , i
               ij = ij + 1
               dc(ij) = -2.0d0*da(ij,k)
 20         continue
 30      continue
c
c     need occ-vir block of derivative density matrix
c
         m = 0
         call secget(isect(30+k),m,iblok)
         call rdedx(da(1,k),ltri,iblok,ifild)
         do 50 i = nocc + 1 , ncoorb
            do 40 j = 1 , nocc
               ij = iky(i) + j
               dc(ij) = -da(ij,k)*e(j)
 40         continue
 50      continue
c
c     back transform
c
         call demoao(dc,da(1,k),v,y,num,ncoorb,num)
 60   continue
c
c     add mp2 contribution
c
      isecll = isect(102)
      call secget(isecll,isecll,iblok)
      call search(iblok,ifild)
      do 80 i = 1 , 3
         call reads(dc,nx,ifild)
         do 70 j = 1 , nx
            da(j,i) = da(j,i) + dc(j)
 70      continue
 80   continue
      return
      end
      subroutine mpd1p3(da,fa,v,y,e,dipd,nat3)
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/sizes)
INCLUDE(common/common)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
c
      dimension e(num),y(num),v(num,ncoorb)
      dimension da(nx,3),fa(nx),dipd(3,nat3)
      ltri = ncoorb*(ncoorb+1)/2
c
c     get three 1-pdm's in da
c
      call mpdbt1(da,v,fa,y)
      call search(iochf(11),ifockf)
c
c     contract with eta matrix
c
      do 30 n = 1 , nat3
         call reads(fa,ltri,ifockf)
         do 20 i = 1 , 3
            t1 = tracep(fa,da(1,i),num)
            dipd(i,n) = dipd(i,n) - t1
 20      continue
 30   continue
c
c     get three derivative lagranians in da
c
      call lagbak(da,fa,v,e,y)
      call search(iochf(12),ifockf)
c
c     contract with derivative overlap
c
      do 50 n = 1 , nat3
         call reads(fa,ltri,ifockf)
         do 40 k = 1 , 3
            t1 = tracep(da(1,k),fa,num)
            dipd(k,n) = dipd(k,n) - t1
 40      continue
 50   continue
      return
      end
      subroutine mpdmkc(t,t1,ff,a1,a2,e,wks,eps,fus,h,u,y,w,
     1    nocc,nuoc,norbs,istrmj,istrmk)
c....................a1,a2,t,t1,ff, are all scratch areas of dim norbs*n
      implicit REAL  (a-h,o-z)
      dimension h(norbs,norbs,3),u(norbs,norbs,3)
      dimension t(norbs,norbs),t1(norbs,norbs),ff(norbs,norbs)
      dimension a1(norbs,norbs),a2(norbs,norbs),e(norbs)
      dimension eps(norbs,norbs,3),fus(norbs,norbs,3)
      dimension y(norbs,norbs),w(norbs,norbs),wks(norbs,norbs)
c
c--------------------------------------------------------------
c      this forms the matrices called f and h for each field
c      component. defined in equations (23) and (24) of
c      the paper
c
c---------------------------------------------------------------
c
      nocc1 = nocc + 1
      npert = 3
      call vclr(fus,1,norbs*norbs*npert)
      call vclr(h,1,norbs*norbs*npert)
c
      do 30 j = 1 , norbs
         do 20 i = 1 , norbs
            a1(i,j) = w(i,j) + w(j,i)
            ff(i,j) = -(y(i,j)+y(j,i))
 20      continue
 30   continue
      do 50 j = 1 , norbs
         do 40 i = 1 , norbs
            w(i,j) = -a1(i,j)
            y(i,j) = -ff(i,j)
 40      continue
 50   continue
      call vclr(ff,1,norbs*norbs)
      call vclr(a1,1,norbs*norbs)
c
      ifint1 = istrmj
      ifint2 = istrmk
      call rewedz(ifint1)
      call rewedz(ifint2)
      do 1020 iip = 1 , norbs
         do 1010 iiq = 1 , iip
            call rdedz(a2,norbs*norbs,ifint1)
            call rdedz(a1,norbs*norbs,ifint2)
            if (iiq.gt.nocc) then
c...................(ab) integrals
               ia = iip
               ib = iiq
               eab = e(ia) + e(ib)
               itr = 0
c.........t(ij|ab)
               do 70 j = 1 , nocc
                  do 60 i = 1 , nocc
                     wks(i,j) = 1.0d0/(eab-e(i)-e(j))
 60               continue
 70            continue
 80            do 100 j = 1 , nocc
                  do 90 i = 1 , nocc
                     t(i,j) = -4.0d0*(a1(i,j)+a1(i,j)-a1(j,i))*wks(i,j)
 90               continue
 100           continue
               do 150 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
c...201..........(u(d,j)*t(i,j)=ff(d,i)*(pa|db)=fus(p,i)
                  call mxmb(u(nocc1,1,ie),1,norbs,t,norbs,1,ff(nocc1,1),
     +                      1,norbs,nuoc,nocc,nocc)
c...201..............long
                  call mxmb(ff(nocc1,1),norbs,1,a1(1,nocc1),norbs,1,
     +                      fus(1,1,ie),norbs,1,nocc,nuoc,norbs)
c...301.........2*(ai|bc)-(ac|bi)
                  do 120 i = 1 , nocc
                     do 110 ic = nocc + 1 , norbs
                        t(i,ic) = -4.0d0*(a1(i,ic)+a1(i,ic)-a1(ic,i))
 110                 continue
 120              continue
c...301.............u(c,j)*t(i,c)=ff(j,i)/d(ij|ab)/*(ar|bj)=fus(r,i)
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(u(nocc1,1,ie),norbs,1,t(1,nocc1),norbs,1,ff,
     +                      1,norbs,nocc,nuoc,nocc)
c...302..........eps(j,k)*t(i,k)=ff(j,i)
                  call mxmb(eps(1,1,ie),1,norbs,t,norbs,1,ff,1,norbs,
     +                      nocc,nocc,nocc)
                  do 140 i = 1 , nocc
                     do 130 j = 1 , nocc
                        ff(j,i) = ff(j,i)*wks(j,i)
 130                 continue
 140              continue
c........301+302....
                  call mxmb(ff,norbs,1,a1,norbs,1,fus(1,1,ie),norbs,1,
     +                      nocc,nocc,norbs)
 150           continue
               do 170 k = 1 , nocc
                  do 160 i = 1 , nocc
                     t1(i,k) = a1(i,k)*wks(i,k)
 160              continue
 170           continue
c..401....t(kl)*e(lj)+t(lj)*e(lk)=ff(jk)/d(jk|ab)/*t1(ij)=h(ki)
               do 220 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(eps(1,1,ie),1,norbs,t,norbs,1,ff,1,norbs,
     +                      nocc,nocc,nocc)
                  call mxmb(eps(1,1,ie),1,norbs,t,1,norbs,ff,norbs,1,
     +                      nocc,nocc,nocc)
                  do 190 j = 1 , nocc
                     do 180 k = 1 , nocc
                        ff(j,k) = ff(j,k)*wks(j,k)
 180                 continue
 190              continue
                  call mxmb(ff,norbs,1,t1,norbs,1,h(1,1,ie),1,norbs,
     +                      nocc,nocc,nocc)
c..402....u(c,i)*(ca|jb)+u(c,j)*(ia|cb)=ff(i,j)/d(i,j)/*t(ik|ab)=h(j,k)
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(u(nocc1,1,ie),norbs,1,a1(nocc1,1),1,norbs,
     +                      ff,1,norbs,nocc,nuoc,nocc)
                  call mxmb(u(nocc1,1,ie),norbs,1,a1(1,nocc1),norbs,1,
     +                      ff,norbs,1,nocc,nuoc,nocc)
                  do 210 j = 1 , nocc
                     do 200 i = 1 , nocc
                        ff(i,j) = ff(i,j)*wks(i,j)
 200                 continue
 210              continue
                  call mxmb(ff,norbs,1,t,1,norbs,h(1,1,ie),1,norbs,nocc,
     +                      nocc,nocc)
 220           continue
               itr = itr + 1
               if (itr.ne.2 .and. ia.ne.ib) then
                  do 240 ip = 2 , norbs
                     do 230 iq = 1 , ip - 1
                        zz = a1(ip,iq)
                        a1(ip,iq) = a1(iq,ip)
                        a1(iq,ip) = zz
 230                 continue
 240              continue
                  go to 80
               end if
            else if (iip.le.nocc) then
c..................(ij) integrals
               i = iip
               j = iiq
               eij = e(i) + e(j)
               itr = 0
               do 260 ia = nocc + 1 , norbs
                  do 250 ib = nocc + 1 , norbs
                     wks(ib,ia) = 1.0d0/(e(ib)+e(ia)-eij)
 250              continue
 260           continue
 270           do 290 ib = nocc1 , norbs
                  do 280 ia = nocc1 , norbs
                     t(ia,ib) = -4.0d0*(a1(ia,ib)+a1(ia,ib)-a1(ib,ia))
     +                          *wks(ia,ib)
 280              continue
 290           continue
               do 300 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
c..202.............u(l,a)*(il|jp)=ff(p,a)*t(ij|ab)=fus(p,b)
                  call mxmb(u(1,nocc1,ie),norbs,1,a1,1,norbs,ff(1,nocc1)
     +                      ,norbs,1,nuoc,nocc,norbs)
                  call mxmb(ff(1,nocc1),1,norbs,t(nocc1,nocc1),1,norbs,
     +                      fus(1,nocc1,ie),1,norbs,norbs,nuoc,nuoc)
 300           continue
c...303...........2*(ik|ja)-(ia|jk)
               do 320 k = 1 , nocc
                  do 310 ia = nocc + 1 , norbs
                     t(k,ia) = 4.0d0*(a1(k,ia)+a1(k,ia)-a1(ia,k))
 310              continue
 320           continue
               do 350 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
c..303.............u(k,b)*t(k,a)=ff(b,a)/d(ij|ab)/*(ib,jr)=fus(r,a)
                  call mxmb(u(1,nocc1,ie),norbs,1,t(1,nocc1),1,norbs,
     +                      ff(nocc1,nocc1),1,norbs,nuoc,nocc,nuoc)
c..304........eps(b,c)*t(a,c)=ff(b,a)
                  call mxmb(eps(nocc1,nocc1,ie),1,norbs,t(nocc1,nocc1),
     +                      1,norbs,ff(nocc1,nocc1),1,norbs,nuoc,nuoc,
     +                      nuoc)
                  do 340 ib = nocc1 , norbs
                     do 330 ia = nocc1 , norbs
                        ff(ia,ib) = -ff(ia,ib)*wks(ia,ib)
 330                 continue
 340              continue
c...............303+304.../
                  call mxmb(ff(nocc1,nocc1),norbs,1,a1(nocc1,1),1,norbs,
     +                      fus(1,nocc1,ie),norbs,1,nuoc,nuoc,norbs)
 350           continue
               do 370 ic = nocc1 , norbs
                  do 360 ia = nocc1 , norbs
                     t1(ia,ic) = a1(ia,ic)*wks(ia,ic)
 360              continue
 370           continue
c..403....eps(b,d)*t(c,d)+eps(c,d)*t(d,b)=ff(b,c)/d(ij|cb)/*t1(ab)=h(ac)
               do 420 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(eps(nocc1,nocc1,ie),1,norbs,t(nocc1,nocc1),
     +                      norbs,1,ff(nocc1,nocc1),1,norbs,nuoc,nuoc,
     +                      nuoc)
                  call mxmb(eps(nocc1,nocc1,ie),1,norbs,t(nocc1,nocc1),
     +                      1,norbs,ff(nocc1,nocc1),norbs,1,nuoc,nuoc,
     +                      nuoc)
                  do 390 ic = nocc1 , norbs
                     do 380 ib = nocc1 , norbs
                        ff(ib,ic) = ff(ib,ic)*wks(ib,ic)
 380                 continue
 390              continue
                  call mxmb(ff(nocc1,nocc1),norbs,1,t1(nocc1,nocc1),
     +                      norbs,1,h(nocc1,nocc1,ie),norbs,1,nuoc,nuoc,
     +                      nuoc)
c..404....u(k,a)*(ik|jb)+u(k,b)*(ia|jk)=ff(a,b)/d(ij|ab)/*t(ij|ac)=h(b,c
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(u(1,nocc1,ie),norbs,1,a1(1,nocc1),1,norbs,
     +                      ff(nocc1,nocc1),1,norbs,nuoc,nocc,nuoc)
                  call mxmb(u(1,nocc1,ie),norbs,1,a1(nocc1,1),norbs,1,
     +                      ff(nocc1,nocc1),norbs,1,nuoc,nocc,nuoc)
                  do 410 ib = nocc1 , norbs
                     do 400 ia = nocc1 , norbs
                        ff(ia,ib) = -ff(ia,ib)*wks(ia,ib)
 400                 continue
 410              continue
                  call mxmb(ff(nocc1,nocc1),norbs,1,t(nocc1,nocc1),1,
     +                      norbs,h(nocc1,nocc1,ie),1,norbs,nuoc,nuoc,
     +                      nuoc)
 420           continue
               itr = itr + 1
               if (itr.ne.2 .and. i.ne.j) then
                  do 440 ip = 2 , norbs
                     do 430 iq = 1 , ip - 1
                        zz = a1(ip,iq)
                        a1(ip,iq) = a1(iq,ip)
                        a1(iq,ip) = zz
 430                 continue
 440              continue
                  go to 270
               end if
            else
c...............(bj) integrals
               ib = iip
               j = iiq
               ebj = e(ib) - e(j)
               do 460 i = 1 , nocc
                  do 450 ia = nocc + 1 , norbs
                     wks(i,ia) = 1.0d0/(e(ia)+ebj-e(i))
 450              continue
 460           continue
c..........t(ji|ba)
               do 480 i = 1 , nocc
                  do 470 ia = nocc + 1 , norbs
                     t(i,ia) = -4.0d0*(a2(i,ia)+a2(i,ia)-a1(i,ia))
     +                         *wks(i,ia)
 470              continue
 480           continue
               do 490 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
c..203.......(pl|jb)*u(l,a) = ff(pa) ; ff(p,a)*t(ia) = fus(p,i)
                  call mxmb(u(1,nocc1,ie),norbs,1,a2,norbs,1,ff(1,nocc1)
     +                      ,norbs,1,nuoc,nocc,norbs)
                  call mxmb(ff(1,nocc1),1,norbs,t(1,nocc1),norbs,1,
     +                      fus(1,1,ie),1,norbs,norbs,nuoc,nocc)
                  call vclr(ff,1,norbs*norbs)
c..204............u(d,i)*(dp|jb) = ff(p,i) ; ff(p,i)*t(i,a) = fus(p,a)
                  call mxmb(u(nocc1,1,ie),norbs,1,a2(nocc1,1),1,norbs,
     +                      ff,norbs,1,nocc,nuoc,norbs)
                  call mxmb(ff,1,norbs,t(1,nocc1),1,norbs,
     +                      fus(1,nocc1,ie),1,norbs,norbs,nocc,nuoc)
 490           continue
               do 510 i = 1 , nocc
                  do 500 ia = nocc + 1 , norbs
                     t(i,ia) = -4.0d0*(a1(i,ia)+a1(i,ia)-a2(i,ia))
     +                         *wks(i,ia)
 500              continue
 510           continue
               do 520 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
c..205.......u(d,i)*(bd|jp) = ff(i,p) ; ff(i,p)*t(ia) = fus(p,a)
                  call mxmb(u(nocc1,1,ie),norbs,1,a1(nocc1,1),1,norbs,
     +                      ff,1,norbs,nocc,nuoc,norbs)
                  call mxmb(ff,norbs,1,t(1,nocc1),1,norbs,
     +                      fus(1,nocc1,ie),1,norbs,norbs,nocc,nuoc)
                  call vclr(ff,1,norbs*norbs)
c...206......u(l,a)*(bp|jl) = ff(a,p) , ff(a,p)*t(i,a) = fus(p,i)
                  call mxmb(u(1,nocc1,ie),norbs,1,a1,norbs,1,ff(nocc1,1)
     +                      ,1,norbs,nuoc,nocc,norbs)
                  call mxmb(ff(nocc1,1),norbs,1,t(1,nocc1),norbs,1,
     +                      fus(1,1,ie),1,norbs,norbs,nuoc,nocc)
 520           continue
c..305...........2(ik|bj) - (bi|jk)
               do 540 i = 1 , nocc
                  do 530 k = 1 , nocc
                     t(i,k) = a2(i,k) + a2(i,k) - a1(i,k)
 530              continue
 540           continue
c..310...........2(ac|bj) - (bc|ja)
               do 560 ia = nocc1 , norbs
                  do 550 ic = nocc1 , norbs
                     t(ia,ic) = a2(ia,ic) + a2(ia,ic) - a1(ic,ia)
 550              continue
 560           continue
               do 580 i = 1 , nocc
                  do 570 ia = nocc + 1 , norbs
                     t(i,ia) = (a2(i,ia)+a2(i,ia)-a1(i,ia))*wks(i,ia)
                     t(ia,i) = -t(i,ia)
 570              continue
 580           continue
c..305........u(k,a)*t(i,k) = ff(a,i)/d(i,j)/ff(a,i)*(ri|jb) =fus(r,a) a
c............ff(a,i)*(ar|jb) = fus(r,i)
               do 610 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(u(1,nocc1,ie),norbs,1,t,norbs,1,ff(nocc1,1),
     +                      1,norbs,nuoc,nocc,nocc)
c...310............u(c,i)*t(a,c) = ff(a,i)/d(i,j)/ff(a,i)(ri|jb) = fus(r
c............and  ff(a,i)*(ar|bj) = fus(r,i)
                  call mxmb(u(nocc1,1,ie),norbs,1,t(nocc1,nocc1),norbs,
     +                      1,ff(nocc1,1),norbs,1,nocc,nuoc,nuoc)
c....311....e(a,c)*t(c,i)-e(i,k)*t(k,a)=ff(a,i)
                  call mxmb(eps(nocc1,nocc1,ie),1,norbs,t(nocc1,1),1,
     +                      norbs,ff(nocc1,1),1,norbs,nuoc,nuoc,nocc)
                  call mxmb(eps(1,1,ie),1,norbs,t(1,nocc1),1,norbs,
     +                      ff(nocc1,1),norbs,1,nocc,nocc,nuoc)
c...............305+310+311
                  do 600 i = 1 , nocc
                     do 590 ia = nocc + 1 , norbs
                        ff(ia,i) = -4.0d0*ff(ia,i)*wks(i,ia)
 590                 continue
 600              continue
                  call mxmb(ff(nocc1,1),1,norbs,a2,norbs,1,
     +                      fus(1,nocc1,ie),norbs,1,nuoc,nocc,norbs)
                  call mxmb(ff(nocc1,1),norbs,1,a2(nocc1,1),1,norbs,
     +                      fus(1,1,ie),norbs,1,nocc,nuoc,norbs)
 610           continue
               do 630 i = 1 , nocc
                  do 620 ic = nocc + 1 , norbs
                     t(ic,i) = (a2(ic,i)+a2(ic,i)-a1(i,ic))*wks(i,ic)
                     t(i,ic) = a2(ic,i)*wks(i,ic)
 620              continue
 630           continue
c..405..........e(k,i)*t(c,k) = ff(i,c)/d(i,j)/ff(i,c)*t(i,a) = h(a,c)
               do 680 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(eps(1,1,ie),norbs,1,t(nocc1,1),norbs,1,
     +                      ff(1,nocc1),1,norbs,nocc,nocc,nuoc)
                  do 650 i = 1 , nocc
                     do 640 ic = nocc + 1 , norbs
                        ff(i,ic) = 4.0d0*ff(i,ic)*wks(i,ic)
 640                 continue
 650              continue
                  call mxmb(ff(1,nocc1),norbs,1,t(1,nocc1),1,norbs,
     +                      h(nocc1,nocc1,ie),norbs,1,nuoc,nocc,nuoc)
c...406....e(a,d)*t(d,k) = ff(a,k)/d(j,k)/ ff(a,k)*t(i,a)=h(k,i)
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(eps(nocc1,nocc1,ie),1,norbs,t(nocc1,1),1,
     +                      norbs,ff(nocc1,1),1,norbs,nuoc,nuoc,nocc)
                  do 670 k = 1 , nocc
                     do 660 ia = nocc + 1 , norbs
                        ff(ia,k) = 4.0d0*ff(ia,k)*wks(k,ia)
 660                 continue
 670              continue
                  call mxmb(ff(nocc1,1),norbs,1,t(1,nocc1),norbs,1,
     +                      h(1,1,ie),1,norbs,nocc,nuoc,nocc)
 680           continue
c...306..........2(bc|ja)-(bj|ca)
               do 700 ic = nocc1 , norbs
                  do 690 ia = nocc1 , norbs
                     t(ic,ia) = a1(ic,ia) + a1(ic,ia) - a2(ic,ia)
 690              continue
 700           continue
c................307..2(bk|ja)-(bj|ka)
               do 720 k = 1 , nocc
                  do 710 ia = nocc + 1 , norbs
                     t(k,ia) = (a1(k,ia)+a1(k,ia)-a2(k,ia))*wks(k,ia)
 710              continue
 720           continue
c..307...........e(i,k)*t(k,a) = ff(i,a)
               do 750 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(eps(1,1,ie),1,norbs,t(1,nocc1),1,norbs,
     +                      ff(1,nocc1),1,norbs,nocc,nocc,nuoc)
c..306.......u(c,i)*t(c,a)=ff(i,a)/d(i,j)/ff(i,a)*(bi|jr) = fus(r,a)
                  call mxmb(u(nocc1,1,ie),norbs,1,t(nocc1,nocc1),1,
     +                      norbs,ff(1,nocc1),1,norbs,nocc,nuoc,nuoc)
c.............306+307.........
                  do 740 i = 1 , nocc
                     do 730 ia = nocc + 1 , norbs
                        ff(i,ia) = -4.0d0*ff(i,ia)*wks(i,ia)
 730                 continue
 740              continue
                  call mxmb(ff(1,nocc1),norbs,1,a1,1,norbs,
     +                      fus(1,nocc1,ie),norbs,1,nuoc,nocc,norbs)
 750           continue
c....308..........2(bi|jk) - (bj|ik)
               do 770 i = 1 , nocc
                  do 760 k = 1 , nocc
                     t(i,k) = a1(i,k) + a1(i,k) - a2(i,k)
 760              continue
 770           continue
c...309.......2(bi|jc) - (jb|ci)
               do 790 i = 1 , nocc
                  do 780 ic = nocc + 1 , norbs
                     t(i,ic) = -(a1(i,ic)+a1(i,ic)-a2(i,ic))*wks(i,ic)
 780              continue
 790           continue
c..309......e(a,c) * t(i,c) = ff(a,i)
               do 820 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(eps(nocc1,nocc1,ie),1,norbs,t(1,nocc1),
     +                      norbs,1,ff(nocc1,1),1,norbs,nuoc,nuoc,nocc)
c..308....u(k,a)*t(i,k) = ff(a,i)/d(i,j)/ff(a,i)*(br|ja) = fus(r,i)
                  call mxmb(u(1,nocc1,ie),norbs,1,t,norbs,1,ff(nocc1,1),
     +                      1,norbs,nuoc,nocc,nocc)
                  do 810 i = 1 , nocc
                     do 800 ia = nocc + 1 , norbs
                        ff(ia,i) = -4.0d0*ff(ia,i)*wks(i,ia)
 800                 continue
 810              continue
c.................308+309..../
                  call mxmb(ff(nocc1,1),norbs,1,a1(1,nocc1),norbs,1,
     +                      fus(1,1,ie),norbs,1,nocc,nuoc,norbs)
 820           continue
               do 840 i = 1 , nocc
                  do 830 ia = nocc + 1 , norbs
                     t(ia,i) = (a1(i,ia)+a1(i,ia)-a2(i,ia))*wks(i,ia)
                     t(i,ia) = a1(i,ia)*wks(i,ia)
 830              continue
 840           continue
c...408.......e(k,i)*t(c,k) = ff(i,c)/d(i,j)/ff(i,c)*t(i,a) = h(a,c)
               do 890 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
                  call mxmb(eps(1,1,ie),norbs,1,t(nocc1,1),norbs,1,
     +                      ff(1,nocc1),1,norbs,nocc,nocc,nuoc)
                  do 860 i = 1 , nocc
                     do 850 ic = nocc + 1 , norbs
                        ff(i,ic) = 4.0d0*ff(i,ic)*wks(i,ic)
 850                 continue
 860              continue
                  call mxmb(ff(1,nocc1),norbs,1,t(1,nocc1),1,norbs,
     +                      h(nocc1,nocc1,ie),norbs,1,nuoc,nocc,nuoc)
                  call vclr(ff,1,norbs*norbs)
c..407.......e(a,d)*t(d,k) = ff(a,k)/d(j,k)/ff(a,k)*t(i,a) = h(k,i)
                  call mxmb(eps(nocc1,nocc1,ie),1,norbs,t(nocc1,1),1,
     +                      norbs,ff(nocc1,1),1,norbs,nuoc,nuoc,nocc)
                  do 880 k = 1 , nocc
                     do 870 ia = nocc + 1 , norbs
                        ff(ia,k) = 4.0d0*ff(ia,k)*wks(k,ia)
 870                 continue
 880              continue
                  call mxmb(ff(nocc1,1),norbs,1,t(1,nocc1),norbs,1,
     +                      h(1,1,ie),1,norbs,nocc,nuoc,nocc)
 890           continue
               do 910 i = 1 , nocc
                  do 900 ia = nocc + 1 , norbs
                     t(i,ia) = (a2(ia,i)+a2(ia,i)-a1(i,ia))*wks(i,ia)
 900              continue
 910           continue
               do 1000 ie = 1 , 3
                  call vclr(ff,1,norbs*norbs)
c..409............u(d,i)*(db|ja) = ff(i,a)/d(i,j)/*t(c,i) = h(a,c)
                  call mxmb(u(nocc1,1,ie),norbs,1,a1(nocc1,nocc1),1,
     +                      norbs,ff(1,nocc1),1,norbs,nocc,nuoc,nuoc)
                  do 930 i = 1 , nocc
                     do 920 ia = nocc + 1 , norbs
                        ff(i,ia) = 4.0d0*ff(i,ia)*wks(i,ia)
 920                 continue
 930              continue
                  call mxmb(ff(1,nocc1),norbs,1,t(nocc1,1),norbs,1,
     +                      h(nocc1,nocc1,ie),1,norbs,nuoc,nocc,nuoc)
                  call vclr(ff,1,norbs*norbs)
c..410........u(d,i)*(bj|da) = ff(i,a)/d(i,j)/*t(i,c) = h(a,c)
                  call mxmb(u(nocc1,1,ie),norbs,1,a2(nocc1,nocc1),1,
     +                      norbs,ff(1,nocc1),1,norbs,nocc,nuoc,nuoc)
                  do 950 i = 1 , nocc
                     do 940 ia = nocc + 1 , norbs
                        ff(i,ia) = 4.0d0*ff(i,ia)*wks(i,ia)
 940                 continue
 950              continue
                  call mxmb(ff(1,nocc1),norbs,1,t(1,nocc1),1,norbs,
     +                      h(nocc1,nocc1,ie),1,norbs,nuoc,nocc,nuoc)
                  call vclr(ff,1,norbs*norbs)
c..411......u(l,a)*(bi|jl) = ff(a,i)/d(i,j)/*t(a,k) = h(i,k)
                  call mxmb(u(1,nocc1,ie),norbs,1,a1,norbs,1,ff(nocc1,1)
     +                      ,1,norbs,nuoc,nocc,nocc)
                  do 970 i = 1 , nocc
                     do 960 ia = nocc + 1 , norbs
                        ff(ia,i) = -4.0d0*ff(ia,i)*wks(i,ia)
 960                 continue
 970              continue
                  call mxmb(ff(nocc1,1),norbs,1,t(nocc1,1),1,norbs,
     +                      h(1,1,ie),1,norbs,nocc,nuoc,nocc)
                  call vclr(ff,1,norbs*norbs)
c..412......u(l,a)*(bj|il) = ff(a,i)/d(i,j)/*t(k,a) = h(i,k)
                  call mxmb(u(1,nocc1,ie),norbs,1,a2,norbs,1,ff(nocc1,1)
     +                      ,1,norbs,nuoc,nocc,nocc)
                  do 990 i = 1 , nocc
                     do 980 ia = nocc + 1 , norbs
                        ff(ia,i) = -4.0d0*ff(ia,i)*wks(i,ia)
 980                 continue
 990              continue
                  call mxmb(ff(nocc1,1),norbs,1,t(1,nocc1),norbs,1,
     +                      h(1,1,ie),1,norbs,nocc,nuoc,nocc)
 1000          continue
            end if
 1010    continue
 1020 continue
c
c
c................y holds -(y(pq)+y(qp))
      do 1150 ie = 1 , 3
c..............601 u(ai)*y(ib)=h(ab)
         call mxmb(u(nocc1,1,ie),1,norbs,y(1,nocc1),1,norbs,
     +             h(nocc1,nocc1,ie),1,norbs,nuoc,nocc,nuoc)
c..............601 u(ia)*y(aj)=h(ij)
         call mxmb(u(1,nocc1,ie),1,norbs,y(nocc1,1),1,norbs,h(1,1,ie),1,
     +             norbs,nocc,nuoc,nocc)
c.........602 e(ji)*y(ir)=fus(jr)
         call mxmb(eps(1,1,ie),1,norbs,y,1,norbs,fus(1,1,ie),1,norbs,
     +             nocc,nocc,norbs)
c.........603 e(ba)*y(ar)=fus(br)
         call mxmb(eps(nocc1,nocc1,ie),1,norbs,y(nocc1,1),1,norbs,
     +             fus(nocc1,1,ie),1,norbs,nuoc,nuoc,norbs)
c.......604
         do 1050 i = 1 , nocc
            do 1040 ia = nocc + 1 , norbs
               zz = u(ia,i,ie)*(e(ia)-e(i))
               do 1030 ip = 1 , norbs
cnm  803 fus(i,ip,ie)=fus(i,ip,ie)+y(ia,ip)*zz
                  fus(i,ip,ie) = fus(i,ip,ie) - y(ia,ip)*zz
 1030          continue
 1040       continue
 1050    continue
c........605
         do 1080 ia = nocc + 1 , norbs
            do 1070 i = 1 , nocc
               zz = u(ia,i,ie)*(e(ia)-e(i))
               do 1060 ip = 1 , norbs
cnm  804 fus(ia,ip,ie)=fus(ia,ip,ie)+y(i,ip)*zz
                  fus(ia,ip,ie) = fus(ia,ip,ie) - y(i,ip)*zz
 1060          continue
 1070       continue
 1080    continue
c...606
         do 1110 i = 1 , nocc
            do 1100 ib = nocc + 1 , norbs
               do 1090 ip = 1 , norbs
cnm  805 fus(ip,i,ie)=fus(ip,i,ie)+y(ip,ib)*u(i,ib,ie)*e(ip)
                  fus(ip,i,ie) = fus(ip,i,ie) - y(ip,ib)*u(i,ib,ie)
     +                           *e(ip)
 1090          continue
 1100       continue
 1110    continue
c.......607
         do 1140 j = 1 , nocc
            do 1130 ia = nocc + 1 , norbs
               do 1120 ip = 1 , norbs
                  fus(ip,ia,ie) = fus(ip,ia,ie) - y(ip,j)*u(ia,j,ie)
     +                            *e(ip)
 1120          continue
 1130       continue
 1140    continue
c...608 ....u(ai)*w(ap)=fus(pi)
         call mxmb(u(nocc1,1,ie),norbs,1,w(nocc1,1),1,norbs,fus(1,1,ie),
     +             norbs,1,nocc,nuoc,norbs)
c
c....609 ..u(ia)*w(ip)=fus(pa)
         call mxmb(u(1,nocc1,ie),norbs,1,w,1,norbs,fus(1,nocc1,ie),
     +             norbs,1,nuoc,nocc,norbs)
 1150 continue
c
c.......reading a
c
      call rewedz(istrmj)
      call rewedz(istrmk)
      do 1250 ip = 1 , norbs
         do 1240 iq = 1 , ip
            call rdedz(a1,norbs*norbs,istrmj)
            call rdedz(a2,norbs*norbs,istrmk)
            do 1170 ir = 1 , norbs
               do 1160 is = 1 , norbs
                  a1(is,ir) = 4.0d0*a1(is,ir) - a2(is,ir) - a2(ir,is)
 1160          continue
 1170       continue
            zz = 1.0d0
            if (ip.eq.iq) zz = 0.5d0
            do 1190 ir = nocc1 , norbs
               do 1180 is = 1 , norbs
                  a2(ir,is) = a1(ir,is)*zz*y(ip,iq)
 1180          continue
 1190       continue
c.....610........u(aj)*a2(at)=fus(tj)
            do 1200 ie = 1 , 3
               call mxmb(u(nocc1,1,ie),norbs,1,a2(nocc1,1),1,norbs,
     +                   fus(1,1,ie),norbs,1,nocc,nuoc,norbs)
 1200       continue
c.............611....h(pq)*a1(kj)=fus(kj)
            if (ip.le.nocc .or. iq.gt.nocc) then
               do 1230 ie = 1 , 3
                  zzz = (h(ip,iq,ie)+h(iq,ip,ie))*zz
                  do 1220 j = 1 , nocc
                     do 1210 ib = 1 , norbs
                        fus(ib,j,ie) = fus(ib,j,ie) + zzz*a1(ib,j)
 1210                continue
 1220             continue
 1230          continue
            end if
 1240    continue
 1250 continue
c............612....h(pq)*(e(p)+e(q))
      do 1300 ie = 1 , 3
         do 1270 ip = nocc1 , norbs
            do 1260 iq = nocc1 , norbs
               fus(ip,iq,ie) = fus(ip,iq,ie) + h(ip,iq,ie)*(e(ip)+e(iq))
 1260       continue
 1270    continue
         do 1290 ip = 1 , nocc
            do 1280 iq = 1 , nocc
               fus(ip,iq,ie) = fus(ip,iq,ie) + h(ip,iq,ie)*(e(ip)+e(iq))
 1280       continue
 1290    continue
 1300 continue
c      do 848 ie=1,3
c      call mout(fus(1,1,ie),norbs,norbs,norbs,6)
c  848 call mout(h(1,1,ie),norbs,norbs,norbs,6)
cc.......y(p,q) is coefficient of -h(pq,xb)
c.......fus(ib,j,ie)-fus(j,ib,ie) is coefficient of u(b,j,x)
c.......-0.5*fus(ip,iq,ie) is coefficient of s(p,q,x)
      return
      end
      subroutine mpdmkg(t,u,eps,ff,e,ip,nocca,nocc1,norbs,nvirt,
     1    ff1,ebj,vec)
c
c ------------------------------------------------------------
c    does most of the actual work for edstpd
c
c--------------------------------given field do the tpdm
c
c--------------------------------------------------------------
      implicit REAL  (a-h,o-z)
      common/mpdfil/mpfile(3)
      dimension t(norbs,norbs),u(norbs,norbs,3),eps(norbs,norbs,3),
     1   ff(norbs,norbs),ff1(norbs,norbs),e(norbs),vec(norbs*norbs)
c
c
c
c.......t(i,a)*u(c,i)=g(a,c)
      call vclr(ff,1,norbs*norbs)
      call mxmb(t(1,nocc1),norbs,1,u(nocc1,1,ip),norbs,1,ff(nocc1,nocc1)
     +          ,norbs,1,nvirt,nocca,nvirt)
c.......t(i,a)*u(k,a)=g(i,k)
      call mxmb(t(1,nocc1),1,norbs,u(1,nocc1,ip),norbs,1,ff,1,norbs,
     +          nocca,nvirt,nocca)
c
c
c......t(c,a)*u(c,i)=ff1(a,i)/dijab=g(a,i)
      call vclr(ff1,1,norbs*norbs)
c......-t(i,c)*e(a,c)=ff1(a,i)
      call mxmb(t(1,nocc1),1,norbs,eps(nocc1,nocc1,ip),norbs,1,
     +          ff1(nocc1,1),norbs,1,nocca,nvirt,nvirt)
      do 30 ia = nocc1 , norbs
         do 20 i = 1 , nocca
            ff1(ia,i) = -ff1(ia,i)
 20      continue
 30   continue
c
c................
      call mxmb(t(nocc1,nocc1),norbs,1,u(nocc1,1,ip),1,norbs,
     +          ff1(nocc1,1),1,norbs,nvirt,nvirt,nocca)
c........t(i,k)*u(k,a)=ff1(a,i)/dijab=g(a,i)
      call mxmb(t,1,norbs,u(1,nocc1,ip),1,norbs,ff1(nocc1,1),norbs,1,
     +          nocca,nocca,nvirt)
c........t(k,a)*e(i,k)=ff1(a,i)
      call mxmb(t(1,nocc1),norbs,1,eps(1,1,ip),norbs,1,ff1(nocc1,1),1,
     +          norbs,nvirt,nocca,nocca)
c
      do 50 ia = nocc1 , norbs
         do 40 i = 1 , nocca
            ff(ia,i) = ff1(ia,i)/(ebj+e(ia)-e(i))
 40      continue
 50   continue
c
      call mpdtr(ff,vec,ff1,norbs)
c
      call symm1b(ff1,ff,norbs,ntri)
c
      call wtedz(ff1,ntri,mpfile(ip))
      return
      end
      subroutine mkdmkw(y,z,w,ibly,iblz,iblw,a1,a2,nocca,
     1   nvirta,ncoorb,ifils,e,istrmj,istrmk,ifile1)
      implicit REAL  (a-h,o-z)
      dimension y(ncoorb,ncoorb),w(ncoorb,ncoorb),
     1  z(nocca*nvirta),a1(ncoorb,ncoorb),a2(ncoorb,ncoorb),
     2 e(ncoorb)
c
c ---------------------------------------------------------
c     make the matrices y and w which multiply the
c     derivative 1-electron integrals in the gradient
c
c-----------------------------------------------------------
c
c
      call rewedz(istrmj)
      call rewedz(istrmk)
      call rdedx(z,nocca*nvirta,iblz,ifils)
      call rdedx(y,ncoorb*ncoorb,ibly,ifile1)
c
c     define matrix y as in equation (8) of the paper
c
      do 30 ia = nocca + 1 , ncoorb
         do 20 i = 1 , nocca
            iai = (ia-nocca-1)*nocca + i
            y(ia,i) = -z(iai)
 20      continue
 30   continue
      call wrt3(y,ncoorb*ncoorb,ibly,ifile1)
c
c
      call rdedx(a1,ncoorb*ncoorb,iblw,ifile1)
c
c      calculate the matrix w defined in equation (10)
c      of the paper. are using some of the intermediate
c      results from routine mkyir
c
      do 50 is = 1 , ncoorb
         do 40 ir = 1 , ncoorb
            w(ir,is) = y(ir,is)*e(is)
 40      continue
 50   continue
      do 70 j = 1 , nocca
         do 60 i = 1 , nocca
            w(i,j) = w(i,j) - 0.5d0*a1(i,j)
 60      continue
 70   continue
      do 90 j = nocca + 1 , ncoorb
         do 80 i = nocca + 1 , ncoorb
            w(i,j) = w(i,j) - 0.5d0*a1(i,j)
 80      continue
 90   continue
      do 110 ia = nocca + 1 , ncoorb
         do 100 i = 1 , nocca
            w(i,ia) = w(i,ia) - a1(i,ia)
 100     continue
 110  continue
c
c
      do 150 j = 1 , nocca
         do 140 k = 1 , j
            call rdedz(a1,ncoorb*ncoorb,istrmj)
            call rdedz(a2,ncoorb*ncoorb,istrmk)
            zz = 0.0d0
            do 130 is = 1 , ncoorb
               do 120 ir = 1 , ncoorb
                  zz = zz + 0.5d0*y(ir,is)
     +                 *(4.0d0*a1(ir,is)-a2(ir,is)-a2(is,ir))
 120           continue
 130        continue
            w(j,k) = w(j,k) + zz
            if (j.ne.k) w(k,j) = w(k,j) + zz
 140     continue
 150  continue
      call wrt3(w,ncoorb*ncoorb,iblw,ifile1)
      return
      end
      subroutine mpdmky(a1,a2,e,ncoorb,y,zlg,
     +                  nocca,istrmy,nvirt,t,
     +            iblw,iblks,ifils,b,mn,istrmj,istrmk,ifile1)
c
c--------------------------------------------------------------------
c     calculate the y-matrix and the r.h.s of coupled
c     hartree-fock equations
c-------------------------------------------------------------------
      implicit REAL  (a-h,o-z)
      dimension a1(ncoorb,ncoorb),a2(ncoorb,ncoorb),e(ncoorb),
     + y(ncoorb,ncoorb),t(ncoorb,ncoorb),
     + zlg(ncoorb,ncoorb),b(mn)
      common/crio/last(40)
c
c
      nocc = nocca
      norbs = ncoorb
      nocc1 = nocc + 1
c     nocc2 = nocc + 2
      call vclr(y,1,norbs*norbs)
      call vclr(zlg,1,norbs*norbs)
c
      ifint1 = istrmj
      ifint2 = istrmk
      call rewedz(ifint1)
      call rewedz(ifint2)
      do 70 ip = 1 , norbs
         do 60 iq = 1 , ip
            call rdedz(a1,norbs*norbs,ifint1)
            call rdedz(a2,norbs*norbs,ifint2)
c
c      do 11 j=1,norbs
c      do 11 i=1,norbs
c11    t(i,j)=a1(i,j)+a1(i,j)+a1(i,j)+a1(i,j)-a2(i,j)-a2(j,i)
c      call wrtmp(t,ncoorb*ncoorb,istrma)
            call vclr(t,1,norbs*norbs)
            if (iq.le.nocca) then
               if (ip.gt.nocca) then
                  ebj = e(ip) - e(iq)
c      form a block of the t-vector
c
c
                  do 30 i = 1 , nocc
                     do 20 ia = nocc1 , norbs
                        t(i,ia) = 4.0d0*(a1(i,ia)+a1(i,ia)-a2(i,ia))
     +                            /(ebj+e(ia)-e(i))
 20                  continue
 30               continue
c
c     t multiplied by coulomb integrals
c
                  call mxmb(t(1,nocc1),1,norbs,a1(nocc1,1),1,norbs,zlg,
     +                      norbs,1,nocc,nvirt,norbs)
                  call mxmb(a1,1,norbs,t(1,nocc1),1,norbs,zlg(1,nocc1),
     +                      1,norbs,norbs,nocc,nvirt)
c
                  do 50 i = 1 , nocc
                     do 40 ia = nocc1 , norbs
                        a1(i,ia) = 0.5d0*a1(i,ia)/(ebj+e(ia)-e(i))
 40                  continue
 50               continue
c
c     these multiplications give the matrix called
c     v   in the paper
c
                  call mxmb(t(1,nocc1),norbs,1,a1(1,nocc1),1,norbs,
     +                      y(nocc1,nocc1),1,norbs,nvirt,nocc,nvirt)
                  call mxmb(t(1,nocc1),1,norbs,a1(1,nocc1),norbs,1,y,1,
     +                      norbs,nocc,nvirt,nocc)
               end if
            end if
 60      continue
 70   continue
      do 90 ib = nocc1 , norbs
         do 80 ia = nocc1 , norbs
            y(ia,ib) = -y(ia,ib)
 80      continue
 90   continue
c
c.....................integral contribution complete
c.....................to calculate t**2 contributions
c.....................store partial sums j,a,b and i,j,b of t**2
c
      do 110 ib = nocc1 , norbs
         do 100 ia = nocc1 , norbs
            zlg(ia,ib) = zlg(ia,ib) + y(ia,ib)*(e(ia)-e(ib))
 100     continue
 110  continue
      do 130 j = 1 , nocca
         do 120 i = 1 , nocca
            zlg(i,j) = zlg(i,j) + y(i,j)*(e(i)-e(j))
 120     continue
 130  continue
c
c      call rewimp(istrma)
c
c    take terms of form  v * a
c
      call rewedz(istrmj)
      call rewedz(istrmk)
      do 170 ip = 1 , norbs
         do 160 iq = 1 , ip
            call rdedz(a1,norbs*norbs,istrmj)
            call rdedz(a2,norbs*norbs,istrmk)
            if (iq.le.nocca) then
               if (ip.gt.nocca) then
                  do 150 k = 1 , norbs
                     do 140 j = 1 , norbs
                        zlg(ip,iq) = zlg(ip,iq) + y(j,k)
     +                               *(a1(j,k)*4.0d0-a2(j,k)-a2(k,j))
 140                 continue
 150              continue
               end if
            end if
 160     continue
 170  continue
c
c
      do 190 i = nocc1 , norbs
         do 180 j = 1 , nocc
            kt = (i-nocca-1)*nocca + j
            b(kt) = zlg(i,j) - zlg(j,i)
 180     continue
 190  continue
c
c..... b  is  now  calculated
c      b is r.h.s of chf equations - called l in paper
c
      do 210 i = 1 , norbs
         do 200 j = 1 , norbs
            y(i,j) = -y(i,j)
 200     continue
 210  continue
      call wrt3(y,ncoorb*ncoorb,istrmy,ifile1)
      call wrt3(zlg,ncoorb*ncoorb,iblw,ifile1)
      call wrt3(b,mn,iblks,ifils)
      return
      end
      subroutine mpdmdw(dd,dipd)
c
c     wavefunction component to mp2 dipole moment derivatives
c
c     wavefunction derivative contribution to dipole derivative
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/common)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
      dimension dd(*)
c
      dimension dipd(3,3,maxat)
c
      i1 = nx*3 + 1
      i2 = i1 + nx
      i3 = i2 + num*ncoorb
      i4 = i3 + num
      nat3 = nat*3
      call mpd1p3(dd(1),dd(i1),dd(i2),dd(i3),dd(i4),dipd,nat3)
      return
      end
      subroutine mpdpol(fus,h,u,dx,pol,pola,ntri,npert,npdim)
c
c----------------------------------------------------------------
c
c     mp2 polarisabilities.
c     uses the middle two terms of equation (22) in the dipole
c     derivative paper
c
c-------------------------------------------------------------------
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/common)
INCLUDE(common/cndx41)
      dimension dx(ntri,npert)
     & ,fus(ncoorb,ncoorb,npert),h(ncoorb,ncoorb,npert),
     & u(ncoorb,ncoorb,npert),pol(npdim,npdim)
      dimension pola(npdim,npdim)
c
c
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
INCLUDE(common/mapper)
      ind(i,j) = iky(max(i,j)) + min(i,j)
c
      call vclr(pol,1,npdim*npdim)
      m22 = 22
      call secget(isect(22),m22,ibx)
      call rdedx(dx,ntri*npert,ibx,ifild)
c
      call secget(isect(52),52,iblkj)
      call rdchr(pnames,ldsect(isect(52)),iblkj,ifild)
      call reads(freq,lds(isect(52)),ifild)
      iblkj = iblkj + 2 + lensec(npole) + lensec(npole*np)
      call rdedx(pola,npdim*npdim,iblkj,ifild)
      ij = 0
      do 30 i = 1 , np
         do 20 j = 1 , np
            ij = ij + 1
            pol(i,j) = pola(i,j)
 20      continue
 30   continue
c
      do 60 ifield = 1 , 3
         do 50 ia = nocca + 1 , ncoorb
            do 40 i = 1 , nocca
               pol(ifield,1) = pol(ifield,1)
     +                         - (fus(ia,i,ifield)-fus(i,ia,ifield))
     +                         *u(ia,i,1)
               pol(ifield,2) = pol(ifield,2)
     +                         - (fus(ia,i,ifield)-fus(i,ia,ifield))
     +                         *u(ia,i,2)
               pol(ifield,3) = pol(ifield,3)
     +                         - (fus(ia,i,ifield)-fus(i,ia,ifield))
     +                         *u(ia,i,3)
 40         continue
 50      continue
 60   continue
c
c
      do 90 ifield = 1 , 3
         do 80 ip = 1 , ncoorb
            do 70 iq = 1 , ncoorb
               pol(ifield,1) = pol(ifield,1) - h(ip,iq,ifield)
     +                         *dx(ind(ip,iq),1)
               pol(ifield,2) = pol(ifield,2) - h(ip,iq,ifield)
     +                         *dx(ind(ip,iq),2)
               pol(ifield,3) = pol(ifield,3) - h(ip,iq,ifield)
     +                         *dx(ind(ip,iq),3)
 70         continue
 80      continue
 90   continue
c
      call prpol0(pol,npdim)
      return
      end
      subroutine plrmp2(q,iq)
c
c     driving routine from mp2 polarisabilities
c
      implicit REAL  (a-h,o-z)
      logical mpsv
INCLUDE(common/sizes)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
      dimension iq(*),q(*)
      ldiag = .true.
      write (iwr,6010)
      mpsv = mp2
      mp2 = .false.
      call dipmom(q)
c
      call poldrv(q,iq)
      mp2 = mpsv
      ldiag = .false.
      call revise
c
c
      write (iwr,6020)
      call mp2dmd(q,iq)
      return
 6010 format (/
     + 20x,'******************************************************'/
     + 20x,'* calculate the scf dipole moment and polarisability *'/
     + 20x,'******************************************************'/)
 6020 format (/
     + 20x,'******************************************************'/
     + 20x,'* calculate the mp2 dipole moment and polarisability *'/
     + 20x,'******************************************************'/)
      end
      subroutine mpdslv(q)
c
c     calls simultaneous equations routines to give
c     3 sets of field dependent z-matrices
c
      implicit REAL  (a-h,o-z)
      dimension q(*)
      logical lstop,skipp
      dimension skipp(100)
c
INCLUDE(common/common)
INCLUDE(common/cndx41)
c
      mn = nocca*nvirta
      i1 = igmem_alloc(mn)
      i2 = igmem_alloc(ncoorb)
c
      m9 = 9
      call secget(isect(9),m9,isec9)
      call rdedx(q(i2),ncoorb,isec9,ifild)
c
      do 30 ia = nocca + 1 , ncoorb
         do 20 i = 1 , nocca
            iai = (ia-nocca-1)*nocca + i + i1-1
            q(iai) = 1.0d0/(q(i2+ia-1)-q(i2+i-1))
 20      continue
 30   continue
c
      call gmem_free(i2)
c
      np = 3
      skipp(1) = .false.
      skipp(2) = .false.
      skipp(3) = .false.
      lstop = .false.
      npstar = 0
      call chfdrv(q(i1),lstop,skipp)
      call gmem_free(i1)
      return
      end
      subroutine symm1b(ff1,ff,norbs,ntri)
      implicit REAL  (a-h,o-z)
      dimension ff1(*),ff(norbs,norbs)
      ntri = 0
      do 30 i = 1 , norbs
         do 20 j = 1 , i - 1
            ntri = ntri + 1
            ff1(ntri) = 0.5d0*(ff(i,j)+ff(j,i))
 20      continue
         ntri = ntri + 1
         ff1(ntri) = ff(i,i)
 30   continue
      return
      end
      subroutine ver_mp2d(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mp2d.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
