c 
c  $Author: wab $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/derdrv.m,v $
c  $State: Exp $
c  
      subroutine dertwo(q,iq)
c
c     driving routine for analytic second derivatives
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/cigrad)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/timez)
INCLUDE(common/statis)
INCLUDE(common/prnprn)
INCLUDE(common/ghfblk)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
_ENDIF
      common/maxlen/maxq
      character*10 charwall
      dimension q(*),iq(*)
      logical open,clos,ghf,oecp
      character *8 blank,grhf,oscf,closed
      character *8 fnm
      character *6 snm
      data fnm/'derdrv.m'/
      data snm/'dertwo'/
      data blank/' '/
      data grhf/'grhf'/
      data oscf,closed/'oscf','closed'/
      data ten/10.0d0/
      len = nat*nat*9
      lds(isect(46)) = len
      leng = lensec(len)
      maxq = igmem_max_memory() 
     +     - memreq_pg_dgop(3*nat*nx,'+')
     +     - 2*igmem_overhead()
      ibase  = igmem_alloc_inf(maxq,fnm,snm,'ibase1',IGMEM_NORMAL)
      iibase = lenrel(ibase-1)+1
      mmaxq = maxq
      if (.not.mp2) then
         call secput(isect(46),46,leng,isec46)
         call vclr(q(ibase),1,len)
         call wrt3(q(ibase),len,isec46,ifild)
         call revind
      else
         call secget(isect(110),110,isec46)
      end if
      call timit(3)
      ghf = scftyp.eq.grhf
      open = scftyp.eq.oscf
      clos = scftyp.eq.closed
      oecp = lpseud.ne.0
      write (iwr,6010)
      if (irest.le.7) then
c
         call revise
         if ((timlim-tim).lt.ten) go to 30
      end if
c
      if (irest.le.7) then
         irest = 7
         call revise
         if ((timlim-tim).lt.ten) go to 30
c
         write (iwr,6020) cpulft(1) ,charwall()
         len60 = lensec(nat*9*nat)
         call secput(isect(60),60,len60,iblko)
         call vclr(q(ibase),1,len)
         call wrt3(q(ibase),len,iblko,ifild)
         lds(isect(60)) = nat*nat*9
         call revind
         if (clos) call ovlcl(q(ibase),iq(iibase))
         if (open) call ovlop(q(ibase),iq(iibase))
      end if
      if (irest.le.8) then
         irest = 8
         call revise
         if (clos) call chfcla(q(ibase),iq(iibase))
         if (open) call chfopa(q(ibase),iq(iibase))
         if (ghf) call wgrhf(q(ibase),iq(iibase),erga,ergb)
         if(odebug(30)) write (iwr,6030)
         fkder = blank
         call timit(3)
         write (iwr,6040) cpulft(1) ,charwall()
      end if
c
c
      call cpuwal(begin,ebegin)
      if (irest.le.9) then
         irest = 9
c
c    contributions accumulate on section 46
c    if mp2 is not set these will accumulate on zero
         if (oecp) then
c         ecp contribution
          call dr2ecp(q(ibase),isec46)
         endif
c    nuclear contribution
         call dr2nc0(q(ibase),odebug,iwr,isec46,ifild)
c
         call revise
         if ((timlim-tim).lt.ten) go to 30
         call secget(isect(60),60,isec60)
         call rdedx(q(ibase),lds(isect(60)),isec60,ifild)
         call rdedx(q(ibase+len),lds(isect(46)),isec46,ifild)
         do 20 ji = 0 , len-1
            q(ibase+len+ji) = q(ibase+len+ji) + q(ibase+ji)
 20      continue
c
         call wrt3(q(ibase+len),lds(isect(46)),isec46,ifild)
c
         write (iwr,6050) cpulft(1) ,charwall()
         call dr2ovl(q(ibase),iq(iibase),nshell,isec46)
      end if
      if (irest.le.10) then
         irest = 10
         call revise
         call dr2ke(q(ibase),iq(iibase),nshell,isec46)
      end if
      if (irest.le.11) then
         irest = 11
         call revise
         call dr2pe(q(ibase),iq(iibase),nshell,isec46)
         call timit(3)
         write (iwr,6060) cpulft(1) ,charwall()
         ist = 1
         jst = 1
         kst = 1
         lst = 1
         nrec = 1
         intloc = 1
      end if
c
c
      call timana(23)
      irest = max(13,irest)
      call revise
      call gmem_free_inf(ibase,fnm,snm,'ibase1')
      maxq = mmaxq
      if ((timlim-tim).ge.ten) then
c
c     two electron contibution
c
         call cpuwal(begin,ebegin)
_IF(ccpdft)
         ierror = CD_set_2e()
         call dr2dft(q,iq,isec46)
_ENDIF
         maxq = igmem_max_memory() 
     +        - memreq_pg_dgop(3*nat*nx,'+')
     +        - 2*igmem_overhead()
         ibase = igmem_alloc_inf(maxq,fnm,snm,'ibase2',IGMEM_NORMAL)
         iibase = lenrel(ibase-1)+1
         call dr2int(q(ibase),iq(iibase),iq(iibase),nshell,
     +               iq(iibase),isec46)
         call gmem_free_inf(ibase,fnm,snm,'ibase2')
         maxq = mmaxq
_IF(ccpdft)
         ierror = CD_reset_2e()
_ENDIF
         call timana(24)
         write (iwr,6070) cpulft(1) ,charwall()
      end if
      return
c
c
 30   call clredx
      write (iwr,6080) irest
      call timit(3)
      write (iwr,6070) cpulft(1) ,charwall()
      call gmem_free_inf(ibase,fnm,snm,'ibase')
      maxq = mmaxq
      call clenms('restart job')
 6010 format (//1x,104('-')//40x,27('*')/40x,
     +        'analytic second derivatives'/40x,27('*'))
 6020 format (/' commence coupled hartree-fock calculation at ',f8.2,
     +        ' seconds',a10,' wall')
 6030 format (/1x,'hamfile and m.o. integrals no longer required')
 6040 format (/' end of coupled hartree-fock calculation at ',f8.2,
     +        ' seconds',a10,' wall')
 6050 format (//1x,35('*')/1x,'1-electron 2nd-derivative integrals'/1x,
     +        35('*')//
     +        ' commence 1-electron derivative integral evaluation at ',
     +        f8.2,' seconds',a10,' wall')
 6060 format (/' end of 1-electron derivative integral evaluation at ',
     +        f8.2,' seconds',a10,' wall')
 6070 format (//' end of analytic 2nd-derivatives at ',f8.2,' seconds'
     +        ,a10,' wall')
 6080 format (//' insufficient time to continue, irest=',i4)
      end
_IFN(mp2_parallel)
      subroutine emp23(q,e)
c
c     driving routine for mp2 and mp3 energy calculations
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      logical orest
      dimension q(*),array(10)
c
INCLUDE(common/segm)
      common/maxlen/maxq
INCLUDE(common/timez)
INCLUDE(common/cigrad)
c
      logical lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis
      common/scfblk/en,etot,ehf,sh1(2),sh2(2),gap1(2),gap2(2),
     1              d12,d13,d23,canna,cannb,cannc,fx,fy,fz,
     2              lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis,
     3              ncyc,ischm,lock,maxit,nconv,npunch,lokcyc
c
INCLUDE(common/vectrn)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
c
INCLUDE(common/infoa)
INCLUDE(common/mapper)
c
      common/junke/maxt,ires,ipass,nteff,
     1     npass1,npass2,lentri,nbuck,mloww,mhi,ntri,iacc,iontrn
c
INCLUDE(common/prnprn)
INCLUDE(common/restrj)
INCLUDE(common/disp)
c
      character *8 closed,hfsc
      character *8 fnm
      character *5 snm
      data fnm/'derdrv.m'/
      data snm/'emp23'/
      data closed/'closed'/
c     character *8 oscf,grhf,blank,scf
c     data blank,scf,oscf,grhf/'        ','scf','oscf','grhf'/
      data m1,m10,m13,m16/1,10,13,16/
      data hfsc/'hfscf'/
c
c     evaluate integrals
c
      if (opass2) then
       if(nopk.eq.0.or.nopk.ne.nopkr.or.iofsym.eq.1.or.
     +    iofrst.ne.iofsym) then
        write (iwr,6020)
        opass2 = .false.
       endif
      endif
      nopk = 1
      iofsym = 0
      isecvv = isect(8)
      itypvv = 8
      nconv = max(nconv,7)
      orest = .false.
      if (mp2 .or. mp3) then
         call timit(3)
         t1 = tim
      end if
      if (.not.((mp2 .or. mp3) .and. mprest.ge.1)) then
c
c  calculate hf energy
c
         call integ(q)
         call revise
         if (odisp) then
            call dispvec(q)
         else
            call scfrun(q)
         end if
c  allow for incomplete scf i.e. maxcyc exceeded
         if (irest.ge.2) then
          orest = .true.
         else
          irest = 5
         endif
         call revise
      end if
      if (mp2 .or. mp3) then
         call timit(3)
         timscf = tim - t1
         mprest = max(1,mprest)
         call revise
         if (cpulft(0).ge.timscf.and..not.orest) then
c
            ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',
     +                                  IGMEM_NORMAL)
            mmaxq = maxq
            maxq = mword
c
            call mptran(q(ibase))
            if (.not.(mp2)) then
               call gmem_free_inf(ibase,fnm,snm,'ibase')
               call uhfmp3(q,q)
               ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',
     +                                     IGMEM_NORMAL)
            else if (scftyp.ne.closed) then
               call gmem_free_inf(ibase,fnm,snm,'ibase')
               call uhfmp2(q,q)
               ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',
     +                                     IGMEM_NORMAL)
            else
               call mp2eng(q(ibase),ncore,nvr)
            end if
            array(1) = en
            array(2) = ehf
            array(3) = etot
            do loop = 4,10
              array(loop) = 0.0d0
            enddo
            call secput(isect(494),m16,m1,iblk9)
            call wrt3(array,m10,iblk9,ifild)
            mprest = 3
c
c ====  this restart needs attention ====
c
            irest = 0
            if (runtyp.eq.hfsc) mprest = 0
            e = etot
c
c     ----- reset core allocation
c
            call gmem_free_inf(ibase,fnm,snm,'ibase')
            maxq = mmaxq
         else
            write (iwr,6010) mprest
            call clenms('restart job')
         end if
c
      end if
c
c    read energy from dumpfile
c
      call secget(isect(13),m13,isec13)
      call rdedx(en,lds(isect(13)),isec13,ifild)
c     write(iwr,50) etot
c50    format(/1x,'energy =',f20.8)
      e = etot
      call revise
      return
 6010 format (//'insufficient time , restart parameter =',i5)
 6020 format(/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/
     + 1x,'= integrals must NOT be in supermatrix form ='/
     + 1x,'=        requested bypass is ignored        ='/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/)
      end
      subroutine grmp23(q,eg)
c
c     driving routine for mp2 and mp3 gradient calculations
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension eg(*)
      dimension q(*)
INCLUDE(common/segm)
      common/maxlen/maxq
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
c
INCLUDE(common/cigrad)
INCLUDE(common/infoa)
c
      character *8 closed
      data closed /'closed'/
c
      call vclr(eg,1,nat*3)
c
      if (mp2 .and. mprest.le.3) then
         if (scftyp.eq.closed) then
            call mpgrad(q,q)
         else
            call uhfmp2(q,q)
         end if
         mprest = 4
         call revise
      end if
c
      if (mp3 .and. mprest.le.3) then
         call uhfmp3(q,q)
         mprest = 4
         call revise
      end if
c
c     calculate gradient
c
      call hfgrdn(q)
      call secget(isect(14),14,iblok)
      call rdedx(eg,lds(isect(14)),iblok,ifild)
c
      if (lmcscf) mcrest = 0
      if (mp2 .or. mp3) mprest = 0
      call revise
      return
      end
_ENDIF(mp2_parallel)
      subroutine hfgrdn(q)
c
c     calculate one scf gradient
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/prnprn)
INCLUDE(common/funct)
INCLUDE(common/runlab)
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
     +             nnfile,nofile(4),jblk(4),mblk(4),
     +             mmfile,nufile(4),kblk(4),nblk(4),
     +             ione(12),lone(12),
     +             lds(508),isect(508),ldsect(508)
c
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/restrj)
INCLUDE(common/timez)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/grad2)
INCLUDE(common/machin)
      dimension q(*)
      character *8 fkd
c     character *8 grad1
c     data grad1/'gradone'/
      data dzero/0.0d0/
      data fkd/'fockder'/
      data m17/17/
      maxn3 = maxat*3
      do 20 ijr = 1 , maxn3
         egrad(ijr) = dzero
 20   continue
      call timit(3)
      if ((timlim-tim).le.3.0d0) then
         write (iwr,6010)
         call clenms('restart job')
      else
         if (fkder.eq.fkd .and. odebug(30) ) then
            write (iwr,6020)
         end if
         if (.not. opass8 ) then
c
c     allocate gradient section on dumpfile
c
            ncoord = 3*nat
            nc2 = ncoord*ncoord
            isize = lensec(nc2) + lensec(mach(7))
            call secput(isect(495),m17,isize,ibl3g)
            ibl3hs = ibl3g + lensec(mach(7))
c
            if (irest.le.5) call hfgrad(zscftp,q)
         end if
         opass8 = .false.
         call dcopy(maxn3,de,1,egrad,1)
         call putgrd(egrad)
         return
      end if
 6010 format (//10x,'insufficient time to continue'//)
 6020 format (/1x,'keepfock option set')
      end
      subroutine hfpder(q)
c
c     driving routine for polarisability derivatives
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
c
      common/maxlen/maxq
INCLUDE(common/segm)
INCLUDE(common/statis)
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
      logical lfokab
      common/specal/ndenin,iflden,iblden,iflout,ibdout,lfokab
INCLUDE(common/mapper)
      common/scfopt/maxcyc,mconv,nconv
c
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
      common/junke/ibl5,ibl54,ibl56,maxt,ires,ipass,nteff,
     1     npass1,npass2,lentri,nbuck,mloww,mhi,ntri,iacc,iontrn
c
INCLUDE(common/prnprn)
INCLUDE(common/restrj)
c
      character *8 fkd,blank,closed
      character *8 fnm
      character *6 snm
      data fnm/'derdrv.m'/
      data snm/'hfpder'/
      data fkd,blank /'fockder','        '/
      data closed/'closed'/
c
c
      if (scftyp.ne.closed .or. mp2) call caserr(
     +    ' polarisability derivatives only for closed-shell ')
c
c     evaluate integrals
c
      if (opass2) then
       if(nopk.eq.0.or.nopk.ne.nopkr.or.iofsym.eq.1.or.
     +    iofrst.ne.iofsym) then
        write (iwr,130)
        opass2 = .false.
       endif
      endif
      nopk = 1
      iofsym = 0
      isecvv = isect(8)
      itypvv = 8
      nconv = max(nconv,7)
      if (irest6.lt.1) then
         call integ(q)
         irest6 = 1
         call revise
      end if
      if (irest6.lt.2) then
         call scfrun(q)
         irest6 = 2
         call revise
      end if
      if (opass6 .and. (iscftp.lt.4)) call caserr(
     +    'less restricted 4-index transformation required ')
      if (.not.opass6) then
c
c  restrict the transformation
c
         iscftp = max(iscftp,4)
c
         npass1 = max(nps1,1)
         npass2 = max(nps2,1)
         iconvv = max(iconvv,9)
         lword4 = maxq
         call revise
      end if
c
c   do the 4-index transformation and set
c
      ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',IGMEM_NORMAL)
      mmaxq = maxq
      lword4 = mword
      maxq = mword
c
      call indxsy(q(ibase))
      oprn(4) = .false.
      if (irest6.lt.3) then
         call cpuwal(begin,ebegin)
         call indx2t(q(ibase))
         call indx4t(q(ibase))
         oprn(5) = oprn(14)
         irest6 = 3
         irest = 5
         call revise
         call timana(11)
      end if
      if (iscftp.lt.4) call caserr(
     +    'less restricted 4-index transformation required')
      if (irest6.lt.4) then
         fkder = fkd
c
         call gmem_free_inf(ibase,fnm,snm,'ibase')
c
         maxq = mmaxq
         call hfgrdn(q)
         irest6 = 4
         call revise
c
         ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',IGMEM_NORMAL)
         mmaxq = maxq
         maxq = mword
      end if
      if (irest6.lt.5) then
         call trnfkd(q(ibase))
         call gmem_free_inf(ibase,fnm,snm,'ibase')
         maxq = mmaxq
         call chfndr(q,q)
         ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',IGMEM_NORMAL)
         mmaxq = maxq
         maxq = mword
         fkder = blank
         call dmder(q(ibase))
         irest6 = 5
         irest = 5
         call revise
      end if
      if (irest6.lt.6) then
         ldiag = .true.
         np = 0
         do 20 i = 1 , 3
            if (ione(i+3).ne.0) then
               np = np + 1
               opskip(i) = .false.
               ipsec(i) = isect(i+21)
            end if
 20      continue
         npa = np
         call gmem_free_inf(ibase,fnm,snm,'ibase')
         maxq = mmaxq
         call poldrv(q,q)
         ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',IGMEM_NORMAL)
         mmaxq = maxq
         maxq = mword
         irestp = 0
         irest6 = 6
         call revise
      end if
      if (irest6.lt.7) then
c      fockabd
         lfokab = .true.
         fkder = blank
         ndenin = 3
         iscden = isect(31)
         m = 0
         call secget(iscden,m,iblden)
         if (iochf(18).eq.0) then
            ibdout = iochf(1)
            iochf(18) = iochf(1)
         else
            ibdout = iochf(18)
         end if
         iflden = ifild
         iflout = ifockf
c
         call gmem_free_inf(ibase,fnm,snm,'ibase')
         maxq = mmaxq
         irest = 5
         call hfgrdn(q)
c
         ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',IGMEM_NORMAL)
         mmaxq = maxq
         maxq = mword
         call revise
      end if
c
      maxq = maxq - 54*nat
      i0 = ibase + 27*nat
      i1 = i0 + 27*nat
      call pdrasm(q(ibase),q(i0),q(i1))
      irest = 0
      irest6 = 0
      lfokab = .false.
      ldiag = .false.
      call revise
      do 30 i = 1 , 9
         opskip(i) = .true.
 30   continue
c
c     ----- reset core allocation
c
      call gmem_free_inf(ibase,fnm,snm,'ibase')
      maxq = mmaxq
      return
 130  format(/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/
     + 1x,'= integrals must NOT be in supermatrix form ='/
     + 1x,'=        requested bypass is ignored        ='/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/)
      end
      subroutine mp2dd(q)
c
c     driving routine for mp2 second derivative calculations
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/cigrad)
c
      dimension q(*)
      common/maxlen/maxq
INCLUDE(common/segm)
INCLUDE(common/statis)
INCLUDE(common/vectrn)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/infoa)
INCLUDE(common/mapper)
      common/scfopt/maxcyc,mconv,nconv
c
      common/junke/ibl5,ibl54,ibl56,maxt,ires,ipass,nteff,
     1     npass1,npass2,lentri,nbuck,mloww,mhi,ntri,iacc,iontrn
c
INCLUDE(common/restrj)
c
      logical lsave
INCLUDE(common/prnprn)
      character *8 closed,fkd,blank
      character *8 gradie,xmp2sc
      character*8 fnm
      character*5 snm
      data fnm,snm/"derdrv.m","mp2dd"/
      data closed/'closed'/
      data fkd,blank /'fockder','        '/
      data gradie /'gradient'/
      data xmp2sc/'mp2sec'/
c
      if (mp2 .and. scftyp.ne.closed) call caserr(
     +    ' mp2 second derivative properties for closed shell only')
c
c     evaluate integrals
c
      if (opass2) then
       if(nopk.eq.0.or.nopk.ne.nopkr.or.iofsym.eq.1.or.
     +    iofrst.ne.iofsym) then
        write (iwr,130)
        opass2 = .false.
       endif
      endif
      nopk = 1
      iofsym = 0
      isecvv = isect(8)
      itypvv = 8
      nconv = max(nconv,7)
      if (mpflag.lt.8) then
         if (mpflag.lt.1) then
            call integ(q)
            mpflag = 1
            call revise
         end if
         if (mpflag.lt.2) then
            call scfrun(q)
            mpflag = 2
            call revise
         end if
         if (.not.(mpflag.ge.3 .or. opass6)) then
c
c  restrict the transformation
c
            iscftp = 99
c
            npass1 = max(nps1,1)
            npass2 = max(nps2,1)
            iconvv = max(iconvv,9)
            lword4 = maxq
            call revise
         end if
c
c   do the 4-index transformation and set
c   up the mp2 gradient
c
         oprn(4) = .true.
         ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',IGMEM_DEBUG)
         mmaxq = maxq
         maxq = mword
         lword4 = mword
         call indxsy(q(ibase))
         oprn(4) = .false.
         if (mpflag.lt.3) then
            call cpuwal(begin,ebegin)
            call indx2t(q(ibase))
            if (opass6 .and. iscftp.ne.99) call caserr(
     +          ' full transformation required -- set restrict 99 ')
            call indx4t(q(ibase))
            call timana(11)
            call mp2eng(q(ibase),ncore,nvr)
            mpflag = 3
            call revise
         end if
         if (iscftp.ne.99) call caserr(
     +    ' full transformation required -- set restrict 99')
         if (mpflag.lt.4) then
            call gmem_free_inf(ibase,fnm,snm,'ibase')
            maxq = mmaxq
            call mp2ddrv(q,q)
            ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',
     +                                  IGMEM_DEBUG)
            mmaxq = maxq
            maxq  = mword
            irest = 5
            mpflag = 4
            call revise
         end if
         if (mpflag.lt.5) then
            fkder = fkd
            mp2w = .true.
c
            call gmem_free_inf(ibase,fnm,snm,'ibase')
            maxq = mmaxq
c
            call hfgrdn(q)
c
            fkder = blank
            mp2w = .false.
            mpflag = 5
            call revise
c
            ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',
     +                                  IGMEM_DEBUG)
            mmaxq = maxq
            maxq = mword
         end if
         if (mpflag.lt.6) then
            call trnfkd(q(ibase))
            call gmem_free_inf(ibase,fnm,snm,'ibase')
            maxq = mmaxq
            call chfndr(q,q)
            mpflag = 6
            call revise
            if (rstop.eq.gradie) then
               write(iwr,*) ' stopping before derivative int sort '
               rstop = blank
               call revise
               call clenms('stop on request')
            end if
            ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',
     +                                  IGMEM_DEBUG)
            mmaxq = maxq
            maxq = mword
         end if
         if (mpflag.lt.7) then
            call gmem_free_inf(ibase,fnm,snm,'ibase')
            maxq = mmaxq
            call mp2ddrv(q,q)
            mpflag = 7
            irest = 7
            call revise
            if (rstop.eq.xmp2sc) then
               write(iwr,*) ' stopping before second deriv integrals '
               rstop = blank
               call revise
               call clenms('stop on request')
            end if
            ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',
     +                                  IGMEM_DEBUG)
            mmaxq = maxq
            maxq = mword
         end if
         if (mpflag.lt.8) then
            call gmem_free_inf(ibase,fnm,snm,'ibase')
            maxq = mmaxq
            lsave = oprn(5)
            oprn(5) = .false.
            call dertwo(q,q)
            ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',
     +                                  IGMEM_DEBUG)
            mmaxq = maxq
            maxq = mword
            oprn(5) = lsave
            mpflag = 8
            irest = 0
            call revise
         end if
      end if
      call gmem_free_inf(ibase,fnm,snm,'ibase')
      if(oprn(40)) call anairr(q)
c
c     ----- reset core allocation
c
      maxq = mmaxq
      return
 130  format(/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/
     + 1x,'= integrals must NOT be in supermatrix form ='/
     + 1x,'=        requested bypass is ignored        ='/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/)
      end
      subroutine mpdder(q)
c
c     driving routine for mp2 dipole moment derivative calculations
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
c
      common/maxlen/maxq
INCLUDE(common/segm)
INCLUDE(common/statis)
INCLUDE(common/vectrn)
      logical exist
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
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
     +             nnfile,nofile(4),jblk(4),mblk(4),
     +             mmfile,nufile(4),kblk(4),nblk(4),
     +             ione(12),lone(12),
     +             lds(508),isect(508),ldsect(508)
c
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/machin)
INCLUDE(common/restrj)
INCLUDE(common/mapper)
INCLUDE(common/nshel)
      common/scfopt/maxcyc,mconv,nconv
c
      common/junke/ibl5,ibl54,ibl56,maxt,ires,ipass,nteff,
     1     npass1,npass2,lentry,nbuck,mloww,mhi,ntri,iacc,iontrn
c
INCLUDE(common/symtry)
c
INCLUDE(common/infoa)
INCLUDE(common/runlab)
      logical mpsv
      common/crnams/  iangc(40),iangs(24)
      character *8 pnamc,ac6,pnams
      character *4 bfnam,atnam
      common/crnamx/ac6(6),pnamc(40),pnams(24),bfnam(20),atnam(37)
      dimension q(*)
      common/dipblk/dipd(3,3,maxat),dipn(3,3,maxat),dipi(3,3,maxat)
INCLUDE(common/prnprn)
INCLUDE(common/cslosc)
INCLUDE(common/ijlab)
      character *8 fkd,blank,polari,closed,oscf,grhf
      character*5 comp(3)
      character*8 fnm
      character*6 snm
      data fnm/"derdrv.m"/
      data snm/"mpdder"/
      data comp/'d/dx','d/dy','d/dz'/
      data fkd/'fockder'/,blank/'        '/
      data polari/'polariza'/
      data closed,oscf,grhf/'closed','oscf','grhf'/
      data m17/17/
c
      if (lci .or. lmcscf .or. mp3) call caserr(
     +'2nd derivative property unavailable for this correlated wavefunct
     +ion')
      if (mp2 .and. scftyp.ne.closed) call caserr(
     +    ' mp2 second derivative properties for closed shell only')
c
c     evaluate integrals
c
      if (opass2) then
       if(nopk.eq.0.or.nopk.ne.nopkr.or.iofsym.eq.1.or.
     +    iofrst.ne.iofsym) then
        write (iwr,130)
        opass2 = .false.
       endif
      endif
      nopk = 1
      iofsym = 0
      isecvv = isect(8)
      itypvv = 8
      nconv = max(nconv,7)
      if (mprest.lt.1) then
         call integ(q)
         mprest = 1
         call revise
      end if
      if (mprest.lt.2) then
         call scfrun(q)
         mprest = 2
         call revise
      end if
      if (opass6) then
         if (.not.mp2) then
            if ((scftyp.eq.closed .and. iscftp.lt.2) .or.
     +          (scftyp.eq.grhf .and. iscftp.lt.5) .or.
     +          (scftyp.eq.oscf .and. iscftp.lt.3)) opass6 = .false.
         else
            if (iscftp.lt.99) opass6 = .false.
         end if
      end if
      if (opass6) go to 20
c
c  restrict the transformation
c
      iscftp = 99
      if (.not.mp2 .and. (scftyp.ne.grhf)) iscftp = 3
      if (.not.mp2 .and. (scftyp.eq.grhf)) iscftp = 5
c
      if (ldiag) iscftp = max(iscftp,4)
      npass1 = max(nps1,1)
      npass2 = max(nps2,1)
      iconvv = max(iconvv,9)
      lword4 = maxq
c
c   do the 4-index transformation and set
c
 20   if (mprest.ge.3) oprn(4) = .false.
c
      ibase = igmem_alloc_all_inf(mword,fnm,snm,"indx4t",IGMEM_DEBUG)
      mmaxq = maxq
      maxq = mword
      lword4 = maxq
      call indxsy(q(ibase))
      oprn(4) = .false.
      if (mprest.lt.3) then
         call cpuwal(begin,ebegin)
         call indx2t(q(ibase))
         call indx4t(q(ibase))
         mprest = 3
         call revise
         call timana(11)
      end if
      if (.not.mp2) then
         if ((scftyp.eq.closed .and. iscftp.lt.2) .or.
     +       (scftyp.eq.grhf .and. iscftp.lt.5) .or.
     +       (scftyp.eq.oscf .and. iscftp.lt.3))
     +       call caserr(' less restricted transformation required')
      else
         if (iscftp.ne.99) call caserr(
     +     ' full 4-index transformation required')
      end if
      ipol = 1
c     write (iwr,6010) runtyp
      np = 0
      maxp = 9
      if (mp2) maxp = 3
      if (.not.ogen) then
         do 30 i = 1 , maxp
            if (ione(i+3).ne.0) then
               np = np + 1
               opskip(i) = .false.
               ipsec(i) = isect(i+21)
            end if
 30      continue
         npa = np
      end if
      mpsv = mp2
      mp2 = .false.
      write (iwr,6020)
      call dipmom(q(ibase))
      mp2 = mpsv
      if (mp2) ldiag = .true.
      call gmem_free_inf(ibase,fnm,snm,"indx4t")
      maxq = mmaxq
      call poldrv(q,q)
      if (.not.mp2) then
         mprest = 0
         irest = 0
         do 40 i = 1 , 9
            opskip(i) = .true.
 40      continue
         call revise
         return
      end if
      if (runtyp.ne.polari) write (iwr,6030)
c
c     get dipole and quadrupole for general interest
c
      call mp2dmd(q,q)
      if (runtyp.eq.polari) then
         mprest = 0
         do 50 i = 1 , 9
            opskip(i) = .true.
 50      continue
         call revise
         return
      end if
      ibase = igmem_alloc_all_inf(mword,fnm,snm,"dmdint",IGMEM_DEBUG)
      mmaxq = maxq
      maxq  = mword
      call dipmom(q(ibase))
      call dmdint(q(ibase),dipi,dipn,dipd)
      do 80 i = 1 , 3
         do 70 j = 1 , 3
            do 60 k = 1 , nat
               dipi(i,j,k) = 0.0d0
 60         continue
 70      continue
 80   continue
c
      len = lensec(27*maxat)
      call secput(isect(57),57,len,iblok)
      lds(isect(57)) = 27*maxat
      call wrt3(dipd,lds(isect(57)),iblok,ifild)
      call revind
      fkder = fkd
      oprn(9) = .false.
      oprn(10) = .false.
      call gmem_free_inf(ibase,fnm,snm,"dmdint")
      maxq = mmaxq
c
      call cpuwal(cpu,wall)
c
      call secloc(isect(495),exist,ibl3g)
      if (.not.exist) then
c
c     allocate gradient section on dumpfile
c
         ncoord = 3*nat
         nc2 = ncoord*ncoord
         isize = lensec(nc2) + lensec(mach(7))
         call secput(isect(495),m17,isize,ibl3g)
         ibl3hs = ibl3g + lensec(mach(7))
      end if
c
      i10 = igmem_alloc(nw196(5))
      iprefa = igmem_alloc(ikyp(nshell))
c
      call rdedx(q(i10),nw196(5),ibl196(5),ifild)
      dlntol = -dlog(10.0d0**(-icut))
      call rdmake(q(iprefa))
      call stvder(zscftp,q,q(iprefa),q(i10),nshell)
      call timana(6)
c
      nindmx = 0
      call cpuwal(cpu,wall)
      call spchck
      istd = 1
      do 90 i = 1 , nshell
         kad(i) = -1
 90   continue
      nindmx = 1
      onocnt = .true.
      fkder = blank
      call jkder(zscftp,q,q(iprefa),q(i10),nshell)
      call timana(7)
c
      call gmem_free(iprefa)
      call gmem_free(i10)
c
c
      call rdedx(dipd,lds(isect(57)),iblok,ifild)
      ibase = igmem_alloc_all_inf(mword,fnm,snm,"mpdmdw",IGMEM_DEBUG)
      mmaxq = maxq
      maxq = mword
      call mpdmdw(q(ibase),dipd)
      call gmem_free_inf(ibase,fnm,snm,"mpdmdw")
c
      iso = igmem_alloc(nw196(5))
      call rdedx(q(iso),nw196(5),ibl196(5),ifild)
      ict = igmem_alloc(lenint(nat*nt))
      call dmdsym(dipd,q(iso),q(ict),nat,nshell)
      call gmem_free(ict)
      call gmem_free(iso)
      call wrt3(dipd,lds(isect(57)),iblok,ifild)
      if(oprn(40)) then
      if (opunch(3)) write (ipu,6080)
      write (iwr,6040)
      do 110 n = 1 , nat
         write (iwr,6050)
         do 100 nc = 1 , 3
            if (opunch(3)) write (ipu,6070) (dipd(nn,nc,n),nn=1,3)
            write (iwr,6060) zaname(n) , comp(nc) , 
     +                       (dipd(nn,nc,n),nn=1,3)
 100     continue
 110  continue
      call dmdrot(c,dipd,nat)
      endif
      mprest = 0
      irest = 0
      call revise
      call delfil(20)
      call delfil(21)
      call delfil(22)
      do 120 i = 1 , 9
         opskip(i) = .true.
 120  continue
      oprn(10) = .true.
      return
 130  format(/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/
     + 1x,'= integrals must NOT be in supermatrix form ='/
     + 1x,'=        requested bypass is ignored        ='/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/)
c6010 format (/1x,'runtyp = ',a8)
 6020 format (//1x,'************************************'/1x,
     +        'scf dipole moment and polarisability'/1x,
     +        '************************************'/)
 6030 format (//1x,'****************************************'/
     +    1x, 'moller plesset dipole moment derivatives'/
     +    1x, '****************************************'/)
 6040 format
     +  (//20x,'mp2 dipole derivatives in atomic units'/
     +     20x,'**************************************'//
     +     30x,'x',15x,'y',15x,'z')
 6050 format (/)
 6060 format (5x,a8,5x,a5,3f16.8)
 6070 format (1x,3e20.12)
 6080 format (1x,'mp2 dipole derivatives')
      end
_IFN(secd_parallel)
      subroutine scfdd(q)
c
c     driving routine for scf second derivative calculations
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension q(*)
c
      common/maxlen/maxq
INCLUDE(common/segm)
INCLUDE(common/vectrn)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/infoa)
INCLUDE(common/mapper)
INCLUDE(common/statis)
      common/scfopt/maxcyc,mconv,nconv
c
      common/junke/maxt,ires,ipass,nteff,
     1     npass1,npass2,lentri,nbuck,mloww,mhi,ntri,iacc,iontrn
c
INCLUDE(common/restrj)
      logical lsave
INCLUDE(common/prnprn)
INCLUDE(common/timeperiods)
      character *8 fkd,blank,grhf,dipd
c     character *8 closed,oscf
      data fkd,blank /'fockder','        '/
      data grhf/'grhf'/
c     data closed,oscf/'closed','oscf'/
      data dipd /'dipder'/
c
c     evaluate integrals
c
      if (opass2) then
       if(nopk.eq.0.or.nopk.ne.nopkr.or.iofsym.eq.1.or.
     +    iofrst.ne.iofsym) then
        write (iwr,130)
        opass2 = .false.
       endif
      endif

      call start_time_period(TP_2D_TOTAL)

      nopk = 1
      iofsym = 0
      isecvv = isect(8)
      itypvv = 8
      nconv = max(nconv,7)
      mmaxq = maxq
      if (irest5.ge.6) then
         ibase = igmem_alloc_all(mword)
         maxq = mword
         lword4 = mword
         go to 30
      else
         if (irest5.lt.1) then
            call start_time_period(TP_2D_AOINTS)
            call integ(q)
            call end_time_period(TP_2D_AOINTS)
            irest5 = 1
            call revise
         end if
         if (irest5.lt.2) then
            call start_time_period(TP_2D_SCF)
            call scfrun(q)
            call end_time_period(TP_2D_SCF)
            irest5 = 2
            irest = 5
            call revise
         end if
         if (irest5.lt.3) then
            fkder = fkd
            call start_time_period(TP_2D_HFGRDN)
            call hfgrdn(q)
            call end_time_period(TP_2D_HFGRDN)
            irest5 = 3
            call revise
         end if
         if (opass6) then
            if ((scftyp.eq.grhf .and. iscftp.lt.5) .or.
     +          (scftyp.ne.grhf .and. iscftp.lt.3)) call caserr(
     +          'less restricted 4-index transformation required ')
            go to 20
         end if
c
c  restrict the transformation
c
         if (scftyp.eq.grhf) then
            iscftp = max(iscftp,5)
         else
            iscftp = max(iscftp,3)
         end if
c
         npass1 = max(nps1,1)
         npass2 = max(nps2,1)
         iconvv = max(iconvv,9)
         lword4 = maxq
c
         call revise
      end if
c
c   do the 4-index transformation and set
c
 20   oprn(4) = .false.
      ibase = igmem_alloc_all(mword)
      maxq = mword
      lword4 = mword
c
      call indxsy(q(ibase))
      if (irest5.lt.4) then
         call start_time_period(TP_2D_INDX2T)
         call cpuwal(begin,ebegin)
         call indx2t(q(ibase))
         call end_time_period(TP_2D_INDX2T)
         call start_time_period(TP_2D_MOINTS)
         call indx4t(q(ibase))
         call end_time_period(TP_2D_MOINTS)
         irest5 = 4
         call revise
         call timana(11)
      end if
      if (iscftp.lt.3 .or. (scftyp.eq.grhf .and. iscftp.lt.5))
     +    call caserr('less restricted 4-index transformation required')
      if (irest5.lt.5) then
         call start_time_period(TP_2D_TRNFKD)
         call trnfkd(q(ibase))
         call gmem_free(ibase)
         call end_time_period(TP_2D_TRNFKD)
         maxq = mmaxq
         call dksm_exp(q,q)
         call start_time_period(TP_2D_CHFNDR)
         call chfndr(q,q)
         call end_time_period(TP_2D_CHFNDR)
         ibase = igmem_alloc_all(mword)
         maxq = mword
         lword4 = mword
         fkder = blank
         call start_time_period(TP_2D_DMDER)
         call dmder(q(ibase))
         call end_time_period(TP_2D_DMDER)
         call start_time_period(TP_2D_QMDER)
         call qmderi(q(ibase))
         call end_time_period(TP_2D_QMDER)
         irest5 = 5
         irest = 7
         call revise
         if (runtyp.eq.dipd) go to 30
      end if
      if (irest5.lt.6) then
         lsave = oprn(5)
         oprn(5) = .false.
         call gmem_free(ibase)
         maxq = mmaxq
         call start_time_period(TP_2D_2D)
         call dertwo(q,q)
         call end_time_period(TP_2D_2D)
         ibase = igmem_alloc_all(mword)
         maxq = mword
         lword4 = mword
         oprn(5) = lsave
         irest5 = 6
         irest = 0
         call revise
      end if
c
      call end_time_period(TP_2D_TOTAL)
c
c     ----- reset core allocation
c
 30   call gmem_free(ibase)
      maxq = mmaxq
      return
 130  format(/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/
     + 1x,'= integrals must NOT be in supermatrix form ='/
     + 1x,'=        requested bypass is ignored        ='/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/)
      end
_ENDIF
_IFN(secd_parallel)
      subroutine dksm_exp(q,iq)
      implicit none
c
c     Construct and add the Kohn-Sham contributions to the explicit
c     derivatives of the Fock matrixes. I.e. derivatives with respect
c     to nuclear coordinates and no wavefunction contributions.
c
c     Parameters
c
INCLUDE(common/sizes)
c
c     Input
c
INCLUDE(common/common)
INCLUDE(common/mapper)
INCLUDE(common/debug)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/cndx41)
INCLUDE(common/drive_dft)
INCLUDE(common/atmblk)
INCLUDE(common/dump3)
c
c     Workspace:
c
      REAL q(*)
      integer iq(*)
c
c     Functions:
c
INCLUDE(common/ccpdft.hf77)
INCLUDE(common/gmempara)
      integer igmem_alloc_inf
      integer igmem_null
      integer lensec
c
c     Local:
c
      character *8 grhf,oscf,zfock
      data grhf/'grhf'/
      data oscf/'oscf'/
      data zfock/'fockder'/
      logical ofock,out
      integer i0,i1,i3,lennew,lenblk,newblk,nat3,ib2,i,nfok,ifok
      integer nblkq,iblkq,nincr
      integer ierror, inull
_IF(ccpdft)
      ofock = fkder.eq.zfock
      inull = igmem_null()
      if (CD_active().and.ofock) then
         lennew = iky(ncoorb)+ncoorb
         lenblk = lensec(nx)
         newblk = lensec(lennew)
         out = odebug(3) .or. odebug(4)
         nat3 = nat*3
c
c        Compute DFT contributions
c
         if (ks_dx_bas.eq.KS_DX_AO) then
c
c           create the fock matrices
c
            nincr = nx
            nfok  = nat3
            ifok  = igmem_alloc_inf(nincr*nfok,'derdrv.m','dksm_exp',
     &                              'der-fock',IGMEM_NORMAL)
            call vclr(q(ifok),1,nincr*nfok)
c
c           load the density matrix
c
            i1 = igmem_alloc_inf(nx,'derdrv.m','dksm_exp',
     &                           'alpha-dens-mat',IGMEM_NORMAL)
            call rdedx(q(i1),nx,ibl3pa,idaf)
c
c           calculate DFT contributions
c
            ierror = CD_dksm_exp_ao(iq,q,nfok,q(i1),q(inull),
     &                              q(ifok),q(inull),.false.,iwr)
c
c           load the KS vectors
c
            i0 = igmem_alloc_inf(num*num,'derdrv.m','dksm_exp',
     &                           'alpha-vectors',IGMEM_NORMAL)
            nblkq = num*ncoorb
            call secget(isect(8),8,iblkq)
            iblkq = iblkq + mvadd
            call rdedx(q(i0),nblkq,iblkq,ifild)
c
c           transform DFT contributions to MO-basis
c
            do i = 1, nfok
               i3 = ifok + (i-1)*nincr
               call qhq1(q(i1),q(i0),ilifq,ncoorb,q(i3),iky,num)
               call dcopy(lennew,q(i1),1,q(i3),1)
            enddo
c
            call gmem_free_inf(i0,'derdrv.m','dksm_exp','alpha-vectors')
            call gmem_free_inf(i1,'derdrv.m','dksm_exp',
     &                         'alpha-dens-mat')
c
         else if (ks_dx_bas.eq.KS_DX_MO) then
c
c           create the fock matrices
c
            nincr = lennew
            nfok  = nat3
            ifok  = igmem_alloc_inf(nincr*nfok,'derdrv.m','dksm_exp',
     &                              'der-fock',IGMEM_NORMAL)
            call vclr(q(ifok),1,nincr*nfok)
c
c           load the KS vectors
c
            i0 = igmem_alloc_inf(num*num,'derdrv.m','dksm_exp',
     &                           'alpha-vectors',IGMEM_NORMAL)
            nblkq = num*ncoorb
            call secget(isect(8),8,iblkq)
            iblkq = iblkq + mvadd
            call rdedx(q(i0),nblkq,iblkq,ifild)
c
c           calculate DFT contributions
c
            ierror = CD_dksm_exp_mo(iq,q,nfok,ncoorb,na,0,
     &               q(i0),q(inull),q(ifok),q(inull),.false.,iwr)
c
            call gmem_free_inf(i0,'derdrv.m','dksm_exp',
     &                         'alpha-vectors')
c
         else
            write(iwr,*)'dksm_exp: ks_dx_bas = ',ks_dx_bas
            call caserr('dksm_exp: ks_dx_bas has an illegal value!')
         endif
c
c        Add explicit derivative KS matrices onto stored quantities
c        derivatives of fock matrices (no wavefunction derivatives)
c        m.o. basis at section 13 of fockfile
c
         i1  = igmem_alloc_inf(lennew,'derdrv.m','dksm_exp','tmp-fock',
     &                         IGMEM_NORMAL)
         ib2 = iochf(13)
         i3  = ifok
         do i = 1 , nfok
            call rdedx(q(i1),lennew,ib2,ifockf)
            call daxpy(lennew,1.0d0,q(i3),1,q(i1),1)
            call wrt3(q(i1),lennew,ib2,ifockf)
            ib2 = ib2 + newblk
            i3  = i3  + nincr
         enddo
         call gmem_free_inf(i1,'derdrv.m','dksm_exp','tmp-fock')
         call gmem_free_inf(ifok,'derdrv.m','dksm_exp','der-fock')
c
         call revise
         call clredx
      endif
c
c     old junk:
c  
c     if (CD_active().and.ofock) then
c        i0 = igmem_alloc(num*num)
c        i1 = igmem_alloc(nx)
c        lennew = iky(ncoorb+1)
c        lenblk = lensec(nx)
c        newblk = lensec(lennew)
c        out = odebug(3) .or. odebug(4)
c        nat3 = nat*3
c        ib2 = iochf(13)
c
c        load vectors
c
c        nblkq = num*ncoorb
c        call secget(isect(8),8,iblkq)
c        iblkq = iblkq + mvadd
c        call rdedx(q(i0),nblkq,iblkq,ifild)
c
c        create the fock matrices
c
c        nfok = nat3
c        ifok = igmem_alloc(nx*nfok)
c        call vclr(q(ifok),1,nx*nfok)
c
c        calculate fock matrix contributions
c
c        if (.true.) then
c           call rdedx(q(i1),nx,ibl3pa,idaf)
c           ierror = CD_dksm_exp_ao(iq,q,nfok,q(i1),q(inull),
c    &                              q(ifok),q(inull),.false.,iwr)
c           do i = 1, nfok
c              i3 = ifok + (i-1)*nx
c              call qhq1(q(i1),q(i0),ilifq,ncoorb,q(i3),iky,num)
c              call dcopy(lennew,q(i1),1,q(i3),1)
c           enddo
c        endif
c
c        derivatives of fock matrices (no wavefunction derivatives)
c        m.o. basis at section 13 of fockfile
c
c        i3 = ifok
c        do i = 1 , nfok
c           call rdedx(q(i1),lennew,ib2,ifockf)
c           call daxpy(lennew,1.0d0,q(i3),1,q(i1),1)
c           call wrt3(q(i1),lennew,ib2,ifockf)
c           ib2 = ib2 + newblk
c           i3  = i3  + nx
c        enddo
c
c        call revise
c        call clredx
c
c        call gmem_free(ifok)
c        call gmem_free(i1)
c        call gmem_free(i0)
c     endif
      return
_ENDIF
      end
_ENDIF
      subroutine trndrv(q)
c
c     driving routine for hondo 4-index transformation
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension q(*)
c
      common/maxlen/maxq
INCLUDE(common/vectrn)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/infoa)
c
      common/scfopt/maxcyc,mconv,nconv
      common/junke/maxt,ires,ipass,nteff,
     1     npass1,npass2,lentri,nbuck,mloww,mhi,ntri,iacc,iontrn
c
INCLUDE(common/prnprn)
INCLUDE(common/statis)
INCLUDE(common/restrj)
c
c     character *8 fkd,blank,closed,oscf,grhf,dipd
c     data fkd,blank /'fockder','        '/
c     data closed,oscf,grhf/'closed','oscf','grhf'/
c     data dipd /'dipder'/
c
c     evaluate integrals
c
      if (opass2) then
       if(nopk.eq.0.or.nopk.ne.nopkr.or.iofsym.eq.1.or.
     +    iofrst.ne.iofsym) then
        write (iwr,130)
        opass2 = .false.
       endif
      endif
      nopk = 1
      iofsym = 0
      isecvv = isect(8)
      itypvv = 8
      nconv = max(nconv,7)
      if (irest5.lt.1) then
         call integ(q)
         irest5 = 1
      end if
      if (irest5.lt.2) then
         call scfrun(q)
         irest5 = 2
         irest = 5
         call revise
      end if
      if (.not.opass6) then
c
         npass1 = max(nps1,1)
         npass2 = max(nps2,1)
         iconvv = max(iconvv,9)
         lword4 = maxq
c
         call revise
c
c   do the 4-index transformation and set
c
         call indxsy(q)
         oprn(4) = .false.
         if (irest5.lt.4) then
            call cpuwal(begin,ebegin)
            call indx2t(q)
            call indx4t(q)
            irest5 = 4
            call revise
            call timana(11)
         end if
      end if
      call revind
      return
 130  format(/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/
     + 1x,'= integrals must NOT be in supermatrix form ='/
     + 1x,'=        requested bypass is ignored        ='/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/)
      end
_IFN(secd_parallel)
      subroutine trnfkd(q)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      logical out
INCLUDE(common/infoa)
      common/small/y(maxorb)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
      dimension q(*)
INCLUDE(common/mapper)
INCLUDE(common/atmblk)
INCLUDE(common/ghfblk)
INCLUDE(common/prnprn)
      character *8 grhf,oscf
      data grhf/'grhf'/
      data oscf/'oscf'/
c
c
      if (lfdtrn .or. irest.eq.1) then
        if ( odebug(30)) then
         write (iwr,6050)
         if (lfdtrn) write (iwr,6060)
         if (irest.eq.1) write (iwr,6070)
         write (iwr,6030)iochf(13),iochf(14)
        endif
       return
      end if
      if(odebug(30)) write (iwr,6040)
      i1 = num*num + 1
      i2 = i1 + nx
      lennew = iky(ncoorb+1)
      lenblk = lensec(nx)
      newblk = lensec(lennew)
      out = odebug(3) .or. odebug(4)
      nat3 = nat*3
      ib = iochf(11)
      ib2 = iochf(11)
      iochf(13) = ib2
      nblkq = num*ncoorb
      call secget(isect(8),8,iblkq)
      iblkq = iblkq + mvadd
c
c     derivatives of fock matrices (no wavefunction derivatives)
c     a.o. basis at section 11
c     m.o. basis at section 13 of fockfile
c    ******** section 13 overwrites section 11 *********
c
      if (out) then
         write (iwr,6010)
      end if
      call rdedx(q(1),nblkq,iblkq,ifild)
      max = nat3
      if (scftyp.eq.oscf) max = nat3 + nat3
      if (scftyp.eq.grhf) max = (njk+njk+1)*nat3
      do 20 i = 1 , max
         call rdedx(q(i2),nx,ib,ifockf)
         call qhq1(q(i1),q(1),ilifq,ncoorb,q(i2),iky,num)
         call wrt3(q(i1),lennew,ib2,ifockf)
         ib = ib + lenblk
         ib2 = ib2 + newblk
         if (out) then
            call prtris(q(i1),ncoorb,iwr)
         end if
 20   continue
      if (out) then
         write (iwr,6020)
      end if
      ib = iochf(12)
      ib2 = iochf(12)
      iochf(14) = ib2
c
c     derivatives of overlap matrix
c     a.o. basis at section 12
c     m.o. basis at section 14
c     ******** section 14 overwrites section 12
c
      do 30 i = 1 , nat3
         call rdedx(q(i2),nx,ib,ifockf)
         call qhq1(q(i1),q(1),ilifq,ncoorb,q(i2),iky,num)
         call wrt3(q(i1),lennew,ib2,ifockf)
         ib = ib + lenblk
         ib2 = ib2 + newblk
         if (out) then
            call prtris(q(i1),ncoorb,iwr)
         end if
 30   continue
      lfdtrn = .true.
      irest = 1
      call revise
      call clredx
      if(odebug(30)) write (iwr,6030)iochf(13),iochf(14)
      return
 6010 format (///5x,'transformed one-electron matrix derivatives'//)
 6020 format (///5x,'transformed overlap matrix derivatives'//)
 6030 format (/1x,'hamfile summary'/
     +         1x,'section 13 at block ',i5/
     +         1x,'section 14 at block ',i5)
 6040 format(/1x,'calling trnfkd')
 6050 format(/1x,'omitting call of trnfkd')
 6060 format(1x,'because lfdtrn is true')
 6070 format(1x,'because irest = 1')
      end
_ENDIF
      subroutine raman(q)
c
c     driving routine for raman intensities
c     closed-shell scf only
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      dimension q(*)
c
      common/maxlen/maxq
INCLUDE(common/segm)
INCLUDE(common/vectrn)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/infoa)
INCLUDE(common/mapper)
INCLUDE(common/statis)
      common/scfopt/maxcyc,mconv,nconv
      logical lfokab
      common/specal/ndenin,iflden,iblden,iflout,ibdout,lfokab
c
      common/junke/maxt,ires,ipass,nteff,
     1     npass1,npass2,lentri,nbuck,mloww,mhi,ntri,iacc,iontrn
c
INCLUDE(common/restrj)
      logical lsave
INCLUDE(common/prnprn)
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
      character *8 fkd,blank,closed
      character*8 fnm
      character*5 snm
      data fnm,snm/"derdrv.m","raman"/
      data fkd,blank /'fockder','        '/
      data closed/'closed'/
c
      if (scftyp.ne.closed .or. mp2) call caserr(
     +    'raman intensities only for closed-shell scf')
_IF(secd_parallel)
      call caserr('RAMAN is not yet available in PARALLEL')
_ENDIF
c
c     evaluate integrals
c
      if (opass2) then
       if(nopk.eq.0.or.nopk.ne.nopkr.or.iofsym.eq.1.or.
     +    iofrst.ne.iofsym) then
        write (iwr,130)
        opass2 = .false.
       endif
      endif
      nopk = 1
      iofsym = 0
      isecvv = isect(8)
      itypvv = 8
      nconv = max(nconv,7)
      mmaxq = maxq
      if (irest6.ge.10) then
         maxq = mword
         lword4 = mword
         oprn(40) = .true.
         call anairr(q)
         go to 300
      else
         if (irest6.lt.1) then
            call integ(q)
            irest6 = 1
            call revise
         end if
         if (irest6.lt.2) then
            call scfrun(q)
            irest6 = 2
            irest = 5
            call revise
         end if
         if (irest6.lt.3) then
            fkder = fkd
            call hfgrdn(q)
            irest6 = 3
            call revise
         end if
         if (opass6) then
            if (iscftp.lt.4) call caserr(
     +          'less restricted 4-index transformation required ')
         end if
c
c  restrict the transformation
c
         iscftp = max(iscftp,4)
c
         npass1 = max(nps1,1)
         npass2 = max(nps2,1)
         iconvv = max(iconvv,9)
         lword4 = maxq
c
         call revise
      end if
c
c   do the 4-index transformation and set
c
      oprn(4) = .false.
      ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',IGMEM_DEBUG)
      maxq = mword
      lword4 = mword
c
      call indxsy(q(ibase))
      if (irest6.lt.4) then
         call cpuwal(begin,ebegin)
         call indx2t(q(ibase))
         call indx4t(q(ibase))
         irest6 = 4
         call revise
         call timana(11)
      end if
      if (iscftp.lt.4) call caserr
     +     ('less restricted 4-index transformation required')
      call gmem_free_inf(ibase,fnm,snm,'ibase')
      maxq = mmaxq
      if (irest6.lt.5) then
         ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',IGMEM_DEBUG)
         maxq = mword
         lword4 = mword
         call trnfkd(q(ibase))
         call gmem_free_inf(ibase,fnm,snm,'ibase')
         maxq = mmaxq
         call chfndr(q,q)
         ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',IGMEM_DEBUG)
         maxq = mword
         lword4 = mword
         fkder = blank
         call dmder(q(ibase))
         call qmderi(q(ibase))
         call gmem_free_inf(ibase,fnm,snm,'ibase')
         maxq = mmaxq
         irest6 = 5
         irest = 7
         call revise
      end if
      if (irest6.lt.6) then
         lsave = oprn(5)
         oprn(5) = .false.
         call dertwo(q,q)
         oprn(5) = lsave
         irest6 = 6
         irest = 0
         call revise
      end if
      if( oprn(40)) call anairr(q)
c
c  ----- reset core allocation
c      now for the polarizability derivatives
c
      if (irest6.lt.7) then
         fkder = fkd
         maxq = mmaxq
         call hfgrdn(q)
         irest6 = 7
         call revise
      end if
      if (irest6.lt.8) then
         ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase8',IGMEM_DEBUG)
         mmaxq = maxq
         maxq = mword
         call trnfkd(q(ibase))
         call gmem_free_inf(ibase,fnm,snm,'ibase8')
         maxq = mmaxq
         call chfndr(q,q)
         ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase8',IGMEM_DEBUG)
         mmaxq = maxq
         maxq = mword
         fkder = blank
         call dmder(q(ibase))
         call gmem_free_inf(ibase,fnm,snm,'ibase8')
         maxq = mmaxq
         irest6 = 8
         irest = 5
         call revise
      end if
      if (irest6.lt.9) then
         ldiag = .true.
         np = 0
         do 20 i = 1 , 3
            if (ione(i+3).ne.0) then
               np = np + 1
               opskip(i) = .false.
               ipsec(i) = isect(i+21)
            end if
 20      continue
         npa = np
         call poldrv(q,q)
         irestp = 0
         irest6 = 9
         call revise
      end if
      if (irest6.lt.10) then
c      fockabd
         lfokab = .true.
         fkder = blank
         ndenin = 3
         iscden = isect(31)
         m = 0
         call secget(iscden,m,iblden)
         if (iochf(18).eq.0) then
            ibdout = iochf(1)
            iochf(18) = iochf(1)
         else
            ibdout = iochf(18)
         end if
         iflden = ifild
         iflout = ifockf
         irest = 5
         call hfgrdn(q)
         call revise
      end if
c
      maxq = maxq - 54*nat
      i0 = igmem_alloc_inf(27*nat,fnm,snm,'i0',IGMEM_DEBUG)
      i1 = igmem_alloc_inf(27*nat,fnm,snm,'i1',IGMEM_DEBUG)
      ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase11',IGMEM_DEBUG)
      mmaxq = maxq
      maxq = mword
      call pdrasm(q(i0),q(i1),q(ibase))
      call gmem_free_inf(ibase,fnm,snm,'ibase11')
      call gmem_free_inf(i1,fnm,snm,'i1')
      call gmem_free_inf(i0,fnm,snm,'i0')
      maxq = mmaxq
      irest = 0
      irest6 = 10
      lfokab = .false.
      ldiag = .false.
      call revise
      do 30 i = 1 , 9
         opskip(i) = .true.
 30   continue
c
      oprn(40) = .true.
      call anairr(q)
c
c     ----- reset core allocation
c
300   continue
      maxq = mmaxq
      return
 130  format(/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/
     + 1x,'= integrals must NOT be in supermatrix form ='/
     + 1x,'=        requested bypass is ignored        ='/
     + 1x,'= = = = = = = = = = = = = = = = = = = = = = ='/)
      end
      subroutine dispvec(q)
c
      implicit REAL  (a-h,o-z)
c
c...  read vectors for polarisation dispersion calc (simple monomer-monomer)
c
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      parameter (mxorb1=maxorb+1)
INCLUDE(common/disp)
INCLUDE(common/infoa)
INCLUDE(common/cndx41)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
INCLUDE(common/atmol3)
INCLUDE(common/harmon)
INCLUDE(common/machin)
_IF(mp2_parallel,masscf)
INCLUDE(common/dump3)
_ENDIF
c
      character *8 com,dtitle
      common/junkc/com(19),dtitle(10)
      logical iftran
      common/small/
     + ilifc(maxorb),ntran(maxorb),itran(mxorb3),ctran(mxorb3),
     + iftran,isp,
     + value(maxorb),occ(mxorb1),
     + nbasis,newbas,ncol,ivalue,iocc,ift
      common/blkorbs/deig(maxorb),dpop(maxorb),
     1             dumc,idumc(3),jeig,jpop,ipad
c..   common/blkorbs/ is used to get eigenvalues and occupations from getqvb
      dimension q(*)
      character*8 fnm
      character*7 snm
_IFN(vb)
      call caserr('Disp option currently requires vb-servec')
_ELSE
c...   save real dumpfile
      call ini_set_dump
c
      kvec = igmem_alloc_inf(num*num,fnm,snm,'kvec',IGMEM_NORMAL)
      kveca = igmem_alloc_inf(num*num,fnm,snm,'kveca',IGMEM_NORMAL)
      kocca = igmem_alloc_inf(num,fnm,snm,'kocca',IGMEM_DEBUG)
      keiga = igmem_alloc_inf(num,fnm,snm,'keiga',IGMEM_DEBUG)
      kvecb = igmem_alloc_inf(num*num,fnm,snm,'kvecb',IGMEM_NORMAL)
c
      call vclr(q(kvec),1,num*num)
      call vclr(value,1,num)
c
      call secini(iblk_a,iunit_a)
      call getqvb(q(kveca),naa,newa,isec_a,'print')
      do i=1,num
         if (dpop(i).lt.0.5d0) go to 10
      end do
      call caserr(' disp error a')
10    nocc_a = i-1
c...   eliminate possible harmonic extra's
      nmo_a = naa
11    if (deig(nmo_a).gt.9999900.0d0) then
         do i=1,naa
            if (q(kveca+(nmo_a-1)*naa+i-1).ne.0.0d0) go to 12
         end do
         nmo_a = nmo_a - 1
         go to 11
      end if
12    call dcopy(nmo_a,deig,1,q(keiga),1)
      call dcopy(nmo_a,dpop,1,q(kocca),1)
c
      call secini(iblk_b,iunit_b)
      call getqvb(q(kvecb),nbb,newb,isec_b,'print')
      do i=1,num
         if (dpop(i).lt.0.5d0) go to 20
      end do
      call caserr(' disp error b')
20    nocc_b = i-1
c...   eliminate possible harmonic extra's
      nmo_b = nbb
21    if (deig(nmo_b).gt.9999900.0d0) then
         do i=1,nbb
            if (q(kvecb+(nmo_b-1)*nbb+i-1).ne.0.0d0) go to 22
         end do
         nmo_b = nmo_b - 1
         go to 21
      end if
c
c...   reset real dumpfile
c
22    call reset_dump
c
      if (nbb+naa.ne.num) call caserr('total dimension in disp not num')
      if (nmo_a+nmo_b.ne.newbas0) call caserr('# mo not right -dispvec')
c
      kk = 0
      kka = 0
      kkb = 0
      do i=1,nocc_a
         call dcopy(naa,q(kveca+kka*naa),1,q(kvec+kk*num),1)
         kk = kk + 1
         kka = kka + 1
         value(kk) = q(keiga+kka-1)
         occ(kk) = q(kocca+kka-1)
      end do
      do i=1,nocc_b
         call dcopy(nbb,q(kvecb+kkb*nbb),1,q(kvec+kk*num+naa),1)
         kk = kk + 1
         kkb = kkb + 1
         value(kk) = deig(kkb)
         occ(kk) = dpop(kkb)
      end do
      do i=nocc_a+1,nmo_a
         call dcopy(naa,q(kveca+kka*naa),1,q(kvec+kk*num),1)
         kk = kk + 1
         kka = kka + 1
         value(kk) = q(keiga+kka-1)
         occ(kk) = q(kocca+kka-1)
      end do
      do i=nocc_b+1,nmo_b
         call dcopy(nbb,q(kvecb+kkb*nbb),1,q(kvec+kk*num+naa),1)
         kk = kk + 1
         kkb = kkb + 1
         value(kk) = deig(kkb)
         occ(kk) = dpop(kkb)
      end do
c
      do i=nmo_a+nmo_b+1,naa+nbb
         occ(i) = 0.0d0
         value(i) = 9999920.0d0
      end do
c
c     store vectors
c
      dtitle(10) = 'combined'
      call putq(com,dtitle,value,occ,num,num,num,1,1,q(kvec),mouta,idum)
c
c...  store an mockup density matrix
c
      nx = num*(num+1)/2
      lenx = lensec(nx)
      call vclr(q(kvec),1,lenx)
      ii = kvec
      do i=1,nocc_a+nocc_b
         q(ii) = 1.0d0
         ii = ii + i
      end do
      call secput(isect(497),19,lenx,iblkdc)
      call wrt3(q(kvec),nx,iblkdc,ifild)
c
      call gmem_free_inf(kvecb,fnm,snm,'kvecb')
      call gmem_free_inf(keiga,fnm,snm,'keiga')
      call gmem_free_inf(kocca,fnm,snm,'kocca')
      call gmem_free_inf(kveca,fnm,snm,'kveca')
      call gmem_free_inf(kvec,fnm,snm,'kvec')
c...  
      call putdev(q,mouta,7,1)
_IF(mp2_parallel,masscf)
c...  where did we put the eigenvalues ??
      call secget(isect(9),9,ibl3ea)
_ENDIF
c...    put stv on dumpfile
      call putstv(q)
c
_ENDIF
      return
      end 
      subroutine ver_derdrv(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/derdrv.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
