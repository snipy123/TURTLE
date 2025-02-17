 
c  $Author: jmht $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/drvmp.m,v $
c  $State: Exp $
c  
      subroutine mp2pdm(c,iblw,ifw,ifytr,ifdm,ifile1,ifint1,ifint2,maxq)
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/sizes)
      logical dpres, gpres
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/atmblk)
INCLUDE(common/symtry)
INCLUDE(common/nshel)
      dimension c(*)
c
c
      dpres = .false.
      fpres = .false.
      gpres = .false.
      do i = 1 , nshell
         dpres = dpres .or. ktype(i).eq.3
      end do
      do i = 1 , nshell
         fpres = fpres .or. ktype(i).eq.4
      end do
      do i = 1 , nshell
         gpres = gpres .or. ktype(i).eq.5
      end do
      ntrned = 16
      if (dpres) ntrned = 36
      if (fpres) ntrned = 100
      if (gpres) ntrned = 225
      n2 = ncoorb*ncoorb
      nov = nocca*nvirta
      ntri = ncoorb*(ncoorb+1)/2
      ireq = nov + n2*5 + ntri*ntrned
      if (ireq.gt.maxq) then
         write (iwr,6010) ireq , maxq
         call caserr(' not enough core for mp2 gradients')
      end if
c
      i0 = 1
      i1 = i0 + nw196(5)
      call rdedx(c(i0),nw196(5),ibl196(5),ifild)
      ieig = i1
      ia1 = ieig + ncoorb
      ia2 = ia1 + n2
      ib = ia2 + n2
      ivec = ib + nov
c     imapr = ivec + n2
c     ilmap = imapr + n2
c
      m9 = 9
      call secget(isect(9),m9,isec9)
      call rdedx(c(ieig),ncoorb,isec9,ifild)
c
      itype = 0
      call secget(isect(8),itype,ibl)
      ibl = ibl + mvadd
      call rdedx(c(ivec),n2,ibl,ifild)
      call mpsub2(c(i0),c(ieig),c(ia1),c(ia2),c(ib),c(ivec),ifint1,
     +  ifint2,ifw,nocca,nvirta,ncoorb,ncount,nshell)
      call delfil(ifint2)
      call delfil(ifint1)
      call mpsrt0(ifw,ifint1,nov,ncount,c(i1),c(i1),maxq-nw196(5))
      itype = 0
      call secget(isect(8),itype,ibl)
      ibl = ibl + mvadd
      call rdedx(c(i1),n2,ibl,ifild)
      call mpsub3(c(i1),c(n2+i1),c(n2+n2+i1),ifytr,ifdm,ncoorb,nocca,
     +  ifile1)
      cut = 10.0d0**(-icut)
      i1 = i0 + nw196(5)
      i2 = i1 + n2
      i3 = i2 + nov
      i4 = i3 + n2
      i5 = i4 + n2
      i6 = i5 + n2
      i7 = i6 + n2
c     itop = i7 + n2
      call mpsub4(c(i0),c(i1),c(i3),c(i2),c(i7),iblw,ifw,ifint1,nocca,
     +  nvirta,ncoorb,c(i4),c(i5),ifytr,ifdm,ntri,c(i6),ifile1,nshell,
     +  cut)
c
c
      return
 6010 format (/' insufficient core for mp2 gradients'/'  need ',i8,
     +        ' real words '/'  have ',i8,' real words')
      end
      subroutine mpsub2(iso,e,dum,r,b,vec,ifint1,ifint2,ifw,
     & nocca,nvirta,ncoorb,ncount,nshls)
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/symtry)
      dimension b(nocca*nvirta),dum(ncoorb*ncoorb)
      dimension e(ncoorb)
      dimension vec(ncoorb*ncoorb),r(ncoorb*ncoorb)
      logical ijump,jjump
      dimension iso(nshls,*),m0(48)
c
c     nov = nocca*nvirta
c
      nsq = ncoorb*ncoorb
      ntri = ncoorb*(ncoorb+1)/2
      call search(1,ifint1)
      call search(1,ifint2)
      call search(1,ifw)
c
      do 160 ip = nocca + 1 , ncoorb
         do 150 iq = 1 , nocca
            call rdedz(r,ntri,ifint1)
            call squr(r,dum,ncoorb)
            call rdedz(r,nsq,ifint2)
            ebj = e(ip) - e(iq)
            do 30 ia = nocca + 1 , ncoorb
               do 20 i = 1 , nocca
                  iai = (ia-nocca-1)*nocca + i
                  iaii = (ia-1)*ncoorb + i
                  b(iai) = (dum(iaii)*4.0d0-r(iaii)-r(iaii))
     +                     /(e(ia)+ebj-e(i))
 20            continue
 30         continue
            iv1 = ncoorb*nocca + 1
c
            call vclr(dum,1,ncoorb*ncoorb)
            call mxmb(vec(iv1),1,ncoorb,b,nocca,1,dum,nocca,1,ncoorb,
     +                nvirta,nocca)
            call vclr(r,1,ncoorb*ncoorb)
            call mxmb(vec,1,ncoorb,dum,1,nocca,r,1,ncoorb,ncoorb,nocca,
     +                ncoorb)
c
            do 40 im = 1 , ncoorb
               imm = (im-1)*ncoorb + im
               dum(imm) = r(imm)
 40         continue
c
            do 60 im = 2 , ncoorb
_IF1(ct)cdir$ ivdep
_IF1(a)cvd$  nodepck
_IF1(x)c$dir no_recurrence
               do 50 in = 1 , im - 1
                  imn = (in-1)*ncoorb + im
                  inm = (im-1)*ncoorb + in
                  dum(imn) = (r(imn)+r(inm))*0.5d0
                  dum(inm) = dum(imn)
 50            continue
 60         continue
c
            icount = 1
            do 140 ii = 1 , nshell
               ijump = .false.
               do 80 it = 1 , nt
                  id = iso(ii,it)
                  ijump = ijump .or. id.gt.ii
                  m0(it) = id
 80            continue
               mini = kmin(ii)
               maxi = kmax(ii)
               loci = kloc(ii) - mini
               do 130 jj = 1 , ii
                  jjump = .false.
                  do 100 it = 1 , nt
                     id = m0(it)
                     jd = iso(jj,it)
                     jjump = jjump .or. jd.gt.ii
                     if (id.lt.jd) then
                        nd = id
                        id = jd
                        jd = nd
                     end if
                     jjump = jjump .or. (id.eq.ii .and. jd.gt.jj)
 100              continue
                  minj = kmin(jj)
                  maxj = kmax(jj)
                  locj = kloc(jj) - minj
c
                  do 120 i = mini , maxi
                     i1 = loci + i
_IF1(x)c$dir scalar
_IF1(ct)cdir$ nextscalar
                     do 110 j = minj , maxj
                        j1 = locj + j
c
                        ij1 = (j1-1)*ncoorb + i1
                        r(icount) = dum(ij1)
                        if (ijump .or. jjump) r(icount) = 0.0d0
                        icount = icount + 1
 110                 continue
 120              continue
c
 130           continue
 140        continue
c
            ncount = icount - 1
            call wtedz(r,ncount,ifw)
 150     continue
 160  continue
      return
      end
      subroutine mpsub3(vec,y,ysym,ifytr,ifdm,ncoorb,nocca,ifile1)
c
      implicit REAL  (a-h,o-z)
      dimension y(ncoorb*ncoorb),ysym(ncoorb*ncoorb)
      dimension vec(ncoorb*ncoorb)
c
      call rdedx(y,ncoorb*ncoorb,ifytr,ifile1)
c
      do 30 i = 1 , ncoorb
         do 20 j = 1 , ncoorb
            ij = (j-1)*ncoorb + i
            ji = (i-1)*ncoorb + j
            ysym(ij) = (y(ij)+y(ji))*0.5d0
 20      continue
 30   continue
c
      call vclr(y,1,ncoorb*ncoorb)
      call mxmb(vec,1,ncoorb,vec,ncoorb,1,y,1,ncoorb,ncoorb,nocca,
     +          ncoorb)
c
      call wrt3(ysym,ncoorb*ncoorb,ifytr,ifile1)
      call wrt3(y,ncoorb*ncoorb,ifdm,ifile1)
c
c
      return
      end
      subroutine mpsub4(iso,vec,dum,d,b,iblw,ifw,ifort,nocca,nvirta,
     &         ncoorb,ys,css,ifytr,ifdm,ntri,wks,ifile1,nshls,cut)
c
      implicit REAL  (a-h,o-z)
      dimension d(nocca*nvirta),vec(ncoorb*ncoorb),
     1  dum(ncoorb*ncoorb),wks(ncoorb,ncoorb),b(2)
      dimension ys(ncoorb*ncoorb),css(ncoorb*ncoorb)
      dimension iso(nshls,*)
INCLUDE(common/sizes)
INCLUDE(common/symtry)
INCLUDE(common/atmblk)
INCLUDE(common/nshel)
INCLUDE(common/mapper)
      logical ijump,jjump
      dimension m0(48)
_IFN1(iv)      common/craypk/labout(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
      common/blkin/g(510),nint,nxtr
      logical lab,labc,labcd
      data mzero/0/
c
c
_IF1(c)      call szero(labout,1360)
_IF1(iv)      call setsto(1360,0,i205)
_IFN1(civ)      call setsto(1360,0,labout)
      nov = nocca*nvirta
      call rdedx(ys,ncoorb*ncoorb,ifytr,ifile1)
      call rdedx(css,ncoorb*ncoorb,ifdm,ifile1)
c
c
      call search(1,ifort)
      call search(iblw,ifw)
      nint = 0
c
      do 160 ii = 1 , nshell
         ijump = .false.
         do 30 it = 1 , nt
            id = iso(ii,it)
            ijump = ijump .or. id.gt.ii
            m0(it) = id
 30      continue
         iceni = katom(ii)
         do 150 jj = 1 , ii
            if (.not.(ijump)) then
               jjump = .false.
               do 50 it = 1 , nt
                  id = m0(it)
                  jd = iso(jj,it)
                  jjump = jjump .or. jd.gt.ii
                  if (id.lt.jd) then
                     nd = id
                     id = jd
                     jd = nd
                  end if
                  jjump = jjump .or. (id.eq.ii .and. jd.gt.jj)
 50            continue
               lab = katom(jj).eq.iceni
            end if
            mini = kmin(ii)
            minj = kmin(jj)
            maxi = kmax(ii)
            maxj = kmax(jj)
            loci = kloc(ii) - mini
            locj = kloc(jj) - minj
c
            ntimes = (maxi-mini+1)*(maxj-minj+1)
            imax = loci + maxi
            do 80 itimes = 1 , ntimes
               ib1 = (itimes-1)*ntri
c
               call rdedz(d,nov,ifort)
               if (.not.(ijump .or. jjump)) then
                  iv1 = ncoorb*nocca + 1
c
                  call vclr(dum,1,ncoorb*ncoorb)
                  call mxmb(vec(iv1),1,ncoorb,d,nocca,1,dum,1,ncoorb,
     +                      imax,nvirta,nocca)
                  call vclr(wks,1,ncoorb*ncoorb)
                  call mxmb(vec,1,ncoorb,dum,ncoorb,1,wks,1,ncoorb,imax,
     +                      nocca,imax)
c
                  do 70 ms1 = 1 , imax
                     do 60 ms2 = 1 , ms1
                        ms12 = iky(ms1) + ms2
                        b(ib1+ms12) = (wks(ms1,ms2)+wks(ms2,ms1))*0.5d0
 60                  continue
 70               continue
               end if
c
 80         continue
            if (.not.(ijump .or. jjump)) then
               do 140 kk = 1 , ii
                  labc = lab .and. katom(kk).eq.iceni
                  maxll = kk
                  if (kk.eq.ii) maxll = jj
                  do 130 ll = 1 , maxll
                     labcd = labc .and. katom(ll).eq.iceni
                     if (.not.(labcd)) then
                        mink = kmin(kk)
                        minl = kmin(ll)
                        maxk = kmax(kk)
                        maxl = kmax(ll)
                        lock = kloc(kk) - mink
                        locl = kloc(ll) - minl
                        icount = 1
                        do 120 i = mini , maxi
                           i1 = loci + i
c                          i11 = (i1-1)*ncoorb
                           do 110 j = minj , maxj
                              j1 = locj + j
                              j11 = (j1-1)*ncoorb
                              imn = j11 + i1
                              do 100 k = mink , maxk
                                 k1 = lock + k
                                 k11 = (k1-1)*ncoorb
                                 iml = k11 + i1
                                 inl = k11 + j1
_IF1(x)c$dir scalar
_IF1(ct)cdir$ nextscalar
                                 do 90 l = minl , maxl
                                    l1 = locl + l
c
                                    ikl = iky(max(k1,l1)) + min(k1,l1)
c
                                    l11 = (l1-1)*ncoorb
c
                                    ils = l11 + k1
                                    ims = l11 + i1
                                    ins = l11 + j1
c
c
                                    ipos = (icount-1)*ntri
                                    val = -b(ipos+ikl) + ys(imn)
     +                                 *css(ils) + ys(ils)*css(imn)
     +                                 - (ys(iml)*css(ins)+ys(ims)
     +                                 *css(inl)+ys(inl)*css(ims)
     +                                 +ys(ins)*css(iml))*0.25d0
c
c
                                    if (dabs(val).gt.cut) then
                                       nint = nint + 1
                                       g(nint) = val
_IF(ibm,vax)
                                       i205(nint) = i1
                                       j205(nint) = j1
                                       k205(nint) = k1
                                       l205(nint) = l1
                                       if (nint.eq.num2e) then
                                        call pak8v(g(num2e+1),i205)
_ELSE
                                       nint4 = nint + nint + nint + nint
                                       labout(nint4-3) = i1
                                       labout(nint4-2) = j1
                                       labout(nint4-1) = k1
                                       labout(nint4) = l1
                                       if (nint.eq.num2e) then
                                        call pack(g(num2e+1),lab816,
     +                                  labout,numlab)
_ENDIF
                                         call put(g,m511,ifw)
                                         nint = 0
_IF1(c)                                        call szero(labout,1360)
_IF1(iv)                                       call setsto(1360,0,i205)
_IFN1(civ)                                       call setsto(1360,0,labout)
                                       end if
                                    end if
c
 90                              continue
 100                          continue
                              icount = icount + 1
 110                       continue
 120                    continue
                     end if
 130              continue
 140           continue
            end if
 150     continue
 160  continue
c
_IFN1(iv)      call pack(g(num2e+1),lab816,labout,numlab)
_IF1(iv)      call pak8v(g(num2e+1),i205)
      call put(g,m511,ifw)
      call put(g,mzero,ifw)
      call clredx
      return
      end
_EXTRACT(mkmakw,mkmakw,pclinux)
      subroutine mkmakw(y,z,w,ibly,iblz,iblw,a1,a2,nocca,
     1   nvirta,ncoorb,ifils,e,ifint1,ifint2,ifile1)
c
      implicit REAL  (a-h,o-z)
      dimension y(ncoorb,ncoorb),w(ncoorb,ncoorb),
     1  z(nocca*nvirta),a1(ncoorb,ncoorb),a2(ncoorb,ncoorb),
     2 e(ncoorb)
c
      nsq = ncoorb*ncoorb
      ntri = ncoorb*(ncoorb+1)/2
      call rdedx(z,nocca*nvirta,iblz,ifils)
      call rdedx(y,nsq,ibly,ifile1)
      do 30 i = 1 , nocca
         do 20 ia = nocca + 1 , ncoorb
            iai = (ia-nocca-1)*nocca + i
            y(ia,i) = -z(iai)
 20      continue
 30   continue
      call wrt3(y,nsq,ibly,ifile1)
c
c
      call rdedx(a1,nsq,iblw,ifile1)
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
            call rdedz(a2,ntri,ifint1)
            call squr(a2,a1,ncoorb)
            call rdedz(a2,nsq,ifint2)
            do 130 iq = 1 , ncoorb
               do 120 ip = 1 , ncoorb
                  a1(ip,iq) = 4.0d0*a1(ip,iq) - a2(ip,iq) - a2(iq,ip)
 120           continue
 130        continue
            temp = ddot(ncoorb*ncoorb,y,1,a1,1)
            w(j,k) = w(j,k) + 0.5d0*temp
            if (j.ne.k) then
               w(k,j) = w(k,j) + 0.5d0*temp
            end if
 140     continue
 150  continue
c
      call wrt3(w,nsq,iblw,ifile1)
      return
      end
_ENDEXTRACT
      subroutine mp1pdm(a1,a2,e,ncoorb,y,zlg,
     1 nocca,istrmy,nvirt,t,
     2 iblw,iblks,ifils,b,mn,ifile1,ifint1,ifint2)
c
      implicit REAL  (a-h,o-z)
      dimension a1(ncoorb,ncoorb),a2(ncoorb,ncoorb),e(ncoorb),
     1 y(ncoorb,ncoorb),t(ncoorb,ncoorb)
     1,zlg(ncoorb,ncoorb),b(mn)
c
c
      nocc = nocca
      norbs = ncoorb
      nsq = norbs*norbs
      ntri = ncoorb*(ncoorb+1)/2
      nocc1 = nocc + 1
c     nocc2 = nocc + 2
      call vclr(y,1,norbs*norbs)
      call vclr(zlg,1,norbs*norbs)
c
      call search(1,ifint1)
      call search(1,ifint2)
      do 70 ip = nocca + 1 , norbs
         do 60 iq = 1 , nocca
            call rdedz(a2,ntri,ifint1)
            call squr(a2,a1,ncoorb)
            call rdedz(a2,nsq,ifint2)
c
            ebj = e(ip) - e(iq)
c
            do 30 ia = nocc1 , norbs
               do 20 i = 1 , nocc
                  t(i,ia) = 4.0d0*(a1(i,ia)+a1(i,ia)-a2(i,ia))
     +                      /(ebj+e(ia)-e(i))
 20            continue
 30         continue
c
            call mxmb(t(1,nocc1),1,norbs,a1(nocc1,1),1,norbs,zlg,norbs,
     +                1,nocc,nvirt,norbs)
            call mxmb(a1,1,norbs,t(1,nocc1),1,norbs,zlg(1,nocc1),1,
     +                norbs,norbs,nocc,nvirt)
c
            do 50 ia = nocc1 , norbs
               do 40 i = 1 , nocc
                  a1(i,ia) = 0.5d0*a1(i,ia)/(ebj+e(ia)-e(i))
 40            continue
 50         continue
c
            call mxmb(t(1,nocc1),norbs,1,a1(1,nocc1),1,norbs,
     +                y(nocc1,nocc1),1,norbs,nvirt,nocc,nvirt)
            call mxmb(t(1,nocc1),1,norbs,a1(1,nocc1),norbs,1,y,1,norbs,
     +                nocc,nvirt,nocc)
 60      continue
 70   continue
      do 90 ib = nocc1 , norbs
         do 80 ia = nocc1 , norbs
            y(ia,ib) = -y(ia,ib)
 80      continue
 90   continue
c
c......integral contribution complete
c...............to calculate t**2 contributions
c...............store partial sums j,a,b and i,j,b of t**
c
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
      call search(1,ifint2)
      call search(1,ifint1)
      do 170 ip = nocca + 1 , norbs
         do 160 iq = 1 , nocca
            call rdedz(a2,ntri,ifint1)
            call squr(a2,a1,ncoorb)
            call rdedz(a2,nsq,ifint2)
            do 150 j = 1 , norbs
               do 140 k = 1 , norbs
                  zlg(ip,iq) = zlg(ip,iq) + y(j,k)
     +                         *(a1(j,k)*4.0d0-a2(j,k)-a2(k,j))
 140           continue
 150        continue
 160     continue
 170  continue
c
      do 190 i = nocc1 , norbs
         do 180 j = 1 , nocc
            kt = (i-nocca-1)*nocca + j
            b(kt) = zlg(i,j) - zlg(j,i)
 180     continue
 190  continue
c........................b  is  now  calculated
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
_IFN(mp2_parallel)
      subroutine mpgrad(q,iq)
c
c     mp2 gradient driving routines
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension q(*),iq(*)
      common/mpases/mpass,ipass,mpst,mpfi,mpadd,iaoxf1,iaoxf2,moderf
INCLUDE(common/nshel)
INCLUDE(common/infoa)
INCLUDE(common/cigrad)
INCLUDE(common/symtry)
      common/maxlen/maxq
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
c
      common/small/eigs(maxorb)
      logical lstop,skipp
      dimension skipp(100)
INCLUDE(common/atmblk)
      character*10 charwall
c     character *8 grad
c     data grad/'gradient'/
c
c     l100 = 70 + lenint(60)
      mn = nocca*nvirta
c     nij = nocca*(nocca+1)/2
c     nab = nvirta*(nvirta+1)/2
      ntri = ncoorb*(ncoorb+1)/2
      nsq = ncoorb*ncoorb
      ifile1 = 1
      ifint1 = 17
      ifint2 = 18
      ifort2 = 19
c     istrma = 20
c     istrmd = 21
      call search(1,ifint1)
      call search(1,ifint2)
      call search(1,ifort2)
c     ndep = nab + nij
c     m103 = 103
      ityp = 0
c
c   set up blocks for ed0 for
c   1) gradient matrix (n3n,n3n)
c   2) workspace for the (rs/bj) derivative integral term
c   3) blank
c   4) e (ncoorb)
c   5) eder(ncoorb,ncoorb,n3n)
c   6) u(ncoorb,ncoorb,n3n)
c   7) y(ncoorb,ncoorb)
c   8) w(ncoorb,ncoorb)
c   9) w2(ncoorb,ncoorb)
c   10) wtrans(nbf,nbf)
c   11) ytrans(nbf,nbf)
c   12) dm(ncoorb,ncoorb)
c
      mpblk(1) = 1
      nat3 = nat*3
      mpblk(2) = mpblk(1) + lensec(nat3*nat3)
      mpblk(3) = mpblk(2) + lensec(nat3*nsq)
      mpblk(4) = mpblk(3)
      mpblk(5) = mpblk(4) + lensec(ncoorb)
      mpblk(6) = mpblk(5) + lensec(nsq*nat3)
      mpblk(7) = mpblk(6) + lensec(nsq*nat3)
      mpblk(8) = mpblk(7) + lensec(nsq)
      mpblk(9) = mpblk(8) + lensec(nsq)
      mpblk(10) = mpblk(9) + lensec(nsq)
      mpblk(11) = mpblk(10) + lensec(num*num)
      mpblk(12) = mpblk(11) + lensec(num*num)
      mpblk(13) = mpblk(12) + lensec(nsq)
      call revise
      call mpsrt4(q,iq,nocca,nvirta,ncoorb,kblk(1),nufile(1),ifint1)
      call mpsrt5(q,iq,nocca,nvirta,ncoorb,kblk(1),nufile(1),ifint2)
      i1 = igmem_alloc_all(maxa)
      call chfcls(q(i1),maxa)
      call gmem_free(i1)
c     write(6,*) 'sorting finished'
c     can get rid of ed6 here if necessary
      call delfil(nufile(1))
      call timit(3)
c
c   read in eigenvalues
c
      m9 = 9
      call secget(isect(9),m9,isec9)
      i2 = 1 + ncoorb
      i3 = i2 + nsq + lenint(nsq)
      i4 = i3 + nsq + lenint(nsq)
      i5 = i4 + nsq
      i6 = i5 + nsq
      i7 = i6 + nsq
      itop = i7 + nocca*nvirta
      if (itop.gt.maxq) then
         write (iwr,6010) maxq , itop
         call caserr(' not enough core for mp2 gradients')
      end if
c
      i0 = igmem_alloc(ncoorb)
      i2 = igmem_alloc(nsq+lenint(nsq))
      i3 = igmem_alloc(nsq+lenint(nsq))
      i4 = igmem_alloc(nsq)
      i5 = igmem_alloc(nsq)
      i6 = igmem_alloc(nsq)
      i7 = igmem_alloc(nocca*nvirta)
      call rdedx(q(i0),ncoorb,isec9,ifild)
      call mp1pdm(q(i2),q(i3),q(i0),ncoorb,q(i4),q(i5),nocca,
     +  mpblk(7),nvirta,q(i6),mpblk(8),iblks,ifils,q(i7),mn,ifile1,
     +  ifint1,ifint2)
      call gmem_free(i7)
      call gmem_free(i6)
      call gmem_free(i5)
      call gmem_free(i4)
      call gmem_free(i3)
      call gmem_free(i2)
c     call gmem_free(i1)
      call gmem_free(i0)
c
      m9 = 9
      ieps = igmem_alloc(nocca*nvirta)
      call secget(isect(9),m9,isec9)
      call rdedx(eigs,ncoorb,isec9,ifild)
      do 30 i = 1 , nocca
         do 20 iaa = nocca + 1 , ncoorb
            iai = (iaa-nocca-1)*nocca + i + ieps-1
            q(iai) = 1.0d0/(eigs(iaa)-eigs(i))
 20      continue
 30   continue
      np = 1
      npstar = 0
      skipp(1) = .false.
      lstop = .false.
c
c     solve for z-matrix
c
      call chfdrv(q(ieps),lstop,skipp)
      call gmem_free(ieps)
c
      call delfil(nofile(1))
c
      iy  = igmem_alloc(nsq)
      iz  = igmem_alloc(nocca*nvirta)
      iww = igmem_alloc(nsq)
      ia1 = igmem_alloc(nsq+lenint(nsq))
      ia2 = igmem_alloc(nsq+lenint(nsq))
      ie  = igmem_alloc(ncoorb)
      iblz = iblks + lensec(mn)
      m9 = 9
      call secget(isect(9),m9,isec9)
      call rdedx(q(ie),ncoorb,isec9,ifild)
c
      call mkmakw(q(iy),q(iz),q(iww),mpblk(7),iblz,mpblk(8),q(ia1),
     +  q(ia2),nocca,nvirta,ncoorb,ifils,q(ie),ifint1,ifint2,ifile1)
      call gmem_free(ie)
      call gmem_free(ia2)
      call gmem_free(ia1)
      call gmem_free(iww)
      call gmem_free(iz)
      call gmem_free(iy)
c
c     y,w,w2 matrices now stored on ed0 in the mo basis
c
c
      ityp = 0
      len = lensec(ntri)
c
      i1 = igmem_alloc(nsq)
      i2 = igmem_alloc(nsq)
      i3 = igmem_alloc(nsq)
      call secget(isect(8),8,iblok)
      iblok = iblok + mvadd
      call rdedx(q(i2),num*ncoorb,iblok,ifild)
c
      call rdedx(q(i1),nsq,mpblk(7),ifile1)
      call vtamv(q(i1),q(i2),q(i3),ncoorb)
      call wrt3(q(i1),nsq,mpblk(11),ifile1)
      call trsqsq(q(i1),q(i3),ncoorb)
      call secput(isecdd,ityp,len,isdd)
      call wrt3(q(i3),ntri,isdd,ifild)
      call rdedx(q(i1),nsq,mpblk(8),ifile1)
      call vtamv(q(i1),q(i2),q(i3),ncoorb)
      call wrt3(q(i1),nsq,mpblk(10),ifile1)
c
c   now because for some funny reason we are
c   calculating -w change the sign
c
      do 40 iijj = i1 , i1+nsq-1
         q(iijj) = -q(iijj)
 40   continue
      call trsqsq(q(i1),q(i3),ncoorb)
      call secput(isecll,ityp,len,isll)
      call wrt3(q(i3),ntri,isll,ifild)
      call gmem_free(i3)
      call gmem_free(i2)
      call gmem_free(i1)
c
      if (nprint.ne.-5) then
         dum = cpulft(1)
         write (iwr,6020) dum ,charwall()
      end if
      i1 = igmem_alloc_all(maxa)
      call mp2pdm(q(i1),iblk2d,ifil2d,mpblk(11),mpblk(12),ifile1,
     +  ifint1,ifint2,maxa)
      call gmem_free(i1)
      if (nprint.ne.-5) then
         dum = cpulft(1)
         write (iwr,6030) dum ,charwall()
      end if
      call timit(3)
c
      call revind
      call delfil(ifort2)
      call delfil(1)
      call delfil(ifint1)
      call delfil(ifint2)
      return
 6010 format (/' insufficient core for mp2 gradients'/'  have ',i8,
     +        ' real words '/'  need ',i8,' real words')
 6020 format (/1x,'construction of 1-particle gradient density matrices'
     +        ,' complete at',f8.2,' seconds',a10,' wall')
 6030 format (/1x,'construction of 2-particle gradient density matrices'
     +        ,' complete at',f8.2,' seconds',a10,' wall')
      end
_ENDIF
      subroutine rdsrt4(a,ia,iblki,ifili,nocca)
      implicit REAL  (a-h,o-z)
      dimension ia(*),a(*)
c
INCLUDE(common/sizes)
INCLUDE(common/three)
INCLUDE(common/stak)
INCLUDE(common/blksiz)
INCLUDE(common/atmblk)
INCLUDE(common/mapper)
      common/nap/mapy(maxorb)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
      common/bufb/nkk1,mkk1,g(1)
      common/junke/ibl5,ibl52,maxt,maxb,nadd,nij,n2,nbuck
      common/maxlen/maxq
      common/blkin/gin(510),nint
      common/junk/nwbuck(maxbuc)
      data lastb/999999/
c
c      pac2(n,m)=shiftl(n,32).or.m
c
c       open the sort file
c       each block consists of ibl5 real and ibl5 integer
c       words.
c       ibase gives offset for start of real part of each
c       block, as elements of a real array
c       ibasen gives offset for start of integer part of
c       each block , as elements of integer array.
c
      ibl5i = lenint(ibl5)
      do 20 ibuck = 1 , nbuck
         nwbuck(ibuck) = 0
         mark(ibuck) = lastb
         i = (ibuck-1)*(ibl5+ibl5i)
         ibase(ibuck) = i
         ibasen(ibuck) = lenrel(i+ibl5)
 20   continue
c
      call vclr(g,1,nsz340+nsz170)
c
      iblock = 0
c      ninb = no of elements in bucket(coreload)
      ninb = nadd*nij
c
      call search(iblki,ifili)
 30   call find(ifili)
      call get(gin,nw)
      if (nw.eq.0) then
c
c     empty anything remaining in buckets
c
         do 40 ibuck = 1 , nbuck
            nwb = nwbuck(ibuck)
            if (nwb.ne.0) then
               call stopbk
               mkk1 = mark(ibuck)
               nkk1 = nwb
_IFN1(iv)               call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)               call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)               call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)               call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
               call sttout
               nwbuck(ibuck) = 0
               mark(ibuck) = iblock
               iblock = iblock + nsz
            end if
 40      continue
c
c
         call stopbk
         return
      else
_IFN1(iv)         call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)         call upak8v(gin(num2e+1),i205)
         do 50 int = 1 , nint
_IFN1(iv)            n4 = int + int + int + int
_IF(ibm,vax)
            i1 = i205(int)
            j1 = j205(int)
            k1 = k205(int)
            l1 = l205(int)
_ELSEIF(littleendian)
            i1 = labs(n4-2)
            j1 = labs(n4-3)
            k1 = labs(n4  )
            l1 = labs(n4-1)
_ELSE
            i1 = labs(n4-3)
            j1 = labs(n4-2)
            k1 = labs(n4-1)
            l1 = labs(n4)
_ENDIF
            if (j1.gt.nocca .and. l1.gt.nocca) go to 50
            val = gin(int)
            if (j1.le.nocca) then
               ij = mapy(i1) + j1
               kl = iky(k1) + l1
c
c
               iaddr = (ij-1)*nij + kl
c
c     iaddr is address of integral in final sequence
c
               ibuck = (iaddr-1)/ninb
               iaddr = iaddr - ninb*ibuck
               ibuck = ibuck + 1
c
c     element goes in bucket ibuck with modified address
c
               nwb = nwbuck(ibuck) + 1
               a(ibase(ibuck)+nwb) = val
               ia(ibasen(ibuck)+nwb) = iaddr
               nwbuck(ibuck) = nwb
               if (nwb.eq.ibl5) then
c
c     this block full - empty
c
                  call stopbk
                  mkk1 = mark(ibuck)
                  nkk1 = nwb
_IFN1(iv)                  call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)                  call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)                  call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)                  call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
                  call sttout
                  nwbuck(ibuck) = 0
                  mark(ibuck) = iblock
                  iblock = iblock + nsz
               end if
c
c
c     now check if klij integral is different
c
c   caution! we are assuming that (vv/vv) integrals are not
c   present.  same applies to sorting of k matrices.
c
               if (l1.gt.nocca) go to 50
            end if
c
            ij = iky(i1) + j1
            kl = iky(k1) + l1
            if (ij.ne.kl) then
               ij = iky(i1) + j1
               kl = mapy(k1) + l1
               iaddr = (kl-1)*nij + ij
               ibuck = (iaddr-1)/ninb
               iaddr = iaddr - ninb*ibuck
               ibuck = ibuck + 1
c
c     element goes in bucket ibuck with modified address
c
               nwb = nwbuck(ibuck) + 1
               a(ibase(ibuck)+nwb) = val
               ia(ibasen(ibuck)+nwb) = iaddr
               nwbuck(ibuck) = nwb
               if (nwb.eq.ibl5) then
c
c
                  call stopbk
                  mkk1 = mark(ibuck)
                  nkk1 = nwb
_IFN1(iv)                  call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)                  call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)                  call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)                  call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
                  call sttout
                  nwbuck(ibuck) = 0
                  mark(ibuck) = iblock
                  iblock = iblock + nsz
               end if
c
            end if
c
 50      continue
         go to 30
      end if
      end
      subroutine rdsrt5(a,ia,iblki,ifili,ncoorb,nocca)
      implicit REAL  (a-h,o-z)
      dimension ia(*),a(*)
INCLUDE(common/sizes)
INCLUDE(common/three)
INCLUDE(common/stak)
INCLUDE(common/blksiz)
INCLUDE(common/atmblk)
      common/junk/nwbuck(maxbuc)
      common/bufb/nkk1,mkk1,g(1)
      common/junke/ibl5,ibl52,maxt,maxb,nadd,nij,n2,nbuck
      common/maxlen/maxq
      common/blkin/gin(510),nint
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
INCLUDE(common/mapper)
      common/nap/mapy(maxorb)
      data lastb/999999/
c
c       open the sort file
c       each block consists of ibl5 real and ibl5 integer
c       words.
c       ibase gives offset for start of real part of each
c       block, as elements of a real array
c       ibasen gives offset for start of integer part of
c       each block , as elements of integer array.
c
      ibl5i = lenint(ibl5)
      do 20 ibuck = 1 , nbuck
         nwbuck(ibuck) = 0
         mark(ibuck) = lastb
         i = (ibuck-1)*(ibl5+ibl5i)
         ibase(ibuck) = i
         ibasen(ibuck) = lenrel(i+ibl5)
 20   continue
c
      call vclr(g,1,nsz340+nsz170)
c
      iblock = 0
c     ninb = no of elements in bucket(coreload)
      ninb = nadd*n2
c
      call search(iblki,ifili)
 30   call find(ifili)
      call get(gin,nw)
      if (nw.eq.0) then
c
c     empty anything remaining in buckets
c
         do 40 ibuck = 1 , nbuck
            nwb = nwbuck(ibuck)
            if (nwb.ne.0) then
               call stopbk
               mkk1 = mark(ibuck)
               nkk1 = nwb
_IFN1(iv)               call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)               call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)               call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)               call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
               call sttout
               nwbuck(ibuck) = 0
               mark(ibuck) = iblock
               iblock = iblock + nsz
            end if
 40      continue
c
c
         call stopbk
         return
      else
_IFN1(iv)         call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)         call upak8v(gin(num2e+1),i205)
         do 60 int = 1 , nint
_IFN1(iv)            n4 = int + int + int + int
_IF(ibm,vax)
            i1 = i205(int)
            j1 = j205(int)
            k1 = k205(int)
            l1 = l205(int)
_ELSEIF(littleendian)
            i1 = labs(n4-2)
            j1 = labs(n4-3)
            k1 = labs(n4  )
            l1 = labs(n4-1)
_ELSE
            i1 = labs(n4-3)
            j1 = labs(n4-2)
            k1 = labs(n4-1)
            l1 = labs(n4)
_ENDIF
            if (j1.gt.nocca .and. l1.gt.nocca) go to 60
            val = gin(int)
            i11 = (i1-1)*ncoorb
            j11 = (j1-1)*ncoorb
            k11 = (k1-1)*ncoorb
            l11 = (l1-1)*ncoorb
c----------------------------------------------------------------
c     do the contribution to k([ik],j,l)
c
            if (k1.le.nocca) then
               ik = mapy(i1) + k1
               jl = l11 + j1
c
c
               iaddr = (ik-1)*n2 + jl
c
c     iaddr is address of integral in final sequence
c
               ibuck = (iaddr-1)/ninb
               iaddr = iaddr - ninb*ibuck
               ibuck = ibuck + 1
c
c     element goes in bucket ibuck with modified address
c
               nwb = nwbuck(ibuck) + 1
               a(ibase(ibuck)+nwb) = val
               ia(ibasen(ibuck)+nwb) = iaddr
               nwbuck(ibuck) = nwb
               if (nwb.eq.ibl5) then
c
c     this block full - so empty it
c
                  call stopbk
                  mkk1 = mark(ibuck)
                  nkk1 = nwb
_IFN1(iv)                  call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)                  call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)                  call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)                  call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
                  call sttout
                  nwbuck(ibuck) = 0
                  mark(ibuck) = iblock
                  iblock = iblock + nsz
               end if
c----------------------------------------------------------------
c     if i1=k1 then do k([ik],l,j) - if i1 .ne. k1
c     then this contribution arises when (il/kj) is
c     processed
c
               if (i1.eq.k1 .and. j1.ne.l1) then
                  ik = mapy(i1) + k1
                  jl = j11 + l1
                  iaddr = (ik-1)*n2 + jl
                  ibuck = (iaddr-1)/ninb
                  iaddr = iaddr - ninb*ibuck
                  ibuck = ibuck + 1
                  nwb = nwbuck(ibuck) + 1
                  a(ibase(ibuck)+nwb) = val
                  ia(ibasen(ibuck)+nwb) = iaddr
                  nwbuck(ibuck) = nwb
                  if (nwb.eq.ibl5) then
                     call stopbk
                     mkk1 = mark(ibuck)
                     nkk1 = nwb
_IFN1(iv)                     call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)                     call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)                     call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)                     call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
                     call sttout
                     nwbuck(ibuck) = 0
                     mark(ibuck) = iblock
                     iblock = iblock + nsz
                  end if
               end if
            end if
c
c
c-----------------------------------------------------------------
c
c     contribution to k([il],j,k)
c
            if (l1.le.nocca) then
               if (k1.ne.l1) then
c
c       if k1.eq.l1 contribution already covered
c       in k([ik],j,l) above
c
                  il = mapy(i1) + l1
                  jk = k11 + j1
c
                  iaddr = (il-1)*n2 + jk
c
                  ibuck = (iaddr-1)/ninb
                  iaddr = iaddr - ninb*ibuck
                  ibuck = ibuck + 1
c
                  nwb = nwbuck(ibuck) + 1
                  a(ibase(ibuck)+nwb) = val
                  ia(ibasen(ibuck)+nwb) = iaddr
                  nwbuck(ibuck) = nwb
                  if (nwb.eq.ibl5) then
c
                     call stopbk
                     mkk1 = mark(ibuck)
                     nkk1 = nwb
_IFN1(iv)                     call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)                     call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)                     call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)                     call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
                     call sttout
                     nwbuck(ibuck) = 0
                     mark(ibuck) = iblock
                     iblock = iblock + nsz
                  end if
               end if
c
c-------------------------------------------------------------------
c     contribution to k([jl],i,k) or k([jl],k,i)
c
               jl = mapy(j1) + l1
               ik = k11 + i1
c
               if (j1.ge.l1) go to 50
            end if
            jl = mapy(l1) + j1
            ik = i11 + k1
c
 50         iaddr = (jl-1)*n2 + ik
c
c
            ibuck = (iaddr-1)/ninb
            iaddr = iaddr - ninb*ibuck
            ibuck = ibuck + 1
c
            nwb = nwbuck(ibuck) + 1
            a(ibase(ibuck)+nwb) = val
            ia(ibasen(ibuck)+nwb) = iaddr
            nwbuck(ibuck) = nwb
            if (nwb.eq.ibl5) then
c
c
               call stopbk
               mkk1 = mark(ibuck)
               nkk1 = nwb
_IFN1(iv)               call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)               call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)               call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)               call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
               call sttout
               nwbuck(ibuck) = 0
               mark(ibuck) = iblock
               iblock = iblock + nsz
            end if
c
c--------------------------------------------------------------
c     if j1.eq.l1 then include k([jl],k,i)
c     if j1.ne.l1 then this is included when the integral
c     (il/kj) is processed
c
            if (l1.le.nocca) then
               if (j1.eq.l1 .and. i1.ne.k1) then
                  jl = mapy(j1) + l1
                  ik = i11 + k1
                  iaddr = (jl-1)*n2 + ik
                  ibuck = (iaddr-1)/ninb
                  iaddr = iaddr - ninb*ibuck
                  ibuck = ibuck + 1
                  nwb = nwbuck(ibuck) + 1
                  a(ibase(ibuck)+nwb) = val
                  ia(ibasen(ibuck)+nwb) = iaddr
                  nwbuck(ibuck) = nwb
                  if (nwb.eq.ibl5) then
                     call stopbk
                     mkk1 = mark(ibuck)
                     nkk1 = nwb
_IFN1(iv)                     call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)                     call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)                     call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)                     call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
                     call sttout
                     nwbuck(ibuck) = 0
                     mark(ibuck) = iblock
                     iblock = iblock + nsz
                  end if
               end if
            end if
c
c-------------------------------------------------------------
c     contribution to k([jk],i,l) or k([jk],l,i)
c
            if (i1.ne.j1) then
c
c       if i1.eq.j1 these contributions covered by
c       earlier terms
c
c      jk=mapy(j1)+k1
c      il=l11+i1
c
c      if(j1-k1)201,202,202
c201   jk=mapy(k1)+j1
c      il=i11+l1
c
               if (j1.lt.k1) then
                  if (j1.gt.nocca) go to 60
                  jk = mapy(k1) + j1
                  il = i11 + l1
               else
                  if (k1.gt.nocca) go to 60
                  jk = mapy(j1) + k1
                  il = l11 + i1
               end if
               iaddr = (jk-1)*n2 + il
c
               ibuck = (iaddr-1)/ninb
               iaddr = iaddr - ninb*ibuck
               ibuck = ibuck + 1
c
c
               nwb = nwbuck(ibuck) + 1
               a(ibase(ibuck)+nwb) = val
               ia(ibasen(ibuck)+nwb) = iaddr
               nwbuck(ibuck) = nwb
               if (nwb.eq.ibl5) then
c
c
                  call stopbk
                  mkk1 = mark(ibuck)
                  nkk1 = nwb
_IFN1(iv)                  call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)                  call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)                  call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)                  call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
                  call sttout
                  nwbuck(ibuck) = 0
                  mark(ibuck) = iblock
                  iblock = iblock + nsz
               end if
c
c-------------------------------------------------------------
c     if j1.eq.k1 then also include k([jk],l,i)
c     if j1.ne.k1 this comes from integral (ik/jl)
c
               if (j1.eq.k1 .and. i1.ne.l1) then
                  jk = mapy(j1) + k1
                  il = i11 + l1
c
                  iaddr = (jk-1)*n2 + il
c
                  ibuck = (iaddr-1)/ninb
                  iaddr = iaddr - ninb*ibuck
                  ibuck = ibuck + 1
c
                  nwb = nwbuck(ibuck) + 1
                  a(ibase(ibuck)+nwb) = val
                  ia(ibasen(ibuck)+nwb) = iaddr
                  nwbuck(ibuck) = nwb
                  if (nwb.eq.ibl5) then
c
                     call stopbk
                     mkk1 = mark(ibuck)
                     nkk1 = nwb
_IFN1(iv)                     call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
_IFN1(iv)                     call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_IF1(iv)                     call fmove ( a(ibase(ibuck)+1),g,ibl5)
_IF1(iv)                     call fmove ( ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
                     call sttout
                     nwbuck(ibuck) = 0
                     mark(ibuck) = iblock
                     iblock = iblock + nsz
                  end if
               end if
            end if
c
c
 60      continue
         go to 30
      end if
      end
      subroutine mpsrt4(q,iq,nocca,nvirta,ncoorb,iblki,ifili,
     * ifort)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
c
INCLUDE(common/mapper)
      common/nap/mapy(maxorb)
      common/junke/ibl5,ibl52,maxt,maxb,nadd,nij,n2,nbuck
      common/craypk/labs(1360)
INCLUDE(common/blksiz)
INCLUDE(common/atmblk)
INCLUDE(common/three)
      common/junk/nwbuck(maxbuc)
INCLUDE(common/iofile)
      dimension q(*),iq(*)
c
c     ibl5 = no of integrals in block of sortfile
c
      do 20 iip = 1 , ncoorb
         if (iip.gt.nocca) then
            mapy(iip) = (iip-nocca-1)*nocca
         else
            mapy(iip) = nocca*nvirta + iky(iip)
         end if
 20   continue
c
c
      ibl5 = nsz340
      iilen = nsz340*mach12/2
      call setsto(1360,0,labs)
      ibl52 = iilen
      ibl5i = lenint(ibl5)
      nij = ncoorb*(ncoorb+1)/2
      n2 = ncoorb*ncoorb
      noctri = nocca*(nocca+1)/2
      nall = nocca*nvirta + noctri
c
c       are going to sort the integrals from file ifili and
c       starting block iblki so that for ij (i.ge.j) all kl
c       integrals are available in a square on stream ifort
c
c       maxt is the number of triangles (squares for exchange ints)
c       which can be held in core (allowing n2 wkspace for reading back)
c       which is the number in each bucket
c
      i1  = igmem_alloc_all(maxq)
      ii1 = lenrel(i1-1)+1
      maxt = (maxq-n2)/nij
      nword = (maxq/(1+lenrel(1)))*lenrel(1)
c
c      maxb is the maximum number of blocks of the sortfile
c      which can be held in core
c      which is the maximum number of buckets
c
      maxb = min(maxbuc,nword/ibl5)
c
c     nbuck is the number of buckets required
c
      nbuck = (nall/maxt) + 1
      nadd = min(maxt,nall)
      maxa = nbuck*(ibl5+ibl5i) + n2
c
c
      if (nbuck.gt.maxb) then
         write (iwr,6010) maxq , maxa
         call caserr('insufficient memory available')
      end if
c
c       read through original file producing sorted file
c
      call vclr(q(i1),1,maxa)
      call setbfa
      call rdsrt4(q(i1),iq(ii1),iblki,ifili,nocca)
c
c       read through the sort file to give final result
c
c     maxqq = maxq - n2
      maxqq = nadd * nij
      call wtsrt4(q(i1+n2),maxqq,ifort,nall)
c
      call closbf(0)
      call gmem_free(i1)
      return
 6010 format (//1x,'insufficient core'/1x,'available',i8,'  required',
     +        i8)
      end
      subroutine mpsrt5(q,iq,nocca,nvirta,ncoorb,iblki,ifili,
     * ifort)
      implicit REAL  (a-h,o-z)
      common/junke/ibl5,ibl52,maxt,maxb,nadd,nij,n2,nbuck
      common/craypk/labs(1360)
INCLUDE(common/blksiz)
INCLUDE(common/atmblk)
INCLUDE(common/iofile)
      parameter (maxbuc=1500)
      dimension q(*),iq(*)
c
c
c     ibl5 = no of integrals in block of sortfile
c
      ibl5 = nsz340
      iilen = nsz340*mach12/2
      call setsto(1360,0,labs)
      ibl52 = iilen
      ibl5i = lenint(ibl5)
      nij = ncoorb*(ncoorb+1)/2
      n2 = ncoorb*ncoorb
      noctri = nocca*(nocca+1)/2
      nall = nocca*nvirta + noctri
c
c       are going to sort the integrals from file ifili and
c       starting block iblki so that for ij (i.ge.j) all kl
c       integrals are available in a square on stream ifort
c
c       maxt is the number of triangles (squares for exchange ints)
c       which can be held in core (allowing n2 wkspace for reading back)
c       which is the number in each bucket
c
      i1  = igmem_alloc_all(maxq)
      ii1 = lenrel(i1-1)+1
      maxt = (maxq-n2)/n2
      nword = (maxq/(1+lenrel(1)))*lenrel(1)
c
c      maxb is the maximum number of blocks of the sortfile
c      which can be held in core
c      which is the maximum number of buckets
c
      maxb = min(maxbuc,nword/ibl5)
c
c     nbuck is the number of buckets required
c
      nbuck = (nall/maxt) + 1
      nadd = min(maxt,nall)
      maxa = nbuck*(ibl5+ibl5i) + n2
c
c
      if (nbuck.gt.maxb) then
         write (iwr,6010) maxq , maxa
         call caserr('insufficient memory available')
      end if
c
c       read through original file producing sorted file
c
      call vclr(q(i1),1,maxa)
      call setbfa
      call rdsrt5(q(i1),iq(ii1),iblki,ifili,ncoorb,nocca)
c
c       read through the sort file to give final result
c
c     maxqq = maxq - n2
      maxqq = nadd * n2
      call wtsrt5(q(i1+n2),maxqq,ifort,nall)
      call closbf(0)
      call gmem_free(i1)
c
      return
 6010 format (//1x,'insufficient core'/1x,'available',i8,'  required',
     +        i8)
      end
      subroutine wtsrt4(q,maxqq,ifort,nall)
      implicit REAL  (a-h,o-z)
      dimension q(maxqq)
INCLUDE(common/three)
      common/junk/nwbuck(maxbuc)
INCLUDE(common/stak)
INCLUDE(common/blksiz)
      common/bufb/nkk,mkk,g(1)
      common/sortpk/labs(1)
      common/junke/ibl5,ibl52,maxt,maxb,nadd,nij,n2,nbuck
_IF1(iv)      dimension lin(2)
_IF1(iv)      equivalence (lin(1),g(1))
      data lastb/999999/
c
c    read thru the sort file to get core load of elements then
c    write them out on sequential file
c
      call rewedz(ifort)
c
      mmin = 1
      mmax = nadd
c
c     loop over buckets
c
      do 40 i = 1 , nbuck
         call vclr(q,1,maxqq)
         mkk = mark(i)
 20      if (mkk.eq.lastb) then
c
c     triangles mmin thru mmax are in core - clear them out
c
            j = 1
            do 30 n = mmin , mmax
c      call squr(q(j),buf,ncoorb)
               call wtedz(q(j),nij,ifort)
               j = j + nij
 30         continue
            mmin = mmin + nadd
            mmax = mmax + nadd
            if (mmax.gt.nall) mmax = nall
         else
c
c     loop over the sortfile blocks comprising this bucket
c
            iblock = mkk
            call rdbak(iblock)
            call stopbk
_IFN1(iv)            call unpack(g(nsz341),32,labs,ibl5)
_IFN1(civ)            call dsctr(nkk,g,labs,q)
_IF1(c)            call scatter(nkk,q,labs,g)
_IF1(iv)            ij = ibl5+ibl5+1
_IF1(iv)            do 4000 iword=1,nkk
_IF1(iv)            q(lin(ij)) = g(iword)
_IF1(iv) 4000       ij = ij+1
            go to 20
         end if
 40   continue
      return
      end
      subroutine wtsrt5(q,maxqq,ifort,nall)
      implicit REAL  (a-h,o-z)
c
      dimension q(maxqq)
INCLUDE(common/three)
      common/junk/nwbuck(maxbuc)
INCLUDE(common/stak)
INCLUDE(common/blksiz)
      common/bufb/nkk,mkk,g(1)
      common/sortpk/labs(1)
      common/junke/ibl5,ibl52,maxt,maxb,nadd,nij,n2,nbuck
_IF1(iv)      dimension lin(2)
_IF1(iv)      equivalence (lin(1),g(1))
      data lastb/999999/
c
c    read thru the sort file to get core load of elements then
c    write them out on sequential file
c
      call rewedz(ifort)
c
      mmin = 1
      mmax = nadd
c
c     loop over buckets
c
      do 40 i = 1 , nbuck
         call vclr(q,1,maxqq)
         mkk = mark(i)
 20      if (mkk.eq.lastb) then
c
c     squares min thru mmax are in core - clear them out
c
            j = 1
            do 30 n = mmin , mmax
               call wtedz(q(j),n2,ifort)
               j = j + n2
 30         continue
            mmin = mmin + nadd
            mmax = mmax + nadd
            if (mmax.gt.nall) mmax = nall
         else
c
c     loop over the sortfile blocks comprising this bucket
c
            iblock = mkk
            call rdbak(iblock)
            call stopbk
_IFN1(iv)            call unpack(g(nsz341),32,labs,ibl5)
_IFN1(civ)            call dsctr(nkk,g,labs,q)
_IF1(c)            call scatter(nkk,q,labs,g)
_IF1(iv)            ij = ibl5+ibl5+1
_IF1(iv)            do 4000 iword=1,nkk
_IF1(iv)            q(lin(ij)) = g(iword)
_IF1(iv) 4000       ij = ij+1
            go to 20
         end if
 40   continue
      return
      end
      subroutine ver_drvmp(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/drvmp.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
