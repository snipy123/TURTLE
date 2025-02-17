c 
c  $Author: jmht $
c  $Date: 2010-07-15 00:46:22 +0200 (Thu, 15 Jul 2010) $
c  $Locker:  $
c  $Revision: 6141 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mrdci7.m,v $
c  $State: Exp $
c  
c ******************************************************
c ******************************************************
c             =   Table-ci (diagonalisation module) =
c ******************************************************
c ******************************************************
      subroutine dmrdci(aa,bb,atp,vec,ddd,dia,maxcnf,core,
     + energy,lword)
      implicit REAL (a-h,o-z), integer (i-n)
      character *8 title,zcomm
      character *1 dash
c     driver for ci diagonalization program
c     ndhf = block size of hmx file (assumed mxcrec in this program)
c     ndel = block size of energy lowering data (assumed 500)
INCLUDE(common/sizes)
INCLUDE(common/prints)
      common/file/ndhf,ndel
INCLUDE(common/iofile)
      common/ftape/nfb,nfab,nf11,nfrsut,nfsc,nfmx,
     * nspacf(6),nfmain,nfci,idum4(6)
      common/miscop/vmain(mxcsf*mxroot),atmx(mxcsf*(mxcsf+1)/2),
     + escf,eci(mxroot,10),pthr,iovlp(mxroot),
     + iwfm(mxcsf),ncsf,nocsf,nomain,nroot,ntry,kcsf(10),
     + iper(mxroot)
      common/junkc/zcomm(29),title(10)
INCLUDE(common/runlab)
      logical oroot
      common/craypk/thr,thrcc,thrs,thrf,cutoff,
     * mtry,mroot,mexp,maxcyc,jovlp(mxroot),jfix(mxroot),
     * mset,mproot,merr,oroot,mcut,mspac
      dimension ifxx(mxroot),scra(mxcsf)
      dimension core(lword)
      dimension aa(maxcnf),bb(maxcnf),atp(*),vec(*),
     +  ddd(maxcnf),dia(maxcnf)
      data dash/'-'/
      data zero/0.0d0/
c
      write(iwr,11)
 11   format(/1x,104('=')//
     *40x,36('*')/
     *40x,'Table-ci  --  diagonalization module'/
     *40x,36('*')/)
      nocsf=0
      mxcsft = mxcsf*(mxcsf+1)/2
      call vclr(atmx,1,mxcsft)
      call rewftn(nfmain)
      call rewftn(nfci)
      call rewftn(nfmx)
      call rewftn(nfrsut)
      call rewftn(nfb)
      call rewftn(nfab)
      call rewftn(nfsc)
      call rewftn(nf11)
      do 555 loop=1,10
555   title(loop)=ztitle(loop)
c
c    ----- trial
c
      ntry=mtry
c
c     ----- roots
c
      nroot=mroot
      mcut=min(mcut,mxroot)
c
c     ----- extrap
c
      nexp=mexp
c
c     ----- maxcyc
c
      maxit=maxcyc
c
c     ----- overlap + fixup
c
      do 2051 i=1,mxroot
      ifxx(i)=jfix(i)
 2051 iovlp(i)=jovlp(i)
c
c     ----- print/output
c
      pthr=thr
      pthrcc=thrcc
      nproot=mproot
c
c     ----- accuracy/threshold
c
      vthrs=thrs
      vthrf=thrf
c
c     ----- vectors
c
      nset=mset
c
c     ----- error
c
      nerr=merr
c
      if(ntry.le.0.or.ntry.gt.mxcsf)call caserr(
     *'invalid zero order space requested')
      if(nroot.lt.0.or.nroot.gt.mxroot)call caserr(
     *'invalid number of ci roots requested')
      if(nexp.lt.0.or.nexp.gt.6)call caserr(
     *'invalid number of extrapolation passes specified')
      if(maxit.le.0.or.maxit.gt.mxcsf)maxit=50
      if(pthr.eq.zero)pthr=0.05d0
      if(pthrcc.eq.zero)pthrcc=0.002d0
      if(oroot) then
       call dmrdfa(core,lword,aa,bb,mxconf,
     + thr1,thr2,nsk,nexp,pthrcc,nset,cutoff,mcut,energy,iwr)
       go to 210
      else
       call dmrd80(aa,bb,mxconf,thr1,thr2,m0,nsk,nexp,iwr)
      endif
      if(.not.oprint(29)) write(iwr,3) nroot,nexp,maxit,vthrs,vthrf
      call prjajd('table',dum,iwr)
      ncsfo=ntry
      thr=thr1+thr2*nexp
      vthr=vthrs
      nexp1=nexp+1
      do 1000 k=1,nexp1
      if(.not.oprint(29)) write(iwr,9001)(dash,j=1,129)
 9001 format(/1x,129a1)
      cpu=cpulft(1)
      if(k.le.nexp.and..not.oprint(29)) write(iwr,9000)k,cpu
 9000 format(/
     *' commence extrapolation pass no. ',i2,
     *'    at ',f8.2,' secs.'/)
      if(k.eq.nexp1) vthr=vthrf
      call dmrdc(aa,bb,atp,mxconf,thr,nsk)
      kcsf(k)=ncsf
      call dmrdp(thr,m0,aa,bb,ncsf,aa,bb,ncsfo,atp,ddd,dia)
      if(.not.oprint(29)) then
       write(iwr,5) title
       write(iwr,6) nocsf
       write(iwr,7) thr,ncsf
       write(iwr,1) escf,vthr
      endif
      do 1100 n=1,nroot
      ndat=m0
chvd      call drmdd(aa,bb,dia,ncsf,atp,vec,iovlp(n),vthr,ndat,
chvd     +atmx,mxcsft,maxit,ifxx(n),iwr,*40)
c
      ncused = mxcsf*(mxcsf+1)/2 + 3*maxcnf
c
c     <ncused> is the amount of <core> used for <atp>,<vec>,<ddd>
c     and <dia>
c   
      call drmdd(aa,bb,dia,ncsf,atp,vec,iovlp(n),vthr,ndat,
     +atmx,mxcsft,maxit,ifxx(n),core(ncused+1),lword-ncused,iwr,*40)
chvd
      nerr=nerr+2
   40 if(k.eq.nexp1.and.n.eq.nroot.and.nerr.eq.0) go to 1100
      m0=iovlp(n)
      do 1120 i=1,nroot
      if(i.eq.n) go to 1120
      if(ifxx(i).gt.0) go to 1120
      l=iovlp(i)
      call dcopy(ndat,vec(l),ndat,scra,1)
 1140 imax=idamax(ndat,scra,1)
      if(imax.eq.0.or.dabs(scra(imax)).le.0.005d0)
     * call caserr('problem with redundant vectors in diag')
      do 1130 j=1,i-1
       if(iovlp(j).eq.imax) then
        scra(imax) = 0.0d0
       go to 1140
       endif
 1130 continue
      iovlp(i) = imax
 1120 if(iovlp(i).gt.m0) m0=iovlp(i)
      ij=0
      do 1110 i=1,m0
      do 1111 j=1,i
      ij=ij+1
 1111 atmx(ij)=0.0d0
 1110 atmx(ij)=atp(ij)
      call dmrdm(nfab,nfsc,m0,ndat,aa,bb,vec,ncsf)
      call dmrdm(nfb, nfsc,m0,ndat,aa,bb,vec,ncsf)
 1100 continue
      if(nerr.gt.0.and.nproot.gt.0) 
     +               call dmrpwa(nfb,m0,ncsf,pthr,bb,iwr)
      call rewftn(nfrsut)
      call dmrpwf(aa,eci(1,k),atp,aa,bb,iwr)
      ncsfo=ncsf
 1000 thr=thr-thr2
      if(nset.ge.0) call rewftn(nfci)
      if(nset.ne.0) go to 32
      do 30 i=1,mxconf
      read (nfci,end=31) lie
c needed in older version ..  read (nfci,end=31,err=31) lie
   30 if(lie.eq.1000) nset=nset+1
   31 backspace nfci
      nset=nset+1
   32 if(nerr.gt.0.and.nproot.gt.0) 
     +               call dmrpwa(nfb,m0,ncsf,pthr,bb,iwr)
      call dmrwwf(nexp1,aa,title,nset,pthrcc,energy,iwr)
      if(.not.oprint(29)) write(iwr,8)
      nerr=nerr/2
      if(nerr.eq.0.and..not.oprint(29))  write(iwr, 9)
      if(nerr.ne.0) write(iwr,10) nerr
210   call rewftn(nfmain)
      call rewftn(nfci)
      call rewftn(nfmx)
      call rewftn(nfrsut)
      call rewftn(nfb)
      call rewftn(nfab)
      call rewftn(nfsc)
      call rewftn(nf11)
      cpu=cpulft(1)
      if(.not.oprint(29)) write(iwr,12)cpu
 12   format(/
     *' **** end of diagonalization at ',
     *f10.2,' secs.'/)
      return
    1 format(/1x,'intermediate diagonization results'/
     *        1x,'**********************************'/
     *        1x,'eigenvalues are shifted by',f14.7/
     *        1x,'diagonalization threshold is',f11.6)
    3 format(/1x,'no. of roots sought                   =',i4,/
     *        1x,'no. of extrapolation passes           =',i4,/
     *        1x,'no. of max diagonalization iterations =',i4,/
     *       1x,'intermediate diagonalization threshold =',f10.6,/
     *        1x,'*** final ** diagonalization threshold =',f10.6)
    5 format(' case :     ',10a8)
    6 format(/1x,'total number of configuration state functions =',i6)
    7 format(1x,'number of configuration state functions with ',/1x,
     *  'energy lowering effect of at least',f10.7,'  =',i6)
    8 format(/1x,104('*')//
     *43x,'***** end of ci diagonalization *****'//
     * /)
   9  format(//20x,90('*')/20x,'*',88x,'*'/20x,'*',88x,'*'/
     * 20x,'*',15x,
     *' *** ci diagonalisation has been successfully completed ***',
     *14x,'*'/20x,'*',88x,'*'/20x,90('*')/)
 10   format(//20x,90('*')/20x,'*',88x,'*'/20x,'*',88x,'*'/
     *20x,'*',20x,' *** warning: ',i2,
     *' roots did not fully converge ***',20x,'*'/
     *20x,'*',88x,'*'/
     *20x,90('*')/)
      end
_EXTRACT(dmrdp,hp800)
      subroutine dmrdp(thr,m0,aa,bb,ncsf,at,bt,nt,jwfv,iwfv,dia)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
c
c     this routine prepares trial vectors b and ab
c     for davidson's diagonization procedure (nt is ncsfo)
c
      common/file/ndhf,ndel
      common/ftape/nfb,nfab,nf11,nfrsut,nfsc,nfmx,
     * nspacf(6),nfmain,nfci,idum4(6)
      common/miscop/vmain(mxcsf*mxroot),atmx(mxcsf*(mxcsf+1)/2),
     +   escf,eci(mxroot,10),pthr,iovlp(mxroot),
     +   iwfm(mxcsf),nncsf,nocsf,nomain,nroot,ntry,kcsf(10),
     +   idum31(mxroot)
      common/scrtch/hmx(1600),id(1600),jd(1600)
      dimension aa(ncsf),bb(ncsf),at(nt),bt(nt),jwfv(ncsf),
     *          iwfv(ncsf), dia(ncsf)
      read (nfrsut) ncsfo,(iwfv(i),i=1,ncsfo)
      call rewftn(nfrsut)
      k=ncsfo
      j=ncsf
      do 200 i=1,ncsf
      if(j.gt.k) iwfv(j)=0
      if(k.eq.0) go to 200
      if(iwfv(k).ne.jwfv(j)) go to 200
      iwfv(j)=1
      k=k-1
  200 j=j-1
c.....construct b(i) vectors and parts of ab(i) vectors
      do 1000 n=1,m0
      j=ncsf
      k=ncsfo
      read (nfb ) bt
      read (nfab) at
      do 1100 i=1,ncsf
      if(j.eq.k) go to 10
      aa(j)=0.0d0
      bb(j)=0.0d0
      if(iwfv(j).eq.0) go to 1100
      if(k.le.0) go to 1100
      bb(j)=bb(k)
      aa(j)=aa(k)
      k=k-1
 1100 j=j-1
c.....complete ab(i) vectors
   10 k=0
      read (nfmx,end=20,err=20) nd,hmx,id,jd
      if(nd.eq.-999) go to 20
   11 k=k+1
      if(k.gt.nd) go to 10
      if(iwfv(id(k)).eq.iwfv(jd(k))) go to 11
      if(iwfv(id(k)).ne.0) aa(jd(k))=aa(jd(k))+hmx(k)*bb(id(k))
      if(iwfv(id(k)).eq.0) aa(id(k))=aa(id(k))+hmx(k)*bb(jd(k))
      go to 11
   20 call rewftn(nfmx)
      write (nfsc  ) bb
      write (nfrsut) aa
 1000 continue
      call rewftn(nfab)
      call rewftn(nfb)
      call rewftn(nfsc)
      call rewftn(nfrsut)
      n=nfab
      nfab=nfrsut
      nfrsut=n
      n=nfsc
      nfsc=nfb
      nfb=n
      write (nfrsut) ncsf,jwfv,thr
      read (nf11) dia
      call rewftn(nf11)
      return
      end
_ENDEXTRACT
      subroutine eigend(a,r,n)
      implicit REAL (a-h,o-z), integer (i-n)
      dimension a(*),r(*)
      r(1)=1.0d0
      if(n.eq.1) return
      fn=n
      n1=n+1
      n2=n*n
      do 10 i=2,n2
  10  r(i)=0.0d0
      ij=n+2
      do 20 i=2,n
      r(ij)=1.0d0
  20  ij=ij+n1
      n1=n-1
      thr=0.0d0
      ij=2
      do 35 i=2,n
      jm=i-1
      do 30 j=1,jm
      thr=thr+a(ij)*a(ij)
  30  ij=ij+1
  35  ij=ij+1
      if(thr.le.0.0d0) go to 165
      thr=2.0d0*dsqrt(thr)
      anrmx=thr*1.0d-6/fn
      ind=0
  45  thr=thr/fn
  50  l=1
      mq=1
      lq=0
      ilq=0
      imq=n
  55  m=l+1
  60  lm=l+mq
      if(dabs(a(lm)).lt.thr) go to 130
      ind=1
      ll=l+lq
      mm=m+mq
      x=0.5d0*(a(ll)-a(mm))
      y=-a(lm)/dsqrt(a(lm)*a(lm)+x*x)
      if(x.lt.0.0d0) y=-y
      sinx=y/dsqrt(2.0d0*(1.0d0+(dsqrt(1.0d0-y*y))))
      sinx2=sinx*sinx
      cosx=dsqrt(1.0d0-sinx2)
      cosx2=cosx*cosx
      sincs=sinx*cosx
      iq=0
      do 125 i=1,n
      if(i.eq.l.or.i.eq.m) go to 120
      if(i.gt.m) go to 90
      im=i+mq
      go to 95
  90  im=m+iq
  95  if(i.ge.l) go to 105
      il=i+lq
      go to 110
 105  il=l+iq
 110  x=a(il)*cosx-a(im)*sinx
      a(im)=(a(il)*sinx)+(a(im)*cosx)
      a(il)=x
 120  ilr=ilq+i
      imr=imq+i
      x=r(ilr)*cosx-r(imr)*sinx
      r(imr)=(r(ilr)*sinx)+(r(imr)*cosx)
      r(ilr)=x
 125  iq=iq+i
      x=2.0d0*a(lm)*sincs
      y=(a(ll)*cosx2)+(a(mm)*sinx2)-x
      x=(a(ll)*sinx2)+(a(mm)*cosx2)+x
      a(lm)=(a(ll)-a(mm))*sincs+a(lm)*(cosx2-sinx2)
      a(ll)=y
      a(mm)=x
 130  if(m.eq.n) go to 140
      mq=mq+m
      imq=imq+n
      m=m+1
      go to 60
 140  if(l.eq.n1) go to 150
      lq=lq+l
      ilq=ilq+n
      imq=ilq+n
      l=l+1
      mq=lq+l
      go to 55
 150  if(ind.ne.1) go to 160
      ind=0
      go to 50
 160  if(thr.gt.anrmx) go to 45
 165  iz=1
      ii=0
      do 200 i=1,n1
      ii=ii+i
      jj=ii
      x=a(ii)
      kz=0
      jp=i+1
      do 210 j=jp,n
      jj=jj+j
      if(a(jj).ge.a(ii)) go to 210
      a(ii)=a(jj)
      kz=j
      kk=jj
 210  continue
      if(kz.eq.0) iz=iz+n
      if(kz.eq.0) go to 200
      a(kk)=x
      kz=kz*n-n1
      do 220 k=1,n
      x=r(kz)
      r(kz)=r(iz)
      r(iz)=x
      kz=kz+1
 220  iz=iz+1
 200  continue
      return
      end
_EXTRACT(dmrd80,mips4)
      subroutine dmrd80(aa,iwfv,mxdim,thr1,thr2,m0,nsk,nexp,iwrite)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
c
c     this routine finds the ntry most important configurations,
c     diagonalize the matrix and writes out first trial vectors
c
      common/file/ndhf,ndel
INCLUDE(common/prints)
      common/ftape/nfb,nfab,nf11,nfrsut,nfsc,nfmx,
     * nspacf(6),nfmain,nfci,idum4(6)
      common/miscop/vmain(mxcsf*mxroot),atmx(mxcsf*(mxcsf+1)/2),
     +   escf,eci(mxroot,10),pthr,iovlp(mxroot),
     +   iwfm(mxcsf),ncsf,nocsf,nomain,nroot,ntry,kcsf(10),
     +   idum31(mxroot)
      common /scrtch/ jwfv(mxcsf),hmx(mxcrec),id(mxcrec),jd(mxcrec),
     + vec(mxcsf*mxcsf),save(mxroot,mxcsf),nconf(5),nytl(5),
_IF(cray,ksr,i8)
     + s(45689)
_ELSE
     + is(68589)
_ENDIF
      dimension sss(3),newya(255)
      dimension veig(mxcsf),scrap(mxcsf)
      dimension aa(mxdim),iwfv(mxdim)
      dimension vcrap(mxroot)
_IF(cray,ksr,i8)
      dimension ss(10)
      equivalence (s(1),ss(1),sss(1))
_ELSE
      dimension iss(10)
      equivalence (is(1),iss(1),sss(1))
_ENDIF
c
      max2 = mxcsf*(mxcsf+1)/2
c
c.....read main tape for information
c
_IF(cray,ksr,i8)
      read(nfmain,err=140,end=140)ndhf,x,escf,x,x,nconf,
     +   newya,nytl,ss,iswh,x,x,
     +   nomain,nrut,vmain,vcrap,s,ndel
_ELSE
      read(nfmain,err=140,end=140)ndhf,x,escf,ix,ix,nconf,
     +   newya,nytl,iss,iswh,
     +   ix,ix,nomain,nrut,vmain,vcrap,is,ndel
_ENDIF
      escf=escf-5.0d0
      if(nroot.eq.0) nroot=nrut
      if(nroot.gt.nrut) nroot=nrut
      nsk=3
      do 100 i=1,iswh
      if(nconf(i).eq.0) go to 100
      read (nfmain) ndum,kml
      nocsf=nocsf+nconf(i)*kml
      read (nfmain)
      nsk=nsk+2
  100 continue
      read (nfmain) sss,thr1,thr2,ist
      if(nexp.gt.10-ist) nexp=10-ist
      length=(nocsf-1)/ndel+1
      jmax=0
      do 200 i=1,length
      jmin=jmax+1
      jmax=jmax+ndel
      if(jmax.gt.nocsf) jmax=nocsf
      read (nfmain) (aa(j),j=jmin,jmax)
  200 continue
      write (nf11) aa
      call rewftn(nf11)
      read (nfmain)
      nsk=nsk+length
      do 1000 i=1,iswh
      nx=nytl(i)*nconf(i)
      if(nx.eq.0) go to 1000
      nx=nx/ndhf+1
      do 1100 j=1,nx
 1100 read (nfmain)
      nsk=nsk+nx
 1000 continue
c.....find ntry most important configurations
      if(nomain.gt.mxcsf) 
     + call caserr('too many CSF from main configurations')
      if(ntry.lt.nomain) ntry=nomain
      if(ntry.gt.nocsf)  ntry=nocsf
_IF1()      do 300 i=1,nocsf
_IF1()  300 iwfv(i)=0
      call setsto(nocsf,0,iwfv)
      do 2000 i=1,ntry
      temp=0.0d0
      do 2100 j=1,nocsf
      if(aa(j).lt.temp.or.aa(j).gt.955.0d0) go to 2100
      temp=aa(j)
      jj=j
 2100 continue
      aa(jj)=-aa(jj)
      iwfv(jj)=1
      if(i.le.nomain) iwfm(nomain-i+1)=jj
 2000 continue
      k=0
      do 400 i=1,nocsf
      if(iwfv(i).eq.0) go to 400
      k=k+1
      iwfv(i)=k
      jwfv(k)=i
  400 continue
      if(k.lt.ntry) ntry=k
      if(k.gt.ntry) call caserr('trial error in dmrd80')
      if(.not.oprint(29))
     +     write(iwrite,6) ntry,(jwfv(i),i=1,ntry)
c.....construct ntry*ntry matrix in atmx
   20 k=0
      read (nfmain) hmx,id,jd
      if(oprint(32)) call hprnt(hmx,id,jd,iwrite)
   21 k=k+1
      if(k.gt.ndhf) go to 20
      if(id(k).gt.0) go to 23
      if(jd(k).eq.0) go to 24
      if(iwfv(jd(k)).eq.0) go to 21
      i=iwfv(jd(k))*(iwfv(jd(k))+1)/2
   22 if(i.gt.max2) call caserr('atmx error in dmrd80')
      atmx(i)=hmx(k)
      go to 21
   23 if(iwfv(id(k)).eq.0.or.iwfv(jd(k)).eq.0) go to 21
      i=iwfv(id(k))*(iwfv(id(k))-1)/2+iwfv(jd(k))
      go to 22
   24 call rewftn(nfmain)
c.....diagonalize ntry*ntry matrix
c     call eigend(atmx,vec,ntry)
      call square(vec,atmx,ntry,ntry)
      if(oprint(32)) then
       write(iwrite,6240)
6240   format(//40x,'trial hamiltonian'/
     *          40x,'******************'/)
       call prsq(vec,ntry,ntry,ntry)
      endif
      call f02abf(vec,ntry,ntry,veig,vec,ntry,scrap,ifail)
      if(ifail.ne.0) write(iwrite,*)
     + ' f02abf: diag problems in dmrd80'
c .... print trial vectors
      if(oprint(32)) then
       write(iwrite,6200)
6200   format(//40x,'trial eigen vectors'/
     *         40x,'*******************'/)
       call prsq(vec,ntry,ntry,ntry)
       write(iwrite,6210)
6210   format(//40x,'trial eigen values'/
     *         40x,'******************'/)
       do 6230 loop=1,ntry
6230   scrap(loop)=veig(loop)+escf
       write(iwrite,6220)(scrap(loop),loop=1,ntry)
6220   format(/6x,12f9.5)
      endif
c.....check overlap between the reference and trial eigenvectors
      if(.not.oprint(29)) write(iwrite,3) ntry
      jjz=1
      do 3000 i=1,nroot
      kkk=0
      do 3100 j=1,ntry
      jj=jjz
      kk=1
      temp=0.0d0
      do 3110 k=1,ntry
      kkk=kkk+1
      if(jwfv(k).ne.iwfm(kk)) goto 3110
      temp=temp+vmain(jj)*vec(kkk)
      kk=kk+1
      jj=jj+1
 3110 continue
      save(i,j)=temp
 3100 continue
      if(.not.oprint(29)) write(iwrite,4) i,(save(i,j),j=1,ntry)
 3000 jjz=jj
      if(iovlp(1).eq.0) go to 50
      if(.not.oprint(29)) write(iwrite,5) (iovlp(i),i=1,nroot)
      k=1
      do 500 i=1,ntry
      if(i.ne.iovlp(k)) go to 49
      k=k+1
      go to 500
   49 do 510 j=1,nroot
  510 save(j,i)=0.0d0
  500 continue
   50 do 4000 k=1,nroot
      temp=0.0d0
      do 4100 i=1,nroot
      do 4110 j=1,ntry
      tt=dabs(save(i,j))
      if(tt.lt.temp) go to 4110
      temp=tt
      ii=i
      jj=j
 4110 continue
 4100 continue
      jd(jj)=-ii
      if(.not.oprint(29)) write(iwrite,1) ii,jj,temp
      do 4200 j=1,nroot
 4200 save(j,jj)=0.0d0
      do 4300 j=1,ntry
 4300 save(ii,j)=0.0d0
 4000 continue
      k=1
      do 600 j=1,ntry
      if(jd(j).gt.-1) go to 600
      iovlp(k)=j
      k=k+1
  600 continue
      m0=iovlp(nroot)
      if(.not.oprint(29)) write(iwrite,2) (i,i=1,m0)
c.....write trial vectors in nfab and nfb for dmrdp
      write (nfrsut) ntry,(jwfv(i),i=1,ntry),temp
      call rewftn(nfrsut)
      call vclr(atmx,1,m0*(m0+1)/2)
      ii=0
      imax=0
      do 5000 j=1,m0
      ii=ii+j
      imin=imax+1
      imax=imax+ntry
      write (nfb) (vec(i),i=imin,imax)
      atmx(ii)=veig(j)
_IF1()      do 5100 i=imin,imax
_IF1() 5100 vec(i)=atmx(ii)*vec(i)
      call dscal(imax-imin+1,veig(j),vec(imin),1)
      write (nfab) (vec(i),i=imin,imax)
 5000 continue
      call rewftn(nfb)
      call rewftn(nfab)
      return
 140  call caserr('error processing hamiltonian interface')
      return
    1 format(/1x,'main reference eigenvector no.',i3,
     + ' has max (or next max) overlap with trial eigenvector no.',
     +   i3,'   s =',f10.5)
    2 format(/1x,'The following trial vectors are used :'/
     *        1x,'======================================'/10x,20i4)
    3 format(/1x,'Dimension of trial eigenvectors  = ',i3//
     *1x,'overlap matrix between main ref csf and trial eigenvectors'/
     *1x,'========================================================='/)
    4 format(/6x,i2,2x,10f10.5/(10x,10f10.5))
    5 format(/1x,
     *'following specific trial eigenvectors are requested :'/
     * 10x,20i5)
    6 format(/1x,'The most important ',i3,' csf are:'/
     *        1x,'==============================='/
     *        (10x,20(1x,i5)) )
      end
_ENDEXTRACT
      subroutine dmrdfa(atmx,lword,aa,iwfv,mxdim,
     + thr1,thr2,nsk,nexp,pthrcc,nset,cutoff,mcut,energy,iwrite)
      implicit REAL (a-h,o-z), integer (i-n)
      character *8 zcomm,title
c
c     this routine aims to diagonalise the complete CI matrix
c
INCLUDE(common/sizes)
      common/junkc/zcomm(29),title(10)
      common/file/ndhf,ndel
INCLUDE(common/prints)
      common/ftape/nfb,nfab,nf11,nfrsut,nfsc,nfmx,
     * nspacf(6),nfmain,nfci,idum4(6)
      common/miscop/vmain(mxcsf*mxroot),dumx(mxcsf*(mxcsf+1)/2),
     + escf,eci(mxroot,10),pthr,iovlp(mxroot),
     + iwfm(mxcsf),ncsf,nocsf,nomain,nroot,ntry,kcsf(10),
     + idum31(mxroot)
      common /scrtch/jwfv(mxcsf),
     +        hmx(mxcrec),id(mxcrec),jd(mxcrec),
     +        save(mxroot,mxcsf),nconf(5),nytl(5),
_IF(cray,ksr,i8)
     +        s(45689)
_ELSE
     +       is(68589)
_ENDIF
      dimension atmx(lword),aa(mxdim),iwfv(mxdim)
      dimension vcrap(mxroot)
_IF(cray,ksr,i8)
      dimension ss(10),sss(3),newya(255)
      equivalence (s(1),ss(1),sss(1))
_ELSE
      dimension iss(10),sss(3),newya(255)
      equivalence (is(1),iss(1),sss(1))
_ENDIF
c
c.....read main tape for information
c
_IF(cray,ksr,i8)
      read (nfmain) ndhf,x,escf,x,x,nconf,newya,nytl,ss,iswh,x,x,
     *   nomain,nrut,vmain,vcrap,s,ndel
_ELSE
      read (nfmain) ndhf,x,escf,ix,ix,nconf,newya,nytl,iss,iswh,
     *   ix,ix,nomain,nrut,vmain,vcrap,is,ndel
_ENDIF
      escf=escf-5.0d0
      if(nroot.eq.0) nroot=nrut
      if(nroot.gt.nrut) nroot=nrut
      nsk=3
      do 100 i=1,iswh
      if(nconf(i).eq.0) go to 100
      read (nfmain) ndt,kml
      nocsf=nocsf+nconf(i)*kml
      read (nfmain)
      nsk=nsk+2
  100 continue
      write(iwrite,10000)title,nocsf
10000 format(/1x,
     * 'case : ',10a8/1x,
     * 'explicit diagonalisation requested'/1x,
     * 'total no. of csfs    ',i8)
      if(mcut.gt.0) then
       if(mcut.gt.1) then
        mcut=min(mcut,mxroot)
        write(iwrite,10100) mcut
10100   format(1x,'determine reference set for lowest ',i3,
     *  ' roots')
       else
        write(iwrite,10200) cutoff
10200   format(1x,'cutoff energy for reference determination',
     *  f10.2,' e.v.')
       endif
      endif
      read (nfmain) sss,thr1,thr2,ist
      if(nexp.gt.10-ist) nexp=10-ist
      length=(nocsf-1)/ndel+1
      jmax=0
      do 200 i=1,length
      jmin=jmax+1
      jmax=jmax+ndel
      if(jmax.gt.nocsf) jmax=nocsf
      read (nfmain) (aa(j),j=jmin,jmax)
  200 continue
      write (nf11) aa
      call rewftn(nf11)
      read (nfmain)
      nsk=nsk+length
      do 1000 i=1,iswh
      nx=nytl(i)*nconf(i)
      if(nx.eq.0) go to 1000
      nx=nx/ndhf+1
      do 1100 j=1,nx
 1100 read (nfmain)
      nsk=nsk+nx
 1000 continue
      ntry=nocsf
      nocsf2=nocsf*(nocsf+1)/2
c.....allocate core for diagonalising nocsf*nocsf matrix
      i10 = 1
      i20 = i10+nocsf2
      i30 = i20+nocsf*nocsf
      i40 = i30+nocsf
      last = i40+nocsf
      if(last.gt.lword)call caserr
     *('insufficient memory for explicit diagonalisation')
c.....find ntry most important configurations
      call vclr(atmx,1,nocsf2)
      if(ntry.lt.nomain) ntry=nomain
      if(ntry.gt.nocsf)  ntry=nocsf
      call setsto(nocsf,1,iwfv)
_IF1()c     do 2000 i=1,ntry
_IF1()c     temp=0.0e0
_IF1()c     do 2100 j=1,nocsf
_IF1()c     if(aa(j).lt.temp.or.aa(j).gt.955.0e0) go to 2100
_IF1()c     temp=aa(j)
_IF1()c     jj=j
_IF1()c2100 continue
_IF1()c     aa(jj)=-aa(jj)
_IF1()c     iwfv(jj)=1
_IF1()c     if(i.le.nomain) iwfm(nomain-i+1)=jj
_IF1()c2000 continue
      do 2000 i=1,nomain
2000  iwfm(i)=i
      k=0
      do 400 i=1,nocsf
      if(iwfv(i).eq.0) go to 400
      k=k+1
      iwfv(i)=k
c     jwfv(k)=i
  400 continue
      if(k.lt.ntry) ntry=k
c     write(iwrite,6) ntry,(jwfv(i),i=1,ntry)
c.....construct explicit nocsf*nocsf matrix in atmx
   20 k=0
      read (nfmain) hmx,id,jd
   21 k=k+1
      if(k.gt.ndhf) go to 20
      if(id(k).gt.0) go to 23
      if(jd(k).eq.0) go to 24
      if(iwfv(jd(k)).eq.0) go to 21
      i=iwfv(jd(k))*(iwfv(jd(k))+1)/2
   22 atmx(i)=hmx(k)
      go to 21
   23 if(iwfv(id(k)).eq.0.or.iwfv(jd(k)).eq.0) go to 21
      i=iwfv(id(k))*(iwfv(id(k))-1)/2+iwfv(jd(k))
      go to 22
   24 call rewftn(nfmain)
      call square(atmx(i20),atmx(i10),nocsf,nocsf)
      call f02abf(atmx(i20),nocsf,nocsf,atmx(i30),atmx(i20),
     *nocsf,atmx(i40),ifail)
c .... print trial vectors
      if(oprint(32)) then
      write(iwrite,6200)
6200  format(//40x,'****************'/
     *         40x,'Ci Eigen vectors'/
     *         40x,'****************'/)
      call prsq(atmx(i20),nocsf,nocsf,nocsf)
      endif
      write(iwrite,6210)
6210  format(//40x,'***************'/
     *         40x,'Ci Eigen values'/
     *         40x,'***************'/)
      do 6230 loop=1,nocsf
6230  atmx(i30+loop-1)=atmx(i30+loop-1)+escf
      energy = atmx(i30)
      write(iwrite,6220)(atmx(i30+loop-1),loop=1,nocsf)
6220  format(/6x,8f14.6)
      call rewftn(nfci)
      thr1=0.0d0
      call dmrwwa(aa,atmx(i20),atmx(i30),title,nset,pthrcc,nocsf,
     * cutoff,mcut,iwrite)
      return
      end
      subroutine dmrdc(aa,dia,jwfv,mxdim,thr,nsk)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
c
c     this routine construct a submatrix from files nfmain to nfmx
c     input energy lowering criteria in thr
c     the dimension of the submatrix is returned in ncsf
c
      common/file/ndhf,ndel
      common/ftape/nfb,nfab,nf11,nfrsut,nfsc,nfmx,
     * nspacf(6),nfmain,nfci,idum4(6)
      common/miscop/vmain(mxcsf*mxroot),atmx(mxcsf*(mxcsf+1)/2),
     +   escf, eci(mxroot,10),pthr,iovlp(mxroot),
     +   iwfm(mxcsf),ncsf,nocsf,nomain,nroot,ntry,kcsf(10),
     +   idum31(mxroot)
      common/scrtch/hmx(mxcrec),id(mxcrec),jd(mxcrec),
     + hmxp(1600),iid(1600),jjd(1600)
      dimension aa(mxdim),dia(mxdim),jwfv(mxdim)
      data m999 /-999/
c
      do 20 i=1,nsk
   20 read (nfmain)
      read (nf11) aa
      ncsf=0
      do 100 i=1,nocsf
      jwfv(i)=0
      if(aa(i).lt.thr) go to 100
      ncsf=ncsf+1
      jwfv(i)=ncsf
  100 continue
      l=0
   10 k=0
      read (nfmain) hmx,id,jd
   11 k=k+1
      if(k.gt.ndhf) go to 10
      if(id(k).gt.0) go to 12
      if(jd(k).eq.0) go to 13
      if(jwfv( jd(k)).ne.0) dia(jwfv( jd(k)))=hmx(k)
      go to 11
   12 if(jwfv(id(k)).eq.0.or.jwfv(jd(k)).eq.0) go to 11
      l=l+1
      iid(l)=jwfv(id(k))
      jjd(l)=jwfv(jd(k))
      hmxp(l)=hmx(k)
      if(l.ne.1600) go to 11
      write (nfmx) l,hmxp,iid,jjd
      l=0
      go to 11
   13 call rewftn(nfmain)
      if(l.ne.0) write (nfmx) l,hmxp,iid,jjd
      write (nfmx) m999,hmxp,iid,jjd
c     end file nfmx
      call rewftn(nfmx)
      write (nf11) dia
c problem on rs6000
c      backspace nf11
      call rewftn(nf11)
      read(nf11)
      k=1
      do 50 i=1,nocsf
      if(jwfv(i).eq.0) go to 50
      jwfv(k)=i
      if(k.eq.ncsf) return
      k=k+1
   50 continue
      return
      end
      subroutine dmrdm(nfa,nfb,m0,mdim,aa,bb,vec,ncsf)
      implicit REAL (a-h,o-z), integer (i-n)
c
c     this routine finds better approximate starting vectors from
c     eigenvectors of a tilt matrix
c     input data from nfa   output data in nfb
c
      dimension aa(ncsf),bb(ncsf),vec(*)
      ij=1
      do 1000 m=1,m0
      read (nfa) aa
_IF1()      do 1100 i=1,ncsf
_IF1() 1100 aa(i)=vec(ij)*aa(i)
      call dscal(ncsf,vec(ij),aa,1)
      ij=ij+1
      do 1200 mm=2,mdim
      read (nfa) bb
_IF(cray)
      do i=1,ncsf
       aa(i)=aa(i)+vec(ij)*bb(i)
      enddo
_ELSE
      call daxpy(ncsf,vec(ij),bb,1,aa,1)
_ENDIF
 1200 ij=ij+1
      call rewftn(nfa)
 1000 write (nfb) aa
      call rewftn(nfb)
      m=nfb
      nfb=nfa
      nfa=m
      return
      end
      subroutine dmrpwa(nfb,m0,ncsf,pthr,bb,iwrite)
      implicit REAL (a-h,o-z), integer (i-n)
c     this routine prints all intermediate ci wave functions
      dimension bb(ncsf)
      write(iwrite,11)
      do 2000 i=1,m0
      write(iwrite,12) i
      read (nfb) bb
      do 2100 j=1,ncsf
 2100 if(dabs(bb(j)).gt.pthr) write(iwrite,13) j,bb(j)
 2000 continue
      call rewftn(nfb)
      return
  11   format(//1x,104('*')//1x,
     *'***** all roots treated in final ci *****')
   12 format(/6x,'root no.',i3,':    csf no.    coefficient'/1x,
     * 43('=')/)
   13 format(23x,i5,5x,f8.5)
      end
_EXTRACT(drmdd,hp800)
      subroutine drmdd(aa,bb,dia,ndvec,atp,vec,kth,thr,mdim,
     +                 atmx,mxtri,maxit,ifxx,core,lword,iwrite,*)
c
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/prints)
c
c     this routine uses davidson's method to extract the k-th root of
c     a large real symmetric matrix
c     see j. computational physics vol. 17, p.95 (1975)
c
c     nfmx fortran file no. for hmx,i,j
c     nfb  fortran file no. for b1,b2,.....bm
c     nfab fortran file no. for ab1,ab2,.....abm
c     resulting eigenvector is returned in bb
c     max dimension of a tilt matrix is  mxzero at the present time
c     to enlarge it change the dimensions of atp and vec
c     storage for vec and (hmx,ind,jnd) can be shared if necessary
c
      dimension aa(ndvec),bb(ndvec),dia(ndvec),atmx(mxtri),
     +          atp(*),vec(*),core(lword)
      dimension eig(mxcsf),scrap(mxcsf)
      common /file/ ndhf,ndel
      common/ftape/nfb,nfab,nf11,nfrsut,nfsc,nfmx,
     * nspacf(6),nfmain,nfci,idum4(6)
      common/miscop/vmain(mxcsf*mxroot),dumx(mxcsf*(mxcsf+1)/2),
     +eshift
      common/scrtch/hmx(1600),ind(1600),jnd(1600)
c
c.....step a:  diagonalize a tilt matrix
c
      it=0
      kc=kth
      mtri=mdim*(mdim+1)/2
      if(.not.oprint(29)) write(iwrite,3)
 20   continue
_IF1()      do 21 i=1,mtri
_IF1()   21 atp(i)=atmx(i)
c     call eigend(atp,vec,mdim)
      call dcopy(mtri,atmx,1,atp,1)
      call square(vec,atp,mdim,mdim)
      call f02abf(vec,mdim,mdim,eig,vec,mdim,scrap,ifail)
      if(ifail.ne.0) write(iwrite,*)
     + ' f02abf: diag problems in drmdd'
      ii=0
      do 350 i=1,mdim
      ii=ii+i
 350  atp(ii)=eig(i)
c.....pick up the root which has the right structure for extrapolation
      coef=0.0d0
      if(ifxx.gt.0) go to 22
      j=kc
      do 100 i=1,mdim
      if(dabs(vec(j)).le.coef) go to 100
      coef=dabs(vec(j))
      kth=i
  100 j=j+mdim
   22 continue
      kk=kth*(kth+1)/2
      ikz=(kth-1)*mdim
c
c.....step b: form q vectors in aa
c
c...  Possible Jacobi Davidson
c
      call gdvdtb(mdim,ndvec,nfb,nfab,aa,dia,bb,
     1            vec(ikz+1),atp(kk),ncyc,temp,core,lword)
c
       if (ncyc.gt.0) go to  801
c
_IF1()      do 200 i=1,ndvec
_IF1()  200 aa(i)=0.0
      call vclr(aa,1,ndvec)
      do 2000 m=1,mdim
      read (nfab) bb
_IF(cray)
      temp=vec(ikz+m)
      do 2000 i=1,ndvec
 2000 aa(i)=aa(i)+temp*bb(i)
_ELSE
 2000 call daxpy(ndvec,vec(ikz+m),bb,1,aa,1)
_ENDIF
      do 3000 m=1,mdim
      read (nfb) bb
_IF(cray)
      temp=vec(ikz+m)*atp(kk)
      do 3000 i=1,ndvec
 3000 aa(i)=aa(i)-temp*bb(i)
_ELSE
 3000 call daxpy(ndvec,-vec(ikz+m)*atp(kk),bb,1,aa,1)
_ENDIF
      call rewftn(nfb)
c
c.....step c: check convergence
c
_IF1()     temp=0.0
_IF1()     do 300 i=1,ndvec
_IF1() 300 temp=temp+aa(i)*aa(i)
_IF1()     temp=dsqrt(temp)
      temp=dnrm2(ndvec,aa,1)
c
c.....step d:  form ksi in aa
c
      do 800 k=1,ndvec
  800 aa(k)=aa(k)/(atp(kk)-dia(k))
c
c...  we jump to here for jacobi - davidson
c
 801  cpu=cpulft(1)
      edum=atp(kk)+eshift
      if(.not.oprint(29)) 
     +  write(iwrite,2) it,mdim,edum,temp,kth,coef,cpu
      if(temp.lt.thr) go to 71
c
c.....step e:  form d(m+1)
c
      do 4000 m=1,mdim
      read (nfb) bb
_IF1()      temp=0.0
_IF1()      do 4100 n=1,ndvec
_IF1() 4100 temp=temp+bb(n)*aa(n)
      temp=-ddot(ndvec,bb,1,aa,1)
_IF(cray)
      do 4200 n=1,ndvec
 4200 aa(n)=aa(n)+temp*bb(n)
_ELSE
      call daxpy(ndvec,temp,bb,1,aa,1)
_ENDIF
 4000 continue
c
c.....step f:  normalize d(m+1)=b(m+1) in aa
c
_IF1()      temp=0.0
_IF1()      do 400 n=1,ndvec
_IF1()  400 temp=temp+aa(n)*aa(n)
_IF1()      temp=1.0d0/dsqrt(temp)
_IF1()      do 500 n=1,ndvec
_IF1()  500 aa(n)=aa(n)*temp
      temp=1.0d0/dnrm2(ndvec,aa,1)
      call dscal(ndvec,temp,aa,1)
      write (nfb) aa
      call rewftn(nfb)
c
c.....step g:  form ab(m+1) in bb
c
_IF1()      do 600 n=1,ndvec
_IF1()  600 bb(n)=0.0
      call vclr(bb,1,ndvec)
   40 k=0
      read (nfmx,end=60,err=60) nd,hmx,ind,jnd
   41 k=k+1
      if(k.gt.nd) go to 40
      bb(jnd(k))=bb(jnd(k))+hmx(k)*aa(ind(k))
      bb(ind(k))=bb(ind(k))+hmx(k)*aa(jnd(k))
      go to 41
   60 call rewftn(nfmx)
      do 61 k=1,ndvec
   61 bb(k)=bb(k)+dia(k)*aa(k)
      write (nfab) bb
      call rewftn(nfab)
c
c.....step h:  form a tilt matrix (i,m+1)
c
      mdim=mdim+1
      if(mdim.gt.maxit) go to 70
      do 5000 m=1,mdim
      read (nfb) aa
      mtri=mtri+1
_IF1()      atmx(mtri)=0.0
_IF1()      do 5000 i=1,ndvec
_IF1() 5000 atmx(mtri)=atmx(mtri)+aa(i)*bb(i)
 5000 atmx(mtri)=ddot(ndvec,aa,1,bb,1)
      call rewftn(nfb)
      it=it+1
      go to 20
c     obtain resulting eigenvector in bb
   70 mdim=maxit
      kc=-1
   71 call rewftn(nfab)
_IF1()      do 700 i=1,ndvec
_IF1()  700 bb(i)=0.0
      call vclr(bb,1,ndvec)
      do 6000 i=1,mdim
      read (nfb) aa
_IF(cray)
      temp=vec(ikz+i)
      do 6100 j=1,ndvec
 6100 bb(j)=bb(j)+temp*aa(j)
_ELSE
      call daxpy(ndvec,vec(ikz+i),aa,1,bb,1)
_ENDIF
 6000 continue
      call rewftn(nfb)
      write (nfrsut) kth,atp(kk),bb
      if(kc.gt.0) return 1
      write(iwrite,1) it,maxit
      call rewftn(nfab)
      return
    1 format(//
     + ' ***** diagonalization fails to converge within',i4,
     + ' iteration allowed at the present time ***** (maxit=',
     + i3,' )')
    2 format(15x,i5,2x,i5,3x,f14.6,f16.7,i7,4x,f10.4,f10.1)
    3 format(//
     + 15x,'iteration  dimens  eigenvalue',6x,'vec. cor.   root no.',
     + '    weight      time (secs.)'/15x,76('=')/)
      end
_ENDEXTRACT
      subroutine dmrpwf(aa,deng,jwfv,ax,bx,iwrite)
      implicit REAL (a-h,o-z), integer (i-n)
      character *11 tag11
INCLUDE(common/sizes)
INCLUDE(common/prints)
c
c     this routine prints the resulting wave functions
c
      common/file/ndhf,ndel
      common/ftape/nfb,nfab,nf11,nfrsut,nfsc,nfmx,
     * nspacf(6),nfmain,nfci,idum4(6)
      common/miscop/vmain(mxcsf*mxroot),atmx(mxcsf*(mxcsf+1)/2),
     + escf, eci(mxroot,10),pthr,iovlp(mxroot),
     + iwfm(mxcsf),ncsf,nocsf,nomain,nroot,ntry,kcsf(10),
     + iper(mxroot)
      common/scrtch/temp(mxroot),ovlp(mxroot,mxroot),kth(mxroot)
      dimension deng(*),jwfv(ncsf),ax(ncsf),bx(ncsf),aa(*)
c
      data tag11/'==========='/
      do 300 i=1,nroot
      do 300 j=1,nroot
  300 ovlp(j,i)=0.0d0
      read (nfrsut) ncsf,jwfv,thr
      call rewftn(nfrsut)
      if(.not.oprint(29)) write(iwrite,5) pthr
      k=1
      do 100 i=1,ncsf
      if(iwfm(k).ne.jwfv(i)) go to 100
      k=k+1
      jwfv(i)=-jwfv(i)
  100 continue
      nl=mxconf/nroot
      if(nl.gt.ncsf) nl=ncsf
      npass=(ncsf-1)/nl+1
      kmz=1
      nskip=0
      do 1000 n=1,npass
      read (nfrsut)
      imax=0
      do 1100 nn=1,nroot
      imin=imax+1
      imax=imax+nl
      if(nskip.ne.0) go to 10
      read (nfrsut) kth(nn),deng(nn),(aa(i),i=imin,imax)
      deng(nn)=deng(nn)+escf
      go to 1100
   10 read (nfrsut) i,eng,(dp,i=1,nskip),(aa(i),i=imin,imax)
 1100 continue
      call rewftn(nfrsut)
      if(n.eq.1.and..not.oprint(29)) then
       write(iwrite,1) (kth (nn),nn=1,nroot)
       write(iwrite,2) (deng(nn),nn=1,nroot)
       write(iwrite,222)(tag11,nn=1,nroot)
      endif
      kz=1
      imin=nskip+1
      imax=nskip+nl
      do 1200 i=imin,imax
      if(jwfv(i).gt.0) go to 30
      k=kz
      do 1220 nn=1,nroot
      km=kmz
      do 1221 mm=1,nroot
      ovlp(nn,mm)=ovlp(nn,mm)+aa(k)*vmain(km)
 1221 km=km+nomain
 1220 k=k+nl
      kmz=kmz+1
   30 k=kz
      nchek=0
      do 1210 nn=1,nroot
      if(jwfv(i).lt.0) go to 31
      temp(nn)=0.0d0
      if(dabs(aa(k)).lt.pthr) go to 1210
   31 temp(nn)=aa(k)
      nchek=1
 1210 k=k+nl
      if(nchek.eq.0) go to 1200
      nchek=jwfv(i)
      k=iabs(nchek)
      if(.not.oprint(29)) then
       if(nchek.ge.0) write(iwrite,3) k,(temp(nn),nn=1,nroot)
       if(nchek.lt.0) write(iwrite,4) k,(temp(nn),nn=1,nroot)
      endif
 1200 kz=kz+1
      nskip=nskip+nl
 1000 if(nskip+nl.gt.ncsf) nl=ncsf-nskip
      if(.not.oprint(29)) then
c .... print overlap matrix between ci vectors and main csf
       write(iwrite,6200)
6200   format(/10x,'Ci-vector / Main-csf overlap matrix'/
     *          10x,'***********************************')
       call prsq(ovlp,nroot,nroot,mxroot)
      endif
c
      do 400 n=1,nroot
      x=0.0d0
      do 410 i=1,nroot
      if(dabs(ovlp(n,i)).lt.x) go to 410
      x=dabs(ovlp(n,i))
      iper(n)=i
  410 continue
  400 continue
      if(nroot.eq.1) return
      lie=nroot-1
      call vclr(ovlp,1,mxroot*mxroot)
      ovlp(nroot,nroot)=1.0d0
      do 2000 i=1,lie
      ovlp(i,i)=1.0d0
      call rewftn(nfrsut)
      do 2100 j=1,i
 2100 read (nfrsut)
      read (nfrsut) k,tempk,ax
      n=i+1
      do 2200 j=n,nroot
      read (nfrsut) k,tempk,bx
_IF1()      ovlp(i,j)=0.0
_IF1()      do 2210 k=1,ncsf
_IF1() 2210 ovlp(i,j)=ovlp(i,j)+ax(k)*bx(k)
      ovlp(i,j) = ddot(ncsf,ax,1,bx,1)
      ovlp(j,i) = ovlp(i,j)
 2200 continue
 2000 continue
      call rewftn(nfrsut)
      if(.not.oprint(29)) then
       write(iwrite,6210)
6210   format(//10x,'Root Overlap Matrix'/
     *          10x,'*******************')
       call prsq(ovlp,nroot,nroot,mxroot)
      endif
    1 format(5x,' root no. ',10(3x,i5,3x)/15x,10(3x,i5,3x))
    2 format(5x,'eigenvalue',10f11.4/15x,10f11.4)
  222 format(15x,10a11/15x,10a11)
    3 format(4x,i6,5x,10(f11.5   )/15x,10(f11.5))
    4 format(4x,i6,'m',4x,10(f11.5)/15x,10(f11.5))
    5 format(/1x,'Resulting wave functions : (0.0 means the contri',
     *'bution of that csf is less than the print threshold',f8.4,')'/)
      return
      end
_EXTRACT(dmrwwf,hp800)
_IF(hpux11)
c$HP$ OPTIMIZE ASSUME_NO_PARAMETERS_OVERLAPS OFF
_ENDIF
      subroutine dmrwwf(nexp,vx,title,nset,pthrcc,energy,iwrite)
      implicit REAL (a-h,o-z), integer (i-n)
      character *8 title
INCLUDE(common/sizes)
c
      common/file/ndhf,ndel
      common/ftape/nfb,nfab,nf11,nfrsut,nfsc,nfmx,
     * nspacf(6),nfmain,nfci,idum4(6)
      common/miscop/vmain(mxcsf*mxroot),atmx(mxcsf*(mxcsf+1)/2),
     + escf,eci(mxroot,10),pthr,iovlp(mxroot),
     * iwfm(mxcsf),ncsf,nocsf,nomain,nroot,ntry,kcsf(10),
     * iper(mxroot)
_IF(cray,ksr,i8)
      common/scrtch/ia(5),ib(10),id(45690),ie(9723),
     + ic(mxcsf*mxroot+2),
_ELSE
      common/scrtch/ia(7),ispa,ib(10),id(68590),ie(15588),
     + ic((mxcsf+mxcsf)*mxroot+2),
_ENDIF
     + a(5292),e(2304),f(mxcrec),h(100),g(500),
     + ft(mxcrec),gt(mxcrc2),ht(100),ex(mxroot),ew(mxroot),
     + trsum(mxroot,10),
     + t1(10),t2(10),t3(10),t4(10),t5(10),xl(mxroot),
     + nconf(5),ihog(48),imap(504),jkan(mxcrec),kkan(mxcrc2),nytl(5)
      dimension xx(5),ttt(10*mxroot),newya(255)
      equivalence (ic(1),xx(1),ttt(1))
      dimension vx(nocsf),title(10)
      data ijrk/100/
      read (nfmain) ia,nconf,newya,nytl,ib,iswh,iq,jq,ic,ew,id,kq,ie
      do 100 i=1,iswh
      if(nconf(i).eq.0) go to 100
      read (nfmain) ndt,kml,a
      write (nfmx)  ndt,kml,a
      read (nfmain) ihog,imap,e
      write (nfmx)  imap,ihog,e
  100 continue
      call rewftn(nfmx)
      read (nfmain) xx,ist
      n=(nocsf-1)/ndel+1
      do 200 i=1,n
  200 read (nfmain)
      k=nroot*10
      read (nfmain) (ttt(i),i=1,k)
      kz=ist+nexp-1
      do 1000 i=1,nroot
      k=kz+(iper(i)-1)*10
      do 1100 j=1,nexp
      trsum(i,j)=ttt(k)
 1100 k=k-1
 1000 continue
      if(nexp.gt.1) go to 40
      do 30 i=1,nroot
   30 ex(i)=eci(i,1)
      go to 41
   40 nex=nexp-1
      do 300 i=1,nroot
      if ( trsum(i,nex) .eq. trsum(i,nexp)) then
      ex(i) = eci(i,nexp)
       else
      xl(i)=(eci(i,nex)-eci(i,nexp))/(trsum(i,nex)-trsum(i,nexp))
      ex(i)=eci(i,nexp)-trsum(i,nexp)*xl(i)
      endif
 300  continue
 41   if(nset.gt.0) write(nfci) ia,nconf,newya,
     *nytl,ib,iswh,iq,jq,kq,id,ie,ex
      do 400 i=1,iswh
      nx=nytl(i)*nconf(i)
      if(nx.eq.0) go to 400
      nx=nx/ndhf+1
      do 410 j=1,nx
      read (nfmain) jkan
  410 write (nf11)  jkan
  400 continue
      call rewftn(nfmain)
      call rewftn(nf11)
      read (nfrsut)
      do 10000 i=1,nroot
      write(iwrite,19) title
      read (nfrsut) lie,xdum,vx
      if(nexp.gt.1) go to 42
      write(iwrite,20) lie,nocsf
      tt=0.0d0
      go to 43
   42 write(iwrite,9) lie,iper(i)
      x1=xl(i)+0.05d0
      x2=xl(i)-0.05d0
      do 500 k=1,nexp
      t1(k)=eci(i,k)-trsum(i,k)
      t2(k)=eci(i,k)-trsum(i,k)*0.5d0
      t3(k)=eci(i,k)-trsum(i,k)*x1
      t4(k)=eci(i,k)-trsum(i,k)*x2
  500 t5(k)=eci(i,k)-trsum(i,k)*xl(i)
      write(iwrite,21) (kcsf(k),k=1,nexp)
      write(iwrite,10) (trsum(i,k),k=1,nexp)
      write(iwrite,11) (eci  (i,k),k=1,nexp)
      write(iwrite,12) (t1(k),k=1,nexp)
      write(iwrite,13) (t2(k),k=1,nexp)
      write(iwrite,14) xl(i)
      write(iwrite,15) (t3(k),k=1,nexp)
      write(iwrite,16) (t4(k),k=1,nexp)
      write(iwrite,17) (t5(k),k=1,nexp)
      tt=trsum(i,nexp)*xl(i)*0.05d0
   43 write(iwrite,18) ex(i),tt
      if=0
      ig=0
      ih=0
      nm=0
      do 11000 j=1,iswh
      if (nconf(j).eq.0) go to 11000
      read (nfmx) nd,kml,a
      read (nfmx) imap,ihog,e
      nc=nconf(j)
      do 11100 k=1,nc
      do 11110 l=1,nd
      if=if+1
      f(if)=0.0d0
      mm=nm
      lx=l-nd
      do 11111 ll=1,kml
      lx=lx+nd
      mm=mm+1
11111 f(if)=f(if)+vx(mm)*a(lx)
      if (if.lt.ndhf) go to 11110
      write (nfb) f
      if=0
11110 continue
      do 11120 l=1,kml
      ig=ig+1
      g(ig)=0.0d0
      mm=nm
      lx=l-kml
      do 11121 ll=1,kml
      lx=lx+kml
      mm=mm+1
11121 g(ig)=g(ig)+vx(mm)*e(lx)
      if (ig.lt.ndel) go to 11120
      write(nfab) g
      ig=0
11120 continue
      ih=ih+1
      h(ih)=0.0d0
      do 11130 l=1,kml
      nm=nm+1
11130 h(ih)=h(ih)+vx(nm)*vx(nm)
      if (ih.lt.ijrk) go to 11100
      write (nfsc) h
      ih=0
11100 continue
11000 continue
      call rewftn(nfmx)
      write (nfsc) h
      write (nfab) g
      write (nfb) f
      call rewftn(nfb)
      call rewftn(nfab)
      call rewftn(nfsc)
      read (nfsc) h
      ih=0
      read (nfab) g
      ig=0
      read (nfb) f
      if=0
      write(iwrite,1)
      dumy=0.0d0
      idumy=1
      ihous=1
      idumx=iwfm(1)
      do 12000 j=1,iswh
      nc=nconf(j)
      if (nc.eq.0) go to 12000
      nl=nytl(j)
      read (nfmx) ndt,kml
      read (nfmx) imap,ihog
      l1=ndel/nl
      l2=ndhf/ndt
      l3=ndel/kml
      imax=min(ijrk,l1,l2,l3)
      nhb=(nc-1)/imax+1
      if(nset.gt.0) write (nfci) nhb,imax,ndt,kml,imap,ihog,ex(i)
      nres=nc-(nhb-1)*imax
      read (nf11) jkan
      nx=0
      nxl=imax*nl
      igl=imax*kml
      ifl=imax*ndt
      do 12100 k=1,nhb
      if (k.lt.nhb) go to 50
      nxl=nres*nl
      igl=nres*kml
      ifl=nres*ndt
      imax=nres
   50 do 12110 l=1,nxl
      nx=nx+1
      kkan(l)=jkan(nx)
      if (nx.lt.ndhf) go to 12110
      nx=0
      read (nf11) jkan
12110 continue
      do 12120 l=1,imax
      ih=ih+1
      hf=h(ih)
      ipt=-1
      if(hf.gt.pthrcc) ipt=1
      ist=idumy
      if (idumy.ne.idumx) go to 70
      ipt=2
      dumy=dumy+hf
      ihous=ihous+kml
      if (ihous.le.nomain) idumx=iwfm(ihous)
   70 idumy=idumy+kml
      if(ipt.lt.0) go to 80
      iend=idumy-1
      ibc=(l-1)*nl
      ibb=ibc+1
      ibc=ibc+nl
      if(ipt.eq.1) write(iwrite,3) ist,iend,hf,(kkan(ixy),ixy=ibb,ibc)
      if(ipt.gt.1) write(iwrite,2) ist,iend,hf,(kkan(ixy),ixy=ibb,ibc)
   80 ht(l)=hf
      if (ih.lt.ijrk) go to 12120
      ih=0
      read (nfsc) h
12120 continue
      do 12130 l=1,igl
      ig=ig+1
      gt(l)=g(ig)
      if (ig.lt.ndel) go to 12130
      ig=0
      read (nfab) g
12130 continue
      do 12140 l=1,ifl
      if=if+1
      ft(l)=f(if)
      if (if.lt.ndhf) go to 12140
      if=0
      read (nfb) f
12140 continue
12100 if(nset.gt.0) write (nfci) kkan,ft,gt,ht
12000 continue
      call rewftn(nfb)
      call rewftn(nfab)
      call rewftn(nfsc)
      call rewftn(nfmx)
      call rewftn(nf11)
      if(nset.gt.0) write(iwrite,4) nset,nfci
      if(nset.gt.0) nset=nset+1
      write(iwrite,5) dumy
      dumx=ex(i)-ew(iper(i))-escf-5.0d0
      dumz=(1.0d0-dumy)*dumx
      dumw=ex(i)+dumz
      write(iwrite,6) dumx
      write(iwrite,7) dumz
      write(iwrite,8) dumw
10000 continue
      energy = ex(nroot)
      if(nset.gt.0) endfile nfci
      if(nset.gt.0) call rewftn(nfci)
      call rewftn(nfrsut)
      return
    1 format(//7x,49('=')   /11x,'csf no.',15x,'c*c',7x,
     *  'configuration'/7x,49('=')/)
    2 format(9x,'(',i6,'-',i6,')','m',f15.8,2x,20i4)
    3 format(9x,'(',i6,'-',i6,')',1x, f15.8,2x,20i4)
    4 format(/7x,'***** ci wave function written on set',i3,' of ft'
     * ,i2,'f001 *****')
    5 format(/6x,'sum of main reference c*c =',f11.8/)
    6 format(6x,'mrd-ci energy lowering relative to main csf =',f12.8/)
    7 format(6x,'full ci correction estimated relative to mrd-ci = '
     *,f12.8)
    8 format(/6x,'estimated full ci energy for this root =',f16.8)
    9 format(/1x,'final root no. ',i3,/' extrapolation based on main ref
     *erence csf no. ',i3)
   10 format(6x,'energy lowering',8f13.6,/21x,8f13.6)
   11 format(6x,    'mrd-ci energy  ',8f13.6,/21x,8f13.6)
   12 format(6x,'at lambda=1.0  ',8f13.6,/21x,8f13.6)
   13 format(6x,    'at lambda=0.5  ',8f13.6,/21x,8f13.6)
   14 format(/16x,'optimum lambda = ',f12.6)
   15 format(/6x,'at l opt + 0.05',8f13.6,/21x,8f13.6)
   16 format(6x,    'at l opt - 0.05',8f13.6,/21x,8f13.6)
   17 format(6x,    'at l optimum   ',8f13.6,/21x,8f13.6)
   18 format(/6x,'extrapolated total energy = ',f13.7,'+/-',f9.7)
   19 format(//1x,104('*')//
     *'extrapolation results for   ',10a8)
   20 format(/1x,'final root no.',i3,/' no extrapolation requested',
     * /' total no. of csf =',i6)
   21 format(/6x,'no. of csf =   ',8i13,/21x,8i13)
      end
_IF(hpux11)
c$HP$ OPTIMIZE ASSUME_NO_PARAMETERS_OVERLAPS ON
_ENDIF
_ENDEXTRACT
      subroutine dmrwwa(vx,civec,eci,title,nset,pthrcc,nocsf,
     * cutoff,mcut,iwrite)
      implicit REAL (a-h,o-z), integer (i-n)
      logical oflag,ocut
      character *8 title
INCLUDE(common/sizes)
c
      common/file/ndhf,ndel
      common/ftape/nfb,nfab,nf11,nfrsut,nfsc,nfmx,
     * nspacf(6),nfmain,nfci,idum4(6)
      common/miscop/vmain(mxcsf*mxroot),atmx(mxcsf*(mxcsf+1)/2),
     + escf,dci(mxroot,10),pthr,iovlp(mxroot),
     + iwfm(mxcsf),ncsf,ndum,nomain,nroot,ntry,kcsf(10),
     + iper(mxroot)
_IF(cray,ksr,i8)
      common/scrtch/ia(5),ib(10),id(45690),ie(9723),
     + ic(mxcsf*mxroot+2),
_ELSE
      common/scrtch/ia(7),ispa,ib(10),id(68590),ie(15588),
     + ic((mxcsf+mxcsf)*mxroot+2),
_ENDIF
     + a(5292),e(2304),f(mxcrec),h(100),g(500),
     + ft(mxcrec),gt(mxcrc2),ht(100),ex(mxroot),ew(mxroot),
     + trsum(mxroot,10),
     + t1(10),t2(10),t3(10),t4(10),t5(10),xl(mxroot),
     + nconf(5),ihog(48),imap(504),jkan(mxcrec),kkan(mxcrc2),nytl(5)
     + ,ikeep(100),jkeep(100),ckeep(100),kkeep(100,40)
     + ,label(mxroot),labeli(mxroot),labelj(mxroot,40)
      dimension  xx(5),ttt(10*mxroot),newya(255),eci(*)
      equivalence (ic(1),xx(1),ttt(1))
      dimension vx(nocsf),title(10),civec(nocsf,*)
      data ijrk/100/
c
      ocut=.true.
      if(mcut.lt.1) then
       ocut=.false.
      else if(mcut.gt.1) then
       mcut = min(nocsf,mcut)
       cutoff=(eci(mcut)-eci(1))*27.21d0
       write(iwrite,30000)mcut,cutoff
30000 format(/1x,
     *' effective cutoff energy for ',i2,' mains selection = ',
     * f10.2,' e.v.')
      else
       dum=cutoff/27.21d0
       emin=eci(1)+dum
       do 30010 loop=1,nocsf
       if(emin.lt.eci(loop)) go to 30020
30010  continue
       write(iwrite,30040)
30040  format(' cutoff leads to zero states!')
       ocut=.false.
       go to 30050
30020  mcut=loop
       write(iwrite,30030)cutoff,mcut
30030  format(/1x,
     * 'cutoff energy of ',f10.2,' e.v. leads to ',i2,
     * ' states for main selection analysis')
      endif
30050 read (nfmain) ia,nconf,newya,nytl,ib,iswh,iq,jq,ic,ew,id,kq,ie
      do 100 i=1,iswh
      if(nconf(i).eq.0) go to 100
      read (nfmain) ndt,kml,a
      write (nfmx)  ndt,kml,a
      read (nfmain) ihog,imap,e
      write (nfmx)  imap,ihog,e
  100 continue
      call rewftn(nfmx)
      read (nfmain) xx,ist
      n=(nocsf-1)/ndel+1
      do 200 i=1,n
  200 read (nfmain)
      read (nfmain)
      mdum = min(nocsf,mxroot)
      mcut = min(mcut,mdum)
      do 30 i=1,mdum
   30 ex(i)=eci(i)
      if(nset.gt.0) write(nfci) ia,nconf,newya,
     *nytl,ib,iswh,iq,jq,kq,id,ie,ex
      do 400 i=1,iswh
      nx=nytl(i)*nconf(i)
      if(nx.eq.0) go to 400
      nx=nx/ndhf+1
      do 410 j=1,nx
      read (nfmain) jkan
  410 write (nf11)  jkan
  400 continue
      call rewftn(nfmain)
      call rewftn(nf11)
      do 10000 i=1,mdum
      oflag=.false.
      write(iwrite,19) title
      call dcopy(nocsf,civec(1,i),1,vx,1)
      write(iwrite,20) i,nocsf
      write(iwrite,8) eci(i)
      if=0
      ig=0
      ih=0
      nm=0
      do 11000 j=1,iswh
      if (nconf(j).eq.0) go to 11000
      read (nfmx) nd,kml,a
      read (nfmx) imap,ihog,e
      nc=nconf(j)
      do 11100 k=1,nc
      do 11110 l=1,nd
      if=if+1
      f(if)=0.0d0
      mm=nm
      lx=l-nd
      do 11111 ll=1,kml
      lx=lx+nd
      mm=mm+1
11111 f(if)=f(if)+vx(mm)*a(lx)
      if (if.lt.ndhf) go to 11110
      write (nfb) f
      if=0
11110 continue
      do 11120 l=1,kml
      ig=ig+1
      g(ig)=0.0d0
      mm=nm
      lx=l-kml
      do 11121 ll=1,kml
      lx=lx+kml
      mm=mm+1
11121 g(ig)=g(ig)+vx(mm)*e(lx)
      if (ig.lt.ndel) go to 11120
      write(nfab) g
      ig=0
11120 continue
      ih=ih+1
      h(ih)=0.0d0
      do 11130 l=1,kml
      nm=nm+1
11130 h(ih)=h(ih)+vx(nm)*vx(nm)
      if (ih.lt.ijrk) go to 11100
      write (nfsc) h
      ih=0
11100 continue
11000 continue
      call rewftn(nfmx)
      write (nfsc) h
      write (nfab) g
      write (nfb) f
      call rewftn(nfb)
      call rewftn(nfab)
      call rewftn(nfsc)
      read (nfsc) h
      ih=0
      read (nfab) g
      ig=0
      read (nfb) f
      if=0
      write(iwrite,1)
      dumy=0.0d0
      idumy=1
      ihous=1
      idumx=iwfm(1)
      icount=0
      do 12000 j=1,iswh
      nc=nconf(j)
      if (nc.eq.0) go to 12000
      nl=nytl(j)
      read (nfmx) ndt,kml
      read (nfmx) imap,ihog
      l1=ndel/nl
      l2=ndhf/ndt
      l3=ndel/kml
      imax=min(ijrk,l1,l2,l3)
      nhb=(nc-1)/imax+1
      if(nset.gt.0) write (nfci) nhb,imax,ndt,kml,imap,ihog,ex(i)
      nres=nc-(nhb-1)*imax
      read (nf11) jkan
      nx=0
      nxl=imax*nl
      igl=imax*kml
      ifl=imax*ndt
      do 12100 k=1,nhb
      if (k.lt.nhb) go to 50
      nxl=nres*nl
      igl=nres*kml
      ifl=nres*ndt
      imax=nres
   50 do 12110 l=1,nxl
      nx=nx+1
      kkan(l)=jkan(nx)
      if (nx.lt.ndhf) go to 12110
      nx=0
      read (nf11) jkan
12110 continue
      do 12120 l=1,imax
      ih=ih+1
      hf=h(ih)
      ipt=-1
      if(hf.gt.pthrcc) ipt=1
      ist=idumy
      if (idumy.ne.idumx) go to 70
      ipt=2
      dumy=dumy+hf
      ihous=ihous+kml
      if (ihous.le.nomain) idumx=iwfm(ihous)
   70 idumy=idumy+kml
      if(ipt.lt.0) go to 80
      iend=idumy-1
      ibc=(l-1)*nl
      ibb=ibc+1
      ibc=ibc+nl
      if(ipt.ne.0) then
       icount=icount+1
       ikeep(icount)=ist
       jkeep(icount)=nl
       ckeep(icount)=hf
       do 25000 loop=1,nl
       loop1=ibb+loop-1
25000  kkeep(icount,loop)=kkan(loop1)
      endif
      if(ipt.eq.1) write(iwrite,3) ist,iend,hf,(kkan(ixy),ixy=ibb,ibc)
      if(ipt.gt.1) write(iwrite,2) ist,iend,hf,(kkan(ixy),ixy=ibb,ibc)
   80 ht(l)=hf
      if (ih.lt.ijrk) go to 12120
      ih=0
      read (nfsc) h
12120 continue
      do 12130 l=1,igl
      ig=ig+1
      gt(l)=g(ig)
      if (ig.lt.ndel) go to 12130
      ig=0
      read (nfab) g
12130 continue
      do 12140 l=1,ifl
      if=if+1
      ft(l)=f(if)
      if (if.lt.ndhf) go to 12140
      if=0
      read (nfb) f
12140 continue
12100 if(nset.gt.0) write (nfci) kkan,ft,gt,ht
12000 continue
      if(ocut) then
c
c store information for final dominant terms
c
      loop=idamax(icount,ckeep,1)
      if(ckeep(loop).le.0.2d0) then
      write(iwrite,23100)i,ckeep(loop)
23100 format(1x,'root : ',i3,
     * ' beginning to incorporate terms less than ', f10.2)
      endif
      if(i.ne.1) then
22000   moop=locat1(label,i-1,ikeep(loop))
        if(moop.ne.0) then
        ckeep(loop)=0.0d0
        loop=idamax(icount,ckeep,1)
        if(.not.oflag.and.ckeep(loop).le.0.2d0) then
        write(iwrite,23100)i,ckeep(loop)
        oflag=.true.
        endif
        go to 22000
        endif
      endif
      label(i)=ikeep(loop)
      nnl = jkeep(loop)
      labeli(i)= nnl
      do 22100 moop=1,nnl
22100 labelj(i,moop)=kkeep(loop,moop)
      endif
      call rewftn(nfb)
      call rewftn(nfab)
      call rewftn(nfsc)
      call rewftn(nfmx)
      call rewftn(nf11)
      if(nset.gt.0) write(iwrite,4) nset,nfci
      if(nset.gt.0) nset=nset+1
10000 continue
      if(nset.gt.0) endfile nfci
      if(nset.gt.0) call rewftn(nfci)
      call rewftn(nfrsut)
      if(ocut) then
       write(iwrite,7)mcut
7      format(/1x,
     * '****************************'/1x,
     * 'Final CONF data for ',i2,' roots'/1x,
     * '****************************'/)
       do 23000 loop=1,mcut
       nterm = labeli(loop)
       write(iwrite,24000)(labelj(loop,i),i=1,nterm)
24000  format(1x,20i4)
23000  continue
       write(iwrite,9)
9      format(1x,
     *  '****************************'/)
      endif
      return
    1 format(//7x,49('=')   /15x,'csf no.',11x,'c*c',7x,
     *  'configuration'/7x,49('=')/)
    2 format(9x,'(',i6,'-',i6,')','m',f15.8,2x,20i3)
    3 format(9x,'(',i6,'-',i6,')',1x, f15.8,2x,20i3)
    4 format(/7x,'***** ci wave function written on set',i3,' of ft'
     * ,i2,'f001 *****')
   19 format(//1x,104('*')//
     *'Final analysis for ',10a8)
   20 format(/1x,'final root no.',i3,/' no extrapolation requested',
     * /' total no. of csf =',i6)
    8 format(/6x,'Ci energy for this root =',f16.8)
      end
      subroutine hprnt(hmx,id,jd,iwrite)
      implicit REAL (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
      dimension hmx(mxcrec),id(mxcrec),jd(mxcrec)
      common/blkin/ham(mxcrec),ih(mxcrec),jh(mxcrec)
      save irec,ifirst
      data ifirst/0/
      data thresh /0.0001d0/
c
      if(ifirst.eq.0) then
       ifirst = 1
       irec = 0
      endif
      irec = irec + 1
      write(iwrite,10) irec
 10   format(' hamiltonian matrix record',i10)
      ii = 0
      do 20 loop =1,mxcrec
      if(id(loop).gt.0) go to 30
      if(jd(loop).eq.0) go to 40
 30   if(dabs(hmx(loop)).gt.thresh) then
        ii = ii + 1
       ih(ii) = id(loop)
       jh(ii) = jd(loop)
       ham(ii) = hmx(loop)
      endif
 20   continue
 40   if(ii.gt.0) then
      write(iwrite,50) (ih(i),jh(i),ham(i), i=1,ii)
 50   format(5(1x,2i5,f9.4))
      endif
      return
      end
      subroutine ver_mrdci7(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mrdci7.m,v $
     +     "/
      data revision /"$Revision: 6141 $"/
      data date /"$Date: 2010-07-15 00:46:22 +0200 (Thu, 15 Jul 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
