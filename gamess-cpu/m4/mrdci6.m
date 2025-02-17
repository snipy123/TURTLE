c 
c  $Author: mrdj $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mrdci6.m,v $
c  $State: Exp $
c  
c ******************************************************
c ******************************************************
c             =   Table-ci (table-ci module) =
c ******************************************************
c ******************************************************
      subroutine tabci(qq,iqq,lword)
      implicit REAL (a-h,o-z), integer(i-n)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/prints)
      dimension qq(*),iqq(*)
      character*10 charwall
      if(.not.oprint(29)) write(iwr,1)
 1    format( //1x,104('=')//
     *40x,36('*')/
     *40x,'Table-CI  --  CI Hamiltonian Builder'/
     *40x,36('*'))
c
c     use conventional 8-byte packing value as maxorb (256)
c
      maxo = 256
      intmax = maxo*(maxo+1)/2
      intrel = lenint(intmax)
      lwordd = lword - intrel
      intrel = intrel + 1
      call tab0(qq(intrel),iqq(1), intmax, lwordd,iwr)
      i10 = 1
      i20 = i10 + maxig
      i30 = i20 + maxig
      i40 = i30 + lenint(maxig)
      last= i40 + lenint(maxig)
      if (last.gt.lword)call caserr(
     +          'insufficient memory for tab1')
      call tab1(qq(i10),qq(i20),qq(i30),qq(i40),maxig,iwr)
c
      i10 =  1
      i20 =  i10 + intmax
      i30 =  i20 + intmax
      i40 =  3*intmax*lenwrd() + 1
      i413 = i40 + 12
c               acoul   bkay    aexc
      call tab2(qq(i10),qq(i20),qq(i30),intmax,
c                 ot     oihog    oiot
     +          iqq(i40),iqq(i413),iqq(i413),iwr)
c
      cpu=cpulft(1)
      if(.not.oprint(29)) write(iwr,3)cpu ,charwall()
 3    format(/
     *' **** end of table-ci at ',f8.2,' seconds',a10,' wall'/)
       return
       end
      subroutine tab1(g,h,lc,ld,mxdim,iwr)
      implicit REAL (a-h,o-z), integer(i-n)
INCLUDE(common/sizes)
INCLUDE(common/prints)
      common/scrtch/ kc(mxcrec),kd(mxcrec),y(2000)
      common/lsort/ iwod,nid,lg,ifrk,nc,lt,lz,nx,nd,
     +              iswh,nr,mm,jblk,jto,igmax,nr1,
     +              ii,jg,ndt,ia,kml,ie,iz,mzer,nps,nms,n3,
     +              np1,np2,nd1,nm1,nm2
      common/ftape/
     + mtype,nf2,nf3,nf4,ntape,ntype,nf10,nf22,nston,nf32,
     + ltape,ideli,nhuk,idum4(7)
      dimension g(mxdim),h(mxdim),lc(mxdim),ld(mxdim)
      if (jto.gt.0) jblk=jblk+1
      lgh=(lg-1)/igmax+1
      ib8=(lg-1)/nid+1
      igma=igmax/nid
      cpu=cpulft(1)
      if(.not.oprint(29)) write(iwr,10)cpu,jblk,jto
 10   format(
     *' generation of integral label file complete at ',f8.2,
     *' secs.'//
     *' no. of records on integral label file = ',i8/
     *' no. of elements in last record        = ',i8/
     *1x,104('-')//
     *' now convert integral labels into ordered file'/
     *' of repulsion integrals (ft01)')
      igy=igmax/iwod
      nres=ib8-(lgh-1)*igma
      lx=lg-(ib8-1)*nid
      iga=(jblk-1)/igy
      jblk=jblk-iga*igy
      iga=iga+1
      igz=igy
      iw=iwod
      if(jto.eq.0) jto=iwod
      do 1 i=1,iga
      if (i.eq.iga) igz=jblk
      ig=0
      do 2 j=1,igz
      read(ntype) kc,kd
      if (i.eq.iga.and.j.eq.igz) iw=jto
      do 2 k=1,iw
      ig=ig+1
      lc(ig)=kc(k)
2     ld(ig)=kd(k)
      call rewftn(nston)
      read(nston)
      read(nston)
      nx=igma
      lz=nid
      do 3 k=1,lgh
      if(k.eq.lgh) nx=nres
      il=0
      do 4 l=1,nx
      read(nston)y
      if (k.eq.lgh.and.l.eq.nres) lz=lx
      do 4 ll=1,lz
      il=il+1
4     g(il)=y(ll)
      do 5 l=1,ig
      if (lc(l).ne.k) go to 5
      kx=ld(l)
      h(l)=g(kx)
5     continue
3     continue
      if (ig.eq.igmax) go to 6
      igy=(ig-1)/iwod+1
6     la=0
      do 7 k=1,igy
      lb=la+1
      la=la+iwod
7     write(mtype)(h(l),l=lb,la)
1     continue
      write(mtype) h
      cpu=cpulft(1)
      if(.not.oprint(29)) write(iwr,11)cpu
 11   format(/
     *' *** conversion complete ***'//
     *' commence final evaluation of hamiltonian matrix elements at ',
     *f8.2,' secs.'//
     *' *** output hamiltonian to ft35'/)
      call rewftn(mtype)
      if (lg-ib8*nid.eq.0) read (nston)
      return
      end
      subroutine tab2(acoul,bkay,aexc,intmax,ot,oihog,oiot,iwr)
      implicit REAL (a-h,o-z), integer(i-n)
      integer ot,oiot,oihog,olab
_IF(cray,ksr,i8)
      integer olab8
_ENDIF
INCLUDE(common/sizes)
INCLUDE(common/prints)
      common/linkmr/ic,i2,i3
      common/ftape/
     + mtype,nf2,nf3,nf4,ntape,ntype,nf10,nf22,nston,nf32,
     + ltape,ideli,nhuk,idum4(7)
      common/bufd/gout(510),nword
      common/blksi3/nsz
      common/lsort/ iwod,nid,lg,ifrk,nc,lt,lz,nx,nd,
     +              iswh,nr,mm,jblk,jto,igmax,nr1,
     +              ii,jg,ndt,ia,kml,ie,iz,mzer,nps,nms,n3,
     +              np1,np2,nd1,nm1,nm2
      common/jany/ jerk(10),jbnk(10),idumy(10)
c
      common/scrtch/ndet(5),nsac(5),iaz(5),iez(5),idra(5),idrc(5),
     + jdrc(5),jan(7),jbn(7),ispa2(7),ae(7829),
     + iy(8),lj(8),jsym(36),isym(8),lsym(2040),nsel,nj(8),ntil(8),
     + nbal(9),ncomp(256),
_IF(cray,ksr,i8)
     + e(7401),nit(667),
_ELSE
     + e(6633),nit(667),ispa4,
_ENDIF
     + vect(mxcsf*mxroot),ew(mxroot),
     + ab(5292),eb(2304),khog(48),kmap(504),b(500),
     + cf(22500),icf(22500),c(400),ibal(8),itil(8),mcomp(256),kj(8),
     + trsum(10,mxroot),istm(10),
     + ideks(maxorb),olab(2000),jkan(mxcrec),
     + ij(8),nytl(5),nplu(5),ndub(5),nod(5),
_IF(cray,ksr,i8)
     + nir(maxorb),loc(maxorb),
     + nconf(5),itest(mxnshl),sac(10),q(mxcrec),mi(mxcrec),mj(mxcrec),
     + bob(3),f(2304),h(mxcrec),isc(5)
_ELSE
     + nir(maxorb),loc(maxorb),ispe,
     + nconf(5),itest(mxnshl),sac(10),q(mxcrec),mi(mxcrec),mj(mxcrec),
     + bob(3),f(2304),h(mxcrec),isc(5),ispb
_ENDIF
c
      dimension res(2304)
      dimension lout(510)
      dimension ot(*),oihog(*),oiot(*)
      dimension bkay(intmax),acoul(intmax),aexc(intmax)
      dimension newya(255)
_IF(cray,ksr,i8)
      dimension a(2322)
      dimension z(45680)
_ELSE
      dimension a(1161)
      dimension z(34290)
_ENDIF
      dimension mconf(5),olab8(250)
c
      equivalence (z(1),cf(1))
      equivalence (a(1),lsym(1)),(lout(1),gout(1))
c
c     now replaced by dynamic memory allocations (tabci)
c
c
      fzero=5.0d0
c     ifr1=1-ifrk
      nad=4000
      nad1=-3999
      read(nston) mfg,(bkay(i),i=1,mfg),
     * mfg1,(acoul(i),i=1,mfg1),
     * mfg1,(aexc(i),i=1,mfg1),core
      read(ltape) jsec,nrootx,nytl,nplu,ndub,vect,ew,mconf
      read (ntape) nconf
      is=nplu(1)
      mult=is+1
      m=is+ndub(1)*2
      nod(1)=is
      do 903 i=2,iswh
903   nod(i)=nod(i-1)+2
_IFN(cray,ksr)
       call setsto(2000,0,olab)
_ENDIF
_IF(parallel)
c **** MPP
      call closbf3
      call setbfc(-1)
c **** MPP
_ELSE
      call setbfc
_ENDIF
      is=jerk(mult)
      il=jbnk(mult)
_IF1()      ix=ifr1
      ill=2
      call stopbk3
      call rdbak3(is)
      call stopbk3
_IF(cray)
      call fmove(lout,ndet,49)
_ELSE
      call icopy(49,lout,1,ndet,1)
_ENDIF
      is=is+nsz
      ik=1
5551  if(il.lt.ill)go to 5550
      call rdbak3(is)
      is=is+nsz
      call stopbk3
       call dcopy(nword,gout,1,ae(ik),1)
      ik=ik+nword
      ill=ill+1
      go to 5551
5550  call rewftn(nston)
      read(nston)n,iwod,nid,ksum,imo,kj,iy,lj,nj,nsel,ntil,nbal,isym,
     +  jsym,iorbs,knu,newya,lsym,ncomp,e,c,vnuc,dzero
      ix=0
      do 230 i=1,n
      kz=lj(i)
      if (kz.eq.0) go to 230
      do 232 j=1,kz
      ix=ix+1
      nir(ix)=i
 232  loc(ix)=j
 230  continue
      read(nston)nit,ij,cf,icf,ibal,itil,mcomp
      write(nhuk)iwod,vnuc,dzero,imo,m,nconf,newya,
     +  nytl,nplu,ndub,iswh,ksum,iorbs,jsec,nrootx,vect,ew,z,lj,n,
     +  ifrk,knu,e,a
      core=core+fzero
      do 2 i=1,iswh
      md=mconf(i)
      if (md.eq.0) go to 2
      nc=nconf(i)
      if (nc.ne.0) go to 836
      read (ltape)
      read (ltape)
      read (ltape)
      go to 2
 836  read (ltape) ndt,kml,ab
      write(nhuk) ndt,kml,ab
      read(ltape) khog,kmap,eb
      write(nhuk)khog,kmap,eb
      nx=nytl(i)*nc
      nx=nx/iwod+1
      do 900 j=1,nx
900   read(ltape)
2     continue
      call rewftn(ltape)
      jsum=0
      do 901 i=1,iswh
      isc(i)=jsum
901   jsum=jsum+nconf(i)*nsac(i)
      jsum=(jsum-1)/ifrk+1
      read(ideli)(b(i),i=1,5),isp
      write(nhuk)(b(i),i=1,5),isp
      do 902 i=1,jsum
      read(ideli) b
902   write(nhuk)b
      read(ideli)nrootx,((trsum(j,i),j=1,10),i=1,nrootx),istm
      write(nhuk)((trsum(j,i),j=1,10),i=1,nrootx),istm
      read(ltape)
      do 3 i=1,iswh
      md=mconf(i)
      if (md.eq.0) go to 3
      read(ltape)
      read(ltape)
      nc=nconf(i)
      if (nc.ne.0) go to 837
      read (ltape)
      go to 3
  837 nx=nytl(i)*nc
      nx=nx/iwod+1
      do 4 j=1,nx
      read(ltape) jkan
4     write(nhuk) jkan
 3    continue
      call rewftn(ltape)
      read(ltape)
      ideks(1)=0
      do 5 i=1,imo
5     ideks(i+1)=ideks(i)+i
      mm=0
      jto=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
      read(mtype) h
      ibl=0
      jg=0
      do 6 i=1,iswh
      nc=nconf(i)
      if (nc.gt.0) go to 7
      md=mconf(i)
      if (i.lt.3) go to 8
      ibl=ibl+2
      if (md.eq.0) go to 6
      read (ltape)
      read (ltape)
      read (ltape)
      go to 6
8     ibl=ibl+i-1
      if (md.eq.0) go to 6
      read (ltape)
      read (ltape)
      read (ltape)
      go to 6
7     ndt=ndet(i)
      ia=iaz(i)
      kml=nsac(i)
      ie=iez(i)
      iz=isc(i)
      mzer=kml*kml
      nd=ndub(i)
      nps=nplu(i)
      nms=i-1
      niw=nps*nms
      nr=nod(i)
      nx=nytl(i)
      n1=nr+1
      n2=nr+2
      n3=nr-1
      np1=nps-1
      np2=np1+np1
      nd1=nd-1
      nm1=i-2
      nm2=nm1+nm1
      ii=kml+kml+1
      nis=1-ii
      if (i.lt.3) go to 9
      ibl=ibl+1
      j8=i-2
      mc=nconf(j8)
      if(mc.eq.0) go to 10
      ndj=ndet(j8)
      kmj=nsac(j8)
      ja=iaz(j8)
      jz=isc(j8)
      nzer=kml*kmj
_IF1()      mr=nod(j8)
      js=jan(ibl)
      ks=jbn(ibl)
      ix=nad1
      kss=0
 11   if(kss.eq.ks)go to 5560
      ix=ix+nad
      call rdbak3(js)
      js=js+nsz
      call stopbk3
      call unpack(lout,8,ot(ix),nad)
      kss=kss+1
      go to 11
 5560 kz=iz
      do 12 k=1,nc
      lz=jz
      do 13 l=1,mc
      mm=mm+1
      ll=olab(mm)
      if(mm.lt.nid) go to 14
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
14    if(ll.eq.0) go to 13
      mm=mm+1
      jj=olab(mm)
      if (mm.lt.nid) go to 15
      mm=0
      read(ntape) olab8
      call unpack(olab8,8,olab,2000)
15    jj=jj*ii+nis
      jto=jto+1
      ip=ot(jj)
      if(ip.eq.255) go to 803
      coul=h(jto)
      if (jto.lt.iwod) go to 16
      jto=0
      read(mtype) h
16    jto=jto+1
      exc=-h(jto)
      if (jto.lt.iwod) go to 805
      jto=0
      read(mtype)h
      go to 805
803   coul=-h(jto)
      if (jto.lt.iwod) go to 904
      jto=0
      read(mtype) h
904   jto=jto+1
      exc=h(jto)
      if(jto.lt.iwod) go to 805
      jto=0
      read(mtype) h
 805  if(ll-2) 800,801,802
 800  bob(1)=-coul-exc
      bob(2)=exc
      bob(3)=coul
      go to 804
 801  bob(1)=-exc
      bob(2)=coul+exc
      bob(3)=-coul
      go to 804
802   bob(1)=exc
      bob(2)=coul
      bob(3)=-coul-exc
804   call vclr(f,1,nzer)
      do 18 m=1,kml
      jj=jj+1
      my=ot(jj)
      jj=jj+1
      if (my.eq.0) go to 18
      mike=ot(jj)
      tim=bob(mike)
_IF1(iv)      kx=ja+my
_IF1(iv)      lx=m-kml
_IF1(iv)      do 22 if=1,kmj
_IF1(iv)      kx=kx+ndj
_IF1(iv)      lx=lx+kml
_IF1(iv)22    f(lx)=f(lx)+tim*ae(kx)
_IFN1(iv)      kx=ja+my+ndj
_IFN1(iv)      call daxpy(kmj,tim,ae(kx),ndj,f(m),kml)
18    continue
_IF(cray)
      call mxma(ae(ie+1),kml,1,f,1,kml,res,1,kml,kml,kml,kmj)
_ELSE
      call mxmaa(ae(ie+1),kml,1,f,1,kml,res,1,kml,kml,kml,kmj)
_ENDIF
      mz=kz
      do 23 m=1,kml
      mz=mz+1
      nz=lz
      ifm=0
      do 231 if=1,kmj
      nz=nz+1
      tim=res(m+ifm)
      if (dabs(tim).lt.1.0d-7) go to 231
      jg=jg+1
      q(jg)=tim
      mi(jg)=mz
      mj(jg)=nz
      if (jg.lt.iwod) go to 231
      jg=0
      write(nhuk) q,mi,mj
231   ifm=ifm+kml
23    continue
13    lz=lz+kmj
12    kz=kz+kml
      go to 10
9     if (i.eq.1) go to 25
10    ibl=ibl+1
      j8=i-1
      mc=nconf(j8)
      if (mc.eq.0) go to 25
      js=jan(ibl)
      ks=jbn(ibl)
      ndj=ndet(j8)
      kmj=nsac(j8)
      ja=iaz(j8)
      jz=isc(j8)
      nzer=kml*kmj
      mr=nod(j8)
      mps=nplu(j8)
      mms=j8-1
      ix=nad1
      kss=0
 27   if(kss.eq.ks)go to 5570
      ix=ix+nad
      call rdbak3(js)
      js=js+nsz
      call stopbk3
      call unpack(lout,8,ot(ix),nad)
      kss=kss+1
      go to 27
5570  call upackx(ot)
      jc=nr+mult
      j3=jc*kml+1
      kz=iz
      do 28 k=1,nc
      lz=jz
      do 29 l=1,mc
      mm=mm+1
      kk=olab(mm)
      if (mm.lt.nid) go to 30
      mm=0
      read(ntape) olab8
      call unpack(olab8,8,olab,2000)
30    go to (29,31,32,33), kk
 31   mm=mm+1
      ll=olab(mm)
      if (ll.gt.128) ll=ll-256
      if (mm.lt.nid) go to 34
      mm=0
      read(ntape) olab8
      call unpack(olab8,8,olab,2000)
34    mm=mm+1
      jj=olab(mm)
      if (mm.lt.nid) go to 35
      mm=0
      read(ntape) olab8
      call unpack(olab8,8,olab,2000)
35    mm=mm+1
      kk=olab(mm)
      if (mm.lt.nid) go to 36
      mm=0
      read(ntape) olab8
      call unpack(olab8,8,olab,2000)
36    jj=(kk-1)*mr +jj
      jj=jj*ii+ic
      ip=ot(jj)
      if(ip.eq.255) ll=-ll
      jto=jto+1
      if (ll.lt.0) go to 820
      coul = h(jto)
      if (jto.lt.iwod) go to 37
      jto=0
      read(mtype) h
37    jto=jto+1
      exc=-h(jto)
      if (jto.lt.iwod) go to 38
      jto=0
      read(mtype) h
      go to 38
820   coul=-h(jto)
      if (jto.lt.iwod) go to 821
      jto=0
      read(mtype) h
821   jto=jto+1
      ll=-ll
      exc=h(jto)
      if (jto.lt.iwod) go to 38
      jto=0
      read(mtype) h
38    if (ll-2)810,811,812
810   bob(1)=-exc
      bob(2)=-coul
      bob(3)=coul+exc
      go to 49
811   bob(1)=exc
      bob(2)=-coul-exc
      bob(3)=coul
      go to 49
812   bob(1)=coul+exc
      bob(2)=-exc
      bob(3)=-coul
49    call vclr(f,1,nzer)
      do 40 m=1,kml
      jj=jj+1
      my=ot(jj)
      jj=jj+1
      if(my.eq.0) go to 40
_IFN1(iv)      kx=ja+my+ndj
_IF1(iv)      kx=ja+my
      mike=ot(jj)
      if(mike.gt.128) go to 42
      tim=bob(mike)
      go to 43
42    tim=-bob(256-mike)
_IFN1(iv)43    call daxpy(kmj,tim,ae(kx),ndj,f(m),kml)
_IF1(iv)43    lx=m-kml
_IF1(iv)      do 44 if=1,kmj
_IF1(iv)      kx=kx+ndj
_IF1(iv)      lx=lx+kml
_IF1(iv)44    f(lx)=f(lx)+tim*ae(kx)
40    continue
47    mz=kz
_IF(cray)
      call mxma(ae(ie+1),kml,1,f,1,kml,res,1,kml,kml,kml,kmj)
_ELSE
      call mxmaa(ae(ie+1),kml,1,f,1,kml,res,1,kml,kml,kml,kmj)
_ENDIF
      do 45 m=1,kml
      mz=mz+1
      nz=lz
      ifm=0
      do 451 if=1,kmj
      nz=nz+1
      tim=res(ifm+m)
      if (dabs(tim).lt.1.0d-7) go to 451
      jg=jg+1
      q(jg)=tim
      mi(jg)=mz
      mj(jg)=nz
      if (jg.lt.iwod) go to 451
      jg=0
      write(nhuk)q,mi,mj
451   ifm=ifm+kml
45    continue
      go to 29
  32  mm=mm+1
      ll=olab(mm)
      if (mm.lt.nid) go to 51
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
51    jto=jto+1
      sm=h(jto)
      if(jto.lt.iwod) go to 52
      jto=0
      read(mtype) h
52    if(ll.lt.128) go to 53
      sm=-sm
      ll=256-ll
53    jj=ll*kml+i2
      call vclr(f,1,nzer)
      do 56 m=1,kml
      jj=jj+1
      my=ot(jj)
      if (my.eq.0) go to 56
      if(my.lt.128) go to 58
_IFN1(iv)      kx=ja-my+256+ndj
_IF1(iv)      kx=ja-my+256
      tim=-sm
      go to 59
58    tim=sm
_IFN1(iv)      kx=my+ja+ndj
_IF1(iv)      kx=my+ja
_IFN1(iv)59    call daxpy(kmj,tim,ae(kx),ndj,f(m),kml)
_IF1(iv)59    lx=m-kml
_IF1(iv)      do 60 if=1,kmj
_IF1(iv)      kx=kx+ndj
_IF1(iv)      lx=lx+kml
_IF1(iv)60    f(lx)=f(lx)+tim*ae(kx)
56    continue
      go to 47
  33  mm=mm+1
      ll=olab(mm)
      if (mm.lt.nid) go to 61
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
61    mm=mm+1
      ntar=olab(mm)
      if (mm.lt.nid) go to 62
      mm=0
      read (ntape) olab8
      call unpack(olab8,8,olab,2000)
62    mm=mm+1
      nb=olab(mm)
      if(mm.lt.nid) go to 63
      mm=0
      read (ntape) olab8
      call unpack(olab8,8,olab,2000)
63    mm=mm+1
      mb=olab(mm)
      if (mm.lt.nid) go to 41
      mm=0
      read (ntape) olab8
      call unpack(olab8,8,olab,2000)
  41  nb=ideks(nb)+mb+ij(ntar)
      sm=bkay(nb)
      jto=jto+1
      sm=sm+h(jto)
      if(jto.lt.iwod) go to 64
      jto=0
      read(mtype) h
64    if (mr.eq.0 ) go to 65
      do 66 m=1,mr
      jto=jto+1
      sm=sm+h(jto)
      if(jto.lt.iwod) go to 68
      jto=0
      read(mtype) h
68    jto=jto+1
      sac(m)=-h(jto)
      if (jto.lt.iwod) go to 66
      jto=0
      read(mtype) h
66    continue
65    if(nd.eq.0) go to 67
      do 69 m=1,nd
      jto=jto+1
      tim=h(jto)
      sm=sm+tim+tim
      if(jto.lt.iwod) go to 70
      jto=0
      read(mtype) h
70    jto=jto+1
      sm=sm-h(jto)
      if(jto.lt.iwod) go to 69
      jto=0
      read(mtype) h
69    continue
67    if(ll.gt.128) go to 86
      jj=ll*j3+i3
      ip=ot(jj)
      if(ip.eq.1) go to 71
      sm=-sm
      if(mr.ne.0) then
_IF(vax)
      do m=1,mr
       sac(m)=-sac(m)
      enddo
_ELSE
      call dscal(mr,-1.0d0,sac,1)
_ENDIF
      endif
71    jj=jj+1
      call vclr(f,1,nzer)
_IF1(iv)      jx=-kml
      do 73 m=1,kml
_IF1(iv)      jx=jx+1
      in=jj
      im=ot(in)
      go to (74,75,76,77),im
 74   in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ja+ndj
_IF1(iv)      kx=kx+ja
      tim=sm
      if(mps.eq.0) go to 78
_IF1(c)      call gather(mps,res,sac,ot(in+1))
_IFN1(civ)      call dgthr(mps,sac,res,ot(in+1))
_IFN1(iv)      tim=tim+dsum(mps,res,1)
_IFN1(iv)78    call daxpy(kmj,tim,ae(kx),ndj,f(m),kml)
_IF1(iv)      do 79 if=1,mps
_IF1(iv)      in=in+1
_IF1(iv)      im=ot(in)
_IF1(iv)79    tim=tim+sac(im)
_IF1(iv)78    lx=jx
_IF1(iv)      do 81 if=1,kmj
_IF1(iv)      kx=kx+ndj
_IF1(iv)      lx=lx+kml
_IF1(iv)81    f(lx)=f(lx)+tim*ae(kx)
      go to 73
 75   in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ja+ndj
_IF1(iv)      kx=kx+ja
      tim=-sm
      if(mms.eq.0) go to 78
_IF1(c)      call gather(mms,res,sac,ot(in+1))
_IFN1(civ)      call dgthr(mms,sac,res,ot(in+1))
_IFN1(iv)      tim=tim-dsum(mms,res,1)
_IF1(iv)      do 83 if=1,mms
_IF1(iv)      in=in+1
_IF1(iv)      im=ot(in)
_IF1(iv)83    tim=tim-sac(im)
      go to 78
76    do 84 if=1,nms
      in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ja+ndj
_IF1(iv)      kx=kx+ja
      in=in+1
      im=ot(in)
      tim=-sac(im)
_IFN1(iv)84    call daxpy(kmj,tim,ae(kx),ndj,f(m),kml)
_IF1(iv)      lx=jx
_IF1(iv)      do 84 ig=1,kmj
_IF1(iv)      kx=kx+ndj
_IF1(iv)      lx=lx+kml
_IF1(iv)84    f(lx)=f(lx)+tim*ae(kx)
      go to 73
77    do 85 if=1,nps
      in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ja+ndj
_IF1(iv)      kx=kx+ja
      in=in+1
      im=ot(in)
      tim=sac(im)
_IFN1(iv)85    call daxpy(kmj,tim,ae(kx),ndj,f(m),kml)
_IF1(iv)      lx=jx
_IF1(iv)      do 85 ig=1,kmj
_IF1(iv)      kx=kx+ndj
_IF1(iv)      lx=lx+kml
_IF1(iv)85    f(lx)=f(lx)+tim*ae(kx)
73    jj=jj+jc
      go to 47
86    jj=(256-ll)*j3+i3
      ip=ot(jj)
      if (ip.eq.1) go to 87
      sm=-sm
      if (mr.ne.0) then
_IFN1(v)      call dscal(mr,-1.0d0,sac,1)
_IF1(v)      do 88 m=1,mr
_IF1(v)88    sac(m)=-sac(m)
      endif
87    jj=jj+1
      call vclr(f,1,nzer)
_IF1(iv)      jx=-kml
      do 90 m=1,kml
_IF1(iv)      jx=jx+1
      in=jj
      im=ot(in)
      go to (91,95,96,97),im
91    in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ja+ndj
_IF1(iv)      kx=kx+ja
      tim=sm
      if(mms.eq.0) go to 92
_IF(cray)
      call gather(mms,res,sac,ot(in+mps+1))
      tim=tim+dsum(mms,res,1)
92    call daxpy(kmj,tim,ae(kx),ndj,f(m),kml)
_ELSEIF(ibm,vax)
      in=in+mps
      do 93 if=1,mms
      in=in+1
      im=ot(in)
93    tim=tim+sac(im)
92    lx=jx
      do 94 if=1,kmj
      kx=kx+ndj
      lx=lx+kml
94    f(lx)=f(lx)+tim*ae(kx)
_ELSE
      call dgthr(mms,sac,res,ot(in+mps+1))
      tim=tim+dsum(mms,res,1)
92    call daxpy(kmj,tim,ae(kx),ndj,f(m),kml)
_ENDIF
      go to 90
95    in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ja+ndj
_IF1(iv)      kx=kx+ja
      tim=-sm
      if(mps.eq.0) go to 92
_IF1(c)      call gather(mps,res,sac,ot(in+mms+1))
_IFN1(civ)      call dgthr(mps,sac,res,ot(in+mms+1))
_IFN1(iv)      tim=tim-dsum(mps,res,1)
_IF1(iv)      in=in+mms
_IF1(iv)      do 99 if=1,mps
_IF1(iv)      in=in+1
_IF1(iv)      im=ot(in)
_IF1(iv)99    tim=tim-sac(im)
      go to 92
96    do 100 if=1,nms
      in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ja+ndj
_IF1(iv)      kx=kx+ja
      in=in+1
      im=ot(in)
      tim=sac(im)
_IFN1(iv)100   call daxpy(kmj,tim,ae(kx),ndj,f(m),kml)
_IF1(iv)      lx=jx
_IF1(iv)      do 100 ig=1,kmj
_IF1(iv)      kx=kx+ndj
_IF1(iv)      lx=lx+kml
_IF1(iv)100   f(lx)=f(lx)+tim*ae(kx)
      go to 90
97    do 101 if=1,nps
      in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ja+ndj
_IF1(iv)      kx=kx+ja
      in=in+1
      im=ot(in)
      tim=-sac(im)
_IFN1(iv)101   call daxpy(kmj,tim,ae(kx),ndj,f(m),kml)
_IF1(iv)      lx=jx
_IF1(iv)      do 101 ig=1,kmj
_IF1(iv)      kx=kx+ndj
_IF1(iv)      lx=lx+kml
_IF1(iv)101   f(lx)=f(lx)+tim*ae(kx)
90    jj=jj+jc
      go to 47
29    lz=lz+kmj
28    kz=kz+kml
25    js=idra(i)
      ks=idrc(i)
      ix=nad1
      kss=0
 102  if(kss.eq.ks)go to 5580
      ix=ix+nad
      call rdbak3(js)
      js=js+nsz
      call stopbk3
      call unpack(lout,8,ot(ix),nad)
      kss=kss+1
      go to 102
 5580 call upackx(ot)
      kz=iz
      read(ltape)
      read(ltape)
      read(ltape) jkan
      ig=0
      do 103 k=1,nc
      do 104 l=1,nx
      ig=ig+1
      itest(l)=jkan(ig)
      if(ig.lt.iwod) go to 104
      ig=0
      read(ltape) jkan
104   continue
      call vclr(f,1,mzer)
      care=core
      if (nr.eq.0) go to 106
      do 107 l=1,nr
      mal=itest(l)
      ntar=nir(mal)
      mal=loc(mal)+1
      mal=ideks(mal)+ij(ntar)
107   care=care+bkay(mal)
      if(nd.eq.0) go to 108
106   do 109 l=n1,nx
      mal=itest(l)
      ntar=nir(mal)
      nal=ideks(mal+1)
      mal=loc(mal)+1
      mal=ideks(mal)+ij(ntar)
      sm=bkay(mal)
109   care=care+sm+sm+acoul(nal)
108   if(nr.lt.2) go to 110
      do 111 l=2,nr
      mal=itest(l)
      mal=ideks(mal)
      it=l-1
      do 111 m=1,it
      nal=mal+itest(m)
111   care=care+acoul(nal)
110   if(nd.lt.2) go to 112
      sm=0.0d0
      do 113 l=n2,nx
      mal=itest(l)
      mal=ideks(mal)
      it=l-1
      do 113 m=n1,it
      nal=mal+itest(m)
      tim=acoul(nal)
113   sm=sm+tim+tim-aexc(nal)
      care=care+sm+sm
112   if(nr.eq.0.or.nd.eq.0) go to 114
      do 115 l=1,nr
      mal=itest(l)
      do 115 m=n1,nx
      nal=itest(m)
      nal=ideks(max(nal,mal))+min(nal,mal)
      sm=acoul(nal)
115   care=care+sm+sm-aexc(nal)
114   kk=ic
      kn=i2
      ml=i3
_IF1(iv)      jx=-kml
      do 118 l=1,kml
_IF1(iv)      jx=jx+1
_IF1(iv)      lx=jx
_IFN1(iv)      kx=oihog(l)+ia+ndt
_IF1(iv)      kx=oihog(l)+ia
      tim=care
      if(nps.lt.2) go to 122
      mx=kn+1
      do 123 if=2,nps
      mx=mx+1
      it=if-1
      mal=oiot(mx)
      mal=itest(mal)
      mal=ideks(mal)
      mz=kn
      do 123 in=1,it
      mz=mz+1
      nal=oiot(mz)
      nal=itest(nal)+mal
123   tim=tim-aexc(nal)
      kn=mx
      if(nms.lt.2) go to 122
      mx=ml+1
      do 124 if=2,nms
      mx=mx+1
      mal=oiot(mx)
      mal=itest(mal)
      mal=ideks(mal)
      mz=ml
      it=if-1
      do 124 in=1,it
      mz=mz+1
      nal=oiot(mz)
      nal=itest(nal)+mal
124   tim=tim-aexc(nal)
      ml=mx
_IFN1(iv)122   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)122   do 121 if=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)121   f(lx)=f(lx)+tim*ae(kx)
      if(niw.eq.0) go to 118
      do 120 m=1,niw
      kk=kk+1
_IFN1(iv)      kx=oiot(kk)+ia+ndt
_IF1(iv)      kx=oiot(kk)+ia
      kk=kk+1
      mal=oiot(kk)
      kk=kk+1
      nal=oiot(kk)
      if (k.eq.0) write (6,241) kx,mal,nal,kk
 241  format(2x,21i6)
      mal=itest(mal)
      nal=ideks(mal)+itest(nal)
      tim=-aexc(nal)
_IFN1(iv)120   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      lx=jx
_IF1(iv)      do 120 if=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)120   f(lx)=f(lx)+tim*ae(kx)
_IF1(iv)      if (k.eq.0) write (6,239) lx,kx,mal,nal,tim,f(lx),ae(kx)
_IF1(iv)239   format(2x,4i6,3f20.8)
118   continue
      mz=kz
      mx=ie
      do 125 l=1,kml
      ly=1
      nz=kz
      mz=mz+1
      do 1251 m=1,l
      nz=nz+1
      tim=ddot(kml,f(ly),1,ae(mx+1),1)
      if(l.gt.m) go to 127
      jg=jg+1
      q(jg)=tim
      mi(jg)=-mz
      mj(jg)=mz
      if(jg.lt.iwod) go to 1251
      jg=0
      write(nhuk)q,mi,mj
      go to 1251
127   if(dabs(tim).lt.1.0d-7) go to 1251
      jg=jg+1
      q(jg)=tim
      mi(jg)=mz
      mj(jg)=nz
      if(jg.lt.iwod) go to 1251
      jg=0
      write(nhuk)q,mi,mj
1251  ly=ly+kml
125   mx=mx+kml
103   kz=mz
      if(nc.eq.1) go to 6
      ks=jdrc(i)
      ix=nad1
      kss=0
 128  if(kss.eq.ks)go to 5590
      ix=ix+nad
      call rdbak3(js)
      js=js+nsz
      call stopbk3
      call unpack(lout,8,ot(ix),nad)
      kss=kss+1
      go to 128
5590  call upackx(ot)
      call tab20(bkay,aexc,intmax,ot,oihog)
6     continue
      jg=jg+1
      call clredx
      mi(jg)=-1
      mj(jg)=0
c     write (6,229) mj
      cpu=cpulft(1)
      if(.not.oprint(29)) write(iwr,8000)cpu
 8000 format(
     *' transformation to matrix elements over safs completed at ',
     *f8.2,' secs.')
      write(nhuk)q,mi,mj
      call rewftn(nston)
      call rewftn(ntape)
      call rewftn(ntype)
      call rewftn(mtype)
      call rewftn(ideli)
      call rewftn(ltape)
      call rewftn(nhuk)
      return
      end
      subroutine tab20(bkay,aexc,intmax,ot,oihog)
      implicit REAL (a-h,o-z), integer(i-n)
      integer ot,oihog,olab
_IF(cray,ksr,i8)
      integer olab8
_ENDIF
INCLUDE(common/sizes)
      common/linkmr/ic,i2,i3
      common/ftape/mtype,nf2,nf3,nf4,ntape,ntype,nf10,nf22,nston,
     +             nf32,ltape,ideli,nhuk,idum4(7)
      common/bufd/gout(510),nword
      common/blksi3/nsz
      common/lsort/ iwod,nid,lg,ifrk,nc,lt,lz,nx,nd,
     +              iswh,nr,mm,jblk,jto,igmax,nr1,
     +              ii,jg,ndt,ia,kml,ie,iz,mzer,nps,nms,n3,
     +              np1,np2,nd1,nm1,nm2
      common/jany/ jerk(10),jbnk(10),idumy(10)
c
      common/scrtch/ndet(5),nsac(5),iaz(5),iez(5),idra(5),idrc(5),
     + jdrc(5),jan(7),jbn(7),ispa2(7),ae(7829),
     + iy(8),lj(8),jsym(36),isym(8),lsym(2040),nsel,nj(8),ntil(8),
     + nbal(9),ncomp(256),
_IF(cray,ksr,i8)
     + e(7401),nit(667),
_ELSE
     + e(6633),nit(667),ispa4,
_ENDIF
     + vect(mxcsf*mxroot),ew(mxroot),
     + ab(5292),eb(2304),khog(48),kmap(504),b(500),
     + cf(22500),icf(22500),c(400),ibal(8),itil(8),mcomp(256),kj(8),
     + trsum(10,mxroot),istm(10),
     + ideks(maxorb),olab(2000),jkan(mxcrec),
     + ij(8),nytl(5),nplu(5),ndub(5),nod(5),
_IF(cray,ksr,i8)
     + nir(maxorb),loc(maxorb),
     + nconf(5),itest(mxnshl),sac(10),q(mxcrec),mi(mxcrec),mj(mxcrec),
     + bob(3),f(2304),h(mxcrec),isc(5)
_ELSE
     + nir(maxorb),loc(maxorb),ispe,
     + nconf(5),itest(mxnshl),sac(10),q(mxcrec),mi(mxcrec),mj(mxcrec),
     + bob(3),f(2304),h(mxcrec),isc(5),ispb
_ENDIF
c
      dimension res(2304)
      dimension j9(56),lout(510)
_IF(cray,ksr,i8)
      dimension af(7885),t(7886)
      dimension z(45680)
      dimension a(2322)
_ELSE
      dimension af(7857),t(7858)
      dimension z(34290)
      dimension a(1161)
_ENDIF
c
c     now replaced by dynamic memory allocation in tabci/tab2
c
      dimension oihog(*),ot(*),bkay(intmax),aexc(intmax)
      dimension olab8(250)
c
      equivalence (j9(1),ndet(1),af(1),t(1))
      equivalence (z(1),cf(1))
      equivalence (a(1),lsym(1)),(lout(1),gout(1))
      ii=ii+kml
      j2=kml+1
      jc=nr+nr
      j3=jc*kml+1
      kz=iz+kml
      j8=0
      do 129 j=2,nc
      lz=iz
      j8=j8+1
      do 130 k=1,j8
      mm=mm+1
      kk=olab(mm)
      if (mm.lt.nid) go to 131
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
 131  go to (130,132,133,134,135),kk
 135  mm=mm+1
      kk=olab(mm)
      if(mm.lt.nid) go to 136
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
136   mm=mm+1
      ll=olab(mm)
      if(mm.lt.nid) go to 137
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
137   kk=ideks(max(kk,ll))+min(kk,ll)
      call vclr(f,1,mzer)
      tim=aexc(kk)
_IF1(iv)      jx=-kml
      do 141 l=1,kml
_IFN1(iv)      kx=oihog(l)+ia+ndt
_IF1(iv)      kx=oihog(l)+ia
_IFN1(iv)141   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      jx=jx+1
_IF1(iv)      lx=jx
_IF1(iv)      do 141 m=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)141   f(lx)=f(lx)+tim*ae(kx)
146   mz=kz
_IF1(c)      call mxma(ae(ie+1),kml,1,f,1,kml,res,1,kml,kml,kml,kml)
_IFN1(c)      call mxmaa(ae(ie+1),kml,1,f,1,kml,res,1,kml,kml,kml,kml)
      do 145 l=1,kml
      mz=mz+1
      nz=lz
      ifm=0
      do 1451 m=1,kml
      nz=nz+1
      tim=res(ifm+l)
      if(dabs(tim).lt.1.0d-7) go to 1451
      jg=jg+1
      q(jg)=tim
      mi(jg)=mz
      mj(jg)=nz
      if(jg.lt.iwod) go to 1451
      jg=0
      write(nhuk)q,mi,mj
1451  ifm=ifm+kml
145   continue
      go to 130
_IF1(c) 144  call mxma(ae(ie+1),kml,1,f,1,kml,res,1,kml,kml,kml,kml)
_IFN1(c) 144  call mxmaa(ae(ie+1),kml,1,f,1,kml,res,1,kml,kml,kml,kml)
      nzz=lz
      do 253 l=1,kml
      nzz=nzz+1
      mzz=kz
      ifm=0
      do 2531 m=1,kml
      mzz=mzz+1
      tim=res(ifm+l)
      if (dabs(tim).lt.1.0d-7) go to 2531
      jg=jg+1
      q(jg)=tim
      mi(jg)=mzz
      mj(jg)=nzz
      if (jg.lt.iwod) go to 2531
      jg=0
      write (nhuk) q,mi,mj
2531  ifm=ifm+kml
253   continue
      go to 130
 132  mm=mm+1
      ll=olab(mm)
      if(mm.lt.nid) go to 147
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
147   mm=mm+1
      jj=olab(mm)
      if(mm.lt.nid) go to 148
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
148   mm=mm+1
      kk=olab(mm)
      if(mm.lt.nid) go to 149
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
149   if(jj.lt.kk) go to 150
      jj=ideks(jj)+kk
      ibob=0
      go to 151
150   jj=ideks(kk)+jj
      ibob=1
151   jj=jj*ii+ic
      jto=jto+1
      ip=ot(jj)
      if(ip.eq.255) go to 830
      coul=h(jto)
      if(jto.lt.iwod) go to 152
      jto=0
      read(mtype) h
152   jto=jto+1
      exc=-h(jto)
      if(jto.lt.iwod) go to 153
      jto=0
      read(mtype) h
      go to 153
830   coul=-h(jto)
      if (jto.lt.iwod) go to 831
      jto=0
      read (mtype) h
831   jto=jto+1
      exc=h(jto)
      if(jto.lt.iwod) go to 153
      jto=0
      read (mtype) h
  153 if (ll-2) 832,833,834
  832 bob(1)=coul+exc
      bob(2)=exc
      bob(3)=coul
      go to 835
  833 bob(1)=exc
      bob(2)=-coul
      bob(3)=coul+exc
      go to 835
 834  bob(1)=-exc
      bob(2)=-coul-exc
      bob(3)=coul
835   call vclr(f,1,mzer)
_IF1(iv)      mx=-kml
      do 155 l=1,kml
      jj=jj+1
_IF1(iv)      mx=mx+1
      ip=ot(jj)
      if(ip.eq.2)  go to 159
      jj=jj+1
      kx=ot(jj)
_IFN1(iv)      kx=kx+ia+ndt
_IF1(iv)      kx=kx+ia
      jj=jj+1
      tim=bob(1)
_IFN1(iv)      call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      lx=mx
_IF1(iv)      do 161 m=1,kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)      lx=lx+kml
_IF1(iv)161   f(lx)=f(lx)+tim*ae(kx)
      go to 155
159   jj=jj+1
      kx=ot(jj)
_IFN1(iv)      kx=kx+ia+ndt
_IF1(iv)      kx=kx+ia
      tim=bob(2)
_IFN1(iv)      call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      lx=mx
_IF1(iv)      do 160 m=1,kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)      lx=lx+kml
_IF1(iv)160   f(lx)=f(lx)+tim*ae(kx)
      jj=jj+1
      kx=ot(jj)
_IFN1(iv)      kx=kx+ia+ndt
_IF1(iv)      kx=kx+ia
      tim=bob(3)
_IFN1(iv)      call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      lx=mx
_IF1(iv)      do 167 m=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)167   f(lx)=f(lx)+tim*ae(kx)
155   continue
      if (ibob.eq.1) go to 144
      go to 146
 133  mm=mm+1
      ll=olab(mm)
      if (mm.lt.nid) go to 168
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
168   mm=mm+1
      jj=olab(mm)
      if(mm.lt.nid) go to 169
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
169   if(jj.gt.ll) go to 170
      jj=ideks(ll)+jj
      ibob=0
      go to 171
170   jj=ideks(jj)+ll
      ibob=1
171   jto=jto+1
      tim=h(jto)
      if(jto.lt.iwod) go to 172
      jto=0
      read(mtype)h
172   jj=jj*j2+i2
      call vclr(f,1,mzer)
_IF1(iv)      jx=-kml
      ip=ot(jj)
      if(ip.eq.255) tim=-tim
      do 173 l=1,kml
      jj=jj+1
      kx=ot(jj)
_IFN1(iv)      kx=kx+ia+ndt
_IF1(iv)      kx=kx+ia
_IF1(iv)      jx=jx+1
_IFN1(iv)173   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      lx=jx
_IF1(iv)      do 173 m=1,kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)      lx=lx+kml
_IF1(iv)173   f(lx)=f(lx)+tim*ae(kx)
      if (ibob.eq.1) go to 144
      go to 146
 134  mm=mm+1
      ll=olab(mm)
      if(mm.lt.nid) go to 179
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
179   mm=mm+1
      jj=olab(mm)
      if(mm.lt.nid) go to 180
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
180   mm=mm+1
      ntar=olab(mm)
      if(mm.lt.nid) go to 183
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
183   mm=mm+1
      nb=olab(mm)
      if(mm.lt.nid) go to 184
      mm=0
      read(ntape)olab8
      call unpack(olab8,8,olab,2000)
184   mm=mm+1
      mb=olab(mm)
      if (mm.lt.nid) go to 48
      mm=0
      read (ntape) olab8
      call unpack(olab8,8,olab,2000)
  48  nb=ideks(nb)+mb+ij(ntar)
      sm=bkay(nb)
      if(ll.gt.128) go to 181
      if(ll.lt.jj) go to 182
      ibob=0
      jj=ideks(ll)+jj
      go to 205
182   jj=ideks(jj)+ll
      ibob=1
205   jj=jj*j3+i3
      if(nr.eq.1) go to 185
      do 186 l=1,n3
      jto=jto+1
      sm=sm+h(jto)
      if(jto.lt.iwod) go to 187
      jto=0
      read(mtype) h
187   jto=jto+1
      sac(l)=-h(jto)
      if(jto.lt.iwod) go to 186
      jto=0
      read(mtype) h
186   continue
185   if(nd.eq.0) go to 188
      do 189 l=1,nd
      jto=jto+1
      tim=h(jto)
      sm=sm+tim+tim
      if(jto.lt.iwod) go to 190
      jto=0
      read(mtype) h
190   jto=jto+1
      sm=sm-h(jto)
      if(jto.lt.iwod) go to 189
      jto=0
      read(mtype) h
189   continue
188   ip=ot(jj)
      if(ip.eq.1) go to 191
      sm=-sm
      if (nr.ne.1) then
_IFN1(v)       call dscal(n3,-1.0d0,sac,1)
_IF1(v)      do 192 l=1,n3
_IF1(v)192   sac(l)=-sac(l)
      endif
191   jj=jj+1
      call vclr(f,1,mzer)
_IF1(iv)      jx=-kml
      do 194 l=1,kml
      in=jj
      im=ot(in)
      in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ia+ndt
_IF1(iv)      kx=kx+ia
_IF1(iv)      jx=jx+1
_IF1(iv)      lx=jx
      tim=sm
      if(im.eq.2) go to 195
      if(nps.eq.1) go to 196
      do 197 m=1,np1
      in=in+2
      nn=ot(in)
197   tim=tim+sac(nn)
_IFN1(iv)196   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)196   do 198 m=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)198   f(lx)=f(lx)+tim*ae(kx)
      if(nms.eq.0) go to 194
      do 199 m=1,nms
      in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ia+ndt
_IF1(iv)      kx=kx+ia
_IF1(iv)      lx=jx
      in=in+1
      mx=ot(in)
      tim=sac(mx)
_IFN1(iv)199   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      do 199 if=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)199   f(lx)=f(lx)+tim*ae(kx)
      go to 194
195   if(nms.eq.1) go to 200
      do 201 m=1,nm1
      in=in+2
      nn=ot(in)
201   tim=tim+sac(nn)
_IFN1(iv)200   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)200   do 202 m=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)202   f(lx)=f(lx)+tim*ae(kx)
      do 203 m=1,nps
      in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ia+ndt
_IF1(iv)      kx=kx+ia
_IF1(iv)      lx=jx
      in=in+1
      mx=ot(in)
      tim=sac(mx)
_IFN1(iv)203   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      do 203 if=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)203   f(lx)=f(lx)+tim*ae(kx)
194   jj=jj+jc
      if (ibob.eq.1) go to 144
      go to 146
181   ll=256-ll
      if(ll.lt.jj) go to 204
      ibob=0
      jj=ideks(ll)+jj
      go to 206
204   jj=ideks(jj)+ll
      ibob=1
206   jj=jj*j3+i3
      jto=jto+1
      sm=sm+h(jto)
      if(jto.lt.iwod) go to 207
      jto=0
      read(mtype) h
207   jto=jto+1
      sm=sm+h(jto)
      if(jto.lt.iwod) go to 208
      jto=0
      read(mtype) h
208   if(nr.eq.1) go to 209
      do 211 l=1,n3
      jto=jto+1
      sm=sm+h(jto)
      if(jto.lt.iwod) go to 210
      jto=0
      read(mtype) h
210   jto=jto+1
      sac(l)=-h(jto)
      if(jto.lt.iwod) go to 211
      jto=0
      read(mtype) h
211   continue
209   if(nd.eq.1) go to 212
      do 213 l=1,nd1
      jto=jto+1
      tim=h(jto)
      sm=sm+tim+tim
      if(jto.lt.iwod) go to 214
      jto=0
      read(mtype) h
214   jto=jto+1
      sm=sm-h(jto)
      if (jto.lt.iwod) go to 213
      jto=0
      read(mtype) h
213   continue
212   ip=ot(jj)
      if(ip.eq.1) go to 215
      sm=-sm
      if(nr.ne.1) then
_IFN1(v)       call dscal(n3,-1.0d0,sac,1)
_IF1(v)      do 216 l=1,n3
_IF1(v)216   sac(l)=-sac(l)
      endif
215   jj=jj+1
      call vclr(f,1,mzer)
_IF1(iv)      jx=-kml
      do 218 l=1,kml
      in=jj
      im=ot(in)
_IF1(iv)      jx=jx+1
      in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ia+ndt
_IF1(iv)      kx=kx+ia
_IF1(iv)      lx=jx
      tim=-sm
      if (im.eq.2) go to 219
      if(nms.eq.0) go to 220
      in=in+np2
      jn=in
      do 221 m=1,nms
      jn=jn+2
      nn=ot(jn)
221   tim=tim-sac(nn)
_IFN1(iv)220   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)220   do 222 m=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)222   f(lx)=f(lx)+tim*ae(kx)
      if(nms.eq.0) go to 218
      do 223 m=1,nms
      in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ia+ndt
_IF1(iv)      kx=kx+ia
_IF1(iv)      lx=jx
      in=in+1
      mx=ot(in)
      tim=sac(mx)
_IFN1(iv)223   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      do 223 if =1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)223   f(lx)=f(lx)+tim*ae(kx)
      go to 218
219   in=in+nm2
      jn=in
      do 224 m=1,nps
      jn=jn+2
      nn=ot(jn)
224   tim=tim-sac(nn)
_IFN1(iv)      call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      do 225 m=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)225   f(lx)=f(lx)+tim*ae(kx)
      do 226 m=1,nps
      in=in+1
      kx=ot(in)
_IFN1(iv)      kx=kx+ia+ndt
_IF1(iv)      kx=kx+ia
_IF1(iv)      lx=jx
      in=in+1
      mx=ot(in)
      tim=sac(mx)
_IFN1(iv)226   call daxpy(kml,tim,ae(kx),ndt,f(l),kml)
_IF1(iv)      do 226 if=1,kml
_IF1(iv)      lx=lx+kml
_IF1(iv)      kx=kx+ndt
_IF1(iv)226   f(lx)=f(lx)+tim*ae(kx)
218   jj=jj+jc
      if (ibob.eq.1) go to 144
      go to 146
130   lz=lz+kml
129   kz=kz+kml
      return
      end
      subroutine tab0(iot,ideks,intmax,lword,iwr)
      implicit REAL  (a-h,o-z), integer(i-n)
      integer olab
_IF(cray,ksr,i8)
      integer olab8
_ENDIF
INCLUDE(common/sizes)
INCLUDE(common/prints)
      common/lsort/ iwod,nid,lg,ifrk,nc,lt,lz,nx,nd,
     1iswh,nr,mm,jblk,jto,igmax,nr1,nr2
     2,i,ia,iab,iz,iq
      common/ftape/mtype,nf2,nf3,nf4,ntape,ntype,nf10,nf22,nston,
     +             nf32,ltape,ideli,nhuk,idum4(7)
c
      common/scrtch/kj(8),mj(8),vect(mxcsf*mxroot),ew(mxroot),
     + jdeks(9),kdeks(8),lj(8),olab(2000),
     + nit(666),ij(8),
     + nytl(5),nplu(5),ndub(5),icon(5),nod(5),
     + jkan(mxcrec),jcon(maxorb),nir(maxorb),loc(maxorb),
     + kc(mxcrec),kd(mxcrec),lab(3),nconf(5)
c
      dimension iot(*),ideks(intmax)
      dimension olab8(250)
      equivalence (kc(mxcrec),j9)
c
c
      call rewftn(nhuk)
      call rewftn(ntape)
      call rewftn(ntype)
      call rewftn(nston)
      call rewftn(ltape)
      call rewftn(ideli)
      call rewftn(mtype)
c
      igmax=maxig
c     nirm=maxorb
      nirm=255
      im3=nirm*(nirm+1)/2
      iswh=5
      ifrk=500
      nopmax=10
      nymax=lword*lenwrd()
      ideks(1)=0
      do 1 i=1,im3
   1  ideks(i+1)=ideks(i)+i
      np=nopmax-2
      jdeks(1)=0
      do 3 i=1,np
   3  jdeks(i+1)=jdeks(i)+ideks(i+1)
      np=np-1
      kdeks(1)=0
      do 4 i=1,np
   4  kdeks(i+1)=kdeks(i)+jdeks(i+1)
      read (nston) n,iwod,nid,ksum,imo,kj,mj,lj
      read (nston) nit,lg,ij
      call rewftn(nston)
      ix=0
      do 5 i=1,n
      kap=lj(i)
      if (kap.eq.0) go to 5
      do 6 j=1,kap
      ix=ix+1
      nir(ix)=i
   6  loc(ix)=j
   5  continue
      i=ksum-imo
      if(.not.oprint(29)) then
       write(iwr,9002)imo,i,n
 9002  format(/
     * ' no. of active orbitals             ',i3/
     * ' no. of frozen orbitals             ',i3/
     * ' no. of irreducible representations ',i3/)
       do 9030 j=1,n
 9030  write(iwr,9031)j,lj(j)
 9031  format(/' * irrep. no. ',i2,'  : no. of active mos ',i3)
      endif
      read (ltape) jsec,nrootx,nytl,nplu,ndub,vect,ew,nconf
      ny=0
      do 7 i=1,iswh
      icon(i)=ny
      nod(i)=nytl(i)-ndub(i)
      if (nconf(i).eq.0) go to 7
      ig=1
      nx=nytl(i)
      jg=0
      read (ltape)
      read (ltape)
      read (ltape) jkan
   8  if (jkan(ig).eq.0) go to 9
      jg=jg+1
      do 10 j=1,nx
      ny=ny+1
      iot(ny)=jkan(ig)
      if (ig.lt.iwod) go to 10
      read (ltape) jkan
      ig=0
   10 ig=ig+1
      go to 8
    9 nconf(i)=jg
    7 continue
      write (ntape) nconf
c
      cpu=cpulft(1)
      if(.not.oprint(29)) then
       write(iwr,901)jsec,nrootx
 901   format(/
     * ' no. of reference configurations                ',i3/
     * ' selection performed with respect to following   '/
     * ' no. of roots of zero order problem              ',i2/)
       do 9000 j=1,iswh
       if(nconf(j).eq.0)go to 9000
       write(iwr,9001)j,nconf(j)
 9001  format(
     * ' no. of configurations in supercategory ',i2,
     * ' = ',i6/)
 9000  continue
      endif
      mm = 1 + lenint(ny)
      if(.not.oprint(29)) write(iwr,9003)cpu,mm
 9003 format(/1x,104('-')//
     *' commence generation of configuration label file (ft38)'/
     *' and integral label file (ft39) at',f8.2, ' secs.'//
     *' core usage in table-ci:',i10,' words'/)
      call rewftn(ltape)
      if (ny.gt.nymax) then
       write(iwr,9009) ny, nymax
 9009  format(/' ****** ny    = ',i7/
     +         ' ****** nymax = ',i7/)
       call caserr
     * ('internal array bounds exceeded - enlarge core')
      endif
      mm=0
      jto=0
      jblk=0
      do 14 j=1,imo
  14  jcon(j)=0
      do 11 i=1,iswh
      nc=nconf(i)
      if (nc.eq.0) go to 11
      lt=icon(i)
      nx=nytl(i)
      nd=ndub(i)
      nr=nod(i)
      iab=ideks(nr)
      nr1=nr-1
      nr2=nr-2
      lz=lt+nr
      if (i.lt.3) go to 12
      j8=i-2
      mc=nconf(j8)
      if (mc.eq.0) go to 100
      mx=nx-2
      md=nd+2
      mr=nr-4
      nt=lt
      jt=icon(j8)
      iz=mr+jt
      do 13 j=1,nc
      it=nt
      mt=jt
      mz=iz
      do 15 k=1,nr
      it=it+1
      ll=iot(it)
   15 jcon(ll)=1
      if (nd.eq.0) go to 16
      do 18 k=1,nd
      it=it+1
      ll=iot(it)
   18 jcon(ll)=2
   16 do 17 k=1,mc
      jz=mz
      do 19 l=1,md
      jz=jz+1
      ll=iot(jz)
      if (jcon(ll)-1) 20,21,19
   21 ia=l+1
      go to 22
   19 continue
   20 mm=mm+1
      olab(mm)=0
      if (mm.lt.nid) go to 61
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
      go to 61
   22 do 23 l=ia,md
      jz=jz+1
      nn=iot(jz)
      if (jcon(nn)-1) 20,24,23
   24 ja=l+1
      go to 25
   23 continue
   25 if (ja.gt.md) go to 26
      do 27 l=ja,md
      jz=jz+1
      ii=iot(jz)
      if (jcon(ii).ne.2) go to 20
   27 continue
   26 if (mr.eq.0) go to 28
      jz=mt
      do 29 l=1,mr
      jz=jz+1
      ii=iot(jz)
      if (jcon(ii).ne.1) go to 20
   29 continue
   28 jz=nt
      kz=mt+1
      jq=0
      if (mr.gt.0) iq=iot(kz)
      do 30 l=1,nr
      jz=jz+1
      ii=iot(jz)
      if (ii.eq.ll) go to 31
      if (jq.eq.mr.or.iq.ne.ii) go to 32
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   30 continue
   31 ip=l
      ia=l+1
      do 33 l=ia,nr
      jz=jz+1
      ii=iot(jz)
      if (ii.eq.nn) go to 34
      if (jq.eq.mr.or.iq.ne.ii) go to 35
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   33 continue
   32 ip=l
      ia=l+1
      do 36 l=ia,nr
      jz=jz+1
      jj=iot(jz)
      if (jj.eq.ll) go to 37
      if (jq.eq.mr.or.iq.ne.jj) go to 38
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   36 continue
   34 jp=ideks(l-1)
      ia=l+1
      do 39 l=ia,nr
      jz=jz+1
      ii=iot(jz)
      if (jq.eq.mr.or.iq.ne.ii) go to 40
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   39 continue
   40 kp=jdeks(l-2)
      ia=l+1
      do 41 l=ia,nr
      jz=jz+1
      jj=iot(jz)
      if (jq.eq.mr.or.iq.ne.jj) go to 42
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   41 continue
   42 mm=mm+1
      olab(mm)=1
      lp=kdeks(l-3)
      if (mm.lt.nid) go to 43
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
      go to 43
   35 jp=ideks(l-1)
      ia=l+1
      do 44l=ia,nr
      jz=jz+1
      jj=iot(jz)
      if (jj.eq.nn) go to 45
      if (jq.eq.mr.or.jj.ne.iq) go to 46
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   44 continue
   37 jp=ideks(l-1)
      ia=l+1
      do 47 l=ia,nr
      jz=jz+1
      jj=iot(jz)
      if (jj.eq.nn) go to 48
      if (jq.eq.mr.or.jj.ne.iq) go to 49
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   47 continue
   38 jp=ideks(l-1)
      ia=l+1
      do 50 l=ia,nr
      jz=jz+1
      kk=iot(jz)
      if (kk.eq.ll) go to 51
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   50 continue
   51 kp=jdeks(l-2)
      ia=l+1
      do 52 l=ia,nr
      jz=jz+1
      kk=iot(jz)
      if (kk.eq.nn) go to 42
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   52 continue
   48 kp=jdeks(l-2)
      ia=l+1
      do 53 l=ia,nr
      jz=jz+1
      jj=iot(jz)
      if (jq.eq.mr.or.jj.ne.iq) go to 54
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   53 continue
   54 lp=kdeks(l-3)
      mm=mm+1
      olab(mm)=3
      if (mm.lt.nid) go to 43
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
      go to 43
   49 kp=jdeks(l-2)
      ia=l+1
      do 55 l=ia,nr
      jz=jz+1
      kk=iot(jz)
      if (kk.eq.nn) go to 56
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   55 continue
   56 lp=kdeks(l-3)
      mm=mm+1
      olab(mm)=2
      if (mm.lt.nid) go to 43
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
      go to 43
   45 kp=jdeks(l-2)
      ia=l+1
      do 57 l=ia,nr
      jz=jz+1
      jj=iot(jz)
      if (jq.eq.mr.or.jj.ne.iq) go to 56
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   57 continue
   46 kp=jdeks(l-2)
      ia=l+1
      do 58 l=ia,nr
      jz=jz+1
      kk=iot(jz)
      if (kk.eq.nn) go to 54
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   58 continue
 43   mm=mm+1
      olab(mm)=ip+jp+kp+lp
      if (mm.lt.nid) go to 170
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
 170  nt1r = nir(ll)
      nl1r = loc (ll)
      nt2r = nir (nn)
      nl2r = loc (nn)
      kix=3
      nb1r = nir(ii)
      nm1r = loc (ii)
      nb2r = nir (jj)
      nm2r = loc (jj)
  120 if (nt1r-nb1r)123,122,199
  199 iax = ideks(nt1r)+nb1r
      if (nt2r.lt.nb2r) go to 124
      ibx = ideks(nt2r)+nb2r
      if (iax-ibx) 125,126,127
  127 icx = ideks(iax) + ibx
      icq = (nl1r-1)*lj(nb1r) + nm1r
  140 ljn = lj(nb2r)
      idq = (nl2r-1)*ljn + nm2r
      icq = (icq-1)*ljn*lj(nt2r)+idq
      go to 129
  126 icx = ideks (iax+1)
      ljn = lj(nb1r)
      icq = (nl1r-1)*ljn+nm1r
  141 idq = (nl2r-1)*ljn+nm2r
      go to 133
  125 icx = ideks(ibx) + iax
      icq = (nl2r-1)*lj(nb2r)+nm2r
  135 ljn = lj(nb1r)
      idq = (nl1r-1)*ljn+nm1r
      icq =(icq-1)*ljn*lj(nt1r) +idq
      go to 129
  124 ibx = ideks(nb2r) + nt2r
      if (iax-ibx) 130,131,132
  132 icx = ideks(iax)+ibx
      icq = (nl1r-1)*lj(nb1r)+nm1r
      ljn = lj(nt2r)
      idq = (nm2r-1)*ljn+nl2r
      icq = (icq-1)*ljn*lj(nb2r) + idq
      go to 129
  131 icx = ideks(iax+1)
      ljn = lj(nb1r)
      icq = (nl1r-1)*ljn+nm1r
      idq = (nm2r-1)*ljn+nl2r
133   icq  = min(icq,idq) + ideks( max(icq,idq))
      go to 129
  130 icx=ideks(ibx)+iax
      icq = (nm2r-1)*lj(nt2r)+nl2r
      go to 135
  123 iax = ideks(nb1r)+nt1r
      if (nt2r.lt.nb2r) go to 136
      ibx = ideks(nt2r)+nb2r
      if (iax-ibx) 137,138,139
  139 icx = ideks(iax)+ibx
      icq = (nm1r-1)*lj(nt1r)+nl1r
      go to 140
  138 icx = ideks(iax+1)
      ljn = lj(nt1r)
      icq = (nm1r-1)*ljn+nl1r
      go to 141
  137 icx = ideks(ibx) + iax
      icq = (nl2r-1)*lj(nb2r) +nm2r
  145 ljn = lj(nt1r)
      idq = (nm1r-1)*ljn         +nl1r
      icq = (icq-1)*ljn*lj(nb1r) +idq
      go to 129
  136 ibx = ideks(nb2r)+nt2r
      if (iax-ibx) 142,143,144
  144 icx = ideks(iax)+ibx
      icq =(nm1r-1) *lj(nt1r)+nl1r
      ljn = lj(nt2r)
      idq = (nm2r-1)*ljn+nl2r
      icq = (icq-1)*ljn*lj(nb2r)+idq
      go to 129
  143 icx=ideks(iax+1)
      ljn = lj(nt1r)
      icq = (nm1r-1)*ljn+nl1r
      idq = (nm2r-1)*ljn+nl2r
      go to 133
  142 icx = ideks(ibx)+iax
      icq =(nm2r-1)*lj(nt2r)+nl2r
      go to 145
  122 iax=ideks(nt1r+1)
      iay = min(nl1r,nm1r) + ideks( max(nl1r,nm1r))
      iby = min(nl2r,nm2r) + ideks( max(nl2r,nm2r))
      if (nt1r.eq.nt2r) go to 150
      ibx=ideks(nt2r+1)
      if (iax.lt.ibx) go to 151
      icx=ideks(iax)+ibx
      ljn =lj(nt2r)
      icq = (iay-1)*ideks(ljn+1)+iby
      go to 129
  151 icx=ideks(ibx)+iax
      ljn=lj(nt1r)
      icq =(iby-1)*ideks(ljn+1)+iay
      go to 129
  150 icx=ideks(iax+1)
      icq = min(iay,iby) + ideks( max(iay,iby))
 129  icq=nit(icx)  +  icq
      idud=(icq -1)/igmax
      jto=jto + 1
      kc(jto) = idud  + 1
      icq=icq  -  idud*igmax
      kd(jto)  = icq
      if(jto.lt.iwod)  go to 160
      write(ntype)  kc,kd
      jto=0
      jblk=jblk  + 1
  160 if (kix.lt.0) go to 61
      kix=-3
      itr=nb1r
      nb1r=nb2r
      nb2r=itr
      itr=nm1r
      nm1r=nm2r
      nm2r=itr
      go to 120
   61 mz=mz+mx
   17 mt=mt+mx
      do 62 k=1,nx
      nt=nt+1
      ll=iot(nt)
   62 jcon(ll)=0
   13 continue
      go to 100
   12 if (i.eq.1) go to 64
  100 call tab01(iot,ideks,nymax)
   64 call tab02(iot,ideks,nymax)
   11 continue
      kc(jto+1)=0
      kc(iwod)=0
      write (ntype) kc,kd
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      call rewftn(ntype)
      call rewftn(ntape)
       return
       end
      subroutine tab01(iot,ideks,nymax)
      implicit REAL  (a-h,o-z), integer(i-n)
      integer olab
_IF(cray,ksr,i8)
      integer olab8
_ENDIF
INCLUDE(common/sizes)
      common/lsort/ iwod,nid,lg,ifrk,nc,lt,lz,nx,nd,
     1iswh,nr,mm,jblk,jto,igmax,nr1,nr2
     2,i,ia,iab,iz,iq
      common/ftape/mtype,nf2,nf3,nf4,ntape,ntype,nf10,nf22,nston,
     +             nf32,ltape,ideli,nhuk,idum4(7)
c
      common/scrtch/kj(8),mj(8),vect(mxcsf*mxroot),ew(mxroot),
     + jdeks(9),kdeks(8),lj(8),olab(2000),
     + nit(666),ij(8),
     + nytl(5),nplu(5),ndub(5),icon(5),nod(5),
     + jkan(mxcrec),jcon(maxorb),nir(maxorb),loc(maxorb),
     + kc(mxcrec),kd(mxcrec),lab(3),nconf(5)
c
      dimension iot(nymax),olab8(250),ideks(*)
      equivalence (kc(mxcrec),j9)
c
      j8=i-1
      mc=nconf(j8)
      if (mc.eq.0) return
      mx=nx-1
      md=nd+1
      mr=nr-2
      jt=icon(j8)
      iz=mr+jt
      nt=lt
      do 65 j=1,nc
      it=nt
      nt1=nt+1
      nz=nt+nr
      mt=jt
      mz=iz
      do 66 k=1,nr
      it=it+1
      ll=iot(it)
   66 jcon(ll)=1
      if (nd.eq.0) go to 67
      do 68 k=1,nd
      it=it+1
      ll=iot(it)
   68 jcon(ll)=2
   67 do 69 k=1,mc
      jz=mz
      do 70 l=1,md
      jz=jz+1
      jj=iot(jz)
      if (jcon(jj)-1) 71,72,70
   70 continue
   71 if (l.eq.md) go to 73
      ia=l+1
      do 74 l=ia,md
      jz=jz+1
      ll=iot(jz)
      if (jcon(ll).ne.2) go to 75
   74 continue
      go to 73
  75  mm=mm+1
      olab(mm)=1
      if (mm.lt.nid) go to 260
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
      go to 260
   72 l1=l
      if (l.eq.md) go to 76
      ia=l+1
      do 78 l=ia,md
      jz=jz+1
      ll=iot(jz)
      if (jcon(ll)-1) 75,77,78
  78  continue
      go to 76
  77  l2=l
      if (l.eq.md) go to 79
      ia=l+1
      do 80 l=ia,md
      jz=jz+1
      kk=iot(jz)
      if (jcon(kk).ne.2) go to 75
   80 continue
      go to 79
   73 if (mr.eq.0) go to 81
      jz=mt
      do 82 l=1,mr
      jz=jz+1
      ll=iot(jz)
      if (jcon(ll).ne.1) go to 75
   82 continue
  81  mm=mm+1
      olab(mm)=3
      if (mm.lt.nid) go to 83
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
  83  jz=nt
      kz=mt+1
      jq=0
      if (mr.gt.0) iq=iot(kz)
      do 84 l=1,nr
      jz=jz+1
      ll=iot(jz)
      if (jq.eq.mr.or.iq.ne.ll) go to 85
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   84 continue
   85 ia=l+1
      ip=l
      do 86 l=ia,nr
      jz=jz+1
      nn=iot(jz)
      if (jq.eq.mr.or.iq.ne.nn) go to 87
      jq=jq+1
      kz=kz+1
      if (jq.lt.mr) iq=iot(kz)
   86 continue
  87  mm=mm+1
      olab(mm)=ideks(l-1)+ip
      if (mm.lt.nid) go to 88
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
  88  nt1r=nir(jj)
      nl1r=loc(jj)
      nb1r=nir(ll)
      nm1r=loc(ll)
      nm2r=loc(nn)
  220 if (nt1r-nb1r) 223,222,299
  299 iax = ideks(nt1r)+nb1r
      icx = ideks (iax+1)
      ljn = lj(nb1r)
      icq = (nl1r-1)*ljn
      idq = icq+nm2r
      icq=ideks(idq)+icq+nm1r
      go to 229
  223 iax = ideks(nb1r)+nt1r
      icx=ideks(iax+1)
      ljn = lj(nt1r)
      icq = (nm1r-1)*ljn+nl1r
      idq = (nm2r-1)*ljn+nl1r
      icq=ideks(idq)+icq
      go to 229
  222 iax=ideks(nt1r+1)
      icx=ideks(iax+1)
      if (nl1r.lt.nm1r) go to 246
      iay=ideks(nl1r)+nm1r
      go to 247
  246 iay= ideks(nm1r)+nl1r
      iby=ideks(nm2r)+nl1r
      go to 253
  247 if (nl1r.lt.nm2r) go to 248
      iby=ideks(nl1r)+nm2r
      go to 253
  248 iby=ideks(nm2r)+nl1r
  253 icq=ideks(iby)+iay
  229 icq=nit(icx)  +  icq
      idud=(icq -1)/igmax
      jto=jto + 1
      kc(jto) = idud  + 1
      icq=icq  -  idud*igmax
      kd(jto)  = icq
      if(jto.lt.iwod)  go to 260
      write(ntype) kc,kd
      jto=0
      jblk=jblk  + 1
      go to 260
   79 if (mr.eq.0) go to 89
      jz=mt
      do 90 l=1,mr
      jz=jz+1
      ii=iot(jz)
      if (jcon(ii)-1) 75,90,91
  90  continue
      go to 89
  91  l1=l
      if (l.eq.mr) go to 93
      ia=l+1
      do 92 l=ia,mr
      jz=jz+1
      jc=iot(jz)
      if (jcon(jc).ne.1) go to 75
  92  continue
      go to 93
  89  mm=mm+1
      olab(mm)=3
      if (mm.lt.nid) go to 94
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
   94 jz=nt
      do 95 l=1,nr
      jz=jz+1
      if (iot(jz).eq.jj) go to 96
   95 continue
   96 ia=l+1
      ip=l
      do 97 l=ia,nr
      jz=jz+1
      if (iot(jz).eq.ll) go to 98
   97 continue
  98  mm=mm+1
      olab(mm)=-ip-ideks(l-1)
      if (mm.lt.nid) go to 99
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
   99 jz=nz
      if (l1.eq.1) go to 180
      kz=mz
      ja=l1-1
      do 181 l=1,ja
      kz=kz+1
      jz=jz+1
      kk=iot(jz)
      if (kk.ne.iot(kz)) go to 182
  181 continue
  180 if (l2.eq.l1+1) go to 183
      kz=mz+l1
      ia=l1+1
      ja=l2-1
      do 184 l=ia,ja
      kz=kz+1
      jz=jz+1
      kk=iot(jz)
      if (kk.ne.iot(kz)) go to 182
  184 continue
  183 if (l2.lt.md) go to 185
      kk=iot(jz+1)
      go to 182
  185 kz=mz+l2
      ia=l2+1
      do 186 l=ia,md
      kz=kz+1
      jz=jz+1
      kk=iot(jz)
      if (kk.ne.iot(kz)) go to 182
  186 continue
      kk=iot(jz+1)
  182 nt1r=nir(kk)
      nl1r=loc(kk)
      nb1r=nir(jj)
      nm1r=loc(jj)
      nm2r=loc(ll)
      go to 220
  93  mm=mm+1
      olab(mm)=2
      if (mm.lt.nid) go to 187
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
 187  jz=nt
      kz=mt
      ig=0
      if (l1.eq.1) go to 188
      ja=l1-1
      ka=1
      do 189 l=ka,ja
      kz=kz+1
      jp=iot(kz)
 802  jz=jz+1
      if (jp.eq.iot(jz)) go to 189
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.3) go to 190
      go to 802
  189 continue
  188 if (l1.eq.mr) go to 191
      ia=l1+1
      kz=kz+1
      do 192 l=ia,mr
      kz=kz+1
      jp=iot(kz)
 803  jz=jz+1
      if (jp.eq.iot(jz)) go to 192
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.3) go to 190
      go to 803
  192 continue
  191 lab(3)=nr
      if (ig-1) 284,285,190
  284 lab(2)=nr1
      lab(1)=nr2
      go to 190
  285 lab(2)=nr1
  190 jz=lab(1)+nt
      nn=iot(jz)
      mm=mm+1
      if (nn.eq.jj) go to 194
      olab(mm)=1
  195 if (mm.lt.nid) go to 196
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  196 mm=mm+1
      olab(mm)=l1
      if (mm.lt.nid) go to 197
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  197 mm=mm+1
      jp=lab(2)-1
      kp=lab(3)-2
      olab(mm)=lab(1)+ideks(jp)+jdeks(kp)
      if (mm.lt.nid) go to 198
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      go to 198
  194 jz=lab(2)+nt
      nn=iot(jz)
      if (nn.eq.ll) go to 271
      olab(mm)=2
      go to 195
  271 jz=lab(3)+nt
      nn=iot(jz)
      olab(mm)=3
      go to 195
  198 nt1r=nir(jj)
      nt2r=nir(ll)
      nl1r=loc(jj)
      nl2r=loc(ll)
      kix=3
      nb1r=nir(nn)
      nb2r=nir(ii)
      nm1r=loc(nn)
      nm2r=loc(ii)
  320 if (nt1r-nb1r) 323,322,399
  399 iax = ideks(nt1r)+nb1r
      if (nt2r.lt.nb2r) go to 324
      ibx = ideks(nt2r)+nb2r
      if (iax-ibx) 325,326,327
  327 icx = ideks(iax) + ibx
      icq = (nl1r-1)*lj(nb1r) + nm1r
  340 ljn = lj(nb2r)
      idq = (nl2r-1)*ljn + nm2r
      icq = (icq-1)*ljn*lj(nt2r)+idq
      go to 329
  326 icx = ideks (iax+1)
      ljn = lj(nb1r)
      icq = (nl1r-1)*ljn+nm1r
  341 idq = (nl2r-1)*ljn+nm2r
      go to 333
  325 icx = ideks(ibx) + iax
      icq = (nl2r-1)*lj(nb2r)+nm2r
  335 ljn = lj(nb1r)
      idq = (nl1r-1)*ljn+nm1r
      icq =(icq-1)*ljn*lj(nt1r) +idq
      go to 329
  324 ibx = ideks(nb2r) + nt2r
      if (iax-ibx) 330,331,332
  332 icx = ideks(iax)+ibx
      icq = (nl1r-1)*lj(nb1r)+nm1r
      ljn = lj(nt2r)
      idq = (nm2r-1)*ljn+nl2r
      icq = (icq-1)*ljn*lj(nb2r) + idq
      go to 329
  331 icx = ideks(iax+1)
      ljn = lj(nb1r)
      icq = (nl1r-1)*ljn+nm1r
      idq = (nm2r-1)*ljn+nl2r
  333 icq = min(icq,idq) + ideks( max(icq,idq))
      go to 329
  330 icx=ideks(ibx)+iax
      icq = (nm2r-1)*lj(nt2r)+nl2r
      go to 335
  323 iax = ideks(nb1r)+nt1r
      if (nt2r.lt.nb2r) go to 336
      ibx = ideks(nt2r)+nb2r
      if (iax-ibx) 337,338,339
  339 icx = ideks(iax)+ibx
      icq = (nm1r-1)*lj(nt1r)+nl1r
      go to 340
  338 icx = ideks(iax+1)
      ljn = lj(nt1r)
      icq = (nm1r-1)*ljn+nl1r
      go to 341
  337 icx = ideks(ibx) + iax
      icq = (nl2r-1)*lj(nb2r) +nm2r
  345 ljn = lj(nt1r)
      idq = (nm1r-1)*ljn         +nl1r
      icq = (icq-1)*ljn*lj(nb1r) +idq
      go to 329
  336 ibx = ideks(nb2r)+nt2r
      if (iax-ibx) 342,343,344
  344 icx = ideks(iax)+ibx
      icq =(nm1r-1) *lj(nt1r)+nl1r
      ljn = lj(nt2r)
      idq = (nm2r-1)*ljn+nl2r
      icq = (icq-1)*ljn*lj(nb2r)+idq
      go to 329
  343 icx=ideks(iax+1)
      ljn = lj(nt1r)
      icq = (nm1r-1)*ljn+nl1r
      idq = (nm2r-1)*ljn+nl2r
      go to 333
  342 icx = ideks(ibx)+iax
      icq =(nm2r-1)*lj(nt2r)+nl2r
      go to 345
  322 iax=ideks(nt1r+1)
      iay = min(nl1r,nm1r) + ideks( max(nl1r,nm1r))
      iby = min(nl2r,nm2r) + ideks( max(nl2r,nm2r))
      if (nt1r.eq.nt2r) go to 350
      ibx=ideks(nt2r+1)
      if (iax.lt.ibx) go to 351
      icx=ideks(iax)+ibx
      ljn =lj(nt2r)
      icq = (iay-1)*ideks(ljn+1)+iby
      go to 329
  351 icx=ideks(ibx)+iax
      ljn=lj(nt1r)
      icq =(iby-1)*ideks(ljn+1)+iay
      go to 329
  350 icx=ideks(iax+1)
      icq = min(iby,iay) + ideks( max(iby,iay))
  329 icq=nit(icx)  +  icq
      idud=(icq -1)/igmax
      jto=jto + 1
      kc(jto) = idud  + 1
      icq=icq  -  idud*igmax
      kd(jto)  = icq
      if(jto.lt.iwod)  go to 360
      write(ntype) kc,kd
      jto=0
      jblk=jblk  + 1
 360  if (kix.lt.0) go to 260
      kix=-3
      itr=nb1r
      nb1r=nb2r
      nb2r=itr
      itr=nm1r
      nm1r=nm2r
      nm2r=itr
      go to 320
  76  if (mr.eq.0) go to 273
      jz=mt
      do 274 l=1,mr
      jz=jz+1
      ll=iot(jz)
      if (jcon(ll)-1) 275,274,75
 274  continue
      go to 273
 275  l1=l
      if (l.eq.mr) go to 277
      ia=l+1
      do 276 l=ia,mr
      jz=jz+1
      nn=iot(jz)
      if (jcon(nn).ne.1) go to 75
  276 continue
 277  mm=mm+1
      olab(mm)=2
      if (mm.lt.nid) go to 278
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      mm=0
 278  jz=nt
      kz=mt
      ig=0
      if (l1.eq.1) go to 279
      ja=l1-1
      do 280 l=1,ja
      kz=kz+1
      jp=iot(kz)
 254  jz=jz+1
      if (jp.eq.iot(jz)) go to 280
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.3) go to 281
      go to 254
 280  continue
 279  if (l1.eq.mr) go to 282
      ia=l1+1
      kz=kz+1
      do 283 l=ia,mr
      kz=kz+1
      jp=iot(kz)
 255  jz=jz+1
      if (jp.eq.iot(jz)) go to 283
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.3) go to 281
      go to 255
  283 continue
  282 lab(3)=nr
      if (ig-1) 286,287,281
  286 lab(2)=nr1
      lab(1)=nr2
      go to 281
  287 lab(2)=nr1
  281 jz=lab(1)+nt
      kk=iot(jz)
      mm=mm+1
      if (kk.ne.jj) go to 288
      olab(mm)=-1
      jz=lab(2)+nt
      kk=iot(jz)
      jz=lab(3)+nt
      nn=iot(jz)
 289  if(mm.lt.nid) go to 290
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
 290  mm=mm+1
      olab(mm)=l1
      if(mm.lt.nid) go to 291
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
 291  mm=mm+1
      jp=lab(2)-1
      kp=lab(3)-2
      olab(mm)=lab(1)+ideks(jp) +jdeks(kp)
      if(mm.lt.nid)go to 292
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
      go to 292
 288  jz=lab(2)+nt
      nn=iot(jz)
      if (nn.ne.jj) go to 293
      olab(mm)=-2
      jz=lab(3)+nt
      nn=iot(jz)
      go to 289
 293  olab(mm)=-3
      go to 289
 292  nt1r=nir(jj)
      nt2r=nir(ll)
      nl1r=loc(jj)
      nl2r=loc(ll)
      kix=3
      nb1r=nir(kk)
      nb2r=nir(nn)
      nm1r=loc(kk)
      nm2r=loc(nn)
      go to 320
 273  mm=mm+1
      olab(mm)=4
      if(mm.lt.nid) go  to 294
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
 294  jz=nt
      mm=mm+1
      if(mr.eq.0) go to 297
      kz=mt
      do 295 l=1,mr
      kz=kz+1
      jz=jz+1
      ll=iot(jz)
      if(ll.ne.iot(kz)) go to 296
 295  continue
 297  ll=iot(jz+1)
      if(ll.eq.jj) go to 298
      olab(mm) =iab
      if(mm.lt.nid) go to 371
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
      go to 371
 298  ll=iot(jz+2)
      olab(mm)=-iab
      if(mm.lt.nid) go to 371
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
      go to 371
 296  l1 =jz-nt
      if(ll.eq.jj) go to 373
      do 374 l=1,nr
      jz=jz+1
      if(iot(jz).eq.jj) go to 375
 374  continue
 375  olab(mm)=l1+ideks(jz-nt1)
      if(mm.lt.nid) go to 371
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
      go to 371
 373  kz=kz-1
      do 376 ia=l,mr
      kz=kz+1
      jz=jz+1
      ll=iot(jz)
      if(ll.ne.iot(kz)) go to 377
 376  continue
      jz=jz+1
      ll=iot(jz)
 377  olab(mm)=-l1-ideks(jz-nt1)
      if(mm.lt.nid) go to 371
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
 371  mm=mm+1
      iax=nir(jj)
      olab(mm)=iax
      if(mm.lt.nid) go to 372
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  372 iay=ideks(iax+1)
      iaz=ideks(iay+1)
      mq=lj(iax)
      mv=ideks(mq+1)
      iaq=iay-iax
      iaw=iaz-iay
      iat=nit(iaz)
      ii=loc(jj)
      kk=loc(ll)
      km=ideks(kk)
      nm=ideks(ii)
      nn=nm+ii
      if(ii.gt.kk) go to 380
      mm=mm+1
      jb=ii+km
      olab(mm)=kk
      if(mm.lt.nid) go to 378
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
 378  mm=mm+1
      olab(mm)=ii
      if(mm.lt.nid) go to 379
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
 379  ib=ideks(jb) +nn+iat
      go to 381
 380  lb=kk-ii
      jb=nn+lb
      ib=ideks(nn+1)+lb+iat
      mm=mm+1
      olab(mm)=ii
      if(mm.lt.nid) go to 900
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
 900  mm=mm+1
      olab(mm)=kk
      if(mm.lt.nid) go to 381
      mm=0
      call pack(olab8,8,olab,2000)
      write(ntape) olab8
 381  idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=ib
      if(jto.lt.iwod) go to 382
      jto=0
      write(ntype) kc,kd
      jblk=jblk+1
 382  if(mr.eq.0) go to 383
      jz=mt
      ir=mr
      kix=1
 472  do 384 l=1,ir
      jz=jz+1
      mi=iot(jz)
      mar=nir(mi)
      mlr=loc(mi)
      mlb=ideks(mlr)
      mla=mlb+mlr
      if (mar-iax) 385,395,396
 395  if(mla.lt.jb) go to 386
      ib=iat+ideks(mla) +jb
 388  idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto = jto+1
      kc(jto)=idud+1
      kd(jto) =ib
      if(jto.lt.iwod) go to 387
      jto =0
      write(ntype) kc,kd
      jblk=jblk+1
      go to 387
 386  ib=iat+ideks(jb) +mla
      go to 388
 387  if(mlr.lt.ii) go to 389
      kb=mlb+ii
      go to 390
 389  kb=nm+mlr
 390  if(mlr.lt.kk) go to 391
      lb=mlb+kk
      go to 392
 391  lb=mlr+km
 392  if(kb.lt.lb) go to 393
      ib=iat+ideks(kb) +lb
      go to 394
 393  ib=iat+ideks(lb) +kb
 394  idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=ib
      if(jto.lt.iwod) go to 384
      jto=0
      jblk=jblk+1
      write(ntype) kc,kd
      go to 384
 385  iby=ideks(mar+1)
      iby=iaw+iby
      ibx=iaq+mar
      ibx=ideks(ibx+1)
      ibx=nit(ibx)
      iby=nit(iby)
      ml=lj(mar)
      ib=ideks(ml+1)*(jb-1) +mla+iby
      idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=ib
      if(jto.lt.iwod) go to 397
      jto=0
      jblk=jblk+1
      write(ntype) kc,kd
 397  kb=(ii-1)*ml +mlr
      lb=(kk-1)*ml +mlr
      ib = min(kb,lb) + ideks( max(kb,lb)) + ibx
      idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto) = ib
      if(jto.lt.iwod) go to 384
      jto=0
      jblk=jblk+1
      write(ntype) kc,kd
      go to 384
396   ibx=ideks(mar+1)
      iby=ideks(ibx) +iay
      iby=nit(iby)
      ibx=ibx-mar+iax
      ibx=ideks(ibx+1)
      ibx=nit(ibx)
      ib=(mla-1)*mv +jb+iby
      idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=ib
      if(jto.lt.iwod) go to 473
      jto=0
      jblk=jblk+1
      write(ntype) kc,kd
 473  kb=(mlr-1)*mq
      lb=kb+ii
      kb=kb+kk
      ib = min(lb,kb) + ideks( max(lb,kb)) + ibx
      idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=ib
      if (jto.lt.iwod) go to 384
      jto=0
      jblk=jblk+1
      write (ntype) kc,kd
 384  continue
      if (kix.lt.0) go to 260
 383  if (nd.eq.0) go to 260
      kix=-1
      jz=nz
      ir=nd
      go to 472
 260  mz=mz+mx
  69  mt=mt+mx
      do 476 k=1,nx
      nt=nt+1
      ll=iot(nt)
  476 jcon(ll)=0
   65 continue
      return
      end
      subroutine tab02(iot,ideks,nymax)
      implicit REAL  (a-h,o-z),integer(i-n)
      integer olab
_IF(cray,ksr,i8)
      integer olab8
_ENDIF
INCLUDE(common/sizes)
      common/lsort/ iwod,nid,lg,ifrk,nc,lt,lz,nx,nd,
     1iswh,nr,mm,jblk,jto,igmax,nr1
      common/ftape/mtype,nf2,nf3,nf4,ntape,ntype,nf10,nf22,nston,
     +             nf32,ltape,ideli,nhuk,idum4(7)
c
      common/scrtch/kj(8),mj(8),vect(mxcsf*mxroot),ew(mxroot),
     + jdeks(9),kdeks(8),lj(8),olab(2000),
     + nit(666),ij(8),
     + nytl(5),nplu(5),ndub(5),icon(5),nod(5),
     + jkan(mxcrec),jcon(maxorb),nir(maxorb),loc(maxorb),
     + kc(mxcrec),kd(mxcrec),lab(3),nconf(5)
c
      dimension iot(nymax),olab8(250),ideks(*)
c
      if (nc.eq.1) return
      nt=lt+nx
      nz=lz+nx
      j1=0
      do 100 j=2,nc
      j1=j1+1
      it=nt
      mt=lt
      mz=lz
      if (nr.eq.0) go to 102
      do 101 k=1,nr
      it=it+1
      ll=iot(it)
 101  jcon(ll)=1
      if (nd.eq.0) go to 103
 102  do 104 k=1,nd
      it=it+1
      ll=iot(it)
 104  jcon(ll)=2
 103  do 105 k=1,j1
      if (nd.eq.0) go to 106
      jz=mz
      do 107 l=1,nd
      jz=jz+1
      ll=iot(jz)
      if (jcon(ll)-1) 108,109,107
 107  continue
      go to 106
 108  ip=l
      if (l.eq.nd) go to 110
      ia=l+1
      do 111 l=ia,nd
      jz=jz+1
      jj=iot(jz)
      if (jcon(jj).ne.2) go to 112
  111 continue
      go to 110
  112 mm=mm+1
      olab(mm)=1
      if (mm.lt.nid) go to 113
      mm=0
      call pack(olab8,8,olab,2000)
      write  (ntape) olab8
      goto 113
 109  ip=l
      if (l.eq.nd) go to 114
      ia=l+1
      do 115 l=ia,nd
      jz=jz+1
      nn=iot(jz)
      if (jcon(nn)-1) 112,116,115
115   continue
      go to 114
116   if (l.eq.nd) go to 117
      ia=l+1
      do 118 l=ia,nd
      jz=jz+1
      kk=iot(jz)
      if (jcon(kk).ne.2)  go to 112
 118  continue
      go to 117
 110  if (nr.eq.0) go to 119
      jz=mt
      do 120 l=1,nr
      jz=jz+1
      jj=iot(jz)
      if (jcon(jj)-1) 112,120,121
 120  continue
      go to 119
 121  ip=l
      if (l.eq.nr) go to 122
      ia=l+1
      do 123 l=ia,nr
      jz=jz+1
      kk=iot(jz)
      if (jcon(kk).ne.1) go to 112
 123  continue
      go to 122
 119  mm=mm+1
      olab(mm)=5
      if (mm.lt.nid) go to 124
      mm=0
      call pack(olab8,8,olab,2000)
      write  (ntape) olab8
 124  jz=nz
      if (ip.eq.1) go to 125
      kz=mz
      ja=ip-1
      do 126 l=1,ja
      kz=kz+1
      jz=jz+1
      kk=iot(jz)
      if (kk.ne.iot(kz)) go to 127
 126  continue
 125  if (ip.eq.nd) go to 128
      ja=ip+1
      kz=mz+ip
      do 129 l=ja,nd
      kz=kz+1
      jz=jz+1
      kk=iot(jz)
      if (kk.ne.iot(kz)) go to 127
 129  continue
 128  kk=iot(jz+1)
  127 mm=mm+1
      olab(mm)=ll
      if (mm.lt.nid) go to 130
      mm=0
      call pack(olab8,8,olab,2000)
      write  (ntape) olab8
  130 mm=mm+1
      olab(mm)=kk
      if (mm.lt.nid) go to 113
      mm=0
       call pack(olab8,8,olab,2000)
      write  (ntape) olab8
      go to 113
  122 mm=mm+1
      olab(mm)=3
      if (mm.lt.nid) go to 131
      mm=0
      call pack(olab8,8,olab,2000)
      write  (ntape) olab8
  131 jz=nt
      if (ip.eq.1) go to 132
      kz=mt
      ja=ip-1
      do 133 l=1,ja
      kz=kz+1
      jz=jz+1
      kk=iot(jz)
      if (kk.ne.iot(kz)) go to 134
 133  continue
 132  if (ip.eq.nr) go to 650
      ja=ip+1
      kz=mt+ip
      do 651 l=ja,nr
      kz=kz+1
      jz=jz+1
      kk=iot(jz)
      if (kk.ne.iot(kz)) go to 134
 651  continue
 650  jz=jz+1
      kk=iot(jz)
  134 mm=mm+1
      olab(mm)=jz-nt
      if (mm.lt.nid) go to 135
      mm=0
      call pack(olab8,8,olab,2000)
      write  (ntape) olab8
  135 mm=mm+1
      olab(mm)=ip
      if (mm.lt.nid) go to 136
      mm=0
      call pack(olab8,8,olab,2000)
      write  (ntape) olab8
  136 nt1r=nir(ll)
      nl1r=loc(ll)
      nb1r=nir(jj)
      nm1r=loc(jj)
      nm2r=loc(kk)
   20 if (nt1r-nb1r) 23,22,99
   99 iax = ideks(nt1r)+nb1r
      icx = ideks (iax+1)
      ljn = lj(nb1r)
      icq = (nl1r-1)*ljn
      idq=icq+nm2r
      icq=icq+nm1r
   33 icq = min(icq,idq) + ideks( max(icq,idq))
      go to 29
   23 iax=ideks(nb1r)+nt1r
      icx=ideks(iax+1)
      ljn = lj(nt1r)
      icq = (nm1r-1)*ljn+nl1r
      idq = (nm2r-1)*ljn+nl1r
      go to 33
   22 iax=ideks(nt1r+1)
      iay = min(nl1r,nm1r) + ideks( max(nl1r,nm1r))
      iby = min(nl1r,nm2r) + ideks( max(nl1r,nm2r))
      icx=ideks(iax+1)
      icq = min(iay,iby) + ideks( max(iay,iby))
 29   icq=nit(icx)  +  icq
      idud=(icq -1)/igmax
      jto=jto + 1
      kc(jto) = idud  + 1
      icq=icq  -  idud*igmax
      kd(jto)  = icq
      if(jto.lt.iwod)  go to 113
      write(ntype) kc,kd
      jto=0
      jblk=jblk  + 1
      go to 113
 117  jz=mt
      do 137 l=1,nr
      jz=jz+1
      kk=iot(jz)
      if (jcon(kk)-1) 112,137,138
  137 continue
  138 l1=l
      ia=l+1
      do 139 l=ia,nr
      jz=jz+1
      jj=iot(jz)
      if (jcon(jj)-1) 112,139,140
  139 continue
  140 l2=l
      if (l.eq.nr) go to 141
      ia=l+1
      do 142 l=ia,nr
      jz=jz+1
      ii=iot(jz)
      if (jcon(ii).ne.1) go to 112
 142  continue
 141  mm=mm+1
      olab(mm)=2
      if (mm.lt.nid) go to 143
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  143 mm=mm+1
      olab(mm)=1
      if (mm.lt.nid) go to 144
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 144  jz=nt
      do 145 l=1,nr
      jz=jz+1
      if (iot(jz).eq.ll) go to 146
 145  continue
 146  ip=l
      ia=l+1
      do 870 l=ia,nr
      jz=jz+1
      if (iot(jz).eq.nn) go to 147
 870  continue
 147  mm=mm+1
      olab(mm)=ip+ideks(l-1)
      if (mm.lt.nid) go to 148
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  148 mm=mm+1
      olab(mm)=ideks(l2-1)+l1
 540  if (mm.lt.nid) go to 149
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 149  nt1r=nir(ll)
      nt2r=nir(nn)
      nl1r=loc(ll)
      nl2r=loc(nn)
 189  nb1r=nir(kk)
      nb2r=nir(jj)
      nm1r=loc(kk)
      nm2r=loc(jj)
      kix=3
  220 if (nt1r-nb1r) 223,222,299
  299 iax = ideks(nt1r)+nb1r
      if (nt2r.lt.nb2r) go to 224
      ibx = ideks(nt2r)+nb2r
      if (iax-ibx) 225,226,227
  227 icx = ideks(iax) + ibx
      icq = (nl1r-1)*lj(nb1r) + nm1r
  240 ljn = lj(nb2r)
      idq = (nl2r-1)*ljn + nm2r
      icq = (icq-1)*ljn*lj(nt2r)+idq
      go to 229
  226 icx = ideks (iax+1)
      ljn = lj(nb1r)
      icq = (nl1r-1)*ljn+nm1r
  241 idq = (nl2r-1)*ljn+nm2r
      go to 233
  225 icx = ideks(ibx) + iax
      icq = (nl2r-1)*lj(nb2r)+nm2r
  235 ljn = lj(nb1r)
      idq = (nl1r-1)*ljn+nm1r
      icq =(icq-1)*ljn*lj(nt1r) +idq
      go to 229
  224 ibx = ideks(nb2r) + nt2r
      if (iax-ibx) 230,231,232
  232 icx = ideks(iax)+ibx
      icq = (nl1r-1)*lj(nb1r)+nm1r
      ljn = lj(nt2r)
      idq = (nm2r-1)*ljn+nl2r
      icq = (icq-1)*ljn*lj(nb2r) + idq
      go to 229
  231 icx = ideks(iax+1)
      ljn = lj(nb1r)
      icq = (nl1r-1)*ljn+nm1r
      idq = (nm2r-1)*ljn+nl2r
  233 icq = min(icq,idq) + ideks( max(icq,idq))
      go to 229
  230 icx=ideks(ibx)+iax
      icq = (nm2r-1)*lj(nt2r)+nl2r
      go to 235
  223 iax = ideks(nb1r)+nt1r
      if (nt2r.lt.nb2r) go to 236
      ibx = ideks(nt2r)+nb2r
      if (iax-ibx) 237,238,239
  239 icx = ideks(iax)+ibx
      icq = (nm1r-1)*lj(nt1r)+nl1r
      go to 240
  238 icx = ideks(iax+1)
      ljn = lj(nt1r)
      icq = (nm1r-1)*ljn+nl1r
      go to 241
  237 icx = ideks(ibx) + iax
      icq = (nl2r-1)*lj(nb2r) +nm2r
  245 ljn = lj(nt1r)
      idq = (nm1r-1)*ljn         +nl1r
      icq = (icq-1)*ljn*lj(nb1r) +idq
      go to 229
  236 ibx = ideks(nb2r)+nt2r
      if (iax-ibx) 242,243,244
  244 icx = ideks(iax)+ibx
      icq =(nm1r-1) *lj(nt1r)+nl1r
      ljn = lj(nt2r)
      idq = (nm2r-1)*ljn+nl2r
      icq = (icq-1)*ljn*lj(nb2r)+idq
      go to 229
  243 icx=ideks(iax+1)
      ljn = lj(nt1r)
      icq = (nm1r-1)*ljn+nl1r
      idq = (nm2r-1)*ljn+nl2r
      go to 233
  242 icx = ideks(ibx)+iax
      icq =(nm2r-1)*lj(nt2r)+nl2r
      go to 245
  222 iax=ideks(nt1r+1)
      iay = min(nl1r,nm1r) + ideks( max(nl1r,nm1r))
      iby = min(nl2r,nm2r) + ideks( max(nl2r,nm2r))
      if (nt1r.eq.nt2r) go to 250
      ibx=ideks(nt2r+1)
      if (iax.lt.ibx) go to 251
      icx=ideks(iax)+ibx
      ljn =lj(nt2r)
      icq = (iay-1)*ideks(ljn+1)+iby
      go to 229
  251 icx=ideks(ibx)+iax
      ljn=lj(nt1r)
      icq =(iby-1)*ideks(ljn+1)+iay
      go to 229
  250 icx=ideks(iax+1)
      icq = min(iay,iby) + ideks( max(iay,iby))
 229  icq=nit(icx)  +  icq
      idud=(icq -1)/igmax
      jto=jto + 1
      kc(jto) = idud  + 1
      icq=icq  -  idud*igmax
      kd(jto)  = icq
      if(jto.lt.iwod)  go to 260
      write(ntype) kc,kd
      jto=0
      jblk=jblk  + 1
260   if(kix.lt.0)  go to 113
      kix=-3
      itr=nb1r
      nb1r=nb2r
      nb2r=itr
      itr=nm1r
      nm1r=nm2r
      nm2r=itr
      go to 220
 114  jz=mt
      do 150 l=1,nr
      jz=jz+1
      nn=iot(jz)
      if (jcon(nn)-1) 151,150,152
  150 continue
  151 jp=l
      if (l.eq.nr) go to 153
      ia=l+1
      do 154 l=ia,nr
      jz=jz+1
      kk=iot(jz)
      if (jcon(kk)-1) 112,154,155
  154 continue
      go to 153
  155 kp=l
      if (l.eq.nr) go to 156
      ia=l+1
      do 157 l=ia,nr
      jz=jz+1
      ii=iot(jz)
      if (jcon(ii).ne.1) go to 112
  157 continue
      go to 156
  152 jp=l
      if (l.eq.nr) go to 158
      ia=l+1
      do 159 l=ia,nr
      jz=jz+1
      kk=iot(jz)
      if (jcon(kk)-1) 160,159,112
  159 continue
      go to 158
  160 kp=l
      if (l.eq.nr) go to 161
      ia=l+1
      do 162 l=ia,nr
      jz=jz+1
      ii=iot(jz)
      if (jcon(ii).ne.1) go to 112
  162 continue
      go to 161
  153 mm=mm+1
      olab(mm)=3
      if (mm.lt.nid) go to 163
      mm=0
      call  pack(olab8,8,olab,2000)
      write (ntape) olab8
 163  jz=nt
      do 164 l=1,nr
      jz=jz+1
      if (iot(jz).eq.ll) go to 165
 164  continue
  165 mm=mm+1
      olab(mm)=l
      if (mm.lt.nid) go to 166
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  166 mm=mm+1
      olab(mm)=jp
      if (mm.lt.nid) go to 167
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  167 jz=nz
      if (ip.eq.1) go to 168
      kz=mz
      ja=ip-1
      do 169 l=1,ja
      jz=jz+1
      kz=kz+1
      kk=iot(jz)
      if (kk.ne.iot(kz)) go to 170
  169 continue
  168 if (ip.eq.nd) go to 171
      ja=ip+1
      kz=mz+ip
      do 172 l=ja,nd
      jz=jz+1
      kz=kz+1
      kk=iot(jz)
      if (kk.ne.iot(kz)) go to 170
  172 continue
  171 kk=iot(jz+1)
  170 nt1r=nir(kk)
      nl1r=loc(kk)
      nb1r=nir(ll)
      nm1r=loc(ll)
      nm2r=loc(nn)
      go to 20
  156 mm=mm+1
      olab(mm)=2
      if (mm.lt.nid) go to 173
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  173 jz=nt
      mm=mm+1
      kz=mt
      ig=0
      if (jp.eq.1) go to 174
      ka=1
      ja=jp-1
  176 do 175 l=ka,ja
      jz=jz+1
      kz=kz+1
      if (iot(jz).eq.iot(kz)) go to 175
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.2) go to 177
      go to 800
 175  continue
      go to 174
 800  ka=l
      kz=kz-1
      go to 176
 174  la=kp-1
      if (jp.eq.la) go to 178
      ja=jp+1
      kz=kz+1
 180  do 179 l=ja,la
      kz=kz+1
      jz=jz+1
      if (iot(kz).eq.iot(jz)) go to 179
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.2) go to 177
      go to 801
 179  continue
      go to 178
 801  ja=l
      kz=kz-1
      go to 180
 178  if (kp.eq.nr) go to 181
      ia=kp+1
      kz=mt+kp
 182  do 183 l=ia,nr
      jz=jz+1
      kz=kz+1
      if (iot(jz).eq.iot(kz)) go to 183
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.2) go to 177
      go to 802
 183  continue
      go to 181
 802  ia=l
      kz=kz-1
      go to 182
 181  lab(2)=nr
      if (ig.eq.1) go to 177
      lab(1)=nr1
 177  ia=lab(1)
      jz=ia+nt
      ja=lab(2)
      jj=iot(jz)
      if (jj.eq.ll) go to 184
      olab(mm)=2
 188  if (mm.lt.nid) go to 185
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  185 mm=mm+1
      olab(mm)=ideks(ja-1)+ia
      if (mm.lt.nid) go to 186
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  186 mm=mm+1
      olab(mm)=ideks(kp-1)+jp
      if (mm.lt.nid) go to 187
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 187  nt1r=nir(nn)
      nt2r=nir(ll)
      nl1r=loc(nn)
      nl2r=loc(ll)
      go to 189
 184  olab(mm)=3
      jz=nt+ja
      jj=iot(jz)
      go to 188
  161 mm=mm+1
      olab(mm)=2
      if (mm.lt.nid) go to 190
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  190 jz=nt
      mm=mm+1
      kz=mt
      ig=0
      if (jp.eq.1) go to 191
      ka=1
      ja=jp-1
 192  do 193 l=ka,ja
      jz=jz+1
      kz=kz+1
      if (iot(jz).eq.iot(kz)) go to 193
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.2) go to 806
      go to 803
 193  continue
      go to 191
 803  ka=l
      kz=kz-1
      go to 192
 191  la=kp-1
      if (jp.eq.la) go to 194
      ja=jp+1
      kz=kz+1
 195  do 196 l=ja,la
      kz=kz+1
      jz=jz+1
      if (iot(kz).eq.iot(jz)) go to 196
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.2) go to 806
      go to 804
196   continue
      go to 194
 804  ja=l
      kz=kz-1
      go to 195
 194  if (kp.eq.nr) go to 197
      ia=kp+1
      kz=mt+kp
 198  do 199 l=ia,nr
      kz=kz+1
      jz=jz+1
      if (iot(jz).eq.iot(kz)) go to 199
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.2) go to 806
      go to 805
  199 continue
      go to 197
  805 ia=l
      kz=kz-1
      go to 198
  197 lab(2)=nr
      if (ig.eq.1) go to 806
      lab(1)=nr-1
  806 ia=lab(1)
      jz=ia+nt
      ja=lab(2)
      jj=iot(jz)
      if (jj.eq.ll) go to 501
      olab(mm)=3
 502  if (mm.lt.nid) go to 503
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  503 mm=mm+1
      olab(mm)=ideks(ja-1)+ia
      if (mm.lt.nid) go to 504
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  504 mm=mm+1
      olab(mm)=ideks(kp-1)+jp
      if (mm.lt.nid) go to 505
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 505  nt1r=nir(nn)
      nt2r=nir(jj)
      nl1r=loc(nn)
      nl2r=loc(jj)
      kix=3
      nb1r=nir(kk)
      nb2r=nir(ll)
      nm1r=loc(kk)
      nm2r=loc(ll)
      go to 220
 501  olab(mm)=2
      jz=nt+ja
      jj=iot(jz)
      go to 502
 158  mm=mm+1
      olab(mm)=4
      if (mm.lt.nid) go to 506
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 506  jz=nt
      do 507 l=1,nr
      jz=jz+1
      if (iot(jz).eq.ll) go to 508
 507  continue
 508  mm=mm+1
      olab(mm)=-l
      if (mm.lt.nid) go to 509
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 509  mm=mm+1
      olab(mm)=jp
      if (mm.lt.nid) go to 510
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 510  mm=mm+1
      iax=nir(ll)
      iay=ideks(iax+1)
      iaz=ideks(iay+1)
      olab(mm)=iax
      if (mm.lt.nid) go to 893
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 893  mm=mm+1
      mq=lj(iax)
      mv=ideks(mq+1)
      iaq=iay-iax
      iaw=iaz-iay
      iat=nit(iaz)
      ii=loc(ll)
      kk=loc(nn)
      km=ideks(kk)
      kl=km+kk
      nm=ideks(ii)
      nn=nm+ii
      if (ii.gt.kk) go to 513
      olab(mm)=kk
      if (mm.lt.nid) go to 511
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 511  mm=mm+1
      olab(mm)=ii
      if (mm.lt.nid) go to 512
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 512  jb=km+ii
      ib=ideks(jb)+nn+iat
      kb=ideks(kl)+jb+iat
      go to 514
 513  jb=nm+kk
      olab(mm)=ii
      if (mm.lt.nid) go to 551
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 551  mm=mm+1
      olab(mm)=kk
      if (mm.lt.nid) go to 552
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 552  ib=ideks(jb)+kl+iat
      kb=ideks(nn)+jb+iat
 514  idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=ib
      if (jto.lt.iwod) go to 515
      jto=0
      write (ntype) kc,kd
      jblk=jblk+1
 515  idud=(kb-1)/igmax
      kb=kb-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=kb
      nix=1
      if (jto.lt.iwod) go to 516
      jto=0
      write (ntype) kc,kd
      jblk=jblk+1
 516  if (nr.eq.1) go to 517
      jz=mt
      kix=1
      lp=jp
      ir=nr
 518  do 384 l=1,ir
      jz=jz+1
      if (l.eq.lp) go to 384
      mi=iot(jz)
      mar=nir(mi)
      mlr=loc(mi)
      mlb=ideks(mlr)
      mla=mlb+mlr
      if (mar-iax) 385,395,396
 395  if(mla.lt.jb) go to 386
      ib=iat+ideks(mla) +jb
 388  idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto = jto+1
      kc(jto)=idud+1
      kd(jto) =ib
      if(jto.lt.iwod) go to 387
      jto =0
      write(ntype) kc,kd
      jblk=jblk+1
      go to 387
 386  ib=iat+ideks(jb) +mla
      go to 388
 387  if(mlr.lt.ii) go to 389
      kb=mlb+ii
      go to 390
 389  kb=nm+mlr
 390  if(mlr.lt.kk) go to 391
      lb=mlb+kk
      go to 392
 391  lb=mlr+km
 392  if(kb.lt.lb) go to 393
      ib=iat+ideks(kb) +lb
      go to 394
 393  ib=iat+ideks(lb) +kb
 394  idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=ib
      if(jto.lt.iwod) go to 384
      jto=0
      jblk=jblk+1
      write(ntype) kc,kd
      go to 384
 385  iby=ideks(mar+1)
      iby=iaw+iby
      ibx=iaq+mar
      ibx=ideks(ibx+1)
      ibx=nit(ibx)
      iby=nit(iby)
      ml=lj(mar)
      ib=ideks(ml+1)*(jb-1) +mla+iby
      idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=ib
      if(jto.lt.iwod) go to 397
      jto=0
      jblk=jblk+1
      write(ntype) kc,kd
 397  kb=(ii-1)*ml +mlr
      lb=(kk-1)*ml +mlr
      if(kb.lt.lb) go to 398
      ib=ideks(kb)+lb+ibx
      go to 471
 398  ib=ideks(lb) +kb+ibx
 471  idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto) = ib
      if(jto.lt.iwod) go to 384
      jto=0
      jblk=jblk+1
      write(ntype) kc,kd
      go to 384
396   ibx=ideks(mar+1)
      iby=ideks(ibx) +iay
      iby=nit(iby)
      ibx=ibx-mar+iax
      ibx=ideks(ibx+1)
      ibx=nit(ibx)
      ib=(mla-1)*mv +jb+iby
      idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=ib
      if(jto.lt.iwod) go to 473
      jto=0
      jblk=jblk+1
      write(ntype) kc,kd
 473  kb=(mlr-1)*mq
      lb=kb+ii
      kb=kb+kk
      if(kb.lt.lb) go to 474
      ib=ideks(kb)+lb+ibx
      go to 475
 474  ib=ideks(lb)+kb+ibx
 475  idud=(ib-1)/igmax
      ib=ib-idud*igmax
      jto=jto+1
      kc(jto)=idud+1
      kd(jto)=ib
      if (jto.lt.iwod) go to 384
      jto=0
      jblk=jblk+1
      write (ntype) kc,kd
 384  continue
      if (kix.lt.0) go to 113
      if (nix.lt.0) go to 519
 517  if (nd.eq.1) go to 113
      kix=-1
      jz=mz
      lp=ip
      ir=nd
      go to 518
  519 if (nd.eq.0) go to 113
      kix=-1
      jz=mz
      lp=0
      ir=nd
      go to 518
  106 jz=mt
      do 520 l=1,nr
      jz=jz+1
      ll=iot(jz)
      if (jcon(ll)-1) 521,520,112
  520 continue
  521 ip=l
      if (l.eq.nr) go to 522
      ia=l+1
      do 523 l=ia,nr
      jz=jz+1
      nn=iot(jz)
      if (jcon(nn)-1) 524,523,112
  523 continue
      go to 522
  524 jp=l
      if (l.eq.nr) go to 525
      ia=l+1
      do 526 l=ia,nr
      jz=jz+1
      ii=iot(jz)
      if (jcon(ii).ne.1) go to 112
  526 continue
  525 mm=mm+1
      olab(mm)=2
      if (mm.lt.nid) go to 527
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  527 mm=mm+1
      olab(mm)=1
      if (mm.lt.nid) go to 528
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  528 mm=mm+1
      jz=nt
      kz=mt
      ig=0
      if (ip.eq.1) go to 529
      ka=1
      ja=ip-1
  531 do 530 l=ka,ja
      jz=jz+1
      kz=kz+1
      if (iot(jz).eq.iot(kz)) go to 530
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.2) go to 532
      go to 807
  530 continue
      go to 529
  807 ka=l
      kz=kz-1
      go to 531
  529 la=jp-1
      if (ip.eq.la) go to 533
      ja=ip+1
      kz=kz+1
 534  do 535 l=ja,la
      jz=jz+1
      kz=kz+1
      if (iot(jz).eq.iot(kz)) go to 535
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.2) go to 532
      go to 808
  535 continue
      go to 533
  808 ja=l
      kz=kz-1
      go to 534
  533 if (jp.eq.nr) go to 536
      ia=jp+1
      kz=mt+jp
  537 do 538 l=ia,nr
      kz=kz+1
      jz=jz+1
      if (iot(jz).eq.iot(kz)) go to 538
      ig=ig+1
      lab(ig)=jz-nt
      if (ig.eq.2) go to 532
      go to 809
  538 continue
      go to 536
  809 ia=l
      kz=kz-1
      go to 537
  536 lab(2)=nr
      if (ig.eq.1) go to 532
      lab(1)=nr1
  532 l1=lab(1)
      jz=nt+l1
      kk=iot(jz)
      l2=lab(2)
      jz=nt+l2
      jj=iot(jz)
      olab(mm)=ideks(l2-1)+l1
      if (mm.lt.nid) go to 539
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  539 mm=mm+1
      olab(mm)=ideks(jp-1)+ip
      go to 540
  522 mm=mm+1
      olab(mm)=4
      if (mm.lt.nid) go to 541
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  541 mm=mm+1
      jz=nt
      if (nr.eq.1) go to 546
      kz=mt
      if (ip.eq.1) go to 542
      ja=ip-1
      do 543 l=1,ja
      jz=jz+1
      kz=kz+1
      nn=iot(jz)
      if (nn.ne.iot(kz)) go to 544
  543 continue
      if (ip.eq.nr) go to 546
  542 ja=ip+1
      kz=kz+1
      do 547 l=ja,nr
      jz=jz+1
      kz=kz+1
      nn=iot(jz)
      if (nn.ne.iot(kz)) go to 544
  547 continue
  546 nn=iot(jz+1)
      l1=nr
      go to 548
  544 l1=jz-nt
  548 olab(mm)=l1
      if (mm.lt.nid) go to 549
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  549 mm=mm+1
      olab(mm)=ip
      if (mm.lt.nid) go to 550
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  550 mm=mm+1
      iax=nir(ll)
      olab(mm)=iax
      if (mm.lt.nid) go to 897
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
 897  mm=mm+1
      iay=ideks(iax+1)
      iaz=ideks(iay+1)
      mq=lj(iax)
      mv=ideks(mq+1)
      iaq=iay-iax
      iaw=iaz-iay
      iat=nit(iaz)
      ii=loc(ll)
      kk=loc(nn)
      km=ideks(kk)
      nm=ideks(ii)
      if (ii.gt.kk) go to 560
      olab(mm)=kk
      if (mm.lt.nid) go to 561
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  561 mm=mm+1
      olab(mm)=ii
      if (mm.lt.nid) go to 562
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  562 jb=km+ii
      go to 565
  560 olab(mm)=ii
      if (mm.lt.nid) go to 563
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  563 mm=mm+1
      olab(mm)=kk
      if (mm.lt.nid) go to 564
      mm=0
      call pack(olab8,8,olab,2000)
      write (ntape) olab8
  564 jb=nm+kk
  565 nix=-1
      if (nr.eq.1) go to 519
      jz=mt
      kix=1
      lp=ip
      ir=nr
      go to 518
  113 mz=mz+nx
  105 mt=mt+nx
      do 570 k=1,nx
      nt=nt+1
      ll=iot(nt)
  570 jcon(ll)=0
  100 nz=nt+nr
      return
      end
      subroutine ver_mrdci6(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mrdci6.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
