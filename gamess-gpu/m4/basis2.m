c 
c  $Author: jmht $
c  $Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
c  $Locker:  $
c  $Revision: 5774 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/basis2.m,v $
c  $State: Exp $
c  
c     deck=basis2
      subroutine dgauss_a1_fit(csinp,cpinp,cdinp,
     + nucz,intyp,nangm,nbfs,minf,maxf,loc,ngauss,
     + ns,ierr1,ierr2,nat)
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
c
      dimension csinp(*),cpinp(*),cdinp(*),
     +  intyp(*),nangm(*),nbfs(*),minf(*),maxf(*),ns(*)
      common/blkin/eex(50),ccs(50),ccp(50),ccd(50)
INCLUDE(common/iofile)
      common/junk/ptr(18192),iptr(4,maxat),iptrs(2,mxshel),
     *ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     *cf(mxprim),cg(mxprim),
     +kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     +kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell
INCLUDE(common/restar)
c
      data pt5,pt75/
     + 0.5d+00,0.75d+00/
      data pi32,tm10/5.56832799683170d+00,1.0d-10/
c
c     DGAUSS_A1_DFT Coulomb Fitting basis sets
************************************************************
c      N. Godbout, D. R. Salahub, J. Andzelm, and E. Wimmer,    
c      Can. J. Chem. 70, 560 (1992).                            
c      H  - He: ( 4s)
c      Li - Be: ( 7s,2p,1d)
c      B  - Ne: ( 7s,3p,3d)                                                           
c      Na - Mg: ( 9s,4p,3d)                                                           
c      Al - Ar: ( 9s,4p,4d)                                                           
c      K  - Ca: (10s,5p,4d)                                                           
c      Sc - Kr: (10s,5p,5d)                                                           
c      Rb - Sr: (11s,6p,5d)                                                           
c      Y  - Xe: (10s,5p,5d)                                                           
************************************************************
c
      ng = -2**20
      igauss = ng
      ityp = ng
      ierr1=0
      ierr2=0
      odone = .false.
_IFN1(civu)      call vclr(eex,1,200)
_IFN(civu)      call szero(eex,200)
c
c     ----- hydrogen to helium -----
c
      if (nucz .le. 2) then
          call dgauss_a1_fit0(eex,ccs,ccp,nucz)
c
c     ----- lithium to neon -----
c
      else if (nucz .le. 10) then
          call dgauss_a1_fit1(eex,ccs,ccp,ccd,nucz)
c
c     ----- sodium to argon -----
c
      else if (nucz .le. 18) then
          call dgauss_a1_fit2(eex,ccs,ccp,ccd,nucz)
c
c     ----- potassium to zinc -----
c
      else if(nucz.le.30) then
          call dgauss_a1_fit3(eex,ccs,ccp,ccd,nucz)
c
c     ----- gallium to krypton -----
c
      else if(nucz.le.36) then
          call dgauss_a1_fit4(eex,ccs,ccp,ccd,nucz)
c
c     ----- rubidium to cadmium
c
      else if (nucz .le. 48) then
          call dgauss_a1_fit5(eex,ccs,ccp,ccd,nucz)
c
c     ----- indium to xenon
c
       else if (nucz .le. 54) then
          call dgauss_a1_fit6(eex,ccs,ccp,ccd,nucz)
c
c
c     ----- past xenon does not exist
c
      else
        call caserr2(
     +   'attempting to site dgauss_a1 function on invalid centre')
      endif
c
c
c     ----- loop over each shell -----
c
      ipass = 0
  210 ipass = ipass+1
        call dgauss_a1_fitsh(nucz,ipass,ityp,igauss,ng,odone)
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
      do 440 i = 1,igauss
         k = k1+i-1
         ex(k) = eex(ng+i)
         if(ityp.eq.16) then
          csinp(k) = ccs(ng+i)
         else if(ityp.eq.17) then
          cpinp(k) = ccp(ng+i)
         else if(ityp.eq.18) then
          cdinp(k) = ccd(ng+i)
         else if (ityp.eq.22) then
          csinp(k) = ccs(ng+i)
          cpinp(k) = ccp(ng+i)
         else
          call caserr2('invalid shell type')
         endif
         cs(k) = 0.0d+00
         cp(k) = 0.0d+00
         cd(k) = 0.0d+00
         cf(k) = 0.0d+00
         if(ityp.eq.16) then
          cs(k) = csinp(k)
         else if(ityp.eq.17) then
          cp(k) = cpinp(k)
         else if(ityp.eq.18) then
          cd(k) = cdinp(k)
         else if(ityp.eq.22) then
          cs(k) = csinp(k)
          cp(k) = cpinp(k)
         else
          call caserr2('invalid shell type')
         endif
  440 continue
c
c     ----- always unnormalize primitives -----
c
      do 460 k = k1,k2
         ee = ex(k)+ex(k)
         facs = pi32/(ee*sqrt(ee))
         facp = pt5*facs/ee
         facd = pt75*facs/(ee*ee)
         if(ityp.eq.16) then
          cs(k) = cs(k)/sqrt(facs)
         else if(ityp.eq.17) then
          cp(k) = cp(k)/sqrt(facp)
         else if(ityp.eq.18) then
          cd(k) = cd(k)/sqrt(facd)
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
      if (normf .eq. 1) go to 210
      facs = 0.0d+00
      facp = 0.0d+00
      facd = 0.0d+00
      do 510 ig = k1,k2
         do 500 jg = k1,ig
            ee = ex(ig)+ex(jg)
            fac = ee*sqrt(ee)
            dums = cs(ig)*cs(jg)/fac
            dump = pt5*cp(ig)*cp(jg)/(ee*fac)
            dumd = pt75*cd(ig)*cd(jg)/(ee*ee*fac)
            if (ig .eq. jg) go to 480
               dums = dums+dums
               dump = dump+dump
               dumd = dumd+dumd
  480       continue
            facs = facs+dums
            facp = facp+dump
            facd = facd+dumd
  500    continue
  510 continue
c
      fac=0.0d+00
      if(ityp.eq.16.and. facs.gt.tm10) then
        fac=1.0d+00/sqrt(facs*pi32)
      else if(ityp.eq.17.and. facp.gt.tm10) then
        fac=1.0d+00/sqrt(facp*pi32)
      else if(ityp.eq.18.and. facd.gt.tm10) then
        fac=1.0d+00/sqrt(facd*pi32)
      else if(ityp.eq.22.and. facs.gt.tm10.
     +                   and. facp.gt.tm10 ) then
        fac1=1.0d+00/sqrt(facs*pi32)
        fac2=1.0d+00/sqrt(facp*pi32)
      else
      endif
c
      do 550 ig = k1,k2
         if(ityp.eq.16) then
          cs(ig) = fac*cs(ig)
         else if(ityp.eq.17) then
          cp(ig) = fac*cp(ig)
         else if(ityp.eq.18) then
          cd(ig) = fac*cd(ig)
         else if(ityp.eq.22) then
          cs(ig) = fac1*cs(ig)
          cp(ig) = fac2*cp(ig)
         else
         endif
  550 continue
      go to 210
c
  220 continue
      return
      end
      subroutine dgauss_a1_fit0(e,s,p,n)
c
c     ----- dgauss_a1 fitting basis 
c     ----- hydrogen and helium (4s)/(4s) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*)
      go to (100,120),n
c
c     ----- h  -----
c
c h     (4s) / [4s]
c
  100 continue
      e (1) =  45.00000000d0
      e (2) =   7.50000000d0
      e (3) =   1.50000000d0
      e (4) =   0.30000000d0
c
      go to 200
c
c     ----- he  -----
c
c he    (4s) / [4s] 
c
  120 continue
      e (1) =  54.00000000d0
      e (2) =   9.00000000d0
      e (3) =   1.80000000d0
      e (4) =   0.36000000d0
c
  200 do i =1,4
       s(i) = 1.0d0
      enddo
c
      return
c
      end
      subroutine dgauss_a1_fit1(e,s,p,d,n)
c
c  ----- DGauss_A1 primitive Coulomb fitting basis
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-2
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- li -----
c
c li    (5s2sp1d) / [5s2sp1d]
c
  100 continue
      e (1) = 256.00000000d0
      e (2) =  51.20000000d0
      e (3) =  12.80000000d0
      e (4) =   3.20000000d0
      e (5) =   0.80000000d0
      e (6) =   0.05000000d0
      e (7) =   0.20000000d0
      e (8) =   0.20000000d0
c
      go to 1000
c
c     ----- be -----
c
c be    (5s2sp1d) / [5s2sp1d]
c
  120 continue
c
      e (1) = 512.00000000d0
      e (2) = 103.00000000d0
      e (3) =  25.60000000d0
      e (4) =   6.40000000d0
      e (5) =   1.60000000d0
      e (6) =   0.11000000d0
      e (7) =   0.40000000d0
      e( 8) =   0.40000000d0
c
1000  do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,7
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      d(8) = 1.0d0
c
      return
c
c     ----- b -----
c
c B     (4s3sp3d) / [4s3sp3d]
c
  140 continue
c
      e( 1) = 716.80000000d0
      e( 2) = 143.40000000d0
      e( 3) =  35.84000000d0
      e( 4) =   8.96000000d0
      e( 5) =   2.80000000d0
      e( 6) =   0.56000000d0
      e( 7) =   0.14000000d0
      e( 8) =   2.80000000d0
      e( 9) =   0.56000000d0
      e(10) =   0.14000000d0
c
      go to 2000
c
c     ----- c -----
c
c C     (4s3sp3d) / [4s3sp3d]
c
  160 continue
      e( 1) = 1114.00000000d0
      e( 2) =  223.00000000d0
      e( 3) =   55.72000000d0
      e( 4) =   13.90000000d0
      e( 5) =    4.40000000d0
      e( 6) =    0.87000000d0
      e( 7) =    0.22000000d0
      e( 8) =    4.40000000d0
      e( 9) =    0.87000000d0
      e(10) =    0.22000000d0
c
      go to 2000
c
c     ----- n -----
c
c N     (4s3sp3d) / [4s3sp3d]
c
  180 continue
c
      e( 1) = 1640.00000000d0
      e( 2) =  328.00000000d0
      e( 3) =   82.00000000d0
      e( 4) =   20.50000000d0
      e( 5) =    6.40000000d0
      e( 6) =    1.28000000d0
      e( 7) =    0.32000000d0
      e( 8) =    6.40000000d0
      e( 9) =    1.28000000d0
      e(10) =    0.32000000d0
c
      go to 2000
c
c     ----- o ------
c
c O     (4s3sp3d) / [4s3sp3d]
c
  200 continue
c
      e( 1) = 2000.00000000d0
      e( 2) =  400.00000000d0
      e( 3) =  100.00000000d0
      e( 4) =   25.00000000d0
      e( 5) =    7.80000000d0
      e( 6) =    1.56000000d0
      e( 7) =    0.39000000d0
      e( 8) =    7.80000000d0
      e( 9) =    1.56000000d0
      e(10) =    0.39000000d0
c
      go to 2000
c
c     ----- f -----
c
c F     (4s3sp3d) / [4s3sp3d]
c
  220 continue
c
      e( 1) = 2458.00000000d0
      e( 2) =  492.00000000d0
      e( 3) =  123.00000000d0
      e( 4) =   30.70000000d0
      e( 5) =    9.60000000d0
      e( 6) =    1.92000000d0
      e( 7) =    0.48000000d0
      e( 8) =    9.60000000d0
      e( 9) =    1.92000000d0
      e(10) =    0.48000000d0
c
      go to 2000
c
c     ----- ne -----
c
c Ne    (4s3sp3d) / [4s3sp3d]
c
  240 continue
      e( 1) = 3072.00000000d0
      e( 2) =  614.00000000d0
      e( 3) =  153.60000000d0
      e( 4) =   38.40000000d0
      e( 5) =   12.00000000d0
      e( 6) =    2.40000000d0
      e( 7) =    0.60000000d0
      e( 8) =   12.00000000d0
      e( 9) =    2.40000000d0
      e(10) =    0.60000000d0
c
2000   do i = 1,4
       s(i) = 1.0d0
      enddo
      do i = 5,7
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i =  8,10
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine dgauss_a1_fit2(e,s,p,d,n)
c
c     ----- dgauss_a1 fitting contractions  -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-10
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- na  -----
c
c na    (5s4sp3d) / [5s4sp3d]
c
  100 continue
      e( 1) = 3700.00000000d0
      e( 2) =  737.00000000d0
      e( 3) =  184.00000000d0
      e( 4) =   46.00000000d0
      e( 5) =   11.50000000d0
      e( 6) =    0.04700000d0
      e( 7) =    3.60000000d0
      e( 8) =    0.72000000d0
      e( 9) =    0.18000000d0
      e(10) =    3.60000000d0
      e(11) =    0.72000000d0
      e(12) =    0.18000000d0
c
      go to 1000
c
c     ----- mg -----
c
c mg    (5s4sp3d) / [5s4sp3d]
c 
  120 continue
c
      e( 1) = 6140.00000000d0
      e( 2) = 1220.00000000d0
      e( 3) =  310.00000000d0
      e( 4) =   77.00000000d0
      e( 5) =   19.00000000d0
      e( 6) =    0.08000000d0
      e( 7) =    6.00000000d0
      e( 8) =    1.20000000d0
      e( 9) =    0.30000000d0
      e(10) =    6.00000000d0
      e(11) =    1.20000000d0
      e(12) =    0.30000000d0
c
 1000 do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,9
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 10,12
       d(i) = 1.0d0
      enddo
c
      return
c
c     ----- al -----
c
c al    (5s4sp4d/ [5s4sp4d]
c 
  140 continue
c
      e( 1) = 6861.00000000d0
      e( 2) = 1372.00000000d0
      e( 3) =  343.00000000d0
      e( 4) =   85.80000000d0
      e( 5) =   21.40000000d0
      e( 6) =    6.72000000d0
      e( 7) =    1.34000000d0
      e( 8) =    0.34000000d0
      e( 9) =    0.08400000d0
      e(10) =    6.72000000d0
      e(11) =    1.34000000d0
      e(12) =    0.34000000d0
      e(13) =    0.08400000d0
c
      go to 2000
c
c     ----- si -----
c
c si    (5s4sp4d/ [5s4sp4d]
c
  160 continue
c
      e( 1) = 9830.00000000d0
      e( 2) = 1966.00000000d0
      e( 3) =  492.00000000d0
      e( 4) =  123.00000000d0
      e( 5) =   30.72000000d0
      e( 6) =    9.60000000d0
      e( 7) =    1.92000000d0
      e( 8) =    0.48000000d0
      e( 9) =    0.12000000d0
      e(10) =    9.60000000d0
      e(11) =    1.92000000d0
      e(12) =    0.48000000d0
      e(13) =    0.12000000d0
c
      go to 2000
c
c     ----- p -----
c
c p    (5s4sp4d/ [5s4sp4d]
c
  180 continue
c
      e( 1) = 13107.00000000d0
      e( 2) =  2621.00000000d0
      e( 3) =   655.00000000d0
      e( 4) =   164.00000000d0
      e( 5) =    41.00000000d0
      e( 6) =    13.00000000d0
      e( 7) =     2.60000000d0
      e( 8) =     0.64000000d0
      e( 9) =     0.16000000d0
      e(10) =    13.00000000d0
      e(11) =     2.60000000d0
      e(12) =     0.64000000d0
      e(13) =     0.16000000d0
c
      go to 2000
c
c     ----- s -----
c
c s    (5s4sp4d/ [5s4sp4d]
c
  200 continue
c
      e( 1) = 16384.00000000d0
      e( 2) =  3277.00000000d0
      e( 3) =   819.00000000d0
      e( 4) =   205.00000000d0
      e( 5) =    51.00000000d0
      e( 6) =    16.00000000d0
      e( 7) =     3.20000000d0
      e( 8) =     0.80000000d0
      e( 9) =     0.20000000d0
      e(10) =    16.00000000d0
      e(11) =     3.20000000d0
      e(12) =     0.80000000d0
      e(13) =     0.20000000d0
c
      go to 2000
c
c     ----- cl -----
c
c cl    (5s4sp4d/ [5s4sp4d]
c
  220 continue
c
      e( 1) = 20480.00000000d0
      e( 2) =  4096.00000000d0
      e( 3) =  1024.00000000d0
      e( 4) =   256.00000000d0
      e( 5) =    64.00000000d0
      e( 6) =    20.00000000d0
      e( 7) =     4.00000000d0
      e( 8) =     1.00000000d0
      e( 9) =     0.25000000d0
      e(10) =    20.00000000d0
      e(11) =     4.00000000d0
      e(12) =     1.00000000d0
      e(13) =     0.25000000d0
c
      go to 2000
c
c     ----- ar -----
c
c ar    (5s4sp4d/ [5s4sp4d]
c
  240 continue
c
      e( 1) = 24576.00000000d0
      e( 2) =  4915.00000000d0
      e( 3) =  1229.00000000d0
      e( 4) =   307.00000000d0
      e( 5) =    77.00000000d0
      e( 6) =    24.00000000d0
      e( 7) =     4.80000000d0
      e( 8) =     1.20000000d0
      e( 9) =     0.30000000d0
      e(10) =    24.00000000d0
      e(11) =     4.80000000d0
      e(12) =     1.20000000d0
      e(13) =     0.30000000d0
c
 2000 do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,9
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 10,13
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine dgauss_a1_fit3(e,s,p,d,n)
c
c ----- dgauss_a1 coulomb fitting basis 
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-18
      go to (100,120,140,160,180,200,220,240,260,280,300,320),nn
c
c k     (5s5sp4d) / [5s5sp4d]
c
  100 continue
c
      e( 1) = 10000.00000000d0
      e( 2) =  2000.00000000d0
      e( 3) =   490.00000000d0
      e( 4) =   122.00000000d0
      e( 5) =    30.70000000d0
      e( 6) =     0.03500000d0
      e( 7) =     9.60000000d0
      e( 8) =     1.92000000d0
      e( 9) =     0.48000000d0
      e(10) =     0.12000000d0
      e(11) =     9.60000000d0
      e(12) =     1.92000000d0
      e(13) =     0.48000000d0
      e(14) =     0.12000000d0
c
      go to 1000
c
c ca  (5s5sp4d) / [5s5sp4d]
c 
  120 continue
c
      e( 1) = 13900.00000000d0
      e( 2) =  2800.00000000d0
      e( 3) =   700.00000000d0
      e( 4) =   174.00000000d0
      e( 5) =    43.50000000d0
      e( 6) =     0.05400000d0
      e( 7) =    13.60000000d0
      e( 8) =     2.72000000d0
      e( 9) =     0.68000000d0
      e(10) =     0.17000000d0
      e(11) =    13.60000000d0
      e(12) =     2.72000000d0
      e(13) =     0.68000000d0
      e(14) =     0.17000000d0
c
1000  do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,10
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 11,14
       d(i) = 1.0d0
      enddo
c
      return
c
c sc    (5s5sp5d) / [5s5sp5d]
c 
  140 continue
c
      e( 1) = 21000.00000000d0
      e( 2) =  4200.00000000d0
      e( 3) =  1050.00000000d0
      e( 4) =   262.40000000d0
      e( 5) =    65.60000000d0
      e( 6) =    20.50000000d0
      e( 7) =     4.10000000d0
      e( 8) =     1.03000000d0
      e( 9) =     0.25600000d0
      e(10) =     0.06400000d0
      e(11) =    20.50000000d0
      e(12) =     4.10000000d0
      e(13) =     1.03000000d0
      e(14) =     0.25600000d0
      e(15) =     0.06400000d0
c
      go to 2000
c
c ti (5s5sp5d) / [5s5sp5d]
c 
  160 continue
c
      e(1 ) = 28000.00000000d0
      e(2 ) =  5600.00000000d0
      e(3 ) =  1400.00000000d0
      e(4 ) =   348.00000000d0
      e(5 ) =    87.00000000d0
      e(6 ) =    27.20000000d0
      e(7 ) =     5.44000000d0
      e(8 ) =     1.36000000d0
      e(9 ) =     0.34000000d0
      e(10) =     0.08400000d0
      e(11) =    27.20000000d0
      e(12) =     5.44000000d0
      e(13) =     1.36000000d0
      e(14) =     0.34000000d0
      e(15) =     0.08400000d0
c
      go to 2000
c
c v    (5s5sp5d) / [5s5sp5d]
c 
  180 continue
c
      e(1 ) = 33100.00000000d0
      e(2 ) =  6620.00000000d0
      e(3 ) =  1650.00000000d0
      e(4 ) =   414.00000000d0
      e(5 ) =   103.00000000d0
      e(6 ) =    32.00000000d0
      e(7 ) =     6.46000000d0
      e(8 ) =     1.61000000d0
      e(9 ) =     0.40400000d0
      e(10) =     0.10100000d0
      e(11) =    32.00000000d0
      e(12) =     6.46000000d0
      e(13) =     1.61000000d0
      e(14) =     0.40400000d0
      e(15) =     0.10100000d0
c
      go to 2000
c
c cr    (5s5sp5d) / [5s5sp5d]
c
  200 continue
c
      e( 1) = 37000.00000000d0
      e( 2) =  7530.00000000d0
      e( 3) =  1880.00000000d0
      e( 4) =   471.00000000d0
      e( 5) =   117.00000000d0
      e( 6) =    36.80000000d0
      e( 7) =     7.36000000d0
      e( 8) =     1.84000000d0
      e( 9) =     0.46000000d0
      e(10) =     0.11500000d0
      e(11) =    36.80000000d0
      e(12) =     7.36000000d0
      e(13) =     1.84000000d0
      e(14) =     0.46000000d0
      e(15) =     0.11500000d0
c
      go to 2000
c
c mn    (5s5sp5d) / [5s5sp5d]
c 
  220 continue
c
      e(1 ) = 41000.00000000d0
      e(2 ) =  8200.00000000d0
      e(3 ) =  2050.00000000d0
      e(4 ) =   510.00000000d0
      e(5 ) =   128.00000000d0
      e(6 ) =    40.00000000d0
      e(7 ) =     8.00000000d0
      e(8 ) =     2.00000000d0
      e(9 ) =     0.50000000d0
      e(10) =     0.12500000d0
      e(11) =    40.00000000d0
      e(12) =     8.00000000d0
      e(13) =     2.00000000d0
      e(14) =     0.50000000d0
      e(15) =     0.12500000d0
c
      go to 2000
c
c fe    (5s5sp5d) / [5s5sp5d]
c 
  240 continue
c
      e( 1) = 44000.00000000d0
      e( 2) =  8800.00000000d0
      e( 3) =  2200.00000000d0
      e( 4) =   550.00000000d0
      e( 5) =   137.00000000d0
      e( 6) =    43.20000000d0
      e( 7) =     8.60000000d0
      e( 8) =     2.20000000d0
      e( 9) =     0.54000000d0
      e(10) =     0.13500000d0
      e(11) =    43.20000000d0
      e(12) =     8.60000000d0
      e(13) =     2.20000000d0
      e(14) =     0.54000000d0
      e(15) =     0.13500000d0
c
      go to 2000
c
c co    (5s5sp5d) / [5s5sp5d]
c 
  260 continue
c
      e( 1) = 47000.00000000d0
      e( 2) =  9400.00000000d0
      e( 3) =  2350.00000000d0
      e( 4) =   590.00000000d0
      e( 5) =   147.00000000d0
      e( 6) =    46.00000000d0
      e( 7) =     9.20000000d0
      e( 8) =     2.30000000d0
      e( 9) =     0.58000000d0
      e(10) =     0.14400000d0
      e(11) =    46.00000000d0
      e(12) =     9.20000000d0
      e(13) =     2.30000000d0
      e(14) =     0.58000000d0
      e(15) =     0.14400000d0
c
      go to 2000
c
c ni    (5s5sp5d) / [5s5sp5d]
c 
  280 continue
c
      e( 1) = 50000.00000000d0
      e( 2) =  9930.00000000d0
      e( 3) =  2500.00000000d0
      e( 4) =   620.00000000d0
      e( 5) =   155.00000000d0
      e( 6) =    48.00000000d0
      e( 7) =     9.70000000d0
      e( 8) =     2.40000000d0
      e( 9) =     0.60000000d0
      e(10) =     0.15200000d0
      e(11) =    48.00000000d0
      e(12) =     9.70000000d0
      e(13) =     2.40000000d0
      e(14) =     0.60000000d0
      e(15) =     0.15200000d0
c
      go to 2000
c
c cu    (5s5sp5d) / [5s5sp5d]
c
  300 continue
c
      e( 1) = 53000.00000000d0
      e( 2) = 10500.00000000d0
      e( 3) =  2640.00000000d0
      e( 4) =   660.00000000d0
      e( 5) =   165.00000000d0
      e( 6) =    51.00000000d0
      e( 7) =    10.30000000d0
      e( 8) =     2.57000000d0
      e( 9) =     0.64000000d0
      e(10) =     0.16000000d0
      e(11) =    51.00000000d0
      e(12) =    10.30000000d0
      e(13) =     2.57000000d0
      e(14) =     0.64000000d0
      e(15) =     0.16000000d0
c
      go to 2000
c
c zn    (5s5sp5d) / [5s5sp5d]
c 
  320 continue
c
      e( 1) = 75500.00000000d0
      e( 2) = 15100.00000000d0
      e( 3) =  3776.00000000d0
      e( 4) =   944.00000000d0
      e( 5) =   236.00000000d0
      e( 6) =    74.00000000d0
      e( 7) =    14.80000000d0
      e( 8) =     3.70000000d0
      e( 9) =     0.92000000d0
      e(10) =     0.23000000d0
      e(11) =    74.00000000d0
      e(12) =    14.80000000d0
      e(13) =     3.70000000d0
      e(14) =     0.92000000d0
      e(15) =     0.23000000d0
c
2000  do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,10
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 11,15
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine dgauss_a1_fit4(e,s,p,d,n)
c
c ----- dgauss_a1 coulomb fitting basis 
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-30
      go to (100,120,140,160,180,200),nn
c
c ga    (5s5sp5d) / [5s5sp5d] 
c
  100 continue
c
      e(1 ) = 26880.00000000d0
      e(2 ) =  5376.00000000d0
      e(3 ) =  1344.00000000d0
      e(4 ) =   336.00000000d0
      e(5 ) =    84.00000000d0
      e(6 ) =    26.20000000d0
      e(7 ) =     5.25000000d0
      e(8 ) =     1.31000000d0
      e(9 ) =     0.33000000d0
      e(10) =     0.08200000d0
      e(11) =    26.20000000d0
      e(12) =     5.25000000d0
      e(13) =     1.31000000d0
      e(14) =     0.33000000d0
      e(15) =     0.08200000d0
c
      go to 1000
c
c ge    (5s5sp5d) / [5s5sp5d] 
c 
  120 continue
c
      e(1 ) = 36032.00000000d0
      e(2 ) =  7206.00000000d0
      e(3 ) =  1802.00000000d0
      e(4 ) =   450.00000000d0
      e(5 ) =   113.00000000d0
      e(6 ) =    35.20000000d0
      e(7 ) =     7.04000000d0
      e(8 ) =     1.76000000d0
      e(9 ) =     0.44000000d0
      e(10) =     0.11000000d0
      e(11) =    35.20000000d0
      e(12) =     7.04000000d0
      e(13) =     1.76000000d0
      e(14) =     0.44000000d0
      e(15) =     0.11000000d0
c
      go to 1000
c
c as    (5s5sp5d) / [5s5sp5d] 
c 
  140 continue
c
      e(1 ) = 45760.00000000d0
      e(2 ) =  9152.00000000d0
      e(3 ) =  2288.00000000d0
      e(4 ) =   572.00000000d0
      e(5 ) =   143.00000000d0
      e(6 ) =    44.80000000d0
      e(7 ) =     8.96000000d0
      e(8 ) =     2.24000000d0
      e(9 ) =     0.56000000d0
      e(10) =     0.14000000d0
      e(11) =    44.80000000d0
      e(12) =     8.96000000d0
      e(13) =     2.24000000d0
      e(14) =     0.56000000d0
      e(15) =     0.14000000d0
c
      go to 1000
c
c se    (5s5sp5d) / [5s5sp5d] 
c
  160 continue
c
      e(1 ) = 52160.00000000d0
      e(2 ) = 10432.00000000d0
      e(3 ) =  2608.00000000d0
      e(4 ) =   652.00000000d0
      e(5 ) =   163.00000000d0
      e(6 ) =    51.00000000d0
      e(7 ) =    10.20000000d0
      e(8 ) =     2.56000000d0
      e(9 ) =     0.64000000d0
      e(10) =     0.16000000d0
      e(11) =    51.00000000d0
      e(12) =    10.20000000d0
      e(13) =     2.56000000d0
      e(14) =     0.64000000d0
      e(15) =     0.16000000d0
c
      go to 1000
c
c br    (5s5sp5d) / [5s5sp5d] 
c 
  180 continue
c
      e(1 ) = 62480.00000000d0
      e(2 ) = 12496.00000000d0
      e(3 ) =  3123.00000000d0
      e(4 ) =   781.00000000d0
      e(5 ) =   195.00000000d0
      e(6 ) =    60.80000000d0
      e(7 ) =    12.20000000d0
      e(8 ) =     3.04000000d0
      e(9 ) =     0.76000000d0
      e(10) =     0.19000000d0
      e(11) =    60.80000000d0
      e(12) =    12.20000000d0
      e(13) =     3.04000000d0
      e(14) =     0.76000000d0
      e(15) =     0.19000000d0
c
      go to 1000
c
c kr    (5s5sp5d) / [5s5sp5d] 
c
  200 continue
c
      e(1 ) = 72320.00000000d0
      e(2 ) = 14464.00000000d0
      e(3 ) =  3616.00000000d0
      e(4 ) =   904.00000000d0
      e(5 ) =   226.00000000d0
      e(6 ) =    70.50000000d0
      e(7 ) =    14.10000000d0
      e(8 ) =     3.52000000d0
      e(9 ) =     0.88000000d0
      e(10) =     0.22000000d0
      e(11) =    70.50000000d0
      e(12) =    14.10000000d0
      e(13) =     3.52000000d0
      e(14) =     0.88000000d0
      e(15) =     0.22000000d0
c
1000  continue
      do i = 1, 5
       s(i) = 1.0d0
      enddo
      do i = 6,10
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 11,15
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine dgauss_a1_fit5(e,s,p,d,n)
c
c ----- dgauss_a1 coulomb fitting basis [rb-cd]
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-36
      go to (100,120,140,160,180,200,220,240,260,280,300,320),nn
c
c rb    (5s6sp5d) / [5s6sp5d]
c
  100 continue
c
      e(1 ) = 40000.00000000d0
      e(2 ) =  8200.00000000d0
      e(3 ) =  2050.00000000d0
      e(4 ) =   512.00000000d0
      e(5 ) =   128.00000000d0
      e(6 ) =     0.03200000d0
      e(7 ) =    40.00000000d0
      e(8 ) =     8.00000000d0
      e(9 ) =     2.00000000d0
      e(10) =     0.51020000d0
      e(11) =     0.12800000d0
      e(12) =    40.00000000d0
      e(13) =     8.00000000d0
      e(14) =     2.00000000d0
      e(15) =     0.51020000d0
      e(16) =     0.12800000d0
c
      go to 1000
c
c sr  (5s6sp5d) / [5s6sp5d]
c 
  120 continue
c
      e(1 ) = 60000.00000000d0
      e(2 ) = 12300.00000000d0
      e(3 ) =  3100.00000000d0
      e(4 ) =   770.00000000d0
      e(5 ) =   192.00000000d0
      e(6 ) =     0.04700000d0
      e(7 ) =    60.00000000d0
      e(8 ) =    12.00000000d0
      e(9 ) =     3.00000000d0
      e(10) =     0.75220000d0
      e(11) =     0.18800000d0
      e(12) =    60.00000000d0
      e(13) =    12.00000000d0
      e(14) =     3.00000000d0
      e(15) =     0.75220000d0
      e(16) =     0.18800000d0
c
1000  do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,11
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 12,16
       d(i) = 1.0d0
      enddo
c
      return
c
c yttrium    (5s5sp5d) / [5s5sp5d]
c 
  140 continue
c
      e(1 ) =121875.00000000d0
      e(2 ) = 20312.00000000d0
      e(3 ) =  4062.00000000d0
      e(4 ) =   812.00000000d0
      e(5 ) =   162.00000000d0
      e(6 ) =    39.00000000d0
      e(7 ) =     6.50000000d0
      e(8 ) =     1.30000000d0
      e(9 ) =     0.26000000d0
      e(10) =     0.05200000d0
      e(11) =    39.00000000d0
      e(12) =     6.50000000d0
      e(13) =     1.30000000d0
      e(14) =     0.26000000d0
      e(15) =     0.05200000d0
c
      go to 2000
c
c zirconium (5s5sp5d) / [5s5sp5d]
c 
  160 continue
c
      e(1 ) =138375.00000000d0
      e(2 ) = 23062.00000000d0
      e(3 ) =  4612.00000000d0
      e(4 ) =   922.00000000d0
      e(5 ) =   184.00000000d0
      e(6 ) =    44.20000000d0
      e(7 ) =     7.38000000d0
      e(8 ) =     1.48000000d0
      e(9 ) =     0.29500000d0
      e(10) =     0.05900000d0
      e(11) =    44.20000000d0
      e(12) =     7.38000000d0
      e(13) =     1.48000000d0
      e(14) =     0.29500000d0
      e(15) =     0.05900000d0
c
      go to 2000
c
c niobium    (5s5sp5d) / [5s5sp5d]
c 
  180 continue
c
      e(1 ) = 150938.00000000d0
      e(2 ) =  25156.00000000d0
      e(3 ) =   5031.00000000d0
      e(4 ) =   1006.00000000d0
      e(5 ) =    201.00000000d0
      e(6 ) =     48.30000000d0
      e(7 ) =      8.05000000d0
      e(8 ) =      1.61000000d0
      e(9 ) =      0.32200000d0
      e(10) =      0.06400000d0
      e(11) =     48.30000000d0
      e(12) =      8.05000000d0
      e(13) =      1.61000000d0
      e(14) =      0.32200000d0
      e(15) =      0.06400000d0
c
      go to 2000
c
c molybdenum (5s5sp5d) / [5s5sp5d]
c
  200 continue
c
      e(1 ) =164062.00000000d0
      e(2 ) = 27344.00000000d0
      e(3 ) =  5469.00000000d0
      e(4 ) =  1094.00000000d0
      e(5 ) =   219.00000000d0
      e(6 ) =    52.50000000d0
      e(7 ) =     8.75000000d0
      e(8 ) =     1.75000000d0
      e(9 ) =     0.35000000d0
      e(10) =     0.07000000d0
      e(11) =    52.50000000d0
      e(12) =     8.75000000d0
      e(13) =     1.75000000d0
      e(14) =     0.35000000d0
      e(15) =     0.07000000d0
c
      go to 2000
c
c technecium (5s5sp5d) / [5s5sp5d]
c 
  220 continue
c
      e(1 ) = 174375.00000000d0
      e(2 ) =  29062.00000000d0
      e(3 ) =   5812.00000000d0
      e(4 ) =   1162.00000000d0
      e(5 ) =    232.00000000d0
      e(6 ) =     55.80000000d0
      e(7 ) =      9.30000000d0
      e(8 ) =      1.86000000d0
      e(9 ) =      0.37200000d0
      e(10) =      0.07400000d0
      e(11) =     55.80000000d0
      e(12) =      9.30000000d0
      e(13) =      1.86000000d0
      e(14) =      0.37200000d0
      e(15) =      0.07400000d0
c
      go to 2000
c
c ruthenium (5s5sp5d) / [5s5sp5d]
c 
  240 continue
c
      e(1 ) =180375.00000000d0
      e(2 ) = 30062.00000000d0
      e(3 ) =  6012.00000000d0
      e(4 ) =  1202.00000000d0
      e(5 ) =   240.00000000d0
      e(6 ) =    57.80000000d0
      e(7 ) =     9.62000000d0
      e(8 ) =     1.92000000d0
      e(9 ) =     0.38500000d0
      e(10) =     0.07700000d0
      e(11) =    57.80000000d0
      e(12) =     9.62000000d0
      e(13) =     1.92000000d0
      e(14) =     0.38500000d0
      e(15) =     0.07700000d0
c
      go to 2000
c
c rhodium  (5s5sp5d) / [5s5sp5d]
c 
  260 continue
c
      e(1 ) =185250.00000000d0
      e(2 ) = 30875.00000000d0
      e(3 ) =  6175.00000000d0
      e(4 ) =  1235.00000000d0
      e(5 ) =   247.00000000d0
      e(6 ) =    59.20000000d0
      e(7 ) =     9.88000000d0
      e(8 ) =     1.98000000d0
      e(9 ) =     0.39500000d0
      e(10) =     0.07900000d0
      e(11) =    59.20000000d0
      e(12) =     9.88000000d0
      e(13) =     1.98000000d0
      e(14) =     0.39500000d0
      e(15) =     0.07900000d0
c
      go to 2000
c
c palladium  (5s5sp5d) / [5s5sp5d]
c 
  280 continue
c
      e(1 ) = 187500.00000000d0
      e(2 ) =  31250.00000000d0
      e(3 ) =   6250.00000000d0
      e(4 ) =   1250.00000000d0
      e(5 ) =    250.00000000d0
      e(6 ) =     60.00000000d0
      e(7 ) =     10.00000000d0
      e(8 ) =      2.00000000d0
      e(9 ) =      0.40000000d0
      e(10) =      0.08000000d0
      e(11) =     60.00000000d0
      e(12) =     10.00000000d0
      e(13) =      2.00000000d0
      e(14) =      0.40000000d0
      e(15) =      0.08000000d0
c
      go to 2000
c
c silver (5s5sp5d) / [5s5sp5d]
c
  300 continue
c
      e(1 ) = 189375.00000000d0
      e(2 ) =  31562.00000000d0
      e(3 ) =   6312.00000000d0
      e(4 ) =   1262.00000000d0
      e(5 ) =    252.00000000d0
      e(6 ) =     60.80000000d0
      e(7 ) =     10.10000000d0
      e(8 ) =      2.02000000d0
      e(9 ) =      0.40500000d0
      e(10) =      0.08100000d0
      e(11) =     60.80000000d0
      e(12) =     10.10000000d0
      e(13) =      2.02000000d0
      e(14) =      0.40500000d0
      e(15) =      0.08100000d0
c
      go to 2000
c
c cadmium (5s5sp5d) / [5s5sp5d]
c 
  320 continue
c
      e(1 ) = 228750.00000000d0
      e(2 ) =  38125.00000000d0
      e(3 ) =   7625.00000000d0
      e(4 ) =   1525.00000000d0
      e(5 ) =    305.00000000d0
      e(6 ) =     73.50000000d0
      e(7 ) =     12.20000000d0
      e(8 ) =      2.45000000d0
      e(9 ) =      0.49000000d0
      e(10) =      0.09800000d0
      e(11) =     73.50000000d0
      e(12) =     12.20000000d0
      e(13) =      2.45000000d0
      e(14) =      0.49000000d0
      e(15) =      0.09800000d0
c
2000  do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,10
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 11,15
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine dgauss_a1_fit6(e,s,p,d,n)
c
c ----- dgauss_a1 coulomb fitting basis [In-Cd]
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-48
      go to (100,120,140,160,180,200),nn
c
c indium (5s5sp5d) / [5s5sp5d] 
c
  100 continue
c
      e(1 ) = 164062.00000000d0
      e(2 ) =  27344.00000000d0
      e(3 ) =   5469.00000000d0
      e(4 ) =   1094.00000000d0
      e(5 ) =    219.00000000d0
      e(6 ) =     52.50000000d0
      e(7 ) =      8.75000000d0
      e(8 ) =      1.75000000d0
      e(9 ) =      0.35000000d0
      e(10) =      0.07000000d0
      e(11) =     52.50000000d0
      e(12) =      8.75000000d0
      e(13) =      1.75000000d0
      e(14) =      0.35000000d0
      e(15) =      0.07000000d0
c
      go to 1000
c
c tin  (5s5sp5d) / [5s5sp5d] 
c 
  120 continue
c
      e(1 ) = 204375.00000000d0
      e(2 ) =  34062.00000000d0
      e(3 ) =   6812.00000000d0
      e(4 ) =   1362.00000000d0
      e(5 ) =    272.00000000d0
      e(6 ) =     65.20000000d0
      e(7 ) =     10.90000000d0
      e(8 ) =      2.18000000d0
      e(9 ) =      0.43500000d0
      e(10) =      0.08700000d0
      e(11) =     65.20000000d0
      e(12) =     10.90000000d0
      e(13) =      2.18000000d0
      e(14) =      0.43500000d0
      e(15) =      0.08700000d0
c
      go to 1000
c
c antimony  (5s5sp5d) / [5s5sp5d] 
c 
  140 continue
c
       e(1 ) = 253125.00000000d0
       e(2 ) =  42188.00000000d0
       e(3 ) =   8438.00000000d0
       e(4 ) =   1688.00000000d0
       e(5 ) =    338.00000000d0
       e(6 ) =     81.00000000d0
       e(7 ) =     13.50000000d0
       e(8 ) =      2.70000000d0
       e(9 ) =      0.54000000d0
       e(10) =      0.10800000d0
       e(11) =     81.00000000d0
       e(12) =     13.50000000d0
       e(13) =      2.70000000d0
       e(14) =      0.54000000d0
       e(15) =      0.10800000d0
c
      go to 1000
c
c tellurium  (5s5sp5d) / [5s5sp5d] 
c
  160 continue
c
       e(1 ) = 290625.00000000d0
       e(2 ) =  48438.00000000d0
       e(3 ) =   9688.00000000d0
       e(4 ) =   1938.00000000d0
       e(5 ) =    388.00000000d0
       e(6 ) =     93.00000000d0
       e(7 ) =     15.50000000d0
       e(8 ) =      3.10000000d0
       e(9 ) =      0.62000000d0
       e(10) =      0.12400000d0
       e(11) =     93.00000000d0
       e(12) =     15.50000000d0
       e(13) =      3.10000000d0
       e(14) =      0.62000000d0
       e(15) =      0.12400000d0
c
      go to 1000
c
c iodine  (5s5sp5d) / [5s5sp5d] 
c 
  180 continue
c
      e(1 ) = 335625.00000000d0
      e(2 ) =  55938.00000000d0
      e(3 ) =  11188.00000000d0
      e(4 ) =   2238.00000000d0
      e(5 ) =    448.00000000d0
      e(6 ) =    107.00000000d0
      e(7 ) =     17.90000000d0
      e(8 ) =      3.58000000d0
      e(9 ) =      0.71500000d0
      e(10) =      0.14300000d0
      e(11) =    107.00000000d0
      e(12) =     17.90000000d0
      e(13) =      3.58000000d0
      e(14) =      0.71500000d0
      e(15) =      0.14300000d0
c
      go to 1000
c
c xenon  (5s5sp5d) / [5s5sp5d] 
c
  200 continue
c
      e(1 ) = 384375.00000000d0
      e(2 ) =  64062.00000000d0
      e(3 ) =  12812.00000000d0
      e(4 ) =   2562.00000000d0
      e(5 ) =    512.00000000d0
      e(6 ) =    123.00000000d0
      e(7 ) =     20.50000000d0
      e(8 ) =      4.10000000d0
      e(9 ) =      0.82000000d0
      e(10) =      0.16400000d0
      e(11) =    123.00000000d0
      e(12) =     20.50000000d0
      e(13) =      4.10000000d0
      e(14) =      0.82000000d0
      e(15) =      0.16400000d0
c
1000  continue
c
      do i = 1, 5
       s(i) = 1.0d0
      enddo
      do i = 6,10
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 11,15
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine dgauss_a2_fit(csinp,cpinp,cdinp,
     + nucz,intyp,nangm,nbfs,minf,maxf,loc,ngauss,
     + ns,ierr1,ierr2,nat)
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
c
      dimension csinp(*),cpinp(*),cdinp(*),
     +  intyp(*),nangm(*),nbfs(*),minf(*),maxf(*),ns(*)
      common/blkin/eex(50),ccs(50),ccp(50),ccd(50)
INCLUDE(common/iofile)
      common/junk/ptr(18192),iptr(4,maxat),iptrs(2,mxshel),
     *ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     *cf(mxprim),cg(mxprim),
     +kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     +kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell
INCLUDE(common/restar)
c
      data pt5,pt75/
     + 0.5d+00,0.75d+00/
      data pi32,tm10/5.56832799683170d+00,1.0d-10/
c
c     DGAUSS_A2_DFT Coulomb Fitting basis sets
c     N. Godbout, D. R. Salahub, J. Andzelm, and E. Wimmer,   
c     Can. J. Chem. 70, 560 (1992).                            
c     Elements             
c     H  - He: ( 4s,1p,1d)  
c     Li - Be: ( 7s,2p,1d)  
c     B  - Ne: ( 8s,4p,4d)                                                           
c     Na - Mg: ( 9s,4p,3d)                                                           
c     Al - Ar: ( 9s,4p,4d)                                                           
c     Sc - Zn: (10s,5p,5d)                                                           
**                                                                             
c     DGauss basis sets provided courtesy of Cray Research, Inc.                     
c
      ng = -2**20
      igauss = ng
      ityp = ng
      ierr1=0
      ierr2=0
      odone = .false.
_IFN1(civu)      call vclr(eex,1,200)
_IFN(civu)      call szero(eex,200)
c
c     ----- hydrogen to helium -----
c
      if (nucz .le. 2) then
          call dgauss_a2_fit0(eex,ccs,ccp,ccd,nucz)
c
c     ----- lithium to neon -----
c
      else if (nucz .le. 10) then
          call dgauss_a2_fit1(eex,ccs,ccp,ccd,nucz,iwr)
c
c     ----- sodium to argon -----
c
      else if (nucz .le. 18) then
          call dgauss_a2_fit2(eex,ccs,ccp,ccd,nucz,iwr)
c
c     ----- potassium to zinc -----
c
      else if(nucz.le.30) then
          call dgauss_a2_fit3(eex,ccs,ccp,ccd,nucz,iwr)
c
c     ----- past zinc does not exist
c
      else
        call caserr2(
     +   'attempting to site dgauss_a2 function on invalid centre')
      endif
c
c     ----- loop over each shell -----
c
      ipass = 0
  210 ipass = ipass+1
        call dgauss_a2_fitsh(nucz,ipass,ityp,igauss,ng,odone)
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
      do 440 i = 1,igauss
         k = k1+i-1
         ex(k) = eex(ng+i)
         if(ityp.eq.16) then
          csinp(k) = ccs(ng+i)
         else if(ityp.eq.17) then
          cpinp(k) = ccp(ng+i)
         else if(ityp.eq.18) then
          cdinp(k) = ccd(ng+i)
         else if (ityp.eq.22) then
          csinp(k) = ccs(ng+i)
          cpinp(k) = ccp(ng+i)
         else
          call caserr2('invalid shell type')
         endif
         cs(k) = 0.0d+00
         cp(k) = 0.0d+00
         cd(k) = 0.0d+00
         cf(k) = 0.0d+00
         if(ityp.eq.16) then
          cs(k) = csinp(k)
         else if(ityp.eq.17) then
          cp(k) = cpinp(k)
         else if(ityp.eq.18) then
          cd(k) = cdinp(k)
         else if(ityp.eq.22) then
          cs(k) = csinp(k)
          cp(k) = cpinp(k)
         else
          call caserr2('invalid shell type')
         endif
  440 continue
c
c     ----- always unnormalize primitives -----
c
      do 460 k = k1,k2
         ee = ex(k)+ex(k)
         facs = pi32/(ee*sqrt(ee))
         facp = pt5*facs/ee
         facd = pt75*facs/(ee*ee)
         if(ityp.eq.16) then
          cs(k) = cs(k)/sqrt(facs)
         else if(ityp.eq.17) then
          cp(k) = cp(k)/sqrt(facp)
         else if(ityp.eq.18) then
          cd(k) = cd(k)/sqrt(facd)
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
      if (normf .eq. 1) go to 210
      facs = 0.0d+00
      facp = 0.0d+00
      facd = 0.0d+00
      do 510 ig = k1,k2
         do 500 jg = k1,ig
            ee = ex(ig)+ex(jg)
            fac = ee*sqrt(ee)
            dums = cs(ig)*cs(jg)/fac
            dump = pt5*cp(ig)*cp(jg)/(ee*fac)
            dumd = pt75*cd(ig)*cd(jg)/(ee*ee*fac)
            if (ig .eq. jg) go to 480
               dums = dums+dums
               dump = dump+dump
               dumd = dumd+dumd
  480       continue
            facs = facs+dums
            facp = facp+dump
            facd = facd+dumd
  500    continue
  510 continue
c
      fac=0.0d+00
      if(ityp.eq.16.and. facs.gt.tm10) then
        fac=1.0d+00/sqrt(facs*pi32)
      else if(ityp.eq.17.and. facp.gt.tm10) then
        fac=1.0d+00/sqrt(facp*pi32)
      else if(ityp.eq.18.and. facd.gt.tm10) then
        fac=1.0d+00/sqrt(facd*pi32)
      else if(ityp.eq.22.and. facs.gt.tm10.
     +                   and. facp.gt.tm10 ) then
        fac1=1.0d+00/sqrt(facs*pi32)
        fac2=1.0d+00/sqrt(facp*pi32)
      else
      endif
c
      do 550 ig = k1,k2
         if(ityp.eq.16) then
          cs(ig) = fac*cs(ig)
         else if(ityp.eq.17) then
          cp(ig) = fac*cp(ig)
         else if(ityp.eq.18) then
          cd(ig) = fac*cd(ig)
         else if(ityp.eq.22) then
          cs(ig) = fac1*cs(ig)
          cp(ig) = fac2*cp(ig)
         else
         endif
  550 continue
      go to 210
c
  220 continue
      return
      end
      subroutine dgauss_a2_fit0(e,s,p,d,n)
c
c     ----- dgauss_a2 fitting basis 
c     ----- hydrogen and helium (3s1sp1d)/(3s1sp1d) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      go to (100,120),n
c
c     ----- h  -----
c
c h     (3s1sp1d) / [3s1sp1d]
c
  100 continue
      e (1) =  45.00000000d0
      e (2) =   7.50000000d0
      e (3) =   0.30000000d0
      e (4) =   1.50000000d0
      e (5) =   1.50000000d0
c
      go to 200
c
c     ----- he  -----
c
c he    (3s1sp1d) / [3s1sp1d] 
c
  120 continue
      e (1) =  54.00000000d0
      e (2) =   9.00000000d0
      e (3) =   0.36000000d0
      e (4) =   1.80000000d0
      e (5) =   1.80000000d0
c
  200 do i =1,3
       s(i) = 1.0d0
      enddo
      s(4) = 1.0d0
      p(4) = 1.0d0
      d(5) = 1.0d0
c
      return
c
      end
      subroutine dgauss_a2_fit1(e,s,p,d,n,iwr)
c
c  ----- DGauss_A2 primitive Coulomb fitting basis
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-2
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- li -----
c
c li    (5s2sp1d) / [5s2sp1d]
c
  100 continue
      e (1) = 256.00000000d0
      e (2) =  51.20000000d0
      e (3) =  12.80000000d0
      e (4) =   3.20000000d0
      e (5) =   0.80000000d0
      e (6) =   0.05000000d0
      e (7) =   0.20000000d0
      e (8) =   0.20000000d0
c
      go to 1000
c
c     ----- be -----
c
c be    (5s2sp1d) / [5s2sp1d]
c
  120 continue
c
      e (1) = 512.00000000d0
      e (2) = 103.00000000d0
      e (3) =  25.60000000d0
      e (4) =   6.40000000d0
      e (5) =   1.60000000d0
      e (6) =   0.11000000d0
      e (7) =   0.40000000d0
      e (8) =   0.40000000d0
c
1000  do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,7
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      d(8) = 1.0d0
c
      return
c
c     ----- b -----
c
c B     (4s4sp4d) / [4s4sp4d]
c
  140 continue
c
      e(1 ) = 992.00000000d0
      e(2 ) = 220.00000000d0
      e(3 ) =  63.04000000d0
      e(4 ) =  18.00000000d0
      e(5 ) =   6.62000000d0
      e(6 ) =   1.47000000d0
      e(7 ) =   0.42000000d0
      e(8 ) =   0.12000000d0
      e(9 ) =   6.62000000d0
      e(10) =   1.47000000d0
      e(11) =   0.42000000d0
      e(12) =   0.12000000d0
c
      go to 2000
c
c     ----- c -----
c
c C     (4s4sp4d) / [4s4sp4d]
c
  160 continue
      e(1 ) = 1500.00000000d0
      e(2 ) =  330.00000000d0
      e(3 ) =   94.32000000d0
      e(4 ) =   27.00000000d0
      e(5 ) =    9.92000000d0
      e(6 ) =    2.20000000d0
      e(7 ) =    0.63000000d0
      e(8 ) =    0.18000000d0
      e(9 ) =    9.92000000d0
      e(10) =    2.20000000d0
      e(11) =    0.63000000d0
      e(12) =    0.18000000d0
c
      go to 2000
c
c     ----- n -----
c
c N     (4s4sp4d) / [4s4sp4d]
c
  180 continue
c
      e(1 ) = 2066.00000000d0
      e(2 ) =  459.00000000d0
      e(3 ) =  131.00000000d0
      e(4 ) =   37.50000000d0
      e(5 ) =   13.80000000d0
      e(6 ) =    3.06000000d0
      e(7 ) =    0.88000000d0
      e(8 ) =    0.25000000d0
      e(9 ) =   13.80000000d0
      e(10) =    3.06000000d0
      e(11) =    0.88000000d0
      e(12) =    0.25000000d0
c
      go to 2000
c
c     ----- o ------
c
c O     (4s4sp4d) / [4s4sp4d]
c
  200 continue
c
      e(1 ) = 2566.00000000d0
      e(2 ) =  570.00000000d0
      e(3 ) =  163.00000000d0
      e(4 ) =   46.50000000d0
      e(5 ) =   17.00000000d0
      e(6 ) =    3.80000000d0
      e(7 ) =    1.08000000d0
      e(8 ) =    0.31000000d0
      e(9 ) =   17.00000000d0
      e(10) =    3.80000000d0
      e(11) =    1.08000000d0
      e(12) =    0.31000000d0
c
      go to 2000
c
c     ----- f -----
c
c F     (4s4sp4d) / [4s4sp4d]
c
  220 continue
c
      e(1 ) = 3100.00000000d0
      e(2 ) =  690.00000000d0
      e(3 ) =  197.00000000d0
      e(4 ) =   56.30000000d0
      e(5 ) =   21.00000000d0
      e(6 ) =    4.60000000d0
      e(7 ) =    1.33000000d0
      e(8 ) =    0.38000000d0
      e(9 ) =   21.00000000d0
      e(10) =    4.60000000d0
      e(11) =    1.33000000d0
      e(12) =    0.38000000d0
c
      go to 2000
c
c     ----- ne -----
c
  240 continue
      if (opg_root()) then
         write(iwr,*)'*** nuclear charge = ',n
      endif
      call caserr2('requested basis set not available')
c
2000   do i = 1,4
       s(i) = 1.0d0
      enddo
      do i = 5,8
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i =  9,12
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine dgauss_a2_fit2(e,s,p,d,n,iwr)
c
c     ----- dgauss_a2 fitting contractions  -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-10
      go to (100,100,140,160,180,200,220,240),nn
c
c     ----- na, mg  -----
c
  100 continue
      if (opg_root()) then
         write(iwr,*)'*** nuclear charge = ',n
      endif
      call caserr2('requested basis set not available')
c
      return
c
c     ----- al -----
c
c al    (5s4sp4d/ [5s4sp4d]
c 
  140 continue
c
      e( 1) = 6861.00000000d0
      e( 2) = 1372.00000000d0
      e( 3) =  343.00000000d0
      e( 4) =   85.80000000d0
      e( 5) =   21.40000000d0
      e( 6) =    6.72000000d0
      e( 7) =    1.34000000d0
      e( 8) =    0.34000000d0
      e( 9) =    0.08400000d0
      e(10) =    6.72000000d0
      e(11) =    1.34000000d0
      e(12) =    0.34000000d0
      e(13) =    0.08400000d0
c
      go to 2000
c
c     ----- si -----
c
c si    (5s4sp4d/ [5s4sp4d]
c
  160 continue
c
      e( 1) = 9830.00000000d0
      e( 2) = 1966.00000000d0
      e( 3) =  492.00000000d0
      e( 4) =  123.00000000d0
      e( 5) =   30.72000000d0
      e( 6) =    9.60000000d0
      e( 7) =    1.92000000d0
      e( 8) =    0.48000000d0
      e( 9) =    0.12000000d0
      e(10) =    9.60000000d0
      e(11) =    1.92000000d0
      e(12) =    0.48000000d0
      e(13) =    0.12000000d0
c
      go to 2000
c
c     ----- p -----
c
c p    (5s4sp4d/ [5s4sp4d]
c
  180 continue
c
      e( 1) = 13107.00000000d0
      e( 2) =  2621.00000000d0
      e( 3) =   655.00000000d0
      e( 4) =   164.00000000d0
      e( 5) =    41.00000000d0
      e( 6) =    13.00000000d0
      e( 7) =     2.60000000d0
      e( 8) =     0.64000000d0
      e( 9) =     0.16000000d0
      e(10) =    13.00000000d0
      e(11) =     2.60000000d0
      e(12) =     0.64000000d0
      e(13) =     0.16000000d0
c
      go to 2000
c
c     ----- s -----
c
c s    (5s4sp4d/ [5s4sp4d]
c
  200 continue
c
      e( 1) = 16384.00000000d0
      e( 2) =  3277.00000000d0
      e( 3) =   819.00000000d0
      e( 4) =   205.00000000d0
      e( 5) =    51.00000000d0
      e( 6) =    16.00000000d0
      e( 7) =     3.20000000d0
      e( 8) =     0.80000000d0
      e( 9) =     0.20000000d0
      e(10) =    16.00000000d0
      e(11) =     3.20000000d0
      e(12) =     0.80000000d0
      e(13) =     0.20000000d0
c
      go to 2000
c
c     ----- cl -----
c
c cl    (5s4sp4d/ [5s4sp4d]
c
  220 continue
c
      e( 1) = 20480.00000000d0
      e( 2) =  4096.00000000d0
      e( 3) =  1024.00000000d0
      e( 4) =   256.00000000d0
      e( 5) =    64.00000000d0
      e( 6) =    20.00000000d0
      e( 7) =     4.00000000d0
      e( 8) =     1.00000000d0
      e( 9) =     0.25000000d0
      e(10) =    20.00000000d0
      e(11) =     4.00000000d0
      e(12) =     1.00000000d0
      e(13) =     0.25000000d0
c
      go to 2000
c
c     ----- ar -----
c
c ar    (5s4sp4d/ [5s4sp4d]
c
  240 continue
c
      e( 1) = 24576.00000000d0
      e( 2) =  4915.00000000d0
      e( 3) =  1229.00000000d0
      e( 4) =   307.00000000d0
      e( 5) =    77.00000000d0
      e( 6) =    24.00000000d0
      e( 7) =     4.80000000d0
      e( 8) =     1.20000000d0
      e( 9) =     0.30000000d0
      e(10) =    24.00000000d0
      e(11) =     4.80000000d0
      e(12) =     1.20000000d0
      e(13) =     0.30000000d0
c
 2000 do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,9
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 10,13
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine dgauss_a2_fit3(e,s,p,d,n,iwr)
c
c ----- dgauss_a2 coulomb fitting basis 
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-18
      go to (100,100,140,160,180,200,220,240,260,280,300,320),nn
c
c     k, ca
c
  100 continue
      if (opg_root()) then
         write(iwr,*)'*** nuclear charge = ',n
      endif
      call caserr2('requested basis set not available')
c
      return
c
c sc    (5s5sp5d) / [5s5sp5d]
c 
  140 continue
c
      e( 1) = 21000.00000000d0
      e( 2) =  4200.00000000d0
      e( 3) =  1050.00000000d0
      e( 4) =   262.40000000d0
      e( 5) =    65.60000000d0
      e( 6) =    20.50000000d0
      e( 7) =     4.10000000d0
      e( 8) =     1.03000000d0
      e( 9) =     0.25600000d0
      e(10) =     0.06400000d0
      e(11) =    20.50000000d0
      e(12) =     4.10000000d0
      e(13) =     1.03000000d0
      e(14) =     0.25600000d0
      e(15) =     0.06400000d0
c
      go to 2000
c
c ti (5s5sp5d) / [5s5sp5d]
c 
  160 continue
c
      e(1 ) = 28000.00000000d0
      e(2 ) =  5600.00000000d0
      e(3 ) =  1400.00000000d0
      e(4 ) =   348.00000000d0
      e(5 ) =    87.00000000d0
      e(6 ) =    27.20000000d0
      e(7 ) =     5.44000000d0
      e(8 ) =     1.36000000d0
      e(9 ) =     0.34000000d0
      e(10) =     0.08400000d0
      e(11) =    27.20000000d0
      e(12) =     5.44000000d0
      e(13) =     1.36000000d0
      e(14) =     0.34000000d0
      e(15) =     0.08400000d0
c
      go to 2000
c
c v    (5s5sp5d) / [5s5sp5d]
c 
  180 continue
c
      e(1 ) = 33100.00000000d0
      e(2 ) =  6620.00000000d0
      e(3 ) =  1650.00000000d0
      e(4 ) =   414.00000000d0
      e(5 ) =   103.00000000d0
      e(6 ) =    32.00000000d0
      e(7 ) =     6.46000000d0
      e(8 ) =     1.61000000d0
      e(9 ) =     0.40400000d0
      e(10) =     0.10100000d0
      e(11) =    32.00000000d0
      e(12) =     6.46000000d0
      e(13) =     1.61000000d0
      e(14) =     0.40400000d0
      e(15) =     0.10100000d0
c
      go to 2000
c
c cr    (5s5sp5d) / [5s5sp5d]
c
  200 continue
c
      e( 1) = 37000.00000000d0
      e( 2) =  7530.00000000d0
      e( 3) =  1880.00000000d0
      e( 4) =   471.00000000d0
      e( 5) =   117.00000000d0
      e( 6) =    36.80000000d0
      e( 7) =     7.36000000d0
      e( 8) =     1.84000000d0
      e( 9) =     0.46000000d0
      e(10) =     0.11500000d0
      e(11) =    36.80000000d0
      e(12) =     7.36000000d0
      e(13) =     1.84000000d0
      e(14) =     0.46000000d0
      e(15) =     0.11500000d0
c
      go to 2000
c
c mn    (5s5sp5d) / [5s5sp5d]
c 
  220 continue
c
      e(1 ) = 41000.00000000d0
      e(2 ) =  8200.00000000d0
      e(3 ) =  2050.00000000d0
      e(4 ) =   510.00000000d0
      e(5 ) =   128.00000000d0
      e(6 ) =    40.00000000d0
      e(7 ) =     8.00000000d0
      e(8 ) =     2.00000000d0
      e(9 ) =     0.50000000d0
      e(10) =     0.12500000d0
      e(11) =    40.00000000d0
      e(12) =     8.00000000d0
      e(13) =     2.00000000d0
      e(14) =     0.50000000d0
      e(15) =     0.12500000d0
c
      go to 2000
c
c fe    (5s5sp5d) / [5s5sp5d]
c 
  240 continue
c
      e( 1) = 44000.00000000d0
      e( 2) =  8800.00000000d0
      e( 3) =  2200.00000000d0
      e( 4) =   550.00000000d0
      e( 5) =   137.00000000d0
      e( 6) =    43.20000000d0
      e( 7) =     8.60000000d0
      e( 8) =     2.20000000d0
      e( 9) =     0.54000000d0
      e(10) =     0.13500000d0
      e(11) =    43.20000000d0
      e(12) =     8.60000000d0
      e(13) =     2.20000000d0
      e(14) =     0.54000000d0
      e(15) =     0.13500000d0
c
      go to 2000
c
c co    (5s5sp5d) / [5s5sp5d]
c 
  260 continue
c
      e( 1) = 47000.00000000d0
      e( 2) =  9400.00000000d0
      e( 3) =  2350.00000000d0
      e( 4) =   590.00000000d0
      e( 5) =   147.00000000d0
      e( 6) =    46.00000000d0
      e( 7) =     9.20000000d0
      e( 8) =     2.30000000d0
      e( 9) =     0.58000000d0
      e(10) =     0.14400000d0
      e(11) =    46.00000000d0
      e(12) =     9.20000000d0
      e(13) =     2.30000000d0
      e(14) =     0.58000000d0
      e(15) =     0.14400000d0
c
      go to 2000
c
c ni    (5s5sp5d) / [5s5sp5d]
c 
  280 continue
c
      e( 1) = 50000.00000000d0
      e( 2) =  9930.00000000d0
      e( 3) =  2500.00000000d0
      e( 4) =   620.00000000d0
      e( 5) =   155.00000000d0
      e( 6) =    48.00000000d0
      e( 7) =     9.70000000d0
      e( 8) =     2.40000000d0
      e( 9) =     0.60000000d0
      e(10) =     0.15200000d0
      e(11) =    48.00000000d0
      e(12) =     9.70000000d0
      e(13) =     2.40000000d0
      e(14) =     0.60000000d0
      e(15) =     0.15200000d0
c
      go to 2000
c
c cu    (5s5sp5d) / [5s5sp5d]
c
  300 continue
c
      e( 1) = 53000.00000000d0
      e( 2) = 10500.00000000d0
      e( 3) =  2640.00000000d0
      e( 4) =   660.00000000d0
      e( 5) =   165.00000000d0
      e( 6) =    51.00000000d0
      e( 7) =    10.30000000d0
      e( 8) =     2.57000000d0
      e( 9) =     0.64000000d0
      e(10) =     0.16000000d0
      e(11) =    51.00000000d0
      e(12) =    10.30000000d0
      e(13) =     2.57000000d0
      e(14) =     0.64000000d0
      e(15) =     0.16000000d0
c
      go to 2000
c
c zn    (5s5sp5d) / [5s5sp5d]
c 
  320 continue
c
      e( 1) = 75500.00000000d0
      e( 2) = 15100.00000000d0
      e( 3) =  3776.00000000d0
      e( 4) =   944.00000000d0
      e( 5) =   236.00000000d0
      e( 6) =    74.00000000d0
      e( 7) =    14.80000000d0
      e( 8) =     3.70000000d0
      e( 9) =     0.92000000d0
      e(10) =     0.23000000d0
      e(11) =    74.00000000d0
      e(12) =    14.80000000d0
      e(13) =     3.70000000d0
      e(14) =     0.92000000d0
      e(15) =     0.23000000d0
c
2000  do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,10
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 11,15
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine demon_fit(csinp,cpinp,cdinp,
     + nucz,intyp,nangm,nbfs,minf,maxf,loc,ngauss,
     + ns,ierr1,ierr2,nat)
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
c
      dimension csinp(*),cpinp(*),cdinp(*),
     +  intyp(*),nangm(*),nbfs(*),minf(*),maxf(*),ns(*)
      common/blkin/eex(50),ccs(50),ccp(50),ccd(50)
INCLUDE(common/iofile)
      common/junk/ptr(18192),iptr(4,maxat),iptrs(2,mxshel),
     *ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     *cf(mxprim),cg(mxprim),
     +kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     +kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell
INCLUDE(common/restar)
c
      data pt5,pt75/
     + 0.5d+00,0.75d+00/
      data pi32,tm10/5.56832799683170d+00,1.0d-10/
c
c     DeMon DFT Coulomb Fitting basis sets
************************************************************
c      N. Godbout, D. R. Salahub, J. Andzelm, and E. Wimmer,    
c      Can. J. Chem. 70, 560 (1992).                            
************************************************************
c      H - He : (4s,1p)     
c      Li     : (7s,3p,3d)
c      Be     : (7s,2p,1d)
c      B  - Ne: (7s,3p,3d)
c      Na     : (9s,3p,3d)
c      Mg     : (9s,4p,3d)
c      Al - Ar: (9s,4p,4d)
c      K- Ca  : (10s,5p,4d)
c      Sc - Kr: (10s,5p,5d)
c      Rb - Sr: (11s,6p,5d)
c      Y  - Xe: (10s,5p,5d)
************************************************************
c
      ng = -2**20
      igauss = ng
      ityp = ng
      ierr1=0
      ierr2=0
      odone = .false.
_IFN1(civu)      call vclr(eex,1,200)
_IFN(civu)      call szero(eex,200)
c
c     ----- hydrogen to helium -----
c
      if (nucz .le. 2) then
          call demon_fit0(eex,ccs,ccp,nucz)
c
c     ----- lithium to neon -----
c
      else if (nucz .le. 10) then
          call demon_fit1(eex,ccs,ccp,ccd,nucz)
c
c     ----- sodium to argon -----
c
      else if (nucz .le. 18) then
          call demon_fit2(eex,ccs,ccp,ccd,nucz)
c
c     ----- potassium to zinc -----
c
      else if(nucz.le.30) then
c     note that K-Zn are same as DGauss A1
          call dgauss_a1_fit3(eex,ccs,ccp,ccd,nucz)
c
c     ----- gallium to krypton -----
c
      else if(nucz.le.36) then
c     note that Ga-Kr are same as DGauss A1
          call dgauss_a1_fit4(eex,ccs,ccp,ccd,nucz)
c
c     ----- rubidium to cadmium
c
      else if (nucz .le. 48) then
c     note that Rb-Cd are same as DGauss A1
          call dgauss_a1_fit5(eex,ccs,ccp,ccd,nucz)
c
c     ----- indium to xenon
c
       else if (nucz .le. 54) then
c     note that In-Xe are same as DGauss A1
          call dgauss_a1_fit6(eex,ccs,ccp,ccd,nucz)
c
c     ----- past xenon does not exist
c
      else
        call caserr2(
     +   'attempting to site demon function on invalid centre')
      endif
c
c     ----- loop over each shell -----
c
      ipass = 0
  210 ipass = ipass+1
        call demon_fitsh(nucz,ipass,ityp,igauss,ng,odone)
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
      do 440 i = 1,igauss
         k = k1+i-1
         ex(k) = eex(ng+i)
         if(ityp.eq.16) then
          csinp(k) = ccs(ng+i)
         else if(ityp.eq.17) then
          cpinp(k) = ccp(ng+i)
         else if(ityp.eq.18) then
          cdinp(k) = ccd(ng+i)
         else if (ityp.eq.22) then
          csinp(k) = ccs(ng+i)
          cpinp(k) = ccp(ng+i)
         else
          call caserr2('invalid shell type')
         endif
         cs(k) = 0.0d+00
         cp(k) = 0.0d+00
         cd(k) = 0.0d+00
         cf(k) = 0.0d+00
         if(ityp.eq.16) then
          cs(k) = csinp(k)
         else if(ityp.eq.17) then
          cp(k) = cpinp(k)
         else if(ityp.eq.18) then
          cd(k) = cdinp(k)
         else if(ityp.eq.22) then
          cs(k) = csinp(k)
          cp(k) = cpinp(k)
         else
          call caserr2('invalid shell type')
         endif
  440 continue
c
c     ----- always unnormalize primitives -----
c
      do 460 k = k1,k2
         ee = ex(k)+ex(k)
         facs = pi32/(ee*sqrt(ee))
         facp = pt5*facs/ee
         facd = pt75*facs/(ee*ee)
         if(ityp.eq.16) then
          cs(k) = cs(k)/sqrt(facs)
         else if(ityp.eq.17) then
          cp(k) = cp(k)/sqrt(facp)
         else if(ityp.eq.18) then
          cd(k) = cd(k)/sqrt(facd)
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
      if (normf .eq. 1) go to 210
      facs = 0.0d+00
      facp = 0.0d+00
      facd = 0.0d+00
      do 510 ig = k1,k2
         do 500 jg = k1,ig
            ee = ex(ig)+ex(jg)
            fac = ee*sqrt(ee)
            dums = cs(ig)*cs(jg)/fac
            dump = pt5*cp(ig)*cp(jg)/(ee*fac)
            dumd = pt75*cd(ig)*cd(jg)/(ee*ee*fac)
            if (ig .eq. jg) go to 480
               dums = dums+dums
               dump = dump+dump
               dumd = dumd+dumd
  480       continue
            facs = facs+dums
            facp = facp+dump
            facd = facd+dumd
  500    continue
  510 continue
c
      fac=0.0d+00
      if(ityp.eq.16.and. facs.gt.tm10) then
        fac=1.0d+00/sqrt(facs*pi32)
      else if(ityp.eq.17.and. facp.gt.tm10) then
        fac=1.0d+00/sqrt(facp*pi32)
      else if(ityp.eq.18.and. facd.gt.tm10) then
        fac=1.0d+00/sqrt(facd*pi32)
      else if(ityp.eq.22.and. facs.gt.tm10.
     +                   and. facp.gt.tm10 ) then
        fac1=1.0d+00/sqrt(facs*pi32)
        fac2=1.0d+00/sqrt(facp*pi32)
      else
      endif
c
      do 550 ig = k1,k2
         if(ityp.eq.16) then
          cs(ig) = fac*cs(ig)
         else if(ityp.eq.17) then
          cp(ig) = fac*cp(ig)
         else if(ityp.eq.18) then
          cd(ig) = fac*cd(ig)
         else if(ityp.eq.22) then
          cs(ig) = fac1*cs(ig)
          cp(ig) = fac2*cp(ig)
         else
         endif
  550 continue
      go to 210
c
  220 continue
      return
      end
      subroutine demon_fit0(e,s,p,n)
c
c     ----- demon fitting basis 
c     ----- hydrogen and helium (3s1sp)/(3s1sp) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*)
      go to (100,120),n
c
c     ----- h  -----
c
c h     (3s1sp) / [3s1sp]
c
  100 continue
      e (1) =  45.00000000d0
      e (2) =   7.50000000d0
      e (3) =   0.30000000d0
      e (4) =   1.50000000d0
c
      go to 200
c
c     ----- he  -----
c
c he    (3s1sp) / [3s1sp] 
c
  120 continue
      e (1) =  54.00000000d0
      e (2) =   9.00000000d0
      e (3) =   0.36000000d0
      e (4) =   1.80000000d0
c
  200 do i =1,3
       s(i) = 1.0d0
      enddo
      s(4) = 1.0d0
      p(4) = 1.0d0
c
      return
c
      end
      subroutine demon_fit1(e,s,p,d,n)
c
c  ----- DeMon primitive Coulomb fitting basis
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-2
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- li -----
c
c li    (4s3sp3d) / [4s3sp3d]
c
  100 continue
      e (1) = 256.00000000d0
      e (2) =  51.20000000d0
      e (3) =  12.80000000d0
      e (4) =   3.20000000d0
      e (5) =   1.02000000d0
      e (6) =   0.20000000d0
      e (7) =   0.05100000d0
      e (8) =   1.02000000d0
      e (9) =   0.20000000d0
      e (10)=   0.05100000d0
c
      do i = 1,4
       s(i) = 1.0d0
      enddo
      do i = 5,7
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 8,10
      d(i) = 1.0d0
      enddo
      return
c
c     ----- be -----
c
c be    (5s2sp1d) / [5s2sp1d]
c
  120 continue
c
      e (1) = 512.00000000d0
      e (2) = 103.00000000d0
      e (3) =  25.60000000d0
      e (4) =   6.40000000d0
      e (5) =   1.60000000d0
      e (6) =   0.11000000d0
      e (7) =   0.40000000d0
      e( 8) =   0.40000000d0
c
      do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,7
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      d(8) = 1.0d0
c
      return
c
c     ----- b -----
c
c B     (4s3sp3d) / [4s3sp3d]
c
  140 continue
c
      e( 1) = 716.80000000d0
      e( 2) = 143.40000000d0
      e( 3) =  35.84000000d0
      e( 4) =   8.96000000d0
      e( 5) =   2.80000000d0
      e( 6) =   0.56000000d0
      e( 7) =   0.14000000d0
      e( 8) =   2.80000000d0
      e( 9) =   0.56000000d0
      e(10) =   0.14000000d0
c
      go to 2000
c
c     ----- c -----
c
c C     (4s3sp3d) / [4s3sp3d]
c
  160 continue
      e( 1) = 1114.00000000d0
      e( 2) =  223.00000000d0
      e( 3) =   55.72000000d0
      e( 4) =   13.90000000d0
      e( 5) =    4.40000000d0
      e( 6) =    0.87000000d0
      e( 7) =    0.22000000d0
      e( 8) =    4.40000000d0
      e( 9) =    0.87000000d0
      e(10) =    0.22000000d0
c
      go to 2000
c
c     ----- n -----
c
c N     (4s3sp3d) / [4s3sp3d]
c
  180 continue
c
      e( 1) = 1640.00000000d0
      e( 2) =  328.00000000d0
      e( 3) =   82.00000000d0
      e( 4) =   20.50000000d0
      e( 5) =    6.40000000d0
      e( 6) =    1.28000000d0
      e( 7) =    0.32000000d0
      e( 8) =    6.40000000d0
      e( 9) =    1.28000000d0
      e(10) =    0.32000000d0
c
      go to 2000
c
c     ----- o ------
c
c O     (4s3sp3d) / [4s3sp3d]
c
  200 continue
c
      e( 1) = 2000.00000000d0
      e( 2) =  400.00000000d0
      e( 3) =  100.00000000d0
      e( 4) =   25.00000000d0
      e( 5) =    7.80000000d0
      e( 6) =    1.56000000d0
      e( 7) =    0.39000000d0
      e( 8) =    7.80000000d0
      e( 9) =    1.56000000d0
      e(10) =    0.39000000d0
c
      go to 2000
c
c     ----- f -----
c
c F     (4s3sp3d) / [4s3sp3d]
c
  220 continue
c
      e( 1) = 2458.00000000d0
      e( 2) =  492.00000000d0
      e( 3) =  123.00000000d0
      e( 4) =   30.70000000d0
      e( 5) =    9.60000000d0
      e( 6) =    1.92000000d0
      e( 7) =    0.48000000d0
      e( 8) =    9.60000000d0
      e( 9) =    1.92000000d0
      e(10) =    0.48000000d0
c
      go to 2000
c
c     ----- ne -----
c
c Ne    (4s3sp3d) / [4s3sp3d]
c
  240 continue
      e( 1) = 3072.00000000d0
      e( 2) =  614.00000000d0
      e( 3) =  153.60000000d0
      e( 4) =   38.40000000d0
      e( 5) =   12.00000000d0
      e( 6) =    2.40000000d0
      e( 7) =    0.60000000d0
      e( 8) =   12.00000000d0
      e( 9) =    2.40000000d0
      e(10) =    0.60000000d0
c
2000   do i = 1,4
       s(i) = 1.0d0
      enddo
      do i = 5,7
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i =  8,10
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine demon_fit2(e,s,p,d,n)
c
c     ----- demon fitting contractions  -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-10
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- na  -----
c
c na    (6s3sp3d) / [6s3sp3d]
c
  100 continue
      e( 1) = 3700.00000000d0
      e( 2) =  737.00000000d0
      e( 3) =  184.00000000d0
      e( 4) =   46.00000000d0
      e( 5) =   11.50000000d0
      e( 6) =    0.04700000d0
      e( 7) =    3.60000000d0
      e( 8) =    0.72000000d0
      e( 9) =    0.18000000d0
      e(10) =    3.60000000d0
      e(11) =    0.72000000d0
      e(12) =    0.18000000d0
c
      do i = 1,6
       s(i) = 1.0d0
      enddo
      do i = 7,9
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 10,12
       d(i) = 1.0d0
      enddo
      return
c
c     ----- mg -----
c
c mg    (5s4sp3d) / [5s4sp3d]
c 
  120 continue
c
      e( 1) = 6140.00000000d0
      e( 2) = 1220.00000000d0
      e( 3) =  310.00000000d0
      e( 4) =   77.00000000d0
      e( 5) =   19.00000000d0
      e( 6) =    0.08000000d0
      e( 7) =    6.00000000d0
      e( 8) =    1.20000000d0
      e( 9) =    0.30000000d0
      e(10) =    6.00000000d0
      e(11) =    1.20000000d0
      e(12) =    0.30000000d0
c
      do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,9
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 10,12
       d(i) = 1.0d0
      enddo
c
      return
c
c     ----- al -----
c
c al    (5s4sp4d/ [5s4sp4d]
c 
  140 continue
c
      e( 1) = 6861.00000000d0
      e( 2) = 1372.00000000d0
      e( 3) =  343.00000000d0
      e( 4) =   85.80000000d0
      e( 5) =   21.40000000d0
      e( 6) =    6.72000000d0
      e( 7) =    1.34000000d0
      e( 8) =    0.34000000d0
      e( 9) =    0.08400000d0
      e(10) =    6.72000000d0
      e(11) =    1.34000000d0
      e(12) =    0.34000000d0
      e(13) =    0.08400000d0
c
      go to 2000
c
c     ----- si -----
c
c si    (5s4sp4d/ [5s4sp4d]
c
  160 continue
c
      e( 1) = 9830.00000000d0
      e( 2) = 1966.00000000d0
      e( 3) =  492.00000000d0
      e( 4) =  123.00000000d0
      e( 5) =   30.72000000d0
      e( 6) =    9.60000000d0
      e( 7) =    1.92000000d0
      e( 8) =    0.48000000d0
      e( 9) =    0.12000000d0
      e(10) =    9.60000000d0
      e(11) =    1.92000000d0
      e(12) =    0.48000000d0
      e(13) =    0.12000000d0
c
      go to 2000
c
c     ----- p -----
c
c p    (5s4sp4d/ [5s4sp4d]
c
  180 continue
c
      e( 1) = 13107.00000000d0
      e( 2) =  2621.00000000d0
      e( 3) =   655.00000000d0
      e( 4) =   164.00000000d0
      e( 5) =    41.00000000d0
      e( 6) =    13.00000000d0
      e( 7) =     2.60000000d0
      e( 8) =     0.64000000d0
      e( 9) =     0.16000000d0
      e(10) =    13.00000000d0
      e(11) =     2.60000000d0
      e(12) =     0.64000000d0
      e(13) =     0.16000000d0
c
      go to 2000
c
c     ----- s -----
c
c s    (5s4sp4d/ [5s4sp4d]
c
  200 continue
c
      e( 1) = 16384.00000000d0
      e( 2) =  3277.00000000d0
      e( 3) =   819.00000000d0
      e( 4) =   205.00000000d0
      e( 5) =    51.00000000d0
      e( 6) =    16.00000000d0
      e( 7) =     3.20000000d0
      e( 8) =     0.80000000d0
      e( 9) =     0.20000000d0
      e(10) =    16.00000000d0
      e(11) =     3.20000000d0
      e(12) =     0.80000000d0
      e(13) =     0.20000000d0
c
      go to 2000
c
c     ----- cl -----
c
c cl    (5s4sp4d/ [5s4sp4d]
c
  220 continue
c
      e( 1) = 20480.00000000d0
      e( 2) =  4096.00000000d0
      e( 3) =  1024.00000000d0
      e( 4) =   256.00000000d0
      e( 5) =    64.00000000d0
      e( 6) =    20.00000000d0
      e( 7) =     4.00000000d0
      e( 8) =     1.00000000d0
      e( 9) =     0.25000000d0
      e(10) =    20.00000000d0
      e(11) =     4.00000000d0
      e(12) =     1.00000000d0
      e(13) =     0.25000000d0
c
      go to 2000
c
c     ----- ar -----
c
c ar    (5s4sp4d/ [5s4sp4d]
c
  240 continue
c
      e( 1) = 24576.00000000d0
      e( 2) =  4915.00000000d0
      e( 3) =  1229.00000000d0
      e( 4) =   307.00000000d0
      e( 5) =    77.00000000d0
      e( 6) =    24.00000000d0
      e( 7) =     4.80000000d0
      e( 8) =     1.20000000d0
      e( 9) =     0.30000000d0
      e(10) =    24.00000000d0
      e(11) =     4.80000000d0
      e(12) =     1.20000000d0
      e(13) =     0.30000000d0
c
 2000 do i = 1,5
       s(i) = 1.0d0
      enddo
      do i = 6,9
       s(i) = 1.0d0
       p(i) = 1.0d0
      enddo
      do i = 10,13
       d(i) = 1.0d0
      enddo
c
      return
      end
      subroutine ahlrichs_fit(csinp,cpinp,cdinp,cfinp,cginp,
     + nucz,intyp,nangm,nbfs,minf,maxf,loc,ngauss,
     + ns,ierr1,ierr2,nat)
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
c
      dimension csinp(*),cpinp(*),cdinp(*)
      dimension cfinp(*),cginp(*),
     +  intyp(*),nangm(*),nbfs(*),minf(*),maxf(*),ns(*)
      common/blkin/eex(50),ccs(50),ccp(50),ccd(50),ccf(50),ccg(50)
INCLUDE(common/iofile)
      common/junk/ptr(18192),iptr(4,maxat),iptrs(2,mxshel),
     *ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     *cf(mxprim),cg(mxprim),
     +kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     +kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell
INCLUDE(common/restar)
c
      data pt5,pt75/0.5d+00,0.75d+00/
      data done/1.0d+00/
      data tol /1.0d-10/

      data pi32/5.56832799683170d+00/
      data pt187,pt6562 /1.875d+00,6.5625d+00/
c
c     Ahlrichs DFT Coulomb Fitting Basis Sets                               
************************************************************
c     K. Eichkorn, O. Treutler, H. Ohm, M. Haser,R. Ahlrichs, 
c     Chem. Phys. Lett. 240, 283 (1995)    
c     K. Eichkorn, F. Weigend, O. Treutler, R. Ahlrichs, 
c     Theor. Chim. Acc. 97,    119 (1997)               
************************************************************
c    Contractions                                                              
c   H:  (4s2p1d)     -> [3s2p1d]      {211/11/1}
c   **
c   He: (4s2p)       -> [2s2p]        {31/11}
c   **
c   Li: (9s2p2d1f)   -> [7s2p2d1f]    {3111111/11/11/1}
c   Be: (9s2p2d1f)   -> [7s2p2d1f]    {3111111/11/11/1}
c   B:  (9s3p3d1f)   -> [7s3p3d1f]    {3111111/111/111/1}
c   **                                                                               
c   C:  (9s3p3d1f)   -> [7s3p3d1f]    {3111111/111/111/1}
c   N:  (9s3p3d1f)   -> [7s3p3d1f]    {3111111/111/111/1}
c   O:  (9s3p3d1f)   -> [7s3p3d1f]    {3111111/111/111/1}
c   F:  (9s3p4d1f)   -> [7s3p4d1f]    {3111111/111/1111/1}
c   Ne: (8s3p3d1f)   -> [6s3p3d1f]    {311111/111/111/1}
c   **                                                                             
c   Na: (12s4p4d1f)   / [5s2p2d1f]    {81111/31/31/1}
c   Mg: (12s4p4d1f)   / [5s2p2d1f]    {81111/31/31/1}
c   Al: (12s4p5d1f)   / [5s3p2d1f]    {81111/211/41/1}
c   Si: (12s6p5d1f1g) / [5s3p2d1f1g]  {81111/411/41/1/1}
c   P:  (12s6p5d1f1g) / [5s3p2d1f1g]  {81111/411/41/1/1}
c   S:  (12s6p5d1f1g) / [5s3p2d1f1g]  {81111/411/41/1/1}
c   Cl: (12s6p5d1f1g) / [5s3p2d1f1g]  {81111/411/41/1/1} 
c   Ar: (12s6p5d1f)   / [5s3p2d1f]    {81111/411/41/1}
c   **                                                                             
c   K:  (16s4p4d1f)   / [6s2p2d1f]    {10 21111/31/31/1}
c   Ca: (16s4p4d1f)   / [6s2p2d1f]    {10 21111/31/31/1}
c   Sc: (16s4p4d3f4g) / [6s4p3d3f2g]  {10 21111/1111/211/111/31}
c   Ti: (16s4p4d3f4g) / [6s4p2d3f2g]  {10 21111/1111/31/111/31}
c   V:  (16s4p4d3f4g) / [6s4p2d3f2g]  {10 21111/1111/31/111/31}
c   Cr: (16s4p4d3f4g) / [6s4p2d3f2g]  {10 21111/1111/31/111/31}
c   Mn: (16s4p4d3f4g) / [6s4p2d3f2g]  {10 21111/1111/31/111/31}
c   Fe: (16s4p4d3f4g) / [6s4p2d3f2g]  {10 21111/1111/31/111/31}
c   Co: (16s4p4d3f4g) / [6s4p3d3f2g]  {10 21111/1111/211/111/31} 
c   Ni: (17s4p4d3f4g) / [7s4p2d3f2g]  {10 211111/1111/31/111/31} 
c   Cu: (17s4p4d3f4g) / [7s4p2d3f2g]  {10 211111/1111/31/111/31}
c   Zn: (17s4p4d3f4g) / [7s4p2d3f2g]  {10 211111/1111/31/111/31} 
c   Ga: (16s4p4d1f)   / [6s4p2d1f]    {10 21111/1111/31/1}
c   Ge: (16s4p5d1f1g) / [6s4p2d1f1g]  {10 21111/1111/41/1/1}
c   As: (16s4p5d1f1g) / [6s4p2d1f1g]  {10 21111/1111/41/1/1}
c   Se: (16s4p5d1f1g) / [6s4p2d1f1g]  {10 21111/1111/41/1/1}
c   Br: (16s4p5d1f1g) / [6s4p2d1f1g]  {10 21111/1111/41/1/1}
c   Kr: (17s4p5d1f1g) / [7s4p2d1f1g]  {10 211111/1111/41/1/1}
c   **                                                                             
c   Rb: (8s4p4d)      / [5s2p2d]      {41111/31/31}
c   Sr: (9s3p3d2f1g)  / [6s3p3d2f1g]  {411111/111/111/11/1}
c   Y:  (8s4p4d3f4g)  / [6s4p2d3f2g]  {311111/1111/31/111/31}
c   Zr: (10s4p4d3f4g) / [6s4p2d3f2g]  {511111/1111/31/111/31}
c   Nb: (8s4p4d3f4g)  / [6s4p3d3f2g]  {311111/1111/211/111/31}
c   Mo: (8s4p4d3f4g)  / [7s4p3d3f2g]  {311111/1111/211/111/31}
c   Tc: (8s4p4d3f4g)  / [6s4p3d3f2g]  {3 11111/1111/211/111/31}
c   Ru: (9s4p4d3f4g)  / [7s4p3d3f2g]  {3111111/1111/211/111/31}
c   Rh: (9s4p4d3f4g)  / [7s4p4d3f2g]  {3111111/1111/1111/111/31}
c   Pd: (9s4p4d3f4g)  / [7s4p2d3f2g]  {3111111/1111/31/111/31}
c   Ag: (9s4p4d3f4g)  / [7s4p3d3f2g]  {3111111/1111/211/111/31}
c   Cd: (9s4p4d3f4g)  / [7s4p2d3f2g]  {3111111/1111/31/111/31}
c   In: (5s3p3d1f1g)  / [3s3p2d1f1g]  {311/111/21/1/1}
c   Sn: (5s3p3d1f1g)  / [4s3p3d1f1g]  {2111/111/111/1/1}
c   Sb: (5s3p3d1f1g)  / [4s3p3d1f1g]  {2111/111/111/1/1}
c   Te: (5s3p3d1f1g)  / [4s3p3d1f1g]  {2111/111/111/1/1}
c   I:  (5s3p3d1f1g)  / [3s3p2d1f1g]  {311/111/21/1/1}
c   Xe: (8s3p3d1f1g)  / [5s3p2d1f1g]  {41111/111/21/1/1}
c   **                                                                             
c   Cs: (9s4p4d)      / [5s2p2d]      {51111/31/31}
c   Ba: (9s3p3d2f1g)  / [6s3p3d2f1g]  {411111/111/111/11/1}
c   Hf: (9s4p4d3f4g)  / [7s4p4d3f2g]  {3111111/1111/1111/111/31}
c   Ta: (8s4p4d3f4g)  / [6s4p3d3f2g]  {311111/1111/211/111/31}
c   W:  (9s4p4d3f4g)  / [7s4p3d3f2g]  {3111111/1111/211/111/31}
c   Re: (9s4p4d3f4g)  / [7s4p3d3f2g]  {3111111/1111/211/111/31}
c   Os: (9s4p4d3f4g)  / [7s4p3d3f2g]  {3111111/1111/211/111/31}
c   Ir: (9s4p4d3f4g)  / [7s4p3d3f2g]  {3111111/1111/211/111/31}
c   Pt: (10s4p5d3f4g) / [8s4p4d3f2g]  {31111111/1111/2111/111/31}
c   Au: (9s4p4d3f4g)  / [8s4p3d3f2g]  {21111111/1111/211/111/31}
c   Hg: (12s4p3d2f2g) / [7s4p3d2f2g]  {6111111/1111/111/11/11}
c   Tl: (5s3p3d1f1g)  / [3s3p2d1f1g]  {311/111/21/1/1}
c   Pb: (5s3p3d1f1g)  / [4s3p2d1f1g]  {2111/111/21/1/1}
c   Bi: (5s3p3d1f1g)  / [4s3p3d1f1g]  {2111/111/111/1/1} 
c   Po: (5s3p3d1f1g)  / [4s3p2d1f1g]  {2111/111/21/1/1}
c   At: (5s3p3d1f1g)  / [3s3p2d1f1g]  {311/111/21/1/1}
************************************************************
c
      ng = -2**20
      igauss = ng
      ityp = ng
      ierr1=0
      ierr2=0
      odone = .false.
_IFN1(civu)      call vclr(eex,1,300)
_IFN(civu)      call szero(eex,300)
c
c     ----- hydrogen to helium -----
c
      if (nucz .le. 2) then
          call ahlrichs_fit0(eex,ccs,ccp,ccd,nucz)
c
c     ----- lithium to neon -----
c
      else if (nucz .le. 10) then
          call ahlrichs_fit1(eex,ccs,ccp,ccd,ccf,nucz)
c
c     ----- sodium to argon -----
c
      else if (nucz .le. 18) then
          call ahlrichs_fit2(eex,ccs,ccp,ccd,ccf,ccg,nucz)
c
c     ----- potassium to zinc -----
c
      else if(nucz.le.30) then
          call ahlrichs_fit3(eex,ccs,ccp,ccd,ccf,ccg,nucz)
c
c     ----- gallium to krypton -----
c
      else if(nucz.le.36) then
          call ahlrichs_fit4(eex,ccs,ccp,ccd,ccf,ccg,nucz)
c
c     ----- rubidium to cadmium
c
      else if (nucz .le. 48) then
          call ahlrichs_fit5(eex,ccs,ccp,ccd,ccf,ccg,nucz)
c
c     ----- indium to xenon
c
       else if (nucz .le. 54) then
          call ahlrichs_fit6(eex,ccs,ccp,ccd,ccf,ccg,nucz)
c
c     ----- past xenon does not exist
c
      else
        call caserr2(
     +   'attempting to site ahlrichs function on invalid centre')
      endif
c
c     ----- loop over each shell -----
c
      ipass = 0
  210 ipass = ipass+1
      call ahlrichs_fitsh(nucz,ipass,ityp,igauss,ng,odone)
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
        if(ityp.eq.16) csinp(k) = ccs(ng+i)
        if(ityp.eq.17) cpinp(k) = ccp(ng+i)
        if(ityp.eq.18) cdinp(k) = ccd(ng+i)
        if(ityp.eq.19) cfinp(k) = ccf(ng+i)
        if(ityp.eq.20) cginp(k) = ccg(ng+i)
        cs(k) = 0.0d0
        cp(k) = 0.0d0
        cd(k) = 0.0d0
        cf(k) = 0.0d0
        cg(k) = 0.0d0
        if(ityp.eq.16) cs(k) = csinp(k)
        if(ityp.eq.17) cp(k) = cpinp(k)
        if(ityp.eq.18) cd(k) = cdinp(k)
        if(ityp.eq.19) cf(k) = cfinp(k)
        if(ityp.eq.20) cg(k) = cginp(k)
      enddo
c
c     ----- always unnormalize primitives -----
c
      do k = k1,k2
        ee = ex(k)+ex(k)
        facs = pi32/(ee*sqrt(ee))
        facp = pt5*facs/ee
        facd = pt75*facs/(ee*ee)
        facf = pt187*facs/(ee**3)
        facg = pt6562*facs/(ee**4)
        if(ityp.eq.16) cs(k) = cs(k)/sqrt(facs)
        if(ityp.eq.17) cp(k) = cp(k)/sqrt(facp)
        if(ityp.eq.18) cd(k) = cd(k)/sqrt(facd)
        if(ityp.eq.19) cf(k) = cf(k)/sqrt(facf)
        if(ityp.eq.20) cg(k) = cg(k)/sqrt(facg)
      enddo
c
c     ----- if(normf.eq.0) normalize basis functions -----
c
      if (normf .eq. 1) go to 210
      facs = 0.0d+00
      facp = 0.0d+00
      facd = 0.0d+00
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
      fac=0.0d+00
      if(ityp.eq.16.and. facs.gt.tol) fac=done/sqrt(facs*pi32)
      if(ityp.eq.17.and. facp.gt.tol) fac=done/sqrt(facp*pi32)
      if(ityp.eq.18.and. facd.gt.tol) fac=done/sqrt(facd*pi32)
      if(ityp.eq.19.and. facf.gt.tol) fac=done/sqrt(facf*pi32)
      if(ityp.eq.20.and. facg.gt.tol) fac=done/sqrt(facg*pi32)
c
      do ig = k1,k2
        if(ityp.eq.16) cs(ig) = fac*cs(ig)
        if(ityp.eq.17) cp(ig) = fac*cp(ig)
        if(ityp.eq.18) cd(ig) = fac*cd(ig)
        if(ityp.eq.19) cf(ig) = fac*cf(ig)
        if(ityp.eq.20) cg(ig) = fac*cg(ig)
      enddo
      go to 210
c
  220 continue
      return
      end
      subroutine ahlrichs_fit0(e,s,p,d,n)
c
c     ----- ahlrichs fitting basis 
c     ----- hydrogen and helium ( -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      go to (100,120),n
c
c     ----- h  -----
c
c h     (4s2p1d) / [3s2p1d]
c
  100 continue
      e(  1) =      9.30813000d0
      s(  1) =      0.03446618d0
      e(  2) =      2.30671800d0
      s(  2) =      0.12253380d0
      e(  3) =      0.75201200d0
      s(  3) =      0.18250021d0
      e(  4) =      0.27397800d0
      s(  4) =      0.02215055d0
      e(  5) =      2.03270400d0
      p(  5) =      0.02951366d0
      e(  6) =      0.79025200d0
      p(  6) =      0.03275587d0
      e(  7) =      2.01954800d0
      d(  7) =      1.00000000d0

c
      return
c
c     ----- he  -----
c
c he    (4s2p) / [2s2p] 
c
  120 continue
      e(  1) =     37.39393000d0
      s(  1) =      0.10996705d0
      e(  2) =      6.98669000d0
      s(  2) =      0.37520477d0
      e(  3) =      1.92344500d0
      s(  3) =      0.41847746d0
      e(  4) =      0.62875700d0
      s(  4) =      0.10809876d0
      e(  5) =      3.60021686d0
      p(  5) =     -0.03554743d0
      e(  6) =      1.50009035d0
      p(  6) =     -0.03052394d0
c
      return
c
      end
      subroutine ahlrichs_fit1(e,s,p,d,f,n)
c
c  ----- Ahlrichs  Coulomb fitting basis (Li-Ne)
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*)
      nn = n-2
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- li -----
c
c li    (9s2p2d1f) / [7s2p2d1f]
c
  100 continue
      e(  1) =    173.28970900d0
      s(  1) =      0.08014875d0
      e(  2) =     47.83443600d0
      s(  2) =      0.25220565d0
      e(  3) =     14.75362700d0
      s(  3) =      0.66520903d0
      e(  4) =      5.05214700d0
      s(  4) =      0.77658078d0
      e(  5) =      1.90155000d0
      s(  5) =      0.27184755d0
      e(  6) =      0.77551500d0
      s(  6) =     -0.01362138d0
      e(  7) =      0.33635500d0
      s(  7) =     -0.00915809d0
      e(  8) =      0.15165900d0
      s(  8) =      0.03582379d0
      e(  9) =      0.06929600d0
      s(  9) =      0.01936454d0
      e( 10) =      0.37786400d0
      p( 10) =      0.00619413d0
      e( 11) =      0.15955400d0
      p( 11) =     -0.01671452d0
      e( 12) =      0.56049300d0
      d( 12) =      0.00008470d0
      e( 13) =      0.23737800d0
      d( 13) =      0.00130504d0
      e( 14) =      0.46842600d0
      f( 14) =     -0.00173419d0
c
      return
c
c     ----- be -----
c
c be    (9s2p2d1f) / [7s2p2d1f]
c
  120 continue
c
      e(  1) =    268.61624200d0
      s(  1) =      0.15583423d0
      e(  2) =     76.01519800d0
      s(  2) =      0.46299792d0
      e(  3) =     23.91629800d0
      s(  3) =      1.16784141d0
      e(  4) =      8.31085400d0
      s(  4) =      1.24405915d0
      e(  5) =      3.15795600d0
      s(  5) =      0.29869665d0
      e(  6) =      1.29404000d0
      s(  6) =     -0.08096314d0
      e(  7) =      0.56171800d0
      s(  7) =      0.03579799d0
      e(  8) =      0.25283000d0
      s(  8) =      0.12502778d0
      e(  9) =      0.11521700d0
      s(  9) =      0.03167219d0
      e( 10) =      3.73425100d0
      p( 10) =     -0.03355593d0
      e( 11) =      1.11302600d0
      p( 11) =      0.01077840d0
      e( 12) =      0.91871400d0
      d( 12) =     -0.00415891d0
      e( 13) =      0.35568200d0
      d( 13) =     -0.03089278d0
      e( 14) =      0.39537000d0
      f( 14) =      1.00000000d0
c
      return
c
c     ----- b -----
c
c B     (9s3p3d1f) / [7s3p3d1f]
c
  140 continue
c
      e(  1) =    392.03445800d0
      s(  1) =      0.24593101d0
      e(  2) =    117.49724000d0
      s(  2) =      0.64303242d0
      e(  3) =     38.12459600d0
      s(  3) =      1.68735933d0
      e(  4) =     13.30012200d0
      s(  4) =      1.80216774d0
      e(  5) =      4.94389200d0
      s(  5) =      0.38496025d0
      e(  6) =      1.93641700d0
      s(  6) =     -0.15685891d0
      e(  7) =      0.78870500d0
      s(  7) =      0.21515206d0
      e(  8) =      0.32911700d0
      s(  8) =      0.20305080d0
      e(  9) =      0.13846800d0
      s(  9) =      0.02841510d0
      e( 10) =      1.22297600d0
      p( 10) =     -0.01767502d0
      e( 11) =      0.49485300d0
      p( 11) =     -0.00772346d0
      e( 12) =      0.20879300d0
      p( 12) =     -0.04317522d0
      e( 13) =      2.40189800d0
      d( 13) =      0.03434676d0
      e( 14) =      0.76449700d0
      d( 14) =      0.05617363d0
      e( 15) =      0.25749400d0
      d( 15) =      0.02163396d0
      e( 16) =      0.91306700d0
      f( 16) =      0.02792465d0
c
      return
c
c     ----- c -----
c
c C    (9s3p3d1f) / [7s3p3d1f]
c
  160 continue
      e(  1) =    591.55392700d0
      s(  1) =      0.31582020d0
      e(  2) =    172.11794000d0
      s(  2) =      0.87503863d0
      e(  3) =     54.79925900d0
      s(  3) =      2.30760524d0
      e(  4) =     18.95909400d0
      s(  4) =      2.41797215d0
      e(  5) =      7.05993000d0
      s(  5) =      0.41345762d0
      e(  6) =      2.79484900d0
      s(  6) =     -0.19000954d0
      e(  7) =      1.15863400d0
      s(  7) =      0.37707105d0
      e(  8) =      0.49432400d0
      s(  8) =      0.34791788d0
      e(  9) =      0.21296900d0
      s(  9) =      0.05474077d0
      e( 10) =      0.32784736d0
      p( 10) =      0.05319099d0
      e( 11) =      0.78683366d0
      p( 11) =      0.00134420d0
      e( 12) =      1.97101832d0
      p( 12) =      0.02219860d0
      e( 13) =      4.01330100d0
      d( 13) =      0.05246841d0
      e( 14) =      1.24750500d0
      d( 14) =      0.08026783d0
      e( 15) =      0.40814800d0
      d( 15) =      0.02963617d0
      e( 16) =      0.90000000d0
      f( 16) =      1.00000000d0
c 
c
      return
c
c     ----- n -----
c
c N    (9s3p3d1f) / [7s3p3d1f]
c
  180 continue
c
      e(  1) =    791.07693500d0
      s(  1) =      0.41567506d0
      e(  2) =    229.45018400d0
      s(  2) =      1.14750694d0
      e(  3) =     72.88696000d0
      s(  3) =      3.01935767d0
      e(  4) =     25.18159600d0
      s(  4) =      3.03233041d0
      e(  5) =      9.37169700d0
      s(  5) =      0.38784949d0
      e(  6) =      3.71065500d0
      s(  6) =     -0.18292931d0
      e(  7) =      1.53946300d0
      s(  7) =      0.65238939d0
      e(  8) =      0.65755300d0
      s(  8) =      0.49991067d0
      e(  9) =      0.28365400d0
      s(  9) =      0.07386879d0
      e( 10) =      0.47073919d0
      p( 10) =      0.06740575d0
      e( 11) =      1.12977407d0
      p( 11) =     -0.02250555d0
      e( 12) =      2.83008403d0
      p( 12) =      0.03554557d0
      e( 13) =      5.83298650d0
      d( 13) =      0.04160404d0
      e( 14) =      1.73268650d0
      d( 14) =      0.01105970d0
      e( 15) =      0.54524250d0
      d( 15) =      0.04840796d0
      e( 16) =      1.82648000d0
      f( 16) =      1.00000000d0
c
      return
c
c     ----- o ------
c
c O     (9s3p3d1f) / [7s3p3d1f]
c
  200 continue
c
      e(  1) =    957.84325300d0
      s(  1) =      0.56249624d0
      e(  2) =    281.96742500d0
      s(  2) =      1.49108985d0
      e(  3) =     90.19983200d0
      s(  3) =      3.86547733d0
      e(  4) =     31.13829900d0
      s(  4) =      3.60577725d0
      e(  5) =     11.49373200d0
      s(  5) =      0.23005858d0
      e(  6) =      4.48404900d0
      s(  6) =     -0.05015769d0
      e(  7) =      1.82350400d0
      s(  7) =      1.05070463d0
      e(  8) =      0.76090300d0
      s(  8) =      0.58565488d0
      e(  9) =      0.32029200d0
      s(  9) =      0.07499129d0
      e( 10) =      0.61470886d0
      p( 10) =     -0.08557844d0
      e( 11) =      1.47530127d0
      p( 11) =      0.04179996d0
      e( 12) =      3.69562968d0
      p( 12) =     -0.05855108d0
      e( 13) =      7.65267200d0
      d( 13) =      0.09106873d0
      e( 14) =      2.21786800d0
      d( 14) =      0.11163134d0
      e( 15) =      0.68233700d0
      d( 15) =      0.04600666d0
      e( 16) =      2.19178082d0
      f( 16) =      1.00000000d0
c
      return
c
c     ----- f -----
c
c F    (9s3p4d1f) / [7s3p4d1f]
c
  220 continue
c
      e(  1) =   1156.70231000d0
      s(  1) =      0.71431186d0
      e(  2) =    345.04030200d0
      s(  2) =      1.84554195d0
      e(  3) =    111.33205800d0
      s(  3) =      4.71095270d0
      e(  4) =     38.59023400d0
      s(  4) =      4.21329515d0
      e(  5) =     14.24146600d0
      s(  5) =      0.11772222d0
      e(  6) =      5.53413200d0
      s(  6) =      0.15894702d0
      e(  7) =      2.23509600d0
      s(  7) =      1.49637682d0
      e(  8) =      0.92451400d0
      s(  8) =      0.68056750d0
      e(  9) =      0.38551600d0
      s(  9) =      0.11297897d0
      e( 10) =      3.12693419d0
      p( 10) =      1.00000000d0
      e( 11) =      1.26740199d0
      p( 11) =      1.00000000d0
      e( 12) =      0.52808416d0
      p( 12) =      1.00000000d0
      e( 13) =     23.18557000d0
      d( 13) =     -0.04106421d0
      e( 14) =      6.68248300d0
      d( 14) =     -0.13327013d0
      e( 15) =      2.16767700d0
      d( 15) =     -0.12350252d0
      e( 16) =      0.73384900d0
      d( 16) =     -0.03195039d0
      e( 17) =      2.55707762d0
      f( 17) =      1.00000000d0
c
      return
c
c     ----- ne -----
c
c Ne   (8s3p3d1f)   -> [6s3p3d1f]
c
  240 continue
      e(  1) =   1273.30572000d0
      s(  1) =      0.89624205d0
      e(  2) =    414.74795000d0
      s(  2) =      2.13453736d0
      e(  3) =    138.15585800d0
      s(  3) =      5.43243958d0
      e(  4) =     46.89036900d0
      s(  4) =      5.12447677d0
      e(  5) =     16.15205200d0
      s(  5) =     -0.13343712d0
      e(  6) =      5.62371600d0
      s(  6) =      0.89830505d0
      e(  7) =      1.97076200d0
      s(  7) =      2.09523338d0
      e(  8) =      0.69212900d0
      s(  8) =      0.44196115d0
      e(  9) =      5.92304060d0
      p(  9) =      0.00333975d0
      e( 10) =      2.36448720d0
      p( 10) =     -0.00991504d0
      e( 11) =      0.98520300d0
      p( 11) =      0.00744346d0
      e( 12) =     11.64327200d0
      d( 12) =     -0.00136835d0
      e( 13) =      3.49736420d0
      d( 13) =      0.00191058d0
      e( 14) =      1.11027430d0
      d( 14) =     -0.00316267d0
      e( 15) =      3.77600000d0
      f( 15) =      0.00054413d0
c
      return
      end
      subroutine ahlrichs_fit2(e,s,p,d,f,g,n)
c
c     ----- ahlrichs fitting contractions  -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*),g(*)
      nn = n-10
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- na  -----
c
c Na: (12s4p4d1f)   / [5s2p2d1f]    {81111/31/31/1}
c
  100 continue
c
      e(  1) =   1822.59686000d0
      s(  1) =      0.87708826d0
      e(  2) =    614.83375600d0
      s(  2) =      1.87407783d0
      e(  3) =    216.82363800d0
      s(  3) =      5.13494627d0
      e(  4) =     79.70117500d0
      s(  4) =      6.50321066d0
      e(  5) =     30.43393900d0
      s(  5) =      1.67978337d0
      e(  6) =     12.02568500d0
      s(  6) =     -0.53919911d0
      e(  7) =      4.89602400d0
      s(  7) =      2.21157329d0
      e(  8) =      2.04406800d0
      s(  8) =      1.90323348d0
      e(  9) =      0.87062800d0
      s(  9) =      0.28294600d0
      e( 10) =      0.37625500d0
      s( 10) =      0.00171988d0
      e( 11) =      0.16404500d0
      s( 11) =      0.00721684d0
      e( 12) =      0.07173500d0
      s( 12) =      0.03349118d0
      e( 13) =      0.28704200d0
      p( 13) =      0.00645603d0
      e( 14) =      0.12636300d0
      p( 14) =     -0.00973781d0
      e( 15) =      0.06686700d0
      p( 15) =     -0.01447956d0
      e( 16) =      0.03793900d0
      p( 16) =      0.00191820d0
      e( 17) =      0.32748100d0
      d( 17) =     -0.00059472d0
      e( 18) =      0.09445800d0
      d( 18) =      0.00414107d0
      e( 19) =      0.02847800d0
      d( 19) =     -0.00045836d0
      e( 20) =      0.00871700d0
      d( 20) =      0.00003717d0
      e( 21) =      0.13495300d0
      f( 21) =     -0.00040890d0
c
      return
c
c     ----- mg -----
c
c Mg: (12s2p2d1f)   / [5s2p2d1f]
c 
  120 continue
c
      e(  1) =   2322.92522000d0
      s(  1) =      0.93046749d0
      e(  2) =    780.20526000d0
      s(  2) =      2.02907033d0
      e(  3) =    275.40661000d0
      s(  3) =      5.62509844d0
      e(  4) =    101.86220400d0
      s(  4) =      7.52497942d0
      e(  5) =     39.33338200d0
      s(  5) =      2.35689967d0
      e(  6) =     15.79076300d0
      s(  6) =     -0.81547749d0
      e(  7) =      6.55951000d0
      s(  7) =      2.56544360d0
      e(  8) =      2.80452000d0
      s(  8) =      2.54940372d0
      e(  9) =      1.22698300d0
      s(  9) =      0.36062429d0
      e( 10) =      0.54588300d0
      s( 10) =     -0.04255652d0
      e( 11) =      0.24535100d0
      s( 11) =      0.07636400d0
      e( 12) =      0.11065300d0
      s( 12) =      0.07251368d0
      e( 13) =     20.15338100d0
      p( 13) =      0.00302972d0
      e( 14) =      3.96115200d0
      p( 14) =      0.02178989d0
      e( 15) =      0.97862200d0
      p( 15) =     -0.02560187d0
      e( 16) =      0.26442200d0
      p( 16) =      0.03260640d0
      e( 17) =     49.36793300d0
      d( 17) =     -0.00047602d0
      e( 18) =      7.30566200d0
      d( 18) =      0.00144097d0
      e( 19) =      1.34845700d0
      d( 19) =     -0.00576280d0
      e( 20) =      0.27125200d0
      d( 20) =      0.01418215d0
      e( 21) =      0.24603700d0
      f( 21) =      0.00384940d0
c
      return
c
c     ----- al -----
c
c Al: (12s4p5d1f)   / [5s3p2d1f]
c 
  140 continue
c
      e(  1) =   2838.12879000d0
      s(  1) =      0.98901466d0
      e(  2) =   1055.50526000d0
      s(  2) =      1.74006712d0
      e(  3) =    400.89567200d0
      s(  3) =      5.12581286d0
      e(  4) =    155.22047900d0
      s(  4) =      8.24241456d0
      e(  5) =     61.14585500d0
      s(  5) =      4.86552632d0
      e(  6) =     24.45635700d0
      s(  6) =     -1.09354000d0
      e(  7) =      9.91029200d0
      s(  7) =      2.23516080d0
      e(  8) =      4.05953100d0
      s(  8) =      3.86939384d0
      e(  9) =      1.67707400d0
      s(  9) =      0.53799944d0
      e( 10) =      0.69707800d0
      s( 10) =     -0.10440190d0
      e( 11) =      0.29081000d0
      s( 11) =      0.20407057d0
      e( 12) =      0.12147100d0
      s( 12) =      0.08214089d0
      e( 13) =      0.93486800d0
      p( 13) =     -0.00361593d0
      e( 14) =      0.34575400d0
      p( 14) =     -0.00722040d0
      e( 15) =      0.13853800d0
      p( 15) =     -0.03468159d0
      e( 16) =      0.05709700d0
      p( 16) =     -0.00021647d0
      e( 17) =     15.36961200d0
      d( 17) =      0.01850798d0
      e( 18) =      4.05229400d0
      d( 18) =      0.00029445d0
      e( 19) =      1.24144400d0
      d( 19) =     -0.00899572d0
      e( 20) =      0.42125800d0
      d( 20) =      0.03215606d0
      e( 21) =      0.14826400d0
      d( 21) =      0.02148560d0
      e( 22) =      0.50034800d0
      f( 22) =      0.01957413d0
c
      return
c
c     ----- si -----
c
c Si: (12s6p5d1f1g) / [5s3p2d1f1g]
c
  160 continue
c
      e(  1) =   2611.04428000d0
      s(  1) =      1.56488355d0
      e(  2) =    778.10695400d0
      s(  2) =      4.01170927d0
      e(  3) =    251.33454900d0
      s(  3) =      9.91872011d0
      e(  4) =     87.77160300d0
      s(  4) =      7.69589454d0
      e(  5) =     33.01605500d0
      s(  5) =     -0.83505216d0
      e(  6) =     13.30896300d0
      s(  6) =      1.74225093d0
      e(  7) =      5.71110600d0
      s(  7) =      4.75683271d0
      e(  8) =      2.58733400d0
      s(  8) =      1.24764169d0
      e(  9) =      1.22527200d0
      s(  9) =     -0.32562388d0
      e( 10) =      0.59965700d0
      s( 10) =      0.17914316d0
      e( 11) =      0.29948700d0
      s( 11) =      0.24619214d0
      e( 12) =      0.15060100d0
      s( 12) =      0.09450132d0
      e( 13) =     24.37119520d0
      p( 13) =      1.00000000d0
      e( 14) =      8.26542474d0
      p( 14) =      1.00000000d0
      e( 15) =      3.05158086d0
      p( 15) =      1.00000000d0
      e( 16) =      1.20276273d0
      p( 16) =      1.00000000d0
      e( 17) =      0.49409267d0
      p( 17) =      1.00000000d0
      e( 18) =      0.20587195d0
      p( 18) =      1.00000000d0
      e( 19) =     16.83377400d0
      d( 19) =     -0.02758637d0
      e( 20) =      5.06087100d0
      d( 20) =      0.00093937d0
      e( 21) =      1.67639500d0
      d( 21) =      0.01469722d0
      e( 22) =      0.59142800d0
      d( 22) =     -0.04773658d0
      e( 23) =      0.21328000d0
      d( 23) =     -0.02554689d0
      e( 24) =      0.63926941d0
      f( 24) =      1.00000000d0
      e( 25) =      0.70000000d0
      g( 25) =      1.00000000d0
c
      return
c
c     ----- p -----
c
c P:  (12s6p5d1f1g) / [5s3p2d1f1g]
c
  180 continue
c
      e(  1) =   3080.37463000d0
      s(  1) =      1.69071816d0
      e(  2) =    913.43425600d0
      s(  2) =      4.40910922d0
      e(  3) =    294.67914500d0
      s(  3) =     10.94606900d0
      e(  4) =    103.18237700d0
      s(  4) =      8.71606171d0
      e(  5) =     39.07326100d0
      s(  5) =     -0.94145644d0
      e(  6) =     15.92055200d0
      s(  6) =      1.93918410d0
      e(  7) =      6.93259400d0
      s(  7) =      5.61881863d0
      e(  8) =      3.19860600d0
      s(  8) =      1.50104535d0
      e(  9) =      1.54748600d0
      s(  9) =     -0.59648053d0
      e( 10) =      0.77558600d0
      s( 10) =      0.32196064d0
      e( 11) =      0.39728500d0
      s( 11) =      0.35720257d0
      e( 12) =      0.20501100d0
      s( 12) =      0.16055723d0
      e( 13) =     33.05554940d0
      p( 13) =     -0.03122479d0
      e( 14) =     11.21069990d0
      p( 14) =      0.09092310d0
      e( 15) =      4.13897148d0
      p( 15) =     -0.08203196d0
      e( 16) =      1.63135137d0
      p( 16) =      0.07560904d0
      e( 17) =      0.67015608d0
      p( 17) =     -0.03912389d0
      e( 18) =      0.27923170d0
      p( 18) =      0.04543913d0
      e( 19) =     22.77470000d0
      d( 19) =      0.01441838d0
      e( 20) =      6.84373550d0
      d( 20) =     -0.00091274d0
      e( 21) =      2.26347250d0
      d( 21) =     -0.00383921d0
      e( 22) =      0.79671950d0
      d( 22) =      0.01406653d0
      e( 23) =      0.28657650d0
      d( 23) =      0.01491393d0
      e( 24) =      0.82191781d0
      f( 24) =      1.00000000d0
      e( 25) =      0.90000000d0
      g( 25) =      1.00000000d0
c
      return
c
c     ----- s -----
c
c S:  (12s6p5d1f1g) / [5s3p2d1f1g] 
c
  200 continue
c
      e(  1) =   3612.93769000d0
      s(  1) =      1.81284859d0
      e(  2) =   1059.65142000d0
      s(  2) =      4.84805075d0
      e(  3) =    339.29484500d0
      s(  3) =     12.11665650d0
      e(  4) =    118.35323600d0
      s(  4) =      9.70399474d0
      e(  5) =     44.81973000d0
      s(  5) =     -1.16396453d0
      e(  6) =     18.33376100d0
      s(  6) =      2.39681432d0
      e(  7) =      8.04530900d0
      s(  7) =      6.53823916d0
      e(  8) =      3.75400800d0
      s(  8) =      1.55418734d0
      e(  9) =      1.84237700d0
      s(  9) =     -0.95175205d0
      e( 10) =      0.93893100d0
      s( 10) =      0.62532806d0
      e( 11) =      0.48979800d0
      s( 11) =      0.40459013d0
      e( 12) =      0.25753100d0
      s( 12) =      0.24775177d0
      e( 13) =     41.74187100d0
      p( 13) =     -0.03327321d0
      e( 14) =     14.15664230d0
      p( 14) =      0.08886927d0
      e( 15) =      5.22660844d0
      p( 15) =     -0.07523737d0
      e( 16) =      2.06003711d0
      p( 16) =      0.07158818d0
      e( 17) =      0.84625938d0
      p( 17) =     -0.03825018d0
      e( 18) =      0.35260807d0
      p( 18) =      0.02599717d0
      e( 19) =     28.71562600d0
      d( 19) =      0.04310507d0
      e( 20) =      8.62660000d0
      d( 20) =      0.00370010d0
      e( 21) =      2.85055000d0
      d( 21) =     -0.02603492d0
      e( 22) =      1.00201100d0
      d( 22) =      0.07226404d0
      e( 23) =      0.35987300d0
      d( 23) =      0.03752159d0
      e( 24) =      1.00456621d0
      f( 24) =      1.00000000d0
      e( 25) =      1.10000000d0
      g( 25) =      1.00000000d0
c
      return
c
c     ----- cl -----
c
c Cl (12s6p5d1f1g) / [5s3p2d1f1g]
c
  220 continue
c
      e(  1) =   4097.08041000d0
      s(  1) =      1.98054511d0
      e(  2) =   1203.08319000d0
      s(  2) =      5.30973450d0
      e(  3) =    386.28094800d0
      s(  3) =     13.23526550d0
      e(  4) =    135.33769000d0
      s(  4) =     10.71499600d0
      e(  5) =     51.56704600d0
      s(  5) =     -1.32565114d0
      e(  6) =     21.26103400d0
      s(  6) =      2.71180364d0
      e(  7) =      9.42013500d0
      s(  7) =      7.54640511d0
      e(  8) =      4.44522800d0
      s(  8) =      1.73603618d0
      e(  9) =      2.20939900d0
      s(  9) =     -1.40197496d0
      e( 10) =      1.14157500d0
      s( 10) =      0.98271974d0
      e( 11) =      0.60418200d0
      s( 11) =      0.46417859d0
      e( 12) =      0.32237800d0
      s( 12) =      0.36933689d0
      e( 13) =     51.84999030d0
      p( 13) =      0.03593355d0
      e( 14) =     17.58478350d0
      p( 14) =     -0.08695993d0
      e( 15) =      6.49227240d0
      p( 15) =      0.07212112d0
      e( 16) =      2.55889115d0
      p( 16) =     -0.06342019d0
      e( 17) =      1.05118768d0
      p( 17) =      0.02641523d0
      e( 18) =      0.43799487d0
      p( 18) =     -0.01976707d0
      e( 19) =     34.70555000d0
      d( 19) =     -0.05487037d0
      e( 20) =     10.70442700d0
      d( 20) =     -0.00619019d0
      e( 21) =      3.56806700d0
      d( 21) =      0.03374505d0
      e( 22) =      1.24984800d0
      d( 22) =     -0.09052322d0
      e( 23) =      0.44536000d0
      d( 23) =      0.04186801d0
      e( 24) =      1.18721461d0
      f( 24) =      1.00000000d0
      e( 25) =      1.30000000d0
      g( 25) =      1.00000000d0
c
      return
c
c     ----- ar -----
c
c Ar: (12s6p5d1f) / [5s3p2d1f] 
c
  240 continue
c
      e(  1) =   4620.80404000d0
      s(  1) =      2.13523201d0
      e(  2) =   1374.29205000d0
      s(  2) =      5.65223447d0
      e(  3) =    446.44822800d0
      s(  3) =     14.10271770d0
      e(  4) =    158.08289300d0
      s(  4) =     12.03992770d0
      e(  5) =     60.80344900d0
      s(  5) =     -1.24701561d0
      e(  6) =     25.27622600d0
      s(  6) =      2.60119316d0
      e(  7) =     11.27840900d0
      s(  7) =      8.70461044d0
      e(  8) =      5.35391500d0
      s(  8) =      2.25190285d0
      e(  9) =      2.67438100d0
      s(  9) =     -1.99771329d0
      e( 10) =      1.38771700d0
      s( 10) =      1.37290316d0
      e( 11) =      0.73723300d0
      s( 11) =      0.56969048d0
      e( 12) =      0.39479500d0
      s( 12) =      0.51291992d0
      e( 13) =     63.19533100d0
      p( 13) =      0.00385527d0
      e( 14) =     21.43252500d0
      p( 14) =     -0.00756290d0
      e( 15) =      7.91285210d0
      p( 15) =      0.01106432d0
      e( 16) =      3.11880430d0
      p( 16) =     -0.01633243d0
      e( 17) =      1.28119890d0
      p( 17) =      0.02140237d0
      e( 18) =      0.53383290d0
      p( 18) =     -0.01504615d0
      e( 19) =     89.76640050d0
      d( 19) =     -0.00249127d0
      e( 20) =     23.21569850d0
      d( 20) =     -0.00370477d0
      e( 21) =      6.69329640d0
      d( 21) =      0.00247795d0
      e( 22) =      2.07246860d0
      d( 22) =     -0.00304045d0
      e( 23) =      0.65792654d0
      d( 23) =     -0.00882790d0
      e( 24) =      1.39199999d0
      f( 24) =     -0.00094775d0
c
      return
      end
      subroutine ahlrichs_fit3(e,s,p,d,f,g,n)
c
c ----- ahlrichs coulomb fitting basis 
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*),g(*)
      nn = n-18
      go to (100,120,140,160,180,200,220,240,260,280,300,320),nn
c
c K:  (16s4p4d1f) / [6s2p2d1f]
c
  100 continue
c
      e(  1) =  10737.35380000d0
      s(  1) =      0.91363645d0
      e(  2) =   4120.32231000d0
      s(  2) =      1.53688032d0
      e(  3) =   1624.88943000d0
      s(  3) =      4.96541961d0
      e(  4) =    657.64744500d0
      s(  4) =     10.40760840d0
      e(  5) =    272.77349300d0
      s(  5) =     14.20192240d0
      e(  6) =    115.76005800d0
      s(  6) =      5.51466241d0
      e(  7) =     50.17832000d0
      s(  7) =     -2.45663541d0
      e(  8) =     22.17554700d0
      s(  8) =      6.63059665d0
      e(  9) =      9.97200500d0
      s(  9) =      8.90456311d0
      e( 10) =      4.55346300d0
      s( 10) =     -1.48384471d0
      e( 11) =      2.10673400d0
      s( 11) =      0.12845686d0
      e( 12) =      0.98538200d0
      s( 12) =      1.70664621d0
      e( 13) =      0.46484900d0
      s( 13) =      0.33597318d0
      e( 14) =      0.22064300d0
      s( 14) =      0.00017810d0
      e( 15) =      0.10511900d0
      s( 15) =      0.00575921d0
      e( 16) =      0.05014300d0
      s( 16) =      0.02745457d0
      e( 17) =      0.90193900d0
      p( 17) =     -0.00902224d0
      e( 18) =      0.31777700d0
      p( 18) =      0.01082090d0
      e( 19) =      0.13492700d0
      p( 19) =     -0.00037256d0
      e( 20) =      0.06149500d0
      p( 20) =     -0.01573674d0
      e( 21) =      2.88853200d0
      d( 21) =      0.00042812d0
      e( 22) =      0.86532800d0
      d( 22) =      0.00012732d0
      e( 23) =      0.26454000d0
      d( 23) =     -0.00138221d0
      e( 24) =      0.08142900d0
      d( 24) =      0.00334877d0
      e( 25) =      0.24897200d0
      f( 25) =     -0.00011496d0
c
      return
c
c Ca: (16s4p4d1f) / [6s2p2d1f]
c 
  120 continue
c
      e(  1) =  17876.40270000d0
      s(  1) =      0.60160865d0
      e(  2) =   6236.15617000d0
      s(  2) =      1.33992384d0
      e(  3) =   2269.45107000d0
      s(  3) =      4.53385725d0
      e(  4) =    860.30577100d0
      s(  4) =     10.62374110d0
      e(  5) =    339.12491100d0
      s(  5) =     16.23019100d0
      e(  6) =    138.72891400d0
      s(  6) =      7.40879611d0
      e(  7) =     58.75897600d0
      s(  7) =     -2.85661768d0
      e(  8) =     25.70110800d0
      s(  8) =      7.08295526d0
      e(  9) =     11.57553100d0
      s(  9) =     10.32823040d0
      e( 10) =      5.35125700d0
      s( 10) =     -1.93881247d0
      e( 11) =      2.53040700d0
      s( 11) =      0.11197143d0
      e( 12) =      1.21934800d0
      s( 12) =      2.16692993d0
      e( 13) =      0.59642200d0
      s( 13) =      0.34345164d0
      e( 14) =      0.29490000d0
      s( 14) =     -0.03749973d0
      e( 15) =      0.14677000d0
      s( 15) =      0.05509684d0
      e( 16) =      0.07320700d0
      s( 16) =      0.05894361d0
      e( 17) =      7.35849500d0
      p( 17) =      0.01255954d0
      e( 18) =      3.44117700d0
      p( 18) =     -0.04466907d0
      e( 19) =      1.94420000d0
      p( 19) =      0.07228314d0
      e( 20) =      1.18032600d0
      p( 20) =     -0.03489372d0
      e( 21) =      0.52226200d0
      d( 21) =     -0.00766335d0
      e( 22) =      0.20145100d0
      d( 22) =      0.01215499d0
      e( 23) =      0.09020200d0
      d( 23) =      0.00173920d0
      e( 24) =      0.04267700d0
      d( 24) =     -0.00045902d0
      e( 25) =      0.14784300d0
      f( 25) =      0.00384803d0
c
      return
c
c Sc: (16s4p4d3f4g) / [6s4p3d3f2g]
c 
  140 continue
c
      e(  1) =  12111.03180000d0
      s(  1) =      1.18999550d0
      e(  2) =   4731.60352000d0
      s(  2) =      1.84853680d0
      e(  3) =   1899.74196000d0
      s(  3) =      6.00531030d0
      e(  4) =    782.81285500d0
      s(  4) =     12.16096810d0
      e(  5) =    330.56840100d0
      s(  5) =     16.26738570d0
      e(  6) =    142.82775400d0
      s(  6) =      6.26954165d0
      e(  7) =     63.03256800d0
      s(  7) =     -3.04184975d0
      e(  8) =     28.36080400d0
      s(  8) =      8.00576151d0
      e(  9) =     12.98441200d0
      s(  9) =     11.16241200d0
      e( 10) =      6.03639100d0
      s( 10) =     -2.35325253d0
      e( 11) =      2.84342200d0
      s( 11) =      0.32575233d0
      e( 12) =      1.35404300d0
      s( 12) =      2.49181136d0
      e( 13) =      0.65033400d0
      s( 13) =      0.35879285d0
      e( 14) =      0.31427600d0
      s( 14) =      0.08484089d0
      e( 15) =      0.15244000d0
      s( 15) =      0.06805558d0
      e( 16) =      0.07403200d0
      s( 16) =      0.02487008d0
      e( 17) =      2.05792980d0
      p( 17) =      1.00000000d0
      e( 18) =      0.77110677d0
      p( 18) =      1.00000000d0
      e( 19) =      0.31254328d0
      p( 19) =      1.00000000d0
      e( 20) =      0.13022637d0
      p( 20) =      1.00000000d0
      e( 21) =      7.26661900d0
      d( 21) =      0.02280851d0
      e( 22) =      2.26096600d0
      d( 22) =      0.07170814d0
      e( 23) =      0.79220200d0
      d( 23) =      0.06431769d0
      e( 24) =      0.28975300d0
      d( 24) =      0.03321151d0
      e( 25) =      2.10745790d0
      f( 25) =      1.00000000d0
      e( 26) =      0.81056073d0
      f( 26) =      1.00000000d0
      e( 27) =      0.32422429d0
      f( 27) =      1.00000000d0
      e( 28) =      8.07289000d0
      g( 28) =      0.06450426d0
      e( 29) =      2.80936400d0
      g( 29) =      0.10999183d0
      e( 30) =      0.99531100d0
      g( 30) =      0.08258121d0
      e( 31) =      0.35475700d0
      g( 31) =      0.03372256d0
c
      return
c
c Ti: (16s4p4d3f4g) / [6s4p2d3f2g]
c 
  160 continue
c
      e(  1) =  11741.26180000d0
      s(  1) =      1.46681383d0
      e(  2) =   3896.11238000d0
      s(  2) =      3.62744316d0
      e(  3) =   1366.68455000d0
      s(  3) =     10.66612390d0
      e(  4) =    506.17401300d0
      s(  4) =     19.18945630d0
      e(  5) =    197.62067900d0
      s(  5) =     12.10329270d0
      e(  6) =     81.16794300d0
      s(  6) =     -3.34206544d0
      e(  7) =     34.98399200d0
      s(  7) =      6.94372569d0
      e(  8) =     15.77534700d0
      s(  8) =     13.55639800d0
      e(  9) =      7.41605500d0
      s(  9) =     -1.83867930d0
      e( 10) =      3.61970700d0
      s( 10) =     -0.65176411d0
      e( 11) =      1.82585700d0
      s( 11) =      2.99750579d0
      e( 12) =      0.94692200d0
      s( 12) =      0.86704175d0
      e( 13) =      0.50208200d0
      s( 13) =      0.11661173d0
      e( 14) =      0.27054100d0
      s( 14) =      0.00672510d0
      e( 15) =      0.14721300d0
      s( 15) =      0.08440778d0
      e( 16) =      0.08036900d0
      s( 16) =      0.04269773d0
      e( 17) =      2.31598962d0
      p( 17) =      1.00000000d0
      e( 18) =      0.86780187d0
      p( 18) =      1.00000000d0
      e( 19) =      0.35173552d0
      p( 19) =      1.00000000d0
      e( 20) =      0.14655646d0
      p( 20) =      1.00000000d0
      e( 21) =      6.23666600d0
      d( 21) =      0.05865617d0
      e( 22) =      2.36921300d0
      d( 22) =      0.13491083d0
      e( 23) =      0.91546100d0
      d( 23) =      0.08439268d0
      e( 24) =      0.35576600d0
      d( 24) =      0.01480684d0
      e( 25) =      2.74153601d0
      f( 25) =      1.00000000d0
      e( 26) =      1.05443693d0
      f( 26) =      1.00000000d0
      e( 27) =      0.42177477d0
      f( 27) =      1.00000000d0
      e( 28) =     10.57544300d0
      g( 28) =      0.08134739d0
      e( 29) =      3.63036300d0
      g( 29) =      0.14331238d0
      e( 30) =      1.36530400d0
      g( 30) =      0.08740949d0
      e( 31) =      0.53035200d0
      g( 31) =      0.01886622d0
c
      return
c
c V:  (16s4p4d3f4g) / [6s4p2d3f2g]
c 
  180 continue
c
      e(  1) =  12144.54840000d0
      s(  1) =      1.68958579d0
      e(  2) =   4090.54722000d0
      s(  2) =      3.96788447d0
      e(  3) =   1453.53223000d0
      s(  3) =     11.63643080d0
      e(  4) =    544.19969900d0
      s(  4) =     20.41942580d0
      e(  5) =    214.32301900d0
      s(  5) =     12.68021780d0
      e(  6) =     88.60643600d0
      s(  6) =     -3.74378480d0
      e(  7) =     38.35869400d0
      s(  7) =      7.89174859d0
      e(  8) =     17.33703800d0
      s(  8) =     14.62988600d0
      e(  9) =      8.15256700d0
      s(  9) =     -2.48613669d0
      e( 10) =      3.97283100d0
      s( 10) =     -0.33218908d0
      e( 11) =      1.99735500d0
      s( 11) =      3.37727442d0
      e( 12) =      1.03090700d0
      s( 12) =      0.96668964d0
      e( 13) =      0.54333700d0
      s( 13) =      0.14610881d0
      e( 14) =      0.29075500d0
      s( 14) =      0.02218525d0
      e( 15) =      0.15703600d0
      s( 15) =      0.08535787d0
      e( 16) =      0.08507800d0
      s( 16) =      0.04308577d0
      e( 17) =      2.53219895d0
      p( 17) =      1.00000000d0
      e( 18) =      0.94881555d0
      p( 18) =      1.00000000d0
      e( 19) =      0.38457180d0
      p( 19) =      1.00000000d0
      e( 20) =      0.16023825d0
      p( 20) =      1.00000000d0
      e( 21) =      6.90779900d0
      d( 21) =      0.06884186d0
      e( 22) =      2.58671150d0
      d( 22) =      0.13778187d0
      e( 23) =      1.01227500d0
      d( 23) =      0.07406157d0
      e( 24) =      0.40236900d0
      d( 24) =      0.01159695d0
      e( 25) =      3.28352762d0
      f( 25) =      1.00000000d0
      e( 26) =      1.26289524d0
      f( 26) =      1.00000000d0
      e( 27) =      0.50515810d0
      f( 27) =      1.00000000d0
      e( 28) =     12.31328300d0
      g( 28) =     -0.09575741d0
      e( 29) =      4.30026200d0
      g( 29) =     -0.16475087d0
      e( 30) =      1.64902000d0
      g( 30) =     -0.09851399d0
      e( 31) =      0.65370800d0
      g( 31) =     -0.02203652d0
c
      return
c
c Cr: (16s4p4d3f4g) / [6s4p2d3f2g]
c
  200 continue
c
      e(  1) =  12542.69720000d0
      s(  1) =      1.93966091d0
      e(  2) =   4376.16594000d0
      s(  2) =      4.07787870d0
      e(  3) =   1604.41232000d0
      s(  3) =     12.04028220d0
      e(  4) =    617.25050900d0
      s(  4) =     20.91471080d0
      e(  5) =    248.76503200d0
      s(  5) =     14.56672690d0
      e(  6) =    104.80967800d0
      s(  6) =     -3.48121298d0
      e(  7) =     46.05014500d0
      s(  7) =      6.20608733d0
      e(  8) =     21.03946300d0
      s(  8) =     16.78464630d0
      e(  9) =      9.96292800d0
      s(  9) =     -1.00088521d0
      e( 10) =      4.87169800d0
      s( 10) =     -1.62195460d0
      e( 11) =      2.44979600d0
      s( 11) =      3.98680666d0
      e( 12) =      1.26120300d0
      s( 12) =      1.33916495d0
      e( 13) =      0.66152600d0
      s( 13) =      0.42233673d0
      e( 14) =      0.35171700d0
      s( 14) =     -0.06953542d0
      e( 15) =      0.18854200d0
      s( 15) =      0.11045773d0
      e( 16) =      0.10134900d0
      s( 16) =      0.06065213d0
      e( 17) =      2.72072805d0
      p( 17) =      1.00000000d0
      e( 18) =      1.01945745d0
      p( 18) =      1.00000000d0
      e( 19) =      0.41320422d0
      p( 19) =      1.00000000d0
      e( 20) =      0.17216843d0
      p( 20) =      1.00000000d0
      e( 21) =      7.57893200d0
      d( 21) =      0.14894071d0
      e( 22) =      2.80421000d0
      d( 22) =      0.27056033d0
      e( 23) =      1.10908900d0
      d( 23) =      0.13217286d0
      e( 24) =      0.44897200d0
      d( 24) =      0.01719276d0
      e( 25) =      2.85945066d0
      f( 25) =      1.00000000d0
      e( 26) =      1.09978872d0
      f( 26) =      1.00000000d0
      e( 27) =      0.43991549d0
      f( 27) =      1.00000000d0
      e( 28) =     13.47992400d0
      g( 28) =      0.11440080d0
      e( 29) =      4.61635800d0
      g( 29) =      0.18749813d0
      e( 30) =      1.70714600d0
      g( 30) =      0.10129249d0
      e( 31) =      0.64856900d0
      g( 31) =      0.01461293d0
c
      return
c
c Mn: (16s4p4d3f4g) / [6s4p2d3f2g]
c 
  220 continue
c
      e(  1) =  12991.43000000d0
      s(  1) =      2.18695219d0
      e(  2) =   4434.44278000d0
      s(  2) =      4.84120886d0
      e(  3) =   1593.83118000d0
      s(  3) =     14.10583720d0
      e(  4) =    602.40907900d0
      s(  4) =     23.32476010d0
      e(  5) =    239.03319800d0
      s(  5) =     12.90389480d0
      e(  6) =     99.36791000d0
      s(  6) =     -4.81404845d0
      e(  7) =     43.16958700d0
      s(  7) =     11.59631670d0
      e(  8) =     19.54268700d0
      s(  8) =     15.52807890d0
      e(  9) =      9.18750300d0
      s(  9) =     -4.56822157d0
      e( 10) =      4.46837200d0
      s( 10) =      1.32779379d0
      e( 11) =      2.23859300d0
      s( 11) =      3.90641865d0
      e( 12) =      1.14980900d0
      s( 12) =      1.13362105d0
      e( 13) =      0.60240200d0
      s( 13) =      0.13304378d0
      e( 14) =      0.32018600d0
      s( 14) =      0.06667091d0
      e( 15) =      0.17167900d0
      s( 15) =      0.07742915d0
      e( 16) =      0.09232200d0
      s( 16) =      0.04330246d0
      e( 17) =      2.90306049d0
      p( 17) =      1.00000000d0
      e( 18) =      1.08777746d0
      p( 18) =      1.00000000d0
      e( 19) =      0.44089553d0
      p( 19) =      1.00000000d0
      e( 20) =      0.18370647d0
      p( 20) =      1.00000000d0
      e( 21) =     20.55459100d0
      d( 21) =     -0.01578675d0
      e( 22) =      6.38583200d0
      d( 22) =      0.00699240d0
      e( 23) =      2.28018900d0
      d( 23) =      0.01014757d0
      e( 24) =      0.85683700d0
      d( 24) =     -0.01610295d0
      e( 25) =      4.38661677d0
      f( 25) =      1.00000000d0
      e( 26) =      1.68716030d0
      f( 26) =      1.00000000d0
      e( 27) =      0.67486412d0
      f( 27) =      1.00000000d0
      e( 28) =     21.38616900d0
      g( 28) =      0.06636163d0
      e( 29) =      7.23747200d0
      g( 29) =      0.14384410d0
      e( 30) =      2.56798000d0
      g( 30) =      0.09252292d0
      e( 31) =      0.92612300d0
      g( 31) =      0.02357866d0
c
      return
c
c Fe: (16s4p4d3f4g) / [6s4p2d3f2g]
c 
  240 continue
c
      e(  1) =  13280.74690000d0
      s(  1) =      2.49415899d0
      e(  2) =   4555.93194000d0
      s(  2) =      5.39132690d0
      e(  3) =   1645.24364000d0
      s(  3) =     15.57680870d0
      e(  4) =    624.60170900d0
      s(  4) =     24.82965950d0
      e(  5) =    248.86609300d0
      s(  5) =     12.59900200d0
      e(  6) =    103.85349100d0
      s(  6) =     -5.27093265d0
      e(  7) =     45.27861300d0
      s(  7) =     13.84433260d0
      e(  8) =     20.56439300d0
      s(  8) =     15.49182960d0
      e(  9) =      9.69677400d0
      s(  9) =     -5.52028999d0
      e( 10) =      4.72897700d0
      s( 10) =      2.29526551d0
      e( 11) =      2.37510000d0
      s( 11) =      4.11618242d0
      e( 12) =      1.22274400d0
      s( 12) =      1.23245923d0
      e( 13) =      0.64199200d0
      s( 13) =      0.12922793d0
      e( 14) =      0.34192300d0
      s( 14) =      0.09483559d0
      e( 15) =      0.18369300d0
      s( 15) =      0.07609497d0
      e( 16) =      0.09897400d0
      s( 16) =      0.04546964d0
      e( 17) =      3.08055495d0
      p( 17) =      1.00000000d0
      e( 18) =      1.15428468d0
      p( 18) =      1.00000000d0
      e( 19) =      0.46785209d0
      p( 19) =      1.00000000d0
      e( 20) =      0.19493837d0
      p( 20) =      1.00000000d0
      e( 21) =     10.08270200d0
      d( 21) =      0.05113178d0
      e( 22) =      4.06361600d0
      d( 22) =      0.08387445d0
      e( 23) =      1.67243900d0
      d( 23) =      0.06042159d0
      e( 24) =      0.69321000d0
      d( 24) =      0.01515849d0
      e( 25) =      0.73048786d0
      f( 25) =      1.00000000d0
      e( 26) =      1.82621966d0
      f( 26) =      1.00000000d0
      e( 27) =      4.74817111d0
      f( 27) =      1.00000000d0
      e( 28) =     18.28354900d0
      g( 28) =      0.08353784d0
      e( 29) =      6.21035900d0
      g( 29) =      0.14250650d0
      e( 30) =      2.26352000d0
      g( 30) =      0.07957566d0
      e( 31) =      0.84558000d0
      g( 31) =      0.01880144d0
c
      return
c
c Co: (16s4p4d3f4g) / [6s4p3d3f2g]
c 
  260 continue
c
      e(  1) =  14890.77660000d0
      s(  1) =      2.52008475d0
      e(  2) =   5011.33863000d0
      s(  2) =      5.76161793d0
      e(  3) =   1782.88257000d0
      s(  3) =     16.60614600d0
      e(  4) =    669.72941400d0
      s(  4) =     26.64726680d0
      e(  5) =    265.21018400d0
      s(  5) =     12.93299700d0
      e(  6) =    110.48771900d0
      s(  6) =     -5.60012488d0
      e(  7) =     48.30408300d0
      s(  7) =     15.46435860d0
      e(  8) =     22.09487400d0
      s(  8) =     15.92900120d0
      e(  9) =     10.53649900d0
      s(  9) =     -6.15264331d0
      e( 10) =      5.21698300d0
      s( 10) =      2.65789949d0
      e( 11) =      2.66959900d0
      s( 11) =      4.46962773d0
      e( 12) =      1.40454700d0
      s( 12) =      1.50204712d0
      e( 13) =      0.75552100d0
      s( 13) =      0.21192488d0
      e( 14) =      0.41301100d0
      s( 14) =      0.11055689d0
      e( 15) =      0.22800000d0
      s( 15) =      0.10416493d0
      e( 16) =      0.12628000d0
      s( 16) =      0.05825387d0
      e( 17) =      3.23825416d0
      p( 17) =      1.00000000d0
      e( 18) =      1.21337461d0
      p( 18) =      1.00000000d0
      e( 19) =      0.49180229d0
      p( 19) =      1.00000000d0
      e( 20) =      0.20491762d0
      p( 20) =      1.00000000d0
      e( 21) =     10.70510200d0
      d( 21) =      0.07311294d0
      e( 22) =      4.05188000d0
      d( 22) =      0.12371548d0
      e( 23) =      1.54112500d0
      d( 23) =      0.05416795d0
      e( 24) =      0.58712000d0
      d( 24) =      0.00611389d0
      e( 25) =      0.80030020d0
      f( 25) =      1.00000000d0
      e( 26) =      2.00075049d0
      f( 26) =      1.00000000d0
      e( 27) =      5.20195127d0
      f( 27) =      1.00000000d0
      e( 28) =     20.35036100d0
      g( 28) =      0.14891968d0
      e( 29) =      6.89038800d0
      g( 29) =      0.24818368d0
      e( 30) =      2.51199000d0
      g( 30) =      0.13075126d0
      e( 31) =      0.93981600d0
      g( 31) =      0.02739146d0
c
      return
c
c Ni: (17s4p4d3f4g) / [7s4p2d3f2g]
c 
  280 continue
c
      e(  1) =  16946.51430000d0
      s(  1) =      2.53863983d0
      e(  2) =   6055.90923000d0
      s(  2) =      4.78297454d0
      e(  3) =   2273.44576000d0
      s(  3) =     14.67319080d0
      e(  4) =    895.60244800d0
      s(  4) =     25.10891970d0
      e(  5) =    369.71209300d0
      s(  5) =     20.15452090d0
      e(  6) =    159.65513500d0
      s(  6) =     -3.61460213d0
      e(  7) =     71.97400400d0
      s(  7) =      5.03670181d0
      e(  8) =     33.78971500d0
      s(  8) =     22.34920060d0
      e(  9) =     16.47345300d0
      s(  9) =      2.21702008d0
      e( 10) =      8.31342500d0
      s( 10) =     -4.87240374d0
      e( 11) =      4.32716600d0
      s( 11) =      6.37840791d0
      e( 12) =      2.31378600d0
      s( 12) =      2.70517445d0
      e( 13) =      1.26547100d0
      s( 13) =      1.63803373d0
      e( 14) =      0.70463900d0
      s( 14) =     -0.25608636d0
      e( 15) =      0.39749300d0
      s( 15) =      0.33711354d0
      e( 16) =      0.22600400d0
      s( 16) =     -0.03222894d0
      e( 17) =      0.12884000d0
      s( 17) =      0.09290945d0
      e( 18) =      3.37469360d0
      p( 18) =      1.00000000d0
      e( 19) =      1.26449850d0
      p( 19) =      1.00000000d0
      e( 20) =      0.51252371d0
      p( 20) =      1.00000000d0
      e( 21) =      0.21355155d0
      p( 21) =      1.00000000d0
      e( 22) =     11.63109000d0
      d( 22) =     -0.07610942d0
      e( 23) =      4.34717200d0
      d( 23) =     -0.11052369d0
      e( 24) =      1.65023900d0
      d( 24) =     -0.06007773d0
      e( 25) =      0.62974000d0
      d( 25) =     -0.00709715d0
      e( 26) =      0.87471844d0
      f( 26) =      1.00000000d0
      e( 27) =      2.18679609d0
      f( 27) =      1.00000000d0
      e( 28) =      5.68566983d0
      f( 28) =      1.00000000d0
      e( 29) =     22.51733700d0
      g( 29) =      0.14558805d0
      e( 30) =      7.62090900d0
      g( 30) =      0.24324429d0
      e( 31) =      2.70958300d0
      g( 31) =      0.12313508d0
      e( 32) =      0.97988400d0
      g( 32) =      0.02123531d0
c
      return
c
c Cu: (17s4p4d3f4g) / [7s4p2d3f2g]
c
  300 continue
c
      e(  1) =  18942.62600000d0
      s(  1) =      2.57075800d0
      e(  2) =   6692.60718000d0
      s(  2) =      4.93087859d0
      e(  3) =   2487.16950000d0
      s(  3) =     15.41595380d0
      e(  4) =    971.19106400d0
      s(  4) =     26.57468650d0
      e(  5) =    397.92066100d0
      s(  5) =     21.58791800d0
      e(  6) =    170.78102600d0
      s(  6) =     -4.14873549d0
      e(  7) =     76.61888700d0
      s(  7) =      6.07284943d0
      e(  8) =     35.84420500d0
      s(  8) =     23.74028270d0
      e(  9) =     17.43598000d0
      s(  9) =      1.29248122d0
      e( 10) =      8.79010800d0
      s( 10) =     -4.53339314d0
      e( 11) =      4.57569200d0
      s( 11) =      7.00887627d0
      e( 12) =      2.44935700d0
      s( 12) =      2.89311419d0
      e( 13) =      1.34224700d0
      s( 13) =      1.73720863d0
      e( 14) =      0.74938200d0
      s( 14) =     -0.11792364d0
      e( 15) =      0.42407900d0
      s( 15) =      0.16411050d0
      e( 16) =      0.24196400d0
      s( 16) =      0.05878702d0
      e( 17) =      0.13843600d0
      s( 17) =      0.08675038d0
      e( 18) =      3.43520112d0
      p( 18) =     73.01695690d0
      e( 19) =      1.28717068d0
      p( 19) =      9.72546331d0
      e( 20) =      0.52171315d0
      p( 20) =      1.75088628d0
      e( 21) =      0.21738048d0
      p( 21) =      0.02089881d0
      e( 22) =     12.65447700d0
      d( 22) =      0.08735417d0
      e( 23) =      4.69589900d0
      d( 23) =      0.12497440d0
      e( 24) =      1.76481900d0
      d( 24) =      0.06075469d0
      e( 25) =      0.66609000d0
      d( 25) =      0.00575386d0
      e( 26) =      5.05414019d0
      f( 26) =      0.31585905d0
      e( 27) =      1.94390007d0
      f( 27) =     -0.00155238d0
      e( 28) =      0.77756003d0
      f( 28) =      0.00424752d0
      e( 29) =     23.21669200d0
      g( 29) =      0.13014422d0
      e( 30) =      7.84863100d0
      g( 30) =      0.19765260d0
      e( 31) =      2.78019800d0
      g( 31) =      0.08969062d0
      e( 32) =      1.00077500d0
      g( 32) =      0.01223144d0
c
      return
c
c Zn: (17s4p4d3f4g) / [7s4p2d3f2g]
c 
  320 continue
c
      e(  1) =  18187.96560000d0
      s(  1) =      3.09780061d0
      e(  2) =   6792.96241000d0
      s(  2) =      4.97729695d0
      e(  3) =   2648.30444000d0
      s(  3) =     15.80769640d0
      e(  4) =   1076.40227000d0
      s(  4) =     26.37903670d0
      e(  5) =    455.44819800d0
      s(  5) =     23.60908450d0
      e(  6) =    200.26674600d0
      s(  6) =     -2.46728130d0
      e(  7) =     91.33008800d0
      s(  7) =      2.63929637d0
      e(  8) =     43.09840000d0
      s(  8) =     25.10448590d0
      e(  9) =     20.99096500d0
      s(  9) =      5.46836242d0
      e( 10) =     10.52165500d0
      s( 10) =     -6.64532010d0
      e( 11) =      5.41065700d0
      s( 11) =      7.46863023d0
      e( 12) =      2.84477300d0
      s( 12) =      3.88621636d0
      e( 13) =      1.52366000d0
      s( 13) =      2.04483011d0
      e( 14) =      0.82811000d0
      s( 14) =     -0.15064812d0
      e( 15) =      0.45487200d0
      s( 15) =      0.34323380d0
      e( 16) =      0.25146300d0
      s( 16) =     -0.01867062d0
      e( 17) =      0.13931300d0
      s( 17) =      0.09296290d0
      e( 18) =      3.74062853d0
      p( 18) =     -0.03036581d0
      e( 19) =      1.40161441d0
      p( 19) =      0.02530383d0
      e( 20) =      0.56809922d0
      p( 20) =     -0.00904182d0
      e( 21) =      0.23670801d0
      p( 21) =     -0.01141149d0
      e( 22) =     13.67786400d0
      d( 22) =     -0.00785324d0
      e( 23) =      5.04462600d0
      d( 23) =      0.02926524d0
      e( 24) =      1.87939900d0
      d( 24) =     -0.02283859d0
      e( 25) =      0.70244000d0
      d( 25) =      0.00709309d0
      e( 26) =      6.75682588d0
      f( 26) =      0.00254188d0
      e( 27) =      2.59877918d0
      f( 27) =      0.00053400d0
      e( 28) =      1.03951167d0
      f( 28) =     -0.00139947d0
      e( 29) =     23.91604700d0
      g( 29) =     -0.00292834d0
      e( 30) =      8.07635300d0
      g( 30) =     -0.00739891d0
      e( 31) =      2.85081300d0
      g( 31) =      0.00106217d0
      e( 32) =      1.02166600d0
      g( 32) =     -0.00193935d0
c
      return
      end
      subroutine ahlrichs_fit4(e,s,p,d,f,g,n)
c
c ----- ahlrichs coulomb fitting basis 
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*),g(*)
      nn = n-30
      go to (100,120,140,160,180,200),nn
c
c Ga: (16s4p4d1f)   / [6s4p2d1f]    
c
  100 continue
c
      e(  1) =  17947.03950000d0
      s(  1) =      3.57430337d0
      e(  2) =   7922.16536000d0
      s(  2) =      3.39372888d0
      e(  3) =   3518.77746000d0
      s(  3) =     11.91142200d0
      e(  4) =   1571.99720000d0
      s(  4) =     22.05004650d0
      e(  5) =    706.05046000d0
      s(  5) =     27.23975470d0
      e(  6) =    318.67834200d0
      s(  6) =     11.38825860d0
      e(  7) =    144.48013400d0
      s(  7) =     -7.60413132d0
      e(  8) =     65.76665900d0
      s(  8) =     20.98017210d0
      e(  9) =     30.04321200d0
      s(  9) =     18.86092330d0
      e( 10) =     13.76666100d0
      s( 10) =     -8.46428828d0
      e( 11) =      6.32483700d0
      s( 11) =      7.23092797d0
      e( 12) =      2.91208300d0
      s( 12) =      6.20958655d0
      e( 13) =      1.34303100d0
      s( 13) =      0.73875466d0
      e( 14) =      0.62013800d0
      s( 14) =      0.16607840d0
      e( 15) =      0.28655200d0
      s( 15) =      0.25908435d0
      e( 16) =      0.13244100d0
      s( 16) =      0.02963249d0
      e( 17) =      1.90022400d0
      p( 17) =      0.01149631d0
      e( 18) =      0.72099400d0
      p( 18) =     -0.01121227d0
      e( 19) =      0.29380300d0
      p( 19) =     -0.01881965d0
      e( 20) =      0.12275100d0
      p( 20) =     -0.01281854d0
      e( 21) =      4.45194400d0
      d( 21) =      0.02628010d0
      e( 22) =      1.56407300d0
      d( 22) =     -0.03286209d0
      e( 23) =      0.59838600d0
      d( 23) =      0.03314263d0
      e( 24) =      0.23592900d0
      d( 24) =      0.01802422d0
      e( 25) =      0.37858500d0
      f( 25) =      0.01023525d0
c
      return
c
c Ge: (16s4p5d1f1g) / [6s4p2d1f1g]  
c 
  120 continue
c
      e(  1) =  19411.27560000d0
      s(  1) =      3.70937134d0
      e(  2) =   8687.03880000d0
      s(  2) =      3.29548181d0
      e(  3) =   3898.10051000d0
      s(  3) =     11.96005610d0
      e(  4) =   1753.53519000d0
      s(  4) =     22.36698450d0
      e(  5) =    790.62781000d0
      s(  5) =     28.66815190d0
      e(  6) =    357.22447800d0
      s(  6) =     13.70766090d0
      e(  7) =    161.70993400d0
      s(  7) =     -8.31008593d0
      e(  8) =     73.32851700d0
      s(  8) =     20.81353050d0
      e(  9) =     33.30149500d0
      s(  9) =     21.47933890d0
      e( 10) =     15.14337500d0
      s( 10) =     -9.37342140d0
      e( 11) =      6.89386800d0
      s( 11) =      8.20864926d0
      e( 12) =      3.14121300d0
      s( 12) =      6.99384644d0
      e( 13) =      1.43231600d0
      s( 13) =      0.50763304d0
      e( 14) =      0.65343000d0
      s( 14) =      0.18920648d0
      e( 15) =      0.29818900d0
      s( 15) =      0.28802491d0
      e( 16) =      0.13609100d0
      s( 16) =      0.08079445d0
      e( 17) =      2.98062086d0
      p( 17) =      1.00000000d0
      e( 18) =      1.11683935d0
      p( 18) =      1.00000000d0
      e( 19) =      0.45267483d0
      p( 19) =      1.00000000d0
      e( 20) =      0.18861451d0
      p( 20) =      1.00000000d0
      e( 21) =      9.39473000d0
      d( 21) =     -0.02326026d0
      e( 22) =      3.21049900d0
      d( 22) =      0.00783386d0
      e( 23) =      1.18694500d0
      d( 23) =      0.00823280d0
      e( 24) =      0.46148800d0
      d( 24) =     -0.04737640d0
      e( 25) =      0.18257100d0
      d( 25) =     -0.01855919d0
      e( 26) =      0.44931500d0
      f( 26) =      1.00000000d0
      e( 27) =      0.49200000d0
      g( 27) =      1.00000000d0
c
      return
c
c As: (16s4p5d1f1g) / [6s4p2d1f1g]  
c 
  140 continue
c
      e(  1) =  29520.49350000d0
      s(  1) =      2.39486005d0
      e(  2) =  12150.79500000d0
      s(  2) =      3.42447383d0
      e(  3) =   5085.99345000d0
      s(  3) =     10.51023840d0
      e(  4) =   2162.75739000d0
      s(  4) =     22.65895320d0
      e(  5) =    933.35966000d0
      s(  5) =     31.59406580d0
      e(  6) =    408.34374900d0
      s(  6) =     17.34383880d0
      e(  7) =    180.90225000d0
      s(  7) =     -8.78626939d0
      e(  8) =     81.05669800d0
      s(  8) =     20.56939130d0
      e(  9) =     36.68833600d0
      s(  9) =     24.16330340d0
      e( 10) =     16.75373600d0
      s( 10) =    -10.34298930d0
      e( 11) =      7.70859500d0
      s( 11) =      8.53324542d0
      e( 12) =      3.56895400d0
      s( 12) =      8.25146161d0
      e( 13) =      1.66042700d0
      s( 13) =      0.27797924d0
      e( 14) =      0.77520200d0
      s( 14) =      0.21885509d0
      e( 15) =      0.36267800d0
      s( 15) =      0.45559282d0
      e( 16) =      0.16979800d0
      s( 16) =      0.11565690d0
      e( 17) =      3.75204767d0
      p( 17) =      1.00000000d0
      e( 18) =      1.40589316d0
      p( 18) =      1.00000000d0
      e( 19) =      0.56983348d0
      p( 19) =      1.00000000d0
      e( 20) =      0.23743062d0
      p( 20) =      1.00000000d0
      e( 21) =     14.40813800d0
      d( 21) =      0.00537875d0
      e( 22) =      4.75934700d0
      d( 22) =      0.00099258d0
      e( 23) =      1.69657350d0
      d( 23) =     -0.00450645d0
      e( 24) =      0.63516400d0
      d( 24) =      0.01198248d0
      e( 25) =      0.24197950d0
      d( 25) =      0.01184794d0
      e( 26) =      0.53515982d0
      f( 26) =      1.00000000d0
      e( 27) =      0.58600000d0
      g( 27) =      1.00000000d0
c
      return
c
c Se: (16s4p5d1f1g) / [6s4p2d1f1g]  
c
  160 continue
c
      e(  1) =  28424.07940000d0
      s(  1) =      2.90097726d0
      e(  2) =  11965.44300000d0
      s(  2) =      3.55041308d0
      e(  3) =   5109.12776000d0
      s(  3) =     11.67349710d0
      e(  4) =   2210.86522000d0
      s(  4) =     23.72229470d0
      e(  5) =    968.68087300d0
      s(  5) =     32.74077850d0
      e(  6) =    429.33047100d0
      s(  6) =     17.28584060d0
      e(  7) =    192.29577600d0
      s(  7) =     -9.07279130d0
      e(  8) =     86.95112300d0
      s(  8) =     21.29404260d0
      e(  9) =     39.65110900d0
      s(  9) =     25.92002430d0
      e( 10) =     18.21568800d0
      s( 10) =    -11.40284310d0
      e( 11) =      8.42113600d0
      s( 11) =      9.35370129d0
      e( 12) =      3.91332900d0
      s( 12) =      9.27835933d0
      e( 13) =      1.82591500d0
      s( 13) =     -0.11953816d0
      e( 14) =      0.85442700d0
      s( 14) =      0.36555754d0
      e( 15) =      0.40052300d0
      s( 15) =      0.57919518d0
      e( 16) =      0.18786000d0
      s( 16) =      0.13324768d0
      e( 17) =      4.45082971d0
      p( 17) =      1.00000000d0
      e( 18) =      1.66772696d0
      p( 18) =      1.00000000d0
      e( 19) =      0.67595937d0
      p( 19) =      1.00000000d0
      e( 20) =      0.28164974d0
      p( 20) =      1.00000000d0
      e( 21) =     19.42154600d0
      d( 21) =      0.01122967d0
      e( 22) =      6.30819500d0
      d( 22) =      0.02619541d0
      e( 23) =      2.20620200d0
      d( 23) =     -0.03894025d0
      e( 24) =      0.80884000d0
      d( 24) =      0.06357082d0
      e( 25) =      0.30138800d0
      d( 25) =      0.03421231d0
      e( 26) =      0.61735160d0
      f( 26) =      1.00000000d0
      e( 27) =      0.67600000d0
      g( 27) =      1.00000000d0
c
      return
c
c Br: (16s4p5d1f1g) / [6s4p2d1f1g]  
c 
  180 continue
c
      e(  1) =  30913.13860000d0
      s(  1) =      2.92400253d0
      e(  2) =  10271.90370000d0
      s(  2) =      7.05924872d0
      e(  3) =   3613.36292000d0
      s(  3) =     21.30320000d0
      e(  4) =   1344.06976000d0
      s(  4) =     38.70370750d0
      e(  5) =    527.84275700d0
      s(  5) =     25.77249310d0
      e(  6) =    218.41776900d0
      s(  6) =     -8.80496954d0
      e(  7) =     94.99162700d0
      s(  7) =     20.50238100d0
      e(  8) =     43.28901600d0
      s(  8) =     29.27610360d0
      e(  9) =     20.59684200d0
      s(  9) =    -12.71277140d0
      e( 10) =     10.18912700d0
      s( 10) =      7.14337376d0
      e( 11) =      5.21576200d0
      s( 11) =     11.04171600d0
      e( 12) =      2.74810400d0
      s( 12) =      2.44407981d0
      e( 13) =      1.48167900d0
      s( 13) =     -1.22802368d0
      e( 14) =      0.81239200d0
      s( 14) =      1.12822095d0
      e( 15) =      0.44999900d0
      s( 15) =      0.34099040d0
      e( 16) =      0.25011800d0
      s( 16) =      0.28184906d0
      e( 17) =      5.24719287d0
      p( 17) =      1.00000000d0
      e( 18) =      1.96612443d0
      p( 18) =      1.00000000d0
      e( 19) =      0.79690517d0
      p( 19) =      1.00000000d0
      e( 20) =      0.33204382d0
      p( 20) =      1.00000000d0
      e( 21) =      7.98887400d0
      d( 21) =     -0.05512916d0
      e( 22) =      3.34200800d0
      d( 22) =      0.05788013d0
      e( 23) =      1.45718400d0
      d( 23) =     -0.02782685d0
      e( 24) =      0.65190000d0
      d( 24) =     -0.06490489d0
      e( 25) =      0.29419300d0
      d( 25) =     -0.01911432d0
      e( 26) =      0.71050228d0
      f( 26) =      1.00000000d0
      e( 27) =      0.77800000d0
      g( 27) =      1.00000000d0
c
      return
c
c Kr: (17s4p5d1f1g) / [7s4p2d1f1g]  
c
  200 continue
c
      e(  1) =  28150.84840000d0
      s(  1) =      3.80324890d0
      e(  2) =  12247.09120000d0
      s(  2) =      3.69596396d0
      e(  3) =   5379.15537000d0
      s(  3) =     13.62470020d0
      e(  4) =   2383.88443000d0
      s(  4) =     25.64191440d0
      e(  5) =   1065.34302000d0
      s(  5) =     35.24840910d0
      e(  6) =    479.80337400d0
      s(  6) =     18.02404200d0
      e(  7) =    217.63898400d0
      s(  7) =     -9.84020936d0
      e(  8) =     99.36504600d0
      s(  8) =     23.14005850d0
      e(  9) =     45.63232300d0
      s(  9) =     29.37922250d0
      e( 10) =     21.06526200d0
      s( 10) =    -13.98908200d0
      e( 11) =      9.76844300d0
      s( 11) =     11.99954440d0
      e( 12) =      4.54729100d0
      s( 12) =     11.03515140d0
      e( 13) =      2.12349100d0
      s( 13) =     -1.50376854d0
      e( 14) =      0.99407000d0
      s( 14) =      1.07556113d0
      e( 15) =      0.46617400d0
      s( 15) =      0.79834999d0
      e( 16) =      0.21884700d0
      s( 16) =      0.15068445d0
      e( 17) =      0.10277400d0
      s( 17) =     -0.00633131d0
      e( 18) =      6.11829760d0
      p( 18) =     -0.00983149d0
      e( 19) =      2.29252760d0
      p( 19) =      0.02119416d0
      e( 20) =      0.92920210d0
      p( 20) =     -0.02917046d0
      e( 21) =      0.38716750d0
      p( 21) =      0.01858504d0
      e( 22) =     64.08916900d0
      d( 22) =      0.00115365d0
      e( 23) =     16.57496300d0
      d( 23) =     -0.00222969d0
      e( 24) =      4.77871230d0
      d( 24) =     -0.00006131d0
      e( 25) =      1.47964920d0
      d( 25) =      0.00082129d0
      e( 26) =      0.46972993d0
      d( 26) =     -0.00798075d0
      e( 27) =      0.80900000d0
      f( 27) =      0.00292522d0
      e( 28) =      0.88600000d0
      g( 28) =      0.00273936d0
c
      return
      end
      subroutine ahlrichs_fit5(e,s,p,d,f,g,n)
c
c ----- ahlrichs coulomb fitting basis [rb-cd]
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*),g(*)
      nn = n-36
      go to (100,120,140,160,180,200,220,240,260,280,300,320),nn
c
c Rb: (8s4p4d)      / [5s2p2d]
c
  100 continue
c
      e(  1) =     10.88721500d0
      s(  1) =     -0.15502245d0
      e(  2) =      4.96476100d0
      s(  2) =      1.13800526d0
      e(  3) =      2.30007300d0
      s(  3) =     -3.11889651d0
      e(  4) =      1.07964500d0
      s(  4) =      2.01338928d0
      e(  5) =      0.51203800d0
      s(  5) =      1.26605968d0
      e(  6) =      0.24465500d0
      s(  6) =      0.03949840d0
      e(  7) =      0.11742400d0
      s(  7) =      0.00608859d0
      e(  8) =      0.05644300d0
      s(  8) =      0.04913786d0
      e(  9) =      0.55527200d0
      p(  9) =     -0.01206752d0
      e( 10) =      0.26911800d0
      p( 10) =      0.01517249d0
      e( 11) =      0.13101800d0
      p( 11) =      0.00026597d0
      e( 12) =      0.06388000d0
      p( 12) =     -0.01237421d0
      e( 13) =      0.71644000d0
      d( 13) =     -0.00066312d0
      e( 14) =      0.35493700d0
      d( 14) =      0.00061813d0
      e( 15) =      0.17882000d0
      d( 15) =     -0.00258233d0
      e( 16) =      0.09060200d0
      d( 16) =      0.00382908d0
c
      return
c
c Sr: (9s3p3d2f1g)  / [6s3p3d2f1g]
c 
  120 continue
c
      e(  1) =     10.83291800d0
      s(  1) =     -0.17835490d0
      e(  2) =      5.30735600d0
      s(  2) =      1.25330950d0
      e(  3) =      2.67182100d0
      s(  3) =     -2.97510301d0
      e(  4) =      1.37712900d0
      s(  4) =      1.33916387d0
      e(  5) =      0.72393900d0
      s(  5) =      1.39362421d0
      e(  6) =      0.38655000d0
      s(  6) =      0.07821836d0
      e(  7) =      0.20874400d0
      s(  7) =      0.03275285d0
      e(  8) =      0.11350000d0
      s(  8) =      0.03654871d0
      e(  9) =      0.06185400d0
      s(  9) =      0.02334212d0
      e( 10) =      0.40474300d0
      p( 10) =     -0.04003698d0
      e( 11) =      0.20063900d0
      p( 11) =      0.02514615d0
      e( 12) =      0.09947100d0
      p( 12) =     -0.01540285d0
      e( 13) =      2.58535000d0
      d( 13) =     -0.00363898d0
      e( 14) =      1.31445900d0
      d( 14) =      0.00948669d0
      e( 15) =      0.67532800d0
      d( 15) =     -0.00285307d0
      e( 16) =      2.98165600d0
      f( 16) =      0.00019646d0
      e( 17) =      1.07396400d0
      f( 17) =     -0.01583147d0
      e( 18) =      0.16663500d0
      g( 18) =      1.00000000d0
c
      return
c
c  Y:  (8s4p4d3f4g)  / [6s4p2d3f2g]
c 
  140 continue
c
c
      return
c
c Zr: (10s4p4d3f4g) / [6s4p2d3f2g]
c 
  160 continue
c
c
      return
c
c Nb: (8s4p4d3f4g)  / [6s4p3d3f2g]
c 
  180 continue
c
c
      return
c
c Mo: (8s4p4d3f4g)  / [7s4p3d3f2g]
c
  200 continue
c
c
      return
c
c Tc: (8s4p4d3f4g)  / [6s4p3d3f2g]
c 
  220 continue
c
c
      return
c
c Ru: (9s4p4d3f4g)  / [7s4p3d3f2g]
c 
  240 continue
c
c
      return
c
c Rh: (9s4p4d3f4g)  / [7s4p4d3f2g]
c 
  260 continue
c
c
      return
c
c Pd: (9s4p4d3f4g)  / [7s4p2d3f2g]
c 
  280 continue
c
c
      return
c
c Ag: (9s4p4d3f4g)  / [7s4p3d3f2g]
c
  300 continue
c
c
      return
c
c Cd: (9s4p4d3f4g)  / [7s4p2d3f2g]
c 
  320 continue
c
c
      return
      end
      subroutine ahlrichs_fit6(e,s,p,d,f,g,n)
c
c ----- ahlrichs coulomb fitting basis [In-Cd]
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*),f(*),g(*)
      nn = n-48
      go to (100,120,140,160,180,200),nn
c
c In: (5s3p3d1f1g)  / [3s3p2d1f1g]
c
  100 continue
      call caserr2('ahlrichs coulomb fitting basis not implemented')
c
c
      return
c
c Sn: (5s3p3d1f1g)  / [4s3p3d1f1g]
c 
  120 continue
c
      call caserr2('ahlrichs coulomb fitting basis not implemented')
c
      return
c
c Sb: (5s3p3d1f1g)  / [4s3p3d1f1g]
c 
  140 continue
c
      call caserr2('ahlrichs coulomb fitting basis not implemented')
c
      return
c
c Te: (5s3p3d1f1g)  / [4s3p3d1f1g] 
c
  160 continue
c
      call caserr2('ahlrichs coulomb fitting basis not implemented')
c
      return
c
c I:  (5s3p3d1f1g)  / [3s3p2d1f1g] 
c 
  180 continue
c
      call caserr2('ahlrichs coulomb fitting basis not implemented')
c
      return
c
c Xe: (8s3p3d1f1g)  / [5s3p2d1f1g] 
c
  200 continue
c
      call caserr2('ahlrichs coulomb fitting basis not implemented')
c
      return
      end
      subroutine dftorbs(ztype,csinp,cpinp,cdinp,
     + nucz,intyp,nangm,nbfs,minf,maxf,loc,ngauss,
     + ns,ierr1,ierr2,nat)
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
c
      dimension csinp(*),cpinp(*),cdinp(*),
     +  intyp(*),nangm(*),nbfs(*),minf(*),maxf(*),ns(*)
      common/blkin/eex(50),ccs(50),ccp(50),ccd(50)
INCLUDE(common/iofile)
      common/junk/ptr(18192),iptr(4,maxat),iptrs(2,mxshel),
     *ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     *cf(mxprim),cg(mxprim),
     +kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     +kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell
INCLUDE(common/restar)
c
      data pt5,pt75/
     + 0.5d+00,0.75d+00/
      data pi32,tm10/5.56832799683170d+00,1.0d-10/
c
************************************************************
c     DGauss DZVP Polarized DFT Orbitals Basis Sets
c     N. Godbout, D. R. Salahub, J. Andzelm,
c     and E. Wimmer, Can. J. Chem. 70, 560
c     Other basis sets were taken from the DGauss basis set library.
************************************************************
c Elements     Contraction             
c  H     : ( 5s)        -> [2s]       
c  He    : ( 6s)        -> [2s]       
c Li - Be: ( 9s, 1p,1d) -> [3s,1p,1d] 
c  B - Ne: ( 9s, 5p,1d) -> [3s,2p,1d] 
c Na - Mg: (12s, 6p,1d) -> [4s,3p,1d]
c Al - Ar: (12s, 8p,1d) -> [4s,3p,1d]
c  K - Ca: (15s, 9p,1d) -> [5s,4p,1d]
c Sc - Zn: (15s, 9p,5d) -> [5s,3p,2d]
c Ga - Kr: (15s,11p,5d) -> [5s,4p,2d]
c Rb     : (18s,12p,6d) -> [6s,5p,2d]
c Sr - Cd: (18s,12p,9d) -> [6s,5p,3d]
c In - Xe: (18s,14p,9d) -> [6s,5p,3d]
************************************************************
c     DGauss DZVP2 Polarized DFT Orbitals Basis Sets
************************************************************
c Elements     Contraction         
c  H     : ( 5s,1p)    -> [2s,1p]
c  He    : ( 6s,1p)    -> [2s,1p]
c Li - Be: (10s,1p,1d) -> [3s,1p,1d]
c  B - F : (10s,6p,1d) -> [3s,2p,1d]
c Al - Ar: (13s,9p,1d) -> [4s,3p,1d]
c Sc - Zn: (15s,9p,5d) -> [5s,4p,2d]
************************************************************
c     DGauss TZVP Polarized DFT Orbitals Basis Sets
************************************************************
c Elements            Contraction 
c   H     : ( 5s,1p)    -> [3s,1p]
c   C - F : (10s,6p,1d) -> [4s,3p,1d]
c  Al - Ar: (13s,9p,1d) -> [5s,4p,1d]
************************************************************
c
      ng = -2**20
      igauss = ng
      ityp = ng
      ierr1=0
      ierr2=0
      odone = .false.
c
c     decide whether dzvp, dzvp2 or tzvp
c
      odzvp = .false.
      odzvp2 = .false.
      otzvp = .false.
      if(ztype.eq.'dzvp') then
        odzvp = .true.
      else if(ztype.eq.'tzvp') then
        otzvp = .true.
      else if(ztype.eq.'dzvp2') then
        odzvp2 = .true.
      else
c     default to dzvp
        odzvp = .true.
      endif
_IFN1(civu)      call vclr(eex,1,200)
_IFN(civu)      call szero(eex,200)
c
c     ----- hydrogen to helium -----
c
      if (nucz .le. 2) then
         if (odzvp) then
          call dftdzvp_0(eex,ccs,ccp,nucz)
         else if (odzvp2) then
          call dftdzvp2_0(eex,ccs,ccp,nucz)
         else 
          call dfttzvp_0(eex,ccs,ccp,nucz)
         endif
c
c     ----- lithium to neon -----
c
      else if (nucz .le. 10) then
         if (odzvp) then
          call dftdzvp_1(eex,ccs,ccp,ccd,nucz)
         else if (odzvp2) then
          call dftdzvp2_1(eex,ccs,ccp,ccd,nucz)
         else 
          call dfttzvp_1(eex,ccs,ccp,ccd,nucz)
         endif
c
c     ----- sodium to argon -----
c
      else if (nucz .le. 18) then
         if (odzvp) then
          call dftdzvp_2(eex,ccs,ccp,ccd,nucz)
         else if (odzvp2) then
          call dftdzvp2_2(eex,ccs,ccp,ccd,nucz)
         else 
          call dfttzvp_2(eex,ccs,ccp,ccd,nucz)
         endif
c
c     ----- potassium to zinc -----
c
      else if(nucz.le.30) then
         if (odzvp) then
          call dftdzvp_3(eex,ccs,ccp,ccd,nucz)
         else if (odzvp2) then
          call dftdzvp2_3(eex,ccs,ccp,ccd,nucz)
         else 
          go to 3000
         endif
c
c     ----- gallium to krypton -----
c
      else if(nucz.le.36) then
         if (odzvp) then
          call dftdzvp_4(eex,ccs,ccp,ccd,nucz)
         else if (odzvp2) then
          go to 2000
         else 
          go to 3000
         endif
c
c     ----- rubidium to cadmium
c
      else if (nucz .le. 48) then
         if (odzvp) then
          call dftdzvp_5(eex,ccs,ccp,ccd,nucz)
         else if (odzvp2) then
          go to 2000
         else 
          go to 3000
         endif
c
c     ----- indium to xenon
c
       else if (nucz .le. 54) then
         if (odzvp) then
          call dftdzvp_6(eex,ccs,ccp,ccd,nucz)
         else if (odzvp2) then
          go to 2000
         else 
          go to 3000
         endif
c
c
c     ----- past xenon does not exist
c
      else
        call caserr2(
     +   'attempting to site DFT function on invalid centre')
      endif
c
c
c     ----- loop over each shell -----
c
      ipass = 0
  210 ipass = ipass+1
      if (odzvp) then
       call dftdzvp_sh(nucz,ipass,ityp,igauss,ng,odone)
      elseif (odzvp2) then
       call dftdzvp2_sh(nucz,ipass,ityp,igauss,ng,odone)
      else
       call dfttzvp_sh(nucz,ipass,ityp,igauss,ng,odone)
      endif
        
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
      do 440 i = 1,igauss
         k = k1+i-1
         ex(k) = eex(ng+i)
         if(ityp.eq.16) then
          csinp(k) = ccs(ng+i)
         else if(ityp.eq.17) then
          cpinp(k) = ccp(ng+i)
         else if(ityp.eq.18) then
          cdinp(k) = ccd(ng+i)
         else
          call caserr2('invalid shell type')
         endif
         cs(k) = 0.0d+00
         cp(k) = 0.0d+00
         cd(k) = 0.0d+00
         cf(k) = 0.0d+00
         if(ityp.eq.16) then
          cs(k) = csinp(k)
         else if(ityp.eq.17) then
          cp(k) = cpinp(k)
         else 
          cd(k) = cdinp(k)
         endif
  440 continue
c
c     ----- always unnormalize primitives -----
c
      do 460 k = k1,k2
         ee = ex(k)+ex(k)
         facs = pi32/(ee*sqrt(ee))
         facp = pt5*facs/ee
         facd = pt75*facs/(ee*ee)
         if(ityp.eq.16) then
          cs(k) = cs(k)/sqrt(facs)
         else if(ityp.eq.17) then
          cp(k) = cp(k)/sqrt(facp)
         else 
          cd(k) = cd(k)/sqrt(facd)
         endif
  460 continue
c
c     ----- if(normf.eq.0) normalize basis functions -----
c
      if (normf .eq. 1) go to 210
      facs = 0.0d+00
      facp = 0.0d+00
      facd = 0.0d+00
      do 510 ig = k1,k2
         do 500 jg = k1,ig
            ee = ex(ig)+ex(jg)
            fac = ee*sqrt(ee)
            dums = cs(ig)*cs(jg)/fac
            dump = pt5*cp(ig)*cp(jg)/(ee*fac)
            dumd = pt75*cd(ig)*cd(jg)/(ee*ee*fac)
            if (ig .eq. jg) go to 480
               dums = dums+dums
               dump = dump+dump
               dumd = dumd+dumd
  480       continue
            facs = facs+dums
            facp = facp+dump
            facd = facd+dumd
  500    continue
  510 continue
c
      fac=0.0d+00
      if(ityp.eq.16.and. facs.gt.tm10) then
        fac=1.0d+00/sqrt(facs*pi32)
      else if(ityp.eq.17.and. facp.gt.tm10) then
        fac=1.0d+00/sqrt(facp*pi32)
      else if(ityp.eq.18.and. facd.gt.tm10) then
        fac=1.0d+00/sqrt(facd*pi32)
      else
      endif
c
      do 550 ig = k1,k2
         if(ityp.eq.16) then
          cs(ig) = fac*cs(ig)
         else if(ityp.eq.17) then
          cp(ig) = fac*cp(ig)
         else 
          cd(ig) = fac*cd(ig)
         endif
  550 continue
      go to 210
c
  220 continue
      return
 2000 call caserr2(
     + 'attempting to site DFT DZVP2 function on invalid centre')
 3000 call caserr2(
     + 'attempting to site DFT TZVP function on invalid centre')
      return
      end
      subroutine dftdzvp_sh(nucz,ipass,itype,igauss,ng,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension igau(14,13), itypes(14,13)
      dimension kind(13)
      data kind/2, 2, 5, 6, 8, 8, 10, 11, 10, 11, 13, 14, 14/
c
      data igau /
c  H
     + 4,1,0,0,0,0,0,0,0,0,0,0,0,0,
c  He
     + 5,1,0,0,0,0,0,0,0,0,0,0,0,0,
c  Li-Be
     + 6,2,1,1,1,0,0,0,0,0,0,0,0,0,
c  B-Ne
     + 6,2,1,4,1,1,0,0,0,0,0,0,0,0,
c  Na-Mg
     + 6,3,2,1,4,1,1,1,0,0,0,0,0,0,
c  AL-Ar
     + 6,3,2,1,5,2,1,1,0,0,0,0,0,0,
c  K
     + 6,3,3,2,1,5,2,1,1,1,0,0,0,0,
c  Ca
     + 6,3,3,2,1,5,2,1,1,4,1,0,0,0,
c  Sc-Zn
     + 6,3,3,2,1,5,3,1,4,1,0,0,0,0,
c  Ga-Kr
     + 6,3,3,2,1,5,3,2,1,4,1,0,0,0,
c  Rb
     + 6,3,3,3,2,1,5,3,2,1,1,5,1,0,
c  Sr-Cd
     + 6,3,3,3,2,1,5,3,2,1,1,5,3,1,
c  In-Xe
     + 6,3,3,3,2,1,5,3,3,2,1,5,3,1 /

      data itypes /
c  H
     + 1,1,0,0,0,0,0,0,0,0,0,0,0,0,
c  He
     + 1,1,0,0,0,0,0,0,0,0,0,0,0,0,
c  Li-Be
     + 1,1,1,2,3,0,0,0,0,0,0,0,0,0,
c  B-Ne
     + 1,1,1,2,2,3,0,0,0,0,0,0,0,0,
c  Na-Mg
     + 1,1,1,1,2,2,2,3,0,0,0,0,0,0,
c  Al-Ar
     + 1,1,1,1,2,2,2,3,0,0,0,0,0,0,
c  K
     + 1,1,1,1,1,2,2,2,2,3,0,0,0,0,
c  Ca
     + 1,1,1,1,1,2,2,2,2,3,3,0,0,0,
c  Sc-Zn
     + 1,1,1,1,1,2,2,2,3,3,0,0,0,0,
c  Ga-Kr
     + 1,1,1,1,1,2,2,2,2,3,3,0,0,0,
c  Rb
     + 1,1,1,1,1,1,2,2,2,2,2,3,3,0,
c  Sr-Cd
     + 1,1,1,1,1,1,2,2,2,2,2,3,3,3,
c  In-Xe
     + 1,1,1,1,1,1,2,2,2,2,2,3,3,3/
c
c     set values for the current dzvp_dft   shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3 for s,p,d shell
c            ng     = offset in e,cs,cp,cd arrays for current shell
c
      ind=1
      if(nucz.gt. 1) ind=2
      if(nucz.gt. 2) ind=3
      if(nucz.gt. 4) ind=4
      if(nucz.gt.10) ind=5
      if(nucz.gt.12) ind=6
      if(nucz.gt.18) ind=7
      if(nucz.gt.19) ind=8
      if(nucz.gt.20) ind=9
      if(nucz.gt.30) ind=10
      if(nucz.gt.36) ind=11
      if(nucz.gt.37) ind=12
      if(nucz.gt.48) ind=13
      if(nucz.gt.54) then
         call caserr2('dzvp_dft basis sets only extend to xeon')
      end if
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if (odone) go to 100
c
       igauss = igau(ipass,ind)
       ng =0
       do loop = 1, ipass-1
        ng = ng + igau(loop,ind)
       enddo
       ityp = itypes(ipass,ind)
c
100   itype = ityp + 15
      return
      end
      subroutine dftdzvp_0(e,s,p,n)
c
c     ----- dft_dzvp basis 
c     ----- hydrogen (5s/2s) and helium (6s)/(2s) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*)
      go to (100,120),n
c
c     ----- h  -----
c
c h     (5s) / [2s]
c
  100 continue
c
      e(  1) =     50.99917800d0
      s(  1) =      0.00966050d0
      e(  2) =      7.48321810d0
      s(  2) =      0.07372890d0
      e(  3) =      1.77746760d0
      s(  3) =      0.29585810d0
      e(  4) =      0.51932950d0
      s(  4) =      0.71590530d0
      e(  5) =      0.15411000d0
      s(  5) =      1.00000000d0
c
      go to 200
c
c     ----- he  -----
c
c he    (6s) / [4s] 
c
  120 continue
c
      e(  1) =    221.38803000d0
      s(  1) =      0.00274910d0
      e(  2) =     33.26196600d0
      s(  2) =      0.02086580d0
      e(  3) =      7.56165490d0
      s(  3) =      0.09705880d0
      e(  4) =      2.08559900d0
      s(  4) =      0.28072890d0
      e(  5) =      0.61433920d0
      s(  5) =      0.47422180d0
      e(  6) =      0.18292120d0
      s(  6) =      1.00000000d0
c
  200 return
c
      end
      subroutine dftdzvp_1(e,s,p,d,n)
c
c  ----- dft_dzvp fitting basis [Li-Ne]
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-2
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- li -----
c
c li    (9s,1p,1d) -> [3s,1p,1d]
c
  100 continue
c
      e(  1) =    605.70539000d0
      s(  1) =     -0.00228700d0
      e(  2) =     90.86090700d0
      s(  2) =     -0.01745280d0
      e(  3) =     20.63127100d0
      s(  3) =     -0.08369700d0
      e(  4) =      5.73844620d0
      s(  4) =     -0.25974850d0
      e(  5) =      1.75152610d0
      s(  5) =     -0.47946130d0
      e(  6) =      0.54639010d0
      s(  6) =     -0.32330060d0
      e(  7) =      0.84272330d0
      s(  7) =      0.07486090d0
      e(  8) =      0.06744830d0
      s(  8) =     -0.65464900d0
      e(  9) =      0.02537330d0
      s(  9) =      1.00000000d0
      e( 10) =      0.07730000d0
      p( 10) =      1.00000000d0
      e( 11) =      0.12200000d0
      d( 11) =      1.00000000d0
c
      go to 1000
c
c     ----- be -----
c
c be    (9s,1p,1d) -> [3s,1p,1d]
c
  120 continue
c
      e(  1) =   1203.41410000d0
      s(  1) =      0.00205040d0
      e(  2) =    180.24571000d0
      s(  2) =      0.01570780d0
      e(  3) =     40.80005400d0
      s(  3) =      0.07683150d0
      e(  4) =     11.33653800d0
      s(  4) =      0.24802520d0
      e(  5) =      3.50348300d0
      s(  5) =      0.47984520d0
      e(  6) =      1.10912160d0
      s(  6) =      0.33714590d0
      e(  7) =      1.95934200d0
      s(  7) =     -0.07504550d0
      e(  8) =      0.16520130d0
      s(  8) =      0.58135570d0
      e(  9) =      0.05522080d0
      s(  9) =      1.00000000d0
      e( 10) =      0.16650000d0
      p( 10) =      1.00000000d0
      e( 11) =      0.27800000d0
      d( 11) =      1.00000000d0
c 
      go to 1000
c
c     ----- b -----
c
c B     (9s,5p,1d) -> [3s,2p,1d] 
c
  140 continue
c
      e(  1) =   1915.16660000d0
      s(  1) =     -0.00203950d0
      e(  2) =    287.18311000d0
      s(  2) =     -0.01559660d0
      e(  3) =     65.15717600d0
      s(  3) =     -0.07624420d0
      e(  4) =     18.19582700d0
      s(  4) =     -0.24792440d0
      e(  5) =      5.70153790d0
      s(  5) =     -0.47908230d0
      e(  6) =      1.84383750d0
      s(  6) =     -0.33529530d0
      e(  7) =      3.49143040d0
      s(  7) =      0.07742240d0
      e(  8) =      0.30505600d0
      s(  8) =     -0.57412390d0
      e(  9) =      0.09648650d0
      s(  9) =      1.00000000d0
      e( 10) =     11.68741700d0
      p( 10) =      0.01508610d0
      e( 11) =      2.63077550d0
      p( 11) =      0.08881570d0
      e( 12) =      0.74422690d0
      p( 12) =      0.29036820d0
      e( 13) =      0.23047610d0
      p( 13) =      0.49944330d0
      e( 14) =      0.06993800d0
      p( 14) =      1.00000000d0
      e( 15) =      0.40000000d0
      d( 15) =      1.00000000d0
c
      go to 1000
c
c     ----- c -----
c
c C    (9s,5p,1d) -> [3s,2p,1d]
c
  160 continue
c
      e(  1) =   2808.06450000d0
      s(  1) =      0.00201780d0
      e(  2) =    421.13828000d0
      s(  2) =      0.01543320d0
      e(  3) =     95.58661600d0
      s(  3) =      0.07558150d0
      e(  4) =     26.73900400d0
      s(  4) =      0.24782820d0
      e(  5) =      8.43282680d0
      s(  5) =      0.47937250d0
      e(  6) =      2.76058210d0
      s(  6) =      0.33383440d0
      e(  7) =      5.44700450d0
      s(  7) =     -0.07784080d0
      e(  8) =      0.47924220d0
      s(  8) =      0.56895600d0
      e(  9) =      0.14615650d0
      s(  9) =      1.00000000d0
      e( 10) =     18.13085200d0
      p( 10) =      0.01585470d0
      e( 11) =      4.09988320d0
      p( 11) =      0.09568280d0
      e( 12) =      1.18583700d0
      p( 12) =      0.30491190d0
      e( 13) =      0.36859740d0
      p( 13) =      0.49350160d0
      e( 14) =      0.10972000d0
      p( 14) =      1.00000000d0
      e( 15) =      0.60000000d0
      d( 15) =      1.00000000d0
c
      go to 1000
c
c     ----- n -----
c
c N    (9s,5p,1d) -> [3s,2p,1d]
c
  180 continue
c
      e(  1) =   3845.41490000d0
      s(  1) =      0.00201860d0
      e(  2) =    577.53323000d0
      s(  2) =      0.01540780d0
      e(  3) =    131.31983000d0
      s(  3) =      0.07537140d0
      e(  4) =     36.82378100d0
      s(  4) =      0.24821220d0
      e(  5) =     11.67011500d0
      s(  5) =      0.47982740d0
      e(  6) =      3.85426040d0
      s(  6) =      0.33180120d0
      e(  7) =      7.82956110d0
      s(  7) =     -0.07766690d0
      e(  8) =      0.68773510d0
      s(  8) =      0.56545980d0
      e(  9) =      0.20403880d0
      s(  9) =      1.00000000d0
      e( 10) =     26.80984100d0
      p( 10) =      0.01546630d0
      e( 11) =      6.06815400d0
      p( 11) =      0.09643970d0
      e( 12) =      1.76762560d0
      p( 12) =      0.30836100d0
      e( 13) =      0.54667270d0
      p( 13) =      0.49115970d0
      e( 14) =      0.15872890d0
      p( 14) =      1.00000000d0
      e( 15) =      0.70000000d0
      d( 15) =      1.00000000d0
c
      go to 1000
c
c     ----- o ------
c
c O    (9s,5p,1d) -> [3s,2p,1d]
c
  200 continue
c
      e(  1) =   5222.90220000d0
      s(  1) =     -0.00193640d0
      e(  2) =    782.53994000d0
      s(  2) =     -0.01485070d0
      e(  3) =    177.26743000d0
      s(  3) =     -0.07331870d0
      e(  4) =     49.51668800d0
      s(  4) =     -0.24511620d0
      e(  5) =     15.66644000d0
      s(  5) =     -0.48028470d0
      e(  6) =      5.17935990d0
      s(  6) =     -0.33594270d0
      e(  7) =     10.60144100d0
      s(  7) =      0.07880580d0
      e(  8) =      0.94231700d0
      s(  8) =     -0.56769520d0
      e(  9) =      0.27747460d0
      s(  9) =      1.00000000d0
      e( 10) =     33.42412600d0
      p( 10) =      0.01756030d0
      e( 11) =      7.62217140d0
      p( 11) =      0.10763000d0
      e( 12) =      2.23820930d0
      p( 12) =      0.32352560d0
      e( 13) =      0.68673000d0
      p( 13) =      0.48322290d0
      e( 14) =      0.19381350d0
      p( 14) =      1.00000000d0
      e( 15) =      0.80000000d0
      d( 15) =      1.00000000d0
c
      go to 1000
c
c     ----- f -----
c
c F   (9s,5p,1d) -> [3s,2p,1d]
c
  220 continue
c
      e(  1) =   6384.71440000d0
      s(  1) =     -0.00203020d0
      e(  2) =    958.88652000d0
      s(  2) =     -0.01549810d0
      e(  3) =    218.19010000d0
      s(  3) =     -0.07577870d0
      e(  4) =     61.36473100d0
      s(  4) =     -0.25027230d0
      e(  5) =     19.60289600d0
      s(  5) =     -0.48010870d0
      e(  6) =      6.56488340d0
      s(  6) =     -0.32716140d0
      e(  7) =     13.81069400d0
      s(  7) =      0.07907070d0
      e(  8) =      1.22986650d0
      s(  8) =     -0.56812160d0
      e(  9) =      0.35847130d0
      s(  9) =      1.00000000d0
      e( 10) =     42.46991100d0
      p( 10) =      0.01831704d0
      e( 11) =      9.71388110d0
      p( 11) =      0.11245129d0
      e( 12) =      2.86403860d0
      p( 12) =      0.32977705d0
      e( 13) =      0.87460544d0
      p( 13) =      0.47997719d0
      e( 14) =      0.24250706d0
      p( 14) =      1.00000000d0
      e( 15) =      1.00000000d0
      d( 15) =      1.00000000d0
c
      go to 1000
c
c     ----- ne -----
c
c Ne   (9s,5p,1d) -> [3s,2p,1d]
c
  240 continue
c
      e(  1) =   7883.82610000d0
      s(  1) =      0.00203750d0
      e(  2) =   1184.40550000d0
      s(  2) =      0.01554680d0
      e(  3) =    269.67309000d0
      s(  3) =      0.07596380d0
      e(  4) =     75.94165200d0
      s(  4) =      0.25110270d0
      e(  5) =     24.32109500d0
      s(  5) =      0.48047650d0
      e(  6) =      8.18325590d0
      s(  6) =      0.32511420d0
      e(  7) =     17.44952400d0
      s(  7) =     -0.07901000d0
      e(  8) =      1.55163160d0
      s(  8) =      0.56762740d0
      e(  9) =      0.44769850d0
      s(  9) =      1.00000000d0
      e( 10) =     52.90380800d0
      p( 10) =      0.01879110d0
      e( 11) =     12.12336100d0
      p( 11) =      0.11576050d0
      e( 12) =      3.58592250d0
      p( 12) =      0.33426270d0
      e( 13) =      1.09216340d0
      p( 13) =      0.47780380d0
      e( 14) =      0.29944190d0
      p( 14) =      1.00000000d0
      e( 15) =      1.20000000d0
      d( 15) =      1.00000000d0
c
1000  return
      end
      subroutine dftdzvp_2(e,s,p,d,n)
c
c     ----- dzvp_dft contractions  [Na-Ar] -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-10
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- na  -----
c
c na  (12s,6p,1d) -> [4s,3p,1d]
c
  100 continue
c
      e(  1) =   9911.99600000d0
      s(  1) =      0.00195050d0
      e(  2) =   1487.45550000d0
      s(  2) =      0.01491710d0
      e(  3) =    337.95385000d0
      s(  3) =      0.07341660d0
      e(  4) =     94.91394500d0
      s(  4) =      0.24569100d0
      e(  5) =     30.34149900d0
      s(  5) =      0.47956110d0
      e(  6) =     10.19083900d0
      s(  6) =      0.33372120d0
      e(  7) =     21.22964800d0
      s(  7) =      0.08230290d0
      e(  8) =      1.98041760d0
      s(  8) =     -0.56084800d0
      e(  9) =      0.61888240d0
      s(  9) =     -0.52243780d0
      e( 10) =      0.69917380d0
      s( 10) =      0.09209750d0
      e( 11) =      0.06182700d0
      s( 11) =     -0.67082520d0
      e( 12) =      0.02372740d0
      s( 12) =      1.00000000d0
      e( 13) =     73.08531500d0
      p( 13) =      0.01671760d0
      e( 14) =     16.86456300d0
      p( 14) =      0.10653950d0
      e( 15) =      5.05539130d0
      p( 15) =      0.32422170d0
      e( 16) =      1.59202070d0
      p( 16) =      0.48913630d0
      e( 17) =      0.47026900d0
      p( 17) =      1.00000000d0
      e( 18) =      0.06470000d0
      p( 18) =      1.00000000d0
      e( 19) =      0.11690000d0
      d( 19) =      1.00000000d0
c
      go to 1000
c
c     ----- mg -----
c
c mg  (12s,6p,1d) -> [4s,3p,1d]
c 
  120 continue
c
      e(  1) =  12436.67500000d0
      s(  1) =     -0.00183330d0
      e(  2) =   1862.22320000d0
      s(  2) =     -0.01408280d0
      e(  3) =    421.37452000d0
      s(  3) =     -0.07009560d0
      e(  4) =    117.69304000d0
      s(  4) =     -0.23877180d0
      e(  5) =     37.43145300d0
      s(  5) =     -0.47873770d0
      e(  6) =     12.50548900d0
      s(  6) =     -0.34477730d0
      e(  7) =     25.45140000d0
      s(  7) =      0.08521400d0
      e(  8) =      2.45287650d0
      s(  8) =     -0.56469160d0
      e(  9) =      0.80513340d0
      s(  9) =     -0.51572750d0
      e( 10) =      1.08200760d0
      s( 10) =     -0.11133340d0
      e( 11) =      0.10833400d0
      s( 11) =      0.64814520d0
      e( 12) =      0.03990740d0
      s( 12) =      1.00000000d0
      e( 13) =     92.46322200d0
      p( 13) =      0.01627160d0
      e( 14) =     21.50176900d0
      p( 14) =      0.10456300d0
      e( 15) =      6.53744230d0
      p( 15) =      0.32243280d0
      e( 16) =      2.11808080d0
      p( 16) =      0.49403990d0
      e( 17) =      0.65831480d0
      p( 17) =      1.00000000d0
      e( 18) =      0.10610000d0
      p( 18) =      1.00000000d0
      e( 19) =      0.18700000d0
      d( 19) =      1.00000000d0
c
      go to 1000
c
c     ----- al -----
c
c al  (12s,8p,1d) -> [4s,3p,1d]
c 
  140 continue
c
      e(  1) =  14724.45100000d0
      s(  1) =      0.00181820d0
      e(  2) =   2205.46340000d0
      s(  2) =      0.01395810d0
      e(  3) =    499.30207000d0
      s(  3) =      0.06950090d0
      e(  4) =    139.59014000d0
      s(  4) =      0.23710620d0
      e(  5) =     44.49227700d0
      s(  5) =      0.47761040d0
      e(  6) =     14.90569100d0
      s(  6) =      0.34763390d0
      e(  7) =     30.07506500d0
      s(  7) =     -0.08788510d0
      e(  8) =      2.98383280d0
      s(  8) =      0.56773710d0
      e(  9) =      1.02098990d0
      s(  9) =      0.51050080d0
      e( 10) =      1.49277920d0
      s( 10) =      0.13414240d0
      e( 11) =      0.16922910d0
      s( 11) =     -0.66567580d0
      e( 12) =      0.06174490d0
      s( 12) =      1.00000000d0
      e( 13) =    127.91613000d0
      p( 13) =      0.01330240d0
      e( 14) =     29.77677800d0
      p( 14) =      0.08967100d0
      e( 15) =      9.09173840d0
      p( 15) =      0.29813080d0
      e( 16) =      3.00098650d0
      p( 16) =      0.49626280d0
      e( 17) =      0.96955840d0
      p( 17) =      0.33014500d0
      e( 18) =      0.37560010d0
      p( 18) =      0.20509820d0
      e( 19) =      0.12509890d0
      p( 19) =      0.55181020d0
      e( 20) =      0.04173980d0
      p( 20) =      1.00000000d0
      e( 21) =      0.30000000d0
      d( 21) =      1.00000000d0
c
      go to 1000
c
c     ----- si -----
c
c si (12s,8p,1d) -> [4s,3p,1d]
c
  160 continue
c
      e(  1) =  17268.57700000d0
      s(  1) =     -0.00179740d0
      e(  2) =   2586.65090000d0
      s(  2) =     -0.01379700d0
      e(  3) =    585.63641000d0
      s(  3) =     -0.06878070d0
      e(  4) =    163.77364000d0
      s(  4) =     -0.23525080d0
      e(  5) =     52.26702800d0
      s(  5) =     -0.47661940d0
      e(  6) =     17.54168100d0
      s(  6) =     -0.35077260d0
      e(  7) =     35.12413900d0
      s(  7) =      0.09021370d0
      e(  8) =      3.56542270d0
      s(  8) =     -0.57225480d0
      e(  9) =      1.25914740d0
      s(  9) =     -0.50455370d0
      e( 10) =      1.94701440d0
      s( 10) =     -0.15083520d0
      e( 11) =      0.23675730d0
      s( 11) =      0.67455940d0
      e( 12) =      0.08589660d0
      s( 12) =      1.00000000d0
      e( 13) =    159.68174000d0
      p( 13) =     -0.01239320d0
      e( 14) =     37.25817200d0
      p( 14) =     -0.08508000d0
      e( 15) =     11.43825300d0
      p( 15) =     -0.29055130d0
      e( 16) =      3.82783360d0
      p( 16) =     -0.49855880d0
      e( 17) =      1.26790030d0
      p( 17) =     -0.33256240d0
      e( 18) =      0.53440950d0
      p( 18) =     -0.22643690d0
      e( 19) =      0.18290310d0
      p( 19) =     -0.55530350d0
      e( 20) =      0.06178730d0
      p( 20) =      1.00000000d0
      e( 21) =      0.45000000d0
      d( 21) =      1.00000000d0
c
      go to 1000
c
c     ----- p -----
c
c p  (12s,8p,1d) -> [4s,3p,1d]
c
  180 continue
c
      e(  1) =  20024.93600000d0
      s(  1) =     -0.00177870d0
      e(  2) =   2999.44100000d0
      s(  2) =     -0.01365410d0
      e(  3) =    679.08680000d0
      s(  3) =     -0.06814420d0
      e(  4) =    189.94389000d0
      s(  4) =     -0.23361370d0
      e(  5) =     60.68347700d0
      s(  5) =     -0.47574010d0
      e(  6) =     20.39822500d0
      s(  6) =     -0.35354700d0
      e(  7) =     40.59416300d0
      s(  7) =     -0.09224270d0
      e(  8) =      4.19721960d0
      s(  8) =      0.57746770d0
      e(  9) =      1.51929550d0
      s(  9) =      0.49837730d0
      e( 10) =      2.44585870d0
      s( 10) =      0.16316950d0
      e( 11) =      0.31161580d0
      s( 11) =     -0.67871740d0
      e( 12) =      0.11201010d0
      s( 12) =      1.00000000d0
      e( 13) =    195.39937000d0
      p( 13) =     -0.01162980d0
      e( 14) =     45.66674900d0
      p( 14) =     -0.08114130d0
      e( 15) =     14.07306700d0
      p( 15) =     -0.28377060d0
      e( 16) =      4.75724270d0
      p( 16) =     -0.50040740d0
      e( 17) =      1.60350650d0
      p( 17) =     -0.33577580d0
      e( 18) =      0.70394320d0
      p( 18) =     -0.24716970d0
      e( 19) =      0.24511450d0
      p( 19) =     -0.55520250d0
      e( 20) =      0.08313240d0
      p( 20) =      1.00000000d0
      e( 21) =      0.55000000d0
      d( 21) =      1.00000000d0
c
      go to 1000
c
c     ----- s -----
c
c s  (12s,8p,1d) -> [4s,3p,1d]
c
  200 continue
c
      e(  1) =  23050.06700000d0
      s(  1) =     -0.00175670d0
      e(  2) =   3451.86630000d0
      s(  2) =     -0.01348940d0
      e(  3) =    781.27867000d0
      s(  3) =     -0.06743250d0
      e(  4) =    218.47653000d0
      s(  4) =     -0.23186040d0
      e(  5) =     69.83263200d0
      s(  5) =     -0.47494160d0
      e(  6) =     23.49479800d0
      s(  6) =     -0.35649920d0
      e(  7) =     46.48237700d0
      s(  7) =     -0.09404220d0
      e(  8) =      4.88074880d0
      s(  8) =      0.58288810d0
      e(  9) =      1.80147580d0
      s(  9) =      0.49232620d0
      e( 10) =      2.97780390d0
      s( 10) =      0.17315530d0
      e( 11) =      0.39425100d0
      s( 11) =     -0.68543630d0
      e( 12) =      0.14170280d0
      s( 12) =      1.00000000d0
      e( 13) =    231.33126000d0
      p( 13) =      0.01127890d0
      e( 14) =     54.14616400d0
      p( 14) =      0.07942570d0
      e( 15) =     16.75761800d0
      p( 15) =      0.28087990d0
      e( 16) =      5.71931970d0
      p( 16) =      0.50201900d0
      e( 17) =      1.95603510d0
      p( 17) =      0.33441460d0
      e( 18) =      0.89559120d0
      p( 18) =      0.26468110d0
      e( 19) =      0.30942270d0
      p( 19) =      0.54961270d0
      e( 20) =      0.10211570d0
      p( 20) =      1.00000000d0
      e( 21) =      0.65000000d0
      d( 21) =      1.00000000d0
c
      go to 1000
c
c     ----- cl -----
c
c cl (12s,8p,1d) -> [4s,3p,1d]
c
  220 continue
c
      e(  1) =  26351.45800000d0
      s(  1) =      0.00173240d0
      e(  2) =   3945.05670000d0
      s(  2) =      0.01331090d0
      e(  3) =    892.43835000d0
      s(  3) =      0.06667480d0
      e(  4) =    249.41743000d0
      s(  4) =      0.23005060d0
      e(  5) =     79.72157200d0
      s(  5) =      0.47423070d0
      e(  6) =     26.83114500d0
      s(  6) =      0.35952400d0
      e(  7) =     52.78530100d0
      s(  7) =     -0.09562960d0
      e(  8) =      5.61564290d0
      s(  8) =      0.58808400d0
      e(  9) =      2.10590760d0
      s(  9) =      0.48669820d0
      e( 10) =      3.55861490d0
      s( 10) =      0.18068910d0
      e( 11) =      0.48479810d0
      s( 11) =     -0.68848290d0
      e( 12) =      0.17333100d0
      s( 12) =      1.00000000d0
      e( 13) =    271.07821000d0
      p( 13) =     -0.01092570d0
      e( 14) =     63.54720800d0
      p( 14) =     -0.07759090d0
      e( 15) =     19.73710900d0
      p( 15) =     -0.27751590d0
      e( 16) =      6.78899370d0
      p( 16) =     -0.50319330d0
      e( 17) =      2.34803030d0
      p( 17) =     -0.33484260d0
      e( 18) =      1.10668640d0
      p( 18) =     -0.27653810d0
      e( 19) =      0.38296800d0
      p( 19) =     -0.54667680d0
      e( 20) =      0.12511330d0
      p( 20) =      1.00000000d0
      e( 21) =      0.75000000d0
      d( 21) =      1.00000000d0
c
      go to 1000
c
c     ----- ar -----
c
c ar  (12s,8p,1d) -> [4s,3p,1d]
c
  240 continue
c
      e(  1) =  29505.77400000d0
      s(  1) =     -0.00173750d0
      e(  2) =   4419.21620000d0
      s(  2) =     -0.01333810d0
      e(  3) =   1000.57700000d0
      s(  3) =     -0.06672490d0
      e(  4) =    280.03798000d0
      s(  4) =     -0.22988870d0
      e(  5) =     89.71208200d0
      s(  5) =     -0.47357440d0
      e(  6) =     30.27987800d0
      s(  6) =     -0.35991600d0
      e(  7) =     59.51440600d0
      s(  7) =      0.09702570d0
      e(  8) =      6.39977790d0
      s(  8) =     -0.59339870d0
      e(  9) =      2.43147090d0
      s(  9) =     -0.48108050d0
      e( 10) =      4.18753570d0
      s( 10) =     -0.18640000d0
      e( 11) =      0.58325620d0
      s( 11) =      0.68956890d0
      e( 12) =      0.20710810d0
      s( 12) =      1.00000000d0
      e( 13) =    313.02176000d0
      p( 13) =      0.01067530d0
      e( 14) =     73.48723100d0
      p( 14) =      0.07630950d0
      e( 15) =     22.89798800d0
      p( 15) =      0.27512700d0
      e( 16) =      7.93221480d0
      p( 16) =      0.50407190d0
      e( 17) =      2.77026960d0
      p( 17) =      0.33462710d0
      e( 18) =      1.33189530d0
      p( 18) =      0.28770000d0
      e( 19) =      0.46186150d0
      p( 19) =      0.54475270d0
      e( 20) =      0.15021940d0
      p( 20) =      1.00000000d0
      e( 21) =      0.85000000d0
      d( 21) =      1.00000000d0
c
 1000 return
      end
      subroutine dftdzvp_3(e,s,p,d,n)
c
c ----- dzvp_dft basis 
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-18
      go to (100,120,140,160,180,200,220,240,260,280,300,320),nn
c
c k   (15s,9p,1d) -> [5s,4p,1d]
c
  100 continue
c
      e(  1) =  33078.64800000d0
      s(  1) =      0.00172670d0
      e(  2) =   4954.90240000d0
      s(  2) =      0.01325140d0
      e(  3) =   1122.13080000d0
      s(  3) =      0.06631420d0
      e(  4) =    314.20807000d0
      s(  4) =      0.22867240d0
      e(  5) =    100.77629000d0
      s(  5) =      0.47266980d0
      e(  6) =     34.06134800d0
      s(  6) =      0.36214160d0
      e(  7) =     66.60293100d0
      s(  7) =     -0.09845070d0
      e(  8) =      7.26445630d0
      s(  8) =      0.59416190d0
      e(  9) =      2.80367870d0
      s(  9) =      0.47991390d0
      e( 10) =      4.83243900d0
      s( 10) =      0.19727090d0
      e( 11) =      0.70581890d0
      s( 11) =     -0.69564730d0
      e( 12) =      0.26975200d0
      s( 12) =     -0.42287810d0
      e( 13) =      0.35335350d0
      s( 13) =     -0.12467830d0
      e( 14) =      0.04209160d0
      s( 14) =      0.73836330d0
      e( 15) =      0.01744850d0
      s( 15) =      1.00000000d0
      e( 16) =    367.51146000d0
      p( 16) =     -0.01003330d0
      e( 17) =     86.26085800d0
      p( 17) =     -0.07273480d0
      e( 18) =     26.89796800d0
      p( 18) =     -0.26790430d0
      e( 19) =      9.35412480d0
      p( 19) =     -0.50383670d0
      e( 20) =      3.29205810d0
      p( 20) =     -0.34262240d0
      e( 21) =      1.62091890d0
      p( 21) =     -0.29527220d0
      e( 22) =      0.58724930d0
      p( 22) =     -0.55635660d0
      e( 23) =      0.20469410d0
      p( 23) =      1.00000000d0
      e( 24) =      0.04080000d0
      p( 24) =      1.00000000d0
      e( 25) =      0.07410000d0
      d( 25) =      1.00000000d0
c
      go to 1000
c
c ca  (15s,9p,1d) -> [5s,4p,1d]
c 
  120 continue
c
      e(  1) =  36930.00900000d0
      s(  1) =      0.00171280d0
      e(  2) =   5531.70970000d0
      s(  2) =      0.01314490d0
      e(  3) =   1252.74140000d0
      s(  3) =      0.06583590d0
      e(  4) =    350.81485000d0
      s(  4) =      0.22736060d0
      e(  5) =    112.59658000d0
      s(  5) =      0.47184690d0
      e(  6) =     38.08879300d0
      s(  6) =      0.36449950d0
      e(  7) =     74.11647000d0
      s(  7) =     -0.09974360d0
      e(  8) =      8.18437380d0
      s(  8) =      0.59521130d0
      e(  9) =      3.20036840d0
      s(  9) =      0.47859930d0
      e( 10) =      5.52832780d0
      s( 10) =      0.20718530d0
      e( 11) =      0.83789520d0
      s( 11) =     -0.71058040d0
      e( 12) =      0.33303330d0
      s( 12) =     -0.41099170d0
      e( 13) =      0.50885980d0
      s( 13) =     -0.15455110d0
      e( 14) =      0.06602440d0
      s( 14) =      0.72416430d0
      e( 15) =      0.02685900d0
      s( 15) =      1.00000000d0
      e( 16) =    421.34592000d0
      p( 16) =     -0.00968650d0
      e( 17) =     98.97598900d0
      p( 17) =     -0.07075990d0
      e( 18) =     30.92869800d0
      p( 18) =     -0.26365930d0
      e( 19) =     10.81166100d0
      p( 19) =     -0.50336510d0
      e( 20) =      3.83798000d0
      p( 20) =     -0.34663080d0
      e( 21) =      1.92760190d0
      p( 21) =     -0.30269800d0
      e( 22) =      0.72568230d0
      p( 22) =     -0.55916280d0
      e( 23) =      0.26598630d0
      p( 23) =      1.00000000d0
      e( 24) =      0.05810000d0
      p( 24) =      1.00000000d0
      e( 25) =      7.20311460d0
      d( 25) =      0.05694780d0
      e( 26) =      1.89880740d0
      d( 26) =      0.19125180d0
      e( 27) =      0.59249740d0
      d( 27) =      0.29123020d0
      e( 28) =      0.18403880d0
      d( 28) =      0.29468690d0
      e( 29) =      0.05570440d0
      d( 29) =      1.00000000d0
c
      return
c
c sc  (15s,9p,1d) -> [5s,3p,1d]
c 
  140 continue
c
      e(  1) =  40355.90900000d0
      s(  1) =      0.00173330d0
      e(  2) =   6050.51540000d0
      s(  2) =      0.01327890d0
      e(  3) =   1372.47650000d0
      s(  3) =      0.06630410d0
      e(  4) =    385.24704000d0
      s(  4) =      0.22810440d0
      e(  5) =    124.03194000d0
      s(  5) =      0.47136570d0
      e(  6) =     42.11942300d0
      s(  6) =      0.36337640d0
      e(  7) =     82.15869800d0
      s(  7) =     -0.10081750d0
      e(  8) =      9.13498380d0
      s(  8) =      0.60057600d0
      e(  9) =      3.60008560d0
      s(  9) =      0.47318600d0
      e( 10) =      6.31097380d0
      s( 10) =      0.20966180d0
      e( 11) =      0.96549480d0
      s( 11) =     -0.70888480d0
      e( 12) =      0.37893510d0
      s( 12) =     -0.41495890d0
      e( 13) =      0.53398660d0
      s( 13) =     -0.15187660d0
      e( 14) =      0.07369860d0
      s( 14) =      0.70297410d0
      e( 15) =      0.02872050d0
      s( 15) =      1.00000000d0
      e( 16) =    483.11966000d0
      p( 16) =      0.00927160d0
      e( 17) =    113.24773000d0
      p( 17) =      0.06863490d0
      e( 18) =     35.35725400d0
      p( 18) =      0.25997160d0
      e( 19) =     12.37920400d0
      p( 19) =      0.50433570d0
      e( 20) =      4.41037250d0
      p( 20) =      0.34958900d0
      e( 21) =      2.22423780d0
      p( 21) =      0.31023150d0
      e( 22) =      0.83389920d0
      p( 22) =      0.55513980d0
      e( 23) =      0.30345080d0
      p( 23) =      0.26173530d0
      e( 24) =      0.07650000d0
      p( 24) =      1.00000000d0
      e( 25) =     10.66290300d0
      d( 25) =      0.06447520d0
      e( 26) =      2.71962190d0
      d( 26) =      0.26369060d0
      e( 27) =      0.76770850d0
      d( 27) =      0.47189550d0
      e( 28) =      0.18863360d0
      d( 28) =      0.54521500d0
      e( 29) =      0.03600000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c ti  (15s,9p,5d) -> [5s,3p,2d]
c 
  160 continue
c
      e(  1) =  44446.89600000d0
      s(  1) =     -0.00172760d0
      e(  2) =   6664.41460000d0
      s(  2) =     -0.01323290d0
      e(  3) =   1511.98650000d0
      s(  3) =     -0.06608370d0
      e(  4) =    424.55078000d0
      s(  4) =     -0.22746910d0
      e(  5) =    136.80023000d0
      s(  5) =     -0.47087550d0
      e(  6) =     46.51453500d0
      s(  6) =     -0.36449010d0
      e(  7) =     90.60494200d0
      s(  7) =     -0.10181260d0
      e(  8) =     10.14685800d0
      s(  8) =      0.60429920d0
      e(  9) =      4.02771640d0
      s(  9) =      0.46944500d0
      e( 10) =      7.12703760d0
      s( 10) =     -0.21271460d0
      e( 11) =      1.10314030d0
      s( 11) =      0.71041180d0
      e( 12) =      0.43244950d0
      s( 12) =      0.41533070d0
      e( 13) =      0.61557520d0
      s( 13) =     -0.15265740d0
      e( 14) =      0.08585810d0
      s( 14) =      0.66103500d0
      e( 15) =      0.03310330d0
      s( 15) =      1.00000000d0
      e( 16) =    537.66903000d0
      p( 16) =      0.00920800d0
      e( 17) =    126.36414000d0
      p( 17) =      0.06818680d0
      e( 18) =     39.57137900d0
      p( 18) =      0.25913240d0
      e( 19) =     13.92175000d0
      p( 19) =      0.50463900d0
      e( 20) =      4.99168060d0
      p( 20) =      0.34877870d0
      e( 21) =      2.54789080d0
      p( 21) =      0.31521970d0
      e( 22) =      0.95979350d0
      p( 22) =      0.55340100d0
      e( 23) =      0.35020630d0
      p( 23) =      0.25775430d0
      e( 24) =      0.08550000d0
      p( 24) =      1.00000000d0
      e( 25) =     13.52001600d0
      d( 25) =     -0.06241370d0
      e( 26) =      3.50745230d0
      d( 26) =     -0.26480160d0
      e( 27) =      1.02209480d0
      d( 27) =     -0.47977000d0
      e( 28) =      0.26278610d0
      d( 28) =     -0.52405580d0
      e( 29) =      0.05100000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c v   (15s,9p,5d) -> [5s,3p,2d]
c 
  180 continue
c
      e(  1) =  49145.25800000d0
      s(  1) =     -0.00170490d0
      e(  2) =   7366.10090000d0
      s(  2) =     -0.01306850d0
      e(  3) =   1669.95980000d0
      s(  3) =     -0.06540440d0
      e(  4) =    468.43959000d0
      s(  4) =     -0.22592860d0
      e(  5) =    150.82100000d0
      s(  5) =     -0.47044030d0
      e(  6) =     51.25277600d0
      s(  6) =     -0.36702730d0
      e(  7) =     99.48018000d0
      s(  7) =     -0.10271690d0
      e(  8) =     11.21326400d0
      s(  8) =      0.60769800d0
      e(  9) =      4.47782520d0
      s(  9) =      0.46607310d0
      e( 10) =      7.99133500d0
      s( 10) =     -0.21478090d0
      e( 11) =      1.24681580d0
      s( 11) =      0.71090440d0
      e( 12) =      0.48739340d0
      s( 12) =      0.41627090d0
      e( 13) =      0.69088900d0
      s( 13) =     -0.14902600d0
      e( 14) =      0.09698660d0
      s( 14) =      0.63308970d0
      e( 15) =      0.03676400d0
      s( 15) =      1.00000000d0
      e( 16) =    595.12707000d0
      p( 16) =     -0.00915890d0
      e( 17) =    140.00397000d0
      p( 17) =     -0.06796570d0
      e( 18) =     43.94137700d0
      p( 18) =     -0.25889920d0
      e( 19) =     15.52695200d0
      p( 19) =     -0.50501160d0
      e( 20) =      5.59921580d0
      p( 20) =     -0.34734430d0
      e( 21) =      2.88927230d0
      p( 21) =     -0.31914860d0
      e( 22) =      1.09088840d0
      p( 22) =     -0.55183650d0
      e( 23) =      0.39812970d0
      p( 23) =     -0.25524260d0
      e( 24) =      0.09510000d0
      p( 24) =      1.00000000d0
      e( 25) =     16.22047300d0
      d( 25) =     -0.06163860d0
      e( 26) =      4.25474240d0
      d( 26) =     -0.26686080d0
      e( 27) =      1.26177140d0
      d( 27) =     -0.48444430d0
      e( 28) =      0.33151450d0
      d( 28) =     -0.51113550d0
      e( 29) =      0.06400000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c cr  (15s,9p,5d) -> [5s,3p,2d]
c
  200 continue
c
      e(  1) =  52778.74500000d0
      s(  1) =      0.00173540d0
      e(  2) =   7918.30170000d0
      s(  2) =      0.01327750d0
      e(  3) =   1798.48710000d0
      s(  3) =      0.06619060d0
      e(  4) =    505.92005000d0
      s(  4) =      0.22738480d0
      e(  5) =    163.50058000d0
      s(  5) =      0.47007280d0
      e(  6) =     55.81763400d0
      s(  6) =      0.36476530d0
      e(  7) =    108.80412000d0
      s(  7) =      0.10351710d0
      e(  8) =     12.32738700d0
      s(  8) =     -0.61151690d0
      e(  9) =      4.94622950d0
      s(  9) =     -0.46230660d0
      e( 10) =      8.90204460d0
      s( 10) =      0.21619010d0
      e( 11) =      1.39669760d0
      s( 11) =     -0.71092030d0
      e( 12) =      0.54401410d0
      s( 12) =     -0.41735880d0
      e( 13) =      0.77736610d0
      s( 13) =      0.14687210d0
      e( 14) =      0.10703580d0
      s( 14) =     -0.61484960d0
      e( 15) =      0.03990770d0
      s( 15) =      1.00000000d0
      e( 16) =    661.71204000d0
      p( 16) =     -0.00898940d0
      e( 17) =    155.31302000d0
      p( 17) =     -0.06727680d0
      e( 18) =     48.74308000d0
      p( 18) =     -0.25797560d0
      e( 19) =     17.26608300d0
      p( 19) =     -0.50558000d0
      e( 20) =      6.25076520d0
      p( 20) =     -0.34714140d0
      e( 21) =      3.25048650d0
      p( 21) =     -0.32202080d0
      e( 22) =      1.22840880d0
      p( 22) =     -0.55047770d0
      e( 23) =      0.44784370d0
      p( 23) =     -0.25390240d0
      e( 24) =      0.10510000d0
      p( 24) =      1.00000000d0
      e( 25) =     18.83297300d0
      d( 25) =     -0.06170400d0
      e( 26) =      4.97912030d0
      d( 26) =     -0.27010800d0
      e( 27) =      1.49186960d0
      d( 27) =     -0.48809890d0
      e( 28) =      0.39585120d0
      d( 28) =     -0.50111050d0
      e( 29) =      0.07500000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c mn  (15s,9p,5d) -> [5s,3p,2d]
c 
  220 continue
c
      e(  1) =  58745.69200000d0
      s(  1) =      0.00168350d0
      e(  2) =   8803.03930000d0
      s(  2) =      0.01291030d0
      e(  3) =   1994.93300000d0
      s(  3) =      0.06472260d0
      e(  4) =    559.35363000d0
      s(  4) =      0.22426570d0
      e(  5) =    180.12270000d0
      s(  5) =      0.46969490d0
      e(  6) =     61.26213400d0
      s(  6) =      0.36980490d0
      e(  7) =    118.52803000d0
      s(  7) =      0.10427700d0
      e(  8) =     13.50494600d0
      s(  8) =     -0.61400010d0
      e(  9) =      5.44318340d0
      s(  9) =     -0.45989710d0
      e( 10) =      9.85695530d0
      s( 10) =      0.21755470d0
      e( 11) =      1.55521630d0
      s( 11) =     -0.71088590d0
      e( 12) =      0.60461780d0
      s( 12) =     -0.41837030d0
      e( 13) =      0.86296550d0
      s( 13) =      0.14376110d0
      e( 14) =      0.11671880d0
      s( 14) =     -0.60090080d0
      e( 15) =      0.04285910d0
      s( 15) =      1.00000000d0
      e( 16) =    740.92768000d0
      p( 16) =     -0.00864200d0
      e( 17) =    173.91313000d0
      p( 17) =     -0.06522490d0
      e( 18) =     54.51849100d0
      p( 18) =     -0.25404170d0
      e( 19) =     19.30041400d0
      p( 19) =     -0.50615190d0
      e( 20) =      6.98930980d0
      p( 20) =     -0.35142320d0
      e( 21) =      3.63261960d0
      p( 21) =     -0.32483590d0
      e( 22) =      1.37382970d0
      p( 22) =     -0.54964150d0
      e( 23) =      0.50142890d0
      p( 23) =     -0.25172730d0
      e( 24) =      0.11290000d0
      p( 24) =      1.00000000d0
      e( 25) =     21.25795800d0
      d( 25) =      0.06302750d0
      e( 26) =      5.65799460d0
      d( 26) =      0.27540610d0
      e( 27) =      1.70294550d0
      d( 27) =      0.49168450d0
      e( 28) =      0.45188690d0
      d( 28) =      0.49148300d0
      e( 29) =      0.08200000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c fe  (15s,9p,5d) -> [5s,3p,2d]
c 
  240 continue
c
      e(  1) =  61430.22700000d0
      s(  1) =      0.00175590d0
      e(  2) =   9222.17600000d0
      s(  2) =      0.01341690d0
      e(  3) =   2097.59690000d0
      s(  3) =      0.06669540d0
      e(  4) =    591.49040000d0
      s(  4) =      0.22820510d0
      e(  5) =    191.86062000d0
      s(  5) =      0.46944990d0
      e(  6) =     65.82632800d0
      s(  6) =      0.36355690d0
      e(  7) =    128.74074000d0
      s(  7) =     -0.10491680d0
      e(  8) =     14.71813300d0
      s(  8) =      0.61796190d0
      e(  9) =      5.95075430d0
      s(  9) =      0.45600930d0
      e( 10) =     10.85987900d0
      s( 10) =      0.21849170d0
      e( 11) =      1.71944710d0
      s( 11) =     -0.71133100d0
      e( 12) =      0.66645320d0
      s( 12) =     -0.41869470d0
      e( 13) =      0.97547610d0
      s( 13) =     -0.14410540d0
      e( 14) =      0.12311430d0
      s( 14) =      0.59581340d0
      e( 15) =      0.04487950d0
      s( 15) =      1.00000000d0
      e( 16) =    780.62030000d0
      p( 16) =     -0.00912170d0
      e( 17) =    184.00622000d0
      p( 17) =     -0.06800400d0
      e( 18) =     58.08446700d0
      p( 18) =     -0.25976810d0
      e( 19) =     20.75979500d0
      p( 19) =     -0.50601380d0
      e( 20) =      7.59345150d0
      p( 20) =     -0.34190820d0
      e( 21) =      4.02791730d0
      p( 21) =     -0.32729620d0
      e( 22) =      1.52647000d0
      p( 22) =     -0.54815000d0
      e( 23) =      0.55737020d0
      p( 23) =     -0.25066290d0
      e( 24) =      0.12100000d0
      p( 24) =      1.00000000d0
      e( 25) =     23.92931600d0
      d( 25) =     -0.06349210d0
      e( 26) =      6.39990130d0
      d( 26) =     -0.27839130d0
      e( 27) =      1.93174170d0
      d( 27) =     -0.49381950d0
      e( 28) =      0.51152790d0
      d( 28) =     -0.48626940d0
      e( 29) =      0.09000000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c co  (15s,9p,5d) -> [5s,3p,2d]
c 
  260 continue
c
      e(  1) =  67981.04200000d0
      s(  1) =     -0.00170240d0
      e(  2) =  10193.42800000d0
      s(  2) =     -0.01303860d0
      e(  3) =   2313.18140000d0
      s(  3) =     -0.06518800d0
      e(  4) =    650.07779000d0
      s(  4) =     -0.22502900d0
      e(  5) =    210.06015000d0
      s(  5) =     -0.46914570d0
      e(  6) =     71.77449800d0
      s(  6) =     -0.36865860d0
      e(  7) =    139.32221000d0
      s(  7) =      0.10555780d0
      e(  8) =     16.00278600d0
      s(  8) =     -0.62009540d0
      e(  9) =      6.49193530d0
      s(  9) =     -0.45397250d0
      e( 10) =     11.91039400d0
      s( 10) =     -0.21912730d0
      e( 11) =      1.89041050d0
      s( 11) =      0.71142010d0
      e( 12) =      0.73022780d0
      s( 12) =      0.41922480d0
      e( 13) =      1.05860200d0
      s( 13) =      0.13928930d0
      e( 14) =      0.13009050d0
      s( 14) =     -0.58643150d0
      e( 15) =      0.04685300d0
      s( 15) =      1.00000000d0
      e( 16) =    852.79139000d0
      p( 16) =     -0.00902660d0
      e( 17) =    201.06964000d0
      p( 17) =     -0.06750980d0
      e( 18) =     63.52134500d0
      p( 18) =     -0.25902510d0
      e( 19) =     22.74864900d0
      p( 19) =     -0.50639190d0
      e( 20) =      8.34277550d0
      p( 20) =     -0.34185210d0
      e( 21) =      4.44760870d0
      p( 21) =     -0.32895350d0
      e( 22) =      1.68587800d0
      p( 22) =     -0.54729940d0
      e( 23) =      0.61512090d0
      p( 23) =     -0.25001630d0
      e( 24) =      0.12660000d0
      p( 24) =      1.00000000d0
      e( 25) =     26.53246900d0
      d( 25) =     -0.06447590d0
      e( 26) =      7.12589450d0
      d( 26) =     -0.28236590d0
      e( 27) =      2.15476730d0
      d( 27) =     -0.49565360d0
      e( 28) =      0.56886000d0
      d( 28) =     -0.48065190d0
      e( 29) =      0.09700000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c ni  (15s,9p,5d) -> [5s,3p,2d]
c 
  280 continue
c
      e(  1) =  72509.04200000d0
      s(  1) =     -0.00172080d0
      e(  2) =  10879.17600000d0
      s(  2) =     -0.01316370d0
      e(  3) =   2471.64600000d0
      s(  3) =     -0.06565670d0
      e(  4) =    695.82606000d0
      s(  4) =     -0.22590270d0
      e(  5) =    225.37504000d0
      s(  5) =     -0.46891570d0
      e(  6) =     77.24015800d0
      s(  6) =     -0.36728410d0
      e(  7) =    150.36412000d0
      s(  7) =      0.10612160d0
      e(  8) =     17.33109200d0
      s(  8) =     -0.62289970d0
      e(  9) =      7.04885550d0
      s(  9) =     -0.45126310d0
      e( 10) =     13.00639600d0
      s( 10) =     -0.21955900d0
      e( 11) =      2.06828210d0
      s( 11) =      0.71117420d0
      e( 12) =      0.79634340d0
      s( 12) =      0.41996870d0
      e( 13) =      1.14076120d0
      s( 13) =      0.13450420d0
      e( 14) =      0.13649560d0
      s( 14) =     -0.57911790d0
      e( 15) =      0.04864020d0
      s( 15) =      1.00000000d0
      e( 16) =    925.37823000d0
      p( 16) =      0.00898080d0
      e( 17) =    218.37918000d0
      p( 17) =      0.06725680d0
      e( 18) =     69.07589400d0
      p( 18) =      0.25871990d0
      e( 19) =     24.79418600d0
      p( 19) =      0.50670800d0
      e( 20) =      9.11772700d0
      p( 20) =      0.34125310d0
      e( 21) =      4.88655560d0
      p( 21) =      0.33026540d0
      e( 22) =      1.85205680d0
      p( 22) =      0.54657530d0
      e( 23) =      0.67489050d0
      p( 23) =      0.24968220d0
      e( 24) =      0.13510000d0
      p( 24) =      1.00000000d0
      e( 25) =     29.22965900d0
      d( 25) =     -0.06539530d0
      e( 26) =      7.87891450d0
      d( 26) =     -0.28601300d0
      e( 27) =      2.38611600d0
      d( 27) =     -0.49715640d0
      e( 28) =      0.62824370d0
      d( 28) =     -0.47563690d0
      e( 29) =      0.10400000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c cu  (15s,9p,5d) -> [5s,3p,2d]
c
  300 continue
c
      e(  1) =  80289.62000000d0
      s(  1) =     -0.00165620d0
      e(  2) =  12027.33800000d0
      s(  2) =     -0.01270930d0
      e(  3) =   2724.25750000d0
      s(  3) =     -0.06385180d0
      e(  4) =    763.56173000d0
      s(  4) =     -0.22211540d0
      e(  5) =    246.06459000d0
      s(  5) =     -0.46860490d0
      e(  6) =     83.86836300d0
      s(  6) =     -0.37337930d0
      e(  7) =    161.79726000d0
      s(  7) =      0.10667590d0
      e(  8) =     18.72537500d0
      s(  8) =     -0.62459430d0
      e(  9) =      7.63641650d0
      s(  9) =     -0.44967240d0
      e( 10) =     14.15082900d0
      s( 10) =     -0.21980770d0
      e( 11) =      2.25283040d0
      s( 11) =      0.71087600d0
      e( 12) =      0.86448860d0
      s( 12) =      0.42065710d0
      e( 13) =      1.22309630d0
      s( 13) =      0.13031690d0
      e( 14) =      0.14297710d0
      s( 14) =     -0.57086010d0
      e( 15) =      0.05046030d0
      s( 15) =      1.00000000d0
      e( 16) =   1002.97450000d0
      p( 16) =      0.00891430d0
      e( 17) =    236.62530000d0
      p( 17) =      0.06697040d0
      e( 18) =     74.89232100d0
      p( 18) =      0.25841470d0
      e( 19) =     26.93125200d0
      p( 19) =      0.50706200d0
      e( 20) =      9.92677590d0
      p( 20) =      0.34075110d0
      e( 21) =      5.34466480d0
      p( 21) =      0.33137450d0
      e( 22) =      2.02474800d0
      p( 22) =      0.54598710d0
      e( 23) =      0.73663310d0
      p( 23) =      0.24947670d0
      e( 24) =      0.14100000d0
      p( 24) =      1.00000000d0
      e( 25) =     31.81266700d0
      d( 25) =     -0.06688910d0
      e( 26) =      8.60587160d0
      d( 26) =     -0.29074010d0
      e( 27) =      2.60934110d0
      d( 27) =     -0.49841940d0
      e( 28) =      0.68521350d0
      d( 28) =     -0.46972510d0
      e( 29) =      0.11000000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c zn  (15s,9p,5d) -> [5s,3p,2d]
c 
  320 continue
c
      e(  1) =  82904.22000000d0
      s(  1) =     -0.00173130d0
      e(  2) =  12444.23200000d0
      s(  2) =     -0.01323280d0
      e(  3) =   2829.85290000d0
      s(  3) =     -0.06589010d0
      e(  4) =    797.89288000d0
      s(  4) =     -0.22619880d0
      e(  5) =    259.06473000d0
      s(  5) =     -0.46839110d0
      e(  6) =     89.07951200d0
      s(  6) =     -0.36691560d0
      e(  7) =    173.68172000d0
      s(  7) =     -0.10716240d0
      e(  8) =     20.16649700d0
      s(  8) =      0.62649820d0
      e(  9) =      8.24708190d0
      s(  9) =      0.44782060d0
      e( 10) =     15.31658400d0
      s( 10) =     -0.22123750d0
      e( 11) =      2.45574930d0
      s( 11) =      0.70919110d0
      e( 12) =      0.95487770d0
      s( 12) =      0.42241470d0
      e( 13) =      1.41000340d0
      s( 13) =     -0.14046520d0
      e( 14) =      0.16934410d0
      s( 14) =      0.60127450d0
      e( 15) =      0.05922100d0
      s( 15) =      1.00000000d0
      e( 16) =   1085.17850000d0
      p( 16) =      0.00882600d0
      e( 17) =    256.18093000d0
      p( 17) =      0.06644550d0
      e( 18) =     81.14025300d0
      p( 18) =      0.25742460d0
      e( 19) =     29.22252000d0
      p( 19) =      0.50714550d0
      e( 20) =     10.79369500d0
      p( 20) =      0.34143560d0
      e( 21) =      5.84129040d0
      p( 21) =      0.33121250d0
      e( 22) =      2.22636600d0
      p( 22) =      0.54637610d0
      e( 23) =      0.82116400d0
      p( 23) =      0.24681440d0
      e( 24) =      0.16900000d0
      p( 24) =      1.00000000d0
      e( 25) =     38.09346700d0
      d( 25) =     -0.06069660d0
      e( 26) =     10.42375600d0
      d( 26) =     -0.27605000d0
      e( 27) =      3.25325210d0
      d( 27) =     -0.49826380d0
      e( 28) =      0.90975290d0
      d( 28) =     -0.46898980d0
      e( 29) =      0.17200000d0
      d( 29) =      1.00000000d0
c
 1000 return
      end
      subroutine dftdzvp_4(e,s,p,d,n)
c
c ----- dzvp_dft basis 
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-30
      go to (100,120,140,160,180,200),nn
c
c ga  (15s,11p,5d) -> [5s,4p,2d]
c
  100 continue
c
      e(  1) =  88374.04500000d0
      s(  1) =      0.00173580d0
      e(  2) =  13268.90500000d0
      s(  2) =      0.01326050d0
      e(  3) =   3018.79410000d0
      s(  3) =      0.06597590d0
      e(  4) =    851.78841000d0
      s(  4) =      0.22626580d0
      e(  5) =    276.87619000d0
      s(  5) =      0.46810110d0
      e(  6) =     95.34532400d0
      s(  6) =      0.36688220d0
      e(  7) =    185.96030000d0
      s(  7) =     -0.10764530d0
      e(  8) =     21.67074900d0
      s(  8) =      0.62772650d0
      e(  9) =      8.88938940d0
      s(  9) =      0.44663790d0
      e( 10) =     16.53362600d0
      s( 10) =      0.22265950d0
      e( 11) =      2.66660230d0
      s( 11) =     -0.70817740d0
      e( 12) =      1.05154140d0
      s( 12) =     -0.42338460d0
      e( 13) =      1.56254650d0
      s( 13) =     -0.15772530d0
      e( 14) =      0.20761150d0
      s( 14) =      0.63911790d0
      e( 15) =      0.07354390d0
      s( 15) =      1.00000000d0
      e( 16) =   1163.19550000d0
      p( 16) =     -0.00884070d0
      e( 17) =    274.89727000d0
      p( 17) =     -0.06650620d0
      e( 18) =     87.25598900d0
      p( 18) =     -0.25736020d0
      e( 19) =     31.53486400d0
      p( 19) =     -0.50652980d0
      e( 20) =     11.70061100d0
      p( 20) =     -0.34114500d0
      e( 21) =      6.38766730d0
      p( 21) =     -0.32781640d0
      e( 22) =      2.46670220d0
      p( 22) =     -0.54244220d0
      e( 23) =      0.93619400d0
      p( 23) =     -0.25055940d0
      e( 24) =      0.38127270d0
      p( 24) =     -0.21248640d0
      e( 25) =      0.12550960d0
      p( 25) =     -0.55175480d0
      e( 26) =      0.04107170d0
      p( 26) =      1.00000000d0
      e( 27) =     38.05827200d0
      d( 27) =     -0.07003580d0
      e( 28) =     10.36152200d0
      d( 28) =     -0.30525740d0
      e( 29) =      3.16035230d0
      d( 29) =     -0.51672600d0
      e( 30) =      0.84771950d0
      d( 30) =     -0.42780520d0
      e( 31) =      0.16200000d0
      d( 31) =      1.00000000d0
c
      go to 1000
c
c ge  (15s,11p,5d) -> [5s,4p,2d]
c 
  120 continue
c
      e(  1) = 100666.23000000d0
      s(  1) =     -0.00160060d0
      e(  2) =  15061.97300000d0
      s(  2) =     -0.01230940d0
      e(  3) =   3404.19460000d0
      s(  3) =     -0.06220620d0
      e(  4) =    951.21698000d0
      s(  4) =     -0.21834360d0
      e(  5) =    305.64810000d0
      s(  5) =     -0.46753750d0
      e(  6) =    103.88138000d0
      s(  6) =     -0.37971320d0
      e(  7) =    198.54803000d0
      s(  7) =     -0.10816690d0
      e(  8) =     23.26486500d0
      s(  8) =      0.62661300d0
      e(  9) =      9.58350040d0
      s(  9) =      0.44779000d0
      e( 10) =     17.78910200d0
      s( 10) =     -0.22474440d0
      e( 11) =      2.88957350d0
      s( 11) =      0.70960980d0
      e( 12) =      1.16092590d0
      s( 12) =      0.42198270d0
      e( 13) =      1.78408380d0
      s( 13) =     -0.17767660d0
      e( 14) =      0.25387400d0
      s( 14) =      0.66761280d0
      e( 15) =      0.09219810d0
      s( 15) =      1.00000000d0
      e( 16) =   1316.93060000d0
      p( 16) =      0.00804890d0
      e( 17) =    310.76532000d0
      p( 17) =      0.06160660d0
      e( 18) =     98.04171600d0
      p( 18) =      0.24688940d0
      e( 19) =     35.14999100d0
      p( 19) =      0.50664840d0
      e( 20) =     12.94924700d0
      p( 20) =      0.35571050d0
      e( 21) =      6.94761470d0
      p( 21) =      0.32776490d0
      e( 22) =      2.70378890d0
      p( 22) =      0.54289770d0
      e( 23) =      1.04848090d0
      p( 23) =      0.24668860d0
      e( 24) =      0.44171250d0
      p( 24) =      0.25576960d0
      e( 25) =      0.16060940d0
      p( 25) =      0.53783290d0
      e( 26) =      0.05740760d0
      p( 26) =      1.00000000d0
      e( 27) =     43.66375100d0
      d( 27) =      0.06646480d0
      e( 28) =     11.97921000d0
      d( 28) =      0.29829690d0
      e( 29) =      3.72278640d0
      d( 29) =      0.52032600d0
      e( 30) =      1.04237150d0
      d( 30) =      0.42028940d0
      e( 31) =      0.21800000d0
      d( 31) =      1.00000000d0
c
      go to 1000
c
c as  (15s,11p,5d) -> [5s,4p,2d]
c 
  140 continue
c
      e(  1) = 107365.86000000d0
      s(  1) =     -0.00159570d0
      e(  2) =  16064.05300000d0
      s(  2) =     -0.01227220d0
      e(  3) =   3630.65180000d0
      s(  3) =     -0.06203620d0
      e(  4) =   1014.52830000d0
      s(  4) =     -0.21786570d0
      e(  5) =    326.07429000d0
      s(  5) =     -0.46721080d0
      e(  6) =    110.86519000d0
      s(  6) =     -0.38057830d0
      e(  7) =    211.62924000d0
      s(  7) =     -0.10860480d0
      e(  8) =     24.88731200d0
      s(  8) =      0.62711800d0
      e(  9) =     10.28619000d0
      s(  9) =      0.44730110d0
      e( 10) =     19.09051400d0
      s( 10) =     -0.22701130d0
      e( 11) =      3.12028380d0
      s( 11) =      0.71378230d0
      e( 12) =      1.27513510d0
      s( 12) =      0.41802480d0
      e( 13) =      2.02023070d0
      s( 13) =     -0.19448640d0
      e( 14) =      0.30320860d0
      s( 14) =      0.68715010d0
      e( 15) =      0.11132560d0
      s( 15) =      1.00000000d0
      e( 16) =   1416.24090000d0
      p( 16) =      0.00795610d0
      e( 17) =    334.27920000d0
      p( 17) =      0.06103730d0
      e( 18) =    105.52400000d0
      p( 18) =      0.24549260d0
      e( 19) =     37.88714000d0
      p( 19) =      0.50625540d0
      e( 20) =     13.98761200d0
      p( 20) =      0.35733750d0
      e( 21) =      7.52934580d0
      p( 21) =     -0.32758040d0
      e( 22) =      2.96102690d0
      p( 22) =     -0.54296510d0
      e( 23) =      1.17062320d0
      p( 23) =     -0.24337570d0
      e( 24) =      0.19623060d0
      p( 24) =     -0.54879520d0
      e( 25) =      0.52522100d0
      p( 25) =     -0.27959730d0
      e( 26) =      0.07047480d0
      p( 26) =      1.00000000d0
      e( 27) =     49.42882000d0
      d( 27) =      0.06367440d0
      e( 28) =     13.64811400d0
      d( 28) =      0.29272500d0
      e( 29) =      4.30529590d0
      d( 29) =      0.52334170d0
      e( 30) =      1.24664460d0
      d( 30) =      0.41420440d0
      e( 31) =      0.27300000d0
      d( 31) =      1.00000000d0
c
      go to 1000
c
c se  (15s,11p,5d) -> [5s,4p,2d]
c
  160 continue
c
      e(  1) = 114288.76000000d0
      s(  1) =     -0.00159100d0
      e(  2) =  17099.74000000d0
      s(  2) =     -0.01223620d0
      e(  3) =   3864.67620000d0
      s(  3) =     -0.06187230d0
      e(  4) =   1079.95320000d0
      s(  4) =     -0.21740280d0
      e(  5) =    347.18530000d0
      s(  5) =     -0.46689170d0
      e(  6) =    118.08358000d0
      s(  6) =     -0.38142020d0
      e(  7) =    225.12776000d0
      s(  7) =     -0.10902020d0
      e(  8) =     26.56506800d0
      s(  8) =      0.62756290d0
      e(  9) =     11.01558300d0
      s(  9) =      0.44686610d0
      e( 10) =     20.43701600d0
      s( 10) =     -0.22942090d0
      e( 11) =      3.36049730d0
      s( 11) =      0.71970400d0
      e( 12) =      1.39405050d0
      s( 12) =      0.41254180d0
      e( 13) =      2.26452780d0
      s( 13) =     -0.20832190d0
      e( 14) =      0.35443570d0
      s( 14) =      0.70415150d0
      e( 15) =      0.13190640d0
      s( 15) =      1.00000000d0
      e( 16) =   1519.28300000d0
      p( 16) =      0.00786850d0
      e( 17) =    358.72461000d0
      p( 17) =      0.06048660d0
      e( 18) =    113.31008000d0
      p( 18) =      0.24410710d0
      e( 19) =     40.73758100d0
      p( 19) =      0.50586030d0
      e( 20) =     15.06974600d0
      p( 20) =      0.35897370d0
      e( 21) =      8.12948940d0
      p( 21) =      0.32820520d0
      e( 22) =      3.22743270d0
      p( 22) =      0.54386750d0
      e( 23) =      1.29509820d0
      p( 23) =      0.23880120d0
      e( 24) =      0.61261980d0
      p( 24) =      0.30877930d0
      e( 25) =      0.22722670d0
      p( 25) =      0.54470870d0
      e( 26) =      0.08062480d0
      p( 26) =      1.00000000d0
      e( 27) =     55.37210800d0
      d( 27) =      0.06143620d0
      e( 28) =     15.37296300d0
      d( 28) =      0.28821940d0
      e( 29) =      4.90922880d0
      d( 29) =      0.52597970d0
      e( 30) =      1.46024160d0
      d( 30) =      0.40904990d0
      e( 31) =      0.32100000d0
      d( 31) =      1.00000000d0
c
      go to 1000
c
c br  (15s,11p,5d) -> [5s,4p,2d]
c 
  180 continue
c
      e(  1) = 115354.10000000d0
      s(  1) =      0.00168940d0
      e(  2) =  17308.39000000d0
      s(  2) =      0.01292180d0
      e(  3) =   3932.85340000d0
      s(  3) =      0.06455660d0
      e(  4) =   1107.77230000d0
      s(  4) =      0.22287210d0
      e(  5) =    359.63336000d0
      s(  5) =      0.46683360d0
      e(  6) =    123.69988000d0
      s(  6) =      0.37268700d0
      e(  7) =    239.12180000d0
      s(  7) =      0.10936400d0
      e(  8) =     28.26812700d0
      s(  8) =     -0.62943770d0
      e(  9) =     11.75056600d0
      s(  9) =     -0.44498710d0
      e( 10) =     21.82996400d0
      s( 10) =      0.23187340d0
      e( 11) =      3.60882570d0
      s( 11) =     -0.72724570d0
      e( 12) =      1.51648650d0
      s( 12) =     -0.40558660d0
      e( 13) =      2.52093670d0
      s( 13) =      0.22026260d0
      e( 14) =      0.40934150d0
      s( 14) =     -0.71631210d0
      e( 15) =      0.15309530d0
      s( 15) =      1.00000000d0
      e( 16) =   1580.37390000d0
      p( 16) =      0.00817570d0
      e( 17) =    373.09755000d0
      p( 17) =      0.06255250d0
      e( 18) =    118.35233000d0
      p( 18) =      0.24847450d0
      e( 19) =     42.85895500d0
      p( 19) =      0.50541370d0
      e( 20) =     15.97787400d0
      p( 20) =      0.35234430d0
      e( 21) =      8.75332750d0
      p( 21) =      0.32835040d0
      e( 22) =      3.51603350d0
      p( 22) =      0.54379910d0
      e( 23) =      1.43073780d0
      p( 23) =      0.23578590d0
      e( 24) =      0.70915080d0
      p( 24) =     -0.32441620d0
      e( 25) =      0.26568350d0
      p( 25) =     -0.53954160d0
      e( 26) =      0.09439950d0
      p( 26) =      1.00000000d0
      e( 27) =     61.51441400d0
      d( 27) =      0.05957770d0
      e( 28) =     17.16198300d0
      d( 28) =      0.28437810d0
      e( 29) =      5.53847060d0
      d( 29) =      0.52818560d0
      e( 30) =      1.68481660d0
      d( 30) =      0.40477240d0
      e( 31) =      0.36200000d0
      d( 31) =      1.00000000d0
c
      go to 1000
c
c kr  (15s,11p,5d) -> [5s,4p,2d]
c
  200 continue
c
      e(  1) = 121095.87000000d0
      s(  1) =     -0.00170620d0
      e(  2) =  18179.49900000d0
      s(  2) =     -0.01303720d0
      e(  3) =   4135.02440000d0
      s(  3) =     -0.06499150d0
      e(  4) =   1166.56060000d0
      s(  4) =     -0.22366780d0
      e(  5) =    379.52584000d0
      s(  5) =     -0.46658390d0
      e(  6) =    130.87605000d0
      s(  6) =     -0.37150060d0
      e(  7) =    253.48193000d0
      s(  7) =      0.10972650d0
      e(  8) =     30.04623200d0
      s(  8) =     -0.63018010d0
      e(  9) =     12.52578900d0
      s(  9) =     -0.44424480d0
      e( 10) =     23.26909800d0
      s( 10) =     -0.23436070d0
      e( 11) =      3.86788750d0
      s( 11) =      0.73518940d0
      e( 12) =      1.64368020d0
      s( 12) =      0.39837980d0
      e( 13) =      2.79045650d0
      s( 13) =      0.23057670d0
      e( 14) =      0.46764850d0
      s( 14) =     -0.72494650d0
      e( 15) =      0.17508990d0
      s( 15) =      1.00000000d0
      e( 16) =   1659.88440000d0
      p( 16) =     -0.00831950d0
      e( 17) =    392.52006000d0
      p( 17) =     -0.06339410d0
      e( 18) =    124.89496000d0
      p( 18) =     -0.25001950d0
      e( 19) =     45.42858900d0
      p( 19) =     -0.50492660d0
      e( 20) =     17.01620900d0
      p( 20) =     -0.34979570d0
      e( 21) =      9.39873930d0
      p( 21) =     -0.32901420d0
      e( 22) =      3.81506190d0
      p( 22) =     -0.54381780d0
      e( 23) =      1.57176670d0
      p( 23) =     -0.23245680d0
      e( 24) =      0.81017450d0
      p( 24) =      0.33733380d0
      e( 25) =      0.30647470d0
      p( 25) =      0.53529310d0
      e( 26) =      0.10935400d0
      p( 26) =      1.00000000d0
      e( 27) =     67.81939900d0
      d( 27) =      0.05807190d0
      e( 28) =     19.00354100d0
      d( 28) =      0.28127750d0
      e( 29) =      6.18903150d0
      d( 29) =      0.53010520d0
      e( 30) =      1.91929950d0
      d( 30) =      0.40085330d0
      e( 31) =      0.40200000d0
      d( 31) =      1.00000000d0
c
1000  return
      end
      subroutine dftdzvp_5(e,s,p,d,n)
c
c ----- dzvp_dft basis [rb-cd]
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-36
      go to (100,120,140,160,180,200,220,240,260,280,300,320),nn
c
c rb  (18s,12p,6d) -> [6s,5p,2d]
c
  100 continue
c
      e(  1) = 131515.06000000d0
      s(  1) =     -0.00164990d0
      e(  2) =  19719.21700000d0
      s(  2) =     -0.01263720d0
      e(  3) =   4474.30400000d0
      s(  3) =     -0.06338420d0
      e(  4) =   1257.75080000d0
      s(  4) =     -0.22010850d0
      e(  5) =    139.81533000d0
      s(  5) =     -0.37748000d0
      e(  6) =    407.51700000d0
      s(  6) =     -0.46593210d0
      e(  7) =    267.84558000d0
      s(  7) =      0.11022850d0
      e(  8) =     32.00259900d0
      s(  8) =     -0.62605580d0
      e(  9) =     13.41194600d0
      s(  9) =     -0.44841620d0
      e( 10) =     24.68546100d0
      s( 10) =     -0.23786790d0
      e( 11) =      4.17669120d0
      s( 11) =      0.73124140d0
      e( 12) =      1.80933560d0
      s( 12) =      0.40378990d0
      e( 13) =      3.03795360d0
      s( 13) =      0.24708080d0
      e( 14) =      0.54666660d0
      s( 14) =     -0.72794530d0
      e( 15) =      0.22100440d0
      s( 15) =     -0.41950150d0
      e( 16) =      0.30079900d0
      s( 16) =     -0.14763920d0
      e( 17) =      0.03774790d0
      s( 17) =      0.76435710d0
      e( 18) =      0.01598400d0
      s( 18) =      1.00000000d0
      e( 19) =   1813.89280000d0
      p( 19) =      0.00791100d0
      e( 20) =    428.15812000d0
      p( 20) =      0.06090810d0
      e( 21) =    135.84109000d0
      p( 21) =      0.24442330d0
      e( 22) =     49.25288200d0
      p( 22) =      0.50442210d0
      e( 23) =     18.40875300d0
      p( 23) =      0.35775040d0
      e( 24) =     10.10238300d0
      p( 24) =      0.32762150d0
      e( 25) =      4.15214220d0
      p( 25) =      0.54185070d0
      e( 26) =      1.74137790d0
      p( 26) =      0.23299810d0
      e( 27) =      0.94123370d0
      p( 27) =     -0.34597010d0
      e( 28) =      0.37909040d0
      p( 28) =     -0.54081540d0
      e( 29) =      0.14350020d0
      p( 29) =      1.00000000d0
      e( 30) =      0.03580000d0
      p( 30) =      1.00000000d0
      e( 31) =    130.85515000d0
      d( 31) =      0.02027370d0
      e( 32) =     37.95294400d0
      d( 32) =      0.12666240d0
      e( 33) =     13.46733800d0
      d( 33) =      0.35776860d0
      e( 34) =      4.94247520d0
      d( 34) =      0.49204490d0
      e( 35) =      1.70833140d0
      d( 35) =      0.27985080d0
      e( 36) =      0.06000000d0
      d( 36) =      1.00000000d0
c
      go to 1000
c
c sr  (18s,12p,6d) -> [6s,5p,2d]
c 
  120 continue
c
      e(  1) = 139600.84000000d0
      s(  1) =     -0.00163780d0
      e(  2) =  20926.65900000d0
      s(  2) =     -0.01254990d0
      e(  3) =   4746.22760000d0
      s(  3) =     -0.06302380d0
      e(  4) =   1333.31110000d0
      s(  4) =     -0.21929390d0
      e(  5) =    431.68069000d0
      s(  5) =     -0.46579140d0
      e(  6) =    148.00238000d0
      s(  6) =     -0.37876580d0
      e(  7) =    283.06519000d0
      s(  7) =     -0.11056330d0
      e(  8) =     33.89344500d0
      s(  8) =      0.62673300d0
      e(  9) =     14.24983300d0
      s(  9) =      0.44769670d0
      e( 10) =     26.23897900d0
      s( 10) =     -0.24018350d0
      e( 11) =      4.45407780d0
      s( 11) =      0.74071440d0
      e( 12) =      1.94837340d0
      s( 12) =      0.39499940d0
      e( 13) =      3.31181170d0
      s( 13) =     -0.26237860d0
      e( 14) =      0.62127800d0
      s( 14) =      0.75298030d0
      e( 15) =      0.26072110d0
      s( 15) =      0.40203210d0
      e( 16) =      0.39263120d0
      s( 16) =     -0.17315450d0
      e( 17) =      0.05652420d0
      s( 17) =      0.74828080d0
      e( 18) =      0.02373960d0
      s( 18) =      1.00000000d0
      e( 19) =   1927.61250000d0
      p( 19) =      0.00785390d0
      e( 20) =    455.11466000d0
      p( 20) =      0.06056190d0
      e( 21) =    144.47812000d0
      p( 21) =      0.24348580d0
      e( 22) =     52.46280200d0
      p( 22) =      0.50396510d0
      e( 23) =     19.65178500d0
      p( 23) =      0.35888530d0
      e( 24) =     10.77580000d0
      p( 24) =     -0.33047700d0
      e( 25) =      4.46204210d0
      p( 25) =     -0.54191470d0
      e( 26) =      1.89430820d0
      p( 26) =     -0.22773870d0
      e( 27) =      1.05242250d0
      p( 27) =      0.37238700d0
      e( 28) =      0.44024900d0
      p( 28) =      0.53487950d0
      e( 29) =      0.17565030d0
      p( 29) =      1.00000000d0
      e( 30) =      0.04630000d0
      p( 30) =      1.00000000d0
      e( 31) =    143.12708000d0
      d( 31) =      0.01965120d0
      e( 32) =     41.62180400d0
      d( 32) =      0.12414180d0
      e( 33) =     14.83673500d0
      d( 33) =      0.35542700d0
      e( 34) =      5.49566550d0
      d( 34) =      0.49384180d0
      e( 35) =      1.93027760d0
      d( 35) =      0.27742540d0
      e( 36) =      0.91409510d0
      d( 36) =     -0.21602490d0
      e( 37) =      0.34593790d0
      d( 37) =     -0.27058490d0
      e( 38) =      0.12241880d0
      d( 38) =     -0.51606140d0
      e( 39) =      0.07800000d0
      d( 39) =      1.00000000d0
c
      go to 1000
c
c yttrium   (18s,12p,9d) -> [6s,5p,3d]
c 
  140 continue
c
      e(  1) = 147196.99000000d0
      s(  1) =      0.00163640d0
      e(  2) =  22066.57400000d0
      s(  2) =      0.01253720d0
      e(  3) =   5005.38940000d0
      s(  3) =      0.06295520d0
      e(  4) =   1406.38600000d0
      s(  4) =      0.21906560d0
      e(  5) =    455.53662000d0
      s(  5) =      0.46550180d0
      e(  6) =    156.28319000d0
      s(  6) =      0.37925050d0
      e(  7) =    298.95115000d0
      s(  7) =      0.11080660d0
      e(  8) =     35.78158500d0
      s(  8) =     -0.62938000d0
      e(  9) =     15.07100000d0
      s(  9) =     -0.44499430d0
      e( 10) =     27.84173800d0
      s( 10) =      0.24233880d0
      e( 11) =      4.73244060d0
      s( 11) =     -0.75309830d0
      e( 12) =      2.08408200d0
      s( 12) =     -0.38329470d0
      e( 13) =      3.62851340d0
      s( 13) =      0.27254800d0
      e( 14) =      0.69598990d0
      s( 14) =     -0.76602650d0
      e( 15) =      0.29185790d0
      s( 15) =     -0.39521020d0
      e( 16) =      0.42479370d0
      s( 16) =      0.18473830d0
      e( 17) =      0.06432540d0
      s( 17) =     -0.76524650d0
      e( 18) =      0.02596900d0
      s( 18) =      1.00000000d0
      e( 19) =   2045.56140000d0
      p( 19) =     -0.00779630d0
      e( 20) =    483.06531000d0
      p( 20) =     -0.06019970d0
      e( 21) =    153.45325000d0
      p( 21) =     -0.24248550d0
      e( 22) =     55.79203500d0
      p( 22) =     -0.50361480d0
      e( 23) =     20.93487500d0
      p( 23) =     -0.36004740d0
      e( 24) =     11.44753100d0
      p( 24) =     -0.33522340d0
      e( 25) =      4.76026960d0
      p( 25) =     -0.54332780d0
      e( 26) =      2.03958490d0
      p( 26) =     -0.21950770d0
      e( 27) =      1.18152980d0
      p( 27) =     -0.38298970d0
      e( 28) =      0.49856170d0
      p( 28) =     -0.52926420d0
      e( 29) =      0.20057950d0
      p( 29) =      1.00000000d0
      e( 30) =      0.05350000d0
      p( 30) =      1.00000000d0
      e( 31) =    163.47263000d0
      d( 31) =      0.01747850d0
      e( 32) =     47.64534400d0
      d( 32) =      0.11390840d0
      e( 33) =     17.06563500d0
      d( 33) =      0.34044510d0
      e( 34) =      6.39887150d0
      d( 34) =      0.49576760d0
      e( 35) =      2.30072060d0
      d( 35) =      0.29384990d0
      e( 36) =      1.50229570d0
      d( 36) =      0.19480340d0
      e( 37) =      0.45494000d0
      d( 37) =      0.47826090d0
      e( 38) =      0.12656150d0
      d( 38) =      0.57108450d0
      e( 39) =      0.02850000d0
      d( 39) =      1.00000000d0
c
      go to 1000
c
c zirconium (18s,12p,9d) -> [6s,5p,3d]
c 
  160 continue
c
      e(  1) = 154759.61000000d0
      s(  1) =      0.00163800d0
      e(  2) =  23203.44800000d0
      s(  2) =      0.01254620d0
      e(  3) =   5264.80420000d0
      s(  3) =      0.06297210d0
      e(  4) =   1479.97130000d0
      s(  4) =      0.21899160d0
      e(  5) =    479.71858000d0
      s(  5) =      0.46524230d0
      e(  6) =    164.71597000d0
      s(  6) =      0.37945770d0
      e(  7) =    314.93173000d0
      s(  7) =      0.11113470d0
      e(  8) =     37.80598700d0
      s(  8) =     -0.62929350d0
      e(  9) =     15.97023400d0
      s(  9) =     -0.44508230d0
      e( 10) =     29.46276600d0
      s( 10) =      0.24483390d0
      e( 11) =      5.03790260d0
      s( 11) =     -0.76072430d0
      e( 12) =      2.23582090d0
      s( 12) =     -0.37673390d0
      e( 13) =      3.94152210d0
      s( 13) =     -0.28196390d0
      e( 14) =      0.77735420d0
      s( 14) =      0.77376580d0
      e( 15) =      0.32766990d0
      s( 15) =      0.39367400d0
      e( 16) =      0.47665330d0
      s( 16) =     -0.18520310d0
      e( 17) =      0.07420470d0
      s( 17) =      0.74448720d0
      e( 18) =      0.02936770d0
      s( 18) =      1.00000000d0
      e( 19) =   2177.79450000d0
      p( 19) =     -0.00767910d0
      e( 20) =    514.19091000d0
      p( 20) =     -0.05947830d0
      e( 21) =    163.31121000d0
      p( 21) =     -0.24073040d0
      e( 22) =     59.39459000d0
      p( 22) =     -0.50320790d0
      e( 23) =     22.30765600d0
      p( 23) =     -0.36239510d0
      e( 24) =     12.17466600d0
      p( 24) =     -0.33741390d0
      e( 25) =      5.09742090d0
      p( 25) =     -0.54336430d0
      e( 26) =      2.20523200d0
      p( 26) =     -0.21533070d0
      e( 27) =      1.31250440d0
      p( 27) =     -0.39460160d0
      e( 28) =      0.55904420d0
      p( 28) =     -0.52429790d0
      e( 29) =      0.22701450d0
      p( 29) =      1.00000000d0
      e( 30) =      0.05960000d0
      p( 30) =      1.00000000d0
      e( 31) =    179.91428000d0
      d( 31) =      0.01655920d0
      e( 32) =     52.51868700d0
      d( 32) =      0.10970420d0
      e( 33) =     18.87025400d0
      d( 33) =      0.33469950d0
      e( 34) =      7.12777470d0
      d( 34) =      0.49743770d0
      e( 35) =      2.59548450d0
      d( 35) =      0.29760560d0
      e( 36) =      1.76629550d0
      d( 36) =     -0.20674700d0
      e( 37) =      0.55271310d0
      d( 37) =     -0.49562320d0
      e( 38) =      0.15940010d0
      d( 38) =     -0.53520370d0
      e( 39) =      0.03520000d0
      d( 39) =      1.00000000d0
c
      go to 1000
c
c niobium   (18s,12p,9d) -> [6s,5p,3d]
c 
  180 continue
c
      e(  1) = 161518.44000000d0
      s(  1) =      0.00165190d0
      e(  2) =  24228.12500000d0
      s(  2) =      0.01264130d0
      e(  3) =   5502.18400000d0
      s(  3) =      0.06333130d0
      e(  4) =   1548.80330000d0
      s(  4) =      0.21964900d0
      e(  5) =    502.95061000d0
      s(  5) =      0.46501910d0
      e(  6) =    173.06900000d0
      s(  6) =      0.37849350d0
      e(  7) =    331.47133000d0
      s(  7) =     -0.11140850d0
      e(  8) =     39.85041400d0
      s(  8) =      0.63032240d0
      e(  9) =     16.87194700d0
      s(  9) =      0.44403670d0
      e( 10) =     31.14005100d0
      s( 10) =      0.24713790d0
      e( 11) =      5.34781170d0
      s( 11) =     -0.76999480d0
      e( 12) =      2.38611710d0
      s( 12) =     -0.36848210d0
      e( 13) =      4.27129240d0
      s( 13) =     -0.28955120d0
      e( 14) =      0.86010710d0
      s( 14) =      0.78093940d0
      e( 15) =      0.36298840d0
      s( 15) =      0.39166100d0
      e( 16) =      0.53373310d0
      s( 16) =      0.18680770d0
      e( 17) =      0.08284850d0
      s( 17) =     -0.72514560d0
      e( 18) =      0.03221350d0
      s( 18) =      1.00000000d0
      e( 19) =   2299.55780000d0
      p( 19) =     -0.00764980d0
      e( 20) =    543.12805000d0
      p( 20) =     -0.05928460d0
      e( 21) =    172.64752000d0
      p( 21) =     -0.24012410d0
      e( 22) =     62.88070000d0
      p( 22) =     -0.50286280d0
      e( 23) =     23.66290700d0
      p( 23) =     -0.36303490d0
      e( 24) =     12.91742300d0
      p( 24) =     -0.33996310d0
      e( 25) =      5.44252300d0
      p( 25) =     -0.54340970d0
      e( 26) =      2.37456510d0
      p( 26) =     -0.21094620d0
      e( 27) =      1.45169140d0
      p( 27) =     -0.40216290d0
      e( 28) =      0.62284850d0
      p( 28) =     -0.52021130d0
      e( 29) =      0.25425670d0
      p( 29) =      1.00000000d0
      e( 30) =      0.06490000d0
      p( 30) =      1.00000000d0
      e( 31) =    194.69324000d0
      d( 31) =      0.01611910d0
      e( 32) =     56.94875000d0
      d( 32) =      0.10768990d0
      e( 33) =     20.54099500d0
      d( 33) =      0.33177670d0
      e( 34) =      7.81935620d0
      d( 34) =      0.49793790d0
      e( 35) =      2.88433990d0
      d( 35) =      0.29792100d0
      e( 36) =      2.03303600d0
      d( 36) =     -0.21538580d0
      e( 37) =      0.65209330d0
      d( 37) =     -0.50627150d0
      e( 38) =      0.19238670d0
      d( 38) =     -0.51085220d0
      e( 39) =      0.04170000d0
      d( 39) =      1.00000000d0
c
      go to 1000
c
c molybdenum (18s,12p,9d) -> [6s,5p,3d]
c
  200 continue
c
      e(  1) = 170343.94000000d0
      s(  1) =     -0.00164230d0
      e(  2) =  25548.85900000d0
      s(  2) =     -0.01257100d0
      e(  3) =   5800.48870000d0
      s(  3) =     -0.06303610d0
      e(  4) =   1632.07850000d0
      s(  4) =     -0.21893680d0
      e(  5) =    529.78964000d0
      s(  5) =     -0.46475200d0
      e(  6) =    182.22550000d0
      s(  6) =     -0.37972610d0
      e(  7) =    348.33319000d0
      s(  7) =      0.11170180d0
      e(  8) =     41.97860300d0
      s(  8) =     -0.63043450d0
      e(  9) =     17.81851700d0
      s(  9) =     -0.44392430d0
      e( 10) =     32.85854300d0
      s( 10) =     -0.24945020d0
      e( 11) =      5.67184380d0
      s( 11) =      0.77815760d0
      e( 12) =      2.54296260d0
      s( 12) =      0.36142870d0
      e( 13) =      4.61214840d0
      s( 13) =      0.29592070d0
      e( 14) =      0.94651160d0
      s( 14) =     -0.78503060d0
      e( 15) =      0.39941420d0
      s( 15) =     -0.39216300d0
      e( 16) =      0.58733550d0
      s( 16) =     -0.18498950d0
      e( 17) =      0.09093840d0
      s( 17) =      0.70542660d0
      e( 18) =      0.03475310d0
      s( 18) =      1.00000000d0
      e( 19) =   2428.04200000d0
      p( 19) =      0.00760410d0
      e( 20) =    573.59779000d0
      p( 20) =      0.05899760d0
      e( 21) =    182.42914000d0
      p( 21) =      0.23933600d0
      e( 22) =     66.51764700d0
      p( 22) =      0.50252540d0
      e( 23) =     25.07187400d0
      p( 23) =      0.36396970d0
      e( 24) =     13.67903000d0
      p( 24) =     -0.34271100d0
      e( 25) =      5.79586460d0
      p( 25) =     -0.54347500d0
      e( 26) =      2.54769630d0
      p( 26) =     -0.20650350d0
      e( 27) =      1.59626890d0
      p( 27) =      0.40849060d0
      e( 28) =      0.68782000d0
      p( 28) =      0.51685540d0
      e( 29) =      0.28147020d0
      p( 29) =      1.00000000d0
      e( 30) =      0.06970000d0
      p( 30) =      1.00000000d0
      e( 31) =    211.04075000d0
      d( 31) =     -0.01557090d0
      e( 32) =     61.82259100d0
      d( 32) =     -0.10513940d0
      e( 33) =     22.36574800d0
      d( 33) =     -0.32805760d0
      e( 34) =      8.56872670d0
      d( 34) =     -0.49873000d0
      e( 35) =      3.19400650d0
      d( 35) =     -0.29980070d0
      e( 36) =      2.30404010d0
      d( 36) =     -0.22243020d0
      e( 37) =      0.75354230d0
      d( 37) =     -0.51335610d0
      e( 38) =      0.22590200d0
      d( 38) =     -0.49278120d0
      e( 39) =      0.04820000d0
      d( 39) =      1.00000000d0
c
      go to 1000
c
c technecium (18s,12p,9d) -> [6s,5p,3d]
c 
  220 continue
c
      e(  1) = 179686.19000000d0
      s(  1) =     -0.00163020d0
      e(  2) =  26943.26300000d0
      s(  2) =     -0.01248390d0
      e(  3) =   6114.30290000d0
      s(  3) =     -0.06267660d0
      e(  4) =   1719.28350000d0
      s(  4) =     -0.21809350d0
      e(  5) =    557.74914000d0
      s(  5) =     -0.46449360d0
      e(  6) =    191.70466000d0
      s(  6) =     -0.38115960d0
      e(  7) =    365.60662000d0
      s(  7) =      0.11199610d0
      e(  8) =     44.18232100d0
      s(  8) =     -0.63013750d0
      e(  9) =     18.80250300d0
      s(  9) =     -0.44423140d0
      e( 10) =     34.62194100d0
      s( 10) =     -0.25167210d0
      e( 11) =      6.00807990d0
      s( 11) =      0.78536700d0
      e( 12) =      2.70512620d0
      s( 12) =      0.35534390d0
      e( 13) =      4.96301430d0
      s( 13) =      0.30124060d0
      e( 14) =      1.03565130d0
      s( 14) =     -0.78669860d0
      e( 15) =      0.43715540d0
      s( 15) =     -0.39442380d0
      e( 16) =      0.64301250d0
      s( 16) =     -0.17817230d0
      e( 17) =      0.09800660d0
      s( 17) =      0.67576940d0
      e( 18) =      0.03721640d0
      s( 18) =      1.00000000d0
      e( 19) =   2561.00520000d0
      p( 19) =      0.00759740d0
      e( 20) =    604.85698000d0
      p( 20) =      0.05821900d0
      e( 21) =    192.81618000d0
      p( 21) =      0.24019940d0
      e( 22) =     69.51824000d0
      p( 22) =      0.50846890d0
      e( 23) =     26.21057500d0
      p( 23) =      0.35774000d0
      e( 24) =    107.08955000d0
      p( 24) =     -0.02379320d0
      e( 25) =     12.23761300d0
      p( 25) =      0.49521800d0
      e( 26) =      4.49121180d0
      p( 26) =      0.58125430d0
      e( 27) =      1.84840300d0
      p( 27) =     -0.38179620d0
      e( 28) =      0.77112820d0
      p( 28) =     -0.54360580d0
      e( 29) =      0.31068710d0
      p( 29) =      1.00000000d0
      e( 30) =      0.07650000d0
      p( 30) =      1.00000000d0
      e( 31) =    228.83732000d0
      d( 31) =     -0.01496570d0
      e( 32) =     67.16576600d0
      d( 32) =     -0.10206900d0
      e( 33) =     24.37622000d0
      d( 33) =     -0.32311630d0
      e( 34) =      9.39361480d0
      d( 34) =     -0.49936460d0
      e( 35) =      3.53472280d0
      d( 35) =     -0.30381080d0
      e( 36) =      2.65249860d0
      d( 36) =     -0.22115620d0
      e( 37) =      0.89490990d0
      d( 37) =     -0.51069900d0
      e( 38) =      0.27688700d0
      d( 38) =     -0.48757960d0
      e( 39) =      0.06460000d0
      d( 39) =      1.00000000d0
c
      go to 1000
c
c ruthenium (18s,12p,9d) -> [6s,5p,3d]
c 
  240 continue
c
      e(  1) = 188363.70000000d0
      s(  1) =     -0.00162830d0
      e(  2) =  28246.15400000d0
      s(  2) =     -0.01246800d0
      e(  3) =   6410.45580000d0
      s(  3) =     -0.06259880d0
      e(  4) =   1802.76960000d0
      s(  4) =     -0.21784820d0
      e(  5) =    584.99810000d0
      s(  5) =     -0.46426620d0
      e(  6) =    201.14280000d0
      s(  6) =     -0.38163520d0
      e(  7) =    383.36292000d0
      s(  7) =     -0.11225130d0
      e(  8) =     46.40909900d0
      s(  8) =      0.63063010d0
      e(  9) =     19.79243600d0
      s(  9) =      0.44373510d0
      e( 10) =     36.43717600d0
      s( 10) =     -0.25381610d0
      e( 11) =      6.35162270d0
      s( 11) =      0.79359270d0
      e( 12) =      2.86751190d0
      s( 12) =      0.34823810d0
      e( 13) =      5.33114150d0
      s( 13) =      0.30560420d0
      e( 14) =      1.12727160d0
      s( 14) =     -0.78808340d0
      e( 15) =      0.47577670d0
      s( 15) =     -0.39627280d0
      e( 16) =      0.70971610d0
      s( 16) =      0.17436610d0
      e( 17) =      0.10185850d0
      s( 17) =     -0.66660110d0
      e( 18) =      0.03836270d0
      s( 18) =      1.00000000d0
      e( 19) =   2680.74990000d0
      p( 19) =     -0.00763190d0
      e( 20) =    633.20760000d0
      p( 20) =     -0.05848760d0
      e( 21) =    201.99995000d0
      p( 21) =     -0.24094530d0
      e( 22) =     72.96513700d0
      p( 22) =     -0.50838160d0
      e( 23) =     27.59114200d0
      p( 23) =     -0.35640230d0
      e( 24) =    112.37554000d0
      p( 24) =      0.02395380d0
      e( 25) =     12.97049400d0
      p( 25) =     -0.49591820d0
      e( 26) =      4.80004260d0
      p( 26) =     -0.57958460d0
      e( 27) =      2.00228240d0
      p( 27) =      0.39094790d0
      e( 28) =      0.83448040d0
      p( 28) =      0.53994330d0
      e( 29) =      0.33682390d0
      p( 29) =      1.00000000d0
      e( 30) =      0.08200000d0
      p( 30) =      1.00000000d0
      e( 31) =    244.46943000d0
      d( 31) =     -0.01475640d0
      e( 32) =     71.82758100d0
      d( 32) =     -0.10124690d0
      e( 33) =     26.13545500d0
      d( 33) =     -0.32211650d0
      e( 34) =     10.13205300d0
      d( 34) =     -0.49925980d0
      e( 35) =      3.85360720d0
      d( 35) =     -0.30267710d0
      e( 36) =      2.98509990d0
      d( 36) =      0.22214270d0
      e( 37) =      1.02875130d0
      d( 37) =      0.50996120d0
      e( 38) =      0.32463850d0
      d( 38) =      0.48174610d0
      e( 39) =      0.07870000d0
      d( 39) =      1.00000000d0
c
      go to 1000
c
c rhodium  (18s,12p,9d) -> [6s,5p,3d]
c 
  260 continue
c
      e(  1) = 194399.54000000d0
      s(  1) =     -0.00165570d0
      e(  2) =  29173.20200000d0
      s(  2) =     -0.01265920d0
      e(  3) =   6630.91150000d0
      s(  3) =     -0.06334160d0
      e(  4) =   1869.11580000d0
      s(  4) =     -0.21933290d0
      e(  5) =    608.35128000d0
      s(  5) =     -0.46413470d0
      e(  6) =    209.92021000d0
      s(  6) =     -0.37931390d0
      e(  7) =    401.64960000d0
      s(  7) =     -0.11246410d0
      e(  8) =     48.65711600d0
      s(  8) =      0.63202220d0
      e(  9) =     20.78386000d0
      s(  9) =      0.44233070d0
      e( 10) =     38.30187200d0
      s( 10) =     -0.25584840d0
      e( 11) =      6.70346620d0
      s( 11) =      0.80201830d0
      e( 12) =      3.03136470d0
      s( 12) =      0.34090330d0
      e( 13) =      5.71425940d0
      s( 13) =      0.30907200d0
      e( 14) =      1.21968480d0
      s( 14) =     -0.79137800d0
      e( 15) =      0.51315450d0
      s( 15) =     -0.39568220d0
      e( 16) =      0.77922840d0
      s( 16) =      0.17310670d0
      e( 17) =      0.10527620d0
      s( 17) =     -0.65524290d0
      e( 18) =      0.03941740d0
      s( 18) =      1.00000000d0
      e( 19) =   2807.51950000d0
      p( 19) =     -0.00764450d0
      e( 20) =    663.57601000d0
      p( 20) =     -0.05852840d0
      e( 21) =    211.94292000d0
      p( 21) =     -0.24092560d0
      e( 22) =     76.67761700d0
      p( 22) =     -0.50812330d0
      e( 23) =     29.06029800d0
      p( 23) =     -0.35620860d0
      e( 24) =    117.86437000d0
      p( 24) =      0.02412410d0
      e( 25) =     13.71922500d0
      p( 25) =     -0.49692910d0
      e( 26) =      5.11613930d0
      p( 26) =     -0.57769920d0
      e( 27) =      2.16362680d0
      p( 27) =      0.39793950d0
      e( 28) =      0.90177590d0
      p( 28) =      0.53619140d0
      e( 29) =      0.36471450d0
      p( 29) =      1.00000000d0
      e( 30) =      0.08820000d0
      p( 30) =      1.00000000d0
      e( 31) =    263.35664000d0
      d( 31) =     -0.01426860d0
      e( 32) =     77.38864000d0
      d( 32) =     -0.09902180d0
      e( 33) =     28.19765000d0
      d( 33) =     -0.31900270d0
      e( 34) =     10.97668700d0
      d( 34) =     -0.49992670d0
      e( 35) =      4.20680870d0
      d( 35) =     -0.30469890d0
      e( 36) =      3.33227140d0
      d( 36) =      0.22214710d0
      e( 37) =      1.16721760d0
      d( 37) =      0.50960830d0
      e( 38) =      0.37332670d0
      d( 38) =      0.47790620d0
      e( 39) =      0.09240000d0
      d( 39) =      1.00000000d0
c
      go to 1000
c
c palladium (18s,12p,9d) -> [6s,5p,3d]
c 
  280 continue
c
      e(  1) = 207193.10000000d0
      s(  1) =      0.00161660d0
      e(  2) =  31063.77200000d0
      s(  2) =      0.01238220d0
      e(  3) =   7047.74950000d0
      s(  3) =      0.06223230d0
      e(  4) =   1981.20010000d0
      s(  4) =      0.21692190d0
      e(  5) =    642.75338000d0
      s(  5) =      0.46381870d0
      e(  6) =    220.95334000d0
      s(  6) =      0.38327710d0
      e(  7) =    420.08860000d0
      s(  7) =      0.11274460d0
      e(  8) =     51.04383900d0
      s(  8) =     -0.63118580d0
      e(  9) =     21.86011700d0
      s(  9) =     -0.44318190d0
      e( 10) =     40.20133600d0
      s( 10) =      0.25796900d0
      e( 11) =      7.07600110d0
      s( 11) =     -0.80795260d0
      e( 12) =      3.20869310d0
      s( 12) =     -0.33617300d0
      e( 13) =      6.10419670d0
      s( 13) =     -0.31233860d0
      e( 14) =      1.31792490d0
      s( 14) =      0.79114630d0
      e( 15) =      0.55345370d0
      s( 15) =      0.39862190d0
      e( 16) =      0.82336030d0
      s( 16) =     -0.16230370d0
      e( 17) =      0.10882260d0
      s( 17) =      0.64480500d0
      e( 18) =      0.04012680d0
      s( 18) =      1.00000000d0
      e( 19) =   2972.42140000d0
      p( 19) =     -0.00750910d0
      e( 20) =    702.11490000d0
      p( 20) =     -0.05770110d0
      e( 21) =    224.06464000d0
      p( 21) =     -0.23901530d0
      e( 22) =     81.02367800d0
      p( 22) =     -0.50764660d0
      e( 23) =     30.72530500d0
      p( 23) =     -0.35898040d0
      e( 24) =    123.25971000d0
      p( 24) =      0.02423580d0
      e( 25) =     14.51192800d0
      p( 25) =     -0.49683310d0
      e( 26) =      5.44882860d0
      p( 26) =     -0.57700640d0
      e( 27) =      2.33229490d0
      p( 27) =      0.40367940d0
      e( 28) =      0.97112590d0
      p( 28) =      0.53336480d0
      e( 29) =      0.39282890d0
      p( 29) =      1.00000000d0
      e( 30) =      0.09040000d0
      p( 30) =      1.00000000d0
      e( 31) =    282.67187000d0
      d( 31) =      0.01383090d0
      e( 32) =     83.16509800d0
      d( 32) =      0.09683270d0
      e( 33) =     30.35853800d0
      d( 33) =      0.31556610d0
      e( 34) =     11.86274800d0
      d( 34) =      0.50070920d0
      e( 35) =      4.57100130d0
      d( 35) =      0.30724510d0
      e( 36) =      3.59365150d0
      d( 36) =      0.23146030d0
      e( 37) =      1.25997260d0
      d( 37) =      0.51503040d0
      e( 38) =      0.40041960d0
      d( 38) =      0.46550960d0
      e( 39) =      0.09520000d0
      d( 39) =      1.00000000d0
c
      go to 1000
c
c silver (18s,12p,9d) -> [6s,5p,3d]
c
  300 continue
c
      e(  1) = 215086.06000000d0
      s(  1) =     -0.00162820d0
      e(  2) =  32258.58800000d0
      s(  2) =     -0.01246210d0
      e(  3) =   7324.36440000d0
      s(  3) =     -0.06253390d0
      e(  4) =   2061.31010000d0
      s(  4) =     -0.21748460d0
      e(  5) =    669.74756000d0
      s(  5) =     -0.46366480d0
      e(  6) =    230.64332000d0
      s(  6) =     -0.38243120d0
      e(  7) =    439.15415000d0
      s(  7) =      0.11295710d0
      e(  8) =     53.42193900d0
      s(  8) =     -0.63200980d0
      e(  9) =     22.91685100d0
      s(  9) =     -0.44235420d0
      e( 10) =     42.15640600d0
      s( 10) =     -0.25990670d0
      e( 11) =      7.45258920d0
      s( 11) =      0.81502610d0
      e( 12) =      3.38347380d0
      s( 12) =      0.33020850d0
      e( 13) =      6.51203040d0
      s( 13) =      0.31484730d0
      e( 14) =      1.41646390d0
      s( 14) =     -0.79277250d0
      e( 15) =      0.59312070d0
      s( 15) =     -0.39906820d0
      e( 16) =      0.89276310d0
      s( 16) =     -0.16100010d0
      e( 17) =      0.11075100d0
      s( 17) =      0.64155710d0
      e( 18) =      0.04064750d0
      s( 18) =      1.00000000d0
      e( 19) =   3110.45820000d0
      p( 19) =      0.00750540d0
      e( 20) =    735.04937000d0
      p( 20) =      0.05765110d0
      e( 21) =    234.78029000d0
      p( 21) =      0.23881600d0
      e( 22) =     85.00222500d0
      p( 22) =      0.50739840d0
      e( 23) =     32.29478700d0
      p( 23) =      0.35908470d0
      e( 24) =    128.99157000d0
      p( 24) =     -0.02439550d0
      e( 25) =     15.30321300d0
      p( 25) =      0.49789270d0
      e( 26) =      5.78359000d0
      p( 26) =      0.57521850d0
      e( 27) =      2.50525600d0
      p( 27) =     -0.40911230d0
      e( 28) =      1.04232560d0
      p( 28) =     -0.53032570d0
      e( 29) =      0.42178770d0
      p( 29) =      1.00000000d0
      e( 30) =      0.09860000d0
      p( 30) =      1.00000000d0
      e( 31) =    310.27356000d0
      d( 31) =     -0.01280800d0
      e( 32) =     91.14433800d0
      d( 32) =     -0.09178170d0
      e( 33) =     33.21961700d0
      d( 33) =     -0.30792960d0
      e( 34) =     12.98314800d0
      d( 34) =     -0.50269520d0
      e( 35) =      5.01375660d0
      d( 35) =     -0.31585620d0
      e( 36) =      3.97898030d0
      d( 36) =      0.22894090d0
      e( 37) =      1.42204070d0
      d( 37) =      0.51065960d0
      e( 38) =      0.46260390d0
      d( 38) =      0.46606270d0
      e( 39) =      0.11620000d0
      d( 39) =      1.00000000d0
c
      go to 1000
c
c cadmium (18s,12p,9d) -> [6s,5p,3d]
c 
  320 continue
c
      e(  1) = 225379.46000000d0
      s(  1) =      0.00161940d0
      e(  2) =  33798.15800000d0
      s(  2) =      0.01239760d0
      e(  3) =   7671.64190000d0
      s(  3) =      0.06226560d0
      e(  4) =   2158.12710000d0
      s(  4) =      0.21683280d0
      e(  5) =    700.93157000d0
      s(  5) =      0.46341490d0
      e(  6) =    241.26502000d0
      s(  6) =      0.38357140d0
      e(  7) =    458.53463000d0
      s(  7) =      0.11319400d0
      e(  8) =     55.89407700d0
      s(  8) =     -0.63183820d0
      e(  9) =     24.03144200d0
      s(  9) =     -0.44252070d0
      e( 10) =     44.14981400d0
      s( 10) =      0.26190170d0
      e( 11) =      7.84985180d0
      s( 11) =     -0.81975650d0
      e( 12) =      3.57394040d0
      s( 12) =     -0.32664510d0
      e( 13) =      6.91484810d0
      s( 13) =     -0.31930360d0
      e( 14) =      1.52699530d0
      s( 14) =      0.79084490d0
      e( 15) =      0.64915300d0
      s( 15) =      0.40368590d0
      e( 16) =      0.97963690d0
      s( 16) =     -0.16898890d0
      e( 17) =      0.13500070d0
      s( 17) =      0.63925610d0
      e( 18) =      0.04921930d0
      s( 18) =      1.00000000d0
      e( 19) =   3286.54910000d0
      p( 19) =     -0.00737070d0
      e( 20) =    776.72654000d0
      p( 20) =     -0.05672580d0
      e( 21) =    248.06988000d0
      p( 21) =     -0.23638250d0
      e( 22) =     89.77214300d0
      p( 22) =     -0.50667760d0
      e( 23) =     34.11290200d0
      p( 23) =     -0.36269490d0
      e( 24) =    134.66571000d0
      p( 24) =      0.02451680d0
      e( 25) =     16.14285500d0
      p( 25) =     -0.49764830d0
      e( 26) =      6.14018790d0
      p( 26) =     -0.57472800d0
      e( 27) =      2.69031120d0
      p( 27) =      0.41315050d0
      e( 28) =      1.12636010d0
      p( 28) =      0.52994290d0
      e( 29) =      0.46189700d0
      p( 29) =      1.00000000d0
      e( 30) =      0.11240000d0
      p( 30) =      1.00000000d0
      e( 31) =    323.87850000d0
      d( 31) =      0.01303330d0
      e( 32) =     95.51482000d0
      d( 32) =      0.09261470d0
      e( 33) =     35.01335400d0
      d( 33) =      0.30850420d0
      e( 34) =     13.78705700d0
      d( 34) =      0.50113720d0
      e( 35) =      5.38572960d0
      d( 35) =      0.31328800d0
      e( 36) =      4.45921750d0
      d( 36) =      0.22298320d0
      e( 37) =      1.63783560d0
      d( 37) =      0.51181750d0
      e( 38) =      0.55511580d0
      d( 38) =      0.45882060d0
      e( 39) =      0.14780000d0
      d( 39) =      1.00000000d0
c
 1000 return
      end
      subroutine dftdzvp_6(e,s,p,d,n)
c
c ----- dzvp_dft basis [In-Cd]
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-48
      go to (100,120,140,160,180,200),nn
c
c indium (18s,14p,9d) -> [6s,5p,3d]
c
  100 continue
c
      e(  1) = 235861.12000000d0
      s(  1) =     -0.00161140d0
      e(  2) =  35365.28300000d0
      s(  2) =     -0.01233990d0
      e(  3) =   8025.25890000d0
      s(  3) =     -0.06202380d0
      e(  4) =   2256.76790000d0
      s(  4) =     -0.21624070d0
      e(  5) =    732.73538000d0
      s(  5) =     -0.46316740d0
      e(  6) =    252.11518000d0
      s(  6) =     -0.38461920d0
      e(  7) =    478.37678000d0
      s(  7) =     -0.11341490d0
      e(  8) =     58.40865200d0
      s(  8) =      0.63198630d0
      e(  9) =     25.16607200d0
      s(  9) =      0.44235820d0
      e( 10) =     46.20629700d0
      s( 10) =     -0.26374620d0
      e( 11) =      8.25219320d0
      s( 11) =      0.82570030d0
      e( 12) =      3.76163410d0
      s( 12) =      0.32178740d0
      e( 13) =      7.33772530d0
      s( 13) =      0.32327030d0
      e( 14) =      1.63800340d0
      s( 14) =     -0.79130410d0
      e( 15) =      0.70771280d0
      s( 15) =     -0.40529350d0
      e( 16) =      1.07961880d0
      s( 16) =      0.19167570d0
      e( 17) =      0.16346500d0
      s( 17) =     -0.67696900d0
      e( 18) =      0.06086760d0
      s( 18) =      1.00000000d0
      e( 19) =   3433.64120000d0
      p( 19) =     -0.00736530d0
      e( 20) =    811.31519000d0
      p( 20) =     -0.05674560d0
      e( 21) =    259.14879000d0
      p( 21) =     -0.23656630d0
      e( 22) =     93.89184300d0
      p( 22) =     -0.50642420d0
      e( 23) =     35.77110700d0
      p( 23) =     -0.36234340d0
      e( 24) =    140.41031000d0
      p( 24) =      0.02467220d0
      e( 25) =     17.02277900d0
      p( 25) =     -0.49653230d0
      e( 26) =      6.52928090d0
      p( 26) =     -0.57485980d0
      e( 27) =      2.88597930d0
      p( 27) =      0.41512220d0
      e( 28) =      1.21954380d0
      p( 28) =      0.52798920d0
      e( 29) =      0.51521360d0
      p( 29) =      0.14713520d0
      e( 30) =      0.27325220d0
      p( 30) =     -0.23920500d0
      e( 31) =      0.09897240d0
      p( 31) =     -0.56371240d0
      e( 32) =      0.03513300d0
      p( 32) =      1.00000000d0
      e( 33) =    337.48528000d0
      d( 33) =      0.01327010d0
      e( 34) =     99.57066100d0
      d( 34) =      0.09424830d0
      e( 35) =     36.59662500d0
      d( 35) =      0.31097020d0
      e( 36) =     14.49920500d0
      d( 36) =      0.50042930d0
      e( 37) =      5.69394580d0
      d( 37) =      0.30847180d0
      e( 38) =      4.37632230d0
      d( 38) =      0.27130870d0
      e( 39) =      1.52335700d0
      d( 39) =      0.55544820d0
      e( 40) =      0.47834560d0
      d( 40) =      0.38588030d0
      e( 41) =      0.12700000d0
      d( 41) =      1.00000000d0
c
      go to 1000
c
c tin  (18s,14p,9d) -> [6s,5p,3d]
c 
  120 continue
c
      e(  1) = 245047.36000000d0
      s(  1) =     -0.00161620d0
      e(  2) =  36750.02600000d0
      s(  2) =     -0.01237110d0
      e(  3) =   8342.77350000d0
      s(  3) =     -0.06213390d0
      e(  4) =   2347.47230000d0
      s(  4) =     -0.21639770d0
      e(  5) =    762.83620000d0
      s(  5) =     -0.46297490d0
      e(  6) =    262.73793000d0
      s(  6) =     -0.38444780d0
      e(  7) =    498.73283000d0
      s(  7) =     -0.11360520d0
      e(  8) =     60.95045800d0
      s(  8) =      0.63271820d0
      e(  9) =     26.30561000d0
      s(  9) =      0.44160860d0
      e( 10) =     48.30391300d0
      s( 10) =     -0.26553590d0
      e( 11) =      8.66714370d0
      s( 11) =      0.83088970d0
      e( 12) =      3.95646920d0
      s( 12) =      0.31767240d0
      e( 13) =      7.76814460d0
      s( 13) =     -0.32757650d0
      e( 14) =      1.75268360d0
      s( 14) =      0.79394680d0
      e( 15) =      0.77029610d0
      s( 15) =      0.40493410d0
      e( 16) =      1.20051550d0
      s( 16) =     -0.21484200d0
      e( 17) =      0.19470260d0
      s( 17) =      0.70261140d0
      e( 18) =      0.07427410d0
      s( 18) =      1.00000000d0
      e( 19) =   3581.69690000d0
      p( 19) =     -0.00736590d0
      e( 20) =    846.74434000d0
      p( 20) =     -0.05670970d0
      e( 21) =    270.73208000d0
      p( 21) =     -0.23633750d0
      e( 22) =     98.21837200d0
      p( 22) =     -0.50602840d0
      e( 23) =     37.49606700d0
      p( 23) =     -0.36260460d0
      e( 24) =    146.34338000d0
      p( 24) =      0.02481840d0
      e( 25) =     17.90996300d0
      p( 25) =     -0.49619260d0
      e( 26) =      6.91641320d0
      p( 26) =     -0.57442560d0
      e( 27) =      3.08060130d0
      p( 27) =      0.41930380d0
      e( 28) =      1.31196840d0
      p( 28) =      0.52890390d0
      e( 29) =      0.55868590d0
      p( 29) =      0.13917010d0
      e( 30) =      0.30090370d0
      p( 30) =     -0.29992500d0
      e( 31) =      0.11542730d0
      p( 31) =     -0.56151550d0
      e( 32) =      0.04340330d0
      p( 32) =      1.00000000d0
      e( 33) =    354.24033000d0
      d( 33) =     -0.01329820d0
      e( 34) =    104.71075000d0
      d( 34) =     -0.09432700d0
      e( 35) =     38.60672100d0
      d( 35) =     -0.31107820d0
      e( 36) =     15.37179000d0
      d( 36) =     -0.49958390d0
      e( 37) =      6.09218330d0
      d( 37) =     -0.30691380d0
      e( 38) =      4.84719880d0
      d( 38) =     -0.26645580d0
      e( 39) =      1.72875630d0
      d( 39) =     -0.55816140d0
      e( 40) =      0.56542830d0
      d( 40) =     -0.37615910d0
      e( 41) =      0.15400000d0
      d( 41) =      1.00000000d0
c
      go to 1000
c
c antimony  (18s,14p,9d) -> [6s,5p,3d]
c 
  140 continue
c
      e(  1) = 256073.33000000d0
      s(  1) =      0.00160780d0
      e(  2) =  38397.81700000d0
      s(  2) =      0.01231080d0
      e(  3) =   8714.34150000d0
      s(  3) =      0.06188220d0
      e(  4) =   2451.05140000d0
      s(  4) =      0.21578090d0
      e(  5) =    796.19247000d0
      s(  5) =      0.46274030d0
      e(  6) =    274.09077000d0
      s(  6) =      0.38552500d0
      e(  7) =    519.32174000d0
      s(  7) =     -0.11382730d0
      e(  8) =     63.60106500d0
      s(  8) =      0.63233450d0
      e(  9) =     27.51096500d0
      s(  9) =      0.44198750d0
      e( 10) =     50.44497400d0
      s( 10) =     -0.26733140d0
      e( 11) =      9.09715550d0
      s( 11) =      0.83517080d0
      e( 12) =      4.16049150d0
      s( 12) =      0.31448690d0
      e( 13) =      8.20927740d0
      s( 13) =      0.33195850d0
      e( 14) =      1.87050870d0
      s( 14) =     -0.79852200d0
      e( 15) =      0.83479070d0
      s( 15) =     -0.40279370d0
      e( 16) =      1.32617410d0
      s( 16) =     -0.23424290d0
      e( 17) =      0.22737370d0
      s( 17) =      0.72142250d0
      e( 18) =      0.08777690d0
      s( 18) =      1.00000000d0
      e( 19) =   3762.05370000d0
      p( 19) =      0.00727350d0
      e( 20) =    889.08808000d0
      p( 20) =      0.05612610d0
      e( 21) =    284.15403000d0
      p( 21) =      0.23492950d0
      e( 22) =    103.07294000d0
      p( 22) =      0.50553880d0
      e( 23) =     39.38422200d0
      p( 23) =      0.36468550d0
      e( 24) =    152.31598000d0
      p( 24) =      0.02495550d0
      e( 25) =     18.83057100d0
      p( 25) =     -0.49546160d0
      e( 26) =      7.31826960d0
      p( 26) =     -0.57443570d0
      e( 27) =      3.28440800d0
      p( 27) =     -0.42284120d0
      e( 28) =      1.41139340d0
      p( 28) =     -0.52859780d0
      e( 29) =      0.60814560d0
      p( 29) =     -0.13314470d0
      e( 30) =      0.34968180d0
      p( 30) =     -0.32125220d0
      e( 31) =      0.13927800d0
      p( 31) =     -0.55340510d0
      e( 32) =      0.05402620d0
      p( 32) =      1.00000000d0
      e( 33) =    381.57661000d0
      d( 33) =      0.01264010d0
      e( 34) =    112.70694000d0
      d( 34) =      0.09101250d0
      e( 35) =     41.53102700d0
      d( 35) =      0.30606040d0
      e( 36) =     16.54610900d0
      d( 36) =      0.50078230d0
      e( 37) =      6.57750210d0
      d( 37) =      0.31232280d0
      e( 38) =      5.32295220d0
      d( 38) =      0.26280880d0
      e( 39) =      1.93796680d0
      d( 39) =      0.56021200d0
      e( 40) =      0.65518290d0
      d( 40) =      0.36820200d0
      e( 41) =      0.18200000d0
      d( 41) =      1.00000000d0
c
      go to 1000
c
c tellurium  (18s,14p,9d) -> [6s,5p,3d]
c
  160 continue
c
      e(  1) = 265467.04000000d0
      s(  1) =     -0.00161370d0
      e(  2) =  39815.85700000d0
      s(  2) =     -0.01235020d0
      e(  3) =   9040.22220000d0
      s(  3) =     -0.06202540d0
      e(  4) =   2544.44690000d0
      s(  4) =     -0.21600780d0
      e(  5) =    827.31644000d0
      s(  5) =     -0.46256150d0
      e(  6) =    285.11675000d0
      s(  6) =     -0.38523610d0
      e(  7) =    540.45125000d0
      s(  7) =      0.11401640d0
      e(  8) =     66.27054800d0
      s(  8) =     -0.63271320d0
      e(  9) =     28.71637800d0
      s(  9) =     -0.44159600d0
      e( 10) =     52.63758800d0
      s( 10) =      0.26903760d0
      e( 11) =      9.53659520d0
      s( 11) =     -0.83962250d0
      e( 12) =      4.36728650d0
      s( 12) =     -0.31108860d0
      e( 13) =      8.66198540d0
      s( 13) =     -0.33633940d0
      e( 14) =      1.99155480d0
      s( 14) =      0.80481050d0
      e( 15) =      0.90078500d0
      s( 15) =      0.39905750d0
      e( 16) =      1.45509120d0
      s( 16) =      0.24955120d0
      e( 17) =      0.26021480d0
      s( 17) =     -0.73869600d0
      e( 18) =      0.10190780d0
      s( 18) =      1.00000000d0
      e( 19) =   3950.21790000d0
      p( 19) =     -0.00717370d0
      e( 20) =    933.93266000d0
      p( 20) =     -0.05540980d0
      e( 21) =    298.49500000d0
      p( 21) =     -0.23303180d0
      e( 22) =    108.24180000d0
      p( 22) =     -0.50490130d0
      e( 23) =     41.37776300d0
      p( 23) =     -0.36751170d0
      e( 24) =    158.46596000d0
      p( 24) =     -0.02509890d0
      e( 25) =     19.77174500d0
      p( 25) =      0.49491000d0
      e( 26) =      7.73011770d0
      p( 26) =      0.57431770d0
      e( 27) =      3.49381560d0
      p( 27) =      0.42660050d0
      e( 28) =      1.51529950d0
      p( 28) =      0.52769610d0
      e( 29) =      0.65961700d0
      p( 29) =      0.12771850d0
      e( 30) =      0.40644180d0
      p( 30) =      0.33878270d0
      e( 31) =      0.16253450d0
      p( 31) =      0.54186240d0
      e( 32) =      0.06224560d0
      p( 32) =      1.00000000d0
      e( 33) =    405.16882000d0
      d( 33) =     -0.01231970d0
      e( 34) =    119.78244000d0
      d( 34) =     -0.08928470d0
      e( 35) =     44.18133100d0
      d( 35) =     -0.30344280d0
      e( 36) =     17.63609800d0
      d( 36) =     -0.50124300d0
      e( 37) =      7.04416160d0
      d( 37) =     -0.31446610d0
      e( 38) =      5.82146680d0
      d( 38) =     -0.25862910d0
      e( 39) =      2.15795600d0
      d( 39) =     -0.56221190d0
      e( 40) =      0.74877360d0
      d( 40) =     -0.36252210d0
      e( 41) =      0.21200000d0
      d( 41) =      1.00000000d0
c
      go to 1000
c
c iodine  (18s,14p,9d) -> [6s,5p,3d]
c 
  180 continue
c
      e(  1) = 274845.46000000d0
      s(  1) =     -0.00162070d0
      e(  2) =  41233.18800000d0
      s(  2) =     -0.01239760d0
      e(  3) =   9366.73330000d0
      s(  3) =     -0.06220070d0
      e(  4) =   2638.40810000d0
      s(  4) =     -0.21629380d0
      e(  5) =    858.77440000d0
      s(  5) =     -0.46239490d0
      e(  6) =    296.30252000d0
      s(  6) =     -0.38484170d0
      e(  7) =    561.83722000d0
      s(  7) =      0.11422840d0
      e(  8) =     69.04014600d0
      s(  8) =     -0.63229090d0
      e(  9) =     29.98063500d0
      s(  9) =     -0.44201790d0
      e( 10) =     54.86968400d0
      s( 10) =     -0.27079860d0
      e( 11) =      9.99545850d0
      s( 11) =      0.84264720d0
      e( 12) =      4.58886780d0
      s( 12) =      0.30916570d0
      e( 13) =      9.12082560d0
      s( 13) =     -0.34102240d0
      e( 14) =      2.11967870d0
      s( 14) =      0.81006500d0
      e( 15) =      0.97089250d0
      s( 15) =      0.39675370d0
      e( 16) =      1.58799650d0
      s( 16) =      0.26297110d0
      e( 17) =      0.29533560d0
      s( 17) =     -0.75104120d0
      e( 18) =      0.11640160d0
      s( 18) =      1.00000000d0
      e( 19) =   4089.45540000d0
      p( 19) =     -0.00723660d0
      e( 20) =    967.03359000d0
      p( 20) =     -0.05583900d0
      e( 21) =    309.44213000d0
      p( 21) =     -0.23402420d0
      e( 22) =    112.45886000d0
      p( 22) =     -0.50470180d0
      e( 23) =     43.11859000d0
      p( 23) =     -0.36596330d0
      e( 24) =    164.64620000d0
      p( 24) =     -0.02523300d0
      e( 25) =     20.73658300d0
      p( 25) =      0.49441910d0
      e( 26) =      8.15583040d0
      p( 26) =      0.57414620d0
      e( 27) =      3.71048720d0
      p( 27) =      0.42999550d0
      e( 28) =      1.62499900d0
      p( 28) =      0.52623710d0
      e( 29) =      0.71462160d0
      p( 29) =      0.12340630d0
      e( 30) =      0.46281930d0
      p( 30) =      0.35372510d0
      e( 31) =      0.18643120d0
      p( 31) =      0.53558300d0
      e( 32) =      0.07148350d0
      p( 32) =      1.00000000d0
      e( 33) =    417.50324000d0
      d( 33) =     -0.01272520d0
      e( 34) =    123.61483000d0
      d( 34) =     -0.09152120d0
      e( 35) =     45.77903900d0
      d( 35) =     -0.30709890d0
      e( 36) =     18.39166300d0
      d( 36) =     -0.49963970d0
      e( 37) =      7.42179320d0
      d( 37) =     -0.30830660d0
      e( 38) =      6.27385860d0
      d( 38) =     -0.25930050d0
      e( 39) =      2.35941460d0
      d( 39) =     -0.56507650d0
      e( 40) =      0.83779660d0
      d( 40) =     -0.35236940d0
      e( 41) =      0.24400000d0
      d( 41) =      1.00000000d0
c
      go to 1000
c
c xenon  (18s,14p,9d) -> [6s,5p,3d]
c
  200 continue
c
      e(  1) = 287346.87000000d0
      s(  1) =      0.00160710d0
      e(  2) =  43095.30100000d0
      s(  2) =      0.01230010d0
      e(  3) =   9784.12850000d0
      s(  3) =      0.06180250d0
      e(  4) =   2753.63840000d0
      s(  4) =      0.21538810d0
      e(  5) =    895.43918000d0
      s(  5) =      0.46214850d0
      e(  6) =    308.62368000d0
      s(  6) =      0.38639710d0
      e(  7) =    583.95609000d0
      s(  7) =     -0.11438460d0
      e(  8) =     71.78511000d0
      s(  8) =      0.63322530d0
      e(  9) =     31.21570400d0
      s(  9) =      0.44105870d0
      e( 10) =     57.17189000d0
      s( 10) =     -0.27228310d0
      e( 11) =     10.45042100d0
      s( 11) =      0.84784920d0
      e( 12) =      4.79634320d0
      s( 12) =      0.30490360d0
      e( 13) =      9.60140440d0
      s( 13) =     -0.34504860d0
      e( 14) =      2.24514470d0
      s( 14) =      0.81961900d0
      e( 15) =      1.03824270d0
      s( 15) =      0.38963110d0
      e( 16) =      1.72612860d0
      s( 16) =      0.27454000d0
      e( 17) =      0.33198920d0
      s( 17) =     -0.76094750d0
      e( 18) =      0.13115160d0
      s( 18) =      1.00000000d0
      e( 19) =   4259.57200000d0
      p( 19) =      0.00721620d0
      e( 20) =   1007.47600000d0
      p( 20) =      0.05568170d0
      e( 21) =    322.55731000d0
      p( 21) =      0.23357220d0
      e( 22) =    117.30657000d0
      p( 22) =      0.50440390d0
      e( 23) =     45.04384900d0
      p( 23) =      0.36652760d0
      e( 24) =    171.16083000d0
      p( 24) =     -0.02539230d0
      e( 25) =     21.71036300d0
      p( 25) =      0.49445310d0
      e( 26) =      8.58627200d0
      p( 26) =      0.57350990d0
      e( 27) =      3.92782090d0
      p( 27) =     -0.43476890d0
      e( 28) =      1.73472550d0
      p( 28) =     -0.52419630d0
      e( 29) =      0.76938130d0
      p( 29) =     -0.11848080d0
      e( 30) =      0.52176710d0
      p( 30) =      0.36394880d0
      e( 31) =      0.21238860d0
      p( 31) =      0.53025110d0
      e( 32) =      0.08178090d0
      p( 32) =      1.00000000d0
      e( 33) =    443.54520000d0
      d( 33) =     -0.01232780d0
      e( 34) =    131.56120000d0
      d( 34) =     -0.08916270d0
      e( 35) =     19.66012300d0
      d( 35) =     -0.49984010d0
      e( 36) =     48.81639500d0
      d( 36) =     -0.30254280d0
      e( 37) =      7.95644190d0
      d( 37) =     -0.31340450d0
      e( 38) =      6.82453850d0
      d( 38) =     -0.25375490d0
      e( 39) =      2.60497700d0
      d( 39) =     -0.56607080d0
      e( 40) =      0.94221920d0
      d( 40) =     -0.35110780d0
      e( 41) =      0.27500000d0
      d( 41) =      1.00000000d0
c
 1000 return
      end
      subroutine dftdzvp2_0(e,s,p,n)
c
c     ----- dft_dzvp2 basis 
c     ----- hydrogen (5s1p/2s1p) and helium (6s1p)/(2s1p) -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*)
      go to (100,120),n
c
c     ----- h  -----
c
c h     (5s1p) / [2s1p]
c
  100 continue
c
      e(  1) =     50.99917800d0
      s(  1) =      0.00966050d0
      e(  2) =      7.48321810d0
      s(  2) =      0.07372890d0
      e(  3) =      1.77746760d0
      s(  3) =      0.29585810d0
      e(  4) =      0.51932950d0
      s(  4) =      0.71590530d0
      e(  5) =      0.15411000d0
      s(  5) =      1.00000000d0
      e(  6) =      0.75000000d0
      p(  6) =      1.00000000d0
c
      go to 200
c
c     ----- he  -----
c
c he    (6s1p) / [2s1p] 
c
  120 continue
c
      e(  1) =     33.26196600d0
      s(  1) =      0.02086580d0
      e(  2) =      7.56165490d0
      s(  2) =      0.09705880d0
      e(  3) =    221.38803000d0
      s(  3) =      0.00274910d0
      e(  4) =      2.08559900d0
      s(  4) =      0.28072890d0
      e(  5) =      0.61433920d0
      s(  5) =      0.47422180d0
      e(  6) =      0.18292120d0
      s(  6) =      1.00000000d0
      e(  7) =      1.10000000d0
      p(  7) =      1.00000000d0
c
  200 return
c
      end
      subroutine dftdzvp2_1(e,s,p,d,n)
c
c  ----- dft_dzvp2 fitting basis [Li-Ne]
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-2
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- li -----
c
c li    (10s,1p,1d) -> [3s,1p,1d]
c
  100 continue
c
      e(  1) =   1455.81970000d0
      s(  1) =     -0.00077220d0
      e(  2) =    214.45374000d0
      s(  2) =     -0.00611310d0
      e(  3) =     48.17779100d0
      s(  3) =     -0.03137500d0
      e(  4) =     13.50569700d0
      s(  4) =     -0.11606760d0
      e(  5) =      4.28661980d0
      s(  5) =     -0.29339130d0
      e(  6) =      1.44532450d0
      s(  6) =     -0.45752190d0
      e(  7) =      0.48590640d0
      s(  7) =     -0.26240740d0
      e(  8) =      0.83473710d0
      s(  8) =      0.07514560d0
      e(  9) =      0.06768050d0
      s(  9) =     -0.65259490d0
      e( 10) =      0.02544590d0
      s( 10) =      1.00000000d0
      e( 11) =      0.07730000d0
      p( 11) =      1.00000000d0
      e( 12) =      0.12200000d0
      d( 12) =      1.00000000d0
c
      go to 1000
c
c     ----- be -----
c
c be   (10s,1p,1d) -> [3s,1p,1d]
c
  120 continue
c
      e(  1) =   2692.37950000d0
      s(  1) =      0.00075060d0
      e(  2) =    403.72786000d0
      s(  2) =      0.00580460d0
      e(  3) =     91.69794500d0
      s(  3) =      0.02957660d0
      e(  4) =     25.81860300d0
      s(  4) =      0.11098870d0
      e(  5) =      8.22949200d0
      s(  5) =      0.28955560d0
      e(  6) =      2.82668470d0
      s(  6) =      0.45777170d0
      e(  7) =      0.97589940d0
      s(  7) =      0.26699430d0
      e(  8) =      1.95703150d0
      s(  8) =     -0.07508010d0
      e(  9) =      0.16519790d0
      s(  9) =      0.58234850d0
      e( 10) =      0.05515710d0
      s( 10) =      1.00000000d0
      e( 11) =      0.16650000d0
      p( 11) =      1.00000000d0
      e( 12) =      0.27800000d0
      d( 12) =      1.00000000d0
c 
      go to 1000
c
c     ----- b -----
c
c B    (10s,6p,1d) -> [3s,2p,1d]
c
  140 continue
c
      e(  1) =   3862.59880000d0
      s(  1) =      0.00084930d0
      e(  2) =    581.45071000d0
      s(  2) =      0.00650810d0
      e(  3) =    133.16963000d0
      s(  3) =      0.03263480d0
      e(  4) =     37.98787200d0
      s(  4) =      0.11914060d0
      e(  5) =     12.32784800d0
      s(  5) =      0.30309300d0
      e(  6) =      4.34496420d0
      s(  6) =      0.45122830d0
      e(  7) =      1.56373090d0
      s(  7) =      0.24491060d0
      e(  8) =      3.49662620d0
      s(  8) =     -0.07740170d0
      e(  9) =      0.30455240d0
      s(  9) =      0.57637190d0
      e( 10) =      0.09623270d0
      s( 10) =      1.00000000d0
      e( 11) =     22.25845500d0
      p( 11) =      0.00552880d0
      e( 12) =      5.05086360d0
      p( 12) =      0.03856160d0
      e( 13) =      1.48465120d0
      p( 13) =      0.14401930d0
      e( 14) =      0.49797710d0
      p( 14) =      0.34284210d0
      e( 15) =      0.17109000d0
      p( 15) =      0.46622480d0
      e( 16) =      0.05707440d0
      p( 16) =      1.00000000d0
      e( 17) =      0.40000000d0
      d( 17) =      1.00000000d0
c
      go to 1000
c
c     ----- c -----
c
c C    (10s,6p,1d) -> [3s,2p,1d]
c
  160 continue
c
      e(  1) =   5784.15710000d0
      s(  1) =      0.00081900d0
      e(  2) =    869.30350000d0
      s(  2) =      0.00629350d0
      e(  3) =    198.51164000d0
      s(  3) =      0.03178120d0
      e(  4) =     56.42990100d0
      s(  4) =      0.11727340d0
      e(  5) =     18.28545700d0
      s(  5) =      0.30347630d0
      e(  6) =      6.44871460d0
      s(  6) =      0.45352140d0
      e(  7) =      2.34185960d0
      s(  7) =      0.24305910d0
      e(  8) =      5.45953280d0
      s(  8) =     -0.07780440d0
      e(  9) =      0.47819680d0
      s(  9) =      0.57149470d0
      e( 10) =      0.14573010d0
      s( 10) =      1.00000000d0
      e( 11) =     34.25856300d0
      p( 11) =      0.00580430d0
      e( 12) =      7.86389540d0
      p( 12) =      0.04064030d0
      e( 13) =      2.34451930d0
      p( 13) =      0.15502190d0
      e( 14) =      0.79617150d0
      p( 14) =      0.35314440d0
      e( 15) =      0.27268040d0
      p( 15) =      0.45500620d0
      e( 16) =      0.08926050d0
      p( 16) =      1.00000000d0
      e( 17) =      0.60000000d0
      d( 17) =      1.00000000d0
c
      go to 1000
c
c     ----- n -----
c
c N    (10s,6p,1d) -> [3s,2p,1d]
c
  180 continue
c
      e(  1) =   8104.17610000d0
      s(  1) =      0.00079690d0
      e(  2) =   1217.31380000d0
      s(  2) =      0.00612890d0
      e(  3) =    277.73993000d0
      s(  3) =      0.03104710d0
      e(  4) =     78.84759800d0
      s(  4) =      0.11536820d0
      e(  5) =     25.53716100d0
      s(  5) =      0.30257380d0
      e(  6) =      9.00457110d0
      s(  6) =      0.45579130d0
      e(  7) =      3.28352780d0
      s(  7) =      0.24302080d0
      e(  8) =      7.84935730d0
      s(  8) =     -0.07763640d0
      e(  9) =      0.68622390d0
      s(  9) =      0.56798150d0
      e( 10) =      0.20350260d0
      s( 10) =      1.00000000d0
      e( 11) =     49.01460800d0
      p( 11) =     -0.00590070d0
      e( 12) =     11.31667100d0
      p( 12) =     -0.04164440d0
      e( 13) =      3.40340530d0
      p( 13) =     -0.16102490d0
      e( 14) =      1.16111070d0
      p( 14) =     -0.35835380d0
      e( 15) =      0.39533580d0
      p( 15) =     -0.44884150d0
      e( 16) =      0.12689810d0
      p( 16) =      1.00000000d0
      e( 17) =      0.70000000d0
      d( 17) =      1.00000000d0
c
      go to 1000
c
c     ----- o ------
c
c O    (10s,6p,1d) -> [3s,2p,1d]
c
  200 continue
c
      e(  1) =  10814.40200000d0
      s(  1) =      0.00078090d0
      e(  2) =   1623.75320000d0
      s(  2) =      0.00601020d0
      e(  3) =    370.18274000d0
      s(  3) =      0.03052220d0
      e(  4) =    104.97475000d0
      s(  4) =      0.11400890d0
      e(  5) =     33.98442200d0
      s(  5) =      0.30195740d0
      e(  6) =     11.98431200d0
      s(  6) =      0.45711070d0
      e(  7) =      4.38597040d0
      s(  7) =      0.24324780d0
      e(  8) =     10.63003400d0
      s(  8) =     -0.07876540d0
      e(  9) =      0.93985260d0
      s(  9) =      0.57063030d0
      e( 10) =      0.27662130d0
      s( 10) =      1.00000000d0
      e( 11) =     61.54421800d0
      p( 11) =      0.00662380d0
      e( 12) =     14.27619400d0
      p( 12) =      0.04646420d0
      e( 13) =      4.33176790d0
      p( 13) =      0.17442290d0
      e( 14) =      1.47660430d0
      p( 14) =      0.36661150d0
      e( 15) =      0.49598570d0
      p( 15) =      0.43693610d0
      e( 16) =      0.15448360d0
      p( 16) =      1.00000000d0
      e( 17) =      0.80000000d0
      d( 17) =      1.00000000d0
c
      go to 1000
c
c     ----- f -----
c
c F   (10s,6p,1d) -> [3s,2p,1d]
c
  220 continue
c
      e(  1) =  13652.10100000d0
      s(  1) =      0.00078730d0
      e(  2) =   2050.28700000d0
      s(  2) =      0.00605500d0
      e(  3) =    467.68712000d0
      s(  3) =      0.03072890d0
      e(  4) =    132.76350000d0
      s(  4) =      0.11464530d0
      e(  5) =     43.07638100d0
      s(  5) =      0.30377060d0
      e(  6) =     15.22882800d0
      s(  6) =      0.45730670d0
      e(  7) =      5.60511800d0
      s(  7) =      0.23957790d0
      e(  8) =     13.84793600d0
      s(  8) =     -0.07903450d0
      e(  9) =      1.22668860d0
      s(  9) =      0.57084820d0
      e( 10) =      0.35745640d0
      s( 10) =      1.00000000d0
      e( 11) =     78.96175200d0
      p( 11) =      0.00678270d0
      e( 12) =     18.34788000d0
      p( 12) =      0.04789760d0
      e( 13) =      5.58718880d0
      p( 13) =      0.17938410d0
      e( 14) =      1.90184740d0
      p( 14) =      0.36929890d0
      e( 15) =      0.63336520d0
      p( 15) =      0.43327800d0
      e( 16) =      0.19334550d0
      p( 16) =      1.00000000d0
      e( 17) =      1.00000000d0
      d( 17) =      1.00000000d0
c
      go to 1000
c
c     ----- ne -----
c
  240 call caserr2('basis set unavailable for neon')
c
1000  return
      end
      subroutine dftdzvp2_2(e,s,p,d,n)
c
c     ----- dzvp2_dft contractions  [Na-Ar] -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-10
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- na  -----
c
  100 call caserr2('basis set unavailable for sodium')
c
      go to 1000
c
c     ----- mg -----
c 
  120 call caserr2('basis set unavailable for magnesium')
c
c
      go to 1000
c
c     ----- al -----
c
c al  (13s,9p,1d) -> [4s,3p,1d]
c 
  140 continue
c
      e(  1) =  36088.15200000d0
      s(  1) =      0.00059760d0
      e(  2) =   5334.36200000d0
      s(  2) =      0.00470910d0
      e(  3) =   1199.08920000d0
      s(  3) =      0.02455380d0
      e(  4) =    334.07447000d0
      s(  4) =      0.09671100d0
      e(  5) =    106.12906000d0
      s(  5) =      0.27681910d0
      e(  6) =     36.88280200d0
      s(  6) =      0.46452590d0
      e(  7) =     13.33268800d0
      s(  7) =      0.28140030d0
      e(  8) =     30.15812800d0
      s(  8) =      0.08777140d0
      e(  9) =      2.97327740d0
      s(  9) =     -0.57150000d0
      e( 10) =      1.01638120d0
      s( 10) =     -0.50668800d0
      e( 11) =      1.49076120d0
      s( 11) =      0.13403970d0
      e( 12) =      0.16935720d0
      s( 12) =     -0.66554910d0
      e( 13) =      0.06178970d0
      s( 13) =      1.00000000d0
      e( 14) =    286.95815000d0
      p( 14) =      0.00351850d0
      e( 15) =     66.16730800d0
      p( 15) =      0.02833550d0
      e( 16) =     20.32179500d0
      p( 16) =      0.12620280d0
      e( 17) =      7.08582350d0
      p( 17) =      0.32838700d0
      e( 18) =      2.52221040d0
      p( 18) =      0.47129210d0
      e( 19) =      0.86306860d0
      p( 19) =      0.27335180d0
      e( 20) =      0.37612550d0
      p( 20) =      0.20315750d0
      e( 21) =      0.12662860d0
      p( 21) =      0.54380680d0
      e( 22) =      0.04268430d0
      p( 22) =      1.00000000d0
      e( 23) =      0.30000000d0
      d( 23) =      1.00000000d0
c
      go to 1000
c
c     ----- si -----
c
c si (13s,9p,1d) -> [4s,3p,1d]
c
  160 continue
c
      e(  1) =  42393.92700000d0
      s(  1) =     -0.00058950d0
      e(  2) =   6264.11290000d0
      s(  2) =     -0.00464830d0
      e(  3) =   1407.85520000d0
      s(  3) =     -0.02424700d0
      e(  4) =    392.20396000d0
      s(  4) =     -0.09567860d0
      e(  5) =    124.62688000d0
      s(  5) =     -0.27481680d0
      e(  6) =     43.36724800d0
      s(  6) =     -0.46402380d0
      e(  7) =     15.71023700d0
      s(  7) =     -0.28471220d0
      e(  8) =     35.22356900d0
      s(  8) =      0.09008520d0
      e(  9) =      3.55172360d0
      s(  9) =     -0.57645250d0
      e( 10) =      1.25288180d0
      s( 10) =     -0.50029720d0
      e( 11) =      1.94520470d0
      s( 11) =     -0.15076400d0
      e( 12) =      0.23685470d0
      s( 12) =      0.67463270d0
      e( 13) =      0.08592430d0
      s( 13) =      1.00000000d0
      e( 14) =    368.52147000d0
      p( 14) =      0.00314460d0
      e( 15) =     83.65581300d0
      p( 15) =      0.02624470d0
      e( 16) =     25.65768500d0
      p( 16) =      0.11962790d0
      e( 17) =      8.99255640d0
      p( 17) =      0.32097050d0
      e( 18) =      3.24806860d0
      p( 18) =      0.47502370d0
      e( 19) =      1.13807290d0
      p( 19) =      0.27740660d0
      e( 20) =      0.52840940d0
      p( 20) =      0.22910930d0
      e( 21) =      0.18313370d0
      p( 21) =      0.54832590d0
      e( 22) =      0.06255500d0
      p( 22) =      1.00000000d0
      e( 23) =      0.45000000d0
      d( 23) =      1.00000000d0
c
      go to 1000
c
c     ----- p -----
c
c p  (13s,9p,1d) -> [4s,3p,1d]
c
  180 continue
c
      e(  1) =  48863.35400000d0
      s(  1) =     -0.00058650d0
      e(  2) =   7253.04570000d0
      s(  2) =     -0.00460080d0
      e(  3) =   1632.60220000d0
      s(  3) =     -0.02398640d0
      e(  4) =    454.98230000d0
      s(  4) =     -0.09478640d0
      e(  5) =    144.62260000d0
      s(  5) =     -0.27307690d0
      e(  6) =     50.38272300d0
      s(  6) =     -0.46356650d0
      e(  7) =     18.28669000d0
      s(  7) =     -0.28758130d0
      e(  8) =     40.71252000d0
      s(  8) =      0.09210100d0
      e(  9) =      4.18001890d0
      s(  9) =     -0.58204850d0
      e( 10) =      1.51111730d0
      s( 10) =     -0.49372730d0
      e( 11) =      2.44424650d0
      s( 11) =     -0.16314310d0
      e( 12) =      0.31164180d0
      s( 12) =      0.67910500d0
      e( 13) =      0.11201190d0
      s( 13) =      1.00000000d0
      e( 14) =    435.29457000d0
      p( 14) =     -0.00306350d0
      e( 15) =    101.35449000d0
      p( 15) =     -0.02486740d0
      e( 16) =     31.41165900d0
      p( 16) =     -0.11471120d0
      e( 17) =     11.07597700d0
      p( 17) =     -0.31530500d0
      e( 18) =      4.04618090d0
      p( 18) =     -0.47792110d0
      e( 19) =      1.44238140d0
      p( 19) =     -0.28001610d0
      e( 20) =      0.70023080d0
      p( 20) =     -0.24842200d0
      e( 21) =      0.24481070d0
      p( 21) =     -0.55487670d0
      e( 22) =      0.08298960d0
      p( 22) =      1.00000000d0
      e( 23) =      0.55000000d0
      d( 23) =      1.00000000d0
c
      go to 1000
c
c     ----- s -----
c
c s  (13s,9p,1d) -> [4s,3p,1d]
c
  200 continue
c
      e(  1) =  56415.58000000d0
      s(  1) =     -0.00057780d0
      e(  2) =   8345.26890000d0
      s(  2) =     -0.00455130d0
      e(  3) =   1876.30410000d0
      s(  3) =     -0.02374720d0
      e(  4) =    522.73216000d0
      s(  4) =     -0.09398070d0
      e(  5) =    166.17491000d0
      s(  5) =     -0.27150210d0
      e(  6) =     57.94542200d0
      s(  6) =     -0.46315380d0
      e(  7) =     21.06674500d0
      s(  7) =     -0.29019390d0
      e(  8) =     46.61931500d0
      s(  8) =     -0.09389010d0
      e(  9) =      4.85989100d0
      s(  9) =      0.58778920d0
      e( 10) =      1.79118190d0
      s( 10) =      0.48734860d0
      e( 11) =      2.97659540d0
      s( 11) =      0.17317010d0
      e( 12) =      0.39422610d0
      s( 12) =     -0.68587360d0
      e( 13) =      0.14167320d0
      s( 13) =      1.00000000d0
      e( 14) =    520.42034000d0
      p( 14) =     -0.00293020d0
      e( 15) =    120.42997000d0
      p( 15) =     -0.02411078d0
      e( 16) =     37.39062400d0
      p( 16) =     -0.11217634d0
      e( 17) =     13.24845000d0
      p( 17) =     -0.31230673d0
      e( 18) =      4.88812770d0
      p( 18) =     -0.48011094d0
      e( 19) =      1.76493200d0
      p( 19) =     -0.27939772d0
      e( 20) =      0.88920670d0
      p( 20) =     -0.26593078d0
      e( 21) =      0.31032832d0
      p( 21) =     -0.54484109d0
      e( 22) =      0.10306758d0
      p( 22) =      1.00000000d0
      e( 23) =      0.65000000d0
      d( 23) =      1.00000000d0
c
      go to 1000
c
c     ----- cl -----
c
c cl (13s,9p,1d) -> [4s,3p,1d]
c
  220 continue
c
      e(  1) =  63923.62600000d0
      s(  1) =     -0.00057410d0
      e(  2) =   9525.98700000d0
      s(  2) =     -0.00448510d0
      e(  3) =   2146.31160000d0
      s(  3) =     -0.02339370d0
      e(  4) =    598.02741000d0
      s(  4) =     -0.09280490d0
      e(  5) =    190.02855000d0
      s(  5) =     -0.26931960d0
      e(  6) =     66.26196300d0
      s(  6) =     -0.46296130d0
      e(  7) =     24.09660800d0
      s(  7) =     -0.29371230d0
      e(  8) =     52.93325300d0
      s(  8) =      0.09547700d0
      e(  9) =      5.59230800d0
      s(  9) =     -0.59301610d0
      e( 10) =      2.09395600d0
      s( 10) =     -0.48168960d0
      e( 11) =      3.55768590d0
      s( 11) =     -0.18075010d0
      e( 12) =      0.48474690d0
      s( 12) =      0.68895940d0
      e( 13) =      0.17330460d0
      s( 13) =      1.00000000d0
      e( 14) =    583.20115000d0
      p( 14) =     -0.00305110d0
      e( 15) =    135.44725000d0
      p( 15) =     -0.02491210d0
      e( 16) =     42.33562500d0
      p( 16) =     -0.11471060d0
      e( 17) =     15.15427000d0
      p( 17) =     -0.31474760d0
      e( 18) =      5.68306770d0
      p( 18) =     -0.47810120d0
      e( 19) =      2.09023900d0
      p( 19) =     -0.27176950d0
      e( 20) =      1.09799700d0
      p( 20) =     -0.27857900d0
      e( 21) =      0.38227610d0
      p( 21) =     -0.54518290d0
      e( 22) =      0.12499850d0
      p( 22) =      1.00000000d0
      e( 23) =      0.75000000d0
      d( 23) =      1.00000000d0
c
      go to 1000
c
c     ----- ar -----
c
c ar  (13s,9p,1d) -> [4s,3p,1d]
c
  240 continue
c
      e(  1) =  71235.46300000d0
      s(  1) =     -0.00057860d0
      e(  2) =  10643.43300000d0
      s(  2) =     -0.00450440d0
      e(  3) =   2402.54480000d0
      s(  3) =     -0.02344520d0
      e(  4) =    670.38906000d0
      s(  4) =     -0.09286030d0
      e(  5) =    213.36001000d0
      s(  5) =     -0.26919550d0
      e(  6) =     74.55808800d0
      s(  6) =     -0.46232680d0
      e(  7) =     27.19964100d0
      s(  7) =     -0.29399690d0
      e(  8) =     59.69619800d0
      s(  8) =      0.09685500d0
      e(  9) =      6.37035430d0
      s(  9) =     -0.59884620d0
      e( 10) =      2.41606460d0
      s( 10) =     -0.47553970d0
      e( 11) =      4.18650470d0
      s( 11) =     -0.18646480d0
      e( 12) =      0.58305010d0
      s( 12) =      0.69021700d0
      e( 13) =      0.20700690d0
      s( 13) =      1.00000000d0
      e( 14) =    699.42564000d0
      p( 14) =      0.00277690d0
      e( 15) =    163.58304000d0
      p( 15) =      0.02270690d0
      e( 16) =     51.14601600d0
      p( 16) =      0.10738370d0
      e( 17) =     18.25605800d0
      p( 17) =      0.30607000d0
      e( 18) =      6.84150560d0
      p( 18) =      0.48295780d0
      e( 19) =      2.51825460d0
      p( 19) =      0.28163440d0
      e( 20) =      1.32563520d0
      p( 20) =      0.28850040d0
      e( 21) =      0.46219470d0
      p( 21) =      0.54346880d0
      e( 22) =      0.15037120d0
      p( 22) =      1.00000000d0
      e( 23) =      0.85000000d0
      d( 23) =      1.00000000d0
c
 1000 return
      end
      subroutine dftdzvp2_3(e,s,p,d,n)
c
c ----- dzvp2_dft basis 
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-18
      go to (100,120,140,160,180,200,220,240,260,280,300,320),nn
c
c k 
c
  100 call caserr2('basis set unavailable for potassium')
c
      go to 1000
c
c ca  
c 
  120 call caserr2('basis set unavailable for calcium')
c
c
      return
c
c sc  (15s,9p,5d) -> [5s,3p,2d]
c 
  140 continue
c
      e(  1) =  40355.90900000d0
      s(  1) =      0.00173330d0
      e(  2) =   6050.51540000d0
      s(  2) =      0.01327890d0
      e(  3) =   1372.47650000d0
      s(  3) =      0.06630410d0
      e(  4) =    385.24704000d0
      s(  4) =      0.22810440d0
      e(  5) =    124.03194000d0
      s(  5) =      0.47136570d0
      e(  6) =     42.11942300d0
      s(  6) =      0.36337640d0
      e(  7) =     82.15869800d0
      s(  7) =     -0.10081750d0
      e(  8) =      9.13498380d0
      s(  8) =      0.60057600d0
      e(  9) =      3.60008560d0
      s(  9) =      0.47318600d0
      e( 10) =      6.31097380d0
      s( 10) =      0.20966180d0
      e( 11) =      0.96549480d0
      s( 11) =     -0.70888480d0
      e( 12) =      0.37893510d0
      s( 12) =     -0.41495890d0
      e( 13) =      0.53398660d0
      s( 13) =     -0.15187660d0
      e( 14) =      0.07369860d0
      s( 14) =      0.70297410d0
      e( 15) =      0.02872050d0
      s( 15) =      1.00000000d0
      e( 16) =    483.11966000d0
      p( 16) =      0.00927160d0
      e( 17) =    113.24773000d0
      p( 17) =      0.06863490d0
      e( 18) =     35.35725400d0
      p( 18) =      0.25997160d0
      e( 19) =     12.37920400d0
      p( 19) =      0.50433570d0
      e( 20) =      4.41037250d0
      p( 20) =      0.34958900d0
      e( 21) =      2.22423780d0
      p( 21) =      0.31023150d0
      e( 22) =      0.83389920d0
      p( 22) =      0.55513980d0
      e( 23) =      0.30345080d0
      p( 23) =      1.00000000d0
      e( 24) =      0.07650000d0
      p( 24) =      1.00000000d0
      e( 25) =     10.66290300d0
      d( 25) =      0.06447520d0
      e( 26) =      2.71962190d0
      d( 26) =      0.26369060d0
      e( 27) =      0.76770850d0
      d( 27) =      0.47189550d0
      e( 28) =      0.18863360d0
      d( 28) =      0.54521500d0
      e( 29) =      0.03600000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c ti  (15s,9p,5d) -> [5s,4p,2d]
c 
  160 continue
c
      e(  1) =  44446.89600000d0
      s(  1) =     -0.00172760d0
      e(  2) =   6664.41460000d0
      s(  2) =     -0.01323290d0
      e(  3) =   1511.98650000d0
      s(  3) =     -0.06608370d0
      e(  4) =    424.55078000d0
      s(  4) =     -0.22746910d0
      e(  5) =    136.80023000d0
      s(  5) =     -0.47087550d0
      e(  6) =     46.51453500d0
      s(  6) =     -0.36449010d0
      e(  7) =     90.60494200d0
      s(  7) =     -0.10181260d0
      e(  8) =     10.14685800d0
      s(  8) =      0.60429920d0
      e(  9) =      4.02771640d0
      s(  9) =      0.46944500d0
      e( 10) =      7.12703760d0
      s( 10) =     -0.21271460d0
      e( 11) =      1.10314030d0
      s( 11) =      0.71041180d0
      e( 12) =      0.43244950d0
      s( 12) =      0.41533070d0
      e( 13) =      0.61557520d0
      s( 13) =     -0.15265740d0
      e( 14) =      0.08585810d0
      s( 14) =      0.66103500d0
      e( 15) =      0.03310330d0
      s( 15) =      1.00000000d0
      e( 16) =    537.66903000d0
      p( 16) =      0.00920800d0
      e( 17) =    126.36414000d0
      p( 17) =      0.06818680d0
      e( 18) =     39.57137900d0
      p( 18) =      0.25913240d0
      e( 19) =     13.92175000d0
      p( 19) =      0.50463900d0
      e( 20) =      4.99168060d0
      p( 20) =      0.34877870d0
      e( 21) =      2.54789080d0
      p( 21) =      0.31521970d0
      e( 22) =      0.95979350d0
      p( 22) =      0.55340100d0
      e( 23) =      0.35020630d0
      p( 23) =      1.00000000d0
      e( 24) =      0.08550000d0
      p( 24) =      1.00000000d0
      e( 25) =     13.52001600d0
      d( 25) =     -0.06241370d0
      e( 26) =      3.50745230d0
      d( 26) =     -0.26480160d0
      e( 27) =      1.02209480d0
      d( 27) =     -0.47977000d0
      e( 28) =      0.26278610d0
      d( 28) =     -0.52405580d0
      e( 29) =      0.05100000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c v   (15s,9p,5d) -> [5s,4p,2d]
c 
  180 continue
c
      e(  1) =  49145.25800000d0
      s(  1) =     -0.00170490d0
      e(  2) =   7366.10090000d0
      s(  2) =     -0.01306850d0
      e(  3) =   1669.95980000d0
      s(  3) =     -0.06540440d0
      e(  4) =    468.43959000d0
      s(  4) =     -0.22592860d0
      e(  5) =    150.82100000d0
      s(  5) =     -0.47044030d0
      e(  6) =     51.25277600d0
      s(  6) =     -0.36702730d0
      e(  7) =     99.48018000d0
      s(  7) =     -0.10271690d0
      e(  8) =     11.21326400d0
      s(  8) =      0.60769800d0
      e(  9) =      4.47782520d0
      s(  9) =      0.46607310d0
      e( 10) =      7.99133500d0
      s( 10) =     -0.21478090d0
      e( 11) =      1.24681580d0
      s( 11) =      0.71090440d0
      e( 12) =      0.48739340d0
      s( 12) =      0.41627090d0
      e( 13) =      0.69088900d0
      s( 13) =     -0.14902600d0
      e( 14) =      0.09698660d0
      s( 14) =      0.63308970d0
      e( 15) =      0.03676400d0
      s( 15) =      1.00000000d0
      e( 16) =    595.12707000d0
      p( 16) =     -0.00915890d0
      e( 17) =    140.00397000d0
      p( 17) =     -0.06796570d0
      e( 18) =     43.94137700d0
      p( 18) =     -0.25889920d0
      e( 19) =     15.52695200d0
      p( 19) =     -0.50501160d0
      e( 20) =      5.59921580d0
      p( 20) =     -0.34734430d0
      e( 21) =      2.88927230d0
      p( 21) =     -0.31914860d0
      e( 22) =      1.09088840d0
      p( 22) =     -0.55183650d0
      e( 23) =      0.39812970d0
      p( 23) =      1.00000000d0
      e( 24) =      0.09510000d0
      p( 24) =      1.00000000d0
      e( 25) =     16.22047300d0
      d( 25) =     -0.06163860d0
      e( 26) =      4.25474240d0
      d( 26) =     -0.26686080d0
      e( 27) =      1.26177140d0
      d( 27) =     -0.48444430d0
      e( 28) =      0.33151450d0
      d( 28) =     -0.51113550d0
      e( 29) =      0.06400000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c cr  (15s,9p,5d) -> [5s,4p,2d]
c
  200 continue
c
      e(  1) =  52778.74500000d0
      s(  1) =      0.00173540d0
      e(  2) =   7918.30170000d0
      s(  2) =      0.01327750d0
      e(  3) =   1798.48710000d0
      s(  3) =      0.06619060d0
      e(  4) =    505.92005000d0
      s(  4) =      0.22738480d0
      e(  5) =    163.50058000d0
      s(  5) =      0.47007280d0
      e(  6) =     55.81763400d0
      s(  6) =      0.36476530d0
      e(  7) =    108.80412000d0
      s(  7) =      0.10351710d0
      e(  8) =     12.32738700d0
      s(  8) =     -0.61151690d0
      e(  9) =      4.94622950d0
      s(  9) =     -0.46230660d0
      e( 10) =      8.90204460d0
      s( 10) =      0.21619010d0
      e( 11) =      1.39669760d0
      s( 11) =     -0.71092030d0
      e( 12) =      0.54401410d0
      s( 12) =     -0.41735880d0
      e( 13) =      0.77736610d0
      s( 13) =      0.14687210d0
      e( 14) =      0.10703580d0
      s( 14) =     -0.61484960d0
      e( 15) =      0.03990770d0
      s( 15) =      1.00000000d0
      e( 16) =    661.71204000d0
      p( 16) =     -0.00898940d0
      e( 17) =    155.31302000d0
      p( 17) =     -0.06727680d0
      e( 18) =     48.74308000d0
      p( 18) =     -0.25797560d0
      e( 19) =     17.26608300d0
      p( 19) =     -0.50558000d0
      e( 20) =      6.25076520d0
      p( 20) =     -0.34714140d0
      e( 21) =      3.25048650d0
      p( 21) =     -0.32202080d0
      e( 22) =      1.22840880d0
      p( 22) =     -0.55047770d0
      e( 23) =      0.44784370d0
      p( 23) =      1.00000000d0
      e( 24) =      0.10510000d0
      p( 24) =      1.00000000d0
      e( 25) =     18.83297300d0
      d( 25) =     -0.06170400d0
      e( 26) =      4.97912030d0
      d( 26) =     -0.27010800d0
      e( 27) =      1.49186960d0
      d( 27) =     -0.48809890d0
      e( 28) =      0.39585120d0
      d( 28) =     -0.50111050d0
      e( 29) =      0.07500000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c mn  (15s,9p,5d) -> [5s,4p,2d]
c 
  220 continue
c
      e(  1) =  58745.69200000d0
      s(  1) =      0.00168350d0
      e(  2) =   8803.03930000d0
      s(  2) =      0.01291030d0
      e(  3) =   1994.93300000d0
      s(  3) =      0.06472260d0
      e(  4) =    559.35363000d0
      s(  4) =      0.22426570d0
      e(  5) =    180.12270000d0
      s(  5) =      0.46969490d0
      e(  6) =     61.26213400d0
      s(  6) =      0.36980490d0
      e(  7) =    118.52803000d0
      s(  7) =      0.10427700d0
      e(  8) =     13.50494600d0
      s(  8) =     -0.61400010d0
      e(  9) =      5.44318340d0
      s(  9) =     -0.45989710d0
      e( 10) =      9.85695530d0
      s( 10) =      0.21755470d0
      e( 11) =      1.55521630d0
      s( 11) =     -0.71088590d0
      e( 12) =      0.60461780d0
      s( 12) =     -0.41837030d0
      e( 13) =      0.86296550d0
      s( 13) =      0.14376110d0
      e( 14) =      0.11671880d0
      s( 14) =     -0.60090080d0
      e( 15) =      0.04285910d0
      s( 15) =      1.00000000d0
      e( 16) =    740.92768000d0
      p( 16) =     -0.00864200d0
      e( 17) =    173.91313000d0
      p( 17) =     -0.06522490d0
      e( 18) =     54.51849100d0
      p( 18) =     -0.25404170d0
      e( 19) =     19.30041400d0
      p( 19) =     -0.50615190d0
      e( 20) =      6.98930980d0
      p( 20) =     -0.35142320d0
      e( 21) =      3.63261960d0
      p( 21) =     -0.32483590d0
      e( 22) =      1.37382970d0
      p( 22) =     -0.54964150d0
      e( 23) =      0.50142890d0
      p( 23) =      1.00000000d0
      e( 24) =      0.11290000d0
      p( 24) =      1.00000000d0
      e( 25) =     21.25795800d0
      d( 25) =      0.06302750d0
      e( 26) =      5.65799460d0
      d( 26) =      0.27540610d0
      e( 27) =      1.70294550d0
      d( 27) =      0.49168450d0
      e( 28) =      0.45188690d0
      d( 28) =      0.49148300d0
      e( 29) =      0.08200000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c fe  (15s,9p,5d) -> [5s,4p,2d]
c 
  240 continue
c
      e(  1) =  61430.22700000d0
      s(  1) =      0.00175590d0
      e(  2) =   9222.17600000d0
      s(  2) =      0.01341690d0
      e(  3) =   2097.59690000d0
      s(  3) =      0.06669540d0
      e(  4) =    591.49040000d0
      s(  4) =      0.22820510d0
      e(  5) =    191.86062000d0
      s(  5) =      0.46944990d0
      e(  6) =     65.82632800d0
      s(  6) =      0.36355690d0
      e(  7) =    128.74074000d0
      s(  7) =     -0.10491680d0
      e(  8) =     14.71813300d0
      s(  8) =      0.61796190d0
      e(  9) =      5.95075430d0
      s(  9) =      0.45600930d0
      e( 10) =     10.85987900d0
      s( 10) =      0.21849170d0
      e( 11) =      1.71944710d0
      s( 11) =     -0.71133100d0
      e( 12) =      0.66645320d0
      s( 12) =     -0.41869470d0
      e( 13) =      0.97547610d0
      s( 13) =     -0.14410540d0
      e( 14) =      0.12311430d0
      s( 14) =      0.59581340d0
      e( 15) =      0.04487950d0
      s( 15) =      1.00000000d0
      e( 16) =    780.62030000d0
      p( 16) =     -0.00912170d0
      e( 17) =    184.00622000d0
      p( 17) =     -0.06800400d0
      e( 18) =     58.08446700d0
      p( 18) =     -0.25976810d0
      e( 19) =     20.75979500d0
      p( 19) =     -0.50601380d0
      e( 20) =      7.59345150d0
      p( 20) =     -0.34190820d0
      e( 21) =      4.02791730d0
      p( 21) =     -0.32729620d0
      e( 22) =      1.52647000d0
      p( 22) =     -0.54815000d0
      e( 23) =      0.55737020d0
      p( 23) =      1.00000000d0
      e( 24) =      0.12100000d0
      p( 24) =      1.00000000d0
      e( 25) =     23.92931600d0
      d( 25) =     -0.06349210d0
      e( 26) =      6.39990130d0
      d( 26) =     -0.27839130d0
      e( 27) =      1.93174170d0
      d( 27) =     -0.49381950d0
      e( 28) =      0.51152790d0
      d( 28) =     -0.48626940d0
      e( 29) =      0.09000000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c co  (15s,9p,5d) -> [5s,4p,2d]
c 
  260 continue
c
      e(  1) =  67981.04200000d0
      s(  1) =     -0.00170240d0
      e(  2) =  10193.42800000d0
      s(  2) =     -0.01303860d0
      e(  3) =   2313.18140000d0
      s(  3) =     -0.06518800d0
      e(  4) =    650.07779000d0
      s(  4) =     -0.22502900d0
      e(  5) =    210.06015000d0
      s(  5) =     -0.46914570d0
      e(  6) =     71.77449800d0
      s(  6) =     -0.36865860d0
      e(  7) =    139.32221000d0
      s(  7) =      0.10555780d0
      e(  8) =     16.00278600d0
      s(  8) =     -0.62009540d0
      e(  9) =      6.49193530d0
      s(  9) =     -0.45397250d0
      e( 10) =     11.91039400d0
      s( 10) =     -0.21912730d0
      e( 11) =      1.89041050d0
      s( 11) =      0.71142010d0
      e( 12) =      0.73022780d0
      s( 12) =      0.41922480d0
      e( 13) =      1.05860200d0
      s( 13) =      0.13928930d0
      e( 14) =      0.13009050d0
      s( 14) =     -0.58643150d0
      e( 15) =      0.04685300d0
      s( 15) =      1.00000000d0
      e( 16) =    852.79139000d0
      p( 16) =     -0.00902660d0
      e( 17) =    201.06964000d0
      p( 17) =     -0.06750980d0
      e( 18) =     63.52134500d0
      p( 18) =     -0.25902510d0
      e( 19) =     22.74864900d0
      p( 19) =     -0.50639190d0
      e( 20) =      8.34277550d0
      p( 20) =     -0.34185210d0
      e( 21) =      4.44760870d0
      p( 21) =     -0.32895350d0
      e( 22) =      1.68587800d0
      p( 22) =     -0.54729940d0
      e( 23) =      0.61512090d0
      p( 23) =      1.00000000d0
      e( 24) =      0.12660000d0
      p( 24) =      1.00000000d0
      e( 25) =     26.53246900d0
      d( 25) =     -0.06447590d0
      e( 26) =      7.12589450d0
      d( 26) =     -0.28236590d0
      e( 27) =      2.15476730d0
      d( 27) =     -0.49565360d0
      e( 28) =      0.56886000d0
      d( 28) =     -0.48065190d0
      e( 29) =      0.09700000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c ni  (15s,9p,5d) -> [5s,4p,2d]
c 
  280 continue
c
      e(  1) =  72509.04200000d0
      s(  1) =     -0.00172080d0
      e(  2) =  10879.17600000d0
      s(  2) =     -0.01316370d0
      e(  3) =   2471.64600000d0
      s(  3) =     -0.06565670d0
      e(  4) =    695.82606000d0
      s(  4) =     -0.22590270d0
      e(  5) =    225.37504000d0
      s(  5) =     -0.46891570d0
      e(  6) =     77.24015800d0
      s(  6) =     -0.36728410d0
      e(  7) =    150.36412000d0
      s(  7) =      0.10612160d0
      e(  8) =     17.33109200d0
      s(  8) =     -0.62289970d0
      e(  9) =      7.04885550d0
      s(  9) =     -0.45126310d0
      e( 10) =     13.00639600d0
      s( 10) =     -0.21955900d0
      e( 11) =      2.06828210d0
      s( 11) =      0.71117420d0
      e( 12) =      0.79634340d0
      s( 12) =      0.41996870d0
      e( 13) =      1.14076120d0
      s( 13) =      0.13450420d0
      e( 14) =      0.13649560d0
      s( 14) =     -0.57911790d0
      e( 15) =      0.04864020d0
      s( 15) =      1.00000000d0
      e( 16) =    925.37823000d0
      p( 16) =      0.00898080d0
      e( 17) =    218.37918000d0
      p( 17) =      0.06725680d0
      e( 18) =     69.07589400d0
      p( 18) =      0.25871990d0
      e( 19) =     24.79418600d0
      p( 19) =      0.50670800d0
      e( 20) =      9.11772700d0
      p( 20) =      0.34125310d0
      e( 21) =      4.88655560d0
      p( 21) =      0.33026540d0
      e( 22) =      1.85205680d0
      p( 22) =      0.54657530d0
      e( 23) =      0.67489050d0
      p( 23) =      1.00000000d0
      e( 24) =      0.13510000d0
      p( 24) =      1.00000000d0
      e( 25) =     29.22965900d0
      d( 25) =     -0.06539530d0
      e( 26) =      7.87891450d0
      d( 26) =     -0.28601300d0
      e( 27) =      2.38611600d0
      d( 27) =     -0.49715640d0
      e( 28) =      0.62824370d0
      d( 28) =     -0.47563690d0
      e( 29) =      0.10400000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c cu  (15s,9p,5d) -> [5s,4p,2d]
c
  300 continue
c
      e(  1) =  80289.62000000d0
      s(  1) =     -0.00165620d0
      e(  2) =  12027.33800000d0
      s(  2) =     -0.01270930d0
      e(  3) =   2724.25750000d0
      s(  3) =     -0.06385180d0
      e(  4) =    763.56173000d0
      s(  4) =     -0.22211540d0
      e(  5) =    246.06459000d0
      s(  5) =     -0.46860490d0
      e(  6) =     83.86836300d0
      s(  6) =     -0.37337930d0
      e(  7) =    161.79726000d0
      s(  7) =      0.10667590d0
      e(  8) =     18.72537500d0
      s(  8) =     -0.62459430d0
      e(  9) =      7.63641650d0
      s(  9) =     -0.44967240d0
      e( 10) =     14.15082900d0
      s( 10) =     -0.21980770d0
      e( 11) =      2.25283040d0
      s( 11) =      0.71087600d0
      e( 12) =      0.86448860d0
      s( 12) =      0.42065710d0
      e( 13) =      1.22309630d0
      s( 13) =      0.13031690d0
      e( 14) =      0.14297710d0
      s( 14) =     -0.57086010d0
      e( 15) =      0.05046030d0
      s( 15) =      1.00000000d0
      e( 16) =   1002.97450000d0
      p( 16) =      0.00891430d0
      e( 17) =    236.62530000d0
      p( 17) =      0.06697040d0
      e( 18) =     74.89232100d0
      p( 18) =      0.25841470d0
      e( 19) =     26.93125200d0
      p( 19) =      0.50706200d0
      e( 20) =      9.92677590d0
      p( 20) =      0.34075110d0
      e( 21) =      5.34466480d0
      p( 21) =      0.33137450d0
      e( 22) =      2.02474800d0
      p( 22) =      0.54598710d0
      e( 23) =      0.73663310d0
      p( 23) =      1.00000000d0
      e( 24) =      0.14100000d0
      p( 24) =      1.00000000d0
      e( 25) =     31.81266700d0
      d( 25) =     -0.06688910d0
      e( 26) =      8.60587160d0
      d( 26) =     -0.29074010d0
      e( 27) =      2.60934110d0
      d( 27) =     -0.49841940d0
      e( 28) =      0.68521350d0
      d( 28) =     -0.46972510d0
      e( 29) =      0.11000000d0
      d( 29) =      1.00000000d0
c
      go to 1000
c
c zn  (15s,9p,5d) -> [5s,4p,2d]
c 
  320 continue
c
      e(  1) =  82904.22000000d0
      s(  1) =     -0.00173130d0
      e(  2) =  12444.23200000d0
      s(  2) =     -0.01323280d0
      e(  3) =   2829.85290000d0
      s(  3) =     -0.06589010d0
      e(  4) =    797.89288000d0
      s(  4) =     -0.22619880d0
      e(  5) =    259.06473000d0
      s(  5) =     -0.46839110d0
      e(  6) =     89.07951200d0
      s(  6) =     -0.36691560d0
      e(  7) =    173.68172000d0
      s(  7) =     -0.10716240d0
      e(  8) =     20.16649700d0
      s(  8) =      0.62649820d0
      e(  9) =      8.24708190d0
      s(  9) =      0.44782060d0
      e( 10) =     15.31658400d0
      s( 10) =     -0.22123750d0
      e( 11) =      2.45574930d0
      s( 11) =      0.70919110d0
      e( 12) =      0.95487770d0
      s( 12) =      0.42241470d0
      e( 13) =      1.41000340d0
      s( 13) =     -0.14046520d0
      e( 14) =      0.16934410d0
      s( 14) =      0.60127450d0
      e( 15) =      0.05922100d0
      s( 15) =      1.00000000d0
      e( 16) =   1085.17850000d0
      p( 16) =      0.00882600d0
      e( 17) =    256.18093000d0
      p( 17) =      0.06644550d0
      e( 18) =     81.14025300d0
      p( 18) =      0.25742460d0
      e( 19) =     29.22252000d0
      p( 19) =      0.50714550d0
      e( 20) =     10.79369500d0
      p( 20) =      0.34143560d0
      e( 21) =      5.84129040d0
      p( 21) =      0.33121250d0
      e( 22) =      2.22636600d0
      p( 22) =      0.54637610d0
      e( 23) =      0.82116400d0
      p( 23) =      1.00000000d0
      e( 24) =      0.16900000d0
      p( 24) =      1.00000000d0
      e( 25) =     38.09346700d0
      d( 25) =     -0.06069660d0
      e( 26) =     10.42375600d0
      d( 26) =     -0.27605000d0
      e( 27) =      3.25325210d0
      d( 27) =     -0.49826380d0
      e( 28) =      0.90975290d0
      d( 28) =     -0.46898980d0
      e( 29) =      0.17200000d0
      d( 29) =      1.00000000d0
c
 1000 return
      end
      subroutine dftdzvp2_sh(nucz,ipass,itype,igauss,ng,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension igau(11,6), itypes(11,6)
      dimension kind(6)
      data kind/3, 3, 5, 6, 8, 11 /
c
      data igau /
c  H
     + 4,1,1,0,0,0,0,0,0,0,0,
c  He
     + 5,1,1,0,0,0,0,0,0,0,0,
c  Li-Be
     + 7,2,1,1,1,0,0,0,0,0,0,
c  B-Ne
     + 7,2,1,5,1,1,0,0,0,0,0,
c  Na-Ar
     + 7,3,2,1,6,2,1,1,0,0,0,
c  Sc-Zn
     + 6,3,3,2,1,5,2,1,1,4,1/

      data itypes /
c  H
     + 1,1,2,0,0,0,0,0,0,0,0,
c  He
     + 1,1,2,0,0,0,0,0,0,0,0,
c  Li-Be
     + 1,1,1,2,3,0,0,0,0,0,0,
c  B-Ne
     + 1,1,1,2,2,3,0,0,0,0,0,
c  Na-Ar
     + 1,1,1,1,2,2,2,3,0,0,0,
c  Sc-Zn
     + 1,1,1,1,1,2,2,2,2,3,3/
c
c     set values for the current dzvp2_dft   shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3 for s,p,d shell
c            ng     = offset in e,cs,cp,cd arrays for current shell
c
      ind=1
      if(nucz.gt. 1) ind=2
      if(nucz.gt. 2) ind=3
      if(nucz.gt. 4) ind=4
      if(nucz.gt.10) ind=5
      if(nucz.gt.18) ind=6
      if(nucz.gt.30) then
         call caserr2('dzvp2_dft basis sets only extend to zinc')
      end if
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if (odone) go to 100
c
       igauss = igau(ipass,ind)
       ng =0
       do loop = 1, ipass-1
        ng = ng + igau(loop,ind)
       enddo
       ityp = itypes(ipass,ind)
c
100   itype = ityp + 15
      return
      end
      subroutine dfttzvp_0(e,s,p,n)
c
c     ----- dft_tzvp basis 
c     ----- hydrogen (5s1p/3s1p) 
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*)
      go to (100,120),n
c
c     ----- h  -----
c
c h     (5s1p) / [3s1p]
c
  100 continue
c
      e(  1) =     50.99917800d0
      s(  1) =      0.00966050d0
      e(  2) =      7.48321810d0
      s(  2) =      0.07372890d0
      e(  3) =      1.77746760d0
      s(  3) =      0.29585810d0
      e(  4) =      0.51932950d0
      s(  4) =      1.00000000d0
      e(  5) =      0.15411000d0
      s(  5) =      1.00000000d0
      e(  6) =      0.75000000d0
      p(  6) =      1.00000000d0
c
      go to 200
c
c     ----- he  -----
c
  120 call caserr2('tzvp dft basis not available for helium')
c
  200 return
c
      end
      subroutine dfttzvp_1(e,s,p,d,n)
c
c  ----- dft_tzvp fitting basis [Li-Ne]
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-2
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- li -----
c
  100 call caserr2('basis set unavailable for lithium')
c
      go to 1000
c
c     ----- be -----
c
  120 call caserr2('basis set unavailable for beryllium')
c
      go to 1000
c
c     ----- b -----
c
  140 call caserr2('basis set unavailable for boron')
c
      go to 1000
c
c     ----- c -----
c
c C    (10s,6p,1d) -> [4s,3p,1d]
c
  160 continue
c
      e(  1) =   5784.15710000d0
      s(  1) =      0.00081900d0
      e(  2) =    869.30350000d0
      s(  2) =      0.00629350d0
      e(  3) =    198.51164000d0
      s(  3) =      0.03178120d0
      e(  4) =     56.42990100d0
      s(  4) =      0.11727340d0
      e(  5) =     18.28545700d0
      s(  5) =      0.30347630d0
      e(  6) =      6.44871460d0
      s(  6) =      0.45352140d0
      e(  7) =      2.34185960d0
      s(  7) =      0.24305910d0
      e(  8) =      5.45953280d0
      s(  8) =      1.00000000d0
      e(  9) =      0.47819680d0
      s(  9) =      1.00000000d0
      e( 10) =      0.14573010d0
      s( 10) =      1.00000000d0
      e( 11) =     34.25856300d0
      p( 11) =      0.00580430d0
      e( 12) =      7.86389540d0
      p( 12) =      0.04064030d0
      e( 13) =      2.34451930d0
      p( 13) =      0.15502190d0
      e( 14) =      0.79617150d0
      p( 14) =      0.35314440d0
      e( 15) =      0.27268040d0
      p( 15) =      1.00000000d0
      e( 16) =      0.08926050d0
      p( 16) =      1.00000000d0
      e( 17) =      0.60000000d0
      d( 17) =      1.00000000d0
c
      go to 1000
c
c     ----- n -----
c
c N    (10s,6p,1d) -> [4s,3p,1d]
c
  180 continue
c
      e(  1) =   8104.17610000d0
      s(  1) =      0.00079690d0
      e(  2) =   1217.31380000d0
      s(  2) =      0.00612890d0
      e(  3) =    277.73993000d0
      s(  3) =      0.03104710d0
      e(  4) =     78.84759800d0
      s(  4) =      0.11536820d0
      e(  5) =     25.53716100d0
      s(  5) =      0.30257380d0
      e(  6) =      9.00457110d0
      s(  6) =      0.45579130d0
      e(  7) =      3.28352780d0
      s(  7) =      0.24302080d0
      e(  8) =      7.84935730d0
      s(  8) =      1.00000000d0
      e(  9) =      0.68622390d0
      s(  9) =      1.00000000d0
      e( 10) =      0.20350260d0
      s( 10) =      1.00000000d0
      e( 11) =     49.01460800d0
      p( 11) =     -0.00590070d0
      e( 12) =     11.31667100d0
      p( 12) =     -0.04164440d0
      e( 13) =      3.40340530d0
      p( 13) =     -0.16102490d0
      e( 14) =      1.16111070d0
      p( 14) =     -0.35835380d0
      e( 15) =      0.39533580d0
      p( 15) =      1.00000000d0
      e( 16) =      0.12689810d0
      p( 16) =      1.00000000d0
      e( 17) =      0.70000000d0
      d( 17) =      1.00000000d0
c
      go to 1000
c
c     ----- o ------
c
c O    (10s,6p,1d) -> [4s,3p,1d]
c
  200 continue
c
      e(  1) =  10814.40200000d0
      s(  1) =      0.00078090d0
      e(  2) =   1623.75320000d0
      s(  2) =      0.00601020d0
      e(  3) =    370.18274000d0
      s(  3) =      0.03052220d0
      e(  4) =    104.97475000d0
      s(  4) =      0.11400890d0
      e(  5) =     33.98442200d0
      s(  5) =      0.30195740d0
      e(  6) =     11.98431200d0
      s(  6) =      0.45711070d0
      e(  7) =      4.38597040d0
      s(  7) =      0.24324780d0
      e(  8) =     10.63003400d0
      s(  8) =      1.00000000d0
      e(  9) =      0.93985260d0
      s(  9) =      1.00000000d0
      e( 10) =      0.27662130d0
      s( 10) =      1.00000000d0
      e( 11) =     61.54421800d0
      p( 11) =      0.00662380d0
      e( 12) =     14.27619400d0
      p( 12) =      0.04646420d0
      e( 13) =      4.33176790d0
      p( 13) =      0.17442290d0
      e( 14) =      1.47660430d0
      p( 14) =      0.36661150d0
      e( 15) =      0.49598570d0
      p( 15) =      1.00000000d0
      e( 16) =      0.15448360d0
      p( 16) =      1.00000000d0
      e( 17) =      0.80000000d0
      d( 17) =      1.00000000d0
c
      go to 1000
c
c     ----- f -----
c
c F   (10s,6p,1d) -> [4s,3p,1d]
c
  220 continue
c
      e(  1) =  13652.10100000d0
      s(  1) =      0.00078730d0
      e(  2) =   2050.28700000d0
      s(  2) =      0.00605500d0
      e(  3) =    467.68712000d0
      s(  3) =      0.03072890d0
      e(  4) =    132.76350000d0
      s(  4) =      0.11464530d0
      e(  5) =     43.07638100d0
      s(  5) =      0.30377060d0
      e(  6) =     15.22882800d0
      s(  6) =      0.45730670d0
      e(  7) =      5.60511800d0
      s(  7) =      0.23957790d0
      e(  8) =     13.84793600d0
      s(  8) =      1.00000000d0
      e(  9) =      1.22668860d0
      s(  9) =      1.00000000d0
      e( 10) =      0.35745640d0
      s( 10) =      1.00000000d0
      e( 11) =     78.96175200d0
      p( 11) =      0.00678270d0
      e( 12) =     18.34788000d0
      p( 12) =      0.04789760d0
      e( 13) =      5.58718880d0
      p( 13) =      0.17938410d0
      e( 14) =      1.90184740d0
      p( 14) =      0.36929890d0
      e( 15) =      0.63336520d0
      p( 15) =      1.00000000d0
      e( 16) =      0.19334550d0
      p( 16) =      1.00000000d0
      e( 17) =      1.00000000d0
      d( 17) =      1.00000000d0
c
      go to 1000
c
c     ----- ne -----
c
  240 call caserr2('basis set unavailable for neon')
c
1000  return
      end
      subroutine dfttzvp_2(e,s,p,d,n)
c
c     ----- tzvp_dft contractions  [Na-Ar] -----
c
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension e(*),s(*),p(*),d(*)
      nn = n-10
      go to (100,120,140,160,180,200,220,240),nn
c
c     ----- na  -----
c
  100 call caserr2('basis set unavailable for sodium')
c
      go to 1000
c
c     ----- mg -----
c 
  120 call caserr2('basis set unavailable for magnesium')
c
c
      go to 1000
c
c     ----- al -----
c
c al  (13s,9p,1d) -> [5s,4p,1d]
c 
  140 continue
c
      e(  1) =  36088.15200000d0
      s(  1) =      0.00059760d0
      e(  2) =   5334.36200000d0
      s(  2) =      0.00470910d0
      e(  3) =   1199.08920000d0
      s(  3) =      0.02455380d0
      e(  4) =    334.07447000d0
      s(  4) =      0.09671100d0
      e(  5) =    106.12906000d0
      s(  5) =      0.27681910d0
      e(  6) =     36.88280200d0
      s(  6) =      0.46452590d0
      e(  7) =     13.33268800d0
      s(  7) =      0.28140030d0
      e(  8) =     30.15812800d0
      s(  8) =      0.08777140d0
      e(  9) =      2.97327740d0
      s(  9) =     -0.57150000d0
      e( 10) =      1.01638120d0
      s( 10) =     -0.50668800d0
      e( 11) =      1.49076120d0
      s( 11) =      1.00000000d0
      e( 12) =      0.16935720d0
      s( 12) =      1.00000000d0
      e( 13) =      0.06178970d0
      s( 13) =      1.00000000d0
      e( 14) =    286.95815000d0
      p( 14) =      0.00351850d0
      e( 15) =     66.16730800d0
      p( 15) =      0.02833550d0
      e( 16) =     20.32179500d0
      p( 16) =      0.12620280d0
      e( 17) =      7.08582350d0
      p( 17) =      0.32838700d0
      e( 18) =      2.52221040d0
      p( 18) =      0.47129210d0
      e( 19) =      0.86306860d0
      p( 19) =      0.27335180d0
      e( 20) =      0.37612550d0
      p( 20) =      1.00000000d0
      e( 21) =      0.12662860d0
      p( 21) =      1.00000000d0
      e( 22) =      0.04268430d0
      p( 22) =      1.00000000d0
      e( 23) =      0.30000000d0
      d( 23) =      1.00000000d0
c
      go to 1000
c
c     ----- si -----
c
c si (13s,9p,1d) -> [5s,4p,1d]
c
  160 continue
c
      e(  1) =  42393.92700000d0
      s(  1) =     -0.00058950d0
      e(  2) =   6264.11290000d0
      s(  2) =     -0.00464830d0
      e(  3) =   1407.85520000d0
      s(  3) =     -0.02424700d0
      e(  4) =    392.20396000d0
      s(  4) =     -0.09567860d0
      e(  5) =    124.62688000d0
      s(  5) =     -0.27481680d0
      e(  6) =     43.36724800d0
      s(  6) =     -0.46402380d0
      e(  7) =     15.71023700d0
      s(  7) =     -0.28471220d0
      e(  8) =     35.22356900d0
      s(  8) =      0.09008520d0
      e(  9) =      3.55172360d0
      s(  9) =     -0.57645250d0
      e( 10) =      1.25288180d0
      s( 10) =     -0.50029720d0
      e( 11) =      1.94520470d0
      s( 11) =      1.00000000d0
      e( 12) =      0.23685470d0
      s( 12) =      1.00000000d0
      e( 13) =      0.08592430d0
      s( 13) =      1.00000000d0
      e( 14) =    368.52147000d0
      p( 14) =      0.00314460d0
      e( 15) =     83.65581300d0
      p( 15) =      0.02624470d0
      e( 16) =     25.65768500d0
      p( 16) =      0.11962790d0
      e( 17) =      8.99255640d0
      p( 17) =      0.32097050d0
      e( 18) =      3.24806860d0
      p( 18) =      0.47502370d0
      e( 19) =      1.13807290d0
      p( 19) =      0.27740660d0
      e( 20) =      0.52840940d0
      p( 20) =      1.00000000d0
      e( 21) =      0.18313370d0
      p( 21) =      1.00000000d0
      e( 22) =      0.06255500d0
      p( 22) =      1.00000000d0
      e( 23) =      0.45000000d0
      d( 23) =      1.00000000d0
c
      go to 1000
c
c     ----- p -----
c
c p  (13s,9p,1d) -> [5s,4p,1d]
c
  180 continue
c
      e(  1) =  48863.35400000d0
      s(  1) =     -0.00058650d0
      e(  2) =   7253.04570000d0
      s(  2) =     -0.00460080d0
      e(  3) =   1632.60220000d0
      s(  3) =     -0.02398640d0
      e(  4) =    454.98230000d0
      s(  4) =     -0.09478640d0
      e(  5) =    144.62260000d0
      s(  5) =     -0.27307690d0
      e(  6) =     50.38272300d0
      s(  6) =     -0.46356650d0
      e(  7) =     18.28669000d0
      s(  7) =     -0.28758130d0
      e(  8) =     40.71252000d0
      s(  8) =      0.09210100d0
      e(  9) =      4.18001890d0
      s(  9) =     -0.58204850d0
      e( 10) =      1.51111730d0
      s( 10) =     -0.49372730d0
      e( 11) =      2.44424650d0
      s( 11) =      1.00000000d0
      e( 12) =      0.31164180d0
      s( 12) =      1.00000000d0
      e( 13) =      0.11201190d0
      s( 13) =      1.00000000d0
      e( 14) =    435.29457000d0
      p( 14) =     -0.00306350d0
      e( 15) =    101.35449000d0
      p( 15) =     -0.02486740d0
      e( 16) =     31.41165900d0
      p( 16) =     -0.11471120d0
      e( 17) =     11.07597700d0
      p( 17) =     -0.31530500d0
      e( 18) =      4.04618090d0
      p( 18) =     -0.47792110d0
      e( 19) =      1.44238140d0
      p( 19) =     -0.28001610d0
      e( 20) =      0.70023080d0
      p( 20) =      1.00000000d0
      e( 21) =      0.24481070d0
      p( 21) =      1.00000000d0
      e( 22) =      0.08298960d0
      p( 22) =      1.00000000d0
      e( 23) =      0.55000000d0
      d( 23) =      1.00000000d0
c
      go to 1000
c
c     ----- s -----
c
c s  (13s,9p,1d) -> [5s,4p,1d]
c
  200 continue
c
      e(  1) =  56415.58000000d0
      s(  1) =     -0.00057780d0
      e(  2) =   8345.26890000d0
      s(  2) =     -0.00455130d0
      e(  3) =   1876.30410000d0
      s(  3) =     -0.02374720d0
      e(  4) =    522.73216000d0
      s(  4) =     -0.09398070d0
      e(  5) =    166.17491000d0
      s(  5) =     -0.27150210d0
      e(  6) =     57.94542200d0
      s(  6) =     -0.46315380d0
      e(  7) =     21.06674500d0
      s(  7) =     -0.29019390d0
      e(  8) =     46.61931500d0
      s(  8) =     -0.09389010d0
      e(  9) =      4.85989100d0
      s(  9) =      0.58778920d0
      e( 10) =      1.79118190d0
      s( 10) =      0.48734860d0
      e( 11) =      2.97659540d0
      s( 11) =      1.00000000d0
      e( 12) =      0.39422610d0
      s( 12) =      1.00000000d0
      e( 13) =      0.14167320d0
      s( 13) =      1.00000000d0
      e( 14) =    520.42034000d0
      p( 14) =     -0.00293020d0
      e( 15) =    120.42997000d0
      p( 15) =     -0.02411010d0
      e( 16) =     37.39062400d0
      p( 16) =     -0.11217630d0
      e( 17) =     13.24845000d0
      p( 17) =     -0.31230670d0
      e( 18) =      4.88812770d0
      p( 18) =     -0.48011090d0
      e( 19) =      1.76493200d0
      p( 19) =     -0.27939770d0
      e( 20) =      0.88920670d0
      p( 20) =      1.00000000d0
      e( 21) =      0.31032830d0
      p( 21) =      1.00000000d0
      e( 22) =      0.10306760d0
      p( 22) =      1.00000000d0
      e( 23) =      0.65000000d0
      d( 23) =      1.00000000d0
c
      go to 1000
c
c     ----- cl -----
c
c cl (13s,9p,1d) -> [5s,4p,1d]
c
  220 continue
c
      e(  1) =  63923.62600000d0
      s(  1) =     -0.00057410d0
      e(  2) =   9525.98700000d0
      s(  2) =     -0.00448510d0
      e(  3) =   2146.31160000d0
      s(  3) =     -0.02339370d0
      e(  4) =    598.02741000d0
      s(  4) =     -0.09280490d0
      e(  5) =    190.02855000d0
      s(  5) =     -0.26931960d0
      e(  6) =     66.26196300d0
      s(  6) =     -0.46296130d0
      e(  7) =     24.09660800d0
      s(  7) =     -0.29371230d0
      e(  8) =     52.93325300d0
      s(  8) =      0.09547700d0
      e(  9) =      5.59230800d0
      s(  9) =     -0.59301610d0
      e( 10) =      2.09395600d0
      s( 10) =     -0.48168960d0
      e( 11) =      3.55768590d0
      s( 11) =      1.00000000d0
      e( 12) =      0.48474690d0
      s( 12) =      1.00000000d0
      e( 13) =      0.17330460d0
      s( 13) =      1.00000000d0
      e( 14) =    583.20115000d0
      p( 14) =     -0.00305110d0
      e( 15) =    135.44725000d0
      p( 15) =     -0.02491210d0
      e( 16) =     42.33562500d0
      p( 16) =     -0.11471060d0
      e( 17) =     15.15427000d0
      p( 17) =     -0.31474760d0
      e( 18) =      5.68306770d0
      p( 18) =     -0.47810120d0
      e( 19) =      2.09023900d0
      p( 19) =     -0.27176950d0
      e( 20) =      1.09799700d0
      p( 20) =      1.00000000d0
      e( 21) =      0.38227610d0
      p( 21) =      1.00000000d0
      e( 22) =      0.12499850d0
      p( 22) =      1.00000000d0
      e( 23) =      0.75000000d0
      d( 23) =      1.00000000d0
c
      go to 1000
c
c     ----- ar -----
c
c ar  (13s,9p,1d) -> [5s,4p,1d]
c
  240 continue
c
      e(  1) =  71235.46300000d0
      s(  1) =     -0.00057860d0
      e(  2) =  10643.43300000d0
      s(  2) =     -0.00450440d0
      e(  3) =   2402.54480000d0
      s(  3) =     -0.02344520d0
      e(  4) =    670.38906000d0
      s(  4) =     -0.09286030d0
      e(  5) =    213.36001000d0
      s(  5) =     -0.26919550d0
      e(  6) =     74.55808800d0
      s(  6) =     -0.46232680d0
      e(  7) =     27.19964100d0
      s(  7) =     -0.29399690d0
      e(  8) =     59.69619800d0
      s(  8) =      0.09685500d0
      e(  9) =      6.37035430d0
      s(  9) =     -0.59884620d0
      e( 10) =      2.41606460d0
      s( 10) =     -0.47553970d0
      e( 11) =      4.18650470d0
      s( 11) =      1.00000000d0
      e( 12) =      0.58305010d0
      s( 12) =      1.00000000d0
      e( 13) =      0.20700690d0
      s( 13) =      1.00000000d0
      e( 14) =    699.42564000d0
      p( 14) =      0.00277690d0
      e( 15) =    163.58304000d0
      p( 15) =      0.02270690d0
      e( 16) =     51.14601600d0
      p( 16) =      0.10738370d0
      e( 17) =     18.25605800d0
      p( 17) =      0.30607000d0
      e( 18) =      6.84150560d0
      p( 18) =      0.48295780d0
      e( 19) =      2.51825460d0
      p( 19) =      0.28163440d0
      e( 20) =      1.32563520d0
      p( 20) =      1.00000000d0
      e( 21) =      0.46219470d0
      p( 21) =      1.00000000d0
      e( 22) =      0.15037120d0
      p( 22) =      1.00000000d0
      e( 23) =      0.85000000d0
      d( 23) =      1.00000000d0
c
 1000 return
      end
      subroutine dfttzvp_sh(nucz,ipass,itype,igauss,ng,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension igau(10,3), itypes(10,3)
      dimension kind(3)
      data kind/4, 8, 10 /
c
      data igau /
c  H,He
     + 3,1,1,1,0,0,0,0,0,0,
c  C-F
     + 7,1,1,1,4,1,1,1,0,0,
c  Na-Ar
     + 7,3,1,1,1,6,1,1,1,1/

      data itypes /
c  H,He
     + 1,1,1,2,0,0,0,0,0,0,
c  C-F
     + 1,1,1,1,2,2,2,3,0,0,
c Na-Ar
     + 1,1,1,1,1,2,2,2,2,3/
c
c     set values for the current tzvp_dft   shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3 for s,p,d shell
c            ng     = offset in e,cs,cp,cd arrays for current shell
c
      ind=1
      if(nucz.gt. 2) ind=2
      if(nucz.gt.10) ind=3
      if(nucz.gt.18) then
         call caserr2('tzvp_dft basis sets only extend to argon')
      end if
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if (odone) go to 100
c
       igauss = igau(ipass,ind)
       ng =0
       do loop = 1, ipass-1
        ng = ng + igau(loop,ind)
       enddo
       ityp = itypes(ipass,ind)
c
100   itype = ityp + 15
      return
      end
      subroutine ver_basis2(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/basis2.m,v $
     +     "/
      data revision /"$Revision: 5774 $"/
      data date /"$Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
_IF(notused)
      subroutine dgauss_a1_fitsh(nucz,ipass,itype,igauss,ng,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension igau(16,8), itypes(16,8)
      dimension kind(8)
      data kind/4, 8,10,12,13,14,15,16/
c     note all shells are single primitives in a1-fitting basis
      data igau /
     + 1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1/
      data itypes /
     + 1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,7,7,3,0,0,0,0,0,0,0,0,
     + 1,1,1,1,7,7,7,3,3,3,0,0,0,0,0,0,
     + 1,1,1,1,1,7,7,7,7,3,3,3,0,0,0,0,
     + 1,1,1,1,1,7,7,7,7,3,3,3,3,0,0,0,
     + 1,1,1,1,1,7,7,7,7,7,3,3,3,3,0,0,
     + 1,1,1,1,1,7,7,7,7,7,3,3,3,3,3,0,
     + 1,1,1,1,1,7,7,7,7,7,7,3,3,3,3,3 /
c
c     set values for the current dgauss_a1_  shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3 for s,p,d shell
c            ng     = offset in e,cs,cp,cd arrays for current shell
c
      ind=1
      if(nucz.gt. 2) ind=2
      if(nucz.gt. 4) ind=3
      if(nucz.gt.10) ind=4
      if(nucz.gt.12) ind=5
      if(nucz.gt.18) ind=6
      if(nucz.gt.30) ind=7
      if(nucz.gt.36) ind=8
      if(nucz.gt.38) ind=7
      if(nucz.gt.54) then
         call caserr2('dgauss_a1 basis sets only extend to xeon')
      end if
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if(odone) go to 100
c
       igauss = igau(ipass,ind)
       ng =0
       do loop = 1, ipass-1
        ng = ng + igau(loop,ind)
       enddo
       ityp = itypes(ipass,ind)
c
100   itype = ityp + 15
      return
      end
      subroutine dgauss_a2_fitsh(nucz,ipass,itype,igauss,ng,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension igau(15,5), itypes(15,5)
      dimension kind(5)
      data kind/5, 8,12,13,15/
c     note all shells are single primitives in a1-fitting basis
      data igau /
     + 1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1/
      data itypes /
     + 1,1,1,7,3,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,7,7,3,0,0,0,0,0,0,0,
     + 1,1,1,1,7,7,7,7,3,3,3,3,0,0,0,
     + 1,1,1,1,1,7,7,7,7,3,3,3,3,0,0,
     + 1,1,1,1,1,7,7,7,7,7,3,3,3,3,3 /
c
c     set values for the current dgauss_a2_  shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3,7 for s,p,d,sp shell
c            ng     = offset in e,cs,cp,cd arrays for current shell
c
      ind=1
      if(nucz.gt. 2) ind=2
      if(nucz.gt. 4) ind=3
      if(nucz.gt.10) ind=4
      if(nucz.gt.18) ind=5
      if(nucz.gt.30) then
         call caserr2('dgauss_a2 basis sets only extend to zinc')
      end if
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if(odone) go to 100
c
       igauss = igau(ipass,ind)
       ng =0
       do loop = 1, ipass-1
        ng = ng + igau(loop,ind)
       enddo
       ityp = itypes(ipass,ind)
c
100   itype = ityp + 15
      return
      end
      subroutine demon_fitsh(nucz,ipass,itype,igauss,ng,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension igau(16,9), itypes(16,9)
      dimension kind(9)
      data kind/4, 10, 8, 12, 12, 13, 14, 15, 16/
c     note all shells are single primitives in demon-fitting basis
      data igau /
     + 1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,
     + 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1/
      data itypes /
     + 1,1,1,7,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,7,7,7,3,3,3,0,0,0,0,0,0,
     + 1,1,1,1,1,7,7,3,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,7,7,7,3,3,3,0,0,0,0,
     + 1,1,1,1,1,7,7,7,7,3,3,3,0,0,0,0,
     + 1,1,1,1,1,7,7,7,7,3,3,3,3,0,0,0,
     + 1,1,1,1,1,7,7,7,7,7,3,3,3,3,0,0,
     + 1,1,1,1,1,7,7,7,7,7,3,3,3,3,3,0,
     + 1,1,1,1,1,7,7,7,7,7,7,3,3,3,3,3 /
c
c     set values for the current demon shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3,7 for s,p,d,sp shell
c            ng     = offset in e,cs,cp,cd arrays for current shell
c
c
      ind=1
      if(nucz.gt. 2) ind=2
      if(nucz.gt. 3) ind=3
      if(nucz.gt. 4) ind=2
      if(nucz.gt.10) ind=4
      if(nucz.gt.11) ind=5
      if(nucz.gt.12) ind=6
      if(nucz.gt.18) ind=7
      if(nucz.gt.20) ind=8
      if(nucz.gt.36) ind=9
      if(nucz.gt.38) ind=8
      if(nucz.gt.54) then
         call caserr2('demon basis sets only extend to xeon')
      end if
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if(odone) go to 100
c
       igauss = igau(ipass,ind)
       ng =0
       do loop = 1, ipass-1
        ng = ng + igau(loop,ind)
       enddo
       ityp = itypes(ipass,ind)
c
100   itype = ityp + 15
      return
      end
      subroutine ahlrichs_fitsh(nucz,ipass,itype,igauss,ng,odone)
      implicit REAL (a-h,p-w),integer (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension igau(20,18), itypes(20,18)
      dimension kind(18)
      data kind/6, 4, 12, 14, 15, 13, 10, 11, 12, 11,
     +         11,18, 17, 18, 18, 13, 14, 15 /
c
      data igau /
     + 2,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 3,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 3,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,
     + 3,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,
     + 3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,
     + 3,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,
     + 8,1,1,1,1,3,1,3,1,1,0,0,0,0,0,0,0,0,0,0,
     + 8,1,1,1,1,2,1,1,4,1,1,0,0,0,0,0,0,0,0,0,
     + 8,1,1,1,1,4,1,1,4,1,1,1,0,0,0,0,0,0,0,0,
     + 8,1,1,1,1,4,1,1,4,1,1,0,0,0,0,0,0,0,0,0,
     +10,2,1,1,1,1,3,1,3,1,1,0,0,0,0,0,0,0,0,0,
     +10,2,1,1,1,1,1,1,1,1,2,1,1,1,1,1,3,1,0,0,
     +10,2,1,1,1,1,1,1,1,1,3,1,1,1,1,3,1,0,0,0,
     +10,2,1,1,1,1,1,1,1,1,2,1,1,1,1,1,3,1,0,0,
     +10,2,1,1,1,1,1,1,1,1,1,3,1,1,1,1,3,1,0,0,
     +10,2,1,1,1,1,1,1,1,1,3,1,1,0,0,0,0,0,0,0,
     +10,2,1,1,1,1,1,1,1,1,4,1,1,1,0,0,0,0,0,0,
     +10,2,1,1,1,1,1,1,1,1,1,4,1,1,1,0,0,0,0,0/
c
      data itypes /
     + 1,1,1,2,2,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,2,2,3,3,4,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,2,2,2,3,3,3,4,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,2,2,2,3,3,3,3,4,0,0,0,0,0,
     + 1,1,1,1,1,1,2,2,2,3,3,3,4,0,0,0,0,0,0,0,
     + 1,1,1,1,1,2,2,3,3,4,0,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,2,2,2,3,3,4,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,2,2,2,3,3,4,5,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,2,2,2,3,3,4,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,2,2,3,3,4,0,0,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,2,2,2,2,3,3,3,4,4,4,5,5,0,0,
     + 1,1,1,1,1,1,2,2,2,2,3,3,4,4,4,5,5,0,0,0,
     + 1,1,1,1,1,1,2,2,2,2,3,3,3,4,4,4,5,5,0,0,
     + 1,1,1,1,1,1,1,2,2,2,2,3,3,4,4,4,5,5,0,0,
     + 1,1,1,1,1,1,2,2,2,2,3,3,4,0,0,0,0,0,0,0,
     + 1,1,1,1,1,1,2,2,2,2,3,3,4,5,0,0,0,0,0,0,
     + 1,1,1,1,1,1,1,2,2,2,2,3,3,4,5,0,0,0,0,0/
c
c     set values for the current ahlrichs  shell
c
c     return igauss = number of gaussians in current shell
c            ityp   = 1,2,3,4,5 for s,p,d,f,g shell
c            ng     = offset in e,cs,cp,cd arrays for current shell
c
      ind=1
      if(nucz.gt. 1) ind=2
      if(nucz.gt. 2) ind=3
      if(nucz.gt. 4) ind=4
      if(nucz.gt. 8) ind=5
      if(nucz.gt. 9) ind=6
      if(nucz.gt.10) ind=7
      if(nucz.gt.12) ind=8
      if(nucz.gt.13) ind=9
      if(nucz.gt.17) ind=10
      if(nucz.gt.18) ind=11
      if(nucz.gt.20) ind=12
      if(nucz.gt.21) ind=13
      if(nucz.gt.26) ind=14
      if(nucz.gt.27) ind=15
      if(nucz.gt.30) ind=16
      if(nucz.gt.31) ind=17
      if(nucz.gt.35) ind=18
      if(nucz.gt.36) then
         call caserr2('ahlrichs basis sets only extend to krypton')
      end if
c
      mxpass=kind(ind)
c
      if(ipass.gt.mxpass) odone=.true.
      if(odone) go to 100
c
       igauss = igau(ipass,ind)
       ng =0
       do loop = 1, ipass-1
        ng = ng + igau(loop,ind)
       enddo
       ityp = itypes(ipass,ind)
c
100   itype = ityp + 15
      return
      end
_ENDIF
