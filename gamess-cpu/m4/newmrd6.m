      subroutine nmrdci2(core,odebug)
      implicit REAL  (a-h,p-z), integer (i-n)
      logical odebug
c
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/discc)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
      REAL occ
      common/blkorbs/value(maxorb),occ(maxorb+1),iorbs,
     *newbas,ksum,ivalue,iocc,ipad
      integer nston, mtype, nhuk, ltape, ideli, ntab, mtapev
      integer nf88, iput, mousa, ifox
      integer lun20, lun21, lun22, lunalt
      integer lun01, lund, lun02, lun03, jtmfil
      common /ftap5/ nston, mtype, nhuk, ltape, ideli,
     +               ntab, mtapev, nf88, iput, mousa, ifox,
     +               lun20, lun21, lun22, lunalt,
     +               lun01, lund, lun02, lun03, jtmfil
c
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
c
      REAL occatr
      common/scrtch/irm(mxcrec),ibal(8),itil(8),
     + mcomp(maxorb),e(ndime),c8(4*maxat),nzer(maxorb),
     + tc(maxorb),rr(maxorb),occatr(maxorb),
     + nfil(8),ndog(20),jrm(126)
      common/bufb/nconf(5),lsym(8*maxorb),ncomp(maxorb),
     + mper(maxorb),intp(maxorb),intn(maxorb),jcon4(maxorb),
     + nda(20),mj4(20),ided(20),nj(8),kj(8),ntil(8),nbal(9),
     + idep(8),lj(8),nstr(5),nytl(5),nplu(5),ndub(5),
     + jtest(mxnshl),ktest(mxnshl),ibug(4)
CMR   Allocate space for the different abuses of lsort
      double precision bytes(maxorb*2+maxat*9+2000)
      common/lsort/ical,iswh,m,mu,m2,imo,iorbs4,knu,bytes
      parameter (maxroot=50)
      REAL enegx, enegs
      common/scra6/enegx(4,maxroot),enegs(4,maxroot)
c
      dimension core(*)
c
      write(iwr,3)yed(idaf),ibl3d
 3    format(/1x,104('=')//
     *40x,39('*')/
     *40x,'*** MRD-CI V2.0: Natural Orbital Module'/
     *40x,39('*')//
     *1x,'dumpfile on ',a4,' at block',i6/)
       if(ibl3d)12,12,13
 12   call caserr('invalid starting block for dumpfile')
 13   if(num.le.0.or.num.gt.maxorb) call caserr(
     * 'invalid number of basis functions')
      ivalue=-1
      iocc=1
c
c     first restore limited information from iput
c
      call iput_in(iput, nconf, nytl, nplu, ndub, 
     +             iswh, m, imo, enegx, odebug,iwr)
c
c      now restore information from conversion adapt and tran routines
c      must allocate space for cf and icf
c
      nbsq = num * num
      need = nbsq + lenint(nbsq)
      i6 = igmem_alloc(need)
      i7 = i6 + nbsq
      call nf3in(core(i6),core(i7),nbsq,lunalt,knu,
     +           iwr,odebug)
c
      iorbs4 = iorbs
c
      if(odebug) then
       write(iwr,*) 'imo =',imo
       write(iwr,*) 'knu =',knu
       write(iwr,*) 'iswh =',iswh
       write(iwr,*) 'nconf=',nconf
       write(iwr,*) 'nytl=',nytl
       write(iwr,*) 'nplu=',nplu
       write(iwr,*) 'ndub=',ndub
       write(iwr,*) 'iorbs',iorbs
       write(iwr,*) 'kj  =',kj
       write(iwr,*) 'lj  =',lj
       write(iwr,*) 'ibal=',ibal
       write(iwr,*) 'itil=',itil
       write(iwr,*) 'ksum=',ksum
       write(iwr,*) 'mcomp(1)=',mcomp(1)
      endif
c
      if(iorbs.ne.num.or.imo.gt.ksum.or.ksum.gt.iorbs)
     * call caserr('inconsistent parameters on dumpfile')
c     rewind iput
      newbas=iorbs
      len1=ksum*iorbs
      nxx=imo*(imo+1)/2
      len3=imo*imo
      i1=1
      i2=i1+nbsq
      i3=i2+len1
      i4=i3+nxx
      i5=i4+len3
      i8=i5+len3
      lenmat=100000
c     for imat and jmat
      i9=i8+lenmat
      need = i9 + 3780
      i1 = igmem_alloc(need)
      i2=i1+nbsq
      i3=i2+len1
      i4=i3+nxx
      i5=i4+len3
      i8=i5+len3
      i9=i8+lenmat
      call nmrd0n(core(i1),core(i6),core(i2),core(i3),core(i4),
     +            core(i5),core(i6),core(i7),core(i8),lenmat,
     +            core(i9),
     +            enegx,nbsq,
     +            len1,nxx,len3,iput,odebug)
      call clredx
      call rewftn(iput)
c
      call gmem_free(i1)
c
      call gmem_free(i6)
c
      return
      end
      subroutine eigenf(a,r,n,mv)
      implicit REAL  (a-h,o-z), integer (i-n)
      dimension a(*),r(*)
      if(mv-1) 10,25,10
  10  iq=-n
      do 20 j=1,n
      iq=iq+n
      do 20 i=1,n
      ij=iq+i
      r(ij)=0.0d0
      if(i-j) 20,15,20
  15  r(ij)=1.0d0
  20  continue
  25  anorm=0.0d0
      do 35 i=1,n
      do 35 j=i,n
      if(i-j) 30,35,30
  30  ia=i+(j*j-j)/2
      anorm=anorm+a(ia)*a(ia)
  35  continue
      if(anorm) 165,165,40
  40  anorm=1.414d0*dsqrt(anorm)
      anrmx=anorm*1.0d-6/dfloat(n)
      ind=0
      thr=anorm
  45  thr=thr/dfloat(n)
  50  l=1
  55  m=l+1
  60  mq=((m*m)-m)/2
      lq=((l*l)-l)/2
      lm=l+mq
      if(dabs(a(lm))-thr) 130,65,65
  65  ind=1
      ll=l+lq
      mm=m+mq
      x=0.5d0*(a(ll)-a(mm))
      y=-a(lm)/dsqrt(a(lm)*a(lm)+x*x)
      if(x) 70,75,75
  70  y=-y
  75  if(y .gt. 1.0d0) y=1.0d0
      if(y .lt. -1.0d0) y=-1.0d0
      sinx=y/dsqrt(2.0d0*(1.0d0+(dsqrt(1.0d0-y*y))))
      sinx2=sinx*sinx
      cosx=dsqrt(1.0d0-sinx2)
      cosx2=cosx*cosx
      sincs=sinx*cosx
      ilq=n*(l-1)
      imq=n*(m-1)
      do 125 i=1,n
      iq=(i*i-i)/2
      if(i-l) 80,115,80
  80  if(i-m) 85,115,90
  85  im=i+mq
      go to 95
  90  im=m+iq
  95  if(i-l) 100,105,105
 100  il=i+lq
      go to 110
 105  il=l+iq
 110  x=a(il)*cosx-a(im)*sinx
      a(im)=(a(il)*sinx)+(a(im)*cosx)
      a(il)=x
 115  if(mv-1) 120,125,120
 120  ilr=ilq+i
      imr=imq+i
      x=r(ilr)*cosx-r(imr)*sinx
      r(imr)=(r(ilr)*sinx)+(r(imr)*cosx)
      r(ilr)=x
 125  continue
      x=2.0d0*a(lm)*sincs
      y= (a(ll)*cosx2)+(a(mm)*sinx2)-x
      x=(a(ll)*sinx2)+(a(mm)*cosx2)+x
      a(lm)=(a(ll)-a(mm))*sincs+a(lm)*(cosx2-sinx2)
      a(ll)=y
      a(mm)=x
 130  if(m-n) 135,140,135
 135  m=m+1
      go to 60
 140  if(l-n+1) 145,150,145
 145  l=l+1
      go to 55
 150  if(ind-1) 160,155,160
 155  ind=0
      go to 50
 160  if(thr-anrmx) 165,165,45
 165  iq=-n
      do 185 i=1,n
      iq=iq+n
      ll=i+(i*i-i)/2
      jq=n*(i-2)
      do 185 j=i,n
      jq=jq+n
      mm=j+(j*j-j)/2
      if(a(ll)-a(mm)) 170,185,185
 170  x=a(ll)
      a(ll)=a(mm)
      a(mm)=x
      if(mv-1) 175,185,175
 175  do 180 k=1,n
      ilr=iq+k
      imr=jq+k
      x=r(ilr)
      r(ilr)=r(imr)
 180  r(imr)=x
 185  continue
      return
      end
      subroutine nmrd0n(qat,qatr,y,gx,w,q,cf,icf,
     +                  imat,lenmat,jmat,
     +                  enegx,lensq,
     +                  len1,len2,len3,
     +                  ifox,odebug)
      implicit REAL  (a-h,o-z), integer (i-n)
      logical odebug, oextrap
      character *1 dash,star
      character *4 tagg
INCLUDE(common/sizes)
c
INCLUDE(common/prints)
      parameter (maxroot=50)
      common/blkorbs/vvv(maxorb),occat(maxorb+1),iorbs4,
     + newbas,ksum,ivalue,iocc,ispace
      common/natorbn/itag(maxroot),isec(maxroot),jsec(maxroot),nwi
INCLUDE(common/mapper)
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      REAL occatr
      common/scrtch/irm(mxcrec),ibal(8),itil(8),
     + mcomp(maxorb),e(ndime),c(4*maxat),nzer(maxorb),
     + tc(maxorb),rr(maxorb),occatr(maxorb),
     + nfil(8),ndog(20),jrm(126)
      common/bufb/nconf(5),lsym(8*maxorb),ncomp(maxorb),
     + mper(maxorb),intp(maxorb),intn(maxorb),jcon(maxorb),
     + nda(20),mj(20),ided(20),nj(8),kj(8),ntil(8),nbal(9),
     + idep(8),lj(8),nstr(5),nytl(5),nplu(5),ndub(5),
     + jtest(mxnshl),ktest(mxnshl),ibug(4),
     + ipt(maxorb),iipt(maxorb)
c
      integer imap, ihog, jmap
      common /scra4/ imap(504),ihog(48),jmap(140)
      REAL fj, gj, h, f, g
      integer jkan, ikan
      common /scra5/ fj(1000),gj(500),h(100),
     +                f(1000),g(500),
     +              jkan(500),ikan(500)
      common/scr1/vnuc,zero,nit(667),newya(maxorb),ij(8),n
c
INCLUDE(common/iofile)
      common/ftap5/ntaper(15),
     +             lun01, lund, lun02, lun03, jtmfil
      common/lsort/ical,iswh,m,mu,m2,imo,iorbs,knu
c
      integer iselecx,izusx,iselect
      common /cselec/ iselecx(maxroot),izusx(maxroot),
     +                iselect(maxroot),nrootci,
     +                iselecz(maxroot)
c
      parameter (maxref=256)
      REAL edavit,cdavit,extrapit,eigvalr,cradd,
     +     weighb, rootdel, ethreshit
      integer mbuenk,nbuenk,mxroots
      logical ifbuen, ordel, odave, oweight, odavit
      common /comrjb2/edavit(maxroot),cdavit(maxroot),
     +                odavit(maxroot),
     +                extrapit(maxroot),ethreshit(maxroot),
     +                eigvalr(maxref),cradd(3),weighb,
     +                rootdel,ifbuen,mbuenk,mxroots,
     +                ordel,odave,nbuenk,oweight
c
      dimension qat(lensq),w(len3),y(len1),gx(len2),q(len3)
      dimension qatr(lensq)
      dimension imat(lenmat),jmat(3780)
      dimension cf(lensq),icf(lensq)
      dimension enegx(4,*)
      dimension tagg(2),ilifs(maxorb)
c
      data two/2.0d0/
      data tagg/'sabf','a.o.'/
      data dash,star/'-','*'/
c
 9500 format(/' *** commence natural orbital analysis at ',f8.2,
     * ' secs.')
c     read(ifox)iwod,vnuc,zero,imo,m,nconf,newya,
c    + nytl,nplu,ndub,iswh,ksum,iorbs,
c    + knu,cf,icf,c,ibal,itil,mcomp,kj,lj,n,ifrk,e,lsym,nsel,nj,
c    + ntil,nbal,ncomp
c
c     specify default settings ....
c     density matrix o/p to ft42
c     natural orbital generation
c     abelian point groups only
c
      lwater=1
      iprp=1
      ndeg=0
      nwinit = nwi
c
      if(ifbuen) then
c     reset nwi if greater than current nrootci
       if(nwi.gt.nrootci) nwi = nrootci
      endif
c
      if(nwi.le.0.or.nwi.gt.maxroot)call caserr(
     *'invalid number of orbital sets requested')
      do 7002 i=1,nwi
      if(itag(i).le.0.or.itag(i).gt.1000)call caserr(
     *'invalid orbital set requested')
 7002 continue
      write(iwr,8000)nwi,(itag(i),i=1,nwi)
 8000 format(/
     *' *** natural orbital analysis requested for',i3,
     *' ci vectors'//5x,
     *'with following locations on the ci vector file (ft36)'
     *,50i3)
      if(oprint(32))
     *write(iwr,8501)
 8501 format(/
     *' print of density matrix and n.o.s in mo basis requested'/)
      do 20006 i=1,nwi
      if(isec(i).gt.0)write(iwr,7004)tagg(1),i,isec(i)
      if(jsec(i).gt.0)write(iwr,7004)tagg(2),i,jsec(i)
      if(isec(i).gt.350. or .jsec(i).gt.350)
     * call caserr('invalid dumpfile section specified for nos.')
20006 continue
 7004 format(/
     *' ** route n.o.s ( ',a4,' basis) for state',i3,
     *' to section',i4,' of dumpfile')
      write(iwr,7053)imo,m
 7053 format(//
     *' no. of active orbitals ',i3/
     *' no. of active electrons',i3/)
      write(iwr,3)(dash,i=1,40)
 3    format(
     *' irreducible       no. of'/
     *' representation    active orbitals'/1x,40a1)
      do i=1,n
       if (lj(i).gt.0) then
        write(iwr,7061)i,lj(i)
       endif
      enddo
 7061 format(7x,i5,10x,i3)
      write(iwr,7071)(dash,i=1,40)
 7071 format(1x,40a1)
      jx=0
      do i=1,iorbs
       nzer(i)=jx
       jx=jx+ncomp(i)
      enddo
      icore=ksum-imo
      icorp=icore-1
      im9=iky(imo+1)
      if(im9.ne.len2)call caserr(
     *'inconsistency detected in contents of table-ci interfaces')
      iimo=0
      do i=1,ksum
       ilifs(i)=iimo
       iimo=iimo+iorbs
      enddo
      ncol=ksum*iorbs
      jx=0
       mb=0
      ibuk=0
      mg=icore*iorbs
      do 303 i=1,n
      kp=kj(i)
      lp=kp-lj(i)
      kx=ntil(i)
      do 303 j=1,kp
      if(j.gt.lp) go to 360
      jz=ibuk
      id=ibuk+1
      ibuk=ibuk+iorbs
      jw=ibuk
      go to 361
 360  jz=mg
      id=mg+1
      mg=mg+iorbs
      jw=mg
361   do k=id,jw
       y(k)=0
      enddo
      mb=mb+1
      ll=mcomp(mb)
      do k=1,ll
       jx=jx+1
       vm=cf(jx)
       nzh=icf(jx)+kx
       lx=nzer(nzh)
       nzh=ncomp(nzh)
        do l=1,nzh
        lx=lx+1
        ibj=lsym(lx)
        if(ibj.le.0) then
         y(jz-ibj)=-vm
        else
         y(jz+ibj)=vm
        endif
        enddo
      enddo
 303  continue
      if(iprp.eq.0) go to 308
      call rewftn(lund)
      write(lund)iorbs,imo,icore,n,lj,knu,m,y,e,c,newya
      if(lwater.eq.0) go to 20
308   do i=1,imo
       mper(i)= i
      enddo
      do i=1,n
       nda(i)=i
       mj(i)=lj(i)
      enddo
20    mu=m-2
      m2=m+2
      nzh=0
      cpu=cpulft(1)
      write(iwr,9500)cpu
c
      do 1000 i=1,nwi
      write(iwr,9000)(star,j=1,104)
 9000 format(/1x,104a1)
      write(iwr,8502)i
 8502 format(/40x,
     *'natural orbital analysis for state no.',i3/40x,41('-')/)
      call vclr(qat,1,ncol)
      iimo=0
      nid=itag(i)
      oextrap = .true.
      do loop =1,4
       if(dabs(enegx(loop,nid)).le.1.0d-5) oextrap =.false.
      enddo
      if (oextrap) then
       write(iwr,8600) enegx(1,nid),enegx(2,nid),
     +                 enegx(4,nid)
 8600  format(1x,'CI energy           = ',f15.8, ' hartree '/
     +        1x,'extrapolated energy = ',f15.8, ' hartree '/
     +        1x,'c**2                = ',f10.4/)
      else
       write(iwr,8601)
 8601  format(1x,'extrapolated energies not available'/)
      endif
30    nzh=nzh+1
      if (odebug) write(iwr,*) 'nid,nzh= ', nid,nzh
      if (nzh.ne.nid) go to 31
      call rewftn(lun01)
      nreclun = 0
      if (odebug) write(iwr,*) 'rewind unit ', lun01
      do  j=1,iswh
       if (odebug) write(iwr,*) 'j, nconf(j)=', j, nconf(j)
       if (nconf(j).gt.0) then
       read (ifox,err=8610,end=8611) nhb,imax,ndt,kml,imap,ihog
       write (lun01)nhb,imax,ndt,kml,imap,ihog
       nreclun = nreclun + 1
c      if (mod(nconf(j),imax).eq.0)then
c       nhb = nhb + 1
c      endif
       if (odebug) write(iwr,*) 'nhb,imax = ', nhb, imax
        do k=1,nhb
        read (ifox,err=8610,end=8611) jkan,fj,g,h
        nreclun = nreclun + 1
        write (lun01)jkan,fj,g,h
        enddo
       endif
      enddo
      if (odebug) write(iwr,*) 
     +      'total no. of record to lun01 = ', nreclun
      call rewftn(lun01)
      go to 32
  31  do j=1,iswh
       if (nconf(j).gt.0) then
        read (ifox) nhb,imax
c       if (mod(nconf(j),imax).eq.0)then
c        nhb = nhb + 1
c       endif
        do k=1,nhb
        read (ifox)
        enddo
       endif
      enddo
      go to 30
  32  call vclr(q,1,im9)
      call nmrd1n(q,imat,lenmat,jmat,iwr,odebug)
      if(.not.oprint(32))go to 8503
      write(iwr,511) i
 511  format(/20x,
     *'first order ci density matrix for state no.',i2,
     *'  (active mo basis)'/)
      call writel(q,imo)
      write(iwr,9000)(dash,j=1,104)
8503  if (iprp.eq.0) go to 501
      write(lund) im9,q
      if(lwater.eq.0) go to 1000
 501  if(oprint(32))
     *write(iwr,451)i
 451  format(/20x,
     *' *** natural orbitals (active mo basis) for state',
     *i2,' ****'//)
      call rewftn(lun01)
      do j=1,n
       nfil(j)=0
      enddo
      if(icore.eq.0) go to 450
      lw=-iorbs
      do 322 k=1,n
      ix=kj(k)-lj(k)
      if(ix.eq.0) go to 322
      iz=ntil(k)
      lx=nj(k)
      ky=nbal(k)+1
      nfil(k)=nfil(k)+ix
      do l=1,ix
       lw=lw+iorbs
       jz=iz
       ls=ky
       do mb=1,lx
        jz=jz+1
        ks=lsym(ls)+lw
        ls=ls+ncomp(jz)
        rr(mb)=y(ks)
       enddo
       iimo=iimo+1
       iii=iz+ilifs(iimo)
       call dcopy(lx,rr,1,qat(iii+1),1)
       occat(iimo)=two
      enddo
322   continue
450   if(ndeg.eq.0) then
       do j=1,n
        ided(j)=j
       enddo
       ideg=n
      endif
C
      ix=0
      imom=0
      orb=0
      do 504 j=1,ideg
      ix=ix+1
      mjk=mj(j)
      if (ided(j).eq.ix) go to 505
      ix=ix-1
      imom=imom+mjk
      go to 504
505   jmom=imom
      ndog(1)=j
      imom=imom+mjk
      iz=(jmom+icorp)*iorbs
      nstr(1)=iz
      nbas=1
      lx=jmom
      idx=0
      do l=1,mjk
       lx=lx+1
       kp=mper(lx)
       kp=iky(kp)
       kx=jmom
       do k=1,l
        kx=kx+1
        lp=mper(kx)+kp
        idx=idx+1
        gx(idx)=q(lp)
       enddo
      enddo
      if (j.eq.ideg) go to 507
      ja=j+1
      jmom=imom
      do 508 jb=ja,ideg
      if (ided(jb).eq.ix) go to 509
      jmom=jmom+mj(jb)
      go to 508
509   iz=(jmom+icorp)*iorbs
      nbas=nbas+1
      ndog(nbas)=jb
      nstr(nbas)=iz
      lx=jmom
      idx=0
      do l=1,mjk
       lx=lx+1
       kp=mper(lx)
       kp=iky(kp)
       kx=jmom
       do k=1,l
        kx=kx+1
        lp=mper(kx)+kp
        idx=idx+1
        gx(idx)=gx(idx)+q(lp)
       enddo
      enddo
      jmom=jmom+mjk
508   continue
507   vm=0.0d0
      if (mjk.eq.1) go to 550
      call eigenf(gx,w,mjk,0)
      ida=0
      idb=0
      do 520 k=1,mjk
      idb=idb+k
      orc=gx(idb)
      vm=vm+orc
      if(oprint(32) )write(iwr,521)(star,l=1,104)
     *,ix,k,orc
 521  format(/1x,104a1/
     * ' irrep. no. ',i1,3x,
     *' n.o. sequence no.',i3,5x,
     *' occupation ',f14.8//)
      idc=ida+1
      ida=ida+mjk
      if(oprint(32) )write(iwr,522) (w(l),l=idc,ida)
522   format(/5x,10f12.8)
      do 526 l=1,nbas
      iz=nstr(l)
      do la=1,iorbs
       iz=iz+1
       jz=iz
       cz=0.0d0
       do lb=idc,ida
        jz=jz+iorbs
        cz=cz+w(lb)*y(jz)
       enddo
       tc(la)=cz
      enddo
      ig=ndog(l)
      ia=nda(ig)
      id=nfil(ia)+1
      write(lun01)orc,(tc(la),la=1,iorbs)
      nfil(ia)=id
      lb=nj(ia)
      iw=ntil(ia)
      ig=nbal(ia)+1
      do la=1,lb
       iw=iw+1
       ks=lsym(ig)
       ig=ig+ncomp(iw)
       rr(la)=tc(ks)
      enddo
c
      iimo=iimo+1
      iii=ilifs(iimo)+ntil(ia)
      call dcopy(lb,rr,1,qat(iii+1),1)
      occat(iimo)=orc
c
526   continue
520   continue
      write(iwr,527)ix,vm
 527  format(/' **** irrep. no. ',i1,
     *10x,'**** sum of occupation numbers',f14.8/)
      orb=orb+vm
      if(oprint(32))write(iwr,9000)(dash,l=1,104)
      go to 504
550   orc=gx(1)
      orb=orb+orc
      if(oprint(32))write(iwr,521)(star,l=1,104), ix,mjk,orc
      do ld=1,nbas
       la=nstr(ld)+iorbs
       lb=la+1
       la=la+iorbs
       ig=ndog(ld)
       ia=nda(ig)
       id=nfil(ia)+1
       nfil(ia)=id
       write(lun01)orc,(y(ll),ll=lb,la)
       la=lb-1
       lb=nj(ia)
       iw=ntil(ia)
       ig=nbal(ia)+1
       do ir=1,lb
         iw=iw+1
         ks=lsym(ig)+la
         ig=ig+ncomp(iw)
         rr(ir)=y(ks)
       enddo
       iimo=iimo+1
       iii=ilifs(iimo)+ntil(ia)
       call dcopy(lb,rr,1,qat(iii+1),1)
       occat(iimo)=orc
      enddo
      write(iwr,527)ix,orc
504   continue
      write(iwr,553) orb
553   format(/2x,'total active electron sum',f20.8)
c
c     order by occupation numbers
c
      nact = iimo - icore
      nnn = iimo
      if (odebug) 
     +     write(iwr,*) (occat(j),j=1,nnn)
      call nosrt(nact,occat(icore+1),ipt,iipt)
      do j=1,icore
      iipt(j)=j
      enddo
      do j=1,nact
      iipt(j+icore)=icore+ipt(j)
      enddo
      if (odebug) 
     +    write(iwr,*) (iipt(j),j=1,nnn)
      do j = 1,icore
      kk = ilifs(j)+1
      occatr(j)=occat(j)
      call dcopy(iorbs,qat(kk),1,qatr(kk),1)
      enddo
      do j = icore+1, nnn
       kk = ilifs(j)+1
       kkk = ilifs(iipt(j))+1
       occatr(j)=occat(iipt(j))
       call dcopy(iorbs,qat(kkk),1,qatr(kk),1)
      enddo
      call dcopy(icore+nact,occatr,1,occat,1)
c
      if(isec(i).gt.0)then
       call putqnon(qatr,zero,tagg(1),isec(i),1)
      endif
      call rewftn(lun01)
c
c   now output n.o.s in ao representation
c   o/p to lineprinter comprises active orbitals ** only **
c   symmetry ordered, and occupation ordered within each irrep
c   o/p to dumpfile , section jsec(i), includes core orbitals
c
      ibuk=0
      jcore=0
      mg=icore
      nact=0
      do 9003 ir=1,n
      kp=kj(ir)
      lp=kp-lj(ir)
      do 9003 ld=1,kp
      if(ld.gt.lp)go to 9001
      jcore=jcore+1
      iimo=ilifs(jcore)
      occat(jcore)=two
      do k=1,iorbs
       qat(newya(k)+iimo)=y(ibuk+k)
      enddo
      ibuk=ibuk+iorbs
      go to 9003
 9001 nact=nact+1
      mgg=ilifs(mg+nact)
      read(lun01,err=8612,end=8613 )orc,
     +                (qat(newya(k)+mgg),k=1,iorbs)
      occat(mg+nact)=orc
 9003 continue
c
c     order by occupation nos 
c
      nnn = icore + nact
      if (odebug)
     +    write(iwr,*) (occat(j),j=1,nnn)
      call nosrt(nact,occat(icore+1),ipt,iipt)
      do j=1,icore
       iipt(j)=j
      enddo
      do j=1,nact
       iipt(j+icore)=icore+ipt(j)
      enddo
      if (odebug) write(iwr,*) (iipt(j),j=1,nnn)
      do j = 1,icore
      kk = ilifs(j)+1
      occatr(j)=occat(j)
      call dcopy(iorbs,qat(kk),1,qatr(kk),1)
      enddo
      do j = icore+1, nnn
       kk = ilifs(j)+1
       kkk = ilifs(iipt(j))+1
       occatr(j)=occat(iipt(j))
       call dcopy(iorbs,qat(kkk),1,qatr(kk),1)
      enddo
      call dcopy(icore+nact,occatr,1,occat,1)
c
      write(iwr,9000)(dash,j=1,104)
      write(iwr,9600)i
 9600 format(/40x,'natural orbitals for state',i3,
     *'  (a.o. basis)'/40x,43('-')/)
      if(oprint(31))call prev(qat(icore*iorbs+1),occat(icore+1),
     *  nact,iorbs,iorbs)
      write(iwr,9601)
      mg1=mg+1
      mg2=mg+nact
      write(iwr,9602)(occat(k),k=mg1,mg2)
 9602 format(/10x,8f14.7)
 9601 format(/50x,'occupation numbers'/50x,18('-'))
      if(jsec(i).le.0)go to 1000
      call putqnon(qatr,zero,tagg(2),jsec(i),2)
1000  continue
      cpu=cpulft(1)
      write(iwr,8001)cpu
 8001 format(/1x,104('*')//
     *' *** end of natural orbital analysis at ',f8.2,
     * ' secs.'/)
c
      call rewftn(lun01)
      call rewftn(lund)
c
      nwi =  nwinit
      return
 8610 call caserr('error on reading ci vector file')
 8611 call caserr('unexpected end of ci vector file')
 8612 call caserr('error on reading MO scratch file')
 8613 call caserr('unexpected end of MO scratch file')
      return
      end
      subroutine nosrt(newbas,e,ipt,iipt)
      implicit REAL (a-h,o-z), integer (i-n)
      dimension e(newbas),ipt(newbas),iipt(newbas)
c
      do i=1,newbas
       iipt(i)=i/2
      enddo
c... binary sort of e.values to increasing value sequence
      ipt(1)=1
      do 19 j=2,newbas
      ia=1
      ib=j-1
      test=e(j)
   53 irm1=ib-ia
      if(irm1)58,50,51
   51 ibp=ia+iipt(irm1)
      if(test.lt.e(ipt(ibp)))goto 52
c...  insert into high half
      ia=ibp+1
      goto 53
c... insert into low half
   52 jj=ib
      do i=ibp,ib
       ipt(jj+1)=ipt(jj)
       jj=jj-1
      enddo
      ib=ibp-1
      goto 53
c...  end point of search
   50 jj=ipt(ia)
      if(test.ge.e(jj))goto 57
      ipt(ia+1)=jj
   58 ipt(ia)=j
      goto 19
   57 ipt(ia+1)=j
   19 continue
c
c      invert above ordering
c
      itest=newbas+1
      ip1=iipt(newbas)
      do  i=1,ip1
       j=itest-i
       k=ipt(i)
       ipt(i)=ipt(j)
       ipt(j)=k
      enddo
c
      return
      end
_EXTRACT(nmrd1n,_AND(hp800,i8))
      subroutine nmrd1n(q,imat,lenmat,jmat,iwr,odebug)
      implicit REAL  (a-h,o-z), integer (i-n)
      logical odebug
INCLUDE(common/sizes)
      parameter (maxroot=50)
c
      common/blkorbs/vvv(maxorb),occat(maxorb+1),nspabc(6)
      common/natorbn/itag(maxroot),isec(maxroot),jsec(maxroot),nwi
INCLUDE(common/mapper)
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      REAL occatr
      common/scrtch/irm(mxcrec),ibal(8),itil(8),
     + mcomp(maxorb),e(ndime),c(4*maxat),nzer(maxorb),
     + tc(maxorb),rr(maxorb),occatr(maxorb),nfil(8),ndog(20),
     + jrm(126)
      common/bufb/nconf(5),lsym(8*maxorb),ncomp(maxorb),
     + mper(maxorb),intp(maxorb),intn(maxorb),jcon(maxorb),
     + nda(20),mj(20),ided(20),nj(8),kj(8),ntil(8),nbal(9),idep(8),
     + lj(8),nstr(5),nytl(5),nplu(5),ndub(5),jtest(mxnshl),
     + ktest(mxnshl),ibug(4)
      common/ftap5/ntaper(15),
     +             lun01, lund, lun02, lun03, jtmfil
c
      integer imap, ihog, jmap
      common /scra4/ imap(504),ihog(48),jmap(140)
      REAL fj, gj, h, f, g
      integer jkan, ikan
      common /scra5/ fj(1000), gj(500), h(100),
     +                f(1000),  g(500),
     +              jkan(500), ikan(500)
c
      common/lsort/ical,iswh,m,mu,m2,imo,iorbs,knu
c
      dimension q(*),imat(lenmat),jmat(3780)
c
      ical=1
      nreclun = 0
      do 43 j=1,iswh
      nc=nconf(j)
      if(odebug) write(iwr,*)'j, nc = ',j,nc
      if (nc.eq.0) go to 43
      read (lun01,err=8620,end=8613) 
     +      jhb,jmax,nd,kml,imap,ihog
      if(odebug) write(iwr,*)'43: jhb = ', jhb
      nl=nytl(j)
      nmns=j-1
      nqns=j-2
      nps=nplu(j)
      ndb=ndub(j)
      ndbq=ndb+ndb
      nod=nmns+nps
      nod2=nod-m2
      jcl=0
      idel=nd*m
      do 100 na=1,jhb
      jcl=jcl+jmax
      if(jcl.gt.nc) jmax=jmax+nc-jcl
      read(lun01,err=8620,end=8613) ikan,fj,gj,h
      nxj=0
      k4=0
      k5=0
      nreclun = nreclun + 1
      if(odebug) write(iwr,*)
     +   ' 100: processing jhb records, number = '
     +          , nreclun
      do 44 k=1,jmax
      do l=1,nl
       nxj=nxj+1
       jtest(l)=ikan(nxj)
      enddo
      if(nmns.gt.0) go to 56
      irm(k)=1
      if (nps.eq.0) go to 57
      do 58 l=1,nps
      k4=k4+1
58    imat(k4)=jtest(l)
      if (ndb.eq.0) go to 44
57    kx=nps
      do l=1,ndb
       kx=kx+1
       k4=k4+1
       lk=jtest(kx)
       imat(k4)=lk
       k4=k4+1
       imat(k4)=-lk
      enddo
      go to 44
56    jq=1
      lx=k4
      do 60 l=1,nd
      k5=k5+1
      irm(k5)=1
      jz=jq+nqns
      jy=imap(jq)
      do 61 kk=1,nod
      lx=lx+1
      if (kk.ne.jy)  go to 62
      if (jz.eq.jq) go to 63
      jq=jq+1
      jy=imap(jq)
63    imat(lx)=-jtest(kk)
      go to 61
62    imat(lx)=jtest(kk)
61    continue
      jq=jz+1
60    lx=lx+ndbq
      if (ndb.eq.0) go to 101
      kx=nod2+k4
      kk=nod
      do l=1,ndb
       kk=kk+1
       lk=jtest(kk)
       kx=kx+2
       mx=kx
       do ll=1,nd
        mx=mx+m
        imat(mx+1)=lk
        imat(mx+2) =-lk
       enddo
      enddo
      k4=mx+2
      go to 44
 101  k4=lx
 44   continue
c
      if(ical.gt.1) go to 102
      ical=2
      go to 103
 102  call rewftn(lun01)
      if(j.eq.1) go to 104
      jw=j-1
      if(j.eq.2) go to 105
      j8=j-2
      do k=1,j8
      mc=nconf(k)
      if(mc.ne.0) then
       read(lun01,err=8620,end=8613) nhb
       do l=1,nhb
        read(lun01,err=8620,end=8613)
       enddo
      endif
      enddo
c
 105  mc=nconf(jw)
      if(mc.eq.0) go to 108
      read(lun01,err=8620,end=8613) 
     +       nhb,imax,ndj,kmj,jmap
      nlj=nytl(jw)
      jmns=jw-1
      jqns=jw-2
      jps=nplu(jw)
      jdb=ndub(jw)
      jdbq=jdb+jdb
      nodj=jps+jmns
      nodj2=nodj-m2
      icl=imax
      do 72 iw=1,mc
      if (icl.lt.imax) go to 37
      read (lun01,err=8620,end=8613) jkan,f
      icl=1
      nx=0
      if=0
      go to 38
   37 icl=icl+1
      if=if+ndj
   38 do kw=1,nlj
       nx=nx+1
       ktest(kw) =jkan(nx)
      enddo
      call setsto(imo,0,jcon)
      if(nodj.eq.0) go to 110
      do l=1,nodj
       nt=ktest(l)
       jcon(nt)=1
      enddo
      if(jdb.eq.0) go to 70
 110  kk=nodj
      do l=1,jdb
       kk=kk+1
       nt=ktest(kk)
       jcon(nt)=2
      enddo
70    if (jmns.gt.0) go to 80
      jrm(1)=1
      if (jps.eq.0) go to 81
      do kw=1,jps
       jmat(kw)=ktest(kw)
      enddo
      if (jdb.eq.0) go to 94
81    lx=jps
      kx=jps
      do kw=1,jdb
      kx=kx+1
      lx=lx+1
      lk=ktest(kx)
      jmat(lx)=lk
      lx=lx+1
       jmat(lx)=-lk
      enddo
      go to 94
80    lx=0
      jq=1
      do 85 kw=1,ndj
      jrm(kw)=1
      jz=jq+jqns
      jy=jmap(jq)
      do 86 lw=1,nodj
      lx=lx+1
      if (lw.ne.jy) go to 87
      if (jz.eq.jq) go to 88
      jq=jq+1
      jy=jmap(jq)
88    jmat(lx)=-ktest(lw)
      go to 86
87    jmat(lx)=ktest(lw)
86    continue
      jq=jz+1
85    lx=lx+jdbq
      if (jdb.eq.0) go to 94
      kx=nodj2
      kk=nodj
      do kw=1,jdb
       kk=kk+1
       lk=ktest(kk)
       kx=kx+2
       mx=kx
        do lw=1,ndj
        mx=mx+m
        jmat(mx+1)=lk
        jmat(mx+2)=-lk
       enddo
      enddo
94    nxj=0
      inis=-nd
      igi=-kml
      do 114 l=1,jmax
      inis=inis+nd
      igi=igi+kml
      do ll=1,nl
       nxj=nxj+1
       jtest(ll)=ikan(nxj)
      enddo
      nix=0
      if(nod.eq.0) go to 116
      do 117 ll=1,nod
      jt=jtest(ll)
      if(jcon(jt).gt.0) go to 117
      if(nix.eq.1) go to 114
      nix=1
 117  continue
      if(ndb.eq.0) go to 119
 116  kk=nod
      do 120 ll=1,ndb
      kk=kk+1
      jt=jtest(kk)
      jb=jcon(jt)
      if(jb.eq.2) go to 120
      if(jb.eq.0.or.nix.eq.1) go to 114
      nix=1
 120  continue
 119  if(ndj.gt.kml) go to 150
      inj=-m
      ls=if
      do 151 lw=1,ndj
      ls=ls+1
      orb=f(ls)
      inj=inj+m
      do kw=1,imo
       intp(kw)=0
       intn(kw)=0
      enddo
      ink=inj
      do 153 kw=1,m
      ink=ink+1
      lx=jmat(ink)
      if (lx.lt.0) go to 154
      intp(lx)=kw
      go to 153
154   intn(-lx)=kw
153   continue
      ks=igi
      do 155 kw=1,kml
      nix=0
      ks=ks+1
      ir=ihog(kw)+inis
      ini=(ir-1)*m
      ink=ini
      do 156 mw=1,m
      ink=ink+1
      lo=imat(ink)
      if (lo.lt.0) go to 157
      if (intp(lo).gt.0) go to 156
160   if (nix.eq.1) go to 155
      nix=1
      iodd=mw
      go to 156
157   if(intn(-lo).eq.0) go to 160
156   continue
      if (iodd.eq.1) go to 161
      kx=1
      ky=iodd-1
      ink=ini
169   do 162 mw=kx,ky
      ink=ink+1
      lx=imat(ink)
      if (lx.lt.0) go to 163
      lo=intp(lx)
      go to 164
163   lo=intn(-lx)
164   if (lo.eq.mw) go to 162
      ix=inj+lo
      iy=inj+mw
      ni=jmat(iy)
      jmat(ix)=ni
      jmat(iy)=lx
      jrm(lw)=-jrm(lw)
      if (lx.lt.0) go to 165
      intp(lx)=mw
      go to 166
165   intn(-lx)=mw
166   if (ni.lt.0) go to 167
      intp(ni)=lo
      go to 162
167   intn(-ni)=lo
162   continue
      if (ky.gt.mu) go to 170
161   kx=iodd+1
      ky=m
      ink=ini+iodd
      go to 169
170   vm=orb*gj(ks)
      if (irm(ir).ne.jrm(lw))vm=-vm
      ink=iodd+ini
      ia=imat(ink)
      ink=iodd+inj
      ib=jmat(ink)
      if (ia.gt.0) go to 171
      ia=-ia
      ib=-ib
171   ia=min(ia,ib)+iky(max(ia,ib))
      q(ia)=q(ia)+vm
155   continue
151   continue
      go to 114
150   ks=igi
      do 180 lw=1,kml
      ks=ks+1
      ir=ihog(lw)+inis
      ini=(ir-1)*m
      orb=gj(ks)
      do 181 kw=1,imo
      intp(kw)=0
181   intn(kw)=0
      ink=ini
      do 182 kw=1,m
      ink=ink+1
      lx=imat(ink)
      if (lx.lt.0) go to 183
      intp(lx)=kw
      go to 182
183   intn(-lx)=kw
182   continue
      inj=-m
      ls=if
      do 184 kw=1,ndj
      ls=ls+1
      inj=inj+m
      ink=inj
      nix=0
      do 185 mw=1,m
      ink=ink+1
      lo=jmat(ink)
      if (lo.lt.0) go to 186
      if (intp(lo).gt.0) go to 185
187   if(nix.eq.1) go to 184
      nix=1
      iodd=mw
      go to 185
186   if(intn(-lo).eq.0) go to 187
185   continue
      if (iodd.eq.1) go to 188
      kx=1
      ky=iodd-1
      ink=inj
189   do 190 mw=kx,ky
      ink=ink+1
      lx=jmat(ink)
      if (lx.lt.0) go to 191
      lo=intp(lx)
      go to 192
191   lo=intn(-lx)
192   if (lo.eq.mw) go to 190
      ix=ini+lo
      iy=ini+mw
      ni=imat(iy)
      imat(ix)=ni
      imat(iy)=lx
      irm(ir)=-irm(ir)
      if (lx.lt.0) go to 193
      intp(lx)=mw
      go to 194
193   intn(-lx)=mw
194   if (ni.lt.0) go to 195
      intp(ni)=lo
      go to 190
195   intn(-ni)=lo
190   continue
      if (ky.gt.mu) go to 196
188   kx=iodd+1
      ky=m
      ink=inj+iodd
      go to 189
  196 vm=orb*f(ls)
      if (irm(ir).ne.jrm(kw)) vm=-vm
      ink=iodd+ini
      ia=imat(ink)
      ink=iodd+inj
      ib=jmat(ink)
      if (ia.gt.0) go to 197
      ia=-ia
      ib=-ib
197   ia = min(ia,ib)+iky(max(ia,ib))
      q(ia)=q(ia)+vm
184   continue
180   continue
114   continue
   72 continue
 108  if(na.eq.1) go to 121
 104  nb=na-1
      read(lun01,err=8620,end=8613) nhb,imax
      do 122 jw=1,nb
      read(lun01,err=8620,end=8613) jkan,f,g
      nx=0
      ig=-kml
      do 122 iw=1,imax
      do 203 kw=1,nl
      nx=nx+1
  203 ktest(kw)=jkan(nx)
      ig=ig+kml
      call setsto(imo,0,jcon)
      if(nod.eq.0) go to 124
      do 125 l=1,nod
      nt=ktest(l)
 125  jcon(nt)=1
      if (ndb.eq.0) go to 207
124   kk=nod
      do 126 l=1,ndb
      kk=kk+1
      nt=ktest(kk)
126   jcon(nt)=2
207   if (nmns.gt.0) go to 210
      jrm(1)=1
      if (nps.eq.0) go to 211
      do 212 kw=1,nps
212   jmat(kw)=ktest(kw)
      if (ndb.eq.0) go to 220
211   lx=nps
      kx=nps
      do 213 kw=1,ndb
      kx=kx+1
      lx=lx+1
      lk=ktest(kx)
      jmat(lx)=lk
      lx=lx+1
213   jmat(lx)=-lk
      go to 220
210   lx=0
      do 214 kw=1,kml
      jrm(kw)=1
      jq=(ihog(kw)-1)*nmns+1
      jz=jq+nqns
      jy=imap(jq)
      do 215 lw=1,nod
      lx=lx+1
      if (lw.ne.jy) go to 216
      if (jz.eq.jq) go to 217
      jq=jq+1
      jy=imap(jq)
217   jmat(lx)=-ktest(lw)
      go to 215
216   jmat(lx)=ktest(lw)
215   continue
214   lx=lx+ndbq
      if (ndb.eq.0) go to 220
      kx=nod2
      kk=nod
      do 218 kw=1,ndb
      kk=kk+1
      lk=ktest(kk)
      kx=kx+2
      mx=kx
      do 218 lw=1,kml
      mx=mx+m
      jmat(mx+1)=lk
218   jmat(mx+2) =-lk
220   nxj=0
      inis=-nd
      do 127 l=1,jmax
      inis=inis+nd
      inx=(inis-1)*m
      do 128 ll=1,nl
      nxj=nxj+1
 128  jtest(ll)=ikan(nxj)
      nix=0
      if(nod.eq.0) go to 129
      do 130 ll=1,nod
      jt=jtest(ll)
      if(jcon(jt).gt.0) go to 130
      if(nix.eq.1) go to 127
      nix=1
 130  continue
      if(ndb.eq.0) go to 131
 129  kk=nod
      do 132 ll=1,ndb
      kk=kk+1
      jt=jtest(kk)
      jb=jcon(jt)
      if(jb.eq.2) go to 132
      if(jb.eq.0.or.nix.eq.1) go to 127
      nix=1
 132  continue
 131  ks=ig
      inj=-m
      do 222 kw=1,kml
      ks=ks+1
      orb=g(ks)
      inj=inj+m
      do 223 lw=1,imo
      intp(lw)=0
223   intn(lw)=0
      ink=inj
      do 224 lw=1,m
      ink=ink+1
      lx=jmat(ink)
      if (lx.lt.0) go to 225
      intp(lx)=lw
      go to 224
225   intn(-lx)=lw
224   continue
      ini=inx
      iny=inis
      do 226 lw=1,nd
      ini=ini+m
      ink=ini
      iny=iny+1
      nix=0
      do 227 mw=1,m
      ink=ink+1
      lo=imat(ink)
      if (lo.lt.0) go to 228
      if (intp(lo).gt.0) go to 227
229   if (nix.eq.1) go to 226
      nix=1
      iodd=mw
      go to 227
228   if (intn(-lo).eq.0) go to 229
227   continue
      if (iodd.eq.1) go to 230
      kx=1
      ky=iodd-1
      ink=ini
233   do 231 mw=kx,ky
      ink=ink+1
      lx=imat(ink)
      if (lx.lt.0) go to 232
      lo=intp(lx)
      go to 234
232   lo=intn(-lx)
234   if(lo.eq.mw) go to 231
      ix=inj+lo
      iy=inj+mw
      ni=jmat(iy)
      jmat(ix)=ni
      jmat(iy)=lx
      jrm(kw)=-jrm(kw)
      if (lx.lt.0) go to 235
      intp(lx)=mw
      go to 236
235   intn(-lx)=mw
236   if (ni.lt.0) go to 237
      intp(ni)=lo
      go to 231
237   intn(-ni)=lo
231   continue
      if (ky.gt.mu) go to 238
230   kx=iodd+1
      ky=m
      ink=ini+iodd
      go to 233
238   vm=orb*fj(iny)
      if (irm(iny).ne.jrm(kw)) vm=-vm
      ink=iodd+ini
      ia=imat(ink)
      ink=iodd+inj
      ib=jmat(ink)
      if (ia.gt.0) go to 240
      ia=-ia
      ib=-ib
240   ia = min(ia,ib) + iky(max(ia,ib))
      q(ia)=q(ia)+vm
226   continue
222   continue
127   continue
122   continue
      go to 133
121   read(lun01,err=8620,end=8613)
 133  read(lun01,err=8620,end=8613)
 103  nx=0
      ini=-idel
      inis=-nd
      in2=-kml
      do 134 l=1,jmax
      in2=in2+kml
      inis=inis+nd
      ini=ini+idel
      call setsto(imo,0,jcon)
      if(nod.eq.0) go to 840
      do 141 ll=1,nod
      nx=nx+1
      nt=ikan(nx)
 141  jcon(nt)=1
      if(ndb.eq.0) go to 142
 840  do 143 ll=1,ndb
      nx=nx+1
      nt=ikan(nx)
 143  jcon(nt)=2
 142  nx=nx-nl
      orb=h(l)
      if(nod.eq.0) go to 135
      do 136 ll=1,nod
      nx=nx+1
      nt=ikan(nx)+1
      idx=iky(nt)
 136  q(idx)=q(idx)+orb
      if(ndb.eq.0) go to 137
 135  orb=orb+orb
      do 138 ll=1,ndb
      nx=nx+1
      nt=ikan(nx)+1
      idx=iky(nt)
 138  q(idx)=q(idx)+orb
 137  if(l.eq.1) go to 134
      l1=l-1
      inj=-idel-m
      injs=-nd
      nxj=0
      do 139 ll=1,l1
      inj=inj+idel
      injs=injs+nd
      do 243 kw=1,nl
      nxj=nxj+1
 243  ktest(kw)=ikan(nxj)
      nix=0
      if(nod.eq.0) go to 244
      do 245 kw=1,nod
      jt=ktest(kw)
      if(jcon(jt).gt.0) go to 245
      if(nix.eq.1) go to 139
      nix=1
 245  continue
      if(ndb.eq.0) go to 246
 244  kk=nod
      do 247 kw=1,ndb
      kk=kk+1
      jt=ktest(kk)
      jc=jcon(jt)
      if(jc.eq.2) go to 247
      if(jc.eq.0.or.nix.eq.1) go to 139
      nix=1
 247  continue
 246  ink=in2
      do 248 kw=1,kml
      ihq=ihog(kw)
      ink=ink+1
      orb=gj(ink)
      in3=(ihq-1)*m+ini
      in7=ihq+inis
      do 249 lw=1,imo
      intp(lw)=0
 249  intn(lw)=0
      in8=in3
      do 250 lw=1,m
      in8=in8+1
      lx=imat(in8)
      if(lx.lt.0) go to 251
      intp(lx)=lw
      go to 250
 251  intn(-lx)=lw
 250  continue
      in4=inj
      in6=injs
      do 252 lw=1,nd
      in4=in4+m
      in5=in4
      nix=0
      in6=in6+1
      do 253 mw=1,m
      in5=in5+1
      lo=imat(in5)
      if(lo.lt.0) go to 254
      if(intp(lo).gt.0) go to 253
 255  if(nix.eq.1) go to 252
      nix=1
      iodd=mw
      go to 253
 254  if(intn(-lo).eq.0) go to 255
 253  continue
      if(iodd.eq.1) go to 256
      kx=1
      ky=iodd-1
      in5=in4
 257  do 258 mw=kx,ky
      in5=in5+1
      lx=imat(in5)
      if(lx.lt.0) go to 259
      lo=intp(lx)
      go to 260
 259  lo=intn(-lx)
 260  if(lo.eq.mw) go to 258
      ix=in3+lo
      iy=in3+mw
      ni=imat(iy)
      imat(ix)=ni
      imat(iy)=lx
      irm(in7)=-irm(in7)
      if(lx.lt.0) go to 261
      intp(lx)=mw
      go to 262
 261  intn(-lx)=mw
 262  if(ni.lt.0) go to 263
      intp(ni)=lo
      go to 258
 263  intn(-ni)=lo
 258  continue
      if(ky.gt.mu) go to 264
 256  kx=iodd+1
      ky=m
      in5=in4+iodd
      go to 257
 264  vm=orb*fj(in6)
      if(irm(in6).ne.irm(in7)) vm=-vm
      ia=iodd+in4
      ia=imat(ia)
      ib=iodd+in3
      ib=imat(ib)
      if(ia.gt.0) go to 265
      ia=-ia
      ib=-ib
 265  ia=min(ia,ib)+iky(max(ia,ib))
      q(ia)=q(ia)+vm
 252  continue
 248  continue
 139  continue
 134  continue
 100  continue
 43   continue
      return
 8620 call caserr('error on reading ci scratch file')
 8613 call caserr('unexpected end of ci vector file')
      return
      end
_ENDEXTRACT
      subroutine putqnon(q,etot,tbas,mpos,mtype)
      implicit REAL  (a-h,o-z), integer (i-n)
      character *(*) tbas
      character *8 text,type,title,com
      logical otran,otri,otrann
INCLUDE(common/sizes)
      common/tran/ilifc(maxorb),ntran(maxorb),itran(mxorb3),
     * ctran(mxorb3),otran,otri
INCLUDE(common/discc)
      common/blkorbs/value(maxorb),occ(maxorb+1),
     * nbasis,newbas,ncol,ivalue,iocc,ipad
INCLUDE(common/iofile)
INCLUDE(common/jinfo)
      common/junkc/com(19),title(10)
INCLUDE(common/runlab)
INCLUDE(common/machin)
      dimension q(*),type(2)
      data text/' mrd-ci'/
      data type/'no-sabf','no-aos'/
      data m29/29/
c
      otrann = otran
      if (mtype.eq.2) then
c     nos written to dumpfile in ao basis with otran .true.
       otran=.true.
      else
c     nos written in sabf with otran .false
       otran=.false.
      endif
c
      if(mpos.gt.350)call caserr(
     * 'invalid section specified for natural orbital output')
       if(ncol.ne.newbas) then
c     clear non-existent vectors and populations and make 
c     eigenvalues large
        call vclr(q(ncol*newbas+1),1,(newbas-ncol)*newbas)
        do i=ncol+1,newbas
           value(i) = 9999900.0d0 + dfloat(i)*0.1d0
           occ(i) = 0.0d0
        enddo
      endif
      nbsq=newbas*newbas
      j=1+lensec(mach(8))+lensec(mach(9))+lensec(nbsq)
      call secput(mpos,3,j,iblk)
      do 20 i=1,10
 20   title(i)=ztitle(i)
      write(iwr,1)text,tbas,mpos,ibl3d,yed(idaf)
 1    format(//a7,
     *' natural orbitals ( ',a4,' basis) stored in section',i4,
     *' of dumpfile starting at block',i6,
     *' of ',a4)
      occ(maxorb+1)=etot
      com(1)=zanam
      com(2)=zdate
      com(3)=ztime
      com(4)=text(2:7)
      com(5)=type(mtype)
      call wrtc(com,m29,iblk,idaf)
      call wrt3s(value,mach(8),idaf)
      nav = lenwrd()
      call wrt3is(ilifc(1),mach(9)*nav,idaf)
      call wrt3s(q,nbsq,idaf)
      call clredx
      call revind
c
      otran = otrann
c
      return
      end
c ******************************************************
c    =   Table-ci (conversion module for adapt =
c ******************************************************
c ******************************************************
      subroutine cmrdci(x,odebug)
      implicit REAL  (a-h,o-z), integer (i-n)
      logical odebug
      character *4 fdump
INCLUDE(common/sizes)
      common /blkin/ pp(4),y(507)
INCLUDE(common/prints)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/ftape)
INCLUDE(common/discc)
      common /linkmr/ imap(maxorb+maxorb),ipr,lbuff,igame
INCLUDE(common/infoa)
      common/lsort /atomo(4,maxat),poto,nnsho(maxat)
      common/bnew/sum(2),itape(2),ntape,mtape,ltape,mscr
INCLUDE(common/files)
INCLUDE(common/restar)
INCLUDE(common/filel)
      common/restri/nfils(63),lds(508),isect(508),ldsect(508)
      logical oop29, oop31, oop32
      dimension iq(6),x(*)
c
      data fdump/'dump'/
      data m1,m2,m511/1,2,511/
c
      if (nat.eq.1)  then
       write(iwr,'(a)') ' '
       write(iwr,'(a)') ' *********************************************'
       write(iwr,'(a)') ' ** There is only one nucleus               **'
       write(iwr,'(a)') ' ** The one-electron integral adaption is   **'
       write(iwr,'(a)') ' ** not properly implemented for this case  **'
       write(iwr,'(a)') ' ** To use tm/natorb place a He at infinity **'
       write(iwr,'(a)') ' ** (and freeze it in the MRDCI of course)  **'
       write(iwr,'(a)') ' **            J.H. van Lenthe (2003)       **'
       write(iwr,'(a)') ' *********************************************'
       write(iwr,'(a)') ' '
       call caserr('CI properties not available in atomic jobs')
      end if
      igame = 1
      isec3 = 482
      oop29 = oprint(29)
      oop31 = oprint(31)
      oop32 = oprint(32)
      if (odebug) then
       oprint(29) = .false.
       oprint(31) = .true.
       oprint(32) = .true.
      else
       oprint(29) = .true.
       oprint(31) = .false.
       oprint(32) = .false.
      endif
      if(.not.oprint(29)) write(iwr,35)
      if(isec3.gt.350.and.isec3.ne.482)call caserr(
     *'invalid section specified for 1-electron integrals')
      if(isec3.ne.0)ions2=isec3
      if(.not.oprint(29)) then
        write(iwr,3)fdump,yed(idaf),ibl3d
        write(iwr,105)
      endif
c        1st tackle the dfile
      call secget(isect(491),m1,iblkv)
c
c ----- decide if this section has originated from an
c       gamess run - modified for arbitrary mxprim
c
      call search(iblkv,idaf)
      nblk1 = lensec(mxprim) - 1
      nw1 = mxprim - nblk1 * 511
      if (nblk1. gt. 0) then
       do 3000 loop = 1, nblk1
       call find(idaf)
       call get(pp(1),nw)
 3000  continue
      endif
      call find(idaf)
      call get(pp(1),nw)
      call cgamrd(iblkv)
c
c          restore potnuc
c
      call secget(ionsec,m2,iblk33)
      call rdedx(pp,m511,iblk33,idaf)
      poto=pp(1)
c
      call rewftn(nf2)
      lenbas=num*(num+1)/2
      iq(1)=1
      do 26 i=2,4
 26   iq(i)=iq(i-1)+lenbas
      iq(5) = iq(4) + lenbas
      iq(6) = iq(5) + maxorb * mxprms
      last =  iq(6) + maxorb * mxprms
c     memory for cface1
      last2 = 7 * nat + 3 * mxgaus  + 5 * num
      if (odebug) write(6,*) 'last, last2 = ', last, last2
      maxl = max(last,last2)
c
      iq(1) = igmem_alloc(maxl)
      do i=2,4
       iq(i)=iq(i-1)+lenbas
      enddo
      iq(5) = iq(4) + lenbas
      iq(6) = iq(5) + maxorb * mxprms
      last =  iq(6) + maxorb * mxprms
c
      call cface1(x(iq(1)),maxl,iwr)
      call cmrdm(x(iq(1)),x(iq(2)),x(iq(3)),
     +           x(iq(4)),
     +           x(iq(5)),x(iq(6)),odebug)
c     now rewind data sets (Pentium problem)
      call rewftn(ntape)
      call rewftn(mtape)
      if (ltape.ne.ntape) then
       call rewftn(ltape)
      endif
      call rewftn(mscr)
c
      call gmem_free(iq(1))
c
c     now for transformation interface
c
      call cmrdci2(x,odebug)
c
      oprint(29) = oop29
      oprint(31) = oop31
      oprint(32) = oop32
      return
 105  format(/' *** no sabf routing specified'/)
 3    format(/1x,a4,'file on ',a4,' at block',i6 )
 35   format(//1x,104('=')//
     + 40x,'*******************************'/
     * 40x,'Table-Ci  --  symmetry adaption'/
     + 40x,'*******************************'/)
      end
      subroutine cgamrd(iblkv)
      implicit REAL  (a-h,o-z),integer (i-n)
      character *8 title,tagg
c
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
      common/junk/ishp(mxgaus),ityp(mxgaus),igp(mxgaus),exxp(2,mxgaus)
      common/lsort/atomo(4,maxat),poto,nsho(maxat)
      common/junkc/title(10),tagg(maxat)
      common/blkin/h(2)
      common/scra/ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     * cf(mxprim),cg(mxprim),z(maxat),
     * kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     * kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell,non,norb,nspace
      common/linkmr/new(maxorb),newei(maxorb),iprim,lbuff,igame
INCLUDE(common/machin)
      common/restri/nfils(63),lds(508),isect(508),ldsect(508)
      data m15/15/
c
      if(oprint(31))write(iwr,1)
 1    format(
     *' section 191 created by gamess program *****'/)
      igame=1
      m110=10+maxat
      m1420=mxprim*5+maxat
      call rdedx(ex,mxprim,iblkv,idaf)
      call reads(cs,m1420,idaf)
      call rdchrs(title,m110,idaf)
      nav = lenwrd()
      call readis(kstart,mach(2)*nav,idaf)
c
      if(non.le.0.or.non.gt.maxat)go to 1000
      if(nshell.le.0.or.nshell.gt.mxshel)go to 1000
      if(norb.gt.0.and.norb.le.maxorb)go to 1010
 1000 call caserr(
     *'parameter error detected in adapt pre-processor')
 1010 nat=non
      mach4 = 12*nat + 3 + 4/lenwrd()
      call secget(isect(493),m15,iblkv)
      call rdedx(h,mach4,iblkv,idaf)
c
      itemp = 9*nat + 1
      do 20 i=1,non
      atomo(1,i)=z(i)
      atomo(2,i)=h(itemp )
      atomo(3,i)=h(itemp + 1)
      atomo(4,i)=h(itemp + 2)
      nsho(i)=0
 20   itemp = itemp + 3
c
      iprim=0
      num=0
      ishell=0
c
      do 22 iat=1,non
      do 23 ii=1,nshell
      i=katom(ii)
      if(i.ne.iat)go to 23
      is=kstart(ii)
      ipri=kng(ii)
      if=is+ipri-1
      mini=kmin(ii)
      maxi=kmax(ii)
      kk=kloc(ii)-mini
c
      do 25 iorb=mini,maxi
      li=kk+iorb
      num=num+1
      new(num)=li
 25   newei(li)=num
c
      ishell=ishell+1
      j=maxi-mini
      if(j.eq.0)go to 26
      if(j-3)27,26,28
c ----- s
 26   m=1
      do 2008 ig=is,if
      iprim=iprim+1
      ishp(iprim)=ishell
      ityp(iprim)=m
      igp(iprim)=iprim
      exxp(1,iprim)=ex(ig)
 2008 exxp(2,iprim)=cs(ig)
      if(j.eq.0)go to 24
c ----- sp
      ishell=ishell+1
      nsho(iat)=nsho(iat)+1
c ----- p
 27   m=2
      do 2009 ig=is,if
      iprim=iprim+1
      ishp(iprim)=ishell
      ityp(iprim)=m
      igp(iprim)=iprim
      exxp(1,iprim)=ex(ig)
 2009 exxp(2,iprim)=cp(ig)
      go to 24
c ----- d, f and g
 28   if(j.eq.5) then
      m=3
      do 2010 ig=is,if
      iprim=iprim+1
      ishp(iprim)=ishell
      ityp(iprim)=m
      igp(iprim)=iprim
      exxp(1,iprim)=ex(ig)
 2010 exxp(2,iprim)=cd(ig)
c
      else if(j.eq.9) then
c
      m=4
      do 2011 ig=is,if
      iprim=iprim+1
      ishp(iprim)=ishell
      ityp(iprim)=m
      igp(iprim)=iprim
      exxp(1,iprim)=ex(ig)
 2011 exxp(2,iprim)=cf(ig)
      else
c     g functions
      m = 5
      do 2012 ig=is,if
      iprim=iprim+1
      ishp(iprim)=ishell
      ityp(iprim)=m
      igp(iprim)=iprim
      exxp(1,iprim)=ex(ig)
 2012 exxp(2,iprim)=cg(ig)
c
      endif
c
 24   nsho(iat)=nsho(iat)+1
      if(iprim.gt.mxgaus)go to 1000
 23   continue
 22   continue
c
      if(ishell.le.0.or.ishell.gt.mxgrps)go to 1000
      if(num.ne.norb)go to 1000
      return
      end
      subroutine cmrdm(sm,hm,sa,ha,bbuff,cbbuff,odebug)
      implicit REAL (a-h,o-z), integer (i-n)
      logical odebug
      character *1 dash
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/mapper)
      common/aplus/g(900),p(751),v(maxorb),
     + nir(maxorb),loc(maxorb),ncomp(maxorb),jdeks(maxorb),
     + kdeks(maxorb),lsym(maxorb*8),
     + mj(8),nj(8),ntil(8),nbal(9),irper(8),
     + ircor(8),mtil(4),mbal(4),inper(8),mver(4),
     + mvom(4),npal(8),ij(8),mvil(4)
      common/junk/ixa(3400),bb(10*maxorb),cbb(10*maxorb),
     + x(maxorb),y(maxorb),q(maxorb),
     + nnum(maxorb),i2(maxorb),i3(maxorb),i4(maxorb),
     + nord(maxat),ilife(maxorb),
     + nco(100),nrw(100),ityp(maxorb),icon(maxorb),
     + iord(maxat),ncont(maxat)
      common/lsort /natt(maxat),ise(7),ip(7*maxat),ibas(maxat),
     + npf(7),npz(7),nel(3),nbon(maxat),
     + nfun(3*maxorb),npar(3*maxorb),mpar(3*maxorb)
      common/scra/sexp(1000),coe(1000),
     + cm(maxat),cx(maxat),cy(maxat),cz(maxat),
     + z(maxat),xx(maxat),yy(maxat),zz(maxat),
     + mcomp(maxorb),ksym(8*maxorb),nfil(maxorb),
     + imix(3),ibuk(3),inuk(3),nzer(8),nblz(8),ncal(8),
     + nzil(8),nsog(maxorb),msym(8*maxorb),kcomp(maxorb),
     + nwil(8),ngal(8),kj(8)
INCLUDE(common/iofile)
INCLUDE(common/ftape)
      common/bnew/sum,gg,itape,jtape,ntape,mtape,ltape,mscr,nrac,nrecy,
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,is,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc
INCLUDE(common/blockc)
      common/linkmr/neway(maxorb),newya(maxorb)
      REAL guf
      common/miscop/guf(mxcrec)
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      dimension h(ndime)
      dimension sm(*),hm(*),sa(*),ha(*)
      dimension bbuff(*),cbbuff(*)
      dimension c(4*maxat)
      equivalence (bb(1),h(1)),(c(1),cm(1))
c
      data dash/'-'/
      jtape=iwr
      mx2550 = 10 * maxorb
      itape=ird
      ntape=nf2
      ltape=nf22
      ipup=ltape
      mscr=nf1
      mtape=nf3
      jpup=mtape
c
      call rewftn(ltape)
      call rewftn(mscr)
      call rewftn(mtape)
c
      nrac=10
      cpu=cpulft(1)
      if(.not.oprint(29)) write(jtape,8999)cpu
 8999 format(/' commence symmetry adaption at ',f8.2,
     *' secs.')
      norb=maxorb
c     namx=100
      namx=maxat
      nsmx=7*maxat
c     nsmx=700
      ifrk=500
      ifrk1=ifrk+1
      if2=1000
      ik = 0
      irs = 0
c
      read(ntape) natoms,nbas,nhfunc,(iord(i),i=1,
     1 nhfunc),repel,newya
      if (oprint(32)) then
       write(iwr,*)' ntape = ', ntape
       write(iwr,*)' ltape = ', ltape
       write(iwr,*)' mtape = ', mtape
       write(iwr,*)' natoms = ', natoms
       write(iwr,*)' nbas = ', nbas
       write(iwr,*)' nhfunc = ', nhfunc
       write(iwr,*)' iord = ', (iord(i),i=1,nhfunc)
       write(iwr,*)' repel = ', repel
       write(iwr,*)' newya = ', newya
      endif
      read(ntape) (iord(i),i=1,natoms),
     1(z(i),i=1,natoms),(xx(i),i=1,natoms),(yy(i),i=1,natoms),
     2(zz(i),i=1,natoms)
      if (oprint(32)) then
       write(iwr,*)' iord  = ', (iord(i),i=1,natoms)
       write(iwr,*)' z     = ', (z(i),i=1,natoms)
       write(iwr,*)' xx    = ', (xx(i),i=1,natoms)
       write(iwr,*)' yy    = ', (yy(i),i=1,natoms)
       write(iwr,*)' zz    = ', (zz(i),i=1,natoms)
      endif
      nc2=2*natoms*(natoms-1)
      nc3=nc2*(natoms-2)/2
      nrec2=nc3*(natoms-3)/8+nc3+nc2+natoms
      nbasr=2
      i1=0
      i7=0
      do 110 i=1,nbas
      read(ntape)nraw,ncon
      nbasr=nbasr+1
      if(nraw.eq.0.or.ncon.eq.0)go to 111
      read(ntape)(sexp(i1+j),j=1,nraw),(coe(i1+j),j=1,nraw),
     1 (ityp(i7+j),j=1,ncon),(icon(i7+j),j=1,ncon)
       if(oprint(32)) then
       write(iwr,*) 'exp = ', (sexp(i1+j),j=1,nraw)
       write(iwr,*) 'coe = ', (coe(i1+j),j=1,nraw)
       write(iwr,*) 'ityp = ', (ityp(i7+j),j=1,ncon)
       write(iwr,*) 'icon = ', (icon(i7+j),j=1,ncon)
       endif
      do j = i7+1, i7+ncon
        if (icon(j).gt.mxprms) then
          write(*,*)'*** nbas   = ',nbas
          write(*,*)'*** icon   = ',(icon(k),k=1,i7+ncon)
          write(*,*)'*** mxprms = ',mxprms
          write(*,*)'*** The number of primitive functions in the '
          write(*,*)'*** contraction <icon> exceeds parameter <mxprms>'
          call caserr(
     $       "Number of prim. functions <icon> exceeds <mxprms>")
        endif
      enddo
      nbasr=nbasr+1
 111  nco(i)=ncon
      nrw(i)=nraw
      i1=i1+nraw
      i7=i7+ncon
 110  continue
      iorbs=0
      do 114 k=1,natoms
      ncc=iord(k)
      iorbs=iorbs+nco(ncc)
      ncont(k)=nco(ncc)
 114  continue
      do 832 i=1,natoms
      natt(i)=0
      chg=z(i)
      ns1=ncont(i)
      if(dabs(chg).gt.1.0d-5)go to 831
      if(ns1.eq.0)natt(i)=3
      if(ns1.ne.0)natt(i)=1
      go to 832
 831  if(ns1.eq.0)natt(i)=2
 832  continue
      if(iorbs.gt.norb) call caserr(
     *'internal orbital count corrupted .. call for help .. 279')
      do 73 i=1,nbas
  73  nord(i)=0
      do 72 i=1,natoms
      isal=iord(i)
  72  nord(isal)=nord(isal)+1
      iexp=0
      ican=0
      ibat=0
      do 80 i=1,nbas
      isal=nord(i)
      ncw=nco(i)
      if(ncw.eq.0)go to 80
      do 82 j=1,ncw
      ican=ican+1
      ithn=icon(ican)
      ittp=ityp(ican)
      ibat=ibat+1
      nyx=nix(ittp)
      nyy=niy(ittp)
      nyz=niz(ittp)
      do 71 k=1,ithn
      iexp=iexp+1
      coff=coe(iexp)
      expf=sexp(iexp)
      jbat=ibat-ncw
      do 71 l=1,isal
      jbat=jbat+ncw
      jbati = (jbat-1)*mxprms + k
      bbuff(jbati)=expf
  71  cbbuff(jbati)=coff
      jbat=ibat-ncw
      do 82 k=1,isal
      jbat=jbat+ncw
      nnum(jbat)=ithn
      i2(jbat)=nyx
      i3(jbat)=nyy
  82  i4(jbat)=nyz
      ibat=jbat
 80   continue
c
c     ilife indexing array for bb and cbb
c
      jbat = 0
      do 770 i=1,iorbs
      ilife(i)=jbat
      jbat=jbat + nnum(i)
770   continue
      if(jbat.gt.mx2550) then
       call caserr('dimensioning problem in cmrdm')
      endif
      kkk=0
      do 771 i=1,iorbs
      jbat=ilife(i)
      isal=(i-1)*mxprms
      jk=nnum(i)
      do 772 j=1,jk
      jbat = jbat + 1
      bb(jbat) = bbuff(isal+j)
      cbb(jbat) = cbbuff(isal+j)
772   continue
771   continue
c     
      jbat=0
      do 83 i=1,nbas
      isal=nord(i)
      ncv=nco(i)
      if(ncv.eq.0)go to 83
      jk=0
      do 408 k=1,natoms
      jp=iord(k)
      if (jp.ne.i) go to 408
      xt=xx(k)
      yt=yy(k)
      zt=zz(k)
      do 406 j=1,ncv
      jbat=jbat+1
      x(jbat)=xt
      y(jbat)=yt
 406  q(jbat)=zt
      jk=jk+1
      if (jk.eq.isal) go to 83
 408  continue
      call caserr(
     *'internal orbital count corrupted .. call for help .. 280')
  83  continue
      do 21 i=1,nbas
 21      ibas(i)=0
         ibs=0
         do 22 i=1,natoms
         k=iord(i)
         kkk=natt(i)
         if(kkk-1)22,2040,2041
2040     ibs=1
         go to 2042
2041     ibs=2
2042     ibas(k)=kkk
 22     continue
      do 7i=1,nsmx
7     ip(i)=0
      icx=-namx
      do 3 i=1,7
      icx=icx+namx
      ix=isx(i)
      iy=isy(i)
      iz=isz(i)
      do 9 j=1,nbas
      if (ibas(j).ne.0) go to 9
      isal=nord(j)
      isl=0
      idx=icx
      do 8 k=1,natoms
      idx=idx+1
      if(natt(k).ne.0.or.ip(idx).ne.0) go to 8
      if (iord(k).ne.j) go to 8
      nfl=0
      if (ix.eq.0) go to 10
      if (dabs(xx(k)).lt.1.0d-4) go to 11
      gx=-xx(k)
      nfl=1
      go to 12
11    gx=0.0d0
      go to 12
10    gx=xx(k)
12    if (iy.eq.0) go to 13
      if (dabs(yy(k)).lt.1.0d-4) go to 14
      gy=-yy(k)
      nfl=1
      go to 15
14    gy=0.0d0
      go to 15
13    gy=yy(k)
15    if(iz.eq.0) go to 16
      if (dabs(zz(k)).lt.1.0d-4) go to 17
      gz=-zz(k)
      nfl=1
      go to 18
17    gz=0.0d0
      go to 18
16    gz=zz(k)
18    if (nfl.eq.1) go to 19
      ip(idx)=k
      isl=isl+1
      if(isl.eq.isal) go to 9
      go to 8
19    k1=k+1
      if (k1.gt.natoms) go to 36
      iex=idx
      do 20 l=k1,natoms
      iex=iex+1
      if (natt(l).ne.0.or.ip(iex).ne.0) go to 20
      if (iord(l).ne.j) go to 20
      if (dabs(gx-xx(l)).gt.1.0d-4) go to 20
      if (dabs(gy-yy(l)).gt.1.0d-4) go to 20
      if (dabs(gz-zz(l)).gt.1.0d-4) go to 20
      ip(idx)=l
      ip(iex)=k
      isl=isl+2
      if(isl.eq.isal) go to 9
      go to 8
20    continue
36    ise(i)=0
      go to 3
8     continue
9     continue
      if(ibs.eq.0) go to 23
      do 24 j=1,nbas
      if (ibas(j).ne.1) go to 24
      isal=nord(j)
      isl=0
      idx=icx
      do 25 k=1,natoms
      idx=idx+1
      if (natt(k).ne.1.or.ip(idx).ne.0) go to 25
      if (iord(k).ne.j) go to 25
      nfl=0
      if (ix.eq.0) go to 26
      if (dabs(xx(k)).lt.1.0d-4) go to 27
      gx=-xx(k)
      nfl=1
      go to 28
27    gx=0.0d0
      go to 28
26    gx=xx(k)
28    if(iy.eq.0) go to 29
      if (dabs(yy(k)).lt.1.0d-4) go to 30
      gy=-yy(k)
      nfl=1
      go to 31
30    gy=0.0d0
      go to 31
29    gy=yy(k)
31    if(iz.eq.0) go to 6
      if(dabs(zz(k)).lt.1.0d-4) go to 32
      gz=-zz(k)
      nfl=1
      go to 33
32    gz=0.0d0
      go to 33
6     gz=zz(k)
33    if(nfl.eq.1) go to 34
      ip(idx)=k
      isl=isl+1
      if(isl.eq.isal) go to 24
      go to 25
34    k1=k+1
      if(k1.gt.natoms) go to 37
      iex=idx
      do 35 l=k1,natoms
      iex=iex+1
      if(natt(l).ne.1.or.ip(iex).ne.0) go to 35
      if (iord(l).ne.j) go to 35
      if(dabs(gx-xx(l)).gt.1.0d-4) go to 35
      if (dabs(gy-yy(l)).gt.1.0d-4) go to 35
      if (dabs(gz-zz(l)).gt.1.0d-4) go to 35
      ip(idx)=l
      ip(iex)=k
      isl=isl+2
      if(isl.eq.isal) go to 24
      go to 25
35    continue
37    ise(i)=0
      go to 3
25    continue
24    continue
      do 700 j=1,nbas
      if (ibas(j).ne.2) go to 700
      isal=nord(j)
      isl=0
      idx=icx
      do 701 k=1,natoms
      idx=idx+1
      if (natt(k).ne.2.or.ip(idx).ne.0) go to 701
      if (iord(k).ne.j) go to 701
      nfl=0
      if (ix.eq.0) go to 702
      if (dabs(xx(k)).lt.1.0d-4) go to 703
      gx=-xx(k)
      nfl=1
      go to 704
703   gx=0.0d0
      go to 704
702   gx=xx(k)
704   if(iy.eq.0) go to 705
      if (dabs(yy(k)).lt.1.0d-4) go to 706
      gy=-yy(k)
      nfl=1
      go to 707
706   gy=0.0d0
      go to 707
705   gy=yy(k)
707   if(iz.eq.0) go to 708
      if(dabs(zz(k)).lt.1.0d-4) go to 709
      gz=-zz(k)
      nfl=1
      go to 710
709   gz=0.0d0
      go to 710
708   gz=zz(k)
710   if(nfl.eq.1) go to 711
      ip(idx)=k
      isl=isl+1
      if(isl.eq.isal) go to 700
      go to 701
711   k1=k+1
      if(k1.gt.natoms) go to 712
      iex=idx
      do 713 l=k1,natoms
      iex=iex+1
      if(natt(l).ne.2.or.ip(iex).ne.0) go to 713
      if (iord(l).ne.j) go to 713
      if (dabs(gx-xx(l)).gt.1.0d-4) go to 713
      if (dabs(gy-yy(l)).gt.1.0d-4) go to 713
      if (dabs(gz-zz(l)).gt.1.0d-4) go to 713
      ip(idx)=l
      ip(iex)=k
      isl=isl+2
      if(isl.eq.isal) go to 700
      go to 701
713   continue
712   continue
      call caserr(
     *'internal orbital count corrupted .. call for help .. 281')
701   continue
700   continue
23    ise(i)=1
3     continue
      icx=-namx
      ix=0
      do 38 i=1,7
      icx=icx+namx
      if (ise(i).eq.0) go to 38
      iy=0
      ix=ix+1
      idx=icx
      do 39 j=1,natoms
      idx=idx+1
      if (ip(idx).eq.j) go to 39
      iy=iy+ncont(j)
39    continue
      npf(i)=iy
38    continue
      isymx=ix
      if (ix.gt.0 .and. natoms.ne.1 ) go to 40
      if(.not.oprint(29)) write(jtape,41)
 41   format(/1x,74('=')/1x,
     *'no symmetry elements have been recognized in the current ',
     1'coordinate system' /1x,74('=')/)
      isymx=0
      ix = 0
      nsel=1
      nj(1)=iorbs
      nbal(1)=0
      ntil(1)=0
      do 4000 i=1,iorbs
      ncomp(i)=1
 4000 lsym(i)=i
      jsym(1)=1
      knu=0
      do 4001 i=1,natoms
      knu=knu+1
      cm(knu)=z(i)
      cx(knu)=xx(i)
      cy(knu)=yy(i)
 4001 cz(knu)=zz(i)
      write(ltape)natoms,nbas,nhfunc,
     *(iord(i),i=1,nhfunc),repel,newya
      write(ltape)nsel,nj,iorbs,knu,c,jsym
      write(ltape)lsym,ncomp,ntil,nbal
      do 4005 i=1,natoms
 4005 nord(i)=iord(i)
      write(ltape)repel,h
      go to 4002
c
 40   if (ix.eq.1) jx=1
      if (ix.eq.3) jx=2
      if (ix.eq.7) jx=3
      nsel=ix+1
      kx=0
      do 43 i=1,7
43    npz(i)=0
      do 45 j=1,jx
      lx=10000
      do 44 i=1,7
      if (ise(i).eq.0) go to 44
      if (npz(i).eq.1) go to 44
      nf=npf(i)
      if (nf.ge.lx) go to 44
      lx=nf
      ji=i
      if (nf.eq.0) go to 46
44    continue
      npz(ji)=1
      nel(j)=ji
      go to 45
46    kx=kx+1
      npz(ji)=1
      nel(j)=ji
45    continue
      if (jx.lt.3) go to 47
      ia=nel(1)
      ib=nel(2)
      kk=nel(3)
      igx=isx(ia)+isx(ib)+isx(kk)
      if (igx.gt.1) igx=igx-2
      if (igx.ne.0) go to 47
      igx=isy(ia)+isy(ib)+isy(kk)
      if (igx.gt.1) igx=igx-2
      if (igx.ne.0) go to 47
      igx=isz(ia)+isz(ib)+isz(kk)
      if (igx.gt.1) igx=igx-2
      if (igx.ne.0) go to 47
      lx=10000
      if(npf(kk).eq.0) kx=kx-1
      do 48 i=1,7
      if (npz(i).eq.1) go to 48
      nel(3)=i
      go to 49
48    continue
49    if(npf(i).eq.0) kx=kx+1
47    nbon(1)=0
      if (natoms.eq.1) go to 50
      do 51 i=2,natoms
      il=i-1
51    nbon(i)=nbon(il)+ncont(il)
50    icx=-iorbs
      do 52 i=1,jx
      icx=icx+iorbs
      ji=nel(i)
      idx=(ji-1)*namx
      ix=isx(ji)
      iy=isy(ji)
      iz=isz(ji)
      do 53 j=1,natoms
53    ibas(j)=0
      ican=0
      do 54 j=1,nbas
      isal=nord(j)
      ncw=nco(j)
      if(ncw.eq.0)go to 54
      icbn=ican
      ist=0
      do 55 k=1,natoms
      if (iord(k).ne.j) go to 55
      if(ibas(k).ne.0) goto 55
      ipx=idx+k
      ipx=ip(ipx)
      ka=nbon(k)
       nb=ka+icx
      ican=icbn
      if (ipx.ne.k) go to 56
      ist=ist+1
      do 57 l=1,ncw
      ican=ican+1
      nb=nb+1
         ka=ka+1
      ittp=ityp(ican)
      isum=0
      if (ix.eq.1) isum=isum+nix(ittp)
      if (iy.eq.1) isum=isum+niy(ittp)
      if (iz.eq.1) isum=isum+niz(ittp)
      if (isum-(isum/2)*2.eq.0) go to 58
      nfun(nb)=-ka
      npar(nb)=1
      go to 57
58    nfun(nb)=ka
      npar(nb)=0
57    continue
      if (ist.eq.isal) go to 54
      go to 55
 56       im=nbon(ipx)
      mb=im+icx
      ibas(ipx)=1
      ist=ist+2
      do 59 l=1,ncw
      nb=nb+1
       ka=ka+1
       im=im+1
      mb=mb+1
      npar(nb)=-1
      npar(mb)=-1
      ican=ican+1
      ittp=ityp(ican)
      isum=0
      if(ix.eq.1) isum=isum+nix(ittp)
      if (iy.eq.1) isum=isum+niy(ittp)
      if(iz.eq.1) isum=isum+niz(ittp)
      if (isum-(isum/2)*2.eq.0) go to 74
      nfun(nb)=-im
      nfun(mb)=-ka
      go to 59
74    nfun(nb)=im
      nfun(mb)=ka
59    continue
      if (ist.eq.isal) go to 54
55    continue
54    continue
52    continue
      if (kx.eq.jx) go to 84
      ix=0
      iy=0
      lx=0
      do 60 i=1,iorbs
60    nfil(i)=0
      ly=-iorbs
      do 61 i=1,iorbs
      ly=ly+1
      if(nfil(i).ne.0) go to 61
      my=ly
      do 62 j=1,jx
      my=my+iorbs
62    imix(j)=npar(my)
      iz=0
      jz=0
      do 63 j=1,jx
      if (imix(j).ge.0) go to 64
      iz=iz+1
      ibuk(iz)=j
      go to 63
64    jz=jz+1
      inuk(jz)=j
63    continue
      if (iz.gt.0) go to 65
      lx=lx+1
      mcomp(lx)=1
      ix=ix+1
      ksym(ix)=i
      do 75 j=1,jx
      iy=iy+1
75    mpar(iy)=imix(j)
      go to 61
65    ih=ix
      ix=ix+1
      ksym(ix)=i
      k=ibuk(1)
      ig=iorbs*(k-1)+i
      ix=ix+1
      mq=nfun(ig)
      ksym(ix)=mq
      if (mq.lt.0) mq=-mq
      nfil(mq)=1
      if (iz.eq.1) go to 66
      jg=iorbs*(ibuk(2)-1)
      ix=ix+1
      mq=nfun(jg+i)
      ksym(ix)=mq
      if (mq.lt.0) mq=-mq
      nfil(mq)=1
      ix=ix+1
      ig=ksym(ih+2)
      if (ig.lt.0) go to 68
      mq=nfun(jg+ig)
      ksym(ix)=mq
      if(mq.lt.0)mq=-mq
      nfil(mq)=1
      go to 69
68    mq=-nfun(jg-ig)
      ksym(ix)=mq
      if (mq.lt.0) mq=-mq
      nfil(mq)=1
69    if (iz.eq.2) go to 67
      jg=iorbs+iorbs
      ix=ix+1
      mq=nfun(jg+i)
      ksym(ix)=mq
      if(mq.lt.0) mq=-mq
      nfil(mq)=1
      do 86 j=1,3
      ix=ix+1
      ig=ksym(ih+j)
      if(ig.lt.0) go to 85
      mq=nfun(jg+ig)
      ksym(ix)=mq
      if(mq.lt.0)mq=-mq
      go to 86
85    mq=-nfun(jg-ig)
      ksym(ix)=mq
      if(mq.lt.0) mq=-mq
86    nfil(mq)=1
      do 91 j=1,8
      lx=lx+1
91    mcomp(lx)=8
      do 92 j=1,24
      iy=iy+1
92    mpar(iy)=irrep(j)
      ix=ix-7
      do 93 j=1,7
      ix=ix+8
93    ksym(ix)=i
      nq=0
      ih=ih+1
      do 94 j=1,7
      ih=ih+1
      mq=ksym(ih)
      kh=ih
      do 94 k=1,7
      nq=nq+1
      kh=kh+8
      if (idh(nq).lt.0) go to 95
      ksym(kh)=mq
      go to 94
95    ksym(kh)=-mq
94    continue
      ix=kh
      go to 61
67    do 96 j=1,4
      lx=lx+1
96    mcomp(lx)=4
      ix=ix-3
      do 97 j=1,3
      ix=ix+4
97    ksym(ix)=i
      nq=0
      ih=ih+1
      do 98 j=1,3
      ih=ih+1
      mq=ksym(ih)
      kh=ih
      do 98 k=1,3
      nq=nq+1
      kh=kh+4
      if (jdh(nq).lt.0) go to 99
      ksym(kh)=mq
      go to 98
99    ksym(kh)=-mq
98    continue
      ix=kh
      if (jz.eq.0) go to 120
      lq=inuk(1)
      mq=imix(lq)
      ky=iy+lq-3
      do 121 j=1,4
      ky=ky+3
121   mpar(ky)=mq
      ky=iy+ibuk(1)
      mpar(ky)=0
      mpar(ky+6)=0
      mpar(ky+3)=1
      mpar(ky+9)=1
      ky=iy+ibuk(2)
      mpar(ky)=0
      mpar(ky+3)=0
      mpar(ky+6)=1
      mpar(ky+9)=1
      iy=iy+12
      go to 61
120   mpar(iy+1)=0
      mpar(iy+2)=0
      mpar(iy+3)=1
      mpar(iy+4)=0
      mpar(iy+5)=0
      mpar(iy+6)=1
      mpar(iy+7)=1
      mpar(iy+8)=1
      iy=iy+8
      go to 61
66    ksym(ix+1)=ksym(ix-1)
      ksym(ix+2)=-ksym(ix)
      ix=ix+2
      do 122 j=1,2
      lx=lx+1
122   mcomp(lx)=2
      if (jz.lt.2) go to 123
      lq=inuk(1)
      mq=imix(lq)
      ky=iy+lq-3
      do 124 j=1,2
      ky=ky+3
124   mpar(ky)=mq
      lq=inuk(2)
      mq=imix(lq)
      ky=iy+lq-3
      do 125 j=1,2
      ky=ky+3
125   mpar(ky)=mq
      lq=ibuk(1)+iy
      mpar(lq)=0
      mpar(lq+3)=1
      iy=iy+6
      go to 61
123   if(jz.eq.0) go to 126
      lq=inuk(1)
      mq=imix(lq)
      ky=iy+lq-2
      do 127 j=1,2
      ky=ky+2
127   mpar(ky)=mq
      lq=ibuk(1)+iy
      mpar(lq)=0
      mpar(lq+2)=1
      iy=iy+4
      go to 61
126   mpar(iy+1)=0
      mpar(iy+2)=1
      iy=iy+2
61    continue
      go to 130
84    do 131 i=1,nsel
131   mj(i)=0
      kx=jx
      ly=-iorbs
      do 132 i=1,iorbs
      ly=ly+1
      my=ly
      isum=1
      ny=1
      do 133 j=1,jx
      my=my+iorbs
      lz=npar(my)
      if (lz.eq.1) isum=isum+ny
133   ny=ny+ny
      nc=mj(isum)+1
      mj(isum)=nc
      nir(i)=isum
132   loc(i)=nc
      nzer(1)=0
      do 134 i=2,nsel
      i9=i-1
134   nzer(i)=nzer(i9)+mj(i9)
      jv=0
      do 145 i=1,nsel
      js=mj(i)
      nj(i)=js
      ntil(i)=jv
      nbal(i)=jv
145   jv=jv+js
      do 135 i=1,iorbs
      ni=nir(i)
      nz=nzer(ni)+1
      nzer(ni)=nz
135   lsym(nz)=i
      do 136 i=1,iorbs
136   ncomp(i)=1
      ix=iorbs
      go to 220
130   do 140 i=1,nsel
140   mj(i)=0
      if (kx.eq.0) go to 141
      ly=-iorbs
      do 142 i=1,iorbs
      ly=ly+1
      my=ly
      isum=1
      ny=1
      do 143 j=1,kx
      my=my+iorbs
      lg=npar(my)
      if (lg.eq.1) isum=isum+ny
143   ny=ny+ny
      nc=mj(isum)+1
      mj(isum)=nc
      nir(i)=isum
142   loc(i)=nc
      ltape=jpup
141   do 144 i=1,nsel
      nj(i)=0
144   nblz(i)=0
      i9=0
      do 146 i=1,iorbs
      ny=1
      isum=1
      do 147 j=1,jx
      i9=i9+1
      if (mpar(i9).eq.1) isum=isum+ny
147   ny=ny+ny
      nsog(i)=isum
      nj(isum)=nj(isum)+1
146   nblz(isum)=nblz(isum)+mcomp(i)
      nzil(1)=0
      ncal(1)=0
      do 148 i=2,nsel
      i9=i-1
      ncal(i)=ncal(i9)+nblz(i9)
148   nzil(i)=nzil(i9)+nj(i9)
      nork=ncal(nsel)+nblz(nsel)
      do 149 i=1,nsel
      ntil(i)=nzil(i)
149   nbal(i)=ncal(i)
      lz=0
      nbal(nsel+1)=nork
      do 150 i=1,iorbs
      isum=nsog(i)
      mc=mcomp(i)
      nz=nzil(isum)+1
      nt=ncal(isum)
      ncomp(nz)=mc
      nzil(isum)=nz
      do 151 j=1,mc
      lz=lz+1
      nt=nt+1
151   lsym(nt)=ksym(lz)
150   ncal(isum)=nt
220   continue
      knu=0
      do 1000 i=1,natoms
        knu=knu+1
      cm(knu)=z(i)
      cx(knu)=xx(i)
      cy(knu)=yy(i)
      cz(knu)=zz(i)
1000  continue
      nb=-1
       if(oprint(32)) then
        write(jtape,*) 'nb, ltape = ', nb, ltape
       endif
      write(ltape)nb,nbas,nhfunc,(iord(i),i=1,nhfunc),repel
     * ,newya
      write(ltape)nsel,mj,nj,iorbs,knu,c,jsym,msym
      write (ltape)nir,loc,lsym,ncomp,ntil,nbal
      do 4006 i=1,natoms
 4006 nord(i)=iord(i)
      write (ltape) repel,h
4002  nrecy=4
      do 9980 ipass=1,3
      nrec1=nbasr
      call cgetshm(sa,ha,natoms,ncont,iky,g,900,ntape,nrec1,jtape)
      iz=0
      ih=0
      ig=0
      do 202 i=1,nsel
      mjx=nj(i)
      if (mjx.eq.0) go to 202
      jz=iz
      mh=ih
      do 203 j=1,mjx
      jz=jz+1
      kz=iz
      mc=ncomp(jz)
      nh=ih
      do 215 k=1,j
      kz=kz+1
      ig=ig+1
      nc=ncomp(kz)
      hum=0.0d0
      sum=0.0d0
      lh=mh
      do 204 jj=1,mc
      lh=lh+1
      md=lsym(lh)
      if (md.lt.0) go to 205
      isig=0
      go to 206
205   md=-md
      isig=1
206   me=iky(md)
      kh=nh
      do 204 kk=1,nc
      kh=kh+1
      nd=lsym(kh)
      if (nd.lt.0) go to 207
      if (nd.gt.md) go to 208
      jg=me+nd
210   sam=sa(jg)
      ham=ha(jg)
      if (isig.eq.0) go to 213
      sam=-sam
      ham=-ham
      go to 213
208   jg=iky(nd)+md
      go to 210
207   nd=-nd
      if (nd.gt.md) go to 211
      jg=me+nd
212   sam=sa(jg)
      ham=ha(jg)
      if (isig.eq.1) go to 213
      sam=-sam
      ham=-ham
      go to 213
211   jg=iky(nd)+md
      go to 212
213   sum=sum+sam
204   hum=hum+ham
        sm(ig)=sum
        hm(ig)=hum
215   nh=kh
203   mh=kh
      ih=kh
      iz=kz
202   continue
      nblk=(ig-1)/mxcrc2+1
      nrecy=nblk+nrecy
      i9=0
      do 216 i=1,nblk
      lg=mxcrc2
      do 217 j=1,mxcrc2
      lg=lg+1
      i9=i9+1
      guf(j)=hm(i9)
217   guf(lg)=sm(i9)
216   write(ltape)guf
9980  continue
       if(oprint(32)) then
        write(jtape,*) 'nb, ltape after 1e-ints = ', nb, ltape
       endif
c
      if(oprint(31))write(jtape,6500)(dash,i=1,104)
 6500 format(/1x,104a1)
      if(oprint(32))write(jtape,*) 'isymx = ', isymx
      call cmrdm2(nork,ipup,isymx,odebug)
      return
      end
      subroutine cmrdm2(nork,ipup,isymx,odebug)
      implicit REAL (a-h,o-z), integer (i-n)
      logical odebug
INCLUDE(common/sizes)
INCLUDE(common/prints)
      common/aplus/g(900),p(751),v(maxorb),
     + nir(maxorb),loc(maxorb),ncomp(maxorb),jdeks(maxorb),
     + kdeks(maxorb),lsym(8*maxorb),
     + mj(8),nj(8),ntil(8),nbal(9),irper(8),
     + ircor(8),mtil(4),mbal(4),inper(8),mver(4),
     + mvom(4),npal(8),ij(8),mvil(4)
      common/junk/ixa(3400),bb(10*maxorb),cbb(10*maxorb),
     + x(maxorb),y(maxorb),q(maxorb),
     + nnum(maxorb),i2(maxorb),i3(maxorb),i4(maxorb),
     + nord(maxat),ilife(maxorb),nco(100),nrw(100),
     + ityp(maxorb),icon(maxorb),iord(maxat),ncont(maxat)
      common/lsort /natt(maxat),ise(7),ip(7*maxat),ibas(maxat),
     + npf(7),npz(7),nel(3),nbon(maxat),
     + nfun(3*maxorb),npar(3*maxorb),mpar(3*maxorb)
      common/scra/sexp(1000),coe(1000),
     + cm(maxat),cx(maxat),cy(maxat),cz(maxat),
     + z(maxat),xx(maxat),yy(maxat),zz(maxat),
     + mcomp(maxorb),ksym(8*maxorb),nfil(maxorb),
     + imix(3),ibuk(3),inuk(3),nzer(8),nblz(8),ncal(8),
     + nzil(8),nsog(maxorb),msym(8*maxorb),kcomp(maxorb),
     + nwil(8),ngal(8),kj(8)
INCLUDE(common/ftape)
      common/bnew/sum,gg,itape,jtape,ntape,mtape,ltape,mscr,nrac,nrecy,
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,is,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc
INCLUDE(common/blockc)
      common/linkmr/neway(maxorb),newya(maxorb)
      REAL guf
      common/miscop/guf(mxcrec),iwrit(50)
      dimension c(4*maxat)
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      dimension h(ndime)
      equivalence (bb(1),h(1)),(c(1),cm(1))
      if (oprint(32)) then
        write(jtape,*)' isymx, jx, kx = ', isymx, jx, kx
      endif
        if(isymx.le.0)go to 8997
      if(oprint(31))write(jtape,6501)
 6501 format(/40x,
     *'symmetry adapted basis functions'/40x,32('-'))
      if (kx.eq.0) go to 600
c
      ntel=8
      if(kx.eq.2) ntel=4
      if(kx.eq.1) ntel=2
c
      if(jx.ne.kx) go to 400
       n=0
       nc=1
       k=0
       do 861 i=1,nsel
      if(oprint(31))write(jtape,6502)i
 6502 format(/
     *' irreducible representation no. ',i2/1x,33('-'))
        njx=nj(i)
       if(njx.eq.0) go to 6503
       n=n+1
      if(oprint(31))write(jtape,6504)
 6504 format(/
     *' sequence     no. of    lcbf'/
     *' no. of sabf  terms    (gamess numbering)'/)
       do 868 j=1,njx
       k=k+1
       kkkk=lsym(k)
       l=newya(iabs(kkkk))
       if(kkkk.lt.0)l=-l
 868    if(oprint(31))write(jtape,6505)j,nc,l
 6505 format(4x,i4,8x,i2,7x,8i5)
       nj(n)=njx
       irper(n)=i
      if(oprint(31))write(jtape,6506)njx,n
 6506 format(/
     *' *** total no. of sabfs = ',i3/
     */'    revised representation no. = ',i3/)
      go to 861
 6503 if(oprint(31))write(jtape,6507)
 6507 format(/
     *' *** there are no sabf of this representation *** ')
  861  continue
       go to 8997
400   ltape=ipup
      n=0
      do 401 i=1,nsel
      if(nj(i).ne.0) go to 402
      ircor(i)=0
      go to 401
402   nb=nbal(i)+1
      nb=lsym(nb)
      n=n+1
      if (nb.lt.0) nb=-nb
      ircor(i)=nir(nb)
401   continue
      nm=0
      do 403 i=1,ntel
      do 404 j=1,nsel
      if (ircor(j).ne.i) go to 404
      nm=nm+1
      irper(nm)=j
      if (nm.eq.n) go to 405
404   continue
403   continue
405   lx=0
      mx=0
      do 407 i=1,n
      nb=irper(i)
      nc=nbal(nb)
      nd=ntil(nb)
      mjx=nj(nb)
      kj(i)=mjx
      nwil(i)=mx
      ngal(i)=lx
      do 407 j=1,mjx
      nd=nd+1
      mx=mx+1
      kc=ncomp(nd)
      kcomp(mx)=kc
      do 407 k=1,kc
      lx=lx+1
      nc=nc+1
407   msym(lx)=lsym(nc)
      do 417 i=1,nork
      lx=msym(i)
      if(lx.lt.0) go to 418
      lsym(i)=loc(lx)
      go to 417
418   lsym(i)=-loc(-lx)
417   continue
      do 409 i=1,iorbs
409   ncomp(i)=kcomp(i)
      do 410 i=1,n
      nbal(i)=ngal(i)
      nj(i)=kj(i)
410   ntil(i)=nwil(i)
      nbal(n+1)=nork
      mx=0
      do 218 i=1,n
      nb=irper(i)
      mjx=nj(i)
      do 218 j=1,mjx
      mx=mx+1
      nir(mx)=nb
218   loc(mx)=j
      lx=0
      mx=0
      iw=1
       mi=1
      do 411 i=1,ntel
      mjx=mj(i)
      mtil(i)=mx
      mbal(i)=lx
      if (mjx.eq.0) go to 411
      mx=mx+mjx
      do 412 it=iw,n
      il=irper(it)
      if (ircor(il).eq.i) go to 412
      mi=it
      lx=nbal(it)
      go to 411
412   continue
411   iw=mi
      if (odebug) write(6,*)' mtape,ltape = ', mtape, ltape
      call rewftn(mtape)
      read(mtape,end=8101)nb,nbas,nhfunc,
     +              (iord(i),i=1,nhfunc),repel,newya
      nb=-4
      write(ltape)nb,nbas,nhfunc,(iord(i),i=1,nhfunc),repel,newya
      read(mtape,end=8102)nsel,nwil,nwil,iorbs,knu,c
      write(ltape)nsel,mj,nj,iorbs,knu,c,msym
      read(mtape,end=8103)
      write(ltape)nir,loc,lsym,ncomp,ntil,nbal
      read(mtape,end=8104) repel,h
      write(ltape) repel,h
      nblk=nrecy-4
      do 413 i=1,nblk
      read(mtape,end=8105) guf
413   write(ltape) guf
c
      do 470 i=1,nsel
470   inper(i)=0
      do 471 i=1,n
      j=irper(i)
471   inper(j)=i
      do 472 i=1,ntel
472   mver(i)=0
      do 473 i=1,n
      j=irper(i)
      j=ircor(j)
473   mver(j)=mver(j)+1
      mvom(1)=0
      do 474 i=2,ntel
474   mvom(i)=mvom(i-1)+mver(i-1)
      go to 800
600   n=0
      do 601 i=1,nsel
      if (nj(i).ne.0) go to 602
      ircor(i)=0
      go to 601
602   n=n+1
      ntil(n)=ntil(i)
      nbal(n)=nbal(i)
      nj(n)=nj(i)
      ircor(i)=1
601   continue
      do 603 i=1,n
603   irper(i)=i
      mvom(1)=0
      mver(1)=n
       mj(1)=iorbs
      do 604 i=1,nsel
604   inper(i)=0
      do 605 i=1,n
      j=irper(i)
605   inper(j)=i
      mtil(1)=0
      mbal(1)=0
      iu=0
      do 607 i=1,n
      nb=irper(i)
      nx=nj(i)
      do 607 j=1,nx
      iu=iu+1
      nir(iu)=nb
607   loc(iu)=j
800   call rewftn(ltape)
      call rewftn(mtape)
      do 650 i=1,n
      ij(i)=nj(i)-1
      ix=irper(i)
      iy=ircor(ix)
650   npal(i)=ntil(i)-mtil(iy)+1
      read (ltape) nb,nbas,nhfunc,(iord(i),i=1,nhfunc),repel,newya
      nb=-2
      write(mtape)nb,nbas,nhfunc,(iord(i),i=1,nhfunc),repel,newya
      read(ltape)nsel,nwil,nwil,iorbs,knu,c,msym
       if(kx.gt.0) go to 163
         do 164 i=1,nork
 164      msym(i)=lsym(i)
 163  write(mtape)nsel,n,ntel,mj,nj,iorbs,knu,c,nrecy,msym
      read(ltape)
      write(mtape)nir,loc,mver,mvom,lsym,ncomp,nbal,ntil,mbal,mtil,irper
     1,inper,ircor,jsym,npal,ij,mvil
      read(ltape) repel,h
      write(mtape) repel,h
      nblk=nrecy-4
      do 801 i=1,nblk
      read(ltape)guf
801   write(mtape)guf
      call rewftn(mtape)
      call rewftn(ltape)
      read(mtape) nb,nbas,nhfunc,(iord(i),i=1,nhfunc),repel,newya
      nb=-3
      write(ltape)nb,nbas,nhfunc,(iord(i),i=1,nhfunc),repel,newya
      read(mtape)nsel,n,ntel,mj,nj,iorbs,knu,c,nrecy,msym
      write(ltape)nsel,n,ntel,mj,nj,iorbs,knu,c,nrecy,msym,irs,ifrk1
      read(mtape)
      write(ltape)nir,loc,mver,mvom,lsym,ncomp,nbal,ntil,mtil,irper,inp
     1er,ircor,jsym,npal,ij,mvil
      read(mtape) repel,h
      write(ltape) repel,h
      do 900 i=1,nblk
      read(mtape) guf
900   write(ltape) guf
c     read(mtape) jx
       iz=0
      do 863 i=1,nsel
      iw=inper(i)
      if(iw.eq.0) go to 863
       iz=iz+1
       mj(iz)=nj(iw)
      irper(iz)=i
 863    continue
      iz=0
      do 864 i=1,nsel
      iw=inper(i)
      if(oprint(31))write(jtape,6502)i
      if(iw.eq.0)go to 6600
      kg=ntil(iw)
       iz=iz+1
       njx=mj(iz)
       it=nbal(iw)
      if(oprint(31))write(jtape,6504)
       do 865 j=1,njx
        kg=kg+1
       nc=ncomp(kg)
        do 869 k=1,nc
      it=it+1
 869   lsym(k)=msym(it)
       do 6601 k=1,nc
       kkkk=lsym(k)
       if(kkkk.lt.0)go to 6602
       iwrit(k)=newya(kkkk)
       go to 6601
 6602  iwrit(k)=-newya(-kkkk)
 6601  continue
 865   if(oprint(31))write(jtape,6505) j,nc,(iwrit(l),l=1,nc)
      if(oprint(31))write(jtape,6506)njx,iz
      go to 864
 6600 if(oprint(31))write(jtape,6507)
 864     continue
c
 8997 cpu=cpulft(1)
      if(.not.oprint(29)) write(jtape,8998)cpu
 8998 format(/
     *' end of symmetry adaption at ',f8.2,' secs.'/)
      return
8101  call caserr('end of mtape - record 1')
8102  call caserr('end of mtape - record 2')
8103  call caserr('end of mtape - record 3')
8104  call caserr('end of mtape - record 4')
8105  call caserr('end of mtape - record 5')
      return
      end
      subroutine cgetshm(s,h,natoms,ncon,if,buff,lbuff,oneu,nrec1,iwr)
      implicit REAL  (a-h,o-z),integer(i-n)
      logical odum
      integer oneu
      dimension buff(lbuff)
      dimension s(*),h(*),ncon(*),if(*)
      int=lbuff
      ipend=0
      do 19 ia=1,natoms
      ipbeg=ipend+1
      ipend=ipend+ncon(ia)
      if(ncon(ia).eq.0)go to 19
      do 18 ip=ipbeg,ipend
      it2=if(ip)
      do 17 iq=ipbeg,ip
      ix=it2+iq
      int=int+1
      if(int.le.lbuff) go to 16
      read(oneu,end=120,err=120) odum,buff
      nrec1=nrec1+1
      int=1
   16 s(ix)=buff(int)
   17 continue
   18 continue
   19 continue
      if(natoms.eq.1) go to 30
      ipend=ncon(1)
      do 29 ia=2,natoms
      ipbeg=ipend+1
      ipend=ipend+ncon(ia)
      if(ncon(ia).eq.0)go to 29
      iam1=ia-1
      iqend=0
      do 28 ib=1,iam1
      iqbeg=iqend+1
      iqend=iqend+ncon(ib)
      if(ncon(ib).eq.0)go to 28
      do 27 ip=ipbeg,ipend
      it2=if(ip)
      do 26 iq=iqbeg,iqend
      ix=it2+iq
      int=int+1
      if(int.le.lbuff) go to 25
      read(oneu,end=120,err=120) odum,buff
      nrec1=nrec1+1
      int=1
   25 s(ix)=buff(int)
   26 continue
   27 continue
   28 continue
   29 continue
   30 ipend=0
      do 39 ia=1,natoms
      ipbeg=ipend+1
      ipend=ipend+ncon(ia)
      if(ncon(ia).eq.0)go to 39
      do 38 ip=ipbeg,ipend
      it2=if(ip)
      do 37 iq=ipbeg,ip
      ix=it2+iq
      int=int+1
      if(int.le.lbuff) go to 36
      read(oneu,end=120,err=120) odum,buff
      nrec1=nrec1+1
      int=1
   36 h(ix)=buff(int)
   37 continue
   38 continue
   39 continue
      if(natoms.eq.1) go to 50
      ipend=ncon(1)
      do 49 ia=2,natoms
      ipbeg=ipend+1
      ipend=ipend+ncon(ia)
      iam1=ia-1
      iqend=0
      if(ncon(ia).eq.0)go to 49
      do 48 ib=1,iam1
      iqbeg=iqend+1
      iqend=iqend+ncon(ib)
      if(ncon(ib).eq.0)go to 48
      do 47 ip=ipbeg,ipend
      it2=if(ip)
      do 46 iq=iqbeg,iqend
      ix=it2+iq
      int=int+1
      if(int.le.lbuff) go to 45
      read(oneu,end=120,err=120) odum,buff
      nrec1=nrec1+1
      int=1
   45 h(ix)=buff(int)
   46 continue
   47 continue
   48 continue
   49 continue
   50 if (int.eq.lbuff) read (oneu)
      if (int.eq.lbuff) nrec1=nrec1+1
_IF1()      ipend=0
_IF1()      do 9998 ia=1,natoms
_IF1() 9998 ipend=ipend+ncon(ia)
_IF1()      ipend=if(ipend)+ipend
      return
  120 write(iwr,130)
  130 format (//' ** error detected on reading one-electron integrals')
      call caserr(
     * 'error reading 1-electron integrals')
      return
      end
      subroutine creadsh(s,h,ao,mst)
      implicit REAL  (a-h,o-z),integer(i-n)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/mapper)
INCLUDE(common/zorac)
      common /blkin/ pp(4),y(512)
      common/linkmr/new(maxorb)
c
      dimension s(*),h(*),ao(*),mst(2)
c
      data mmat,m2,m511/ 2,2,511/
c
      call secget(ionsec,m2,iblk33)
      call rdedx(pp,m511,iblk33,idaf)
      lenb = lensec(nx)
      do imat=1,mmat
      j=mst(imat)
      ibl = iblk33 + 1 + (j-1) * lenb
      call rdedx(ao,nx,ibl,idaf)
c
      if (j.eq.3.and.ozora) then
          if (nwcor_z.ne.nx) call caserr('zora confusion in readsh')
c....     no dynamic memory here ; mrdcim must have called zora
          call rdedx(h,nwcor_z,ibcor_z,num8)
          call vadd(h,1,ao,1,ao,1,nwcor_z)
          if (oscalz) then
c...  add scaling correction to 1-electron matrix
             call rdedx(h,nwcor_z,ibscalao_z,num8)
             call vadd(h,1,ao,1,ao,1,nwcor_z)
          end if
      end if
c
      ij = 0
        do ia = 1,num
         do ja = 1,ia
         ij = ij + 1
         yy=ao(ij)
         ih=new(ia)
         jh=new(ja)
         iinn=min(ih,jh)+iky(max(ih,jh))
         h(iinn)=yy
         if(imat.eq.1) s(iinn)=yy
         enddo
        enddo
      enddo
      return
      end
      subroutine cface1(s,ns,iw)
      implicit REAL  (a-h,o-z),integer(i-n)
INCLUDE(common/sizes)
      dimension s(*),mst(6)
      common /linkmr/ map(maxorb+maxorb),ipr,lbuff
INCLUDE(common/infoa)
INCLUDE(common/ftape)
      data mst / 1,3,2,4,5,6 /
c
      i1=1
      i2=i1+nat
      i3=i2+nat
      i4=i3+3*mxgaus
      i5=i4+num
      i6=i5+num
      i7=i6+4*nat
      i8=i7+nat
      i9=i8+num
      i10=i9+num
      icx=i10+(num+1)/2
      if (icx.le.ns) go to 1000
1001  call caserr('insufficient memory in property pre-processor')
1000  call cbasis(s(i6) ,s(i2) ,s(i3) ,s(i4) ,s(i5), s(i1),
c                atom   nsh    exx    ntyp   nnum   ncon
     *           s(i7) ,s(i8) ,s(i9),nat,num,mxgaus,iw)
c                nraw   nord  ncent
      lbuff=900
      i1=i2
      i2=lbuff+i1
      i3=nx+i2
      i4=max(nx,na)+i3
      last=nx+i4
      if (last.gt.ns) go to 1001
      ik=1
      do 200 k=1,3
      call creadsh(s(i2),s(i3),s(i4),mst(ik))
c                 s     h     dummy
      call cputshm(s(i2),s(i3),s(i1),s(1),lbuff)
c                 s     h     buff   ncon
200   ik=ik+2
      call rewftn(nf2)
      return
      end
      subroutine cbasis(atom,nsh,exx,ntyp,nnum,ncon,nraw,nord,nhelp,
     +                 natoms,ior,mxe,iw)
      implicit REAL  (a-h,o-z),integer(i-n)
      character *1 icar,dash,ishh
      character *8 title,tagg
INCLUDE(common/sizes)
INCLUDE(common/prints)
      common/junk/ishp(mxgaus),ityp(mxgaus),igp(mxgaus),exxp(2,mxgaus)
      common/lsort/atomo(4,maxat),poto,nsho(maxat)
INCLUDE(common/infoa)
      common/linkmr/news(maxorb),newei(maxorb),ipr,lbuff,igame
INCLUDE(common/ftape)
      common/junkc/title(10),tagg(maxat)
      dimension ioff(5),mtyp(15)
      dimension atom(4,natoms),nsh(natoms),exx(3,mxe),
     *ntyp(ior),nnum(ior),ncon(natoms),nraw(natoms),nhelp(ior),
     *nord(natoms)
      dimension mal(10),iotypa(35),icar(6),iotypg(35)
      data mal /1,3,6,10,15,1,4,6,10,15/
      data iotypa/1,2,3,4,6,7,9,5,8,10,
     *11,16,20,12,13,15,17,18,19,14,21,22,23,24,25,26,27,28,29,30,31,32,
     *33,34,35/
      data iotypg/ 1, 2, 3, 4, 5, 8,10, 6, 7, 9,
     1            11,16,20,12,13,15,17,18,19,14,
     2            21,22,23,24,25,26,27,28,29,30,31,32,33,34,35/
      data icar /'s','p','d','f','g','0'/,
     *ioff /0,1,4,10,20/
      data dash/'-'/
c
      potnuc=poto
      do 9999 i=1,nat
      nsh(i)=nsho(i)
      ncon(i)=0
      nraw(i)=0
      do 9999 j=1,4
 9999 atom(j,i)=atomo(j,i)
      iat=1
      norbs=0
      ksh=nsh(iat)
      if(ksh.eq.0)call caserr(
     *'indexing problem in adaptation .. call for help ..259')
      iprim=0
      jsh=0
      kshel=1
      jorbs=0
      kprim=1
      iexx=1
      ioo=0
      i=0
2     continue
      i=i+1
      if(i.eq.ipr+1) then
        ig=ig+1
        ioo=-1
        goto 7
      endif 
      ish=ishp(i)
      ity=ityp(i)
      ig=igp(i)
      do 9997 j=1,2
 9997 exx(j,iexx)=exxp(j,ig)
      im=mal(ity)-1
      if (im.eq.0) goto 3
      do 500 j=1,im
      exx(1,iexx+j)=exx(1,iexx)
500   exx(2,iexx+j)=exx(2,iexx)
    3 iexx=iexx+im+1
      if (iexx.gt.mxgaus) call caserr(
     *'primitive allocation exceeded in adaptation')
      if (ish.eq.kshel) goto 503
      ioo=0
7     kshel=ish
      jsh=jsh+1
      do 600 j=1,kmal
      iprim=ig-kprim+iprim
      nnum(jorbs+j)=ig-kprim
600   ntyp(jorbs+j)=mtyp(j)
      kprim=ig
      jorbs=jorbs+kmal
      if (jsh.lt.ksh) goto 503
      nraw(iat)=iprim
      iprim=0
      ncon(iat)=jorbs-norbs
      norbs=jorbs
      iat=iat+1
      ksh=nsh(iat)
      jsh=0
503   if (ioo) 5,8,2
8     ioo=1
      if(ity .gt. 5) ity=ity-5
      kmal=im+1
      nhelp(jorbs+1)=ity
      if (im.eq.0) goto 11
      do 10 j=1,im
10    nhelp(jorbs+j+1)=6
11    kstrt=ioff(ity)
      do 703 j=1,kmal
      jjj=iotypa(kstrt+j)
      if(igame.eq.1)jjj=iotypg(kstrt+j)
 703  mtyp(j)=jjj
      goto 2
5     continue
      nbas=1
      nord(1)=1
      lnb=ncon(1)
      lpr=nraw(1)
      if (nat.eq.1) goto 99
      do 12 i=2,nat
      ig=0
      kmal=0
      ish=ncon(i)
      zi=atom(1,i)
      iprim=nraw(i)
      iat=i-1
      do 13 j=1,iat
      zij=zi-atom(1,j)
      jsh=ncon(j)
      kprim=nraw(j)
      if (jsh.ne.ish) goto 14
      if (kprim.ne.iprim) goto 14
      if(dabs(zij).gt.0.003d0)go to 14
      if(ish.eq.0)go to 2027
      do 16 k=1,ish
      if (nnum(lnb+k).ne.nnum(kmal+k)) goto 14
      if (ntyp(lnb+k).ne.ntyp(kmal+k)) goto 14
16    continue
      do 17 k=1,kprim
      do 15 l=1,2
      if (dabs(exx(l,lpr+k)-exx(l,ig+k)).gt.1.d-5) goto 14
15    continue
17    continue
2027  nord(i)=nord(j)
      goto 18
14    ig=ig+kprim
      kmal=kmal+jsh
13    continue
      nbas=nbas+1
      nord(i)=nbas
18    lnb=lnb+ish
12    lpr=lpr+iprim
99    if(.not.oprint(29)) write(iw,9168)title
 9168 format(//20x,90('*')/
     *20x,'*',88x,'*'/
     *20x,'*',88x,'*'/
     *20x,'*',4x,10a8,4x,'*'/
     *20x,'*',88x,'*'/
     *20x,90('*')/)
      if(oprint(31))write(iw,100) num,nat,
     *(i,(atom(j,i),j=1,4),nord(i),i=1,nat)
100   format(/
     *' no. of basis functions      ',i6/
     *' no. of nuclei               ',i6//
     *'  centre      charge     x          y          z       basis'/
     *2x,58('-')
     */(1x,i2,7x,4(f8.2,3x),i2))
      call rewftn(nf2)
      k=1
      write (nf2) nat,nbas,k,k,potnuc,newei
      write (nf2) (nord(i),i=1,nat),
     *((atom(i,j),j=1,nat),i=1,4)
      lnb=0
      lpr=0
      nbas=0
      if(oprint(31))write(iw,7001)(dash,i=1,104)
 7001 format(/1x,104a1)
      if(oprint(32))write(iw,7000)
 7000 format(/40x,28('-')/
     *40x,'basis function specification'/40x,28('-'))
      do 31 i=1,nat
      nco=ncon(i)
      nra=nraw(i)
      if (nord(i).le.nbas) goto 19
      jpr=lpr
      nbas=nbas+1
      if(oprint(32))write(iw,101) nbas,nco,nra
101   format(/5x,' **** atom type no.',i3,' no. of gtos: ',i3,
     *' no. of primitives: ',i3)
      if(nco.eq.0)go to 2037
      if(oprint(32))write(iw,104) (nnum(lnb+j),j=1,nco)
104   format(/' gto contractions: ',50i2)
      if(oprint(32))write(iw,6666)
6666  format(/)
      do 34 j=1,nco
      jsh=nnum(lnb+j)
      ksh=mal(nhelp(lnb+j))
      if (nhelp(lnb+j).eq.6) goto 34
      ishh=icar(nhelp(lnb+j))
      call ctrmrsp(exx(1,jpr+1),ksh,jsh)
      do 9 ity=1,jsh
9     if(oprint(32))write (iw,103) ishh,exx(2,ity+jpr),exx(1,ity+jpr)
      jpr=jpr+jsh*ksh
34    continue
103   format(1x,a1,3x,2f14.6)
 2037 write(nf2)nra,nco
      if(nra.ne.0.and.nco.ne.0)
     *write (nf2) ((exx(k,lpr+j),j=1,nra),k=1,2),
     *(ntyp(lnb+j),j=1,nco),(nnum(lnb+j),j=1,nco)
19    lpr=lpr+nra
31    lnb=lnb+nco
      return
      end
      subroutine cputshm(s,h,buff,ncon,lbu)
      implicit REAL  (a-h,o-z), integer (i-n)
      logical otrue,ofalse
INCLUDE(common/sizes)
      common /linkmr/ map(maxorb+maxorb),ipr,lbuff
INCLUDE(common/infoa)
INCLUDE(common/mapper)
INCLUDE(common/ftape)
      dimension buff(lbu),s(*),h(*),ncon(*)
      otrue=.true.
      ofalse=.false.
      ir=0
      ipend=0
      do 19 ia=1,nat
      ipbeg=ipend+1
      ipend=ipend+ncon(ia)
      if(ncon(ia).eq.0)go to 19
      do 18 jp=ipbeg,ipend
      it2=iky(jp)
      do 17 jq=ipbeg,jp
      ix=it2+jq
      ir=ir+1
      if (ir .le. lbuff) goto 16
      ir=1
      write (nf2) ofalse,buff
   16 buff(ir)=s(ix)
   17 continue
   18 continue
   19 continue
      if(nat.eq.1) go to 30
      ipend=ncon(1)
      do 29 ia=2,nat
      ipbeg=ipend+1
      ipend=ipend+ncon(ia)
      if(ncon(ia).eq.0)go to 29
      iam1=ia-1
      iqend=0
      do 28 ib=1,iam1
      iqbeg=iqend+1
      iqend=iqend+ncon(ib)
      if(ncon(ib).eq.0)go to 28
      do 27 jp=ipbeg,ipend
      it2=iky(jp)
      do 26 jq=iqbeg,iqend
      ix=it2+jq
      ir=ir+1
      if (ir .le. lbuff) goto 25
      ir=1
      write (nf2) ofalse,buff
   25 buff(ir)=s(ix)
   26 continue
   27 continue
   28 continue
   29 continue
   30 ipend=0
      do 39 ia=1,nat
      ipbeg=ipend+1
      ipend=ipend+ncon(ia)
      if(ncon(ia).eq.0)go to 39
      do 38 jp=ipbeg,ipend
      it2=iky(jp)
      do 37 jq=ipbeg,jp
      ix=it2+jq
      ir=ir+1
      if (ir .le. lbuff) goto 36
      ir=1
      write (nf2) ofalse,buff
   36 buff(ir)=h(ix)
   37 continue
   38 continue
   39 continue
      if(nat.eq.1) goto 1
      ipend=ncon(1)
      do 49 ia=2,nat
      ipbeg=ipend+1
      ipend=ipend+ncon(ia)
      if(ncon(ia).eq.0)go to 49
      iam1=ia-1
      iqend=0
      do 48 ib=1,iam1
      iqbeg=iqend+1
      iqend=iqend+ncon(ib)
      if(ncon(ib).eq.0)go to 48
      do 47 jp=ipbeg,ipend
      it2=iky(jp)
      do 46 jq=iqbeg,iqend
      ix=it2+jq
_IF1()      int=int+1
      ir=ir+1
      if (ir .le. lbuff) goto 45
      ir=1
      write (nf2) ofalse,buff
   45 buff(ir)=h(ix)
   46 continue
   47 continue
   48 continue
   49 continue
1     write (nf2) otrue,buff
      return
      end
      subroutine ctrmrsp(e,i1,i2)
       implicit REAL  (a-h,o-z), integer (i-n)
      dimension e(3,2)
      if (i1.eq.1) goto 999
      if (i2.eq.1) goto 999
      nz=i1*i2
      m=1
      n=1
      do 1 i=1,nz
      e(3,i)=e(1,n)
      n=n+i1
      if (n.le.nz) goto 11
      m=m+1
      n=m
11    continue
1     continue
      do 2 i=1,nz
2     e(1,i)=e(3,i)
      m=1
      n=1
      do 3 i=1,nz
      e(3,i)=e(2,n)
      n=n+i1
      if (n.le.nz) goto 12
      m=m+1
      n=m
12    continue
3     continue
      do 4 i=1,nz
4     e(2,i)=e(3,i)
999   continue
      return
      end
c ******************************************************
c ******************************************************
c             =   Table-ci (transformation interface)
c ******************************************************
c ******************************************************
      subroutine cmrdci2(x,odebug)
      implicit REAL  (a-h,o-z), integer(i-n)
      logical odebug
INCLUDE(common/sizes)
INCLUDE(common/prints)
      common/trann/ic,i7,mj(8),kj(8),isecv,
     +             icore,ick(maxorb),izer,iaus(maxorb)
INCLUDE(common/discc)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/atmol3)
      common/lsort /space4(2000)
      dimension iq(6),x(*)
c
c     retrieve core and discarded mos specs
c     from /trann/ as set by defaults_mrdci
c
      if(.not.oprint(29)) write(iwr,6)yed(idaf),ibl3d
      if(isecv.le.0)then
      isecv=mouta
      if(moutb.ne.0) isecv=moutb
      endif
      if(ibl3d)12,12,13
12    call caserr('invalid starting block for dumpfile')
 13   if(isecv.gt.350)call caserr(
     *'invalid dumpfile section nominated for vectors')
      if(.not.oprint(29)) then 
       write(iwr,4)isecv
      endif
      if(num.le.0. or.num.gt.maxorb) call caserr(
     *'invalid number of basis functions')
c
      nbsq = num * num
      need = nx * 5 + nbsq + lenint(nbsq)
c
      iq(1) = igmem_alloc(need)
      do 26 i=2,4
26    iq(i)=iq(i-1)+nx
      iq(5) = iq(4) + nx
      iq(6) = iq(5) + nbsq
      call ctmrdm(x(iq(1)),x(iq(4)),x(iq(1)),
     +            x(iq(2)),x(iq(5)),x(iq(6)),nbsq,
     +            odebug,x)
      if(oprint(31))call secsum
      if(oprint(31))call whtps
c
      call gmem_free(iq(1))
c
      call clredx
      return
 6    format(//1x,104('=')//
     *40x,38('*')/
     *40x,'Table-Ci  -- transformation conversion'/
     *40x,38('*')//
     *1x,'dumpfile on ',a4,' at block',i6)
 4    format(/1x,
     *'eigen vectors to be restored from section',i4)
      end
      subroutine ctvec(r,q,etot,nj,lj,ntil,mwal,mj,ick,kj,iaus,
     *nsym,iorbs,iposv,odebug,core)
      implicit REAL  (a-h,o-z),integer (i-n)
      character *8 zcom,ztit
      character *1 dash
      logical  iftran,odebug
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/iofile)
      common/junkc/zcom(19),ztit(10)
      common/scra /ixa(3400),
     *ilifd(maxorb),ntrad(maxorb),itrad(mxorb3),
     *ctrad(mxorb3),iftran
      common/lsort /value(maxorb),occ(maxorb+1),
     *nbasis,newbas,ncol,ivalue,iocc,isp
INCLUDE(common/discc)
INCLUDE(common/machin)
INCLUDE(common/harmon)
INCLUDE(common/scra7)
INCLUDE(common/mapper)
INCLUDE(common/tran)
      common/junk2/ilifch(maxorb),ntranh(maxorb),itranh(mxorb3),
     +             ctranh(mxorb3),
     +             ilifct(maxorb),ntrant(maxorb),itrant(mxorb3),
     +             ctrant(mxorb3)
c
      common/linkmr/map(maxorb+maxorb),ipr,lbuff,igame
c
      dimension r(*),q(*),nj(*),lj(*),ntil(*),mwal(*)
      dimension mj(*),ick(*),kj(*),iaus(*),core(*)
      dimension mmm(maxorb)
c
      data dash/'*'/
      data thr/1.0d-4/
      data m3,m29/3,29/
      if(iposv.gt.350)call caserr(
     *'invalid section specified for vector input')
      if(.not.oprint(29)) write(iwr,14 )iposv,ibl3d,yed(idaf)
14    format(/' vectors restored from section',i4,
     *' of dumpfile starting at block',i6,' of ',a4)
      call secget(iposv,m3,k)
      call rdchr(zcom(1),m29,k,idaf)
      call reads(value,mach(8),idaf)
      nav = lenwrd()
c
c     see notes below
      call readis(ilifc,mach(9)*nav,idaf)
      call icopy(maxorb,ilifc,1,ilifd,1)
      call icopy(maxorb,ntran,1,ntrad,1)
      call icopy(mxorb3,itran,1,itrad,1)
      call dcopy(mxorb3,ctran,1,ctrad,1)
      iftran = otran
c     
      if(nbasis.ne.iorbs) then
       write(6,*)' TVEC ERROR: nbasis,iorbs = ', nbasis, iorbs
       call caserr(
     +    'vectors restored from dumpfile have incorrect format')
      endif
      if(nbasis.ne.newbas.or.nbasis.lt.ncol) then
         call caserr(
     + 'invalid number of basis functions in ctvec')
      endif
      if(igame.eq.1)go to 40
      if(.not.iftran)call caserr(
     *'restored vectors generated with ADAPT off')
 40   etot=occ(maxorb+1)
      if(.not.oprint(29)) write(iwr,15)(zcom(7-i),i=1,6),ztit,etot
 15   format(/' header block information :'/
     *' vectors created under acct. ',a8/1x,
     *a7,'vectors created by ',a8,'  program at ',
     *a8,' on ',a8,' in the job ',a8/
     *' with the title: ',10a8/
     *' ezero : ',f14.7,' hartree'/)
c     nbsq=nbasis*ncol
      nbsq=nbasis*nbasis
      call reads(q,nbsq,idaf)
c
c...   for harmonic transform vectors to just symmetry adapted
c
      if (oharm) then
c        note that the original implementation that overwrote /tran/
c        is flawed in multiple passes through the NO generator as
c        tdown ceases to function correctly in the 2nd and successive pass
c
c...     bring to unadapted basis
        call tdown(q,ilifq,q,ilifq,newbas0)
        oharm = .false.
c...     read non harmonic symmetry adapt in tran
        call readi(ilifc,2*maxorb+mxorb3,ibl7ha,num8)
        call reads(ctran,mxorb3,num8)
c...    generated transformation to symmetry adapted basis
        isovl = igmem_alloc(nbsq)
        call  anorm(core(isovl),core)
        call gmem_free(isovl)
        oharm = .true.
c
c...  transform orbitals back to sabf basis
c
        call tback(q,ilifq,q,ilifq,nbasis)
      end if
c
c     classify scf-mos into symmetry types
c
      do i=1,nsym
       lj(i)=0
      enddo
      kk=0
      ncol1=0
      do 20 k=1,ncol
      do 21 i=1,nsym
      ii=ntil(i)+kk
      iii=nj(i)
      xx=0.0d0
      do j=1,iii
      qq=q(ii+j)
      xx=xx+qq*qq
      enddo
      if(xx.lt.thr)go to 21
      lj(i)=lj(i)+1
      mmm(k)=i
      go to 20
 21   continue
c
c     the following code is necessary given that any vectors
c     written under vectors/enter are finally loaded with
c     ncol = nbasis. Thus restoring NOs under control of
c     vectors must recognise this, and reduce ncol accordingly.
c
      if (odebug) then
        write(iwr,*)' nsym, ncol = ', nsym, ncol
        write(iwr,*)' ntil = ', (ntil(i),i=1,nsym)
        write(iwr,*)' *** m.o., symmetry = ', k, i
      endif
      ncol1 = ncol1 + 1
*     call caserr('error assigning symmetry of input m.o.s')
 20   kk=kk+nbasis
      if (odebug) then
       write(iwr,*)'ncol, ncol1 = ', ncol, ncol1
       write(iwr,*)'nsym, lj = ', nsym, (lj(i),i=1,nsym)
       write(iwr,*)'nsym, nj = ', nsym, (nj(i),i=1,nsym)
      endif
      ncol = ncol - ncol1
      do i=1,nsym
      if(lj(i).gt.nj(i)) then
       write(iwr,*) 'lj, nj = ', lj(i), nj(i)
       call caserr(
     *'error in molecular orbital symmetry designations')
      endif
      enddo
_IF1()c     write(iwr,24)(mmm(k),k=1,ncol)
_IF1()c24   format(1x,20i5)
c
c     now load into core in ctmrdm order
c
      ic=0
      do i=1,nsym
       mwal(i)=ic
       ic=ic+nj(i)*lj(i)
      enddo
c
      nact=0
      iicore=0
      iivirt=0
      do 100 i=1,nsym
      mcore=mj(i)
      mout=kj(i)
      if(lj(i).ne.0)go to 104
      if(mcore.gt.0.or.mout.gt.0)call caserr(
     *'incorrect symmetry designation for frozen or discarded mo')
      go to 100
 104  if((mcore+mout).gt.lj(i))call caserr(
     *'no. of frozen plus discarded mos exceeds irrep. total')
      ij=0
      do 101 j=1,ncol
      jjj=(j-1)*nbasis
      if(mmm(j).ne.i)go to 101
c
c     check if active or frozen/discarded
c
      ij=ij+1
      if(mcore.ne.0)then
       iii=iicore
       do ii=1,mcore
        iii=iii+1
        if(ij.eq.ick(iii))go to 101
       enddo
      endif
      if(mout.gt.0)then
       iii=iivirt
       do ii=1,mout
        iii=iii+1
        if(ij.eq.iaus(iii))go to 101
       enddo
      endif
      nact=nact+1
      ilifm(nact)=jjj
 101  continue
      iicore=iicore+mcore
      iivirt=iivirt+mout
 100  continue
      if(oprint(31)) then
       write(iwr,110)(dash,i=1,104)
 110   format(/1x,104a1)
       write(iwr,111)
 111   format(/40x,
     * 'active orbitals (sabf basis) -- internal labelling'/
     * 40x,50('-'))
       call writem(q,ilifm,nbasis,nact)
      endif
      do i=1,nsym
      ii=nj(i)
      iii=ntil(i)
      ibase=mwal(i)
      jjj=0
       do j=1,ncol
       if(mmm(j).eq.i)then
        ij=jjj+iii
        do k=1,ii
         ibase=ibase+1
         r(ibase)=q(ij+k)
        enddo
       endif
       jjj=jjj+nbasis
       enddo
      enddo
c
      if(oprint(31))write(iwr,110)(dash,i=1,104)
      return
      end
_EXTRACT(ctmrdm,hp800)
      subroutine ctmrdm(r,q,sa,ha,cf,icf,ithr,odebug,cr)
      implicit REAL  (a-h,o-z), integer (i-n)
      logical ocrash,odebug
      dimension r(*),q(*),sa(*),ha(*),cr(*)
      dimension cf(ithr),icf(ithr)
INCLUDE(common/sizes)
      character *1 dash
INCLUDE(common/prints)
INCLUDE(common/mapper)
INCLUDE(common/iofile)
INCLUDE(common/ftape)
INCLUDE(common/blockc)
      common/trann/ic,i7,mjj(8),kjj(8),isecvv,icorf,
     * icl(maxorb),izer1,iaut(maxorb),ispp(1467)
      common/aplus/g(900),p(751),v(maxorb),
     + nir(maxorb),loc(maxorb),ncomp(maxorb),jdeks(maxorb),
     + kdeks(maxorb),
     + lsym(8*maxorb),mj(8),nj(8),ntil(8),nbal(9),
     + irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     + mvom(4),npal(8),ij(8),mvil(4),
     + kj(8),mcomp(maxorb),ibal(8),itil(8)
      common/scra /ixa(3400),ss(maxorb),st(maxorb),espace(6891)
      common/blkin/cm(maxat),cx(maxat),cy(maxat),cz(maxat),
     + z(maxat),xx(maxat),yy(maxat),zz(maxat),
     + iord(maxat),ncont(maxat),nco(100),
     + hm(mxcrc2),sm(mxcrc2),nit(667),
     + lj(8),ick(maxorb),iaus(maxorb),jtil(8),
     + mwal(8),isym(8),isper(8)
      common/lsort /ston(2000)
      common/bnew/sum,gg,itape,jtape,ntape,mtape,ltape,mscr,nrac,nrecy,
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icm,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ktape
c
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      dimension c(4*maxat),msym(8*maxorb),e(ndime)
      dimension fm(500),guf(mxcrec),f(751)
      dimension intin(2000),newya(maxorb)
      character*10 charwall
c
      equivalence (c(1),cm(1)),(msym(1),e(1),ss(1))
      equivalence (fm(251),n2),(f(501),fm(1)),(g(1),f(1))
      equivalence (hm(1),guf(1))
      equivalence (nit(667),lg),(intin(1),ic)
c
      data dash/'*'/
c
      ntape=nf22
      ltape=nf3
      mtape=nf2
      nrac=10
      mscr=nf1
      itape=ird
      jtape=iwr
c
      call rewftn(ntape)
      call rewftn(ltape)
      call rewftn(mtape)
c
      cpu=cpulft(1)
      if(.not.oprint(29)) write(jtape,8999)cpu ,charwall()
 8999 format(/' commence integral transformation at ',f8.2,
     * ' seconds',a10,' wall'/)
      thr=1.0d-5
c ... max.no.. of aos now set to 150
      ifrk=500
      nod=mxcrec
      jod=2000
      ib=401
      ib2=ib+ib
      itx=ib2
      ity=itx
      if2=1000
c
      ik = 0
      irs = 0
c
      ifrk1=ifrk+1
c
      read(ntape)nb,ndum,nhfunc,(iord(i),i=1,nhfunc),repel
     * ,newya
      if(odebug)write(6,*)'nb = ', nb
      if (nb.lt.0) go to 1
      read(ntape)nsel,nj,iorbs,knu,c,jsym
      read(ntape)lsym,ncomp,ntil,nbal
      read(ntape)repel,e
      isper(1)=1
      isym(1)=1
      n=1
      iey=9
      go to 7
 1    iey=0
      if(nb.eq.-1) go to 8
      read(ntape)nsel,n,ntel,mj,kj,iorbs,knu,c,nrecy,msym
      read(ntape)nir,loc,mver,mvom,lsym,mcomp,mbal,mtil,mvil,irper,inper
     1,ircor,jsym
      iz=0
      do 9 i=1,nsel
      iw=inper(i)
      if(iw.eq.0) go to 9
      iz=iz+1
      isper(i)=iz
      nj(iz)=kj(iw)
      isym(iz)=i
9     continue
      iz=0
      lg=0
      lt=0
      do 10 i=1,nsel
      iw=inper(i)
      if(iw.eq.0) go to 10
      kg=mtil(iw)
      iz=iz+1
      njx=nj(iz)
      it=mbal(iw)
      ntil(iz)=lg
      nbal(iz)=lt
      do 11 j=1,njx
      kg=kg+1
      nc=mcomp(kg)
      lg=lg+1
      ncomp(lg)=nc
      do 11 k=1,nc
      lt=lt+1
      it=it+1
11    lsym(lt)=msym(it)
10    continue
      read(ntape)repel,e
      go to 7
8     read(ntape)nsel,mj,nj,iorbs,knu,c,jsym
      read(ntape)nir,loc,lsym,ncomp,ntil,nbal
      read(ntape)repel,e
      if(odebug)write(6,*) '8 - iorbs = ', iorbs
      n=0
      do i=1,nsel
       if(nj(i).gt.0) then
        n=n+1
        isper(i)=n
        nj(n)=nj(i)
        ntil(n)=ntil(i)
        nbal(n)=nbal(i)
        isym(n)=i
       endif
      enddo
c
 7    write(ltape)nsel,nj,ntil,nbal,isym,jsym,n,iorbs,knu,lsym,ncomp,e,c
     1,repel
      if(.not.oprint(29)) then
        if(iey.eq.9)write(jtape,8086)
 8086   format(/' process integrals over ao basis functions (ft22)'
     */)
        if(iey.eq.0)write(jtape,8085)
 8085 format(/' process integrals over sabf (ft22)')
        if(ic.ne.0)write(jtape,8082)
 8082   format(/
     *' *** frozen orbitals specified ')
        if(i7.ne.0)write(jtape,8083)
 8083   format(/
     *' *** discarded orbitals specified')
      endif
      if(oprint(32))write(jtape,8084)
 8084 format(/
     *' integral print option specified')
c14   format(2x,8i10)
      iposv=isecvv
      izer=izer1
      icore=icorf
c     do 8990 loop=1,8
c     mj(loop)=mjj(loop)
c8990 kj(loop)=kjj(loop)
c
      do loop = 1, 8
       mj(loop) = 0
       kj(loop) = 0
       lj(loop) = 0
      enddo
c
      if(odebug)write(6,*)'  n = ', n
      do loop = 1, n
      mfg = isym(loop)
      mj(loop) = mjj(mfg)
      kj(loop) = kjj(mfg)
      enddo
c
      if(odebug)write(6,*)' mj = ',mj
      if(odebug)write(6,*)' kj = ', kj
      if(odebug)write(6,*)' isym = ', isym
c
      do 8991 loop=1,maxorb
      ick(loop)=icl(loop)
 8991 iaus(loop)=iaut(loop)
      if(.not.oprint(29)) write(jtape,8069)
8069  format(/40x,27('=')/
     *        40x,'input orbital specification'/
     *        40x,27('=')/)
      ic=0
      k=0
      l=0
      if(odebug)write(6,*)'8070: n = ', n
      do 8070 i=1,n
       if(odebug) then
        write(6,*)'8070: i = ', i
        write(6,*)'8070: nj(i) = ', nj(i)
        write(6,*)'8070: lj(i) = ', lj(i)
        write(6,*)'8070: mj(i) = ', mj(i)
        write(6,*)'8070: kj(i) = ', kj(i)
       endif
      if(.not.oprint(29)) then
       write(jtape,8071)(dash,j=1,38)
 8071  format(/1x,104a1)
       write(jtape,8072)i
 8072  format(/' orbital symmetry representation no.',i3)
      endif
      if(mj(i).ne.0)go to 8073
      if(.not.oprint(29)) write(jtape,8074)
 8074 format(/' *** no orbitals to be frozen')
      go to 8075
 8073 iij=k+1
      k=k+mj(i)
      if(.not.oprint(29)) then
       write(jtape,8076)mj(i)
 8076  format(/' no. of frozen orbitals ',i3)
       write(jtape,8077)
       write(jtape,8078)(ick(j),j=iij,k)
 8077  format(/' orbital sequence nos.')
 8078  format(/1x,20i4)
      endif
 8075 if(kj(i).ne.0)go to 8079
      if(.not.oprint(29)) write(jtape,8080)
 8080 format(/' *** no orbitals to be discarded')
      go to 8070
 8079 iij=l+1
      l=l+kj(i)
      if(.not.oprint(29)) then
       write(jtape,8081)kj(i)
 8081  format(/' no. of discarded orbitals ',i3)
       write(jtape,8077)
       write(jtape,8078)(iaus(j),j=iij,l)
      endif
 8070 continue
      ocrash = .false.
      do i = n+1, 8
        if (mj(i).ne.0) then
          ocrash = .true.
          write(jtape,8180)mj(i),i
8180      format(' *** Freeze  ',i2,' orbitals for non-present ',
     *           'symmetry set ',i1,' ???')
        endif
        if (kj(i).ne.0) then
          ocrash = .true.
          write(jtape,8182)kj(i),i
8182      format(' *** Discard ',i2,' orbitals for non-present ',
     *           'symmetry set ',i1,' ???')
        endif
      enddo
      if (ocrash) then
         write(jtape,*)'*** Check your TRAN directive with respect ',
     *                      'to the symmetries !!!'
         call caserr(
     *    "Error with symmetries in TRAN directive")
      endif
      if(.not.oprint(29)) write(jtape,8071)(dash,i=1,38)
      ich=0
      izt=0
c     call routine for restoring vectors
c
      call ctvec(r,q,etot,nj,lj,ntil,mwal,mj,ick,kj,iaus,
     * n,iorbs,iposv,odebug,cr)
c
      do i=1,n
       mbal(i)=mwal(i)
      enddo
      imo=0
      ic=0
      ivla=0
      if (odebug) then
       write(6,*) '24:  n = ', n
       write(6,*) '24: nj = ', nj
       write(6,*) '24: mj = ', mj
       write(6,*) '24: kj = ', kj
      endif
      do 24 i=1,n
      ibal(i)=ic
      np=nj(i)
      mw=mbal(i)
      ict=mj(i)
      if(icore.gt.0) then
      if(ict.gt.0) then
      do j=1,ict
       ich=ich+1
       icy=mw+(ick(ich)-1)*np
       imo=imo+1
       isam=ic
        do k=1,np
        icy=icy+1
        sac=r(icy)
        if(dabs(sac).ge.thr*0.0001d0) then
         ic=ic+1
         icf(ic)=k
         cf(ic)=sac
        endif
        enddo
       mcomp(imo)=ic-isam
      enddo
      jch=ich-ict+1
      jct=1
      jcx=ick(jch)
      go to 27
      endif
      endif
c
      jcx=0
 27   izx=kj(i)
      if(izer.gt.0) then
       if(izx.gt.0) then
        ivla=ivla+izx
        izt=izt+1
        izy=1
        izq=iaus(izt)
        go to 29
       endif
      endif
      izq=0
29    kij=lj(i)-izx-ict
      ij(i)=kij
       if(kij.eq.0) go to 116
      lh=0
      do 30 j=1,kij
      imo=imo+1
      lh=lh+1
33    if(lh.ne.jcx) go to 31
      mw=mw+np
      lh=lh+1
      if(jct.eq.ict) go to 32
      jct=jct+1
      jch=jch+1
      kcx=ick(jch)
      if(kcx.le.jcx) call caserr(
     *'error in specifying frozen or discarded m.o. sequence nos')
      jcx=kcx
      go to 33
32    jcx=0
31    if(lh.ne.izq) go to 34
      mw=mw+np
      lh=lh+1
      if (izy.eq.izx) go to 35
      izy=izy+1
      izt=izt+1
      kcx=iaus(izt)
      if(kcx.le.izq) call caserr(
     *'error in specifying frozen or discarded m.o. sequence nos')
      izq=kcx
      go to 31
35    izq=0
34    isam=ic
      do k=1,np
       mw=mw+1
       sac=r(mw)
       if(dabs(sac).ge.thr*0.0001d0) then
        ic=ic+1
        icf(ic)=k
        cf(ic)=sac
       endif
      enddo
c
30    mcomp(imo)=ic-isam
116   izt=ivla
24    continue
      if (odebug) write(6,*) '24: ij = ', ij
      if(ic.gt.ithr) call caserr(
     * 'dimensioning problem with vectors')
      icmo=0
      do 37 loop=1,n
      kj(loop)=lj(loop)-kj(loop)
      itil(loop)=icmo
37    icmo=icmo+kj(loop)
c    
      if(odebug) then
       write(6,*)'37: n= ', n
       write(6,*)'37: lj = ', lj
       write(6,*)'37: kj = ', kj
      endif
      write(ltape)cf,ibal,itil,icf,mcomp,kj,mj,etot,icmo,ij
     * ,icore
      ig=0
      do i=1,n
        kij=nj(i)
       ig=ig+iky(kij+1)
       enddo
      nblk=(ig-1)/mxcrc2+1
      lg=0
      do i=1,nblk
      read(ntape)guf
        do j=1,mxcrc2
         lg=lg+1
         sa(lg)=sm(j)
         ha(lg)=hm(j)
         if(lg.eq.ig) go to 44
        enddo
      enddo
44    nrecy=nblk+4
      do ipass=1,2
        do i=1,nblk
         read(ntape)guf
        enddo
      nrecy=nrecy+nblk
      enddo
      ig=0
      nt=1
      mg=0
      if(oprint(32)) then
        write(jtape,57)
 57     format(/2x,'overlap and t+v integrals'/)
      endif
      do 45 i=1,n
      kij=kj(i)
      ng=nj(i)
      if(kij.eq.0) go to 45
      kx=ibal(i)
      lkg=itil(i)
      llx=kx
      kg=lkg
      do 47 j=1,kij
      kg=kg+1
      nc=mcomp(kg)
      do k=1,ng
       ss(k)=0.0d0
       st(k)=0.0d0
      enddo
      do k=1,nc
       llx=llx+1
       ld=icf(llx)
       sac=cf(llx)
       if(ld.gt.1) then
        lda=ld-1
        iw=mg+iky(ld)
        do l=1,lda
          iw=iw+1
          ss(l)=ss(l)+sac*sa(iw)
c         if (odebug) then
c         write(6,*) 'ld, l, sac, sa(iw), ss(l) = ',
c    +                ld, l, sac, sa(iw), ss(l)
c         endif
          st(l)=st(l)+sac*ha(iw)
        enddo
       endif
       iw=mg+ld
       do l=ld,ng
        iz=iw+iky(l)
        ss(l)=ss(l)+sac*sa(iz)
c       if (odebug) then
c         write(6,*) '+ld,l, sac, sa(iz), ss(l) = ',
c    +                ld, l, sac, sa(iz), ss(l)
c       endif
        st(l)=st(l)+sac*ha(iz)
       enddo
      enddo
      mx=kx
      mm=lkg
      do 47 k=1,j
      mm=mm+1
      ncp=mcomp(mm)
_IF(VAX)
      sum=0.0
      tum=0.0
      do l=1,ncp
       mx=mx+1
       ld=icf(mx)
       sac=cf(mx)
       sum=sum+sac*ss(ld)
       tum=tum+sac*st(ld)
      enddo
_ELSEIF(cray)
      sum=spdot(ncp,ss,icf(mx+1),cf(mx+1))
      tum=spdot(ncp,st,icf(mx+1),cf(mx+1))
      mx=mx+ncp
_ELSE
****
c     write(6,*) 'j,k,ncp,mx = ', j,k,ncp,mx
c     write(6,*) 'cf = '
c     write(6,*) (cf(mmfg),mmfg=mx+1,mx+ncp)
c     write(6,*) 'icf = '
c     write(6,*) (icf(mmfg),mmfg=mx+1,mx+ncp)
c     write(6,*) 'ss = '
c     write(6,*) (ss(icf(mmfg)),mmfg=mx+1,mx+ncp)
*****
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),ss)
      tum=ddoti(ncp,cf(mx+1),icf(mx+1),st)
      mx=mx+ncp
_ENDIF
      ig=ig+1
      guf(ig)=tum
      if(j.eq.k) go to 53
      if(dabs(sum).lt.thr) go to 54
      go to 55
53    if(dabs(sum-1.0d0) .lt.thr)  go to 54
55    write(jtape,56)i,j,k,sum,tum
56    format
     + (2x,'tran4: Warning - ir,i,j,overlap.ne.0,e-kin: ',3i5,2e20.8)
54    if (ig.lt.nod)go to 47
      write(ltape) guf
      if(oprint(32)) write(jtape,411) guf
      nt=nt+1
      ig=0
47    continue
45    mg=mg+iky(ng+1)
      write(ltape) guf
      if(oprint(32)) write(jtape,411) guf
411   format(2x,8e15.8)
c
      call rewftn(ntape)
      call rewftn(ltape)
      read(ltape)nsel,nj,ntil,nbal,isym,jsym,n,iorbs,knu,lsym,ncomp,e,c,
     1repel
      write(mtape)nsel,nj,ntil,nbal,isym,jsym,n,iorbs,knu,lsym,ncomp,e,c
     1,repel
      read(ltape)cf,ibal,itil,icf,mcomp,kj,mj,etot,icmo,ij,icore
      ns=0
      if(odebug)write(6,*) '101 - iorbs = ', iorbs
      do 101 i=1,n
      lj(i)=ns
      njx=ij(i)
101   ns=ns+iky(njx+1)
      iw=0
      lg=0
      do 102 i=1,n
      nai=ij(i)
      nip=isym(i)
      do 102 j=1,i
      naj=ij(j)
      njp=isym(j)
      nij=min(nip,njp)+iky(max(nip,njp))
      nij=jsym(nij)
      do 102 k=1,i
      nak=ij(k)
      nkp=isym(k)
      lim=k
      if(i.eq.k) lim=j
      do 102 l=1,lim
      iw=iw+1
      nit(iw)=lg
      nlp=isym(l)
      njj=min(nkp,nlp)+iky(max(nkp,nlp))
       njj=jsym(njj)
      if(nij.ne.njj) go to 102
      if(i.eq.j) go to 106
      isu=nai*naj
      if(i.eq.k) go to 107
      jsu=nak*ij(l)
108   lg=lg+isu*jsu
      go to 102
106   isu=iky(nai+1)
      if(i.eq.k) go to 107
      jsu=iky(nak+1)
      go to 108
107   lg=lg+isu*(isu+1)/2
102   continue
      iw=iw+1
      nit(iw)=lg
_IF1()c     write(jtape,334)
_IF1()c334  format(5x,' nit one- and two-electron array zeroes')
_IF1()c391  format(2x,15i8)
_IF1()c     write(jtape,391) (nit(i),i=1,iw),iw,lj
      write(mtape)nit,lj,kj,mj,ij,cf,icf,ibal,itil,mcomp,etot,icmo
     * ,icore
      do 109 i=1,nt
      read(ltape) guf
109   write(mtape) guf
      nrecy=nt+4
      call rewftn(ltape)
      call rewftn(mtape)
      read(mtape)nsel,nj,ntil,nbal,isym,jsym,n,iorbs,knu,lsym,ncomp,e,c,
     1repel
      read(mtape)nit,lj,kj,mj,ij,cf,icf,ibal,itil,mcomp,etot,icmo,
     * icore
      core=repel-etot
      nt=0
      if(odebug)write(6,*) '201 - iorbs = ', iorbs
      do 201 i=1,n
      jtil(i)=nt
      njx=ij(i)
201   nt=nt+njx
      if(odebug) then
       write(6,*)' transformation data to unit', ltape
       write(iwr,*) '***** first record to unit ', ltape
       write(iwr,*) 'n =',n
       write(iwr,*) 'nod =',nod
       write(iwr,*) 'jod =',jod
       write(iwr,*) 'icmo =',icmo
       write(iwr,*) 'nt =',nt
       write(iwr,*) 'kj  =',kj
       write(iwr,*) 'mj  =',mj
       write(iwr,*) 'ij  =',ij
       write(iwr,*) 'nj  =',nj
       write(iwr,*) 'nsel=',nsel
       write(iwr,*) 'ntil=',ntil
       write(iwr,*) 'nbal=',nbal
       write(iwr,*) 'isym = ', isym
       write(iwr,*) 'jsym = ', jsym
       write(iwr,*) 'iorbs= ',iorbs
       write(iwr,*) 'knu  = ',knu
       write(iwr,*) 'newya= ',newya
       write(iwr,*) 'ncomp= ',ncomp
       write(iwr,*) 'repel= ',repel
       write(iwr,*) 'etot= ',etot
      endif
      write(ltape)n,nod,jod,icmo,nt,kj,mj,ij,nj,nsel,ntil,
     +      nbal,isym,jsym,iorbs,knu,
     +      newya,lsym,ncomp,e,c,repel,etot
      if(odebug) then
       write(iwr,*) '***** second record *****'
       write(iwr,*) 'lj  =',lj
       write(iwr,*) 'ibal=',ibal
       write(iwr,*) 'itil=',itil
       write(iwr,*) 'mcomp=',mcomp
      endif
      write(ltape)nit,lj,cf,icf,ibal,itil,mcomp
c
      call rewftn(ntape)
      call rewftn(ltape)
      call rewftn(mtape)
      cpu=cpulft(1)
      if(.not.oprint(29)) write(jtape,8998)cpu ,charwall()
 8998 format(/
     *' end of transformation conversion at',f8.2,' seconds',
     +  a10,' wall'/)
      return
      end
_ENDEXTRACT
      subroutine nf3in(cf,icf,len,ltape,knu,iwr,odebug)
      implicit REAL  (a-h,o-z), integer (i-n)
      dimension cf(len), icf(len)
      logical odebug
INCLUDE(common/sizes)
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      REAL occatr
      common/scrtch/irm(mxcrec),ibal(8),itil(8),
     + mcomp(maxorb),e(ndime),c(4*maxat),nzer(maxorb),
     + tc(maxorb),rr(maxorb),occatr(maxorb),nfil(8),ndog(20),
     + jrm(126)
      common/bufb/nconf(5),lsym(8*maxorb),ncomp(maxorb),
     +mper(maxorb),intp(maxorb),intn(maxorb),jcon(maxorb),
     +nda(20),mj(8),mj2(12),ided(20),nj(8),kj(8),ntil(8),nbal(9),
     +idep(8),lj(8),nstr(5),nytl(5),nplu(5),ndub(5),
     +jtest(mxnshl),ktest(mxnshl),ibug(4),isym(8)
      common/scr1/repel,etot,nit(667),newya(maxorb),ij(8),n,
     +            jsym(36),iy(8)
      REAL occ
      common/blkorbs/value(maxorb),occ(maxorb+1),iorbs,
     *newbas,icmo,ivalue,iocc,ipad
c
      call rewftn(ltape)
c     1st record
      read(ltape) n,nod,jod,icmo,nt,
     +            kj,iy,lj,nj,nsel,
     +            ntil,nbal,isym,jsym,iorbs,knu,
     +            newya,lsym,ncomp,e,c,repel,etot
c
      if (odebug) then
       write(iwr,*) '***** first record from unit ', ltape
       write(iwr,*) 'n =',n
       write(iwr,*) 'nod =',nod
       write(iwr,*) 'jod =',jod
       write(iwr,*) 'icmo =',icmo
       write(iwr,*) 'nt =',nt
       write(iwr,*) 'kj  =',kj
       write(iwr,*) 'iy  =',iy
       write(iwr,*) 'ij  =',ij
       write(iwr,*) 'nj  =',nj
       write(iwr,*) 'nsel=',nsel
       write(iwr,*) 'ntil=',ntil
       write(iwr,*) 'nbal=',nbal
       write(iwr,*) 'isym = ', isym
       write(iwr,*) 'jsym = ', jsym
       write(iwr,*) 'iorbs= ',iorbs
       write(iwr,*) 'knu  = ',knu
       write(iwr,*) 'newya= ',newya
       write(iwr,*) 'ncomp= ',ncomp
       write(iwr,*) 'repel= ',repel
       write(iwr,*) 'etot= ',etot
      endif
c
c     2nd record
      read(ltape) nit,ij,cf,icf,ibal,itil,mcomp
      if (odebug) then
       write(iwr,*) '***** second record *****'
       write(iwr,*) 'ij  =',ij
       write(iwr,*) 'ibal=',ibal
       write(iwr,*) 'itil=',itil
       write(iwr,*) 'mcomp=',mcomp
      endif
c
      n = nsel
c
      call rewftn(ltape)
      return
      end
      subroutine iput_in (iput,
     + nconf4, nytl4, nplu4, ndub4, iswh4, m, imo4,
     + eneg36,odebug,iwr)
      implicit REAL  (a-h,p-z), integer (i-n)
c
      logical odebug
c
      parameter (maxroot =      50)
c momax  : max. # von mo's
      parameter (momax  =     256)
c nopmax : max. # offener schalen
      parameter (nopmax =      10)
c iswhm  : max. # von superkategorien
      parameter (iswhm  =       5)
cvp
c niot   : startadresse einer sk auf iot (konfigurationen nicht
c          transponiert)
c nconf  : # (selektierte) konfigurationen pro sk
c imo    : # mo's
c ibinom : binomialkoeffizienten
c nirred gibt an, in welcher irred. darst. ein mo ist
c mopos gibt die nummer eines mo's innerhalb einer irred. darst. an
c ndub   : # doppelt besetzte mo's pro konf. einer sk
c nytl   : # aller besetzten mo's pro konf. einer sk
c nod    : # einfach besetzte mo's pro konf. einer sk
c
      integer nconf4, nytl4, nplu4, ndub4, iswh4, imo4
      dimension nconf4(5), nytl4(5), nplu4(5)
      dimension ndub4(5)
c
      REAL eneg36
      dimension eneg36(4,*)
c
      integer niot,nconf,imo,ibinom,nirred,mopos
      integer nytl,ndub,nod
      common/rvergl/ niot(iswhm),nconf(iswhm),imo
     & ,ibinom(0:nopmax+1,0:nopmax+1)
     & ,nirred(momax),mopos(momax)
     & ,ndub(iswhm),nytl(iswhm)
     & ,nod(iswhm)
c
      integer nsac,nplu,idrem1
      dimension nplu(iswhm)
      common /rhus/ idrem1,nsac(iswhm),ndet(iswhm)
c
      integer kj,lj
      dimension lj(8),kj(8)
c-- koordinaten
      integer ibal,itil
      dimension ibal(8),itil(8)
      integer mcomp
      dimension mcomp(100)
      dimension b(232)
c --- alter common aus conmdi (teilweise)
      common /per/ ixt,i0,esav36(4,maxroot)
c
      data maxb/999999/
c
c     restore limited information from iput
c
      write(iwr,*)'*** restore ci-data from unit ', iput
      call rewftn(iput)
      read(iput)iwod,vnuc,zero,imo,m,nconf,
     +           nytl, nplu, ndub, iswh, ksum, iorbs,
     +           knu,
c      anzahl der atomkerne
     + ibal,itil,
cbe es scheint hier wurde mcomp und kj vergessen
     + mcomp,kj,
c      information koeffizienten, kerninformationen
     + lj,nn,ifrk,b
 
       if (odebug) then
        write(iwr,*) 'iwod=',iwod
        write(iwr,*) 'vnuc=',vnuc
        write(iwr,*) 'zero=',zero
        write(iwr,*) 'imo =',imo
        write(iwr,*) 'm   =',m
        write(iwr,*) 'iswh=',iswh
        write(iwr,*) 'ksum=',ksum
        write(iwr,*) 'ibal=',ibal
        write(iwr,*) 'itil=',itil
        write(iwr,*) 'kj  =',kj
        write(iwr,*) 'lj  =',lj
        write(iwr,*) 'ifrk=',ifrk
c
        write(iwr,*)'mcomp(1)=',mcomp(1)
        write(iwr,*)'nn=',nn
       endif
c
c      now restore information from conversion adapt and tran routines
c
       do loop = 1, 5
       nplu4(loop) = nplu(loop)
       ndub4(loop) = ndub(loop)
       nytl4(loop) = nytl(loop)
       nconf4(loop) = nconf(loop)
       enddo
       iswh4 = iswh
       imo4 = imo
       if(odebug) then
        write(iwr,*) 'imo =',imo4
        write(iwr,*) 'iswh =',iswh4
        write(iwr,*) 'nconf=',nconf4
        write(iwr,*) 'nytl=',nytl4
        write(iwr,*) 'nplu=',nplu4
        write(iwr,*) 'ndub=',ndub4
       endif
c
c     now restore the energetic data from iput ..
c     this is rather messy, and involves scanning to the end of
c     the data set, backspacing, and reading the last record
c
c     first determine no. of records to reach penultimate block
      loop = 0
      do i = 1, maxb
       read(iput,end=10,err=11) 
       loop = loop + 1
      enddo
      go to 11
 10   rewind iput
      do i = 1, loop
       read(iput)
      enddo
      read (iput,err=11) esav36
      call dcopy(maxroot*4,esav36,1,eneg36,1)
c
      call rewftn(iput)
c     position at beginning of second record
      read (iput) 
c
      return
11    call caserr('error processing ci wavefunction interface')
      end
      subroutine moment2(core,odebug)
      implicit REAL  (a-h,o-z), integer (i-n)
      logical odebug
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/discc)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
c
      integer nston, mtype, nhuk, ltape, ideli, ntab, mtapev
      integer nf88, iput, mousa, ifox
      integer lun20, lun21, lun22, lunalt
      integer lun01, lund, lun02, lun03, jtmfil
      common /ftap5/ nston, mtype, nhuk, ltape, ideli,
     +               ntab, mtapev, nf88, iput, mousa, ifox,
     +               lun20, lun21, lun22, lunalt,
     +               lun01, lund, lun02, lun03, jtmfil
c
      common/lsort/fac,acore,enee,ilifq(maxorb),iorbs,
     +             iswh,m,m2,mu,id,
     +             ni8,nj8,nk8,imo,ig,ksum,knu
c
      common/scr1/repel,etot,nit(667),newya(maxorb),ijj(8),n,
     +            jsym(36),iy(8)
      common/scrtch/bc(10*maxorb),cbb(10*maxorb),
     + x(maxorb),p(maxorb),r(maxorb),
     + ic(maxorb),ii(maxorb),ij(maxorb),ik(maxorb),
     + ispa4(maxat),ilife(maxorb),
     + ovl(3500),spc(19000),icu(22500),
     + ibal(8),itil(8),mcomp(maxorb),kj(8),lsym(8*maxorb),
     + nj(8),ntil(8),nbal(9),ispa,ncomp(maxorb),nzer(maxorb),
     + xdum(1300),
     + nconf(5),jconf(5),nytl(5),ndub(5),jtest(mxnshl),
     + nplu(5),itest(mxnshl),jytl(5),jdub(5),jplu(5),lj(8),
     + jcon(maxorb),irm(126),jrm(mxcrec),
     + intp(maxorb),intn(maxorb),
     + zeta(10*maxorb),d(10*maxorb),xorb(maxorb),yorb(maxorb),
     + zzorb(maxorb),anorm(maxorb),psep(6),pvec(3),dif(3),dif2(3),
     + wcxyz(4*maxat),t1(5),t2(5),t3(5),
     + zxf(11),zyf(11),zzf(11),alf(11),bf(5),af(6),
     + ci(126),cj(126),
     + di(48),dj(48),isym(8)
      parameter (maxroot=50)
      REAL enegx, enegs
      common/scra6/enegx(4,maxroot),enegs(4,maxroot)
      common/ctmn/iput1,idx,jput,jdx,nstate
      integer iselecx,izusx,iselect
      common /cselec/ iselecx(maxroot),izusx(maxroot),
     +                iselect(maxroot),nrootci,
     +                iselecz(maxroot)
c
      parameter (maxref=256)
      REAL edavit,cdavit,extrapit,eigvalr,cradd,
     +     weighb, rootdel, ethreshit
      integer mbuenk,nbuenk,mxroots
      logical ifbuen, ordel, odave, oweight, odavit
      common /comrjb2/edavit(maxroot),cdavit(maxroot),
     +                odavit(maxroot),
     +                extrapit(maxroot),ethreshit(maxroot),
     +                eigvalr(maxref),cradd(3),weighb,
     +                rootdel,ifbuen,mbuenk,mxroots,
     +                ordel,odave,nbuenk,oweight
c
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      dimension e(ndime)
      equivalence (e(1),bc(1))
c
      dimension core(*)
c
c ifox=36 default
c iwod=1000 (block size)
c vnuc is nuclear repulsion
c zero is total scf energy
c imo is no. of active mos
c m is no. of active electrons
c ksum is active+frozen mos
c iorbs is total mos (active+frozen+discarded)
c nconf(5) are number of selected configs (not safs) in last extr pass
c 
      write(iwr,3)yed(idaf),ibl3d
 3    format(/1x,104('=')//
     *40x,41('*')/
     *40x,'*** MRD-CI V2.0: Transition Moment Module'/
     *40x,41('*')//
     *1x,'dumpfile on ',a4,' at block',i6 )
      if(ibl3d.le.0) then
       call caserr('invalid starting block for dumpfile')
      endif
c
      if(num.le.0.or.num.gt.maxorb) call caserr(
     *'invalid number of basis functions')
c
      jdxini = jdx
      nstini = nstate
      if(ifbuen) then
c     reset nstate if greater than current nrootci
c     cover the two cases, allowing for previous
c     ground state calculation
       if(iput1.eq.jput) then
        if(nstate.gt.(nrootci-1)) then
         nstate = nrootci-jdx+1
        endif
       else
        if(nstate.gt.nrootci) then
         nstate = nrootci
        endif
       endif
      endif
c
c     first restore limited information from iput1
c
      call iput_in(iput1, nconf, nytl, nplu, ndub,
     +             iswh, m, imo, enegx, odebug,iwr)
c
c     now restore information from conversion adapt and tran routines
c     need space for cf and icf from transformation interface
c
      nbsq = num * num
      need = nbsq + lenint(nbsq)
      i5 = igmem_alloc(need)
      i6 = i5 + nbsq
      call nf3in1(core(i5),core(i6),nbsq,lunalt,iwr,odebug)
c
      if(iorbs.ne.num.or.imo.gt.ksum.or.ksum.gt.iorbs)
     * call caserr('invalid parameters on dumpfile')
c     call rewftn(ifox)
c
      lentot=ksum*iorbs
      lensq=imo*imo
      nxx=iorbs*(iorbs+1)/2
      i1=1
      i2=i1+lentot
      i3=i2+nxx
      i4=i3+lentot
      i7=i4+nbsq
c     for imat and jmat
      lenmat=100000
      i8=i7+lenmat
      need=i8+3780
      i1 = igmem_alloc(need)
      i2 = i1+lentot
      i3 = i2+nxx
      i4 = i3+lentot
      i7 = i4+nbsq
      i8 = i7+lenmat
c
      call tmn(core(i1),core(i2),core(i3),core(i1),
     +         core(i5),core(i6),
     +         nbsq,lentot,nxx,lensq,
     +         core(i7),lenmat,core(i8),odebug)
      call clredx
      call rewftn(iput1)
c
      call gmem_free(i1)
      call gmem_free(i5)
c
      jdx = jdxini
      nstate = nstini
c
      return
      end
      subroutine tmn(y,pig,dbq,q,
     +               cf,icf,lenf,lentot,lenbas,lensq,
     +               jmat,lenmat,imat,odebug)
      implicit REAL  (a-h,o-z), integer (i-n)
      logical odebug,oextrapx,oextrap
      dimension cf(lenf),icf(lenf)
      dimension y(lentot),dbq(lentot),pig(lenbas),q(lensq)
      dimension jmat(lenmat),imat(3780)
INCLUDE(common/sizes)
      character *1 dash,is
      character *4 stype
      logical onew
INCLUDE(common/prints)
INCLUDE(common/runlab)
INCLUDE(common/iofile)
      common/aaaa/icom(21)
c
c 10  = max primitives in one contracted gaussian !!
c ispa4 was introduced to map the mrdci order to gamess scf 
c order, set in the symmetry adaption .
c
      common/scrtch/bc(10*maxorb),cbb(10*maxorb),
     + x(maxorb),p(maxorb),r(maxorb),
     + ic(maxorb),ii(maxorb),ij(maxorb),ik(maxorb),
     + ispa4(maxat),ilife(maxorb),
     + ovl(500),dixf(500),diyf(500),dizf(500),xnab(500),ynab(500),
     + znab(500),spc(19000),
     + icu(22500),ibal(8),itil(8),
     + mcomp(maxorb),kj(8),lsym(8*maxorb),
     + nj(8),ntil(8),nbal(9),ispa,ncomp(maxorb),nzer(maxorb),
     + xdum(1300),
     + nconf(5),jconf(5),nytl(5),ndub(5),jtest(mxnshl),
     + nplu(5),itest(mxnshl),jytl(5),jdub(5),jplu(5),lj(8),
     + jcon(maxorb),irm(126),jrm(mxcrec),
     + intp(maxorb),intn(maxorb),
     + zeta(10*maxorb),d(10*maxorb),xorb(maxorb),yorb(maxorb),
     + zzorb(maxorb),anorm(maxorb),
     + psep(6),pvec(3),dif(3),dif2(3),
     + wc(maxat),wx(maxat),wy(maxat),wz(maxat),t1(5),t2(5),t3(5),
     + zxf(11),zyf(11),zzf(11),alf(11),bf(5),af(6),
     + ci(126),cj(126),di(48),dj(48)
c
      integer imap, ihog, jmap, jhog
      common /scra4/ imap(504),ihog(48),
     +               jmap(504),jhog(48)
      REAL fj, gj, f, g
      integer jkan, ikan
      common /scra5/ fj(1000), gj(500), 
     +                f(1000),  g(500),
     +              jkan(500), ikan(500)
c
      common/ftap5/ntaper(15),
     +             lun01, lund, lun02, lun03, jtmfil
c lun01 are one el integ in ao basis written in tm2
c lun02 are used only in this routine
c jtmfil is the unit to permit subsequent TM analysis
      common/ctmn/iput1,idx,jput,jdx,nstate
c
      integer maxroot
      parameter (maxroot=50)
      REAL enegx, enegs
      common/scra6/enegx(4,maxroot),enegs(4,maxroot)
c
      common/lsort/fac,acore,enee,ilifq(maxorb),iorbs,iswh,m,m2,mu,id
     *,ni8,nj8,nk8,imo,ig,ksum,knu
      common/scr1/repel,etot,nit(667),newya(maxorb),ijj(8),n,
     +            jsym(36),iyy(8)
      dimension bloc(9100),ovm(1300)
      dimension xm(1300),ym(1300),zm(1300)
      dimension xam(1300),yam(1300),zam(1300)
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      dimension e(ndime),dihf(3500)
c
      dimension new(maxorb),stype(35),inumb(35),is(5)
      dimension icen(maxorb)
      character*10 charwall
      equivalence (e(1),bc(1),bloc(1))
      equivalence (dihf(1),ovl(1)),(bloc(1),ovm(1)),
     + (bloc(1301),xm(1)),(bloc(2601),ym(1)),(bloc(3901),zm(1)),
     + (bloc(5201),xam(1)),(bloc(6501),yam(1)),(bloc(7801),zam(1))
c
      data d5,dash/1.0d-5,'-'/
      data inumb/0,25,5,1,30,26,6,50,10,2,
     +  31,55,51,35,11,27,7,75,15,3,
     +  56,36,32,60,52,12,80,76,40,16,28,8,100,20,4/
      data stype/
     *'s','x','y','z','xy','xz','yz','xx','yy','zz',
     +'xyz','xxy','xxz','xyy','yyz','xzz','yzz','xxx','yyy','zzz',
     +'xxyz','xyyz','xyzz','xxyy','xxzz','yyzz',
     +'xxxy','xxxz','xyyy','yyyz','xzzz','yzzz',
     +'xxxx','yyyy','zzzz'/
      data is/'s','p','d','f','g'/
c
      ind(i,j)=max(new(i),new(j))*
     + (max(new(i),new(j))-1)/2 + min(new(i),new(j))
c
      cpu=cpulft(1)
      write(iwr,9000)cpu ,charwall()
 9000 format(/' *** commence moment evaluation at ',f8.2,
     * ' seconds',a10,' wall')
      istont=0
      if(iput1.le.0.or.jput.le.0)call caserr(
     *'invalid fortran stream specified for ci vector')
      call rewftn(lun03)
      call rewftn(lun01)
      call rewftn(lun02)
c
      irbmax=maxorb
      mmax=90
      ksmax=maxorb
c
c     save initial value of jdx for potential re-entry to routine
c
      jdxini = jdx
c
c jd= block length on lun02 file
      jd=1300
      id=500
      fack=8066.0d0
      ev=27.211d0
      amult=2.02592d-6
      t1(1)=4.0d0
      t2(1)=2.0d0
      t3(1)=0.5d0
      j=1
      do 128 i=2,5
      j=j+2
      t1(i)=(t1(i-1)*4)/j
      t3(i)=t3(i-1)*j*0.5d0
  128 t2(i)=dsqrt(t1(i))
      fac=2.0d0**1.5d0
c
c     read(iput1)iwod,vnuc,zero,imo,m,nconf,newya,
c    *nytl,nplu,ndub,iswh,ksum,
c    1iorbs,knu,cf,icf,wc,wx,wy,wz,ibal,itil,mcomp,kj,lj,n,ifrk,e,lsym,
c    2 nsel,nj,ntil,nbal,ncomp
c
      iflw=imo*imo
      icore=ksum-imo
      write(iwr,36)iput1,idx,ztitle,jput,jdx,nstate,
     * iorbs,imo,icore,m
 36   format(/
     *' location of ground state ci vector on ft',i2,7x,i3/
     *' case : ',10a8//
     *' excited state vector(s) reside on ft',i2/
     *' location of first excited state vector           ',i3/
     *' number of excited state vectors to be treated    ',i3/
     *' number of contracted a.o. basis functions        ',i3/
     *' number of active orbitals                        ',i3/
     *' number of frozen orbitals                        ',i3/
     *' number of correlated electrons                   ',i3)
      if(oprint(32))write(iwr,9004)
 9004 format(/
     *' print out of basis orbitals requested')
      do 900 i=1,iorbs
      new(i)=0
900   continue
c     do 31 i=1,iorbs
c31   new(newya(i))=i
      call prpind(wx,wy,wz,ispa4,newya,new,iorbs,knu,iwr)
      onew=.false.
      do 910 i=1,iorbs
      if(new(i).ne.i) onew=.true.
910   continue
      if(onew) then
       if(oprint(32)) then
       write(iwr,*)' tm: array "new" is NOT identical permutation'
       write(iwr,32)(new(i),i=1,iorbs)
32     format(20i5)
       endif
      else
      if(oprint(32))write(iwr,*)
     +              ' tm: array "new" is identical permutation'
      endif
      if(oprint(32)) write(iwr,9997)
 9997 format(/29x,'geometry (a.u.)'//
     *8x,'x',15x,'y',15x,'z',17x,'charge'/)
      if(oprint(32)) then
       do 9001 j=1,knu
 9001  write(iwr,9002)wx(j),wy(j),wz(j),wc(j)
      endif
 9002 format(4f16.7)
      if(oprint(32)) write(iwr,9003)knu
 9003 format(/' no. of nuclei = ',i3)
      if(oprint(32)) write(iwr,9020)iorbs
 9020 format(/' *** basis function specification'//
     *' no. of gtos = ',i3//
     *7x,'ordered list of basis functions'/)
      do 9021 i=1,iorbs
      kk=new(i)
      x0=x(kk)
      y0=p(kk)
      z0=r(kk)
      do 9022 j=1,knu
      if  ( (dabs(x0-wx(j)).lt.d5) .
     * and. (dabs(y0-wy(j)).lt.d5) .
     * and. (dabs(z0-wz(j)).lt.d5) ) go to 9023
 9022 continue
      call caserr(
     *'attempt to cite basis function on unknown centre')
 9023 icen(kk)=j
      j=ii(kk)*25+ij(kk)*5+ik(kk)
      do 9024 k=1,35
      if(j.eq.inumb(k))go to 9025
 9024 continue
      call caserr(
     *'basis function of unknown type detected')
 9025 if(k.eq.1)j=1
      if(k.gt.1.and.k.le.4)j=2
      if(k.gt.4.and.k.le.10)j=3
      if(k.gt.10.and.k.le.20)j=4
      if(k.gt.20.and.k.le.35)j=5
      if(k.gt.35) then
        call caserr('impossible: k.gt.35')
      endif
      l=ic(kk)
      if(oprint(32)) write(iwr,9026)i,icen(kk),is(j),stype(k)
      if(oprint(32)) then
      kkkk = ilife(kk)
      do 9028 j=1,l
 9028 write(iwr,9002)cbb(kkkk+j),bc(kkkk+j)
      endif
 9021 continue
c
c save important information for tmatrix conversion 
c to cartesian representation
c
      if(jtmfil.ne.0) then
      call rewftn(jtmfil)
      write(jtmfil) nstate,iorbs,imo,icore,m,knu
c  geometry
      write(jtmfil) (wc(j),j=1,knu)
      write(jtmfil) (wx(j),j=1,knu)
      write(jtmfil) (wy(j),j=1,knu)
      write(jtmfil) (wz(j),j=1,knu)
c
c  basis
c     new is permutation of 1..iorbs
c  we will better permute the molcao coefficients with newya
c
c     write(jtmfil) (new(j),j=1,iorbs)
      write(jtmfil) (j,j=1,iorbs)
c centers
      write(jtmfil) (icen(j),j=1,iorbs)
c x,y,z exponents
      write(jtmfil) (ii(j),j=1,iorbs)
      write(jtmfil) (ij(j),j=1,iorbs)
      write(jtmfil) (ik(j),j=1,iorbs)
c number of primitives
      write(jtmfil) (ic(j),j=1,iorbs)
c contraction coefficients and exponents
      do 8000, j=1,iorbs
      kkkk = ilife(j)
      do 8001, k=1,ic(j)
      write(jtmfil) cbb(kkkk+k),bc(kkkk+k)
8001  continue
8000  continue
c
      endif
c
      write(iwr,9009)(dash,j=1,104)
 9009 format(/1x,104a1)
 9026 format(/
     *' orbital centre   type sub-type'/
     *i8,i7,4x,a1,7x,a4//
     *11x,'ctran',12x,'zeta')
      jy=0
      do 450 i=1,iorbs
      nzer(i)=jy
450   jy=jy+ncomp(i)
      jy=0
      ma=0
      ibuk=0
      jcl=icore*iorbs
      do 451 i=1,n
      k2=kj(i)
      k4=k2-lj(i)
      kx=ntil(i)
       do 451 j=1,k2
       if(j.gt.k4) go to 452
       j8=ibuk
       k5=j8+1
       ibuk=ibuk+iorbs
       jt=ibuk
       go to 453
 452   j8=jcl
       k5=jcl+1
       jcl=jcl+iorbs
       jt=jcl
453    do 454 k=k5,jt
454    y(k)=0.0d0
       ma=ma+1
       ll=mcomp(ma)
       do 455 k=1,ll
       jy=jy+1
       vm=cf(jy)
       nxx=icf(jy)+kx
       lx=nzer(nxx)
       nxx=ncomp(nxx)
       do 455 l=1,nxx
       lx=lx+1
       ifj=lsym(lx)
       if(ifj.gt.0) go to 456
       y(j8-ifj)=-vm
       go to 455
456    y(j8+ifj)=vm
455    continue
451    continue
c
c  save y(ao,mo) coeffs - coeffs of transformed mos to aos
c  core and discarded orbitals are skipped and the rest is sorted 
c  according to irreps
c  in AO the order is like in the scf printout , or like here
c  in increasing order with indirection through the array newya()
c
c the permutation new is usually identity, but does not have to be
c
c  arrays cf and icf contain only those coefficients which are finite
c  due to the symmetry and they are kept only with one sign
c  you can have a look at the transformation above
c  the coefficients refer to normalised contracted gaussians
c
c when omitting the permutation new, molcao coefs are in the 
c following order:
c mo index: mrdci numbering(as in configuration specification)
c ao index: scf numbering permuted through newya
c
c the tmat plotting will be shielded from it by permuting molcao 
c coefs when saving them to tmfile 
c (by inverse permutation the the one discussed above)
c
      if(jtmfil.ne.0) then
      write(iwr,*)' molcao coefficients written to tmfile',jtmfil
      if(oprint(32)) then 
       write(iwr,*)' 1st index is active mo no. in mrdci convention'
       write(iwr,*)' 2nd index is ao in the usual scf ordering'
      endif
      ibase=icore*iorbs
      do 8004,i=1,imo
      write(jtmfil)(y(ibase+newya(j)),j=1,iorbs)
      if(oprint(32)) then
         do 9091,j=1,iorbs
9091     write(iwr,*)'i,j,newya(j),y(newya(j),i) ',
     +    i,j,newya(j),y(ibase+newya(j))
      endif
      ibase=ibase+iorbs
8004  continue
      endif
c
      zbx=0.0d0
      zby=0.0d0
      zbz=0.0d0
      do 901 i=1,knu
      c=wc(i)
      zbx=zbx+c*wx(i)
      zby=zby+c*wy(i)
  901 zbz=zbz+c*wz(i)
      write (iwr,902) zbx,zby,zbz
  902 format(/'  nuclear dipole components : ',3f15.8)
      if (iorbs.gt.irbmax) go to 750
      if (m.gt.mmax) go to 750
      if (ksum.gt.ksmax) go to 750
      j=0
c set column pointers, one column after another
      do 148 i=1,imo
      ilifq(i)=j
 148  j=j+imo
      if (iput1.ne.jput) then
c
       call rewftn(jput)
c     process variables from excited state file
c     read (jput) iwod,vnuc,zero,jmo,m2,jconf,newya,jytl,
c    * jplu,jdub,iswh,jsum,jorbs,knu,df
c     note .. not all the above variables are now available
       call iput_in(jput, jconf, jytl, jplu, jdub,
     +              iswh, m2, jmo, enegs, odebug,iwr)
       jcore=ksum-jmo
       if (jmo.ne.imo) go to 751
       if (jcore.ne.icore) go to 752
       if (m2.ne.m) go to 755
c
      else
c     excited state and ground state vectors are on same file
       call dcopy(maxroot*4,enegx,1,enegs,1)
      endif
c
      call tm2n(jmat,lenmat,imat)
c necessary integrals calculated
      fcorx=0.0d0
      fcory=0.0d0
      fcorz=0.0d0
       iaa=iorbs*(iorbs+1)/2
       iorq=imo*(imo+1)/2
       iblk=(iaa-1)/id
       ires=iaa-iblk*id
       iblk=iblk+1
       iors=ksum*iorbs
       ixy=icore*iorbs
       call rewftn(lun02)
       iy=-id
       do 812 ma=1,7
       call rewftn(lun01)
       iy=iy+id
       ig=0
       iend=id
       do 813 i=1,iblk
       read(lun01) dihf
       if(i.eq.iblk) iend=ires
       jy=iy
       do 813 j=1,iend
       ig=ig+1
       jy=jy+1
 813   pig(ig)=dihf(jy)
       call vclr(dbq,1,iors)
       do 815 i=1,iorbs
       do 815 j=1,i
       jab=ind(i,j)
       big=pig(jab)
       if(dabs(big).lt.1.0d-14) go to 815
       kab=-iorbs
       do 816 k=1,ksum
       kab=kab+iorbs
       ig=kab+i
       jg=kab+j
       dbq(jg)=dbq(jg)+big *y(ig)
       if(i.eq.j) go to 816
       if(ma.gt.4) go to 216
       dbq(ig)=dbq(ig)+big*y(jg)
        go to 816
216    dbq(ig)=dbq(ig)-big*y(jg)
816   continue
815   continue
       kab=0
       jdx0 = jdx
       if(icore.eq.0) go to 817
c no core orbitals
       if(ma.eq.1.or.ma.gt.4) go to 822
       if(ma-3) 818,819,820
818    do 821 i=1,icore
_IF1()       do 821 j=1,iorbs
_IF1()       kab=kab+1
_IF1()821    fcorx=fcorx+y(kab)*dbq(kab)
      fcorx=fcorx+ddot(iorbs,y(kab+1),1,dbq(kab+1),1)
 821  kab=kab+iorbs
       go to 817
822    kab=kab+ixy
       go to 817
819    do 823 i=1,icore
_IF1()       do 823 j=1,iorbs
_IF1()       kab=kab+1
_IF1()823    fcory=fcory+y(kab)*dbq(kab)
      fcory=fcory+ddot(iorbs,y(kab+1),1,dbq(kab+1),1)
 823  kab=kab+iorbs
       go to 817
820    do 824 i=1,icore
_IF1()       do 824 j=1,iorbs
_IF1()       kab=kab+1
_IF1()824    fcorz=fcorz+y(kab)*dbq(kab)
      fcorz=fcorz+ddot(iorbs,y(kab+1),1,dbq(kab+1),1)
 824  kab=kab+iorbs
817    jg=0
       mdx=kab
       do 825 i=1,imo
       ldx=kab
       do 826 j=1,i
       mdy=mdx
       jg=jg+1
       sum=0.0d0
       do 827 k=1,iorbs
       mdy=mdy+1
       ldx=ldx+1
 827   sum=sum+y(mdy)*dbq(ldx)
       xdum(jg)=sum
c here is the multiplication with molcao coefs
       if(jg.lt.jd) go to 826
       write(lun02) xdum
       jg=0
 826   continue
 825   mdx=mdy
       if(jg.gt.0) write(lun02) xdum
 812   continue
       iblk=(iorq-1)/jd
       ires=iorq-iblk*jd
       iblk=iblk+1
       fcorx=fcorx+fcorx
       fcory=fcory+fcory
       fcorz=fcorz+fcorz
       write(iwr,603) fcorx,fcory,fcorz
603    format(/5x,'core dipole components : ',3f15.8)
c
c subtract the nuclear component (which should be zero because of 
c standard orientation with [0,0,0] in the charge centre
c but even if the molecule is shifted, it must be multiplied with the
c overlap, which is zero
c
       fcorx=fcorx-zbx
       fcory=fcory-zby
       fcorz=fcorz-zbz
      if (idx.eq.1) go to 50
      idy=idx-1
      do 45 i=1,idy
      do 51 j=1,iswh
      nc=nconf(j)
      if (nc.eq.0) go to 51
      read(iput1) nhb, imax
c      if (mod(nc,imax).eq.0)then
c       nhb = nhb + 1
c      endif
      do 52 k=1,nhb
52    read(iput1)
51    continue
45    continue
   50 do 57 j=1,iswh
      if (nconf(j).eq.0) go to 57
      read(iput1)nhb,imax,ndt,kml,imap,ihog,eneg
c     if (mod(nconf(j),imax).eq.0)then
c      nhb = nhb + 1
c     endif
      write(lun03)nhb,imax,ndt,kml,imap,ihog
      do 58 k=1,nhb
      read(iput1) jkan,f,g
58    write(lun03) jkan,f,g
   57 continue
      if (iput1.ne.jput) go to 60
      do 66 i=1,iswh
      jconf(i)=nconf(i)
      jytl(i)=nytl(i)
      jdub(i)=ndub(i)
66    jplu(i)=nplu(i)
 60   if(iput1.eq.jput)jdx=jdx-idx
      if (jdx.eq.1) go to 64
      jdy=jdx-1
      do 65 i=1,jdy
      do 69 j=1,iswh
      nc=jconf(j)
      if (nc.eq.0) go to 69
      read(jput) nhb,imax
c     if (mod(nc,imax).eq.0)then
c      nhb = nhb + 1
c     endif
      do 70 k=1,nhb
70    read(jput)
69    continue
65    continue
c
64    continue
c
c  here is the main loop for all states treated
c
c  extract energetics of lower state (idx)
c
      if(dabs(enegx(1,idx)).gt.1.0d-4) then
       oextrapx = .true.
      else
       write(iwr,8603)
 8603  format(/1x,
     +  'warning ** extrapolated energies for lower state are not',
     +  ' available - use ci energies')
       oextrapx = .false.
      endif
c
      do 200 i=1,nstate
      istate = jdx0+i-1
      oextrap = .true.
      write(iwr,9030)i
 9030 format(/1x,104('-')//40x,43('-')/
     *40x,'moment calculation for excited state no.',i3/
     *40x,43('-')/)
c
c  extract energetics of upper state (jdx+i-1)
c
      if (oextrapx) then
       write(iwr,8600) enegx(1,idx),enegx(2,idx),enegx(3,idx),
     +                 enegx(4,idx)
 8600  format(1x,'ground state'/
     +        1x,'++++++++++++'/
     +        10x,'CI energy           = ',f15.8, ' hartree '/
     +        10x,'extrapolated energy = ',f15.8, ' hartree '/
     +        10x,'Davidson energy     = ',f15.8, ' hartree '/
     +        10x,'c**2                = ',f10.4/)
c
       if(dabs(enegs(1,istate)).gt.1.0d-4) then
        write(iwr,8601) enegs(1,istate),enegs(2,istate),
     +                  enegs(3,istate),enegs(4,istate)
 8601   format(1x,'excited state'/
     +         1x,'+++++++++++++'/
     +         10x,'CI energy           = ',f15.8, ' hartree '/
     +         10x,'extrapolated energy = ',f15.8, ' hartree '/
     +         10x,'Davidson energy     = ',f15.8, ' hartree '/
     +         10x,'c**2                = ',f10.4/)
       else
        oextrap = .false.
        write(iwr,8604)
 8604   format(/1x,
     +  'warning ** extrapolated energies for upper state are not',
     +  ' available - use ci energies')
       endif
      endif
c
      acore=0.0d0
      call vclr(q,1,iflw)
      call tm3n(q,jmat,lenmat,imat,lensq)
      if (oextrapx. and. oextrap) then
       eneg = enegx(2,idx)
       enee = enegs(2,istate)
       enegd = enegx(3,idx)
       eneed = enegs(3,istate)
      endif
      write(iwr,499) acore
499   format(/2x,'overlap between upper and lower state is',f20.16)
      if(oprint(32)) then
      write(iwr,299)
 299  format(/
     *40x,'transition density matrix'/40x,25('-'))
c          in mrd-ci frozen, discarded and reordered mo basis
      call writem(q,ilifq,imo,imo)
      endif
c
c save tmat for this state
c
      if(jtmfil.ne.0) then
c write in columns
      do 8003,j=1,imo
      jpoint=ilifq(j)
      write(jtmfil) (q(k+jpoint),k=1,imo)
8003  continue
      endif
c     Relative energies based on Extrapolated Energies
      del=enee-eneg
      delv=del*ev
      delc=delv*fack
      write(iwr,501) eneg,enee,del,delv,delc
      if (dabs(del).gt.1.0d-10) then
        write(iwr,504) 45.564d0/del
      endif
 501  format(//
     +  1x,'transition energy data (Extrapolated Energies)'/
     *  1x,'=============================================='//
     *' total ci energy of ground state   ',f16.6,' hartree'/
     *' total ci energy of excited state  ',f16.6,' hartree'//
     *' excitation energy                 ',f16.6,' hartree'/
     *' excitation energy                 ',f16.6,' e.v.'/
     *' excitation energy                 ',f16.6,' cm-1')
 504  format(
     *' excitation wavelength             ',f16.6,' nm'/)
c
c     Relative energies based on Davidson Energies
      deld=eneed-enegd
      delvd=deld*ev
      delcd=delvd*fack
      write(iwr,5501) enegd,eneed,deld,delvd,delcd
      if (dabs(deld).gt.1.0d-10) then
        write(iwr,5504) 45.564d0/deld
      endif
5501  format(/
     +  1x,'transition energy data (Davidson Energies)'/
     *  1x,'=========================================='//
     *' Davidson energy of ground state   ',f16.6,' hartree'/
     *' Davidson energy of excited state  ',f16.6,' hartree'//
     *' excitation energy                 ',f16.6,' hartree'/
     *' excitation energy                 ',f16.6,' e.v.'/
     *' excitation energy                 ',f16.6,' cm-1')
5504  format(
     *' excitation wavelength             ',f16.6,' nm'/)
c
      x1g=acore*fcorx
      x2g=acore*fcory
      x3g=acore*fcorz
c the core and nuclear contributions are multiplied by the overlap
c nuclear was added to the core somewhere above
      y1g=0.0d0
      y2g=0.0d0
      icam=0
      iend=jd
      y3g=0.0d0
      ig=jd
      write(iwr,9009)(dash,j=1,60)
      if(oprint(32))then
        finthr=0.01d0
      else
        finthr=0.1d0
      endif
      write(iwr,9031) finthr
 9031 format(//' finite contributions to oscillator strengths '/
     + ' (threshold is |d(k|l)| >= ',f6.3,' )'/1x,80('-')///
     *6x,'i',4x,'j',8x,'d(i,j)',14x,'x',14x,'y',14x,'z',
     *9x,'del<x>',9x,'del<y>',9x,'del<z>',14x,'s'/5x,127('-')//)
c
c use tmat and integrals to calculate contributions
c loops only for 1 triangle, but checks both 
c jk and kj element if k.ne.j
c
      do 502 j=1,imo
      iaf=ilifq(j)
      do 502 k=1,j
      iag=iaf+k
c row k column j -th element
      cp=q(iag)
      if(ig.lt.jd) go to 830
      icam=icam+1
       call rewftn(lun02)
      if(icam.eq.iblk) iend=ires
      ig=0
      kz=-jd
      do 832 lc=1,7
      kz=kz+jd
      do 831 l=1,iblk
      if(l.eq.icam) go to 833
      read(lun02)
      go to 831
833   read(lun02)xdum
      lz=kz
      do 834 ld=1,iend
      lz=lz+1
834   bloc(lz)=xdum(ld)
831   continue
832   continue
830   ig=ig+1
      if (dabs(cp).gt.finthr)
     +  write(iwr,505)j,k,cp,xm(ig),ym(ig),zm(ig),
     +                  xam(ig),yam(ig),zam(ig),ovm(ig)
  505 format(2x,2i5,8f15.6)
      if (j.eq.k) go to 503
      jaf=ilifq(k)+j
      cq=q(jaf)
      if (dabs(cq).gt.finthr)
     +  write(iwr,505) k,j,cq,xm(ig),ym(ig),zm(ig),xam(ig),
     +                   yam(ig),zam(ig),ovm(ig)
      cplu=cp+cq
      cmin=cp-cq
      x1g=x1g+xm(ig)*cplu
      x2g=x2g+ym(ig)*cplu
      x3g=x3g+zm(ig)*cplu
      y1g=y1g+xam(ig)*cmin
      y2g=y2g+yam(ig)*cmin
      y3g=y3g+zam(ig)*cmin
      go to 502
503   x1g=x1g+xm(ig)*cp
      x2g=x2g+ym(ig)*cp
      x3g=x3g+zm(ig)*cp
502   continue
      delc=delc*delc*delc*amult
      x1h=x1g*x1g
      y1h=x2g*x2g
      z1h=x3g*x3g
      x1q=delc*x1h
      y1q=delc*y1h
      z1q=delc*z1h
      dbt=x1h+y1h+z1h
      dct=dbt*delc
      write (iwr,2010)
 2010 format(/8x,3h(x),12x,3h(y),12x,3h(z))
      write(iwr,700)x1g,x2g,x3g
700   format(/2x,7f15.6)
      write (iwr,2015)
 2015 format(/8x,4h(x)2,11x,4h(y)2,11x,4h(z)2,12x,3hsum )
      write(iwr,700) x1h,y1h,z1h,dbt
      write(iwr,701)
 701  format(/
     *' dipole transition probability and life-time (tau)'
     */1x,49('-'))
      write(iwr,702)x1q,y1q,z1q,dct
      tau=1.0d0/max(dct,1.0d-10)
      if (dct.ge.1.0d-10) then
        write(iwr,703)tau
      else
        write(iwr,704)'>',tau
      endif
 702  format(/
     *'      dx       ',5x,e15.6/
     *'      dy       ',5x,e15.6/
     *'      dz       ',5x,e15.6//
     *' dtotal (sec-1)',5x,e15.6//)
 703  format(
     *' tau (sec)     ',5x,e15.6/)
 704  format(
     *' tau (sec)     ',a5,e15.6/)
      fun=del/1.5d0
      x1h=fun*x1h
      y1h=fun*y1h
      z1h=fun*z1h
      ftt=fun*dbt
      write (iwr,2016)
 2016 format(' oscillator strengths -- dipole length operator'/
     *1x,46('-')//
     *9x,'fx',13x,'fy',13x,'fz',13x,'f(r)')
      write(iwr,700) x1h,y1h,z1h,ftt
      write (iwr,2060)
 2060 format(/8x,'delx',11x,'dely',11x,'delz')
      write(iwr,700) y1g,y2g,y3g
      y1g=y1g*y1g
      y2g=y2g*y2g
      y3g=y3g*y3g
      ftt=y1g+y2g+y3g
      write (iwr,2061)
 2061 format(/8x,5hdelx2,10x,5hdely2,10x,5hdelz2,11x,3hsum)
      write(iwr,700) y1g,y2g,y3g,ftt
      write (iwr,2062)
 2062 format(//' oscillator strengths -- dipole velocity operator'
     +/1x,48('-')//
     *8x,'fx(del)',8x,'fy(del)',8x,'fz(del)',11x,'f(del)')
      fun=1.0d0/(1.5d0*del)
      y1g=fun*y1g
      y2g=fun*y2g
      y3g=fun*y3g
      ftt=fun*ftt
      write(iwr,700) y1g,y2g,y3g,ftt
200   continue
c
c     restore initial value of jdx 
c
      jdx = jdxini
c
      call rewftn(lun03)
      call rewftn(lun01)
      call rewftn(lun02)
      if(iput1.ne.jput) call rewftn(jput)
      cpu=cpulft(1)
      write(iwr,8002)cpu ,charwall()
 8002 format(/' *** end of moment calculation at ',f8.2,
     *' seconds',a10,' wall'/)
      return
750   write(iwr,758)iorbs,m,ksum
 758  format(//
     *' dimensioning error has occurred'//
     *' no. of basis functions                   ',i3//
     =' no. of correlated electrons              ',i3//
     *' no. of core+active orbitals              ',i3//)
      call caserr('dimensioning error has occurred')
751   write(iwr,759) jmo,imo
 759  format(//
     *' inconsistent number of active orbitals'/
     *' no. of active orbitals in excited state ',i3//
     *' no. of active orbitals in  ground state ',i3//)
      call caserr('inconsistent number of active orbitals')
752   write(iwr,760) icore,jcore
 760  format(//
     *' inconsistent number of frozen core orbitals'/
     *' no. of frozen orbitals in ground state ',i3//
     *' no. of frozen orbitals in excited state',i3//)
      call caserr('inconsistent no. of frozen core orbitals')
755   write(iwr,763)m2,m
 763  format(//
     *' inconsistent number of correlated electrons'//
     *' number of active electrons in excited state',i3//
     *' number of active electrons in  ground state',i3//)
      call caserr('inconsistent number of correlated electrons')
      return
      end
      subroutine tm2n(jmat,lenmat,imat)
      implicit REAL  (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
      dimension jmat(lenmat),imat(3780)
      common/aaaa/icom(21)
      common/scrtch/bc(10*maxorb),cbb(10*maxorb),
     + x(maxorb),p(maxorb),r(maxorb),
     + ic(maxorb),ii(maxorb),ij(maxorb),
     + ik(maxorb),ispa4(maxat),ilife(maxorb),
     + ovl(500),dixf(500),diyf(500),dizf(500),xnab(500),ynab(500),
     + znab(500),spc(19000),
     + icu(22500),ibal(8),itil(8),mcomp(maxorb),kj(8),lsym(8*maxorb),
     + nj(8),ntil(8),nbal(9),ispa,ncomp(maxorb),nzer(maxorb),
     + xdum(1300),
     + nconf(5),jconf(5),nytl(5),ndub(5),jtest(mxnshl),
     + nplu(5),itest(mxnshl),jytl(5),jdub(5),jplu(5),lj(8),
     + jcon(maxorb),irm(126),jrm(mxcrec),
     + intp(maxorb),intn(maxorb),
     + zeta(10*maxorb),d(10*maxorb),xorb(maxorb),yorb(maxorb),
     + zorb(maxorb),anorm(maxorb),psep(6),pvec(3),dif(3),dif2(3),
     + wc(maxat),wx(maxat),wy(maxat),wz(maxat),t1(5),t2(5),t3(5),
     + zxf(11),zyf(11),zzf(11),alf(11),bf(5),af(6),
     + ci(126),cj(126),di(48),dj(48)
c
      common/ftap5/ntaper(15),
     +             lun01, lund, lun02, lun03, jtmfil
      common/ctmn/iput1,idx,jput,jdx,nstate
      common/lsort/fac,acore,enee,ilifq(maxorb),iorbs,iswh,m,m2,mu,id
     *,ni8,nj8,nk8,imo,ig
c
      dimension bloc(9100),ovm(1300)
      dimension xm(1300),ym(1300),zm(1300),xam(1300),yam(1300)
      dimension zam(1300),dihf(3500)
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      dimension e(ndime)
      integer imap, ihog, jmap, jhog
      common /scra4/ imap(504),ihog(48),
     +               jmap(504),jhog(48)
      REAL fj, gj, h, f, g
      integer jkan, ikan
      common /scra5/ fj(1000), gj(500), h(100),
     +                f(1000),  g(500),
     +              jkan(500), ikan(500)
c
      equivalence (e(1),bc(1),bloc(1))
      equivalence (dihf(1),ovl(1)),(bloc(1),ovm(1)),
     + (bloc(1301),xm(1)),(bloc(2601),ym(1)),(bloc(3901),zm(1)),
     + (bloc(5201),xam(1)),(bloc(6501),yam(1)),(bloc(7801),zam(1))
c
      thrs=140.0d0
      mm=0
      m2=m+2
      mu=m-2
      do 101 k=1,iorbs
      lco=ic(k)
      mi2=ii(k)
      t1f=fac
      if(mi2.gt.0) t1f=t1f*t2(mi2)
      mj2=ij(k)
      if(mj2.gt.0) t1f=t1f*t2(mj2)
      mk2=ik(k)
      if(mk2.gt.0) t1f=t1f*t2(mk2)
      max=mi2
      if(max.lt.mj2) max=mj2
      if(max.lt.mk2) max=mk2
      mi3=mi2+1
      mj3=mj2+1
      mk3=mk2+1
      fun=mi2+mj2+mk2
      farx=0.5d0*fun+0.75d0
       gun=fun*0.5d0
      mi4=mi2*(mi2-1)/2
      mj4=mj2*(mj2-1)/2
      mk4=mk2*(mk2-1)/2
      x0=x(k)
      y0=p(k)
      z0=r(k)
      kkk = ilife(k)
      kkkk = kkk
      do 4 l=1,lco
      zeta(l+kkkk)=bc(kkk+l)
   4  d(l+kkkk)   =cbb(kkk+l)
      xorb(k)=x0
      yorb(k)=y0
      zorb(k)=z0
      sum=0.0d0
      do 550 l=1,lco
      a1=zeta(l+kkkk)
      ga=d(l+kkkk)*(a1**(0.75d0+gun))
      do 550 l2=1,lco
      b=zeta(l2+kkkk)
      gb=dsqrt(b)/(a1+b)
  550 sum=sum+ga*d(l2+kkkk)*(gb**(1.5d0+fun))
      sum=sum*fac*(2.0d0**fun)
      anorm(k)=1.0d0/dsqrt(sum)
      t1f=t1f*anorm(k)
      do 102 l=1,k
      mm=mm+1
      llll = ilife(l)
      ni3=ii(l)
      nj3=ij(l)
      nk3=ik(l)
      suma=0.0d0
      sumb=0.0d0
      sumc=0.0d0
      sumd=0.0d0
      sume=0.0d0
      sumf=0.0d0
      sumg=0.0d0
      t2f=t1f*anorm(l)
      if(ni3.gt.0) t2f=t2f*t2(ni3)
      if(nj3.gt.0) t2f=t2f*t2(nj3)
      if(nk3.gt.0) t2f=t2f*t2(nk3)
      fbrx=0.5d0*(ni3+nj3+nk3)+0.75d0
      nax=ni3
      if(nax.lt.nj3) nax=nj3
      if(nax.lt.nk3) nax=nk3
      nax=nax+1
      x5=xorb(l)
      y5=yorb(l)
      z5=zorb(l)
      ni4=ni3+1
      ni5=ni4+1
      if(ni3.lt.2) go to 143
      ni8=(ni3-1)*(ni3-2)/2-1
  143 ni6=ni3*(ni3-1)/2
      ni7=ni4*(ni4-1)/2-1
      nj4=nj3+1
      nj5=nj4+1
      if(nj3.lt.2) go to 144
      nj8=(nj3-1)*(nj3-2)/2-1
  144 nj6=nj3*(nj3-1)/2
      nj7=nj4*(nj4-1)/2-1
      nk4=nk3+1
      nk5=nk4+1
      if(nk3.lt.2) go to 145
      nk8=(nk3-1)*(nk3-2)/2-1
  145 nk6=nk3*(nk3-1)/2
      nk7=nk4*(nk4-1)/2-1
      dif(1)=xorb(l)-x0
      dif(2)=yorb(l)-y0
      dif(3)=zorb(l)-z0
      difsum=0.0d0
      do 10 i1=1,3
      dif2(i1)=dif(i1)*dif(i1)
  10  difsum=difsum+dif2(i1)
      lc1=ic(l)
      nxx=mi2+ni3+1
      nxy=mj2+nj3+1
      nxz=mk2+nk3+1
      nox=nxx
      if(nox.lt.nxy) nox=nxy
      if(nox.lt.nxz) nox=nxz
      bax=dif(1)
      bay=dif(2)
      baz=dif(3)
      zxf(1)=bax
      zyf(1)=bay
      zzf(1)=baz
      if(nxx.eq.1) go to 129
      do 130 i=2,nxx
  130 zxf(i)=zxf(i-1)*bax
  129 if(nxy.eq.1) go to 131
      do 132 i=2,nxy
  132 zyf(i)=zyf(i-1)*bay
  131 if(nxz.eq.1) go to 133
      do 134 i=2,nxz
  134 zzf(i)=zzf(i-1)*baz
  133 do 3 l1=1,lco
      aa=zeta(l1+kkkk)
      qx=aa*x0
      qy=aa*y0
      qz=aa*z0
      tuffy=d(l1+kkkk)*(aa**farx)
      am=-aa
      af(1)=am
      aab2=difsum*aa
      if(nax.eq.1) go to 135
      do 136 i=2,nax
  136 af(i)=am*af(i-1)
  135 do 3 l2=1,lc1
      bb=zeta(l2+llll)
      bb2=bb+bb
      alp=aa+bb
      alg=1.0d0/alp
      arg=aab2*bb*alg
      if(arg.gt.thrs) go to 3
      tuf=tuffy*dexp(-arg)
      tuf=tuf*d(l2+llll)*(bb**fbrx)
      if(max.eq.0) go to 141
      bf(1)=bb
      if(max.eq.1) go to 141
      do 907 i=2,max
  907 bf(i)=bf(i-1)*bb
  141 tuf=tuf*(alg**1.5d0)
      alf(1)=alg
      if(nox.eq.1) go to 150
      do 151 i=2,nox
  151 alf(i)=alf(i-1)*alg
  150 sxma=0.0d0
      sxmb=0.0d0
      sxmc=0.0d0
      sxmd=0.0d0
      syma=0.0d0
      symb=0.0d0
      symc=0.0d0
      symd=0.0d0
      szma=0.0d0
      szmb=0.0d0
      szmc=0.0d0
      szmd=0.0d0
      px=(qx+bb*x5)*alg
      py=(qy+bb*y5)*alg
      pz=(qz+bb*z5)*alg
      mi5=mi4
      do 140 i=1,mi3
      w4=1.0d0
      if(i.eq.1) go to 142
      mi5=mi5+1
      w4=icom(mi5)*bf(i-1)
  142 ni9=ni6
      do 146 j=1,ni4
      w5=w4
      if(j.eq.1) go to 147
      ni9=ni9+1
      w5=w5*icom(ni9)*af(j-1)
  147 i9=i+j-2
      if(i9.gt.0) w5=w5*zxf(i9)
      i8=nxx-i9
      i7=i8/2
      i4=i7+i9
      if(i4.gt.0) w5=w5*alf(i4)
      if(i8-i7*2.eq.0) go to 153
      if(i7.gt.0) w5=w5*t3(i7)
      sxma=sxma+w5
      go to 146
  153 sxmb=sxmb+w5*t3(i7)
  146 continue
c     next comes fx(m+1)  ***********
      ni9=ni7
      do 154 j=1,ni5
      ni9=ni9+1
      i9=i+j-2
      i8=nxx-i9
      i7=i8/2
      if(i8-i7*2.ne.0) go to 154
      w5=w4
      if(i7.eq.0) go to 800
      w5=w5*t3(i7)*alf(i7+i9)
      go to 801
  800 if(i9.gt.0) w5=w5*alf(i9)*zxf(i9)
      go to 802
  801 if(i9.gt.0) w5=w5*zxf(i9)
  802 if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
      sxmc=sxmc+w5
 154  continue
      if(ni3.eq.0) go to 140
      ni9=ni8
      do 157 j=1,ni3
      ni9=ni9+1
      i9=i+j-2
      i8=nxx-i9-2
      i7=i8/2
      if(i8-i7*2.ne.0) go to 157
      w5=w4
      if(i7.eq.0) go to 158
      w5=w5*t3(i7)*alf(i7+i9)
      go to 159
  158 if(i9.gt.0) w5=w5*alf(i9)*zxf(i9)
      go to 803
  159 if(i9.gt.0) w5=w5*zxf(i9)
  803 if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
      sxmd=sxmd+w5
  157 continue
  140 continue
      mi5=mj4
      do 160 i=1,mj3
      w4=1.0d0
      if(i.eq.1) go to 162
      mi5=mi5+1
      w4=icom(mi5)*bf(i-1)
  162 ni9=nj6
      do 166 j=1,nj4
      w5=w4
      if(j.eq.1) go to 167
      ni9=ni9+1
      w5=w5*icom(ni9)*af(j-1)
  167 i9=i+j-2
      if(i9.gt.0) w5=w5*zyf(i9)
      i8=nxy-i9
      i7=i8/2
      i4=i7+i9
      if(i4.gt.0) w5=w5*alf(i4)
      if(i8-i7*2.eq.0) go to 173
      if(i7.gt.0) w5=w5*t3(i7)
      syma=syma+w5
      go to 166
  173 symb=symb+w5*t3(i7)
  166 continue
      ni9=nj7
      do 174 j=1,nj5
      ni9=ni9+1
      i9=i+j-2
      i8=nxy-i9
      i7=i8/2
      if(i8-i7*2.ne.0) go to 174
      w5=w4
      if(i7.eq.0) go to 804
      w5=w5*t3(i7)*alf(i7+i9)
      go to 805
  804 if(i9.gt.0) w5=w5*alf(i9)*zyf(i9)
      go to 806
  805 if(i9.gt.0) w5=w5*zyf(i9)
  806 if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
      symc=symc+w5
  174 continue
      if(nj3.eq.0) go to 160
      ni9=nj8
      do 177 j=1,nj3
      ni9=ni9+1
      i9=i+j-2
      i8=nxy-i9-2
      i7=i8/2
      if(i8-i7*2.ne.0) go to 177
      w5=w4
      if(i7.eq.0) go to 178
      w5=w5*t3(i7)*alf(i7+i9)
      go to 179
  178 if(i9.gt.0) w5=w5*alf(i9)*zyf(i9)
      go to 807
  179 if(i9.gt.0) w5=w5*zyf(i9)
  807 if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
      symd=symd+w5
  177 continue
  160 continue
      mi5=mk4
      do 180 i=1,mk3
      w4=1.0d0
      if(i.eq.1) go to 182
      mi5=mi5+1
      w4=icom(mi5)*bf(i-1)
  182 ni9=nk6
      do 186 j=1,nk4
      w5=w4
      if(j.eq.1) go to 187
      ni9=ni9+1
      w5=w5*icom(ni9)*af(j-1)
  187 i9=i+j-2
      if(i9.gt.0) w5=w5*zzf(i9)
      i8=nxz-i9
      i7=i8/2
      i4=i7+i9
      if(i4.gt.0) w5=w5*alf(i4)
      if(i8-i7*2.eq.0) go to 193
      if(i7.gt.0) w5=w5*t3(i7)
      szma=szma+w5
      go to 186
  193 szmb=szmb+w5*t3(i7)
  186 continue
      ni9=nk7
      do 194 j=1,nk5
      ni9=ni9+1
      i9=i+j-2
      i8=nxz-i9
      i7=i8/2
      if(i8-i7*2.ne.0) go to 194
      w5=w4
      if(i7.eq.0) go to 808
      w5=w5*t3(i7)*alf(i7+i9)
      go to 809
  808 if(i9.gt.0) w5=w5*alf(i9)*zzf(i9)
      go to 810
  809 if(i9.gt.0) w5=w5*zzf(i9)
  810 if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
      szmc=szmc+w5
  194 continue
      if(nk3.eq.0) go to 180
      ni9=nk8
      do 197 j=1,nk3
      ni9=ni9+1
      i9=i+j-2
      i8=nxz-i9-2
      i7=i8/2
      if(i8-i7*2.ne.0) go to 197
      w5=w4
      if(i7.eq.0) go to 198
      w5=w5*t3(i7)*alf(i7+i9)
      go to 199
  198 if(i9.gt.0) w5=w5*alf(i9)*zzf(i9)
      go to 811
  199 if(i9.gt.0) w5=w5*zzf(i9)
  811 if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
      szmd=szmd+w5
  197 continue
  180 continue
      sumg=sumg+tuf*sxma*syma*szma
      suma=suma+tuf*(sxmb+px*sxma)*syma*szma
      sumb=sumb+tuf*sxma*(symb+py*syma)*szma
      sumc=sumc+tuf*sxma*syma*(szmb+pz*szma)
      sumd=sumd+tuf*(ni3*sxmd-bb2*sxmc)*syma*szma
      sume=sume+tuf*(nj3*symd-bb2*symc)*sxma*szma
      sumf=sumf+tuf*(nk3*szmd-bb2*szmc)*sxma*syma
   3  continue
      ovl(mm)=t2f*sumg
      dixf(mm)=t2f*suma
      diyf(mm)=t2f*sumb
      dizf(mm)=t2f*sumc
      xnab(mm)=-t2f*sumd
      ynab(mm)=-t2f*sume
      znab(mm)=-t2f*sumf
       if(mm.lt.id) go to 102
       write(lun01) dihf
      mm=0
 102   continue
  101 continue
           write(lun01) dihf
      return
      end
_EXTRACT(tm3n,_AND(hp800,i8))
      subroutine tm3n(q,jmat,lenmat,imat,lensq)
      implicit REAL  (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
      common/aaaa/icom(21)
      common/scrtch/bc(10*maxorb),cbb(10*maxorb),
     + x(maxorb),p(maxorb),r(maxorb),
     + ic(maxorb),ii(maxorb),ij(maxorb),
     + ik(maxorb),ispa4(maxat),ilife(maxorb),
     + ovl(500),dixf(500),diyf(500),dizf(500),xnab(500),ynab(500),
     + znab(500),spc(19000),
     + icu(22500),ibal(8),itil(8),mcomp(maxorb),kj(8),
     + lsym(8*maxorb),nj(8),ntil(8),nbal(9),ispa,
     + ncomp(maxorb),nzer(maxorb),
     + xdum(1300),
     + nconf(5),jconf(5),nytl(5),ndub(5),jtest(mxnshl),
     + nplu(5),itest(mxnshl),jytl(5),jdub(5),jplu(5),lj(8),
     + jcon(maxorb),irm(126),jrm(mxcrec),
     + intp(maxorb),intn(maxorb),
     + zeta(10*maxorb),d(10*maxorb),xorb(maxorb),yorb(maxorb),
     + zorb(maxorb),anorm(maxorb),psep(6),pvec(3),dif(3),dif2(3),
     + wc(maxat),wx(maxat),wy(maxat),wz(maxat),t1(5),t2(5),t3(5),
     + zxf(11),zyf(11),zzf(11),alf(11),bf(5),af(6),
     + ci(126),cj(126),di(48),dj(48)
c
      common/ftap5/ntaper(15),
     +             lun01, lund, lun02, lun03, jtmfil
      common/ctmn/iput1,idx,jput,jdx,nstate
      common/lsort/fac,acore,enee,ilifq(maxorb),iorbs,iswh,m,m2,mu,id
     *,ni8,nj8,nk8,imo,ig
      dimension q(lensq),jmat(lenmat),imat(3780)
      integer imap, ihog, jmap, jhog
      common /scra4/ imap(504),ihog(48),
     +               jmap(504),jhog(48)
      REAL fj, gj, h, f, g
      integer jkan, ikan
      common /scra5/ fj(1000), gj(500), h(100),
     +                f(1000),  g(500),
     +              jkan(500), ikan(500)
c
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      dimension e(ndime)
      dimension bloc(9100),ovm(1300)
      dimension xm(1300),ym(1300),zm(1300),xam(1300),yam(1300)
      dimension zam(1300),dihf(3500)
c
      equivalence (e(1),bc(1),bloc(1))
      equivalence (dihf(1), ovl(1)),
     +             (bloc(1),ovm(1)),
     +          (bloc(1301),xm(1)),(bloc(2601),ym(1)),
     +          (bloc(3901),zm(1)),(bloc(5201),xam(1)),
     +          (bloc(6501),yam(1)),(bloc(7801),zam(1))
c
      do 201 j=1,iswh
      jc=jconf(j)
      if (jc.eq.0) go to 201
      read(jput)jhb,jmax,ndj,kmj,jmap,jhog,enee
c     if (mod(jc,jmax).eq.0)then
c      jhb = jhb + 1
c     endif
      nlj=jytl(j)
      jmns=j-1
      jqns=j-2
      jps=jplu(j)
      jdb=jdub(j)
      jdbq=jdb+jdb
      nodj=jmns+jps
      nodj2=nodj-m2
      jcl=0
      idel=ndj*m
      do 202 k=1,jhb
      jcl=jcl+jmax
      if(jcl.gt.jc) jmax=jc+jmax-jcl
      read(jput) jkan,fj,gj
      nxj=0
      call rewftn(lun03)
      k5=0
      k4=0
      do 111 k6=1,jmax
      do 112 l=1,nlj
       nxj=nxj+1
 112  jtest(l)=jkan(nxj)
      if(jmns .gt. 0) go to 213
      jrm(k6)=1
      if(jps.eq.0) go to 214
      do 215 l=1,jps
      k4=k4+1
 215  jmat(k4)=jtest(l)
      if(jdb.eq.0) go to 111
 214  kx=jps
      do 217 l=1,jdb
      kx=kx+1
      k4=k4+1
      lk=jtest(kx)
      jmat(k4)=lk
      k4=k4+1
 217  jmat(k4)=-lk
      go to 111
213   jq=1
      lx=k4
      do 218 l=1,ndj
      k5=k5+1
      jrm(k5)=1
      jz=jq+jqns
      jy=jmap(jq)
      do 219 kk=1,nodj
      lx=lx+1
      if (kk.ne.jy) go to 220
      if (jz.eq.jq) go to 221
      jq=jq+1
      jy=jmap(jq)
221   jmat(lx)=-jtest(kk)
      go to 219
220   jmat(lx)=jtest(kk)
219   continue
      jq=jz+1
218   lx=lx+jdbq
      if (jdb.eq.0) go to 113
      kx=nodj2+k4
      kk=nodj
      do 222 l=1,jdb
      kk=kk+1
      lk=jtest(kk)
      kx=kx+2
      mx=kx
      do 222 ll=1,ndj
      mx=mx+m
      jmat(mx+1)=lk
222   jmat(mx+2) =-lk
      k4=mx+2
      go to 111
  113 k4=lx
 111  continue
      if (j.eq.1) go to 300
      j9=j-1
      if(j.eq.2) go to 114
      j8=j-2
      do 115 l=1,j8
      nc=nconf(l)
      if(nc.eq.0) go to 115
      read(lun03)nhb
      do 116 ll=1,nhb
 116  read(lun03)
 115  continue
 114  nc=nconf(j9)
      if(nc.eq.0) go to 300
      read(lun03)nhb,imax,ndt,kml,imap
      nl=nytl(j9)
      nmns=j9-1
      nqns=j9-2
      nps=nplu(j9)
      ndb=ndub(j9)
      ndbq=ndb+ndb
      nod=nmns+nps
      nodm2=nod-m2
      icl=imax
      do 224 k9=1,nc
      if (icl.lt.imax) go to 225
      read(lun03) ikan,f
      icl=1
      nx=0
      if=0
      go to 226
225   icl=icl+1
226   do 227 l9=1,nl
      nx=nx+1
227   itest(l9)=ikan(nx)
      do 208 l=1,imo
 208  jcon(l)=0
      if(nod.eq.0) go to 209
      do 210 l=1,nod
      nt=itest(l)
 210  jcon(nt)=1
      if(ndb.eq.0) go to 211
 209  kk=nod
      do 212 l=1,ndb
      kk=kk+1
      nt=itest(kk)
 212  jcon(nt)=2
 211  do 233 kw=1,ndt
      if=if+1
 233  ci(kw)=f(if)
      if(nmns.gt.0) go to 235
      irm(1)=1
      if (nps.eq.0) go to 236
      do 237 kw=1,nps
237   imat(kw)=itest(kw)
      if(ndb.eq.0) go to 240
236   lx=nps
      kx=nps
      do 238 kw=1,ndb
      kx=kx+1
      lx=lx+1
      lk=itest(kx)
      imat(lx)=lk
      lx=lx+1
238   imat(lx)=-lk
      go to 240
235   lx=0
      jq=1
      do 239 kw=1,ndt
      irm(kw)=1
      jz=jq+nqns
      jy=imap(jq)
      do 241 lw=1,nod
      lx=lx+1
      if (lw.ne.jy) go to 242
      if (jz.eq.jq) go to 243
      jq=jq+1
      jy=imap(jq)
243   imat(lx)=-itest(lw)
      go to 241
242   imat(lx)=itest(lw)
241   continue
      jq=jz+1
239   lx=lx+ndbq
      if (ndb.eq.0) go to 240
      kx=nodm2
      kk=nod
      do 244 kw=1,ndb
      kk=kk+1
      lk=itest(kk)
      kx=kx+2
      mx=kx
      do 244 lw=1,ndt
      mx=mx+m
      imat(mx+1)=lk
244   imat(mx+2)=-lk
 240  nxj=0
      injs=-ndj
      igj=0
      do 117 l=1,jmax
      injs=injs+ndj
      do 118 ll=1,nlj
      nxj=nxj+1
 118  jtest(ll)=jkan(nxj)
      nix=0
      if(nodj.eq.0) go to 228
      do 229 kw=1,nodj
      jt=jtest(kw)
      if(jcon(jt).gt.0) go to 229
      if(nix.eq.1) go to 230
      nix=1
  229 continue
      if(jdb.eq.0) go to 231
 228  kk=nodj
      do 232 kw=1,jdb
      kk=kk+1
      jt=jtest(kk)
      jb=jcon(jt)
      if(jb.eq.2) go to 232
      if(jb.eq.0.or.nix.eq.1) go to 230
      nix=1
 232  continue
 231  do 206     ll=1,kmj
      igj=igj+1
 206  dj(ll)=gj(igj)
      go to 119
  230 igj=igj+kmj
      go to 117
 119  if(ndt.gt.kmj) go to 280
      ini=-m
      do 245 lw=1,ndt
      orb=ci(lw)
      ini=ini+m
      do 246 kw=1,imo
      intp(kw)=0
246   intn(kw)=0
      ink=ini
      do 247 kw=1,m
      ink=ink+1
      lx=imat(ink)
      if(lx.lt.0) go to 248
      intp(lx)=kw
      go to 247
248   intn(-lx)=kw
247   continue
      do 249 kw=1,kmj
      nix=0
      jr=jhog(kw)+injs
      inj=(jr-1)*m
      ink=inj
      do 250 mw=1,m
      ink=ink+1
      la=jmat(ink)
      if (la.lt.0) go to 251
      if (intp(la).gt.0) go to 250
252   if (nix.eq.1) go to 249
      nix=1
      iodd=mw
      go to 250
251   if (intn(-la).eq.0) go to 252
250   continue
      if (iodd.eq.1) go to 253
      kx=1
      ky=iodd-1
      ink=inj
261   do 254 mw=kx,ky
      ink=ink+1
      lx=jmat(ink)
      if(lx.lt.0) go to 255
      la=intp(lx)
      go to 256
255   la=intn(-lx)
256   if (la.eq.mw) go to 254
      ix=ini+la
      iy=ini+mw
      ni=imat(iy)
      imat(ix)=ni
      imat(iy)=lx
      irm(lw)=-irm(lw)
      if (lx.lt.0) go to 257
      intp(lx)=mw
      go to 258
257   intn(-lx)=mw
258   if(ni.lt.0) go to 259
      intp(ni)=la
      go to 254
259   intn(-ni)=la
254   continue
      if (ky.gt.mu) go to 260
253   kx=iodd+1
      ky=m
      ink=inj+iodd
      go to 261
260   vm=orb*dj(kw)
      if (irm(lw).ne.jrm(jr))vm=-vm
      ink=ini+iodd
      ia=imat(ink)
      ink=inj+iodd
      ja=jmat(ink)
      if(ia.gt.0) go to 262
      ia=-ia
      ja=-ja
262   ia=ilifq(ia)+ja
      q(ia)=q(ia)+vm
249   continue
245   continue
      go to 117
280   do 281 lw=1,kmj
      jr=jhog(lw)+injs
      inj=(jr-1)*m
      orb=dj(lw)
      do 282 kw=1,imo
      intp(kw)=0
282   intn(kw)=0
      ink=inj
      do 283 kw=1,m
      ink=ink+1
      lx=jmat(ink)
      if (lx.lt.0) go to 284
      intp(lx)=kw
      go to 283
284   intn(-lx)=kw
283   continue
      ini=-m
      do 285 kw=1,ndt
      ini=ini+m
      ink=ini
      nix=0
      do 286 mw=1,m
      ink=ink+1
      la=imat(ink)
      if (la.lt.0) go to 287
      if (intp(la).gt.0) go to 286
288   if (nix.eq.1) go to 285
      nix=1
      iodd=mw
      go to 286
287   if (intn(-la).eq.0) go to 288
286   continue
      if (iodd.eq.1) go to 289
      kx=1
      ky=iodd-1
      ink=ini
290   do 291 mw=kx,ky
      ink=ink+1
      lx=imat(ink)
      if (lx.lt.0) go to 292
      la=intp(lx)
      go to 293
292   la=intn(-lx)
293   if(la.eq.mw) go to 291
      ix=inj+la
      iy=inj +mw
      ni=jmat(iy)
      jmat(ix)=ni
      jmat(iy)=lx
      jrm(jr)=-jrm(jr)
      if (lx.lt.0) go to 294
      intp(lx)=mw
      go to 295
294   intn(-lx)=mw
295   if (ni.lt.0) go to 296
      intp(ni)=la
      go to 291
296   intn(-ni)=la
291   continue
      if (ky.gt.mu) go to 297
289   kx=iodd+1
      ky=m
      ink=ini+iodd
      go to 290
297   vm=orb*ci(kw)
      if (irm(kw).ne.jrm (jr))vm=-vm
      ink=iodd+ini
      ia=imat(ink)
      ink=iodd+inj
      ja=jmat(ink)
      if (ia.gt.0) go to 298
      ia=-ia
      ja=-ja
298   ia=ilifq(ia)+ja
      q(ia)=q(ia)+vm
285   continue
281   continue
 117  continue
 224  continue
 300  jpig=j+1
      if(j.eq.iswh) jpig=j
      do 323 j9=j,jpig
      nc=nconf(j9)
      if(nc.eq.0) go to 323
      read(lun03)nhb,imax,ndt,kml,imap,ihog
      nl=nytl(j9)
      nmns=j9-1
      nqns=j9-2
      nps=nplu(j9)
      ndb=ndub(j9)
      ndbq=ndb+ndb
      nod=nmns+nps
      nodm2=nod-m2
      icl=imax
      do 324 k9=1,nc
      if (icl.lt.imax) go to 325
      read(lun03) ikan,f,g
      icl=1
      nx=0
      ig=0
      go to 326
325   icl=icl+1
326   do 327 l9=1,nl
      nx=nx+1
327   itest(l9)=ikan(nx)
      do 120 l=1,imo
 120  jcon(l)=0
      if(nod.eq.0) go to 123
      do 121 l=1,nod
      nt=itest(l)
 121  jcon(nt)=1
      if(ndb.eq.0) go to 122
 123  kk=nod
      do 124 l=1,ndb
      kk=kk+1
      nt=itest(kk)
 124  jcon(nt)=2
  122  do 125 kw=1,kml
      ig=ig+1
 125  di(kw)=g(ig)
      if(nmns.gt.0) go to 335
      irm(1)=1
      if (nps.eq.0) go to 336
      do 337 kw=1,nps
337   imat(kw)=itest(kw)
      if(ndb.eq.0) go to 340
336   lx=nps
      kx=nps
      do 338 kw=1,ndb
      kx=kx+1
      lx=lx+1
      lk=itest(kx)
      imat(lx)=lk
      lx=lx+1
338   imat(lx)=-lk
      go to 340
335   lx=0
      do 339 kw=1,kml
      irm(kw)=1
      jq=(ihog(kw)-1)*nmns+1
      jz=jq+nqns
      jy=imap(jq)
      do 341 lw=1,nod
      lx=lx+1
      if (lw.ne.jy) go to 342
      if (jz.eq.jq) go to 343
      jq=jq+1
      jy=imap(jq)
343   imat(lx)=-itest(lw)
      go to 341
342   imat(lx)=itest(lw)
341   continue
339   lx=lx+ndbq
      if (ndb.eq.0) go to 340
      kx=nodm2
      kk=nod
      do 344 kw=1,ndb
      kk=kk+1
      lk=itest(kk)
      kx=kx+2
      mx=kx
      do 344 lw=1,kml
      mx=mx+m
      imat(mx+1)=lk
344   imat(mx+2)=-lk
 340  nxj=0
      ifj=0
      jsig=-m-idel
      do 126 l=1,jmax
      jsig=jsig+idel
      do 127 ll=1,nlj
      nxj=nxj+1
 127  jtest(ll)=jkan(nxj)
      nix=0
      if(nodj.eq.0) go to 328
      do 329 kw=1,nodj
      jt=jtest(kw)
      if(jcon(jt).gt.0) go to 329
      if(nix.eq.1) go to 330
      nix=1
 329  continue
      if(jdb.eq.0) go to 331
 328  kk=nodj
      do 332 kw=1,jdb
      kk=kk+1
      jt=jtest(kk)
      jb=jcon(jt)
      if(jb.eq.2) go to 332
      if(jb.eq.0.or.nix.eq.1) go to 330
      nix=1
 332  continue
 331  injs=ifj
      do 333 kw=1,ndj
      ifj=ifj+1
 333  cj(kw)=fj(ifj)
      go to 334
 330  ifj=ifj+ndj
      go to 126
334   if (nix.eq.1) go to 434
      vm=0.0d0
      do 400 kw=1,kml
      jr=jhog(kw)
400   vm=vm+cj(jr)*di(kw)
      acore=acore+vm
      if (nod.eq.0) go to 402
      do 401 kw=1,nod
      jt=itest(kw)
      ia=ilifq(jt)+jt
401   q(ia)=q(ia)+vm
      if(ndb.eq.0) go to 126
402   kk=nod
      vm=vm+vm
      do 403 kw=1,ndb
      kk=kk+1
      jt=itest(kk)
      ia=ilifq(jt)+jt
403   q(ia)=q(ia)+vm
      go to 126
 434  if(ndj.gt.kml) go to 380
      inj=jsig
      do 345 lw=1,ndj
      orb=cj(lw)
      inj=inj+m
      do 346 kw=1,imo
      intp(kw)=0
346   intn(kw)=0
      ink=inj
      do 347 kw=1,m
      ink=ink+1
      lx=jmat(ink)
      if(lx.lt.0) go to 348
      intp(lx)=kw
      go to 347
348   intn(-lx)=kw
347   continue
      ini=-m
      do 349 kw=1,kml
      nix=0
      ini=ini+m
      ink=ini
      do 350 mw=1,m
      ink=ink+1
      la=imat(ink)
      if (la.lt.0) go to 351
      if (intp(la).gt.0) go to 350
352   if(nix.eq.1) go to 349
      nix=1
      iodd=mw
      go to 350
351   if(intn(-la).eq.0) go to 352
350   continue
      if (iodd.eq.1) go to 353
      kx=1
      ky=iodd-1
      ink=ini
361   do 354 mw=kx,ky
      ink=ink+1
      lx=imat(ink)
      if(lx.lt.0) go to 355
      la=intp(lx)
      go to 356
355   la=intn(-lx)
356   if(la.eq.mw) go to 354
      ix=inj+la
      iy=inj+mw
      ni=jmat(iy)
      jmat(ix)=ni
      jmat(iy)=lx
       jrm(lw+injs)=-jrm(lw+injs)
      if(lx.lt.0) go to 357
      intp(lx)=mw
      go to 358
357   intn(-lx)=mw
358   if(ni.lt.0) go to 359
      intp(ni)=la
      go to 354
359   intn(-ni)=la
354   continue
      if(ky.gt.mu) go to 360
353   kx=iodd+1
      ky=m
      ink=ini+iodd
      go to 361
360   vm=orb*di(kw)
       if(irm(kw).ne.jrm(lw+injs)) vm=-vm
      ink=ini+iodd
      ia=imat(ink)
      ink=inj+iodd
      ja=jmat(ink)
      if(ia.gt.0) go to 362
      ia=-ia
      ja=-ja
362   ia=ilifq(ia)+ja
      q(ia)=q(ia)+vm
349   continue
345   continue
      go to 126
380   ini=-m
      do 381 lw=1,kml
      orb=di(lw)
      ini=ini+m
      do 382 kw=1,imo
      intp(kw)=0
382   intn(kw)=0
      ink=ini
      do 383 kw=1,m
      ink=ink+1
      lx=imat(ink)
      if(lx.lt.0) go to 384
      intp(lx)=kw
      go to 383
384   intn(-lx)=kw
383   continue
      inj=jsig
      do 385 kw=1,ndj
      inj=inj+m
      ink=inj
      nix=0
      do 386 mw=1,m
      ink=ink+1
      la=jmat(ink)
      if(la.lt.0) go to 387
      if (intp(la).gt.0) go to 386
388   if (nix.eq.1) go to 385
      nix=1
      iodd=mw
      go to 386
387   if (intn(-la).eq.0) go to 388
386   continue
      if (iodd.eq.1) go to 389
      kx=1
      ky=iodd-1
      ink=inj
390   do 391 mw=kx,ky
      ink=ink+1
      lx=jmat(ink)
      if (lx.lt.0) go to 392
      la=intp(lx)
      go to 393
392   la=intn(-lx)
393   if(la.eq.mw) go to 391
      ix=ini+la
      iy=ini+mw
      ni=imat(iy)
      imat(ix)=ni
      imat(iy)=lx
      irm(lw)=-irm(lw)
      if (lx.lt.0) go to 394
      intp(lx)=mw
      go to 395
394   intn(-lx)=mw
395   if(ni.lt.0) go to 396
      intp(ni)=la
      go to 391
396   intn(-ni)=la
391   continue
      if (ky.gt.mu) go to 397
389   kx=iodd+1
      ky=m
      ink=inj+iodd
      go to 390
397   vm=orb*cj(kw)
      if(irm(lw).ne.jrm(kw+injs)) vm=-vm
      ink=iodd+ini
      ia=imat(ink)
      ink=iodd+inj
      ja=jmat(ink)
      if(ia.gt.0) go to 398
      ia=-ia
      ja=-ja
398   ia=ilifq(ia)+ja
      q(ia)=q(ia)+vm
385   continue
381   continue
 126   continue
324   continue
323   continue
202   continue
201   continue
      return
      end
_ENDEXTRACT
      subroutine nf3in1(cf,icf,len,ltape,iwr,odebug)
      implicit REAL  (a-h,o-z), integer (i-n)
      dimension cf(len),icf(len)
      logical odebug
INCLUDE(common/sizes)
      common/scr1/repel,etot,nit(667),newya(maxorb),ijj(8),n,
     +            jsym(36),iy(8)
      common/scrtch/bc(10*maxorb),cbb(10*maxorb),
     + x(maxorb),p(maxorb),r(maxorb),
     + ic(maxorb),ii(maxorb),ij(maxorb),ik(maxorb),
     + ispa4(maxat),ilife(maxorb),
     + cu(22500),icu(22500),
     + ibal(8),itil(8),mcomp(maxorb),kj(8),lsym(8*maxorb),
     + nj(8),ntil(8),nbal(9),ispa,ncomp(maxorb),nzer(maxorb),
     + xdum(1300),
     + nconf(5),jconf(5),nytl(5),ndub(5),jtest(mxnshl),
     + nplu(5),itest(mxnshl),jytl(5),jdub(5),jplu(5),lj(8),
     + jcon(maxorb),irm(126),jrm(mxcrec),
     + intp(maxorb),intn(maxorb),
     + zeta(10*maxorb),d(10*maxorb),xorb(maxorb),yorb(maxorb),
     + zzorb(maxorb),anorm(maxorb),
     + psep(6),pvec(3),dif(3),dif2(3),wcxyz(4*maxat),
     + t1(5),t2(5),t3(5),
     + zxf(11),zyf(11),zzf(11),alf(11),bf(5),af(6),
     + ci(126),cj(126),di(48),dj(48),isym(8)
c
      common/ctmn/iput1,idx,jput,jdx,nstate
      common/lsort/fac,acore,enee,ilifq(maxorb),iorbs,iswh,m,m2,mu,id
     *,ni8,nj8,nk8,imo,ig,ksum,knu
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      dimension e(ndime)
      equivalence (e(1),bc(1))
c
c
c    interface file to replace components of the following:
c    ******************************************************************
c     read(iput1)iwod,vnuc,zero,imo,m,nconf,newya,
c    * nytl,nplu,ndub,iswh,ksum,
c    1 iorbs,knu,cf,icf,wc,wx,wy,wz,ibal,itil,mcomp,kj,lj,n,ifrk,e,lsym,
c    2 nsel,nj,ntil,nbal,ncomp
c    ******************************************************************
c
      call rewftn(ltape)
c     1st record
      read(ltape) n,nod,jod,ksum,nt,
     +            kj,iy,lj,nj,nsel,
     +            ntil,nbal,isym,jsym,iorbs,knu,
     +            newya,lsym,ncomp,e,wcxyz,repel,etot
c
      if (odebug) then
       write(iwr,*) '***** first record from unit ', ltape
       write(iwr,*) 'n =',n
       write(iwr,*) 'nod =',nod
       write(iwr,*) 'jod =',jod
       write(iwr,*) 'ksum =',ksum
       write(iwr,*) 'nt =',nt
       write(iwr,*) 'kj  =',kj
       write(iwr,*) 'iy  =',iy
       write(iwr,*) 'lj  =',lj
       write(iwr,*) 'nj  =',nj
       write(iwr,*) 'nsel=',nsel
       write(iwr,*) 'ntil=',ntil
       write(iwr,*) 'nbal=',nbal
       write(iwr,*) 'isym = ', isym
       write(iwr,*) 'jsym = ', jsym
       write(iwr,*) 'iorbs= ',iorbs
       write(iwr,*) 'knu  = ',knu
       write(iwr,*) 'newya= ',newya
       write(iwr,*) 'ncomp= ',ncomp
       write(iwr,*) 'repel= ',repel
       write(iwr,*) 'etot= ',etot
      endif
c
c     2nd record
      read(ltape) nit,ijj,cf,icf,ibal,itil,mcomp
      if (odebug) then
       write(iwr,*) '***** second record *****'
       write(iwr,*) 'ij  =',ijj
       write(iwr,*) 'ibal=',ibal
       write(iwr,*) 'itil=',itil
       write(iwr,*) 'mcomp=',mcomp
      endif
c
      n = nsel
c
      call rewftn(ltape)
      return
      end
      subroutine pmrdci2(core,odebug)
      implicit REAL  (a-h,o-z), integer (i-n)
      dimension core(*)
      logical odebug
INCLUDE(common/sizes)
INCLUDE(common/discc)
INCLUDE(common/prints)
      parameter (maxroot=50)
      parameter (maxshl =50)
      parameter (maxshl1=maxshl+1)
      common/ftap5/ntaper(15),
     +             lun01, lund, lun02, lun03, jtmfil
INCLUDE(common/infoa)
      logical ospecp,debugp
      logical oprop1e,noscfp,doscf
      common/cprop1e/istate,ipig(maxroot),ipmos,ipaos,iaopr(11),
     +               imopr(11),jkonp(maxshl1*maxroot),
     +               debugp,ospecp,oprop1e,noscfp,doscf
INCLUDE(common/iofile)
      parameter (maxref=256)
      REAL edavit,cdavit,extrapit,eigvalr,cradd,
     +     weighb, rootdel, ethreshit
      integer mbuenk,nbuenk,mxroots
      logical ifbuen, ordel, odave, oweight, odavit
      common /comrjb2/edavit(maxroot),cdavit(maxroot),
     +                odavit(maxroot),
     +                extrapit(maxroot),ethreshit(maxroot),
     +                eigvalr(maxref),cradd(3),weighb,
     +                rootdel,ifbuen,mbuenk,mxroots,
     +                ordel,odave,nbuenk,oweight
      integer iselecx,izusx,iselect
      common /cselec/ iselecx(maxroot),izusx(maxroot),
     +                iselect(maxroot),nrootci,
     +                iselecz(maxroot)
      dimension lj(8),iq(15)
c
      write(iwr,3)yed(idaf),ibl3d
 3    format(/1x,104('=')//
     *40x,47('*')/
     *40x,'*** MRD-CI V2.0: One-electron Properties Module'/
     *40x,47('*')//
     *1x,'dumpfile on ',a4,' at block',i6)
      if(ibl3d.le.0) then
       call caserr('invalid starting block for dumpfile')
      endif
      if(num.le.0.or.num.gt.maxorb) call caserr(
     *'invalid number of basis functions')
      call rewftn(lund)
      read(lund)iorbs,imo,icore,nsym,lj
      if (odebug) then
       write(iwr,*) 'iorbs = ', iorbs
       write(iwr,*) 'imo = ', imo
       write(iwr,*) 'icore = ', icore
       write(iwr,*) 'nsym = ', nsym
       write(iwr,*) 'lj = ', lj
      endif
      if(iorbs.ne.num.or.imo.gt.iorbs)
     * call caserr('inconsistent parameters on dumpfile')
      nxx=iorbs*(iorbs+1)/2
      lenmo=imo*(imo+1)/2
      lensym=icore
      do 4 i=1,nsym
 4    lensym=lensym+lj(i)*(lj(i)+1)/2
      lenact=(imo+icore)*iorbs
c
      iq(1)=1
      do i=2,15
       iq(i)=iq(i-1)+nxx
      enddo
      need = iq(15)+nxx
      iq(1)= igmem_alloc(need)
      do i=2,15
       iq(i)=iq(i-1)+nxx
      enddo
c
      istini = istate
      if(ifbuen) then
c     reset istate if greater than current nrootci
       if(istate.gt.nrootci) istate = nrootci
      endif
c
      call pmrd0n(core(iq(1)),core(iq(2)),core(iq(3)),core(iq(4)),
     +            core(iq(5)),core(iq(6)),core(iq(7)),core(iq(8)),
     +            core(iq(9)),core(iq(10)),core(iq(11)),
     +            core(iq(3)),core(iq(4)),core(iq(6)),core(iq(7)),
     +            core(iq(10)),core(iq(12)),core(iq(14)),
     *            nxx,lenact,lensym,lenmo,iwr)
      call clredx
      call rewftn(lund)
      istate = istini
      call gmem_free(iq(1))
c
      return
      end
      subroutine pmrd0n(ovl,dipx,dipy,dipz,
     * qdxx,qdyy,qdzz,qdxy,qdxz,qdyz,tvl,tigl,
     * temp,pig,q,f,scr1,scr2,len,lenact,lensym,lenmo,iwr)
      implicit REAL  (a-h,o-z), integer (i-n)
      logical iaopr,imopr
      character *2 stype
      character *1 dash
      character *4 imos,iaos,mopr,is
INCLUDE(common/sizes)
INCLUDE(common/runlab)
INCLUDE(common/prints)
      common/scrtch/dinx,diny,dinz,qnxx,qnyy,qnzz,qnxy,qnxz,qnyz,
     + chg(maxat),cx(maxat),cy(maxat),cz(maxat),
     + cc(10*maxorb),cbb(10*maxorb),x(maxorb),y(maxorb),z(maxorb),
     + ic(maxorb),ii(maxorb),ij(maxorb),
     + ik(maxorb),ii4(maxat),ilife(maxorb),
     + zeta(10*maxorb),d(10*maxorb),anorm(maxorb),pvec(3),
     + h(11),s(11),t(11),lcomp(maxorb),ipigg(10),lj(8),
     + jcon(maxorb),jkon(20)
      common/aaaa/icom(21)
INCLUDE(common/mapper)
      common/ftap5/ntaper(15),
     +             lun01, lund, lun02, lun03, jtmfil
      parameter (maxroot=50)
      parameter (maxshl =50)
      parameter (maxshl1=maxshl+1)
      logical ospecp,debugp,oprop1e,noscfp,doscf
      common/cprop1e/istate,ipig(maxroot),ipmos,ipaos,iaopr(11),
     +               imopr(11),jkonp(maxshl1*maxroot),
     +               debugp,ospecp,oprop1e,noscfp,doscf
c
      dimension ovl(len),dipx(len),dipy(len),dipz(len)
      dimension qdxx(len),qdyy(len),qdzz(len),qdxy(len)
      dimension qdxz(len),qdyz(len),tigl(len),tvl(len),f(lenact)
      dimension temp(lenact),q(lenmo),pig(lensym),scr1(len),scr2(len)
c
      common/bufb/mfg(maxorb),newya(maxorb),new(maxorb)
c
      dimension t1(5),t2(5),t3(5),zxf(12),zyf(12),zzf(12),alf(12)
      dimension bf(5),af(7),dif(3),dif2(3)
      dimension stype(10),inumb(10),mopr(11),is(3)
      dimension ia(4),ja(4),ka(4)
c
      dimension ch(4*maxat)
_IF(cray,ksr,i8)
      parameter (ndime = 28*maxorb + maxat)
_ELSE
      parameter (ndime = 23*maxorb + (5*maxorb)/ 2 + maxat / 2)
_ENDIF
      dimension a(ndime)
      character*10 charwall
      equivalence (a(1),cc(1)),(ch(1),chg(1))
c
      data inumb/0,9,3,1,12,10,4,18,6,2/
      data stype/
     *'s','x','y','z','xy','xz','yz','xx','yy','zz'/
      data dash/'-'/
      data mopr/
     *'s','x','y','z','xx','yy','zz','xy','xz','yz','t'/
      data d5/1.0d-5/
      data is,iaos,imos/
     *'s','p','d','a.o.','m.o.'/
c
      ind(i,j)=max(new(i),new(j))*
     + (max(new(i),new(j))-1)/2 + min(new(i),new(j))
c
      cpu=cpulft(1)
      write(iwr,7002)cpu ,charwall()
 7002 format(/' *** commence property evaluation at ',
     *f8.2,' seconds',a10,' wall')
      nshl=20
      thrs=140.0d0
      fac=2.0d0**1.5d0
      call rewftn(lund)
      read (lund)iorbs,imo,icore,n,lj,knu,mlec,f,a,ch,newya
c
      call prpind(cx,cy,cz,ii4,newya,new,iorbs,knu,iwr)
c
      if(istate.le.0.or.istate.gt.maxroot)call caserr(
     *'invalid number of ci vectors requested for analysis')
      do i=1,istate
      if(ipig(i).le.0)call caserr(
     *'invalid ci vector specified for analysis')
      enddo
      write(iwr,9000)istate,
     * iorbs,imo,icore,mlec,ztitle,(ipig(i),i=1,istate)
 9000 format(/
     *' no. of states to be treated         ',i3/
     *' no. of a.o. basis functions         ',i3/
     *' no. of active orbitals              ',i3/
     *' no. of frozen orbitals              ',i3/
     *' no. of correlated electrons         ',i3//
     *' *** case : ',10a8//
     *' locations on ft42 of associated     '/
     *' ci density matrices                 ',20i3/)
c
c     ao integral print specification
c
      if(oprint(32))write(iwr,9100)
 9100 format(
     *' print out of basis functions requested'/)
      if(ipaos.eq.0)then
       write(iwr,9005)iaos
 9005  format(
     * ' no printing of integrals in ',a4,' basis required')
      else
       write(iwr,9007)iaos
 9007  format(' print following integrals in ',a4,' basis : ')
       do j=1,11
       if(.not.iaopr(j))write(iwr,9010)mopr(j)
 9010  format(/10x,a2,' - matrix')
       enddo
      endif
c
c    mo integral print specification
c
      if(ipmos.eq.0) then
       write(iwr,9005)imos
      else
       write(iwr,9007)imos
       do j=1,11
       if(.not.imopr(j))write(iwr,9010)mopr(j)
       enddo
      endif
c
      write(iwr,22)
 22   format(/29x,'geometry (a.u.)'/29x,15('-')/
     *8x,'x',15x,'y',15x,'z',17x,'charge'/1x,63('='))
      do m=1,knu
       write(iwr,9002)cx(m),cy(m),cz(m),chg(m)
      enddo
 9002 format(4f16.7)
      write(iwr,9003)knu
 9003 format(/' no. of nuclei = ',i3)
      if(.not.oprint(32))go to 9029
      write(iwr,9020)iorbs
 9020 format(/1x,104('-')//40x,19('-')/40x,'molecular basis set'/
     *40x,19('-')//
     *' no. of gtos = ',i3/
     */7x,'ordered list of basis functions'/)
      do 9021 i=1,iorbs
      kk=new(i)
      x0=x(kk)
      y0=y(kk)
      z0=z(kk)
      do 9022 j=1,knu
      if( (dabs(x0-cx(j)).lt.d5) .
     * and. (dabs(y0-cy(j)).lt.d5).
     * and. (dabs(z0-cz(j)).lt.d5) ) go to 9023
 9022 continue
      call caserr(
     *'attempt to cite basis function on unknown centre')
 9023 icen=j
      j=ii(kk)*9+ij(kk)*3+ik(kk)
      do 9024 k=1,10
      if(j.eq.inumb(k))go to 9025
 9024 continue
      call caserr(
     *'basis function of unknown type detected')
 9025 if(k.eq.1)j=1
      if(k.gt.1.and.k.le.4)j=2
      if(k.ge.5)j=3
      l=ic(kk)
      write(iwr,9026)i,icen,is(j),stype(k)
      do 9028 j=1,l
      kkj = j + ilife(kk)
 9028 write(iwr,9002)cbb(kkj),cc(kkj)
 9021 continue
 9029 write(iwr,9009)(dash,j=1,104)
 9009 format(/1x,104a1)
 9026 format(/' orbital centre   type sub-type'/
     *i8,i7,4x,a1,7x,a2//
     *11x,'ctran',12x,'zeta')
      do 421 i=1,iorbs
      kk=i
      x0=x(kk)
      y0=y(kk)
      z0=z(kk)
      do 422 j=1,knu
      if( (dabs(x0-cx(j)).lt.d5) .
     * and. (dabs(y0-cy(j)).lt.d5).
     * and. (dabs(z0-cz(j)).lt.d5) ) go to 423
 422  continue
      call caserr('parameter error in property routines')
 423  icen=j
      mfg(i)=j
 421  continue
c     write (iwr,5243) (mfg(i),i=1,22)
c5243 format(5x,18i8)
      call nmruc(chg,cx,cy,cz,knu)
      debye=2.541587d0
      h(1)=0.0d0
      h(2)=dinx
      h(3)=diny
      h(4)=dinz
      h(5)=qnxx
      h(6)=qnyy
      h(7)=qnzz
      h(8)=qnxy
      h(9)=qnxz
      h(10)=qnyz
      h(11)=0.0d0
      call rewftn(lun01)
      write (lun01) f
      call rewftn(lun01)
      t1(1)=4.0d0
      t2(1)=2.0d0
      t3(1)=0.5d0
      j=1
      do 128 i=2,5
      j=j+2
      t1(i)=(t1(i-1)*4)/j
      t3(i)=t3(i-1)*j*0.5d0
  128 t2(i)=dsqrt(t1(i))
      mm=0
      do 101 k=1,iorbs
      lcomp(k)=ic(k)
      lco=lcomp(k)
      kkk = ilife(k)
      kkkk = kkk
      do 30 l=1,lco
      zeta(l+kkkk)=cc(l+kkk)
  30  d(l+kkkk)=cbb(l+kkk)
      lco=ic(k)
      mi2=ii(k)
      t1f=fac
      if(mi2.gt.0) t1f=t1f*t2(mi2)
      mj2=ij(k)
      if(mj2.gt.0) t1f=t1f*t2(mj2)
      mk2=ik(k)
      if(mk2.gt.0) t1f=t1f*t2(mk2)
      maxijk=mi2
      if(maxijk.lt.mj2) maxijk=mj2
      if(maxijk.lt.mk2) maxijk=mk2
      mi3=mi2+1
      mj3=mj2+1
      mk3=mk2+1
      fun=mi2+mj2+mk2
      farx=0.5d0*fun+0.75d0
       gun=fun*0.5d0
      mi4=mi2*(mi2-1)/2
      mj4=mj2*(mj2-1)/2
      mk4=mk2*(mk2-1)/2
      x0=x(k)
      y0=y(k)
      z0=z(k)
      sum=0.0d0
      do 550 l=1,lco
      a1=zeta(l+kkkk)
      ga=d(l+kkkk)*(a1**(0.75d0+gun))
      do 550 l2=1,lco
      b=zeta(l2+kkkk)
      gb=dsqrt(b)/(a1+b)
  550 sum=sum+ga*d(l2+kkkk)*(gb**(1.5d0+fun))
      sum=sum*fac*(2.0d0**fun)
      anorm(k)=1.0d0/dsqrt(sum)
      t1f=t1f*anorm(k)
      do 2 l=1,k
      mm=mm+1
      llll = ilife(l)
      ni3=ii(l)
      nj3=ij(l)
      nk3=ik(l)
      suma=0.0d0
      sumb=0.0d0
      sumc=0.0d0
      sumd=0.0d0
      sume=0.0d0
      sumf=0.0d0
      sumg=0.0d0
      sumh=0.0d0
      sumi=0.0d0
      sumj=0.0d0
      sumk=0.0d0
      t2f=t1f*anorm(l)
      if(ni3.gt.0) t2f=t2f*t2(ni3)
      if(nj3.gt.0) t2f=t2f*t2(nj3)
      if(nk3.gt.0) t2f=t2f*t2(nk3)
      fbrx=0.5d0*(ni3+nj3+nk3)+0.75d0
      nax=ni3
      if(nax.lt.nj3) nax=nj3
      if(nax.lt.nk3) nax=nk3
      nax=nax+2
      x5=x(l)
      y5=y(l)
      z5=z(l)
      ni4=ni3+1
      ni5=ni4+1
      nia=ni5+1
      nib=ni3-1
      if(ni3.lt.3) go to 143
      ni8=(ni3-3)*(ni3-2)/2-1
  143 ni6=ni3*(ni3-1)/2
      ni7=ni5*(ni5-1)/2-1
      nj4=nj3+1
      nj5=nj4+1
      nja=nj5+1
      njb=nj3-1
      if(nj3.lt.3) go to 144
      nj8=(nj3-3)*(nj3-2)/2-1
  144 nj6=nj3*(nj3-1)/2
      nj7=nj5*(nj5-1)/2-1
      nk4=nk3+1
      nk5=nk4+1
      nka=nk5+1
      nkb=nk3-1
      if(nk3.lt.3) go to 145
      nk8=(nk3-3)*(nk3-2)/2-1
  145 nk6=nk3*(nk3-1)/2
      nk7=nk5*(nk5-1)/2-1
      dif(1)=x(l)-x0
      dif(2)=y(l)-y0
      dif(3)=z(l)-z0
      difsum=0.0d0
      do 10 i1=1,3
      dif2(i1)=dif(i1)*dif(i1)
  10  difsum=difsum+dif2(i1)
      lc1=ic(l)
      nxx=mi2+ni3+1
      nxy=mj2+nj3+1
      nxz=mk2+nk3+1
      mxx=nxx+1
      mxy=nxy+1
      mxz=nxz+1
      nox=mxx
      if(nox.lt.mxy) nox=mxy
      if(nox.lt.mxz) nox=mxz
      bax=dif(1)
      bay=dif(2)
      baz=dif(3)
      zxf(1)=bax
      zyf(1)=bay
      zzf(1)=baz
      do 130 i=2,mxx
  130 zxf(i)=zxf(i-1)*bax
      do 132 i=2,mxy
  132 zyf(i)=zyf(i-1)*bay
      do 134 i=2,mxz
  134 zzf(i)=zzf(i-1)*baz
      do 3 l1=1,lco
      aa=zeta(l1+kkkk)
      qx=aa*x0
      qy=aa*y0
      qz=aa*z0
      tuffy=d(l1+kkkk)*(aa**farx)
      am=-aa
      af(1)=am
      aab2=difsum*aa
      do 136 i=2,nax
  136 af(i)=am*af(i-1)
      do 3 l2=1,lc1
      bb=zeta(l2+llll)
      bb3=-2.0d0*bb*bb
      alp=aa+bb
      alg=1.0d0/alp
      arg=aab2*bb*alg
      if(arg.gt.thrs) go to 3
      tuf=tuffy*dexp(-arg)
      tuf=tuf*d(l2+llll)*(bb**fbrx)
      if(maxijk.eq.0) go to 141
      bf(1)=bb
      if(maxijk.eq.1) go to 141
      do 907 i=2,maxijk
  907 bf(i)=bf(i-1)*bb
  141 tuf=tuf*(alg**1.5d0)
      alf(1)=alg
      do 151 i=2,nox
  151 alf(i)=alf(i-1)*alg
      sxma=0.0d0
      sxmb=0.0d0
      sxmc=0.0d0
      syma=0.0d0
      symb=0.0d0
      symc=0.0d0
      szma=0.0d0
      szmb=0.0d0
      szmc=0.0d0
      sxmd=0.0d0
      sxme=0.0d0
      symd=0.0d0
      syme=0.0d0
      szmd=0.0d0
      szme=0.0d0
      px=(qx+bb*x5)*alg
      py=(qy+bb*y5)*alg
      pz=(qz+bb*z5)*alg
      mi5=mi4
      do 140 i=1,mi3
      w4=1.0d0
      if(i.eq.1) go to 142
      mi5=mi5+1
      w4=icom(mi5)*bf(i-1)
  142 ni9=ni6
      do 146 j=1,ni4
      w5=w4
      if(j.eq.1) go to 147
      ni9=ni9+1
      w5=w5*icom(ni9)*af(j-1)
  147 i9=i+j-2
      if(i9.gt.0) w5=w5*zxf(i9)
      i8=nxx-i9
      i7=i8/2
      i4=i7+i9
      if(i8-i7*2.eq.0) go to 153
      w6=w5*alf(i4+1)
      if(i4.gt.0) w5=w5*alf(i4)
      w6=w6*t3(i7+1)
      if(i7.gt.0) w5=w5*t3(i7)
      sxma=sxma+w5
      sxmc=sxmc+w6
      go to 146
 153  w5=w5*alf(i4)*t3(i7)
      sxmb=sxmb+w5
 146   continue
       ni9=ni7
       do 300 j=1,nia
       ni9=ni9+1
       i9=i+j-2
       i8=mxx-i9
       i7=i8/2
       if(i8-i7*2.ne.0) go to 300
       w5=w4
       if(i7.eq.0) go to 301
       w5=w5*t3(i7)*alf(i7+i9)
       go to 302
 301   if(i9.gt.0) w5=w5*alf(i9)*zxf(i9)
       go to 303
 302    if(i9.gt.0) w5=w5*zxf(i9)
 303   if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
       sxmd=sxmd+w5
 300   continue
       if(ni3.lt.2) go to 140
       ni9=ni8
       do 304 j=1,nib
       ni9=ni9+1
       i9=i+j-2
       i8=mxx-i9-4
       i7=i8/2
       if(i8-i7*2.ne.0) go to 304
       w5=w4
       if(i7.eq.0) go to 305
       w5=w5*t3(i7)*alf(i7+i9)
       go to 306
305    if(i9.gt.0) w5=w5*alf(i9)*zxf(i9)
       go to 307
 306    if(i9.gt.0) w5=w5*zxf(i9)
 307   if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
       sxme=sxme+w5
 304   continue
 140   continue
      mi5=mj4
      do 160 i=1,mj3
      w4=1.0d0
      if(i.eq.1) go to 162
      mi5=mi5+1
      w4=icom(mi5)*bf(i-1)
  162 ni9=nj6
      do 166 j=1,nj4
      w5=w4
      if(j.eq.1) go to 167
      ni9=ni9+1
      w5=w5*icom(ni9)*af(j-1)
  167 i9=i+j-2
      if(i9.gt.0) w5=w5*zyf(i9)
      i8=nxy-i9
      i7=i8/2
      i4=i7+i9
      if(i8-i7*2.eq.0) go to 173
      w6=w5*alf(i4+1)
      if(i4.gt.0) w5=w5*alf(i4)
      w6=w6*t3(i7+1)
      if(i7.gt.0) w5=w5*t3(i7)
      syma=syma+w5
      symc=symc+w6
      go to 166
 173  w5=w5*alf(i4)*t3(i7)
      symb=symb+w5
 166  continue
       ni9=nj7
       do 320 j=1,nja
       ni9=ni9+1
       i9=i+j-2
       i8=mxy-i9
       i7=i8/2
       if(i8-i7*2.ne.0) go to 320
       w5=w4
       if(i7.eq.0) go to 321
       w5=w5*t3(i7)*alf(i7+i9)
       go to 322
 321   if(i9.gt.0) w5=w5*alf(i9)*zyf(i9)
       go to 323
 322    if(i9.gt.0) w5=w5*zyf(i9)
 323   if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
       symd=symd+w5
 320   continue
       if(nj3.lt.2) go to 160
       ni9=nj8
       do 324 j=1,njb
       ni9=ni9+1
       i9=i+j-2
       i8=mxy-i9-4
       i7=i8/2
       if(i8-i7*2.ne.0) go to 324
       w5=w4
       if(i7.eq.0) go to 325
       w5=w5*t3(i7)*alf(i7+i9)
       go to 326
325    if(i9.gt.0) w5=w5*alf(i9)*zyf(i9)
       go to 327
 326    if(i9.gt.0) w5=w5*zyf(i9)
 327   if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
       syme=syme+w5
 324   continue
 160   continue
      mi5=mk4
      do 180 i=1,mk3
      w4=1.0d0
      if(i.eq.1) go to 182
      mi5=mi5+1
      w4=icom(mi5)*bf(i-1)
  182 ni9=nk6
      do 186 j=1,nk4
      w5=w4
      if(j.eq.1) go to 187
      ni9=ni9+1
      w5=w5*icom(ni9)*af(j-1)
  187 i9=i+j-2
      if(i9.gt.0) w5=w5*zzf(i9)
      i8=nxz-i9
      i7=i8/2
      i4=i7+i9
      if(i8-i7*2.eq.0) go to 193
      w6=w5*alf(i4+1)
      if(i4.gt.0) w5=w5*alf(i4)
      w6=w6*t3(i7+1)
      if(i7.gt.0) w5=w5*t3(i7)
      szma=szma+w5
      szmc=szmc+w6
      go to 186
 193  w5=w5*alf(i4)*t3(i7)
      szmb=szmb+w5
 186   continue
       ni9=nk7
       do 340 j=1,nka
       ni9=ni9+1
       i9=i+j-2
       i8=mxz-i9
       i7=i8/2
       if(i8-i7*2.ne.0) go to 340
       w5=w4
       if(i7.eq.0) go to 341
       w5=w5*t3(i7)*alf(i7+i9)
       go to 342
 341   if(i9.gt.0) w5=w5*alf(i9)*zzf(i9)
       go to 343
 342    if(i9.gt.0) w5=w5*zzf(i9)
 343   if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
       szmd=szmd+w5
 340   continue
       if(nk3.lt.2) go to 180
       ni9=nk8
       do 344 j=1,nkb
       ni9=ni9+1
       i9=i+j-2
       i8=mxz-i9-4
       i7=i8/2
       if(i8-i7*2.ne.0) go to 344
       w5=w4
       if(i7.eq.0) go to 345
       w5=w5*t3(i7)*alf(i7+i9)
       go to 346
345    if(i9.gt.0) w5=w5*alf(i9)*zzf(i9)
       go to 347
 346    if(i9.gt.0) w5=w5*zzf(i9)
 347   if(j.gt.1) w5=w5*icom(ni9)*af(j-1)
       szme=szme+w5
 344   continue
 180   continue
       sumg=sumg+tuf*sxma*syma*szma
       suma=suma+tuf*(sxmb+px*sxma)*syma*szma
       sumb=sumb+tuf*(symb+py*syma)*szma*sxma
       sumc=sumc+tuf*(szmb+pz*szma)*syma*sxma
       sumd=sumd+tuf*(sxmc+2.0d0*px*sxmb+px*px*sxma)*syma*szma
       sume=sume+tuf*(symc+2.0d0*py*symb+py*py*syma)*sxma*szma
       sumf=sumf+tuf*(szmc+2.0d0*pz*szmb+pz*pz*szma)*sxma*syma
       sumh=sumh+tuf*(sxmb+px*sxma)*(symb+py*syma)*szma
       sumi=sumi+tuf*(sxmb+px*sxma)*(szmb+pz*szma)*syma
       sumj=sumj+tuf*(symb+py*syma)*(szmb+pz*szma)*sxma
       w5=bb3*sxmd
       w5=w5+(2.0d0*ni3+1.0d0)*bb*sxma
       w5=w5-ni6*sxme
       w4=w5*syma*szma
       w5=bb3*symd
       w5=w5+(2.0d0*nj3+1.0d0)*bb*syma
       w5=w5-nj6*syme
       w4=w5*sxma*szma+w4
       w5=bb3*szmd
       w5=w5+(2.0d0*nk3+1.0d0)*bb*szma
       w5=w5-nk6*szme
       w4=w4+w5*sxma*syma
       sumk=sumk+tuf*w4
 3    continue
       ovl(mm)=t2f*sumg
       dipx(mm)=-t2f*suma
       dipy(mm)=-t2f*sumb
       dipz(mm)=-t2f*sumc
       qdxx(mm)=-t2f*sumd
       qdyy(mm)=-t2f*sume
       qdzz(mm)=-t2f*sumf
       qdxy(mm)=-t2f*sumh
       qdxz(mm)=-t2f*sumi
       qdyz(mm)=-t2f*sumj
       tvl(mm)=t2f*sumk
 2     continue
 101  continue
      call rewftn(lun02)
      write     (lun02) ovl
      write     (lun02) dipx
      write     (lun02) dipy
      write     (lun02) dipz
      write     (lun02) qdxx
      write     (lun02) qdyy
      write     (lun02) qdzz
      write     (lun02) qdxy
      write     (lun02) qdxz
      write     (lun02) qdyz
      write     (lun02) tvl
c
c    now print ao integrals if requested
c
      j=0
      do 9030 i=1,11
      if(iaopr(i))go to 9030
      write(iwr,9031)mopr(i)
 9031 format(//40x,'a.o. integrals ***   ',a2,'- matrix ***'/
     *40x,36('-')//)
      call writex(ovl(j+1),new,iorbs,iwr)
      write(iwr,9009)(dash,l=1,104)
 9030 j=j+len
c
      call rewftn(lun02)
      read (lun01) f
      call rewftn(lun01)
      ksum=icore+imo
      jmax=ksum*iorbs
      do 41 i=1,11
      read (lun02) tigl
      call vclr(temp,1,jmax)
      jdx=0
      do 42 j=1,iorbs
      do 42 k=1,j
      jdx=jdx+1
      big=tigl(ind(j,k))
      if (dabs(big).lt.1.0d-14) go to 42
      kdx=-iorbs
      do 43 l=1,ksum
      kdx=kdx+iorbs
      ig=kdx+j
      jg=kdx+k
      temp(ig)=temp(ig)+big*f(jg)
      if (j.eq.k) go to 43
      temp(jg)=temp(jg)+big*f(ig)
   43 continue
   42 continue
      kdx=0
      if (icore.eq.0) go to 44
      do 46 j=1,icore
      sum=0.0d0
      do 45 k=1,iorbs
      kdx=kdx+1
   45 sum=sum+f(kdx)*temp(kdx)
   46 pig(j)=sum
   44 imark=icore
      do 47 j=1,n
      ljn=lj(j)
      mdx=kdx
      do 48 k=1,ljn
      ldx=kdx
      do 50 l=1,k
      imark=imark+1
      sum=0.0d0
      mdy=mdx
      do 49 m=1,iorbs
      mdy=mdy+1
      ldx=ldx+1
   49 sum=sum+f(mdy)*temp(ldx)
   50 pig(imark)=sum
   48 mdx=mdy
   47 kdx=mdx
      if(imopr(i))go to 41
      write(iwr,9009)(dash,j=1,104)
      write (iwr,81)mopr(i)
 81   format(//40x,'m.o. integrals ***   ',a2,'- matrix ***'/
     *40x,36('-')//)
      if (icore.eq.0) go to 77
      write(iwr,9040)
 9040 format(/10x,'frozen core orbitals'/
     *'   orbital   integral'//)
      do 78 jj=1,icore
   78 write (iwr,79) jj,pig(jj)
   79 format (i10,f20.8)
   77 kdx=icore
      write(iwr,9041)
 9041 format(//10x,'integrals over active orbitals'//
     *4(' irrep.  i  j',19x)//)
      l=0
      do 80 jj=1,n
      ljn=lj(jj)
      do 80 j=1,ljn
      do 80 k=1,j
      kdx=kdx+1
      l=l+1
      ia(l)=jj
      ja(l)=j
      ka(l)=k
      temp(l)=pig(kdx)
      if(l.lt.4)go to 80
      write (iwr,9042) (ia(l),ja(l),ka(l),temp(l),l=1,4)
 9042 format(4(i4,3x,2i3,1x,f12.6,6x ))
      l=0
 80   continue
      if(l.ne.0)write(iwr,9042)
     *(ia(j),ja(j),ka(j),j=1,l)
   41 write (lun01) pig
      ich=0
      ijp=1
      do 53 i=1,istate
      write(iwr,9050)i
 9050 format(/1x,104('-')//
     *40x,37('-')/
     *40x,'molecular properties for state no.',i3/
     *40x,37('-')/)
      call setsto(imo,0,jcon)
      np=jkonp(ijp)
      do 7001 j=1,nshl
7001  jkon(j)=jkonp(ijp+j)
      ijp=ijp+maxshl1
      if(np.eq.0) go to 32
      do 34 j=1,np
      idx=jkon(j)
 34   jcon(idx)=1
 32   ib=(mlec-np)/2+np
      np1=np+1
      do 35 j=np1,ib
      idx=jkon(j)
 35   jcon(idx)=2
c
c  check for no scf configuration specified and kill el. scf terms
c
      if(noscfp) then
       doscf = .false.
      else
       do j=np1,ib
        if(jkon(j).le.0) then
         doscf = .false.
         go to 33336
        endif
       enddo
      endif
33336 if(doscf) then
       write(iwr,1)
 1     format(/
     * ' *** corresponding single configuration for this state :')
       if(np.eq.0)go to 9060
       write(iwr,9051)np,(jkon(j),j=1,np)
 9051  format(/' sequence nos. of ',i2,
     * ' open shell orbitals'//
     * 10x,6i3)
       go to 9052
 9060  write(iwr,9054)
 9054  format(/' no open shell orbitals')
 9052  j=ib-np
       write(iwr,9055)j,(jkon(j),j=np1,ib)
 9055  format(/
     * ' sequence nos. of ',i2,' doubly occupied orbitals'//
     * 10x,30i3)
      endif
   54 ich=ich+1
      if (ich.eq.ipig(i)) go to 55
      read (lund)
      go to 54
   55 read (lund) k,(q(j),j=1,k)
      call rewftn(lun02)
      read (lun02) tigl
      call rewftn(lun02)
      call pmrd1(q,f,tigl,scr1,scr2,lj,iky,iorbs,icore,
     +           knu,imo,ksum,n,mfg)
      idx=0
      do 61 j=1,imo
      do 61 k=1,j
      idx=idx+1
      if (j.eq.k) go to 61
      q(idx)=q(idx)+q(idx)
   61 continue
      call rewftn(lun01)
      do 70 j=1,11
      read (lun01) pig
      sum=0.0d0
      if (icore.eq.0) go to 72
      do 71 k=1,icore
   71 sum=sum+2.0d0*pig(k)
   72 scf=sum
      kdx=icore
      ipr=0
      do 73 k=1,n
      ljn=lj(k)
      lpr=ipr
      do 74 l=1,ljn
      lpr=lpr+1
      lrr=lpr
      mpr=ipr
      jrr=iky(lrr)
      do 74 m=1,l
      kdx=kdx+1
      mpr=mpr+1
      mrr=mpr+jrr
      ant=pig(kdx)
      sum=sum+ant*q(mrr)
      if (l.ne.m) go to 74
      if(jcon(lrr).eq.0) goto 74
      scf=scf+ant*jcon(lrr)
   74 continue
   73 ipr=lpr
      s(j)=scf
   70 t(j)=sum
      write (iwr,76) ich
   76 format(/30x,' molecular properties for state no.',i3,
     +            ' on output tape'//)
      if(doscf) then
      write(iwr,201)
  201 format(25x,'EL.SCF',7x,'NUCLEAR',10x,'EL.CI',6x,'TOTAL SCF',
     +        7x,'TOTAL CI'/10x,85('=')/)
      ovs=s(1)
      ovc=t(1)
      zero=0.0d0
      write(iwr,202) ovs,zero,ovc,ovs,ovc
  202 format(10x,'overlap',3x,5f15.8/)
      dinx=h(2)
      disx=s(2)
      dicx=t(2)
      f1=dinx+disx
      f2=dinx+dicx
      write(iwr,203)disx,dinx,dicx,f1,f2
  203 format(10x,'dipole(x)',1x,5f15.8/)
      diny=h(3)
      disy=s(3)
      dicy=t(3)
      f1=diny+disy
      f2=diny+dicy
      write(iwr,204)disy,diny,dicy,f1,f2
  204 format(10x,'dipole(y)',1x,5f15.8/)
      dinz=h(4)
      disz=s(4)
      dicz=t(4)
      f1=dinz+disz
      f2=dinz+dicz
      write(iwr,205)disz,dinz,dicz,f1,f2
  205 format(10x,'dipole(z)',1x,5f15.8/)
      dinxd=dinx*debye
      disxd=disx*debye
      dicxd=dicx*debye
      dinyd=diny*debye
      disyd=disy*debye
      dicyd=dicy*debye
      dinzd=dinz*debye
      diszd=disz*debye
      diczd=dicz*debye
      write(iwr,2200)
 2200 format(/10x,'dipole moment in debye'/)
      f1=dinxd+disxd
      f2=dinxd+dicxd
      write(iwr,203)  disxd,dinxd,dicxd,f1,f2
      f1=dinyd+disyd
      f2=dinyd+dicyd
      write(iwr,204) disyd,dinyd,dicyd,f1,f2
      f1= dinzd+diszd
      f2=dinzd+diczd
      write(iwr,205) diszd,dinzd,diczd,f1,f2
      qnxx=h(5)
      qusxx=s(5)
      qcxx=t(5)
      f1=qnxx+qusxx
      f2=qnxx+qcxx
      write(iwr,206) qusxx,qnxx,qcxx,f1,f2
  206 format(//10x,'quad(xx)',2x,5f15.8/)
      qnyy=h(6)
      qusyy=s(6)
      qcyy=t(6)
      f1=qnyy+qusyy
      f2=qnyy+qcyy
      write(iwr,207) qusyy,qnyy,qcyy,f1,f2
  207 format(10x,'quad(yy)',2x,5f15.8/)
      qnzz=h(7)
      quszz=s(7)
      qczz=t(7)
      f1=qnzz+quszz
      f2=qnzz+qczz
      write(iwr,208) quszz,qnzz,qczz,f1,f2
  208 format(10x,'quad(zz)',2x,5f15.8/)
      qnxy=h(8)
      qusxy=s(8)
      qcxy=t(8)
      f1=qnxy+qusxy
      f2=qnxy+qcxy
      write(iwr,209) qusxy,qnxy,qcxy,f1,f2
  209 format(10x,'quad(xy)',2x,5f15.8/)
      qnxz=h(9)
      qusxz=s(9)
      qcxz=t(9)
      f1=qnxz+qusxz
      f2=qnxz+qcxz
      write(iwr,210) qusxz,qnxz,qcxz,f1,f2
  210 format(10x,'quad(xz)',2x,5f15.8/)
      qnyz=h(10)
      qusyz=s(10)
      qcyz=t(10)
      f1=qnyz+qusyz
      f2=qnyz+qcyz
      write(iwr,211) qusyz,qnyz,qcyz,f1,f2
  211 format(10x,'quad(yz)',2x,5f15.8/)
      tvs=s(11)
      tvc=t(11)
      write(iwr,222) tvs,zero,tvc,tvs,tvc
  222 format(10x,'kinetic e.',5f15.8/)
      else
c     no leading term available
      write(iwr,2201)
 2201 format(25x,'NUCLEAR',10x,'El.CI',
     +        7x,'TOTAL CI'/10x,55('=')/)
      ovc=t(1)
      zero=0.0d0
      write(iwr,2202) zero,ovc,ovc
 2202 format(10x,'overlap',3x,3f15.8/)
      dinx=h(2)
      dicx=t(2)
      f2=dinx+dicx
      write(iwr,2203)dinx,dicx,f2
 2203 format(10x,'dipole(x)',1x,3f15.8/)
      diny=h(3)
      dicy=t(3)
      f2=diny+dicy
      write(iwr,2204)diny,dicy,f2
 2204 format(10x,'dipole(y)',1x,3f15.8/)
      dinz=h(4)
      dicz=t(4)
      f2=dinz+dicz
      write(iwr,2205)dinz,dicz,f2
 2205 format(10x,'dipole(z)',1x,3f15.8/)
      dinxd=dinx*debye
      dicxd=dicx*debye
      dinyd=diny*debye
      dicyd=dicy*debye
      dinzd=dinz*debye
      diczd=dicz*debye
      write(iwr,22001)
22001 format(/10x,'dipole moment in debye'/)
      f2=dinxd+dicxd
      write(iwr,2203) dinxd,dicxd,f2
      f2=dinyd+dicyd
      write(iwr,2204) dinyd,dicyd,f2
      f2=dinzd+diczd
      write(iwr,2205) dinzd,diczd,f2
      qnxx=h(5)
      qcxx=t(5)
      f2=qnxx+qcxx
      write(iwr,2206) qnxx,qcxx,f2
 2206 format(//10x,'quad(xx)',2x,3f15.8/)
      qnyy=h(6)
      qcyy=t(6)
      f2=qnyy+qcyy
      write(iwr,2207) qnyy,qcyy,f2
 2207 format(10x,'quad(yy)',2x,3f15.8/)
      qnzz=h(7)
      qczz=t(7)
      f2=qnzz+qczz
      write(iwr,2208) qnzz,qczz,f2
 2208 format(10x,'quad(zz)',2x,3f15.8/)
      qnxy=h(8)
      qcxy=t(8)
      f2=qnxy+qcxy
      write(iwr,2209) qnxy,qcxy,f2
 2209 format(10x,'quad(xy)',2x,3f15.8/)
      qnxz=h(9)
      qcxz=t(9)
      f2=qnxz+qcxz
      write(iwr,2210) qnxz,qcxz,f2
 2210 format(10x,'quad(xz)',2x,3f15.8/)
      qnyz=h(10)
      qcyz=t(10)
      f2=qnyz+qcyz
      write(iwr,2211) qnyz,qcyz,f2
 2211 format(10x,'quad(yz)',2x,3f15.8/)
      tvc=t(11)
      write(iwr,2222) zero,tvc,tvc
 2222 format(10x,'kinetic e.',3f15.8/)
c
      endif
   53 continue
      write(iwr,9009)(dash,j=1,104)
      call rewftn(lun01)
      call rewftn(lun02)
      cpu=cpulft(1)
      write(iwr,8001)cpu ,charwall()
 8001 format(//
     *' *** end of Table-Ci properties calculation at ',
     *f8.2,' seconds',a10,' wall'/)
      return
      end
      subroutine ver_newmrd6(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/newmrd6.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
