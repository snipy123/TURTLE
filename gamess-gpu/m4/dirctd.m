c
c  $Author: jmht $
c  $Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
c  $Locker:  $
c  $Revision: 5774 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/dirctd.m,v $
c  $State: Exp $
c
      subroutine cntrci(conf,cr1,cr2,iblk1,iblk2,cr,ic1,ic12,sum12)
c
c...  contract a combination of c/z vectors to contributions
c...  per model configuration  for mrdcepa / i.e. all refs together
c...  note for n-2 contraction per spin-type
c     cr1  : vector 1   (iblk1 block-number if out-store)
c     cr2  : vector 2   (iblk2 block-number if out-store)
c     cr   : start of result-array for contractesd products
c     ic1  : index of array for the contracted <c/c>-vector (if>0)
c     ic12 : index of array to receive the contracted <c/z>-vector
c            length nnst-nref+1 + nmin1 + 2*nmin2
c     icpsto if .true. no reading needs to be done
c
      implicit REAL (a-h,o-z)
_IF(cray,t3e,i8)
      integer conf(5,*)
_ELSEIF(convex,i8drct)
      integer *8 conf(5,*)
_ELSE
      REAL conf(5,*)
_ENDIF
      dimension cr1(*),cr2(*),cr(*)
c
INCLUDE(common/ccntl)
INCLUDE(common/disktl)
INCLUDE(common/cntrl)
INCLUDE(common/symci)
INCLUDE(common/ccepa)
INCLUDE(common/mr_cepctl)
c
c...  vacuum
c
      nref1 = nref + 1
      kc1 =  (ic1-1)*ncpcc + 1
      kc12 = (ic12-1)*ncpcc + 1
      if (.not.icpsto) then
         call brtsb(iblk1)
         call brtsc(iblk2)
         call getsbcz(cr1,nval)
         call getsccz(cr2,nval)
c        call rdedx(cr1,nval,iblk1,numci)
c        call rdedx(cr2,nval,iblk2,numci)
      end if
      cr(kc12) = ddot(nrfcsf,cr1,1,cr2,1)
      if (ic1.gt.0) cr(kc1) = ddot(nrfcsf,cr1,1,cr1,1)
      kc = 1
      if (nnst.eq.nref) go to 7
      do 5 loop=nref1,nnst
_IF(cray,i8,convex,t3e,i8drct)
         lams=conf(3,loop)
         kk=conf(1,loop)
_ELSE
         lams = ipad(conf(3,loop))
         kk = ipad(conf(1,loop))
_ENDIF
         cr(kc12+kc) = ddot(lams,cr1(kk+1),1,cr2(kk+1),1)
         if (ic1.gt.0) cr(kc1+kc) = ddot(lams,cr1(kk+1),1,cr1(kk+1),1)
5     kc = kc + 1
c
c...  doublets
c
7     if (ndoub.le.0) go to 17
      if (icpsto) then
         kk = nval + 1
      else
         call getsbcz(cr1,ndoub)
         call getsccz(cr2,ndoub)
_IF()
        call rdedx(cr1,ndoub,iblk1+ipad(conf(2,1)),numci)
        call rdedx(cr2,ndoub,iblk2+ipad(conf(2,1)),numci)
_ENDIF
         kk = 1
      end if
 
8     do 10 loop=nstrt1,nlast1
_IF(cray,i8,convex,t3e,i8drct)
         isi=conf(4,loop)
         nn = norbe(isi)*conf(3,loop)
_ELSE
         isi = ipad(conf(4,loop))
         nn = norbe(isi)*ipad(conf(3,loop))
_ENDIF
         cr(kc12+kc) = ddot(nn,cr1(kk),1,cr2(kk),1)
         if (ic1.gt.0) cr(kc1+kc) = ddot(nn,cr1(kk),1,cr1(kk),1)
         kc = kc + 1
10    kk = kk + nn
c
c...    n-2 's
c***    note the minor trouble by difference in storing
c***    singlet/triplet n-2's in store and on disk / in store
c***    all singlets are adjacent / on disk the singlet and
c***    triplet from one model-config. are adjacent
c***    also some triplets may not be present
c
17    if (nstrt2.gt.nlast2) go to 27
      call vclr(cr(kc12+kc),1,nmin2*2)
      if (ic1.gt.0) call vclr(cr(kc1+kc),1,nmin2*2)
c
      kks = nval + ndoub + 1
      kkt = kks + nsingl
      do 20 loop=nstrt2,nlast2
_IF(convex,cray,i8,t3e,i8drct)
         isi=conf(4,loop)
_ELSE
         isi = ipad(conf(4,loop))
_ENDIF
         call upack2(conf(3,loop),lamt,lams)
         ns = lams*norbsi(isi)
         nt = lamt*norbtr(isi)
         if (.not.icpsto) then 
            call upack2(conf(2,loop),kkc,jc)
            call getsbcz(cr1,ns+nt)
            call getsccz(cr2,ns+nt)
c           call rdedx(cr1,ns+nt,iblk1+jc,numci)
c           call rdedx(cr2,ns+nt,iblk2+jc,numci)
            kks = 1
            kkt = kks + ns
         end if
c..   singlets
         if (ns.eq.0) go to 19
            cr(kc12+kc) = ddot(ns,cr1(kks),1,cr2(kks),1)
	    if (ic1.gt.0) cr(kc1+kc) = ddot(ns,cr1(kks),1,cr1(kks),1)
            kks = kks + ns
c..   triplets
19       if (nt.eq.0) go to 20
	    cr(kc12+kc+1) = ddot(nt,cr1(kkt),1,cr2(kkt),1)
            if (ic1.gt.0) cr(kc1+kc+1) = ddot(nt,cr1(kkt),1,cr1(kkt),1)
            kkt = kkt + nt
20    kc = kc + 2
c
27    sum12 = 0.0d0
      do 28 i=1,ncpcc
28    sum12 = sum12 + cr(kc12-1+i)
c
      return
      end
      subroutine hh2cep(cc,nc,conf,h,hs,h2,h2s,xn,ndim)
c
c...  produce the modified <h> and <h**2> matrices by applying
c...  the (mrd)cepa diagonal shifts. use the saved original <hs>
c...  and <h2s> matrices and the contracted <c.c> and <c.z> vectors
c...  (from disc) / dimension of h-matrices is ndim
c...   normalisation-factors for the c-vectors are stored in xn
c
      implicit REAL (a-h,o-z)
_IF(cray,i8,t3e)
      integer conf
_ELSEIF(convex,i8drct)
      integer*8 conf
_ELSE
      REAL conf
_ENDIF
      dimension cc(nc,5),conf(5,*)
      dimension h(*),hs(*),h2(*),h2s(*),xn(ndim)
c
INCLUDE(common/mr_cepctl)
INCLUDE(common/disktl)
c
c...  set up shifts and shift**2 arrays
c
      call expdsh(conf,cc(1,1))
      call vvtv(ncpcc,cc(1,2),cc(1,1),cc(1,1))
c
      kh = 1
      kbl = kcpbl
c
c...  go over the h-matrix-triangle
c
      do 20 i=1,ndim
         do 10 j=1,i
c...  read contracted vectors  (ci.cj / ci.zj / zi.cj)
            call rdedx(cc(1,3),ncpcc*3,kbl,numci)
c...  h = hs + <ci/diag/cj>
            h(kh) = hs(kh) + ddot(ncpcc,cc(1,1),1,cc(1,3),1)
     *                     * xn(i)*xn(j)

c...  hs = h2s + <ci/diag/zj> + <zi/diag/cj> + <ci/diag**2/cj>
            h2(kh) = h2s(kh)  + ( ddot(ncpcc,cc(1,1),1,cc(1,4),1)
     *                        +   ddot(ncpcc,cc(1,1),1,cc(1,5),1)
     *                        +   ddot(ncpcc,cc(1,2),1,cc(1,3),1) )
     *                        *   xn(i)*xn(j)
c
            kh = kh + 1
            kbl = kbl + ncpbl
c
10       continue
20    continue
c
      return
      end
      subroutine ccijkl(conf,cr)
      implicit real*8(a-h,o-z)
_IF(cray,i8,t3e)
      integer conf
_ELSEIF(convex,i8drct)
      integer*8 conf
_ELSE
      REAL conf
_ENDIF
      dimension cr(*), conf(5,*)
c     common//iconf(2,5,1)
INCLUDE(common/mr_cepctl)
INCLUDE(common/cdcryz)
      common/spew/rmode(5)
      equivalence (rmode(1),model),(rmode(2),ic),(rmode(3),ir),
     * (rmode(4),kkkbas),(rmode(5),itrans)
c     equivalence (iconf(1,1,1),cr(1))
ccepa
INCLUDE(common/mr_pairs)
ccepa
c...
c... (ij/kl)    vacuum/vacuum    pair-energy contributions (mrdcepa)
c...
      if (model.eq.1) return
999   call getsb(rmode(2),2)
_IF(cray,i8,i8drct)
      nc=conf(3,ic)
      nr=conf(3,ir)
_ELSE
      nc=ipad(conf(3,ic))
      nr=ipad(conf(3,ir))
_ENDIF
      call getsb(cr(kcpill+1),nc*nr)
_IF(cray,i8,i8drct)
      icbas=conf(1,ic)
      irbas=conf(1,ir)
_ELSE
      icbas=ipad(conf(1,ic))
      irbas=ipad(conf(1,ir))
_ENDIF
      call mxmd(cr(kcpill+1),1,nr,cr(icbas+kcpv+1),1,1,
     *          cr(kcpz+1),1,1,nr,nc,1)
      call upack2(conf(5,ic),iisi,iish)
      epair(iisi,iish) = epair(iisi,iish) +
     1                   ddot(nr,cr(kcpz+1),1,cr(irbas+kcpv+1),1)
      call getsb(rmode(1),1)
      if(model.eq.22)goto 999
      return
      end
      subroutine ccijka(conf,cr)
      implicit real*8(a-h,o-z)
INCLUDE(common/sizes)
c...  doublet/vacuum (ij/ka) - fock(ia) pair contributions
_IF(cray,t3e,i8)
      integer conf
_ELSEIF(convex,i8drct)
      integer *8 conf
_ELSE
      REAL conf
_ENDIF
      dimension cr(*), conf(5,*)
c     common//iconf(2,5,1)
      common/loco/integr,iduml,scr(201)
      common/spew/rmode(8)
      equivalence (rmode(1),model),(rmode(2),ic),(rmode(3),ir),
     * (rmode(4),ninti),(rmode(5),itrans),(rmode(6),icfock),
     * (rmode(7),integr2),(rmode(8),iduml2)
INCLUDE(common/diactl)
INCLUDE(common/symci)
INCLUDE(common/helpr)
INCLUDE(common/disktl)
INCLUDE(common/ccntl)
INCLUDE(common/ccepa)
INCLUDE(common/mr_cepctl)
INCLUDE(common/cdcryz)
      common/stoctl/khbill,khbz,khbc,khbb,khbzd,khbzs,khbzt,khbcd,
     *khbcs,khbct,kh,khb1,khb2,khb3,khb4,khb5,khb6,khb7,khb8
     *,khb44,khb55,khb66,khb88,khb111,khb222,khb333
INCLUDE(common/mr_pairs)

      logical fock
ccepa
c     equivalence (iconf(1,1,1),cr(1))
       icl=0
       kcpx=khbb+m2em1e
c... kcpill   (ij/ka) integrals
c... kcpx     coupling coefficients
c... read (ij/ka) integrals
c
      call rdedx(cr(kcpill+1),m2e,index(2),numci)
crz
c
                   if (ibrst.eq.0) then
c
crz...exclude brillouin states
c
      fock= .false.
c
55    call getsb(rmode(2),3)
      if(ic.eq.icl)goto 500
      icl=ic
      irl = ir
      fock = .false.
_IF(cray,i8,i8drct)
      itop=conf(1,ic)
_ELSE
      itop=ipad(conf(1,ic))
_ENDIF
      khcdub=kcpd+itop
_IF(cray,i8,i8drct)
      ne=norbe(conf(4,ic))
_ELSE
      ne=norbe(ipad(conf(4,ic)))
_ENDIF
      call upack2(conf(5,ic),iisi,iish)
_IF(cray,i8,i8drct)
      lamd=conf(3,ic)
500   lamv=conf(3,ir)
      itop=conf(1,ir)
_ELSE
      lamd=ipad(conf(3,ic))
500   lamv=ipad(conf(3,ir))
      itop=ipad(conf(1,ir))
_ENDIF
      khi=ninti+kh
      call getsb(cr(kcpx+1),lamv*lamd)
ccepa
      if (ir.gt.nref) go to 504
      if (ir.ne.irl) fock = .false.
      irl = ir
ccepa
      if (khi.lt.kcpill+m2e) go to 502
c.... ch-coefficients   => move to safety
      fock = .true.
      call fmove(cr(kcpx+1),cr(kcpcd+1),lamv*lamd)
c.... precompute  cnorm
      cnorm = ddot(lamd,cr(kcpcd+1),lamv,cr(kcpcd+1),lamv)
      go to 504
ccepa     2-electron contributions / substract fock ??
502   if (.not.fock) go to 503
      i1 = 1
      do 501 i=1,lamv
         cbk = -ddot(lamd,cr(kcpcd+i1),lamv,cr(kcpx+i1),lamv)/cnorm
         call daxpy(lamd,cbk,cr(kcpcd+i1),lamv,cr(kcpx+i1),lamv)
501   i1 = i1 + 1
ccepa
c... construct m
503   call mxmd(cr(khcdub+1),ne,1,cr(khi+1),1,1,scr(1),1,1,
     *lamd,ne,1)
c...  z vacuum
      if (instor) kcpz=khbz+itop
      call mxmd(cr(kcpx+1),1,lamv,scr(1),1,1,cr(kcpz+1),1,1,
     *lamv,lamd,1)
c...  update pair energy
      epair(iisi,iish) = epair(iisi,iish) +
     1                   ddot(lamv,cr(kcpz+1),1,cr(kcpv+itop+1),1)
c
504   call getsb(rmode(1),1)
      if(model.eq.5)goto 55
crz
c
                   else
c
crz..include brillouin states as in standard mrdci
c
c....initiate input of fock(ia) operators
      call brtsc(index(3))
      call getsc(rmode(6),1)
      loijka=.true.
77    call getsb(rmode(2),3)
      if(ic.eq.icl) goto 700
      icl = ic
_IF(cray,i8,i8drct)
      itop = conf(1,ic)
_ELSE
      itop = ipad(conf(1,ic))
_ENDIF
      khcdub = kcpd + itop
_IF(cray,i8,i8drct)
      ne = norbe(conf(4,ic))
_ELSE
      ne = norbe(ipad(conf(4,ic)))
_ENDIF
      call upack2(conf(5,ic),iisi,iish)
_IF(cary,i8,t3e,i8drct)
      lamd = conf(3,ic)
_ELSE
      lamd = ipad(conf(3,ic))
_ENDIF
701     if(ic-icfock) 700,1,2
c.....skip redundant fock operator
_IF(cray,i8,t3e,i8drct)
2     call skipsc(norbe(conf(4,icfock))+2)
_ELSE
2     call skipsc(norbe(ipad(conf(4,icfock)))+2)
_ENDIF
      go to 800
c......get fock operator
1     call getsc(rmode(7),2)
      integr=integr2
      iduml=iduml2
      call getsc(cr(integr+kh+1),ne)
800   call getsc(rmode(6),1)
      go to 701
_IF(cray,i8,i8drct)
700   lamv = conf(3,ir)
      itop = conf(1,ir)
_ELSE
700   lamv = ipad(conf(3,ir))
      itop = ipad(conf(1,ir))
_ENDIF
      khi = ninti + kh
      call getsb(cr(kcpx+1),lamv*lamd)
c...  06/04/95  next line skips vacuum doublet contributions outside
c...  of ref-space that were erroneously included
c
      if(ir.gt.nref) go to 704
ccepa
703   call mxmd(cr(khcdub+1),ne,1,cr(khi+1),1,1,scr(1),1,1,
     *lamd,ne,1)
c...  z vacuum
      if (instor) kcpz=khbz+itop
      call mxmd(cr(kcpx+1),1,lamv,scr(1),1,1,cr(kcpz+1),1,1,
     *lamv,lamd,1)
c...  update pair energy
      epair(iisi,iish) = epair(iisi,iish) +
     1                   ddot(lamv,cr(kcpz+1),1,cr(kcpv+itop+1),1)
c
704   call getsb(rmode(1),1)
      if(model.eq.5)goto 77
crz
c
                   end if
c
      return
      end
      subroutine setstr(n,rtext,rlab)
c...   set double precision reals
      implicit real*8 (a-h,o-z), integer*4 (i-n)
      dimension rlab(n)
c
      do 10 i=1,n
         rlab(i)=rtext
10    continue
c
      return
      end

      subroutine expdsh(conf,shifts)
c
c...  expand (mrd)cepa shifts into shifts/model configuration
c...  **note** the first shift [for vacuum] is always 0.0
c...  the shift array produced is used in an inner-product with
c...  the results from cntrci
c
      implicit REAL (a-h,o-z)
_IF(cray,t3e,i8)
      integer conf
_ELSEIF(convex,i8drct)
      integer *8 conf
_ELSE
      REAL conf
_ENDIF
      dimension conf(5,*),shifts(*)
c
INCLUDE(common/ccntl)
INCLUDE(common/cntrl)
INCLUDE(common/ccepa)
INCLUDE(common/mr_pairs)
c
      shifts(1) = 0.0d0
      kc = 2
c
c...  vacuum
c
      nref1 = nref + 1
      if (nref1.gt.nnst) go to 7
      do 5 loop=nref1,nnst
         call upack2(conf(5,loop),iisi,iish)
         shifts(kc) = eshifc(iisi,iish)
5     kc = kc + 1
c
c...  doublets
c
7     if (ndoub.le.0) go to 17
      do 10 loop=nstrt1,nlast1
         call upack2(conf(5,loop),iisi,iish)
         if (icepa.lt.10) then
            shifts(kc) = eshifd(iish)
         else
            shifts(kc) = eshifc(iisi,iish)
         end if
10    kc = kc + 1
c
c...    n-2 's
c
17    if (nstrt2.gt.nlast2) go to 27
      do 20 loop=nstrt2,nlast2
         call upack2(conf(5,loop),iisi,iish)
         shifts(kc) = eshifc(iisi,iish)
         if (icepa.lt.10) then
            shifts(kc+1) = eshifc(iish,iisi)
         else
            shifts(kc+1) = eshifc(iisi,iish)
         end if
20    kc = kc + 2
c
27    continue
c
      return
      end

      subroutine vvtv(n,r,a,b)
c**    cy205 utility / r = a*b
      implicit double precision (a-h,o-z), integer (i-n)
c
      dimension r(n),a(n),b(n)
       do 10 i=1,n
10     r(i) = a(i) * b(i)
c
      return
      end

      subroutine cepijkl(cj,ck,cx,ch,conf,cr)
c
c*ap*   jsut for fun try this one with integer iconf(2,5,1)
cjvl    now back again
c
      implicit REAL (a-h,o-z)
_IF(cray,t3e,i8)
      integer conf
_ELSEIF(convex,i8drct)
      integer *8 conf
_ELSE
      REAL conf
_ENDIF
      external ihint
      dimension cr(*),cj(*),ck(*),cx(*),ch(*)
      dimension conf(5,*)
      dimension xnumb(2)
c
c     utrechts mrd-cepa(0) option  march 1985
c          p.j.a. ruttink  / j.h. van lenthe
c
c                pair-energy calculation
c     compute the h-matrix between vacuum states
c==== vacuum - internal excitation interactions =======only==========
c     **     the fock-type contributions are skipped/excluded      **
c
c ###  extra option  include brillouin states  if brst is given in
c      input --  renate zwaans  april 1988 ####
c
INCLUDE(common/ccntl)
INCLUDE(common/ccepa)
      common/cdcray/ n32,mms,ms,magic,nd32,n32m
      common/spew/rmode(5)
      common/symcon/norbbb(7),nd,ii,jj,kk,ll,konte(14)
      common/three/n1l(1024),n2l(1024),minlhs(64),maxlhs(64),iocc(64),
     *n1r(1024),n2r(1024),minrhs(64),maxrhs(64),jocc(64),modelr
      common/orb/nint,next,ninnex,nwm1,nw,nwp1
      equivalence (rmode(1),model), (rmode(2),ic), (rmode(3),ir)
      data xnumb/1.0d0,2.0d0/
c
      nref1 = nref + 1
      if (nref1.gt.nnst) go to 99999
      do 1001 ic=nref1,nnst
c...  check excitation class (1 => no holes / under-cover ref)
         call upack2(conf(5,ic),i1,i2)
         if (i2.eq.1) go to 1001
c
         call expan1(conf(1,ic))
c
         call upack2(conf(3,ic),ncolt,ncols)
c
         do 1000 ir=1,nref
            call expan2(conf(1,ir))
c.... establish number of differences
c.... if more then 4 => no future in it
            if (nd.gt.4) go to 1000
            call upack2(conf(3,ir),nrowt,nrows)
            ndims=nrows*ncols
            call vclr(cx,1,ndims)
c
            if (nd.gt.2) go to 100

c
crz   include brillouin states - skip brillouin part
crz
c
                   if ( ibrst.eq.0) then
c
c.... single difference
c...  fock-matrix (brillouin) part : sum <br/d><d/h/r> (over sigma)
c...                                       ch    ck's
c...  normalization of br : sum <br/d><d/br> = sum  ch.ch
c...  so the following exchange coupling
c...   ch . sum ch.ck / sum ch.ch
c...  must be excluded
c...  all summation run over ncols ( # spins of the excited config)
c
c     *** note the second conf defines the most rapid varying index ***
            call symb1
            call sym1tr(ch,ifl,0,0)
c.... precompute normalisation (same for all)
            cnorm = ddot(ncols,ch,nrows,ch,nrows)
c.... loop over the k-orbitals
            do 80 k=1,nint
               iocci=iocc(k)
c.... we are only interested in singly occupied k-orbitals
c     (diffrent from ii and jj)
               if(iocci.ne.1.or.k.eq.ii.or.k.eq.jj) go to 80
c.... k singly occupied => interesting coupling
               call symb2(k,0)
               call symbtr(cj,ck,ifl,0,0)
               if (ifl.eq.0) go to 80
               exch=cr(irint(ii,k,jj,k))
c...
c...  compute modified ck's
c...
               i1 = 1
               do 50 iw=1,nrows
                  cbk = -ddot(ncols,ch(i1),nrows,ck(i1),nrows)/cnorm
                  call daxpy(ncols,cbk,ch(i1),nrows,ck(i1),nrows)
50             i1 = i1 + 1
c.... total exchange contribution     (modified ck's)
               call daxpy(ndims,exch,ck,1,cx,1)
80             continue
c
c---- end of delta = 1 -------------------------------------------------
c rz
c
                   else
c
crz ##  include brillouin states as in standard scdi   ###
c
c ..  single difference
500        h = cr(ihint(ii,jj))
c
c ..  first do the orbitals with differences
      if(jocc(ii).eq.2)h=h+cr(irint(ii,ii,ii,jj))
      if(iocc(jj).eq.2)h=h+cr(irint(ii,jj,jj,jj))
c
c ..  fock type contributions
           do 530 i=1,nint
           iocci=iocc(i)
           if(iocci.eq.0.or.i.eq.ii.or.i.eq.jj) go to 530
           coul=cr(irint(ii,jj,i,i))
           exch=cr(irint(ii,i,jj,i))
           if((iocci-1).gt.0) go to 520
c
c ..  i singly occupied => interesting coupling
               call symb2(i,0)
               call symbtr(cj,ck,ifl,0,0)
           h=h+coul
           if(ifl.eq.0) go to 510
               call daxpy(ndims,exch,ck,1,cx,1)
510            call symbtr(cj,ck,ifl,1,1)
           go to 530
c
c ..  i doubly occupied => add contribution to h
520        h=h+coul+coul-exch
530   continue
c
c ..  now add accumulated h + 2j - k contributions
         call symb1
         call sym1tr(ck,ifl,0,0)
      if(ifl.ne.0) call daxpy(ndims,h,ck,1,cx,1)
c
crz----------end of delta = 1 including brllouin states ---------------
crz
c
                   end if
      go to 400
c
c.... 2 orthogonalities
c
100         call symb2(0,0)
            coul =cr(irint(ii,jj,kk,ll))
            exch =cr(irint(ii,kk,jj,ll))
            call symbtr(cj,ck,ifl,0,0)
            if (ifl.eq.0) go to 400
            call ihj(cx,cj,ck,coul,exch,ndims)
c
c---- end of delta = 2 -------------------------------------------------
c
400         call wrtsb(rmode(1),3)
            call wrtsb(cx,ndims)
c---- end --------------------------------------------------------------
1000     continue
1001  continue
99999 return
      end

      function ihint(ii,jj)
      implicit real*8(a-h,o-z)
INCLUDE(common/sizes)
      common/helpr/isym(nd200),iky(nd200),niky(8),m1e,m2e,m1ia,m2coul,
     *m2exch,m2fock,m2psup,m2qsup,
     *mbase(288),nbase(8),npairi(36),norbi(8),mbasi(8),mnbasi(8)
     *,iap(62),mbfock(62),mbexch(36),mbcoul(36),mbpsup(36),mbqsup(36)
     *,norbas(nd200)
c...
c... to compute index of 1-electron integral
c...
      if(ii.ge.jj)goto 111
      i=jj
      j=ii
      goto 1
111   i=ii
      j=jj
1     ihint=iky(norbas(i))+j+nbase(isym(i))
      return
      end

      subroutine cepvds(diag,z,c,adjd,adjz,conf)
c
c...  adjust diagonal or z vector for davidson
c
      implicit REAL (a-h,o-z)
      dimension diag(*),z(*),c(*)
      logical adjd,adjz
c
_IF(cray,t3e,i8)
      integer conf
_ELSEIF(convex,i8drct)
      integer *8 conf
_ELSE
      REAL conf
_ENDIF
      dimension conf(5,*)
c
INCLUDE(common/ccepa)
INCLUDE(common/symci)
INCLUDE(common/cntrl)
INCLUDE(common/ccntl)
INCLUDE(common/mr_pairs)
c
c...  vacuum shifts
c
      nref1 = nref + 1
      kk = nrfcsf + 1
      if (nref1.gt.nnst) go to 7
      do 5 ic=nref1,nnst
_IF(cray,i8,i8drct)
         lams = conf(3,ic)
_ELSE
         lams = ipad(conf(3,ic))
_ENDIF
         call upack2(conf(5,ic),iisi,iish)
         if (adjd) call vsav(lams,eshifc(iisi,iish),diag(kk),diag(kk))
         if (adjz) call daxpy(lams,eshifc(iisi,iish),c(kk),1,z(kk),1)
5     kk = kk + lams
c
c...   doublets
c
7      if (ndoub.le.0.or.lsinsh.le.0) go to 17
       do 10 ic=nstrt1,nlast1
_IF(cray,i8,t3e,i8drct)
          isi = conf(4,ic)
          nn = norbe(isi)*conf(3,ic)
_ELSE
          isi = ipad(conf(4,ic))
          nn = norbe(isi)*ipad(conf(3,ic))
_ENDIF
          call upack2(conf(5,ic),iisi,iish)
          if (icepa.lt.10) then
             eshifdd = eshifd(iish)
          else
             eshifdd = eshifc(iisi,iish)
          end if
          if (adjd) call vsav(nn,eshifdd,diag(kk),diag(kk))
          if (adjz) call daxpy(nn,eshifdd,c(kk),1,z(kk),1)
10     kk = kk + nn
c
c...  singlets
c
17    kk = nval + ndoub + 1
      if (nstrt2.gt.nlast2) return
      do 20 ic=nstrt2,nlast2
_IF(cary,i8,t3e,i8drct)
         isi = conf(4,ic)
_ELSE
         isi = ipad(conf(4,ic))
_ENDIF
         call upack2(conf(5,ic),iisi,iish)
         call upack2(conf(3,ic),nt,ns)
         nn = ns*norbsi(isi)
            if (nn.eq.0) go to 20
         if (adjd) call vsav(nn,eshifc(iisi,iish),diag(kk),diag(kk))
         if (adjz) call daxpy(nn,eshifc(iisi,iish),c(kk),1,z(kk),1)
20    kk = kk + nn
c
c...  triplets
c
      do 30 ic=nstrt2,nlast2
_IF(cray,i8,i8drct)
         isi = conf(4,ic)
_ELSE
         isi = ipad(conf(4,ic))
_ENDIF
         call upack2(conf(5,ic),iisi,iish)
         call upack2(conf(3,ic),nt,ns)
         nn = nt*norbtr(isi)
            if (nn.eq.0) go to 30
         if (icepa.lt.10) then
            if (adjd) call vsav(nn,eshifc(iish,iisi),diag(kk),diag(kk))
            if (adjz) call daxpy(nn,eshifc(iish,iisi),c(kk),1,z(kk),1)
         else
            if (adjd) call vsav(nn,eshifc(iisi,iish),diag(kk),diag(kk))
            if (adjz) call daxpy(nn,eshifc(iisi,iish),c(kk),1,z(kk),1)
         end if
30    kk = kk + nn
c
      return
      end

      subroutine cepvds_out(diag,z,c,adjd,adjz,conf,oreset,nmi)
c
c...  adjust diagonal or z vector for davidson
c...  only nmi elements of diagonal/z vector complete c vector
c...  oreset=.true. for initialisation, .false. for real work
      implicit REAL (a-h,o-z)
      dimension diag(*),z(*),c(*)
      logical adjd,adjz,oreset
c
_IF(cray,t3e,i8)
      integer conf
_ELSEIF(convex,i8drct)
      integer *8 conf
_ELSE
      REAL conf
_ENDIF
      dimension conf(5,*)
c
INCLUDE(common/ccepa)
INCLUDE(common/symci)
INCLUDE(common/cntrl)
INCLUDE(common/ccntl)
INCLUDE(common/mr_pairs)
      common/cepvds_cntr/icount,icstart,ndone,kk,kkz,otrip,ofirst
      logical otrip,ofirst
c
      if (oreset) then
         icount=0
         icstart=nref + 1
         kk = nrfcsf + 1
         kkz = kk
         ndone=0
         otrip=.false.
         ofirst=.true.
         return
      endif
c
c...  vacuum shifts
c
      nnow=0
      if (ofirst) then
         nnow=nrfcsf
         ofirst=.false.
      endif
      ndifference=0
      ic = icstart
      if (icstart.gt.nnst) go to 7
_IF(cray,i8,i8drct)
5     lams = conf(3,ic)
_ELSE
5     lams = ipad(conf(3,ic))
_ENDIF
      if (icount.ne.0) then
         lams = icount
         icount = 0
      endif
      nnow = nnow+lams
      if (nnow.gt.nmi) then
         ndifference=nnow-nmi
         lams=lams-ndifference
         nnow=nnow-ndifference
      endif
      call upack2(conf(5,ic),iisi,iish)
      if (adjd) call vsav(lams,eshifc(iisi,iish),diag(kkz),diag(kkz))
      if (adjz) call daxpy(lams,eshifc(iisi,iish),c(kk),1,z(kkz),1)
      kk = kk + lams
      kkz = kkz + lams
      ic = ic + 1
      if (nnow.ge.nmi) then
         icstart=ic
         if (ndifference.ne.0) then
            icstart = icstart - 1
            icount = ndifference
         endif
         ndone=ndone+nnow
         kkz=1
         return
      endif
      icstart = ic
      if (ic.gt.nnst) goto 7
      goto 5
c
c...   doublets
c
7     if (ndoub.le.0.or.lsinsh.le.0) go to 17
      if (icstart.lt.nstrt1)call caserr('onverwacht')
      if (icstart.gt.nlast1) goto 17
      ic = icstart
_IF(cray,i8,i8drct)
10    isi = conf(4,ic)
      nn = norbe(isi)*conf(3,ic)
_ELSE
10    isi = ipad(conf(4,ic))
      nn = norbe(isi)*ipad(conf(3,ic))
_ENDIF
      call upack2(conf(5,ic),iisi,iish)
      if (icount.ne.0) then
         nn = icount
         icount = 0
      endif
      nnow = nnow+nn
      if (nnow.gt.nmi) then
         ndifference=nnow-nmi
         nn=nn-ndifference
         nnow=nnow-ndifference
      endif
      if (icepa.lt.10) then
         eshifdd = eshifd(iish)
      else
         eshifdd = eshifc(iisi,iish)
      end if
      if (adjd) call vsav(nn,eshifdd,diag(kkz),diag(kkz))
      if (adjz) call daxpy(nn,eshifdd,c(kk),1,z(kkz),1)
      kk = kk + nn
      kkz = kkz + nn
      ic = ic + 1
      if (nnow.ge.nmi) then
         icstart=ic
         if (ndifference.ne.0) then
            icstart = icstart - 1
            icount = ndifference
         endif
         ndone=ndone+nnow
         kkz=1
         return
      endif
      icstart = ic
      if (ic.gt.nlast1) goto 17
      goto 10
c
c...  singlets and triplets
c
c 17    kk = nval + ndoub + 1
17    if (nstrt2.gt.nlast2) return
      ic = icstart
      if (ic.gt.nlast2) goto 40
_IF(cray,i8,i8drct)
20    isi = conf(4,ic)
_ELSE
20    isi = ipad(conf(4,ic))
_ENDIF
      call upack2(conf(5,ic),iisi,iish)
      call upack2(conf(3,ic),nt,ns)
      nns = ns*norbsi(isi)
      nnt = nt*norbtr(isi)
      if (otrip) goto 19
      if (icount.ne.0) then
         nns = icount
         icount = 0
      endif
      nnow = nnow+nns
      if (nnow.gt.nmi) then
         ndifference=nnow-nmi
         nns=nns-ndifference
         nnow=nnow-ndifference
      endif
      if (nns.eq.0) go to 18
      if (adjd) call vsav(nns,eshifc(iisi,iish),diag(kkz),diag(kkz))
      if (adjz) call daxpy(nns,eshifc(iisi,iish),c(kk),1,z(kkz),1)
18    kk = kk + nns
      kkz = kkz + nns
      if (nnow.ge.nmi) then
         icstart=ic
         if (ndifference.ne.0) then
            icount = ndifference
         endif
         ndone=ndone+nnow
         kkz=1
         if (nnt.gt.0.and.icount.eq.0) otrip=.true.
         if (nnt.eq.0.and.icount.eq.0) icstart=icstart+1
         return
      endif
c start triplet part
19    if (icount.ne.0) then
         nnt=icount
         icount=0
      endif
      otrip=.false.
      nnow = nnow+nnt
      if (nnow.gt.nmi) then
         ndifference=nnow-nmi
         nnt=nnt-ndifference
         nnow=nnow-ndifference
      endif
      if (nnt.eq.0) goto 38
      if (icepa.lt.10) then
         if (adjd) call vsav(nnt,eshifc(iish,iisi),diag(kkz),diag(kkz))
         if (adjz) call daxpy(nnt,eshifc(iish,iisi),c(kk),1,z(kkz),1)
      else
         if (adjd) call vsav(nnt,eshifc(iisi,iish),diag(kkz),diag(kkz))
         if (adjz) call daxpy(nnt,eshifc(iisi,iish),c(kk),1,z(kkz),1)
      end if
38    kk = kk + nnt
      kkz = kkz + nnt
      ic = ic + 1
      if (nnow.ge.nmi) then
         icstart=ic
         if (ndifference.ne.0) then
            icstart = icstart - 1
            icount = ndifference
            otrip=.true.
         endif
         ndone=ndone+nnow
         kkz=1
         if (ic.gt.nlast2.and.icount.eq.0) goto 40
         return
      endif
      icstart = ic
      if (ic.gt.nlast2) goto 40
      goto 20
      ndone=ndone+nnow
40    if (ndone.ne.ntotal) then
        call caserr('cepvds error')
      endif
c
      return
      end

      subroutine vsav(n,scalar,r,b)
c...     205 : r = scalar + b
      implicit double precision (a-h,o-z), integer (i-n)
      dimension r(n),b(n)
c
       do 10 i=1,n
10     r(i) = scalar + b(i)
c
      return
      end

      double precision function absmax(n,test,c)
c...    205 : absmax = absolute max of tester and c(n)
      implicit double precision (a-h,o-z), integer (i-n)
      dimension c(n)
c
      tt = test
      do 10 i=1,n
10    if (dabs(c(i)).gt.tt) tt = dabs(c(i))
c
      absmax = tt
c
      return
      end
      function minimum(n,c)
c...     205 : minimum yields pos, of smallest element (starting at 0)
      implicit double precision (a-h,o-z), integer (i-n)
      dimension c(n)
c
      ii = 1
      do 10 i=2,n
        if (c(i).lt.c(ii)) ii = i
10    continue
      minimum = ii - 1
c
      return
      end

      subroutine scaler(n,scalar,r,b)
c...   ***note***  more general then dscal
      implicit double precision (a-h,o-z), integer (i-n)
      dimension r(n),b(n)
c
      do 1 i=1,n
 1    r(i)=scalar*b(i)
c
      return
      end

      subroutine shorto(action,text,real,array,n)
c
c...  general routine to provide a short output
c...  usually input is echoed to this file
c...  not so if noecho is supplied on short directive
c   
      implicit real*8 (a-h,p-z), integer (i-n), logical (o)
      character*(*) action,text
      dimension array(*)
      character*60 fname
      character*8 zdate,ztime,zaccno,zanam,zecho
      logical oshort,echo
      save oshort,iunit,echo
      data oshort/.false./,iunit/61/,echo/.true./
      call caserr('shorto gone')
c
      return
      end
      subroutine gtriad_weg(n,scalar,r,a,b)
c..    r = a + scalar*b
      implicit double precision (a-h,o-z), integer (i-n)
c
      dimension a(*),r(*),b(*)
      do 1 i=1,n
 1    r(i)=a(i)+scalar*b(i)
      return
c
      end

      subroutine cepadvv(diag,z,c,conf)
c
c...  adjust diagonal + z vector for vacuum   (vvc2)
c
      implicit REAL (a-h,o-z)
      dimension diag(*),z(*),c(*),conf(5,*)
_IF(cray,t3e,i8)
      integer conf
_ELSEIF(convex,i8drct)
      integer *8 conf
_ELSE
      REAL conf
_ENDIF
c
INCLUDE(common/ccntl)
INCLUDE(common/ccepa)
INCLUDE(common/cdcryz)
c
INCLUDE(common/mr_pairs)
c
chvd  ref.states should not be shifted.
      kk = nrfcsf+1
      do 10 loop = nref+1,nnst
         call upack2(conf(5,loop),iisi,iish)
_IF(cray,i8,i8drct)
         nn = conf(3,loop)
_ELSE
         nn = ipad(conf(3,loop))
_ENDIF
         call vsav(nn,eshifc(iisi,iish),diag(kk),diag(kk))
         call daxpy(nn,eshifc(iisi,iish),c(kk),1,z(kk),1)
10    kk = kk + nn
c
      return
      end

      subroutine cepadst(diag,z,c,ist,num,conf)
c
c...  adjust diagonal + z vector for n-2 (ssc2)
c     *** ist = 0 : singlets / ist = 1 : triplets
c
      implicit REAL (a-h,o-z)
      dimension diag(*),z(*),c(*),conf(5,*)
_IF(cray,t3e,i8)
      integer conf
_ELSEIF(convex,i8drct)
      integer *8 conf
_ELSE
      REAL conf
_ENDIF
c
INCLUDE(common/mr_pairs)
INCLUDE(common/ccntl)
      common /moco/ isi,ic
c
      call upack2(conf(5,ic),iisi,iish)
      eshif = eshifc(iisi,iish)
      if (ist.gt.0) eshif = eshifc(iish,iisi)
      call vsav(num,eshif,diag,diag)
      call daxpy(num,eshif,c,1,z,1)
c
      return
      end

      subroutine getsbcz(q,nword)
      implicit REAL  (a-h,o-z),integer  (i-n)
      dimension q(*)
      common/disksa/bof(511),no,iblo,inbuf
INCLUDE(common/disktl)
_IF(linux)
      external fget
_ENDIF
      k=nword
      j=1
      if(no)30,20,30
30    nn=min(k,inbuf-no)
      call fmove(bof(no+1),q(j),nn)
      k=k-nn
      j=j+nn
      no=no+nn
      if(no.eq.inbuf)no=0
20    if(iposun(numci).ne.iblo)call search(iblo,numci)
       k511=k-511
      if(k511)10,40,40
40    call fget(q(j),m,numci)
      inbuf=m
      iblo=iblo+1
c     k=k511
c     j=j+511
      k=k-m
      j=j+m
      goto 20
10    if(k)50,999,50
50    call fget(bof,m,numci)
      inbuf=m
      iblo=iblo+1
      call fmove(bof,q(j),k)
      no=k
      if (no.eq.inbuf)no=0
      if (m.lt.k) then
         j=j+m
         k=k-m
         goto 20
      endif
999   return
      end
      subroutine getsccz(q,nword)
      implicit REAL  (a-h,o-z),integer (i-n)
      dimension q(*)
INCLUDE(common/disktl)
      common/bufb /bof(511),no,iblo,inbuf
_IF(linux)
      external fget
_ENDIF
      k=nword
      j=1
      if(no)30,20,30
30    nn=min(k,inbuf-no)
      call fmove(bof(no+1),q(j),nn)
      k=k-nn
      j=j+nn
      no=no+nn
      if(no.eq.inbuf)no=0
20    if(iposun(numci).ne.iblo)call search(iblo,numci)
      k511=k-511
      if(k511)10,40,40
40    call fget(q(j),m,numci)
      inbuf=m
      iblo=iblo+1
      k=k-m
      j=j+m
      goto 20
10    if(k)50,999,50
50    call fget(bof,m,numci)
      inbuf=m
      iblo=iblo+1
      call fmove(bof,q(j),k)
      no=k
      if (no.eq.inbuf) no=0
      if (m.lt.k) then
         j=j+m
         k=k-m
         goto 20
      endif
999   return
      end
_IFN(vb)
      subroutine cinput(ifield,nfield,incr)
c
c...  inquire (and change) jrec/jump from work
c...  isolates character IO more
c...  note jrec = field last read
c...  if (incr=100) jrec is set to 0
c
INCLUDE(common/work)
c
      jrec = jrec + incr
      if (incr.eq.100) jrec = 0
      ifield = jrec
      nfield = jump
c
      return
      end
_ENDIF
      subroutine ver_dirctd(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/dirctd.m,v $
     +     "/
      data revision /"$Revision: 5774 $"/
      data date /"$Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end

