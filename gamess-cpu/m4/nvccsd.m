      subroutine advec2(a,b,n,fac)
      implicit integer(a-z)
      REAL a(n),b(n),fac
      do 10 i = 1,n
      a(i) =  a(i) + b(i)*fac
   10 continue
      return
      end
      subroutine ampltd(buf,ibuf,t2,tau,t1o,t1n,e,fpbka,fpbkb,fpbkc,
     1                  fpbkd1,fpbkd2,fpbkd3,fpbke1,fpbkf,
     2                  npr,ioff,itriv,itrio,isqvv,isqoo,isqov,ifa,
     3                  ifb,ifc,ifd1,ifd2,ifd3,ifd4,ife1,iff,flov,
     4                  fsec,isqvo,ifa2,ioovvt,ivvoot,ivooot,iooovt,
     5                  ioovv,ivvoo,ivooo,iooov,ntr,w1,w2,escf,
     6                  cc,bb,bb2,eccsd,iopt)
      implicit integer (a-z)
c
      integer ibuf(*),fpbka(nbka),fpbkb(nbkb),fpbkc(nbkc),
     1        fpbkd1(nbkd1),fpbkd2(nbkd2),fpbkd3(nbkd3),fpbke1(nbke1),
     2        fpbkf(nbkf),npr(nirred,3,2),ioff(nbf),itriv(ntriv),
     3        itrio(ntrio),isqvv(nsqvv),isqoo(nsqoo),isqov(nsqov),
     4        ifa(nirred),ifb(nirred),ifc(nirred),ifd1(nirred),
     5        ifd2(nirred),ifd3(nirred),ife1(nirred)
      integer iff(nirred),ifd4(nirred),flov(nirred,4),fsec(nlist)
      integer isqvo(nsqov),ifa2(nirred),ioovvt(nirred),ivvoot(nirred)
      integer ivooot(nirred),iooovt(nirred),ioovv(nirred,nirred)
      integer ivvoo(nirred,nirred),ivooo(nirred,nirred)
      integer iooov(nirred,nirred),ntr(nirred,4)
      REAL buf(lnbkt),t2(ndimw),tau(ndimw),t1o(ndimt1),t1n(ndimt1)
      REAL e(nbf),w1(nsqvv),w2(nsqvv),cc(maxdim),bb(maxdim+1,maxdim+2)
      REAL bb2(maxdim+1,maxdim+2)
      REAL a0,ap5,a1,conv,xeo,xe,a2,escf,eccsd,eccsd2,rms
      REAL test
      REAL anmt1,anmt2
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
INCLUDE(common/t_iter)
INCLUDE(common/prnprn)
c
      data a0,ap5,a1,a2 /0.0d0,0.5d0,1.0d0,2.0d0/
c
      icray = 1
      itc = 0
      nit = 0
      conv = 10.d0**(-convi)
      xeo = a0
      xe = escf
      it = 0
c
c  read in initial values of t2 and t1 (set up in ccsort)
c
ctjl  call rfile(itap69)
      call srew(itap69)
      call tit_sread(itap69,t1o,intowp(ndimt1))
      call rgetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
      call vclr(t1n,1,ndimt1)
c
c     start iterative procedure
c
      write(iw,3000)
 3000 format(//1x,'iter',2x,'correlation',5x,'extrapolated',7x,
     1      'rms',10x,'norm t1',8x,'norm t2',/,
     1      6x,             '   energy  ',6x,'   energy   ',/)
 2000 format(i3,2f16.10,3d15.6)
c
c
c
cqci  qcisd option
      qci = 0
      if(iopt.eq.5.or.iopt.eq.6) qci = 1
cqci  qcisd option
c
      rms = a1
c
 1000 continue
      nit=nit+1
 9000 format(/)
ctjl  call timit(1,6)
c
c  test for convergence
c
ctjl  if(dabs(xeo-xe).lt.conv) then
      if(rms.lt.conv) then
      write(iw,9020) conv
 9020 format(///,32('*'),/,'* t1 & t2 amplitudes converged *',3x,d12.2,
     . /,32('*'))
c
c  print out final t1 and t2 if desired
c
      if (odebug(33)) then
        if(ndimt2.lt.100) then
        write(iw,9000)
        write(iw,*)  '    t1 '
        call matout(t1n,1,ndimt1,1,ndimt1)
        write(iw,9000)
        write(iw,*)  '    t2 '
        call matout(tau,1,ndimt2,1,ndimt2)
        end if
      endif
c
      anmt1 = anmt1/dsqrt(dfloat(no+no))
      write(iw,1414) anmt1
 1414 format(//,5x,'final value of the t1 diagnostic = ',f10.5,/)
c
      return
      end if
c
c  test on number of iterations used
c
      if(nit.ge.maxit) then
      write(iw,9030)
 9030 format(///,'iterations exhausted & did not converge',///)
      return
      end if
c
c
      itjl = 1
c
c  b integral contribution to t2
c
cttt  call vclr(t2,1,ndimw)
copt long dot products (=0) or long accumulation vectors (=1)
      if(icray.eq.0) then
cqci
      if(qci.eq.1) then
      call vclr(w1,1,ndimt1)
      call extau1(tau,t2,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,ifd4,w1,
     1            isqov)
      else
      call extau1(tau,t2,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,ifd4,t1o,
     1            isqov)
      end if
      call vclr(tau,1,ndimw)
      if(odebug(33)) then
       write(iw,*) '    t2  before b integrals '
       call matout(t2,1,ndimw,1,ndimw)
       call dotpr(t2,t2,ndimw,test)
       write(*,*) ' t2*t2 = ',test
      endif
c
      call srew(itap61)
      ibkb = 0
      off2 = 1
      off3 = 1
      nbg = 1
c
      do 10 bgsym = 1,nirred
      lnab = npr(bgsym,2,2)
c
      if(lnab.ne.0) then
      add2 = 0
      numbg = npr(bgsym,2,1)
c
   20 if(nbg.eq.fpbkb(ibkb+1)) then
      call tit_sread(itap61,buf,intowp(lnbkt))
      off1 = 1
      ibkb = ibkb + 1
      fbg = fpbkb(ibkb)
      if(ibkb.eq.nbkb) then
      lbg = ntriv
      else
      lbg = fpbkb(ibkb+1) - 1
      end if
      end if
c
      lnbg = lbg - nbg + 1
      if(lnbg.gt.numbg) lnbg = numbg
      lnuv = npr(bgsym,1,2)
c
      if(lnuv.ne.0) then
      adt2 = off2 + add2*lnuv
      call mxmb(t2(off3),1,lnuv,buf(off1),1,lnab,tau(adt2),1,lnuv,
     1          lnuv,lnab,lnbg)
_IF1()c      call dgemm('n','n',lnuv,lnbg,lnab,a1,t2(off3),lnuv,buf(off1),
_IF1()c     1           lnab,a1,tau(adt2),lnuv)
      add2 = add2 + lnbg
      end if
c
      off1 = off1 + lnbg*lnab
      nbg = nbg + lnbg
      numbg = numbg - lnbg
      if(numbg.ne.0) go to 20
c
      off3 = off3 + lnab*lnuv
      off2 = off2 + lnuv*npr(bgsym,2,1)
      end if
c
   10 continue
      call srew(itap90)
      call swrit(itap90,tau,intowp(ndimt2))
      call rgetsa(itap90,endt2)
cttt  write(iw,*) ' endt2 ',endt2
copt
      else
copt
cqci
      if(qci.eq.1) then
      call vclr(w1,1,ndimt1)
      call ext23(tau,t2,itriv,isqoo,npr,flov,ifd2,w1,isqov)
      else
      call ext23(tau,t2,itriv,isqoo,npr,flov,ifd2,t1o,isqov)
      end if
c      call dotpr(t2,t2,ndimt2,test)
c      write(*,*) '  dot after ext23 = ',test
      call vclr(tau,1,ndimw)
c
      call srew(itap61)
      ibkb = 0
      off2 = 1
      nab = 1
c      write(*,*) '  nbkb = ',nbkb
c
      do 11 absym = 1,nirred
      off3 = off2
      lnbg = npr(absym,2,2)
      adt2 = ifd4(absym) + 1
c
      if(lnbg.ne.0) then
      numab = npr(absym,2,1)
      mxab = numab
c
   21 if(nab.eq.fpbkb(ibkb+1)) then
      call tit_sread(itap61,buf,intowp(lnbkt))
      off1 = 1
      ibkb = ibkb + 1
      if(ibkb.eq.nbkb) then
      lab = ntriv
      else
      lab = fpbkb(ibkb+1) - 1
      end if
      end if
c
      lnab = lab - nab + 1
      if(lnab.gt.numab) lnab = numab
      lnuv = npr(absym,1,2)
c
      if(lnuv.ne.0) then
      call mxmb(buf(off1),1,lnbg,t2(off3),1,mxab,tau(adt2),1,lnbg,
     1          lnbg,lnab,lnuv)
_IF1()c      write(*,*) ' adt2,off1,off3 = ',adt2,off1,off3
_IF1()c      call dgemm('n','n',lnbg,lnuv,lnab,a1,buf(off1),lnbg,t2(off3),
_IF1()c     1           mxab,a1,tau(adt2),lnbg)
      end if
c
      off3 = off3 + lnab 
      off2 = off2 + lnab*lnuv
      off1 = off1 + lnbg*lnab
      nab = nab + lnab
      numab = numab - lnab
      if(numab.ne.0) go to 21
c
      end if
c
   11 continue
c      write(*,*) ' after 11: adt2,off1,off3 = ',adt2,off1,off3
c
c  must fold answer and then write out
c
c      call dotpr(tau,tau,ndimw,test)
c      write(*,*) '  dot before fltau3 = ',test
      call fltau3(tau,t2,isqoo,isqvv,npr,flov,ifd4)
c      call dotpr(t2,t2,ndimt2,test)
c      write(*,*) '  dot after fltau3 = ',test
      call srew(itap90)
      call swrit(itap90,t2,intowp(ndimt2))
      call rgetsa(itap90,endt2)
cttt  write(iw,*) ' endt2 ',endt2
      end if
copt
c
c  d integral contribution : form d2a first
c
c  form full (2*t(vjgab)-t(vjbga)) and store as t(jb,vga)
c  this is done in extau4
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
c
      call extau4(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
ctjl  call matout(t2,1,ndimw,1,ndimw)
      call vclr(tau,1,ndimw)
cttt  write(iw,*)  '    t2 beginning d1 integrals: d2a part '
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
cttt  if(itjl.eq.0) stop
c
      call srew(itap63)
      ibkd1 = 0
      off2 = 0
      off3 = 1
      nbeu = 1
c
      do 90 beusym = 1,nirred
      lnjb = npr(beusym,3,2)
c
      if(lnjb.ne.0) then
      add2 = 1
      numbeu = lnjb
c
  100 if(nbeu.eq.fpbkd1(ibkd1+1)) then
      call tit_sread(itap63,buf,intowp(lnbkt))
      off1 = 1
      ibkd1 = ibkd1 + 1
      fbeu = fpbkd1(ibkd1)
      if(ibkd1.eq.nbkd1) then
      lbeu = nsqov
      else
      lbeu = fpbkd1(ibkd1+1) - 1
      end if
      if(odebug(33)) then
       test = a0
       do 1119 ijkli = 1,lnbkt
       test = test + dabs(buf(ijkli))
 1119 continue
       write(*,*) ' fbeu,lbeu,ibkd1,test = ',fbeu,lbeu,ibkd1,test
      endif
      end if
c
      lnbeu = lbeu - nbeu + 1
      if(lnbeu.gt.numbeu) lnbeu = numbeu
      lngav = lnjb
      adt2 = off2 + add2
      call mxmb(t2(off3),1,lnjb,buf(off1),1,lnjb,tau(adt2),lnjb,1,
     1          lngav,lnjb,lnbeu)
_IF1()c      call dgemm('t','t',lnbeu,lngav,lnjb,a1,buf(off1),lnjb,t2(off3),
_IF1()c     1           lnjb,a1,tau(adt2),lnjb)
      add2 = add2 + lnbeu
      off1 = off1 + lnbeu*lnjb
      nbeu = nbeu + lnbeu
      numbeu = numbeu - lnbeu
      if(numbeu.ne.0) go to 100
c
      off3 = off3 + lnjb*lngav
      off2 = off2 + lnjb*lngav
      end if
c
   90 continue
c
c  write d2a out for later use, fold it over and add direct
c  contribution to t2; work file is itap90
c
      call rsetsa(itap90,endt2)
      call swrit(itap90,tau,intowp(ndimw))
c
      call fltau1(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
      call srew(itap90)
      call tit_sread(itap90,tau,intowp(ndimt2))
      call vadd(t2,1,tau,1,t2,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,t2,intowp(ndimt2))
c
      if(odebug(33)) then
       write(iw,*)  '    t2 after d2a  '
       call matout(t2,1,ndimt2,1,ndimt2)
       call dotpr(t2,t2,ndimt2,test)
       write(*,*) ' t2*t2 = ',test
      endif
c
c  form d2b
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
c
      call extau2(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
ctjl  call matout(t2,1,ndimw,1,ndimw)
      call vclr(tau,1,ndimw)
      if(odebug(33)) then
       write(iw,*)  '    t2 beginning d2 integrals: d2b part '
       call dotpr(t2,t2,ndimw,test)
       write(*,*) ' t2*t2 = ',test
      endif
c
      call rsetsa(itap63,fsec(5))
      ibkd2 = 0
      off2 = 0
      off3 = 1
      nia = 1
c
      do 110 iasym = 1,nirred
      lnjb = npr(iasym,3,2)
c
      if(lnjb.ne.0) then
      add2 = 1
      numia = lnjb
c
  120 if(nia.eq.fpbkd2(ibkd2+1)) then
      call tit_sread(itap63,buf,intowp(lnbkt))
      off1 = 1
      ibkd2 = ibkd2 + 1
      fia = fpbkd2(ibkd2)
      if(ibkd2.eq.nbkd2) then
      lia = nsqov
      else
      lia = fpbkd2(ibkd2+1) - 1
      end if
      end if
c
      lnia = lia - nia + 1
      if(lnia.gt.numia) lnia = numia
      lngav = lnjb
      adt2 = off2 + add2
      call mxmb(t2(off3),1,lnjb,buf(off1),1,lnjb,tau(adt2),lnjb,1,
     1          lngav,lnjb,lnia)
_IF1()c      call dgemm('t','t',lnia,lngav,lnjb,a1,buf(off1),lnjb,t2(off3),
_IF1()c     1           lnjb,a1,tau(adt2),lnjb)
      add2 = add2 + lnia
      off1 = off1 + lnia*lnjb
      nia = nia + lnia
      numia = numia - lnia
      if(numia.ne.0) go to 120
c
      off3 = off3 + lnjb*lngav
      off2 = off2 + lnjb*lngav
      end if
c
  110 continue
c
c  read d2a (into t2) and form (d2a - d2b);
c  write this out on top of d2a on file 90
c  form (d2a-d2b)t contribution to t1
c
      call rsetsa(itap90,endt2)
      call tit_sread(itap90,t2,intowp(ndimw))
      call vsub(t2,1,tau,1,t2,1,ndimw)
      call rsetsa(itap90,endt2)
      call swrit(itap90,t2,intowp(ndimw))
c
      call vclr(tau,1,ndimw)
      call vclr(w1,1,ndimt1)
c
c  form (d2a-d2b) contribution to t1
c
      lnia = npr(1,3,2)
      call mxmb(t2,lnia,1,t1o,1,lnia,w1,1,lnia,
     &          lnia,lnia,1)
_IF1()c      call dgemm('t','n',lnia,1,lnia,a1,t2,lnia,t1o,
_IF1()c     &           lnia,a1,w1,lnia)
cttt  call dotpr(w1,w1,ndimt1,test)
cttt  write(6,*) ' t1 after d2a-d2b contrubution ',test
      call sbvec2(t1n,w1,ndimt1,a2)
c
c  sort d2a-d2b for t1*t1 contribution to t2
c  and multiply by t1o(i,a)
c
cqci
      if(qci.ne.1) then
c
      call srt22(t2,tau,isqoo,ntr,flov,ivvoo,ivvoot)
      call vclr(t2,1,ndimw)
      off1 = 1
      off2 = 1
      off3 = 1
      do 700 asym = 1,nirred
      lni = flov(asym,2) - flov(asym,1) + 1
      lna = flov(asym,4) - flov(asym,3) + 1
      lngiv = ntr(asym,2)
      if(lna.ne.0.and.lni.ne.0) then
      call mxmb(tau(off1),1,lngiv,t1o(off2),lni,1,t2(off3),1,lngiv,
     1          lngiv,lna,lni)
_IF1()c      call dgemm('n','t',lngiv,lni,lna,a1,tau(off1),lngiv,t1o(off2),
_IF1()c     1           lni,a1,t2(off3),lngiv)
      end if
      off2 = off2 + lni*lna
      off1 = off1 + lna*lngiv
      off3 = off3 + lni*lngiv
  700 continue
c
      call srt23(t2,tau,isqoo,ntr,flov,iooov,iooovt)
      call vclr(t2,1,ndimw)
      off1 = 1
      off2 = 1
      off3 = 1
      do 701 isym = 1,nirred
      lni = flov(isym,2) - flov(isym,1) + 1
      lnbe = flov(isym,4) - flov(isym,3) + 1
      lngvu = ntr(isym,2)
      if(lni.ne.0.and.lnbe.ne.0) then
      call mxmb(tau(off1),1,lngvu,t1o(off2),1,lni,t2(off3),1,lngvu,
     1          lngvu,lni,lnbe)
_IF1()c      call dgemm('n','n',lngvu,lnbe,lni,a1,tau(off1),lngvu,t1o(off2),
_IF1()c     1           lni,a1,t2(off3),lngvu)
      end if
      off2 = off2 + lni*lnbe
      off1 = off1 + lni*lngvu
      off3 = off3 + lnbe*lngvu
  701 continue
c
c  fold [d2a-d2b]*t1*t1 contribution and subtract from t2
c
      call flt22(tau,t2,ioff,itriv,isqoo,npr,flov,ifd2,ivvoo,
     1           ivvoot,ntr)
      call srew(itap90)
      call tit_sread(itap90,t2,intowp(ndimt2))
      call vsub(t2,1,tau,1,t2,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,t2,intowp(ndimt2))
c
      end if
c
      if(odebug(33)) then
       write(iw,*)  '    t2 after d2a-d2b*t1*t1 '
       call matout(tau,1,ndimt2,1,ndimt2)
       call dotpr(tau,tau,ndimt2,test)
       write(*,*) ' test = ',test
      endif
c
c  make f12 and form [d2a-d2b+2f12] and add direct contribution to t2
c
      call vclr(t2,1,ndimw)
      call mkf12(t2,buf,ioff,itriv,isqov,npr,flov,ifc,fpbkf,t1o,isqvv)
      if(odebug(33)) then
       call dotpr(t2,t2,ndimw,test)
       write(6,*) ' t2 after mkf12 construction ',test
      endif
c
cqci
      if(qci.ne.1) then
c
      call rsetsa(itap90,endt2)
      call tit_sread(itap90,tau,intowp(ndimw))
      call advec2(tau,t2,ndimw,a2)
      call rsetsa(itap90,endt2)
      call swrit(itap90,tau,intowp(ndimw))
c
      end if
c
c  add direct contribution of f12 into t2
c
      call vclr(tau,1,ndimw)
      call fltau1(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
      if(odebug(33)) then
       write(iw,*)  '    t2 after f12 integrals '
       call matout(tau,1,ndimt2,1,ndimt2)
       call dotpr(tau,tau,ndimt2,test)
       write(*,*) ' test = ',test
      endif
      call srew(itap90)
      call tit_sread(itap90,t2,intowp(ndimt2))
      call vadd(t2,1,tau,1,t2,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,t2,intowp(ndimt2))
c
c  form e1*
c
      call gte1s(t2,buf,isqoo,npr,flov,iooov,iooovt,fpbke1,ntr)
      call vclr(tau,1,ndimw)
c
cttt  write(*,*) ' before e1s: t1o = ',t1o
      off1 = 1
      off2 = 1
      off3 = 1
      do 600 isym = 1,nirred
      lni = flov(isym,2) - flov(isym,1) + 1
      lnbuv = ntr(isym,2)
      lnga = flov(isym,4) - flov(isym,3) + 1
      if(lni.ne.0.and.lnga.ne.0) then
      call mxmb(t2(off1),1,lnbuv,t1o(off2),1,lni,tau(off3),1,lnbuv,
     1          lnbuv,lni,lnga)
_IF1()c      call dgemm('n','n',lnbuv,lnga,lni,a1,t2(off1),lnbuv,t1o(off2),
_IF1()c     1           lni,a1,tau(off3),lnbuv)
      end if
      off3 = off3 + lnga*lnbuv
      off2 = off2 + lni*lnga
      off1 = off1 + lni*lnbuv
  600 continue
c
cttt  write(iw,*)  '    e1* before srte1s: off3,ndimw = ',off3,ndimw
ctjl  call matout(tau,1,ndimw,1,ndimw)
ctjl  call dotpr(tau,tau,ndimw,test)
cttt  write(*,*) ' test = ',test
      call vclr(t2,1,ndimw)
      call srte1s(tau,t2,isqov,npr,flov,ifc)
cttt  write(iw,*)  '    t2 after srte1s '
ctjl  call matout(t2,1,ndimw,1,ndimw)
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' test = ',test
c
c  read in [d2a-d2b+2f12] and subtract 2[e1*]
c
c9998 continue
      call rsetsa(itap90,endt2)
      call tit_sread(itap90,tau,intowp(ndimw))
cqci
      if(qci.ne.1) then
c
      call sbvec2(tau,t2,ndimw,a2)
c
      end if
c
c  write [d2a-d2b+2f12-2e1*] like the d1 integral list
c
      call rsetsa(itap90,endt2)
      ibkd1 = 1
      liajb = 0
      off1 = 1
      lnbuf = lnbkt
      nia = 0
      do 130 iasym = 1,nirred
      lnia = npr(iasym,3,2)
      numia = lnia
  140 lia = nia + numia
      if(ibkd1.ne.nbkd1) then
      if(lia.ge.(fpbkd1(ibkd1+1)-1)) then
      ibkd1 = ibkd1 + 1
      mia = fpbkd1(ibkd1) - nia - 1
      liajb = liajb + mia*lnia
      nia = fpbkd1(ibkd1) - 1
      numia = numia - mia
      call swrit(itap90,tau(off1),intowp(lnbuf))
      off1 = off1 + liajb
      liajb = 0
      go to 140
      end if
      end if
      nia = lia
      liajb = liajb + numia*lnia
  130 continue
c
c  write out the last bucket
c
      call swrit(itap90,tau(off1),intowp(liajb))
cttt  write(*,*)' bucket of (d2a-d2b): ndimw,liajb = ',ndimw,liajb
      lastb = liajb
c
c  add [e1*] direct contribution into t2
c
      call fltau1(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
      if(odebug(33)) then
       write(iw,*)  '    t2 e1s direct contribution '
       call matout(tau,1,ndimt2,1,ndimt2)
       call dotpr(tau,tau,ndimt2,test)
       write(*,*) ' test = ',test
      endif
      call srew(itap90)
      call tit_sread(itap90,t2,intowp(ndimt2))
      call vsub(t2,1,tau,1,t2,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,t2,intowp(ndimt2))
      if(odebug(33)) then
       call dotpr(t2,t2,ndimt2,test)
       write(6,*) ' t2 after e1* direct contribution ',test
      endif
c
c  now form [t2(i,u,a<be)-0.5*t2(u,i,a<be)]
c  and store as t2(i,a,u,be)
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
c
      call extau5(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
ctjl  call matout(t2,1,ndimw,1,ndimw)
      call vclr(tau,1,ndimw)
      if(odebug(33)) then
       write(iw,*)  '    t2 beginning d2 integrals: (d2a - d2b) part '
       call dotpr(t2,t2,ndimw,test)
       write(*,*) ' t2*t2 = ',test
      endif
c
      call vclr(w1,1,ndimt1)
      call rsetsa(itap90,endt2)
      ibkd1 = 0
      off2 = 1
      off3 = 1
      nbeu = 1
      adt1 = 1
      lnbuf = lnbkt
c
      do 150 beusym = 1,nirred
      lnjb = npr(beusym,3,2)
c
      if(lnjb.ne.0) then
      add2 = 0
      numbeu = lnjb
c
  160 if(nbeu.eq.fpbkd1(ibkd1+1)) then
      ibkd1 = ibkd1 + 1
      off1 = 1
      fbeu = fpbkd1(ibkd1)
      if(ibkd1.eq.nbkd1) then
      lbeu = nsqov
      lnbuf = lastb
      else
      lbeu = fpbkd1(ibkd1+1) - 1
      end if
cttt  write(*,*) ' reading 90: lnbuf,lastb,lnbkt = ',lnbuf,lastb,lnbkt
      call tit_sread(itap90,buf,intowp(lnbuf))
      end if
c
      lnbeu = lbeu - nbeu + 1
      if(lnbeu.gt.numbeu) lnbeu = numbeu
      lngav = lnjb
      adt2 = off2 + add2*lnjb
      call mxmb(t2(off3),1,lnjb,buf(off1),1,lnjb,tau(adt2),1,lnjb,
     1          lngav,lnjb,lnbeu)
_IF1()c      call dgemm('n','n',lngav,lnbeu,lnjb,a1,t2(off3),lnjb,buf(off1),
_IF1()c     1           lnjb,a1,tau(adt2),lnjb)
      add2 = add2 + lnbeu
      off1 = off1 + lnbeu*lnjb
      nbeu = nbeu + lnbeu
      numbeu = numbeu - lnbeu
      if(numbeu.ne.0) go to 160
c
      off3 = off3 + lnjb*lngav
      off2 = off2 + lnjb*lngav
      end if
c
  150 continue
c
c  fold tau over and add into t2
c
      call fltau1(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
c
cttt  write(iw,*)  '    t2 after (d2a - d2b)  '
ctjl  call matout(t2,1,ndimt2,1,ndimt2)
cttt  call dotpr(t2,t2,ndimt2,test)
cttt  write(*,*) ' t2*t2 = ',test
      call srew(itap90)
      call tit_sread(itap90,tau,intowp(ndimt2))
      call vadd(t2,1,tau,1,t2,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,t2,intowp(ndimt2))
cttt  call dotpr(t2,t2,ndimt2,test)
cttt  write(*,*) ' t2*t2 = ',test
cttt  if(itjl.eq.0) stop
c
c  form d2c
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
c
      call extau3(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
ctjl  call matout(t2,1,ndimw,1,ndimw)
      call vclr(tau,1,ndimw)
cttt  write(iw,*)  '    t2 beginning d2 integrals: d2c part '
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
cttt  if(itjl.eq.0) stop
c
      call rsetsa(itap63,fsec(5))
      ibkd2 = 0
      off2 = 0
      off3 = 1
      nia = 1
c
      do 170 iasym = 1,nirred
      lnjb = npr(iasym,3,2)
c
      if(lnjb.ne.0) then
      add2 = 1
      numia = lnjb
c
  180 if(nia.eq.fpbkd2(ibkd2+1)) then
      call tit_sread(itap63,buf,intowp(lnbkt))
      off1 = 1
      ibkd2 = ibkd2 + 1
      fia = fpbkd2(ibkd2)
      if(ibkd2.eq.nbkd2) then
      lia = nsqov
      else
      lia = fpbkd2(ibkd2+1) - 1
      end if
      end if
c
      lnia = lia - nia + 1
      if(lnia.gt.numia) lnia = numia
      lngav = lnjb
      adt2 = off2 + add2
      call mxmb(t2(off3),1,lnjb,buf(off1),1,lnjb,tau(adt2),lnjb,1,
     1          lngav,lnjb,lnia)
_IF1()c      call dgemm('t','t',lnia,lngav,lnjb,a1,buf(off1),lnjb,t2(off3),
_IF1()c     1           lnjb,a1,tau(adt2),lnjb)
      add2 = add2 + lnia
      off1 = off1 + lnia*lnjb
      nia = nia + lnia
      numia = numia - lnia
      if(numia.ne.0) go to 180
c
      off3 = off3 + lnjb*lngav
      off2 = off2 + lnjb*lngav
      end if
c
  170 continue
cttt  write(iw,*)  '    t2 after d2c '
ctjl  call matout(tau,1,ndimt2,1,ndimt2)
cttt  call dotpr(tau,tau,ndimt2,test)
cttt  write(*,*) ' t2*t2 = ',test
cttt  if(itjl.eq.0) stop
c
c  form d2c contribution to t1
c
      call vclr(w1,1,ndimt1)
      lnia = npr(1,3,2)
      call mxmb(tau,lnia,1,t1o,1,lnia,w1,1,lnia,
     &          lnia,lnia,1)
_IF1()c      call dgemm('t','n',lnia,1,lnia,a1,tau,lnia,t1o,
_IF1()c     &           lnia,a1,w1,lnia)
cttt  call dotpr(w1,w1,ndimt1,test)
cttt  write(6,*) ' t1 after d2c contribution ',test
      call vsub(t1n,1,w1,1,t1n,1,ndimt1)
c
c  form 0.5*d2c in other vector
c
      do 510 jki = 1,ndimw
      t2(jki) = tau(jki)*ap5
510   continue
c
c  c integral contribution to t2 : t2 part first : [c2]
c  also [c1] contribution to t1
c
c
c  form [d2c-c] and [0.5*d2c-c] and t1 contribution from c integral
c
      call srew(itap62)
      ibkc = 0
      off3 = 1
      ngav = 1
      adt1 = 1
c
      do 50 gavsym = 1,nirred
      lnia = npr(gavsym,3,2)
c
      if(lnia.ne.0) then
      numgav = lnia
c
   60 if(ngav.eq.fpbkc(ibkc+1)) then
      call tit_sread(itap62,buf,intowp(lnbkt))
      off1 = 1
      ibkc = ibkc + 1
      if(odebug(33)) then
       test = a0
       do 1199 ijkli = 1,lnbkt
       test = test + dabs(buf(ijkli))
 1199  continue
       write(*,*) ' ibkc,test = ',ibkc,test
      endif
      fgav = fpbkc(ibkc)
      if(ibkc.eq.nbkc) then
      lgav = nsqov
      else
      lgav = fpbkc(ibkc+1) - 1
      end if
      end if
c
      lngav = lgav - ngav + 1
      if(lngav.gt.numgav) lngav = numgav
      call vsub(tau(off3),1,buf(off1),1,tau(off3),1,lngav*lnia)
      call vsub(t2(off3),1,buf(off1),1,t2(off3),1,lngav*lnia)
c
c t1 part : untested
c
      if(gavsym.eq.1) then
      call mxmb(buf(off1),lnia,1,t1o,1,lnia,t1n(adt1),1,lnia,
     1          lngav,lnia,1)
_IF1()c      call dgemm('t','n',lngav,1,lnia,a1,buf(off1),lnia,t1o,
_IF1()c     1           lnia,a1,t1n(adt1),lnia)
      adt1 = adt1 + lngav
      end if
c
c
      off1 = off1 + lngav*lnia
      ngav = ngav + lngav
      numgav = numgav - lngav
      off3 = off3 + lnia*lngav
      if(numgav.ne.0) go to 60
c
      end if
c
   50 continue
c
c   write out 0.5*d2c-c
c
cttt  call dotpr(t1n,t1n,ndimt1,test)
cttt  write(6,*) ' c contribution to t1n ',test
      call rsetsa(itap90,endt2)
      call swrit(itap90,t2,intowp(ndimw))
c
c  sort [d2c-c] for t1*t1 contribution to t2
c  and multiply by t1(v,a)
c
cqci
      if(qci.ne.1) then
c
      call srt22(tau,t2,isqoo,ntr,flov,ivvoo,ivvoot)
      call vclr(tau,1,ndimw)
      off1 = 1
      off2 = 1
      off3 = 1
      do 705 asym = 1,nirred
      lni = flov(asym,2) - flov(asym,1) + 1
      lna = flov(asym,4) - flov(asym,3) + 1
      lngiv = ntr(asym,2)
      if(lni.ne.0.and.lna.ne.0) then
      call mxmb(t2(off1),1,lngiv,t1o(off2),lni,1,tau(off3),1,lngiv,
     1          lngiv,lna,lni)
_IF1()c      call dgemm('n','t',lngiv,lni,lna,a1,t2(off1),lngiv,t1o(off2),
_IF1()c     1           lni,a1,tau(off3),lngiv)
      end if
      off2 = off2 + lni*lna
      off1 = off1 + lna*lngiv
      off3 = off3 + lni*lngiv
  705 continue
c
      call srt23(tau,t2,isqoo,ntr,flov,iooov,iooovt)
      call vclr(tau,1,ndimw)
      off1 = 1
      off2 = 1
      off3 = 1
      do 706 isym = 1,nirred
      lni = flov(isym,2) - flov(isym,1) + 1
      lnbe = flov(isym,4) - flov(isym,3) + 1
      lngvu = ntr(isym,2)
      if(lni.ne.0.and.lnbe.ne.0) then
      call mxmb(t2(off1),1,lngvu,t1o(off2),1,lni,tau(off3),1,lngvu,
     1          lngvu,lni,lnbe)
_IF1()c      call dgemm('n','n',lngvu,lnbe,lni,a1,t2(off1),lngvu,t1o(off2),
_IF1()c     1           lni,a1,tau(off3),lngvu)
      end if
      off2 = off2 + lni*lnbe
      off1 = off1 + lni*lngvu
      off3 = off3 + lnbe*lngvu
  706 continue
c
c  fold [d2c-c]*t1*t1 contribution and add to t2
c
      call flt23(t2,tau,ioff,itriv,isqoo,npr,flov,ifd2,ivvoo,
     1           ivvoot,ntr)
      call srew(itap90)
      call tit_sread(itap90,tau,intowp(ndimt2))
      call vadd(t2,1,tau,1,t2,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,t2,intowp(ndimt2))
c
      if(odebug(33)) then
       write(iw,*)  '    t2 after [d2c-c]*t1*t1 contribution '
       call matout(tau,1,ndimt2,1,ndimt2)
       call dotpr(t2,t2,ndimt2,test)
       write(*,*) ' test = ',test
      endif
c
cttt  if(itjl.eq.0) stop
c
c  make f11 and form [0.5*d2c-c-f11]
c
      call vclr(t2,1,ndimw)
      call mkf11(t2,buf,ioff,itriv,isqov,npr,flov,ifc,fpbkf,t1o,isqvv)
c
      call rsetsa(itap90,endt2)
      call tit_sread(itap90,tau,intowp(ndimw))
      call vsub(tau,1,t2,1,tau,1,ndimw)
      call rsetsa(itap90,endt2)
      call swrit(itap90,tau,intowp(ndimw))
c
c  make e11 and form [0.5*d2c-c-f11+e11]
c
      call vclr(t2,1,ndimw)
      call gte11(t2,buf,isqoo,npr,flov,iooov,iooovt,fpbke1,ntr)
      call vclr(tau,1,ndimw)
c
      off1 = 1
      off2 = 1
      off3 = 1
      do 601 usym = 1,nirred
      lnu = flov(usym,2) - flov(usym,1) + 1
      lnbvi = ntr(usym,2)
      lnga = flov(usym,4) - flov(usym,3) + 1
      if(lnu.ne.0.and.lnga.ne.0) then
      call mxmb(t2(off1),1,lnbvi,t1o(off2),1,lnu,tau(off3),1,lnbvi,
     1          lnbvi,lnu,lnga)
_IF1()c      call dgemm('n','n',lnbvi,lnga,lnu,a1,t2(off1),lnbvi,t1o(off2),
_IF1()c     1           lnu,a1,tau(off3),lnbvi)
      end if
      off3 = off3 + lnga*lnbvi
      off2 = off2 + lnu*lnga
      off1 = off1 + lnu*lnbvi
  601 continue
c
cttt  write(iw,*)  '    t2 before srte1s: off3,ndimw = ',off3,ndimw
ctjl  call matout(tau,1,ndimw,1,ndimw)
cttt  call dotpr(tau,tau,ndimw,test)
cttt  write(*,*) ' test = ',test
      call vclr(t2,1,ndimw)
      call srte1s(tau,t2,isqov,npr,flov,ifc)
cttt  write(iw,*)  '    t2 after srte1s (gte11) '
ctjl  call matout(t2,1,ndimw,1,ndimw)
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' test = ',test
c
      end if
cqci
      call rsetsa(itap90,endt2)
      call tit_sread(itap90,tau,intowp(ndimw))
cqci
      if(qci.ne.1) then
      call vadd(tau,1,t2,1,tau,1,ndimw)
      end if
c
c  write d2c in buffered fashion
c
      call rsetsa(itap90,endt2)
      ibkd1 = 1
      liajb = 0
      off1 = 1
      lnbuf = lnbkt
      nia = 0
      do 190 iasym = 1,nirred
      lnia = npr(iasym,3,2)
      numia = lnia
  200 lia = nia + numia
      if(ibkd1.ne.nbkd1) then
      if(lia.ge.(fpbkd1(ibkd1+1)-1)) then
      ibkd1 = ibkd1 + 1
      mia = fpbkd1(ibkd1) - nia - 1
      liajb = liajb + mia*lnia
      nia = fpbkd1(ibkd1) - 1
      numia = numia - mia
      call swrit(itap90,tau(off1),intowp(lnbuf))
      off1 = off1 + liajb
      liajb = 0
      go to 200
      end if
      end if
      nia = lia
      liajb = liajb + numia*lnia
  190 continue
c
c  write out the last bucket
c
      call swrit(itap90,tau(off1),intowp(liajb))
cttt  write(*,*)' bucket of d2c: ndimw,liajb = ',ndimw,liajb
      lastb = liajb
c
c  now form [t2(i,u,be<a)]
c  and store as t2(i,a,u,be)
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
c
      call extau6(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
ctjl  call matout(t2,1,ndimw,1,ndimw)
      call vclr(tau,1,ndimw)
cttt  write(iw,*)  '    t2 beginning d2 integrals: d2c*t part '
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
cttt  if(itjl.eq.0) stop
c
c  form d2c * t contribution to t2; and d2c contribution to t1
c
      call vclr(w1,1,ndimt1)
      call rsetsa(itap90,endt2)
      ibkd1 = 0
      off2 = 1
      off3 = 1
      ngau = 1
      adt1 = 1
      lnbuf = lnbkt
c
      do 210 gausym = 1,nirred
      lnjb = npr(gausym,3,2)
c
      if(lnjb.ne.0) then
      add2 = 0
      numgau = lnjb
c
  220 if(ngau.eq.fpbkd1(ibkd1+1)) then
      ibkd1 = ibkd1 + 1
      off1 = 1
      fgau = fpbkd1(ibkd1)
      if(ibkd1.eq.nbkd1) then
      lgau = nsqov
      lnbuf = lastb
      else
      lgau = fpbkd1(ibkd1+1) - 1
      end if
cttt  write(*,*) ' reading 90: lnbuf,lastb,lnbkt = ',lnbuf,lastb,lnbkt
      call tit_sread(itap90,buf,intowp(lnbuf))
      end if
c
      lngau = lgau - ngau + 1
      if(lngau.gt.numgau) lngau = numgau
      lnbev = lnjb
      adt2 = off2 + add2*lnjb
      call mxmb(t2(off3),1,lnjb,buf(off1),1,lnjb,tau(adt2),1,lnjb,
     1          lnbev,lnjb,lngau)
_IF1()c      call dgemm('n','n',lnbev,lngau,lnjb,a1,t2(off3),lnjb,buf(off1),
_IF1()c     1           lnjb,a1,tau(adt2),lnjb)
      add2 = add2 + lngau
      off1 = off1 + lngau*lnjb
      ngau = ngau + lngau
      numgau = numgau - lngau
      if(numgau.ne.0) go to 220
c
      off3 = off3 + lnjb*lnbev
      off2 = off2 + lnjb*lnbev
      end if
c
  210 continue
c
c  fold tau over and add into t2
c
      call fltau2(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
c
cttt  write(iw,*)  '    t2 after d2c*t '
ctjl  call matout(t2,1,ndimt2,1,ndimt2)
cttt  call dotpr(t2,t2,ndimt2,test)
cttt  write(*,*) ' t2*t2 = ',test
      call srew(itap90)
      call tit_sread(itap90,tau,intowp(ndimt2))
      call vadd(t2,1,tau,1,t2,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,t2,intowp(ndimt2))
cttt  call dotpr(t2,t2,ndimt2,test)
cttt  write(iw,*)  '    total t2 at this point '
cttt  write(*,*) ' t2*t2 = ',test
cttt  if(itjl.eq.0) stop
c
c  form d2c * t2 contribution to t2;
c  expand t2(v,u,ga<be) to t2(v,ga,u,be)
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
c
      call extau2(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
ctjl  call matout(t2,1,ndimw,1,ndimw)
      call vclr(tau,1,ndimw)
cttt  write(iw,*)  '    t2 beginning d2c*t2 contribution '
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
cttt  if(itjl.eq.0) stop
c
      call rsetsa(itap90,endt2)
      ibkd1 = 0
      off2 = 1
      off3 = 1
      nbeu = 1
      lnbuf = lnbkt
c
      do 230 beusym = 1,nirred
      lnjb = npr(beusym,3,2)
c
      if(lnjb.ne.0) then
      add2 = 0
      numbeu = lnjb
c
  240 if(nbeu.eq.fpbkd1(ibkd1+1)) then
      ibkd1 = ibkd1 + 1
      off1 = 1
      fbeu = fpbkd1(ibkd1)
      if(ibkd1.eq.nbkd1) then
      lbeu = nsqov
      lnbuf = lastb
      else
      lbeu = fpbkd1(ibkd1+1) - 1
      end if
cttt  write(*,*) ' reading 90: lnbuf,lastb,lnbkt = ',lnbuf,lastb,lnbkt
      call tit_sread(itap90,buf,intowp(lnbuf))
      end if
c
      lnbeu = lbeu - nbeu + 1
      if(lnbeu.gt.numbeu) lnbeu = numbeu
      lngav = lnjb
      adt2 = off2 + add2*lnjb
      call mxmb(t2(off3),1,lnjb,buf(off1),1,lnjb,tau(adt2),1,lnjb,
     1          lngav,lnjb,lnbeu)
_IF1()c      call dgemm('n','n',lngav,lnbeu,lnjb,a1,t2(off3),lnjb,buf(off1),
_IF1()c     1           lnjb,a1,tau(adt2),lnjb)
      add2 = add2 + lnbeu
      off1 = off1 + lnbeu*lnjb
      nbeu = nbeu + lnbeu
      numbeu = numbeu - lnbeu
      if(numbeu.ne.0) go to 240
c
      off3 = off3 + lnjb*lngav
      off2 = off2 + lnjb*lngav
      end if
c
  230 continue
c
c  fold tau over and add into t2
c
      call fltau1(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc)
c
cttt  write(*,*) ' t2 after d2c*t2 '
ctjl  call matout(t2,1,ndimt2,1,ndimt2)
cttt  call dotpr(t2,t2,ndimt2,test)
cttt  write(*,*) ' t2*t2 = ',test
      call srew(itap90)
      call tit_sread(itap90,tau,intowp(ndimt2))
      call vadd(tau,1,t2,1,tau,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,tau,intowp(ndimt2))
cttt  call dotpr(tau,tau,ndimt2,test)
cttt  write(*,*) ' t2*t2 at end of d2a,b,c = ',test
cttt  if(itjl.eq.0) stop
c
c  form d2'
c
c
c d2prime contribution
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
c
cqci
      if(qci.eq.1) then
      call vclr(w1,1,ndimt1)
      call extau1(tau,t2,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,ifd4,w1,
     1            isqov)
      else
      call extau1(tau,t2,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,ifd4,t1o,
     1            isqov)
c
      end if
      call vclr(tau,1,ndimw)
ctjl
cttt  write(iw,*) '    t2  before d2prime   '
ctjl  call matout(t2,1,ndimw,1,ndimw)
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
ctjl
c
      call rsetsa(itap63,fsec(6))
      ibkd3 = 0
      off2 = 1
      off3 = 1
      nij = 1
c
      do 250 ijsym = 1,nirred
      lnab = npr(ijsym,2,2)
      numij = npr(ijsym,1,1)
c
      if(lnab.ne.0.and.numij.ne.0) then
      add2 = 0
c
  260 if(nij.eq.fpbkd3(ibkd3+1)) then
      call tit_sread(itap63,buf,intowp(lnbkt))
ctjl
_IF1()      test = 0.0d0
_IF1()      do 261 jk=1,lnbkt
_IF1()      test = test + dabs(buf(jk))
_IF1()261   continue
_IF1()      write(6,*) ' test ,ibkd3 ',test,(ibkd3+1)
_IF1()ctjl
      off1 = 1
      ibkd3 = ibkd3 + 1
      fij = fpbkd3(ibkd3)
      if(ibkd3.eq.nbkd3) then
      lij = ntrio
      else
      lij = fpbkd3(ibkd3+1) - 1
      end if
      end if
c
      lnij = lij - nij + 1
      if(lnij.gt.numij) lnij = numij
      lnuv = npr(ijsym,1,2)
c
      if(lnuv.ne.0) then
      adt2 = off2 + add2*lnuv
      call mxmb(t2(off3),1,lnuv,buf(off1),1,lnab,tau(adt2),1,lnuv,
     1          lnuv,lnab,lnij)
_IF1()c      call dgemm('n','n',lnuv,lnij,lnab,a1,t2(off3),lnuv,buf(off1),
_IF1()c     1           lnab,a1,tau(adt2),lnuv)
      add2 = add2 + lnij
      end if
c
      off1 = off1 + lnij*lnab
      nij = nij + lnij
      numij = numij - lnij
      if(numij.ne.0) go to 260
c
      off3 = off3 + lnab*lnuv
      end if
      off2 = off2 + npr(ijsym,1,2)*npr(ijsym,1,1)
c
  250 continue
c
cttt  write(*,*) ' d2prime before expansion '
ctjl  call matout(tau,1,ndimw,1,ndimw)
cttt  call dotpr(tau,tau,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
      call vclr(t2,1,ndimw)
      call expd2p(tau,t2,ioff,itrio,isqoo,npr,flov,ifa,ifa2)
cttt  write(*,*) ' d2prime after expansion '
ctjl  call matout(t2,1,ndimw,1,ndimw)
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
      call vclr(tau,1,ndimw)
c
c  add d2p contribution to giu with expanded d2p
c
      call vclr(w1,1,nsqoo)
      call mkgiu(t2,w1,npr,isqoo,flov,ifa)
      if(odebug(33)) then
       write(6,*) ' giu after d2prime contribution '
       call dotpr(w1,w1,nsqoo,test)
       write(*,*) ' giu*giu = ',test
      endif
c
c  a integral contribution to t2 : read in different tau
c
      call srew(itap60)
      ibka = 0
      off2 = 1
      nuv = 1
c
      do 30 uvsym = 1,nirred
      lnij = npr(uvsym,1,2)
c
      if(lnij.ne.0) then
      numuv = lnij
c
   40 if(nuv.eq.fpbka(ibka+1)) then
      call tit_sread(itap60,buf,intowp(lnbkt))
      off1 = 1
      ibka = ibka + 1
      fuv = fpbka(ibka)
      if(ibka.eq.nbka) then
      luv = nsqoo
      else
      luv = fpbka(ibka+1) - 1
      end if
      end if
c
      lnuv = luv - nuv + 1
      if(lnuv.gt.numuv) lnuv = numuv
      call vadd(t2(off2),1,buf(off1),1,t2(off2),1,lnij*lnuv)
      off1 = off1 + lnuv*lnij
      off2 = off2 + lnuv*lnij
      nuv = nuv + lnuv
      numuv = numuv - lnuv
      if(numuv.ne.0) go to 40
c
      end if
c
   30 continue
c
c  form [0.5*(d2p+a)]
c
ctjl  do 602 jki = 1,ndimw
ctjl  t2(jki) = ap5*t2(jki)
ctjl  continue
c
c  write  [d2p + a] out to file 90
c
      call rsetsa(itap90,endt2)
      call swrit(itap90,t2,intowp(ndimw))
c
cttt  write(iw,*)  '    t2 after a integrals '
ctjl  call matout(t2,1,ndimw,1,ndimw)
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
cttt  if(itjl.eq.0) stop
c
c   form e1 here ( store in t2 )
c
cqci
      if(qci.ne.1) then
c
      call gte1(t2,buf,isqoo,npr,flov,ivooo,ivooot,fpbke1,ntr)
      call vclr(tau,1,ndimw)
c
      off1 = 1
      off2 = 1
      off3 = 1
      do 603 besym = 1,nirred
      lnbe = flov(besym,4) - flov(besym,3) + 1
      lnuvi = ntr(besym,3)
      lnj = flov(besym,2) - flov(besym,1) + 1
      if(lnj.ne.0.and.lnbe.ne.0) then
      call mxmb(t2(off1),1,lnuvi,t1o(off2),lnj,1,tau(off3),1,lnuvi,
     1          lnuvi,lnbe,lnj)
_IF1()c      call dgemm('n','t',lnuvi,lnj,lnbe,a1,t2(off1),lnuvi,t1o(off2),
_IF1()c     1           lnj,a1,tau(off3),lnuvi)
      end if
      off3 = off3 + lnj*lnuvi
      off2 = off2 + lnj*lnbe
      off1 = off1 + lnbe*lnuvi
  603 continue
c
      if(odebug(33)) then
       write(iw,*)  '    t2 before srte1s: off3,ndimw = ',off3,ndimw
       call matout(tau,1,ndimw,1,ndimw)
       call dotpr(tau,tau,ndimw,test)
       write(*,*) ' test = ',test
      endif
      call vclr(t2,1,ndimw)
      call srte1(tau,t2,isqoo,npr,flov,ifa)
      if(odebug(33)) then
       write(iw,*)  '    t2 after srte1 (gte1) '
       call matout(t2,1,ndimw,1,ndimw)
       call dotpr(t2,t2,ndimw,test)
       write(*,*) ' test = ',test
      endif
c
c  add in e1 contribution to g(i,u)
c
      call mkgiu(t2,w1,npr,isqoo,flov,ifa)
c
      if(odebug(33)) then
       write(6,*) ' giu after e1 contribution '
       call dotpr(w1,w1,nsqoo,test)
       write(*,*) ' giu*giu = ',test
      endif
c
c  form [d2p + a + e1]
c
      call srte12(tau,t2,isqoo,npr,flov,ifa)
      call rsetsa(itap90,endt2)
      call tit_sread(itap90,t2,intowp(ndimw))
      call vadd(t2,1,tau,1,t2,1,ndimw)
cqci
      end if
c
c  write [d2p + a + e1] out like the a integral list
c
      call rsetsa(itap90,endt2)
      ibka = 1
      luvij = 0
      off1 = 1
      lnbuf = lnbkt
      nuv = 0
      do 280 uvsym = 1,nirred
      lnuv = npr(uvsym,1,2)
      numuv = lnuv
  290 luv = nuv + numuv
      if(ibka.ne.nbka) then
      if(luv.ge.(fpbka(ibka+1)-1)) then
      ibka = ibka + 1
      muv = fpbka(ibka) - nuv - 1
      luvij = luvij + muv*lnuv
      nuv = fpbka(ibka) - 1
      numuv = numuv - muv
      call swrit(itap90,t2(off1),intowp(lnbuf))
      off1 = off1 + luvij
      luvij = 0
      go to 290
      end if
      end if
      nuv = luv
      luvij = luvij + numuv*lnuv
  280 continue
c
c  write out the last bucket
c
      call swrit(itap90,t2(off1),intowp(luvij))
_IF1()      write(*,*)' bucket of 0.5*d2p+e1 :  ndimw,luvij = ',ndimw,luvij
_IF1()      test = 0.0d0
_IF1()      do 285 jki=1,luvij
_IF1()      test = test + dabs(t2(jki))
_IF1()  285 continue
_IF1()      write(6,*) ' sum of d2p ints ',test
      lastb = luvij
c
c  read in t2 and sort to t2(i,ubega)
c  multiply by g(i,v), fold over and add to t2
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
      call vclr(t2,1,ndimw)
      call srt21(tau,t2,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,ioovv,
     1           ioovvt,ntr)
      if(odebug(33)) then
       write(*,*) ' t2 after srt21 '
       call matout(t2,1,ndimw,1,ndimw)
       call dotpr(t2,t2,ndimw,test)
       write(*,*) ' t2*t2 = ',test
      endif
c
      call vclr(tau,1,ndimw)
c
      off1 = 1
      off2 = 1
      off4 = 1
      do 500 isym = 1,nirred
      lni = flov(isym,2) - flov(isym,1) + 1
      lnbgu = ntr(isym,1)
      lnbe = flov(isym,4) - flov(isym,3) + 1
      if(lni.ne.0) then
      call mxmb(t2(off1),1,lnbgu,w1(off2),1,lni,tau(off1),1,lnbgu,
     1          lnbgu,lni,lni)
_IF1()c      call dgemm('n','n',lnbgu,lni,lni,a1,t2(off1),lnbgu,w1(off2),
_IF1()c     1           lni,a1,tau(off1),lnbgu)
      if(lnbe.ne.0) then
      call mxmb(t1o(off4),lni,1,w1(off2),1,lni,t1n(off4),lni,1,
     1          lnbe,lni,lni)
_IF1()c      call dgemm('t','n',lni,lnbe,lni,a1,w1(off2),lni,t1o(off4),
_IF1()c     1           lni,a1,t1n(off4),lni)
      end if
      end if
      off4 = off4 + lnbe*lni
      off2 = off2 + lni*lni
      off1 = off1 + lni*lnbgu
  500 continue
c
c  fold giu contribution
c
cttt  write(*,*) ' t2 after mult by giu '
ctjl  call matout(tau,1,ndimw,1,ndimw)
cttt  call dotpr(tau,tau,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
cttt  write(*,*) ' t1n after mult by giu '
ctjl  call matout(t1n,1,ndimt1,1,ndimt1)
cttt  call dotpr(t1n,t1n,ndimt1,test)
cttt  write(*,*) ' t1n*t1n = ',test
c
      call flt21(t2,tau,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,ioovv,
     1           ioovvt,ntr)
      call srew(itap90)
      call tit_sread(itap90,tau,intowp(ndimt2))
      call vsub(tau,1,t2,1,tau,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,tau,intowp(ndimt2))
cttt  write(*,*) ' t2 after flt21 '
ctjl  call matout(t2,1,ndimt2,1,ndimt2)
cttt  call dotpr(t2,t2,ndimt2,test)
cttt  write(*,*) ' t2*t2 = ',test
cttt  if(itjl.eq.0) stop
c
c  [d2p + a + e1] contribution
c
c
c  form tau (v,u,ga,be) from t2 and t1
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
cqci
      if(qci.eq.1) then
      call vclr(w1,1,ndimt1)
      call mktau(tau,t2,ioff,itriv,isqoo,npr,flov,ifd2,w1,isqov)
      else
      call mktau(tau,t2,ioff,itriv,isqoo,npr,flov,ifd2,t1o,isqov)
      end if
c
c  multiply (d2p + a + e1) * tau and form t2(v,u,ga,be)
c
      call vclr(tau,1,ndimw)
      call rsetsa(itap90,endt2)
      ibka = 0
      off2 = 0
      off3 = 1
      nuv = 1
      lnbuf = lnbkt
c
      do 300 uvsym = 1,nirred
      lnij = npr(uvsym,1,2)
c
      if(lnij.ne.0) then
      add2 = 1
      numuv = lnij
c
  310 if(nuv.eq.fpbka(ibka+1)) then
      ibka = ibka + 1
      off1 = 1
      fuv = fpbka(ibka)
      if(ibka.eq.nbka) then
      lnbuf = lastb
      luv = nsqoo
      else
      luv = fpbka(ibka+1) - 1
      end if
      call tit_sread(itap90,buf,intowp(lnbuf))
cttt  test = 0.0d0
cttt  do 311 jki=1,lnbuf
cttt  test = test + dabs(buf(jki))
cttt  write(6,*) ' sum of d2p ints as read in ',test
      end if
c
      lnuv = luv - nuv + 1
      if(lnuv.gt.numuv) lnuv = numuv
      lnbg = npr(uvsym,2,1)
c
      if(lnbg.ne.0) then
      adt2 = off2 + add2
      call mxmb(t2(off3),lnij,1,buf(off1),1,lnij,tau(adt2),lnij,1,
     1          lnbg,lnij,lnuv)
_IF1()c      call dgemm('t','n',lnuv,lnbg,lnij,a1,buf(off1),lnij,t2(off3),
_IF1()c     1           lnij,a1,tau(adt2),lnij)
      add2 = add2 + lnuv
      end if
c
      off1 = off1 + lnuv*lnij
      nuv = nuv + lnuv
      numuv = numuv - lnuv
      if(numuv.ne.0) go to 310
c
      off3 = off3 + lnij*lnbg
      off2 = off2 + lnij*lnbg
      end if
c
  300 continue
c
ctjl  call fltau3(t2,tau,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,ifd4)
      call srew(itap90)
      call tit_sread(itap90,t2,intowp(ndimt2))
      call vadd(tau,1,t2,1,tau,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,tau,intowp(ndimt2))
c
ctjl  call matout(t2,1,ndimt2,1,ndimt2)
cttt  call dotpr(t2,t2,ndimt2,test)
cttt  write(iw,*)  ' 0.5d2p+0.5a+e1 contribution  ',test
cttt  call dotpr(tau,tau,ndimt2,test)
cttt  write(iw,*)  ' total e contribution  ',test
cttt  if(itjl.eq.0) stop
c
c  form f2p
c
cqci
      if(qci.ne.1) then
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
      call vclr(t2,1,ndimw)
      call extau1(tau,t2,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,ifd4,t1o,
     1            isqov)
      call vclr(tau,1,ndimw)
ctjl
cttt  write(iw,*) '    t2 before f2p '
ctjl  call matout(t2,1,ndimw,1,ndimw)
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
c
      call srew(itap65)
      ibkf = 0
      off2 = 1
      off3 = 1
      nbi = 1
c
      do 103 bisym = 1,nirred
      lnab = npr(bisym,2,2)
      lnbei = npr(bisym,3,2)
      lnuv = npr(bisym,1,2)
c
      if(lnab.ne.0.and.lnbei.ne.0) then
      add2 = 0
      numbi = lnbei
c
  203 if(nbi.eq.fpbkf(ibkf+1)) then
      call tit_sread(itap65,buf,intowp(lnbkt))
c
_IF1()ctjl
_IF1()      test = 0.0d0
_IF1()      do 113 jk=1,lnbkt
_IF1()      test = test + dabs(buf(jk))
_IF1()113   continue
_IF1()      write(6,*) ' test ,ibkb ',test,(ibkb+1)
      off1 = 1
      ibkf = ibkf + 1
      fbi = fpbkf(ibkf)
      if(ibkf.eq.nbkf) then
      lbi = nsqov
      else
      lbi = fpbkf(ibkf+1) - 1
      end if
      end if
c
      lnbi = lbi - nbi + 1
      if(lnbi.gt.numbi) lnbi = numbi
      if(lnuv.ne.0) then
      adt2 = off2 + add2*lnuv
      call mxmb(t2(off3),1,lnuv,buf(off1),1,lnab,tau(adt2),1,lnuv,
     1          lnuv,lnab,lnbi)
_IF1()c      call dgemm('n','n',lnuv,lnbi,lnab,a1,t2(off3),lnuv,buf(off1),
_IF1()c     1           lnab,a1,tau(adt2),lnuv)
      add2 = add2 + lnbi
      end if
c
      off1 = off1 + lnbi*lnab
      nbi = nbi + lnbi
      numbi = numbi - lnbi
      if(numbi.ne.0) go to 203
c
      end if
      off3 = off3 + lnab*lnuv
      off2 = off2 + lnuv*lnbei
c
  103 continue
cttt  call dotpr(tau,tau,ndimw,test)
cttt  write(6,*) ' f2p stage 1',test
c
c  sort f2p to f2p(b,uv:i)
c
      call srt25(tau,t2,isqoo,npr,flov,iooov,iooovt,ntr)
c
c  write out f2p
c
      call rsetsa(itap90,endt2)
      call swrit(itap90,t2,intowp(ndimw))
cqci
      end if
c
c  form d1 and add d integral to t2
c
      call srew(itap90)
      call tit_sread(itap90,tau,intowp(ndimt2))
      call gtd12(t2,buf,isqoo,npr,flov,ivvoo,ivvoot,fpbkd1,ntr,tau,
     1            ifd2,itriv,ioff)
cttt  call dotpr(tau,tau,ndimt2,test)
cttt  write(6,*) ' t2 after d integral direct contribution ',test
      call srew(itap90)
      call swrit(itap90,tau,intowp(ndimt2))
      call vclr(tau,1,ndimw)
c
      off1 = 1
      off2 = 1
      off3 = 1
      do 608 asym = 1,nirred
      lna = flov(asym,4) - flov(asym,3) + 1
      lnbui = ntr(asym,2)
      lnv = flov(asym,2) - flov(asym,1) + 1
      if(lnv.ne.0.and.lna.ne.0) then
      call mxmb(t2(off1),1,lnbui,t1o(off2),lnv,1,tau(off3),1,lnbui,
     1          lnbui,lna,lnv)
_IF1()c      call dgemm('n','t',lnbui,lnv,lna,a1,t2(off1),lnbui,t1o(off2),
_IF1()c     1           lnv,a1,tau(off3),lnbui)
      end if
      off3 = off3 + lnv*lnbui
      off2 = off2 + lnv*lna
      off1 = off1 + lna*lnbui
  608 continue
c
      if(odebug(33)) then
       write(iw,*)  '    d1  '
       call matout(tau,1,ndimw,1,ndimw)
       call dotpr(tau,tau,ndimw,test)
       write(*,*) ' test = ',test
      endif
c
c  form d1 contributions to t1
c
      if(odebug(33)) then
       call dotpr(t1n,t1n,ndimt1,test)
       write(*,*) ' t1n before d1 contributions '
       write(*,*) ' test = ',test
      endif
cqci
      if(qci.eq.1) then
      call vclr(w2,1,ndimt1)
      call d1t1(tau,w2,w1,t1n,isqoo,ntr,flov,iooov,iooovt,isqov)
      else
      call d1t1(tau,t1o,w1,t1n,isqoo,ntr,flov,iooov,iooovt,isqov)
      end if
cqci
      if (odebug(33)) then
       call dotpr(t1n,t1n,ndimt1,test)
       write(*,*) ' t1n after d1 contributions '
       write(*,*) ' test = ',test
      endif
c
c  sort d1 for addition to f2p
c
cqci
      if(qci.ne.1) then
c
      call srt23(tau,t2,isqoo,ntr,flov,iooov,iooovt)
cttt  write(iw,*)  '    d1 after srt23 (gtd) '
ctjl  call matout(t2,1,ndimw,1,ndimw)
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' test = ',test
c
c  read f2p and multiply sum by t1(i,ga)
c
      call rsetsa(itap90,endt2)
      call tit_sread(itap90,tau,intowp(ndimw))
c
      call vadd(tau,1,t2,1,tau,1,ndimw)
c
      call vclr(t2,1,ndimw)
c
      off1 = 1
      off2 = 1
      off3 = 1
      do 609 isym = 1,nirred
      lni = flov(isym,2) - flov(isym,1) + 1
      lnbuv = ntr(isym,2)
      lnga = flov(isym,4) - flov(isym,3) + 1
      if(lni.ne.0.and.lnga.ne.0) then
      call mxmb(tau(off1),1,lnbuv,t1o(off2),1,lni,t2(off3),1,lnbuv,
     1          lnbuv,lni,lnga)
_IF1()c      call dgemm('n','n',lnbuv,lnga,lni,a1,tau(off1),lnbuv,t1o(off2),
_IF1()c     1           lni,a1,t2(off3),lnbuv)
      end if
      off3 = off3 + lnga*lnbuv
      off2 = off2 + lnga*lni
      off1 = off1 + lni*lnbuv
  609 continue
c
c  fold [d1+f2p] contribution and subtract from t2
c
      call flt22(tau,t2,ioff,itriv,isqoo,npr,flov,ifd2,ivvoo,
     1           ivvoot,ntr)
      call srew(itap90)
      call tit_sread(itap90,t2,intowp(ndimt2))
      call vsub(t2,1,tau,1,t2,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,t2,intowp(ndimt2))
cqci
      end if
c
cttt  write(iw,*)  '    t2 after [d1+f2p] contribution '
ctjl  call matout(tau,1,ndimt2,1,ndimt2)
cttt  call dotpr(tau,tau,ndimt2,test)
cttt  write(*,*) ' test = ',test
c
c  form [tau(j,i,b,be)-2*tau(i,j,b,be)] for d2p* contribution
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
c
      call vclr(t2,1,ndimw)
cqci
      if(qci.eq.1) then 
      call vclr(w1,1,ndimt1)
      call extau7(tau,t2,ioff,itriv,isqoo,npr,flov,ifd2,
     1            isqov,w1,ntr,ivvoo,ivvoot)
      else
      call extau7(tau,t2,ioff,itriv,isqoo,npr,flov,ifd2,
     1            isqov,t1o,ntr,ivvoo,ivvoot)
      end if
cttt  write(6,*) ' t2 after  extau7 '
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' test = ',test
c
      call vclr(tau,1,ndimw)
      call gtd1(tau,buf,isqoo,npr,flov,ivvoo,ivvoot,fpbkd1,ntr)
cttt  write(6,*) ' tau after gtd1 and extau7 '
cttt  call dotpr(tau,tau,ndimw,test)
cttt  write(*,*) ' test = ',test
c
      call vclr(w1,1,nsqvv)
c
      off1 = 1
      off2 = 1
      off3 = 1
      do 809 besym = 1,nirred
      lnbe = flov(besym,4) - flov(besym,3) + 1
      lnbij = ntr(besym,2)
      lna = lnbe
      if(lnbe.ne.0) then
      call mxmb(tau(off2),lnbij,1,t2(off1),1,lnbij,w1(off3),1,lna,
     1          lna,lnbij,lnbe)
_IF1()c      call dgemm('t','n',lna,lnbe,lnbij,a1,tau(off2),lnbij,t2(off1),
_IF1()c     1           lnbij,a1,w1(off3),lna)
      end if
      off3 = off3 + lna*lnbe
      off2 = off2 + lnbij*lna
      off1 = off1 + lnbe*lnbij
  809 continue
      if(odebug(33)) then
       call dotpr(w1,w1,nsqvv,test)
       write(6,*) ' gab after d2ps contribution ',test
      endif
c
c  f contribution to t1 and g(a,be)
c
      if(odebug(33)) then
       call dotpr(t1n,t1n,ndimt1,test)
       write(*,*) ' t1n before f contributions '
       write(*,*) ' test = ',test
      endif
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
      call ext21(tau,t2,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,ifd4)
      if(odebug(33)) then
       call dotpr(t2,t2,ndimw,test)
       write(6,*) ' 2t-t before f contribution to t1 '
       write(6,*) ' t2*t2 = ',test
      endif
      call vclr(tau,1,ndimw)
cqci
      if(qci.eq.1) then
      call vclr(w2,1,ndimt1)
      call mkgabe(t2,buf,isqov,npr,flov,ifd4,fpbkf,w2,t1n,isqvv,w1,
     1            isqoo)
      else
      call mkgabe(t2,buf,isqov,npr,flov,ifd4,fpbkf,t1o,t1n,isqvv,w1,
     1            isqoo)
      end if
c
      if(odebug(33)) then
       call dotpr(t1n,t1n,ndimt1,test)
       write(*,*) ' t1n after f contributions '
       write(*,*) ' test = ',test
      endif
c
c  expand t2 into t2(bvu,a) and multiply by g(a,be) and add to t2
c
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
      call extau8(tau,t2,ioff,itriv,isqoo,npr,flov,ifd2,
     1            ntr,ivvoo,ivvoot)
c
ctjl  call matout(t2,1,ndimw,1,ndimw)
      if(odebug(33)) then
       write(6,*) ' t2 after extau8 '
       call dotpr(t2,t2,ndimw,test)
       write(*,*) ' t2*t2 = ',test
      endif
c
      call vclr(tau,1,ndimw)
c
      off1 = 1
      off2 = 1
      off3 = 1
      call vclr(w2,1,ndimt1)
      do 503 asym = 1,nirred
      lna = flov(asym,4) - flov(asym,3) + 1
      lnbuv = ntr(asym,2)
      lni = flov(asym,2) - flov(asym,1) + 1
      if(lna.ne.0) then
      call mxmb(t2(off1),1,lnbuv,w1(off2),1,lna,tau(off1),1,lnbuv,
     1          lnbuv,lna,lna)
_IF1()c      call dgemm('n','n',lnbuv,lna,lna,a1,t2(off1),lnbuv,w1(off2),
_IF1()c     1           lna,a1,tau(off1),lnbuv)
      if(lni.ne.0) then
      call mxmb(t1o(off3),1,lni,w1(off2),1,lna,w2(off3),1,lni,
     1          lni,lna,lna)
_IF1()c      call dgemm('n','n',lni,lna,lna,a1,t1o(off3),lni,w1(off2),
_IF1()c     1           lna,a1,w2(off3),lni)
      end if
      end if
      off3 = off3 + lni*lna
      off2 = off2 + lna*lna
      off1 = off1 + lna*lnbuv
  503 continue
c
      call vsub(t1n,1,w2,1,t1n,1,ndimt1)
cttt  call dotpr(t1n,t1n,ndimt1,test)
cttt  write(6,*) ' t1n after gab contribution ',test
c
c  fold gab contribution
c
cttt  write(*,*) ' t2 after mult by gab '
ctjl  call matout(tau,1,ndimw,1,ndimw)
cttt  call dotpr(tau,tau,ndimw,test)
cttt  write(*,*) ' t2*t2 = ',test
      call flt23(t2,tau,ioff,itriv,isqoo,npr,flov,ifd2,ivvoo,
     1           ivvoot,ntr)
      call srew(itap90)
      call tit_sread(itap90,tau,intowp(ndimt2))
      call vadd(tau,1,t2,1,tau,1,ndimt2)
      call srew(itap90)
      call swrit(itap90,tau,intowp(ndimt2))
cttt  write(*,*) ' t2 after flt23 '
ctjl  call matout(t2,1,ndimt2,1,ndimt2)
cttt  call dotpr(t2,t2,ndimt2,test)
cttt  write(*,*) ' t2*t2 = ',test
cttt  write(*,*) ' complete t2 after iteration ',nit
ctjl  call matout(tau,1,ndimt2,1,ndimt2)
cttt  call dotpr(tau,tau,ndimt2,test)
cttt  write(*,*) ' t2*t2 = ',test
c
c  divide by mo eigenvalues
c
      call divt2(flov,tau,e)
cttt  call dotpr(tau,tau,ndimt2,test)
cttt  write(6,*) ' t2 after divide by eigenvalues ',test
      call srew(itap90)
      call swrit(itap90,tau,intowp(ndimt2))
c
c  e integral contribution to t1
c
cttt  call dotpr(t1n,t1n,ndimt1,test)
cttt  write(*,*) ' t1n before e contributions '
cttt  write(*,*) ' test = ',test
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,tau,intowp(ndimt2))
c
      call vclr(t2,1,ndimw)
      call extau9(tau,t2,ioff,itriv,isqoo,npr,flov,ifd2,
     1            ntr,ivvoo,ivvoot)
cttt  call dotpr(t2,t2,ndimw,test)
cttt  write(*,*) ' t2 after extau9 '
cttt  write(*,*) ' test = ',test
c
      call vclr(tau,1,ndimw)
      call gte1s(tau,buf,isqoo,npr,flov,iooov,iooovt,fpbke1,ntr)
cttt  call dotpr(tau,tau,ndimw,test)
cttt  write(6,*) ' tau after gte1s '
cttt  write(6,*) ' test = ',test
c
      off1 = 1
      off2 = 1
      off3 = 1
      do 901 usym = 1,nirred
      lnu = flov(usym,2) - flov(usym,1) + 1
      lnbe = flov(usym,4) - flov(usym,3) + 1
      lnbij = ntr(usym,2)
      if (lnu.ne.0.and.lnbe.ne.0) then
      call mxmb(t2(off1),lnbij,1,tau(off2),1,lnbij,t1n(off3),lnu,1,
     1          lnbe,lnbij,lnu)
_IF1()c      call dgemm('t','n',lnu,lnbe,lnbij,a1,tau(off2),lnbij,t2(off1),
_IF1()c     1           lnbij,a1,t1n(off3),lnu)
      end if
      off1 = off1 + lnbe*lnbij
      off2 = off2 + lnu*lnbij
      off3 = off3 + lnbe*lnu
  901 continue
cttt  write(6,*) ' t1n  after e1 contribution '
cttt  call dotpr(t1n,t1n,ndimt1,test)
cttt  write(*,*) ' t1n*t1n = ',test
c
c  divide by mo eigenvalues
c
      call divt1(flov,t1n,e)
ctjl  option for ccd ************** ccd **************
      if(iopt.eq.1.or.iopt.eq.4) call vclr(t1n,1,ndimt1)
ctjl  option for ccd ************** ccd **************
cttt  call dotpr(t1n,t1n,ndimt1,test)
cttt  write(6,*) ' t1 after divide by eigenvalues ',test
c
c  calculate correlation energy and extrapolate t1 and t2
c
      call srew(itap90)
      call tit_sread(itap90,tau,intowp(ndimt2))
cqci
      if(qci.eq.1) then
      call vclr(w1,1,ndimt1)
      call ext22(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc,w1)
      else
      call ext22(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc,t1n)
      end if
cqci
      xeo = eccsd
      call cceng(t2,buf,fpbkc,eccsd,escf,npr)
      xe = eccsd
      call rsetsa(itap69,endt1)
      call tit_sread(itap69,t2,intowp(ndimt2))
      call diis(t1o,t1n,t2,tau,it,cc,bb,itc,bb2,rms)
cqci
      if(qci.eq.1) then
      call ext22(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc,w1)
      else
      call ext22(tau,t2,ioff,itriv,isqoo,isqov,npr,flov,ifd2,ifc,t1n)
      end if
cqci
      call cceng(t2,buf,fpbkc,eccsd2,escf,npr)
c
c  set up next iteration
c
      do 390 jki = 1,ndimt1
      t1o(jki) = t1n(jki)
  390 continue
      call vclr(t1n,1,ndimt1)
ctjl temp
ctjl   if(nit.eq.1) then
ctjl   itap69 = 70
ctjl   call rfile(itap69)
ctjl   end if
ctjl temp
      call srew(itap69)
      call swrit(itap69,t1o,intowp(ndimt1))
      call swrit(itap69,tau,intowp(ndimt2))
      call dotpr(t1o,t1o,ndimt1,anmt1)
cttt  write(6,*) ' t1 , nit = ',nit,test
      call dotpr(tau,tau,ndimt2,anmt2)
cttt  write(6,*) ' t2 , nit = ',nit,test
      anmt1 = dsqrt(anmt1)
      anmt2 = dsqrt(anmt2)
      write(iw,2000) nit,eccsd,eccsd2,rms,anmt1,anmt2
cttt  go to 1000
c
c
c*******************end of new code***********************************
c
cttt  if(diisfl.eq.1) then
ctjl  call diisc (t1o,t1n,t2,s,no,nv,ndimt2,nit,it,iflag,
ctjl .            epsi,ngo,ndiis,mindim,maxdim,
ctjl .            cc,bb,itap98,itap99,itc,bb2)
c    .            cc,bb,tt1,dt1,tt2,dt2,itap98,itap99)
      go to 1000
c
      end
      subroutine ccdrv(cc,ic,maxcor,iconvi,imaxit,iopt,escf)
      implicit integer (a-z)
      REAL cc(*)
      REAL enuc,escf,eccsd
      integer ic(*)
      logical grad
      character*8 option
INCLUDE(common/t_adata)
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      character*60 wkdir
      common/t_iodir/lwkdir,wkdir
c
INCLUDE(common/t_iter)
c
      convi=iconvi
      maxit=imaxit
      oldtrp = 0
      debug = 0
      grad = .false.
      write(iw,6000)
      call rfile(itap57)
      call rfile(itap60)
      call rfile(itap61)
      call rfile(itap62)
      call rfile(itap63)
      call rfile(itap64)
      call rfile(itap65)
      call rfile(itap69)
      call rfile(itap90)
c
c  read in variables for coupled cluster calculation
c
      numint = 24
      junk = numint + intowp(2)
      call wreadw(itap57,ic,junk,1,pt57)
c
      nirred = ic(1)
      nbf = ic(2)
      no = ic(3)
      nv = ic(4)
      ntriv = ic(5)
      ntrio = ic(6)
      nsqvv = ic(7)
      nsqoo = ic(8)
      nsqov = ic(9)
      lnbkt = ic(10)
      nlist = ic(11)
      nbka = ic(12)
      nbkb = ic(13)
      nbkc = ic(14)
      nbkd1 = ic(15)
      nbkd2 = ic(16)
      nbkd3 = ic(17)
      nbke1 = ic(18)
ctjl  nbke2 = ic(19)
      nbkf = ic(19)
      ndimt1 = ic(20)
      ndimt2 = ic(21)
      norbs = ic(22)
      ndimw = ic(23)
      junk = numint/intowp(1) + 1
      escf = cc(junk)
      enuc = cc(junk+1)
c
      nmin = 2
      mindim = 2
      maxdim = 8
      fldiis=0
      if (iopt.eq.0)then
        option='ccsd    '
      else if (iopt.eq.3)then
        option='ccsd(t) '
      else if (iopt.eq.5)then
        option='qcisd   '
      else if (iopt.eq.6)then
        option='qcisd(t)'
      endif
c
c      if(option.eq.'CCD     ') iopt = 1
c      if(option.eq.'MP4T    ') iopt = 2
c      if(option.eq.'CCT     ') iopt = 3
c      if(option.eq.'CCTG    ') then
c        iopt = 3
c        grad = .true.
c      endif
c      if(option.eq.'CCDT    ') iopt = 4
c      if(option.eq.'CCDTG   ') then
c        iopt = 4
c        grad = .true.
c      endif
c      if(option.eq.'QCI     ') iopt = 5
c      if(option.eq.'QCIT    ') iopt = 6
ctjl
      if (fldiis.eq.2)then
      write(iw,6005)
 6005 format(/,5x,' ******* fldiis = 2, no diis ! ******',/)
      end if
      write(iw,6003) nmin ,mindim,maxdim,convi,maxit
 6003 format(   2x,' ***** diis parameters *****',
     .        /,2x,' nmin   = ',i5,
     .        /,2x,' mindim = ',i5,
     .        /,2x,' maxdim = ',i5,
     .       //,2x,' ***** ccsd parameters *****',
     .        /,2x,' convi  = ',i5,
     .        /,2x,' maxit  = ',i5)
      write(iw,*)
      write(iw,*)'  *****  options available  *****'
      write(iw,*)
      write(iw,*)' ccsd (default)'
c      write(iw,*)'  CCD    =   ccd'
c      write(iw,*)'  MP4T   =   mp4 + mp5 triples'
      write(iw,*)' ccsd(t)'
c      write(iw,*)'  CCDT   =   ccd + t(ccd)'
      write(iw,*)' qcisd'
      write(iw,*)' qcisd(t)'
      write(iw,*)
      write(iw,6059) option
 6059 format(' **** option =  ',a8)
c
c
c  allocate core for integer work arrays
c
      flov = 1
      fpbka = flov + nirred*4
      fpbkb = fpbka + nbka + 1
      fpbkc = fpbkb + nbkb + 1
      fpbkd1 = fpbkc + nbkc + 1
      fpbkd2 = fpbkd1 + nbkd1 + 1
      fpbkd3 = fpbkd2 + nbkd2 + 1
      fpbke1 = fpbkd3 + nbkd3 + 1
ctjl  fpbke2 = fpbke1 + nbke1 + 1
      fpbkf = fpbke1 + nbke1 + 1
      npr = fpbkf + nbkf + 1
      fsec = npr + nirred*3*2
      orbsym = fsec + nlist
      itriv = orbsym + nbf
      itrio = itriv + ntriv
      isqvv = itrio + ntrio
      isqoo = isqvv + nsqvv
      isqov = isqoo + nsqoo
      isqvo = isqov + nsqov
      ioff = isqvo + nsqov
      ifa = ioff + nbf
      ifa2 = ifa + nirred
      ifb = ifa2 + nirred
      ifc = ifb + nirred
      ifd1 = ifc + nirred
      ifd2 = ifd1 + nirred
      ifd3 = ifd2 + nirred
      ifd4 = ifd3 + nirred
      ife1 = ifd4 + nirred
ctjl  ife2 = ife1 + nirred
      iff = ife1 + nirred
      ptocc = iff + nirred
      ntr  = ptocc + nbf
      ioovvt = ntr + nirred*4
      ivvoot = ioovvt + nirred + 1
      ivooot = ivvoot + nirred + 1
      iooovt = ivooot + nirred + 1
      ioovv = iooovt + nirred + 1
      ivvoo = ioovv + nirred*nirred
      ivooo = ivvoo + nirred*nirred
      iooov = ivooo + nirred*nirred
      e = iadtwp(iooov+nirred*nirred)
      top = wpadti(e+nbf)
      write(iw,7001) top,iadtwp(top)
      if(iadtwp(top).gt.maxcor) then
        write(iw,*)' not enough core: top,maxcor = ',iadtwp(top),maxcor
        call caserr('insufficient memory')
c      else 
c        call getmem(cc,top) 
      end if
c
c  read in file57 information for the coupled cluster calculation
c
      call read57(ic(flov),ic(fpbka),ic(fpbkb),ic(fpbkc),ic(fpbkd1),
     1            ic(fpbkd2),ic(fpbkd3),ic(fpbke1),ic(fpbkf),
     2            ic(npr),ic(fsec),ic(orbsym),cc(e),pt57,ic(itriv),
     3            ic(itrio),ic(isqvv),ic(isqoo),ic(isqov),ic(ioff),
     4            ic(ifa),ic(ifb),ic(ifc),ic(ifd1),ic(ifd2),ic(ifd3),
     5            ic(ifd4),ic(ife1),ic(iff),ic(ptocc),
     6            ic(isqvo),ic(ifa2))
c
c  set up arrays for triple compound indices
c
      call ccsetup(ic(flov),ic(npr),ic(ntr),ic(ioovv),ic(ivvoo),
     1           ic(ivooo),ic(iooov),ic(ioovvt),ic(ivvoot),ic(ivooot),
     2           ic(iooovt))
c
c  allocate core for real arrays
c
      buf = iadtwp(top)
      ibuf = wpadti(buf)
      t2 = buf + lnbkt
      tau = t2 + ndimw
      t1o = tau + ndimw
      t1n = t1o + ndimt1
      w1 = t1n + ndimt1
      w2 = w1 + max(nsqoo,nsqvv)
      rcc = w2 + max(nsqoo,nsqvv)
      bb = rcc + maxdim
      bb2 = bb + (maxdim+1)*(maxdim+2)
      top2 = bb2 + (maxdim+1)*(maxdim+2)
c
c  core check
c
      if(top2.gt.maxcor) then
      write(iw,*) ' not enough core: top2,maxcor = ',top2,maxcor
      call caserr('insufficient memory')
c      else 
c        call getmem(cc,top2)
      end if
ctjl  if(fldiis.eq.2)then
ctjl  diisfl=2
ctjl  end if
      write(iw,6008)
 6008 format('diis will be used to extrapolate t1 and t2 ')
      diisfl=1
      write(iw,6001) maxcor,top2
c
c********closed-shell coupled cluster calculation
c
      if(option.eq.'chek') stop ' check'
      call rfile(itap98)
      call rfile(itap99)
      if(iopt.eq.2) go to 200
c
c      call tset(iw)
c
c      call getcpus
      call deltt(0,' ccsd calculation ')
      call ampltd(cc(buf),ic(ibuf),cc(t2),cc(tau),cc(t1o),cc(t1n),
     1            cc(e),ic(fpbka),ic(fpbkb),ic(fpbkc),ic(fpbkd2),
     2            ic(fpbkd2),ic(fpbkd3),ic(fpbke1),
     3            ic(fpbkf),ic(npr),ic(ioff),ic(itriv),ic(itrio),
     4            ic(isqvv),ic(isqoo),ic(isqov),ic(ifa),ic(ifb),
     5            ic(ifc),ic(ifd1),ic(ifd2),ic(ifd3),ic(ifd4),ic(ife1),
     6            ic(iff),ic(flov),ic(fsec),ic(isqvo),ic(ifa2),
     7            ic(ioovvt),ic(ivvoot),ic(ivooot),ic(iooovt),ic(ioovv),
     8            ic(ivvoo),ic(ivooo),ic(iooov),ic(ntr),
     9            cc(w1),cc(w2),escf,cc(rcc),cc(bb),cc(bb2),eccsd,iopt)
      call deltt(1,' ccsd calculation ')
c      call relcpus
c
  200 continue
      write(iw,6074)
      write(iw,6071) escf
      write(iw,6072) eccsd
      escf = escf + eccsd
      write(iw,6073) escf
 6074 format(1x,'calculation results'/
     +       1x,'*******************')
 6071 format(1x,'scf   energy = ',f30.15)
 6072 format(1x,'corr  energy = ',f30.15)
 6073 format(1x,'total energy = ',f30.15)
c
c      call trset(iw)
c
c  analyze the t1 vector 
c
      t1 = iadtwp(top)
      w1 = t1 + ndimt1
      w2 = w1 + no*no
      w3 = w2 + nv*nv
      u = w3 + ndimt1
      v = u + no*no
c
ctjl  call anlyz(cc(t1),cc(w1),cc(w2),cc(w3),ic(flov))
c
c  evaluate triples contribution if desired
c
      if(iopt.eq.2.or.iopt.eq.3.or.iopt.eq.4.or.iopt.eq.6) then
c
      if (oldtrp.ne.0) then
      call deltt(0,' old triples ')
      write(*,*)
      write(*,*)' original triples calculation '
      write(*,*)
      iff2 = top
      ife2 = iff2 + nirred + 1
      buf1 = iadtwp(ife2+nirred+1)
      buf2 = buf1 + max(lnbkt,ndimw)
      w1 = buf2 + ndimw
c
      call settr(ic(iff2),ic(ife2),ic(npr),ndimf,ndime,cc(buf1),
     1           cc(buf2),cc(w1),ic(ioff),ic(isqoo),ic(isqvv),ic(isqov),
     2           ic(flov),ic(itriv),ic(ifd2),ic(ifd4),ic(fpbkd2))
c
      itrsqv = ife2 + nirred + 1
      itrsqo = itrsqv + nsqvv 
      fints = iadtwp(itrsqo+nsqoo)
      eints = fints + ndimf
      buf = eints + ndime
      top1 = buf + lnbkt
c
c  allocate for trps
c
      t1 = eints + ndime
      t2 = t1 + ndimt1
      t3 = t2 + ndimw
      dints = t3 + nsqoo*no
      top2 = dints + ndimw
      top = max(top1,top2)
c
      write(*,*)
      write(*,*)
      write(*,*) '     before triples: top = ',top
      write(*,*)
      if(top.gt.maxcor) then
      write(*,*)' before trps: top too big; top,maxcor = ',top,maxcor
      write(*,*) '  top1,top2 = ',top1,top2
      return
c      else 
c        call getmem(cc,top) 
      end if
c
c  read in fints
c
      call rdf(cc(fints),cc(buf),ic(ioff),ic(itriv),ic(isqov),
     1         ic(npr),ic(flov),ic(fpbkf),ic(isqvv),ic(iff2))
c
c  read in eints
c
      call rde(cc(eints),cc(buf),ic(npr),ic(flov),ic(isqov),ic(itrio),
     1         ic(ife2),ic(fpbke1),ic(ioff))
c
      call trps(cc(t2),cc(fints),cc(eints),cc(e),ic(isqoo),ic(npr),
     1          ic(flov),ic(isqov),ic(itrsqv),ic(itrsqo),ic(itriv),
     2          ic(itrio),ic(ifd2),ic(iff2),ic(ife2),ic(orbsym),cc(t3),
     3          ic(fpbkc),ic(ioff),ic(ifc),ndimf,ndime,ic(ifd4),
     4          ic(isqvv),escf,cc(t1),cc(dints),iopt)
c
      call deltt(1,' old triples ')
      endif
c
      write(iw,8765)
 8765 format(/,2x,60(1h*),/,2x,1h*,7x,'triples calculation ',
     &       '- apr and tjl december 90',6x,1h*,/,2x,60(1h*),/)
      if (grad) write(iw,8766)
 8766 format(' intermediates for triples gradient evaluated ',/)
c
      if (debug.gt.0) then
        t1 = top
        t2 = t1 + ndimt1
        buf1 = t2 + ndimw
        print *,' calling putdata'
        call putdata(ic(fsec),ic(flov),ic(npr),cc(t1),cc(t2),cc(buf1),
     &               cc(e))
      endif
c
c      call tset(iw)
      call deltt(0,' triples ')
      iovvvt = top
      iovvv  = iovvvt + nirred
      novvvt = iovvv  + nirred*nirred
      idx1   = novvvt + nirred
      idx2   = idx1   + nsqvv
      jdx1   = idx2   + nsqvv
      jdx2   = jdx1   + nirred*nirred
      t1 = iadtwp(jdx2+nirred*nirred)
      t2 = t1 + ndimt1
      tmp2 = t2 + ndimw
      topx = tmp2 + ndimw
c
      if (topx.gt.maxcor) then
        write(*,*)' memory before nsettr: topx,maxcor = ',topx,maxcor
        return
      endif
c
      call nsettr(cc(t1),cc(t2),cc(tmp2),ic(flov),ic(npr),ic(isqoo),
     &            ic(isqvv),ic(iovvvt),ic(iovvv),ic(novvvt),ic(ifd4),
     &            ndimd,ndime,ndimf,mxv3,iopt)
c
      if (.not.grad) then
      fints = tmp2
      dints = fints + ndimf
      eints = dints + ndimd
      buf1  = eints + ndime
      top1  = buf1  + lnbkt
      buf2  = buf1 + mxv3
      top2  = buf2 + mxv3
      topx = max(top1,top2)
c
c      print *,' force out of core triples'
c      topx=maxcor+1
c      maxcor=topx-500
c
      if (topx.lt.maxcor) then
        incore = 1
        write(iw,1921) topx
 1921   format(/,' triples performed in core - total memory:',i10)
c        call getmem(cc,topx) 
      else
        incore = 2
        istrt = wpadti(tmp2)
        fints = iadtwp(istrt+no)
        dints = fints + 3*mxv3
        eints = dints + ndimd
        buf1  = eints + ndime
        top1  = buf1 + lnbkt
        buf2  = buf1 + mxv3
        top2  = buf2 + mxv3
        topx = max(top1,top2)
c        print *,' force out of core triples - 3 buffers'
c        topx=maxcor+1
        if (topx.gt.maxcor) then
          incore = 3
          istrt = wpadti(tmp2)
          fints = iadtwp(istrt+no)
          dints = fints + mxv3
          eints = dints + ndimd
          buf1  = eints + ndime
          top1  = buf1 + lnbkt
          buf2  = buf1 + mxv3
          top2  = buf2 + mxv3
          topx = max(top1,top2)
ctjl **** implement 2 buffer version of triples energy ****
c  force two buffer version
c        print *,' force out of core triples - 2 buffers'
c         topx = maxcor + 1
          if (topx.gt.maxcor) then
            incore = 4
            istrt = wpadti(tmp2)
            fints = iadtwp(istrt+no)
            dints = iadtwp(istrt+no)
            eints = dints + ndimd
            buf1  = eints + ndime
            top1  = buf1 + lnbkt
            buf2  = buf1 + mxv3
            top2  = buf2 + mxv3
            topx = max(top1,top2)
            write(iw,1924) topx
 1924     format(/,' triples performed out of core - total memory:',i10,
     &           /,' 2 mxv3 buffers used',/)
          else
ctjl **** implement 2 buffer version of triples energy ****
          write(iw,1922) topx
 1922     format(/,' triples performed out of core - total memory:',i10,
     &           /,' 3 mxv3 buffers used',/)
          end if
        else
          write(iw,1923) topx
 1923     format(/,' triples performed out of core - total memory:',i10,
     &           /,' 5 mxv3 buffers used',/)
        endif
        if(topx.gt.maxcor) then
          write(*,*)' increase memory - before trps: topx,maxcor = ',
     &              topx,maxcor
          return
        end if
c        call getmem(cc,maxcor)
      endif
c
c -- read in fints
      if (incore.eq.1)then
        call icrdf(cc(fints),cc(buf1),ic(flov),ic(npr),ic(iovvvt),
     &             ic(iovvv),ic(novvvt),ic(fpbkf),ndimf)
      else
        ibin = wpadti(fints)
        ipos = ibin + 3*no
        bufy = iadtwp(ipos+nsqov)
        wrk  = bufy + lnbkt
        lwrk = maxcor - wrk
        if (lwrk.lt.2*mxv3)then
          print *,'out of space before ocrdf'
          call caserr('insufficient memory before ocrdf')
        endif
        call ocrdf(cc(bufy),ic(istrt),ic(ibin),ic(ipos),ic(flov),
     &             ic(npr),ic(novvvt),ic(fpbkf),mxv3,cc(wrk),lwrk)
      endif
c -- read in dints
      call nrdd(cc(dints),cc(buf1),ic(flov),ic(npr),ic(itrio),
     &          ic(isqvv),ic(ifd3),ic(fsec),ndimd)
c -- read in eints
      call nrde(cc(eints),cc(buf1),ic(flov),ic(npr),ic(isqoo),
     &          ic(isqov),ic(ife1),ic(fpbke1),ndime)
c
c -- evaluate triples
c      call getcpus
      if (incore.eq.1)then
        call ictrps(cc(t1),cc(t2),cc(dints),cc(eints),cc(fints),
     &              cc(buf1),cc(buf2),cc(e),ic(flov),ic(npr),
     &              ic(isqov),ic(isqvo),ic(isqoo),ic(isqvv),
     &              ic(iovvvt),ic(iovvv),ic(novvvt),ic(orbsym),
     &              ic(ifd4),ic(ife1),escf,iopt,ndimd,ndime,ndimf,
     &              mxv3,ic(idx1),ic(idx2),ic(jdx1),ic(jdx2),
     &              ic(itrio),ic(ifd3),debug)
      else if(incore.eq.2)then
        call octrp1(cc(t1),cc(t2),cc(dints),cc(eints),cc(fints),
     &              cc(buf1),cc(buf2),cc(e),ic(flov),ic(npr),
     &              ic(isqov),ic(isqvo),ic(isqoo),ic(isqvv),
     &              ic(iovvvt),ic(iovvv),ic(novvvt),ic(orbsym),
     &              ic(ifd4),ic(ife1),escf,iopt,ndimd,ndime,ndimf,
     &              mxv3,ic(idx1),ic(idx2),ic(jdx1),ic(jdx2),
     &              ic(istrt),ic(itrio),ic(ifd3),debug)
      else if(incore.eq.3)then
        call octrp2(cc(t1),cc(t2),cc(dints),cc(eints),cc(fints),
     &              cc(buf1),cc(buf2),cc(e),ic(flov),ic(npr),
     &              ic(isqov),ic(isqvo),ic(isqoo),ic(isqvv),
     &              ic(iovvvt),ic(iovvv),ic(novvvt),ic(orbsym),
     &              ic(ifd4),ic(ife1),escf,iopt,ndimd,ndime,ndimf,
     &              mxv3,ic(idx1),ic(idx2),ic(jdx1),ic(jdx2),
     &              ic(istrt),ic(itrio),ic(ifd3),debug)
      else if(incore.eq.4)then
        call octrp3(cc(t1),cc(t2),cc(dints),cc(eints),
     &              cc(buf1),cc(buf2),cc(e),ic(flov),ic(npr),
     &              ic(isqov),ic(isqvo),ic(isqoo),ic(isqvv),
     &              ic(iovvvt),ic(iovvv),ic(novvvt),ic(orbsym),
     &              ic(ifd4),ic(ife1),escf,iopt,ndimd,ndime,ndimf,
     &              mxv3,ic(idx1),ic(idx2),ic(jdx1),ic(jdx2),
     &              ic(istrt),ic(itrio),ic(ifd3),debug)
      else
        write(*,*) ' error in incore parameter ',incore
        return
      endif
c
      else
c
      fints = tmp2
      dints = fints + ndimf
      eints = dints + ndimd
      buf1  = eints + ndime
      top1  = buf1  + lnbkt
      buf2  = buf1 + mxv3
      top2  = buf2 + mxv3
      bufx  = fints
      eta   = max(fints+lnbkt,top2)
      zeta  = eta  + ndimt1
      epo   = zeta + ndimd
      epv   = epo  + no
      gam   = epv  + nv
      aaa   = gam  + ndimw
      ccc   = aaa  + ndimf
      top2  = ccc  + ndime
c
      topx = max(top1,top2)
c
c      print *,'  force out of core triples --- 8 buffers '
c      topx=maxcor+1
c      maxcor=topx-500
c
      if (topx.lt.maxcor) then
        incore = 1
        write(iw,2921) topx
 2921   format(/,' triples performed in core - total memory:',i10)
c        call getmem(cc,topx) 
      else
        write(iw,*) '  triples performed out-of-core   ',topx,maxcor
        incore = 2
        istrt = wpadti(tmp2)
        fints = iadtwp(istrt+no)
        dints = fints + 3*mxv3
        eints = dints + ndimd
        buf1  = eints + ndime
        top1  = buf1 + lnbkt
        buf2  = buf1 + mxv3
        top2  = buf2 + mxv3
        bufx  = fints
        eta   = max(top2,bufx+lnbkt)
        zeta  = eta  + ndimt1
        epo   = zeta + ndimd
        epv   = epo  + no
        gam   = epv  + nv
        aaa   = gam  + ndimw
        ccc   = aaa  + 3*mxv3
        top2  = ccc  + ndime
        topx = max(top1,top2)
c
c      print *,'  force out of core triples --- 3 buffers '
c      topx=maxcor+1
c      maxcor=topx-500
c
      if (topx.lt.maxcor) then
        write(iw,2922) topx
 2922   format(/,' triples performed out of core - total memory:',i10,
     &  /,'  8 mxv3 buffers used')
      else
        write(iw,*) '  triples performed out-of-core   ',topx,maxcor
        incore = 3
        istrt = wpadti(tmp2)
        dints = iadtwp(istrt+no)
c  equivalence fints with dints for allocation of core for ocrdf
        fints = dints
        eints = dints + ndimd
        buf1  = eints + ndime
        buf2  = buf1 + mxv3
        buf3  = buf2 + mxv3
        eta   = buf3 + mxv3
        zeta  = eta  + ndimt1
        epo   = zeta + ndimd
        epv   = epo  + no
        gam   = epv  + nv
        ccc   = gam  + ndimw
        topx  = ccc  + ndime
c
        write(iw,2923) topx
 2923   format(/,' triples performed out of core - total memory:',i10,
     &         /,'  3 mxv3 buffers used')
        if (topx.gt.maxcor) then
          write(iw,*)'  out of memory before trps: topx,maxcor = ',
     &              topx,maxcor
          return
        end if
      end if
c        call getmem(cc,maxcor)
      end if
c
c -- read in fints
      if (incore.eq.1) then
        call icrdf(cc(fints),cc(buf1),ic(flov),ic(npr),ic(iovvvt),
     &             ic(iovvv),ic(novvvt),ic(fpbkf),ndimf)
      else
        ibin = wpadti(fints)
        ipos = ibin + 3*no
        bufy = iadtwp(ipos+nsqov)
        wrk  = bufy + lnbkt
        lwrk = maxcor - wrk
        if (lwrk.lt.2*mxv3) then
          write(iw,*) '  out of space before ocrdf  ',lwrk,(mxv3*2)
          call caserr('insufficient memory before ocrdf')
        endif
        call ocrdf(cc(bufy),ic(istrt),ic(ibin),ic(ipos),ic(flov),
     &             ic(npr),ic(novvvt),ic(fpbkf),mxv3,cc(wrk),lwrk)
      endif
c -- read in dints
      call nrdd(cc(dints),cc(buf1),ic(flov),ic(npr),ic(itrio),
     &          ic(isqvv),ic(ifd3),ic(fsec),ndimd)
c -- read in eints
      call nrde(cc(eints),cc(buf1),ic(flov),ic(npr),ic(isqoo),
     &          ic(isqov),ic(ife1),ic(fpbke1),ndime)
c
c -- evaluate triples
c      call getcpus
      if (incore.eq.1) then
        call gictrps(cc(t1),cc(t2),cc(dints),cc(eints),cc(fints),
     &               cc(buf1),cc(buf2),cc(eta),cc(zeta),
     &               cc(epo),cc(epv),cc(gam),cc(aaa),cc(ccc),
     &               cc(e),ic(flov),ic(npr),
     &               ic(isqov),ic(isqvo),ic(isqoo),ic(isqvv),
     &               ic(iovvvt),ic(iovvv),ic(novvvt),ic(orbsym),
     &               ic(ifd4),ic(ife1),escf,iopt,ndimd,ndime,ndimf,
     &               mxv3,ic(idx1),ic(idx2),ic(jdx1),ic(jdx2),
     &               ic(itrio),ic(ifd3),debug)
        call ictp40(cc(eta),cc(zeta),cc(epo),cc(epv),cc(gam),
     &              cc(aaa),cc(ccc),cc(bufx),ic(flov),ic(npr),
     &              ic(iovvvt),ic(iovvv),ic(novvvt),ic(isqvv),
     &              ndimd,ndime,ndimf,mxv3)
      else
c
      if(incore.eq.2) then
c
        call goctrps(cc(t1),cc(t2),cc(dints),cc(eints),cc(fints),
     &               cc(buf1),cc(buf2),cc(eta),cc(zeta),
     &               cc(epo),cc(epv),cc(gam),cc(aaa),cc(ccc),
     &               cc(e),ic(flov),ic(npr),
     &               ic(isqov),ic(isqvo),ic(isqoo),ic(isqvv),
     &               ic(iovvvt),ic(iovvv),ic(novvvt),ic(orbsym),
     &               ic(ifd4),ic(ife1),escf,iopt,ndimd,ndime,ndimf,
     &               mxv3,ic(idx1),ic(idx2),ic(jdx1),ic(jdx2),
     &               ic(istrt),ic(itrio),ic(ifd3),debug)
c
      else
c
        call goct3(cc(t1),cc(t2),cc(dints),cc(eints),cc(buf1),
     &               cc(buf2),cc(buf3),cc(eta),cc(zeta),
     &               cc(epo),cc(epv),cc(gam),cc(ccc),
     &               cc(e),ic(flov),ic(npr),
     &               ic(isqov),ic(isqvo),ic(isqoo),ic(isqvv),
     &               ic(iovvvt),ic(iovvv),ic(novvvt),ic(orbsym),
     &               ic(ifd4),ic(ife1),escf,iopt,ndimd,ndime,ndimf,
     &               mxv3,ic(idx1),ic(idx2),ic(jdx1),ic(jdx2),
     &               ic(istrt),ic(itrio),ic(ifd3),debug)
c
      end if
c
        jstrt = istrt + no
        ibin = jstrt + nv
        ipos = ibin + nv*3
        buf1 = iadtwp(ipos+no*nv)
        lbuf = max(lnbkt,mxv3)
        buf2 = buf1 + lbuf
        wrk = buf2 + lbuf
        lwrk = maxcor - wrk
c
        call octp40(cc(eta),cc(zeta),cc(epo),cc(epv),cc(gam),
     &              cc(ccc),ic(flov),ic(npr),ic(ntr),ic(novvvt),
     &              ic(iovvv),ic(isqvv),cc(buf1),cc(buf2),lbuf,
     &              ic(istrt),ic(jstrt),ic(ibin),ic(ipos),cc(wrk),
     &              lwrk,ndimd,ndime,ndimf)
      endif
c      call relcpus
      endif
c
c      call trset(iw)
       call deltt(1,' triples ')
      end if
C
C  write final energy to tape57
c
      ic(1)=nirred
      ic(2)=nbf
      ic(3)=no
      ic(4)=nv
      ic(5)=ntriv
      ic(6)=ntrio
      ic(7)=nsqvv
      ic(8)=nsqoo
      ic(9)=nsqov
      ic(10)=lnbkt
      ic(11)=nlist
      ic(12)=nbka
      ic(13)=nbkb
      ic(14)=nbkc
      ic(15)=nbkd1
      ic(16)=nbkd2
      ic(17)=nbkd3
      ic(18)=nbke1
      ic(19)=nbkf
      ic(20)=ndimt1
      ic(21)=ndimt2
      ic(22)=norbs
      ic(23)=ndimw
      junk = numint/intowp(1) + 1
      cc(junk)=escf
      cc(junk+1)=enuc
      write(6,1982)escf
 1982 format(' total energy written to 57 ',f20.10)
c
      numint = 24
      junk = numint + intowp(2)
      call wwritw(itap57,ic,junk,1,pt57)
c
      call rclose(itap57,3)
c
c  close files and return
c
      call rclose(itap60,3)
      call rclose(itap61,3)
      call rclose(itap62,3)
      call rclose(itap63,3)
      call rclose(itap64,3)
      call rclose(itap65,3)
      call rclose(itap69,3)
      call rclose(itap98,4)
      call rclose(itap99,4)
c
c      igrad=20
c      write(6,1930)escf
c 1930 format(/' energy written to optim.coord ',f20.12,/)
c
c      open(unit=igrad,file='optim.coord')
c 1910 continue
c      read(igrad,*,end=1900)
c      goto 1910
c 1900 continue
c      write(igrad,1200)escf
c 1200 format(' block = scf_energy records = 1 index =   1',/,
c     &       1x,f20.12)
c      close(igrad)
c
c
 6000 format(/
     +10x,'**********************************************'/
     +10x,'**   Closed-shell coupled cluster module    **'/
     +10x,'**   T.J. Lee, J.E. Rice and A.P. Rendell   **'/
     +10x,'**********************************************'/)
 6001 format('   maximum  core = ',i20,' real words ',/,
     1       '   required core = ',i20,' real words ')
 7001 format('   integer arrays take up ',i10,'  words or ',i10,
     1          '  real words ')
      return
      end
      subroutine cceng(t2,buf,fpbkc,eccsd,escf,npr)
      implicit integer(a-z)
      integer fpbkc(nbkc),npr(nirred,3,2)
      REAL t2(ndimw),buf(lnbkt),eccsd,escf,etot,a0
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
INCLUDE(common/t_iter)
c
      data a0 /0.0d0/
c
      call srew(itap63)
      ibkc = 0
      nbeu = 1
      off2 = 0
      eccsd = a0
c
      do 10 busym = 1,nirred
      lngav = npr(busym,3,2)
      numbeu = lngav
c
      if(lngav.ne.0) then
c
   30 if(nbeu.eq.fpbkc(ibkc+1)) then
      ibkc = ibkc + 1
      off1 = 0
      fbeu = fpbkc(ibkc)
      if(ibkc.eq.nbkc) then
      lbeu = nsqov
      else
      lbeu = fpbkc(ibkc+1) - 1
      end if
      call tit_sread(itap63,buf,intowp(lnbkt))
      end if
c
      lnbeu = lbeu - nbeu + 1
      if(lnbeu.gt.numbeu) lnbeu = numbeu
      leng = lnbeu*lngav
      do 20 ijab = 1,leng
      add1 = off1 + ijab
      add2 = off2 + ijab
      eccsd = eccsd + buf(add1)*t2(add2)
   20 continue
      off1 = off1 + leng
      off2 = off2 + leng
      numbeu = numbeu - lnbeu
      nbeu = nbeu + lnbeu
      if(numbeu.ne.0) go to 30
      end if
   10 continue
c
      etot = escf + eccsd
_IF1()      write(iw,90) escf,eccsd,etot
_IF1()   90 format(/'  escf  = ',f30.15,
_IF1()     1       /'  eccsd = ',f30.15,
_IF1()     2       /'  etot  = ',f30.15)
c
      return
      end
      subroutine ccsetup(flov,npr,ntr,ioovv,ivvoo,ivooo,iooov,ioovvt,
     1                 ivvoot,ivooot,iooovt)
      implicit integer(a-z)
      integer flov(nirred,4),ioovv(nirred,nirred),ioovvt(nirred+1)
      integer ivvoo(nirred,nirred),ivvoot(nirred+1),ivooot(nirred+1)
      integer ivooo(nirred,nirred),iooov(nirred,nirred)
      integer iooovt(nirred+1)
      integer npr(nirred,3,2),ntr(nirred,4)
c
INCLUDE(common/t_parm)
c
      nirr2 = nirred*nirred
c
c  determine the number of csfs in this calculation
c
      csf = ndimt1
      do 11 irr = 1,nirred
      csf = csf + (npr(irr,3,2)+1)*npr(irr,3,2)/2
  11  continue
      write(*,*)
      write(*,*) '  total number of configurations = ',csf
      write(*,*)
c
c  set up ioovv and ioovvt arrays
c  indices are ordered as: (o,vv:o)
c  also set up the ovv component of the ntr array
c
      call tit_izo(ioovv,nirr2)
      call tit_izo(ioovvt,nirred+1)
      do 10 isym = 1,nirred
      ioovvt(isym+1) = ioovvt(isym)
      ni = flov(isym,2) - flov(isym,1) + 1
      do 20 bgsym = 1,nirred
      usym = IXOR32(isym-1,bgsym-1) + 1
      nu = flov(usym,2) - flov(usym,1) + 1
      if(bgsym.ne.nirred)
     1 ioovv(bgsym+1,isym) = ioovv(bgsym,isym) + npr(bgsym,2,2)*nu
      ioovvt(isym+1) = ioovvt(isym+1) + npr(bgsym,2,2)*nu*ni
   20 continue
      usym = IXOR32(isym-1,nirred-1) + 1
      nu = flov(usym,2) - flov(usym,1) + 1
      ntr(isym,1) = ioovv(nirred,isym) + npr(nirred,2,2)*nu
   10 continue
c
c  set up ivvoo and ivvoot arrays
c  indices are ordered as: (v,oo:v)
c
      call tit_izo(ivvoo,nirr2)
      call tit_izo(ivvoot,nirred+1)
      do 30 besym = 1,nirred
      ivvoot(besym+1) = ivvoot(besym)
      nbe = flov(besym,4) - flov(besym,3) + 1
      do 40 uvsym = 1,nirred
      gasym = IXOR32(besym-1,uvsym-1) + 1
      nga = flov(gasym,4) - flov(gasym,3) + 1
      if(uvsym.ne.nirred)
     1 ivvoo(uvsym+1,besym) = ivvoo(uvsym,besym) + npr(uvsym,1,2)*nga
      ivvoot(besym+1) = ivvoot(besym+1) + npr(uvsym,1,2)*nga*nbe
   40 continue
   30 continue
c
c  set up ivooo and ivooot arrays
c  indices are ordered as: (o,oo:v)
c  and the ooo component of ntr
c
      call tit_izo(ivooo,nirr2)
      call tit_izo(ivooot,nirred+1)
      do 50 besym = 1,nirred
      ivooot(besym+1) = ivooot(besym)
      nbe = flov(besym,4) - flov(besym,3) + 1
      do 60 uvsym = 1,nirred
      usym = IXOR32(besym-1,uvsym-1) + 1
      nu = flov(usym,2) - flov(usym,1) + 1
      if(uvsym.ne.nirred)
     1 ivooo(uvsym+1,besym) = ivooo(uvsym,besym) + npr(uvsym,1,2)*nu
      ivooot(besym+1) = ivooot(besym+1) + npr(uvsym,1,2)*nu*nbe
   60 continue
      usym = IXOR32(besym-1,nirred-1) + 1
      nu = flov(usym,2) - flov(usym,1) + 1
      ntr(besym,3) = ivooo(nirred,besym) + npr(nirred,1,2)*nu
   50 continue
c
c  set up iooov and iooovt arrays
c  indices are ordered as: (v,oo:o)
c  also set up the oov component of ntr
c
      call tit_izo(iooov,nirr2)
      call tit_izo(iooovt,nirred+1)
      do 70 isym = 1,nirred
      iooovt(isym+1) = iooovt(isym)
      ni = flov(isym,2) - flov(isym,1) + 1
      do 80 bgsym = 1,nirred
      asym = IXOR32(isym-1,bgsym-1) + 1
      na = flov(asym,4) - flov(asym,3) + 1
      if(bgsym.ne.nirred)
     1 iooov(bgsym+1,isym) = iooov(bgsym,isym) + npr(bgsym,1,2)*na
      iooovt(isym+1) = iooovt(isym+1) + npr(bgsym,1,2)*na*ni
   80 continue
      asym = IXOR32(isym-1,nirred-1) + 1
      na = flov(asym,4) - flov(asym,3) + 1
      ntr(isym,2) = iooov(nirred,isym) + npr(nirred,1,2)*na
   70 continue
c
c  print the arrays out!
c
      itest = 0
      if(itest.eq.0) return
      do 90 jki = 1,nirred
      write(6,*) ' isym,ioovv ',jki,(ioovv(jkl,jki),jkl=1,nirred)
   90 continue
      write(*,*) ' ioovvt = ',ioovvt
      do 91 jki = 1,nirred
      write(6,*) ' isym,ivvoo ',jki,(ivvoo(jkl,jki),jkl=1,nirred)
   91 continue
      write(*,*) ' ivvoot = ',ivvoot
      do 92 jki = 1,nirred
      write(6,*) ' isym,ivooo ',jki,(ivooo(jkl,jki),jkl=1,nirred)
   92 continue
      write(*,*) ' ivooot = ',ivooot
      do 93 jki = 1,nirred
      write(6,*) ' isym,iooov ',jki,(iooov(jkl,jki),jkl=1,nirred)
   93 continue
      write(*,*) ' iooovt = ',iooovt
      write(6,*) ' ntr ',ntr
      return
      end
      subroutine deltt(iparm,label)
      integer iparm
      character*(*) label
      REAL tcp0,tsy0,tel0,tcp1,tsy1,tel1
      save tcp0,tsy0,tel0
      if (iparm.eq.0)then
        call cputimer(tcp0,tsy0,tel0)
      else
        call cputimer(tcp1,tsy1,tel1)
        ln=len(label)
        write(6,99)label(1:ln),tcp1-tcp0,tsy1-tsy0,tel1-tel0
 99     format(/
     +     10x,26('-')/
     +     10x,'timing information: '/
     +     10x,a/
     +     10x,26('-')/
     +     10x,'cpu time     ',f12.2/
     +     10x,'system time  ',f12.2/
     +     10x,'elapsed time ',f12.2/
     +     10x,26('-')/)
      endif
      return
      end
      subroutine cputimer(tcpu,tsys,telp)
      implicit REAL  (a-h,o-z)
      dimension cpubuf(3)
      call walltime(telp)
      call gms_cputime(cpubuf)
      tcpu = cpubuf(1)
      tsys = cpubuf(2)
      end

      subroutine d1t1(t2,t1o,w1,t1n,isqoo,ntr,flov,iooov,iooovt,
     1                isqov)
      implicit integer(a-z)
      integer flov(nirred,4),isqoo(nsqoo),iooov(nirred,nirred),
     1  iooovt(nirred),ntr(nirred,2),isqov(nsqov)
      REAL t2(ndimw),t1o(ndimt1),t1n(ndimt1),w1(ndimt1)
      REAL a1
c
INCLUDE(common/t_parm)
      character *1 xn
      data xn / 'n'/
      data a1/1.0d00/
c
c  take t2(be,iu:v) and
c  add d1 contributions to t1n
c
      call vclr(w1,1,ndimt1)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      nbe = lbe - fbe + 1
      fu = flov(besym,1)
      lu = flov(besym,2)
      do 20 be = fbe,lbe
      do 30 u = fu,lu
      ube = isqov((be-1)*no+u)
      do 40 isym = 1,nirred
      uisym = IXOR32(besym-1,isym-1) + 1
      iof = iooovt(isym) + iooov(uisym,isym) + be - fbe + 1
      fi = flov(isym,1)
      li = flov(isym,2)
      do 50 i = fi,li
      biui = (isqoo((u-1)*no+i)-1)*nbe + (i-fi)*ntr(isym,2) + iof
      w1(ube) = t2(biui) + w1(ube)
   50 continue
   40 continue
   30 continue
   20 continue
   10 continue
c
      do 60 jki = 1,ndimt1
      t1n(jki) = t1n(jki) - w1(jki) - w1(jki)
   60 continue
c
c
c
      call vclr(w1,1,nsqoo)
      do 70 vsym = 1,nirred
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      fi = flov(vsym,1)
      li = flov(vsym,2)
      do 80 v = fv,lv
      vof = iooovt(vsym) + (v-fv)*ntr(vsym,2)
      do 90 i = fi,li
      iv = isqoo((i-1)*no + v)
      do 100 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      bvsym = IXOR32(besym-1,vsym-1) + 1
      bvof = vof + iooov(bvsym,vsym)
      nbe = lbe - fbe + 1
      fu = flov(besym,1)
      lu = flov(besym,2)
      do 110 be = fbe,lbe
      bvoff = bvof + be - fbe + 1
      do 120 u = fu,lu
      ube = isqov((be-1)*no + u)
      biuv = (isqoo((u-1)*no+i)-1)*nbe + bvoff
      buiv = (isqoo((i-1)*no+u)-1)*nbe + bvoff
      w1(iv) = w1(iv) - (t2(biuv) + t2(biuv) - t2(buiv))*t1o(ube)
  120 continue
  110 continue
  100 continue
   90 continue
   80 continue
   70 continue
c
      off1 = 1
      off2 = 1
      do 200 isym = 1,nirred
      lni = flov(isym,2) - flov(isym,1) + 1
      lnbe = flov(isym,4) - flov(isym,3) + 1
      if(lni.ne.0.and.lnbe.ne.0) then
_IF1()c      call mxmb(w1(off1),1,lni,t1o(off2),1,lni,t1n(off2),1,lni,lni,
_IF1()c     1          lni,lnbe)
      call dgemm(xn,xn,lni,lnbe,lni
     +           ,a1,w1(off1),lni,t1o(off2),lni
     +           ,a1,t1n(off2),lni)
      end if
      off1 = off1 + lni*lni
      off2 = off2 + lni*lnbe
  200 continue
c
      return
      end
      subroutine diis(t1o,t1n,t2,tau,it,cc,bb,itc,bb2,rms)
      implicit integer (a-z)
convexreal*16 det
      REAL det
      REAL t2(ndimt2),tau(ndimt2),t1o(ndimt1),t1n(ndimt1),cc(maxdim)
      REAL bb(maxdim+1,maxdim+2),bb2(maxdim+1,maxdim+2)
      REAL a0,a1,xm,xmax,xen,xfac,xadd,rms,sum1,sum2
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
INCLUDE(common/t_iter)
c
      data a0,a1 /0.0d0,1.0d0/
c
c     diis extrapolation
c
      it = it + 1
      if(it.gt.maxdim) it = maxdim
      itc = itc + 1
      if(itc.gt.maxdim) itc = 1
c
      sum1 = a0
      sum2 = a0
      do 10 ia = 1,ndimt1
      t1o(ia) = t1n(ia) - t1o(ia)
      sum1 = sum1 + t1o(ia)
      sum2 = sum2 + t1o(ia)*t1o(ia)
   10 continue
c
      pt1 = (itc-1)*intowp(ndimt1 + ndimt2) + 1
      pt2 = pt1 + intowp(ndimt1)
      call wwritw(itap99,t1o,intowp(ndimt1),pt1,junk)
      call wwritw(itap98,t1n,intowp(ndimt1),pt1,junk)
c
      do 20 uvbg = 1,ndimt2
      t2(uvbg) = tau(uvbg) - t2(uvbg)
      sum1 = sum1 + t2(uvbg)
      sum2 = sum2 + t2(uvbg)*t2(uvbg)
   20 continue
      rms = dsqrt(dabs(sum2-(sum1*sum1)))
c
      call wwritw(itap99,t2,intowp(ndimt2),pt2,junk)
      call wwritw(itap98,tau,intowp(ndimt2),pt2,junk)
c
      do 30 n = 1,it
c
      pt1 = (n-1)*intowp(ndimt1 + ndimt2) + 1
      pt2 = pt1 + intowp(ndimt1)
      call wreadw(itap99,t1n,intowp(ndimt1),pt1,junk)
      call wreadw(itap99,tau,intowp(ndimt2),pt2,junk)
c
      bb2(n,itc) = a0
c
      do 40 ia = 1,ndimt1
      bb2(n,itc) = bb2(n,itc) + t1n(ia)*t1o(ia)
   40 continue
c
      do 50 uvbg = 1,ndimt2
      bb2(n,itc) = bb2(n,itc) + tau(uvbg)*t2(uvbg)
   50 continue
      bb2(itc,n) = bb2(n,itc)
c
   30 continue
c
c  transfer into the bb array
c
      do 60 n = 1,it
      do 70 m = 1,n-1
      bb(n,m) = bb2(n,m)
      bb(m,n) = bb2(m,n)
  70  continue
      bb(n,n) = bb2(n,n)
  60  continue
c
c  find the maximum and scale
c
      xm = dabs(bb(1,1))
      do 80 n = 1,it
      do 90 m = 1,n
      xfac = dabs(bb(n,m))
      xmax = dmax1(xm,xfac)
      xm = xmax
   90 continue
   80 continue
c
      xm = a1/xm
      do 100 n = 1,it
      do 110 m = 1,it
      bb(n,m) = bb(n,m)*xm
  110 continue
  100 continue
c
      it1 = it+1
      it2 = it+2
      do 120 n = 1,it
      bb(n,it1) = -a1
      bb(it1,n) = -a1
  120 continue
c
      bb(it1,it1) = a0
      do 130 n = 1,it
      bb(n,it2) = a0
  130 continue
      bb(it1,it2) = -a1
c
      call flinq(bb,9,it1,1,det)
c     write(iw,*)'det=',det
      xadd = a0
      do 140 n = 1,it
      cc(n) = bb(n,it2)
      xadd = xadd + cc(n)
c     write(iw,*)'n=',n,'cc(n)=',cc(n)
  140 continue
      xen = bb(it1,it2)*xm
      xen = dsqrt(xen)
c     write(iw,*)'csum=',xadd
c     write(iw,*)'  xen = ',xen,'  xon = ',xon
c
      call vclr(t1n,1,ndimt1)
      call vclr(tau,1,ndimt2)
c
      do 150 n = 1,it
c
      pt1 = (n-1)*intowp(ndimt1 + ndimt2) + 1
      pt2 = pt1 + intowp(ndimt1)
      call wreadw(itap98,t1o,intowp(ndimt1),pt1,junk)
      call wreadw(itap98,t2,intowp(ndimt2),pt2,junk)
c
      do 160 ia = 1,ndimt1
      t1n(ia) = t1n(ia) + cc(n)*t1o(ia)
  160 continue
c
      do 170 uvbg = 1,ndimt2
      tau(uvbg) = tau(uvbg) + cc(n)*t2(uvbg)
  170 continue
c
  150 continue
      return
      end
      subroutine divt1(flov,t1,e)
      implicit integer(a-z)
      integer flov(nirred,4)
      REAL e(nbf),t1(ndimt1),d
c
INCLUDE(common/t_parm)
c
      icnt = 0
      do 10 besym = 1,nirred
      fbe = flov(besym,3)
      lbe = flov(besym,4)
      fu = flov(besym,1)
      lu = flov(besym,2)
      do 20 be = fbe,lbe
      do 30 u = fu,lu
      d = e(be) - e(u)
      icnt = icnt + 1
      t1(icnt) = t1(icnt) / d
   30 continue
   20 continue
   10 continue
c
      return
      end
      subroutine divt2(flov,t2,e)
      implicit integer(a-z)
      integer flov(nirred,4)
      REAL e(nbf),t2(ndimt2),d
c
INCLUDE(common/t_parm)
c
c   divide t2 by eigenvalues
c
      icnt=0
      do 1001 asym=1,nirred
      fa=flov(asym,3)-no
      la=flov(asym,4)-no
      do 2001 a=fa,la
      do 3001 b=fa,a
      do 4001 isym=1,nirred
      fi=flov(isym,1)
      li=flov(isym,2)
      do 5001 i=fi,li
      do 6001 j=fi,li
      d=e(i)+e(j)-e(a+no)-e(b+no)
cj    write(6,*) ' i,j,a,b,ijab,buf ',i,j,a,b,ijab,buf(icnt)
      icnt=icnt+1
      t2(icnt)=t2(icnt)/d
6001  continue
5001  continue
4001  continue
3001  continue
2001  continue
1001  continue
      do 101 absym=2,nirred
      do 201 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      if(asym.gt.bsym) then
      fa=flov(asym,3)-no
      la=flov(asym,4)-no
      fb=flov(bsym,3)-no
      lb=flov(bsym,4)-no
      do 301 a=fa,la
      do 401 b=fb,lb
      do 501 isym=1,nirred
      jsym=IXOR32(isym-1,absym-1)+1
      fi=flov(isym,1)
      li=flov(isym,2)
      fj=flov(jsym,1)
      lj=flov(jsym,2)
      do 601 i=fi,li
      do 701 j=fj,lj
      d=e(i)+e(j)-e(a+no)-e(b+no)
      icnt=icnt+1
      t2(icnt)=t2(icnt)/d
701   continue
601   continue
501   continue
401   continue
301   continue
      end if
201   continue
101   continue
c
      return
      end
      SUBROUTINE DOTPR(A,B,N,D)
      implicit integer (A-Z)
      REAL  A(N),B(N),D
      D = 0.0D0
      DO 10 I = 1,N
      D = D + A(I)*B(I)
   10 CONTINUE
      RETURN
      END
      FUNCTION DOTT(A,NA,B,NB,N)
      implicit REAL (A-H,O-Z)
      DIMENSION A(1),B(1)
      DATA ZERO / 0.0D+00 /
C
      IAPT=1
      IBPT=1
      D=ZERO
      DO 10 I=1,N
      D=D+A(IAPT)*B(IBPT)
      IAPT=IAPT+NA
      IBPT=IBPT+NB
 10   CONTINUE
      DOTT=D
      RETURN
      END
      subroutine expd2p(t2,tau,ioff,itrio,isqoo,npr,flov,ifa,
     1  ifa2)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifa(nirred),
     1  ioff(nbf),itrio(ntrio),isqoo(nsqoo),ifa2(nirred)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  expand d2p  from d2p(v,u,j<i) to d2p(j,i,v,u)
c
      off2 = npr(1,1,2)
      do 10 isym = 1,nirred
      fi = flov(isym,1)
      li = flov(isym,2)
      do 20 i = fi,li
      do 30 j = fi,i-1
      ij = ioff(i) + j
      ijoff = (itrio(ij)-1)*off2
      ijq = (i-1)*no + j
      jiq = (j-1)*no + i
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      do 60 v = fu,lu
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvof = (isqoo(uv)-1)*off2
      vuof = (isqoo(vu)-1)*off2
      uvij = ijoff + isqoo(uv)
      ijuvq = uvof + isqoo(ijq)
      jivuq = vuof + isqoo(jiq)
      tau(ijuvq) = t2(uvij)
      tau(jivuq) = t2(uvij)
  60  continue
  50  continue
  40  continue
  30  continue
      ii = ioff(i) + i
      iioff = (itrio(ii)-1)*off2
      iiq = (i-1)*no + i
      do 70 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvof = (isqoo(uv)-1)*off2
      uvii = iioff + isqoo(uv)
      iiuvq = uvof + isqoo(iiq)
      tau(iiuvq) = t2(uvii)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 ijsym = 2,nirred
      off2 = npr(ijsym,1,2)
      do 21 isym = 1,nirred
      jsym = IXOR32(ijsym-1,isym-1) + 1
      if(isym.gt.jsym) then
      fi = flov(isym,1)
      li = flov(isym,2)
      fj = flov(jsym,1)
      lj = flov(jsym,2)
      do 31 i = fi,li
      do 41 j = fj,lj
      ij = ioff(i) + j
      ijoff = (itrio(ij)-1)*off2 + ifa2(ijsym)
      ijq = (i-1)*no + j
      jiq = (j-1)*no + i
      do 51 usym = 1,nirred
      vsym = IXOR32(usym-1,ijsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      do 71 v = fv,lv
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvof = (isqoo(uv)-1)*off2 + ifa(ijsym)
      vuof = (isqoo(vu)-1)*off2 + ifa(ijsym)
      uvij = ijoff + isqoo(uv)
      ijuvq = uvof + isqoo(ijq)
      jivuq = vuof + isqoo(jiq)
      tau(ijuvq) = t2(uvij)
      tau(jivuq) = t2(uvij)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine ext21(t2,tau,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,
     1  ifd4)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqvv(nsqvv),ifd4(nirred)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  expand t2 from t2(v,u,ga<be) to tau(v,u,ga,be)
c  starting from t2(v,u,ga<be) form:
c  [2*t2(v,u,ga,be) - t2(u,v,ga,be)] and store as:
c  t2(ga,be,v,u)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      bgq = isqvv((be-1)*nv + ga)
      gbq = isqvv((ga-1)*nv + be)
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      do 60 v = fu,lu
      vga = (ga-1)*no + v
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      gbvu = (isqoo(uv)-1)*npr(1,2,2) + bgq
      bguv = (isqoo(vu)-1)*npr(1,2,2) + gbq
      tau(gbvu) = t2(uvbg) + t2(uvbg) - t2(vubg)
      tau(bguv) = tau(gbvu)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      bbq = isqvv((be-1)*nv + be)
      do 70 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      do 90 v = fu,lu
      vbe = (be-1)*no + v
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bbvu = (isqoo(uv)-1)*npr(1,2,2) + bbq
      tau(bbvu) = t2(uvbb)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      do 41 ga = fga,lga
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      bgq = isqvv((be-1)*nv + ga) + ifd4(bgsym)
      gbq = isqvv((ga-1)*nv + be) + ifd4(bgsym)
      do 51 usym = 1,nirred
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      do 71 v = fv,lv
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      gbvu = (isqoo(uv)-1)*npr(bgsym,2,2) + bgq
      bguv = (isqoo(vu)-1)*npr(bgsym,2,2) + gbq
      tau(gbvu) = t2(uvbg) + t2(uvbg) - t2(vubg)
      tau(bguv) = tau(gbvu)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine ext22(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,
     1                  ifc,t1o)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifc(nirred),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqov(nsqov)
      REAL t2(ndimw),tau(ndimw),t1o(ndimt1)
      REAL t11,t12,fac1,fac2,a1,a2,a0
c
INCLUDE(common/t_parm)
c
      data a0,a1,a2 /0.0d0,1.0d0,2.0d0/
c
c  starting with t2(v,u,ga<be) form :
c  [2*tau(v,ga,u,be)-tau(v,be,u,ga)] and store as
c  tau(v,ga,u,be)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      beof = (be-1)*no
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gaof = (ga-1)*no
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      fac1 = a0
      if(usym.eq.besym) fac1 = a1
      do 50 u = fu,lu
      uga = isqov(gaof + u)
      busym = IXOR32(besym-1,usym-1) + 1
      beu = beof + u
      ube = isqov(beu)
      t11 = t1o(ube)*fac1
      t12 = t1o(uga)*fac1
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 60 v = fu,lu
      vbe = isqov(beof+v)
      gav = gaof + v
      vga = isqov(gav)
      gavof = (isqov(gav)-1)*npr(busym,3,2) + ifc(busym)
      vgub = beuof + isqov(gav)
      ubvg = gavof + isqov(beu)
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      tau(vgub) = a2*(t2(uvbg)+t11*t1o(vga)) - (t2(vubg)+t12*t1o(vbe))
      tau(ubvg) = tau(vgub)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      do 70 usym = 1,nirred
      fac1 = a0
      if(besym.eq.usym) fac1 = a1
      busym = IXOR32(besym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      beu = beof + u
      ube = isqov(beu)
      t11 = t1o(ube)*fac1
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bev = beof + v
      vbe = isqov(bev)
      ubvb = beuof + isqov(bev)
      tau(ubvb) = t2(uvbb) + t11*t1o(vbe)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      beof = (be-1)*no
      do 41 ga = fga,lga
      gaof = (ga-1)*no
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fac1 = a0
      if(usym.eq.besym) fac1 = a1
      fac2 = a0
      if(usym.eq.gasym) fac2 = a1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      beu = beof + u
      ube = isqov(beu)
      uga = isqov(gaof+u)
      t11 = t1o(ube)*fac1
      t12 = t1o(uga)*fac2
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 71 v = fv,lv
      gav = gaof + v
      vga = isqov(gav)
      vbe = isqov(beof+v)
      gavof = (isqov(gav)-1)*npr(busym,3,2) + ifc(busym)
      vgub = beuof + isqov(gav)
      ubvg = gavof + isqov(beu)
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      tau(vgub) = a2*(t2(uvbg)+t11*t1o(vga)) - (t2(vubg)+t12*t1o(vbe))
      tau(ubvg) = tau(vgub)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine ext23(t2,tau,itriv,isqoo,npr,flov,ifd2,t1,isqov)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),isqov(nsqov),
     1  itriv(ntriv),isqoo(nsqoo)
      REAL t2(ndimw),tau(ndimw),t1(ndimt1)
      REAL fac,a0,a1,ap5,t11
c
INCLUDE(common/t_parm)
c
      data a0,a1,ap5 /0.0d0,1.0d0,0.5d0/
c
c  expand t2 from t2(v,u,ga<be) to tau(ga<be,v,u) 
c
      icnt = 0
      do 10 uvsym = 1,nirred
      do 20 usym = 1,nirred
      vsym = IXOR32(usym-1,uvsym-1) + 1
      fu = flov(usym,1) 
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 30 u = fu,lu
      uof = (u-1)*no
      do 40 v = fv,lv
      uvof = isqoo(uof+v) + ifd2(uvsym)
c
      if(uvsym.eq.1) then
      do 50 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fac = a0
      if(usym.eq.besym) fac = a1
      do 60 be = fbe,lbe
      beof = be*(be-1)/2
      t11 = t1(isqov((be-1)*no+u))*fac
      do 70 ga = fbe,be-1
      icnt = icnt + 1
      vugb = uvof + (itriv(beof+ga)-1)*npr(uvsym,1,2)
      tau(icnt) = t2(vugb) + t1(isqov((ga-1)*no+v))*t11
   70 continue
      icnt = icnt + 1
      vubb = uvof + (itriv(beof+be)-1)*npr(uvsym,1,2)
      tau(icnt) = ap5*(t2(vubb)+t1(isqov((be-1)*no+v))*t11)
   60 continue
   50 continue
      else
      do 80 besym = 1,nirred
      gasym = IXOR32(besym-1,uvsym-1) + 1
      if(gasym.gt.besym) go to 81
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      fac = a0
      if(usym.eq.besym) fac = a1
      do 90 be = fbe,lbe
      beof = be*(be-1)/2
      t11 = t1(isqov((be-1)*no+u))*fac
      do 100 ga = fga,lga
      icnt = icnt + 1
      vugb = uvof + (itriv(beof+ga)-1)*npr(uvsym,1,2)
      tau(icnt) = t2(vugb) + t1(isqov((ga-1)*no+v))*t11
  100 continue
   90 continue
   81 continue
   80 continue
      end if
   40 continue
   30 continue
   20 continue
   10 continue
      return
      end
      subroutine extau1(t2,tau,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,
     1  ifd4,t1o,isqov)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),isqov(nsqov),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqvv(nsqvv),ifd4(nirred)
      REAL t2(ndimw),tau(ndimw),t1o(ndimt1)
      REAL fac,a0,a1,t11
c
INCLUDE(common/t_parm)
c
      data a0,a1 /0.0d0,1.0d0/
c
c  expand t2 (or tau) from t2(v,u,ga<be) to tau(v,u,ga,be)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      bgq = (be-1)*nv + ga
      gbq = (ga-1)*nv + be
      bgqof = (isqvv(bgq)-1)*off2
      gbqof = (isqvv(gbq)-1)*off2
      do 40 usym = 1,nirred
      fac = a0
      if(usym.eq.besym) fac = a1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      ube = (be-1)*no + u
      t11 = t1o(isqov(ube))*fac
      do 60 v = fu,lu
      vga = (ga-1)*no + v
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      uvbgq = bgqof + isqoo(uv)
      vugbq = gbqof + isqoo(vu)
      tau(uvbgq) = t2(uvbg) + t1o(isqov(vga))*t11
      tau(vugbq) = tau(uvbgq)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      bbq = (be-1)*nv + be
      bbqof = (isqvv(bbq)-1)*off2
      do 70 usym = 1,nirred
      fac = a0
      if(usym.eq.besym) fac = a1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      ube = (be-1)*no + u
      t11 = t1o(isqov(ube))*fac
      do 90 v = fu,lu
      vbe = (be-1)*no + v
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      uvbbq = bbqof + isqoo(uv)
      tau(uvbbq) = t2(uvbb) + t1o(isqov(vbe))*t11
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      do 41 ga = fga,lga
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      bgq = (be-1)*nv + ga
      bgqof = (isqvv(bgq)-1)*off2 + ifd4(bgsym)
      gbq = (ga-1)*nv + be
      gbqof = (isqvv(gbq)-1)*off2 + ifd4(bgsym)
      do 51 usym = 1,nirred
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fac = a0
      if(usym.eq.besym) fac = a1
      if(vsym.ne.gasym) fac = a0
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      ube = isqov((be-1)*no+u)
      t11 = t1o(ube)*fac
      do 71 v = fv,lv
      vga = isqov((ga-1)*no+v)
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      uvbgq = bgqof + isqoo(uv)
      vugbq = gbqof + isqoo(vu)
      tau(uvbgq) = t2(uvbg) + t1o(vga)*t11
      tau(vugbq) = tau(uvbgq)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine extau2(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,
     1                  ifc)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifc(nirred),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqov(nsqov)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  expand t2 (or tau) from t2(v,u,ga<be) to tau(v,ga,u,be)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      beof = (be-1)*no
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gaof = (ga-1)*no
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      busym = IXOR32(besym-1,usym-1) + 1
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 60 v = fu,lu
      gav = gaof + v
      gavof = (isqov(gav)-1)*npr(busym,3,2) + ifc(busym)
      vgub = beuof + isqov(gav)
      ubvg = gavof + isqov(beu)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      tau(vgub) = t2(uvbg)
      tau(ubvg) = t2(uvbg)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      do 70 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bev = beof + v
      ubvb = beuof + isqov(bev)
      tau(ubvb) = t2(uvbb)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      beof = (be-1)*no
      do 41 ga = fga,lga
      gaof = (ga-1)*no
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 71 v = fv,lv
      gav = gaof + v
      gavof = (isqov(gav)-1)*npr(busym,3,2) + ifc(busym)
      vgub = beuof + isqov(gav)
      ubvg = gavof + isqov(beu)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      tau(vgub) = t2(uvbg)
      tau(ubvg) = t2(uvbg)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine extau3(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,
     1                  ifc)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifc(nirred),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqov(nsqov)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  expand t2 (or tau) from t2(v,u,ga<be) to tau(v,be,u,ga)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      beof = (be-1)*no
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gaof = (ga-1)*no
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      busym = IXOR32(besym-1,usym-1) + 1
      gau = gaof + u
      gauof = (isqov(gau)-1)*npr(busym,3,2) + ifc(busym)
      do 60 v = fu,lu
      bev = beof + v
      bevof = (isqov(bev)-1)*npr(busym,3,2) + ifc(busym)
      vbug = gauof + isqov(bev)
      ugvb = bevof + isqov(gau)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      tau(vbug) = t2(uvbg)
      tau(ugvb) = t2(uvbg)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      do 70 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bev = beof + v
      ubvb = beuof + isqov(bev)
      tau(ubvb) = t2(uvbb)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      beof = (be-1)*no
      do 41 ga = fga,lga
      gaof = (ga-1)*no
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      gusym = IXOR32(gasym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      gau = gaof + u
      gauof = (isqov(gau)-1)*npr(gusym,3,2) + ifc(gusym)
      do 71 v = fv,lv
      bev = beof + v
      bevof = (isqov(bev)-1)*npr(gusym,3,2) + ifc(gusym)
      vbug = gauof + isqov(bev)
      ugvb = bevof + isqov(gau)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      tau(vbug) = t2(uvbg)
      tau(ugvb) = t2(uvbg)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine extau4(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,
     1                  ifc)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifc(nirred),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqov(nsqov)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  starting with t2(v,u,ga<be) form:
c  (2*t2(v,u,ga,be) - t2(u,v,ga,be))  and store as t2(v,ga,u,be)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      beof = (be-1)*no
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gaof = (ga-1)*no
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      busym = IXOR32(besym-1,usym-1) + 1
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 60 v = fu,lu
      gav = gaof + v
      gavof = (isqov(gav)-1)*npr(busym,3,2) + ifc(busym)
      vgub = beuof + isqov(gav)
      ubvg = gavof + isqov(beu)
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      tau(vgub) = t2(uvbg) + t2(uvbg) - t2(vubg)
      tau(ubvg) = t2(uvbg) + t2(uvbg) - t2(vubg)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      do 70 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bev = beof + v
      ubvb = beuof + isqov(bev)
      tau(ubvb) = t2(uvbb)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      beof = (be-1)*no
      do 41 ga = fga,lga
      gaof = (ga-1)*no
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 71 v = fv,lv
      gav = gaof + v
      gavof = (isqov(gav)-1)*npr(busym,3,2) + ifc(busym)
      vgub = beuof + isqov(gav)
      ubvg = gavof + isqov(beu)
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      tau(vgub) = t2(uvbg) + t2(uvbg) - t2(vubg)
      tau(ubvg) = t2(uvbg) + t2(uvbg) - t2(vubg)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine extau5(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,
     1                  ifc)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifc(nirred),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqov(nsqov)
      REAL t2(ndimw),tau(ndimw)
      REAL a0,a1,ap5
c
INCLUDE(common/t_parm)
c
      data a0,a1,ap5 /0.0d0,1.0d0,0.5d0/
c
c  starting with t2(v,u,ga<be) form:
c  [t2(v,u,ga,be) - 0.5*t2(u,v,ga,be)]
c  and store as t2(v,ga,u,be)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      beof = (be-1)*no
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gaof = (ga-1)*no
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      busym = IXOR32(besym-1,usym-1) + 1
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 60 v = fu,lu
      gav = gaof + v
      gavof = (isqov(gav)-1)*npr(busym,3,2) + ifc(busym)
      vgub = beuof + isqov(gav)
      ubvg = gavof + isqov(beu)
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      vbe = isqov(beof+v)
      tau(vgub) = t2(uvbg) - ap5*t2(vubg)
      tau(ubvg) = tau(vgub)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      do 70 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bev = beof + v
      ubvb = beuof + isqov(bev)
      tau(ubvb) = ap5*t2(uvbb)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      beof = (be-1)*no
      do 41 ga = fga,lga
      gaof = (ga-1)*no
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 71 v = fv,lv
      gav = gaof + v
      gavof = (isqov(gav)-1)*npr(busym,3,2) + ifc(busym)
      vgub = beuof + isqov(gav)
      ubvg = gavof + isqov(beu)
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      tau(vgub) = t2(uvbg) - ap5*t2(vubg)
      tau(ubvg) = tau(vgub)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine extau6(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,
     1                  ifc)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifc(nirred),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqov(nsqov)
      REAL t2(ndimw),tau(ndimw)
      REAL a0,a1,ap5
c
INCLUDE(common/t_parm)
c
      data a0,a1,ap5 /0.0d0,1.0d0,0.5d0/
c
c  starting with t2(v,u,ga<be) and t1o(v,ga) form:
c  [t2(v,u,ga,be)] and store as t2(v,be,u,ga)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      beof = (be-1)*no
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gaof = (ga-1)*no
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      busym = IXOR32(besym-1,usym-1) + 1
      gau = gaof + u
      gauof = (isqov(gau)-1)*npr(busym,3,2) + ifc(busym)
      do 60 v = fu,lu
      bev = beof + v
      bevof = (isqov(bev)-1)*npr(busym,3,2) + ifc(busym)
      vbug = gauof + isqov(bev)
      ugvb = bevof + isqov(gau)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      tau(vbug) = t2(uvbg)
      tau(ugvb) = tau(vbug)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      do 70 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bev = beof + v
      ubvb = beuof + isqov(bev)
      tau(ubvb) = t2(uvbb)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      beof = (be-1)*no
      do 41 ga = fga,lga
      gaof = (ga-1)*no
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      gusym = IXOR32(gasym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      gau = gaof + u
      gauof = (isqov(gau)-1)*npr(gusym,3,2) + ifc(gusym)
      do 71 v = fv,lv
      bev = beof + v
      bevof = (isqov(bev)-1)*npr(gusym,3,2) + ifc(gusym)
      vbug = gauof + isqov(bev)
      ugvb = bevof + isqov(gau)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      tau(vbug) = t2(uvbg)
      tau(ugvb) = tau(vbug)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine extau7(t2,tau,ioff,itriv,isqoo,npr,flov,ifd2,
     1                  isqov,t1o,ntr,ivvoo,ivvoot)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),ntr(nirred,4),isqov(nsqov),
     2  ivvoot(nirred),ivvoo(nirred,nirred)
      REAL t2(ndimw),tau(ndimw),t1o(ndimt1)
      REAL a0,a1,a2,fac1,t11,fac2,t12
c
INCLUDE(common/t_parm)
c
      data a0,a1,a2 /0.0d0,1.0d0,2.0d0/
c
c  starting with t2(v,u,ga<be) and t1o(v,ga) form:
c  [tau(v,u,ga,be) - 2*tau(u,v,ga,be)] and store as
c  t2(ga,uv:be) and t2(be,vu:ga)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      nbe = lbe - fbe + 1
      do 20 be = fbe,lbe
      beof = (be-1)*no
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gaof = (ga-1)*no
      gbof = (ga-fbe)*ntr(besym,2) + ivvoot(besym) + be - fbe + 1
      bgof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + ga - fbe + 1
      do 40 usym = 1,nirred
      fac1 = a0
      if(usym.eq.besym) fac1 = a1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      busym = IXOR32(besym-1,usym-1) + 1
      ube = isqov(beof+u)
      uga = isqov(gaof+u)
      t11 = t1o(ube)*fac1
      t12 = t1o(uga)*fac1
      do 60 v = fu,lu
      vbe = isqov(beof+v)
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      vga = isqov(gaof+v)
      guvb = (isqoo(vu)-1)*nbe + bgof
      bvug = (isqoo(uv)-1)*nbe + gbof
      tau(guvb) = t2(uvbg) + t11*t1o(vga) - a2*(t2(vubg)+t12*t1o(vbe))
      tau(bvug) = tau(guvb)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      bbof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + be - fbe + 1
      do 70 usym = 1,nirred
      fac1 = a0
      if(usym.eq.besym) fac1 = a1
      busym = IXOR32(besym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      beu = beof + u
      ube = isqov(beu)
      t11 = t1o(ube)*fac1
      do 90 v = fu,lu
      uv = (u-1)*no + v
      buvb = (isqoo(uv)-1)*nbe + bbof
      uvbb = beoff + isqoo(uv)
      vbe = isqov(beof+v)
      tau(buvb) = - t2(uvbb) - t11*t1o(vbe)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      nbe = lbe - fbe + 1
      nga = lga - fga + 1
      do 31 be = fbe,lbe
      beof = (be-1)*no
      do 41 ga = fga,lga
      gaof = (ga-1)*no
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      gbof = (ga-fga)*ntr(gasym,2) + ivvoot(gasym) + be - fbe + 1
     1        + ivvoo(bgsym,gasym)
      bgof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + ga - fga + 1
     1        + ivvoo(bgsym,besym)
      do 51 usym = 1,nirred
      fac1 = a0
      fac2 = a0
      if(usym.eq.besym) fac1 = a1
      if(usym.eq.gasym) fac2 = a1
      gusym = IXOR32(gasym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      if(vsym.ne.gasym) fac1 = a0
      if(vsym.ne.besym) fac2 = a0
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      ube = isqov(beof+u)
      uga = isqov(gaof+u)
      t11 = t1o(ube)*fac1
      t12 = t1o(uga)*fac2
      do 71 v = fv,lv
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      bvug = (isqoo(uv)-1)*nbe + gbof
      guvb = (isqoo(vu)-1)*nga + bgof
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      vga = isqov(gaof+v)
      vbe = isqov(beof+v)
      tau(bvug) = t2(uvbg) + t11*t1o(vga) - a2*(t2(vubg)+t12*t1o(vbe))
      tau(guvb) = tau(bvug)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine extau8(t2,tau,ioff,itriv,isqoo,npr,flov,ifd2,
     1                  ntr,ivvoo,ivvoot)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),ntr(nirred,4),
     2  ivvoot(nirred),ivvoo(nirred,nirred)
      REAL t2(ndimw),tau(ndimw)
      REAL a0,a1,a2
c
INCLUDE(common/t_parm)
c
      data a0,a1,a2 /0.0d0,1.0d0,2.0d0/
c
c  starting with t2(v,u,ga<be)  form:
c  t2(ga,uv:be) and t2(be,vu:ga)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      nbe = lbe - fbe + 1
      do 20 be = fbe,lbe
      beof = (be-1)*no
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gbof = (ga-fbe)*ntr(besym,2) + ivvoot(besym) + be - fbe + 1
      bgof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + ga - fbe + 1
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      busym = IXOR32(besym-1,usym-1) + 1
      do 60 v = fu,lu
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      guvb = (isqoo(vu)-1)*nbe + bgof
      bvug = (isqoo(uv)-1)*nbe + gbof
      tau(guvb) = t2(uvbg)
      tau(bvug) = t2(uvbg)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      bbof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + be - fbe + 1
      do 70 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      do 90 v = fu,lu
      uv = (u-1)*no + v
      buvb = (isqoo(uv)-1)*nbe + bbof
      uvbb = beoff + isqoo(uv)
      tau(buvb) =  t2(uvbb)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      nbe = lbe - fbe + 1
      nga = lga - fga + 1
      do 31 be = fbe,lbe
      do 41 ga = fga,lga
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      gbof = (ga-fga)*ntr(gasym,2) + ivvoot(gasym) + be - fbe + 1
     1        + ivvoo(bgsym,gasym)
      bgof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + ga - fga + 1
     1        + ivvoo(bgsym,besym)
      do 51 usym = 1,nirred
      gusym = IXOR32(gasym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      do 71 v = fv,lv
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      bvug = (isqoo(uv)-1)*nbe + gbof
      guvb = (isqoo(vu)-1)*nga + bgof
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      tau(bvug) = t2(uvbg)
      tau(guvb) = t2(uvbg)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine extau9(t2,tau,ioff,itriv,isqoo,npr,flov,ifd2,
     1                  ntr,ivvoo,ivvoot)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),ntr(nirred,4),
     2  ivvoot(nirred),ivvoo(nirred,nirred)
      REAL t2(ndimw),tau(ndimw)
      REAL a0,a1,a2
c
INCLUDE(common/t_parm)
c
      data a0,a1,a2 /0.0d0,1.0d0,2.0d0/
c
c  starting with t2(v,u,ga<be) form:
c  [2*t2(v,u,ga,be) - t2(u,v,ga,be)] and store as
c  t2(ga,uv:be) and t2(be,vu:ga)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      nbe = lbe - fbe + 1
      do 20 be = fbe,lbe
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gbof = (ga-fbe)*ntr(besym,2) + ivvoot(besym) + be - fbe + 1
      bgof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + ga - fbe + 1
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      do 60 v = fu,lu
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      guvb = (isqoo(vu)-1)*nbe + bgof
      bvug = (isqoo(uv)-1)*nbe + gbof
      tau(guvb) = t2(uvbg) + t2(uvbg) - t2(vubg)
      tau(bvug) = tau(guvb)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      bbof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + be - fbe + 1
      do 70 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      do 90 v = fu,lu
      uv = (u-1)*no + v
      buvb = (isqoo(uv)-1)*nbe + bbof
      uvbb = beoff + isqoo(uv)
      tau(buvb) =  t2(uvbb)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      nbe = lbe - fbe + 1
      nga = lga - fga + 1
      do 31 be = fbe,lbe
      do 41 ga = fga,lga
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      gbof = (ga-fga)*ntr(gasym,2) + ivvoot(gasym) + be - fbe + 1
     1        + ivvoo(bgsym,gasym)
      bgof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + ga - fga + 1
     1        + ivvoo(bgsym,besym)
      do 51 usym = 1,nirred
      gusym = IXOR32(gasym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      do 71 v = fv,lv
      uv = (u-1)*no + v
      vu = (v-1)*no + u
      bvug = (isqoo(uv)-1)*nbe + gbof
      guvb = (isqoo(vu)-1)*nga + bgof
      uvbg = bgoff + isqoo(uv)
      vubg = bgoff + isqoo(vu)
      tau(bvug) = t2(uvbg) + t2(uvbg) - t2(vubg)
      tau(guvb) = tau(bvug)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      SUBROUTINE FLINQ(A,IDIM,IN,IM,DET)
      IMPLICIT REAL (A-H,O-Z)
CONVEXREAL*16 DET,D,SIGN
C
C     LINEAR SIMULTANEOUS EQUATION
C
C     A(IN*IN) * X(IN*IM) = B(IN*IM)
C
C     A & B SHOULD BE STORED ON A(IN*(IN+IM))
C     SOLUTION X WILL BE STORED ON B PART IN DIMENSION A.
C
      DIMENSION A(IDIM,1)
      DATA ZERO,ONE / 0.0D+00 , 1.0D+00 /
C
      N=IN
      NR=IM
      JMAX=N+NR
      SIGN=1.0D+00
C     SIGN=1.0Q+00
C M IS THE STAGE OF ELIMINATION
      DO 49 M=1,N
      TEMP=ZERO
      DO 41 I=M,N
      IF(M.GT.1)A(I,M)=A(I,M)-DOTT(A(I,1),IDIM,A(1,M),1,M-1)
      AVAL=A(I,M)
      IF(ABS(AVAL).LE.TEMP)GOTO 41
      TEMP=ABS(AVAL)
      IMAX=I
 41   CONTINUE
      IF(TEMP.LE.ZERO)GOTO 999
      IF(IMAX.EQ.M)GOTO 45
      SIGN=-SIGN
      DO 44 J=1,JMAX
      STOR=A(M,J)
      A(M,J)=A(IMAX,J)
      A(IMAX,J)=STOR
 44   CONTINUE
 45   CONTINUE
      JJ=M+1
      IF(JJ.GT.JMAX)GOTO 49
      IF(M.GT.1)GOTO 47
      DO 46 J=JJ,JMAX
      A(1,J)=A(1,J)/A(1,1)
 46   CONTINUE
      D=A(1,1)
      GOTO 49
 47   CONTINUE
      DO 48 J=JJ,JMAX
      A(M,J)=(A(M,J)-DOTT(A(M,1),IDIM,A(1,J),1,M-1))/A(M,M)
 48   CONTINUE
      D=D*A(M,M)
 49   CONTINUE
      IF(NR.EQ.0) RETURN
      DO 59 I=1,NR
      NPI=N+I
      DO 58 K=2,N
      J=N+1-K
      A(J,NPI)=A(J,NPI)-DOTT(A(J,J+1),IDIM,A(J+1,NPI),1,K-1)
 58   CONTINUE
 59   CONTINUE
      DET=D*SIGN
      RETURN
C ON ZERO PIVOT, SET DET=0.AND RETURN TO CALLING PROGRAM NOV 1972
 999  DET=0.0D+00
C999  DET=0.0Q+00
      RETURN
      END
      subroutine flt21(t2,tau,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,
     1                 ioovv,ioovvt,ntr)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqvv(nsqvv),ioovvt(nirred),
     2  ioovv(nirred,nirred),ntr(nirred,2)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  sort and expand t2 from t2(v,u,ga<be) to tau(v,ugabe)
c  fold from tau to t2
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      bgq = (be-1)*nv + ga
      gbq = (ga-1)*nv + be
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      nu = lu - fu + 1
      bgof = (isqvv(bgq)-1)*nu + ioovvt(usym)
      gbof = (isqvv(gbq)-1)*nu + ioovvt(usym)
      do 50 u = fu,lu
      bguof = bgof + (u-fu)*ntr(usym,1)
      gbu = gbof + u - fu + 1
      do 60 v = fu,lu
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      bguv = bguof + v - fu + 1
      gbvu = gbu + (v-fu)*ntr(usym,1)
      t2(uvbg) = tau(bguv) + tau(gbvu)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      bbq = (be-1)*nv + be
      do 70 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      nu = lu - fu + 1
      bbof = (isqvv(bbq)-1)*nu + ioovvt(usym)
      do 80 u = fu,lu
      bbuof = bbof + (u-fu)*ntr(usym,1)
      bbvof = bbof + u - fu + 1
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bbuv = bbuof + v - fu + 1
      bbvu = bbvof + (v-fu)*ntr(usym,1)
      t2(uvbb) = tau(bbuv) + tau(bbvu)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      do 41 ga = fga,lga
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      bgq = (be-1)*nv + ga
      gbq = (ga-1)*nv + be
      do 51 usym = 1,nirred
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      nu = lu - fu + 1
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      nvv = lv - fv + 1
      bgof = (isqvv(bgq)-1)*nvv + ioovvt(usym) + ioovv(bgsym,usym)
      gbof = (isqvv(gbq)-1)*nu + ioovvt(vsym) + ioovv(bgsym,vsym)
      do 61 u = fu,lu
      bguof = bgof + (u-fu)*ntr(usym,1)
      gbu = gbof + u - fu + 1
      do 71 v = fv,lv
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      bguv = bguof + v - fv + 1
      gbvu = gbu + (v-fv)*ntr(vsym,1)
      t2(uvbg) = tau(bguv) + tau(gbvu)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine flt22(t2,tau,ioff,itriv,isqoo,npr,flov,ifd2,
     1                 ivvoo,ivvoot,ntr)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),ivvoot(nirred),
     2  ivvoo(nirred,nirred),ntr(nirred,2)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  fold tau(be,uv:ga) to t2(v,u,ga<be) also adding (ga,vu:be)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      nbe = lbe - fbe + 1
      do 20 be = fbe,lbe
      beof = (be-fbe)*ntr(besym,2) + ivvoot(besym)
      do 30 ga = fbe,be-1
      gbof = (ga-fbe)*ntr(besym,2) + ivvoot(besym) + be - fbe + 1
      bgof = beof + ga - fbe + 1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      uof = (u-1)*no
      do 60 v = fu,lu
      buvg = (isqoo((v-1)*no + u)-1)*nbe + gbof
      gvub = (isqoo(uof+v)-1)*nbe + bgof
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      t2(uvbg) = tau(buvg) + tau(gvub)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      bbof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + be - fbe + 1
      do 70 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      uof = (u-1)*no
      do 90 v = fu,lu
      uv = uof + v
      uvbb = beoff + isqoo(uv)
      buvb = bbof + (isqoo((v-1)*no+u)-1)*nbe
      bvub = bbof + (isqoo(uv)-1)*nbe
      t2(uvbb) = tau(buvb) + tau(bvub)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      nbe = lbe - fbe + 1
      nga = lga - fga + 1
      do 31 be = fbe,lbe
      beof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + ivvoo(bgsym,besym)
      do 41 ga = fga,lga
      gbof = (ga-fga)*ntr(gasym,2) + ivvoot(gasym) + be - fbe + 1
     1       + ivvoo(bgsym,gasym)
      bgof = beof + ga - fga + 1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      uof = (u-1)*no
      do 71 v = fv,lv
      uv = uof + v
      uvbg = bgoff + isqoo(uv)
      buvg = gbof + (isqoo((v-1)*no+u)-1)*nbe
      gvub = bgof + (isqoo(uv)-1)*nga
      t2(uvbg) = tau(buvg) + tau(gvub)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine flt23(t2,tau,ioff,itriv,isqoo,npr,flov,ifd2,
     1                 ivvoo,ivvoot,ntr)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),ivvoot(nirred),
     2  ivvoo(nirred,nirred),ntr(nirred,2)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  fold tau(ga,uv:be) to t2(v,u,ga<be) adding also tau(be,vu:ga)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      nbe = lbe - fbe + 1
      do 20 be = fbe,lbe
      beof = (be-fbe)*ntr(besym,2) + ivvoot(besym)
      do 30 ga = fbe,be-1
      gbof = (ga-fbe)*ntr(besym,2) + ivvoot(besym) + be - fbe + 1
      bgof = beof + ga - fbe + 1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      uof = (u-1)*no
      do 60 v = fu,lu
      bvug = (isqoo(uof+v)-1)*nbe + gbof
      guvb = (isqoo((v-1)*no+u)-1)*nbe + bgof
      uv = uof + v
      uvbg = bgoff + isqoo(uv)
      t2(uvbg) = tau(bvug) + tau(guvb)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      bbof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + be - fbe + 1
      do 70 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      uof = (u-1)*no
      do 90 v = fu,lu
      uv = uof + v
      uvbb = beoff + isqoo(uv)
      buvb = bbof + (isqoo((v-1)*no+u)-1)*nbe
      bvub = bbof + (isqoo(uv)-1)*nbe
      t2(uvbb) = tau(buvb) + tau(bvub)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      nbe = lbe - fbe + 1
      nga = lga - fga + 1
      do 31 be = fbe,lbe
      beof = (be-fbe)*ntr(besym,2) + ivvoot(besym) + ivvoo(bgsym,besym)
      do 41 ga = fga,lga
      gbof = (ga-fga)*ntr(gasym,2) + ivvoot(gasym) + be - fbe + 1
     1       + ivvoo(bgsym,gasym)
      bgof = beof + ga - fga + 1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      uof = (u-1)*no
      do 71 v = fv,lv
      uv = uof + v
      uvbg = bgoff + isqoo(uv)
      bvug = gbof + (isqoo(uv)-1)*nbe
      guvb = bgof + (isqoo((v-1)*no+u)-1)*nga
      t2(uvbg) = tau(bvug) + tau(guvb)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine fltau1(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,
     1                  ifc)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifc(nirred),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqov(nsqov)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  fold t2(u,be,v,ga) to t2(v,u,ga<be) adding both
c  t2(u,be,v,ga) and t2(v,ga,u,be) to t2(v,u,ga<be)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      beof = (be-1)*no
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gaof = (ga-1)*no
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      busym = IXOR32(besym-1,usym-1) + 1
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 60 v = fu,lu
      gav = gaof + v
      gavof = (isqov(gav)-1)*npr(busym,3,2) + ifc(busym)
      vgub = beuof + isqov(gav)
      ubvg = gavof + isqov(beu)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      t2(uvbg) = tau(vgub) + tau(ubvg)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      do 70 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bev = beof + v
      ubvb = beuof + isqov(bev)
      bevof = (isqov(bev)-1)*npr(busym,3,2) + ifc(busym)
      vbub = bevof + isqov(beu)
      t2(uvbb) = tau(ubvb) + tau(vbub)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      beof = (be-1)*no
      do 41 ga = fga,lga
      gaof = (ga-1)*no
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 71 v = fv,lv
      gav = gaof + v
      gavof = (isqov(gav)-1)*npr(busym,3,2) + ifc(busym)
      vgub = beuof + isqov(gav)
      ubvg = gavof + isqov(beu)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      t2(uvbg) = tau(vgub) + tau(ubvg)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine fltau2(t2,tau,ioff,itriv,isqoo,isqov,npr,flov,ifd2,
     1                  ifc)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifc(nirred),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqov(nsqov)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  fold t2(v,be,u,ga) to t2(v,u,ga<be) adding both
c  t2(v,be,u,ga) and t2(u,ga,v,be) to t2(v,u,ga<be)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      beof = (be-1)*no
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      gaof = (ga-1)*no
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      gusym = IXOR32(besym-1,usym-1) + 1
      gau = gaof + u
      gauof = (isqov(gau)-1)*npr(gusym,3,2) + ifc(gusym)
      do 60 v = fu,lu
      bev = beof + v
      bevof = (isqov(bev)-1)*npr(gusym,3,2) + ifc(gusym)
      vbug = gauof + isqov(bev)
      ugvb = bevof + isqov(gau)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      t2(uvbg) = tau(vbug) + tau(ugvb)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      do 70 usym = 1,nirred
      busym = IXOR32(besym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      beu = beof + u
      beuof = (isqov(beu)-1)*npr(busym,3,2) + ifc(busym)
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bev = beof + v
      ubvb = beuof + isqov(bev)
      bevof = (isqov(bev)-1)*npr(busym,3,2) + ifc(busym)
      vbub = bevof + isqov(beu)
      t2(uvbb) = tau(ubvb) + tau(vbub)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      beof = (be-1)*no
      do 41 ga = fga,lga
      gaof = (ga-1)*no
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      gusym = IXOR32(gasym-1,usym-1) + 1
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      gau = gaof + u
      gauof = (isqov(gau)-1)*npr(gusym,3,2) + ifc(gusym)
      do 71 v = fv,lv
      bev = beof + v
      bevof = (isqov(bev)-1)*npr(gusym,3,2) + ifc(gusym)
      vbug = gauof + isqov(bev)
      ugvb = bevof + isqov(gau)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      t2(uvbg) = tau(vbug) + tau(ugvb)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine fltau3(t2,tau,isqoo,isqvv,npr,flov,ifd4)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd4(nirred),
     1        isqoo(nsqoo),isqvv(nsqvv)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  fold t2(ga,be,v,u) to t2(v,u,ga<be) adding both
c  t2(ga,be,v,u) and t2(be,ga,u,v) to t2(v,u,ga<be)
c
      icnt = 0
      do 10 bgsym = 1,nirred
      do 20 besym = 1,nirred
      gasym = IXOR32(besym-1,bgsym-1) + 1
      if(gasym.gt.besym) go to 21
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 30 be = fbe,lbe
      beof = (be-1)*nv
      llga = lga
      if(besym.eq.gasym) llga = be
      do 40 ga = fga,llga
      gboff = isqvv(beof+ga) + ifd4(bgsym)
      bgoff = isqvv((ga-1)*nv+be) + ifd4(bgsym)
      do 50 usym = 1,nirred
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 60 u = fu,lu
      uof = (u-1)*no
      do 70 v = fv,lv
      icnt = icnt + 1
      gbvu = gboff + (isqoo(uof+v)-1)*npr(bgsym,2,2)
      bguv = bgoff + (isqoo((v-1)*no+u)-1)*npr(bgsym,2,2)
      tau(icnt) = t2(gbvu) + t2(bguv)
   70 continue
   60 continue
   50 continue
   40 continue
   30 continue
   21 continue
   20 continue
   10 continue
      return
      end
      subroutine gictrps(t1,t2,dints,eints,fints,buf1,buf2,
     &                   eta,zeta,epo,epv,gam,aaa,ccc,ee,flov,
     &                   npr,isqov,isqvo,isqoo,isqvv,iovvvt,iovvv,
     &                   novvvt,orbsym,ifd4,ife1,eccsd,iopt,ndimd,
     &                   ndime,ndimf,mxv3,idx1,idx2,jdx1,jdx2,itrio,
     &                   ifd3,debug)
      implicit integer(a-z)
      parameter(lntx=40)
      integer flov(nirred,4),npr(nirred,3,2),isqov(nsqov),
     &        isqvo(nsqov),isqoo(nsqoo),isqvv(nsqvv),iovvvt(nirred),
     &        iovvv(nirred,nirred),novvvt(nirred),orbsym(nbf),
     &        ifd4(nirred),ife1(nirred),idx1(nsqvv),idx2(nsqvv),
     &        jdx1(nirred),jdx2(nirred,nirred),itrio(ntrio),
     &        ifd3(nirred)
      REAL t1(ndimt1),t2(ndimw),dints(ndimd),eints(ndime),
     &       fints(ndimf),buf1(mxv3),buf2(mxv3),
     &       eta(ndimt1),zeta(ndimd),epo(no),epv(nv),gam(ndimw),
     &       aaa(ndimf),ccc(ndime),ee(nbf)
      REAL tx(lntx)
      REAL d1,d2,d3,d4,d5,fac3
      REAL emp4t,eccsd
      REAL x1,x2,x3,y1,y2,y3,x11,y11,e1
c
INCLUDE(common/t_adata)
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      character *1 xn,xt
      data xn, xt / 'n', 't'/
      call vclr(tx,1,lntx)
c
c  we have f integrals, e integrals and t2 in memory; form emp4(t)
c  form w(a,b,c) for a given i,j,k
c
      icnt=0
      do 900 absym=1,nirred
      jdx1(absym)=icnt
      do 902 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 904 a=flov(asym,3)-no,flov(asym,4)-no
      do 906 b=flov(bsym,3)-no,flov(bsym,4)-no
      icnt=icnt+1
      idx1(icnt)=isqvv((b-1)*nv+a)
  906 continue
  904 continue
  902 continue
  900 continue
c
      call vclr(eta,1,ndimt1)
      call vclr(zeta,1,ndimd)
      call vclr(epo,1,no)
      call vclr(epv,1,nv)
      call vclr(gam,1,ndimw)
      call vclr(aaa,1,ndimf)
      call vclr(ccc,1,ndime)
c
      emp4t = a0
      do 100 ijksym=1,nirred
c
      icnt=0
      do 910 asym=1,nirred
      bcsym=IXOR32(ijksym-1,asym-1)+1
      do 912 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      acsym=IXOR32(asym-1,csym-1)+1
      nvb=flov(bsym,4)-flov(bsym,3)+1
      nvc=flov(csym,4)-flov(csym,3)+1
      jdx2(asym,bsym)=icnt
      do 914 b=1,nvb
      off1=(b-1)*npr(acsym,2,2)-1
      off2=icnt+(b-1)*nvc
      do 916 c=1,nvc
      idx2(off2+c)=off1+c
  916 continue
  914 continue
      icnt=icnt+nvc*nvb
  912 continue
  910 continue
c
      do 101 i = 1,no
      isym = orbsym(i) + 1
      ii=i-flov(isym,1)+1
      d1 = ee(i)
      do 102 j = 1,i
c      do 102 j = 1,no
      jsym = orbsym(j) + 1
      ijsym=IXOR32(isym-1,jsym-1)+1
      ksym=IXOR32(ijksym-1,ijsym-1)+1
      if (ksym.gt.jsym)goto 102
      iksym=IXOR32(isym-1,ksym-1)+1
      jksym=IXOR32(jsym-1,ksym-1)+1
      jj=j-flov(jsym,1)+1
      d2 = d1 + ee(j)
      limj=min(flov(ksym,2),j)
c      do 104 k = flov(ksym,1),flov(ksym,2)
      do 104 k = flov(ksym,1),limj
      if(k.eq.i) go to 104
      ksym = orbsym(k) + 1
      kk=k-flov(ksym,1)+1
      d3 = d2 + ee(k)
c
      if (i.eq.j.or.j.eq.k)then
        fac3=a3
      else
        fac3=a6
      endif
      len=novvvt(ijksym)
      call vclr(buf1,1,len)
c
c - form w intermediate
c
c (ia:bf)*t2(kc:jf)
      call wtst
      ad1=iovvvt(isym)+(ii-1)*novvvt(isym)+1
      call mxmtp1(buf1,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,j,k,isym,jsym,ksym,mxv3,ndime)
      call wtgt(tx(1))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(7))
      call wtst
c
c (ia:cf)*t2(jb:kf)
      ad1=iovvvt(isym)+(ii-1)*novvvt(isym)+1
      call mxmtp1(buf2,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,k,j,isym,ksym,jsym,mxv3,ndime)
      call wtgt(tx(2))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(8))
      call wtst
c
c (kc:af)*t2(jb:if)
      ad1=iovvvt(ksym)+(kk-1)*novvvt(ksym)+1
      call mxmtp1(buf1,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,i,j,ksym,isym,jsym,mxv3,ndime)
      call wtgt(tx(3))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(9))
      call wtst
c
c (kc:bf)*t2(ia:jf)
      ad1=iovvvt(ksym)+(kk-1)*novvvt(ksym)+1
      call mxmtp1(buf2,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,j,i,ksym,jsym,isym,mxv3,ndime)
      call wtgt(tx(4))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(10))
      call wtst
c
c (jb:cf)*t2(ia:kf)
      ad1=iovvvt(jsym)+(jj-1)*novvvt(jsym)+1
      call mxmtp1(buf1,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,k,i,jsym,ksym,isym,mxv3,ndime)
      call wtgt(tx(5))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
c (jb:af)*t2(kc:if)
      ad1=iovvvt(jsym)+(jj-1)*novvvt(jsym)+1
      call mxmtp1(buf2,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,i,k,jsym,isym,ksym,mxv3,ndime)
      call wtgt(tx(6))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(12))
      call wtst
c
c - form intermediate for zeta and eta
      do 340 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 342 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no
      d4=d3-ee(c+no)
      do 344 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 344
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 346 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b,lima)
      do 348 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no
      ixabc=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixacb=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixcba=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
      ixbca=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
      x1=buf1(ixabc)+buf1(ixbca)+buf1(ixcab)
      x2=buf1(ixcba)+buf1(ixacb)+buf1(ixbac)
      y1=x1-x2-x2
      y2=x2-x1-x1
      buf2(ixabc)=(a3*buf1(ixabc)+y1)/(d5-ee(a+no))
      buf2(ixacb)=(a3*buf1(ixacb)+y2)/(d5-ee(a+no))
      buf2(ixcab)=(a3*buf1(ixcab)+y1)/(d5-ee(a+no))
      buf2(ixcba)=(a3*buf1(ixcba)+y2)/(d5-ee(a+no))
      buf2(ixbca)=(a3*buf1(ixbca)+y1)/(d5-ee(a+no))
      buf2(ixbac)=(a3*buf1(ixbac)+y2)/(d5-ee(a+no))
  348 continue
  346 continue
  344 continue
  342 continue
  340 continue
      call wtgt(tx(13))
      call wtst
c
c -- compute eta and zeta
c (ia:jb)*t1(kc)
      lnab=npr(ijsym,2,2)
      lnc=flov(ksym,4)-flov(ksym,3)+1
c      ad1=ifd4(ijsym)+(isqoo((j-1)*no+i)-1)*lnab+1
      ad1=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*lnab+1
      ad2=isqvo((k-1)*nv+flov(ksym,3)-no)
      ad3=iovvv(ijksym,ksym)+1
      if (lnab*lnc.ne.0)then
      call dgemm(xt,xn,lnc,1,lnab
     +          ,fac3,buf2(ad3),lnab,dints(ad1)
     &          ,lnab,a1,eta(ad2),lnc)
      call dgemm(xn,xn,lnab,1,lnc
     +          ,fac3,buf2(ad3),lnab,t1(ad2)
     &          ,lnc,a1,zeta(ad1),lnab)
      endif
c
c (ia:kc)*t1(jb)
      lnb=flov(jsym,4)-flov(jsym,3)+1
      do 370 csym=1,nirred
      asym=IXOR32(iksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnac=npr(iksym,2,2)
      lna=flov(asym,4)-flov(asym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(jsym,3)-no-1)*nv+flov(asym,3)-no)
      do 372 c=flov(csym,3)-no,flov(csym,4)-no
c      ad1=ifd4(iksym)+(isqoo((k-1)*no+i)-1)*lnac+
c     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad1=ifd3(iksym)+(itrio(i*(i-1)/2+k)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad2=isqvo((j-1)*nv+flov(jsym,3)-no)
      if (lna*lnb.ne.0)then
      call dgemm(xt,xn,lnb,1,lna
     +          ,fac3,buf2(ad3),lna,dints(ad1)
     &          ,lna,a1,eta(ad2),lnb)
      call dgemm(xn,xn,lna,1,lnb
     +          ,fac3,buf2(ad3),lna,t1(ad2)
     &          ,lnb,a1,zeta(ad1),lna)
      endif
      ad3=ad3+lnab
  372 continue
  370 continue
c
c (jb:kc)*t1(ia)
      lna=flov(isym,4)-flov(isym,3)+1
      do 380 csym=1,nirred
      bsym=IXOR32(jksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnbc=npr(jksym,2,2)
      lnb=flov(bsym,4)-flov(bsym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(bsym,3)-no-1)*nv+flov(isym,3)-no)
      do 382 c=flov(csym,3)-no,flov(csym,4)-no
c      ad1=ifd4(jksym)+(isqoo((k-1)*no+j)-1)*lnbc+
c     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad1=ifd3(jksym)+(itrio(j*(j-1)/2+k)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad2=isqvo((i-1)*nv+flov(isym,3)-no)
      if (lna*lnb.ne.0)then
      call dgemm(xt,xn,lnb,1,lna
     +          ,fac3,buf2(ad3),lna,t1(ad2)
     +          ,lna,a1,zeta(ad1),lnb)
      call dgemm(xn,xn,lna,1,lnb
     +          ,fac3,buf2(ad3),lna,dints(ad1)
     +          ,lnb,a1,eta(ad2),lna)
      endif
      ad3=ad3+lnab
  382 continue
  380 continue
      call wtgt(tx(14))
      call wtst
c
c -- compute mp5 term - v
      do 601 abc=1,len
      buf2(abc)=buf1(abc)
  601 continue
c (ia:jb)*t1(kc)
      lnab=npr(ijsym,2,2)
      lnc=flov(ksym,4)-flov(ksym,3)+1
c      ad1=ifd4(ijsym)+(isqoo((j-1)*no+i)-1)*lnab+1
      ad1=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*lnab+1
      ad2=isqvo((k-1)*nv+flov(ksym,3)-no)
      ad3=iovvv(ijksym,ksym)+1
c      call mxmb(dints(ad1),1,lnab,t1(ad2),1,1,buf2(ad3),1,lnab,
c     &          lnab,1,lnc)
      if (lnab*lnc.ne.0)then
      call dgemm(xn,xn,lnab,lnc,1
     +          ,a1,dints(ad1),lnab,t1(ad2)
     +          ,1,a1,buf2(ad3),lnab)
      endif
c
c (ia:kc)*t1(jb)
      lnb=flov(jsym,4)-flov(jsym,3)+1
      do 270 csym=1,nirred
      asym=IXOR32(iksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnac=npr(iksym,2,2)
      lna=flov(asym,4)-flov(asym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(jsym,3)-no-1)*nv+flov(asym,3)-no)
      do 272 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd4(iksym)+(isqoo((k-1)*no+i)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad1=ifd3(iksym)+(itrio(i*(i-1)/2+k)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad2=isqvo((j-1)*nv+flov(jsym,3)-no)
c      call mxmb(dints(ad1),1,lna,t1(ad2),1,1,buf2(ad3),1,lna,
c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,dints(ad1),lna,t1(ad2)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  272 continue
  270 continue
c
c (jb:kc)*t1(ia)
      lna=flov(isym,4)-flov(isym,3)+1
      do 280 csym=1,nirred
      bsym=IXOR32(jksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnbc=npr(jksym,2,2)
      lnb=flov(bsym,4)-flov(bsym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(bsym,3)-no-1)*nv+flov(isym,3)-no)
      do 282 c=flov(csym,3)-no,flov(csym,4)-no
c      ad1=ifd4(jksym)+(isqoo((k-1)*no+j)-1)*lnbc+
c     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad1=ifd3(jksym)+(itrio(j*(j-1)/2+k)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad2=isqvo((i-1)*nv+flov(isym,3)-no)
c      call mxmb(t1(ad2),1,lna,dints(ad1),1,1,buf2(ad3),1,lna,
c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,t1(ad2),lna,dints(ad1)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  282 continue
  280 continue
      call wtgt(tx(15))
      call wtst
c
c -- compute triples energy and epsilons
      do 320 b=1,flov(ijksym,4)-flov(ijksym,3)+1
      off1=iovvv(ijksym,ijksym)+(b-1)*npr(1,2,2)
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 322 a=1,nv
      off2=off1+isqvv(a*(nv+1)-nv)
      buf2(off2)=buf2(off2)*ap5
  322 continue
  320 continue
c
      do 330 asym=1,nirred
      absym=IXOR32(asym-1,ijksym-1)+1
      do 332 a=flov(asym,3)-no,flov(asym,4)-no
      off1=iovvv(ijksym,asym)+(a-flov(asym,3)+no)*npr(absym,2,2)
      aof=(a-1)*nv
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 334 b=flov(ijksym,3)-no,flov(ijksym,4)-no
      ixyzy=off1+isqvv((b-1)*nv+a)
      ixzyy=off1+isqvv(aof+b)
      buf2(ixyzy)=buf2(ixyzy)*ap5
      buf2(ixzyy)=buf2(ixzyy)*ap5
  334 continue
  332 continue
  330 continue
c
      e1=a0
      do 250 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 252 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no+1
      d4=d3-ee(c+no)
      do 254 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 254
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 256 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no+1
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b-1,lima)
      do 258 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no+1
      ixabc=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixacb=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixcba=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
      ixbca=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
c  a>b>c
      x1=buf2(ixabc)+buf2(ixbca)+buf2(ixcab)
      x2=buf2(ixacb)+buf2(ixbac)+buf2(ixcba)
      y1=buf1(ixabc)+buf1(ixbca)+buf1(ixcab)
      y2=buf1(ixacb)+buf1(ixbac)+buf1(ixcba)
      x3=(x1-x2-x2)*y1+(x2-x1-x1)*y2
      y3=a3*(buf1(ixabc)*buf2(ixabc)+buf1(ixacb)*buf2(ixacb)+
     &       buf1(ixbac)*buf2(ixbac)+buf1(ixbca)*buf2(ixbca)+
     &       buf1(ixcab)*buf2(ixcab)+buf1(ixcba)*buf2(ixcba))
      x11=(x3+y3)*fac3/(d5-ee(a+no))
      y11=x11/(d5-ee(a+no))
      e1=e1+x11
      epo(i)=epo(i)-y11
      epv(a)=epv(a)-y11
      epo(j)=epo(j)-y11
      epv(b)=epv(b)-y11
      epo(k)=epo(k)-y11
      epv(c)=epv(c)-y11
  258 continue
  256 continue
  254 continue
  252 continue
  250 continue
      emp4t=emp4t+e1
      call wtgt(tx(16))
      call wtst
c 
c -- compute m
      do 820 b=1,flov(ijksym,4)-flov(ijksym,3)+1
      off1=iovvv(ijksym,ijksym)+(b-1)*npr(1,2,2)
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 822 a=1,nv
      off2=off1+isqvv(a*(nv+1)-nv)
      buf2(off2)=buf2(off2)+buf2(off2)
  822 continue
  820 continue
c
      do 830 asym=1,nirred
      absym=IXOR32(asym-1,ijksym-1)+1
      do 832 a=flov(asym,3)-no,flov(asym,4)-no
      off1=iovvv(ijksym,asym)+(a-flov(asym,3)+no)*npr(absym,2,2)
      aof=(a-1)*nv
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 834 b=flov(ijksym,3)-no,flov(ijksym,4)-no
      ixyzy=off1+isqvv((b-1)*nv+a)
      ixzyy=off1+isqvv(aof+b)
      buf2(ixyzy)=buf2(ixyzy)+buf2(ixyzy)
      buf2(ixzyy)=buf2(ixzyy)+buf2(ixzyy)
  834 continue
  832 continue
  830 continue
c
      icnt=0
      do 300 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 302 c=flov(csym,3)-no,flov(csym,4)-no
      d4=d3-ee(c+no)
      do 304 bsym=1,nirred
      asym=IXOR32(absym-1,bsym-1)+1
      do 306 b=flov(bsym,3)-no,flov(bsym,4)-no
      d5=d4-ee(b+no)
      do 308 a=flov(asym,3),flov(asym,4)
      icnt=icnt+1
      buf2(icnt)=fac3*(buf1(icnt)+buf2(icnt))/(d5-ee(a))
  308 continue
  306 continue
  304 continue
  302 continue
  300 continue
c
      do 740 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 742 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no
      d4=d3-ee(c+no)
      do 744 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 744
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 746 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b,lima)
      do 748 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no
      ixabc=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixacb=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixcba=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
      ixbca=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
      x1=buf2(ixabc)+buf2(ixbca)+buf2(ixcab)
      x2=buf2(ixcba)+buf2(ixacb)+buf2(ixbac)
      y1=x1-x2-x2
      y2=x2-x1-x1
      buf1(ixabc)=a3*buf2(ixabc)+y1
      buf1(ixacb)=a3*buf2(ixacb)+y2
      buf1(ixcab)=a3*buf2(ixcab)+y1
      buf1(ixcba)=a3*buf2(ixcba)+y2
      buf1(ixbca)=a3*buf2(ixbca)+y1
      buf1(ixbac)=a3*buf2(ixbac)+y2
  748 continue
  746 continue
  744 continue
  742 continue
  740 continue
      call wtgt(tx(17))
      call wtst
c
c (ia:bf)*t2(kc:jf)
      ad1=iovvvt(isym)+(ii-1)*novvvt(isym)+1
      call mxmtp2(buf1,eints,fints(ad1),t2,ccc,aaa(ad1),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,i,j,k,
     &            isym,jsym,ksym,mxv3,ndime)
      call wtgt(tx(21))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(27))
      call wtst
c
c (ia:cf)*t2(jb:kf)
      ad1=iovvvt(isym)+(ii-1)*novvvt(isym)+1
      call mxmtp2(buf2,eints,fints(ad1),t2,ccc,aaa(ad1),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,i,k,j,
     &            isym,ksym,jsym,mxv3,ndime)
      call wtgt(tx(22))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(28))
      call wtst
c
c (kc:af)*t2(jb:if)
      ad1=iovvvt(ksym)+(kk-1)*novvvt(ksym)+1
      call mxmtp2(buf1,eints,fints(ad1),t2,ccc,aaa(ad1),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,k,i,j,
     &            ksym,isym,jsym,mxv3,ndime)
      call wtgt(tx(23))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(29))
      call wtst
c
c (kc:bf)*t2(ia:jf)
      ad1=iovvvt(ksym)+(kk-1)*novvvt(ksym)+1
      call mxmtp2(buf2,eints,fints(ad1),t2,ccc,aaa(ad1),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,k,j,i,
     &            ksym,jsym,isym,mxv3,ndime)
      call wtgt(tx(24))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(30))
      call wtst
c
c (jb:cf)*t2(ia:kf)
      ad1=iovvvt(jsym)+(jj-1)*novvvt(jsym)+1
      call mxmtp2(buf1,eints,fints(ad1),t2,ccc,aaa(ad1),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,j,k,i,
     &            jsym,ksym,isym,mxv3,ndime)
      call wtgt(tx(25))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(31))
      call wtst
c
c (jb:af)*t2(kc:if)
      ad1=iovvvt(jsym)+(jj-1)*novvvt(jsym)+1
      call mxmtp2(buf2,eints,fints(ad1),t2,ccc,aaa(ad1),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,j,i,k,
     &            jsym,isym,ksym,mxv3,ndime)
      call wtgt(tx(26))
      call wtst
c
  104 continue
  102 continue
  101 continue
  100 continue
c
c
      emp4t = emp4t/a3
      write(iw,1) emp4t
      if(iopt.eq.6) then
      write(iw,5) eccsd+emp4t
      else
      write(iw,4) eccsd+emp4t
      end if
      eccsd=eccsd+emp4t
   1  format(/  ,2x,'triples : mp4+mp5 =  ',f25.15)
   4  format(    2x,'ccsd(t)   energy  =  ',f25.15,//)
   5  format(    2x,'qcisd(t)  energy  =  ',f25.15,//)
c
      do 9823 i=2,6
      tx(1)=tx(1)+tx(i)
      tx(7)=tx(7)+tx(6+i)
      tx(21)=tx(21)+tx(20+i)
      tx(27)=tx(27)+tx(26+i)
 9823 continue
      write(iw,9824)tx(1),tx(7),tx(15),tx(16),tx(13),tx(14),tx(17),
     &             tx(21),tx(27),
     &             tx(1)+tx(7)+tx(15)+tx(16)+tx(13)+tx(14)+tx(17)+
     &             tx(21)+tx(27)
 9824 format(8x,' **** timing  information ****',8x,/,
     &' mp(4) e and f integral mxm    ',e15.5,/,
     &'                        sorts  ',e15.5,/,
     &' mp(5) d integral term         ',e15.5,/,
     &' final energy,epsilon          ',e15.5,/,
     &' eta,zeta - intermediates      ',e15.5,/,
     &' eta,zeta - mxm                ',e15.5,/,
     &' mmm - intermediate            ',e15.5,/,
     &' gamma,aaa,ccc          mxm    ',e15.5,/,
     &' gamma,aaa,ccc          sorts  ',e15.5,/,
     &' total                         ',e15.5,/)
c
      return
      end
_EXTRACT(nvccsd1,hp800)
_IF(hpux11)
c HP compiler bug JAGae55153
c$HP$ OPTIMIZE LEVEL2 
_ENDIF
      subroutine goct3(t1,t2,dints,eints,buf1,buf2,buf3,
     &                   eta,zeta,epo,epv,gam,ccc,ee,flov,
     &                   npr,isqov,isqvo,isqoo,isqvv,iovvvt,iovvv,
     &                   novvvt,orbsym,ifd4,ife1,eccsd,iopt,ndimd,
     &                   ndime,ndimf,mxv3,idx1,idx2,jdx1,jdx2,istrt,
     &                   itrio,ifd3,debug)
      implicit integer(a-z)
      parameter(lntx=40)
      integer flov(nirred,4),npr(nirred,3,2),isqov(nsqov),
     &        isqvo(nsqov),isqoo(nsqoo),isqvv(nsqvv),iovvvt(nirred),
     &        iovvv(nirred,nirred),novvvt(nirred),orbsym(nbf),
     &        ifd4(nirred),ife1(nirred),idx1(nsqvv),idx2(nsqvv),
     &        jdx1(nirred),jdx2(nirred,nirred),istrt(no),
     &        itrio(ntrio),ifd3(nirred)
      REAL t1(ndimt1),t2(ndimw),dints(ndimd),eints(ndime),
     &       buf1(mxv3),buf2(mxv3),buf3(mxv3),
     &       eta(ndimt1),zeta(ndimd),epo(no),epv(nv),gam(ndimw),
     &       ccc(ndime),ee(nbf)
      REAL tx(lntx)
      REAL d1,d2,d3,d4,d5,fac3
      REAL emp4t,eccsd
      REAL x1,x2,x3,y1,y2,y3,x11,y11,e1
c
INCLUDE(common/t_adata)
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      character *1 xn, xt
      data xn, xt / 'n', 't' /
c
      call vclr(tx,1,lntx)
c
c  we have f integrals, e integrals and t2 in memory; form emp4(t)
c  form w(a,b,c) for a given i,j,k
c
      icnt=0
      do 900 absym=1,nirred
      jdx1(absym)=icnt
      do 902 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 904 a=flov(asym,3)-no,flov(asym,4)-no
      do 906 b=flov(bsym,3)-no,flov(bsym,4)-no
      icnt=icnt+1
      idx1(icnt)=isqvv((b-1)*nv+a)
  906 continue
  904 continue
  902 continue
  900 continue
c
      call vclr(eta,1,ndimt1)
      call vclr(zeta,1,ndimd)
      call vclr(epo,1,no)
      call vclr(epv,1,nv)
      call vclr(gam,1,ndimw)
      call vclr(ccc,1,ndime)
c
      call vclr(buf1,1,mxv3)
      do 10 i=1,no
        isym = orbsym(i) + 1
        call rsetsa(itap98,istrt(i))
        call swrit(itap98,buf1,intowp(novvvt(isym)))
   10 continue
c
      emp4t = a0
      do 100 ijksym=1,nirred
c
      icnt=0
      do 910 asym=1,nirred
      bcsym=IXOR32(ijksym-1,asym-1)+1
      do 912 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      acsym=IXOR32(asym-1,csym-1)+1
      nvb=flov(bsym,4)-flov(bsym,3)+1
      nvc=flov(csym,4)-flov(csym,3)+1
      jdx2(asym,bsym)=icnt
      do 914 b=1,nvb
      off1=(b-1)*npr(acsym,2,2)-1
      off2=icnt+(b-1)*nvc
      do 916 c=1,nvc
      idx2(off2+c)=off1+c
  916 continue
  914 continue
      icnt=icnt+nvc*nvb
  912 continue
  910 continue
c
      do 101 i = 1,no
      isym = orbsym(i) + 1
      ii=i-flov(isym,1)+1
      d1 = ee(i)
ctjl      call rsetsa(itap99,istrt(i))
ctjl      call tit_sread(itap99,fints(1,1),intowp(novvvt(isym)))
ctjl      call vclr(aaa(1,1),1,novvvt(isym))
      do 102 j = 1,i
      jsym = orbsym(j) + 1
      ijsym=IXOR32(isym-1,jsym-1)+1
      ksym=IXOR32(ijksym-1,ijsym-1)+1
      if (ksym.gt.jsym)goto 102
      iksym=IXOR32(isym-1,ksym-1)+1
      jksym=IXOR32(jsym-1,ksym-1)+1
      jj=j-flov(jsym,1)+1
      d2 = d1 + ee(j)
ctjl      if (j.eq.i)then
ctjl      call rcopy(novvvt(jsym),fints(1,1),1,fints(1,2),1)
ctjl      else
ctjl      call rsetsa(itap99,istrt(j))
ctjl      call tit_sread(itap99,fints(1,2),intowp(novvvt(jsym)))
ctjl      endif
ctjl      call vclr(aaa(1,2),1,novvvt(jsym))
      limk = min(flov(ksym,2),j)
      do 104 k = flov(ksym,1),limk
      if(k.eq.i) go to 104
      ksym = orbsym(k) + 1
      kk=k-flov(ksym,1)+1
      d3 = d2 + ee(k)
ctjl      if (k.eq.i)then
ctjl      call rcopy(novvvt(ksym),fints(1,1),1,fints(1,3),1)
ctjl      else if (k.eq.j)then
ctjl      call rcopy(novvvt(ksym),fints(1,2),1,fints(1,3),1)
ctjl      else
ctjl      call rsetsa(itap99,istrt(k))
ctjl      call tit_sread(itap99,fints(1,3),intowp(novvvt(ksym)))
ctjl      endif
ctjl      call vclr(aaa(1,3),1,novvvt(ksym))
c
      if (i.eq.j.or.j.eq.k)then
        fac3=a3
      else
        fac3=a6
      endif
      len=novvvt(ijksym)
      call vclr(buf1,1,len)
c
c - form w intermediate
c
c (ia:bf)*t2(kc:jf)
c  read in fints for i
      call rsetsa(itap99,istrt(i))
      call tit_sread(itap99,buf3,intowp(novvvt(isym)))
c
      call wtst
      call mxmtp1(buf1,eints,buf3,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,j,k,isym,jsym,ksym,mxv3,ndime)
      call wtgt(tx(1))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(7))
      call wtst
c
c (ia:cf)*t2(jb:kf)
      call mxmtp1(buf2,eints,buf3,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,k,j,isym,ksym,jsym,mxv3,ndime)
      call wtgt(tx(2))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(8))
      call wtst
c
c (kc:af)*t2(jb:if)
c  read in fints for k
      call rsetsa(itap99,istrt(k))
      call tit_sread(itap99,buf3,intowp(novvvt(ksym)))
c
      call mxmtp1(buf1,eints,buf3,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,i,j,ksym,isym,jsym,mxv3,ndime)
      call wtgt(tx(3))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(9))
      call wtst
c
c (kc:bf)*t2(ia:jf)
      call mxmtp1(buf2,eints,buf3,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,j,i,ksym,jsym,isym,mxv3,ndime)
      call wtgt(tx(4))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(10))
      call wtst
c
c (jb:cf)*t2(ia:kf)
c  read in fints for j
      call rsetsa(itap99,istrt(j))
      call tit_sread(itap99,buf3,intowp(novvvt(jsym)))
c
      call mxmtp1(buf1,eints,buf3,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,k,i,jsym,ksym,isym,mxv3,ndime)
      call wtgt(tx(5))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
c (jb:af)*t2(kc:if)
      call mxmtp1(buf2,eints,buf3,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,i,k,jsym,isym,ksym,mxv3,ndime)
      call wtgt(tx(6))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(12))
      call wtst
c
c - form intermediate for zeta and eta
      do 340 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 342 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no
      d4=d3-ee(c+no)
      do 344 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 344
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 346 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b,lima)
      do 348 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no
      ixabc=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixacb=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixcba=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
      ixbca=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
      x1=buf1(ixabc)+buf1(ixbca)+buf1(ixcab)
      x2=buf1(ixcba)+buf1(ixacb)+buf1(ixbac)
      y1=x1-x2-x2
      y2=x2-x1-x1
      buf2(ixabc)=(a3*buf1(ixabc)+y1)/(d5-ee(a+no))
      buf2(ixacb)=(a3*buf1(ixacb)+y2)/(d5-ee(a+no))
      buf2(ixcab)=(a3*buf1(ixcab)+y1)/(d5-ee(a+no))
      buf2(ixcba)=(a3*buf1(ixcba)+y2)/(d5-ee(a+no))
      buf2(ixbca)=(a3*buf1(ixbca)+y1)/(d5-ee(a+no))
      buf2(ixbac)=(a3*buf1(ixbac)+y2)/(d5-ee(a+no))
  348 continue
  346 continue
  344 continue
  342 continue
  340 continue
      call wtgt(tx(13))
      call wtst
c
c -- compute eta and zeta
c (ia:jb)*t1(kc)
      lnab=npr(ijsym,2,2)
      lnc=flov(ksym,4)-flov(ksym,3)+1
      ad1=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*lnab+1
      ad2=isqvo((k-1)*nv+flov(ksym,3)-no)
      ad3=iovvv(ijksym,ksym)+1
      if (lnab*lnc.ne.0)then
      call dgemm(xt,xn,lnc,1,lnab
     +          ,fac3,buf2(ad3),lnab,dints(ad1)
     +          ,lnab,a1,eta(ad2),lnc)
      call dgemm(xn,xn,lnab,1,lnc
     +          ,fac3,buf2(ad3),lnab,t1(ad2)
     +          ,lnc,a1,zeta(ad1),lnab)
      endif
c
c (ia:kc)*t1(jb)
      lnb=flov(jsym,4)-flov(jsym,3)+1
      do 370 csym=1,nirred
      asym=IXOR32(iksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnac=npr(iksym,2,2)
      lna=flov(asym,4)-flov(asym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(jsym,3)-no-1)*nv+flov(asym,3)-no)
      do 372 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd3(iksym)+(itrio(i*(i-1)/2+k)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad2=isqvo((j-1)*nv+flov(jsym,3)-no)
      if (lna*lnb.ne.0)then
      call dgemm(xt,xn,lnb,1,lna
     +          ,fac3,buf2(ad3),lna,dints(ad1)
     +          ,lna,a1,eta(ad2),lnb)
      call dgemm(xn,xn,lna,1,lnb
     +          ,fac3,buf2(ad3),lna,t1(ad2)
     +          ,lnb,a1,zeta(ad1),lna)
      endif
      ad3=ad3+lnab
  372 continue
  370 continue
c
c (jb:kc)*t1(ia)
      lna=flov(isym,4)-flov(isym,3)+1
      do 380 csym=1,nirred
      bsym=IXOR32(jksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnbc=npr(jksym,2,2)
      lnb=flov(bsym,4)-flov(bsym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(bsym,3)-no-1)*nv+flov(isym,3)-no)
      do 382 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd3(jksym)+(itrio(j*(j-1)/2+k)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad2=isqvo((i-1)*nv+flov(isym,3)-no)
      if (lna*lnb.ne.0)then
      call dgemm(xt,xn,lnb,1,lna
     +          ,fac3,buf2(ad3),lna,t1(ad2)
     +          ,lna,a1,zeta(ad1),lnb)
      call dgemm(xn,xn,lna,1,lnb
     +          ,fac3,buf2(ad3),lna,dints(ad1)
     +          ,lnb,a1,eta(ad2),lna)
      endif
      ad3=ad3+lnab
  382 continue
  380 continue
      call wtgt(tx(14))
      call wtst
c
c -- compute mp5 term - v
      do 601 abc=1,len
      buf2(abc)=buf1(abc)
  601 continue
c (ia:jb)*t1(kc)
      lnab=npr(ijsym,2,2)
      lnc=flov(ksym,4)-flov(ksym,3)+1
      ad1=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*lnab+1
      ad2=isqvo((k-1)*nv+flov(ksym,3)-no)
      ad3=iovvv(ijksym,ksym)+1
_IF1()c      call mxmb(dints(ad1),1,lnab,t1(ad2),1,1,buf2(ad3),1,lnab,
_IF1()c     &          lnab,1,lnc)
      if (lnab*lnc.ne.0)then
      call dgemm(xn,xn,lnab,lnc,1
     +          ,a1,dints(ad1),lnab,t1(ad2)
     +          ,1,a1,buf2(ad3),lnab)
      endif
c
c (ia:kc)*t1(jb)
      lnb=flov(jsym,4)-flov(jsym,3)+1
      do 270 csym=1,nirred
      asym=IXOR32(iksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnac=npr(iksym,2,2)
      lna=flov(asym,4)-flov(asym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(jsym,3)-no-1)*nv+flov(asym,3)-no)
      do 272 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd3(iksym)+(itrio(i*(i-1)/2+k)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad2=isqvo((j-1)*nv+flov(jsym,3)-no)
_IF1()c      call mxmb(dints(ad1),1,lna,t1(ad2),1,1,buf2(ad3),1,lna,
_IF1()c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,dints(ad1),lna,t1(ad2)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  272 continue
  270 continue
c
c (jb:kc)*t1(ia)
      lna=flov(isym,4)-flov(isym,3)+1
      do 280 csym=1,nirred
      bsym=IXOR32(jksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnbc=npr(jksym,2,2)
      lnb=flov(bsym,4)-flov(bsym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(bsym,3)-no-1)*nv+flov(isym,3)-no)
      do 282 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd3(jksym)+(itrio(j*(j-1)/2+k)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad2=isqvo((i-1)*nv+flov(isym,3)-no)
c      call mxmb(t1(ad2),1,lna,dints(ad1),1,1,buf2(ad3),1,lna,
c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,t1(ad2),lna,dints(ad1)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  282 continue
  280 continue
      call wtgt(tx(15))
      call wtst
c
c -- compute triples energy and epsilons
      do 320 b=1,flov(ijksym,4)-flov(ijksym,3)+1
      off1=iovvv(ijksym,ijksym)+(b-1)*npr(1,2,2)
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 322 a=1,nv
      off2=off1+isqvv(a*(nv+1)-nv)
      buf2(off2)=buf2(off2)*ap5
  322 continue
  320 continue
c
      do 330 asym=1,nirred
      absym=IXOR32(asym-1,ijksym-1)+1
      do 332 a=flov(asym,3)-no,flov(asym,4)-no
      off1=iovvv(ijksym,asym)+(a-flov(asym,3)+no)*npr(absym,2,2)
      aof=(a-1)*nv
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 334 b=flov(ijksym,3)-no,flov(ijksym,4)-no
      ixyzy=off1+isqvv((b-1)*nv+a)
      ixzyy=off1+isqvv(aof+b)
      buf2(ixyzy)=buf2(ixyzy)*ap5
      buf2(ixzyy)=buf2(ixzyy)*ap5
  334 continue
  332 continue
  330 continue
c
      e1=a0
      do 250 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 252 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no+1
      d4=d3-ee(c+no)
      do 254 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 254
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 256 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no+1
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b-1,lima)
      do 258 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no+1
      ixabc=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixacb=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixcba=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
      ixbca=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
c  a>b>c
      x1=buf2(ixabc)+buf2(ixbca)+buf2(ixcab)
      x2=buf2(ixacb)+buf2(ixbac)+buf2(ixcba)
      y1=buf1(ixabc)+buf1(ixbca)+buf1(ixcab)
      y2=buf1(ixacb)+buf1(ixbac)+buf1(ixcba)
      x3=(x1-x2-x2)*y1+(x2-x1-x1)*y2
      y3=a3*(buf1(ixabc)*buf2(ixabc)+buf1(ixacb)*buf2(ixacb)+
     &       buf1(ixbac)*buf2(ixbac)+buf1(ixbca)*buf2(ixbca)+
     &       buf1(ixcab)*buf2(ixcab)+buf1(ixcba)*buf2(ixcba))
      x11=(x3+y3)*fac3/(d5-ee(a+no))
      y11=x11/(d5-ee(a+no))
      e1=e1+x11
      epo(i)=epo(i)-y11
      epv(a)=epv(a)-y11
      epo(j)=epo(j)-y11
      epv(b)=epv(b)-y11
      epo(k)=epo(k)-y11
      epv(c)=epv(c)-y11
  258 continue
  256 continue
  254 continue
  252 continue
  250 continue
      emp4t=emp4t+e1
      call wtgt(tx(16))
      call wtst
c 
c -- compute m
      do 820 b=1,flov(ijksym,4)-flov(ijksym,3)+1
      off1=iovvv(ijksym,ijksym)+(b-1)*npr(1,2,2)
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 822 a=1,nv
      off2=off1+isqvv(a*(nv+1)-nv)
      buf2(off2)=buf2(off2)+buf2(off2)
  822 continue
  820 continue
c
      do 830 asym=1,nirred
      absym=IXOR32(asym-1,ijksym-1)+1
      do 832 a=flov(asym,3)-no,flov(asym,4)-no
      off1=iovvv(ijksym,asym)+(a-flov(asym,3)+no)*npr(absym,2,2)
      aof=(a-1)*nv
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 834 b=flov(ijksym,3)-no,flov(ijksym,4)-no
      ixyzy=off1+isqvv((b-1)*nv+a)
      ixzyy=off1+isqvv(aof+b)
      buf2(ixyzy)=buf2(ixyzy)+buf2(ixyzy)
      buf2(ixzyy)=buf2(ixzyy)+buf2(ixzyy)
  834 continue
  832 continue
  830 continue
c
      icnt=0
      do 300 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 302 c=flov(csym,3)-no,flov(csym,4)-no
      d4=d3-ee(c+no)
      do 304 bsym=1,nirred
      asym=IXOR32(absym-1,bsym-1)+1
      do 306 b=flov(bsym,3)-no,flov(bsym,4)-no
      d5=d4-ee(b+no)
      do 308 a=flov(asym,3),flov(asym,4)
      icnt=icnt+1
      buf2(icnt)=fac3*(buf1(icnt)+buf2(icnt))/(d5-ee(a))
  308 continue
  306 continue
  304 continue
  302 continue
  300 continue
c
      do 740 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 742 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no
      d4=d3-ee(c+no)
      do 744 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 744
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 746 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b,lima)
      do 748 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no
      ixabc=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixacb=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixcba=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
      ixbca=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
      x1=buf2(ixabc)+buf2(ixbca)+buf2(ixcab)
      x2=buf2(ixcba)+buf2(ixacb)+buf2(ixbac)
      y1=x1-x2-x2
      y2=x2-x1-x1
      buf1(ixabc)=a3*buf2(ixabc)+y1
      buf1(ixacb)=a3*buf2(ixacb)+y2
      buf1(ixcab)=a3*buf2(ixcab)+y1
      buf1(ixcba)=a3*buf2(ixcba)+y2
      buf1(ixbca)=a3*buf2(ixbca)+y1
      buf1(ixbac)=a3*buf2(ixbac)+y2
  748 continue
  746 continue
  744 continue
  742 continue
  740 continue
      call wtgt(tx(17))
c
c (ia:bf)*t2(kc:jf)
c  read in fints for i; zero out buf3 for aaa for i
      call rsetsa(itap99,istrt(i))
      call tit_sread(itap99,buf2,intowp(novvvt(isym)))
      call vclr(buf3,1,mxv3)
c
      call wtst
      call mxmtp2(buf1,eints,buf2,t2,ccc,buf3,gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,i,j,k,
     &            isym,jsym,ksym,mxv3,ndime)
      call wtgt(tx(21))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(27))
c  read in fints for i
      call rsetsa(itap99,istrt(i))
      call tit_sread(itap99,buf1,intowp(novvvt(isym)))
c
c (ia:cf)*t2(jb:kf)
      call wtst
      call mxmtp2(buf2,eints,buf1,t2,ccc,buf3,gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,i,k,j,
     &            isym,ksym,jsym,mxv3,ndime)
      call wtgt(tx(22))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(28))
c  write out aaa for i
      call rsetsa(itap98,istrt(i))
      call tit_sread(itap98,buf2,intowp(novvvt(isym)))
      call vadd(buf2,1,buf3,1,buf2,1,novvvt(isym))
      call rsetsa(itap98,istrt(i))
      call swrit(itap98,buf2,intowp(novvvt(isym)))
c
c (kc:af)*t2(jb:if)
c  read in fints for k; zero out buf3 for aaa for k
      call rsetsa(itap99,istrt(k))
      call tit_sread(itap99,buf2,intowp(novvvt(ksym)))
      call vclr(buf3,1,mxv3)
c
      call wtst
      call mxmtp2(buf1,eints,buf2,t2,ccc,buf3,gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,k,i,j,
     &            ksym,isym,jsym,mxv3,ndime)
      call wtgt(tx(23))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(29))
c  read in fints for k
      call rsetsa(itap99,istrt(k))
      call tit_sread(itap99,buf1,intowp(novvvt(ksym)))
c
c (kc:bf)*t2(ia:jf)
      call wtst
      call mxmtp2(buf2,eints,buf1,t2,ccc,buf3,gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,k,j,i,
     &            ksym,jsym,isym,mxv3,ndime)
      call wtgt(tx(24))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(30))
c  write out aaa for k
      call rsetsa(itap98,istrt(k))
      call tit_sread(itap98,buf2,intowp(novvvt(ksym)))
      call vadd(buf2,1,buf3,1,buf2,1,novvvt(ksym))
      call rsetsa(itap98,istrt(k))
      call swrit(itap98,buf2,intowp(novvvt(ksym)))
c
c (jb:cf)*t2(ia:kf)
c  read in fints for j; zero out buf3 for aaa for j
      call rsetsa(itap99,istrt(j))
      call tit_sread(itap99,buf2,intowp(novvvt(jsym)))
      call vclr(buf3,1,mxv3)
c
      call wtst
      call mxmtp2(buf1,eints,buf2,t2,ccc,buf3,gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,j,k,i,
     &            jsym,ksym,isym,mxv3,ndime)
      call wtgt(tx(25))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(31))
c  read in fints for j
      call rsetsa(itap99,istrt(j))
      call tit_sread(itap99,buf1,intowp(novvvt(jsym)))
c
c (jb:af)*t2(kc:if)
      call wtst
      call mxmtp2(buf2,eints,buf1,t2,ccc,buf3,gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,j,i,k,
     &            jsym,isym,ksym,mxv3,ndime)
      call wtgt(tx(26))
c  write out aaa for j
      call rsetsa(itap98,istrt(j))
      call tit_sread(itap98,buf2,intowp(novvvt(jsym)))
      call vadd(buf2,1,buf3,1,buf2,1,novvvt(jsym))
      call rsetsa(itap98,istrt(j))
      call swrit(itap98,buf2,intowp(novvvt(jsym)))
c
      call wtst
c
ctjl      if (k.eq.i)then
ctjl        call vadd(aaa(1,1),1,aaa(1,3),1,aaa(1,1),1,novvvt(ksym))
ctjl      else if (k.eq.j)then
ctjl        call vadd(aaa(1,2),1,aaa(1,3),1,aaa(1,2),1,novvvt(ksym))
ctjl      else
ctjl        call rsetsa(itap98,istrt(k))
ctjl        call tit_sread(itap98,buf1,intowp(novvvt(ksym)))
ctjl        call vadd(buf1,1,aaa(1,3),1,buf1,1,novvvt(ksym))
ctjl        call rsetsa(itap98,istrt(k))
ctjl        call swrit(itap98,buf1,intowp(novvvt(ksym)))
ctjl      endif
  104 continue
ctjl      if (j.eq.i)then
ctjl        call vadd(aaa(1,1),1,aaa(1,2),1,aaa(1,1),1,novvvt(jsym))
ctjl      else
ctjl        call rsetsa(itap98,istrt(j))
ctjl        call tit_sread(itap98,buf1,intowp(novvvt(jsym)))
ctjl        call vadd(buf1,1,aaa(1,2),1,buf1,1,novvvt(jsym))
ctjl        call rsetsa(itap98,istrt(j))
ctjl        call swrit(itap98,buf1,intowp(novvvt(jsym)))
ctjl      endif
  102 continue
ctjl      call rsetsa(itap98,istrt(i))
ctjl      call tit_sread(itap98,buf1,intowp(novvvt(isym)))
ctjl      call vadd(buf1,1,aaa(1,1),1,buf1,1,novvvt(isym))
ctjl      call rsetsa(itap98,istrt(i))
ctjl      call swrit(itap98,buf1,intowp(novvvt(isym)))
  101 continue
  100 continue
c
      emp4t = emp4t/a3
      write(iw,1) emp4t
      if(iopt.eq.6) then
      write(iw,5) eccsd+emp4t
      else
      write(iw,4) eccsd+emp4t
      end if
      eccsd=eccsd+emp4t
   1  format(/  ,2x,'triples : mp4+mp5 =  ',f25.15)
   4  format(    2x,'ccsd(t)   energy  =  ',f25.15,//)
   5  format(    2x,'qcisd(t)  energy  =  ',f25.15,//)
c
      do 9823 i=2,6
      tx(1)=tx(1)+tx(i)
      tx(7)=tx(7)+tx(6+i)
      tx(21)=tx(21)+tx(20+i)
      tx(27)=tx(27)+tx(26+i)
 9823 continue
      write(iw,9824)tx(1),tx(7),tx(15),tx(16),tx(13),tx(14),tx(17),
     &             tx(21),tx(27),
     &             tx(1)+tx(7)+tx(15)+tx(16)+tx(13)+tx(14)+tx(17)+
     &             tx(21)+tx(27)
 9824 format(8x,' **** timing  information ****',8x,/,
     &' mp(4) e and f integral mxm    ',e15.5,/,
     &'                        sorts  ',e15.5,/,
     &' mp(5) d integral term         ',e15.5,/,
     &' final energy,epsilon          ',e15.5,/,
     &' eta,zeta - intermediates      ',e15.5,/,
     &' eta,zeta - mxm                ',e15.5,/,
     &' mmm - intermediate            ',e15.5,/,
     &' gamma,aaa,ccc          mxm    ',e15.5,/,
     &' gamma,aaa,ccc          sorts  ',e15.5,/,
     &' total                         ',e15.5,/)
c
      return
      end
      subroutine goctrps(t1,t2,dints,eints,fints,buf1,buf2,
     &                   eta,zeta,epo,epv,gam,aaa,ccc,ee,flov,
     &                   npr,isqov,isqvo,isqoo,isqvv,iovvvt,iovvv,
     &                   novvvt,orbsym,ifd4,ife1,eccsd,iopt,ndimd,
     &                   ndime,ndimf,mxv3,idx1,idx2,jdx1,jdx2,istrt,
     &                   itrio,ifd3,debug)
      implicit integer(a-z)
      parameter(lntx=40)
      integer flov(nirred,4),npr(nirred,3,2),isqov(nsqov),
     &        isqvo(nsqov),isqoo(nsqoo),isqvv(nsqvv),iovvvt(nirred),
     &        iovvv(nirred,nirred),novvvt(nirred),orbsym(nbf),
     &        ifd4(nirred),ife1(nirred),idx1(nsqvv),idx2(nsqvv),
     &        jdx1(nirred),jdx2(nirred,nirred),istrt(no),
     &        itrio(ntrio),ifd3(nirred)
      REAL t1(ndimt1),t2(ndimw),dints(ndimd),eints(ndime),
     &       fints(mxv3,3),buf1(mxv3),buf2(mxv3),
     &       eta(ndimt1),zeta(ndimd),epo(no),epv(nv),gam(ndimw),
     &       aaa(mxv3,3),ccc(ndime),ee(nbf)
      REAL tx(lntx)
      REAL d1,d2,d3,d4,d5,fac3
      REAL emp4t,eccsd
      REAL x1,x2,x3,y1,y2,y3,x11,y11,e1
c
INCLUDE(common/t_adata)
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      character *1 xn,xt
      data xn,xt / 'n','t' / 
c
      call vclr(tx,1,lntx)
c
c  we have f integrals, e integrals and t2 in memory; form emp4(t)
c  form w(a,b,c) for a given i,j,k
c
      icnt=0
      do 900 absym=1,nirred
      jdx1(absym)=icnt
      do 902 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 904 a=flov(asym,3)-no,flov(asym,4)-no
      do 906 b=flov(bsym,3)-no,flov(bsym,4)-no
      icnt=icnt+1
      idx1(icnt)=isqvv((b-1)*nv+a)
  906 continue
  904 continue
  902 continue
  900 continue
c
      call vclr(eta,1,ndimt1)
      call vclr(zeta,1,ndimd)
      call vclr(epo,1,no)
      call vclr(epv,1,nv)
      call vclr(gam,1,ndimw)
      call vclr(ccc,1,ndime)
c
      call vclr(buf1,1,mxv3)
      do 10 i=1,no
        isym = orbsym(i) + 1
        call rsetsa(itap98,istrt(i))
        call swrit(itap98,buf1,intowp(novvvt(isym)))
   10 continue
c
      emp4t = a0
      do 100 ijksym=1,nirred
c
      icnt=0
      do 910 asym=1,nirred
      bcsym=IXOR32(ijksym-1,asym-1)+1
      do 912 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      acsym=IXOR32(asym-1,csym-1)+1
      nvb=flov(bsym,4)-flov(bsym,3)+1
      nvc=flov(csym,4)-flov(csym,3)+1
      jdx2(asym,bsym)=icnt
      do 914 b=1,nvb
      off1=(b-1)*npr(acsym,2,2)-1
      off2=icnt+(b-1)*nvc
      do 916 c=1,nvc
      idx2(off2+c)=off1+c
  916 continue
  914 continue
      icnt=icnt+nvc*nvb
  912 continue
  910 continue
c
      do 101 i = 1,no
      isym = orbsym(i) + 1
      ii=i-flov(isym,1)+1
      d1 = ee(i)
      call rsetsa(itap99,istrt(i))
      call tit_sread(itap99,fints(1,1),intowp(novvvt(isym)))
      call vclr(aaa(1,1),1,novvvt(isym))
      do 102 j = 1,i
c      do 102 j = 1,no
      jsym = orbsym(j) + 1
      ijsym=IXOR32(isym-1,jsym-1)+1
      ksym=IXOR32(ijksym-1,ijsym-1)+1
      if (ksym.gt.jsym)goto 102
      iksym=IXOR32(isym-1,ksym-1)+1
      jksym=IXOR32(jsym-1,ksym-1)+1
      jj=j-flov(jsym,1)+1
      d2 = d1 + ee(j)
      if (j.eq.i)then
      call rcopy(novvvt(jsym),fints(1,1),1,fints(1,2),1)
      else
      call rsetsa(itap99,istrt(j))
      call tit_sread(itap99,fints(1,2),intowp(novvvt(jsym)))
      endif
      call vclr(aaa(1,2),1,novvvt(jsym))
      limj=min(flov(ksym,2),j)
c      do 104 k = flov(ksym,1),flov(ksym,2)
      do 104 k = flov(ksym,1),limj
      if(k.eq.i) go to 104
      ksym = orbsym(k) + 1
      kk=k-flov(ksym,1)+1
      d3 = d2 + ee(k)
      if (k.eq.i)then
      call rcopy(novvvt(ksym),fints(1,1),1,fints(1,3),1)
      else if (k.eq.j)then
      call rcopy(novvvt(ksym),fints(1,2),1,fints(1,3),1)
      else
      call rsetsa(itap99,istrt(k))
      call tit_sread(itap99,fints(1,3),intowp(novvvt(ksym)))
      endif
      call vclr(aaa(1,3),1,novvvt(ksym))
c
      if (i.eq.j.or.j.eq.k)then
        fac3=a3
      else
        fac3=a6
      endif
      len=novvvt(ijksym)
      call vclr(buf1,1,len)
c
c - form w intermediate
c
c (ia:bf)*t2(kc:jf)
      call wtst
      call mxmtp1(buf1,eints,fints(1,1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,j,k,isym,jsym,ksym,mxv3,ndime)
      call wtgt(tx(1))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(7))
      call wtst
c
c (ia:cf)*t2(jb:kf)
      call mxmtp1(buf2,eints,fints(1,1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,k,j,isym,ksym,jsym,mxv3,ndime)
      call wtgt(tx(2))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(8))
      call wtst
c
c (kc:af)*t2(jb:if)
      call mxmtp1(buf1,eints,fints(1,3),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,i,j,ksym,isym,jsym,mxv3,ndime)
      call wtgt(tx(3))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(9))
      call wtst
c
c (kc:bf)*t2(ia:jf)
      call mxmtp1(buf2,eints,fints(1,3),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,j,i,ksym,jsym,isym,mxv3,ndime)
      call wtgt(tx(4))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(10))
      call wtst
c
c (jb:cf)*t2(ia:kf)
      call mxmtp1(buf1,eints,fints(1,2),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,k,i,jsym,ksym,isym,mxv3,ndime)
      call wtgt(tx(5))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
c (jb:af)*t2(kc:if)
      call mxmtp1(buf2,eints,fints(1,2),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,i,k,jsym,isym,ksym,mxv3,ndime)
      call wtgt(tx(6))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(12))
      call wtst
c
c - form intermediate for zeta and eta
      do 340 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 342 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no
      d4=d3-ee(c+no)
      do 344 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 344
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 346 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b,lima)
      do 348 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no
      ixabc=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixacb=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixcba=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
      ixbca=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
      x1=buf1(ixabc)+buf1(ixbca)+buf1(ixcab)
      x2=buf1(ixcba)+buf1(ixacb)+buf1(ixbac)
      y1=x1-x2-x2
      y2=x2-x1-x1
      buf2(ixabc)=(a3*buf1(ixabc)+y1)/(d5-ee(a+no))
      buf2(ixacb)=(a3*buf1(ixacb)+y2)/(d5-ee(a+no))
      buf2(ixcab)=(a3*buf1(ixcab)+y1)/(d5-ee(a+no))
      buf2(ixcba)=(a3*buf1(ixcba)+y2)/(d5-ee(a+no))
      buf2(ixbca)=(a3*buf1(ixbca)+y1)/(d5-ee(a+no))
      buf2(ixbac)=(a3*buf1(ixbac)+y2)/(d5-ee(a+no))
  348 continue
  346 continue
  344 continue
  342 continue
  340 continue
      call wtgt(tx(13))
      call wtst
c
c -- compute eta and zeta
c (ia:jb)*t1(kc)
      lnab=npr(ijsym,2,2)
      lnc=flov(ksym,4)-flov(ksym,3)+1
c      ad1=ifd4(ijsym)+(isqoo((j-1)*no+i)-1)*lnab+1
      ad1=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*lnab+1
      ad2=isqvo((k-1)*nv+flov(ksym,3)-no)
      ad3=iovvv(ijksym,ksym)+1
      if (lnab*lnc.ne.0)then
      call dgemm(xt,xn,lnc,1,lnab
     +          ,fac3,buf2(ad3),lnab,dints(ad1)
     +          ,lnab,a1,eta(ad2),lnc)
      call dgemm(xn,xn,lnab,1,lnc
     +          ,fac3,buf2(ad3),lnab,t1(ad2)
     +          ,lnc,a1,zeta(ad1),lnab)
      endif
c
c (ia:kc)*t1(jb)
      lnb=flov(jsym,4)-flov(jsym,3)+1
      do 370 csym=1,nirred
      asym=IXOR32(iksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnac=npr(iksym,2,2)
      lna=flov(asym,4)-flov(asym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(jsym,3)-no-1)*nv+flov(asym,3)-no)
      do 372 c=flov(csym,3)-no,flov(csym,4)-no
c      ad1=ifd4(iksym)+(isqoo((k-1)*no+i)-1)*lnac+
c     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad1=ifd3(iksym)+(itrio(i*(i-1)/2+k)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad2=isqvo((j-1)*nv+flov(jsym,3)-no)
      if (lna*lnb.ne.0)then
      call dgemm(xt,xn,lnb,1,lna
     +          ,fac3,buf2(ad3),lna,dints(ad1)
     +          ,lna,a1,eta(ad2),lnb)
      call dgemm(xn,xn,lna,1,lnb
     +          ,fac3,buf2(ad3),lna,t1(ad2)
     +          ,lnb,a1,zeta(ad1),lna)
      endif
      ad3=ad3+lnab
  372 continue
  370 continue
c
c (jb:kc)*t1(ia)
      lna=flov(isym,4)-flov(isym,3)+1
      do 380 csym=1,nirred
      bsym=IXOR32(jksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnbc=npr(jksym,2,2)
      lnb=flov(bsym,4)-flov(bsym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(bsym,3)-no-1)*nv+flov(isym,3)-no)
      do 382 c=flov(csym,3)-no,flov(csym,4)-no
c      ad1=ifd4(jksym)+(isqoo((k-1)*no+j)-1)*lnbc+
c     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad1=ifd3(jksym)+(itrio(j*(j-1)/2+k)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad2=isqvo((i-1)*nv+flov(isym,3)-no)
      if (lna*lnb.ne.0)then
      call dgemm(xt,xn,lnb,1,lna
     +          ,fac3,buf2(ad3),lna,t1(ad2)
     +          ,lna,a1,zeta(ad1),lnb)
      call dgemm(xn,xn,lna,1,lnb
     +          ,fac3,buf2(ad3),lna,dints(ad1)
     +          ,lnb,a1,eta(ad2),lna)
      endif
      ad3=ad3+lnab
  382 continue
  380 continue
      call wtgt(tx(14))
      call wtst
c
c -- compute mp5 term - v
      do 601 abc=1,len
      buf2(abc)=buf1(abc)
  601 continue
c (ia:jb)*t1(kc)
      lnab=npr(ijsym,2,2)
      lnc=flov(ksym,4)-flov(ksym,3)+1
c      ad1=ifd4(ijsym)+(isqoo((j-1)*no+i)-1)*lnab+1
      ad1=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*lnab+1
      ad2=isqvo((k-1)*nv+flov(ksym,3)-no)
      ad3=iovvv(ijksym,ksym)+1
_IF1()c      call mxmb(dints(ad1),1,lnab,t1(ad2),1,1,buf2(ad3),1,lnab,
_IF1()c     &          lnab,1,lnc)
      if (lnab*lnc.ne.0)then
      call dgemm(xn,xn,lnab,lnc,1
     +          ,a1,dints(ad1),lnab,t1(ad2)
     +          ,1,a1,buf2(ad3),lnab)
      endif
c
c (ia:kc)*t1(jb)
      lnb=flov(jsym,4)-flov(jsym,3)+1
      do 270 csym=1,nirred
      asym=IXOR32(iksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnac=npr(iksym,2,2)
      lna=flov(asym,4)-flov(asym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(jsym,3)-no-1)*nv+flov(asym,3)-no)
      do 272 c=flov(csym,3)-no,flov(csym,4)-no
c      ad1=ifd4(iksym)+(isqoo((k-1)*no+i)-1)*lnac+
c     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad1=ifd3(iksym)+(itrio(i*(i-1)/2+k)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad2=isqvo((j-1)*nv+flov(jsym,3)-no)
_IF1()c      call mxmb(dints(ad1),1,lna,t1(ad2),1,1,buf2(ad3),1,lna,
_IF1()c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,dints(ad1),lna,t1(ad2)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  272 continue
  270 continue
c
c (jb:kc)*t1(ia)
      lna=flov(isym,4)-flov(isym,3)+1
      do 280 csym=1,nirred
      bsym=IXOR32(jksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnbc=npr(jksym,2,2)
      lnb=flov(bsym,4)-flov(bsym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(bsym,3)-no-1)*nv+flov(isym,3)-no)
      do 282 c=flov(csym,3)-no,flov(csym,4)-no
c      ad1=ifd4(jksym)+(isqoo((k-1)*no+j)-1)*lnbc+
c     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad1=ifd3(jksym)+(itrio(j*(j-1)/2+k)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad2=isqvo((i-1)*nv+flov(isym,3)-no)
_IF1()c      call mxmb(t1(ad2),1,lna,dints(ad1),1,1,buf2(ad3),1,lna,
_IF1()c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,t1(ad2),lna,dints(ad1)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  282 continue
  280 continue
      call wtgt(tx(15))
      call wtst
c
c -- compute triples energy and epsilons
      do 320 b=1,flov(ijksym,4)-flov(ijksym,3)+1
      off1=iovvv(ijksym,ijksym)+(b-1)*npr(1,2,2)
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 322 a=1,nv
      off2=off1+isqvv(a*(nv+1)-nv)
      buf2(off2)=buf2(off2)*ap5
  322 continue
  320 continue
c
      do 330 asym=1,nirred
      absym=IXOR32(asym-1,ijksym-1)+1
      do 332 a=flov(asym,3)-no,flov(asym,4)-no
      off1=iovvv(ijksym,asym)+(a-flov(asym,3)+no)*npr(absym,2,2)
      aof=(a-1)*nv
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 334 b=flov(ijksym,3)-no,flov(ijksym,4)-no
      ixyzy=off1+isqvv((b-1)*nv+a)
      ixzyy=off1+isqvv(aof+b)
      buf2(ixyzy)=buf2(ixyzy)*ap5
      buf2(ixzyy)=buf2(ixzyy)*ap5
  334 continue
  332 continue
  330 continue
c
      e1=a0
      do 250 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 252 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no+1
      d4=d3-ee(c+no)
      do 254 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 254
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 256 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no+1
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b-1,lima)
      do 258 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no+1
      ixabc=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixacb=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixcba=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
      ixbca=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
c  a>b>c
      x1=buf2(ixabc)+buf2(ixbca)+buf2(ixcab)
      x2=buf2(ixacb)+buf2(ixbac)+buf2(ixcba)
      y1=buf1(ixabc)+buf1(ixbca)+buf1(ixcab)
      y2=buf1(ixacb)+buf1(ixbac)+buf1(ixcba)
      x3=(x1-x2-x2)*y1+(x2-x1-x1)*y2
      y3=a3*(buf1(ixabc)*buf2(ixabc)+buf1(ixacb)*buf2(ixacb)+
     &       buf1(ixbac)*buf2(ixbac)+buf1(ixbca)*buf2(ixbca)+
     &       buf1(ixcab)*buf2(ixcab)+buf1(ixcba)*buf2(ixcba))
      x11=(x3+y3)*fac3/(d5-ee(a+no))
      y11=x11/(d5-ee(a+no))
      e1=e1+x11
      epo(i)=epo(i)-y11
      epv(a)=epv(a)-y11
      epo(j)=epo(j)-y11
      epv(b)=epv(b)-y11
      epo(k)=epo(k)-y11
      epv(c)=epv(c)-y11
  258 continue
  256 continue
  254 continue
  252 continue
  250 continue
      emp4t=emp4t+e1
      call wtgt(tx(16))
      call wtst
c 
c -- compute m
      do 820 b=1,flov(ijksym,4)-flov(ijksym,3)+1
      off1=iovvv(ijksym,ijksym)+(b-1)*npr(1,2,2)
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 822 a=1,nv
      off2=off1+isqvv(a*(nv+1)-nv)
      buf2(off2)=buf2(off2)+buf2(off2)
  822 continue
  820 continue
c
      do 830 asym=1,nirred
      absym=IXOR32(asym-1,ijksym-1)+1
      do 832 a=flov(asym,3)-no,flov(asym,4)-no
      off1=iovvv(ijksym,asym)+(a-flov(asym,3)+no)*npr(absym,2,2)
      aof=(a-1)*nv
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 834 b=flov(ijksym,3)-no,flov(ijksym,4)-no
      ixyzy=off1+isqvv((b-1)*nv+a)
      ixzyy=off1+isqvv(aof+b)
      buf2(ixyzy)=buf2(ixyzy)+buf2(ixyzy)
      buf2(ixzyy)=buf2(ixzyy)+buf2(ixzyy)
  834 continue
  832 continue
  830 continue
c
      icnt=0
      do 300 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 302 c=flov(csym,3)-no,flov(csym,4)-no
      d4=d3-ee(c+no)
      do 304 bsym=1,nirred
      asym=IXOR32(absym-1,bsym-1)+1
      do 306 b=flov(bsym,3)-no,flov(bsym,4)-no
      d5=d4-ee(b+no)
      do 308 a=flov(asym,3),flov(asym,4)
      icnt=icnt+1
      buf2(icnt)=fac3*(buf1(icnt)+buf2(icnt))/(d5-ee(a))
  308 continue
  306 continue
  304 continue
  302 continue
  300 continue
c
      do 740 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 742 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no
      d4=d3-ee(c+no)
      do 744 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 744
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 746 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b,lima)
      do 748 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no
      ixabc=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+cc*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixacb=iovvv(ijksym,bsym)+bb*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixcba=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
      ixbca=iovvv(ijksym,asym)+aa*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
      x1=buf2(ixabc)+buf2(ixbca)+buf2(ixcab)
      x2=buf2(ixcba)+buf2(ixacb)+buf2(ixbac)
      y1=x1-x2-x2
      y2=x2-x1-x1
      buf1(ixabc)=a3*buf2(ixabc)+y1
      buf1(ixacb)=a3*buf2(ixacb)+y2
      buf1(ixcab)=a3*buf2(ixcab)+y1
      buf1(ixcba)=a3*buf2(ixcba)+y2
      buf1(ixbca)=a3*buf2(ixbca)+y1
      buf1(ixbac)=a3*buf2(ixbac)+y2
  748 continue
  746 continue
  744 continue
  742 continue
  740 continue
      call wtgt(tx(17))
      call wtst
c
c (ia:bf)*t2(kc:jf)
      call mxmtp2(buf1,eints,fints(1,1),t2,ccc,aaa(1,1),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,i,j,k,
     &            isym,jsym,ksym,mxv3,ndime)
      call wtgt(tx(21))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(27))
      call wtst
c
c (ia:cf)*t2(jb:kf)
      call mxmtp2(buf2,eints,fints(1,1),t2,ccc,aaa(1,1),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,i,k,j,
     &            isym,ksym,jsym,mxv3,ndime)
      call wtgt(tx(22))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(28))
      call wtst
c
c (kc:af)*t2(jb:if)
      call mxmtp2(buf1,eints,fints(1,3),t2,ccc,aaa(1,3),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,k,i,j,
     &            ksym,isym,jsym,mxv3,ndime)
      call wtgt(tx(23))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(29))
      call wtst
c
c (kc:bf)*t2(ia:jf)
      call mxmtp2(buf2,eints,fints(1,3),t2,ccc,aaa(1,3),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,k,j,i,
     &            ksym,jsym,isym,mxv3,ndime)
      call wtgt(tx(24))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(30))
      call wtst
c
c (jb:cf)*t2(ia:kf)
      call mxmtp2(buf1,eints,fints(1,2),t2,ccc,aaa(1,2),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,j,k,i,
     &            jsym,ksym,isym,mxv3,ndime)
      call wtgt(tx(25))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(31))
      call wtst
c
c (jb:af)*t2(kc:if)
      call mxmtp2(buf2,eints,fints(1,2),t2,ccc,aaa(1,2),gam,flov,npr,
     &            iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,j,i,k,
     &            jsym,isym,ksym,mxv3,ndime)
      call wtgt(tx(26))
      call wtst
c
      if (k.eq.i)then
        call vadd(aaa(1,1),1,aaa(1,3),1,aaa(1,1),1,novvvt(ksym))
      else if (k.eq.j)then
        call vadd(aaa(1,2),1,aaa(1,3),1,aaa(1,2),1,novvvt(ksym))
      else
        call rsetsa(itap98,istrt(k))
        call tit_sread(itap98,buf1,intowp(novvvt(ksym)))
        call vadd(buf1,1,aaa(1,3),1,buf1,1,novvvt(ksym))
        call rsetsa(itap98,istrt(k))
        call swrit(itap98,buf1,intowp(novvvt(ksym)))
      endif
  104 continue
      if (j.eq.i)then
        call vadd(aaa(1,1),1,aaa(1,2),1,aaa(1,1),1,novvvt(jsym))
      else
        call rsetsa(itap98,istrt(j))
        call tit_sread(itap98,buf1,intowp(novvvt(jsym)))
        call vadd(buf1,1,aaa(1,2),1,buf1,1,novvvt(jsym))
        call rsetsa(itap98,istrt(j))
        call swrit(itap98,buf1,intowp(novvvt(jsym)))
      endif
  102 continue
      call rsetsa(itap98,istrt(i))
      call tit_sread(itap98,buf1,intowp(novvvt(isym)))
      call vadd(buf1,1,aaa(1,1),1,buf1,1,novvvt(isym))
      call rsetsa(itap98,istrt(i))
      call swrit(itap98,buf1,intowp(novvvt(isym)))
  101 continue
  100 continue
c
      emp4t = emp4t/a3
      write(iw,1) emp4t
      if(iopt.eq.6) then
      write(iw,5) eccsd+emp4t
      else
      write(iw,4) eccsd+emp4t
      end if
      eccsd=eccsd+emp4t
   1  format(/  ,2x,'triples : mp4+mp5 =  ',f25.15)
   4  format(    2x,'ccsd(t)   energy  =  ',f25.15,//)
   5  format(    2x,'qcisd(t)  energy  =  ',f25.15,//)
c
      do 9823 i=2,6
      tx(1)=tx(1)+tx(i)
      tx(7)=tx(7)+tx(6+i)
      tx(21)=tx(21)+tx(20+i)
      tx(27)=tx(27)+tx(26+i)
 9823 continue
      write(iw,9824)tx(1),tx(7),tx(15),tx(16),tx(13),tx(14),tx(17),
     &             tx(21),tx(27),
     &             tx(1)+tx(7)+tx(15)+tx(16)+tx(13)+tx(14)+tx(17)+
     &             tx(21)+tx(27)
 9824 format(8x,' **** timing  information ****',8x,/,
     &' mp(4) e and f integral mxm    ',e15.5,/,
     &'                        sorts  ',e15.5,/,
     &' mp(5) d integral term         ',e15.5,/,
     &' final energy,epsilon          ',e15.5,/,
     &' eta,zeta - intermediates      ',e15.5,/,
     &' eta,zeta - mxm                ',e15.5,/,
     &' mmm - intermediate            ',e15.5,/,
     &' gamma,aaa,ccc          mxm    ',e15.5,/,
     &' gamma,aaa,ccc          sorts  ',e15.5,/,
     &' total                         ',e15.5,/)
c
      return
      end
      subroutine gtd1(tau,buf,isqoo,npr,flov,ivvoo,ivvoot,
     1                 fpbkd1,ntr)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ivvoot(nirred),
     1  isqoo(nsqoo),fpbkd1(nbkd1),ivvoo(nirred,nirred),ntr(nirred,4)
      REAL tau(ndimw),buf(lnbkt)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  sort d integrals into t2(be,ui:a)
c
      call srew(itap63)
      ibkd1 = 0
      nbeu = 0
c
      do 10 busym = 1,nirred
      lnbeu = npr(busym,3,2)
      lnia = lnbeu
c
      if(lnbeu.ne.0) then
c
      do 20 besym = 1,nirred
      usym = IXOR32(busym-1,besym-1) + 1
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fu = flov(usym,1)
      lu = flov(usym,2)
c
      nbe = lbe - fbe + 1
      do 30 be = fbe,lbe
      bof = be - fbe + 1
      do 40 u = fu,lu
      nbeu = nbeu + 1
c
      if(nbeu.eq.fpbkd1(ibkd1+1)) then
      icnt = 0
      ibkd1 = ibkd1 + 1
      call tit_sread(itap63,buf,intowp(lnbkt))
      end if
c
      do 50 asym = 1,nirred
      isym = IXOR32(busym-1,asym-1) + 1
      uisym = IXOR32(usym-1,isym-1) + 1
      fi = flov(isym,1)
      li = flov(isym,2)
      fa = flov(asym,3) - no
      la = flov(asym,4) - no
c
      aof = ivvoot(asym) + ivvoo(uisym,asym) + bof
      do 60 a = fa,la
      abof = aof + (a-fa)*ntr(asym,2)
      do 80 i = fi,li
      icnt = icnt + 1
      iuq = (i-1)*no + u
      buia = (isqoo(iuq)-1)*nbe + abof
      tau(buia) = buf(icnt)
   80 continue
   60 continue
   50 continue
   40 continue
   30 continue
   20 continue
      end if
   10 continue
c
      return
      end
      subroutine gtd12(tau,buf,isqoo,npr,flov,ivvoo,ivvoot,
     1                 fpbkd1,ntr,t2,ifd2,itriv,ioff)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ivvoot(nirred),
     1  isqoo(nsqoo),fpbkd1(nbkd1),ivvoo(nirred,nirred),ntr(nirred,4),
     2  ioff(nbf),itriv(ntriv),ifd2(nirred)
      REAL tau(ndimw),buf(lnbkt),t2(ndimw)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
INCLUDE(common/t_iter)
c
c  sort d integrals into t2(be,iu:a)
c
      call srew(itap63)
      ibkd1 = 0
      nbeu = 0
c
      do 10 busym = 1,nirred
      lnbeu = npr(busym,3,2)
      lnia = lnbeu
c
      if(lnbeu.ne.0) then
c
      do 20 besym = 1,nirred
      usym = IXOR32(busym-1,besym-1) + 1
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fu = flov(usym,1)
      lu = flov(usym,2)
c
      nbe = lbe - fbe + 1
      do 30 be = fbe,lbe
      bof = be - fbe + 1
      do 40 u = fu,lu
      nbeu = nbeu + 1
c
      if(nbeu.eq.fpbkd1(ibkd1+1)) then
      icnt = 0
      ibkd1 = ibkd1 + 1
      call tit_sread(itap63,buf,intowp(lnbkt))
      end if
c
      do 50 asym = 1,nirred
      isym = IXOR32(busym-1,asym-1) + 1
      uisym = IXOR32(usym-1,isym-1) + 1
      fi = flov(isym,1)
      li = flov(isym,2)
      fa = flov(asym,3) - no
      la = flov(asym,4) - no
c
      aof = ivvoot(asym) + ivvoo(uisym,asym) + bof
      do 60 a = fa,la
      abof = aof + (a-fa)*ntr(asym,2)
      beaof = (itriv(ioff(be)+a)-1)*npr(uisym,1,2) + ifd2(uisym)
      do 80 i = fi,li
      icnt = icnt + 1
      iuq = (u-1)*no + i
      buia = (isqoo(iuq)-1)*nbe + abof
      tau(buia) = buf(icnt)
      iuab = isqoo(iuq) + beaof
      if(be.ge.a) t2(iuab) = t2(iuab) + buf(icnt)
   80 continue
   60 continue
   50 continue
   40 continue
   30 continue
   20 continue
      end if
   10 continue
c
      return
      end
      subroutine gte1(tau,buf,isqoo,npr,flov,ivooo,ivooot,
     1                 fpbke1,ntr)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ivooot(nirred),
     1  isqoo(nsqoo),fpbke1(nbke1),ivooo(nirred,nirred),ntr(nirred,4)
      REAL tau(ndimw),buf(lnbkt)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  sort e integrals into t2(u,vi:be)
c
      call srew(itap64)
      ibke1 = 0
      nbeu = 0
c
      do 10 busym = 1,nirred
      lnbeu = npr(busym,3,2)
      lniv = npr(busym,1,2)
c
      if(lnbeu.ne.0.and.lniv.ne.0) then
c
      do 20 besym = 1,nirred
      usym = IXOR32(busym-1,besym-1) + 1
      beof = ivooot(besym) + ivooo(busym,besym)
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fu = flov(usym,1)
      lu = flov(usym,2)
c
      nu = lu - fu + 1
      do 30 be = fbe,lbe
      bof = (be-fbe)*ntr(besym,3) + beof
      do 40 u = fu,lu
      uof = u - fu + 1 + bof
      nbeu = nbeu + 1
c
      if(nbeu.eq.fpbke1(ibke1+1)) then
      icnt = 0
      ibke1 = ibke1 + 1
      call tit_sread(itap64,buf,intowp(lnbkt))
      end if
c
      do 50 isym = 1,nirred
      vsym = IXOR32(busym-1,isym-1) + 1
      fi = flov(isym,1)
      li = flov(isym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
c
      do 60 i = fi,li
      do 80 v = fv,lv
      icnt = icnt + 1
      ivq = (i-1)*no + v
      uvib = (isqoo(ivq)-1)*nu + uof
      tau(uvib) = buf(icnt)
   80 continue
   60 continue
   50 continue
   40 continue
   30 continue
   20 continue
      end if
   10 continue
c
      return
      end
      subroutine gte11(tau,buf,isqoo,npr,flov,iooov,iooovt,
     1                 fpbke1,ntr)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),iooovt(nirred),
     1  isqoo(nsqoo),fpbke1(nbke1),iooov(nirred,nirred),ntr(nirred,2)
      REAL tau(ndimw),buf(lnbkt)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  sort e integrals into t2(be,vi:u)
c
      call srew(itap64)
      ibke1 = 0
      nbeu = 0
c
      do 10 busym = 1,nirred
      lnbeu = npr(busym,3,2)
      lniv = npr(busym,1,2)
c
      if(lnbeu.ne.0.and.lniv.ne.0) then
c
      do 20 besym = 1,nirred
      usym = IXOR32(busym-1,besym-1) + 1
      uof = iooovt(usym) + iooov(busym,usym)
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fu = flov(usym,1)
      lu = flov(usym,2)
c
      nbe = lbe - fbe + 1
      do 30 be = fbe,lbe
      beof = be - fbe + 1 + uof
      do 40 u = fu,lu
      beuof = beof + (u-fu)*ntr(usym,2)
      nbeu = nbeu + 1
c
      if(nbeu.eq.fpbke1(ibke1+1)) then
      icnt = 0
      ibke1 = ibke1 + 1
      call tit_sread(itap64,buf,intowp(lnbkt))
      end if
c
      do 50 isym = 1,nirred
      vsym = IXOR32(busym-1,isym-1) + 1
      fi = flov(isym,1)
      li = flov(isym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
c
      do 60 i = fi,li
      do 80 v = fv,lv
      icnt = icnt + 1
      ivq = (i-1)*no + v
      bviu = (isqoo(ivq)-1)*nbe + beuof
      tau(bviu) = buf(icnt)
   80 continue
   60 continue
   50 continue
   40 continue
   30 continue
   20 continue
      end if
   10 continue
c
      return
      end
      subroutine gte1s(tau,buf,isqoo,npr,flov,iooov,iooovt,
     1                 fpbke1,ntr)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),iooovt(nirred),
     1  isqoo(nsqoo),fpbke1(nbke1),iooov(nirred,nirred),ntr(nirred,2)
      REAL tau(ndimw),buf(lnbkt)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  read e1 list (beu,vi)  and store as t2(be,vu:i)
c
      call srew(itap64)
      ibke1 = 0
      nbeu = 0
c
      do 10 busym = 1,nirred
      lnbeu = npr(busym,3,2)
      lniv = npr(busym,1,2)
c
      if(lnbeu.ne.0.and.lniv.ne.0) then
c
      do 20 besym = 1,nirred
      usym = IXOR32(busym-1,besym-1) + 1
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fu = flov(usym,1)
      lu = flov(usym,2)
c
      nbe = lbe - fbe + 1
      do 30 be = fbe,lbe
      do 40 u = fu,lu
      nbeu = nbeu + 1
c
      if(nbeu.eq.fpbke1(ibke1+1)) then
      icnt = 0
      ibke1 = ibke1 + 1
      call tit_sread(itap64,buf,intowp(lnbkt))
      end if
c
      do 50 isym = 1,nirred
      vsym = IXOR32(busym-1,isym-1) + 1
      uvsym = IXOR32(usym-1,vsym-1) + 1
      fi = flov(isym,1)
      li = flov(isym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      uiof = iooovt(isym) + iooov(uvsym,isym) + be - fbe + 1
c
      do 60 i = fi,li
      beiof = (i-fi)*ntr(isym,2) + uiof
      do 80 v = fv,lv
      icnt = icnt + 1
      uvq = (u-1)*no + v
      buvi = (isqoo(uvq)-1)*nbe + beiof
      tau(buvi) = buf(icnt)
   80 continue
   60 continue
   50 continue
   40 continue
   30 continue
   20 continue
      end if
   10 continue
c
      return
      end
      subroutine icrdf(fints,buf,flov,npr,iovvvt,iovvv,novvvt,
     &                fpbkf,ndimf)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),iovvvt(nirred),
     &        iovvv(nirred,nirred),novvvt(nirred),fpbkf(nbkf)
      REAL fints(ndimf),buf(lnbkt)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      call srew(itap65)
      ibkf = 0
      nbei = 0
c
      do 110 bisym = 1,nirred
      lnov = npr(bisym,3,2)
      lnvv = npr(bisym,2,2)
c
      if(lnov.ne.0.and.lnvv.ne.0) then
c
      do 120 besym = 1,nirred
      isym = IXOR32(bisym-1,besym-1) + 1
      nbe = flov(besym,4) - flov(besym,3) + 1
      nbi = flov(isym,2)  - flov(isym,1)  + 1
c
      do 130 be = 1,nbe
      do 140 i = 1,nbi
      nbei = nbei + 1
c
      if(nbei.eq.fpbkf(ibkf+1)) then
      off1 = 0
      ibkf = ibkf + 1
      call tit_sread(itap65,buf,intowp(lnbkt))
      end if
c
      ad1 = iovvvt(isym)+(i-1)*novvvt(isym) + iovvv(isym,besym) +
     &      (be-1)*lnvv
      do 150 ab=1,lnvv
      fints(ad1+ab)=buf(off1+ab)
  150 continue
      off1 = off1 + lnvv
  140 continue
  130 continue
  120 continue
      end if
  110 continue
c
      return
      end
      subroutine ictp40(eta,zeta,epo,epv,gam,aaa,ccc,buf,flov,
     &                  npr,iovvvt,iovvv,novvvt,isqvv,
     &                  ndimd,ndime,ndimf,mxv3)
      implicit integer(a-z)
      parameter(lnax=20)
      integer flov(nirred,4),npr(nirred,3,2),iovvvt(nirred),
     &        iovvv(nirred,nirred),novvvt(nirred),isqvv(nsqvv)
      REAL eta(ndimt1),zeta(ndimd),epo(no),epv(nv),gam(ndimw),
     &       aaa(ndimf),ccc(ndime),buf(lnbkt)
      integer ax(lnax)
      REAL tst1,tst2
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
      REAL fac
INCLUDE(common/t_adata)
c
      itap40=40
      call rfile(itap40)
      call srew(itap40)
      call swrit(itap40,ax,lnax)
c
      ax(1)=ndimt1
      call rgetsa(itap40,ax(2))
      call swrit(itap40,eta,intowp(ndimt1))
      tst1=a0
      call dotpr(eta,eta,ndimt1,tst1)
      write(iw,1000)'eta  ',tst1
 1000 format(' dot product of ',a5,e20.12)
c
      ax(3)=ndimw
      call rgetsa(itap40,ax(4))
      call swrit(itap40,gam,intowp(ndimw))
      tst1=a0
      call dotpr(gam,gam,ndimw,tst1)
      write(iw,1000)'gam  ',tst1
c
      ax(5)=no
      call rgetsa(itap40,ax(6))
      call swrit(itap40,epo,intowp(no))
      tst1=a0
      call dotpr(epo,epo,no,tst1)
      write(iw,1000)'epo  ',tst1
c
      ax(7)=nv
      call rgetsa(itap40,ax(8))
      call swrit(itap40,epv,intowp(nv))
      tst1=a0
      call dotpr(epv,epv,nv,tst1)
      write(iw,1000)'epv  ',tst1
c
      ax(9)=ndimd
      call rgetsa(itap40,ax(10))
      call swrit(itap40,zeta,intowp(ndimd))
      tst1=a0
      call dotpr(zeta,zeta,ndimd,tst1)
      write(iw,1000)'zet  ',tst1
c
      ax(11)=ndime
      call rgetsa(itap40,ax(12))
      call swrit(itap40,ccc,intowp(ndime))
      tst1=a0
      call dotpr(ccc,ccc,ndime,tst1)
      write(iw,1000)'ccc  ',tst1
c
      ax(13)=ndimf
      call rgetsa(itap40,ax(14))
c      call swrit(itap40,aaa,intowp(ndimf))
c      tst1=a0
c      call dotpr(aaa,aaa,ndimf,tst1)
c      write(iw,1000)'aaa1 ',tst1
c      if (tst1.gt.0.0d00)goto 1234
      fac=a1/a3
      tst1=a0
      adb=0
      do 110 asym=1,nirred
      do 112 a=flov(asym,3)-no,flov(asym,4)-no
      do 114 isym=1,nirred
      aisym=IXOR32(asym-1,isym-1)+1
      lnvv1=npr(aisym,2,1)
      nbi=flov(isym,2)-flov(isym,1)+1
      do 116 i=1,nbi
c
      if(adb+lnvv1.gt.lnbkt)then
        tst2=a0
        call dotpr(buf,buf,adb,tst2)
        tst1=tst1+tst2
        call swrit(itap40,buf,intowp(lnbkt))
        adb=0
      end if
c
      do 118 bsym=1,nirred
      fsym=IXOR32(aisym-1,bsym-1)+1
      if (fsym.gt.bsym)goto 119
      fisym=IXOR32(fsym-1,isym-1)+1
      bisym=IXOR32(bsym-1,isym-1)+1
      do 120 b=flov(bsym,3)-no,flov(bsym,4)-no
      bb=b-flov(bsym,3)+no+1
      lf=flov(fsym,4)-no
      if (bsym.eq.fsym)lf=b
      do 122 f=flov(fsym,3)-no,lf
      ff=f-flov(fsym,3)+no+1
      ad1=iovvvt(isym)+(i-1)*novvvt(isym)+iovvv(isym,fsym)+
     &    (ff-1)*npr(fisym,2,2)+isqvv((b-1)*nv+a)
      ad2=iovvvt(isym)+(i-1)*novvvt(isym)+iovvv(isym,bsym)+
     &    (bb-1)*npr(bisym,2,2)+isqvv((f-1)*nv+a)
      adb=adb+1
      buf(adb)=fac*(aaa(ad1)+aaa(ad2))
  122 continue
  120 continue
  119 continue
  118 continue
  116 continue
  114 continue
  112 continue
  110 continue
      tst2=a0
      call dotpr(buf,buf,adb,tst2)
      tst1=tst1+tst2
      call swrit(itap40,buf,intowp(lnbkt))
      write(iw,1000)'aaa  ',tst1
c
c 1234 continue
      call srew(itap40)
      call swrit(itap40,ax,lnax)
      call rclose(itap40,3)
      return
      end
      subroutine ictrps(t1,t2,dints,eints,fints,buf1,buf2,ee,flov,
     &                  npr,isqov,isqvo,isqoo,isqvv,iovvvt,iovvv,
     &                  novvvt,orbsym,ifd4,ife1,eccsd,iopt,ndimd,
     &                  ndime,ndimf,mxv3,idx1,idx2,jdx1,jdx2,itrio,
     &                  ifd3,debug)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqov(nsqov),
     &        isqvo(nsqov),isqoo(nsqoo),isqvv(nsqvv),iovvvt(nirred),
     &        iovvv(nirred,nirred),novvvt(nirred),orbsym(nbf),
     &        ifd4(nirred),ife1(nirred),idx1(nsqvv),idx2(nsqvv),
     &        jdx1(nirred),jdx2(nirred,nirred),itrio(ntrio),
     &        ifd3(nirred)
      REAL t1(ndimt1),t2(ndimt2),dints(ndimd),eints(ndime),
     &       fints(ndimf),buf1(mxv3),buf2(mxv3),ee(nbf)
      REAL a0,a1,a2,a3,a4,a5,a6,a9,ap5
      REAL d1,d2,d3,d4,d5,fac
      REAL emp4t,eccsd
      REAL x1,x2,y1,y2,e1
      REAL e11
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      REAL tst1,tst2,tst3,tst4,tst5,tst6
      REAL intget,t2get,wget,vget
      REAL tx(20)
c
      character *1 xn
      data xn / 'n' / 
      data a0,a1,a2,a3,a4,a5 /0.0d0,1.0d0,2.0d0,3.0d0,4.0d0,5.0d0/
      data a6,a9,ap5 /6.0d0,9.0d0,0.5d00/
c
      call vclr(tx,1,20)
      if (debug.gt.0)then
      print *,' testing dints'
      icnt=0
      do 1060 ijsym=1,nirred
      do 1060 isym=1,nirred
      jsym=IXOR32(ijsym-1,isym-1)+1
      do 1060 i=flov(isym,1),flov(isym,2)
      do 1060 j=flov(jsym,1),flov(jsym,2)
      do 1060 asym=1,nirred
      bsym=IXOR32(ijsym-1,asym-1)+1
      do 1060 a=flov(asym,3),flov(asym,4)
      do 1060 b=flov(bsym,3),flov(bsym,4)
      icnt=icnt+1
      tst1=intget(i,a,j,b)
      if (abs(dints(icnt)-tst1).gt.1.0d-10)then
      write(6,1062)isym,jsym,asym,bsym,i,j,a,b,dints(icnt),tst1,
     &             dints(icnt)-tst1
      endif
 1062 format(8i3,3e15.5)
 1060 continue
      print *,' end testing dints'
c
      print *,' testing eints'
      icnt=0
      do 1040 ijsym=1,nirred
      do 1040 isym=1,nirred
      jsym=IXOR32(ijsym-1,isym-1)+1
      do 1040 i=flov(isym,1),flov(isym,2)
      do 1040 j=flov(jsym,1),flov(jsym,2)
      do 1040 asym=1,nirred
      msym=IXOR32(ijsym-1,asym-1)+1
      do 1040 a=flov(asym,3),flov(asym,4)
      do 1040 m=flov(msym,1),flov(msym,2)
      icnt=icnt+1
      tst1=-intget(i,a,j,m)
      if (abs(eints(icnt)-tst1).gt.1.0d-10)then
      write(6,1042)isym,jsym,asym,msym,i,j,a,m,eints(icnt),
     &             tst1,eints(icnt)-tst1
      endif
 1042 format(8i3,3e15.5)
 1040 continue
      print *,' end testing eints'
c
      print *,' testing fints'
      icnt=0
      do 1000 isym=1,nirred
      do 1000 i=flov(isym,1),flov(isym,2)
      do 1000 fsym=1,nirred
      basym=IXOR32(isym-1,fsym-1)+1
      do 1000 f=flov(fsym,3),flov(fsym,4)
      do 1000 bsym=1,nirred
      asym=IXOR32(basym-1,bsym-1)+1
      do 1000 b=flov(bsym,3),flov(bsym,4)
      do 1000 a=flov(asym,3),flov(asym,4)
      icnt=icnt+1
      tst1=intget(f,b,i,a)
      if (abs(fints(icnt)-tst1).gt.1.0d-10)then
      write(6,1002)isym,fsym,bsym,asym,i,f,b,a,fints(icnt),
     &             tst1,fints(icnt)-tst1
      endif
 1002 format(8i3,3e15.5)
 1000 continue
      print *,' end testing fints'
c
      print *,' testing t2'
      icnt=0
      do 1020 ijsym=1,nirred
      do 1020 isym=1,nirred
      jsym=IXOR32(ijsym-1,isym-1)+1
      do 1020 i=flov(isym,1),flov(isym,2)
      do 1020 j=flov(jsym,1),flov(jsym,2)
      do 1020 asym=1,nirred
      bsym=IXOR32(ijsym-1,asym-1)+1
      do 1020 a=flov(asym,3),flov(asym,4)
      do 1020 b=flov(bsym,3),flov(bsym,4)
      icnt=icnt+1
      tst1=t2get(i,a,j,b)
      if (abs(t2(icnt)-tst1).gt.1.0d-10)then
      write(6,1022)isym,jsym,asym,bsym,i,j,a,b,t2(icnt),tst1,
     &             t2(icnt)-tst1
      endif
 1022 format(8i3,3e15.5)
 1020 continue
      print *,' end testing t2'
      endif
c
c  we have f integrals, e integrals and t2 in memory; form emp4(t)
c  form w(a,b,c) for a given i,j,k
c
      icnt=0
      do 400 absym=1,nirred
      jdx1(absym)=icnt
      do 402 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 404 a=flov(asym,3)-no,flov(asym,4)-no
      do 406 b=flov(bsym,3)-no,flov(bsym,4)-no
      icnt=icnt+1
      idx1(icnt)=isqvv((b-1)*nv+a)
  406 continue
  404 continue
  402 continue
  400 continue
      
      emp4t = a0
      do 100 ijksym=1,nirred
c
      icnt=0
      do 410 asym=1,nirred
      bcsym=IXOR32(ijksym-1,asym-1)+1
      do 412 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      acsym=IXOR32(asym-1,csym-1)+1
      nvb=flov(bsym,4)-flov(bsym,3)+1
      nvc=flov(csym,4)-flov(csym,3)+1
      jdx2(asym,bsym)=icnt
      do 414 b=1,nvb
      off1=(b-1)*npr(acsym,2,2)-1
      off2=icnt+(b-1)*nvc
      do 416 c=1,nvc
      idx2(off2+c)=off1+c
  416 continue
  414 continue
      icnt=icnt+nvc*nvb
  412 continue
  410 continue
c
      do 101 i = 1,no
      isym = orbsym(i) + 1
      ii=i-flov(isym,1)+1
      d1 = ee(i)
      do 102 j = 1,i
      jsym = orbsym(j) + 1
      ijsym=IXOR32(isym-1,jsym-1)+1
      ksym=IXOR32(ijksym-1,ijsym-1)+1
      if (ksym.gt.jsym)goto 102
      iksym=IXOR32(isym-1,ksym-1)+1
      jksym=IXOR32(jsym-1,ksym-1)+1
      jj=j-flov(jsym,1)+1
      d2 = d1 + ee(j)
      limj=min(flov(ksym,2),j)
      do 104 k = flov(ksym,1),limj
      if(k.eq.i) go to 104
      ksym = orbsym(k) + 1
      kk=k-flov(ksym,1)+1
      d3 = d2 + ee(k)
c
      len=novvvt(ijksym)
      call vclr(buf1,1,len)
c
c (ia:bf)*t2(kc:jf)
      call wtst
      ad1=iovvvt(isym)+(ii-1)*novvvt(isym)+1
      call mxmtp1(buf1,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,j,k,isym,jsym,ksym,mxv3,ndime)
      call wtgt(tx(1))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(7))
      call wtst
c
c (ia:cf)*t2(jb:kf)
      ad1=iovvvt(isym)+(ii-1)*novvvt(isym)+1
      call mxmtp1(buf2,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,k,j,isym,ksym,jsym,mxv3,ndime)
      call wtgt(tx(2))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(8))
      call wtst
c
c (kc:af)*t2(jb:if)
      ad1=iovvvt(ksym)+(kk-1)*novvvt(ksym)+1
      call mxmtp1(buf1,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,i,j,ksym,isym,jsym,mxv3,ndime)
      call wtgt(tx(3))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(9))
      call wtst
c
c (kc:bf)*t2(ia:jf)
      ad1=iovvvt(ksym)+(kk-1)*novvvt(ksym)+1
      call mxmtp1(buf2,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,j,i,ksym,jsym,isym,mxv3,ndime)
      call wtgt(tx(4))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(10))
      call wtst
c
c (jb:cf)*t2(ia:kf)
      ad1=iovvvt(jsym)+(jj-1)*novvvt(jsym)+1
      call mxmtp1(buf1,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,k,i,jsym,ksym,isym,mxv3,ndime)
      call wtgt(tx(5))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
c (jb:af)*t2(kc:if)
      ad1=iovvvt(jsym)+(jj-1)*novvvt(jsym)+1
      call mxmtp1(buf2,eints,fints(ad1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,i,k,jsym,isym,ksym,mxv3,ndime)
      call wtgt(tx(6))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
      do 228 abc=1,len
      buf2(abc)=buf1(abc)
  228 continue
c (ia:jb)*t1(kc)
      lnab=npr(ijsym,2,2)
      lnc=flov(ksym,4)-flov(ksym,3)+1
      ad1=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*lnab+1
      ad2=isqvo((k-1)*nv+flov(ksym,3)-no)
      ad3=iovvv(ijksym,ksym)+1
_IF1()c      call mxmb(dints(ad1),1,lnab,t1(ad2),1,1,buf2(ad3),1,lnab,
_IF1()c     &          lnab,1,lnc)
      if (lnab*lnc.ne.0)then
      call dgemm(xn,xn,lnab,lnc,1
     +         ,a1,dints(ad1),lnab,t1(ad2)
     +         ,1,a1,buf2(ad3),lnab)
      endif
c
c (ia:kc)*t1(jb)
      lnb=flov(jsym,4)-flov(jsym,3)+1
      do 270 csym=1,nirred
      asym=IXOR32(iksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnac=npr(iksym,2,2)
      lna=flov(asym,4)-flov(asym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(jsym,3)-no-1)*nv+flov(asym,3)-no)
      do 272 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd3(iksym)+(itrio(i*(i-1)/2+k)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad2=isqvo((j-1)*nv+flov(jsym,3)-no)
_IF1()c      call mxmb(dints(ad1),1,lna,t1(ad2),1,1,buf2(ad3),1,lna,
_IF1()c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,dints(ad1),lna,t1(ad2)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  272 continue
  270 continue
c
c (jb:kc)*t1(ia)
      lna=flov(isym,4)-flov(isym,3)+1
      do 280 csym=1,nirred
      bsym=IXOR32(jksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnbc=npr(jksym,2,2)
      lnb=flov(bsym,4)-flov(bsym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(bsym,3)-no-1)*nv+flov(isym,3)-no)
      do 282 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd3(jksym)+(itrio(j*(j-1)/2+k)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad2=isqvo((i-1)*nv+flov(isym,3)-no)
_IF1()c      call mxmb(t1(ad2),1,lna,dints(ad1),1,1,buf2(ad3),1,lna,
_IF1()c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,t1(ad2),lna,dints(ad1)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  282 continue
  280 continue
      call wtgt(tx(13))
      call wtst
c
      if (debug.gt.0)then
      write(6,9111)isym,jsym,ksym,i,j,k
 9111 format(' testing w and v: i,j,k ',/,6i5)
      off1=0
      do 9112 asym=1,nirred
      bcsym=IXOR32(asym-1,ijksym-1)+1
      do 9114 a=flov(asym,3),flov(asym,4)
      do 9116 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      do 9118 b=flov(bsym,3),flov(bsym,4)
      do 9120 c=flov(csym,3),flov(csym,4)
      off1=off1+1
      tst1=wget(i,j,k,c,b,a)
      tst2=buf1(off1)
      tst3=tst1-tst2
      tst4=vget(i,j,k,c,b,a)
      tst5=buf2(off1)
      tst6=tst4-tst5
      if (abs(tst3).gt.1.0d-10.or.abs(tst6).gt.1.0d-10)then
      write(6,9122)i,j,k,a,b,c,tst1,tst2,tst3,tst4,tst5,tst6
      endif
 9122 format(6i5,3e15.5,/,30x,3e15.5)
 9120 continue
 9118 continue
 9116 continue
 9114 continue
 9112 continue
      endif
c
c -- (a b c) ordering
      do 320 b=1,flov(ijksym,4)-flov(ijksym,3)+1
      off1=iovvv(ijksym,ijksym)+(b-1)*npr(1,2,2)
      do 322 a=1,nv
      off2=off1+isqvv(a*(nv+1)-nv)
      buf2(off2)=buf2(off2)*ap5
  322 continue
  320 continue
c
      do 330 asym=1,nirred
      absym=IXOR32(asym-1,ijksym-1)+1
      do 332 a=flov(asym,3)-no,flov(asym,4)-no
      off1=iovvv(ijksym,asym)+(a-flov(asym,3)+no)*npr(absym,2,2)
      aof=(a-1)*nv
      do 334 b=flov(ijksym,3)-no,flov(ijksym,4)-no
      ixyzy=off1+isqvv((b-1)*nv+a)
      ixzyy=off1+isqvv(aof+b)
      buf2(ixyzy)=buf2(ixyzy)*ap5
      buf2(ixzyy)=buf2(ixzyy)*ap5
  334 continue
  332 continue
  330 continue
c
      e1=a0
      e11=a0
      do 250 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 252 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no+1
      d4=d3-ee(c+no)
      do 254 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 254
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 256 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no+1
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b-1,lima)
      do 258 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no+1
      ixabc=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixacb=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixbca=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixcba=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
c  a>b>c
      x1=buf2(ixabc)+buf2(ixbca)+buf2(ixcab)
      x2=buf2(ixacb)+buf2(ixbac)+buf2(ixcba)
      y1=buf1(ixabc)+buf1(ixbca)+buf1(ixcab)
      y2=buf1(ixacb)+buf1(ixbac)+buf1(ixcba)
      fac=d5-ee(a+no)
      e1=e1+((x1-x2-x2)*y1+(x2-x1-x1)*y2)/fac
      e11=e11+(buf1(ixabc)*buf2(ixabc)+buf1(ixacb)*buf2(ixacb)+
     &         buf1(ixbac)*buf2(ixbac)+buf1(ixbca)*buf2(ixbca)+
     &         buf1(ixcab)*buf2(ixcab)+buf1(ixcba)*buf2(ixcba))/fac
  258 continue
  256 continue
  254 continue
  252 continue
  250 continue
      call wtgt(tx(14))
      call wtst
c
      if (i.eq.j.or.j.eq.k)then
      emp4t=emp4t+a3*(e1+a3*e11)
      else
      emp4t=emp4t+a6*(e1+a3*e11)
      endif
c
  104 continue
  102 continue
  101 continue
  100 continue
c
      emp4t = emp4t/a3
      write(*,1) emp4t
      if(iopt.eq.6) then
      write(*,5) eccsd+emp4t
      else
      write(*,4) eccsd+emp4t
      end if
      eccsd=eccsd+emp4t
   1  format(/  ,2x,'triples : mp4+mp5 =  ',f24.15)
   4  format(    2x,'ccsd(t)   energy  =  ',f24.15,//)
   5  format(    2x,'qcisd(t)  energy  =  ',f24.15,//)
c
      do 9823 i=2,6
      tx(1)=tx(1)+tx(i)
      tx(7)=tx(7)+tx(6+i)
 9823 continue
      write(6,9824)tx(1),tx(7),tx(13),tx(14),
     &             tx(1)+tx(7)+tx(13)+tx(14)
 9824 format(8x,' **** timing  information ****',8x,/,
     &' mp(4) e and f integral mxm    ',e15.5,/,
     &'                        sorts  ',e15.5,/,
     &' mp(5) d integral contribution ',e15.5,/,
     &' final energy summation        ',e15.5,/,
     &' total                         ',e15.5,/)
      return
      end
      function intget(a,b,c,d)
      implicit integer (a-z)
      REAL intget
INCLUDE(common/t_parm)
INCLUDE(common/t_int)
      idx(i,j)=max(i,j)*(max(i,j)-1)/2+min(i,j)
      ix1=idx(a,b)
      ix2=idx(c,d)
      ix3=rint+idx(ix1,ix2)-1
      intget=scr(ix3)
      return
      end
      subroutine mkf11(t2,buf,ioff,itriv,isqov,npr,flov,ifc,
     1                 fpbkf,t1o,isqvv)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifc(nirred),
     1  ioff(nbf),itriv(ntriv),isqov(nsqov),fpbkf(nbkf),isqvv(nsqvv)
      REAL t2(ndimw),buf(lnbkt),t1o(ndimt1)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  form [f11](av,bei) and store as t2(i,a,v,be)
c
      call srew(itap65)
      ibkf = 0
      nbei = 0
c
      do 10 bisym = 1,nirred
      lnbei = npr(bisym,3,2)
      lnab = npr(bisym,2,2)
c
      if(lnbei.ne.0.and.lnab.ne.0) then
c
      do 20 besym = 1,nirred
      isym = IXOR32(bisym-1,besym-1) + 1
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fi = flov(isym,1)
      li = flov(isym,2)
c
      do 30 be = fbe,lbe
      beofo = (be-1)*no
      do 40 i = fi,li
      beiq = (be-1)*no + i
      nbei = nbei + 1
c
      if(nbei.eq.fpbkf(ibkf+1)) then
      off1 = 0
      ibkf = ibkf + 1
      call tit_sread(itap65,buf,intowp(lnbkt))
      end if
c
      do 50 asym = 1,nirred
      bsym = IXOR32(bisym-1,asym-1) + 1
      bvsym = IXOR32(besym-1,bsym-1) + 1
      off2 = ifc(bvsym)
      off3 = npr(bvsym,3,2)
      fb = flov(bsym,3) - no
      lb = flov(bsym,4) - no
      fa = flov(asym,3) - no
      la = flov(asym,4) - no
      fv = flov(bsym,1)
      lv = flov(bsym,2)
c
      do 60 a = fa,la
      iaq = isqov((a-1)*no+i) + off2
      aofv = (a-1)*nv
      do 70 v = fv,lv
      iavbe = iaq + (isqov(beofo+v)-1)*off3
      do 80 b = fb,lb
      add1 = off1 + isqvv(aofv+b)
      t2(iavbe) = t2(iavbe) + buf(add1)*t1o(isqov((b-1)*no+v))
   80 continue
   70 continue
   60 continue
   50 continue
      off1 = off1 + lnab
   40 continue
   30 continue
   20 continue
      end if
   10 continue
c
      return
      end
      subroutine mkf12(t2,buf,ioff,itriv,isqov,npr,flov,ifc,
     1                 fpbkf,t1o,isqvv)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifc(nirred),
     1  ioff(nbf),itriv(ntriv),isqov(nsqov),fpbkf(nbkf),isqvv(nsqvv)
      REAL t2(ndimw),buf(lnbkt),t1o(ndimt1)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  form [f12](av,bei) and store as t2(i,a,v,be)
c
      call srew(itap65)
      ibkf = 0
      nbei = 0
c
      do 10 bisym = 1,nirred
      lnbei = npr(bisym,3,2)
      lnab = npr(bisym,2,2)
c
      if(lnbei.ne.0.and.lnab.ne.0) then
c
      do 20 besym = 1,nirred
      isym = IXOR32(bisym-1,besym-1) + 1
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fi = flov(isym,1)
      li = flov(isym,2)
c
      do 30 be = fbe,lbe
      beofo = (be-1)*no
      do 40 i = fi,li
      beiq = (be-1)*no + i
      nbei = nbei + 1
c
      if(nbei.eq.fpbkf(ibkf+1)) then
      off1 = 0
      ibkf = ibkf + 1
      call tit_sread(itap65,buf,intowp(lnbkt))
      end if
c
      do 50 bsym = 1,nirred
      bvsym = IXOR32(besym-1,bsym-1) + 1
      off2 = ifc(bvsym)
      off3 = npr(bvsym,3,2)
      asym = IXOR32(bisym-1,bsym-1) + 1
      fb = flov(bsym,3) - no
      lb = flov(bsym,4) - no
      fa = flov(asym,3) - no
      la = flov(asym,4) - no
      fv = flov(bsym,1)
      lv = flov(bsym,2)
c
      do 60 v = fv,lv
      bevof = (isqov(beofo+v)-1)*off3 + off2
      do 70 a = fa,la
      iabev = isqov((a-1)*no+i) + bevof
      do 80 b = fb,lb
      add1 = off1 + isqvv((b-1)*nv+a)
      t2(iabev) = t2(iabev) + buf(add1)*t1o(isqov((b-1)*no+v))
   80 continue
   70 continue
   60 continue
   50 continue
      off1 = off1 + lnab
   40 continue
   30 continue
   20 continue
      end if
   10 continue
c
      return
      end
      subroutine mkgabe(t2,buf,isqov,npr,flov,ifd4,
     1                 fpbkf,t1o,t1n,isqvv,w1,isqoo)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd4(nirred),
     1  isqov(nsqov),fpbkf(nbkf),isqvv(nsqvv),isqoo(nsqoo)
      REAL t2(ndimw),buf(lnbkt),t1o(ndimt1),t1n(ndimt1),w1(nsqvv)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  add f integral contribution to w1(a,be) and to t1
c  [f1*] --> w1(a,be) and [f2a] --> t1
c
      call srew(itap65)
      ibkf = 0
      nbei = 0
c
      do 10 bisym = 1,nirred
      lnbei = npr(bisym,3,2)
      lnab = npr(bisym,2,2)
c
      if(lnbei.ne.0.and.lnab.ne.0) then
c
      do 20 besym = 1,nirred
      isym = IXOR32(bisym-1,besym-1) + 1
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fi = flov(isym,1)
      li = flov(isym,2)
      fu = flov(besym,1)
      lu = flov(besym,2)
c
      do 30 be = fbe,lbe
      beofq = (be-1)*nv
      beofo = (be-1)*no
      do 40 i = fi,li
      iofo = (i-1)*no
      nbei = nbei + 1
c
      if(nbei.eq.fpbkf(ibkf+1)) then
      off1 = 0
      off3 = 0
      ibkf = ibkf + 1
      call tit_sread(itap65,buf,intowp(lnbkt))
      end if
c
      fb = flov(isym,3) - no
      lb = flov(isym,4) - no
      fa = flov(besym,3) - no
      la = flov(besym,4) - no
c
      do 60 a = fa,la
      abe = isqvv(beofq+a)
      do 70 b = fb,lb
      ib = isqov((b-1)*no+i)
      beiab = off3 + isqvv((a-1)*nv+b)
      beiba = off3 + isqvv((b-1)*nv+a)
      w1(abe) = w1(abe) + (buf(beiab) + buf(beiab) - buf(beiba))*t1o(ib)
   70 continue
   60 continue
c
c  f integral contribution to t1
c
      do 80 u = fu,lu
      ube = isqov(beofo + u)
      off2 = (isqoo((u-1)*no+i)-1)*lnab + ifd4(bisym)
      do 90 iab = 1,lnab
      add1 = off3 + iab
      add2 = off2 + iab
      t1n(ube) = t1n(ube) - buf(add1)*t2(add2)
   90 continue
   80 continue
      off3 = off3 + lnab
c
   40 continue
   30 continue
   20 continue
      end if
   10 continue
c
      return
      end
      subroutine mkgiu(t2,g,npr,isqoo,flov,ifa)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifa(nirred),
     1  isqoo(nsqoo)
      REAL t2(ndimw),g(nsqoo)
c
INCLUDE(common/t_parm)
c
c  sum d2p(j,i,j,u)*2 + d2p(i,j,j,u) into g(iu)
c
      off2 = npr(1,1,2)
      do 10 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 20 u = fu,lu
      do 30 j = fu,lu
      ujq = (u-1)*no + j
      ujqof = (isqoo(ujq)-1)*off2
      do 50 i = fu,lu
      ij = (i-1)*no + j
      ji = (j-1)*no + i
      jiju = ujqof + isqoo(ij)
      ijju = ujqof + isqoo(ji)
      iu = (u-1)*no + i
      iuoff = isqoo(iu)
      g(iuoff) = g(iuoff) + t2(jiju) + t2(jiju) - t2(ijju)
  50  continue
  30  continue
  20  continue
  10  continue
c
      do 11 ujsym = 2,nirred
      off2 = npr(ujsym,1,2)
      do 21 usym = 1,nirred
      jsym = IXOR32(ujsym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fj = flov(jsym,1)
      lj = flov(jsym,2)
      do 31 u = fu,lu
      do 41 j = fj,lj
      ujq = (u-1)*no + j
      ujqof = (isqoo(ujq)-1)*off2 + ifa(ujsym)
      do 61 i = fu,lu
      ij = (i-1)*no + j
      ji = (j-1)*no + i
      jiju = ujqof + isqoo(ij)
      ijju = ujqof + isqoo(ji)
      iu = (u-1)*no + i
      iuoff = isqoo(iu)
      g(iuoff) = g(iuoff) + t2(jiju) + t2(jiju) - t2(ijju)
61    continue
41    continue
31    continue
21    continue
11    continue
      return
      end
      subroutine mktau(t2,tau,ioff,itriv,isqoo,npr,flov,ifd2,t1o,isqov)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),isqov(nsqov),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo)
      REAL t2(ndimw),tau(ndimw),t1o(ndimt1)
      REAL fac,a0,a1,t11
c
INCLUDE(common/t_parm)
c
      data a0,a1 /0.0d0,1.0d0/
c
c  form tau(v,u,ga<be) from t2 and t1
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      do 40 usym = 1,nirred
      fac = a0
      if(usym.eq.besym) fac = a1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 50 u = fu,lu
      ube = (be-1)*no + u
      t11 = t1o(isqov(ube))*fac
      do 60 v = fu,lu
      vga = (ga-1)*no + v
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      tau(uvbg) = t2(uvbg) + t1o(isqov(vga))*t11
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      do 70 usym = 1,nirred
      fac = a0
      if(usym.eq.besym) fac = a1
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 80 u = fu,lu
      ube = (be-1)*no + u
      t11 = t1o(isqov(ube))*fac
      do 90 v = fu,lu
      vbe = (be-1)*no + v
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      tau(uvbb) = t2(uvbb) + t1o(isqov(vbe))*t11
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      do 41 ga = fga,lga
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      do 51 usym = 1,nirred
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fac = a0
      if(usym.eq.besym) fac = a1
      if(vsym.ne.gasym) fac = a0
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      ube = isqov((be-1)*no+u)
      t11 = t1o(ube)*fac
      do 71 v = fv,lv
      vga = isqov((ga-1)*no+v)
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      tau(uvbg) = t2(uvbg) + t1o(vga)*t11
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine mxmtp1(bfin,eints,fints,t2,flov,npr,iovvv,isqoo,isqov,
     &                  isqvv,ifd4,ife1,i,j,k,isym,jsym,ksym,mxv3,
     &                  ndime)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),iovvv(nirred,nirred),
     &        isqoo(nsqoo),isqov(nsqov),isqvv(nsqvv),
     &        ifd4(nirred),ife1(nirred)
      REAL bfin(mxv3),eints(ndime),fints(mxv3),t2(ndimw)
c
INCLUDE(common/t_parm)
INCLUDE(common/t_adata)
c
      character *1 xn
      data xn / 'n' / 
c
      jksym=IXOR32(jsym-1,ksym-1)+1
      iksym=IXOR32(isym-1,ksym-1)+1
      ijksym=IXOR32(isym-1,jksym-1)+1
      do 110 fsym=1,nirred
      nvf=flov(fsym,4)-flov(fsym,3)+1
      nof=flov(fsym,2)-flov(fsym,1)+1
      ifsym=IXOR32(isym-1,fsym-1)+1
      csym=IXOR32(jksym-1,fsym-1)+1
      lnab=npr(ifsym,2,2)
      lncf=npr(jksym,2,2)
      nvc=flov(csym,4)-flov(csym,3)+1
      ad1=iovvv(isym,fsym)+1
      ad2=ifd4(jksym)+(isqoo((k-1)*no+j)-1)*lncf+
     &    isqvv((flov(csym,3)-no-1)*nv+flov(fsym,3)-no)
      ad3=iovvv(ijksym,csym)+1
      if (lnab*nvc*nvf.ne.0)then
_IF1()c      call mxmb(fints(ad1),1,lnab,t2(ad2),1,nvf,bfin(ad3),1,lnab,
_IF1()c     &          lnab,nvf,nvc)
      call dgemm(xn,xn,lnab,nvc,nvf
     +          ,a1,fints(ad1),lnab,t2(ad2)
     +          ,nvf,a1,bfin(ad3),lnab)
      endif
      jfsym=IXOR32(jsym-1,fsym-1)+1
      csym=IXOR32(iksym-1,fsym-1)+1
      lnab=npr(jfsym,2,2)
      lncf=npr(iksym,3,2)
      nvc=flov(csym,4)-flov(csym,3)+1
      ad1=ifd4(jfsym)+(isqoo((j-1)*no+flov(fsym,1))-1)*lnab+1
      ad2=ife1(iksym)+(isqoo((k-1)*no+i)-1)*lncf+
     &    isqov((flov(csym,3)-no-1)*no+flov(fsym,1))
      ad3=iovvv(ijksym,csym)+1
      if (lnab*nvc*nof.ne.0)then
_IF1()c      call mxmb(t2(ad1),1,lnab,eints(ad2),1,nof,bfin(ad3),1,lnab,
_IF1()c     &          lnab,nof,nvc)
      call dgemm(xn,xn,lnab,nvc,nof
     +         ,a1,t2(ad1),lnab,eints(ad2)
     +         ,nof,a1,bfin(ad3),lnab)
      endif
  110 continue
      return
      end
      subroutine mxmtp2(bfin,eints,fints,t2,ccc,aaa,gam,flov,npr,
     &                  iovvv,isqoo,isqov,isqvo,isqvv,ifd4,ife1,
     &                  i,j,k,isym,jsym,ksym,mxv3,ndime)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),iovvv(nirred,nirred),
     &        isqoo(nsqoo),isqov(nsqov),isqvo(nsqov),isqvv(nsqvv),
     &        ifd4(nirred),ife1(nirred)
      REAL bfin(mxv3),eints(ndime),fints(mxv3),t2(ndimw),ccc(ndime),
     &       aaa(mxv3),gam(ndimw)
c
INCLUDE(common/t_parm)
INCLUDE(common/t_adata)
c
      character *1 xn, xt
      data xn,xt / 'n','t' / 
      jksym=IXOR32(jsym-1,ksym-1)+1
      iksym=IXOR32(isym-1,ksym-1)+1
      ijksym=IXOR32(isym-1,jksym-1)+1
      do 410 fsym=1,nirred
      nvf=flov(fsym,4)-flov(fsym,3)+1
      nof=flov(fsym,2)-flov(fsym,1)+1
      ifsym=IXOR32(isym-1,fsym-1)+1
      csym=IXOR32(jksym-1,fsym-1)+1
      lnab=npr(ifsym,2,2)
      lncf=npr(jksym,2,2)
      nvc=flov(csym,4)-flov(csym,3)+1
      ad1=iovvv(isym,fsym)+1
      ad2=ifd4(jksym)+(isqoo((k-1)*no+j)-1)*lncf+
     &    isqvv((flov(csym,3)-no-1)*nv+flov(fsym,3)-no)
      ad3=iovvv(ijksym,csym)+1
      if (lnab*nvc*nvf.ne.0)then
      call dgemm(xt,xn,nvf,nvc,lnab
     +          ,a1,fints(ad1),lnab,bfin(ad3)
     +          ,lnab,a1,gam(ad2),nvf)
      call dgemm(xn,xt,lnab,nvf,nvc
     +          ,a1,bfin(ad3),lnab,t2(ad2)
     +          ,nvf,a1,aaa(ad1),lnab)
      endif
      jfsym=IXOR32(jsym-1,fsym-1)+1
      csym=IXOR32(iksym-1,fsym-1)+1
      lnab=npr(jfsym,2,2)
      lncf=npr(iksym,3,2)
      nvc=flov(csym,4)-flov(csym,3)+1
      ad3=iovvv(ijksym,csym)+1
      ad2=ife1(iksym)+(isqoo((k-1)*no+i)-1)*lncf+
     &    isqov((flov(csym,3)-no-1)*no+flov(fsym,1))
      ad1=ifd4(jfsym)+(isqoo((j-1)*no+flov(fsym,1))-1)*lnab+1
      if (lnab*nvc*nof.ne.0)then
      call dgemm(xn,xt,lnab,nof,nvc
     +          ,a1,bfin(ad3),lnab,eints(ad2)
     +          ,nof,a1,gam(ad1),lnab)
      ad2=ife1(iksym)+(isqoo((k-1)*no+i)-1)*lncf+
     &    isqvo((flov(fsym,1)-1)*nv+flov(csym,3)-no)
      call dgemm(xt,xn,nvc,nof,lnab
     +          ,a1,bfin(ad3),lnab,t2(ad1)
     +          ,lnab,a1,ccc(ad2),nvc)
      endif
  410 continue
      return
      end
      subroutine nrdd(dints,buf,flov,npr,itrio,isqvv,ifd3,fsec,ndimd)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),itrio(ntrio),
     &        isqvv(nsqvv),ifd3(nirred),fsec(nlist)
      REAL dints(ndimd),buf(lnbkt)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      call rsetsa(itap63,fsec(6))
      off1=lnbkt
      off2=0
      do 110 ijsym = 1,nirred
      lnvv = npr(ijsym,2,2)
      if(lnvv.eq.0)goto 110
      do 120 isym = 1,nirred
      jsym = IXOR32(ijsym-1,isym-1) + 1
      if (isym.lt.jsym)goto 120
      do 130 i = flov(isym,1),flov(isym,2)
      limj=flov(jsym,2)
      if (isym.eq.jsym)limj=i
      do 140 j = flov(jsym,1),limj
      off2=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*npr(ijsym,2,2)
      if(off1+lnvv.gt.lnbkt)then
        off1 = 0
        call tit_sread(itap63,buf,intowp(lnbkt))
      end if
      do 150 asym=1,nirred
      bsym=IXOR32(ijsym-1,asym-1)+1
      do 160 a=flov(asym,3)-no,flov(asym,4)-no
      do 170 b=flov(bsym,3)-no,flov(bsym,4)-no
      off1=off1+1
      dints(off2+isqvv((b-1)*nv+a))=buf(off1)
  170 continue
  160 continue
  150 continue
  140 continue
  130 continue
  120 continue
  110 continue
c
      return
      end
      subroutine nrde(eints,buf,flov,npr,isqoo,isqov,ife1,
     &                fpbke1,ndime)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqoo(nsqoo),
     &        isqov(nsqov),ife1(nirred),fpbke1(nbke1)
      REAL eints(ndime),buf(lnbkt)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      call srew(itap64)
      ibke = 0
      nbei = 0
c
      do 110 bisym = 1,nirred
      lnov = npr(bisym,3,2)
      lnoo = npr(bisym,1,2)
c
      if(lnov.eq.0.or.lnoo.eq.0)goto 110
c
      do 120 besym = 1,nirred
      isym = IXOR32(bisym-1,besym-1) + 1
c
      do 130 be = flov(besym,3)-no,flov(besym,4)-no
      do 140 i = flov(isym,1),flov(isym,2)
      nbei = nbei + 1
c
      if(nbei.eq.fpbke1(ibke+1)) then
      off1 = 0
      ibke = ibke + 1
      call tit_sread(itap64,buf,intowp(lnbkt))
      end if
c
      do 150 jsym=1,nirred
      ksym=IXOR32(bisym-1,jsym-1)+1
      bksym=IXOR32(besym-1,ksym-1)+1
      do 160 j=flov(jsym,1),flov(jsym,2)
      do 170 k=flov(ksym,1),flov(ksym,2)
      off1=off1+1
      ad1=ife1(bksym)+(isqoo((i-1)*no+j)-1)*npr(bksym,3,2)+
     &                 isqov((be-1)*no+k)
      eints(ad1)=-buf(off1)
  170 continue
  160 continue
  150 continue
  140 continue
  130 continue
  120 continue
  110 continue
c
      return
      end
      subroutine nsettr(t1,t2,tmp2,flov,npr,isqoo,isqvv,iovvvt,
     &                  iovvv,novvvt,ifd4,ndimd,ndime,ndimf,mxv3,iopt)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqoo(nsqoo),
     &        isqvv(nsqvv),iovvvt(nirred),iovvv(nirred,nirred),
     &        novvvt(nirred),ifd4(nirred)
      REAL t1(ndimt1),t2(ndimw),tmp2(ndimw)
      REAL a2
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      data a2 /2.0d00/
c
c read in t1 and transpose
      call srew(itap69)
      call tit_sread(itap69,tmp2,intowp(ndimt1))
c - qcit
      if (iopt.eq.6)call rscal(ndimt1,a2,tmp2,1)
      ad1=1
      do 50 isym=1,nirred
      noi=flov(isym,2)-flov(isym,1)+1
      nvi=flov(isym,4)-flov(isym,3)+1
      call trmat(tmp2(ad1),noi,nvi,t1(ad1))
      ad1=ad1+noi*nvi
   50 continue
c
c  read in t2 and expand list
      call tit_sread(itap69,tmp2,intowp(ndimt2))
      icnt=0
      do 10 absym=1,nirred
      lnvv=npr(absym,2,2)
      do 12 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      if (asym.lt.bsym)goto 12
      do 14 a=flov(asym,3)-no,flov(asym,4)-no
      limb=flov(bsym,4)-no
      if (asym.eq.bsym)limb=a
      do 16 b=flov(bsym,3)-no,limb
      do 18 isym=1,nirred
      jsym=IXOR32(absym-1,isym-1)+1
      do 20 i=flov(isym,1),flov(isym,2)
      do 22 j=flov(jsym,1),flov(jsym,2)
      icnt=icnt+1
      ad1=ifd4(absym)+(isqoo((i-1)*no+j)-1)*lnvv+isqvv((a-1)*nv+b)
      ad2=ifd4(absym)+(isqoo((j-1)*no+i)-1)*lnvv+isqvv((b-1)*nv+a)
      t2(ad1)=tmp2(icnt)
      t2(ad2)=tmp2(icnt)
   22 continue
   20 continue
   18 continue
   16 continue
   14 continue
   12 continue
   10 continue
c
c  set up arrays needed for addressing
c
      off1=0
      mxv3=0
      ndimd=0
      ndime=0
      do 30 isym=1,nirred
      noi=flov(isym,2)-flov(isym,1)+1
      off2=0
      do 32 bsym=1,nirred
      bisym=IXOR32(bsym-1,isym-1)+1
      nvb=flov(bsym,4)-flov(bsym,3)+1
      lnvv=npr(bisym,2,2)
      iovvv(isym,bsym)=off2
      off2=off2+lnvv*nvb
   32 continue
      iovvvt(isym)=off1
      novvvt(isym)=off2
      off1=off1+noi*off2
      mxv3=max(mxv3,off2)
      ndimd=ndimd+npr(isym,1,1)*npr(isym,2,2)
      ndime=ndime+npr(isym,3,2)*npr(isym,1,2)
   30 continue
      ndimf=off1
c
      write(6,100)ndimd,ndime,ndimf,mxv3
  100 format(' total length of d integrals ',i8,/,
     &       ' total length of e integrals ',i8,/,
     &       ' total length of f integrals ',i8,/,
     &       ' max length of nv**3 block   ',i8)
c
      return
      end
      subroutine ocrdf(buf,istrt,ibin,ipos,flov,npr,
     &                 novvvt,fpbkf,mxv3,wrk,lwrk)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),novvvt(nirred),
     &        fpbkf(nbkf),istrt(no),ibin(no,3),ipos(nv,no)
      REAL wrk(lwrk),buf(lnbkt)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      lbin=(lwrk+no-1)/no
      lbin=min(mxv3,lbin)
      lsec=sec2i(1)/intowp(1)
c
c      lbin=max(nsqvv,lsec)
c
      lbin=(lbin/lsec)*lsec
      nsec=intowp(lbin)/sec2i(1)
      if (nsec*sec2i(1).ne.intowp(lbin))then
        write(*,*)' you have a problem: in ocrdf'
        call caserr('error detected in ocrdf')
      endif
      if (lbin.lt.nsqvv)then
        write(6,1000)lwrk,no,lbin,nsqvv
 1000   format(' increase blank common in ocrdf -',
     &         ' lwrk,no,lbin,nsqvv ',/,4i8)
        call caserr('increase allocated memory')
      endif
      write(6,1002)lwrk,lsec,lbin,nsqvv
 1002 format(/,' out of core sort of f integrals',/,
     &       ' length of work area ',i8,/,
     &       ' length of sector    ',i8,/,
     &       ' length of a bin     ',i8,/,
     &       ' length of nsqvv     ',i8,/)
c
      call srew(itap99)
      call rgetsa(itap99,addr)
      do 10 isym=1,nirred
      do 12 i=flov(isym,1),flov(isym,2)
      ibin(i,1)=0
      ibin(i,2)=0
      ibin(i,3)=addr
      istrt(i)=addr
      len=novvvt(isym)
      nbin=(len+lbin-1)/lbin
      addr=addr+nbin*nsec
c      do 14 icnt=1,nbin
c      call swrit(itap99,wrk,intowp(lbin))
c   14 continue
   12 continue
   10 continue
c
      call srew(itap65)
      ibkf = 0
      nbei = 0
c
      do 110 bisym = 1,nirred
      lnov = npr(bisym,3,2)
      lnvv = npr(bisym,2,2)
c
      if(lnov.ne.0.and.lnvv.ne.0) then
c
      do 120 besym = 1,nirred
      isym = IXOR32(bisym-1,besym-1) + 1
      nbe = flov(besym,4) - flov(besym,3) + 1
      nbi = flov(isym,2)  - flov(isym,1)  + 1
c
      do 130 be=flov(besym,3)-no,flov(besym,4)-no
      bebe=be-flov(besym,3)+no+1
      do 140 i=flov(isym,1),flov(isym,2)
      iof=(i-1)*lbin
      nbei = nbei + 1
      ipos(be,i)=ibin(i,2)
      ibin(i,2)=ibin(i,2)+lnvv
c
      if(nbei.eq.fpbkf(ibkf+1)) then
      off1 = 0
      ibkf = ibkf + 1
      call tit_sread(itap65,buf,intowp(lnbkt))
      end if
c
      totvv=lnvv
c
  152 continue
      limab=lbin-ibin(i,1)
      limab=min(totvv,limab)
      if (limab.eq.0)then
        call rsetsa(itap99,ibin(i,3))
        call swrit(itap99,wrk(iof+1),intowp(lbin))
        call rgetsa(itap99,ibin(i,3))
        ibin(i,1)=0
        limab=lbin
        limab=min(totvv,limab)
      endif
      off2=iof+ibin(i,1)
      do 150 ab=1,limab
      wrk(off2+ab)=buf(off1+ab)
  150 continue
      ibin(i,1)=ibin(i,1)+limab
      off1 = off1 + limab
      totvv=totvv-limab
      if (totvv.ne.0)goto 152
c
  140 continue
  130 continue
  120 continue
      end if
  110 continue
c
      do 200 i=1,no
      iof=(i-1)*lbin+1
      if (ibin(i,1).ne.0)then
        call rsetsa(itap99,ibin(i,3))
        call swrit(itap99,wrk(iof),intowp(lbin))
      endif
  200 continue
c
      call srew(itap99)
      do 310 isym=1,nirred
      len=novvvt(isym)
      do 312 i=flov(isym,1),flov(isym,2)
      call rsetsa(itap99,istrt(i))
      call tit_sread(itap99,wrk,intowp(len))
      off1=mxv3
      do 314 besym=1,nirred
      beisym=IXOR32(besym-1,isym-1)+1
      lnvv=npr(beisym,2,2)
      do 316 be=flov(besym,3)-no,flov(besym,4)-no
      off2=ipos(be,i)
      do 318 ab=1,lnvv
      wrk(off1+ab)=wrk(off2+ab)
  318 continue
      off1=off1+lnvv
  316 continue
  314 continue
      call rsetsa(itap99,istrt(i))
      call swrit(itap99,wrk(mxv3+1),intowp(len))
  312 continue
  310 continue
c
      return
      end
      subroutine octp40(eta,zeta,epo,epv,gam,ccc,flov,npr,ntr,
     &                  novvvt,iovvv,isqvv,buf1,buf2,lbuf,istrt,
     &                  jstrt,ibin,ipos,wrk,lwrk,ndimd,ndime,ndimf)
      implicit integer(a-z)
      parameter(lnax=20)
      integer flov(nirred,4),npr(nirred,3,2),ntr(nirred,4),
     &        novvvt(nirred),iovvv(nirred,nirred),isqvv(nsqvv),
     &        istrt(no),jstrt(nv),ibin(nv,3),ipos(nv,no)
      REAL eta(ndimt1),zeta(ndimd),epo(no),epv(nv),gam(ndimw),
     &       ccc(ndime),buf1(lbuf),buf2(lbuf),wrk(lwrk)
      integer ax(lnax),iwka1(8)
      REAL tst1,tst2
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
      REAL fac
INCLUDE(common/t_adata)
c
      do 31 asym = 1,nirred
      iwka1(asym) = 0
      do 32 isym = 1,nirred
      bfsym = IXOR32(asym-1,isym-1) + 1
      ni = flov(isym,2) - flov(isym,1) + 1
      iwka1(asym) = iwka1(asym) + ni*npr(bfsym,2,1)
   32 continue
   31 continue
c
      itap40=40
      call rfile(itap40)
      call srew(itap40)
      call swrit(itap40,ax,lnax)
c
c -- eta
c
      ax(1)=ndimt1
      call rgetsa(itap40,ax(2))
      call swrit(itap40,eta,intowp(ndimt1))
      tst1=a0
      call dotpr(eta,eta,ndimt1,tst1)
      write(iw,1000)'eta  ',tst1
 1000 format(' dot product of ',a5,e20.12)
c
c -- gamma
c
      ax(3)=ndimw
      call rgetsa(itap40,ax(4))
      call swrit(itap40,gam,intowp(ndimw))
      tst1=a0
      call dotpr(gam,gam,ndimw,tst1)
      write(iw,1000)'gam  ',tst1
c
c -- epsilon occ
c
      ax(5)=no
      call rgetsa(itap40,ax(6))
      call swrit(itap40,epo,intowp(no))
      tst1=a0
      call dotpr(epo,epo,no,tst1)
      write(iw,1000)'epo  ',tst1
c
c -- epsilon vir
c
      ax(7)=nv
      call rgetsa(itap40,ax(8))
      call swrit(itap40,epv,intowp(nv))
      tst1=a0
      call dotpr(epv,epv,nv,tst1)
      write(iw,1000)'epv  ',tst1
c
c -- zeta 
c
      ax(9)=ndimd
      call rgetsa(itap40,ax(10))
      call swrit(itap40,zeta,intowp(ndimd))
      tst1=a0
      call dotpr(zeta,zeta,ndimd,tst1)
      write(iw,1000)'zet  ',tst1
c
c -- ccc
c
      ax(11)=ndime
      call rgetsa(itap40,ax(12))
      call swrit(itap40,ccc,intowp(ndime))
      tst1=a0
      call dotpr(ccc,ccc,ndime,tst1)
      write(iw,1000)'ccc  ',tst1
c
c -- aaa
c
      ax(13)=ndimf
      call rgetsa(itap40,ax(14))
      fac=a1/a3
      tst1=a0
      mxovv=0
      do 1 asym=1,nirred
        mxovv=max(mxovv,ntr(asym,1))
    1 continue
c
c  allocate core for sort
c
      lbin = (lwrk+nv-1)/nv
      lbin = min(mxovv,lbin)
      lsec = sec2i(1)/intowp(1)
_IF1()cdbg      lbin=max(nsqvv,lsec)
      lbin = max((lbin/lsec)*lsec,lsec)
      nsec = intowp(lbin)/sec2i(1)
c
      if(nsec*sec2i(1).ne.intowp(lbin)) then
        write(iw,*) ' you have a problem: in ocrdf'
        call caserr('error detected in ocrdf')
      endif
c
      if(lbin.lt.nsqvv) then
        write(iw,1002) lwrk,no,lbin,nsqvv
 1002   format('  increase blank common in octp40 -',
     &         '  lwrk,no,lbin,nsqvv ',/,4i8)
        call caserr('increase memory in octp40')
      endif
c
c  perform sort
c
      write(iw,1004)lwrk,lsec,lbin,nsqvv
 1004 format(/,' out of core sort of aaa',/,
     &       ' length of work area ',i8,/,
     &       ' length of sector    ',i8,/,
     &       ' length of a bin     ',i8,/,
     &       ' length of nsqvv     ',i8,/)
c
      call srew(itap99)
      call rgetsa(itap99,addr)
      do 10 asym = 1,nirred
      do 12 a = flov(asym,3)-no,flov(asym,4)-no
      ibin(a,1) = 0
      ibin(a,2) = 0
      ibin(a,3) = addr
      jstrt(a) = addr
ctjl      len=ntr(asym,1)
      len = iwka1(asym)
      nbin = (len+lbin-1)/lbin
      addr = addr + nbin*nsec
   12 continue
   10 continue
c
      call srew(itap98)
      do 110 isym = 1,nirred
      do 112 i = flov(isym,1),flov(isym,2)
      call rsetsa(itap98,istrt(i))
      call tit_sread(itap98,buf1,intowp(novvvt(isym)))
      adb = 0
      do 114 asym = 1,nirred
      aisym = IXOR32(asym-1,isym-1)+1
      do 116 a = flov(asym,3)-no,flov(asym,4)-no
      do 118 bsym = 1,nirred
      fsym = IXOR32(aisym-1,bsym-1)+1
      if(fsym.gt.bsym) go to 119
      fisym = IXOR32(fsym-1,isym-1)+1
      bisym = IXOR32(bsym-1,isym-1)+1
      do 120 b = flov(bsym,3)-no,flov(bsym,4)-no
      bb = b-flov(bsym,3)+no+1
      lf = flov(fsym,4) - no
      if(fsym.eq.bsym) lf = b
ctjl      do 122 f=flov(fsym,3)-no,flov(fsym,4)-no
      do 122 f = flov(fsym,3)-no,lf
      ff = f - flov(fsym,3) + no + 1
      ad1=iovvv(isym,fsym)+(ff-1)*npr(fisym,2,2)+isqvv((b-1)*nv+a)
      ad2=iovvv(isym,bsym)+(bb-1)*npr(bisym,2,2)+isqvv((f-1)*nv+a)
      adb = adb + 1
      buf2(adb) = fac*(buf1(ad1)+buf1(ad2))
  122 continue
  120 continue
  119 continue
  118 continue
  116 continue
  114 continue
c
      adb = 0
      do 124 asym = 1,nirred
      aisym = IXOR32(asym-1,isym-1)+1
ctjl      lnvv=npr(aisym,2,2)
      lnvv = npr(aisym,2,1)
      do 126 a = flov(asym,3)-no,flov(asym,4)-no
      aof = (a-1)*lbin
      ipos(a,i) = ibin(a,2)
      ibin(a,2) = ibin(a,2) + lnvv
      totvv = lnvv
c
  152 continue
      limab = lbin - ibin(a,1)
      limab = min(totvv,limab)
      if (limab.eq.0)then
        call rsetsa(itap99,ibin(a,3))
        call swrit(itap99,wrk(aof+1),intowp(lbin))
        call rgetsa(itap99,ibin(a,3))
        ibin(a,1) = 0
        limab = lbin
        limab = min(totvv,limab)
      endif
      off2 = aof + ibin(a,1)
      do 150 ab = 1,limab
      wrk(off2+ab) = buf2(adb+ab)
_IF1()cdbg      tst1 = tst1 + wrk(off2+ab)*wrk(off2+ab)
  150 continue
      ibin(a,1) = ibin(a,1) + limab
      adb = adb + limab
      totvv = totvv - limab
      if (totvv.ne.0)goto 152
c
  126 continue
  124 continue
  112 continue
  110 continue
_IF1()cdbg      write(*,*) '  after 110: tst1 = ',tst1
_IF1()cdbg      tst1 = a0
c
      do 200 a=1,nv
      aof=(a-1)*lbin+1
      if (ibin(a,1).ne.0)then
        call rsetsa(itap99,ibin(a,3))
        call swrit(itap99,wrk(aof),intowp(lbin))
      endif
  200 continue
c
      adb=0
      call srew(itap99)
      do 310 asym=1,nirred
ctjl      len=ntr(asym,1)
      len = iwka1(asym)
      do 312 a=flov(asym,3)-no,flov(asym,4)-no
      call rsetsa(itap99,jstrt(a))
      call tit_sread(itap99,wrk,intowp(len))
      do 314 isym=1,nirred
      aisym=IXOR32(asym-1,isym-1)+1
ctjl      lnvv=npr(aisym,2,2)
      lnvv = npr(aisym,2,1)
      do 316 i=flov(isym,1),flov(isym,2)
      if (adb+lnvv.gt.lnbkt)then
        tst2=a0
        call dotpr(buf1,buf1,adb,tst2)
        tst1=tst1+tst2
        call swrit(itap40,buf1,intowp(lnbkt))
        adb=0
      endif
      off2=ipos(a,i)
      do 318 ab=1,lnvv
      buf1(adb+ab)=wrk(off2+ab)
  318 continue
      adb=adb+lnvv
  316 continue
  314 continue
  312 continue
  310 continue
      tst2=a0
      call dotpr(buf1,buf1,adb,tst2)
      tst1=tst1+tst2
      call swrit(itap40,buf1,intowp(lnbkt))
      write(iw,1000)'aaa  ',tst1
c
      call srew(itap40)
      call swrit(itap40,ax,lnax)
      call rclose(itap40,3)
      return
      end
      subroutine octrp1(t1,t2,dints,eints,fints,buf1,buf2,ee,flov,
     &                  npr,isqov,isqvo,isqoo,isqvv,iovvvt,iovvv,
     &                  novvvt,orbsym,ifd4,ife1,eccsd,iopt,ndimd,
     &                  ndime,ndimf,mxv3,idx1,idx2,jdx1,jdx2,istrt,
     &                  itrio,ifd3,debug)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqov(nsqov),
     &        isqvo(nsqov),isqoo(nsqoo),isqvv(nsqvv),iovvvt(nirred),
     &        iovvv(nirred,nirred),novvvt(nirred),orbsym(nbf),
     &        ifd4(nirred),ife1(nirred),idx1(nsqvv),idx2(nsqvv),
     &        jdx1(nirred),jdx2(nirred,nirred),istrt(no),
     &        itrio(ntrio),ifd3(nirred)
      REAL t1(ndimt1),t2(ndimt2),dints(ndimd),eints(ndime),
     &       fints(mxv3,3),buf1(mxv3),buf2(mxv3),ee(nbf)
      REAL a0,a1,a2,a3,a4,a5,a6,a9,ap5
      REAL d1,d2,d3,d4,d5,fac
      REAL emp4t,eccsd
      REAL x1,x2,y1,y2,e1,e11
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
      REAL tst1,tst2,tst3,tst4,tst5,tst6
      REAL intget,t2get,wget,vget
      REAL tx(20)
c
      character *1 xn
      data xn / 'n' / 
      data a0,a1,a2,a3,a4,a5 /0.0d0,1.0d0,2.0d0,3.0d0,4.0d0,5.0d0/
      data a6,a9,ap5 /6.0d0,9.0d0,0.5d00/
c
c
      call vclr(tx,1,20)
      if (debug.gt.0)then
      print *,' testing dints'
      icnt=0
      do 1060 ijsym=1,nirred
      do 1060 isym=1,nirred
      jsym=IXOR32(ijsym-1,isym-1)+1
      do 1060 i=flov(isym,1),flov(isym,2)
      do 1060 j=flov(jsym,1),flov(jsym,2)
      do 1060 asym=1,nirred
      bsym=IXOR32(ijsym-1,asym-1)+1
      do 1060 a=flov(asym,3),flov(asym,4)
      do 1060 b=flov(bsym,3),flov(bsym,4)
      icnt=icnt+1
      tst1=intget(i,a,j,b)
      if (abs(dints(icnt)-tst1).gt.1.0d-10)then
      write(6,1062)isym,jsym,asym,bsym,i,j,a,b,dints(icnt),tst1,
     &             dints(icnt)-tst1
      endif
 1062 format(8i3,3e15.5)
 1060 continue
      print *,' end testing dints'
c
      print *,' testing eints'
      icnt=0
      do 1040 ijsym=1,nirred
      do 1040 isym=1,nirred
      jsym=IXOR32(ijsym-1,isym-1)+1
      do 1040 i=flov(isym,1),flov(isym,2)
      do 1040 j=flov(jsym,1),flov(jsym,2)
      do 1040 asym=1,nirred
      msym=IXOR32(ijsym-1,asym-1)+1
      do 1040 a=flov(asym,3),flov(asym,4)
      do 1040 m=flov(msym,1),flov(msym,2)
      icnt=icnt+1
      tst1=-intget(i,a,j,m)
      if (abs(eints(icnt)-tst1).gt.1.0d-10)then
      write(6,1042)isym,jsym,asym,msym,i,j,a,m,eints(icnt),
     &             tst1,eints(icnt)-tst1
      endif
 1042 format(8i3,3e15.5)
 1040 continue
      print *,' end testing eints'
c
      print *,' testing fints'
      icnt=0
      do 1000 isym=1,nirred
      do 1000 i=flov(isym,1),flov(isym,2)
      call rsetsa(itap99,istrt(i))
      call tit_sread(itap99,fints(1,1),intowp(novvvt(isym)))
      do 1000 fsym=1,nirred
      basym=IXOR32(isym-1,fsym-1)+1
      do 1000 f=flov(fsym,3),flov(fsym,4)
      do 1000 bsym=1,nirred
      asym=IXOR32(basym-1,bsym-1)+1
      do 1000 b=flov(bsym,3),flov(bsym,4)
      do 1000 a=flov(asym,3),flov(asym,4)
      icnt=icnt+1
      tst1=intget(f,b,i,a)
      if (abs(fints(icnt,1)-tst1).gt.1.0d-10)then
      write(6,1002)isym,fsym,bsym,asym,i,f,b,a,fints(icnt,1),
     &             tst1,fints(icnt,1)-tst1
      endif
 1002 format(8i3,3e15.5)
 1000 continue
      print *,' end testing fints'
c
      print *,' testing t2'
      icnt=0
      do 1020 ijsym=1,nirred
      do 1020 isym=1,nirred
      jsym=IXOR32(ijsym-1,isym-1)+1
      do 1020 i=flov(isym,1),flov(isym,2)
      do 1020 j=flov(jsym,1),flov(jsym,2)
      do 1020 asym=1,nirred
      bsym=IXOR32(ijsym-1,asym-1)+1
      do 1020 a=flov(asym,3),flov(asym,4)
      do 1020 b=flov(bsym,3),flov(bsym,4)
      icnt=icnt+1
      tst1=t2get(i,a,j,b)
      if (abs(t2(icnt)-tst1).gt.1.0d-10)then
      write(6,1022)isym,jsym,asym,bsym,i,j,a,b,t2(icnt),tst1,
     &             t2(icnt)-tst1
      endif
 1022 format(8i3,3e15.5)
 1020 continue
      print *,' end testing t2'
      endif
c
c  we have f integrals, e integrals and t2 in memory; form emp4(t)
c  form w(a,b,c) for a given i,j,k
c
      icnt=0
      do 400 absym=1,nirred
      jdx1(absym)=icnt
      do 402 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 404 a=flov(asym,3)-no,flov(asym,4)-no
      do 406 b=flov(bsym,3)-no,flov(bsym,4)-no
      icnt=icnt+1
      idx1(icnt)=isqvv((b-1)*nv+a)
  406 continue
  404 continue
  402 continue
  400 continue
      
      emp4t = a0
      do 100 ijksym=1,nirred
c
      icnt=0
      do 410 asym=1,nirred
      bcsym=IXOR32(ijksym-1,asym-1)+1
      do 412 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      acsym=IXOR32(asym-1,csym-1)+1
      nvb=flov(bsym,4)-flov(bsym,3)+1
      nvc=flov(csym,4)-flov(csym,3)+1
      jdx2(asym,bsym)=icnt
      do 414 b=1,nvb
      off1=(b-1)*npr(acsym,2,2)-1
      off2=icnt+(b-1)*nvc
      do 416 c=1,nvc
      idx2(off2+c)=off1+c
  416 continue
  414 continue
      icnt=icnt+nvc*nvb
  412 continue
  410 continue
c
      do 101 i = 1,no
      isym = orbsym(i) + 1
      ii=i-flov(isym,1)+1
      d1 = ee(i)
      call rsetsa(itap99,istrt(i))
      call tit_sread(itap99,fints(1,1),intowp(novvvt(isym)))
      do 102 j = 1,i
      jsym = orbsym(j) + 1
      ijsym=IXOR32(isym-1,jsym-1)+1
      ksym=IXOR32(ijksym-1,ijsym-1)+1
      if (ksym.gt.jsym)goto 102
      iksym=IXOR32(isym-1,ksym-1)+1
      jksym=IXOR32(jsym-1,ksym-1)+1
      jj=j-flov(jsym,1)+1
      d2 = d1 + ee(j)
      if (j.eq.i)then
      call rcopy(novvvt(jsym),fints(1,1),1,fints(1,2),1)
      else
      call rsetsa(itap99,istrt(j))
      call tit_sread(itap99,fints(1,2),intowp(novvvt(jsym)))
      endif
      limj=min(flov(ksym,2),j)
      do 104 k = flov(ksym,1),limj
      if(k.eq.i) go to 104
      ksym = orbsym(k) + 1
      kk=k-flov(ksym,1)+1
      d3 = d2 + ee(k)
      if (k.eq.i)then
      call rcopy(novvvt(ksym),fints(1,1),1,fints(1,3),1)
      else if (k.eq.j)then
      call rcopy(novvvt(ksym),fints(1,2),1,fints(1,3),1)
      else
      call rsetsa(itap99,istrt(k))
      call tit_sread(itap99,fints(1,3),intowp(novvvt(ksym)))
      endif
c
      len=novvvt(ijksym)
      call vclr(buf1,1,len)
c
c (ia:bf)*t2(kc:jf)
      call wtst
      call mxmtp1(buf1,eints,fints(1,1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,j,k,isym,jsym,ksym,mxv3,ndime)
      call wtgt(tx(1))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(7))
      call wtst
c
c (ia:cf)*t2(jb:kf)
      call mxmtp1(buf2,eints,fints(1,1),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,k,j,isym,ksym,jsym,mxv3,ndime)
      call wtgt(tx(2))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(8))
      call wtst
c
c (kc:af)*t2(jb:if)
      call mxmtp1(buf1,eints,fints(1,3),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,i,j,ksym,isym,jsym,mxv3,ndime)
      call wtgt(tx(3))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(9))
      call wtst
c
c (kc:bf)*t2(ia:jf)
      ad1=iovvvt(ksym)+(kk-1)*novvvt(ksym)+1
      call mxmtp1(buf2,eints,fints(1,3),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,j,i,ksym,jsym,isym,mxv3,ndime)
      call wtgt(tx(4))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(10))
      call wtst
c
c (jb:cf)*t2(ia:kf)
      ad1=iovvvt(jsym)+(jj-1)*novvvt(jsym)+1
      call mxmtp1(buf1,eints,fints(1,2),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,k,i,jsym,ksym,isym,mxv3,ndime)
      call wtgt(tx(5))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
c (jb:af)*t2(kc:if)
      ad1=iovvvt(jsym)+(jj-1)*novvvt(jsym)+1
      call mxmtp1(buf2,eints,fints(1,2),t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,i,k,jsym,isym,ksym,mxv3,ndime)
      call wtgt(tx(6))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
      do 228 abc=1,len
      buf2(abc)=buf1(abc)
  228 continue
c (ia:jb)*t1(kc)
      lnab=npr(ijsym,2,2)
      lnc=flov(ksym,4)-flov(ksym,3)+1
      ad1=ifd4(ijsym)+(isqoo((j-1)*no+i)-1)*lnab+1
      ad1=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*lnab+1
      ad2=isqvo((k-1)*nv+flov(ksym,3)-no)
      ad3=iovvv(ijksym,ksym)+1
_IF1()c      call mxmb(dints(ad1),1,lnab,t1(ad2),1,1,buf2(ad3),1,lnab,
_IF1()c     &          lnab,1,lnc)
      if (lnab*lnc.ne.0)then
      call dgemm(xn,xn,lnab,lnc,1
     +          ,a1,dints(ad1),lnab,t1(ad2)
     +          ,1,a1,buf2(ad3),lnab)
      endif
c
c (ia:kc)*t1(jb)
      lnb=flov(jsym,4)-flov(jsym,3)+1
      do 270 csym=1,nirred
      asym=IXOR32(iksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnac=npr(iksym,2,2)
      lna=flov(asym,4)-flov(asym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(jsym,3)-no-1)*nv+flov(asym,3)-no)
      do 272 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd4(iksym)+(isqoo((k-1)*no+i)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad1=ifd3(iksym)+(itrio(i*(i-1)/2+k)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad2=isqvo((j-1)*nv+flov(jsym,3)-no)
_IF1(c)c      call mxmb(dints(ad1),1,lna,t1(ad2),1,1,buf2(ad3),1,lna,
_IF1(c)c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,dints(ad1),lna,t1(ad2)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  272 continue
  270 continue
c
c (jb:kc)*t1(ia)
      lna=flov(isym,4)-flov(isym,3)+1
      do 280 csym=1,nirred
      bsym=IXOR32(jksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnbc=npr(jksym,2,2)
      lnb=flov(bsym,4)-flov(bsym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(bsym,3)-no-1)*nv+flov(isym,3)-no)
      do 282 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd4(jksym)+(isqoo((k-1)*no+j)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad1=ifd3(jksym)+(itrio(j*(j-1)/2+k)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad2=isqvo((i-1)*nv+flov(isym,3)-no)
_IF1()c      call mxmb(t1(ad2),1,lna,dints(ad1),1,1,buf2(ad3),1,lna,
_IF1()c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,t1(ad2),lna,dints(ad1)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  282 continue
  280 continue
      call wtgt(tx(13))
      call wtst
c
      if (debug.gt.0)then
      write(6,9111)isym,jsym,ksym,i,j,k
 9111 format(' testing w and v: i,j,k ',/,6i5)
      off1=0
      do 9112 asym=1,nirred
      bcsym=IXOR32(asym-1,ijksym-1)+1
      do 9114 a=flov(asym,3),flov(asym,4)
      do 9116 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      do 9118 b=flov(bsym,3),flov(bsym,4)
      do 9120 c=flov(csym,3),flov(csym,4)
      off1=off1+1
      tst1=wget(i,j,k,c,b,a)
      tst2=buf1(off1)
      tst3=tst1-tst2
      tst4=vget(i,j,k,c,b,a)
      tst5=buf2(off1)
      tst6=tst4-tst5
      if (abs(tst3).gt.1.0d-10.or.abs(tst6).gt.1.0d-10)then
      write(6,9122)i,j,k,a,b,c,tst1,tst2,tst3,tst4,tst5,tst6
      endif
 9122 format(6i5,3e15.5,/,30x,3e15.5)
 9120 continue
 9118 continue
 9116 continue
 9114 continue
 9112 continue
      endif
c
c -- (a b c) ordering
      do 320 b=1,flov(ijksym,4)-flov(ijksym,3)+1
      off1=iovvv(ijksym,ijksym)+(b-1)*npr(1,2,2)
      do 322 a=1,nv
      off2=off1+isqvv(a*(nv+1)-nv)
      buf2(off2)=buf2(off2)*ap5
  322 continue
  320 continue
c
      do 330 asym=1,nirred
      absym=IXOR32(asym-1,ijksym-1)+1
      do 332 a=flov(asym,3)-no,flov(asym,4)-no
      off1=iovvv(ijksym,asym)+(a-flov(asym,3)+no)*npr(absym,2,2)
      aof=(a-1)*nv
      do 334 b=flov(ijksym,3)-no,flov(ijksym,4)-no
      ixyzy=off1+isqvv((b-1)*nv+a)
      ixzyy=off1+isqvv(aof+b)
      buf2(ixyzy)=buf2(ixyzy)*ap5
      buf2(ixzyy)=buf2(ixzyy)*ap5
  334 continue
  332 continue
  330 continue
c
      e1=a0
      e11=a0
      do 250 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 252 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no+1
      d4=d3-ee(c+no)
      do 254 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 254
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 256 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no+1
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b-1,lima)
      do 258 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no+1
      ixabc=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixacb=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixbca=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixcba=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
c  a>b>c
      x1=buf2(ixabc)+buf2(ixbca)+buf2(ixcab)
      x2=buf2(ixacb)+buf2(ixbac)+buf2(ixcba)
      y1=buf1(ixabc)+buf1(ixbca)+buf1(ixcab)
      y2=buf1(ixacb)+buf1(ixbac)+buf1(ixcba)
      fac=d5-ee(a+no)
      e1=e1+((x1-x2)*(y1-y2)-x1*y2-x2*y1)/fac
      e11=e11+(buf1(ixabc)*buf2(ixabc)+buf1(ixacb)*buf2(ixacb)+
     &         buf1(ixbac)*buf2(ixbac)+buf1(ixbca)*buf2(ixbca)+
     &         buf1(ixcab)*buf2(ixcab)+buf1(ixcba)*buf2(ixcba))/fac
  258 continue
  256 continue
  254 continue
  252 continue
  250 continue
      call wtgt(tx(14))
      call wtst
c
      if (i.eq.j.or.j.eq.k)then
      emp4t=emp4t+a3*(e1+a3*e11)
      else
      emp4t=emp4t+a6*(e1+a3*e11)
      endif
c
  104 continue
  102 continue
  101 continue
  100 continue
c
      emp4t = emp4t/a3
      write(*,1) emp4t
      if(iopt.eq.6) then
      write(*,5) eccsd+emp4t
      else
      write(*,4) eccsd+emp4t
      end if
      eccsd=eccsd+emp4t
   1  format(/  ,2x,'triples : mp4+mp5 =  ',f24.15)
   4  format(    2x,'ccsd(t)   energy  =  ',f24.15,//)
   5  format(    2x,'qcisd(t)  energy  =  ',f24.15,//)
c
      do 9823 i=2,6
      tx(1)=tx(1)+tx(i)
      tx(7)=tx(7)+tx(6+i)
 9823 continue
      write(6,9824)tx(1),tx(7),tx(13),tx(14),
     &             tx(1)+tx(7)+tx(13)+tx(14)
 9824 format(8x,' **** timing  information ****',8x,/,
     &' mp(4) e and f integral mxm    ',e15.5,/,
     &'                        sorts  ',e15.5,/,
     &' mp(5) d integral contribution ',e15.5,/,
     &' final energy summation        ',e15.5,/,
     &' total                         ',e15.5,/)
      return
      end
      subroutine octrp2(t1,t2,dints,eints,fints,buf1,buf2,ee,flov,
     &                  npr,isqov,isqvo,isqoo,isqvv,iovvvt,iovvv,
     &                  novvvt,orbsym,ifd4,ife1,eccsd,iopt,ndimd,
     &                  ndime,ndimf,mxv3,idx1,idx2,jdx1,jdx2,istrt,
     &                  itrio,ifd3,debug)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqov(nsqov),
     &        isqvo(nsqov),isqoo(nsqoo),isqvv(nsqvv),iovvvt(nirred),
     &        iovvv(nirred,nirred),novvvt(nirred),orbsym(nbf),
     &        ifd4(nirred),ife1(nirred),idx1(nsqvv),idx2(nsqvv),
     &        jdx1(nirred),jdx2(nirred,nirred),istrt(no),
     &        itrio(ntrio),ifd3(nirred)
      REAL t1(ndimt1),t2(ndimt2),dints(ndimd),eints(ndime),
     &       fints(mxv3),buf1(mxv3),buf2(mxv3),ee(nbf)
      REAL a0,a1,a2,a3,a4,a5,a6,a9,ap5
      REAL d1,d2,d3,d4,d5,fac
      REAL emp4t,eccsd
      REAL x1,x2,y1,y2,e1,e11
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
      REAL tst1,tst2,tst3,tst4,tst5,tst6
      REAL wget,vget
      REAL tx(20)
c
      character *1 xn
      data xn / 'n' / 
      data a0,a1,a2,a3,a4,a5 /0.0d0,1.0d0,2.0d0,3.0d0,4.0d0,5.0d0/
      data a6,a9,ap5 /6.0d0,9.0d0,0.5d00/
c
c
      call vclr(tx,1,20)
c
c  we have f integrals, e integrals and t2 in memory; form emp4(t)
c  form w(a,b,c) for a given i,j,k
c
      icnt=0
      do 400 absym=1,nirred
      jdx1(absym)=icnt
      do 402 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 404 a=flov(asym,3)-no,flov(asym,4)-no
      do 406 b=flov(bsym,3)-no,flov(bsym,4)-no
      icnt=icnt+1
      idx1(icnt)=isqvv((b-1)*nv+a)
  406 continue
  404 continue
  402 continue
  400 continue
      
      emp4t = a0
      do 100 ijksym=1,nirred
c
      icnt=0
      do 410 asym=1,nirred
      bcsym=IXOR32(ijksym-1,asym-1)+1
      do 412 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      acsym=IXOR32(asym-1,csym-1)+1
      nvb=flov(bsym,4)-flov(bsym,3)+1
      nvc=flov(csym,4)-flov(csym,3)+1
      jdx2(asym,bsym)=icnt
      do 414 b=1,nvb
      off1=(b-1)*npr(acsym,2,2)-1
      off2=icnt+(b-1)*nvc
      do 416 c=1,nvc
      idx2(off2+c)=off1+c
  416 continue
  414 continue
      icnt=icnt+nvc*nvb
  412 continue
  410 continue
c
      do 101 i = 1,no
      isym = orbsym(i) + 1
      ii=i-flov(isym,1)+1
      d1 = ee(i)
      do 102 j = 1,i
      jsym = orbsym(j) + 1
      ijsym=IXOR32(isym-1,jsym-1)+1
      ksym=IXOR32(ijksym-1,ijsym-1)+1
      if (ksym.gt.jsym)goto 102
      iksym=IXOR32(isym-1,ksym-1)+1
      jksym=IXOR32(jsym-1,ksym-1)+1
      jj=j-flov(jsym,1)+1
      d2 = d1 + ee(j)
      limj=min(flov(ksym,2),j)
      do 104 k = flov(ksym,1),limj
      if(k.eq.i) go to 104
      ksym = orbsym(k) + 1
      kk=k-flov(ksym,1)+1
      d3 = d2 + ee(k)
c
      len=novvvt(ijksym)
      call vclr(buf1,1,len)
c
c (ia:bf)*t2(kc:jf)
      call wtst
      call rsetsa(itap99,istrt(i))
      call tit_sread(itap99,fints,intowp(novvvt(isym)))
      call mxmtp1(buf1,eints,fints,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,j,k,isym,jsym,ksym,mxv3,ndime)
      call wtgt(tx(1))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(7))
      call wtst
c
c (ia:cf)*t2(jb:kf)
      call mxmtp1(buf2,eints,fints,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,k,j,isym,ksym,jsym,mxv3,ndime)
      call wtgt(tx(2))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(8))
      call wtst
c
c (kc:af)*t2(jb:if)
      call rsetsa(itap99,istrt(k))
      call tit_sread(itap99,fints,intowp(novvvt(ksym)))
      call mxmtp1(buf1,eints,fints,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,i,j,ksym,isym,jsym,mxv3,ndime)
      call wtgt(tx(3))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(9))
      call wtst
c
c (kc:bf)*t2(ia:jf)
      call mxmtp1(buf2,eints,fints,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,j,i,ksym,jsym,isym,mxv3,ndime)
      call wtgt(tx(4))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(10))
      call wtst
c
c (jb:cf)*t2(ia:kf)
      call rsetsa(itap99,istrt(j))
      call tit_sread(itap99,fints,intowp(novvvt(jsym)))
      call mxmtp1(buf1,eints,fints,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,k,i,jsym,ksym,isym,mxv3,ndime)
      call wtgt(tx(5))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
c (jb:af)*t2(kc:if)
      call mxmtp1(buf2,eints,fints,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,i,k,jsym,isym,ksym,mxv3,ndime)
      call wtgt(tx(6))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
      do 228 abc=1,len
      buf2(abc)=buf1(abc)
  228 continue
c (ia:jb)*t1(kc)
      lnab=npr(ijsym,2,2)
      lnc=flov(ksym,4)-flov(ksym,3)+1
      ad1=ifd4(ijsym)+(isqoo((j-1)*no+i)-1)*lnab+1
      ad1=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*lnab+1
      ad2=isqvo((k-1)*nv+flov(ksym,3)-no)
      ad3=iovvv(ijksym,ksym)+1
_IF1()c      call mxmb(dints(ad1),1,lnab,t1(ad2),1,1,buf2(ad3),1,lnab,
_IF1()c     &          lnab,1,lnc)
      if (lnab*lnc.ne.0)then
      call dgemm(xn,xn,lnab,lnc,1
     +          ,a1,dints(ad1),lnab,t1(ad2)
     +          ,1,a1,buf2(ad3),lnab)
      endif
c
c (ia:kc)*t1(jb)
      lnb=flov(jsym,4)-flov(jsym,3)+1
      do 270 csym=1,nirred
      asym=IXOR32(iksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnac=npr(iksym,2,2)
      lna=flov(asym,4)-flov(asym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(jsym,3)-no-1)*nv+flov(asym,3)-no)
      do 272 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd4(iksym)+(isqoo((k-1)*no+i)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad1=ifd3(iksym)+(itrio(i*(i-1)/2+k)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad2=isqvo((j-1)*nv+flov(jsym,3)-no)
_IF1()c      call mxmb(dints(ad1),1,lna,t1(ad2),1,1,buf2(ad3),1,lna,
_IF1()c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,dints(ad1),lna,t1(ad2)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  272 continue
  270 continue
c
c (jb:kc)*t1(ia)
      lna=flov(isym,4)-flov(isym,3)+1
      do 280 csym=1,nirred
      bsym=IXOR32(jksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnbc=npr(jksym,2,2)
      lnb=flov(bsym,4)-flov(bsym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(bsym,3)-no-1)*nv+flov(isym,3)-no)
      do 282 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd4(jksym)+(isqoo((k-1)*no+j)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad1=ifd3(jksym)+(itrio(j*(j-1)/2+k)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad2=isqvo((i-1)*nv+flov(isym,3)-no)
_IF1()c      call mxmb(t1(ad2),1,lna,dints(ad1),1,1,buf2(ad3),1,lna,
_IF1()c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,t1(ad2),lna,dints(ad1)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  282 continue
  280 continue
      call wtgt(tx(13))
      call wtst
c
      if (debug.gt.0)then
      write(6,9111)isym,jsym,ksym,i,j,k
 9111 format(' testing w and v: i,j,k ',/,6i5)
      off1=0
      do 9112 asym=1,nirred
      bcsym=IXOR32(asym-1,ijksym-1)+1
      do 9114 a=flov(asym,3),flov(asym,4)
      do 9116 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      do 9118 b=flov(bsym,3),flov(bsym,4)
      do 9120 c=flov(csym,3),flov(csym,4)
      off1=off1+1
      tst1=wget(i,j,k,c,b,a)
      tst2=buf1(off1)
      tst3=tst1-tst2
      tst4=vget(i,j,k,c,b,a)
      tst5=buf2(off1)
      tst6=tst4-tst5
      if (abs(tst3).gt.1.0d-10.or.abs(tst6).gt.1.0d-10)then
      write(6,9122)i,j,k,a,b,c,tst1,tst2,tst3,tst4,tst5,tst6
      endif
 9122 format(6i5,3e15.5,/,30x,3e15.5)
 9120 continue
 9118 continue
 9116 continue
 9114 continue
 9112 continue
      endif
c
c -- (a b c) ordering
      do 320 b=1,flov(ijksym,4)-flov(ijksym,3)+1
      off1=iovvv(ijksym,ijksym)+(b-1)*npr(1,2,2)
      do 322 a=1,nv
      off2=off1+isqvv(a*(nv+1)-nv)
      buf2(off2)=buf2(off2)*ap5
  322 continue
  320 continue
c
      do 330 asym=1,nirred
      absym=IXOR32(asym-1,ijksym-1)+1
      do 332 a=flov(asym,3)-no,flov(asym,4)-no
      off1=iovvv(ijksym,asym)+(a-flov(asym,3)+no)*npr(absym,2,2)
      aof=(a-1)*nv
      do 334 b=flov(ijksym,3)-no,flov(ijksym,4)-no
      ixyzy=off1+isqvv((b-1)*nv+a)
      ixzyy=off1+isqvv(aof+b)
      buf2(ixyzy)=buf2(ixyzy)*ap5
      buf2(ixzyy)=buf2(ixzyy)*ap5
  334 continue
  332 continue
  330 continue
c
      e1=a0
      e11=a0
      do 250 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 252 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no+1
      d4=d3-ee(c+no)
      do 254 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 254
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 256 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no+1
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b-1,lima)
      do 258 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no+1
      ixabc=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixacb=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixbca=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixcba=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
c  a>b>c
      x1=buf2(ixabc)+buf2(ixbca)+buf2(ixcab)
      x2=buf2(ixacb)+buf2(ixbac)+buf2(ixcba)
      y1=buf1(ixabc)+buf1(ixbca)+buf1(ixcab)
      y2=buf1(ixacb)+buf1(ixbac)+buf1(ixcba)
      fac=d5-ee(a+no)
      e1=e1+((x1-x2)*(y1-y2)-x1*y2-x2*y1)/fac
      e11=e11+(buf1(ixabc)*buf2(ixabc)+buf1(ixacb)*buf2(ixacb)+
     &         buf1(ixbac)*buf2(ixbac)+buf1(ixbca)*buf2(ixbca)+
     &         buf1(ixcab)*buf2(ixcab)+buf1(ixcba)*buf2(ixcba))/fac
  258 continue
  256 continue
  254 continue
  252 continue
  250 continue
      call wtgt(tx(14))
      call wtst
c
      if (i.eq.j.or.j.eq.k)then
      emp4t=emp4t+a3*(e1+a3*e11)
      else
      emp4t=emp4t+a6*(e1+a3*e11)
      endif
c
  104 continue
  102 continue
  101 continue
  100 continue
c
      emp4t = emp4t/a3
      write(*,1) emp4t
      if(iopt.eq.6) then
      write(*,5) eccsd+emp4t
      else
      write(*,4) eccsd+emp4t
      end if
      eccsd=eccsd+emp4t
   1  format(/  ,2x,'triples : mp4+mp5 =  ',f24.15)
   4  format(    2x,'ccsd(t)   energy  =  ',f24.15,//)
   5  format(    2x,'qcisd(t)  energy  =  ',f24.15,//)
c
      do 9823 i=2,6
      tx(1)=tx(1)+tx(i)
      tx(7)=tx(7)+tx(6+i)
 9823 continue
      write(6,9824)tx(1),tx(7),tx(13),tx(14),
     &             tx(1)+tx(7)+tx(13)+tx(14)
 9824 format(8x,' **** timing  information ****',8x,/,
     &' mp(4) e and f integral mxm    ',e15.5,/,
     &'                        sorts  ',e15.5,/,
     &' mp(5) d integral contribution ',e15.5,/,
     &' final energy summation        ',e15.5,/,
     &' total                         ',e15.5,/)
      return
      end
      subroutine octrp3(t1,t2,dints,eints,buf1,buf2,ee,flov,
     &                  npr,isqov,isqvo,isqoo,isqvv,iovvvt,iovvv,
     &                  novvvt,orbsym,ifd4,ife1,eccsd,iopt,ndimd,
     &                  ndime,ndimf,mxv3,idx1,idx2,jdx1,jdx2,istrt,
     &                  itrio,ifd3,debug)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqov(nsqov),
     &        isqvo(nsqov),isqoo(nsqoo),isqvv(nsqvv),iovvvt(nirred),
     &        iovvv(nirred,nirred),novvvt(nirred),orbsym(nbf),
     &        ifd4(nirred),ife1(nirred),idx1(nsqvv),idx2(nsqvv),
     &        jdx1(nirred),jdx2(nirred,nirred),istrt(no),
     &        itrio(ntrio),ifd3(nirred)
      REAL t1(ndimt1),t2(ndimt2),dints(ndimd),eints(ndime),
     &       buf1(mxv3),buf2(mxv3),ee(nbf)
      REAL a0,a1,a2,a3,a4,a5,a6,a9,ap5
      REAL d1,d2,d3,d4,d5,fac
      REAL emp4t,eccsd
      REAL x1,x2,y1,y2,e1,e11
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
      REAL tst1,tst2,tst3,tst4,tst5,tst6
      REAL wget,vget
      REAL tx(20)
c
      character *1 xn
      data xn / 'n' / 
      data a0,a1,a2,a3,a4,a5 /0.0d0,1.0d0,2.0d0,3.0d0,4.0d0,5.0d0/
      data a6,a9,ap5 /6.0d0,9.0d0,0.5d00/
c
      call vclr(tx,1,20)
c
c  we have f integrals, e integrals and t2 in memory; form emp4(t)
c  form w(a,b,c) for a given i,j,k
c
      icnt=0
      do 400 absym=1,nirred
      jdx1(absym)=icnt
      do 402 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 404 a=flov(asym,3)-no,flov(asym,4)-no
      do 406 b=flov(bsym,3)-no,flov(bsym,4)-no
      icnt=icnt+1
      idx1(icnt)=isqvv((b-1)*nv+a)
  406 continue
  404 continue
  402 continue
  400 continue
      
      emp4t = a0
      do 100 ijksym=1,nirred
c
      icnt=0
      do 410 asym=1,nirred
      bcsym=IXOR32(ijksym-1,asym-1)+1
      do 412 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      acsym=IXOR32(asym-1,csym-1)+1
      nvb=flov(bsym,4)-flov(bsym,3)+1
      nvc=flov(csym,4)-flov(csym,3)+1
      jdx2(asym,bsym)=icnt
      do 414 b=1,nvb
      off1=(b-1)*npr(acsym,2,2)-1
      off2=icnt+(b-1)*nvc
      do 416 c=1,nvc
      idx2(off2+c)=off1+c
  416 continue
  414 continue
      icnt=icnt+nvc*nvb
  412 continue
  410 continue
c
      do 101 i = 1,no
      isym = orbsym(i) + 1
      ii=i-flov(isym,1)+1
      d1 = ee(i)
      do 102 j = 1,i
      jsym = orbsym(j) + 1
      ijsym=IXOR32(isym-1,jsym-1)+1
      ksym=IXOR32(ijksym-1,ijsym-1)+1
      if (ksym.gt.jsym)goto 102
      iksym=IXOR32(isym-1,ksym-1)+1
      jksym=IXOR32(jsym-1,ksym-1)+1
      jj=j-flov(jsym,1)+1
      d2 = d1 + ee(j)
      limj=min(flov(ksym,2),j)
      do 104 k = flov(ksym,1),limj
      if(k.eq.i) go to 104
      ksym = orbsym(k) + 1
      kk=k-flov(ksym,1)+1
      d3 = d2 + ee(k)
c
      len=novvvt(ijksym)
      call vclr(buf1,1,len)
c
c (ia:bf)*t2(kc:jf)
      call wtst
      call rsetsa(itap99,istrt(i))
      call tit_sread(itap99,buf2,intowp(novvvt(isym)))
      call mxmtp1(buf1,eints,buf2,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,j,k,isym,jsym,ksym,mxv3,ndime)
      call wtgt(tx(1))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(7))
      call wtst
c
c (ia:cf)*t2(jb:kf)
      call rsetsa(itap99,istrt(i))
      call tit_sread(itap99,buf1,intowp(novvvt(isym)))
      call mxmtp1(buf2,eints,buf1,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,i,k,j,isym,ksym,jsym,mxv3,ndime)
      call wtgt(tx(2))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(8))
      call wtst
c
c (kc:af)*t2(jb:if)
      call rsetsa(itap99,istrt(k))
      call tit_sread(itap99,buf2,intowp(novvvt(ksym)))
      call mxmtp1(buf1,eints,buf2,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,i,j,ksym,isym,jsym,mxv3,ndime)
      call wtgt(tx(3))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(9))
      call wtst
c
c (kc:bf)*t2(ia:jf)
      call rsetsa(itap99,istrt(k))
      call tit_sread(itap99,buf1,intowp(novvvt(ksym)))
      call mxmtp1(buf2,eints,buf1,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,k,j,i,ksym,jsym,isym,mxv3,ndime)
      call wtgt(tx(4))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(10))
      call wtst
c
c (jb:cf)*t2(ia:kf)
      call rsetsa(itap99,istrt(j))
      call tit_sread(itap99,buf2,intowp(novvvt(jsym)))
      call mxmtp1(buf1,eints,buf2,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,k,i,jsym,ksym,isym,mxv3,ndime)
      call wtgt(tx(5))
      call wtst
      call srttp1(buf1,buf2,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
c (jb:af)*t2(kc:if)
      call rsetsa(itap99,istrt(j))
      call tit_sread(itap99,buf1,intowp(novvvt(jsym)))
      call mxmtp1(buf2,eints,buf1,t2,flov,npr,iovvv,isqoo,isqov,
     &            isqvv,ifd4,ife1,j,i,k,jsym,isym,ksym,mxv3,ndime)
      call wtgt(tx(6))
      call wtst
      call srttp2(buf2,buf1,flov,iovvv,npr,isqvv,idx1,idx2,
     &            jdx1,jdx2,ijksym,mxv3)
      call wtgt(tx(11))
      call wtst
c
      do 228 abc=1,len
      buf2(abc)=buf1(abc)
  228 continue
c (ia:jb)*t1(kc)
      lnab=npr(ijsym,2,2)
      lnc=flov(ksym,4)-flov(ksym,3)+1
      ad1=ifd4(ijsym)+(isqoo((j-1)*no+i)-1)*lnab+1
      ad1=ifd3(ijsym)+(itrio(i*(i-1)/2+j)-1)*lnab+1
      ad2=isqvo((k-1)*nv+flov(ksym,3)-no)
      ad3=iovvv(ijksym,ksym)+1
c      call mxmb(dints(ad1),1,lnab,t1(ad2),1,1,buf2(ad3),1,lnab,
c     &          lnab,1,lnc)
      if (lnab*lnc.ne.0)then
      call dgemm(xn,xn,lnab,lnc,1
     +          ,a1,dints(ad1),lnab,t1(ad2)
     +          ,1,a1,buf2(ad3),lnab)
      endif
c
c (ia:kc)*t1(jb)
      lnb=flov(jsym,4)-flov(jsym,3)+1
      do 270 csym=1,nirred
      asym=IXOR32(iksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnac=npr(iksym,2,2)
      lna=flov(asym,4)-flov(asym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(jsym,3)-no-1)*nv+flov(asym,3)-no)
      do 272 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd4(iksym)+(isqoo((k-1)*no+i)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad1=ifd3(iksym)+(itrio(i*(i-1)/2+k)-1)*lnac+
     &                 isqvv((c-1)*nv+flov(asym,3)-no)
      ad2=isqvo((j-1)*nv+flov(jsym,3)-no)
_IF1()c      call mxmb(dints(ad1),1,lna,t1(ad2),1,1,buf2(ad3),1,lna,
_IF1()c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,dints(ad1),lna,t1(ad2)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  272 continue
  270 continue
c
c (jb:kc)*t1(ia)
      lna=flov(isym,4)-flov(isym,3)+1
      do 280 csym=1,nirred
      bsym=IXOR32(jksym-1,csym-1)+1
      absym=IXOR32(ijksym-1,csym-1)+1
      lnab=npr(absym,2,2)
      lnbc=npr(jksym,2,2)
      lnb=flov(bsym,4)-flov(bsym,3)+1
      ad3=iovvv(ijksym,csym)+
     &    isqvv((flov(bsym,3)-no-1)*nv+flov(isym,3)-no)
      do 282 c=flov(csym,3)-no,flov(csym,4)-no
      ad1=ifd4(jksym)+(isqoo((k-1)*no+j)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad1=ifd3(jksym)+(itrio(j*(j-1)/2+k)-1)*lnbc+
     &                 isqvv((c-1)*nv+flov(bsym,3)-no)
      ad2=isqvo((i-1)*nv+flov(isym,3)-no)
_IF1()c      call mxmb(t1(ad2),1,lna,dints(ad1),1,1,buf2(ad3),1,lna,
_IF1()c     &          lna,1,lnb)
      if (lna*lnb.ne.0)then
      call dgemm(xn,xn,lna,lnb,1
     +          ,a1,t1(ad2),lna,dints(ad1)
     +          ,1,a1,buf2(ad3),lna)
      endif
      ad3=ad3+lnab
  282 continue
  280 continue
      call wtgt(tx(13))
      call wtst
c
      if (debug.gt.0)then
      write(6,9111)isym,jsym,ksym,i,j,k
 9111 format(' testing w and v: i,j,k ',/,6i5)
      off1=0
      do 9112 asym=1,nirred
      bcsym=IXOR32(asym-1,ijksym-1)+1
      do 9114 a=flov(asym,3),flov(asym,4)
      do 9116 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      do 9118 b=flov(bsym,3),flov(bsym,4)
      do 9120 c=flov(csym,3),flov(csym,4)
      off1=off1+1
      tst1=wget(i,j,k,c,b,a)
      tst2=buf1(off1)
      tst3=tst1-tst2
      tst4=vget(i,j,k,c,b,a)
      tst5=buf2(off1)
      tst6=tst4-tst5
      if (abs(tst3).gt.1.0d-10.or.abs(tst6).gt.1.0d-10)then
      write(6,9122)i,j,k,a,b,c,tst1,tst2,tst3,tst4,tst5,tst6
      endif
 9122 format(6i5,3e15.5,/,30x,3e15.5)
 9120 continue
 9118 continue
 9116 continue
 9114 continue
 9112 continue
      endif
c
c -- (a b c) ordering
      do 320 b=1,flov(ijksym,4)-flov(ijksym,3)+1
      off1=iovvv(ijksym,ijksym)+(b-1)*npr(1,2,2)
      do 322 a=1,nv
      off2=off1+isqvv(a*(nv+1)-nv)
      buf2(off2)=buf2(off2)*ap5
  322 continue
  320 continue
c
      do 330 asym=1,nirred
      absym=IXOR32(asym-1,ijksym-1)+1
      do 332 a=flov(asym,3)-no,flov(asym,4)-no
      off1=iovvv(ijksym,asym)+(a-flov(asym,3)+no)*npr(absym,2,2)
      aof=(a-1)*nv
      do 334 b=flov(ijksym,3)-no,flov(ijksym,4)-no
      ixyzy=off1+isqvv((b-1)*nv+a)
      ixzyy=off1+isqvv(aof+b)
      buf2(ixyzy)=buf2(ixyzy)*ap5
      buf2(ixzyy)=buf2(ixzyy)*ap5
  334 continue
  332 continue
  330 continue
c
      e1=a0
      e11=a0
      do 250 csym=1,nirred
      absym=IXOR32(csym-1,ijksym-1)+1
      do 252 c=flov(csym,3)-no,flov(csym,4)-no
      cc=c-flov(csym,3)+no+1
      d4=d3-ee(c+no)
      do 254 bsym=1,csym
      asym=IXOR32(absym-1,bsym-1)+1
      if (asym.gt.bsym)goto 254
      acsym=IXOR32(asym-1,csym-1)+1
      bcsym=IXOR32(bsym-1,csym-1)+1
      limb=flov(bsym,4)-no
      if (csym.eq.bsym)limb=c
      do 256 b=flov(bsym,3)-no,limb
      bb=b-flov(bsym,3)+no+1
      d5=d4-ee(b+no)
      lima=flov(asym,4)-no
      if (asym.eq.bsym)lima=b
      if (c.eq.b)lima=min(b-1,lima)
      do 258 a=flov(asym,3)-no,lima
      aa=a-flov(asym,3)+no+1
      ixabc=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((b-1)*nv+a)
      ixacb=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((c-1)*nv+a)
      ixbac=iovvv(ijksym,csym)+(cc-1)*npr(absym,2,2)+isqvv((a-1)*nv+b)
      ixbca=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((c-1)*nv+b)
      ixcab=iovvv(ijksym,bsym)+(bb-1)*npr(acsym,2,2)+isqvv((a-1)*nv+c)
      ixcba=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+isqvv((b-1)*nv+c)
c  a>b>c
      x1=buf2(ixabc)+buf2(ixbca)+buf2(ixcab)
      x2=buf2(ixacb)+buf2(ixbac)+buf2(ixcba)
      y1=buf1(ixabc)+buf1(ixbca)+buf1(ixcab)
      y2=buf1(ixacb)+buf1(ixbac)+buf1(ixcba)
      fac=d5-ee(a+no)
      e1=e1+((x1-x2)*(y1-y2)-x1*y2-x2*y1)/fac
      e11=e11+(buf1(ixabc)*buf2(ixabc)+buf1(ixacb)*buf2(ixacb)+
     &         buf1(ixbac)*buf2(ixbac)+buf1(ixbca)*buf2(ixbca)+
     &         buf1(ixcab)*buf2(ixcab)+buf1(ixcba)*buf2(ixcba))/fac
  258 continue
  256 continue
  254 continue
  252 continue
  250 continue
      call wtgt(tx(14))
      call wtst
c
      if (i.eq.j.or.j.eq.k)then
      emp4t=emp4t+a3*(e1+a3*e11)
      else
      emp4t=emp4t+a6*(e1+a3*e11)
      endif
c
  104 continue
  102 continue
  101 continue
  100 continue
c
      emp4t = emp4t/a3
      write(*,1) emp4t
      if(iopt.eq.6) then
      write(*,5) eccsd+emp4t
      else
      write(*,4) eccsd+emp4t
      end if
      eccsd=eccsd+emp4t
   1  format(/  ,2x,'triples : mp4+mp5 =  ',f24.15)
   4  format(    2x,'ccsd(t)   energy  =  ',f24.15,//)
   5  format(    2x,'qcisd(t)  energy  =  ',f24.15,//)
c
      do 9823 i=2,6
      tx(1)=tx(1)+tx(i)
      tx(7)=tx(7)+tx(6+i)
 9823 continue
      write(6,9824)tx(1),tx(7),tx(13),tx(14),
     &             tx(1)+tx(7)+tx(13)+tx(14)
 9824 format(8x,' **** timing  information ****',8x,/,
     &' mp(4) e and f integral mxm    ',e15.5,/,
     &'                        sorts  ',e15.5,/,
     &' mp(5) d integral contribution ',e15.5,/,
     &' final energy summation        ',e15.5,/,
     &' total                         ',e15.5,/)
      return
      end
      subroutine putdata(fsec,flov,npr,t1,t2,buf,ee)
      implicit integer (a-z)
      integer fsec(*),flov(nirred,4),npr(nirred,3,2)
      REAL t1(*),t2(*),buf(*),ee(*)
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
      REAL diff,intget,t1get,t2get,tst1,wget,vget
      REAL d1,d2,d3,d4,d5,fac
INCLUDE(common/t_int)
c
      idx(i,j)=max(i,j)*(max(i,j)-1)/2+min(i,j)
c
      call srew(itap69)
      call tit_sread(itap69,t1,intowp(ndimt1))
      call tit_sread(itap69,t2,intowp(ndimt2))
c
      call vclr(buf,1,lnbkt)
      call srew(itap60)
c      call swrit(itap60,buf,intowp(lnbkt))
      call srew(itap61)
c      call swrit(itap61,buf,intowp(lnbkt))
      call srew(itap62)
c      call swrit(itap62,buf,intowp(lnbkt))
      call srew(itap63)
c      call swrit(itap63,buf,intowp(lnbkt))
c      call swrit(itap63,buf,intowp(lnbkt))
c      call swrit(itap63,buf,intowp(lnbkt))
      call srew(itap64)
c      call swrit(itap64,buf,intowp(lnbkt))
      call srew(itap65)
c      call swrit(itap65,buf,intowp(lnbkt))
c
      ix=(no+nv)*(no+nv+1)/2
      lint=ix*(ix+1)/2
      lt1amp=no*nv
      lt2amp=lt1amp*(lt1amp+1)/2
      t1amp=1
      t2amp=t1amp+lt1amp
      taumat=t2amp+lt2amp
      rint=taumat+lt2amp
      fmat=rint+lint
      nonv=no*nv
      lthw=(nonv+2)*(nonv+1)*nonv/6
      emat=fmat+lthw
      iend=emat+lthw
      if (iend.gt.lscr)then
        print *,' increase length of scr to ',iend
        call caserr('increase length of scratch')
      endif
      do 1 i=1,lscr
        scr(i)=0.0d00
    1 continue
c
c --  sort t1 amplitudes
      off=0
      do 10 asym=1,nirred
      do 20 a=flov(asym,3)-no,flov(asym,4)-no 
      do 30 i=flov(asym,1),flov(asym,2)
      off=off+1
      ix1=t1amp+(a-1)*no+i-1
      scr(ix1)=t1(off)
   30 continue
   20 continue
   10 continue
c
c --  sort t2 amplitudes
      off=0
      do 110 absym=1,nirred
      len=npr(absym,3,2)
      do 120 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      if (asym.lt.bsym)goto 120
      do 130 a=flov(asym,3)-no,flov(asym,4)-no
      limb=flov(bsym,4)-no
      if (asym.eq.bsym)limb=a
      do 140 b=flov(bsym,3)-no,limb
      do 150 csym=1,nirred
      dsym=IXOR32(absym-1,csym-1)+1
      do 160 c=flov(csym,1),flov(csym,2)
      do 170 d=flov(dsym,1),flov(dsym,2)
      off=off+1
      ix1=(a-1)*no+c
      ix2=(b-1)*no+d
      ix3=t2amp+idx(ix1,ix2)-1
      scr(ix3)=t2(off)
  170 continue
  160 continue
  150 continue
  140 continue
  130 continue
  120 continue
  110 continue
c
c     make the tau matrix
      do 3000 aisym=1,nirred
      do 3000 asym=1,nirred
      isym=IXOR32(aisym-1,asym-1)+1
      do 3000 a=flov(asym,3),flov(asym,4)
      do 3000 i=flov(isym,1),flov(isym,2)
      ix1=(a-no-1)*no+i
      do 3000 bsym=1,nirred
      jsym=IXOR32(aisym-1,bsym-1)+1
      do 3000 b=flov(bsym,3),flov(bsym,4)
      do 3000 j=flov(jsym,1),flov(jsym,2)
      ix2=(b-no-1)*no+j
      ix3=taumat+idx(ix1,ix2)-1
      if (aisym.eq.1)then
      scr(ix3)=t2get(i,a,j,b)+t1get(i,a)*t1get(j,b)
      else
      scr(ix3)=t2get(i,a,j,b)
      endif
 3000 continue
      print *,' end of 3000'
c
c -- start integral reading
c
c --  a integrals
      print *,' reading in a integrals '
      call srew(itap60)
      itscr=itap60
      off=lnbkt
      do 510 absym=1,nirred
      len=npr(absym,1,2)
      do 520 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 530 a=flov(asym,1),flov(asym,2)
      do 540 b=flov(bsym,1),flov(bsym,2)
      if (off+len.gt.lnbkt)then
        call tit_sread(itscr,buf,intowp(lnbkt))
        off=0
      endif
      do 550 csym=1,nirred
      dsym=IXOR32(absym-1,csym-1)+1
      do 560 c=flov(csym,1),flov(csym,2)
      do 570 d=flov(dsym,1),flov(dsym,2)
      ix1=idx(a,c)
      ix2=idx(b,d)
      ix3=rint+idx(ix1,ix2)-1
      off=off+1
      diff=abs(scr(ix3)-buf(off))
_IF1()       if (scr(ix3).ne.9.99d+99.and.diff.gt.1.0d-10)
_IF1()      &   write(6,1235)a,b,c,d,scr(ix3),buf(off),diff
      scr(ix3)=buf(off)
  570 continue
  560 continue
  550 continue
  540 continue
  530 continue
  520 continue
  510 continue
c
c --  b integrals
      print *,' reading in b integrals '
      call srew(itap61)
      itscr=itap61
      off=lnbkt
      do 610 absym=1,nirred
      len=npr(absym,2,2)
      do 620 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      if (bsym.gt.asym)goto 620
      do 630 a=flov(asym,3),flov(asym,4)
      limb=flov(bsym,4)
      if (asym.eq.bsym)limb=a
      do 640 b=flov(bsym,3),limb
      if (off+len.gt.lnbkt)then
        call tit_sread(itscr,buf,intowp(lnbkt))
        off=0
      endif
      do 650 csym=1,nirred
      dsym=IXOR32(absym-1,csym-1)+1
      do 660 c=flov(csym,3),flov(csym,4)
      do 670 d=flov(dsym,3),flov(dsym,4)
      ix1=idx(a,c)
      ix2=idx(b,d)
      ix3=rint+idx(ix1,ix2)-1
      off=off+1
      diff=abs(scr(ix3)-buf(off))
_IF1()       if (scr(ix3).ne.9.99d+99.and.diff.gt.1.0d-10)
_IF1()      &   write(6,1235)a,b,c,d,scr(ix3),buf(off),diff
      scr(ix3)=buf(off)
  670 continue
  660 continue
  650 continue
  640 continue
  630 continue
  620 continue
  610 continue
c
c --  c integrals
      print *,' reading in c integrals '
      call srew(itap62)
      itscr=itap62
      off=lnbkt
      do 410 absym=1,nirred
      len=npr(absym,3,2)
      do 420 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 430 a=flov(asym,3),flov(asym,4)
      do 440 b=flov(bsym,1),flov(bsym,2)
      if (off+len.gt.lnbkt)then
        call tit_sread(itscr,buf,intowp(lnbkt))
        off=0
      endif
      do 450 csym=1,nirred
      dsym=IXOR32(absym-1,csym-1)+1
      do 460 c=flov(csym,3),flov(csym,4)
      do 470 d=flov(dsym,1),flov(dsym,2)
      ix1=idx(a,c)
      ix2=idx(b,d)
      ix3=rint+idx(ix1,ix2)-1
      off=off+1
      diff=abs(scr(ix3)-buf(off))
_IF1()       if (scr(ix3).ne.9.99d+99.and.diff.gt.1.0d-10)
_IF1()      &   write(6,1235)a,b,c,d,scr(ix3),buf(off),diff
      scr(ix3)=buf(off)
  470 continue
  460 continue
  450 continue
  440 continue
  430 continue
  420 continue
  410 continue
c
c --  d integrals
      print *,' reading in d integrals '
      call rsetsa(itap63,fsec(5))
      itscr=itap63
      off=lnbkt
      do 210 absym=1,nirred
      len=npr(absym,3,2)
      do 220 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 230 a=flov(asym,3),flov(asym,4)
      do 240 b=flov(bsym,1),flov(bsym,2)
      if (off+len.gt.lnbkt)then
        call tit_sread(itscr,buf,intowp(lnbkt))
        off=0
      endif
      do 250 csym=1,nirred
      dsym=IXOR32(absym-1,csym-1)+1
      do 260 c=flov(csym,3),flov(csym,4)
      do 270 d=flov(dsym,1),flov(dsym,2)
      ix1=idx(a,d)
      ix2=idx(b,c)
      ix3=rint+idx(ix1,ix2)-1
      off=off+1
      diff=abs(scr(ix3)-buf(off))
_IF1()       if (scr(ix3).ne.9.99d+99.and.diff.gt.1.0d-10)
_IF1()      &   write(6,1235)a,b,c,d,scr(ix3),buf(off),diff
_IF1() 1235 format(1x,4i5,2e22.14,e15.5)
      scr(ix3)=buf(off)
  270 continue
  260 continue
  250 continue
  240 continue
  230 continue
  220 continue
  210 continue
c
c --  e integrals
      print *,' reading in e integrals '
      call srew(itap64)
      itscr=itap64
      off=lnbkt
      do 710 absym=1,nirred
      len=npr(absym,1,2)
      do 720 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 730 a=flov(asym,3),flov(asym,4)
      do 740 b=flov(bsym,1),flov(bsym,2)
      if (off+len.gt.lnbkt)then
        call tit_sread(itscr,buf,intowp(lnbkt))
        off=0
      endif
      do 750 csym=1,nirred
      dsym=IXOR32(absym-1,csym-1)+1
      do 760 c=flov(csym,1),flov(csym,2)
      do 770 d=flov(dsym,1),flov(dsym,2)
      ix1=idx(a,b)
      ix2=idx(c,d)
      ix3=rint+idx(ix1,ix2)-1
      off=off+1
      diff=abs(scr(ix3)-buf(off))
_IF1()       if (scr(ix3).ne.9.99d+99.and.diff.gt.1.0d-10)
_IF1()      &   write(6,1235)a,b,c,d,scr(ix3),buf(off),diff
      scr(ix3)=buf(off)
  770 continue
  760 continue
  750 continue
  740 continue
  730 continue
  720 continue
  710 continue
c
c
c --  f integrals
      print *,' reading in f integrals '
      itscr=itap65
      call srew(itscr)
      off=lnbkt
      do 310 absym=1,nirred
      len=npr(absym,2,2)
      do 320 asym=1,nirred
      bsym=IXOR32(absym-1,asym-1)+1
      do 330 a=flov(asym,3),flov(asym,4)
      do 340 b=flov(bsym,1),flov(bsym,2)
      if (off+len.gt.lnbkt)then
        call tit_sread(itscr,buf,intowp(lnbkt))
        off=0
      endif
      do 350 csym=1,nirred
      dsym=IXOR32(absym-1,csym-1)+1
      do 360 c=flov(csym,3),flov(csym,4)
      do 370 d=flov(dsym,3),flov(dsym,4)
      ix1=idx(a,c)
      ix2=idx(b,d)
      ix3=rint+idx(ix1,ix2)-1
      off=off+1
      diff=abs(scr(ix3)-buf(off))
_IF1()       if (scr(ix3).ne.9.99d+99.and.diff.gt.1.0d-10)
_IF1()      &   write(6,1235)a,b,c,d,scr(ix3),buf(off),diff
      scr(ix3)=buf(off)
  370 continue
  360 continue
  350 continue
  340 continue
  330 continue
  320 continue
  310 continue
c
      off1=fmat-1
      do 3400 i=1,no
      do 3402 a=no+1,no+nv
      do 3404 j=1,i
      limb=no+nv
      if (j.eq.i)limb=a
      do 3406 b=no+1,limb
      do 3408 k=1,j
      limc=no+nv
      if (k.eq.j)limc=b
      do 3410 c=no+1,limc
      tst1=0.0d00
      do 3420 f=no+1,no+nv
      tst1=tst1+intget(i,a,b,f)*t2get(k,c,j,f)
      tst1=tst1+intget(i,a,c,f)*t2get(j,b,k,f)
      tst1=tst1+intget(k,c,a,f)*t2get(j,b,i,f)
      tst1=tst1+intget(k,c,b,f)*t2get(i,a,j,f)
      tst1=tst1+intget(j,b,c,f)*t2get(i,a,k,f)
      tst1=tst1+intget(j,b,a,f)*t2get(k,c,i,f)
 3420 continue
c
      do 3422 m=1,no
      tst1=tst1-intget(k,c,i,m)*t2get(j,b,m,a)
      tst1=tst1-intget(j,b,i,m)*t2get(k,c,m,a)
      tst1=tst1-intget(j,b,k,m)*t2get(i,a,m,c)
      tst1=tst1-intget(i,a,k,m)*t2get(j,b,m,c)
      tst1=tst1-intget(i,a,j,m)*t2get(k,c,m,b)
      tst1=tst1-intget(k,c,j,m)*t2get(i,a,m,b)
 3422 continue
      off1=off1+1
      scr(off1)=tst1
 3410 continue
 3408 continue
 3406 continue
 3404 continue
 3402 continue
 3400 continue
c
      off1=emat-1
      do 3500 i=1,no
      d1=ee(i)
      do 3502 a=no+1,no+nv
      d2=d1-ee(a)
      do 3504 j=1,i
      d3=d2+ee(j)
      limb=no+nv
      if (j.eq.i)limb=a
      do 3506 b=no+1,limb
      d4=d3-ee(b)
      do 3508 k=1,j
      d5=d4+ee(k)
      limc=no+nv
      if (k.eq.j)limc=b
      do 3510 c=no+1,limc
      fac=6.0d00/(d5-ee(c))
ctemp
c      fac=6.0d00
ctemp
      tst1=(8.0d00*wget(i,j,k,a,b,c)+2.0d00*wget(i,j,k,b,c,a)+
     &      2.0d00*wget(i,j,k,c,a,b)-4.0d00*wget(i,j,k,c,b,a)-
     &      4.0d00*wget(i,j,k,a,c,b)-4.0d00*wget(i,j,k,b,a,c)+
     &      4.0d00*vget(i,j,k,a,b,c)+1.0d00*vget(i,j,k,b,c,a)+
     &      1.0d00*vget(i,j,k,c,a,b)-2.0d00*vget(i,j,k,c,b,a)-
     &      2.0d00*vget(i,j,k,a,c,b)-2.0d00*vget(i,j,k,b,a,c))*fac
      off1=off1+1
      scr(off1)=tst1
 3510 continue
 3508 continue
 3506 continue
 3504 continue
 3502 continue
 3500 continue
      print *,' end of putdata'
      return
      end
      subroutine rcopy(n,a,ia,b,ib)
      implicit integer (a-z)
      REAL a(*),b(*)
c
      ada = 1
      adb = 1
      do 10 i = 1,n
      b(adb) = a(ada)
      ada = ada + ia
      adb = adb + ib
   10 continue
c
      return
      end
      subroutine rde(eints,buf,npr,flov,isqov,itrio,ife2, 
     1                 fpbke1,ioff)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),fpbke1(nbke1),
     1  isqov(nsqoo),itrio(ntrio),ioff(nbf),ife2(nirred)
      REAL eints(*),buf(lnbkt)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  read in e integrals and store unique set in eints
c
      ife2(1) = 0
      do 11 irr = 2,nirred
      irrm1 = irr - 1
      ife2(irr) = ife2(irrm1) + npr(irrm1,3,2)*npr(irrm1,1,1)
   11 continue
c
      call srew(itap64)
      ibke1 = 0
      nbeu = 0
c
      do 10 busym = 1,nirred
      lnbeu = npr(busym,3,2)
      lniv = npr(busym,1,2)
c
      if(lnbeu.ne.0.and.lniv.ne.0) then
c
      do 20 besym = 1,nirred
      usym = IXOR32(busym-1,besym-1) + 1
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fu = flov(usym,1)
      lu = flov(usym,2)
c
      nu = lu - fu + 1
      do 30 be = fbe,lbe
      do 40 u = fu,lu
      nbeu = nbeu + 1
      buof = ife2(busym) + (isqov((be-1)*no+u)-1)*npr(busym,1,1)
c
      if(nbeu.eq.fpbke1(ibke1+1)) then
      icnt = 0
      ibke1 = ibke1 + 1
      call tit_sread(itap64,buf,intowp(lnbkt))
      end if
c
      do 50 isym = 1,nirred
      vsym = IXOR32(busym-1,isym-1) + 1
      fi = flov(isym,1)
      li = flov(isym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
c
      do 60 i = fi,li
      do 80 v = fv,lv
      icnt = icnt + 1
      buiv = buof + itrio(ioff(max(i,v))+min(i,v))
      eints(buiv) = buf(icnt)
ctjl  tau(uvib) = buf(icnt)
   80 continue
   60 continue
   50 continue
   40 continue
   30 continue
   20 continue
      end if
   10 continue
c
      return
      end
      subroutine rdf(fints,buf,ioff,itriv,isqov,npr,flov,
     1                 fpbkf,isqvv,iff2)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),iff2(nirred),
     1  ioff(nbf),itriv(ntriv),isqov(nsqov),fpbkf(nbkf),isqvv(nsqvv)
      REAL fints(*),buf(lnbkt)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  set up three arrays needed for addressing
c
ctjl      nfpr = 1
ctjl      do 110 nbk = 2,nbkf+1
ctjl      do 120 bi = nfpr,(fpbkf(nbk)-1)
ctjl      bkopr(bi) = nbk - 1
ctjl 120  continue
ctjl      nfpr = fpbkf(nbk)
ctjl 110  continue
c
ctjl      offs(1) = 0
ctjl      nbk = 1
ctjl      len = 0
ctjl      do 130 irr = 1,nirred
ctjl      do 140 bi = 1,npr(irr,3,2)
ctjl      len = len + npr(irr,2,2)
ctjl      if(len.gt.lnbkt) then
ctjl      nbk = nbk + 1
ctjl      offs(nbk) = len - npr(irr,2,2) + offs(nbk-1)
ctjl      len = npr(irr,2,2)
ctjl      end if
ctjl 140  continue
ctjl 130  continue
c
ctjl      offov(1) = 0
ctjl      do 150 irr = 2,nirred
ctjl      offov(irr) = npr(irr,3,2) + offov(irr-1)
ctjl 150  continue
c
ctjl      iff2(1) = 0
ctjl      do 110 irr = 2,nirred
ctjl      irrm1 = irr - 1
ctjl      iff2(irr) = iff2(irrm1) + npr(irrm1,3,2)*npr(irrm1,2,1)
ctjl 110  continue
c
c
      call srew(itap65)
      ibkf = 0
      nbei = 0
c
      do 10 bisym = 1,nirred
      lnbei = npr(bisym,3,2)
      lnab = npr(bisym,2,2)
c
      if(lnbei.ne.0.and.lnab.ne.0) then
c
      do 20 besym = 1,nirred
      isym = IXOR32(bisym-1,besym-1) + 1
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fi = flov(isym,1)
      li = flov(isym,2)
c
      do 30 be = fbe,lbe
      beofo = (be-1)*no
      do 40 i = fi,li
      beiq = beofo + i
      nbei = nbei + 1
c
      if(nbei.eq.fpbkf(ibkf+1)) then
      off1 = 0
      ibkf = ibkf + 1
      call tit_sread(itap65,buf,intowp(lnbkt))
      end if
c
      do 50 asym = 1,nirred
      bsym = IXOR32(bisym-1,asym-1) + 1
      ibsym = IXOR32(bsym-1,isym-1) + 1
      fb = flov(bsym,3) - no
      lb = flov(bsym,4) - no
      fa = flov(asym,3) - no
      la = flov(asym,4) - no
c
      do 60 a = fa,la
      aofv = (a-1)*nv
      bea = ioff(max(be,a)) + min(be,a)
      beatr = itriv(bea)
      do 80 b = fb,lb
c
      add1 = off1 + isqvv(aofv+b)
      bi = (b-1)*no + i
      biq = isqov(bi)
      iadr = (biq-1)*npr(ibsym,2,1) + beatr + iff2(ibsym)
      fints(iadr) = buf(add1)
c
   80 continue
   60 continue
   50 continue
      off1 = off1 + lnab
   40 continue
   30 continue
   20 continue
      end if
   10 continue
c
c  write out last buckets
c
ctjl      do 210 ibk = 1,nbkf
ctjl      noff = (ibk-1)*nszbf + 1
ctjl      call rgetsa(itap90,ichan)
ctjl      mchain(ibk) = ichan
ctjl      call swrit(itap90,bkt(noff),nszbf2)
ctjl 210  continue
c
c  chain back and rewrite itap65
c
ctjl      call srew(itap65)
ctjl      do 310 ibk = 1,nbkf
ctjl      call vclr(buf,1,lnbkt)
ctjl      isec = mchain(ibk)
ctjl 320  call rread(itap90,ibkt,nszbf2,isec)
ctjl      isec = ibkt(1)
ctjl      call rmove(buf,bkt(ivoff+1),ibkt(3),ibkt(2))
ctjl      if(ibkt(1).ne.0) go to 320
ctjl      call swrit(itap65,buf,intowp(lnbkt))
ctjl      call vclr(buf,1,lnbkt)
ctjl 310  continue
c
      return
      end
      subroutine read57(flov,fpbka,fpbkb,fpbkc,fpbkd1,fpbkd2,fpbkd3,
     1                  fpbke1,fpbkf,npr,fsec,orbsym,e,pt57,
     2                  itriv,itrio,isqvv,isqoo,isqov,ioff,ifa,ifb,
     3                  ifc,ifd1,ifd2,ifd3,ifd4,ife1,iff,ptocc,
     4                  isqvo,ifa2)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),fpbka(nbka+1),
     1  fpbkb(nbkb+1),fpbkc(nbkc+1),fpbkd1(nbkd1+1),fpbkd2(nbkd2+1),
     2  fpbke1(nbke1+1),fpbkf(nbkf+1),fsec(nlist),fpbkd3(nbkd3+1),
     3  orbsym(nbf),itriv(ntriv),itrio(ntrio),isqvv(nsqvv),
     4  isqov(nsqov),ioff(nbf),ifa(nirred),ifb(nirred),
     5  ifc(nirred),ifd1(nirred),ifd2(nirred),ifd3(nirred),
     6  ifd4(nirred),ife1(nirred),iff(nirred),
     7  ptocc(nbf),isqoo(nsqoo),isqvo(nsqov),ifa2(nirred)
      REAL e(nbf)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      call wreadw(itap57,flov,nirred*4,pt57,pt57)
      call wreadw(itap57,npr,nirred*6,pt57,pt57)
      call wreadw(itap57,fpbka,nbka+1,pt57,pt57)
      call wreadw(itap57,fpbkb,nbkb+1,pt57,pt57)
      call wreadw(itap57,fpbkc,nbkc+1,pt57,pt57)
      call wreadw(itap57,fpbkd1,nbkd1+1,pt57,pt57)
      call wreadw(itap57,fpbkd2,nbkd2+1,pt57,pt57)
      call wreadw(itap57,fpbkd3,nbkd3+1,pt57,pt57)
      call wreadw(itap57,fpbke1,nbke1+1,pt57,pt57)
ctjl  call wreadw(itap57,fpbke2,nbke2+1,pt57,pt57)
      call wreadw(itap57,fpbkf,nbkf+1,pt57,pt57)
      call wreadw(itap57,fsec,nlist,pt57,pt57)
      call wreadw(itap57,orbsym,nbf,pt57,pt57)
      call wreadw(itap57,itriv,ntriv,pt57,pt57)
      call wreadw(itap57,itrio,ntrio,pt57,pt57)
      call wreadw(itap57,isqvv,nsqvv,pt57,pt57)
      call wreadw(itap57,isqoo,nsqoo,pt57,pt57)
      call wreadw(itap57,isqov,nsqov,pt57,pt57)
      call wreadw(itap57,isqvo,nsqov,pt57,pt57)
      call wreadw(itap57,ioff,nbf,pt57,pt57)
      call wreadw(itap57,ifa,nirred,pt57,pt57)
      call wreadw(itap57,ifa2,nirred,pt57,pt57)
      call wreadw(itap57,ifb,nirred,pt57,pt57)
      call wreadw(itap57,ifc,nirred,pt57,pt57)
      call wreadw(itap57,ifd1,nirred,pt57,pt57)
      call wreadw(itap57,ifd2,nirred,pt57,pt57)
      call wreadw(itap57,ifd3,nirred,pt57,pt57)
      call wreadw(itap57,ifd4,nirred,pt57,pt57)
      call wreadw(itap57,ife1,nirred,pt57,pt57)
ctjl  call wreadw(itap57,ife2,nirred,pt57,pt57)
      call wreadw(itap57,iff,nirred,pt57,pt57)
      call wreadw(itap57,ptocc,nbf,pt57,pt57)
      call wreadw(itap57,e,intowp(nbf),pt57,pt57)
c
c  close file 57 and return to main
c
c      call rclose(itap57,3)
c
      itest = 0
      if(itest.eq.1) then
      write(iw,*) '  in subroutine read57 '
      write(iw,*) ' nirred ',nirred
      write(iw,*) ' ntriv ',ntriv
      write(iw,*) ' ntrio ',ntrio
      write(iw,*) ' nsqvv ',nsqvv
      write(iw,*) ' nsqoo ',nsqoo
      write(iw,*) ' nsqov ',nsqov
      write(iw,*) ' lnbkt ',lnbkt
      write(iw,*) ' nlist ',nlist
      write(iw,*) ' nbka ',nbka
      write(iw,*) ' nbkb ',nbkb
      write(iw,*) ' nbkc ',nbkc
      write(iw,*) ' nbkd1 ',nbkd1
      write(iw,*) ' nbkd2 ',nbkd2
      write(iw,*) ' nbkd3 ',nbkd3
      write(iw,*) ' nbke1 ',nbke1
      write(iw,*) ' nbke2 ',nbke2
      write(iw,*) ' nbkf ',nbkf
      write(iw,*) ' ndimt1 ',ndimt1
      write(iw,*) ' ndimt2 ',ndimt2
      write(iw,*) ' norbs ',norbs
      write(iw,*) ' ndimw ',ndimw
c
      write(iw,*) ' fpbka  ',fpbka
      write(iw,*) ' fpbkb  ',fpbkb
      write(iw,*) ' fpbkc  ',fpbkc
      write(iw,*) ' fpbkd1 ',fpbkd1
      write(iw,*) ' fpbkd2 ',fpbkd2
      write(iw,*) ' fpbkd3 ',fpbkd3
      write(iw,*) ' fpbke1 ',fpbke1
      write(iw,*) ' fpbkf  ',fpbkf
c
      write(6,*) ' isqoo ',isqoo
      write(6,*) ' itrio ',itrio
      write(6,*) ' itriv ',itriv
      write(6,*) ' isqvv ',isqvv
      write(6,*) ' isqov ',isqov
      write(6,*) ' ifa2 ',ifa2
      write(6,*) ' ifc ',ifc
      write(6,*) ' fsec ',fsec
      write(6,*) ' npr ',npr
      write(6,*) ' ifd1 ',ifd1
      write(6,*) ' ifd3 ',ifd3
      end if
      return
      end
      subroutine rscal(itot,xx,a,ia)
      implicit integer (a-z)
      REAL xx,a(*)
      do 10 i=1,itot*ia,ia
        a(i)=a(i)*xx
   10 continue
      return
      end
      subroutine sbvec2(a,b,n,fac)
      implicit integer(a-z)
      REAL a(n),b(n),fac
      do 10 i = 1,n
      a(i) =  a(i) - b(i)*fac
   10 continue
      return
      end
      subroutine settr(iff2,ife2,npr,ndimf,ndime,buf1,buf2,w1,ioff,
     1                 isqoo,isqvv,isqov,flov,itriv,ifd2,ifd4,fpbkd1)
      implicit integer(a-z)
      integer iff2(nirred+1),ife2(nirred+1),npr(nirred,3,2),ioff(nbf)
      integer isqoo(nsqoo),isqvv(nsqvv),isqov(nsqov),flov(nirred,4)
      integer itriv(ntriv),ifd2(nirred),ifd4(nirred),fpbkd1(nbkd1)
      REAL buf1(lnbkt),buf2(ndimw),w1(ndimt1)
      REAL a0
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      data a0 /0.0d0/
c
      iff2(1) = 0
      ife2(1) = 0
      do 10 irr = 2,nirred+1
      irrm1 = irr - 1
      iff2(irr) = iff2(irrm1) + npr(irrm1,3,2)*npr(irrm1,2,1)
      ife2(irr) = ife2(irrm1) + npr(irrm1,3,2)*npr(irrm1,1,1)
   10 continue
      ndimf = iff2(nirred+1)
      ndime = ife2(nirred+1)
ctjl  write(*,*)
ctjl  write(*,*) ' ndimf,ndime = ',ndimf,ndime
ctjl  write(*,*)
      ntrps = (npr(1,3,2)+2)*(npr(1,3,2)+1)*npr(1,3,2)/6
      do 12 irr = 2,nirred
      ntrps = ntrps + npr(1,3,2)*(npr(irr,3,2)+1)*npr(irr,3,2)/2
   12 continue
c
      do 13 irr = 3,nirred
      do 14 jrr = (irr+1),nirred
      krr = IXOR32(irr-1,jrr-1) + 1
      ntrps = ntrps + npr(irr,3,2)*npr(jrr,3,2)*npr(krr,3,2)
   14 continue
   13 continue
c
      write(*,*) 
      write(*,*) '  there are ',ntrps,' triple excitations'
      write(*,*)
c
c
c  read in t2, expand and write out to file 90
c
      call srew(itap69)
      call tit_sread(itap69,w1,intowp(ndimt1))
      call tit_sread(itap69,buf1,intowp(ndimt2))
c
c  expand the t2 amplitudes 
c
      call vclr(w1,1,ndimt1)
      call extau1(buf1,buf2,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,ifd4,
     1            w1,isqov)
      call srew(itap90)
      call swrit(itap90,buf2,intowp(ndimw))
c
c  read in the d integrals, store the unique list and write to 90
c
      call vclr(buf2,1,ndimw)
      call srew(itap63)
      ibkd1 = 0
      nbeu = 0
c
      do 11 busym = 1,nirred
      lnbeu = npr(busym,3,2)
      lnia = lnbeu
c
      if(lnbeu.ne.0) then
c
      do 20 besym = 1,nirred
      usym = IXOR32(busym-1,besym-1) + 1
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fu = flov(usym,1)
      lu = flov(usym,2)
c
      do 30 be = fbe,lbe
      do 40 u = fu,lu
      nbeu = nbeu + 1
c
      if(nbeu.eq.fpbkd1(ibkd1+1)) then
      icnt = 0
      ibkd1 = ibkd1 + 1
      call tit_sread(itap63,buf1,intowp(lnbkt))
      end if
c
      do 50 asym = 1,nirred
      isym = IXOR32(busym-1,asym-1) + 1
      uisym = IXOR32(usym-1,isym-1) + 1
      fi = flov(isym,1)
      li = flov(isym,2)
      fa = flov(asym,3) - no
      la = flov(asym,4) - no
c
      do 60 a = fa,la
      mxabe = max(a,be)
      mnabe = min(a,be)
      beaof=(itriv((mxabe-1)*mxabe/2+mnabe)-1)*npr(uisym,1,2)
     1      + ifd2(uisym)
      do 80 i = fi,li
      icnt = icnt + 1
ctemp
      if(be.ge.a) then
      buai = beaof + isqoo((u-1)*no+i)
      buf2(buai) = buf1(icnt)
      end if
ctemp
   80 continue
   60 continue
   50 continue
   40 continue
   30 continue
   20 continue
      end if
   11 continue
c
c  write the d integrals out
c
      call swrit(itap90,buf2,intowp(ndimw))
c
c  return
c
      return
      end
      subroutine srt21(t2,tau,ioff,itriv,isqoo,isqvv,npr,flov,ifd2,
     1                 ioovv,ioovvt,ntr)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ifd2(nirred),
     1  ioff(nbf),itriv(ntriv),isqoo(nsqoo),isqvv(nsqvv),ioovvt(nirred),
     2  ioovv(nirred,nirred),ntr(nirred,2)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  sort and expand t2 from t2(v,u,ga<be) to tau(v,ugabe)
c
      off2 = npr(1,1,2)
      do 10 besym = 1,nirred
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 20 be = fbe,lbe
      do 30 ga = fbe,be-1
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2
      bgq = (be-1)*nv + ga
      gbq = (ga-1)*nv + be
      do 40 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      nu = lu - fu + 1
      bgof = (isqvv(bgq)-1)*nu + ioovvt(usym)
      gbof = (isqvv(gbq)-1)*nu + ioovvt(usym)
      do 50 u = fu,lu
      bguof = bgof + (u-fu)*ntr(usym,1)
      gbu = gbof + u - fu + 1
      do 60 v = fu,lu
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      bguv = bguof + v - fu + 1
      gbvu = gbu + (v-fu)*ntr(usym,1)
      tau(bguv) = t2(uvbg)
      tau(gbvu) = t2(uvbg)
  60  continue
  50  continue
  40  continue
  30  continue
      bebe = ioff(be) + be
      beoff = (itriv(bebe)-1)*off2
      bbq = (be-1)*nv + be
      do 70 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      nu = lu - fu + 1
      bbof = (isqvv(bbq)-1)*nu + ioovvt(usym)
      do 80 u = fu,lu
      bbuof = bbof + (u-fu)*ntr(usym,1)
      do 90 v = fu,lu
      uv = (u-1)*no + v
      uvbb = beoff + isqoo(uv)
      bbuv = bbuof + v - fu + 1
      tau(bbuv) = t2(uvbb)
  90  continue
  80  continue
  70  continue
  20  continue
  10  continue
c
      do 11 bgsym = 2,nirred
      off2 = npr(bgsym,1,2)
      do 21 besym = 1,nirred
      gasym = IXOR32(bgsym-1,besym-1) + 1
      if(besym.gt.gasym) then
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 31 be = fbe,lbe
      do 41 ga = fga,lga
      bega = ioff(be) + ga
      bgoff = (itriv(bega)-1)*off2 + ifd2(bgsym)
      bgq = (be-1)*nv + ga
      gbq = (ga-1)*nv + be
      do 51 usym = 1,nirred
      vsym = IXOR32(usym-1,bgsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      nu = lu - fu + 1
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      nvv = lv - fv + 1
      bgof = (isqvv(bgq)-1)*nvv + ioovvt(usym) + ioovv(bgsym,usym)
      gbof = (isqvv(gbq)-1)*nu + ioovvt(vsym) + ioovv(bgsym,vsym)
      do 61 u = fu,lu
      bguof = bgof + (u-fu)*ntr(usym,1)
      gbu = gbof + u - fu + 1
      do 71 v = fv,lv
      uv = (u-1)*no + v
      uvbg = bgoff + isqoo(uv)
      bguv = bguof + v - fv + 1
      gbvu = gbu + (v-fv)*ntr(vsym,1)
      tau(bguv) = t2(uvbg)
      tau(gbvu) = t2(uvbg)
71    continue
61    continue
51    continue
41    continue
31    continue
      end if
21    continue
11    continue
      return
      end
      subroutine srt22(t2,tau,isqoo,ntr,flov,ivvoo,ivvoot)
      implicit integer(a-z)
      integer flov(nirred,4),isqoo(nsqoo),ivvoo(nirred,nirred),
     1  ivvoot(nirred),ntr(nirred,2)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  sort t2 from t2(ube,vga) to t2(ga,uv:be)
c
      icnt = 0
      do 10 gvsym = 1,nirred
      do 20 gasym = 1,nirred
      vsym = IXOR32(gvsym-1,gasym-1) + 1
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      nga = lga - fga + 1
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 30 ga = fga,lga
      gaof = ga - fga + 1
      do 40 v = fv,lv
      vofo = (v-1)*no
      do 50 besym = 1,nirred
      usym = IXOR32(gvsym-1,besym-1) + 1
      uvsym = IXOR32(usym-1,vsym-1) + 1
      beoff = ivvoot(besym) + ivvoo(uvsym,besym) + gaof
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 60 be = fbe,lbe
      beof = beoff + (be-fbe)*ntr(besym,2)
      do 70 u = fu,lu
      guvb = (isqoo(vofo+u) - 1)*nga + beof
      icnt = icnt + 1
      tau(guvb) = t2(icnt)
   70 continue
   60 continue
   50 continue
   40 continue
   30 continue
   20 continue
   10 continue
c
      return
      end
      subroutine srt23(t2,tau,isqoo,ntr,flov,iooov,iooovt)
      implicit integer(a-z)
      integer flov(nirred,4),isqoo(nsqoo),iooov(nirred,nirred),
     1  iooovt(nirred),ntr(nirred,2)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  sort t2 from t2(ga,iv:u) to t2(ga,vu:i)
c
      icnt = 0
      do 10 usym = 1,nirred
      fu = flov(usym,1)
      lu = flov(usym,2)
      do 20 u = fu,lu
      uofo = (u-1)*no
      do 30 visym = 1,nirred
      gasym = IXOR32(visym-1,usym-1) + 1
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      nga = lga - fga + 1
      do 40 vsym = 1,nirred
      isym = IXOR32(visym-1,vsym-1) + 1
      uvsym = IXOR32(usym-1,vsym-1) + 1
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      fi = flov(isym,1)
      li = flov(isym,2)
      iof = iooovt(isym) + iooov(uvsym,isym)
      do 50 v = fv,lv
      uvof = (isqoo(uofo+v)-1)*nga + iof
      do 60 i = fi,li
      iofi = uvof + (i-fi)*ntr(isym,2)
      do 70 ga = fga,lga
      gvui = iofi + ga - fga + 1
      icnt = icnt + 1
      tau(gvui) = t2(icnt)
   70 continue
   60 continue
   50 continue
   40 continue
   30 continue
   20 continue
   10 continue
c
      return
      end
      subroutine srt25(t2,tau,isqoo,npr,flov,iooov,iooovt,ntr)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),ntr(nirred,4),
     1  isqoo(nsqoo),iooovt(nirred),iooov(nirred,nirred)
      REAL t2(ndimw),tau(ndimw)
c
INCLUDE(common/t_parm)
c
c  sort  f2p from t2(v,u,i,be) to tau(be,uv:i)
c
      icnt = 0
      do 11 bisym = 1,nirred
      off2 = npr(bisym,1,2)
      do 21 besym = 1,nirred
      isym = IXOR32(bisym-1,besym-1) + 1
      iof = iooovt(isym) + iooov(bisym,isym)
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      fi = flov(isym,1)
      li = flov(isym,2)
      nbe = lbe - fbe + 1
      do 31 be = fbe,lbe
      beof = be - fbe + 1 + iof
      do 41 i = fi,li
      beiof = beof + (i-fi)*ntr(isym,2)
      do 51 usym = 1,nirred
      vsym = IXOR32(usym-1,bisym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 61 u = fu,lu
      do 71 v = fv,lv
      vu = (v-1)*no + u
      buvi = (isqoo(vu)-1)*nbe + beiof
      icnt = icnt + 1
      tau(buvi) = t2(icnt)
71    continue
61    continue
51    continue
41    continue
31    continue
21    continue
11    continue
      return
      end
      subroutine srte1(tau,t2,isqoo,npr,flov,ifa)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqoo(nsqoo),ifa(nirred)
      REAL tau(ndimw),t2(ndimw)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  sort [e1](j,ui:v) to t2(ij,uv)
c
      icnt = 0
      do 10 vsym = 1,nirred
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 40 v = fv,lv
      do 20 uisym = 1,nirred
      jsym = IXOR32(vsym-1,uisym-1) + 1
      fj = flov(jsym,1)
      lj = flov(jsym,2)
      do 30 usym = 1,nirred
      isym = IXOR32(uisym-1,usym-1) + 1
      uvsym = IXOR32(usym-1,vsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fi = flov(isym,1)
      li = flov(isym,2)
      do 50 u = fu,lu
      uvof = (isqoo((u-1)*no+v)-1)*npr(uvsym,1,2) + ifa(uvsym)
      do 60 i = fi,li
      do 70 j = fj,lj
      jivu = uvof + isqoo((i-1)*no+j)
      icnt = icnt + 1
      t2(jivu) = tau(icnt)
   70 continue
   60 continue
   50 continue
   30 continue
   20 continue
   40 continue
   10 continue
c
      return
      end
      subroutine srte12(tau,t2,isqoo,npr,flov,ifa)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqoo(nsqoo),ifa(nirred)
      REAL tau(ndimw),t2(ndimw)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  starting with [e1](ij,uv) form {[e1](ij,uv) + [e1](ji,vu)}
c  and store as [e1](ij,uv)
c
      do 10 uvsym = 1,nirred
      do 20 usym = 1,nirred
      vsym = IXOR32(uvsym-1,usym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 30 u = fu,lu
      do 40 v = fv,lv
      uvof = (isqoo((u-1)*no+v)-1)*npr(uvsym,1,2) + ifa(uvsym)
      vuof = (isqoo((v-1)*no+u)-1)*npr(uvsym,1,2) + ifa(uvsym)
      do 50 isym = 1,nirred
      jsym = IXOR32(isym-1,uvsym-1) + 1
      fi = flov(isym,1)
      li = flov(isym,2)
      fj = flov(jsym,1)
      lj = flov(jsym,2)
      do 60 i = fi,li
      do 70 j = fj,lj
      jivu = isqoo((i-1)*no+j) + uvof
      ijuv = isqoo((j-1)*no+i) + vuof
      tau(jivu) = t2(jivu) + t2(ijuv)
      tau(ijuv) = tau(jivu)
   70 continue
   60 continue
   50 continue
   40 continue
   30 continue
   20 continue
   10 continue
      return
      end
      subroutine srte1s(tau,t2,isqov,npr,flov,ifc)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqov(nsqov),ifc(nirred)
      REAL tau(ndimw),t2(ndimw)
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
c  sort [e1*](be,vu:ga) to t2(ube,vga)
c
      icnt = 0
      do 10 gasym = 1,nirred
      fga = flov(gasym,3) - no
      lga = flov(gasym,4) - no
      do 40 ga = fga,lga
      gaof = (ga-1)*no
      do 20 uvsym = 1,nirred
      besym = IXOR32(gasym-1,uvsym-1) + 1
      fbe = flov(besym,3) - no
      lbe = flov(besym,4) - no
      do 30 usym = 1,nirred
      vsym = IXOR32(uvsym-1,usym-1) + 1
      gavsym = IXOR32(gasym-1,vsym-1) + 1
      fu = flov(usym,1)
      lu = flov(usym,2)
      fv = flov(vsym,1)
      lv = flov(vsym,2)
      do 50 u = fu,lu
      do 60 v = fv,lv
      gavq = (isqov(gaof+v)-1)*npr(gavsym,3,2) + ifc(gavsym)
      do 70 be = fbe,lbe
      ubvg = gavq + isqov((be-1)*no+u)
      icnt = icnt + 1
      t2(ubvg) = tau(icnt)
   70 continue
   60 continue
   50 continue
   30 continue
   20 continue
   40 continue
   10 continue
c
      return
      end
      subroutine srttp1(bfin,bfout,flov,iovvv,npr,isqvv,idx1,idx2,
     &                  jdx1,jdx2,ijksym,mxv3)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqvv(nsqvv),
     &        iovvv(nirred,nirred),idx1(nsqvv),idx2(nsqvv),
     &        jdx1(nirred),jdx2(nirred,nirred)
      REAL bfin(mxv3),bfout(mxv3)
c
INCLUDE(common/t_parm)
c
      do 112 asym=1,nirred
      bcsym=IXOR32(asym-1,ijksym-1)+1
      do 114 bsym=1,nirred
      csym=IXOR32(bcsym-1,bsym-1)+1
      lnbc=(flov(bsym,4)-flov(bsym,3)+1)*
     &     (flov(csym,4)-flov(csym,3)+1)
_IF1()cfpp$ nodepchk
      do 116 a=flov(asym,3)-no,flov(asym,4)-no
      aa=a-flov(asym,3)+no+1
      off1=iovvv(ijksym,asym)+(aa-1)*npr(bcsym,2,2)+
     &     isqvv((flov(bsym,3)-no-1)*nv+flov(csym,3)-no)-1
      off2=iovvv(ijksym,bsym)+isqvv((a-1)*nv+flov(csym,3)-no)
      off3=jdx2(asym,bsym)
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 118 bc=1,lnbc
      bfout(off1+bc)=bfin(off2+idx2(off3+bc))
  118 continue
  116 continue
  114 continue
  112 continue
      return
      end
      subroutine srttp2(bfin,bfout,flov,iovvv,npr,isqvv,idx1,idx2,
     &                  jdx1,jdx2,ijksym,mxv3)
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),isqvv(nsqvv),
     &        iovvv(nirred,nirred),idx1(nsqvv),idx2(nsqvv),
     &        jdx1(nirred),jdx2(nirred,nirred)
      REAL bfin(mxv3),bfout(mxv3)
c
INCLUDE(common/t_parm)
c
      off1=0
      do 132 asym=1,nirred
      bcsym=IXOR32(asym-1,ijksym-1)+1
      nva=flov(asym,4)-flov(asym,3)+1
      do 134 a=1,nva
      lnbc=npr(bcsym,2,2)
      off2=iovvv(ijksym,asym)+(a-1)*npr(bcsym,2,2)
      off3=jdx1(bcsym)
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir force_vector
      do 136 bc=1,lnbc
      bfout(off1+bc)=bfin(off2+idx1(bc+off3))
  136 continue
      off1=off1+lnbc
  134 continue
  132 continue
      return
      end
      function t1get(i,a)
      implicit integer (a-z)
      REAL t1get
INCLUDE(common/t_parm)
INCLUDE(common/t_int)
      ix1=t1amp+(a-no-1)*no+i-1
      t1get=scr(ix1)
      return
      end
      function t2get(i,a,j,b)
      implicit integer (a-z)
      REAL t2get
INCLUDE(common/t_parm)
INCLUDE(common/t_int)
      idx(i,j)=max(i,j)*(max(i,j)-1)/2+min(i,j)
      ix1=(a-no-1)*no+i
      ix2=(b-no-1)*no+j
      ix3=t2amp+idx(ix1,ix2)-1
      t2get=scr(ix3)
      return
      end
      subroutine trmat(a,nd1,nd2,b)
      implicit integer (a-z)
      REAL a(nd1,nd2),b(nd2,nd1)
      do 10 i=1,nd1
      do 20 j=1,nd2
      b(j,i)=a(i,j)
   20 continue
   10 continue
      return
      end
      subroutine trps(t2,fints,eints,e,isqoo,npr,flov,isqov,
     1                itrsqv,itrsqo,itriv,itrio,ifd2,iff2,ife2,
     2                orbsym,t3,fpbkc,ioff,ifc,ndimf,ndime,
     3                ifd4,isqvv,eccsd,t1,dints,iopt) 
      implicit integer(a-z)
      integer flov(nirred,4),npr(nirred,3,2),itriv(ntriv),itrio(ntrio),
     1  isqoo(nsqoo),ifd2(nirred),iff2(nirred),ife2(nirred),isqov(nsqov)
      integer itrsqv(nsqvv),itrsqo(nsqoo),orbsym(nbf),ifd4(nirred)
      integer ioff(nbf),ifc(nirred),fpbkc(nbkc),isqvv(nsqvv)
      REAL t2(ndimt2),e(nbf),t3(nsqoo*no),t1(ndimt1)
      REAL eints(ndime),fints(ndimf),dints(ndimw)
      REAL a0,a1,a2,a3,a4,a5,a6,a9,e1,emp4t,eccsd,emp4x
      REAL d1,d2,d3,d4,d5,fac,e2,e3,e4,e5,e6
      REAL fia,fib,fic,fja,fjb,fjc,fka,fkb,fkc
      REAL t1ia,t1ib,t1ic,t1ja,t1jb,t1jc,t1ka,t1kb,t1kc
      REAL e11,e22,e33,e44,e55,e66
c
INCLUDE(common/t_files)
INCLUDE(common/t_parm)
c
      data a0,a1,a2,a3,a4,a5 /0.0d0,1.0d0,2.0d0,3.0d0,4.0d0,5.0d0/
      data a6,a9 /6.0d0,9.0d0/
c
c  read in : t2, dints, and t1
c
      call srew(itap90)
      call tit_sread(itap90,t2,intowp(ndimw))
      call tit_sread(itap90,dints,intowp(ndimw))
c
      call srew(itap69)
      call tit_sread(itap69,t1,intowp(ndimt1))
c
c  we have f integrals, e integrals and t2 in memory; form emp4(t)
c
      ab = 0
      do 300 a = 1,nv
      do 310 b = 1,a
      ab = ab + 1
      itrsqv((a-1)*nv+b) = itriv(ab)
      itrsqv((b-1)*nv+a) = itriv(ab)
  310 continue
  300 continue
c
      ij = 0 
      do 320 i = 1,no
      do 330 j = 1,i
      ij = ij + 1
      itrsqo((i-1)*no+j) = itrio(ij)
      itrsqo((j-1)*no+i) = itrio(ij)
  330 continue
  320 continue
c
c  form t3(i,j,l) for a given a,b,c
c
      emp4t = a0
      emp4x = a0
      do 10 a = 1,nv
      asym = orbsym(a+no) + 1
      aof = (a-1)*nv
      d1 = -e(a+no)
      do 20 b = 1,a
ctjl  do 20 b = 1,nv
      bsym = orbsym(b+no) + 1
      absym = IXOR32(asym-1,bsym-1) + 1
      bof = (b-1)*nv
      eab = ifd4(absym) + (isqvv(aof+b)-1)*npr(absym,1,2)
      d2 = d1 - e(b+no)
      do 30 c = 1,b
ctjl  do 30 c = 1,nv
      if(c.eq.a) go to 31
ctjl  if(a.eq.b.and.b.eq.c) go to 31
      csym = orbsym(c+no) + 1
      acsym = IXOR32(asym-1,csym-1) + 1
      bcsym = IXOR32(bsym-1,csym-1) + 1
      abcsm = IXOR32(absym-1,csym-1) + 1
      cof = (c-1)*nv
      eac = ifd4(acsym) + (isqvv(aof+c)-1)*npr(acsym,1,2)
      ebc = ifd4(bcsym) + (isqvv(bof+c)-1)*npr(bcsym,1,2)
      d3 = d2 - e(c+no)
      e1 = a0
      e2 = a0
      e3 = a0
      e4 = a0
      e5 = a0
      e6 = a0
      e11 = a0
      e22 = a0
      e33 = a0
      e44 = a0
      e55 = a0
      e66 = a0
c
      call vclr(t3,1,nsqoo*no)
      do 40 ksym = 1,nirred
      ijsym = IXOR32(ksym-1,abcsm-1) + 1
      fk = flov(ksym,1)
      lk = flov(ksym,2)
      cksym = IXOR32(csym-1,ksym-1) + 1
c
      f3sym = IXOR32(bcsym-1,ksym-1) + 1
      f4sym = IXOR32(acsym-1,ksym-1) + 1
      ff3 = flov(f3sym,3) - no
      lf3 = flov(f3sym,4) - no
      fm1 = flov(f3sym,1) 
      lm1 = flov(f3sym,2)
      ff4 = flov(f4sym,3) - no
      lf4 = flov(f4sym,4) - no
      fm2 = flov(f4sym,1)
      lm2 = flov(f4sym,2)
c
      do 50 jsym = 1,nirred
      isym = IXOR32(jsym-1,ijsym-1) + 1
      fj = flov(jsym,1)
      lj = flov(jsym,2)
      fi = flov(isym,1)
      li = flov(isym,2)
      bjsym = IXOR32(bsym-1,jsym-1) + 1
      aisym = IXOR32(asym-1,isym-1) + 1
      iksym = IXOR32(isym-1,ksym-1) + 1
      jksym = IXOR32(jsym-1,ksym-1) + 1
c
      f1sym = IXOR32(absym-1,isym-1) + 1
      f2sym = IXOR32(absym-1,jsym-1) + 1
      f5sym = IXOR32(bcsym-1,jsym-1) + 1
      f6sym = IXOR32(acsym-1,isym-1) + 1
      ff1 = flov(f1sym,3) - no
      lf1 = flov(f1sym,4) - no
      fm3 = flov(f1sym,1) 
      lm3 = flov(f1sym,2)
      ff2 = flov(f2sym,3) - no
      lf2 = flov(f2sym,4) - no
      fm4 = flov(f2sym,1)
      lm4 = flov(f2sym,2)
      ff5 = flov(f5sym,3) - no
      lf5 = flov(f5sym,4) - no
      fm6 = flov(f5sym,1)
      lm6 = flov(f5sym,2)
      ff6 = flov(f6sym,3) - no
      lf6 = flov(f6sym,4) - no
      fm5 = flov(f6sym,1)
      lm5 = flov(f6sym,2)
c
      do 60 k = fk,lk
      kof = (k-1)*no
      koft = (k-1)*nsqoo
      ck = isqov((c-1)*no+k)
      ckqf = (ck-1)*npr(cksym,2,1) + iff2(cksym)
      ckqe = (ck-1)*npr(cksym,1,1) + ife2(cksym)
      do 70 j = fj,lj
      jof = (j-1)*no
      kj = kof + j
      jk = jof + k
      fkj = isqoo(kj) + ifd4(jksym)
      fjk = isqoo(jk) + ifd4(jksym)
      jofd = (j-1)*no + koft
      bj = isqov((b-1)*no+j)
      bjqf = (bj-1)*npr(bjsym,2,1) + iff2(bjsym)
      bjqe = (bj-1)*npr(bjsym,1,1) + ife2(bjsym)
      do 80 i = fi,li
      if(i.eq.j.and.j.eq.k) go to 81
      iof = (i-1)*no
      ij = iof + j
      ji = jof + i
      ik = iof + k
      ki = kof + i
      fij = isqoo(ij) + ifd4(ijsym)
      fji = isqoo(ji) + ifd4(ijsym)
      fik = isqoo(ik) + ifd4(iksym)
      fki = isqoo(ki) + ifd4(iksym)
      ijk = jofd + i
      ai = isqov((a-1)*no+i)
      aiqf = (ai-1)*npr(aisym,2,1) + iff2(aisym)
      aiqe = (ai-1)*npr(aisym,1,1) + ife2(aisym)
c
      do 90 f = ff1,lf1
      aibf = aiqf + itrsqv(bof+f)
      ckfj = fkj + (isqvv(cof+f)-1)*npr(jksym,1,2)
      t3(ijk) = t3(ijk) + fints(aibf)*t2(ckfj)
   90 continue
c 
      do 100 f = ff2,lf2
      bjaf = bjqf + itrsqv(aof+f)
      ckfi = fki + (isqvv(cof+f)-1)*npr(iksym,1,2)
      t3(ijk) = t3(ijk) + fints(bjaf)*t2(ckfi)
  100 continue
c
      do 110 f = ff3,lf3
      ckbf = ckqf + itrsqv(bof+f)
      aifj = fij + (isqvv(aof+f)-1)*npr(ijsym,1,2)
      t3(ijk) = t3(ijk) + fints(ckbf)*t2(aifj)
  110 continue
c
      do 120 f = ff4,lf4
      ckaf = ckqf + itrsqv(aof+f)
      bjfi = fji + (isqvv(bof+f)-1)*npr(ijsym,1,2)
      t3(ijk) = t3(ijk) + fints(ckaf)*t2(bjfi)
  120 continue
c
      do 130 f = ff5,lf5
      bjcf = bjqf + itrsqv(cof+f)
      aifk = fik + (isqvv(aof+f)-1)*npr(iksym,1,2)
      t3(ijk) = t3(ijk) + fints(bjcf)*t2(aifk)
  130 continue
c
      do 140 f = ff6,lf6
      aicf = aiqf + itrsqv(cof+f)
      bjfk = fjk + (isqvv(bof+f)-1)*npr(jksym,1,2)
      t3(ijk) = t3(ijk) + fints(aicf)*t2(bjfk)
  140 continue
c
      do 150 m = fm1,lm1
      aimj = aiqe + itrsqo(jof+m)
      bmck = isqoo((m-1)*no+k) + ebc
      t3(ijk) = t3(ijk) - eints(aimj)*t2(bmck)
  150 continue
c
      do 160 m = fm2,lm2
      bjmi = bjqe + itrsqo(iof+m)
      amck = isqoo((m-1)*no+k) + eac
      t3(ijk) = t3(ijk) - eints(bjmi)*t2(amck)
  160 continue
c
      do 170 m = fm3,lm3
      ckmj = ckqe + itrsqo(jof+m)
      bmai = isqoo((i-1)*no+m) + eab
      t3(ijk) = t3(ijk) - eints(ckmj)*t2(bmai)
  170 continue
c
      do 180 m = fm4,lm4
      ckmi = ckqe + itrsqo(iof+m)
      ambj = isqoo((m-1)*no+j) + eab
      t3(ijk) = t3(ijk) - eints(ckmi)*t2(ambj)
  180 continue
c
      do 190 m = fm5,lm5
      bjmk = bjqe + itrsqo(kof+m)
      cmai = isqoo((i-1)*no+m) + eac
      t3(ijk) = t3(ijk) - eints(bjmk)*t2(cmai)
  190 continue
c
      do 200 m = fm6,lm6
      aimk = aiqe + itrsqo(kof+m)
      cmbj = isqoo((j-1)*no+m) + ebc
      t3(ijk) = t3(ijk) - eints(aimk)*t2(cmbj)
  200 continue
c
   81 continue
   80 continue
   70 continue
   60 continue
   50 continue
   40 continue
c
      abof = ifd2(absym) + (itriv((a-1)*a/2+b)-1)*npr(absym,1,2)
      acof = ifd2(acsym) + (itriv((a-1)*a/2+c)-1)*npr(acsym,1,2)
      bcof = ifd2(bcsym) + (itriv((b-1)*b/2+c)-1)*npr(bcsym,1,2)
c
      do 210 ksym = 1,nirred
      ijsym = IXOR32(ksym-1,abcsm-1) + 1
      fk = flov(ksym,1)
      lk = flov(ksym,2)
c
      fka = a0
      if(ksym.eq.asym) fka = a1
      fkb = a0
      if(ksym.eq.bsym) fkb = a1
      fkc = a0
      if(ksym.eq.csym) fkc = a1
c
      do 220 jsym = 1,nirred
      isym = IXOR32(jsym-1,ijsym-1) + 1
c
      fia = a0
      if(isym.eq.asym) fia = a1
      fib = a0
      if(isym.eq.bsym) fib = a1
      fic = a0
      if(isym.eq.csym) fic = a1
      fja = a0
      if(jsym.eq.asym) fja = a1
      fjb = a0
      if(jsym.eq.bsym) fjb = a1
      fjc = a0
      if(jsym.eq.csym) fjc = a1
c
      fj = flov(jsym,1)
      lj = flov(jsym,2)
      fi = flov(isym,1)
      li = flov(isym,2)
      do 230 k = fk,lk
      koft = (k-1)*nsqoo
      kofd = (k-1)*no
      d4 = d3 + e(k)
c
      t1ka = fka*t1(isqov((a-1)*no+k))
      t1kb = fkb*t1(isqov((b-1)*no+k))
      t1kc = fkc*t1(isqov((c-1)*no+k))
c
      do 240 j = fj,lj
      joft = (j-1)*nsqoo
      jofd = (j-1)*no
      d5 = d4 + e(j)
c
      t1ja = fja*t1(isqov((a-1)*no+j))
      t1jb = fjb*t1(isqov((b-1)*no+j))
      t1jc = fjc*t1(isqov((c-1)*no+j))
      abjk = abof + isqoo((j-1)*no+k)
      acjk = acof + isqoo((j-1)*no+k)
      bcjk = bcof + isqoo((j-1)*no+k)
      abkj = abof + isqoo((k-1)*no+j)
      ackj = acof + isqoo((k-1)*no+j)
      bckj = bcof + isqoo((k-1)*no+j)
c
      do 250 i = fi,li
      if(i.eq.j.and.j.eq.k) go to 251
      ioft = (i-1)*nsqoo
      iofd = (i-1)*no
c
      t1ia = fia*t1(isqov((a-1)*no+i))
      t1ib = fib*t1(isqov((b-1)*no+i))
      t1ic = fic*t1(isqov((c-1)*no+i))
      abij = abof + isqoo((i-1)*no+j)
      acij = acof + isqoo((i-1)*no+j)
      bcij = bcof + isqoo((i-1)*no+j)
      abji = abof + isqoo((j-1)*no+i)
      acji = acof + isqoo((j-1)*no+i)
      bcji = bcof + isqoo((j-1)*no+i)
      abik = abof + isqoo((i-1)*no+k)
      acik = acof + isqoo((i-1)*no+k)
      bcik = bcof + isqoo((i-1)*no+k)
      abki = abof + isqoo((k-1)*no+i)
      acki = acof + isqoo((k-1)*no+i)
      bcki = bcof + isqoo((k-1)*no+i)
c
      ijk = i + jofd + koft
      ikj = i + kofd + joft
      jik = j + iofd + koft
      jki = j + kofd + ioft
      kij = k + iofd + joft
      kji = k + jofd + ioft
c
      fac = a1/(d5+e(i))
c
c  a > b > c
c
      e1 = e1 + t3(ijk)*(a4*t3(ijk)+t3(kij)+t3(jki)
     1        - a4*t3(kji)-t3(jik)-t3(ikj))*fac
      e11 = e11 + (t1ia*dints(bcjk)+t1jb*dints(acik)+t1kc*dints(abij))*
     1      (a4*t3(ijk)+t3(kij)+t3(jki)-a4*t3(kji)-t3(jik)-t3(ikj))*fac
c
c  b > a > c
c
      e2 = e2 + t3(jik)*(a4*t3(jik)+t3(ikj)+t3(kji)
     1        - a4*t3(jki)-t3(ijk)-t3(kij))*fac
      e22 = e22 + (t1ja*dints(bcik)+t1ib*dints(acjk)+t1kc*dints(abji))*
     1      (a4*t3(jik)+t3(ikj)+t3(kji)-a4*t3(jki)-t3(ijk)-t3(kij))*fac
c
c  c > b > a
c       
      e3 = e3 + t3(kji)*(a4*t3(kji)+t3(jik)+t3(ikj)
     1        - a4*t3(ijk)-t3(kij)-t3(jki))*fac
      e33 = e33 + (t1ka*dints(bcji)+t1jb*dints(acki)+t1ic*dints(abkj))*
     1      (a4*t3(kji)+t3(jik)+t3(ikj)-a4*t3(ijk)-t3(kij)-t3(jki))*fac
c
c  a > c > b
c
      e4 = e4 + t3(ikj)*(a4*t3(ikj)+t3(kji)+t3(jik)
     1        - a4*t3(kij)-t3(jki)-t3(ijk))*fac
      e44 = e44 + (t1ia*dints(bckj)+t1kb*dints(acij)+t1jc*dints(abik))*
     1      (a4*t3(ikj)+t3(kji)+t3(jik)-a4*t3(kij)-t3(jki)-t3(ijk))*fac
c
c  c > a > b
c
      e5 = e5 + t3(kij)*(a4*t3(kij)+t3(jki)+t3(ijk)
     1        - a4*t3(ikj)-t3(kji)-t3(jik))*fac
      e55 = e55 + (t1ka*dints(bcij)+t1ib*dints(ackj)+t1jc*dints(abki))*
     1      (a4*t3(kij)+t3(jki)+t3(ijk)-a4*t3(ikj)-t3(kji)-t3(jik))*fac
c
c  b > c > a
c
      e6 = e6 + t3(jki)*(a4*t3(jki)+t3(ijk)+t3(kij)
     1        - a4*t3(jik)-t3(ikj)-t3(kji))*fac
      e66 = e66 + (t1ja*dints(bcki)+t1kb*dints(acji)+t1ic*dints(abjk))*
     1      (a4*t3(jki)+t3(ijk)+t3(kij)-a4*t3(jik)-t3(ikj)-t3(kji))*fac
c
  251 continue
  250 continue
  240 continue
  230 continue
  220 continue
  210 continue
c
      if(a.eq.b.or.b.eq.c) then
      emp4t = emp4t + e1 + e3
      emp4x = emp4x + e11 + e33
      else 
      emp4t = emp4t + e1 + e2 + e3 + e4 + e5 + e6
      emp4x = emp4x + e11 + e22 + e33 + e44 + e55 + e66
      end if
c
   31 continue
   30 continue
   20 continue
   10 continue
c
c
      emp4t = emp4t/a3
      emp4x = emp4x/a3
      write(*,1) emp4t
      if(iopt.eq.6) then
      write(*,2) (emp4x+emp4x)
      else
      write(*,2) emp4x
      end if
      write(*,3) (eccsd+emp4t)
      if(iopt.eq.6) then
      write(*,5) (eccsd+emp4t+emp4x+emp4x)
      else
      write(*,4) (eccsd+emp4t+emp4x)
      end if
   1  format(/  ,2x,'triples : mp4(t) =  ',f25.15)
   2  format(    2x,'triples : mp5(t) =  ',f25.15)
   3  format(// ,2x,'ccsd+t   energy  =  ',f25.15)
   4  format(    2x,'ccsd(t)  energy  =  ',f25.15,//)
   5  format(    2x,'qcisd(t) energy  =  ',f25.15,//)
c
      print *,' end of subroutine trps'
c
      return
      end
      subroutine vccsd(cc,ic,lscr,iconvi,imaxit,iopt,escf)
      implicit integer (a-z)
      REAL cc(lscr),escf
      integer ic(*),iconvi,imaxit,iopt
c      equivalence (cc(1),ic(1))
c
c    *******************************************************************
c    *******************************************************************
c    *  the closed-shell coupled cluster singles and doubles program   *
c    *                            written by                           *
c    *      timothy j. lee, julia e. rice and alistair p. rendell      *
c    *******************************************************************
c    *******************************************************************
c    *                                                                 *
c    *  publications reporting results obtained with this program      *
c    *  should reference the titan set of electronic structure         *
c    *  programs written by t. j. lee, a. p. rendell and j. e. rice.   *
c    *                                                                 *
c    *  formulae on which this program is based are presented in :     *
c    * 1) t. j. lee and j. e. rice, cpl vol. 150, 406 (1988),          *
c    * 2) g. e. scuseria, a. c. scheiner, t. j. lee, j. e. rice and    *
c    *    h. f. schaefer, jcp vol. 86, 2881 (1987), and                *
c    * 3) t. j. lee, a. p. rendell and p. r. taylor,                   *
c    *    jpc vol. 94, 5463 (1990).                                    *
c    * 4) a. p. rendell, t. j. lee and a. komornicki, cpl, in press.   *
c    * 5) t. j. lee and a. p. rendell, jcp, in press.                  *
c    *                                                                 *
c    *  1) and 2) contain equations for the ccsd amplitudes and energy;*
c    *  3) and 4) contain equations for the perturbational estimate of *
c    *     connected triple excitations [i.e., (t)];                   *
c    *  5) contains equations for the additional quantities which must *
c    *     be evaluated for the (t) gradient.                          *
c    *******************************************************************
c    *******************************************************************
c    ***** last update :  february 1991 by tjl                     *****
c    *******************************************************************
c    *******************************************************************
c
c *--------------------------------------------------------------------*
c |   this version works with cctrans and sortcc.                      |
c |   two electron integrals are paged and each term in the t2 and t1  |
c |   equations is vectorized and symmetry adapted.                    |
c |   t2 and t1 are symmetry packed.                                   |
c |   diis out of core version.                                        |
c |   options for 'ccsd', 'ccd ', 'cct ', 'qci', 'qcit', 'mp4t' and    |
c |   'cctg' are implemented.                                          |
c *--------------------------------------------------------------------*
c
      logical iprint
INCLUDE(common/t_files)
      common/t_memsav/ maxmem,maxblnk,maxuse,iprint
c
      iprint=.false.
      maxcor = lscr
c
      in = 5
      iw = 6
      itap57 = 57
      itap60 = 60
      itap61 = 61
      itap62 = 62
      itap63 = 66
      itap64 = 64
      itap65 = 65
      itap69 = 69
      itap90 = 90
      itap98 = 91
      itap99 = 92
c
      call ccdrv(cc,ic,maxcor,iconvi,imaxit,iopt,escf)
c
      return
      end
      function vget(i,j,k,a,b,c)
      implicit integer (a-z)
      REAL vget,tst1,intget,t1get
INCLUDE(common/t_parm)
INCLUDE(common/t_int)
      tst1=0.0d00
      tst1=tst1+intget(i,a,j,b)*t1get(k,c)
      tst1=tst1+intget(i,a,k,c)*t1get(j,b)
      tst1=tst1+intget(j,b,k,c)*t1get(i,a)
      vget=tst1
      return
      end
      function wget(i,j,k,a,b,c)
      implicit integer (a-z)
      REAL wget
INCLUDE(common/t_parm)
INCLUDE(common/t_int)
c
      ia=(i-1)*nv+a-no
      jb=(j-1)*nv+b-no
      kc=(k-1)*nv+c-no
      mx1=max(ia,jb)
      mn1=min(ia,jb)
      iaa=max(mx1,kc)
      mn2=min(mx1,kc)
      jbb=max(mn1,mn2)
      kcc=min(mn1,mn2)
      idx=fmat+(iaa+1)*iaa*(iaa-1)/6+jbb*(jbb-1)/2+kcc-1
      wget=scr(idx)
      return
      end
       subroutine wtgt(delt)
       REAL tcpu,tsys,telp
       REAL tstrt,tx,delt
_IF1()       REAL eetime
_IF1()       real*4 temp(2)
_IF1()       real*4 dtime
       common/t_wtime/tstrt
       call cputimer(tcpu,tsys,telp)
       tx=tcpu+tsys
       delt=delt+tx-tstrt
       return
       end
       subroutine wtst
       REAL tcpu,tsys,telp
       REAL tstrt
_IF1()       REAL eetime
_IF1()       real*4 temp(2),dtime
       common/t_wtime/tstrt
       call cputimer(tcpu,tsys,telp)
       tstrt=tcpu+tsys
       return
       end
      subroutine ver_nvccsd(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/nvccsd.m,v $
     +     "/
      data revision /"$Revision: 5774 $"/
      data date /"$Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
_ENDEXTRACT
