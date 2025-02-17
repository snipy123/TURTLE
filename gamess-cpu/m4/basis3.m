c 
c  $Author: jmht $
c  $Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
c  $Locker:  $
c  $Revision: 5774 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/basis3.m,v $
c  $State: Exp $
c  
c     deck=basis23
      subroutine potzv(csinp,cpinp,cdinp,opol,sc,scc,nucz,intyp,
     +nangm,nbfs,minf,maxf,loc,ngauss,ns,nshmax,ngsmax,ierr1,ierr2,
     +nat,iwr)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/blkin/eex(14),ccs(14),ccp(14),ccd(14)
      common/junk/ptr(18192),iptr(4,maxat),iptrs(2,mxshel),
     *ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     *cf(mxprim),cg(mxprim),
     +kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     +kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell
INCLUDE(common/restar)
      dimension csinp(*),cpinp(*),cdinp(*)
      dimension ns(*),intyp(*),nangm(*),nbfs(*),minf(*),maxf(*)
      dimension scc(*)
      data pt75/0.75d0/
      data pt5,pi32/0.5d+00,5.56832799683170d+00/
c     data tol/1.0d-10/
      data scalh1,scalh2,scalh3/1.00d0,1.00d0,1.00d0/
_IF1(civu)      call szero(eex,14)
_IF1(civu)      call szero(ccs,14)
_IF1(civu)      call szero(ccp,14)
_IF1(civu)      call szero(ccd,14)
c
_IFN1(civu)      call vclr(eex,1,56)
      if (nucz .gt. 2) go to 120
      mxpass=6
      if(opol) mxpass=mxpass+1
      call fzero(eex,ccs,ccp,nucz)
      if (sc .le. 0.0d0) sc = scalh1
      if (scc(1) .le. 0.0d0) scc(1) = scalh2
      if (scc(2) .le. 0.0d0) scc(2) = scalh3
      eex(1) = eex(1)*sc**2
      eex(2) = eex(2)*sc**2
      eex(3) = eex(3)*sc**2
      eex(4) = eex(4)*scc(1)**2
      eex(5) = eex(5)*scc(2)**2
      go to 160
  120 if (nucz .gt. 10) go to 140
c
c     ----- lithium to neon -----
c
      mxpass=7
      if(opol) mxpass=mxpass+1
      call econe(eex,ccs,ccp,ccd,nucz)
      go to 160
  140 if (nucz .gt. 18) go to 150
c
c     ----- sodium to argon ------------
c
      mxpass=7
      if(opol) mxpass=mxpass+1
      call ectwo(eex,ccs,ccp,ccd,nucz)
      go to 160
c
  150 if(nucz.gt.30) then
         if (opg_root()) then
            write(iwr,*)'*** nuclear charge = ',nucz
         endif
         call caserr2('requested basis set not available')
      endif
c
c     ----- potassium to zinc
c
      mxpass=8
c     call ecthr(eex,ccs,ccp,ccd,nucz)
c
  160 continue
c
c     ----- loop over shells -----
c
      ipass = 0
  180 ipass = ipass+1
      if (nucz .gt. 2) go to 240
c
c     ----- h -----
c
      go to (180,180,180,200,220,230,235),ipass
  200 ityp = 16
      igauss = 3
      ig = 0
      go to 700
  220 ityp = 16
      igauss = 1
      ig = 3
      go to 700
  230 ityp = 16
      igauss = 1
      ig = 4
      go to 700
  235 ityp = 17
      igauss = 1
      ig = 5
      go to 700
  240 if (nucz .gt. 4) go to 360
c
c     ----- li - be ---
c
      go to (180,180,180,180,260,280,300,180),ipass
  260 ityp = 22
      igauss = 1
      ig = 0
      go to 700
  280 ityp = 22
      igauss = 2
      ig = 1
      go to 700
  300 ityp = 22
      igauss = 1
      ig = 3
      go to 700
  360 if (nucz .gt. 18) go to 500
c
c     ----- b  - to - ne -----
c     ----- na - to - ar -----
c
      go to (180,180,180,180,380,400,420,440),ipass
  380 ityp = 22
      igauss = 1
      ig = 0
      go to 700
  400 ityp = 22
      igauss = 2
      ig = 1
      go to 700
  420 ityp = 22
      igauss = 1
      ig = 3
      go to 700
  440 ityp = 18
      igauss = 1
      ig = 4
      go to 700
c
c     ----- k to zn ----
c
  500 go to (1000,1010,1020,1030,1040,1050,1060,1070), ipass
 1000 ityp=22
      igauss=4
      ig=0
      go to 700
 1010 ityp=22
      igauss=1
      ig=4
      go to 700
 1020 ityp=22
      igauss=1
      ig=5
      go to 700
 1030 ityp=22
      igauss=1
      ig=6
      go to 700
 1040 ityp=22
      igauss=1
      ig=7
      go to 700
 1050 ityp=18
      igauss=4
      ig=8
      go to 700
 1060 ityp=18
      igauss=1
      ig=12
      go to 700
 1070 ityp=18
      igauss=1
      ig=13
      go to 700
c
  700 continue
      nshell = nshell+1
      if (nshell .gt. nshmax) ierr1 = 1
      if (ierr1 .ne. 0) return
      ns(nat) = ns(nat)+1
      kmin(nshell) = minf(ityp)
      kmax(nshell) = maxf(ityp)
      kstart(nshell) = ngauss+1
      katom(nshell) = nat
      ktype(nshell) = nangm(ityp)
      intyp(nshell) = ityp
      kng(nshell) = igauss
      kloc(nshell) = loc+1
      ngauss = ngauss+igauss
      if (ngauss .gt. ngsmax) ierr2 = 1
      if (ierr2 .ne. 0) return
      loc = loc+nbfs(ityp)
      k1 = kstart(nshell)
      k2 = k1+kng(nshell)-1
      do 720 i = 1,igauss
      k = k1+i-1
      ex(k) = eex(ig+i)
      csinp(k) = ccs(ig+i)
      cpinp(k) = ccp(ig+i)
      cdinp(k) = ccd(ig+i)
      cs(k) = csinp(k)
      cp(k) = cpinp(k)
  720 cd(k) = cdinp(k)
c
c     ----- always unnormalize primitives... -----
c
      do 740 k = k1,k2
      ee = ex(k)+ex(k)
      facs = pi32/(ee*  dsqrt(ee))
      facp = pt5*facs/ee
      facd = pt75*facs/(ee*ee)
      cs(k) = cs(k)/  dsqrt(facs)
      cp(k) = cp(k)/  dsqrt(facp)
  740 cd(k) = cd(k)/  dsqrt(facd)
c
      if (ipass .lt. mxpass) go to 180
      return
      end
      subroutine econe(e,s,p,d,n)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
c     ----- compact -ecp- from stevens,bash, and krauss -----
c
      dimension e(*),s(*),p(*),d(*)
      nn = n-2
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- li -----
c
  100 continue
      e(1)=0.6177d+00
      s(1)=-0.16287d+00
      p(1)=0.06205d+00
      e(2)=0.1434d+00
      s(2)=0.12643d+00
      p(2)=0.24719d+00
      e(3)=0.05048d+00
      s(3)=0.76179d+00
      p(3)=0.52140d+00
      e(4)=0.01923d+00
      s(4)=0.21800d+00
      p(4)=0.34290d+00
      return
c
c     ----- be -----
c
  120 continue
      e(1)=1.447d+00
      s(1)=-0.15647d+00
      p(1)=0.08924d+00
      e(2)=0.3522d+00
      s(2)=0.10919d+00
      p(2)=0.30999d+00
      e(3)=0.1219d+00
      s(3)=0.67538d+00
      p(3)=0.51842d+00
      e(4)=0.04395d+00
      s(4)=0.32987d+00
      p(4)=0.27911d+00
      return
c
c     ----- b  -----
c
  140 continue
      e(1)=2.710d+00
      s(1)=-0.14987d+00
      p(1)=0.09474d+00
      e(2)=0.6552d+00
      s(2)=0.08442d+00
      p(2)=0.30807d+00
      e(3)=0.2248d+00
      s(3)=0.69751d+00
      p(3)=0.46876d+00
      e(4)=0.07584d+00
      s(4)=0.32842d+00
      p(4)=0.35025d+00
      e(5)=0.7000d+00
      d(5)=1.00000d+00
      return
c
c     ----- c  -----
c
  160 continue
      e(1)=4.286d+00
      s(1)=-0.14722d+00
      p(1)=0.10257d+00
      e(2)=1.046d+00
      s(2)=0.08125d+00
      p(2)=0.32987d+00
      e(3)=0.3447d+00
      s(3)=0.71360d+00
      p(3)=0.48212d+00
      e(4)=0.1128d+00
      s(4)=0.31521d+00
      p(4)=0.31593d+00
      e(5)=0.7500d+00
      d(5)=1.0000d+00
      return
c
c     ----- n -----
c
  180 continue
      e(1)=6.403d+00
      s(1)=-0.13955d+00
      p(1)=0.10336d+00
      e(2)=1.580d+00
      s(2)=0.05492d+00
      p(2)=0.33205d+00
      e(3)=0.5094d+00
      s(3)=0.71678d+00
      p(3)=0.48708d+00
      e(4)=0.1623d+00
      s(4)=0.33210d+00
      p(4)=0.31312d+00
      e(5)=0.8000d+00
      d(5)=1.0000d+00
      return
c
c     ----- o  ------
c
  200 continue
      e(1)=8.519d+00
      s(1)=-0.14551d+00
      p(1)=0.11007d+00
      e(2)=2.073d+00
      s(2)=0.08286d+00
      p(2)=0.34969d+00
      e(3)=0.6471d+00
      s(3)=0.74325d+00
      p(3)=0.48093d+00
      e(4)=0.2000d+00
      s(4)=0.28472d+00
      p(4)=0.30727d+00
      e(5)=0.8500d+00
      d(5)=1.0000d+00
      return
c
c     ----- f  -----
c
  220 continue
      e(1)=11.12d+00
      s(1)=-0.14451d+00
      p(1)=0.11300d+00
      e(2)=2.687d+00
      s(2)=0.08971d+00
      p(2)=0.35841d+00
      e(3)=0.8210d+00
      s(3)=0.75659d+00
      p(3)=0.48002d+00
      e(4)=0.2475d+00
      s(4)=0.26570d+00
      p(4)=0.30381d+00
      e(5)=0.9000d+00
      d(5)=1.0000d+00
      return
c
c     ----- ne -----
c
  240 continue
      e(1)=14.07d+00
      s(1)=-0.14463d+00
      p(1)=0.11514d+00
      e(2)=3.389d+00
      s(2)=0.09331d+00
      p(2)=0.36479d+00
      e(3)=1.021d+00
      s(3)=0.76297d+00
      p(3)=0.48052d+00
      e(4)=0.3031d+00
      s(4)=0.25661d+00
      p(4)=0.29896d+00
      e(5)=1.0000d+00
      d(5)=1.0000d+00
      return
      end
      subroutine ectwo(e,s,p,d,n)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
c     ----- compact -ecp- from stevens, bash, and krauss -----
c
      dimension e(*),s(*),p(*),d(*)
      nn = n - 10
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- na -----
c
  100 continue
      e(1)=0.4299d+00
      s(1)=-0.20874d+00
      p(1)=-0.02571d+00
      e(2)=0.08897d+00
      s(2)=0.31206d+00
      p(2)=0.21608d+00
      e(3)=0.03550d+00
      s(3)=0.70300d+00
      p(3)=0.54196d+00
      e(4)=0.01455d+00
      s(4)=0.11648d+00
      p(4)=0.35484d+00
      e(5)=0.20000d+00
      d(5)=1.00000d+00
      return
c
c     ----- mg -----
c
  120 continue
      e(1)=0.6606d+00
      s(1)=-0.24451d+00
      p(1)=-0.04421d+00
      e(2)=0.1845d+00
      s(2)=0.25323d+00
      p(2)=0.27323d+00
      e(3)=0.06983d+00
      s(3)=0.69720d+00
      p(3)=0.57626d+00
      e(4)=0.02740d+00
      s(4)=0.21655d+00
      p(4)=0.28152d+00
      e(5)=0.20000d+00
      d(5)=1.00000d+00
      return
c
c     ----- al -----
c
  140 continue
      e(1)=0.9011d+00
      s(1)=-0.30377d+00
      p(1)=-0.07929d+00
      e(2)=0.4495d+00
      s(2)=0.13382d+00
      p(2)=0.16540d+00
      e(3)=0.1405d+00
      s(3)=0.76037d+00
      p(3)=0.53015d+00
      e(4)=0.04874d+00
      s(4)=0.32232d+00
      p(4)=0.47724d+00
      e(5)=0.30000d+00
      d(5)=1.00000d+00
      return
c
c     ----- si -----
c
  160 continue
      e(1)=1.167d+00
      s(1)=-0.32403d+00
      p(1)=-0.08450d+00
      e(2)=0.5268d+00
      s(2)=0.18438d+00
      p(2)=0.23786d+00
      e(3)=0.1807d+00
      s(3)=0.77737d+00
      p(3)=0.56532d+00
      e(4)=0.06480d+00
      s(4)=0.26767d+00
      p(4)=0.37433d+00
      e(5)=0.40000d+00
      d(5)=1.00000d+00
      return
c
c     ----- p  -----
c
  180 continue
      e(1)=1.459d+00
      s(1)=-0.34091d+00
      p(1)=-0.09378d+00
      e(2)=0.6549d+00
      s(2)=0.21535d+00
      p(2)=0.29205d+00
      e(3)=0.2256d+00
      s(3)=0.79578d+00
      p(3)=0.58688d+00
      e(4)=0.08115d+00
      s(4)=0.23092d+00
      p(4)=0.30631d+00
      e(5)=0.45000d+00
      d(5)=1.00000d+00
      return
c
c     ----- s  -----
c
  200 continue
      e(1)=1.817d+00
      s(1)=-0.34015d+00
      p(1)=-0.10096d+00
      e(2)=0.8379d+00
      s(2)=0.19601d+00
      p(2)=0.31244d+00
      e(3)=0.2854d+00
      s(3)=0.82666d+00
      p(3)=0.57906d+00
      e(4)=0.09939d+00
      s(4)=0.21652d+00
      p(4)=0.30748d+00
      e(5)=0.50000d+00
      d(5)=1.00000d+00
      return
c
c     ----- cl -----
c
  220 continue
      e(1)=2.225d+00
      s(1)=-0.33098d+00
      p(1)=-0.12604d+00
      e(2)=1.173d+00
      s(2)=0.11528d+00
      p(2)=0.29952d+00
      e(3)=0.3851d+00
      s(3)=0.84717d+00
      p(3)=0.58357d+00
      e(4)=0.1301d+00
      s(4)=0.26534d+00
      p(4)=0.34097d+00
      e(5)=0.55000d+00
      d(5)=1.00000d+00
      return
c
c     ----- ar -----
c
  240 continue
      e(1)=2.706d+00
      s(1)=-0.31286d+00
      p(1)=-0.10927d+00
      e(2)=1.278d+00
      s(2)=0.11821d+00
      p(2)=0.32601d+00
      e(3)=0.4354d+00
      s(3)=0.86786d+00
      p(3)=0.57952d+00
      e(4)=0.1476d+00
      s(4)=0.22264d+00
      p(4)=0.30349d+00
      e(5)=0.65000d+00
      d(5)=1.00000d+00
      return
      end
      subroutine ecthr(e,s,p,d,n)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      parameter (done=1.0d+00)
c
c     stevens, jasien, krauss, basch exponents and contraction
c     coefficients for the main group, 4th period.
c
      nn = n-18
      if(nn.gt.2) nn=n-28
      go to (100,200,300,400,500,600,700,800), nn
c
c   potassium
c
  100 continue
      e(1)=  0.2201d+00
      e(2)=  0.4825d-01
      e(3)=  0.2242d-01
      s(1)= -0.286027d+00
      s(2)=  0.48205d+00
      s(3)=  0.675841d+00
      p(1)= -0.66245d-01
      p(2)=  0.356898d+00
      p(3)=  0.704426d+00
      e(4)=  0.102d-01
      s(4)=  done
      p(4)=  done
      return
c
c   calcium
c
  200 continue
      e(1)=  0.2604d+00
      e(2)=  0.1439d+00
      e(3)=  0.4859d-01
      s(1)= -0.676466d+00
      s(2)=  0.525693d+00
      s(3)=  0.960216d+00
      p(1)= -0.270374d+00
      p(2)=  0.407807d+00
      p(3)=  0.828129d+00
      e(4)=  0.2167d-01
      s(4)=  done
      p(4)=  done
      return
c
c   gallium  ... semi-core basis
c
  300 continue
      e(1)=  1.139d+02
      e(2)=  9.155d+00
      e(3)=  6.633d+00
      e(4)=  2.278d+00
      s(1)= -1.711d-03
      s(2)= -8.23036d-01
      s(3)=  4.58618d-01
      s(4)=  1.161817d+00
      p(1)= -8.046d-03
      p(2)= -3.57432d-01
      p(3)=  6.63794d-01
      p(4)=  7.13619d-01
      e(5)=  7.043d+01
      e(6)=  2.105d+01
      e(7)=  7.401d+00
      e(8)=  2.752d+00
      d(5)=  2.8877d-02
      d(6)=  1.66253d-01
      d(7)=  4.27776d-01
      d(8)=  5.7041d-01
      e(9)=  7.461d-02
      s(9)=  done
      p(9)=  done
      e(10)=  2.123d+00
      e(11)=  1.939d-01
      s(10)= -1.45506d-01
      s(11)=  1.051147d+00
      p(10)= -9.6261d-02
      p(11)=  1.017573d+00
      e(12)=  8.818d-01
      s(12)=  done
      p(12)=  done
      e(13)=  1.026d+00
      d(13)=  done
      e(14)=  3.907d-01
      d(14)=  done
      return
c
c   germanium
c
  400 continue
      e(1)=  0.1834d+01
      e(2)=  0.1529d+01
      e(3)=  0.3594d+00
      e(4)=  0.147d+00
      s(1)=  0.49386d+00
      s(2)= -0.857354d+00
      s(3)=  0.41083d+00
      s(4)=  0.800378d+00
      p(1)=  0.6414d-02
      p(2)= -0.86052d-01
      p(3)=  0.383232d+00
      p(4)=  0.698185d+00
      e(5)=  0.5598d-01
      s(5)=  done
      p(5)=  done
      return
c
c   arsenic
c
  500 continue
      e(1)=  0.2709d+01
      e(2)=  0.1578d+01
      e(3)=  0.4358d+00
      e(4)=  0.1776d+00
      s(1)=  0.121479d+00
      s(2)= -0.518918d+00
      s(3)=  0.428791d+00
      s(4)=  0.808078d+00
      p(1)= -0.292d-02
      p(2)= -0.95054d-01
      p(3)=  0.424682d+00
      p(4)=  0.67129d+00
      e(5)=  0.6984d-01
      s(5)=  done
      p(5)=  done
      return
c
c   selenium
c
  600 continue
      e(1)=  0.3711d+01
      e(2)=  0.1586d+01
      e(3)=  0.5339d+00
      e(4)=  0.2085d+00
      s(1)=  5.5744d-02
      s(2)= -5.10520d-01
      s(3)=  4.80755d-01
      s(4)=  8.10292d-01
      p(1)= -6.014d-03
      p(2)= -1.21447d-01
      p(3)=  4.52607d-01
      p(4)=  6.69751d-01
      e(5)=  7.821d-02
      s(5)=  done
      p(5)=  done
      return
c
c   bromine
c
  700 continue
      e(1)=  0.3276d+01
      e(2)=  0.2044d+01
      e(3)=  0.6398d+00
      e(4)=  0.2561d+00
      s(1)=  0.20057d+00
      s(2)= -0.649296d+00
      s(3)=  0.405401d+00
      s(4)=  0.872607d+00
      p(1)=  0.5411d-02
      p(2)= -0.132391d+00
      p(3)=  0.430027d+00
      p(4)=  0.686009d+00
      e(5)=  0.9567d-01
      s(5)=  done
      p(5)=  done
      return
c
c   krypton
c
  800 continue
      e(1)=  0.3081d+01
      e(2)=  0.2413d+01
      e(3)=  0.7386d+00
      e(4)=  0.2941d+00
      s(1)=  0.533789d+00
      s(2)= -0.1001465d+01
      s(3)=  0.41551d+00
      s(4)=  0.880103d+00
      p(1)=  0.35906d-01
      p(2)= -0.169695d+00
      p(3)=  0.43508d+00
      p(4)=  0.68576d+00
      e(5)=  0.1095d+00
      s(5)=  done
      p(5)=  done
      return
      end
      subroutine ecfour(e,s,p,d,n)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      parameter (done=1.d+00)
c
c     stevens, jasien, krauss, basch exponents and contraction
c     coefficients for the main group, 5th period.
c
      nn= n-36
      if(nn.gt.2) nn=n-46
      go to (100,200,300,400,500,600,700,800), nn
c
c   rubidium
c
  100 continue
      e(1)=  0.1543d+00
      e(2)=  0.9892d-01
      e(3)=  0.3227d-01
      s(1)= -0.75339d+00
      s(2)=  0.40627d+00
      s(3)=  0.1112487d+01
      p(1)= -0.108684d+00
      p(2)=  0.55587d-01
      p(3)=  0.1014168d+01
      e(4)=  0.149d-01
      s(4)=  done
      p(4)=  done
      return
c
c   strontium
c
  200 continue
      e(1)=  0.1836d+00
      e(2)=  0.1252d+00
      e(3)=  0.3968d-01
      s(1)= -0.1075139d+01
      s(2)=  0.947037d+00
      s(3)=  0.934226d+00
      p(1)= -0.955549d+00
      p(2)=  0.856447d+00
      p(3)=  0.871558d+00
      e(4)=  0.184d-01
      s(4)=  done
      p(4)=  done
      return
c
c   indium ... semi-core basis
c
  300 continue
      e(1)=  7.176d+01
      e(2)=  7.654d+00
      e(3)=  5.616d+00
      e(4)=  2.104d+00
      s(1)=  7.33d-04
      s(2)=  1.089781d+00
      s(3)= -2.731089d+00
      s(4)=  2.112844d+00
      p(1)= -4.513d-03
      p(2)=  3.1615d-02
      p(3)= -3.38006d-01
      p(4)=  1.213464d+00
      e(5)=  1.716d+01
      e(6)=  3.127d+00
      e(7)=  1.475d+00
      d(5)=  1.4893d-02
      d(6)=  3.88135d-01
      d(7)=  6.62639d-01
      e(8)=  8.267d-02
      s(8)=  done
      p(8)=  done
      e(9)=  2.61d+00
      e(10)=  1.901d-01
      s(9)= -9.969d-02
      s(10)=  1.03123d+00
      p(9)= -1.10317d-01
      p(10)=  1.0139d+00
      e(11)=  8.41d-01
      s(11)=  done
      p(11)=  done
      e(12)=  6.452d-01
      d(12)=  done
      e(13)=  2.754d-01
      d(13)=  done
      return
c
c   tin
c
  400 continue
      e(1)=  0.2604d+01
      e(2)=  0.7532d+00
      e(3)=  0.3191d+00
      e(4)=  0.1239d+00
      s(1)=  0.31042d-01
      s(2)= -0.611859d+00
      s(3)=  0.548163d+00
      s(4)=  0.84915d+00
      p(1)= -0.5053d-02
      p(2)= -0.1801d+00
      p(3)=  0.370068d+00
      p(4)=  0.781334d+00
      e(5)=  0.4798d-01
      s(5)=  done
      p(5)=  done
      return
c
c   antimony
c
  500 continue
      e(1)=  0.9922d+00
      e(2)=  0.8089d+00
      e(3)=  0.4312d+00
      e(4)=  0.1498d+00
      s(1)=  0.690076d+00
      s(2)= -0.1580495d+01
      s(3)=  0.815248d+00
      s(4)=  0.894994d+00
      p(1)=  0.180229d+00
      p(2)= -0.487093d+00
      p(3)=  0.473936d+00
      p(4)=  0.804414d+00
      e(5)=  0.5803d-01
      s(5)=  done
      p(5)=  done
      return
c
c   tellurium
c
  600 continue
      e(1)=  0.2364d+01
      e(2)=  0.9769d+00
      e(3)=  0.4647d+00
      e(4)=  0.1771d+00
      s(1)=  0.87179d-01
      s(2)= -0.776826d+00
      s(3)=  0.56325d+00
      s(4)=  0.926053d+00
      p(1)= -0.3982d-02
      p(2)= -0.2369d+00
      p(3)=  0.401467d+00
      p(4)=  0.793179d+00
      e(5)=  0.6737d-01
      s(5)=  done
      p(5)=  done
      return
c
c   iodine
c
  700 continue
      e(1)=  0.2625d+01
      e(2)=  0.1014d+01
      e(3)=  0.5009d+00
      e(4)=  0.2023d+00
      s(1)=  0.7366d-01
      s(2)= -0.83687d+00
      s(3)=  0.656247d+00
      s(4)=  0.900744d+00
      p(1)= -0.888d-02
      p(2)= -0.257351d+00
      p(3)=  0.455368d+00
      p(4)=  0.760107d+00
      e(5)=  0.78d-01
      s(5)=  done
      p(5)=  done
      return
c
c   xenon
c
  800 continue
      e(1)=  0.1739d+01
      e(2)=  0.1169d+01
      e(3)=  0.5765d+00
      e(4)=  0.2218d+00
      s(1)=  0.349091d+00
      s(2)= -0.1197512d+01
      s(3)=  0.758409d+00
      s(4)=  0.888699d+00
      p(1)= -0.5429d-02
      p(2)= -0.277342d+00
      p(3)=  0.467189d+00
      p(4)=  0.763456d+00
      e(5)=  0.8486d-01
      s(5)=  done
      p(5)=  done
      return
      end
      subroutine ecfive(e,s,p,d,n)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      parameter (done=1.d+00)
c
c     stevens, jasien, krauss, basch exponents and contraction
c     coefficients for the main group, 6th period.
c
      nn= n-54
      if(nn.gt.2) nn=n-78
      go to (100,200,300,400,500,600,700,800), nn
c
c   cesium
c
  100 continue
      e(1)=  0.1157d+00
      e(2)=  0.5317d-01
      e(3)=  0.1897d-01
      s(1)= -0.519994d+00
      s(2)=  0.493361d+00
      s(3)=  0.872312d+00
      p(1)= -0.15056d+00
      p(2)=  0.221602d+00
      p(3)=  0.896486d+00
      e(4)=  0.774d-02
      s(4)=  done
      p(4)=  done
      return
c
c   barium
c
  200 continue
      e(1)=  0.1266d+00
      e(2)=  0.9433d-01
      e(3)=  0.302d-01
      s(1)= -0.1560287d+01
      s(2)=  0.1482538d+01
      s(3)=  0.878917d+00
      p(1)= -0.686637d+00
      p(2)=  0.807346d+00
      p(3)=  0.822436d+00
      e(4)=  0.1531d-01
      s(4)=  done
      p(4)=  done
      return
c
c   thallium ... semi-core basis
c
  300 continue
      e(1)=  2.772d+01
      e(2)=  8.583d+00
      e(3)=  4.65d+00
      e(4)=  1.876d+00
      e(5)=  7.369d-01
      s(1)= -1.5939d-02
      s(2)=  3.07229d-01
      s(3)= -1.124512d+00
      s(4)=  1.114798d+00
      s(5)=  5.31758d-01
      p(1)= -5.281d-03
      p(2)=  7.2455d-02
      p(3)= -3.43413d-01
      p(4)=  7.5962d-01
      p(5)=  4.8955d-01
      e(6)=  4.284d+00
      e(7)=  2.136d+00
      e(8)=  9.832d-01
      d(6)= -7.7432d-02
      d(7)=  4.55402d-01
      d(8)=  6.52892d-01
      e(9)=  1.6d-01
      s(9)=  done
      p(9)=  done
      e(10)=  6.181d-02
      s(10)=  done
      p(10)=  done
      e(11)=  1.629d+00
      s(11)=  done
      p(11)=  done
      e(12)=  4.5d-01
      d(12)=  done
      e(13)=  2.04d-01
      d(13)=  done
      return
c
c   lead
c
  400 continue
      e(1)=  0.1534d+01
      e(2)=  0.9923d+00
      e(3)=  0.2241d+00
      e(4)=  0.9664d-01
      s(1)=  0.225652d+00
      s(2)= -0.658998d+00
      s(3)=  0.766214d+00
      s(4)=  0.500934d+00
      p(1)=  0.28257d-01
      p(2)= -0.140659d+00
      p(3)=  0.428132d+00
      p(4)=  0.663422d+00
      e(5)=  0.39d-01
      s(5)=  done
      p(5)=  done
      return
c
c   bismuth
c
  500 continue
      e(1)=  0.1746d+01
      e(2)=  0.9925d+00
      e(3)=  0.2642d+00
      e(4)=  0.1135d+00
      s(1)=  0.162327d+00
      s(2)= -0.653854d+00
      s(3)=  0.80135d+00
      s(4)=  0.516861d+00
      p(1)=  0.16087d-01
      p(2)= -0.158284d+00
      p(3)=  0.460932d+00
      p(4)=  0.64977d+00
      e(5)=  0.4642d-01
      s(5)=  done
      p(5)=  done
      return
c
c   polonium
c
  600 continue
      e(1)=  0.1897d+01
      e(2)=  done
      e(3)=  0.3107d+00
      e(4)=  0.1273d+00
      s(1)=  0.13269d+00
      s(2)= -0.681546d+00
      s(3)=  0.840179d+00
      s(4)=  0.536942d+00
      p(1)=  0.6796d-02
      p(2)= -0.176142d+00
      p(3)=  0.490092d+00
      p(4)=  0.645759d+00
      e(5)=  0.51d-01
      s(5)=  done
      p(5)=  done
      return
c
c   astatine
c
  700 continue
      e(1)=  0.2676d+01
      e(2)=  0.9805d+00
      e(3)=  0.3598d+00
      e(4)=  0.1483d+00
      s(1)=  0.68973d-01
      s(2)= -0.718668d+00
      s(3)=  0.917123d+00
      s(4)=  0.546749d+00
      p(1)= -0.2652d-02
      p(2)= -0.194971d+00
      p(3)=  0.506172d+00
      p(4)=  0.653171d+00
      e(5)=  0.5887d-01
      s(5)=  done
      p(5)=  done
      return
c
c   radon
c
  800 continue
      e(1)=  0.2489d+01
      e(2)=  0.1013d+01
      e(3)=  0.4072d+00
      e(4)=  0.1646d+00
      s(1)=  0.8282d-01
      s(2)= -0.8032d+00
      s(3)=  0.983073d+00
      s(4)=  0.553051d+00
      p(1)=  0.4727d-02
      p(2)= -0.23118d+00
      p(3)=  0.541354d+00
      p(4)=  0.647745d+00
      e(5)=  0.65d-01
      s(5)=  done
      p(5)=  done
      return
      end
      subroutine ecphw(olanl,csinp,cpinp,cdinp,cfinp,omin,
     +sc,scc,nucz,intyp,
     +nangm, nbfs,minf,maxf,loc,ngauss,ns,nshmax,ngsmax,
     +ierr1,ierr2,nat,stos1,iwr)
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/blkin/eex(50),ccs(50),ccp(50),ccd(50),ccf(50)
      common/junk/ptr(18192),iptr(4,maxat),iptrs(2,mxshel),
     *ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     *cf(mxprim),cg(mxprim),
     +kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     +kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell
INCLUDE(common/restar)
      dimension csinp(*),cpinp(*),cdinp(*),cfinp(*)
      dimension ns(*),intyp(*),nangm(*),nbfs(*),minf(*),maxf(*)
      dimension scc(*),stos1(*)
      data pt75 /0.75d+00/
      data pt1875/1.875d+00/
      data pt5,pi32,tol /0.5d+00,
     + 5.56832799683170d+00,1.0d-10/
      data scalh1,scalh2/1.20d0,1.15d0/
c
c     ----- get exponents, contraction coefficients, and
c          scale factors. -----
c
_IF1(civu)      call szero(eex,250)
_IFN1(civu)      call vclr(eex,1,250)
c
      ng = 0
      igauss = ng
      ityp = ng
      ierr1=0
      ierr2=0
      odone = .false.
      scale=1.0d0
      if (nucz .le. 2) then
c
c     ----- hydrogen and helium-----
c
       if(omin) then
        scale = stos1(nucz)
        call s1s(eex,ccs,igauss)
       else
        call ddzero(eex,ccs,ccp,nucz)
        if (sc .le. 0.0d0) sc = scalh1
        if (scc(1) .le. 0.0d0) scc(1) = scalh2
        eex(1) = eex(1)*sc**2
        eex(2) = eex(2)*sc**2
        eex(3) = eex(3)*sc**2
        eex(4) = eex(4)*scc(1)**2
       endif
c
      else if (nucz .le. 10) then
c
c     ----- lithium to fluorine -----
c
        call econe(eex,ccs,ccp,ccd,nucz)
c
      else if (nucz .le. 18) then
c
c     ----- sodium to argon -----
c
         call ec2bas(eex,ccs,ccp,nucz,omin)
c
      else if (nucz .le. 36) then
c
c     ----- potassium to krypton
c
         call ec3bas(eex,ccs,ccp,ccd,nucz,omin,olanl)
c
      else if (nucz .le. 54) then
c
c     ----- rubidium to xenon
c
         call ec4bas(eex,ccs,ccp,ccd,nucz,omin,olanl)
c
      else if (nucz .le. 86) then
c
c     ----- cesium to bismuth
c
         call ec5bas(eex,ccs,ccp,ccd,nucz,omin,olanl)
c
      else
         if (opg_root()) then
            write(iwr,*)'*** nuclear charge = ',nucz
         endif
         call caserr2('requested basis set not available')
      endif
c
      ipass = 0
  180 ipass = ipass+1
c
      call ecphws(nucz,omin,olanl,ipass,ityp,igauss,odone)
c
      if(odone) go to 830

      nshell = nshell+1
      if (nshell .gt. nshmax) then
       ierr1 = 1
       return
      endif
      ns(nat) = ns(nat)+1
      kmin(nshell) = minf(ityp)
      kmax(nshell) = maxf(ityp)
      kstart(nshell) = ngauss+1
      katom(nshell) = nat
      ktype(nshell) = nangm(ityp)
      intyp(nshell) = ityp
      kng(nshell) = igauss
      kloc(nshell) = loc+1
      ngauss = ngauss+igauss
      if (ngauss .gt. ngsmax) then
       ierr2 = 1
       return
      endif
      loc = loc+nbfs(ityp)
      k1 = kstart(nshell)
      k2 = k1+kng(nshell)-1
      sc2 = scale * scale
      do i = 1,igauss
       k = k1+i-1
       ex(k) = eex(ng+i) * sc2
       csinp(k) = ccs(ng+i)
       cpinp(k) = ccp(ng+i)
       cdinp(k) = ccd(ng+i)
       cfinp(k) = ccf(ng+i)
       cs(k) = csinp(k)
       cp(k) = cpinp(k)
       cd(k) = cdinp(k)
       cf(k) = cfinp(k)
      enddo
c
c     ----- always unnormalize primitives... -----
c
      do k = k1,k2
       ee = ex(k)+ex(k)
       facs = pi32/(ee*dsqrt(ee))
       facp = pt5*facs/ee
       facd = pt75*facs/(ee*ee)
       facf = pt1875*facs/(ee*ee*ee)
       cs(k) = cs(k)/dsqrt(facs)
       cp(k) = cp(k)/dsqrt(facp)
       cd(k) = cd(k)/dsqrt(facd)
       cf(k) = cf(k)/dsqrt(facf)
      enddo
c
c     ----- if(normf.eq.0) normalize basis functions. -----
c
      if (normf .eq. 1) go to 820
      facs = 0.0d0
      facp = 0.0d0
      facd = 0.0d0
      facf = 0.0d0
      do ig = k1,k2
       do jg = k1,ig
       ee = ex(ig)+ex(jg)
       fac = ee*dsqrt(ee)
       dums = cs(ig)*cs(jg)/fac
       dump = pt5*cp(ig)*cp(jg)/(ee*fac)
       dumd = pt75*cd(ig)*cd(jg)/(ee*ee*fac)
       dumf = pt1875*cf(ig)*cf(jg)/(ee*ee*ee*fac)
       if (ig .ne. jg) then
        dums = dums+dums
        dump = dump+dump
        dumd = dumd+dumd
        dumf = dumf+dumf
       endif
       facs = facs+dums
       facp = facp+dump
       facd = facd+dumd
       facf = facf+dumf
       enddo
      enddo
      do  ig = k1,k2
       if (facs .gt. tol) cs(ig) = cs(ig)/dsqrt(facs*pi32)
       if (facp .gt. tol) cp(ig) = cp(ig)/dsqrt(facp*pi32)
       if (facd .gt. tol) cd(ig) = cd(ig)/dsqrt(facd*pi32)
       if (facf .gt. tol) cf(ig) = cf(ig)/dsqrt(facf*pi32)
      enddo
  820 continue
      ng = ng + igauss
      go to 180
c
  830 return
c
      end
      subroutine ecpsbkjc(csinp,cpinp,cdinp,cfinp,omin,odz,
     +sc,scc,nucz,intyp,
     +nangm, nbfs,minf,maxf,loc,ngauss,ns,nshmax,ngsmax,
     +ierr1,ierr2,nat,stos1,iwr)
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/blkin/eex(50),ccs(50),ccp(50),ccd(50),ccf(50)
      common/junk/ptr(18192),iptr(4,maxat),iptrs(2,mxshel),
     *ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     *cf(mxprim),cg(mxprim),
     +kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     +kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell
INCLUDE(common/restar)
      dimension csinp(*),cpinp(*),cdinp(*),cfinp(*)
      dimension ns(*),intyp(*),nangm(*),nbfs(*),minf(*),maxf(*)
      dimension scc(*),stos1(*)
      data pt75 /0.75d+00/
      data pt1875/1.875d+00/
      data pt5,pi32,tol /0.5d+00,
     + 5.56832799683170d+00,1.0d-10/
      data scalh1,scalh2/1.20d0,1.15d0/
c
c     ----- get exponents, contraction coefficients, and
c          scale factors. -----
c
_IF1(civu)      call szero(eex,250)
_IFN1(civu)      call vclr(eex,1,250)
c
      scale=1.0d0
      ng = 0
      igauss = ng
      ityp = ng
      ierr1=0
      ierr2=0
      odone = .false.
c
      if (nucz .le. 2) then
c
c     ----- hydrogen and helium-----
c
       if(omin) then
        scale = stos1(nucz)
        call s1s(eex,ccs,igauss)
       else
        call ddzero(eex,ccs,ccp,nucz)
        if (sc .le. 0.0d0) sc = scalh1
        if (scc(1) .le. 0.0d0) scc(1) = scalh2
        eex(1) = eex(1)*sc**2
        eex(2) = eex(2)*sc**2
        eex(3) = eex(3)*sc**2
        eex(4) = eex(4)*scc(1)**2
       endif
c
      else if (nucz .le. 10) then
c
c     ----- lithium to fluorine -----
c
        call econe(eex,ccs,ccp,ccd,nucz)
c
      else if (nucz .le. 18) then
c
c     ----- sodium to argon -----
c
        call ectwo(eex,ccs,ccp,ccd,nucz)
c
      else if (nucz .le. 36) then
c
c     ----- potassium to krypton
c
        if (nucz.ge.21  .and.  nucz.le.30) then
           call ectm1(eex,ccs,ccp,ccd,nucz)
        else
           call ecthr(eex,ccs,ccp,ccd,nucz)
        end if
c
      else if (nucz .le. 54) then
c
c     ----- rubidium to xenon
c
        if (nucz.ge.39  .and.  nucz.le.48) then
           call ectm2(eex,ccs,ccp,ccd,nucz)
        else
           call ecfour(eex,ccs,ccp,ccd,nucz)
        end if
c
      else if (nucz .le. 86) then
c
c     ----- cesium to bismuth
c
        if (nucz.ge.58  .and.  nucz.le.71) then
           call ecplan(eex,ccs,ccp,ccd,ccf,nucz)
        else if (nucz.ge.57  .and.  nucz.le.80) then
           call ectm3(eex,ccs,ccp,ccd,nucz)
        else
           call ecfive(eex,ccs,ccp,ccd,nucz)
        end if
c
      else
        if (opg_root()) then
          write(iwr,*)'*** nuclear charge = ',nucz
        endif
        call caserr2('requested basis set not available')
      endif
c
      ipass = 0
180   ipass = ipass + 1
c
      call ecpsbs(nucz,omin,odz,ipass,ityp,igauss,odone,.false.)
c
      if(odone) go to 830
c
      nshell = nshell+1
      if (nshell .gt. nshmax) then
       ierr1 = 1
       return
      endif
      ns(nat) = ns(nat)+1
      kmin(nshell) = minf(ityp)
      kmax(nshell) = maxf(ityp)
      kstart(nshell) = ngauss+1
      katom(nshell) = nat
      ktype(nshell) = nangm(ityp)
      intyp(nshell) = ityp
      kng(nshell) = igauss
      kloc(nshell) = loc+1
      ngauss = ngauss+igauss
      if (ngauss .gt. ngsmax) then
       ierr2 = 1
       return
      endif
      loc = loc+nbfs(ityp)
      k1 = kstart(nshell)
      k2 = k1+kng(nshell)-1
      sc2 = scale * scale
      do i = 1,igauss
       k = k1+i-1
       ex(k) = eex(ng+i) * sc2
       csinp(k) = ccs(ng+i)
       cpinp(k) = ccp(ng+i)
       cdinp(k) = ccd(ng+i)
       cfinp(k) = ccf(ng+i)
       cs(k) = csinp(k)
       cp(k) = cpinp(k)
       cd(k) = cdinp(k)
       cf(k) = cfinp(k)
      enddo
c
c     ----- always unnormalize primitives... -----
c
      do k = k1,k2
       ee = ex(k)+ex(k)
       facs = pi32/(ee*dsqrt(ee))
       facp = pt5*facs/ee
       facd = pt75*facs/(ee*ee)
       facf = pt1875*facs/(ee*ee*ee)
       cs(k) = cs(k)/dsqrt(facs)
       cp(k) = cp(k)/dsqrt(facp)
       cd(k) = cd(k)/dsqrt(facd)
       cf(k) = cf(k)/dsqrt(facf)
      enddo
c
c     ----- if(normf.eq.0) normalize basis functions. -----
c
      if (normf .eq. 1) go to 820
      facs = 0.0d0
      facp = 0.0d0
      facd = 0.0d0
      facf = 0.0d0
      do  ig = k1,k2
       do  jg = k1,ig
       ee = ex(ig)+ex(jg)
       fac = ee*dsqrt(ee)
       dums = cs(ig)*cs(jg)/fac
       dump = pt5*cp(ig)*cp(jg)/(ee*fac)
       dumd = pt75*cd(ig)*cd(jg)/(ee*ee*fac)
       dumf = pt1875*cf(ig)*cf(jg)/(ee*ee*ee*fac)
       if (ig .ne. jg) then
        dums = dums+dums
        dump = dump+dump
        dumd = dumd+dumd
        dumf = dumf+dumf
       endif
       facs = facs+dums
       facp = facp+dump
       facd = facd+dumd
       facf = facf+dumf
       enddo
      enddo
      do  ig = k1,k2
       if (facs .gt. tol) cs(ig) = cs(ig)/dsqrt(facs*pi32)
       if (facp .gt. tol) cp(ig) = cp(ig)/dsqrt(facp*pi32)
       if (facd .gt. tol) cd(ig) = cd(ig)/dsqrt(facd*pi32)
       if (facf .gt. tol) cf(ig) = cf(ig)/dsqrt(facf*pi32)
      enddo
  820 continue
      ng = ng + igauss
      go to 180
  830 return
c
      end
      subroutine ecpsbs(nucz,omin,odz,ipass,ityp,igauss,odone,
     +                  onew)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension maxps1(2),itype1(2),ngauss1(2)
      data maxps1/1,1/
      data itype1/16,22/
      data ngauss1/3,4/
c
      dimension maxps2(8),itype2(8,8),ngauss2(8,8)
      data maxps2/2,2,2,7,7,7,7,8/
      data itype2/16,16, 6*0,
     +            22,22, 6*0,
     +            22,22, 6*0,
     +            22,18,18,22,22,22,18,0,
     +            22,18,18,22,22,22,18,0,
     +            22,18,18,22,22,22,18,0,
     +            22,18,22,22,22,18,18,0,
     +            22,22,22,22,18,18,19,19 /
      data ngauss2/3,1,   6*0,
     +             3,1,   6*0,
     +             4,1,   6*0,
     +             4,4,1,2,1,1,1,0,
     +             4,3,1,2,1,1,1,0,
     +             4,3,1,1,1,1,1,0,
     +             4,4,1,2,1,1,1,0,
     +             3,1,1,1,2,1,5,2 /
c
c     ----- define current shell parameters for n-21g bases -----
c        nucz  =nuclear charge of this atom
c        ipass =number of current shell
c        mxpass=total number of shells on this atom
c        ityp  =16,18,19,22 for s,d,f,l shells
c        igauss=number of gaussians in current shell
c
      if (omin.and.nucz.gt.18) then
       call caserr2('minimal CEP basis not available')
      endif
c             h and he use a -31g s only shell
      kind=1
c             alkalis, and light right main group use a -31g split
      if(nucz.ge. 3  .and.  nucz.le.20) kind=2
      if(nucz.ge.37  .and.  nucz.le.38) kind=2
      if(nucz.ge.55  .and.  nucz.le.56) kind=2
c             heavier right main group use a -41g split
      if(nucz.ge.32  .and.  nucz.le.36) kind=3
      if(nucz.ge.50  .and.  nucz.le.54) kind=3
      if(nucz.ge.82  .and.  nucz.le.86) kind=3
c             semi-core transition metals
      if(nucz.ge.21  .and.  nucz.le.30) kind=4
      if(nucz.ge.39  .and.  nucz.le.48) kind=5
      if(nucz.eq.57                   ) kind=6
      if(nucz.ge.72  .and.  nucz.le.80) kind=6
c             semi-core ga, in, tl
      if(nucz.eq.31  .or.  nucz.eq.49  .or.  nucz.eq.81) kind=7
c             lanthanides (meaning ce-lu)
      if(nucz.ge.58  .and.  nucz.le.71) kind=8
c
      if (omin) then
       mxpass=maxps1(kind)
      else
       mxpass=maxps2(kind)
c      allow old ecpdz specification to hold (for consistency)
       if (odz.and.mxpass.eq.7) mxpass = mxpass -1
      endif
      if(ipass.gt.mxpass) odone=.true.
      if(odone) return
c
      if (omin) then
       ityp = itype1(kind)
       igauss = ngauss1(kind)
      else
       ityp = itype2(ipass,kind)
       igauss = ngauss2(ipass,kind)
c      old and new default definitions for h,he
       if (nucz.le.2.and.onew) then
         if(ipass.eq.1) igauss = 2
       endif
      endif
c
c     la, hg are not quite like the rest of 3rd tm series
      if(nucz.eq.57  .and.  ipass.eq.1) igauss=5
      if(nucz.eq.57  .and.  ipass.eq.4) igauss=2
      if(nucz.eq.80  .and.  ipass.eq.1) igauss=5
c            in is not quite like ga
      if(nucz.eq.49  .and.  ipass.eq.2) igauss=3
c            tl is not quite like ga
      if(nucz.eq.81  .and.  ipass.eq.1) igauss=5
      if(nucz.eq.81  .and.  ipass.eq.2) igauss=3
      if(nucz.eq.81  .and.  ipass.eq.3) igauss=1
      if(nucz.eq.81  .and.  ipass.eq.4) igauss=1
      return
      end
      subroutine ecphws(nucz,omin,olanl,ipass,ityp,igauss,odone)
      implicit REAL (a-h,o-z)
      logical odone, omin, olanl
      dimension maxps1(10),itype1(4,10),ngaus1(4,10)
      dimension maxps2(12),itype2(8,12),ngaus2(8,12)
c
      data maxps1/1,1,2,2,4,3,4,3,4,3/
      data itype1/16,0,0,0,
     *            22,0,0,0,
     *            16,17,0,0,
     *            16,17,0,0,
     *            16,17,18,16,
     *            16,17,18,0,
     *            16,17,18,16,
     *            16,17,18,0,
     *            16,17,18,16,
     *            16,17,18,0/
      data ngaus1/3,0,0,0,
     *            4,0,0,0,
     *            3,3,0,0,
     *            3,3,0,0,
     *            5,5,5,5,
     *            3,2,5,0,
     *            5,5,4,5,
     *            3,3,4,0,
     *            5,5,3,5,
     *            3,3,3,0/
c
      data maxps2/2,2,4,4,8,6,8,6,8,6,6,6/
      data itype2/16,16,0,0,0,0,0,0,
     *            22,22,0,0,0,0,0,0,
     *            16,16,17,17,0,0,0,0,
     *            16,16,17,17,0,0,0,0,
     *            16,16,16,17,17,17,18,18,
     *            16,16,17,17,18,18,0,0,
     *            16,16,16,17,17,17,18,18,
     *            16,16,17,17,18,18,0,0,
     *            16,16,16,17,17,17,18,18,
     *            16,16,17,17,18,18,0,0,
     *            16,16,16,17,17,17,0,0,
     *            16,16,16,17,17,17,0,0/
      data ngaus2/3,1,0,0,0,0,0,0,
     *            3,1,0,0,0,0,0,0,
     *            2,1,2,1,0,0,0,0,
     *            2,1,2,1,0,0,0,0,
     *            3,4,1,3,1,1,4,1,
     *            2,1,1,1,4,1,0,0,
     *            3,4,1,3,2,1,3,1,
     *            2,1,2,1,3,1,0,0,
     *            3,4,1,3,2,1,2,1,
     *            2,1,2,1,2,1,0,0,
     *            3,4,1,3,1,1,0,0,
     *            3,4,1,3,2,1,0,0 /
c
c     ----- define current shell parameters for hw basis sets -----
c        nucz  =nuclear charge of this atom
c        ipass =number of current shell
c        mxpass=total number of shells on this atom
c        ityp  =16,17,18,22 for s,p,d,l shells
c        igauss=number of gaussians in current shell
c        kind =0  means undefined (e.g. a lanthanide),
c             =1  means  h-he (non-hw)
c             =2  means li-ne (non-hw)
c             =3  means alkali/alkali earth
c             =4  means al-cl,ga-kr,in-xe,tl-bi main group,
c             =5  means 1st tm row semi-core transition metal
c             =6  means 1st tm row full-core (e.g. zn)
c             =7  means 2nd tm row semi-core transition metal
c             =8  means 2nd tm row full-core (e.g. cd)
c             =9  means 3rd tm row semi-core transition metal
c             =10 means 3rd tm row full-core (e.g. hg)
c             =11 means LASL2DZ alkali/alkali earth (e.g. k,ca,rb,sr)
c
      kind=0
c             h,he
      if(nucz.ge. 1  .and.  nucz.le. 2) kind=1
c             li-ne
      if(nucz.ge. 3  .and.  nucz.le.10) kind=2
c             na-ar
      if(nucz.ge.11  .and.  nucz.le.12) kind=3
      if(nucz.ge.13  .and.  nucz.le.18) kind=4
c             k-kr
      if(nucz.ge.19  .and.  nucz.le.20) then
       if (olanl) then
        kind=11
       else
        kind=3
       endif
      endif
C****
      if(nucz.ge.21  .and.  nucz.le.29) then
       if(olanl) then
        kind=5
       else
        kind=6
       endif
      endif
      if(nucz.eq.30)                    kind=6
      if(nucz.ge.31  .and.  nucz.le.36) kind=4
c             rb-xe
      if(nucz.ge.37  .and.  nucz.le.38) then
       if (olanl) then
        kind = 12
       else
        kind=3
       endif
      endif
C****
      if(nucz.ge.39  .and.  nucz.le.47) then
       if(olanl) then
        kind=7
       else
        kind=8
       endif
      endif
c
      if(nucz.eq.48)                    kind=8
      if(nucz.ge.49  .and.  nucz.le.54) kind=4
c             cs-rn
      if(nucz.ge.55  .and.  nucz.le.56) then
       if (olanl) then
        kind = 12
       else
        kind=3
       endif
      endif
c
      if(nucz.eq.57) then
       if(olanl) then
        kind = 9
       else
        kind = 10
       endif
      endif
c
      if(nucz.ge.58  .and.  nucz.le.71) kind=0
C****
      if(nucz.ge.72  .and.  nucz.le.79) then
       if(olanl) then
        kind=9
       else
        kind=10
       endif
      endif
      if(nucz.eq.80)                    kind=10
      if (nucz.eq.81) then
       if (olanl) then
        kind = 0
       else
        kind = 10
       endif
      endif
      if(nucz.ge.82  .and.  nucz.le.83) kind=4
c
      if(kind.eq.0) then
         write(6,*) 'hwshl: problem with z=',nucz
         call caserr2('problem in shell assignment for HW ECP basis')
      end if
c
      if(omin) then
         mxpass=maxps1(kind)
      else
         mxpass=maxps2(kind)
      end if
      if(ipass.gt.mxpass) odone=.true.
      if(odone) return
c
      if(omin) then
         ityp   = itype1(ipass,kind)
         igauss = ngaus1(ipass,kind)
      else
         ityp   = itype2(ipass,kind)
         igauss = ngaus2(ipass,kind)
      end if
      return
      end
      subroutine ecplan(e,s,p,d,f,n)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
      parameter (done=1.d+00)
c
c     "n-21g" type basis for the lanthanides -----
c     t.r.cundari, w.j.stevens, j.chem.phys, 98, 5555(1993).
c
      nn= n-57
c
      go to (58,59,60,61,62,63,64,65,66,67,68,69,70,71), nn
c
c   cerium
c
 58   continue
      e(1) =  3.45700d+00
      e(2) =  4.29100d+00
      e(3) =  2.29000d+00
      e(4) =  0.28570d+00
      e(5) =  0.66840d+00
      e(6) =  0.06957d+00
      s(1) =  3.1374906d+00
      s(2) = -1.4295166d+00
      s(3) = -2.6758482d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) =  1.9497168d+00
      p(2) = -0.9123114d+00
      p(3) = -2.0200371d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      d(7) =   0.3946619d+00
      d(8) =   0.6503444d+00
      d(9) =   done
      e(7) =  0.59160d+00
      e(8) =  0.30020d+00
      e(9) =  0.12440d+00
      f(10) =   0.0073853d+00
      f(11) =   0.0618916d+00
      f(12) =   0.2011817d+00
      f(13) =   0.3887943d+00
      f(14) =   0.5522320d+00
      f(15) =   0.7217269d+00
      f(16) =   0.3878059d+00
      e(10)= 83.88000d+00
      e(11)= 29.97000d+00
      e(12)= 13.05000d+00
      e(13)=  5.72700d+00
      e(14)=  2.54900d+00
      e(15)=  1.07500d+00
      e(16)=  0.39860d+00
      return
c
c  praseodymium
c
 59   continue
      e(1) =  3.45800d+00
      e(2) =  4.92100d+00
      e(3) =  2.10000d+00
      e(4) =  0.72900d+00
      e(5) =  0.29940d+00
      e(6) =  0.07179d+00
      s(1) =  0.8806114d+00
      s(2) = -0.1917569d+00
      s(3) = -1.6579589d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) =  0.7403625d+00
      p(2) = -0.2657420d+00
      p(3) = -1.4636781d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      d(7) =   0.3849163d+00
      d(8) =   0.6634936d+00
      d(9) =   done
      e(7) =  0.64190d+00
      e(8) =  0.31570d+00
      e(9) =  0.12900d+00
      f(10) =   0.0076926d+00
      f(11) =   0.0621079d+00
      f(12) =   0.2008683d+00
      f(13) =   0.3881868d+00
      f(14) =   0.5494929d+00
      f(15) =   0.7209543d+00
      f(16) =   0.3882895d+00
      e(10)= 88.46000d+00
      e(11)= 32.00000d+00
      e(12)= 14.09000d+00
      e(13)=  6.24600d+00
      e(14)=  2.80800d+00
      e(15)=  1.19800d+00
      e(16)=  0.44510d+00
      return
c
c   neodymium
c
 60   continue
      e(1) =  5.63400d+00
      e(2) =  4.72400d+00
      e(3) =  2.06400d+00
      e(4) =  0.77240d+00
      e(5) =  0.31270d+00
      e(6) =  0.07372d+00
      s(1) = -0.7064226d+00
      s(2) =  1.1373480d+00
      s(3) = -1.4029331d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.5818411d+00
      p(2) =  0.8487167d+00
      p(3) = -1.2523796d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      d(7) =   0.3873425d+00 
      d(8) =   0.6642494d+00
      d(9) =   done 
      e(7) =  0.67780d+00
      e(8) =  0.32550d+00
      e(9) =  0.13240d+00
      f(10) =   0.0077258d+00 
      f(11) =   0.0617211d+00 
      f(12) =   0.2004538d+00 
      f(13) =   0.3857174d+00 
      f(14) =   0.5490437d+00 
      f(15) =   0.7190505d+00 
      f(16) =   0.3912950d+00 
      e(10)= 94.38000d+00
      e(11)= 34.33000d+00
      e(12)= 15.21000d+00
      e(13)=  6.81600d+00
      e(14)=  3.09600d+00
      e(15)=  1.33000d+00
      e(16)=  0.49230d+00
      return
c
c   promethium
c
 61   continue
      e(1) =  8.28900d+00
      e(2) =  3.85600d+00
      e(3) =  2.12300d+00
      e(4) =  0.82050d+00
      e(5) =  0.32550d+00
      e(6) =  0.07554d+00
      s(1) = -0.0647755d+00
      s(2) =  0.5300920d+00
      s(3) = -1.4386781d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0785342d+00
      p(2) =  0.3975542d+00
      p(3) = -1.3026512d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      d(7) =   0.3689878d+00 
      d(8) =   0.6815842d+00 
      d(9) =   done 
      e(7) =  0.71890d+00
      e(8) =  0.34490d+00
      e(9) =  0.13700d+00
      f(10) =   0.0077411d+00 
      f(11) =   0.0614518d+00 
      f(12) =   0.1994959d+00 
      f(13) =   0.3823259d+00 
      f(14) =   0.5500773d+00 
      f(15) =   0.7143553d+00 
      f(16) =   0.3988111d+00 
      e(10)=101.10000d+00
      e(11)= 36.86000d+00
      e(12)= 16.43000d+00
      e(13)=  7.44500d+00
      e(14)=  3.41400d+00
      e(15)=  1.47200d+00
      e(16)=  0.53960d+00
      return
c
c   samarium
c
 62   continue
      e(1) = 12.61000d+00
      e(2) =  3.27800d+00
      e(3) =  2.23800d+00
      e(4) =  0.86610d+00
      e(5) =  0.33740d+00
      e(6) =  0.07732d+00
      s(1) = -0.0149996d+00
      s(2) =  0.7187788d+00
      s(3) = -1.6781500d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0315794d+00
      p(2) =  0.5090988d+00
      p(3) = -1.4640624d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      d(7) =   0.3794177d+00 
      d(8) =   0.6769150d+00 
      d(9) =   done 
      e(7) =  0.78510d+00
      e(8) =  0.36220d+00
      e(9) =  0.15730d+00
      f(10) =   0.0124675d+00 
      f(11) =   0.0875616d+00 
      f(12) =   0.2405394d+00 
      f(13) =   0.4205135d+00 
      f(14) =   0.4734687d+00 
      f(15) =   0.7473807d+00 
      f(16) =   0.3463134d+00 
      e(10)= 83.76000d+00
      e(11)= 30.54000d+00
      e(12)= 13.16000d+00
      e(13)=  5.73000d+00
      e(14)=  2.58500d+00
      e(15)=  1.13400d+00
      e(16)=  0.44450d+00
      return
c
c  europium
c
 63   continue
      e(1) = 14.22000d+00
      e(2) =  3.23700d+00
      e(3) =  2.34400d+00
      e(4) =  0.90470d+00
      e(5) =  0.34860d+00
      e(6) =  0.07916d+00
      s(1) = -0.0090055d+00
      s(2) =  0.8423269d+00
      s(3) = -1.8080826d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0261021d+00
      p(2) =  0.5780793d+00
      p(3) = -1.5403465d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      d(7) =   0.3280824d+00
      d(8) =   0.7171188d+00
      d(9) =   done
      e(7) =  0.81540d+00
      e(8) =  0.39910d+00
      e(9) =  0.15110d+00
      f(10) =   0.0139652d+00
      f(11) =   0.0943945d+00
      f(12) =   0.2492058d+00
      f(13) =   0.4238233d+00
      f(14) =   0.4589102d+00
      f(15) =   0.7550047d+00
      f(16) =   0.3360615d+00
      e(10)= 83.90000d+00
      e(11)= 30.66000d+00
      e(12)= 13.17000d+00
      e(13)=  5.74500d+00
      e(14)=  2.58800d+00
      e(15)=  1.13400d+00
      e(16)=  0.44720d+00
      return
c
c   gadolinium
c
 64   continue
      e(1) = 17.24000d+00
      e(2) =  3.34600d+00
      e(3) =  2.42900d+00
      e(4) =  0.93490d+00
      e(5) =  0.35880d+00
      e(6) =  0.08105d+00
      s(1) =  0.0036070d+00
      s(2) =  0.7375706d+00
      s(3) = -1.7149278d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0207287d+00
      p(2) =  0.5191487d+00
      p(3) = -1.4883822d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      d(7) =   0.3051932d+00
      d(8) =   0.7399451d+00
      d(9) =   done
      e(7) =  0.85730d+00
      e(8) =  0.41280d+00
      e(9) =  0.15190d+00
      f(10) =   0.0180914d+00
      f(11) =   0.1102055d+00
      f(12) =   0.2694254d+00
      f(13) =   0.4344260d+00
      f(14) =   0.4265979d+00
      f(15) =   0.7856925d+00
      f(16) =   0.2938734d+00
      e(10)= 77.60000d+00
      e(11)= 28.61000d+00
      e(12)= 12.13000d+00
      e(13)=  5.23900d+00
      e(14)=  2.30500d+00
      e(15)=  0.99420d+00
      e(16)=  0.40310d+00
      return
c
c   terbium
c
 65   continue
      e(1) = 13.18000d+00
      e(2) =  3.84700d+00
      e(3) =  2.53700d+00
      e(4) =  0.96140d+00
      e(5) =  0.36970d+00
      e(6) =  0.08254d+00
      s(1) = -0.0398058d+00
      s(2) =  0.7806111d+00
      s(3) = -1.7158528d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0326821d+00
      p(2) =  0.3979847d+00
      p(3) = -1.3560540d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      d(7) =   0.2846558d+00
      d(8) =   0.7609937d+00
      d(9) =   done
      e(7) =  0.90250d+00
      e(8) =  0.42480d+00
      e(9) =  0.15210d+00
      f(10) =   0.0151330d+00
      f(11) =   0.0998279d+00
      f(12) =   0.2549994d+00
      f(13) =   0.4191934d+00
      f(14) =   0.4497551d+00
      f(15) =   0.7446962d+00
      f(16) =   0.3516849d+00
      e(10)= 90.72000d+00
      e(11)= 33.17000d+00
      e(12)= 14.33000d+00
      e(13)=  6.35700d+00
      e(14)=  2.91400d+00
      e(15)=  1.28600d+00
      e(16)=  0.49850d+00
      return
c
c   dysprosium
c
 66   continue
      e(1) = 12.36000d+00
      e(2) =  4.15500d+00
      e(3) =  2.64700d+00
      e(4) =  0.99290d+00
      e(5) =  0.38080d+00
      e(6) =  0.08408d+00
      s(1) = -0.0469790d+00
      s(2) =  0.7231229d+00
      s(3) = -1.6509757d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0393311d+00
      p(2) =  0.3666596d+00
      p(3) = -1.3190207d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      e(7) =  0.92440d+00
      e(8) =  0.42800d+00
      e(9) =  0.15230d+00
      d(7) =   0.2894139d+00
      d(8) =   0.7585502d+00
      d(9) =   done
      e(10)= 97.47000d+00
      e(11)= 35.71000d+00
      e(12)= 15.58000d+00
      e(13)=  7.00600d+00
      e(14)=  3.25900d+00
      e(15)=  1.44000d+00
      e(16)=  0.54570d+00
      f(10) =   0.0147178d+00
      f(11) =   0.0977056d+00
      f(12) =   0.2512386d+00
      f(13) =   0.4123795d+00
      f(14) =   0.4564398d+00
      f(15) =   0.7338642d+00
      f(16) =   0.3690476d+00
      return
c
c    holmium
c
 67   continue
      e(1) = 12.31000d+00
      e(2) =  4.30500d+00
      e(3) =  2.74900d+00
      e(4) =  1.02400d+00
      e(5) =  0.39140d+00
      e(6) =  0.08555d+00
      s(1) = -0.0454979d+00
      s(2) =  0.7105661d+00
      s(3) = -1.6401006d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0383146d+00
      p(2) =  0.3479272d+00
      p(3) = -1.3021661d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      e(7) =  0.95070d+00
      e(8) =  0.43170d+00
      e(9) =  0.15310d+00
      d(7) =   0.2945199d+00 
      d(8) =   0.7561902d+00 
      d(9) =   done 
      e(10)=104.90000d+00
      e(11)= 38.50000d+00
      e(12)= 16.95000d+00
      e(13)=  7.72500d+00
      e(14)=  3.63500d+00
      e(15)=  1.60200d+00
      e(16)=  0.59480d+00
      f(10) =   0.0141835d+00 
      f(11) =   0.0950565d+00 
      f(12) =   0.2466934d+00 
      f(13) =   0.4052217d+00 
      f(14) =   0.4651430d+00 
      f(15) =   0.7262095d+00 
      f(16) =   0.3822719d+00 
      return
c
c    erbium
c
 68   continue
      e(1) = 12.58000d+00
      e(2) =  4.44900d+00
      e(3) =  2.87300d+00
      e(4) =  1.05800d+00
      e(5) =  0.40250d+00
      e(6) =  0.08708d+00
      s(1) = -0.0425587d+00
      s(2) =  0.7179336d+00
      s(3) = -1.6502894d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0402829d+00
      p(2) =  0.3577179d+00
      p(3) = -1.3110413d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      e(7) =  0.97910d+00
      e(8) =  0.43670d+00
      e(9) =  0.15440d+00
      d(7) =   0.2987899d+00 
      d(8) =   0.7544645d+00 
      d(9) =   done 
      e(10)=105.10000d+00
      e(11)= 38.68000d+00
      e(12)= 17.00000d+00
      e(13)=  7.74500d+00
      e(14)=  3.64200d+00
      e(15)=  1.60800d+00
      e(16)=  0.59800d+00
      f(10) =   0.0156082d+00 
      f(11) =   0.1009470d+00 
      f(12) =   0.2538319d+00 
      f(13) =   0.4082474d+00 
      f(14) =   0.4524062d+00 
      f(15) =   0.7274973d+00 
      f(16) =   0.3804196d+00 
      return
c
c    thulium
c
 69   continue
      e(1) = 11.04000d+00
      e(2) =  4.88100d+00
      e(3) =  2.92800d+00
      e(4) =  1.08000d+00
      e(5) =  0.41210d+00
      e(6) =  0.08851d+00
      s(1) = -0.0592729d+00
      s(2) =  0.6115702d+00
      s(3) = -1.5277045d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0242818d+00
      p(2) =  0.2161241d+00
      p(3) = -1.1825576d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      e(7) =  1.00900d+00
      e(8) =  0.44270d+00
      e(9) =  0.15560d+00
      d(7) =   0.3005086d+00
      d(8) =   0.7548745d+00
      d(9) =   done
      e(10)=113.40000d+00
      e(11)= 41.80000d+00
      e(12)= 18.53000d+00
      e(13)=  8.54700d+00
      e(14)=  4.05600d+00
      e(15)=  1.77900d+00
      e(16)=  0.64780d+00
      f(10) =   0.0148458d+00
      f(11) =   0.0973394d+00
      f(12) =   0.2481870d+00
      f(13) =   0.4010063d+00
      f(14) =   0.4634212d+00
      f(15) =   0.7219403d+00
      f(16) =   0.3913644d+00
      return
c
c    ytterbium
c
 70   continue
      e(1) = 10.08000d+00
      e(2) =  5.39500d+00
      e(3) =  3.03100d+00
      e(4) =  1.10800d+00
      e(5) =  0.42210d+00
      e(6) =  0.09008d+00
      s(1) = -0.0890681d+00
      s(2) =  0.5767409d+00
      s(3) = -1.4628924d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0359281d+00
      p(2) =  0.1941357d+00
      p(3) = -1.1499825d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      e(7) =  1.05100d+00
      e(8) =  0.45190d+00
      e(9) =  0.15620d+00
      d(7) =   0.2939074d+00
      d(8) =   0.7630676d+00
      d(9) =   done
      e(10)=122.50000d+00
      e(11)= 45.18000d+00
      e(12)= 20.20000d+00
      e(13)=  9.42800d+00
      e(14)=  4.50100d+00
      e(15)=  1.96000d+00
      e(16)=  0.70050d+00
      f(10) =   0.0140468d+00
      f(11) =   0.0934822d+00
      f(12) =   0.2418361d+00
      f(13) =   0.3940876d+00
      f(14) =   0.4754289d+00
      f(15) =   0.7171299d+00
      f(16) =   0.4009835d+00
      return
c
c    lutetium
c
 71   continue
      e(1) =  9.46900d+00
      e(2) =  5.56800d+00
      e(3) =  3.18200d+00
      e(4) =  1.13500d+00
      e(5) =  0.43200d+00
      e(6) =  0.09161d+00
      s(1) = -0.1119004d+00
      s(2) =  0.6321414d+00
      s(3) = -1.4951712d+00
      s(4) =  done
      s(5) =  done
      s(6) =  done
      p(1) = -0.0463915d+00
      p(2) =  0.2179130d+00
      p(3) = -1.1634161d+00
      p(4) =  done
      p(5) =  done
      p(6) =  done
      e(7) =  1.10100d+00
      e(8) =  0.46390d+00
      e(9) =  0.15640d+00
      d(7) =   0.2744246d+00
      d(8) =   0.7823096d+00
      d(9) =   done
      e(10)=117.80000d+00
      e(11)= 43.40000d+00
      e(12)= 19.13000d+00
      e(13)=  8.79700d+00
      e(14)=  4.15300d+00
      e(15)=  1.81700d+00
      e(16)=  0.66170d+00
      f(10) =   0.0164643d+00
      f(11) =   0.1045249d+00
      f(12) =   0.2577225d+00
      f(13) =   0.4054234d+00
      f(14) =   0.4476287d+00
      f(15) =   0.7256251d+00
      f(16) =   0.3870116d+00
c
      return
      end
      subroutine ectm1(e,s,p,d,n)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      parameter (done=1.d+00)
c
c     stevens, jasien, krauss, basch exponents and contraction
c     coefficients for the first transition series.
c
      nn = n-20
      go to (100,200,300,400,500,600,700,800,900,1000), nn
c
c     scandium
c
  100 continue
      e(1)=  4.007d+01
      e(2)=  3.665d+00
      e(3)=  3.047d+00
      e(4)=  9.588d-01
      s(1)= -3.296d-03
      s(2)= -6.55617d-01
      s(3)=  1.03253d-01
      s(4)=  1.320199d+00
      p(1)= -7.753d-03
      p(2)= -6.15592d-01
      p(3)=  7.80261d-01
      p(4)=  8.34079d-01
      e(5)=  2.324d+01
      e(6)=  6.143d+00
      e(7)=  2.007d+00
      e(8)=  6.652d-01
      d(5)=  2.6288d-02
      d(6)=  1.42881d-01
      d(7)=  3.98178d-01
      d(8)=  6.40201d-01
      e(9)=  2.021d-01
      d(9)=  done
      e(10)=  1.264d+00
      e(11)=  7.502d-02
      s(10)= -5.7596d-02
      s(11)=  1.016468d+00
      p(10)= -3.1779d-02
      p(11)=  1.004065d+00
      e(12)=  2.741d-02
      s(12)=  done
      p(12)=  done
      e(13)=  3.557d-01
      s(13)=  done
      p(13)=  done
      e(14)=  5.454d-02
      d(14)=  done
      return
c
c     titanium
c
  200 continue
      e(1)=  5.108d+01
      e(2)=  4.18d+00
      e(3)=  2.997d+00
      e(4)=  1.019d+00
      s(1)= -2.004d-03
      s(2)= -6.19686d-01
      s(3)=  1.56029d-01
      s(4)=  1.248817d+00
      p(1)= -6.949d-03
      p(2)= -3.26613d-01
      p(3)=  5.44254d-01
      p(4)=  7.89631d-01
      e(5)=  2.811d+01
      e(6)=  7.63d+00
      e(7)=  2.528d+00
      e(8)=  8.543d-01
      d(5)=  2.5746d-02
      d(6)=  1.41260d-01
      d(7)=  4.00607d-01
      d(8)=  6.34532d-01
      e(9)=  2.673d-01
      d(9)=  done
      e(10)=  1.383d+00
      e(11)=  8.128d-02
      s(10)= -7.2891d-02
      s(11)=  1.020184d+00
      p(10)= -2.5949d-02
      p(11)=  1.003353d+00
      e(12)=  3.023d-02
      s(12)=  done
      p(12)=  done
      e(13)=  3.745d-01
      s(13)=  done
      p(13)=  done
      e(14)=  7.43d-02
      d(14)=  done
      return
c
c     vanadium
c
  300 continue
      e(1)=  4.816d+01
      e(2)=  4.685d+00
      e(3)=  3.115d+00
      e(4)=  1.098d+00
      s(1)= -4.277d-03
      s(2)= -5.45554d-01
      s(3)=  1.31799d-01
      s(4)=  1.218022d+00
      p(1)= -8.007d-03
      p(2)= -2.65673d-01
      p(3)=  5.22944d-01
      p(4)=  7.54434d-01
      e(5)=  3.336d+01
      e(6)=  9.331d+00
      e(7)=  3.158d+00
      e(8)=  1.113d+00
      d(5)=  2.553d-02
      d(6)=  1.40336d-01
      d(7)=  3.97933d-01
      d(8)=  6.29027d-01
      e(9)=  3.608d-01
      d(9)=  done
      e(10)=  1.565d+00
      e(11)=  9.409d-02
      s(10)= -8.5426d-02
      s(11)=  1.023584d+00
      p(10)= -2.2816d-02
      p(11)=  1.003066d+00
      e(12)=  3.37d-02
      s(12)=  done
      p(12)=  done
      e(13)=  3.936d-01
      s(13)=  done
      p(13)=  done
      e(14)=  1.007d-01
      d(14)=  done
      return
c
c     chromium
c
  400 continue
      e(1)=  2.312d+01
      e(2)=  5.036d+00
      e(3)=  2.867d+00
      e(4)=  1.144d+00
      s(1)= -5.918d-03
      s(2)= -5.9075d-01
      s(3)=  2.9612d-01
      s(4)=  1.107646d+00
      p(1)= -1.8018d-02
      p(2)= -1.44996d-01
      p(3)=  4.97416d-01
      p(4)=  6.72884d-01
      e(5)=  3.789d+01
      e(6)=  1.058d+01
      e(7)=  3.603d+00
      e(8)=  1.27d+00
      d(5)=  2.591d-02
      d(6)=  1.4413d-01
      d(7)=  4.03597d-01
      d(8)=  6.20846d-01
      e(9)=  4.118d-01
      d(9)=  done
      e(10)=  1.571d+00
      e(11)=  9.654d-02
      s(10)= -9.0329d-02
      s(11)=  1.025164d+00
      p(10)= -3.7281d-02
      p(11)=  1.004879d+00
      e(12)=  3.492d-02
      s(12)=  done
      p(12)=  done
      e(13)=  4.529d-01
      s(13)=  done
      p(13)=  done
      e(14)=  1.126d-01
      d(14)=  done
      return
c
c     manganese
c
  500 continue
      e(1)=  7.217d+01
      e(2)=  5.728d+00
      e(3)=  3.729d+00
      e(4)=  1.321d+00
      s(1)= -2.635d-03
      s(2)= -5.93184d-01
      s(3)=  2.24656d-01
      s(4)=  1.175342d+00
      p(1)= -7.172d-03
      p(2)= -2.45649d-01
      p(3)=  5.32283d-01
      p(4)=  7.30536d-01
      e(5)=  4.263d+01
      e(6)=  1.197d+01
      e(7)=  4.091d+00
      e(8)=  1.45d+00
      d(5)=  2.6095d-02
      d(6)=  1.46772d-01
      d(7)=  4.07115d-01
      d(8)=  6.1459d-01
      e(9)=  4.7d-01
      d(9)=  done
      e(10)=  1.827d+00
      e(11)=  1.13d-01
      s(10)= -9.6146d-02
      s(11)=  1.026668d+00
      p(10)= -3.26d-02
      p(11)=  1.004376d+00
      e(12)=  3.89d-02
      s(12)=  done
      p(12)=  done
      e(13)=  4.754d-01
      s(13)=  done
      p(13)=  done
      e(14)=  1.281d-01
      d(14)=  done
      return
c
c     iron
c
  600 continue
      e(1)=  7.028d+01
      e(2)=  6.061d+00
      e(3)=  4.134d+00
      e(4)=  1.421d+00
      s(1)= -2.611d-03
      s(2)= -6.92435d-01
      s(3)=  3.6253d-01
      s(4)=  1.140645d+00
      p(1)= -7.94d-03
      p(2)= -2.90151d-01
      p(3)=  5.91028d-01
      p(4)=  7.19448d-01
      e(5)=  4.71d+01
      e(6)=  1.312d+01
      e(7)=  4.478d+00
      e(8)=  1.581d+00
      d(5)=  2.6608d-02
      d(6)=  1.5201d-01
      d(7)=  4.13827d-01
      d(8)=  6.05542d-01
      e(9)=  5.1d-01
      d(9)=  done
      e(10)=  1.978d+00
      e(11)=  1.213d-01
      s(10)= -9.8172d-02
      s(11)=  1.026957d+00
      p(10)= -3.3731d-02
      p(11)=  1.004462d+00
      e(12)=  4.1d-02
      s(12)=  done
      p(12)=  done
      e(13)=  5.121d-01
      s(13)=  done
      p(13)=  done
      e(14)=  1.382d-01
      d(14)=  done
      return
c
c     cobalt
c
  700 continue
      e(1)=  7.568d+01
      e(2)=  6.496d+00
      e(3)=  4.791d+00
      e(4)=  1.594d+00
      s(1)= -5.271d-03
      s(2)= -7.05525d-01
      s(3)=  3.4788d-01
      s(4)=  1.175595d+00
      p(1)= -8.085d-03
      p(2)= -3.90988d-01
      p(3)=  6.80078d-01
      p(4)=  7.29594d-01
      e(5)=  5.169d+01
      e(6)=  1.47d+01
      e(7)=  4.851d+00
      e(8)=  1.643d+00
      d(5)=  2.5447d-02
      d(6)=  1.49529d-01
      d(7)=  4.25056d-01
      d(8)=  6.05465d-01
      e(9)=  5.075d-01
      d(9)=  done
      e(10)=  2.337d+00
      e(11)=  1.269d-01
      s(10)= -8.9267d-02
      s(11)=  1.022589d+00
      p(10)= -1.5935d-02
      p(11)=  1.001945d+00
      e(12)=  4.232d-02
      s(12)=  done
      p(12)=  done
      e(13)=  5.572d-01
      s(13)=  done
      p(13)=  done
      e(14)=  1.433d-01
      d(14)=  done
      return
c
c     nickel
c
  800 continue
      e(1)=  8.936d+01
      e(2)=  7.265d+00
      e(3)=  5.572d+00
      e(4)=  1.85d+00
      s(1)= -5.22d-03
      s(2)= -6.83993d-01
      s(3)=  2.5105d-01
      s(4)=  1.236451d+00
      p(1)= -7.529d-03
      p(2)= -4.45862d-01
      p(3)=  7.06364d-01
      p(4)=  7.53606d-01
      e(5)=  5.873d+01
      e(6)=  1.671d+01
      e(7)=  5.783d+00
      e(8)=  2.064d+00
      d(5)=  2.6246d-02
      d(6)=  1.50334d-01
      d(7)=  4.13385d-01
      d(8)=  6.04114d-01
      e(9)=  6.752d-01
      d(9)=  done
      e(10)=  3.235d+00
      e(11)=  1.295d-01
      s(10)= -6.3418d-02
      s(11)=  1.013237d+00
      p(10)=  1.136d-03
      p(11)=  9.99895d-01
      e(12)=  4.327d-02
      s(12)=  done
      p(12)=  done
      e(13)=  6.594d-01
      s(13)=  done
      p(13)=  done
      e(14)=  1.825d-01
      d(14)=  done
      return
c
c     copper
c
  900 continue
      e(1)=  8.342d+01
      e(2)=  7.97d+00
      e(3)=  5.6d+00
      e(4)=  1.932d+00
      s(1)= -4.829d-03
      s(2)= -6.44799d-01
      s(3)=  2.6524d-01
      s(4)=  1.189791d+00
      p(1)= -8.284d-03
      p(2)= -3.21895d-01
      p(3)=  6.18133d-01
      p(4)=  7.22184d-01
      e(5)=  6.58d+01
      e(6)=  1.882d+01
      e(7)=  6.538d+00
      e(8)=  2.348d+00
      d(5)=  2.5597d-02
      d(6)=  1.48609d-01
      d(7)=  4.11786d-01
      d(8)=  6.05507d-01
      e(9)=  7.691d-01
      d(9)=  done
      e(10)=  2.866d+00
      e(11)=  1.319d-01
      s(10)= -7.4774d-02
      s(11)=  1.017037d+00
      p(10)= -5.41d-04
      p(11)=  1.000058d+00
      e(12)=  4.4d-02
      s(12)=  done
      p(12)=  done
      e(13)=  6.874d-01
      s(13)=  done
      p(13)=  done
      e(14)=  2.065d-01
      d(14)=  done
      return
c
c     zinc
c
 1000 continue
      e(1)=  1.135d+02
      e(2)=  8.308d+00
      e(3)=  6.332d+00
      e(4)=  2.146d+00
      s(1)= -4.28d-03
      s(2)= -8.20232d-01
      s(3)=  4.25006d-01
      s(4)=  1.198077d+00
      p(1)= -7.429d-03
      p(2)= -4.32605d-01
      p(3)=  7.23451d-01
      p(4)=  7.27217d-01
      e(5)=  6.599d+01
      e(6)=  1.981d+01
      e(7)=  6.945d+00
      e(8)=  2.543d+00
      d(5)=  2.7653d-02
      d(6)=  1.58794d-01
      d(7)=  4.20971d-01
      d(8)=  5.85277d-01
      e(9)=  9.165d-01
      d(9)=  done
      e(10)=  2.906d+00
      e(11)=  1.623d-01
      s(10)= -8.2356d-02
      s(11)=  1.021574d+00
      p(10)= -2.3001d-02
      p(11)=  1.002824d+00
      e(12)=  5.369d-02
      s(12)=  done
      p(12)=  done
      e(13)=  8.116d-01
      s(13)=  done
      p(13)=  done
      e(14)=  3.264d-01
      d(14)=  done
      return
      end
      subroutine ectm2(e,s,p,d,n)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      parameter (done=1.d+00)
c
c     stevens, jasien, krauss, basch exponents and contraction
c     coefficients for the second transition series.
c
      nn = n-38
      go to (100,200,300,400,500,600,700,800,900,1000), nn
c
c     yttrium
c
  100 continue
      e(1)=  2.984d+01
      e(2)=  3.242d+00
      e(3)=  2.694d+00
      e(4)=  8.43d-01
      s(1)= -6.294d-03
      s(2)=  1.436231d+00
      s(3)= -2.550213d+00
      s(4)=  1.756065d+00
      p(1)= -3.457d-03
      p(2)= -9.7386d-02
      p(3)= -9.8933d-02
      p(4)=  1.11219d+00
      e(5)=  5.399d+00
      e(6)=  1.066d+00
      e(7)=  3.892d-01
      d(5)=  1.202d-02
      d(6)=  3.4295d-01
      d(7)=  7.39397d-01
      e(8)=  1.3d-01
      d(8)=  done
      e(9)=  1.324d+00
      e(10)=  6.806d-02
      s(9)= -5.7976d-02
      s(10)=  1.014874d+00
      p(9)= -2.5891d-02
      p(10)=  1.002833d+00
      e(11)=  2.729d-02
      s(11)=  done
      p(11)=  done
      e(12)=  3.015d-01
      s(12)=  done
      p(12)=  done
      e(13)=  4.121d-02
      d(13)=  done
      return
c
c     zirconium
c
  200 continue
      e(1)=  3.053d+01
      e(2)=  3.518d+00
      e(3)=  2.971d+00
      e(4)=  9.587d-01
      s(1)= -4.504d-03
      s(2)=  1.708899d+00
      s(3)= -2.918518d+00
      s(4)=  1.822958d+00
      p(1)= -4.092d-03
      p(2)= -7.8665d-02
      p(3)= -1.40588d-01
      p(4)=  1.130526d+00
      e(5)=  6.191d+00
      e(6)=  1.32d+00
      e(7)=  5.359d-01
      d(5)=  1.2d-02
      d(6)=  3.25005d-01
      d(7)=  7.40299d-01
      e(8)=  1.9d-01
      d(8)=  done
      e(9)=  9.293d-01
      e(10)=  6.91d-02
      s(9)= -6.1958d-02
      s(10)=  1.020739d+00
      p(9)= -6.0217d-02
      p(10)=  1.009302d+00
      e(11)=  2.759d-02
      s(11)=  done
      p(11)=  done
      e(12)=  3.764d-01
      s(12)=  done
      p(12)=  done
      e(13)=  5.9d-02
      d(13)=  done
      return
c
c     niobium
c
  300 continue
      e(1)=  3.853d+01
      e(2)=  3.907d+00
      e(3)=  3.274d+00
      e(4)=  1.052d+00
      s(1)= -2.059d-03
      s(2)=  1.618867d+00
      s(3)= -2.83086d+00
      s(4)=  1.818465d+00
      p(1)= -3.576d-03
      p(2)= -3.3217d-02
      p(3)= -1.85568d-01
      p(4)=  1.133471d+00
      e(5)=  7.994d+00
      e(6)=  1.55d+00
      e(7)=  6.666d-01
      d(5)=  1.0433d-02
      d(6)=  3.18071d-01
      d(7)=  7.39654d-01
      e(8)=  2.462d-01
      d(8)=  done
      e(9)=  1.057d+00
      e(10)=  7.876d-02
      s(9)= -7.1919d-02
      s(10)=  1.023797d+00
      p(9)= -6.7815d-02
      p(10)=  1.010254d+00
      e(11)=  3.091d-02
      s(11)=  done
      p(11)=  done
      e(12)=  4.165d-01
      s(12)=  done
      p(12)=  done
      e(13)=  7.86d-02
      d(13)=  done
      return
c
c     molybdenum
c
  400 continue
      e(1)=  3.967d+01
      e(2)=  4.633d+00
      e(3)=  3.208d+00
      e(4)=  1.224d+00
      s(1)= -9.716d-03
      s(2)=  7.70126d-01
      s(3)= -2.22953d+00
      s(4)=  2.046495d+00
      p(1)= -4.015d-03
      p(2)= -3.4146d-02
      p(3)= -2.51817d-01
      p(4)=  1.192347d+00
      e(5)=  9.051d+00
      e(6)=  1.777d+00
      e(7)=  7.848d-01
      d(5)=  1.0883d-02
      d(6)=  3.11829d-01
      d(7)=  7.41802d-01
      e(8)=  2.899d-01
      d(8)=  done
      e(9)=  1.181d+00
      e(10)=  8.489d-02
      s(9)= -7.5222d-02
      s(10)=  1.024137d+00
      p(9)= -7.1971d-02
      p(10)=  1.010227d+00
      e(11)=  3.276d-02
      s(11)=  done
      p(11)=  done
      e(12)=  4.728d-01
      s(12)=  done
      p(12)=  done
      e(13)=  9.107d-02
      d(13)=  done
      return
c
c     technetium
c
  500 continue
      e(1)=  4.887d+01
      e(2)=  4.77d+00
      e(3)=  3.74d+00
      e(4)=  1.305d+00
      s(1)= -6.485d-03
      s(2)=  1.33093d+00
      s(3)= -2.698832d+00
      s(4)=  1.956263d+00
      p(1)= -3.492d-03
      p(2)=  3.7514d-02
      p(3)= -2.97801d-01
      p(4)=  1.1749d+00
      e(5)=  9.451d+00
      e(6)=  1.887d+00
      e(7)=  8.506d-01
      d(5)=  1.2195d-02
      d(6)=  3.4695d-01
      d(7)=  7.07123d-01
      e(8)=  3.258d-01
      d(8)=  done
      e(9)=  1.744d+00
      e(10)=  1.206d-01
      s(9)= -9.4275d-02
      s(10)=  1.028604d+00
      p(9)= -8.5401d-02
      p(10)=  1.010946d+00
      e(11)=  4.31d-02
      s(11)=  done
      p(11)=  done
      e(12)=  4.94d-01
      s(12)=  done
      p(12)=  done
      e(13)=  1.031d-01
      d(13)=  done
      return
c
c     ruthenium
c
  600 continue
      e(1)=  5.6d+01
      e(2)=  4.625d+00
      e(3)=  3.793d+00
      e(4)=  1.367d+00
      s(1)= -2.837d-03
      s(2)=  1.891661d+00
      s(3)= -3.431011d+00
      s(4)=  2.074446d+00
      p(1)= -3.198d-03
      p(2)= -1.03766d-01
      p(3)= -1.27594d-01
      p(4)=  1.146533d+00
      e(5)=  1.03d+01
      e(6)=  2.044d+00
      e(7)=  8.988d-01
      d(5)=  1.1961d-02
      d(6)=  3.64575d-01
      d(7)=  6.94316d-01
      e(8)=  3.443d-01
      d(8)=  done
      e(9)=  1.528d+00
      e(10)=  9.673d-02
      s(9)= -6.9035d-02
      s(10)=  1.020343d+00
      p(9)= -7.299d-02
      p(10)=  1.008642d+00
      e(11)=  3.636d-02
      s(11)=  done
      p(11)=  done
      e(12)=  5.183d-01
      s(12)=  done
      p(12)=  done
      e(13)=  1.108d-01
      d(13)=  done
      return
c
c     rhodium
c
  700 continue
      e(1)=  5.687d+01
      e(2)=  5.945d+00
      e(3)=  4.078d+00
      e(4)=  1.547d+00
      s(1)= -3.087d-03
      s(2)=  7.0051d-01
      s(3)= -2.160867d+00
      s(4)=  2.029434d+00
      p(1)= -3.748d-03
      p(2)= -1.4772d-02
      p(3)= -2.68975d-01
      p(4)=  1.193604d+00
      e(5)=  1.156d+01
      e(6)=  2.24d+00
      e(7)=  1.015d+00
      d(5)=  1.3519d-02
      d(6)=  3.70081d-01
      d(7)=  6.84936d-01
      e(8)=  3.96d-01
      d(8)=  done
      e(9)=  1.894d+00
      e(10)=  1.179d-01
      s(9)= -8.17d-02
      s(10)=  1.023308d+00
      p(9)= -7.1093d-02
      p(10)=  1.00828d+00
      e(11)=  4.219d-02
      s(11)=  done
      p(11)=  done
      e(12)=  5.963d-01
      s(12)=  done
      p(12)=  done
      e(13)=  1.262d-01
      d(13)=  done
      return
c
c     palladium
c
  800 continue
      e(1)=  4.182d+01
      e(2)=  5.46d+00
      e(3)=  4.6d+00
      e(4)=  1.752d+00
      s(1)= -1.6522d-02
      s(2)=  2.749478d+00
      s(3)= -4.457343d+00
      s(4)=  2.253933d+00
      p(1)= -5.555d-03
      p(2)=  5.6773d-02
      p(3)= -3.88641d-01
      p(4)=  1.231997d+00
      e(5)=  1.24d+01
      e(6)=  2.404d+00
      e(7)=  1.143d+00
      d(5)=  1.3759d-02
      d(6)=  3.94121d-01
      d(7)=  6.55946d-01
      e(8)=  4.693d-01
      d(8)=  done
      e(9)=  2.177d+00
      e(10)=  1.149d-01
      s(9)= -7.5029d-02
      s(10)=  1.019049d+00
      p(9)= -5.6178d-02
      p(10)=  1.005515d+00
      e(11)=  4.219d-02
      s(11)=  done
      p(11)=  done
      e(12)=  6.691d-01
      s(12)=  done
      p(12)=  done
      e(13)=  1.513d-01
      d(13)=  done
      return
c
c     silver
c
  900 continue
      e(1)=  6.356d+01
      e(2)=  6.39d+00
      e(3)=  5.022d+00
      e(4)=  1.789d+00
      s(1)= -7.31d-04
      s(2)=  1.392736d+00
      s(3)= -2.873102d+00
      s(4)=  2.017361d+00
      p(1)= -4.234d-03
      p(2)=  6.1276d-02
      p(3)= -3.38746d-01
      p(4)=  1.190832d+00
      e(5)=  1.464d+01
      e(6)=  2.693d+00
      e(7)=  1.233d+00
      d(5)=  1.3628d-02
      d(6)=  3.72695d-01
      d(7)=  6.81294d-01
      e(8)=  5.057d-01
      d(8)=  done
      e(9)=  2.451d+00
      e(10)=  1.561d-01
      s(9)= -7.2539d-02
      s(10)=  1.021358d+00
      p(9)= -4.983d-02
      p(10)=  1.006516d+00
      e(11)=  5.227d-02
      s(11)=  done
      p(11)=  done
      e(12)=  6.871d-01
      s(12)=  done
      p(12)=  done
      e(13)=  1.9d-01
      d(13)=  done
      return
c
c     cadmium
c
 1000 continue
      e(1)=  6.338d+01
      e(2)=  6.714d+00
      e(3)=  5.602d+00
      e(4)=  1.971d+00
      s(1)= -4.64d-04
      s(2)=  2.292877d+00
      s(3)= -3.902884d+00
      s(4)=  2.084604d+00
      p(1)= -4.874d-03
      p(2)=  1.8963d-01
      p(3)= -4.91872d-01
      p(4)=  1.213501d+00
      e(5)=  1.551d+01
      e(6)=  2.941d+00
      e(7)=  1.379d+00
      d(5)=  1.2065d-02
      d(6)=  3.70168d-01
      d(7)=  6.8076d-01
      e(8)=  5.782d-01
      d(8)=  done
      e(9)=  2.696d+00
      e(10)=  1.758d-01
      s(9)= -6.4866d-02
      s(10)=  1.019661d+00
      p(9)= -5.3338d-02
      p(10)=  1.007102d+00
      e(11)=  5.647d-02
      s(11)=  done
      p(11)=  done
      e(12)=  7.689d-01
      s(12)=  done
      p(12)=  done
      e(13)=  2.3d-01
      d(13)=  done
      return
      end
      subroutine ectm3(e,s,p,d,n)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
c
      parameter (done=1.d+00)
c
c     stevens, jasien, krauss, basch exponents and contraction
c     coefficients for the third transition series.
c     note that the lanthanides, except lanthanum, are set in
c     ecplan.
c
      nn = n-70
      if(n.eq.57) nn=1
      go to (100,200,300,400,500,600,700,800,900,1000), nn
c
c     lanthanum
c
  100 continue
      e(1)=  9.173d+00
      e(2)=  3.12d+00
      e(3)=  2.104d+00
      e(4)=  1.32d+00
      e(5)=  4.96d-01
      s(1)= -5.4833d-02
      s(2)=  6.76604d-01
      s(3)= -1.034429d+00
      s(4)= -5.18907d-01
      s(5)=  1.631603d+00
      p(1)= -9.798d-03
      p(2)=  2.31262d-01
      p(3)= -6.01215d-01
      p(4)=  1.95189d-01
      p(5)=  1.076137d+00
      e(6)=  1.238d+00
      e(7)=  6.061d-01
      e(8)=  2.518d-01
      d(6)= -5.3797d-02
      d(7)=  3.80144d-01
      d(8)=  7.20349d-01
      e(9)=  9.787d-02
      d(9)=  done
      e(10)=  6.182d-01
      e(11)=  4.546d-02
      s(10)= -1.07095d-01
      s(11)=  1.033448d+00
      p(10)= -5.1869d-02
      p(11)=  1.008108d+00
      e(12)=  1.775d-02
      s(12)=  done
      p(12)=  done
      e(13)=  2.004d-01
      s(13)=  done
      p(13)=  done
      e(14)=  3.536d-02
      d(14)=  done
      return
c
c     hafnium
c
  200 continue
      e(1)=  4.711d+00
      e(2)=  3.331d+00
      e(3)=  9.844d-01
      e(4)=  3.587d-01
      s(1)=  4.03273d-01
      s(2)= -9.9654d-01
      s(3)=  9.79338d-01
      s(4)=  4.45791d-01
      p(1)=  1.3791d-02
      p(2)= -1.79991d-01
      p(3)=  6.93601d-01
      p(4)=  4.61877d-01
      e(5)=  3.298d+00
      e(6)=  9.286d-01
      e(7)=  3.405d-01
      d(5)= -5.062d-03
      d(6)=  4.27636d-01
      d(7)=  6.67943d-01
      e(8)=  1.23d-01
      d(8)=  done
      e(9)=  8.568d-02
      s(9)=  done
      p(9)=  done
      e(10)=  3.5d-02
      s(10)=  done
      p(10)=  done
      e(11)=  6.448d-01
      s(11)=  done
      p(11)=  done
      e(12)=  4.268d-02
      d(12)=  done
      return
c
c     tantalum
c
  300 continue
      e(1)=  5.554d+00
      e(2)=  3.436d+00
      e(3)=  1.033d+00
      e(4)=  3.747d-01
      s(1)=  2.64429d-01
      s(2)= -8.65843d-01
      s(3)=  1.008583d+00
      s(4)=  4.20826d-01
      p(1)=  1.6092d-02
      p(2)= -1.82862d-01
      p(3)=  7.22442d-01
      p(4)=  4.36168d-01
      e(5)=  3.438d+00
      e(6)=  1.016d+00
      e(7)=  3.733d-01
      d(5)= -1.0797d-02
      d(6)=  4.39474d-01
      d(7)=  6.58929d-01
      e(8)=  1.351d-01
      d(8)=  done
      e(9)=  9.34d-02
      s(9)=  done
      p(9)=  done
      e(10)=  3.684d-02
      s(10)=  done
      p(10)=  done
      e(11)=  7.315d-01
      s(11)=  done
      p(11)=  done
      e(12)=  4.807d-02
      d(12)=  done
      return
c
c     tungsten
c
  400 continue
      e(1)=  4.328d+00
      e(2)=  3.898d+00
      e(3)=  1.108d+00
      e(4)=  4.047d-01
      s(1)=  1.97396d+00
      s(2)= -2.605377d+00
      s(3)=  1.05292d+00
      s(4)=  4.12613d-01
      p(1)=  1.72752d-01
      p(2)= -3.48372d-01
      p(3)=  7.27425d-01
      p(4)=  4.34635d-01
      e(5)=  3.653d+00
      e(6)=  1.112d+00
      e(7)=  4.148d-01
      d(5)= -1.6297d-02
      d(6)=  4.50108d-01
      d(7)=  6.48857d-01
      e(8)=  1.495d-01
      d(8)=  done
      e(9)=  9.776d-02
      s(9)=  done
      p(9)=  done
      e(10)=  3.75d-02
      s(10)=  done
      p(10)=  done
      e(11)=  8.219d-01
      s(11)=  done
      p(11)=  done
      e(12)=  5.255d-02
      d(12)=  done
      return
c
c     rhenium
c
  500 continue
      e(1)=  4.666d+00
      e(2)=  4.062d+00
      e(3)=  1.188d+00
      e(4)=  4.339d-01
      s(1)=  1.451709d+00
      s(2)= -2.101771d+00
      s(3)=  1.062295d+00
      s(4)=  4.16694d-01
      p(1)=  1.56457d-01
      p(2)= -3.429d-01
      p(3)=  7.38595d-01
      p(4)=  4.32092d-01
      e(5)=  3.846d+00
      e(6)=  1.216d+00
      e(7)=  4.585d-01
      d(5)= -2.136d-02
      d(6)=  4.56284d-01
      d(7)=  6.43606d-01
      e(8)=  1.659d-01
      d(8)=  done
      e(9)=  1.048d-01
      s(9)=  done
      p(9)=  done
      e(10)=  3.981d-02
      s(10)=  done
      p(10)=  done
      e(11)=  9.127d-01
      s(11)=  done
      p(11)=  done
      e(12)=  5.836d-02
      d(12)=  done
      return
c
c     osmium
c
  600 continue
      e(1)=  5.019d+00
      e(2)=  4.444d+00
      e(3)=  1.23d+00
      e(4)=  4.501d-01
      s(1)=  1.726729d+00
      s(2)= -2.364185d+00
      s(3)=  1.070406d+00
      s(4)=  3.91956d-01
      p(1)=  2.83956d-01
      p(2)= -4.62163d-01
      p(3)=  7.63251d-01
      p(4)=  4.03944d-01
      e(5)=  3.829d+00
      e(6)=  1.339d+00
      e(7)=  5.165d-01
      d(5)= -2.8163d-02
      d(6)=  4.57633d-01
      d(7)=  6.42551d-01
      e(8)=  1.88d-01
      d(8)=  done
      e(9)=  1.104d-01
      s(9)=  done
      p(9)=  done
      e(10)=  4.101d-02
      s(10)=  done
      p(10)=  done
      e(11)=  1.002d+00
      s(11)=  done
      p(11)=  done
      e(12)=  6.552d-02
      d(12)=  done
      return
c
c     iridium
c
  700 continue
      e(1)=  5.522d+00
      e(2)=  4.579d+00
      e(3)=  1.289d+00
      e(4)=  4.734d-01
      s(1)=  1.052849d+00
      s(2)= -1.697001d+00
      s(3)=  1.087609d+00
      s(4)=  3.7723d-01
      p(1)=  1.43988d-01
      p(2)= -3.25563d-01
      p(3)=  7.76442d-01
      p(4)=  3.89328d-01
      e(5)=  4.393d+00
      e(6)=  1.403d+00
      e(7)=  5.593d-01
      d(5)= -2.5391d-02
      d(6)=  4.75718d-01
      d(7)=  6.18182d-01
      e(8)=  2.129d-01
      d(8)=  done
      e(9)=  1.159d-01
      s(9)=  done
      p(9)=  done
      e(10)=  4.276d-02
      s(10)=  done
      p(10)=  done
      e(11)=  1.116d+00
      s(11)=  done
      p(11)=  done
      e(12)=  7.634d-02
      d(12)=  done
      return
c
c     platinum
c
  800 continue
      e(1)=  6.653d+00
      e(2)=  3.995d+00
      e(3)=  1.541d+00
      e(4)=  5.599d-01
      s(1)=  2.82256d-01
      s(2)= -1.075967d+00
      s(3)=  1.131255d+00
      s(4)=  4.78241d-01
      p(1)=  3.6575d-02
      p(2)= -2.84606d-01
      p(3)=  7.52346d-01
      p(4)=  4.76585d-01
      e(5)=  4.658d+00
      e(6)=  1.487d+00
      e(7)=  6.093d-01
      d(5)= -2.6327d-02
      d(6)=  4.95995d-01
      d(7)=  5.94877d-01
      e(8)=  2.527d-01
      d(8)=  done
      e(9)=  1.277d-01
      s(9)=  done
      p(9)=  done
      e(10)=  4.754d-02
      s(10)=  done
      p(10)=  done
      e(11)=  1.2d+00
      s(11)=  done
      p(11)=  done
      e(12)=  9.508d-02
      d(12)=  done
      return
c
c     gold
c
  900 continue
      e(1)=  7.419d+00
      e(2)=  4.023d+00
      e(3)=  1.698d+00
      e(4)=  6.271d-01
      s(1)=  2.22546d-01
      s(2)= -1.086045d+00
      s(3)=  1.156039d+00
      s(4)=  5.18061d-01
      p(1)=  1.9924d-02
      p(2)= -2.99997d-01
      p(3)=  7.48919d-01
      p(4)=  5.04023d-01
      e(5)=  3.63d+00
      e(6)=  1.912d+00
      e(7)=  8.423d-01
      d(5)= -8.7402d-02
      d(6)=  4.68634d-01
      d(7)=  6.54805d-01
      e(8)=  3.756d-01
      d(8)=  done
      e(9)=  1.515d-01
      s(9)=  done
      p(9)=  done
      e(10)=  4.925d-02
      s(10)=  done
      p(10)=  done
      e(11)=  1.502d+00
      s(11)=  done
      p(11)=  done
      e(12)=  1.544d-01
      d(12)=  done
      return
c
c     mercury
c
 1000 continue
      e(1)=  2.554d+01
      e(2)=  8.458d+00
      e(3)=  4.493d+00
      e(4)=  1.751d+00
      e(5)=  6.753d-01
      s(1)= -2.2041d-02
      s(2)=  3.09845d-01
      s(3)= -1.080984d+00
      s(4)=  1.0936d+00
      s(5)=  5.19202d-01
      p(1)= -6.068d-03
      p(2)=  6.3d-02
      p(3)= -3.14502d-01
      p(4)=  7.46398d-01
      p(5)=  4.87253d-01
      e(6)=  4.204d+00
      e(7)=  1.871d+00
      e(8)=  8.215d-01
      d(6)= -5.5849d-02
      d(7)=  4.78221d-01
      d(8)=  6.22006d-01
      e(9)=  3.7d-01
      d(9)=  done
      e(10)=  1.52d-01
      s(10)=  done
      p(10)=  done
      e(11)=  4.78d-02
      s(11)=  done
      p(11)=  done
      e(12)=  1.586d+00
      s(12)=  done
      p(12)=  done
      e(13)=  1.674d-01
      d(13)=  done
      return
      end
      subroutine ec2bas(e,s,p,n,omin)
c
c     ----- Hay ECP basis  sets
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*)
      nn = n-10
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- na ----
c
100   continue
      e(1) = 0.4972d0
      e(2) = 0.0560d0
      e(3) = 0.0221d0
      e(4) = 0.6697d0
      e(5) = 0.0636d0
      e(6) = 0.0204d0
      If(omin) then
         s(1) = -0.1691179d0
         s(2) =  0.6749776d0
         s(3) =  0.4189118d0
         p(4) = -0.0293850d0
         p(5) =  0.4357419d0
         p(6) =  0.6551108d0
      else
         s(1) = -0.2753574d0
         s(2) =  1.0989969d0
         s(3) =  1.0000000d0
         p(4) = -0.0683845d0
         p(5) =  1.0140550d0
         p(6) =  1.0000000d0
      endif
      return
c
c     ----- mg ----
c
 120  continue
      e(1) = 0.7250d0
      e(2) = 0.1112d0
      e(3) = 0.0404d0
      e(4) = 1.2400d0
      e(5) = 0.1346d0
      e(6) = 0.0422d0
      If(omin) then
         s(1) = -0.2064601d0
         s(2) =  0.5946231d0
         s(3) =  0.5308271d0
         p(4) = -0.0364350d0
         p(5) =  0.4946187d0
         p(6) =  0.6045677d0
      else
         s(1) = -0.4058454d0
         s(2) =  1.1688704d0
         s(3) =  1.0000000d0
         p(4) = -0.0749753d0
         p(5) =  1.0178183d0
         p(6) =  1.0000000d0
      endif
      return
c
c     ----- al -----
c
  140 continue
      e(1) = 0.9615d0
      e(2) = 0.1819d0
      e(3) = 0.0657d0
      e(4) = 1.9280d0
      e(5) = 0.2013d0
      e(6) = 0.0580d0
      If(omin) then
         s(1) = -0.2484069d0
         s(2) =  0.6105639d0
         s(3) =  0.5443899d0
         p(4) = -0.0337570d0
         p(5) =  0.4814472d0
         p(6) =  0.6281982d0
      else
         s(1) = -0.5021546d0
         s(2) =  1.2342547d0
         s(3) =  1.0000000d0
         p(4) = -0.0712584d0
         p(5) =  1.0162966d0
         p(6) =  1.0000000d0
      endif
      return
c
c     ----- si -----
c
  160 continue
      e(1) = 1.2220d0
      e(2) = 0.2595d0
      e(3) = 0.0931d0
      e(4) = 2.5800d0
      e(5) = 0.2984d0
      e(6) = 0.0885d0
      If(omin) then
         s(1) = -0.2744620d0
         s(2) =  0.6166890d0
         s(3) =  0.5580860d0
         p(4) = -0.0397850d0
         p(5) =  0.5219971d0
         p(6) =  0.5873821d0
         else
         s(1) = -0.5707339d0
         s(2) =  1.2823826d0
         s(3) =  1.0000000d0
         p(4) = -0.0777250d0
         p(5) =  1.0197870d0
         p(6) =  1.0000000d0
      endif
      return
c
c     ----- p  -----
c
  180 continue
      e(1) = 1.5160d0
      e(2) = 0.3369d0
      e(3) = 0.1211d0
      e(4) = 3.7050d0
      e(5) = 0.3934d0
      e(6) = 0.1190d0
      If(omin) then
         s(1) = -0.2885448d0
         s(2) =  0.6396117d0
         s(3) =  0.5461777d0
         p(4) = -0.0363030d0
         p(5) =  0.5335154d0
         p(6) =  0.5720504d0
      else
         s(1) = -0.5862089d0
         s(2) =  1.2994376d0
         s(3) =  1.0000000d0
         p(4) = -0.0691472d0
         p(5) =  1.0161988d0
         p(6) =  1.0000000d0
      endif
      return
c
c     ----- s  -----
c
  200 continue
      e(1) = 1.8500d0
      e(2) = 0.4035d0
      e(3) = 0.1438d0
      e(4) = 4.9450d0
      e(5) = 0.4870d0
      e(6) = 0.1379d0
      If(omin) then
         s(1) = -0.2916700d0
         s(2) =  0.6992080d0
         s(3) =  0.4901470d0
         p(4) = -0.0344310d0
         p(5) =  0.5737040d0
         p(6) =  0.5410530d0
      else
         s(1) = -0.5324335d0
         s(2) =  1.2763801d0
         s(3) =  1.0000000d0
         p(4) = -0.0608116d0
         p(5) =  1.0132686d0
         p(6) =  1.0000000d0
      endif
      return
c
c     ----- cl ----
c
 220  continue
      e(1) = 2.2310d0
      e(2) = 0.4720d0
      e(3) = 0.1631d0
      e(4) = 6.2960d0
      e(5) = 0.6333d0
      e(6) = 0.1819d0
      If(omin) then
         s(1) = -0.2958918d0
         s(2) =  0.7573126d0
         s(3) =  0.4350998d0
         p(4) = -0.0348650d0
         p(5) =  0.5562549d0
         p(6) =  0.5565879d0
      else
         s(1) = -0.4900589d0
         s(2) =  1.2542684d0
         s(3) =  1.0000000d0
         p(4) = -0.0635641d0
         p(5) =  1.0141355d0
         p(6) =  1.0000000d0
      endif
      return
c
c     ----- ar ----
c
 240  continue
      e(1) = 2.6130d0
      e(2) = 0.5736d0
      e(3) = 0.2014d0
      e(4) = 7.8600d0
      e(5) = 0.7387d0
      e(6) = 0.2081d0
      If(omin) then
         s(1) = -0.2977400d0
         s(2) =  0.7399851d0
         s(3) =  0.4553460d0
         p(4) = -0.0319740d0
         p(5) =  0.5826147d0
         p(6) =  0.5321287d0
      else
         s(1) = -0.5110463d0
         s(2) =  1.2701236d0
         s(3) =  1.0000000d0
         p(4) = -0.0555167d0
         p(5) =  1.0115982d0
         p(6) =  1.0000000d0
      endif
      return
c
      end
      subroutine ec3bas(e,s,p,d,n,omin,olanl)
c
c     ----- Hay ECP basis and LANL2DZ  sets
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-18
      go to (100,120,130,140,150,160,170,180,190,
     *       200,210,220,230,240,250,260,270,280), nn
c
c     ----- k  ----
c
100   if(olanl) then
       e(   1) =          3.07200000d0
       s(   1) =         -0.30830670d0
       e(   2) =          0.67520000d0
       s(   2) =          0.78207110d0
       e(   3) =          0.25450000d0
       s(   3) =          0.41428830d0
       e(   4) =          3.07200000d0
       s(   4) =          0.18940870d0
       e(   5) =          0.67520000d0
       s(   5) =         -0.54723320d0
       e(   6) =          0.25450000d0
       s(   6) =         -0.75764580d0
       e(   7) =          0.05290000d0
       s(   7) =          0.99521570d0
       e(   8) =          0.02090000d0
       s(   8) =          1.00000000d0
       e(   9) =          8.23300000d0
       p(   9) =         -0.04199190d0
       e(  10) =          0.95260000d0
       p(  10) =          0.57768190d0
       e(  11) =          0.30130000d0
       p(  11) =          0.52346110d0
       e(  12) =          0.03760000d0
       p(  12) =          1.00000000d0
       e(  13) =          0.01400000d0
       p(  13) =          1.00000000d0
      else
       e(1) = 0.2099d0
       e(2) = 0.0529d0
       e(3) = 0.0209d0
       e(4) = 0.2794d0
       e(5) = 0.0376d0
       e(6) = 0.0140d0
       If(omin) then
       s(1) = -0.2871128d0
       s(2) =  0.4206847d0
       s(3) =  0.7493584d0
       p(4) = -0.0508040d0
       p(5) =  0.5239690d0
       p(6) =  0.5575560d0
       else
       s(1) = -0.9790253d0
       s(2) =  1.4344918d0
       s(3) =  1.0000000d0
       p(4) = -0.0997817d0
       p(5) =  1.0291027d0
       p(6) =  1.0000000d0
       endif
      endif
      return
c
c     ----- ca ----
c
 120  if(olanl) then
       e(   1) =          3.48400000d0
       s(   1) =         -0.33373700d0
       e(   2) =          0.85510000d0
       s(   2) =          0.75898310d0
       e(   3) =          0.31920000d0
       s(   3) =          0.46061090d0
       e(   4) =          3.48400000d0
       s(   4) =          0.26060300d0
       e(   5) =          0.85510000d0
       s(   5) =         -0.68391500d0
       e(   6) =          0.31920000d0
       s(   6) =         -1.19878070d0
       e(   7) =          0.14470000d0
       s(   7) =          1.02512210d0
       e(   8) =          0.03500000d0
       s(   8) =          1.00000000d0
       e(   9) =          9.42000000d0
       p(   9) =         -0.04369430d0
       e(  10) =          1.15000000d0
       p(  10) =          0.60347470d0
       e(  11) =          0.36880000d0
       p(  11) =          0.49611070d0
       e(  12) =          0.07050000d0
       p(  12) =          1.00000000d0
       e(  13) =          0.02630000d0
       p(  13) =          1.00000000d0
      else
       e(1) = 0.2342d0
       e(2) = 0.1447d0
       e(3) = 0.0350d0
       e(4) = 0.4119d0
       e(5) = 0.0705d0
       e(6) = 0.0263d0
       If(omin) then
       s(1) = -0.6975968d0
       s(2) =  0.6897188d0
       s(3) =  0.8833578d0
       p(4) = -0.0735430d0
       p(5) =  0.5797403d0
       p(6) =  0.5123463d0
       else
       s(1) = -3.4613442d0
       s(2) =  3.4222550d0
       s(3) =  1.0000000d0
       p(4) = -0.1330041d0
       p(5) =  1.0484721d0
       p(6) =  1.0000000d0
       endif
      endif
      return
c
c ----- sc
c
 130  if(olanl) then
       e( 1) =          3.71700000d0
       s( 1) =         -0.39262920d0
       e( 2) =          1.09700000d0
       s( 2) =          0.71473390d0
       e( 3) =          0.41640000d0
       s( 3) =          0.55094000d0
       e( 4) =          3.71700000d0
       s( 4) =          0.21974460d0
       e( 5) =          1.09700000d0
       s( 5) =         -0.45460670d0
       e( 6) =          0.41640000d0
       s( 6) =         -0.69381810d0
       e( 7) =          0.07610000d0
       s( 7) =          1.12601720d0
       e( 8) =          0.02840000d0
       s( 8) =          1.00000000d0
       e( 9) =         10.40000000d0
       p( 9) =         -0.04926150d0
       e(10) =          1.31100000d0
       p(10) =          0.60719650d0
       e(11) =          0.42660000d0
       p(11) =          0.49175820d0
       e(12) =          0.04700000d0
       p(12) =          1.00000000d0
       e(13) =          0.01400000d0
       p(13) =          1.00000000d0
       e(14) =         15.13000000d0
       d(14) =          0.03792910d0
       e(15) =          4.20500000d0
       d(15) =          0.17383600d0
       e(16) =          1.30300000d0
       d(16) =          0.42680570d0
       e(17) =          0.36800000d0
       d(17) =          0.62385390d0
       e(18) =          0.08120000d0
       d(18) =          1.00000000d0
      else
      e(1) = 0.3077d0
      e(2) = 0.0761d0
      e(3) = 0.0284d0
      e(4) = 0.0470d0
      e(5) = 0.0140d0
      e(6) = 15.1300d0
      e(7) = 4.2050d0
      e(8) = 1.3030d0
      e(9) = 0.3683d0
      e(10) = 0.08122d0
      If(omin) then
      s(1) = -0.3002444d0
      s(2) =  0.5832849d0
      s(3) = 0.6108632d0
      p(4) = 0.7575277d0
      p(5) = 0.3256854d0
      d(6) = 0.0314705d0
      d(7) = 0.1449296d0
      d(8) = 0.3554122d0
      d(9) = 0.5159288d0
      d(10) = 0.3716804d0
      else
      s(1) = -0.7057998d0
      s(2) =  1.3711575d0
      s(3) =  1.0000000d0
      p(4) =  1.0000000d0
      p(5) =  1.0000000d0
      d(6) =   0.0379251d0
      d(7) =   0.1746549d0
      d(8) =   0.4283077d0
      d(9) =   0.6217465d0
      d(10) =  1.0000000d0
      endif
      endif
      return
c
c ----- ti
c
 140  if(olanl) then
       e( 1) =          4.37200000d0
       s( 1) =         -0.36370980d0
       e( 2) =          1.09800000d0
       s( 2) =          0.81845330d0
       e( 3) =          0.41780000d0
       s( 3) =          0.41845260d0
       e( 4) =          4.37200000d0
       s( 4) =          0.20490270d0
       e( 5) =          1.09800000d0
       s( 5) =         -0.55754130d0
       e( 6) =          0.41780000d0
       s( 6) =         -0.58936520d0
       e( 7) =          0.08720000d0
       s( 7) =          1.14516610d0
       e( 8) =          0.03140000d0
       s( 8) =          1.00000000d0
       e( 9) =         12.52000000d0
       p( 9) =         -0.04569080d0
       e(10) =          1.49100000d0
       p(10) =          0.62033130d0
       e(11) =          0.48590000d0
       p(11) =          0.47653290d0
       e(12) =          0.05300000d0
       p(12) =          1.00000000d0
       e(13) =          0.01600000d0
       p(13) =          1.00000000d0
       e(14) =         20.21000000d0
       d(14) =          0.03416820d0
       e(15) =          5.49500000d0
       d(15) =          0.17100060d0
       e(16) =          1.69900000d0
       d(16) =          0.44058490d0
       e(17) =          0.48400000d0
       d(17) =          0.61142460d0
       e(18) =          0.11570000d0
       d(18) =          1.00000000d0
      else
      e(1) = 0.3560d0
      e(2) = 0.0872d0
      e(3) = 0.0314d0
      e(4) = 0.0530d0
      e(5) = 0.0160d0
      e(6) = 20.2100d0
      e(7) = 5.4950d0
      e(8) = 1.6990d0
      e(9) = 0.4840d0
      e(10) = 0.1157d0
      If(omin) then
      s(1) = -0.2919751d0
      s(2) =  0.5537924d0
      s(3) = 0.6353389d0
      p(4) = 0.7007589d0
      p(5) = 0.3894470d0
      d(6) = 0.0290178d0
      d(7) = 0.1456664d0
      d(8) = 0.3752920d0
      d(9) = 0.5150936d0
      d(10) = 0.3334562d0
      else
      s(1) = -0.7239276d0
      s(2) =  1.3730815d0
      s(3) =  1.0000000d0
      p(4) =  1.0000000d0
      p(5) =  1.0000000d0
      d(6) =  0.0342651d0
      d(7) =  0.1720072d0
      d(8) =  0.4431560d0
      d(9) =  0.6082378d0
      d(10) = 1.0000000d0
      endif
      endif
      return
c
c ----- v
c
 150  if(olanl) then
       e( 1) =          4.59000000d0
       s( 1) =         -0.42773020d0
       e( 2) =          1.49300000d0
       s( 2) =          0.70696910d0
       e( 3) =          0.55700000d0
       s( 3) =          0.58958130d0
       e( 4) =          4.59000000d0
       s( 4) =          0.25010810d0
       e( 5) =          1.49300000d0
       s( 5) =         -0.46977770d0
       e( 6) =          0.55700000d0
       s( 6) =         -0.71294150d0
       e( 7) =          0.09750000d0
       s( 7) =          1.10065690d0
       e( 8) =          0.03420000d0
       s( 8) =          1.00000000d0
       e( 9) =         13.76000000d0
       p( 9) =         -0.04823120d0
       e(10) =          1.71200000d0
       p(10) =          0.61411610d0
       e(11) =          0.55870000d0
       p(11) =          0.48383420d0
       e(12) =          0.05900000d0
       p(12) =          1.00000000d0
       e(13) =          0.01800000d0
       p(13) =          1.00000000d0
       e(14) =         25.70000000d0
       d(14) =          0.03310330d0
       e(15) =          6.53000000d0
       d(15) =          0.17957530d0
       e(16) =          2.07800000d0
       d(16) =          0.43730620d0
       e(17) =          0.62430000d0
       d(17) =          0.59848600d0
       e(18) =          0.15420000d0
       d(18) =          1.00000000d0
      else
      e(1) = 0.4064d0
      e(2) = 0.0975d0
      e(3) = 0.0342d0
      e(4) = 0.0590d0
      e(5) = 0.0180d0
      e(6) = 25.7000d0
      e(7) = 6.5300d0
      e(8) = 2.0780d0
      e(9) = 0.6243d0
      e(10) = 0.1542d0
      If(omin) then
      s(1) = -0.2849561d0
      s(2) =  0.5447320d0
      s(3) = 0.6403582d0
      p(4) = 0.6466282d0
      p(5) = 0.4475728d0
      d(6) = 0.0263649d0
      d(7) = 0.1485117d0
      d(8) = 0.3715161d0
      d(9) = 0.5033771d0
      d(10) = 0.3353727d0
      else
      s(1) = -0.7125749d0
      s(2) =  1.3621829d0
      s(3) =  1.0000000d0
      p(4) =  1.0000000d0
      p(5) =  1.0000000d0
      d(6) =  0.0312848d0
      d(7) =  0.1762254d0
      d(8) =  0.4408447d0
      d(9) =  0.5973122d0
      d(10) = 1.0000000d0
      endif
      endif
      return
c
c ----- cr
c
 160  if(olanl) then
       e( 1) =          5.36100000d0
       s( 1) =         -0.38056890d0
       e( 2) =          1.44900000d0
       s( 2) =          0.77956250d0
       e( 3) =          0.54960000d0
       s( 3) =          0.47307770d0
       e( 4) =          5.36100000d0
       s( 4) =          0.22031110d0
       e( 5) =          1.44900000d0
       s( 5) =         -0.54233910d0
       e( 6) =          0.54960000d0
       s( 6) =         -0.60477160d0
       e( 7) =          0.10520000d0
       s( 7) =          1.11366570d0
       e( 8) =          0.03640000d0
       s( 8) =          1.00000000d0
       e( 9) =         16.42000000d0
       p( 9) =         -0.04613970d0
       e(10) =          1.91400000d0
       p(10) =          0.61099650d0
       e(11) =          0.62410000d0
       p(11) =          0.48596350d0
       e(12) =          0.06300000d0
       p(12) =          1.00000000d0
       e(13) =          0.01900000d0
       p(13) =          1.00000000d0
       e(14) =         28.95000000d0
       d(14) =          0.03377870d0
       e(15) =          7.70800000d0
       d(15) =          0.17803450d0
       e(16) =          2.49500000d0
       d(16) =          0.43700080d0
       e(17) =          0.76550000d0
       d(17) =          0.59417950d0
       e(18) =          0.18890000d0
       d(18) =          1.00000000d0
      else
      e(1) = 0.4596d0
      e(2) = 0.1052d0
      e(3) = 0.0364d0
      e(4) = 0.0630d0
      e(5) = 0.0190d0
      e(6) = 28.9500d0
      e(7) = 7.7080d0
      e(8) = 2.4950d0
      e(9) = 0.7655d0
      e(10) = 0.1889d0
      If(omin) then
      s(1) = -0.2722899d0
      s(2) =  0.5367682d0
      s(3) = 0.6394025d0
      p(4) = 0.6025797d0
      p(5) = 0.4959298d0
      d(6) = 0.0271427d0
      d(7) = 0.1476532d0
      d(8) = 0.3722435d0
      d(9) = 0.5027451d0
      d(10) = 0.3297045d0
      else
      s(1) = -0.6777180d0
      s(2) =  1.3359932d0
      s(3) =  1.0000000d0
      p(4) =  1.0000000d0
      p(5) =  1.0000000d0
      d(6) =  0.0320666d0
      d(7) =  0.1744385d0
      d(8) =  0.4397711d0
      d(9) =  0.5939466d0
      d(10) = 1.0000000d0
      endif
      endif
      return
c
c ----- mn
c
 170  if(olanl) then
      e(   1) =          5.91400000d0
      s(   1) =         -0.37645080d0
      e(   2) =          1.60500000d0
      s(   2) =          0.77247890d0
      e(   3) =          0.62600000d0
      s(   3) =          0.47693460d0
      e(   4) =          5.91400000d0
      s(   4) =          0.21199660d0
      e(   5) =          1.60500000d0
      s(   5) =         -0.51994720d0
      e(   6) =          0.62600000d0
      s(   6) =         -0.58576810d0
      e(   7) =          0.11150000d0
      s(   7) =          1.10039640d0
      e(   8) =          0.03800000d0
      s(   8) =          1.00000000d0
      e(   9) =         18.20000000d0
      p(   9) =         -0.04479010d0
      e(  10) =          2.14100000d0
      p(  10) =          0.62603110d0
      e(  11) =          0.70090000d0
      p(  11) =          0.46963290d0
      e(  12) =          0.06900000d0
      p(  12) =          1.00000000d0
      e(  13) =          0.02100000d0
      p(  13) =          1.00000000d0
      e(  14) =         32.27000000d0
      d(  14) =          0.03415800d0
      e(  15) =          8.87500000d0
      d(  15) =          0.17611050d0
      e(  16) =          2.89000000d0
      d(  16) =          0.43942980d0
      e(  17) =          0.87610000d0
      d(  17) =          0.59432710d0
      e(  18) =          0.21200000d0
      d(  18) =          1.00000000d0
      else
      e(1) = 0.5097d0
      e(2) = 0.1115d0
      e(3) = 0.0380d0
      e(4) = 0.0690d0
      e(5) = 0.0210d0
      e(6) = 32.2700d0
      e(7) = 8.8750d0
      e(8) = 2.8900d0
      e(9) = 0.8761d0
      e(10) = 0.2120d0
      If(omin) then
      s(1) = -0.2600382d0
      s(2) =  0.5266443d0
      s(3) = 0.6412356d0
      p(4) = 0.5410664d0
      p(5) = 0.5571744d0
      d(6) = 0.0277861d0
      d(7) = 0.1473857d0
      d(8) = 0.3767350d0
      d(9) = 0.5038089d0
      d(10) = 0.3274470d0
      else
      s(1) = -0.6484729d0
      s(2) =  1.3133245d0
      s(3) =  1.0000000d0
      p(4) =  1.0000000d0
      p(5) =  1.0000000d0
      d(6) =  0.0326829d0
      d(7) =  0.1733599d0
      d(8) =  0.4431280d0
      d(9) =  0.5925964d0
      d(10) = 1.0000000d0
      endif
      endif
      return
c
c ----- fe
c
 180  if(olanl) then
      e(   1) =          6.42200000d0
      s(   1) =         -0.39278820d0
      e(   2) =          1.82600000d0
      s(   2) =          0.77126430d0
      e(   3) =          0.71350000d0
      s(   3) =          0.49202280d0
      e(   4) =          6.42200000d0
      s(   4) =          0.17868770d0
      e(   5) =          1.82600000d0
      s(   5) =         -0.41940320d0
      e(   6) =          0.71350000d0
      s(   6) =         -0.45681850d0
      e(   7) =          0.10210000d0
      s(   7) =          1.10350480d0
      e(   8) =          0.03630000d0
      s(   8) =          1.00000000d0
      e(   9) =         19.48000000d0
      p(   9) =         -0.04702820d0
      e(  10) =          2.38900000d0
      p(  10) =          0.62488410d0
      e(  11) =          0.77950000d0
      p(  11) =          0.47225420d0
      e(  12) =          0.07400000d0
      p(  12) =          1.00000000d0
      e(  13) =          0.02200000d0
      p(  13) =          1.00000000d0
      e(  14) =         37.08000000d0
      d(  14) =          0.03290000d0
      e(  15) =         10.10000000d0
      d(  15) =          0.17874180d0
      e(  16) =          3.22000000d0
      d(  16) =          0.44876570d0
      e(  17) =          0.96280000d0
      d(  17) =          0.58763610d0
      e(  18) =          0.22620000d0
      d(  18) =          1.00000000d0
      else
      e(1) = 0.5736d0
      e(2) = 0.1021d0
      e(3) = 0.03626d0
      e(4) = 0.0740d0
      e(5) = 0.0220d0
      e(6) = 37.0800d0
      e(7) = 10.1000d0
      e(8) = 3.2200d0
      e(9) = 0.9628d0
      e(10) = 0.2262d0
      If(omin) then
      s(1) = -0.2247884d0
      s(2) =  0.5927703d0
      s(3) = 0.5498673d0
      p(4) = 0.5171734d0
      p(5) = 0.5840788d0
      d(6) = 0.0272770d0
      d(7) = 0.1521108d0
      d(8) = 0.3904070d0
      d(9) = 0.5046913d0
      d(10) = 0.3137533d0
      else
      s(1) = -0.4585154d0
      s(2) =  1.2091119d0
      s(3) =  1.0000000d0
      p(4) =  1.0000000d0
      p(5) =  1.0000000d0
      d(6) =  0.0316328d0
      d(7) =  0.1764010d0
      d(8) =  0.4527502d0
      d(9) =  0.5852844d0
      d(10) = 1.0000000d0
      endif
      endif
      return
c
c ----- co
c
 190  if(olanl) then
      e(   1) =          7.17600000d0
      s(   1) =         -0.38567340d0
      e(   2) =          2.00900000d0
      s(   2) =          0.74531160d0
      e(   3) =          0.80550000d0
      s(   3) =          0.50918190d0
      e(   4) =          7.17600000d0
      s(   4) =          0.17361610d0
      e(   5) =          2.00900000d0
      s(   5) =         -0.39704420d0
      e(   6) =          0.80550000d0
      s(   6) =         -0.46306220d0
      e(   7) =          0.10700000d0
      s(   7) =          1.08996540d0
      e(   8) =          0.03750000d0
      s(   8) =          1.00000000d0
      e(   9) =         21.39000000d0
      p(   9) =         -0.04804130d0
      e(  10) =          2.65000000d0
      p(  10) =          0.62223370d0
      e(  11) =          0.86190000d0
      p(  11) =          0.47580420d0
      e(  12) =          0.08000000d0
      p(  12) =          1.00000000d0
      e(  13) =          0.02300000d0
      p(  13) =          1.00000000d0
      e(  14) =         39.25000000d0
      d(  14) =          0.03615410d0
      e(  15) =         10.78000000d0
      d(  15) =          0.18967440d0
      e(  16) =          3.49600000d0
      d(  16) =          0.45249810d0
      e(  17) =          1.06600000d0
      d(  17) =          0.57104270d0
      e(  18) =          0.26060000d0
      d(  18) =          1.00000000d0
      else
      e(1) = 0.6252d0
      e(2) = 0.1070d0
      e(3) = 0.0375d0
      e(4) = 0.0800d0
      e(5) = 0.0230d0
      e(6) = 39.2500d0
      e(7) = 10.7800d0
      e(8) = 3.4960d0
      e(9) = 1.0660d0
      e(10) = 0.2660d0
      If(omin) then
      s(1) = -0.2146440d0
      s(2) =  0.5714746d0
      s(3) = 0.5649293d0
      p(4) = 0.5051990d0
      p(5) = 0.6005087d0
      d(6) = 0.0301234d0
      d(7) = 0.1621897d0
      d(8) = 0.3941711d0
      d(9) = 0.4911045d0
      d(10) = 0.3075324d0
      else
      s(1) = -0.4505354d0
      s(2) =  1.1995189d0
      s(3) =  1.0000000d0
      p(4) =  1.0000000d0
      p(5) =  1.0000000d0
      d(6) =  0.0348748d0
      d(7) =  0.1877720d0
      d(8) =  0.4563441d0
      d(9) =  0.5685669d0
      d(10) = 1.0000000d0
      endif
      endif
      return
c
c ----- ni
c
 200  if(olanl) then
      e(   1) =          7.62000000d0
      s(   1) =         -0.40825500d0
      e(   2) =          2.29400000d0
      s(   2) =          0.74553080d0
      e(   3) =          0.87600000d0
      s(   3) =          0.53257210d0
      e(   4) =          7.62000000d0
      s(   4) =          0.18725910d0
      e(   5) =          2.29400000d0
      s(   5) =         -0.39669640d0
      e(   6) =          0.87600000d0
      s(   6) =         -0.49540030d0
      e(   7) =          0.11530000d0
      s(   7) =          1.08443430d0
      e(   8) =          0.03960000d0
      s(   8) =          1.00000000d0
      e(   9) =         23.66000000d0
      p(   9) =         -0.04815580d0
      e(  10) =          2.89300000d0
      p(  10) =          0.62584730d0
      e(  11) =          0.94350000d0
      p(  11) =          0.47151580d0
      e(  12) =          0.08400000d0
      p(  12) =          1.00000000d0
      e(  13) =          0.02400000d0
      p(  13) =          1.00000000d0
      e(  14) =         42.72000000d0
      d(  14) =          0.03726990d0
      e(  15) =         11.76000000d0
      d(  15) =          0.19561030d0
      e(  16) =          3.81700000d0
      d(  16) =          0.45612730d0
      e(  17) =          1.16900000d0
      d(  17) =          0.56215870d0
      e(  18) =          0.28360000d0
      d(  18) =          1.00000000d0
      else
      e(1) = 0.6778d0
      e(2) = 0.1116d0
      e(3) = 0.0387d0
      e(4) = 0.0840d0
      e(5) = 0.0240d0
      e(6) = 42.7200d0
      e(7) = 11.7600d0
      e(8) = 3.8170d0
      e(9) = 1.1690d0
      e(10) = 0.2836d0
      If(omin) then
      s(1) = -0.2067432d0
      s(2) =  0.5621607d0
      s(3) = 0.5695310d0
      p(4) = 0.4931106d0
      p(5) = 0.6129736d0
      d(6) = 0.0313362d0
      d(7) = 0.1685554d0
      d(8) = 0.3996197d0
      d(9) = 0.4868314d0
      d(10) = 0.3005152d0
      else
      s(1) = -0.4372528d0
      s(2) =  1.1889453d0
      s(3) =  1.0000000d0
      p(4) =  1.0000000d0
      p(5) =  1.0000000d0
      d(6) =  0.0360414d0
      d(7) =  0.1938645d0
      d(8) =  0.4596238d0
      d(9) =  0.5599305d0
      d(10) = 1.0000000d0
      endif
      endif
      return
c
c ----- cu (2d)
c
 210  if(olanl) then
      e(   1) =          8.17600000d0
      s(   1) =         -0.42102600d0
      e(   2) =          2.56800000d0
      s(   2) =          0.73859240d0
      e(   3) =          0.95870000d0
      s(   3) =          0.55256920d0
      e(   4) =          8.17600000d0
      s(   4) =          0.17876650d0
      e(   5) =          2.56800000d0
      s(   5) =         -0.35922730d0
      e(   6) =          0.95870000d0
      s(   6) =         -0.47048250d0
      e(   7) =          0.11530000d0
      s(   7) =          1.08074070d0
      e(   8) =          0.03960000d0
      s(   8) =          1.00000000d0
      e(   9) =         25.63000000d0
      p(   9) =         -0.04891730d0
      e(  10) =          3.16600000d0
      p(  10) =          0.62728540d0
      e(  11) =          1.02300000d0
      p(  11) =          0.47161880d0
      e(  12) =          0.08600000d0
      p(  12) =          1.00000000d0
      e(  13) =          0.02400000d0
      p(  13) =          1.00000000d0
      e(  14) =         41.34000000d0
      d(  14) =          0.04654240d0
      e(  15) =         11.42000000d0
      d(  15) =          0.22278240d0
      e(  16) =          3.83900000d0
      d(  16) =          0.45390590d0
      e(  17) =          1.23000000d0
      d(  17) =          0.53147690d0
      e(  18) =          0.31020000d0
      d(  18) =          1.00000000d0
      else
      e(1) = 0.7307d0
      e(2) = 0.1153d0
      e(3) = 0.0396d0
      e(4) = 0.0860d0
      e(5) = 0.0240d0
      e(6) = 41.3400d0
      e(7) = 11.4200d0
      e(8) = 3.8390d0
      e(9) = 1.2300d0
      e(10) = 0.3102d0
      If(omin) then
      s(1) = -0.1979738d0
      s(2) =  0.5496303d0
      s(3) = 0.5768265d0
      p(4) = 0.4703623d0
      p(5) = 0.6377452d0
      d(6) = 0.0395247d0
      d(7) = 0.1943744d0
      d(8) = 0.4005019d0
      d(9) = 0.4638820d0
      d(10) = 0.2870209d0
      else
      s(1) = -0.4244167d0
      s(2) =  1.1782986d0
      s(3) =  1.0000000d0
      p(4) =  1.0000000d0
      p(5) =  1.0000000d0
      d(6) =  0.0450969d0
      d(7) =  0.2217772d0
      d(8) =  0.4569644d0
      d(9) =  0.5292798d0
      d(10) = 1.0000000d0
      endif
      endif
      return
c
c ----- zn (1s)
c
 220  continue
      e(1) = 0.7997d0
      e(2) = 0.1752d0
      e(3) = 0.0556d0
      e(4) = 0.1202d0
      e(5) = 0.0351d0
      e(6) = 68.8500d0
      e(7) = 18.3200d0
      e(8) = 5.9220d0
      e(9) = 1.9270d0
      e(10) = 0.5528d0
      If(omin) then
      s(1) = -0.2517637d0
      s(2) =  0.5099734d0
      s(3) = 0.6581327d0
      p(4) = 0.6130140d0
      p(5) = 0.4898007d0
      d(6) = 0.0214335d0
      d(7) = 0.1368916d0
      d(8) = 0.3704352d0
      d(9) = 0.4834232d0
      d(10) = 0.3315150d0
      else
      s(1) = -0.6486112d0
      s(2) =  1.3138291d0
      s(3) =  1.0000000d0
      p(4) =  1.0000000d0
      p(5) =  1.0000000d0
      d(6) =  0.0258532d0
      d(7) =  0.1651195d0
      d(8) =  0.4468212d0
      d(9) =  0.5831080d0
      d(10) = 1.0000000d0
      endif
      return
C
c     Ga
C
 230  continue
      e(1) = 0.8306d0
      e(2) = 0.3392d0
      e(3) = 0.0918d0
      e(4) = 1.6750d0
      e(5) = 0.2030d0
      e(6) = 0.0579d0
      If(omin) then
      s(1) = -0.4137939d0
      s(2) =  0.4907699d0
      s(3) =  0.8122499d0
      p(4) = -0.0408020d0
      p(5) =  0.4874108d0
      p(6) =  0.6264438d0
      else
      s(1) = -1.6759436d0
      s(2) =  1.9877108d0
      s(3) =  1.0000000d0
      p(4) = -0.0856107d0
      p(5) =  1.0226850d0
      p(6) =  1.0000000d0
      endif
      return
C
c     ge
C
 240  continue
      e(1) = 0.8935d0
      e(2) = 0.4424d0
      e(3) = 0.1162d0
      e(4) = 1.8770d0
      e(5) = 0.2623d0
      e(6) = 0.0798d0
      If(omin) then
      s(1) = -0.5473100d0
      s(2) =  0.6161590d0
      s(3) =  0.8113429d0
      p(4) = -0.0518020d0
      p(5) =  0.5302898d0
      p(6) =  0.5800398d0
      else
      s(1) = -2.1756591d0
      s(2) =  2.4493467d0
      s(3) =  1.0000000d0
      p(4) = -0.1006779d0
      p(5) =  1.0306256d0
      p(6) =  1.0000000d0
      endif
      return
C
c     as
C
 250  continue
      e(1) = 0.9635d0
      e(2) = 0.5427d0
      e(3) = 0.1407d0
      e(4) = 2.0840d0
      e(5) = 0.3224d0
      e(6) = 0.1020d0
      If(omin) then
      s(1) = -0.6857832d0
      s(2) =  0.7545512d0
      s(3) =  0.8069852d0
      p(4) = -0.0613810d0
      p(5) =  0.5603297d0
      p(6) =  0.5488037d0
      else
      s(1) = -2.6709549d0
      s(2) =  2.9387892d0
      s(3) =  1.0000000d0
      p(4) = -0.1137100d0
      p(5) =  1.0380266d0
      p(6) =  1.0000000d0
      endif
      return
C
c     Se
C
 260  continue
      e(1) = 1.0330d0
      e(2) = 0.6521d0
      e(3) = 0.1660d0
      e(4) = 2.3660d0
      e(5) = 0.3833d0
      e(6) = 0.1186d0
      If(omin) then
      s(1) = -0.9057412d0
      s(2) =  0.9815111d0
      s(3) =  0.7922743d0
      p(4) = -0.0655770d0
      p(5) =  0.5760669d0
      p(6) =  0.5382919d0
      else
      s(1) = -3.3224095d0
      s(2) =  3.6003462d0
      s(3) =  1.0000000d0
      p(4) = -0.1185522d0
      p(5) =  1.0414320d0
      p(6) =  1.0000000d0
      endif
      return
C
c     br
C
 270  continue
      e(1) = 1.1590d0
      e(2) = 0.7107d0
      e(3) = 0.1905d0
      e(4) = 2.6910d0
      e(5) = 0.4446d0
      e(6) = 0.1377d0
      If(omin) then
      s(1) = -0.8690699d0
      s(2) =  0.9641899d0
      s(3) =  0.7737520d0
      p(4) = -0.0673380d0
      p(5) =  0.5899843d0
      p(6) =  0.5251153d0
      else
      s(1) = -3.0378769d0
      s(2) =  3.3703735d0
      s(3) =  1.0000000d0
      p(4) = -0.1189800d0
      p(5) =  1.0424471d0
      p(6) =  1.0000000d0
      endif
      return
C
c     kr
C
 280  continue
      e(1) = 1.2270d0
      e(2) = 0.8457d0
      e(3) = 0.2167d0
      e(4) = 2.9200d0
      e(5) = 0.5169d0
      e(6) = 0.1614d0
      If(omin) then
      s(1) = -1.1859395d0
      s(2) =  1.2811545d0
      s(3) =  0.7678797d0
      p(4) = -0.0759660d0
      p(5) =  0.5995830d0
      p(6) =  0.5182310d0
      else
      s(1) = -4.0317198d0
      s(2) =  4.3554125d0
      s(3) =  1.0000000d0
      p(4) = -0.1330685d0
      p(5) =  1.0502807d0
      p(6) =  1.0000000d0
      endif
      return
      end
      subroutine ec4bas(e,s,p,d,n,omin,olanl)
c
c     ----- Hay ECP basis and LANL2DZ  sets
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-36
      go to (100,120,130,140,150,160,170,180,190,
     *       200,210,220,230,240,250,260,270,280), nn
C
c     Rb
C
100   if(olanl) then
       e( 1) =          1.45700000d0
       s( 1) =         -1.06174060d0
       e( 2) =          0.94000000d0
       s( 2) =          1.17221250d0
       e( 3) =          0.27060000d0
       s( 3) =          0.74370080d0
       e( 4) =          1.45700000d0
       s( 4) =          0.50521740d0
       e( 5) =          0.94000000d0
       s( 5) =         -0.57184040d0
       e( 6) =          0.27060000d0
       s( 6) =         -0.68353080d0
       e( 7) =          0.03660000d0
       s( 7) =          1.11364770d0
       e( 8) =          0.01550000d0
       s( 8) =          1.00000000d0
       e( 9) =          3.30000000d0
       p( 9) =         -0.07294170d0
       e(10) =          0.59850000d0
       p(10) =          0.63217820d0
       e(11) =          0.20670000d0
       p(11) =          0.47074260d0
       e(12) =          0.19470000d0
       p(12) =         -0.12505520d0
       e(13) =          0.03180000d0
       p(13) =          1.04382060d0
       e(14) =          0.01240000d0
       p(14) =          1.00000000d0
      else
       e(1) = 0.1756d0
       e(2) = 0.0366d0
       e(3) = 0.0155d0
       e(4) = 0.1947d0
       e(5) = 0.0318d0
       e(6) = 0.0124d0
       If(omin) then
       s(1) = -0.2912452d0
       s(2) =  0.6631344d0
       s(3) =  0.5088743d0
       p(4) = -0.0659050d0
       p(5) =  0.5501010d0
       p(6) =  0.5337630d0
       else
       s(1) = -0.5596355d0
       s(2) =  1.2742307d0
       s(3) =  1.0000000d0
       p(4) = -0.1250552d0
       p(5) =  1.0438206d0
       p(6) =  1.0000000d0
       endif
      endif
      return
C
c     Sr
C
120   if(olanl) then
       e(   1) =          1.64800000d0
       s(   1) =         -0.95198790d0
       e(   2) =          1.00300000d0
       s(   2) =          1.08698570d0
       e(   3) =          0.31060000d0
       s(   3) =          0.72031600d0
       e(   4) =          1.64800000d0
       s(   4) =          0.79143370d0
       e(   5) =          1.00300000d0
       s(   5) =         -0.94340460d0
       e(   6) =          0.31060000d0
       s(   6) =         -1.30430630d0
       e(   7) =          0.10990000d0
       s(   7) =          0.90468690d0
       e(   8) =          0.02920000d0
       s(   8) =          1.00000000d0
       e(   9) =          3.55200000d0
       p(   9) =         -0.08864610d0
       e(  10) =          0.69750000d0
       p(  10) =          0.66618570d0
       e(  11) =          0.24800000d0
       p(  11) =          0.43907050d0
       e(  12) =          0.27350000d0
       p(  12) =         -0.17874700d0
       e(  13) =          0.05700000d0
       p(  13) =          1.07661340d0
       e(  14) =          0.02220000d0
       p(  14) =          1.00000000d0
      else
       e(1) = 0.1865d0
       e(2) = 0.1099d0
       e(3) = 0.0292d0
       e(4) = 0.2735d0
       e(5) = 0.0570d0
       e(6) = 0.0222d0
       If(omin) then
       s(1) = -0.7123187d0
       s(2) =  0.7327107d0
       s(3) =  0.8470097d0
       p(4) = -0.0989490d0
       p(5) =  0.5959809d0
       p(6) =  0.5039349d0
       else
       s(1) = -3.0896684d0
       s(2) =  3.1781183d0
       s(3) =  1.0000000d0
       p(4) = -0.1787470d0
       p(5) =  1.0766134d0
       p(6) =  1.0000000d0
       endif
      endif
      return
C
c     Y
C
130   if (olanl) then
      e(   1) =          1.75100000d0
      s(   1) =         -1.16179050d0
      e(   2) =          1.14300000d0
      s(   2) =          1.29588770d0
      e(   3) =          0.35810000d0
      s(   3) =          0.71151250d0
      e(   4) =          1.75100000d0
      s(   4) =          0.96831230d0
      e(   5) =          1.14300000d0
      s(   5) =         -1.13463670d0
      e(   6) =          0.35810000d0
      s(   6) =         -1.19140540d0
      e(   7) =          0.10580000d0
      s(   7) =          0.92810630d0
      e(   8) =          0.03180000d0
      s(   8) =          1.00000000d0
      e(   9) =          3.88400000d0
      p(   9) =         -0.08206010d0
      e(  10) =          0.76600000d0
      p(  10) =          0.67564130d0
      e(  11) =          0.28900000d0
      p(  11) =          0.41954820d0
      e(  12) =          0.28960000d0
      p(  12) =         -0.15010800d0
      e(  13) =          0.06290000d0
      p(  13) =          1.06869260d0
      e(  14) =          0.02230000d0
      p(  14) =          1.00000000d0
      e(  15) =          1.52300000d0
      d(  15) =          0.10748430d0
      e(  16) =          0.56340000d0
      d(  16) =          0.45639540d0
      e(  17) =          0.18340000d0
      d(  17) =          0.60398550d0
      e(  18) =          0.05690000d0
      d(  18) =          1.00000000d0
      else
      e(1) =  0.2081d0
      e(2) =  0.1058d0
      e(3) =  0.0318d0
      e(4) =  0.2896d0
      e(5) =  0.0629d0
      e(6) =  0.0223d0
      e(7) =  1.5230d0
      e(8) =  0.5634d0
      e(9) =  0.1843d0
      e(10) =  0.0569d0
      If(omin) then
      s(1) = -0.5896795d0
      s(2) =  0.6660333d0
      s(3) =  0.7963108d0
      p(4) = -0.0768697d0
      p(5) =  0.5472731d0
      p(6) =  0.5580630d0
      d(7) = 0.0926789d0
      d(8) = 0.3704772d0
      d(9) = 0.5006576d0
      d(10) = 0.3203606d0
      else
      s(1) = -2.2404831d0
      s(2) =  2.5305889d0
      s(3) =  1.0000000d0
      p(4) = -0.1501080d0
      p(5) =  1.0686926d0
      p(6) =  1.0000000d0
      d(7) = 0.1124043d0
      d(8) = 0.4493279d0
      d(9) = 0.6072153d0
      d(10) = 1.0000000d0
      endif
      endif
      return
C
c     Zr
C
140   if (olanl) then
      e(   1) =          1.97600000d0
      s(   1) =         -0.92067450d0
      e(   2) =          1.15400000d0
      s(   2) =          1.09290330d0
      e(   3) =          0.39100000d0
      s(   3) =          0.67956210d0
      e(   4) =          1.97600000d0
      s(   4) =          0.75060600d0
      e(   5) =          1.15400000d0
      s(   5) =         -0.98108260d0
      e(   6) =          0.39100000d0
      s(   6) =         -1.02251510d0
      e(   7) =          0.10010000d0
      s(   7) =          1.08600380d0
      e(   8) =          0.03340000d0
      s(   8) =          1.00000000d0
      e(   9) =          4.19200000d0
      p(   9) =         -0.09425540d0
      e(  10) =          0.87640000d0
      p(  10) =          0.67836750d0
      e(  11) =          0.32630000d0
      p(  11) =          0.42466180d0
      e(  12) =          0.29720000d0
      p(  12) =         -0.15274010d0
      e(  13) =          0.07240000d0
      p(  13) =          1.07771850d0
      e(  14) =          0.02430000d0
      p(  14) =          1.00000000d0
      e(  15) =          2.26900000d0
      d(  15) =          0.05997410d0
      e(  16) =          0.78550000d0
      d(  16) =          0.47341580d0
      e(  17) =          0.26150000d0
      d(  17) =          0.61171780d0
      e(  18) =          0.08020000d0
      d(  18) =          1.00000000d0
      else
      e(1) =  0.2537d0
      e(2) =  0.1001d0
      e(3) =  0.0334d0
      e(4) =  0.2972d0
      e(5) =  0.0724d0
      e(6) =  0.0243d0
      e(7) =  2.2690d0
      e(8) =  0.7855d0
      e(9) =  0.2615d0
      e(10) =  0.0802d0
      If(omin) then
      s(1) = -0.4513644d0
      s(2) =  0.6134560d0
      s(3) =  0.7182652d0
      p(4) = -0.0727095d0
      p(5) =  0.5130309d0
      p(6) =  0.5997819d0
      d(7) = 0.0595974d0
      d(8) = 0.3825547d0
      d(9) = 0.5140234d0
      d(10) = 0.3085450d0
      else
      s(1) = -1.3826834d0
      s(2) =  1.8792254d0
      s(3) =  1.0000000d0
      p(4) = -0.1527401d0
      p(5) =  1.0777185d0
      p(6) =  1.0000000d0
      d(7) = 0.0717033d0
      d(8) = 0.4602626d0
      d(9) = 0.6184363d0
      d(10) = 1.0000000d0
      endif
      endif
      return
C
c     Nb
C
150   if (olanl) then
      e(   1) =          2.18200000d0
      s(   1) =         -0.88461440d0
      e(   2) =          1.20900000d0
      s(   2) =          1.10337750d0
      e(   3) =          0.41650000d0
      s(   3) =          0.62987760d0
      e(   4) =          2.18200000d0
      s(   4) =          0.77902870d0
      e(   5) =          1.20900000d0
      s(   5) =         -1.07527880d0
      e(   6) =          0.41650000d0
      s(   6) =         -1.15060140d0
      e(   7) =          0.14540000d0
      s(   7) =          0.99691550d0
      e(   8) =          0.03920000d0
      s(   8) =          1.00000000d0
      e(   9) =          4.51900000d0
      p(   9) =         -0.08173030d0
      e(  10) =          0.94060000d0
      p(  10) =          0.69951150d0
      e(  11) =          0.34920000d0
      p(  11) =          0.39809960d0
      e(  12) =          0.41060000d0
      p(  12) =         -0.12121760d0
      e(  13) =          0.07520000d0
      p(  13) =          1.04804770d0
      e(  14) =          0.02470000d0
      p(  14) =          1.00000000d0
      e(  15) =          3.46600000d0
      d(  15) =          0.03159830d0
      e(  16) =          0.99380000d0
      d(  16) =          0.48343060d0
      e(  17) =          0.33500000d0
      d(  17) =          0.61648930d0
      e(  18) =          0.10240000d0
      d(  18) =          1.00000000d0
      else
      e(1) =  0.2568d0
      e(2) =  0.1454d0
      e(3) =  0.0392d0
      e(4) =  0.4106d0
      e(5) =  0.0752d0
      e(6) =  0.0247d0
      e(7) =  3.4660d0
      e(8) =  0.9938d0
      e(9) =  0.3350d0
      e(10) =  0.1024d0
      If(omin) then
      s(1) = -0.6994660d0
      s(2) =  0.7808829d0
      s(3) =  0.7950838d0
      p(4) = -0.0587033d0
      p(5) =  0.5075489d0
      p(6) =  0.5971067d0
      d(7) = 0.0416743d0
      d(8) = 0.3879263d0
      d(9) = 0.5230223d0
      d(10) = 0.3019870d0
      else
      s(1) =  -2.6417492d0
      s(2) =  2.9492453d0
      s(3) =  1.0000000d0
      p(4) = -0.1212176d0
      p(5) =  1.0480477d0
      p(6) =  1.0000000d0
      d(7) = 0.0499371d0
      d(8) = 0.4648411d0
      d(9) = 0.6267228d0
      d(10) = 1.0000000d0
      endif
      endif
      return
C
c     Mo
C
160   if (olanl) then
      e(   1) =          2.36100000d0
      s(   1) =         -0.91217600d0
      e(   2) =          1.30900000d0
      s(   2) =          1.14774530d0
      e(   3) =          0.45000000d0
      s(   3) =          0.60971090d0
      e(   4) =          2.36100000d0
      s(   4) =          0.81392590d0
      e(   5) =          1.30900000d0
      s(   5) =         -1.13600840d0
      e(   6) =          0.45000000d0
      s(   6) =         -1.16115920d0
      e(   7) =          0.16810000d0
      s(   7) =          1.00647860d0
      e(   8) =          0.04230000d0
      s(   8) =          1.00000000d0
      e(   9) =          4.89500000d0
      p(   9) =         -0.09082580d0
      e(  10) =          1.04400000d0
      p(  10) =          0.70428990d0
      e(  11) =          0.38770000d0
      p(  11) =          0.39731790d0
      e(  12) =          0.49950000d0
      p(  12) =         -0.10819450d0
      e(  13) =          0.07800000d0
      p(  13) =          1.03680930d0
      e(  14) =          0.02470000d0
      p(  14) =          1.00000000d0
      e(  15) =          2.99300000d0
      d(  15) =          0.05270630d0
      e(  16) =          1.06300000d0
      d(  16) =          0.50039070d0
      e(  17) =          0.37210000d0
      d(  17) =          0.57940240d0
      e(  18) =          0.11780000d0
      d(  18) =          1.00000000d0
      else
      e(1) =  0.2768d0
      e(2) =  0.1681d0
      e(3) =  0.0423d0
      e(4) =  0.4995d0
      e(5) =  0.0780d0
      e(6) =  0.0247d0
      e(7) =  2.9930d0
      e(8) =  1.0630d0
      e(9) =  0.3721d0
      e(10) =  0.1178d0
      If(omin) then
      s(1) = -0.8035334d0
      s(2) =  0.8836685d0
      s(3) =  0.7963994d0
      p(4) = -0.0509638d0
      p(5) =  0.4883774d0
      p(6) =  0.6157657d0
      d(7) = 0.0576368d0
      d(8) = 0.4128484d0
      d(9) = 0.5071459d0
      d(10) = 0.2652848d0
      else
      s(1) =  -3.0265390d0
      s(2) =  3.3283709d0
      s(3) =  1.0000000d0
      p(4) = -0.1081945d0
      p(5) =  1.0368093d0
      p(6) =  1.0000000d0
      d(7) = 0.0671501d0
      d(8) = 0.4809917d0
      d(9) = 0.5908536d0
      d(10) = 1.0000000d0
      endif
      endif
      return
C
c     Tc
C
170   if (olanl) then
      e(   1) =          2.34200000d0
      s(   1) =         -1.49117820d0
      e(   2) =          1.63400000d0
      s(   2) =          1.67490430d0
      e(   3) =          0.50940000d0
      s(   3) =          0.65730060d0
      e(   4) =          2.34200000d0
      s(   4) =          1.35239970d0
      e(   5) =          1.63400000d0
      s(   5) =         -1.62163010d0
      e(   6) =          0.50940000d0
      s(   6) =         -1.14637700d0
      e(   7) =          0.17060000d0
      s(   7) =          0.98591900d0
      e(   8) =          0.04350000d0
      s(   8) =          1.00000000d0
      e(   9) =          5.27800000d0
      p(   9) =         -0.09954190d0
      e(  10) =          1.15600000d0
      p(  10) =          0.70815440d0
      e(  11) =          0.43020000d0
      p(  11) =          0.39735710d0
      e(  12) =          0.47670000d0
      p(  12) =         -0.09731270d0
      e(  13) =          0.08950000d0
      p(  13) =          1.04048620d0
      e(  14) =          0.02460000d0
      p(  14) =          1.00000000d0
      e(  15) =          4.63200000d0
      d(  15) =          0.02687240d0
      e(  16) =          1.27900000d0
      d(  16) =          0.50730890d0
      e(  17) =          0.44250000d0
      d(  17) =          0.59113810d0
      e(  18) =          0.13640000d0
      d(  18) =          1.00000000d0
      else
      e(1) =  0.3076d0
      e(2) =  0.1706d0
      e(3) =  0.0435d0
      e(4) =  0.4767d0
      e(5) =  0.0895d0
      e(6) =  0.0246d0
      e(7) =  4.6320d0
      e(8) =  1.2790d0
      e(9) =  0.4425d0
      e(10) =  0.1364d0
      If(omin) then
      s(1) = -0.6987010d0
      s(2) =  0.8183812d0
      s(3) =  0.7635744d0
      p(4) = -0.0429919d0
      p(5) =  0.4596779d0
      p(6) =  0.6620962d0
      d(7) = 0.0420641d0
      d(8) = 0.4148349d0
      d(9) = 0.5160747d0
      d(10) = 0.2725891d0
      else
      s(1) = -2.3899333d0
      s(2) =  2.7993039d0
      s(3) =  1.0000000d0
      p(4) = -0.0973127d0
      p(5) =  1.0404862d0
      p(6) =  1.0000000d0
      d(7) = 0.0491989d0
      d(8) = 0.4851984d0
      d(9) = 0.6036102d0
      d(10) = 1.0000000d0
      endif
      endif
      return
C
c     Ru
C
180   if (olanl) then
      e(   1) =          2.56500000d0
      s(   1) =         -1.04310560d0
      e(   2) =          1.50800000d0
      s(   2) =          1.33147860d0
      e(   3) =          0.51290000d0
      s(   3) =          0.56130650d0
      e(   4) =          2.56500000d0
      s(   4) =          0.87701280d0
      e(   5) =          1.50800000d0
      s(   5) =         -1.26346600d0
      e(   6) =          0.51290000d0
      s(   6) =         -0.83849870d0
      e(   7) =          0.13620000d0
      s(   7) =          1.06377730d0
      e(   8) =          0.04170000d0
      s(   8) =          1.00000000d0
      e(   9) =          4.85900000d0
      p(   9) =         -0.09457550d0
      e(  10) =          1.21900000d0
      p(  10) =          0.74347980d0
      e(  11) =          0.44130000d0
      p(  11) =          0.36681440d0
      e(  12) =          0.57250000d0
      p(  12) =         -0.08808640d0
      e(  13) =          0.08300000d0
      p(  13) =          1.02839700d0
      e(  14) =          0.02500000d0
      p(  14) =          1.00000000d0
      e(  15) =          4.19500000d0
      d(  15) =          0.04857290d0
      e(  16) =          1.37700000d0
      d(  16) =          0.51052230d0
      e(  17) =          0.48280000d0
      d(  17) =          0.57300280d0
      e(  18) =          0.15010000d0
      d(  18) =          1.00000000d0
      else
      e(1) =  0.3816d0
      e(2) =  0.1362d0
      e(3) =  0.0417d0
      e(4) =  0.5725d0
      e(5) =  0.0830d0
      e(6) =  0.0250d0
      e(7) =  4.1950d0
      e(8) =  1.3770d0
      e(9) =  0.4828d0
      e(10) =  0.1501d0
      If(omin) then
      s(1) = -0.3951238d0
      s(2) =  0.5706421d0
      s(3) =  0.7166590d0
      p(4) = -0.0385634d0
      p(5) =  0.4502226d0
      p(6) =  0.6544573d0
      d(7) = 0.0506308d0
      d(8) = 0.4305510d0
      d(9) = 0.5054939d0
      d(10) = 0.2540578d0
      else
      s(1) = -1.1960626d0
      s(2) =  1.7273666d0
      s(3) =  1.0000000d0
      p(4) = -0.0880864d0
      p(5) =  1.0283970d0
      p(6) =  1.0000000d0
      d(7) = 0.0583381d0
      d(8) = 0.4960916d0
      d(9) = 0.5824427d0
      d(10) = 1.0000000d0
      endif
      endif
      return
C
c     Rh
C
190   if (olanl) then
      e(   1) =          2.64600000d0
      s(   1) =         -1.35540840d0
      e(   2) =          1.75100000d0
      s(   2) =          1.61122330d0
      e(   3) =          0.57130000d0
      s(   3) =          0.58938140d0
      e(   4) =          2.64600000d0
      s(   4) =          1.14721370d0
      e(   5) =          1.75100000d0
      s(   5) =         -1.49435250d0
      e(   6) =          0.57130000d0
      s(   6) =         -0.85897040d0
      e(   7) =          0.14380000d0
      s(   7) =          1.02972410d0
      e(   8) =          0.04280000d0
      s(   8) =          1.00000000d0
      e(   9) =          5.44000000d0
      p(   9) =         -0.09876990d0
      e(  10) =          1.32900000d0
      p(  10) =          0.74335950d0
      e(  11) =          0.48450000d0
      p(  11) =          0.36684620d0
      e(  12) =          0.65950000d0
      p(  12) =         -0.08380560d0
      e(  13) =          0.08690000d0
      p(  13) =          1.02448410d0
      e(  14) =          0.02570000d0
      p(  14) =          1.00000000d0
      e(  15) =          3.66900000d0
      d(  15) =          0.07600590d0
      e(  16) =          1.42300000d0
      d(  16) =          0.51588520d0
      e(  17) =          0.50910000d0
      d(  17) =          0.54365850d0
      e(  18) =          0.16100000d0
      d(  18) =          1.00000000d0
      else
      e(1) =  0.4111d0
      e(2) =  0.1438d0
      e(3) =  0.0428d0
      e(4) =  0.6595d0
      e(5) =  0.0869d0
      e(6) =  0.0257d0
      e(7) =  3.6690d0
      e(8) =  1.4230d0
      e(9) =  0.5091d0
      e(10) =  0.1610d0
      If(omin) then
      s(1) = -0.3788832d0
      s(2) =  0.5435654d0
      s(3) =  0.7306408d0
      p(4) = -0.0370046d0
      p(5) =  0.4523639d0
      p(6) =  0.6538225d0
      d(7) = 0.0730956d0
      d(8) = 0.4460567d0
      d(9) = 0.4857581d0
      d(10) = 0.2320624d0
      else
      s(1) = -1.1915123d0
      s(2) =  1.7094050d0
      s(3) =  1.0000000d0
      p(4) = -0.0838056d0
      p(5) =  1.0244841d0
      p(6) =  1.0000000d0
      d(7) = 0.0828065d0
      d(8) = 0.5053162d0
      d(9) = 0.5502920d0
      d(10) = 1.0000000d0
      endif
      endif
      return
C
c     Pd
C
200   if (olanl) then
       e( 1) =          2.78700000d0
       s( 1) =         -1.61023930d0
       e( 2) =          1.96500000d0
       s( 2) =          1.84898420d0
       e( 3) =          0.62430000d0
       s( 3) =          0.60374920d0
       e( 4) =          2.78700000d0
       s( 4) =          1.35407750d0
       e( 5) =          1.96500000d0
       s( 5) =         -1.67808480d0
       e( 6) =          0.62430000d0
       s( 6) =         -0.85593810d0
       e( 7) =          0.14960000d0
       s( 7) =          1.02002990d0
       e( 8) =          0.04360000d0
       s( 8) =          1.00000000d0
       e( 9) =          5.99900000d0
       p( 9) =         -0.10349100d0
       e(10) =          1.44300000d0
       p(10) =          0.74569520d0
       e(11) =          0.52640000d0
       p(11) =          0.36564940d0
       e(12) =          0.73680000d0
       p(12) =          0.07632850d0
       e(13) =          0.08990000d0
       p(13) =          0.97400650d0
       e(14) =          0.02620000d0
       p(14) =          1.00000000d0
       e(15) =          6.09100000d0
       d(15) =          0.03761460d0
       e(16) =          1.71900000d0
       d(16) =          0.52004790d0
       e(17) =          0.60560000d0
       d(17) =          0.57060710d0
       e(18) =          0.18830000d0
       d(18) =          1.00000000d0
      else
       e(1) =  0.4416d0
       e(2) =  0.1496d0
       e(3) =  0.0436d0
       e(4) =  0.7368d0
       e(5) =  0.0899d0
       e(6) =  0.0262d0
       e(7) =  6.0910d0
       e(8) =  1.7190d0
       e(9) =  0.6056d0
       e(10) =  0.1883d0
       If(omin) then
       s(1) = -0.3594574d0
       s(2) =  0.5167561d0
       s(3) =  0.7414499d0
       p(4) =  0.0344578d0
       p(5) =  0.4397064d0
       p(6) =  0.6525627d0
       d(7) = 0.0447293d0
       d(8) = 0.4425814d0
       d(9) = 0.5051035d0
       d(10) = 0.2450132d0
       else
       s(1) = -1.1660418d0
       s(2) =  1.6763022d0
       s(3) =  1.0000000d0
       p(4) =  0.0763285d0
       p(5) =  0.9740065d0
       p(6) =  1.0000000d0
       d(7) = 0.0511957d0
       d(8) = 0.5065641d0
       d(9) = 0.5781248d0
       d(10) = 1.0000000d0
       endif
      endif
      return
C
c     Ag
C
210   if (olanl) then
       e( 1) =          2.95000000d0
       s( 1) =         -1.79105640d0
       e( 2) =          2.14900000d0
       s( 2) =          2.02445700d0
       e( 3) =          0.66840000d0
       s( 3) =          0.60728390d0
       e( 4) =          2.95000000d0
       s( 4) =          1.01411250d0
       e( 5) =          2.14900000d0
       s( 5) =         -1.24139710d0
       e( 6) =          0.66840000d0
       s( 6) =         -0.49014270d0
       e( 7) =          0.09970000d0
       s( 7) =          1.11283750d0
       e( 8) =          0.03470000d0
       s( 8) =          1.00000000d0
       e( 9) =          6.55300000d0
       p( 9) =         -0.10791170d0
       e(10) =          1.56500000d0
       p(10) =          0.74036450d0
       e(11) =          0.57480000d0
       p(11) =          0.37210080d0
       e(12) =          0.90850000d0
       p(12) =         -0.04183710d0
       e(13) =          0.08330000d0
       p(13) =          1.00875860d0
       e(14) =          0.02520000d0
       p(14) =          1.00000000d0
       e(15) =          3.39100000d0
       d(15) =          0.13969380d0
       e(16) =          1.59900000d0
       d(16) =          0.47444210d0
       e(17) =          0.62820000d0
       d(17) =          0.51563110d0
       e(18) =          0.21080000d0
       d(18) =          1.00000000d0
      else
       e(1) =  0.5523d0
       e(2) =  0.0997d0
       e(3) =  0.0347d0
       e(4) =  0.9085d0
       e(5) =  0.0833d0
       e(6) =  0.0252d0
       e(7) =  3.3910d0
       e(8) =  1.5990d0
       e(9) =  0.6282d0
       e(10) =  0.2108d0
       If(omin) then
       s(1) = -0.2442193d0
       s(2) =  0.6415812d0
       s(3) =  0.5125480d0
       p(4) = -0.0187318d0
       p(5) =  0.4516535d0
       p(6) =  0.6467139d0
       d(7) = 0.1199877d0
       d(8) = 0.4204947d0
       d(9) = 0.4534121d0
       d(10) = 0.2301487d0
       else
       s(1) = -0.4615778d0
       s(2) =  1.2125973d0
       s(3) =  1.0000000d0
       p(4) = -0.0418371d0
       p(5) =  1.0087586d0
       p(6) =  1.0000000d0
       d(7) = 0.1362719d0
       d(8) = 0.4775624d0
       d(9) = 0.5149472d0
       d(10) = 1.0000000d0
       endif
      endif
      return
C
c     Cd
C
220   continue
      e(1) =  0.5095d0
      e(2) =  0.1924d0
      e(3) =  0.0544d0
      e(4) =  0.8270d0
      e(5) =  0.1287d0
      e(6) =  0.0405d0
      e(7) =  5.1480d0
      e(8) =  1.9660d0
      e(9) =  0.7360d0
      e(10) =  0.2479d0
      If(omin) then
      s(1) = -0.4140627d0
      s(2) =  0.5863291d0
      s(3) =  0.7244515d0
      p(4) = -0.0544015d0
      p(5) =  0.5207503d0
      p(6) =  0.5865668d0
      d(7) = 0.0629604d0
      d(8) = 0.4601487d0
      d(9) = 0.4850734d0
      d(10) = 0.2015723d0
      else
      s(1) = -1.2713002d0
      s(2) =  1.8002112d0
      s(3) =  1.0000000d0
      p(4) = -0.1083020d0
      p(5) =  1.0367049d0
      p(6) =  1.0000000d0
      d(7) = 0.0703071d0
      d(8) = 0.5138427d0
      d(9) = 0.5416758d0
      d(10) = 1.0000000d0
      endif
      return
C
c     In
C
230   continue
      e(1) = 0.4915d0
      e(2) = 0.3404d0
      e(3) = 0.0774d0
      e(4) = 0.9755d0
      e(5) = 0.1550d0
      e(6) = 0.0474d0
      If(omin) then
      s(1) = -1.0815561d0
      s(2) =  1.1418861d0
      s(3) =  0.8134181d0
      p(4) = -0.0610500d0
      p(5) =  0.5185538d0
      p(6) =  0.5945877d0
      else
      s(1) = -4.2418681d0
      s(2) =  4.4784826d0
      s(3) =  1.0000000d0
      p(4) = -0.1226473d0
      p(5) =  1.0417571d0
      p(6) =  1.0000000d0
      endif
      return
C
c     Sn
C
240   continue
      e(1) = 0.5418d0
      e(2) = 0.3784d0
      e(3) = 0.0926d0
      e(4) = 1.0470d0
      e(5) = 0.1932d0
      e(6) = 0.0630d0
      If(omin) then
      s(1) = -1.2116640d0
      s(2) =  1.3011570d0
      s(3) =  0.7758870d0
      p(4) = -0.0763140d0
      p(5) =  0.5681508d0
      p(6) =  0.5445228d0
      else
      s(1) = -4.2089644d0
      s(2) =  4.5198368d0
      s(3) =  1.0000000d0
      p(4) = -0.1417678d0
      p(5) =  1.0554488d0
      p(6) =  1.0000000d0
      endif
      return
C
c     Sb
C
250   continue
      e(1) = 0.5863d0
      e(2) = 0.4293d0
      e(3) = 0.1078d0
      e(4) = 1.1110d0
      e(5) = 0.2365d0
      e(6) = 0.0800d0
      If(omin) then
      s(1) = -1.4596445d0
      s(2) =  1.5689216d0
      s(3) =  0.7529903d0
      p(4) = -0.0994670d0
      p(5) =  0.5924868d0
      p(6) =  0.5267898d0
      else
      s(1) = -1.4596445d0
      s(2) =  1.5689216d0
      s(3) =  1.0000000d0
      p(4) = -0.0994670d0
      p(5) =  0.5924868d0
      p(6) =  1.0000000d0
      endif
      return
C
c     Te
C
260   continue
      e(1) = 0.6938d0
      e(2) = 0.4038d0
      e(3) = 0.1165d0
      e(4) = 1.2310d0
      e(5) = 0.2756d0
      e(6) = 0.0911d0
      If(omin) then
      s(1) = -0.9544519d0
      s(2) =  1.1549188d0
      s(3) =  0.6537419d0
      p(4) = -0.1079069d0
      p(5) =  0.6102076d0
      p(6) =  0.5171696d0
      else
      s(1) = -2.4115013d0
      s(2) =  2.9179976d0
      s(3) =  1.0000000d0
      p(4) = -0.1923340d0
      p(5) =  1.0876382d0
      p(6) =  1.0000000d0
      endif
      return
C
c     I
C
270   continue
      e(1) = 0.7242d0
      e(2) = 0.4653d0
      e(3) = 0.1336d0
      e(4) = 1.2900d0
      e(5) = 0.3180d0
      e(6) = 0.1053d0
      If(omin) then
      s(1) = -1.1737608d0
      s(2) =  1.3749707d0
      s(3) =  0.6531029d0
      p(4) = -0.1189321d0
      p(5) =  0.6272564d0
      p(6) =  0.5082193d0
      else
      s(1) = -2.9731048d0
      s(2) =  3.4827643d0
      s(3) =  1.0000000d0
      p(4) = -0.2092377d0
      p(5) =  1.1035347d0
      p(6) =  1.0000000d0
      endif
      return
C
c     Xe
C
280   continue
      e(1) = 0.7646d0
      e(2) = 0.5322d0
      e(3) = 0.1491d0
      e(4) = 1.2110d0
      e(5) = 0.3808d0
      e(6) = 0.1259d0
      If(omin) then
      s(1) = -1.5143658d0
      s(2) =  1.7270277d0
      s(3) =  0.6338089d0
      p(4) = -0.1405220d0
      p(5) =  0.6212978d0
      p(6) =  0.5366258d0
      else
c PS missing s(1) calculated from s(1):s(2) ratio of ecpmin
      s(1) = -3.6543173d0
      s(2) =  4.1674919d0
      s(3) =  1.0000000d0
      p(4) = -0.2616924d0
      p(5) =  1.1570355d0
      p(6) =  1.0000000d0
      endif
      return
      end
      subroutine ec5bas(e,s,p,d,n,omin,olanl)
c
c     ----- Hay ECP and LANL2DZ basis sets
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-54
      go to (100,120,130,
     *       9999,9999,9999,9999,9999,9999,9999,
     *       9999,9999,9999,9999,9999,9999,9999,
     *       140,150,160,170,180,190,
     *       200,210,220,230,240,250), nn
C
c     Cs
C
100   if(olanl) then
       e( 1) =          0.87090000d0
       s( 1) =         -1.16047980d0
       e( 2) =          0.53930000d0
       s( 2) =          1.41985150d0
       e( 3) =          0.17240000d0
       s( 3) =          0.58729050d0
       e( 4) =          0.87090000d0
       s( 4) =          0.82377270d0
       e( 5) =          0.53930000d0
       s( 5) =         -1.07091810d0
       e( 6) =          0.17240000d0
       s( 6) =         -0.90851220d0
       e( 7) =          0.03930000d0
       s( 7) =          1.07740490d0
       e( 8) =          0.01510000d0
       s( 8) =          1.00000000d0
       e( 9) =          1.46800000d0
       p( 9) =         -0.13210330d0
       e(10) =          0.41340000d0
       p(10) =          0.65724100d0
       e(11) =          0.15360000d0
       p(11) =          0.47564560d0
       e(12) =          0.14580000d0
       p(12) =         -0.16805560d0
       e(13) =          0.02790000d0
       p(13) =          1.06657460d0
       e(14) =          0.01130000d0
       p(14) =          1.00000000d0
      else
       e(1) = 0.1206d0
       e(2) = 0.0393d0
       e(3) = 0.0151d0
       e(4) = 0.1458d0
       e(5) = 0.0279d0
       e(6) = 0.0113d0
       If(omin) then
        s(1) = -0.4033569d0
        s(2) =  0.5743688d0
        s(3) =  0.6938567d0
        p(4) = -0.0868370d0
        p(5) =  0.5511162d0
        p(6) =  0.5376642d0
       else
        s(1) = -1.1536494d0
        s(2) =  1.6427642d0
        s(3) =  1.0000000d0
        p(4) = -0.1680556d0
        p(5) =  1.0665746d0
        p(6) =  1.0000000d0
       endif
      endif
      return
C
c     Ba
C
120   if(olanl) then
        e( 1) =          0.86990000d0
        s( 1) =         -2.25497470d0
        e( 2) =          0.66760000d0
        s( 2) =          2.51457860d0
        e( 3) =          0.19820000d0
        s( 3) =          0.57751840d0
        e( 4) =          0.86990000d0
        s( 4) =          2.03913830d0
        e( 5) =          0.66760000d0
        s( 5) =         -2.37177120d0
        e( 6) =          0.19820000d0
        s( 6) =         -1.27580060d0
        e( 7) =          0.08230000d0
        s( 7) =          1.17033460d0
        e( 8) =          0.02310000d0
        s( 8) =          1.00000000d0
        e( 9) =          1.60500000d0
        p( 9) =         -0.16264030d0
        e(10) =          0.47900000d0
        p(10) =          0.69712890d0
        e(11) =          0.18180000d0
        p(11) =          0.45051070d0
        e(12) =          0.18040000d0
        p(12) =         -0.26425370d0
        e(13) =          0.04760000d0
        p(13) =          1.13472120d0
        e(14) =          0.01920000d0
        p(14) =          1.00000000d0
      else
       e(1) = 0.1297d0
       e(2) = 0.0823d0
       e(3) = 0.0231d0
       e(4) = 0.1804d0
       e(5) = 0.0476d0
       e(6) = 0.0192d0
       If(omin) then
        s(1) = -0.9330926d0
        s(2) =  1.0001676d0
        s(3) =  0.7928327d0
        p(4) = -0.1406549d0
        p(5) =  0.6039805d0
        p(6) =  0.5175636d0
       else
        s(1) = -3.4063657d0
        s(2) =  3.6512309d0
        s(3) =  1.0000000d0
        p(4) = -0.2642537d0
        p(5) =  1.1347212d0
        p(6) =  1.0000000d0
       endif
      endif
      return
C
c     La
C
130   if(olanl) then
        e( 1) =          0.91670000d0
        s( 1) =         -3.02407510d0
        e( 2) =          0.74270000d0
        s( 2) =          3.29714760d0
        e( 3) =          0.22370000d0
        s( 3) =          0.55135420d0
        e( 4) =          0.91670000d0
        s( 4) =          2.69102430d0
        e( 5) =          0.74270000d0
        s( 5) =         -3.04743630d0
        e( 6) =          0.22370000d0
        s( 6) =         -1.10302110d0
        e( 7) =          0.07920000d0
        s( 7) =          1.19418630d0
        e( 8) =          0.02390000d0
        s( 8) =          1.00000000d0
        e( 9) =          1.55400000d0
        p( 9) =         -0.18171680d0
        e(10) =          0.56220000d0
        p(10) =          0.66322260d0
        e(11) =          0.22390000d0
        p(11) =          0.50297820d0
        e(12) =          0.21250000d0
        p(12) =         -0.19688100d0
        e(13) =          0.04830000d0
        p(13) =          1.09075420d0
        e(14) =          0.01790000d0
        p(14) =          1.00000000d0
        e(15) =          0.45240000d0
        d(15) =          0.44680510d0
        e(16) =          0.16020000d0
        d(16) =          0.65434930d0
        e(17) =          0.05310000d0
        d(17) =          1.00000000d0
      else
       e(1) =  0.1413d0
       e(2) =  0.0792d0
       e(3) =  0.0239d0
       e(4) =  0.2125d0
       e(5) =  0.0483d0
       e(6) =  0.0179d0
       e(7) =  0.4524d0
       e(8) =  0.1602d0
       e(9) =  0.0531d0
       If(omin) then
        s(1) = -0.8171303d0
        s(2) =  0.9661994d0
        s(3) =  0.7098560d0
        p(4) = -0.1082407d0
        p(5) =  0.5996720d0
        p(6) =  0.5131390d0
        d(7) =  0.3682427d0
        d(8) =  0.5335878d0
        d(9) =  0.3051338d0
       else
        s(1) = -2.3877035d0
        s(2) =  2.8232923d0
        s(3) =  1.0000d0
        p(4) = -0.1968810d0
        p(5) =  1.0907542d0
        p(6) =  1.0000d0
        d(7) =  0.4497269d0
        d(8) =  0.6516593d0
        d(9) =  1.0000d0
       endif
      endif
      return
C
c     Ce - Lu
C
9999  Call caserr2('ECP basis set unavailable')
      return
C
c     Hf
C
140   if(olanl) then
       e( 1) =          1.95000000d0
       s( 1) =         -1.22608500d0
       e( 2) =          1.18300000d0
       s( 2) =          1.56950740d0
       e( 3) =          0.38970000d0
       s( 3) =          0.49334120d0
       e( 4) =          1.95000000d0
       s( 4) =          1.07783820d0
       e( 5) =          1.18300000d0
       s( 5) =         -1.50108620d0
       e( 6) =          0.38970000d0
       s( 6) =         -1.19821750d0
       e( 7) =          0.16560000d0
       s( 7) =          1.22902960d0
       e( 8) =          0.04240000d0
       s( 8) =          1.00000000d0
       e( 9) =          1.97200000d0
       p( 9) =         -0.63234670d0
       e(10) =          1.35400000d0
       p(10) =          1.04651620d0
       e(11) =          0.41340000d0
       p(11) =          0.58016700d0
       e(12) =          0.34270000d0
       p(12) =         -0.17391780d0
       e(13) =          0.08040000d0
       p(13) =          1.08416440d0
       e(14) =          0.02740000d0
       p(14) =          1.00000000d0
       e(15) =          0.82260000d0
       d(15) =          0.44904050d0
       e(16) =          0.25850000d0
       d(16) =          0.67238910d0
       e(17) =          0.07620000d0
       d(17) =          1.00000000d0
      else
       e(1) = 0.2457d0
       e(2) = 0.1656d0
       e(3) = 0.0424d0
       e(4) = 0.3427d0
       e(5) = 0.0804d0
       e(6) = 0.0274d0
       e(7) = 0.8226d0
       e(8) = 0.2585d0
       e(9) = 0.0762d0
       If(omin) then
        s(1) = -1.0978540d0
        s(2) =  1.1873377d0
        s(3) =  0.7754017d0
        p(4) = -0.0839349d0
        p(5) =  0.5232311d0
        p(6) =  0.5909315d0
        d(7) =  0.3619963d0
        d(8) =  0.5364635d0
        d(9) =  0.3502947d0
       else
        s(1) = -3.8217151d0
        s(2) =  4.1332149d0
        s(3) =  1.0000000d0
        p(4) = -0.1739178d0
        p(5) =  1.0841644d0
        p(6) =  1.0000000d0
        d(7) =  0.4519513d0
        d(8) =  0.6697730d0
        d(9) =  1.0000000d0
       endif
      endif
      return
C
c     Ta
C
150   if(olanl) then
        e( 1) =          2.04400000d0
        s( 1) =         -1.31047790d0
        e( 2) =          1.26700000d0
        s( 2) =          1.65799250d0
        e( 3) =          0.41570000d0
        s( 3) =          0.48483370d0
        e( 4) =          2.04400000d0
        s( 4) =          1.18973150d0
        e( 5) =          1.26700000d0
        s( 5) =         -1.66504620d0
        e( 6) =          0.41570000d0
        s( 6) =         -1.05633350d0
        e( 7) =          0.16710000d0
        s( 7) =          1.18406520d0
        e( 8) =          0.04820000d0
        s( 8) =          1.00000000d0
        e( 9) =          2.56500000d0
        p( 9) =         -0.29172380d0
        e(10) =          1.22900000d0
        p(10) =          0.75706490d0
        e(11) =          0.42440000d0
        p(11) =          0.52400810d0
        e(12) =          0.43600000d0
        p(12) =         -0.15130140d0
        e(13) =          0.08400000d0
        p(13) =          1.06131230d0
        e(14) =          0.02800000d0
        p(14) =          1.00000000d0
        e(15) =          0.89480000d0
        d(15) =          0.47310720d0
        e(16) =          0.29890000d0
        d(16) =          0.63992000d0
        e(17) =          0.09350000d0
        d(17) =          1.00000000d0
      else
       e(1) = 0.3084d0
       e(2) = 0.1671d0
       e(3) = 0.0482d0
       e(4) = 0.4360d0
       e(5) = 0.0840d0
       e(6) = 0.0280d0
       e(7) = 0.8948d0
       e(8) = 0.2989d0
       e(9) = 0.0935d0
       If(omin) then
        s(1) = -0.6940372d0
        s(2) =  0.7824080d0
        s(3) =  0.7770293d0
        p(4) = -0.0737334d0
        p(5) =  0.5172072d0
        p(6) =  0.5910988d0
        d(7) =  0.3884774d0
        d(8) =  0.5224911d0
        d(9) =  0.3190890d0
       else
        s(1) = -2.4452356d0
        s(2) =  2.7565841d0
        s(3) =  1.0000000d0
        p(4) = -0.1513014d0
        p(5) =  1.0613123d0
        p(6) =  1.0000000d0
        d(7) =  0.4746917d0
        d(8) =  0.6384469d0
        d(9) =  1.0000000d0
       endif
      endif
      return
C
c     W
C
160   if(olanl) then
       e( 1) =          2.13700000d0
       s( 1) =         -1.39161510d0
       e( 2) =          1.34700000d0
       s( 2) =          1.75102610d0
       e( 3) =          0.43660000d0
       s( 3) =          0.46946470d0
       e( 4) =          2.13700000d0
       s( 4) =          1.29850880d0
       e( 5) =          1.34700000d0
       s( 5) =         -1.81024290d0
       e( 6) =          0.43660000d0
       s( 6) =         -1.08445310d0
       e( 7) =          0.18830000d0
       s( 7) =          1.25806180d0
       e( 8) =          0.05180000d0
       s( 8) =          1.00000000d0
       e( 9) =          3.00500000d0
       p( 9) =         -0.24055630d0
       e(10) =          1.22800000d0
       p(10) =          0.73640920d0
       e(11) =          0.44150000d0
       p(11) =          0.48814870d0
       e(12) =          0.40100000d0
       p(12) =         -0.14974990d0
       e(13) =          0.09000000d0
       p(13) =          1.07074630d0
       e(14) =          0.02800000d0
       p(14) =          1.00000000d0
       e(15) =          0.95190000d0
       d(15) =          0.49852650d0
       e(16) =          0.32700000d0
       d(16) =          0.61111100d0
       e(17) =          0.10540000d0
       d(17) =          1.00000000d0
      else
       e(1) = 0.3313d0
       e(2) = 0.1883d0
       e(3) = 0.0518d0
       e(4) = 0.4010d0
       e(5) = 0.0900d0
       e(6) = 0.0280d0
       e(7) = 0.9519d0
       e(8) = 0.3270d0
       e(9) = 0.1054d0
       If(omin) then
        s(1) = -0.7652966d0
        s(2) =  0.8588369d0
        s(3) =  0.7713327d0
        p(4) = -0.0679181d0
        p(5) =  0.4856300d0
        p(6) =  0.6318430d0
        d(7) =  0.4225700d0
        d(8) =  0.5153273d0
        d(9) =  0.2788919d0
       else
        s(1) = -2.6381161d0
        s(2) =  2.9605665d0
        s(3) =  1.0000000d0
        p(4) = -0.1497499d0
        p(5) =  1.0707463d0
        p(6) =  1.0000000d0
        d(7) =  0.4999776d0
        d(8) =  0.6097264d0
        d(9) =  1.0000000d0
       endif
      endif
      return
C
c     Re
C
170   if(olanl) then
       e( 1) =          2.18500000d0
       s( 1) =         -1.62237300d0
       e( 2) =          1.45100000d0
       s( 2) =          1.99386470d0
       e( 3) =          0.45850000d0
       s( 3) =          0.45311660d0
       e( 4) =          2.18500000d0
       s( 4) =          1.54597520d0
       e( 5) =          1.45100000d0
       s( 5) =         -2.07589270d0
       e( 6) =          0.45850000d0
       s( 6) =         -1.19223960d0
       e( 7) =          0.23140000d0
       s( 7) =          1.22728640d0
       e( 8) =          0.05660000d0
       s( 8) =          1.00000000d0
       e( 9) =          3.35800000d0
       p( 9) =         -0.23186670d0
       e(10) =          1.27100000d0
       p(10) =          0.74586830d0
       e(11) =          0.46440000d0
       p(11) =          0.46326860d0
       e(12) =          0.49600000d0
       p(12) =         -0.13113700d0
       e(13) =          0.08900000d0
       p(13) =          1.05036710d0
       e(14) =          0.02800000d0
       p(14) =          1.00000000d0
       e(15) =          1.11600000d0
       d(15) =          0.46898880d0
       e(16) =          0.42670000d0
       d(16) =          0.62095910d0
       e(17) =          0.13780000d0
       d(17) =          1.00000000d0
      else
       e(1) = 0.3314d0
       e(2) = 0.2314d0
       e(3) = 0.0566d0
       e(4) = 0.4960d0
       e(5) = 0.0890d0
       e(6) = 0.0280d0
       e(7) = 1.1160d0
       e(8) = 0.4267d0
       e(9) = 0.1378d0
       If(omin) then
        s(1) = -1.1074561d0
        s(2) =  1.1522357d0
        s(3) =  0.8217259d0
        p(4) = -0.0539986d0
        p(5) =  0.4325121d0
        p(6) =  0.6707919d0
        d(7) =  0.3725292d0
        d(8) =  0.5014277d0
        d(9) =  0.3341287d0
       else
        s(1) = -4.4235772d0
        s(2) =  4.6024430d0
        s(3) =  1.0000000d0
        p(4) = -0.1311370d0
        p(5) =  1.0503671d0
        p(6) =  1.0000000d0
        d(7) =  0.4644937d0
        d(8) =  0.6252127d0
        d(9) =  1.0000000d0
       endif
      endif
      return
C
c     Os
C
180   if(olanl) then
       e( 1) =          2.22200000d0
       s( 1) =         -1.65380360d0
       e( 2) =          1.49600000d0
       s( 2) =          2.06702970d0
       e( 3) =          0.47740000d0
       s( 3) =          0.42320170d0
       e( 4) =          2.22200000d0
       s( 4) =          1.60469680d0
       e( 5) =          1.49600000d0
       s( 5) =         -2.21203860d0
       e( 6) =          0.47740000d0
       s( 6) =         -1.13012090d0
       e( 7) =          0.24370000d0
       s( 7) =          1.26545530d0
       e( 8) =          0.05830000d0
       s( 8) =          1.00000000d0
       e( 9) =          2.51800000d0
       p( 9) =         -0.41773450d0
       e(10) =          1.46000000d0
       p(10) =          0.94349470d0
       e(11) =          0.49230000d0
       p(11) =          0.46729760d0
       e(12) =          0.51000000d0
       p(12) =         -0.14902790d0
       e(13) =          0.09800000d0
       p(13) =          1.06036160d0
       e(14) =          0.02900000d0
       p(14) =          1.00000000d0
       e(15) =          1.18300000d0
       d(15) =          0.48384700d0
       e(16) =          0.44920000d0
       d(16) =          0.60795730d0
       e(17) =          0.14630000d0
       d(17) =          1.00000000d0
      else
       e(1) = 0.3553d0
       e(2) = 0.2437d0
       e(3) = 0.0583d0
       e(4) = 0.5100d0
       e(5) = 0.0980d0
       e(6) = 0.0290d0
       e(7) = 1.1830d0
       e(8) = 0.4492d0
       e(9) = 0.1463d0
       If(omin) then
        s(1) = -1.0298132d0
        s(2) =  1.0766338d0
        s(3) =  0.8249345d0
        p(4) = -0.0600261d0
        p(5) =  0.4270969d0
        p(6) =  0.6860066d0
        d(7) =  0.4003032d0
        d(8) =  0.5004758d0
        d(9) =  0.3036704d0
       else
        s(1) = -4.1980722d0
        s(2) =  4.3889382d0
        s(3) =  1.0000000d0
        p(4) = -0.1490279d0
        p(5) =  1.0603616d0
        p(6) =  1.0000000d0
        d(7) =  0.4852204d0
        d(8) =  0.6066428d0
        d(9) =  1.0000000d0
       endif
      endif
      return
C
c     Ir
C
190   if(olanl) then
       e( 1) =          2.35000000d0
       s( 1) =         -1.67846420d0
       e( 2) =          1.58200000d0
       s( 2) =          2.09525530d0
       e( 3) =          0.50180000d0
       s( 3) =          0.41629340d0
       e( 4) =          2.35000000d0
       s( 4) =          1.64644670d0
       e( 5) =          1.58200000d0
       s( 5) =         -2.27481500d0
       e( 6) =          0.50180000d0
       s( 6) =         -1.04943570d0
       e( 7) =          0.25000000d0
       s( 7) =          1.21677910d0
       e( 8) =          0.05980000d0
       s( 8) =          1.00000000d0
       e( 9) =          2.79200000d0
       p( 9) =         -0.38892120d0
       e(10) =          1.54100000d0
       p(10) =          0.90775160d0
       e(11) =          0.52850000d0
       p(11) =          0.46914430d0
       e(12) =          0.51000000d0
       p(12) =         -0.11706690d0
       e(13) =          0.09800000d0
       p(13) =          1.04890020d0
       e(14) =          0.02900000d0
       p(14) =          1.00000000d0
       e(15) =          1.24000000d0
       d(15) =          0.50870220d0
       e(16) =          0.46470000d0
       d(16) =          0.58621020d0
       e(17) =          0.15290000d0
       d(17) =          1.00000000d0
      else
       e(1) = 0.3857d0
       e(2) = 0.2500d0
       e(3) = 0.0598d0
       e(4) = 0.5100d0
       e(5) = 0.0980d0
       e(6) = 0.0290d0
       e(7) = 1.2400d0
       e(8) = 0.4647d0
       e(9) = 0.1529d0
       If(omin) then
        s(1) = -0.8851354d0
        s(2) =  0.9276371d0
        s(3) =  0.8300342d0
        p(4) = -0.0488611d0
        p(5) =  0.4377874d0
        p(6) =  0.6736952d0
        d(7) =  0.4309934d0
        d(8) =  0.4977205d0
        d(9) =  0.2715636d0
       else
        s(1) = -3.6672892d0
        s(2) =  3.8433821d0
        s(3) =  1.0000000d0
        p(4) = -0.1170669d0
        p(5) =  1.0489002d0
        p(6) =  1.0000000d0
        d(7) =  0.5081144d0
        d(8) =  0.5867815d0
        d(9) =  1.0000000d0
       endif
      endif
      return
C
c     Pt
C
200   if(olanl) then
       e( 1) =          2.54700000d0
       s( 1) =         -1.47391750d0
       e( 2) =          1.61400000d0
       s( 2) =          1.91157190d0
       e( 3) =          0.51670000d0
       s( 3) =          0.39223190d0
       e( 4) =          2.54700000d0
       s( 4) =          1.43881660d0
       e( 5) =          1.61400000d0
       s( 5) =         -2.09118210d0
       e( 6) =          0.51670000d0
       s( 6) =         -1.09213150d0
       e( 7) =          0.26510000d0
       s( 7) =          1.34265960d0
       e( 8) =          0.05800000d0
       s( 8) =          1.00000000d0
       e( 9) =          2.91100000d0
       p( 9) =         -0.52474380d0
       e(10) =          1.83600000d0
       p(10) =          0.96718840d0
       e(11) =          0.59820000d0
       p(11) =          0.54386320d0
       e(12) =          0.60480000d0
       p(12) =         -0.10614380d0
       e(13) =          0.09960000d0
       p(13) =          1.03831020d0
       e(14) =          0.02900000d0
       p(14) =          1.00000000d0
       e(15) =          1.24300000d0
       d(15) =          0.55981500d0
       e(16) =          0.42710000d0
       d(16) =          0.55110900d0
       e(17) =          0.13700000d0
       d(17) =          1.00000000d0
      else
       e(1) = 0.3755d0
       e(2) = 0.2651d0
       e(3) = 0.0580d0
       e(4) = 0.6048d0
       e(5) = 0.0996d0
       e(6) = 0.0290d0
       e(7) = 1.2430d0
       e(8) = 0.4271d0
       e(9) = 0.1370d0
       If(omin) then
          s(1) = -1.1780900d0
          s(2) =  1.2683001d0
          s(3) =  0.7895579d0
          p(4) = -0.0447327d0
          p(5) =  0.4375802d0
          p(6) =  0.6730424d0
          d(7) =  0.5038163d0
          d(8) =  0.4979002d0
          d(9) =  0.1976129d0
       else
          s(1) = -4.3030775d0
          s(2) =  4.6325779d0
          s(3) =  1.0000000d0
          p(4) = -0.1061438d0
          p(5) =  1.0383102d0
          p(6) =  1.0000000d0
          d(7) =  0.5587443d0
          d(8) =  0.5521832d0
          d(9) =  1.0000000d0
       endif
      endif
      return
C
c     Au
C
210   if(olanl) then
       e( 1) =          2.80900000d0
       s( 1) =         -1.20215560d0
       e( 2) =          1.59500000d0
       s( 2) =          1.67415780d0
       e( 3) =          0.53270000d0
       s( 3) =          0.35265930d0
       e( 4) =          2.80900000d0
       s( 4) =          1.16084810d0
       e( 5) =          1.59500000d0
       s( 5) =         -1.86428460d0
       e( 6) =          0.53270000d0
       s( 6) =         -1.03562300d0
       e( 7) =          0.28260000d0
       s( 7) =          1.30643990d0
       e( 8) =          0.05980000d0
       s( 8) =          1.00000000d0
       e( 9) =          3.68400000d0
       p( 9) =         -0.28026810d0
       e(10) =          1.66600000d0
       p(10) =          0.78183980d0
       e(11) =          0.59890000d0
       p(11) =          0.48047760d0
       e(12) =          0.68380000d0
       p(12) =         -0.09520780d0
       e(13) =          0.09770000d0
       p(13) =          1.02991470d0
       e(14) =          0.02790000d0
       p(14) =          1.00000000d0
       e(15) =          1.28700000d0
       d(15) =          0.58442730d0
       e(16) =          0.43350000d0
       d(16) =          0.52981610d0
       e(17) =          0.13960000d0
       d(17) =          1.00000000d0
      else
       e(1) = 0.3992d0
       e(2) = 0.2826d0
       e(3) = 0.0598d0
       e(4) = 0.6838d0
       e(5) = 0.0977d0
       e(6) = 0.0279d0
       e(7) = 1.2870d0
       e(8) = 0.4335d0
       e(9) = 0.1396d0
       If(omin) then
          s(1) = -1.1140055d0
          s(2) =  1.1838178d0
          s(3) =  0.8145308d0
          p(4) = -0.0391462d0
          p(5) =  0.4234659d0
          p(6) =  0.6856038d0
          d(7) =  0.5380450d0
          d(8) =  0.4869991d0
          d(9) =  0.1682663d0
       else
          s(1) = -4.4402904d0
          s(2) =  4.7185538d0
          s(3) =  1.0000000d0
          p(4) = -0.0952078d0
          p(5) =  1.0299147d0
          p(6) =  1.0000000d0
          d(7) =  0.5848601d0
          d(8) =  0.5293727d0
          d(9) =  1.0000000d0
       endif
      endif
      return
C
c     Hg
C
220   if(olanl) then
       call caserr2('HW basis for Hg not available')
      else
       e(1) = 0.5275d0
       e(2) = 0.2334d0
       e(3) = 0.06861d0
       e(4) = 0.6503d0
       e(5) = 0.1368d0
       e(6) = 0.04256d0
       e(7) = 1.4840d0
       e(8) = 0.5605d0
       e(9) = 0.1923d0
       If(omin) then
          s(1) = -0.4911676d0
          s(2) =  0.6044070d0
          s(3) =  0.7690260d0
          p(4) = -0.0672271d0
          p(5) =  0.4979023d0
          p(6) =  0.6187761d0
          d(7) =  0.4976772d0
          d(8) =  0.5010071d0
          d(9) =  0.1943363d0
       else
          s(1) = -1.7292589d0
          s(2) =  2.1279420d0
          s(3) =  1.0000000d0
          p(4) = -0.1436715d0
          p(5) =  1.0640703d0
          p(6) =  1.0000000d0
          d(7) =  0.5630223d0
          d(8) =  0.5667893d0
          d(9) =  1.0000000d0
       endif
      endif
      return
C
c     Tl 3 electron (sp) basis
C
c230  continue
c     e(1) = 0.5169
c     e(2) = 0.3025
c     e(3) = 0.0812
c     e(4) = 0.7912
c     e(5) = 0.1494
c     e(6) = 0.0451
c     If(omin) then
c     s(1) = -0.8960439
c     s(2) =  1.0673799
c     s(3) =  0.6946559
c     p(4) = -0.0709860
c     p(5) =  0.5326750
c     p(6) =  0.5887880
c     else
c     s(1) = -2.5002165
c     s(2) =  2.9782925
c     s(3) =  1.0000000
c     p(4) = -0.1407872
c     p(5) =  1.0564590
c     p(6) =  1.0000000
c       endIf
c     return
C
c     Tl 13 electron (spd) basis
C
230   continue
      e(1) = 0.5355d0
      e(2) = 0.3082d0
      e(3) = 0.08183d0
      e(4) = 0.7977d0
      e(5) = 0.1498d0
      e(6) = 0.04435d0
      e(7) = 8.655d0
      e(8) = 1.415d0
      e(9) = 0.4442d0
      If(omin) then
         s(1) = -0.8008350d0
         s(2) =  0.9220130d0
         s(3) =  0.7480820d0
         p(4) = -0.0690671d0
         p(5) =  0.5109710d0
         p(6) =  0.6114320d0
         d(7) =  0.0156029d0
         d(8) =  0.6226510d0
         d(9) =  0.4994810d0
      else
         s(1) = -0.8008350d0
         s(2) =  0.9220130d0
         s(3) =  1.0000000d0
         p(4) = -0.0690671d0
         p(5) =  0.5109710d0
         p(6) =  1.0000000d0
         d(7) =  0.0156029d0
         d(8) =  0.6226510d0
         d(9) =  1.0000000d0
      endif
      return
C
c     Pb
C
240   continue
      e(1) = 0.5135d0
      e(2) = 0.3756d0
      e(3) = 0.0944d0
      e(4) = 0.8748d0
      e(5) = 0.1843d0
      e(6) = 0.0598d0
      If(omin) then
         s(1) = -1.6466069d0
         s(2) =  1.8286900d0
         s(3) =  0.6759934d0
         p(4) = -0.0951399d0
         p(5) =  0.5717806d0
         p(6) =  0.5510027d0
      else
         s(1) = -4.3675036d0
         s(2) =  4.8504656d0
         s(3) =  1.0000000d0
         p(4) = -0.1793128d0
         p(5) =  1.0776505d0
         p(6) =  1.0000000d0
      endif
      return
C
c     Bi
C
250   continue
      e(1) = 0.5744d0
      e(2) = 0.3851d0
      e(3) = 0.1050d0
      e(4) = 0.9105d0
      e(5) = 0.2194d0
      e(6) = 0.0745d0
      If(omin) then
         s(1) = -1.3604224d0
         s(2) =  1.5862744d0
         s(3) =  0.6266092d0
         p(4) = -0.1188660d0
         p(5) =  0.6064640d0
         p(6) =  0.5241060d0
      else
         s(1) = -3.2278875d0
         s(2) =  3.7637689d0
         s(3) =  1.0000000d0
         p(4) = -0.2164189d0
         p(5) =  1.1041867d0
         p(6) =  1.0000000d0
      endif
c
      return
      end
      subroutine ec6bas(e,s,p,d,f,n)
c
c     ----- Hay ECP and LANL2DZ basis sets
c           for U, Np and Pu
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-86
      go to (100,100,100,
     +   100,100,200,220,240,100,100,100,100,100,100,100,100,100),
     +   nn
c
  100 call caserr2('No LANL2DZ ecp basis available')
c
      return
c
c u   
c
  200 continue
c
      e(   1) =          2.44400000d0
      s(   1) =          0.28027800d0
      e(   2) =          1.43300000d0
      s(   2) =         -1.32311000d0
      e(   3) =          0.66770000d0
      s(   3) =          1.39499900d0
      e(   4) =          0.25560000d0
      s(   4) =          0.45312300d0
      e(   5) =          2.44400000d0
      s(   5) =         -0.08375400d0
      e(   6) =          1.43300000d0
      s(   6) =          0.60823600d0
      e(   7) =          0.66770000d0
      s(   7) =         -0.81843300d0
      e(   8) =          0.25560000d0
      s(   8) =         -0.90575300d0
      e(   9) =          0.12000000d0
      s(   9) =          1.23402000d0
      e(  10) =          0.04000000d0
      s(  10) =          1.00000000d0
      e(  11) =          1.13800000d0
      p(  11) =         -0.55815000d0
      e(  12) =          0.68740000d0
      p(  12) =          0.97017200d0
      e(  13) =          0.25060000d0
      p(  13) =          0.54190300d0
      e(  14) =          1.13800000d0
      p(  14) =          0.22576300d0
      e(  15) =          0.68740000d0
      p(  15) =         -0.42046900d0
      e(  16) =          0.25060000d0
      p(  16) =         -0.54590300d0
      e(  17) =          0.12000000d0
      p(  17) =          0.74293600d0
      e(  18) =          0.04000000d0
      p(  18) =          1.00000000d0
      e(  19) =          0.38260000d0
      d(  19) =          1.00000000d0
      e(  20) =          0.14730000d0
      d(  20) =          1.00000000d0
      e(  21) =          4.11300000d0
      f(  21) =          0.21899300d0
      e(  22) =          1.69700000d0
      f(  22) =          0.45953900d0
      e(  23) =          0.67740000d0
      f(  23) =          0.42169900d0
      e(  24) =          0.25100000d0
      f(  24) =          0.17906600d0
c
      return
c
c np   
c
  220 continue
c
      e(   1) =          2.37800000d0
      s(   1) =          0.57195000d0
      e(   2) =          1.57500000d0
      s(   2) =         -1.95715500d0
      e(   3) =          0.89500000d0
      s(   3) =          1.47318000d0
      e(   4) =          0.31800000d0
      s(   4) =          0.71261700d0
      e(   5) =          2.37800000d0
      s(   5) =         -0.22043200d0
      e(   6) =          1.57500000d0
      s(   6) =          0.93249500d0
      e(   7) =          0.89500000d0
      s(   7) =         -0.82463000d0
      e(   8) =          0.31800000d0
      s(   8) =         -0.90226500d0
      e(   9) =          0.11300000d0
      s(   9) =          1.10305700d0
      e(  10) =          0.04000000d0
      s(  10) =          1.00000000d0
      e(  11) =          1.30500000d0
      p(  11) =         -0.46802300d0
      e(  12) =          0.72100000d0
      p(  12) =          0.84737200d0
      e(  13) =          0.26900000d0
      p(  13) =          0.56283100d0
      e(  14) =          1.30500000d0
      p(  14) =          0.19954600d0
      e(  15) =          0.72100000d0
      p(  15) =         -0.39493000d0
      e(  16) =          0.26900000d0
      p(  16) =         -0.43603100d0
      e(  17) =          0.10000000d0
      p(  17) =          0.78625300d0
      e(  18) =          0.03740000d0
      p(  18) =          1.00000000d0
      e(  19) =          0.39600000d0
      d(  19) =          1.00000000d0
      e(  20) =          0.15000000d0
      d(  20) =          1.00000000d0
      e(  21) =          4.79100000d0
      f(  21) =          0.18536100d0
      e(  22) =          1.98300000d0
      f(  22) =          0.45685400d0
      e(  23) =          0.78900000d0
      f(  23) =          0.43694200d0
      e(  24) =          0.29000000d0
      f(  24) =          0.19819800d0
c
      return
c
c pu   
c
  240 continue
c
      e(   1) =         11.56000000d0
      s(   1) =         -0.03648600d0
      e(   2) =          2.48700000d0
      s(   2) =          1.61569900d0
      e(   3) =          1.79900000d0
      s(   3) =         -3.63885600d0
      e(   4) =          1.17600000d0
      s(   4) =          2.03147100d0
      e(   5) =          0.35900000d0
      s(   5) =          0.85330400d0
      e(   6) =         11.56000000d0
      s(   6) =          0.01753100d0
      e(   7) =          2.48700000d0
      s(   7) =         -0.70279100d0
      e(   8) =          1.79900000d0
      s(   8) =          1.73396800d0
      e(   9) =          1.17600000d0
      s(   9) =         -1.09029600d0
      e(  10) =          0.35900000d0
      s(  10) =         -0.94506000d0
      e(  11) =          0.11300000d0
      s(  11) =          1.10626600d0
      e(  12) =          0.04000000d0
      s(  12) =          1.00000000d0
      e(  13) =          2.58000000d0
      p(  13) =          0.20050000d0
      e(  14) =          1.62200000d0
      p(  14) =         -0.59122600d0
      e(  15) =          0.74820000d0
      p(  15) =          0.79747300d0
      e(  16) =          0.27930000d0
      p(  16) =          0.56355500d0
      e(  17) =          2.58000000d0
      p(  17) =         -0.06970900d0
      e(  18) =          1.62200000d0
      p(  18) =          0.21961100d0
      e(  19) =          0.74820000d0
      p(  19) =         -0.35754700d0
      e(  20) =          0.27930000d0
      p(  20) =         -0.42816600d0
      e(  21) =          0.10000000d0
      p(  21) =          0.79326800d0
      e(  22) =          0.03700000d0
      p(  22) =          1.00000000d0
      e(  23) =          0.40900000d0
      d(  23) =          1.00000000d0
      e(  24) =          0.15200000d0
      d(  24) =          1.00000000d0
      e(  25) =          4.85700000d0
      f(  25) =          0.20668700d0
      e(  26) =          2.03100000d0
      f(  26) =          0.46962500d0
      e(  27) =          0.81500000d0
      f(  27) =          0.42121500d0
      e(  28) =          0.30200000d0
      f(  28) =          0.17252200d0
c
      return
      end
      subroutine ecpbas(ztype,csinp,cpinp,cdinp,cfinp,cginp,
     +   nucz,intyp,nangm,
     +   nbfs,minf,maxf,loc,ngauss,ns,ierr1,ierr2,nat)
c
c ****** ROUTINE for input and handling of LOCAL ECP basis sets
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/blkin/eex(200),ccs(200),ccp(200),ccd(200),ccf(200),
     +             ccg(200)
      common/junk/ptr(18192),iptr(4,maxat),iptrs(2,mxshel),
     *ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     *cf(mxprim),cg(mxprim),
     +kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     +kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell
INCLUDE(common/restar)
      dimension csinp(*),cpinp(*),cdinp(*),cfinp(*),cginp(*)
      dimension ns(*),intyp(*),nangm(*),nbfs(*),minf(*),maxf(*)
      dimension zecp(8)
      data pt75 /0.75d+00/
      data done/1.0d+00/
      data pt5,pi32,tol /0.5d+00,
     + 5.56832799683170d+00,1.0d-10/
      data pt187,pt6562 /1.875d+00,6.5625d+00/
      data zecp / 'sbkjc','cep','lanl','lanl2','crenbl',
     +            'crenbs','strlc','strsc' /
      data scalh1,scalh2/1.20d0,1.15d0/
c
c     ----- get exponents, contraction coefficients
c
      ng = 0
      igauss = ng
      ityp = ng
      ierr1=0
      ierr2=0
      odone = .false.
      ocep = .false.
      ohw = .false.
      olanl = .false.
      ocrenbl = .false.
      ocrenbs = .false.
      ostrlc = .false.
      ostrsc = .false.
_IFN1(civu)      call vclr(eex,1,1200)
_IF1(civu)      call szero(eex,1200)
c
c     decide which pseudopotential
c
      iecpt = locatc(zecp,8,ztype)
c
      if (iecpt.eq.0) then
       call caserr2('unrecognised ECP tag specified')
      else if (iecpt.eq.1.or.iecpt.eq.2) then
        ocep = .true.
      else if (iecpt.eq.3.or.iecpt.eq.4) then
        ohw = .true.
        if(iecpt.eq.4) olanl = .true.
      else if (iecpt.eq.5) then
        ocrenbl = .true.
      else if (iecpt.eq.6) then
        ocrenbs = .true.
      else if (iecpt.eq.7) then
        ostrlc = .true.
      else if (iecpt.eq.8) then
        ostrsc = .true.
      endif
c
      if (nucz .le. 2) then
c
c     ----- hydrogen and helium  -----
c
       if (ocep) then
         call sbkjc_0(eex,ccs,ccp,nucz)
       else if (ohw) then
         if (olanl) then
          call lanl_0(eex,ccs,ccp,nucz)
         else
          call ddzero(eex,ccs,ccp,nucz)
          eex(1) = eex(1)*scalh1**2
          eex(2) = eex(2)*scalh1**2
          eex(3) = eex(3)*scalh1**2
          eex(4) = eex(4)*scalh2**2
         endif
       else if (ocrenbl) then
        call crenbl_0(eex,ccs,ccp,nucz)
       else if (ocrenbs) then
        go to 1000
       else if (ostrlc) then
        call strlc_0(eex,ccs,ccp,ccd,ccf,nucz)
       else if (ostrsc) then
        go to 1200
       endif
c
      else if (nucz .le. 10) then
c
c     ----- lithium to neon  -----
c
       if (ocep) then
         call sbkjc_0(eex,ccs,ccp,nucz)
       else if (ohw) then
         if (olanl) then
          call lanl_0(eex,ccs,ccp,nucz)
         else
          call econe(eex,ccs,ccp,ccd,nucz)
         endif
       else if (ocrenbl) then
        call crenbl_0(eex,ccs,ccp,nucz)
       else if (ocrenbs) then
        go to 1000
       else if (ostrlc) then
        call strlc_0(eex,ccs,ccp,ccd,ccf,nucz)
       else if (ostrsc) then
        go to 1200
       endif
c
      else if (nucz .le. 18) then
c
c     ----- sodium to argon -----
c
       if (ocep) then
         call ectwo(eex,ccs,ccp,ccd,nucz)
       else if (ohw) then
         call ec2bas(eex,ccs,ccp,nucz,.false.)
       else if (ocrenbl) then
        call crenbl_1(eex,ccs,ccp,nucz)
       else if (ocrenbs) then
        go to 1000
       else if (ostrlc) then
        call strlc_1(eex,ccs,ccp,ccd,ccf,nucz)
       else if (ostrsc) then
        go to 1200
       endif
c
      else if (nucz .le. 36) then
c
c     ----- potassium to krypton -----
c
       if (ocep) then
        if (nucz.ge.21  .and.  nucz.le.30) then
           call ectm1(eex,ccs,ccp,ccd,nucz)
        else
           call ecthr(eex,ccs,ccp,ccd,nucz)
        end if
       else if (ohw) then
         call ec3bas(eex,ccs,ccp,ccd,nucz,.false.,olanl)
       else if (ocrenbl) then
        call crenbl_2(eex,ccs,ccp,ccd,nucz)
       else if (ocrenbs) then
        if (nucz.ge.21  .and.  nucz.le.30) then
          call crenbs_2(eex,ccs,ccp,ccd,nucz)
        else
          go to 1000
        end if
       else if (ostrlc) then
        call strlc_2(eex,ccs,ccp,ccd,ccf,nucz)
       else if (ostrsc) then
        call strsc_2(eex,ccs,ccp,ccd,ccf,nucz)
       else
          call caserr2('requested ECP basis set not available')
       endif
c
      else if (nucz .le. 54) then
c
c     ----- rubidium to xenon ----
c
       if (ocep) then
        if (nucz.ge.39  .and.  nucz.le.48) then
           call ectm2(eex,ccs,ccp,ccd,nucz)
        else
           call ecfour(eex,ccs,ccp,ccd,nucz)
        end if 
       else if (ohw) then
         call ec4bas(eex,ccs,ccp,ccd,nucz,.false.,olanl)
       else if (ocrenbl) then
        call crenbl_3(eex,ccs,ccp,ccd,nucz)
       else if (ocrenbs) then
        if (nucz.ge.39  .and.  nucz.le.48) then
           call crenbs_3(eex,ccs,ccp,ccd,nucz)
        else
          go to 1000
        end if 
       else if (ostrlc) then
        call strlc_3(eex,ccs,ccp,ccd,ccf,nucz)
       else if (ostrsc) then
        call strsc_3(eex,ccs,ccp,ccd,nucz)
       else
          call caserr2('requested ECP basis set not available')
       endif
c
      else if (nucz .le. 86) then
c
c     ----- cesium to radon
c
       if (ocep) then
        if (nucz.ge.58  .and.  nucz.le.71) then
           call ecplan(eex,ccs,ccp,ccd,ccf,nucz)
        else if (nucz.ge.57  .and.  nucz.le.80) then
           call ectm3(eex,ccs,ccp,ccd,nucz)
        else
           call ecfive(eex,ccs,ccp,ccd,nucz)
        end if
       else if (ohw) then
         call ec5bas(eex,ccs,ccp,ccd,nucz,.false.,olanl)
       else if (ocrenbl) then
        call crenbl_4(eex,ccs,ccp,ccd,ccf,nucz)
       else if (ocrenbs) then
        if (nucz.eq.57. or .
     +     (nucz.ge.72.and.nucz.le.80) .or.
     +     (nucz.ge.82.and.nucz.le.86)   ) then
          call crenbs_4(eex,ccs,ccp,ccd,nucz)
         else
          go to 1000
        endif
       else if (ostrlc) then
        call strlc_4(eex,ccs,ccp,ccd,nucz)
       else if (ostrsc) then
        call strsc_4(eex,ccs,ccp,ccd,ccf,nucz)
       endif
c
      else if (nucz.ge.87.and.nucz.le.103) then
c
c     ----- fr to lw
c
       if (ohw) then
         call ec6bas(eex,ccs,ccp,ccd,ccf,nucz)
       else if (ocrenbl) then
        call crenbl_5(eex,ccs,ccp,ccd,ccf,nucz)
       else if (ostrlc) then
        call strlc_5(eex,ccs,ccp,ccd,ccf,ccg,nucz)
       else if (ostrsc) then
        call strsc_5(eex,ccs,ccp,ccd,ccf,nucz)
       else
        call caserr2('requested ECP basis set not available')
       endif
c
      else
       call caserr2('requested ECP basis set not available')
      endif
c
c     ----- loop over each shell -----
c
      ipass = 0
  180 ipass = ipass+1
      if (ocep) then
        call ecpsbs(nucz,.false.,.false.,ipass,ityp,igauss,
     +              odone,.true.)
      else if (ohw) then
         if (olanl) then
          call ecphws2(nucz,ipass,ityp,igauss,odone)
         else
          call ecphws(nucz,.false.,.false.,ipass,ityp,igauss,odone)
         endif
      else if(ocrenbl) then
        call shcrenbl(nucz,ipass,ityp,igauss,odone)
      else if(ocrenbs) then
        call shcrenbs(nucz,ipass,ityp,igauss,odone)
      else if(ostrlc) then
        call shstrlc(nucz,ipass,ityp,igauss,odone)
      else if(ostrsc) then
        call shstrsc(nucz,ipass,ityp,igauss,odone)
      else
        call caserr2('unrecognised ECP basis set')
      endif
c
      if(odone) go to 220
c
c     ----- define the current shell -----
c
      nshell = nshell+1
      if (nshell.gt.mxshel) ierr1 = 1
      if (ierr1.ne.0) return
      ns(nat) = ns(nat)+1
      kmin(nshell) = minf(ityp)
      kmax(nshell) = maxf(ityp)
      kstart(nshell) = ngauss+1
      katom(nshell) = nat
      ktype(nshell) = nangm(ityp)
      intyp(nshell) = ityp
      kng(nshell) = igauss
      kloc(nshell) = loc+1
      ngauss = ngauss+igauss
      if (ngauss.gt.mxprim) ierr2 = 1
      if (ierr2.ne.0) return
      loc = loc+nbfs(ityp)
      k1 = kstart(nshell)
      k2 = k1+kng(nshell)-1
      do i = 1,igauss
         k = k1+i-1
         ex(k) = eex(ng+i) 
         if(ityp.eq.16) then
          csinp(k) = ccs(ng+i)
         else if(ityp.eq.17) then
          cpinp(k) = ccp(ng+i)
         else if(ityp.eq.18) then
          cdinp(k) = ccd(ng+i)
         else if(ityp.eq.19) then
          cfinp(k) = ccf(ng+i)
         else if(ityp.eq.20) then
          cginp(k) = ccg(ng+i)
         else if(ityp.eq.22) then
          csinp(k) = ccs(ng+i)
          cpinp(k) = ccp(ng+i)
         else
          call caserr2('invalid shell type')
         endif
         cs(k) = 0.0d0
         cp(k) = 0.0d0
         cd(k) = 0.0d0
         cf(k) = 0.0d0
         cg(k) = 0.0d0
         if(ityp.eq.16) then
          cs(k) = csinp(k)
         else if(ityp.eq.17) then
          cp(k) = cpinp(k)
         else if(ityp.eq.18) then
          cd(k) = cdinp(k)
         else if(ityp.eq.19) then
          cf(k) = cfinp(k)
         else if(ityp.eq.20) then
          cg(k) = cginp(k)
         else if(ityp.eq.22) then
          cs(k) = csinp(k)
          cp(k) = cpinp(k)
         else
          call caserr2('invalid shell type')
         endif
      enddo
c
c     ----- always unnormalize primitives -----
c
      do 460 k = k1,k2
         ee = ex(k)+ex(k)
         facs = pi32/(ee*sqrt(ee))
         facp = pt5*facs/ee
         facd = pt75*facs/(ee*ee)
         facf = pt187*facs/(ee**3)
         facg = pt6562*facs/(ee**4)
         if(ityp.eq.16) then
          cs(k) = cs(k)/sqrt(facs)
         else if(ityp.eq.17) then
          cp(k) = cp(k)/sqrt(facp)
         else if(ityp.eq.18) then
          cd(k) = cd(k)/sqrt(facd)
         else if(ityp.eq.19) then
          cf(k) = cf(k)/sqrt(facf)
         else if(ityp.eq.20) then
          cg(k) = cg(k)/sqrt(facg)
         else if(ityp.eq.22) then
          cs(k) = cs(k)/sqrt(facs)
          cp(k) = cp(k)/sqrt(facp)
         else
          call caserr2('invalid shell type')
         endif
  460 continue
c
c     ----- if(normf.eq.0) normalize basis functions -----
c
      if (normf .eq. 1) go to 180
      facs = 0.0d0
      facp = 0.0d0
      facd = 0.0d0
      facf = 0.0d0
      facg = 0.0d0
      do ig = k1,k2
         do jg = k1,ig
            ee = ex(ig)+ex(jg)
            fac = ee*sqrt(ee)
            dums = cs(ig)*cs(jg)/fac
            dump = pt5*cp(ig)*cp(jg)/(ee*fac)
            dumd = pt75*cd(ig)*cd(jg)/(ee*ee*fac)
            dumf = pt187*cf(ig)*cf(jg)/(ee**3*fac)
            dumg = pt6562*cg(ig)*cg(jg)/(ee**4*fac)
            if (ig .ne. jg) then
               dums = dums+dums
               dump = dump+dump
               dumd = dumd+dumd
               dumf = dumf+dumf
               dumg = dumg+dumg
            endif
            facs = facs+dums
            facp = facp+dump
            facd = facd+dumd
            facf = facf+dumf
            facg = facg+dumg
         enddo
      enddo
c
      fac=0.0d0
      if(ityp.eq.16.and. facs.gt.tol) then
       fac=done/sqrt(facs*pi32)
      else if(ityp.eq.17.and. facp.gt.tol) then
       fac=done/sqrt(facp*pi32)
      else if(ityp.eq.18.and. facd.gt.tol) then
       fac=done/sqrt(facd*pi32)
      else if(ityp.eq.19.and. facf.gt.tol) then
       fac=done/sqrt(facf*pi32)
      else if(ityp.eq.20.and. facg.gt.tol) then
       fac=done/sqrt(facg*pi32)
      else if(ityp.eq.22.and. facs.gt.tol.
     +                   and. facp.gt.tol ) then
        fac1=done/sqrt(facs*pi32)
        fac2=done/sqrt(facp*pi32)
      else
      endif
c
      do ig = k1,k2
         if(ityp.eq.16) then
          cs(ig) = fac*cs(ig)
         else if(ityp.eq.17) then
          cp(ig) = fac*cp(ig)
         else if(ityp.eq.18) then
          cd(ig) = fac*cd(ig)
         else if(ityp.eq.19) then
          cf(ig) = fac*cf(ig)
         else if(ityp.eq.20) then
          cg(ig) = fac*cg(ig)
         else if(ityp.eq.22) then
          cs(ig) = fac1*cs(ig)
          cp(ig) = fac2*cp(ig)
         else
         endif
      enddo
      ng = ng + igauss
      go to 180
c
  220 continue
      return
 1000 call caserr2('no CRENBS ecp basis for requested element')
 1200 call caserr2('no STRSC ecp basis for requested element')
      return
      end
      subroutine ecphws2(nucz,ipass,ityp,igauss,odone)
      implicit REAL (a-h,o-z)
      logical odone
      dimension maxps(14),itype(10,14),ngaus(10,14)
c
      data maxps/2,5,4,4,8,6,8,6,8,6,6,6,10,10/
      data itype/ 16,16,0,0,0,0,0,0,0,0,
     *            16,16,16,17,17,0,0,0,0,0,
     *            16,16,17,17,0,0,0,0,0,0,
     *            16,16,17,17,0,0,0,0,0,0,
     *            16,16,16,17,17,17,18,18,0,0,
     *            16,16,17,17,18,18,0,0,0,0,
     *            16,16,16,17,17,17,18,18,0,0,
     *            16,16,17,17,18,18,0,0,0,0,
     *            16,16,16,17,17,17,18,18,0,0,
     *            16,16,17,17,18,18,0,0,0,0,
     *            16,16,16,17,17,17,0,0,0,0,
     *            16,16,16,17,17,17,0,0,0,0,
     *            16,16,16,17,17,17,18,18,19,19,
     *            16,16,16,17,17,17,18,18,19,19/
      data ngaus/ 3,1,0,0,0,0,0,0,0,0,
     *            7,2,1,4,1,0,0,0,0,0,
     *            2,1,2,1,0,0,0,0,0,0,
     *            2,1,2,1,0,0,0,0,0,0,
     *            3,4,1,3,1,1,4,1,0,0,
     *            2,1,1,1,4,1,0,0,0,0,
     *            3,4,1,3,2,1,3,1,0,0,
     *            2,1,2,1,3,1,0,0,0,0,
     *            3,4,1,3,2,1,2,1,0,0,
     *            2,1,2,1,2,1,0,0,0,0,
     *            3,4,1,3,1,1,0,0,0,0,
     *            3,4,1,3,2,1,0,0,0,0,
     *            4,5,1,3,4,1,1,1,2,2,
     *            5,6,1,4,5,1,1,1,2,2 /
c
c     ----- define current shell parameters for hw basis sets -----
c        nucz  =nuclear charge of this atom
c        ipass =number of current shell
c        mxpass=total number of shells on this atom
c        ityp  =16,17,18,19,22 for s,p,d,f,l shells
c        igauss=number of gaussians in current shell
c        kind =0  means undefined (e.g. a lanthanide),
c             =1  means  h-he (non-hw)
c             =2  means li-ne (non-hw)
c             =3  means alkali/alkali earth
c             =4  means al-cl,ga-kr,in-xe,tl-bi main group,
c             =5  means 1st tm row semi-core transition metal
c             =6  means 1st tm row full-core (e.g. zn)
c             =7  means 2nd tm row semi-core transition metal
c             =8  means 2nd tm row full-core (e.g. cd)
c             =9  means 3rd tm row semi-core transition metal
c             =10 means 3rd tm row full-core (e.g. hg)
c             =11 means LASL2DZ alkali/alkali earth (e.g. k,ca,rb,sr)
c             =12 means LASL2DZ alkali/alkali earth (e.g. cs,ba)
c             =13 means LASL2DZ actinides (u and np)
c             =14 means LASL2DZ actinides (pu)
c
      kind=0
c             h,he
      if(nucz.ge. 1  .and.  nucz.le. 2) kind=1
c             li-ne
      if(nucz.ge. 3  .and.  nucz.le.10) kind=2
c             na-ar
      if(nucz.ge.11  .and.  nucz.le.12) kind=3
      if(nucz.ge.13  .and.  nucz.le.18) kind=4
c             k-kr
      if(nucz.ge.19  .and.  nucz.le.20) kind=11
      if(nucz.ge.21  .and.  nucz.le.29) kind=5
      if(nucz.eq.30)                    kind=6
      if(nucz.ge.31  .and.  nucz.le.36) kind=4
c             rb-xe
      if(nucz.ge.37  .and.  nucz.le.38) kind=12
      if(nucz.ge.39  .and.  nucz.le.47) kind=7
c
      if(nucz.eq.48)                    kind=8
      if(nucz.ge.49  .and.  nucz.le.54) kind=4
c             cs-rn
      if(nucz.ge.55  .and.  nucz.le.56) kind=12
c
      if(nucz.eq.57) kind = 9
c
      if(nucz.ge.58  .and.  nucz.le.71) kind=0
C****
      if(nucz.ge.72  .and.  nucz.le.79) kind=9
      if(nucz.eq.80)                    kind=10
      if(nucz.ge.81  .and.  nucz.le.83) kind=4
      if(nucz.ge.92  .and.  nucz.le.93) kind=13
      if(nucz.eq.94)                    kind=14
c
      if(kind.eq.0) then
         write(6,*) 'ecphws2: problem with z=',nucz
         call caserr2('problem in shell assignment for HW ECP basis')
      end if
c
      mxpass=maxps(kind)
      if(ipass.gt.mxpass) odone=.true.
      if(odone) return
c
      ityp   = itype(ipass,kind)
      igauss = ngaus(ipass,kind)
c
c     1st row - li different from b-ne
      if(nucz.eq.3.and.ipass.eq.4) igauss = 3
c
      return
      end
      subroutine lanl_0(e,s,p,n)
c
c     ----- LANL2DZ basis for first row atoms
c     ----- h - ne -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*)
c
      go to (100,120,
     +       140,160,180,200,220,240,260,280),n
c
c +++ basis h
c
100    continue
c
      e(   1) =         19.23840000d0
      s(   1) =          0.03282800d0
      e(   2) =          2.89870000d0
      s(   2) =          0.23120400d0
      e(   3) =          0.65350000d0
      s(   3) =          0.81722600d0
      e(   4) =          0.17760000d0
      s(   4) =          1.00000000d0
c
      go to 500
c
c +++ basis he
c
120    call caserr2('LANL2DZ ECP basis not available for He')
c
       go to 500
c
c +++ basis li
c
140    continue
c
      e(   1) =        921.30000000d0
      s(   1) =          0.00136700d0
      e(   2) =        138.70000000d0
      s(   2) =          0.01042500d0
      e(   3) =         31.94000000d0
      s(   3) =          0.04985900d0
      e(   4) =          9.35300000d0
      s(   4) =          0.16070100d0
      e(   5) =          3.15800000d0
      s(   5) =          0.34460400d0
      e(   6) =          1.15700000d0
      s(   6) =          0.42519700d0
      e(   7) =          0.44460000d0
      s(   7) =          0.16946800d0
      e(   8) =          0.44460000d0
      s(   8) =         -0.22231100d0
      e(   9) =          0.07666000d0
      s(   9) =          1.11647700d0
      e(  10) =          0.02864000d0
      s(  10) =          1.00000000d0
      e(  11) =          1.48800000d0
      p(  11) =          0.03877000d0
      e(  12) =          0.26670000d0
      p(  12) =          0.23625700d0
      e(  13) =          0.07201000d0
      p(  13) =          0.83044800d0
      e(  14) =          0.02370000d0
      p(  14) =          1.00000000d0
c
       go to 500
c
c +++ basis be
c
160    continue
c
      e(   1) =       1741.00000000d0
      s(   1) =          0.00130500d0
      e(   2) =        262.10000000d0
      s(   2) =          0.00995500d0
      e(   3) =         60.33000000d0
      s(   3) =          0.04803100d0
      e(   4) =         17.62000000d0
      s(   4) =          0.15857700d0
      e(   5) =          5.93300000d0
      s(   5) =          0.35132500d0
      e(   6) =          2.18500000d0
      s(   6) =          0.42700600d0
      e(   7) =          0.85900000d0
      s(   7) =          0.16049000d0
      e(   8) =          2.18500000d0
      s(   8) =         -0.18529400d0
      e(   9) =          0.18060000d0
      s(   9) =          1.05701400d0
      e(  10) =          0.05835000d0
      s(  10) =          1.00000000d0
      e(  11) =          6.71000000d0
      p(  11) =          0.01637800d0
      e(  12) =          1.44200000d0
      p(  12) =          0.09155300d0
      e(  13) =          0.41030000d0
      p(  13) =          0.34146900d0
      e(  14) =          0.13970000d0
      p(  14) =          0.68542800d0
      e(  15) =          0.04922000d0
      p(  15) =          1.00000000d0
c
      go to 500
c
c +++ basis b
c
180    continue
c
      e(   1) =       2788.00000000d0
      s(   1) =          0.00128800d0
      e(   2) =        419.00000000d0
      s(   2) =          0.00983500d0
      e(   3) =         96.47000000d0
      s(   3) =          0.04764800d0
      e(   4) =         28.07000000d0
      s(   4) =          0.16006900d0
      e(   5) =          9.37600000d0
      s(   5) =          0.36289400d0
      e(   6) =          3.40600000d0
      s(   6) =          0.43358200d0
      e(   7) =          1.30600000d0
      s(   7) =          0.14008200d0
      e(   8) =          3.40600000d0
      s(   8) =         -0.17933000d0
      e(   9) =          0.32450000d0
      s(   9) =          1.06259400d0
      e(  10) =          0.10220000d0
      s(  10) =          1.00000000d0
      e(  11) =         11.34000000d0
      p(  11) =          0.01798800d0
      e(  12) =          2.43600000d0
      p(  12) =          0.11034300d0
      e(  13) =          0.68360000d0
      p(  13) =          0.38307200d0
      e(  14) =          0.21340000d0
      p(  14) =          0.64789500d0
      e(  15) =          0.07011000d0
      p(  15) =          1.00000000d0
c
       go to 500
c
c +++ basis c
c
200    continue
c
      e(   1) =       4233.00000000d0
      s(   1) =          0.00122000d0
      e(   2) =        634.90000000d0
      s(   2) =          0.00934200d0
      e(   3) =        146.10000000d0
      s(   3) =          0.04545200d0
      e(   4) =         42.50000000d0
      s(   4) =          0.15465700d0
      e(   5) =         14.19000000d0
      s(   5) =          0.35886600d0
      e(   6) =          5.14800000d0
      s(   6) =          0.43863200d0
      e(   7) =          1.96700000d0
      s(   7) =          0.14591800d0
      e(   8) =          5.14800000d0
      s(   8) =         -0.16836700d0
      e(   9) =          0.49620000d0
      s(   9) =          1.06009100d0
      e(  10) =          0.15330000d0
      s(  10) =          1.00000000d0
      e(  11) =         18.16000000d0
      p(  11) =          0.01853900d0
      e(  12) =          3.98600000d0
      p(  12) =          0.11543600d0
      e(  13) =          1.14300000d0
      p(  13) =          0.38618800d0
      e(  14) =          0.35940000d0
      p(  14) =          0.64011400d0
      e(  15) =          0.11460000d0
      p(  15) =          1.00000000d0
c
       go to 500
c
c +++ basis n
c
220    continue
c
      e(   1) =       5909.00000000d0
      s(   1) =          0.00119000d0
      e(   2) =        887.50000000d0
      s(   2) =          0.00909900d0
      e(   3) =        204.70000000d0
      s(   3) =          0.04414500d0
      e(   4) =         59.84000000d0
      s(   4) =          0.15046400d0
      e(   5) =         20.00000000d0
      s(   5) =          0.35674100d0
      e(   6) =          7.19300000d0
      s(   6) =          0.44653300d0
      e(   7) =          2.68600000d0
      s(   7) =          0.14560300d0
      e(   8) =          7.19300000d0
      s(   8) =         -0.16040500d0
      e(   9) =          0.70000000d0
      s(   9) =          1.05821500d0
      e(  10) =          0.21330000d0
      s(  10) =          1.00000000d0
      e(  11) =         26.79000000d0
      p(  11) =          0.01825400d0
      e(  12) =          5.95600000d0
      p(  12) =          0.11646100d0
      e(  13) =          1.70700000d0
      p(  13) =          0.39017800d0
      e(  14) =          0.53140000d0
      p(  14) =          0.63710200d0
      e(  15) =          0.16540000d0
      p(  15) =          1.00000000d0
c
       go to 500
c
c +++ basis o
c
240    continue
c
      e(   1) =       7817.00000000d0
      s(   1) =          0.00117600d0
      e(   2) =       1176.00000000d0
      s(   2) =          0.00896800d0
      e(   3) =        273.20000000d0
      s(   3) =          0.04286800d0
      e(   4) =         81.17000000d0
      s(   4) =          0.14393000d0
      e(   5) =         27.18000000d0
      s(   5) =          0.35563000d0
      e(   6) =          9.53200000d0
      s(   6) =          0.46124800d0
      e(   7) =          3.41400000d0
      s(   7) =          0.14020600d0
      e(   8) =          9.53200000d0
      s(   8) =         -0.15415300d0
      e(   9) =          0.93980000d0
      s(   9) =          1.05691400d0
      e(  10) =          0.28460000d0
      s(  10) =          1.00000000d0
      e(  11) =         35.18000000d0
      p(  11) =          0.01958000d0
      e(  12) =          7.90400000d0
      p(  12) =          0.12420000d0
      e(  13) =          2.30500000d0
      p(  13) =          0.39471400d0
      e(  14) =          0.71710000d0
      p(  14) =          0.62737600d0
      e(  15) =          0.21370000d0
      p(  15) =          1.00000000d0
c
       go to 500
c
c +++ basis f
c
260    continue
c
      e(   1) =       9995.00000000d0
      s(   1) =          0.00116000d0
      e(   2) =       1506.00000000d0
      s(   2) =          0.00887000d0
      e(   3) =        350.30000000d0
      s(   3) =          0.04238000d0
      e(   4) =        104.10000000d0
      s(   4) =          0.14292900d0
      e(   5) =         34.84000000d0
      s(   5) =          0.35537200d0
      e(   6) =         12.22000000d0
      s(   6) =          0.46208500d0
      e(   7) =          4.36900000d0
      s(   7) =          0.14084800d0
      e(   8) =         12.22000000d0
      s(   8) =         -0.14845200d0
      e(   9) =          1.20800000d0
      s(   9) =          1.05527000d0
      e(  10) =          0.36340000d0
      s(  10) =          1.00000000d0
      e(  11) =         44.36000000d0
      p(  11) =          0.02087600d0
      e(  12) =         10.08000000d0
      p(  12) =          0.13010700d0
      e(  13) =          2.99600000d0
      p(  13) =          0.39616600d0
      e(  14) =          0.93830000d0
      p(  14) =          0.62040400d0
      e(  15) =          0.27330000d0
      p(  15) =          1.00000000d0
c
       go to 500
c
c +++ basis ne
c
280    continue
c
      e(   1) =      12100.00000000d0
      s(   1) =          0.00120000d0
      e(   2) =       1821.00000000d0
      s(   2) =          0.00909200d0
      e(   3) =        432.80000000d0
      s(   3) =          0.04130500d0
      e(   4) =        132.50000000d0
      s(   4) =          0.13786700d0
      e(   5) =         43.77000000d0
      s(   5) =          0.36243300d0
      e(   6) =         14.91000000d0
      s(   6) =          0.47224700d0
      e(   7) =          5.12700000d0
      s(   7) =          0.13003500d0
      e(   8) =         14.91000000d0
      s(   8) =         -0.14081000d0
      e(   9) =          1.49100000d0
      s(   9) =          1.05332700d0
      e(  10) =          0.44680000d0
      s(  10) =          1.00000000d0
      e(  11) =         56.45000000d0
      p(  11) =          0.02087500d0
      e(  12) =         12.92000000d0
      p(  12) =          0.13003200d0
      e(  13) =          3.86500000d0
      p(  13) =          0.39567900d0
      e(  14) =          1.20300000d0
      p(  14) =          0.62145000d0
      e(  15) =          0.34440000d0
      p(  15) =          1.00000000d0
c
  500 continue
      return
      end
      subroutine sbkjc_0(e,s,p,n)
c
c     ----- SBKJC VDZ basis for first row atoms
c     ----- h - ne -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*)
c
      go to (100,120,
     +       140,160,180,200,220,240,260,280),n
c
c +++ basis h
c
100    continue
c
      e(   1) =          5.44717800d0
      s(   1) =          0.15628500d0
      e(   2) =          0.82454700d0
      s(   2) =          0.90469100d0
      e(   3) =          0.18319200d0
      s(   3) =          1.00000000d0
c
      go to 500
c
c +++ basis he
c
120    continue
c
      e(   1) =         13.62670000d0
      s(   1) =          0.17523000d0
      e(   2) =          1.99935000d0
      s(   2) =          0.89348300d0
      e(   3) =          0.38299300d0
      s(   3) =          1.00000000d0
c
       go to 500
c
c +++ basis li
c
140    continue
c
      e(   1) =          0.61770000d0
      s(   1) =         -0.16287000d0
      e(   2) =          0.14340000d0
      s(   2) =          0.12643000d0
      e(   3) =          0.05048000d0
      s(   3) =          0.76179000d0
      p(   1) =          0.06205000d0
      p(   2) =          0.24719000d0
      p(   3) =          0.52140000d0
      e(   4) =          0.01923000d0
      s(   4) =          0.21800000d0
      p(   4) =          0.34290000d0
c
       go to 500
c
c +++ basis be
c
160    continue
c
      e(   1) =          1.44700000d0
      s(   1) =         -0.15647000d0
      e(   2) =          0.35220000d0
      s(   2) =          0.10919000d0
      e(   3) =          0.12190000d0
      s(   3) =          0.67538000d0
      p(   1) =          0.08924000d0
      p(   2) =          0.30999000d0
      p(   3) =          0.51842000d0
      e(   4) =          0.04395000d0
      s(   4) =          0.32987000d0
      p(   4) =          0.27911000d0
c
      go to 500
c
c +++ basis b
c
180    continue
c
      e(   1) =          2.71000000d0
      s(   1) =         -0.14987000d0
      e(   2) =          0.65520000d0
      s(   2) =          0.08442000d0
      e(   3) =          0.22480000d0
      s(   3) =          0.69751000d0
      p(   1) =          0.09474000d0
      p(   2) =          0.30807000d0
      p(   3) =          0.46876000d0
      e(   4) =          0.07584000d0
      s(   4) =          0.32842000d0
      p(   4) =          0.35025000d0
c
       go to 500
c
c +++ basis c
c
200    continue
c
      e(   1) =          4.28600000d0
      s(   1) =         -0.14722000d0
      e(   2) =          1.04600000d0
      s(   2) =          0.08125000d0
      e(   3) =          0.34470000d0
      s(   3) =          0.71360000d0
      p(   1) =          0.10257000d0
      p(   2) =          0.32987000d0
      p(   3) =          0.48212000d0
      e(   4) =          0.11280000d0
      s(   4) =          0.31521000d0
      p(   4) =          0.31593000d0
c
       go to 500
c
c +++ basis n
c
220    continue
c
      e(   1) =          6.40300000d0
      s(   1) =         -0.13955000d0
      e(   2) =          1.58000000d0
      s(   2) =          0.05492000d0
      e(   3) =          0.50940000d0
      s(   3) =          0.71678000d0
      p(   1) =          0.10336000d0
      p(   2) =          0.33205000d0
      p(   3) =          0.48708000d0
      e(   4) =          0.16230000d0
      s(   4) =          0.33210000d0
      p(   4) =          0.31312000d0
c
       go to 500
c
c +++ basis o
c
240    continue
c
      e(   1) =          8.51900000d0
      s(   1) =         -0.14551000d0
      e(   2) =          2.07300000d0
      s(   2) =          0.08286000d0
      e(   3) =          0.64710000d0
      s(   3) =          0.74325000d0
      p(   1) =          0.11007000d0
      p(   2) =          0.34969000d0
      p(   3) =          0.48093000d0
      e(   4) =          0.20000000d0
      s(   4) =          0.28472000d0
      p(   4) =          0.30727000d0
c
       go to 500
c
c +++ basis f
c
260    continue
c
      e(   1) =         11.12000000d0
      s(   1) =         -0.14451000d0
      e(   2) =          2.68700000d0
      s(   2) =          0.08971000d0
      e(   3) =          0.82100000d0
      s(   3) =          0.75659000d0
      p(   1) =          0.11300000d0
      p(   2) =          0.35841000d0
      p(   3) =          0.48002000d0
      e(   4) =          0.24750000d0
      s(   4) =          0.26570000d0
      p(   4) =          0.30381000d0
c
       go to 500
c
c +++ basis ne
c
280    continue
c
      e(   1) =         14.07000000d0
      s(   1) =         -0.14463000d0
      e(   2) =          3.38900000d0
      s(   2) =          0.09331000d0
      e(   3) =          1.02100000d0
      s(   3) =          0.76297000d0
      p(   1) =          0.11514000d0
      p(   2) =          0.36479000d0
      p(   3) =          0.48052000d0
      e(   4) =          0.30310000d0
      s(   4) =          0.25661000d0
      p(   4) =          0.29896000d0
c
  500 continue
      return
      end
      subroutine shcrenbl(nucz,ipass,itype,igauss,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c   ******************************************************************
c   CRENBL ECP   -  Christiansen et al. Large Orbital Basis, Small Core Pot.
c  Elements  Primitives                         References
c  H:       (4s)            T. H. Dunning, Jr. and P. J. Hay, Methods of
c                           Electronic Structure Theory, Vol. 3, H. F.
c                           Schaefer III, Ed. Plenum Press (1977).
c  Li - Ne: (4s,4p)         L. F. Pacios and P. A. Christiansen, J. Chem. Phys.
c
c                           82, (1985) 2664.
c  Na - Mg: (6s,4p)
c  Al - Ar: (4s,4p)
c  K - Ca:  (5s,4p)         M. M. Hurley et al. J. Chem. Phys. 84, 6840 (1986)
c  Sc - Zn: (7s,6p,6d)
c  Ga - Kr: (3s,3p,4d)
c  Rb - Sr: (5s,5p)         L. A. LaJohn et al. J. Chem. Phys., 87, 2812 (1987)
c
c  Y - Cd:  (5s,5p,4d)
c  In - I:  (3s,3p,4d)
c  Xe:      (3s,3p,4d)      M. M. Hurley et al., J. Chem. Phys. 84, (1986) 6840
c  .
c  Cs:      (5s,5p,4d)      R. B. Ross, W. C. Ermler, P. A. Christiansen et al.
c
c                           J. Chem. Phys. 93, 6654 (1990).
c  Ba:      (5s,5p,4d)      R.B. ROSS, W.C. ERMLER, P.A. CHRISTIANSEN,
c                           ET AL. SUB.TO J. CHEM. PHYS.
c  La:      (5s,5p,4d)      R.B. ROSS, W.C. ERMLER, P.A. CHRISTIANSEN
c                           ET AL. J. CHEM. PHYS. 93,(1990)6654.
c  Ce - Lu: (6s,6p,6d,6f)   R.B. Ross, W.C. Ermler, S. Das, To be published
c  Hf - Hg: (5s,5p,4d)      R.B. ROSS, W.C. ERMLER, P.A. CHRISTIANSEN
c                           ET AL. J. CHEM. PHYS. 93,(1990)6654.
c  Ti - Rn: (3s,3p,4d)
c  Fr - Ra: (5s,5p,4d)      W.C. ERMLER, R.B. ROSS, P.A. CHRISTIANSEN,
c                           INT. J. QUANT. CHEM. 40,(1991)829.
c  Ac - Pu: (5s,5p,4d,4f)
c  Am - Uub:  (0s,2p,6d,5f) C.S. NASH, B.E. BURSTEN, W.C. ERMLER,
c                                         J. CHEM. PHYS. 1997
c  Uut - Uuo: (0s,3p,6d,5f)
**
c  These ECPs are sometimes referred to as shape consistent because they
c  maintain the shape of the atomic orbitals in the valence region.
c   ******************************************************************
      dimension igau(24,11), itypes(24,11)
      dimension kind(11)
      data kind/4,8,10,9,19,10,10,14,24,18,13/
      data igau /
     + 1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0 /
      data itypes /
     + 1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,0,0,0,0,0,
     + 1,1,1,2,2,2,3,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,2,2,2,2,2,3,3,3,3,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,
     + 1,1,1,1,1,2,2,2,2,2,3,3,3,3,4,4,4,4,0,0,0,0,0,0,
     + 2,2,3,3,3,3,3,3,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0 /
c
c     set values for the current ccdz  shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3,4 for s,p,d,f shell
c
      ind=1
      if(nucz.ge. 3  .and.  nucz.le.10) ind=2
      if(nucz.ge.11  .and.  nucz.le.12) ind=3
      if(nucz.ge.13  .and.  nucz.le.18) ind=2
      if(nucz.ge.19  .and.  nucz.le.20) ind=4
      if(nucz.ge.21  .and.  nucz.le.30) ind=5
      if(nucz.ge.31  .and.  nucz.le.36) ind=6
      if(nucz.ge.37  .and.  nucz.le.38) ind=7
      if(nucz.ge.39  .and.  nucz.le.48) ind=8
      if(nucz.ge.49  .and.  nucz.le.54) ind=6
      if(nucz.ge.55  .and.  nucz.le.57) ind=8
      if(nucz.ge.58  .and.  nucz.le.71) ind=9
      if(nucz.ge.72  .and.  nucz.le.80) ind=8
      if(nucz.ge.81  .and.  nucz.le.86) ind=6
      if(nucz.ge.87  .and.  nucz.le.88) ind=8
      if(nucz.ge.89  .and.  nucz.le.94) ind=10
      if(nucz.ge.95  .and.  nucz.le.103) ind=11
      if(nucz.gt.103) then
         call caserr2(
     +          'CRENBL ecp basis sets only extend to Lr')
      end if
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if(.not.odone) then
c
       igauss = igau(ipass,ind)
       ityp = itypes(ipass,ind)
      endif
      itype = ityp + 15
c
      return
      end
      subroutine crenbl_0(e,s,p,n)
c
c     ----- ECP Christiansen et al. Large Orbital Basis, Small Core Pot --
c     ----- h - ne -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*)
c
      go to (100,120,
     +       140,160,180,200,220,240,260,280),n
c
c +++ basis h
c
100    continue
c
      e(   1) =         13.36000000d0
      e(   2) =          2.01300000d0
      e(   3) =          0.45380000d0
      e(   4) =          0.12330000d0
      do i = 1,4
       s(i) = 1.0d0
      enddo
      return
c
c +++ basis he
c
120    call caserr2('CRENBL ECP basis not available for He')
c
       go to 500
c
c +++ basis li
c
140    continue
c
      e(   1) =          3.76400000d0
      e(   2) =          0.56410000d0
      e(   3) =          0.07417000d0
      e(   4) =          0.02833000d0
      e(   5) =          1.48700000d0
      e(   6) =          0.26810000d0
      e(   7) =          0.07252000d0
      e(   8) =          0.02385000d0
c
       go to 500
c
c +++ basis be
c
160    continue
c
      e(   1) =          7.89000000d0
      e(   2) =          1.30600000d0
      e(   3) =          0.17020000d0
      e(   4) =          0.05668000d0
      e(   5) =          3.15300000d0
      e(   6) =          0.62520000d0
      e(   7) =          0.17720000d0
      e(   8) =          0.05673000d0
c
      go to 500
c
c
c +++ basis b
c
180    continue
      e(   1) =          2.92600000d0
      e(   2) =          0.29640000d0
      e(   3) =          0.13060000d0
      e(   4) =          0.06673000d0
      e(   5) =          4.86400000d0
      e(   6) =          1.01900000d0
      e(   7) =          0.28790000d0
      e(   8) =          0.08601000d0
c
       go to 500
c
c +++ basis c
c
200    continue
c
      e(   1) =          4.36200000d0
      e(   2) =          0.43660000d0
      e(   3) =          0.17230000d0
      e(   4) =          0.08716000d0
      e(   5) =          6.78700000d0
      e(   6) =          1.49700000d0
      e(   7) =          0.42970000d0
      e(   8) =          0.12860000d0
c
       go to 500
c
c +++ basis n
c
220    continue
c
      e(   1) =          6.26100000d0
      e(   2) =          0.65380000d0
      e(   3) =          0.31520000d0
      e(   4) =          0.17340000d0
      e(   5) =         10.11000000d0
      e(   6) =          2.26900000d0
      e(   7) =          0.64870000d0
      e(   8) =          0.19040000d0
c
       go to 500
c
c +++ basis o
c
240    continue
c
      e(   1) =          8.65700000d0
      e(   2) =          0.86920000d0
      e(   3) =          0.39940000d0
      e(   4) =          0.19780000d0
      e(   5) =         13.34000000d0
      e(   6) =          3.01600000d0
      e(   7) =          0.84890000d0
      e(   8) =          0.23710000d0
c
       go to 500
c
c +++ basis f
c
260    continue
c
      e(   1) =         11.38000000d0
      e(   2) =          1.13200000d0
      e(   3) =          0.56250000d0
      e(   4) =          0.25660000d0
      e(   5) =         17.16000000d0
      e(   6) =          3.89300000d0
      e(   7) =          1.08800000d0
      e(   8) =          0.29800000d0
c
       go to 500
c
c +++ basis ne
c
280    continue
c
      e(   1) =         14.30000000d0
      e(   2) =          1.52800000d0
      e(   3) =          0.58420000d0
      e(   4) =          0.31180000d0
      e(   5) =         22.12000000d0
      e(   6) =          5.12500000d0
      e(   7) =          1.43300000d0
      e(   8) =          0.38380000d0
c
  500 continue
      do i = 1, 4
       s(i) = 1.0d0
       p(i+4) = 1.0d0
      enddo
c
      return
      end
      subroutine crenbl_1(e,s,p,n)
c
c     ----- ECP Christiansen et al. Large Orbital Basis, Small Core Pot --
c     ----- na - ar -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*)
c
      nn = n - 10
      go to (300,320,340,360,380,400,420,440),nn
c
c
c +++ basis na
c
  300 continue
c
      e(   1) =         15.68000000d0
      e(   2) =          1.83600000d0
      e(   3) =          0.57840000d0
      e(   4) =          0.31320000d0
      e(   5) =          0.07191000d0
      e(   6) =          0.02914000d0
      e(   7) =         25.26000000d0
      e(   8) =          5.89500000d0
      e(   9) =          1.70600000d0
      e(  10) =          0.50240000d0
c
      go to 330
c
c +++ basis mg
c
  320 continue
c
      e(   1) =         19.33000000d0
      e(   2) =          2.14800000d0
      e(   3) =          0.72700000d0
      e(   4) =          0.22060000d0
      e(   5) =          0.07381000d0
      e(   6) =          0.02394000d0
      e(   7) =         24.45000000d0
      e(   8) =          5.69000000d0
      e(   9) =          1.69900000d0
      e(  10) =          0.55050000d0
c
330   do i =1,6
       s(i) = 1.0d0
      enddo
      do i = 1,4
       p(i+6) = 1.0d0
      enddo
c
      go to 500
c
c +++ basis al
c
340    continue
c
      e(   1) =          9.35100000d0
      e(   2) =          0.95720000d0
      e(   3) =          0.15860000d0
      e(   4) =          0.05381000d0
      e(   5) =          3.90600000d0
      e(   6) =          1.56700000d0
      e(   7) =          0.19770000d0
      e(   8) =          0.05730000d0
c
       go to 500
c
c +++ basis si
c
360    continue
c
      e(   1) =         11.07000000d0
      e(   2) =          1.22100000d0
      e(   3) =          0.24730000d0
      e(   4) =          0.08624000d0
      e(   5) =          6.67100000d0
      e(   6) =          2.12000000d0
      e(   7) =          0.29750000d0
      e(   8) =          0.08867000d0
c
       go to 500
c
c +++ basis p
c
380    continue
c
      e(   1) =         14.10000000d0
      e(   2) =          1.50200000d0
      e(   3) =          0.32420000d0
      e(   4) =          0.11350000d0
      e(   5) =          8.14000000d0
      e(   6) =          2.64800000d0
      e(   7) =          0.40160000d0
      e(   8) =          0.12180000d0
c
       go to 500
c
c +++ basis s
c
400    continue
c
      e(   1) =         17.03000000d0
      e(   2) =          1.77700000d0
      e(   3) =          0.41840000d0
      e(   4) =          0.14490000d0
      e(   5) =         11.84000000d0
      e(   6) =          3.59900000d0
      e(   7) =          0.50820000d0
      e(   8) =          0.14920000d0
c
       go to 500
c
c +++ basis cl
c
420    continue
c
      e(   1) =         21.51000000d0
      e(   2) =          2.14500000d0
      e(   3) =          0.51190000d0
      e(   4) =          0.17990000d0
      e(   5) =         14.55000000d0
      e(   6) =          4.17900000d0
      e(   7) =          0.62910000d0
      e(   8) =          0.18300000d0
c
       go to 500
c
c +++ basis ar
c
440    continue
c
      e(   1) =         25.99000000d0
      e(   2) =          2.33600000d0
      e(   3) =          0.65030000d0
      e(   4) =          0.22400000d0
      e(   5) =         16.49000000d0
      e(   6) =          5.25500000d0
      e(   7) =          0.76890000d0
      e(   8) =          0.22230000d0
c
  500 continue
      do i = 1, 4
      s(i) = 1.0d0
      p(i+4) = 1.0d0
      enddo
c
      return
      end
      subroutine crenbl_2(e,s,p,d,n)
c
c     ----- ECP Christiansen et al. Large Orbital Basis, Small Core Pot --
c     ----- basis (K-Kr) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
c
      nn = n-18
      go to (100,120,140,160,180,200,220,240,260,280,300,320,
     +       340,360,380,400,420,440),nn
c
c k   
c
  100 continue
c
      e(   1) =          2.88900000d0
      e(   2) =          0.81960000d0
      e(   3) =          0.31270000d0
      e(   4) =          0.03388000d0
      e(   5) =          0.01725000d0
      e(   6) =          8.71400000d0
      e(   7) =          1.08900000d0
      e(   8) =          0.59060000d0
      e(   9) =          0.22670000d0
c
      go to 130
c
c ca   
c
  120 continue
c
      e(   1) =          3.33500000d0
      e(   2) =          0.98920000d0
      e(   3) =          0.39770000d0
      e(   4) =          0.06394000d0
      e(   5) =          0.02670000d0
      e(   6) =         10.55000000d0
      e(   7) =          1.32600000d0
      e(   8) =          0.76960000d0
      e(   9) =          0.30070000d0
130   continue
      do i = 1, 5
       s(i) = 1.0d0
      enddo
      do i = 6,9
       p(i) = 1.0d0
      enddo
      return
c
c sc   
c
  140 continue
c
      e(   1) =         36.58000000d0
      e(   2) =         11.04000000d0
      e(   3) =          4.49100000d0
      e(   4) =          1.12900000d0
      e(   5) =          0.45460000d0
      e(   6) =          0.07753000d0
      e(   7) =          0.03079000d0
      e(   8) =         32.59000000d0
      e(   9) =         13.22000000d0
      e(  10) =          5.58400000d0
      e(  11) =          2.18600000d0
      e(  12) =          0.89500000d0
      e(  13) =          0.35200000d0
      e(  14) =         22.43000000d0
      e(  15) =          6.03500000d0
      e(  16) =          1.97900000d0
      e(  17) =          0.66680000d0
      e(  18) =          0.21820000d0
      e(  19) =          0.05880000d0
c
      go to 330
c
c ti   
c
  160 continue
c
      e(   1) =         39.81000000d0
      e(   2) =         12.22000000d0
      e(   3) =          5.00900000d0
      e(   4) =          1.28600000d0
      e(   5) =          0.51280000d0
      e(   6) =          0.08558000d0
      e(   7) =          0.03300000d0
      e(   8) =         36.37000000d0
      e(   9) =         14.78000000d0
      e(  10) =          6.27500000d0
      e(  11) =          2.47900000d0
      e(  12) =          1.01600000d0
      e(  13) =          0.39820000d0
      e(  14) =         25.99000000d0
      e(  15) =          7.08600000d0
      e(  16) =          2.34900000d0
      e(  17) =          0.80020000d0
      e(  18) =          0.26200000d0
      e(  19) =          0.07200000d0
c
      go to 330
c
c v   
c
  180 continue
c
      e(   1) =         43.25000000d0
      e(   2) =         13.51000000d0
      e(   3) =          5.56700000d0
      e(   4) =          1.45200000d0
      e(   5) =          0.57440000d0
      e(   6) =          0.09282000d0
      e(   7) =          0.03553000d0
      e(   8) =         40.32000000d0
      e(   9) =         16.46000000d0
      e(  10) =          7.02400000d0
      e(  11) =          2.79000000d0
      e(  12) =          1.14600000d0
      e(  13) =          0.44730000d0
      e(  14) =         30.22000000d0
      e(  15) =          8.27200000d0
      e(  16) =          2.75800000d0
      e(  17) =          0.94210000d0
      e(  18) =          0.30530000d0
      e(  19) =          0.08200000d0
c
      go to 330
c
c cr   
c
  200 continue
c
      e(   1) =         46.37000000d0
      e(   2) =         14.82000000d0
      e(   3) =          6.13300000d0
      e(   4) =          1.63000000d0
      e(   5) =          0.64120000d0
      e(   6) =          0.09551000d0
      e(   7) =          0.03759000d0
      e(   8) =         43.20000000d0
      e(   9) =         17.78000000d0
      e(  10) =          7.66100000d0
      e(  11) =          3.07700000d0
      e(  12) =          1.26600000d0
      e(  13) =          0.49350000d0
      e(  14) =         34.02000000d0
      e(  15) =          9.43200000d0
      e(  16) =          3.15900000d0
      e(  17) =          1.08000000d0
      e(  18) =          0.34660000d0
      e(  19) =          0.09120000d0
c
      go to 330
c
c mn   
c
  220 continue
c
      e(   1) =         49.12000000d0
      e(   2) =         16.09000000d0
      e(   3) =          6.70400000d0
      e(   4) =          1.80500000d0
      e(   5) =          0.70300000d0
      e(   6) =          0.10640000d0
      e(   7) =          0.03962000d0
      e(   8) =         44.61000000d0
      e(   9) =         18.60000000d0
      e(  10) =          8.13800000d0
      e(  11) =          3.33700000d0
      e(  12) =          1.37900000d0
      e(  13) =          0.53860000d0
      e(  14) =         37.90000000d0
      e(  15) =         10.52000000d0
      e(  16) =          3.53800000d0
      e(  17) =          1.21200000d0
      e(  18) =          0.38790000d0
      e(  19) =          0.10540000d0
c
      go to 330
c
c fe   
c
  240 continue
c
      e(   1) =         53.50000000d0
      e(   2) =         17.72000000d0
      e(   3) =          7.37700000d0
      e(   4) =          2.01800000d0
      e(   5) =          0.77990000d0
      e(   6) =          0.11420000d0
      e(   7) =          0.04189000d0
      e(   8) =         49.12000000d0
      e(   9) =         20.50000000d0
      e(  10) =          8.98700000d0
      e(  11) =          3.68200000d0
      e(  12) =          1.52200000d0
      e(  13) =          0.59270000d0
      e(  14) =         41.45000000d0
      e(  15) =         11.54000000d0
      e(  16) =          3.88500000d0
      e(  17) =          1.32400000d0
      e(  18) =          0.41670000d0
      e(  19) =          0.11330000d0
c
      go to 330
c
c co   
c
  260 continue
c
      e(   1) =         56.12000000d0
      e(   2) =         18.92000000d0
      e(   3) =          7.95200000d0
      e(   4) =          2.19800000d0
      e(   5) =          0.84670000d0
      e(   6) =          0.12230000d0
      e(   7) =          0.04417000d0
      e(   8) =         49.24000000d0
      e(   9) =         20.75000000d0
      e(  10) =          9.20400000d0
      e(  11) =          3.81800000d0
      e(  12) =          1.58800000d0
      e(  13) =          0.62470000d0
      e(  14) =         44.98000000d0
      e(  15) =         12.57000000d0
      e(  16) =          4.24400000d0
      e(  17) =          1.44300000d0
      e(  18) =          0.45000000d0
      e(  19) =          0.12190000d0
c
      go to 330
c
c ni   
c
  280 continue
c
      e(   1) =         59.26000000d0
      e(   2) =         20.37000000d0
      e(   3) =          8.59400000d0
      e(   4) =          2.39400000d0
      e(   5) =          0.91820000d0
      e(   6) =          0.13020000d0
      e(   7) =          0.04639000d0
      e(   8) =         53.17000000d0
      e(   9) =         22.39000000d0
      e(  10) =          9.92800000d0
      e(  11) =          4.11600000d0
      e(  12) =          1.71000000d0
      e(  13) =          0.67250000d0
      e(  14) =         48.94000000d0
      e(  15) =         13.72000000d0
      e(  16) =          4.64000000d0
      e(  17) =          1.57400000d0
      e(  18) =          0.48640000d0
      e(  19) =          0.13160000d0
c
      go to 330
c
c cu   
c
  300 continue
c
      e(   1) =         64.63000000d0
      e(   2) =         22.14000000d0
      e(   3) =          9.34700000d0
      e(   4) =          2.60900000d0
      e(   5) =          0.99720000d0
      e(   6) =          0.14010000d0
      e(   7) =          0.04936000d0
      e(   8) =         60.48000000d0
      e(   9) =         25.36000000d0
      e(  10) =         11.17000000d0
      e(  11) =          4.56400000d0
      e(  12) =          1.88400000d0
      e(  13) =          0.73470000d0
      e(  14) =         53.65000000d0
      e(  15) =         15.07000000d0
      e(  16) =          5.10400000d0
      e(  17) =          1.72700000d0
      e(  18) =          0.52830000d0
      e(  19) =          0.14910000d0
c
      go to 330
c
c zn   
c
  320 continue
c
      e(   1) =         68.59000000d0
      e(   2) =         23.71000000d0
      e(   3) =         10.04000000d0
      e(   4) =          2.81000000d0
      e(   5) =          1.07000000d0
      e(   6) =          0.14700000d0
      e(   7) =          0.05114000d0
      e(   8) =         66.08000000d0
      e(   9) =         27.69000000d0
      e(  10) =         12.18000000d0
      e(  11) =          4.98800000d0
      e(  12) =          2.05800000d0
      e(  13) =          0.79860000d0
      e(  14) =         58.41000000d0
      e(  15) =         16.45000000d0
      e(  16) =          5.57600000d0
      e(  17) =          1.88400000d0
      e(  18) =          0.57230000d0
      e(  19) =          0.19080000d0
c
  330 do i = 1,7
       s(i) = 1.0d0
      enddo
      do i = 1,6
       p(i+7) = 1.0d0
       d(i+13) = 1.0d0
      enddo
      return
c
c ga  
c
  340 continue
c
      e(   1) =          0.97380000d0
      e(   2) =          0.22150000d0
      e(   3) =          0.07653000d0
      e(   4) =          1.70800000d0
      e(   5) =          0.20180000d0
      e(   6) =          0.05750000d0
      e(   7) =         39.56000000d0
      e(   8) =         10.68000000d0
      e(   9) =          3.28000000d0
      e(  10) =          0.91310000d0
c
      go to 500
c
c ge  
c 
  360 continue
c
      e(   1) =          1.01800000d0
      e(   2) =          0.31880000d0
      e(   3) =          0.10300000d0
      e(   4) =          1.83600000d0
      e(   5) =          0.26220000d0
      e(   6) =          0.07976000d0
      e(   7) =         44.88000000d0
      e(   8) =         12.25000000d0
      e(   9) =          3.83200000d0
      e(  10) =          1.10600000d0
c
      go to 500
c
c as  
c 
  380 continue
c
      e(   1) =          1.22100000d0
      e(   2) =          0.32000000d0
      e(   3) =          0.11380000d0
      e(   4) =          1.97600000d0
      e(   5) =          0.32320000d0
      e(   6) =          0.10240000d0
      e(   7) =         50.14000000d0
      e(   8) =         13.81000000d0
      e(   9) =          4.38300000d0
      e(  10) =          1.30400000d0
c
      go to 500
c
c se  
c
  400 continue
c
      e(   1) =          1.34000000d0
      e(   2) =          0.37170000d0
      e(   3) =          0.13220000d0
      e(   4) =          2.14200000d0
      e(   5) =          0.38540000d0
      e(   6) =          0.11950000d0
      e(   7) =         55.15000000d0
      e(   8) =         15.38000000d0
      e(   9) =          4.94700000d0
      e(  10) =          1.50600000d0
c
      go to 500
c
c br  
c 
  420 continue
c
      e(   1) =          1.38000000d0
      e(   2) =          0.52230000d0
      e(   3) =          0.17270000d0
      e(   4) =          2.53700000d0
      e(   5) =          0.44970000d0
      e(   6) =          0.13960000d0
      e(   7) =         62.41000000d0
      e(   8) =         17.27000000d0
      e(   9) =          5.58300000d0
      e(  10) =          1.73200000d0
c
      go to 500
c
c kr  
c
  440 continue
c
      e(   1) =          1.59700000d0
      e(   2) =          0.48650000d0
      e(   3) =          0.16940000d0
      e(   4) =          2.66600000d0
      e(   5) =          0.51760000d0
      e(   6) =          0.16180000d0
      e(   7) =         68.53000000d0
      e(   8) =         19.02000000d0
      e(   9) =          6.19500000d0
      e(  10) =          1.95400000d0
c
500   do i = 1,3
       s(i) = 1.0d0
       p(i+3) = 1.0d0
      enddo
      do i = 7,10
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine crenbl_3(e,s,p,d,n)
c
c     ----- ECP Christiansen et al. Large Orbital Basis, Small Core Pot --
c     ----- basis (Rb-Xe) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
c
      nn = n-36
      go to (100,120,140,160,180,200,220,240,260,280,300,320,
     +       340,360,380,400,420,440),nn
c
c rb   
c
  100 continue
c
      e(   1) =          1.38500000d0
      e(   2) =          0.98590000d0
      e(   3) =          0.28220000d0
      e(   4) =          0.03220000d0
      e(   5) =          0.01625000d0
      e(   6) =          3.07000000d0
      e(   7) =          0.61190000d0
      e(   8) =          0.21250000d0
      e(   9) =          0.03190000d0
      e(  10) =          0.01240000d0
c
      go to 110
c
c sr   
c
  120 continue
c
      e(   1) =          1.55300000d0
      e(   2) =          1.07100000d0
      e(   3) =          0.33440000d0
      e(   4) =          0.05818000d0
      e(   5) =          0.02567000d0
      e(   6) =          3.00400000d0
      e(   7) =          0.74180000d0
      e(   8) =          0.28010000d0
      e(   9) =          0.05700000d0
      e(  10) =          0.02220000d0
c
  110 do i = 1,5
       s(i) = 1.0d0
       p(i+5) = 1.0d0
      enddo
c
      return
c
c y   
c
  140 continue
c
      e(   1) =          2.06300000d0
      e(   2) =          0.73470000d0
      e(   3) =          0.29670000d0
      e(   4) =          0.08233000d0
      e(   5) =          0.03142000d0
      e(   6) =          3.56400000d0
      e(   7) =          0.79570000d0
      e(   8) =          0.30220000d0
      e(   9) =          0.06290000d0
      e(  10) =          0.02230000d0
      e(  11) =          1.36200000d0
      e(  12) =          0.60110000d0
      e(  13) =          0.20890000d0
      e(  14) =          0.06851000d0
c
      go to 330
c
c zr   
c
  160 continue
c
      e(   1) =          1.85400000d0
      e(   2) =          1.16400000d0
      e(   3) =          0.38780000d0
      e(   4) =          0.08328000d0
      e(   5) =          0.03336000d0
      e(   6) =          3.50600000d0
      e(   7) =          0.90090000d0
      e(   8) =          0.33460000d0
      e(   9) =          0.07240000d0
      e(  10) =          0.02430000d0
      e(  11) =          1.59000000d0
      e(  12) =          0.77960000d0
      e(  13) =          0.29550000d0
      e(  14) =          0.09587000d0
c
      go to 330
c
c nb   
c
  180 continue
c
      e(   1) =          1.98600000d0
      e(   2) =          1.35400000d0
      e(   3) =          0.43850000d0
      e(   4) =          0.08841000d0
      e(   5) =          0.03613000d0
      e(   6) =          3.98600000d0
      e(   7) =          1.01300000d0
      e(   8) =          0.38010000d0
      e(   9) =          0.07520000d0
      e(  10) =          0.02470000d0
      e(  11) =          1.61000000d0
      e(  12) =          0.86070000d0
      e(  13) =          0.33560000d0
      e(  14) =          0.10840000d0
c
      go to 330
c
c mo   
c
  200 continue
c
      e(   1) =          2.43000000d0
      e(   2) =          1.14500000d0
      e(   3) =          0.41340000d0
      e(   4) =          0.08971000d0
      e(   5) =          0.03741000d0
      e(   6) =          4.48300000d0
      e(   7) =          1.09500000d0
      e(   8) =          0.41200000d0
      e(   9) =          0.07800000d0
      e(  10) =          0.02470000d0
      e(  11) =          1.86600000d0
      e(  12) =          0.97590000d0
      e(  13) =          0.38420000d0
      e(  14) =          0.12700000d0
c
      go to 330
c
c tc   
c
  220 continue
c
      e(   1) =          2.89700000d0
      e(   2) =          1.14100000d0
      e(   3) =          0.48140000d0
      e(   4) =          0.10790000d0
      e(   5) =          0.03908000d0
      e(   6) =          4.32100000d0
      e(   7) =          1.22900000d0
      e(   8) =          0.47000000d0
      e(   9) =          0.08950000d0
      e(  10) =          0.02460000d0
      e(  11) =          2.16900000d0
      e(  12) =          1.11800000d0
      e(  13) =          0.46660000d0
      e(  14) =          0.16750000d0
c
      go to 330
c
c ru   
c
  240 continue
c
      e(   1) =          2.93200000d0
      e(   2) =          1.21100000d0
      e(   3) =          0.42430000d0
      e(   4) =          0.11010000d0
      e(   5) =          0.03952000d0
      e(   6) =          4.94400000d0
      e(   7) =          1.30600000d0
      e(   8) =          0.48910000d0
      e(   9) =          0.08300000d0
      e(  10) =          0.02500000d0
      e(  11) =          2.28500000d0
      e(  12) =          1.25900000d0
      e(  13) =          0.50120000d0
      e(  14) =          0.16350000d0
c
      go to 330
c
c rh   
c
  260 continue
c
      e(   1) =          3.05000000d0
      e(   2) =          1.36800000d0
      e(   3) =          0.48750000d0
      e(   4) =          0.10250000d0
      e(   5) =          0.03710000d0
      e(   6) =          5.23500000d0
      e(   7) =          1.48800000d0
      e(   8) =          0.56550000d0
      e(   9) =          0.08690000d0
      e(  10) =          0.02570000d0
      e(  11) =          2.91600000d0
      e(  12) =          1.54800000d0
      e(  13) =          0.60700000d0
      e(  14) =          0.19550000d0
c
      go to 330
c
c pd   
c
  280 continue
c
      e(   1) =          3.31700000d0
      e(   2) =          1.43300000d0
      e(   3) =          0.50580000d0
      e(   4) =          0.11860000d0
      e(   5) =          0.04140000d0
      e(   6) =          5.08500000d0
      e(   7) =          1.56000000d0
      e(   8) =          0.58040000d0
      e(   9) =          0.08990000d0
      e(  10) =          0.02620000d0
      e(  11) =          2.79300000d0
      e(  12) =          1.55300000d0
      e(  13) =          0.62200000d0
      e(  14) =          0.20380000d0
c
      go to 330
c
c ag   
c
  300 continue
c
      e(   1) =          2.75500000d0
      e(   2) =          2.28300000d0
      e(   3) =          0.66540000d0
      e(   4) =          0.10150000d0
      e(   5) =          0.03656000d0
      e(   6) =          5.59400000d0
      e(   7) =          1.68300000d0
      e(   8) =          0.61770000d0
      e(   9) =          0.08330000d0
      e(  10) =          0.02520000d0
      e(  11) =          2.65100000d0
      e(  12) =          1.45700000d0
      e(  13) =          0.65170000d0
      e(  14) =          0.22100000d0
c
      go to 330
c
c cd   
c
  320 continue
c
      e(   1) =          3.41600000d0
      e(   2) =          1.93400000d0
      e(   3) =          0.62380000d0
      e(   4) =          0.13970000d0
      e(   5) =          0.04756000d0
      e(   6) =          6.08500000d0
      e(   7) =          1.85400000d0
      e(   8) =          0.77710000d0
      e(   9) =          0.12870000d0
      e(  10) =          0.04050000d0
      e(  11) =          3.09800000d0
      e(  12) =          1.56800000d0
      e(  13) =          0.67160000d0
      e(  14) =          0.24270000d0
c
  330 do i = 1,5
       s(i) = 1.0d0
       p(i+5) = 1.0d0
      enddo
      do i = 1,4
       d(i+10)= 1.0d0
      enddo
      return
c
c in  
c
  340 continue
c
      e(   1) =          0.53320000d0
      e(   2) =          0.27760000d0
      e(   3) =          0.07460000d0
      e(   4) =          0.90110000d0
      e(   5) =          0.15350000d0
      e(   6) =          0.04720000d0
      e(   7) =          2.88400000d0
      e(   8) =          1.25900000d0
      e(   9) =          0.53760000d0
      e(  10) =          0.21290000d0
c
      go to 500
c
c sn  
c 
  360 continue
c
      e(   1) =          0.55410000d0
      e(   2) =          0.35840000d0
      e(   3) =          0.09380000d0
      e(   4) =          0.92700000d0
      e(   5) =          0.19670000d0
      e(   6) =          0.06420000d0
      e(   7) =          3.12000000d0
      e(   8) =          1.38640000d0
      e(   9) =          0.60530000d0
      e(  10) =          0.24230000d0
c
      go to 500
c
c sb  
c 
  380 continue
c
      e(   1) =          0.55980000d0
      e(   2) =          0.44230000d0
      e(   3) =          0.11210000d0
      e(   4) =          0.99760000d0
      e(   5) =          0.24050000d0
      e(   6) =          0.08140000d0
      e(   7) =          3.52130000d0
      e(   8) =          1.67910000d0
      e(   9) =          0.77810000d0
      e(  10) =          0.31870000d0
c
      go to 500
c
c te  
c
  400 continue
c
      e(   1) =          0.63870000d0
      e(   2) =          0.46690000d0
      e(   3) =          0.12640000d0
      e(   4) =          1.07950000d0
      e(   5) =          0.30840000d0
      e(   6) =          0.10330000d0
      e(   7) =          3.78790000d0
      e(   8) =          2.45770000d0
      e(   9) =          1.20710000d0
      e(  10) =          0.47070000d0
c
      go to 500
c
c i  
c 
  420 continue
c
      e(   1) =          0.68030000d0
      e(   2) =          0.52080000d0
      e(   3) =          0.11430000d0
      e(   4) =          1.12500000d0
      e(   5) =          0.35080000d0
      e(   6) =          0.11660000d0
      e(   7) =          3.95020000d0
      e(   8) =          2.57420000d0
      e(   9) =          1.30710000d0
      e(  10) =          0.51160000d0
c
      go to 500
c
c xe  
c
  440 continue
c
      e(   1) =          0.71270000d0
      e(   2) =          0.57190000d0
      e(   3) =          0.15190000d0
      e(   4) =          1.23530000d0
      e(   5) =          0.37260000d0
      e(   6) =          0.12290000d0
      e(   7) =          4.51190000d0
      e(   8) =          2.47990000d0
      e(   9) =          1.29830000d0
      e(  10) =          0.54350000d0
c
500   do i = 1,3
       s(i) = 1.0d0
       p(i+3) = 1.0d0
      enddo
      do i = 7,10
       d(i) = 1.0d0
      enddo
      return
      end
      subroutine crenbl_4(e,s,p,d,f,n)
c
c     ----- ECP Christiansen et al. Large Orbital Basis, Small Core Pot --
c     ----- ECP basis (Cs-Xe) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-54
      go to (100,120,140,
     +       160,180,200,220,240,260,280,300,320,340,360,380,400,420,
     +       440,460,480,500,520,540,560,580,600,620,640,660,680,700,
     +       720),nn
c
c cs   
c
  100 continue
c
      e(   1) =          0.84330000d0
      e(   2) =          0.56550000d0
      e(   3) =          0.17660000d0
      e(   4) =          0.03270000d0
      e(   5) =          0.01670000d0
      e(   6) =          1.46400000d0
      e(   7) =          0.42310000d0
      e(   8) =          0.15600000d0
      e(   9) =          0.02790000d0
      e(  10) =          0.01130000d0
      e(  11) =          1.61500000d0
      e(  12) =          0.45470000d0
      e(  13) =          0.16900000d0
      e(  14) =          0.03070000d0
c
      go to 150
c
c ba   
c
  120 continue
c
      e(   1) =          0.82920000d0
      e(   2) =          0.68450000d0
      e(   3) =          0.19490000d0
      e(   4) =          0.06810000d0
      e(   5) =          0.02580000d0
      e(   6) =          1.44800000d0
      e(   7) =          0.50360000d0
      e(   8) =          0.19810000d0
      e(   9) =          0.04760000d0
      e(  10) =          0.01930000d0
      e(  11) =          1.76600000d0
      e(  12) =          0.52690000d0
      e(  13) =          0.20000000d0
      e(  14) =          0.05270000d0
c
      go to 150
c
c la   
c
  140 continue
c
      e(   1) =          0.89370000d0
      e(   2) =          0.73190000d0
      e(   3) =          0.21380000d0
      e(   4) =          0.06420000d0
      e(   5) =          0.02790000d0
      e(   6) =          1.56600000d0
      e(   7) =          0.56980000d0
      e(   8) =          0.21990000d0
      e(   9) =          0.04030000d0
      e(  10) =          0.01790000d0
      e(  11) =          1.90000000d0
      e(  12) =          0.44330000d0
      e(  13) =          0.16250000d0
      e(  14) =          0.05550000d0
c
150   do i = 1,5
       s(i) = 1.0d0
       p(i+5) = 1.0d0
      enddo
      do i = 11,14
       d(i) = 1.0d0
      enddo
c
      return
c
c ce   
c
  160 continue
c
      e(   1) =          0.90180000d0
      e(   2) =          0.35580000d0
      e(   3) =          0.25800000d0
      e(   4) =          0.06719000d0
      e(   5) =          0.03169000d0
      e(   6) =          0.01471000d0
      e(   7) =          1.85400000d0
      e(   8) =          0.20730000d0
      e(   9) =          0.12290000d0
      e(  10) =          0.05814000d0
      e(  11) =          0.02833000d0
      e(  12) =          0.01234000d0
      e(  13) =          3.67900000d0
      e(  14) =          0.53400000d0
      e(  15) =          0.24630000d0
      e(  16) =          0.12810000d0
      e(  17) =          0.06433000d0
      e(  18) =          0.02956000d0
      e(  19) =         54.74000000d0
      e(  20) =         18.24000000d0
      e(  21) =          6.95600000d0
      e(  22) =          2.79300000d0
      e(  23) =          1.06800000d0
      e(  24) =          0.34990000d0
c
      go to 430
c
c pr   
c
  180 continue
c
      e(   1) =          2.56800000d0
      e(   2) =          0.35170000d0
      e(   3) =          0.30360000d0
      e(   4) =          0.05512000d0
      e(   5) =          0.02796000d0
      e(   6) =          0.01450000d0
      e(   7) =          0.95550000d0
      e(   8) =          0.62620000d0
      e(   9) =          0.43200000d0
      e(  10) =          0.08774000d0
      e(  11) =          0.03315000d0
      e(  12) =          0.02096000d0
      e(  13) =          4.45900000d0
      e(  14) =          0.55700000d0
      e(  15) =          0.25960000d0
      e(  16) =          0.13620000d0
      e(  17) =          0.06557000d0
      e(  18) =          0.02857000d0
      e(  19) =         59.55000000d0
      e(  20) =         18.27000000d0
      e(  21) =          7.22300000d0
      e(  22) =          2.82900000d0
      e(  23) =          1.05000000d0
      e(  24) =          0.33900000d0
c

      go to 430
c
c nd   
c
  200 continue
c
      e(   1) =          2.52900000d0
      e(   2) =          0.37660000d0
      e(   3) =          0.30730000d0
      e(   4) =          0.05592000d0
      e(   5) =          0.02781000d0
      e(   6) =          0.01434000d0
      e(   7) =          2.17000000d0
      e(   8) =          0.31920000d0
      e(   9) =          0.10090000d0
      e(  10) =          0.04985000d0
      e(  11) =          0.03010000d0
      e(  12) =          0.01197000d0
      e(  13) =          4.30300000d0
      e(  14) =          0.59020000d0
      e(  15) =          0.27410000d0
      e(  16) =          0.14250000d0
      e(  17) =          0.07009000d0
      e(  18) =          0.03173000d0
      e(  19) =         62.64000000d0
      e(  20) =         19.71000000d0
      e(  21) =          7.82500000d0
      e(  22) =          3.06200000d0
      e(  23) =          1.14300000d0
      e(  24) =          0.37110000d0
c
      go to 430
c
c pm   
c
  220 continue
c
      e(   1) =          2.34800000d0
      e(   2) =          0.37780000d0
      e(   3) =          0.30580000d0
      e(   4) =          0.05544000d0
      e(   5) =          0.02768000d0
      e(   6) =          0.01435000d0
      e(   7) =          2.41900000d0
      e(   8) =          0.30140000d0
      e(   9) =          0.10930000d0
      e(  10) =          0.04663000d0
      e(  11) =          0.01713000d0
      e(  12) =          0.00981500d0
      e(  13) =          4.26700000d0
      e(  14) =          0.63160000d0
      e(  15) =          0.29960000d0
      e(  16) =          0.15360000d0
      e(  17) =          0.07247000d0
      e(  18) =          0.03175000d0
      e(  19) =         70.81000000d0
      e(  20) =         23.13000000d0
      e(  21) =          9.19600000d0
      e(  22) =          3.64100000d0
      e(  23) =          1.40200000d0
      e(  24) =          0.47480000d0
c
      go to 430
c
c sm   
c
  240 continue
c
      e(   1) =         21.59000000d0
      e(   2) =          0.36920000d0
      e(   3) =          0.28620000d0
      e(   4) =          0.12210000d0
      e(   5) =          0.04462000d0
      e(   6) =          0.01936000d0
      e(   7) =          2.73300000d0
      e(   8) =          0.20530000d0
      e(   9) =          0.11910000d0
      e(  10) =          0.04837000d0
      e(  11) =          0.02887000d0
      e(  12) =          0.01654000d0
      e(  13) =          4.27300000d0
      e(  14) =          0.66480000d0
      e(  15) =          0.31310000d0
      e(  16) =          0.15850000d0
      e(  17) =          0.07558000d0
      e(  18) =          0.03381000d0
      e(  19) =         76.00000000d0
      e(  20) =         25.72000000d0
      e(  21) =         10.26000000d0
      e(  22) =          4.12900000d0
      e(  23) =          1.63000000d0
      e(  24) =          0.56880000d0
c
      go to 430
c
c eu   
c
  260 continue
c
      e(   1) =         16.48000000d0
      e(   2) =          0.40740000d0
      e(   3) =          0.28550000d0
      e(   4) =          0.12130000d0
      e(   5) =          0.04533000d0
      e(   6) =          0.01963000d0
      e(   7) =          2.81700000d0
      e(   8) =          0.21880000d0
      e(   9) =          0.11400000d0
      e(  10) =          0.04748000d0
      e(  11) =          0.02404000d0
      e(  12) =          0.01270000d0
      e(  13) =          4.82900000d0
      e(  14) =          0.68610000d0
      e(  15) =          0.32260000d0
      e(  16) =          0.16300000d0
      e(  17) =          0.07650000d0
      e(  18) =          0.03366000d0
      e(  19) =         74.34000000d0
      e(  20) =         24.39000000d0
      e(  21) =          9.65500000d0
      e(  22) =          3.78500000d0
      e(  23) =          1.42500000d0
      e(  24) =          0.46410000d0
c
      go to 430
c
c gd   
c
  280 continue
c
      e(   1) =         17.40000000d0
      e(   2) =          0.42150000d0
      e(   3) =          0.29460000d0
      e(   4) =          0.12370000d0
      e(   5) =          0.04647000d0
      e(   6) =          0.02004000d0
      e(   7) =          2.81300000d0
      e(   8) =          0.19740000d0
      e(   9) =          0.15040000d0
      e(  10) =          0.06406000d0
      e(  11) =          0.04367000d0
      e(  12) =          0.01991000d0
      e(  13) =          4.86200000d0
      e(  14) =          0.72360000d0
      e(  15) =          0.34260000d0
      e(  16) =          0.17020000d0
      e(  17) =          0.07855000d0
      e(  18) =          0.03428000d0
      e(  19) =         79.03000000d0
      e(  20) =         25.73000000d0
      e(  21) =         10.19000000d0
      e(  22) =          3.98600000d0
      e(  23) =          1.49300000d0
      e(  24) =          0.48160000d0
c
      go to 430
c
c tb   
c
  300 continue
c
      e(   1) =         17.55000000d0
      e(   2) =          0.65830000d0
      e(   3) =          0.25070000d0
      e(   4) =          0.13220000d0
      e(   5) =          0.04732000d0
      e(   6) =          0.02214000d0
      e(   7) =          2.79600000d0
      e(   8) =          0.20430000d0
      e(   9) =          0.15030000d0
      e(  10) =          0.06517000d0
      e(  11) =          0.04199000d0
      e(  12) =          0.01956000d0
      e(  13) =          4.99700000d0
      e(  14) =          0.75260000d0
      e(  15) =          0.34700000d0
      e(  16) =          0.17210000d0
      e(  17) =          0.08111000d0
      e(  18) =          0.03603000d0
      e(  19) =         85.79000000d0
      e(  20) =         27.76000000d0
      e(  21) =         10.98000000d0
      e(  22) =          4.27900000d0
      e(  23) =          1.59200000d0
      e(  24) =          0.50630000d0
c
      go to 430
c
c dy   
c
  320 continue
c
      e(   1) =         14.89000000d0
      e(   2) =          0.80040000d0
      e(   3) =          0.24640000d0
      e(   4) =          0.13240000d0
      e(   5) =          0.04720000d0
      e(   6) =          0.02296000d0
      e(   7) =          4.85700000d0
      e(   8) =          0.23860000d0
      e(   9) =          0.17590000d0
      e(  10) =          0.07296000d0
      e(  11) =          0.02989000d0
      e(  12) =          0.00750000d0
      e(  13) =          5.93000000d0
      e(  14) =          0.81840000d0
      e(  15) =          0.39380000d0
      e(  16) =          0.18620000d0
      e(  17) =          0.07982000d0
      e(  18) =          0.02956000d0
      e(  19) =         91.06000000d0
      e(  20) =         30.88000000d0
      e(  21) =         11.79000000d0
      e(  22) =          4.58100000d0
      e(  23) =          1.70200000d0
      e(  24) =          0.53750000d0
c
      go to 430
c
c ho   
c
  340 continue
c
      e(   1) =         11.07000000d0
      e(   2) =          0.43290000d0
      e(   3) =          0.34060000d0
      e(   4) =          0.14360000d0
      e(   5) =          0.04786000d0
      e(   6) =          0.01916000d0
      e(   7) =          2.58400000d0
      e(   8) =          0.52000000d0
      e(   9) =          0.20190000d0
      e(  10) =          0.07589000d0
      e(  11) =          0.02706000d0
      e(  12) =          0.00719800d0
      e(  13) =          5.36800000d0
      e(  14) =          0.89220000d0
      e(  15) =          0.39190000d0
      e(  16) =          0.18630000d0
      e(  17) =          0.08271000d0
      e(  18) =          0.03054000d0
      e(  19) =        101.60000000d0
      e(  20) =         34.38000000d0
      e(  21) =         12.94000000d0
      e(  22) =          5.04100000d0
      e(  23) =          1.87500000d0
      e(  24) =          0.58960000d0
c
      go to 430
c
c er   
c
  360 continue
c
      e(   1) =         18.09000000d0
      e(   2) =          0.51560000d0
      e(   3) =          0.35220000d0
      e(   4) =          0.07469000d0
      e(   5) =          0.03487000d0
      e(   6) =          0.01633000d0
      e(   7) =          2.43700000d0
      e(   8) =          0.25130000d0
      e(   9) =          0.17990000d0
      e(  10) =          0.07137000d0
      e(  11) =          0.03459000d0
      e(  12) =          0.01659000d0
      e(  13) =          6.33100000d0
      e(  14) =          0.84500000d0
      e(  15) =          0.38220000d0
      e(  16) =          0.18070000d0
      e(  17) =          0.08295000d0
      e(  18) =          0.03614000d0
      e(  19) =        104.50000000d0
      e(  20) =         35.88000000d0
      e(  21) =         13.55000000d0
      e(  22) =          5.32600000d0
      e(  23) =          1.97900000d0
      e(  24) =          0.61870000d0
c
      go to 430
c
c tm   
c
  380 continue
c
      e(   1) =         13.25000000d0
      e(   2) =          0.53500000d0
      e(   3) =          0.36770000d0
      e(   4) =          0.07395000d0
      e(   5) =          0.03456000d0
      e(   6) =          0.01659000d0
      e(   7) =          2.40400000d0
      e(   8) =          0.25810000d0
      e(   9) =          0.18400000d0
      e(  10) =          0.07136000d0
      e(  11) =          0.03456000d0
      e(  12) =          0.01635000d0
      e(  13) =          6.48400000d0
      e(  14) =          0.87410000d0
      e(  15) =          0.38260000d0
      e(  16) =          0.17970000d0
      e(  17) =          0.08604000d0
      e(  18) =          0.03834000d0
      e(  19) =        106.50000000d0
      e(  20) =         35.69000000d0
      e(  21) =         13.54000000d0
      e(  22) =          5.29900000d0
      e(  23) =          1.97000000d0
      e(  24) =          0.61620000d0
c
      go to 430
c
c yb   
c
  400 continue
c
      e(   1) =         15.01000000d0
      e(   2) =          0.47270000d0
      e(   3) =          0.39080000d0
      e(   4) =          0.11310000d0
      e(   5) =          0.04367000d0
      e(   6) =          0.01503000d0
      e(   7) =          1.42500000d0
      e(   8) =          0.29920000d0
      e(   9) =          0.22780000d0
      e(  10) =          0.08319000d0
      e(  11) =          0.02904000d0
      e(  12) =          0.07290000d0
      e(  13) =          7.00500000d0
      e(  14) =          0.96560000d0
      e(  15) =          0.43480000d0
      e(  16) =          0.17820000d0
      e(  17) =          0.08966000d0
      e(  18) =          0.02975000d0
      e(  19) =        125.50000000d0
      e(  20) =         40.55000000d0
      e(  21) =         14.98000000d0
      e(  22) =          5.86000000d0
      e(  23) =          2.16900000d0
      e(  24) =          0.67220000d0
c
      go to 430
c
c lu   
c
  420 continue
c
      e(   1) =          5.40600000d0
      e(   2) =          0.58690000d0
      e(   3) =          0.48030000d0
      e(   4) =          0.08701000d0
      e(   5) =          0.04189000d0
      e(   6) =          0.01926000d0
      e(   7) =          1.13200000d0
      e(   8) =          0.66400000d0
      e(   9) =          0.36200000d0
      e(  10) =          0.10920000d0
      e(  11) =          0.04826000d0
      e(  12) =          0.02062000d0
      e(  13) =          9.17700000d0
      e(  14) =          0.89220000d0
      e(  15) =          0.39190000d0
      e(  16) =          0.18630000d0
      e(  17) =          0.08271000d0
      e(  18) =          0.03416000d0
      e(  19) =        120.70000000d0
      e(  20) =         40.23000000d0
      e(  21) =         15.34000000d0
      e(  22) =          6.16100000d0
      e(  23) =          2.35700000d0
      e(  24) =          0.77180000d0
c
  430 do i = 1,6
       s(i) = 1.0d0
       p(i+6) = 1.0d0
       d(i+12) = 1.0d0
       f(i+18) = 1.0d0
      enddo
c
      return
c
c hf   
c
  440 continue
c
      e(   1) =          2.55500000d0
      e(   2) =          0.70100000d0
      e(   3) =          0.44100000d0
      e(   4) =          0.09360000d0
      e(   5) =          0.03580000d0
      e(   6) =          2.60860000d0
      e(   7) =          1.51410000d0
      e(   8) =          0.62900000d0
      e(   9) =          0.27840000d0
      e(  10) =          0.09998000d0
      e(  11) =          0.89160000d0
      e(  12) =          0.34700000d0
      e(  13) =          0.13920000d0
      e(  14) =          0.05467000d0
c
      go to 610
c
c ta   
c
  460 continue
c
      e(   1) =          5.27400000d0
      e(   2) =          3.20250000d0
      e(   3) =          1.37970000d0
      e(   4) =          0.54540000d0
      e(   5) =          0.06560000d0
      e(   6) =          2.63520000d0
      e(   7) =          1.87510000d0
      e(   8) =          0.77220000d0
      e(   9) =          0.37490000d0
      e(  10) =          0.15850000d0
      e(  11) =          0.93570000d0
      e(  12) =          0.36640000d0
      e(  13) =          0.15050000d0
      e(  14) =          0.06150000d0
c
      go to 610
c
c w   
c
  480 continue
c
      e(   1) =          2.85330000d0
      e(   2) =          0.90670000d0
      e(   3) =          0.28150000d0
      e(   4) =          0.11020000d0
      e(   5) =          0.03969000d0
      e(   6) =          3.00850000d0
      e(   7) =          1.72650000d0
      e(   8) =          0.73640000d0
      e(   9) =          0.31890000d0
      e(  10) =          0.09046000d0
      e(  11) =          1.01700000d0
      e(  12) =          0.40260000d0
      e(  13) =          0.16320000d0
      e(  14) =          0.06538000d0
c
      go to 610
c
c re   
c
  500 continue
c
      e(   1) =          2.67600000d0
      e(   2) =          1.11000000d0
      e(   3) =          0.64290000d0
      e(   4) =          0.11730000d0
      e(   5) =          0.04592000d0
      e(   6) =          3.14170000d0
      e(   7) =          1.93600000d0
      e(   8) =          0.82830000d0
      e(   9) =          0.37950000d0
      e(  10) =          0.14760000d0
      e(  11) =          1.06230000d0
      e(  12) =          0.41470000d0
      e(  13) =          0.16730000d0
      e(  14) =          0.06771000d0
c
      go to 610
c
c os   
c
  520 continue
c
      e(   1) =          2.21730000d0
      e(   2) =          1.48110000d0
      e(   3) =          0.30640000d0
      e(   4) =          0.14040000d0
      e(   5) =          0.04833000d0
      e(   6) =          3.90400000d0
      e(   7) =          1.46830000d0
      e(   8) =          0.68010000d0
      e(   9) =          0.30740000d0
      e(  10) =          0.10630000d0
      e(  11) =          1.12130000d0
      e(  12) =          0.43060000d0
      e(  13) =          0.17040000d0
      e(  14) =          0.06810000d0
c
      go to 610
c
c ir   
c
  540 continue
c
      e(   1) =          2.17940000d0
      e(   2) =          1.83650000d0
      e(   3) =          0.52210000d0
      e(   4) =          0.14620000d0
      e(   5) =          0.05139000d0
      e(   6) =          2.81170000d0
      e(   7) =          2.46140000d0
      e(   8) =          0.89010000d0
      e(   9) =          0.39200000d0
      e(  10) =          0.14470000d0
      e(  11) =          1.21500000d0
      e(  12) =          0.47250000d0
      e(  13) =          0.18760000d0
      e(  14) =          0.07457000d0
c
      go to 610
c
c pt   
c
  560 continue
c
      e(   1) =          2.36540000d0
      e(   2) =          1.80450000d0
      e(   3) =          0.50830000d0
      e(   4) =          0.14840000d0
      e(   5) =          0.05148000d0
      e(   6) =          3.37220000d0
      e(   7) =          2.53280000d0
      e(   8) =          1.27400000d0
      e(   9) =          0.62380000d0
      e(  10) =          0.22100000d0
      e(  11) =          1.44630000d0
      e(  12) =          0.88980000d0
      e(  13) =          0.33870000d0
      e(  14) =          0.13200000d0
c
      go to 610
c
c au   
c
  580 continue
c
      e(   1) =          2.46510000d0
      e(   2) =          1.94310000d0
      e(   3) =          0.56130000d0
      e(   4) =          0.14520000d0
      e(   5) =          0.05039000d0
      e(   6) =          3.53060000d0
      e(   7) =          2.61220000d0
      e(   8) =          0.98130000d0
      e(   9) =          0.42660000d0
      e(  10) =          0.14750000d0
      e(  11) =          1.33660000d0
      e(  12) =          0.50350000d0
      e(  13) =          0.19400000d0
      e(  14) =          0.07560000d0
c
      go to 610
c
c hg   
c
  600 continue
c
      e(   1) =          2.49570000d0
      e(   2) =          2.06650000d0
      e(   3) =          0.55530000d0
      e(   4) =          0.17360000d0
      e(   5) =          0.05873000d0
      e(   6) =          3.71970000d0
      e(   7) =          2.48060000d0
      e(   8) =          1.02190000d0
      e(   9) =          0.45140000d0
      e(  10) =          0.15580000d0
      e(  11) =          1.44190000d0
      e(  12) =          0.55540000d0
      e(  13) =          0.21630000d0
      e(  14) =          0.08224000d0
c
 610  continue
      do i = 1,5
       s(i) = 1.0d0
       p(i+5) = 1.0d0
      enddo
      do i = 1,4
       d(i+10) = 1.0d0
      enddo
c
      return
c
c tl  
c
  620 call caserr2('CRENBL ecp basis set unavailable')
c
      go to 800
c
c pb  
c 
  640 continue
c
      e(   1) =          0.59200000d0
      e(   2) =          0.30280000d0
      e(   3) =          0.09220000d0
      e(   4) =          0.75640000d0
      e(   5) =          0.18760000d0
      e(   6) =          0.06100000d0
      e(   7) =          1.58880000d0
      e(   8) =          0.61370000d0
      e(   9) =          0.23390000d0
      e(  10) =          0.06550000d0
c
      go to 800
c
c bi  
c 
  660 continue
c
      e(   1) =          0.70020000d0
      e(   2) =          0.31190000d0
      e(   3) =          0.11030000d0
      e(   4) =          0.88010000d0
      e(   5) =          0.22070000d0
      e(   6) =          0.07540000d0
      e(   7) =          1.69090000d0
      e(   8) =          0.66360000d0
      e(   9) =          0.25290000d0
      e(  10) =          0.06410000d0
c
      go to 800
c
c po  
c
  680 continue
c
      e(   1) =          0.66580000d0
      e(   2) =          0.36960000d0
      e(   3) =          0.11460000d0
      e(   4) =          0.91720000d0
      e(   5) =          0.26710000d0
      e(   6) =          0.08730000d0
      e(   7) =          1.82130000d0
      e(   8) =          0.74400000d0
      e(   9) =          0.29110000d0
      e(  10) =          0.08100000d0
c
      go to 800
c
c at
c 
  700 continue
c
      e(   1) =          0.71850000d0
      e(   2) =          0.35530000d0
      e(   3) =          0.12460000d0
      e(   4) =          0.92930000d0
      e(   5) =          0.26700000d0
      e(   6) =          0.08760000d0
      e(   7) =          1.81610000d0
      e(   8) =          0.73960000d0
      e(   9) =          0.28330000d0
      e(  10) =          0.08000000d0
c
      go to 800
c
c rn  
c
  720 continue
c
      e(   1) =          0.70220000d0
      e(   2) =          0.41150000d0
      e(   3) =          0.13400000d0
      e(   4) =          1.03690000d0
      e(   5) =          0.33080000d0
      e(   6) =          0.11080000d0
      e(   7) =          2.14760000d0
      e(   8) =          0.96660000d0
      e(   9) =          0.40880000d0
      e(  10) =          0.13020000d0
c
800   do i = 1,3
       s(i) = 1.0d0
       p(i+3) = 1.0d0
       d(i+6) = 1.0d0
      enddo
      d(10) = 1.0d0
c
      return
      end
      subroutine crenbl_5(e,s,p,d,f,n)
c
c     ----- ECP Christiansen et al. Large Orbital Basis, Small Core Pot --
c     ----- ECP basis (Fr-Lw) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-86
      go to (100,120,140,
     +   160,180,200,220,240,260,280,300,320,340,360,380,400,420),
     +   nn
c
c fr   
c
  100 continue
c
      e(   1) =          0.74750000d0
      e(   2) =          0.51330000d0
      e(   3) =          0.22200000d0
      e(   4) =          0.18000000d0
      e(   5) =          0.02260000d0
      e(   6) =          0.95030000d0
      e(   7) =          0.42370000d0
      e(   8) =          0.15670000d0
      e(   9) =          0.04250000d0
      e(  10) =          0.02490000d0
      e(  11) =          0.82200000d0
      e(  12) =          0.67840000d0
      e(  13) =          0.12890000d0
      e(  14) =          0.02470000d0
c
      go to 130
c
c ra   
c
  120 continue
c
      e(   1) =          0.85730000d0
      e(   2) =          0.54900000d0
      e(   3) =          0.19980000d0
      e(   4) =          0.16310000d0
      e(   5) =          0.02280000d0
      e(   6) =          1.15180000d0
      e(   7) =          0.42290000d0
      e(   8) =          0.16400000d0
      e(   9) =          0.04420000d0
      e(  10) =          0.01720000d0
      e(  11) =          1.61500000d0
      e(  12) =          0.45500000d0
      e(  13) =          0.16900000d0
      e(  14) =          0.03100000d0
c
  130 continue
      do i = 1,5
       s(i) = 1.0d0
       p(i+5) = 1.0d0
      enddo
      do i = 1,4
       d(i+10) = 1.0d0
      enddo
c
      return
c
c ac   
c
  140 continue
c
      e(   1) =          0.96360000d0
      e(   2) =          0.52660000d0
      e(   3) =          0.15130000d0
      e(   4) =          0.11940000d0
      e(   5) =          0.03570000d0
      e(   6) =          0.94020000d0
      e(   7) =          0.67560000d0
      e(   8) =          0.25850000d0
      e(   9) =          0.09060000d0
      e(  10) =          0.02890000d0
      e(  11) =          1.36670000d0
      e(  12) =          0.34220000d0
      e(  13) =          0.13290000d0
      e(  14) =          0.04630000d0
      e(  15) =          0.11100000d0
      e(  16) =          0.02390000d0
      e(  17) =          0.00800000d0
      e(  18) =          0.00320000d0
c
      go to 250
c
c th   
c
  160 continue
c
      e(   1) =          0.85590000d0
      e(   2) =          0.67880000d0
      e(   3) =          0.16870000d0
      e(   4) =          0.09870000d0
      e(   5) =          0.03310000d0
      e(   6) =          1.09550000d0
      e(   7) =          0.70350000d0
      e(   8) =          0.28390000d0
      e(   9) =          0.11660000d0
      e(  10) =          0.03510000d0
      e(  11) =          2.12320000d0
      e(  12) =          0.35070000d0
      e(  13) =          0.13510000d0
      e(  14) =          0.04950000d0
      e(  15) =          3.68710000d0
      e(  16) =          1.44050000d0
      e(  17) =          0.53340000d0
      e(  18) =          0.16960000d0
c
      go to 250
c
c pa   
c
  180 continue
c
      e(   1) =          0.96520000d0
      e(   2) =          0.60980000d0
      e(   3) =          0.16360000d0
      e(   4) =          0.08750000d0
      e(   5) =          0.03030000d0
      e(   6) =          1.18210000d0
      e(   7) =          0.73660000d0
      e(   8) =          0.29630000d0
      e(   9) =          0.12030000d0
      e(  10) =          0.03260000d0
      e(  11) =          1.70270000d0
      e(  12) =          0.37480000d0
      e(  13) =          0.14170000d0
      e(  14) =          0.05050000d0
      e(  15) =          3.91440000d0
      e(  16) =          1.54490000d0
      e(  17) =          0.57370000d0
      e(  18) =          0.18160000d0
c

      go to 250
c
c u   
c
  200 continue
c
      e(   1) =          0.99780000d0
      e(   2) =          0.72810000d0
      e(   3) =          0.21320000d0
      e(   4) =          0.10920000d0
      e(   5) =          0.03460000d0
      e(   6) =          1.42480000d0
      e(   7) =          0.64530000d0
      e(   8) =          0.27110000d0
      e(   9) =          0.10190000d0
      e(  10) =          0.03080000d0
      e(  11) =          2.15050000d0
      e(  12) =          0.38440000d0
      e(  13) =          0.14190000d0
      e(  14) =          0.04920000d0
      e(  15) =          4.37770000d0
      e(  16) =          1.79700000d0
      e(  17) =          0.70500000d0
      e(  18) =          0.24250000d0
c
      go to 250
c
c np   
c
  220 continue
c
      e(   1) =          1.00120000d0
      e(   2) =          0.76870000d0
      e(   3) =          0.20640000d0
      e(   4) =          0.09880000d0
      e(   5) =          0.03100000d0
      e(   6) =          1.49450000d0
      e(   7) =          0.68440000d0
      e(   8) =          0.29520000d0
      e(   9) =          0.12330000d0
      e(  10) =          0.03280000d0
      e(  11) =          2.78710000d0
      e(  12) =          0.39300000d0
      e(  13) =          0.14380000d0
      e(  14) =          0.05030000d0
      e(  15) =          4.36770000d0
      e(  16) =          1.77790000d0
      e(  17) =          0.68020000d0
      e(  18) =          0.22390000d0
c
      go to 250
c
c pu   
c
  240 continue
c
      e(   1) =          1.08170000d0
      e(   2) =          0.74570000d0
      e(   3) =          0.21150000d0
      e(   4) =          0.07740000d0
      e(   5) =          0.02940000d0
      e(   6) =          1.56110000d0
      e(   7) =          0.72420000d0
      e(   8) =          0.30810000d0
      e(   9) =          0.12670000d0
      e(  10) =          0.03400000d0
      e(  11) =          2.69030000d0
      e(  12) =          0.40880000d0
      e(  13) =          0.14340000d0
      e(  14) =          0.04780000d0
      e(  15) =          4.44950000d0
      e(  16) =          1.83340000d0
      e(  17) =          0.71270000d0
      e(  18) =          0.23950000d0
c
 250  do i = 1,5
       s(i) = 1.0d0
       p(i+5) = 1.0d0
      enddo
      do i = 1,4
       d(i+10) = 1.0d0
       f(i+14) = 1.0d0
      enddo
c
      return
c
c am   
c
  260 continue
c
      e(   1) =          0.04335880d0
      e(   2) =          0.01522670d0
      e(   3) =         11.51588900d0
      e(   4) =          1.95854460d0
      e(   5) =          1.32842980d0
      e(   6) =          0.52826690d0
      e(   7) =          0.15314740d0
      e(   8) =          0.05094990d0
      e(   9) =          5.37740340d0
      e(  10) =          2.42819570d0
      e(  11) =          1.12379420d0
      e(  12) =          0.49715580d0
      e(  13) =          0.19645350d0
c
      go to 430
c
c cm   
c
  280 continue
c
      e(   1) =          0.04263980d0
      e(   2) =          0.01540940d0
      e(   3) =         11.02652600d0
      e(   4) =          2.39198110d0
      e(   5) =          1.31993830d0
      e(   6) =          0.54607930d0
      e(   7) =          0.15739560d0
      e(   8) =          0.05221260d0
      e(   9) =          5.33984120d0
      e(  10) =          2.40378290d0
      e(  11) =          1.10193270d0
      e(  12) =          0.48262640d0
      e(  13) =          0.18792170d0
c
      go to 430
c
c bk   
c
  300 continue
c
      e(   1) =          0.04390840d0
      e(   2) =          0.01562090d0
      e(   3) =         16.75488400d0
      e(   4) =          2.29324010d0
      e(   5) =          1.25778310d0
      e(   6) =          0.52011910d0
      e(   7) =          0.15541460d0
      e(   8) =          0.05182450d0
      e(   9) =          5.70334440d0
      e(  10) =          2.57415690d0
      e(  11) =          1.17489840d0
      e(  12) =          0.51336950d0
      e(  13) =          0.20007850d0
c
      go to 430
c
c cf   
c
  320 continue
c
      e(   1) =          0.04826890d0
      e(   2) =          0.01630720d0
      e(   3) =         20.73390900d0
      e(   4) =          2.09370820d0
      e(   5) =          1.53630600d0
      e(   6) =          0.59543880d0
      e(   7) =          0.16920880d0
      e(   8) =          0.05543990d0
      e(   9) =          6.00470680d0
      e(  10) =          2.73251890d0
      e(  11) =          1.31022990d0
      e(  12) =          0.58337150d0
      e(  13) =          0.23152530d0
c
      go to 430
c
c es   
c
  340 continue
c
      e(   1) =          0.04899320d0
      e(   2) =          0.01672860d0
      e(   3) =         14.96070400d0
      e(   4) =          2.16427310d0
      e(   5) =          1.56404960d0
      e(   6) =          0.61089500d0
      e(   7) =          0.17462840d0
      e(   8) =          0.05696390d0
      e(   9) =          6.16992400d0
      e(  10) =          2.83612030d0
      e(  11) =          1.32270240d0
      e(  12) =          0.58624110d0
      e(  13) =          0.23481080d0
c
      go to 430
c
c fm   
c
  360 continue
c
      e(   1) =          0.04864470d0
      e(   2) =          0.01664780d0
      e(   3) =         14.37279300d0
      e(   4) =          2.62799100d0
      e(   5) =          1.55810720d0
      e(   6) =          0.63415630d0
      e(   7) =          0.17930110d0
      e(   8) =          0.05831330d0
      e(   9) =          6.33627440d0
      e(  10) =          2.89705110d0
      e(  11) =          1.35387540d0
      e(  12) =          0.59713380d0
      e(  13) =          0.23716210d0
c
      go to 430
c
c md   
c
  380 continue
c
      e(   1) =          0.05161830d0
      e(   2) =          0.01693650d0
      e(   3) =         22.02971900d0
      e(   4) =          2.16427310d0
      e(   5) =          1.56732490d0
      e(   6) =          0.61228550d0
      e(   7) =          0.17972460d0
      e(   8) =          0.05840550d0
      e(   9) =          6.85821970d0
      e(  10) =          3.14133220d0
      e(  11) =          1.44174340d0
      e(  12) =          0.63708280d0
      e(  13) =          0.25549650d0
c
      go to 430
c
c no   
c
  400 continue
c
      e(   1) =          0.05012060d0
      e(   2) =          0.01631360d0
      e(   3) =         20.27771100d0
      e(   4) =          2.14384330d0
      e(   5) =          1.80435260d0
      e(   6) =          0.66882830d0
      e(   7) =          0.19098420d0
      e(   8) =          0.06140980d0
      e(   9) =          7.37302060d0
      e(  10) =          3.22258130d0
      e(  11) =          1.39804020d0
      e(  12) =          0.61396710d0
      e(  13) =          0.24924950d0
c
      go to 430
c
c lw   
c
  420 continue
c
      e(   1) =          0.05639850d0
      e(   2) =          0.01875040d0
      e(   3) =         18.91717800d0
      e(   4) =          2.58309720d0
      e(   5) =          1.75575200d0
      e(   6) =          0.68543400d0
      e(   7) =          0.21870840d0
      e(   8) =          0.06977190d0
      e(   9) =          7.58039550d0
      e(  10) =          3.44526950d0
      e(  11) =          1.57154760d0
      e(  12) =          0.71214350d0
      e(  13) =          0.29802480d0
c
  430 do i = 1,2
       p(i) = 1.0d0
      enddo
      do i =3,8
       d(i) = 1.0d0
      enddo
      do i = 9,13
       f(i) = 1.0d0
      enddo
c
      return
      end

      subroutine shcrenbs(nucz,ipass,itype,igauss,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c   ******************************************************************
c  CRENBS ECP     -   Ermler and Co-workers Small Basis Sets for Use with
c                     Averaged Relativistic, Large Core ECPs
c  Elements     Contraction                             References
c  Sc - Co: (4s)             M.M. Hurley et al., J. Chem. Phys., 84, 6840 (1986)
c  Ni:      (4s)             L.A. LaJohn et al., J. CHEM. PHYS., 87, (1987) 2812.
c  Cu - Zn: (4s,5d)    -> [1s,1d]    M.M. Hurley et al., J. Chem. Phys., 84, 6840
c                                    (1986)
c  Y - Cd:  (3s,3p,4d) -> [1s,1p,1d] L.A. LaJohn et al., J. CHEM. PHYS., 87,
c                                    2812 (1987).
c
c  La, Hf-Hg: (3s,3p,4d)     R.B. Ross, W.C. Ermler, P.A. CHRISTIANSEN ET AL. J.
c                            CHEM. PHYS. 93,(1990)6654.
c  Ti - Rn: (3s,3p)
c  Rf - Uut:(0s,5p,6d)       C.S. NASH, B.E. BURSTEN, W.C. ERMLER, J. CHEM.
c                            PHYS. 1997
c  Uuq - Uuo: (0s,6p,6d)
c  ** e.g.  for copper only the 4s and 3d orbitals are included in the
c  valence space.
c  These ECPs are sometimes referred to as shape consistent because they
c  maintain the shape of the atomic orbitals in the valence region.
c   ******************************************************************
c
      dimension igau(3,3), itypes(3,3)
      dimension kind(3)
      data kind/2,3,2 /
      data igau /
     + 4,5,0,
     + 3,3,4,
     + 3,3,0  /
      data itypes /
     + 1,3,0,
     + 1,2,3,
     + 1,2,0/
c
c     set values for the current ccdz  shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3,4 for s,p,d,f shell
c
      ind=0
      if(nucz.ge.21  .and.  nucz.le.30) ind=1
      if(nucz.ge.39  .and.  nucz.le.48) ind=2
      if(nucz.eq.57) ind=2
      if(nucz.ge.72  .and.  nucz.le.80) ind=2
      if(nucz.ge.82  .and.  nucz.le.86) ind=3
      if(nucz.gt.86) then
         call caserr2(
     +          'CRENBS ecp basis sets only extend to radon')
      end if
      if(ind.eq.0) call caserr2('no available CRENBS ecp basis')
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if(.not.odone) then
c
       igauss = igau(ipass,ind)
       ityp = itypes(ipass,ind)
      endif
      itype = ityp + 15
c
      return
      end
      subroutine crenbs_2(e,s,p,d,n)
c
c     ----- ECP Christiansen et al. Large Orbital Basis, Small Core Pot --
c     ----- basis (K-Kr) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
c
      nn = n-18
      go to (100,100,140,160,180,200,220,240,260,280,300,320,
     +       100,100,100,100,100,100),nn
c
c k , ca, ga-kr
c
  100 call caserr2('no CRENBS ecp basis for requested element')
c
      go to 500
c
c sc   
c
  140 continue
c
      e(   1) =          1.12900000d0
      s(   1) =          0.03543000d0
      e(   2) =          0.45120000d0
      s(   2) =         -0.30247600d0
      e(   3) =          0.07760000d0
      s(   3) =          0.61180600d0
      e(   4) =          0.03027000d0
      s(   4) =          0.54308200d0
      e(   5) =         12.23000000d0
      d(   5) =          0.05311100d0
      e(   6) =          3.15100000d0
      d(   6) =          0.23367700d0
      e(   7) =          0.98740000d0
      d(   7) =          0.42576100d0
      e(   8) =          0.34820000d0
      d(   8) =          0.39811100d0
      e(   9) =          0.12560000d0
      d(   9) =          0.23948900d0
c
      go to 500
c
c ti   
c
  160 continue
      e(   1) =          1.28600000d0
      s(   1) =          0.03813500d0
      e(   2) =          0.52730000d0
      s(   2) =         -0.29565800d0
      e(   3) =          0.08545000d0
      s(   3) =          0.60358600d0
      e(   4) =          0.03290000d0
      s(   4) =          0.54414000d0
      e(   5) =         13.86000000d0
      d(   5) =          0.05937600d0
      e(   6) =          3.60000000d0
      d(   6) =          0.25702900d0
      e(   7) =          1.13800000d0
      d(   7) =          0.44254900d0
      e(   8) =          0.41390000d0
      d(   8) =          0.37713200d0
      e(   9) =          0.15170000d0
      d(   9) =          0.20711900d0
c
      go to 500
c
c v   
c
  180 continue
c
      e(   1) =          1.35100000d0
      s(   1) =          0.04311100d0
      e(   2) =          0.60080000d0
      s(   2) =         -0.28494600d0
      e(   3) =          0.09275000d0
      s(   3) =          0.59974400d0
      e(   4) =          0.03482000d0
      s(   4) =          0.54169300d0
      e(   5) =         16.49000000d0
      d(   5) =          0.05921000d0
      e(   6) =          4.29400000d0
      d(   6) =          0.26030800d0
      e(   7) =          1.35700000d0
      d(   7) =          0.45209800d0
      e(   8) =          0.48610000d0
      d(   8) =          0.37436300d0
      e(   9) =          0.18070000d0
      d(   9) =          0.19458100d0
      go to 500
c
c cr   
c
  200 continue
c
      e(   1) =          1.62900000d0
      s(   1) =          0.00619400d0
      e(   2) =          0.51240000d0
      s(   2) =         -0.27333600d0
      e(   3) =          0.10600000d0
      s(   3) =          0.60508300d0
      e(   4) =          0.03778000d0
      s(   4) =          0.56593200d0
      e(   5) =         18.64000000d0
      d(   5) =          0.06199100d0
      e(   6) =          4.94000000d0
      d(   6) =          0.26857400d0
      e(   7) =          1.58600000d0
      d(   7) =          0.45349900d0
      e(   8) =          0.58100000d0
      d(   8) =          0.36265900d0
      e(   9) =          0.21610000d0
      d(   9) =          0.19037900d0
c
      go to 500
c
c mn   
c
  220 continue
c
      e(   1) =          1.80500000d0
      s(   1) =          0.02795200d0
      e(   2) =          0.70010000d0
      s(   2) =         -0.26596900d0
      e(   3) =          0.11200000d0
      s(   3) =          0.56511400d0
      e(   4) =          0.04117000d0
      s(   4) =          0.57511500d0
      e(   5) =         21.54000000d0
      d(   5) =          0.06052700d0
      e(   6) =          5.67000000d0
      d(   6) =          0.26773100d0
      e(   7) =          1.83000000d0
      d(   7) =          0.44131600d0
      e(   8) =          0.68740000d0
      d(   8) =          0.36720100d0
      e(   9) =          0.24140000d0
      d(   9) =          0.20497400d0
c
      go to 500
c
c fe   
c
  240 continue
c
      e(   1) =          1.92100000d0
      s(   1) =          0.01646000d0
      e(   2) =          0.70000000d0
      s(   2) =         -0.26005700d0
      e(   3) =          0.11390000d0
      s(   3) =          0.64872900d0
      e(   4) =          0.04042000d0
      s(   4) =          0.49944400d0
      e(   5) =         24.08000000d0
      d(   5) =          0.06139600d0
      e(   6) =          6.37600000d0
      d(   6) =          0.27133300d0
      e(   7) =          2.03700000d0
      d(   7) =          0.44919400d0
      e(   8) =          0.75930000d0
      d(   8) =          0.34349500d0
      e(   9) =          0.29130000d0
      d(   9) =          0.21596000d0
c
      go to 500
c
c co   
c
  260 continue
c
      e(   1) =          2.01700000d0
      s(   1) =          0.06297300d0
      e(   2) =          0.73300000d0
      s(   2) =         -0.24703500d0
      e(   3) =          0.12020000d0
      s(   3) =          0.66722300d0
      e(   4) =          0.04171000d0
      s(   4) =          0.48040500d0
      e(   5) =         26.64000000d0
      d(   5) =          0.06297300d0
      e(   6) =          7.07100000d0
      d(   6) =          0.27619600d0
      e(   7) =          2.25100000d0
      d(   7) =          0.45451500d0
      e(   8) =          0.80390000d0
      d(   8) =          0.36131800d0
      e(   9) =          0.28570000d0
      d(   9) =          0.19493200d0
c
      go to 500
c
c ni   
c
  280 continue
c
      e(   1) =          2.36200000d0
      s(   1) =          0.01037600d0
      e(   2) =          0.80790000d0
      s(   2) =         -0.23838400d0
      e(   3) =          0.12750000d0
      s(   3) =          0.66522900d0
      e(   4) =          0.04398000d0
      s(   4) =          0.47746100d0
      e(   5) =         28.73000000d0
      d(   5) =          0.06520900d0
      e(   6) =          7.72600000d0
      d(   6) =          0.28056500d0
      e(   7) =          2.49600000d0
      d(   7) =          0.44350200d0
      e(   8) =          0.91660000d0
      d(   8) =          0.35962700d0
      e(   9) =          0.31050000d0
      d(   9) =          0.20531300d0
c
      go to 500
c
c cu   
c
  300 continue
c
      e(   1) =          2.44900000d0
      s(   1) =          0.01028000d0
      e(   2) =          0.85960000d0
      s(   2) =         -0.20028900d0
      e(   3) =          0.11920000d0
      s(   3) =          0.51294400d0
      e(   4) =          0.04177000d0
      s(   4) =          0.60231900d0
      e(   5) =         31.84000000d0
      d(   5) =          0.06276200d0
      e(   6) =          8.49800000d0
      d(   6) =          0.27301200d0
      e(   7) =          2.68400000d0
      d(   7) =          0.44320000d0
      e(   8) =          0.91080000d0
      d(   8) =          0.37137100d0
      e(   9) =          0.28900000d0
      d(   9) =          0.23152600d0
c
      go to 500
c
c zn   
c
  320 continue
c
      e(   1) =          2.79700000d0
      s(   1) =          0.01410800d0
      e(   2) =          0.99820000d0
      s(   2) =         -0.22949100d0
      e(   3) =          0.14540000d0
      s(   3) =          0.65598800d0
      e(   4) =          0.04622000d0
      s(   4) =          0.48434800d0
      e(   5) =         34.46000000d0
      d(   5) =          0.06662200d0
      e(   6) =          9.32500000d0
      d(   6) =          0.28625700d0
      e(   7) =          2.97600000d0
      d(   7) =          0.45795200d0
      e(   8) =          1.04400000d0
      d(   8) =          0.35473600d0
      e(   9) =          0.36660000d0
      d(   9) =          0.19023400d0
c
500   return
      end
      subroutine crenbs_3(e,s,p,d,n)
c
c     ----- ECP Christiansen et al. Large Orbital Basis, Small Core Pot --
c     ----- basis (Rb-Xe) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
c
      nn = n-36
      go to (100,100,140,160,180,200,220,240,260,280,300,320,
     +       100,100,100,100,100,100),nn
c
c rb, sr, in - xe
c
  100 call caserr2('no CRENBS ecp basis for requested element')
c
      go to 500
c
c y   
c
  140 continue
c
      e(   1) =          0.21240000d0
      s(   1) =         -0.78198400d0
      e(   2) =          0.12530000d0
      s(   2) =          0.84441000d0
      e(   3) =          0.03362000d0
      s(   3) =          0.80238000d0
      e(   4) =          0.28960000d0
      p(   4) =         -0.08992000d0
      e(   5) =          0.06290000d0
      p(   5) =          0.83167600d0
      e(   6) =          0.02230000d0
      p(   6) =          0.26287500d0
      e(   7) =          1.23300000d0
      d(   7) =          0.14273700d0
      e(   8) =          0.54610000d0
      d(   8) =          0.35404300d0
      e(   9) =          0.21020000d0
      d(   9) =          0.47422700d0
      e(  10) =          0.07050000d0
      d(  10) =          0.27932300d0
c
      go to 500
c
c zr   
c
  160 continue
c
      e(   1) =          0.25610000d0
      s(   1) =         -0.53008100d0
      e(   2) =          0.11240000d0
      s(   2) =          0.69292000d0
      e(   3) =          0.03449000d0
      s(   3) =          0.71382100d0
      e(   4) =          0.29720000d0
      p(   4) =         -0.09631800d0
      e(   5) =          0.07240000d0
      p(   5) =          0.75470400d0
      e(   6) =          0.02430000d0
      p(   6) =          0.36364800d0
      e(   7) =          1.60000000d0
      d(   7) =          0.09992500d0
      e(   8) =          0.77560000d0
      d(   8) =          0.35366600d0
      e(   9) =          0.29490000d0
      d(   9) =          0.50992000d0
      e(  10) =          0.09599000d0
      d(  10) =          0.26658300d0
c
      go to 500
c
c nb   
c
  180 continue
c
      e(   1) =          0.26720000d0
      s(   1) =         -0.87411500d0
      e(   2) =          0.17110000d0
      s(   2) =          0.91654600d0
      e(   3) =          0.04383000d0
      s(   3) =          0.82638700d0
      e(   4) =          0.41060000d0
      p(   4) =         -0.06437200d0
      e(   5) =          0.07520000d0
      p(   5) =          0.80415600d0
      e(   6) =          0.02470000d0
      p(   6) =          0.28645300d0
      e(   7) =          1.61300000d0
      d(   7) =          0.10756600d0
      e(   8) =          0.92650000d0
      d(   8) =          0.28128600d0
      e(   9) =          0.36100000d0
      d(   9) =          0.50122600d0
      e(  10) =          0.11210000d0
      d(  10) =          0.35185400d0
c
      go to 500
c
c mo   
c
  200 continue
c
      e(   1) =          0.28470000d0
      s(   1) =         -0.97570500d0
      e(   2) =          0.18890000d0
      s(   2) =          1.05963700d0
      e(   3) =          0.04582000d0
      s(   3) =          0.79466000d0
      e(   4) =          0.49950000d0
      p(   4) =         -0.06271600d0
      e(   5) =          0.07800000d0
      p(   5) =          0.79825200d0
      e(   6) =          0.02470000d0
      p(   6) =          0.29300000d0
      e(   7) =          2.14900000d0
      d(   7) =          0.06421200d0
      e(   8) =          1.09600000d0
      d(   8) =          0.36352900d0
      e(   9) =          0.38230000d0
      d(   9) =          0.53587500d0
      e(  10) =          0.11240000d0
      d(  10) =          0.27952700d0
c
      go to 500
c
c tc   
c
  220 continue
c
      e(   1) =          0.31520000d0
      s(   1) =         -0.73381000d0
      e(   2) =          0.18430000d0
      s(   2) =          0.81349400d0
      e(   3) =          0.04509000d0
      s(   3) =          0.80071900d0
      e(   4) =          0.47670000d0
      p(   4) =         -0.06596800d0
      e(   5) =          0.08950000d0
      p(   5) =          0.71730600d0
      e(   6) =          0.02460000d0
      p(   6) =          0.41109200d0
      e(   7) =          2.69600000d0
      d(   7) =          0.04646300d0
      e(   8) =          1.33000000d0
      d(   8) =          0.39936000d0
      e(   9) =          0.46900000d0
      d(   9) =          0.56266500d0
      e(  10) =          0.13600000d0
      d(  10) =          0.20579200d0
c
      go to 500
c
c ru   
c
  240 continue
c
      e(   1) =          0.39620000d0
      s(   1) =         -0.43325700d0
      e(   2) =          0.14940000d0
      s(   2) =          0.60713800d0
      e(   3) =          0.04368000d0
      s(   3) =          0.71376100d0
      e(   4) =          0.57250000d0
      p(   4) =         -0.05287700d0
      e(   5) =          0.08300000d0
      p(   5) =          0.82621600d0
      e(   6) =          0.02500000d0
      p(   6) =          0.26030900d0
      e(   7) =          2.65700000d0
      d(   7) =          0.05481000d0
      e(   8) =          1.43500000d0
      d(   8) =          0.37952800d0
      e(   9) =          0.49750000d0
      d(   9) =          0.54180900d0
      e(  10) =          0.14050000d0
      d(  10) =          0.26376500d0
c
      go to 500
c
c rh   
c
  260 continue
c
      e(   1) =          0.42910000d0
      s(   1) =         -0.40256500d0
      e(   2) =          0.15710000d0
      s(   2) =          0.53779300d0
      e(   3) =          0.04589000d0
      s(   3) =          0.75215700d0
      e(   4) =          0.65950000d0
      p(   4) =         -0.04329000d0
      e(   5) =          0.08690000d0
      p(   5) =          0.82177400d0
      e(   6) =          0.02570000d0
      p(   6) =          0.26305300d0
      e(   7) =          2.90000000d0
      d(   7) =          0.08959400d0
      e(   8) =          1.43500000d0
      d(   8) =          0.39399900d0
      e(   9) =          0.53400000d0
      d(   9) =          0.49809500d0
      e(  10) =          0.16380000d0
      d(  10) =          0.25273900d0
c
      go to 500
c
c pd   
c
  280 continue
c
      e(   1) =          0.45420000d0
      s(   1) =         -0.37049800d0
      e(   2) =          0.17200000d0
      s(   2) =          0.43729900d0
      e(   3) =          0.04840000d0
      s(   3) =          0.82380300d0
      e(   4) =          0.73680000d0
      p(   4) =         -0.02996400d0
      e(   5) =          0.08990000d0
      p(   5) =          0.35149300d0
      e(   6) =          0.02620000d0
      p(   6) =          0.74284300d0
      e(   7) =          2.32520000d0
      d(   7) =          0.27813200d0
      e(   8) =          1.00200000d0
      d(   8) =          0.43757600d0
      e(   9) =          0.40320000d0
      d(   9) =          0.36562300d0
      e(  10) =          0.14520000d0
      d(  10) =          0.15007200d0
c
      go to 500
c
c ag   
c
  300 continue
c
      e(   1) =          0.49810000d0
      s(   1) =         -0.32332200d0
      e(   2) =          0.15860000d0
      s(   2) =          0.42564500d0
      e(   3) =          0.04710000d0
      s(   3) =          0.79261400d0
      e(   4) =          0.75890000d0
      p(   4) =         -0.02853400d0
      e(   5) =          0.09080000d0
      p(   5) =          0.39044500d0
      e(   6) =          0.02830000d0
      p(   6) =          0.70070800d0
      e(   7) =          2.41270000d0
      d(   7) =          0.30885300d0
      e(   8) =          1.01530000d0
      d(   8) =          0.45043400d0
      e(   9) =          0.40930000d0
      d(   9) =          0.33831000d0
      e(  10) =          0.15030000d0
      d(  10) =          0.12944000d0
c
      go to 500
c
c cd   
c
  320 continue
c
      e(   1) =          0.49220000d0
      s(   1) =         -0.48078000d0
      e(   2) =          0.22730000d0
      s(   2) =          0.57237100d0
      e(   3) =          0.05970000d0
      s(   3) =          0.80074600d0
      e(   4) =          0.82700000d0
      p(   4) =         -0.04511700d0
      e(   5) =          0.11290000d0
      p(   5) =          0.58816500d0
      e(   6) =          0.04050000d0
      p(   6) =          0.49788600d0
      e(   7) =          2.48230000d0
      d(   7) =          0.36171900d0
      e(   8) =          1.01990000d0
      d(   8) =          0.46825900d0
      e(   9) =          0.41900000d0
      d(   9) =          0.29137300d0
      e(  10) =          0.16390000d0
      d(  10) =          0.08301300d0
c
500   return
      end
      subroutine crenbs_4(e,s,p,d,n)
c
c     ----- ECP Christiansen et al. Large Orbital Basis, Small Core Pot --
c     ----- ECP basis (Cs-Xe) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
c
      nn = n-54
      go to (100,100,140,
     +       100,100,100,100,100,100,100,100,100,100,100,100,100,100,
     +       440,460,480,500,520,540,560,580,600,100,640,660,680,700,
     +       720),nn
c
c cs, ba
c
  100 call caserr2('no CRENBS ecp basis for requested element')
c
      go to 800
c
c la   
c
  140 continue
c
      e(   1) =          0.21240000d0
      s(   1) =         -0.39630000d0
      e(   2) =          0.12530000d0
      s(   2) =          0.17750000d0
      e(   3) =          0.03360000d0
      s(   3) =          1.07130000d0
      e(   4) =          0.22360000d0
      p(   4) =         -0.14870000d0
      e(   5) =          0.06270000d0
      p(   5) =          0.60860000d0
      e(   6) =          0.02410000d0
      p(   6) =          0.52560000d0
      e(   7) =          0.44640000d0
      d(   7) =          0.39750000d0
      e(   8) =          0.17700000d0
      d(   8) =          0.47670000d0
      e(   9) =          0.07360000d0
      d(   9) =          0.26390000d0
      e(  10) =          0.03160000d0
      d(  10) =          0.05000000d0
c
      go to 800
c
c hf   
c
  440 continue
c
      e(   1) =          0.24200000d0
      s(   1) =         -1.72540000d0
      e(   2) =          0.19220000d0
      s(   2) =          1.77800000d0
      e(   3) =          0.04360000d0
      s(   3) =          0.81780000d0
      e(   4) =          0.43890000d0
      p(   4) =         -0.11340000d0
      e(   5) =          0.10450000d0
      p(   5) =          0.59430000d0
      e(   6) =          0.03701000d0
      p(   6) =          0.52800000d0
      e(   7) =          0.89770000d0
      d(   7) =          0.31860000d0
      e(   8) =          0.35160000d0
      d(   8) =          0.44650000d0
      e(   9) =          0.14130000d0
      d(   9) =          0.34540000d0
      e(  10) =          0.05500000d0
      d(  10) =          0.12280000d0
c
      go to 800
c
c ta   
c
  460 continue
c
      e(   1) =          0.26720000d0
      s(   1) =         -1.06550000d0
      e(   2) =          0.17110000d0
      s(   2) =          1.23980000d0
      e(   3) =          0.04260000d0
      s(   3) =          0.69830000d0
      e(   4) =          0.48770000d0
      p(   4) =         -0.10580000d0
      e(   5) =          0.11970000d0
      p(   5) =          0.58040000d0
      e(   6) =          0.04330000d0
      p(   6) =          0.53760000d0
      e(   7) =          0.93210000d0
      d(   7) =          0.36920000d0
      e(   8) =          0.36230000d0
      d(   8) =          0.46530000d0
      e(   9) =          0.14670000d0
      d(   9) =          0.29860000d0
      e(  10) =          0.05900000d0
      d(  10) =          0.08210000d0
c
      go to 800
c
c w   
c
  480 continue
c
      e(   1) =          0.28470000d0
      s(   1) =         -1.18810000d0
      e(   2) =          0.18890000d0
      s(   2) =          1.35590000d0
      e(   3) =          0.04580000d0
      s(   3) =          0.69920000d0
      e(   4) =          0.55790000d0
      p(   4) =         -0.10480000d0
      e(   5) =          0.12680000d0
      p(   5) =          0.61110000d0
      e(   6) =          0.04410000d0
      p(   6) =          0.50890000d0
      e(   7) =          1.00810000d0
      d(   7) =          0.39210000d0
      e(   8) =          0.39770000d0
      d(   8) =          0.46810000d0
      e(   9) =          0.16260000d0
      d(   9) =          0.27560000d0
      e(  10) =          0.06630000d0
      d(  10) =          0.06756000d0
c
      go to 800
c
c re   
c
  500 continue
c
      e(   1) =          0.35200000d0
      s(   1) =         -0.51270000d0
      e(   2) =          0.12100000d0
      s(   2) =          0.93560000d0
      e(   3) =          0.04070000d0
      s(   3) =          0.43960000d0
      e(   4) =          0.57170000d0
      p(   4) =         -0.10050000d0
      e(   5) =          0.13390000d0
      p(   5) =          0.60900000d0
      e(   6) =          0.04600000d0
      p(   6) =          0.51250000d0
      e(   7) =          1.06310000d0
      d(   7) =          0.42000000d0
      e(   8) =          0.41310000d0
      d(   8) =          0.47980000d0
      e(   9) =          0.16600000d0
      d(   9) =          0.23990000d0
      e(  10) =          0.06710000d0
      d(  10) =          0.04390000d0
c
      go to 800
c
c os   
c
  520 continue
c
      e(   1) =          0.39620000d0
      s(   1) =         -0.52820000d0
      e(   2) =          0.14940000d0
      s(   2) =          0.87930000d0
      e(   3) =          0.04360000d0
      s(   3) =          0.52740000d0
      e(   4) =          0.57550000d0
      p(   4) =         -0.09540000d0
      e(   5) =          0.12520000d0
      p(   5) =          0.69910000d0
      e(   6) =          0.04070000d0
      p(   6) =          0.42280000d0
      e(   7) =          1.12710000d0
      d(   7) =          0.44860000d0
      e(   8) =          0.43620000d0
      d(   8) =          0.47260000d0
      e(   9) =          0.17270000d0
      d(   9) =          0.23290000d0
      e(  10) =          0.06510000d0
      d(  10) =          0.03760000d0
c
      go to 800
c
c ir   
c
  540 continue
c
      e(   1) =          0.46290000d0
      s(   1) =         -0.45990000d0
      e(   2) =          0.15570000d0
      s(   2) =          0.80470000d0
      e(   3) =          0.04590000d0
      s(   3) =          0.53780000d0
      e(   4) =          0.63200000d0
      p(   4) =         -0.89730000d0
      e(   5) =          0.14330000d0
      p(   5) =          0.57900000d0
      e(   6) =          0.04640000d0
      p(   6) =          0.54490000d0
      e(   7) =          1.21160000d0
      d(   7) =          0.45940000d0
      e(   8) =          0.47200000d0
      d(   8) =          0.46660000d0
      e(   9) =          0.18860000d0
      d(   9) =          0.22330000d0
      e(  10) =          0.07620000d0
      d(  10) =          0.03930000d0
c
      go to 800
c
c pt   
c
  560 continue
c
      e(   1) =          0.40240000d0
      s(   1) =         -0.99690000d0
      e(   2) =          0.27040000d0
      s(   2) =          1.06100000d0
      e(   3) =          0.06120000d0
      s(   3) =          0.81170000d0
      e(   4) =          0.67510000d0
      p(   4) =         -0.04270000d0
      e(   5) =          0.09660000d0
      p(   5) =          0.47990000d0
      e(   6) =          0.02880000d0
      p(   6) =          0.63010000d0
      e(   7) =          1.27920000d0
      d(   7) =          0.46140000d0
      e(   8) =          0.48900000d0
      d(   8) =          0.45070000d0
      e(   9) =          0.19050000d0
      d(   9) =          0.23460000d0
      e(  10) =          0.07470000d0
      d(  10) =          0.05000000d0
c
      go to 800
c
c au   
c
  580 continue
c
      e(   1) =          0.44090000d0
      s(   1) =         -0.74780000d0
      e(   2) =          0.26260000d0
      s(   2) =          0.81760000d0
      e(   3) =          0.06170000d0
      s(   3) =          0.81130000d0
      e(   4) =          0.66420000d0
      p(   4) =         -0.04590000d0
      e(   5) =          0.10730000d0
      p(   5) =          0.37780000d0
      e(   6) =          0.03190000d0
      p(   6) =          0.72330000d0
      e(   7) =          1.35170000d0
      d(   7) =          0.47870000d0
      e(   8) =          0.51490000d0
      d(   8) =          0.45820000d0
      e(   9) =          0.19940000d0
      d(   9) =          0.22030000d0
      e(  10) =          0.07760000d0
      d(  10) =          0.04120000d0
c
      go to 800
c
c hg   
c
  600 continue
c
      e(   1) =          0.53710000d0
      s(   1) =         -0.52040000d0
      e(   2) =          0.22470000d0
      s(   2) =          0.70180000d0
      e(   3) =          0.06490000d0
      s(   3) =          0.69510000d0
      e(   4) =          0.72130000d0
      p(   4) =         -0.07130000d0
      e(   5) =          0.13050000d0
      p(   5) =          0.41890000d0
      e(   6) =          0.05120000d0
      p(   6) =          0.68050000d0
      e(   7) =          1.44180000d0
      d(   7) =         -0.50300000d0
      e(   8) =          0.55600000d0
      d(   8) =          0.46050000d0
      e(   9) =          0.21670000d0
      d(   9) =          0.19080000d0
      e(  10) =          0.08350000d0
      d(  10) =          0.02380000d0
c
      go to 800
c
c tl  
c
  620 continue
c
c
      go to 800
c
c pb  
c 
  640 continue
c
      e(   1) =          0.59200000d0
      s(   1) =         -0.76950000d0
      e(   2) =          0.30280000d0
      s(   2) =          0.99920000d0
      e(   3) =          0.09220000d0
      s(   3) =          0.62780000d0
      e(   4) =          0.75640000d0
      p(   4) =         -0.09500000d0
      e(   5) =          0.18760000d0
      p(   5) =          0.57510000d0
      e(   6) =          0.06100000d0
      p(   6) =          0.55340000d0
c
      go to 800
c
c bi  
c 
  660 continue
c
      e(   1) =          0.70020000d0
      s(   1) =         -0.64480000d0
      e(   2) =          0.31190000d0
      s(   2) =          0.86290000d0
      e(   3) =          0.11030000d0
      s(   3) =          0.62810000d0
      e(   4) =          0.88010000d0
      p(   4) =         -0.11830000d0
      e(   5) =          0.22070000d0
      p(   5) =          0.60820000d0
      e(   6) =          0.07540000d0
      p(   6) =          0.52340000d0
c
      go to 800
c
c po  
c
  680 continue
c
      e(   1) =          0.66580000d0
      s(   1) =         -0.97190000d0
      e(   2) =          0.36960000d0
      s(   2) =          1.26260000d0
      e(   3) =          0.11460000d0
      s(   3) =          0.55470000d0
      e(   4) =          0.91720000d0
      p(   4) =         -0.13780000d0
      e(   5) =          0.26710000d0
      p(   5) =          0.60420000d0
      e(   6) =          0.08730000d0
      p(   6) =          0.54880000d0
c
      go to 800
c
c at
c 
  700 continue
c
      e(   1) =          0.71850000d0
      s(   1) =         -0.88450000d0
      e(   2) =          0.35530000d0
      s(   2) =          1.26760000d0
      e(   3) =          0.12460000d0
      s(   3) =          0.44730000d0
      e(   4) =          0.92930000d0
      p(   4) =         -0.15050000d0
      e(   5) =          0.26700000d0
      p(   5) =          0.72410000d0
      e(   6) =          0.00760000d0
      p(   6) =          0.43350000d0
c
      go to 800
c
c rn  
c
  720 continue
c
      e(   1) =          0.70220000d0
      s(   1) =         -1.21900000d0
      e(   2) =          0.41150000d0
      s(   2) =          1.62440000d0
      e(   3) =          0.13400000d0
      s(   3) =          0.42450000d0
      e(   4) =          1.03690000d0
      p(   4) =         -0.17150000d0
      e(   5) =          0.33080000d0
      p(   5) =          0.66180000d0
      e(   6) =          0.11080000d0
      p(   6) =          0.51050000d0
c
800   return
      end
      subroutine shstrlc(nucz,ipass,itype,igauss,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c   ******************************************************************
c   RLC ECP   Stuttgart Relativistic, Large Core ECP Basis Set
c                        Stuttgart
c             Core         Name     Primitives        Contractions
c   Li - Be:  2[He]       ECP2SDF  (4s,4p)          -> [2s,2p]
c    B - N :  2           ECP2MWB  (4s,4p)          -> [2s,2p]
c    O - F :  2           ECP2MWB  (4s,5p)          -> [2s,3p]
c   Ne     :  2           ECP2MWB  (7s,7p,3d,1f)    -> [4s,4p,3d,1f]
c   Na - Mg: 10[Ne]       ECP10SDF (4s,4p)          -> [2s,2p]
c   Al - P : 10           ECP10MWB (4s,4p)          -> [2s,2p]
c    S - Cl: 10           ECP10MWB (4s,5p)          -> [2s,3p]
c   Ar     : 10           ECP10MWB (6s,6p,3d,1f)    -> [4s,4p,3d,1f]
c    K - Ca: 18[Ar]       ECP18SDF (4s,4p)          -> [2s,2p]
c   Zn     : 28[Ar+3d]    ECP28MWB (4s,2p)          -> [3s,2p]
c   Ga - As: 28           ECP28MWB (4s,2p)          -> [3s,2p]
c   Se - Br: 28           ECP28MWB (4s,5p)          -> [2s,3p]
c   Kr     : 28           ECP28MWB (6s,6p,3d,1f)    -> [4s,4p,3d,1f]
c   Rb - Sr: 36[Kr]       ECP36SDF (4s,4p)          -> [2s,2p]
c   In - Sb: 46[Kr+4d]    ECP46MWB (4s,4p)          -> [2s,2p]
c   Te - I : 46           ECP46MWB (4s,5p)          -> [2s,3p]
c   Xe     : 46           ECP46MWB (6s,6p,3d,1f)    -> [4s,4p,3d,1f]
c   Cs - Ba: 54[Xe]       ECP54SDF (4s,4p)          -> [2s,2p]
c   Hg - Rn: 78[Xe+4f+5d] ECP78MWB (4s,4p,1d)       -> [2s,2p,1d]
c   Ac - Lr: 78           ECP78MWB (8s,8p,6d,5f,2g) -> [5s,5p,4d,3f,2g]
c
c   Li - Be: P. Fuentealba, H. Preuss, H. Stoll, L. v. Szentpaly,
c   Na       Chem. Phys. Lett.  89, 418 (1982).
c
c   B  - Ne: A. Bergner, M. Dolg, W. Kuechle, H. Stoll, H. Preuss,
c            Mol. Phys. 80,  1431 (1993).
c   Mg     : P. Fuentealba, L. v. Szentpaly, H. Preuss, H. Stoll,
c            J. Phys. B 18,  1287 (1985).
c   Al     : G. Igel-Mann, H. Stoll, H. Preuss,
c            Mol. Phys. 65, 1321 (1988).
c   Hg - Rn: W. Kuechle, M. Dolg, H. Stoll, H. Preuss,
c            Mol. Phys. 74, 1245 (1991).
c   Ac - Lr: W. Kuechle, to be published
c   ******************************************************************
c
      dimension igau(19,8), itypes(19,8)
      dimension kind(8)
      data kind/4,5,12,12,5,5,6,19/
      data igau /
     + 3,1,3,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 3,1,3,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 4,1,1,1,4,1,1,1,1,1,1,1,0,0,0,0,0,0,0,
     + 3,1,1,1,3,1,1,1,1,1,1,1,0,0,0,0,0,0,0,
     + 2,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 3,1,3,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 3,1,3,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 4,1,1,1,1,4,1,1,1,1,3,1,1,1,3,1,1,1,1 /
c
      data itypes /
     + 1,1,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,2,2,2,2,3,3,3,4,0,0,0,0,0,0,0,
     + 1,1,1,1,2,2,2,2,3,3,3,4,0,0,0,0,0,0,0,
     + 1,1,1,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,2,2,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,2,2,2,3,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,2,2,2,2,2,3,3,3,3,4,4,4,5,5 /
c
c     set values for the current ccdz  shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3,4,5 for s,p,d,f,g shell
c
      ind=0
      if(nucz.ge.3  .and.  nucz.le.7) ind=1
      if(nucz.ge.8  .and.  nucz.le.9) ind=2
      if(nucz.eq.10) ind=3
      if(nucz.ge.11  .and.  nucz.le.15) ind=1
      if(nucz.ge.16  .and.  nucz.le.17) ind=2
      if(nucz.eq.18) ind=4
      if(nucz.ge.19  .and.  nucz.le.20) ind=1
      if(nucz.eq.30) ind=5
      if(nucz.ge.31  .and.  nucz.le.33) ind=1
      if(nucz.ge.34  .and.  nucz.le.35) ind=2
      if(nucz.eq.36) ind=4
      if(nucz.ge.37  .and.  nucz.le.38) ind=1
      if(nucz.ge.49  .and.  nucz.le.51) ind=1
      if(nucz.ge.52  .and.  nucz.le.53) ind=2
      if(nucz.eq.54) ind=4
      if(nucz.ge.55  .and.  nucz.le.56) ind=1
      if(nucz.ge.80  .and.  nucz.le.83) ind=6
      if(nucz.ge.84  .and.  nucz.le.85) ind=7
      if(nucz.eq.86) ind=6
      if(nucz.ge.89  .and.  nucz.le.103) ind=8
c
      if (ind.eq.0) then
         call caserr2(
     +        'Stuttgart RLC ecp basis set not available')
      end if
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if(.not.odone) then
c
       igauss = igau(ipass,ind)
       ityp = itypes(ipass,ind)
      endif
      itype = ityp + 15
c
      return
      end
      subroutine strlc_0(e,s,p,d,f,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c   
c     ----- li- ne -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      go to (100,100,
     +       140,160,180,200,220,240,260,280),n
c
c
c +++ basis h, he
c
100    call caserr2('No RLC ECP basis set for H or He')
c
       go to 500
c
c
c +++ basis li
c
140    continue
c
      e(   1) =          3.04732700d0
      s(   1) =          0.00655500d0
      e(   2) =          0.60357900d0
      s(   2) =         -0.14040100d0
      e(   3) =          0.06913800d0
      s(   3) =          0.62375600d0
      e(   4) =          0.02650200d0
      s(   4) =          1.00000000d0
      e(   5) =          0.83715800d0
      p(   5) =          0.04350700d0
      e(   6) =          0.17194100d0
      p(   6) =          0.22964900d0
      e(   7) =          0.05207900d0
      p(   7) =          0.56294900d0
      e(   8) =          0.01917200d0
      p(   8) =          1.00000000d0
c
       go to 500
c
c +++ basis be
c
160    continue
c
      e(   1) =          1.11064430d0
      s(   1) =         -0.17188900d0
      e(   2) =          0.37146500d0
      s(   2) =          0.12915800d0
      e(   3) =          0.13267800d0
      s(   3) =          0.61485900d0
      e(   4) =          0.04775100d0
      s(   4) =          1.00000000d0
      e(   5) =          2.88457770d0
      p(   5) =          0.03152500d0
      e(   6) =          0.78014400d0
      p(   6) =          0.14388800d0
      e(   7) =          0.22006100d0
      p(   7) =          0.48461200d0
      e(   8) =          0.06640700d0
      p(   8) =          1.00000000d0
c
       go to 500
c
180    continue
c
c +++ basis b
c
      e(   1) =          1.69056000d0
      s(   1) =         -0.27220800d0
      e(   2) =          0.98366600d0
      s(   2) =          0.20112800d0
      e(   3) =          0.25697900d0
      s(   3) =          0.57776300d0
      e(   4) =          0.09503800d0
      s(   4) =          1.00000000d0
      e(   5) =          5.39991300d0
      p(   5) =          0.03494100d0
      e(   6) =          1.27121700d0
      p(   6) =          0.18683400d0
      e(   7) =          0.36190900d0
      p(   7) =          0.46846300d0
      e(   8) =          0.10766100d0
      p(   8) =          1.00000000d0
c
       go to 500
c
c +++ basis c
c
200    continue
c
      e(   1) =          2.26310100d0
      s(   1) =          0.49654800d0
      e(   2) =          1.77318600d0
      s(   2) =         -0.42239100d0
      e(   3) =          0.40861900d0
      s(   3) =         -0.59935600d0
      e(   4) =          0.13917500d0
      s(   4) =          1.00000000d0
      e(   5) =          8.38302500d0
      p(   5) =         -0.03854400d0
      e(   6) =          1.99313200d0
      p(   6) =         -0.20318500d0
      e(   7) =          0.55954300d0
      p(   7) =         -0.49817600d0
      e(   8) =          0.15612600d0
      p(   8) =          1.00000000d0
c
       go to 500
c
c +++ basis n
c
220    continue
c
      e(   1) =         32.65683900d0
      s(   1) =         -0.01379400d0
      e(   2) =          4.58918900d0
      s(   2) =          0.12912900d0
      e(   3) =          0.70625100d0
      s(   3) =         -0.56809400d0
      e(   4) =          0.21639900d0
      s(   4) =          1.00000000d0
      e(   5) =         12.14697400d0
      p(   5) =         -0.04129600d0
      e(   6) =          2.88426500d0
      p(   6) =         -0.21400900d0
      e(   7) =          0.80856400d0
      p(   7) =         -0.50278300d0
      e(   8) =          0.22216300d0
      p(   8) =          1.00000000d0
c
       go to 500
c
c +++ basis o
c
240    continue
c
      e(   1) =         47.10551800d0
      s(   1) =         -0.01440800d0
      e(   2) =          5.91134600d0
      s(   2) =          0.12956800d0
      e(   3) =          0.97648300d0
      s(   3) =         -0.56311800d0
      e(   4) =          0.29607000d0
      s(   4) =          1.00000000d0
      e(   5) =         16.69221900d0
      p(   5) =          0.04485600d0
      e(   6) =          3.90070200d0
      p(   6) =          0.22261300d0
      e(   7) =          1.07825300d0
      p(   7) =          0.50018800d0
      e(   8) =          0.28418900d0
      p(   8) =          1.00000000d0
      e(   9) =          0.07020000d0
      p(   9) =          1.00000000d0
c
       go to 500
c
c +++ basis f
c
260    continue
c
      e(   1) =         51.64276300d0
      s(   1) =          0.00856600d0
      e(   2) =          9.41427700d0
      s(   2) =         -0.15300900d0
      e(   3) =          1.21412300d0
      s(   3) =          0.58983500d0
      e(   4) =          0.37008100d0
      s(   4) =          1.00000000d0
      e(   5) =         22.30083000d0
      p(   5) =          0.05185100d0
      e(   6) =          4.95457300d0
      p(   6) =          0.23728700d0
      e(   7) =          1.34231100d0
      p(   7) =          0.50766600d0
      e(   8) =          0.34653000d0
      p(   8) =          1.00000000d0
      e(   9) =          0.08477200d0
      p(   9) =          1.00000000d0
c
       go to 500
c
c +++ basis ne
c
280    continue
c
      e(   1) =        612.00243700d0
      s(   1) =         -0.00610700d0
      e(   2) =         80.95204400d0
      s(   2) =         -0.04260300d0
      e(   3) =         13.86420100d0
      s(   3) =          0.45219600d0
      e(   4) =          8.74552600d0
      s(   4) =          0.57995600d0
      e(   5) =          1.99234600d0
      s(   5) =          1.00000000d0
      e(   6) =          0.80080300d0
      s(   6) =          1.00000000d0
      e(   7) =          0.30777400d0
      s(   7) =          1.00000000d0
      e(   8) =        158.31453500d0
      p(   8) =          0.00785100d0
      e(   9) =         37.30112800d0
      p(   9) =          0.07131600d0
      e(  10) =         12.70555800d0
      p(  10) =          0.28639200d0
      e(  11) =          4.58708700d0
      p(  11) =          0.73539400d0
      e(  12) =          1.73566200d0
      p(  12) =          1.00000000d0
      e(  13) =          0.64055300d0
      p(  13) =          1.00000000d0
      e(  14) =          0.22254400d0
      p(  14) =          1.00000000d0
      e(  15) =          4.27480000d0
      d(  15) =          1.00000000d0
      e(  16) =          1.17170000d0
      d(  16) =          1.00000000d0
      e(  17) =          0.32110000d0
      d(  17) =          1.00000000d0
      e(  18) =          2.57950000d0
      f(  18) =          1.00000000d0
c
  500 continue
c
      return
      end
      subroutine strlc_1(e,s,p,d,f,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- na - ar -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-10
      go to (300,320,340,360,380,400,420,440),nn
c
c
c +++ basis na
c
  300 continue
c
      e(   1) =          2.60333630d0
      s(   1) =          0.00882400d0
      e(   2) =          0.51721700d0
      s(   2) =         -0.18322700d0
      e(   3) =          0.05819600d0
      s(   3) =          0.65201700d0
      e(   4) =          0.02314100d0
      s(   4) =          1.00000000d0
      e(   5) =          0.49920600d0
      p(   5) =          0.01854700d0
      e(   6) =          0.07921900d0
      p(   6) =          0.27621100d0
      e(   7) =          0.02994600d0
      p(   7) =          0.58700400d0
      e(   8) =          0.01260500d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c +++ basis mg
c
  320 continue
c
      e(   1) =          2.42571930d0
      s(   1) =          0.02676400d0
      e(   2) =          0.82262500d0
      s(   2) =         -0.22388000d0
      e(   3) =          0.10774900d0
      s(   3) =          0.62046400d0
      e(   4) =          0.03948500d0
      s(   4) =          1.00000000d0
      e(   5) =          0.76904700d0
      p(   5) =         -0.03664800d0
      e(   6) =          0.18867500d0
      p(   6) =          0.24314500d0
      e(   7) =          0.07510100d0
      p(   7) =          0.55478400d0
      e(   8) =          0.02949700d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c +++ basis al
c
340    continue
c
      e(   1) =          2.78633700d0
      s(   1) =         -0.04641100d0
      e(   2) =          1.14363500d0
      s(   2) =          0.27447200d0
      e(   3) =          0.17002700d0
      s(   3) =         -0.62523400d0
      e(   4) =          0.06732400d0
      s(   4) =          1.00000000d0
      e(   5) =          0.98379400d0
      p(   5) =          0.05203600d0
      e(   6) =          0.35824500d0
      p(   6) =         -0.15509400d0
      e(   7) =          0.13815800d0
      p(   7) =         -0.53258400d0
      e(   8) =          0.04497500d0
      p(   8) =          1.00000000d0
c
       go to 500
c
c +++ basis si
c
360    continue
c
      e(   1) =          4.01437800d0
      s(   1) =         -0.03950800d0
      e(   2) =          1.39370700d0
      s(   2) =          0.29615000d0
      e(   3) =          0.25165800d0
      s(   3) =         -0.59975200d0
      e(   4) =          0.10018000d0
      s(   4) =          1.00000000d0
      e(   5) =          1.10248100d0
      p(   5) =          0.08458300d0
      e(   6) =          0.58312700d0
      p(   6) =         -0.18574800d0
      e(   7) =          0.20867500d0
      p(   7) =         -0.55485200d0
      e(   8) =          0.06914700d0
      p(   8) =          1.00000000d0
c
       go to 500
c
c +++ basis p
c
380    continue
c
      e(   1) =          6.72230800d0
      s(   1) =         -0.03245500d0
      e(   2) =          1.62406300d0
      s(   2) =          0.28505600d0
      e(   3) =          0.33192900d0
      s(   3) =         -0.64691400d0
      e(   4) =          0.12081900d0
      s(   4) =          1.00000000d0
      e(   5) =          1.28322100d0
      p(   5) =         -0.05596200d0
      e(   6) =          0.59972500d0
      p(   6) =          0.28636300d0
      e(   7) =          0.22775900d0
      p(   7) =          0.55225700d0
      e(   8) =          0.08442400d0
      p(   8) =          1.00000000d0
c
       go to 500
c
c +++ basis s
c
400    continue
c
      e(   1) =          6.83351800d0
      s(   1) =         -0.04387500d0
      e(   2) =          2.07773800d0
      s(   2) =          0.31989400d0
      e(   3) =          0.41912100d0
      s(   3) =         -0.66123300d0
      e(   4) =          0.15323700d0
      s(   4) =          1.00000000d0
      e(   5) =          1.81713900d0
      p(   5) =         -0.07922700d0
      e(   6) =          0.85507000d0
      p(   6) =          0.26367100d0
      e(   7) =          0.31205300d0
      p(   7) =          0.58068200d0
      e(   8) =          0.10168700d0
      p(   8) =          1.00000000d0
      e(   9) =          0.02981000d0
      p(   9) =          1.00000000d0
c
       go to 500
c
c +++ basis cl
c
420    continue
c
      e(   1) =         14.07307600d0
      s(   1) =          0.02034500d0
      e(   2) =          2.33156500d0
      s(   2) =         -0.28922300d0
      e(   3) =          0.50710000d0
      s(   3) =          0.63036700d0
      e(   4) =          0.18243300d0
      s(   4) =          1.00000000d0
      e(   5) =          3.35312900d0
      p(   5) =         -0.04155200d0
      e(   6) =          0.78568600d0
      p(   6) =          0.39974800d0
      e(   7) =          0.26745400d0
      p(   7) =          0.59182900d0
      e(   8) =          0.07827500d0
      p(   8) =          1.00000000d0
      e(   9) =          0.01547700d0
      p(   9) =          1.00000000d0
c
       go to 500
c
c +++ basis ar
c
440    continue
c
      e(   1) =        174.66965500d0
      s(   1) =          0.00258700d0
      e(   2) =         12.69576800d0
      s(   2) =          0.06231300d0
      e(   3) =          2.91783400d0
      s(   3) =         -1.04215800d0
      e(   4) =          0.67084000d0
      s(   4) =          1.00000000d0
      e(   5) =          0.29911200d0
      s(   5) =          1.00000000d0
      e(   6) =          0.13140200d0
      s(   6) =          1.00000000d0
      e(   7) =         19.88722100d0
      p(   7) =          0.02334600d0
      e(   8) =          3.77617200d0
      p(   8) =         -0.22462100d0
      e(   9) =          1.21151600d0
      p(   9) =          1.13759600d0
      e(  10) =          0.53849900d0
      p(  10) =          1.00000000d0
      e(  11) =          0.22957500d0
      p(  11) =          1.00000000d0
      e(  12) =          0.09510300d0
      p(  12) =          1.00000000d0
      e(  13) =          1.45090000d0
      d(  13) =          1.00000000d0
      e(  14) =          0.43850000d0
      d(  14) =          1.00000000d0
      e(  15) =          0.13250000d0
      d(  15) =          1.00000000d0
      e(  16) =          0.93050000d0
      f(  16) =          1.00000000d0
c
  500 continue
c
      return
      end
      subroutine strlc_2(e,s,p,d,f,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- basis (K-Kr) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-18
      go to (100,120,140,140,140,140,140,140,140,140,140,320,
     +       340,360,380,400,420,440),nn
c
c k   
c
  100 continue
c
      e(   1) =          1.10549260d0
      s(   1) =          0.02513500d0
      e(   2) =          0.26945100d0
      s(   2) =         -0.28491100d0
      e(   3) =          0.04485200d0
      s(   3) =          0.47357400d0
      e(   4) =          0.02056900d0
      s(   4) =          1.00000000d0
      e(   5) =          0.22027800d0
      p(   5) =         -0.06444300d0
      e(   6) =          0.05161100d0
      p(   6) =          0.27014000d0
      e(   7) =          0.02225300d0
      p(   7) =          0.60128900d0
      e(   8) =          0.00984800d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c ca   
c
  120 continue
c
      e(   1) =          0.83826500d0
      s(   1) =          0.10683100d0
      e(   2) =          0.43231300d0
      s(   2) =         -0.38724000d0
      e(   3) =          0.06511000d0
      s(   3) =          0.64540900d0
      e(   4) =          0.02710700d0
      s(   4) =          1.00000000d0
      e(   5) =          0.31691500d0
      p(   5) =         -0.11713400d0
      e(   6) =          0.11601800d0
      p(   6) =          0.23854100d0
      e(   7) =          0.04970800d0
      p(   7) =          0.59863200d0
      e(   8) =          0.02147800d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c zn   
c
  320 continue
c
      e(   1) =          1.57275500d0
      s(   1) =          0.31386200d0
      e(   2) =          1.19890500d0
      s(   2) =         -0.54180100d0
      e(   3) =          0.14885600d0
      s(   3) =          1.00000000d0
      e(   4) =          0.05101600d0
      s(   4) =          1.00000000d0
      e(   5) =          0.13627000d0
      p(   5) =          1.00000000d0
      e(   6) =          0.04150000d0
      p(   6) =          1.00000000d0
c
      go to 500
c
c ga  
c
  340 continue
c
      e(   1) =          3.48477500d0
      s(   1) =          0.11439400d0
      e(   2) =          1.68583500d0
      s(   2) =         -0.36013100d0
      e(   3) =          0.17854200d0
      s(   3) =          0.69379900d0
      e(   4) =          0.06781400d0
      s(   4) =          1.00000000d0
      e(   5) =          1.28323100d0
      p(   5) =          0.10283400d0
      e(   6) =          0.47616300d0
      p(   6) =         -0.14088600d0
      e(   7) =          0.15562100d0
      p(   7) =         -0.47731500d0
      e(   8) =          0.05429400d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c ge  
c 
  360 continue
c
      e(   1) =          3.23125300d0
      s(   1) =          0.22218000d0
      e(   2) =          1.94754500d0
      s(   2) =         -0.50661600d0
      e(   3) =          0.23232000d0
      s(   3) =          0.70884500d0
      e(   4) =          0.08666900d0
      s(   4) =          1.00000000d0
      e(   5) =          1.22780500d0
      p(   5) =          0.22395000d0
      e(   6) =          0.75685600d0
      p(   6) =         -0.22913400d0
      e(   7) =          0.20434700d0
      p(   7) =         -0.57641400d0
      e(   8) =          0.06779200d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c as  
c 
  380 continue
c
      e(   1) =          3.43147400d0
      s(   1) =          0.14816600d0
      e(   2) =          1.89686600d0
      s(   2) =         -0.44989000d0
      e(   3) =          0.29444900d0
      s(   3) =          0.69568200d0
      e(   4) =          0.11189600d0
      s(   4) =          1.00000000d0
      e(   5) =          1.29644700d0
      p(   5) =         -0.36995400d0
      e(   6) =          0.94997100d0
      p(   6) =          0.37321400d0
      e(   7) =          0.25442100d0
      p(   7) =          0.60030400d0
      e(   8) =          0.08759300d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c se  
c
  400 continue
c
      e(   1) =          3.58818000d0
      s(   1) =          0.24963000d0
      e(   2) =          2.23971100d0
      s(   2) =         -0.58146000d0
      e(   3) =          0.34377300d0
      s(   3) =          0.72893800d0
      e(   4) =          0.13139900d0
      s(   4) =          1.00000000d0
      e(   5) =          1.50942700d0
      p(   5) =          0.19527100d0
      e(   6) =          0.87510600d0
      p(   6) =         -0.25391500d0
      e(   7) =          0.29082600d0
      p(   7) =         -0.59048700d0
      e(   8) =          0.10022100d0
      p(   8) =          1.00000000d0
      e(   9) =          0.03251600d0
      p(   9) =          1.00000000d0
c
      go to 500
c
c br  
c 
  420 continue
c
      e(   1) =          4.72188100d0
      s(   1) =          0.10729700d0
      e(   2) =          2.25755500d0
      s(   2) =         -0.43380200d0
      e(   3) =          0.38960800d0
      s(   3) =          0.77204300d0
      e(   4) =          0.14713400d0
      s(   4) =          1.00000000d0
      e(   5) =          1.89694200d0
      p(   5) =         -0.17939500d0
      e(   6) =          0.91089900d0
      p(   6) =          0.26372900d0
      e(   7) =          0.31685500d0
      p(   7) =          0.60695200d0
      e(   8) =          0.10950300d0
      p(   8) =          1.00000000d0
      e(   9) =          0.03609700d0
      p(   9) =          1.00000000d0
c
      go to 500
c
c kr  
c
  440 continue
c
      e(   1) =         35.40296100d0
      s(   1) =          0.02049500d0
      e(   2) =         15.66508900d0
      s(   2) =         -0.09918800d0
      e(   3) =          6.24771100d0
      s(   3) =          1.07205100d0
      e(   4) =          2.39424600d0
      s(   4) =          1.00000000d0
      e(   5) =          0.45348900d0
      s(   5) =          1.00000000d0
      e(   6) =          0.17215800d0
      s(   6) =          1.00000000d0
      e(   7) =         23.02908500d0
      p(   7) =          0.00562500d0
      e(   8) =          9.50309200d0
      p(   8) =         -0.07505100d0
      e(   9) =          2.84246100d0
      p(   9) =          1.04568900d0
      e(  10) =          0.68929300d0
      p(  10) =          1.00000000d0
      e(  11) =          0.28513600d0
      p(  11) =          1.00000000d0
      e(  12) =          0.10878200d0
      p(  12) =          1.00000000d0
      e(  13) =          0.73790000d0
      d(  13) =          1.00000000d0
      e(  14) =          0.32250000d0
      d(  14) =          1.00000000d0
      e(  15) =          0.14090000d0
      d(  15) =          1.00000000d0
      e(  16) =          0.70520000d0
      f(  16) =          1.00000000d0
c
  500 return
c
  140 call caserr2('No Stuttgart RLC ecp basis for Sc - Cu')
      return
c
      end
      subroutine strlc_3(e,s,p,d,f,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- basis (Rb-Xe) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-36
      go to (100,120,140,140,140,140,140,140,140,140,140,140,
     +       340,360,380,400,420,440),nn
c
c rb   
c
  100 continue
c
      e(   1) =          0.71828800d0
      s(   1) =          0.07722000d0
      e(   2) =          0.27397800d0
      s(   2) =         -0.34462300d0
      e(   3) =          0.03230600d0
      s(   3) =          0.72632600d0
      e(   4) =          0.01523200d0
      s(   4) =          1.00000000d0
      e(   5) =          0.16196700d0
      p(   5) =         -0.09625300d0
      e(   6) =          0.05077100d0
      p(   6) =          0.20084500d0
      e(   7) =          0.02213300d0
      p(   7) =          0.60769800d0
      e(   8) =          0.00993400d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c sr   
c
  120 continue
c
      e(   1) =          0.79174000d0
      s(   1) =          0.08351400d0
      e(   2) =          0.31617800d0
      s(   2) =         -0.42923700d0
      e(   3) =          0.06656500d0
      s(   3) =          0.52396900d0
      e(   4) =          0.02699000d0
      s(   4) =          1.00000000d0
      e(   5) =          0.22582500d0
      p(   5) =         -0.16733500d0
      e(   6) =          0.09569100d0
      p(   6) =          0.25549700d0
      e(   7) =          0.04207700d0
      p(   7) =          0.61166900d0
      e(   8) =          0.01807700d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c in  
c
  340 continue
c
      e(   1) =          1.53256200d0
      s(   1) =          0.26177400d0
      e(   2) =          0.94426900d0
      s(   2) =         -0.62540600d0
      e(   3) =          0.17673300d0
      s(   3) =          0.65130400d0
      e(   4) =          0.06434300d0
      s(   4) =          1.00000000d0
      e(   5) =          0.64147400d0
      p(   5) =          0.21110300d0
      e(   6) =          0.34273900d0
      p(   6) =         -0.24302900d0
      e(   7) =          0.10954600d0
      p(   7) =         -0.56019100d0
      e(   8) =          0.03895800d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c sn  
c 
  360 continue
c
      e(   1) =          1.60032200d0
      s(   1) =          0.63576800d0
      e(   2) =          1.16634100d0
      s(   2) =         -1.07626200d0
      e(   3) =          0.23976100d0
      s(   3) =          0.60858200d0
      e(   4) =          0.08723700d0
      s(   4) =          1.00000000d0
      e(   5) =          2.10467700d0
      p(   5) =          0.07895000d0
      e(   6) =          1.37109400d0
      p(   6) =         -0.19115900d0
      e(   7) =          0.20139300d0
      p(   7) =          0.54254600d0
      e(   8) =          0.06599500d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c sb  
c 
  380 continue
c
      e(   1) =          2.22079900d0
      s(   1) =          0.25671300d0
      e(   2) =          1.26783800d0
      s(   2) =         -0.66901100d0
      e(   3) =          0.26095600d0
      s(   3) =          0.64646000d0
      e(   4) =          0.10006600d0
      s(   4) =          1.00000000d0
      e(   5) =          2.14934900d0
      p(   5) =          0.10891500d0
      e(   6) =          1.43421200d0
      p(   6) =         -0.25139700d0
      e(   7) =          0.24263100d0
      p(   7) =          0.57394700d0
      e(   8) =          0.08341600d0
      p(   8) =          1.00000000d0
c
      go to 500
c
c te  
c
  400 continue
c
      e(   1) =          2.47122200d0
      s(   1) =          0.24195600d0
      e(   2) =          1.50999500d0
      s(   2) =         -0.60048800d0
      e(   3) =          0.25467700d0
      s(   3) =          0.76352200d0
      e(   4) =          0.10263100d0
      s(   4) =          1.00000000d0
      e(   5) =          2.38873400d0
      p(   5) =          0.15818100d0
      e(   6) =          1.64416500d0
      p(   6) =         -0.32493200d0
      e(   7) =          0.28997300d0
      p(   7) =          0.58565500d0
      e(   8) =          0.09675300d0
      p(   8) =          1.00000000d0
      e(   9) =          0.02976700d0
      p(   9) =          1.00000000d0
c
      go to 500
c
c i  
c 
  420 continue
c
      e(   1) =          2.12276500d0
      s(   1) =          1.10402800d0
      e(   2) =          1.77048100d0
      s(   2) =         -1.53532600d0
      e(   3) =          0.31308400d0
      s(   3) =          0.75160300d0
      e(   4) =          0.12407100d0
      s(   4) =          1.00000000d0
      e(   5) =          2.43288700d0
      p(   5) =          0.44223200d0
      e(   6) =          2.13724900d0
      p(   6) =         -0.58380900d0
      e(   7) =          0.31454600d0
      p(   7) =          0.62660600d0
      e(   8) =          0.10494500d0
      p(   8) =          1.00000000d0
      e(   9) =          0.03264100d0
      p(   9) =          1.00000000d0
c
      go to 500
c
c xe  
c
  440 continue
c
      e(   1) =          7.85801500d0
      s(   1) =          0.05992800d0
      e(   2) =          3.49577200d0
      s(   2) =         -0.64907600d0
      e(   3) =          1.75886900d0
      s(   3) =          1.52981400d0
      e(   4) =          0.31474500d0
      s(   4) =          1.00000000d0
      e(   5) =          0.15116000d0
      s(   5) =          1.00000000d0
      e(   6) =          0.07122600d0
      s(   6) =          1.00000000d0
      e(   7) =          3.21452300d0
      p(   7) =          0.21100500d0
      e(   8) =          1.88494400d0
      p(   8) =         -0.71267400d0
      e(   9) =          0.44887600d0
      p(   9) =          1.22808000d0
      e(  10) =          0.21223200d0
      p(  10) =          1.00000000d0
      e(  11) =          0.10011500d0
      p(  11) =          1.00000000d0
      e(  12) =          0.04697900d0
      p(  12) =          1.00000000d0
      e(  13) =          0.44600000d0
      d(  13) =          1.00000000d0
      e(  14) =          0.23220000d0
      d(  14) =          1.00000000d0
      e(  15) =          0.12080000d0
      d(  15) =          1.00000000d0
      e(  16) =          0.51570000d0
      f(  16) =          1.00000000d0
c
  500 return
  140 call caserr2('No Stuttgart RLC ecp basis for Y - Cd')
      return
      end
      subroutine strlc_4(e,s,p,d,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- ECP basis (Cs-Rn) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
c
      nn = n-54
      go to (100,120,140,
     +       140,140,140,140,140,140,140,140,140,140,140,140,140,140,
     +       140,140,140,140,140,140,140,140,600,620,640,660,680,700,
     +       720),nn
c
c cs   
c
  100 continue
c
      e(   1) =          0.39743100d0
      s(   1) =          0.23964700d0
      e(   2) =          0.22979600d0
      s(   2) =         -0.55417200d0
      e(   3) =          0.03653500d0
      s(   3) =          0.25135900d0
      e(   4) =          0.01890100d0
      s(   4) =          1.00000000d0
      e(   5) =          0.12390000d0
      p(   5) =         -0.13090600d0
      e(   6) =          0.05228100d0
      p(   6) =          0.13137000d0
      e(   7) =          0.02189700d0
      p(   7) =          0.61958400d0
      e(   8) =          0.00957400d0
      p(   8) =          1.00000000d0
c
      go to 800
c
c ba   
c
  120 continue
c
      e(   1) =          0.49284700d0
      s(   1) =          0.22896700d0
      e(   2) =          0.28284400d0
      s(   2) =         -0.58103500d0
      e(   3) =          0.04487400d0
      s(   3) =          0.66730800d0
      e(   4) =          0.02058600d0
      s(   4) =          1.00000000d0
      e(   5) =          0.15375200d0
      p(   5) =         -0.27159300d0
      e(   6) =          0.08098700d0
      p(   6) =          0.35423400d0
      e(   7) =          0.03256600d0
      p(   7) =          0.66426400d0
      e(   8) =          0.01423800d0
      p(   8) =          1.00000000d0
c
      go to 800
c
c hg   
c
  600 continue
c
      e(   1) =          1.35484200d0
      s(   1) =          0.23649400d0
      e(   2) =          0.82889200d0
      s(   2) =         -0.59962800d0
      e(   3) =          0.13393200d0
      s(   3) =          0.84630500d0
      e(   4) =          0.05101700d0
      s(   4) =          1.00000000d0
      e(   5) =          1.00014600d0
      p(   5) =          0.14495400d0
      e(   6) =          0.86645300d0
      p(   6) =         -0.20497100d0
      e(   7) =          0.11820600d0
      p(   7) =          0.49030100d0
      e(   8) =          0.03515500d0
      p(   8) =          1.00000000d0
      e(   9) =          0.19000000d0
      d(   9) =          1.00000000d0
c
      go to 800
c
c tl  
c
  620 continue
c
      e(   1) =          1.46333900d0
      s(   1) =          0.42546200d0
      e(   2) =          0.99099600d0
      s(   2) =         -0.82977300d0
      e(   3) =          0.16325500d0
      s(   3) =          0.83244400d0
      e(   4) =          0.06080200d0
      s(   4) =          1.00000000d0
      e(   5) =          1.34250200d0
      p(   5) =          0.09710800d0
      e(   6) =          0.99398900d0
      p(   6) =         -0.19325400d0
      e(   7) =          0.14969300d0
      p(   7) =          0.51477500d0
      e(   8) =          0.04561200d0
      p(   8) =          1.00000000d0
      e(   9) =          0.15000000d0
      d(   9) =          1.00000000d0
c
      go to 800
c
c pb  
c 
  640 continue
c
      e(   1) =          1.30517500d0
      s(   1) =          1.01040200d0
      e(   2) =          1.13528200d0
      s(   2) =         -1.40235500d0
      e(   3) =          0.20277100d0
      s(   3) =          0.79337200d0
      e(   4) =          0.08179600d0
      s(   4) =          1.00000000d0
      e(   5) =          1.44168400d0
      p(   5) =          0.14562600d0
      e(   6) =          0.97714300d0
      p(   6) =         -0.31986300d0
      e(   7) =          0.19450500d0
      p(   7) =          0.55369000d0
      e(   8) =          0.06271000d0
      p(   8) =          1.00000000d0
      e(   9) =          0.17000000d0
      d(   9) =          1.00000000d0
c
      go to 800
c
c bi  
c 
  660 continue
c
      e(   1) =          1.42538800d0
      s(   1) =          0.07600800d0
      e(   2) =          0.98491400d0
      s(   2) =         -0.45740800d0
      e(   3) =          0.25251400d0
      s(   3) =          0.70218400d0
      e(   4) =          0.10061900d0
      s(   4) =          1.00000000d0
      e(   5) =          1.51728300d0
      p(   5) =          0.34668200d0
      e(   6) =          1.25330700d0
      p(   6) =         -0.51331300d0
      e(   7) =          0.20794900d0
      p(   7) =          0.64845700d0
      e(   8) =          0.06943300d0
      p(   8) =          1.00000000d0
      e(   9) =          0.17000000d0
      d(   9) =          1.00000000d0
c
      go to 800
c
c po  
c
  680 continue
c
      e(   1) =          1.95703000d0
      s(   1) =          0.35678700d0
      e(   2) =          1.29926600d0
      s(   2) =         -0.82546500d0
      e(   3) =          0.28447900d0
      s(   3) =          0.86024300d0
      e(   4) =          0.09942300d0
      s(   4) =          1.00000000d0
      e(   5) =          1.73113500d0
      p(   5) =          0.17382300d0
      e(   6) =          1.28216200d0
      p(   6) =         -0.33642600d0
      e(   7) =          0.23544600d0
      p(   7) =          0.69324200d0
      e(   8) =          0.07229900d0
      p(   8) =          1.00000000d0
      e(   9) =          0.02020700d0
      p(   9) =          1.00000000d0
      e(  10) =          0.21000000d0
      d(  10) =          1.00000000d0
c
      go to 800
c
c at
c 
  700 continue
c
      e(   1) =          1.96242000d0
      s(   1) =          0.51901800d0
      e(   2) =          1.38735900d0
      s(   2) =         -1.02561400d0
      e(   3) =          0.29623100d0
      s(   3) =          0.95350800d0
      e(   4) =          0.10412700d0
      s(   4) =          1.00000000d0
      e(   5) =          2.20213800d0
      p(   5) =          0.06344300d0
      e(   6) =          1.33879100d0
      p(   6) =         -0.19457400d0
      e(   7) =          0.26208100d0
      p(   7) =          0.65110400d0
      e(   8) =          0.09626800d0
      p(   8) =          1.00000000d0
      e(   9) =          0.03784900d0
      p(   9) =          1.00000000d0
      e(  10) =          0.23000000d0
      d(  10) =          1.00000000d0
c
      go to 800
c
c rn  
c
  720 continue
c
      e(   1) =          1.97832500d0
      s(   1) =          0.67898800d0
      e(   2) =          1.51403300d0
      s(   2) =         -1.18415900d0
      e(   3) =          0.32465400d0
      s(   3) =          0.92108600d0
      e(   4) =          0.12736600d0
      s(   4) =          1.00000000d0
      e(   5) =          2.03109500d0
      p(   5) =          0.23204000d0
      e(   6) =          1.65612200d0
      p(   6) =         -0.35451800d0
      e(   7) =          0.29836500d0
      p(   7) =          0.66512000d0
      e(   8) =          0.10322200d0
      p(   8) =          1.00000000d0
      e(   9) =          0.26000000d0
      d(   9) =          1.00000000d0
c
  800 return
  140 call caserr2('No Stuttgart RLC ecp basis for La - Au')
      return
      end
      subroutine strlc_5(e,s,p,d,f,g,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- ECP basis (Fr-Lw) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*),g(*)
c
      nn = n-86
      go to (100,120,140,
     +   160,180,200,220,240,260,280,300,320,340,360,380,400,420),
     +   nn
c
c fr   
c
  100 continue
c
      return
c
c ra   
c
  120 continue
c
c
      return
c
c ac   
c
  140 continue
c
c
      return
c
c th   
c
  160 continue
c
c
      return
c
c pa   
c
  180 continue
c

      return
c
c u   
c
  200 continue
c
c
      return
c
c np   
c
  220 continue
c
c
      return
c
c pu   
c
  240 continue
c
c
      return
c
c am   
c
  260 continue
c
      return
c
c cm   
c
  280 continue
c
c
      return
c
c bk   
c
  300 continue
c
c
      return
c
c cf   
c
  320 continue
c
c
      return
c
c es   
c
  340 continue
c
c
      return
c
c fm   
c
  360 continue
c
c
      return
c
c md   
c
  380 continue
c
c
      return
c
c no   
c
  400 continue
c
c
      return
c
c lw   
c
  420 continue
c
c
      return
      end
      subroutine shstrsc(nucz,ipass,itype,igauss,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c   ******************************************************************
c   RSC ECP   Stuttgart Relativistic, Small Core ECP Basis Set
c                         Stuttgart
c              Core         Name     Primitives        Contractions
c     K     : 10[Ne]       ECP10MWB (7s,6p)          -> [5s,4p]
c    Ca     : 10           ECP10MWB (6s,6p,5d)       -> [4s,4p,2d]
c    Sc - Ni: 10           ECP10MDF (8s,7p,6d,1f)    -> [6s,5p,3d,1f]
c    Cu - Zn: 10           ECP10MDF (8s,7p,6d)       -> [6s,5p,3d]
c    Rb     : 28[Ar+3d]    ECP28MWB (7s,6p)          -> [5s,4p]
c    Sr     : 28           ECP28MWB (6s,6p,5d)       -> [4s,4p,2d]
c    Y  - Cd: 28           ECP28MHF (8s,7p,6d)       -> [6s,5p,3d]
c    Cs     : 46[Kr+4d]    ECP46MWB (7s,6p)          -> [5s,4p]
c    Ba     : 46           ECP46MWB (6s,6p,5d,1f)    -> [3s,3p,2d,1f]
c    Ce - Ho: 28[Ar+3d]    ECP28MWB (12s,11p,9d,8f)  -> [5s,5p,4d,3f]
c    Er - Yb: 28           ECP28MWB (12s,10p,8d,8f)  -> [5s,5p,4d,3f]
c    Hf - Hg: 60[Kr+4df]   ECP60MWB (8s,7p,6d)       -> [6s,5p,3d]
c    Ac - Lr: 60           ECP60MWB (12s,11p,10d,8f) -> [8s,7p,6d,4f]
c    Db     : 92[Xe+4f+5d] ECP92MWB (8s,7p,6d,2f,1g) -> [6s,5p,4d,2f,1g]
c
c    K      : A. Bergner, M. Dolg, W. Kuechle, H. Stoll, H. Preuss,
c             Mol. Phys. 80,  1431 (1993).
c    Ca     : M. Kaupp, P. v. R. Schleyer, H. Stoll, H. Preuss,
c             J. Chem. Phys. 94, 1360 (1991).
c    Rf - Db: M. Dolg, H. Stoll, H. Preuss, R.M. Pitzer,
c             J. Phys. Chem. 97, 5852   (1993).
c   ******************************************************************
      dimension igau(25,10), itypes(25,10)
      dimension kind(10)
      data kind/9,10,15,14,9,17,17,14,16,25/
      data igau /
     + 3,1,1,1,1,3,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 3,1,1,1,3,1,1,1,3,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 3,1,1,1,1,1,2,2,1,1,1,4,1,1,1,0,0,0,0,0,0,0,0,0,0,
     + 3,1,1,1,1,1,2,2,1,1,1,4,1,1,0,0,0,0,0,0,0,0,0,0,0,
     + 4,1,1,4,1,1,3,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     +10,10,10,1,1,8,8,1,1,1,6,1,1,1,6,1,1,0,0,0,0,0,0,0,0,
     +10,10,10,1,1,7,7,1,1,1,5,1,1,1,6,1,1,0,0,0,0,0,0,0,0,
     + 2,1,1,1,1,1,1,4,1,1,2,1,1,1,0,0,0,0,0,0,0,0,0,0,0,
     + 3,1,1,1,1,1,2,2,1,1,1,1,4,1,1,1,0,0,0,0,0,0,0,0,0,
     + 7,7,7,1,1,1,1,1,6,6,1,1,1,1,1,6,6,1,1,1,1,5,1,1,1 /
c
      data itypes /
     + 1,1,1,1,1,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,2,2,2,2,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,2,2,2,2,2,3,3,3,4,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,2,2,2,2,2,3,3,3,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,2,2,2,3,3,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,2,2,2,2,2,3,3,3,3,4,4,4,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,2,2,2,2,2,3,3,3,3,4,4,4,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,2,2,2,3,3,3,3,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4 /
c
c     set values for the current ccdz  shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3,4 for s,p,d,f shell
c
      ind=0
      if(nucz.eq.19) ind=1
      if(nucz.eq.20) ind=2
      if(nucz.ge.21  .and.  nucz.le.28) ind=3
      if(nucz.ge.29  .and.  nucz.le.30) ind=4
      if(nucz.eq.37) ind=1
      if(nucz.eq.38) ind=2
      if(nucz.ge.39  .and.  nucz.le.48) ind=4
      if(nucz.eq.55) ind=1
      if(nucz.eq.56) ind=5
      if(nucz.ge.58  .and.  nucz.le.67) ind=6
      if(nucz.eq.60) ind=7
      if(nucz.ge.68  .and.  nucz.le.70) ind=7
      if(nucz.ge.72  .and.  nucz.le.78) ind=4
      if(nucz.eq.79) ind=8
      if(nucz.eq.80) ind=9
      if(nucz.ge.89  .and.  nucz.le.103) ind=10
      if(nucz.gt.103) ind = 0
c
      if (ind.eq.0) then
         call caserr2(
     +        'Stuttgart RSC ecp basis set not available')
      end if
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if(.not.odone) then
c
       igauss = igau(ipass,ind)
       ityp = itypes(ipass,ind)
      endif
      itype = ityp + 15
c
      return
      end
      subroutine strsc_2(e,s,p,d,f,n)
c
c   RSC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- basis (K-Kr) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-18
      go to (100,120,140,160,180,200,220,240,260,280,300,320,
     +       340,340,340,340,340,340),nn
c
c k   (7s,6p)  -> [5s,4p]
c
  100 continue
c
      e(   1) =          8.22336200d0
      s(   1) =          0.10414500d0
      e(   2) =          3.79721100d0
      s(   2) =         -0.43915800d0
      e(   3) =          1.33160700d0
      s(   3) =          0.05219100d0
      e(   4) =          0.66628200d0
      s(   4) =          1.00000000d0
      e(   5) =          0.27280700d0
      s(   5) =          1.00000000d0
      e(   6) =          0.03709200d0
      s(   6) =          1.00000000d0
      e(   7) =          0.01654300d0
      s(   7) =          1.00000000d0
      e(   8) =         21.60567000d0
      p(   8) =         -0.01173700d0
      e(   9) =          1.10021200d0
      p(   9) =         -0.40767500d0
      e(  10) =          0.50434500d0
      p(  10) =         -0.33329200d0
      e(  11) =          0.31786900d0
      p(  11) =          1.00000000d0
      e(  12) =          0.14815000d0
      p(  12) =          1.00000000d0
      e(  13) =          0.02213900d0
      p(  13) =          1.00000000d0
c
      go to 500
c
c ca  (6s,6p,5d)  -> [4s,4p,2d]
c
  120 continue
c
      e(   1) =         12.30752100d0
      s(   1) =          0.05874000d0
      e(   2) =          4.39315100d0
      s(   2) =         -0.40134400d0
      e(   3) =          0.93797500d0
      s(   3) =          0.59287500d0
      e(   4) =          0.42168800d0
      s(   4) =          1.00000000d0
      e(   5) =          0.05801700d0
      s(   5) =          1.00000000d0
      e(   6) =          0.02322200d0
      s(   6) =          1.00000000d0
      e(   7) =          5.97428600d0
      p(   7) =         -0.08230200d0
      e(   8) =          1.56740600d0
      p(   8) =          0.34651100d0
      e(   9) =          0.65624200d0
      p(   9) =          0.56014700d0
      e(  10) =          0.25849800d0
      p(  10) =          1.00000000d0
      e(  11) =          0.08100000d0
      p(  11) =          1.00000000d0
      e(  12) =          0.03000000d0
      p(  12) =          1.00000000d0
      e(  13) =          7.23170000d0
      d(  13) =          0.05036000d0
      e(  14) =          1.96486900d0
      d(  14) =          0.17334300d0
      e(  15) =          0.62030300d0
      d(  15) =          0.30197800d0
      e(  16) =          0.18126000d0
      d(  16) =          0.43805500d0
      e(  17) =          0.04910700d0
      d(  17) =          0.46472000d0
c
      go to 500
c
c sc (8s,7p,6d,1f) -> [6s,5p,3d,1f]
c
  140 continue
c
      e(   1) =         10.00926000d0
      s(   1) =          1.00789600d0
      e(   2) =          8.47076200d0
      s(   2) =         -1.17665500d0
      e(   3) =          4.17911600d0
      s(   3) =         -0.80264700d0
      e(   4) =          1.06920800d0
      s(   4) =          1.00000000d0
      e(   5) =          0.44124800d0
      s(   5) =          1.00000000d0
      e(   6) =          0.06443200d0
      s(   6) =          1.00000000d0
      e(   7) =          0.02720000d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =         41.71184600d0
      p(   9) =          0.02091200d0
      e(  10) =          6.02601500d0
      p(  10) =         -1.00732900d0
      e(  11) =          2.71599500d0
      p(  11) =          0.25364400d0
      e(  12) =          1.05691400d0
      p(  12) =          0.79264300d0
      e(  13) =          0.37694100d0
      p(  13) =          1.00000000d0
      e(  14) =          0.07416100d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02380500d0
      p(  15) =          1.00000000d0
      e(  16) =         16.27354800d0
      d(  16) =          0.03555900d0
      e(  17) =          4.80004900d0
      d(  17) =          0.16935600d0
      e(  18) =          1.54129300d0
      d(  18) =          0.42044600d0
      e(  19) =          0.46818000d0
      d(  19) =          0.61731400d0
      e(  20) =          0.12279900d0
      d(  20) =          1.00000000d0
      e(  21) =          0.04000000d0
      d(  21) =          1.00000000d0
      e(  22) =          0.27000000d0
      f(  22) =          1.00000000d0
c
      go to 500
c
c ti  (8s,7p,6d,1f) -> [6s,5p,3d,1f]
c
  160 continue
c
      e(   1) =         10.78036500d0
      s(   1) =          1.78389200d0
      e(   2) =          9.71701300d0
      s(   2) =         -2.00068900d0
      e(   3) =          4.50775500d0
      s(   3) =         -0.75633300d0
      e(   4) =          1.24670800d0
      s(   4) =          1.00000000d0
      e(   5) =          0.50870700d0
      s(   5) =          1.00000000d0
      e(   6) =          0.07343800d0
      s(   6) =          1.00000000d0
      e(   7) =          0.03004800d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =         17.56638100d0
      p(   9) =          0.08860100d0
      e(  10) =          7.70584400d0
      p(  10) =         -1.07074600d0
      e(  11) =          3.32913800d0
      p(  11) =          0.20010900d0
      e(  12) =          1.30810400d0
      p(  12) =          0.83798600d0
      e(  13) =          0.45448200d0
      p(  13) =          1.00000000d0
      e(  14) =          0.07177200d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02378400d0
      p(  15) =          1.00000000d0
      e(  16) =         19.51919400d0
      d(  16) =          0.03581400d0
      e(  17) =          5.86461300d0
      d(  17) =          0.17237300d0
      e(  18) =          1.92803800d0
      d(  18) =          0.42513600d0
      e(  19) =          0.60656300d0
      d(  19) =          0.60259500d0
      e(  20) =          0.16396100d0
      d(  20) =          1.00000000d0
      e(  21) =          0.05000000d0
      d(  21) =          1.00000000d0
      e(  22) =          0.50000000d0
      f(  22) =          1.00000000d0
c
      go to 500
c
c v   (8s,7p,6d,1f) -> [6s,5p,3d,1f]
c
  180 continue
c
      e(   1) =         12.84320800d0
      s(   1) =          1.14064300d0
      e(   2) =         11.37575300d0
      s(   2) =         -1.21880300d0
      e(   3) =          5.40697400d0
      s(   3) =         -0.89290300d0
      e(   4) =          1.46592700d0
      s(   4) =          1.00000000d0
      e(   5) =          0.59808000d0
      s(   5) =          1.00000000d0
      e(   6) =          0.08879000d0
      s(   6) =          1.00000000d0
      e(   7) =          0.03531800d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =         31.88986800d0
      p(   9) =          0.03940700d0
      e(  10) =          8.23717800d0
      p(  10) =         -1.02260300d0
      e(  11) =          4.32837300d0
      p(  11) =          0.19275600d0
      e(  12) =          1.54052600d0
      p(  12) =          0.85116800d0
      e(  13) =          0.52808100d0
      p(  13) =          1.00000000d0
      e(  14) =          0.08996200d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02639300d0
      p(  15) =          1.00000000d0
      e(  16) =         22.68043300d0
      d(  16) =          0.03629300d0
      e(  17) =          6.86131200d0
      d(  17) =          0.17730100d0
      e(  18) =          2.27544500d0
      d(  18) =          0.43042900d0
      e(  19) =          0.73192200d0
      d(  19) =          0.58930300d0
      e(  20) =          0.20074600d0
      d(  20) =          1.00000000d0
      e(  21) =          0.06000000d0
      d(  21) =          1.00000000d0
      e(  22) =          0.77000000d0
      f(  22) =          1.00000000d0
c
      go to 500
c
c cr   (8s,7p,6d,1f) -> [6s,5p,3d,1f]
c
  200 continue
c
      e(   1) =         14.05345000d0
      s(   1) =          0.88562400d0
      e(   2) =         11.73521800d0
      s(   2) =         -1.03013200d0
      e(   3) =          5.90491500d0
      s(   3) =         -0.82672900d0
      e(   4) =          1.63466500d0
      s(   4) =          1.00000000d0
      e(   5) =          0.66293100d0
      s(   5) =          1.00000000d0
      e(   6) =          0.09780000d0
      s(   6) =          1.00000000d0
      e(   7) =          0.03770500d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =         51.31766400d0
      p(   9) =          0.02967200d0
      e(  10) =          9.32149800d0
      p(  10) =         -1.01276000d0
      e(  11) =          3.74112100d0
      p(  11) =          0.25774600d0
      e(  12) =          1.51021400d0
      p(  12) =          0.78591700d0
      e(  13) =          0.53795600d0
      p(  13) =          1.00000000d0
      e(  14) =          0.09340800d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02664500d0
      p(  15) =          1.00000000d0
      e(  16) =         26.78143900d0
      d(  16) =          0.03497000d0
      e(  17) =          8.23164000d0
      d(  17) =          0.17219500d0
      e(  18) =          2.78164500d0
      d(  18) =          0.42703200d0
      e(  19) =          0.90367800d0
      d(  19) =          0.59293900d0
      e(  20) =          0.24925800d0
      d(  20) =          1.00000000d0
      e(  21) =          0.07000000d0
      d(  21) =          1.00000000d0
      e(  22) =          1.60000000d0
      f(  22) =          1.00000000d0
c 
      go to 500
c
c mn  (8s,7p,6d,1f) -> [6s,5p,3d,1f]
c
  220 continue
c
      e(   1) =         15.56400100d0
      s(   1) =          1.09978900d0
      e(   2) =         13.28692800d0
      s(   2) =         -1.30585100d0
      e(   3) =          6.13728100d0
      s(   3) =         -0.76802400d0
      e(   4) =          1.76598300d0
      s(   4) =          1.00000000d0
      e(   5) =          0.71377400d0
      s(   5) =          1.00000000d0
      e(   6) =          0.09832800d0
      s(   6) =          1.00000000d0
      e(   7) =          0.03709700d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =         27.43206100d0
      p(   9) =          0.08385100d0
      e(  10) =         11.36687300d0
      p(  10) =         -1.06496500d0
      e(  11) =          4.45254000d0
      p(  11) =          0.20265200d0
      e(  12) =          1.85345900d0
      p(  12) =          0.83175400d0
      e(  13) =          0.64518000d0
      p(  13) =          1.00000000d0
      e(  14) =          0.10304400d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02829600d0
      p(  15) =          1.00000000d0
      e(  16) =         29.51422300d0
      d(  16) =          0.03716200d0
      e(  17) =          8.96282400d0
      d(  17) =          0.18274500d0
      e(  18) =          3.02796700d0
      d(  18) =          0.43560700d0
      e(  19) =          0.98329200d0
      d(  19) =          0.57705300d0
      e(  20) =          0.27032500d0
      d(  20) =          1.00000000d0
      e(  21) =          0.07000000d0
      d(  21) =          1.00000000d0
      e(  22) =          1.80000000d0
      f(  22) =          1.00000000d0
c
      go to 500
c
c fe  (8s,7p,6d,1f) -> [6s,5p,3d,1f]
c
  240 continue
c
      e(   1) =         20.51302800d0
      s(   1) =          0.23471400d0
      e(   2) =          9.77679200d0
      s(   2) =         -0.87752700d0
      e(   3) =          4.57359900d0
      s(   3) =         -0.34163600d0
      e(   4) =          1.94991000d0
      s(   4) =          1.00000000d0
      e(   5) =          0.76648800d0
      s(   5) =          1.00000000d0
      e(   6) =          0.10079800d0
      s(   6) =          1.00000000d0
      e(   7) =          0.03751600d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =         63.12532600d0
      p(   9) =          0.02714700d0
      e(  10) =         11.65685500d0
      p(  10) =         -1.01187500d0
      e(  11) =          5.17866100d0
      p(  11) =          0.21516800d0
      e(  12) =          2.03553200d0
      p(  12) =          0.82509500d0
      e(  13) =          0.70881800d0
      p(  13) =          1.00000000d0
      e(  14) =          0.11016800d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02944400d0
      p(  15) =          1.00000000d0
      e(  16) =         33.66679000d0
      d(  16) =          0.03652900d0
      e(  17) =         10.23569500d0
      d(  17) =          0.18282500d0
      e(  18) =          3.46648800d0
      d(  18) =          0.43706900d0
      e(  19) =          1.12729600d0
      d(  19) =          0.57517800d0
      e(  20) =          0.30824700d0
      d(  20) =          1.00000000d0
      e(  21) =          0.08000000d0
      d(  21) =          1.00000000d0
      e(  22) =          2.00000000d0
      f(  22) =          1.00000000d0
c
      go to 500
c
c co  (8s,7p,6d,1f) -> [6s,5p,3d,1f]
c
  260 continue
c
      e(   1) =         20.90800100d0
      s(   1) =          0.39805300d0
      e(   2) =         13.90623400d0
      s(   2) =         -0.64905200d0
      e(   3) =          7.32854300d0
      s(   3) =         -0.72345300d0
      e(   4) =          2.13632400d0
      s(   4) =          1.00000000d0
      e(   5) =          0.85282200d0
      s(   5) =          1.00000000d0
      e(   6) =          0.10669200d0
      s(   6) =          1.00000000d0
      e(   7) =          0.03934600d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =         67.03444300d0
      p(   9) =          0.02937000d0
      e(  10) =         13.26233400d0
      p(  10) =         -1.01362600d0
      e(  11) =          5.69065000d0
      p(  11) =          0.20386500d0
      e(  12) =          2.27194000d0
      p(  12) =          0.83364500d0
      e(  13) =          0.78891100d0
      p(  13) =          1.00000000d0
      e(  14) =          0.11835500d0
      p(  14) =          1.00000000d0
      e(  15) =          0.03059400d0
      p(  15) =          1.00000000d0
      e(  16) =         36.84052000d0
      d(  16) =          0.03805600d0
      e(  17) =         11.17367500d0
      d(  17) =          0.18892500d0
      e(  18) =          3.79756400d0
      d(  18) =          0.44105100d0
      e(  19) =          1.23926200d0
      d(  19) =          0.56569700d0
      e(  20) =          0.33940000d0
      d(  20) =          1.00000000d0
      e(  21) =          0.09000000d0
      d(  21) =          1.00000000d0
      e(  22) =          2.20000000d0
      f(  22) =          1.00000000d0
c
      go to 500
c
c ni  (8s,7p,6d,1f) -> [6s,5p,3d,1f]
c
  280 continue
c
      e(   1) =         23.45799100d0
      s(   1) =          0.34542400d0
      e(   2) =         14.86939200d0
      s(   2) =         -0.59501200d0
      e(   3) =          8.05415400d0
      s(   3) =         -0.72484900d0
      e(   4) =          2.31982400d0
      s(   4) =          1.00000000d0
      e(   5) =          0.92346200d0
      s(   5) =          1.00000000d0
      e(   6) =          0.10995500d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04013400d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =         78.03878000d0
      p(   9) =          0.02700800d0
      e(  10) =         14.77444000d0
      p(  10) =         -1.01208100d0
      e(  11) =          6.15135200d0
      p(  11) =          0.20219500d0
      e(  12) =          2.49642100d0
      p(  12) =          0.83392000d0
      e(  13) =          0.86670200d0
      p(  13) =          1.00000000d0
      e(  14) =          0.12649900d0
      p(  14) =          1.00000000d0
      e(  15) =          0.03178400d0
      p(  15) =          1.00000000d0
      e(  16) =         40.78904800d0
      d(  16) =          0.03842500d0
      e(  17) =         12.34760100d0
      d(  17) =          0.19149800d0
      e(  18) =          4.20704900d0
      d(  18) =          0.44307500d0
      e(  19) =          1.37541300d0
      d(  19) =          0.56121600d0
      e(  20) =          0.37614700d0
      d(  20) =          1.00000000d0
      e(  21) =          0.09000000d0
      d(  21) =          1.00000000d0
      e(  22) =          2.40000000d0
      f(  22) =          1.00000000d0
c
      go to 500
c
c cu  (8s,7p,6d) -> [6s,5p,3d]
c
  300 continue
c
      e(   1) =         27.69632000d0
      s(   1) =          0.23113200d0
      e(   2) =         13.50535000d0
      s(   2) =         -0.65681100d0
      e(   3) =          8.81535500d0
      s(   3) =         -0.54587500d0
      e(   4) =          2.38080500d0
      s(   4) =          1.00000000d0
      e(   5) =          0.95261600d0
      s(   5) =          1.00000000d0
      e(   6) =          0.11266200d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04048600d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =         93.50432700d0
      p(   9) =          0.02282900d0
      e(  10) =         16.28546400d0
      p(  10) =         -1.00951300d0
      e(  11) =          5.99423600d0
      p(  11) =          0.24645000d0
      e(  12) =          2.53687500d0
      p(  12) =          0.79202400d0
      e(  13) =          0.89793400d0
      p(  13) =          1.00000000d0
      e(  14) =          0.13172900d0
      p(  14) =          1.00000000d0
      e(  15) =          0.03087800d0
      p(  15) =          1.00000000d0
      e(  16) =         41.22500600d0
      d(  16) =          0.04469400d0
      e(  17) =         12.34325000d0
      d(  17) =          0.21210600d0
      e(  18) =          4.20192000d0
      d(  18) =          0.45342300d0
      e(  19) =          1.37982500d0
      d(  19) =          0.53346500d0
      e(  20) =          0.38345300d0
      d(  20) =          1.00000000d0
      e(  21) =          0.10000000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c zn  (8s,7p,6d) -> [6s,5p,3d]
c
  320 continue
c
      e(   1) =         30.32412700d0
      s(   1) =          0.21914300d0
      e(   2) =         16.31668200d0
      s(   2) =         -0.23255600d0
      e(   3) =         11.40814800d0
      s(   3) =         -0.95468500d0
      e(   4) =          2.56949200d0
      s(   4) =          1.00000000d0
      e(   5) =          1.06259500d0
      s(   5) =          1.00000000d0
      e(   6) =          0.15155300d0
      s(   6) =          1.00000000d0
      e(   7) =          0.05274700d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =        111.82498000d0
      p(   9) =          0.02327700d0
      e(  10) =         19.13191000d0
      p(  10) =         -1.00953900d0
      e(  11) =          5.46883800d0
      p(  11) =          0.32015100d0
      e(  12) =          2.50567500d0
      p(  12) =          0.71808500d0
      e(  13) =          0.94186800d0
      p(  13) =          1.00000000d0
      e(  14) =          0.17113100d0
      p(  14) =          1.00000000d0
      e(  15) =          0.04998600d0
      p(  15) =          1.00000000d0
      e(  16) =         44.64562900d0
      d(  16) =          0.04724900d0
      e(  17) =         13.43837700d0
      d(  17) =          0.21892600d0
      e(  18) =          4.68200000d0
      d(  18) =          0.45251200d0
      e(  19) =          1.60321100d0
      d(  19) =          0.51857600d0
      e(  20) =          0.48276600d0
      d(  20) =          1.00000000d0
      e(  21) =          0.11000000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c ga  - kr
c
  340 call caserr2('No Stuttgart RSC ecp basis for Ga - Kr')
c
c
500   return
      end
      subroutine strsc_3(e,s,p,d,n)
c
c   RSC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- basis (Rb-Xe) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
c
      nn = n-36
      go to (100,120,140,160,180,200,220,240,260,280,300,320,
     +       340,340,340,340,340,340),nn
c
c rb   
c
  100 continue
c
      e(   1) =          4.72746100d0
      s(   1) =          0.28132900d0
      e(   2) =          2.93082500d0
      s(   2) =         -0.67489200d0
      e(   3) =          0.60184900d0
      s(   3) =          0.45877900d0
      e(   4) =          0.46624400d0
      s(   4) =          1.00000000d0
      e(   5) =          0.24646300d0
      s(   5) =          1.00000000d0
      e(   6) =          0.05337900d0
      s(   6) =          1.00000000d0
      e(   7) =          0.02101800d0
      s(   7) =          1.00000000d0
      e(   8) =          5.60847000d0
      p(   8) =          0.04980500d0
      e(   9) =          3.45272700d0
      p(   9) =         -0.16644100d0
      e(  10) =          0.75437400d0
      p(  10) =          0.43483400d0
      e(  11) =          0.32797400d0
      p(  11) =          1.00000000d0
      e(  12) =          0.14179700d0
      p(  12) =          1.00000000d0
      e(  13) =          0.02050600d0
      p(  13) =          1.00000000d0
c
      go to 500
c
c sr   
c
  120 continue
c
      e(   1) =          5.87915700d0
      s(   1) =          0.19670900d0
      e(   2) =          3.09248200d0
      s(   2) =         -0.62589800d0
      e(   3) =          0.64466700d0
      s(   3) =          0.73572300d0
      e(   4) =          0.29887600d0
      s(   4) =          1.00000000d0
      e(   5) =          0.05727600d0
      s(   5) =          1.00000000d0
      e(   6) =          0.02387000d0
      s(   6) =          1.00000000d0
      e(   7) =          2.43247200d0
      p(   7) =         -0.37489900d0
      e(   8) =          1.66423400d0
      p(   8) =          0.38761500d0
      e(   9) =          0.56998900d0
      p(   9) =          0.65583800d0
      e(  10) =          0.22071800d0
      p(  10) =          1.00000000d0
      e(  11) =          0.06762900d0
      p(  11) =          1.00000000d0
      e(  12) =          0.02672700d0
      p(  12) =          1.00000000d0
      e(  13) =          3.61808100d0
      d(  13) =         -0.00750100d0
      e(  14) =          0.99665600d0
      d(  14) =          0.10809800d0
      e(  15) =          0.39073500d0
      d(  15) =          0.27854000d0
      e(  16) =          0.12277000d0
      d(  16) =          0.47731800d0
      e(  17) =          0.03665500d0
      d(  17) =          0.44818300d0
c
      go to 500
c
c y   
c
  140 continue
c
      e(   1) =          5.13295800d0
      s(   1) =         -1.38751070d0
      e(   2) =          4.24019200d0
      s(   2) =          1.94451280d0
      e(   3) =          1.29828000d0
      s(   3) =          0.44164340d0
      e(   4) =          0.83211300d0
      s(   4) =          1.00000000d0
      e(   5) =          0.34990500d0
      s(   5) =          1.00000000d0
      e(   6) =          0.06655100d0
      s(   6) =          1.00000000d0
      e(   7) =          0.02865900d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =          2.72792000d0
      p(   9) =         -3.58418460d0
      e(  10) =          1.97905000d0
      p(  10) =          3.02120570d0
      e(  11) =          0.87347600d0
      p(  11) =          0.46385860d0
      e(  12) =          0.44106700d0
      p(  12) =          0.57085540d0
      e(  13) =          0.18381500d0
      p(  13) =          1.00000000d0
      e(  14) =          0.06056700d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02223600d0
      p(  15) =          1.00000000d0
      e(  16) =          2.90070900d0
      d(  16) =         -0.08382050d0
      e(  17) =          2.09979200d0
      d(  17) =          0.15258700d0
      e(  18) =          0.61825200d0
      d(  18) =          0.47926810d0
      e(  19) =          0.20018400d0
      d(  19) =          0.60075040d0
      e(  20) =          0.06118900d0
      d(  20) =          1.00000000d0
      e(  21) =          0.02000000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c zr   
c
  160 continue
c
      e(   1) =          5.87378900d0
      s(   1) =         -0.97366300d0
      e(   2) =          4.28727000d0
      s(   2) =          1.70918220d0
      e(   3) =          1.46413700d0
      s(   3) =          0.24383100d0
      e(   4) =          0.83124500d0
      s(   4) =          1.00000000d0
      e(   5) =          0.36233500d0
      s(   5) =          1.00000000d0
      e(   6) =          0.07935700d0
      s(   6) =          1.00000000d0
      e(   7) =          0.03392000d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01100000d0
      s(   8) =          1.00000000d0
      e(   9) =          2.87422400d0
      p(   9) =         -4.21810130d0
      e(  10) =          2.11990100d0
      p(  10) =          4.04794310d0
      e(  11) =          0.85136400d0
      p(  11) =          0.57094510d0
      e(  12) =          0.43729200d0
      p(  12) =          0.46210800d0
      e(  13) =          0.20290400d0
      p(  13) =          1.00000000d0
      e(  14) =          0.06325900d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02252300d0
      p(  15) =          1.00000000d0
      e(  16) =          2.58013700d0
      d(  16) =         -0.09321310d0
      e(  17) =          1.85539600d0
      d(  17) =          0.22135700d0
      e(  18) =          0.68075400d0
      d(  18) =          0.46844270d0
      e(  19) =          0.25669100d0
      d(  19) =          0.53919500d0
      e(  20) =          0.08940000d0
      d(  20) =          1.00000000d0
      e(  21) =          0.03000000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c nb   
c
  180 continue
c
      e(   1) =          6.56630100d0
      s(   1) =         -0.85826540d0
      e(   2) =          4.58643800d0
      s(   2) =          1.30416720d0
      e(   3) =          3.75377000d0
      s(   3) =          0.50690430d0
      e(   4) =          0.88987100d0
      s(   4) =          1.00000000d0
      e(   5) =          0.40713800d0
      s(   5) =          1.00000000d0
      e(   6) =          0.09427100d0
      s(   6) =          1.00000000d0
      e(   7) =          0.03987900d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01100000d0
      s(   8) =          1.00000000d0
      e(   9) =          3.07006300d0
      p(   9) =         -3.90443150d0
      e(  10) =          2.23796400d0
      p(  10) =          4.06880700d0
      e(  11) =          0.85225500d0
      p(  11) =          0.67139100d0
      e(  12) =          0.50443600d0
      p(  12) =          0.34743650d0
      e(  13) =          0.26680000d0
      p(  13) =          1.00000000d0
      e(  14) =          0.06873200d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02344400d0
      p(  15) =          1.00000000d0
      e(  16) =          4.05356300d0
      d(  16) =         -0.02042010d0
      e(  17) =          1.65260000d0
      d(  17) =          0.20898540d0
      e(  18) =          0.70685900d0
      d(  18) =          0.47055150d0
      e(  19) =          0.28636700d0
      d(  19) =          0.47588600d0
      e(  20) =          0.10875700d0
      d(  20) =          1.00000000d0
      e(  21) =          0.03300000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c mo   
c
  200 continue
c
      e(   1) =          7.20338000d0
      s(   1) =         -0.82629730d0
      e(   2) =          5.05229500d0
      s(   2) =          1.46756160d0
      e(   3) =          2.91353300d0
      s(   3) =          0.31895490d0
      e(   4) =          1.02899300d0
      s(   4) =          1.00000000d0
      e(   5) =          0.46953400d0
      s(   5) =          1.00000000d0
      e(   6) =          0.11001400d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04611500d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01500000d0
      s(   8) =          1.00000000d0
      e(   9) =          3.15186600d0
      p(   9) =         -4.73814350d0
      e(  10) =          2.45348200d0
      p(  10) =          5.01904000d0
      e(  11) =          0.87877300d0
      p(  11) =          0.74936290d0
      e(  12) =          0.49079100d0
      p(  12) =          0.27056970d0
      e(  13) =          0.28471400d0
      p(  13) =          1.00000000d0
      e(  14) =          0.07118200d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02360700d0
      p(  15) =          1.00000000d0
      e(  16) =          5.03477000d0
      d(  16) =         -0.02394300d0
      e(  17) =          1.80214900d0
      d(  17) =          0.21945760d0
      e(  18) =          0.80725000d0
      d(  18) =          0.46117140d0
      e(  19) =          0.33900500d0
      d(  19) =          0.46712100d0
      e(  20) =          0.12834200d0
      d(  20) =          1.00000000d0
      e(  21) =          0.04300000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c tc   
c
  220 continue
c
      e(   1) =          7.43440200d0
      s(   1) =         -1.11251800d0
      e(   2) =          5.55132700d0
      s(   2) =          1.81449980d0
      e(   3) =          3.02308600d0
      s(   3) =          0.25692920d0
      e(   4) =          1.08466900d0
      s(   4) =          1.00000000d0
      e(   5) =          0.49258500d0
      s(   5) =          1.00000000d0
      e(   6) =          0.11389600d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04688700d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01600000d0
      s(   8) =          1.00000000d0
      e(   9) =          3.44900500d0
      p(   9) =         -4.81613810d0
      e(  10) =          2.69273700d0
      p(  10) =          5.08660540d0
      e(  11) =          0.95948400d0
      p(  11) =          0.74490720d0
      e(  12) =          0.48521300d0
      p(  12) =          0.28268630d0
      e(  13) =          0.28149000d0
      p(  13) =          1.00000000d0
      e(  14) =          0.06837100d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02261300d0
      p(  15) =          1.00000000d0
      e(  16) =          5.12226800d0
      d(  16) =         -0.03323760d0
      e(  17) =          1.95401500d0
      d(  17) =          0.24673870d0
      e(  18) =          0.85475600d0
      d(  18) =          0.48023800d0
      e(  19) =          0.36058100d0
      d(  19) =          0.42886640d0
      e(  20) =          0.14127500d0
      d(  20) =          1.00000000d0
      e(  21) =          0.04700000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c ru   
c
  240 continue
c
      e(   1) =          7.93657000d0
      s(   1) =         -1.11966560d0
      e(   2) =          5.98424500d0
      s(   2) =          1.44532930d0
      e(   3) =          4.88222000d0
      s(   3) =          0.62616530d0
      e(   4) =          1.14462400d0
      s(   4) =          1.00000000d0
      e(   5) =          0.52301700d0
      s(   5) =          1.00000000d0
      e(   6) =          0.11757300d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04805000d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01600000d0
      s(   8) =          1.00000000d0
      e(   9) =          3.75460900d0
      p(   9) =         -4.72265650d0
      e(  10) =          2.91657100d0
      p(  10) =          4.99090840d0
      e(  11) =          1.04867500d0
      p(  11) =          0.72854670d0
      e(  12) =          0.50732000d0
      p(  12) =          0.30390430d0
      e(  13) =          0.26739800d0
      p(  13) =          1.00000000d0
      e(  14) =          0.06974800d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02292700d0
      p(  15) =          1.00000000d0
      e(  16) =          6.00991300d0
      d(  16) =         -0.03271600d0
      e(  17) =          2.10428000d0
      d(  17) =          0.26573920d0
      e(  18) =          0.92150000d0
      d(  18) =          0.48123980d0
      e(  19) =          0.38859800d0
      d(  19) =          0.40997780d0
      e(  20) =          0.15283600d0
      d(  20) =          1.00000000d0
      e(  21) =          0.05100000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c rh   
c
  260 continue
c
      e(   1) =          7.91774400d0
      s(   1) =         -2.41557750d0
      e(   2) =          6.84120700d0
      s(   2) =          3.09873820d0
      e(   3) =          2.95984000d0
      s(   3) =          0.28212560d0
      e(   4) =          1.33434100d0
      s(   4) =          1.00000000d0
      e(   5) =          0.59881000d0
      s(   5) =          1.00000000d0
      e(   6) =          0.12189400d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04945200d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01600000d0
      s(   8) =          1.00000000d0
      e(   9) =          4.13607900d0
      p(   9) =         -3.34435450d0
      e(  10) =          2.94628100d0
      p(  10) =          3.70374400d0
      e(  11) =          1.12230400d0
      p(  11) =          0.74622580d0
      e(  12) =          0.66617700d0
      p(  12) =          0.26988330d0
      e(  13) =          0.36574300d0
      p(  13) =          1.00000000d0
      e(  14) =          0.07668600d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02417000d0
      p(  15) =          1.00000000d0
      e(  16) =          7.03289200d0
      d(  16) =         -0.01616040d0
      e(  17) =          2.30981900d0
      d(  17) =          0.27639870d0
      e(  18) =          0.99822800d0
      d(  18) =          0.48500260d0
      e(  19) =          0.41705700d0
      d(  19) =          0.39301990d0
      e(  20) =          0.16444700d0
      d(  20) =          1.00000000d0
      e(  21) =          0.05500000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c pd   
c
  280 continue
c
      e(   1) =          8.47564000d0
      s(   1) =         -2.16424970d0
      e(   2) =          7.16571700d0
      s(   2) =          2.89282860d0
      e(   3) =          3.18211000d0
      s(   3) =          0.23395640d0
      e(   4) =          1.40635700d0
      s(   4) =          1.00000000d0
      e(   5) =          0.62392100d0
      s(   5) =          1.00000000d0
      e(   6) =          0.12330300d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04936000d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01600000d0
      s(   8) =          1.00000000d0
      e(   9) =          4.24609700d0
      p(   9) =         -5.25030250d0
      e(  10) =          3.39259400d0
      p(  10) =          5.55278500d0
      e(  11) =          1.21618500d0
      p(  11) =          0.75773150d0
      e(  12) =          0.63962400d0
      p(  12) =          0.26600460d0
      e(  13) =          0.37265700d0
      p(  13) =          1.00000000d0
      e(  14) =          0.07917500d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02475400d0
      p(  15) =          1.00000000d0
      e(  16) =          7.16961200d0
      d(  16) =         -0.01850040d0
      e(  17) =          2.56126300d0
      d(  17) =          0.27696900d0
      e(  18) =          1.10966900d0
      d(  18) =          0.48590350d0
      e(  19) =          0.46229600d0
      d(  19) =          0.39306510d0
      e(  20) =          0.18152500d0
      d(  20) =          1.00000000d0
      e(  21) =          0.06000000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c ag   
c
  300 continue
c
      e(   1) =          9.08844200d0
      s(   1) =         -1.96481320d0
      e(   2) =          7.54073100d0
      s(   2) =          2.73321940d0
      e(   3) =          2.79400500d0
      s(   3) =          0.19911480d0
      e(   4) =          1.48015800d0
      s(   4) =          1.00000000d0
      e(   5) =          0.65385100d0
      s(   5) =          1.00000000d0
      e(   6) =          0.12448800d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04926400d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01600000d0
      s(   8) =          1.00000000d0
      e(   9) =          4.45124000d0
      p(   9) =         -6.08337800d0
      e(  10) =          3.67526300d0
      p(  10) =          6.41685430d0
      e(  11) =          1.29128800d0
      p(  11) =          0.75397350d0
      e(  12) =          0.65257800d0
      p(  12) =          0.27305970d0
      e(  13) =          0.36703600d0
      p(  13) =          1.00000000d0
      e(  14) =          0.07569400d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02372300d0
      p(  15) =          1.00000000d0
      e(  16) =          7.99473000d0
      d(  16) =         -0.01638760d0
      e(  17) =          2.78477300d0
      d(  17) =          0.28141070d0
      e(  18) =          1.20974400d0
      d(  18) =          0.48632640d0
      e(  19) =          0.50539300d0
      d(  19) =          0.38672580d0
      e(  20) =          0.19885100d0
      d(  20) =          1.00000000d0
      e(  21) =          0.06600000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c cd   
c
  320 continue
c
      e(   1) =          9.72701100d0
      s(   1) =         -1.78642590d0
      e(   2) =          7.83752300d0
      s(   2) =          2.57789480d0
      e(   3) =          5.08919400d0
      s(   3) =          0.16011710d0
      e(   4) =          1.55332600d0
      s(   4) =          1.00000000d0
      e(   5) =          0.71407900d0
      s(   5) =          1.00000000d0
      e(   6) =          0.15078400d0
      s(   6) =          1.00000000d0
      e(   7) =          0.05746700d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01900000d0
      s(   8) =          1.00000000d0
      e(   9) =          4.74271600d0
      p(   9) =         -6.23119940d0
      e(  10) =          3.93665500d0
      p(  10) =          6.57419200d0
      e(  11) =          1.38039100d0
      p(  11) =          0.74972650d0
      e(  12) =          0.66848500d0
      p(  12) =          0.28110820d0
      e(  13) =          0.36342300d0
      p(  13) =          1.00000000d0
      e(  14) =          0.10625300d0
      p(  14) =          1.00000000d0
      e(  15) =          0.03664400d0
      p(  15) =          1.00000000d0
      e(  16) =          8.46934100d0
      d(  16) =         -0.01636060d0
      e(  17) =          3.02423100d0
      d(  17) =          0.28647280d0
      e(  18) =          1.31636700d0
      d(  18) =          0.48685180d0
      e(  19) =          0.55639300d0
      d(  19) =          0.37941110d0
      e(  20) =          0.22385600d0
      d(  20) =          1.00000000d0
      e(  21) =          0.07500000d0
      d(  21) =          1.00000000d0
c
      go to 500
c
c in  
c
  340 call caserr2('No Stuttgart RSC ecp basis for In - Xe')
c
 500  return
      end
      subroutine strsc_4(e,s,p,d,f,n)
c
c   RSC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- ECP basis (Cs-Rn) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-54
      go to (100,120,140,
     +       160,180,200,220,240,260,280,300,320,340,360,380,400,620,
     +       440,460,480,500,520,540,560,580,600,620,620,620,620,620,
     +       620),nn
c
c cs   
c
  100 continue
c
      e(   1) =          5.80065900d0
      s(   1) =          0.12734500d0
      e(   2) =          4.29843200d0
      s(   2) =         -0.34990100d0
      e(   3) =          1.80722100d0
      s(   3) =          0.70204200d0
      e(   4) =          0.38892200d0
      s(   4) =          1.00000000d0
      e(   5) =          0.17565200d0
      s(   5) =          1.00000000d0
      e(   6) =          0.03106300d0
      s(   6) =          1.00000000d0
      e(   7) =          0.01315200d0
      s(   7) =          1.00000000d0
      e(   8) =          3.73837600d0
      p(   8) =          0.07097100d0
      e(   9) =          2.11024700d0
      p(   9) =         -0.25305700d0
      e(  10) =          0.55888300d0
      p(  10) =          0.30057600d0
      e(  11) =          0.28182500d0
      p(  11) =          1.00000000d0
      e(  12) =          0.11999100d0
      p(  12) =          1.00000000d0
      e(  13) =          0.01575000d0
      p(  13) =          1.00000000d0
c
      go to 800
c
c ba   
c
  120 continue
c
      e(   1) =          2.39619000d0
      s(   1) =         -5.92889500d0
      e(   2) =          2.24330500d0
      s(   2) =          6.64693400d0
      e(   3) =          0.71740200d0
      s(   3) =         -0.55143700d0
      e(   4) =          0.27844600d0
      s(   4) =         -0.56880300d0
      e(   5) =          0.04318800d0
      s(   5) =          1.00000000d0
      e(   6) =          0.01979800d0
      s(   6) =          1.00000000d0
      e(   7) =          2.92674200d0
      p(   7) =          0.76335900d0
      e(   8) =          2.52071800d0
      p(   8) =         -1.02201400d0
      e(   9) =          0.52409500d0
      p(   9) =          0.64983600d0
      e(  10) =          0.20342800d0
      p(  10) =          0.52844600d0
      e(  11) =          0.04799600d0
      p(  11) =          1.00000000d0
      e(  12) =          0.02009500d0
      p(  12) =          1.00000000d0
      e(  13) =          0.96631500d0
      d(  13) =         -0.90893800d0
      e(  14) =          0.89382800d0
      d(  14) =          0.94724000d0
      e(  15) =          0.27319500d0
      d(  15) =          0.32205700d0
      e(  16) =          0.10389100d0
      d(  16) =          0.47326000d0
      e(  17) =          0.03557800d0
      d(  17) =          0.36597700d0
      e(  18) =          0.69700000d0
      f(  18) =          1.00000000d0
c
      go to 800
c
c la   
c
  140 call caserr2('No Stuttgart RSC ecp basis for La')
c
      go to 800
c
c ce   
c
  160 continue
c
      e(   1) =       3898.59830000d0
      s(   1) =          0.00013970d0
      e(   2) =        587.56214000d0
      s(   2) =          0.00072520d0
      e(   3) =         56.22895700d0
      s(   3) =          0.07107830d0
      e(   4) =         40.16354000d0
      s(   4) =         -0.37917800d0
      e(   5) =         28.68824300d0
      s(   5) =          0.64059940d0
      e(   6) =         11.67211500d0
      s(   6) =         -0.97247020d0
      e(   7) =          3.04133300d0
      s(   7) =          0.96978000d0
      e(   8) =          1.56771300d0
      s(   8) =          0.42892250d0
      e(   9) =          0.59583000d0
      s(   9) =          0.02055450d0
      e(  10) =          0.26355300d0
      s(  10) =         -0.00223240d0
      e(  11) =       3898.59830000d0
      s(  11) =         -0.00006900d0
      e(  12) =        587.56214000d0
      s(  12) =         -0.00040850d0
      e(  13) =         56.22895700d0
      s(  13) =         -0.02640380d0
      e(  14) =         40.16354000d0
      s(  14) =          0.15336130d0
      e(  15) =         28.68824300d0
      s(  15) =         -0.27909240d0
      e(  16) =         11.67211500d0
      s(  16) =          0.49017450d0
      e(  17) =          3.04133300d0
      s(  17) =         -0.70069850d0
      e(  18) =          1.56771300d0
      s(  18) =         -0.51493310d0
      e(  19) =          0.59583000d0
      s(  19) =          0.78569350d0
      e(  20) =          0.26355300d0
      s(  20) =          0.63573450d0
      e(  21) =       3898.59830000d0
      s(  21) =          0.00001960d0
      e(  22) =        587.56214000d0
      s(  22) =          0.00011570d0
      e(  23) =         56.22895700d0
      s(  23) =          0.00737990d0
      e(  24) =         40.16354000d0
      s(  24) =         -0.04275480d0
      e(  25) =         28.68824300d0
      s(  25) =          0.07796250d0
      e(  26) =         11.67211500d0
      s(  26) =         -0.13885850d0
      e(  27) =          3.04133300d0
      s(  27) =          0.21118500d0
      e(  28) =          1.56771300d0
      s(  28) =          0.16348300d0
      e(  29) =          0.59583000d0
      s(  29) =         -0.30330910d0
      e(  30) =          0.26355300d0
      s(  30) =         -0.44029860d0
      e(  31) =          0.02067600d0
      s(  31) =          1.00000000d0
      e(  32) =          0.04895200d0
      s(  32) =          1.00000000d0
      e(  33) =        228.14544000d0
      p(  33) =         -0.00077430d0
      e(  34) =         28.77645300d0
      p(  34) =          0.00684900d0
      e(  35) =         20.38080400d0
      p(  35) =         -0.19584540d0
      e(  36) =         14.55771700d0
      p(  36) =          0.41690990d0
      e(  37) =          4.13703400d0
      p(  37) =         -0.53956830d0
      e(  38) =          2.15984800d0
      p(  38) =         -0.52377250d0
      e(  39) =          1.01808300d0
      p(  39) =         -0.11545380d0
      e(  40) =          0.55417000d0
      p(  40) =          0.00387960d0
      e(  41) =        228.14544000d0
      p(  41) =         -0.00031790d0
      e(  42) =         28.77645300d0
      p(  42) =         -0.00520340d0
      e(  43) =         20.38080400d0
      p(  43) =         -0.05664680d0
      e(  44) =         14.55771700d0
      p(  44) =          0.15715660d0
      e(  45) =          4.13703400d0
      p(  45) =         -0.29049120d0
      e(  46) =          2.15984800d0
      p(  46) =         -0.30056880d0
      e(  47) =          1.01808300d0
      p(  47) =          0.08317600d0
      e(  48) =          0.55417000d0
      p(  48) =          0.52410620d0
      e(  49) =          0.11071000d0
      p(  49) =          1.00000000d0
      e(  50) =          0.26364100d0
      p(  50) =          1.00000000d0
      e(  51) =          0.05000000d0
      p(  51) =          1.00000000d0
      e(  52) =         55.99945800d0
      d(  52) =          0.00464120d0
      e(  53) =         11.83002300d0
      d(  53) =         -0.13250350d0
      e(  54) =          8.35871600d0
      d(  54) =          0.23830960d0
      e(  55) =          3.93891300d0
      d(  55) =          0.45369990d0
      e(  56) =          2.00383900d0
      d(  56) =          0.38580690d0
      e(  57) =          1.00457700d0
      d(  57) =          0.14439740d0
      e(  58) =          0.14243000d0
      d(  58) =          1.00000000d0
      e(  59) =          0.46585300d0
      d(  59) =          1.00000000d0
      e(  60) =          0.04000000d0
      d(  60) =          1.00000000d0
      e(  61) =         65.49671100d0
      f(  61) =         -0.00841580d0
      e(  62) =         24.73690700d0
      f(  62) =         -0.05824770d0
      e(  63) =         10.44307300d0
      f(  63) =         -0.16141870d0
      e(  64) =          4.65883200d0
      f(  64) =         -0.28572500d0
      e(  65) =          2.09130400d0
      f(  65) =         -0.34994570d0
      e(  66) =          0.91932100d0
      f(  66) =         -0.31362480d0
      e(  67) =          0.38133100d0
      f(  67) =          1.00000000d0
      e(  68) =          0.14040000d0
      f(  68) =          1.00000000d0
c
      go to 800
c
c pr   
c
  180 continue
c
      e(   1) =       3975.17730000d0
      s(   1) =          0.00023730d0
      e(   2) =        598.75707000d0
      s(   2) =          0.00124040d0
      e(   3) =         66.33791900d0
      s(   3) =          0.03818550d0
      e(   4) =         41.44061100d0
      s(   4) =         -0.31031780d0
      e(   5) =         29.60043600d0
      s(   5) =          0.60112880d0
      e(   6) =         12.23133300d0
      s(   6) =         -0.96678710d0
      e(   7) =          3.21510100d0
      s(   7) =          0.96465610d0
      e(   8) =          1.65636500d0
      s(   8) =          0.43483770d0
      e(   9) =          0.62019200d0
      s(   9) =          0.02052990d0
      e(  10) =          0.27366600d0
      s(  10) =         -0.00229070d0
      e(  11) =       3975.17730000d0
      s(  11) =         -0.00012230d0
      e(  12) =        598.75707000d0
      s(  12) =         -0.00070660d0
      e(  13) =         66.33791900d0
      s(  13) =         -0.01420370d0
      e(  14) =         41.44061100d0
      s(  14) =          0.12585090d0
      e(  15) =         29.60043600d0
      s(  15) =         -0.26202780d0
      e(  16) =         12.23133300d0
      s(  16) =          0.48797560d0
      e(  17) =          3.21510100d0
      s(  17) =         -0.70273920d0
      e(  18) =          1.65636500d0
      s(  18) =         -0.50424570d0
      e(  19) =          0.62019200d0
      s(  19) =          0.78757630d0
      e(  20) =          0.27366600d0
      s(  20) =          0.62560020d0
      e(  21) =       3975.17730000d0
      s(  21) =          0.00003450d0
      e(  22) =        598.75707000d0
      s(  22) =          0.00019900d0
      e(  23) =         66.33791900d0
      s(  23) =          0.00392140d0
      e(  24) =         41.44061100d0
      s(  24) =         -0.03462240d0
      e(  25) =         29.60043600d0
      s(  25) =          0.07230510d0
      e(  26) =         12.23133300d0
      s(  26) =         -0.13666060d0
      e(  27) =          3.21510100d0
      s(  27) =          0.20923820d0
      e(  28) =          1.65636500d0
      s(  28) =          0.15797370d0
      e(  29) =          0.62019200d0
      s(  29) =         -0.30080060d0
      e(  30) =          0.27366600d0
      s(  30) =         -0.43042160d0
      e(  31) =          0.02122300d0
      s(  31) =          1.00000000d0
      e(  32) =          0.05053300d0
      e(  33) =        218.95693000d0
      p(  33) =         -0.00123390d0
      e(  34) =         29.09449400d0
      p(  34) =         -0.00742110d0
      e(  35) =         20.58011100d0
      p(  35) =         -0.15049700d0
      e(  36) =         14.66433200d0
      p(  36) =          0.38132000d0
      e(  37) =          4.44610000d0
      p(  37) =         -0.50860500d0
      e(  38) =          2.35102300d0
      p(  38) =         -0.53672190d0
      e(  39) =          1.13768800d0
      p(  39) =         -0.13249870d0
      e(  40) =          0.60724800d0
      p(  40) =          0.00026340d0
      e(  41) =        218.95693000d0
      p(  41) =         -0.00053550d0
      e(  42) =         29.09449400d0
      p(  42) =         -0.01172090d0
      e(  43) =         20.58011100d0
      p(  43) =         -0.03572860d0
      e(  44) =         14.66433200d0
      p(  44) =          0.14037450d0
      e(  45) =          4.44610000d0
      p(  45) =         -0.27467900d0
      e(  46) =          2.35102300d0
      p(  46) =         -0.30476800d0
      e(  47) =          1.13768800d0
      p(  47) =          0.04480730d0
      e(  48) =          0.60724800d0
      p(  48) =          0.51799920d0
      e(  49) =          0.11856800d0
      p(  49) =          1.00000000d0
      e(  50) =          0.28390300d0
      p(  50) =          1.00000000d0
      e(  51) =          0.05000000d0
      p(  51) =          1.00000000d0
      e(  52) =         59.45714300d0
      d(  52) =          0.00604080d0
      e(  53) =         11.29445300d0
      d(  53) =         -0.11688070d0
      e(  54) =          8.06726400d0
      d(  54) =          0.27647700d0
      e(  55) =          3.85885900d0
      d(  55) =          0.46094180d0
      e(  56) =          1.97480900d0
      d(  56) =          0.35633800d0
      e(  57) =          0.99756800d0
      d(  57) =          0.12392380d0
      e(  58) =          0.14880300d0
      d(  58) =          1.00000000d0
      e(  59) =          0.46498100d0
      d(  59) =          1.00000000d0
      e(  60) =          0.05000000d0
      d(  60) =          1.00000000d0
      e(  61) =         70.24087700d0
      f(  61) =         -0.00846030d0
      e(  62) =         26.43288800d0
      f(  62) =         -0.06062620d0
      e(  63) =         11.25984700d0
      f(  63) =         -0.16650070d0
      e(  64) =          5.04968000d0
      f(  64) =         -0.29141590d0
      e(  65) =          2.28483500d0
      f(  65) =         -0.35138760d0
      e(  66) =          1.01582900d0
      f(  66) =         -0.30725420d0
      e(  67) =          0.42802300d0
      f(  67) =          1.00000000d0
      e(  68) =          0.16115800d0
      f(  68) =          1.00000000d0
c 
      go to 800
c
c nd   
c
  200 continue
c
      e(   1) =       6051.89230000d0
      s(   1) =          0.00027650d0
      e(   2) =        912.46487000d0
      s(   2) =          0.00163890d0
      e(   3) =        176.96388000d0
      s(   3) =          0.00470310d0
      e(   4) =         38.72712400d0
      s(   4) =         -0.19859190d0
      e(   5) =         27.66223200d0
      s(   5) =          0.58428530d0
      e(   6) =         13.18587800d0
      s(   6) =         -1.01242160d0
      e(   7) =          3.30850500d0
      s(   7) =          0.99010760d0
      e(   8) =          1.68236600d0
      s(   8) =          0.40117770d0
      e(   9) =          0.64500000d0
      s(   9) =          0.01697660d0
      e(  10) =          0.28282200d0
      s(  10) =         -0.00149190d0
      e(  11) =       6051.89230000d0
      s(  11) =         -0.00015250d0
      e(  12) =        912.46487000d0
      s(  12) =         -0.00097470d0
      e(  13) =        176.96388000d0
      s(  13) =         -0.00222840d0
      e(  14) =         38.72712400d0
      s(  14) =          0.08217980d0
      e(  15) =         27.66223200d0
      s(  15) =         -0.25997540d0
      e(  16) =         13.18587800d0
      s(  16) =          0.50927060d0
      e(  17) =          3.30850500d0
      s(  17) =         -0.73516030d0
      e(  18) =          1.68236600d0
      s(  18) =         -0.46342580d0
      e(  19) =          0.64500000d0
      s(  19) =          0.79709270d0
      e(  20) =          0.28282200d0
      s(  20) =          0.61512440d0
      e(  21) =       6051.89230000d0
      s(  21) =          0.00004270d0
      e(  22) =        912.46487000d0
      s(  22) =          0.00027330d0
      e(  23) =        176.96388000d0
      s(  23) =          0.00061990d0
      e(  24) =         38.72712400d0
      s(  24) =         -0.02225260d0
      e(  25) =         27.66223200d0
      s(  25) =          0.07081750d0
      e(  26) =         13.18587800d0
      s(  26) =         -0.14066820d0
      e(  27) =          3.30850500d0
      s(  27) =          0.21625900d0
      e(  28) =          1.68236600d0
      s(  28) =          0.14339450d0
      e(  29) =          0.64500000d0
      s(  29) =         -0.29962920d0
      e(  30) =          0.28282200d0
      s(  30) =         -0.42149480d0
      e(  31) =          0.02168800d0
      s(  31) =          1.00000000d0
      e(  32) =          0.05192200d0
      s(  32) =          1.00000000d0
      e(  33) =        651.68986000d0
      p(  33) =          0.06000000d0
      e(  34) =        152.67458000d0
      p(  34) =         -0.00039170d0
      e(  35) =         25.72095200d0
      p(  35) =         -0.00214330d0
      e(  36) =         12.65250500d0
      p(  36) =         -0.06250620d0
      e(  37) =          9.01668600d0
      p(  37) =          0.42010900d0
      e(  38) =          3.84399100d0
      p(  38) =         -0.22199390d0
      e(  39) =          1.90181000d0
      p(  39) =         -0.65893730d0
      e(  40) =        651.68986000d0
      p(  40) =         -0.00043200d0
      e(  41) =        152.67458000d0
      p(  41) =         -0.00016790d0
      e(  42) =         25.72095200d0
      p(  42) =         -0.00112750d0
      e(  43) =         12.65250500d0
      p(  43) =         -0.02602600d0
      e(  44) =          9.01668600d0
      p(  44) =          0.20018520d0
      e(  45) =          3.84399100d0
      p(  45) =         -0.13322870d0
      e(  46) =          1.90181000d0
      p(  46) =         -0.35197440d0
      e(  47) =          0.14913400d0
      p(  47) =          0.18804380d0
      e(  48) =          0.36606800d0
      p(  48) =          1.00000000d0
      e(  49) =          0.82709800d0
      p(  49) =          1.00000000d0
      e(  50) =         60.19186100d0
      d(  50) =          0.00818790d0
      e(  51) =         10.49467700d0
      d(  51) =         -0.08279880d0
      e(  52) =          7.49616800d0
      d(  52) =          0.31745460d0
      e(  53) =          3.63615200d0
      d(  53) =          0.47009020d0
      e(  54) =          1.84845900d0
      d(  54) =          0.31600030d0
      e(  55) =          0.12095200d0
      d(  55) =          1.00000000d0
      e(  56) =          0.41618200d0
      d(  56) =          1.00000000d0
      e(  57) =          0.92371200d0
      d(  57) =          1.00000000d0
      e(  58) =         76.08944200d0
      f(  58) =         -0.00810170d0
      e(  59) =         28.47190800d0
      f(  59) =         -0.06082250d0
      e(  60) =         12.25261600d0
      f(  60) =         -0.16764290d0
      e(  61) =          5.51749400d0
      f(  61) =         -0.29275530d0
      e(  62) =          2.50746700d0
      f(  62) =         -0.35157570d0
      e(  63) =          1.11951300d0
      f(  63) =         -0.30523620d0
      e(  64) =          0.47341500d0
      f(  64) =          1.00000000d0
      e(  65) =          0.17896300d0
      f(  65) =          1.00000000d0
c
      go to 800
c
c pm   
c
  220 continue
c
      e(   1) =       8586.58980000d0
      s(   1) =          0.00036530d0
      e(   2) =       1295.26380000d0
      s(   2) =          0.00233910d0
      e(   3) =        281.74108000d0
      s(   3) =          0.00632990d0
      e(   4) =         37.00229400d0
      s(   4) =         -0.18241680d0
      e(   5) =         26.43021000d0
      s(   5) =          0.66709460d0
      e(   6) =         14.27856900d0
      s(   6) =         -1.09411640d0
      e(   7) =          3.38049800d0
      s(   7) =          1.02161390d0
      e(   8) =          1.68192300d0
      s(   8) =          0.36134060d0
      e(   9) =          0.67275300d0
      s(   9) =          0.01244730d0
      e(  10) =          0.29234400d0
      s(  10) =         -0.00047510d0
      e(  11) =       8586.58980000d0
      s(  11) =         -0.00022940d0
      e(  12) =       1295.26380000d0
      s(  12) =         -0.00151440d0
      e(  13) =        281.74108000d0
      s(  13) =         -0.00386590d0
      e(  14) =         37.00229400d0
      s(  14) =          0.07105050d0
      e(  15) =         26.43021000d0
      s(  15) =         -0.29311380d0
      e(  16) =         14.27856900d0
      s(  16) =          0.54299510d0
      e(  17) =          3.38049800d0
      s(  17) =         -0.76846810d0
      e(  18) =          1.68192300d0
      s(  18) =         -0.42510740d0
      e(  19) =          0.67275300d0
      s(  19) =          0.80490990d0
      e(  20) =          0.29234400d0
      s(  20) =          0.61153640d0
      e(  21) =       8586.58980000d0
      s(  21) =          0.00006440d0
      e(  22) =       1295.26380000d0
      s(  22) =          0.00042530d0
      e(  23) =        281.74108000d0
      s(  23) =          0.00108630d0
      e(  24) =         37.00229400d0
      s(  24) =         -0.01880770d0
      e(  25) =         26.43021000d0
      s(  25) =          0.07859970d0
      e(  26) =         14.27856900d0
      s(  26) =         -0.14767560d0
      e(  27) =          3.38049800d0
      s(  27) =          0.22315630d0
      e(  28) =          1.68192300d0
      s(  28) =          0.12973380d0
      e(  29) =          0.67275300d0
      s(  29) =         -0.29588890d0
      e(  30) =          0.29234400d0
      s(  30) =         -0.41611950d0
      e(  31) =          0.02205400d0
      s(  31) =          1.00000000d0
      e(  32) =          0.05298900d0
      s(  32) =          1.00000000d0
      e(  33) =        655.34803000d0
      p(  33) =         -0.00050300d0
      e(  34) =        153.44957000d0
      p(  34) =         -0.00272950d0
      e(  35) =         27.88941900d0
      p(  35) =         -0.05477430d0
      e(  36) =         12.94768300d0
      p(  36) =          0.41236530d0
      e(  37) =          9.19919100d0
      p(  37) =         -0.23789160d0
      e(  38) =          3.98674200d0
      p(  38) =         -0.65757130d0
      e(  39) =          1.97566600d0
      p(  39) =         -0.38884300d0
      e(  40) =          0.86318300d0
      p(  40) =         -0.04315130d0
      e(  41) =        655.34803000d0
      p(  41) =         -0.00022000d0
      e(  42) =        153.44957000d0
      p(  42) =         -0.00143050d0
      e(  43) =         27.88941900d0
      p(  43) =         -0.02274630d0
      e(  44) =         12.94768300d0
      p(  44) =          0.19733770d0
      e(  45) =          9.19919100d0
      p(  45) =         -0.14293630d0
      e(  46) =          3.98674200d0
      p(  46) =         -0.35066870d0
      e(  47) =          1.97566600d0
      p(  47) =         -0.20820320d0
      e(  48) =          0.86318300d0
      p(  48) =          0.40647160d0
      e(  49) =          0.15495100d0
      p(  49) =          1.00000000d0
      e(  50) =          0.38080100d0
      p(  50) =          1.00000000d0
      e(  51) =          0.06000000d0
      p(  51) =          1.00000000d0
      e(  52) =        163.32708000d0
      d(  52) =          0.00195500d0
      e(  53) =         46.65422700d0
      d(  53) =          0.01342640d0
      e(  54) =          6.71432300d0
      d(  54) =          0.31831740d0
      e(  55) =          3.43657200d0
      d(  55) =          0.45204060d0
      e(  56) =          1.76691200d0
      d(  56) =          0.27705220d0
      e(  57) =          0.88648800d0
      d(  57) =          0.07435590d0
      e(  58) =          0.11700800d0
      d(  58) =          1.00000000d0
      e(  59) =          0.39517600d0
      d(  59) =          1.00000000d0
      e(  60) =          0.03000000d0
      d(  60) =          1.00000000d0
      e(  61) =         82.72859300d0
      f(  61) =         -0.00788260d0
      e(  62) =         30.91060500d0
      f(  62) =         -0.06063740d0
      e(  63) =         13.37425000d0
      f(  63) =         -0.16724710d0
      e(  64) =          6.03196000d0
      f(  64) =         -0.29270560d0
      e(  65) =          2.74588000d0
      f(  65) =         -0.35177060d0
      e(  66) =          1.22688800d0
      f(  66) =         -0.30505500d0
      e(  67) =          0.19550100d0
      f(  67) =          1.00000000d0
      e(  68) =          0.51833900d0
      f(  68) =          1.00000000d0
c
      go to 800
c
c sm   
c
  240 continue
c
      e(   1) =       8882.95260000d0
      s(   1) =          0.00119410d0
      e(   2) =       1344.07960000d0
      s(   2) =          0.00791420d0
      e(   3) =        299.67129000d0
      s(   3) =          0.01906510d0
      e(   4) =         21.07471200d0
      s(   4) =          0.82666450d0
      e(   5) =         15.05336600d0
      s(   5) =         -1.45788670d0
      e(   6) =          4.28336700d0
      s(   6) =          0.61563890d0
      e(   7) =          2.38059500d0
      s(   7) =          0.76291900d0
      e(   8) =          0.61494000d0
      s(   8) =          0.12733550d0
      e(   9) =          0.43920400d0
      s(   9) =         -0.10180230d0
      e(  10) =          0.26408900d0
      s(  10) =          0.02472800d0
      e(  11) =       8882.95260000d0
      s(  11) =          0.00114130d0
      e(  12) =       1344.07960000d0
      s(  12) =          0.00713260d0
      e(  13) =        299.67129000d0
      s(  13) =          0.01958690d0
      e(  14) =         21.07471200d0
      s(  14) =          0.42968680d0
      e(  15) =         15.05336600d0
      s(  15) =         -0.77231470d0
      e(  16) =          4.28336700d0
      s(  16) =          0.47170970d0
      e(  17) =          2.38059500d0
      s(  17) =          0.65271720d0
      e(  18) =          0.61494000d0
      s(  18) =         -0.75206510d0
      e(  19) =          0.43920400d0
      s(  19) =         -0.15197040d0
      e(  20) =          0.26408900d0
      s(  20) =         -0.41882160d0
      e(  21) =       8882.95260000d0
      s(  21) =          0.00034830d0
      e(  22) =       1344.07960000d0
      s(  22) =          0.00216370d0
      e(  23) =        299.67129000d0
      s(  23) =          0.00602150d0
      e(  24) =         21.07471200d0
      s(  24) =          0.11691140d0
      e(  25) =         15.05336600d0
      s(  25) =         -0.20984660d0
      e(  26) =          4.28336700d0
      s(  26) =          0.13562500d0
      e(  27) =          2.38059500d0
      s(  27) =          0.18890420d0
      e(  28) =          0.61494000d0
      s(  28) =         -0.27619310d0
      e(  29) =          0.43920400d0
      s(  29) =         -0.08938540d0
      e(  30) =          0.26408900d0
      s(  30) =         -0.31619730d0
      e(  31) =          0.02265900d0
      s(  31) =          1.00000000d0
      e(  32) =          0.05527500d0
      s(  32) =          1.00000000d0
      e(  33) =        680.84918000d0
      p(  33) =          0.00067970d0
      e(  34) =        157.57119000d0
      p(  34) =          0.00400300d0
      e(  35) =         30.68757100d0
      p(  35) =          0.04231660d0
      e(  36) =         21.75791500d0
      p(  36) =          0.04180840d0
      e(  37) =         15.42526000d0
      p(  37) =         -0.27775160d0
      e(  38) =          4.92776000d0
      p(  38) =          0.58075810d0
      e(  39) =          2.39658000d0
      p(  39) =          0.52469790d0
      e(  40) =          0.94760500d0
      p(  40) =          0.07109930d0
      e(  41) =        680.84918000d0
      p(  41) =         -0.00033570d0
      e(  42) =        157.57119000d0
      p(  42) =         -0.00187130d0
      e(  43) =         30.68757100d0
      p(  43) =         -0.02925590d0
      e(  44) =         21.75791500d0
      p(  44) =          0.01823940d0
      e(  45) =         15.42526000d0
      p(  45) =          0.08810870d0
      e(  46) =          4.92776000d0
      p(  46) =         -0.32073580d0
      e(  47) =          2.39658000d0
      p(  47) =         -0.27402700d0
      e(  48) =          0.94760500d0
      p(  48) =          0.34082830d0
      e(  49) =          0.17234400d0
      p(  49) =          1.00000000d0
      e(  50) =          0.42540400d0
      p(  50) =          1.00000000d0
      e(  51) =          0.07000000d0
      p(  51) =          1.00000000d0
      e(  52) =        329.85990000d0
      d(  52) =          0.00062470d0
      e(  53) =         99.59045700d0
      d(  53) =          0.00481240d0
      e(  54) =         37.61771800d0
      d(  54) =          0.01924040d0
      e(  55) =          7.93357200d0
      d(  55) =          0.21561050d0
      e(  56) =          4.47552900d0
      d(  56) =          0.39204990d0
      e(  57) =          2.43197300d0
      d(  57) =          0.35203070d0
      e(  58) =          0.56175200d0
      d(  58) =          1.00000000d0
      e(  59) =          1.24781300d0
      d(  59) =          1.00000000d0
      e(  60) =          0.25000000d0
      d(  60) =          1.00000000d0
      e(  61) =        109.52482000d0
      f(  61) =         -0.00444480d0
      e(  62) =         40.05314700d0
      f(  62) =         -0.04139990d0
      e(  63) =         17.83656600d0
      f(  63) =         -0.13284910d0
      e(  64) =          8.10981000d0
      f(  64) =         -0.25953440d0
      e(  65) =          3.70555400d0
      f(  65) =         -0.34860440d0
      e(  66) =          1.64755200d0
      f(  66) =         -0.33507310d0
      e(  67) =          0.25034000d0
      f(  67) =          1.00000000d0
      e(  68) =          0.68447400d0
      f(  68) =          1.00000000d0
c
      go to 800
c
c eu   
c
  260 continue
c
      e(   1) =       9690.55310000d0
      s(   1) =          0.00108120d0
      e(   2) =       1465.97170000d0
      s(   2) =          0.00719560d0
      e(   3) =        326.38554000d0
      s(   3) =          0.01784840d0
      e(   4) =         22.11032800d0
      s(   4) =          0.81549310d0
      e(   5) =         15.73213800d0
      s(   5) =         -1.44763490d0
      e(   6) =          4.40051800d0
      s(   6) =          0.65489570d0
      e(   7) =          2.44496300d0
      s(   7) =          0.72498390d0
      e(   8) =          0.66379800d0
      s(   8) =          0.11416440d0
      e(   9) =          0.47414100d0
      s(   9) =         -0.08285900d0
      e(  10) =          0.26885900d0
      s(  10) =          0.01746200d0
      e(  11) =       9690.55310000d0
      s(  11) =          0.00096990d0
      e(  12) =       1465.97170000d0
      s(  12) =          0.00607890d0
      e(  13) =        326.38554000d0
      s(  13) =          0.01716890d0
      e(  14) =         22.11032800d0
      s(  14) =          0.41772880d0
      e(  15) =         15.73213800d0
      s(  15) =         -0.75820040d0
      e(  16) =          4.40051800d0
      s(  16) =          0.49350720d0
      e(  17) =          2.44496300d0
      s(  17) =          0.62716920d0
      e(  18) =          0.66379800d0
      s(  18) =         -0.64049110d0
      e(  19) =          0.47414100d0
      s(  19) =         -0.28656870d0
      e(  20) =          0.26885900d0
      s(  20) =         -0.39803770d0
      e(  21) =       9690.55310000d0
      s(  21) =          0.00028730d0
      e(  22) =       1465.97170000d0
      s(  22) =          0.00178970d0
      e(  23) =        326.38554000d0
      s(  23) =          0.00512150d0
      e(  24) =         22.11032800d0
      s(  24) =          0.11184850d0
      e(  25) =         15.73213800d0
      s(  25) =         -0.20298480d0
      e(  26) =          4.40051800d0
      s(  26) =          0.13939670d0
      e(  27) =          2.44496300d0
      s(  27) =          0.17988860d0
      e(  28) =          0.66379800d0
      s(  28) =         -0.22591350d0
      e(  29) =          0.47414100d0
      s(  29) =         -0.14383230d0
      e(  30) =          0.26885900d0
      s(  30) =         -0.30522480d0
      e(  31) =          0.02306300d0
      s(  31) =          1.00000000d0
      e(  32) =          0.05651900d0
      s(  32) =          1.00000000d0
      e(  33) =        653.19305000d0
      p(  33) =          0.00103160d0
      e(  34) =        151.62264000d0
      p(  34) =          0.00584290d0
      e(  35) =         30.80411400d0
      p(  35) =          0.05854310d0
      e(  36) =         21.84269400d0
      p(  36) =         -0.00051480d0
      e(  37) =         15.50725500d0
      p(  37) =         -0.23804550d0
      e(  38) =          5.11258000d0
      p(  38) =          0.58303250d0
      e(  39) =          2.47922900d0
      p(  39) =          0.51875530d0
      e(  40) =          0.98100200d0
      p(  40) =          0.06984970d0
      e(  41) =        653.19305000d0
      p(  41) =         -0.00051470d0
      e(  42) =        151.62264000d0
      p(  42) =         -0.00282460d0
      e(  43) =         30.80411400d0
      p(  43) =         -0.03757490d0
      e(  44) =         21.84269400d0
      p(  44) =          0.04033310d0
      e(  45) =         15.50725500d0
      p(  45) =          0.06652440d0
      e(  46) =          5.11258000d0
      p(  46) =         -0.32374140d0
      e(  47) =          2.47922900d0
      p(  47) =         -0.26450980d0
      e(  48) =          0.98100200d0
      p(  48) =          0.34511630d0
      e(  49) =          0.17711000d0
      p(  49) =          1.00000000d0
      e(  50) =          0.43809400d0
      p(  50) =          1.00000000d0
      e(  51) =          0.07000000d0
      p(  51) =          1.00000000d0
      e(  52) =        322.28566000d0
      d(  52) =          0.00079060d0
      e(  53) =         97.32874400d0
      d(  53) =          0.00596710d0
      e(  54) =         37.02988300d0
      d(  54) =          0.02243880d0
      e(  55) =          8.85106700d0
      d(  55) =          0.17432890d0
      e(  56) =          5.07304600d0
      d(  56) =          0.38381550d0
      e(  57) =          2.72101400d0
      d(  57) =          0.37830270d0
      e(  58) =          0.61485000d0
      d(  58) =          1.00000000d0
      e(  59) =          1.37723100d0
      d(  59) =          1.00000000d0
      e(  60) =          0.27000000d0
      d(  60) =          1.00000000d0
      e(  61) =        117.05156000d0
      f(  61) =         -0.00427280d0
      e(  62) =         42.58914800d0
      f(  62) =         -0.04042560d0
      e(  63) =         19.04633600d0
      f(  63) =         -0.13366110d0
      e(  64) =          8.68716300d0
      f(  64) =         -0.26039620d0
      e(  65) =          3.97925500d0
      f(  65) =         -0.34898610d0
      e(  66) =          1.77283500d0
      f(  66) =         -0.33423350d0
      e(  67) =          0.27019500d0
      f(  67) =          1.00000000d0
      e(  68) =          0.73777600d0
      f(  68) =          1.00000000d0
c
      go to 800
c
c gd   
c
  280 continue
c
      e(   1) =       9364.70150000d0
      s(   1) =          0.00152160d0
      e(   2) =       1417.12780000d0
      s(   2) =          0.01004590d0
      e(   3) =        315.77118000d0
      s(   3) =          0.02273190d0
      e(   4) =         25.84543900d0
      s(   4) =          0.44595250d0
      e(   5) =         14.69402700d0
      s(   5) =         -1.18456040d0
      e(   6) =          6.69336600d0
      s(   6) =          0.41295520d0
      e(   7) =          2.95695300d0
      s(   7) =          1.05560480d0
      e(   8) =          0.67700200d0
      s(   8) =          0.18256920d0
      e(   9) =          0.48004100d0
      s(   9) =         -0.14405800d0
      e(  10) =          0.25755700d0
      s(  10) =          0.03167570d0
      e(  11) =       9364.70150000d0
      s(  11) =          0.00183980d0
      e(  12) =       1417.12780000d0
      s(  12) =          0.01146590d0
      e(  13) =        315.77118000d0
      s(  13) =          0.02971300d0
      e(  14) =         25.84543900d0
      s(  14) =          0.24689210d0
      e(  15) =         14.69402700d0
      s(  15) =         -0.66415430d0
      e(  16) =          6.69336600d0
      s(  16) =          0.31638240d0
      e(  17) =          2.95695300d0
      s(  17) =          0.85457950d0
      e(  18) =          0.67700200d0
      s(  18) =         -0.56815480d0
      e(  19) =          0.48004100d0
      s(  19) =         -0.41667280d0
      e(  20) =          0.25755700d0
      s(  20) =         -0.31093740d0
      e(  21) =       9364.70150000d0
      s(  21) =          0.00059770d0
      e(  22) =       1417.12780000d0
      s(  22) =          0.00370320d0
      e(  23) =        315.77118000d0
      s(  23) =          0.00972860d0
      e(  24) =         25.84543900d0
      s(  24) =          0.06841620d0
      e(  25) =         14.69402700d0
      s(  25) =         -0.18185920d0
      e(  26) =          6.69336600d0
      s(  26) =          0.09184030d0
      e(  27) =          2.95695300d0
      s(  27) =          0.24134320d0
      e(  28) =          0.67700200d0
      s(  28) =         -0.19774610d0
      e(  29) =          0.48004100d0
      s(  29) =         -0.21651990d0
      e(  30) =          0.25755700d0
      s(  30) =         -0.25278440d0
      e(  31) =          0.02419300d0
      s(  31) =          1.00000000d0
      e(  32) =          0.06001800d0
      s(  32) =          1.00000000d0
      e(  33) =        954.55264000d0
      p(  33) =          0.00072460d0
      e(  34) =        227.37012000d0
      p(  34) =          0.00457350d0
      e(  35) =         74.51065600d0
      p(  35) =          0.00893340d0
      e(  36) =         25.52549100d0
      p(  36) =          0.10529130d0
      e(  37) =         16.97094600d0
      p(  37) =         -0.27597380d0
      e(  38) =          5.27868500d0
      p(  38) =          0.56917740d0
      e(  39) =          2.56635000d0
      p(  39) =          0.52592550d0
      e(  40) =          0.97444500d0
      p(  40) =          0.07055440d0
      e(  41) =        954.55264000d0
      p(  41) =         -0.00038460d0
      e(  42) =        227.37012000d0
      p(  42) =         -0.00206460d0
      e(  43) =         74.51065600d0
      p(  43) =         -0.00590830d0
      e(  44) =         25.52549100d0
      p(  44) =         -0.03325880d0
      e(  45) =         16.97094600d0
      p(  45) =          0.10350610d0
      e(  46) =          5.27868500d0
      p(  46) =         -0.32916450d0
      e(  47) =          2.56635000d0
      p(  47) =         -0.24925310d0
      e(  48) =          0.97444500d0
      p(  48) =          0.35702430d0
      e(  49) =          0.17892400d0
      p(  49) =          1.00000000d0
      e(  50) =          0.44123100d0
      p(  50) =          1.00000000d0
      e(  51) =          0.07000000d0
      p(  51) =          1.00000000d0
      e(  52) =        330.89212000d0
      d(  52) =          0.00100460d0
      e(  53) =         99.72180500d0
      d(  53) =          0.00770170d0
      e(  54) =         37.52817600d0
      d(  54) =          0.02963980d0
      e(  55) =         12.43045600d0
      d(  55) =          0.07235460d0
      e(  56) =          6.58224100d0
      d(  56) =          0.36339330d0
      e(  57) =          3.37250400d0
      d(  57) =          0.43485420d0
      e(  58) =          0.73016400d0
      d(  58) =          1.00000000d0
      e(  59) =          1.66168700d0
      d(  59) =          1.00000000d0
      e(  60) =          0.32000000d0
      d(  60) =          1.00000000d0
      e(  61) =        122.40741000d0
      f(  61) =         -0.00444750d0
      e(  62) =         44.48477800d0
      f(  62) =         -0.04203300d0
      e(  63) =         19.92903700d0
      f(  63) =         -0.13878300d0
      e(  64) =          9.08752500d0
      f(  64) =         -0.26496170d0
      e(  65) =          4.15480000d0
      f(  65) =         -0.34940640d0
      e(  66) =          1.84453700d0
      f(  66) =         -0.33055940d0
      e(  67) =          0.27714500d0
      f(  67) =          1.00000000d0
      e(  68) =          0.76340500d0
      f(  68) =          1.00000000d0
c
      go to 800
c
c tb   
c
  300 continue
c
      e(   1) =       9271.40270000d0
      s(   1) =          0.00167990d0
      e(   2) =       1402.74040000d0
      s(   2) =          0.01100450d0
      e(   3) =        311.74580000d0
      s(   3) =          0.02346640d0
      e(   4) =         24.76241800d0
      s(   4) =          0.52702590d0
      e(   5) =         14.12468100d0
      s(   5) =         -1.71140370d0
      e(   6) =         10.08905800d0
      s(   6) =          0.73479650d0
      e(   7) =          3.13199400d0
      s(   7) =          1.16712280d0
      e(   8) =          0.64732600d0
      s(   8) =          0.23524750d0
      e(   9) =          0.45958100d0
      s(   9) =         -0.20198590d0
      e(  10) =          0.24917100d0
      s(  10) =          0.04850100d0
      e(  11) =       9271.40270000d0
      s(  11) =          0.00247550d0
      e(  12) =       1402.74040000d0
      s(  12) =          0.01535600d0
      e(  13) =        311.74580000d0
      s(  13) =          0.03747990d0
      e(  14) =         24.76241800d0
      s(  14) =          0.30894290d0
      e(  15) =         14.12468100d0
      s(  15) =         -1.03651490d0
      e(  16) =         10.08905800d0
      s(  16) =          0.53802400d0
      e(  17) =          3.13199400d0
      s(  17) =          0.92079960d0
      e(  18) =          0.64732600d0
      s(  18) =         -0.58488470d0
      e(  19) =          0.45958100d0
      s(  19) =         -0.41122570d0
      e(  20) =          0.24917100d0
      s(  20) =         -0.27868360d0
      e(  21) =       9271.40270000d0
      s(  21) =          0.00084760d0
      e(  22) =       1402.74040000d0
      s(  22) =          0.00522930d0
      e(  23) =        311.74580000d0
      s(  23) =          0.01293460d0
      e(  24) =         24.76241800d0
      s(  24) =          0.08623840d0
      e(  25) =         14.12468100d0
      s(  25) =         -0.28679840d0
      e(  26) =         10.08905800d0
      s(  26) =          0.15648290d0
      e(  27) =          3.13199400d0
      s(  27) =          0.24978630d0
      e(  28) =          0.64732600d0
      s(  28) =         -0.19412640d0
      e(  29) =          0.45958100d0
      s(  29) =         -0.20730880d0
      e(  30) =          0.24917100d0
      s(  30) =         -0.24969740d0
      e(  31) =          0.02399800d0
      s(  31) =          1.00000000d0
      e(  32) =          0.05905300d0
      s(  32) =          1.00000000d0
      e(  33) =       1103.23310000d0
      p(  33) =          0.00071410d0
      e(  34) =        263.34749000d0
      p(  34) =          0.00464760d0
      e(  35) =         85.85010900d0
      p(  35) =          0.01056750d0
      e(  36) =         26.12167300d0
      p(  36) =          0.13366100d0
      e(  37) =         18.49787100d0
      p(  37) =         -0.29195720d0
      e(  38) =          5.55928600d0
      p(  38) =          0.56839700d0
      e(  39) =          2.70766900d0
      p(  39) =          0.52086100d0
      e(  40) =          1.02294700d0
      p(  40) =          0.06966490d0
      e(  41) =       1103.23310000d0
      p(  41) =         -0.00038390d0
      e(  42) =        263.34749000d0
      p(  42) =         -0.00214160d0
      e(  43) =         85.85010900d0
      p(  43) =         -0.00663060d0
      e(  44) =         26.12167300d0
      p(  44) =         -0.04393650d0
      e(  45) =         18.49787100d0
      p(  45) =          0.10822080d0
      e(  46) =          5.55928600d0
      p(  46) =         -0.33391950d0
      e(  47) =          2.70766900d0
      p(  47) =         -0.23797230d0
      e(  48) =          1.02294700d0
      p(  48) =          0.36065870d0
      e(  49) =          0.19003600d0
      p(  49) =          1.00000000d0
      e(  50) =          0.46451200d0
      p(  50) =          1.00000000d0
      e(  51) =          0.08000000d0
      p(  51) =          1.00000000d0
      e(  52) =        385.38468000d0
      d(  52) =          0.00097050d0
      e(  53) =        116.39518000d0
      d(  53) =          0.00775410d0
      e(  54) =         44.16086300d0
      d(  54) =          0.03117190d0
      e(  55) =         18.66176200d0
      d(  55) =          0.05340890d0
      e(  56) =          7.71913000d0
      d(  56) =          0.32195320d0
      e(  57) =          3.87577300d0
      d(  57) =          0.45651510d0
      e(  58) =          0.81421700d0
      d(  58) =          1.00000000d0
      e(  59) =          1.87738700d0
      d(  59) =          1.00000000d0
      e(  60) =          0.35000000d0
      d(  60) =          1.00000000d0
      e(  61) =        129.38871000d0
      f(  61) =         -0.00449900d0
      e(  62) =         46.93680600d0
      f(  62) =         -0.04274100d0
      e(  63) =         21.07838400d0
      f(  63) =         -0.14235930d0
      e(  64) =          9.61749700d0
      f(  64) =         -0.26777510d0
      e(  65) =          4.39273900d0
      f(  65) =         -0.34951970d0
      e(  66) =          1.94552500d0
      f(  66) =         -0.32800590d0
      e(  67) =          0.28941600d0
      f(  67) =          1.00000000d0
      e(  68) =          0.80172500d0
      f(  68) =          1.00000000d0
      go to 800
c
c dy   
c
  320 continue
c
      e(   1) =      25734.63200000d0
      s(   1) =          0.00056290d0
      e(   2) =       3883.47230000d0
      s(   2) =          0.00383600d0
      e(   3) =        886.67528000d0
      s(   3) =          0.01568820d0
      e(   4) =        246.95266000d0
      s(   4) =          0.01941260d0
      e(   5) =         24.50570200d0
      s(   5) =          0.84051540d0
      e(   6) =         17.50407300d0
      s(   6) =         -1.48483140d0
      e(   7) =          5.11128700d0
      s(   7) =          0.62901590d0
      e(   8) =          2.70492600d0
      s(   8) =          0.77483200d0
      e(   9) =          0.70766800d0
      s(   9) =          0.04561860d0
      e(  10) =          0.31843500d0
      s(  10) =         -0.01221630d0
      e(  11) =      25734.63200000d0
      s(  11) =          0.00103520d0
      e(  12) =       3883.47230000d0
      s(  12) =          0.00749030d0
      e(  13) =        886.67528000d0
      s(  13) =          0.02775420d0
      e(  14) =        246.95266000d0
      s(  14) =          0.04443750d0
      e(  15) =         24.50570200d0
      s(  15) =          0.45569090d0
      e(  16) =         17.50407300d0
      s(  16) =         -0.79857370d0
      e(  17) =          5.11128700d0
      s(  17) =          0.49169130d0
      e(  18) =          2.70492600d0
      s(  18) =          0.62773380d0
      e(  19) =          0.70766800d0
      s(  19) =         -0.80153290d0
      e(  20) =          0.31843500d0
      s(  20) =         -0.51335240d0
      e(  21) =      25734.63200000d0
      s(  21) =          0.00040950d0
      e(  22) =       3883.47230000d0
      s(  22) =          0.00297960d0
      e(  23) =        886.67528000d0
      s(  23) =          0.01093880d0
      e(  24) =        246.95266000d0
      s(  24) =          0.01792550d0
      e(  25) =         24.50570200d0
      s(  25) =          0.12677950d0
      e(  26) =         17.50407300d0
      s(  26) =         -0.21611240d0
      e(  27) =          5.11128700d0
      s(  27) =          0.14230540d0
      e(  28) =          2.70492600d0
      s(  28) =          0.16639490d0
      e(  29) =          0.70766800d0
      s(  29) =         -0.28318070d0
      e(  30) =          0.31843500d0
      s(  30) =         -0.35973540d0
      e(  31) =          0.02418000d0
      s(  31) =          1.00000000d0
      e(  32) =          0.05919800d0
      s(  32) =          1.00000000d0
      e(  33) =       1186.87500000d0
      p(  33) =          0.00093960d0
      e(  34) =        282.28651000d0
      p(  34) =          0.00626670d0
      e(  35) =         90.05923700d0
      p(  35) =          0.01606550d0
      e(  36) =         26.42619400d0
      p(  36) =          0.14066960d0
      e(  37) =         18.87585300d0
      p(  37) =         -0.27929750d0
      e(  38) =          5.74588700d0
      p(  38) =          0.55346470d0
      e(  39) =          2.80087900d0
      p(  39) =          0.52559520d0
      e(  40) =          1.05201900d0
      p(  40) =          0.07254040d0
      e(  41) =       1186.87500000d0
      p(  41) =         -0.00051680d0
      e(  42) =        282.28651000d0
      p(  42) =         -0.00308490d0
      e(  43) =         90.05923700d0
      p(  43) =         -0.00978170d0
      e(  44) =         26.42619400d0
      p(  44) =         -0.04743730d0
      e(  45) =         18.87585300d0
      p(  45) =          0.10170020d0
      e(  46) =          5.74588700d0
      p(  46) =         -0.33439850d0
      e(  47) =          2.80087900d0
      p(  47) =         -0.23046090d0
      e(  48) =          1.05201900d0
      p(  48) =          0.35933890d0
      e(  49) =          0.19421800d0
      p(  49) =          1.00000000d0
      e(  50) =          0.47732900d0
      p(  50) =          1.00000000d0
      e(  51) =          0.08000000d0
      p(  51) =          1.00000000d0
      e(  52) =        447.92194000d0
      d(  52) =          0.00086440d0
      e(  53) =        135.38966000d0
      d(  53) =          0.00712070d0
      e(  54) =         51.83891000d0
      d(  54) =          0.02943850d0
      e(  55) =         22.47598900d0
      d(  55) =          0.05956500d0
      e(  56) =          8.56940300d0
      d(  56) =          0.28983700d0
      e(  57) =          4.29174400d0
      d(  57) =          0.46091410d0
      e(  58) =          0.88814100d0
      d(  58) =          1.00000000d0
      e(  59) =          2.06427700d0
      d(  59) =          1.00000000d0
      e(  60) =          0.38000000d0
      d(  60) =          1.00000000d0
      e(  61) =        135.84524000d0
      f(  61) =         -0.00457930d0
      e(  62) =         49.24803000d0
      f(  62) =         -0.04350960d0
      e(  63) =         22.12888100d0
      f(  63) =         -0.14496760d0
      e(  64) =         10.09041000d0
      f(  64) =         -0.27004430d0
      e(  65) =          4.60073900d0
      f(  65) =         -0.34981230d0
      e(  66) =          2.03130600d0
      f(  66) =         -0.32630180d0
      e(  67) =          0.29814700d0
      f(  67) =          1.00000000d0
      e(  68) =          0.83293000d0
      f(  68) =          1.00000000d0
c
      go to 800
c
c ho   
c
  340 continue
c
      e(   1) =       3496.29410000d0
      s(   1) =          0.00281250d0
      e(   2) =        522.96995000d0
      s(   2) =          0.01215050d0
      e(   3) =         40.16074700d0
      s(   3) =         -0.14405160d0
      e(   4) =         28.65574700d0
      s(   4) =          1.05223250d0
      e(   5) =         19.90806300d0
      s(   5) =         -1.50368150d0
      e(   6) =          4.31767700d0
      s(   6) =          1.04263170d0
      e(   7) =          2.00120100d0
      s(   7) =          0.36788500d0
      e(   8) =          1.42838400d0
      s(   8) =         -0.03202180d0
      e(   9) =          0.60662600d0
      s(   9) =          0.00949340d0
      e(  10) =          0.28916300d0
      s(  10) =         -0.00151120d0
      e(  11) =       3496.29410000d0
      s(  11) =          0.00211510d0
      e(  12) =        522.96995000d0
      s(  12) =          0.00928860d0
      e(  13) =         40.16074700d0
      s(  13) =         -0.02712230d0
      e(  14) =         28.65574700d0
      s(  14) =          0.41471360d0
      e(  15) =         19.90806300d0
      s(  15) =         -0.68860760d0
      e(  16) =          4.31767700d0
      s(  16) =          0.74447070d0
      e(  17) =          2.00120100d0
      s(  17) =          0.66620520d0
      e(  18) =          1.42838400d0
      s(  18) =         -0.53142340d0
      e(  19) =          0.60662600d0
      s(  19) =         -0.79705080d0
      e(  20) =          0.28916300d0
      s(  20) =         -0.33728020d0
      e(  21) =       3496.29410000d0
      s(  21) =          0.00056960d0
      e(  22) =        522.96995000d0
      s(  22) =          0.00250980d0
      e(  23) =         40.16074700d0
      s(  23) =         -0.00547200d0
      e(  24) =         28.65574700d0
      s(  24) =          0.10184680d0
      e(  25) =         19.90806300d0
      s(  25) =         -0.17281320d0
      e(  26) =          4.31767700d0
      s(  26) =          0.19954020d0
      e(  27) =          2.00120100d0
      s(  27) =          0.18934110d0
      e(  28) =          1.42838400d0
      s(  28) =         -0.15417910d0
      e(  29) =          0.60662600d0
      s(  29) =         -0.31733220d0
      e(  30) =          0.28916300d0
      s(  30) =         -0.27647650d0
      e(  31) =          0.02509300d0
      s(  31) =          1.00000000d0
      e(  32) =          0.06289900d0
      s(  32) =          1.00000000d0
      e(  33) =       1646.66370000d0
      p(  33) =          0.00070820d0
      e(  34) =        393.49335000d0
      p(  34) =          0.00507420d0
      e(  35) =        127.60800000d0
      p(  35) =          0.01567570d0
      e(  36) =         40.55744300d0
      p(  36) =          0.04820810d0
      e(  37) =         15.63587900d0
      p(  37) =         -0.19940120d0
      e(  38) =          6.47681400d0
      p(  38) =          0.50389160d0
      e(  39) =          3.10221300d0
      p(  39) =          0.58299710d0
      e(  40) =          1.18288900d0
      p(  40) =          0.09296930d0
      e(  41) =       1646.66370000d0
      p(  41) =         -0.00040210d0
      e(  42) =        393.49335000d0
      p(  42) =         -0.00255790d0
      e(  43) =        127.60800000d0
      p(  43) =         -0.00945920d0
      e(  44) =         40.55744300d0
      p(  44) =         -0.02015730d0
      e(  45) =         15.63587900d0
      p(  45) =          0.08069160d0
      e(  46) =          6.47681400d0
      p(  46) =         -0.30895200d0
      e(  47) =          3.10221300d0
      p(  47) =         -0.27149170d0
      e(  48) =          1.18288900d0
      p(  48) =          0.29595410d0
      e(  49) =          0.21304800d0
      p(  49) =          1.00000000d0
      e(  50) =          0.53464300d0
      p(  50) =          1.00000000d0
      e(  51) =          0.08000000d0
      p(  51) =          1.00000000d0
      e(  52) =        466.48368000d0
      d(  52) =          0.00100420d0
      e(  53) =        141.11037000d0
      d(  53) =          0.00830260d0
      e(  54) =         54.18568900d0
      d(  54) =          0.03435510d0
      e(  55) =         23.27407500d0
      d(  55) =          0.07540330d0
      e(  56) =          8.95258800d0
      d(  56) =          0.28229070d0
      e(  57) =          4.45579200d0
      d(  57) =          0.45822320d0
      e(  58) =          0.91407900d0
      d(  58) =          1.00000000d0
      e(  59) =          2.13319700d0
      d(  59) =          1.00000000d0
      e(  60) =          0.39000000d0
      d(  60) =          1.00000000d0
      e(  61) =        141.73616000d0
      f(  61) =         -0.00466120d0
      e(  62) =         51.32708800d0
      f(  62) =         -0.04418030d0
      e(  63) =         23.06260700d0
      f(  63) =         -0.14762350d0
      e(  64) =         10.51565200d0
      f(  64) =         -0.27255900d0
      e(  65) =          4.78930800d0
      f(  65) =         -0.35022280d0
      e(  66) =          2.10962100d0
      f(  66) =         -0.32430470d0
      e(  67) =          0.30620700d0
      f(  67) =          1.00000000d0
      e(  68) =          0.86149900d0
      f(  68) =          1.00000000d0
c
      go to 800
c
c er   
c
  360 continue
c
      e(   1) =       3681.23271600d0
      s(   1) =          0.00231050d0
      e(   2) =        550.11135600d0
      s(   2) =          0.01001210d0
      e(   3) =         46.13558900d0
      s(   3) =         -0.11478910d0
      e(   4) =         30.75706000d0
      s(   4) =          0.90201130d0
      e(   5) =         20.50470600d0
      s(   5) =         -1.38436750d0
      e(   6) =          4.51203600d0
      s(   6) =          1.02924290d0
      e(   7) =          2.20027700d0
      s(   7) =          0.34588310d0
      e(   8) =          0.89585600d0
      s(   8) =          0.01150410d0
      e(   9) =          0.38014300d0
      s(   9) =         -0.00026520d0
      e(  10) =          0.06647900d0
      s(  10) =          0.00057710d0
      e(  11) =       3681.23271600d0
      s(  11) =          0.00162050d0
      e(  12) =        550.11135600d0
      s(  12) =          0.00707920d0
      e(  13) =         46.13558900d0
      s(  13) =         -0.03231170d0
      e(  14) =         30.75706000d0
      s(  14) =          0.38106970d0
      e(  15) =         20.50470600d0
      s(  15) =         -0.65355100d0
      e(  16) =          4.51203600d0
      s(  16) =          0.75472660d0
      e(  17) =          2.20027700d0
      s(  17) =          0.39999070d0
      e(  18) =          0.89585600d0
      s(  18) =         -0.76249530d0
      e(  19) =          0.38014300d0
      s(  19) =         -0.63406310d0
      e(  20) =          0.06647900d0
      s(  20) =         -0.04947690d0
      e(  21) =       3681.23271600d0
      s(  21) =          0.00042400d0
      e(  22) =        550.11135600d0
      s(  22) =          0.00185840d0
      e(  23) =         46.13558900d0
      s(  23) =         -0.00755440d0
      e(  24) =         30.75706000d0
      s(  24) =          0.09398200d0
      e(  25) =         20.50470600d0
      s(  25) =         -0.16305980d0
      e(  26) =          4.51203600d0
      s(  26) =          0.20071860d0
      e(  27) =          2.20027700d0
      s(  27) =          0.10895370d0
      e(  28) =          0.89585600d0
      s(  28) =         -0.23889510d0
      e(  29) =          0.38014300d0
      s(  29) =         -0.40075240d0
      e(  30) =          0.06647900d0
      s(  30) =          0.40348860d0
      e(  31) =          0.02166200d0
      s(  31) =          1.00000000d0
      e(  32) =          0.04431900d0
      s(  32) =          1.00000000d0
      e(  33) =       1817.30238900d0
      p(  33) =          0.00069060d0
      e(  34) =        433.87230000d0
      p(  34) =          0.00501650d0
      e(  35) =        140.19997800d0
      p(  35) =          0.01616260d0
      e(  36) =         44.82172700d0
      p(  36) =          0.04632750d0
      e(  37) =         15.70387400d0
      p(  37) =         -0.20329720d0
      e(  38) =          6.95066300d0
      p(  38) =          0.49501000d0
      e(  39) =          3.29758400d0
      p(  39) =          0.59571590d0
      e(  40) =       1817.30238900d0
      p(  40) =         -0.00039370d0
      e(  41) =        433.87230000d0
      p(  41) =         -0.00255740d0
      e(  42) =        140.19997800d0
      p(  42) =         -0.00970920d0
      e(  43) =         44.82172700d0
      p(  43) =         -0.02024220d0
      e(  44) =         15.70387400d0
      p(  44) =          0.08333180d0
      e(  45) =          6.95066300d0
      p(  45) =         -0.30344620d0
      e(  46) =          3.29758400d0
      p(  46) =         -0.28094450d0
      e(  47) =          0.22477000d0
      p(  47) =          1.00000000d0
      e(  48) =          0.56846500d0
      p(  48) =          1.00000000d0
      e(  49) =          1.26828200d0
      p(  49) =          1.00000000d0
      e(  50) =        470.63621900d0
      d(  50) =          0.00132190d0
      e(  51) =        142.54598100d0
      d(  51) =          0.01090110d0
      e(  52) =         54.90228100d0
      d(  52) =          0.04473080d0
      e(  53) =         23.39421900d0
      d(  53) =          0.10195610d0
      e(  54) =          9.22858300d0
      d(  54) =          0.27749330d0
      e(  55) =          0.91850100d0
      d(  55) =          1.00000000d0
      e(  56) =          2.15340800d0
      d(  56) =          1.00000000d0
      e(  57) =          4.52923700d0
      d(  57) =          1.00000000d0
      e(  58) =        150.28929200d0
      f(  58) =         -0.00411580d0
      e(  59) =         53.84771700d0
      f(  59) =         -0.03955070d0
      e(  60) =         24.14082800d0
      f(  60) =         -0.14647940d0
      e(  61) =         11.10882800d0
      f(  61) =         -0.27288790d0
      e(  62) =          5.06639000d0
      f(  62) =         -0.35048310d0
      e(  63) =          2.22811800d0
      f(  63) =         -0.32472010d0
      e(  64) =          0.31921600d0
      f(  64) =          1.00000000d0
      e(  65) =          0.90577100d0
      f(  65) =          1.00000000d0
c
      go to 800
c
c tm   
c
  380 continue
c
      e(   1) =       3848.73525100d0
      s(   1) =          0.00203150d0
      e(   2) =        574.69944500d0
      s(   2) =          0.00879340d0
      e(   3) =         49.29290000d0
      s(   3) =         -0.12306900d0
      e(   4) =         32.86023600d0
      s(   4) =          0.84263450d0
      e(   5) =         21.15402000d0
      s(   5) =         -1.31794530d0
      e(   6) =          4.69133100d0
      s(   6) =          1.02785320d0
      e(   7) =          2.28501000d0
      s(   7) =          0.34731340d0
      e(   8) =          0.92100400d0
      s(   8) =          0.01161210d0
      e(   9) =          0.38987700d0
      s(   9) =         -0.00033500d0
      e(  10) =          0.06778400d0
      s(  10) =          0.00060420d0
      e(  11) =       3848.73525100d0
      s(  11) =          0.00136530d0
      e(  12) =        574.69944500d0
      s(  12) =          0.00592420d0
      e(  13) =         49.29290000d0
      s(  13) =         -0.03972930d0
      e(  14) =         32.86023600d0
      s(  14) =          0.36049280d0
      e(  15) =         21.15402000d0
      s(  15) =         -0.62586970d0
      e(  16) =          4.69133100d0
      s(  16) =          0.75131940d0
      e(  17) =          2.28501000d0
      s(  17) =          0.39544270d0
      e(  18) =          0.92100400d0
      s(  18) =         -0.76171560d0
      e(  19) =          0.38987700d0
      s(  19) =         -0.62954670d0
      e(  20) =          0.06778400d0
      s(  20) =         -0.04904860d0
      e(  21) =       3848.73525100d0
      s(  21) =          0.00035070d0
      e(  22) =        574.69944500d0
      s(  22) =          0.00152650d0
      e(  23) =         49.29290000d0
      s(  23) =         -0.00945370d0
      e(  24) =         32.86023600d0
      s(  24) =          0.08826190d0
      e(  25) =         21.15402000d0
      s(  25) =         -0.15476470d0
      e(  26) =          4.69133100d0
      s(  26) =          0.19752940d0
      e(  27) =          2.28501000d0
      s(  27) =          0.10666790d0
      e(  28) =          0.92100400d0
      s(  28) =         -0.23566960d0
      e(  29) =          0.38987700d0
      s(  29) =         -0.39584540d0
      e(  30) =          0.06778400d0
      s(  30) =          0.39860290d0
      e(  31) =          0.02199000d0
      s(  31) =          1.00000000d0
      e(  32) =          0.04518900d0
      s(  32) =          1.00000000d0
      e(  33) =       2080.79271500d0
      p(  33) =          0.00073640d0
      e(  34) =        494.96669500d0
      p(  34) =          0.00549910d0
      e(  35) =        158.34055900d0
      p(  35) =          0.01930200d0
      e(  36) =         51.63675100d0
      p(  36) =          0.04784290d0
      e(  37) =         13.89725100d0
      p(  37) =         -0.26037740d0
      e(  38) =          7.99233100d0
      p(  38) =          0.50317650d0
      e(  39) =          3.59022000d0
      p(  39) =          0.63467060d0
      e(  40) =       2080.79271500d0
      p(  40) =         -0.00043100d0
      e(  41) =        494.96669500d0
      p(  41) =         -0.00297140d0
      e(  42) =        158.34055900d0
      p(  42) =         -0.01169240d0
      e(  43) =         51.63675100d0
      p(  43) =         -0.02370170d0
      e(  44) =         13.89725100d0
      p(  44) =          0.11172220d0
      e(  45) =          7.99233100d0
      p(  45) =         -0.30331810d0
      e(  46) =          3.59022000d0
      p(  46) =         -0.31659120d0
      e(  47) =          0.24100100d0
      p(  47) =          1.00000000d0
      e(  48) =          0.62220100d0
      p(  48) =          1.00000000d0
      e(  49) =          1.43151500d0
      p(  49) =          1.00000000d0
      e(  50) =        494.29816700d0
      d(  50) =          0.00137830d0
      e(  51) =        149.72597100d0
      d(  51) =          0.01139300d0
      e(  52) =         57.69562500d0
      d(  52) =          0.04687960d0
      e(  53) =         24.54232200d0
      d(  53) =          0.10803250d0
      e(  54) =          9.72032300d0
      d(  54) =          0.27141510d0
      e(  55) =          0.95419400d0
      d(  55) =          1.00000000d0
      e(  56) =          2.24546900d0
      d(  56) =          1.00000000d0
      e(  57) =          4.74104500d0
      d(  57) =          1.00000000d0
      e(  58) =        156.75151300d0
      f(  58) =         -0.00435480d0
      e(  59) =         56.29037900d0
      f(  59) =         -0.04170030d0
      e(  60) =         25.27753200d0
      f(  60) =         -0.15008510d0
      e(  61) =         11.59982300d0
      f(  61) =         -0.27540620d0
      e(  62) =          5.28067600d0
      f(  62) =         -0.35054310d0
      e(  63) =          2.31725700d0
      f(  63) =         -0.32242740d0
      e(  64) =          0.32925200d0
      f(  64) =          1.00000000d0
      e(  65) =          0.93902800d0
      f(  65) =          1.00000000d0
c
      go to 800
c
c yb   
c
  400 continue
c
      e(   1) =       3904.92090000d0
      s(   1) =          0.00182670d0
      e(   2) =        581.42070000d0
      s(   2) =          0.00782260d0
      e(   3) =         60.20580100d0
      s(   3) =         -0.07181470d0
      e(   4) =         35.41517700d0
      s(   4) =          0.61116630d0
      e(   5) =         20.83245700d0
      s(   5) =         -1.15607360d0
      e(   6) =          5.06233800d0
      s(   6) =          0.96341730d0
      e(   7) =          2.56688200d0
      s(   7) =          0.42126740d0
      e(   8) =          0.93052200d0
      s(   8) =          0.02104750d0
      e(   9) =          0.39509700d0
      s(   9) =         -0.00259990d0
      e(  10) =          0.06397600d0
      s(  10) =          0.00160150d0
      e(  11) =       3904.92090000d0
      s(  11) =          0.00118960d0
      e(  12) =        581.42070000d0
      s(  12) =          0.00502060d0
      e(  13) =         60.20580100d0
      s(  13) =         -0.02437740d0
      e(  14) =         35.41517700d0
      s(  14) =          0.26701570d0
      e(  15) =         20.83245700d0
      s(  15) =         -0.55738270d0
      e(  16) =          5.06233800d0
      s(  16) =          0.68843170d0
      e(  17) =          2.56688200d0
      s(  17) =          0.44239660d0
      e(  18) =          0.93052200d0
      s(  18) =         -0.74973030d0
      e(  19) =          0.39509700d0
      s(  19) =         -0.62112320d0
      e(  20) =          0.06397600d0
      s(  20) =         -0.03875830d0
      e(  21) =       3904.92090000d0
      s(  21) =          0.00029800d0
      e(  22) =        581.42070000d0
      s(  22) =          0.00126030d0
      e(  23) =         60.20580100d0
      s(  23) =         -0.00573030d0
      e(  24) =         35.41517700d0
      s(  24) =          0.06422050d0
      e(  25) =         20.83245700d0
      s(  25) =         -0.13532700d0
      e(  26) =          5.06233800d0
      s(  26) =          0.17670510d0
      e(  27) =          2.56688200d0
      s(  27) =          0.11664370d0
      e(  28) =          0.93052200d0
      s(  28) =         -0.22621560d0
      e(  29) =          0.39509700d0
      s(  29) =         -0.38927390d0
      e(  30) =          0.06397600d0
      s(  30) =          0.56210100d0
      e(  31) =          0.02134800d0
      s(  31) =          1.00000000d0
      e(  32) =          0.03763300d0
      s(  32) =          1.00000000d0
      e(  33) =       2181.70190000d0
      p(  33) =          0.00081670d0
      e(  34) =        518.81230000d0
      p(  34) =          0.00610560d0
      e(  35) =        165.85316000d0
      p(  35) =          0.02159280d0
      e(  36) =         54.60924100d0
      p(  36) =          0.05124970d0
      e(  37) =         14.06235800d0
      p(  37) =         -0.26514200d0
      e(  38) =          8.37446200d0
      p(  38) =          0.51791530d0
      e(  39) =          3.73461600d0
      p(  39) =          0.62906420d0
      e(  40) =       2181.70190000d0
      p(  40) =         -0.00048610d0
      e(  41) =        518.81230000d0
      p(  41) =         -0.00339050d0
      e(  42) =        165.85316000d0
      p(  42) =         -0.01326520d0
      e(  43) =         54.60924100d0
      p(  43) =         -0.02638580d0
      e(  44) =         14.06235800d0
      p(  44) =          0.11280650d0
      e(  45) =          8.37446200d0
      p(  45) =         -0.31346850d0
      e(  46) =          3.73461600d0
      p(  46) =         -0.31077330d0
      e(  47) =          0.25009100d0
      p(  47) =          1.00000000d0
      e(  48) =          0.64490700d0
      p(  48) =          1.00000000d0
      e(  49) =          1.49208900d0
      p(  49) =          1.00000000d0
      e(  50) =        411.88272000d0
      d(  50) =          0.00260900d0
      e(  51) =        125.06366000d0
      d(  51) =          0.02030040d0
      e(  52) =         48.17324000d0
      d(  52) =          0.07517500d0
      e(  53) =         20.31838600d0
      d(  53) =          0.15053210d0
      e(  54) =          8.25831200d0
      d(  54) =          0.33554840d0
      e(  55) =          0.80364200d0
      d(  55) =          1.00000000d0
      e(  56) =          1.88599600d0
      d(  56) =          1.00000000d0
      e(  57) =          3.99277400d0
      d(  57) =          1.00000000d0
      e(  58) =        177.13956000d0
      f(  58) =         -0.00332530d0
      e(  59) =         62.96676500d0
      f(  59) =         -0.03295960d0
      e(  60) =         28.01554600d0
      f(  60) =         -0.13697920d0
      e(  61) =         12.99254900d0
      f(  61) =         -0.26734370d0
      e(  62) =          5.91299100d0
      f(  62) =         -0.35094450d0
      e(  63) =          2.58409600d0
      f(  63) =         -0.33127190d0
      e(  64) =          0.35902100d0
      f(  64) =          1.00000000d0
      e(  65) =          1.03876400d0
      f(  65) =          1.00000000d0
c
      go to 800
c
c hf   
c
  440 continue
c
      e(   1) =         14.59248500d0
      s(   1) =         -0.79934440d0
      e(   2) =         11.54749100d0
      s(   2) =          1.52015480d0
      e(   3) =          4.91119400d0
      s(   3) =         -1.64536400d0
      e(   4) =          0.80851800d0
      s(   4) =          1.00000000d0
      e(   5) =          0.35028500d0
      s(   5) =          1.00000000d0
      e(   6) =          0.10128200d0
      s(   6) =          1.00000000d0
      e(   7) =          0.03933600d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01000000d0
      s(   8) =          1.00000000d0
      e(   9) =          6.72653100d0
      p(   9) =          3.26625490d0
      e(  10) =          5.95997900d0
      p(  10) =         -4.20156280d0
      e(  11) =          1.30195800d0
      p(  11) =          0.32484240d0
      e(  12) =          0.69313600d0
      p(  12) =          0.70101450d0
      e(  13) =          0.27975900d0
      p(  13) =          1.00000000d0
      e(  14) =          0.07769500d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02695200d0
      p(  15) =          1.00000000d0
      e(  16) =          3.72164100d0
      d(  16) =         -0.05916200d0
      e(  17) =          1.58412000d0
      d(  17) =          0.14951390d0
      e(  18) =          0.63351000d0
      d(  18) =          0.43731370d0
      e(  19) =          0.23056400d0
      d(  19) =          0.58875870d0
      e(  20) =          0.07495100d0
      d(  20) =          1.00000000d0
      e(  21) =          0.02500000d0
      d(  21) =          1.00000000d0
c
      go to 800
c
c ta   
c
  460 continue
c
      e(   1) =         13.95110500d0
      s(   1) =         -1.49290850d0
      e(   2) =         12.01024100d0
      s(   2) =          2.28201460d0
      e(   3) =          5.16644600d0
      s(   3) =         -1.71334050d0
      e(   4) =          0.85631500d0
      s(   4) =          1.00000000d0
      e(   5) =          0.36428100d0
      s(   5) =          1.00000000d0
      e(   6) =          0.12549400d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04621300d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01500000d0
      s(   8) =          1.00000000d0
      e(   9) =          7.41887200d0
      p(   9) =          1.26680990d0
      e(  10) =          5.69841000d0
      p(  10) =         -2.20496150d0
      e(  11) =          1.31807200d0
      p(  11) =          0.39272020d0
      e(  12) =          0.68216900d0
      p(  12) =          0.63805260d0
      e(  13) =          0.28217200d0
      p(  13) =          1.00000000d0
      e(  14) =          0.07968500d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02677000d0
      p(  15) =          1.00000000d0
      e(  16) =          3.79167100d0
      d(  16) =         -0.06689760d0
      e(  17) =          1.64930200d0
      d(  17) =          0.16690000d0
      e(  18) =          0.66492500d0
      d(  18) =          0.46427890d0
      e(  19) =          0.24665500d0
      d(  19) =          0.54886710d0
      e(  20) =          0.08272400d0
      d(  20) =          1.00000000d0
      e(  21) =          0.02500000d0
      d(  21) =          1.00000000d0
c
      go to 800
c
c w   
c
  480 continue
c
      e(   1) =         14.29072900d0
      s(   1) =         -1.40860990d0
      e(   2) =         12.24124900d0
      s(   2) =          2.19364700d0
      e(   3) =          5.31224000d0
      s(   3) =         -1.71080130d0
      e(   4) =          0.94962600d0
      s(   4) =          1.00000000d0
      e(   5) =          0.43111800d0
      s(   5) =          1.00000000d0
      e(   6) =          0.12693100d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04653900d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01500000d0
      s(   8) =          1.00000000d0
      e(   9) =          7.24965700d0
      p(   9) =          2.06101380d0
      e(  10) =          6.08487600d0
      p(  10) =         -3.00024710d0
      e(  11) =          1.69408900d0
      p(  11) =          0.21339640d0
      e(  12) =          0.89114400d0
      p(  12) =          0.80690390d0
      e(  13) =          0.34832800d0
      p(  13) =          1.00000000d0
      e(  14) =          0.08467000d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02702800d0
      p(  15) =          1.00000000d0
      e(  16) =          3.44224800d0
      d(  16) =         -0.19325620d0
      e(  17) =          2.66715100d0
      d(  17) =          0.20793290d0
      e(  18) =          0.94710900d0
      d(  18) =          0.44238520d0
      e(  19) =          0.36538400d0
      d(  19) =          0.61598820d0
      e(  20) =          0.12090300d0
      d(  20) =          1.00000000d0
      e(  21) =          0.04000000d0
      d(  21) =          1.00000000d0
c
      go to 800
c
c re   
c
  500 continue
c
      e(   1) =         14.78186200d0
      s(   1) =         -1.14103820d0
      e(   2) =         12.32407500d0
      s(   2) =          1.93714500d0
      e(   3) =          5.49747800d0
      s(   3) =         -1.72327450d0
      e(   4) =          1.02605200d0
      s(   4) =          1.00000000d0
      e(   5) =          0.46900900d0
      s(   5) =          1.00000000d0
      e(   6) =          0.13118400d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04785700d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01500000d0
      s(   8) =          1.00000000d0
      e(   9) =          7.40400500d0
      p(   9) =          2.36983600d0
      e(  10) =          6.35020600d0
      p(  10) =         -3.31055420d0
      e(  11) =          1.88859900d0
      p(  11) =          0.18219610d0
      e(  12) =          0.98348500d0
      p(  12) =          0.83630770d0
      e(  13) =          0.38341000d0
      p(  13) =          1.00000000d0
      e(  14) =          0.07046000d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02202800d0
      p(  15) =          1.00000000d0
      e(  16) =          3.43448200d0
      d(  16) =         -0.36267070d0
      e(  17) =          2.98078100d0
      d(  17) =          0.37616960d0
      e(  18) =          1.01739400d0
      d(  18) =          0.45783320d0
      e(  19) =          0.39506000d0
      d(  19) =          0.59957020d0
      e(  20) =          0.13011100d0
      d(  20) =          1.00000000d0
      e(  21) =          0.04000000d0
      d(  21) =          1.00000000d0
c
      go to 800
c
c os   
c
  520 continue
c
      e(   1) =         15.28673600d0
      s(   1) =         -1.06641470d0
      e(   2) =         12.70063800d0
      s(   2) =          1.84307610d0
      e(   3) =          5.68729500d0
      s(   3) =         -1.70590020d0
      e(   4) =          1.11808700d0
      s(   4) =          1.00000000d0
      e(   5) =          0.52073300d0
      s(   5) =          1.00000000d0
      e(   6) =          0.13637800d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04959200d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01500000d0
      s(   8) =          1.00000000d0
      e(   9) =          7.93627900d0
      p(   9) =          1.41904520d0
      e(  10) =          6.30364100d0
      p(  10) =         -2.36244950d0
      e(  11) =          1.97032300d0
      p(  11) =          0.20640200d0
      e(  12) =          1.02054700d0
      p(  12) =          0.81429590d0
      e(  13) =          0.40059300d0
      p(  13) =          1.00000000d0
      e(  14) =          0.08712700d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02665700d0
      p(  15) =          1.00000000d0
      e(  16) =          3.58081500d0
      d(  16) =         -0.46708080d0
      e(  17) =          3.19616500d0
      d(  17) =          0.47948060d0
      e(  18) =          1.10582500d0
      d(  18) =          0.46491470d0
      e(  19) =          0.43603200d0
      d(  19) =          0.58935760d0
      e(  20) =          0.14433200d0
      d(  20) =          1.00000000d0
      e(  21) =          0.05000000d0
      d(  21) =          1.00000000d0
c
      go to 800
c
c ir   
c
  540 continue
c
      e(   1) =         15.29370900d0
      s(   1) =         -1.67503390d0
      e(   2) =         13.57368200d0
      s(   2) =          2.39346480d0
      e(   3) =          5.81627400d0
      s(   3) =         -1.65049790d0
      e(   4) =          1.19552100d0
      s(   4) =          1.00000000d0
      e(   5) =          0.56577600d0
      s(   5) =          1.00000000d0
      e(   6) =          0.14052700d0
      s(   6) =          1.00000000d0
      e(   7) =          0.05082000d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01500000d0
      s(   8) =          1.00000000d0
      e(   9) =          8.66979600d0
      p(   9) =          0.86771420d0
      e(  10) =          6.24561400d0
      p(  10) =         -1.81448260d0
      e(  11) =          1.96638400d0
      p(  11) =          0.27094540d0
      e(  12) =          1.02020600d0
      p(  12) =          0.75404430d0
      e(  13) =          0.40658000d0
      p(  13) =          1.00000000d0
      e(  14) =          0.09011600d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02736400d0
      p(  15) =          1.00000000d0
      e(  16) =          3.69948500d0
      d(  16) =         -0.59731040d0
      e(  17) =          3.36174300d0
      d(  17) =          0.61122520d0
      e(  18) =          1.17452500d0
      d(  18) =          0.47329390d0
      e(  19) =          0.47017600d0
      d(  19) =          0.57553020d0
      e(  20) =          0.15767800d0
      d(  20) =          1.00000000d0
      e(  21) =          0.05000000d0
      d(  21) =          1.00000000d0
c
      go to 800
c
c pt   
c
  560 continue
c
      e(   1) =         16.55956300d0
      s(   1) =         -0.88494470d0
      e(   2) =         13.89244000d0
      s(   2) =          1.50112280d0
      e(   3) =          5.85360800d0
      s(   3) =         -1.55290120d0
      e(   4) =          1.28732000d0
      s(   4) =          1.00000000d0
      e(   5) =          0.60473200d0
      s(   5) =          1.00000000d0
      e(   6) =          0.14278300d0
      s(   6) =          1.00000000d0
      e(   7) =          0.05096900d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01500000d0
      s(   8) =          1.00000000d0
      e(   9) =          7.92517500d0
      p(   9) =          4.95307570d0
      e(  10) =          7.34153800d0
      p(  10) =         -5.89821000d0
      e(  11) =          1.91251500d0
      p(  11) =          0.30474250d0
      e(  12) =          1.07154500d0
      p(  12) =          0.71648940d0
      e(  13) =          0.43791700d0
      p(  13) =          1.00000000d0
      e(  14) =          0.09362100d0
      p(  14) =          1.00000000d0
      e(  15) =          0.02780200d0
      p(  15) =          1.00000000d0
      e(  16) =          3.93953100d0
      d(  16) =         -0.58264390d0
      e(  17) =          3.58777700d0
      d(  17) =          0.59225760d0
      e(  18) =          1.28623100d0
      d(  18) =          0.47369210d0
      e(  19) =          0.51981400d0
      d(  19) =          0.57652020d0
      e(  20) =          0.17471500d0
      d(  20) =          1.00000000d0
      e(  21) =          0.05000000d0
      d(  21) =          1.00000000d0
c
      go to 800
c
c au   
c
  580 continue
c
      e(   1) =         30.19653700d0
      s(   1) =          0.00473300d0
      e(   2) =          9.72597300d0
      s(   2) =         -0.35438200d0
      e(   3) =          5.08040600d0
      s(   3) =          1.00000000d0
      e(   4) =          1.72265700d0
      s(   4) =          1.00000000d0
      e(   5) =          0.72645900d0
      s(   5) =          1.00000000d0
      e(   6) =          0.09035400d0
      s(   6) =          1.00000000d0
      e(   7) =          0.02210600d0
      s(   7) =          1.00000000d0
      e(   8) =          0.00641500d0
      s(   8) =          1.00000000d0
      e(   9) =         13.83821900d0
      p(   9) =          0.03617900d0
      e(  10) =          5.19578700d0
      p(  10) =         -0.32830300d0
      e(  11) =          1.79804500d0
      p(  11) =          0.66538800d0
      e(  12) =          0.66610500d0
      p(  12) =          0.55266600d0
      e(  13) =          0.15433600d0
      p(  13) =          1.00000000d0
      e(  14) =          0.03400000d0
      p(  14) =          1.00000000d0
      e(  15) =          6.33700100d0
      d(  15) =         -0.04410300d0
      e(  16) =          1.48069700d0
      d(  16) =          0.46211500d0
      e(  17) =          0.52838200d0
      d(  17) =          1.00000000d0
      e(  18) =          0.17111700d0
      d(  18) =          1.00000000d0
      e(  19) =          0.04551200d0
      d(  19) =          1.00000000d0
c
      go to 800
c
c hg   
c
  600 continue
c
      e(   1) =         20.41118100d0
      s(   1) =         -0.04493600d0
      e(   2) =          8.00219000d0
      s(   2) =          1.30917600d0
      e(   3) =          6.06154600d0
      s(   3) =         -1.84510200d0
      e(   4) =          1.14870700d0
      s(   4) =          1.00000000d0
      e(   5) =          0.53792600d0
      s(   5) =          1.00000000d0
      e(   6) =          0.12031200d0
      s(   6) =          1.00000000d0
      e(   7) =          0.04351000d0
      s(   7) =          1.00000000d0
      e(   8) =          0.01500000d0
      s(   8) =          1.00000000d0
      e(   9) =          9.28385800d0
      p(   9) =          0.18889400d0
      e(  10) =          6.52194500d0
      p(  10) =         -0.42597700d0
      e(  11) =          1.68634500d0
      p(  11) =          0.50237400d0
      e(  12) =          0.87901900d0
      p(  12) =          0.51557000d0
      e(  13) =          0.39318100d0
      p(  13) =          1.00000000d0
      e(  14) =          0.11252200d0
      p(  14) =          1.00000000d0
      e(  15) =          0.03759500d0
      p(  15) =          1.00000000d0
      e(  16) =          0.01200000d0
      p(  16) =          1.00000000d0
      e(  17) =          5.01956200d0
      d(  17) =         -0.10213600d0
      e(  18) =          2.71380100d0
      d(  18) =          0.18948000d0
      e(  19) =          1.25783800d0
      d(  19) =          0.44414900d0
      e(  20) =          0.55354400d0
      d(  20) =          0.42761500d0
      e(  21) =          0.21216500d0
      d(  21) =          1.00000000d0
      e(  22) =          0.07000000d0
      d(  22) =          1.00000000d0
      e(  23) =          0.02000000d0
      d(  23) =          1.00000000d0
c
      go to 800
c
c tl  
c
  620 call caserr2('No Stuttgart RSC ecp basis for Lu, Tl - Rn')
c
800   return
      end
      subroutine strsc_5(e,s,p,d,f,n)
c
c   RSC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- ECP basis (Fr-Lw) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-86
      go to (100,100,140,
     +   160,180,200,220,240,260,280,300,320,340,360,380,400,420),
     +   nn
c
c fr , ra
c
  100 call caserr2('No Stuttgart RSC ecp basis for Fr or Ra')
c
      return
c
c ac   
c
  140 continue
c
      e(   1) =       1572.48180000d0
      s(   1) =          0.00042100d0
      e(   2) =        194.88822000d0
      s(   2) =          0.00213300d0
      e(   3) =         22.82375700d0
      s(   3) =         -0.45996900d0
      e(   4) =         17.69174000d0
      s(   4) =          1.12573900d0
      e(   5) =          9.46165200d0
      s(   5) =         -1.37806000d0
      e(   6) =          2.36868300d0
      s(   6) =          1.09137900d0
      e(   7) =          1.24060300d0
      s(   7) =          0.36713200d0
      e(   8) =       1572.48180000d0
      s(   8) =         -0.00028200d0
      e(   9) =        194.88822000d0
      s(   9) =         -0.00108600d0
      e(  10) =         22.82375700d0
      s(  10) =          0.22405700d0
      e(  11) =         17.69174000d0
      s(  11) =         -0.58022500d0
      e(  12) =          9.46165200d0
      s(  12) =          0.79955900d0
      e(  13) =          2.36868300d0
      s(  13) =         -1.02262500d0
      e(  14) =          1.24060300d0
      s(  14) =         -0.41583200d0
      e(  15) =       1572.48180000d0
      s(  15) =          0.00009500d0
      e(  16) =        194.88822000d0
      s(  16) =          0.00035500d0
      e(  17) =         22.82375700d0
      s(  17) =         -0.07200100d0
      e(  18) =         17.69174000d0
      s(  18) =          0.18797300d0
      e(  19) =          9.46165200d0
      s(  19) =         -0.26384500d0
      e(  20) =          2.36868300d0
      s(  20) =          0.36725300d0
      e(  21) =          1.24060300d0
      s(  21) =          0.16341700d0
      e(  22) =          0.55076200d0
      s(  22) =          1.00000000d0
      e(  23) =          0.26040700d0
      s(  23) =          1.00000000d0
      e(  24) =          0.06911300d0
      s(  24) =          1.00000000d0
      e(  25) =          0.03046900d0
      s(  25) =          1.00000000d0
      e(  26) =          0.01000000d0
      s(  26) =          1.00000000d0
      e(  27) =        395.65593000d0
      p(  27) =          0.00063600d0
      e(  28) =         90.76730100d0
      p(  28) =          0.00337800d0
      e(  29) =         13.19370000d0
      p(  29) =          0.16283300d0
      e(  30) =          9.03647600d0
      p(  30) =         -0.34298900d0
      e(  31) =          7.40362600d0
      p(  31) =         -0.08648900d0
      e(  32) =          2.87514600d0
      p(  32) =          0.61623800d0
      e(  33) =        395.65593000d0
      p(  33) =         -0.00035700d0
      e(  34) =         90.76730100d0
      p(  34) =         -0.00211200d0
      e(  35) =         13.19370000d0
      p(  35) =         -0.09408300d0
      e(  36) =          9.03647600d0
      p(  36) =          0.26214300d0
      e(  37) =          7.40362600d0
      p(  37) =         -0.04302100d0
      e(  38) =          2.87514600d0
      p(  38) =         -0.42215200d0
      e(  39) =          1.46710500d0
      p(  39) =          1.00000000d0
      e(  40) =          0.56146600d0
      p(  40) =          1.00000000d0
      e(  41) =          0.23526200d0
      p(  41) =          1.00000000d0
      e(  42) =          0.04241100d0
      p(  42) =          1.00000000d0
      e(  43) =          0.01000000d0
      p(  43) =          1.00000000d0
      e(  44) =         80.69891100d0
      d(  44) =          0.00067100d0
      e(  45) =         62.82613200d0
      d(  45) =         -0.00065700d0
      e(  46) =         14.77606700d0
      d(  46) =          0.04431700d0
      e(  47) =          9.70711800d0
      d(  47) =         -0.15330400d0
      e(  48) =          3.29749400d0
      d(  48) =          0.38031400d0
      e(  49) =          1.70491400d0
      d(  49) =          0.51379600d0
      e(  50) =         80.69891100d0
      d(  50) =          0.00004600d0
      e(  51) =         62.82613200d0
      d(  51) =         -0.00016200d0
      e(  52) =         14.77606700d0
      d(  52) =         -0.01038300d0
      e(  53) =          9.70711800d0
      d(  53) =          0.03963800d0
      e(  54) =          3.29749400d0
      d(  54) =         -0.11588900d0
      e(  55) =          1.70491400d0
      d(  55) =         -0.16150600d0
      e(  56) =          0.83047900d0
      d(  56) =          1.00000000d0
      e(  57) =          0.35021900d0
      d(  57) =          1.00000000d0
      e(  58) =          0.13916100d0
      d(  58) =          1.00000000d0
      e(  59) =          0.05000000d0
      d(  59) =          1.00000000d0
      e(  60) =         58.07969000d0
      f(  60) =          0.00000900d0
      e(  61) =          2.61535900d0
      f(  61) =          0.00909700d0
      e(  62) =          0.94540100d0
      f(  62) =          0.01591900d0
      e(  63) =          0.30829900d0
      f(  63) =          0.02123200d0
      e(  64) =          0.09022200d0
      f(  64) =          0.01876900d0
      e(  65) =          0.02758200d0
      f(  65) =          1.00000000d0
      e(  66) =          0.00574700d0
      f(  66) =          1.00000000d0
      e(  67) =          0.00100000d0
      f(  67) =          1.00000000d0
c
      return
c
c th   
c
  160 continue
c
      e(   1) =       1834.86870000d0
      s(   1) =          0.00146800d0
      e(   2) =        274.52428000d0
      s(   2) =          0.00609400d0
      e(   3) =         22.15898700d0
      s(   3) =         -0.47811500d0
      e(   4) =         17.44715100d0
      s(   4) =          1.24476200d0
      e(   5) =         10.02213900d0
      s(   5) =         -1.47313300d0
      e(   6) =          2.44750200d0
      s(   6) =          1.13703900d0
      e(   7) =          1.24802400d0
      s(   7) =          0.32621950d0
      e(   8) =       1834.86870000d0
      s(   8) =         -0.00136500d0
      e(   9) =        274.52428000d0
      s(   9) =         -0.00544000d0
      e(  10) =         22.15898700d0
      s(  10) =          0.22050300d0
      e(  11) =         17.44715100d0
      s(  11) =         -0.63693600d0
      e(  12) =         10.02213900d0
      s(  12) =          0.87106300d0
      e(  13) =          2.44750200d0
      s(  13) =         -1.13522200d0
      e(  14) =          1.24802400d0
      s(  14) =         -0.34030060d0
      e(  15) =       1834.86870000d0
      s(  15) =          0.00051300d0
      e(  16) =        274.52428000d0
      s(  16) =          0.00204200d0
      e(  17) =         22.15898700d0
      s(  17) =         -0.07203100d0
      e(  18) =         17.44715100d0
      s(  18) =          0.21284800d0
      e(  19) =         10.02213900d0
      s(  19) =         -0.29921800d0
      e(  20) =          2.44750200d0
      s(  20) =          0.42980100d0
      e(  21) =          1.24802400d0
      s(  21) =          0.14531520d0
      e(  22) =          0.57157600d0
      s(  22) =          1.00000000d0
      e(  23) =          0.27152600d0
      s(  23) =          1.00000000d0
      e(  24) =          0.07714700d0
      s(  24) =          1.00000000d0
      e(  25) =          0.03254700d0
      s(  25) =          1.00000000d0
      e(  26) =          0.01000000d0
      s(  26) =          1.00000000d0
      e(  27) =        368.60375000d0
      p(  27) =          0.00115500d0
      e(  28) =         84.96395900d0
      p(  28) =          0.00580000d0
      e(  29) =         14.33632100d0
      p(  29) =          0.12588900d0
      e(  30) =          9.03647600d0
      p(  30) =         -0.31370100d0
      e(  31) =          7.05107300d0
      p(  31) =         -0.06762300d0
      e(  32) =          2.96487100d0
      p(  32) =          0.62167300d0
      e(  33) =        368.60375000d0
      p(  33) =         -0.00072100d0
      e(  34) =         84.96395900d0
      p(  34) =         -0.00385300d0
      e(  35) =         14.33632100d0
      p(  35) =         -0.07897500d0
      e(  36) =          9.03647600d0
      p(  36) =          0.26322600d0
      e(  37) =          7.05107300d0
      p(  37) =         -0.07219400d0
      e(  38) =          2.96487100d0
      p(  38) =         -0.42793800d0
      e(  39) =          1.56941300d0
      p(  39) =          1.00000000d0
      e(  40) =          0.75704000d0
      p(  40) =          1.00000000d0
      e(  41) =          0.37051300d0
      p(  41) =          1.00000000d0
      e(  42) =          0.16666100d0
      p(  42) =          1.00000000d0
      e(  43) =          0.05000000d0
      p(  43) =          1.00000000d0
      e(  44) =         83.19475400d0
      d(  44) =          0.00065300d0
      e(  45) =         64.76920800d0
      d(  45) =         -0.00043400d0
      e(  46) =         14.41984600d0
      d(  46) =          0.06918600d0
      e(  47) =         10.66166400d0
      d(  47) =         -0.16947300d0
      e(  48) =          3.33545800d0
      d(  48) =          0.42399500d0
      e(  49) =          1.70196800d0
      d(  49) =          0.50921500d0
      e(  50) =         83.19475400d0
      d(  50) =          0.00011600d0
      e(  51) =         64.76920800d0
      d(  51) =         -0.00034100d0
      e(  52) =         14.41984600d0
      d(  52) =         -0.01814500d0
      e(  53) =         10.66166400d0
      d(  53) =          0.04856300d0
      e(  54) =          3.33545800d0
      d(  54) =         -0.14970900d0
      e(  55) =          1.70196800d0
      d(  55) =         -0.18320800d0
      e(  56) =          0.82602700d0
      d(  56) =          1.00000000d0
      e(  57) =          0.34523100d0
      d(  57) =          1.00000000d0
      e(  58) =          0.13641300d0
      d(  58) =          1.00000000d0
      e(  59) =          0.05000000d0
      d(  59) =          1.00000000d0
      e(  60) =         89.98335000d0
      f(  60) =          0.00002200d0
      e(  61) =         35.68132900d0
      f(  61) =          0.00114200d0
      e(  62) =          4.36051800d0
      f(  62) =          0.05663500d0
      e(  63) =          2.53487200d0
      f(  63) =          0.23564200d0
      e(  64) =          1.12299300d0
      f(  64) =          0.39192000d0
      e(  65) =          0.45741100d0
      f(  65) =          1.00000000d0
      e(  66) =          0.17407400d0
      f(  66) =          1.00000000d0
      e(  67) =          0.05908700d0
      f(  67) =          1.00000000d0
c
      return
c
c pa   
c
  180 continue
c
      e(   1) =       2002.40530000d0
      s(   1) =          0.00209100d0
      e(   2) =        299.10987000d0
      s(   2) =          0.00869100d0
      e(   3) =         22.37229200d0
      s(   3) =         -0.34774500d0
      e(   4) =         16.32920100d0
      s(   4) =          1.46147100d0
      e(   5) =         10.86050100d0
      s(   5) =         -1.82245800d0
      e(   6) =          2.54917500d0
      s(   6) =          1.14223900d0
      e(   7) =          1.30350500d0
      s(   7) =          0.32176400d0
      e(   8) =       2002.40530000d0
      s(   8) =         -0.00237900d0
      e(   9) =        299.10987000d0
      s(   9) =         -0.00983600d0
      e(  10) =         22.37229200d0
      s(  10) =          0.13479100d0
      e(  11) =         16.32920100d0
      s(  11) =         -0.72142100d0
      e(  12) =         10.86050100d0
      s(  12) =          1.03402500d0
      e(  13) =          2.54917500d0
      s(  13) =         -1.12340900d0
      e(  14) =          1.30350500d0
      s(  14) =         -0.32665200d0
      e(  15) =       2002.40530000d0
      s(  15) =          0.00087600d0
      e(  16) =        299.10987000d0
      s(  16) =          0.00363100d0
      e(  17) =         22.37229200d0
      s(  17) =         -0.03789800d0
      e(  18) =         16.32920100d0
      s(  18) =          0.21942100d0
      e(  19) =         10.86050100d0
      s(  19) =         -0.32475700d0
      e(  20) =          2.54917500d0
      s(  20) =          0.39015000d0
      e(  21) =          1.30350500d0
      s(  21) =          0.12432600d0
      e(  22) =          0.59391800d0
      s(  22) =          1.00000000d0
      e(  23) =          0.27723100d0
      s(  23) =          1.00000000d0
      e(  24) =          0.06991800d0
      s(  24) =          1.00000000d0
      e(  25) =          0.03016500d0
      s(  25) =          1.00000000d0
      e(  26) =          0.01000000d0
      s(  26) =          1.00000000d0
      e(  27) =        417.61544000d0
      p(  27) =         -0.00069500d0
      e(  28) =         96.69706600d0
      p(  28) =         -0.00349600d0
      e(  29) =         13.33111200d0
      p(  29) =         -0.27841900d0
      e(  30) =         10.16924800d0
      p(  30) =          0.51348300d0
      e(  31) =          7.56248400d0
      p(  31) =          0.02837400d0
      e(  32) =          3.01457700d0
      p(  32) =         -0.66995500d0
      e(  33) =        417.61544000d0
      p(  33) =         -0.00040300d0
      e(  34) =         96.69706600d0
      p(  34) =         -0.00221900d0
      e(  35) =         13.33111200d0
      p(  35) =         -0.16910200d0
      e(  36) =         10.16924800d0
      p(  36) =          0.36208000d0
      e(  37) =          7.56248400d0
      p(  37) =         -0.07562400d0
      e(  38) =          3.01457700d0
      p(  38) =         -0.45325800d0
      e(  39) =          1.56651600d0
      p(  39) =          1.00000000d0
      e(  40) =          0.71832800d0
      p(  40) =          1.00000000d0
      e(  41) =          0.33435900d0
      p(  41) =          1.00000000d0
      e(  42) =          0.13881900d0
      p(  42) =          1.00000000d0
      e(  43) =          0.01000000d0
      p(  43) =          1.00000000d0
      e(  44) =         83.25785400d0
      d(  44) =         -0.00093800d0
      e(  45) =         17.35910400d0
      d(  45) =         -0.16910200d0
      e(  46) =          9.64207200d0
      d(  46) =          0.36208000d0
      e(  47) =          3.71217300d0
      d(  47) =         -0.35354200d0
      e(  48) =          1.98392500d0
      d(  48) =         -0.50604100d0
      e(  49) =          0.99179900d0
      d(  49) =         -0.25846000d0
      e(  50) =         83.25785400d0
      d(  50) =         -0.00038800d0
      e(  51) =         17.35910400d0
      d(  51) =         -0.02326800d0
      e(  52) =          9.64207200d0
      d(  52) =          0.11208200d0
      e(  53) =          3.71217300d0
      d(  53) =         -0.13283400d0
      e(  54) =          1.98392500d0
      d(  54) =         -0.18193700d0
      e(  55) =          0.99179900d0
      d(  55) =         -0.00767700d0
      e(  56) =          0.43294200d0
      d(  56) =          1.00000000d0
      e(  57) =          0.17376400d0
      d(  57) =          1.00000000d0
      e(  58) =          0.06337500d0
      d(  58) =          1.00000000d0
      e(  59) =          0.01000000d0
      d(  59) =          1.00000000d0
      e(  60) =         41.56141200d0
      f(  60) =          0.00128500d0
      e(  61) =         15.69197200d0
      f(  61) =          0.00511600d0
      e(  62) =          4.03098200d0
      f(  62) =          0.15503200d0
      e(  63) =          1.92590800d0
      f(  63) =          0.34678700d0
      e(  64) =          0.86282000d0
      f(  64) =          0.40018200d0
      e(  65) =          0.35617300d0
      f(  65) =          1.00000000d0
      e(  66) =          0.12863100d0
      f(  66) =          1.00000000d0
      e(  67) =          0.01000000d0
      f(  67) =          1.00000000d0
c
      return
c
c u   
c
  200 continue
c
      e(   1) =       1534.93360000d0
      s(   1) =          0.00092000d0
      e(   2) =        227.74838000d0
      s(   2) =          0.00368200d0
      e(   3) =         30.69683100d0
      s(   3) =         -0.15023100d0
      e(   4) =         18.17062600d0
      s(   4) =          0.90399500d0
      e(   5) =         10.81353700d0
      s(   5) =         -1.48592200d0
      e(   6) =          2.73329800d0
      s(   6) =          1.12440400d0
      e(   7) =          1.43149800d0
      s(   7) =          0.35107600d0
      e(   8) =       1534.93360000d0
      s(   8) =         -0.00069500d0
      e(   9) =        227.74838000d0
      s(   9) =         -0.00229300d0
      e(  10) =         30.69683100d0
      s(  10) =          0.07244400d0
      e(  11) =         18.17062600d0
      s(  11) =         -0.49055900d0
      e(  12) =         10.81353700d0
      s(  12) =          0.88984000d0
      e(  13) =          2.73329800d0
      s(  13) =         -1.11575800d0
      e(  14) =          1.43149800d0
      s(  14) =         -0.33365000d0
      e(  15) =       1534.93360000d0
      s(  15) =          0.00022300d0
      e(  16) =        227.74838000d0
      s(  16) =          0.00072200d0
      e(  17) =         30.69683100d0
      s(  17) =         -0.02170200d0
      e(  18) =         18.17062600d0
      s(  18) =          0.14979600d0
      e(  19) =         10.81353700d0
      s(  19) =         -0.27611000d0
      e(  20) =          2.73329800d0
      s(  20) =          0.37657900d0
      e(  21) =          1.43149800d0
      s(  21) =          0.12440800d0
      e(  22) =          0.61529800d0
      s(  22) =          1.00000000d0
      e(  23) =          0.28663900d0
      s(  23) =          1.00000000d0
      e(  24) =          0.07117000d0
      s(  24) =          1.00000000d0
      e(  25) =          0.03053900d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00500000d0
      s(  26) =          1.00000000d0
      e(  27) =        553.34525000d0
      p(  27) =         -0.00161000d0
      e(  28) =        109.25501000d0
      p(  28) =         -0.01108700d0
      e(  29) =         23.47603000d0
      p(  29) =         -0.04661900d0
      e(  30) =          6.79447200d0
      p(  30) =          0.64415300d0
      e(  31) =          5.43231900d0
      p(  31) =         -0.52045500d0
      e(  32) =          2.70216900d0
      p(  32) =         -0.63115400d0
      e(  33) =        553.34525000d0
      p(  33) =         -0.00107500d0
      e(  34) =        109.25501000d0
      p(  34) =         -0.00804200d0
      e(  35) =         23.47603000d0
      p(  35) =         -0.02796900d0
      e(  36) =          6.79447200d0
      p(  36) =          0.46904900d0
      e(  37) =          5.43231900d0
      p(  37) =         -0.49263900d0
      e(  38) =          2.70216900d0
      p(  38) =         -0.37576600d0
      e(  39) =          1.49385700d0
      p(  39) =          1.00000000d0
      e(  40) =          0.79281700d0
      p(  40) =          1.00000000d0
      e(  41) =          0.35154200d0
      p(  41) =          1.00000000d0
      e(  42) =          0.14396200d0
      p(  42) =          1.00000000d0
      e(  43) =          0.00500000d0
      p(  43) =          1.00000000d0
      e(  44) =         81.20285800d0
      d(  44) =         -0.00162000d0
      e(  45) =         18.32557500d0
      d(  45) =         -0.02518100d0
      e(  46) =         10.45469900d0
      d(  46) =          0.08963200d0
      e(  47) =          3.66631200d0
      d(  47) =         -0.40942900d0
      e(  48) =          1.92334900d0
      d(  48) =         -0.48226000d0
      e(  49) =          0.98963800d0
      d(  49) =         -0.21090300d0
      e(  50) =         81.20285800d0
      d(  50) =         -0.00063900d0
      e(  51) =         18.32557500d0
      d(  51) =         -0.00702100d0
      e(  52) =         10.45469900d0
      d(  52) =          0.02664200d0
      e(  53) =          3.66631200d0
      d(  53) =         -0.15713200d0
      e(  54) =          1.92334900d0
      d(  54) =         -0.15757200d0
      e(  55) =          0.98963800d0
      d(  55) =         -0.00110000d0
      e(  56) =          0.49534600d0
      d(  56) =          1.00000000d0
      e(  57) =          0.20445500d0
      d(  57) =          1.00000000d0
      e(  58) =          0.07327300d0
      d(  58) =          1.00000000d0
      e(  59) =          0.00500000d0
      d(  59) =          1.00000000d0
      e(  60) =         55.33452500d0
      f(  60) =          0.00129400d0
      e(  61) =         16.58864900d0
      f(  61) =          0.00985700d0
      e(  62) =          4.75751800d0
      f(  62) =          0.13038600d0
      e(  63) =          2.38755000d0
      f(  63) =          0.31808300d0
      e(  64) =          1.13019500d0
      f(  64) =          0.39531400d0
      e(  65) =          0.48953500d0
      f(  65) =          1.00000000d0
      e(  66) =          0.18142000d0
      f(  66) =          1.00000000d0
      e(  67) =          0.00500000d0
      f(  67) =          1.00000000d0
c
      return
c
c np   
c
  220 continue
c
      e(   1) =       2190.23970000d0
      s(   1) =          0.00162900d0
      e(   2) =        327.21100000d0
      s(   2) =          0.00667800d0
      e(   3) =         23.41845500d0
      s(   3) =         -0.75388800d0
      e(   4) =         19.16544500d0
      s(   4) =          1.77775700d0
      e(   5) =         11.80536500d0
      s(   5) =         -1.74321600d0
      e(   6) =          2.77892400d0
      s(   6) =          1.17411700d0
      e(   7) =          1.38808400d0
      s(   7) =          0.30003900d0
      e(   8) =       2190.23970000d0
      s(   8) =         -0.00170200d0
      e(   9) =        327.21100000d0
      s(   9) =         -0.00681400d0
      e(  10) =         23.41845500d0
      s(  10) =          0.34704900d0
      e(  11) =         19.16544500d0
      s(  11) =         -0.90025900d0
      e(  12) =         11.80536500d0
      s(  12) =          1.01419600d0
      e(  13) =          2.77892400d0
      s(  13) =         -1.18047900d0
      e(  14) =          1.38808400d0
      s(  14) =         -0.25950900d0
      e(  15) =       2190.23970000d0
      s(  15) =          0.00058300d0
      e(  16) =        327.21100000d0
      s(  16) =          0.00233700d0
      e(  17) =         23.41845500d0
      s(  17) =         -0.10040000d0
      e(  18) =         19.16544500d0
      s(  18) =          0.26637400d0
      e(  19) =         11.80536500d0
      s(  19) =         -0.30836900d0
      e(  20) =          2.77892400d0
      s(  20) =          0.39417900d0
      e(  21) =          1.38808400d0
      s(  21) =          0.09651200d0
      e(  22) =          0.63551800d0
      s(  22) =          1.00000000d0
      e(  23) =          0.29421000d0
      s(  23) =          1.00000000d0
      e(  24) =          0.07020600d0
      s(  24) =          1.00000000d0
      e(  25) =          0.02872100d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00500000d0
      s(  26) =          1.00000000d0
      e(  27) =        416.56591000d0
      p(  27) =         -0.00180400d0
      e(  28) =         96.89553200d0
      p(  28) =         -0.00906300d0
      e(  29) =         17.78301300d0
      p(  29) =         -0.09957900d0
      e(  30) =         10.58680800d0
      p(  30) =          0.20309100d0
      e(  31) =          7.51378700d0
      p(  31) =          0.15643800d0
      e(  32) =          3.27449400d0
      p(  32) =         -0.71387900d0
      e(  33) =        416.56591000d0
      p(  33) =         -0.00117900d0
      e(  34) =         96.89553200d0
      p(  34) =         -0.00618300d0
      e(  35) =         17.78301300d0
      p(  35) =         -0.06519700d0
      e(  36) =         10.58680800d0
      p(  36) =          0.18265900d0
      e(  37) =          7.51378700d0
      p(  37) =         -0.00999500d0
      e(  38) =          3.27449400d0
      p(  38) =         -0.49179300d0
      e(  39) =          1.61772100d0
      p(  39) =          1.00000000d0
      e(  40) =          0.77452800d0
      p(  40) =          1.00000000d0
      e(  41) =          0.35258200d0
      p(  41) =          1.00000000d0
      e(  42) =          0.14448500d0
      p(  42) =          1.00000000d0
      e(  43) =          0.00500000d0
      p(  43) =          1.00000000d0
      e(  44) =         86.21840900d0
      d(  44) =         -0.00170100d0
      e(  45) =         19.77043400d0
      d(  45) =         -0.02250000d0
      e(  46) =         10.55907900d0
      d(  46) =          0.08771900d0
      e(  47) =          3.85346900d0
      d(  47) =         -0.40111100d0
      e(  48) =          2.04479400d0
      d(  48) =         -0.48341200d0
      e(  49) =          1.04290100d0
      d(  49) =         -0.22285600d0
      e(  50) =         86.21840900d0
      d(  50) =         -0.00067700d0
      e(  51) =         19.77043400d0
      d(  51) =         -0.00632000d0
      e(  52) =         10.55907900d0
      d(  52) =          0.02619200d0
      e(  53) =          3.85346900d0
      d(  53) =         -0.15489700d0
      e(  54) =          2.04479400d0
      d(  54) =         -0.16324100d0
      e(  55) =          1.04290100d0
      d(  55) =          0.01261800d0
      e(  56) =          0.47890900d0
      d(  56) =          1.00000000d0
      e(  57) =          0.19140500d0
      d(  57) =          1.00000000d0
      e(  58) =          0.06784800d0
      d(  58) =          1.00000000d0
      e(  59) =          0.00500000d0
      d(  59) =          1.00000000d0
      e(  60) =         37.85902900d0
      f(  60) =          0.00324700d0
      e(  61) =         13.42103900d0
      f(  61) =          0.01404500d0
      e(  62) =          4.71536700d0
      f(  62) =          0.15535100d0
      e(  63) =          2.37200900d0
      f(  63) =          0.33712800d0
      e(  64) =          1.12862900d0
      f(  64) =          0.39382800d0
      e(  65) =          0.48946800d0
      f(  65) =          1.00000000d0
      e(  66) =          0.18289800d0
      f(  66) =          1.00000000d0
      e(  67) =          0.00500000d0
      f(  67) =          1.00000000d0
c
      return
c
c pu   
c
  240 continue
c
      e(   1) =        948.68027000d0
      s(   1) =          0.00049700d0
      e(   2) =         54.71578300d0
      s(   2) =          0.05860900d0
      e(   3) =         35.29620500d0
      s(   3) =         -0.44474900d0
      e(   4) =         24.29050100d0
      s(   4) =          0.93644900d0
      e(   5) =         11.29279200d0
      s(   5) =         -1.31585500d0
      e(   6) =          3.06818800d0
      s(   6) =          1.13283900d0
      e(   7) =          1.59369800d0
      s(   7) =          0.37275000d0
      e(   8) =        948.68027000d0
      s(   8) =         -0.00029700d0
      e(   9) =         54.71578300d0
      s(   9) =         -0.02434200d0
      e(  10) =         35.29620500d0
      s(  10) =          0.21226700d0
      e(  11) =         24.29050100d0
      s(  11) =         -0.48949800d0
      e(  12) =         11.29279200d0
      s(  12) =          0.79793800d0
      e(  13) =          3.06818800d0
      s(  13) =         -1.11333800d0
      e(  14) =          1.59369800d0
      s(  14) =         -0.37542500d0
      e(  15) =        948.68027000d0
      s(  15) =          0.00009000d0
      e(  16) =         54.71578300d0
      s(  16) =          0.00695500d0
      e(  17) =         35.29620500d0
      s(  17) =         -0.06200500d0
      e(  18) =         24.29050100d0
      s(  18) =          0.14496400d0
      e(  19) =         11.29279200d0
      s(  19) =         -0.24182700d0
      e(  20) =          3.06818800d0
      s(  20) =          0.36460100d0
      e(  21) =          1.59369800d0
      s(  21) =          0.13718700d0
      e(  22) =          0.69447400d0
      s(  22) =          1.00000000d0
      e(  23) =          0.31770700d0
      s(  23) =          1.00000000d0
      e(  24) =          0.07242700d0
      s(  24) =          1.00000000d0
      e(  25) =          0.02954800d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00500000d0
      s(  26) =          1.00000000d0
      e(  27) =        451.83704000d0
      p(  27) =         -0.00294900d0
      e(  28) =        105.12519000d0
      p(  28) =         -0.01495300d0
      e(  29) =         25.32626200d0
      p(  29) =         -0.05013000d0
      e(  30) =          6.76904600d0
      p(  30) =          1.00685800d0
      e(  31) =          5.71279700d0
      p(  31) =         -0.98416800d0
      e(  32) =          2.46396500d0
      p(  32) =         -0.73963600d0
      e(  33) =        451.83704000d0
      p(  33) =         -0.00206200d0
      e(  34) =        105.12519000d0
      p(  34) =         -0.01148200d0
      e(  35) =         25.32626200d0
      p(  35) =         -0.03082900d0
      e(  36) =          6.76904600d0
      p(  36) =          0.71552400d0
      e(  37) =          5.71279700d0
      p(  37) =         -0.80653900d0
      e(  38) =          2.46396500d0
      p(  38) =         -0.46806300d0
      e(  39) =          1.15655700d0
      p(  39) =          1.00000000d0
      e(  40) =          0.64755800d0
      p(  40) =          1.00000000d0
      e(  41) =          0.30024700d0
      p(  41) =          1.00000000d0
      e(  42) =          0.12321800d0
      p(  42) =          1.00000000d0
      e(  43) =          0.00500000d0
      p(  43) =          1.00000000d0
      e(  44) =         37.40643400d0
      d(  44) =         -0.00955800d0
      e(  45) =          6.93808200d0
      d(  45) =          0.32602400d0
      e(  46) =          5.50581700d0
      d(  46) =         -0.51021900d0
      e(  47) =          2.53028800d0
      d(  47) =         -0.54044300d0
      e(  48) =          1.30318800d0
      d(  48) =         -0.28159200d0
      e(  49) =          0.65152100d0
      d(  49) =         -0.06456800d0
      e(  50) =         37.40643400d0
      d(  50) =         -0.00319200d0
      e(  51) =          6.93808200d0
      d(  51) =          0.11213700d0
      e(  52) =          5.50581700d0
      d(  52) =         -0.19016700d0
      e(  53) =          2.53028800d0
      d(  53) =         -0.19324400d0
      e(  54) =          1.30318800d0
      d(  54) =         -0.04388900d0
      e(  55) =          0.65152100d0
      d(  55) =          0.22410600d0
      e(  56) =          0.30124600d0
      d(  56) =          1.00000000d0
      e(  57) =          0.13145800d0
      d(  57) =          1.00000000d0
      e(  58) =          0.05302800d0
      d(  58) =          1.00000000d0
      e(  59) =          0.01000000d0
      d(  59) =          1.00000000d0
      e(  60) =         43.17138000d0
      f(  60) =          0.00353600d0
      e(  61) =         14.27742400d0
      f(  61) =          0.02070100d0
      e(  62) =          4.88206200d0
      f(  62) =          0.18438900d0
      e(  63) =          2.32119500d0
      f(  63) =          0.38111200d0
      e(  64) =          1.06803900d0
      f(  64) =          0.38608800d0
      e(  65) =          0.46806100d0
      f(  65) =          1.00000000d0
      e(  66) =          0.18795300d0
      f(  66) =          1.00000000d0
      e(  67) =          0.05000000d0
      f(  67) =          1.00000000d0
c
      return
c
c am   
c
  260 continue
c
      e(   1) =       1000.13120000d0
      s(   1) =          0.00071600d0
      e(   2) =         62.30775500d0
      s(   2) =          0.05715600d0
      e(   3) =         43.58320700d0
      s(   3) =         -0.20894700d0
      e(   4) =         21.91881000d0
      s(   4) =          0.84119900d0
      e(   5) =         12.17958000d0
      s(   5) =         -1.44505900d0
      e(   6) =          3.16469700d0
      s(   6) =          1.14951100d0
      e(   7) =          1.62848700d0
      s(   7) =          0.34913800d0
      e(   8) =       1000.13120000d0
      s(   8) =         -0.00043400d0
      e(   9) =         62.30775500d0
      s(   9) =         -0.02397000d0
      e(  10) =         43.58320700d0
      s(  10) =          0.09634700d0
      e(  11) =         21.91881000d0
      s(  11) =         -0.45515400d0
      e(  12) =         12.17958000d0
      s(  12) =          0.87476200d0
      e(  13) =          3.16469700d0
      s(  13) =         -1.15146800d0
      e(  14) =          1.62848700d0
      s(  14) =         -0.31615800d0
      e(  15) =       1000.13120000d0
      s(  15) =         -0.00013000d0
      e(  16) =         62.30775500d0
      s(  16) =         -0.00677900d0
      e(  17) =         43.58320700d0
      s(  17) =          0.02768800d0
      e(  18) =         21.91881000d0
      s(  18) =         -0.13414200d0
      e(  19) =         12.17958000d0
      s(  19) =          0.26240100d0
      e(  20) =          3.16469700d0
      s(  20) =         -0.37394700d0
      e(  21) =          1.62848700d0
      s(  21) =         -0.11573000d0
      e(  22) =          0.70986300d0
      s(  22) =          1.00000000d0
      e(  23) =          0.32482400d0
      s(  23) =          1.00000000d0
      e(  24) =          0.07443200d0
      s(  24) =          1.00000000d0
      e(  25) =          0.02990900d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00500000d0
      s(  26) =          1.00000000d0
      e(  27) =        768.90597000d0
      p(  27) =         -0.00200900d0
      e(  28) =        140.84581000d0
      p(  28) =         -0.01612100d0
      e(  29) =         32.93808100d0
      p(  29) =         -0.04848200d0
      e(  30) =          6.06134400d0
      p(  30) =          2.12787300d0
      e(  31) =          5.49350500d0
      p(  31) =         -2.25793900d0
      e(  32) =          2.19822600d0
      p(  32) =         -0.70715100d0
      e(  33) =        768.90597000d0
      p(  33) =         -0.00147700d0
      e(  34) =        140.84581000d0
      p(  34) =         -0.01281500d0
      e(  35) =         32.93808100d0
      p(  35) =         -0.03255300d0
      e(  36) =          6.06134400d0
      p(  36) =          1.48336400d0
      e(  37) =          5.49350500d0
      p(  37) =         -1.68934000d0
      e(  38) =          2.19822600d0
      p(  38) =         -0.41383200d0
      e(  39) =          0.89083700d0
      p(  39) =          1.00000000d0
      e(  40) =          0.46365500d0
      p(  40) =          1.00000000d0
      e(  41) =          0.22753800d0
      p(  41) =          1.00000000d0
      e(  42) =          0.09610400d0
      p(  42) =          1.00000000d0
      e(  43) =          0.00500000d0
      p(  43) =          1.00000000d0
      e(  44) =         39.66743300d0
      d(  44) =         -0.01060400d0
      e(  45) =          6.52430400d0
      d(  45) =          0.71990700d0
      e(  46) =          5.83114700d0
      d(  46) =         -0.92806800d0
      e(  47) =          2.57922300d0
      d(  47) =         -0.54114500d0
      e(  48) =          1.30202300d0
      d(  48) =         -0.27292100d0
      e(  49) =          0.65886300d0
      d(  49) =         -0.04905100d0
      e(  50) =         39.66743300d0
      d(  50) =         -0.00354900d0
      e(  51) =          6.52430400d0
      d(  51) =          0.24657800d0
      e(  52) =          5.83114700d0
      d(  52) =         -0.33243500d0
      e(  53) =          2.57922300d0
      d(  53) =         -0.18912800d0
      e(  54) =          1.30202300d0
      d(  54) =         -0.02869000d0
      e(  55) =          0.65886300d0
      d(  55) =          0.20815800d0
      e(  56) =          0.39548900d0
      d(  56) =          1.00000000d0
      e(  57) =          0.23523300d0
      d(  57) =          1.00000000d0
      e(  58) =          0.10827100d0
      d(  58) =          1.00000000d0
      e(  59) =          0.05000000d0
      d(  59) =          1.00000000d0
      e(  60) =         77.36328700d0
      f(  60) =          0.00185500d0
      e(  61) =         18.66756700d0
      f(  61) =          0.02232900d0
      e(  62) =          5.77425400d0
      f(  62) =          0.16139600d0
      e(  63) =          2.65758600d0
      f(  63) =          0.38960600d0
      e(  64) =          1.19829400d0
      f(  64) =          0.39954900d0
      e(  65) =          0.52218100d0
      f(  65) =          1.00000000d0
      e(  66) =          0.21249800d0
      f(  66) =          1.00000000d0
      e(  67) =          0.05000000d0
      f(  67) =          1.00000000d0
c
      return
c
c cm   
c
  280 continue
c
      e(   1) =       2284.10550000d0
      s(   1) =          0.00120300d0
      e(   2) =        348.21736000d0
      s(   2) =          0.00518000d0
      e(   3) =         35.71041300d0
      s(   3) =         -0.16624900d0
      e(   4) =         21.23851200d0
      s(   4) =          1.02113200d0
      e(   5) =         13.02726300d0
      s(   5) =         -1.59547800d0
      e(   6) =          3.26039800d0
      s(   6) =          1.12865700d0
      e(   7) =          1.70664400d0
      s(   7) =          0.35784000d0
      e(   8) =       2284.10550000d0
      s(   8) =         -0.00115700d0
      e(   9) =        348.21736000d0
      s(   9) =         -0.00438600d0
      e(  10) =         35.71041300d0
      s(  10) =          0.07916900d0
      e(  11) =         21.23851200d0
      s(  11) =         -0.55773100d0
      e(  12) =         13.02726300d0
      s(  12) =          0.96097300d0
      e(  13) =          3.26039800d0
      s(  13) =         -1.15273200d0
      e(  14) =          1.70664400d0
      s(  14) =         -0.28903400d0
      e(  15) =       2284.10550000d0
      s(  15) =         -0.00037400d0
      e(  16) =        348.21736000d0
      s(  16) =         -0.00140200d0
      e(  17) =         35.71041300d0
      s(  17) =          0.02261200d0
      e(  18) =         21.23851200d0
      s(  18) =         -0.16339300d0
      e(  19) =         13.02726300d0
      s(  19) =          0.28608600d0
      e(  20) =          3.26039800d0
      s(  20) =         -0.37229700d0
      e(  21) =          1.70664400d0
      s(  21) =         -0.10454900d0
      e(  22) =          0.72369400d0
      s(  22) =          1.00000000d0
      e(  23) =          0.33252200d0
      s(  23) =          1.00000000d0
      e(  24) =          0.07713300d0
      s(  24) =          1.00000000d0
      e(  25) =          0.03111200d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00500000d0
      s(  26) =          1.00000000d0
      e(  27) =        499.61426000d0
      p(  27) =         -0.00415100d0
      e(  28) =        116.60663000d0
      p(  28) =         -0.02118700d0
      e(  29) =         29.97079300d0
      p(  29) =         -0.05551300d0
      e(  30) =          6.85342900d0
      p(  30) =          0.97256400d0
      e(  31) =          5.73506400d0
      p(  31) =         -1.00332700d0
      e(  32) =          2.55086600d0
      p(  32) =         -0.70895100d0
      e(  33) =        499.61426000d0
      p(  33) =         -0.00315300d0
      e(  34) =        116.60663000d0
      p(  34) =         -0.01740300d0
      e(  35) =         29.97079300d0
      p(  35) =         -0.03791200d0
      e(  36) =          6.85342900d0
      p(  36) =          0.69559500d0
      e(  37) =          5.73506400d0
      p(  37) =         -0.84354900d0
      e(  38) =          2.55086600d0
      p(  38) =         -0.41610100d0
      e(  39) =          1.20413800d0
      p(  39) =          1.00000000d0
      e(  40) =          0.72808500d0
      p(  40) =          1.00000000d0
      e(  41) =          0.33330300d0
      p(  41) =          1.00000000d0
      e(  42) =          0.13596500d0
      p(  42) =          1.00000000d0
      e(  43) =          0.00500000d0
      p(  43) =          1.00000000d0
      e(  44) =         41.12014900d0
      d(  44) =         -0.01236900d0
      e(  45) =          7.02619000d0
      d(  45) =          0.23974500d0
      e(  46) =          5.34519700d0
      d(  46) =         -0.50259800d0
      e(  47) =          2.53283100d0
      d(  47) =         -0.52679800d0
      e(  48) =          1.29091200d0
      d(  48) =         -0.24085800d0
      e(  49) =          0.67863000d0
      d(  49) =         -0.04605700d0
      e(  50) =         41.12014900d0
      d(  50) =         -0.00400900d0
      e(  51) =          7.02619000d0
      d(  51) =          0.07345000d0
      e(  52) =          5.34519700d0
      d(  52) =         -0.17532200d0
      e(  53) =          2.53283100d0
      d(  53) =         -0.17140300d0
      e(  54) =          1.29091200d0
      d(  54) =         -0.01249900d0
      e(  55) =          0.67863000d0
      d(  55) =          0.20081300d0
      e(  56) =          0.32679700d0
      d(  56) =          1.00000000d0
      e(  57) =          0.14138100d0
      d(  57) =          1.00000000d0
      e(  58) =          0.05449900d0
      d(  58) =          1.00000000d0
      e(  59) =          0.01000000d0
      d(  59) =          1.00000000d0
      e(  60) =         45.04949700d0
      f(  60) =          0.00585900d0
      e(  61) =         15.25642500d0
      f(  61) =          0.03447300d0
      e(  62) =          5.63929900d0
      f(  62) =          0.19047800d0
      e(  63) =          2.67852200d0
      f(  63) =          0.38934200d0
      e(  64) =          1.23951300d0
      f(  64) =          0.38343300d0
      e(  65) =          0.54604900d0
      f(  65) =          1.00000000d0
      e(  66) =          0.21903200d0
      f(  66) =          1.00000000d0
      e(  67) =          0.05000000d0
      f(  67) =          1.00000000d0
c
      return
c
c bk   
c
  300 continue
c
      e(   1) =       1574.04750000d0
      s(   1) =          0.00129100d0
      e(   2) =        202.90410000d0
      s(   2) =          0.00474100d0
      e(   3) =         36.35768100d0
      s(   3) =         -0.21088800d0
      e(   4) =         22.57420400d0
      s(   4) =          1.05996000d0
      e(   5) =         13.56889400d0
      s(   5) =         -1.60211500d0
      e(   6) =          3.43708300d0
      s(   6) =          1.12972800d0
      e(   7) =          1.81446100d0
      s(   7) =          0.36069400d0
      e(   8) =       1574.04750000d0
      s(   8) =         -0.00094000d0
      e(   9) =        202.90410000d0
      s(   9) =         -0.00275800d0
      e(  10) =         36.35768100d0
      s(  10) =          0.10563300d0
      e(  11) =         22.57420400d0
      s(  11) =         -0.58435600d0
      e(  12) =         13.56889400d0
      s(  12) =          0.97167800d0
      e(  13) =          3.43708300d0
      s(  13) =         -1.15545600d0
      e(  14) =          1.81446100d0
      s(  14) =         -0.28842400d0
      e(  15) =       1574.04750000d0
      s(  15) =         -0.00028700d0
      e(  16) =        202.90410000d0
      s(  16) =         -0.00082100d0
      e(  17) =         36.35768100d0
      s(  17) =          0.03048500d0
      e(  18) =         22.57420400d0
      s(  18) =         -0.17122800d0
      e(  19) =         13.56889400d0
      s(  19) =          0.28902200d0
      e(  20) =          3.43708300d0
      s(  20) =         -0.37176700d0
      e(  21) =          1.81446100d0
      s(  21) =         -0.10493800d0
      e(  22) =          0.75496000d0
      s(  22) =          1.00000000d0
      e(  23) =          0.34659300d0
      s(  23) =          1.00000000d0
      e(  24) =          0.08069600d0
      s(  24) =          1.00000000d0
      e(  25) =          0.03233900d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00500000d0
      s(  26) =          1.00000000d0
      e(  27) =        664.89858000d0
      p(  27) =         -0.00320500d0
      e(  28) =        172.19816000d0
      p(  28) =         -0.01646100d0
      e(  29) =         57.94880000d0
      p(  29) =         -0.03279600d0
      e(  30) =         18.15671900d0
      p(  30) =         -0.10283500d0
      e(  31) =          9.40211500d0
      p(  31) =          0.35592000d0
      e(  32) =          4.55694300d0
      p(  32) =         -0.45212500d0
      e(  33) =        664.89858000d0
      p(  33) =         -0.00269700d0
      e(  34) =        172.19816000d0
      p(  34) =         -0.01322900d0
      e(  35) =         57.94880000d0
      p(  35) =         -0.02973400d0
      e(  36) =         18.15671900d0
      p(  36) =         -0.05561500d0
      e(  37) =          9.40211500d0
      p(  37) =          0.19476100d0
      e(  38) =          4.55694300d0
      p(  38) =         -0.42177500d0
      e(  39) =          2.29457200d0
      p(  39) =          1.00000000d0
      e(  40) =          0.91274300d0
      p(  40) =          1.00000000d0
      e(  41) =          0.43075100d0
      p(  41) =          1.00000000d0
      e(  42) =          0.17534300d0
      p(  42) =          1.00000000d0
      e(  43) =          0.00500000d0
      p(  43) =          1.00000000d0
      e(  44) =        149.07149000d0
      d(  44) =         -0.00229700d0
      e(  45) =         38.88815500d0
      d(  45) =         -0.01733800d0
      e(  46) =          3.80395400d0
      d(  46) =         -0.57973000d0
      e(  47) =          1.70547700d0
      d(  47) =         -0.45349400d0
      e(  48) =          1.02413900d0
      d(  48) =          0.08119500d0
      e(  49) =          0.81783900d0
      d(  49) =         -0.13890300d0
      e(  50) =        149.07149000d0
      d(  50) =         -0.00068600d0
      e(  51) =         38.88815500d0
      d(  51) =         -0.00592200d0
      e(  52) =          3.80395400d0
      d(  52) =         -0.21297600d0
      e(  53) =          1.70547700d0
      d(  53) =         -0.03313200d0
      e(  54) =          1.02413900d0
      d(  54) =         -0.22682400d0
      e(  55) =          0.81783900d0
      d(  55) =          0.40716600d0
      e(  56) =          0.29384900d0
      d(  56) =          1.00000000d0
      e(  57) =          0.11640100d0
      d(  57) =          1.00000000d0
      e(  58) =          0.04405600d0
      d(  58) =          1.00000000d0
      e(  59) =          0.00500000d0
      d(  59) =          1.00000000d0
      e(  60) =         47.84467200d0
      f(  60) =          0.00663900d0
      e(  61) =         16.26262500d0
      f(  61) =          0.03982500d0
      e(  62) =          6.11378400d0
      f(  62) =          0.18810100d0
      e(  63) =          2.88353200d0
      f(  63) =          0.39018100d0
      e(  64) =          1.32474900d0
      f(  64) =          0.38619400d0
      e(  65) =          0.57521300d0
      f(  65) =          1.00000000d0
      e(  66) =          0.22265300d0
      f(  66) =          1.00000000d0
      e(  67) =          0.00500000d0
      f(  67) =          1.00000000d0
c
      return
c
c cf   
c
  320 continue
c
      e(   1) =        658.19332000d0
      s(   1) =          0.00033900d0
      e(   2) =        126.14145000d0
      s(   2) =          0.00434600d0
      e(   3) =         35.26237200d0
      s(   3) =         -0.58369200d0
      e(   4) =         27.57844300d0
      s(   4) =          1.24968000d0
      e(   5) =         13.88761100d0
      s(   5) =         -1.42778900d0
      e(   6) =          3.61888200d0
      s(   6) =          1.13115200d0
      e(   7) =          1.86123000d0
      s(   7) =          0.36540900d0
      e(   8) =        658.19332000d0
      s(   8) =         -0.00028900d0
      e(   9) =        126.14145000d0
      s(   9) =         -0.00151500d0
      e(  10) =         35.26237200d0
      s(  10) =          0.29819500d0
      e(  11) =         27.57844300d0
      s(  11) =         -0.66972200d0
      e(  12) =         13.88761100d0
      s(  12) =          0.86501400d0
      e(  13) =          3.61888200d0
      s(  13) =         -1.12771800d0
      e(  14) =          1.86123000d0
      s(  14) =         -0.32911800d0
      e(  15) =        658.19332000d0
      s(  15) =         -0.00008600d0
      e(  16) =        126.14145000d0
      s(  16) =         -0.00040700d0
      e(  17) =         35.26237200d0
      s(  17) =          0.08597600d0
      e(  18) =         27.57844300d0
      s(  18) =         -0.19445700d0
      e(  19) =         13.88761100d0
      s(  19) =          0.25574500d0
      e(  20) =          3.61888200d0
      s(  20) =         -0.35732900d0
      e(  21) =          1.86123000d0
      s(  21) =         -0.12360400d0
      e(  22) =          0.80643900d0
      s(  22) =          1.00000000d0
      e(  23) =          0.36560900d0
      s(  23) =          1.00000000d0
      e(  24) =          0.08279700d0
      s(  24) =          1.00000000d0
      e(  25) =          0.03317000d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00500000d0
      s(  26) =          1.00000000d0
      e(  27) =       1240.28310000d0
      p(  27) =         -0.00277200d0
      e(  28) =        294.32078000d0
      p(  28) =         -0.01985400d0
      e(  29) =         93.15679000d0
      p(  29) =         -0.06074200d0
      e(  30) =         30.46576900d0
      p(  30) =         -0.09795100d0
      e(  31) =          5.79994700d0
      p(  31) =          0.77302900d0
      e(  32) =          4.57033000d0
      p(  32) =         -1.02438600d0
      e(  33) =       1240.28310000d0
      p(  33) =         -0.00332500d0
      e(  34) =        294.32078000d0
      p(  34) =         -0.02301600d0
      e(  35) =         93.15679000d0
      p(  35) =         -0.07482200d0
      e(  36) =         30.46576900d0
      p(  36) =         -0.10447000d0
      e(  37) =          5.79994700d0
      p(  37) =          0.37167900d0
      e(  38) =          4.57033000d0
      p(  38) =         -0.74329800d0
      e(  39) =          1.98763200d0
      p(  39) =          1.00000000d0
      e(  40) =          0.85063100d0
      p(  40) =          1.00000000d0
      e(  41) =          0.38521700d0
      p(  41) =          1.00000000d0
      e(  42) =          0.15635700d0
      p(  42) =          1.00000000d0
      e(  43) =          0.00500000d0
      p(  43) =          1.00000000d0
      e(  44) =        124.81616000d0
      d(  44) =         -0.00378500d0
      e(  45) =         34.57643800d0
      d(  45) =         -0.02176200d0
      e(  46) =          6.32201400d0
      d(  46) =          0.13737500d0
      e(  47) =          4.93756900d0
      d(  47) =         -0.54710100d0
      e(  48) =          2.31329000d0
      d(  48) =         -0.50415000d0
      e(  49) =          1.07689200d0
      d(  49) =         -0.16803500d0
      e(  50) =        124.81616000d0
      d(  50) =          0.00122100d0
      e(  51) =         34.57643800d0
      d(  51) =          0.00668300d0
      e(  52) =          6.32201400d0
      d(  52) =         -0.01910700d0
      e(  53) =          4.93756900d0
      d(  53) =          0.15446400d0
      e(  54) =          2.31329000d0
      d(  54) =          0.14484100d0
      e(  55) =          1.07689200d0
      d(  55) =         -0.10122400d0
      e(  56) =          0.42050300d0
      d(  56) =          1.00000000d0
      e(  57) =          0.15604000d0
      d(  57) =          1.00000000d0
      e(  58) =          0.05347100d0
      d(  58) =          1.00000000d0
      e(  59) =          0.00500000d0
      d(  59) =          1.00000000d0
      e(  60) =         57.86442300d0
      f(  60) =          0.00663500d0
      e(  61) =         19.90814000d0
      f(  61) =          0.04345000d0
      e(  62) =          7.85988500d0
      f(  62) =          0.15796200d0
      e(  63) =          3.60027200d0
      f(  63) =          0.36792100d0
      e(  64) =          1.64656100d0
      f(  64) =          0.40163100d0
      e(  65) =          0.70742100d0
      f(  65) =          1.00000000d0
      e(  66) =          0.26847400d0
      f(  66) =          1.00000000d0
      e(  67) =          0.00500000d0
      f(  67) =          1.00000000d0
c
      return
c
c es   
c
  340 continue
c
      e(   1) =        569.48984000d0
      s(   1) =         -0.00025100d0
      e(   2) =        126.14145000d0
      s(   2) =          0.00638600d0
      e(   3) =         36.69293400d0
      s(   3) =         -1.17057700d0
      e(   4) =         31.34439700d0
      s(   4) =          1.84152600d0
      e(   5) =         14.69496400d0
      s(   5) =         -1.44262300d0
      e(   6) =          3.75198000d0
      s(   6) =          1.15929200d0
      e(   7) =          1.86039700d0
      s(   7) =          0.34362100d0
      e(   8) =        569.48984000d0
      s(   8) =          0.00006800d0
      e(   9) =        126.14145000d0
      s(   9) =         -0.00272000d0
      e(  10) =         36.69293400d0
      s(  10) =          0.61838200d0
      e(  11) =         31.34439700d0
      s(  11) =         -0.99348600d0
      e(  12) =         14.69496400d0
      s(  12) =          0.86891300d0
      e(  13) =          3.75198000d0
      s(  13) =         -1.12559700d0
      e(  14) =          1.86039700d0
      s(  14) =         -0.35927900d0
      e(  15) =        569.48984000d0
      s(  15) =          0.00001600d0
      e(  16) =        126.14145000d0
      s(  16) =         -0.00075400d0
      e(  17) =         36.69293400d0
      s(  17) =          0.17927500d0
      e(  18) =         31.34439700d0
      s(  18) =         -0.28901200d0
      e(  19) =         14.69496400d0
      s(  19) =          0.25704400d0
      e(  20) =          3.75198000d0
      s(  20) =         -0.35366400d0
      e(  21) =          1.86039700d0
      s(  21) =         -0.14620400d0
      e(  22) =          0.88271700d0
      s(  22) =          1.00000000d0
      e(  23) =          0.40229000d0
      s(  23) =          1.00000000d0
      e(  24) =          0.10108500d0
      s(  24) =          1.00000000d0
      e(  25) =          0.04777500d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00500000d0
      s(  26) =          1.00000000d0
      e(  27) =       1225.76240000d0
      p(  27) =         -0.00362600d0
      e(  28) =        291.86891000d0
      p(  28) =         -0.02533700d0
      e(  29) =         92.95568500d0
      p(  29) =         -0.07479900d0
      e(  30) =         30.69405100d0
      p(  30) =         -0.11062400d0
      e(  31) =          5.17860300d0
      p(  31) =          1.27682500d0
      e(  32) =          4.43421900d0
      p(  32) =         -1.56500200d0
      e(  33) =       1225.76240000d0
      p(  33) =         -0.00498700d0
      e(  34) =        291.86891000d0
      p(  34) =         -0.03395700d0
      e(  35) =         92.95568500d0
      p(  35) =         -0.10530000d0
      e(  36) =         30.69405100d0
      p(  36) =         -0.13769400d0
      e(  37) =          5.17860300d0
      p(  37) =          0.46903600d0
      e(  38) =          4.43421900d0
      p(  38) =         -0.86504800d0
      e(  39) =          1.84853900d0
      p(  39) =          1.00000000d0
      e(  40) =          0.87174300d0
      p(  40) =          1.00000000d0
      e(  41) =          0.39385000d0
      p(  41) =          1.00000000d0
      e(  42) =          0.16718100d0
      p(  42) =          1.00000000d0
      e(  43) =          0.00500000d0
      p(  43) =          1.00000000d0
      e(  44) =        126.51971000d0
      d(  44) =         -0.00450100d0
      e(  45) =         35.07218200d0
      d(  45) =         -0.02528100d0
      e(  46) =          4.81523800d0
      d(  46) =         -0.30883500d0
      e(  47) =          3.81438100d0
      d(  47) =         -0.22601600d0
      e(  48) =          2.09716500d0
      d(  48) =         -0.43182600d0
      e(  49) =          0.98196800d0
      d(  49) =         -0.12390100d0
      e(  50) =        126.51971000d0
      d(  50) =          0.00137700d0
      e(  51) =         35.07218200d0
      d(  51) =          0.00795200d0
      e(  52) =          4.81523800d0
      d(  52) =          0.15582200d0
      e(  53) =          3.81438100d0
      d(  53) =         -0.00488500d0
      e(  54) =          2.09716500d0
      d(  54) =          0.13907700d0
      e(  55) =          0.98196800d0
      d(  55) =         -0.16655400d0
      e(  56) =          0.35421900d0
      d(  56) =          1.00000000d0
      e(  57) =          0.12855500d0
      d(  57) =          1.00000000d0
      e(  58) =          0.04609100d0
      d(  58) =          1.00000000d0
      e(  59) =          0.00500000d0
      d(  59) =          1.00000000d0
      e(  60) =         55.63663900d0
      f(  60) =          0.00977100d0
      e(  61) =         19.18226600d0
      f(  61) =          0.06089200d0
      e(  62) =          7.68381900d0
      f(  62) =          0.19474200d0
      e(  63) =          3.48702400d0
      f(  63) =          0.38403000d0
      e(  64) =          1.59293800d0
      f(  64) =          0.38082400d0
      e(  65) =          0.69716700d0
      f(  65) =          1.00000000d0
      e(  66) =          0.27902900d0
      f(  66) =          1.00000000d0
      e(  67) =          0.00500000d0
      f(  67) =          1.00000000d0
c
      return
c
c fm   
c
  360 continue
c
      e(   1) =       1342.56800000d0
      s(   1) =          0.00002600d0
      e(   2) =         71.72801200d0
      s(   2) =          0.08226700d0
      e(   3) =         51.78138300d0
      s(   3) =         -0.32879100d0
      e(   4) =         28.35425400d0
      s(   4) =          1.05769700d0
      e(   5) =         15.78982400d0
      s(   5) =         -1.56088100d0
      e(   6) =          3.75746000d0
      s(   6) =          1.22270700d0
      e(   7) =          1.65571600d0
      s(   7) =          0.29056200d0
      e(   8) =       1342.56800000d0
      s(   8) =         -0.00001900d0
      e(   9) =         71.72801200d0
      s(   9) =         -0.03880900d0
      e(  10) =         51.78138300d0
      s(  10) =          0.16494800d0
      e(  11) =         28.35425400d0
      s(  11) =         -0.57915900d0
      e(  12) =         15.78982400d0
      s(  12) =          0.93163900d0
      e(  13) =          3.75746000d0
      s(  13) =         -1.19392900d0
      e(  14) =          1.65571600d0
      s(  14) =         -0.30691600d0
      e(  15) =       1342.56800000d0
      s(  15) =         -0.00000500d0
      e(  16) =         71.72801200d0
      s(  16) =         -0.01118400d0
      e(  17) =         51.78138300d0
      s(  17) =          0.04781600d0
      e(  18) =         28.35425400d0
      s(  18) =         -0.16952500d0
      e(  19) =         15.78982400d0
      s(  19) =          0.27585400d0
      e(  20) =          3.75746000d0
      s(  20) =         -0.37835800d0
      e(  21) =          1.65571600d0
      s(  21) =         -0.13143200d0
      e(  22) =          0.90421900d0
      s(  22) =          1.00000000d0
      e(  23) =          0.39897700d0
      s(  23) =          1.00000000d0
      e(  24) =          0.08929400d0
      s(  24) =          1.00000000d0
      e(  25) =          0.03546300d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00510000d0
      s(  26) =          1.00000000d0
      e(  27) =        610.42788000d0
      p(  27) =         -0.01334400d0
      e(  28) =        143.34446000d0
      p(  28) =         -0.07072800d0
      e(  29) =         41.16463900d0
      p(  29) =         -0.13050200d0
      e(  30) =          6.91462000d0
      p(  30) =         -0.73110600d0
      e(  31) =          5.67454700d0
      p(  31) =          1.93974900d0
      e(  32) =          4.23063100d0
      p(  32) =         -1.61321200d0
      e(  33) =        610.42788000d0
      p(  33) =          0.01990900d0
      e(  34) =        143.34446000d0
      p(  34) =          0.10817900d0
      e(  35) =         41.16463900d0
      p(  35) =          0.19059600d0
      e(  36) =          6.91462000d0
      p(  36) =          0.58345500d0
      e(  37) =          5.67454700d0
      p(  37) =         -1.16645600d0
      e(  38) =          4.23063100d0
      p(  38) =          1.08019600d0
      e(  39) =          1.51738900d0
      p(  39) =          1.00000000d0
      e(  40) =          0.68561900d0
      p(  40) =          1.00000000d0
      e(  41) =          0.32165400d0
      p(  41) =          1.00000000d0
      e(  42) =          0.15647000d0
      p(  42) =          1.00000000d0
      e(  43) =          0.05390700d0
      p(  43) =          1.00000000d0
      e(  44) =        102.84696000d0
      d(  44) =         -0.00761100d0
      e(  45) =         31.15417300d0
      d(  45) =         -0.03157000d0
      e(  46) =          4.80080300d0
      d(  46) =         -0.55060700d0
      e(  47) =          3.70370300d0
      d(  47) =          0.26475000d0
      e(  48) =          2.72753900d0
      d(  48) =         -0.58902700d0
      e(  49) =          1.28717300d0
      d(  49) =         -0.20031600d0
      e(  50) =        102.84696000d0
      d(  50) =          0.00235400d0
      e(  51) =         31.15417300d0
      d(  51) =          0.01020500d0
      e(  52) =          4.80080300d0
      d(  52) =          0.24257900d0
      e(  53) =          3.70370300d0
      d(  53) =         -0.19665200d0
      e(  54) =          2.72753900d0
      d(  54) =          0.22943600d0
      e(  55) =          1.28717300d0
      d(  55) =         -0.07134000d0
      e(  56) =          0.55865100d0
      d(  56) =          1.00000000d0
      e(  57) =          0.25813200d0
      d(  57) =          1.00000000d0
      e(  58) =          0.11082100d0
      d(  58) =          1.00000000d0
      e(  59) =          0.04273000d0
      d(  59) =          1.00000000d0
      e(  60) =         57.18854400d0
      f(  60) =          0.01139600d0
      e(  61) =         18.27654900d0
      f(  61) =          0.07994000d0
      e(  62) =          6.83449100d0
      f(  62) =          0.26556000d0
      e(  63) =          2.94398100d0
      f(  63) =          0.43710600d0
      e(  64) =          1.25982000d0
      f(  64) =          0.35245800d0
      e(  65) =          0.52331700d0
      f(  65) =          1.00000000d0
      e(  66) =          0.20531000d0
      f(  66) =          1.00000000d0
      e(  67) =          0.04950200d0
      f(  67) =          1.00000000d0
c
      return
c
c md   
c
  380 continue
c
      e(   1) =       2405.62650000d0
      s(   1) =          0.00010900d0
      e(   2) =         64.77849600d0
      s(   2) =          0.21398700d0
      e(   3) =         48.45735100d0
      s(   3) =         -1.08592200d0
      e(   4) =         37.78001700d0
      s(   4) =          1.35116400d0
      e(   5) =         14.43013200d0
      s(   5) =         -1.30574400d0
      e(   6) =          4.48231000d0
      s(   6) =          1.00234000d0
      e(   7) =          2.41767000d0
      s(   7) =          0.54107400d0
      e(   8) =       2405.62650000d0
      s(   8) =         -0.00005300d0
      e(   9) =         64.77849600d0
      s(   9) =         -0.10410700d0
      e(  10) =         48.45735100d0
      s(  10) =          0.55546000d0
      e(  11) =         37.78001700d0
      s(  11) =         -0.71818900d0
      e(  12) =         14.43013200d0
      s(  12) =          0.80709500d0
      e(  13) =          4.48231000d0
      s(  13) =         -0.95984400d0
      e(  14) =          2.41767000d0
      s(  14) =         -0.54015800d0
      e(  15) =       2405.62650000d0
      s(  15) =          0.00001400d0
      e(  16) =         64.77849600d0
      s(  16) =          0.02872100d0
      e(  17) =         48.45735100d0
      s(  17) =         -0.15559900d0
      e(  18) =         37.78001700d0
      s(  18) =          0.20312500d0
      e(  19) =         14.43013200d0
      s(  19) =         -0.23436600d0
      e(  20) =          4.48231000d0
      s(  20) =          0.29045200d0
      e(  21) =          2.41767000d0
      s(  21) =          0.19905800d0
      e(  22) =          0.93276900d0
      s(  22) =          1.00000000d0
      e(  23) =          0.41918100d0
      s(  23) =          1.00000000d0
      e(  24) =          0.10702800d0
      s(  24) =          1.00000000d0
      e(  25) =          0.04994900d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00500000d0
      s(  26) =          1.00000000d0
      e(  27) =       1313.50690000d0
      p(  27) =         -0.00387600d0
      e(  28) =        312.40288000d0
      p(  28) =         -0.02701900d0
      e(  29) =         99.27327300d0
      p(  29) =         -0.07812100d0
      e(  30) =         32.70886000d0
      p(  30) =         -0.11175200d0
      e(  31) =          5.71537100d0
      p(  31) =          0.90023900d0
      e(  32) =          4.60206700d0
      p(  32) =         -1.17403500d0
      e(  33) =       1313.50690000d0
      p(  33) =          0.00558000d0
      e(  34) =        312.40288000d0
      p(  34) =          0.03787400d0
      e(  35) =         99.27327300d0
      p(  35) =          0.11517800d0
      e(  36) =         32.70886000d0
      p(  36) =          0.14434600d0
      e(  37) =          5.71537100d0
      p(  37) =         -0.29888400d0
      e(  38) =          4.60206700d0
      p(  38) =          0.69309500d0
      e(  39) =          1.97186700d0
      p(  39) =          1.00000000d0
      e(  40) =          0.90695800d0
      p(  40) =          1.00000000d0
      e(  41) =          0.40839500d0
      p(  41) =          1.00000000d0
      e(  42) =          0.17182600d0
      p(  42) =          1.00000000d0
      e(  43) =          0.00500000d0
      p(  43) =          1.00000000d0
      e(  44) =        307.45729000d0
      d(  44) =         -0.00107100d0
      e(  45) =         91.31519200d0
      d(  45) =         -0.00778700d0
      e(  46) =         32.02114400d0
      d(  46) =         -0.02999500d0
      e(  47) =          5.02376100d0
      d(  47) =         -0.43817900d0
      e(  48) =          2.57364900d0
      d(  48) =         -0.45708700d0
      e(  49) =          1.29014000d0
      d(  49) =         -0.17797300d0
      e(  50) =        307.45729000d0
      d(  50) =          0.00035500d0
      e(  51) =         91.31519200d0
      d(  51) =          0.00229300d0
      e(  52) =         32.02114400d0
      d(  52) =          0.00986800d0
      e(  53) =          5.02376100d0
      d(  53) =          0.16300100d0
      e(  54) =          2.57364900d0
      d(  54) =          0.06751200d0
      e(  55) =          1.29014000d0
      d(  55) =          0.03479400d0
      e(  56) =          0.60015200d0
      d(  56) =          1.00000000d0
      e(  57) =          0.17094500d0
      d(  57) =          1.00000000d0
      e(  58) =          0.09023900d0
      d(  58) =          1.00000000d0
      e(  59) =          0.00500000d0
      d(  59) =          1.00000000d0
      e(  60) =         86.95802200d0
      f(  60) =          0.00425600d0
      e(  61) =         30.15143400d0
      f(  61) =          0.03183700d0
      e(  62) =         12.34469900d0
      f(  62) =          0.11576700d0
      e(  63) =          5.39006700d0
      f(  63) =          0.31593300d0
      e(  64) =          2.46468200d0
      f(  64) =          0.42221800d0
      e(  65) =          1.05167500d0
      f(  65) =          1.00000000d0
      e(  66) =          0.39674000d0
      f(  66) =          1.00000000d0
      e(  67) =          0.00500000d0
      f(  67) =          1.00000000d0
c
      return
c
c no   
c
  400 continue
c
      e(   1) =       2330.03110000d0
      s(   1) =          0.00014800d0
      e(   2) =         81.85889500d0
      s(   2) =          0.05325300d0
      e(   3) =         51.04970400d0
      s(   3) =         -0.41784600d0
      e(   4) =         34.11506300d0
      s(   4) =          0.90911700d0
      e(   5) =         15.19884700d0
      s(   5) =         -1.37055300d0
      e(   6) =          4.76258300d0
      s(   6) =          0.92025200d0
      e(   7) =          2.65717800d0
      s(   7) =          0.61313500d0
      e(   8) =       2330.03110000d0
      s(   8) =         -0.00007300d0
      e(   9) =         81.85889500d0
      s(   9) =         -0.02465000d0
      e(  10) =         51.04970400d0
      s(  10) =          0.21185400d0
      e(  11) =         34.11506300d0
      s(  11) =         -0.49170600d0
      e(  12) =         15.19884700d0
      s(  12) =          0.84517400d0
      e(  13) =          4.76258300d0
      s(  13) =         -0.87913400d0
      e(  14) =          2.65717800d0
      s(  14) =         -0.62677600d0
      e(  15) =       2330.03110000d0
      s(  15) =         -0.00001900d0
      e(  16) =         81.85889500d0
      s(  16) =         -0.00677700d0
      e(  17) =         51.04970400d0
      s(  17) =          0.05973700d0
      e(  18) =         34.11506300d0
      s(  18) =         -0.14056900d0
      e(  19) =         15.19884700d0
      s(  19) =          0.24678200d0
      e(  20) =          4.76258300d0
      s(  20) =         -0.26737900d0
      e(  21) =          2.65717800d0
      s(  21) =         -0.22177800d0
      e(  22) =          1.00892300d0
      s(  22) =          1.00000000d0
      e(  23) =          0.45886700d0
      s(  23) =          1.00000000d0
      e(  24) =          0.10958700d0
      s(  24) =          1.00000000d0
      e(  25) =          0.05097600d0
      s(  25) =          1.00000000d0
      e(  26) =          0.00500000d0
      s(  26) =          1.00000000d0
      e(  27) =       1370.50200000d0
      p(  27) =         -0.00373000d0
      e(  28) =        325.76015000d0
      p(  28) =         -0.02602300d0
      e(  29) =        103.38245000d0
      p(  29) =         -0.07479600d0
      e(  30) =         33.90458000d0
      p(  30) =         -0.10787800d0
      e(  31) =          6.23127200d0
      p(  31) =          0.89300800d0
      e(  32) =          5.06429900d0
      p(  32) =         -1.10593600d0
      e(  33) =       1370.50200000d0
      p(  33) =          0.00518900d0
      e(  34) =        325.76015000d0
      p(  34) =          0.03515900d0
      e(  35) =        103.38245000d0
      p(  35) =          0.10675400d0
      e(  36) =         33.90458000d0
      p(  36) =          0.13307200d0
      e(  37) =          6.23127200d0
      p(  37) =         -0.37374400d0
      e(  38) =          5.06429900d0
      p(  38) =          0.73060300d0
      e(  39) =          2.21781800d0
      p(  39) =          1.00000000d0
      e(  40) =          1.00346300d0
      p(  40) =          1.00000000d0
      e(  41) =          0.45571900d0
      p(  41) =          1.00000000d0
      e(  42) =          0.18867700d0
      p(  42) =          1.00000000d0
      e(  43) =          0.00500000d0
      p(  43) =          1.00000000d0
      e(  44) =        274.46136000d0
      d(  44) =         -0.00164900d0
      e(  45) =         82.03865100d0
      d(  45) =         -0.01103500d0
      e(  46) =         29.56842500d0
      d(  46) =         -0.03645000d0
      e(  47) =          5.34922800d0
      d(  47) =         -0.38601600d0
      e(  48) =          2.84954500d0
      d(  48) =         -0.45792300d0
      e(  49) =          1.46565300d0
      d(  49) =         -0.21484400d0
      e(  50) =        274.46136000d0
      d(  50) =          0.00052200d0
      e(  51) =         82.03865100d0
      d(  51) =          0.00308000d0
      e(  52) =         29.56842500d0
      d(  52) =          0.01159500d0
      e(  53) =          5.34922800d0
      d(  53) =          0.13310400d0
      e(  54) =          2.84954500d0
      d(  54) =          0.09580400d0
      e(  55) =          1.46565300d0
      d(  55) =          0.00272800d0
      e(  56) =          0.70458400d0
      d(  56) =          1.00000000d0
      e(  57) =          0.24267300d0
      d(  57) =          1.00000000d0
      e(  58) =          0.05457100d0
      d(  58) =          1.00000000d0
      e(  59) =          0.00500000d0
      d(  59) =          1.00000000d0
      e(  60) =         97.04318000d0
      f(  60) =          0.00412600d0
      e(  61) =         33.37314300d0
      f(  61) =          0.03282200d0
      e(  62) =         13.57543000d0
      f(  62) =          0.12175400d0
      e(  63) =          5.79283600d0
      f(  63) =          0.31277100d0
      e(  64) =          2.61517500d0
      f(  64) =          0.42549100d0
      e(  65) =          1.10660700d0
      f(  65) =          1.00000000d0
      e(  66) =          0.41449400d0
      f(  66) =          1.00000000d0
      e(  67) =          0.00500000d0
      f(  67) =          1.00000000d0
c
      return
c
c lw   
c
  420 continue
c
      e(   1) =       1982.77390000d0
      s(   1) =         -0.00015100d0
      e(   2) =         74.72688800d0
      s(   2) =          0.53359300d0
      e(   3) =         56.14818700d0
      s(   3) =         -2.66083600d0
      e(   4) =         45.34633100d0
      s(   4) =          2.90028000d0
      e(   5) =         18.17731800d0
      s(   5) =         -1.57605600d0
      e(   6) =          4.50236400d0
      s(   6) =          1.12022200d0
      e(   7) =          2.53357000d0
      s(   7) =          0.36140000d0
      e(   8) =       1982.77390000d0
      s(   8) =          0.00009200d0
      e(   9) =         74.72688800d0
      s(   9) =         -0.28886200d0
      e(  10) =         56.14818700d0
      s(  10) =          1.44248800d0
      e(  11) =         45.34633100d0
      s(  11) =         -1.58094800d0
      e(  12) =         18.17731800d0
      s(  12) =          0.92496000d0
      e(  13) =          4.50236400d0
      s(  13) =         -0.99756400d0
      e(  14) =          2.53357000d0
      s(  14) =         -0.49489200d0
      e(  15) =       1982.77390000d0
      s(  15) =          0.00002700d0
      e(  16) =         74.72688800d0
      s(  16) =         -0.08266400d0
      e(  17) =         56.14818700d0
      s(  17) =          0.41277800d0
      e(  18) =         45.34633100d0
      s(  18) =         -0.45267500d0
      e(  19) =         18.17731800d0
      s(  19) =          0.26752000d0
      e(  20) =          4.50236400d0
      s(  20) =         -0.30275700d0
      e(  21) =          2.53357000d0
      s(  21) =         -0.18107300d0
      e(  22) =          1.10848200d0
      s(  22) =          1.00000000d0
      e(  23) =          0.48500300d0
      s(  23) =          1.00000000d0
      e(  24) =          0.10618800d0
      s(  24) =          1.00000000d0
      e(  25) =          0.04462000d0
      s(  25) =          1.00000000d0
      e(  26) =          0.01300000d0
      s(  26) =          1.00000000d0
      e(  27) =       1460.12210000d0
      p(  27) =         -0.00392500d0
      e(  28) =        346.67201000d0
      p(  28) =         -0.02759100d0
      e(  29) =        109.62487000d0
      p(  29) =         -0.08114900d0
      e(  30) =         35.82813300d0
      p(  30) =         -0.11467200d0
      e(  31) =          5.80681300d0
      p(  31) =          0.99403600d0
      e(  32) =          4.70835400d0
      p(  32) =         -1.30380400d0
      e(  33) =       1460.12210000d0
      p(  33) =          0.00598000d0
      e(  34) =        346.67201000d0
      p(  34) =          0.04098700d0
      e(  35) =        109.62487000d0
      p(  35) =          0.12637400d0
      e(  36) =         35.82813300d0
      p(  36) =          0.15801900d0
      e(  37) =          5.80681300d0
      p(  37) =         -0.26473300d0
      e(  38) =          4.70835400d0
      p(  38) =          0.66995500d0
      e(  39) =          1.98298600d0
      p(  39) =          1.00000000d0
      e(  40) =          1.02411700d0
      p(  40) =          1.00000000d0
      e(  41) =          0.48039600d0
      p(  41) =          1.00000000d0
      e(  42) =          0.21117600d0
      p(  42) =          1.00000000d0
      e(  43) =          0.05000000d0
      p(  43) =          1.00000000d0
      e(  44) =        225.53578000d0
      d(  44) =         -0.00447400d0
      e(  45) =         67.40388900d0
      d(  45) =         -0.02745300d0
      e(  46) =         24.39881000d0
      d(  46) =         -0.07456300d0
      e(  47) =          7.08278800d0
      d(  47) =         -0.19422700d0
      e(  48) =          3.69358400d0
      d(  48) =         -0.50375000d0
      e(  49) =          1.81456200d0
      d(  49) =         -0.32347900d0
      e(  50) =        225.53578000d0
      d(  50) =          0.00138000d0
      e(  51) =         67.40388900d0
      d(  51) =          0.00862600d0
      e(  52) =         24.39881000d0
      d(  52) =          0.02289400d0
      e(  53) =          7.08278800d0
      d(  53) =          0.07700900d0
      e(  54) =          3.69358400d0
      d(  54) =          0.12330100d0
      e(  55) =          1.81456200d0
      d(  55) =          0.04077400d0
      e(  56) =          0.81768500d0
      d(  56) =          1.00000000d0
      e(  57) =          0.27225500d0
      d(  57) =          1.00000000d0
      e(  58) =          0.07744800d0
      d(  58) =          1.00000000d0
      e(  59) =          0.01000000d0
      d(  59) =          1.00000000d0
      e(  60) =         93.14353600d0
      f(  60) =          0.00463700d0
      e(  61) =         32.40988300d0
      f(  61) =          0.03394200d0
      e(  62) =         13.38122100d0
      f(  62) =          0.11905800d0
      e(  63) =          5.90657300d0
      f(  63) =          0.31099800d0
      e(  64) =          2.75181600d0
      f(  64) =          0.41162700d0
      e(  65) =          1.20347100d0
      f(  65) =          1.00000000d0
      e(  66) =          0.45903100d0
      f(  66) =          1.00000000d0
      e(  67) =          0.05000000d0
      f(  67) =          1.00000000d0
c
 500  continue
      return
      end
c
_IF(notused)
      subroutine dum_0(e,s,p,d,f,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c   
c     ----- li- ne -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      go to (100,100,
     +       140,160,180,200,220,240,260,280),n
c
c
c +++ basis h, he
c
100    call caserr2('No RLC ECP basis set for H or He')
c
       go to 500
c
c
c +++ basis li
c
140    continue
c
       go to 500
c
c +++ basis be
c
160    continue
c
       go to 500
c
180    continue
c
c +++ basis b
c
c
       go to 500
c
c +++ basis c
c
200    continue
c
       go to 500
c
c +++ basis n
c
220    continue
c
c
       go to 500
c
c +++ basis o
c
240    continue
c
c
       go to 500
c
c +++ basis f
c
260    continue
c
c
       go to 500
c
c +++ basis ne
c
280    continue
c
c
  500 continue
c
      return
      end
      subroutine dum_1(e,s,p,d,f,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- na - ar -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
c
      go to (300,320,340,360,380,400,420,440),n
c
c
c +++ basis na
c
  300 continue
c
      go to 500
c
c +++ basis mg
c
  320 continue
c
      go to 500
c
c +++ basis al
c
340    continue
c
c
       go to 500
c
c +++ basis si
c
360    continue
c
c
       go to 500
c
c +++ basis p
c
380    continue
c
c
       go to 500
c
c +++ basis s
c
400    continue
c
c
       go to 500
c
c +++ basis cl
c
420    continue
c
c
       go to 500
c
c +++ basis ar
c
440    continue
c
  500 continue
c
      return
      end
      subroutine dum_2(e,s,p,d,f,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- basis (K-Kr) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-18
      go to (100,120,140,160,180,200,220,240,260,280,300,320,
     +       340,360,380,400,420,440),nn
c
c k   
c
  100 continue
c
      go to 500
c
c ca   
c
  120 continue
c
      go to 500
c
c sc   
c
  140 continue
c
      go to 500
c
c ti   
c
  160 continue
c
      go to 500
c
c v   
c
  180 continue
c
      go to 500
c
c cr   
c
  200 continue
c
      go to 500
c
c mn   
c
  220 continue
c
      go to 500
c
c fe   
c
  240 continue
c
      go to 500
c
c co   
c
  260 continue
c
      go to 500
c
c ni   
c
  280 continue
c
      go to 500
c
c cu   
c
  300 continue
c
      go to 500
c
c zn   
c
  320 continue
c
      go to 500
c
c ga  
c
  340 continue
c
c
      go to 500
c
c ge  
c 
  360 continue
c
c
      go to 500
c
c as  
c 
  380 continue
c
c
      go to 500
c
c se  
c
  400 continue
c
c
      go to 500
c
c br  
c 
  420 continue
c
c
      go to 500
c
c kr  
c
  440 continue
c
c
500   return
      end
      subroutine dum_3(e,s,p,d,f,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- basis (Rb-Xe) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
c
      nn = n-36
      go to (100,120,140,160,180,200,220,240,260,280,300,320,
     +       340,360,380,400,420,440),nn
c
c rb   
c
  100 continue
c
      go to 500
c
c sr   
c
  120 continue
c
      go to 500
c
c y   
c
  140 continue
c
      go to 500
c
c zr   
c
  160 continue
c
      go to 500
c
c nb   
c
  180 continue
c
      go to 500
c
c mo   
c
  200 continue
c
      go to 500
c
c tc   
c
  220 continue
c
      go to 500
c
c ru   
c
  240 continue
c
      go to 500
c
c rh   
c
  260 continue
c
      go to 500
c
c pd   
c
  280 continue
c
      go to 500
c
c ag   
c
  300 continue
c
      go to 500
c
c cd   
c
  320 continue
c
      go to 500
c
c in  
c
  340 continue
c
c
      go to 500
c
c sn  
c 
  360 continue
c
c
      go to 500
c
c sb  
c 
  380 continue
c
c
      go to 500
c
c te  
c
  400 continue
c
c
      go to 500
c
c i  
c 
  420 continue
c
c
      go to 500
c
c xe  
c
  440 continue
c
c
500   return
      end
      subroutine dum_4(e,s,p,d,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- ECP basis (Cs-Xe) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
c
      nn = n-54
      go to (100,120,140,
     +       160,180,200,220,240,260,280,300,320,340,360,380,400,420,
     +       440,460,480,500,520,540,560,580,600,620,640,660,680,700,
     +       720),nn
c
c cs   
c
  100 continue
c
      go to 800
c
c ba   
c
  120 continue
c
      go to 800
c
c la   
c
  140 continue
c
      go to 800
c
c ce   
c
  160 continue
c
      go to 800
c
c pr   
c
  180 continue
c
      go to 800
c
c nd   
c
  200 continue
c
      go to 800
c
c pm   
c
  220 continue
c
      go to 800
c
c sm   
c
  240 continue
c
      go to 800
c
c eu   
c
  260 continue
c
      go to 800
c
c gd   
c
  280 continue
c
      go to 800
c
c tb   
c
  300 continue
c
      go to 800
c
c dy   
c
  320 continue
c
      go to 800
c
c ho   
c
  340 continue
c
      go to 800
c
c er   
c
  360 continue
c
      go to 800
c
c tm   
c
  380 continue
c
      go to 800
c
c yb   
c
  400 continue
c
      go to 800
c
c lu   
c
  420 continue
c
      go to 800
c
c hf   
c
  440 continue
c
      go to 800
c
c ta   
c
  460 continue
c
      go to 800
c
c w   
c
  480 continue
c
      go to 800
c
c re   
c
  500 continue
c
      go to 800
c
c os   
c
  520 continue
c
      go to 800
c
c ir   
c
  540 continue
c
      go to 800
c
c pt   
c
  560 continue
c
      go to 800
c
c au   
c
  580 continue
c
      go to 800
c
c hg   
c
  600 continue
c
      go to 800
c
c tl  
c
  620 continue
c
c
      go to 800
c
c pb  
c 
  640 continue
c
c
      go to 800
c
c bi  
c 
  660 continue
c
c
      go to 800
c
c po  
c
  680 continue
c
c
      go to 800
c
c at
c 
  700 continue
c
c
      go to 800
c
c rn  
c
  720 continue
c
c
800   return
      end
      subroutine dum_5(e,s,p,d,f,g,n)
c
c   RLC ECP Stuttgart Relativistic, Large Core ECP Basis Set
c     ----- ECP basis (Fr-Lw) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*),g(*)
c
      nn = n-86
      go to (100,120,140,
     +   160,180,200,220,240,260,280,300,320,340,360,380,400,420),
     +   nn
c
c fr   
c
  100 continue
c
      return
c
c ra   
c
  120 continue
c
c
      return
c
c ac   
c
  140 continue
c
c
      return
c
c th   
c
  160 continue
c
c
      return
c
c pa   
c
  180 continue
c

      return
c
c u   
c
  200 continue
c
c
      return
c
c np   
c
  220 continue
c
c
      return
c
c pu   
c
  240 continue
c
c
      return
c
c am   
c
  260 continue
c
      return
c
c cm   
c
  280 continue
c
c
      return
c
c bk   
c
  300 continue
c
c
      return
c
c cf   
c
  320 continue
c
c
      return
c
c es   
c
  340 continue
c
c
      return
c
c fm   
c
  360 continue
c
c
      return
c
c md   
c
  380 continue
c
c
      return
c
c no   
c
  400 continue
c
c
      return
c
c lw   
c
  420 continue
c
c
      return
      end
_ENDIF
      subroutine ver_basis3(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/basis3.m,v $
     +     "/
      data revision /"$Revision: 5774 $"/
      data date /"$Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
