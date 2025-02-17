c     deck=drv1e
c ******************************************************
c ******************************************************
c             =   dr1e   =
c ******************************************************
c ******************************************************
      subroutine czderv(nat,natmod,de,c,cmod,czan,czmod,nbact)
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character*8 (z), character*1 (x), character*4 (y)
INCLUDE(common/sizes)
c ...
c     ----- routine to evaluate the gradient due the nuclear
c           and surrounding interactions -----
c ...
      dimension de(*),c(*),cmod(*),czan(*),czmod(*),nbact(*)
      data dzero/0.0d+00/
_IF(secd_parallel)
csecd
c this loop is not parallel in the || secd version
c
_ELSEIF(parallel)
c***   **MPP**
      iflop = iipsci()
c***   **MPP**
_ENDIF
      iat3 = -3
      do 30 i = 1 , nat
         iat3 = iat3 + 3
         iat = i
         czang = czan(i)
         gx = c(iat3+1)
         gy = c(iat3+2)
         gz = c(iat3+3)
         dumx = dzero
         dumy = dzero
         dumz = dzero
         jc3 = -3
         do 20 j = 1 , natmod
         jc3 = jc3 + 3
_IF(secd_parallel)
csecd
c not || in || secd version
_ELSEIF(parallel)
c***   **MPP**
         if (oipsci()) go to 20
c***   **MPP**
_ENDIF
            jat = j
            call skip80(iat,iat,jat,nbact,oskip)
            if (.not.oskip) then
               czanv = czmod(j)
               cx = gx - cmod(jc3+1)
               cy = gy - cmod(jc3+2)
               cz = gz - cmod(jc3+3)
               rij = cx*cx + cy*cy + cz*cz
               df = czang*czanv/(rij*dsqrt(rij))
               dumx = dumx + df*cx
               dumy = dumy + df*cy
               dumz = dumz + df*cz
            end if
 20      continue
         de(iat3+1) = de(iat3+1) - dumx
         de(iat3+2) = de(iat3+2) - dumy
         de(iat3+3) = de(iat3+3) - dumz
 30   continue
      return
      end
_IF(mp2_parallel,masscf)
c
c gdf:  version for mp2 and scf and vb  gradients using GA & MA tools
c
      subroutine dendd1(zscftp,da,db,dens,pmat,n)
      implicit none
      REAL da, db, dens, pmat
      integer i,j,k,n,l2,m990,ibl990
      dimension da(*),db(*),dens(n,n), pmat(n,n)
INCLUDE(common/restrl)
INCLUDE(common/dump3)
INCLUDE(common/dm)
INCLUDE(common/iofile)
      character *8 zscftp
      character *8 zuhf,zgvb,zvb
      data zuhf, zgvb, zvb /'uhf', 'gvb' , 'vb' /
      data m990/990/
                           
c      call wrtsqm_ga('P(HF) matrix',n,dens)
c      call wrtsqm_ga('P(2) matrix',n,pmat)

c     write(6,*)'***** DENDD1 entered', zscftp,n
      l2 = n*(n+1)/2
      if (mp2) then
        k = 0
        do i = 1 , n
          do j = 1 , i
            k = k + 1
            da(k) = 2*dens(i,j) + pmat(i,j)
          end do
        end do
      else if (zscftp .eq. 'rhf') then 
         call rdedx(da,l2,ibl3pa,idaf)
      else if (zscftp.eq. zgvb. or. zscftp. eq. zuhf) then
         call rdedx(da,l2,ibl3pa,idaf)
         call rdedx(db,l2,ibl3pb,idaf)
         call vadd(da,1,db,1,da,1,l2)
      else if (zscftp.eq.zvb) then
         call secget(isecda,m990,ibl990)
         call rdedx(da,l2,ibl990,idaf)
      else
         write(6,*)' SCFTYPE = ', zscftp
         call caserr(
     +  'no parallel implementation of scftype for the current runtype')
      end if

c      call wrtvec_ga('2P(HF) + P(2) ',n*(n+1)/2,da)
*     write(6,*)' ***** return from DENDD1'
      return
      end
_ELSE
      subroutine dendd1(zscftp,da,db,l2)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      character *8 title,scftyp,runtyp,guess,conf,fkder
      character *8 scder,dpder,plder,guesc,rstop,charsp
      common/restrz/title(10),scftyp,runtyp,guess,conf,fkder,
     + scder,dpder,plder,guesc,rstop,charsp(30)
c
INCLUDE(common/restar)
INCLUDE(common/restrl)
INCLUDE(common/restri)
INCLUDE(common/cndx41)
INCLUDE(common/dm)
INCLUDE(common/atmblk)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/cigrad)
INCLUDE(common/infoa)
      dimension da(*),db(*)
      data m990/990/
      data zuhf,zrhf,zcas,zmcscf,zvb/'uhf','rhf','casscf','mcscf','vb'/
c
      if (zscftp.eq.zcas.or.zscftp.eq.zvb) then
         call secget(isecda,m990,ibl990)
         call rdedx(da,l2,ibl990,idaf)
         return
c
      else if (zscftp.eq.zrhf) then
         call rdedx(da,l2,ibl3pa,idaf)
c
      else if (zscftp.eq.zmcscf .or. lci .or. lmcscf .or. cigr .or.
     +         mcgr) then
c
         call secloc(isecdd,oexst,ibldd)
         if (oexst) then
            call rdedx(da,l2,ibldd,idaf)
         else
            call caserr('ci density matrix not found')
         end if
         if (ncore.gt.0) then
            call secloc(isecmo,oexst,iblmo)
            if (oexst) then
               call rdedx(db,num*ncoorb,iblmo+mvadd,idaf)
            else
               call caserr('mcscf vectors not found')
            end if
            ij = 0
            do 40 i = 1 , num
               do 30 j = 1 , i
                  ij = ij + 1
                  do 20 k = 1 , ncore
                     kk = (k-1)*num
                     da(ij) = da(ij) + 2.0d0*db(kk+i)*db(kk+j)
 20               continue
 30            continue
 40         continue
         end if
c
      else
c
         call rdedx(da,l2,ibl3pa,idaf)
         call rdedx(db,l2,ibl3pb,idaf)
         call vadd(da,1,db,1,da,1,l2)
      end if
      if (mp2 .or. mp3) then
         if (zscftp.eq.zrhf .or. zscftp.eq.zuhf) then
            call secloc(isecdd,oexst,ibldd)
            if (.not.oexst .and. zscftp.eq.zrhf .and. mp2)
     +          call secloc(isect(45),oexst,ibldd)
            if (.not.oexst) return
            call rdedx(db,l2,ibldd,idaf)
            do 50 loop = 1 , l2
               da(loop) = da(loop) + db(loop)
 50         continue
         end if
      end if
      return
      end
_ENDIF
      subroutine dvint
c
c     ----- gauss-hermite quadrature using minimum point formula -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/junk/desp(3,maxat),
     *pint,qint,rint,t,p0,q0,r0,pi,qi,ri,pj,qj,rj,ni,nj
     + ,cx,cy,cz
INCLUDE(common/hermit)
INCLUDE(common/wermit)
      dimension min(7),max(7)
      data min /1,2,4,7,11,16,22/
      data max /1,3,6,10,15,21,28/
      data dzero /0.0d0/
c
      pint = dzero
      qint = dzero
      rint = dzero
      npts = (ni+nj+1-2)/2 + 1
      imin = min(npts)
      imax = max(npts)
      do 140 i = imin , imax
         dum = h(i)*t
         ptx = dum + p0
         pty = dum + q0
         ptz = dum + r0
         px = ptx - cx
         py = pty - cy
         pz = ptz - cz
         ax = ptx - pi
         ay = pty - qi
         az = ptz - ri
         bx = ptx - pj
         by = pty - qj
         bz = ptz - rj
         go to (60,50,40,30,20,10) , ni
 10      px = px*ax
         py = py*ay
         pz = pz*az
 20      px = px*ax
         py = py*ay
         pz = pz*az
 30      px = px*ax
         py = py*ay
         pz = pz*az
 40      px = px*ax
         py = py*ay
         pz = pz*az
 50      px = px*ax
         py = py*ay
         pz = pz*az
 60      go to (130,120,110,100,90,80,70) , nj
 70      px = px*bx
         py = py*by
         pz = pz*bz
 80      px = px*bx
         py = py*by
         pz = pz*bz
 90      px = px*bx
         py = py*by
         pz = pz*bz
 100     px = px*bx
         py = py*by
         pz = pz*bz
 110     px = px*bx
         py = py*by
         pz = pz*bz
 120     px = px*bx
         py = py*by
         pz = pz*bz
 130     dum = w(i)
         pint = pint + dum*px
         qint = qint + dum*py
         rint = rint + dum*pz
 140  continue
      return
      end
_IF(mp2_parallel,masscf)
c
c gdf:  version for mp2,vb and scf gradients using GA & MA tools
c
      subroutine eijden(zscftp,wga,vga,ega,dd,v,e,ddd,n)
      implicit none
      REAL vga, wga, ega, dd, dum, v, e, ddd
      integer i,j,k,l,n,ntr,ij,kl,iblla,m991
      dimension vga(n,n),wga(n,n),ega(n),dd(*), v(n,n), e(*)
      dimension  ddd(*)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/restrl)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/mapper)
INCLUDE(common/scfwfn)
INCLUDE(common/dm)
      character*(*) zscftp
      character *8 zrhf,zuhf,zgrhf,zgvb,zvb
c
      REAL pt5
      integer m20, l3orb, iblk20, norb
      data m20/20/,pt5/0.5d0/,m991/991/
      data zrhf,zuhf,zgrhf,zgvb,zvb/'rhf','uhf','grhf','gvb','vb'/
c
c      call wrtsqm_ga('W(2) matrix',n,wga)
c      call wrtsqm_ga('eigenvectors ',n,vga)
c      call wrtvec_ga('eigenvalues ',n,ega)
c
      ntr = n*(n+1)/2
c
      if (mp2) then
        call sq2tr_ga(wga,dd,n)
        j = 1
        do i = 1 , n
        do k = 1 , na
            dum = -ega(k)*vga(i,k)
            if (dum.ne.0.0d0) then
              dum = dum + dum
              call daxpy(i,dum,vga(1,k),1,dd(j),1)
            end if
          end do
          j = j + i
        end do
c
      else if (zscftp .eq. zrhf) then
c
        call vclr(dd,1,ntr)
        call rdedx(v,n*n,ibl3qa,idaf)
        call tdown(v,ilifq,v,ilifq,n)
cpsh - probably should
c      replace with similar to serial code
c
c        l3orb = n*n
c        call secget(iseclg,m20,iblk20)
c        call rdedx(e,l3orb,iblk20,idaf)
c
        call rdedx(e,n,ibl3ea,idaf)
c
        j = 1
        do i = 1 , n
        do k = 1 , na
            dum = -e(k)*v(i,k)
            if (dum.ne.0.0d0) then
              dum = dum + dum
              call daxpy(i,dum,v(1,k),1,dd(j),1)
            end if
          end do
          j = j + i
        end do
c
      else if (zscftp .eq. zuhf) then

        call vclr(dd,1,ntr)
        call rdedx(v,n*n,ibl3qa,idaf)
        call tdown(v,ilifq,v,ilifq,n)
        call rdedx(e,n,ibl3ea,idaf)
        j = 1
        do  i = 1 , n
           do  k = 1 , na
              dum = -e(k)*v(i,k)
              if (dum.ne.0.0d0) then
                 call daxpy(i,dum,v(1,k),1,dd(j),1)
              end if
           end do
           j = j + i
        end do
c
        call rdedx(v,n*n,ibl3qb,idaf)
        call tdown(v,ilifq,v,ilifq,n)
        call rdedx(e,n,ibl3eb,idaf)
        j = 1
        do i = 1 , n
           do k = 1 , nb
              dum = -e(k)*v(i,k)
              if (dum.ne.0.0d0) then
                 call daxpy(i,dum,v(1,k),1,dd(j),1)
              end if
           end do
           j = j + i
        end do
c
      else if (zscftp.eq.zgrhf .or. zscftp.eq.zgvb) then
c
         norb = nco + npair + npair
         if (nseto.gt.0) then
            do i = 1 , nseto
               norb = norb + no(i)
            end do
         end if
         call rdedx(v,n*n,ibl3qa,idaf)
         call tdown(v,ilifq,v,ilifq,n)
         l3orb = norb*norb
         call secget(iseclg,m20,iblk20)
         call rdedx(e,l3orb,iblk20,idaf)
c
c     ----- zero out weighted density array -----
c
         call vclr(dd,1,ntr)
c
c     ----- calculate -tr(ce(ct)sa) -----
c
c     ----- note that e(kl) is used exactly twice. divide by
c           two to get the values appropriate for the generalized
c           lagrangian multipliers -----
c
         do i = 1 , n
c
c     ---calculate the half transform first -----
c
            kl = 0
            do l = 1 , norb
               ddd(l) = 0.0d0
               do k = 1 , norb
                  kl = kl + 1
                  ddd(l) = ddd(l) - v(i,k)*e(kl)
               end do
            end do
            call dscal(norb,pt5,ddd,1)
            do j = 1 , n
               ij = iky(max(i,j)) + min(i,j)
               do l = 1 , norb
                  dd(ij) = dd(ij) + ddd(l)*v(j,l)
               end do
            end do
         end do
      else if (zscftp.eq.zvb ) then
c
         call secget(isecla,m991,iblla)
         call rdedx(dd,ntr,iblla,idaf)
c
      else 
         call caserr('invalid parallel scftype in eijden')
      end if
c      call wrtvec_ga('W(MP2) triangle ',ntr,dd)
      return
      end
_ELSE
      subroutine eijden(zscftp,d,v,e,dd,l1,l3,ndim,nprint)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/scra7)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/dm)
INCLUDE(common/infoa)
INCLUDE(common/scfwfn)
INCLUDE(common/mapper)
INCLUDE(common/cigrad)
INCLUDE(common/zorac)
      common/restrl/ociopt,ocifor,omp2,ospac(12),omcscf
INCLUDE(common/cndx41)
      dimension v(ndim,*),d(*),e(*),dd(*)
      data m20/20/
      data pt5/0.5d0/
      data zrhf,zuhf,zgrhf,zgvb/'rhf','uhf','grhf','gvb'/
      data zcas,zmcscf,zvb/'casscf','mcscf','vb'/
      data m991/991/
c
      l2 = l1*(l1+1)/2
      l3 = l1*l1
c
      if (zscftp.eq.zgrhf .or. zscftp.eq.zgvb) then
c
         norb = nco + npair + npair
         if (nseto.gt.0) then
            do 20 i = 1 , nseto
               norb = norb + no(i)
 20         continue
         end if
         call rdedx(v,l3,ibl3qa,idaf)
         call tdown(v,ilifq,v,ilifq,l1)
         l3orb = norb*norb
         call secget(iseclg,m20,iblk20)
         call rdedx(e,l3orb,iblk20,idaf)
c
c     ----- zero out weighted density array -----
c
         call vclr(d,1,l2)
c
c     ----- calculate -tr(ce(ct)sa) -----
c
c     ----- note that e(kl) is used exactly twice. divide by
c           two to get the values appropriate for the generalized
c           lagrangian multipliers -----
c
         do 70 i = 1 , l1
c
c     ---calculate the half transform first -----
c
            kl = 0
            do 40 l = 1 , norb
               dd(l) = 0.0d0
               do 30 k = 1 , norb
                  kl = kl + 1
                  dd(l) = dd(l) - v(i,k)*e(kl)
 30            continue
 40         continue
            call dscal(norb,pt5,dd,1)
            do 60 j = 1 , l1
               ij = iky(max(i,j)) + min(i,j)
               do 50 l = 1 , norb
                  d(ij) = d(ij) + dd(l)*v(j,l)
 50            continue
 60         continue
 70      continue
c
      else if (zscftp.eq.zcas .or. zscftp.eq.zvb ) then
c
         call secget(isecla,m991,iblla)
         call rdedx(d,l2,iblla,idaf)
         if (nprint.ne.-5) write (iwr,6010) isecla
c
c
      else if (zscftp.eq.zmcscf .or. omcscf .or. mcgr) then
c
         call secloc(isecll,oexst,iblll)
         if (oexst) then
            call rdedx(d,l2,iblll,idaf)
            if (nprint.ne.-5) write (iwr,6020) isecll
         else
            call caserr('mcscf lagrangian not found')
         end if
c
      else if (zscftp.eq.zuhf .or. zscftp.eq.zrhf) then
c
         if (omp2 .or. mp3) then
            call secloc(isecll,oexst,iblll)
            if (oexst) then
               if (omp2 .and. nprint.ne.-5) write (iwr,6030) isecll
               if (mp3 .and. nprint.ne.-5) write (iwr,6040) isecll
               call rdedx(d,l2,iblll,idaf)
            else
               if (omp2) call caserr('mp2 lagrangian not found')
               if (mp3) call caserr('mp3 lagrangian not found')
            end if
c
         else
            call vclr(d,1,l2)
         end if
c
         if (zscftp.eq.zuhf) then
          if(oso.and.ozora) then
c.....hier de zora variant van de energy weighted density matrix
            call rdedx(d,l2,ibl7ew_z,num8)
           else
            call rdedx(v,l3,ibl3qa,idaf)
            call tdown(v,ilifq,v,ilifq,l1)
            call rdedx(e,l1,ibl3ea,idaf)
            j = 1
            do 90 i = 1 , l1
               do 80 k = 1 , na
                  dum = -e(k)*v(i,k)
                  if (dum.ne.0.0d0) then
                     call daxpy(i,dum,v(1,k),1,d(j),1)
                  end if
 80            continue
               j = j + i
 90         continue
c
            call rdedx(v,l3,ibl3qb,idaf)
            call tdown(v,ilifq,v,ilifq,l1)
            call rdedx(e,l1,ibl3eb,idaf)
            j = 1
            do 110 i = 1 , l1
               do 100 k = 1 , nb
                  dum = -e(k)*v(i,k)
                  if (dum.ne.0.0d0) then
                     call daxpy(i,dum,v(1,k),1,d(j),1)
                  end if
 100           continue
               j = j + i
 110        continue
          end if
         end if
c
         if (zscftp.eq.zrhf) then
c
            call rdedx(v,l3,ibl3qa,idaf)
            call tdown(v,ilifq,v,ilifq,l1)
            call rdedx(e,l1,ibl3ea,idaf)
            j = 1
            do 130 i = 1 , l1
               do 120 k = 1 , na
                  dum = -e(k)*v(i,k)
                  if (dum.ne.0.0d0) then
                     dum = dum + dum
                     call daxpy(i,dum,v(1,k),1,d(j),1)
                  end if
 120           continue
               j = j + i
 130        continue
         end if
c
      else
c
         call caserr('invalid scftype in eijden')
c
      end if
c
      return
 6010 format (//' casscf lagrangian restored from section ',i3)
 6020 format (//' mcscf lagrangian restored from section ',i3)
 6030 format (/' mp2 lagrangian restored from  section ',i3)
 6040 format (/' mp3 lagrangian restored from  section ',i3)
      end
_ENDIF
      subroutine fabzer(q)
c-------------------------------------------------------------
c     zeroes a derivative fock operator section
c--------------------------------------------------------------
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
      dimension q(*)
INCLUDE(common/specal)
      nat3 = nat*3
      nfok = ndenin*nat3
      call search(ibdout,iflout)
      do 20 n = 1 , nfok
         call vclr(q,1,nx)
         call wrt3s(q,nx,iflout)
 20   continue
      return
      end
      subroutine glimit
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
      common/junk/desg(3,maxat),pint(13),nint(2),cpint(3),
     *liminf(maxat),limsup(maxat)
c
      do 20 i = 1 , nat
         liminf(i) = 0
         limsup(i) = 0
 20   continue
      lat = katom(1)
      liminf(lat) = 1
      do 30 i = 1 , nshell
         iat = katom(i)
         if (lat.ne.iat) then
            limsup(lat) = kloc(i) - 1
            lat = iat
            liminf(lat) = kloc(i)
         end if
 30   continue
      limsup(iat) = num
      return
      end
_EXTRACT(hamd1,mips4)
      subroutine hamd1(q,prefa,mapshl,nshels,maxq)
c------------------------------------------------------------------
c    collects one electron derivatives together
c    1-electron contribution to derivative fock matrix
c------------------------------------------------------------------
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension q(maxq),prefa(*), mapshl(nshels,*)
c
INCLUDE(common/sizes)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/cslosc)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/ghfblk)
      common/junk/ioff(3*maxat)
INCLUDE(common/misc)
      common/blkin/gout(5109),nword
INCLUDE(common/scra7)
INCLUDE(common/mapper)
INCLUDE(common/prnprn)
      common/restrl/ oiopt(20),ofdtrn
c
INCLUDE(common/restri)
INCLUDE(common/cndx41)
c
INCLUDE(common/symtry)
      common /ecp2  / clp(400),zlp(400),nlp(400),kfirst(maxat,6),
     *                klast(maxat,6),lmax(maxat),lpskip(maxat),
     *                izcore(maxat)
c
      character *8 title,scftyp,runtyp,guess,conf,fkder
      character *8 scder,dpder,plder,guesc,rstop,charsp
      common/restrz/title(10),scftyp,runtyp,guess,conf,fkder,
     + scder,dpder,plder,guesc,rstop,charsp(30)
c
c  local storage
c
      logical iandj
      dimension iamina(7)
c
      data iamina/1,2,5,11,21,36,57/
c
      character *8 closed,grhf
      data closed/'closed'/
      data grhf/'grhf'/
      data dzero,done,two/0.0d0,1.0d0,2.0d0/
      data m5110,m5107/5110,5107/
c
      maxqqq = maxq
c
      if (odebug(17)) write (iwr,6010)
      nat3 = nat*3
      length = lensec(nx)
      ofdtrn = .false.
      iandj = .false.
      npass = 1
      maxnuc = 0
_IFN(secd_parallel)
      iposs = iochf(1)
      iposh = iposs + length*nat3
      iochf(11) = iposh
      iochf(12) = iposs
c
c     to allow for file protection problem....zero out
c     some blocks so they are defined in correct order
c
      call search(iposs,ifockf)
      do i = 1 , nat3
       call vclr(q,1,nx)
       call wrt3s(q,nx,ifockf)
      enddo
      call clredx
_ENDIF
c
      nadd = nat
      ntot = nx*nat3
 30   if (ntot.le.maxqqq) then
       do ipass = 1 , npass
        minnuc = maxnuc + 1
        maxnuc = maxnuc + nadd
        if (maxnuc.gt.nat) maxnuc = nat
        nuc = maxnuc - minnuc + 1
        k = (minnuc-1)*3 + 1
        ioff(k) = 0
        do i = 1 , nuc
         do j = 1 , 3
            ioff(k+1) = ioff(k) + nx
            k = k + 1
         enddo
        enddo
       enddo
       maxnuc = 0
c
c
       do 270 ipass = 1 , npass
         minnuc = maxnuc + 1
         maxnuc = maxnuc + nadd
         if (maxnuc.gt.nat) maxnuc = nat
           nuc = maxnuc - minnuc + 1
           nuc3 = nuc*3
           ij = 0
           do i = 1 , nuc3
              do n = 1 , nx
                 ij = ij + 1
                 q(ij) = dzero
              enddo
           enddo
c
c     ..... hellmann-feynman term .....
c
           nint = 1
           ipos1 = ibl7la
           call rdedx(gout,m5110,ipos1,num8)
           ipos1 = ipos1 + 10
           do ii = 1 , nshell
             mini = kmin(ii)
             maxi = kmax(ii)
             loci = kloc(ii) - mini
             ijshel = iky(ii)
             do jj = 1 , ii
              minj = kmin(jj)
              maxj = kmax(jj)
              locj = kloc(jj) - minj
c
c ... prefactor testing (see helfey)
c
              if ((dlntol+prefa(ijshel+jj)).gt.0) then
c
               oianj = ii.eq.jj
               mmax = maxj
               nn = 0
               do i = mini , maxi
                if (oianj) mmax = i
                do j = minj , mmax
                 nn = nn + 1
                 ij = iky(loci+i) + locj + j
                 do nu = 1 , nat
                  do np = 1 , 3
                   if (nu.ge.minnuc .and. nu.le.maxnuc) then
                    nnn = (nu-1)*3 + np
                    ioffn = ioff(nnn) + ij
                    q(ioffn) = q(ioffn) + gout(nint)
                   end if
                   nint = nint + 1
                   if (nint.ge.m5110) then
                    call rdedx(gout,m5110,ipos1,num8)
                    ipos1 = ipos1 + 10
                    nint = 1
                   end if
                  enddo
                 enddo
                enddo
               enddo
              end if
             enddo
           enddo
c
c           1-electron contributions
c
            call rdedx(gout,m5110,ipos1,num8)
            ipos1 = ipos1 + 10
            nint = 1
            do ii = 1 , nshell
             n = katom(ii)
             mini = kmin(ii)
             maxi = kmax(ii)
             loci = kloc(ii) - mini
             ioffn = ioff((n-1)*3+1)
             do jj = 1 , nshell
              minj = kmin(jj)
              maxj = kmax(jj)
c
c ... prefactor testing (see tvder)
c
              tolij = dlntol + prefa(min(ii,jj)+iky(max(ii,jj)))
              if (tolij.gt.0.0d0) then
c
               locj = kloc(jj) - minj
               oianj = ii.eq.jj
               do i = mini , maxi
                in = loci + i
                do j = minj , maxj
                 if (n.ge.minnuc .and. n.le.maxnuc) then
                  jn = locj + j
                  ij = min(in,jn) + iky(max(in,jn))
                  aa = done
                  if (oianj .and. i.eq.j) aa = two
                  ax = gout(nint)*aa
                  ay = gout(nint+1)*aa
                  az = gout(nint+2)*aa
                  ipos = ioffn + ij
                  q(ipos) = q(ipos) + ax
                  ipos = ipos + nx
                  q(ipos) = q(ipos) + ay
                  ipos = ipos + nx
                  q(ipos) = q(ipos) + az
                 end if
                 nint = nint + 3
                 if (nint.ge.m5110) then
                  call rdedx(gout,m5110,ipos1,num8)
                  ipos1 = ipos1 + 10
                  nint = 1
                 end if
                enddo
               enddo
              end if
             enddo
            enddo
c
           if (lpseud.eq.1) then
c
c           include ecp contributions
c
_IF(notused)
c           this code was originally used to hold the ecp
c           contributions to the derivative fock matrix in core
c           do ii = 1 , nshell
c             mini = kmin(ii)
c             maxi = kmax(ii)
c             loci = kloc(ii) - mini
c             ijshel = iky(ii)
c             do jj = 1 , ii
c              minj = kmin(jj)
c              maxj = kmax(jj)
c              locj = kloc(jj) - minj
c
c               oianj = ii.eq.jj
c               mmax = maxj
c               nn = 0
c               do i = mini , maxi
c                if (oianj) mmax = i
c                do j = minj , mmax
c                 nn = nn + 1
c                 ij = iky(loci+i) + locj + j
c                 do nu = 1 , nat
c                  do np = 1 , 3
c                  if (nu.ge.minnuc .and. nu.le.maxnuc) then
c                     nnn = (nu-1)*3 + np
c                     ioffn = ioff(nnn) + ij
c                     q(ioffn) = q(ioffn) + fdecp(ioffn)
c                  end if
c                  enddo
c                 enddo
c                enddo
c               enddo
c             enddo
c           enddo
c
c           do nu=1,nat
c           write(iwr,9068) nu
c9068  format(/1x,'contribution to fock derivative matrix, atom = ',i5)
c            do np = 1 , 3
c            nnn = (nu-1)*3 + np
c            ioffn = ioff(nnn) + 1
c            call prtri(q(ioffn),num)
c            enddo
c           enddo
_ENDIF
c
c        note loops run over full square array of ecp matrix for derivatives.
c
           call rdedx(gout,m5107,ipos1,num8)
           ipos1 = ipos1 + 10
           nint = 1
           do ii=1,nshell
c
            i1 = kstart(ii)
            i2 = i1+kng(ii)-1
            ipmin = i1
            ipmax = i2
            icntr = katom(ii)
            imin = kmin(ii)
            imax = kmax(ii)
            loci = kloc(ii)-imin
            iimax = 1
            if (imin.eq.1.and.imax.eq.4) iimax = 2
            do iii=1,iimax
             if (imin.eq.1.and.imax.eq.4) then
              if (iii.eq.1) then
               iamin = 1
               iamax = 1
              else
               iamin = 2
               iamax = 4
              end if
             else
              iamin = imin
              iamax = imax
             end if
             do jj=ipmin,ipmax
              if (iamin.eq.1) then
                itemp = 1
              else if (iamin.lt.5) then
                itemp = 2
              else if (iamin.lt.11) then
                itemp = 3
              else if (iamin.le.20) then
                itemp = 4
              else if (iamin.le.35) then
                itemp = 5
              end if
             enddo
c
c        -----  jshell  -----
c
             do 8000 jj=1,nshell
c       check symmetry
              ii0 = max(ii,jj)
              jj0 = min(ii,jj)
              do 80 it=1,nt
               id=mapshl(ii,it)
               jd=mapshl(jj,it)
               idd = max(id,jd)
               jdd = min(id,jd)
               if(idd.gt.ii0) go to 8000
               if(idd.lt.ii0) go to 80
               if(jdd.gt.jj0) go to 8000
               if(jdd.lt.jj0) go to 80
 80           continue
c
              jcntr = katom(jj)
              jmin = kmin(jj)
              jmax = kmax(jj)
              locj = kloc(jj)-jmin
              jjmax = 1
              if (jmin.eq.1.and.jmax.eq.4) jjmax = 2
              do 7900 jjj=1,jjmax
               if (jmin.eq.1.and.jmax.eq.4) then
                 if (jjj.eq.1) then
                   jamin = 1
                   jamax = 1
                 else
                   if (iandj.and.iamin.eq.1) go to 7900
                   jamin = 2
                   jamax = 4
                 end if
               else
                 jamin = jmin
                 jamax = jmax
               end if
c now loop over each center with an ecp potential
               do ikcntr=1,nat
                if (icntr.ne.ikcntr) then
                 kcntr = ikcntr
                 if(lpskip(kcntr).ne.1) then
                  iamin = iamina(itemp)
                  iamax = iamina(itemp+1)-1
c
                  n = 0
                  do j=jamin,jamax
                   jn = locj+j
                   do i=iamin,iamax
                    n = n+1
                    in = loci+i
                    nn = iky(in)+jn
                    if(jn.gt.in) nn = iky(jn)+in
c  restore the 1st derivative elements of the second derivative. 
c                   dum = 1.0d+00
c                   if (in.eq.jn) dum = 2.0d+00
c                   nnfd = nn+(3*(icntr-1)*l2)
c                   fd(nnfd) = fd(nnfd) - dum * xin(n)
c                   fd(nnfd+l2) = fd(nnfd+l2) - dum * yin(n)
c                   fd(nnfd+2*l2) = fd(nnfd+2*l2) - dum * zin(n)
                    if (icntr.ge.minnuc .and. icntr.le.maxnuc) then
                     nnn = (icntr-1)*3 + 1
                     ioffn = ioff(nnn) 
                     ipos = ioffn + nn
                     q(ipos) = q(ipos) + gout(nint  )
                     ipos = ipos + nx
                     q(ipos) = q(ipos) + gout(nint+1)
                      ipos = ipos + nx
                      q(ipos) = q(ipos) + gout(nint+2)
                    endif
                    if (ikcntr.ge.minnuc .and. ikcntr.le.maxnuc) then
c                    nnfd = nn+(3*(ikcntr-1)*l2)
c                    fd(nnfd) = fd(nnfd) + dum * xin(n)
c                    fd(nnfd+l2) = fd(nnfd+l2) + dum * yin(n)
c                    fd(nnfd+2*l2) = fd(nnfd+2*l2) + dum * zin(n)
                     nnn = (ikcntr-1)*3 + 1
                     ioffn = ioff(nnn) 
                     ipos = ioffn + nn
                     q(ipos) = q(ipos) + gout(nint+3)
                     ipos = ipos + nx
                     q(ipos) = q(ipos) + gout(nint+4)
                     ipos = ipos + nx
                     q(ipos) = q(ipos) + gout(nint+5)
                    endif
                    nint = nint + 6
                    if (nint.ge.m5107) then
                     call rdedx(gout,m5107,ipos1,num8)
                     ipos1 = ipos1 + 10
                     nint = 1
                    end if
c
                   enddo
                  enddo
                 endif
                endif
               enddo
 7900         continue
 8000        continue
             enddo
            enddo
c
            endif
c
            if (odebug(17)) write (iwr,6020)
            do i = 1 , nuc3
              ioffn = ioff(i) + 1
              if (odebug(17)) call prtris(q(ioffn),num,iwr)
_IF(secd_parallel)
csecd
              call stash( q(ioffn), nx, 'dh', i + minnuc - 1)
_ELSE
              call wrt3(q(ioffn),nx,iposh,ifockf)
              iposh = iposh + length
_ENDIF
            enddo
c
c           derivative overlap matrix
c
            call rdedx(gout,m5110,ipos1,num8)
            ipos1 = ipos1 + 10
            ij = 0
            do i = 1 , nuc3
             do n = 1 , nx
              ij = ij + 1
              q(ij) = dzero
             enddo
            enddo
            nint = 1
            do ii = 1 , nshell
             nati = katom(ii)
             mini = kmin(ii)
             maxi = kmax(ii)
             loci = kloc(ii) - mini
             ioffni = ioff((nati-1)*3+1)
             do jj = 1 , ii
              natj = katom(jj)
              if (nati.ne.natj) then
               ioffnj = ioff((natj-1)*3+1)
               minj = kmin(jj)
               maxj = kmax(jj)
               locj = kloc(jj) - minj
               do i = mini , maxi
                in = loci + i
                do j = minj , maxj
                 jn = locj + j
                 if (jn.le.in) then
                  ij = iky(in) + jn
                  sx = gout(nint)
                  sy = gout(nint+1)
                  sz = gout(nint+2)
                  if (nati.ge.minnuc .and. nati.le.maxnuc) then
                     q(ioffni+ij) = q(ioffni+ij) + sx
                  end if
                  if (natj.ge.minnuc .and. natj.le.maxnuc) then
                     q(ioffnj+ij) = q(ioffnj+ij) - sx
                  end if
                  ij = ij + nx
                  if (nati.ge.minnuc .and. nati.le.maxnuc) then
                     q(ioffni+ij) = q(ioffni+ij) + sy
                  end if
                  if (natj.ge.minnuc .and. natj.le.maxnuc) then
                     q(ioffnj+ij) = q(ioffnj+ij) - sy
                  end if
                  ij = ij + nx
                  if (nati.ge.minnuc .and. nati.le.maxnuc) then
                     q(ioffni+ij) = q(ioffni+ij) + sz
                  end if
                  if (natj.ge.minnuc .and. natj.le.maxnuc) then
                     q(ioffnj+ij) = q(ioffnj+ij) - sz
                  end if
                  nint = nint + 3
                  if (nint.ge.m5110) then
                     call rdedx(gout,m5110,ipos1,num8)
                     ipos1 = ipos1 + 10
                     nint = 1
                  end if
                 end if
                enddo
               enddo
              end if
             enddo
            enddo
            if (odebug(17)) write (iwr,6030)
            do i = 1 , nuc3
             ioffn = ioff(i) + 1
             if (odebug(17)) call prtris(q(ioffn),num,iwr)
_IF(secd_parallel)
csecd
             call stash( q(ioffn), nx, 'ds', i + minnuc - 1)
_ELSE
             call wrt3(q(ioffn),nx,iposs,ifockf)
             iposs = iposs + length
_ENDIF
            enddo
 270     continue
c
c
c
_IFN(secd_parallel)
         iochf(1) = iposh
_ENDIF
         call clredx
         if (scftyp.eq.closed) return
         nfok = nat3
         if (scftyp.eq.grhf) nfok = njk*nat3*2
         do 290 n = 1 , nfok
            do 280 i = 1 , nx
               q(i) = 0.0d0
 280        continue
_IFN(secd_parallel)
            call wrt3(q,nx,iposh,ifockf)
            iposh = iposh + length
 290     continue
         iochf(1) = iposh
_ELSE
 290     continue
_ENDIF
         return
      else
         npass = npass + 1
         nadd = nat/npass + 1
         ntot = nadd*nx*3
         go to 30
      end if
 6010 format (///1x,'output from hamd1'//)
 6020 format (//1x,'derivative 1-electron hamiltonian')
 6030 format (//1x,'derivative overlap matrices')
      end
_ENDEXTRACT
_EXTRACT(helfey,helfey)
      subroutine helfey(zscftp,q,prefa,iso,helfy,natg,nshels)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/cslosc)
INCLUDE(common/timez)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/mapper)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
      common/junk/de(3,maxat),
     + pint,qint,rint,t,p0,q0,r0,pi,qi,ri,pj,qj,rj,ni,nj,
     + cx,cy,cz,
     + dfac(225),dij(225),
     + pin(5,5,5),qin(5,5,5),rin(5,5,5),
     + dpin(5,5,5),dqin(5,5,5),drin(5,5,5) 
INCLUDE(common/root)
INCLUDE(common/segm)
      common/blkin/gout(5109),nword
INCLUDE(common/misc)
_IF(mp2_parallel,masscf)
c***   **MPP**
INCLUDE(common/mp2grad_pointers)
c***   **MPP**
_ENDIF
INCLUDE(common/symtry)
INCLUDE(common/timeperiods)
      dimension q(*),helfy(225,natg,3),prefa(*)
      dimension iso(nshels,*)
      dimension ydnam(3)
      dimension m0(48)
      dimension ijx(35),ijy(35),ijz(35),ijn(225)
      data ydnam /'e/x','e/y','e/z'/
      data pi212 /1.1283791670955d0/
      data sqrt3 /1.73205080756888d0/
      data sqrt5 /2.23606797749979d0/
      data sqrt7 /2.64575131106459d0/     
      data m5110/5110/
      data ijx    / 1, 2, 1, 1, 3, 1, 1, 2, 2, 1,
     1              4, 1, 1, 3, 3, 2, 1, 2, 1, 2,
     2              5, 1, 1, 4, 4, 2, 1, 2, 1, 3,
     3              3, 1, 3, 2, 2/             
      data ijy    / 1, 1, 2, 1, 1, 3, 1, 2, 1, 2,
     1              1, 4, 1, 2, 1, 3, 3, 1, 2, 2,
     2              1, 5, 1, 2, 1, 4, 4, 1, 2, 3,
     3              1, 3, 2, 3, 2/
      data ijz    / 1, 1, 1, 2, 1, 1, 3, 1, 2, 2,
     1              1, 1, 4, 1, 2, 1, 2, 3, 3, 2,
     2              1, 1, 5, 1, 2, 1, 2, 4, 4, 1,
     3              3, 3, 2, 2, 3/
      data dzero,done,two /0.0d0,1.0d0,2.0d0/
      data rln10 /2.30258d0/
c     data zuhf,zgrhf,zgvb/'uhf','grhf','gvb'/
c

      call start_time_period(TP_HELFEY)

      out = nprint.eq. - 3
      outall = nprint.eq. - 10
_IF(parallel)
c***   **MPP**
      iflop = iipsci()
c***   **MPP**
_ENDIF
      if (outall) then
         write (iwr,6010)
         write (iwr,6060)
      end if
c     omp2ir = omp2 .and. opdipd
      l2 = (num*(num+1))/2
      l3 = num*num
c
c     ----- set pointers for partitioning of core -----
c
      i10 = igmem_alloc(l2)
      i20 = igmem_alloc(l3)
c... i20 is used for density matrix and abused for vectors (jvl 97)
c
_IF(mp2_parallel,masscf)
c  version for mp2 and scf gradients using GA & MA tools
      l1 = num
      call dendd1(   zscftp, q(i10),q(i20),
     &               q(mp2grad_dens),
     &               q(mp2grad_pmat),l1)
_ELSE
      call dendd1(zscftp,q(i10),q(i20),l2)
_ENDIF
c
      tol = rln10*itol
      do 30 i = 1 , 3
         do 20 n = 1 , nat
            de(i,n) = dzero
 20      continue
 30   continue
      onorm = normf.ne.1 .or. normp.ne.1
      nword = 1
      if (oham) then
c       call search(ipos1,num8)
c     reset symmetry to c1
        ntsave = nt
        nt = 1
      endif
c
c     ----- ishell
c
      do 430 ii = 1 , nshell
c
c     ----- eliminate ishell -----
c
         do 435 it = 1 , nt
           id = iso(ii,it)
           if (id.gt.ii) go to 430
           m0(it) = id
435      continue
c
         ijshel = iky(ii)
         i = katom(ii)
         pi = c(1,i)
         qi = c(2,i)
         ri = c(3,i)
         i1 = kstart(ii)
         i2 = i1 + kng(ii) - 1
         lit = ktype(ii)
         mini = kmin(ii)
         maxi = kmax(ii)
         loci = kloc(ii) - mini
c
c     ----- jshell
c
         do 420 jj = 1 , ii
            if (dlntol+prefa(ijshel+jj).gt.0) then
_IF(secd_parallel)
csecd
c not parallel in || secd version
c
_ELSEIF(parallel)
c***   **MPP**
            if (oipsci()) go to 420
c***   **MPP**
_ENDIF
               j = katom(jj)
               n2 = 0
               do 425 it = 1 , nt
               jd = iso(jj,it)
               if (jd.gt.ii) go to 420
               id = m0(it)
               if (id.lt.jd) then
                  nd = id
                  id = jd
                  jd = nd
               end if
               if (id.eq.ii .and. jd.gt.jj) go to 420
               if (id.eq.ii.and.jd.eq.jj) then
                   n2 = n2 + 1
               end if
425            continue
               q2 = dble(nt)/dble(n2)
c
               pj = c(1,j)
               qj = c(2,j)
               rj = c(3,j)
               j1 = kstart(jj)
               j2 = j1 + kng(jj) - 1
               ljt = ktype(jj)
               minj = kmin(jj)
               maxj = kmax(jj)
               locj = kloc(jj) - minj
               nroots = (lit+ljt+1-2)/2 + 1
               rr = (pi-pj)**2 + (qi-qj)**2 + (ri-rj)**2
               oianj = ii.eq.jj
c
c     ----- prepare indices for pairs of (i,j) functions
c
               ij = 0
               mmax = maxj
               do 50 i = mini , maxi
                  if (oianj) mmax = i
                  do 40 j = minj , mmax
                     ij = ij + 1
                     ijn(ij) = iky(loci+i) + locj + j
                     dfac(ij) = two
                     if (oianj .and. i.eq.j) dfac(ij) = done
 40               continue
 50            continue
               do 80 i = 1 , ij
                  do 70 j = 1 , nat
                     do 60 k = 1 , 3
                        helfy(i,j,k) = dzero
 60                  continue
 70               continue
 80            continue
c
c     ----- i primitive
c
               jgmax = j2
               do 350 ig = i1 , i2
                  ai = ex(ig)
                  arri = ai*rr
                  axi = ai*pi
                  ayi = ai*qi
                  azi = ai*ri
                  csi = cs(ig)
                  cpi = cp(ig)
                  cdi = cd(ig)
                  cfi = cf(ig)
                  cgi = cg(ig)
c
c     ----- j primitive
c
                  if (oianj) jgmax = ig
                  do 340 jg = j1 , jgmax
                     aj = ex(jg)
                     aa = ai + aj
                     aa1 = done/aa
                     dum = aj*arri*aa1
                     if (dum.le.tol) then
                        fac = dexp(-dum)
                        csj = cs(jg)
                        cpj = cp(jg)
                        cdj = cd(jg)
                        cfj = cf(jg)
                        cgj = cg(jg)
                        ax = (axi+aj*pj)*aa1
                        ay = (ayi+aj*qj)*aa1
                        az = (azi+aj*rj)*aa1
c
c     ----- density factor
c
                        odoubl = oianj .and. ig.ne.jg
                        jmax = maxj
                        nn = 0
                        do 260 i = mini , maxi
                           go to (90,100,160,160,
     +                     110,160,160,120,160,160,
     +                     130,160,160,140,160,160,160,160,160,150,
     +                     152,160,160,154,160,160,160,160,160,156,
     +                     160,160,158,160,160), i
 90                        dum1 = csi*fac
                           go to 160
 100                       dum1 = cpi*fac
                           go to 160
 110                       dum1 = cdi*fac
                           go to 160
 120                       if (onorm) dum1 = dum1*sqrt3
                           go to 160
 130                       dum1 = cfi*fac
                           go to 160
 140                       if (onorm) dum1 = dum1*sqrt5
                           go to 160
 150                       if (onorm) dum1 = dum1*sqrt3
                           go to 160
 152                       dum1 = cgi*fac
                           go to 160
 154                       if (onorm) dum1 = dum1*sqrt7
                           go to 160
 156                       if (onorm) dum1 = dum1*sqrt5/sqrt3
                           go to 160
 158                       if (onorm) dum1 = dum1*sqrt3
 160                       if (oianj) jmax = i
                           do 250 j = minj , jmax
                              go to (170,180,240,240,
     +                        190,240,240,200,240,240,
     +                        210,240,240,220,240,240,240,240,240,230,
     +                        232,240,240,234,240,240,240,240,240,236,
     +                        240,240,238,240,240),j
 170                          dum2 = dum1*csj
                              if (odoubl) then
                                 if (i.gt.1) then
                                    dum2 = dum2 + csi*cpj*fac
                                 else
                                    dum2 = dum2 + dum2
                                 end if
                              end if
                              go to 240
 180                          dum2 = dum1*cpj
                              if (odoubl) dum2 = dum2 + dum2
                              go to 240
 190                          dum2 = dum1*cdj
                              if (odoubl) dum2 = dum2 + dum2
                              go to 240
 200                          if (onorm) dum2 = dum2*sqrt3
                              go to 240
 210                          dum2 = dum1*cfj
                              if (odoubl) dum2 = dum2 + dum2
                              go to 240
 220                          if (onorm) dum2 = dum2*sqrt5
                              go to 240
 230                          if (onorm) dum2 = dum2*sqrt3
                              go to 240
 232                          dum2 = dum1*cgj
                              if (odoubl) dum2 = dum2+dum2
                              go to 240
 234                          if (onorm) dum2 = dum2*sqrt7
                              go to 240
 236                          if (onorm) dum2 = dum2*sqrt5/sqrt3
                              go to 240
 238                          if (onorm) dum2 = dum2*sqrt3
 240                          nn = nn + 1
                              dij(nn) = dum2
 250                       continue
 260                    continue
c
c     ..... hellmann-feynman term .....
c
                        dum = pi212*aa1
                        dum = dum + dum
                        do 270 i = 1 , ij
                           dij(i) = dij(i)*dum
 270                    continue
                        aax = aa*ax
                        aay = aa*ay
                        aaz = aa*az
                        do 330 ic = 1 , nat
                           cznuc = -czan(ic)
                           cx = c(1,ic)
                           cy = c(2,ic)
                           cz = c(3,ic)
                           pp = aa*((ax-cx)**2+(ay-cy)**2+(az-cz)**2)
                           if (nroots.le.3) call rt123
                           if (nroots.eq.4) call roots4
                           if (nroots.eq.5) call roots5
                           do 300 k = 1 , nroots
                              uu = aa*u(k)
                              ww = w(k)*cznuc
                              ww = ww*uu
                              tt = done/(aa+uu)
                              t = dsqrt(tt)
                              p0 = (aax+uu*cx)*tt
                              q0 = (aay+uu*cy)*tt
                              r0 = (aaz+uu*cz)*tt
                              do 290 j = 1 , ljt
                                 nj = j
                                 do 280 i = 1 , lit
                                    ni = i
                                    call vint
                                    pin(i,j,k) = pint
                                    qin(i,j,k) = qint
                                    rin(i,j,k) = rint*ww
                                    call dvint
                                    dpin(i,j,k) = pint
                                    dqin(i,j,k) = qint
                                    drin(i,j,k) = rint*ww
 280                             continue
 290                          continue
 300                       continue
c
                           ij = 0
                           do 320 i = mini,maxi
                           ix = ijx(i)
                           iy = ijy(i)
                           iz = ijz(i)
                           jmax = maxj
                           if(oianj) jmax = i
                            do 325 j = minj,jmax
                             jx = ijx(j)
                             jy = ijy(j)
                             jz = ijz(j)
                             dumx = dzero
                             dumy = dzero
                             dumz = dzero
                             do 310 k = 1,nroots
                             dumx = dumx+dpin(ix,jx,k)* qin(iy,jy,k)*
     +                        rin(iz,jz,k)
                             dumy = dumy+ pin(ix,jx,k)*dqin(iy,jy,k)*
     +                        rin(iz,jz,k)
                             dumz = dumz+ pin(ix,jx,k)* qin(iy,jy,k)*
     +                       drin(iz,jz,k)
  310                        continue
                             ij = ij + 1
                             dum = dij(ij)
                             dumx = dumx*dum
                             dumy = dumy*dum
                             dumz = dumz*dum
                             helfy(ij,ic,1) = helfy(ij,ic,1) + dumx
                             helfy(ij,ic,2) = helfy(ij,ic,2) + dumy
                             helfy(ij,ic,3) = helfy(ij,ic,3) + dumz
 325                        continue
 320                       continue
 330                    continue
                     end if
 340              continue
 350           continue
c
c     ----- end of *primitive* loops -----
c
                  iij = 0
                  do 380 i = mini , maxi
                     mmax = maxj
                     if (oianj) mmax = i
                     ipp = loci + i
                     do 370 j = minj , mmax
                        iij = iij + 1
                        jp = locj + j
                        do 360 k = 1 , nat
                         helfy(iij,k,1) = helfy(iij,k,1) *q2
                         helfy(iij,k,2) = helfy(iij,k,2) *q2
                         helfy(iij,k,3) = helfy(iij,k,3) *q2
                         dum = q(ijn(iij)+i10-1)*dfac(iij)
                         de(1,k) = de(1,k) + dum*helfy(iij,k,1)
                         de(2,k) = de(2,k) + dum*helfy(iij,k,2)
                         de(3,k) = de(3,k) + dum*helfy(iij,k,3)
                           if (outall) write (iwr,6050) ipp , jp , 
     +                     k ,(helfy(iij,k,l),l=1,3) ,
     +                            q(ijn(iij)+i10-1)
 360                    continue
 370                 continue
 380              continue
               if (oham) then
                  do 410 i = 1 , ij
                     do 400 j = 1 , nat
                        do 390 k = 1 , 3
                           gout(nword) = helfy(i,j,k)
                           nword = nword + 1
 390                    continue
                        if (nword.eq.m5110) then
                           nword = nword - 1
                           call wrt3(gout,m5110,ipos1,num8)
                           nword = 1
                           ipos1 = ipos1 + 10
                        end if
 400                 continue
 410              continue
               end if
            end if
 420     continue
 430  continue
c
c     ----- end of *shell* loops -----
c
      if (oham) then
         nword = nword - 1
         call wrt3(gout,m5110,ipos1,num8)
         ipos1 = ipos1 + 10
c     ----- reset symmetry
         nt = ntsave
      end if
      if (out) then
         mmax = 0
 440     mmin = mmax + 1
         mmax = mmax + 8
         if (mmax.gt.nat) mmax = nat
         write (iwr,6020)
         write (iwr,6030) (i,i=mmin,mmax)
         write (iwr,6020)
         do 450 n = 1 , 3
            write (iwr,6040) ydnam(n),(de(n,i),i=mmin,mmax)
 450     continue
         if (mmax.lt.nat) go to 440
         write (iwr,6070)
      end if
c
c     ----- reset core memory -----
c
      call gmem_free(i20)
      call gmem_free(i10)
c
      call end_time_period(TP_HELFEY)

      return
 6010 format (/10x,26('-')/10x,'hellmann-feynman integrals'/10x,26('-'))
 6020 format (/)
 6030 format (5x,'atom',8(6x,i3,6x))
 6040 format (7x,a3,8e15.7)
 6050 format (1x,3i5,5x,4f20.8)
 6060 format (//5x,'i',4x,'j',4x,'k',15x,'ex',18x,'ey',18x,'ez',18x,
     +        'dij')
 6070 format (/' ...... end of hellmann-feynman force ......'/)
      end
_ENDEXTRACT
      subroutine hfgrad(zscf,core)
c
c     ----- calculate gradient of the hf energy with respect
c           to the nuclear coordinates.
c          conventional rhf,uhf,gvb,mp2,mp3 or casscf wavefunction
c           direct rhf, uhf and gvb
c
c     1. compute hellmann-feynman force +
c                other 1e-contribution to the gradient.
c     2. compute 2e-contribution.
c
c     irest = 5     1e-gradient restart ( mo*s saved;no gradient saved)
c     irest = 6     2e-gradient restart ( mo*s saved;   gradient saved)
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/cslosc)
INCLUDE(common/scfwfn)
INCLUDE(common/infoa)
INCLUDE(common/ijlab)
INCLUDE(common/mapper)
INCLUDE(common/nshel)
INCLUDE(common/iofile)
INCLUDE(common/symtry)
INCLUDE(common/statis)
INCLUDE(common/restar)
INCLUDE(common/restri)
      common/restrl/ociopt,ocifor,omp2
INCLUDE(common/cndx41)
INCLUDE(common/timez)
INCLUDE(common/prints)
INCLUDE(common/runlab)
INCLUDE(common/chgcc)
INCLUDE(common/timeperiods)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
c
c need to move gradient into here explicitly if we don't
c call dfinal
c
INCLUDE(common/funct)
INCLUDE(common/grad2)
_ENDIF
      character*10 charwall
      character*5 fnm
      character*6 snm
      data fnm,snm/'drv1e','hfgrad'/
_IF(rpagrad)
      data zrpad/'rpagrad'/
      data zrpaopt/'rpaoptim'/
_ENDIF
      dimension core(*)
      data zuhf,zgvb/'uhf','gvb'/
      data zgrhf,zcas,zmcscf,zsec,zdip,zpol,zram,zmagn,zir,zvb/
     *     'grhf','casscf','mcscf','hessian','dipder','polder',
     *     'raman','magnetiz','infrared','vb'/
c
      call cpuwal(begin,ebegin)
      if (nprint.ne.-5) write (iwr,6010) begin ,charwall()
      if (odscf .and. odnew) then
         call drcdrv(core(1),'gradients')
         return
      end if

      call start_time_period(TP_HFGRAD)

c     nav = lenwrd()

_IF(mp2_parallel,masscf)
      if (omp2) then
        i10 = igmem_alloc_reserved(1, nw196(5))
      else 
        i10 = igmem_alloc(nw196(5))
      end if
_ELSE
      i10 = igmem_alloc(nw196(5))
_ENDIF
      iprefa = igmem_alloc_inf(ikyp(nshell),fnm,snm,'prefac',
     +                         IGMEM_DEBUG)
_IF(parallel)
      call pg_dlbreset
_ENDIF

      call rdedx(core(i10),nw196(5),ibl196(5),idaf)
      if (odscf) then
         dlntol = tolitr(3)
         m171 = 171
         call secget(isect(471),m171,ibl171)
         call rdedx(core(iprefa),ikyp(nshell),ibl171,idaf)
         if (nprint.ne.-5 .and. oprint(57)) then
            write (iwr,6020) ibl171
            call writel(core(iprefa),nshell)
         end if
      else
         dlntol = -dlog(10.0d0**(-icut))
         dumt   =  dexp(-dlntol)
         if (nprint.ne.-5) write (iwr,6040) dumt
         call rdmake(core(iprefa))
         if (nprint.ne.-5 .and. oprint(57)) then
            write (iwr,6030)
            call writel(core(iprefa),nshell)
         end if
      end if
      if (irest.le.5) then
         call stvder(zscftp,core,core(iprefa),core(i10),nshell)
_IF(flucq)
c Calculate the FLUCQ QM-MM interaction (if any)
         call fqqmmm(core,core(i10),nshell)
_ENDIF
         call timana(6)
         nindmx = 0
      end if

      if (tim.ge.timlim) go to 40

_IF(ccpdft)
c
c     ccpdft
c
      idum = CD_set_2e()
      if(CD_active() .and. .not. CD_HF_coulomb_deriv())then

         if(opg_root().and.nprint.ne.-5) write(iwr,6050)
            
c
c        we won't be going through 2e ints driver, so flag
c        complete gradient
c
         irest = 0
c
c        ditto read and copy to /funct/
c
         ncoord = 3*nat
         call rdgrd(de,idum1,idum2,idum3,idum4,idum5)
         if (nt.ne.1) then
            isymd = igmem_alloc(nw196(6))
            call symde(core(isymd),nat)
            call gmem_free(isymd)
         endif
         call dcopy(ncoord,de,1,egrad,1)
c
c        punch out the gradients
c
         call blkgra(nat,egrad)
c
c        !!!! may need other functions here
c
      endif

_ENDIF
      call cpuwal(begin,ebegin)
c
c BQ-force option skips two-electron terms
c
      if(.not.obqf)then

      call spchck

      if (intg76.le.0) then

_IF(ccpdft)
c
c ccpdft
c
        if(.not. CD_active()  .or. CD_HF_coulomb_deriv() 
     &     .or. CD_HF_exchange() ) then
c
c        compute 2-electron contribution to gradient
c
         if(opg_root())
     &        write(iwr,*) 'Forming 4c2e gradient contributions',intg76

_ENDIF
         nindmx = 1
         onocnt = .true.
_IF(mp2_parallel,masscf)
         if (omp2) then
           call caserr('schwartz mod needed here in drv1e')
           call jkder_ga(zscf,core,nshell)
         else 
           call jkder(zscf,core,core(iprefa),core(i10),nshell)
         end if
_ELSE
         call jkder(zscf,core,core(iprefa),core(i10),nshell)
_ENDIF

_IF(ccpdft)
         end if
_ENDIF

      else if (zscf.eq.zgrhf .or. zscf.eq.zcas .or.
     +         zscf.eq.zmcscf .or. omp2 .or. mp3 .or.
     +         zruntp.eq.zsec .or. zruntp.eq.zdip .or. 
_IF(rpagrad)
     +         zruntp.eq.zrpad .or. zruntp.eq.zrpaopt .or.
_ENDIF
     +         zruntp.eq.zpol .or. zruntp.eq.zram .or.
     +         zruntp.eq.zmagn .or. zruntp.eq.zir .or. 
     +         zscf.eq.zvb) then
         istd = 1
         do 20 i = 1 , nshell
            kad(i) = -1
 20      continue
         nindmx = 1
         onocnt = .true.
_IF(ccpdft)
         if(CD_active()) then
            if (zruntp.eq.zpol .or. zruntp.eq.zsec .or. 
     +          zruntp.eq.zir) then
            else
               call caserr('DFT not available for run type')
            endif
         endif
_ENDIF

_IF(mp2_parallel,masscf)
         if (omp2) then
           call caserr('schwartz mod needed here in drv1e')
           call jkder_ga(zscf,core,nshell)
         else 
           call jkder(zscf,core,core(iprefa),core(i10),nshell)
         end if
_ELSE
         call jkder(zscf,core,core(iprefa),core(i10),nshell)
_ENDIF
      else

_IF(ccpdft)
c
c       ccpdft
c
        if(.not. CD_active()  .or. CD_HF_coulomb_deriv() 
     &      .or. CD_HF_exchange() ) then
c
c          compute 2-electron contribution to gradient
c
           if(opg_root().and.nprint.ne.-5)
     &          write(iwr,*) 'Forming 2e gradient contributions',intg76
_ENDIF
           if (nindmx.eq.0) then
              call jkdr80(zscf,core,core(iprefa),core(i10),nshell)
              if (tim.ge.timlim) go to 30
              if (ospbas) go to 30
           end if
           nindmx = 1
           onocnt = .true.
           call jkder(zscf,core,core(iprefa),core(i10),nshell)
_IF(ccpdft)
         end if
_ENDIF
      end if

_IF(ccpdft)
      idum = CD_reset_2e()
_ENDIF

      else
c
c obqf case, copy 1e gradient to total
c
        irest = 0
        ncoord = 3*nat
        call rdgrd(de,idum1,idum2,idum3,idum4,idum5)
        call dcopy(ncoord,de,1,egrad,1)
c
c --- punch out the gradients
c
        call blkgra(nat,egrad)

      end if

 30   call timana(7)

 40   call gmem_free_inf(iprefa,fnm,snm,'prefac')

_IF(mp2_parallel,masscf)
      if (omp2) then
        call gmem_free_reserved(1,i10)
      else 
        call gmem_free(i10)
      end if
_ELSE
      call gmem_free(i10)
_ENDIF
      call end_time_period(TP_HFGRAD)

      return
 6010 format (/' commence gradient evaluation at ',f9.2,' seconds'
     1        ,a10,' wall')
 6020 format (/10x,'direct-scf prefactor matrix from block ',i5)
 6030 format (/10x,'direct-scf prefactor matrix')
 6040 format (/1x,'gradient prefactor threshold ',e12.6)
 6050 format (/1x,'Forming coulomb gradients with Dunlap fit')
      end
      subroutine oneld(x,y,z,xd,yd,zd,a,ni,nj,itype,ndim)
      implicit REAL  (a-h,o-z)
      dimension x(ndim,ndim),y(ndim,ndim),z(ndim,ndim),
     & xd(ndim,ndim),yd(ndim,ndim),zd(ndim,ndim)
      two = -2.0d0
      three = -3.0d0
      four = -4.0d0
      five = -5.0d0
      a2 = a + a
      go to (20,100) , itype
 20   do 90 j = 1 , nj
         do 80 i = 1 , ni
            go to (30,40,50,60,70,75) , i
 30         xd(j,1) = a2*x(j,2)
            yd(j,1) = a2*y(j,2)
            zd(j,1) = a2*z(j,2)
            go to 80
 40         xd(j,2) = a2*x(j,3) - x(j,1)
            yd(j,2) = a2*y(j,3) - y(j,1)
            zd(j,2) = a2*z(j,3) - z(j,1)
            go to 80
 50         xd(j,3) = a2*x(j,4) + two*x(j,2)
            yd(j,3) = a2*y(j,4) + two*y(j,2)
            zd(j,3) = a2*z(j,4) + two*z(j,2)
            go to 80
 60         xd(j,4) = a2*x(j,5) + three*x(j,3)
            yd(j,4) = a2*y(j,5) + three*y(j,3)
            zd(j,4) = a2*z(j,5) + three*z(j,3)
            go to 80
 70         xd(j,5) = a2*x(j,6) + four*x(j,4)
            yd(j,5) = a2*y(j,6) + four*y(j,4)
            zd(j,5) = a2*z(j,6) + four*z(j,4)
            go to 80
 75         xd(j,6) = a2*x(j,7) + five*x(j,5)
            yd(j,6) = a2*y(j,7) + five*y(j,5)
            zd(j,6) = a2*z(j,7) + five*z(j,5)
 80      continue
 90   continue
      return
 100  do 170 i = 1 , ni
         do 160 j = 1 , nj
            go to (110,120,130,140,150,155) , j
 110        xd(1,i) = a2*x(2,i)
            yd(1,i) = a2*y(2,i)
            zd(1,i) = a2*z(2,i)
            go to 160
 120        xd(2,i) = a2*x(3,i) - x(1,i)
            yd(2,i) = a2*y(3,i) - y(1,i)
            zd(2,i) = a2*z(3,i) - z(1,i)
            go to 160
 130        xd(3,i) = a2*x(4,i) + two*x(2,i)
            yd(3,i) = a2*y(4,i) + two*y(2,i)
            zd(3,i) = a2*z(4,i) + two*z(2,i)
            go to 160
 140        xd(4,i) = a2*x(5,i) + three*x(3,i)
            yd(4,i) = a2*y(5,i) + three*y(3,i)
            zd(4,i) = a2*z(5,i) + three*z(3,i)
            go to 160
 150        xd(5,i) = a2*x(6,i) + four*x(4,i)
            yd(5,i) = a2*y(6,i) + four*y(4,i)
            zd(5,i) = a2*z(6,i) + four*z(4,i)
            go to 160
 155        xd(6,i) = a2*x(7,i) + five*x(5,i)
            yd(6,i) = a2*y(7,i) + five*y(5,i)
            zd(6,i) = a2*z(7,i) + five*z(5,i)
 160     continue
 170  continue
      return
      end
      subroutine donel(x,y,z,xd,yd,zd,a,lit,ljt)
      implicit REAL  (a-h,o-z)
      dimension x(6,*),y(6,*),z(6,*),xd(5,*),yd(5,*),zd(5,*)
      a2 = a + a
      do 90 j = 1 , ljt
         do 80 i = 1 , lit
            go to (30,40,50,60,70) , i
 30         xd(1,j) = a2*x(2,j)
            yd(1,j) = a2*y(2,j)
            zd(1,j) = a2*z(2,j)
            go to 80
 40         xd(2,j) = a2*x(3,j) - x(1,j)
            yd(2,j) = a2*y(3,j) - y(1,j)
            zd(2,j) = a2*z(3,j) - z(1,j)
            go to 80
 50         xd(3,j) = a2*x(4,j) - 2.0d0*x(2,j)
            yd(3,j) = a2*y(4,j) - 2.0d0*y(2,j)
            zd(3,j) = a2*z(4,j) - 2.0d0*z(2,j)
            go to 80
 60         xd(4,j) = a2*x(5,j) - 3.0d0*x(3,j)
            yd(4,j) = a2*y(5,j) - 3.0d0*y(3,j)
            zd(4,j) = a2*z(5,j) - 3.0d0*z(3,j)
            go to 80
 70         xd(5,j) = a2*x(6,j) - 4.0d0*x(4,j)
            yd(5,j) = a2*y(6,j) - 4.0d0*y(4,j)
            zd(5,j) = a2*z(6,j) - 4.0d0*z(4,j)
 80      continue
 90   continue
      return
      end
      subroutine wrtgrd(g,n1,n2,n3,n4,n5)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter (mxcen3 = 3 * maxat)
INCLUDE(common/machin)
      common/bufb/q(mxcen3),ix1,ix2,ix3,ix4,ix5
INCLUDE(common/iofile)
INCLUDE(common/dump3)
      dimension g(mxcen3)
      call dcopy(mxcen3,g,1,q,1)
      ix1 = n1
      ix2 = n2
      ix3 = n3
      ix4 = n4
      ix5 = n5
      call wrt3(q,mach(7),ibl3g,idaf)
      return
      end
      subroutine rdgrd(g,n1,n2,n3,n4,n5)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter (mxcen3 = 3 * maxat)
INCLUDE(common/machin)
      common/bufb/q(mxcen3),ix1,ix2,ix3,ix4,ix5
INCLUDE(common/iofile)
INCLUDE(common/dump3)
      dimension g(mxcen3)
      call rdedx(q,mach(7),ibl3g,idaf)
      call dcopy(mxcen3,q,1,g,1)
      n1 = ix1
      n2 = ix2
      n3 = ix3
      n4 = ix4
      n5 = ix5
      return
      end
      subroutine sder(zscftp,q)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
_IF(parallel)
INCLUDE(common/nodinf)
_ENDIF
INCLUDE(common/timez)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/zorac)
c
c...   this routine also used to calculated ZORA integrals 
c...   if oint_zora is .true.
c
      common/junk/desp(3,maxat),
     + pint,qint,rint,t,p0,q0,r0,pi,qi,ri,pj,qj,rj,ni,nj,
     + cx,cy,cz,
     + pin(6,5),qin(6,5),rin(6,5),pd(5,5),qd(5,5),rd(5,5),
     + dij(225),sx(225),sy(225),sz(225)
INCLUDE(common/mapper)
INCLUDE(common/segm)
      common/blkin/gout(5109),nword
INCLUDE(common/misc)
_IF(mp2_parallel,masscf)
c***   **MPP**
INCLUDE(common/mp2grad_pointers)
c***   **MPP**
_ENDIF
INCLUDE(common/timeperiods)

      dimension q(*)
      dimension ijx(35),ijy(35),ijz(35)
c     data sqrt3 /1.73205080756888d0/
      data dzero,done /0.0d0,1.0d0/
      data rln10 /2.30258d0/
      data zgrhf,zgvb/'grhf','gvb'/
      data m5110/5110/
      data ijx    / 1, 2, 1, 1, 3, 1, 1, 2, 2, 1,
     1              4, 1, 1, 3, 3, 2, 1, 2, 1, 2,
     2              5, 1, 1, 4, 4, 2, 1, 2, 1, 3,
     3              3, 1, 3, 2, 2/
      data ijy    / 1, 1, 2, 1, 1, 3, 1, 2, 1, 2,
     1              1, 4, 1, 2, 1, 3, 3, 1, 2, 2,
     2              1, 5, 1, 2, 1, 4, 4, 1, 2, 3,
     3              1, 3, 2, 3, 2/
      data ijz    / 1, 1, 1, 2, 1, 1, 3, 1, 2, 2,
     1              1, 1, 4, 1, 2, 1, 2, 3, 3, 2,
     2              1, 1, 5, 1, 2, 1, 2, 4, 4, 1,
     3              3, 3, 2, 2, 3/


      call start_time_period(TP_SDER)
c
c     ----- calculate derivatives of the overlap matrix -----
c
      tol = rln10*itol
      out = nprint.eq. - 3 .or. nprint.eq. - 10
      onorm = normf.ne.1 .or. normp.ne.1
_IF(secd_parallel)
csecd
c  not parallel in || secd version
c      
_ELSEIF(parallel)
c***   **MPP**
      iflop = iipsci()
c***   **MPP**
_ENDIF
      l1 = num
      l2 = (num*(num+1))/2
      l3 = num*num
c
c     ----- set pointers for partitioning of core -----
c
      i10 = igmem_alloc(l2)

c - allocate i20 and subdivide
_IF(mp2_parallel,masscf)
      i20 = igmem_alloc(l2*4)
      i30 = i20 + l2
      i31 = i20 + l3
      i40 = i30 + l2
      i51 = i40 + l3
_ELSE
      len = 3*l2
      if (zscftp.eq.zgrhf .or. zscftp.eq.zgvb) len = 2*l3+l1
      i20 = igmem_alloc(len)
      i30 = i20 + l2
      i31 = i20 + l3
      i40 = i30 + l2
      i51 = i31 + l3
c     i50 = i40 + l2
_ENDIF
c
      if (oint_zora) go to 666
c
c     ----- calculate eij-weighted density matrix -----
c
_IF(mp2_parallel,masscf)
c   version for mp2 and scf gradients using GA & MA tools
      call eijden(    zscftp
     &,               q(mp2grad_wmat)
     &,               q(mp2grad_vecs)
     &,               q(mp2grad_vals)
     &,  q(i10),q(i20),q(i40),q(i31),l1)
_ELSE
      call eijden(zscftp,q(i10),q(i20),q(i31),q(i51),l1,l3,l1,
     + nprint)
_ENDIF
      if (out.and.opg_root() ) then
         write (iwr,6010)
         call writel(q(i10),num)
         write (iwr,6020)
      end if
      nword = 1
c     if (oham) call search(ipos1,num8)
c
666   continue
c
c...   clear i10,i20,i30
c
      call vclr(q(i20),1,l2*3)
c
c     ----- ishell
c
      do 110 ii = 1 , nshell
         iat = katom(ii)
         pi = c(1,iat)
         qi = c(2,iat)
         ri = c(3,iat)
         i1 = kstart(ii)
         i2 = i1 + kng(ii) - 1
         lit = ktype(ii)
         lit1 = lit + 1
         mini = kmin(ii)
         maxi = kmax(ii)
         loci = kloc(ii) - mini
c
c     ----- jshell
c
         do 100 jj = 1 , ii

_IF(secd_parallel)
csecd
c  not parallel in || secd version
c      
_ELSEIF(parallel)
c***   **MPP**
         if (oipsci()) go to 100
c***   **MPP**
_ENDIF
            jat = katom(jj)
            if (iat.ne.jat.or.oint_zora) then
               pj = c(1,jat)
               qj = c(2,jat)
               rj = c(3,jat)
               if (oatint_z) then
c...              atomic is 1-center on origin
                  if (iat.ne.jat) go to 100
                  pi = 0.0d0
                  qi = 0.0d0
                  ri = 0.0d0
                  pj = 0.0d0
                  qj = 0.0d0
                  rj = 0.0d0
               end if
               j1 = kstart(jj)
               j2 = j1 + kng(jj) - 1
               ljt = ktype(jj)
               minj = kmin(jj)
               maxj = kmax(jj)
               locj = kloc(jj) - minj
               rr = (pi-pj)**2 + (qi-qj)**2 + (ri-rj)**2
               oianj = ii.eq.jj
c
c     ----- zero accumulators sx, sy, sz
c
               ij = 0
               do 20 i = mini, maxi
                  do 20 j = minj,maxj
                     ij = ij + 1
                     sx(ij) = dzero
                     sy(ij) = dzero
                     sz(ij) = dzero
 20            continue
c
c     ----- i primitive
c
               do 70 ig = i1 , i2
                  ai = ex(ig)
                  arri = ai*rr
                  axi = ai*pi
                  ayi = ai*qi
                  azi = ai*ri
                  csi = cs(ig)
                  cpi = cp(ig)
                  cdi = cd(ig)
                  cfi = cf(ig)
                  cgi = cg(ig)
c
c     ----- j primitive
c
                  do 60 jg = j1 , j2
                     aj = ex(jg)
                     aa = ai + aj
                     aa1 = done/aa
                     dum = aj*arri*aa1
                     if (dum.le.tol) then
                        fac = dexp(-dum)
                        csj = cs(jg)*fac
                        cpj = cp(jg)*fac
                        cdj = cd(jg)*fac
                        cfj = cf(jg)*fac
                        cgj = cg(jg)*fac
                        ax = (axi+aj*pj)*aa1
                        ay = (ayi+aj*qj)*aa1
                        az = (azi+aj*rj)*aa1
c
c     ----- density factor
c
                        call denfan(dij,csi,cpi,cdi,cfi,cgi,
     +                  csj,cpj,cdj,cfj,cgj,mini,maxi,minj,maxj,
     +                  .false.,.false.,onorm)
c
c     ----- overlap
c
                        t = dsqrt(aa1)
                        p0 = ax
                        q0 = ay
                        r0 = az
                        do 40 j = 1 , ljt
                           nj = j
                           do 30 i = 1 , lit1
                              ni = i
                              call vint
                              pin(i,j) = pint*t
                              qin(i,j) = qint*t
                              rin(i,j) = rint*t
 30                        continue
 40                     continue
                        call donel(pin,qin,rin,pd,qd,rd,ai,lit,ljt)
c
                        ij = 0
                        do 50 i = mini, maxi
                           ix = ijx(i)
                           iy = ijy(i)
                           iz = ijz(i)
                           do 55 j = minj, maxj
                              jx = ijx(j)
                              jy = ijy(j)
                              jz = ijz(j)
                              ij = ij + 1
                              sx(ij) = sx(ij) + dij(ij)
     +                        * pd(ix,jx) *qin(iy,jy)*rin(iz,jz)
                              sy(ij) = sy(ij) + dij(ij)
     +                        * pin(ix,jx)*qd(iy,jy) *rin(iz,jz)
                              sz(ij) = sz(ij) + dij(ij)
     +                        * pin(ix,jx)*qin(iy,jy)*rd(iz,jz)
 55                        continue
 50                     continue
                     end if
c
c     ----- end of primitive loops -----
c
 60               continue
 70            continue
c
c     ----- calculate derivatives of overlap matrix -----
c
               n = 0
               do 90 i = mini , maxi
                  in = loci + i
                  do 80 j = minj , maxj
                     n = n + 1
                     jn = locj + j
                     if (jn.le.in) then
                        nn = iky(in) + jn
                        q(nn-1+i20) = sx(n)
                        q(nn-1+i30) = sy(n)
                        q(nn-1+i40) = sz(n)
                        if (out) write (iwr,6030) in , jn , sx(n) ,
     +                                  sy(n) , sz(n) , q(nn-1+i10)
                        if (oham) then
                           gout(nword) = sx(n)
                           gout(nword+1) = sy(n)
                           gout(nword+2) = sz(n)
                           nword = nword + 3
                           if (nword.ge.m5110) then
                              nword = nword - 1
                              call wrt3(gout,m5110,ipos1,num8)
                              ipos1 = ipos1 + 10
                              nword = 1
                           end if
                        end if
                     end if
 80               continue
 90            continue
            end if
 100     continue
 110  continue
c
      if (oint_zora) then
c...     write as triangles (in extended basis)
         call wrt3(q(i20),l2,ibsx_z,num8)
         call wrt3(q(i30),l2,ibsy_z,num8)
         call wrt3(q(i40),l2,ibsz_z,num8)
         call gmem_free(i20)
         call gmem_free(i10)
         call end_time_period(TP_SDER)
         return
      end if
c
      if (oham) then
         nword = nword - 1
         call wrt3(gout,m5110,ipos1,num8)
         ipos1 = ipos1 + 10
      end if
      ipos2 = ipos1
c
c     ----- end of shell loops -----
c
      call glimit
c
c     ----- form the 1e-gradient -----
c
_IF(secd_parallel)
c secd disable dgop
_ELSE
       call pg_dgop(909,q(i20),l2*3,'+')
_ENDIF

      call sgrad(q(i10),q(i20),l2,q(1),nprint)
c
c     ----- reset core memory -----
c
      call gmem_free(i20)
      call gmem_free(i10)

      call end_time_period(TP_SDER)

      return
 6010 format (/40x,'lagrangian weighted density'/40x,27('*'))
 6020 format (//5x,'i',4x,'j',15x,'sx',18x,'sy',18x,'sz',18x,'lij')
 6030 format (1x,2i5,5x,4f20.8)
      end
_IF(qmmm)
      REAL function drg1(k,l)
      REAL rkl
INCLUDE(common/sizes)
INCLUDE(common/infoa)
      rkl=0.0d0
      do 20 i = 1 , 3
         rkl = rkl + (c(i,k)-c(i,l))**2
 20   continue
      drg1 = -1.0d0/rkl
      end
      REAL function drg2(k,l)
      REAL rkl
INCLUDE(common/sizes)
INCLUDE(common/infoa)
      rkl=0.0d0
      do 20 i = 1 , 3
         rkl = rkl + (c(i,k)-c(i,l))**2
 20   continue
      drg2 = dsqrt(rkl)
      end
_ENDIF

      subroutine sgrad(dd,sg,l2,drg,nprint)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      logical indij,indji
INCLUDE(common/repp)
INCLUDE(common/infoa)
      dimension dd(*),sg(l2,3)
INCLUDE(common/iofile)
INCLUDE(common/runlab)
INCLUDE(common/chgcc)
INCLUDE(common/timeperiods)
      common/junk/de(3,maxat),pint(13),nint(2),cpint(3),
     *liminf(maxat),limsup(maxat)
     *,eg(3,maxat),eg3(3,maxat),detare(900),qkl(3,maxat)
      dimension ydnam(3),drg(*)
      data ydnam /'e/x','e/y','e/z'/
      data dzero,done,two /0.0d0,1.0d0,2.0d0/

      call start_time_period(TP_SGRAD)

c
c     ----- allocate core for distance matrix
c
      out = nprint.eq. - 3 .or. nprint.eq. - 10
      nn = nat*nat
c
_IF(vdw)
      call vdwaals_gradient(de)
_ENDIF

c
      if(.not.indi) then
c
_IFN(qmmm)
      i10 = igmem_alloc(nn)
c
c     ----- form distance matrix for derivatives of
c           nuclear repulsion energy.              -----
c
      drg(i10) = dzero

      do 40 k = 2 , nat
         kkk = (k-1)*nat + i10 - 1
         drg(kkk+k) = dzero
         k1 = k - 1
         do 30 l = 1 , k1
            lll = (l-1)*nat + i10 - 1
            rkl = dzero
            do 20 i = 1 , 3
               rkl = rkl + (c(i,k)-c(i,l))**2
 20         continue
            drg(k+lll) = -done/rkl
            drg(l+kkk) = dsqrt(rkl)
 30      continue
 40   continue
_ENDIF
c
c     ----- now we are ready to form -eg- vector
c
      do 130 kk = 1 , 3

         iflop = iipsci()

         eg(kk,1) = dzero
         eg3(kk,1) = dzero

         do 80 k = 2 , nat

            eg(kk,k) = dzero
            eg3(kk,k) = dzero

            if (oipsci()) go to 80

            kinf = liminf(k)
            ksup = limsup(k)
            czak = czan(k)
            km1 = k - 1
            kkk = km1*nat + i10 - 1
            obqk = (omtslf .and. zaname(k)(1:2).eq.'bq')
            do 70 l = 1 , km1

               obql = (omtslf .and. zaname(l)(1:2).eq.'bq')
               lll = (l-1)*nat + i10 - 1
               linf = liminf(l)
               lsup = limsup(l)
               czal = czan(l)
_IF(qmmm)
               if(.not. (obqk .and. obql))then
                  pkl = (c(kk,k)-c(kk,l))/drg2(k,l)
                  eg3(kk,k) = eg3(kk,k) + pkl*drg1(k,l)*czak*czal
               endif
_ELSE
               if(.not. (obqk .and. obql))then
                  pkl = (c(kk,k)-c(kk,l))/drg(l+kkk)
                  eg3(kk,k) = eg3(kk,k) + pkl*drg(k+lll)*czak*czal
               endif
_ENDIF
               if (kinf.ne.0 .and. linf.ne.0) then
                  do 60 i = kinf , ksup
                     do 50 j = linf , lsup
                        ij = (i*(i-1))/2 + j
                        eg(kk,k) = eg(kk,k) - sg(ij,kk)*dd(ij)
 50                  continue
 60               continue
               end if
 70         continue
 80      continue


         iflop = iipsci()

         nat1 = nat - 1
         do 120 k = 1 , nat1

            if (oipsci()) go to 120

            czak = czan(k)
            kinf = liminf(k)
            ksup = limsup(k)
            kp1 = k + 1
            kkk = (k-1)*nat + i10 - 1
            obqk = (omtslf .and. zaname(k)(1:2).eq.'bq')
            do 110 l = kp1 , nat
               obql = (omtslf .and. zaname(l)(1:2).eq.'bq')
               lll = (l-1)*nat + i10 - 1
               czal = czan(l)
               linf = liminf(l)
               lsup = limsup(l)
_IF(qmmm)
               if(.not. (obqk .and. obql))then
                  pkl = (c(kk,k)-c(kk,l))/drg2(k,l)
                  eg3(kk,k) = eg3(kk,k) + pkl*drg1(k,l)*czak*czal
               endif
_ELSE
               if(.not. (obqk .and. obql))then
                  pkl = (c(kk,k)-c(kk,l))/drg(k+lll)
                  eg3(kk,k) = eg3(kk,k) + pkl*drg(l+kkk)*czak*czal
               endif
_ENDIF

               if (kinf.ne.0 .and. linf.ne.0) then
                  do 100 i = kinf , ksup
                     do 90 j = linf , lsup
                        ij = (j*(j-1))/2 + i
                        eg(kk,k) = eg(kk,k) + sg(ij,kk)*dd(ij)
 90                  continue
 100              continue
               end if
 110        continue
 120     continue
 130  continue

c
c     ----- add all contributions to 1e-gradient -----
c
      do i = 1 , nat
         do j = 1 , 3
            eg3(j,i) = eg3(j,i) - two*eg(j,i)
         enddo
      enddo

      call pg_dgop(9044,eg3,nat*3,'+')

      do i = 1 , nat
         do  j = 1 , 3
            de(j,i) = de(j,i) + eg3(j,i)
         enddo
      enddo

_IFN(qmmm)
      call gmem_free(i10)
_ENDIF(qmmm)

      else
c
      i10 = igmem_alloc(nn)
c
c     ----- form distance matrix for derivatives of
c           nuclear repulsion energy.              -----
c
      drg(i10) = dzero

      call vclr(detare,1,900)
      do 340 k = 2 , nat
         kkk = (k-1)*nat + i10 - 1
         drg(kkk+k) = dzero
         k1 = k - 1
         do 330 l = 1 , k1
            lll = (l-1)*nat + i10 - 1
            rkl = dzero
            do 320 i = 1 , 3
               rkl = rkl + (c(i,k)-c(i,l))**2
320         continue
c
c     prepare information for more general core - core interaction
c     (repulsion between d - cores of nuclei)
c     after each loop the expression is added to 1e - gradient
c
            li = 0
            do 21 lu = 1,npairs
               indij = ichgat(k).eq.indx(lu).and.ichgat(l).eq.jndx(lu)
               indji = ichgat(k).eq.jndx(lu).and.ichgat(l).eq.indx(lu)
               if (indij.or.indji) li=lu
 21         continue
            dsqrr = dsqrt(rkl)
            if (li.ne.0) then
               deta = -d(li)*eta(li)/dsqrr
               dexa = dexp(-eta(li)*dsqrr)
               detare(l+kkk-i10+1)=deta*dexa
            endif
            drg(k+lll) = -done/rkl
            drg(l+kkk) = dsqrr
330      continue
340   continue
c
c     ----- now we are ready to form -eg- vector
c
      do 350 kk = 1 , 3
         eg(kk,1) = dzero
         eg3(kk,1) = dzero
         qkl(kk,1) = dzero
         do 380 k = 2 , nat
            eg(kk,k) = dzero
            eg3(kk,k) = dzero
            qkl(kk,k) = dzero
            kinf = liminf(k)
            ksup = limsup(k)
            czak = czan(k)
            km1 = k - 1
            kkk = km1*nat + i10 - 1
            obqk = (omtslf .and. zaname(k)(1:2).eq.'bq')
            do 370 l = 1 , km1
               lll = (l-1)*nat + i10 - 1
               obql = (omtslf .and. zaname(l)(1:2).eq.'bq')
               linf = liminf(l)
               lsup = limsup(l)
               czal = czan(l)
               qkl(kk,k) = qkl(kk,k) + (c(kk,k)-c(kk,l))*
     +                      detare(l+kkk-i10+1)
               if(.not. (obqk .and. obql))then
                  pkl = (c(kk,k)-c(kk,l))/drg(l+kkk)
                  eg3(kk,k) = eg3(kk,k) + pkl*drg(k+lll)*czak*czal
               endif
               if (kinf.ne.0 .and. linf.ne.0) then
                  do 390 i = kinf , ksup
                     do 400 j = linf , lsup
                        ij = (i*(i-1))/2 + j
                        eg(kk,k) = eg(kk,k) - sg(ij,kk)*dd(ij)
 400                 continue
 390              continue
               end if
 370        continue
 380     continue
         nat1 = nat - 1
         do 360 k = 1 , nat1
            czak = czan(k)
            kinf = liminf(k)
            ksup = limsup(k)
            kp1 = k + 1
            kkk = (k-1)*nat + i10 - 1
            obqk = (omtslf .and. zaname(k)(1:2).eq.'bq')
            do 410 l = kp1 , nat
               lll = (l-1)*nat + i10 - 1
               obql = (omtslf .and. zaname(l)(1:2).eq.'bq')
               czal = czan(l)
               linf = liminf(l)
               lsup = limsup(l)
               qkl(kk,k) = qkl(kk,k) + (c(kk,k) - c(kk,l))*
     +                     detare(k+lll-i10+1)
               if(.not. (obqk .and. obql))then
                  pkl = (c(kk,k)-c(kk,l))/drg(k+lll)
                  eg3(kk,k) = eg3(kk,k) + pkl*drg(l+kkk)*czak*czal
               endif
               if (kinf.ne.0 .and. linf.ne.0) then
                  do 420 i = kinf , ksup
                     do 430 j = linf , lsup
                        ij = (j*(j-1))/2 + i
                        eg(kk,k) = eg(kk,k) + sg(ij,kk)*dd(ij)
 430                 continue
 420              continue
               end if
 410        continue
 360     continue
 350  continue
      do 440 k = 1 , nat
         do 450 kk = 1 , 3
            eg(kk,k) = two*eg(kk,k)
 450     continue
 440  continue
c
c     ----- add all contributions to 1e-gradient -----
c
      do 470 i = 1 , nat
         do 460 j = 1 , 3
            eg3(j,i) = eg3(j,i) + de(j,i)
            de(j,i) = eg3(j,i) - eg(j,i) + qkl(j,i)
 460     continue
 470  continue
c
      call gmem_free(i10)

      endif
c
c     ----- print section -----
c
      if (out) then
         write (iwr,6050)
         mmax = 0
 180     mmin = mmax + 1
         mmax = mmax + 8
         if (mmax.gt.nat) mmax = nat
         write (iwr,6010)
         write (iwr,6020) (i,i=mmin,mmax)
         write (iwr,6010)
         do 190 n = 1 , 3
            write (iwr,6030) ydnam(n) , (de(n,i),i=mmin,mmax)
 190     continue
         if (mmax.lt.nat) go to 180
         write (iwr,6040)
         mmax = 0
 200     mmin = mmax + 1
         mmax = mmax + 8
         if (mmax.gt.nat) mmax = nat
         write (iwr,6010)
         write (iwr,6020) (i,i=mmin,mmax)
         write (iwr,6010)
         do 210 n = 1 , 3
            write (iwr,6030) ydnam(n) , (eg(n,i),i=mmin,mmax)
 210     continue
         if (mmax.lt.nat) go to 200

      end if
c
c ----- reset core
c

      call end_time_period(TP_SGRAD)

      return
 6010 format (/)
 6020 format (5x,'atom',8(6x,i3,6x))
 6030 format (7x,a3,8e15.7)
 6040 format (/,10x,32('-'),/,10x,'overlap contribution to gradient',/,
     +        10x,32('-'))
 6050 format (/10x,22('-')/10x,'one-electron gradient'/10x,20('-'))
      end
      subroutine skip80(iat80,jat80,iat,nbact,oskip)
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character*8 (z), character*1 (x), character*4 (y)
INCLUDE(common/sizes)
c
c     ----- routine to flag whether the surrounding atom has to be
c           included in the one electron integrals involving the
c           shells on iat80 and jat80 -----
c
INCLUDE(common/g80nb)
      dimension nbact(*)
c
      oskip = .false.
c
c     ----- return if iat is purely non bonded with respective to the
c           g80 atoms -----
c
      if (nbact(iat).ne.0) then
c
c     ----- skip if iat is the map of g80 atom .or. far away ----
c
         if (nbact(iat).eq.-1) then
c
c     ----- atom iat is non-bonded -----
c
c
c     ----- atom iat is to be skipped -----
c
            oskip = .true.
            return
         end if
      end if
c
c     ----- check if iat is an excluded atom for iat80 or jat80 -----
c
c     18/3/90  all mm atoms are now retained so that all qm
c              atoms 'feel' the same mm atoms ie nonbonded pairs
c              are no longer rejected on the basis of being a 1,3 or
c              1,4 connection
c     ixa = ipnonb(iat80)
c     ixb = ipnonb(iat80+1) - 1
c     do 120 i = ixa , ixb
c            if( inonb(i) .eq. iat ) go to 400
c 120 continue
c     ixa = ipnonb(jat80)
c     ixb = ipnonb(jat80+1) - 1
c     do 140 i = ixa , ixb
c            if ( inonb(i) .eq. iat ) go to 400
c 140 continue
      return
      end
      subroutine stvder(zscftp,core,prefa,iso,nshels)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/segm)
      common/junk/de(3,maxat)
INCLUDE(common/infoa)
INCLUDE(common/modj)
INCLUDE(common/scra7)
INCLUDE(common/misc)
INCLUDE(common/specal)
_IF(ccpdft)
INCLUDE(common/dump3)
INCLUDE(common/iofile)
INCLUDE(common/ccpdft.hf77)
INCLUDE(common/statis)
INCLUDE(common/blur)
_ENDIF
_IF(charmm)
INCLUDE(common/chmgms)
_ENDIF
INCLUDE(common/drfopt)
_IF(drf)
INCLUDE(../drf/comdrf/sizesrf)
INCLUDE(../drf/comdrf/drfpar)
INCLUDE(../drf/comdrf/drfbem)
INCLUDE(../drf/comdrf/runpar)
INCLUDE(../drf/comdrf/rfene)
INCLUDE(../drf/comdrf/rfgrad)
      logical odrf
_ENDIF
      dimension core(*),prefa(*),iso(nshels,*)
c
_IF(drf)
      odrf = field .ne. ' '
      if (odrf) then
        if (nat + nxtpts .gt. maxat) then
          write(iwr,101)
  101     format(/,' Too many QM + Classical atoms for gradient')
          call caserr('Problem too large for gradient: change maxat')
        endif
      endif
_ENDIF
      nat3 = 3*nat
      i10a = igmem_alloc_inf(225*nat3,'drv1e.m','stvder',
     &                       'helman-feynman',IGMEM_DEBUG)
c
      iposf1 = ibl7la
      ipos1 = iposf1
      omp2 = mp2
      opdipd = runtyp.eq.'mpdipder'
      oham = fkder.eq.'fockder'
      ouhf = zscftp .eq. 'uhf '

c
c          helman feynman force
c ...
      call helfey(zscftp,core,prefa,iso,core(i10a),nat,nshels)
_IF(mp2_parallel,masscf)
c
c gdf:       integral force  for mp2 gradient GA version
c
      call tvder(zscftp,core,prefa,idum0,idum0,idum0,iso,nshels)
_ELSE
c ...
c      nuclear and surrounding repulsion contribution
c ...

      if (oaminc) then
         call stvmm(core,i10,i20,i30)
      end if
c
      if (lpseud.eq.2) then
         call stvecp(zscftp,core)
      end if
c
c           integral force
c
      call tvder(zscftp,core,prefa,i20,i10,i30,iso,nshels)

      if (oaminc) then
         call gmem_free_inf(i30,'drv1e.m','stvder','nbact')
         call gmem_free_inf(i20,'drv1e.m','stvder','czmod')
         call gmem_free_inf(i10,'drv1e.m','stvder','cmod')
      endif

_ENDIF
c ...
c           density force
c ...
      call sder(zscftp,core)
c ...
c     include mechanics contibution if required.
c ...
      if (omodel) call model(core,core,3)
_IF(ccpdft)
c
c Kohn Sham XC gradient contributions
c
      if(CD_active()) then

            outon = nprint.ne.-5
            call timana(6)
            call cpuwal(begin,ebegin)
            if(opg_root().and.outon)write(iwr,*) 
     +      'Now off to CD_forces'

            l2     = (num*(num+1))/2
            igrad =igmem_alloc_inf(nat3,'drv1e.m','stvder','dft_grad',
     &                             IGMEM_DEBUG)
            iadens=igmem_alloc_inf(l2,'drv1e.m','stvder',
     &                             'alpha-dens-mat',IGMEM_NORMAL)
            call rdedx(core(iadens),l2,ibl3pa,idaf)
            call dcopy(nat3,de,1,core(igrad),1)
	    if(ouhf)then
               ibdens=igmem_alloc_inf(l2,'drv1e.m','stvder',
     &                                'beta-dens-mat',IGMEM_NORMAL)
               call rdedx(core(ibdens),l2,ibl3pb,idaf)
               idum = CD_forces_ao(c,core(iadens),core(ibdens),
     &              core,core,core(igrad),outon,iwr)
               call gmem_free_inf(ibdens,'drv1e.m','stvder',
     &                            'beta-dens-mat')
            else
               idum = CD_forces_ao(c,core(iadens),dumb,
     &              core,core,core(igrad),outon,iwr)
            endif
            call dcopy(nat3,core(igrad),1,de,1)
            call gmem_free_inf(iadens,'drv1e.m','stvder',
     &                         'alpha-dens-mat') 
            call gmem_free_inf(igrad,'drv1e.m','stvder','dft_grad') 
            call timana(32)
            call cpuwal(begin,ebegin)
         endif
******
         if(oblur)then
         if(opg_root()) write(iwr,*)'Gradient blur=',oblur
            l2     = (num*(num+1))/2
            iadens=igmem_alloc_inf(l2,'drv1e.m','stvder',
     &                             'alpha-dens-mat',IGMEM_NORMAL)
            call rdedx(core(iadens),l2,ibl3pa,idaf)
            idum = gden_forces(c,core(iadens),dumb,
     &           core,core,de,outon,ochmdbg,iwr)
            call gmem_free_inf(iadens,'drv1e.m','stvder',
     &                         'alpha-dens-mat') 
         endif
*******
_ENDIF

_IF(drf)
      if (odrf) then
        call drfgrad(core)
      endif
_ENDIF

c
c     save 1e-gradient on disk and check time -----
c
      nrest = 6
      ist = 1
      jst = 1
      kst = 1
      lst = 1
      call wrtgrd(de,nrest,ist,jst,kst,lst)
      call texit(0,nrest)
c
      call gmem_free_inf(i10a,'drv1e.m','stvder','helman-feynman')
c
      if (ofokab .or. oham) then

         i10 = igmem_alloc_all_inf(lsize,'drv1e.m','stvder',
     &                             'ofokab.or.oham',IGMEM_DEBUG)
         if (ofokab) call fabzer(core(i10))
         if (oham) call hamd1(core(i10),prefa,iso,nshels,lsize)
c
c     ----- reset core allocation
c
         call gmem_free_inf(i10,'drv1e.m','stvder','ofokab.or.oham')
      end if
c
      iposf1 = ipos1
      iposf2 = ipos2
      return
      end
      subroutine stvecp(zscftp,core)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/junk/de(3,maxat)
INCLUDE(common/infoa)
INCLUDE(common/symtry)
INCLUDE(common/timeperiods)


      dimension core(*)

      call start_time_period(TP_STVECP)

c
c --- split up some core for wder to use.
c
c     nav = lenwrd()
c
c     l1 = num
c
      l2 = (num*(num+1))/2
c l4 is 180*num since the max. size of dsdw,x,y,z is num*itpmax*ncomp
c since itpmax and ncomp are calculated in wder their maximum possible
c sizes are used here: itpmax 20, ncomp 9; hence 180*num
      l4 = num*180
c l5 is 9*num because (i think) dumw,x,y,z can have maximum
c dimensions of (ncomp,num)
      l5 = num*9


      i10 = 0
      i20 = i10 + l4
      i30 = i20 + l4
      i40 = i30 + l4
      i50 = i40 + l4
      i70 = i50 + l2
      i80 = i70 + l5
      i90 = i80 + l5
      i100 = i90 + l5
      i110 = i100 + l5
      i120 = i110 + l2
      last = i120 + nw196(6)
      length = last - i10

      i10 = igmem_alloc(length)
      i20 = i10 + l4
      i30 = i20 + l4
      i40 = i30 + l4
      i50 = i40 + l4
      i70 = i50 + l2
      i80 = i70 + l5
      i90 = i80 + l5
      i100 = i90 + l5
      i110 = i100 + l5
      i120 = i110 + l2

      call wder(core(i10),core(i20),core(i30),core(i40),core(i50),
     +          core(i70),core(i80),core(i90),core(i100),core(i110),
     +          core(i120),zscftp,nat,l2)
c               dsdw      dsdx      dsdy      dsdz
c               dd         dumw      dumx      dumy
c               dumz       db       ict
c
c ...                    reset memory.
      call gmem_free(i10)
c
      call end_time_period(TP_STVECP)

      return
      end
      subroutine stvmm(core,i10,i20,i30)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      common/junk/de(3,maxat)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/modj)
INCLUDE(common/g80nb)
INCLUDE(common/symtry)
INCLUDE(common/restri)
      dimension core(*)
      data  m51/51/
c ...
c      nuclear and surrounding repulsion contribution
c ...
      nat3 = 3*natmod

      i10 = igmem_alloc_inf(nat3,'drv1e.m','stvmm','cmod',IGMEM_DEBUG)
      i20 = igmem_alloc_inf(natmod,'drv1e.m','stvmm','czmod',
     &                      IGMEM_DEBUG)
      i30 = igmem_alloc_inf(natmod,'drv1e.m','stvmm','czmod',
     &                      IGMEM_DEBUG)
c
      call secget(isect(472),m51,ibl172)
      call rdedx(core(i10),nat3,ibl172,idaf)
      call secget(isect(473),m51,ibl173)
      nword = (natmod-1) / lenwrd() + 1
      call rdedx(core(i30),nword,ibl173,idaf)
      call secget(isect(474),m51,ibl174)
      call rdedx(core(i20),natmod,ibl174,idaf)
      call czderv(nat,natmod,de,c,core(i10),czan,core(i20),
     +            core(i30))
c
      return
      end
_EXTRACT(tvder,ultra,_AND(hp800,i8))
c PS: 22/8/03 zscftp is now taken from common/runlab so first
c     subroutine arg is a dummy
      subroutine tvder(zdumm,q,prefa,icmod,iczmod,inbact,
     +                 iso,nshels)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/cslosc)
INCLUDE(common/mapper)
INCLUDE(common/timez)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
      common/junk/de(3,maxat),
     +   pint,qint,rint,t,p0,q0,r0,pi,qi,ri,pj,qj,rj,ni,nj,
     +   cx,cy,cz,
     +   pin(6,7),qin(6,7),rin(6,7),pad(5,5),qad(5,5),rad(5,5),
     +   delx(6,5),dely(6,5),delz(6,5),
     +   delxa(5,5),delya(5,5),delza(5,5),
     +   tvx(225),tvy(225),tvz(225),
     +   dij(225),tvd(3,maxat)
INCLUDE(common/segm)
INCLUDE(common/root)
INCLUDE(common/g80nb)
INCLUDE(common/modj)
INCLUDE(common/chgcc)
      common/blkin/gout(5109),nword
INCLUDE(common/misc)
_IF(parallel)
**   ***node-MPP***
      common/bufb/scratc(maxat*3)
**   ***node-MPP***
_ENDIF
_IF(mp2_parallel,masscf)
INCLUDE(common/mp2grad_pointers)
_ENDIF
_IF(charmm)
INCLUDE(common/chmgms)
_ENDIF
INCLUDE(common/timeperiods)
INCLUDE(common/prints)
INCLUDE(common/runlab)
      dimension ydnam(3),q(*),prefa(*)
      dimension iso(nshels,*)
      dimension ibuffi(8)
      dimension ijx(35),ijy(35),ijz(35)
c
      data ijx    / 1, 2, 1, 1, 3, 1, 1, 2, 2, 1,
     1              4, 1, 1, 3, 3, 2, 1, 2, 1, 2,
     2              5, 1, 1, 4, 4, 2, 1, 2, 1, 3,
     3              3, 1, 3, 2, 2/
      data ijy    / 1, 1, 2, 1, 1, 3, 1, 2, 1, 2,
     1              1, 4, 1, 2, 1, 3, 3, 1, 2, 2,
     2              1, 5, 1, 2, 1, 4, 4, 1, 2, 3,
     3              1, 3, 2, 3, 2/
      data ijz    / 1, 1, 1, 2, 1, 1, 3, 1, 2, 2,
     1              1, 1, 4, 1, 2, 1, 2, 3, 3, 2,
     2              1, 1, 5, 1, 2, 1, 2, 4, 4, 1,
     3              3, 3, 2, 2, 3/ 
      data m5110/5110/
      data ydnam /'e/x','e/y','e/z'/
      data pi212 /1.1283791670955d0/
      data dzero,done,two /0.0d0,1.0d0,2.0d0 /
      data pt5 /0.5d0/
      data rln10 /2.30258d0/
c     data sqrt3 /1.73205080756888d0/
c     data three,five,seven /3.0d0,5.0d0,7.0d0/
c     data zuhf,zgrhf,zgvb/'uhf','grhf','gvb'/
c
      out = nprint.eq. - 3 .or. nprint.eq. - 10
      outall = nprint.eq. - 10

      call start_time_period(TP_TVDER)
_IF(charmm)
      out = out .and. .not. onoatpr
_ENDIF

_IF(parallel)
c***   **MPP**
      iflop = iipsci()
c***   **MPP**
_ENDIF
      if (outall) write (iwr,6070)
      tol = rln10*itol
      onorm = normf.ne.1 .or. normp.ne.1
      l2 = (num*(num+1))/2
      l3 = num*num
c
c     ----- set pointers for partitioning of core -----
c
      i10 = igmem_alloc(l2)
      i20 = igmem_alloc(l3)
c... i20 is used for density matrix and abused for vectors (jvl 97)
      i101 = i10 - 1
c
_IF(mp2_parallel,masscf)
c  version for mp2 and scf gradients using GA & MA tools
      l1 = num
      call dendd1(   zscftp, q(i10),q(i20),
     &               q(mp2grad_dens),
     &               q(mp2grad_pmat),  l1)
_ELSE
      call dendd1(zscftp,q(i10),q(i20),l2)
_ENDIF
c
c     if (oham) call search(ipos1,num8)
      do 30 j = 1 , nat
         do 20 i = 1 , 3
            tvd(i,j) = dzero
 20      continue
 30   continue
      nword = 1
c
c     ----- ishell
c
      do 240 ii = 1 , nshell
         iat = katom(ii)
         pi = c(1,iat)
         qi = c(2,iat)
         ri = c(3,iat)
         i1 = kstart(ii)
         i2 = i1 + kng(ii) - 1
         lit = ktype(ii)
         lit1 = lit + 1
         mini = kmin(ii)
         maxi = kmax(ii)
         loci = kloc(ii) - mini
c
c     ----- jshell
c
         do 230 jj = 1 , nshell
            tolij = dlntol + prefa(iky(max(ii,jj))+min(ii,jj))
            if (tolij.gt.0.0d0) then
_IF(secd_parallel)
csecd
c  not parallel in || secd version
c      
_ELSEIF(parallel)
c***   **MPP**
            if (oipsci()) go to 230
c***   **MPP**
_ENDIF
               jat = katom(jj)
               pj = c(1,jat)
               qj = c(2,jat)
               rj = c(3,jat)
               j1 = kstart(jj)
               j2 = j1 + kng(jj) - 1
               ljt = ktype(jj)
               minj = kmin(jj)
               maxj = kmax(jj)
               locj = kloc(jj) - minj
               nroots = (lit+ljt+1)/2
               rr = (pi-pj)**2 + (qi-qj)**2 + (ri-rj)**2
c
c     ----- zero accumulators tvx, tvy, yvz
c
               ij = 0
               do 40 i = mini, maxi
                  do 40 j = minj, maxj
                     ij = ij +1
                     tvx(ij) = dzero
                     tvy(ij) = dzero
                     tvz(ij) = dzero
 40            continue
c
c     ----- i primitive
c
               do 200 ig = i1 , i2
                  ai = ex(ig)
                  arri = ai*rr
                  axi = ai*pi
                  ayi = ai*qi
                  azi = ai*ri
                  csi = cs(ig)
                  cpi = cp(ig)
                  cdi = cd(ig)
                  cfi = cf(ig)
                  cgi = cg(ig)
c
c     ----- j primitive
c
                  do 190 jg = j1 , j2
                     aj = ex(jg)
                     aa = ai + aj
                     aa1 = done/aa
                     dum = aj*arri*aa1
                     if (dum.le.tol) then
                        fac = dexp(-dum)
                        csj = cs(jg)*fac
                        cpj = cp(jg)*fac
                        cdj = cd(jg)*fac
                        cfj = cf(jg)*fac
                        cgj = cg(jg)*fac
                        ax = (axi+aj*pj)*aa1
                        ay = (ayi+aj*qj)*aa1
                        az = (azi+aj*rj)*aa1
c
c     ----- density factor
c
                        call denfan(dij,csi,cpi,cdi,cfi,cgi,
     +                        csj,cpj,cdj,cfj,cgj,
     +                        mini,maxi,minj,maxj,.false.,.false.,
     +                        onorm)
c
c     -----  kinetic energy
c
                        t = dsqrt(aa1)
                        t1 = -two*aj*aj*t
                        t2 = -pt5*t
                        t22 = aj*t
                        p0 = ax
                        q0 = ay
                        r0 = az
                        do 60 i = 1 , lit1
                           ni = i
                           do 50 j = 1 , ljt
                              nj = j
                              call vint
                              pin(i,j) = pint*t
                              qin(i,j) = qint*t
                              rin(i,j) = rint*t
c     elements of del-squared
                              dum = dfloat(j+j-1)*t22
                              delx(i,j) = dum*pint
                              dely(i,j) = dum*qint
                              delz(i,j) = dum*rint
                              nj = j + 2
                              call vint
                              delx(i,j) = delx(i,j) + pint*t1
                              dely(i,j) = dely(i,j) + qint*t1
                              delz(i,j) = delz(i,j) + rint*t1
                              if (j.gt.2) then
                                 nj = j - 2
                                 call vint
                                 n = (j-1)*(j-2)
                                 dum = dfloat(n)*t2
                                 delx(i,j) = delx(i,j) + pint*dum
                                 dely(i,j) = dely(i,j) + qint*dum
                                 delz(i,j) = delz(i,j) + rint*dum
                              end if
 50                        continue
 60                     continue
                        call donel(pin,qin,rin,pad,qad,rad,ai,lit,ljt)
                        call donel(delx,dely,delz,delxa,delya,delza,ai,
     +                             lit,ljt)
                        ij = 0
                        do 70 i = mini,maxi
                        ix = ijx(i)
                        iy = ijy(i)
                        iz = ijz(i)
                           do 70 j = minj,maxj
                           jx = ijx(j)
                           jy = ijy(j)
                           jz = ijz(j)
                           ij = ij + 1
                           d1 = dij(ij)
                           tvx(ij) = tvx(ij)+ d1*(
     +                         delxa(ix,jx)*qin (iy,jy)* rin(iz,jz)
     +                       + pad  (ix,jx)*dely(iy,jy)* rin(iz,jz)
     +                       + pad  (ix,jx)*qin (iy,jy)*delz(iz,jz))
                           tvy(ij) = tvy(ij)+ d1*(
     +                          delx(ix,jx)*qad  (iy,jy)*rin (iz,jz)
     +                          +pin(ix,jx)*delya(iy,jy)*rin (iz,jz)
     +                          +pin(ix,jx)*qad  (iy,jy)*delz(iz,jz))
                           tvz(ij) = tvz(ij)+ d1*(
     +                          delx(ix,jx)*qin (iy,jy)*rad  (iz,jz)
     +                          +pin(ix,jx)*dely(iy,jy)*rad  (iz,jz)
     +                          +pin(ix,jx)*qin (iy,jy)*delza(iz,jz))
 70                     continue
c
c     ..... nuclear attraction
c
                        dum = pi212*aa1
                        do 80 i = 1 , ij
                           dij(i) = dij(i)*dum
 80                     continue
                        aax = aa*ax
                        aay = aa*ay
                        aaz = aa*az
                        do 130 ic = 1 , nat
                           cznuc = -czan(ic)
                           cx = c(1,ic)
                           cy = c(2,ic)
                           cz = c(3,ic)
                           pp = aa*((ax-cx)**2+(ay-cy)**2+(az-cz)**2)
                           if (nroots.le.3) call rt123
                           if (nroots.eq.4) call roots4
                           if (nroots.eq.5) call roots5
                           do 120 k = 1 , nroots
                              uu = aa*u(k)
                              ww = w(k)*cznuc
                              tt = done/(aa+uu)
                              t = dsqrt(tt)
                              p0 = (aax+uu*cx)*tt
                              q0 = (aay+uu*cy)*tt
                              r0 = (aaz+uu*cz)*tt
                              do 100 i = 1 , lit1
                                 ni = i
                                 do 90 j = 1 , ljt
                                    nj = j
                                    call vint
                                    pin(i,j) = pint
                                    qin(i,j) = qint
                                    rin(i,j) = rint*ww
 90                              continue
 100                          continue
                              call donel(pin,qin,rin,pad,qad,rad,ai,lit,
     +                           ljt)
                              ij = 0
                              do 110 i = mini,maxi
                                 ix = ijx(i) 
                                 iy = ijy(i)
                                 iz = ijz(i)
                                 do 110 j = minj,maxj
                                 jx = ijx(j)
                                 jy = ijy(j)
                                 jz = ijz(j)
                                 ij = ij +1
                                 d1 = dij(ij)
                                 tvx(ij) = tvx(ij) + d1*
     +                                pad(ix,jx)*qin(iy,jy)*rin(iz,jz)
                                 tvy(ij) = tvy(ij) + d1*
     +                                pin(ix,jx)*qad(iy,jy)*rin(iz,jz)
                                 tvz(ij) = tvz(ij) + d1*
     +                                pin(ix,jx)*qin(iy,jy)*rad(iz,jz)
 110                          continue
 120                       continue
 130                    continue
c ...
c            ----- surrounding interaction -----
c ...
                        if (oaminc) then
                           ic3 = -3
                           do 180 ic = 1 , natmod
                              ic3 = ic3 + 3
                              call skip80(iat,jat,ic,q(inbact),oskmod)
                              if (.not.oskmod) then
                                 cznuc = -q(icmod-1+ic)
                                 cx = q(iczmod-1+ic3+1)
                                 cy = q(iczmod-1+ic3+2)
                                 cz = q(iczmod-1+ic3+3)
                                 pp = aa*((ax-cx)**2+(ay-cy)**2+(az-cz)
     +                                **2)
                                 if (nroots.le.3) call rt123
                                 if (nroots.eq.4) call roots4
                                 if (nroots.eq.5) call roots5
                                 do 170 k = 1 , nroots
                                    uu = aa*u(k)
                                    ww = w(k)*cznuc
                                    tt = done/(aa+uu)
                                    t = dsqrt(tt)
                                    p0 = (aax+uu*cx)*tt
                                    q0 = (aay+uu*cy)*tt
                                    r0 = (aaz+uu*cz)*tt
                                    do 150 i = 1 , lit1
                                       ni = i
                                       do 140 j = 1 , ljt
                                         nj = j
                                         call vint
                                         pin(i,j) = pint
                                         qin(i,j) = qint
                                         rin(i,j) = rint*ww
 140                                   continue
 150                                continue
                                    call donel(pin,qin,rin,pad,qad,rad,
     +                                 ai,lit,ljt)
                                    ij = 0
                                    do 160 i = mini,maxi
                                       ix = ijx(i) 
                                       iy = ijy(i)
                                       iz = ijz(i)
                                       do 160 j = minj,maxj
                                       jx = ijx(j)
                                       jy = ijy(j)
                                       jz = ijz(j)
                                       ij = ij +1
                                       d1 = dij(ij)
                                       tvx(ij) = tvx(ij) + d1*
     +                                pad(ix,jx)*qin(iy,jy)*rin(iz,jz)
                                       tvy(ij) = tvy(ij) + d1*
     +                                pin(ix,jx)*qad(iy,jy)*rin(iz,jz)
                                       tvz(ij) = tvz(ij) + d1*
     +                                pin(ix,jx)*qin(iy,jy)*rad(iz,jz)
 160                                continue
 170                             continue
                              end if
 180                       continue
                        end if
                     end if
c
c     ----- end of primitive loops -----
c
 190              continue
 200           continue
c
c     ----- calculate contribution to gradient -----
c
               n = 0
               do 220 i = mini , maxi
                  in = loci + i
                  do 210 j = minj , maxj
                     n = n + 1
                     jn = locj + j
                     nn = iky(max(in,jn)) + min(in,jn)
                     dum0 = q(nn+i101)
                     dum = dum0 + dum0
                     if (oham) then
                        gout(nword) = tvx(n)
                        gout(nword+1) = tvy(n)
                        gout(nword+2) = tvz(n)
                        nword = nword + 3
                        if (nword.ge.m5110) then
                           nword = nword - 1
                           call wrt3(gout,m5110,ipos1,num8)
                           nword = 1
                           ipos1 = ipos1 + 10
                        end if
                     end if
                     tvd(1,iat) = tvd(1,iat) + dum*tvx(n)
                     tvd(2,iat) = tvd(2,iat) + dum*tvy(n)
                     tvd(3,iat) = tvd(3,iat) + dum*tvz(n)
                     if (outall) write (iwr,6060) in , jn , tvx(n) ,
     +                                  tvy(n) , tvz(n) , dum0
 210              continue
 220           continue
            end if
 230     continue
 240  continue
c
c     ----- end of shell loops -----
c
      if (oham) then
         nword = nword - 1
         call wrt3(gout,m5110,ipos1,num8)
         ipos1 = ipos1 + 10
         call clredx
      end if
      do 260 j = 1 , nat
         do 250 i = 1 , 3
            de(i,j) = de(i,j) + tvd(i,j)
 250     continue
 260  continue
_IF(secd_parallel)
csecd
c disable dgop here
_ELSEIF(parallel)
c***   ***node-MPP***
c...    first gop everything together (to be ok on dumpfile/ see ddebut)
      call pg_dgop(904,de,nat*3,'+')
c***   ***node-MPP***
_ENDIF

      if (lpseud.eq.1 .and. .not. obqf) then
c

_IF(parallel)
         i50 = igmem_alloc(3*maxat)
         call ecdint(q,q(i10),q(i50),iso,nshels,oham,out)
         do 290  n=1,3
         in = i50-1+n
         do 290  i=1,nat
         de(n,i) = de(n,i) + q(in)
         in = in + 3
 290     continue
         call gmem_free(i50)
_ELSE 
         call ecdint(q,q(i10),iso,nshels,oham,out)
_ENDIF
      end if

      if (out) then
      if (oprint(31)) then
c
c  print out non-bq centres only
c
         mmax = 0
         do while (mmax .lt. nat)
            omore = .true.
            do while (omore)
               nbuff = 0
               if (nbuff .eq. 8 .or. mmax .ge. nat) then
                  omore = .false.
               else
                  mmax = mmax + 1
                  if (zaname(mmax)(1:2) .ne. 'bq')then
                     nbuff = nbuff + 1
                     ibuffi(nbuff) = mmax
                  endif
               endif
            enddo
            if (nbuff .gt. 0) then
               write (iwr,6020)
               write (iwr,6030) (ibuffi(i),i=1,nbuff)
               write (iwr,6020)
               do n = 1 , 3
                  write (iwr,6040) ydnam(n),(de(n,ibuffi(i)),i=1,nbuff)
               enddo
            endif
            write (iwr,6050)
         enddo

      else
         mmax = 0
 270     mmin = mmax + 1
         mmax = mmax + 8
         if (mmax.gt.nat) mmax = nat
         write (iwr,6020)
         write (iwr,6030) (i,i=mmin,mmax)
         write (iwr,6020)
         do 280 n = 1 , 3
            write (iwr,6040) ydnam(n),(de(n,i),i=mmin,mmax)
 280     continue

         if (mmax.lt.nat) go to 270
         write (iwr,6050)
      end if
      end if

c
c     ----- reset core memory -----
c
      call gmem_free(i20)
      call gmem_free(i10)

      call end_time_period(TP_TVDER)

      return
 6010 format (/10x,45('-')/10x,'other 1 electron contribution',
     +        ' to the gradient'/10x,45('-'))
 6020 format (/)
 6030 format (5x,'atom',8(6x,i3,6x))
 6040 format (7x,a3,8e15.7)
 6050 format (/' ...... end of 1-electron gradient ...... '/)
 6060 format (1x,2i5,5x,4f20.8)
 6070 format (//5x,'i',4x,'j',15x,'ex',18x,'ey',18x,'ez',18x,'dij')
      end
_ENDEXTRACT
      subroutine vint
c
c     ----- gauss-hermite quadrature using minimum point formula -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/junk/desp(3,maxat),
     +       pint,qint,rint,t,p0,q0,r0,pi,qi,ri,pj,qj,rj,ni,nj,
     +       cx,cy,cz
INCLUDE(common/hermit)
INCLUDE(common/wermit)
      dimension min(7),max(7)
      data min /1,2,4, 7,11,16,22/
      data max /1,3,6,10,15,21,28/
      data dzero /0.0d0/
c
      pint = dzero
      qint = dzero
      rint = dzero
      npts = (ni+nj-2)/2 + 1
      imin = min(npts)
      imax = max(npts)
      do 160 i = imin , imax
         dum = w(i)
         px = dum
         py = dum
         pz = dum
         dum = h(i)*t
         ptx = dum + p0
         pty = dum + q0
         ptz = dum + r0
         ax = ptx - pi
         ay = pty - qi
         az = ptz - ri
         bx = ptx - pj
         by = pty - qj
         bz = ptz - rj
         go to (70,60,50,40,30,20,10) , ni
 10      px = px*ax
         py = py*ay
         pz = pz*az
 20      px = px*ax
         py = py*ay
         pz = pz*az
 30      px = px*ax
         py = py*ay
         pz = pz*az
 40      px = px*ax
         py = py*ay
         pz = pz*az
 50      px = px*ax
         py = py*ay
         pz = pz*az
 60      px = px*ax
         py = py*ay
         pz = pz*az
 70      go to (150,140,130,120,110,100,90,80) , nj
 80      px = px*bx
         py = py*by
         pz = pz*bz
 90      px = px*bx
         py = py*by
         pz = pz*bz
 100     px = px*bx
         py = py*by
         pz = pz*bz
 110     px = px*bx
         py = py*by
         pz = pz*bz
 120     px = px*bx
         py = py*by
         pz = pz*bz
 130     px = px*bx
         py = py*by
         pz = pz*bz
 140     px = px*bx
         py = py*by
         pz = pz*bz
 150     pint = pint + px
         qint = qint + py
         rint = rint + pz
 160  continue
      return
      end
      subroutine ver_drv1e(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/drv1e.m,v $
     +     "/
      data revision /"$Revision: 6231 $"/
      data date /"$Date: 2011-03-29 16:16:48 +0200 (Tue, 29 Mar 2011) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
