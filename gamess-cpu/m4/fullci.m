c 
c  $Author: jmht $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/fullci.m,v $
c  $State: Exp $
c  
      subroutine aabb(s, ic, itz, nstra, nstrb, isss, iperm, na, nb)
      implicit REAL  (a-h, o-z)
INCLUDE(common/iofile)
      dimension s(*), ic(*), itz(*), nstra(*), nstrb(*), iperm(8,8)
c
c     put s(aa,bb) = s(aa,bb)+s(bb,aa) for singlet wavefunctions
c     where we are using the effect of the onela and ciaa routines
c     are the same as the transpose of the onelb and cibb routines
c     
      if (na.ne.nb) then
        write(iwr,*) ' na, nb different in aabb ', na, nb
        call caserr('na and nb different in aabb')
      endif
c
c***  loop thru symmetry types
      do 10 isyma=1,8
         isymb=iperm(isyma,isss)
         if (isyma.lt.isymb) goto 10
c***  loop thru alpha strings of given sym
         mta=0
         do 20 ia=1,nstra(isyma)
            call getmt(na,isyma,ia,mta)
c***  loop thru beta strings of required sym
            mtb=0
            ibhi = nstrb(isymb)
            if (isyma.eq.isymb) ibhi = ia
            do 30 ib=1,ibhi
               call getmt(nb,isymb,ib,mtb)
               ipta = ic(mta) + itz(mtb)
               iptb = ic(mtb) + itz(mta)
               x = s(ipta) + s(iptb)
               s(ipta) = x
               s(iptb) = x
30          continue
20       continue
10     continue
c
      return
      end
      subroutine add1 (ioc1,m,n,m1,n1,itype,jw,nw,inter,
     +                 nxisym,m1n )
c..   
c..   adds one electron to a specified occupation ( ioc1 ). the symmetry
c..   of the orbital where the electron is added has to match nxisym
c..   the resulting string number is calculated (index)
c..   
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/ci)
INCLUDE(common/iofile)
      dimension ioc1 (n) ,ick(200), itype (m)
      dimension inter (n1,m1), jw (m1n,3)
      common /clocks/ lockio
INCLUDE(common/prnprn)
      if (odebug(32)) then
      call lock(lockio)
      write(iwr,*) ' add1 '
      call flushn(iwr)
      call unlockf(lockio)
      endif
c     
c     
      nw=0
      icn=1
      isign=1
      do 10 i1=1,m
         if (ioc1(icn).eq.i1) then
            isign=isign*(-1)
            ick(icn)=i1
            icn=icn+1
            goto 10
         endif
         ick(icn) = i1
         if ( itype (i1)  .ne. nxisym ) goto 10
_IF1(a)cvd$  noconcur
         nw=nw+1
         do 21 ir = icn+1,n
            ick(ir) = ioc1(ir-1)
 21      continue
c     
         index=1
_IF1(a)cvd$  noconcur
_IF1(a)cvd$  shortloop
_IF1(c)cdir$ shortloop
         do 26 in = 1, n
            index=index+inter (in,ick(in))
 26      continue
         jw (nw,1) = i1
         jw (nw,2) = isign
         jw (nw,3) = index
c         
 10   continue
      return
      end
      subroutine bnela (c,s,skv,m,na,itype,ic,inter,
     +     na1,m1,isss,iwa,jwa,ioc1,rops,icpu,ncpu,
     +     icref, isymop)
      implicit REAL  (a-h,o-z)
      common /cor   / core
      common /ftimes / t0,td,t1,t2,t3,t4,t5,t6,t7,t8
INCLUDE(common/cone)
INCLUDE(common/ci)
      dimension c(*),s(*),skv(m,m),itype(m),ic(*),icref(*)
      dimension iwa(na,3)
      dimension jwa(m1-na,4)
      dimension ioc1(na,na)
      dimension inter(na1,m1,2)
      dimension icga(200)
c     
c parallel version must be compiled reentrant with all external
c references inlined
c
      rops = 0.0d0
      do 10 isyma=1,8
         if (nstra(isyma).eq.0) goto 10
         napp = (nstra(isyma))
         nb = nstrb ( iperm ( isss,isyma ) )
c     
         mta = 0
         do 20 ia = icpu , napp , ncpu
            call getstr(na,isyma,ia,mta,icga)
            iapp = ic (mta)
c
c     loop thru killing occupied alpha orbitals in b vector
c
            call elim1 ( icga,ioc1,m,na,itype,iwa,nwa)
            do 30 iww = 1,nwa
               nxi    = iwa (iww,1)
               iparit = iwa (iww,2)
               nxisym = iperm(iwa (iww,3),isymop)
c
c     loop thru adding alpha orbitals to get ci alpha string
c
               call add1 (ioc1(1,iww),m,na,m1,na1,itype,jwa,mwa,
     1              inter,nxisym,m1-na)
c     
               do 40 jww = 1, mwa
                  nxj  = jwa (jww,1)
                  isign = iparit * jwa (jww,2)
                  iap = icref ( jwa (jww,3) )
                  xval =   isign * skv (nxi,nxj)
c..   the inner loop
                  if (xval.ne.0.0d0) then
                     rops = rops + nb
              call daxpy(nb,xval,c(iap+1),1,s(iapp+1), 1)
                  endif
c     
 40            continue
 30         continue
 20      continue
 10   continue
c     
      return
      end
      subroutine bnelb (c,s,skv,m,nb,itype,itz,inter,
     +     na1,m1,isss,iwb,jwb,ioc1,rops,icpu,ncpu,
     +     icref,isymop, maxaa)
      implicit REAL  (a-h,o-z)
      common /cor   / core
      common /ftimes / t0,td,t1,t2,t3,t4,t5,t6,t7
INCLUDE(common/cone)
INCLUDE(common/ci)
      common /scrtch/ temp(10000)
      dimension c(*),s(*),skv(m,m),itype(m),itz(*),icref(*)
      dimension iwb (nb,3)
      dimension jwb (m1-nb,4)
      dimension ioc1(nb,nb)
      dimension inter (na1,m1,2)
      dimension icgb (200), iptref(8)
_IF1()      dimension icga(200)
c
c parallel version should be conmpiled re-entrant with all
c external references inlined
c
      if (maxaa .gt. 10000) call dump('bnelb: hard dim failed',maxaa)
      do 5 isymm = 1,8
c     get lexical index of first string for symmetry required
         call getmt(na1-1,isymm,1,mta)
         iptref(isymm) = icref(mta)
 5    continue
c
      rops = 0.0d0
      ipnt = 0
      do 10 isymb  =1,8
         nbpp = nstrb ( isymb  )
         if (nbpp.eq.0) goto 10
c rjh ... force odd skips between betas ... need for cray2
         incbp = nbpp + mod(nbpp+1,2)
         isyma = iperm ( isss,isymb)
         napp = (nstra(isyma))
c     
         mtb = 0
         do 20 ib = icpu , nbpp ,ncpu
c
             call vclr(temp,1,napp)
c
            call getstr(nb,isymb,ib,mtb,icgb)
            ibpp = itz (mtb)
            call elim1 ( icgb,ioc1,m,nb,itype,iwb,nwb)
            do 30 iww = 1,nwb
               nxi    = iwb (iww,1)
               iparit = iwb (iww,2)
               nxisym = iperm(iwb (iww,3),isymop)
               call add1 (ioc1(1,iww),m,nb,m1,na1,itype,jwb,mwb,
     1              inter(1,1,2),nxisym,m1-nb)
c     
               do 40 jww = 1, mwb
                  nxj  = jwb (jww,1)
                  isign = iparit * jwb (jww,2)
                  ibp = itz ( jwb (jww,3) )
                  xval =   isign * skv (nxi,nxj)
c..   the inner loop
                  if (xval.ne.0.0d0) then
                     iaa = ipnt
                     rops = rops + napp
                     iaref = iptref(isyma)
                     incref = nstrb(iperm(isymop,isymb))
                     incref = incref + mod(incref+1,2)
              call daxpy(napp,xval,c(ibp+iaref),incref,temp,1)
                  endif
c     
 40            continue
 30         continue
            iaa = ipnt
            do 501 ia = 1,napp
               s(ibpp+iaa) = s(ibpp+iaa) + temp(ia)
               iaa = iaa + incbp
 501        continue
 20      continue
         ipnt = ipnt + napp * incbp
 10   continue
c     
      return
      end
      subroutine ciaa (c,s,zint,m,na,itype,ic,
     +                 isss,iwa,ind2,nn,
     +                 ic3e,iaptmp,xvltmp,npmax,rops,
     +     ipt2a,npt2a,nstr2,iadd2a,ladd2a,intr2,nn2,mm2,icpu,ncpu  )
c.    
c..   calculates the 2-e contribution coming from the alfa-alfa block
c
c mods by rjh to run as ncpu parallel processes with this as the icpu'th
c.    
      implicit REAL  (a-h,o-z)
      common /cor   / core
INCLUDE(common/cciab)
INCLUDE(common/cone)
INCLUDE(common/ci)
INCLUDE(common/iofile)
      dimension c(*),s(*),zint(*),itype(m),ic(*)
      dimension ic3e(*)
      dimension iwa(nn,4)
      dimension ind2(nn)
      dimension intr2(nn2,mm2)
      dimension icga(200)
      dimension iaptmp(npmax),xvltmp(npmax),ipt2a(nstr2,8),
     &     npt2a(nstr2,8),
     &     iadd2a(ladd2a,3)
c
      rops = 0.0d0
      mtpar = 0
c     
c now force blocking of integrals in symmetry blocks
c
c need to re-check the coarse grain parallel stuff ... IS broken !!
c     
      ibasr = 0
      rewind ntapes(1)
      do 1010 isymr = 1, 8
        if (nprsqr(isymr).eq.0) goto 1010
        call sread(ntapes(1), nprsqr(isymr)**2, zint)
c
      do 10 isyma=1,8
         if (nstra(isyma).eq.0) goto 10
         napp = (nstra(isyma))
         isymb = iperm (isyma,isss)
         nb = nstrb ( isymb )
c
c this is the loop that has been parallelized ... note that
c ciaa is compiled with all external references inlined and with
c the reentrant code option
c     
c         do 20 ia = icpu , napp , ncpu
         do 20 ia = 1 , napp
            mtpar = mtpar + 1
            if (mod(mtpar-1,ncpu).ne.icpu-1) goto 20  
            call getstr(na,isyma,ia,mta,icga)
            iapp = ic (mta)
            call elim2 ( icga,ind2,intr2,nn2,mm2,m,na,itype,iwa,nwa,nn)
            do 30 iww = 1,nwa
               klsym = iwa (iww,4)
               if (klsym .ne. isymr) goto 30
               iparit = iwa (iww,3)
               kind = iwa (iww,2)
               lind = iwa (iww,1)
               kl = ic3e ( (kind-1) * m + lind  ) - ibasr
               lk = ic3e ( (lind-1) * m + kind  ) - ibasr
c
               ipt = ipt2a(ind2(iww),klsym)
               mwa = npt2a(ind2(iww),klsym)
c     vector gather addresses
_IF1(a)cvd$  noconcur
               do 35 jww = 1, mwa
                  iaptmp(jww) = iadd2a(ipt+jww,3)
                  ij  = iadd2a(ipt+jww,1)
                  ijkl = ij + kl
                  ijlk = ij + lk
                  xvltmp(jww) =  iparit * iadd2a(ipt+jww,2) * 
     &                 ( zint (ijkl) - zint (ijlk) )
 35            continue
c     
               do 40 jww = 1,mwa
                  iap = iaptmp(jww)
                  xval = xvltmp(jww)
                  if (xval.ne.0.0d0) then
                     rops = rops + nb
              call daxpy(nb,xval,c(iap+1),1,s(iapp+1),1)
                  endif
 40            continue
c     
 30         continue
 20      continue
 10   continue
      ibasr = ibasr + nprsqr(isymr)**2
1010  continue
      rops = 2.0d0 * rops
c     
      return
      end
      subroutine ciab (c,s,zint,m,na,nb,itype,ic3e,nablk,nbblk,nblk2
     1   ,ic,itz,inter,na1,m1,jwa,jwb,d,e,maxpar,isss,maxsym,nwk,nwl,
     2   rop1,rop2)
c     
      implicit REAL  (a-h,o-z)
      common /cor   / core
INCLUDE(common/cone)
INCLUDE(common/ci)
INCLUDE(common/cciab)
INCLUDE(common/iofile)
c     
      dimension c(*),s(*),zint(*),itype(m),ic3e(*),ic(*),itz(*)
      dimension inter (na1,m1,2), jwa (nablk,3,m),
     1     jwb (nbblk,3,m) ,nwk(m), nwl (m) ,
     2     d (nblk2*maxpar) ,e (nblk2*maxpar)
      dimension icga1(200),icgb1(200)
_IF1()      dimension icgaa(200),icgbb(200)
      dimension parl(2500)
c     
      if (nbblk .gt. 2500) call dump('ciab: hard dim (2500) failed',
     +                               nbblk)
c     nprint = 0
      rop1 = 0.0d0
      rop2 = 0.0d0
c
      rewind ntapes(1)
      do 10101 isymr = 1,8
        if (nprsqr(isymr).eq.0) goto 10101
        call sread(ntapes(1), nprsqr(isymr)**2, zint)
c
      do 350 isyma=1,8
         if (ntra1(isyma).eq.0) goto 350
         nalock = (ntra1(isyma)-1)/nablk+1
c
         mtas = 0     
         do 340 ialock=1,nalock
            naa=nablk
            if (ialock.eq.nalock) naa=ntra1(isyma)-(nalock-1)*nablk
c           do 320 isymb=1,8
            isymb = iperm(isyma,iperm(isss,isymr))
c
               if (ntrb1(isymb).eq.0) goto 320
               nblock = (ntrb1(isymb)-1)/nbblk+1
c...  symmetry of intermediate state
c              isymk = iperm(isyma,isymb)
c...  symmetry of orbital excitations
c              isymr = iperm(isss,isymk)
               npairr = nprsqr (isymr)
               mtbs = 0
               do 310 iblock=1,nblock
                  nbb = nbblk
                  if (iblock.eq.nblock) 
     &             nbb = ntrb1(isymb) - (iblock-1)*nbblk
c...  number of strings in the intermediate (n-1) strings of
c...  this symmetry block
                  naabb = naa*nbb
c...  zero out the d matrix
                  do 70 i = 1, nblk2 * npairr
c                    e(i) = 0.0d00
                     d(i) = 0.0d00
 70               continue
c     
c...  loop over symmetry of k removal from alfa, which also fixes
c...  symmetry of l removal from beta
                  do 149 ksym = 1,maxsym
                     lsym = iperm ( isymr , ksym )
c.    
c..   loop over all orbitals of sym. ksym and add that orbital to all
c..   intermediate alfa strings
                     do 110 korb=1,m
                        if ( itype (korb) .ne. ksym ) goto 110
                        mtas1 = mtas
                        call orbadd (na,m1,na1,naa,korb,mtas1,
     &                       mta1,
     &                       icga1,isyma,inter,ic,
     &                       jwa(1,1,korb),nwk(korb),nablk )
 110                 continue
c..   loop over all orbitals of sym. lsym and add it to inter. beta strings
                     do 120 lorb = 1,m
                        if ( itype (lorb) .ne. lsym ) goto 120
                        mtbs1 = mtbs
                        call orbadd (nb,m1,na1,nbb,lorb,mtbs1,
     &                       mtb1,
     &                       icgb1,isymb,inter(1,1,2),itz,
     &                       jwb(1,1,lorb),nwl(lorb),nbblk)
 120                 continue
c...  now construct the integer indexing arrays used in construction of d
c..   a) loop over all k of sym. ksym
                     do 130 korb = 1,m
                        if ( itype (korb) .ne. ksym ) goto 130
                        if ( nwk (korb) .eq. 0 ) goto 130
                        nwwk = nwk (korb)
                        kof = (korb-1) * m
c..   b) loop over all l of sym. lsym
                        do 140 lorb = 1,m
                           if ( itype (lorb) .ne. lsym ) goto 140
                           if ( nwl (lorb) .eq. 0 ) goto 140
                           nwwl = nwl (lorb)
                           klof = (   ic3e (kof+lorb)    -1) * nblk2
                           rop1 = rop1 + nwwk*nwwl*3
                           do 141 iwwl = 1, nwwl
                               parl(iwwl) = dfloat(jwb(iwwl,2,lorb))
141                        continue
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(concurrent)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir no_recurrence
_IF()
_IF1(c)CMIC$ DO ALL IF (NWWK .GT. 15) SHARED(NWWK, KORB, NBB, NWWL, KLOF, LORB
_IF1(c)CMIC$1   , JWA, JWB, D, C) PRIVATE(IWWK, IAOF, DPAR, IAPOF, IWWL, INDT)
_IF1(c)CMIC$2   , NUMCHUNKS(4)
_ENDIF
                           do 150 iwwk = 1,nwwk
                              iaof = ( jwa(iwwk,1,korb) -1) *nbb
c                             dpar = float ( jwa(iwwk,2,korb) )
                              kpar = jwa(iwwk,2,korb)
                              iapof =  jwa (iwwk,3,korb)
c
                              if (kpar.gt.0) then
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir no_recurrence
                                do 160 iwwl = 1,nwwl
                                   indt = (klof+iaof) + jwb(iwwl,1,lorb)
                                   d(indt) = d(indt) + 
     &                                  c(iapof+ jwb(iwwl,3,lorb) ) *
     &                                   parl(iwwl)
 160                            continue
                              else
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir no_recurrence
                                do 161 iwwl = 1,nwwl
                                   indt = (klof+iaof) + jwb(iwwl,1,lorb)
                                   d(indt) = d(indt) - 
     &                                  c(iapof+ jwb(iwwl,3,lorb) ) *
     &                                   parl(iwwl)
 161                            continue
                              endif
c following replaces entire above if block ... note use of dpar
c                              do 160 iwwl = 1,nwwl
c                                 indt = (klof+iaof) + jwb(iwwl,1,lorb)
c                                 d(indt) = d(indt) + 
c     &                                c(iapof+ jwb(iwwl,3,lorb) ) *
c     &                                dpar * float(jwb(iwwl,2,lorb))
c 160                          continue
 150                       continue
 140                    continue
 130                 continue
 149              continue
c...  now matrix multiply with integrals
                  rop2 = rop2 + 2*naabb*npairr*npairr
ccray 2
c                  call mmxma (d,1,nblk2, zint),1,npairr,
c     1                 e,1,nblk2, naabb,npairr,npairr)
cnot cray 2
_IF1(c)                  call mxma(d,1,nblk2, zint,1,npairr,
_IFN1(c)               call mxmaa(d,1,nblk2, zint,1,npairr,
     1                e,1,nblk2, naabb,npairr,npairr)
c
c       call gettim(start,wall)
_IF1()*                  call dgemm('N','N',naabb,npairr,npairr,1.0d0,
_IF1()*     *                 d,nblk2,zint,npairr,0.0d0,
_IF1()*     *                 e,nblk2)
_IF1()c         if(nprint .lt. 100) then
_IF1()c           call gettim(end, wall)
_IF1()c           nprint = nprint + 1
_IF1()c           used = end-start
_IF1()c           write(6,10101) naabb, npairr, nblk2, used,
_IF1()c     $      float(2*naabb)*float(npairr*npairr)/(used*1.0d6)
_IF1()c10101      format(' dgemm: ',3i8,2d12.5)
_IF1()c         endif
c..   
                  do 449 ksym = 1,maxsym
                     lsym = iperm ( isymr , ksym )
c.    
c...  construct the integer indexing arrays used in construction of s
c..   a) loop over all k of sym. ksym
                     do 430 korb = 1,m
                        if ( itype (korb) .ne. ksym ) goto 430
                        if ( nwk (korb) .eq. 0 ) goto 430
                        nwwk = nwk (korb)
                        kof = (korb-1) * m
c..   b) loop over all l of sym. lsym
                        do 440 lorb = 1,m
                           if ( itype (lorb) .ne. lsym ) goto 440
                           if ( nwl (lorb) .eq. 0 ) goto 440
                           nwwl = nwl (lorb)
                           klof = (   ic3e (kof+lorb)    -1) * nblk2
                           rop1 = rop1 + nwwk*nwwl*3
                           do 441 iwwl = 1, nwwl
                               parl(iwwl) = dfloat(jwb(iwwl,2,lorb))
441                        continue
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(concurrent)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir no_recurrence
_IF()
_IF1(c)CMIC$ DO ALL IF (NWWK .GT. 15) SHARED(NWWK, KORB, NBB, NWWL, LORB, KLOF
_IF1(c)CMIC$1   , JWA, JWB, S, E) PRIVATE(IWWK, IAOF, DPAR, IAPOF, IWWL, INDE,
_IF1(c)CMIC$2   INDX)
_IF1(c)CMIC$3  NUMCHUNKS(4)
_ENDIF
                           do 450 iwwk = 1,nwwk
                              iaof = ( jwa(iwwk,1,korb) -1) *nbb
c                             dpar = float ( jwa(iwwk,2,korb) )
                              kpar = jwa(iwwk,2,korb)
                              iapof =  jwa (iwwk,3,korb)
c
                            if (kpar.gt.0) then
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir no_recurrence
                              do 460 iwwl = 1,nwwl
                                 inde = (klof+iaof) + jwb (iwwl,1,lorb)
                                 indx = iapof + jwb(iwwl,3,lorb)
                                 s(indx) = s(indx) + e(inde)*parl(iwwl)
 460                          continue
                            else
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(vector)
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir no_recurrence
                              do 461 iwwl = 1,nwwl
                                 inde = (klof+iaof) + jwb (iwwl,1,lorb)
                                 indx = iapof + jwb(iwwl,3,lorb)
                                 s(indx) = s(indx) - e(inde)*parl(iwwl)
 461                          continue
                            endif
c below replaces entire above if block ... note use of dpar
c                              do 460 iwwl = 1,nwwl
c                                 inde = (klof+iaof) + jwb (iwwl,1,lorb)
c                                 indx = iapof + jwb(iwwl,3,lorb)
c                                 s(indx) = s(indx) + e(inde) *
c     &                                dpar * float(jwb(iwwl,2,lorb))
c 460                          continue
c     
 450                       continue
 440                    continue
 430                 continue
 449              continue
                  mtbs = mtbs1
c...  end of current beta block
 310           continue
c...  end of beta symmetry
 320        continue
            mtas = mtas1
c...  end of alpha block
 340     continue
c...  end of alpha symmetry
 350  continue
10101 continue
c
      return
      end
      subroutine cibb (c,s,zint,m,nb,itype,itz,
     &     isss,iwb,ind2,nn,
     &     ic3e,temp,maxaa,iaptmp,xvltmp,npmax,rops,
     &     ipt2b,npt2b,nstr2,iadd2b,ladd2b,intr2,nn2,mm2)
c    +     ,icpu,ncpu)
c     
c..   calculates the 2-e contribution from the beta-beta block
c
c parallel version .... compile as reentrant with all externals
c inlined 
_IF1(a)c  ... bummer on the frigging alliant we need temp declared
_IF1(a)c locally for it to be cachable.
c     
      implicit REAL  (a-h,o-z)
INCLUDE(common/cciab)
      common /cor   / core
INCLUDE(common/cone)
INCLUDE(common/ci)
INCLUDE(common/iofile)
      dimension c(*),s(*),zint(*),itype(m),itz(*)
      dimension ic3e(*)
      dimension iwb (nn,4)
      dimension ind2(nn)
      dimension intr2(nn2,mm2)
      dimension temp(maxaa)
      dimension icgb(200),iaptmp(npmax),xvltmp(npmax)
      dimension ipt2b(nstr2,8),npt2b(nstr2,8),iadd2b(ladd2b,3)
c     
      rops = 0.0d0
c
      ibasr = 0
      rewind ntapes(1)
      do 1010 isymr = 1, 8
        if (nprsqr(isymr).eq.0) goto 1010
        call sread(ntapes(1), nprsqr(isymr)**2, zint)
c
      ipnt = 0
      do 10 isymb  = 1,8
         nbpp = nstrb ( isymb )
         if (nbpp.eq.0) goto 10
c ... increment is now forced odd for Cray-2
         incbp = nbpp + mod(nbpp+1,2)
         isyma = iperm (isymb,isss)
         napp = (nstra(isyma))
c     
         mtb = 0
c         do 20 ib = icpu , nbpp , ncpu
         do 20 ib = 1 , nbpp
            call getstr(nb,isymb,ib,mtb,icgb)
            ibpp = itz (mtb)
            call elim2 ( icgb,ind2,intr2,nn2,mm2,m,nb,itype,iwb,nwb,nn)
            do 21 iapp = 1,napp
               temp(iapp) = 0.0d0
 21         continue
            do 30 iww = 1,nwb
               klsym = iwb (iww,4)
               if (klsym.ne.isymr) goto 30
               iparit = iwb (iww,3)
               kind = iwb (iww,2)
               lind = iwb (iww,1)
               kl = ic3e ( (kind-1) * m + lind  ) - ibasr
               lk = ic3e ( (lind-1) * m + kind  ) - ibasr
               ipt = ipt2b(ind2(iww),klsym)
               mwb = npt2b(ind2(iww),klsym)
c     
c     vector compute required information
c     
_IF1(a)cvd$  noconcur
               do 40 jww = 1, mwb
                  ij  = iadd2b(ipt+jww,1)
                  ijkl = ij + kl
                  ijlk = ij + lk
                  xvltmp(jww) = iparit * iadd2b(ipt+jww,2) *
     &                 (zint (ijkl) - zint (ijlk))
                  iaptmp(jww) = ipnt + iadd2b(ipt+jww,3)
 40            continue
c     
c     accumulate sigma contributions
c     
               do 410 jww = 1,mwb
                  iaa = iaptmp(jww)
                  xval = xvltmp(jww)
                  if (xval.ne.0.0d0) then
c..   the inner loop
                     rops = rops + napp
                call daxpy(napp,xval,c(iaa),incbp,temp, 1)
                  endif
 410           continue
 30         continue
            iaa = ipnt
            do 25 ia = 1,napp
               s(ibpp+iaa) = s(ibpp+iaa) + temp(ia)
               iaa = iaa + incbp
 25         continue
 20      continue
         ipnt = ipnt + napp * incbp
 10   continue
c
      ibasr = ibasr + nprsqr(isymr)**2
1010  continue
      rops = rops * 2.0d0
c     
      return
      end
      subroutine ciini (q,iq)
      implicit REAL  (a-h,o-z)
      dimension q(*),iq(*)
INCLUDE(common/sizes)
      logical osymab
      common /clocks/ lockio
      common /mccore/ intrel,lword,ltop,lmax,lmin
      common /cor   / core
INCLUDE(common/cone)
INCLUDE(common/ci)
INCLUDE(common/cciab)
      common /ccpu / ncpu
INCLUDE(common/savem)
      common /ftimes / t(10)
      common /copcnt/ ropcnt(6)
INCLUDE(common/iofile)
INCLUDE(common/prnprn)
      dimension c(1),s(1) ,b(1),hb(1)
_IF1()      dimension icg(200)
c
      save
c
      iprad = 0
      icall = 0
      osymab = .true.
c
      if(odebug(32))
     + write(iwr,*) ' icall ', icall
c
      if (icall.eq.0) then
_IF1(a)cvd$  noconcur
         do 33 i = 1,6
            ropcnt(i) = 0.0d0
 33      continue
      endif
      inter = icori((nna+1)*(nact+1)*2)
      intr2 = icori((nna-1)*(nact+1)*2)
      call minter (iq(inter),nna+1,nact+1,nna,nnb,nact)
      call minter (iq(intr2),nna-1,nact+1,nna-2,nnb-2,nact)
c
      if (icall.eq.0) then
         mm = (nact*(nact+1))/2
         ic2e = icori(mm)
         ic3e = icori(mm)
         call mice (iq(ic2e),iq(ic3e),nact,itype,nint)
c     
         ic2esq = icori (nact*nact)
         ic3esq = icori (nact*nact)
         call micesq ( iq(ic2esq),iq(ic3esq),nact,itype,nintsq)
      endif
c
c compute strings once and for all
c
      if (icall.eq.0) call makstr(nstraa,nstrbb,nstra1,nstrb1)
      ic = icori(nstraa)
      itz = icori(nstrbb)
c
c make ci addressing arrays ic and itz ... with odd offset for cibb
c nci = size of ci ... nnci = size of vector with padding 
c
      call mic (iq(ic),iq(itz),nna,nnb,isss,nci,nnci)
c
c compute info to eliminate add2
c
      nstma2 = nstrng(nna-2,nact)
      nstmb2 = nstrng(nnb-2,nact)
      if (nna-2.ge.0) then
         maxss = (nact-nna+2)*(nact-nna+1)/2
         ipt2a = icori(nstma2*8)
         npt2a = icori(nstma2*8)
         ladd2a = maxss*nstma2
         iadd2a = icori(ladd2a*3)
         call mkadd2(nact,nna,itype,iperm,iq(ic2esq),
     &     iq(iadd2a),ladd2a,
     &     iq(ipt2a),iq(npt2a),nstma2,iq(inter),
     &     nna+1,nact+1,iq(ic),iused,
     &     iq(intr2),nna-1,nact+1)
         if(outon)write(iwr,38) nstma2*16+ladd2a*3
 38      format(/' integer core used for alpha add2 ',i10)
      endif
      maxss = (nact-nnb+2)*(nact-nnb+1)/2
      if (nnb-2.ge.0) then
         ipt2b = icori(nstmb2*8)
         npt2b = icori(nstmb2*8)
         ladd2b = maxss*nstmb2
         iadd2b = icori(ladd2b*3)
         call mkadd2(nact,nnb,itype,iperm,iq(ic2esq),
     &        iq(iadd2b),ladd2b,
     &        iq(ipt2b),iq(npt2b),nstmb2,iq(inter+(nna+1)*(nact+1)),
     &        nna+1,nact+1,iq(itz),iused,iq(intr2+(nna-1)*(nact+1)),
     &        nna-1,nact+1)
         if(outon)write(iwr,39) nstmb2*16+ladd2b*3
 39      format(' integer core used for beta  add2 ',i10/)
      endif
c
c count n-2 intermediate states
c
      na2 = nstrng(nna-2,nact)*nstrng(nnb,nact)
      nb2 = nstrng(nnb-2,nact)*nstrng(nna,nact)
      na1nb1 = nstrng(nna-1,nact)*nstrng(nnb-1,nact)
c
      if (icall.eq.0) then
         if(outon)write (iwr,40) nstra,nstrb,npair,nint
 40      format(' alpha   string by sym: ',8i6
     1        /' beta    string by sym: ',8i6
     2        /' orbital  pairs by sym: ',8i6
     3        /' two-elec integrals   : ',i8/)
         if(outon)write (iwr,41) ntra1,ntrb1,nprsqr,nintsq
 41      format(' alpha-1 string by sym: ',8i6
     1        /' beta-1  string by sym: ',8i6
     2        /' orbital square by sym: ',8i6
     3        /' two-elec squares     : ',i8/)
      endif
      junk = nstraa*nstrbb
      if(outon)write (iwr,50) nci,nnci,junk,na2,nb2,na1nb1
50    format(' no. of determinants in ci : ',i10/
     &       ' size of padded ci vector  : ',i10//
     1       ' no. of na+nb      states: ',i10/
     &       ' no. of na-2  nb   states: ',i10/
     &       ' no. of nb-2  na   states: ',i10/
     &       ' no. of na-1, nb-1 states: ',i10/)
c
      nci = nnci
c
      if (iprad.le.0) goto 110
      if(outon)write (iwr,60)
60    format(1x,'addressing arrays'/' -----------------'/)
      if(outon)write (iwr,70) (iq(ic2esq-1+i),i=1,nact*nact)
70    format(1x,'ic2esq:'/100(14i6/) )
      if(outon)write (iwr,80) (iq(ic3esq-1+i),i=1,nact*nact)
80    format(1x,'ic3esq:'/100(14i6/) )
      if(outon)write (iwr,90) (iq(ic-1+i),i=1,nstraa)
90    format(1x,'ic:'/100(14i6/) )
      if(outon)write (iwr,100) (iq(itz-1+i),i=1,nstrbb)
100   format(1x,'itz:'/100(14i6/) )
110   continue
c
      if(outon)write(iwr,195)
195   format(1x,36('*'))
      maxaa=0
      maxbb=0
c..   for the n-1 strings
      mxaa1 = 0
      mxbb1 = 0
_IF1(a)cvd$  noconcur
      do 120 i=1,8
      mxaa1 = max (mxaa1,ntra1(i))
      mxbb1 = max (mxbb1,ntrb1(i))
      maxaa=max(maxaa,nstra(i))
120   maxbb=max(maxbb,nstrb(i))
c
c... max no of orbital pairs
      maxpar=0
c...   for the square integral matrix
      mxsqr = 0
_IF1(a)cvd$  noconcur
      do 130 i=1,8
      mxsqr = max (mxsqr,nprsqr(i))
130   maxpar = max(maxpar,npair(i))
_IF1()c     write (iwr,*) 'in ciini  mxsqr', mxsqr
c
c     Make space for 1-electron density matrices
c
      idena = icorr(npair(1))
      idenb = icorr(npair(1))
      call vclr(q(idena),1,npair(1))
      call vclr(q(idenb),1,npair(1))
c     izint = 1
c     iskv = 1
      icall = 1
      return
c
      entry loader(q,iq,ibase)
c
c     call ciini to be (to define the required arrays etc),
c     reset the core base, then loader to load the integrals at the
c     beginning of core, and then ciini multiple times without
c     loading the integrals or computing the strings each time
c
c     ibase is the real base to which core can be reset without
c     destroying the integrals or addressing arrays
c
c...  load integrals into memory ... zint and skv only needed
c     for slow spin adatped diagonals ... change here and in load
c     if wanted and see below where diags is called
      mm = (nact*(nact+1))/2
      ic2e = icori(mm)
      ic3e = icori(mm)
      call mice (iq(ic2e),iq(ic3e),nact,itype,nint)
c
      ic2esq = icori (nact*nact)
      ic3esq = icori (nact*nact)
      call micesq ( iq(ic2esq),iq(ic3esq),nact,itype,nintsq)
c
      if(odebug(32)) write(iwr,*) ' nintsq, npair(1),mxsqr = ',
     + nintsq,npair(1),mxsqr
      idnt = icorr(mxsqr**2)
      iskv2 = icorr(npair(1))
      call load (q(idnt),itype,iq(ic3e),mm,nact,
     2     iq(ic2esq),iq(ic3esq),mxsqr**2,q(iskv2))
      ibase = icorr(0)
      if(odebug(32)) write(iwr,*) ' ibase = ',ibase
      return
c
c
      entry fdiagl (q,iq,s)
_IF(alliant)
*mdc*if alliant
*       call set_resource_type(3, -1, 10)
*mdc*endif
_ENDIF
c
c this diags much faster and computes actual diagonal element
c rather than occupancy averaged one.
c
       call timer(t(1))
       ih = icorr(nact)
       ip = icorr(nact**2)
       iqq = icorr(nact**2)
       ieaa = icorr(maxaa)
       iebb = icorr(maxbb)
       ioca = icori(nna*maxaa)
       iocb = icori(nnb*maxbb)
       imta = icori(maxaa)
       maxeab = min(icorrm()/nact,maxaa)
       if (maxeab.lt.1) call dump(' maxeab ',maxeab)
       ieab = icorr(maxeab*nact)
       call vclr(s,1,nci)
       call newdgs(iq(ic2esq),iq(ic3esq),iq(ic),s,q(iskv2),q(idnt),
     &      q(ih),q(ip),q(iqq),q(ieab),q(ieaa),q(iebb),iq(ioca),
     &      iq(iocb),iq(imta),iq(ic3e),nact,nna,nnb,maxaa,maxbb,
     &      isss,maxeab,itype)
       call corlsr(ih)
       call timer(t(2))
c
_IF(alliant)
*mdc*if alliant
*       call set_resource_type(2, -1, -1)
*mdc*endif
_ENDIF
      return
c
      entry guessv(q,iq,c,v)
      call makges(c,v,nguess,nci,nact,nna,nnb,iq(ic),iq(itz),
     &            iq(inter))
      return
c
      entry sadapt (q,iq,c,imin)
      call fspnad (c,imin,nact,nna,nnb,iq(ic),iq(itz),isss,
     &             iq(inter),nna+1,nact+1,nci)
      return
c
      entry fsigma (q,iq,c,s)
_IF(alliant)
*mdc*if alliant
*       call set_resource_type(3, -1, 10)
*mdc*endif
_ENDIF
      icall = icall+1
c
      do 150 i = 1, nci
         s(i) = 0.0d0
150   continue
      if (ischem.gt.0) goto 169
 169    continue
c...  taking care of the one electron contribution
c..  make sure the s vector is not zeroed out later to wipe out this
c...   contribution.
c...  first the alpha contribution
      m1n = nact-nna+1
      kkiwa = nna*3
      kkjwa = m1n*3
      kkoc1 = nna*nna
      iwa = icori (kkiwa * ncpu)
      jwa = icori (kkjwa * ncpu)
      ioc1 = icori (kkoc1 * ncpu)
      iops = icorr (ncpu)
c
_IF1()c     write(iwr,*) ' call onela '
      call flushn(iwr)
      if (nna.ge.1) then
      call timer(t(1))
      m1 = nact+1
      na1 = nna+1
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  cncall
_IF1(c)cfpp$ nodepchk
_IF1(c)cfpp$ cncall
      do 1691 icpu = 1,ncpu
        iwapt = iwa + (icpu-1)*kkiwa
        jwapt = jwa + (icpu-1)*kkjwa
        iocpt = ioc1+ (icpu-1)*kkoc1
        ioppt = iops+ (icpu-1)
      call onela ( c,s,q(iskv2),nact,nna,itype,iq(ic),iq(inter),
     1     na1,m1,isss,iq(iwapt),iq(jwapt),iq(iocpt),
     &     iq(ic3e),q(ioppt),icpu,ncpu)
 1691 continue
c      do 1691 icpu = 1,ncpu
c      call onela(c,s,q(iskv2),nact,nna,itype,iq(ic),iq(itz),iq(inter),
c     1     nna+1,nact+1,isss,iq(iwa + (icpu-1)*kkiwa),
c     &     iq(jwa + (icpu-1)*kkjwa),iq(ioc1 + (icpu-1)*kkoc1),
c     &     iq(ic3e),q(iops-1+icpu),icpu,ncpu)
c 1691 continue
      call timer(t(3))
      do 16911 icpu = 1,ncpu
         ropcnt(1) = ropcnt(1) + q(iops-1+icpu)
16911 continue
      endif
      call corlsi (iwa)
c
      nn= nna * (nna-1) /2
      npmax = (nact*(nact-1))/2
      kkiwa = nn*4
      kkind2 = nn
      kkap = npmax
      kkxval = npmax
      ineed = kkiwa + kkind2 + kkap + intrel*kkxval
      ineed = ineed*ncpu
      ihave =  icorim()
      if ( ineed .gt. ihave ) then
        write (iwr,171) ineed,ihave
 171    format (2x,'not enough core for ciaa routine',2i9)
        call dump(' ciaa core ',ineed)
      endif
      iwa = icori (kkiwa * ncpu)
      ind2 = icori (kkind2 * ncpu)
      iaptmp = icori(kkap * ncpu)
      ixval = icorr (kkxval * ncpu)
      iops = icorr (ncpu)
c
_IF1()c     write(iwr,*)' call ciaa'
      call flushn(iwr)
      if (nna.ge.2) then
      call timer(t(1))
c parallel version broken due to io in ciaa .. ha ha
_IF1(a)c vd$  nodepchk
_IF1(a)c vd$  cncall
_IF1(c)c fpp$ nodepchk
_IF1(c)c fpp$ cncall
      do 1711 icpu = 1,ncpu
      call ciaa  (c,s,q(idnt),nact,nna,itype,iq(ic),
     &            isss,iq(iwa + (icpu-1)*kkiwa),
     &        iq(ind2 + (icpu-1)*kkind2),
     &        nn,iq(ic3esq),iq(iaptmp + (icpu-1)*kkap),
     &        q(ixval + (icpu-1)*kkxval),npmax,
     &        q(iops-1+icpu),iq(ipt2a),iq(npt2a),nstma2,
     &        iq(iadd2a),ladd2a,
     &        iq(intr2),nna-1,nact+1,icpu,ncpu )
 1711 continue
      call timer(t(5))
      do 17111 icpu = 1,ncpu
         ropcnt(3) = ropcnt(3) + q(iops-1+icpu)
17111 continue
      endif
      call corlsi(iwa)
c
_IF1()c     write(iwr,*) ' s block after onela, ciaa '
_IF1()c     call foutp(s,1,10,1,10,nstra(1)+mod(nstra(1),2),nstra(1),1,iwr)
      if (nna.eq.nnb .and.  osymab) then
        call aabb(s, iq(ic), iq(itz), nstra, nstrb, isss, iperm, 
     +            nna, nnb)
c
      else
c
      m1n = nact-nnb+1
      kkiwb = nnb*3
      kkjwb = m1n*3
      kkoc1 = nnb*nnb
      iwb = icori (kkiwb * ncpu)
      jwb = icori (kkjwb * ncpu)
      ioc1 = icori (kkoc1 * ncpu)
      iops = icorr (ncpu)
c
_IF1()c     write(iwr,*) ' call onelb '
      call flushn(iwr)
      if (nnb.ge.1) then
      call timer(t(1))
_IF1(a)ccvd$  nodepchk
_IF1(a)cvd$  cncall
_IF1(c)cfpp$ nodepchk
_IF1(c)cfpp$ cncall
      do 1692 icpu = 1,ncpu
      call onelb (c,s,q(iskv2),nact,nnb,itype,iq(itz),iq(inter),
     1     nna+1,nact+1,isss,iq(iwb + (icpu-1)*kkiwb),
     &     iq(jwb + (icpu-1)*kkjwb),iq(ioc1 + (icpu-1)*kkoc1),
     &     iq(ic3e),q(iops-1+icpu),icpu,ncpu)
 1692 continue
      call timer(t(4))
      do 16922 icpu = 1,ncpu
         ropcnt(2) = ropcnt(2) + q(iops-1+icpu)
16922 continue
      endif
      call corlsi (iwb)
c
c....   the beta- beta  block
      nn= nnb * (nnb-1) /2
      kkiwb = nn*4
      kkind2 = nn
      kkap = npmax
      kkxval = npmax
      kktmp = maxaa
      ineed = kkiwb + kkind2 + kkap + intrel*(kkxval+kktmp)
      ineed = ineed * ncpu
      ihave =  icorim()
      if ( ineed .gt. ihave ) then
        write (iwr,172) ineed,ihave
 172    format (2x,'not enough core for cibb routine',2i9)
        call dump(' core in cibb ',ineed)
      endif
      iwb = icori (kkiwb * ncpu)
      ind2 = icori (kkind2 * ncpu)
      iaptmp = icori(kkap * ncpu)
      ixval = icorr(kkxval * ncpu)
      itemp = icorr (kktmp * ncpu)
      iops = icorr(ncpu)
c....
_IF1()c     write(iwr,*)' call cibb'
      call flushn(iwr)
      if (nnb.ge.2) then
      call timer(t(1))
_IF1(a)c vd$  nodepchk
_IF1(a)c vd$  cncall
_IF1(c)c fpp$ nodepchk
_IF1(c)c fpp$ cncall
      do 1721 icpu = 1,ncpu
      call cibb  (c,s,q(idnt),nact,nnb,itype,iq(itz),
     &     isss,iq(iwb + (icpu-1)*kkiwb),
     &     iq(ind2 + (icpu-1)*kkind2),
     &     nn,iq(ic3esq),q(itemp+(icpu-1)*kktmp),maxaa,
     &     iq(iaptmp + (icpu-1)*kkap),q(ixval + (icpu-1)*kkxval),npmax,
     &     q(iops-1+icpu),iq(ipt2b),iq(npt2b),nstmb2,iq(iadd2b),ladd2b,
     &     iq(intr2+(nna-1)*(nact+1)),nna-1,nact+1)
c    &     ,icpu,ncpu)
 1721 continue
      call timer(t(6))
      do 17211 icpu = 1,ncpu
         ropcnt(4) = ropcnt(4) + q(iops-1+icpu)
17211 continue
      endif
      call corlsi (iwb)
      endif
_IF1()c     write(iwr,*) ' s block after onelb, cibb '
_IF1()c     call foutp(s,1,10,1,10,nstra(1)+mod(nstra(1),2),nstra(1),1,iwr)
c....
c...   the all new "  ciab  " routine allocation for core memory
      maxsym = 1
      do 173 ii = 1,nact
 173  maxsym = max(maxsym,itype(ii))
      if ( maxsym .ge. 5 ) then
        maxsym=8
      else if ( maxsym .ge. 2 ) then
        maxsym=4
      endif
c
      maxqq = icorrm()
c 200000 ... smaller than cache on the fx2800
c     maxqq = min(maxqq, 200000)
      nablk = ((mxaa1/2)*2)+1
      nbblk = ((mxbb1/2)*2)+1
180   nblk2 = nablk*nbblk
      jj = (nblk2*mxsqr*2) + 3 * nact * (nablk + nbblk)/intrel +
     &   2 * nact /intrel + 2* nbblk / intrel
      if (jj.gt.maxqq) then
        if (nablk.le.1 .and. nbblk.le.1) then
          call dump('ciab failure',-1)
        else if (nablk.gt.1) then
          nablk = nablk-1
        else
          nbblk = nbblk-1
        endif
        goto 180
      endif
***      if (nablk.eq.1) goto 190
***200   nablk = nablk-1
***      goto 180
***190   nbblk = nbblk-2
***      goto 180
c..     allocate core now and then call ciab routie
      iwa = icori ( nact * nablk * 3 )
      iwb = icori ( nact * nbblk * 3 )
      nwk = icori ( nact )
      nwl = icori ( nact )
      id  = icorr ( mxsqr * nblk2 )
      ie  = icorr ( mxsqr * nblk2 )
_IF1()c     write(iwr,*) ' call ciab: nablk=',nablk,', nbblk=',nbblk
_IF1()c     write(iwr,*)' call ciab'
      call flushn(iwr)
      call timer(t(1))
      if (nna.ge.1 .and. nnb.ge.1)
     &  call ciab (c,s,q(idnt),nact,nna,nnb,itype,iq(ic3esq),
     1      nablk,nbblk,nblk2,iq(ic),iq(itz),iq(inter),nna+1,nact+1,
     2      iq(iwa),iq(iwb),q(id),q(ie),mxsqr,isss,maxsym,
     3      iq(nwk),iq(nwl),rop1,rop2)
      ropcnt(5) = ropcnt(5) + rop1
      ropcnt(6) = ropcnt(6) + rop2
      call timer(t(7))
      call corlsi (iwa)
_IF1()c     write(iwr,*) ' s block after ciab '
_IF1()c     call foutp(s,1,10,1,10,nstra(1)+mod(nstra(1),2),nstra(1),1,iwr)
c
      do 1501 i=1,nci
1501   s(i) = s(i) + c(i)*core
c     call zerpad(s, nstra, nstrb, nci, isss, iperm)
      call flushn(iwr)
_IF(alliant)
*mdc*if alliant
*       call set_resource_type(2, -1, -1)
*mdc*endif
_ENDIF
      return
c
c-----------------------------------------------------------------------
c
      entry fnatorb (q,iq,c)
c
c     This thing constructs the 1-electron density matrices from the
c     CI vector. The method is simply to use the machinery to add the
c     1-electron contributions to the matrix vector product (see
c     onela and onelb) but now add the products of CI-coefficients
c     onto the 1-electron quantity instead. So in actual fact the main
c     components are:
c
c     - fnatorb - a modified version of fsigma
c     - dena    - a modified version of onela
c     - denb    - a modified version of onelb
c
c     Note that the density matrices are given in terms of the active
c     starting (SCF) orbitals. So the blocks associated with any frozen
c     orbitals are not there.
c
c     This should work...
c
_IF(alliant)
*mdc*if alliant
*       call set_resource_type(3, -1, 10)
*mdc*endif
_ENDIF
      icall = icall+1
c
c...  first the alpha contribution
      m1n = nact-nna+1
      kkiwa = nna*3
      kkjwa = m1n*3
      kkoc1 = nna*nna
      iwa = icori (kkiwa * ncpu)
      jwa = icori (kkjwa * ncpu)
      ioc1 = icori (kkoc1 * ncpu)
      iops = icorr (ncpu)
c
_IF1()c     write(iwr,*) ' call onela '
      call flushn(iwr)
      if (nna.ge.1) then
      call timer(t(1))
      m1 = nact+1
      na1 = nna+1
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  cncall
_IF1(c)cfpp$ nodepchk
_IF1(c)cfpp$ cncall
      do  icpu = 1,ncpu
        iwapt = iwa + (icpu-1)*kkiwa
        jwapt = jwa + (icpu-1)*kkjwa
        iocpt = ioc1+ (icpu-1)*kkoc1
        ioppt = iops+ (icpu-1)
        call dena ( c,q(idena),nact,nna,itype,iq(ic),iq(inter),
     1       na1,m1,isss,iq(iwapt),iq(jwapt),iq(iocpt),
     &       iq(ic3e),q(ioppt),icpu,ncpu)
      enddo
c      do 1691 icpu = 1,ncpu
c      call onela(c,s,q(iskv2),nact,nna,itype,iq(ic),iq(itz),iq(inter),
c     1     nna+1,nact+1,isss,iq(iwa + (icpu-1)*kkiwa),
c     &     iq(jwa + (icpu-1)*kkjwa),iq(ioc1 + (icpu-1)*kkoc1),
c     &     iq(ic3e),q(iops-1+icpu),icpu,ncpu)
c 1691 continue
      call timer(t(3))
      do  icpu = 1,ncpu
         ropcnt(1) = ropcnt(1) + q(iops-1+icpu)
      enddo
      endif
      call corlsi (iwa)
c
c
_IF1()c     write(iwr,*) ' s block after onela, ciaa '
_IF1()c     call foutp(s,1,10,1,10,nstra(1)+mod(nstra(1),2),nstra(1),1,iwr)
      if (nna.eq.nnb .and.  osymab) then
        call dcopy(npair(1),q(idena),1,q(idenb),1)
c
      else
c
      m1n = nact-nnb+1
      kkiwb = nnb*3
      kkjwb = m1n*3
      kkoc1 = nnb*nnb
      iwb = icori (kkiwb * ncpu)
      jwb = icori (kkjwb * ncpu)
      ioc1 = icori (kkoc1 * ncpu)
      iops = icorr (ncpu)
c
_IF1()c     write(iwr,*) ' call onelb '
      call flushn(iwr)
      if (nnb.ge.1) then
      call timer(t(1))
_IF1(a)ccvd$  nodepchk
_IF1(a)cvd$  cncall
_IF1(c)cfpp$ nodepchk
_IF1(c)cfpp$ cncall
      do  icpu = 1,ncpu
        call denb (c,q(idenb),nact,nnb,itype,iq(itz),iq(inter),
     1       nna+1,nact+1,isss,iq(iwb + (icpu-1)*kkiwb),
     &       iq(jwb + (icpu-1)*kkjwb),iq(ioc1 + (icpu-1)*kkoc1),
     &       iq(ic3e),q(iops-1+icpu),icpu,ncpu)
      enddo
      call timer(t(4))
      do  icpu = 1,ncpu
         ropcnt(2) = ropcnt(2) + q(iops-1+icpu)
      enddo
      endif
      call corlsi (iwb)
      endif
c
      idenaa = icorr(nact*(nact+1)/2)
      idenbb = icorr(nact*(nact+1)/2)
      ij = 0
      do i = 1, nact
        do j = 1, i
          ij = ij + 1
          q(idenaa+ij-1) = q(idena+iq(ic3e+ij-1)-1)
          q(idenbb+ij-1) = q(idenb+iq(ic3e+ij-1)-1)
          if (itype(i).ne.itype(j)) then
            q(idenaa+ij-1) = 0.0d0
            q(idenbb+ij-1) = 0.0d0
          endif
          if (i.ne.j) then
            q(idenaa+ij-1) = 0.5d0*q(idenaa+ij-1)
            q(idenbb+ij-1) = 0.5d0*q(idenbb+ij-1)
          endif
        enddo
      enddo
      iiky   = icori(nact)
      iilifq = icori(nact)
      iocca  = icorr(ncor+nact)
      ioccb  = icorr(ncor+nact)
      itrns  = icorr(nact*nact)
      do i = 0, ncor-1
        q(iocca+i) = 1.0d0
        q(ioccb+i) = 1.0d0
      enddo
      do i = 1, nact
        iq(iiky+i-1)   = i*(i-1)/2
        iq(iilifq+i-1) = (i-1)*nact
      enddo
c
c     finalize alpha spin density matrix
c
      call jacobi(q(idenaa),iq(iiky),nact,q(itrns),iq(iilifq),nact,
     +            q(iocca+ncor),2,0,1.0d-10)
      call fmknatorb(q,iq,nact,ncor,q(itrns),q(iocca),1)
c
c     finalize beta spin density matrix
c
      call jacobi(q(idenbb),iq(iiky),nact,q(itrns),iq(iilifq),nact,
     +            q(ioccb+ncor),2,0,1.0d-10)
      call fmknatorb(q,iq,nact,ncor,q(itrns),q(ioccb),2)
      call corlsi (idenaa)
c
_IF(alliant)
*mdc*if alliant
*       call set_resource_type(2, -1, -1)
*mdc*endif
_ENDIF
      return
c
c-----------------------------------------------------------------------
c
      entry makeb (q,iq,isref,isymop,hb,c,b,ioptio)
_IF(alliant)
*mdc*if alliant
*       call set_resource_type(3, -1, 10)
*mdc*endif
_ENDIF
c
c     make rhs vector for the response equations
c     isref - symmetry of reference state
c     c - eigenvector from ci
c     b - required vector - rhs of response equations
c     hb - input full square of one-electron perturbation
c
c     ciini is assumed to have been last called with isss set to the
c     symmetry of the pertubed state. all we need to do is compute
c     the ic and itz vectors for the reference state
c
      if (isss.ne.iperm(isref,isymop)) then
         write(iwr,*) ' makeb: isss, isref, isymop ',isss, isref, isymop
         call caserr('fatal error in fullci: makeb')
      endif
      icref = icori(nstraa)
      itzref = icori(nstrbb)
      call mic (iq(icref),iq(itzref),nna,nnb,
     +          isref,ncirf,nncirf)
_IF1()c     write(iwr,*) ' ncirf, nncirf ', ncirf, nncirf
c
             call vclr(b,1,nci)
c
c...  first the alpha contribution
      m1n = nact-nna+1
      kkiwa = nna*3
      kkjwa = m1n*3
      kkoc1 = nna*nna
      iwa = icori (kkiwa * ncpu)
      jwa = icori (kkjwa * ncpu)
      ioc1 = icori (kkoc1 * ncpu)
      iops = icorr (ncpu)
c
_IF1()c     write(iwr,*) ' makeb: norm of reference vector ', ncirf,
_IF1()c    $  sdot(ncirf, c, 1, c, 1)
      call flushn(iwr)
c
      if (nna.ge.1) then
      call timer(t(1))
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  cncall
_IF1(c)cfpp$ nodepchk
_IF1(c)cfpp$ cncall
      do 11691 icpu = 1,ncpu
      call bnela ( c,b,hb,nact,nna,itype,iq(ic),iq(inter),
     1     nna+1,nact+1,isss,iq(iwa + (icpu-1)*kkiwa),
     &     iq(jwa + (icpu-1)*kkjwa),iq(ioc1 + (icpu-1)*kkoc1),
     &     q(iops-1+icpu),icpu,ncpu,iq(icref),
     $        isymop)
11691 continue
      call timer(t(3))
      do 16912 icpu = 1,ncpu
         ropcnt(1) = ropcnt(1) + q(iops-1+icpu)
16912 continue
      endif
      call corlsi (iwa)
      if (nna.eq.nnb .and.  osymab) then
        call aabb(b, iq(ic), iq(itz), nstra, nstrb, isss, 
     +            iperm, nna, nnb)
      else
c...   now the beta contribution
_IF1()c      write(iwr,*) ' call bnelb'
        call flushn(iwr)
        m1n = nact-nnb+1
        kkiwb = nnb*3
        kkjwb = m1n*3
        kkoc1 = nnb*nnb
        iwb = icori (kkiwb * ncpu)
        jwb = icori (kkjwb * ncpu)
        ioc1 = icori (kkoc1 * ncpu)
        iops = icorr (ncpu)
c
        if (nnb.ge.1) then
        call timer(t(1))
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  cncall
_IF1(c)cfpp$ nodepchk
_IF1(c)cfpp$ cncall
        do 16931 icpu = 1,ncpu
        call bnelb ( c,b,hb,nact,nnb,itype,iq(itz),iq(inter),
     1       nna+1,nact+1,isss,iq(iwb + (icpu-1)*kkiwb),
     &       iq(jwb + (icpu-1)*kkjwb),iq(ioc1 + (icpu-1)*kkoc1),
     &       q(iops-1+icpu),icpu,ncpu,iq(icref), isymop,
     &       maxaa)
16931   continue
        call timer(t(4))
        do 16932 icpu = 1,ncpu
           ropcnt(2) = ropcnt(2) + q(iops-1+icpu)
16932   continue
        endif
      endif
      call corlsi (icref)
c
c     finally project out component of the ci vector
c
_IF1()c     write(iwr,*) ' makeb: ', sdot(nci, b, 1, b, 1)
      call flushn(iwr)
      if (ioptio .ne. 0 .and. isymop.eq.1) then
         scale = ddot(nci,c,1,b,1)
_IF1()c        write(iwr,*) ' scale = ',scale
         call flushn(iwr)
         call daxpy(nci,-scale,c,1,b,1)
      endif
_IF1()c     write(iwr,*) ' this is the b vector'
_IF1()c     call vecpr(b,1.0d-2,nna,nnb,isss,itype,iq(ic),iq(itz))
_IF(alliant)
*mdc*if alliant
*       call set_resource_type(2, -1, -1)
*mdc*endif
_ENDIF
      return
c
      entry vecprf (q,iq,s,thresh,threshp)
      call vecpr (s,thresh,nna,nnb,isss,iq(ic),iq(itz))
      if (opunch(15)) then
       open(ipu,file='civecs.ascii',form='formatted',status='unknown')
c
       call vecpun(s,threshp,nna,nnb,isss,iq(ic),iq(itz))
      endif
      return
c
      entry singen (q,iq,s)
      call single (s,nna,nnb,isss,iq(ic),iq(itz))
      return
c
      entry ciinit(q,iq)
      iprad = 0
      icall = 0
      osymab = .true.
      return
c
      end
c
c-----------------------------------------------------------------------
c
      subroutine fmknatorb(q,iq,nact,ncor,trns,docc,ispin)
      implicit none
c
c     Given the transformation and occupation number of the natural
c     orbitals do:
c     1. Read in the present SCF vectors
c     2. Apply the transformation to the active orbitals
c     3. Dump the natural orbitals inclusive occupation number to
c        a suitable section (this step is not implemented at 
c        present)
c
c     - ispin .eq. 1 - alpha spin
c     - ispin .eq. 2 - beta spin
c
INCLUDE(common/sizes)
INCLUDE(common/machin)
INCLUDE(common/runlab)
INCLUDE(common/blkorbs)
INCLUDE(common/restri)
INCLUDE(common/sector)
INCLUDE(common/harmon)
INCLUDE(common/iofile)
INCLUDE(common/atmol3)
INCLUDE(common/tran)
c     integer ilifc,ntranc,itranc,iftran,iftri
c     REAL ctran
c     common/junk/ilifc(maxorb),ntranc(maxorb),itranc(mxorb3),
c    * ctran(mxorb3),iftran,iftri
c
      REAL q(*)
      integer iq(*)
      integer nact ! number of active orbitals
      integer ncor ! number of core orbitals
      REAL trns(nact,nact) ! active orbital transformation matrix
      REAL docc(ncor+nact) ! orbital occupations 
      integer ispin        ! spin component
c
      integer iblkvs
      integer lentitle, lenhead, lenitran, lenvec, lenvt
      integer ivec, ivect
      REAL done, dzero
      integer ilifq, i 
c
      integer  lenwrd, icorr, icori
      external lenwrd, icorr, icori
c
c     call secget(isect(301),3,iblkvs)
      call secget(mouta,3,iblkvs)
      lentitle = 29
      call rdchr(zcom,lentitle,iblkvs,numdu)
      lenhead = mach(8)
      call reads(deig,lenhead,numdu)
      lenitran = mach(9)*lenwrd()
      call readis(ilifc,lenitran,numdu)
      lenvec = newbas1*newbas1
      ivec = icorr(lenvec)
      call reads(q(ivec),lenvec,numdu)
c
      write(iwr,10) isect(301)
 10   format(//,1x,'vectors restored from section',i4,
     +' of dumpfile'/)
c
      lenvt = newbas1*nact
      ivect = icorr(lenvt)
      done = 1.0d0
      dzero = 0.0d0
      call dgemm('n','n',newbas1,nact,nact,done,q(ivec+ncor*newbas1),
     +           newbas1,trns,nact,dzero,q(ivect),newbas1)
      call dcopy(lenvt,q(ivect),1,q(ivec+ncor*newbas1),1)
      call corlsi(ivect)
      ilifq = icori(newbas1)
      do i = 0, newbas1-1
        iq(ilifq+i) = i*newbas1
      enddo
c
      if (ispin.eq.1) then
        write(iwr,20)"alpha"
      else if (ispin.eq.2) then
        write(iwr,20)"beta"
      else 
        write(iwr,20)"wrong"
      endif
 20   format(1x,"----- ",a5," spin natural orbitals -----")
      call tdown(q(ivec),iq(ilifq),q(ivec),iq(ilifq),newbas1)
      call prev(q(ivec),docc,ncor+nact,newbas1,newbas1)
      write(iwr,*)
      call corlsi(ivec)
c
      end
c
c-----------------------------------------------------------------------
c
      subroutine cmpres(n,nbits,a,p,abig,nw)
      implicit REAL  (a-h,o-z)
      parameter (lencbf=256*3*5)
      common /cbuff/ icpack(lencbf)
      dimension a(n),p(*)
c
c pack to nbits representation allowing p to overlay start of a
c and allowing use of vectorization and concurrency
c lencbf must be a multiple of the packing ratio
c
      abig = dabs(a(idamax(n,a,1)))
      if (abig.eq.0.0d0) call dump( ' cmpres zero v',n)
c
      ifac = 2**(nbits-1) - 1
      fac = dfloat(ifac)
      scale = fac / abig
c
      ipt = 1
      nbuff = (n-1)/lencbf + 1
      do 30 ibuff = 1,nbuff
         ioff = (ibuff-1)*lencbf
         ido = min(lencbf,n-ioff)
         do 20 i = 1,ido
            icpack(i) = nint(scale*a(i+ioff)) + ifac
 20      continue
         call gpack(p(ipt),nbits,icpack,ido,lenp)
         ipt = ipt + lenp
 30   continue
c
      nw = ipt - 1
      end
      subroutine diagci (q,iq,v1,v2,n,nit,accur,accpr,accpu,
     +                   energy)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      logical odump
      parameter(ndvdmx = 50, ndvmx2 = ndvdmx*ndvdmx)
c     
c     ndvdmx = max. no. of davidsion expansion vectors ....
c     truncation of expansion set only works for nroots = 1
c     so for multiple roots should have ndvdmx>=nits
c     
INCLUDE(common/savem)
INCLUDE(common/iofile)
      common /ftimes / t(10)
INCLUDE(common/ci)
INCLUDE(common/restar)
INCLUDE(common/timez)
INCLUDE(common/prnprn)
      dimension q(*),iq(*)
      dimension v1(n),v2(n)
      common /scrtch / temp(10000),
     +     zh(ndvdmx,ndvdmx),zs(ndvdmx,ndvdmx),
     +     ys(ndvdmx,ndvdmx),
     +     zv(ndvdmx,ndvdmx),r(ndvdmx),z1(ndvdmx),
     +     z2(ndvdmx),imin(128)
      character*10 charwall
c     
      call gettim(cpu,time)
      if(outon)write (iwr,11) cpulft(1) ,charwall()
 11   format(' hamiltonian diagonaliser entered at ',f8.2,' seconds'
     +       ,a10,' wall')
      if (odebug(32)) 
     + write(iwr,*) ' dimension of vectors in diagci ', n
      call flushn(iwr)
chvd  nits = min(nit,ndvdmx)
      nits = nit
      nroots = min(ndvdmx-1,nroots)
      nroot=1
      call inirec
c     
      call vclr(zs,1,ndvmx2)
      call vclr(zh,1,ndvmx2)
      call timer(t(1))
      call gettim(cpus,epaps)
c     
      if (nguess.eq.0) then
c     
c     usual guess on lowest diagonal element or last evec
c     
         call timer(t(10))
         call guess1(q,iq,vmin,imin,n,v1,v2)
         call putrec(ntapes(3),1,n,v1,1.0d0)
         call fsigma (q,iq,v1,v2)
         zh(1,1) = ddot(n,v1,1,v2,1)
         zs(1,1) = ddot(n,v1,1,v1,1)
         r(1)    = zh(1,1)
         zv(1,1) = 1.0d0
c for packed sigma
c        es = -zh(1,1)/zs(1,1)
c        call saxpy(n,es,v1,1,v2,1)
         call putrec(ntapes(4),1,n,v2,1.0d0)
         idvd = 1
c     
      else if (nguess.gt.0) then
c     
c     start from ascii data on guesses file or eigen vectors file
c     
         if (nguess.ge.100) then
           nguess = nguess/100
           write(iwr,*) ' read ', nguess,' vectors from unit ',
     +      ntapes(5)
           rewind ntapes(5)
           do 11011 iroot = 1, nguess
             read(ntapes(5))
             read(ntapes(5)) v1
             call frnorm(n, v1, 1, vnorm)
             call putrec(ntapes(3),iroot,n,v1,1.0d0)
11011      continue
           rewind ntapes(5)
         else
           write(iwr,*) ' read ',nguess,' guess vectors from unit 7'
           call guessv(q,iq,v1,v2)
         endif
         idvd = iabs(nguess)
         do 10 iguess=1,idvd
            call getrec(ntapes(3),iguess,n,v1)
            do 20 ig = 1,iguess-1
               call getrec(ntapes(3),ig,n,v2)
               zs(ig,iguess) = ddot(n,v1,1,v2,1)
               zs(iguess,ig) = zs(ig,iguess)
 20         continue
            call fsigma (q,iq,v1,v2)
            zs(iguess,iguess) = ddot(n,v1,1,v1,1)
            zh(iguess,iguess) = ddot(n,v1,1,v2,1)
_IF1()c for packed sigma
_IF1()c           es = -zh(iguess,iguess)/zs(iguess,iguess)
_IF1()c           do 21 i = 1,n
_IF1()c              v1(i) = v2(i) + es*v1(i)
_IF1()c21         continue
_IF1()c           call putrec(ntapes(4),iguess,n,v1,1.0d0)
            call putrec(ntapes(4),iguess,n,v2,1.0d0)
            do 30 ig=1,iguess-1
               call getrec(ntapes(3),ig,n,v1)
               zh(ig,iguess)=ddot(n,v1,1,v2,1)
               zh(iguess,ig)=zh(ig,iguess)
 30         continue
 10      continue
c     
      else
c     
c     restart from vectors on 3,4 and reduced matrices on 2
c     
         call getrec(ntapes(2),1,ndvmx2,zh)
         call getrec(ntapes(2),2,ndvmx2,zs)
         idvd = mod(iabs(nguess)-1,ndvdmx-1) + 1
         do 33 i = idvd+1,ndvdmx
            do 34 j = idvd+1,ndvdmx
               zh(j,i) = 0.0d0
               zs(j,i) = 0.0d0
 34         continue
 33      continue
      endif
      nguess = iabs(nguess)
c     
      call putrec(ntapes(2),1,ndvmx2,zh,1.0d0)
      call putrec(ntapes(2),2,ndvmx2,zs,1.0d0)
c     
      if(outon) then
       write(iwr,1001)
 1001  format(/' Reduced hamiltonian matrix from startup '/)
       call foutp(zh,1,idvd,1,idvd,ndvdmx,ndvdmx,1,iwr)
       write(iwr,1002)
 1002  format(/' Reduced overlap matrix from startup '/)
       call foutp(zs,1,idvd,1,idvd,ndvdmx,ndvdmx,1,iwr)
      endif
c     
c iterative loop
c
      coeff = 1.0d0
      call gettim(cpuf,epapf)
      cpu=cpuf-cpus
      elaps=epapf-epaps
      iter1=max(nguess,1)
      if(outon)write(iwr,1003)
 1003 format(/
     &     ' iter  idvd  root      energy         conv.      cpu',
     &     '     elapsed '/
     &     ' ----  ----  ----  ---------------  --------  --------',
     &     '  --------')
      call flushn(iwr)
      old = cpulft(1)
      fact = 2.0d0
      fact2 = 2.0d0
      odump = .false.
      do 200 it=iter1,nits
c     
c     if this is the first iteration just need to diagonalise the matrix
c     
         if (it.eq.iter1) goto 500
c
c     update reduced overlap matrix
c
         call putrec(ntapes(3),idvd,n,v1,1.0d0)
         do 45 jt=1,idvd-1
            call getrec(ntapes(3),jt,n,v2)
            zs(jt,idvd) = ddot(n,v1,1,v2,1)
            zs(idvd,jt) = zs(jt,idvd)
 45      continue
         zs(idvd,idvd) = ddot(n,v1,1,v1,1)
c
         call timer (t(10))
         call gettim(cpus,epaps)
         call fsigma (q,iq,v1,v2)
         call gettim(cpuf,epapf)
         cpu=cpuf-cpus
         elaps=epapf-epaps
c     
c     update reduced hamiltonian matrix
c
         zh(idvd,idvd) = ddot(n,v1,1,v2,1)
c for packed sigma
c        es = -zh(idvd,idvd)/zs(idvd,idvd)
c        do 450 i = 1,n
c           v1(i) = v2(i) + es*v1(i)
c450     continue
c        call putrec(ntapes(4),idvd,n,v1,coeff)
         call putrec(ntapes(4),idvd,n,v2,coeff)
c
         do 40 jt=1,idvd-1
            call getrec(ntapes(3),jt,n,v1)
            zh(jt,idvd) = ddot(n,v1,1,v2,1)
            zh(idvd,jt) = zh(jt,idvd)
 40      continue
c
         call putrec(ntapes(2),1,ndvmx2,zh,1.0d0)
         call putrec(ntapes(2),2,ndvmx2,zs,1.0d0)
c
c      call foutp(zh,1,idvd,1,idvd,ndvdmx,ndvdmx,1,iwr)
c      call foutp(zs,1,idvd,1,idvd,ndvdmx,ndvdmx,1,iwr)
c     
 500     call dcopy(ndvmx2,zh,1,zv,1)
         call dcopy(ndvmx2,zs,1,ys,1)
         call rsg(ndvdmx,idvd,zv,ys,r,1,zv,z1,z2,ierr)
         if (ierr.ne.0) call dump(' rsg error ',ierr)
         call forder(idvd,r,zv,ndvdmx)
_IF1()c        write(iwr,*) ' the eigen vectors of the reduced hamiltonian'
_IF1()c        call foutp(zv,1,idvd,1,idvd,ndvdmx,ndvdmx,1,iwr)
_IF1()c        call exit(0)
c     
         eref = r(nroot)
         nrtold=nroot
         test=dabs(zv(idvd,nroot))
         if(test.lt.accur) nroot=nroot+1
         if(it.eq.iter1) nroot = 1
         do 50 iroot=1,min(idvd,nroots)
            test = dabs(zv(idvd,iroot))
            if(test.gt.accur) nroot=min(nroot,iroot)
            if(iroot.le.max(nrtold,nroot)) then
             if(outon) write (iwr,1004) it,idvd,iroot,r(iroot),
     +                 test,cpu,elaps
 1004          format(1x,3(i4,2x),f15.10,2x,f8.6,2x,f8.1,2x,f8.1)
               call flushn(iwr)
            endif
 50      continue
c     
         if (nroot.gt.nroots) goto 220
         if (it.eq.nits) goto 211
         if (odump) go to 240
         if(nrtold.ne.nroot) then
            write(iwr,1005) nrtold,nroot
 1005       format(/' root ',i3,' past threshold. new root selected ',
     &           i3/)
            call flushn(iwr)
         endif
         coeff = 0.0d0
         do 51 i = 1,nroot
            coeff = max(dabs(zv(idvd,i)),coeff)
 51      continue
         coeff = coeff * 0.5d0
_IF1()c         write(iwr,*) ' coeff for packing ',coeff
         if (idvd.eq.ndvdmx) then
c
c     maximum no. of expansion vectors ... resum
c
c           if (nroot.ne.1) call dump(' cannot resum nroot=',nroot)
            call vclr(zh,1,ndvmx2)
            call vclr(zs,1,ndvmx2)
            do nr = 1, nroots
               call vclr(v1,1,n)
               do 310 i = 1,idvd
                  call getrec(ntapes(3),i,n,v2)
                  call daxpy(n,zv(i,nr),v2,1,v1,1)
 310           continue
c
c              Repeated modified Gramm-Schmidt orthogonalisation.
c
               call frnorm(n,v1,1,vnorm)
               do i = 1, nr-1
                  call getrec(ntapes(5),i,n,v2)
                  s = -ddot(n,v1,1,v2,1)
                  call daxpy(n,s,v2,1,v1,1)
               enddo
               call frnorm(n,v1,1,vnorm)
               if (vnorm.gt.1.01d0) then
                  do i = 1, nr-1
                     call getrec(ntapes(5),i,n,v2)
                     s = -ddot(n,v1,1,v2,1)
                     call daxpy(n,s,v2,1,v1,1)
                  enddo
                  call frnorm(n,v1,1,vnorm)
               endif
               call putrec(ntapes(5),nr,n,v1,1.0d0)
            enddo
c
c           New guesses constructed. Rebuild zh and zs and copy guess
c           to the right place.
c
            call vclr(zv,1,ndvmx2)
            do nr = 1, nroots-1
               call getrec(ntapes(5),nr,n,v1)
               call fsigma(q,iq,v1,v2)
               zh(nr,nr) = ddot(n,v1,1,v2,1)
               zs(nr,nr) = 1.0d0
               zv(nr,nr) = 1.0d0
               call putrec(ntapes(3),nr,n,v1,1.0d0)
               call putrec(ntapes(4),nr,n,v2,1.0d0)
               do ns = 1, nr-1
                  call getrec(ntapes(4),ns,n,v2)
                  zh(nr,ns) = ddot(n,v1,1,v2,1)
                  zh(ns,nr) = zh(nr,ns)
               enddo
            enddo
            call getrec(ntapes(5),nroots,n,v1)
            call putrec(ntapes(3),nroots,n,v1,1.0d0)
            idvd = nroots
            goto 230
         endif
c     
c     make the update vector ... leaves 4 at EOF
c     
         call vclr(v1,1,n)
         do 60 jt=1,idvd
c for packed sigma
c           delta = r(nroot)-zh(jt,jt)/zs(jt,jt)
            delta = r(nroot)
            call getrec(ntapes(3),jt,n,v2)
            call daxpy(n,-delta*zv(jt,nroot),v2,1,v1,1)
            call getrec(ntapes(4),jt,n,v2)
            call daxpy(n,zv(jt,nroot),v2,1,v1,1)
 60      continue
c
         test = dnrm2(n,v1,1)
         if(test.lt.accur) nroot=nroot+1
         if (nroot.gt.nroots) goto 220
c        write(iwr,'(a,i5,f12.8)') ' norm of update vector ',it,xxx
c     
         call timer(t(10))
         call fdiagl (q,iq,v2)
c     
         eref = r(nroot)
_IF1(a)cvd$  noconcur
_IF1(a)cvd$  novector
         do 70 i=1,n
            denom = v2(i) - eref
            denom = dsign(dmax1(0.1d0,dabs(denom)),denom)
            v1(i) = v1(i) / denom
 70      continue
c     
c     approx. orthogonalise to previous iterations ... leaves 3 at EOF
c     
         call frnorm(n,v1,1,vnorm)
c        do 801 ipass = 1,0
         do 80 jt=1,idvd
            call getrec(ntapes(3),jt,n,v2)
 90         ab = ddot(n,v1,1,v2,1) / zs(jt,jt)
            call daxpy(n,-ab,v2,1,v1,1)
            call frnorm(n,v1,1,vnorm)
            if (vnorm.lt.0.99d0) goto 90
 80      continue
c801      continue
         if (nna.eq.nnb) then
c
c        singlet projection
c
            call singen(q, iq, v1)
            call frnorm(n, v1, 1, vnorm)
         endif
c
c compress and expand the vector
c
         idvd = idvd + 1
c
 230  top = cpulft(1)
      tlefti = timlim-top-fact2
      if(tlefti.lt.fact*(top-old)) odump = .true.
      old=top
 200  continue
      write(iwr,*) ' fell out of 200 loop ... how ?? '
 240  write(iwr,102)
 102  format(/20x,14('*')/20x,'no convergence'/20x,14('*')//
     *20x,27('*')/
     *20x,'*** warning ***'/
     *20x,'insufficient time allocated'/
     *20x,'this job must be restarted'/
     *20x,27('*')/)
      goto 280 
 211  write (iwr,210)
 210  format(/
     +      10x,'++++++++++++++++++++++++++++++++++++++++++'/
     +      10x,'convergence not achieved in max iterations'/
     +      10x,'++++++++++++++++++++++++++++++++++++++++++'//)
 280  irest = 9
      tim = timlim + 0.1d0
      go to 270
c
 220  write(iwr,260)it
 260  format(/20x,26('*')/20x,'convergence at cycle',i6/20x,26('*'))
      irest=0
c***  
 270  do 1000 nroot=1,nroots
         write (iwr,250) nroot,r(nroot)
 250     format(/1x,'full-ci: root',i3,' final energy =',f25.12/)
         call flushn(iwr)
         call vclr(v1,1,n)
         do 2401 jt=1,idvd
            call getrec(ntapes(3),jt,n,v2 )
            call daxpy(n,zv(jt,nroot),v2,1,v1,1)
 2401    continue
         call frnorm(n, v1, 1, vnorm)
         call vecprf(q,iq,v1,accpr,accpu)
         write(ntapes(5)) r(nroot)
         write(ntapes(5)) v1
 1000 continue
      energy = r(nroots)
c
c...  natorb
c
      call fnatorb(q,iq,v1)
c     
      call timer (t(10))
      return
      end
      subroutine domkst(m,n,ipt,istr,iipt,len,nst,nstr,itype,iperm)
      implicit REAL  (a-h,o-z)
c only if max(mta) < 65535
c      integer*2 istr
      dimension ipt(8),istr(len),nstr(8),icg(10),itype(8),iperm(8,8)
INCLUDE(common/iofile)
c     
      nst = 0
      do 10 isym = 1,8
         ipt(isym) = iipt
         nstr(isym) = 0
         mt=0
 20      call fstrng (mt,m,n,icg,itype,jmt,iu,iperm)
         if (mt.eq.0) goto 10
         if (jmt.ne.isym) goto 20
c     
         if (iipt.gt.len) then
            write(iwr,*) ' iipt in domkst ',iipt,len,n
            call dump(' dead in domkst',0)
         endif
c     
         do 30 j = 1,n
            istr(j+iipt) = icg(j)
 30      continue
         istr(1+n+iipt) = mt
         iipt = iipt + n + 1
         nstr(isym) = nstr(isym) + 1
         nst = nst + 1
         goto 20
c     
 10   continue
      return
      end
      subroutine dump(s,i)
      character*(*) s
INCLUDE(common/iofile)
      write(iwr,*) ' ************* dump was called'
      write(iwr,*) s,i
      call caserr(s)
      return
      end
      subroutine elim1 ( icg,ioc1,m,n,itype,iw,nw)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/ci)
INCLUDE(common/iofile)
      dimension icg (n) , iw (n,3) , itype (m)
      dimension ioc1 (n,n)
      common /clocks/ lockio
INCLUDE(common/prnprn)
c
c... take care iof itz array later
c
      if (odebug(32)) then
       call lock(lockio)
       write(iwr,*) ' elim1 ' 
       call flushn(iwr)
       call unlockf(lockio)
      endif
c
      ipas=-1
      do 10 i=1,n
        ipas=-1* ipas
          iw (i,1) = icg (i)
          iw (i,2) = ipas
          iw (i,3) = itype ( icg(i) )
_IF1(a)cvd$  noconcur
            do 21 ik = 1,n
 21         ioc1 (ik,i) = 0
          icount = 1
_IF1(a)cvd$  noconcur
          do 30 k = 1, n
            if ( icg(k) .eq.  icg(i) ) goto 30
            ioc1 (icount,i) = icg (k)
            icount = icount+1
 30       continue
 10   continue
      nw=n
      return
      end
      subroutine elim2 ( icg,ind2,intr2,nn2,mm2,m,n,itype,iw,nw,nn)
      implicit REAL  (a-h,o-z)
c     
c..   eliminates two electrons from a specified occupation (icg)
c..   and return lexical index of n-2 string
c     
INCLUDE(common/cone)
INCLUDE(common/ci)
c     
      dimension icg (n)
      dimension ind2(nn),intr2(nn2,mm2) , iw (nn,4) , itype (m)
c     
_IF1(a)cvd$r noconcur
      nw=0
      do 10 i=1,n-1
         ipas=-1
         do 20 j=i+1,n
            nw=nw+1
            ipas=-1*ipas
            iw (nw,1) = icg(i)
            iw (nw,2) = icg(j)
            iw (nw,3) = ipas
            iw (nw,4) = iperm ( itype(icg(i)) , itype(icg(j) ) )
            icount = 0
            ind2(nw) = 1
_IF1(ct)cdir$ novector
_IF1(x)c$dir scalar
_IF1(a)cvd$  novector
            do 30 k = 1, n
               if ( (k .ne. i) .and. (k .ne. j) ) then
                  icount = icount+1
                  ind2(nw) = ind2(nw) + intr2(icount,icg (k))
               endif
 30         continue
c     
 20      continue
 10   continue
_IF1()c     if ( nw .ne. nn) write (iwr,50) nw,nn
_IF1()c50   format (2x,'**warning::  nn is not equal to nw in delim !!'
_IF1()c    1     /2x,'nw=',i2,'     nn=',i2)
      return
      end
      subroutine expand(n,nbits,a,p,abig)
      implicit REAL  (a-h,o-z)
      parameter (lencbf = 256*3*5)
      common /cbuff/ icpack(lencbf)
      dimension a(n),p(*)
c
c upack from nbits allowing ip to overlay the start of a
c and allowing use of vectorization and concurrency
c lencbf must be a multiple of the packing ratio
c
      ifac = 2**(nbits-1) - 1
      fac = dfloat(ifac)
      scale = abig / fac
c
      nbuff = (n-1)/lencbf + 1
      ipskp = lencbf*nbits/64
      ipt = (nbuff-1)*ipskp + 1
      do 10 ibuff = nbuff,1,-1
         ioff = (ibuff-1)*lencbf
         ido = min(lencbf,n-ioff)
         call gupack(p(ipt),nbits,icpack,ido,lenp)
         ipt = ipt - ipskp
         do 20 i = 1,ido
            a(i+ioff) = dfloat(icpack(i)-ifac) * scale
 20      continue
c         call izero(lencbf,icpack,1)
 10   continue
c     
      end
      subroutine fci(q,energy)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/statis)
       common/ccpu/ncpu
INCLUDE(common/iofile)
INCLUDE(common/ci)
INCLUDE(common/restar)
      character*10 charwall
      dimension q(*)
      ncpu=1
      outon = nprint.ne.-5
      call cpuwal(begin,ebegin)
      if(outon) write(iwr,1100)
 1100 format(/1x,104('=')/
     *40x,26('*')/
     *40x,'determinant full-ci module'/
     *40x,26('*')//)
c
c     allocate core (all available memory)
c
      i10 = igmem_alloc_all(lword)
c
      if(lword.lt.1)call caserr(
     *'insufficient memory for full-ci module')
      call fullci(q(i10),lword,energy)
      at=cpulft(1)
      if(outon) write(iwr,1300) at ,charwall()
 1300 format(/1x,'end of full-ci module at',f8.2,' seconds'
     *       ,a10,' wall'//1x,104('=')/)
      call clredx
      call timana(18)
c
c     reset core allocation
c
      call gmem_free(i10)
c
      return
      end
      subroutine forder(it,e,zv,n)
      implicit REAL (a-h,o-z)
      dimension e(n),zv(n,n)
c***
c*** order eigenvalues and vectors in increasing order.
c***
      do 10 j=1,it
          do 20 i=j+1,it
              if(e(i).lt.e(j)) then
                t=e(i)
                e(i)=e(j)
                e(j)=t
                do 30 k=1,it
                    t=zv(k,i)
                    zv(k,i)=zv(k,j)
30                  zv(k,j)=t
              endif
20        continue
10    continue
      return
      end
      subroutine foutp (z,rowlow,rowhi,collow,colhi,rowdim,coldim,
     $     nctl,iwr)
c.......................................................................
c foutp prints a real  matrix in formatted form with numbered rows
c and columns.  the input is as follows;
c        matrix(*,*).........matrix to be output
c        rowlow..............row number at which output is to begin
c        rowhi...............row number at which output is to end
c        collow..............column number at which output is to begin
c        colhi...............column number at which output is to end
c        rowdim..............row dimension of matrix(*,*)
c        coldim..............column dimension of matrix(*,*)
c        nctl................carriage control flag; 1 for single space
c                                                   2 for double space
c                                                   3 for triple space
c the parameters that follow matrix are all of type integer*4.  the
c program is set up to handle 5 columns/page with a 1p5d24.15 format for
c the columns.  if a different number of columns is required, change
c formats 1000 and 2000, and initialize kcol with the new number of
c columns.
c.......................................................................
      implicit REAL  (a-h,o-z)
      integer rowlow,rowhi,collow,colhi,rowdim,coldim,begin,kcol
      character *1 asa,ctl,blank
      character *6 column
      dimension z(rowdim,coldim)
      dimension asa(3)
      data column/'column'  /,asa/' ' ,'0' ,'-'  /,blank/' '/
      data kcol/4/
      data zero/0.d00/
      do 11 i=rowlow,rowhi
         do 10 j=collow,colhi
            if (z(i,j).ne.zero) go to 15
 10      continue
 11   continue
      write (iwr,3000)
 3000 format (/' zero matrix'/)
      go to 3
 15   continue
      ctl = blank
      if ((nctl.le.3).and.(nctl.gt.0)) ctl = asa(nctl)
      if (rowhi.lt.rowlow) go to 3
      if (colhi.lt.collow) go to 3
      last = min(colhi,collow+kcol-1)
      do 2 begin = collow,colhi,kcol
         write (iwr,1000) (column,i,i = begin,last)
         do 1 k = rowlow,rowhi
            do 4 i=begin,last
               if (z(k,i).ne.zero) go to 5
 4          continue
            go to 1
 5          write (iwr,2000) ctl,k,(z(k,i), i = begin,last)
 1       continue
         last = min(last+kcol,colhi)
 2    continue
 3    return
 1000 format (/' ',16x,3(a6,i4,7x),(a6,i4))
 2000 format (a1,'row',i4,2x,4f17.11)
      end
      subroutine frnorm(n,a,ia,anorm)
      implicit REAL  (a-h,o-z)
      dimension a(*)
c
      anorm = dnrm2(n, a, ia)
      scale = 1.0d0 / anorm
      call dscal(n, scale, a, ia)
c
      return
      end
      subroutine fspnad (c,iref,m,na,nb,ic,itz,isss,inter,
     1     na1,m1,nci)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/iofile)
INCLUDE(common/ci)
      dimension c(nci),ic(*),itz(*),inter(na1,m1,2)
      dimension icga(200),icgb(200),ialp(200),ibet(200)
c     dimension idoca(200),idocb(200)
c
      do 5 jmta = 1,8
         do 10 ia = 1,nstra(jmta)
            call getstr(na,jmta,ia,mta,icga)
            ica = ic(mta)
            jmtb = iperm(jmta,isss)
            do 20 ib = 1,nstrb(jmtb)
               call getstr(nb,jmtb,ib,mtb,icgb)
               if (ica + itz(mtb).eq.iref) goto 25
 20         continue
 10      continue
 5    continue
 25   continue
      if(outon)write(iwr,3) (icga(i),i=1,na)
      if(outon)write(iwr,4) (icgb(i),i=1,nb)
3     format(/' reference alpha occ ',8i3)
4     format( ' reference beta  occ ',8i3/)
c
c     ndoc=0
      nalp=0
      nbet=0
      do 80 i=1,m
         icase=1
         do 30 j=1,na
            if (icga(j).ne.i) goto 30
            icase=3
            ja=j
 30      continue
         do 40 j=1,nb
            if (icgb(j).ne.i) goto 40
            icase=icase+1
            jb=j
 40      continue
         goto (80,50,60,70),icase
 50      nbet=nbet+1
         ibet(nbet)=jb
         goto 80
 60      nalp=nalp+1
         ialp(nalp)=ja
         goto 80
70       continue
c70      ndoc=ndoc+1
c        idoca(ndoc)=ja
c        idocb(ndoc)=jb
 80   continue
      do 90 i=1,nci
         c(i)=0.0d0
 90   continue
      fac = 1.0d0/dsqrt(dfloat(2**nbet))
      if (nbet.gt.7) call dump(' nbet in fspnad ',nbet)
      do 142 i7 = 1,2
      do 141 i6 = 1,2
      do 140 i5=1,2
         do 130 i4=1,2
            do 120 i3=1,2
               do 110 i2=1,2
                  do 100 i1=1,2
                     ipar = 1
                     mta = ifstrd (ipar,inter(1,1,1),na1,m1,icga,na)
                     mtb = ifstrd(ipar,inter(1,1,2),na1,m1,icgb,nb)
                     c(ic(mta)+itz(mtb)) = dfloat(ipar)*fac
                     if (nbet.lt.1) goto 150
                     j1=icgb(ibet(1))
                     icgb(ibet(1))=icga(ialp(1))
                     icga(ialp(1))=j1
 100              continue
                  if (nbet.lt.2) goto 150
                  j1=icgb(ibet(2))
                  icgb(ibet(2))=icga(ialp(2))
                  icga(ialp(2))=j1
 110           continue
               if(nbet.lt.3) goto 150
               j1=icgb(ibet(3))
               icgb(ibet(3))=icga(ialp(3))
               icga(ialp(3))=j1
 120        continue
            if (nbet.lt.4) goto 150
            j1=icgb(ibet(4))
            icgb(ibet(4))=icga(ialp(4))
            icga(ialp(4))=j1
 130     continue
         if (nbet.lt.5) goto 150
         j1=icgb(ibet(5))
         icgb(ibet(5))=icga(ialp(5))
         icga(ialp(5))=j1
 140  continue
         if (nbet.lt.6) goto 150
         j1=icgb(ibet(6))
         icgb(ibet(6))=icga(ialp(6))
         icga(ialp(6))=j1
 141  continue
         if (nbet.lt.7) goto 150
         j1=icgb(ibet(7))
         icgb(ibet(7))=icga(ialp(7))
         icga(ialp(7))=j1
 142  continue
 150  continue
c
      return
      end
      subroutine fstrng (mt,m,n,icg,itype,jmt,iu,iperm)
c... generate a new alpha or beta string
c...  mt,icg,iu should be preserved between calls
c
      implicit REAL  (a-h,o-z)
      dimension icg(n),itype(m),iperm(8,8)
c
_IF1(a)cvd$r noconcur
_IF1(a)cvd$r novector
      if (mt.gt.0) goto 20
_IF1(c)cdir$ shortloop
      do 10 i=1,n
10    icg(i)=i
      iu=n
      goto 40
c
20    icg(iu) = icg(iu) + 1
      if (icg(iu).le.m+iu-n) goto 30
      iu = iu-1
      if (iu.eq.0) goto 60
      goto 20
30    if (iu.eq.n) goto 40
      iu = iu+1
      icg(iu) = icg(iu-1)+1
      goto 30
c
40    mt = mt+1
      jmt = 1
_IF1(ct)cdir$ novector
_IF1(x)c$dir scalar
      do 50 j=1,n
50    jmt = iperm(jmt,itype(icg(j)))
      return
60    mt = 0
      return
      end
      subroutine fulcin
      implicit REAL  (a-h,o-z),integer (i-n)
      character *4 itext,ifd
INCLUDE(common/sizes)
c     **** input routine for full-ci ****
INCLUDE(common/direc)
INCLUDE(common/machin)
INCLUDE(common/infoa)
      common/data1/vlist(400),newpro(206),louta(2,maxorb),norbt,
     * norbta(maxorb),norbtp,norbc
INCLUDE(common/scfwfn)
INCLUDE(common/restar)
INCLUDE(common/savem)
INCLUDE(common/work)
INCLUDE(common/timez)
INCLUDE(common/iofile)
INCLUDE(common/prnprn)
      dimension ifd(7)
      parameter (ndvdmx = 50)
      data ifd/
     * 'root','maxc','thre','symm','prin','gues','punc'/
      top=cpulft(1)
      write(iwr,444)top
 444  format(/
     */1x,104('=')//
     *' **** full-ci input processor called at',f9.2,' secs')
      if(jump.ne.1)go to 2
c     mspin=mul
      nint=ne-nopen-npair-npair
      nint=nint/2-norbc
      if(nseto.eq.0)go to 8001
      do 8002 i=1,nseto
8002  nint=nint+no(i)
8001  nint=nint+npair+npair
      next=norbt-nint
      nact = nint+next
      nna = na - norbc
      nnb = nb - norbc
      go to 8003
2     call inpi(nact)
      call inpi(nna)
      call inpi(nnb)
8003  write(iwr,446)nact,nna,nnb
446   format(/' # orbitals       =',i6,
     *//      ' # alpha electrons=',i6,
     *//      ' # beta electrons =',i6)
      if(nact.gt.200)call caserr(
     * 'invalid number of active orbitals')
      if(nna.gt.79.or.nnb.gt.nna.or.nna.lt.1.or.nnb.lt.0)call caserr(
     * 'invalid number of electrons')
c
      ivec2 = -2
      ivec1 = 5
      ivec4 = -7
      ivec3 = 1
      nroots = 1
      maxit  = ndvdmx
      iacc1 = 5
      iacc2 = -4
      ischem = 0
      isss = 1
      nguess = 0
93    call input
c.... see what password is on it
      call inpa4(itext)
      ii=locatc(ifd,7,itext)
      if (ii.gt.0) go to 99
      jrec=jrec-1
      ii = locatc(ydd(101),limit2,itext)
      if(ii)9995,9996,9995
 9996 call caserr(
     *'unrecognised directive or invalid directive sequence')
c.... go to proper place
99    go to (3,4,5,6,7,9,11),ii
c.... roots
 3    call inpi(nroots)
      if(nroots.lt.1)nroots=1
      go to 93
c.... maxcyc
 4    call inpi(maxit)
      if(maxit.le.0.or.maxit.gt.10*ndvdmx) maxit = 10*ndvdmx
      go to 93
c.... threshold
 5    call inpi(iacc1)
      call inpi(iacc2)
      go to 93
c.... symmetry
6     call inpi(isss)
      if(isss.le.0.or.isss.gt.8) isss=1
      go to 93
c.... print
7     call inpi(ivec1)
      call inpi(ivec2)
      go to 93
c     guess
 9    call inpi(nguess)
      go to 93
c.... punch
11    call inpi(ivec3)
      call inpi(ivec4)
      opunch(15) = .true.
      go to 93
c
9995  if(irest.eq.9) then
       if(nguess.eq.0) then
        nguess = 100
       else
        nguess = nguess * 100
       endif
      endif
      return
      end
      subroutine fullci(q,llword,energy)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension q(llword)
      common /mccore/ intrel,lword,ltop,lmax,lmin
      common /ftimes / t(10)
INCLUDE(common/savem)
INCLUDE(common/cone)
INCLUDE(common/iofile)
INCLUDE(common/ci)
      common /cor/ core
INCLUDE(common/cciab)
      common /copcnt/ ropcnt(6)
      parameter (ndvdmx = 50)
_IF(ibm,vax,cyber205,fps)
      character*80 redmat,civecs,sigmas,guesses,evecs,fciz
_ENDIF
c
      do 541 it = 1,10
        t(it) = 0.0d0
541   continue
      call gettim(startc,starte)
_IF(alliant)
* this to force initialization to run on single ce
*mdc*if alliant
*       call set_resource_type(2, -1, -1)
*mdc*endif
_ENDIF
      lword = llword
_IF(ibm,vax,cyber205,fps)
      call getnam('redmat',redmat)
      call getnam('civecs',civecs)
      call getnam('sigmas',sigmas)
      call getnam('guesses',guesses)
      call getnam('evecs',evecs)
      call getnam('fciz',fciz)
_ENDIF
_IF1()      call getnam('redmat'l,redmat)
_IF1()      call getnam('civecs'l,civecs)
_IF1()      call getnam('sigmas'l,sigmas)
_IF1()      call getnam('guesses'l,guesses)
_IF1()      call getnam('evecs'l,evecs)
_IF1()      call getnam('fciz'l,fciz)
_IF(ibm,vax,cyber205)
      open (7,file=guesses,form='formatted',blank='zero',status='unknown
     +')
      open (ntapes(5),file=evecs,form='unformatted',status='unknown')
      open (ntapes(1),file=fciz,form='unformatted',status='unknown')
      open (ntapes(2),file=redmat,form='unformatted',status='unknown')
      open (ntapes(3),file=civecs,form='unformatted',status='unknown')
      open (ntapes(4),file=sigmas,form='unformatted',status='unknown')
_ENDIF
_IF(fps)
      open (7,file=guesses,form='formatted',status='unknown')
      open (ntapes(5),form='unformatted',status='unknown',recl=4000000)
      open (ntapes(1),form='unformatted',status='unknown',recl=4000000)
      open (ntapes(2),form='unformatted',status='unknown',recl=4000000)
      open (ntapes(3),form='unformatted',status='unknown',recl=4000000)
      open (ntapes(4),form='unformatted',status='unknown',recl=4000000)
_ENDIF
      call initil(q,lword)
_IF1()c     read (5,10)itit
_IF1()c     read (5,11)nact,nna,nnb,isss,maxit,iacc1,iacc2,ischem,ivec1,ivec2,
_IF1()c    1            nroots,nguess
_IF1()c10    format(80a1)
_IF1()c11    format(12i5)
      if (nact.gt.200 .or.nna.gt.79 .or. nnb.gt.nna 
     1 .or. nna.lt.1 .or. nnb.lt.0
     1 .or. isss.le.0 .or. isss.gt.8 )then
        write(iwr,*) nact,nna,nnb,isss
      call caserr('invalid parameters in full-ci module')
      endif
_IF1()c     read(5,20) (itype(i),i=1,m)
_IF1()c20    format(40i2)
      if(outon)write (iwr,30) nact,nna,nnb,isss,(itype(i),i=1,nact)
30    format(/
     2' number of orbitals        =',i3/
     3' number of alpha electrons =',i3/
     4' number of beta electrons  =',i3/
     5' space symmetry            =',i3//
     6' orbital symmetries         '/3(40i2/1x)/)
      if(outon)write (iwr,40) lword
40    format(' memory available =',i10,' reals'/)
c
c     first call to ciini to set up strings etc.
c
      ibase = icorr(0)
c
c     allow for multiple full-ci entries
c
      call ciinit (q,q)
c
      call ciini (q,q)
c
c     load integrals at start of core
c
      call loader(q,q,ibaser)
c     call corlsr(ibaser)
      call flushn(iwr)
c
c
      if (iacc1.eq.0) iacc1 = 5
      if (iacc2.eq.0) iacc2 = -4
      accur = dfloat(iacc1)*10.0d0**iacc2
      if (maxit.eq.0) maxit=ndvdmx
chvd  maxit = min(maxit,ndvdmx)
      maxit = min(maxit,nci-1)
      if(nroots.eq.0) nroots=1
      nroots=min(maxit,nci-1,nroots)
      if(outon)write (iwr,50) accur,maxit,nroots
50    format(/' convergence threshold for diagonalisation =',
     1f12.8/' maximum number of iterations =',i3/
     2' number of roots sought ',i3/)
      if (ivec1.eq.0) ivec1=5
      if (ivec2.eq.0) ivec2=-2
      accpr = dfloat(ivec1)*10.0d0**ivec2
      if (ivec3.eq.0) ivec3=1
      if (ivec4.eq.0) ivec4=-7
      accpu = dfloat(ivec3)*10.0d0**ivec4
         call ciini(q,q)
         iv1 = icorr(nci+64)
         iv2 = icorr(nci+64)
c
         call diagci (q,q,q(iv1),q(iv2),nci,maxit,accur,accpr,accpu,
     +                energy)
         call corlsr(ibaser)
      call corlsr (ibase)
      call revise
c
      call timer (t(1))
      if(outon)write (iwr,60) (t(ii),ii=1,10)
60    format(/' timing analysis'/' ==============='/
     1' miscellaneous          ',f10.2/
     2' diagonal elements      ',f10.2/
     3' onel, alpha spin       ',f10.2/
     4' onel, beta spin        ',f10.2/
     5' twoel, alpha-2         ',f10.2/
     6' twoel, beta-2          ',f10.2/
     7' twoel, alpha-1,beta-1  ',f10.2/
     &' spin adaption          ',f10.2/
     &' ci vector printer      ',f10.2/
     a' diagonalisation routine',f10.2/)
c
      rop1 = ropcnt(5)
      rop2 = ropcnt(6)
      ropcnt(5) = rop1+rop2
      if(outon)write(iwr,61) (ropcnt(i),
     +         ropcnt(i)*1.0d-6/(t(i+2)+1.0d-5),i = 1,5),rop1,rop2
 61   format(/' performance analysis',/' ====================',//
     1' module                     nops     mflops '/
     2' =====================  ==========  ======== '/
     3' onel, alpha spin       ',1pd10.2,2x,0pf7.2/
     4' onel, beta spin        ',1pd10.2,2x,0pf7.2/
     5' twoel, alpha-2         ',1pd10.2,2x,0pf7.2/
     6' twoel, beta-2          ',1pd10.2,2x,0pf7.2/
     7' twoel, alpha-1,beta-1  ',1pd10.2,2x,0pf7.2/
     &'              d&s       ',1pd10.2/
     &'              mxma      ',1pd10.2)
      call sumrec
c
      return
      end
      subroutine getmt(n,isym,mts,mt)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/cstrng)
c
c get lexical string number out of common block
c n = no. of electrons
c isym = symmetry (input)
c mts = string no. within symmetry block (input)
c mt = lexical string index (output)
c icg = orbital string (output)
c
      mt = 1
      if (n.gt.0) then
       ioff = iptstr(isym,n) + mts*(n+1)
       mt = istrng(ioff)
      endif
c
      return
      end
_IF(ibm,vax,cyber205,fps)
      subroutine getnam(env,name)
c
c return value of logical name/environmental variable
c
_IF(alliant,convex,titan,apollo,sun,sgi,ipsc,rs6000,dec,hp700,hpux11)
      character*(*) env,name
INCLUDE(common/iofile)
_IFN1(r)      call getenv(env,name)
_IF1(r)      call gtnv(env,name)
      if (name.eq.' ') name = env
      do 10 i = len(name),1,-1
        if(name(i:i).ne.' ') goto 20
 10   continue
 20   write(iwr,1) env,name(1:i)
 1    format(' getnam: ',a,' = ',a)
_ENDIF
_IF(cray,unicos)
c
c unicos version requires env be 7 chars or less specified
c as a string in the format 'string'l and name be at least char*80
c
       character*(*) name
       integer getenv,itemp(10),env
INCLUDE(common/iofile)
       ierr = getenv(env,itemp,10)
       if (ierr.eq.0) then
         write(name,'(a8)') env
       else
          write(name,'(10a8)') itemp
       endif
       do 10 i = len(name),1,-1
         if(name(i:i).ne.' ') goto 20
  10   continue
  20   write(iwr,1) env,name(1:i)
  1    format(' getnam: ',a7,' = ',a)
_ENDIF
c
      return
      end
_ENDIF
      subroutine getspn (c,v,nci,m,na,nb,isss,itype,ic,itz,
     &                    inter)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/ci)
      dimension c(nci),v(nci),itype(m),ic(*),itz(*),inter(na+1,m+1,2)
      dimension icgan(6),icgbn(6),icga(6),icgb(6)
c***
c*** calculate the vector |v> =  s**2 |c>
c*** s**2 = -sum(p in b,q in a){pa+ qa qb+ pb} + nb + (ms+1)*ms
c*** where a,b,+ in {} are used to denote alpha,beta,dagger respectively
c***
      if(na.gt.5 .or. nb.gt.5) call dump(' na or nb in getspn ',0)
      z=0.25d0*dfloat((2+na-nb)*(na-nb)) + dfloat(nb)
      do 10 i=1,nci
10        v(i)=z*c(i)
c***  now go through all poss alpha strings
      do 20 isyma=1,8
          nstras = nstra(isyma)
          if(nstras.eq.0) goto 20
          isymb=iperm(isss,isyma)
          nstrbs=nstrb(isymb)
          if(nstrbs.eq.0) goto 20
          mta=0
          do 30 ia=1,nstras
40            call fstrng (mta,m,na,icga,itype,jmta,iua,iperm)
              if (mta.eq.0) call dump(' mta in getspn ',mta)
              if (jmta.ne.isyma) goto 40
              icmta=ic(mta)
c*** loop thru beta strings of the required symmetry
              mtb=0
              do 50 ib=1,nstrbs
60                call fstrng (mtb,m,nb,icgb,itype,jmtb,iub,iperm)
                  if (mtb.eq.0) call dump(' mtb in getspn ',mtb)
                  if (jmtb.ne.isymb) goto 60
                  coef=c(icmta+itz(mtb))
c*** loop thru occupied beta orbitals
                  do 70 ielb=1,nb
                      iorbb=icgb(ielb)
c*** loop thru occupied alpha orbitals
                      do 80 iela=1,na
                          iorba=icga(iela)
c*** generate new strings, lexically order and compute phases and weights
                          do 90 ielbb=1,nb
90                            icgbn(ielbb)=icgb(ielbb)
                          icgbn(ielb)=iorba
                          isign=1
                          call lexord(icgbn,nb,ielb,isign,mtbb,
     &                         inter(1,1,2),na+1)
                          if(isign.eq.0) goto 80
                          do 100 ielaa=1,na
100                           icgan(ielaa)=icga(ielaa)
                          icgan(iela)=iorbb
                          call lexord(icgan,na,iela,isign,mtaa,
     &                         inter(1,1,1),na+1)
                          icabab=ic(mtaa)+itz(mtbb)
                          if(isign) 110,80,120
110                       v(icabab)=v(icabab)-coef
                          goto 80
120                       v(icabab)=v(icabab)+coef
80                    continue
70                continue
50            continue
30        continue
20    continue
      return
      end
      subroutine getstr(n,isym,mts,mt,icg)
INCLUDE(common/sizes)
INCLUDE(common/cstrng)
      dimension icg(*)
c
c get string out of common block
c n = no. of electrons
c isym = symmetry (input)
c mts = string no. within symmetry block (input)
c mt = lexical string index (output)
c icg = orbital string (output)
c
      mt = 1
      if (n.le.0) return
      ioff = iptstr(isym,n) + (mts-1)*(n+1)
_IF1(a)cvd$  noconcur
_IF1(a)cvd$  shortloop
_IF1(c)cdir$ shortloop
      do 10 i = 1,n
         icg(i) = istrng(i + ioff)
 10   continue
      mt = istrng(n + 1 + ioff)
c
      end
      subroutine gettim(cpud,elapsd)
      implicit REAL  (a-h,o-z)
      dimension cpubuf(3)
      call gms_cputime(cpubuf)
      cpud = cpubuf(1)
      call walltime(elapsd)
      end
      subroutine gpack(p,nbits,u,nw,lenp)
      implicit REAL  (a-h,o-z)
      parameter (lncbf1 = 256*3*5)
      common/cbuff1/ipack(lncbf1)
      dimension p(*)
      integer   u(*)
c
c pack nbits (4,8,12,16,20,24,32) of each element of u into p
c lenp returns the packed length ... may be slightly longer than
c the minimum
c
      if (mod(nbits,4).ne.0 .or. nbits.eq.28)
     &     call dump(' mod(nbits,4).ne.0',nbits)
c
      nb = 8
      nbits1 = 0
      do 10 i = 1,3
         kk = nbits - nb
         if (kk.lt.0) goto 20
         nbits1 = nb
         nb = nb*2
 10   continue
c
 20   nbits2 = nbits - nbits1
c
      ip = 1
      do 30 ibuff = 1,(nw-1)/lncbf1+1
         iu = (ibuff-1)*lncbf1 + 1
         ndo = min(lncbf1,nw-iu+1)
         if (nbits1.gt.0) then
            call pack(p(ip),nbits1,u(iu),ndo) 
            ip = ip + (ndo-1)*nbits1/64 + 1
         endif
         if (nbits2.gt.0) then
            do 40 i = 1,ndo

_IF(ibm,cray,ksr)
               ipack(i) = shiftr(u(i+iu-1),nbits1)
_ELSEIF(apollo)
               ipack(i) = rshft(u(i+iu-1),nbits1)
_ELSE
               ipack(i) = ishft(u(i+iu-1),-nbits1)
_ENDIF

cc_IF(convex,alliant,sun,ctss,titan,sun,sgi,ipsc,rs6000,dec,hp700,hpux11)
cc               ipack(i) = ishft(u(i+iu-1),-nbits1)
cc_ENDIF
cc_IF(apollo)
cc               ipack(i) = rshft(u(i+iu-1),nbits1)
cc_ENDIF
cc_IFN(convex,alliant,sun,ctss,titan,apollo,sun,sgi,ipsc,rs6000,dec,hp700,hpux11)
cc               ipack(i) = shiftr(u(i+iu-1),nbits1)
cc_ENDIF

 40         continue
            call pack(p(ip),nbits2,ipack,ndo)
            ip = ip + (ndo-1)*nbits2/64 + 1
         endif
 30   continue
c
      lenp = ip - 1
      return
      end
      subroutine guess1(q,iq,vmin,imin,n,v1,v2)
      implicit REAL  (a-h,o-z)
INCLUDE(common/iofile)
INCLUDE(common/ci)
      dimension q(*),iq(*),imin(*),v1(n),v2(n)
c
c generate spin adapted guess based on lowest diagonal element
c
      call fdiagl (q,iq,v2)
_IF1()c      write(iwr) ' diagonal elements of the CI '
_IF1()c      call vecprf(q,iq,v2,0.0d0,0,0d0)
c     
      vmin = 1.0d20
      do 20 i=1,n
         if (v2(i).gt.vmin) goto 20
c
chvd     Messy handling of symmetry: The diagonal elements of 
chvd     determinants of symmetry different from the wavefunction are
chvd     not computed and left as zero. This leads to trouble in (not
chvd     physically relevant) cases where all determinants have positive
chvd     energies. Problem arose when investigating binding electrons
chvd     to dipoles.
c
         if (dabs(v2(i)).lt.1.0d-14) goto 20
         imin(1) = i
         vmin = v2(i)
 20   continue
      call sadapt (q,iq,v1,imin(1))
      if(outon)write (iwr,30)
 30   format(' initial configuration generated:')
      nref = 0
      do 50 i=1,n
         if (v1(i).eq.0.0d0) goto 50
         if(outon)write (iwr,40) i,v1(i),v2(i)
         nref = nref+1
         imin(nref) = i
 40      format(' reference ',i8,f15.7,f20.7)
 50   continue
c
      return
      end
      subroutine gupack(p,nbits,u,nw,lenp)
      implicit REAL  (a-h,o-z)
      parameter (lncbf1 = 256*3*5)
      common/cbuff1/ipack(lncbf1)
      dimension  p(*)
      integer   u(*)
c
c unpack nbits (4,8,12,16,20,24,32) from p into u
c
      if (mod(nbits,4).ne.0 .or. nbits.eq.28)
     &     call dump(' gupack mod(nbits,4).ne.0',nbits)
c
      nb = 8
      nbits1 = 0
      do 10 i = 1,3
         kk = nbits - nb
         if (kk.lt.0) goto 20
         nbits1 = nb
         nb = nb*2
 10   continue
c
 20   nbits2 = nbits - nbits1
c
      ip = 1
      do 30 ibuff = 1,(nw-1)/lncbf1+1
         iu = (ibuff-1)*lncbf1 + 1
         ndo = min(lncbf1,nw-iu+1)
         if (nbits1.gt.0) then
            call unpack(p(ip),nbits1,u(iu),ndo)
            ip = ip + (ndo-1)*nbits1/64 + 1
         else
_IFN1(cuf)            call izero(ndo,u(iu),1)
_IF1(f)            call vclr(u(iu),1,ndo)
_IF1(cu)            call szero(u(iu),ndo)
         endif
         if (nbits2.gt.0) then
            call unpack(p(ip),nbits2,ipack,ndo)
            do 40 i = 1,ndo

_IF(ibm,cray,ksr)
               u(i+iu-1) = or(u(i+iu-1),shiftl(ipack(i),nbits1))
_ELSEIF(apollo)
               u(i+iu-1) = or(u(i+iu-1),lshft(ipack(i),nbits1))
_ELSE
               u(i+iu-1) = IOR32(u(i+iu-1),ishft(ipack(i),nbits1))
_ENDIF

cc_IF(convex,alliant,ctss,titan,sgi,ipsc,rs6000,dec,hp700,hpux11)
cc               u(i+iu-1) = ior(u(i+iu-1),ishft(ipack(i),nbits1))
cc_ENDIF
cc_IF(sun)
cc               u(i+iu-1) = or(u(i+iu-1),ishft(ipack(i),nbits1))
cc_ENDIF
cc_IF(apollo)
cc               u(i+iu-1) = or(u(i+iu-1),lshft(ipack(i),nbits1))
cc_ENDIF
cc_IFN(convex,alliant,sun,ctss,titan,apollo,sun,sgi,ipsc,rs6000,dec,hp700,hpux11)
cc               u(i+iu-1) = or(u(i+iu-1),shiftl(ipack(i),nbits1))
cc_ENDIF


 40         continue
            ip = ip + (ndo-1)*nbits2/64 + 1
         endif
 30   continue
c
      lenp = ip - 1
      end
      function ifstrd (ipar,inter,na1,m1,icg,n)
      implicit REAL  (a-h,o-z)
      dimension icg(n),inter(na1,m1)
      dimension icgg(200)
      do 10 j=1,n
10    icgg(j) = icg(j)
      if (n.lt.2) goto 40
      do 30 jj=2,n
      jjm = jj-1
      i = jjm
      do 20 ii=1,jjm
      if (icgg(i).lt.icgg(i+1)) goto 20
      j1=icgg(i)
      icgg(i)=icgg(i+1)
      icgg(i+1)=j1
      ipar=-ipar
20    i=i-1
30    continue
40    continue
      ifstrd=1
      do 50 j=1,n
50    ifstrd = ifstrd+inter(j,icgg(j))
      return
      end
      subroutine initil(q,lword)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter (mxorb1=maxorb+1)
INCLUDE(common/discc)
INCLUDE(common/machin)
INCLUDE(common/iofile)
      common/junk/pop(maxorb),potn,core,ncolo(3),ncore,
     *mapcie(maxorb),map2(maxorb),nnact,mapaie(maxorb),mapaei(maxorb)
     *,iqsec,nacta(maxorb),nactb(maxorb),nactc(5),isecor,
     *evalue(maxorb),eocc(mxorb1),nbas,newb,ncol,ieval,ipop,ispp
     *,nirr,mult(8,8),isymao(maxorb),isymmo(maxorb),nsp
INCLUDE(common/filel)
INCLUDE(common/restar)
INCLUDE(common/restri)
      common/junkc/zjob,zdate,ztime,zprog,ztype,zspace(14),ztext(10)
INCLUDE(common/savem)
INCLUDE(common/ci)
      dimension q(*)
      data thresh/1.0d-5 /
      data m0/0/
      data m51,m29/51,29/
      i=inicor(lword)
      nav = lenwrd()
      call secget(isect(470),1005,iblka)
      call readi(nacta,mach(14)*nav,iblka,idaf)
      wwww = 0.0d0
      call timer(wwww)
      nsecor=isecor
      call secget(nsecor,1004,iblka)
      call rdedx(pop,mach(15),iblka,idaf)
      if(outon)write(iwr,5004) yed(idaf),ibl3d,nsecor
 5004 format(/1x,'dumpfile resides on ',a4,' at block ',i6/
     * 1x,'core hamiltonian to be retrieved from section ',i4)
      if(outon)write(iwr,2)nnact,ncore,potn,core
    2 format(1x,'header block information :'/
     *       1x,'=========================='/
     *       1x,'number of active orbitals ',i4/
     *       1x,'number of core   orbitals ',i4/
     *       1x,'nuclear repulsion energy ',e21.12/
     *       1x,'core energy              ',e21.12)
      if(nnact.gt.1) go to 10005
      call caserr('invalid number of active orbitals')
80010 call caserr('parameter error in full-ci preprocessor')
10005 do 82003 i=1,nnact
      j=mapaie(i)
82003 mapaei(j)=i
      lfile=m6file
      do 60001 i=1,lfile
      lotape(i)=m6tape(i)
      liblk  (i)=m6blk(i)
60001 llblk  (i)=liblk(i)-m6last(i)
      nact=nnact
      ncor=ncore
      call secget(isect(490),m51,iblka)
      call readi(nirr,mach(13)*nav,iblka,idaf)
      call setsto(nact,m0,itype)
      call secget(iqsec,3,iblka)
      call rdchr(zjob,m29,iblka,idaf)
      call reads(evalue,mach(8),idaf)
      if(outon)
     +write(iwr,89005) iqsec,ztype,ztime,zdate,zjob,ztext,nbas,ncol
89005 format(/1x,'scf mo specifications restored from section ',i4,
     *          ' of dumpfile'/
     *       1x,'header block information :'/
     *       1x,'=========================='/
     *       1x,a7,' vectors created at ',
     *          a8,' on ',a8,' in the job ',a8/
     *       1x,'with the title :',1x,10a8/
     *       1x,'no. of gtos        ',i4/
     *       1x,'no. of scf vectors ',i4)
      call symvec(q,isymao,isymmo,nbas,ncol,iblka)
      do 44 i=1,nact
      itype(i)=isymmo(mapaie(i))
 44   continue
      nocc=0
      nunocc=0
      do 89006 i=1,nact
      jscf=mapaie(i)
      qio=eocc(jscf)
      if(qio.le.thresh) nunocc=nunocc+1
      if(qio.gt.thresh) nocc=nocc+1
89006 continue
      if(nocc+nunocc.ne.nact) go to 80010
      if(nunocc.le.0) go to 80010
      if(outon)write(iwr,1)
 1    format(/1x,'transformed integral files'/1x,26('*'))
      call filprn(m6file,m6blk,m6last,m6tape)
      return
      end
      subroutine intind (i,j,k,l,m,ic2esq,ic3esq,itype,n1)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/ci)
      dimension ic2esq(m*m),ic3esq(m*m),itype(*)
      ijsym = iperm ( itype (i) , itype (j) )
      klsym = iperm ( itype (k) , itype (l) )
      if ( ijsym .ne. klsym ) return
      n1 = ic2esq (  (i-1) * m + j  )   +
     1    ic3esq (  (k-1) * m + l  )
      return
      end
      subroutine lexord(icgbn,nb,ielb,isign,mtb,inter,na1)
      implicit REAL (a-h,o-z)
      dimension icgbn(nb),inter(na1,*)
      do 100 ielbb=ielb+1,nb
          if(icgbn(ielbb)-icgbn(ielbb-1)) 110,80,100
110       isign=-isign
          it=icgbn(ielbb)
          icgbn(ielbb)=icgbn(ielbb-1)
          icgbn(ielbb-1)=it
100   continue
      do 120 ielbb=1,ielb-1
          if(icgbn(ielbb)-icgbn(ielbb+1)) 120,80,130
130       isign=-isign
          it=icgbn(ielbb)
          icgbn(ielbb)=icgbn(ielbb+1)
          icgbn(ielbb+1)=it
120   continue
      mtb=1
      do 140 i=1,nb
140       mtb=mtb+inter(i,icgbn(i))
      return
80    isign=0
      return
      end
      subroutine load(dint,itypes,ic3e,mm,m,
     *     ic2esq,ic3esq,nintsq,skv2)
c     
c..   dint is integrals in dirac notation stored in squares using
c..   ic2esq  and ic3esq
c..   skv2 is pure one electron integrals
c     
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/mapper)
INCLUDE(common/cciab)
INCLUDE(common/cone)
INCLUDE(common/ci)
      common /cor/ core
      common/blkin/gin(510),numi
      common/craypk/i205(1360)
INCLUDE(common/filel)
INCLUDE(common/discc)
INCLUDE(common/machin)
INCLUDE(common/iofile)
INCLUDE(common/savem)
INCLUDE(common/atmblk)
      common/junk/occ(maxorb),potn,corree,ncolo(3),ncore,
     *mapcie(maxorb),map2(maxorb),nactt,mapaie(maxorb),mapaei(maxorb)
     *,iqsec
INCLUDE(common/prnprn)
      dimension itypes(*),ic3e(mm)
      dimension skv2(*),dint(*)
      dimension ic2esq(m,m),ic3esq(m,m)
_IF(linux)
      external fget
_ENDIF
c     
      n1(i,j,k,l) = ic2esq(j,i) + ic3esq(l,k) - ipqbas
c     
c... this is the interface to the one and two electron integrals
c... reads them from transformed integral file
c
      nint1 = npair(1)
      call vclr(skv2,1,nint1)
      rewind ntapes(1)
c     
      ipass = 0
      ipqbas = 0
      call setsto(1360,0,i205)
      do 12345 isympq = 1,8
         if (nprsqr(isympq).eq.0) goto 12345
c     
      call vclr(dint,1,nintsq)
      ic=0
      do 8 ifile=1,lfile
      iunit=lotape(ifile)
      call search(liblk(ifile),iunit)
      call find(iunit)
      lbl=llblk(ifile)
    6 lbl=lbl+1
      call get(gin(1),mw)
      if(mw.eq.0) go to 8
      if(lbl.ne.0) call find(iunit)
      int4=1
      call unpack(gin(num2e+1),lab816,i205,numlab)
      do 30 num=1,numi
      i=i205(int4  )
      j=i205(int4+1)
      k=i205(int4+2)
      l=i205(int4+3)
      ic=ic+1
      g=gin(num)
c     too small too worry about?
      if (dabs(g).lt.1d-10) goto 30
c     any old 2-e integral
      i1 = max(i,j)
      j1 = min(i,j)
      k1 = max(k,l)
      l1 = min(k,l)
      i=i1
      j=j1
      k=k1
      l=l1
      if (i.gt.k1 .or. (i1.eq.k1.and.j1.ge.l1)) goto 40
      i=k1
      j=l1
      k=i1
      l=j1
40    if (i.gt.m) goto 30
c     
            ijs = iperm(itypes(i),itypes(j))
            kls = iperm(itypes(k),itypes(l))
            if (ijs.ne.kls) then
               if (dabs(g).gt.1.0d-6)
     $           write(iwr,*) ' integ zero by symmetry ',i,j,k,l,g
               goto 30
            endif
c     full square of integrals in dirac notation
            if(iperm(itypes(k),itypes(i)).eq.isympq) then
               dint(n1(k,i,l,j)) = g
               dint(n1(l,j,k,i)) = g
               dint(n1(i,k,j,l)) = g
               dint(n1(j,l,i,k)) = g
            endif
            if(iperm(itypes(k),itypes(j)).eq.isympq) then
               dint(n1(k,j,l,i)) = g
               dint(n1(l,i,k,j)) = g
               dint(n1(i,l,j,k)) = g
               dint(n1(j,k,i,l)) = g
            endif
c
   30 int4=int4+4
      if(lbl.ne.0) go to 6
    8 continue
c     
         call swrite(ntapes(1), nprsqr(isympq)**2, dint)
c     
         ipqbas = ipqbas + nprsqr(isympq)**2
         ipass = ipass + 1
12345 continue
c     
c...
c... restore 1-elec integrals
c...
      call secget(nsecor,1004,jblkk)
      call rdedx(occ,mach(15),jblkk,idaf)
      write(iwr,1100)nsecor,ibl3d,yed(idaf)
1100  format(
     */' transformed 1-electron integrals restored from section',i4/
     *' of dumpfile starting at block',i8,' of ',a4)
      core=corree
      nin=0
      jblkk=jblkk+lensec(mach(15))
      call search(jblkk,idaf)
      call fget(gin,kword,idaf)
      valmax=0.0d0
      ivmax=0
      do 101 i=1,m
      do 101 j=1,i
       nin=nin+1
      if(nin.le.kword)goto 102
      call fget(gin,kword,idaf)
      nin=1
102   val=gin(nin)
      if(itypes(j).ne.itypes(i))goto 511
      i1=ic3e(iky(max(i,j))+min(i,j))
      skv2(i1)=val
      goto 101
c...   symmetry forbidden integral
511   if ( dabs(val).le. dabs(valmax)) go to 101
      valmax = val
      ivmax = i
      jvmax = j
101   continue
      if (ivmax.ne.0) write(iwr,512) ivmax,jvmax,valmax
512   format(/1x,
     + 'full-ci: symmetry check / largest forbidden h-integral :',
     +         2i4,1x,e12.5)
c     
      if(odebug(32))
     +write(iwr,*) ' integrals have been read', core, ipass
      return
      end
      subroutine lock(lockio)
      implicit REAL  (a-h,o-z)
      end
      subroutine makges (c,v,nguess,nci,m,na,nb,ic,itz,
     &                    inter)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/iofile)
INCLUDE(common/ci)
      dimension c(nci),v(nci),ic(*),itz(*),inter(na+1,m+1,2)
      dimension icgag(5),icgbg(5),iin(200)
c***
c*** program assumes that orbitals remain in same order in going from
c*** small to large basis. maintaining lexicality eases calculating
c*** the new string numbers and also removes any phase problems.
c***
      if(na.gt.5 .or. nb.gt.5) call dump(' na or nb in makges ',na)
      read(7,*) ng
      if(ng.ne.nguess) nguess=min(ng,nguess)
      read(7,*) nnew
      if(nnew.gt.200) call dump(' nnew in makges ',nnew)
      read(7,*) (iin(i),i=1,nnew)
      write(iwr,78) (iin(i),i=1,nnew)
78    format(/' mapping from small basis to large',20i3)
      do 344 iguess=1,nguess
          read(7,*) ndets
          if(ndets.gt.nci) call dump(' ndets in makges ',ndets)
          call vclr(c,1,nci)
          write(iwr,*) ' guess ',iguess,'. no. of determinants',ndets
          csum = 0.0d0
          do 345 idet=1,ndets
              read(7,*) jnk1,coef,(icgag(i),i=1,na),
     &         (icgbg(i),i=1,nb)
              mta=1
              do 346 i=1,na
346               mta=mta+inter(i,iin(icgag(i)),1)
              mtb=1
              do 347 i=1,nb
347               mtb=mtb+inter(i,iin(icgbg(i)),2)
              c(ic(mta)+itz(mtb))=coef
              csum = csum + coef*coef
345       continue
          write(iwr,*) ' norm of input vector ', dsqrt(csum)
c*** orthogonalise to previous iterations
          do 349 ig=1,iguess-1
             call getrec(ntapes(3),ig,nci,v)
              z = ddot(nci,c,1,v,1)
349           call daxpy(nci,-z,v,1,c,1)
          z=ddot(nci,c,1,c,1)
          z=1.0d0/dsqrt(z)
          call dscal(nci,z,c,1)
          call putrec(ntapes(3),iguess,nci,c,1.0d0)
344   continue
      close(7,status='keep')
c
      return
      end
      subroutine makstr(nstraa,nstrbb,nstra1,nstrb1)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/cone)
INCLUDE(common/iofile)
INCLUDE(common/ci)
INCLUDE(common/savem)
INCLUDE(common/cciab)
INCLUDE(common/cstrng)
c
c make strings once and for all
c iptstr(isym,n) points to start of symmetry block isym for
c                strings of n electrons
c istrng(*) is dense list of records of format
c         (icg(i),i=1,n),mt (mt = lexical string no.)
c
      iipt = 0
      do 10 n = 1,max(nna,nnb)
         call domkst(nact,n,iptstr(1,n),istrng,iipt,lenci,nstsum(n),
     &        nstsym(1,n),itype,iperm)
 10   continue
      if(outon)write(iwr,1) iipt
1     format(/1x,'core statistics'/
     *        1x,'==============='/
     *' core used to store strings ',i8)
c
      nstraa = nstsum(nna)
      if (nnb.gt.0) then
        nstrbb = nstsum(nnb)
      else
        nstrbb = 1
      endif
      if (nna.gt.1) then
        nstra1 = nstsum(nna-1)
      else
        nstra1 = 1
      endif
      if (nnb.gt.1) then
        nstrb1 = nstsum(nnb-1)
      else if (nnb.eq.1) then
        nstrb1 = 1
      else
        nstrb1 = 0
      endif
      do 20 i = 1,8
         nstra(i) = nstsym(i,nna)
         if (nnb.gt.1) then
           nstrb(i) = nstsym(i,nnb)
           ntrb1(i) = nstsym(i,nnb-1)
         else if (nnb.eq.1) then
           nstrb(i) = nstsym(i,nnb)
           if (i.eq.1) then
             ntrb1(i) = 1
           else
             ntrb1(i) = 0
           endif
         else if (nnb.eq.0) then
           if (i.eq.1) then
             nstrb(i) = 1
           else
             nstrb(i) = 0
           endif
           ntrb1(i) = 0
         endif
         if (nna.gt.1) then
           ntra1(i) = nstsym(i,nna-1)
         else
           if (i.eq.1) then
             ntra1(i) = 1
           else
             ntra1(i) = 0
           endif
         endif
 20   continue
c
      return
      end
      subroutine mic (ic,itz,na,nb,isss,nci,nnci)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/ci)
      dimension ic(*),itz(*)
c...sets up addressing of ci vector
c... loop over beta string symmetries
      nci=0
      nnci=0
      do 10 iz=1,8
c... first do beta string address offsets -- itz
         do 20 kt = 1,nstrb(iz)
            call getmt(nb,iz,kt,mtb)
            itz(mtb)=kt
 20      continue
c...  now loop over valid alpha strings
         iaz = iperm(isss,iz)
c...  rjh force odd stride to improve cibb on Cray-2
         nbb = nstrb(iz)
         nbb = nbb + mod(nbb+1,2)
         do 30 kt = 1,nstra(iaz)
            call getmt(na,iaz,kt,mta)
            ic(mta) = nnci
            nnci = nnci + nbb
            nci = nci + nstrb(iz)
 30      continue
 10   continue
      return
      end
      subroutine mice (ic2e,ic3e,m,itype,nint)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/ci)
      dimension ic2e(*),ic3e(*),itype(m)
c     
      nint=0
      do 30 iz=1,8
         intoff(iz) = nint
         kt=0
         ij=0
         do 11 i=1,m
            do 10 j=1,i
               ij=ij+1
               if (iz.ne.iperm(itype(i),itype(j))) goto 10
               kt=kt+1
               ic3e(ij)=kt
 10         continue
 11      continue
         ij=0
         do 21 i=1,m
            do 20 j=1,i
               ij=ij+1
               if (iz.ne.iperm(itype(i),itype(j))) goto 20
               ic2e(ij) = nint
               nint = nint + kt
 20         continue
 21      continue
         npair(iz) = kt
 30   continue
      return
      end
      subroutine micesq (ic2e,ic3e,m,itype,nint)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/ci)
      dimension ic2e(*),ic3e(*),itype(m)
c     
INCLUDE(common/cciab)
c     
c     
      nint=0
      do 30 iz=1,8
         intsqr(iz) = nint
         kt=0
         ij=0
         do 10 i=1,m
            do 20 j=1,m
               ij=ij+1
               if (iz.ne.iperm(itype(i),itype(j))) goto 20
               kt=kt+1
               ic3e(ij)=kt
 20         continue
 10      continue
         ij=0
         do 40 i=1,m
            do 50 j=1,m
               ij=ij+1
               if (iz.ne.iperm(itype(i),itype(j))) goto 50
               ic2e(ij) = nint
               nint = nint + kt
 50         continue
 40      continue
         nprsqr(iz) = kt
 30   continue
      return
      end
      subroutine minter (inter,na1,m1,na,nb,m)
      implicit REAL  (a-h,o-z)
      dimension inter(na1,m1,2)
c     
      nab=na
      do 70 kk=1,2
         if (kk.eq.2) nab=nb
         if (nab.le.0) goto 70
         n1=nab+1
         do 11 i=1,m1
            do 10 j=1,n1
               inter(j,i,kk)=0
 10         continue
 11      continue
         do 50 k=1,nab
            inter(k,k,kk)=0
            do 40 l=k,m
               if (m-l.le.nab-k) goto 40
               z4=1.0d0
               zl1=m-l
               zl2=nab-k
               if (nab.eq.k) goto 30
               l22=nab-k
               do 20 l3=1,l22
                  z4=z4*zl1/zl2
                  zl1=zl1-1.0d0
                  zl2=zl2-1.0d0
 20            continue
 30            iz4=z4+0.1d0
               inter(k,l+1,kk) = iz4+inter(k,l,kk)
 40         continue
 50      continue
         do 61 i=1,nab
            do 60 k=1,m
               inter(i,k,kk) = inter(i,k,kk) - inter(i+1,k+1,kk)
 60         continue
 61      continue
 70   continue
      return
      end
      subroutine mkadd2(m,n,itype,iperm,
     &     ic2e,iadd2,ladd2,ipt2,npt2,nstr2,inter,n1,m1,ic,iused,
     &     intr2,nn2,mm2)
      implicit integer (a-z)
c     
INCLUDE(common/sizes)
INCLUDE(common/cstrng)
c     
      dimension itype(m),iperm(8,8),ic2e(m,m),iadd2(ladd2,3),
     &     ipt2(nstr2,8),npt2(nstr2,8),
     &     ioc2(10),ick(200),inter(n1,m1),ic(*)
      dimension intr2(nn2,mm2)
c     
c     loop through n-2 particle strings and generate all double additions
c     which give correct symmetry. store indexed by lexical n-2 index.
c     
      if (n-2.lt.0) return
      do 4 isym = 1,8
         do 5 i = 1,nstr2
            ipt2(i,isym) = 0
            npt2(i,isym) = 0
 5       continue
 4    continue
      ipt = 0
      do 10 msym = 1,8
         if (n-2.eq.0) then
            if (msym.eq.1) then
               nmt = 1
            else
               nmt = 0
               goto 10
            endif
         else
            nmt = nstsym(msym,n-2)
         endif
         do 20 mts = 1,nmt
            if (n-2.gt.0) then
               call getstr(n-2,msym,mts,mt,ioc2)
            else
               mt = 1
            endif
            ind = 1
            do 21 ii = 1,n-2
               ind = ind + intr2(ii,ioc2(ii))
 21         continue
            if (ind.ne.mt) call dump(' intr2 screwed ',ind)
            do 200 klsym = 1,8
               ipt2(mt,klsym) = ipt
               ngot = 0
               do 30 i=1,m
                  ick(i)=0
 30            continue
_IF1(ct)cdir$ novector
_IF1(x)c$dir scalar
_IF1(a)cvd$  novector
               do 40 i = 1,n-2
                  ick(ioc2(i)) = 1
 40            continue
               iel = 0
               index = 1
               do 50 i = 1,m-1
                  if (ick(i) .ne. 0) then
                     iel = iel + 1
                     index = index + inter(iel,i)
                     goto 50
                  endif
                  iphas = 1
                  iklsym = iperm(itype(i),klsym)
                  jndex = index + inter(iel+1,i)
                  jel = iel
                  do 60 j = i+1,m
                     if (ick(j) .ne. 0) then
                        jel = jel + 1
                        iphas = -iphas
                        jndex = jndex + inter(jel+1,j)
                        goto 60
                     endif
                     if (itype(j) .ne. iklsym) goto 60
                     istrin = jndex + inter(jel+2,j)
_IF1(ct)cdir$ novector
_IF1(x)c$dir scalar
_IF1(a)cvd$  novector
                     do 70 jjel = jel+1,n-2
                        istrin = istrin + inter(jjel+2,ioc2(jjel))
 70                  continue
c     
                     if(ipt.gt.ladd2)call dump('over add2 limit ',ipt)
                     ngot = ngot + 1
                     ipt = ipt + 1
                     iadd2(ipt,1) = ic2e(i,j)
                     iadd2(ipt,2) = iphas
                     iadd2(ipt,3) = ic(istrin)
 60               continue
 50            continue
c     
               npt2(mt,klsym) = ngot
 200        continue
 20      continue
 10   continue
c     
      iused = ipt
      return
      end
_IF(alliant)
      recursive subroutine newdg1(n,isym,mts,mt,ioc,e,p,h,m)
_ENDIF
_IFN(alliant)
      subroutine newdg1(n,isym,mts,mt,ioc,e,p,h,m)
_ENDIF
      implicit REAL (a-h,o-z)
      dimension p(m,m),h(m),ioc(n)
c     
_IF1(a)cvd$r noconcur
      call getstr(n,isym,mts,mt,ioc)
      e = 0.0d0
      do 50 i = 1,n
         ii = ioc(i)
         e = e + h(ii)
_IF1(a)cvd$  shortloop
_IF1(c)cdir$ shortloop
         do 60 j = 1,i-1
            jj = ioc(j)
            e = e + p(jj,ii)
 60      continue
 50   continue
c     
      return
      end
      subroutine newdgs(ic2e,ic3e,ic,d,skv,z,h,p,q,eab,eaa,ebb,
     &     ioca,iocb,mta,ic3et,m,na,nb,maxaa,maxbb,isss,maxeab,itype)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common /cor   / core
INCLUDE(common/cciab)
INCLUDE(common/mapper)
INCLUDE(common/cone)
INCLUDE(common/ci)
INCLUDE(common/iofile)
      dimension ic2e(m,m),ic3e(m,m),ic(*),ic3et(*), itype(*)
      dimension d(*),skv(*),z(*)
      dimension h(m),p(m,m),q(m,m),eab(m,maxeab),eaa(maxaa),
     &     ioca(na,maxaa),
     &     iocb(nb,maxbb),ebb(maxbb),mta(maxaa)
c     
c     build diagonal elements of the hamiltonian
c     d(a,b) = eaa + ebb + eab
c     eaa = <ij/ij> - <ij/ji>, i>j=1,na
c     eab = <ij/ij> ,i=1,na j=1,nb
c     
      rewind ntapes(1)
      ijoff = 0
      do 12345 isymij = 1,8
          if (nprsqr(isymij).eq.0) goto 12345
          call sread(ntapes(1), nprsqr(isymij)**2, z)
c
      do 10 i = 1,m
         h(i) = skv(ic3et(iky(i+1)))
         do 20 j = 1,i
            if (iperm(itype(i),itype(j)).ne.isymij) goto 20
            ijij = ic3e(j,i) + ic2e(j,i) - ijoff
            ijji = ic3e(j,i) + ic2e(i,j) - ijoff
            p(j,i) = z(ijij) - z(ijji)
            p(i,j) = p(j,i)
            q(j,i) = z(ijij)
            q(i,j) = q(j,i)
 20      continue
 10   continue
      ijoff = ijoff + nprsqr(isymij)**2
12345 continue
c     
      do 30 isyma = 1,8
         isymb = iperm(isyma,isss)
         naa = nstra(isyma)
         nbb = nstrb(isymb)
c
c make eaa, ebb and ioca, iocb
c     
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  cncall
_IF1(c)cfpp$ nodepchk
_IF1(c)cfpp$ cncall
         do 40 ib = 1,nbb
            call newdg1(nb,isymb,ib,mta(ib),iocb(1,ib),ebb(ib),p,h,m)
 40      continue
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  cncall
cfpp$ nodepchk
cfpp$ cncall
         do 50 ia = 1,naa
            call newdg1(na,isyma,ia,mta(ia),ioca(1,ia),eaa(ia),p,h,m)
 50      continue
c     
c     d(b,a) = core+eaa+ebb
c     
_IF1(a)cvd$  nodepchk
_IF1(c)cfpp$ nodepchk
_IF1(x)c$dir no_recurrence
         do 170 ia = 1,naa
            iaoff = ic(mta(ia))
_IF1(a)cvd$  nodepchk
_IF1(ct)cdir$ ivdep
_IF1(x)c$dir no_recurrence
            do 100 ib = 1,nbb
               d(iaoff + ib) = core + eaa(ia) + ebb(ib)
 100        continue
 170     continue
c     
c     d(b,a) = d(b,a) + eab 
c
         nblock = (naa-1)/maxeab + 1
         ialo = 0
         nleft = naa
         do 103 iblock = 1,nblock
_IF1(a)cvd$  nodepchk
_IF1(a)cvd$  select(concurrent)
_IF1(c)cfpp$ nodepchk
_IF1(c)cfpp$ select(concur)
            do 70 ia = 1,min(maxeab,nleft)
               do 110 i = 1,m
                  eab(i,ia) = 0.0d0
 110           continue
c
               do 120 i = 1,na
                  ii = ioca(i,ialo+ia)
                  do 130 j = 1,m
                     eab(j,ia) = eab(j,ia) + q(j,ii)
 130              continue
 120           continue
c
               iaoff = ic(mta(ialo+ia))
               do 140 j = 1,nb
                  do 150 ib = 1,nbb
                     jj = iocb(j,ib)
                     d(iaoff+ib) = d(iaoff+ib) + eab(jj,ia)
 150              continue
 140           continue
 70         continue
            ialo = ialo + maxeab
            nleft = nleft - maxeab
 103     continue
 30   continue
c     
      return
      end
      function nstrng(n,m)
      implicit REAL  (a-h,o-z)
c
      if (n.lt.0) then
        nstrng = 0
      else if (n.eq.0) then
        nstrng = 1
      else
        z = 1.0d0
        do 10 i = m,(m-n+1),-1
           z = z*dfloat(i)
 10     continue
        do 20 i = 1,n
           z = z/dfloat(i)
 20     continue
        nstrng = nint(z)
      endif
c
      return
      end
      subroutine onela (c,s,skv,m,na,itype,ic,inter,
     &     na1,m1,isss,iwa,jwa,ioc1,ic3e,rops,icpu,ncpu)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common /cor   / core
      common /ftimes / t0,td,t1,t2,t3,t4,t5,t6,t7
INCLUDE(common/mapper)
INCLUDE(common/cone)
INCLUDE(common/ci)
      common /clocks/ lockio
      dimension c(*),s(*),skv(*),itype(m),ic(*),ic3e(*)
      dimension iwa(na,3)
      dimension jwa(m1-na,4)
      dimension ioc1(na,na)
      dimension inter(na1,m1,2)
      dimension icga(200)
_IF1()c     
_IF1()c parallel version must be compiled reentrant with all external
_IF1()c references inlined
_IF1()c
_IF1()c     call lock(lockio)
_IF1()c     write(iwr,*) ' icpu, ncpu, m, na, na1, m1, isss',
_IF1()c    $       icpu, ncpu, m, na, na1, m1, isss
_IF1()c     call flush(iwr)
_IF1()c     call unlockf(lockio)
c
      rops = 0.0d0
      do 10 isyma=1,8
         if (nstra(isyma).eq.0) goto 10
         napp = (nstra(isyma))
         nb = nstrb ( iperm ( isss,isyma ) )
c     
         mta = 0
         do 20 ia = icpu , napp , ncpu
            call getstr(na,isyma,ia,mta,icga)
            iapp = ic (mta)
            call elim1 ( icga,ioc1,m,na,itype,iwa,nwa)
            do 30 iww = 1,nwa
               nxi    = iwa (iww,1)
               iparit = iwa (iww,2)
               nxisym = iwa (iww,3)
               call add1 (ioc1(1,iww),m,na,m1,na1,itype,jwa,mwa,
     1              inter,nxisym,m1-na)
c     
               do 40 jww = 1, mwa
                  nxj  = jwa (jww,1)
                  isign = iparit * jwa (jww,2)
                  iap = ic ( jwa (jww,3) )
                  ij  = ic3e (iky( max (nxi,nxj))  + min(nxi,nxj) )
                  xval =   isign * skv (ij)
c..   the inner loop
                  if (xval.ne.0.0d0) then
                     rops = rops + nb
              call daxpy(nb,xval,c(iap+1),1,s(iapp+1),1)
                  endif
c     
 40            continue
 30         continue
 20      continue
 10   continue
c     
      return
      end
      subroutine onelb (c,s,skv,m,nb,itype,itz,inter,
     &     na1,m1,isss,iwb,jwb,ioc1,ic3e,rops,icpu,ncpu)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common /cor   / core
      common /ftimes / t0,td,t1,t2,t3,t4,t5,t6,t7
INCLUDE(common/mapper)
INCLUDE(common/cone)
INCLUDE(common/ci)
      dimension c(*),s(*),skv(*),itype(m),itz(*),ic3e(*)
      dimension iwb (nb,3)
      dimension jwb (m1-nb,4)
      dimension ioc1(nb,nb)
      dimension inter (na1,m1,2)
      dimension icgb (200)
c
c parallel version should be conmpiled re-entrant with all
c external references inlined
c
      rops = 0.0d0
      ipnt = 0
      do 10 isymb  =1,8
         nbpp = nstrb ( isymb  )
         if (nbpp.eq.0) goto 10
c rjh ... force odd skips between betas ... need for cray2
         incbp = nbpp + mod(nbpp+1,2)
         isyma = iperm ( isss,isymb)
         napp = (nstra(isyma))
c     
         mtb = 0
         do 20 ib = icpu , nbpp ,ncpu
            call getstr(nb,isymb,ib,mtb,icgb)
            ibpp = itz (mtb)
            call elim1 ( icgb,ioc1,m,nb,itype,iwb,nwb)
            do 30 iww = 1,nwb
               nxi    = iwb (iww,1)
               iparit = iwb (iww,2)
               nxisym = iwb (iww,3)
               call add1 (ioc1(1,iww),m,nb,m1,na1,itype,jwb,mwb,
     1              inter(1,1,2),nxisym,m1-nb)
c     
               do 40 jww = 1, mwb
                  nxj  = jwb (jww,1)
                  isign = iparit * jwb (jww,2)
                  ibp = itz ( jwb (jww,3) )
                  ij  = ic3e (iky ( max(nxi,nxj) ) + min(nxi,nxj))
                  xval =   isign * skv (ij)
c..   the inner loop
                  if (xval.ne.0.0d0) then
c                    iaa = ipnt
                     rops = rops + napp
             call daxpy(napp,xval,c(ibp+ipnt),incbp
     +       ,s(ibpp+ipnt),incbp)
                  endif
c     
 40            continue
 30         continue
 20      continue
         ipnt = ipnt + napp * incbp
 10   continue
c     
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine dena (c,skv,m,na,itype,ic,inter,
     &     na1,m1,isss,iwa,jwa,ioc1,ic3e,rops,icpu,ncpu)
      implicit REAL  (a-h,o-z)
c
c     This routine is a modified version of onela for
c     the purpose of calculating the 1-electron density
c     matrix.
c
INCLUDE(common/sizes)
      common /cor   / core
      common /ftimes / t0,td,t1,t2,t3,t4,t5,t6,t7
INCLUDE(common/mapper)
INCLUDE(common/cone)
INCLUDE(common/ci)
      common /clocks/ lockio
      dimension c(*),skv(*),itype(m),ic(*),ic3e(*)
      dimension iwa(na,3)
      dimension jwa(m1-na,4)
      dimension ioc1(na,na)
      dimension inter(na1,m1,2)
      dimension icga(200)
_IF1()c     
_IF1()c parallel version must be compiled reentrant with all external
_IF1()c references inlined
_IF1()c
_IF1()c     call lock(lockio)
_IF1()c     write(iwr,*) ' icpu, ncpu, m, na, na1, m1, isss',
_IF1()c    $       icpu, ncpu, m, na, na1, m1, isss
_IF1()c     call flush(iwr)
_IF1()c     call unlockf(lockio)
c
      rops = 0.0d0
      do 10 isyma=1,8
         if (nstra(isyma).eq.0) goto 10
         napp = (nstra(isyma))
         nb = nstrb ( iperm ( isss,isyma ) )
c     
         mta = 0
         do 20 ia = icpu , napp , ncpu
            call getstr(na,isyma,ia,mta,icga)
            iapp = ic (mta)
            call elim1 ( icga,ioc1,m,na,itype,iwa,nwa)
            do 30 iww = 1,nwa
               nxi    = iwa (iww,1)
               iparit = iwa (iww,2)
               nxisym = iwa (iww,3)
               call add1 (ioc1(1,iww),m,na,m1,na1,itype,jwa,mwa,
     1              inter,nxisym,m1-na)
c     
               do 40 jww = 1, mwa
                  nxj  = jwa (jww,1)
                  isign = iparit * jwa (jww,2)
                  iap = ic ( jwa (jww,3) )
                  ij  = ic3e (iky( max (nxi,nxj))  + min(nxi,nxj) )
c                 xval =   isign * skv (ij)
c..   the inner loop
c                 if (xval.ne.0.0d0) then
                     rops = rops + nb
                     skv(ij) = skv(ij) 
     +                       + isign*ddot(nb,c(iap+1),1,c(iapp+1),1)
c             call daxpy(nb,xval,c(iap+1),1,s(iapp+1),1)
c                 endif
c     
 40            continue
 30         continue
 20      continue
 10   continue
c     
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine denb (c,skv,m,nb,itype,itz,inter,
     &     na1,m1,isss,iwb,jwb,ioc1,ic3e,rops,icpu,ncpu)
      implicit REAL  (a-h,o-z)
c
c     This routine is a modified version of onelb for
c     the purpose of calculating the 1-electron density
c     matrix.
c
INCLUDE(common/sizes)
      common /cor   / core
      common /ftimes / t0,td,t1,t2,t3,t4,t5,t6,t7
INCLUDE(common/mapper)
INCLUDE(common/cone)
INCLUDE(common/ci)
      dimension c(*),skv(*),itype(m),itz(*),ic3e(*)
      dimension iwb (nb,3)
      dimension jwb (m1-nb,4)
      dimension ioc1(nb,nb)
      dimension inter (na1,m1,2)
      dimension icgb (200)
c
c parallel version should be conmpiled re-entrant with all
c external references inlined
c
      rops = 0.0d0
      ipnt = 0
      do 10 isymb  =1,8
         nbpp = nstrb ( isymb  )
         if (nbpp.eq.0) goto 10
c rjh ... force odd skips between betas ... need for cray2
         incbp = nbpp + mod(nbpp+1,2)
         isyma = iperm ( isss,isymb)
         napp = (nstra(isyma))
c     
         mtb = 0
         do 20 ib = icpu , nbpp ,ncpu
            call getstr(nb,isymb,ib,mtb,icgb)
            ibpp = itz (mtb)
            call elim1 ( icgb,ioc1,m,nb,itype,iwb,nwb)
            do 30 iww = 1,nwb
               nxi    = iwb (iww,1)
               iparit = iwb (iww,2)
               nxisym = iwb (iww,3)
               call add1 (ioc1(1,iww),m,nb,m1,na1,itype,jwb,mwb,
     1              inter(1,1,2),nxisym,m1-nb)
c     
               do 40 jww = 1, mwb
                  nxj  = jwb (jww,1)
                  isign = iparit * jwb (jww,2)
                  ibp = itz ( jwb (jww,3) )
                  ij  = ic3e (iky ( max(nxi,nxj) ) + min(nxi,nxj))
c                 xval =   isign * skv (ij)
c..   the inner loop
c                 if (xval.ne.0.0d0) then
c                    iaa = ipnt
                     rops = rops + napp
                  skv(ij) = skv(ij) 
     +                    + ddot(napp,c(ibp+ipnt),incbp,
     +                                c(ibpp+ipnt),incbp)*isign
c            call daxpy(napp,xval,c(ibp+ipnt),incbp
c    +       ,s(ibpp+ipnt),incbp)
c                 endif
c     
 40            continue
 30         continue
 20      continue
         ipnt = ipnt + napp * incbp
 10   continue
c     
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine orbadd (n,m1,n1,ncc,iorb,mts,mt,icg,
     &     nsym,inter,ic,jw,nw,nblk)
c     
      dimension icg (n),inter(n1,m1),ic(*)
      dimension jw(nblk,3)
c     
_IF1(a)cvd$r noconcur
_IF1(a)cvd$r novector
      nw = 0
      do 1 ia = 1,ncc
         mts = mts + 1
         if (n.gt.1) call getstr(n-1,nsym,mts,mt,icg)
c     
         itmp = 1
         iap = 1
         isign = 1
         do 20 i = 1,n-1
            if (icg(i) .lt. iorb ) then
               isign = -isign
               iap = iap + inter (i,icg(i))
               itmp = i + 1
            else if (icg(i).eq.iorb) then
               goto 1
            else
               itmp = i
               goto 21
            endif
 20      continue
c     
 21      continue
         iap = iap + inter (itmp,iorb)
_IF1(ct)cdir$ novector
_IF1(x)c$dir scalar
         do 25 i = itmp , n-1
            iap  = iap + inter (i+1,icg(i))
 25      continue
c     
         nw = nw+1
         jw (nw,1) = ia
         jw (nw,2) = isign
         jw (nw,3) = ic (iap)
c     
 1    continue
c     
      return
      end
_IF(ibm,vax,fps)
      subroutine pack(p,nbits,u,nw)
      byte p(*),u(4,nw)
c
      if (nbits.eq.4) then
         call pack4(p,u,nw)
      else if (nbits.eq.8) then
         do 20 i = 1,nw
            p(i) = u(4,i)
 20      continue
      else if (nbits.eq.16) then
         call pack16(p,u,nw)
      else if (nbits.eq.32) then
         call icopy(nw,u,1,p,1)
      else
         call dump(' nbits 8,16,32 only ',nbits)
      endif
c
      end
      subroutine pack16(p,u,n)
      integer*2 p(n),u(2,n)
c
      do 10 i = 1,n
         p(i) = u(2,i)
 10   continue
c
      return
      end
      subroutine pack4(p,u,n)
      integer*4 p(*),u(*)
      m8(i,j) = ior(ishft(i,4),j)
c
      i8 = 0
      do 10 i = 1,(n-1)/8 + 1
          p(i) = m8(m8(m8(m8(m8(m8(m8(
     &         u(i8+8) ,u(i8+7)),u(i8+6)),u(i8+5)),
     &         u(i8+4)),u(i8+3)),u(i8+2)),u(i8+1))
          i8 = i8 + 8
10    continue
c
      return
      end
      subroutine unpack(p,nbits,u,nw)
      implicit REAL  (a-h,o-z)
      byte p(nw),u(4,nw)
c
      call izero(nw,u,1)
c
      if (nbits.eq.4) then
        call upck4(p,u,nw)
      else if (nbits.eq.8) then
         do 20 i = 1,nw
            u(4,i) = p(i)
 20      continue
      else if (nbits.eq.16) then
         call upck16(p,u,nw)
      else if (nbits.eq.32) then
         call icopy(nw,p,1,u,1)
      else
         call dump(' nbits 8,16,32 only ',nbits)
      endif
c
      return
      end
      subroutine upck16(p,u,n)
      integer*2 p(n),u(2,n)
c
      do 10 i = 1,n
         u(2,i) = p(i)
 10   continue
c
      end
      subroutine upck4(p,u,n)
      integer*4 p(*),u(*)
      m8(i,j) = ior(ishft(i,4),j)
c
      mask = 15
      i8 = 0
_IF1(a)cvd$  novector
_IF1(s)cvd$  noconcur
      do 10 i = 1,(n-1)/8 + 1
          ip = p(i)
          u(i8+1) = iand(ip,mask)
          ip = ishft(ip,-4)
          u(i8+2) = iand(ip,mask)
          ip = ishft(ip,-4)
          u(i8+3) = iand(ip,mask)
          ip = ishft(ip,-4)
          u(i8+4) = iand(ip,mask)
          ip = ishft(ip,-4)
          u(i8+5) = iand(ip,mask)
          ip = ishft(ip,-4)
          u(i8+6) = iand(ip,mask)
          ip = ishft(ip,-4)
          u(i8+7) = iand(ip,mask)
          ip = ishft(ip,-4)
          u(i8+8) = iand(ip,mask)
          ip = ishft(ip,-4)
          i8 = i8 + 8
10    continue
c
      end
_ENDIF
      subroutine putrec(iunit,irec,n,v,coeff)
      implicit REAL  (a-h,o-z)
_IF1(cfu)      parameter (acc = 6.0e-8)
_IFN1(cfu)      parameter (acc = 6.0d-8)
      common /ciorec/ rword(99,2),rtime(99,2),
     + ipos(99),ipack(99),ireqst(99,3)
INCLUDE(common/iofile)
INCLUDE(common/ci)
      dimension v(n)
c
c     simple i/o system to manipulate a few records of different
c     length on a sequential file.
c     ipos(iunit) = set to read this record (or -1 if not active)
c     ipack(iunit) =  -1 ... file is not packed
c                  =   0 .. nbits is dynamically determined
c                  =  +nbits ... pack to nbits
c     everything else is just gathering statistics
c
      call setrec(iunit,irec)
      nbits = ipack(iunit)
      if (nbits.lt.0) then
         nw = n
         vbig = 0.0d0
      else if (nbits.gt.0) then
         call cmpres(n,nbits,v,v,vbig,nw)
      else
         vbig = dabs(v(idamax(n,v,1)))
         nbits = -log(acc/(vbig*coeff))/log(2.0d0)
         nbits = max(((nbits+3)/4)*4,4)
         if (nbits.gt.24) call dump(' putrec nbits ',nbits)
c        write(iwr,*) ' PUTREC ',iunit,nbits,coeff
         call cmpres(n,nbits,v,v,vbig,nw)
      endif
c
      call gettim(c1,e1)
      write (iunit) nbits,nw,vbig
      call swrite(iunit,nw,v)
      call gettim(c2,e2)
c
      if (nbits.gt.0) call expand(n,nbits,v,v,vbig)
      ireqst(iunit,2) = ireqst(iunit,2) + 1
      rword(iunit,2) = rword(iunit,2) + nw
      rtime(iunit,2) = rtime(iunit,2) + e2 - e1
      ipos(iunit) = ipos(iunit) + 1
      return
c     
      entry getrec(iunit,irec,n,v)
      call setrec(iunit,irec)
      call gettim(c1,e1)
      read (iunit) nbits,nw,vbig
      call sread(iunit,nw,v)
      call gettim(c2,e2)
      if (nbits.gt.0) call expand(n,nbits,v,v,vbig)
c
      ireqst(iunit,1) = ireqst(iunit,1) + 1
      rword(iunit,1) = rword(iunit,1) + nw
      rtime(iunit,1) = rtime(iunit,1) + e2 - e1
      ipos(iunit) = ipos(iunit) + 1
      return
c     
      entry skprec(iunit)
      read (iunit)
      read (iunit)
      ireqst(iunit,1) = ireqst(iunit,1) + 1
      ipos(iunit) = ipos(iunit) + 1
      return
c
      entry inirec
      do 10 i = 1,99
         ipos(i) = -1
         ipack(i) = -1
         ireqst(i,1) = 0
         ireqst(i,2) = 0
         ireqst(i,3) = 0
         rword(i,1) = 0.0d0
         rword(i,2) = 0.0d0
         rtime(i,1) = 0.0d0
         rtime(i,2) = 0.0d0
 10   continue
      rewind 2
      rewind 3
      rewind 4
      ipos(2) = 1
      ipos(3) = 1
      ipos(4) = 1
chvd  needed in the davidson as tmp-file during restarting
      ipos(8) = 1
c set this to the desired no. of bits 4,8,12,16,20,24,28
c or comment out for no packing of the CI vector
c     ipack(3) = 4
c
      return
c
      entry sumrec
      if(outon)write(iwr,1000)
 1000 format(/' i/o summary '/,' ==========='//
     & ' unit  type   count     mw      time (s)     mw/s     pack'/
     & ' ====  =====  =====  =========  =========  =========  ====')
      do 20 i = 1,99
         if (ipos(i).ne.-1) then
            rtime(i,1) = max(rtime(i,1),0.001d0)
            rtime(i,2) = max(rtime(i,2),0.001d0)
            if(outon) then
             write(iwr,1001) i,'read ',ireqst(i,1),rword(i,1)*1.0d-6,
     &            rtime(i,1),rword(i,1)*1.0d-6/rtime(i,1),ipack(i)
             write(iwr,1001) i,'write',ireqst(i,2),rword(i,2)*1.0d-6,
     &            rtime(i,2),rword(i,2)*1.0d-6/rtime(i,2),ipack(i)
             write(iwr,1001) i,'rewnd',ireqst(i,3)
 1001        format(1x,i4,2x,a5,2x,i5,f9.2,2x,f9.2,2x,f9.2,2x,i4)
            endif
         endif
 20   continue
c
      return
      end
      subroutine setrec(iunit,irec)
      implicit REAL  (a-h,o-z)
      common /ciorec/ rword(99,2),rtime(99,2),
     &                ipos(99),ipack(99),ireqst(99,3)
c
c position sequential file to read/write record irec assuming
c that it is positioned at record ipos(iunit)
c
      if (ipos(iunit).le.0) then
         call dump (' setvec: file is not active ',iunit)
      else if (ipos(iunit).gt.irec) then
         ireqst(iunit,3) = ireqst(iunit,3) + 1
         rewind iunit
         ipos(iunit) = 1
      endif
c
      ip = ipos(iunit)
      do 10 k = ip,irec-1
         read (iunit)
         read (iunit)
         ireqst(iunit,1) = ireqst(iunit,1) + 1
         ipos(iunit) = ipos(iunit) + 1
 10   continue
c     
      return
      end
      subroutine single (v,na,nb,isss,ic,itz)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/ci)
      dimension v(*),ic(*),itz(*)
      if (na.ne.nb) return
      nlook=0
      nconf=0
c***  loop thru symmetry types
      do 310 isyma=1,8
c***  loop thru alpha strings of given sym
         mta=0
         do 300 ia=1,nstra(isyma)
            call getmt(na,isyma,ia,mta)
            icmta=ic(mta)
            isymb=iperm(isyma,isss)
c***  loop thru beta strings of required sym
            mtb=0
            do 290 ib=1,nstrb(isymb)
               call getmt(nb,isymb,ib,mtb)
               icmtb=ic(mtb)
               coefab=v(icmta+itz(mtb))
               coefba=v(icmtb+itz(mta))
               coef=(coefab+coefba)*0.5d0
               v(icmta+itz(mtb))=coef
               v(icmtb+itz(mta))=coef
               nlook=nlook+1
               nconf=nconf+1
 290        continue
 300     continue
 310  continue
      return
      end
_IFN(hp700,hpux11)
      subroutine swrite(iunit,n,v)
      implicit REAL  (a-h,o-z)
      dimension v(n)
c
      write (iunit) v
      call flushn(iunit)
      return
c
      entry sread(iunit,n,v)
      read (iunit) v
c
      return
      end
_ENDIF
_IF(hp700,hpux11)
      subroutine swrite(num3,nword,q)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(*)
      j=1
      k=nword
 20   if(k)30,30,10
 10   call wtfors(q(j),min(k,5120),num3)
      j=j+5120
      k=k-5120
      go to 20
30    return
      end
      subroutine sread(num3,nword,q)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(*)
      j=1
      k=nword
 20   if(k)30,30,10
 10   call rdfors(q(j),min(k,5120),num3)
      j=j+5120
      k=k-5120
      go to 20
30    return
      end
_ENDIF
      subroutine timer(t)
      implicit REAL  (a-h,o-z)
      save tlast,i
      data i/0/
      if (i.eq.0) then
      tlast=0.0d0
      endif
      call gettim(cpu,elaps)
      tnow = cpu
      t=t+tnow-tlast
      tlast=tnow
      i=1
      return
      end
      subroutine unlockf(lockio)
      implicit REAL  (a-h,o-z)
      return
      end
      subroutine vecpr (v,thresh,na,nb,isss,ic,itz)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/ci)
      common /ftimes / t(10)
INCLUDE(common/iofile)
      dimension v(*),ic(*),itz(*)
      dimension icga(200),icgb(200)
      character*80 fmat
c
      write(fmat,1) na,nb
 1    format('(i8,f11.6,4x,',i2,'i3,8x,',i2,'i3)')
      if(outon)write(iwr,*) fmat
      nlook=0
      nconf=0
      if(outon)write(iwr,10)
 10   format(/15x,'analysis of ci vector'/
     *        15x,'=====================')
      if(outon)write(iwr,5)
 5    format(/1x,'   no. ',' coefficient','     occupation'/
     *        1x,'-------',' -----------','     ----------')
c***  loop thru symmetry types
      do 310 isyma=1,8
c***  loop thru alpha strings of given sym
         mta=0
         do 300 ia=1,nstra(isyma)
            call getstr(na,isyma,ia,mta,icga)
            icmta=ic(mta)
            isymb=iperm(isyma,isss)
c***  loop thru beta strings of required sym
            mtb=0
            do 290 ib=1,nstrb(isymb)
               call getstr(nb,isymb,ib,mtb,icgb)
               coef=v(icmta+itz(mtb))
               nlook=nlook+1
               if(dabs(coef).lt.thresh) goto 290
               nconf=nconf+1
               if(outon)write(iwr,fmat) nconf,coef,(icga(i),i=1,na),
     &              (icgb(i),i=1,nb)
 290        continue
 300     continue
 310  continue
      if(outon)write(iwr,90) nlook,nconf,thresh
 90   format(/1x,'Examined',i8,' coefficients. Found',i8,
     & ' greater than ',f20.10)
c
      return
      end
      subroutine vecpun(v,thresh,na,nb,isss,ic,itz)
      implicit REAL  (a-h,o-z)
INCLUDE(common/cone)
INCLUDE(common/ci)
      common /ftimes / t(10)
INCLUDE(common/iofile)
      dimension v(*),ic(*),itz(*)
      dimension icga(200),icgb(200)
      character*80 fmat
c
      write(fmat,1) na,nb
 1    format('(i8,f12.8,4x,',i2,'i3,8x,',i2,'i3)')
      write(ipu,*) fmat
      nlook=0
      nconf=0
      write(iwr,10)
 10   format(/15x,'punch ci vector'/
     *        15x,'===============')
c***  loop thru symmetry types
      do isyma=1,8
c***  loop thru alpha strings of given sym
         mta=0
         do ia=1,nstra(isyma)
            call getstr(na,isyma,ia,mta,icga)
            icmta=ic(mta)
            isymb=iperm(isyma,isss)
c***  loop thru beta strings of required sym
            mtb=0
            do ib=1,nstrb(isymb)
               call getstr(nb,isymb,ib,mtb,icgb)
               coef=v(icmta+itz(mtb))
               nlook=nlook+1
               if(dabs(coef).ge.thresh) then
                nconf=nconf+1
                write(ipu,fmat) nconf,coef,(icga(i),i=1,na),
     &          (icgb(i),i=1,nb)
               endif
            enddo
         enddo
      enddo
      write(iwr,90) nlook,nconf,thresh
 90   format(/1x,'Examined',i8,' coefficients. Punched',i8,
     & ' greater than ',f20.10)
c
      close(ipu,status='keep')
c
      return
      end
      subroutine ver_fullci(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/fullci.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
