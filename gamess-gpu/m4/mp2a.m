c 
c  $Author: jmht $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mp2a.m,v $
c  $State: Exp $
c  
      subroutine mp2srt(q,iblki,ifili,nocca,nvirta,ncor,nvir,e2,
     +           eigs,ee,ieqj,maxoc2)
      implicit REAL  (a-h,o-z)
      logical ieqj
c
c     sorting routine -
c
      common/junke/ibl5,ibl52,maxt,maxb,nadd,nij,n2,nbuck
      common/maxlen/maxq
      common/craypk/labs(1360)
INCLUDE(common/blksiz)
INCLUDE(common/iofile)
INCLUDE(common/timeperiods)
INCLUDE(common/disp)
      dimension q(*),eigs(*),ee(maxoc2),ieqj(maxoc2)
c
      parameter (maxbuc=1500)
c
c     ibl5 = no of integrals in block of sortfile
c
c     call start_time_period('mp2 sort')
      call start_time_period(TP_MP2)
c
      call setbfa
c
      ibl5 = nsz340
      iilen = nsz340*lenwrd()/2
      ibl52 = iilen
      ibl5i = lenint(ibl5)
      nij = nocca*(nocca+1)/2
      n2 = nvirta*nvirta
c
c       are going to sort the integrals from file ifili and
c       starting block iblki so that for ij (i.ge.j) all kl
c       integrals are available in a square on stream ifort
c
c       is this modified version for mp2 energies ij covers only
c       occupied = occupied pairs, and kl only virtual - virtual
c       square
c
c       maxt is the number of triangles (squares for exchange ints)
c       which can be held in core (allowing n2 wkspace for reading back)
c       which is the number in each bucket
c
      maxt = (maxq-n2)/n2
      nword = (maxq/(1+lenrel(1)))*lenrel(1)
c      maxb is the maximum number of blocks of the sortfile
c      which can be held in core
c      which is the maximum number of buckets
c
      maxb = min(maxbuc,nword/ibl5)
c
c     nbuck is the number of buckets required
c
      nbuck = (nij/maxt) + 1
      nadd = min(maxt,nij)
      maxa = nbuck*(ibl5+ibl5i)
c
c
      if (nbuck.gt.maxb) then
         write (iwr,6010) maxq , maxa
         call caserr('insufficient memory for mp2 calculation')
      end if
c
c       read through original file producing sorted file
c
      call vclr(q,1,maxa)
      call setsto(1360,0,labs)
      call setbfa
      call mp2sr0(q,q,iblki,ifili,nvirta,nocca)
c
c     call end_time_period('mp2 sort')
c     call start_time_period('mp2 ener')
c
c       read through the sort file to give final result
c
      maxqq = nadd*n2
      call mp2sr1(q(n2+1),maxqq,nocca,nvirta,e2,ncor,nvir,
     +  xnorm,eigs,ee,ieqj,maxoc2)
c
      cnorm = 1.0d0/dsqrt(1.0d0+xnorm)
      renorm = e2*xnorm
c     write (iwr,6020) e2 , xnorm , cnorm , renorm
      if (.not.odisp) then
         write (iwr,6020) e2 , renorm , cnorm 
      else
         write (iwr,6021) nocc_a,nmo_a-nocc_a,
     1                    nocc_b,nmo_b-nocc_b, e2,
     1                    e2*2625.562d0,e2*627.52d0,e2*315777.d0,cnorm 
      end if
c     call end_time_period('mp2 ener')
      call end_time_period(TP_MP2)
      call closbf(0)
c
      return
 6010 format (//1x,'insufficient core'/1x,'available',i8,'  required',
     +        i8)
 6020 format (/10x,42('*')/10x,'mp2 calculation'/10x,42('*')
     +        /10x,'mp2 correlation energy     ',f15.8
     +        /10x,'mp4 renormalisation energy ',f15.8
c    +        /10x,'xnorm  <1|1>               ',f15.8
     +        /10x,'c(0)                       ',f15.8
     +        /10x,42('*'))
 6021 format (/10x,62('*')/10x,'mp2 Dispersion','  occ_a ',i3,
     +        ' virt_a ',i5,' occ_b ',i3,' virt_b ',i4,/10x,62('*'),
     +   /10x,'Polarisation dispersion  energy ',e15.8,' a.u.',
     +   /10x,'                                ',f15.10,' Kjoule/mole',
     +   /10x,'                                ',f15.10,' Kcal/mole',
     +   /10x,'                                ',f15.10,' K',
     +   /10x,'c(0)                            ',f15.10,
     +   /10x,62('*'))
      end
      subroutine mp2sr0(a,ia,iblki,ifili,nvirta,nocca)
      implicit REAL  (a-h,o-z)
c-------------------------------------------------------------
c     reads the integral file to produce the back-chained
c     sortfile of exchange integrals
c---------------------------------------------------------------
INCLUDE(common/sizes)
INCLUDE(common/stak)
INCLUDE(common/blksiz)
INCLUDE(common/atmblk)
      common/bufb/nkk1,mkk1,g(1)
INCLUDE(common/three)
      common/junk/nwbuck(maxbuc)
      common/junke/ibl5,ibl52,maxt,maxb,nadd,nij,n2,nbuck
      common/maxlen/maxq
      common/blkin/gin(510),nint
_IFN1(iv)      common/craypk/labs(1360)
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
INCLUDE(common/mapper)
      dimension a(*),ia(*)
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
c      ninb = no of elements in bucket(coreload)
      ninb = nadd*n2
c
      call search(iblki,ifili)
 30   call find(ifili)
      call get(gin,nw)
      if (nw.eq.0) then
c
c      empty anything remaining in buckets
c
         do 40 ibuck = 1 , nbuck
            nwb = nwbuck(ibuck)
            if (nwb.ne.0) then
               call stopbk
               mkk1 = mark(ibuck)
               nkk1 = nwb
_IF(ibm,vax)
               call fmove(a(ibase(ibuck)+1),g,ibl5)
               call fmove(ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
_ELSE
               call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
               call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_ENDIF
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

c     only want (ai/bj)
c
            if (i1.gt.nocca .and. j1.le.nocca .and. k1.gt.nocca .and.
     +          l1.le.nocca) then

               val = gin(int)
               i1 = i1 - nocca
               k1 = k1 - nocca
               i11 = (i1-1)*nvirta
               k11 = (k1-1)*nvirta
c
c-------------------------------------------------------------------
c     contribution to k([jl],i,k) or k([jl],k,i)
c
               jl = iky(j1) + l1
               ik = k11 + i1
c
               if (j1.lt.l1) then
                  jl = iky(l1) + j1
                  ik = i11 + k1
               end if
c
               iaddr = (jl-1)*n2 + ik
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
_IF(ibm,vax)
                  call fmove(a(ibase(ibuck)+1),g,ibl5)
                  call fmove(ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
_ELSE
                  call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
                  call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_ENDIF
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
               if (j1.eq.l1 .and. i1.ne.k1) then
                  jl = iky(j1) + l1
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
_IF(ibm,vax)
                     call fmove(a(ibase(ibuck)+1),g,ibl5)
                     call fmove(ia(ibasen(ibuck)+1),g(nsz341),ibl5i)
_ELSE
                     call dcopy(ibl5,a(ibase(ibuck)+1),1,g,1)
                     call pack(g(nsz341),32,ia(ibasen(ibuck)+1),ibl5)
_ENDIF
                     call sttout
                     nwbuck(ibuck) = 0
                     mark(ibuck) = iblock
                     iblock = iblock + nsz
                  end if
               end if
            end if
c
 50      continue
         go to 30
      end if
      end
      subroutine mp2sr1(q,maxqq,nocca,nvirta,e2,ncor,nvir,
     1   xnorm,e,ee,ieqj,maxoc2)
      implicit REAL  (a-h,o-z)
      logical ieqj
c
c     energy assembly
c
INCLUDE(common/sizes)
      dimension q(maxqq),e(*),ee(maxoc2),ieqj(maxoc2)
INCLUDE(common/mapper)
      common/junke/ibl5,ibl52,maxt,maxb,nadd,nij,n2,nbuck
INCLUDE(common/stak)
INCLUDE(common/blksiz)
      common/bufb/nkk,mkk,g(1)
      common/sortpk/labs(1)
INCLUDE(common/three)
INCLUDE(common/disp)
_IF1(iv)      dimension lin(2)
_IF1(iv)      equivalence (lin(1),g(1))
      data lastb/999999/
c
      if (odisp) then
         exch_fac = 0.0d0
         nvirt_a = nmo_a - nocc_a
      else
         exch_fac = 1.0d0
      end if
c
c    read thru the sort file to get core load of elements then
c    write them out on sequential file
c
c
      e2 = 0.0d0
      xnorm = 0.0d0
      icnt = 0
      noctri = nocca*(nocca+1)/2
      do 30 i = 1 , nocca
         do 20 j = 1 , i
            icnt = icnt + 1
            ieqj(icnt) = i.eq.j
            ee(icnt) = e(mapie(i)) + e(mapie(j))
 20      continue
 30   continue
      icnt = 0
      icnt1 = 1
      jcnt1 = 0
c
c
      min = 1
      max = nadd
c
c     loop over buckets
c
      do 80 i = 1 , nbuck
         call vclr(q,1,maxqq)
         mkk = mark(i)
 40      if (mkk.eq.lastb) then
c
c     squares min thru max are in core - clear them out
c
            j = 0
            do 70 n = min , max
c
               icnt = icnt + 1
               if (icnt.gt.noctri) return
               fac = -2.0d0
               jcnt1 = jcnt1 + 1
               if (jcnt1.gt.icnt1) then
                  icnt1 = icnt1 + 1
                  jcnt1 = 1
               end if
               if (jcnt1.gt.ncor.and.
     1            (.not.odisp.or.jcnt1.le.nocc_a)) then
                  if (icnt1.gt.ncor.and.
     1               (.not.odisp.or.icnt1.gt.nocc_a)) then
                     if (ieqj(icnt)) fac = -1.0d0
                     do 60 ia = 1 , nvirta - nvir
                        do 50 ib = 1 , nvirta - nvir
                           if (odisp.and.
     1                         ((ia.le.nvirt_a.and.ib.le.nvirt_a).or.
     1                          (ia.gt.nvirt_a.and.ib.gt.nvirt_a).or.
     1                          (ia.le.ib)  )) go to 50
                           ddiff = 1.0d0/(e(mapie(ia+nocca))
     +                             +e(mapie(ib+nocca))-ee(icnt))
                           iab = (ib-1)*nvirta + ia
                           iba = (ia-1)*nvirta + ib
                           e2 = e2 + fac*( q(j+iab)+q(j+iab)
     +                                    -q(j+iba)*exch_fac  )
     +                          *q(j+iab)*ddiff
                           xnorm = xnorm +
     +                             fac*(q(j+iab)+q(j+iab)
     +                                 -q(j+iba)*exch_fac)
     +                             *q(j+iab)*ddiff*ddiff
 50                     continue
 60                  continue
                  end if
               end if
c
               j = j + n2
 70         continue
            min = min + nadd
            max = max + nadd
            if (max.gt.nij) max = nij
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
            go to 40
         end if
 80   continue
      xnorm = -xnorm
      return
      end
      subroutine mp2eng(q,ncor,nvir)
      implicit REAL  (a-h,o-z)
c
c     mp2 energy - low memory version
c
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/statis)
      common/mpases/mpass,ipass,mpst,mpfi,mpadd,iaoxf1,iaoxf2,moderf
INCLUDE(common/nshel)
INCLUDE(common/infoa)
c
      logical lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis
      common/scfblk/en,etot,ehf,sh1(2),sh2(2),gap1(2),gap2(2),
     1              d12,d13,d23,canna,cannb,cannc,fx,fy,fz,
     2              lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis,
     3              ncyc,ischm,lock,maxit,nconv,npunch,lokcyc
c
      common/maxlen/maxq
INCLUDE(common/cigrad)
c
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
      logical ieqj
      parameter (maxocc=100)
      common/small/eigs(maxorb),ee(maxocc*(maxocc+1)/2),
     &  ieqj(maxocc*(maxocc+1)/2)
_IF1()      logical lstop,skipp
_IF1()      dimension skipp(100)
INCLUDE(common/atmblk)
INCLUDE(common/disp)
      dimension q(*)
      character *80 errstr
c
      call cpuwal(begin,ebegin)
      m9 = 9
      call secget(isect(9),m9,isec9)
      call rdedx(eigs,lds(isect(9)),isec9,ifild)
      if(nocca.gt.maxocc) then
         write(errstr,6020) nocca,maxocc
         call caserr(errstr)
      endif
      maxoc2 = (maxocc*(maxocc+1))/2
      call mp2srt(q,kblk(1),nufile(1),nocca,nvirta,ncor,nvir,e2,
     +            eigs,ee,ieqj,maxoc2)
      call secget(isect(13),13,isec13)
      call rdedx(en,lds(isect(13)),isec13,ifild)
      etot = en + ehf + e2
      call wrt3(en,lds(isect(13)),isec13,ifild)
      if (.not.odisp) write (iwr,6010) etot
      call timit(3)
      call timana(25)
      return
 6010 format (10x,'total energy (mp2)         ',f15.8/10x,42('*'))
 6020 format('invalid no. of DOMOS: ',i4,' - limit = ',i3)
      end
      subroutine mptran(q)
c
c     driving routine for mp2 gradient calculations
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/cigrad)
c
      common/maxlen/maxq
INCLUDE(common/vectrn)
c
      dimension q(*)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/infoa)
INCLUDE(common/mapper)
INCLUDE(common/statis)
c
      common/junke/ibl5,ibl54,ibl56,maxt,ires,ipass,nteff,
     1     npass1,npass2,lentri,nbuck,mloww,mhi,ntri,iacc,iontrn
INCLUDE(common/prnprn)
INCLUDE(common/restrj)
      character *8 hfscf
c     character *8 closed
      character*10 charwall
      data hfscf/'hfscf'/
c     data closed /'closed'/
c
c
      isecvv = isect(8)
      itypvv = 8
      iconvv = max(iconvv,9)
      if (.not.(mprest.gt.1 .or. opass6)) then
         if (nprint.ne.-5) then
            dum = cpulft(1)
            write (iwr,6010) dum ,charwall()
         end if
         if (nprint.eq.-100) write (iwr,6020) mprest
         if (nopk.eq.0) call caserr(
     +     'transformation not possible with supermatrix on')
c
c  restrict the transformation
c
         npass1 = max(nps1,1)
         npass2 = max(nps2,1)
         if (runtyp.eq.hfscf) then
            iscftp = max(iscftp,1)
         else
            iscftp = max(iscftp,4)
         end if
         if (mp3) iscftp = 99
c
         iontrn = 0
         lword4 = maxq
         call revise
      end if
c
c   do the 4-index transformation and set
c
      if (mprest.le.1) then
         call indxsy(q)
         oprn(4) = .false.
         call cpuwal(begin,ebegin)
         call indx2t(q)
         call indx4t(q)
         call timana(11)
         mprest = 2
         call revise
         if (nprint.eq.-100) write (iwr,6020) mprest
      end if
      return
 6010 format (/1x,'commence mp integral transformation at ',
     +        f8.2,' seconds',a10,' wall')
 6020 format (/1x,'moller-plesset restart option ',i4)
      end
      subroutine ver_mp2a(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/mp2a.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
