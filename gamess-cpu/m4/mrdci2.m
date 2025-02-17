c 
c  $Author: jmht $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mrdci2.m,v $
c  $State: Exp $
c  
c ******************************************************
c ******************************************************
c             =   Table-ci (tran4 module) =
c ******************************************************
c ******************************************************
      subroutine tmrdci(x,lword)
      implicit REAL  (a-h,o-z), integer(i-n)
INCLUDE(common/sizes)
INCLUDE(common/prints)
      common/craypk/ic,i7,mj(8),kj(8),isecv,
     +              icore,ick(256),izer,iaus(256),ispcy(3867)
INCLUDE(common/discc)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/atmol3)
      common/lsort /space4(2000)
      dimension iq(4),x(*)
_IF(parallel)
INCLUDE(common/blksiz)
c
c     sort file settings
c
      nsz512=nsz*512
      nsz170=(nsz512-2)/3
      nsz85 =nsz170/2
      nszkl=nsz170+1
      nsz340=nsz170+nsz170
      nsz341=nsz340+1
      nsz510=nsz340+nsz170
      nszij=nsz340+1
      nsz342=nsz341+nsz85
      nsstat=0
_ENDIF
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
       write(iwr,18)lword
      endif
      if(num.le.0. or.num.gt.maxorb) call caserr(
     *'invalid number of basis functions')
      iq(1)=1
      do 26 i=2,4
 26   iq(i)=iq(i-1)+nx
      if((nx*5).gt.lword)call caserr
     *('insufficient memory available')
      call tmrdm(x(1),x(1),x(iq(4)),x(1),x(iq(2)),
     * x(1),x(iq(2)),x(iq(3)),lword)
      if(oprint(31))call secsum
      if(oprint(31))call whtps
      call clredx
      return
 6    format(//1x,104('=')//
     *40x,37('*')/
     *40x,'Table-Ci  -- transformation module --'/
     *40x,37('*')//
     *1x,'dumpfile on ',a4,' at block',i6)
 4    format(/1x,
     *'eigen vectors to be restored from section',i4)
 18   format(/' main core available = ',i8,' words')
      end
_IF(vax)
      subroutine tr2iii(ma,t,is)
_ELSE
      subroutine tr2iii(ma,t,is,res,mjx)
_ENDIF
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/mapper)
INCLUDE(common/prints)
INCLUDE(common/blksiz)
      common/stak/btri,mlow(2),irec
      common/scra /ixa(3400)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/bufb/nwbnwb,lnklnk,gout(5119)
      common/craypk/intin(2000),intout(2000)
      common/junk /cf(22500),icf(22500)
      common/b/ sum,gg,itape,jtape,ktape,mtape,ltape,mscr,nrac,nrecy,
_IF(vax)
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
_ELSE
     1nblk,ifrk,ifrk1,ik,if2,im,mjxx,kxl,njx,nzl,ina,il,iq,ib,icak,
_ENDIF
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ntape
_IF(vax)
      dimension f(751)
_ELSE
      dimension f(751),res(mjx,*)
_ENDIF
      dimension q(500),fm(251),pq(500),pli(251)
     +,is(*),t(*),gin(5119)
      equivalence (g(1),q(1)),(g(501),fm(1)),(fm(251),n2),
     +(gout(1),gin(1))
     +,(p(1),pq(1)),(p(501),pli(1)),(g(1),f(1))
      data maxb/9999999/
_IF(vax)
      mjx=nj(ma)
_ENDIF
      ljx=kj(ma)
      mmm=itil(ma)
      mmx=ibal(ma)
      ina=iky(mjx+1)
      im=ik/ina
      if (im.gt.ina) im=ina
      inb=iky(ljx+1)
      il=(inb-1)/im+1
      iq=(il-1)/if2+1
      il=(il-1)/iq+1
      ib=ik/il
      icak=ina*im
c
      nav = lenwrd()
c
      itx=ib/nav
      if(itx*nav.ne.ib) ib=ib-1
      if (ib.gt.nsz340) ib=nsz340
      itx=(nav+1)*ib
      ity=itx/nav
      ix=-ib
      iy=-ity
      imax=im*il
      ifm=-imax
      do  1  i=1,il
      ix=ix+itx
      iy=iy+ity
      mlr(i)=iy
      mli(i)=ix
      nrc(i)=maxb
    1 nfg(i)=0
      ig=0
      ig4=-3
      isb=0
      jsb=0
      if (iq.eq.1.or.ma.eq.1) go to 700
      call rewftn(mscr)
  701 read (ltape) f
      write(mscr) f
      if (n2.ne.0) go to 701
      ntape=mscr
      call rewftn(ntape)
      go to 702
  700 ntape=ltape
  702 do  2  i8=1,iq
      ifm=ifm+imax
      irec=0
      ilc=0
_IFN(cray)
      call setsto(2000,0,intin)
_ENDIF
   11 read (ntape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 3 jj=1,ifrk
      ijkl=intin(int4)
      if (ijkl.eq.0) go to 705
      i=ijkl
      j=intin(int4+1)
      idx=iky(i)+j-ifm
      if (idx.lt.1.or.idx.gt.imax) go to 3
      k=intin(int4+2)
      iln=(idx-1)/im+1
      kz=idx-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=q(jj)
      l=intin(int4+3)
      if(oprint(31)) then
       write(6,5566) jj,i,j,k,l,q(jj)
5566   format(1x,'tr2iii: i,j,k,l,val = ',i4,2x,4i4,5x,f20.10)
      endif
      is(mm)=(kz-1)*ina+iky(k)+l
      if=nfg(iln)+1
      if (if.eq.ib) go to 10
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
      go to 3
 10   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout,1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
    3 int4=int4+4
      go to 11
 705  do 13 jj=1,il
      nz=nfg(jj)
      if(nz.eq.0)go to 13
      call stopbk
      nwbnwb=nz
      lnklnk=nrc(jj)
      mq=mlr(jj)-nz
      mm=mli(jj)-nz
      call dcopy(nz,t(mq+1),1,gout,1)
      call pack(gout(nsz341),32,is(mm+1),nsz340)
      call sttout
      mlr(jj)=mq
      mli(jj)=mm
      nrc(jj)=irec
      irec=irec+nsz
 13   continue
c
      call stopbk
c
      imc=im
      i=isb
 200  i=i+1
      j=jsb
 201  j=j+1
      if(imc.lt.im) goto 40
      if (ilc.eq.il) go to 50
      ilc=ilc+1
      imc=0
      iwa=0
      call vclr(t,1,icak)
      lnklnk=nrc(ilc)
      go to 32
 33   iblok=lnklnk
      call rdbak(iblok)
      call stopbk
      call unpack(gin(nsz341),32,ixa,nsz340)
_IF(vax)
      do 332 moop=1,nwbnwb
      ixq=ixa(moop)
 332  t(ixq)=gin(moop)
_ELSEIF(cray)
      call scatter(nwbnwb,t,ixa,gin)
_ELSE
      call dsctr(nwbnwb,gin,ixa,t)
_ENDIF
 32   if(lnklnk.ne.maxb)go to 33
   40 imc=imc+1
      lx=mmx
      kk=mmm
_IFN1(v)      call square(res,t(iwa+1),mjx,mjx)
      do 41 k=1,i
      mlim=k
      if(i.eq.k) mlim=j
      kk=kk+1
      mcp=mcomp(kk)
      call vclr(v,1,mjx)
_IF(vax)
      do 43 ll=1,mcp
      lx=lx+1
      ld=icf(lx)
      sac=cf(lx)
      if (ld.eq.1) go to 850
      lda=ld-1
      iw=iwa+iky(ld)
      do 70 l=1,lda
      iw=iw+1
   70 v(l)=v(l)+sac*t(iw)
  850 iw=iwa+ld
      do 851 l=ld,mjx
      iz=iw+iky(l)
 851  v(l)=v(l)+t(iz)*sac
   43 continue
_ELSE
      do 43 ll=1,mcp
      lx=lx+1
      sac=cf(lx)
      ld=icf(lx)
_IF(cray)
      do 433 loop=1,mjx
433   v(loop)=v(loop)+sac*res(loop,ld)
_ELSE
      call daxpy(mjx,sac,res(1,ld),1,v,1)
_ENDIF
   43 continue
_ENDIF
      mx=mmx
      mm=mmm
      do 55 l=1,mlim
      mm=mm+1
      ncp=mcomp(mm)
_IF(vax)
      sum=0.0
      do 53 ll=1,ncp
      mx=mx+1
      ld=icf(mx)
  53  sum=sum+cf(mx)*v(ld)
_ELSEIF(cray)
      sum=spdot(ncp,v,icf(mx+1),cf(mx+1))
      mx=mx+ncp
_ELSE
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),v)
      mx=mx+ncp
_ENDIF
      ig=ig+1
      pq(ig)=sum
      ig4=ig4+4
      intout(ig4  )=i
      intout(ig4+1)=j
      intout(ig4+2)=k
      intout(ig4+3)=l
      if (ig.lt.ifrk) go to 55
      call pack(pli,8,intout,2000)
      write (mtape) p
      ig=0
      ig4=-3
   55 continue
   41 continue
      iwa=iwa+ina
        if( j.lt.i) go to 201
      jsb=0
      if(i.lt.ljx) go to 200
      ig4=ig4+4
      intout(ig4)=0
      intout(ig4+1)=0
      intout(ig4+2)=0
      intout(ig4+3)=0
      call pack(pli,8,intout,2000)
      write(mtape) p
      return
   50 isb=i-1
      jsb=j-1
      call rewftn(ntape)
      if (ma.gt.1) go to 762
      do 57 i=1,nrecy
   57 read (ntape)
  762 do 58 i=1,il
      nfg(i)=0
   58 nrc(i)=maxb
    2 continue
      return
      end
_IF(vax)
      subroutine tr2iij(ma,mb,t,is)
_ELSE
      subroutine tr2iij(ma,mb,t,is,res,mjx)
_ENDIF
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/mapper)
INCLUDE(common/prints)
INCLUDE(common/blksiz)
      common/stak/btri,mlow(2),irec
      common/scra /ixa(3400)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/bufb/nwbnwb,lnklnk,gout(5119)
      common/craypk/intin(2000),intout(2000)
      common/junk /cf(22500),icf(22500)
      common/b/ sum,gg,itape,jtape,ktape,mtape,ltape,mscr,nrac,nrecy,
_IFN1(v)     1nblk,ifrk,ifrk1,ik,if2,im,mjxx,kxl,njx,nzl,ina,il,iq,ib,icak,
_IF1(v)     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ntape
_IFN1(v)      dimension f(751),res(mjx,*)
_IF1(v)      dimension f(751)
      dimension q(500),fm(251),pq(500),pli(251)
     +,is(*),t(*),gin(5119)
      equivalence (g(1),q(1)),(g(501),fm(1)),(fm(251),n2),
     +(gin(1),gout(1))
     +,(p(1),pq(1)),(p(501),pli(1)),(g(1),f(1))
      data maxb/9999999/
_IF1(v)      mjx=nj(mb)
      mjy=kj(ma)
      ljx=kj(mb)
      ina=iky(mjx+1)
      inb=iky(mjy+1)
      im=ik/ina
      mmx=ibal(mb)
      mmm=itil(mb)
      if(im.gt.inb) im=inb
      il=(inb-1)/im+1
      iq=(il-1)/if2+1
      il=(il-1)/iq+1
      ib=ik/il
      icak=ina*im
c
      nav = lenwrd()
c
      itx=ib/nav
      if(itx*nav.ne.ib) ib=ib-1
      if(ib.gt.nsz340) ib=nsz340
      itx=(nav+1)*ib
      ity=itx/nav
      ix=-ib
      iy=-ity
      imax=im*il
      ifm=-imax
      do 1 i=1,il
      ix=ix+itx
       iy=iy+ity
      mlr(i)=iy
      mli(i)=ix
      nrc(i)=maxb
 1    nfg(i)=0
      ig=0
      ig4=-3
       isb=0
       jsb=0
      if(iq.eq.1) go to 700
      call rewftn(mscr)
 701  read(ltape) f
      write(mscr) f
      if(n2.ne.0) goto 701
       ntape=mscr
       call rewftn(ntape)
      goto 702
 700   ntape=ltape
 702  do 2 i8=1,iq
_IFN(cray)
      call setsto(2000,0,intin)
_ENDIF
      ifm=ifm+imax
       irec=0
       ilc=0
  11  read(ntape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 3 jj=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 705
      i=ijkl
      j=intin(int4+1)
      idx=iky(i)+j-ifm
      if(idx.lt.1.or.idx.gt.imax) goto 3
      k=intin(int4+2)
      iln=(idx-1)/im+1
      kz=idx-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=q(jj)
      l=intin(int4+3)
      if(oprint(31)) then
       write(6,5566) jj,i,j,k,l,q(jj)
5566   format(1x,'tr2iij: i,j,k,l,val = ',i4,2x,4i4,5x,f20.10)
      endif
      is(mm)=(kz-1)*ina+iky(k)+l
      if=nfg(iln)+1
      if (if.eq.ib) goto 10
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
       goto 3
 10   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout,1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
 3     int4=int4+4
      goto 11
 705  do 13 jj=1,il
      nz=nfg(jj)
      if(nz.eq.0)go to 13
      call stopbk
      nwbnwb=nz
      lnklnk=nrc(jj)
      mq=mlr(jj)-nz
      mm=mli(jj)-nz
      call dcopy(nz,t(mq+1),1,gout,1)
      call pack(gout(nsz341),32,is(mm+1),nsz340)
      call sttout
      mlr(jj)=mq
      mli(jj)=mm
      nrc(jj)=irec
      irec=irec+nsz
 13   continue
c
      call stopbk
c
       imc=im
        i=isb
 200   i=i+1
      j=jsb
 201    j=j+1
      if(imc.lt.im) goto 40
      if(ilc.eq.il) goto 50
      ilc=ilc+1
      imc=0
      iwa=0
      call vclr(t,1,icak)
      lnklnk=nrc(ilc)
      go to 32
 33   iblok=lnklnk
      call rdbak(iblok)
      call stopbk
      call unpack(gin(nsz341),32,ixa,nsz340)
_IF(vax)
      do 332 moop=1,nwbnwb
      ixq=ixa(moop)
 332  t(ixq)=gin(moop)
_ELSEIF(cray)
      call scatter(nwbnwb,t,ixa,gin)
_ELSE
      call dsctr(nwbnwb,gin,ixa,t)
_ENDIF
 32   if(lnklnk.ne.maxb)go to 33
 40    imc=imc+1
      lx=mmx
      kk=mmm
_IFN1(v)      call square(res,t(iwa+1),mjx,mjx)
      do 41 k=1,ljx
      kk=kk+1
      mcp=mcomp(kk)
      call vclr(v,1,mjx)
_IF(vax)
      do 43 ll=1,mcp
      lx=lx+1
      ld=icf(lx)
      sac=cf(lx)
      if (ld.eq.1) go to 850
      lda=ld-1
      iw=iwa+iky(ld)
      do 70 l=1,lda
      iw=iw+1
   70 v(l)=v(l)+sac*t(iw)
  850 iw=iwa+ld
      do 851 l=ld,mjx
      iz=iw+iky(l)
 851  v(l)=v(l)+t(iz)*sac
   43 continue
_ELSE
      do 43 ll=1,mcp
      lx=lx+1
      sac=cf(lx)
      ld=icf(lx)
_IF(cray)
      do 433 loop=1,mjx
433   v(loop)=v(loop)+sac*res(loop,ld)
_ELSE
      call daxpy(mjx,sac,res(1,ld),1,v,1)
_ENDIF
   43 continue
_ENDIF
      mx=mmx
      mm=mmm
      do 55 l=1,k
      mm=mm+1
      ncp=mcomp(mm)
_IF(vax)
      sum=0.0
      do 53 ll=1,ncp
      mx=mx+1
      ld=icf(mx)
  53  sum=sum+cf(mx)*v(ld)
_ELSEIF(cray)
      sum=spdot(ncp,v,icf(mx+1),cf(mx+1))
      mx=mx+ncp
_ELSE
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),v)
      mx=mx+ncp
_ENDIF
      ig=ig+1
      pq(ig)=sum
      ig4=ig4+4
      intout(ig4  )=i
      intout(ig4+1)=j
      intout(ig4+2)=k
      intout(ig4+3)=l
      if(ig.lt.ifrk) goto 55
      call pack(pli,8,intout,2000)
      ig4=-3
      write(mtape) p
       ig=0
  55   continue
  41   continue
        iwa=iwa+ina
       if(j.lt.i) go to 201
       jsb=0
       if(i.lt.mjy) go to 200
      ig4=ig4+4
      intout(ig4)=0
      intout(ig4+1)=0
      intout(ig4+2)=0
      intout(ig4+3)=0
      call pack(pli,8,intout,2000)
       write(mtape) p
      return
 50     isb=i-1
       jsb=j-1
      call rewftn(ntape)
       do 58 i=1,il
      nfg(i)=0
 58    nrc(i)=maxb
 2      continue
      return
      end
_EXTRACT(tr2iji,hp800)
      subroutine tr2iji(ma,mb,t,is)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/blksiz)
      common/stak/btri,mlow(2),irec
      common/scra /ixa(3400)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/bufb/nwbnwb,lnklnk,gout(5119)
      common/craypk/intin(2000),intout(2000)
      common/junk /cf(22500),icf(22500)
      common/b/ sum,gg,itape,jtape,ktape,mtape,ltape,mscr,nrac,nrecy,
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ntape
      dimension f(751)
      dimension q(500),fm(251),pq(500),pli(251)
     + ,gin(5119),is(*),t(*)
      equivalence (g(1),q(1)),(g(501),fm(1)),(fm(251),n2),
     +(gin(1),gout(1)),
     +(p(1),pq(1)),(p(501),pli(1)),(g(1),f(1))
      data maxb/9999999/
      mjx=nj(ma)
      mjy=nj(mb)
      ljx=kj(ma)
      ljy=kj(mb)
      mmx=ibal(mb)
      mmm=itil(mb)
      jdx=ibal(ma)
      idx=itil(ma)
      ifm=-ljy
      do 900 i=1,ljx
      ifm=ifm+ljy
  900 jdeks(i) = ifm
      ina=mjx*mjy
      im=ik/ina
      inb=ljx*ljy
      if (im.gt.inb) im=inb
      ifm=-mjy
      do 901 i=1,mjx
      ifm=ifm+mjy
 901  kdeks(i)=ifm
      il=(inb-1)/im+1
      iq=(il-1)/if2+1
      il=(il-1)/iq + 1
      ib=ik/il
      icak=ina*im
c
      nav = lenwrd()
c
      itx=ib/nav
      if(itx*nav.ne.ib) ib=ib-1
      if(ib.gt.nsz340) ib=nsz340
      itx=(nav+1)*ib
      ity=itx/nav
      ix = -ib
      iy = - ity
      imax=im*il
      ifm=-imax
      do 1 i=1,il
      ix=ix+itx
      iy=iy+ity
      mlr(i) = iy
      mli(i) = ix
      nrc(i) = maxb
    1 nfg(i) = 0
      ig = 0
      ig4 = -3
      isb = 0
      jsb = 0
      if(iq.eq.1) go to 700
      call rewftn(mscr)
  701 read(ltape) f
      write(mscr) f
      if(n2.ne.0) go to 701
      ntape = mscr
      call rewftn(ntape)
      go to 702
  700 ntape = ltape
  702 do 2 i8 = 1,iq
      ifm = ifm + imax
      irec = 0
      ilc = 0
_IFN(cray)
      call setsto(2000,0,intin)
_ENDIF
   11 read (ntape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 3 jj=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 705
      i=ijkl
      j=intin(int4+1)
      kdx=jdeks(i) + j - ifm
      if(kdx.lt.1.or.kdx.gt.imax) go to 3
      k = intin(int4+2)
      iln = (kdx-1)/im + 1
      kz = kdx - (iln-1)*im
      mq=mlr(iln) + 1
      mm = mli(iln)  + 1
      t(mq) = q(jj)
      l=intin(int4+3)
      if(oprint(31)) then
       write(6,5566) jj,i,j,k,l,q(jj)
5566   format(1x,'tr2iji: i,j,k,l,val = ',i4,2x,4i4,5x,f20.10)
      endif
      is(mm) = (kz-1)*ina + kdeks(k) + l
      if = nfg(iln) + 1
      if(if.eq.ib) go to 10
      nfg(iln) = if
      mlr(iln) = mq
      mli(iln) = mm
      go to 3
 10   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout,1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
    3 int4=int4+4
      go to 11
 705  do 13 jj=1,il
      nz=nfg(jj)
      if(nz.eq.0)go to 13
      call stopbk
      nwbnwb=nz
      lnklnk=nrc(jj)
      mq=mlr(jj)-nz
      mm=mli(jj)-nz
      call dcopy(nz,t(mq+1),1,gout,1)
      call pack(gout(nsz341),32,is(mm+1),nsz340)
      call sttout
      mlr(jj)=mq
      mli(jj)=mm
      nrc(jj)=irec
      irec=irec+nsz
 13   continue
c
      call stopbk
c
      imc=im
       i=isb
 200    i=i+1
       j=jsb
 201      j=j+1
      if(imc.lt.im) goto 40
      if(ilc.eq.il) go to 50
      ilc = ilc + 1
      imc=0
      iwa=0
      call vclr(t,1,icak)
      lnklnk=nrc(ilc)
      go to 32
 33   iblok=lnklnk
      call rdbak(iblok)
      call stopbk
      call unpack(gin(nsz341),32,ixa,nsz340)
_IF(vax)
      do 332 moop=1,nwbnwb
      ixq=ixa(moop)
 332  t(ixq)=gin(moop)
_ELSEIF(cray)
      call scatter(nwbnwb,t,ixa,gin)
_ELSE
      call dsctr(nwbnwb,gin,ixa,t)
_ENDIF
 32   if(lnklnk.ne.maxb)go to 33
   40 imc=imc+1
      lx=jdx
      kk = idx
      do 41 k=1,i
      kk=kk+1
      mcp=mcomp(kk)
c     do 39 ll=1,mjy
c  39 v(ll) = 0.0
      call vclr(v,1,mjy)
      mlim=ljy
      if(k.eq.i)mlim=j
      do 43 ll=1,mcp
      lx = lx + 1
      ld = icf(lx)
      iw = iwa + kdeks(ld)
      do 70 l=1,mjy
      iw = iw + 1
  70  v(l) = v(l) + t(iw)*cf(lx)
   43 continue
      mx = mmx
      mm = mmm
      do 55 l=1,mlim
      mm = mm + 1
      ncp = mcomp(mm)
_IF(vax)
      sum=0.0
      do 53 ll=1,ncp
      mx=mx+1
      ld=icf(mx)
  53  sum=sum+cf(mx)*v(ld)
_ELSEIF(cray)
      sum=spdot(ncp,v,icf(mx+1),cf(mx+1))
      mx=mx+ncp
_ELSE
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),v)
      mx=mx+ncp
_ENDIF
      ig = ig + 1
      pq(ig) = sum
      ig4=ig4+4
      intout(ig4)=i
      intout(ig4+1)=j
      intout(ig4+2)=k
      intout(ig4+3)=l
      if(ig.lt.ifrk) go to 55
      call pack(pli,8,intout,2000)
      write (mtape) p
      ig = 0
      ig4 = -3
   55 continue
   41 continue
      iwa = iwa + ina
       if(j.lt.ljy) go to 201
      jsb=0
       if(i.lt.ljx) go to 200
      ig4=ig4+4
      intout(ig4)=0
      intout(ig4+1)=0
      intout(ig4+2)=0
      intout(ig4+3)=0
      call pack(pli,8,intout,2000)
      write (mtape) p
      return
   50 isb = i-1
      jsb = j-1
      call rewftn(ntape)
      do 58 i=1,il
      nfg(i) = 0
   58 nrc(i) = maxb
    2 continue
      return
      end
_ENDEXTRACT
_EXTRACT(tr1iji,hp800)
      subroutine tr1iji(ma,mb,t,is)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/blksiz)
      common/stak/btri,mlow(2),irec
      common/scra /ixa(3400)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/junk /cf(22500),icf(22500)
      common/bufb/nwbnwb,lnklnk,gout(5119)
      common/craypk/intin(2000),intout(2000)
      common/b/ sum,gg,itape,jtape,mtape,ktape,ltape,mscr,nrac,nrecy,
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ntape
      dimension f(751)
      dimension q(500),fm(251),pq(500),pli(251)
     + ,gin(5119),is(*),t(*)
      equivalence (g(1),q(1)),(g(501),fm(1)),(fm(251),n2),
     +(pli(251),m2),(gin(1),gout(1)),
     +(p(1),pq(1)),(p(501),pli(1)),(g(1),f(1))
      data maxb/9999999/
      llx=ibal(ma)
      lly=ibal(mb)
      mjx=nj(ma)
      mjy=nj(mb)
      ljx=kj(ma)
      ljy=kj(mb)
      ifm=-mjy
      do 900 i=1,mjx
      ifm=ifm+mjy
  900 jdeks(i)=ifm
      kx=itil(ma)
      ky=itil(mb)
      ina=mjx*mjy
      im=ik/ina
      if (im.gt.ina) im=ina
      if (im.eq.0) call caserr(
     *'insufficient main memory for the program to continue')
c
      nav = lenwrd()
c
      il=(ina-1)/im+1
      iq=(il-1)/if2+1
      il=(il-1)/iq+1
      ib=ik/il
      icak=ina*im
      itx=ib/nav
      if(itx*nav.ne.ib) ib=ib-1
      if (ib.gt.nsz340) ib=nsz340
      itx=(nav+1)*ib
      ity=itx/nav
      ix=-ib
      iy=-ity
      imax=im*il
      ifm=-imax
      do 1 i=1,il
      ix=ix+itx
      iy=iy+ity
      mlr(i)=iy
      mli(i)=ix
      nrc(i)=maxb
    1 nfg(i)=0
      ig=0
      ig4=-3
      isb=0
      jsb=0
      if (iq.eq.1) go to 700
      call rewftn(mscr)
  701 read (mtape) f
      write (mscr) f
      if (n2.ne.0) go to 701
      ntape=mscr
      call rewftn(ntape)
      go to 702
  700 ntape=mtape
  702 do 2 i8=1,iq
      ifm=ifm+imax
      irec=0
      ilc=0
_IFN(cray)
      call setsto(2000,0,intin)
_ENDIF
   11 read (ntape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 3 jj=1,ifrk
_IF(littleendian)
      ijkl=intin(int4+1)
_ELSE
      ijkl=intin(int4)
_ENDIF
      if (ijkl.eq.0) go to 705
      i=ijkl
      gg=q(jj)
_IF(littleendian)
      j=intin(int4  )
      l=intin(int4+2)
      k=intin(int4+3)
_ELSE
      j=intin(int4+1)
      k=intin(int4+2)
      l=intin(int4+3)
_ENDIF
      if(oprint(31)) then
       write(6,5566) jj,i,j,k,l,q(jj)
5566   format(1x,'tr1iji: i,j,k,l,val = ',i4,2x,4i4,5x,f20.10)
      endif
      idx=jdeks(i)+j
      kdx=jdeks(k)+l
      kt=kdx-ifm
      if (kt.lt.1.or.kt.gt.imax) go to 9
      iln=(kt-1)/im+1
      kz=kt-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=gg
      is(mm)=(kz-1)*ina+idx
      if=nfg(iln)+1
      if (if.eq.ib) go to 10
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
      go to 9
 10   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout,1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
    9 if (idx.eq.kdx) go to 3
      kt=idx-ifm
      if (kt.lt.1.or.kt.gt.imax) go to 3
      iln=(kt-1)/im+1
      kz=kt-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=gg
      is(mm)=(kz-1)*ina+kdx
      if=nfg(iln)+1
      if (if.eq.ib) go to 12
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
      go to 3
 12   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout,1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
    3 int4=int4+4
      go to 11
 705  do 13 jj=1,il
      nz=nfg(jj)
      if(nz.eq.0)go to 13
      call stopbk
      nwbnwb=nz
      lnklnk=nrc(jj)
      mq=mlr(jj)-nz
      mm=mli(jj)-nz
      call dcopy(nz,t(mq+1),1,gout,1)
      call pack(gout(nsz341),32,is(mm+1),nsz340)
      call sttout
      mlr(jj)=mq
      mli(jj)=mm
      nrc(jj)=irec
      irec=irec+nsz
 13   continue
c
      call stopbk
c
      imc=im
       k=isb
 200     k=k+1
       l=jsb
 201      l=l+1
      if(imc.lt.im) goto 40
      if (ilc.eq.il) go to 50
      ilc=ilc+1
      imc=0
      iwa=0
      call vclr(t,1,icak)
      lnklnk=nrc(ilc)
      go to 32
 33   iblok=lnklnk
      call rdbak(iblok)
      call stopbk
      call unpack(gin(nsz341),32,ixa,nsz340)
_IF(vax)
      do 332 moop=1,nwbnwb
      ixq=ixa(moop)
 332  t(ixq)=gin(moop)
_ELSEIF(cray)
      call scatter(nwbnwb,t,ixa,gin)
_ELSE
      call dsctr(nwbnwb,gin,ixa,t)
_ENDIF
 32   if(lnklnk.ne.maxb)go to 33
   40 lx=llx
      kk=kx
      imc=imc+1
      do 41 ii=1,ljx
      kk=kk+1
      mcp=mcomp(kk)
c     do 39 i=1,mjy
c  39 v(i)=0.0
      call vclr(v,1,mjy)
      do 43 i=1,mcp
      lx=lx+1
      ld=icf(lx)
      sac=cf(lx)
      iw=iwa+jdeks(ld)
      do 70 j=1,mjy
      iw=iw+1
   70 v(j)=v(j)+sac*t(iw)
   43 continue
      mx=lly
      mm=ky
      do 55 jj=1,ljy
      mm=mm+1
      ncp=mcomp(mm)
_IF(vax)
      sum=0.0
      do 53 ll=1,ncp
      mx=mx+1
      ld=icf(mx)
  53  sum=sum+cf(mx)*v(ld)
_ELSEIF(cray)
      sum=spdot(ncp,v,icf(mx+1),cf(mx+1))
      mx=mx+ncp
_ELSE
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),v)
      mx=mx+ncp
_ENDIF
      if (dabs(sum).lt.1.0d-10) go to 55
      ig=ig+1
      pq(ig)=sum
      ig4=ig4+4
      intout(ig4  )=ii
      intout(ig4+1)=jj
      intout(ig4+2)=k
      intout(ig4+3)=l
      if (ig.lt.ifrk) go to 55
      call pack(pli,8,intout,2000)
      m2=ig
      ig4=-3
      write (ltape) p
      ig=0
   55 continue
   41 continue
      iwa=iwa+ina
        if(l.lt.mjy) go to 201
      jsb=0
      if(k.lt.mjx) go to 200
      ig4=ig4+4
      intout(ig4)=0
      intout(ig4+1)=0
      intout(ig4+2)=0
      intout(ig4+3)=0
      call pack(pli,8,intout,2000)
      m2=0
      write (ltape) p
      return
   50 isb=k-1
      jsb=l-1
      call rewftn(ntape)
      do 58 i=1,il
      nfg(i)=0
   58 nrc(i)=maxb
    2 continue
       return
      end
_ENDEXTRACT
_EXTRACT(tr1ijk,hp800)
       subroutine tr1ijk(le,lb,lc,lf,t,is)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/blksiz)
      common/stak/btri,mlow(2),irec
      common/scra /ixa(3400)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/junk /cf(22500),icf(22500)
      common/bufb/nwbnwb,lnklnk,gout(5119)
      common/craypk/intin(2000),intout(2000)
      common/b/ sum,gg,itape,jtape,mtape,ktape,ltape,mscr,nrac,nrecy,
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ntape
      dimension f(751)
      dimension q(500),fm(251),pq(500),pli(251)
     + ,gin(5119),is(*),t(*)
      equivalence (g(1),q(1)),(g(501),fm(1)),(fm(251),n2),
     + (pli(251),m2),(gin(1),gout(1)),
     + (p(1),pq(1)),(p(501),pli(1)),(g(1),f(1))
      data maxb/9999999/
      llx = ibal(le)
      lly=ibal(lb)
      mjx=nj(le)
      mjy=nj(lb)
      mja=nj(lc)
      mjb=nj(lf)
      kx=itil(le)
      ky=itil(lb)
      ljx=kj(le)
      ljy=kj(lb)
      ina=mjx*mjy
      inb=mja*mjb
      ifm=-mjy
      do 901 i=1,mjx
      ifm=ifm+mjy
901   kdeks(i)=ifm
      ifm=-mjb
      do 900 i=1,mja
      ifm=ifm+mjb
900   jdeks(i)=ifm
      im=ik/ina
      if (im.gt.inb) im=inb
      if (im.eq.0) call caserr(
     *'insufficient main memory for the program to continue')
c
      nav = lenwrd()
c
      il=(inb-1)/im + 1
      iq=(il-1)/if2+1
      il=(il-1)/iq+1
      ib=ik/il
      icak=ina*im
      itx=ib/nav
      if(itx*nav.ne.ib) ib=ib-1
      if (ib .gt. nsz340) ib=nsz340
      itx=(nav+1)*ib
      ity=itx/nav
      ix=-ib
      iy=-ity
      imax=im*il
      ifm=-imax
      do 1 i=1,il
      ix=ix+itx
      iy=iy+ity
      mlr(i)=iy
      mli(i)=ix
      nrc(i)=maxb
1     nfg(i)=0
      ig=0
      ig4=-3
      isb=0
      jsb=0
      if (iq .eq. 1 ) go to 700
      call rewftn(mscr)
701    read (mtape) f
      write (mscr) f
      if (n2 .ne. 0) goto 701
      ntape=mscr
      call rewftn(ntape)
      goto 702
700   ntape=mtape
702    do 2 i8=1 ,iq
      ifm=ifm+imax
      irec=0
      ilc=0
_IFN(cray)
      call setsto(2000,0,intin)
_ENDIF
11    read (ntape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 3 jj=1,ifrk

_IF(littleendian)
      ijkl=intin(int4+1)
_ELSE
      ijkl=intin(int4)
_ENDIF
      if (ijkl.eq. 0) goto 705
_IF(littleendian)
      l=intin(int4+2)
      k=intin(int4+3)
_ELSE
      k=intin(int4+2)
      l=intin(int4+3)
_ENDIF
      kdx=jdeks(k) + l - ifm
      if (kdx .lt.1  .or. kdx .gt. imax) goto 3
      i=ijkl
      iln=(kdx-1)/im +1
      kz=kdx-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=q(jj)
_IF(littleendian)
      j=intin(int4  )
_ELSE
      j=intin(int4+1)
_ENDIF
      if(oprint(31)) then
       write(6,5566) jj,i,j,k,l,q(jj)
5566   format(1x,'tr2iii: i,j,k,l,val = ',i4,2x,4i4,5x,f20.10)
      endif
      is(mm)=(kz-1)*ina+kdeks(i)+j
      if=nfg(iln)+1
      if (if .eq. ib) goto 10
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
      goto 3
 10   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout,1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
3      int4=int4+4
      goto 11
 705  do 13 jj=1,il
      nz=nfg(jj)
      if(nz.eq.0)go to 13
      call stopbk
      nwbnwb=nz
      lnklnk=nrc(jj)
      mq=mlr(jj)-nz
      mm=mli(jj)-nz
      call dcopy(nz,t(mq+1),1,gout,1)
      call pack(gout(nsz341),32,is(mm+1),nsz340)
      call sttout
      mlr(jj)=mq
      mli(jj)=mm
      nrc(jj)=irec
      irec=irec+nsz
 13   continue
c
       call stopbk
c
      imc=im
       k=isb
 200      k=k+1
       l=jsb
 201     l=l+1
      if(imc.lt.im) goto 40
      if (ilc .eq. il) goto 50
      ilc=ilc+1
      imc=0
      iwa=0
      call vclr(t,1,icak)
      lnklnk=nrc(ilc)
      go to 32
 33   iblok=lnklnk
      call rdbak(iblok)
      call stopbk
      call unpack(gin(nsz341),32,ixa,nsz340)
_IF(vax)
      do 332 moop=1,nwbnwb
      ixq=ixa(moop)
 332  t(ixq)=gin(moop)
_ELSEIF(cray)
      call scatter(nwbnwb,t,ixa,gin)
_ELSE
      call dsctr(nwbnwb,gin,ixa,t)
_ENDIF
 32   if(lnklnk.ne.maxb)go to 33
40     lx=llx
      kk=kx
      imc=imc+1
      do 41 ii=1,ljx
      kk=kk+1
      mcp=mcomp(kk)
c     do 39 i=1,mjy
c39    v(i)=0.0
      call vclr(v,1,mjy)
      do 43 i=1,mcp
      lx=lx+1
      lt=icf(lx)
      sac=cf(lx)
      iw=iwa+kdeks(lt)
      do 70 j=1,mjy
      iw=iw+1
70    v(j)=v(j)+sac*t(iw)
43    continue
      mx=lly
      mm=ky
      do 55 j=1,ljy
      mm=mm+1
      ncp=mcomp(mm)
_IF(vax)
      sum=0.0
      do 53 ll=1,ncp
      mx=mx+1
      lt=icf(mx)
  53  sum=sum+cf(mx)*v(lt)
_ELSEIF(cray)
      sum=spdot(ncp,v,icf(mx+1),cf(mx+1))
      mx=mx+ncp
_ELSE
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),v)
      mx=mx+ncp
_ENDIF
      if (dabs(sum) .lt. 1.0d-10) goto 55
      ig=ig+1
      pq(ig)=sum
      ig4=ig4+4
      intout(ig4  )=ii
      intout(ig4+1)= j
      intout(ig4+2)= k
      intout(ig4+3)= l
      if (ig .lt. ifrk) goto 55
      call pack(pli,8,intout,2000)
      m2=ig
      write (ltape) p
      ig=0
      ig4=-3
55    continue
41    continue
      iwa=iwa+ina
       if(l.lt.mjb) go to 201
      jsb=0
       if(k.lt.mja) go to 200
      ig4=ig4+4
      intout(ig4)=0
      intout(ig4+1)=0
      intout(ig4+2)=0
      intout(ig4+3)=0
      call pack(pli,8,intout,2000)
      m2=0
      write(ltape) p
      return
50    isb=k-1
      jsb=l-1
      call rewftn(ntape)
      do 58 i=1,il
      nfg(i)=0
58    nrc(i)=maxb
2     continue
      return
      end
_ENDEXTRACT
_IFN1(v)      subroutine tmrd0(t,is,res,iorbs)
_IF1(v)      subroutine tmrd0(t,is)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/blksiz)
      common/stak/btri,mlow(2),irec
      common/scra /ixa(3400)
INCLUDE(common/mapper)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/craypk/intin(2400),intout(2000)
      common/bufb/nwbnwb,lnklnk,gout(5119)
      common/junk /cf(22500),icf(22500)
      common/b/ sum,gg,itape,jtape,ntape,mtape,ltape,mscr,nrac,nrecy,
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
_IFN1(v)     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icl,iorbss,llx,mjy,inb,i8,lly,ky,
_IF1(v)     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ktape
_IFN1(v)      dimension res(iorbs,*)
      dimension gin(5119),pq(500),pli(251),is(*),t(*)
      dimension q(500),fm(251),f(751)
      equivalence (fm(251),n2),(g(1),q(1),f(1)),(g(501),fm(1))
      equivalence (p(1),pq(1)),(p(501),pli(1)),
     + (pli(251),m2),(gin(1),gout(1))
      data maxb/9999999/
      ina=iky(iorbs+1)
      im=ik/ina
      if(im.gt.ina)im=ina
      if (im.eq.0) call caserr(
     *'insufficient main memory for the program to continue')
c
      nav = lenwrd()
c
      il=(ina-1)/im+1
      iq=(il-1)/if2+1
      il=(il-1)/iq+1
      ib=ik/il
      icak=ina*im
      mjx=kj(1)
      itx=ib/nav
      if(itx*nav.ne.ib) ib=ib-1
      if (ib.gt.nsz340) ib=nsz340
      itx=(nav+1)*ib
      ity=itx/nav
      ix=-ib
      iy=-ity
      imax=im*il
      ifm=-imax
      do 1 i=1,il
      ix=ix+itx
      iy=iy+ity
      mlr(i)=iy
      mli(i)=ix
      nrc(i)=maxb
1     nfg(i)=0
      ig=0
      ig4=-3
      isb=0
      jsb=0
      do 2 i8=1,iq
      ifm=ifm+imax
      ilc=0
      irec=0
_IFN(cray)
      call setsto(2000,0,intin)
_ENDIF
 120  read(ntape)f
      call unpack(fm,8,intin,2000)
      int4=1
      if(oprint(31)) then
        write(6,*)'tmrd0: ntape, ifrk =', ntape, ifrk
      endif
      do 5 int=1,ifrk

_IF(littleendian)
      i=intin(int4+1)
_ELSE
      i=intin(int4)
_ENDIF
      if(oprint(31)) write(6,*)'tmrd0: i = ', i
      if(i.eq.0)go to 3
      gg=g(int)
_IF(littleendian)
      j=intin(int4  )
      l=intin(int4+2)
      k=intin(int4+3)
_ELSE
      j=intin(int4+1)
      k=intin(int4+2)
      l=intin(int4+3)
_ENDIF
      if(oprint(31)) then
       write(6,5566) int,i,j,k,l,gg
5566   format(1x,'tmrd0: i,j,k,l,val = ',i4,2x,4i4,5x,f20.10)
      endif
      idx=min(i,j)+iky(max(i,j))
      kdx=min(k,l)+iky(max(k,l))
      kt=kdx-ifm
      if (kt.lt.1.or.kt.gt.imax) go to 9
      iln=(kt-1)/im+1
      kz=kt-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=gg
      is(mm)=(kz-1)*ina+idx
      if=nfg(iln)+1
      if(if.eq.ib) go to 10
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
      go to 9
 10   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout(1),1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
9     if (idx.eq.kdx) go to 5
      kt=idx-ifm
      if (kt.lt.1.or.kt  .gt.imax) go to 5
      iln=(kt-1)/im+1
      kz=kt-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=gg
      is(mm)=(kz-1)*ina+kdx
      if=nfg(iln)+1
      if (if.eq.ib) go to 12
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
      go to 5
 12   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout(1),1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
 5    int4=int4+4
      go to 120
 3    do 13 jj=1,il
      nz=nfg(jj)
      if(nz.eq.0)go to 13
      call stopbk
      nwbnwb=nz
      lnklnk=nrc(jj)
      mq=mlr(jj)-nz
      mm=mli(jj)-nz
      call dcopy(nz,t(mq+1),1,gout(1),1)
      call pack(gout(nsz341),32,is(mm+1),nsz340)
      call sttout
      mlr(jj)=mq
      mli(jj)=mm
      nrc(jj)=irec
      irec=irec+nsz
 13   continue
c
      call stopbk
c
      imc=im
      k=isb
 200  k=k+1
      l=jsb
 201  l=l+1
      if(imc.lt.im) goto 40
      if (ilc.eq.il) go to 50
      ilc=ilc+1
      imc=0
      iwa=0
      call vclr(t,1,icak)
      lnklnk=nrc(ilc)
      go to 32
 33   iblok=lnklnk
      call rdbak(iblok)
      call stopbk
      call unpack(gin(nsz341),32,ixa,nsz340)
_IF(vax)
      do 332 moop=1,nwbnwb
      ixq=ixa(moop)
 332  t(ixq)=gin(moop)
_ELSEIF(cray)
      call scatter(nwbnwb,t,ixa,gin)
_ELSE
      call dsctr(nwbnwb,gin,ixa,t)
_ENDIF
 32   if(lnklnk.ne.maxb)go to 33
40    lx=0
      imc=imc+1
_IFN1(v)      call square(res,t(iwa+1),iorbs,iorbs)
      do 41 ii=1,mjx
      mcp=mcomp(ii)
      call vclr(v,1,iorbs)
_IF(vax)
      do 43 i=1,mcp
      lx=lx+1
      ld=icf(lx)
      sac=cf(lx)
      if (ld.eq.1) go to 850
      lda=ld-1
      iw=iwa+iky(ld)
      do 70 j=1,lda
      iw=iw+1
   70 v(j)=v(j)+sac*t(iw)
  850 iw=iwa+ld
      do 851 j=ld,iorbs
      iz=iw+iky(j)
 851  v(j)=v(j)+t(iz)*sac
   43 continue
_ELSE
      do 43 i=1,mcp
      lx=lx+1
      sac=cf(lx)
      ld=icf(lx)
_IF(cray)
      do 433 loop=1,iorbs
433   v(loop)=v(loop)+sac*res(loop,ld)
_ELSE
      call daxpy(iorbs,sac,res(1,ld),1,v,1)
_ENDIF
   43 continue
_ENDIF
      mx=0
      do 55 jj=1,ii
      ncp=mcomp(jj)
_IF(vax)
      sum=0.0
      do 53 ll=1,ncp
      mx=mx+1
      ld=icf(mx)
  53  sum=sum+cf(mx)*v(ld)
_ELSEIF(cray)
      sum=spdot(ncp,v,icf(mx+1),cf(mx+1))
      mx=mx+ncp
_ELSE
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),v)
      mx=mx+ncp
_ENDIF
      if(dabs(sum).lt.1.0d-10) go to 55
      ig=ig+1
      pq(ig)=sum
      ig4=ig4+4
      intout(ig4  )=ii
      intout(ig4+1)=jj
      intout(ig4+2)=k
      intout(ig4+3)=l
      if (ig.lt.ifrk) go to 55
      call pack(pli,8,intout,2000)
      m2=ig
      write(ltape) p
      ig=0
      ig4=-3
55    continue
41    continue
      iwa=iwa+ina
       if(l.lt.k) go to 201
      jsb=0
        if(k.lt.iorbs) go to 200
      ig4=ig4+4
      intout(ig4)=0
      intout(ig4+1)=0
      intout(ig4+2)=0
      intout(ig4+3)=0
      call pack(pli,8,intout,2000)
      m2=0
      write(ltape ) p
      return
50    isb=k-1
      jsb=l-1
      call rewftn(ntape)
      do 57 i=1,nrecy
57    read(ntape)
      do 58 i=1,il
      nfg(i)=0
58    nrc(i)=maxb
2     continue
      return
      end
_IFN1(v)      subroutine tr1iii(ma,t,is,res,mjx)
_IF1(v)      subroutine tr1iii(ma,t,is)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/mapper)
INCLUDE(common/prints)
INCLUDE(common/blksiz)
      common/stak/btri,mlow(2),irec
      common/scra /ixa(3400)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/junk /cf(22500),icf(22500)
      common/bufb/nwbnwb,lnklnk,gout(5119)
      common/craypk/intin(2000),intout(2000)
      common/b/ sum,gg,itape,jtape,mtape,ktape,ltape,mscr,nrac,nrecy,
_IFN1(v)     1nblk,ifrk,ifrk1,ik,if2,im,mjxx,kxl,njx,nzl,ina,il,iq,ib,icak,
_IF1(v)     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ntape
      dimension f(751)
_IFN1(v)       dimension res(mjx,*)
      dimension q(500),fm(251),pq(500),pli(251)
     + ,gin(5119),is(*),t(*)
      equivalence (g(1),q(1)),(g(501),fm(1)),(fm(251),n2),
     + (pli(251),m2),(gin(1),gout(1)),
     +(p(1),pq(1)),(p(501),pli(1)),(g(1),f(1))
      data maxb/9999999/
      llx=ibal(ma)
_IF1(v)      mjx=nj(ma)
      kx=itil(ma)
      ljx=kj(ma)
      ina=iky(mjx+1)
      im=ik/ina
      if(im.gt.ina)im=ina
      if (im.eq.0) call caserr(
     *'insufficient main memory for the program to continue')
c
      nav = lenwrd()
c
      il=(ina-1)/im+1
      iq=(il-1)/if2+1
      il=(il-1)/iq+1
      ib=ik/il
      icak=ina*im
      itx=ib/nav
      if(itx*nav.ne.ib) ib=ib-1
      if(ib.gt.nsz340) ib=nsz340
      itx=(nav+1)*ib
      ity=itx/nav
      ix=-ib
      iy=-ity
      imax=im*il
      ifm=-imax
      do 1 i=1,il
      ix=ix+itx
      iy=iy+ity
      mlr(i)=iy
      mli(i)=ix
      nrc(i)=maxb
1     nfg(i)=0
      ig=0
      ig4=-3
      isb=0
      jsb=0
      if(oprint(31)) write(6,*)'tr1iii,iq,ma = ',iq, ma
      if(iq.eq.1.or.ma.eq.1) go to 700
      call rewftn(mscr)
701   read(mtape) f
      write(mscr) f
      if(oprint(31)) write(6,*)'tr1iii: n2,ifrk = ', n2,ifrk
      if (n2.ne.0) go to 701
      ntape=mscr
      call rewftn(ntape)
      go to 702
700   ntape=mtape
      if(oprint(31)) write(6,*)'tr1iii: n2,ifrk = ', n2,ifrk
702   do 2i8=1,iq
      ifm=ifm+imax
      irec=0
      ilc=0
_IFN(cray)
      call setsto(2000,0,intin)
_ENDIF
11    read(ntape) f
      call unpack(fm,8,intin,2000)
      int4=1
c
      if(oprint(31)) then
       write(6,*) 'q = '
       write(6,99223)(q(jj),jj=1,ifrk)
99223  format(1x,6f12.7)
       write(6,*) ' labels ='
       write(6,99224)(fm(jj),jj=1,250)
99224  format(2x,4(1x,z16))
      endif
c
      do 3 jj=1,ifrk
_IF(littleendian)
      ijkl=intin(int4+1)
_ELSE
      ijkl=intin(int4)
_ENDIF
      if(oprint(31)) write(6,*) 'tr1iii, jj, ijkl = ', jj, ijkl
      if (ijkl.eq.0) go to 705
      i=ijkl
      gg=q(jj)
_IF(littleendian)
      j=intin(int4  )
      l=intin(int4+2)
      k=intin(int4+3)
_ELSE
      j=intin(int4+1)
      k=intin(int4+2)
      l=intin(int4+3)
_ENDIF
      if(oprint(31)) then
       write(6,5566) jj,i,j,k,l,q(jj)
5566   format(1x,'tr1iii: i,j,k,l,val = ',i4,2x,4i4,5x,f20.10)
      endif
      idx=iky(i)+j
      kdx=iky(k)+l
      kt=kdx-ifm
      if (kt.lt.1.or.kt.gt.imax) go to 9
      iln=(kt-1)/im+1
      kz=kt-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=gg
      is(mm)=(kz-1)*ina+idx
      if=nfg(iln)+1
      if(if.eq.ib) go to 10
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
      go to 9
 10   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout,1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
9     if(idx.eq.kdx) go to 3
      kt=idx-ifm
      if (kt.lt.1.or.kt.gt.imax) go to 3
      iln=(kt-1)/im+1
      kz=kt-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=gg
      is(mm)=(kz-1)*ina+kdx
      if =nfg(iln)+1
      if(if.eq.ib) go to 12
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
      go to 3
 12   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout,1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
3     int4=int4+4
      go to 11
 705  do 13 jj=1,il
      nz=nfg(jj)
      if(nz.eq.0)go to 13
      call stopbk
      nwbnwb=nz
      lnklnk=nrc(jj)
      mq=mlr(jj)-nz
      mm=mli(jj)-nz
      call dcopy(nz,t(mq+1),1,gout,1)
      call pack(gout(nsz341),32,is(mm+1),nsz340)
      call sttout
      mlr(jj)=mq
      mli(jj)=mm
      nrc(jj)=irec
      irec=irec+nsz
 13   continue
c
      call stopbk
c
      imc=im
       k=isb
 200      k=k+1
      l=jsb
 201      l=l+1
       if(imc.lt.im) goto 40
      if(ilc.eq.il) go to 50
      ilc=ilc+1
      imc=0
      iwa=0
      call vclr(t,1,icak)
      lnklnk=nrc(ilc)
      go to 32
 33   iblok=lnklnk
      call rdbak(iblok)
      call stopbk
      call unpack(gin(nsz341),32,ixa,nsz340)
_IF(vax)
      do 332 moop=1,nwbnwb
      ixq=ixa(moop)
 332  t(ixq)=gin(moop)
_ELSEIF(cray)
      call scatter(nwbnwb,t,ixa,gin)
_ELSE
      call dsctr(nwbnwb,gin,ixa,t)
_ENDIF
 32   if(lnklnk.ne.maxb)go to 33
_IF(vax)
40    continue
_ELSE
40    call square(res,t(iwa+1),mjx,mjx)
_ENDIF
      lx=llx
      kk=kx
      imc=imc+1
      do 41 ii=1,ljx
      kk=kk+1
      mcp=mcomp(kk)
      call vclr(v,1,mjx)
_IF(vax)
      do 43 i=1,mcp
      lx=lx+1
      ld=icf(lx)
      sac=cf(lx)
      if (ld.eq.1) go to 850
      lda=ld-1
      iw=iwa+iky(ld)
      do 70 j=1,lda
      iw=iw+1
70    v(j)=v(j)+sac*t(iw)
850   iw=iwa+ld
      do 851 j=ld,mjx
      iz=iw+iky(j)
851   v(j)=v(j)+sac*t(iz)
43    continue
_ELSE
      do 43 i=1,mcp
      lx=lx+1
      sac=cf(lx)
      ld=icf(lx)
_IF(cray)
      do 433 loop=1,mjx
433   v(loop)=v(loop)+sac*res(loop,ld)
_ELSE
      call daxpy(mjx,sac,res(1,ld),1,v,1)
_ENDIF
43    continue
_ENDIF
      mx=llx
      mm=kx
      do 55 jj=1,ii
      mm=mm+1
      ncp=mcomp(mm)
_IF(vax)
      sum=0.0
      do 53 ll=1,ncp
      mx=mx+1
      ld=icf(mx)
  53  sum=sum+cf(mx)*v(ld)
_ELSEIF(cray)
      sum=spdot(ncp,v,icf(mx+1),cf(mx+1))
      mx=mx+ncp
_ELSE
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),v)
      mx=mx+ncp
_ENDIF
      if(dabs(sum).lt.1.0d-10) go to 55
      ig=ig+1
      pq(ig)=sum
      ig4=ig4+4
      intout(ig4  )=ii
      intout(ig4+1)=jj
      intout(ig4+2)=k
      intout(ig4+3)=l
      if(ig.lt.ifrk) go to 55
      call pack(pli,8,intout,2000)
      m2=ig
      write(ltape)p
      ig=0
      ig4=-3
55    continue
41    continue
      iwa=iwa+ina
       if(l.lt.k) go to 201
        jsb=0
        if(k.lt.mjx) go to 200
      ig4=ig4+4
      intout(ig4)=0
      intout(ig4+1)=0
      intout(ig4+2)=0
      intout(ig4+3)=0
      call pack(pli,8,intout,2000)
      m2=0
      write(ltape) p
      return
50    isb=k-1
      jsb=l-1
      call rewftn(ntape)
      if(ma.gt.1) go to 762
      do 57 i=1,nrecy
57    read(ntape)
762   do 58 i=1,il
      nfg(i)=0
58    nrc(i)=maxb
2     continue
      return
      end
_IFN1(v)      subroutine tr1iij(ma,mb,t,is,res,mjx)
_IF1(v)      subroutine tr1iij(ma,mb,t,is)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/mapper)
INCLUDE(common/prints)
INCLUDE(common/blksiz)
      common/stak/btri,mlow(2),irec
      common/scra /ixa(3400)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/junk /cf(22500),icf(22500)
      common/bufb/nwbnwb,lnklnk,gout(5119)
      common/craypk/intin(2000),intout(2000)
      common/b/ sum,gg,itape,jtape,mtape,ktape,ltape,mscr,nrac,nrecy,
_IFN1(v)     1nblk,ifrk,ifrk1,ik,if2,im,mjxx,kxl,njx,nzl,ina,il,iq,ib,icak,
_IF1(v)     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ntape
_IFN1(v)      dimension f(751),res(mjx,*)
_IF1(v)      dimension f(751)
      dimension q(500),fm(251),pq(500),pli(251)
     + ,gin(5119),is(*),t(*)
      equivalence (g(1),q(1)),(g(501),fm(1)),(fm(251),n2),
     +(pli(251),m2),(gin(1),gout(1)),
     +(p(1),pq(1)),(p(501),pli(1)),(g(1),f(1))
      data maxb/9999999/
      llx=ibal(ma)
_IF1(v)      mjx=nj(ma)
      mjy=nj(mb)
      kx=itil(ma)
      ljx=kj(ma)
      ina=iky(mjx+1)
      inb=iky(mjy+1)
      im=ik/ina
      if(im.gt.inb)im=inb
      if (im.eq.0) call caserr(
     *'insufficient main memory for the program to continue')
c
      nav = lenwrd()
c
      il=(inb-1)/im+1
      iq=(il-1)/if2+1
      il=(il-1)/iq+1
      ib=ik/il
      icak=ina*im
      itx=ib/nav
      if(itx*nav.ne.ib) ib=ib-1
      if(ib.gt.nsz340)ib=nsz340
      itx=(nav+1)*ib
      ity=itx/nav
      ix=-ib
      iy=-ity
      imax=im*il
      ifm=-imax
      do 1 i=1,il
      ix=ix+itx
      iy=iy+ity
      mlr(i)=iy
      mli(i)=ix
      nrc(i)=maxb
1     nfg(i)=0
      ig=0
      ig4=-3
      isb=0
      jsb=0
      if(iq.eq.1) go to 700
      call rewftn(mscr)
701   read(mtape) f
      write(mscr) f
      if(n2.ne.0) go to 701
      ntape=mscr
      call rewftn(ntape)
      go to 702
700   ntape=mtape
702   do 2 i8=1,iq
      ifm=ifm+imax
      irec=0
      ilc=0
_IFN(cray)
      call setsto(2000,0,intin)
_ENDIF
11    read(ntape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 3 jj=1,ifrk
_IF(littleendian)
      ijkl=intin(int4+1)
_ELSE
      ijkl=intin(int4)
_ENDIF
      if(ijkl.eq.0) go to 705
_IF(littleendian)
      l=intin(int4+2)
      k=intin(int4+3)
_ELSE
      k=intin(int4+2)
      l=intin(int4+3)
_ENDIF
      kdx=iky(k)+l-ifm
      if(kdx.lt.1.or.kdx.gt.imax) go to 3
      i=ijkl
      iln=(kdx-1)/im+1
      kz=kdx-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=q(jj)
_IF(littleendian)
      j=intin(int4  )
_ELSE
      j=intin(int4+1)
_ENDIF
      if(oprint(31)) then
       write(6,5566) jj,i,j,k,l,q(jj)
5566   format(1x,'tr1iij: i,j,k,l,val = ',i4,2x,4i4,5x,f20.10)
      endif
      is(mm)=(kz-1)*ina+iky(i)+j
      if=nfg(iln)+1
      if(if.eq.ib) go to 10
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
      go to 3
 10   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout,1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
3     int4=int4+4
      go to 11
 705  do 13 jj=1,il
      nz=nfg(jj)
      if(nz.eq.0)go to 13
      call stopbk
      nwbnwb=nz
      lnklnk=nrc(jj)
      mq=mlr(jj)-nz
      mm=mli(jj)-nz
      call dcopy(nz,t(mq+1),1,gout,1)
      call pack(gout(nsz341),32,is(mm+1),nsz340)
      call sttout
      mlr(jj)=mq
      mli(jj)=mm
      nrc(jj)=irec
      irec=irec+nsz
 13   continue
c
      call stopbk
c
      imc=im
        k=isb
 200     k=k+1
      l=jsb
 201      l=l+1
      if(imc.lt.im) goto 40
      if (ilc.eq.il) go to 50
      ilc=ilc+1
      imc=0
      iwa=0
      call vclr(t,1,icak)
      lnklnk=nrc(ilc)
      go to 32
 33   iblok=lnklnk
      call rdbak(iblok)
      call stopbk
      call unpack(gin(nsz341),32,ixa,nsz340)
_IF(vax)
      do 332 moop=1,nwbnwb
      ixq=ixa(moop)
 332  t(ixq)=gin(moop)
_ELSEIF(cray)
      call scatter(nwbnwb,t,ixa,gin)
_ELSE
      call dsctr(nwbnwb,gin,ixa,t)
_ENDIF
 32   if(lnklnk.ne.maxb)go to 33
40    lx=llx
      imc=imc+1
      kk=kx
_IFN1(v)      call square(res,t(iwa+1),mjx,mjx)
      do 41 ii=1,ljx
      kk=kk+1
      mcp=mcomp(kk)
      call vclr(v,1,mjx)
_IF(vax)
      do 43 i=1,mcp
      lx=lx+1
      ld=icf(lx)
      sac=cf(lx)
      if (ld.eq.1) go to 850
      lda=ld-1
      iw=iwa+iky(ld)
      do 70 j=1,lda
      iw=iw+1
70    v(j)=v(j)+sac*t(iw)
850   iw=iwa+ld
      do 851 j=ld,mjx
      iz=iw+iky(j)
851   v(j)=v(j)+sac*t(iz)
43    continue
_ELSE
      do 43 i=1,mcp
      lx=lx+1
      sac=cf(lx)
      ld=icf(lx)
_IF(cray)
      do 433 loop=1,mjx
433   v(loop)=v(loop)+sac*res(loop,ld)
_ELSE
      call daxpy(mjx,sac,res(1,ld),1,v,1)
_ENDIF
43    continue
_ENDIF
      mx=llx
      mm=kx
      do 55 jj=1,ii
      mm=mm+1
      ncp=mcomp(mm)
_IF(vax)
      sum=0.0
      do 53 ll=1,ncp
      mx=mx+1
      ld=icf(mx)
  53  sum=sum+cf(mx)*v(ld)
_ELSEIF(cray)
      sum=spdot(ncp,v,icf(mx+1),cf(mx+1))
      mx=mx+ncp
_ELSE
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),v)
      mx=mx+ncp
_ENDIF
      if(dabs(sum).lt.1.0d-10) go to 55
      ig=ig+1
      pq(ig)=sum
      ig4=ig4+4
      intout(ig4  )=ii
      intout(ig4+1)=jj
      intout(ig4+2)=k
      intout(ig4+3)=l
      if(ig.lt.ifrk) go to 55
      call pack(pli,8,intout,2000)
      m2=ig
      write(ltape) p
      ig=0
      ig4=-3
55    continue
41    continue
      iwa=iwa+ina
      if(l.lt.k) go to 201
       jsb=0
        if(k.lt.mjy) go to 200
      ig4=ig4+4
      intout(ig4)=0
      intout(ig4+1)=0
      intout(ig4+2)=0
      intout(ig4+3)=0
      call pack(pli,8,intout,2000)
      m2=0
      write(ltape) p
      return
50    isb=k-1
      jsb=l-1
      call rewftn(ntape)
      do 58 i=1,il
      nfg(i)=0
58    nrc(i)=maxb
2     continue
      return
      end
      subroutine tvec(r,q,etot,nj,lj,ntil,mwal,mj,ick,kj,iaus,
     *nsym,iorbs,iposv)
      implicit REAL  (a-h,o-z),integer (i-n)
      character *8 zcom,ztit
      character *1 dash
      logical  iftran
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
      common/linkmr/map(510),ipr,lbuff,igame
c
      dimension r(*),q(*),nj(*),lj(*),ntil(*),mwal(*),
     * mmm(255),mj(*),ick(*),kj(*),iaus(*),ilifm(255)
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
      call readis(ilifd,mach(9)*nav,idaf)
      if(nbasis.ne.iorbs) then
       write(6,*)' TVEC ERROR: nbasis,iorbs = ', nbasis, iorbs
       call caserr(
     +    'vectors restored from dumpfile have incorrect format')
      endif
      if(nbasis.ne.newbas.or.nbasis.lt.ncol) then
         call caserr(
     + 'invalid number of basis functions in tvec')
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
      nbsq=nbasis*ncol
      call reads(q,nbsq,idaf)
c
c     classify atmol scf-mos into symmetry types
c
      do 19 i=1,nsym
 19   lj(i)=0
      kk=0
      do 20 k=1,ncol
      do 21 i=1,nsym
      ii=ntil(i)+kk
      iii=nj(i)
      xx=0.0d0
      do 22 j=1,iii
      qq=q(ii+j)
 22   xx=xx+qq*qq
      if(xx.lt.thr)go to 21
      lj(i)=lj(i)+1
      mmm(k)=i
      go to 20
 21   continue
      call caserr('error assigning symmetry of input m.o.s')
 20   kk=kk+nbasis
      do 23 i=1,nsym
      if(lj(i).gt.nj(i))call caserr(
     *'error in molecular orbital symmetry designations')
 23   continue
c
c     now load into core in tmrdm order
c
      ic=0
      do 26 i=1,nsym
      mwal(i)=ic
 26   ic=ic+nj(i)*lj(i)
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
      if(mcore.eq.0)go to 102
      iii=iicore
      do 103 ii=1,mcore
      iii=iii+1
      if(ij.eq.ick(iii))go to 101
 103  continue
 102  if(mout.eq.0)go to 106
      iii=iivirt
      do 105 ii=1,mout
      iii=iii+1
      if(ij.eq.iaus(iii))go to 101
 105  continue
 106  nact=nact+1
      ilifm(nact)=jjj
 101  continue
      iicore=iicore+mcore
      iivirt=iivirt+mout
 100  continue
      if(oprint(31))write(iwr,110)(dash,i=1,129)
 110  format(/1x,129a1)
      if(oprint(31))write(iwr,111)
 111  format(/40x,
     *'active orbitals (sabf basis) -- internal labelling'/40x,
     *50('-'))
      if(oprint(31))call writem(q,ilifm,nbasis,nact)
      do 30 i=1,nsym
      ii=nj(i)
      iii=ntil(i)
      ibase=mwal(i)
      jjj=0
      do 31 j=1,ncol
      if(mmm(j).ne.i)go to 31
      ij=jjj+iii
      do 32 k=1,ii
      ibase=ibase+1
 32   r(ibase)=q(ij+k)
 31   jjj=jjj+nbasis
 30   continue
c
      if(oprint(31))write(iwr,110)(dash,i=1,129)
      return
      end
_EXTRACT(tmrdm,hp800)
      subroutine tmrdm(t,r,q,sa,ha,bob,acoul,aexc,lword)
      implicit REAL  (a-h,o-z), integer (i-n)
      logical ocrash
INCLUDE(common/sizes)
      character *1 dash
INCLUDE(common/prints)
INCLUDE(common/mapper)
INCLUDE(common/iofile)
INCLUDE(common/ftape)
INCLUDE(common/blockc)
      common/craypk/ic,i7,mjj(8),kjj(8),isecvv,icorf,
     * icl(256),izer1,iaut(256),ispp(1467)
_IFN1(v)      common/scrtch/res(22500)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/junk /cf(22500),icf(22500)
      common/scra /ixa(3400),
     *ss(255),st(255),espace(6891)
      common/blkin/cm(100),cx(100),cy(100),cz(100),
     * z(100),xx(100),yy(100),zz(100),
     * iord(256),ncont(100),nco(100)
     *,hm(mxcrc2),sm(mxcrc2),nit(667),
     * lj(8),ick(256),iaus(256),jtil(8),
     * mwal(8),isym(8),isper(8)
      common/lsort /ston(2000)
      common/b/ sum,gg,itape,jtape,ntape,mtape,ltape,mscr,nrac,nrecy,
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icm,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ktape
c
      dimension t(*),r(*),q(*),sa(*),ha(*)
      dimension bob(*),acoul(*),aexc(*)
_IF(cray,ksr,i8)
      dimension c(400),msym(2040),e(7401)
_ELSE
      dimension c(400),msym(2040),e(6633)
_ENDIF
      dimension fm(500),guf(mxcrec),f(751)
      dimension intin(2000),newya(255)
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
      ltape=nf31
      mtape=nf2
      nrac=10
      mscr=nf1
      itape=ird
      jtape=iwr
c
      call rewftn(ntape)
      call rewftn(ltape)
      call rewftn(mtape)
      call rewftn(mscr)
c
      cpu=cpulft(1)
      if(.not.oprint(29)) write(jtape,8999)cpu ,charwall()
 8999 format(/' commence integral transformation at ',f8.2,
     * ' seconds',a10,' wall'/)
      thr=1.0d-6
c ... max.no.. of aos now set to 150
      ithr=22500
      ifrk=500
      nod=mxcrec
      jod=2000
      ib=401
      ib2=ib+ib
      itx=ib2
      ity=itx
      if2=1000
_IF(cray,ksr)
      ik=(lword-500)/2
      irs=ik+ik
_ELSE
      ik=(lword-500)/3
      ik=ik+ik
      irs=(3*ik+500)/2
_ENDIF
      ifrk1=ifrk+1
c
c     ----- open sort file
c
_IF(parallel)
c **** MPP
      call closbf(0)
      call setbfa(-1)
c **** MPP
_ELSE
      call setbfa
_ENDIF
c
      read(ntape)nb,ndum,nhfunc,(iord(i),i=1,nhfunc),repel
     * ,newya
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
      n=0
      do 12 i=1,nsel
      if(nj(i).eq.0) go to 12
      n=n+1
      isper(i)=n
      nj(n)=nj(i)
      ntil(n)=ntil(i)
      nbal(n)=nbal(i)
      isym(n)=i
12    continue
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
      do 8990 loop=1,8
      mj(loop)=mjj(loop)
 8990 kj(loop)=kjj(loop)
      do 8991 loop=1,256
      ick(loop)=icl(loop)
 8991 iaus(loop)=iaut(loop)
      if(.not.oprint(29)) write(jtape,8069)
8069  format(/40x,27('=')/
     *        40x,'input orbital specification'/
     *        40x,27('=')/)
      ic=0
      k=0
      l=0
      do 8070 i=1,n
      if(.not.oprint(29)) then
       write(jtape,8071)(dash,j=1,38)
 8071  format(/1x,129a1)
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
c     call routine for restoring atmol vectors
c
      call tvec(r,q,etot,nj,lj,ntil,mwal,mj,ick,kj,iaus,
     * n,iorbs,iposv)
       do 19 i=1,n
 19    mbal(i)=mwal(i)
      imo=0
      ic=0
      ivla=0
      do 24 i=1,n
      ibal(i)=ic
      np=nj(i)
      mw=mbal(i)
      ict=mj(i)
      if(icore.eq.0) go to 25
      if(ict.eq.0) go to 25
      do 26 j=1,ict
      ich=ich+1
      icy=mw+(ick(ich)-1)*np
      imo=imo+1
      isam=ic
      do 39 k=1,np
      icy=icy+1
      sac=r(icy)
      if(dabs(sac).lt.thr) go to 39
      ic=ic+1
      icf(ic)=k
      cf(ic)=sac
39    continue
26    mcomp(imo)=ic-isam
      jch=ich-ict+1
      jct=1
      jcx=ick(jch)
      go to 27
25    jcx=0
 27   izx=kj(i)
      if(izer.eq.0) go to 28
      if(izx.eq.0) go to 28
      ivla=ivla+izx
      izt=izt+1
      izy=1
      izq=iaus(izt)
      go to 29
28    izq=0
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
      do 36 k=1,np
      mw=mw+1
      sac=r(mw)
      if(dabs(sac).lt.thr) go to 36
      ic=ic+1
      icf(ic)=k
      cf(ic)=sac
36    continue
30    mcomp(imo)=ic-isam
116   izt=ivla
24    continue
      if(ic.gt.ithr) call caserr(
     * 'dimensioning problem with vectors')
      icmo=0
      do 37 loop=1,n
      kj(loop)=lj(loop)-kj(loop)
      itil(loop)=icmo
37    icmo=icmo+kj(loop)
      write(ltape)cf,ibal,itil,icf,mcomp,kj,mj,etot,icmo,ij
     * ,icore
      ig=0
      do 42 i=1,n
      kij=nj(i)
      ig=ig+iky(kij+1)
42    continue
      nblk=(ig-1)/mxcrc2+1
      lg=0
      do 43 i=1,nblk
      read(ntape)guf
      do 43 j=1,mxcrc2
      lg=lg+1
      sa(lg)=sm(j)
      ha(lg)=hm(j)
      if(lg.eq.ig) go to 44
43    continue
44    nrecy=nblk+4
      do 2000 ipass=1,2
      do 2001 i=1,nblk
 2001 read(ntape)guf
 2000 nrecy=nrecy+nblk
      ig=0
      nt=1
      mg=0
      if(oprint(32)) write(jtape,57)
57    format(/2x,'overlap and t+v integrals'/)
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
      do 48 k=1,ng
      ss(k)=0.0d0
48    st(k)=0.0d0
      do 49 k=1,nc
      llx=llx+1
      ld=icf(llx)
      sac=cf(llx)
      if(ld.eq.1) go to 50
      lda=ld-1
      iw=mg+iky(ld)
      do 46 l=1,lda
      iw=iw+1
      ss(l)=ss(l)+sac*sa(iw)
46    st(l)=st(l)+sac*ha(iw)
50    iw=mg+ld
      do 51 l=ld,ng
      iz=iw+iky(l)
      ss(l)=ss(l)+sac*sa(iz)
51    st(l)=st(l)+sac*ha(iz)
49    continue
      mx=kx
      mm=lkg
      do 47 k=1,j
      mm=mm+1
      ncp=mcomp(mm)
_IF(vax)
      sum=0.0
      tum=0.0
      do 52 l=1,ncp
      mx=mx+1
      ld=icf(mx)
      sac=cf(mx)
      sum=sum+sac*ss(ld)
 52   tum=tum+sac*st(ld)
_ELSE
_IF(cray)
      sum=spdot(ncp,ss,icf(mx+1),cf(mx+1))
      tum=spdot(ncp,st,icf(mx+1),cf(mx+1))
_ELSE
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),ss)
      tum=ddoti(ncp,cf(mx+1),icf(mx+1),st)
_ENDIF
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
      if(nb.lt.0) go to 58
      read(ntape)ig
      if(ig.ne.1)call caserr('format error on ft22')
      read(ntape)
      write(ltape) ig
      write(ltape)ig,ig,ig,ig
_IFN1(v)      call tmrd0(t(1),t(1),res,iorbs)
_IF1(v)      call tmrd0(t(1),t(1))
      go to 100
58    read(ntape)jv
      if(oprint(31)) write(6,*)'jv = ', jv
      write(ltape) jv
      do 59 i=1,jv
      read(ntape) ii,jj,kk,ll
      if(oprint(31)) write(6,*)'ii,jj,kk,ll = ', ii,jj,kk,ll
      ii=isper(ii)
      jj=isper(jj)
      ll=isper(ll)
      kk=isper(kk)
      if(oprint(31)) then
       write(6,*)'isper,ii,jj,kk,ll = ', ii,jj,kk,ll
       write(6,*)'kj, ii,jj,kk,ll = ', kj(ii),kj(jj),
     +                                kj(kk),kj(ll)
      endif
      if (kj(ii)*kj(jj)*kj(kk)*kj(ll).eq.0) go to 215
      write(ltape) ii,jj,kk,ll
      if(ii.ne.jj) go to 60
      if(ii.eq.kk) go to 61
      go to 62
60    if(ii.eq.kk) go to 63
      go to 64
_IFN1(v)61    call tr1iii(ii,t(1),t(1),res,nj(ii))
_IF1(v)61    call tr1iii(ii,t(1),t(1))
      go to 59
_IFN1(v)62    call tr1iij(ii,kk,t(1),t(1),res,nj(ii))
_IF1(v)62    call tr1iij(ii,kk,t(1),t(1))
      go to 59
63    call tr1iji(ii,jj,t(1),t(1))
      go to 59
215   read(ntape) f
      if (n2.ne.0) go to 215
      ii=0
      write (ltape) ii,ii,ii,ii
      go to 59
64    call tr1ijk(ii,jj,kk,ll,t(1),t(1))
59    continue
100   call rewftn(ntape)
      call rewftn(ltape)
      read(ltape)nsel,nj,ntil,nbal,isym,jsym,n,iorbs,knu,lsym,ncomp,e,c,
     1repel
      write(mtape)nsel,nj,ntil,nbal,isym,jsym,n,iorbs,knu,lsym,ncomp,e,c
     1,repel
      read(ltape)cf,ibal,itil,icf,mcomp,kj,mj,etot,icmo,ij
     * ,icore
      ns=0
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
      read(ltape) jv
      write(mtape) jv
      nrecy=nt+4
      do 110 ii=1,jv
      read(ltape) i,j,k,l
      write(mtape) i,j,k,l
      if (i.eq.0) go to 110
      if(i.ne.j) go to 111
      if(i.eq.k) go to 112
      go to 113
111   if(i.eq.k) go to 114
      go to 115
_IFN1(v)112   call tr2iii(i,t(1),t(1),res,nj(i))
_IF1(v)112   call tr2iii(i,t(1),t(1))
      go to 110
_IFN1(v)113   call tr2iij(i,k,t(1),t(1),res,nj(k))
_IF1(v)113   call tr2iij(i,k,t(1),t(1))
      go to 110
114   call tr2iji(i,j,t(1),t(1))
      go to 110
115   call tr2ijk(i,j,k,l,t(1),t(1))
110   continue
      call rewftn(ltape)
      call rewftn(mtape)
      read(mtape)nsel,nj,ntil,nbal,isym,jsym,n,iorbs,knu,lsym,ncomp,e,c,
     1repel
      read(mtape)nit,lj,kj,mj,ij,cf,icf,ibal,itil,mcomp,etot,icmo,
     * icore
      core=repel-etot
      nt=0
      do 201 i=1,n
      jtil(i)=nt
      njx=ij(i)
201   nt=nt+njx
      write(ltape)n,nod,jod,icmo,nt,kj,mj,ij,nj,nsel,ntil,nbal,
     1isym,jsym,iorbs,knu,newya,lsym,ncomp,e,c,repel,etot
      write(ltape)nit,lj,cf,icf,ibal,itil,mcomp
      read(mtape) guf
      ig=0
      do 202 i=1,n
      kjx=kj(i)
      if(kjx.eq.0) go to 202
      mjx=mj(i)
      ljx=lj(i)
      do 203 j=1,kjx
      lx=j-mjx
      do 203 k=1,j
      ig=ig+1
      if(lx.gt.0) go to 204
      if(j.ne.k) go to 205
      core=core+2.0d0*guf(ig)
      go to 205
204   mx=k-mjx
      if(mx.lt.1) go to 205
      mx=iky(lx)+mx+ljx
      bob(mx)=guf(ig)
205   if(ig.lt.nod) go to 203
      ig=0
      read(mtape)guf
203   continue
202   continue
      call tmrdm2(bob,acoul,aexc,core,icore,ns,nt,jod)
      return
      end
_ENDEXTRACT
      subroutine tmrdm2(bob,acoul,aexc,core,icore,ns,nt,jod)
      implicit REAL  (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/mapper)
INCLUDE(common/iofile)
INCLUDE(common/ftape)
      common/craypk/ic,i7,mjj(8),kjj(8),isecvv,icorf,
     * icl(256),izer1,iaut(256),ispp(1467)
_IFN1(v)      common/scrtch/res(22500)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/junk /cf(22500),icf(22500)
      common/scra /ixa(3400),ss(255),st(255),espace(6891)
      common/blkin/cm(100),cx(100),cy(100),cz(100),
     * z(100),xx(100),yy(100),zz(100),
     * iord(256),ncont(100),nco(100)
     *,hm(mxcrc2),sm(mxcrc2),nit(667),
     * lj(8),ick(256),iaus(256),jtil(8),
     * mwal(8),isym(8),isper(8)
      common/lsort /ston(2000)
      common/b/ sum,gg,itape,jtape,ntape,mtape,ltape,mscr,nrac,nrecy,
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icm,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ktape
c
      dimension bob(*),acoul(*),aexc(*)
      dimension c(400),msym(2040)
_IF(cray,ksr,i8)
      dimension e(7401)
_ELSE
      dimension e(6633)
_ENDIF
      dimension fm(500),guf(mxcrec),f(751)
      dimension intin(2000)
      character*10 charwall
c
      equivalence (c(1),cm(1)),(msym(1),e(1),ss(1))
      equivalence (hm(1),guf(1))
      equivalence (fm(251),n2),(f(501),fm(1)),(g(1),f(1))
      equivalence (nit(667),lg),(intin(1),ic)
c
c
      nx=iky(nt+1)
      call vclr(acoul,1,nx)
      call vclr(aexc,1,nx)
      read(mtape) jv
      ig=0
_IFN(cray)
      call setsto(2000,0,intin)
_ENDIF
      if(icore.eq.0) go to 300
      do 207 i=1,jv
      read(mtape) ii,jj,kk,ll
      if (ii.eq.0) go to 207
      if(ii.eq.jj) go to 208
      if(ii.eq.kk) go to 214
      go to 210
208   if (ii.ne.kk) go to 213
      mjx=mj(ii)
      mat=lj(ii)
      jta=jtil(ii)
220   read(mtape)f
      call unpack(fm,8,intin,2000)
      int4=1
      do 221 is=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 207
      ia=ijkl    -mjx
      ja=intin(int4+1)-mjx
      ka=intin(int4+2)-mjx
      la=intin(int4+3)-mjx
      if(la.gt.0) go to 222
      if (ka.ne.la) go to 223
      if(ia.ne.ja) go to 224
      if(ia.gt.0) go to 225
      if(ia.eq.ka) go to 226
      core=core+4.0d0*f(is)
      go to 221
226   core=core+f(is)
      go to 221
225   ib=iky(ia+1)+mat
227   bob(ib)=bob(ib)+2.0d0*f(is)
      go to 221
224   if(ja.lt.1) go to 221
      ib=iky(ia)+ja+mat
      go to 227
223   if(ka.gt.0) go to 228
      if(ia.ne.ka) go to 221
      if(ja.ne.la) go to 221
      core=core-2.0d0*f(is)
      go to 221
228   if(ja.ne.la) go to 221
      ib=iky(ia)+ka+mat
      bob(ib)=bob(ib)-f(is)
      go to 221
222   if(ja.lt.1) go to 221
      ig=ig+1
      ston(ig)=f(is)
      if(ig.lt.jod) go to 230
      ig=0
      write(ltape) ston
230   if(ia.eq.ja) go to 229
      if(ia.ne.ka.or.ja.ne.la) go to 221
      ia=ia+jta
      ja=ja+jta
      ib=iky(ia)+ja
      aexc(ib)=f(is)
      go to 221
229   if(ka.ne.la) go to 221
       ia=ia+jta
       ka=ka+jta
      if(ia.eq.ka) go to 231
      ib=iky(ia)+ka
      acoul(ib)=f(is)
      go to 221
231   ib=iky(ia+1)
      ac=f(is)
      acoul(ib)=ac
      aexc(ib)=ac
221   int4=int4+4
      go to 220
213   mjx=mj(ii)
      mjy=mj(kk)
      jta=jtil(ii)
      jtb=jtil(kk)
      mat=lj(ii)
      mbt=lj(kk)
232   read(mtape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 233 is=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 207
      ia=ijkl    -mjx
      ja=intin(int4+1)-mjx
      ka=intin(int4+2)-mjy
      la=intin(int4+3)-mjy
c394    format(2x,10i6,e15.8)
      if (la.gt.0) go to 234
      if(ka.ne.la) go to 233
      if(ja.gt.0) go to 235
      if(ia.ne.ja) go to 233
      core=core+4.0d0*f(is)
      go to 233
235   ib=iky(ia)+ja+mat
237   bob(ib)=bob(ib)+2.0d0*f(is)
      go to 233
234   if(ja.gt.0) go to 236
      if(ia.ne.ja) go to 233
      ib=iky(ka)+la+mbt
      go to 237
 236  ig=ig+1
      ston(ig)=f(is)
      if(ig.lt.jod) go to 238
      ig=0
      write(ltape) ston
238   if(ia.ne.ja.or.ka.ne.la) go to 233
      ia=ia+jta
      ka=ka+jtb
      ia=iky(ia)+ka
      acoul(ia)=f(is)
233   int4=int4+4
      go to 232
 214  mjx=mj(ii)
      mjy=mj(jj)
      jta=jtil(ii)
      jtb=jtil(jj)
      mat=lj(ii)
      mbt=lj(jj)
239   read(mtape)f
      call unpack(fm,8,intin,2000)
      int4=1
      do 240 is=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 207
      ia= ijkl   -mjx
      ja=intin(int4+1)-mjy
      ka=intin(int4+2)-mjx
      la=intin(int4+3)-mjy
      if(la.gt.0) go to 241
      if (ja.ne.la) go to 240
      if(ka.gt.0) go to 242
      if (ia.ne.ka) go to 240
      core=core-2.0d0*f(is)
      go to 240
242   ib=iky(ia)+ka+mat
244   bob(ib)=bob(ib)-f(is)
      go to 240
241    if(ja.lt.1) go to 240
      if(ka.gt.0) go to 243
      if(ia.ne.ka) go to 240
      ib=iky(ja)+la+mbt
      go to 244
 243  ig=ig+1
      ston(ig)=f(is)
      if (ig.lt.jod) go to 245
      ig=0
      write(ltape) ston
245   if(ia.ne.ka.or.ja.ne.la) go to 240
      ia=ia+jta
      ja=ja+jtb
      ia=iky(ia)+ja
      aexc(ia)=f(is)
240   int4=int4+4
      go to 239
 210  mjx=mj(ii)
      mjy=mj(jj)
      mja=mj(kk)
      mjb=mj(ll)
246   read(mtape)f
      call unpack(fm,8,intin,2000)
      int4=1
      do 247 is=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 207
      ia= ijkl   -mjx
      if(ia.lt.1) go to 247
      ja=intin(int4+1)-mjy
      if(ja.lt.1) go to 247
      ka=intin(int4+2)-mja
      if(ka.lt.1) go to 247
      la=intin(int4+3)-mjb
      if(la.lt.1) go to 247
      ig=ig+1
      ston(ig)=f(is)
      if(ig.lt.jod) go to 247
      ig=0
      write(ltape) ston
247   int4=int4+4
      go to 246
207   continue
      go to 400
300   do 307 i=1,jv
      read(mtape) ii,jj,kk,ll
      if(ii.eq.jj) go to 308
      if(ii.eq.kk) go to 314
      go to 346
308   if(ii.ne.kk) go to 313
      jta=jtil(ii)
320   read(mtape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 321 is=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 307
      ia= ijkl
      ja=intin(int4+1)
      ka=intin(int4+2)
      la=intin(int4+3)
      ig=ig+1
      ston(ig)=f(is)
      if(ig.lt.jod) got o330
      ig=0
      write(ltape) ston
330   if(ia.eq.ja) go to 329
      if(ia.ne.ka.or.ja.ne.la) go to 321
      ia=ia+jta
      ja=ja+jta
      ib=iky(ia) +ja
      aexc(ib)=f(is)
      go to 321
329   if(ka.ne.la) go to 321
       ia=ia+jta
       ka=ka+jta
      if(ia.eq.ka) go to 331
      ib=iky(ia)+ka
      acoul(ib)=f(is)
      go to 321
331   ib=iky(ia+1)
      ac=f(is)
      acoul(ib)=ac
      aexc(ib)=ac
321   int4=int4+4
      go to 320
 313  jta=jtil(ii)
      jtb=jtil(kk)
332   read(mtape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 333 is=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 307
      ia= ijkl
      ja=intin(int4+1)
      ka=intin(int4+2)
      la=intin(int4+3)
      ig=ig+1
      ston(ig)=f(is)
      if(ig.lt.jod) go to 338
      ig=0
      write(ltape) ston
338   if(ia.ne.ja.or.ka.ne.la) go to 333
      ia=ia+jta
      ka=ka+jtb
      ia=iky(ia) +ka
      acoul(ia)=f(is)
333   int4=int4+4
      go to 332
 314  jta=jtil(ii)
      jtb=jtil(jj)
339   read(mtape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 340 is=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 307
      ia= ijkl
      ja=intin(int4+1)
      ka=intin(int4+2)
      la=intin(int4+3)
      ig=ig+1
      ston(ig)=f(is)
      if(ig.lt.jod) go to 345
      ig=0
      write(ltape) ston
345   if(ia.ne.ka.or.ja.ne.la) go to 340
      ia=ia+jta
      ja=ja+jtb
      ia=iky(ia)+ja
      aexc(ia)=f(is)
340   int4=int4+4
      go to 339
346   read(mtape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 347 is=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 307
      ia= ijkl   -1
      ja=intin(int4+1)-1
      ka=intin(int4+2)-1
      la=intin(int4+3)-1
      ig=ig+1
      ston(ig)=f(is)
      if(ig.lt.jod) go to 347
      ig=0
      write(ltape) ston
347   int4=int4+4
      go to 346
307   continue
 400  write(ltape) ston
      write(ltape) ns,(bob(i),i=1,ns),
     *nx,(acoul(i),i=1,nx),
     *nx,(aexc(i),i=1,nx),
     *core
      if(.not.oprint(29)) write(jtape,390)
390   format(//20x,'coulomb and exchange integrals'/20x,30('-')/)
      if(oprint(32)) go to 401
      ig=0
      do 402 i=1,nt
      ig=ig+i
402   if(.not.oprint(29)) write(jtape,403) i,i,acoul(ig)
403   format(17x,2i5,2f20.8)
      go to 405
401   ig=0
      do 404 i=1,nt
      do 404 j=1,i
      ig=ig+1
404   write(jtape,403) i,j,acoul(ig),aexc(ig)
      ig=0
      write(jtape,409)
      do 406 i=1,n
      ljx=ij(i)
      if(ljx.eq.0) go to 406
      ia=jtil(i)
      do 407 j=1,ljx
      ja=j+ia
      do 407 k=1,j
      ig=ig+1
       ka=k+ia
407   write(jtape,408)i,ja,ka,bob(ig)
408   format(10x,3i5,f20.8)
409   format(/20x,'core-type integrals'/)
406   continue
405   if(.not.oprint(29)) write(jtape,420) core
420   format(/20x,'core = ',f20.8,' hartree')
      call rewftn(ntape)
      call rewftn(ltape)
      call rewftn(mtape)
      call rewftn(mscr)
      cpu=cpulft(1)
      if(.not.oprint(29)) write(jtape,8998)cpu ,charwall()
 8998 format(/
     *' end of integral transformation at',f8.2,' seconds',a10,' wall'/)
      return
      end
_EXTRACT(tr2ijk,hp800)
      subroutine tr2ijk(i,j,k,l,t,is)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/blksiz)
      common/stak/btri,mlow(2),irec
      common/scra /ixa(3400)
INCLUDE(common/prints)
      common/aplus/g(900),p(751),v(255),idxd(300),
     * nir(256),loc(256),ncomp(256),jdeks(256),kdeks(256),
     * lsym(2040),mj(8),nj(8),ntil(8),nbal(9),
     * irper(8),ircor(8),mtil(8),mbal(9),inper(8),mver(4),
     * mvom(4),npal(8),ij(8),mvil(4),
     * kj(8),mcomp(256),ibal(8),itil(8)
      common/three/mli(1000),mlr(1000),nrc(1000),nfg(1000)
      common/bufb/nwbnwb,lnklnk,gout(5119)
      common/craypk/intin(2000),intout(2000)
      common/junk /cf(22500),icf(22500)
      common/b/ sum,gg,itape,jtape,ktape,mtape,ltape,mscr,nrac,nrecy,
     1nblk,ifrk,ifrk1,ik,if2,im,mjx,kxl,njx,nzl,ina,il,iq,ib,icak,
     2ib2,itx,nbyt,ity,ix,iy,imax,ifm,ig,isb,jsb,jx,ilc,jj,idx,
     3iln,kz,mq,mm,if,md,iba,nz,jdx,iwa,it,kdx,kt,lh,k5,jm,ixq,lv,km,
     4kd,kr,inr,lp,kw,mmx,mmm,lx,kk,lw,mlim,mcp,ll,ld,lda,iw,iz,mc,mx,
     5ncp,kx,nrec2,ntel,irs,ijkl,nmel,ist,mi,jl,mk,ibl,jn,in1,in,ncas,
     6nlop,ia,ja,ka,la,kp,lenth,int,ii,icl,iorbs,llx,mjy,inb,i8,lly,ky,
     7mja,mjb,lt,kyl,i5,nsel,n,jv,js,ks,ls,lr,jr,nrec1,imc,ntape
      dimension f(751)
      dimension q(500),fm(251),pq(500),pli(251)
     + ,gin(5119),is(*),t(*)
      equivalence (g(1),q(1)),(g(501),fm(1)),(fm(251),n2),
     +(gin(1),gout(1)),(p(1),pq(1)),(p(501),pli(1))
     +,(g(1),f(1))
      data maxb/9999999/
      mjx=kj(i)
      mjy=kj(j)
      mja=nj(k)
      mjb=nj(l)
      lja=kj(k)
      ljb=kj(l)
      ifm=-mjy
      do 901 ll=1,mjx
      ifm=ifm+mjy
  901 kdeks(ll)=ifm
      ifm=-mjb
      do 900 ll=1,mja
      ifm=ifm+mjb
  900 jdeks(ll)=ifm
c
      nav = lenwrd()
c
      mmx=ibal(l)
      mmm=itil(l)
      jdx=ibal(k)
      idx=itil(k)
      ina=mjx*mjy
      inb=mja*mjb
      im=ik/inb
      if(im.gt.ina) im=ina
      il=(ina-1)/im+1
      iq=(il-1)/if2+1
      il=(il-1)/iq+1
      ib=ik/il
      icak=inb*im
      itx=ib/nav
      if(itx*nav.ne.ib) ib=ib-1
      if(ib.gt.nsz340) ib=nsz340
      itx=(nav+1)*ib
      ity=itx/nav
      ix=-ib
      iy=-ity
      imax=im*il
      ifm=-imax
      do 1 i=1,il
      ix=ix+itx
      iy=iy+ity
      mlr(i)=iy
      mli(i)=ix
      nrc(i)=maxb
    1 nfg(i)=0
      ig=0
      ig4=-3
      isb=0
      jsb=0
      if(iq.eq.1) go to 700
      call rewftn(mscr)
  701 read(ltape) f
      write(mscr) f
      if(n2.ne.0) go to 701
      ntape=mscr
      call rewftn(ntape)
      go to 702
  700 ntape=ltape
  702 do 2 i8=1,iq
      ifm=ifm+imax
      irec=0
      ilc=0
_IFN(cray)
      call setsto(2000,0,intin)
_ENDIF
  11  read(ntape) f
      call unpack(fm,8,intin,2000)
      int4=1
      do 3 jj=1,ifrk
      ijkl=intin(int4)
      if(ijkl.eq.0) go to 705
      i=ijkl
      j=intin(int4+1)
      kdx=kdeks(i)+j-ifm
      if(kdx.lt.1.or.kdx.gt.imax) go to 3
      k=intin(int4+2)
      iln=(kdx-1)/im+1
      kz=kdx-(iln-1)*im
      mq=mlr(iln)+1
      mm=mli(iln)+1
      t(mq)=q(jj)
      l=intin(int4+3)
      if(oprint(31)) then
       write(6,5566) jj,i,j,k,l,q(jj)
5566   format(1x,'tr2ijk: i,j,k,l,val = ',i4,2x,4i4,5x,f20.10)
      endif
      is(mm)=(kz-1)*inb+jdeks(k)+l
      if=nfg(iln)+1
      if(if.eq.ib) go to 10
      nfg(iln)=if
      mlr(iln)=mq
      mli(iln)=mm
      go to 3
 10   call stopbk
      nwbnwb=ib
      lnklnk=nrc(iln)
      md=mq-ib
      me=mm-ib
      call dcopy(ib,t(md+1),1,gout,1)
      call pack(gout(nsz341),32,is(me+1),nsz340)
      call sttout
      mlr(iln)=md
      mli(iln)=me
      nrc(iln)=irec
      nfg(iln)=0
      irec=irec+nsz
   3  int4=int4+4
      go to 11
 705  do 13 jj=1,il
      nz=nfg(jj)
      if(nz.eq.0)go to 13
      call stopbk
      nwbnwb=nz
      lnklnk=nrc(jj)
      mq=mlr(jj)-nz
      mm=mli(jj)-nz
      call dcopy(nz,t(mq+1),1,gout,1)
      call pack(gout(nsz341),32,is(mm+1),nsz340)
      call sttout
      mlr(jj)=mq
      mli(jj)=mm
      nrc(jj)=irec
      irec=irec+nsz
 13   continue
c
      call stopbk
c
      imc=im
      i=isb
 200  i=i+1
      j=jsb
 201  j=j+1
      if(imc.lt.im)  goto 40
      if(ilc.eq.il) go to 50
      ilc=ilc+1
      imc=0
      iwa=0
      call vclr(t,1,icak)
      lnklnk=nrc(ilc)
      go to 32
 33   iblok=lnklnk
      call rdbak(iblok)
      call stopbk
      call unpack(gin(nsz341),32,ixa,nsz340)
_IF(vax)
      do 332 moop=1,nwbnwb
      ixq=ixa(moop)
 332  t(ixq)=gin(moop)
_ELSEIF(cray)
      call scatter(nwbnwb,t,ixa,gin)
_ELSE
      call dsctr(nwbnwb,gin,ixa,t)
_ENDIF
 32   if(lnklnk.ne.maxb)go to 33
  40  imc=imc+1
      lx=jdx
      kk=idx
      do 41 k=1,lja
      kk=kk+1
      mcp=mcomp(kk)
c     do 39 ll=1,mjb
c 39  v(ll)=0.0
      call vclr(v,1,mjb)
      do 43 ll=1,mcp
      lx=lx+1
      ld=icf(lx)
      iw=iwa+jdeks(ld)
      do 70 l=1,mjb
      iw=iw+1
  70  v(l)=v(l)+t(iw)*cf(lx)
  43  continue
      mx=mmx
      mm=mmm
      do 55 l=1,ljb
      mm=mm+1
      ncp=mcomp(mm)
_IF(vax)
      sum=0.0
      do 53 ll=1,ncp
      mx=mx+1
      ld=icf(mx)
  53  sum=sum+cf(mx)*v(ld)
_ELSEIF(cray)
      sum=spdot(ncp,v,icf(mx+1),cf(mx+1))
      mx=mx+ncp
_ELSE
      sum=ddoti(ncp,cf(mx+1),icf(mx+1),v)
      mx=mx+ncp
_ENDIF
      ig=ig+1
      pq(ig)=sum
      ig4=ig4+4
      intout(ig4  )=i
      intout(ig4+1)=j
      intout(ig4+2)=k
      intout(ig4+3)=l
      if(ig.lt.ifrk) go to 55
      call pack(pli,8,intout,2000)
      write(mtape) p
      ig=0
      ig4=-3
  55  continue
  41  continue
      iwa=iwa+inb
         if(j.lt.mjy) go to 201
       jsb=0
      if(i.lt.mjx) go to 200
      ig4=ig4+4
      intout(ig4)=0
      intout(ig4+1)=0
      intout(ig4+2)=0
      intout(ig4+3)=0
      call pack(pli,8,intout,2000)
      write(mtape) p
      return
  50  isb=i-1
      jsb=j-1
      call rewftn(ntape)
      do 58 i=1,il
      nfg(i)=0
  58  nrc(i)=maxb
   2  continue
      return
      end
_ENDEXTRACT
      subroutine ver_mrdci2(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mrdci2.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
