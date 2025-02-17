c 
c  $Author: wab $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/inpci.m,v $
c  $State: Exp $
c  
c ******************************************************
c ******************************************************
c             =   inpci   =
c ******************************************************
c ******************************************************
      subroutine cget(c,nv)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/multic)
      dimension c(*)
      ii=1
      nvec=nv
      if(nv.lt.0) nvec=1
      if(nv.ge.-1) call search(iblkc,num3)
      do 40 i=1,nvec
      call reads(c(ii),nci,num3)
40    ii=ii+nci
      return
      end
      subroutine ciin(core,odci)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/files)
INCLUDE(common/disktl)
INCLUDE(common/fpinfo)
      dimension core(*)
      common/ccntl/nref
      data oyes/.true./
c
c     allocate all available memory
c
      ibase = igmem_alloc_all(lword)
c
      mblkci=n5blk(1)
      numci=n5tape(1)
      nxblk=mblkci
      call cizero(oyes,lword,ocifp)
      call cidata(core(ibase),odci)
      if(nref.ne.0) then
        nw=nref*5
_IF(i8drct)
        call wrt3i8(core(ibase),nw,nxblk,numci)
_ELSE
        call wrt3(core(ibase),nw,nxblk,numci)
_ENDIF
      endif
c
c     reset core allocation
c
      call gmem_free(ibase)
c
      return
      end
      subroutine headup
      implicit REAL  (a-h,o-z), integer (i-n)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
      common/bufb/kstart(7,mxshel),nshell,nuc,norb,ispace
INCLUDE(common/machin)
INCLUDE(common/iofile)
INCLUDE(common/runlab)
      common/restri/nfils(63),lds(508),isect(508),ldsect(508)
      data m1/1/
      call secget(isect(491),m1,iblkv)
      iblkv=iblkv+lensec(mxprim)
     *           +lensec(mxprim*5+maxat)
      m110=10+maxat
      call rdchr(ztitle,m110,iblkv,idaf)
      nav = lenwrd()
      call readis(kstart,mach(2)*nav,idaf)
      if(norb.le.0.or.norb.gt.maxorb.
     * or. nuc.le.0.or.nuc.gt.maxat)  call caserr2(
     *'invalid number of basis functions and/or nucleii')
      nat=nuc
      num=norb
      nx=num*(num+1)/2
      return
      end
      function ibynom(n,kk)
      implicit REAL (a-h,o-z), integer(i-n)
      k=kk
      if(k.lt.0.or.k.gt.n) then
       ibynom=0
       return
      endif
      if(k.eq.0.or.k.eq.n) then
       ibynom=1
       return
      endif
      if(k.gt.n/2) k=n-k
      ib=1
      do 10 i=n-k+1,n
      ib=ib*i
10    continue
      ibynom=ib/iifact(k)
      return
      end
      function iifact(n)
      implicit REAL (a-h,o-z), integer(i-n)
      if (n.lt.0) then
       iifact=0
       return
      endif
      if (n.le.1) then
       iifact=1
      else
       j=1
       do 10 k=2,n
       j=j*k
10     continue
       iifact=j
      endif
      return
      end
      subroutine incas1
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/mapper)
INCLUDE(common/iofile)
      common/cone/m,nag,nbg,ispre(6),iperm(8,8)
INCLUDE(common/exc)
      common/drtlnk/norbl,nsyml,npassi,iprinl,labdrt(maxorb),odrt
     *, omt0
      common/qpar/ma,n2e,ntype,ncore,nact,nprim,nsec,nprimp,naa
     1                  ,nab,nst,nqe,isym,mults,macro,maxc,itypci
     2                  ,itydrt
INCLUDE(common/gjs)
INCLUDE(common/infoa)
INCLUDE(common/work)
INCLUDE(common/harmon)
      dimension ond(maxorb),ylbl(7),yopti(6)
      equivalence (ond(1),i4096(1))
      data yopti/'prin','pass','noso','bypa','nodr',' '/
      data maxact/255/
      data ylbl/
     *'fzc','doc','alp','aos','bos','uoc','fzv'/
      data ibltyp/6/
      data yend,yto/'end','to'/
      data oyes,ono/.true.,.false./
      ma=newbas0
      norbl=ma
      npassi=1
      iprinl=0
      omt0=ono
      odrt=oyes
 2231  call inpa4(ytext)
       j=locatc(yopti,6,ytext)
      if(j.eq.0)go to 2231
      go to (2236,2237,2238,2239,2239,2232),j
 2236 iprinl=1
      go to 2231
 2237 call inpi(npassi)
      go to 2231
 2238 omt0=oyes
      go to 2231
 2239 odrt=ono
      go to 2231
 2251  call caserr2(
     * 'invalid no. of orbitals in primary space.')
 2247  call caserr2(
     * 'invalid orbital type specified in config directive.')
 2265  call caserr2(
     * 'illegal parameters given in config directive.')
 2266  call caserr2(
     * 'illegal orbitals specified in config directive.')
 2267  call caserr2(
     * 'illegal number of active electrons.')
 2232   ij=0
        do 2235 i=1,ma
 2235   ond(i)=ono
        nprim=0
 2240 call input
      call inpa4(ytext)
      if(ytext.eq.yend)go to 2241
      k=locatc(ylbl,ibltyp,ytext)
      if(k)2243,2247,2243
 2243 call inpa4(ytest)
      if(ytest.eq.yopti(6))go to 2240
      jrec=jrec-1
      call inpi(m)
      n=m
      call inpa4(ytest)
      if(ytest.ne.yto)go to 2244
      call inpi(n)
      go to 2245
 2244 jrec=jrec-1
 2245 if(n.lt.1.or.m.lt.1.or.n.gt.ma)go to 2266
      do 2246 i=m,n
      ij=ij+1
      if(ond(i))call caserr2(
     *'orbital doubly defined in config directive.')
      if(ij.gt.maxact)go to 2251
      ond(i)=oyes
 2246 labdrt(i)=k
      if (ij.gt.100) write(iwr,603)
603   format(/,' ** more than 100 orbitals in CASSCF **',/,1x)
      go to 2243
 2241  do 2248 i=1,ma
       if(.not.ond(i))go to 2249
 2248  nprim=nprim+1
 2249  if(nprim.le.0.or.nprim.ne.ij)go to 2251
       ncore=0
       naa=0
       nact=0
       nab=0
       do 2252 i=1,nprim
       j=labdrt(i)
       if(j)2254,2247,2254
 2254  go to (2255,2256,2257,2257,2258,2259),j
 2255  ncore=ncore+1
       go to 2252
 2256  naa=naa+1
 2258  nab=nab+1
       go to 2259
 2257  naa=naa+1
 2259  nact=nact+1
 2252  continue
      nst=ncore+1
      if((nprim-ncore).ne.nact)go to 2251
      if(ncore.lt.0.or.ncore.ge.(ma-1))go to 2265
      if (nact.le.0) then
         write(iwr,602)
602      format(' ** no active orbitals ?? try doc instead of fzc **')
         go to 2265
      end if
      if(nab.gt.nact.or.naa.gt.nact) go to 2267
      if (nab.lt.1.or.nab.eq.nact.or.naa.lt.1) 
     +   write(iwr,601) 
601   format( 5x,'++++++++++++++++++++++++++++++++++++++++++++++++',
     +       /5x,'++ special single-config(?) case - careful !! ++',
     +       /5x,'++++++++++++++++++++++++++++++++++++++++++++++++'/)
cjvl
      nag=naa
      nbg=nab
      mults=(nag-nbg)+1
      if(mults.ne.mul)call caserr2(
     *'inconsistent multiplicity defined by config data.')
      nprimp=nprim+1
      nsec=ma-nprim
      if(nsec.lt.1)call caserr2(
     *'no orbitals in secondary space.')
      nmc=nprim
      call setsto(nsec,7,labdrt(nprim+1))
      do 2262 i=1,maxorb
 2262 i4096(i)=i*256
      ifstr=1
      do 3450 i=1,nact
      j=ncore+i
      lby=labdrt(j)
      if(lby.eq.5.or.lby.eq.6)go to 3451
      do 3452 k=1,kkkm
 3452 iocca(k,i)=1
 3451 if(lby.eq.3.or.lby.eq.4.or.lby.eq.6)
     *go to 3450
      do 3453 k=1,kkkm
3453  ioccb(k,i)=1
 3450 continue
      if(kkkm.eq.1)go to 5500
      do 5501 i=2,kkkm
      call input
      j=jump/2
      if(j*2.ne.jump)go to 2265
      do 5502 k=1,j
      call inpa4(ytext)
      do 5503 ktyp=2,ibltyp
      if(ytext.eq.ylbl(ktyp))go to 5504
 5503 continue
      go to 2247
 5504 call inpi(m)
      if(m.le.ncore.or.m.gt.nprim)go to 2266
      mm=m-ncore
      iocca(i,mm)=0
      ioccb(i,mm)=0
      if(ktyp.eq.5.or.ktyp.eq.6)go to 5505
      iocca(i,mm)=1
 5505 if(ktyp.eq.3.or.ktyp.eq.4.or.ktyp.eq.6)
     *go to 5502
      ioccb(i,mm)=1
 5502 continue
 5501 continue
 5500 do 5506 i=1,kkkm
      k=0
      do 5507 j=1,nact
 5507 k=k+iocca(i,j)+ioccb(i,j)
      if(k.ne.(nag+nbg))go to 2267
 5506 continue
      return
      end
      subroutine incas2(oactiv,ocidu,jdeg,jrun)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/avstat)
INCLUDE(common/simul)
INCLUDE(common/blksiz)
INCLUDE(common/dm)
INCLUDE(common/ctrl)
INCLUDE(common/ciconv)
      common/degen /ifdeg,idegen(100),ophase
INCLUDE(common/exc)
      common/blbpar/accblb,clevs
INCLUDE(common/finish)
      common/prints/oprint(20),
     * odist, obas , oadap, osadd, ovect, oanal, ohess,
     * onopr(13),
     * opmull, oplowd, opmos , opsadd, opvect, opadap, opdiis,
     * opsymm, opfock, opq   , opao  , opmo  , opdump, opgf  ,
     * optda , oprin(5),
     * ciprnt
      common/drtlnk/norbl,nsyml,npassi,iprinl,labdrt(maxorb),odrt
     *, omt0
INCLUDE(common/files)
      common/qpar/ma,n2e,ntype,ncore,nact,nprim,nsec,nprimp,naa
     1                  ,nab,nst,nqe,isym,mults,macro,maxc,itypci
     2                  ,itydrt
INCLUDE(common/runlab)
INCLUDE(common/restar)
INCLUDE(common/restrj)
      common/tran/ilifc(maxorb),ntranc(maxorb),itranc(mxorb3),
     * ctran(mxorb3),otran,otri
      common/atmol3/mina,minb,mouta,moutb,lock,ibrk,
     * numg(2),isecg(2),iblk3g(2),mextra,nsym,iorbsy(100),
     * oming, oextg,
     *gapa1,gapa2,gapb1,gapb2,scale,symtag(9)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/cndx40)
      common/scfopt/maxit,mconv,nconv,npunch,accdi1,accdi2,odiis
     * ,icoupl,ifolow,irotb,dmpcut
      dimension iigrad(7)
      equivalence (iigrad(1),igrad)
      data oyes/.true./
c     data maxact/100/
      data m4,m8,m3,m5,m6,m7,m2/4,8,3,5,6,7,2/
c
      if(minb.gt.0)write(iwr,9075)minb
 9075 format(/' restore casscf-ci vector from dumpfile section ',i3)
      if(moutb.gt.0)write(iwr,9074)moutb
 9074 format(/' output casscf-ci vector to dumpfile section',i3)
      write(iwr,2041)nsz
 2041 format(' blocking factor for sort file = ',i3)
      write(iwr,9072)ions2
 9072 format(
     *' symmetry adapted 1-e integrals to section',i4,
     *' of the dumpfile')
      call filchk(n1file,n1blk,n1last,n1tape,m7)
      call filchk(n4file,n4blk,n4last,n4tape,m2)
      call filchk(n6file,n6blk,n6last,n6tape,m3)
      call filchk(n9file,n9blk,n9last,n9tape,m5)
      if(.not.omt0)call filchk(ntfile,ntblk,ntlast,nttape,m6)
      maxc=maxit
      if(maxc.gt.n20cas)maxc=n20cas
      if(.not.oactiv)call caserr2(
     *'config directive omitted.')
_IFN(parallel)
      call setbfa
_ENDIF
      write(iwr,2411)
2411  format(/1x,'casscf options'/1x,14('-')/)
      if(ocidu)write(iwr,2091)ciprnt
 2091 format(1x,
     *'specified threshold for ci vector print',f9.5)
      if(icanon.ne.0)write(iwr,2102)icanon
 2102 format(1x,
     *'final vectors to be canonicalised over hamiltonian',i3)
      write(iwr,2171)accblb
 2171 format(1x,'super-ci accuracy',e10.2)
      acc1=10.0d0**(-iacc4)
      write(iwr,2181)acc1
 2181 format(1x,'4-index accuracy factor',e12.1)
      write(iwr,2233)nst,nprim
 2233 format(1x,
     *'active space - orbitals',i3,' to',i3)
      write(iwr,2201)naa,nab
2201  format(1x,
     *i3,' alpha spin electrons and',i3,
     *' beta spin electrons in active space')
      if(ojust)write(iwr,2163)
 2163 format(1x,
     *'dynamically adjust ci accuracies')
      if(.not.ojust)write(iwr,2162)fudgit
 2162 format(1x,
     *'ci accuracies in successive iterations : ',10e8.1)
      if(ifdeg.ne.1)go to 2420
      write(iwr,2122)
 2122 format(/1x,
     *'orbitals to be symmetry equivalenced'/1x,36('-')/)
      i=jdeg/2
      k=1
      do 2421 j=1,i
      write(iwr,2422)ilifc(k),ilifc(k+1)
 2422 format(/i5,' and',i3)
 2421 k=k+2
 2420  if(nwt.le.1)go to 2430
      write(iwr,2024)(weight(i),i=1,nwt)
 2024 format(1x,
     *'orbital optimization to be performed for average of states'/
     *1x,'weights of states are : ',5f16.7)
2430  write(iwr,2450)
 2450 format(/1x,'strings specification'/1x,21('-')/)
      do 2451 i=1,kkkm
      write(iwr,2452)i,(iocca(i,j),j=1,nact)
 2452 format(1x,'state ',i2,5x,'alpha electrons',20i3)
      write(iwr,2453)(ioccb(i,j),j=1,nact)
 2453 format(14x,' beta electrons',20i3)
 2451 continue
      if(omt0)write(iwr,2454)
 2454 format(1x,
     *'suppress sorting of loop formulae tape')
      if(orege) odrt=oyes
      if(.not.odrt)write(iwr,2440)
 2440 format(1x,'suppress generation of loop formulae tape')
      write(iwr,2300)
 2300 format(/1x,60('-')/
     *1x,'optimization',24x,'iterations'/
     *1x,60('-')/)
      if (osuped) then
c...   dynamic CASSCF convergence control
       if (swnr.gt.0.0d0) nrever = 1
       swsimu = dmin1(swsimu,swnr)
       if (swsimu.gt.0.0d0) ifsimu = 1
       write(iwr,2413) swnr,swsimu,nhesnr
2413   format(' *** dynamic CASSCF control *** '/
     1        ' switch to Newton Raphson  at maximal B-state ',f12.6/
     2        ' switch to simultaneous NR at maximal B-state ',f12.6/
     3        ' recalculate Hessian every ',i2,' iteration ')
       fmax = 1.0d0
       go to 2432
      end if
c
      do 24021 i=1,maxc
      j1=isort(i)
      if(j1.eq.0)go to 24021
      if(j1.eq.2)go to 24022
      isort(i)=2
      go to 24022
24021 continue
24022 j1=0
      j2=n20cas
      j3=2*n20cas
      j4=3*n20cas
      j5=4*n20cas
      do 2400 i=1,maxc
      if(isort(i)-1)2401,2402,2402
 2401 j1=j1+1
      ilifc(j1)=i
      go to 2403
 2402 j2=j2+1
      nrever=1
      ilifc(   j2)=i
      if(isort(i).ne.2)go to 2403
      j3=j3+1
      ilifc(   j3)=i
 2403 if(isimul(i).ne.1)go to 2404
      j4=j4+1
      ilifc(   j4)=i
 2404 if(noci(i).ne.1)go to 2400
      j5=j5+1
      ilifc(  j5)=i
 2400 continue
      if(j1.gt.0)write(iwr,2405)(ilifc(i),i=1,j1)
      if(j2.gt.n20cas)  write(iwr,2406)(ilifc(i),i=n20cas+1,j2)
      if(j3.gt.n20cas*2)write(iwr,2407)(ilifc(i),i=n20cas*2+1,j3)
      if(j4.gt.n20cas*3)write(iwr,2408)(ilifc(i),i=n20cas*3+1,j4)
      if(j5.gt.n20cas*4)write(iwr,2409)(ilifc(i),i=n20cas*4+1,j5)
 2405 format(1x,'super-ci',26x,30i3)
 2406 format(1x,'newton raphson',20x,30i3)
 2407 format(1x,'hessian construction and inversion',30i3)
 2408 format(1x,'simultaneous optimization',9x,30i3)
 2409 format(1x,'ci stage to be omitted',12x,30i3)
      if(j5.gt.4*n20cas) then
      do 2431 i=1,maxc
      if(noci(i).eq.0)go to 2431
      if(i.eq.1.or.isimul(i-1).eq.0)call caserr2(
     * 'noci requested but previous iteration not simult. opt.')
 2431 continue
      endif
 2432 write(iwr,2410)
 2410 format(/1x,60('-')/)
      if ((j4.gt.n20cas*3.and..not.osuped).or.
     +    (osuped.and.swsimu.ne.0.0d0)) then
      if(omt0)call caserr2(
     * 'simult. opt. requested but no sorted formula tape.')
      endif
      if(ipople.eq.1)write(iwr,2412)
 2412 format(1x,
     *' solve the newton-raphson equations with method due to pople'/)
      if(jrun.lt.4)go to 9071
      do 2076 i=1,7
 2076 iigrad(i)=1
      ifmola=1
      if(.not.orege.and.irest.eq.4)oconv=oyes
      call filchk(n6file,n6blk,n6last,n6tape,m8)
      call filchk(n11fil,n11bl,n11lst,n11tap,m4)
      write(iwr,2075)isecdm,isecda,isecla
 2075 format(/
     *' casscf routing specification'/1x,28('-')/
     *' 1-particle density matrix (mo basis) to section',i4/
     *' 1-particle density matrix (ao basis) to section',i4/
     *' lagrangian (ao basis) to section               ',i4/
     *1x,28('-')/)
9071  return
      end
      subroutine incas3(jrun)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      logical oyes
INCLUDE(common/multic)
INCLUDE(common/jobopt)
INCLUDE(common/blksiz)
INCLUDE(common/dm)
INCLUDE(common/files)
      common/atmol3/mina,minb,mouta,moutb
INCLUDE(common/iofile)
INCLUDE(common/dump3)
      common/linkmc/irestm,ivect,iorbit,iblrst,numrst,isecrs,
     * ivgues,ipread,iblpp,ibllg,icano
INCLUDE(common/restrj)
INCLUDE(common/finish)
      dimension iigrad(7)
      equivalence (iigrad(1),igrad)
      data m4,m8,m3,m5,m7,m2/4,8,3,5,7,2/
      data oyes/.true./
c
      if(moutb.le.0)moutb=472
      ivgues=1
      isecrs=mouta
      isec=mouta
      isecd=moutb
c     set convergence accuracy (based on nconv in start)
      if (econv.eq.0.0d0) econv = cccnv
c
      if(icano.eq.1) icang=1
      if(minb.gt.0)write(iwr,9075)minb
 9075 format(/' restore mcscf-ci vector from dumpfile section ',i3)
      if(isecd.gt.0)write(iwr,9074)isecd
 9074 format(/' output mcscf-ci vector to dumpfile section',i3)
      write(iwr,2041)nsz
 2041 format(/' blocking factor for sort file = ',i3)
      write(iwr,9072)ions2
 9072 format(/
     *' symmetry adapted 1-e integrals to section',i4,
     *' of the dumpfile')
      call filchk(n1file,n1blk,n1last,n1tape,m7)
      call filchk(n4file,n4blk,n4last,n4tape,m2)
      call filchk(n6file,n6blk,n6last,n6tape,m3)
      if(iexc.ge.0)
     *call filchk(n9file,n9blk,n9last,n9tape,m5)
_IFN(parallel)
      call setbfa
_ENDIF
      iblsrt=nsz*512
      if(jrun.lt.4)go to 9071
      do 2076 i=1,7
 2076 iigrad(i)=1
      ifmola=1
      if(.not.orege.and.irestm.eq.4)oconv=oyes
      call filchk(n6file,n6blk,n6last,n6tape,m8)
      call filchk(n12fil,n12bl,n12lst,n12tap,m4)
      write(iwr,2075)isecdm,isecda,isecla
 2075 format(/
     *' mcscf  routing specification'/1x,28('*')//
     *' 1-particle density matrix (mo basis) to section',i4/
     *' 1-particle density matrix (ao basis) to section',i4/
     *' lagrangian (ao basis) to section               ',i4//
     *1x,28('-')//)
9071  return
      end
      subroutine inplis (inf,ibit,icntrl)
c...  read input list & set or clear bits in inf
      implicit REAL  (a-h,o-z)
      character*8 test
INCLUDE(common/work)
      integer inf(*)
      jfirst=1
10    if (jrec.ge.jump) return
      call inpa(test)
      if (test.eq.'to') then
      call inpi(jlast)
      else
      jrec = jrec -1
      call inpi(jfirst)
      jlast = jfirst
      end if
      if (jfirst.gt.jlast .or. jfirst.lt.1 .or. jlast.gt.40)
     1 call caserr2('error in list input')
      do 20 j=jfirst,jlast
      if (icntrl.eq.1) inf(j) = ibset(inf(j),ibit)
      if (icntrl.eq.0) inf(j) = ibclr(inf(j),ibit)
20    continue
      goto 10
      end
      subroutine mcdata(q,iq)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      parameter (ndirec=37,nprin=23,nitdir=7,nprop=6)
      logical lflag,oslash
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/multic)
INCLUDE(common/jobopt)
      common/linkmc/irestm,ivect,iorbit,
     *              iblrst,numrst,isecrs,ivgues,ipread,iblkp,iblkg
      common/rotat/akk(20),all(20),rota(20),nswap
INCLUDE(common/machin)
INCLUDE(common/direc)
INCLUDE(common/runlab)
INCLUDE(common/workc)
INCLUDE(common/work)
      dimension q(*),iq(*)
      character*4 test
      character*4 dirctv(ndirec),iprin(nprin),itdir(nitdir),props(nprop)
      integer itdep (nitdir,nitdir), ittemp(40)
      character*10 charwall
      data iprin/'drt ' ,'form','inte','addr','debu'
     1           ,'dens','hess','grad','orbi','cive'
     2           ,'step','nato','virt','pspa','ci2 '
     3           ,8*' '/
      data itdir /'diag','unco','wern','augm','newt'
     1          ,'null','inte'/
      data itdep / 1,5*0,0, 2*1,4*0,0, 2*0,1,3*-1,0, 2*0,-1,1,2*-1,0,
     <             2*0,2*-1,1,-1,0,  2*0,3*-1,1,0,  -1,5*0,1 /
      data props /'s','t','t+v','x','y','z'/
      data dirctv/'****','main','ipri','prin','****'
     1           ,'dump','size','conv','maxc','begi'
     2           ,'rota','file','test','step','rest'
     3           ,'do  ','dont','exci','stat','cigu'
     4           ,'orbi','iter','****','pola','cano'
     5           ,'spar','auto','prop','nonl','weig'
     6           ,'into','diis','thre','copt','safe'
     >           ,'pspa','root'/
      ibase=icorr(0)
      nav = lenwrd()
      dumt = seccpu()
      write(iwr,3000)dumt ,charwall()
3000  format(/1x,79('*')/
     *1x,'mcscf pre-processor called at ',f9.2,' seconds',a10,' wall'/)
      iagues=0
c
c     defaults for =canonical=, correspond to directive
c     canonical 10 fock density fock
      isecn = 10
      icani = 1
      icant = 2
c
c     defaults for print, correspond to
c     print orbitals virtuals natorb
      j = 0
      j = ibset(j,9)
      j = ibset(j,13)
      j = ibset(j,12)
      lprint = j
c
c
c..   process begin directive
      lflag=.false.
      itest=0
      goto 441
c...  read directives
90    if(lflag) go to 900
c... process =multi=directive
      if(irestm.ne.1)go to 900
      call restr(q(1),isecrs,iblrst,numrst,iagues)
      irestm=1
      nstrea=nstate
      icang=0
      ifsort=0
      itrsfm=0
      ifwvfn=0
c...  read directives
900   call input
      itest=0
      test1=0
      test2=0
      lflag=.true.
      if(char1(1:1).eq.'*' .or. jump.eq.0) goto 90
      call inpa4(test)
      k = locatc (dirctv,ndirec,test)
      if (k.ne.0) go to 9000
      jrec=jrec-1
      k=locatc(ydd(101),limit2,test)
      if(k.eq.0)call caserr2(
     *'unrecognised directive or invalid directive sequence')
      go to 9995
9000  goto (90,540,520,520,90
     1     ,90,480,470,460,440
     2     ,430,420,400,390,370
     3     ,300,300,320,330,350
     4     ,290,270,90,250,240
     5     ,230,210,200,130,110
     6     ,140,150,160,135,113
     7     ,505,431),k
c
c...  =root=
431   call inpi(iroot1)
      write(iwr,432)iroot1
432   format(' first state to be root number',i2,' of hamiltonian')
      goto 90
c
c... =pspace=
 505   ix=icori(1280)
       jjj=0
       do 506 ii=1,40
       call input
       call inpa4(test)
       if(test.eq.'end')go to 507
       jrec=jrec-1
       do 508 jj=1,jump
       call inpi(iq(jjj+ix))
 508   jjj=jjj+1
 506   ipread=ipread+1
 507   nw=(jjj-1)/nav+1
       iblkp=iposun(num8)
       call wrt3i(iq(ix),nw*nav,iblkp,num8)
       call corlsi(ix)
      go to 90
c
c... =safety=
113   call inpf(safty(1))
      call inpf(safty(2))
      goto 90
c
c... =weight=
110   do 120 i=1,nstate
120   call inpf(weight(i))
      zz = 1.0d0/dsum(nstate,weight,1)
      call dscal(nstate,zz,weight,1)
      write(iwr,121)(weight(i),i=1,nstate)
121   format(/' weight factors for states: ',10f10.5)
      goto 90
c
c... =nonlinear=
130   if (jrec.lt.jump) call inpi(itmaxr)
      if (jrec.lt.jump) call inpi(ipri)
      if (jrec.lt.jump) call inpf(drmax)
      if (jrec.lt.jump) call inpf(drdamp)
      if (jrec.lt.jump) call inpf(gfak1)
      if (jrec.lt.jump) call inpf(gfak2)
      if (jrec.lt.jump) call inpf(gfak3)
      if (jrec.lt.jump) call inpi(irdamp)
      if (jrec.lt.jump) call inpi(ntexp)
      call outrec
      goto 90
c
c... =copt=
c.....copvar=start threshold for ci-optimization
c.....select=selection threshold for primary configurations
c.....cishft=denominator shift for q-space
c.....icimax=max. number of ci-optimizations in first macroiteration
c.....icimx1=max. number of ci-optimizations in second and subsequent it
c.....icimx2=max. number of ci-optimizations in internal absorption step
c.....maxci= max. number of ci-optimizations per microiteration
c.....icstep=microiteration increment between ci optimizations
c......ciacc=grad threshold for ci diagonalisation
135   if (jrec.lt.jump) call inpf(copvar)
      if (jrec.lt.jump) call inpf(select)
      if (jrec.lt.jump) call inpf(cishft)
      if (jrec.lt.jump) call inpf(ciacc)
      if (jrec.lt.jump) call inpi(icimax)
      if (jrec.lt.jump) call inpi(icimx1)
      if (jrec.lt.jump) call inpi(icimx2)
      if (jrec.lt.jump) call inpi(maxci)
      if (jrec.lt.jump) call inpi(icstrt)
      if (jrec.lt.jump) call inpi(icstep)
      call outrec
      goto 90
c
c... =intopt=
140   if (jrec.lt.jump) call inpi(maxito)
      if (jrec.lt.jump) call inpi(maxitc)
      if (jrec.lt.jump) call inpi(maxrep)
      if (jrec.lt.jump) call inpi(nitrep)
      if (jrec.lt.jump) call inpi(iuprod)
      call outrec
      goto 90
c
c.. =diis=
150   if (jrec.lt.jump) call inpf(disvar)
      if (jrec.lt.jump) call inpf(augvar)
      if (jrec.lt.jump) call inpi(maxdis)
      if (jrec.lt.jump) call inpi(maxaug)
      if (jrec.lt.jump) call inpi(idsci)
      if( jrec.lt.jump) call inpi(igwgt)
      if (jrec.lt.jump) call inpi(igvec)
      if (jrec.lt.jump) call inpi(idstrt)
      if (jrec.lt.jump) call inpi(idstep)
      call outrec
      goto 90
c
c... =thresh=
160   if (jrec.lt.jump) call inpf(varmin)
      if (jrec.lt.jump) call inpf(varmax)
      if (jrec.lt.jump) call inpf(thrdiv)
      if (jrec.lt.jump) call inpf(ciderr)
      call outrec
      goto 90
c
c... =property=
200   call inpa4(test)
      if (test.eq.' ') goto 90
      n1elec = n1elec + 1
      if (n1elec.gt.20) call caserr2('too many properties specified')
      i1elec(n1elec) = locatc(props,nprop,test)
      goto 200
c
c... =auto=
210   write(iwr,220)
220   format(' auto directive not used at present')
      goto 90
c
c...  =sparsity=
230   call inpf(sparse)
      call outrec
      goto 90
c
c...  =canonical=
240   test1=0
      call inpf(test1)
      isecn=test1
      call inpa4(test)
      icani=0
      if (test.eq.'fock') icani=1
      call inpa4(test)
      icant=0
      if (test.eq.'fock') icant=1
      icant=0
      if (test.eq.'dens') icant=2
      call inpa4(test)
      icana=1
      if (test.eq.'none') icana=0
      call inpa4(test)
      icinat=0
      if (test.eq.'ci') icinat=1
      call inpf(test2)
      isecnc=test2
      if(isecnc.gt.1000) isecnc=10*test2+0.1d0
      call outrec
      goto 90
c
c...  =polarizability=
250   call inpi(isecp)
      if (isecp.le.0) isecp=52
      print '('' polarizability not yet implemented'')'
      goto 90
c
c... =iterations=
270   call input
      icntrl = 1
280   call inpa4(test)
      if (test.eq.'end') goto 90
      if (test.eq.'dont') icntrl=0
      if (test.eq.'dont' .or. test.eq.'do') goto 280
      k = locatc(itdir,nitdir,test)
      if (k.eq.0) call caserr2('unrecognised iterations option')
      if (icntrl.eq.0) then
      call inplis (itinfo,k,0)
      else
      call setsto(40,0,ittemp)
      call inplis(ittemp,k,icntrl)
      do 445 i=1,40
      if (ittemp(i).eq.0) goto 445
      do 446 j=1,nitdir
      if (itdep(j,k).eq.1) then
      itinfo(i) = ibset(itinfo(i),j)
      else if (itdep(j,k).eq.-1) then
      itinfo(i) = ibclr(itinfo(i),j)
      end if
446   continue
445   continue
      end if
      goto 270
c
c... =orbital=
c
290   iorbit=1
      oslash=.false.
292   call input
      do 291 i=1,jump
      call inpa(zorb(iorbit))
      if(index(zorb(iorbit),'/').ne.0) oslash = .true.
      if(zorb(iorbit).eq.'end')then
       if(oslash) then
       oslash = .false.
       go to 291
       else
       go to 90
       endif
      endif
291   iorbit=iorbit+1
      go to 292
c
c... =do=,=dont=
c
300   junk=0
      if (test.eq.'dont') junk=1
      do 310 i=2,jump
      call inpa4(test)
      if (test.eq.'ints' .or. test.eq.'sort') ifsort=junk
      if (test.eq.'form' .or. test.eq.'fmtp') iffmtp=junk
      if (test.eq.'wave' .or. test.eq.'wvfn') ifwvfn=junk
      if(test.eq.'anal'.or.test.eq.'prin')
     1   ifanal=junk
      if (test.eq.'cano'.and.junk.eq.1) then
      icana=0
      icant=0
      icani=0
      end if
310   continue
      goto 90
c
c... =excitation=
320   iexc=0
      call inpi(iexc)
      call inpi(iexcv)
      goto 90
c
c... =state
330   call inpi(nstate)
      if(iguess.lt.0.and.nstate.ne.nstrea) call caserr2(
     +  'ciguess card must follow state card')
      if(iguess.gt.0.and.nstate.ne.nstrea) then
      iguess=0
      call corlsr(iagues)
      write(iwr,341)nstate,nstrea
341   format(/' *** warning: specified number of states not equal to'
     1  ,' number in restarted job, ciguess omitted',2i4)
      end if
      do 340 i=1,nstate-1
340   weight(i)=0.0d0
      weight(nstate)=1.0d0
      write(iwr,342)nstate
342   format(/' number of states =',i2)
      goto 90
c
c... =ciguess=
350   call outrec
      call inpa4(test)
      if(test.eq.'unit') then
      iguess=0
      goto 90
      end if
      iguess=-1
      if(test.ne.'here'.and.test.ne.'card') then
      call caserr2('unknown ciguess directive')
      end if
      call inpi(itest)
      if(nci.eq.0) nci=itest
      if(nci.eq.0) call caserr2(
     +  'specify no. of configs. with ciguess or restore required')
      junk=nci*nstate
      if(iagues.eq.0) iagues=icorr(junk)
      call vclr(q(iagues),1,junk)
360   call input
      call inpa4(test)
      if (test.eq.'end') goto 90
      jrec=jrec-1
      junk1=0
      junk2=0
      call inpi(junk1)
      call inpi(junk2)
      call inpf (q(iagues-1+(junk1-1)*nci+junk2))
      call outrec
      goto 360
c
c... =restore=
370   irestm=1
      go to 90
c
c... =step=
390   if (jump.gt.1) call inpf(radius)
      if (jump.gt.2) call inpf(trust1)
      if (jump.gt.3) call inpf(tfac1)
      if (jump.gt.4) call inpf(trust2)
      if (jump.gt.5) call inpf(tfac2)
      call outrec
      radius = - radius
      goto 90
c
c... =test=
400   do 410 i=2,jump
      itest=0
      call inpi(itest)
410   if(itest.ne.0) lto(itest)=.true.
      call outrec
      goto 90
c
c... =files=
420   if (jrec.lt.jump) call inpdd(num2,iblk2)
      if (jrec.lt.jump) call inpdd(num4,iblk4)
      if (jrec.lt.jump) call inpdd(num6,iblk6)
      if (jrec.lt.jump) call inpdd(numft,iblkft)
      if (jrec.lt.jump) call inpdd(numscr,iblk8)
      goto90
c
c... =rotate=
 430  nswap=nswap+1
      call inpf(akk(nswap))
      call inpf(all(nswap))
      call inpf(rota(nswap))
      go to 90
c
c... =begin= directive .. reset iteration controls etc
440   if(jrec.lt.jump) call inpi(itest)
441   itrsfm=0
      nstrea=0
      ifwvfn=0
      ifanal=0
      iter=0
      if(itest.ne.0) iter=1
      elast=0.0d0
      elast2=0.0d0
      glast=100.0d0
      glast2=100.0d0
      slast=100.0d0
      enext=0.0d0
      goto 90
c
c... =maxcyc= directive
460   call inpi(maxcyc)
      maxcyc=min(maxcyc,39)
      go to 90
c
c... =convergence= directive
470   call inpf(buff)
      call inpa4(test)
      if (test.eq.' ' .or. test.eq.'grad') conv = buff
      if (test.eq.'ener') econv = buff
      if (test.eq.'step') sconv = buff
      go to 90
c... =size= directive
480   call maxset
       call revind
       goto 90
c... =print=,=iprint=
520   icntrl=0
      if (test.eq.'ipri') icntrl=1
      j=0
      do 530 i=2,jump
      call inpa4(test)
      k = locatc(iprin,23,test)
      if (k.eq.0) then
      call errout (istrt(jrec))
      call caserr2('illegal print option')
      end if
530   j = ibset(j,k)
      if (icntrl.eq.0) lprint=j
      if (icntrl.eq.1) iprint=j
      call outrec
      go to 90
c
c... =mainfile=
540   call inpdd(numa,iblka)
      goto 90
c
c...  append cigues data to scratch file
9995  if(iagues.eq.0)go to 2000
      iblkg=iposun(num8)
      call wrt3(q(iagues),nci*nstate,iblkg,num8)
2000  call corlsr(ibase)
c     ibl7la=iposun(num8)
      return
      end
      subroutine mczero(first)
      implicit REAL  (a-h,o-z)
      character *8 itdir,props
      logical first
INCLUDE(common/sizes)
      character*3 codes
      integer dela,delb,delele,virtul,occupd,valocc,rescor,resvir
     >       ,frozen,valvir,opensh,multi,speshl,multrf,valenc
     >       ,fzc,fzv,cor,vir,doc,uoc,alp,bet,spe
INCLUDE(common/iofile)
INCLUDE(common/dump3)
      common/rotat/akk(60),nswap
INCLUDE(common/multic)
INCLUDE(common/jobopt)
INCLUDE(common/syminf)
INCLUDE(common/machin)
      common /drtcoc/ codes(9)
      common /drtcod/ ncodes,dela(9),delb(9),delele(9)
     1,               ntypes,virtul,occupd,valocc,rescor,resvir,frozen
     2,               valvir,opensh,multi,speshl,multrf,valenc
     3,   fzc, fzv, cor, vir, doc, uoc, alp, bet, spe
      common/linkmc/irest,ivect,iorbit
     * , iblrst,numrst,isecrs,ivgues,ipread,iblkp,iblkg
c
      dimension itdir(7),props(6),multmc(8,8)
c
      data multmc/1,2,3,4,5,6,7,8,
     1           2,1,4,3,6,5,8,7,
     2           3,4,1,2,7,8,5,6,
     3           4,3,2,1,8,7,6,5,
     4           5,6,7,8,1,2,3,4,
     5           6,5,8,7,2,1,4,3,
     6           7,8,5,6,3,4,1,2,
     7           8,7,6,5,4,3,2,1/
      data itdir /'diagci  ','uncouple','werner  ','augment ','newton  '
     1          ,'null    ','internal'/
      data props /'s','t','t+v','x','y','z'/
c
      mcacct=.true.
c
       ipread=0
       iblkp=0
       iblkg=0
      ncodes=9
      codes(1)='fzc'
      codes(2)='fzv'
      codes(3)='cor'
      codes(4)='vir'
      codes(5)='doc'
      codes(6)='uoc'
      codes(7)='alp'
      codes(8)='bet'
      codes(9)='spe'
c
      do 1 i=1,9
      dela(i)=0
      delb(i)=0
   1  delele(i)=0
      dela(3)=1
      dela(5)=1
      dela(8)=1
      delb(7)=1
      delb(8)=-1
      delele(3)=2
      delele(5)=2
      delele(7)=1
      delele(8)=1
c
      ntypes=10
      virtul=1
      occupd=2
      valocc=4
      rescor=8
      resvir=9
      frozen=10
      opensh=6
      multi=5
      valvir=3
      speshl=7
      multrf=2
      valenc=3
c
      fzc=1
      fzv=2
      cor=3
      vir=4
      doc=5
      uoc=6
      alp=7
      bet=8
      spe=9
c
      nswap=0
c
      do 2 i=1,8
      do 2 j=1,8
 2    mults(i,j)=multmc(i,j)
      do 51 i=1,8
      nsymao(i)=0
51    nsymm(i)=0
      nitdir=7
      nprop=6
      ivect=0
      iorbit=0
      safty(1)=0.9d0
      safty(2)=0.0d0
      do 10 i=1,10
10    lto(i) = .false.
      idump = 0
      iguess=0
      ivgues=0
c
c.....initialization and default values
c
      if(first)go to 1000
      irest=0
      nfreez=0
      do 50 i=1,8
50    ifreez(i)=0
c
      maxcyc=12
      icang=0
c...  convergence thresholds
      conv = 0.0d0
c     econv set in incas3
c     econv = 1.0d-6
      sconv = 0.0d0
c...  for augmented hessian method
      radius = -0.5d0
      trust1 = 0.3d0
      tfac1 = 0.66d0
      trust2 = 0.15d0
      tfac2 = 1.2d0
      itrsfm=0
      ifwvfn=0
      ifanal=0
      iter=0
      elast=0.0d0
      elast2=0.0d0
      glast=100.0d0
      glast2=100.0d0
      slast=100.0d0
      enext=0.0d0
c...  for nonlinear
      copvar = 0.10d0
      icimax=3
      icimx1=10
      icimx2=1
      maxci=1
      icstrt=4
      icstep=1
      irdamp=0
      itmaxr = 15
      ipri=0
      ntexp=10
      varmin = 1.0d-7
      varmax = 1.0d-3
      thrdiv=2.0d-1
      ciderr = 1.0d-2
      gfak1 = 4.0d0
      gfak2 = 3.0d0
      gfak3 = 0.7d0
      drmax = 0.1d0
      select = 0.4d0
      drdamp = 0.75d0
      cishft = 0.4d0
      ciacc = 0.1d0
      sparse = 0.01d0
c...  for intopt
      maxito=3
      maxitc=1
      maxrep=1
      nitrep=1
      iuprod=0
c...  for diis
      igvec=1
      igwgt=0
      idsci=2
      idstrt=2
      idstep=1
      maxdis=10
      maxaug=15
      disvar=0.07d0
      augvar=0.2d0
c...  default for properties
      i1elec(1)=locatc(props,nprop,'t')
      i1elec(2)=locatc(props,nprop,'x')
      i1elec(3)=locatc(props,nprop,'y')
      i1elec(4)=locatc(props,nprop,'z')
      n1elec=4
c
      iintern = locatc(itdir,nitdir,'internal')
      iwerner = locatc(itdir,nitdir,'werner')
c...  to fix ibset problems on rs6000 (compiler ??)
      do 450 i=1,39
      itinfo(i)=ibset(0,iwerner)
      if (i.gt.1) itinfo(i)=ibset(itinfo(i),iintern)
450   continue
c....  default to diagonalise ci at first iteration
      itinfo(1)=ibset(itinfo(1),locatc(itdir,nitdir,'diagci'))
c...  default no optimisation at last iteration
      itinfo(40) = ibset(0,locatc(itdir,nitdir,'null'))
      nci=0
      iexc=-1
      iexcv=0
      iprint=0
      lprint=0
      iblkn=0
      icinat=0
      isecn=0
      isecd=472
      isec=0
      icani=1
      icant=0
      icana=1
      nstate=1
      iroot1=1
      weight(1)=1.0d0
      iffmtp=0
      ifsort=0
      return
1000  numrst=num3
      iblrst=iblk3
c
c     need to set block pointers etc. to allow for symmetry
c     changes in force constant calculations
c
      iblkn=0
      irest = 0
      iguess = 0
      ivgues = 1
      iorbit = 1
      call secget(isecd,172,iblpr)
      call rdedx(radius,mach(18),iblpr,num3)
      isecrs=isec
      write(iwr,20)isecd
 20   format(/
     *' job information and ci vectors restored from section',
     *i4)
      maxcyc=12
      iter=0
      elast=0.0d0
      elast2=0.0d0
      glast=100.0d0
      glast2=100.0d0
      slast=100.0d0
      enext=0.0d0
      ifsort=0
      ifwvfn=0
      ifanal=0
      itrsfm=0
      return
      end
      subroutine mrdcim(core,energy)
      implicit REAL  (a-h,o-z),integer(i-n)
      logical bypass,oprin
INCLUDE(common/sizes)
INCLUDE(common/restar)
INCLUDE(common/iofile)
_IF1()c     common/scrtch/space(185000)
INCLUDE(common/mapper)
INCLUDE(common/prints)
      common/mrdci1/bypass(9),oprin(9,3),modew(10),igame,ispci,mblkci
      common/linkmr/imap(512),igam
      common/craypk/param(1)
INCLUDE(common/statis)
INCLUDE(common/timez)
INCLUDE(common/zorac)
INCLUDE(common/infoa)
      common/restri/nfils(63),lds(508),isect(508),ldsect(508)
      Dimension core(*),ipoint(9,9)
      character*10 charwall
      data m10/10/
      data ipoint /
     * 0,0,0,0,0,0,0,0,0,
     * 1,0,0,0,0,0,0,0,0,
     * 0,1,0,0,0,0,0,0,0,
     * 0,1,1,0,0,0,0,0,0,
     * 0,0,0,1,0,0,0,0,0,
     * 0,0,0,0,1,1,0,0,0,
     * 0,0,0,0,0,1,1,0,0,
     * 0,0,0,0,0,0,1,1,0,
     * 0,0,0,0,0,1,1,1,1 /
c
      if(ibl3d.le.0)call caserr2('invalid dumpfile starting block')
c
c...  calculate zora stuff before memory is eaten
c...   (not used here ; just to get it written to disk)
c
      if (ozora) then
         if (oscalz.and..not.opre_zora)
     1      call caserr2('scaled zora requires scf before mrdci')
         ibase = igmem_alloc(nx*2)
_IF(cray,ibm,vax)
          call szero(core(ibase+nx),nx)
_ELSE
          call vclr(core(ibase+nx),1,nx)
_ENDIF
         call zora(core,core(ibase),core(ibase+nx),'calc')
         call gmem_free(ibase)
      end if
c
c     allocate all available memory
c
      ibase = igmem_alloc_all(lword)
c
      if(nprint.eq.-5) then
       oprint(29) = .true.
      else
       oprint(29) = .false.
      endif
      write(iwr,4)lword
      call cpuwal(begin,ebegin)
      call headup
      nw=48
      call secget(isect(469),m10,mblkci)
      call readi(bypass,nw,mblkci,idaf)
      igam = igame
      imode = 0
      ntask = 0
 50   call timrem(tleft)
      imode=imode+1
      if(imode.gt.9)go to 16
      if(bypass(imode))go to 50
      cpu = cpulft(1)
      if(cpu.le.timlim) go to 100
      tim = timlim+0.1d0
      irest = 9
      go to 110
 100  iblk=mblkci+1
      if(ntask.ge.1) then
      if(ipoint(ntask,imode).ne.1)call caserr2(
     * 'invalid sequence of ci-steps requested')
      endif
      do 5 i=1,imode-1
  5   iblk=iblk+lensec(modew(i))
      call rdedx(param,modew(imode),iblk,idaf)
      ntask=imode
      oprint(31) = oprin(imode,1)
      oprint(32) = oprin(imode,2)
      oprint(33) = oprin(imode,3)
      if(oprint(29)) oprint(33) = .false.
      go to (70,80,90,10,11,12,13,14,15),imode
c     ----- symmetry adaption
 70   call amrdci(core(ibase),lword)
      go to 60
c     ----- integral transformation
 80   call tmrdci(core(ibase),lword)
 60   call closbf(0)
      go to 50
c     ----- table data base module
  90  call tdata
      go to 65
c     ----- table ci selection module
  10  call smrdci(core(ibase),core(ibase),lword)
  65  call closbf3
      go to 50
c      -----  ci module
 11   call tabci(core(ibase),core(ibase),lword)
      go to 65
c     ----- diagonalization module
  12  i10 = ibase
      i20 = i10 + mxconf
      i30 = i20 + mxconf
      i31 = i30 + mxcsf*(mxcsf+1)/2
      i40 = i30 + mxconf
      i50 = i40 + mxconf
      last = i50 + mxconf
      lmem = lword - 2 * mxconf
      if (.not.oprint(29)) write(iwr,115) last
      call dmrdci(core(i10),core(i20),core(i30),core(i31),
     + core(i40),core(i50),mxconf,core(i30),energy,lmem)
      go to 50
c     ----- natural orbital and density matrix module
  13  call nmrdci(core(ibase),lword)
      go to 50
c     ----- 1-e properties module
  14  call pmrdci(core(ibase),lword)
      go to 50
c     ----- transition moment module
 15   call moment(core(ibase),lword)
      go to 50
 16   cpu=cpulft(1)
      irest = 0
 110  write(iwr,17)cpu ,charwall()
      call timana(13)
      call clredx
c
c     reset core allocation
c
      call gmem_free(ibase)
c
      return
 4    format(/40x,32('*')/
     +        40x,'Conventional Table-CI Calculation'/
     +        40x,32('*')//
     +1x,'** main core available = ',i8,' words')
 115  format(/1x,
     + 'aproximate core usage in mrdci-diagonalisation:',i8)
 17   format(/1x,79('=')/
     +' end of Table-ci calculation at ',f8.2,' seconds',a10,' wall'/)
      end
      subroutine consort(jkon,n,np)
      implicit none
      integer n, jkon(n), np
c
c...  Sorts orbital labels in increasing order for MRDCIN.
c...  If jkon(i).eq.0 then we have reached end of configuration.
c...  The first np orbitals are singly occupied, 
c...  the orthers are doubly occupied.
c
      integer i, j, iswp, ilow, nelm
      nelm = 0
      do i = 1, n
        if (jkon(i).ne.0) nelm = i
      enddo
      if (np.gt.nelm) then
        call caserr2(
     +  "no. of singly occupied exceeds total no. occupied")
      endif
      do i = 1, np
        ilow = i
        do j = i+1, np
          if (jkon(j).lt.jkon(ilow)) then
            ilow = j
          endif
        enddo
        if (ilow.ne.i) then
          iswp       = jkon(i)
          jkon(i)    = jkon(ilow)
          jkon(ilow) = iswp
        endif
      enddo
      do i = np+1, nelm
        ilow = i
        do j = i+1, nelm
          if (jkon(j).lt.jkon(ilow)) then
            ilow = j
          endif
        enddo
        if (ilow.ne.i) then
          iswp       = jkon(i)
          jkon(i)    = jkon(ilow)
          jkon(ilow) = iswp
        endif
      enddo
      end
      subroutine mrdcin
      implicit REAL (a-h,o-z), integer(i-n)
      logical route,oprint,bypass
      logical iaopr,imopr,oroot,oci0,odel
      character *4 end,iop,iop44,iop444,itext,iop4
      character *8 text,ztit,zcomm
      character *4 iop1,iop11,iop2,iop66
      character *4 mode
      character *4 iop77,tagg
      character *4 ioff
      character *4 iblnk,iop88
      character *4 imos,iaos,paos,pmos,mopr
INCLUDE(common/sizes)
chvd  Every "paragraph" in common/junk/ is one record on 
chvd  section isect(469). See also assignment of modew
chvd  and wrt calls at the end of the subroutine.
      common/junk/
     * bypass(9),oprint(9,3),modew(10),
     * igame,route,isec3,ispaca,
     * ic,i7,mj(8),kj(8),isecv,icore,ick(256),izer,iaus(256),kjunk,
     * mmax,isq(11),
     * ical,nmul,nelec,ispace,nko,mxex,nprin,jkon(mxcsf*mxnshl),
     *   npkon(mxcsf),nrootx,ipt0,nprtn,lsng,lulu,mxset,
     *   ipt1,jtest(mxcsf),isym(mxroot),doff(mxcsf*mxroot),
     +   trash,tdel,
     * ispci(10),
     * pthr,pthrcc,vthrs,vthrf,cutoff,ntry,nroot,nexp,maxit,
     *   iovlp(mxroot),ifixx(mxroot),nset,nproot,nerrd,oroot,
     *   mcut,mspac,
     * itag(mxroot),isec(mxroot),jsec(mxroot),nwi,nspacn,
     * istate,ipig(mxroot),ipmos,ipaos,iaopr(11),imopr(11),
     *   jkonp(21*mxroot),ispacp,
     * iput,idx,jput,jdx,nstate,nspacm,
     * odel(mxcsf)
INCLUDE(common/files)
INCLUDE(common/direc)
INCLUDE(common/machin)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
      common/junkc/zcomm(29),text,ztit(10)
INCLUDE(common/runlab)
INCLUDE(common/work)
INCLUDE(common/discc)
INCLUDE(common/infoa)
INCLUDE(common/cjdavid)
INCLUDE(common/workc)
INCLUDE(common/limy)
      common/restri/nfils(63),lds(508),isect(508),ldsect(508)
INCLUDE(common/blksiz)
      dimension mode(18),iop1(7),iop11(6),iop2(9),iop(5)
      dimension idef(10),iop77(3),tagg(4)
      dimension iop66(14),iop4(9),iop44(6),iop444(13)
      dimension iop88(4),modei(9),moder(9)
      dimension paos(11),pmos(11)
      dimension mopr(11)
      dimension nytl(5),isw(10),nop(mxcsf)
c     dimension ndub(mxcsf)
      dimension isaf(0:5)
      character*10 charwall
      data idef/5,5,4,4,3,3,3,3,2,2/
      data mode/
     *'$ada','adap','$tra','tran','$tab','tabl','$sel','sele',
     *'$ci ','ci  ','$dia','diag','$nat','nato','$pro','prop',
     *'$mom','mome'/
      data end/'end'/
      data iop1/'rout','noro','ipri','fpri','nopr','bypa',' '/
      data iop11/'maxb','minb','main','mfil','afil','ffil'/
      data iop2/
     *'ipri','fpri','core','free','disc','dele','nopr','bypa',' '/
      data iop/'ipri','fpri','nopr','bypa',' '/
      data iop77/'cive','putq',' '/
      data tagg/'sabf','a.o.','aos',' '/
      data iop44/
     *'sing','doub','trip','quar','quin','sext'/
      data iop4/'ipri','fpri','nopr','star','rest','merg','opt4',
     * 'bypa',' '/
      data iop444/
     *'cntr','exci','symm','spin','maxc',
     *'root','sing','cize','conf','tvec','thre',
     *'coef','tria' /
      data ioff/'off'/
      data zero/0.0d0/
      data iop66/
     *'titl','tria','root','extr','maxd',
     *'over','prin','outp','accu','dthr',
     *'dvec','erro','fixu','jacd' /
      data iop88/'cive','aopr','mopr',' '/
      data mopr/
     *'s','x','y','z','xx','yy','zz','xy','xz','yz','t'/
      data iblnk/' '/
      data iaos,imos/'a.o.','m.o.'/
c     data m469/469/
      data m10/10/
c
      dumt = seccpu()
      write(iwr,7777)dumt ,charwall()
 7777 format(//1x,
     1 '*** mrd-ci pre-processor called at ',f8.2,' seconds',
     1 a10,' wall'/)
c      default paths
c
       do 90000 loop=1,6
90000  bypass(loop)=.false.
       do 90010 loop=7,9
90010  bypass(loop)=.true.
       bypass(3)   =.true.
c
      nav = lenwrd()
      do 90080 loop=1,9
90080 moder(loop)=0
      modei( 1) = 4
      modei( 2) = 534
      modei( 3) = 12
      modei( 4) = 14+(mxnshl+2)*mxcsf+mxroot
      moder( 4) = 2+mxroot*mxcsf
      modei( 5) = 10
      modei( 6) = 10+2*mxroot
      moder( 6) = 5
      modei( 7) = 2+3*mxroot
      modei( 8) = 26+22*mxroot
      modei( 9) = 6
c
      do 90020 loop=1,9
      modew(loop) = moder(loop)+ (modei(loop)-1)/nav+1
      oprint(loop,1)=.false.
      oprint(loop,2)=.false.
90020 oprint(loop,3)=.true.
c
c     reset blocking factor on sortfile to 1
c
      nsz=1
c
c === adapt defaults
      igame=1
      route=.false.
      isec3=0
c === tran4 defaults
      ic=0
      i7=0
      icore=0
      izer=0
      do 2001 loop=1,8
      mj(loop)=0
 2001 kj(loop)=0
      call setsto(256,0,ick)
      call setsto(256,0,iaus)
      isecv=0
c === table defaults
      nmax=10
c === selection defaults
      ical=0
_IF1()      nsec=80
      nshl=mxnshl
      trash=30.0d0
      tdel =10.0d0
      mxex =2
      ispace=1
      nko=0
      nmul=mul
      nrootx=1
      ipt0=0
      mxset=0
      nelec=0
      lsng=0
      lulu=0
      call vclr(doff,1,mxcsf*mxroot)
      nprin=0
      ipt1=0
      nwroot=0
      call setsto(mxroot,0,isym)
      call setsto(mxroot,0,nosec)
      call setsto(mxcsf*mxnshl,0,jkon)
      call setsto(mxcsf,0,jtest)
      call setsto(mxcsf,0,npkon)
c === diag defaults
      nroot  =0
_IF1()c     this is the correct setting, but causes problems
_IF1()c     which at present (18/3/93) cant be traced
_IF1()      ntry   =mxcsf
      ntry   =80
      nexp   =2
      nerrd   =0
      maxit  =mxcsf
      mcut   =-1
      vthrs  =0.005d0
      vthrf  =0.001d0
      pthr   =0.0d0
      pthrcc  =0.0d0
      cutoff  =10.0d0
      nproot =0
      oroot  =.false.
      oci0  =.true.
      nset   =1
      call setsto(mxroot,0,ifixx)
      iovlp(1)=0
      do 90030 loop=2,mxroot
90030 iovlp(loop)=loop
      do 555 loop=1,10
555   ztit(loop)=ztitle(loop)
c... jacobi davidson defaults (invisible switched on automatic)
c..   shift -1000 signifies dynamic shifting
      eshijd = -1000.0d0
      iprjd = 0
      maxcjd = 100
      ifjajd = 1
      threjd = 0.00001d0
      crijd = 0.01d0
      maxsjd = 500
c === =natorb= defaults
      nwi=1
      itag(1)=1
      isec(1)=0
      jsec(1)=0
c === =prop1e= defaults
      do 8999 i=1,11
      iaopr(i)=.true.
 8999 imopr(i)=.true.
      istate=1
      ipig(1)=1
      ipmos=0
      ipaos=0
      call setsto(21*mxroot,0,jkonp)
c === =moment= defaults
      iput=36
      idx =1
      jput=36
      jdx=1
      nstate=1
      if(jump.le.1) go to 9999
      call inpi(nelec)
c
9999  call input
9998  call inpa(text)
      itext=text(1:4)
      imode=locatc(mode,18,itext)
      if(imode.ne.0)go to 90040
      jrec=jrec-1
      k=locatc(ydd(101),limit2,itext)
      if(k.ne.0) go to 11111
 4061 call caserr2(
     *'unrecognised directive or faulty directive ordering')
7781  call caserr2('invalid parameters detected in table generator')
c777  write(iwr,778)
c778  format(5x,'at least two of the main configurations are identical')
c     call caserr2('identical main configurations detected')
 775  write(iwr,776)
 776  format(5x,'too many open shells in mains for dimensions')
      call caserr2('invalid number of open shells')
 773  write(iwr,774)
 774  format(5x,'orbital numbering is weird in mains')
      call caserr2('invalid orbital numbering detected')
 771  write(iwr,772)
 772  format(5x,'open shell structure in mains inconsistent with ',
     1'multiplicity')
      call caserr2('inconsistent multiplicity and open shell structure')
 769  write(iwr,770) i,nv,nz,jkon(kg),kg,jkon(lb),lb
 770  format(5x,'pauli was right or maybe permutation error',7i5)
      call caserr2('possible permutation error detected')
 751  call caserr2('excitation class not allowed')
 752  call caserr2('invalid spin multiplicity')
 753  call caserr2('invalid no. of active electrons')
 754  call caserr2('invalid no. of reference configurations')
 755  call caserr2('invalid no. of trial vector elements')
 756  call caserr2(
     *'inconsistent number of specified roots for selection')
90040 go to (
     *1000,1000,2000,2000,3000,3000,4000,4000,
     *5000,5000,6000,6000,7000,7000,9000,9000,8000,8000),imode
c
c === =adapt= input
c
 1000 call inpa4(itext)
      i=locatc(iop1,7,itext)
      if(i.ne.0) go to 1010
      jrec=jrec-1
      call inpi(isec3)
      go to 1000
 1010 go to (1020,1030,1040,1050,1070,1080,1060), i
 1020 route=.true.
      go to 1000
 1030 route=.false.
      go to 1000
 1040 oprint(1,1)=.true.
      go to 1000
 1050 oprint(1,2)=.true.
      go to 1040
 1070 oprint(1,3)=.false.
      go to 1000
 1080 bypass(1)=.true.
      go to 1000
1060  if(isec3.gt.350)call caserr2(
     *'invalid section specified for 1-electron integrals')
 490  call input
      call inpa4(itext)
      i=locatc(iop11,6,itext)
      if(i.ne.0) go to 481
      jrec=0
      go to 9998
 481  go to (483,482,484,484,485,485), i
 482  if(jump.eq.3)go to 486
 487  call caserr2('invalid syntax of maxblock or minblock')
 486  call inpa4(itext)
      i=locatc(yed,maxlfn,itext)
      if(i)488,489,488
 489  call caserr2('invalid ddname parameter')
 488  call inpi(minbl(i))
      go to 490
 483  if(jump.ne.3) go to 487
      call inpa4(itext)
      i=locatc(yed,maxlfn,itext)
      if(i)491,489,491
 491  call inpi(maxbl(i))
      go to 490
 484  call filein(n2file,n2tape)
      go to 490
 485  call filein(n1file,n1tape)
      go to 490
c
c === =tran4= input
c
 2000 call inpa4(itext)
      i=locatc(iop2,9,itext)
      if(i.ne.0)go to 2010
      jrec=jrec-1
      call inpi(isecv)
      go to 2000
 2010 go to (2020,2030,2040,2040,2050,2050,2070,2080,2060),i
 2020 oprint(2,1)=.true.
      go to 2000
 2030 oprint(2,2)=.true.
      go to 2020
 2040 ic=1
      go to 2000
 2050 i7=1
      go to 2000
 2070 oprint(2,3)=.false.
      go to 2000
 2080 bypass(2)=.true.
      go to 2000
2060  if(ic.ne.0) then
      call input
      do 8990 i=1,jump
      call inpi(mj(i))
 8990 icore=icore+mj(i)
      call mrinmo(ick,icore,num)
      endif
      if(i7.ne.0) then
      call input
      do 8991 i=1,jump
      call inpi(kj(i))
 8991 izer=izer+kj(i)
      call mrinmo(iaus,izer,num)
      endif
      go to 9999
c
c === =table= data
c
 3000 bypass(3)=.false.
      if(jump.le.1)go to 3065
3010  call inpa4(itext)
      i=locatc(iop,5,itext)
      if(i.eq.0)go to 3020
      go to (3030,3040,3050,3060,3065),i
3030  oprint(3,1)=.true.
      go to 3010
3040  oprint(3,2)=.true.
      go to 3030
3050  oprint(3,3)=.false.
      go to 3010
3060  bypass(3)=.true.
      go to 3010
3020  jrec=jrec-1
      if(jump.gt.3)go to 3035
3065  mmax=7
      do 3066 i=1,mmax
3066  isq(i)=idef(i)
      go to 9999
3035  call inpi(mmax)
      if(mmax.le.0.or.mmax.gt.nmax)go to 7781
      do 3068 i=1,mmax
      call inpi(isq(i))
      if(isq(i).le.0.or.isq(i).gt.5)go to 7781
 3068 continue
      go to 9999
c
c === =tabci= data
c
 5000 call inpa4(itext)
      i=locatc(iop,5,itext)
      if(i.ne.0) go to 5010
      go to 5000
 5010 go to (5020,5030,5040,5050,9999),i
 5020 oprint(5,1)=.true.
      go to 5000
 5030 oprint(5,2)=.true.
      go to 5020
 5040 oprint(5,3)=.false.
      go to 5000
 5050 bypass(5)=.true.
      go to 5000
c
c === =diag= data
c
 6000 call inpa4(itext)
      i=locatc(iop,5,itext)
      if(i.ne.0)go to 6001
      go to 6000
 6001 go to (6002,6003,6004,6005,60000),i
 6002 oprint(6,1)=.true.
      go to 6000
 6003 oprint(6,2)=.true.
      go to 6002
 6004 oprint(6,3)=.false.
      go to 6000
 6005 bypass(6)=.true.
      go to 6000
60000 call input
      call inpa4(itext)
      i=locatc(iop66,14,itext)
      if(i.ne.0)go to 6110
      jrec=0
      go to 9998
 6110 go to (6015,6010,6020,6030,6040,6050,
     *6060,6060,6070,6070,6080,6090,6100,6120),i
c
c     ----- title
c
6015  call input
      k=1
      do 9068 i=1,10
      ztit(i)=char1(k:k+7)
 9068 k=k+8
      go to 60000
c
c    ----- trial
c
 6010 call inpi(ntry)
      go to 60000
c
c     ----- roots
c
 6020 call inpa4(itext)
      if(itext.ne.'all') then
       jrec=jrec-1
       call inpi(nroot)
      else
       oroot=.true.
       nexp = 0
       if(jump.ge.3) then
        call inpa4(itext)
        if(itext.eq.'cuto') then
         call inpf(cutoff)
         mcut = 1
        else
         jrec=jrec-1
         call inpi(mcut)
        endif
       endif
      endif
      go to 60000
c
c     ----- extrap
c
 6030 call inpa4(itext)
      if(itext.ne.ioff)go to 6031
      nexp=0
      go to 60000
 6031 jrec=jrec-1
      call inpi(nexp)
      go to 60000
c
c     ----- maxd
c
 6040 call inpi(maxit)
      go to 60000
c
c     ----- overlap
c
 6050 do 6051 i=1,mxroot
 6051 call inpi(iovlp(i))
      go to 60000
c
c     ----- print/output
c
 6060 call inpf(pthr)
      call inpf(pthrcc)
      call inpi(nproot)
      go to 60000
c
c     ----- accuracy/dthresh
c
 6070 call inpf(vthrs)
      call inpf(vthrf)
      if(vthrs.le.0.0d0) vthrs = 0.005d0
      if(vthrf.le.0.0d0) vthrf = vthrs/5.0d0
      go to 60000
c
c     ----- dvec
c
 6080 call inpi(nset)
      go to 60000
c
c     ----- error
c
 6090 call inpi(nerrd)
      go to 60000
c
c    ----- fixup
c
 6100 do 6101 i=1,mxroot
 6101 call inpi(ifixx(i))
      go to 60000
c
c    ----- jacdav 'off' 'on' 'shift' shift 'tresh' tresh
c    -----        'maxcyc' maxcyc 'print'
c    -----        'sele' maxsjd 'crit' crijd
c
6120  call inpa4(itext)
      if (itext.eq.'off') ifjajd = 0
      if (itext.eq.'on') ifjajd = 1
      if (itext.eq.'prin') then
          iprjd = iprjd + 10
      else if (itext.eq.'shif') then
          call inpa(text)
          if (text.eq.'dynamic') then
             eshijd = -1000.0d0
          else
             jrec = jrec - 1
             call inpf(eshijd)
          end if
      else if (itext.eq.'tres') then
          call inpf(threjd)
      else if (itext.eq.'crit') then
          call inpf(crijd)
      else if (itext.eq.'sele') then
          call inpi(maxsjd)
      else if (itext.eq.'maxc') then
          call inpi(maxcjd)
      else if (itext.eq.' ') then
          call outrec
          go to 60000
      end if
      go to 6120
c
c === =natorb= data
c
 7000 bypass(7)=.false.
      if(jump.eq.1) go to 7040
 7010 call inpa4(itext)
      i=locatc(iop,5,itext)
      go to (7020,7030,7025,7035,7040),i
 7020 oprint(7,1)=.true.
      go to 7010
 7030 oprint(7,2)=.true.
      go to 7020
 7025 oprint(7,3)=.false.
      go to 7010
 7035 bypass(7)=.true.
      go to 7010
c
7040  call input
      call inpa4(itext)
      i=locatc(iop77,3,itext)
      if(i.eq.0)go to 7060
      go to (7070 ,7080,7060 ),i
c
7070  nwi=jump-1
      if(nwi.le.0.or.nwi.gt.mxroot)call caserr2(
     *'invalid number of orbital sets requested')
      do 7075 i=1,nwi
      isec(i)=0
      jsec(i)=0
      call inpi(itag(i))
      if(itag(i).le.0.or.itag(i).gt.1000)call caserr2(
     *'invalid orbital set requested')
 7075 continue
      go to 7040
c
 7080 call inpa4(itext)
      ktag=locatc(tagg,4,itext)
      if(ktag.eq.0)call caserr2('invalid basis option requested')
      go to( 7081, 7084, 7084,7040 ),ktag
 7081 do 7082 i=1,nwi
      call inpi(isec(i))
      if(isec(i).gt.350)go to 7083
 7082 continue
      go to 7080
 7083 call caserr2('invalid dumpfile section specified for nos')
 7084 do 7085 i=1,nwi
      call inpi(jsec(i))
      if(jsec(i).gt.350)go to 7083
 7085 continue
c     store copy of NO sections in /limy/ for analg
      nwroot = nwi 
      do i = 1, nwroot
        nosec (i) = jsec(i)
      enddo
      go to 7080
7060  jrec=0
      go to 9998
c
c === =prop1e= data
c
 9000 bypass(8)=.false.
      if(jump.eq.1) go to 9010
 9020 call inpa4(itext)
      i=locatc(iop,5,itext)
      if(i.eq.0)go to 9010
      go to (9030,9040,9035,9045,9010),i
 9030 oprint(8,1)=.true.
      go to 9020
 9040 oprint(8,2)=.true.
      go to 9030
 9035 oprint(8,3)=.false.
      go to 9020
 9045 bypass(8)=.true.
c
9010  call input
      call inpa4(itext)
      i=locatc(iop88,4,itext)
      if(i.eq.0)go to 9050
      go to (9060,9070,9080,9050),i
 9060 istate=jump-1
      if(istate.le.0.or.istate.gt.mxroot)call caserr2(
     *'invalid number of ci vectors requested for analysis')
      do 9065 i=1,istate
      call inpi(ipig(i))
      if(ipig(i).le.0)call caserr2(
     *'invalid ci vector specified for analysis')
 9065 continue
      go to 9010
c ..  process ao list
c
 9070 call inpa4(itext)
      if(itext.eq.iblnk)go to 9010
      ipaos=ipaos+1
      paos(ipaos)=itext
      go to  9070
c ..  process mo list
c
 9080 call inpa4(itext)
      if(itext.eq.iblnk)go to 9010
      ipmos=ipmos+1
      pmos(ipmos)=itext
      go to 9080
 9050 jrec=0
      if(ipaos.eq.0)go to 9004
      do 9094 i=1,ipaos
      j=locatc(mopr,11,paos(i))
      if(j.ne.0)iaopr(j)=.false.
 9094 continue
 9004 if(ipmos.eq.0)go to 9090
      do 9093 i=1,ipmos
      j=locatc(mopr,11,pmos(i))
      if(j.ne.0)imopr(j)=.false.
 9093 continue
c
 9090 jrec=0
      ij=1
      do 9091 i=1,istate
      if(i.gt.1)call input
      call inpi(jkonp(ij))
      do 9092 j=1,20
9092  call inpi(jkonp(ij+j))
9091  ij=ij+21
      go to 9999
c
c === =moment= data
c
 8000 bypass(9)=.false.
 8005 call inpa4(itext)
      i=locatc(iop,5,itext)
      if(i.eq.0)go to 8010
      go to (8020,8030,8025,8035,8010),i
 8020 oprint(9,1)=.true.
      go to 8005
 8030 oprint(9,2)=.true.
      go to 8020
 8025  oprint(9,3)=.false.
       go to 8005
 8035  bypass(9)=.true.
       go to 8005
8010  call input
      call inpi(iput)
      call inpi(idx)
      call inpi(jput)
      call inpi(jdx)
      call inpi(nstate)
      if(iput.le.0.or.jput.le.0)call caserr2(
     *'invalid fortran stream specified for ci vector')
      go to 9999
c
c === =selection= input
c
 4000 call inpa4(itext)
      i=locatc(iop4,9,itext)
      go to (4010,4020,4050,4030,4030,4030,4030,4060,4040),i
 4010 oprint(4,1)=.true.
      go to 4000
 4020 oprint(4,2)=.true.
      go to 4010
 4050 oprint(4,3)=.false.
      go to 4000
 4030 ical=i-2
      go to 4000
 4060 bypass(4)=.true.
      go to 4000
 4040 call input
 4041 call inpa4(itext)
      i=locatc(iop444,13,itext)
      if(i.ne.0)go to 4045
      jrec=0
      go to 9998
 4045 go to (4074,4071,4072,4073,4075,
     *       4076,4078,4079,4081,4065,4069,4065,4065),i
c === cntrl
 4074 call inpi(nelec)
      go to 4040
c === exci
 4071 call inpi(mxex)
      go to 4040
c === symmetry
 4072 call inpi(ispace)
      go to 4040
c === spin
 4073 call inpa4(itext)
      nmul=locatc(iop44,6,itext)
      if(nmul.gt.0)go to 4040
      jrec=jrec-1
      call inpi(nmul)
      go to 4040
c === maxcon
 4075 call inpi(mxset)
      go to 4040
c === roots
 4076 call inpi(nrootx)
      if(jump.eq.2)go to 4040
      j=jump-2
      if(j.ne.nrootx)go to 756
      do 4077 i=1,j
 4077 call inpi(isym(i))
      ipt0=1
      go to 4040
c === singles
 4078 call inpi(lsng)
      go to 4040
c === cizero
 4079 call inpi(lulu)
      if(nko.eq.0) go to 4061
      if(lulu.eq.nko) go to 4040
      oci0=.false.
      call input
      do 4080 loop=1,lulu
 4080 call inpi(jtest(loop))
      go to 4040
c === conf
 4081 im=0
 4082 call input
      call inpa4(itext)
      loop=locatc(iop444,13,itext)
      jrec=0
      if(loop.ne.0) go to 4041
      k=locatc(mode,18,itext)
      if(k.ne.0)then
      imode=k
      go to 90040
      endif
      k=locatc(ydd(101),limit2,itext)
      if(k.ne.0) go to 11111
      nko=nko+1
      call inpi(npkon(nko))
      nt=im+1
      im=im+nshl
      do 4083 j=nt,im
      call inpi(jkon(j))
      if(jkon(j).le.0) go to 4082
 4083 continue
      go to 4082
c === tvec
 4065 ipt0=-1
      nsd=0
 4066 call input
      do 4067 i=1,jump
      call inpa4(itext)
      if(itext.eq.end) go to 4068
      jrec=jrec-1
      nsd=nsd+1
 4067 call inpf(doff(nsd))
      go to 4066
 4068 if(nsd.le.0.or.nsd.gt.mxcsf*mxroot) go to 755
      go to 4040
c === thresh
 4069 call inpf(trash)
      call inpf(tdel)
      go to 4040
11111 if(nelec.le.0) nelec = ne -icore*2
      if(bypass(1))go to 10000
      if(isec3.eq.0)isec3=ions2
      write(iwr,3)
3     format(/1x,'symmetry adaption'/1x,
     *           '*****************')
      call filchk(n2file,n2blk,n2last,n2tape,1)
      if(route)go to 104
      write(iwr,105)
 105  format(/' *** no sabf routing specified'/)
      go to 10000
 104  write(iwr,33)ions2
 33   format(/' *** sabf routing specified'//
     * ' one-electron integrals to section ',i3,' of dumpfile'/)
      call filchk(n1file,n1blk,n1last,n1tape,7)
      if(ions2.eq.ionsec)write(iwr,34)
 34   format(/
     *' **** note : original 1-electron integrals to be overwritten'
     */)
10000 if(bypass(2))go to 10100
      if(isecv.gt.350)call caserr2(
     *'invalid dumpfile section nominated for vectors')
      write(iwr,4)
4     format(/1x,'integral transformation'/1x,
     *           '***********************')
      if(isecv.gt.0) write(iwr,44444)isecv
44444 format(/
     *1x,'eigen vectors to be restored from section',i4)
      if(oprint(2,2))write(iwr,8084)
 8084 format(/
     *' integral print option specified')
      if(ic.ne.0) then
      write(iwr,8082)
 8082 format(/
     *' *** frozen orbitals specified ')
      endif
      if (i7.ne.0) then
      write(iwr,8083)
 8083 format(/
     *' *** discarded orbitals specified')
      endif
10100 if(bypass(3)) go to 10200
      write(iwr,31000)
31000 format(/1x,'table generation'/1x,
     *           '****************'/)
      write (iwr,7800) mmax,(isq(i),i=1,mmax)
 7800 format(2x,40i3)
10200 if(bypass(4)) go to 10300
      write(iwr,30000)
30000 format(/1x,'configuration selection'/1x,
     *           '***********************')
      if(mxex.gt.4.or.mxex.lt.0) go to 751
      if(nmul.lt.1.or.nmul.ge.5) then
       write(iwr,30001)
30001  format(/
     +     20x,'*******************************************'/
     +     20x,'*** Table-ci module can only handle up to *'/
     +     20x,'*** quartet spin states                   *'/
     +     20x,'*******************************************'/)
       go to 752
      endif
      if(nelec.lt.2.or.nelec.gt.40)go to 753
      if(nko.gt.mxcsf) go to 754
      nbox=num
      m=nelec
      nops=5
      iswh=5
      nnx=(nelec+nmul-3)/2
      do 87 loop=1,iswh
      nnx=nnx+1
 87   nytl(loop)=nnx
      do 88 loop=1,10
 88   isw(loop)=0
      if(nmul.gt.1) isw(nmul-1)=1
      isw(nmul+1) = 2
      isw(nmul+3) = 3
       if (mxex.le.0) mxex=2
      if(oprint(4,1))nprin=1
      if(oprint(4,2))nprin=2
      im=0
      do loop = 1, mxcsf
       odel(loop) = .false.
      enddo
c
c     first check for duplicate configs and remove
c
      do i=1,nko
      nt=im+1
      im=im+nshl
      np=npkon(i)
      if (np.gt.nops) go to 775
c...  sort orbital labels in configuration
      nyt=1
      if(np.ne.0) then
       nyt=isw(np)
      endif
      nyt=nytl(nyt)
      if(i.eq.1) go to 5503
      i1=i-1
      mx=-nshl
      do 5504 j=1,i1
      if (odel(j)) go to 5504
      mx=mx+nshl
      if(nop(j).ne.np) go to 5504
      nv=mx
      la=nt-1
      do k=1,nyt
       la=la+1
       nv=nv+1
       if(jkon(la).ne.jkon(nv)) go to 5504
      enddo
c
c     this main configuration has already appeared .. print
c     warning and reset nko, npkon and jkon
c
      odel(i) = .true.
      write(iwr,778)
 778  format(/10x,
     +  '**             WARNING                        **'/10x,
     +  '* two of the main configurations are identical *'/10x,
     +  '* duplicate removed and number of mains reset  *'/)
      write(iwr,777) nop(i), (jkon(nt-1+loop),loop=1,nyt)
 777  format(10x,'**',i5,2x,30i3)
5504  continue
5503  continue
      nop(i)=np
      enddo
c
      imf = 0
      im = 0
      nkof = 0
      do i = 1, nko
      nt = im + 1
      im = im + nshl
      if(.not.odel(i)) then
       nkof = nkof + 1
       ntf = imf + 1
       imf = imf + nshl
       npkon(nkof) = npkon(i)
       do loop = 1, nshl
        jkon(ntf+loop-1) = jkon(nt+loop-1)
       enddo
      endif
      enddo
c
      nko = nkof
      im = 0
c
      do 2 i=1,nko
      nt=im+1
      im=im+nshl
      np=npkon(i)
c...  sort orbital labels in configuration
      call consort(jkon(nt),nshl,np)
      nyt=1
      if(np.eq.0) go to  94
      nyt=isw(np)
 94   nyt=nytl(nyt)
      if(i.eq.1) go to 503
      i1=i-1
      mx=-nshl
      do 504 j=1,i1
      mx=mx+nshl
      if(nop(j).ne.np) go to 504
      nv=mx
      la=nt-1
      do 505 k=1,nyt
      la=la+1
      nv=nv+1
      if(jkon(la).ne.jkon(nv)) go to 504
 505  continue
c
      call caserr2('** identical mains +++ STILL')
 504  continue

 503  nae=nmul+np
      if(nae-2*(nae/2).eq.0) go to 771
      if(np.gt.m) go to 771
      if(np.gt.nmul+3) go to 771
      nop(i)=np
      if(np.lt.2) go to 500
      nz=jkon(nt)
      if(nz.lt.1.or.nz.gt.nbox) go to 773
      do j=2,np
       nt=nt+1
       nv=jkon(nt)
       if(nv.le.nz) go to 769
       if(nv.gt.nbox) go to 773
       nz=nv
      enddo
      if(np.eq.m) go to 2
518   mx=np+im-nshl+1
      nv=jkon(mx)
      if(nv.lt.1.or.nv.gt.nbox) go to 773
      lb=im-nshl
      do 506 j=1,np
      lb=lb+1
      if(jkon(lb)-nv) 506,769,507
506   continue
507   jm=np+2
      if(jm.gt.nyt) go to 2
      kp=mx
      do 508 j=jm,nyt
      kg=mx
      mx=mx+1
      nv=jkon(mx)
      if(nv.lt.1.or.nv.gt.nbox) go to 773
      do 509 k=kp,kg
      nz=jkon(k)
      if(nv.le.nz) go to 769
 509   continue
      kg=im-nshl
      do 510 k=1,np
      kg=kg+1
      if(jkon(kg)-nv) 510,769,508
 510   continue
 508   continue
       go to 2
 500   if(np.eq.0) go to 511
       nv=jkon(nt)
       if(nv.lt.1.or.nv.gt.nbox) go to 773
       go to 518
 511   nz=jkon(nt)
       if(nz.lt.1.or.nz.gt.nbox) go to 773
       if(nyt.eq.1) go to 2
       kp=nt
       do 512 j=2,nyt
       kg=nt
       nt=nt+1
       nv=jkon(nt)
       if(nv.lt.1.or.nv.gt.nbox) go to 773
       do 512 k=kp,kg
       nz=jkon(k)
       if(nv.le.nz) go to 769
 512   continue
   2   continue
c
c     check requested size of zero order space
c
      do 551, j=(nmul-1),nops,2
551   isaf(j)=numsaf(nmul,j)
      k=0
      do 552, j=1,nko
552   k= k + isaf(nop(j))
      write(iwr,553) nko,k
553   format(/' The set of',i5,' main configurations leads to',
     + i5,' spin adapted functions.')
      if (k.gt.mxcsf) 
     + call caserr2('too many SAFs from specified mains')
c...   for jacobi-davidson
       nkojd = nko
c
      if (ical.gt.1) go to 600
      if(mxset.le.0) mxset=mxconf/1000
      if (mxex.ne.1) then
       lulu=nko
       go to 1501
      else
       if (oci0) then
        lulu=nko
        do 1510 loop=1,lulu
1510    jtest(loop)=loop
       endif
       if (lulu.eq.nko) go to 1501
       do 20010 i=1,lulu
       if (jtest(i).le.0.or.jtest(i).gt.nko) call caserr2(
     *  'invalid reference function specified')
20010  continue
       ix=0
       do 1502 i=1,lulu
       jt=jtest(i)
       if (jt.ne.i) then
        jx=(jt-1)*nshl
        do 1504 j=1,nshl
        jx=jx+1
        ix=ix+1
 1504   jkon(ix)=jkon(jx)
        go to 1502
       endif
       ix=ix+nshl
 1502  continue
       endif
 1501 i=mxset*1000
      write(iwr,850)lulu,nrootx,nmul,ispace,i
 850  format(/
     *' no. of reference configurations to be'/
     *' used in zero order secular problem   ',i3/
     *' no. of roots to be treated           ',i3/
     *' state spin multiplicity              ',i3/
     *' state spatial symmetry               ',i3/
     *' maximum no. of configurations to be included',i7/)
      if(lsng.eq.0)write(iwr,3070)
 3070 format(/
     *' no automatic selection of singly excited configurations')
      if(lsng.ne.0)write(iwr,3071)lsng
 3071 format(/
     *' include all singly excited configurations with'/
     *' respect to root function no. ',i3)
      if(nprin.eq.0)write(iwr,3072)
 3072 format(/' default print specified')
      if(nprin.eq.1)write(iwr,3073)
 3073 format(/' print all test species selected')
      if(nprin.eq.2)write(iwr,3074)
 3074 format(/' print all test species')
      write(iwr,3075)
 3075 format(/' *** root certifying input specification : ')
      if(iabs(ipt0).gt.1)call caserr2(
     *'invalid root specification option')
      if(ipt0.eq.0)write(iwr,3076)nrootx
 3076 format(/20x,'lowest',i2,' roots to be considered')
      if(ipt0.eq.1)write(iwr,3077)
 3077 format(/20x,'roots to be user nominated')
      if(ipt0.eq.-1)write(iwr,3078)
 3078 format(/20x,'trial eigenvectors to be user specified')
      if(ipt1.gt.0)write(iwr,3079)
 3079 format(///
     *' overlap test between input eigenvectors and'/
     *' zero order counterparts requested')
      if(mxex.ne.1.or.lulu.ne.nko)go to 3080
      write(iwr,3081)
 3081 format(//
     *' following reference configurations to be used for'/
     *' zero order secular problem :')
      write(iwr,3082)(jtest(i),i=1,lulu)
 3082 format(/40x,20i4)
 3080  if(ipt0) 680, 600,681
 680  write(iwr,3083)
 3083 format(//
     *' trial input eigenvectors provided'/)
      go to 600
681   do 20015 i=1,nrootx
      if (isym(i).lt.1.or.isym(i).gt.mxcsf) call caserr2(
     *'invalid root specified for selection')
20015 continue
      write (iwr,3084) (isym(i),i=1,nrootx)
3084  format(/' input specified roots for use in selection :
     1 ',3x,6i4)
 600  write (iwr,9300) trash,tdel
 9300 format(//' *** threshold specified ***'//
     *' minimal selection threshold ',f7.2,' microhartree'//
     *' threshold increment for use in selection ',f7.2,
     *' microhartree'/)
10300 if(bypass(5))go to 10400
      write(iwr,32000)
32000 format(/1x,'ci hamiltonian builder'/1x,
     *           '**********************')
10400 if(bypass(6)) go to 10500
      write(iwr,33000)
33000 format(/1x,'davidson diagonalisation'/1x,
     *           '************************')
      if(ntry.le.0.or.ntry.gt.mxcsf)call caserr2(
     *'invalid zero order space requested (enlarge mxcsf if necessary)')
      if(nroot.lt.0.or.nroot.gt.mxroot)call caserr2(
     *'invalid number of ci roots requested')
      if(nexp.lt.0.or.nexp.gt.6)call caserr2(
     *'invalid number of extrapolation passes specified')
      if(maxit.le.0.or.maxit.gt.mxcsf)maxit=mxcsf
      if(pthr.eq.zero)pthr=0.05d0
      if(pthrcc.eq.zero)pthrcc=0.002d0
10500 if(bypass(7)) go to 10600
      write(iwr,7090)nwi,(itag(i),i=1,nwi)
7090  format(/1x,'natural orbital analysis'/1x,
     *           '************************'//
     *' *** analysis requested for',i3,
     *' ci vectors'//5x,
     *'with following locations on the ci vector file (ft36)'
     *,20i3)
      if(oprint(7,2))
     *write(iwr,7091)
 7091 format(/
     *' print of density matrix and n.o.s in mo basis requested'/)
      do 7092  i=1,nwi
      if(isec(i).gt.0)write(iwr,7093)tagg(1),i,isec(i)
      if(jsec(i).gt.0)write(iwr,7093)tagg(2),i,jsec(i)
 7092 continue
 7093 format(/
     *' ** route n.o.s ( ',a4,' basis) for state',i3,
     *' to section',i4,' of dumpfile')
10600 if(bypass(8)) go to 10700
      write(iwr,34000)
34000 format(/1x,'molecular properties'/1x,
     *           '********************')
      if(oprint(8,2))write(iwr,9100)
 9100 format(
     *' print out of basis functions requested'/)
      if(ipaos.ne.0)go to 9024
      write(iwr,9005)iaos
 9005 format(
     *' no printing of integrals in ',a4,' basis required')
      go to 9006
 9024 write(iwr,9007)iaos
 9007 format(' print following integrals in ',a4,' basis : ')
      do 9008 i=1,11
      if(.not.iaopr(i))
     *write(iwr,9025)mopr(j)
 9025 format(/10x,a2,' - matrix')
 9008 continue
c
c    mo integral print specification
c
 9006 if(ipmos.ne.0)go to 9011
      write(iwr,9005)imos
      go to 9012
 9011 do 9013 i=1,11
      if(.not.imopr(i))
     *write(iwr,9025)mopr(j)
 9013 continue
 9012 continue
10700 if(bypass(9)) go to 10800
      write(iwr,35000)
35000 format(/1x,'transition moment analysis'/1x,
     *           '**************************')
10800 len=1
      do 10810 loop=1,9
10810 len=len+lensec(modew(loop))
      call secput(isect(469),m10,len,ibl169)
      m48=48/nav
      call wrt3i(bypass,m48*nav,ibl169,idaf)
c
      call wrt3is(igame ,modew(1)*nav,idaf)
      call wrt3is(ic    ,modew(2)*nav,idaf)
      call wrt3is(mmax  ,modew(3)*nav,idaf)
      call wrt3is(ical  ,modew(4)*nav,idaf)
      call wrt3is(ispci ,modew(5)*nav,idaf)
      call wrt3s(pthr  ,modew(6),idaf)
      call wrt3is(itag  ,modew(7)*nav,idaf)
      call wrt3is(istate,modew(8)*nav,idaf)
      call wrt3is(iput  ,modew(9)*nav,idaf)
c
      call revind
      write(iwr,7776)
7776  format(/1x,'*** mrd-ci data input complete'/)
      return
      end
      subroutine mrinmo(label,numb,nbasis)
      implicit REAL (a-h,o-z),integer (i-n)
      character *4 space,to,test
INCLUDE(common/work)
      dimension label(*)
      data space,to/' ','to'/
      nsd=0
 1    if(nsd.ge.numb)go to 2
      call input
 3    call inpa4(test)
      if(test.eq.space)go to 1
      jrec=jrec-1
      call inpi(k)
      call inpa4(test)
      if(test.ne.to)go to 4
      call inpi(l)
      if(l.ge.k)go to 5
 10   call caserr2(
     *'invalid integer and/or sequence of integers')
 4    jrec=jrec-1
      l=k
 5    if(k.lt.1.or.l.gt.nbasis)go to 10
      do 6 j=k,l
      nsd=nsd+1
 6    label(nsd)=j
      go to 3
 2    if(nsd.ne.numb)go to 10
      return
      end
      subroutine multi(q)
      implicit REAL  (a-h,o-z)
      character *24 text
INCLUDE(common/sizes)
c
INCLUDE(common/iofile)
      common/scfopt/maxit(4),addi(2),icoupl(4),dmpc(2),en,etot,ehf
INCLUDE(common/timez)
INCLUDE(common/multic)
INCLUDE(common/jobopt)
INCLUDE(common/restar)
      common/linkmc/irestm(11),ntimes
INCLUDE(common/cigrad)
INCLUDE(common/syminf)
INCLUDE(common/harmon)
INCLUDE(common/mapper)
INCLUDE(common/prints)
c
      dimension q(*)
      dimension text(7)
      data text/
     * 'input processor','formula tape generator',
     * 'redundancy check','integral pre-sort',
     * 'wavefunction calculation','wavefunction analysis',
     * 'MC-gradient interface'/
c
c     set print requirements
c
      if(nprint.eq.-5) then
       mcprin = .false.
      else
       mcprin = .true.
      endif
c
c     allocate all available memory
c
      ibase = igmem_alloc_all(lword)
c
      idumf = inicor(lword)
c
      if(ntimes.gt.0)call mczero(.true.)
      ntimes=ntimes+1
c
      icorx = icorrm()
      if(mcprin)write(iwr,200)icorx
 200  format(//40x,17('*')/
     * 40x,'mcscf calculation'/ 40x,17('*')//
     *     ' ** core available =',i8,' words')
c
_IF(parallel)
      call closbf(0)
      call setbfa(-1)
_ENDIF
c
      loop=0
 300  loop=loop+1
c
      if (loop.gt.6.and.nbasao.ne.newbas1) then
c
c...  transform back to cartesian basis
c...  this is done after anal and before mcgrad !!!!
c
         call expharm(flop,'ctrans',flop)
c...     orbitals
         call rdedx (q(ibase),nblkq,iblkq,num3)
         call expharm(q(ibase),'vectors',ilifq)
         call wrt3 (q(ibase),newbas1*newbas1,iblkq,num3)
c...     natural orbitals
         if (iblkq.ne.iblkn) then
            call rdedx (q(ibase),nblkq,iblkn,num3)
            call expharm(q(ibase),'vectors',ilifq)
            call wrt3 (q(ibase),newbas1*newbas1,iblkn,num3)
         end if
         call mcharm
         call dmpini
      end if
      if (loop.eq.7.and.(.not.oprint(25).and.mcprin)) 
     1    call mcprorb(q(ibase))
c
      iretrn=0
      go to (410,420,430,440,450,460,500,470),loop
410   dumt = seccpu()
      if (mcprin) write(iwr,310) text(loop),dumt
310   format(/1x,79('=')/
     *' *'/' ** mcscf *** ',a24,' entered  at time',f9.2/' *')
      call mcstar (q(ibase),q(ibase))
      go to 510
c
 420  if (iffmtp.eq.1) go to 300
      if (mcprin) then
       dumt = seccpu()
       write (iwr,310) text(loop), dumt
      endif
      call fmtp  (q(ibase),iwr)
      go to 510
c
 430  if (mcprin) then
       dumt = seccpu()
       write (iwr,310) text(loop), dumt
      endif
      call redun(q(ibase),q(ibase),iwr)
      go to 510
c
 440  if (ifsort.eq.1)  go to 300
      if (mcprin) then
       dumt = seccpu()
       write (iwr,310) text(loop), dumt
      endif
_IF(mp2_parallel,charmm,masscf)
      call caserr2('problem in multi - no sort linked in')
_ELSE
      call sort  (q(ibase),q(ibase),iwr)
_ENDIF
      go to 510
c
 450  if (ifwvfn.eq.1) go to 300
      dumt = seccpu()
      write (iwr,310) text(loop), dumt
      call wvfn  (q(ibase),q(ibase),iwr,ipu)
      go to 510
c
 460  if (ifanal.eq.1) go to 300
      if (mcprin) then
        dumt = seccpu()
        write (iwr,310) text(loop), dumt
      endif
      call mcanal(q(ibase),q(ibase),iwr,ipu)
      go to 510
c
 500  if (.not.mcgr.or.irest.eq.3) go to 300
      if (mcprin) then
       dumt = seccpu()
       write (iwr,310) text(loop), dumt
      endif
      call mcgrad(q(ibase),q(ibase))
c
 510  if (idump.eq.1) call mcdump
      if (iretrn.eq.0) go to 300
      write(iwr,320) iretrn,text(loop)
320   format(1x,'** mcscf ***  return code of',i4,' from ',a24)
      call mcstop
_IF(parallel)
      call pg_err(500)
_ELSE
      if (iretrn.eq.1) stop 1
      if (iretrn.eq.2) stop 2
      stop 16
_ENDIF
470   call mcstop
      if(irest.le.0)go to 100
      tim=timlim+0.1d0
      etot=0.0d0
      en=potnuc
      ehf=-en
      go to 150
100   en=potnuc
      ehf=enext - potnuc
      etot=enext
c
150   continue
c
c     reset core allocation
c
      call gmem_free(ibase)
c
c
      return
      end
c ******************************************************
c ******************************************************
c             =   mcdrive     =
c ******************************************************
c ******************************************************
      subroutine multin(q)
      implicit REAL  (a-h,o-z)
      character *4 test
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/multic)
      logical ono
INCLUDE(common/work)
      common/linkmc/irestm,ivect,iorbit,iblrst,numrst,
     +              numspp(6),ntimes
INCLUDE(common/files)
      dimension q(*)
      data ono/.false./
c
c     allocate all available memory
c
      ibase = igmem_alloc_all(lword)
c
      idumf = inicor(lword)
      ntimes=0
c
c   default units and initial blocks
c
      numft=n9tape(1)
      iblkft=n9blk(1)
      numa=n1tape(1)
      iblka=n1blk(1)
      num2=n13tap(1)
      iblk2=n13bl(1)
      num4=n4tape(1)
      iblk4=n4blk(1)
      num6=n6tape(1)
      iblk6=n6blk(1)
      numscr=n12tap(1)
      iblk8=n12bl(1)
      num3=idaf
      numrst=idaf
      iblk3=ibl3d
      iblrst=ibl3d
c
      call mczero(ono)
      call inpa4(test)
      if(test.eq.'rest')go to 102
      irestm=0
      jrec=jrec-1
      go to 103
 102  irestm=1
 103  call mcdata(q(ibase),q(ibase))
c
c     reset core allocation
c
      call gmem_free(ibase)
c
      return
      end
      function numsaf(m,n)
c  calculation of number of SAF for n electrons and 
c  multiplicity m
c  formula used from R.Pauncz: Spin Eigenfunctions, 
c  Plenum, New York 1979,
      implicit REAL (a-h,o-z), integer(i-n)
      id=(n-m+1)/2
      numsaf=ibynom(n,id)-ibynom(n,id-1)
      return
      end
      subroutine restr(q,isecrs,iblrst,numrst,iagues)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/multic)
INCLUDE(common/jobopt)
INCLUDE(common/discc)
INCLUDE(common/work)
INCLUDE(common/machin)
      common/restri/nfils(63),lds(508),isect(508),ldsect(508)
      dimension q(*)
      call inpf(test1)
      itest=test1
      if (itest.eq.0) itest=isect(472)
      numrst=num3
      iblrst=iblk3
      if (jrec.lt.jump) call inpdd(numrst,iblrst)
      call revind
      call secini (iblrst,numrst)
      call secget (itest,172,ivect)
      call rdedx(radius,mach(18),ivect,numrst)
      iguess=nstate
      isecrs=isec
       write(iwr,20) itest,iblrst,yed(numrst)
20    format(/' job information and ci vector restored from section',i4,
     1  ' of dumpfile at block',i4,' on ',a4)
      iagues=icorr(nci*nstate)
      call cget(q(iagues),nstate)
      iguess=nstate
      return
      end
      subroutine inpdd(num,iblk)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      character*8 test
      character *4 ispace,itest
      common /disc  / isel,iselr,iselw,irep,ichek,ipos(maxlfn)
INCLUDE(common/discc)
      data ispace/'    '/
      call inpa(test)
      itest(1:4)=test(1:4)
      do 10 isel=1,maxlfn
      if (yed(isel).eq.itest) goto 20
10    continue
      isel=0
      if (itest.ne.ispace) call caserr2('invalid stream name')
20    num=isel
      call inpi(iblk)
      if(iblk.le.0.or.iblk.gt.99999)iblk=1
      return
      end
_IF(mrdci)
      subroutine mrdcin2
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
INCLUDE(common/work)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/restrj)
c
c rwah mrdci common
c
INCLUDE(common/newmrd_sort)
INCLUDE(common/mrdcid)
INCLUDE(common/machin)
INCLUDE(common/direc)
INCLUDE(common/limy)
INCLUDE(common/fpinfo)
INCLUDE(common/natorb)
c
INCLUDE(common/cepa_mrd1)
INCLUDE(common/cepa_mrd2)
c
      parameter (maxref = 256)
c
      parameter (maxroot=50)
      parameter (maxshl=50)
c
      REAL edavit,cdavit,extrapit,eigvalr,cradd, 
     +     weighb, rootdel, ethreshit
      logical odavit
      integer mbuenk,nbuenk,mxroots
      logical ifbuen, ordel, odave, oweight
      common /comrjb2/edavit(maxroot),cdavit(maxroot),
     +                extrapit(maxroot),ethreshit(maxroot),
     +                odavit(maxroot),
     +                eigvalr(maxref),cradd(3),weighb,
     +                rootdel,ifbuen,mbuenk,mxroots,
     +                ordel,odave,nbuenk,oweight
c
      parameter (maxshl1=maxshl+1)
c
      integer mxretain
      parameter (mxretain = 50)
      REAL energret,facret
      integer idumm,nopret,ipret,jkonret,nretain,iretain
      common /cski1/ idumm(maxshl),
     + energret(mxretain),facret,nopret(mxretain),
     + ipret(mxretain),jkonret(mxretain*maxshl),nretain,
     + iretain
c
      logical ospece,ospecc,ospecs
      common /trann/ ic,i7,mj(8),kj(8),isecv,icore,ick(maxorb),
     +               izer,iaus(maxorb),kjunk,ospece,ospecc,ospecs
      logical lsymd,lsadap
      common/symchk/ crtsymsym,excitsym,nrepsym,lsymd,lsadap
      logical debugs
      common /parkin/egey1,trash,tdel,
     +              ical0,nele,nko,mxex,nmulp,ispacep,nprin,
     1              nft31,nstarv,ncorci,nform,oconf,debugs,
     +              lsng,maxci,ipt0,isym(maxroot)
      logical bypass,oprin,debugd, debugtab, debugci
      logical onteint,omdi,oiotm,onedim,oprintm,oprinsym
      common /adlin/ hstor, rtol, cptol, cptolm, cptolcc,
     =               nroot, ntch, kprin, iselec,
     1               ndeci, icodea, konf,  keps,
     2               ioint, norhp, izus, issk, 
     4               ifirst, ilast, istart, ndav,
     5               iggey, nforma, bypass(6),oprin(6,3),
     6               debugd, debugtab,debugci,
     7               nteint,mdi,iotm,nedim,
     8               onteint,omdi,oiotm,onedim,
     9               oprintm,nglei,oprinsym
       common /ftap/ ntape, mtape, mdisk,
     +               ideli, ltype, linf,  ntab,  kfile,
     +               kclab, ntype, mstvt, nf01,  nf62,
     +               nhead, nf99, mtapev, nf11
      REAL orthon
      common /thresh/ critan,critrn,criten,orthon
c
      integer iselecx,izusx,iselect
      logical gganal
      common /cselec/ iselecx(maxroot),izusx(maxroot),
     +                iselect(maxroot),nrootci,
     +                iselecz(maxroot),gganal
c
      character *4 iop77,tagg
      dimension iop77(3),tagg(4)
c
      logical debugn,onatorb
      common/natorbn/itag(maxroot),isec(maxroot),jsec(maxroot),
     +               nwi,debugn,onatorb
c
      logical debugt,omoment
      common/ctmn/iput,idx,jput,jdx,nstate,debugt,omoment
c
      character *4 imos,iaos,paos,pmos,mopr
      character*4 iop88
      dimension iop88(4)
      dimension paos(11),pmos(11)
      dimension mopr(11)
c
      logical debugp,ospecp,oprop1e,noscfp,doscf
      logical iaopr,imopr
      common/cprop1e/istate,ipig(maxroot),ipmos,ipaos,iaopr(11),
     +               imopr(11),jkonp(maxshl1*maxroot),
     +               debugp,ospecp,oprop1e,noscfp,doscf
c
c
      dimension parkconf(8)
      dimension zkeypark(40),zsymx(8),zsx(8)
      dimension ilecj(maxorb)
      dimension ilecj2(maxorb,2)
c
      character*4 iop
      dimension iop(8)
      character *4 iop44
      dimension iop44(6)
      character*10 charwall
c
      data iop44/
     + 'sing','doub','trip','quar','quin','sext'/
      data iop77/'cive','putq',' '/
      data tagg/'sabf','a.o.','aos',' '/
      data iop88/'cive','aopr','mopr',' '/
      data mopr/
     *'s','x','y','z','xx','yy','zz','xy','xz','yz','t'/
      data iaos,imos/'a.o.','m.o.'/
c
      data zkeypark/
     + 'park','sele','fort','debu','ical','nele','cntr','exci','spin',
     + 'symm','outp','thre','ncor','conf','bypa','nato','mome','tm'  ,
     + 'prop','adle','diag','root','ifir','tabl','sing','maxc','core',
     + 'memo','accu','dthr','ci',  'refc','gues','prin','cpri','davi',
     + 'iter','ipri','cepa','extr'/
      data zsymx/'sym1','sym2','sym3','sym4','sym5','sym6','sym7',
     + 'sym8'/
      data zsx/'s1','s2','s3','s4','s5','s6','s7','s8'/
      data zto/'to'/
c
      data iop/'ipri','fpri','nopr','bypa','debu','off','on',' '/
c
      osortmr=.true.
      osort2=.true.
      odontgened6=.false.
      lsymd=.false.
      lsadap=.true.
c
c defaults for parkwa and adler
c
      dumt = seccpu()
      write(iwr,7777)dumt ,charwall()
c
      onteint = .false.
      omdi = .false.
      oiotm = .false.
      onedim = .false.
      oprintm = .false.
      oprinsym = .false.
      ospecc = .false.
      ospece = .false.
      ospecs = .false.
      nglei = 0
      ical0=0
      nele=0
c     default settings
      mxex=2
      nmulp=mul
      ispacep=1
      nprin=0
      trash=10.0d0
      tdel=10.0d0
c
c     comrjb2  -  defaults for mrdci iterate option
c
      ifbuen = .false.
      ocradd = .true.
      cradd(1) = 0.005d0
      cradd(2) = 0.0016d0
      cradd(3) = 0.01d0
      nbuenk = 0
      mbuenk = 5
      weighb = .95d0
      oweight = .false.
      rootdel = 100.0d0
      ordel = .false.
      oret = .false.
      odave = .false.
      mxroots = 8
c
c     cski1  -  select "retained" configurations from zero order problem
c
      nretain = 0
      iretain = 0
      facret = 0.10d0
c
      maxci=0
      ncorci=0
      istart=1
      nroot=1
      nrootci = 0
      isym(1) = 1
      ifirst=1
      ilast=ifirst+nroot-1
      nform=1
      nstarv=1
      nforma=1
      issk  = 0
      nrec31= 0
      ioint = 0
      ntch  = 1
      iggey = 0
      kprin = 0
      ndeci = 1
      icodea = 0
      ndav  = 1
      konf  = 0
      keps  = 0
      norhp = 0
      othresh = .false.
      critan = 0.00001d0
      critrn = 0.00001d0
      criten = 0.000001d0
      hstor  = 0.0000001d0
      orthon = 0.0000001d0
      opark=.true.
      oconf = .false.
c     singles wrt each root config is the default
      lsng = -999
      ipt0 = 0
      rtol  = 0.005d0
      cptol = 0.0d0
      cptolm = 0.001d0
      cptolcc = 0.0d0
      debugh = .false.
      debugl = .false.
      do loop = 1,4
       bypass(loop) = .false.
      enddo
c
c     memory defaults
      nteint = 3500001
      nedim  = 2000000
c     mdi    = 1000001
      mdi    =  500001
      iotm =   2000000
c
c     prop-1e and TM module not called by default
c
      do loop = 5,6
       bypass(loop) = .true.
      enddo
c
c     default print flags
c
      do loop=1,6
       oprin(loop,1)=.false.
       oprin(loop,2)=.false.
       oprin(loop,3)=.true.
      enddo
c
c     default debug flags
c
      debugd = .false.
      debugtab = .false.
      debugci = .false.
      debugs = .false.
c
c === =natorb= defaults
c
      nwi=1
      itag(1)=1
      isec(1)=0
      jsec(1)=0
      debugn = .false.
      onatorb = .false.
      ispacg = 0
c
c === =prop1e= defaults
c
      do i=1,11
       iaopr(i)=.true.
       imopr(i)=.true.
      enddo
      istate=1
      ipig(1)=1
      ipmos=0
      ipaos=0
      call setsto(maxshl1*maxroot,0,jkonp)
      debugp = .false.
      ospecp = .false.
      oprop1e = .false.
      noscfp = .false.
      doscf = .true.
c
c === =moment= defaults
c
      iput=36
      idx =1
      jput=36
      jdx=1
      nstate=1
      debugt = .false.
      omoment = .false.
c
c *** default for cepa
c
c var in commom/cepa_mrd1
c
      cepai = .false.
      ipcepa = 0
      icepa = 0
c
c var in common/cepa_mrd2
c
      crres = 1.0d-2
      crtest = 1.0d-2
      cre0 = .false.
      crcorr = .false.
c
c *** end defaults for cepa
c
c    default for extrapolation algorithm
c
      gganal = .true.
c
c     initialise unit numbers for all mrdci modules
c
      call funitci
c
 1763 call input
 9998 call inpa4(ytext)
      ii=locatc(zkeypark,40,ytext)
      if (ii.ne.0) go to 9999
c
c     no mrdci directive recognised
c
      jrec = jrec -1
      k=locatc(ydd(101),limit2,ytext)
      if(k.ne.0) go to 1766
      call caserr2(
     *'unrecognised directive or faulty directive ordering')
c
9999  goto(1740,  1740,  1751,  1779,  1752,  1753,  1753,  1754,  1755,
c    +    'park','sele','fort','debu','ical','nele','cntr','exci','spin',
     +     1756,  1757,  1758,  1759,  1761,  1770,  1780,  1790,  1790,
c    +    'symm','outp','thre','ncor','conf','bypa','nato','mome','tm'  ,
     +     1600,  1762,  1762,  1764,  1765,  1730,  1720,  1820,  1830,
c    +    'prop','adle','diag','root','ifir','tabl','sing','maxc','core',
     +     1830,  1840,  1840,  1762,  1762 , 1880,  1980,  1980,  1981,
c    +    'memo','accu','dthr','ci',  'refc','gues','cpri','prin','davi'
     +     1985,  1945 ,  1946,  2946),ii
c         'iter','iprin','cepa','extr'
c
c extrap alogirthm - "new" (default) or "old" (the original)
c
 2946 call inpa4(ytext)
      if(ytext.eq.'old') then
       gganal = .false.
      endif
      go to 1763
c
c input for cepa
c
 1946 call inpa4(ytext)
      cepai = .true.
      if (ytext.eq.'mr0 ') then 
         icepa = 1
         go to 1977
      else if (ytext.eq.'acpf') then 
         icepa = 2
         go to 1977
      else if (ytext.eq.'aqcc') then 
         icepa = 3
         go to 1977
      else 
         call caserr('unrecognized cepa variant')
      end if 
c
 1977 call inpa4(ytext)
      if (ytext.eq.'test') then
          call inpf(crtest)
          go to 1977
      else if (ytext.eq.'resn') then
          call inpf(crres)
          go to 1977
      else if (ytext.eq.'e0') then
          cre0 = .true.
          call inpf(enaught)
          go to 1977
      else if (ytext.eq.'shif') then
          crcorr = .true.
          call inpf(corren)
          go to 1977
      else if (ytext.eq.'prin') then
          call inpi(ipcepa)
      end if
c
c end input for cepa 
c
      go to 1763
c
c.... iprin (more strings to follow)
c
 1945 call inpa4(ytext)
      if (ytext.eq.'symm') oprinsym=.true.
      go to 1763
c
c.... mrdci / read buenker info
c
 1985 call buin_mrdci(oret)
      go to 1763
c
c ---- davidson
c
 1981 if(jump.gt.1) then
       nrootci = jump -1
       do i = 1, nrootci
        call inpi(iselect(i))
       enddo
       else
        call caserr2('no roots specified on davidson directive')
       endif
      go to 1763
c
c ---- cprin / print
c
 1980 call inpf(cptol)
      call inpf(cptolcc)
      call inpf(cptolm)
      go to 1763
c
c ---- guess
c
 1880 call inpa4(ytext)
      if(ytext.eq.'norm') then
       istart = 0
      else
       istart = 1
      endif
      go to 1763
c
c ---- singles
c
 1720 call inpa4(ytext)
      if(ytext.eq.'all') then
       lsng = -999
      else if(ytext.eq.'off') then
       lsng = 0
      else if(ytext.eq.'firs') then
       lsng = 1
      else
       jrec=jrec-1
       call inpi(lsng)
      endif
      go to 1763
c
c ---- table
c
 1730 bypass(1)=.false.
      if(jump.eq.1) go to 1763
 6310 call inpa4(ytext)
      i=locatc(iop,8,ytext)
      go to (6320,6330,6325,6335,6337,1763,1763,1763),i
 6320 oprin(1,1)=.true.
      go to 6310
 6330 oprin(1,2)=.true.
      go to 6320
 6325 oprin(1,3)=.false.
      go to 6310
 6335 bypass(1)=.true.
      go to 6310
 6337 debugtab = .true.
      go to 6410
c
c ---- parkwa or select
c
 1740 bypass(2)=.false.
      if(jump.eq.1) go to 1763
 6410 call inpa4(ytext)
      i=locatc(iop,8,ytext)
      go to (6420,6430,6425,6435,6437,1763,1763,1763),i
 6420 oprin(2,1)=.true.
      go to 6410
 6430 oprin(2,2)=.true.
      go to 6420
 6425 oprin(2,3)=.false.
      go to 6410
 6435 bypass(2)=.true.
      go to 6410
 6437 debugs = .true.
      go to 6410
c
c ----- generating fort.31 for mrdci
c
 1751 if (jump.gt.1) then
         do izut=1,jump-1
             call inpa4(ytext)
             if (ytext.eq.'old') then
                osort2=.true.
             else if (ytext.eq.'new') then
                osort2=.false.
             else if (ytext.eq.'symd') then
                lsadap=.false.
                lsymd=.true.
             else if (ytext.eq.'aled') then
                odontgened6=.true.
             else
                call caserr2('unknown fort option')
             endif
         enddo
      endif
      go to 1763
c
c --- debug
c
 1779 debugl=.true.
      call inpa4(ytext)
      if (ytext.eq.'high') debugh = .true.
      go to 1763
c
c --- ical
c
 1752 call inpi(ical0)
      go to 1763
c
c --- nele or cntrl
c
 1753 call inpi(nele)
      ospece = .true.
      go to 1763
c
c --- exci
c
 1754 call inpi(mxex)
      go to 1763
c
c --- spin
c
 1755 call inpa4(ytext)
      nmulp=locatc(iop44,6,ytext)
      if(nmulp.gt.0)go to 1763
      jrec=jrec-1
      call inpi(nmulp)
      go to 1763
c
c --- symm
c
 1756 ospecs = .true.
      call inpi(ispacep)
      go to 1763
c
c --- outp
c
 1757 call inpi(nprin)
      go to 1763
c
c --- thre
c
 1758 call inpf(trash)
      call inpf(tdel)
      call inpi(nglei)
      if (trash.gt.0.1d0.and.cepai) then
         trash = 0.1d0
         tdel = 0d0
         else 
            if (tdel.ne.0d0.and.cepai) then
              tdel = 0d0
            end if
      end if
      go to 1763
c
c --- ncor
c
 1759 call inpi(ncorci)
      go to 1763
c
c --- bypass
c
 1770 if (jump.gt.1) then
         do loop=1,jump-1
            call inpa4(ytext)
            if (ytext.eq.'tabl') then
             bypass(1) = .true.
             write(iwr,1801)
            endif
            if (ytext.eq.'park'.or.ytext.eq.'sele') then
             bypass(2) = .true.
             write(iwr,1802)
            endif
            if (ytext.eq.'refc'.or.ytext.eq.'ci'.or.
     +          ytext.eq.'diag'.or.ytext.eq.'diag') then
             bypass(3) = .true.
             write(iwr,1803)
            endif
            if (ytext.eq.'nato') then
             bypass(4) = .true.
             write(iwr,1805)
            endif
            if (ytext.eq.'tm') then
             bypass(6) = .true.
             write(iwr,1806)
            endif
            if (ytext.eq.'prop') then
             bypass(5) = .true.
             write(iwr,1807)
            endif
            if (ytext.eq.'all') then
             bypass(1) = .true.
             bypass(2) = .true.
             bypass(3) = .true.
             bypass(4) = .true.
             bypass(5) = .true.
             bypass(6) = .true.
             write(iwr,1804)
            endif
         enddo
      endif
      go to 1763
c
c --- natorb
c
 1780 bypass(4)=.false.
      if(jump.eq.1) go to 7040
 7010 call inpa4(ytext)
      i=locatc(iop,8,ytext)
      go to (7020,7030,7025,7035,7037,7038,7039,7040),i
 7020 oprin(4,1)=.true.
      go to 7010
 7030 oprin(4,2)=.true.
      go to 7020
 7025 oprin(4,3)=.false.
      go to 7010
 7035 bypass(4)=.true.
      go to 7010
 7037 debugn = .true.
      go to 7010
 7038 onatorb = .false.
      bypass(4)=.true.
      go to 1763
 7039 onatorb = .true.
      go to 1763
 7040 call input
      call inpa4(ytext)
      i=locatc(iop77,3,ytext)
      if(i.eq.0)go to 7060
      go to (7070,7080,7060 ),i
c
7070  nwi=jump-1
      if(nwi.le.0.or.nwi.gt.maxroot)call caserr2(
     *'invalid number of orbital sets requested')
      do i=1,nwi
       isec(i)=0
       jsec(i)=0
       call inpi(itag(i))
       if(itag(i).le.0.or.itag(i).gt.1000)call caserr2(
     * 'invalid orbital set requested')
      enddo
      go to 7040
c
 7080 call inpa4(ytext)
      ktag=locatc(tagg,4,ytext)
      if(ktag.eq.0)call caserr2('invalid basis option requested')
      go to( 7081, 7084, 7084,7040 ),ktag
 7081 do i=1,nwi
       call inpi(isec(i))
       if(isec(i).gt.350)go to 7083
      enddo
      go to 7080
 7083 call caserr2('invalid dumpfile section specified for nos')
 7084 do i=1,nwi
      call inpi(jsec(i))
      if(jsec(i).gt.350)go to 7083
      enddo
c     store copy of NO sections in /limy/ for analg
c     and in /natorb/ for FP optimisation
      nwroot = nwi
      do i = 1, nwroot
        nosec (i) = jsec(i)
      enddo
      ispacg = jsec(nwroot)
      go to 7080
7060  jrec=0
      go to 9998
c
c === =moment= or =tm= data
c
 1790 bypass(6)=.false.
 8005 call inpa4(ytext)
      i=locatc(iop,8,ytext)
      if(i.eq.0)go to 8010
      go to (8020,8030,8025,8035,8037,88010,88011,8010),i
 8020 oprin(6,1)=.true.
      go to 8005
 8030 oprin(6,2)=.true.
      go to 8020
 8025 oprin(6,3)=.false.
      go to 8005
 8035 bypass(6)=.true.
      go to 8005
 8037 debugt=.true.
      go to 8005
88010 omoment = .false.
      bypass(6)=.true.
      go to 1763
88011 omoment = .true.
      go to 1763
8010  call input
      call inpi(iput)
      call inpi(idx)
      call inpi(jput)
      call inpi(jdx)
      call inpi(nstate)
      if(iput.le.0.or.jput.le.0)call caserr2(
     *'invalid fortran stream specified for ci vector')
      go to 1763
c
c === =prop1e= data
c
 1600 bypass(5)=.false.
      if(jump.eq.1) go to 9010
 9020 call inpa4(ytext)
      i=locatc(iop,8,ytext)
      if(i.eq.0) then
       if(ytext.eq.'nosc') then
        noscfp = .true.
        doscf = .false.
       endif
       go to 9010
      else
       go to (9030,9040,9035,9045,9047,9048,9049,9010),i
 9030  oprin(5,1)=.true.
       go to 9020
 9040  oprin(5,2)=.true.
       go to 9030
 9035  oprin(5,3)=.false.
       go to 9020
 9045  bypass(5)=.true.
       go to 9020
 9047  debugp = .true.
       go to 9020
 9048  oprop1e = .false.
       bypass(5)=.true.
       go to 1763
 9049  oprop1e = .true.
       go to 1763
      endif
c
9010  call input
      call inpa4(ytext)
      i=locatc(iop88,4,ytext)
      if(i.eq.0)go to 9050
      go to (9060,9070,9080,9050),i
 9060 istate=jump-1
      if(istate.le.0.or.istate.gt.maxroot)call caserr2(
     *'invalid number of ci vectors requested for analysis')
      do i=1,istate
      call inpi(ipig(i))
      if(ipig(i).le.0)call caserr2(
     *'invalid ci vector specified for analysis')
      enddo
      go to 9010
c ..  process ao list
c
 9070 call inpa4(ytext)
      if(ytext.eq.' ')go to 9010
      ipaos=ipaos+1
      paos(ipaos)=ytext
      go to  9070
c ..  process mo list
c
c
 9080 call inpa4(ytext)
      if(ytext.eq.' ')go to 9010
      ipmos=ipmos+1
      pmos(ipmos)=ytext
      go to 9080
 9050 ostatep = .true.
      jrec=0
      if(ipaos.gt.0) then
       do i=1,ipaos
       j=locatc(mopr,11,paos(i))
       if(j.ne.0)iaopr(j)=.false.
       enddo
      endif
      if(ipmos.gt.0) then
       do i=1,ipmos
       j=locatc(mopr,11,pmos(i))
       if(j.ne.0)imopr(j)=.false.
       enddo
      endif
c
c     if reference configurations have been specified (i.e ospecc
c     =.true, and the scf terms are required (noscfp = .false.
c     then the leading term must now be specified for the
c     property analysis. If not, then the default SCF config. will
c     be constructed in defaults_mrdci)
c
      if (ospecc.and..not.noscfp) then
       ospecp = .true.
       jrec=0
       ij=1
       do i=1,istate
       if(i.gt.1)call input
       call inpi(jkonp(ij))
        do j=1,maxshl
        call inpi(jkonp(ij+j))
        enddo
       ij=ij+maxshl1
       enddo
       go to 1763
      else
       jrec = 0
       go to 9998
      endif
c
c --- conf
c
 1761 if (nele.le.0) then
       nele = ne
cjvl    if nele signifies something else we leave it if not irritating 
cjvl       call caserr2('nele directive must preceed conf data')
      endif
      call inpa4(ytext)
      ospecc = .true.
      if (ytext.eq.'dire'.or.ytext.eq.'occu') go to 1900
      if (ytext.eq.'old'.or.ytext.eq.' ') go to 1860
      if (ytext.eq.'sym'.or.ytext.eq.'symm') go to 1910
      call caserr2('illegal conf option')
c
c   table-ci style of configuration specification
c
 1860  oconf=.false.
 1769  ntest=0
       norbm=0
 1771  call input
       if (jump.eq.1) then
          call inpa4(ytext)
          if (ytext.eq.'end') then
c *** NB!!!
c          if (nko.eq.1)
c    +      call caserr(
c    +     'mrdci requires 2 or more reference functions')
c *** NB!!!
           go to 1763
          endif
       endif
       do iz=1,jump
          norbm=norbm+1
          call inpi(ilecj(norbm))
       enddo
       ntest=(norbm-1)*2-ilecj(1)
       if (ntest.lt.nele) goto 1771
       nko=nko+1
       write(nf11,101)ilecj(1),(ilecj(ij),ij=2,norbm)
       goto 1769
c
c     direct-ci / occupation pattern style of 
c     configuration specification
c
 1900 odirect=.true.
      write(nf01)odirect
      oconf=.true.
 1768 itest=0
      jtest=0
      do iz=1,8
        parkconf(iz)=0.0d0
      enddo
 1767 call input
      if (jump.eq.1) then
          call inpa4(ytext)
          if (ytext.eq.'end') goto 1763
      endif
      do iz=1,jump
          call inpi(ilec)
          itest=itest+ilec
          call parkconfin(jtest,ilec,parkconf)
          jtest=jtest+2
      enddo
      if (itest.lt.nele) goto 1767
      if (itest.ne.nele)
     + call caserr2('number of electrons wrong in reference')
      nko=nko+1
      write (nf01) parkconf
      goto 1768
c
c     symmetry configuration for joop
c
 1910 odirect=.false.
      oconf=.true.
      write(nf01) odirect
      nko=0
 1911 do i=1,maxorb
         do j=1,2
            ilecj2(i,j)=0
         enddo
      enddo
      itest=0
      norbsym=0
      oto=.false.
      iorb=0
      call input
      if (jump.eq.1) then
         call inpa4(ytext)
         if (ytext.eq.'end') then
           if (nko.eq.1)
     +      call caserr2(
     +     'mrdci requires 2 or more reference functions')
           go to 1763
          endif
      endif
      call inpi(nopen)
      ist=2
 1913 do iiz=ist,jump
         call inpa4(ytext)
         kk = locatc(zsymx,8,ytext)
         if (kk.eq.0) kk=locatc(zsx,8,ytext)
         if (kk.ne.0) norbsym=kk
         if (ytext.eq.'end') goto 1763
         if (ytext.eq.zto) then
             oto=.true.
             goto 1914
         endif
         if (kk.eq.0.and..not.oto) then
            jrec=jrec-1
            iorb=iorb+1
            call inpi(ilecj2(iorb,1))
            ilecj2(iorb,2)=norbsym
         endif
         if (oto) then
             jrec=jrec-1
             call inpi(nto)
             izstart=ilecj2(iorb,1)+1
             do izz=izstart,nto
                iorb=iorb+1
                ilecj2(iorb,1)=izz
                ilecj2(iorb,2)=norbsym
             enddo
             oto=.false.
         endif
 1914    continue 
      enddo
      itest=(iorb-nopen)*2+nopen
      if (itest.lt.nele) then 
          call input
          ist=1
          goto 1913
      endif
      if (itest.eq.nele) then
          write(nf01)nopen,iorb,ilecj2
          nko=nko+1
          goto 1911
      else
          call caserr2('number of electrons wrong in configuration')
      endif
      goto 1763
c
c ---- ci or refcon or adler or diag
c
 1762 bypass(3)=.false.
      if(jump.eq.1) go to 1763
 6510 call inpa4(ytext)
      i=locatc(iop,8,ytext)
      go to (6520,6530,6525,6535,6537,1763,1763,1763),i
 6520 oprin(3,1)=.true.
      go to 6510
 6530 oprin(3,2)=.true.
      go to 6520
 6525 oprin(3,3)=.false.
      go to 6510
 6535 bypass(3)=.true.
      go to 6510
 6537 debugd = .true.
      debugci = .true.
      go to 6510
c
c --- root
c
 1764 call inpi(nroot)
      if(nroot.le.0.or.nroot.gt.maxroot) then
       call caserr2('invalid number of roots specified')
      endif
      if(jump.eq.2) then
       do i =1,nroot
        isym(i) = i
       enddo
       ipt0 = 0
      else
       j=jump-2
       if(j.ne.nroot) then
        call caserr2(
     *'inconsistent number of specified roots for selection')
       endif
       do i=1,j
        call inpi(isym(i))
       enddo
       ipt0 = 1
      endif
c
      ifirst = isym(1)
      ilast=ifirst+nroot-1
      goto 1763
c
c --- ifir
c
 1765 if (nroot.le.0)
     + call caserr2('invalid number of roots')
      call inpi(ifirst)
      ilast=ifirst+nroot-1
      goto 1763
c
c --- maxci
c
 1820 call inpi(maxci)
      if(maxci.le.0) maxci = 0
      go to 1763
c
c --- core or memory specification for adler
c     override default values for mdi, nteint, nedim and iotm
c
 1830 call inpa4(ytext)
      if(ytext.eq.' ') go to 1777
      if(ytext.eq.'ntei') then
       call inpi(nteint)
       onteint = .true.
       go to 1830
      else if(ytext.eq.'iotm') then
       call inpi(iotm)
       oiotm = .true.
       go to 1830
      else if(ytext.eq.'nedi') then
       call inpi(nedim)
       onedim = .true.
       go to 1830
      else if(ytext.eq.'mdi') then
       call inpi(mdi)
       omdi = .true.
       go to 1830
      else if(ytext.eq.'prin'.or.ytext.eq.'outp') then
       oprintm = .true.
       go to 1830
      else
       call caserr2('invalid core string in MRDCI input')
      endif
 1777 if(mdi.le.0 .or. nteint.le.0 .or. nedim.le.0 .or.
     +   iotm.le.0 ) call caserr2(
     +  'invalid core parameter in MRDCI input')
c
      go to 1763
c
c --- accuracy / dthresh
c
 1840 call inpf(criten)
      call inpf(critrn)
      call inpf(critan)
      if(criten.le.0.0d0) criten = 0.000001d0
      if(critrn.le.0.0d0) critrn = criten*10.0d0
      if(critan.le.0.0d0) critan = critrn
      othresh = .true.
      go to 1763
 1766 continue
c
c     tighten ci thresholds if FP geom optimisation 
c     has been requested
c
      if (ocifp.and. .not. othresh) then
       criten = criten * 0.1d0
       critrn = criten * 10.0d0
       critan = critrn
      endif
c
c     limited print of input options
c
      if (lsng.eq.0) then
       write(iwr,3070)
      else if(lsng.eq.-999) then
       write(iwr,3080)
      else
       write(iwr,3071)lsng
      endif
      write (iwr,3084) (isym(i),i=1,nroot)
      write (iwr,9300) trash,tdel
      if(.not.gganal) write(iwr,9305)
c
      if(cptol.eq.0.0d0)cptol=0.05d0
      if(cptolcc.eq.0.0d0)cptolcc=0.002d0
      if(cptolm.lt.0.0d0) cptolm=0.000d0
c
      if(.not.bypass(4)) then
       if(onatorb) then
        write(iwr,77090)
       else
        write(iwr,7090)nwi,(itag(i),i=1,nwi)
        if(oprin(4,2))write(iwr,7091)
        do i=1,nwi
        if(isec(i).gt.0)write(iwr,7093)tagg(1),i,isec(i)
        if(jsec(i).gt.0)write(iwr,7093)tagg(2),i,jsec(i)
        enddo
       endif
c
      endif
c
      if(.not.bypass(5)) then
       if(oprop1e) then
        write(iwr,34001)
       else
        write(iwr,34000)
        if(oprin(5,2))write(iwr,9100)
        if(ipaos.eq.0) then
         write(iwr,9005)iaos
        else
         write(iwr,9007)iaos
         do i=1,11
         if(.not.iaopr(i))write(iwr,9025)mopr(j)
         enddo
        endif
c
c    mo integral print specification
c
        if(ipmos.eq.0) then
         write(iwr,9005)imos
        else
         do i=1,11
         if(.not.imopr(i))write(iwr,9025)mopr(j)
         enddo
        endif
c
       endif
c
      endif
c
      if(.not.bypass(6)) then
       if (omoment) then
        write(iwr,35001)
       else
        write(iwr,35000)
       endif
      endif
c
c     load up diagonalisation options
c     take options from =davi= if specified
c     and copy zero order selection to iselecz
      if(nrootci.eq.0) then
        nrootci = nroot
        do i = 1,nroot
         iselect(i) = isym(i)
        enddo
      endif
      do i = 1,nroot
       iselecz(i) = isym(i)
      enddo
c
c     ITERATE options
c
      if (ifbuen) then
       write (iwr,6010) mbuenk , mxroots
       do loop=1,maxroot
        odavit(loop) = .false.
       enddo
       if (ocradd) write(iwr,6020)cradd(1)
       if (ordel) write(iwr,6030)rootdel
       if (odave) write(iwr,6050) 
       if (oweight) write(iwr,6060)weighb
       if (oret) then
        write(iwr,6070) facret
        write(iwr,6080) iretain
       endif
c      set defaults for analysis routines
       call defana(iwr)
       write(iwr,6040)
      else
c
       if(onatorb.or.oprop1e.or.omoment) 
     +    call defana(iwr)
      endif
c
c --- end of input of parkwa and adler
c
      write(iwr,7776)
      return
c
 7777 format(//1x,
     1 '*** MRD-CI V2.0: Pre-processor called at ',f8.2,' seconds'
     1 ,a10,' wall'/)
 101  format (i4,',',/,256i4)
 6010 format (/
     + 1x,67('=')/
     + 1x,'==',16x,'MRDCI iterative option requested',15x,'=='/
     + 1x,67('=')/
     + 1x,'== maximum number of',i3,' MRDCI iterations'/
     + 1x,'== maximum number of roots = ', i3)
 6020 format(1x,'== include configurations in reference set',
     +          ' with c**2 .ge . ',f7.3)
 6030 format(1x,'== root inclusion criteria ', f8.2, ' aus')
 6050 format(1x,'== root expansion in davidson requested')
 6060 format(1x,'== increase mains until total c**2 = ',f10.3)
 6070 format(1x,'== retained configuration factor = ',f10.3)
 6080 format(1x,'== Initiate Retain at iteration ',i3)
 6040 format (1x,67('='))
 1801 format(/1x,'bypass generation of table')
 1802 format(/1x,'bypass selection processing')
 1803 format(/1x,'bypass refcon processing')
c1804 format(/1x,'bypass diagonalisation module')
 1804 format(/1x,'bypass all mrdci modules to start with')
 1805 format(/1x,'bypass natural orbital module')
 1806 format(/1x,'bypass transition moment module')
 1807 format(/1x,'bypass property module')
 3070 format(/
     +' no automatic selection of singly excited configurations')
 3080 format(/' take all single excitations into account')
 3084 format(/' input specified roots for use in selection :'/
     + 10x,30i3)
 3071 format(/
     +' include all singly excited configurations with'/
     +' respect to root function no. ',i3)
 9300 format(//' *** threshold specified ***'//
     *' minimal selection threshold ',f7.2,' microhartree'//
     *' threshold increment for use in selection ',f7.2,
     *' microhartree'/)
 9305 format(/1x'*** revert to old extrapolation algorithm'/)
77090 format(1x,'natural orbital analysis requested for all roots')
 7090 format(/1x,'natural orbital analysis'/1x,
     +           '************************'//
     + ' *** analysis requested for',i3,
     + ' ci vectors'//5x,
     + 'with following locations on the ci vector file (ft36)'
     + ,40i3)
 7093 format(/
     + ' ** route n.o.s ( ',a4,' basis) for state',i3,
     + ' to section',i4,' of dumpfile')
 7091 format(/1x,
     + 'print of density matrix and n.o.s in mo basis requested'/)
34001 format(1x,'molecular properties requested for all roots')
34000 format(/1x,'molecular properties'/1x,
     +           '********************')
 9100 format(' print out of basis functions requested'/)
 9005 format(
     + ' no printing of integrals in ',a4,' basis required')
 9007 format(' print following integrals in ',a4,' basis : ')
 7776 format(/1x,'*** mrd-ci data input complete'/)
35000 format(/1x,'transition moment analysis'/1x,
     +           '**************************')
35001 format(1x,
     + 'transition moment analysis requested for all excited statess')
 9025 format(/10x,a2,' - matrix')
      end
**==buin_mrdci.f
      subroutine buin_mrdci(oret)
c
c...  input line for mrdci iteration option
c
      implicit REAL  (a-h,o-z),integer (i-n)
      character *4 ites,itt
      logical oret
c
INCLUDE(common/work)
INCLUDE(common/iofile)
      parameter (maxref = 256)
      parameter (mxroot = 50)
INCLUDE(common/comrjb2)
c
      integer mxretain
      parameter (mxretain = 50)
      REAL energret,facret
      integer idumm,nopret,ipret,jkonret,nretain,iretain
      integer maxshl
      parameter (maxshl=50)
      common /cski1/ idumm(maxshl),
     + energret(mxretain),facret,nopret(mxretain),
     + ipret(mxretain),jkonret(mxretain*maxshl),nretain,
     + iretain
c
      dimension itt(7)
      data itt/'weig','maxi','sroo','droo','maxr',
     +         'c**2','reta'/
c
      ifbuen = .true.
c
c...  see if anything more on the card
c
 20   if (jrec.ge.jump) go to 100
      call inpa4(ites)
      ll = locatc(itt,7,ites)
      if (ll.le.0) then
       write(iwr,50) ites
 50    format(/1x,'invalid ITERATE option = ', a4)
       call caserr2('invalid ITERATE option')
      endif
c
 30   go to (40,60,80,90,110,120,130) , ll
c...  weight 
 40   call inpf(cradd(1))
      if(cradd(1).le.0.0d0) cradd(1) = 0.005d0
      go to 20
c...  maxiter
 60   call inpi(mbuenk)
      if(mbuenk.le.0.or.mbuenk.gt.50) buenk = 50
      go to 20
c...  sroot
 80   call inpf(rootdel)
      ordel = .true.
      go to 20
c...  droot
 90   odave= .true.
      go to 20
c...  c**2
120   call inpf(weighb)
      oweight = .true.
      go to 20
c...  maxroot
110   call inpi(mxroots)
      if(mxroots.le.0.or.mxroots.gt.50)
     +   mxroots = 8
      go to 20
c...  retain
130   call inpf(facret)
      call inpi(iretain)
      oret = .true.
      go to 20
c
 100  continue
c
      return
      end
      subroutine parkconfin(jtest,nel,iparkconf)
      implicit REAL (a-h,o-z)
_IF(i8)
      integer *4 iparkconf, kmask, iup, kshift
_ENDIF
      dimension iparkconf(16)
      dimension kmask(0:2)
      data kmask/0,1,3/
      if (nel.lt.0.or.nel.gt.2)call caserr2('invalid nel')
      if (jtest.gt.256) call caserr2('invalid shift')
      iin=jtest/32
      kshift=mod(jtest,32)
      iup=0
      iup=ior(iup,kmask(nel))
_IF(absoft,i8)
      iup=ishft(iup,kshift)
_ELSE
      iup=ISHFT(iup,kshift)
_ENDIF
      iparkconf(16-iin)=ior(iparkconf(16-iin),iup)
      return
      end
      subroutine funitci
c
c     unit common for selection etc
c
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      integer  nston,mtape,mdisk
      integer  ideli,ltype,linf,ntab,kfile,kclab
      integer  ntype, mstvt, nf01, nf62, nhead
      integer  nf99, mtapev, nf11
      common /ftap/ nston, mtape, mdisk,
     .              ideli, ltype, linf,  ntab,  kfile,
     .              kclab, ntype, mstvt, nf01, nf62,
     +              nhead, nf99, mtapev, nf11
c
c     unit common for adler etc.
c
      integer ntape, mtype, nhuk, ltape, idelj, ntable, nf78
      integer nf88, iput, mousa, ifox
      integer lun20, lun21, lun22, lunalt
      integer lun01, lun02, lun03, lund, jtmfil
      common /ftap5/ ntape, mtype, nhuk, ltape, idelj,
     +               ntable, nf78, nf88, iput, mousa, ifox,
     +               lun20, lun21, lun22, lunalt, 
     +               lun01, lund, lun02, lun03, jtmfil
c
c     units from old MRDCI
c     data index/1,2,3,4,8,9,10,
c    *          22,31,33,34,35,36,41/

c     data index/2,3,4,10,22,41/
c      mtape = 32
c      kfile = 48
c      nhead = 73
c      ntype = 58
c      mtapev =78
c      kclab = 52
       nf01  =  1
       mtape =  2
       ntype =  3
       kfile =  4
       mdisk =  8
       ltype =  9
       nhead = 10
       nf11  = 11
       mtapev =22
       nston = 31
       linf  = 33
       ideli = 34
c
       ntab  = 43
       kclab = 41
c --- tape for the start vector from g0 or g1
       mstvt = 42
       nf62 =  44
       nf99 =  12
c
c  unit numbers for adler (/ftap5/)
c
c  mtype : vorsortierung der integrale
c  ntape : integral-file vom stoney
c  ltape : konfigurationen und anderes vom parkeu
c  idelj : irdendwas vom parkeu
c  nhuk  : (output) groessen von stoney, parkeu sowie die
c          hamiltonmatrix
c  ntable: table
c  mtapev : erzeuger- und vernichter
c
      ntape = nston
      mtype = ltype
      nhuk  = 35
      iput  = 36
      ltape = linf
      idelj = ideli
      ntable = ntab
      nf78  = mtapev
      nf88  = nf62
c
c where is ifox written ?
      ifox  = 2
c
c     mousa = 3
c     lun20 = 20 
c     lun21 = 21
c     lun22 = 22
c     lunalt= 25
c     replace the above with streams used in selection module
      lun20 = mdisk
      lun21 = mtape
      lun22 = kfile
      lunalt= ntype
      mousa = nhead
c
c     analysis (natorb, prop1e and tm files)
c
      lun01 = nf01
      lund = nhuk
      lun02 = mtape
      lun03 = ntype
      jtmfil = kclab
c
      return
      end
      subroutine mrdcim2(core,energy)
      implicit REAL  (a-h,o-z),integer(i-n)
INCLUDE(common/sizes)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/prints)
INCLUDE(common/statis)
INCLUDE(common/timez)
INCLUDE(common/zorac)
INCLUDE(common/infoa)
      logical again, otime
      parameter (maxref = 256)
INCLUDE(common/comrjb2)
      parameter (maxroot=50)
      parameter (maxshl=50)
      parameter (maxshl1 = maxshl+1)
      logical oconf,debugs
      common /parkin/ egey1(3), ical0(11),oconf,debugs
      logical bypass,oprin
      logical debugd, debugtab, debugci, oprinsym
      logical onteint,omdi,oiotm,onedim,oprintm
      common /adlin/ hstor, rtol, cptol, cptolm, cptolcc,
     +               nroot, ntch, kprin, iselec,
     1               ndeci, icodea, konf,  keps,
     2               ioint, norhp, izus, issk,
     4               ifirst, ilast, istart, ndav,
     5               iggey, nforma, bypass(6),oprin(6,3),
     6               debugd, debugtab,debugci,
     7               nteint,mdi,iotm,nedim,
     8               onteint,omdi,oiotm,onedim,
     9               oprintm,nglei,oprinsym
      common/restri/nfils(63),lds(508),isect(508),ldsect(508)
      logical debugn
      common/natorbn/itag(maxroot),isec(maxroot),jsec(maxroot),
     +               nwi,debugn
      logical debugp,ospecp,oprop1e,noscfp,doscf
      logical iaopr,imopr
      common/cprop1e/istate,ipig(maxroot),ipmos,ipaos,iaopr(11),
     +               imopr(11),jkonp(maxshl1*maxroot),
     +               debugp,ospecp,oprop1e,noscfp,doscf
      logical debugt
      common/ctmn/iput,idx,jput,jdx,nstate,debugt
      logical odebug
      character*10 charwall
      dimension core(*)
c
      if(ibl3d.le.0)call caserr2('invalid dumpfile starting block')
c
c...  calculate zora stuff before memory is eaten
c...   (not used here ; just to get it written to disk)
c
      if (ozora) then
         if (oscalz.and..not.opre_zora)
     1      call caserr2('scaled zora requires scf before mrdci')
         ibase = igmem_alloc(nx*2)
_IF(cray,ibm,vax)
         call szero(core(ibase+nx),nx)
_ELSE
         call vclr(core(ibase+nx),1,nx)
_ENDIF
         call zora(core,core(ibase),core(ibase+nx),'calc')
         call gmem_free(ibase)
      end if
c
      if(nprint.eq.-5) then
       oprint(29) = .true.
      else
       oprint(29) = .false.
      endif
      write(iwr,4)
      call cpuwal(begin,ebegin)
      imode = 0
      ntask = 0
      otime = .false.
      again = .false.
 50   call timrem(tleft)
      imode=imode+1
      if(imode.gt.6)go to 16
      if(bypass(imode))go to 50
      cpu = cpulft(1)
      if(cpu.gt.timlim) then
        tim = timlim+0.1d0
        irest = 9
        otime = .true.
        ifbuen = .false.
        write(iwr,18)
      go to 110
      endif
      ntask=imode
      oprint(31) = oprin(imode,1)
      oprint(32) = oprin(imode,2)
      oprint(33) = oprin(imode,3)
      if(oprint(29)) oprint(33) = .false.
      go to (90,10,11,13,14,15),imode
c     ----- table data base module
  90  call tablegen(debugtab)
      go to 65
c     ----- table ci selection module
  10  call parkwa(core,debugs,oprinsym)
  65  call closbf3
      go to 50
c      ----- refcon and semi-direct diagonalization modules
  11  odebug = debugci .or. debugd
      call refcon(core,odebug)
      call adler(core,energy,odebug,oprinsym)
      go to 65
c     ----- natural orbital and density matrix module
c
c     first convert to old mdci file format
  13  call cmrdci(core,debugn)
      call nmrdci2(core,debugn)
      go to 50
c     ----- 1-e properties module
c     note that the properties code assumes that the
c     no module is executed in the same run ...
  14  call pmrdci2(core,debugp)
      go to 50
c     ----- transition moment module
  15  call cmrdci(core,debugt)
      call moment2(core,debugt)
      go to 50
  16  cpu=cpulft(1)
      irest = 0
 110  write(iwr,17)cpu ,charwall()
c
c     set bypass(1) to be true to allow for multiple
c     entries of the table data base generator in the
c     same job (e.g. runtype optimize ci)
c
      bypass (1)=.true.
      call bucntl_mrdci(again,iwr)
      imode = 0
      if (.not.otime.and.again) then
       imode = 0
       go to 50
      endif
c
      call timana(13)
      call clredx
c
      return
 4    format(/40x,32('*')/
     +        40x,'Semi-direct Table-CI Calculation'/
     +        40x,32('*')/)
 17   format(/1x,
     +'end of Table-CI calculation at ',f8.2,' seconds',a10,' wall'/)
18    format(/5x,'*** allocated CPU time will be exceeded ***')
      end
      subroutine bucntl_mrdci(again,iwr)
c
c     control routine for reference configuration selection
c
      implicit REAL  (a-h,o-z),integer (i-n)
      logical again
      logical ocritm, ocrits, ocritd, ocritw
      parameter (maxref = 256)
      parameter (mxroot=50)
INCLUDE(common/comrjb2)
c
      parameter (maxshl = 50 )
      parameter (maxshl1=maxshl+1)
      parameter (ndcon  = maxshl*maxref )
      integer nopmax
      parameter (nopmax = 9)
      parameter (ndk5 = 5 )
      parameter (ndkneu=ndk5+2,nopneu=nopmax+4)
      logical debugs,oconf
      common /parkin/egey1,trash,tdel,
     +              ical0,nele,nko,mxexp,nmulp,ispacep,nprin,
     1              nft31,nstarv,ncorci,nform,oconf,debugs,
     +              lsng,maxci,ipt0,isym(mxroot)
       common /ftap/ ntape, mtape, mdisk,
     +               ideli, ltype, linf,  ntab,  kfile,
     +               kclab, ntype, mstvt, nf01,  nf62,
     +               nhead, nf99, mtapev, nf11
      integer nston, iputt
      common /ftap5/ nston(8),iputt
      common /tap/ ical, m, nkorig, mxex, nmul
c
      common /adlin/ hstor, rtol, cptol, cptolm, cptolcc,
     +               nroot, ntch, kprin, iselec,
     +               ndeci, icodea, konf,  keps,
     +               ioint, norhp, izus, issk,
     +               ifirst, ilast, istart, ndav
c
      integer iselecx,izusx,iselect
      common /cselec/ iselecx(mxroot),izusx(mxroot),
     +                iselect(mxroot),nrootci,
     +                iselecz(mxroot)
c
      common /scrtch/ jkonr(maxshl), jkon(ndcon),
     +       nop(maxref),ndub(maxref),nyzl(maxref)
      integer nytln,nconfn,iswn,jdeksn,kdeksn
      common /momain/ nytln(ndkneu),nconfn(ndkneu),
     +     iswn(ndkneu),jdeksn(nopneu),kdeksn(nopneu)
c
      common /cnbox/ nbox, ocritm, ocrits, ocritd, ocritw
c
c     ifbuen : logical  /.true. do it
c     cradd(1) (0.005)  add config to mains
c     cradd(2)          not used at present
c     cradd(3)          not used at present
c     nbuenk  : iteration count for rjb (initialise to 0)
c     mbuenk  : max. number of rjbs (e.g.initialise to 5)
c     weighb  : desired weight of ref conf. (e.g.initialise .95)
c             : mains increased till total c**2 is achieved
c
c     three criteria to decide on continuing the sequence of mrdci
c     calculations:
c     1. has the no of main configurations requested using cradd(1)
c        changed from the preceding pass (omains)
c     2. does the eigen value spectra of the zero order problem
c        justify expanding the no. of roots to be used in selection?
c        eigval(n+1)-eigval(n)  < rootdel
c        (ordel set true under "sroot rootdel"
c     3. based on 2, should we increase the no. of roots from the davidson
c        odave set true under droot
c     note that these criteria are judged such that 3. is not invoked before
c     2. is satisfied, and 2. is not invoked before 1. is satisfied.
c
      again = .false.
      if (.not.ifbuen) return
      nbuenk = nbuenk + 1
      if(nbuenk.gt.mbuenk) then
       call wrt_mrdci(.false.,nrootci)
       write(iwr,95)
95     format(//
     + 20x,'*********************************************************'/
     + 20x,'* No. of specified iterations for iterative MRDCI       *'/
     + 20x,'* treatment have been exceeded. Iterations terminated   *'/
     + 20x,'*********************************************************'/)
        again = .false.
        return
      endif
c
c     1st decide if no. of main configs to be expanded
c     retrieve nko and configuration list from nf11 (aftci)
c     also restore current c**2 for implementation of c**2 
c     directive
c
      im = 0
      coefft = 0.0d0
      nko = 0
      nshl= maxshl
c     this code requires following definitions
c     iswn, nytyln, and defines nyzl
c
      call rewftn(nf11)
 10   nt = im + 1
      im = im + maxshl
      do loop = nt, im
       jkon(loop) = 0
      enddo
      read (nf11,*,end=20,err=20) np, coeffb
      mm = (m+np)/2
c     reference configurations with up to nopmax open shells are allowed
      if(np.gt.nopmax) call caserr2(
     +  'too many open shells in mains for dimensions')
      read (nf11,*)(jkonr(j),j=1,mm)
      nko = nko + 1
      do j=nt,im
       jkon(j) = jkonr(j-nt+1)
      enddo
      nyt=1
      if(np.eq.0) go to  94
      nyt = iswn(np)
 94   nyt=nytln(nyt)
      nyzl(nko)=nyt
      if(nko.eq.1) go to 503
      i1=nko-1
      mx=-nshl
      do 504 j=1,i1
      mx=mx+nshl
      if(nop(j).ne.np) go to 504
      nv=mx
      la=nt-1
       do k=1,nyt
       la=la+1
       nv=nv+1
       if(jkon(la).ne.jkon(nv)) go to 504
       enddo
c     this main configuration has already appeared
       nko = nko - 1
       do loop = nt, im
        jkon(loop) = 0
       enddo
       im = im - maxshl
       go to 10
 504  continue
c
c     check for excessive values of np (see note below)
c     and remove offending configuration
c
      if(np.gt.nmul+3) then
       nko = nko - 1
       do loop = nt, im
        jkon(loop) = 0
       enddo
       im = im - maxshl
       go to 10
      endif
c
 503  na=nmul+np
      if(na-2*(na/2).eq.0) go to 771
      if(np.gt.m) go to 771
c     I dont understand the condition below given the current setting
c     for nopmax e.g. 6 open shells when nmul=1 will trigger it.
c     I've tried editing it out, but this leads to problems at
c     selection time with "not all mains generated" - for the moment
c     deal with this in the checks above.
c     if(np.gt.nmul+3) go to 771
      nop(nko)=np
      ndub(nko)=(m-np)/2
      coefft = coefft + coeffb
      if(np.lt.2) go to 500
      nz=jkon(nt)
      if(nz.lt.1.or.nz.gt.nbox) go to 773
      do j=2,np
       nt=nt+1
       nv=jkon(nt)
       if(nv.le.nz) go to 769
       if(nv.gt.nbox) go to 773
       nz=nv
      enddo
      if(np.eq.m) go to 10
518   mx=np+im-nshl+1
      nv=jkon(mx)
      if(nv.lt.1.or.nv.gt.nbox) go to 773
      lb=im-nshl
      do 506 j=1,np
      lb=lb+1
      if(jkon(lb)-nv) 506,769,507
506   continue
507   jm=np+2
      if(jm.gt.nyt) go to 10
      kp=mx
      do 508 j=jm,nyt
      kg=mx
      mx=mx+1
      nv=jkon(mx)
      if(nv.lt.1.or.nv.gt.nbox) go to 773
      do 509 k=kp,kg
      nz=jkon(k)
      if(nv.le.nz) go to 769
 509   continue
      kg=im-nshl
      do 510 k=1,np
      kg=kg+1
      if(jkon(kg)-nv) 510,769,508
 510  continue
 508  continue
      go to 10
 500  if(np.eq.0) go to 511
      nv=jkon(nt)
      if(nv.lt.1.or.nv.gt.nbox) go to 773
      go to 518
 511  nz=jkon(nt)
      if(nz.lt.1.or.nz.gt.nbox) go to 773
      if(nyt.eq.1) go to 10
      kp=nt
      do 512 j=2,nyt
      kg=nt
      nt=nt+1
      nv=jkon(nt)
      if(nv.lt.1.or.nv.gt.nbox) go to 773
      do 512 k=kp,kg
      nz=jkon(k)
      if(nv.le.nz) go to 769
 512  continue
      go to 10
 20   continue
c
      if (nko.gt.maxref) go to 776
      ocritm = .false.
      ocrits = .false.
      ocritd = .false.
      ocritw = .false.
c
      if(nkorig.ne.nko) then
       ocritm = .true.
       go to 200
      endif
c     is c**2 option in effect?
      if (oweight) then
       if(coefft. gt. weighb) then
        ocritw = .false.
        ocritm = .false.
       else
        ocritw = .true.
        ocritm = .true.
        cradd(1) = cradd(1) * 0.50d0
        go to 200
       endif
      endif
      if(.not.ordel) go to 200
c
c  ordel specified, consider ocrits and or odave
c  first consider ocrits and expanding root selection
c  only instigated when nrrot = nrootci (davidson)
c
c  now examine zero-order eigen values
c  and increase root selection if higest
c  (nr+1)th root is within rootdel au of the
c  roots originally specified
c      
      if (nroot.eq.nrootci) then
        write(6,*) eigvalr(nroot+1), eigvalr(nroot)
        if(dabs(eigvalr(nroot+1) - eigvalr(nroot)). le.
     +    rootdel.and.nroot.lt.mxroots) then
          nroot = nroot + 1
          ocrits = .true.
          isym(nroot) = nroot
          ifirst = isym(1)
          ilast=ifirst+nroot-1
          go to 200
        endif
      endif
c
c  now consider odave
c  and expanding final davidson
c
      if (odave) then
        if(nroot.gt.nrootci.and.nrootci.lt.mxroots) then
         nrootci = nrootci + 1
         iselect(nrootci) = nrootci
         iselecz(nrootci) = nrootci
         ocritd = .true.
        endif
      endif
c
200   if(ocritm.or.ocrits.or.ocritd.or.ocritw) then
       again = .true.
      else
       again = .false.
      endif
c
      if (again) then
       call rewftn(iputt)
       write(6,*)'ocritm, ocrits, ocritd=', ocritm, ocrits, ocritd
       write(iwr,50) nbuenk, nko, nroot, nrootci
50     format(///
     + 1x,'**********************************************************'/
     + 1x,'** Iteration ',i2,
     +     ' of MRDCI will comprise the following    **'/
     + 1x,'** No. of main configurations    = ', i3, 18x,'**'/
     + 1x,'** Zero-order roots in selection = ', i3, 18x,'**'/
     + 1x,'** ci vectors from davidson      = ', i3, 18x,'**'/
     + 1x,'**********************************************************')
       if (ocrits) write(iwr,60) rootdel,nroot
60     format(1x,
     + '** root expansion will be invoked: criteria = ',f8.2,2x,'**'/
     +  1x,
     + '** selection with respect to ',i4, ' zero-order roots      **')
       if(ocritd) write(iwr,80) nrootci
80     format(1x,
     + '** roots in davidson will be expanded based on above    **'/
     +  1x,
     + '** revised no. of roots in davidson = ', i7, '           **')
       if (oweight) write(iwr,65) coefft, cradd(1)
65     format(1x,
     + '** estimated c**2 for main configurations = ',f7.3,
     + '     **'/1x,
     * '** new c**2 threshold for inclusion as main = ',f7.4,
     + '   **')
c
c      set defaults for analysis routines
c
       call defana(iwr)
c
       if(ocrits.or.ocritd.or.ocritw) then
       write(iwr,70)
70      format(
     + 1x,'**********************************************************'/
     + )
       else
        write(iwr,75)
75      format(/)
       endif
c
c     record current status of MRDCI Iterations
c
       call wrt_mrdci(ocritd,nrootci)
c
c     now write enlarged reference set to nf11
       call rewftn(nf11)
       im = 0
       do i=1,nko
        nt = im +    1
        im = im + nshl
        mm = (m+nop(i))/2
        write(nf11,101) nop(i), (jkon(j),j=nt,nt+mm-1)
101     format (i4,',',/,256i4)
       enddo
       call rewftn(nf11)
      else
       write(iwr,75)
       call wrt_mrdci(.false.,nrootci)
       write(iwr,90)
90     format(//
     + 20x,'*********************************************************'/
     + 20x,'* Requested criteria for iterative MRDCI treatment have *'/
     + 20x,'*       been satisfied. Iterations terminated           *'/
     + 20x,'*********************************************************'/)
      endif
c
      return
c
 771  write(iwr,772)
 772  format(5x,
     + 'open shell structure in mains inconsistent with multiplicity')
      call caserr2(
     +  'open shell structure inconsistent with multiplicity')
 769  write(iwr,770) nko,nv,nz,jkon(kg),kg,jkon(lb),lb
 770  format(5x,'pauli was right or maybe permutation error',7i5)
      call caserr2('possible permutation error')
 773  write(iwr,774)
 774  format(5x,'orbital numbering is weird in mains')
      call caserr2('orbital numbering is inconsistent in mains')
 776  write(iwr,760) nko
 760  format(20x,'** too many main configurations (',
     +      i3, ') requested')
      call caserr2('too many reference configurations')
      return
      end
      subroutine defana(iwr)
c
c     routine for specifying default CI analysis options
c     for semi-direct MRDCI processing
c
      implicit REAL  (a-h,o-z),integer (i-n)
c
      parameter (mxroot=50)
      parameter (maxref = 256)
INCLUDE(common/comrjb2)
INCLUDE(common/limy)
INCLUDE(common/natorb)
c
      parameter (maxshl = 50 )
      parameter (maxshl1=maxshl+1)
c
      integer iselecx,izusx,iselect
      common /cselec/ iselecx(mxroot),izusx(mxroot),
     +                iselect(mxroot),nrootci,
     +                iselecz(mxroot)
c
      logical debugn,onatorb
      common/natorbn/itag(mxroot),isec(mxroot),jsec(mxroot),
     +               nwi,debugn,onatorb
c
      logical debugp,ospecp,oprop1e,noscfp,doscf
      logical iaopr,imopr
      common/cprop1e/istate,ipig(mxroot),ipmos,ipaos,iaopr(11),
     +               imopr(11),jkonp(maxshl1*mxroot),
     +               debugp,ospecp,oprop1e,noscfp,doscf
c
      logical debugt,omoment
      common/ctmn/iput,idx,jput,jdx,nstate,debugt,omoment

       if (onatorb) then
        nwi = nrootci
        do i=1,nwi
         itag(i) = i
        enddo
c      default sections to dumpfile (from section 50 onwards)
        jsec0 = 50
        do i=1,nwi
         jsec(i) = jsec0
         jsec0 = jsec0 + 1
        enddo
c      store copy of NO sections in /limy/ for analg
c      and in /natorb/ for FP optimisation
        nwroot = nwi
        do i = 1, nwroot
          nosec (i) = jsec(i)
        enddo
        ispacg = jsec(nwroot)
       endif
       if (oprop1e) then
        istate = nrootci
        do i=1,istate
         ipig(i) = i
        enddo
       endif
       if (omoment) then
        iput = 36
        idx = 1
        jput = 36
        jdx = 2
        nstate = nrootci-1
       endif
c
       if (onatorb)  write(iwr,660)
660    format(1x,
     + '== default generation of natural orbitals               ==')
       if (oprop1e)  write(iwr,670)
670    format(1x,
     + '== default generation of molecular properties           ==')
       if (omoment)  write(iwr,680)
680    format(1x,
     + '== default generation of transition moments             ==')
c
       return
       end
      subroutine wrt_mrdci(ocritd,nrootci)
      implicit REAL  (a-h,o-z),integer  (i-n)
      logical ocritd, onote
      integer nrootci
      parameter (maxref = 256)
      parameter (mxroot=50)
INCLUDE(common/iofile)
INCLUDE(common/comrjb2)
      common /parkin/egey1,trash,tdel
c
      itrash = idint(trash)
      onote = .false.
      write(iwr,790) itrash
      efirst = edavit(1)
      nort = nrootci
      if (ocritd) nort = nort -1
      do loop = 1, nort
       erel = edavit(loop) - efirst
       erelev = erel * 27.211d0
       if (cdavit(loop).le.0.005d0) then
        write(iwr,785)loop
        onote = .true.
       else
        if(odavit(loop)) then
         write(iwr,781)loop,cdavit(loop),ethreshit(loop),
     +                 extrapit(loop),edavit(loop),
     +                 erel, erelev
         onote = .true.
        else
         write(iwr,780)loop,cdavit(loop),ethreshit(loop),
     +                 extrapit(loop),edavit(loop),
     +                 erel, erelev
        endif
       endif
      enddo
c
      if (onote) then
       write(iwr,770)
      endif
c
      return
790   format(
     + 8x,'=================================================',
     +    '=========================================='/
     + 8x,'==                      Current Energies from MRD',
     +    'CI Iterations                           =='/
     + 8x,'=================================================',
     +    '=========================================='/
     + 8x,'== State    c**2       Energy          Energy    ',
     +    '      Davidson      Relative Energetics =='/
     + 8x,'==                   (T=',i3,', a.u.)   (T=0, a.u',
     +     '.)        (a.u.)          (a.u.)    (eV)   =='/
     + 8x,'=================================================',
     +    '==========================================')
785     format(8x,
     + '==',i3,'                          ***** No Extrapola',
     +    'tion  *****                             ==')
780   format(8x,'==',i3,f11.3,3f16.6,f13.2,4x,f7.3,' =='/
     + 8x,'=================================================',
     +    '==========================================')
781   format(8x,'==',i3,' *',f9.3,3f16.6,f13.2,4x,f7.3,' =='/
     + 8x,'=================================================',
     +    '==========================================')
770    format(
     + 18x,'(*) Analyse Extrapolated Results in More Detail'/
     + 8x,'=================================================',
     +    '==========================================')
      end
      subroutine parkinc(core)
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
      dimension core(*)
c
c     allocate memory for mrdci pre-processor
c
      i10 = igmem_alloc(num*num)
c
      call defaults_mrdci(core(i10))
      call gmem_free(i10)
      return
      end
_ENDIF
      subroutine ver_inpci(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/inpci.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
