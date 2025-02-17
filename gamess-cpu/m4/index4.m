c 
c  $Author: mrdj $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/index4.m,v $
c  $State: Exp $
c  
      subroutine indx40(buf,lbuf,map,triag,
     +   vec,naos,nmos,aiqrs,ntriao,aijrs,aijks,w,
     +   nocc,kkkk,ifirst,ilast,ibatch,idim,ifilao,ifilmo,lcanon,
     +   cutoff)
      implicit REAL  (a-h,o-z)
      logical last,lcanon
INCLUDE(common/sizes)
INCLUDE(common/restar)
      dimension vec(naos,nmos),aiqrs(ntriao,naos,idim),aijrs(ntriao),
     &   aijks(naos),w(naos,naos),buf(lbuf),map(ntriao),triag(ntriao)
      parameter (maxint=3400)
      common/scra/val(maxint),li(maxint),lj(maxint),lk(maxint),
     &  ll(maxint),lij(maxint),lkl(maxint)
      common/outgo/vout(510),nout
_IFN1(iv)      common/sortpk/labs(1360)
_IF1(iv)      common/sortpk/labs(340),labkl(340)
      common/craypk/kbcray(1360)
INCLUDE(common/mapper)
      character *8 groupy
      common/indsyx/groupy
      common/indsym/nrep,itable(8,8),irep(maxorb)
      data m1/1/
c
      call setsto(1360,0,kbcray)
c
c      4-index transformation for large memory machines.
c
c      requires approx (n*(n+1)*(n+1))/2 + 2*n*n + n storage
c
c      this version for restricted transformations
c      kkkk = 1 ; (xo/xo) only
c      kkkk = 2 ; (xo/xo) and (xx/oo)
c      kkkk = 3 ; (oo/oo),(xo/oo),(xo/xo),(xx/oo)
c      kkkk = 4 ; not (xx/xx)
c
c      nocc ( nominally number of occupied orbitals ) is
c      used to divide list into two halfs
c
c     begin transformation for m.o.s in batch ifirst to ilast
c     zero out storage
_IF1(c)cdir$  list
_IF1(c)cdir$  novector
      irlen = nintmx
      if1 = ifirst - 1
      call vclr(aiqrs,1,idim*naos*ntriao)
      call search(m1,ifilao)
      inbrel = -1
      if (lcanon) then
c  >>>>>>>>>>>>>>>  canonical list  <<<<<<<<<<<<<<<<<
         kij = 0
         do 50 ki = 1 , naos
            do 40 kj = 1 , ki
               kij = kij + 1
               call cangt1(buf,buf,lbuf,inbrel,map,nzero,triag,ifilao)
c-------------------------------------------------------------
               if (map(nzero).eq.kij) triag(nzero) = triag(nzero)*0.5d0
               call vclr(aijrs,1,ntriao)
_IF1(c)ccdir$ ivdep
_IF1(t)cdir$ ivdep
_IF1(a)cvd$  nodepck
_IF1(x)c$dir no_recurrence
               do 20 i = 1 , nzero
                  aijrs(map(i)) = triag(i)
 20            continue
               call square(w,aijrs,naos,naos)
c
               call mxmb(w,1,naos,vec(1,ifirst),1,naos,aiqrs(kij,1,1),
     +                   ntriao,ntriao*naos,ki,ki,ibatch)
c
c
               do 30 i = 1 , ibatch
                  if (vec(ki,i+if1).ne.0.0d0)
_IFN1(c)     +                call daxpyi(nzero,vec(ki,i+if1),triag,map,
_IFN1(c)     +                aiqrs(1,kj,i))
_IF1(c)     +                call spaxpy(nzero,vec(ki,i+if1),triag,
_IF1(c)     +                aiqrs(1,kj,i),map)
                  if ((vec(kj,i+if1).ne.0.0d0) .and. ki.ne.kj)
_IFN1(c)     +                call daxpyi(nzero,vec(kj,i+if1),triag,map,
_IFN1(c)     +                            aiqrs(1,ki,i))
_IF1(c)     +                call spaxpy(nzero,vec(kj,i+if1),triag,
_IF1(c)     +                            aiqrs(1,ki,i),map)
 30            continue
 40         continue
 50      continue
c
      else
c
c ------------- not canonical list --------------------------
 60      call indblm(nint,val,li,lj,lk,ll,ifilao,last)
         do 70 n = 1 , nint
            lij(n) = iky(li(n)) + lj(n)
            lkl(n) = iky(lk(n)) + ll(n)
 70      continue
         do 80 n = 1 , nint
            if (lij(n).eq.lkl(n)) val(n) = val(n)*0.5d0
 80      continue
         if (ibatch.le.9) then
_IF1(x)c$dir scalar
            do 110 i = 1 , ibatch
               do 90 n = 1 , nint
                  temp = aiqrs(lkl(n),lj(n),i) + val(n)*vec(li(n),i+if1)
                  aiqrs(lkl(n),li(n),i) = aiqrs(lkl(n),li(n),i) + val(n)
     +               *vec(lj(n),i+if1)
                  aiqrs(lkl(n),lj(n),i) = temp
 90            continue
               do 100 n = 1 , nint
                  temp = aiqrs(lij(n),ll(n),i) + val(n)*vec(lk(n),i+if1)
                  aiqrs(lij(n),lk(n),i) = aiqrs(lij(n),lk(n),i) + val(n)
     +               *vec(ll(n),i+if1)
                  aiqrs(lij(n),ll(n),i) = temp
 100           continue
 110        continue
         else
            do 130 n = 1 , nint
               do 120 i = 1 , ibatch
                  temp = aiqrs(lkl(n),lj(n),i) + val(n)*vec(li(n),i+if1)
                  aiqrs(lkl(n),li(n),i) = aiqrs(lkl(n),li(n),i) + val(n)
     +               *vec(lj(n),i+if1)
                  aiqrs(lkl(n),lj(n),i) = temp
 120           continue
 130        continue
            do 150 n = 1 , nint
               do 140 i = 1 , ibatch
                  temp = aiqrs(lij(n),ll(n),i) + val(n)*vec(lk(n),i+if1)
                  aiqrs(lij(n),lk(n),i) = aiqrs(lij(n),lk(n),i) + val(n)
     +               *vec(ll(n),i+if1)
                  aiqrs(lij(n),ll(n),i) = temp
 140           continue
 150        continue
         end if
         if (.not.last) go to 60
      end if
c----------------------------------------------------------
c
c     have now read a.o. integrals and made (qj/rs)
c
c     now for second quarter transformation
c     this is now simple matrix * vector
c
      do 250 j = ifirst , ilast
         jb = j - if1
c
c     j will be occupied orbital
c     i will have range of virtual mos only (kkkk=1)
c     or occupied and virtual mos (kkkk=2,3,4)
         imax = nmos
         imin = j
         if (kkkk.eq.1) imin = nocc + 1
c
c
         do 240 i = imin , imax
            ijsym = itable(irep(i),irep(j))
            call vclr(aijrs,1,ntriao)
            call mxmb(aiqrs(1,1,jb),1,ntriao,vec(1,i),1,1,aijrs,1,
     +                ntriao,ntriao,naos,1)
c
c     at this point have (ij/rs) , what happens now
c     depends on type of restriction
c     if kkkk = 1, produce (xo/xo) from (xo/rs), with
c     i.ge.j  , k.ge.l and kl.ge.ij
c
c     if kkkk = 2 produce (xo/xo) as above and
c     (oo/xx) from (oo/rs)
c
c     if kkkk = 3 produce (xo/xo) as above and
c     (oo/oo), (oo/xo) and (oo/xx) from (oo/rs) i.e.
c     all kl.ge.ij
c
c     if kkkk = 4 produce (oo/oo), (oo/xo) and (oo/xx)
c     from (oo/rs) and (xo/xo) and (xo/xx) from (xo/rs)
c     note that (xo/xx) case will have some kl.lt.ij
c     and some kl.gt.ij
c
c     third quarter case 1 : ij = (oo/ ; kl = /xx)
c
            if (i.le.nocc .and. j.le.nocc .and. kkkk.eq.2) then
               call squr(aijrs,w,naos)
               do 170 k = nocc + 1 , nmos
                  ijksym = itable(ijsym,irep(k))
                  call vclr(aijks,1,naos)
                  call mxmb(w,1,naos,vec(1,k),1,1,aijks,1,naos,naos,
     +                      naos,1)
c
c     fourth quarter
c
                  do 160 l = nocc + 1 , k
                     if (ijksym.eq.irep(l)) then
                        ans = ddot(naos,aijks,1,vec(1,l),1)
                        if (dabs(ans).ge.cutoff) then
                           nout = nout + 1
                           vout(nout) = ans
_IFN1(iv)                           n2 = nout + nout
_IFN1(iv)                           labs(n2) = j + i4096(i)
_IFN1(iv)                           labs(n2-1) = l + i4096(k)
_IF1(iv)                           labkl(nout) = j + i4096(i)
_IF1(iv)                           labs (nout) = l + i4096(k)
                           if (nout.eq.irlen) then
                              call indblo(nout,vout,labs,ifilmo)
                              nout = 0
                           end if
                        end if
                     end if
 160              continue
 170           continue
            end if
c     end of case 1
c
c     third quarter case 2 , ij = (oo/ ; all kl.ge.ij
c
            if (i.le.nocc .and. j.le.nocc .and. kkkk.ge.3) then
               call squr(aijrs,w,naos)
               do 190 k = i , nmos
                  ijksym = itable(ijsym,irep(k))
                  call vclr(aijks,1,naos)
                  call mxmb(w,1,naos,vec(1,k),1,1,aijks,1,naos,naos,
     +                      naos,1)
c
c     fourth quarter
c
                  lmin = 1
                  if (i.eq.k) lmin = j
                  do 180 l = lmin , k
                     if (ijksym.eq.irep(l)) then
                        ans = ddot(naos,aijks,1,vec(1,l),1)
                        if (dabs(ans).ge.cutoff) then
                           nout = nout + 1
                           vout(nout) = ans
_IFN1(iv)                           n2 = nout + nout
_IFN1(iv)                           labs(n2) = j + i4096(i)
_IFN1(iv)                           labs(n2-1) = l + i4096(k)
_IF1(iv)                           labkl(nout) = j + i4096(i)
_IF1(iv)                           labs (nout) = l + i4096(k)
                           if (nout.eq.irlen) then
                              call indblo(nout,vout,labs,ifilmo)
                              nout = 0
                           end if
                        end if
                     end if
 180              continue
 190           continue
            end if
c     end of case 2
c
c     third quarter case 3 ij = (xo/ ; kl = /xo)
c
            if (i.gt.nocc .and. j.le.nocc) then
               call squr(aijrs,w,naos)
               do 210 l = 1 , nocc
                  ijksym = itable(ijsym,irep(l))
                  call vclr(aijks,1,naos)
                  call mxmb(w,1,naos,vec(1,l),1,1,aijks,1,naos,naos,
     +                      naos,1)
c
c     fourth quarter
c
                  kmin = i
                  if (l.lt.j) kmin = i + 1
                  do 200 k = kmin , nmos
                     if (ijksym.eq.irep(k)) then
                        ans = ddot(naos,aijks,1,vec(1,k),1)
                        if (dabs(ans).ge.cutoff) then
                           nout = nout + 1
                           vout(nout) = ans
_IFN1(iv)                           n2 = nout + nout
_IFN1(iv)                           labs(n2) = j + i4096(i)
_IFN1(iv)                           labs(n2-1) = l + i4096(k)
_IF1(iv)                           labkl(nout) = j + i4096(i)
_IF1(iv)                           labs (nout) = l + i4096(k)
                           if (nout.eq.irlen) then
                              call indblo(nout,vout,labs,ifilmo)
                              nout = 0
                           end if
                        end if
                     end if
 200              continue
 210           continue
            end if
c     end of case 3
c     third quarter case 4 ; ij= (xo/ ; kl = /xx)
c
            if (i.gt.nocc .and. j.le.nocc .and. kkkk.ge.4) then
               call squr(aijrs,w,naos)
               do 230 k = nocc + 1 , nmos
                  ijksym = itable(ijsym,irep(k))
                  call vclr(aijks,1,naos)
                  call mxmb(w,1,naos,vec(1,k),1,1,aijks,1,naos,naos,
     +                      naos,1)
c
c     fourth quarter
c
                  do 220 l = nocc + 1 , k
                     if (ijksym.eq.irep(l)) then
                        ans = ddot(naos,aijks,1,vec(1,l),1)
                        if (dabs(ans).ge.cutoff) then
                           nout = nout + 1
                           vout(nout) = ans
                           if (i.gt.k) then
_IFN1(iv)                              n2 = nout + nout
_IFN1(iv)                              labs(n2-1) = j + i4096(i)
_IFN1(iv)                              labs(n2) = l + i4096(k)
_IF1(iv)                              labs (nout) = j + i4096(i)
_IF1(iv)                              labkl(nout) = l + i4096(k)
                           else
_IFN1(iv)                              n2 = nout + nout
_IFN1(iv)                              labs(n2) = j + i4096(i)
_IFN1(iv)                              labs(n2-1) = l + i4096(k)
_IF1(iv)                              labkl(nout) = j + i4096(i)
_IF1(iv)                              labs (nout) = l + i4096(k)
                           end if
                           if (nout.eq.irlen) then
                              call indblo(nout,vout,labs,ifilmo)
                              nout = 0
                           end if
                        end if
                     end if
 220              continue
 230           continue
            end if
c     end of case 4
 240     continue
 250  continue
_IF1(c)cdir$  nolist
_IF1(c)cdir$  vector
      return
      end
      subroutine indx1a(q,sq,x,qq)
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
c
      dimension q(*),sq(*),x(*),qq(*)
c
      common/junke/maxt,ires,ipass,
     1nteff,npass1,npass2,lentri,
     2nbuck,mloww,mhi,ntri,iacc
c
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/mapper)
      common/bufb/nkk,mkk,gin(1)
      common/blkin/gout(510),mword
_IFN1(iv)      common/craypk/kbcray(680)
_IF1(iv)      common/craypk/kbcray(340),macray(340)
INCLUDE(common/infoa)
INCLUDE(common/three)
INCLUDE(common/vectrn)
INCLUDE(common/atmblk)
      common/symmos/imos(8,maxorb),ibasis(8,maxorb),nt
c
      dimension nsign(8),msign(8)
      data maxb/999999/
c
c     read the eigenvectors
c  ---------------------------------------------------------------
c
      call setsto(680,0,kbcray)
      nblkq = num*ncoorb
      call secget(isecvv,itypvv,iblkq)
      iblkq = iblkq + mvadd
      call rdedx(sq,nblkq,iblkq,ifild)
c     now copy only the active m.o's into q.
      do 30 i = 1 , nsa4
         j = ilifq(i)
         k = ilifm(i)
         do 20 l = 1 , num
            q(j+l) = sq(k+l)
 20      continue
 30   continue
c
c
      imin = 1
      imax = nsa4
      jmax = nsa4
c     noc1 = noccb + 1
      jmin = 1
      irange = imax - imin + 1
      jrange = jmax - jmin + 1
c   -----------------------------------------------------------
c
c
      mword = 0
_IFN1(iv)      int4=-1
      small = 10.0d0**(-iacc-1)
      master = master + 1
      irma = 0
 40   irma = irma + 1
      if (iky(irma).lt.master) go to 40
      irma = irma - 1
      isma = master - iky(irma)
c
c     scan   sort    file
c
      call stopbk
      do 150 ibuck = 1 , nbuck
         mhigh = mloww + ntri
         if (mhigh.gt.mhi) mhigh = mhi
         mtri = mhigh - mloww
         mloww = mloww + 1
         nsize = mtri*nx
         call vclr(qq,1,nsize)
c
c     read in a core load in triangles
c     -------------------------------------------------
c
         mkk = mark(ibuck)
 50      if (mkk.ne.maxb) then
            iblock = mkk
            call rdbak(iblock)
            call stopbk
c...   move block to processing area
            call transg(qq,nx)
            go to 50
         else
c   --------------------------------------------------------------
c
c     start loops over triangles
c     irma=r,irsa=s,master =(rs)
c
            map = 0
            do 140 itri = 1 , mtri
               do 60 i = 1 , nx
                  if (qq(map+i).ne.0.0d0) go to 70
 60            continue
               go to 130
c
c     symmetry information about pair /rs>
c  ---------------------------------------------------------------
c
 70            do 80 i = 1 , nt
                  jr = ibasis(i,irma)
                  is = ibasis(i,isma)
                  irr = iabs(jr)
                  iss = iabs(is)
                  ib = iky(max(irr,iss)) + min(irr,iss)
                  if (ib.ne.master) then
                     nsign(i) = 0
                  else
                     ib = jr*is
                     if (ib.lt.0) then
                        nsign(i) = -1
                     else if (ib.ne.0) then
                        nsign(i) = 1
                     end if
                  end if
 80            continue
c     -----------------------------------------------------------
c     convert triangle to square form
c
               call square(sq,qq(map+1),num,num)
c
               n = num*imax
               call vclr(x,1,n)
c    -------------------------------------------------------------
c
c     transform to <iq/rs>  where i is set of m.o.'s
c     which on average has smallest range
c
               call mxmb(sq,1,num,q,1,num,x,1,num,num,num,imax)
c
c    -------------------------------------------------------------
c     loop over orbitals j to give <ij/rs>
c
               call vclr(sq,1,irange*jrange)
c
c
               call mxmb(x,num,1,q(ilifq(jmin)+1),1,num,sq,jrange,1,
     +                   jrange,num,irange)
               ij = 0
               do 120 i = imin , imax
                  do 90 iop = 1 , nt
                     msign(iop) = nsign(iop)*imos(iop,i)
 90               continue
c
c      reject zero's (numerical or symmetry)
c
                  do 110 j = jmin , jmax
                     ij = ij + 1
                     if (j.ge.i) then
                        do 100 iop = 1 , nt
                           if (msign(iop)*imos(iop,j).eq.-1) go to 110
 100                    continue
                        top = sq(ij)
                        if (dabs(top).ge.small) then
c
                           mword = mword + 1
                           gout(mword) = top
                           ijtri = iky(j) + i
_IF1(iv)                           kbcray(mword) = ijtri
_IF1(iv)                           macray(mword) = master
_IFN1(iv)                          int4=int4+2
_IFN1(iv)                          kbcray(int4  ) = ijtri
_IFN1(iv)                          kbcray(int4+1) = master
                           if (mword.eq.nintmx) then
                            call indblc()
_IFN1(iv)                   int4=-1
                           endif
                        end if
                     end if
 110              continue
 120           continue
c     end loop over i
c     end loop over j
 130           master = master + 1
               isma = isma + 1
               if (isma.gt.irma) then
                  irma = irma + 1
                  isma = 1
               end if
               map = map + nx
 140        continue
            mloww = mhigh
         end if
 150  continue
c
c     end loop over /rs>
c
      if (mword.ge.1) call indblc()
_IFN1(iv)      int4=-1
      master = master - 1
      return
      end
      subroutine indx1c(q,sq,x,qq)
c------------------------------------------------
c   should be no machine dependent features in calc1c
c   though algorithm may be unwise on scalar machine
c---------------------------------------------------
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/sizes)
      dimension q(*),sq(*),x(*),qq(*)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/mapper)
      common/junke/maxt,ires,ipass,
     + nteff,npass1,npass2,lentri,
     + nbuck,mloww,mhi,ntri,iacc
      common/bufb/nkk,mkk,gin(1)
      common/blkin/gout(510),mword
_IFN1(iv)      common/craypk/kbcray(680)
_IF1(iv)      common/craypk/kbcray(340),macray(340)
INCLUDE(common/infoa)
INCLUDE(common/three)
INCLUDE(common/vectrn)
INCLUDE(common/atmblk)
INCLUDE(common/cigrad)
      common/symmos/imos(8,maxorb),ibasis(8,maxorb),nt
     1  ,nt3,itable(8,8),mult(8,8),irt(maxorb),imosb(8,maxorb)
     2  , nirrb(maxorb)
INCLUDE(common/ghfblk)
      logical  exist,uhf
INCLUDE(common/prnprn)
c
      dimension nsign(8),msign(8)
      character *8 open,grhf
      data open/'open'/
      data maxb/999999/
      data  grhf/'grhf'/
      uhf = scftyp.eq.open
c
      if (scftyp.eq.grhf .and. iscftp.lt.99 .and. .not.lci) then
         nupact = 0
         iscftp = 5
         do 30 k = 1 , njk
            nsi = nbshel(k)
            i = ilfshl(k)
            do 20 m = i + 1 , i + nsi
               nupact = max(nupact,iactiv(m))
 20         continue
 30      continue
         write (iwr,6010)nupact
      end if
      call setsto(680,0,kbcray)
c
c     read the eigenvectors
c  ------------------------------------------
c
      nblkq = num*ncoorb
      call secloc(isecvv,exist,iblkq)
      iblkq = iblkq + mvadd
      call rdedx(sq,nblkq,iblkq,ifild)
c     now copy only the active m.o's into q.
      do 50 i = 1 , nsa4
         j = ilifq(i)
         k = ilifm(i)
         do 40 l = 1 , num
            q(j+l) = sq(k+l)
 40      continue
 50   continue
c
c     --------------------------------------------------
c     restrictions on range of loops
c     iscftp=0 : no restriction
c     iscftp=1 : <vo/vo> only
c     iscftp=2 : <vo/vo>,<vv/oo>
c     iscftp=3 : ,<vv/oo>,<vo/oo>,<oo/oo>
c     iscftp=4 : not <vv/vv>
c
      imin = 1
      imax = nsa4
      noc1 = noccb + 1
      if (iscftp.ne.99) imax = noccb
      if (iscftp.eq.5) imax = nupact
      if (uhf .and. isecvv.eq.isect(8)) noc1 = nocca + 1
      if (uhf .and. isecvv.eq.isect(8) .and. iscftp.ne.99) imax = nocca
      jmax = nsa4
      jmin = 1
      if (iscftp.eq.1) jmin = noc1
      irange = imax - imin + 1
      jrange = jmax - jmin + 1
c   --------------------------------------
c
c
      mword = 0
_IFN1(iv)      int4=-1
      small = 10.0d0**(-iacc-2)
      master = master + 1
      irma = 0
 60   irma = irma + 1
      if (iky(irma).lt.master) go to 60
      irma = irma - 1
      isma = master - iky(irma)
c
c     scan   sort    file
c
      call stopbk
      do 190 ibuck = 1 , nbuck
         mhigh = mloww + ntri
         if (mhigh.gt.mhi) mhigh = mhi
         mtri = mhigh - mloww
         mloww = mloww + 1
         nsize = mtri*nx
         call vclr(qq,1,nsize)
c
c...   read in a core load in triangles
c     -------------------------------------------------
c
         mkk = mark(ibuck)
 70      if (mkk.ne.maxb) then
            iblock = mkk
            call rdbak(iblock)
            call stopbk
c...   move block to processing area
            call transg(qq,nx)
            go to 70
         else
c   -------------------------------------------
c
c     start loops over triangles
c     irma=r,irsa=s,master =(rs)
c
            map = 0
            do 180 itri = 1 , mtri
               do 80 i = 1 , nx
                  if (qq(map+i).ne.0.0d0) go to 90
 80            continue
               go to 170
c
c     symmetry information about pair /rs>
c  -------------------------------------------------
c
 90            do 100 i = 1 , nt
                  ir1 = ibasis(i,irma)
                  is = ibasis(i,isma)
                  irr = iabs(ir1)
                  iss = iabs(is)
                  ib = iky(max(irr,iss)) + min(irr,iss)
                  if (ib.ne.master) then
                     nsign(i) = 0
                  else
                     ib = ir1*is
                     if (ib.lt.0) then
                        nsign(i) = -1
                     else if (ib.ne.0) then
                        nsign(i) = 1
                     end if
                  end if
 100           continue
c        ---------------------------------------------------
c
c     convert triangle to square form
c
               call square(sq,qq(map+1),num,num)
c
               n = num*imax
               call vclr(x,1,n)
c    -------------------------------------------------------
c
c     transform to <iq/rs>  where i is set of m.o.'s
c     which on average has smallest range
c
               call mxmb(sq,1,num,q,1,num,x,1,num,num,num,imax)
c
c    -----------------------------------------------
c     loop over orbitals j to give <ij/rs>
c
               call vclr(sq,1,irange*jrange)
               call mxmb(q(ilifq(jmin)+1),num,1,x,1,num,sq,1,jrange,
     +                   jrange,num,irange)
c
               ij = 0
               do 160 i = imin , imax
                  if (uhf .and. isecvv.eq.isect(11)) then
                     do 110 iop = 1 , nt
                        msign(iop) = nsign(iop)*imosb(iop,i)
 110                 continue
                  else
                     do 120 iop = 1 , nt
                        msign(iop) = nsign(iop)*imos(iop,i)
 120                 continue
                  end if
c
c      reject zero's (numerical or symmetry)
c
                  do 150 j = jmin , jmax
                     ij = ij + 1
                     if (j.ge.i) then
                        if (uhf .and. isecvv.eq.isect(11)) then
                           do 130 iop = 1 , nt
                              if (msign(iop)*imosb(iop,j).eq.-1)
     +                            go to 150
 130                       continue
                        else
                           do 140 iop = 1 , nt
                              if (msign(iop)*imos(iop,j).eq.-1)
     +                            go to 150
 140                       continue
                        end if
                        top = sq(ij)
                        if (dabs(top).ge.small) then
c
                           mword = mword + 1
                           gout(mword) = top
                           ijtri = iky(j) + i
_IF1(iv)                           kbcray(mword) = ijtri
_IF1(iv)                           macray(mword) = master
_IFN1(iv)                          int4=int4+2
_IFN1(iv)                          kbcray(int4  ) = ijtri
_IFN1(iv)                          kbcray(int4+1) = master
                           if (odebug(11)) write(iwr,*) 'calc1 output' ,
     +                         ijtri , master , top
                           if (mword.eq.nintmx) then
                            call indblc()
_IFN1(iv)                          int4 = -1
                           endif
                        end if
                     end if
 150              continue
 160           continue
c     end loop over i
c     end loop over j
 170           master = master + 1
               isma = isma + 1
               if (isma.gt.irma) then
                  irma = irma + 1
                  isma = 1
               end if
               map = map + nx
 180        continue
            mloww = mhigh
         end if
 190  continue
c
c     end loop over /rs>
c
      if (mword.ge.1) call indblc()
_IFN1(iv)      int4 = -1
      master = master - 1
      return
 6010 format(/1x,'highest occupied orbital',i3)
      end
      subroutine indx2a(q,sq,x,qq)
      implicit REAL  (a-h,o-z)
      dimension q(*),x(*),qq(*),sq(*)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/mapper)
c
      common/junke/maxt,ires,ipass,
     +  nteff,npass1,npass2,lentri,
     +  nbuck,mloww,mhi,ntri,iacc
      common/bufb/nkk,mkk,gin(1)
      common/blkin/gout(510),mword
_IFN1(iv)      common/craypk/mwcray(680)
_IF1(iv)      common/craypk/mwcray(340),kbcray(340)
c
INCLUDE(common/three)
INCLUDE(common/vectrn)
INCLUDE(common/atmblk)
      common/symmos/imos(8,maxorb),ibasis(8,maxorb),nt,nt2,
     & itable(8,8),mult(8,8),nirr(maxorb)
INCLUDE(common/prnprn)
      data maxb/999999/
c
      call setsto(680,0,mwcray)
c
c     read in orbitals
c   ----------------------------------------------------
      nblkq = num*ncoorb
      call secget(isecvv,itypvv,iblkq)
      iblkq = iblkq + mvadd
      call rdedx(sq,nblkq,iblkq,ifild)
      do 30 i = 1 , nsa4
         j = ilifm(i)
         k = ilifq(i)
         do 20 l = 1 , num
            q(k+l) = sq(j+l)
 20      continue
 30   continue
c    -----------------------------------------------------------
c
      acc1 = 10.0d0**(-iacc)
c     noc1 = noccb + 1
c
c      scan  sort  file
c   ------------------------------------------------------------
      mword = 0
      call stopbk
      do 120 ibuck = 1 , nbuck
         mhigh = mloww + ntri
         if (mhigh.gt.mhi) mhigh = mhi
         mtri = mhigh - mloww
         mloww = mloww + 1
         nsize = mtri*nx
         call vclr(qq,1,nsize)
c
c     read in a core load
c     ------------------------------------------------------------
         mkk = mark(ibuck)
 40      if (mkk.eq.maxb) then
c     -----------------------------------------------------------
c
            map = 0
c
c     start loop over triangles (ij/ )
c     ----------------------------------------------------------
c
            do 110 itri = 1 , mtri
               do 50 i = 1 , nx
                  if (qq(map+i).ne.0.0d0) go to 60
 50            continue
               go to 100
c
c     symmetry of <ij/
c
 60            nirrij = mult(nirr(indxi),nirr(indxj))
c
c
               lfirst = indxi
               llast = nsa4
               lrange = llast - lfirst + 1
               kfirst = 1
               klast = nsa4
c
c     -----------------------------------------------------------
c
c     expand to square
c
               call square(sq,qq(map+1),num,num)
c
               n = lrange*num
               call vclr(x,1,n)
c
c    --------------------------------------------------------------
c     loop over l to give <ij/rl> where l has smaller
c     of two ranges
c
               ilf = ilifq(lfirst) + 1
               call mxmb(sq,1,num,q(ilf),1,num,x,1,num,num,num,lrange)
c     -----------------------------------------------------------
c
c     loop over other index k
c
c
               do 90 k = kfirst , klast
                  lmax = nsa4
                  lmin = k
                  if (k.lt.lfirst) lmin = indxi
                  if (k.lt.indxj) lmin = indxi + 1
                  lrange = lmax - lmin + 1
c
c     ------------------------------------------------------------
c
                  do 70 l = lmin , lmax
                     sq(l) = 0.0d0
 70               continue
                  call mxmb(x(ilifq(lmin-lfirst+1)+1),num,1,
     +                      q(ilifq(k)+1),1,num,sq(lmin),1,lrange,
     +                      lrange,num,1)
c
c    ------------------------------------------------------------
c
                  do 80 l = lmin , lmax
c
c     reject symmetry and numerical zeros
c
                     if (mult(nirr(k),nirr(l)).eq.nirrij) then
                        top = sq(l)
                        if (dabs(top).ge.acc1) then
c
c     ----------------------------------------------------------
c
                           mword = mword + 1
                           gout(mword) = top
                           if1 = indxi
                           jf1 = indxj
                           kf1 = max(k,l)
                           lf1 = min(k,l)
                           if (kf1.gt.if1 .or.
     +                         (kf1.eq.if1 .and. lf1.gt.jf1)) then
                              isv = if1
                              if1 = kf1
                              kf1 = isv
                              isv = jf1
                              jf1 = lf1
                              lf1 = isv
                           end if
_IFN1(iv)                           iw2 = mword + mword
_IFN1(iv)                           mwcray(iw2-1) = jf1 + i4096(if1)
_IFN1(iv)                           mwcray(iw2) = lf1 + i4096(kf1)
_IF1(iv)                           mwcray(mword) = jf1 + i4096(if1)
_IF1(iv)                           kbcray(mword) = lf1 + i4096(kf1)
                           if (odebug(11)) write(iwr,*) 'calc2 output',
     +                         if1 , jf1 , kf1 , lf1 , top
                           if (mword.eq.nintmx) call indbls()
                        end if
                     end if
 80               continue
c     end of l loop
 90            continue
c     end of k loop
 100           indxj = indxj + 1
               if (indxj.gt.indxi) then
                  indxi = indxi + 1
                  indxj = 1
               end if
               map = map + nx
 110        continue
            mloww = mhigh
         else
            iblock = mkk
            call rdbak(iblock)
            call stopbk
            call transc(qq)
            go to 40
         end if
 120  continue
c
c     end of loop over triangles <ij/
c
      if (mword.ge.1) call indbls()
      return
      end
      subroutine indx2c(q,sq,x,qq)
c
c    second half of transformation
c    (ij/rs) to (ij/kl)
c
      implicit REAL  (a-h,o-z)
      dimension q(*),x(*),qq(*),sq(*)
      logical lxx,lxo
INCLUDE(common/sizes)
c
INCLUDE(common/cigrad)
      logical lxoxxa, lxoxxb, lumkk4
INCLUDE(common/uhfspn)
INCLUDE(common/infoa)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/prnprn)
INCLUDE(common/mapper)
c
      common/junke/maxt,ires,ipass,
     +  nteff,npass1,npass2,lentri,
     +  nbuck,mloww,mhi,ntri,iacc
      common/bufb/nkk,mkk,gin(1)
      common/blkin/gout(510),mword
      common/out/gxoxx(510),mwordz
_IF(ibm,vax)
      common/craypk/mwcray(340),kbcray(340)
      common/sortpk/nwcray(340),lbcray(340)
_ELSE
      common/craypk/mwcray(680)
      common/sortpk/nwcray(680)
_ENDIF
c
INCLUDE(common/three)
INCLUDE(common/vectrn)
INCLUDE(common/atmblk)
      common/symmos/imos(8,maxorb),ibasis(8,maxorb),nt,nt2,itable(8,8),
     1mult(8,8),nirr(maxorb),imosb(8,maxorb),nirrb(maxorb)
      character *8 open
      logical exist,uhf
      data maxb/999999/
      data open/'open'/
      uhf = scftyp.eq.open
      call setsto(680,0,mwcray)
      call setsto(680,0,nwcray)
c
c     read in orbitals
c   ----------------------------------------------------
      nblkq = num*ncoorb
      call secloc(isecvv,exist,iblkq)
      iblkq = iblkq + mvadd
      call rdedx(sq,nblkq,iblkq,ifild)
      do 30 i = 1 , nsa4
         j = ilifm(i)
         k = ilifq(i)
         do 20 l = 1 , num
            q(k+l) = sq(j+l)
 20      continue
 30   continue
c    ---------------------------------------
c
      acc1 = 10.0d0**(-iacc)
      noc1 = noccb + 1
      if (uhf .and. isecvv.eq.isect(8)) noc1 = nocca + 1
      lxoxxa = ispin.eq.0 .and. isecvv.eq.isect(11) .and. uhf
      lxoxxb = ispin.eq.1 .and. isecvv.eq.isect(8) .and. uhf
      lumkk4 = uhf .and. iscftp.eq.4
c
c      scan  sort  file
c   -----------------------------------------------
      mword = 0
      mwordz = 0
      call stopbk
      do 120 ibuck = 1 , nbuck
         mhigh = mloww + ntri
         if (mhigh.gt.mhi) mhigh = mhi
         mtri = mhigh - mloww
         mloww = mloww + 1
         nsize = mtri*nx
         call vclr(qq,1,nsize)
c
c...   read in a core load
c     -------------------------------------------
         mkk = mark(ibuck)
 40      if (mkk.eq.maxb) then
c      ---------------------------------------
c
            map = 0
c
c    start loop over triangles (ij/ )
c     --------------------------------------------
c
            do 110 itri = 1 , mtri
               do 50 i = 1 , nx
                  if (qq(map+i).ne.0.0d0) go to 60
 50            continue
               go to 100
c
c     symmetry of <ij/
c
 60            if (uhf .and. ispin.eq.1) then
                  nirrij = mult(nirrb(indxi),nirrb(indxj))
               else
                  nirrij = mult(nirr(indxi),nirr(indxj))
               end if
c
c    restriction on ranges of loops
c    -----------------------------------------------
c    iscftp=0 : no restriction
c    iscftp=1 : <vo/vo> only
c    iscftp=2 : <vo/vo> and <vv/oo>
c    iscftp=3 : <vo/vo>,<vv/oo>,<vo/oo>,<oo/oo>
c    iscftp=4 :  not  <vv/vv>
c
c    if iscftp=1 calc1 stage has produced <vo/rs>
c    if iscftp=2,3,or 4 calc1 produced <vo/rs> and <oo/rs>
c    from <oo/rs> produce <oo/vv> if iscftp=2
c    from <oo/rs> produce <oo/oo>,<oo/vo> and <oo/vv> if
c     iscftp=0,3 or 4
c    from <vo/rs> produce <vo/vo> if iscftp=1 ,2 or 3
c    from <vo/rs> produce <vo/vo> and <vo/vv> if iscftp=0 or 4
c
               lxx = iscftp.eq.2 .and. (indxi.le.noccb) .and. 
     +               (indxj.le.noccb)
               lxo = iscftp.ne.99 .and. (indxi.gt.noccb) .and.
     +               (indxj.le.noccb)
               if (iscftp.eq.5) lxo = .false.
               if (uhf .and. ispin.eq.0) lxo = iscftp.ne.99 .and.
     +             indxi.gt.nocca .and. indxj.le.nocca
               lfirst = indxi
               if (lxo) lfirst = 1
               if (lxx .or. (lxo .and. iscftp.eq.4)) lfirst = noc1
               if (iscftp.eq.5 .and. indxi.gt.nupact .and. 
     +                             indxj.le.nupact)
     +             lfirst = nupact + 1
               if (lumkk4) then
                  lfirst = indxi
                  if (indxi.ge.noc1) lfirst = noc1
               end if
               llast = nsa4
               if (lxo .and. iscftp.ne.4) llast = noccb
               if (lxo .and. iscftp.ne.4 .and. uhf .and. 
     +             isecvv.eq.isect(8)) llast = nocca
               lrange = llast - lfirst + 1
               kfirst = 1
               if (lxx) kfirst = noc1
               if (lxo .and. iscftp.ne.4) kfirst = indxi
               if (lxo .and. iscftp.ne.4 .and. lxoxxb .and. 
     +                                       indxi.le.nocca)
     +             kfirst = nocca + 1
               klast = nsa4
c
c     -------------------------------------------
c
c     expand to square
c
               call square(sq,qq(map+1),num,num)
c
               n = lrange*num
               call vclr(x,1,n)
c
c    -----------------------------------------------
c     loop over l to give <ij/rl> where l has smaller
c     of two ranges
c
               ilf = ilifq(lfirst) + 1
               call mxmb(sq,1,num,q(ilf),1,num,x,1,num,num,num,lrange)
c     ---------------------------------------------
c
c     loop over other index k
c
c
               do 90 k = kfirst , klast
                  if (lxo .and. iscftp.ne.4) then
                     lmin = 1
                     if (k.eq.indxi .and. lxoxxa .and. indxj.gt.noccb)
     +                   go to 90
                     if (k.eq.indxi) lmin = indxj
                     lmax = noccb
                     if (uhf .and. isecvv.eq.isect(8)) lmax = nocca
                  else
                     lmax = nsa4
                     lmin = k
                     if (k.lt.lfirst) lmin = indxi
                     if (k.lt.indxj) lmin = indxi + 1
                     if (lumkk4 .and. k.ge.noc1) lmin = k
                     if (lmin.gt.lmax) go to 90
                  end if
c
                  lrange = lmax - lmin + 1
c
c     ------------------------------
c
                  do 70 l = lmin , lmax
                     sq(l) = 0.0d0
 70               continue
                  call mxmb(x(ilifq(lmin-lfirst+1)+1),num,1,
     +                      q(ilifq(k)+1),1,num,sq(lmin),1,lrange,
     +                      lrange,num,1)
c
c    --------------------------------------------
c
                  do 80 l = lmin , lmax
c
c     reject symmetry and numerical zeros
c
                     if (.not.((.not.uhf .or. isecvv.eq.isect(8)) .and.
     +                   mult(nirr(k),nirr(l)).ne.nirrij)) then
                        if (.not.(uhf .and. isecvv.eq.isect(11) .and.
     +                      mult(nirrb(k),nirrb(l)).ne.nirrij)) then
                           top = sq(l)
                           if (dabs(top).ge.acc1) then
c
c    -----------------------------------
c
                              if1 = indxi
                              jf1 = indxj
                              kf1 = max(k,l)
                              lf1 = min(k,l)
                              if ((.not.((lxoxxa.or.lxoxxb) .and. 
     +                              iscftp.eq.4)) .or.
     +                            (kf1.gt.if1 .or. (kf1.eq.if1 .and.
     +                            lf1.ge.jf1))) then
                                 mword = mword + 1
                                 gout(mword) = top
_IFN1(iv)                                 iw2 = mword + mword
                                 if ((kf1.gt.if1 .or. (kf1.eq.if1 .and.
     +                               lf1.ge.jf1))) then
                                    isv = if1
                                    if1 = kf1
                                    kf1 = isv
                                    isv = jf1
                                    jf1 = lf1
                                    lf1 = isv
                                 end if
_IFN1(iv)                                 mwcray(iw2-1) = jf1 + i4096(if1)
_IFN1(iv)                                 mwcray(iw2) = lf1 + i4096(kf1)
_IF1(iv)                                 mwcray(mword) = jf1 + i4096(if1)
_IF1(iv)                                 kbcray(mword) = lf1 + i4096(kf1)
                                 if (odebug(11)) write(iwr,*)
     +                               'calc2 output' , if1 , jf1 , kf1 ,
     +                               lf1 , top
                                 if (mword.eq.nintmx) call indbls()
                              else
                                 if (lxoxxa) ixoxxa = 1
                                 if (lxoxxb) ixoxxb = 1
                                 mwordz = mwordz + 1
                                 gxoxx(mwordz) = top
_IFN1(iv)                                 iw2z = mwordz + mwordz
_IFN1(iv)                                 nwcray(iw2z-1) = jf1 + i4096(if1)
_IFN1(iv)                                 nwcray(iw2z) = lf1 + i4096(kf1)
_IF1(iv)                                 nwcray(mwordz) = jf1 + i4096(if1)
_IF1(iv)                                 lbcray(mwordz) = lf1 + i4096(kf1)
                                 if (odebug(11)) write(iwr,*)
     +                               ' calc2 extra output ' , if1 ,
     +                               jf1 , kf1 , lf1 , top
                                 if (mwordz.eq.nintmx) call indblt()
                              end if
                           end if
                        end if
                     end if
 80               continue
c     end of l loop
 90            continue
c      end of k loop
 100           indxj = indxj + 1
               if (indxj.gt.indxi) then
                  indxi = indxi + 1
                  indxj = 1
               end if
               map = map + nx
 110        continue
            mloww = mhigh
         else
            iblock = mkk
            call rdbak(iblock)
            call stopbk
            call transc(qq)
            go to 40
         end if
 120  continue
c
c     end of loop over triangles <ij/
c
      if (mword.ge.1) call indbls()
      if (uhf .and. mwordz.ge.1) call indblt()
      return
      end
      subroutine indx41(buf,lbuf,map,triag,
     +    vec,naos,nmos,aiqrs,ntriao,aijrs,aijks,w,
     +    ifirst,ilast,ibatch,idim,ifilao,ifilmo,lcanon,cutoff)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/restar)
      logical last,lcanon
      dimension vec(naos,nmos),aiqrs(ntriao,naos,idim),aijrs(ntriao),
     &   aijks(naos),w(naos,naos),buf(lbuf),map(ntriao),triag(ntriao)
      parameter (maxint=3400)
      common/scra/val(maxint),li(maxint),lj(maxint),lk(maxint),
     &  ll(maxint),lij(maxint),lkl(maxint)
      common/outgo/vout(510),nout
_IFN1(iv)      common/sortpk/labs(1360)
_IF1(iv)      common/sortpk/labs(340),labkl(340)
      common/craypk/kbcray(1360)
INCLUDE(common/mapper)
      character *8 groupy
      common/indsyx/groupy
      common/indsym/nrep,itable(8,8),irep(maxorb)
      data m1/1/
c
c      4-index transformation for large memory machines.
c
c      requires approx (n*(n+1)*(n+1))/2 + 2*n*n + n storage
c
c      this version for full transformation
c
c
c     begin transformation for m.o.s in batch ifirst to ilast
c     zero out storage
_IF1(c)cdir$  list
_IF1(c)cdir$  novector
c
      call setsto(1360,0,kbcray)
c
      if1 = ifirst - 1
      irlen = nintmx
      call vclr(aiqrs,1,idim*naos*ntriao)
      inbrel = -1
      call search(m1,ifilao)
c
c     read batch of integrals
c
      if (lcanon) then
c  >>>>>>>>>>>>>>>  canonical list  <<<<<<<<<<<<<<<<<
         kij = 0
         do 50 ki = 1 , naos
            do 40 kj = 1 , ki
               kij = kij + 1
               call cangt1(buf,buf,lbuf,inbrel,map,nzero,triag,ifilao)
c-------------------------------------------------------------
               if (map(nzero).eq.kij) triag(nzero) = triag(nzero)*0.5d0
               call vclr(aijrs,1,ntriao)
_IF1(c)ccdir$ ivdep
_IF1(t)cdir$ ivdep
_IF1(a)cvd$  nodepck
_IF1(x)c$dir no_recurrence
               do 20 i = 1 , nzero
                  aijrs(map(i)) = triag(i)
 20            continue
               call square(w,aijrs,naos,naos)
c
               call mxmb(w,1,naos,vec(1,ifirst),1,naos,aiqrs(kij,1,1),
     +                   ntriao,ntriao*naos,ki,ki,ibatch)
c
c
               do 30 i = 1 , ibatch
                  if (vec(ki,i+if1).ne.0.0d0)
_IFN1(c)     +                call daxpyi(nzero,vec(ki,i+if1),triag,map,
_IFN1(c)     +                aiqrs(1,kj,i))
_IF1(c)     +                call spaxpy(nzero,vec(ki,i+if1),triag,
_IF1(c)     +                aiqrs(1,kj,i),map)
                  if ((vec(kj,i+if1).ne.0.0d0) .and. ki.ne.kj)
_IFN1(c)     +                call daxpyi(nzero,vec(kj,i+if1),triag,map,
_IFN1(c)     +                            aiqrs(1,ki,i))
_IF1(c)     +                call spaxpy(nzero,vec(kj,i+if1),triag,
_IF1(c)     +                            aiqrs(1,ki,i),map)
 30            continue
 40         continue
 50      continue
c
      else
c
c ------------- not canonical list --------------------------
 60      call indblm(nint,val,li,lj,lk,ll,ifilao,last)
         do 70 n = 1 , nint
            lij(n) = iky(li(n)) + lj(n)
            lkl(n) = iky(lk(n)) + ll(n)
 70      continue
         do 80 n = 1 , nint
            if (lij(n).eq.lkl(n)) val(n) = val(n)*0.5d0
 80      continue
         if (ibatch.le.9) then
_IF1(x)c$dir scalar
            do 110 i = 1 , ibatch
               do 90 n = 1 , nint
                  temp = aiqrs(lkl(n),lj(n),i) + val(n)*vec(li(n),i+if1)
                  aiqrs(lkl(n),li(n),i) = aiqrs(lkl(n),li(n),i) + val(n)
     +               *vec(lj(n),i+if1)
                  aiqrs(lkl(n),lj(n),i) = temp
 90            continue
               do 100 n = 1 , nint
                  temp = aiqrs(lij(n),ll(n),i) + val(n)*vec(lk(n),i+if1)
                  aiqrs(lij(n),lk(n),i) = aiqrs(lij(n),lk(n),i) + val(n)
     +               *vec(ll(n),i+if1)
                  aiqrs(lij(n),ll(n),i) = temp
 100           continue
 110        continue
         else
            do 130 n = 1 , nint
               do 120 i = 1 , ibatch
                  temp = aiqrs(lkl(n),lj(n),i) + val(n)*vec(li(n),i+if1)
                  aiqrs(lkl(n),li(n),i) = aiqrs(lkl(n),li(n),i) + val(n)
     +               *vec(lj(n),i+if1)
                  aiqrs(lkl(n),lj(n),i) = temp
 120           continue
 130        continue
            do 150 n = 1 , nint
               do 140 i = 1 , ibatch
                  temp = aiqrs(lij(n),ll(n),i) + val(n)*vec(lk(n),i+if1)
                  aiqrs(lij(n),lk(n),i) = aiqrs(lij(n),lk(n),i) + val(n)
     +               *vec(ll(n),i+if1)
                  aiqrs(lij(n),ll(n),i) = temp
 140           continue
 150        continue
         end if
         if (.not.last) go to 60
      end if
c----------------------------------------------------------
c
c     have now read a.o. integrals and made (iq/rs)
c
c     now for second quarter transformation
c     this is now simple matrix * vector
c
      do 190 i = ifirst , ilast
         ib = i - if1
         do 180 j = 1 , i
            ijsym = itable(irep(i),irep(j))
            call vclr(aijrs,1,ntriao)
            call mxmb(aiqrs(1,1,ib),1,ntriao,vec(1,j),1,1,aijrs,1,
     +                ntriao,ntriao,naos,1)
c
c     third quarter
c
            call squr(aijrs,w,naos)
            do 170 k = 1 , i
               ijksym = itable(ijsym,irep(k))
               call vclr(aijks,1,naos)
               call mxmb(w,1,naos,vec(1,k),1,1,aijks,1,naos,naos,naos,1)
c
c     fourth quarter
c
               lmax = k
               if (i.eq.k) lmax = j
               do 160 l = 1 , lmax
                  if (ijksym.eq.irep(l)) then
                     ans = ddot(naos,aijks,1,vec(1,l),1)
                     if (dabs(ans).ge.cutoff) then
                        nout = nout + 1
                        vout(nout) = ans
_IFN1(iv)                        n2 = nout + nout
_IFN1(iv)                        labs(n2-1) = j + i4096(i)
_IFN1(iv)                        labs(n2) = l + i4096(k)
_IF1(iv)                        labs (nout) = j + i4096(i)
_IF1(iv)                        labkl(nout) = l + i4096(k)
                        if (nout.eq.irlen) then
                           call indblo(nout,vout,labs,ifilmo)
                           nout = 0
                        end if
                     end if
                  end if
 160           continue
 170        continue
 180     continue
 190  continue
_IF1(c)cdir$  nolist
_IF1(c)cdir$  vector
      return
      end
      subroutine indxdm(iphase,ipass,npass,jbl,jun)
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
      common/blkin/gout(511)
INCLUDE(common/timez)
      character*10 charwall
      data m0,m2/0,2/
      if (ipass.eq.npass) then
         call search(jbl,jun)
         call put(gout,m0,jun)
         if (iphase.eq.1) mblk(nfiles) = jblkas
         if (iphase.eq.2) nblk(nfilef) = jblkaf
         if (iphase.eq.1) nnfile = nfiles
         if (iphase.eq.2) mmfile = nfilef
      end if
      call revise
      call timit(3)
      call clredx
      if (nprint.ne.-5) 
     + write (iwr,6010) iphase , ipass , tim, charwall()
      if (ipass.eq.npass .and. iphase.eq.m2) return
      if ((tx*1.5d0).lt.(timlim-tim)) return
      irest1 = 1
      call revise
      call clenms('*** 4-index incomplete - please restart ***')
 6010 format (/
     +  1x,'job dumped in sort',i1,' pass',i6,' at ',f8.2,
     +     ' seconds',a10,' wall')
      end
      subroutine indblm(n,a,i,j,k,l,ifil,last)
      implicit REAL  (a-h,o-z)
      logical last
      dimension a(*),i(*),j(*),k(*),l(*)
      n = 0
      m = 1
      do 20 loop = 1 , 10
         call indbli(n1,a(m),i(m),j(m),k(m),l(m),ifil,last)
         if (last) go to 30
         m = m + n1
         n = n + n1
 20   continue
 30   return
      end
      subroutine indblo(n,a,labs,ifil)
      implicit REAL  (a-h,o-z)
      dimension a(*),labs(*)
INCLUDE(common/atmblk)
      common/outgo/gout(510),nint
      data m0/0/
c
c     Redundant copy
c     if (n.gt.0) then
c      call dcopy(n,a,1,gout,1)
c     endif
_IFN1(iv)      call pack(gout(num2ep+1),lab1632,labs,numlabp)
_IF1(iv)      call pak4v(labs,gout(num2ep+1))
      nint = n
      len = m511
      if (n.eq.0) len = m0
      call put(gout,len,ifil)
      return
      end
      subroutine indx2t(q)
c---------------------------------------------------------------
c     various one-electron transformations
c---------------------------------------------------------------
      implicit REAL  (a-h,o-z)
      logical lint
      character *8 crap,closed,grhf
INCLUDE(common/sizes)
      dimension crap(12),mst(12)
      common/blkin/g(510),nword
INCLUDE(common/cigrad)
      common/junke/ijunk(12),iontrn
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/mapper)
c
      common/small/y(maxorb),occ(maxorb)
INCLUDE(common/vectrn)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/symtry)
c
      common/scfblk/en
      common/maxlen/maxq
INCLUDE(common/atmblk)
INCLUDE(common/prnprn)
INCLUDE(common/zorac)
cjvl     re zora cf. corbld
      dimension q(*)
      data grhf/'grhf'/
      data closed/'closed'/
      data mmat/12/
      data mst/19,20,21,22,23,24,25,26,27,28,29,30/
      data crap/'fock','s','t+v','x','y','z','xx','yy','zz',
     1'xy','xz','yz'/
      call check_feature('indx2t')
c
c             transformation of one-electron integrals
c
      if (ionsv.eq.0) then
         write (iwr,6040)
         if (odebug(11)) write (iwr,6050) ionsv, irest
         return
      end if
      ionsv = 0
c
      if (ladapt) then
         mst(2) = 5
         mst(3) = 6
c
c  beware
c
         iontrn = 0
         ionsv = 0
      else
         mst(2) = 20
         mst(3) = 21
      end if
      lint = .false.
      lenblk = lensec(nx)
      do 20 i = 1 , 6
         if (itwo(i).gt.0) then
            call qmmo(q)
            go to 30
         end if
 20   continue
 30   i1 = num*num + 1
      i2 = i1 + nx
      i3 = i2 + nx
      i4 = i3 + nx
      i5 = i4 + nx
      i6 = i5 + num
      if ((i6+nw196(5)).gt.maxq) call caserr(
     +   'insufficient core for 2-index transformation')
c
c     read the eigenvectors into q(1)
c
      nblkq = num*ncoorb
      call secget(isecvv,itypvv,iblkq)
      call rdedx(q(1),nblkq,iblkq+mvadd,ifild)
c
c     loop over possible 1-electron integrals
c
_IF(secd_parallel)
c     avoid explicit use of 2-electron list in parallel
c     second derivatives (closed shell only)
      do 240 imat = 2 , mmat
_ELSE
      do 240 imat = 1 , mmat
_ENDIF
         if (ione(imat).le.0) go to 240
         go to (50,40,50,70,70,70,60,60,60,60,60,60) , imat
c
c     get overlap matrix
c
 40      call secget(isect(5),5,iblok)
         call rdedx(q(i2),nx,iblok,ifild)
         go to 120
c
c     get 1-electron hamiltonian
c
 50      call secget(isect(6),6,iblok)
         call rdedx(q(i2),nx,iblok,ifild)
c...    fock and t+v
      if (ozora) call zora(q,q(i1),q(i2),'read1')
c
         go to 120
c
c     get elements of quadrupole previously placed on
c     scratchfile by call of qtran
c
 60      iblkss = iblks + (imat-7)*lenblk
         call rdedx(q(i2),nx,iblkss,ifils)
         go to 120
c
c     dipole moment integrals
c
 70      if (.not.lint) call dmints(q(i2),q(i3),q(i4))
         lint = .true.
         go to (120,120,120,120,80,100) , imat
 80      do 90 i = 1 , nx
            q(i2+i-1) = q(i3+i-1)
 90      continue
         go to 120
 100     do 110 i = 1 , nx
            q(i2+i-1) = q(i4+i-1)
 110     continue
c
 120     if (imat.ne.1) go to 200
c
c     fock matrix to be calculated , so get density matrix
c     and put in q(i1)
c
         if (ione(1).eq.2) then
c
c     construct density matrix over active mo's only
c
            en = enucf(nat,czan,c)
            write (iwr,6010) ncore , en
            call secget(isect(13),13,iblok)
            call wrt3(en,lds(isect(13)),iblok,ifild)
            if (ncore.eq.0) go to 200
             if(odebug(11)) then
              write(iwr,*) ' ncore,ncoorb,nsa ',ncore,ncoorb,nsa4
             endif
            do 130 i = 1 , ncoorb
               occ(i) = 0.0d0
 130        continue
            do 140 i = 1 , ncore
               occ(i) = 2.0d0
 140        continue
            write (iwr,6010) ncore , en
            call dmtx(q(i1),q(1),occ,iky,nsa4,num,num)
            m = 0
            call secget(isect(13),m,isec13)
            call rdedx(en,lds(isect(13)),isec13,ifild)
         else
            call secget(isect(7),7,iblok)
            call rdedx(q(i1),nx,iblok,ifild)
            if (scftyp.ne.grhf .and. scftyp.ne.closed) then
               call secget(isect(10),10,iblok)
               call rdedx(q(i3),nx,iblok,ifild)
               do 150 i = 1 , nx
                  q(i1+i-1) = q(i1+i-1) + q(i3+i-1)
 150           continue
            end if
         end if
c
c
         do 160 i = 1 , nx
            q(i1+i-1) = 0.5d0*q(i1+i-1)
 160     continue
c
c     total density matrix in q(i1)
c
c     scan 2-electron integrals
c
         do 170 i = 1 , num
            ii = ikyp(i) - 1
            q(i1+ii) = 0.5d0*q(i1+ii)
 170     continue
c
         do 190 i = 1 , jjfile
            iunit = notape(i)
            call search(iblk(i),iunit)
            call find(iunit)
 180        call get(g,m)
            if (m.ne.0) then
               if (o255i) then
                  call sgmata(q(i2),q(i1))
               else
                  call sgmata_255(q(i2),q(i1))
               end if
               call find(iunit)
               go to 180
            end if
 190     continue
         call indxsf(q(i2),q(i1),q(i6),nshell,iky)
c
c     now have molecular orbitals in q(1), matrix to be
c     transformed in q(i2)
c
 200     call qhq1(q(i1),q(1),ilifq,ncoorb,q(i2),iky,num)
c
c     and the result in q(i1)
c
         if (ione(1).eq.2 .and. ncore.ne.0) then
            if (imat.eq.1 .or. imat.eq.3) then
               do 210 n = 1 , ncore
                  en = en + q(i1-1+iky(n+1))
 210           continue
               if (imat.eq.3) write (iwr,6020) en
               call wrt3(en,lds(isect(13)),isec13,ifild)
            end if
         end if
         isec = isect(mst(imat))
         lennew = iky(ncoorb+1)
         lds(isec) = lennew
         call secput(isec,mst(imat),lenblk,iblok)
         call revind
c
c     write transformed integrals into sections 19 thru 30 on
c     dumpfile
c
         lnx = lennew
         if (lcontr) then
            do 230 i = 1 , nsa4
               do 220 j = 1 , i
                  ij = iky(i) + j
                  ijp = iky(i+ncore) + j + ncore
                  q(i1+ij-1) = q(i1+ijp-1)
 220           continue
 230        continue
            lnx = nsa4*(nsa4+1)/2
         end if
         call wrt3(q(i1),lnx,iblok,ifild)
         if (lone(imat).ne.0) then
            write (iwr,6030) crap(imat)
            call prtris(q(i1),ncoorb,iwr)
         end if
 240  continue
c
      call indput(q)
c
      call clredx
c     call timit(1)
      call timit(3)
      return
 6010 format (/1x,'core hamiltonian, ncore =',i6/1x,
     +        'nuclear repulsion energy',f16.8)
 6020 format (/1x,'effective nuclear repulsion',f16.8)
 6030 format (//35x,a4,' matrix over mos'/
     +          35x,'********************'/)
 6040 format (/1x,' **** bypass 2-index transformation ****')
 6050 format (/1x,' ionsv, irest ',2i5)
      end
_EXTRACT(indx4t,hp700,hp800)
_IF(hpux11)
c HP compiler bug JAGae53280
c$HP$ OPTIMIZE ASSUME_NO_PARAMETERS_OVERLAPS OFF
_ENDIF
      subroutine indx4t(q)
c  -------------------------------------------------------
c  4-index transformation
c
c  based on atmol program with modifications to allow for
c  hondo symmetry and various forms of partial transformation
c  -------------------------------------------------------
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common/indsym/nirr
      common/maxlen/maxq
INCLUDE(common/infoa)
c
      character *8 title,scftyp,runtyp,guess,conf,fkder
      character *8 scder,dpder,plder,guesc,rstop,charsp
      common/restrz/title(10),scftyp,runtyp,guess,conf,fkder,
     + scder,dpder,plder,guesc,rstop,charsp(30)
c
      common/restrr/
     + gx,gy,gz,rspace(21),tiny,tit(2),scale,ropt,vibsiz
c
INCLUDE(common/restar)
INCLUDE(common/restrl)
c
      equivalence (ifilm,notape(1)),(iblkm,iblk(1)),(mblkm,lblk(1))
      dimension itwo(6),ltwo(6)
      equivalence (ione(7),itwo(1)),(lone(7),ltwo(1))
      common/restri/jjfile,notape(4),iblk(4),lblk(4),
     +              nnfile,nofile(4),jblk(4),mblk(4),
     +              mmfile,nufile(4),kblk(4),nblk(4),
     +              ione(12),lone(12),
     +              lds(508),isect(508),ldsect(508)
c
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/iofile)
      common/junke/maxt,ires,ipass,
     1nteff,npass1,npass2,lentri,
     2nbuck,mloww,mhi,ntri,iacc
      dimension q(*)
      common/blkin/gout(511)
INCLUDE(common/three)
      common/junk/nwbuck(maxbuc)
     &    ,itx(3400),ktx(3400),gtx(3400)
INCLUDE(common/blksiz)
INCLUDE(common/atmblk)
      common/craypk/labs(1360)
INCLUDE(common/timez)
INCLUDE(common/mapper)
INCLUDE(common/uhfspn)
INCLUDE(common/vectrn)
INCLUDE(common/restrj)
c
      logical uhf
INCLUDE(common/prnprn)
c
      character*10 charwall
      character *8 adapt,open,pz
      data adapt/'adapt'/
      data open/'open'/
      data pz/'optimize'/
      data m1,m2/1,2/

      uhf = scftyp.eq.open
      if (opass6.or.opass11) then
         write (iwr,6010)
         opass6 = .false.
         return
      end if
      if (nsa4.le.0) return
      if (runtyp.eq.adapt .and. nirr.eq.1) return
      call timit(3)
      if (nprint.ne.-5) then
         write (iwr,6020)
         write (iwr,6030) cpulft(1),charwall()
      end if
      lbuf = nsz*512
      incore = num*num*2 + num*nx + nx*2 + num + lbuf + lenint(nx)
      lenb4 = nx
      if (.not.odisc) then
         if (.not.uhf .and. incore.lt.maxq) then
            if (nprint.ne.-5) write (iwr,6040)
            call indx4m(q)
            go to 150
         end if
      end if
c
      if (irest1.eq.0) then
         mblk(1) = 0
         nblk(1) = 0
c
         nfiles = 1
         nfilef = 1
         indxi = 1
         indxj = 1
         master = 0
         junits = nofile(1)
         jblkas = jblk(1)
         jblkrs = jblkas - mblk(1) - 1
         junitf = nufile(1)
         jblkaf = kblk(1)
         jblkrf = jblkaf - nblk(1) - 1
         nocc = nb
         nvirt = ncoorb - nb
         nocca = 0
         noccb = 0
         if (.not.uhf) then
            do 20 i = 1 , nsa4
               j = mapie(i)
               if (j.le.na) nocca = nocca + 1
               if (j.gt.na .and. j.le.nb) noccb = noccb + 1
 20         continue
            noccb = noccb + nocca
            nvirta = nsa4 - noccb
            if (oprn(6) .and. nprint.ne.-5) then
               write (iwr,6050) num , ncoorb , nsa4 , nocc , noccb
            end if
         else
            nsb = nsa4
            do 30 i = 1 , nsb
               j = mapie(i)
               if (j.le.na) nocca = nocca + 1
               if (j.le.nb) noccb = noccb + 1
 30         continue
            nvirta = nsa4 - nocca
            nvirtb = nsb - noccb
            if (oprn(6) .and. nprint.ne.-5) then
               write (iwr,6060) num , ncoorb , nsa4 , nsb , nocca , 
     +                            noccb
            end if
         end if
         if (iscftp.eq.0) iscftp = 99
         if (nprint.ne.-5) then
            if (iscftp.eq.1) write (iwr,6070)
            if (iscftp.eq.2) write (iwr,6080)
            if (iscftp.eq.3) write (iwr,6100)
            if (iscftp.eq.4 .or. iscftp.eq.5) write (iwr,6090)
            if (iscftp.eq.99) write (iwr,6110)
         end if
      end if
      call setbfa
      nword = 0
      kword = 0
      do 40 ibuck = 1 , maxbuc
         ibase(ibuck) = nword
         ibasen(ibuck) = kword
         nword = nword + nsz340
         kword = kword + nsz680
 40   continue
c     nblkq = num*ncoorb
      num1 = num*nsa4
      num2 = num1 + num*num
      niqq = num2 + num1
c     maxt = max. no. of triangles in core
      maxt = (lword4-niqq)/nx
c      nword=(lword4*2)/3
c      nword=(nword/2)*2
_IF(ibm,vax)
      nword = lword4/3
      nword = (nword/3)*3
      nword2 = nword
_ELSE
      if(o255i) then
       nword = lword4/3
       nword = (nword/3)*3
       nword2 = nword
      else
       nword = lword4/2
       nword = (nword/2)*2
       nword2 = nword
      endif
_ENDIF
c     ires = max. no. of buckets
      ires = nword/nsz340
      if (ires.lt.1 .or. maxt.lt.1)
     +    call caserr(' insufficient core for transformation ')
      if (ires.gt.maxbuc) ires = maxbuc
c
c     ------------------------------------------------
c            first sort / calc stage
c
      if (master.ne.nx) then
c...   determine min. no. of passes for sort1c/calc1c
         i = nx - master - 1
         npass1 = max(nps1,1)
 50      nteff = i/npass1 + 1
         if (((nteff-1)/ires).lt.maxt) then
            if (npass1.gt.i) npass1 = i + 1
            if (oprn(6) .and. nprint.ne.-5) write (iwr,6120) m1 , npass1
c
c   uhf transformation
c
            if (uhf) then
               npassm = npass1
c      write(iwr,9000)
c9000  format(1x,'  uhf 4-index transformation ')
               iumpbl = 0
               call setsto(1360,0,labs)
               do 70 ipass = 1 , npass1
                  call indx1s(q,q(nword+1))
                  isecvv = isect(8)
                  do 60 inr = 1 , 2
                     iumpbl = iumpbl + 1
                     intblk(iumpbl) = jblkas
                     call indx1c(q,q(num1+1),q(num2+1),q(niqq+1))
                     call indxdm(m1,ipass,npass1,jblkas,junits)
                     isecvv = isect(11)
                     jblkas = jblkas + 1
                     master = 0
                     mloww = master
                     mhi = master + nteff
                     if (mhi.gt.nx) mhi = nx
 60               continue
 70            continue
            else
               do 80 ipass = 1 , npass1
                  call setsto(1360,0,labs)
                  call indx1s(q,q(nword+1))
                  if (.not.ladapt) then
                     call indx1c(q,q(num1+1),q(num2+1),q(niqq+1))
                  else
                     call indx1a(q,q(num1+1),q(num2+1),q(niqq+1))
                  end if
                  call indxdm(m1,ipass,npass1,jblkas,junits)
 80            continue
            end if
         else
            npass1 = npass1 + 1
            go to 50
         end if
      end if
c
c   ------------------------------------------------------
c          second sort / calc stage
c
      if (indxi.le.nsa4) then
         if ((nufile(1).eq.ifilm) .and. (nufile(1).ne.nofile(1)))
     +       call delfil(ifilm)
         if (runtyp.eq.pz .and. ifilm.ne.nufile(1) .and.
     +       ifilm.ne.nofile(1) .and. uhf) call delfil(ifilm)
         call closbf(0)
         call setbfa
         nnfile = nfiles
         lentri = iky(nsa4+1)
c...   determine min. no. of passes for sort2c/calc2c
         i = lentri - iky(indxi) - indxj
         npass2 = max(nps2,1)
 90      nteff = i/npass2 + 1
         if (((nteff-1)/ires).lt.maxt) then
            if (npass2.gt.i) npass2 = i + 1
            if (oprn(6) .and. nprint.ne.-5) write (iwr,6120) m2 , npass2
            if (uhf) then
c              if (nprint.ne.-5) write (iwr,*)
c    +                                  ' 2nd stage of calc entered '
               isecvv = isect(8)
               ispin = 0
               iblkzz = 1
               iumpbl = 1
               ixoxxa = 0
               ixoxxb = 0
               do 110 ipass = 1 , npass2
                  isecvv = isect(8)
                  jblk(1) = intblk(iumpbl)
                  call indx2s(q,q(nword+1))
                  do 100 inr = 1 , 2
                     mupblk(iumpbl) = jblkaf
                     iumpbl = iumpbl + 1
                     call indx2c(q,q(num1+1),q(num2+1),q(niqq+1))
                     call indxdm(m2,ipass,npass2,jblkaf,junitf)
                     isecvv = isect(11)
                     jblkaf = jblkaf + 1
                     indxi = 1
                     indxj = 1
                     mloww = iky(indxi) + indxj - 1
                     mhi = mloww + nteff
                     if (mhi.gt.lentri) mhi = lentri
 100              continue
 110           continue
               isecvv = isect(8)
               iblkz = iblkzz
               ispin = 1
               do 130 ipass = 1 , npass2
                  isecvv = isect(8)
                  jblk(1) = intblk(iumpbl-(npass2*2-1))
                  call indx2s(q,q(nword+1))
                  do 120 inr = 1 , 2
                     mupblk(iumpbl) = jblkaf
                     iumpbl = iumpbl + 1
                     call indx2c(q,q(num1+1),q(num2+1),q(niqq+1))
                     call indxdm(m2,ipass,npass2,jblkaf,junitf)
                     isecvv = isect(11)
                     jblkaf = jblkaf + 1
                     indxi = 1
                     indxj = 1
                     mloww = iky(indxi) + indxj - 1
                     mhi = mloww + nteff
                     if (mhi.gt.lentri) mhi = lentri
 120              continue
 130           continue
            else
               do 140 ipass = 1 , npass2
                  call indx2s(q,q(nword+1))
                  if (.not.ladapt) then
                     call indx2c(q,q(num1+1),q(num2+1),q(niqq+1))
                  else
                     call indx2a(q,q(num1+1),q(num2+1),q(niqq+1))
                  end if
                  call indxdm(m2,ipass,npass2,jblkaf,junitf)
 140           continue
            end if
         else
            npass2 = npass2 + 1
            go to 90
         end if
      end if
c
c   -----------------------------------------------------------
c
      call timit(3)
      call clredx
      if ((nofile(1).ne.ifilm) .and. (nofile(1).ne.nufile(1)))
     +    call delfil(nofile(1))
      call closbf(0)
      irest1 = 0
      if (oprn(6) .and. nprint.ne.-5) then
         write (iwr,6130)
         call filprn(nfilef,kblk,nblk,nufile)
      end if
      mmfile = nfilef
 150  if (nprint.ne.-5) write (iwr,6140) cpulft(1),charwall()
      m6file = mmfile
      m6tape(m6file) = nufile(mmfile)
      m6blk(m6file) = kblk(mmfile)
      m6last(m6file) = nblk(mmfile) + 1
      return
 6010 format (/1x,' **** bypass 4-index transformation ****')
 6020 format (/1x,104('=')//40x,23('*')/40x,
     +        'integral transformation'/40x,23('*')/)
 6030 format (/1x,'start of 4-index transformation at ',f8.2,' seconds',
     *             a10,' wall')
 6040 format (/1x,'performing in-core transformation')
 6050 format (/1x,'number of basis functions          ',i4/1x,
     +        'number of molecular orbitals       ',i4/1x,
     +        'number of active molecular orbitals',i4/1x,
     +        'number of occupied orbitals        ',i4/1x,
     +        'number of occupied active orbitals ',i4)
 6060 format (/1x,'number of basis functions                 ',i4/1x,
     +        'number of molecular orbitals              ',i4/1x,
     +        'number of active alpha molecular orbitals ',i4/1x,
     +        'number of active beta molecular orbitals  ',i4/1x,
     +        'number of occupied alpha orbitals         ',i4/1x,
     +        'number of occupied beta orbitals          ',i4)
 6070 format (/1x,
     +        'integral subsets limited to <vo/vo> only')
 6080 format (/1x,'integral subsets limited to',
     +        ' <vo/vo> and <vv/oo> only')
 6090 format (/1x,'omit <vv/vv> integral subset')
 6100 format (/1x,'generate <oo/oo>, <vo/oo>, <vv/oo>, and <vo/vo>',
     +            ' integral subsets')
 6110 format (/1x,'all integral subsets to be generated')
 6120 format (/' no. of sort',i1,' passes=',i4)
 6130 format (/' transformed integral files'/1x,26('*'))
 6140 format (/' end of 4-index transformation at ',f8.2,' seconds'
     * ,a10,' wall'/)
      end
      function isort4(itx,ktx,gtri)
      implicit REAL  (a-h,o-z)
      logical usesym
INCLUDE(common/sizes)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
      common/blkin/gin(510),mword
INCLUDE(common/mapper)
INCLUDE(common/atmblk)
      common/junke/maxt,ires,ipass,
     *nteff,npass1,npass2,lentri,
     * nbuck,mloww,mhi,ntri,iacc,usesym
      common/symmos/imos(8,maxorb),ibasis(8,maxorb),nnnt
c
      dimension itx(*),ktx(*),gtri(*)
c
_IFN1(iv)      call unpack(gin(num2e+1),lab816,labs,numlab)
_IF1(iv)      call upak8v(gin(num2e+1),i205)
      n = 0
      do 30 loop = 1 , mword
_IFN1(iv)         iww = (loop+loop) + (loop+loop)
_IF(ibm,vax)
         i = i205(loop)
         j = j205(loop)
         k = k205(loop)
         l = l205(loop)
_ELSEIF(littleendian)
         i = labs(iww-2)
         j = labs(iww-3)
         k = labs(iww  )
         l = labs(iww-1)
_ELSE
         i = labs(iww-3)
         j = labs(iww-2)
         k = labs(iww-1)
         l = labs(iww)
_ENDIF
         itri = iky(i) + j
         ktri = iky(k) + l
         itrim = itri
         ktrim = ktri
         if (mloww.lt.itrim .and. mhi.ge.itrim) then
           iopm = 1
           sign = 1.0d0
           n = n + 1
           itx(n) = itrim
           ktx(n) = ktrim
           gtri(n) = gin(loop)*sign
         endif
         if (ktri.ne.itri) then
c... triangle ktri
            ktrim = ktri
            itrim = itri
            iopm = 1
            sign = 1.0d0
            if (usesym) then
               do 20 iop = 2 , nnnt
                  km = iabs(ibasis(iop,k))
                  lm = iabs(ibasis(iop,l))
                  kti = iky(max(km,lm)) + min(km,lm)
                  if (kti.gt.ktrim) then
                     ktrim = kti
                     iopm = iop
                  end if
 20            continue
               if ((ibasis(iopm,k)*ibasis(iopm,l)).lt.0) sign = -1.0d0
c
c     have found k''l'' with highest triangle index
c
            end if
            if (mloww.lt.ktrim .and. mhi.ge.ktrim) then
               if (iopm.ne.1) then
                  if ((ibasis(iopm,i)*ibasis(iopm,j)).lt.0) sign = -sign
                  im = iabs(ibasis(iopm,i))
                  jm = iabs(ibasis(iopm,j))
                  itrim = iky(max(im,jm)) + min(im,jm)
               end if
               n = n + 1
               itx(n) = ktrim
               ktx(n) = itrim
               gtri(n) = gin(loop)*sign
            end if
         end if
 30   continue
      isort4 = n
      return
      end
_IF(hpux11)
c$HP$ OPTIMIZE ASSUME_NO_PARAMETERS_OVERLAPS ON
_ENDIF
_ENDEXTRACT
      subroutine indprt(nat3,nops,prout,iwr)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      logical prout
      logical skip
      common/symmos/imos(8,maxorb),ibasis(8,maxorb),nt3,nt4,
     & itable(8,8),mult(8,8),nirr(maxorb)
      common/scrtch/
     +    ptr(3,144),dtr(6,288),ftr(10,480),gtr(15,720),
     +    dp(27,maxat),
     +    nunpr,skip(maxat*3),mapnu(maxat*3),mapun(maxat*3),
     +    iperm(maxat*3),
     +    ict(maxat,8),mptr(8,maxat*3),nuniq,nuni1,nuni2,nuni3
c
      if (nops.eq.1) then
         do 20 i = 1 , nat3 - 3
            iperm(i) = 1
            skip(i) = .false.
 20      continue
         skip(nat3-2) = .true.
         skip(nat3-1) = .true.
         skip(nat3) = .true.
         iperm(nat3-2) = 0
         iperm(nat3-1) = 0
         iperm(nat3) = 0
         do 30 i = 1 , nat3
            mapnu(i) = i
            mapun(i) = i
 30      continue
         nuniq = nat3/3
         nunpr = nat3 - 3
         return
      end if
c
c
      do 40 i = 1 , nat3
         iperm(i) = 1
         skip(i) = .false.
 40   continue
c
      nat = nat3/3
      do 60 ip = 1 , nat
         maxpr = ip
         maxiop = 1
         do 50 iop = 1 , nops
            nupr = iabs(ict(ip,iop))
            if (nupr.gt.maxpr) then
               maxpr = nupr
               maxiop = iop
            end if
 50      continue
         if (maxpr.gt.ip) then
            skip(ip*3-2) = .true.
            skip(ip*3-1) = .true.
            skip(ip*3) = .true.
            iperm(ip*3-2) = maxiop
            iperm(ip*3-1) = maxiop
            iperm(ip*3) = maxiop
         end if
 60   continue
c
      if (nuniq.ne.0) then
         nuni1 = nuniq*3 - 2
         nuni2 = nuniq*3 - 1
         nuni3 = nuniq*3
         skip(nuni1) = .true.
         skip(nuni2) = .true.
         skip(nuni3) = .true.
         iperm(nuni1) = 0
         iperm(nuni2) = 0
         iperm(nuni3) = 0
      end if
      ic = 0
      do 70 ix = 1 , nat3
         if (.not.(skip(ix))) then
            ic = ic + 1
            mapnu(ic) = ix
            mapun(ix) = ic
         end if
 70   continue
      nunpr = ic
c
      if (prout) then
         do 80 ip = 1 , nat3
           write(iwr,6010) ip , mapnu(ip) , mapun(ip) , iperm(ip) ,
     +                     (mptr(iop,ip),iop=1,nops)
 80      continue
      end if
      return
 6010 format (1x,12i8)
      end
      subroutine indx4m(q)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/cigrad)
      logical exist
INCLUDE(common/atmblk)
INCLUDE(common/ghfblk)
c
c     geometry information block
c
INCLUDE(common/infoa)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
c
INCLUDE(common/vectrn)
      common/outgo/vout(510),nout
      common/sortpk/labs(1360)
_IF1(iv)      common/craypk/i205(irlen*4)
INCLUDE(common/blksiz)
c
      common/maxlen/maxq
      dimension q(*)
INCLUDE(common/mapper)
INCLUDE(common/prints)
      logical uhf
      character *8 grhf,open
      data grhf/'grhf'/,open/'open'/
      uhf = scftyp.eq.open
c
c     sort integrals into canonical order
c
      if (lcanon) then
        call canonc(q,maxq,num,iblk(1),notape(1),nofile(1),.true.)
         write (iwr,6010)
         call timit(3)
      end if
c
c
      nout = 0
      call setsto(680,0,labs)
_IF1(iv)      call setsto(1360,0,i205)
      isecvv = isect(8)
      itypvv = 8
      mblk(1) = 0
      nblk(1) = 0
c
      cutoff = 10.d0**(-icut)
c
c
      nfiles = 1
      nfilef = 1
      indxi = 1
      indxj = 1
      master = 0
      junits = nofile(1)
      jblkas = jblk(1)
      jblkrs = jblkas - mblk(1) - 1
      junitf = nufile(1)
      jblkaf = kblk(1)
      jblkrf = jblkaf - nblk(1) - 1
      nocc = nb
      nvirt = ncoorb - nb
      nocca = 0
      noccb = 0
      if (.not.uhf) then
         do 20 i = 1 , nsa4
            j = mapie(i)
            if (j.le.na) nocca = nocca + 1
            if (j.gt.na .and. j.le.nb) noccb = noccb + 1
 20      continue
         noccb = noccb + nocca
         nvirta = nsa4 - noccb
         if (oprint(58) .and. nprint.ne.-5) then
            write (iwr,6020) num , ncoorb , nsa4 , nocc , noccb
         end if
      else
         nsb = nsa4
         do 30 i = 1 , nsb
            j = mapie(i)
            if (j.le.na) nocca = nocca + 1
            if (j.le.nb) noccb = noccb + 1
 30      continue
         nvirta = nsa4 - nocca
         nvirtb = nsb - noccb
         if (oprint(58) .and. nprint.ne.-5) then
            write (iwr,6030) num , ncoorb , nsa4 , nsb , nocca , noccb
         end if
      end if
      if (iscftp.eq.0) iscftp = 99
      if (nprint.ne.-5) then
         if (iscftp.eq.1) write (iwr,6040)
         if (iscftp.eq.2) write (iwr,6050)
         if (iscftp.eq.3) write (iwr,6070)
         if (iscftp.eq.4 .or. iscftp.eq.5) write (iwr,6060)
         if (iscftp.eq.99) write (iwr,6080)
      end if
c
      if (scftyp.eq.grhf .and. iscftp.lt.99 .and. .not.lci) then
         nupact = 0
         iscftp = 5
         do 50 k = 1 , njk
            nsi = nbshel(k)
            i = ilfshl(k)
            do 40 m = i + 1 , i + nsi
               nupact = max(nupact,iactiv(m))
 40         continue
 50      continue
         if (nprint.ne.-5) write (iwr,6090) nupact
      end if
c
c     read the eigenvectors
c     --------------------------------------------------------------
c
      nblkq = num*ncoorb
      call secloc(isecvv,exist,iblkq)
      iblkq = iblkq + mvadd
      call rdedx(q(num*num+1),nblkq,iblkq,ifild)
c     now copy only the active m.o's into q.

      do 80 i = 1 , nsa4
         j = ilifq(i)
         k = ilifm(i)
_IF1(ct)cdir$ ivdep
_IF1(a)cvd$  nodepck
_IF1(x)c$dir no_recurrence
         do 60 l = 1 , num
            q(j+l) = q(num*num+k+l)
 60      continue
         do 70 l = 1 , num
            if (dabs(q(j+l)).le.1.0d-15) q(j+l) = 0.0d0
 70      continue
 80   continue
c
      ihigh = nsa4
      if (iscftp.ne.99) ihigh = noccb
      if ((scftyp.eq.grhf .or. lci) .and. iscftp.ne.99) ihigh = nupact
      if (oprint(58) .and. nprint.ne.-5) write (iwr,6100) ihigh
c
      lbuf = nsz*512
c
      maxqq = maxq - num*num*2 - nx*2 - num - lbuf - lenint(nx)
      mbatch = maxqq/(num*nx)
      if (mbatch.lt.1) call caserr('insufficient core')
      mbatch = min(mbatch,ihigh)
      if (oprint(58) .and. nprint.ne.-5) write (iwr,6110) mbatch
      ifirst = 1
      ilast = mbatch
      nloop = ((ihigh-1)/mbatch) + 1
      if (oprint(58) .and. nprint.ne.-5) write (iwr,6120) nloop
      call search(1,nufile(1))
      do 90 loop = 1 , nloop
         mdim = ilast - ifirst + 1
         i1 = 1
         i2 = i1 + num*ncoorb
         i3 = i2 + lenint(nx)
         i4 = i3 + nx
         i5 = i4 + lbuf
         i6 = i5 + num*nx*mdim
         i7 = i6 + nx
         i8 = i7 + num
c
c        itop = i8 + num*num
c
c
         iaofil = notape(1)
         if (lcanon) iaofil = nofile(1)
         if (iscftp.eq.99) then
            call indx41(q(i4),lbuf,q(i2),q(i3),q(i1),num,nsa4,q(i5),nx,
     +  q(i6),q(i7),q(i8),ifirst,ilast,mdim,mdim,iaofil,nufile(1),
     +  lcanon,cutoff)
         else
            call indx40(q(i4),lbuf,q(i2),q(i3),q(i1),num,nsa4,q(i5),nx,
     +  q(i6),q(i7),q(i8),ihigh,iscftp,ifirst,ilast,mdim,mdim,iaofil,
     +  nufile(1),lcanon,cutoff)
         end if
c
         if (ilast.lt.ihigh) then
            ifirst = ilast + 1
            ilast = ilast + mbatch
            ilast = min(ilast,ihigh)
         end if
 90   continue
      if (nout.ne.0) then
         call indblo(nout,vout,labs,nufile(1))
         nout = 0
      end if
      call indblo(nout,vout,labs,nufile(1))
c     call timit(1)
      call timit(3)
      nblk(1) = iposun(nufile(1)) - 1
      call revise
      if (lcanon) call delfil(nofile(1))
      return
 6010 format (/1x,'integrals sorted into canonical order')
 6020 format (/1x,'number of basis functions          ',i4/1x,
     +        'number of molecular orbitals       ',i4/1x,
     +        'number of active molecular orbitals',i4/1x,
     +        'number of occupied orbitals        ',i4/1x,
     +        'number of occupied active orbitals ',i4)
 6030 format (/1x,'number of basis functions                ',i4/1x,
     +        'number of molecular orbitals             ',i4/1x,
     +        'number of active alpha molecular orbitals',i4/1x,
     +        'number of active beta molecular orbitals ',i4/1x,
     +        'number of occupied alpha orbitals        ',i4/1x,
     +        'number of occupied beta orbitals         ',i4)
 6040 format (/1x,
     +        'integral subsets limited to <vo/vo> only')
 6050 format (/1x,'integral subsets limited to',
     +        ' <vo/vo> and <vv/oo> only')
 6060 format (/1x,'omit <vv/vv> integral subset')
 6070 format (/1x,'generate <oo/oo>, <vo/oo>, <vv/oo>, and <vo/vo>',
     +            ' integral subsets')
 6080 format (/1x,'all integral subsets to be generated')
 6090 format (/1x,'highest occupied orbital ',i4)
 6100 format (/1x,'ihigh  =',i5)
 6110 format (/1x,'mbatch = ',i5)
 6120 format (/1x,'nloop  = ',i5)
      end
      subroutine indblc
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/atmblk)
      common/blkin/gout(510),mword
      common/craypk/labout(680)
c
      if (iposun(junits).ne.jblkas) call search(jblkas,junits)
_IFN1(iv)      call pack(gout(num2ep+1),lab1632,labout,numlabp)
_IF1(iv)      call pak4v(labout,gout(num2ep+1))
      call put(gout(1),511,junits)
      mword = 0
      jblkas = jblkas + 1
      jblkrs = jblkrs + 1
      if (jblkrs.eq.0) then
c...   change channel
         call put(gout(1),0,junits)
         mblk(nfiles) = jblkas
         nfiles = nfiles + 1
         if (nfiles.gt.nnfile)
     +       call caserr(' additional part of secfile not defined')
         junits = nofile(nfiles)
         jblkas = jblk(nfiles)
         jblkrs = jblkas - mblk(nfiles)
      end if
      return
      end
      subroutine indbls
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/atmblk)
      common/blkin/gout(510),mword
      common/craypk/labout(680)
c
      if (iposun(junitf).ne.jblkaf) call search(jblkaf,junitf)
_IFN1(iv)      call pack(gout(num2ep+1),lab1632,labout,numlabp)
_IF1(iv)      call pak4v(labout,gout(num2ep+1))
      call put(gout(1),511,junitf)
      mword = 0
      jblkaf = jblkaf + 1
      jblkrf = jblkrf + 1
      if (jblkrf.eq.0) then
         call put(gout(1),0,junitf)
         nblk(nfilef) = jblkaf
         nfilef = nfilef + 1
         if (nfilef.gt.mmfile)
     +       call caserr(' additional part of finalfile not defined')
         junitf = nufile(nfilef)
         jblkaf = kblk(nfilef)
         jblkrf = jblkaf - nblk(nfilef)
      end if
      return
      end
      subroutine indblt
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/atmblk)
      common/out/gout(510),mword
      common/sortpk/labout(1360)
INCLUDE(common/uhfspn)
      data m0/0/
c
      ifilz = 1
      if (iposun(ifilz).ne.iblkzz) call search(iblkzz,ifilz)
      itemp = mword
_IFN1(iv)      call pack(gout(num2ep+1),lab1632,labout,numlabp)
_IF1(iv)      call pak4v(labout,gout(num2ep+1))
      call put(gout(1),m511,ifilz)
      mword = 0
      iblkzz = iblkzz + 1
      if (itemp.lt.num2e) then
         call put(gout(1),m0,ifilz)
         iblkzz = iblkzz + 1
      end if
      return
      end
      subroutine ind4pr(nt,idump,isectr,iout)
c     routine to output transformation matrix.
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
      common/scrtch/
     +    ptr(3,144),dtr(6,288),ftr(10,480),gtr(15,720),
     +    icol(maxorb),it(8,maxorb)
INCLUDE(common/nshel)
      logical iftran
INCLUDE(common/runlab)
      common/blkorbs/evalue(maxorb),occ(maxorb+1),nbasis,newbas,
     1ncol,ivalue,iocc,ipad
      common/small/ilifc(maxorb),ntran(maxorb),itran(600),
     1iftran
      character *8 blank
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/prnprn)
      data blank /' '/
      nbasis = num
      newbas = nbasis
      ncol = nbasis
      do 20 i = 1 , 10
         ztitle(i) = title(i)
 20   continue
      do 30 i = 1 , 5
         zcom(i) = blank
 30   continue
      ivalue = -1
      iocc = -1
      iftran = .true.
      lenwo = lenint(5) + 510
      l29 = 29
      call wrtc(zcom,l29,isectr,idump)
      call wrt3s(evalue,lenwo,idump)
      lenwo = lenint(1113) + 600
      call wrt3s(ilifc,lenwo,idump)
      if (odebug(10)) write (iout,6010)
      ic = 0
      do 70 i = 1 , num
         do 40 j = 1 , num
            icol(j) = 0
 40      continue
         do 50 j = 1 , nt
            ii = it(j,i)
            if (ii.lt.0) then
               icol(-ii) = -1
            else if (ii.ne.0) then
               icol(ii) = 1
            end if
 50      continue
         do 60 j = 1 , num
            ic = ic + 1
            evalue(ic) = icol(j)
            if (ic.ge.511) then
               call put(evalue,ic,idump)
               ic = 0
            end if
 60      continue
         if (odebug(10)) write (iout,6020) i , (icol(j),j=1,num)
 70   continue
      if (ic.gt.0) then
         call put(evalue,ic,idump)
      end if
      call clredx
      call whtps
      return
 6010 format (//5x,'transformation matrix for symmetry orbitals'//)
 6020 format (1x,i2,6x,(25i4))
      end
      subroutine indput(q)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
c
      parameter (mxorb1=maxorb+1)
c
      dimension q(*)
INCLUDE(common/machin)
INCLUDE(common/infoa)
INCLUDE(common/prints)
INCLUDE(common/prnprn)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/tran)
INCLUDE(common/mapper)
INCLUDE(common/restar)
INCLUDE(common/harmon)
      common/craypk/nact,nacta(maxorb),nprina,
     *              mact,macta(maxorb),mprina, ihamp,jdsec
      common/scfblk/en
      common/lsort/pop(maxorb),potn,core,ncol,nbasis,newbas,
     * ncore,mapcie(maxorb),icorec(maxorb),nactiv,mappie(maxorb),
     * ilifn(maxorb),iqsec
      common/atmol3/mina(2),mouta,moutb
INCLUDE(common/runlab)
      common/junkc/zjob,zdate,ztime,zprog,ztype,zspace(14),ztext(10)
      common/junk/
     * evalue(maxorb),eocc(mxorb1),
     * nbasj,newb,ncoll,ivalue,iocc
      common/multic/radius(40),irad(57+mcfzc),itype(maxorb),isecn
      common/restri/jjfile(63),lds(508),isect(508),ldsect(508)
c
      data m29,isecb/29,470/
      data zcas/'mcscf'/
      iscfty = 0
      if (zscftp.eq.zcas) iscfty = 1
      isecv = mouta
      if (moutb.ne.0) isecv = moutb
      if (iscfty.eq.1 .and. isecn.gt.0) isecv = isecn
      nav = lenwrd()
c
c     restore vectors
c
      call secget(isecv,3,iblk)
      call rdchr(zjob,m29,iblk,idaf)
      call reads(evalue,mach(8),idaf)
c     len2 = lensec(mach(9))
c     iblkv = iblk + len2 + lensec(mach(8)) + 1
      if (nbasj.ne.num) call caserr(
     + 'restored eigenvectors are in incorrect format')
      ncol = ncoll
      newbas = newb
      nbasis = nbasj
c
      if (ncol.lt.nsa4) then
c...     ncol may be < nbasis ; mp2 gradients can't handle this
c...     reset this ; we assume the extra vectors are 0.0
c...           **harmonic**
         if (ncol.ne.newbas0) call caserr('illegal ncol in indput ?? ')
         if (num.ne.newbas1) call caserr('illegal num in indput ?? ')
         ncol = num
      end if
c
      if (odebug(11)) then
         write (iwr,6010) isecv , ztype , ztime , zdate , zjob , ztext
      end if
      if (iscfty.ne.1) then
c
         call readis(ilifc,mach(9)*nav,idaf)
         if (.not.(.not.odebug(11) .or. nprint.eq.-5)) then
            write (iwr,6020)
c
            do 30 i = 1 , newbas
               n = ntran(i)
               j = ilifc(i)
               write (iwr,6030) ctran(j+1) , itran(j+1) , n , i
               if (n.ne.1) then
                  do 20 k = 2 , n
                     write (iwr,6030) ctran(j+k) , itran(j+k)
 20               continue
               end if
 30         continue
            write (iwr,6040) newbas
         end if
c
      end if
      iqsec = isecv
      call dcopy(maxorb,eocc,1,pop,1)
c
c     now restore =active= and =core= specifications
c
      call secget(isecb,1005,iblka)
      call readi(nact,mach(14)*nav,iblka,idaf)
c
c     active list
c
      if (nsa4.ne.nact) then
         call caserr('invalid number of active orbitals')
      else
         nactiv = nsa4
         if (nsa4.lt.1) then
            call caserr('invalid number of active orbitals')
         else if (nsa4.eq.1) then
            go to 70
         end if
      end if
 40   if (nsa4.gt.ncol) then
         call caserr('invalid number of active orbitals')
         go to 40
      else
         do 50 i = 2 , nsa4
            if ((locat1(nacta,i-1,nacta(i))).ne.0)
     +          call caserr('invalid orbital specified in active list')
 50      continue
         do 60 i = 1 , nsa4
            j = nacta(i)
            mappie(i) = j
            ilifn(i) = ilifq(j)
 60      continue
      end if
 70   if (odebug(11)) then
         write (iwr,6050)
         write (iwr,6060) (mappie(k),k,k=1,nsa4)
      end if
c
c     frozen list
c
      ncore = mact
      if (ncore.lt.1) then
         if (odebug(11)) write (iwr,6070)
         go to 100
      else if (ncore.ne.1) then
         if (ncore.gt.ncol) call caserr(
     +   'invalid number of functions in core list')
      end if
      do 80 i = 1 , ncore
         j = macta(i)
         mapcie(i) = j
         icorec(i) = ilifq(j)
 80   continue
      if (ncore.gt.1) then
         do 90 i = 2 , ncore
            if ((locat1(mapcie,i-1,mapcie(i))).ne.0) call caserr(
     +          'invalid function specified in frozen core list')
 90      continue
      end if
      if (odebug(11)) then
         write (iwr,6080)
         write (iwr,6060) (mapcie(k),k,k=1,ncore)
      end if
c
 100  if (jdsec.gt.350 .and. jdsec.ne.466) call caserr(
     +    'invalid section specified on onelec/core directive')
c
c ... restore core hamiltonian
c
      call secget(isect(21),21,isec21)
      lnx = nsa4*(nsa4+1)/2
      call rdedx(q,lnx,isec21,idaf)
c
      if (jdsec.lt.1) jdsec = 466
      if (nprint.ne.-5) write (iwr,6090) jdsec
      core = en
      if (nprint.ne.-5) write (iwr,6100) core
      lenact = iky(nsa4+1)
      lenblk = lensec(lenact) + lensec(mach(15))
      call secput(jdsec,1004,lenblk,kblxxx)
      call wrt3(pop,mach(15),kblxxx,idaf)
      call wrt3s(q,lenact,idaf)
      if (odebug(11)) then
         write (iwr,6110)
         call writel(q,nsa4)
      end if
c
      return
 6010 format (/' vectors restored from section ',
     +        i4//' header block information : '/1x,a7,
     +        'vectors created at ',a8,' on ',a8,' in the job ',
     +        a8/' with the title: ',10a8)
 6020 format (/14x,'list of lcbf'/14x,12('*')
     +        //' coefficient old orbital nterm new orbital'/1x,41('-')
     +        /)
 6030 format (f12.7,i12,i6,i12)
 6040 format (/' no. of lcbf = ',i4)
 6050 format (/' the following orbitals included in active list'/
     +        ' =============================================='/5
     +        (' function e/i label',4x)/1x,110('-'))
 6060 format (5(i9,i11,4x))
 6070 format (/' no functions specified in frozen core list')
 6080 format (/' the following mos included in frozen core list'/
     +        ' ----------------------------------------------'/5
     +        (' function e/i label',4x))
 6090 format (/' route transformed core hamiltonian to section ',i4)
 6100 format (/' effective nuclear repulsion term',e21.12)
 6110 format (/1x,104('*')//35x,'core matrix over active mos'/35x,
     +        27('*')/)
      end
      subroutine indpro(q,num,nred,v,s,qnew,ichar,iorb,uhf)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension q(num,nred),v(num,nred),qnew(num,nred),
     &  s(*),ichar(*),vlen(8),irrc(maxorb),iperm(maxorb)
      common/symmos/imos(8,maxorb),ibasis(8,maxorb),nt,nt3,itable(8,8),
     1mult(8,8),irr(maxorb),imosb(8,maxorb),irrb(maxorb)
INCLUDE(common/vectrn)
      logical uhf
      logical easy(maxorb)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
c     uses projection operators to reduce set of vectors
c     in q(num,nred) to nred vectors of character in
c     ichar
c
c     first deal with all those orbitals in the set whose
c     symmetry is easy to determine
      call vclr(qnew,1,num*nred)
      nproj = 0
      do 20 i = 1 , nred
         irrc(i) = 0
         easy(i) = .false.
 20   continue
      nredd = nred
c
c------------------------easy symmetries-----------------
c
      do 60 ired = 1 , nred
c
c     decompose one orbital into symmetry types
c
         call indsyt(num,q(1,ired),v,s,vlen)
c
         do 50 irep = 1 , nt
            if (dabs(vlen(irep)).gt.0.90d0) then
c     orbital is mostly one symmetry type - seems safe!
               nproj = nproj + 1
               nredd = nredd - 1
               ichar(irep) = ichar(irep) - 1
               if (ichar(irep).lt.0) then
                write (iwr,*) ' something wrong with symmetry (case 1)'
                call caserr('error in symmetry specification')
               end if
               easy(ired) = .true.
               irrc(nproj) = irep
               iperm(nproj) = ired
               do 30 k = 1 , num
                  qnew(k,nproj) = v(k,irep)
 30            continue
               do 40 k = 1 , num
                  q(k,ired) = q(k,ired) - v(k,irep)
 40            continue
               go to 60
            end if
 50      continue
 60   continue
      do 80 i = 2 , nproj
         do 70 j = 1 , i - 1
            call vschmv(num,qnew(1,j),qnew(1,i),s)
 70      continue
 80   continue
      do 90 i = 1 , nproj
         over = vsv(num,qnew(1,i),qnew(1,i),s)
         if (over.le.1.0d-6) then
           write (iwr,*) 'very short vector produced end of first stage'
           write (iwr,*) 'nred, nredd, nproj, i ' , nred , nredd ,
     +                 nproj , i
           write (iwr,*) 'overlap ' , over
            call caserr('error in orbital symmetries')
         end if
         call vrenrm(num,qnew(1,nproj),s)
 90   continue
c------------------------------------------------------------------
c
c     are nredd vectors remaining whose symmetry has not been
c     assigned
 100  j = 0
      do 110 i = 1 , nt
         j = j + ichar(i)
 110  continue
      if (j.ne.nredd) then
        write (iwr,*) ' inconsistency between number of orbitals'
        write (iwr,*) ' and character of representation'
        call caserr('error in symmetry determination')
      end if
      if (nredd.eq.0) then
c
c------------------------------finished ?------------------
c
c
         do 130 k = 2 , nproj
            do 120 l = 1 , k - 1
               call vschmv(num,qnew(1,l),qnew(1,k),s)
 120        continue
 130     continue
         do 140 i = 1 , nproj
            over = vsv(num,qnew(1,i),qnew(1,i),s)
            if (over.le.1.0d-6) then
              write (iwr,*) 'very short vector produced at final stage'
              write (iwr,*) 'nred, nredd, nproj, i ' , nred , nredd ,
     +                     nproj , i
              write (iwr,*) 'overlap ' , over
              call caserr('error in symmetry determination')
            end if
            call vrenrm(num,qnew(1,i),s)
 140     continue
c
c-----------------------------------------------------------
c
         if (uhf .and. isecvv.eq.isect(11)) then
            do 170 i = 1 , nred
               irm = iperm(i)
               irrb(iorb+irm-1) = irrc(i)
               do 150 k = 1 , num
                  q(k,irm) = qnew(k,i)
 150           continue
               do 160 k = 1 , nt
                  imosb(k,iorb+irm-1) = itable(irrc(i),k)
 160           continue
 170        continue
         else
            do 200 i = 1 , nred
               irm = iperm(i)
               irr(iorb+irm-1) = irrc(i)
               do 180 k = 1 , num
                  q(k,irm) = qnew(k,i)
 180           continue
               do 190 k = 1 , nt
                  imos(k,iorb+irm-1) = itable(irrc(i),k)
 190           continue
 200        continue
         end if
c
c
c     have completely reduced representation
c     all orbitals have been assigned symmetry type, once and
c     once only, and have been left in an order as close as possible
c     to the original order
c     the orbitals are orthonormal and the projection/orthogonalisation
c     has not produced either a null vector nor the same vector twice
c
         return
      else
c
c---------------------------------------------------------------
_IF1()c      add all the little bits of vectors remaining from
_IF1()c      previous round of projection - in case all little
_IF1()c      bits add up to a whole vector?
_IF1()c      do 198 i=1,nred
_IF1()c      if(easy(i))then
_IF1()c      do 195 j=1,nred
_IF1()c      if(easy(j))then
_IF1()c      vlen(j)=0.0d0
_IF1()c      else
_IF1()c      vlen(j)=vovlp(num,q(1,i),q(1,j),s)
_IF1()c      endif
_IF1()c195   continue
_IF1()c      amm=0.0d0
_IF1()c      irm=0
_IF1()c      do 196 j=1,nred
_IF1()c      if(dabs(vlen(j)).gt.amm)then
_IF1()c      amm=dabs(vlen(j))
_IF1()c      irm=j
_IF1()c      endif
_IF1()c196   continue
_IF1()c      if(irm.ne.0)then
_IF1()c      do 197 j=1,num
_IF1()c      q(j,irm)=q(j,irm)+q(j,i)
_IF1()c197   q(j,i)=0.0d0
_IF1()c      endif
_IF1()c      endif
_IF1()c198   continue
c   orthogonalise those vectors remaining to those
c   projected out already - this should prevent same
c   vector being projected out twice?
         do 220 i = 1 , nred
            if (.not.easy(i)) then
               do 210 j = 1 , nproj
                  call vschmv(num,qnew(1,j),q(1,i),s)
 210           continue
            end if
 220     continue
         do 240 i = 2 , nred
            if (.not.(easy(i))) then
               do 230 j = 1 , i - 1
                  if (.not.easy(j)) call vschmv(num,q(1,j),q(1,i),s)
 230           continue
            end if
 240     continue
c----------------------------------------------------------------
         do 290 irep = 1 , nt
            if (ichar(irep).gt.0) then
c
               call vclr(v,1,num)
               do 260 j = 1 , nred
                  if (.not.easy(j)) then
                     do 250 i = 1 , num
                        v(i,1) = v(i,1) + q(i,j)
 250                 continue
                  end if
 260           continue
               over = vsv(num,v(1,1),v(1,1),s)
               if (over.le.1.0d-6) then
                 write (iwr,*) 'very short vector prior to projection'
                 write (iwr,*) 'overlap ' , over
                 call caserr('error in orbital projection')
               end if
c
c     scheme : start with sum of remaining
c              vectors
c            : project out a vector with a symmetry which is
c              known to be present
c            : loop over all symmetry types
c            : repeat if necessary till have enough vectors
c            : overall algorithm amounts to decomposition of
c              original set into vectors along all symmetry
c              directions, then resummation of these components
c              to give new set of vectors
c
               ichar(irep) = ichar(irep) - 1
               nredd = nredd - 1
               nproj = nproj + 1
               irrc(nproj) = irep
               call indprj(v(1,1),num,qnew(1,nproj),s,irep)
c
c     take overlap of projected vector
c     with original orbitals to see which it resembles
c     most
c
               call vrenrm(num,qnew(1,nproj),s)
               do 270 j = 1 , nred
                  if (easy(j)) then
                     vlen(j) = 0.0d0
                  else
                     vlen(j) = vsv(num,q(1,j),qnew(1,nproj),s)
                  end if
 270           continue
               amm = 0.1d0
               irm = 0
               do 280 j = 1 , nred
                  if (dabs(vlen(j)).gt.amm) then
                     amm = dabs(vlen(j))
                     irm = j
                  end if
 280           continue
               if (irm.eq.0) then
c     reason for starting with amm=0.1 is to catch case
c     where projected orbital in no way resembles any of
c     original set
                  write (iwr,*)
     +                      'projected orbital does not match original?'
                  call caserr('error in orbital projection')
               end if
               call vschmv(num,qnew(1,nproj),q(1,irm),s)
               iperm(nproj) = irm
               easy(irm) = .true.
            end if
 290     continue
         go to 100
      end if
      end
      subroutine indx1s(g,nijkl)
      implicit REAL  (a-h,o-z)
_IF1(iv)      integer *2 nijkl
c...   sorts mainfile onto sortfile --- so that for a
c...   given rs comb. al pq combs. available
c
      logical usesym
      dimension g(*),nijkl(*)
c
INCLUDE(common/sizes)
INCLUDE(common/mapper)
INCLUDE(common/infoa)
INCLUDE(common/three)
INCLUDE(common/atmblk)
INCLUDE(common/stak)
INCLUDE(common/blksiz)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
      common/junke/maxt,ires,ipass,
     + nteff,npass1,npass2,lentri,
     + nbuck,mloww,mhi,ntri,iacc,usesym
c
      common/symmos/imos(8,maxorb),ibasis(8,maxorb),nnnt
      common/bufb/nwbnwb,lnklnk,gout(1)
      common/junk/nwbuck(maxbuc)
     +    ,itx(3400),ktx(3400),gtx(3400)
c
      common/blkin/gin(1)
c
c
      data maxb/999999/
c...   determine base and limit triangles for this pass
      usesym = .true.
c      usesym=nnnt.eq.8.or.(nnnt.eq.4.and.iscftp.eq.0)
      mloww = master
      mlow = mloww + 1
      mhi = master + nteff
      if (mhi.gt.nx) mhi = nx
      mtri = mhi - mlow
c...   determine minimum no. of bucks.
      nbuck = ires
 20   ntri = mtri/nbuck
      if (ntri.lt.maxt) then
         nbuck = nbuck - 1
         if (nbuck.ne.0) go to 20
      end if
      nbuck = nbuck + 1
      ntri = mtri/nbuck + 1
c...   ntri=max. no. of triangles controlled by 1 bucket
c...   nbuck=number of buckets
      btri = ntri
      btri = 1.000000001d0/btri
      do 30 ibuck = 1 , nbuck
         mark(ibuck) = maxb
         nwbuck(ibuck) = 0
 30   continue
      iblock = 0
      nstack = 0
      nwbnwb = nsz340
c
c...   start loop over mainfile blocks
c
      do 50 ifile = 1 , jjfile
         iunit = notape(ifile)
         call search(iblk(ifile),iunit)
         call find(iunit)
         lbl = iblk(ifile) - lblk(ifile)
 40      lbl = lbl + 1
         call get(gin(1),m)
         if (m.ne.0) then
            if (lbl.ne.0) then
               call find(iunit)
            end if
c...   process input block
            nnn = isort4(itx(nstack+1),ktx(nstack+1),gtx(nstack+1))
            nstack = nstack + nnn
            if (nstack.ge.2721) call stackr(g,nijkl)
            if (lbl.ne.0) go to 40
         end if
 50   continue
c...   mainfile now swept
c...   clear up output
      if (nstack.ne.0) call stackr(g,nijkl)
      do 60 ibuck = 1 , nbuck
         nwb = nwbuck(ibuck)
         if (nwb.ne.0) then
c...   output code
            ib = ibase(ibuck)
            ibn= ibasen(ibuck)
            call stopbk
            nwbnwb = nwb
            lnklnk = mark(ibuck)
            call dcopy(nwb,g(ib+1),1,gout,1)
_IFN1(iv)            call pack(gout(nsz341),lab1632,nijkl(ibn+1),nsz680)
_IF1(iv)            call fmove(nijkl(ibn+1),gout(nsz341),nsz170)
            call sttout
            mark(ibuck) = iblock
            iblock = iblock + nsz
         end if
 60   continue
      return
      end
      subroutine indx2s(g,nijkl)
      implicit REAL  (a-h,o-z)
_IF1(iv)      integer *2 nijkl
INCLUDE(common/sizes)
c...   sorts secondary mainfile onto sortfile---so that
c...   for a given ij comb. all rs combs. available
c
      dimension g(*),nijkl(*)
c
INCLUDE(common/blksiz)
INCLUDE(common/atmblk)
INCLUDE(common/stak)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/mapper)
INCLUDE(common/three)
      common/junke/maxt,ires,ipass,
     + nteff,npass1,npass2,lentri,
     + nbuck,mloww,mhi,ntri,iacc
      common/bufb/nwbnwb,lnklnk,gout(1)
      common/blkin/gin(510)
      common/junk/nwbuck(maxbuc)
     +    ,itx(3400),ktx(3400),gtx(3400)
c
      data maxb/999999/
c...   determine base and limit triangles for this pass
      mlow = iky(indxi) + indxj
      mloww = mlow - 1
      mhi = mloww + nteff
      if (mhi.gt.lentri) mhi = lentri
      mtri = mhi - mlow
c...   determine minimum no. of bucks.
      nbuck = ires
 20   ntri = mtri/nbuck
      if (ntri.lt.maxt) then
         nbuck = nbuck - 1
         if (nbuck.ne.0) go to 20
      end if
      nbuck = nbuck + 1
      ntri = mtri/nbuck + 1
      btri = ntri
      btri = 1.000000001d0/btri
c...   ntri=max. no. of triangles controlled by 1 bucket
c...   nbuck=number of buckets
      do 30 ibuck = 1 , nbuck
         mark(ibuck) = maxb
         nwbuck(ibuck) = 0
 30   continue
      iblock = 0
      nstack = 0
      nwbnwb = nsz340
c...   start loop over secondary mainfile blocks
      do 50 ifile = 1 , nnfile
         iunit = nofile(ifile)
         call search(jblk(ifile),iunit)
         call find(iunit)
         lbl = jblk(ifile) - mblk(ifile)
 40      lbl = lbl + 1
         call get(gin(1),m)
         if (m.ne.0) then
            if (lbl.ne.0) then
               call find(iunit)
            end if
c...   process input block
            nnn = isort2(itx(nstack+1),ktx(nstack+1),gtx(nstack+1))
            nstack = nstack + nnn
            if (nstack.ge.3061) call stackr(g,nijkl)
            if (lbl.ne.0) go to 40
         end if
 50   continue
c...   secondary mainfile now swept
c...   clear up output
      if (nstack.ne.0) call stackr(g,nijkl)
      do 60 ibuck = 1 , nbuck
         nwb = nwbuck(ibuck)
         if (nwb.ne.0) then
c...   output code
            ib = ibase(ibuck)
            ibn= ibasen(ibuck)
            call stopbk
            nwbnwb = nwb
            lnklnk = mark(ibuck)
            call dcopy(nwb,g(ib+1),1,gout,1)
_IFN1(iv)            call pack(gout(nsz341),lab1632,nijkl(ibn+1),nsz680)
_IF1(iv)            call fmove(nijkl(ibn+1),gout(nsz341),nsz170)
            call sttout
            mark(ibuck) = iblock
            iblock = iblock + nsz
         end if
 60   continue
      return
      end
      subroutine indxsy(q)
c
c     --------------------------------------------
c     constructs symmetry data for 4-index package
c     project m.0.'s to give pure symmetry types
c     only works for simple groups (no degenerate reps.)
c     --------------------------------------------------
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/symtry)
INCLUDE(common/nshel)
      dimension q(*)
c
      i10 = 1
      i20 = i10 + nw196(5)
c
      call indxxx(q(i20),q(i10),nshell)
      return
      end
      subroutine indxxx(q,iso,nshels)
      implicit REAL  (a-h,o-z)
      logical prout
INCLUDE(common/sizes)
INCLUDE(common/atmblk)
      common/symmos/imos(8,maxorb),ibasis(8,maxorb),nnnnt,nt3,
     1itable(8,8),mult(8,8),irr(maxorb),imosb(8,maxorb),irrb(maxorb)
      logical skip
      common/scrtch/
     +    ptr(3,144),dtr(6,288),ftr(10,480),gtr(15,720),
     +    dp(27,maxat),
     +    nunpr,skip(maxat*3),mapnu(maxat*3),mapun(maxat*3),
     +    iperm(maxat*3),
     +    ict(maxat,8),mptr(8,maxat*3),nuniq,nuni1,nuni2,nuni3
      common/indsym/nirr,mmmm(8,8),nrr(maxorb)
INCLUDE(common/nshel)
INCLUDE(common/mapper)
      character *8 groupy
      common/indsyx/groupy
      character *8 groupx
      common/symtrx/groupx
INCLUDE(common/symtry)
      common/molsym/trg(12),index,naxis
INCLUDE(common/infoa)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/vectrn)
      logical exist
INCLUDE(common/prints)
INCLUDE(common/harmon)
      common/maxlen/maxq
      logical uhf
      dimension q(*),iso(nshels,*)
      character *1 dash
      character *8 open,grp,grpy
      dimension grp(8),grpy(8),ichar(8),
     & char(8)
      data grpy/'c1','ci','cs','c2','c2v','d2','c2h','d2h'/
      data grp/'c1','ci','cs','cn','cnv','dn','cnh','dnh'/
      data dash/'-'/
      data open,one/'open',1.0d0/
c
      nav = lenwrd()
      uhf = scftyp.eq.open
      prout = nt.gt.1 .and. oprint(46)
c
c    -----------------------------------
c    check group and get character table
c    -----------------------------------
c
      do 20 i = 1 , 8
         if (groupx.eq.grp(i)) then
            igrp = i
            go to 40
         end if
 20   continue
 30   write (iwr,6010)
      call caserr(' use non-degenerate group')
 40   go to (60,60,60,50,50,50,50,50) , igrp
 50   if (naxis.ne.2) go to 30
 60   call indtab(igrp,itable,mult)
      nirr = nt
      nnnnt = nt
      do 80 i = 1 , 8
         do 70 j = 1 , 8
            mmmm(i,j) = mult(i,j)
 70      continue
 80   continue
      groupy = grpy(igrp)
      if (prout) then
         write (iwr,6020) groupy , (i,i=1,nt)
         ndash = 13 + 4*nt
         write (iwr,6030) (dash,i=1,ndash)
         do 90 i = 1 , nt
            write (iwr,6040) i , (itable(i,j),j=1,nt)
 90      continue
      end if
c
c     --------------------------------------------------
c     construct transformation table for basis functions
c     --------------------------------------------------
c
c     ------------------------------------------------------
c     read in transformation matrices for s,p,d,f & g functions.
c     ------------------------------------------------------
c
      call rdedx(ptr,nw196(1),ibl196(1),ifild)
      if (odbas) call rdedx(dtr,nw196(2),ibl196(2),ifild)
      if (ofbas) call rdedx(ftr,nw196(3),ibl196(3),ifild)
      if (ogbas) call rdedx(gtr,nw196(4),ibl196(4),ifild)
      call readi(iso,nw196(5)*nav,ibl196(5),ifild)
      do 100 i = 1 , num
         ibasis(1,i) = i
 100  continue
      if (nt.gt.1) then
         do 290 i = 1 , nshell
            kty = ktype(i)
            mini = kmin(i)
c           maxi = kmax(i)
            loci = kloc(i) - mini
            do 280 iop = 2 , nt
               id = iso(i,iop)
               locj = kloc(id) - mini
               go to (120,130,180,230,600) , kty
c     s functions
 120           ibasis(iop,loci+1) = locj + 1
               go to 280
c     p functions
 130           npp = (iop-1)*3 - 1
               do 170 j = 2 , 4
                  do 140 k = 2 , 4
                     tr = ptr(k-1,npp+j)
                     if (dabs(tr-one).lt.1.0d-8) go to 150
                     if (dabs(tr+one).lt.1.0d-8) go to 160
 140              continue
                  call caserr(
     +            'error in symtyp - wrong group/orientation')
 150              ibasis(iop,loci+j) = locj + k
                  go to 170
 160              ibasis(iop,loci+j) = -(locj+k)
 170           continue
               if (mini.ne.1) go to 280
               go to 120
c     d functions
 180           nd = (iop-1)*6 - 4
               do 220 j = 5 , 10
                  do 190 k = 5 , 10
                     tr = dtr(k-4,nd+j)
                     if (dabs(tr-one).lt.1.0d-8) go to 200
                     if (dabs(tr+one).lt.1.0d-8) go to 210
 190              continue
                  call caserr(
     +            'error in symtyp - wrong group/orientation')
 200              ibasis(iop,loci+j) = locj + k
                  go to 220
 210              ibasis(iop,loci+j) = -(locj+k)
 220           continue
               go to 280
c     f functions
 230           nf = (iop-1)*10 - 10
               do 270 j = 11 , 20
                  do 240 k = 11 , 20
                     tr = ftr(k-10,nf+j)
                     if (dabs(tr-one).lt.1.0d-8) go to 250
                     if (dabs(tr+one).lt.1.0d-8) go to 260
 240              continue
                  call caserr(
     +            'error in symtyp - wrong group/orientation')
 250              ibasis(iop,loci+j) = locj + k
                  go to 270
 260              ibasis(iop,loci+j) = -(locj+k)
 270           continue
               go to 280
c     g functions
 600           ng = (iop-1)*15 - 20
               do 610 j = 21 , 35
                  do 620 k = 21 , 35
                     tr = gtr(k-20,ng+j)
                     if (dabs(tr-one).lt.1.0d-8) go to 630
                     if (dabs(tr+one).lt.1.0d-8) go to 640
 620              continue
                  call caserr(
     +            'error in symtyp - wrong group/orientation')
 630              ibasis(iop,loci+j) = locj + k
                  go to 610
 640              ibasis(iop,loci+j) = -(locj+k)
 610           continue
c
 280        continue
 290     continue
      end if
      if (prout) then
         write (iwr,6070) (i,i=1,nt)
         write (iwr,6030) (dash,i=1,ndash)
         do 300 i = 1 , num
            write (iwr,6060) i , (ibasis(j,i),j=1,nt)
 300     continue
      end if
c
c
c     now construct transformation table of perturbations
c
c
      do 330 ii = 1 , nshell
         ic = katom(ii)
         do 320 it = 1 , nt
            id = iso(ii,it)
            ict(ic,it) = katom(id)
 320     continue
 330  continue
c
c
      nat3 = 3*nat
      do 340 iii = 1 , nat3
         mptr(1,iii) = iii
 340  continue
c
      do 400 iat = 1 , nat
         do 390 iop = 2 , nt
            nuat = ict(iat,iop)
            npp = (iop-1)*3
            do 380 j = 1 , 3
               ipr = (iat-1)*3 + j
               do 350 k = 1 , 3
                  tr = ptr(k,npp+j)
                  if (dabs(tr-one).lt.1.0d-8) go to 360
                  if (dabs(tr+one).lt.1.0d-8) go to 370
 350           continue
c
c     not supposed to be here!
c
 360           mptr(iop,ipr) = (nuat-1)*3 + k
               go to 380
 370           mptr(iop,ipr) = -((nuat-1)*3+k)
 380        continue
 390     continue
 400  continue
c
      nuniq = 0
      do 560 n = 1 , nat
        do 570 nop = 1 , nt
        if (ict(n,nop).ne.n) go to 560
 570    continue
      nuniq = n
      go to 580
 560  continue
c
 580  call indprt(nat*3,nt,prout,iwr)
c
c     character of basis set
      do 420 iop = 1 , nt
         ichar(iop) = 0
         do 410 j = 1 , num
            ib = ibasis(iop,j)
            if (iabs(ib).eq.j) then
               if (ib.lt.0) ichar(iop) = ichar(iop) - 1
               if (ib.gt.0) ichar(iop) = ichar(iop) + 1
            end if
 410     continue
 420  continue
      if (prout) then
        write (iwr,*) 'reducible representation of basis functions'
        write (iwr,*) (ichar(i),i=1,nt)
         do 440 irep = 1 , nt
            nirep = 0
            do 430 iop = 1 , nt
               nirep = nirep + ichar(iop)*itable(irep,iop)
 430        continue
            nirep = nirep/nt
            write(iwr,*) 'representation ' , irep , ' occurs ' , 
     +         nirep , ' times'
 440     continue
      end if
c
c     get mo's and overlap matrix
c
      nsq = num*num
c     q(1)=vectors,q(i1)=eigenvalues,q(i2)=overlap
c     q(i3),q(i4),q(i5)=decomposions of vectors
      i1 = nsq
      i2 = i1 + num
      i3 = i2 + nx
      i4 = i3 + num*nt
c     i5 = i4 + num*nt
 450  call secloc(isecvv,exist,iblkq)
      if (.not.exist) call caserr('indxxx: no vector section') 
      iblkq = iblkq + mvadd
c     read molecular orbitals
      call rdedx(q(1),num*ncoorb,iblkq,ifild)
      call secget(isect(5),5,isec5)
      call secget(isect(9),9,isec9)
c     read eigenvalues
      call rdedx(q(i1+1),lds(isect(9)),isec9,ifild)
c     read overlap matrix
      call rdedx(q(i2+1),nx,isec5,ifild)
      if (nt.eq.1) then
         if (uhf .and. isecvv.eq.isect(11)) then
            do 460 i = 1 , nsb
               irrb(i) = 1
               imosb(1,i) = 1
 460        continue
         else
            do 470 i = 1 , nsa4
               irr(i) = 1
               nrr(i) = 1
               imos(1,i) = 1
 470        continue
         end if
         go to 530
      end if
c
c     --------------------------------------
c     decide symmetry types of m.o.'s
c     also project out minor symmetry
c     contaminants to ensure exact symmetry
c     for each m.o.
c     --------------------------------------
c
c     ant = one/dfloat(nt)
c
      i = 1
c
 480  ii = ilifq(i)
      call inddeg(q(i1+1),nsa4,i,nred)
      call indcha(q(ii+1),num,nred,q(i3+1),q(i2+1),char,ichar,iwr)
      call indpro(q(ii+1),num,nred,q(i3+1),q(i2+1),q(i4+1),ichar,i,uhf)
      i = i + nred
c
      if (i.gt.newbas0) then
c...    **harmonic**  The last one asre 0.0,leave symmetries in irr
         if (i.ne.newbas0+1) call caserr('harmonic error in indxxx')
         j = 1
         do i=newbas0+1,newbas1
            do k=j,newbas1
               if (ielimh(k).ne.0) go to 481
            end do
481         j = k
            irr(i) = ielimh(j)
         end do
         i = newbas1 + 1
      end if
c
      if (i.le.ncoorb) go to 480
c
c
      if (uhf .and. isecvv.eq.isect(11)) then
         do 500 i = 1 , nsb
            j = mapie(i)
            irrb(i) = irrb(j)
            do 490 k = 1 , nt
               imosb(k,i) = imosb(k,j)
 490        continue
 500     continue
      else
         do 520 i = 1 , nsa4
            j = mapie(i)
            irr(i) = irr(j)
            nrr(i) = irr(j)
            do 510 k = 1 , nt
               imos(k,i) = imos(k,j)
 510        continue
 520     continue
      end if
c
c
c
 530  if (prout) then
         write (iwr,6080) (i,i=1,nt)
         ndash = 21 + 4*nt
         write (iwr,6030) (dash,i=1,ndash)
         if (uhf .and. isecvv.eq.isect(11)) then
            do 540 i = 1 , nsb
               write (iwr,6050) i , irrb(i) , (imosb(j,i),j=1,nt)
 540        continue
         else
            do 550 i = 1 , nsa4
               write (iwr,6050) i , irr(i) , (imos(j,i),j=1,nt)
 550        continue
         end if
      end if
c
c
      lds(isect(104)) = lenint(maxorb+65)
      ldsect(isect(104)) = 1
      call secput(isect(104),104,1+lensec(lds(isect(104))),is104)
      call wrtc(groupy,ldsect(isect(104)),is104,ifild)
cjvl     call wrt3s(nirr,lds(isect(104)),ifild)
      call wrt3is(nirr,maxorb+65,ifild)
      call revind
      if (prout) then
         write (iwr,6090)
         call prsqm(q,num,ncoorb,num,iwr)
      end if
      call wrt3(q,num*ncoorb,iblkq,ifild)
      if (uhf) then
         if (isecvv.eq.isect(11)) then
            isecvv = isect(8)
         else
            isecvv = isect(11)
            go to 450
         end if
      end if
      call clredx
c
      return
 6010 format (//20x,'error in symmetry  program'/20x,
     +        'group is not one of - c1,c2,ci,cs,c2v,d2,c2h or d2h')
 6020 format (//20x,'character table -- group  ',a4/20x,30('=')//20x,
     +        'i.r.',4x,':',4x,8i4)
 6030 format (20x,60a1)
 6040 format (28x,':'/28x,':'/20x,i3,5x,':',4x,8i4)
 6050 format (36x,':'/20x,i3,5x,i3,5x,':',4x,8i4)
 6060 format (28x,':'/20x,i3,5x,':',4x,8i4)
 6070 format (//20x,'transformation table for basis functions'/20x,
     +        40('=')//20x,'a.o.',4x,':',4x,8i4)
 6080 format (//20x,'representation table for active',
     +        ' molecular orbitals'/20x,50('=')//20x,'m.o.',4x,'i.r.',
     +        4x,':',4x,8i4)
 6090 format (//25x,'eigenvectors rotated to give pure symmetry',
     +        ' types')
      end
_IF(ibm,vax)
      subroutine transg(qq,nx)
      implicit REAL  (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer*2 lin
INCLUDE(common/blksiz)
      common/junke/maxt(8),mloww
      common/bufb/nkk,mkk,gin(1)
      dimension qq(*)
      dimension lin(2)
      equivalence (lin(1),gin(1))
      ij=nszij
      kl=nszkl
      do loop=1,nkk
       ijkl = (lin(ij)-mloww)*nx + lin(kl)
       qq(ijkl) = qq(ijkl) + gin(loop)
       j=ij+1
       kl=kl+1
      enddo
      return
      end
_ELSE
      subroutine transg(qq,nx)
      implicit REAL  (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/blksiz)
INCLUDE(common/atmblk)
      common/junke/maxt(8),mloww
      common/bufb/nkk,mkk,gin(1)
      common/scra/ijklin(2,3412),index(3412)
      dimension qq(*)
      call unpack(gin(nsz341),lab1632,ijklin,nsz680)
      do loop = 1,nkk
        index(loop) = (ijklin(1,loop)-mloww)*nx + 
     +                 ijklin(2,loop)
      enddo
      do loop = 1,nkk
         qq(index(loop)) = qq(index(loop)) + gin(loop)
      enddo
      return
      end
_ENDIF
      subroutine indbli(n,a,i,j,k,l,ifil,last)
      implicit REAL  (a-h,o-z)
      dimension a(*),i(*),j(*),k(*),l(*)
      logical last
_IF1(iv)      parameter (irlen=340)
      common/blkin/g(510),nint
INCLUDE(common/atmblk)
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(irlen),j205(irlen),k205(irlen),l205(irlen)
c
c      read and unpack one block a a two-electron integral
c      on two-particle density file, with labels in 1-byte
c      packing pattern (.lt.256) andn 2-byte (.ge.256)
c
      call find(ifil)
      call get(g,nw)
      last = .false.
      if (nw.eq.0 .or. nint.eq.0) then
         n = 0
         last = .true.
c      write(6,*)' last block read'
      else
_IFN1(iv)         call unpack(g(num2e+1),lab816,labs,numlab)
_IF1(iv)         call upak8v(g(num2e+1),i205)
         n = nint
         do 20 kk = 1 , nint
            a(kk) = g(kk)
_IFN1(iv)            kk4 = (kk+kk) + (kk+kk)
_IF(ibm,vax)
            i(kk) = i205(kk)
            j(kk) = j205(kk)
            k(kk) = k205(kk)
            l(kk) = l205(kk)
_ELSEIF(littleendian)
            i(kk) = labs(kk4-2)
            j(kk) = labs(kk4-3)
            k(kk) = labs(kk4  )
            l(kk) = labs(kk4-1)
_ELSE
            i(kk) = labs(kk4-3)
            j(kk) = labs(kk4-2)
            k(kk) = labs(kk4-1)
            l(kk) = labs(kk4)
_ENDIF
 20      continue
      end if
      return
      end
      subroutine indxsf(f,h,iso,nshels,ia)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      logical iandj
c
c     ----- symmetrize the skeleton fock matrix
c
      dimension f(*),h(*),ia(*),iso(nshels,*)
c
INCLUDE(common/nshel)
INCLUDE(common/symtry)
INCLUDE(common/infoa)
      common/hsym/t(35,35),mini,maxi,lit,minj,maxj,ljt,ntr
INCLUDE(common/iofile)
      dimension mi(48)
      data zero,one/0.0d0,1.0d0/
      if (nt.eq.1) return
      nav = lenwrd()
      call readi(iso,nw196(5)*nav,ibl196(5),idaf)
      do 20 i = 1 , nx
         h(i) = zero
 20   continue
c     ----- find a block (i,j)
      do 190 ii = 1 , nshell
         do 40 itr = 1 , nt
            ish = iso(ii,itr)
            if (ish.gt.ii) go to 190
            mi(itr) = ish
 40      continue
         lit = ktype(ii)
         mini = kmin(ii)
         maxi = kmax(ii)
         loci = kloc(ii) - mini
         do 180 jj = 1 , ii
            do 60 itr = 1 , nt
               jsh = iso(jj,itr)
               if (jsh.gt.ii) go to 180
               ish = mi(itr)
               if (ish.lt.jsh) then
                  n = ish
                  ish = jsh
                  jsh = n
               end if
               if (ish.eq.ii .and. jsh.gt.jj) go to 180
 60         continue
            ljt = ktype(jj)
            minj = kmin(jj)
            maxj = kmax(jj)
            locj = kloc(jj) - minj
            iandj = ii.eq.jj
            jmax = maxj
c     ----- find the equivalent blocks
c     ----- transfer equivalent block into t-matrix
c     ----- compute (r) t (r)
c     ----- put the result back into the (i,j) block of the h-matrix
            do 110 itr = 1 , nt
               ntr = itr
               kk = mi(itr)
               ll = iso(jj,itr)
               lock = kloc(kk) - kmin(kk)
               locl = kloc(ll) - kmin(ll)
               do 80 k = mini , maxi
                  lck = lock + k
                  if (iandj) jmax = k
                  do 70 l = minj , jmax
                     if (ll.gt.kk) then
                        kl = ia(locl+l) + lck
                     else
                        kl = ia(lck) + locl + l
                     end if
                     t(k,l) = f(kl)
                     if (iandj) t(l,k) = f(kl)
 70               continue
 80            continue
               if (lit.gt.1 .or. ljt.gt.1) call indx2r()
               do 100 i = mini , maxi
                  lci = ia(loci+i) + locj
                  if (iandj) jmax = i
                  do 90 j = minj , jmax
                     ij = lci + j
                     h(ij) = h(ij) + t(i,j)
 90               continue
 100           continue
 110        continue
c     ----- for each block (k,l) equivalent to (i,j)
c     ----- find the transformation that maps (k,l) into (i,j)
c     ----- compute (r) t (r)
c     ----- put the result back into the (k,l) block of the h-matrix
            do 170 itr = 2 , nt
               kk = mi(itr)
               ll = iso(jj,itr)
               if (kk.ge.ll) then
                  k = kk
                  l = ll
               else
                  k = ll
                  l = kk
               end if
               if (k.ne.ii .or. l.ne.jj) then
                  ntr = itr + 1
                  if (ntr.le.nt) then
                     do 120 it = ntr , nt
                        i = mi(it)
                        j = iso(jj,it)
                        if (i.lt.j) then
                           ij = i
                           i = j
                           j = ij
                        end if
                        if (i.eq.k .and. j.eq.l) go to 170
 120                 continue
                  end if
                  ntr = invt(itr)
                  do 140 i = mini , maxi
                     lci = ia(loci+i) + locj
                     if (iandj) jmax = i
                     do 130 j = minj , jmax
                        t(i,j) = h(lci+j)
                        if (iandj) t(j,i) = h(lci+j)
 130                 continue
 140              continue
                  if (lit.gt.1 .or. ljt.gt.1) call indx2r()
                  lock = kloc(kk) - kmin(kk)
                  locl = kloc(ll) - kmin(ll)
                  do 160 k = mini , maxi
                     lck = lock + k
                     if (iandj) jmax = k
                     do 150 l = minj , jmax
                        if (ll.gt.kk) then
                           kl = ia(locl+l) + lck
                        else
                           kl = ia(lck) + locl + l
                        end if
                        h(kl) = t(k,l)
 150                 continue
 160              continue
               end if
 170        continue
 180     continue
 190  continue
      dum = one/dfloat(nt)
      do 200 i = 1 , nx
         f(i) = h(i)*dum
 200  continue
      return
      end
      subroutine indx2r
      implicit REAL  (a-h,o-z)
      common/scrtch/ptr(3,144),dtr(6,288),ftr(10,480),gtr(15,720)
      common/hsym/t(35,35),mink,maxk,lkt,minl,maxl,llt,ntr
      dimension u(35)
      equivalence (u(1),u1),(u(2),u2),(u(3),u3),(u(4),u4),
     &    (u(5),u5),(u(6),u6)
c     ----- right multiply  t  by  r,
c           result back in  t
      go to (110,90,70,20,220) , llt
c     ----- g shell
 220  ng = (ntr-1)*15
      do k = mink , maxk
         do l = 1 , 15
            u(l) = t(k,l+20)
         enddo
         do l = 1 , 15
            sum = 0.0d0
            do i = 1 , 15
               sum = sum + u(i)*gtr(i,ng+l)
            enddo
            t(k,l+20) = sum
         enddo
       enddo
      go to 110
c     ----- f shell
 20   nf = (ntr-1)*10
      do 60 k = mink , maxk
         do 30 l = 1 , 10
            u(l) = t(k,l+10)
 30      continue
         do 50 l = 1 , 10
            sum = 0.0d0
            do 40 i = 1 , 10
               sum = sum + u(i)*ftr(i,nf+l)
 40         continue
            t(k,l+10) = sum
 50      continue
 60   continue
      go to 110
c     ----- d shell
 70   nd = 6*ntr - 10
      do 80 k = mink , maxk
         u1 = t(k,5)
         u2 = t(k,6)
         u3 = t(k,7)
         u4 = t(k,8)
         u5 = t(k,9)
         u6 = t(k,10)
         t(k,5) = u1*dtr(1,nd+5) + u2*dtr(2,nd+5) + u3*dtr(3,nd+5)
     +            + u4*dtr(4,nd+5) + u5*dtr(5,nd+5) + u6*dtr(6,nd+5)
         t(k,6) = u1*dtr(1,nd+6) + u2*dtr(2,nd+6) + u3*dtr(3,nd+6)
     +            + u4*dtr(4,nd+6) + u5*dtr(5,nd+6) + u6*dtr(6,nd+6)
         t(k,7) = u1*dtr(1,nd+7) + u2*dtr(2,nd+7) + u3*dtr(3,nd+7)
     +            + u4*dtr(4,nd+7) + u5*dtr(5,nd+7) + u6*dtr(6,nd+7)
         t(k,8) = u1*dtr(1,nd+8) + u2*dtr(2,nd+8) + u3*dtr(3,nd+8)
     +            + u4*dtr(4,nd+8) + u5*dtr(5,nd+8) + u6*dtr(6,nd+8)
         t(k,9) = u1*dtr(1,nd+9) + u2*dtr(2,nd+9) + u3*dtr(3,nd+9)
     +            + u4*dtr(4,nd+9) + u5*dtr(5,nd+9) + u6*dtr(6,nd+9)
         t(k,10) = u1*dtr(1,nd+10) + u2*dtr(2,nd+10) + u3*dtr(3,nd+10)
     +             + u4*dtr(4,nd+10) + u5*dtr(5,nd+10) + u6*dtr(6,nd+10)
 80   continue
      go to 110
c     ----- p shell
 90   np = 3*ntr - 4
      do 100 k = mink , maxk
         u1 = t(k,2)
         u2 = t(k,3)
         u3 = t(k,4)
         t(k,2) = u1*ptr(1,np+2) + u2*ptr(2,np+2) + u3*ptr(3,np+2)
         t(k,3) = u1*ptr(1,np+3) + u2*ptr(2,np+3) + u3*ptr(3,np+3)
         t(k,4) = u1*ptr(1,np+4) + u2*ptr(2,np+4) + u3*ptr(3,np+4)
 100  continue
c     ----- left multiply  t  by r
c           result back in  t
 110  go to (210,190,170,120,125) , lkt
c     ------ g shell
 125  ng = (ntr-1)*15
      do l = minl , maxl
        do k = 1 , 15
           u(k) = t(k+20,l)
        enddo
        do k = 1 , 15
         sum = 0.0d0
         do i = 1 , 15
            sum = sum + u(i)*gtr(i,ng+k)
         enddo
         t(k+20,l) = sum
        enddo
      enddo
c
      go to 210
c
c     ------ f shell
 120  nf = (ntr-1)*10
      do 160 l = minl , maxl
         do 130 k = 1 , 10
            u(k) = t(k+10,l)
 130     continue
         do 150 k = 1 , 10
            sum = 0.0d0
            do 140 i = 1 , 10
               sum = sum + u(i)*ftr(i,nf+k)
 140        continue
            t(k+10,l) = sum
 150     continue
 160  continue
      go to 210
c     ----- d shell
 170  nd = 6*ntr - 10
      do 180 k = minl , maxl
         u1 = t(5,k)
         u2 = t(6,k)
         u3 = t(7,k)
         u4 = t(8,k)
         u5 = t(9,k)
         u6 = t(10,k)
         t(5,k) = u1*dtr(1,nd+5) + u2*dtr(2,nd+5) + u3*dtr(3,nd+5)
     +            + u4*dtr(4,nd+5) + u5*dtr(5,nd+5) + u6*dtr(6,nd+5)
         t(6,k) = u1*dtr(1,nd+6) + u2*dtr(2,nd+6) + u3*dtr(3,nd+6)
     +            + u4*dtr(4,nd+6) + u5*dtr(5,nd+6) + u6*dtr(6,nd+6)
         t(7,k) = u1*dtr(1,nd+7) + u2*dtr(2,nd+7) + u3*dtr(3,nd+7)
     +            + u4*dtr(4,nd+7) + u5*dtr(5,nd+7) + u6*dtr(6,nd+7)
         t(8,k) = u1*dtr(1,nd+8) + u2*dtr(2,nd+8) + u3*dtr(3,nd+8)
     +            + u4*dtr(4,nd+8) + u5*dtr(5,nd+8) + u6*dtr(6,nd+8)
         t(9,k) = u1*dtr(1,nd+9) + u2*dtr(2,nd+9) + u3*dtr(3,nd+9)
     +            + u4*dtr(4,nd+9) + u5*dtr(5,nd+9) + u6*dtr(6,nd+9)
         t(10,k) = u1*dtr(1,nd+10) + u2*dtr(2,nd+10) + u3*dtr(3,nd+10)
     +             + u4*dtr(4,nd+10) + u5*dtr(5,nd+10) + u6*dtr(6,nd+10)
 180  continue
      go to 210
c     ----- p shell
 190  np = 3*ntr - 4
      do 200 k = minl , maxl
         u1 = t(2,k)
         u2 = t(3,k)
         u3 = t(4,k)
         t(2,k) = u1*ptr(1,np+2) + u2*ptr(2,np+2) + u3*ptr(3,np+2)
         t(3,k) = u1*ptr(1,np+3) + u2*ptr(2,np+3) + u3*ptr(3,np+3)
         t(4,k) = u1*ptr(1,np+4) + u2*ptr(2,np+4) + u3*ptr(3,np+4)
 200  continue
 210  return
      end
      subroutine ver_index4(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/index4.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
