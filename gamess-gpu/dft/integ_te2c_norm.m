c 
c  $Author: jmht $
c  $Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
c  $Locker:  $
c  $Revision: 5774 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/dft/integ_te2c_norm.m,v $
c  $State: Exp $
c
      subroutine te2c_rep_norm(icd_tag,gout,rmatrix)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
***************************************************************
* common blocks used
**************************************************************
**** from main-line code
*********************************************************************
* cslosc * files * infoa *  parallel * parcntl 
* prints * restar * sizes * statis * timez
***************************************************************
* local common blocks
*
* tabinx, junkx, mapperx, flipsx, flip7x, ijlabx
* pqgeomx, qgeomx, pgeomx, geomx, shlg70x, piconx, miscgx, astorex
* ginfx, bshellx, constx, shllfox, maxcx, savecx, typex
* shlinfx
* shltx, miscx, setintx, rootx, denssx, shlnosx, indezx, rtdatx
* inxblkx
********************************************************************
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/cslosc)
INCLUDE(../m4/common/infoa)
INCLUDE(../m4/common/statis)
INCLUDE(../m4/common/restar)
INCLUDE(../m4/common/timez)
c
INCLUDE(../m4/common/parallel)
INCLUDE(../m4/common/parcntl)
c
INCLUDE(common/dft_mbasis)
INCLUDE(common/dft_shlt)
INCLUDE(common/dft_mapper)
INCLUDE(common/dft_ijlab)
INCLUDE(common/dft_picon)
INCLUDE(common/dft_root)
ccINCLUDE(common/dft_auxvar)
INCLUDE(common/dft_iofile)
c
      dimension gout(*)
      dimension rmatrix(*)
c
      data done/1.0d0/,two/2.0d0/,twopt5/2.5d0/,four/4.0d0/
c
      call cpuwal(begin,ebegin)
c ***
c *** establish arrays normally set in main line code
c ***
c
c ... /mapperx/
c
      do 30 i = 1 , maxorb
         k = i*(i-1)/2
         iky(i) = k
 30   continue
c
c ... /piconx/
c
      pidiv4 = datan(done)
      pi = four*pidiv4
      pito52 = two*pi**twopt5
      root3 = dsqrt(3.0d0)
      root5 = dsqrt(5.0d0)
      root53= root5/root3
      root7 = dsqrt(7.0d0)
c
c ... /rootx/
c
      do 20 loop = 1 , 60
         dji(loop) = 1.0d0/(loop+loop-1)
 20   continue
c
c ... /auxvarx/
c
c      ofast = .false.
c
c /cslosc/
c
      call setsto(10,0,intcut)
      call setsto(1060,0,intmag)
      nopk = 1
c
c     check for pure sp basis. if so, do gaussian integrals.
      call spchck_dft
      nopkr = nopk
      iofrst = iofsym
      nindmx = 1
      call jkint_gamess_norm(icd_tag,gout,rmatrix)
      call final_dft
      return
      end
      subroutine jkint_gamess_norm(icd_tag,gout,rmatrix)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(../m4/common/sizes)
      parameter (mxp2 = mxprms * mxprms)
INCLUDE(../m4/common/cslosc)
INCLUDE(../m4/common/restar)
c
INCLUDE(common/dft_mbasis)
INCLUDE(common/dft_mapper)
INCLUDE(common/dft_shlnos)
INCLUDE(common/dft_shlt)
INCLUDE(common/dft_ijlab)
INCLUDE(common/dft_shlg70)
INCLUDE(common/dft_picon)
INCLUDE(common/dft_misc)
INCLUDE(common/dft_indez)
INCLUDE(common/dft_iofile)
c
c     ----- size of gout -
c                         1   if s or k shells
c                        81   if p      shells
c                       256   if      l shells
c                      1296   if d or m shells
c                     10000   if f shells
c                     50625   if g shells
c
c     ----- this version can handle g shells   -----
c
      common/junkx/cxyz(3,5625),aaa(21*mxp2),ijaaa(225)
INCLUDE(../m4/common/timez)
INCLUDE(common/dft_flips)
INCLUDE(../m4/common/parallel)
c
      dimension ib(4,4)
      dimension gout(*)
      dimension rmatrix(*)
      data ib/64,16,4,1,216,36,6,1,1000,100,10,1,
     +         3375,225,15,1 /
c
c     ----- two-electron integrals -----
c
      ii = 1
      if (opdbas) then
         ii = 2
      end if
      if (opfbas) then
         ii = 3
      end if
      if (opgbas) then
         ii = 4
      end if
      do 30 loop = 1 , 3
        igt(loop) = ib(1,ii)
        jgt(loop) = ib(2,ii)
        kgt(loop) = ib(3,ii)
        lgt(loop) = ib(4,ii)
 30   continue
c
c     ----- set some parameters -----
c
c
      imc=0
c
c     l2 = iky(numorb(1))+numorb(1)
c
      time = cpulft(1)
      tim0 = time
      tim1 = time
c
      ist0 = ist
      jst0 = jst
      kst0 = kst
      lst0 = lst
c
c     are the rotated axis integrals to be used only?
c
      ogauss = .true.
c
cc      if (intg76.ne.0) call filmax_2c
c
c     ----- ishell -----
c
      jnn=0
      do 150 ii = 1 , nshell(icd_tag)
c
c     ----- print intermediate restart data -----
c
         ishell = ii
         dt0 = time - tim0
         dt1 = time - tim1
         tim1 = time
         ikyii = iky(ii)
c
c     ----- jshell -----
c
         j0 = jst0
         jj=1
         jst0 = 1
         minj = 1
         maxj = 1
         itrij = ikyii + jj
c
c     ----- get information about i-shell and j-shell -----
c
         jshell = 0
         locj = 1
         idum = 0

         call shells_dft(gout,1,ishell,jshell,ishell,jshell,
     &        icd_tag,-1,icd_tag,-1,2,1,idum)

         call ijprim_dft(2)
         if (nij.eq.0) go to 170
c
c     ----- kshell -----
c
               k0 = kst0
               kmc=0
               kk=ii
               kst0 = 1
               ikykk = iky(kk)
               kshell = kk
               mink = mini
               maxk = maxi
               lock = loci
               itrjk = iky(max(jj,kk)) + min(jj,kk)
c
c     ----- lshell ----
c
               maxll = kk
               maxll = jj
               ll=1
               q4 = 1.0d0
c
c     ----- (ii,jj//kk,ll) -----
c
               lshell = 0
               qq4 = q4
C *
C *For shell quartet with no sp shell(s)
C *
c
c     ----- get information about ksh and lsh -----
c
                    idum = 0
                    call shells_dft(gout,2,
     &                   ishell,jshell,ishell,jshell,
     &                   icd_tag,-1,icd_tag,-1,2,1,idum)

                    call genral_dft(gout,2)
                    inn=0
                    do i=mini,maxi
                      jnn=jnn+1
                      inn=inn+1
                      knn=0
                      nn=ijgt(inn)+klgt(inn)
                      rmatrix(jnn)=gout(nn)
                    enddo
C *
C *For shells quartet containing sp shell(s)
C *
c
c
 170       continue
 150     continue
c
c
      return
      end
c
      subroutine te2c_rep_schwarz(icd_tag,gout,rmatrix)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
c...  computes the 2 centre 2 electron integrals needed for 
c...  applying the Schwarz inequality to 3 centre 2 electron
c...  integrals.
c
***************************************************************
* common blocks used
**************************************************************
**** from main-line code
*********************************************************************
* cslosc * files * infoa *  parallel * parcntl 
* prints * restar * sizes * statis * timez
***************************************************************
* local common blocks
*
* tabinx, junkx, mapperx, flipsx, flip7x, ijlabx
* pqgeomx, qgeomx, pgeomx, geomx, shlg70x, piconx, miscgx, astorex
* ginfx, bshellx, constx, shllfox, maxcx, savecx, typex
* shlinfx
* shltx, miscx, setintx, rootx, denssx, shlnosx, indezx, rtdatx
* inxblkx
********************************************************************
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/cslosc)
INCLUDE(../m4/common/infoa)
INCLUDE(../m4/common/statis)
INCLUDE(../m4/common/restar)
INCLUDE(../m4/common/timez)
c
INCLUDE(../m4/common/parallel)
INCLUDE(../m4/common/parcntl)
c
INCLUDE(common/dft_mbasis)
INCLUDE(common/dft_shlt)
INCLUDE(common/dft_mapper)
INCLUDE(common/dft_ijlab)
INCLUDE(common/dft_picon)
INCLUDE(common/dft_root)
ccINCLUDE(common/dft_auxvar)
INCLUDE(common/dft_iofile)
c
      dimension gout(*)
      dimension rmatrix(*)
c
      data done/1.0d0/,two/2.0d0/,twopt5/2.5d0/,four/4.0d0/
c
      call cpuwal(begin,ebegin)
c ***
c *** establish arrays normally set in main line code
c ***
c
c ... /mapperx/
c
      do 30 i = 1 , maxorb
         k = i*(i-1)/2
         iky(i) = k
 30   continue
c
c ... /piconx/
c
      pidiv4 = datan(done)
      pi = four*pidiv4
      pito52 = two*pi**twopt5
      root3 = dsqrt(3.0d0)
      root5 = dsqrt(5.0d0)
      root53= root5/root3
      root7 = dsqrt(7.0d0)
c
c ... /rootx/
c
      do 20 loop = 1 , 60
         dji(loop) = 1.0d0/(loop+loop-1)
 20   continue
c
c ... /auxvarx/
c
c      ofast = .false.
c
c /cslosc/
c
      call setsto(10,0,intcut)
      call setsto(1060,0,intmag)
      nopk = 1
c
c     check for pure sp basis. if so, do gaussian integrals.
      call spchck_dft
      nopkr = nopk
      iofrst = iofsym
      nindmx = 1
      call jkint_gamess_schwarz(icd_tag,gout,rmatrix)
      call final_dft
      return
      end
      subroutine jkint_gamess_schwarz(icd_tag,gout,rmatrix)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(../m4/common/sizes)
      parameter (mxp2 = mxprms * mxprms)
INCLUDE(../m4/common/cslosc)
INCLUDE(../m4/common/restar)
c
INCLUDE(common/dft_mbasis)
INCLUDE(common/dft_mapper)
INCLUDE(common/dft_shlnos)
INCLUDE(common/dft_shlt)
INCLUDE(common/dft_ijlab)
INCLUDE(common/dft_shlg70)
INCLUDE(common/dft_picon)
INCLUDE(common/dft_misc)
INCLUDE(common/dft_indez)
INCLUDE(common/dft_iofile)
c
c     ----- size of gout -
c                         1   if s or k shells
c                        81   if p      shells
c                       256   if      l shells
c                      1296   if d or m shells
c                     10000   if f shells
c                     50625   if g shells
c
c     ----- this version can handle g shells   -----
c
      common/junkx/cxyz(3,5625),aaa(21*mxp2),ijaaa(225)
INCLUDE(../m4/common/timez)
INCLUDE(common/dft_flips)
INCLUDE(../m4/common/parallel)
c
      dimension ib(4,4)
      dimension gout(*)
      dimension rmatrix(*)
      data ib/64,16,4,1,216,36,6,1,1000,100,10,1,
     +         3375,225,15,1 /
c
c     ----- two-electron integrals -----
c
      ii = 1
      if (opdbas) then
         ii = 2
      end if
      if (opfbas) then
         ii = 3
      end if
      if (opgbas) then
         ii = 4
      end if
      do 30 loop = 1 , 3
        igt(loop) = ib(1,ii)
        jgt(loop) = ib(2,ii)
        kgt(loop) = ib(3,ii)
        lgt(loop) = ib(4,ii)
 30   continue
c
c     ----- set some parameters -----
c
c
      imc=0
c
c     l2 = iky(numorb(1))+numorb(1)
c
      time = cpulft(1)
      tim0 = time
      tim1 = time
c
      ist0 = ist
      jst0 = jst
      kst0 = kst
      lst0 = lst
c
c     are the rotated axis integrals to be used only?
c
      ogauss = .true.
c
cc      if (intg76.ne.0) call filmax_2c
c
c     ----- ishell -----
c
      jnn=0
      do 150 ii = 1 , nshell(icd_tag)
c
c     ----- print intermediate restart data -----
c
         ishell = ii
         dt0 = time - tim0
         dt1 = time - tim1
         tim1 = time
         ikyii = iky(ii)
c
c     ----- jshell -----
c
         j0 = jst0
         jj=1
         jst0 = 1
         minj = 1
         maxj = 1
         itrij = ikyii + jj
c
c     ----- get information about i-shell and j-shell -----
c
         jshell = 0
         locj = 1

         call shells_dft(gout,1,ishell,jshell,ishell,jshell,
     &        icd_tag,-1,icd_tag,-1,2,1,idum)

         call ijprim_dft(2)
         if (nij.eq.0) go to 170
c
c     ----- kshell -----
c
               k0 = kst0
               kmc=0
               kk=ii
               kst0 = 1
               ikykk = iky(kk)
               kshell = kk
               mink = mini
               maxk = maxi
               lock = loci
               itrjk = iky(max(jj,kk)) + min(jj,kk)
c
c     ----- lshell ----
c
               maxll = kk
               maxll = jj
               ll=1
               q4 = 1.0d0
c
c     ----- (ii,jj//kk,ll) -----
c
               lshell = 0
               qq4 = q4
C *
C *For shell quartet with no sp shell(s)
C *
c
c     ----- get information about ksh and lsh -----
c
                    idum = 0
                    call shells_dft(gout,2,
     &                   ishell,jshell,ishell,jshell,
     &                   icd_tag,-1,icd_tag,-1,2,1,idum)
                    call genral_dft(gout,2)
                    inn=0
                    rmax = 0.0d0
                    do i=mini,maxi
                      jnn=jnn+1
                      inn=inn+1
                      knn=0
                      nn=ijgt(inn)+klgt(inn)
                      rmax=max(rmax,gout(nn))
                    enddo
                    rmatrix(ii)=sqrt(rmax)
C *
C *For shells quartet containing sp shell(s)
C *
c
c
 170       continue
 150     continue
c
c
      return
      end
      subroutine ver_dft_integ_te2c_norm(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/dft/integ_te2c_norm.m,v $
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
