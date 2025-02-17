      subroutine g_rd2el(ptocc,orbsym,buf,bkt,ibkt,ni,nj,nk,nl,
     &                    ibktsp,lnbuf,idu,bkof1,bkof2,tfile,nbf,
     &                    lenbf,maxval)
      implicit REAL  (a-h,o-z)
      integer ptocc(nbf),orbsym(nbf)
      REAL buf(lnbuf),bkt(ibktsp)
      integer ibkt(ibktsp),ni(lnbuf),nj(lnbuf),nk(lnbuf),nl(lnbuf)
      integer idu(nbf),bkof1(16),bkof2(16),tfile(16)
c     
INCLUDE(common/sizes)
INCLUDE(common/filel)
INCLUDE(common/machin)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
      common /cor/ core
      common/blkin/gin(510),numi
_IF1(iv)      common/craypk/i205(340),j205(340),k205(340),l205(340)
_IFN1(iv)      common/craypk/i205(1360)
c     
c... this is the interface to the one and two electron integrals
c... reads them from transformed integral file
c
      call setsto(1360,0,i205)
      do 8 ifile=1,lfile
      iunit=lotape(ifile)
      call search(liblk(ifile),iunit)
      call find(iunit)
      lbl=llblk(ifile)
    6 lbl=lbl+1
      call get(gin(1),mw)
      if(mw.eq.0) go to 8
      if(lbl.ne.0) call find(iunit)
      icnt=0
_IF1(iv)      call upak8v(gin(num2e+1),i205)
_IFN1(iv)      int4=1
_IFN1(iv)      call unpack(gin(num2e+1),lab816,i205,numlab)
      do 30 num=1,numi
_IF(ibm,vax)
      i=i205(num)
      j=j205(num)
      k=k205(num)
      l=l205(num)
_ELSEIF(littleendian)
      j=i205(int4  )
      i=i205(int4+1)
      l=i205(int4+2)
      k=i205(int4+3)
_ELSE
      i=i205(int4  )
      j=i205(int4+1)
      k=i205(int4+2)
      l=i205(int4+3)
_ENDIF
      newi=ptocc(i)
      isnew=orbsym(newi)
      newj=ptocc(j)
      jsnew=orbsym(newj)
      ijsnw=IXOR32(isnew,jsnew)
      newk=ptocc(k)
      ksnew=orbsym(newk)
      newl=ptocc(l)
      lsnew=orbsym(newl)
      klsnw=IXOR32(ksnew,lsnew)
      if (ijsnw.eq.klsnw)then
       icnt=icnt+1
       newij=IOR32(min(newi,newj),ishft(max(newi,newj),8))
       ijov=IOR32(idu(min(newi,newj)),ishft(idu(max(newi,newj)),1))
       ni(icnt) = newij
       nj(icnt) = ijov
       nk(icnt) = max(newk,newl)
       nl(icnt) = min(newk,newl)
       buf(icnt)=gin(num)
      endif
_IFN1(iv)      int4=int4+4
   30 continue
      call prcss(buf,bkt,ibkt,ni,nj,nk,nl,icnt,ibktsp,lnbuf,
     &             idu,bkof1,bkof2,tfile,nbf,lenbf,maxval)
      if(lbl.ne.0) go to 6
    8 continue
c
      return
      end
      subroutine g_rd1el(ptocc,orbsym,honeel,nbf)
      implicit REAL  (a-h,o-z)
      integer ptocc(*),orbsym(*),nbf
      REAL honeel(*)
c     
INCLUDE(common/sizes)
      common /cor/ core
      common/blkin/gin(510),numi
INCLUDE(common/filel)
INCLUDE(common/discc)
INCLUDE(common/machin)
INCLUDE(common/iofile)
INCLUDE(common/savem)
      common/junk/occ(maxorb),potn,corree,ncolo(3),ncore,
     *mapcie(maxorb),map2(maxorb),nactt,mapaie(maxorb),mapaei(maxorb)
     *,iqsec
_IF(linux)
      external fget
_ENDIF
c...
c... restore 1-elec integrals
c...
      call secget(nsecor,1004,jblkk)
      call rdedx(occ,mach(15),jblkk,idaf)
      write(iwr,1100)nsecor,ibl3d,yed(idaf)
1100  format(
     */' transformed 1-electron integrals restored from section',i4,/,
     *' of dumpfile starting at block',i8,' of ',a4)
      core=corree
      nin=0
      jblkk=jblkk+lensec(mach(15))
      call search(jblkk,idaf)
      call fget(gin,kword,idaf)
      do i=1,nbf
      inew=ptocc(i)
      isnew=orbsym(inew)
      do j=1,i
      jnew=ptocc(j)
      jsnew=orbsym(jnew)
      nin=nin+1
      if(nin.gt.kword)then
       call fget(gin,kword,idaf)
       nin=1
      endif
      ij = ((max(inew,jnew)-1)*max(inew,jnew))/2 + min(inew,jnew)
c      print *,'i,j,inew,jnew,isnew,jsnew,nin ',
c     &         i,j,inew,jnew,isnew,jsnew,nin,gin(nin)
      if(isnew.eq.jsnew)then
        honeel(ij)=gin(nin)
      else
        honeel(ij)=0.0d00
      endif
      enddo
      enddo
      return
      end
      subroutine titandrv(q,energy)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/statis)
INCLUDE(common/segm)
INCLUDE(common/iofile)
      common/t_adata/a0,a1,a2,a3,a4,a5,a6,a9,ap5
c
      character*10 charwall
      dimension q(*)
      call cpuwal(begin,ebegin)
      write(iwr,1100)
 1100 format(/1x,104('=')/
     *40x,22('*')/
     *40x,'coupled cluster module'/
     *40x,22('*')//)
c
      ibase = igmem_alloc_all(lword)
c
      if(lword.lt.1)call caserr(
     +        'insufficient memory for coupled cluster module')
c
c set t_adata
c
      a0 = 0.0d0
      a1 = 1.0d0
      a2 = 2.0d0
      a3 = 3.0d0
      a4 = 2.0d0
      a5 = 3.0d0
      a6 = 6.0d0
      a9 = 9.0d0
      ap5= 0.5d0
c
      call titandrv2(q(ibase),lword,energy)
c
      at=cpulft(1)
      write(iwr,1300) at ,charwall()
 1300 format(/1x,'end of coupled cluster module at',f10.2,' seconds'
     *,a10,' wall'/
     */1x,104('=')/)
      call clredx
      call timana(29)
      call gmem_free(ibase)
      return
      end
      subroutine titandrv2(q,llword,energy)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension q(llword)
      common /mccore/ intrel,lword,ltop,lmax,lmin
      common /ftimes / t(10)
INCLUDE(common/savem)
INCLUDE(common/iofile)
      common /cor/ core
INCLUDE(common/runlab)
c
      integer nsymx,noccx(8),nvirx(8)
      REAL potnucx
c
      integer nccit,iccty,iccth
      common/tit_inp/nccit,iccty,iccth
c
c
      call gettim(startc,starte)
      lword = llword
      call initcc(q,lword,potnucx,ncorx)
      if (nact.gt.maxorb .or.nna.ne.nnb.or.nna.le.0)then
        write(iwr,*) nact,nna,nnb
        call caserr('invalid parameters in ccsd module')
      endif
      write (iwr,30) nact,nna-ncorx,isss,(itype(i),i=1,nact)
30    format(/
     &' number of orbitals          =',i3/
     &' number of occupied orbtials =',i3/
     &' space symmetry              =',i3//
     &' orbital symmetries           '/3(40i2/1x)/)
      write (iwr,40) lword
40    format(' memory available =',i10,' reals'/)
c
      call icopy(8,0,0,noccx,1)
      call icopy(8,0,0,nvirx,1)
      nsymx=0
      do i=1,nna-ncorx
       is=itype(i)
       noccx(is)=noccx(is)+1
      enddo
      do i=nna-ncorx+1,nact
       is=itype(i)
       nvirx(is)=nvirx(is)+1
      enddo
      is=8
      do while(noccx(is).eq.0.and.nvirx(is).eq.0)
       is=is-1
      enddo
      nsymx=1
      do while(nsymx.lt.is)
       nsymx=nsymx*2
      enddo
      write(iwr,50)(noccx(i),i=1,nsymx)
 50   format(' occupied per symmetry ',8i4)
      write(iwr,60)(nvirx(i),i=1,nsymx)
 60   format(' virtual per symmetry  ',8i4)
c
      call flushn(iwr)
      call tsort(q,q,lword,nsymx,noccx,nvirx,potnucx,itype)
      call flushn(iwr)
      iconvi=iccth
      maxit=nccit+1
      if (iccty.eq.1)iopt=0
      if (iccty.eq.2)iopt=3
      if (iccty.eq.3)iopt=5
      if (iccty.eq.4)iopt=6
      call vccsd(q,q,lword,iconvi,maxit,iopt,energy)
      call flushn(iwr)
      return
      end
      subroutine initcc(q,lword,potnucx,ncorx)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      REAL potnucx
      parameter (mxorb1=maxorb+1)
INCLUDE(common/machin)
INCLUDE(common/runlab)
INCLUDE(common/iofile)
INCLUDE(common/discc)
      common/junk/pop(maxorb),potn,core,ncolo(3),ncore,
     *mapcie(maxorb),map2(maxorb),nactt,mapaie(maxorb),mapaei(maxorb)
     *,iqsec,nacta(maxorb),nactb(maxorb),nactc(5),isecor,
     *evalue(maxorb),eocc(mxorb1),nbas,newb,ncol,ieval,ipop,ispp
     *,nirr,mult(8,8),isymao(maxorb),isymmo(maxorb),nsp
INCLUDE(common/filel)
INCLUDE(common/restar)
      common/restri/nfils(63),lda(508),isect(508),ldx(508)
      common/junkc/zjob,zdate,ztime,zprog,ztype,zspace(14),ztext(10)
INCLUDE(common/savem)
      dimension q(*)
      data thresh/1.0d-5/
      data m0/0/
      data m51,m29/51,29/
      data wwww/0.0d0/
c
      nav=lenwrd()
      i=inicor(lword)
      call secget(isect(470),1005,iblka)
      call readi(nacta,mach(14)*nav,iblka,idaf)
      call timer(wwww)
      nsecor=isecor
      call secget(isecor,1004,iblka)
      call rdedx(pop,mach(15),iblka,idaf)
      write(iwr,5004) yed(idaf),ibl3d,isecor
 5004 format(/1x,'dumpfile resides on ',a4,' at block ',i6/
     * 1x,'core hamiltonian to be retrieved from section ',i4)
      write(iwr,2)nact,ncore,potn,core
    2 format(1x,'header block information :'/
     *       1x,'=========================='/
     *       1x,'number of active orbitals ',i4/
     *       1x,'number of core   orbitals ',i4/
     *       1x,'nuclear repulsion energy ',e21.12/
     *       1x,'core energy              ',e21.12)
      potnucx=core
      ncorx=ncore
      if(nact.gt.1) go to 10005
      call caserr('invalid number of active orbitals')
80010 call caserr('parameter error in ccsd preprocessor')
10005 do 82003 i=1,nact
      j=mapaie(i)
82003 mapaei(j)=i
      lfile=m6file
      do 60001 i=1,lfile
      lotape(i)=m6tape(i)
      liblk  (i)=m6blk(i)
60001 llblk  (i)=liblk(i)-m6last(i)
      nact=nactt
      call secget(isect(490),m51,iblka)
      call readi(nirr,mach(13)*nav,iblka,idaf)
      call setsto(nact,m0,itype)
      call secget(iqsec,3,iblka)
      call rdchr(zjob,m29,iblka,idaf)
      call reads(evalue,mach(8),idaf)
      write(iwr,89005) iqsec,ztype,ztime,zdate,zjob,ztext,nbas,ncol
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
      write(iwr,1)
 1    format(/1x,'transformed integral files'/1x,26('*'))
      call filprn(m6file,m6blk,m6last,m6tape)
      return
      end
      subroutine ccsdin
      implicit REAL  (a-h,o-z),integer (i-n)
      character *8 ztext
      character *4 itext,ifd
INCLUDE(common/sizes)
c     **** input routine for ccsd ****
INCLUDE(common/direc)
INCLUDE(common/machin)
      common/infoa/nat(2),mul,num,nxx,nelec,naa,nbb
      common/data1/vlist(400),newpro(206),louta(2,maxorb),norbt,
     * norbta(maxorb),norbtp,norbc
      common/scfwfn/cicoef(699),nop(10),nco,nseto,npair
     *,ibms(4),nope
INCLUDE(common/restar)
INCLUDE(common/savem)
INCLUDE(common/work)
      common/timez/timlim,ti(3),safety(6),isecss
INCLUDE(common/iofile)
      integer nccit,iccty,iccth
      common/tit_inp/nccit,iccty,iccth
      dimension ifd(6)
      data ifd/
     * 'ccit','ccty','ccth','****','****','****'/
c
c
      top=cpulft(1)
      write(iwr,444)top
 444  format(//1x,104('=')//
     *' **** coupled cluster input processor called at',f9.2,' secs')
      if(jump.eq.1) then
c       mspin=mul
        nint=nelec-nope-npair-npair
        nint=nint/2-norbc
        if(nseto.ne.0)then
          do 8002 i=1,nseto
8002      nint=nint+nop(i)
        endif
        nint=nint+npair+npair
        next=norbt-nint
        nact = nint+next
        nna = naa -norbc
        nnb = nbb - norbc
      else
        call inpi(nact)
        call inpi(nna)
        call inpi(nnb)
      endif
      write(iwr,446)nact,nna,nnb
446   format(/' # orbitals       =',i6,
     *//      ' # alpha electrons=',i6,
     *//      ' # beta electrons =',i6)
      if(nact.gt.maxorb)call caserr(
     * 'invalid number of active orbitals')
      if(nnb.ne.nna.or.nnb.lt.1)call caserr(
     * 'invalid number of electrons (CCSD closed shell only)')
c
      nna = nna + norbc
      nnb = nnb + norbc
      isss = 1
      nccit=20
      iccth=10
      jrec = 0
      call inpa(ztext)
      if(ztext.eq.'ccsd(t)' ) then
       iccty = 2
      else if (ztext.eq.'qcisd') then
       iccty = 3
      else if (ztext.eq.'qcisd(t)') then
       iccty = 4
      else
       iccty = 1
      endif
93    call input
c.... see what password is on it
      call inpa4(itext)
      ii=locatc(ifd,3,itext)
      if (ii.gt.0) go to 99
      jrec=jrec-1
      ii = locatc(ydd(101),limit2,itext)
      if(ii)9995,9996,9995
 9996 call caserr(
     *'unrecognised directive or invalid directive sequence')
c.... go to proper place
99    go to (3,4,5),ii
c.... iterations
 3    call inpi(nccit)
      if(nccit.le.0)nccit=20
      go to 93
c.... cc type
 4    call inpi(iccty)
      if(iccty.le.0.or.iccty.ge.5)iccty=1
      go to 93
c.... threshold
 5    call inpi(iccth)
      if(iccth.le.0)iccth=10
      go to 93
c
9995  continue
c
      return
      end
      subroutine ver_ccsd(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/ccsd.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
