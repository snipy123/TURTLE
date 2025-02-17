c***./ add name=auxg
      subroutine auxg_crys(scale)
      implicit REAL (a-h,o-z)
      dimension scale(*)
      common/tabaux/t(14014)
      common/pqcon/pq(3),blphax,a,b,f(190),amp1,
     *mmaxm1,mmax,mmaxp1,mxabne,
     *gap,gapinv,range,c6,c2p5,c3,cp75,pid4,pid2,
     *pixy,pixy2,aln(3),gz(191)
      af=a+a
cc
c     write(6,*) 'in auxg'
c     do i=1,14014
c       write(6,*) 't:',t(i)
c     enddo
c     write(6,*) 'pq:',pq(1),pq(2),pq(3)
c     write(6,*) 'blphax a b:',blphax,a,b
c     write(6,*) mmaxm1,mmax,mmaxp1,mxabne
c     write(6,*) gap,gapinv,range,c6,c2p5,c3,cp75,pid4,pid2
c     write(6,*) pixy,pixy2,aln(1),aln(2),aln(3)
c     stop
cc 
      if(a.lt.range)then
c... small argument - cubic interpolation
        i=nint(a*gapinv)
        ai=gap*i-a
        i=mxabne+i
        fmmax=((t(i+3003)*c6*ai+t(i+2002)*0.5d0)*ai+t(i+1001))*ai+t(i)
c... recursion down
        if(mmaxm1.ne.0)then
          expw=exp(-a)
          do 1 l=mmaxm1,1,-1
            f(l+1)=fmmax*scale(l+1)
1         fmmax=(fmmax*af+expw)*gz(l)
        endif
        f(1)=fmmax*scale(1)
      else
c... large argument - asymptotic formula corrected by 1/2 pade approx.
        ai=1.d0/af
        fmmax=sqrt(pid2*ai)
        af=ai+ai
        if(a.lt.amp1)then
          expw=exp(-a)*ai
          fmmax=fmmax-((a+c2p5)*expw/(cp75*ai+a+c3))
c... recursion up
          do 2 l=1,mmaxm1
            f(l)=fmmax*scale(l)
            fmmax=fmmax*ai-expw
2         ai=ai+af
        else
c... very large argument - asymptotic formula
          do 3 l=1,mmaxm1
            f(l)=fmmax*scale(l)
            fmmax=fmmax*ai
3         ai=ai+af
        endif
        f(mmax)=fmmax*scale(mmax)
      endif
      return
      end
c***./ add name=basprt
      subroutine basprt
      implicit REAL (a-h,o-z)
      logical iprat
      character*4 ndn(4)
      common/diagvr/iprat(0:399)
INCLUDE(common/crys_params.hf77)
      common/basato/
     * aznuc(lim016),xa(3,lim016),
     * che(lim015),exad(lim015+1),xl(3,lim015),
     * exx(lim042),c1(lim042),c2(lim042),c3(lim042),
     * cmax(lim042),c2w(lim042),c3w(lim042),
     * nat(lim016),nshpri(lim016+1),ipseud(lim016),
     * laa(lim015+1),lan(lim015),lat(lim015),latao(lim015),
     * ndq(lim015+1),latoat(lim015)
      parameter (limpar=50,limprn=200,limftn=100,limtol=50,liminf=200)
      common/parinf/par(limpar),lprint(limprn),iunit(limftn),
     *itol(limtol),inf(liminf),itit(20),iin,iout
      character*2 symbat(0:92)
      data symbat/   'xx','h ','he','li','be','b ','c ','n ',
     1'o ','f ','ne','na','mg','al','si','p ','s ','cl','ar',
     2'k ','ca','sc','ti','v ','cr','mn','fe','co','ni','cu',
     3'zn','ga','ge','as','se','br','kr','rb','sr','y ','zr',
     4'nb','mo','tc','ru','rh','pd','ag','cd','in','sn','sb',
     5'te','i ','xe','cs','ba','la','ce','pr','nd','pm','sm',
     6'eu','gd','tb','dy','ho','er','tm','yb','lu','hf','ta',
     7'w ','re','os','ir','pt','au','hg','tl','pb','bi','po',
     8'at','rn','fr','ra','ac','th','pa','u '/
      data ndn/' s',' sp',' p',' d'/
      do 20 i=0,399
20    iprat(i)=.false.
      write(iout,1070)
      do 430  na=1,inf(24)
      iam=nat(na)
      ia=mod(iam,100)
      write(iout,1080)na,symbat(ia),(xa(k,na),k=1,3)
      if(iprat(iam))goto 430
      iprat(iam)=.true.
      do 420 i=nshpri(na),nshpri(na+1)-1
      lati=lat(i)+1
      k=ndq(i)+1
      if(lati.eq.1)then
      write(iout,1090)k,ndn(lati)
      else
      write(iout,1100)k,ndq(i+1),ndn(lati)
      endif
      do 420 k=laa(i),laa(i+1)-1
420   write(iout,1120)exx(k),c1(k),c2(k),c3(k)
430   continue
      return
1080  format(i4,1x,a,3f7.3)
1070  format(1x,79('*')/
     *'   atom  x(au)  y(au)  z(au)    no. type  exponent',
     *'    s coef     p coef   d coef'/1x,79('*'))
1090  format(31x,i4,a)
1100  format(26x,i4,'-',i4,a)
1120  format(40x,4(1pe10.3))
      end
c***./ add name=buxtab
      subroutine buxtab(mxabcd,ggap,rrange)
      implicit REAL (a-h,o-z)

      common/tabaux/t(14014)

      common/pqcon/pq(3),blphax,ttt4,hhh4,f(190),amp1,
     *mmaxm1,mmax,mmaxp1,mxabne,
     *gap,gapinv,range,c6,c2p5,c3,cp75,pid4,pid2,
     *pixy,pixy2,aln(3),gz(191),pha(50)

      common/servi/vexpv(1001),dd(1001)

      amp1=24.d0
      gap=ggap
      gapinv=1.d0/gap
      range=rrange
      pid2=acos(0.d0)
      pid4=pid2*0.5d0
      c6=1.d0/6.d0
      cp75=(range+2.5d0)*1.5d0/(range+4.5d0)
      c2p5=cp75+1.d0
      c3=cp75+1.5d0
      ibase=mxabcd*1001
      m=mxabcd+100
      bilbo=gz(m+1)
      do 1000 loop=1,1001
      frodo=(loop-1)*gap
      vexpv(loop)=exp(-frodo)
      dd(loop)=frodo+frodo
1000  t(ibase+loop)=dd(loop)*bilbo
c... recur down from mxabcd+100 to mxabcd
3      bilbo=gz(m)
      do 1001 loop=1,1001
1001  t(ibase+loop)=(t(ibase+loop)*dd(loop)+vexpv(loop))*bilbo
      m=m-1
      if(m.ne.mxabcd)goto 3
c... mxabcd-1 to zero
6     jbase=ibase-1001
      bilbo=gz(m)
      do 1002 loop=1,1001
1002  t(jbase+loop)=(t(ibase+loop)*dd(loop)+vexpv(loop))*bilbo
      ibase=jbase
      m=m-1
      if(m)6,5,6
5     return
      end
c***./ add name=classs
      subroutine classs(inzila,n1,inzilb,n2)
      implicit REAL (a-h,o-z)
      dimension inzila(*),inzilb(*)
INCLUDE(common/crys_params.hf77)
      parameter (limpar=50,limprn=200,limftn=100,limtol=50,liminf=200)
      common/parinf/par(limpar),lprint(limprn),iunit(limftn),
     *itol(limtol),inf(liminf),itit(20),iin,iout
      common/basato/
     * aznuc(lim016),xa(3,lim016),
     * che(lim015),exad(lim015+1),xl(3,lim015),
     * exx(lim042),c1(lim042),c2(lim042),c3(lim042),
     * cmax(lim042),c2w(lim042),c3w(lim042),
     * nat(lim016),nshpri(lim016+1),ipseud(lim016),
     * laa(lim015+1),lan(lim015),lat(lim015),latao(lim015),
     * ndq(lim015+1),latoat(lim015)
      common/gvect/paret(3,3),w1r(3,3),
     *  gmodus(lim007+1),xg(3,lim006),
     *  nm(lim007+1),mn(lim007+1),nn1(lim006),lg(3,lim006)
      common/basold/parold(3,3),
     *trasvo(3,48),exaold(lim015),xold(3,lim016),xlold(3,lim015),
     *hmodus(lim007+1),xgold(3,lim006),scost(lim015,lim015)
      logical lexc13,lexc14
      common/claddd/t6,bccfak,cccfak,ttttt2,adipex,
     * pinf44,pinf45,t7co,t7ex,adicou,accfaj,cccfaj,accfak,
     * xpold,ypold,zpold,
     * x1old,y1old,z1old,x2old,y2old,z2old,ex1old,ex2old,
     * ex3old,ex4old,f12old,rsqold,x9old,y9old,z9old,
     * dddddd,fa2old,fatold,f13old,f14old,f23old,f24old,
     * g13old,g14old,g23old,g24old,g1324o,g1423o,sig12,sx12,
     * b24old,b23old,sx1324,sx1423,t8ex,t8ex44,u8ex,u8ex44,
     * x21old,y21old,z21old,x31old,y31old,z31old,
     * x6old,y6old,z6old,x41old,y41old,z41old,
     * x32old,y32old,z32old,x31ols,y31ols,z31ols,
     * x41ols,y41ols,z41ols,fa2new,g13new,g24new,g1324n,
     * g14new,g23new,g1423n,x31nes,y31nes,z31nes,
     * x41nes,y41nes,z41nes,ex3new,ex4new,
     * x1new,y1new,z1new,x2new,y2new,z2new,ex1new,ex2new,
     * idipex,idicou,icame,jcame,nsh13,nsh14,nnllll,lwri4x,
     * nciclx,igp1,igp2,igp3,ig1,ig2,ig3,lexc13,lexc14
c
c    selection of coulomb integrals
c
      rsqold=x21old*x21old+y21old*y21old+z21old*z21old
      xx=fatold*rsqold+ttttt2
      yy=1d-4-rsqold
      xpold=x21old*fa2old
      ypold=y21old*fa2old
      zpold=z21old*fa2old
      x8=xpold+x1old
      y8=ypold+y1old
      z8=zpold+z1old
      n1=0
      n2=0
      do 291 na=1,inf(24)
        x9=xa(1,na)-x8
        y9=xa(2,na)-y8
        z9=xa(3,na)-z8
        zz=x9*x9+y9*y9+z9*z9
        zz4=zz*4.d0
        do 291 j=nshpri(na),nshpri(na+1)-1
          ex8=exad(j)
          ex9=1.d0/(ex8+dddddd)
          fat1=ex8*dddddd*ex9
          vsq=max((0.75d0*log(fat1*ex9)-xx)/fat1,yy)
c         if(vsq.lt.(0.d0))goto 291
c         write(6,*) 'vsq:',j,vsq,ex8,fa2old,fatold,rsqold
          if((vsq.lt.0.d0).or.(zz.gt.vsq)) then
            n1=n1+1
c291   inzila(j+1)=n1
            inzila(n1)=j
          else
            n2=n2+1
            inzilb(n2)=j
          endif
291   continue      
      return
      end
c***./ add name=cjat
      subroutine cjat(aintn,aint4,maxp,idipp1)
      implicit REAL (a-h,o-z)
      dimension aintn(*),aint4(*),ipower(7)
      common/icon/iky(50),miky(50)
      common/moncon/apole(200),ipole(200),jpole(200),
     *kpole(200),mpole(50),bilb(25),frod(25)
      data ipower/1,4,9,16,25,36,49/
c....   field integrals over poles
      nmaxp=miky(maxp+1)
      mma=0
      ibas=0
      do 16367 i=1,ipower(idipp1)
      do 16366 nu=1,mpole(i)
      mma=mma+1
      ipol=idipp1-ipole(mma)
      jpol=idipp1-jpole(mma)
      kpol=idipp1-kpole(mma)
      bilbo=apole(mma)
      ikyjp0=iky(jpol)
      if(nu.eq.1)goto 999
      aintn(ibas+1)=aint4(miky(ipol)+ikyjp0+kpol)*bilbo
     * +aintn(ibas+1)
      if(maxp.eq.1)goto 16366
      mubas=miky(ipol+1)+kpol
      ikyjp1=iky(jpol+1)
      nubas=mubas+ikyjp1
      aintn(ibas+2)=aint4(ikyjp0+mubas)*bilbo+aintn(ibas+2)
      aintn(ibas+3)=aint4(nubas)*bilbo+aintn(ibas+3)
      aintn(ibas+4)=aint4(nubas+1)*bilbo+aintn(ibas+4)
      if(maxp.eq.2)goto 16366
      mubas=miky(ipol+2)+kpol
      ikyjp2=iky(jpol+2)
      nubas=mubas+ikyjp1
      aintn(ibas+5)=aint4(ikyjp0+mubas)*bilbo+aintn(ibas+5)
      aintn(ibas+6)=aint4(nubas)*bilbo+aintn(ibas+6)
      aintn(ibas+7)=aint4(nubas+1)*bilbo+aintn(ibas+7)
      nubas=mubas+ikyjp2
      aintn(ibas+8)=aint4(nubas)*bilbo+aintn(ibas+8)
      aintn(ibas+9)=aint4(nubas+1)*bilbo+aintn(ibas+9)
      aintn(ibas+10)=aint4(nubas+2)*bilbo+aintn(ibas+10)
      if(maxp.eq.3)goto 16366
      mubas=miky(ipol+3)+kpol
      ikyjp3=iky(jpol+3)
      nubas=mubas+ikyjp1
      aintn(ibas+11)=aint4(ikyjp0+mubas)*bilbo+aintn(ibas+11)
      aintn(ibas+12)=aint4(nubas)*bilbo+aintn(ibas+12)
      aintn(ibas+13)=aint4(nubas+1)*bilbo+aintn(ibas+13)
      nubas=mubas+ikyjp2
      aintn(ibas+14)=aint4(nubas)*bilbo+aintn(ibas+14)
      aintn(ibas+15)=aint4(nubas+1)*bilbo+aintn(ibas+15)
      aintn(ibas+16)=aint4(nubas+2)*bilbo+aintn(ibas+16)
      nubas=mubas+ikyjp3
      aintn(ibas+17)=aint4(nubas)*bilbo+aintn(ibas+17)
      aintn(ibas+18)=aint4(nubas+1)*bilbo+aintn(ibas+18)
      aintn(ibas+19)=aint4(nubas+2)*bilbo+aintn(ibas+19)
      aintn(ibas+20)=aint4(nubas+3)*bilbo+aintn(ibas+20)
      if(maxp.eq.4)goto 16366
      mubas=miky(ipol+4)+kpol
      nubas=mubas+ikyjp1
      aintn(ibas+21)=aint4(ikyjp0+mubas)*bilbo+aintn(ibas+21)
      aintn(ibas+22)=aint4(nubas)*bilbo+aintn(ibas+22)
      aintn(ibas+23)=aint4(nubas+1)*bilbo+aintn(ibas+23)
      nubas=mubas+ikyjp2
      aintn(ibas+24)=aint4(nubas)*bilbo+aintn(ibas+24)
      aintn(ibas+25)=aint4(nubas+1)*bilbo+aintn(ibas+25)
      aintn(ibas+26)=aint4(nubas+2)*bilbo+aintn(ibas+26)
      nubas=mubas+ikyjp3
      aintn(ibas+27)=aint4(nubas)*bilbo+aintn(ibas+27)
      aintn(ibas+28)=aint4(nubas+1)*bilbo+aintn(ibas+28)
      aintn(ibas+29)=aint4(nubas+2)*bilbo+aintn(ibas+29)
      aintn(ibas+30)=aint4(nubas+3)*bilbo+aintn(ibas+30)
      nubas=iky(jpol+4)+mubas
      aintn(ibas+31)=aint4(nubas)*bilbo+aintn(ibas+31)
      aintn(ibas+32)=aint4(nubas+1)*bilbo+aintn(ibas+32)
      aintn(ibas+33)=aint4(nubas+2)*bilbo+aintn(ibas+33)
      aintn(ibas+34)=aint4(nubas+3)*bilbo+aintn(ibas+34)
      aintn(ibas+35)=aint4(nubas+4)*bilbo+aintn(ibas+35)
      goto 16366
999   aintn(ibas+1)=aint4(miky(ipol)+ikyjp0+kpol)*bilbo
      if(maxp.eq.1)goto 16366
      mubas=miky(ipol+1)+kpol
      ikyjp1=iky(jpol+1)
      nubas=mubas+ikyjp1
      aintn(ibas+2)=aint4(ikyjp0+mubas)*bilbo
      aintn(ibas+3)=aint4(nubas)*bilbo
      aintn(ibas+4)=aint4(nubas+1)*bilbo
      if(maxp.eq.2)goto 16366
      mubas=miky(ipol+2)+kpol
      ikyjp2=iky(jpol+2)
      nubas=mubas+ikyjp1
      aintn(ibas+5)=aint4(ikyjp0+mubas)*bilbo
      aintn(ibas+6)=aint4(nubas)*bilbo
      aintn(ibas+7)=aint4(nubas+1)*bilbo
      nubas=mubas+ikyjp2
      aintn(ibas+8)=aint4(nubas)*bilbo
      aintn(ibas+9)=aint4(nubas+1)*bilbo
      aintn(ibas+10)=aint4(nubas+2)*bilbo
      if(maxp.eq.3)goto 16366
      mubas=miky(ipol+3)+kpol
      ikyjp3=iky(jpol+3)
      nubas=mubas+ikyjp1
      aintn(ibas+11)=aint4(ikyjp0+mubas)*bilbo
      aintn(ibas+12)=aint4(nubas)*bilbo
      aintn(ibas+13)=aint4(nubas+1)*bilbo
      nubas=mubas+ikyjp2
      aintn(ibas+14)=aint4(nubas)*bilbo
      aintn(ibas+15)=aint4(nubas+1)*bilbo
      aintn(ibas+16)=aint4(nubas+2)*bilbo
      nubas=mubas+ikyjp3
      aintn(ibas+17)=aint4(nubas)*bilbo
      aintn(ibas+18)=aint4(nubas+1)*bilbo
      aintn(ibas+19)=aint4(nubas+2)*bilbo
      aintn(ibas+20)=aint4(nubas+3)*bilbo
      if(maxp.eq.4)goto 16366
      mubas=miky(ipol+4)+kpol
      nubas=mubas+ikyjp1
      aintn(ibas+21)=aint4(ikyjp0+mubas)*bilbo
      aintn(ibas+22)=aint4(nubas)*bilbo
      aintn(ibas+23)=aint4(nubas+1)*bilbo
      nubas=mubas+ikyjp2
      aintn(ibas+24)=aint4(nubas)*bilbo
      aintn(ibas+25)=aint4(nubas+1)*bilbo
      aintn(ibas+26)=aint4(nubas+2)*bilbo
      nubas=mubas+ikyjp3
      aintn(ibas+27)=aint4(nubas)*bilbo
      aintn(ibas+28)=aint4(nubas+1)*bilbo
      aintn(ibas+29)=aint4(nubas+2)*bilbo
      aintn(ibas+30)=aint4(nubas+3)*bilbo
      nubas=iky(jpol+4)+mubas
      aintn(ibas+31)=aint4(nubas)*bilbo
      aintn(ibas+32)=aint4(nubas+1)*bilbo
      aintn(ibas+33)=aint4(nubas+2)*bilbo
      aintn(ibas+34)=aint4(nubas+3)*bilbo
      aintn(ibas+35)=aint4(nubas+4)*bilbo
16366 continue
16367 ibas=ibas+nmaxp
      return
      end
c***./ add name=cjat0
      subroutine cjat0(l1,l2,idipo,bfp_num,q1,x1old,y1old,z1old,g1,cj)
      implicit REAL (a-h,o-z)
      dimension i5(4),itype(4)
      integer q1,bfp_num
      dimension cj(1225),g1(3)

INCLUDE(common/crys_params.hf77)
      logical lscree

      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree

      common/basato/
     * aznuc(lim016),xa(3,lim016),
     * che(lim015),exad(lim015+1),xl(3,lim015),
     * exx(lim042),c1(lim042),c2(lim042),c3(lim042),
     * cmax(lim042),c2w(lim042),c3w(lim042),
     * nat(lim016),nshpri(lim016+1),ipseud(lim016),
     * laa(lim015+1),lan(lim015),lat(lim015),latao(lim015),
     * ndq(lim015+1),latoat(lim015)

      parameter (limpar=50,limprn=200,limftn=100,limtol=50,liminf=200)

      common/parinf/par(limpar),lprint(limprn),iunit(limftn),
     *itol(limtol),inf(liminf),itit(20),iin,iout

      common/vrsmad/akx(11,300),aky(11,300),akz(11,300),
     1aksq(300),expsq(300),expgam(300),pvrs(3,3),pinv(3,3),r9,h9,
     3a5,gammam,gam2ng,gamsqr,gaminv,poiss,rpi,totchr,pixy3,pix4,pix2,
     4qoiss,a5inv,preuno,beta2,betsq2,ww,absw,zed,sgnz,beta4,betsqz,
     5u9,u94,nreal,nrecip,idim,ldim

      common/servi/p(3),ppqq(3),x1(3),x2(3),atz(25),otz(25),
c    *shift(25),s(1225),aintn(35*49),cj(1225*lim015),
     *shift(25),s(1225),aintn(35*49),dum(1225*lim015),
     *nsh(lim016),inoz(lim016),inzila(lim015+1),nn2(lim006),
     *ila(lim031),ilan(lim031),ilu(lim025)
c...
c... molecule case ---- vrs nov 1987
c...
      common/dfaccc/dfacc(6),tfac1(9)

      common/icon/iky(50),miky(50),itwo(32),ithe(32)

      common/pqcon/pq(3),blphax,ttt4,hhh4,f(190),amp1,
     *mmaxm1,mmax,nnaxp1,mxabne,
     *gap,gapinv,range,c6,c2p5,c3aux,cp75,pid4,pid2,
     *pixy,pixy2,aln(3),gz(191),pha(50)
      common/loco/cfac1(35*25),aint4(286),
     *aint3(286),appaqq(11),tfac2(25)

      data itype/1,2,2,3/
      data i5/0,0,1,4/
      idipp1=idipo+1
      npole=idipp1*idipp1
      mocf=bfp_num
      mocfn=mocf*npole
      lt1=latao(l1)
      lt2=latao(l2)
      l2pbas=laa(l2)
      l2pupp=laa(l2+1)-1
      itypea=lat(l1)
      i5b=i5(itypea+1)
      ixxx=lat(l2)+1
      maxpp1=itype(itypea+1)+itype(ixxx)
      itypea=i4base(itypea+1)+ixxx
      nmaxp=miky(maxpp1)
      maxp=maxpp1-1
      maxpm1=maxp-1
      maxpm2=maxpm1-1
      ixxx=-iky(maxpp1)
      if(maxpm2)10077,10077,10078
10078 itxxx=miky(maxpm1)-nmaxp
      ityyy=maxp+maxpm1
10077 mmaxm1=maxpm1+idipo
      mmax=mmaxm1+1
      mmaxp1=mmax+1
      nnax=miky(mmaxp1)
      mxabne=mmaxm1*1001+1
      appaqq(1)=pixy2
      do i=1,3
        x1(i)=g1(i)
      enddo
c============loop over primitives in shell 1=====
      do 10012 mprima=laa(l1),laa(l1+1)-1
c============loop over primitives in shell 2=====
      do 10012 mprimb=l2pbas,l2pupp
cc    write(6,*) 'new primitive'
c     call aclear_dp(cfac1,25*35,0.0d0)
      call dfac3(mprima,mprimb,x1,itypea,cfac1,p)
c     do i=1,mocf
c       write(6,*) 'cfac1:',cfac1(i),mocf,bfp_num
c     enddo
      if(lscree) goto 10012
c     write(6,*) 'not screened'
      bilbo=-alphap(1)-alphap(1)
      do 12220 loop=2,mmax
12220 appaqq(loop)=appaqq(loop-1)*bilbo

      pq(1)=p(1)-x1old
      pq(2)=p(2)-y1old
      pq(3)=p(3)-z1old
c     write(6,*) 'coords:',p(1),p(2),p(3),x1old,y1old,z1old
      ttt4=(pq(1)*pq(1)+pq(2)*pq(2)+pq(3)*pq(3))*alphap(1)
c     write(6,*) 'going to auxg'
      call auxg_crys(appaqq)
      call rcals(aint4)
      call cjat(aintn,aint4,maxp,idipp1)
      call mxmb_crys(aintn,nmaxp,1,cfac1,1,nmaxp,cj,mocf,1,
     *npole,nmaxp,mocf)
c     do i=1,50
c       write(6,*) 'iky and miky:',iky(i),miky(i)
c     enddo
c     do i=1,mmax
c       write(6,*) 'appaqq:',appaqq(i)
c     enddo
c     do i=1,190
c       write(6,*) 'f:',f(i)
c     enddo
c     if((l1.eq.2).and.(l2.eq.1)) then 
c     write(6,*) 'new'
c     do i=1,35*49
c       write(6,*) 'aintn:',aintn(i)
c     enddo
c     do i=1,236
c       write(6,*) 'aint4:',aint4(i)
c     enddo
c     stop 
c     write(6,*) 'new prim'
c     do i=1,mocfn
c       write(6,*) 'cj:',i,cj(i)
c     enddo
c     endif
10012 continue
c     stop
c     write(6,*) 'nmaxp:',nmaxp,maxp
      return
      end
c***./ add name=congen
      subroutine congen
      implicit REAL (a-h,o-z)

      logical lph,phavrs

      parameter (limpar=50,limprn=200,limftn=100,limtol=50,liminf=200)

      common/parinf/par(limpar),lprint(limprn),iunit(limftn),
     *itol(limtol),inf(liminf),itit(20),iin,iout

      common/dfaccc/dfacc(6),tfac1(9)

      common/tcomm/accfac,expacc,recpi

      common/pqcon/fille(197),mille(4),gille(9),
     *pi,pi2,aln(3),gz(191),pha(50),
     *factvs(35),coef4(10)

      common/icon/iky(50),miky(50),itwo(32),ithe(32)

      common/moncon/apole(200),ipole(200),jpole(200),
     *kpole(200),mpole(50),bilb(25),frod(25)

      logical lscree

      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree

      common/sphfac/fsph(200),nu3p(0:7),ietap(50),
     *net1(200),net2(200),net3(200)

      common/phalog/phavrs(50)

      common/loco/lpol,npo,
     *g(191),fact(13),facti(13)

      common/servi/alm1(21),alm2(21),
     *apol(28,13,2),ipol(28,13,2),jpol(28,13,2),
     *mpol(13,2)

c... routine to generate constants for use in basic integral
c... evaluation and overlap expansion
      i4base(1)=0
      i4base(2)=4
      i4base(3)=8
      i4base(4)=12
      dfacc(1)=1.d0
      pi=acos(0.d0)
      rpi=sqrt(0.5d0/pi)
      pi2=sqrt(rpi+rpi)
      recpi=1.d0/pi2
      itwo(1)=1
      ithe(1)=1
      do 45234 i=2,31
      itwo(i)=itwo(i-1)*2
45234 ithe(i)=itwo(i)+ithe(i-1)
      do 8 i=1,191
      g(i)=i+i-1
8     gz(i)=1.d0/g(i)
      do 88 i=1,10
88    coef4(i)=-g(i)
      do 9966 i=1,5
9966  dfacc(i+1)=dfacc(i)*g(i)
      m=0
      do 9988 i=1,3
      x=i+0.5d0
      l=i+i-1
_IF1(ct)cdir$ shortloop
      do 9988 j=1,l
      m=m+1
9988  tfac1(m)=x
      alphap(4)=sqrt(3.d0)
      aln(1)=(rpi**0.25d0)*2.d0
      aln(2)=aln(1)*2.d0
      aln(3)=aln(2)*2.d0/alphap(4)
      lph=.true.
      m=0
      l=0
      do 2 i=1,50
      iky(i)=m
      m=m+i
      phavrs(i)=lph
      lph=.not.lph
      miky(i)=l
2     l=l+m
      loop=0
      do 4 l=1,6
      zz=l
      yy=1.d0-zz
      x=zz-yy
      do 4 m=1,l
      loop=loop+1
      alm1(loop)=x/zz
      alm2(loop)=yy/zz
      yy=yy-1.d0
  4   zz=zz-1.d0
      fact(1)=1.d0
      do 5 l=2,13
      x=l-1
      fact(l)=fact(l-1)*x
5     facti(l)=1.d0/fact(l)
      loop=0
      do 55 i=1,5
      do 55 l=1,i
      x=fact(i-l+1)
      do 55 m=1,l
      loop=loop+1
55    factvs(loop)=fact(l-m+1)*fact(m)*x
      ietap(1)=0
c...
c...  constants for higher poles
c...
      do 7744 loop=1,4
      ietap(loop+1)=loop
      mpole(loop)=1
      mpol(loop,2)=1
      kpole(loop)=1
      net1(loop)=0
      net2(loop)=0
      ipol(1,loop,2)=0
      jpol(1,loop,2)=0
      ipole(loop)=0
      jpole(loop)=0
      fsph(loop)=1.d0
      apol(1,loop,2)=1.d0
7744  apole(loop)=-1.d0
      net1(3)=1
      net1(4)=1
      net2(4)=1
      x=-1.d0
      apole(1)=1.d0
      apol(1,1,1)=1.d0
      kpole(1)=0
      ipol(1,1,1)=0
      jpol(1,1,1)=0
      lmqu=0
      lpol=4
      lazy=4
      mpol(1,1)=1
      ipol(1,2,2)=1
      jpol(1,2,2)=1
      jpol(1,3,2)=1
      ipole(3)=1
      jpole(3)=1
      jpole(4)=1
      lorder=1
      iold=1
      inew=2
      do 7755 l=2,6
      tfac=l
      ufac=tfac
      xx=tfac+tfac-1.d0
      x=-x/xx
      sfac=1.d0
      yy=x
      mm=1
c...  m . lt . l  cases
      do 7733 m=1,l
      xfac=yy*fact(l-m+2)*facti(l+m)
      lorder=lorder+1
      lmqu=lmqu+1
      bilbo=alm1(lorder)
      frodo=alm2(lorder)
      bilb(lmqu)=bilbo
      frod(lmqu)=frodo
      do 7700 mmm=1,2
      npo=0
      if(m.ne.l)then
      do 7756 loop=1,mpol(mm,iold)
      zz=apol(loop,mm,iold)*frodo
      i=ipol(loop,mm,iold)
      j=jpol(loop,mm,iold)
      call convrs(i+2,j+2,zz)
      call convrs(i,j+2,zz)
7756  call convrs(i,j,zz)
      endif
      do 7757 loop=1,mpol(mm,inew)
7757  call convrs(ipol(loop,mm,inew),jpol(loop,mm,inew),
     *apol(loop,mm,inew)*bilbo)
      lazy=lazy+1
      mpole(lazy)=npo
      mpol(mm,iold)=npo
      vfac=sqrt(1.d0/sfac)
      do 7758 loop=1,npo
      lpol=lpol+1
      kpole(lpol)=l
      net1(lpol)=l-ipole(lpol)
      net2(lpol)=l-jpole(lpol)
      ipol(loop,mm,iold)=ipole(lpol)
      jpol(loop,mm,iold)=jpole(lpol)
      apol(loop,mm,iold)=apole(lpol)
      fsph(lpol)=apole(lpol)*vfac
7758  apole(lpol)=apole(lpol)*xfac
      ietap(lazy+1)=lpol
      mm=mm+1
      if(m.ne.1)goto 7700
      yy=yy+yy
      sfac=0.5d0
      goto 7799
7700  continue
      tfac=tfac-1.d0
7799  ufac=ufac+1.d0
7733  sfac=sfac*tfac*ufac
      lmqu=lmqu+1
      bilb(lmqu)=xx
      mmp1=mm+1
      xfac=yy*facti(mmp1)
      mneg=mm-1
      mpos=mneg-1
      mpo=mpol(mpos,inew)
      mne=mpol(mneg,inew)
c...   m  =  l   case
      npo=0
      do 7790 loop=1,mpo
7790  call convrs(ipol(loop,mpos,inew)+1,jpol(loop,mpos,inew)+1,
     *apol(loop,mpos,inew)*xx)
      do 7791 loop=1,mne
7791  call convrs(ipol(loop,mneg,inew),jpol(loop,mneg,inew)+1,
     *-apol(loop,mneg,inew)*xx)
      lazy=lazy+1
      mpole(lazy)=npo
      mpol(mm,iold)=npo
      vfac=sqrt(1.d0/sfac)
      do 7792 loop=1,npo
      lpol=lpol+1
      kpole(lpol)=l
      net1(lpol)=l-ipole(lpol)
      net2(lpol)=l-jpole(lpol)
      ipol(loop,mm,iold)=ipole(lpol)
      jpol(loop,mm,iold)=jpole(lpol)
      apol(loop,mm,iold)=apole(lpol)
      fsph(lpol)=apole(lpol)*vfac
7792  apole(lpol)=apole(lpol)*xfac
      ietap(lazy+1)=lpol
c...  -m  =  l   case
      npo=0
      do 7793 loop=1,mpo
7793  call convrs(ipol(loop,mpos,inew),jpol(loop,mpos,inew)+1,
     *apol(loop,mpos,inew)*xx)
      do 7794 loop=1,mne
7794  call convrs(ipol(loop,mneg,inew)+1,jpol(loop,mneg,inew)+1,
     *apol(loop,mneg,inew)*xx)
      lazy=lazy+1
      mpole(lazy)=npo
      mpol(mmp1,iold)=npo
      do 7795 loop=1,npo
      lpol=lpol+1
      kpole(lpol)=l
      net1(lpol)=l-ipole(lpol)
      net2(lpol)=l-jpole(lpol)
      ipol(loop,mmp1,iold)=ipole(lpol)
      jpol(loop,mmp1,iold)=jpole(lpol)
      apol(loop,mmp1,iold)=apole(lpol)
      fsph(lpol)=apole(lpol)*vfac
7795  apole(lpol)=apole(lpol)*xfac
      ietap(lazy+1)=lpol
      loop=iold
      iold=inew
7755  inew=loop
      do 7722 i=1,lpol
7722  net3(i)=iky(net1(i)+1)+net2(i)+1
      do 9976 i=0,7
9976  nu3p(i)=i*i
      return
      end
c***./ add name=convrs
      subroutine convrs(i,j,z)
      implicit REAL (a-h,o-z)
      common/loco/lpol,npo
      common/moncon/apole(200),ipole(200),jpole(200),
     *kpole(200),mpole(50),bilb(25),frod(25)
      lponpo=lpol+npo
      do 3 ll=lpol+1,lponpo
      if(i.eq.ipole(ll).and.j.eq.jpole(ll))goto 1
3     continue
      npo=npo+1
      apole(lponpo+1)=z
      ipole(lponpo+1)=i
      jpole(lponpo+1)=j
      return
1     bilbo=apole(ll)+z
      if(abs(bilbo).lt.(1d-8))then
      do 4 l=ll+1,lponpo
      apole(l-1)=apole(l)
      ipole(l-1)=ipole(l)
4     jpole(l-1)=jpole(l)
      npo=npo-1
      else
      apole(ll)=bilbo
      endif
      return
      end
c***./ add name=dfac0d
      subroutine dfac0d(expab,result)
      implicit REAL (a-h,o-z)
      dimension result(20,25)
      logical lscree
      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
c... to calculate expansion coefficients of products of solid
c... harmonics centred on a and b in lambda functions centred on p
c... s on a/d on b
      anormx=-(facx+facx)
      fxpab=expab
      fa=facb
      h100=ba(1)*anormx
      h010=ba(2)*anormx
      h001=ba(3)*anormx
      h200=h100*h100
      h020=h010*h010
      p001=h001+h001
      anormx=-fa*fxpab
      bnormx=anormx+anormx
      anormx=fa*anormx
      result(20,1)=(h001*p001-h200-h020)*fxpab
      result(10,1)=h100*bnormx
      result(16,1)=h010*bnormx
      result(19,1)=-p001*bnormx
      result(4,1)=anormx
      result(13,1)=anormx
      result(18,1)=-anormx-anormx
      anormx=fxpab*alphap(4)
      result(20,4)=(h200-h020)*anormx
      anormx=anormx+anormx
      h100=h100*anormx
      result(20,3)=h010*h001*anormx
      result(20,2)=h100*h001
      result(20,5)=h100*h010
      anormx=anormx*fa
      h100=h100*fa
      h010=h010*anormx
      result(10,2)=h001*anormx
      result(16,3)=result(10,2)
      result(19,2)=h100
      result(10,4)=h100
      result(16,5)=h100
      result(19,3)=h010
      result(10,5)=h010
      result(16,4)=-h010
      anormx=anormx*fa
      result(9,2)=anormx
      result(15,3)=anormx
      result(7,5)=anormx
      result(4,4)=anormx*0.5d0
      result(13,4)=-result(4,4)
      return
      end
c***./ add name=dfac3
      subroutine dfac3(mprima,mprimb,cxa,itypea,result,p)
      implicit REAL (a-h,o-z)
      dimension cxa(*),result(*),p(*)
INCLUDE(common/crys_params.hf77)
      common/basato/
     * aznuc(lim016),xa(3,lim016),
     * che(lim015),exad(lim015+1),xl(3,lim015),
     * exx(lim042),c1(lim042),c2(lim042),c3(lim042),
     * cmax(lim042),c2w(lim042),c3w(lim042),
     * nat(lim016),nshpri(lim016+1),ipseud(lim016),
     * laa(lim015+1),lan(lim015),lat(lim015),latao(lim015),
     * ndq(lim015+1),latoat(lim015)
      logical lscree
      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
      common/tcomm/accfac,expacc
      expa=exx(mprima)
      expb=exx(mprimb)
      alphap(1)=expa+expb
      alphap(2)=1.d0/alphap(1)
      facb=expb*alphap(2)
      facx=facb*expa
      bilbo=facx*rsquar
      lscree=bilbo.ge.(60.d0)
      if(lscree)return
      expabx=exp(-bilbo)*alphap(2)
      alphap(3)=sqrt(alphap(2))
      expacc=alphap(3)*cmax(mprima)*cmax(mprimb)*expabx
      lscree=expacc.le.accfac
      if(lscree)return
      faca=expa*alphap(2)
      p(1)=cxa(1)+ba(1)*facb
      p(2)=cxa(2)+ba(2)*facb
      p(3)=cxa(3)+ba(3)*facb
      goto (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16),itypea
c...  s  -  s
1     result(1)=c1(mprima)*c1(mprimb)*expabx
      return
c...   s   -   sp
2     do 22 loop=1,14
22    result(loop)=0.d0
      csaa=c1(mprima)*expabx
      result(4)=c1(mprimb)*csaa
      csaa=c2w(mprimb)*csaa*facb
      result(5)=csaa
      result(10)=csaa
      result(15)=csaa
      csaa=-(expa+expa)*csaa
      result(8)=ba(1)*csaa
      result(12)=ba(2)*csaa
      result(16)=ba(3)*csaa
      return
c...   s   -   p
3     do 33 loop=2,10
33    result(loop)=0.d0
      csaa=c1(mprima)*c2w(mprimb)*expabx*facb
      result(1)=csaa
      result(6)=csaa
      result(11)=csaa
      csaa=-(expa+expa)*csaa
      result(4)=ba(1)*csaa
      result(8)=ba(2)*csaa
      result(12)=ba(3)*csaa
      return
c...   s   -   d
4     do 44 loop=2,49
44    result(loop)=0.d0
      call dfacsd(c1(mprima)*c3w(mprimb)*expabx,result)
      return
c...   sp   -   s
5     csaa=c1(mprimb)*expabx
      do 55 loop=1,14
55    result(loop)=0.d0
      result(4)=c1(mprima)*csaa
      csaa=c2w(mprima)*csaa*faca
      result(5)=csaa
      result(10)=csaa
      result(15)=csaa
      csaa=(expb+expb)*csaa
      result(8)=ba(1)*csaa
      result(12)=ba(2)*csaa
      result(16)=ba(3)*csaa
      return
c...   sp   -   sp
6     do 66 loop=1,157
66    result(loop)=0.d0
      csaa=c1(mprima)*expabx
      cpaa=c2w(mprima)*expabx
      result(10)=csaa*c1(mprimb)
      csaa=csaa*c2w(mprimb)*facb
      result(14)=csaa
      result(27)=csaa
      result(39)=csaa
      csaa=-(expa+expa)*csaa
      result(20)=ba(1)*csaa
      result(30)=ba(2)*csaa
      result(40)=ba(3)*csaa
      csaa=c1(mprimb)*cpaa*faca
      result(44)=csaa
      result(87)=csaa
      result(129)=csaa
      csaa=(expb+expb)*csaa
      result(50)=ba(1)*csaa
      result(90)=ba(2)*csaa
      result(130)=ba(3)*csaa
      call dfacpp(c2w(mprimb)*cpaa,result(51))
      return
c...   sp   -   p
7     do 77 loop=1,117
77    result(loop)=0.d0
      cpaa=c2w(mprimb)*expabx
      csaa=c1(mprima)*cpaa*facb
      result(4)=csaa
      result(17)=csaa
      result(29)=csaa
      csaa=-(expa+expa)*csaa
      result(10)=ba(1)*csaa
      result(20)=ba(2)*csaa
      result(30)=ba(3)*csaa
      call dfacqq(c2w(mprima)*cpaa,result(31))
      return
c...   sp   -   d
8     csaa=c3w(mprimb)*expabx
      do 88 loop=1,398
88    result(loop)=0.d0
      call dfac0d(c1(mprima)*csaa,result)
      call dfacpd(c2w(mprima)*csaa,result(101))
      return
c...   p   -   s
9     do 99 loop=2,10
99    result(loop)=0.d0
      csaa=c2w(mprima)*c1(mprimb)*expabx*faca
      result(1)=csaa
      result(6)=csaa
      result(11)=csaa
      csaa=(expb+expb)*csaa
      result(4)=ba(1)*csaa
      result(8)=ba(2)*csaa
      result(12)=ba(3)*csaa
      return
c...   p   -   sp
10    do 1010 loop=1,117
1010  result(loop)=0.d0
      cpaa=c2w(mprima)*expabx
      csaa=c1(mprimb)*cpaa*faca
      result(4)=csaa
      result(47)=csaa
      result(89)=csaa
      csaa=(expb+expb)*csaa
      result(10)=ba(1)*csaa
      result(50)=ba(2)*csaa
      result(90)=ba(3)*csaa
      call dfacpp(c2w(mprimb)*cpaa,result(11))
      return
c...   p   -   p
11    do 1111 loop=1,87
1111  result(loop)=0.d0
      call dfacqq(c2w(mprima)*c2w(mprimb)*expabx,result)
      return
c...   p   -   d
12    do 1212 loop=2,298
1212  result(loop)=0.d0
      call dfacpd(c2w(mprima)*c3w(mprimb)*expabx,result)
      return
c...   d   -   s
13    do 1313 loop=2,49
1313  result(loop)=0.d0
      call dfacds(c3w(mprima)*c1(mprimb)*expabx,result)
      return
c...   d   -   sp
14    do 1414 loop=1,398
1414  result(loop)=0.d0
      csaa=c3w(mprima)*expabx
      call dfacdq(csaa*c1(mprimb),csaa*c2w(mprimb),result)
      return
c...   d   -   p
15    do 1515 loop=2,298
1515  result(loop)=0.d0
      call dfacdp(c3w(mprima)*c2w(mprimb)*expabx,result)
      return
c...   d   -   d
16    do 1616 loop=2,874
1616  result(loop)=0.d0
      call dfacdd(c3w(mprima)*c3w(mprimb)*expabx,result)
      return
      end
c***./ add name=dfacdd
      subroutine dfacdd(expab,result)
      implicit REAL (a-h,o-z)
      dimension result(35,25)
      logical lscree
      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
      fx=facx+facx
      h100=ba(1)*fx
      h010=ba(2)*fx
      h001=ba(3)*fx
      h110=h100*h010
      h101=h100*h001
      h011=h010*h001
      h111=h110*h001
      h200=h100*h100-fx
      h020=h010*h010-fx
      h002=h001*h001-fx
      p002=h002+h002
      g220=h200-h020
      p222=p002-h200-h020
      h210=h200*h010
      h201=h200*h001
      h211=h210*h001
      h220=h200*h020
      h202=h200*h002
      p220=h220+h220
      h120=h020*h100
      h021=h020*h001
      g221=h201-h021
      h121=h120*h001
      h022=h020*h002
      h102=h002*h100
      h012=h002*h010
      h112=h102*h010
      fy=fx+fx
      h300=(h200-fy)*h100
      h030=(h020-fy)*h010
      h003=(h002-fy)*h001
      h310=h300*h010
      h301=h300*h001
      h130=h030*h100
      h031=h030*h001
      h103=h003*h100
      h013=h003*h010
      fy=fy+fx
      h400=h100*h300-fy*h200
      h040=h010*h030-fy*h020
      p440=h400+h040
      fb=-facb
      a2=faca*faca
      b2=fb*fb
      a2b=a2*fb
      b2a=b2*faca
      a2tb2=a2*b2
      anorm=expab
      bnorm=anorm*alphap(4)
      result(35,4)=((h202-h022)*2.d0+h040-h400)*bnorm
      result(35,16)=result(35,4)
      aa=a2*bnorm
      bb=b2*bnorm
      aabb=aa*b2
      result(21,4)=aabb
      result(21,16)=aabb
      result(1,4)=-aabb
      result(1,16)=-aabb
      aabb=aabb+aabb
      result(8,4)=aabb
      result(8,16)=aabb
      result(3,2)=-aabb
      result(12,2)=-aabb
      result(6,3)=-aabb
      result(22,3)=-aabb
      result(24,4)=-aabb
      result(2,5)=-aabb
      result(11,5)=-aabb
      result(3,6)=-aabb
      result(12,6)=-aabb
      result(6,11)=-aabb
      result(22,11)=-aabb
      result(24,16)=-aabb
      result(2,21)=-aabb
      result(11,21)=-aabb
      aabb=aabb+aabb
      result(17,2)=aabb
      result(27,3)=aabb
      result(14,5)=aabb
      result(17,6)=aabb
      result(27,11)=aabb
      result(14,21)=aabb
      bnorm=bnorm+bnorm
      result(35,2)=(h103*2.d0-h301-h121)*bnorm
      result(35,6)=result(35,2)
      result(35,3)=(h013*2.d0-h031-h211)*bnorm
      result(35,11)=result(35,3)
      result(35,5)=(h112*2.d0-h310-h130)*bnorm
      result(35,21)=result(35,5)
      aab=a2b*bnorm
      abb=b2a*bnorm
      a001=h001*aab
      a010=h010*aab
      a100=h100*aab
      b001=h001*abb
      b010=h010*abb
      b100=h100*abb
      result(4,2)=-a001
      result(13,2)=-a001
      result(7,3)=-a001
      result(23,3)=-a001
      result(4,6)=-b001
      result(13,6)=-b001
      result(7,11)=-b001
      result(23,11)=-b001
      result(13,4)=b100-a100
      result(13,16)=-result(13,4)
      bilbo=-a100-b100
      result(4,4)=bilbo
      result(4,16)=bilbo
      result(7,5)=bilbo-b100
      result(9,2)=result(7,5)
      result(7,21)=bilbo-a100
      result(9,6)=result(7,21)
      result(23,5)=-a100
      result(25,2)=-a100
      result(23,21)=-b100
      result(25,6)=-b100
      result(7,4)=a010-b010
      result(7,16)=-result(7,4)
      bilbo=a010+b010
      result(23,4)=bilbo
      result(23,16)=bilbo
      result(13,5)=-bilbo-b010
      result(25,3)=result(13,5)
      result(13,21)=-bilbo-a010
      result(25,11)=result(13,21)
      result(4,5)=-a010
      result(9,3)=-a010
      result(4,21)=-b010
      result(9,11)=-b010
      a001=a001+a001
      b001=b001+b001
      a010=a010+a010
      b010=b010+b010
      a100=a100+a100
      b100=b100+b100
      result(9,4)=b001
      result(25,4)=-b001
      result(15,5)=b001+b001
      result(18,2)=result(15,5)+a001
      result(28,3)=result(18,2)
      result(9,16)=a001
      result(25,16)=-a001
      result(15,21)=a001+a001
      result(18,6)=result(15,21)+b001
      result(28,11)=result(18,6)
      result(32,3)=a010
      result(18,5)=a010
      result(28,4)=-a010
      result(15,6)=-a010
      result(32,2)=a100
      result(18,4)=a100
      result(28,5)=a100
      result(15,11)=-a100
      result(32,11)=b010
      result(18,21)=b010
      result(15,2)=-b010
      result(28,16)=-b010
      result(32,6)=b100
      result(18,16)=b100
      result(28,21)=b100
      result(15,3)=-b100
      c=faca*bnorm
      d=fb*bnorm
      a=c+c
      b=d+d
      ab=a*fb
      x200=p222*aa
      a220=g220*aa
      b220=g220*bb
      x020=p222*bb
      ab200=h200*ab
      ab020=h020*ab
      result(10,4)=x020-ab200-a220
      result(26,4)=ab020-a220-x020
      result(33,4)=a220+a220
      result(10,16)=x200-ab200-b220
      result(26,16)=ab020-b220-x200
      result(33,16)=b220+b220
      aa=aa+aa
      bb=bb+bb
      bilbo=h201-h021
      result(34,4)=bilbo*a
      result(34,16)=bilbo*b
      a111=h111*a
      b111=h111*b
      a102=h102*2.d0-h300-h120
      a012=h012*2.d0-h030-h210
      x003=h003*2.d0-h201-h021
      x312=h300-h120
      x231=h030-h210
      d102=a102*d
      d012=a012*d
      b003=x003*d
      a003=x003*c
      c012=a012*c
      c102=a102*c
      result(20,4)=d102-x312*c
      result(30,4)=x231*c-d012
      result(20,16)=c102-x312*d
      result(30,16)=x231*d-c012
      result(20,5)=d012-h210*a
      result(30,5)=d102-h120*a
      result(20,2)=b003-h201*a
      result(30,3)=b003-h021*a
      result(20,21)=c012-h210*b
      result(30,21)=c102-h120*b
      result(20,6)=a003-h201*b
      result(30,11)=a003-h021*b
      result(30,2)=-a111
      result(20,3)=-a111
      result(30,6)=-b111
      result(20,11)=-b111
      result(34,5)=a111+a111
      result(34,21)=b111+b111
      a110=h110*aa
      a101=h101*aa
      a011=h011*aa
      b110=h110*bb
      b101=h101*bb
      b011=h011*bb
      x200=x200+x200
      x020=x020+x020
      bilbo=(p002-h200)*ab
      ab110=-h110*ab
      ab101=h101*ab
      ab011=h011*ab
      result(19,2)=x020+bilbo
      result(19,6)=x200+bilbo
      bilbo=(p002-h020)*ab
      result(29,3)=x020+bilbo
      result(29,11)=x200+bilbo
      bilbo=ab200+ab020
      result(16,5)=x020-bilbo
      result(16,21)=x200-bilbo
      c101=a101+ab101
      c011=a011+ab011
      d101=b101+ab101
      d011=b011+ab011
      result(26,2)=-a101
      result(10,3)=-a011
      result(26,6)=-b101
      result(10,11)=-b011
      result(10,5)=ab110-a110
      result(10,21)=ab110-b110
      result(29,2)=ab110
      result(19,3)=ab110
      result(29,6)=ab110
      result(19,11)=ab110
      result(16,2)=-ab011
      result(16,6)=-ab011
      result(16,3)=-ab101
      result(16,11)=-ab101
      result(10,2)=-c101
      result(26,3)=-c011
      result(26,5)=result(10,5)
      result(10,6)=-d101
      result(26,11)=-d011
      result(26,21)=result(10,21)
      a=a+a
      b=b+b
      ab101=ab101+ab101
      ab011=ab011+ab011
      result(29,5)=ab101
      result(29,21)=ab101
      result(19,4)=ab101
      result(19,16)=ab101
      result(19,5)=ab011
      result(19,21)=ab011
      result(29,4)=-ab011
      result(29,16)=-ab011
      result(34,2)=h102*a+d102
      result(34,3)=h012*a+d012
      result(34,6)=h102*b+c102
      result(34,11)=h012*b+c012
      result(33,5)=a110+a110
      result(33,21)=b110+b110
      result(33,2)=c101+c101
      result(33,3)=c011+c011
      result(33,6)=d101+d101
      result(33,11)=d011+d011
      bnorm=anorm+anorm
      bilbo=(faca+fb)*bnorm
      result(20,1)=-a102*bilbo
      result(30,1)=-a012*bilbo
      result(34,1)=(bilbo+bilbo)*x003
      bilbo=(bnorm+bnorm)*faca*fb
      x200=-(a2+b2)*p222*anorm
      result(10,1)=bilbo*h200+x200
      result(26,1)=bilbo*h020+x200
      bilbo=bilbo+bilbo
      result(16,1)=bilbo*h110
      bilbo=bilbo+bilbo
      result(33,1)=bilbo*h002-x200-x200
      result(19,1)=-bilbo*h101
      result(29,1)=-bilbo*h011
      aabb=a2tb2*anorm
      result(1,1)=aabb
      result(21,1)=aabb
      aabb=aabb+aabb
      result(5,1)=aabb
      aabb=aabb+aabb
      result(8,1)=-aabb
      result(24,1)=-aabb
      result(31,1)=aabb
      bilbo=(a2b+b2a)*bnorm
      result(4,1)=h100*bilbo
      result(13,1)=result(4,1)
      result(7,1)=h010*bilbo
      result(23,1)=result(7,1)
      bilbo=bilbo+bilbo
      result(18,1)=-bilbo*h100
      result(28,1)=-bilbo*h010
      bilbo=bilbo*h001
      result(9,1)=-bilbo
      result(25,1)=-bilbo
      result(32,1)=bilbo+bilbo
      result(35,1)=((h001*h003-fy*h002-h202-h022)*4.d0+
     * p220+p440)*anorm
      anorm=anorm+bnorm
      aabb=a2tb2*anorm
      result(1,19)=aabb
      result(21,19)=aabb
      result(35,19)=(p440-p220)*anorm
      aabb=aabb+aabb
      result(3,9)=aabb
      result(6,14)=aabb
      result(3,17)=aabb
      result(6,18)=aabb
      result(2,20)=aabb
      result(2,24)=aabb
      result(12,9)=-aabb
      result(22,14)=-aabb
      result(12,17)=-aabb
      result(22,18)=-aabb
      result(5,19)=-aabb
      result(11,20)=-aabb
      result(11,24)=-aabb
      aabb=aabb+aabb
      result(8,7)=aabb
      result(14,8)=aabb
      result(14,12)=aabb
      result(6,10)=aabb
      result(24,13)=aabb
      result(12,15)=aabb
      result(6,22)=aabb
      result(12,23)=aabb
      result(5,25)=aabb
      anorm=anorm+anorm
      a=faca*anorm
      b=fb*anorm
      cc=a2*anorm
      dd=b2*anorm
      abb=b2a*anorm
      aab=a2b*anorm
      c=a+a
      d=b+b
      ab=c*fb
      aa=cc+ab
      bb=dd+ab
      a221=g221*a
      b221=g221*b
      c201=h201*c
      c021=h021*c
      c210=h210*c
      c120=h120*c
      d201=h201*d
      d021=h021*d
      d210=h210*d
      d120=h120*d
      a100=h100*aab
      a010=h010*aab
      a001=h001*aab
      c100=a100+a100
      c010=a010+a010
      c001=a001+a001
      b100=h100*abb
      b010=h010*abb
      b001=h001*abb
      d100=b100+b100
      d010=b010+b010
      d001=b001+b001
      a220=g220*cc
      b220=g220*dd
      x200=h200*ab
      x020=h020*ab
      bilbo=(a220+b220)*0.5d0
      result(10,19)=bilbo+x200
      result(26,19)=x020-bilbo
      result(19,9)=a220+x200
      result(29,14)=a220-x020
      result(29,18)=b220-x020
      result(19,17)=b220+x200
      result(33,7)=x200
      result(29,10)=x200
      result(29,22)=x200
      result(26,25)=x200
      result(33,13)=x020
      result(19,15)=x020
      result(19,23)=x020
      result(10,25)=x020
      result(26,17)=-h101*cc
      result(10,18)=h011*cc
      result(10,14)=h011*dd
      result(26,9)=-h101*dd
      result(10,20)=h110*aa
      result(26,20)=-result(10,20)
      result(26,18)=-h011*aa
      result(10,17)=h101*aa
      result(16,24)=g220*aa
      result(16,20)=g220*bb
      result(10,24)=h110*bb
      result(26,24)=-result(10,24)
      result(26,14)=-h011*bb
      result(10,9)=h101*bb
      result(4,9)=b001
      result(7,14)=b001
      result(13,9)=-b001
      result(23,14)=-b001
      result(7,18)=a001
      result(4,17)=a001
      result(13,17)=-a001
      result(23,18)=-a001
      result(7,20)=d100+a100
      result(9,17)=result(7,20)
      result(25,17)=-a100
      result(23,20)=-a100
      result(13,20)=-d010-a010
      result(25,18)=result(13,20)
      result(9,18)=a010
      result(4,20)=a010
      result(23,19)=a010+b010
      result(7,19)=-result(23,19)
      result(13,24)=-c010-b010
      result(25,14)=result(13,24)
      result(9,14)=b010
      result(4,24)=b010
      result(4,19)=a100+b100
      result(13,19)=-result(4,19)
      result(7,24)=c100+b100
      result(9,9)=result(7,24)
      result(25,9)=-b100
      result(23,24)=-b100
      result(34,17)=x312*b
      result(30,20)=result(34,17)-c120
      result(34,9)=x312*a
      result(30,24)=result(34,9)-d120
      result(20,19)=result(34,17)+result(34,9)
      result(34,14)=-x231*a
      result(20,24)=result(34,14)+d210
      result(34,18)=-x231*b
      result(20,20)=result(34,18)+c210
      result(30,19)=-result(34,18)-result(34,14)
      result(20,9)=d201+a221
      result(30,14)=a221-d021
      result(20,17)=c201+b221
      result(30,18)=b221-c021
      result(34,13)=c021+d021
      result(20,15)=d021
      result(20,23)=c021
      result(34,7)=c201+d201
      result(30,10)=d201
      result(30,22)=c201
      result(35,14)=(h211-h031)*anorm
      result(35,18)=result(35,14)
      result(35,9)=(h301-h121)*anorm
      result(35,17)=result(35,9)
      result(35,20)=(h310-h130)*anorm
      result(35,24)=result(35,20)
      anorm=anorm+anorm
      aa=c*faca+ab
      bb=d*fb+ab
      a102=h102*c
      a012=h012*c
      a111=h111*c
      b102=h102*d
      b012=h012*d
      b111=h111*d
      a110=h110*aa
      a101=h101*aa
      a011=h011*aa
      b110=h110*bb
      b101=h101*bb
      b011=h011*bb
      bilbo=a111+b111
      result(20,10)=bilbo
      result(34,8)=bilbo
      result(34,12)=bilbo
      result(30,15)=bilbo
      result(20,22)=bilbo
      result(30,23)=bilbo
      result(20,14)=b111
      result(30,9)=-b111
      result(20,18)=a111
      result(30,17)=-a111
      bilbo=d001+c001
      result(9,7)=bilbo
      result(15,8)=bilbo
      result(15,12)=bilbo
      result(25,13)=bilbo
      result(7,10)=d001
      result(13,15)=d001
      result(7,22)=c001
      result(13,23)=c001
      bilbo=d010+c010
      result(7,25)=bilbo
      result(28,13)=bilbo
      result(15,15)=bilbo
      result(15,23)=bilbo
      result(18,8)=c010
      result(9,10)=c010
      result(15,9)=-c010
      result(18,12)=d010
      result(9,22)=d010
      result(15,17)=-d010
      bilbo=d100+c100
      result(13,25)=bilbo
      result(18,7)=bilbo
      result(15,10)=bilbo
      result(15,22)=bilbo
      result(28,12)=c100
      result(15,14)=c100
      result(25,15)=c100
      result(28,8)=d100
      result(15,18)=d100
      result(25,23)=d100
      result(19,7)=a101+b101
      result(29,8)=b101
      result(16,10)=b101
      result(29,12)=a101
      result(16,22)=a101
      result(29,13)=a011+b011
      result(19,12)=b011
      result(16,15)=b011
      result(19,8)=a011
      result(16,23)=a011
      result(16,25)=a110+b110
      result(19,10)=a110
      result(29,15)=a110
      result(19,22)=b110
      result(29,23)=b110
      result(20,7)=a102+b102
      result(30,8)=b102
      result(30,12)=a102
      result(30,13)=a012+b012
      result(20,8)=a012
      result(20,12)=b012
      result(20,25)=c120+d120
      result(34,15)=c120
      result(34,23)=d120
      result(30,25)=c210+d210
      result(34,10)=c210
      result(34,22)=d210
      h110=h110*ab
      result(33,8)=h110
      result(33,12)=h110
      result(19,14)=h110
      result(19,18)=h110
      result(29,9)=-h110
      result(29,17)=-h110
      result(16,19)=-h110-h110
      h011=h011*ab
      result(10,10)=h011
      result(10,22)=h011
      result(16,9)=-h011
      result(16,17)=-h011
      h101=h101*ab
      result(26,15)=h101
      result(16,14)=h101
      result(16,18)=h101
      result(26,23)=h101
      h002=h002*ab
      result(10,7)=h002
      result(16,8)=h002
      result(16,12)=h002
      result(26,13)=h002
      result(35,15)=h121*anorm
      result(35,23)=result(35,15)
      result(35,10)=h211*anorm
      result(35,22)=result(35,10)
      result(35,8)=h112*anorm
      result(35,12)=result(35,8)
      result(35,7)=h202*anorm
      result(35,13)=h022*anorm
      result(35,25)=h220*anorm
      return
      end
c***./ add name=dfacdp
      subroutine dfacdp(expab,result)
      implicit REAL (a-h,o-z)
      dimension result(20,25)
      logical lscree
      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
c... to calculate expansion coefficients of products of solid
c... harmonics centred on a and b in lambda functions centred on p
c... d on a/p on b
      fx=facx+facx
      fa=faca
      fb=facb
      h100=ba(1)*fx
      h010=ba(2)*fx
      h001=ba(3)*fx
      h110=h100*h010
      h101=h100*h001
      h011=h010*h001
      h200=h100*h100-fx
      h020=h010*h010-fx
      h002=h001*h001-fx
      h210=h200*h010
      h201=h200*h001
      h021=h020*h001
      h120=h020*h100
      h102=h002*h100
      h012=h002*h010
      p001=h001+h001
      p002=h002+h002
      fx=fx+fx
      h300=(h200-fx)*h100
      h030=(h020-fx)*h010
      result(20,1)=(h300+h120-h102*2.d0)*expab
      result(20,2)=(h030+h210-h012*2.d0)*expab
      result(20,3)=(h201+h021+(fx-h002)*p001)*expab
      bnormx=expab*fb
      anormx=expab*fa
      frod=anormx+anormx
      hobb=(p002-h200-h020)*bnormx
      result(10,1)=hobb+h200*frod
      result(16,2)=hobb+h020*frod
      result(19,3)=hobb-p002*frod
      result(16,1)=h110*frod
      result(10,2)=result(16,1)
      bilb=h101*frod
      frod=h011*frod
      result(10,3)=bilb
      result(16,3)=frod
      result(19,1)=-bilb-bilb
      result(19,2)=-frod-frod
      bnormx=-(bnormx+bnormx)*fa
      anormx=anormx*fa
      bilb=h100*bnormx
      frod=h010*bnormx
      hobb=-p001*bnormx
      x200=h100*anormx
      x020=h010*anormx
      x220=h001*anormx
      result(7,2)=bilb
      result(9,3)=bilb
      result(13,1)=x200
      result(18,1)=-x200-x200
      result(4,1)=x200+bilb
      result(7,1)=frod
      result(15,3)=frod
      result(4,2)=x020
      result(18,2)=-x020-x020
      result(13,2)=x020+frod
      result(9,1)=hobb
      result(15,2)=hobb
      result(4,3)=x220
      result(13,3)=x220
      result(18,3)=hobb-x220-x220
      bnormx=-bnormx*fa
      result(8,1)=bnormx
      result(14,2)=bnormx
      result(17,3)=bnormx
      bnormx=-bnormx*0.5d0
      result(1,1)=bnormx
      result(5,1)=bnormx
      result(2,2)=bnormx
      result(11,2)=bnormx
      result(3,3)=bnormx
      result(12,3)=bnormx
      anormx=expab*alphap(4)
      bnormx=anormx*fb
      result(20,10)=(h120-h300)*anormx
      result(20,11)=(h030-h210)*anormx
      result(20,12)=(h021-h201)*anormx
      anormx=-anormx-anormx
      result(20,4)=h201*anormx
      result(20,6)=h102*anormx
      result(20,8)=h021*anormx
      result(20,9)=h012*anormx
      result(20,13)=h210*anormx
      result(20,14)=h120*anormx
      bilb=h110*h001*anormx
      result(20,15)=bilb
      result(20,7)=bilb
      result(20,5)=bilb
      x220=(h200-h020)*bnormx
      bnormx=bnormx+bnormx
      result(19,12)=x220
      result(16,5)=h101*bnormx
      result(10,7)=h011*bnormx
      result(19,15)=h110*bnormx
      anormx=anormx*fa
      x200=h200*anormx
      x020=h020*anormx
      bilb=h011*anormx
      frod=h110*anormx
      hobb=h101*anormx
      result(10,6)=h002*anormx
      result(16,9)=result(10,6)
      result(19,4)=x200
      result(16,13)=x200
      result(10,10)=x220+x200
      result(19,8)=x020
      result(10,14)=x020
      result(16,11)=x220-x020
      result(10,5)=bilb
      result(10,15)=bilb
      result(16,12)=-bilb
      result(16,8)=result(10,7)+bilb
      result(19,9)=result(16,8)
      result(19,5)=frod
      result(19,7)=frod
      result(10,11)=frod
      result(16,10)=-frod
      result(10,13)=result(19,15)+frod
      result(16,14)=result(10,13)
      result(16,7)=hobb
      result(16,15)=hobb
      result(10,12)=hobb
      result(10,4)=result(16,5)+hobb
      result(19,6)=result(10,4)
      bnormx=bnormx*fa
      anormx=anormx*fa
      bilb=h100*bnormx
      frod=h010*bnormx
      hobb=h001*bnormx
      x200=h100*anormx
      x020=h010*anormx
      x220=h001*anormx
      result(15,5)=bilb
      result(18,6)=bilb
      result(7,11)=bilb
      result(9,12)=bilb
      result(13,14)=bilb
      result(15,15)=bilb
      result(15,7)=x200
      result(9,4)=bilb+x200
      result(7,13)=result(9,4)
      result(9,7)=frod
      result(18,9)=frod
      result(4,13)=frod
      result(9,15)=frod
      result(7,10)=-frod
      result(15,12)=-frod
      result(9,5)=x020
      result(15,8)=frod+x020
      result(7,14)=result(15,8)
      result(4,4)=hobb
      result(7,5)=hobb
      result(7,7)=hobb
      result(13,8)=hobb
      result(7,15)=x220
      result(15,9)=x220+hobb
      result(9,6)=result(15,9)
      result(13,10)=-x200*0.5d0
      result(4,10)=bilb-result(13,10)
      result(4,11)=x020*0.5d0
      result(13,11)=-frod-result(4,11)
      result(4,12)=x220*0.5d0
      result(13,12)=-result(4,12)
      bnormx=bnormx*fa
      result(3,4)=bnormx
      result(6,5)=bnormx
      result(8,6)=bnormx
      result(6,7)=bnormx
      result(12,8)=bnormx
      result(14,9)=bnormx
      result(2,13)=bnormx
      result(5,14)=bnormx
      result(6,15)=bnormx
      bnormx=bnormx*0.5d0
      result(3,12)=bnormx
      result(2,11)=bnormx
      result(1,10)=bnormx
      result(5,10)=-bnormx
      result(11,11)=-bnormx
      result(12,12)=-bnormx
      return
      end
c***./ add name=dfacdq
      subroutine dfacdq(expab,expac,result)
      implicit REAL (a-h,o-z)
      dimension result(20,25)
      logical lscree
      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
c... to calculate expansion coefficients of products of solid
c... harmonics centred on a and b in lambda functions centred on p
c... d on a/sp on b
      fx=facx+facx
      fa=faca
      fb=facb
      h100=ba(1)*fx
      h010=ba(2)*fx
      h001=ba(3)*fx
      h110=h100*h010
      h101=h100*h001
      h011=h010*h001
      h200=h100*h100-fx
      h020=h010*h010-fx
      h002=h001*h001-fx
      h210=h200*h010
      h201=h200*h001
      h021=h020*h001
      h120=h020*h100
      h102=h002*h100
      h012=h002*h010
      g220=h200-h020
      p002=h002+h002
      p001=h001+h001
      fx=fx+fx
      h300=(h200-fx)*h100
      h030=(h020-fx)*h010
      anormx=fa*expab
      bnormx=anormx+anormx
      anormx=fa*anormx
      hobb=p002-h200-h020
      result(20,1)=hobb*expab
      result(10,1)=-bnormx*h100
      result(16,1)=-bnormx*h010
      result(19,1)=bnormx*p001
      result(4,1)=-anormx
      result(13,1)=-anormx
      result(18,1)=anormx+anormx
      anormx=expab*alphap(4)
      result(20,13)=g220*anormx
      anormx=anormx+anormx
      result(20,5)=h101*anormx
      result(20,9)=h011*anormx
      result(20,17)=h110*anormx
      anormx=anormx*fa
      bilb=h100*anormx
      frod=h010*anormx
      result(10,5)=h001*anormx
      result(16,9)=result(10,5)
      result(19,5)=bilb
      result(10,13)=bilb
      result(16,17)=bilb
      result(19,9)=frod
      result(10,17)=frod
      result(16,13)=-frod
      anormx=anormx*fa
      result(9,5)=anormx
      result(15,9)=anormx
      result(7,17)=anormx
      result(4,13)=anormx*0.5d0
      result(13,13)=-result(4,13)
      result(20,2)=(h300+h120-h102*2.d0)*expac
      result(20,3)=(h030+h210-h012*2.d0)*expac
      result(20,4)=(h201+h021+(fx-h002)*p001)*expac
      bnormx=expac*fb
      anormx=expac*fa
      frod=anormx+anormx
      hobb=hobb*bnormx
      result(10,2)=hobb+h200*frod
      result(16,3)=hobb+h020*frod
      result(19,4)=hobb-p002*frod
      result(16,2)=h110*frod
      result(10,3)=result(16,2)
      bilb=h101*frod
      frod=h011*frod
      result(10,4)=bilb
      result(16,4)=frod
      result(19,2)=-bilb-bilb
      result(19,3)=-frod-frod
      bnormx=(bnormx+bnormx)*fa
      anormx=anormx*fa
      bilb=-h100*bnormx
      frod=-h010*bnormx
      hobb=p001*bnormx
      x200=h100*anormx
      x020=h010*anormx
      x220=h001*anormx
      result(7,3)=bilb
      result(9,4)=bilb
      result(13,2)=x200
      result(18,2)=-x200-x200
      result(4,2)=x200+bilb
      result(7,2)=frod
      result(15,4)=frod
      result(4,3)=x020
      result(18,3)=-x020-x020
      result(13,3)=x020+frod
      result(9,2)=hobb
      result(15,3)=hobb
      result(4,4)=x220
      result(13,4)=x220
      result(18,4)=hobb-x220-x220
      bnormx=bnormx*fa
      result(8,2)=bnormx
      result(14,3)=bnormx
      result(17,4)=bnormx
      bnormx=-bnormx*0.5d0
      result(1,2)=bnormx
      result(5,2)=bnormx
      result(2,3)=bnormx
      result(11,3)=bnormx
      result(3,4)=bnormx
      result(12,4)=bnormx
      anormx=expac*alphap(4)
      bnormx=anormx*fb
      result(20,14)=(h120-h300)*anormx
      result(20,15)=(h030-h210)*anormx
      result(20,16)=(h021-h201)*anormx
      anormx=-anormx-anormx
      result(20,6)=h201*anormx
      result(20,8)=h102*anormx
      result(20,11)=h021*anormx
      result(20,12)=h012*anormx
      result(20,18)=h210*anormx
      result(20,19)=h120*anormx
      bilb=h110*h001*anormx
      result(20,20)=bilb
      result(20,10)=bilb
      result(20,7)=bilb
      x220=g220*bnormx
      bnormx=bnormx+bnormx
      result(19,16)=x220
      result(16,7)=h101*bnormx
      result(10,10)=h011*bnormx
      result(19,20)=h110*bnormx
      anormx=anormx*fa
      x200=h200*anormx
      x020=h020*anormx
      bilb=h011*anormx
      frod=h110*anormx
      hobb=h101*anormx
      result(10,8)=h002*anormx
      result(16,12)=result(10,8)
      result(19,6)=x200
      result(16,18)=x200
      result(10,14)=x220+x200
      result(19,11)=x020
      result(10,19)=x020
      result(16,15)=x220-x020
      result(10,7)=bilb
      result(10,20)=bilb
      result(16,16)=-bilb
      result(16,11)=result(10,10)+bilb
      result(19,12)=result(16,11)
      result(19,7)=frod
      result(19,10)=frod
      result(10,15)=frod
      result(16,14)=-frod
      result(10,18)=result(19,20)+frod
      result(16,19)=result(10,18)
      result(16,10)=hobb
      result(16,20)=hobb
      result(10,16)=hobb
      result(10,6)=result(16,7)+hobb
      result(19,8)=result(10,6)
      bnormx=bnormx*fa
      anormx=anormx*fa
      bilb=h100*bnormx
      frod=h010*bnormx
      hobb=h001*bnormx
      x200=h100*anormx
      x020=h010*anormx
      x220=h001*anormx
      result(15,7)=bilb
      result(18,8)=bilb
      result(7,15)=bilb
      result(9,16)=bilb
      result(13,19)=bilb
      result(15,20)=bilb
      result(15,10)=x200
      result(9,6)=bilb+x200
      result(7,18)=result(9,6)
      result(9,10)=frod
      result(18,12)=frod
      result(4,18)=frod
      result(9,20)=frod
      result(7,14)=-frod
      result(15,16)=-frod
      result(9,7)=x020
      result(15,11)=frod+x020
      result(7,19)=result(15,11)
      result(4,6)=hobb
      result(7,7)=hobb
      result(7,10)=hobb
      result(13,11)=hobb
      result(7,20)=x220
      result(15,12)=x220+hobb
      result(9,8)=result(15,12)
      result(13,14)=-x200*0.5d0
      result(4,14)=bilb-result(13,14)
      result(4,15)=x020*0.5d0
      result(13,15)=-frod-result(4,15)
      result(4,16)=x220*0.5d0
      result(13,16)=-result(4,16)
      bnormx=bnormx*fa
      result(3,6)=bnormx
      result(6,7)=bnormx
      result(8,8)=bnormx
      result(6,10)=bnormx
      result(12,11)=bnormx
      result(14,12)=bnormx
      result(2,18)=bnormx
      result(5,19)=bnormx
      result(6,20)=bnormx
      bnormx=bnormx*0.5d0
      result(3,16)=bnormx
      result(2,15)=bnormx
      result(1,14)=bnormx
      result(5,14)=-bnormx
      result(11,15)=-bnormx
      result(12,16)=-bnormx
      return
      end
c***./ add name=dfacds
      subroutine dfacds(expab,result)
      implicit REAL (a-h,o-z)
      dimension result(10,25)
      logical lscree
      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
c... to calculate expansion coefficients of products of solid
c... harmonics centred on a and b in lambda functions centred on p
c... d on a/s on b
      anormx=facx+facx
      fxpab=expab
      fa=faca
      h100=ba(1)*anormx
      h010=ba(2)*anormx
      h001=ba(3)*anormx
      h200=h100*h100
      h020=h010*h010
      p001=h001+h001
      anormx=-fa*fxpab
      bnormx=anormx+anormx
      anormx=fa*anormx
      result(10,1)=(h001*p001-h200-h020)*fxpab
      result(4,1)=h100*bnormx
      result(7,1)=h010*bnormx
      result(9,1)=-p001*bnormx
      result(1,1)=anormx
      result(5,1)=anormx
      result(8,1)=-anormx-anormx
      anormx=fxpab*alphap(4)
      result(10,4)=(h200-h020)*anormx
      anormx=anormx+anormx
      h100=h100*anormx
      result(10,3)=h010*h001*anormx
      result(10,2)=h100*h001
      result(10,5)=h100*h010
      anormx=anormx*fa
      h100=h100*fa
      h010=h010*anormx
      result(4,2)=h001*anormx
      result(7,3)=result(4,2)
      result(9,2)=h100
      result(4,4)=h100
      result(7,5)=h100
      result(9,3)=h010
      result(4,5)=h010
      result(7,4)=-h010
      anormx=anormx*fa
      result(3,2)=anormx
      result(6,3)=anormx
      result(2,5)=anormx
      result(1,4)=anormx*0.5d0
      result(5,4)=-result(1,4)
      return
      end
c***./ add name=dfacpd
      subroutine dfacpd(expab,result)
      implicit REAL (a-h,o-z)
      dimension result(20,25)
      logical lscree
      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
c... to calculate expansion coefficients of products of solid
c... harmonics centred on a and b in lambda functions centred on p
c... p on a/d on b
      fx=-facx-facx
      fa=facb
      fb=faca
      h100=ba(1)*fx
      h010=ba(2)*fx
      h001=ba(3)*fx
      h110=h100*h010
      h101=h100*h001
      h011=h010*h001
      h200=h100*h100+fx
      h020=h010*h010+fx
      h002=h001*h001+fx
      h210=h200*h010
      h201=h200*h001
      h021=h020*h001
      h120=h020*h100
      h102=h002*h100
      h012=h002*h010
      p001=h001+h001
      p002=h002+h002
      fx=fx+fx
      h300=(h200+fx)*h100
      h030=(h020+fx)*h010
      result(20,1)=(h300+h120-h102*2.d0)*expab
      result(20,6)=(h030+h210-h012*2.d0)*expab
      result(20,11)=(h201+h021-(fx+h002)*p001)*expab
      bnormx=expab*fb
      anormx=expab*fa
      frod=anormx+anormx
      hobb=(p002-h200-h020)*bnormx
      result(10,1)=hobb+h200*frod
      result(16,6)=hobb+h020*frod
      result(19,11)=hobb-p002*frod
      result(16,1)=h110*frod
      result(10,6)=result(16,1)
      bilb=h101*frod
      frod=h011*frod
      result(10,11)=bilb
      result(16,11)=frod
      result(19,1)=-bilb-bilb
      result(19,6)=-frod-frod
      bnormx=-(bnormx+bnormx)*fa
      anormx=anormx*fa
      bilb=h100*bnormx
      frod=h010*bnormx
      hobb=-p001*bnormx
      x200=h100*anormx
      x020=h010*anormx
      x220=h001*anormx
      result(7,6)=bilb
      result(9,11)=bilb
      result(13,1)=x200
      result(18,1)=-x200-x200
      result(4,1)=x200+bilb
      result(7,1)=frod
      result(15,11)=frod
      result(4,6)=x020
      result(18,6)=-x020-x020
      result(13,6)=x020+frod
      result(9,1)=hobb
      result(15,6)=hobb
      result(4,11)=x220
      result(13,11)=x220
      result(18,11)=hobb-x220-x220
      bnormx=-bnormx*fa
      result(8,1)=bnormx
      result(14,6)=bnormx
      result(17,11)=bnormx
      bnormx=-bnormx*0.5d0
      result(1,1)=bnormx
      result(5,1)=bnormx
      result(2,6)=bnormx
      result(11,6)=bnormx
      result(3,11)=bnormx
      result(12,11)=bnormx
      anormx=expab*alphap(4)
      bnormx=anormx*fb
      result(20,4)=(h120-h300)*anormx
      result(20,9)=(h030-h210)*anormx
      result(20,14)=(h021-h201)*anormx
      anormx=-anormx-anormx
      result(20,2)=h201*anormx
      result(20,12)=h102*anormx
      result(20,8)=h021*anormx
      result(20,13)=h012*anormx
      result(20,5)=h210*anormx
      result(20,10)=h120*anormx
      bilb=h110*h001*anormx
      result(20,15)=bilb
      result(20,3)=bilb
      result(20,7)=bilb
      x220=(h200-h020)*bnormx
      bnormx=bnormx+bnormx
      result(19,14)=x220
      result(16,7)=h101*bnormx
      result(10,3)=h011*bnormx
      result(19,15)=h110*bnormx
      anormx=anormx*fa
      x200=h200*anormx
      x020=h020*anormx
      bilb=h011*anormx
      frod=h110*anormx
      hobb=h101*anormx
      result(10,12)=h002*anormx
      result(16,13)=result(10,12)
      result(19,2)=x200
      result(16,5)=x200
      result(10,4)=x220+x200
      result(19,8)=x020
      result(10,10)=x020
      result(16,9)=x220-x020
      result(10,7)=bilb
      result(10,15)=bilb
      result(16,14)=-bilb
      result(16,8)=result(10,3)+bilb
      result(19,13)=result(16,8)
      result(19,7)=frod
      result(19,3)=frod
      result(10,9)=frod
      result(16,4)=-frod
      result(10,5)=result(19,15)+frod
      result(16,10)=result(10,5)
      result(16,3)=hobb
      result(16,15)=hobb
      result(10,14)=hobb
      result(10,2)=result(16,7)+hobb
      result(19,12)=result(10,2)
      bnormx=bnormx*fa
      anormx=anormx*fa
      bilb=h100*bnormx
      frod=h010*bnormx
      hobb=h001*bnormx
      x200=h100*anormx
      x020=h010*anormx
      x220=h001*anormx
      result(15,7)=bilb
      result(18,12)=bilb
      result(7,9)=bilb
      result(9,14)=bilb
      result(13,10)=bilb
      result(15,15)=bilb
      result(15,3)=x200
      result(9,2)=bilb+x200
      result(7,5)=result(9,2)
      result(9,3)=frod
      result(18,13)=frod
      result(4,5)=frod
      result(9,15)=frod
      result(7,4)=-frod
      result(15,14)=-frod
      result(9,7)=x020
      result(15,8)=frod+x020
      result(7,10)=result(15,8)
      result(4,2)=hobb
      result(7,7)=hobb
      result(7,3)=hobb
      result(13,8)=hobb
      result(7,15)=x220
      result(15,13)=x220+hobb
      result(9,12)=result(15,13)
      result(13,4)=-x200*0.5d0
      result(4,4)=bilb-result(13,4)
      result(4,9)=x020*0.5d0
      result(13,9)=-frod-result(4,9)
      result(4,14)=x220*0.5d0
      result(13,14)=-result(4,14)
      bnormx=bnormx*fa
      result(3,2)=bnormx
      result(6,7)=bnormx
      result(8,12)=bnormx
      result(6,3)=bnormx
      result(12,8)=bnormx
      result(14,13)=bnormx
      result(2,5)=bnormx
      result(5,10)=bnormx
      result(6,15)=bnormx
      bnormx=bnormx*0.5d0
      result(3,14)=bnormx
      result(2,9)=bnormx
      result(1,4)=bnormx
      result(5,4)=-bnormx
      result(11,9)=-bnormx
      result(12,14)=-bnormx
      return
      end
c***./ add name=dfacpp
      subroutine dfacpp(expab,result)
      implicit REAL (a-h,o-z)
      dimension result(10,25)
      logical lscree
      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
      fx=facx+facx
      fy=fx*expab
      ab=faca*facb*expab
      h010=-ba(2)*fx
      h001=-ba(3)*fx
      g100=ba(1)*fy
      g010=ba(2)*fy
      g001=ba(3)*fy
      result(10,1)=fy-ba(1)*fx*g100
      result(10,6)=fy+h010*g010
      result(10,11)=fy+h001*g001
      result(10,3)=g100*h001
      result(10,9)=result(10,3)
      result(10,7)=g010*h001
      result(10,10)=result(10,7)
      result(10,2)=g100*h010
      result(10,5)=result(10,2)
      b100=g100*facb
      g100=-g100*faca
      result(7,2)=b100
      result(9,3)=b100
      result(4,1)=b100+g100
      result(7,5)=g100
      result(9,9)=g100
      b010=g010*facb
      g010=-g010*faca
      result(4,5)=b010
      result(9,7)=b010
      result(7,6)=b010+g010
      result(4,2)=g010
      result(9,10)=g010
      b001=g001*facb
      g001=-g001*faca
      result(4,9)=b001
      result(7,10)=b001
      result(9,11)=b001+g001
      result(4,3)=g001
      result(7,7)=g001
      result(1,1)=ab
      result(2,2)=ab
      result(3,3)=ab
      result(2,5)=ab
      result(5,6)=ab
      result(6,7)=ab
      result(3,9)=ab
      result(6,10)=ab
      result(8,11)=ab
      return
      end
c***./ add name=dfacqq
      subroutine dfacqq(expab,result)
      implicit REAL (a-h,o-z)
      dimension result(10,25)
      logical lscree
      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
      fx=facx+facx
      fy=fx*expab
      ab=faca*facb*expab
      h010=-ba(2)*fx
      h001=-ba(3)*fx
      g100=ba(1)*fy
      g010=ba(2)*fy
      g001=ba(3)*fy
      result(10,1)=fy-ba(1)*fx*g100
      result(10,5)=fy+h010*g010
      result(10,9)=fy+h001*g001
      result(10,3)=g100*h001
      result(10,7)=result(10,3)
      result(10,6)=g010*h001
      result(10,8)=result(10,6)
      result(10,2)=g100*h010
      result(10,4)=result(10,2)
      b100=g100*facb
      g100=-g100*faca
      result(7,2)=b100
      result(9,3)=b100
      result(4,1)=b100+g100
      result(7,4)=g100
      result(9,7)=g100
      b010=g010*facb
      g010=-g010*faca
      result(4,4)=b010
      result(9,6)=b010
      result(7,5)=b010+g010
      result(4,2)=g010
      result(9,8)=g010
      b001=g001*facb
      g001=-g001*faca
      result(4,7)=b001
      result(7,8)=b001
      result(9,9)=b001+g001
      result(4,3)=g001
      result(7,6)=g001
      result(1,1)=ab
      result(2,2)=ab
      result(3,3)=ab
      result(2,4)=ab
      result(5,5)=ab
      result(6,6)=ab
      result(3,7)=ab
      result(6,8)=ab
      result(8,9)=ab
      return
      end
c***./ add name=dfacsd
      subroutine dfacsd(expab,result)
      implicit REAL (a-h,o-z)
      dimension result(10,25)
      logical lscree
      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
c... to calculate expansion coefficients of products of solid
c... harmonics centred on a and b in lambda functions centred on p
c... s on a/d on b
      anormx=-(facx+facx)
      fxpab=expab
      fa=facb
      h100=ba(1)*anormx
      h010=ba(2)*anormx
      h001=ba(3)*anormx
      h200=h100*h100
      h020=h010*h010
      p001=h001+h001
      anormx=-fa*fxpab
      bnormx=anormx+anormx
      anormx=fa*anormx
      result(10,1)=(h001*p001-h200-h020)*fxpab
      result(4,1)=h100*bnormx
      result(7,1)=h010*bnormx
      result(9,1)=-p001*bnormx
      result(1,1)=anormx
      result(5,1)=anormx
      result(8,1)=-anormx-anormx
      anormx=fxpab*alphap(4)
      result(10,4)=(h200-h020)*anormx
      anormx=anormx+anormx
      h100=h100*anormx
      result(10,3)=h010*h001*anormx
      result(10,2)=h100*h001
      result(10,5)=h100*h010
      anormx=anormx*fa
      h100=h100*fa
      h010=h010*anormx
      result(4,2)=h001*anormx
      result(7,3)=result(4,2)
      result(9,2)=h100
      result(4,4)=h100
      result(7,5)=h100
      result(9,3)=h010
      result(4,5)=h010
      result(7,4)=-h010
      anormx=anormx*fa
      result(3,2)=anormx
      result(6,3)=anormx
      result(2,5)=anormx
      result(1,4)=anormx*0.5d0
      result(5,4)=-result(1,4)
      return
      end
c***./ add name=gaunov
      subroutine gaunov
      implicit REAL (a-h,o-z)
      parameter (amin=0.06d0)

INCLUDE(common/crys_params.hf77)     

      common/basato/
     * aznuc(lim016),xa(3,lim016),
     * che(lim015),exad(lim015+1),xl(3,lim015),
     * exx(lim042),c1(lim042),c2(lim042),c3(lim042),
     * cmax(lim042),c2w(lim042),c3w(lim042),
     * nat(lim016),nshpri(lim016+1),ipseud(lim016),
     * laa(lim015+1),lan(lim015),lat(lim015),latao(lim015),
     * ndq(lim015+1),latoat(lim015)

      parameter (limpar=50,limprn=200,limftn=100,limtol=50,liminf=200)
      common/parinf/par(limpar),lprint(limprn),iunit(limftn),
     *itol(limtol),inf(liminf),itit(20),iin,iout

      common/loco/cs(lim014),cp(lim014),cd(lim014)

      common/pqcon/fille(197),mille(4),gille(9),
     *pixy,pixy2,aln(3),gz(191),pha(50)

      laf=inf(20)
      init=1
      do 30 la=1,laf
      ifin=lan(la)
      bilbo=exx(init)
      ibase=init
      do 40 ni=1,ifin
      frodo=exx(ibase)
      bilbo=min(bilbo,frodo)
      cs(ni)=c1(ibase)*(frodo**0.75d0)
      cp(ni)=c2(ibase)*(frodo**1.25d0)
      cd(ni)=c3(ibase)*(frodo**1.75d0)
40    ibase=ibase+1
c     if(inf(3).ne.0.and.bilbo.lt.amin)call errvrs(1,'gaunov',
c    *'gaussian exponent less than 0.06 - it might be too diffuse')
      exad(la)=bilbo
      xnors=0.d0
      xnorp=0.d0
      xnord=0.d0
      ibase=init
      do 500 ni=1,ifin
      frodo=exx(ibase)
      jbase=init
      do 501 nj=1,ifin
      bilbo=2.d0/(frodo+exx(jbase))
      xnors=xnors+cs(ni)*cs(nj)*(bilbo**1.5d0)
      xnorp=xnorp+cp(ni)*cp(nj)*(bilbo**2.5d0)
      xnord=xnord+cd(ni)*cd(nj)*(bilbo**3.5d0)
501   jbase=jbase+1
500   ibase=ibase+1
      if(xnors.lt.(1d-14))xnors=1.d0
      if(xnorp.lt.(1d-14))xnorp=1.d0
      if(xnord.lt.(1d-14))xnord=1.d0
      ys=sqrt(1.d0/xnors)
      yp=sqrt(1.d0/xnorp)
      yd=sqrt(1.d0/xnord)
      xnors=aln(1)*ys
      xnorp=aln(2)*yp
      xnord=aln(3)*yd
      do 30 ni=1,ifin
      frodo=exx(init)
      cmax(init)=((frodo*40.d0)**0.75d0)*
     *    max(abs(c1(init))*ys,abs(c2(init))*yp,abs(c3(init))*yd)
      frodo=0.5d0/frodo
      c1(init)=cs(ni)*xnors
      c2(init)=cp(ni)*xnorp
      c3(init)=cd(ni)*xnord
      c2w(init)=c2(init)*frodo
      c3w(init)=c3(init)*frodo*frodo*0.5d0
c     c2w(init)=c2(init)
c     c3w(init)=c3(init)
30    init=init+1
      return
      end
      subroutine mxmb_crys(a,mcola,mrowa,b,mcolb,mrowb,
     *r,mcolr,mrowr,ncol,nlink,nrow)
      implicit REAL (a-h,o-z)
      dimension r(*),a(*),b(*)
c... r(ncol,nrow)=r(ncol,nrow)+a(ncol,nlink)*b(nlink,nrow) matrix mult
c... sparsity of b used
c... r    ****must****   be pre-initialized
      ncol2=ncol/2
      iaamax=nlink*mrowa+1
      mcola2=mcola+mcola
      mcolr2=mcolr+mcolr
      ir=1
      ib=1
                  if((ncol2+ncol2).eq.ncol)then
      do 1 j=1,nrow
      ibb=ib
      ia=1
101   if(ia.eq.iaamax)goto 9988
      fac1=b(ibb)
      iaa1=ia
      ibb=ibb+mcolb
      ia=ia+mrowa
      if(fac1)102,101,102
102   jr=ir+mcolr
      jaa1=iaa1+mcola
1022  if(ia.eq.iaamax)goto 301
      fac2=b(ibb)
      iaa2=ia
      ibb=ibb+mcolb
      ia=ia+mrowa
      if(fac2)103,1022,103
103   jaa2=iaa2+mcola
1033  if(ia.eq.iaamax)goto 302
      fac3=b(ibb)
      iaa3=ia
      ibb=ibb+mcolb
      ia=ia+mrowa
      if(fac3)104,1033,104
104   jaa3=iaa3+mcola
1044  if(ia.eq.iaamax)goto 303
      fac4=b(ibb)
      iaa4=ia
      ibb=ibb+mcolb
      ia=ia+mrowa
      if(fac4)105,1044,105
105   jaa4=iaa4+mcola
1055  if(ia.eq.iaamax)goto 304
      fac5=b(ibb)
      iaa5=ia
      ibb=ibb+mcolb
      ia=ia+mrowa
      if(fac5)106,1055,106
106   jaa5=iaa5+mcola
      irr=0
      iaa=0
      do 405 loop=1,ncol2
      s1       =r(ir+irr)+fac1*a(iaa1+iaa)+fac2*a(iaa2+iaa)
     *                   +fac3*a(iaa3+iaa)+fac4*a(iaa4+iaa)
     *                   +fac5*a(iaa5+iaa)
      s2       =r(jr+irr)+fac1*a(jaa1+iaa)+fac2*a(jaa2+iaa)
     *                   +fac3*a(jaa3+iaa)+fac4*a(jaa4+iaa)
     *                   +fac5*a(jaa5+iaa)
      r(ir+irr)=s1
      r(jr+irr)=s2
      irr=irr+mcolr2
405   iaa=iaa+mcola2
      goto 101
304   irr=0
      iaa=0
      do 404 loop=1,ncol2
      s1       =r(ir+irr)+fac1*a(iaa1+iaa)+fac2*a(iaa2+iaa)
     *                   +fac3*a(iaa3+iaa)+fac4*a(iaa4+iaa)
      s2       =r(jr+irr)+fac1*a(jaa1+iaa)+fac2*a(jaa2+iaa)
     *                   +fac3*a(jaa3+iaa)+fac4*a(jaa4+iaa)
      r(ir+irr)=s1
      r(jr+irr)=s2
      irr=irr+mcolr2
404   iaa=iaa+mcola2
      goto 9988
303   irr=0
      iaa=0
      do 403 loop=1,ncol2
      s1       =r(ir+irr)+fac1*a(iaa1+iaa)+fac2*a(iaa2+iaa)
     *                   +fac3*a(iaa3+iaa)
      s2       =r(jr+irr)+fac1*a(jaa1+iaa)+fac2*a(jaa2+iaa)
     *                   +fac3*a(jaa3+iaa)
      r(ir+irr)=s1
      r(jr+irr)=s2
      irr=irr+mcolr2
403   iaa=iaa+mcola2
      goto 9988
302   irr=0
      iaa=0
      do 402 loop=1,ncol2
      s1       =r(ir+irr)+fac1*a(iaa1+iaa)+fac2*a(iaa2+iaa)
      s2       =r(jr+irr)+fac1*a(jaa1+iaa)+fac2*a(jaa2+iaa)
      r(ir+irr)=s1
      r(jr+irr)=s2
      irr=irr+mcolr2
402   iaa=iaa+mcola2
      goto 9988
301   irr=0
      iaa=0
      do 401 loop=1,ncol2
      s1       =r(ir+irr)+fac1*a(iaa1+iaa)
      s2       =r(jr+irr)+fac1*a(jaa1+iaa)
      r(ir+irr)=s1
      r(jr+irr)=s2
      irr=irr+mcolr2
401   iaa=iaa+mcola2
9988  ir=ir+mrowr
1     ib=ib+mrowb
                              else
      krr=ncol2*mcolr2
      kaa=ncol2*mcola2
      do 2 j=1,nrow
      ibb=ib
      ia=1
111   if(ia.eq.iaamax)goto 9977
      fac1=b(ibb)
      iaa1=ia
      ibb=ibb+mcolb
      ia=ia+mrowa
      if(fac1)112,111,112
112   jr=ir+mcolr
      jaa1=iaa1+mcola
      if(ia.eq.iaamax)goto 331
      fac2=b(ibb)
      iaa2=ia
      ibb=ibb+mcolb
      ia=ia+mrowa
      if(fac2)113,112,113
113   jaa2=iaa2+mcola
1133  if(ia.eq.iaamax)goto 332
      fac3=b(ibb)
      iaa3=ia
      ibb=ibb+mcolb
      ia=ia+mrowa
      if(fac3)114,1133,114
114   jaa3=iaa3+mcola
1144  if(ia.eq.iaamax)goto 333
      fac4=b(ibb)
      iaa4=ia
      ibb=ibb+mcolb
      ia=ia+mrowa
      if(fac4)115,1144,115
115   jaa4=iaa4+mcola
1155  if(ia.eq.iaamax)goto 334
      fac5=b(ibb)
      iaa5=ia
      ibb=ibb+mcolb
      ia=ia+mrowa
      if(fac5)116,1155,116
116   jaa5=iaa5+mcola
      irr=0
      iaa=0
      do 445 loop=1,ncol2
      s1       =r(ir+irr)+fac1*a(iaa1+iaa)+fac2*a(iaa2+iaa)
     *                   +fac3*a(iaa3+iaa)+fac4*a(iaa4+iaa)
     *                   +fac5*a(iaa5+iaa)
      s2       =r(jr+irr)+fac1*a(jaa1+iaa)+fac2*a(jaa2+iaa)
     *                   +fac3*a(jaa3+iaa)+fac4*a(jaa4+iaa)
     *                   +fac5*a(jaa5+iaa)
      r(ir+irr)=s1
      r(jr+irr)=s2
      irr=irr+mcolr2
445   iaa=iaa+mcola2
      r(ir+krr)=r(ir+krr)+fac1*a(iaa1+kaa)+fac2*a(iaa2+kaa)
     *                   +fac3*a(iaa3+kaa)+fac4*a(iaa4+kaa)
     *                   +fac5*a(iaa5+kaa)
      goto 111
334   irr=0
      iaa=0
      do 444 loop=1,ncol2
      s1       =r(ir+irr)+fac1*a(iaa1+iaa)+fac2*a(iaa2+iaa)
     *                   +fac3*a(iaa3+iaa)+fac4*a(iaa4+iaa)
      s2       =r(jr+irr)+fac1*a(jaa1+iaa)+fac2*a(jaa2+iaa)
     *                   +fac3*a(jaa3+iaa)+fac4*a(jaa4+iaa)
      r(ir+irr)=s1
      r(jr+irr)=s2
      irr=irr+mcolr2
444   iaa=iaa+mcola2
      r(ir+krr)=r(ir+krr)+fac1*a(iaa1+kaa)+fac2*a(iaa2+kaa)
     *                   +fac3*a(iaa3+kaa)+fac4*a(iaa4+kaa)
      goto 9977
333   irr=0
      iaa=0
      do 443 loop=1,ncol2
      s1       =r(ir+irr)+fac1*a(iaa1+iaa)+fac2*a(iaa2+iaa)
     *                   +fac3*a(iaa3+iaa)
      s2       =r(jr+irr)+fac1*a(jaa1+iaa)+fac2*a(jaa2+iaa)
     *                   +fac3*a(jaa3+iaa)
      r(ir+irr)=s1
      r(jr+irr)=s2
      irr=irr+mcolr2
443   iaa=iaa+mcola2
      r(ir+krr)=r(ir+krr)+fac1*a(iaa1+kaa)+fac2*a(iaa2+kaa)
     *                   +fac3*a(iaa3+kaa)
      goto 9977
332   irr=0
      iaa=0
      do 442 loop=1,ncol2
      s1       =r(ir+irr)+fac1*a(iaa1+iaa)+fac2*a(iaa2+iaa)
      s2       =r(jr+irr)+fac1*a(jaa1+iaa)+fac2*a(jaa2+iaa)
      r(ir+irr)=s1
      r(jr+irr)=s2
      irr=irr+mcolr2
442   iaa=iaa+mcola2
      r(ir+krr)=r(ir+krr)+fac1*a(iaa1+kaa)+fac2*a(iaa2+kaa)
      goto 9977
331   irr=0
      iaa=0
      do 441 loop=1,ncol2
      s1       =r(ir+irr)+fac1*a(iaa1+iaa)
      s2       =r(jr+irr)+fac1*a(jaa1+iaa)
      r(ir+irr)=s1
      r(jr+irr)=s2
      irr=irr+mcolr2
441   iaa=iaa+mcola2
      r(ir+krr)=r(ir+krr)+fac1*a(iaa1+kaa)
9977  ir=ir+mrowr
2     ib=ib+mrowb
                            endif
      return
      end
c***./ add name=polipa
      subroutine polipa(l1,l2,idipo,s,xt,yt,zt)
c...
c... poles to l=6 can be used ---- vrs 14 jan 1983
c...
      implicit REAL (a-h,o-z)

INCLUDE(common/basato.hf77)

      dimension itype(4),x11(3),s(*)
      logical lscree

      common/dfacom/alphap(4),facx,faca,facb,rsquar,ba(3),
     *i4base(4),lscree
      common/tcomm/accfac,expacc,rpi
      common/icon/iky(50),miky(50)
      common/pqcon/fille(197),mille(4),gille(9),
     *pixy,pixy2,aln(3),gz(191),pha(50),factvs(35)
      common/loco/p(3),e1(35),e2(35),f1(35),f2(35),cfac1(35*25),
     *cfac2(25,35),ev(35,13,2)
      common/moncon/apole(200),ipole(200),jpole(200),
     *kpole(200),mpole(50),bilb(25),frod(25)

      data x11/3*0.d0/
      data itype/1,2,2,3/
c
c
c     do i=1,4
c       write(6,*) alphap(i)
c     enddo
c
c
      idipm1=idipo-1
      idipp1=idipo+1
      mocf=latao(l1)*latao(l2)
      mocfn=mocf*idipp1*idipp1
      mocf4=mocf*4
      do 6 i=1,mocfn
    6 s(i)=0.d0
      l2pbas=laa(l2)
      l2pupp=laa(l2+1)-1
      itypea=lat(l1)+1
      maxp4=lat(l2)+1
      maxpp1=itype(itypea)+itype(maxp4)
      itypea=i4base(itypea)+maxp4
      maxp=maxpp1-1
      maxpm1=maxpp1-2
      maxpm2=maxp-2
      maxmum=min(maxp,idipp1)
      nmayp=miky(maxp)
      nmaxp=miky(maxpp1)
      maxp4=min(nmaxp,4)
c========loop over primitives in shell 1======
      do 10012 mprima=laa(l1),laa(l1+1)-1
c========loop over primitives in shell 2======
        do 10012 mprimb=l2pbas,l2pupp
          call dfac3(mprima,mprimb,x11,itypea,cfac1,p)
c         do i=1,35*25
c           write(6,*) 'cfac:',cfac1(i)
c         enddo
          if(lscree)goto 10012
c...
c... overlap integrals
c...
          basint=alphap(3)*rpi
      nikyi=0
_IF1(ct)cdir$ shortloop
      do 10099 loop=1,mocf
      nikyi=nikyi+nmaxp
10099 s(loop)=cfac1(nikyi)*basint+s(loop)
      if(idipm1.lt.0)goto 10012
c...
c...  dipole integrals
c...
      vrs3=p(3)-zt
      vrs2=p(2)-yt
      vrs1=p(1)-xt
      ev(1,1,2)=vrs3*basint
      ev(1,2,2)=vrs1*basint
      ev(1,3,2)=vrs2*basint
      ev(4,1,2)=basint
      ev(2,2,2)=basint
      ev(3,3,2)=basint
      ev(2,1,2)=0.d0
      ev(3,1,2)=0.d0
      ev(3,2,2)=0.d0
      ev(4,2,2)=0.d0
      ev(2,3,2)=0.d0
      ev(4,3,2)=0.d0
      loop=0
      do 3040 iorder=1,maxmum
      ikymu=maxpp1-iorder
      do 3040 mu=1,iorder
      mikyi=miky(ikymu+mu-1)+ikymu
      do 3040 nu=1,mu
      loop=loop+1
      nikyi=iky(ikymu+nu-1)+mikyi
      top=factvs(loop)
_IF1(ct)cdir$ shortloop
      do 3040 moc=1,mocf
      cfac2(moc,loop)=cfac1(nikyi)*top
3040  nikyi=nikyi+nmaxp
      call mxmb_crys(cfac2,1,25,ev(1,1,2),1,35,s(mocf+1),1,mocf,
     *mocf,maxp4,3)
      if(idipm1.eq.0)goto 10012
c...
c... quadrupole and higher pole integrals
c...
      inew=2
      iold=1
      lmqu=0
      ibase=mocf4
      ev(1,1,1)=basint
      vrs4=vrs1*vrs1+vrs2*vrs2+vrs3*vrs3
      wrs1=vrs1+vrs1
      wrs2=vrs2+vrs2
      wrs3=vrs3+vrs3
      do 3002 lqu11=2,idipo
      lqu=min(lqu11+1,maxp)
      lqu1=min(lqu11,maxp)
      lqu2=min(lqu11-1,maxp)
      maxtop=miky(lqu+1)
      maxtwo=miky(lqu2+1)
      maxone=miky(lqu1+1)
      mqu2=min(lqu2,maxpm2)
      lqu2=min(lqu2,maxpm1)
      mqu1=min(lqu1,maxpm1)
c...
c...    m=zero   case
c...
_IF1(ct)cdir$ shortloop
      do 3003 loop=1,maxtop
      e2(loop)=0.d0
3003  e1(loop)=0.d0
      loop=0
      do 3005 iorder=1,mqu2
      mikyi=miky(iorder+2)
      nikyi=miky(iorder+1)
      do 3005 mu=1,iorder
      mik2=mikyi+iky(mu+2)
      ikymu=iky(mu)
      nik1=nikyi+ikymu
      mik1=mikyi+ikymu
      nik2=nik1+mu
      do 3005 nu=1,mu
      loop=loop+1
      top=ev(loop,1,iold)
      e2(nik1+nu)=wrs1*top+e2(nik1+nu)
      e2(nik2+nu)=wrs2*top+e2(nik2+nu)
      e2(nik2+nu+1)=wrs3*top+e2(nik2+nu+1)
      e2(mik1+nu)=top+e2(mik1+nu)
      e2(mik2+nu)=top+e2(mik2+nu)
3005  e2(mik2+nu+2)=top
      if(lqu2.eq.maxpm1)then
      do 4005 mu=1,maxpm1
      nik1=iky(mu)+nmayp
      nik2=nik1+mu
      do 4005 nu=1,mu
      loop=loop+1
      top=ev(loop,1,iold)
      e2(nik1+nu)=wrs1*top+e2(nik1+nu)
      e2(nik2+nu)=wrs2*top+e2(nik2+nu)
4005  e2(nik2+nu+1)=wrs3*top+e2(nik2+nu+1)
      endif
_IF1(ct)cdir$ shortloop
      do 5005 loop=1,maxtwo
5005  e2(loop)=ev(loop,1,iold)*vrs4+e2(loop)
      loop=0
      do 3006 iorder=1,mqu1
      mikyi=miky(iorder+1)
      do 3006 mu=1,iorder
      mik2=mikyi+iky(mu+1)
_IF1(ct)cdir$ shortloop
      do 3006 nu=1,mu
      loop=loop+1
3006  e1(mik2+nu+1)=ev(loop,1,inew)
_IF1(ct)cdir$ shortloop
      do 4006 loop=1,maxone
4006  e1(loop)=ev(loop,1,inew)*vrs3+e1(loop)
      lmqu=lmqu+1
      bilbo=bilb(lmqu)
      frodo=frod(lmqu)
_IF1(ct)cdir$ shortloop
      do 3014 loop=1,maxtop
3014  ev(loop,1,iold)=e1(loop)*bilbo+e2(loop)*frodo
c...
c... m finite    m.lt.l   cases
c...
      mpos=2
      do 3015 mqu=2,lqu11
_IF1(ct)cdir$ shortloop
      do 3016 loop=1,maxtop
      e1(loop)=0.d0
3016  f1(loop)=0.d0
      mneg=mpos+1
      lmqu=lmqu+1
      basint=bilb(lmqu)
      loop=0
      do 3026 iorder=1,mqu1
      mikyi=miky(iorder+1)
      do 3026 mu=1,iorder
      mik2=mikyi+iky(mu+1)
_IF1(ct)cdir$ shortloop
      do 3026 nu=1,mu
      loop=loop+1
      e1(mik2+nu+1)=ev(loop,mpos,inew)
3026  f1(mik2+nu+1)=ev(loop,mneg,inew)
_IF1(ct)cdir$ shortloop
      do 4026 loop=1,maxone
      e1(loop)=ev(loop,mpos,inew)*vrs3+e1(loop)
4026  f1(loop)=ev(loop,mneg,inew)*vrs3+f1(loop)
      if(mqu.ne.lqu11)then
_IF1(ct)cdir$ shortloop
      do 4016 loop=1,maxtop
      e2(loop)=0.d0
4016  f2(loop)=0.d0
      loop=0
      do 3025 iorder=1,mqu2
      mikyi=miky(iorder+2)
      nikyi=miky(iorder+1)
      do 3025 mu=1,iorder
      ikymu=iky(mu)
      mik1=mikyi+ikymu
      nik1=nikyi+ikymu
      mik2=iky(mu+2)+mikyi
      nik2=nik1+mu
      do 3025 nu=1,mu
      loop=loop+1
      top=ev(loop,mpos,iold)
      bot=ev(loop,mneg,iold)
      e2(nik1+nu)=wrs1*top+e2(nik1+nu)
      f2(nik1+nu)=wrs1*bot+f2(nik1+nu)
      e2(nik2+nu)=wrs2*top+e2(nik2+nu)
      f2(nik2+nu)=wrs2*bot+f2(nik2+nu)
      e2(nik2+nu+1)=wrs3*top+e2(nik2+nu+1)
      f2(nik2+nu+1)=wrs3*bot+f2(nik2+nu+1)
      e2(mik1+nu)=top+e2(mik1+nu)
      f2(mik1+nu)=bot+f2(mik1+nu)
      e2(mik2+nu)=top+e2(mik2+nu)
      f2(mik2+nu)=bot+f2(mik2+nu)
      e2(mik2+nu+2)=top
3025  f2(mik2+nu+2)=bot
      if(lqu2.eq.maxpm1)then
      do 4025 mu=1,maxpm1
      ikymu=iky(mu)
      nik1=iky(mu)+nmayp
      nik2=nik1+mu
      do 4025 nu=1,mu
      loop=loop+1
      top=ev(loop,mpos,iold)
      bot=ev(loop,mneg,iold)
      e2(nik1+nu)=wrs1*top+e2(nik1+nu)
      f2(nik1+nu)=wrs1*bot+f2(nik1+nu)
      e2(nik2+nu)=wrs2*top+e2(nik2+nu)
      f2(nik2+nu)=wrs2*bot+f2(nik2+nu)
      e2(nik2+nu+1)=wrs3*top+e2(nik2+nu+1)
4025  f2(nik2+nu+1)=wrs3*bot+f2(nik2+nu+1)
      endif
_IF1(ct)cdir$ shortloop
      do 5025 loop=1,maxtwo
      e2(loop)=ev(loop,mpos,iold)*vrs4+e2(loop)
5025  f2(loop)=ev(loop,mneg,iold)*vrs4+f2(loop)
      frodo=frod(lmqu)
_IF1(ct)cdir$ shortloop
      do 3030 loop=1,maxtop
      ev(loop,mpos,iold)=e1(loop)*basint+e2(loop)*frodo
3030  ev(loop,mneg,iold)=f1(loop)*basint+f2(loop)*frodo
      else
_IF1(ct)cdir$ shortloop
      do 4030 loop=1,maxtop
      ev(loop,mpos,iold)=e1(loop)*basint
4030  ev(loop,mneg,iold)=f1(loop)*basint
      endif
3015  mpos=mpos+2
c...
c...      m=l    case
c...
      mneg=mpos+1
      npos=mpos-2
      nneg=mpos-1
_IF1(ct)cdir$ shortloop
      do 3200 loop=1,maxtop
      e1(loop)=0.d0
3200  f1(loop)=0.d0
      do 3201 iorder=1,mqu1
      mikyi=miky(iorder+1)
      nikyi=miky(iorder)
      do 3201 mu=1,iorder
      ikymu=iky(mu)
      nik2=nikyi+ikymu
      mik2=mikyi+ikymu
      top=ev(nik2+1,npos,inew)
      bot=ev(nik2+1,nneg,inew)
      e1(nik2+1)=vrs1*top-vrs2*bot+e1(nik2+1)
      f1(nik2+1)=vrs1*bot+vrs2*top+f1(nik2+1)
      mik1=mik2+mu
      e1(mik2+1)=top+e1(mik2+1)
      f1(mik2+1)=bot+f1(mik2+1)
      e1(mik1+1)=-bot
3201  f1(mik1+1)=top
      if(lqu1.eq.maxp)then
      do 4201 mu=1,maxp
      nik2=iky(mu)+nmayp
      top=ev(nik2+1,npos,inew)
      bot=ev(nik2+1,nneg,inew)
      e1(nik2+1)=vrs1*top-vrs2*bot+e1(nik2+1)
4201  f1(nik2+1)=vrs1*bot+vrs2*top+f1(nik2+1)
      endif
      lmqu=lmqu+1
      bilbo=bilb(lmqu)
_IF1(ct)cdir$ shortloop
      do 3220 loop=1,maxtop
      ev(loop,mpos,iold)=e1(loop)*bilbo
3220  ev(loop,mneg,iold)=f1(loop)*bilbo
      call mxmb_crys(cfac2,1,25,ev(1,1,iold),1,35,s(ibase+1),1,mocf,
     * mocf,maxtop,mneg)
      loop=inew
      inew=iold
      iold=loop
3002  ibase=mocf*mneg+ibase
10012 continue
      return
      end
c***./ add name=rcals
      subroutine rcals(r)
      implicit REAL (a-h,o-z)
      dimension r(*)
      common/pqcon/pq(3),alpha,t4,apaq,f(0:189),
     *amp1,mmaxm1,mmax
c... compute the mcmurchie/davidson r(n,l,m) integrals
      pq1=pq(1)
      pq2=pq(2)
      pq3=pq(3)
c     write(6,*) 'pqs:',pq(1),pq(2),pq(3),mmax
      goto (11111,22222,33333,44444,55555,66666,77777,
     *      88888,9999,99999,99999),mmax
c...
c... general case
c...
99999 call zcals(r)
      return
c... m=8
9999  call zcals8(r)
      return
c... m=7
88888 call zcals7(r)
      return
c... m=0
11111 r(1)=f(0)
      return
c... m=1
22222 r(1)=f(1)*pq1
      r(2)=f(1)*pq2
      r(3)=f(1)*pq3
      r(4)=f(0)
      return
c... m=2
33333 aii=pq1*f(2)
      ajj=pq2*f(2)
      r(9)=pq3*f(1)
      r(8)=pq3*pq3*f(2)+f(1)
      r(7)=pq2*f(1)
      r(6)=ajj*pq3
      r(5)=ajj*pq2+f(1)
      r(4)=pq1*f(1)
      r(3)=aii*pq3
      r(2)=aii*pq2
      r(1)=aii*pq1+f(1)
      r(10)=f(0)
      return
c... m=3
44444 aii=pq1*pq1
      aij=pq1*pq2
      ajj=pq2*pq2
      ekk=f(2)*pq3
      fkk=f(3)*pq3
      f32=f(2)+f(2)
      cii=aii*f(3)+f(2)
      cjj=ajj*f(3)+f(2)
      ckk=fkk*pq3+f(2)
      r(7)=f(2)*aij
      r(6)=fkk*aij
      r(17)=(ckk+f32)*pq3
      r(1)=(cii+f32)*pq1
      r(11)=(cjj+f32)*pq2
      r(2)=cii*pq2
      r(3)=cii*pq3
      r(12)=cjj*pq3
      r(5)=cjj*pq1
      r(8)=ckk*pq1
      r(14)=ckk*pq2
      r(16)=f(1)*pq2
      r(19)=f(1)*pq3
      r(10)=f(1)*pq1
      r(9)=ekk*pq1
      r(15)=ekk*pq2
      r(18)=ekk*pq3+f(1)
      r(4)=f(2)*aii+f(1)
      r(13)=f(2)*ajj+f(1)
      r(20)=f(0)
      return
c... m=4
55555 aii=pq1*pq1
      aij=pq1*pq2
      ajj=pq2*pq2
      ajk=pq2*pq3
      aik=pq1*pq3
      akk=pq3*pq3
      f42=f(3)+f(3)
      f32=f(2)+f(2)
      cii=aii*f(3)+f(2)
      cjj=ajj*f(3)+f(2)
      ckk=akk*f(3)+f(2)
      eii=aii*f(4)+f(3)
      ejj=ajj*f(4)+f(3)
      ekk=akk*f(4)+f(3)
      fii=eii+f42
      fjj=ejj+f42
      fkk=ekk+f42
      r(35)=f(0)
      r(34)=pq3*f(1)
      r(33)=akk*f(2)+f(1)
      r(32)=(ckk+f32)*pq3
      r(31)=fkk*akk+ckk*3.d0
      r(30)=pq2*f(1)
      r(29)=ajk*f(2)
      r(28)=ckk*pq2
      r(27)=fkk*ajk
      r(26)=ajj*f(2)+f(1)
      r(25)=cjj*pq3
      r(24)=ejj*akk+cjj
      r(23)=(cjj+f32)*pq2
      r(22)=fjj*ajk
      r(21)=fjj*ajj+cjj*3.d0
      r(20)=pq1*f(1)
      r(19)=aik*f(2)
      r(18)=ckk*pq1
      r(17)=fkk*aik
      r(16)=aij*f(2)
      r(15)=aij*pq3*f(3)
      r(14)=ekk*aij
      r(13)=cjj*pq1
      r(12)=ejj*aik
      r(11)=fjj*aij
      r(10)=aii*f(2)+f(1)
      r(9)=cii*pq3
      r(8)=ekk*aii+ckk
      r(7)=cii*pq2
      r(6)=eii*ajk
      r(5)=ejj*aii+cjj
      r(4)=(cii+f32)*pq1
      r(3)=fii*aik
      r(2)=fii*aij
      r(1)=fii*aii+cii*3.d0
      return
c... m=5
66666 aii=pq1*pq1
      aij=pq1*pq2
      ajj=pq2*pq2
      ajk=pq2*pq3
      aik=pq1*pq3
      akk=pq3*pq3
      f52=f(4)+f(4)
      f42=f(3)+f(3)
      f32=f(2)+f(2)
      cii=aii*f(3)+f(2)
      cjj=ajj*f(3)+f(2)
      ckk=akk*f(3)+f(2)
      eii=aii*f(4)+f(3)
      ejj=ajj*f(4)+f(3)
      ekk=akk*f(4)+f(3)
      fii=(eii+f42)*pq1
      fjj=(ejj+f42)*pq2
      fkk=(ekk+f42)*pq3
      hjj=ajj*f(5)+f(4)
      hkk=akk*f(5)+f(4)
      pii=(aii*f(5)+f(4)+f52)*pq1
      pjj=(hjj+f52)*pq2
      pkk=(hkk+f52)*pq3
      qii=pii*pq1+eii*3.d0
      qjj=pjj*pq2+ejj*3.d0
      qkk=pkk*pq3+ekk*3.d0
      r(56)=f(0)
      r(55)=f(1)*pq3
      r(54)=akk*f(2)+f(1)
      r(53)=(ckk+f32)*pq3
      r(52)=fkk*pq3+ckk*3.d0
      r(51)=fkk*4.d0+qkk*pq3
      r(50)=f(1)*pq2
      r(49)=f(2)*ajk
      r(48)=ckk*pq2
      r(47)=fkk*pq2
      r(46)=qkk*pq2
      r(45)=ajj*f(2)+f(1)
      r(44)=cjj*pq3
      r(43)=ekk*ajj+ckk
      r(41)=(cjj+f32)*pq2
      r(39)=pjj*akk+fjj
      r(38)=fjj*pq2+cjj*3.d0
      r(36)=fjj*4.d0+qjj*pq2
      r(35)=f(1)*pq1
      r(33)=ckk*pq1
      r(31)=qkk*pq1
      r(30)=f(2)*aij
      r(28)=ekk*aij
      r(26)=cjj*pq1
      r(24)=(hkk*ajj+ekk)*pq1
      r(23)=fjj*pq1
      r(21)=qjj*pq1
      r(20)=f(2)*aii+f(1)
      r(18)=ekk*aii+ckk
      r(16)=cii*pq2
      r(14)=(hkk*aii+ekk)*pq2
      r(13)=ejj*aii+cjj
      r(11)=pjj*aii+fjj
      r(10)=(cii+f32)*pq1
      r(8)=pii*akk+fii
      r(7)=fii*pq2
      r(5)=pii*ajj+fii
      r(4)=fii*pq1+cii*3.d0
      r(42)=pkk*ajj+fkk
      r(40)=fjj*pq3
      r(37)=qjj*pq3
      r(34)=f(2)*aik
      r(32)=fkk*pq1
      r(29)=f(3)*aij*pq3
      r(27)=pkk*aij
      r(25)=ejj*aik
      r(22)=pjj*aik
      r(19)=cii*pq3
      r(17)=pkk*aii+fkk
      r(15)=eii*ajk
      r(12)=(hjj*aii+ejj)*pq3
      r(9)=fii*pq3
      r(6)=pii*ajk
      r(3)=qii*pq3
      r(2)=qii*pq2
      r(1)=fii*4.d0+qii*pq1
      return
c... m=6
77777 aii=pq1*pq1
      aij=pq1*pq2
      ajj=pq2*pq2
      ajk=pq2*pq3
      aik=pq1*pq3
      akk=pq3*pq3
      aijk=aij*pq3
      f63=f(5)*3.d0
      f52=f(4)+f(4)
      f42=f(3)+f(3)
      f32=f(2)+f(2)
      cii=aii*f(3)+f(2)
      cjj=ajj*f(3)+f(2)
      ckk=akk*f(3)+f(2)
      eii=aii*f(4)+f(3)
      ejj=ajj*f(4)+f(3)
      ekk=akk*f(4)+f(3)
      fii=eii+f42
      fjj=ejj+f42
      fkk=ekk+f42
      hii=aii*f(5)+f(4)
      hjj=ajj*f(5)+f(4)
      hkk=akk*f(5)+f(4)
      pii=hii+f52
      pjj=hjj+f52
      pkk=hkk+f52
      qii=pii*aii+eii*3.d0
      qjj=pjj*ajj+ejj*3.d0
      qkk=pkk*akk+ekk*3.d0
      pkk2=pkk+pkk
      bilbo=f(6)*akk
      tii=f(6)*aii+f63
      tjj=f(6)*ajj+f63
      tkk=bilbo+f63
      hkj=hkk*ajj+ekk
      uii=tii*aii+hii*3.d0
      ujj=tjj*ajj+hjj*3.d0
      ukk=tkk*akk+hkk*3.d0
      tji=tjj*aii+pjj
      tkj=tkk*ajj+pkk
      tki=tkk*aii+pkk
      wii=pii*4.d0+uii
      wjj=pjj*4.d0+ujj
      wkk=pkk*4.d0+ukk
      r(84)=f(0)
      r(83)=f(1)*pq3
      r(82)=akk*f(2)+f(1)
      r(81)=(ckk+f32)*pq3
      r(80)=fkk*akk+ckk*3.d0
      r(79)=(fkk*4.d0+qkk)*pq3
      r(78)=wkk*akk+qkk*5.d0
      r(77)=f(1)*pq2
      r(76)=f(2)*ajk
      r(75)=ckk*pq2
      r(74)=fkk*ajk
      r(73)=qkk*pq2
      r(72)=wkk*ajk
      r(71)=ajj*f(2)+f(1)
      r(70)=cjj*pq3
      r(69)=ekk*ajj+ckk
      r(68)=(pkk*ajj+fkk)*pq3
      r(67)=ukk*ajj+qkk
      r(66)=(cjj+f32)*pq2
      r(65)=fjj*ajk
      r(64)=(pjj*akk+fjj)*pq2
      r(63)=(tkj+pkk2)*ajk
      r(62)=fjj*ajj+cjj*3.d0
      r(61)=qjj*pq3
      r(60)=ujj*akk+qjj
      r(59)=(fjj*4.d0+qjj)*pq2
      r(57)=wjj*ajj+qjj*5.d0
      r(56)=f(1)*pq1
      r(55)=f(2)*aik
      r(54)=ckk*pq1
      r(53)=fkk*aik
      r(52)=qkk*pq1
      r(51)=wkk*aik
      r(50)=f(2)*aij
      r(48)=ekk*aij
      r(46)=ukk*aij
      r(45)=cjj*pq1
      r(43)=hkj*pq1
      r(41)=fjj*aij
      r(39)=(tjj*akk+pjj)*aij
      r(38)=qjj*pq1
      r(36)=wjj*aij
      r(35)=f(2)*aii+f(1)
      r(33)=ekk*aii+ckk
      r(31)=ukk*aii+qkk
      r(30)=cii*pq2
      r(28)=(hkk*aii+ekk)*pq2
      r(26)=ejj*aii+cjj
      r(24)=((bilbo+f(5))*ajj+hkk)*aii+hkj
      r(23)=(pjj*aii+fjj)*pq2
      r(21)=ujj*aii+qjj
      r(20)=(cii+f32)*pq1
      r(18)=(pii*akk+fii)*pq1
      r(16)=fii*aij
      r(14)=(tii*akk+pii)*aij
      r(13)=(pii*ajj+fii)*pq1
      r(11)=(pjj*2.d0+tji)*aij
      r(10)=fii*aii+cii*3.d0
      r(8)=uii*akk+qii
      r(7)=qii*pq2
      r(5)=uii*ajj+qii
      r(4)=(fii*4.d0+qii)*pq1
      r(58)=wjj*ajk
      r(49)=f(3)*aijk
      r(47)=pkk*aijk
      r(44)=ejj*aik
      r(42)=tkj*aik
      r(40)=pjj*aijk
      r(37)=ujj*aik
      r(34)=cii*pq3
      r(32)=(pkk*aii+fkk)*pq3
      r(29)=eii*ajk
      r(27)=tki*ajk
      r(25)=(hjj*aii+ejj)*pq3
      r(22)=tji*ajk
      r(19)=fii*aik
      r(17)=(tki+pkk2)*aik
      r(15)=pii*aijk
      r(12)=(tii*ajj+pii)*aik
      r(9)=qii*pq3
      r(6)=uii*ajk
      r(3)=wii*aik
      r(2)=wii*aij
      r(1)=wii*aii+qii*5.d0
      return
      end
c***./ add name=zcals
      subroutine zcals(r)
      implicit REAL (a-h,o-z)
      dimension r(*)
      common/icon/iky(0:49),miky(0:49)
      common/pqcon/pq(3),alpha,t4,apaq,f(0:26),x1(0:10),y1(0:10),
     * z1(0:10),x2(0:9),y2(0:9),z2(0:9),zx1(0:7),yx1(0:7),
     * xy1(0:7),xz1(0:7),yz1(0:7),
     * zx2(0:6),yx2(0:6),xy2(0:6),xz2(0:6),yz2(0:6),
     * zgap(25),amp1,mmaxm1,mmax
c... compute the mcmurchie/davidson r(n,l,m) integrals
      mv=mmaxm1
      pq3=pq(3)
      pq2=pq(2)
      pq1=pq(1)
      akk=pq3*pq3
      ajk=pq2*pq3
      ajj=pq2*pq2
      aik=pq1*pq3
      aij=pq1*pq2
      aii=pq1*pq1
      aijk=pq1*ajk
      mx=mv-1
      my=mv-2
      mu=mv-3
      i10=miky(mv)
      ikymw=iky(mv+1)
      ikymy=iky(my)
      iz=i10+ikymw
      ikymx=ikymy+mx
      i11=i10-mv
      ikymv=ikymx+mv
      n02=i10+ikymx
      i01=i10+ikymv
      n20=i10-ikymv
c...      k = 1
      yyyyy=f(2)
      r(i11-1)=f(3)*aijk
      r(i11)=yyyyy*aij
      r(i10-1)=yyyyy*aik
      r(i10)=f(1)*pq1
      r(i01-1)=yyyyy*ajk
      r(i01)=f(1)*pq2
      r(n02)=yyyyy*ajj+f(1)
      r(n20)=yyyyy*aii+f(1)
      r(iz-2)=yyyyy*akk+f(1)
      r(iz-1)=f(1)*pq3
      r(iz)=f(0)
c...      k = 2
_IF1(ct)cdir$ shortloop
      do 701 m=1,my
      xxxxx=yyyyy
      yyyyy=f(m+2)
      x2(m)=yyyyy*aii+xxxxx
      y2(m)=yyyyy*ajj+xxxxx
      z2(m)=yyyyy*akk+xxxxx
      xxxxx=xxxxx+xxxxx
      x1(m-1)=x2(m)+xxxxx
      y1(m-1)=y2(m)+xxxxx
701   z1(m-1)=z2(m)+xxxxx
      l01=n20-mx
      k01=i11-mx
      j01=l01-mx
      r(i11-2)=z2(2)*aij
      r(i10-2)=z2(1)*pq1
      r(i01-2)=z2(1)*pq2
      r(k01-1)=y2(2)*aik
      r(k01)=y2(1)*pq1
      r(k01-2)=(y2(3)*akk+y2(2))*pq1
      r(n02-2)=y2(2)*akk+y2(1)
      r(n02-1)=y2(1)*pq3
      r(n20-2)=x2(2)*akk+x2(1)
      r(n20-1)=x2(1)*pq3
      xxxxx=x2(3)*ajj+x2(2)
      r(j01-1)=(x2(4)*ajj+x2(3))*akk+xxxxx
      r(j01)=xxxxx*pq3
      r(j01+1)=x2(2)*ajj+x2(1)
      r(l01-2)=(x2(3)*akk+x2(2))*pq2
      r(l01-1)=x2(2)*ajk
      r(l01)=x2(1)*pq2
c...      k = 3
      ukk=3.d0
      k=3
      i20=n20-ikymx
      i02=n02-mx
      r(i20)=x1(0)*pq1
      r(i02)=y1(0)*pq2
      r(iz-3)=z1(0)*pq3
      n01=k01-my
      m01=i20-my
      r(i10-3)=z1(1)*aik
      r(i01-3)=z1(1)*ajk
      r(i02-1)=y1(1)*ajk
      r(n01)=y1(1)*aij
      r(m01)=x1(1)*aij
      r(i20-1)=x1(1)*aik
      r(i11-3)=z1(2)*aijk
      r(n01-1)=y1(2)*aijk
      r(m01-1)=x1(2)*aijk
      zzzzz=z1(3)*aii+z1(2)
      yyyyy=y1(3)*aii+y1(2)
      yz21=y1(3)*akk+y1(2)
      xz21=x1(3)*akk+x1(2)
      xxxx=x1(3)*ajj+x1(2)
      xxxxx=x1(4)*ajj+x1(3)
      yz11=y1(3)*3.d0+y1(4)*akk
      xz11=x1(3)*3.d0+x1(4)*akk
      xy11=x1(3)*2.d0+xxxxx
      ikj=n01-ikymv
      kij=m01-mu
      r(n02-3)=(z1(2)*ajj+z1(1))*pq3
      r(n20-3)=(z1(2)*aii+z1(1))*pq3
      r(ikj+3)=(y1(2)*aii+y1(1))*pq2
      r(i02-2)=(y1(2)*akk+y1(1))*pq2
      r(i20-2)=(x1(2)*akk+x1(1))*pq1
      r(kij)=(x1(2)*ajj+x1(1))*pq1
      r(n01-2)=yz21*aij
      r(m01-2)=xz21*aij
      r(k01-3)=(z1(3)*ajj+z1(2))*aik
      r(kij-1)=xxxx*aik
      r(l01-3)=zzzzz*ajk
      r(ikj+2)=yyyyy*ajk
      r(j01-2)=((z1(4)*aii+z1(3))*ajj+zzzzz)*pq3
      r(ikj+1)=((y1(4)*aii+y1(3))*akk+yyyyy)*pq2
      r(kij-2)=(xxxxx*akk+xxxx)*pq1
      kji=kij-mu
      r(i02-3)=(y1(2)*2.d0+yz21)*ajk
      r(i20-3)=(x1(2)*2.d0+xz21)*aik
      r(kji+1)=(x1(2)*2.d0+xxxx)*aij
      r(n01-3)=yz11*aijk
      r(m01-3)=xz11*aijk
      r(kji)=xy11*aijk
      xxxx=x1(4)*3.d0
      r(ikj)=((y1(5)*akk+y1(4)*3.d0)*aii+yz11)*ajk
      xxxxx=x1(5)*ajj+xxxx
      r(kij-3)=((x1(5)*akk+xxxx)*ajj+xz11)*aik
      r(kji-1)=(xxxxx*akk+xy11)*aij
      r(kji-2)=((x1(6)*ajj+x1(5)*3.d0)*akk+xxxxx*3.d0)*aijk
c...
c...      k = 4,6,8
c...
710   i20=i20-iky(mu+1)
      i02=i02-mu-1
      k=k+1
      mu=mu-1
      r(i20)=x1(1)*aii+x2(1)*ukk
      r(i02)=y1(1)*ajj+y2(1)*ukk
      r(iz-k)=z1(1)*akk+z2(1)*ukk
_IF1(ct)cdir$ shortloop
      do 704 m=1,mu
      x2(m)=x1(m+1)*aii+x2(m+1)*ukk
      y2(m)=y1(m+1)*ajj+y2(m+1)*ukk
704   z2(m)=z1(m+1)*akk+z2(m+1)*ukk
      ukk=ukk+1.d0
      k01=i01-k
      j10=i10-k
      j01=i02-ikymw+k
      ikj=i20-mu
      r(k01)=z2(1)*pq2
      r(j10)=z2(1)*pq1
      r(j01)=y2(1)*pq1
      r(i02-1)=y2(1)*pq3
      r(i20-1)=x2(1)*pq3
      r(ikj-1)=x2(1)*pq2
      r(j10-mv)=z2(2)*aij
      r(j01-1)=y2(2)*aik
      r(ikj-2)=x2(2)*ajk
      k01=k01-mv
      j10=j10-ikymv
      j01=j01-ikymv+k
      l01=ikj-mu
      r(k01)=z2(2)*ajj+z2(1)
      r(j10)=z2(2)*aii+z2(1)
      r(j01)=y2(2)*aii+y2(1)
      r(i02-2)=y2(2)*akk+y2(1)
      r(i20-2)=x2(2)*akk+x2(1)
      r(l01-1)=x2(2)*ajj+x2(1)
      if(mu.eq.2)goto 7101
      zzzzz=z2(3)*ajj+z2(2)
      zx21=z2(3)*aii+z2(2)
      yx21=y2(3)*aii+y2(2)
      yz21=y2(3)*akk+y2(2)
      xz21=x2(3)*akk+x2(2)
      xy21=x2(3)*ajj+x2(2)
      jki=i02-ikymw+k
      kij=j10-mx
      r(k01-ikymw+2)=zzzzz*pq1
      r(jki-2)=yz21*pq1
      r(ikj-3)=xz21*pq2
      r(kij)=zx21*pq2
      r(j01-1)=yx21*pq3
      r(l01-2)=xy21*pq3
      k01=k01-mx
      j10=j10-ikymx
      n01=j01-ikymx+k
      m01=l01-mu
      r(k01)=(z2(2)*2.d0+zzzzz)*pq2
      r(j10)=(z2(2)*2.d0+zx21)*pq1
      r(n01)=(y2(2)*2.d0+yx21)*pq1
      r(i02-3)=(y2(2)*2.d0+yz21)*pq3
      r(i20-3)=(x2(2)*2.d0+xz21)*pq3
      r(m01)=(x2(2)*2.d0+xy21)*pq2
      if(mu.eq.3)goto 709
      xy22=x2(4)*ajj+x2(3)
      xz22=x2(4)*akk+x2(3)
      yz22=y2(4)*akk+y2(3)
      yx22=y2(4)*aii+y2(3)
      zx22=z2(4)*aii+z2(3)
      zzzz=z2(4)*ajj+z2(3)*3.d0
      r(j01-2)=yx22*akk+yx21
      r(l01-3)=xy22*akk+xy21
      r(kij-my)=zx22*ajj+zx21
      xz11=x2(3)*2.d0+xz22
      xy11=x2(3)*2.d0+xy22
      yz11=y2(3)*2.d0+yz22
      yx11=y2(3)*2.d0+yx22
      zx11=z2(3)*2.d0+zx22
      kji=k01-ikymw
      kij=j10-my
      r(n01-1)=yx11*aik
      r(jki-3)=yz11*aik
      r(kji+3)=zzzz*aij
      r(kij)=zx11*aij
      r(ikj-4)=xz11*ajk
      r(m01-1)=xy11*ajk
      j01=m01-mu
      r(i02-4)=yz11*akk+yz21*3.d0
      r(i20-4)=xz11*akk+xz21*3.d0
      r(j01+2)=xy11*ajj+xy21*3.d0
      if(k.eq.4)goto 719
      r(242)=zzzz*ajj+zzzzz*3.d0
      r(78)=zx11*aii+zx21*3.d0
      r(57)=yx11*aii+yx21*3.d0
      goto 709
719   if(mu.eq.4)goto 709
      xy23=x2(5)*ajj+x2(4)
      xz23=x2(5)*akk+x2(4)
      yz23=y2(5)*akk+y2(4)
      yx12=y2(5)*aii+y2(4)*3.d0
      zx12=z2(5)*aii+z2(4)*3.d0
      xz12=x2(4)*2.d0+xz23
      xy12=x2(4)*2.d0+xy23
      yz12=y2(4)*2.d0+yz23
      zzzzz=xz12*akk+xz22*3.d0
      yyyyy=yz12*akk+yz22*3.d0
      xxxxx=xy12*ajj+xy22*3.d0
      r(jki-ikymv+1)=(yz12*aii+yz11)*pq3
      r(ikj-mu-4)=(xz12*ajj+xz11)*pq3
      r(kji-ikymv+6)=((z2(5)*ajj+z2(4)*3.d0)*aii+zzzz)*pq2
      r(m01-2)=(xy12*akk+xy11)*pq2
      r(kij-my+1)=(zx12*ajj+zx11)*pq1
      r(n01-2)=(yx12*akk+yx11)*pq1
      r(jki-4)=yyyyy*pq1
      r(ikj-5)=zzzzz*pq2
      r(j01+1)=xxxxx*pq3
      if(mu.eq.5)goto 709
      xxxx=x2(6)*ajj+x2(5)*3.d0
      r(95)=((z2(6)*aii+z2(5)*3.d0)*ajj+zx12*3.d0)*aij
      r(91)=((y2(6)*aii+y2(5)*3.d0)*akk+yx12*3.d0)*aik
      r(63)=(xxxx*akk+xy12*3.d0)*ajk
      r(131)=((y2(6)*akk+y2(5)*3.d0)*akk+yz23*3.d0)*aii+yyyyy
      r(67)=((x2(6)*akk+x2(5)*3.d0)*akk+xz23*3.d0)*ajj+zzzzz
      r(60)=(xxxx*ajj+xy23*3.d0)*akk+xxxxx
c...
c...      k = 5,7
c...
709   i20=i20-iky(mu+1)
      i02=i02-mu-1
_IF1(ct)cdir$ shortloop
      do 703 m=1,mu
      x1(m-1)=x2(m)+x1(m)*ukk
      y1(m-1)=y2(m)+y1(m)*ukk
703   z1(m-1)=z2(m)+z1(m)*ukk
      ukk=ukk+1.d0
      k=k+1
      mu=mu-1
      r(i20)=x1(0)*pq1
      r(i02)=y1(0)*pq2
      r(iz-k)=z1(0)*pq3
      k01=i01-k
      j10=i10-k
      j01=i02-ikymw+k
      ikj=i20-mu
      r(j10)=z1(1)*aik
      r(k01)=z1(1)*ajk
      r(i02-1)=y1(1)*ajk
      r(j01)=y1(1)*aij
      r(ikj-1)=x1(1)*aij
      r(i20-1)=x1(1)*aik
      r(j10-mv)=z1(2)*aijk
      r(j01-1)=y1(2)*aijk
      r(ikj-2)=x1(2)*aijk
      k01=k01-mv
      j10=j10-ikymv
      j01=j01-ikymv+k
      l01=ikj-mu
      r(k01)=(z1(2)*ajj+z1(1))*pq3
      r(j10)=(z1(2)*aii+z1(1))*pq3
      r(j01)=(y1(2)*aii+y1(1))*pq2
      r(i02-2)=(y1(2)*akk+y1(1))*pq2
      r(i20-2)=(x1(2)*akk+x1(1))*pq1
      r(l01-1)=(x1(2)*ajj+x1(1))*pq1
      if(mu.eq.2)goto 7099
      zzzzz=z1(3)*ajj+z1(2)
      zx21=z1(3)*aii+z1(2)
      yx21=y1(3)*aii+y1(2)
      yz21=y1(3)*akk+y1(2)
      xz21=x1(3)*akk+x1(2)
      xy21=x1(3)*ajj+x1(2)
      jki=i02-ikymw+k
      kij=j10-mx
      r(jki-2)=yz21*aij
      r(ikj-3)=xz21*aij
      r(k01-ikymw+2)=zzzzz*aik
      r(l01-2)=xy21*aik
      r(kij)=zx21*ajk
      r(j01-1)=yx21*ajk
      k01=k01-mv
      j10=j10-ikymx
      n01=j01-ikymx+k
      m01=l01-mu
      r(j10)=(z1(2)*2.d0+zx21)*aik
      r(k01+1)=(z1(2)*2.d0+zzzzz)*ajk
      r(i02-3)=(y1(2)*2.d0+yz21)*ajk
      r(n01)=(y1(2)*2.d0+yx21)*aij
      r(i20-3)=(x1(2)*2.d0+xz21)*aik
      r(m01)=(x1(2)*2.d0+xy21)*aij
      if(mu.eq.3)goto 710
      yz22=y1(4)*akk+y1(3)
      yx22=y1(4)*aii+y1(3)
      zx22=z1(4)*aii+z1(3)
      yyyyy=z1(4)*ajj+z1(3)
      xy22=x1(4)*ajj+x1(3)
      xz22=x1(4)*akk+x1(3)
      r(j01-2)=(yx22*akk+yx21)*pq2
      r(l01-3)=(xy22*akk+xy21)*pq1
      r(kij-my)=(zx22*ajj+zx21)*pq3
      yz11=y1(3)*2.d0+yz22
      yx11=y1(3)*2.d0+yx22
      zx11=z1(3)*2.d0+zx22
      zzzz=z1(3)*2.d0+yyyyy
      xz11=x1(3)*2.d0+xz22
      xy11=x1(3)*2.d0+xy22
      r(n01-1)=yx11*aijk
      r(j10-my)=zx11*aijk
      r(k01-ikymw+4)=zzzz*aijk
      r(k01-mv+3)=(zzzz*ajj+zzzzz*3.d0)*pq3
      r(j10-ikymy)=(zx11*aii+zx21*3.d0)*pq3
      r(n01-ikymy+5)=(yx11*aii+yx21*3.d0)*pq2
      r(i02-4)=(yz11*akk+yz21*3.d0)*pq2
      r(jki-3)=yz11*aijk
      r(ikj-4)=xz11*aijk
      r(m01-1)=xy11*aijk
      r(i20-4)=(xz11*akk+xz21*3.d0)*pq1
      r(m01-mu+2)=(xy11*ajj+xy21*3.d0)*pq1
      if(mu.eq.4)goto 710
      yz12=y1(5)*akk+y1(4)*3.d0
      yx12=y1(5)*aii+y1(4)*3.d0
      zx12=z1(5)*aii+z1(4)*3.d0
      zzzzz=z1(5)*ajj+z1(4)*3.d0
      xz12=x1(5)*akk+x1(4)*3.d0
      xy12=x1(5)*ajj+x1(4)*3.d0
      r(181)=(zzzzz*ajj+yyyyy*3.d0)*aik
      r(42)=(xz12*ajj+xz11)*aik
      r(100)=(zx12*ajj+zx11)*aik
      r(136)=(zzzzz*aii+zzzz)*ajk
      r(58)=(yx12*aii+yx22*3.d0)*ajk
      r(72)=(zx12*aii+zx22*3.d0)*ajk
      r(127)=(yz12*aii+yz11)*ajk
      r(88)=(yx12*akk+yx11)*aij
      r(39)=(xy12*akk+xy11)*aij
      yyyyy=yz12*akk+yz22*3.d0
      zzzzz=xz12*akk+xz22*3.d0
      xxxxx=xy12*ajj+xy22*3.d0
      r(176)=yyyyy*aij
      r(46)=zzzzz*aij
      r(37)=xxxxx*aik
      r(236)=(yyyyy+yz11*4.d0)*ajk
      r(51)=(zzzzz+xz11*4.d0)*aik
      r(36)=(xxxxx+xy11*4.d0)*aij
      goto 710
7099  r(4)=x1(1)*aii+x2(1)*ukk
      xxxxx=x1(2)*aii+x2(2)*ukk
      r(i02-3)=y1(1)*ajj+y2(1)*ukk
      yyyyy=y1(2)*ajj+y2(2)*ukk
      r(i01+2)=z1(1)*akk+z2(1)*ukk
      zzzzz=z1(2)*akk+z2(2)*ukk
      ukk=ukk+1.d0
      r(n02+1)=zzzzz*pq2
      r(i11+1)=zzzzz*pq1
      r(n20+1)=yyyyy*pq1
      r(i02-4)=yyyyy*pq3
      r(3)=xxxxx*pq3
      r(2)=xxxxx*pq2
      r(1)=(xxxxx+x1(1)*ukk)*pq1
      r(i02-5)=(yyyyy+y1(1)*ukk)*pq2
      r(i01+1)=(zzzzz+z1(1)*ukk)*pq3
      return
7101  r(4)=(x2(1)+x1(1)*ukk)*pq1
      xxxxx=x2(2)+x1(2)*ukk
      r(i02-3)=(y2(1)+y1(1)*ukk)*pq2
      yyyyy=y2(2)+y1(2)*ukk
      r(i01+2)=(z2(1)+z1(1)*ukk)*pq3
      zzzzz=z2(2)+z1(2)*ukk
      ukk=ukk+1.d0
      r(i11+1)=zzzzz*aik
      r(n02+1)=zzzzz*ajk
      r(i02-4)=yyyyy*ajk
      r(n20+1)=yyyyy*aij
      r(2)=xxxxx*aij
      r(3)=xxxxx*aik
      r(1)=xxxxx*aii+x2(1)*ukk
      r(i02-5)=yyyyy*ajj+y2(1)*ukk
      r(i01+1)=zzzzz*akk+z2(1)*ukk
      return
      end
c***./ add name=zcals8
      subroutine zcals8(r)
      implicit REAL (a-h,o-z)
      dimension r(*)
      common/pqcon/pq(3),alpha,t4,apaq,f(0:189)
      pq3=pq(3)
      pq2=pq(2)
      pq1=pq(1)
      akk=pq3*pq3
      ajk=pq2*pq3
      ajj=pq2*pq2
      aik=pq1*pq3
      aij=pq1*pq2
      aii=pq1*pq1
      aijk=pq1*ajk
c...      k = 1
      zzzzz=f(1)
      xxxxx=f(2)
      yyyyy=f(3)
      r(84)=xxxxx*aii+zzzzz
      r(111)=yyyyy*aijk
      r(112)=xxxxx*aij
      r(119)=xxxxx*aik
      r(120)=zzzzz*pq1
      r(148)=xxxxx*ajj+zzzzz
      r(155)=xxxxx*ajk
      r(156)=zzzzz*pq2
      r(163)=xxxxx*akk+zzzzz
      r(164)=zzzzz*pq3
      r(165)=f(0)
c...      k = 2
      xxx21=yyyyy*aii+xxxxx
      yyy21=yyyyy*ajj+xxxxx
      zzz21=yyyyy*akk+xxxxx
      xxxxx=xxxxx+xxxxx
      r(56)=(xxx21+xxxxx)*pq1
      r(141)=(yyy21+xxxxx)*pq2
      r(162)=(zzz21+xxxxx)*pq3
      r(83)=xxx21*pq3
      r(77)=xxx21*pq2
      r(147)=yyy21*pq3
      r(105)=yyy21*pq1
      r(118)=zzz21*pq1
      r(154)=zzz21*pq2
      zzzzz=f(4)
      xxx22=zzzzz*aii+yyyyy
      yyy22=zzzzz*ajj+yyyyy
      zzz22=zzzzz*akk+yyyyy
      yyyyy=yyyyy+yyyyy
      xxx11=xxx22+yyyyy
      yyy11=yyy22+yyyyy
      zzz11=zzz22+yyyyy
      xxxxx=f(5)
      xxx23=xxxxx*aii+zzzzz
      yyy23=xxxxx*ajj+zzzzz
      zzz23=xxxxx*akk+zzzzz
      zzzzz=zzzzz+zzzzz
      xxx12=xxx23+zzzzz
      yyy12=yyy23+zzzzz
      zzz12=zzz23+zzzzz
      yyyyy=f(6)
      xxx24=yyyyy*aii+xxxxx
      yyy24=yyyyy*ajj+xxxxx
      zzz24=yyyyy*akk+xxxxx
      xxxxx=xxxxx+xxxxx
      xxx13=xxx24+xxxxx
      yyy13=yyy24+xxxxx
      zzz13=zzz24+xxxxx
      zzzzz=f(7)
      xxx25=zzzzz*aii+yyyyy
      yyy25=zzzzz*ajj+yyyyy
      zzz25=zzzzz*akk+yyyyy
      xxxx=yyyyy+yyyyy
      xxx14=xxx25+xxxx
      yyy14=yyy25+xxxx
      zzz14=zzz25+xxxx
      xxxx=zzzzz*3.d0
      xxxxx=f(8)
      xxx15=xxxxx*aii+xxxx
      yyy15=xxxxx*ajj+xxxx
      sss24=(xxxxx*akk+xxxx)*akk+zzz25*3.d0
      r(110)=zzz22*aij
      r(104)=yyy22*aik
      r(103)=(yyy23*akk+yyy22)*pq1
      r(146)=yyy22*akk+yyy21
      r(82)=xxx22*akk+xxx21
      xxxxx=xxx23*ajj+xxx22
      r(69)=(xxx24*ajj+xxx23)*akk+xxxxx
      r(70)=xxxxx*pq3
      r(71)=xxx22*ajj+xxx21
      r(75)=(xxx23*akk+xxx22)*pq2
      r(76)=xxx22*ajk
c...      k = 3
      r(117)=zzz11*aik
      r(153)=zzz11*ajk
      r(140)=yyy11*ajk
      r(99)=yyy11*aij
      r(50)=xxx11*aij
      r(55)=xxx11*aik
      r(109)=zzz12*aijk
      r(98)=yyy12*aijk
      r(49)=xxx12*aijk
      zzzzz=zzz13*aii+zzz12
      yyyyy=yyy13*aii+yyy12
      yz21=yyy13*akk+yyy12
      xz21=xxx13*akk+xxx12
      xxxx=xxx13*ajj+xxx12
      xxxxx=xxx14*ajj+xxx13
      yz11=yyy13*3.d0+yyy14*akk
      xz11=xxx13*3.d0+xxx14*akk
      xy11=xxx13*2.d0+xxxxx
      r(145)=(zzz12*ajj+zzz11)*pq3
      r(81)=(zzz12*aii+zzz11)*pq3
      r(66)=(yyy12*aii+yyy11)*pq2
      r(139)=(yyy12*akk+yyy11)*pq2
      r(54)=(xxx12*akk+xxx11)*pq1
      r(45)=(xxx12*ajj+xxx11)*pq1
      r(97)=yz21*aij
      r(48)=xz21*aij
      r(102)=(zzz13*ajj+zzz12)*aik
      r(44)=xxxx*aik
      r(74)=zzzzz*ajk
      r(65)=yyyyy*ajk
      r(68)=((zzz14*aii+zzz13)*ajj+zzzzz)*pq3
      r(64)=((yyy14*aii+yyy13)*akk+yyyyy)*pq2
      r(43)=(xxxxx*akk+xxxx)*pq1
      r(138)=(yyy12*2.d0+yz21)*ajk
      r(53)=(xxx12*2.d0+xz21)*aik
      r(41)=(xxx12*2.d0+xxxx)*aij
      r(96)=yz11*aijk
      r(47)=xz11*aijk
      r(40)=xy11*aijk
      xxxx=xxx14*3.d0
      r(63)=((yyy15*akk+yyy14*3.d0)*aii+yz11)*ajk
      r(42)=((xxx15*akk+xxxx)*ajj+xz11)*aik
      r(39)=((xxx15*ajj+xxxx)*akk+xy11)*aij
c...      k = 4
      r(35)=xxx11*aii+xxx21*3.d0
      r(135)=yyy11*ajj+yyy21*3.d0
      r(161)=zzz11*akk+zzz21*3.d0
      xxx21=xxx12*aii+xxx22*3.d0
      yyy21=yyy12*ajj+yyy22*3.d0
      zzz21=zzz12*akk+zzz22*3.d0
      r(20)=(xxx21+xxx11*4.d0)*pq1
      r(130)=(yyy21+yyy11*4.d0)*pq2
      r(160)=(zzz21+zzz11*4.d0)*pq3
      r(152)=zzz21*pq2
      r(116)=zzz21*pq1
      r(94)=yyy21*pq1
      r(134)=yyy21*pq3
      r(34)=xxx21*pq3
      r(30)=xxx21*pq2
      xxx22=xxx13*aii+xxx23*3.d0
      yyy22=yyy13*ajj+yyy23*3.d0
      zzz22=zzz13*akk+zzz23*3.d0
      xxx11=xxx22+xxx12*4.d0
      yyy11=yyy22+yyy12*4.d0
      zzz11=zzz22+zzz12*4.d0
      xxx23=xxx14*aii+xxx24*3.d0
      yyy23=yyy14*ajj+yyy24*3.d0
      zzz23=zzz14*akk+zzz24*3.d0
      xxx12=xxx23+xxx13*4.d0
      yyy12=yyy23+yyy13*4.d0
      zzz12=zzz23+zzz13*4.d0
      xxx24=xxx15*aii+xxx25*3.d0
      yyy24=yyy15*ajj+yyy25*3.d0
      xxx13=xxx24+xxx14*4.d0
      yyy13=yyy24+yyy14*4.d0
      zzz13=sss24+zzz14*4.d0
      r(108)=zzz22*aij
      r(93)=yyy22*aik
      r(29)=xxx22*ajk
      r(144)=zzz22*ajj+zzz21
      r(80)=zzz22*aii+zzz21
      r(62)=yyy22*aii+yyy21
      r(133)=yyy22*akk+yyy21
      r(33)=xxx22*akk+xxx21
      r(26)=xxx22*ajj+xxx21
      zzzzz=zzz23*ajj+zzz22
      zx21=zzz23*aii+zzz22
      yx21=yyy23*aii+yyy22
      yz21=yyy23*akk+yyy22
      xz21=xxx23*akk+xxx22
      xy21=xxx23*ajj+xxx22
      r(101)=zzzzz*pq1
      r(92)=yz21*pq1
      r(28)=xz21*pq2
      r(73)=zx21*pq2
      r(61)=yx21*pq3
      r(25)=xy21*pq3
      r(137)=(zzz22*2.d0+zzzzz)*pq2
      r(52)=(zzz22*2.d0+zx21)*pq1
      r(38)=(yyy22*2.d0+yx21)*pq1
      r(132)=(yyy22*2.d0+yz21)*pq3
      r(32)=(xxx22*2.d0+xz21)*pq3
      r(23)=(xxx22*2.d0+xy21)*pq2
      xy22=xxx24*ajj+xxx23
      xz22=xxx24*akk+xxx23
      yz22=yyy24*akk+yyy23
      yx22=yyy24*aii+yyy23
      zx22=sss24*aii+zzz23
      r(60)=yx22*akk+yx21
      r(24)=xy22*akk+xy21
      r(67)=zx22*ajj+zx21
      xz11=xxx23*2.d0+xz22
      xy11=xxx23*2.d0+xy22
      yz11=yyy23*2.d0+yz22
      r(37)=(yyy23*2.d0+yx22)*aik
      r(91)=yz11*aik
      r(95)=(sss24*ajj+zzz23*3.d0)*aij
      r(46)=(zzz23*2.d0+zx22)*aij
      r(27)=xz11*ajk
      r(22)=xy11*ajk
      r(131)=yz11*akk+yz21*3.d0
      r(31)=xz11*akk+xz21*3.d0
      r(21)=xy11*ajj+xy21*3.d0
c...      k = 5
      r(115)=zzz11*aik
      r(151)=zzz11*ajk
      r(129)=yyy11*ajk
      r(90)=yyy11*aij
      r(16)=xxx11*aij
      r(19)=xxx11*aik
      r(107)=zzz12*aijk
      r(89)=yyy12*aijk
      r(15)=xxx12*aijk
      r(143)=(zzz12*ajj+zzz11)*pq3
      r(79)=(zzz12*aii+zzz11)*pq3
      r(59)=(yyy12*aii+yyy11)*pq2
      r(128)=(yyy12*akk+yyy11)*pq2
      r(18)=(xxx12*akk+xxx11)*pq1
      r(13)=(xxx12*ajj+xxx11)*pq1
      zzzzz=zzz13*ajj+zzz12
      zx21=zzz13*aii+zzz12
      yx21=yyy13*aii+yyy12
      yz21=yyy13*akk+yyy12
      xz21=xxx13*akk+xxx12
      xy21=xxx13*ajj+xxx12
      r(88)=yz21*aij
      r(14)=xz21*aij
      r(100)=zzzzz*aik
      r(12)=xy21*aik
      r(72)=zx21*ajk
      r(58)=yx21*ajk
      r(51)=(zzz12*2.d0+zx21)*aik
      r(136)=(zzz12*2.d0+zzzzz)*ajk
      r(127)=(yyy12*2.d0+yz21)*ajk
      r(36)=(yyy12*2.d0+yx21)*aij
      r(17)=(xxx12*2.d0+xz21)*aik
      r(11)=(xxx12*2.d0+xy21)*aij
c...      k = 6
      r(10)=xxx11*aii+xxx21*5.d0
      r(126)=yyy11*ajj+yyy21*5.d0
      r(159)=zzz11*akk+zzz21*5.d0
      xxx21=xxx12*aii+xxx22*5.d0
      yyy21=yyy12*ajj+yyy22*5.d0
      zzz21=zzz12*akk+zzz22*5.d0
      xxx22=xxx13*aii+xxx23*5.d0
      yyy22=yyy13*ajj+yyy23*5.d0
      zzz22=zzz13*akk+zzz23*5.d0
      r(150)=zzz21*pq2
      r(114)=zzz21*pq1
      r(87)=yyy21*pq1
      r(125)=yyy21*pq3
      r(9)=xxx21*pq3
      r(7)=xxx21*pq2
      r(106)=zzz22*aij
      r(86)=yyy22*aik
      r(6)=xxx22*ajk
      r(142)=zzz22*ajj+zzz21
      r(78)=zzz22*aii+zzz21
      r(57)=yyy22*aii+yyy21
      r(124)=yyy22*akk+yyy21
      r(8)=xxx22*akk+xxx21
      r(5)=xxx22*ajj+xxx21
      r(4)=(xxx21+xxx11*6.d0)*pq1
      xxxxx=xxx22+xxx12*6.d0
      r(123)=(yyy21+yyy11*6.d0)*pq2
      yyyyy=yyy22+yyy12*6.d0
      r(158)=(zzz21+zzz11*6.d0)*pq3
      zzzzz=zzz22+zzz12*6.d0
      r(113)=zzzzz*aik
      r(149)=zzzzz*ajk
      r(122)=yyyyy*ajk
      r(85)=yyyyy*aij
      r(2)=xxxxx*aij
      r(3)=xxxxx*aik
      r(1)=xxxxx*aii+xxx21*7.d0
      r(121)=yyyyy*ajj+yyy21*7.d0
      r(157)=zzzzz*akk+zzz21*7.d0
      return
      end
c***./ add name=zcals7
      subroutine zcals7(r)
      implicit REAL (a-h,o-z)
      dimension r(*)
      common/pqcon/pq(3),alpha,t4,apaq,f(0:189)
      pq3=pq(3)
      pq2=pq(2)
      pq1=pq(1)
      akk=pq3*pq3
      ajk=pq2*pq3
      ajj=pq2*pq2
      aik=pq1*pq3
      aij=pq1*pq2
      aii=pq1*pq1
      aijk=pq1*ajk
c...      k = 1
      xxxxx=f(1)
      yyyyy=f(2)
      zzzzz=f(3)
      r(56)=yyyyy*aii+xxxxx
      r(76)=zzzzz*aijk
      r(77)=yyyyy*aij
      r(83)=yyyyy*aik
      r(84)=xxxxx*pq1
      r(105)=yyyyy*ajj+xxxxx
      r(111)=yyyyy*ajk
      r(112)=xxxxx*pq2
      r(118)=yyyyy*akk+xxxxx
      r(119)=xxxxx*pq3
      r(120)=f(0)
c...      k = 2
      xxx21=zzzzz*aii+yyyyy
      yyy21=zzzzz*ajj+yyyyy
      zzz21=zzzzz*akk+yyyyy
      yyyyy=yyyyy+yyyyy
      r(35)=(xxx21+yyyyy)*pq1
      r(99)=(yyy21+yyyyy)*pq2
      r(117)=(zzz21+yyyyy)*pq3
      xxxxx=f(4)
      xxx22=xxxxx*aii+zzzzz
      yyy22=xxxxx*ajj+zzzzz
      zzz22=xxxxx*akk+zzzzz
      zzzzz=zzzzz+zzzzz
      xxx11=xxx22+zzzzz
      yyy11=yyy22+zzzzz
      zzz11=zzz22+zzzzz
      yyyyy=f(5)
      xxx23=yyyyy*aii+xxxxx
      yyy23=yyyyy*ajj+xxxxx
      zzz23=yyyyy*akk+xxxxx
      xxxxx=xxxxx+xxxxx
      xxx12=xxx23+xxxxx
      yyy12=yyy23+xxxxx
      zzz12=zzz23+xxxxx
c     m=4
      zzzzz=f(6)
      xxx24=zzzzz*aii+yyyyy
      yyy24=zzzzz*ajj+yyyyy
      zzz24=zzzzz*akk+yyyyy
      yyyyy=yyyyy+yyyyy
      xxx13=xxx24+yyyyy
      yyy13=yyy24+yyyyy
      zzz13=zzz24+yyyyy
      zzzzz=zzzzz*3.d0
      xxxxx=f(7)
      xxx14=xxxxx*aii+zzzzz
      yyy14=xxxxx*ajj+zzzzz
      zzz14=xxxxx*akk+zzzzz
      r(75)=zzz22*aij
      r(82)=zzz21*pq1
      r(110)=zzz21*pq2
      r(69)=(yyy23*akk+yyy22)*pq1
      r(70)=yyy22*aik
      r(71)=yyy21*pq1
      r(103)=yyy22*akk+yyy21
      r(104)=yyy21*pq3
      r(54)=xxx22*akk+xxx21
      r(55)=xxx21*pq3
      xxxxx=xxx23*ajj+xxx22
      r(43)=(xxx24*ajj+xxx23)*akk+xxxxx
      r(44)=xxxxx*pq3
      r(45)=xxx22*ajj+xxx21
      r(48)=(xxx23*akk+xxx22)*pq2
      r(49)=xxx22*ajk
      r(50)=xxx21*pq2
c...      k = 3
      r(81)=zzz11*aik
      r(109)=zzz11*ajk
      r(98)=yyy11*ajk
      r(66)=yyy11*aij
      r(30)=xxx11*aij
      r(34)=xxx11*aik
      r(74)=zzz12*aijk
      r(65)=yyy12*aijk
      r(29)=xxx12*aijk
      zzzzz=zzz13*aii+zzz12
      yyyyy=yyy13*aii+yyy12
      yz21=yyy13*akk+yyy12
      xz21=xxx13*akk+xxx12
      xy21=xxx13*ajj+xxx12
      xxxxx=xxx14*ajj+xxx13
      r(102)=(zzz12*ajj+zzz11)*pq3
      r(53)=(zzz12*aii+zzz11)*pq3
      r(41)=(yyy12*aii+yyy11)*pq2
      r(97)=(yyy12*akk+yyy11)*pq2
      r(33)=(xxx12*akk+xxx11)*pq1
      r(26)=(xxx12*ajj+xxx11)*pq1
      r(64)=yz21*aij
      r(28)=xz21*aij
      r(68)=(zzz13*ajj+zzz12)*aik
      r(25)=xy21*aik
      r(47)=zzzzz*ajk
      r(40)=yyyyy*ajk
      r(42)=((zzz14*aii+zzz13)*ajj+zzzzz)*pq3
      r(39)=((yyy14*aii+yyy13)*akk+yyyyy)*pq2
      r(24)=(xxxxx*akk+xy21)*pq1
      r(96)=(yyy12*2.d0+yz21)*ajk
      r(32)=(xxx12*2.d0+xz21)*aik
      r(23)=(xxx12*2.d0+xy21)*aij
      r(22)=(xxx13*2.d0+xxxxx)*aijk
      r(27)=(xxx13*3.d0+xxx14*akk)*aijk
      r(63)=(yyy13*3.d0+yyy14*akk)*aijk
c...      k = 4
      r(20)=xxx11*aii+xxx21*3.d0
      r(94)=yyy11*ajj+yyy21*3.d0
      r(116)=zzz11*akk+zzz21*3.d0
      xxx21=xxx12*aii+xxx22*3.d0
      yyy21=yyy12*ajj+yyy22*3.d0
      zzz21=zzz12*akk+zzz22*3.d0
      r(10)=(xxx21+xxx11*4.d0)*pq1
      r(90)=(yyy21+yyy11*4.d0)*pq2
      r(115)=(zzz21+zzz11*4.d0)*pq3
      xxx22=xxx13*aii+xxx23*3.d0
      yyy22=yyy13*ajj+yyy23*3.d0
      zzz22=zzz13*akk+zzz23*3.d0
      xxx11=xxx22+xxx12*4.d0
      yyy11=yyy22+yyy12*4.d0
      zzz11=zzz22+zzz12*4.d0
      xxx23=xxx14*aii+xxx24*3.d0
      yyy23=yyy14*ajj+yyy24*3.d0
      zzz23=zzz14*akk+zzz24*3.d0
      xxx12=xxx23+xxx13*4.d0
      yyy12=yyy23+yyy13*4.d0
      zzz12=zzz23+zzz13*4.d0
      r(108)=zzz21*pq2
      r(80)=zzz21*pq1
      r(62)=yyy21*pq1
      r(93)=yyy21*pq3
      r(19)=xxx21*pq3
      r(16)=xxx21*pq2
      r(73)=zzz22*aij
      r(61)=yyy22*aik
      r(15)=xxx22*ajk
      r(101)=zzz22*ajj+zzz21
      r(52)=zzz22*aii+zzz21
      r(38)=yyy22*aii+yyy21
      r(92)=yyy22*akk+yyy21
      r(18)=xxx22*akk+xxx21
      r(13)=xxx22*ajj+xxx21
      zzzzz=zzz23*ajj+zzz22
      zx21=zzz23*aii+zzz22
      yx21=yyy23*aii+yyy22
      yz21=yyy23*akk+yyy22
      xz21=xxx23*akk+xxx22
      xy21=xxx23*ajj+xxx22
      r(67)=zzzzz*pq1
      r(60)=yz21*pq1
      r(14)=xz21*pq2
      r(46)=zx21*pq2
      r(37)=yx21*pq3
      r(12)=xy21*pq3
      r(95)=(zzz22*2.d0+zzzzz)*pq2
      r(31)=(zzz22*2.d0+zx21)*pq1
      r(21)=(yyy22*2.d0+yx21)*pq1
      r(91)=(yyy22*2.d0+yz21)*pq3
      r(17)=(xxx22*2.d0+xz21)*pq3
      r(11)=(xxx22*2.d0+xy21)*pq2
c...      k = 5
      r(79)=zzz11*aik
      r(107)=zzz11*ajk
      r(89)=yyy11*ajk
      r(59)=yyy11*aij
      r(7)=xxx11*aij
      r(9)=xxx11*aik
      r(72)=zzz12*aijk
      r(58)=yyy12*aijk
      r(6)=xxx12*aijk
      r(100)=(zzz12*ajj+zzz11)*pq3
      r(51)=(zzz12*aii+zzz11)*pq3
      r(36)=(yyy12*aii+yyy11)*pq2
      r(88)=(yyy12*akk+yyy11)*pq2
      r(8)=(xxx12*akk+xxx11)*pq1
      r(5)=(xxx12*ajj+xxx11)*pq1
      xxxxx=xxx12*aii+xxx22*5.d0
      r(4)=xxx11*aii+xxx21*5.d0
      r(87)=yyy11*ajj+yyy21*5.d0
      yyyyy=yyy12*ajj+yyy22*5.d0
      r(114)=zzz11*akk+zzz21*5.d0
      zzzzz=zzz12*akk+zzz22*5.d0
      r(106)=zzzzz*pq2
      r(78)=zzzzz*pq1
      r(57)=yyyyy*pq1
      r(86)=yyyyy*pq3
      r(3)=xxxxx*pq3
      r(2)=xxxxx*pq2
      r(1)=(xxxxx+xxx11*6.d0)*pq1
      r(85)=(yyyyy+yyy11*6.d0)*pq2
      r(113)=(zzzzz+zzz11*6.d0)*pq3
      return
      end
      subroutine ver_dft_mpole1(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/dft/mpole1.m,v $
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
