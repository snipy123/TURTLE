      subroutine cinput(ifield,nfield,incr)
c
c...  inquire (and change) jrec/jump from work
c...  isolates character IO more
c...  note jrec = field last read
c...  if (incr=100) jrec is set to 0
c
INCLUDE(../m4/common/work)
c
      jrec = jrec + incr
      if (incr.eq.100) jrec = 0
      ifield = jrec
      nfield = jump
c
      return
      end
      integer function nipw()
c....
c.... this function returns the number of integers per 8 byte word
c.... alternatively nipw may be a parameter in routine
c.... or nav is used directly
c....
      integer lenwrd
c
      nipw = lenwrd()
c
      return
      end
      integer function nwpi(nint)
c....
c.... this function returns the number of 8 byte words for a number of integers
c....
      integer nint,lenwrd
c
      nwpi = (nint-1)/lenwrd() + 1
c
      return
      end
c********************************************************************
c******************************************************************** 
c******************** BLAS    CALLS *********************************
c***************        pp/jvl 1989       ***************************
c***************        CB/JvL 1993       ***************************
c********************************************************************
c********************************************************************
c   
c     contains apollo decks: blas,matrix_mult,c205_atmol
c
_IFN(cray)
      subroutine gather(n,r,a,map)
c
      implicit REAL (a-h,o-z), integer (i-n)
      dimension r(n),a(*),map(n)
c
      do 10 loop=1,n
   10 r(loop) = a(map(loop))
c
      return
      end
      subroutine gatherx(n,r,supg,map)
c
      implicit REAL (a-h,o-z), integer (i-n)
      dimension r(n),supg(*),map(n)
c
!$acc parallel loop present (supg) copyin(map) copyout (r)
      do 10 loop=1,n
   10 r(loop) = supg(map(loop))
!$acc end loop
c
      return
      end

      subroutine scatter(n,r,index,a)
c
c...  cray scilib imitation/ but not as in my manual (jvl 1986)
c...  arguments as in cyber205 atmol-library
c
      implicit REAL (a-h,o-z), integer (i-n)
      dimension r(*),index(n),a(n)
c
cc!$acc parallel loop copyin (a,index,n) copyout (r) independent
      do 10 i=1,n
10    r(index(i)) = a(i)
cc!$acc end loop
c
      return
      end
_ENDIF
      subroutine subvec(r,a,b,n)
c
      implicit double precision (a-h,o-z), integer (i-n)
      dimension r(*),a(*),b(*)
c
c...  r = a - b
c
      do 10 i=1,n
         r(i)=a(i)-b(i)
10    continue
c
      return
      end
      subroutine zero(v,n)
c
c...  zero vector
c
      implicit double precision (a-h,o-z), integer(i-n)
      dimension v(*)
c
      do 10 i=1,n
         v(i)=0.0d0
10    continue
c
      return
      end
      subroutine tmoden(vector,d,gam1,nprint)
c
c.....transforms mo 1-particle density matrix to ao basis
c
      implicit REAL (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension vector(ma,*),d(*),gam1(*)
c
INCLUDE(../m4/common/sizes)
c
INCLUDE(../m4/common/qice)
INCLUDE(../m4/common/cndx40)
c
      common/qpar  /ma,n2e,ntype,ncore,nact,nprim,nsec,nprimp,
     1            naa,nab,nst,n1e,isym,mults,macro,maxc
INCLUDE(../m4/common/gjs)
INCLUDE(../m4/common/mapper)
INCLUDE(../m4/common/dm)
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/dump3)
c
      data half/0.5d0/
      data m991/991/
c
      lenb4=ma*(ma+1)/2
      call vclr(d,1,lenb4)
c
      do 20 it=1,nprim
      do 20 iu=1,it
      if(isymmo(iu).ne.isymmo(it)) go to 20
      if(iu.le.ncore.and.it.ne.iu)goto20
      m1=ic1e(it,1)+ic1e(iu,2)
      dum=gam1(m1)*half
      if(it.le.ncore)dum=1.0d0
      do 10 k=1,ma
      kl1=iky(k)
      do 10 l=1,k
      kl1=kl1+1
10    d(kl1)=d(kl1)+dum*(vector(k,it)*vector(l,iu)+
     1vector(k,iu)*vector(l,it))
c
20    continue
c
      call secput(isecla,m991,lensec(lenb4),iblk)
      call wrt3(d,lenb4,iblk,ndump4)
      call revind
      if(nprint.ne.-5)write(iwr,30)isecla
30    format(/' symmetric lagrangian matrix (ao basis) dumped to'
     1,' to section ',i3)
c
c     call tripri(d,ma)
      return
      end
_IF()
      subroutine printldd(rlg,d1,d2,sh,ss,sg,rlx,g1,
     &                    g2,shx,sgx,nelec,nmo,nbasis)
c
      implicit REAL (a-h,p-z) , integer*4 (i-n),logical (o)
c
      common /ncofac3/nul0,nul1,nul2,nul3,nul4,ndim3
c
INCLUDE(../m4/common/iofile)
      dimension rlg(*),d1(*),d2(*),sh(*),ss(*),sg(*)
      dimension rlx(*),g1(*),g2(*),shx(*),sgx(*)
c
      ind(i,j) = max(i,j)*(max(i,j)-1)/2+min(i,j)

      write(iwr,*)'lagrangian'
      call tripri(rlg,nmo)
      write(iwr,*)'1-electron density matrix'
      call tripri(d1,nmo)
      write(iwr,*)'h-matrix'
      call tripri(sh,nmo)
      write(iwr,*)'s-matrix'
      call tripri(ss,nmo)
c     write(iwr,*)'2-electron density matrix'
c     call tripri(d2,nmo*(nmo+1)/2)
c     write(iwr,*)'2-electron integrals'
c     call tripri(sg,nmo*(nmo+1)/2) 
      eleone = 0.0d0
      elagr  = 0.0d0
      snorm  = 0.0d0
      eletwo = 0.0d0
      do i=1,nmo
        do j=1,i
          ij = ind(i,j)
          eleone = eleone + d1(ind(i,j))*sh(ind(i,j))
          elagr  = elagr  + rlg(ind(i,j))*sh(ind(i,j))
          snorm  = snorm  + d1(ind(i,j))*ss(ind(i,j))
          if (i.ne.j) then
            eleone = eleone + d1(ind(i,j))*sh(ind(i,j))
            snorm  = snorm  + d1(ind(i,j))*ss(ind(i,j))
          end if
          do k=1,i
            do l=1,k
              kl = ind(k,l)
              fac = 1.0d0
              if (i.ne.j) fac=fac*2
              if (k.ne.l) fac=fac*2
              if (ij.ne.kl) fac=fac*2
              if (kl.gt.ij) cycle 
              ijkl = ind(ij,kl)
              eletwo = eletwo + d2(ijkl)*sg(ijkl)
            end do
          end do
        end do
      end do  
c
      eelec = eleone + eletwo
      write(iwr,*)'results mo basis'
      write(iwr,*)'one-electron energy:',eleone
      write(iwr,*)'two-electron energy:',eletwo
      write(iwr,*)'normalisation      :',snorm/nelec
      write(iwr,*)'electronic energy  :',eelec
      write(iwr,*)'lagrange energy    :',elagr
c
c     return
      call get1e(shx,core,'h',sgx)
c   
      write(iwr,*)'total energy       :',eelec + core
      print *
      write(iwr,*)'lagrangian ao basis'
      call tripri(rlx,nbasis)
      write(iwr,*)'1-electron density matrix ao basis'
      call tripri(g1,nbasis)
 
      write(iwr,*)'ao h-matrix'
      call tripri(shx,nbasis)
      eleone = 0.0d0
      elagr  = 0.0d0
      do 81 i=1,nbasis
        do 82 j=1,i
           ip = i*(i-1)/2+j
           eleone=eleone+shx(ip)*g1(ip)
           elagr  = elagr + shx(ip)*rlx(ip)
           if (i.ne.j) then
              eleone=eleone+shx(ip)*g1(ip)
              elagr  = elagr + shx(ip)*rlx(ip)
           end if
82       continue
81    continue
      call get1e(shx,flop,'s',shx)
      write(iwr,*)'ao s-matrix'
      call tripri(shx,nbasis)
      snorm = 0.0d0
      do i=1,nbasis
        do j=1,i
           ip = i*(i-1)/2+j
           snorm = snorm + shx(ip)*g1(ip)
           if (i.ne.j) then
              snorm=snorm + shx(ip)*g1(ip)
           end if
         end do
      end do
      call getp2(g2)
c     write(iwr,*)'two-electron density matrix in ao basis' 
c     call tripri(g2,nbasis*(nbasis+1)/2)
      call gete2(sgx)
c     call tripri(sgx,nbasis*(nbasis+1)/2)
      eletwo=0.0d0
c      do i=1,nbasis
c        do j=1,nbasis
c          ij = ind(i,j)
c          do k=1,nbasis
c            do l=1,nbasis
c              kl = ind(k,l)
c              ijkl = ind(ij,kl)
c              eletwo=eletwo+sgx(ijkl)*g2(ijkl)
c78          end do
c           end do
c         end do
c       end do
       do i=1,nbasis
         do j=1,i
           ij = ind(i,j)
           do k=1,i
             do l=1,k
               kl = ind(k,l)
               if (kl.gt.ij) cycle 
               fac = 1.0d0
               if (i.ne.j) fac=fac*2
               if (k.ne.l) fac=fac*2
               if (ij.ne.kl) fac=fac*2
               ijkl = ind(ij,kl) 
              eletwo=eletwo+sgx(ijkl)*g2(ijkl)*fac
c             if (dabs(sgx(ijkl)*g2(ijkl)).gt.1.0d-8) then
c               write(iwr,*)sgx(ijkl),g2(ijkl),fac,eletwo
c             end if
            end do
          end do
        end do
      end do
      eelec = eleone + eletwo
      write(iwr,*)'results ao basis'
      write(iwr,*)'one-electron energy:',eleone
      write(iwr,*)'two-electron energy:',eletwo
      write(iwr,*)'normalisation      :',snorm/nelec
      write(iwr,*)'electronic energy  :',eelec
      write(iwr,*)'lagrange energy    :',elagr
      write(iwr,*)'total energy       :',eelec + core
c 
      write(iwr,*)'overview of nullities encountered'
      write(iwr,*)'nullity  0',nul0
      write(iwr,*)'nullity  1',nul1
      write(iwr,*)'nullity  2',nul2
      write(iwr,*)'nullity  3',nul3
      write(iwr,*)'nullity >3',nul4 
      write(iwr,*)'dimens.  3',ndim3
c
      return
      end
_ENDIF
      subroutine tp1out(d,gam1,iwr,nprint)
      implicit REAL (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(../m4/common/sizes)
c
INCLUDE(../m4/common/cndx40)
c
      common/gjs   /nirr,mult(8,8),isymao(maxorb),itype(maxorb)
c
INCLUDE(../m4/common/mapper)
c
      common/qpar  /ma,n2e,ntype,ncore,nact,nprim,nsec,nprimp,naa,nab,
     1            nst,n1e,isym,mults,macro,maxc
c
INCLUDE(../m4/common/qice)
INCLUDE(../m4/common/dm)
c
      dimension d(*),gam1(*)
      data m400/400/
c
c      output one-particle density matrix of casscf wavefunction
c      to atmol dumpfile
c
c
      lenb4=iky(nbas4+1)
      callsecput(isecdm,m400,lensec(lenb4),iblk)
      call vclr(d,1,lenb4)
      ind=0
      do 10 i=1,nprim
      do 10 j=1,i
      ind=ind+1
      if(itype(j).ne.itype(i))goto10
      in1=ic1e(i,1)+ic1e(j,2)
      d(ind)=gam1(in1)
      if(i.eq.j.and.i.le.ncore)d(ind)=2.0d0
10    continue
      call wrt3(d,lenb4,iblk,ndump4)
      if(nprint.ne.-5)write(iwr,20)isecdm
20    format(/' one particle density matrix (mo basis) dumped to section
     1',i4,' of dumpfile')
      return
c
      end
      subroutine tp2out(gam1,gam2,iwr)
c
c      output two-particle density matrix of casscf wavefunction
c      to mainfile (the one given by the mofile directive
c
      implicit REAL (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(../m4/common/sizes)
      common/disc  /isel(5),name(maxlfn)
creal      common/craypk/ij205(680)
      common/craypk/ij205(1360)
      common/blkin /gout(340),gijout(170),mword
c
INCLUDE(../m4/common/qice)
INCLUDE(../m4/common/gjs)
INCLUDE(../m4/common/mapper)
INCLUDE(../m4/common/files)
INCLUDE(../m4/common/restar)
INCLUDE(../m4/common/machin)
c
      common/qpar/ma,n2e,ntype,ncore,nact,nprim,nsec,nprimp,naa,nab,
     1            nst,n1e,isym,mults,macro,maxc
c
      dimension gam2(*),gam1(*)
      data m0,two/0,2.0d0/
c
      mfilep=1
      mainp=n6tape(1)
      iblkmp=n6blk(1)
      mblp=iblkmp-n6last(1)
c
      mword=0
      ind = 0
c
      call dpconv(nprim,gam1,gam2)
c
      int4=1
c
c.....all active density matrix..
c
60    do 70 i=nst,nprim
      do 70 j=nst,i
      do 70 k=nst,i
      last=k
      if(k.eq.i)last=j
      do 70 l=nst,last
      mword=mword+1
      ind = ind + 1
      gout(mword)=gam2(ind)
      ij205(int4  )=i4096(i)+j
      ij205(int4+1)=i4096(k)+l
      int4=int4+2
      if(mword.lt.340)goto 70
      call block2
      int4=1
70    continue
      if(mword.eq.0)go to 80
      call block2
80    call put(gout,m0,mainp)
      m6file=mfilep
      m6tape(m6file)=n6tape(mfilep)
      m6blk (m6file)=n6blk(mfilep)
      m6last(m6file)=iblkmp+1
      call gconv(nprim,gam1,gam2)
      call revise
      call clredx
      if(nprint.ne.-5)write(iwr,10)
 10   format(//
     *' status of 2-particle mo-density file'/1x,36('-')/)
      if(nprint.ne.-5)
     * call filprn(m6file,m6blk,m6last,m6tape)
      return
c
      end
      subroutine tdpconv(nprim,ma,rlag,gam1,gam2)
      implicit REAL (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/qice)
c
      common/convb /odoubl
      common/qpar  /m8,n2e,ntype,ncore,nact
c
INCLUDE(../m4/common/mapper)
c
      common/gjs   /nirr,mult(8,8),isymao(maxorb),itype(maxorb)
c
c.....routine converts density matrices gamma to d,p
c
      dimension rlag(*),gam1(*),gam2(*)
      if(.not.odoubl)return
      odoubl=.false.
      dumy=0.5d0
      go to 10
      entry tgconv(nprim,ma,rlag,gam1,gam2)
c
c.....converts d,p to gammas
c
      if(odoubl)return
      odoubl=.true.
      dumy=2.0d0
10    continue
      do 30 i=1,nact
      do 30 j=1,i
      ij=iky(i)+j
      do 30 k=1,i
      l1=k
      if(k.eq.i)l1=j
      do 20 l=1,l1
      kl=iky(k)+l
      if(ic4e(kl).ne.ic4e(ij))go to 20
      n=ic2e(ij)+ic3e(kl)
      dumx=1.0d0
      if(i.ne.j)dumx=dumy
      if(k.ne.l)dumx=dumx*dumy
      if(i.ne.k.or.j.ne.l)dumx=dumx*dumy
      gam2(n)=gam2(n)*dumx
20    continue
30    continue
c
      do 40 i=2,nprim
      im=i-1
      do 40 j=1,im
      if(itype(i).ne.itype(j))go to 40
      m=ic1e(i,1)+ic1e(j,2)
      rlag(m)=rlag(m)*dumy
      gam1(m)=gam1(m)*dumy
40    continue
      return
      end
      subroutine fillqpar(nmo,ncor,nbasis)
c
      implicit REAL (a-h,o-z) , integer   (i-n)
c
      common/qpar  /ma,n2e,ntype,ncore,nact,nprim,nsec,nprimp,naa,nab,
     1            nst,n1e,isym,mults,macro
c
      ma   = max(nbasis,nmo+ncor)
      ncore=ncor
      nact =nmo
      nprim=ncore+nact
      nst = 1
      ntype = 1
      call first
      return
      end
      subroutine tranvbini
c    
c...   called from vbin to get vector section right
c
      implicit REAL (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/scra7)
INCLUDE(../m4/common/statis)
c
      common/craypk/kbcray(1360)
INCLUDE(../m4/common/blksiz)
c
INCLUDE(../m4/common/infoa)
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/dump3)
c
INCLUDE(../m4/common/prnprn)
INCLUDE(../m4/common/restar)
c
      common/restri/nfils(63),lda(508),isect(508),ldx(508)
      common/junke/maxt,ires,ipass,nteff,npass1,npass2,lentri,
     *nbuck,mloww,mhi,ntri,iacc
c
INCLUDE(../m4/common/cndx40)
INCLUDE(../m4/common/runlab)
INCLUDE(../m4/common/tran)
INCLUDE(../m4/common/files)
INCLUDE(../m4/common/gjs)
INCLUDE(../m4/common/discc)
INCLUDE(../m4/common/trntim)
INCLUDE(../m4/common/atmol3)
INCLUDE(../m4/common/machin)
c
      common/block /length,nsymm(8),nblock(8,maxorb)
c
      dimension ztit(10)
      data zcas/'mcscf'/
      data ztit/' *** no ','real vec','tors ***',7*'        '/
c
      nav = lenwrd()
      nmaxim=maxorb-1
      iscftp=0
      iacc=iacc4
c
      do 87654 i=1,7
      oprin4(i)=.true.
      if(nprint.eq.3)oprin4(i)=.false.
87654 continue
      oprin4(8)=.true.
      oprin4(9)=.true.
c
cjvl
c  vectors section
        m3 = 3
        l3 = num*num
        len1=lensec(mach(8))
        lenv=lensec(l3)
        len2=lensec(mach(9))
        j=len2+lenv+len1+1
        call secput(mouta,m3,j,iblk)
        call putq(ztit,ztit,value,pop,0,0,0,0,0,q,mouta,ib)
        ibl3qa=iblk+len2+len1+1
cjvl      iblkq4=ibl7la
      iblkq4=ibl3qa
      nbas4=num
      ndump4=idaf
      newb4=num
      if(nbas4.le.1.or.nbas4.gt.nmaxim)call caserr(
     *'error in vb-4-index preprocessor')
      nbb4=nbas4
      nm=nmaxim+1
      m12=12/nav
      m1file=n2file
      do 5009 i=1,n2file
         m1tape(i)=n2tape(i)
         m1blk (i)=n2blk(i)
         m1last(i)=n2last(i)
5009  continue
c
      iacc=iacc4
c
      ncol4=num
c...   this is too much ; might need changing
      nsa4=num
cjvl      newb4=num
cjvl      nbas4=num
cjvl      ndump4=idaf
      nblkq4=nbas4*ncol4
c
c secondary mainfile
c
      junits=n4tape(1)
      jblkas=n4blk(1)
      jblkrs=jblkas-n4last(1)
c
c     final mainfile
c
      junitf=n1tape(1)
      jblkaf=n1blk(1)
      jblkrf=jblkaf-n1last(1)
c
      nsa4=nbas4
      ictr=0
      ion=1
      nfiles=1
      nfilef=1
      indxi=1
      indxj=1
      irr=1
      iss=1
      master=0
      junits=n4tape(1)
      jblkas=n4blk(1)
      jblkrs=jblkas-n4last(1)
      junitf=n6tape(1)
      jblkaf=n6blk(1)
      jblkrf=jblkaf-n6last(1)
      m500 = 500
      call secput(isect(484),m500,1,isecbl)
cjvl      ionst = ionsec
      call stractlt(ionsec,0)
c
c symmetry information
c NOSYMM!
c
      nirr=1
      nsymm(1)=0
      do 100 j=1,nbas4
      isymmo(j)=1
      ibsym=isymmo(j)
      nsymm(ibsym)=nsymm(ibsym)+1
100   nblock(ibsym,nsymm(ibsym))=j
      mstart(1)=1
      nfin(1)=nbas4
      do 110 i=1,maxorb
110   isymao(i)=1
      return
      end
      subroutine stractlt(ions,nb)
c
c...  transfer data to tractlt
c
      integer ions
INCLUDE(common/tractlt)
      if (ions.ne.0) ionsec = ions
      if (nb.ne.0)  nbasis = nb
      return
      end
      subroutine inipi4(lword,nact)
c
      implicit REAL (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/cndx40)
INCLUDE(../m4/common/gjs)
c
      lword4=lword
      nmc = nact
c      
      return
      end 
      subroutine getqvb(q,nbas,ncoll,jsec,tag)
c
c...  getq routine for VB
c...  does tdown for 'normal' vector-sets  to get unadapted
c...  is compatible with putqvb (vector-dimensions may vary)
c...  vb-vector sets are recognised from vb creator, assumed unadapted
c

      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(../m4/common/sizes)
c
      dimension q(*)
      character*(*) tag
c
INCLUDE(../m4/common/iofile)
INCLUDE(../m4/common/scfopt)
c
INCLUDE(../m4/common/sector)
      common/junkc/zcom(19),ztit(10)
INCLUDE(../m4/common/blkorbs)
INCLUDE(../m4/common/tran)
INCLUDE(../m4/common/infoa)
INCLUDE(../m4/common/discc)
INCLUDE(../m4/common/machin)
INCLUDE(../m4/common/restar)
c
      if(tag.eq.'print') write(iwr,100) 'vb-',jsec,iblkdu,yed(numdu)
100   format(/a7,'vectors restored from section',i4,
     *' of dumpfile starting at block',i6,' of ',a4)
c...
c... check number and section type; latter should be 3 or 33
c...
      if(jsec.gt.508)call caserr(
     *'invalid section specified for vector input')
      itype = 0
      call secget(jsec,itype,k)
      if ((itype.ne.3).and.(itype.ne.33)) call caserr(
     &       'getqvb: retrieved dumpfile section of wrong type')
c
      call rdchr(zcom(1),29,k,numdu)
      call reads(deig,mach(8),numdu)
      k=k+1+lensec(mach(8))
      if(tag.eq.'print')write(iwr,200)(zcom(7-i),i=1,6),ztit
200   format(/' header block information :'/
     *' vectors created under acct. ',a8/1x,
     *a7,'vectors created by ',a8,'  program at ',
     *a8,' on ',a8,' in the job ',a8/
     *' with the title: ',10a8)
c
c...   ncol and new seem both the # vectors 
c...   nbas is # basis-functions
c...   for VB no restrictyions apply
c
      nbas=nba
      ncoll = ncol
      newb=new
c       => scfopt
      etot=etott
c
      otran=.true.
      if (zcom(5)(1:2).ne.'vb') then
c...   do a otrans check for non-vb vectors
        call readi(ilifc,mach(9)*lenwrd(),k,numdu)
      end if
c
      if (itype.eq.33) then
         nw=nbas*ncol
      else
         nw=nbas*nbas
      end if
c
      k=k+lensec(mach(9))
      call rdedx(q,nw,k,numdu)
c
c...  go to nonadapted basis if need be
c
      if (.not.otran) then
         call tdown2(q,nbas,newb,ilifc,ntran,itran,ctran,otran)
      end if
      otran = .true.
c
      return
      end
      subroutine putqnatorb(v,eval,occ,nbasis,ncol,isec)
c
      implicit REAL (a-h,o-z) , integer   (i-n)
c
      dimension v(*),occ(*),eval(*)
c
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/runlab)
c
      character*8 zsafe 
      zsafe = zcom(5)
      zcom(5) = 'natvb'
c
      call putq(zcom,ztitle,eval,occ,nbasis,ncol,ncol,0,0,v,isec,iblkq)
c
      zcom(5) = zsafe
      return
      end

      subroutine putqvb(q,norb,ncolu)
c
c...  Vector outputting routine(+ header blocks) for Valence Bond
c...       - no ctrans block is written (adapt off is assumed)
c...       - no eigenvalues/occupations are written (could be though)
c...       - ncolu and norbn may be <> nbasis
c
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension q(*)
c
INCLUDE(../m4/common/sizes)
INCLUDE(../m4/common/sector)
      common/blkorbs/value(maxorb),pop(maxorb),escf,
     *             nbasis,newbas,ncol,ivalue,ipop
INCLUDE(../m4/common/machin)
INCLUDE(../m4/common/scfopt)
INCLUDE(../m4/common/tran)
INCLUDE(../m4/common/runlab)
INCLUDE(common/scftvb)
c
      zcom(5) = 'vb'
c
c...    no eigenvalues or occupations 
c
      call putq(zcom,ztitle,value,pop,norb,ncolu,ncolu,0,0,q,isecv,ib)
c
      return
      end

      function ddotx(n,a,ia,b,ib)
      implicit REAL (a-h,o-z)
      dimension a(n),b(n)
      dtemp=0.0d0
      if ((ia.ne.1).or.(ib.ne.1))stop 'ddotx error'
!$acc parallel loop reduction (+:dtemp) copyin(a(1:n),b(1:n))
      do i=1,n
         dtemp=dtemp+a(i)*b(i)
      enddo
!$acc end loop
      ddotx=dtemp
      return
      end
