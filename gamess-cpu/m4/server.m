      subroutine gserv(core,oquit)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      character *8 a,b,c2
      character *4 aa
      character *8 index2
      logical oquit
      logical oprin_bas
INCLUDE(common/direc)
INCLUDE(common/statis)
INCLUDE(common/iofile)
      common/tran/mword(340),iword(340)
INCLUDE(common/mapper)
INCLUDE(common/work)
      common/bufb/c(512)
INCLUDE(common/machin)
INCLUDE(common/segm)
INCLUDE(common/coptbas)
INCLUDE(common/coptbm)
INCLUDE(common/sysmo)
      logical oprint_bas,ofull
c
      parameter (ndim_a=21)
      dimension core(*),a(ndim_a)
      character*10 charwall
      data a/
     + 'exit','stop','copy','merge','list','check',
     + 'edit','checksum','summary','punch','scan','endfile',
     + 'copydump','finddump','findump','pseudo','plot','servec',
     + 'optbs','optbm','sysmo'/
      data index2 /'2-index' /
      write(iwr,910)
 910  format(/1x,72('*')/
     * /40x,17('*')/
     *  40x,'utility functions'/
     *  40x,17('*')/)
      oquit=.false.
      call cpuwal(begin,ebegin)
      nav = lenwrd()
      ii=0
      index=0
_IF(ibm,vax)
      do 1 loop=1,85
      ij=0
      do 2 moop=1,4
      index=index+1
      mword(index)=ii/4+1
      iword(index)=ij
      ij=ij+16
_ELSE
      do 1 loop=1,170
      ij=32
      do 2 moop=1,2
      index=index+1
      mword(index)=ii/2+1
      iword(index)=ij
      ij=ij-32
_ENDIF
   2  ii=ii+1
   1  continue
      jj=256
      ii=0
      do 200 loop=1,maxorb
      i4096(loop)=jj
      iky(loop)=ii
      jj=jj+256
 200  ii=ii+loop
602   call input
50050 write(iwr,900)
  900 format(/1x,72('='))
      call inpa(b)
      k=locatc(a,ndim_a,b)
      if(k.ne.0)go to 800
      i=locatc(ydd,limit1,b(1:4))
      if(i.eq.0) call caserr(
     *'unrecognised directive or faulty directive ordering')
      go to 10105
800    go to (10110,10110,11,22,3,4,5,4,7,8,6,9,
     +           10,12,12,500,20000,18,19,119,130),k
10110 oquit=.true.
10105 cpu=cpulft(1)
      write(iwr,10088)cpu ,charwall()
10088 format(/1x,
     * 'end of gamess utility functions at ',f8.2,' seconds',
     +  a10,' wall'/)
      call timana(17)
      if(oquit) then
      call timout
      call clenup
      endif
      go to 13
11    call ucopy
  605 top = cpulft(1)
      call clredx
      write(iwr,606)b,top
      call whtps
      goto 602
22    call umerge
      goto 605
3     call ulist
      goto 605
4     call uschk(b)
      goto 605
5     call uedit
      go to 605
7     call summar
      go to 605
8     call inpa(c2)
      if (c2.eq.index2) then
       call ucards2
      else
       jrec = jrec - 1
       call ucards
      endif
      go to 605
6     call uscan
      goto 605
c... =endfile= service
9     iunit=idisc(aa,iblk)
      write(iwr,700)aa,iblk
      call put(c,0,iunit)
      goto 605
12    continue
      call finddu(core)
      goto 605
10    call ucopyd
      goto 605
18    call servec(core,'server')
      goto 605
c
c..   basis set optimisation (P.Todorov)
c
c
19    call inpi(outexp)
      call inpi(nexp)
      call inpi(tnprim)
      call inpi(juniq)
      step_opt = 0.1d0
      tol_opt = 1.0d-2
      oprin_bas = .true.
20    call inpa4(aa)
      if (aa.eq.'    ') then
         go to 21
      else if (aa.eq.'step') then
         call inpf(step_opt)
      else if (aa.eq.'tol') then
         call inpf(tol_opt)
      else if (aa.eq.'prin') then
         oprin_bas = .false.
      end if
      go to 20
21    if (ibl3d.ne.0) call caserr('server-optbas must be called first')
       call mainbs(core,step_opt,tol_opt,oprin_bas)
      top = cpulft(1)
      call clredx
      write(iwr,606)b,top
      call whtps
      oquit = .true.
      return    
c
c --- multi dim. basis opt.
c
119   continue 
c defaults
      dltbm = 1.d-3
      tol2 = 6.75d-4
      ofull  = .false.
      oprint_bas = .false.
      call inpi(ntot)
 120  call inpa4(aa)
       if (aa.eq.'delt') then
          call inpf(dltbm)
       else if(aa.eq.'xtol') then
          call inpf(tol2)
       else if(aa.eq.'full') then
          ofull = .true.
       else if (aa.eq.'prin') then
          oprint_bas = .true.
       else if(aa.eq.'    ') then
          go to 122
       else
        call caserr('invalid option specified')
       end if
       goto 120
c
 122   do i=1,ntot
          call input
          call inpa4(angl(i))
          call inpa(label(i))
       end do
121    if (ibl3d.ne.0) call caserr('server-optbas must be called first')
       call mainbm(dltbm,tol2,oprint_bas,ofull,core)
c
       top = cpulft(1)
       call clredx
       write(iwr,606)b,top
       call whtps
       oquit = .true.
       return
c     
c --- write sysmo interface file
c     
130   thresh1=1.0d-5
       thresh2=1.0d-15
       maxits=250
       mgm1=0
       mgm2=25
       nnrec=1
       oktest=.false.
132    continue
       if (jump.gt.nnrec) then
          call inpa4(aa)
          if (aa.eq.'conv') then
             call inpf(thresh1)
             nnrec=nnrec+2
          elseif (aa.eq.'thre') then
             call inpf(thresh2)
             nnrec=nnrec+2
          elseif (aa.eq.'maxc') then
             call inpi(maxits)
             nnrec=nnrec+2
          elseif (aa.eq.'mgm1') then
             call inpi(mgm1)
             nnrec=nnrec+2
          elseif (aa.eq.'mgm2') then
             call inpi(mgm2)
             nnrec=nnrec+2
          elseif (aa.eq.'prin') then
             oktest=.true.
             nnrec=nnrec+1
          else
             call caserr('unrecognized sysmo key')
          endif
          goto 132
       endif
       call sysmo_int(core)
c     
       top = cpulft(1)
       call clredx
       write(iwr,606)b,top
       call whtps
       oquit = .true.
       return
c
c ----- core allocation for graphical o/p utility
c
20000 maxsq=40000
      i10 = igmem_alloc(maxsq)
      i20 = igmem_alloc(maxsq)
      itmp = maxsq+(maxsq*3)/nav+1
      i30 = igmem_alloc(itmp)
c
      call gamplt(core(i10),core(i20),core(i30))
c
      call gmem_free(i30)
      call gmem_free(i20)
      call gmem_free(i10)
      go to 602
 500  call libp
      go to 50050
606   format(/1x,a8,' complete at',f13.3,' secs')
700   format(//' endfile ',a4,'at block',i7)
13    return
      end
      subroutine libp
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/work)
      common/junk/chglib(204),maxlib(204),link(204),
     + apsl(20,4),cpsl(20,4),cpslo(400,4),
     + libmax(4),libort(4),
     + nword1,nword2,nword3,len1,len2,len3
      common/bufb/zlib(204),ztag(10)
INCLUDE(common/iofile)
INCLUDE(common/discc)
      dimension yjx(7)
      data lible/204/
      data yjx/'appe','null','remo','eras','list','punc',
     *'libr'/
c ==== set jwidth for duration
c
      itemp=jwidth
      jwidth=80
c
      nav = lenwrd()
      nword1=lible
      nword2=lible+2*lible/nav
      nword3=1760+8/nav
      len1=lensec(nword1)
      len2=lensec(nword2)
      len3=lensec(nword3)
      limit=7
      iblkpl=1
      numlib=1
    1 call input
      call inpa4(ytext)
      i=locatc(yjx,limit,ytext)
      if(i.eq.0)go to 16
      goto (10000,12,13,13,14,15,20000),i
20000 call inpa4(ytext)
      numlib=locatc(yed,maxlfn,ytext)
      if(numlib.eq.0)numlib=1
      if(jump.le.2)go to 20001
      call inpi(iblkpl)
      if(iblkpl.le.0)iblkpl=1
20001 limit=6
      go to 1
10000 call search(iblkpl,numlib)
      call append
 4    call search(iblkpl,numlib)
      call wrtc(zlib,nword1,iblkpl,numlib)
      call wrt3s(chglib,nword2,numlib)
      call clredx
      write(iwr,40)
   40 format(/' pseudopotential library revised'//1x,72('*')/)
      go to 1
   12 call setsto(lible,-1,link)
      write(iwr,41)
   41 format(/' null library')
      go to 4
   13 call inpa(zname)
      call outrec
      call pread
      do 7 i = 1,lible
      if(link(i))7,10010,10010
10010  if(zname.ne.zlib(i))goto 7
      link(i)=-1
      go to 4
    7 continue
      write(iwr,42) zname
   42 format(/1x,a8,' not known'//1x,72('*')/)
      go to 1
   14 call plist
      go to 1
   15 call pcard
      go to 1
16    jrec=0
      jwidth=itemp
      return
      end
      subroutine pread
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/junk/chglib(204),maxlib(204),link(204),
     * apsl(20,4),cpsl(20,4),cpslo(400,4)
     *,libmax(8),nword1,nword2
INCLUDE(common/iofile)
      common/bufb/zlib(204),ztag(10)
      call rdchr(zlib,nword1,iblkpl,numlib)
      call reads(chglib,nword2,numlib)
      return
      end
      subroutine append
c.....   append pseudopotentials to library   .....
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/junk/chglib(204),maxlib(204),link(204),
     * apsl(20,4),cpsl(20,4),cpslo(400,4)
     *,libmax(4),libort(4),
     * nword1,nword2,nword3,len1,len2,len3
      common/bufb/zlib(204),ztag(10)
INCLUDE(common/iofile)
      dimension ztype(4)
      data lible/204/,m10/10/
      data zend/'end'/
      data ztype/'s','p','d','f'/
      call pread
      write(iwr,40)
   40 format(/' pseudopotentials below appended to library')
  806 call input
      call inpa(zname)
      if(zname.eq.zend)goto  801
      do 3 i=1,lible
      if(link(i)) 3,10040,10040
10040 if(zname.ne.zlib(i))goto 3
      call caserr(
     *'pseudopotential already present in library')
    3 continue
      iblk=iblkpl+len1+len2
      do 20 k=1,lible
      if(link(k))21,20,20
   20 iblk=iblk+len3+1
      call caserr('all library slots taken')
   21 zlib(k) = zname
      call ptext(ztag)
      call input
      call inpf(chglib(k))
      call inpi(n)
      if(n.le.0.or.n.gt.4)
     *call caserr('invalid number of pseudopotential symmetry types')
      maxlib(k)=n
      link(k) = iblk-iblkpl
      do 802 i = 1,n
      call input
      call inpi(libmax(i))
      call inpi(libort(i))
      ndim=libmax(i)*libort(i)
      if(libmax(i).le.0.or.libmax(i).gt.20)
     * call caserr('invalid max parameter')
      if(libort(i).le.0.or.libort(i).gt.20)
     * call caserr('invalid ort parameter')
      call pinlst(apsl(1,i),libmax(i))
      call pinlst(cpslo(1,i),ndim)
      call pinlst(cpsl(1,i),libmax(i))
  802 continue
      write(iwr,809)iblk,zname,ztag,chglib(k),(ztype(i),i=1,n)
 809  format(/1x,
     *'following potential appended to library at block',i6//
     *' tag                         : ',a8/
     *' title : ',10a8/
     *' effective nuclear charge                       ',f6.1/
     *' symmetry types                                 ',4(2x,a1))
      call wrtc(ztag,m10,iblk,numlib)
      call wrt3s(apsl,nword3,numlib)
      go to 806
  801 return
      end
      subroutine pinlst(array,nterm)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/work)
      dimension array(*)
      loop=1
 1    call input
      do 2 i=1,jump
      if(loop.gt.nterm)go to 3
      call inpf(array(loop))
      loop=loop+1
 2    continue
      if(loop.le.nterm)go to 1
 3    return
      end
      subroutine pcard
c.... punches library
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/junk/chglib(204),maxlib(204),link(204),
     * apsl(20,4),cpsl(20,4),cpslo(400,4)
     * ,libmax(4),libort(4),nword1,nword2,nword3
      common/bufb/zlib(204),ztag(10)
INCLUDE(common/iofile)
      data lible/204/,m10/10/
      call pread
      write(iwr,41)
   41 format(/' punch pseudopotential library')
      write(ipu,42)
42    format('null'/'append')
      do 3 i = 1,lible
      if(link(i)) 3,10090,10090
10090 llllll=link(i)+iblkpl
      call rdchr(ztag,m10,llllll,numlib)
      call reads(apsl,nword3,numlib)
      npmax=maxlib(i)
      if(npmax.gt.0.and.npmax.le.4)go to 10011
10012 call caserr('invalid parameters detected in library')
10011 write(ipu,43) zlib(i),ztag,chglib(i),npmax
   43 format(a8/10a8/f6.1,i3)
      do 10014 np=1,npmax
      itpmax=libmax(np)
      itport=libort(np)
      if(itpmax.le.0.or.itpmax.gt.20.or.itport.le.0.or.itport.gt.20)
     * go to 10012
      ndim=itpmax*itport
      write(ipu,10015)itpmax,itport
10015 format(2i3)
      write(ipu,10016)(apsl(j,np),j=1,itpmax)
10016 format(4e20.12)
      write(ipu,10016)(cpslo(j,np),j=1,ndim)
      write(ipu,10016)(cpsl (j,np),j=1,itpmax)
10014 continue
    3 continue
      write(ipu,45)
   45 format('end'/'exit')
      write(iwr,46)
   46 format(/' punch complete'//1x,72('*')/)
      return
      end
      subroutine plist
c.... list pseudopotentials on lineprinter
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/junk/chglib(204),maxlib(204),link(204),
     * apsl(20,4),cpsl(20,4),cpslo(400,4)
     *,libmax(4),libort(4),nword1,nword2,nword3,len1,len2,len3
      common/bufb/zlib(204),ztag(10)
INCLUDE(common/iofile)
      dimension ztype(4)
      data lible/204/,m10/10/
      data ztype/'s','p','d','f'/
      call pread
      write(iwr,40)
   40 format(/' list of library pseudopotentials')
      do 1 i = 1,lible
      if(link(i)) 1,10100,10100
10100 llllll=link(i)+iblkpl
      call rdchr(ztag,m10,llllll,numlib)
      call reads(apsl,nword3,numlib)
      npmax=maxlib(i)
      if(npmax.gt.0.and.npmax.le.4)go to 10011
10012 call caserr(
     *'invalid parameters detected in library')
10011 write(iwr,10013)zlib(i),ztag,chglib(i)
10013 format(/1x,72('=')//
     1 ' pseudopotential tag              ',1x,a8/
     2 ' pseudopotential title            ',1x,10a8/
     3 ' effective nuclear charge         ',1x,f6.1)
      do 10014 np=1,npmax
      itpmax=libmax(np)
      itport=libort(np)
      if(itpmax.le.0.or.itpmax.gt.20.or.itport.le.0.
     * or. itport.gt.20) go to 10012
      ndim=itpmax*itport
      write(iwr,10015)ztype(np),itpmax,itport
10015 format(/1x,a1,'-pseudopotential'/1x,17('=')//
     *5x,'itpmax = ',i3,5x,'itport = ',i3/
     */1x,'exponent array'/)
      write(iwr,10016)(apsl(j,np),j=1,itpmax)
      write(iwr,10017)
10017 format(/1x,'coefficient matrix'/1x,18('=')/)
      write(iwr,10016)(cpslo(j,np),j=1,ndim)
      write(iwr,10018)
10018 format(/1x,'linear-coefficient array'/1x,25('=')/)
      write(iwr,10016)(cpsl(j,np),j=1,itpmax)
10016 format(4e20.12)
10014 continue
    1 continue
      write(iwr,43)
   43 format(/' list complete'//1x,72('*')/)
      return
      end
      subroutine ptext(title)
      implicit REAL  (a-h,o-z)
      character *8   title
INCLUDE(common/workc)
      dimension title(10)
      call input
      k=1
      do 1 i=1,10
      title(i)=char1(k:k+7)
1     k=k+8
      return
      end
      subroutine ucopyd
      implicit REAL  (a-h,o-z)
      character *4 ai,aw
INCLUDE(common/sizes)
INCLUDE(common/iofile)
      common/bufb/bpos(512)
      common/disc/irep(5),nt(maxlfn)
_IF(linux)
      external fget
_ENDIF
      call secinf(iblkdu,numdu,maxc,maxb)
      call revind
      iunit=idisc(ai,iblk)
      call fget(bpos,nword,iunit)
      call secini(iblk,numdu)
      iuniw=idisc(aw,iblw)
      write(iwr,100)ai,iblk,aw,iblw
 100  format(//' copy dumpfile on ',a4,
     *'starting at block',i7,' to ',a4,'starting at block',i7)
      if(maxb.lt.maxc.or.maxc.lt.1)go to 999
      do 1 i=1,508
         call qsector(i,m,itype,n,'get')
         if(m)2,1,2
 2       if(n.lt.1.or.(m+n).gt.maxc.or.itype.lt.1)goto 999
1     continue
      call secsum
c
      nblk=maxc
      if(iunit.eq.iuniw.and.iblw.gt.iblk.and.iblw.lt.(iblk+nblk))
     *call caserr('conflict between input and output disk area')
c    
480   call search(iblw,iuniw)
      call put(bpos,nword,iuniw)
      iblw=iblw+1
      nblk=nblk- 1
      if (nblk.eq.0) go to 470
471   iblk=iblk+1
      call search(iblk,iunit)
      call fget(bpos,nword,iunit)
      goto 480
c
999   call caserr('index block of dumpfile not in correct format')
c
470   call secini(iblkdu,numdu)
c
      return
      end
      subroutine utype1(iunit,iblk)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/symtry)
INCLUDE(common/machin)
INCLUDE(common/runlab)
      common/junkc/ylabel(26)
      common/junk/csi(mxprim),cpi(mxprim),cdi(mxprim),
     *             cfi(mxprim),cgi(mxprim),cznuc(maxat)
      m1420=5*mxprim+maxat
      m110 =10+maxat
      call rdedx(ex,mxprim,iblk,iunit)
      call reads(csi,m1420,iunit)
      call rdchrs(ztitle,m110,iunit)
      nav = lenwrd()
      call readis(kstart,mach(2)*nav,iunit)
c
c  move to restored area
c
      call dcopy(5*mxprim,csi,1,cs,1)
      call dcopy(maxat,cznuc,1,czan,1)
      nat = non
      num = numorb
      nx = numorb * (numorb+1)/2
c
      return
      end
      subroutine utyp15(iunit,iblk)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter (mxcen3 = maxat * 3)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/symtry)
INCLUDE(common/machin)
INCLUDE(common/runlab)
      common/junkc/ylabel(26)
INCLUDE(common/iofile)
      common/junk/
     & bb(mxcen3),cc(mxcen3),ee(mxcen3),coord(3,maxat),dd(3),
     & ibcd(4),ns(maxat),ks(maxat)
c
      write(iwr,10050)
10050 format(//72('*')//' summary of sections 491 and 493')
      if(numorb.gt.maxorb.or.numorb.lt.1.or.nat.gt.maxat.
     *or.nat.lt.1.or.nshell.gt.mxshel.or.nshell.lt.1) then
      write(iwr,10060)
10060 format(//' section 491 overwritten')
      return
      endif
c      cf. wrrec1/rdrec1 (jvl 2000)
      mach4 = 12*nat +3 +4 /lenwrd()
      call rdedx(bb,mach4,iblk,iunit)
cjvl      call dcopy(mxcen3,coord,1,c,1)
      call dcopy(nat*3,bb(nat*3*3+1),1,c,1)
      kss=0
      do 10070 loop=1,nat
      nss = 0
      do 10080 i=1,nshell
      if(katom(i).eq.loop) then
      nss=nss+1
      endif
10080 continue
      ns(loop)=nss
      ks(loop)=kss+1
      kss=kss+nss
10070 continue
      write (iwr,9168) ztitle,nshell,num,nat
 9168 format(//' case : ',10a8//
     *' total number of shells',15x,i5/
     +' total number of basis functions',6x,i5/
     +    ' total number of atoms',16x,i5/)
      write(iwr,9068)
 9068  format(/1x,72('-')//
     *40x,18('*')/
     *40x,'molecular geometry'/
     *40x,18('*')//
     *9x,79('*')/9x,'*',77x,'*'/
     *9x,'*',5x,'atom',3x,'atomic',16x,'coordinates',17x,'number of',
     *6x,'*'/
     *9x,'*',12x,'charge',7x,'x',13x,'y',14x,'z',7x,'shells',9x,'*'/
     *9x,'*',77x,'*'/9x,79('*'))
      do 1180 iat=1,nat
      write(iwr,9108)zaname(iat),czan(iat),
     +  c(1,iat),c(2,iat),c(3,iat),ns(iat)
 9108 format(9x,'*',77x,'*'/9x,'*',77x,'*'/
     *        9x,'*',4x,a8,f5.1,3(f12.7,3x),i5,10x,'*')
 1180 continue
      write(iwr,9129)
 9129 format(9x,'*',77x,'*'/9x,79('*')/
     */40x,19('*')/
     *40x,'molecular basis set'/
     *40x,19('*')///40x,30('=')/
     +40x,'contracted primitive functions'/40x,30('=')//
     +1x,'atom',8x,'shell',3x,'type',2x,'prim',7x,'exponents',
     +12x,'contraction coefficients'/1x,113('='))
      return
      end
      subroutine utyp80(iunit,iblk,hes)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter (mxcen3 = maxat * 3)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/symtry)
INCLUDE(common/machin)
INCLUDE(common/runlab)
INCLUDE(common/iofile)
INCLUDE(common/cntl2)
INCLUDE(common/cntl1)
INCLUDE(common/czmat)
c
      dimension hes(*),accu(6)
      equivalence (accu(1),acc)
c
      write(iwr,10050)
      if(nvar.lt.1.or.nvar.gt.maxvar) then
      write(iwr,10060)
      return
      endif
      n = nvar
      nvar2 = n*n
      nvar60 = nvar*200
      nvarb = lensec(nvar60)
      nvarh = lensec(nvar2)
 
      i40 = 1
      i50 = i40 + nvar60
c
c  input control and other parameters from dumpfile - section 489
c
      call rdedx(accd,mach(1),iblk,iunit)
c
      do 140 i = 1 , 6
         accu(i) = accd(i,1)
 140  continue
      write (iwr,6150)
      write (iwr,6170) (accu(i),i=1,3)
c
      ibl = iblk + lensec(mach(1))
      call rdedx(en,mach(10),ibl,iunit)
      ibl = ibl + lensec(mach(10))
      call rdedx(hes(i40),nvar60,ibl,iunit)
      ibl = ibl + nvarb
      call rdedx(hes(i50),nvar60,ibl,iunit)
c
      write(iwr,*) 'iterat, jpoint = ', iterat, jpoint
      write(iwr,6120)
      do i = 1, jpoint
       write(iwr,6110) i,ierec(i), igrec(i)
      enddo
      ndim = i40-1
      ndim1 = i50-1
      do i = 1, jpoint
       if(ierec(i).ne.-1) then
        write(iwr,6160)i
        if(ierec(i).eq.1. and. igrec(i).eq.1) then
         write(iwr,6140)
        else
         write(iwr,6130)
        endif
         write(iwr,6200) en(i)
         write(iwr,6180)
         write(iwr,6210) (hes(ndim+i+(j-1)*200),j=1,nvar)
         if(igrec(i).ne.-1) then
          write(iwr,6190)
          write(iwr,6210) (hes(ndim1+i+(j-1)*200),j=1,nvar)
         endif
       endif
      enddo
c
c
      write(iwr,6100)
      return
10050 format(/72('*')//' summary of section 489')
10060 format(//' section 489 overwritten')
6110  format(1x,3i8)
6120  format(/' energy and gradient indices'/
     +        ' +++++++++++++++++++++++++++'/
     +        '    calcn.  energy gradient'/)
6140  format(1x,'energy + gradient calculation')
6130  format(1x,'energy only calculation')
6150  format(/1x,'summary of last optimisation history'/
     +        1x,'++++++++++++++++++++++++++++++++++++'/)
6170  format (/' input control parameters'/1x,25('=')
     +        /' line search termination criterion         ',
     +        f11.6/' parameter convergence precision           ',
     +        f11.6/' line search restriction distance          ',
     +        f11.6/)
6160  format(/1x,'***********************************'/
     +        1x,'**** optimisation point', i3,' **'/
     +        1x,'***********************************'/)
6180  format(/' current position in x-space')
6190  format(/' current gradient in x-space')
6200  format(' total energy = ', f15.8,' a.u.')
6210  format(1x,8f12.6)
6100  format(1x,/72('*'))
      end
      subroutine utyp21(iunit,iblkkk)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/machin)
INCLUDE(common/infoa)
      logical irspl
      common/junko/cspace(30),irspa(700),irspl(40),irspb(1590),
     *             irspc(40),irspd(296),irspe(8)
c
c
      write(iwr,10050)
10050 format(//72('*')//' summary of section 501')
c ...
c ... restore restart section on dumpfile
c
      call rdchr(title,ldsect(isect(501)),iblkkk,iunit)
      call reads(cspace,lds(isect(501)),iunit)
c
      call dcopy(len_restrr,cspace,1,gx,1)
_IF(cray)
      call fmove(irspa,nprint,len_restar)
      call fmove(irspl,ciopt,len_restrl)
      call fmove(irspb,jjfile,len_restri)
      call fmove(irspc,master,len_cndx40)
      call fmove(irspd,ncoorb,len_cndx41)
      call fmove(irspe,nat,len_infoa)
_ELSE
      call icopy(len_restar,irspa,1,nprint,1)
      call icopy(len_restrl,irspl,1,ciopt,1)
      call icopy(len_restri,irspb,1,jjfile,1)
      call icopy(len_cndx40,irspc,1,master,1)
      call icopy(len_cndx41,irspd,1,ncoorb,1)
      call icopy(len_infoa,irspe,1,nat,1)
_ENDIF
      if(nat.lt.1.or.nat.gt.maxat) then
      write(iwr,10060)
10060 format(//' section 501 overwritten')
      endif
      write(iwr,*) ' mtask = ' , mtask
c
      return
      end
      subroutine utyp100(iunit,iblk,core)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/bufb/zdone(maxvar)
INCLUDE(common/phycon)
INCLUDE(common/runlab)
INCLUDE(common/infob)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
INCLUDE(common/csubch)
INCLUDE(common/molsym)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/restar)
      dimension core(*)
c
      write(iwr,10050)
10050 format(//72('*')//' summary of section 420')
c
c  input control and other parameters from dumpfile - section 420
c  retrieve z-matrix section isecz
c
c ... /czmat/
c
      maxint = 8*maxnz+2
      nw1 = maxnz * 3 + lenint(maxint)
c
c ... /csubst/
c
      nw2 = maxvar*4 + lenint(maxvar)
c
c ... /csubch/
c
      nw3 = maxvar
c
c ... /infoa/
c
      maxint = 10+3*maxat
      nw4 = 6*maxat+lenint(maxint)
c
c ... /infob/
c
      maxint = maxat+2
      nw5 = lenint(maxint)
c
c ... /molsym/
c
      nw6 = 12 + lenint(4)
c
c ... /phycon/
c
      nw7 = 84 + lenint(2)
c
c ... /runlab/
c
      nw8 = maxorb+maxat+7
c
       call rdchr(zsymm,nw8,iblk,iunit)
       nav = lenwrd()
       call readis(ianz,nw1*nav,iunit)
       if(mtask.eq.4.or.mtask.eq.5) then
          call reads(values,nw2,iunit)
          iblock = iblk + lensec(nw1) + 2*lensec(nw2) + lensec(nw8)
       else
          iblock = iblk + lensec(nw1) + lensec(nw2) + lensec(nw8)
          call rdedx(values,nw2,iblock,iunit)
          iblock = iblock + lensec(nw2)
       endif
       call rdchr(zvar,nw3,iblock,iunit)
       call readis(nat,nw4*nav,iunit)
       call readis(nonsym,nw5*nav,iunit)
       call reads(tr,nw6,iunit)
       call reads(toang(1),nw7,iunit)
c
      write(iwr,*)' ozmat,mtask = ', ozmat,mtask
      if (.not.ozmat.or.mtask.eq.6) return
      call subvar(bl,alpha,beta,lbl,lalpha,lbeta,nz,nvar)
      call trcart
      call sprintxz(maxnz,nz,ianz,iz,bl,alpha,beta,toang(1),iwr)
      if (nvar.eq.0) go to 90
c
c ---- write out the values and names of the variables
c
      pi =  dacos(0.0d0)*2.0d0
      write (iwr,6020)
      i = 0
      idone = 0
      do 30 k = 1 , 3
         do 20 j = 1 , nz
            if (k.eq.1 .and. lbl(j).ne.0) then
               i = iabs(lbl(j))
               ytype = 'angs'
               const = toang(1)
               if (locatc(zdone,idone,zvar(i)).eq.0) then
                  idone = idone + 1
                  zdone(idone) = zvar(i)
                  write (iwr,6030) zvar(i) , values(i)*const , ytype ,
     +                              fpvec(i)
               end if
            else if (k.eq.2 .and. lalpha(j).ne.0) then
               i = iabs(lalpha(j))
               ytype = 'degs'
               const = 180.0d0/pi
               if (locatc(zdone,idone,zvar(i)).eq.0) then
                  idone = idone + 1
                  zdone(idone) = zvar(i)
                  write (iwr,6030) zvar(i) , values(i)*const , ytype ,
     +                              fpvec(i)
               end if
            else if (k.eq.3 .and. lbeta(j).ne.0) then
               i = iabs(lbeta(j))
               ytype = 'degs'
               const = 180.0d0/pi
               if (locatc(zdone,idone,zvar(i)).eq.0) then
                  idone = idone + 1
                  zdone(idone) = zvar(i)
                  write (iwr,6030) zvar(i) , values(i)*const , ytype ,
     +                              fpvec(i)
               end if
            end if
 20      continue
 30   continue
 90   continue
      write (iwr,6010)
      nreq = 3*maxat + 5*nz
      i10 = igmem_alloc(nreq)
      i20 = i10 + 3 * maxat
      i21 = i20 + nz
      i22 = i21 + nz
      i23 = i22 + nz
      i24 = i23 + nz
c     last = i24 + nz
c
      ntota = nat
      do 50 i = 1 , ntota
         m80 = map80(i)
         czann(i) = czan(m80)
         ztag(i) = zaname(m80)
         do 40 j = 1 , 3
            cat(j,i) = c(j,m80)
 40      continue
 50   continue
      call rotf(ntota,tr,cat,c)
      do 60 i = 1 , ntota
         czan(i) = czann(i)
         zaname(i) = ztag(i)
         c(1,i) = c(1,i) - trx
         c(2,i) = c(2,i) - try
         c(3,i) = c(3,i) - trz
 60   continue
      otest = .true.
      call stocxz(maxnz,nz,ianz,iz,bl,alpha,beta,otest,
     +           ntota,imass,c,core(i10)
     +          ,core(i20),core(i21),core(i22),core(i23),core(i24),iwr,
     +          oerr)
      ki = i10 - 1
      do 70 i = 1 , ntota
         core(ki+1) = c(1,i)
         core(ki+2) = c(2,i)
         core(ki+3) = c(3,i)
         ki = ki + 3
 70   continue
      if (oerr) call caserr(
     + 'error detected in converting z-matrix to cartesian coordinates')
      iold = igroup
      zoldg = zgroup
      jold = jaxis
      call symm(iwr,core)
      if (iold.ne.igroup .or. jold.ne.jaxis) then
         write (iwr,6040) zoldg , jold , zgroup , jaxis
c        call caserr('point group change detected')
      end if
      do 80 i = 1 , ntota
         m80 = map80(i)
         zaname(m80) = ztag(i)
         c(1,m80) = cnew(i,1)
         c(2,m80) = cnew(i,2)
         c(3,m80) = cnew(i,3)
         czan(m80) = czann(i)
 80   continue
c
      call gmem_free(i10)
c
         write (iwr,6060)
         do 140 i = 1 , ntota
            write (iwr,6070) i , zaname(i) , (c(j,i),j=1,3) , czan(i)
 140     continue
         return
 6010 format (1x,'============================================='/)
 6020 format (/1x,'============================================='/1x,
     +        'variable',11x,'value',9x,5x,'hessian'/1x,
     +        '=============================================')
 6030 format (1x,a8,2x,f14.7,1x,a4,2x,f14.6)
 6040 format (//1x,'**** change in point group ****'//5x,2(5x,a8,i6)/)
 6060 format (/40x,19('=')/40x,'nuclear coordinates'/40x,19('=')//23x,
     +        'atom',13x,'x',14x,'y',14x,'z',12x,'chg')
 6070 format (15x,i3,2x,a8,2x,4f15.6)
      end
      subroutine utyp18(iunit,iblk,isoc)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/restar)
INCLUDE(common/prints)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/symtry)
INCLUDE(common/machin)
INCLUDE(common/runlab)
      common/junk/bb(maxat*3,4),bbb(3),ibcd(4),
     * ns(maxat),ks(maxat),intyp(mxshel)
      dimension isoc(*),jshell(5),ylabel(5)
      data ntype/5/
      data ylabel/'s','p','d','f','sp'/
      data jshell/ 1 , 3 , 6 ,10 ,  4 /
      data toll/1.0d-10/
      data zline,zlinev /' * * * *','       *'/
c
c     generate equivalent centers
c     set table ( centers versus transformations )
c
c     process section 496
c
      write(iwr,10050)
10050 format(//72('*')//' summary of section 496')
       nav = lenwrd()
       nwnt = 134
       call readi(invt,nwnt,iblk,iunit)
       mword1=(nshell*nt-1)/nav + 1
       ibl1=lensec(mword1)
       mword2=(nat*nt-1)/nav + 1
c      ibl2=lensec(mword2)
       ibl3=lensec(1728)
       ibl4=lensec(4800)
       ibl5=lensec(10800)
c
       nw196(1)=432
       nw196(2)=1728
       nw196(3)=4800
       nw196(4)=10800
       nw196(5)=mword1
       nw196(6)=mword2
c
c      len196=2+ibl1+ibl2+ibl3+ibl4+ibl5
c
       ibl196(1)=iblk + 1
       ibl196(2)=ibl196(1)+1
       ibl196(3)=ibl196(2)+ibl3
       ibl196(4)=ibl196(3)+ibl4
       ibl196(5)=ibl196(4)+ibl5
       ibl196(6)=ibl196(5)+ibl1
c
c   ----- read -isoc-  -
c
      call readi(isoc,nw196(6)*nav,ibl196(6),iunit)
c
      do 110 loop=1,nshell
      ii=kmax(loop)-kmin(loop)+1
      do 115 i=1,ntype
      if(ii.eq.jshell(i)) then
       intyp(loop) = i
       endif
115   continue
110   continue
c
      do 1360 iat = 1,nat
         do 1200 it = 1,nt
           if (isoc(iat+ilisoc(it)).gt.iat) go to 1360
 1200    continue
      ns2=ns(iat)
      if(ns2.eq.0)go to 1360
      write (iwr,9548) zaname(iat)
      ns1 = ks(iat)
      ns2 = ns1+ns2-1
      do 1340 ish = ns1,ns2
      write (iwr,9468)
      i1 = kstart(ish)
      i2 = i1+kng(ish)-1
      ityp = intyp(ish)
      do 1320 ig = i1,i2
      go to (1220,1240,1260,1250,1280 ),ityp
 1220 c1 = cs(ig)
      go to 1300
 1240 c1 = cp(ig)
      go to 1300
 1260 c1 = cd(ig)
      go to 1300
 1250 c1 = cf(ig)
      go to 1300
 1280 c1 = cs(ig)
      c3 = cp(ig)
      write (iwr,9528) ish,ylabel(ityp),ig,ex(ig),c1,c3
      go to 1320
 1300 write (iwr,9148) ish,ylabel(ityp),ig,ex(ig),c1
 1320 continue
 1340 continue
 1360 continue
c
c ----- classify nucleii into types ...
c
      call build_nuct(nat,ns,zaname,czan,nuct)
c

      write(iwr,9700)
      write (iwr,9428)
      write (iwr,9288)
      imax = 0
 1380 imin = imax+1
      imax = imax+15
      if (imax .gt. nt) imax = nt
      imax1 = imax+1
      write (iwr,9308)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9348) zlinev,(i,i = imin,imax)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zline,i = imin,imax1)
      do 1400 iat = 1,nat
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9368) iat,(isoc(iat+ilisoc(i)),i = imin,imax)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zline,i = imin,imax1)
 1400 continue
      if (imax .lt. nt) go to 1380
      write (iwr,9428)
      write (iwr,9488)
      imax = 0
 1460 imin = imax+1
      imax = imax+15
      if (imax .gt. nt) imax = nt
      imax1 = imax+1
      write (iwr,9308)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9348) zlinev,(i,i = imin,imax)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zline,i = imin,imax1)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9348) zlinev,(invt(i),i = imin,imax)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zlinev,i = imin,imax1)
      write (iwr,9328) (zline,i = imin,imax1)
      if (imax .lt. nt) go to 1460
c
      write(iwr,9700)
c
 9428 format(1h0)
 9288 format(/,1x,5h*****,30h transformation table of atoms, 5h*****,/,
     +     30x,15h rows are atoms,/,30x,
     +     32h columns are symmetry operations)
 9308 format(//)
 9328 format(1x,16a8)
 9348 format(1x,a8,15(2x,i2,3x,1h*))
 9488 format(/1x,'***** inverse transformations *****'/)
 9368 format(1x,16(2x,i2,3x,1h*))
 9148 format(15x,i3,3x,a4,3x,i3,1x,2f15.6)
 9468 format(/)
 9528 format(15x,i3,3x,a4,3x,i3,1x,3f15.6)
 9548 format(/1x,a8)
 9700 format(/1x,72('='))
      return
      end
      subroutine finddu(core)
      implicit REAL  (a-h,o-z)
      logical level,nogg,levelh,sector_block
INCLUDE(common/sizes)
      character *4 ai
      character *8 low,high,highest,test
INCLUDE(common/iofile)
      common/disc/irep(5),nt(maxlfn)
      dimension core(*)
      data low,high,highest/'low','high','highest'/
      iunit=idisc(ai,iblk)
      call inpi(nblk)
      call inpa(test)
      level=test.ne.high.and.test.ne.highest
      levelh = test.eq.highest
      if(level)test=low
      nogg=nblk.le.0
      if(nogg)go to 7300
      write(iwr,100)ai,iblk,nblk,test
100   format(//' find and list dumpfiles on ',a4,
     *'starting at block',i7,' for',i7,' blocks : level=',a8)
      go to 801
7300  write(iwr,101)ai,iblk,test
 101  format(//
     *' find and list dumpfiles on ',a4,
     *' starting at block',i7,' to endfile : level = ',a8)
 801  if (.not.sector_block(iblk,iunit)) go to 999
      call secinf(ib,iun,maxc,maxb)
c...  valid dumpfile index block found
      write(iwr,600)ai,iblk,maxc,maxb
600   format(///' *summary of dumpfile on ',a4,
     *'starting at block',i8/' *',/
     *' *current length=',i8,' blocks'/' *',/
     *' *maximum length=',i8,' blocks'/' *',/
     *' *section type block length')
      do 3 i=1,508
         call qsector(i,m,itype,ilen,'get')
         if (m.eq.0) go to 3 
            m=iblk+m
            write(iwr,500)i,itype,m,ilen
500         format(' *',i7,i5,i6,i7)
3     continue
      if(level)goto 999
c
c... summarize dumpfile at high level
c... we need look at restart section first (section 501)
c
      call qsector(501,m,itype,n,'get')
      if(m.ne.0) call utyp21(iunit,m+iblk)
c
      do 20 i=1,500
         call qsector(i,m,itype,n,'get')
      if(m)21,20,21
21    m=m+iblk
      if(itype.eq.1)then
        call utype1(iunit,m)
      elseif(itype.eq.2)then
        ibase = igmem_alloc_all(mword)
        call utype2(iunit,m,i,core(ibase),levelh)
        call gmem_free(ibase)
      elseif(itype.eq.3)then
        call utype3(iunit,m,i)
      elseif(itype.eq.15)then
        call utyp15(iunit,m)
      elseif(itype.eq.80)then
        ibase = igmem_alloc_all(mword)
        call utyp80(iunit,m,core(ibase))
        call gmem_free(ibase)
      elseif(itype.eq.100)then
        call utyp100(iunit,m,core)
      elseif(itype.eq.18)then
        ibase = igmem_alloc_all(mword)
        call utyp18(iunit,m,core(ibase))
        call gmem_free(ibase)
      else
      endif
20    continue
c
999   iblk=iblk+1
      nblk=nblk-1
      if(nblk)801,800,801
800   return
      end
      subroutine otype1(iunit,iblk,isect)
      implicit REAL  (a-h,o-z)
      logical idd
      character *4 is,itest
      character *8 title,tag,tagc
      character *8 stype
      character *4 new,neww
INCLUDE(common/sizes)
      common/disc/irep(5),nt(maxlfn)
      common/junk/zeta(10,160),coef(10,160),cx(100),cy(100),cz(100),
     *z(100),itype(160),kad(160),icentr(160),mbase(160),ntrm(160),
     *acc1,acc2,imin(4),imax(4),nbasis,non,iblock,
     *maxblk,irun,ngroup,ncentg,nosym,cgx(12),cgy(12),cgz(12),
     *idddd,norbd,nnbase(160)
      common/craypk/title(10),tag(100)
INCLUDE(common/iofile)
      dimension pow(3),ngrp(4),lbase(4),stype(15)
      dimension new(2),is(3)
      dimension tfac(3)
      data pi/3.14159265359d0/
      data m110/110/
      data is/'s','p','d'/
      data new/'new','old'/
      data pow/0.75d0,1.25d0,1.75d0/
      data ngrp/1,3,6,5/
      data lbase/0,1,4,10/
      data stype/'s','x','y','z','xy','xz','yz','xx','yy','zz',
     *'xy','xz','yz','xx-yy','3zz-rr'/
      write(iwr,10050)isect
10050 format(//72('-')//' summary of section',i5)
      call search(iblk,iunit)
      call rdchr(title,m110,iblk,iunit)
      nw=3638+978/lenwrd()
      call reads(zeta,nw,iunit)
      if(nbasis.gt.255.or.nbasis.lt.1.or.non.gt.100.
     *or.non.lt.1.or.ngroup.gt.160.or.ngroup.lt.1)goto 999
      write(iwr,100)title,acc1,acc2,imin,imax,iblock,maxblk
100   format(//1x,10a8//' acc1,acc2=',e11.3,',',e11.3//
     1' imin parameters=',4i5//' imax parameters=',4i5//
     2' current position of mainfile=',i7//
     3' maxblock parameter=',i7///29x,'geometry(a.u.)'//
     48x,'x',15x,'y',15x,'z',17x,'charge',1x,'label')
      do 2 i=1,non
2     write(iwr,101)cx(i),cy(i),cz(i),z(i),tag(i)
101   format(4f16.7,1x,a8)
      write(iwr,102)non
102   format(/' no. of nuclei=',i4)
      if(nosym.eq.1.or.ncentg.lt.1)goto 4
      write(iwr,103)
103   format(//16x,'symmetry centres'//8x,'x',15x,'y',15x,'z')
      do 5 i=1,ncentg
5     write(iwr,101)cgx(i),cgy(i),cgz(i)
      write(iwr,105)
     *ncentg
105   format(/' no. of symmetry centres=',i4)
4     write(iwr,106)
106   format(//7x,'ordered list of groups')
      x=pi**0.125d0
      y=(0.5d0)**0.25d0
      tfac(1)=x*y
      y=y*y
      tfac(2)=tfac(1)*y
      tfac(3)=tfac(2)*y
      do 3 i=1,ngroup
      m=itype(i)
      n=ntrm(i)
      write(iwr,107)i,is(m),tag(icentr(i)),n,new(kad(i)+2)
107   format(/'  group type centre  nterm merge'/
     *i7,1x,a1,4x,a8,i5,1x,a4//11x,'ctran',12x,'zeta')
      x=tfac(m)
      y=pow(m)
      do 3 j=1,n
      g=zeta(j,i)
      c=(coef(j,i)*x)/(g+g)**y
3     write(iwr,101)c,g
      write(iwr,108)ngroup
108   format(/' no. of groups=',i4///7x,
     *'ordered list of gtos'//
     *' orbital centre   type sub-type merge')
      k=0
      idd=idddd.eq.1
      do 6 i=1,ngroup
      tagc=tag(icentr(i))
      jj=itype(i)
      itest=is(jj)
      neww=new(kad(i)+2)
      if(jj.eq.3.and.idd)jj=4
      n=ngrp(jj)
      m=lbase(jj)
      do 6 j=1,n
      k=k+ 1
6     write(iwr,109)k,tagc,itest,stype(m+j),neww
109    format(i8,1x,a8,3x,a4,1x,a8,1x,a3)
      if(idd)goto 7
      write(iwr,110)nbasis
110   format(/' no. of cartesian gtos=',i4)
      goto 8
7     write(iwr,111)norbd
111   format(/' no. of sperical harmonic gtos=',i4)
8     return
999   write(iwr,10060)
10060 format(//' *** section overwritten')
      return
      end
      subroutine utype2(iunit,iblk,isect,q,level)
      implicit REAL  (a-h,o-z)
      logical level
_IF(parallel)
      logical opg_root
_ENDIF
c
c     ----- print 1-electron integrals resident in section
c           isect as a sequence of matrices   ----
c
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/mapper)
INCLUDE(common/infoa)
      common/blkin/potnuc(4),pint(508),blkspa(512)
INCLUDE(common/machin)
      character *4 yprin
      dimension yprin(6),q(*)
      data yprin/'  s-','  t-','t+v-','  x-','  y-','  z-'/
c
c     process the 1e-integrals
c
_IF(parallel)
      if(opg_root()) then
_ENDIF
      write(iwr,10050)isect
10050 format(//72('-')//' summary of section',i5)
_IF(parallel)
      endif
_ENDIF
      call search(iblk,iunit)
c
c     first restore header block
c
      call rdedx(potnuc, 511, iblk, iunit)
c
_IF(parallel)
      if(opg_root()) then
_ENDIF
      write (iwr,6010) isect
      write (iwr,6020) potnuc
_IF(parallel)
      endif
_ENDIF
      if(num.le.0.or.num.gt.maxorb)
     + call caserr('utype2: num not initialised')
      lentri=num*(num+1)/2
      lenb = lensec(lentri)
c
c     now process each matrix in turn (S, T, T+V, X, Y, Z)
c
      iblk = iblk + 1
      do imat=1,6
          call rdedx(q,lentri,iblk,iunit)
_IF(parallel)
          if(opg_root()) then
_ENDIF
          if(level) write(iwr,6030)yprin(imat)
          if(imat.gt.3) then
            do loop = 1, lentri
            q(loop) = - q(loop)
            enddo
          endif
          if(level)call writel(q,num)
_IF(parallel)
          endif
_ENDIF
          iblk = iblk + lenb
      enddo
c
c
      return
 6030  format(/1x,72('*')//
     * 35x,a4,'matrix over gaussian basis set'/
     * 35x,34('-')/)
 6010 format (/1x,72('=')/45x,
     +        '1-electron integrals in section',i6/45x,37('-'))
 6020 format (/' potnuc,dx,dy,dz = ',4f19.8)
      end
      subroutine utype3(iunit,iblk,isect)
      implicit REAL  (a-h,o-z)
      logical iftran
      character *8 obnam,date,time,prog,vectyp,acctno,spare,title
INCLUDE(common/sizes)
      common/disc/irep(5),nt(maxlfn)
      common/craypk/obnam,date,time,prog,vectyp,acctno,spare(13),
     *title(10)
      common/blkin/
     *evalue(maxorb),occ(maxorb),etot,nbasis,newbas,ncol,ivalue,
     *iocc,ispa,
     *ilifc(maxorb),ntran(maxorb),itran(mxorb3),ctran(mxorb3),iftran
     * ,iftram
INCLUDE(common/iofile)
INCLUDE(common/machin)
c
      nav=lenwrd()
      write(iwr,10050)isect
10050 format(//72('-')//' summary of section',i5)
      call rdchr(obnam,29,iblk,iunit)
      call reads(evalue,mach(8),iunit)
      if(nbasis.gt.maxorb.or.newbas.gt.nbasis.
     *or.ncol.gt.maxorb.or.newbas.lt.1.or.ncol.lt.1)goto 999
      write(iwr,200)vectyp,prog,time,date,obnam,acctno,title,nbasis,
     *newbas,ncol,etot
200   format(//1x,a7,' vectors created by ',a8,' program at ',
     *a8,' on ',a8,' in the job ',a8,' under acct. ',a8/
     *' with the title ',10a8//
     *' nbasis=',i4/' newbas=',i4/'   ncol=',i4/'   etot=',f16.8)
      if(ivalue)20,20,30
30    write(iwr,201)
201   format(//50x,' eigen values')
      write(iwr,202)(evalue(i),i=1,ncol)
202   format(/5x,8f14.7)
 20   if(iocc)40,40,50
50    write(iwr,203)
203   format(//47x,' occupation numbers')
      write(iwr,202)(occ(i),i=1,ncol)
40    call readis(ilifc,mach(9)*nav,iunit)
      if(iftran)goto 666
      write(iwr,667)
667   format(//1x,'transformed orbitals(normalized)'//
     *'   coefficient old orbital nterm new orbital')
      do 668 i=1,newbas
      m=ilifc(i)
      n=ntran(i)
      write(iwr,6688)ctran(m+1),itran(m+1),n,i
6688  format(f14.7,i12,i6,i12)
      if(n.eq.1)goto 668
      do 669 j=2,n
669   write(iwr,6688)ctran(m+j),itran(m+j)
668   continue
666   return
 999  write(iwr,4455)
 4455 format(/' *** section overwritten ***')
      return
      end
      subroutine ucards2
c
c     punch transformed 2-electron integrals
c     as written to the dumpfile by the transformed integrals
c     module (tran4)
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      parameter (mxorb1=maxorb+1)
      character *4 ai
      character *8 index2
      common/junk/occ(maxorb),potn,corree,ncolo(3),ncore,
     * mapcie(maxorb),map2(maxorb),nactt,mapaie(maxorb),mapaei(maxorb)
     * ,iqsec,nacta(maxorb),nactb(maxorb),nactc(5),isecor,
     *  evalue(maxorb),eocc(mxorb1),nbas,newb,ncol,ieval,ipop,ispp
     * ,nirr,mult(8,8),isymao(maxorb),isymmo(maxorb),nsp
INCLUDE(common/iofile)
INCLUDE(common/common)
INCLUDE(common/discc)
INCLUDE(common/savem)
INCLUDE(common/machin)
INCLUDE(common/blocks)
INCLUDE(common/sector)
      common/blkin/gg(510),mword,mspace,blkspa(512)
      dimension f(2),ia(2),ja(2)
_IF(linux)
      external fget
_ENDIF
      data index2 /'2-INDEX' /
c
      iunit=idisc(ai,iblkdd)
c
      write(iwr,105) ai
      call secini(iblkdd,iunit)
c
      nav=lenwrd()
      call secget(isect(470),1005,iblka)
      call readi(nacta,mach(14)*nav,iblka,numdu)
c...
c... restore 1-elec integrals
c...
      call secget(isecor,1004,jblkk)
      call rdedx(occ,mach(15),jblkk,numdu)
      write(iwr,102)isecor,iblkdd
      write(iwr,106)nactt,ncore,potn,corree
c
      nact = nactt
      n = 0
      if(nact.le.1.or.nact.gt.maxorb) then
       call caserr('invalid number of active orbitals')
      endif
      nin=0
      jblkk=jblkk+lensec(mach(15))
      call search(jblkk,numdu)
      call fget(gg,kword,numdu)
c
c     first write 2-index tag on punch file
c
      write(nfblck,100) index2
      iseq=0
c     now punch integrals, 2 per line
      do i=1,nact
       do j=1,i
        nin=nin+1
        if(nin.gt.kword)then
         call fget(gg,kword,numdu)
         nin=1
        endif
        n=n+1
        f(n)=gg(nin)
        ia(n) = i
        ja(n) = j
        if(n.ne.1)then
         iseq=iseq+1
         write(nfblck,101)iseq,n,(ia(k),ja(k),f(k),k=1,n)
         n=0
        endif
       enddo
      enddo
c
      if(n.ne.0) then
       iseq=iseq+1
       write(nfblck,101)iseq,n,ia(1),ja(1),f(1)
      endif
      write(iwr,110)iseq
      return
c
105   format(//1x,
     +  'punch transformed MO 2-index integrals from dumpfile on ', 
     +  a4)
102   format(
     */' transformed 1-electron integrals restored from section',i4,/,
     *' of dumpfile starting at block',i6)
106   format(1x,'header block information :'/
     *       1x,'=========================='/
     *       1x,'number of active orbitals ',i4/
     *       1x,'number of core   orbitals ',i4/
     *       1x,'nuclear repulsion energy ',e21.12/
     *       1x,'core energy              ',e21.12)
100   format(a8)
110   format(/i8,' cards punched')
101   format(i8,i2,2(2i4,f17.10))
      end
      subroutine uscan
      implicit REAL  (a-h,o-z)
      character *4 c
INCLUDE(common/iofile)
      common/bufb/din(511),b
      iunit=idisc(c,k)
      write(iwr,600)c,k
600    format(//' scan ',a4,'starting at block',i7)
       k=k-1
 11   call fgett(din,nword,iunit)
      k=k+1
      if(nword.ne.0)go to 11
      return
      end
      subroutine uedit
      implicit REAL  (a-h,o-z)
      logical nogg
      character *4 la2,lend
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/work)
      common/disc/irep(5),nt(maxlfn)
_IF(ibm,vax)
      integer *2 ii1,jj1,ii2,jj2
      common/blkin/g1(340),ii1(340),jj1(340),mwrd1,mspac1,
     +             g2(340),ii2(340),jj2(340),mwrd2,mspac2
_ELSE
      common/craypk/ijkl1(340),ijkl2(340)
      common/blkin/g1(340),gii1(170),mwrd1,mspac1,
     +             g2(340),gii2(170),mwrd2,mspac2
      dimension ii1(2),ii2(2)
      equivalence (ii1(1),gii1(1)),(ii2(1),gii2(1))
_ENDIF
_IF(linux)
      external fget
_ENDIF
      data lend/'end'/
      num2=idisc(la2,iblk2)
      mwrd2=0
      call inpi(j)
      f=10.0d0**(-j)
      write(iwr,100)la2,iblk2,f
100   format(/' edit 2-electron files to ',a4,'starting at block',i7/
     *' threshold=',e10.1//7x,'input file'/
     *6x,'starting terminal',/' lfn  block    block')
      iupp=iblk2
106   call input
      call inpa4(la2)
      if(la2.eq.lend)goto 107
      jrec=0
      num1=idisc(la2,iblk1)
      nogg=num1.eq.num2
      call inpi(nblk)
      write(iwr,400)la2,iblk1,nblk
400   format(1x,a4,2i9)
      nblk=iblk1-nblk
401   if(nblk)707,106,707
707   if(nogg.and.iblk1.ge.iblk2.and.iblk1.lt.iupp)call
     * caserr('conflict between input and output disk areas')
      call search(iblk1,num1)
      call fget(g1,nword,num1)
      if(nword)7200,106,7200
 7200 continue
_IFN(ibm,vax)
      call unpack(ii1,32,ijkl1,340)
_ENDIF
      do 200 j=1,mwrd1
      if(dabs(g1(j)).lt.f)goto 200
      mwrd2=mwrd2+1
      g2(mwrd2)=g1(j)
_IF(ibm,vax)
      ii2(mwrd2)=ii1(j)
      jj2(mwrd2)=jj1(j)
_ELSE
      ijkl2(mwrd2)=ijkl1(j)
_ENDIF
      if(mwrd2.lt.340)goto 200
      call search(iupp,num2)
_IFN(ibm,vax)
      call pack(ii2,32,ijkl2,340)
_ENDIF
      call put(g2,511,num2)
      mwrd2=0
      iupp=iupp+1
200   continue
      iblk1=iblk1+1
      nblk=nblk+1
      goto 401
 107  call search(iupp,num2)
      if(mwrd2.ne.0) then
_IFN(ibm,vax)
       call pack(ii2,32,ijkl2,340)
_ENDIF
       call put(g2,511,num2)
      endif
      call put(g2,0,num2)
      return
      end
      subroutine ucopy
      implicit REAL  (a-h,o-z)
      logical   nogg,logg
      character *4 ai,aw
INCLUDE(common/sizes)
INCLUDE(common/iofile)
      common/bufb/din(511),b
      common/disc/irep,ispa(4),nt(maxlfn)
      iunit=idisc(ai,iblk)
      iuniw=idisc(aw,iblw)
      nogg=iunit.eq.iuniw
      call inpi(nblk)
      logg=nblk.le.0
      iupp=iblw
      if(logg)goto 401
      write(iwr,100)ai,iblk,aw,iblw,nblk
100   format(//' copy from ',a4,'starting at block',i7,' to ',
     1a4,'starting at block',i7,' for',i7,' blocks')
      goto 402
401   write(iwr,102)ai,iblk,aw,iblw
102   format(//' copy from ',a4,'starting at block',i7,' to ',
     1a4,'starting at block',i7,' to endfile block')
402   if(nogg.and.iblk.ge.iblw.and.iblk.lt.iupp)call
     * caserr('conflict between input and output disk areas')
      call search(iblk,iunit)
      call fgett(din,nword,iunit)
      nblk=nblk-1
      if(nword.gt.511.or.nword.lt.0)goto 700
      call search(iupp,iuniw)
      call put(din,nword,iuniw)
      if(logg.and.nword.eq.0)go to 666
700   iupp=iupp+1
      iblk=iblk+1
      if(nblk)402,666,402
 666  return
      end
_IFN(ibm,vax)
      subroutine ucards
      implicit REAL  (a-h,o-z)
      logical logg
      character *4 ai
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
INCLUDE(common/blocks)
      common/blkin/gg(510),mword,mspace,blkspa(512)
      common/craypk/integ(1360)
      dimension f(2),ia(2),ja(2),ka(2),la(2)
_IF(linux)
      external fget
_ENDIF
      iseq=0
      n=0
      iunit = idisc(ai,iblk)
      callinpi(nblk)
      logg=nblk.le. 0
      if(logg)then
        write(iwr,102)ai,iblk
      else
       write(iwr,100)ai,iblk,nblk
      endif
      call  maintp(itype,iblk,nblk,iunit)
      if (itype.ne.1) call caserr('punch only for 2-electron mainfiles')
402   call fget(gg,nword,iunit)
      if(nword)33,44,33
44    if(logg)return
      goto 404
  33  continue
      call unpack(gg(num2e+1),lab816,integ,numlab)
      iword=1
      do 3 iw=1,mword
      n=n+1
      f(n)=gg(iw)
_IF(littleendian)
      ia(n) = integ(iword+1)
      ja(n) = integ(iword  )
      ka(n) = integ(iword+3)
      la(n) = integ(iword+2)
_ELSE
      ia(n) = integ(iword  )
      ja(n) = integ(iword+1)
      ka(n) = integ(iword+2)
      la(n) = integ(iword+3)
_ENDIF
      iword=iword+4
      if(n.ne.1)then
       iseq=iseq+1
       write(nfblck,101)iseq,n,(ia(k),ja(k),ka(k),la(k),f(k),k=1,n)
       n=0
      endif
3     continue
404   nblk=nblk-1
      if(nblk)402,2,402
2     if(n)10120,1,10120
10120 iseq=iseq+1
      write(nfblck,101)iseq,n,ia(1),ja(1),ka(1),la(1),f(1)
1     write(iwr,110)iseq
      return
110   format(/i8,' cards punched')
101   format(i8,i2,2(4i4,f17.10))
102   format(//' punch ',a4,'from block',i7,' to endfile block')
100   format(//' punch ',a4,'from block',i7,' for',i7,' blocks')
      end
_ENDIF
      subroutine summar
      implicit REAL  (a-h,o-z)
      logical logg
      character *4 ai
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
      common/blkin/g(340),gii(170),mword,mspace,blkspa(512)
      dimension ii(2),i(4),iq(4)
      dimension gp(204),gk(204),ijkl(102)
      equivalence (gp(1),g(1)),(gk(1),g(205)),(ijkl(1),gii(69))
      equivalence (ii(1),gii(1))
_IF(linux)
      external fget
_ENDIF
      itype = 0
_IFN(cray)
      do loop=1,4
       i(loop)=0
       iq(loop)=0
      enddo
_ENDIF
      iunit = idisc(ai,iblk)
      callinpi(nblk)
      logg=nblk.gt.0
      if (logg) then
         write(iwr,100)ai,iblk,nblk
      else
         write(iwr,110)ai,iblk 
      end if
c
      call maintp(itype,iblk,nblk,iunit)
      if (itype.eq.1) then
         write(iwr,111) 
      else if (itype.eq.2) then
         write(iwr,112)  
      else if (itype.eq.3) then
         write(iwr,113)
      else
         return
      end if
c
402   call fget(g,nword,iunit)
      if (nword.eq.0) go to 10200
      if (mword.le.0.or.mword.gt.340.or.nword.ne.511)goto 10300
c
      if (itype.eq.1) then
         call upack8(ii,i,1)
         call upack8(ii,iq,mword)
         write(iwr,102)iblk,g(1),i,g(mword),iq,mword
      else if (itype.eq.2) then
         call upack4(ii,i,1)
         call upack4(ii,iq,mword)
         write(iwr,103)iblk,g(1),i(1),i(2),g(mword),iq(1),iq(2),mword
      else
         call upack4(ijkl,i,1)
         call upack4(ijkl,iq,mword)
         write(iwr,104)iblk,gp(1),gk(1),i(1),i(2),
     1                 gp(mword),gk(mword),iq(1),iq(2),mword
      end if
c
1     nblk=nblk-1
      iblk=iblk+1
      if(nblk)402,999,402
999   return
10300 write(iwr,10301)iblk
10301 format(i8,11x,'not mainfile')
      go to 1
10200 write(iwr,101)iblk
      if(logg)goto 1
      return
101   format(i8,10x,'endfile')
102   format(i8,10x,f16.8,4i4,10x,f16.8,4i4,10x,i4)
103   format(i8,10x,f16.8,2i8,10x,f16.8,2i8,10x,i4)
104   format(i8,4x,2f16.8,2i6,4x,2f16.8,2i6,4x,i4)
111   format(/40x,'first word',33x,'last word'/
     +3x,'block',17x,'g',11x,'i',3x,'j',3x,'k',3x,'l',17x,'g',
     +11x,'i',3x,'j',3x,'k',3x,'l',4x,'word count')
112   format(/40x,'first word',33x,'last word'/
     +3x,'block',20x,'p',11x,'ij',3x,3x,'kl',3x,17x,'p',
     +11x,'ij',3x,3x,'kl',3x,4x,'word count')
113   format(/40x,'first word',33x,'last word'/
     +3x,'block',15x,'p',15x,'k',8x,'ij',4x,'kl',15x,'p',15x,'k',
     +8x,'ij',4x,'kl',1x,'word count')
110   format(//29x,'summarize ',a4,'from block',i7,
     +' to endfile block')
100   format(//29x,'summarize ',a4,'from block',i7,' for',i7,
     +' blocks')
      end
      subroutine maintp(itype,iblk,nblk,iunit)
c
c...  establish kind of mainfile
c...  return type / and block-number of first recognised block
c...     1 : 2-electron/ 2 : p / 3 : pk   
c...     0 : Endfile block or end of file encountered
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/iofile)
      common/blkin/g(340),gii(170),mword,mspace,blkspa(512)
      dimension i(4),iq(4)
      character*20 type(3)
      character *8 text,stype(4)
_IF(linux)
      external fget
_ENDIF
      data type/'2-electron-integral ','      p-supermatrix ',
     1          '     pk-supermatrix '/
      data stype/'2e','p','jk','pk'/  
      data i / 4*0 /
c
c...   try to read user specification
c
      call inpa(text)
      itype = min(locatc(stype,4,text),3)
      if (itype.ne.0) then
         write(iwr,121) type(itype)
         return
      end if
c
      call search(iblk,iunit)
402   call fget(g,nword,iunit)
      if (nword.eq.0) then 
         write(iwr,101)iblk
         if (nblk.le.0)  return
      else if ((mword.ne.340.and.mword.ne.204).or.nword.ne.511) then
           write(iwr,10301) iblk 
      else
c
         call upack8(gii,i,1)
         if (mword.ne.340) then
            itype = 3
         else if (i(1).eq.0.or.i(2).eq.0.or.i(3).eq.0.or.i(4).eq.0) then
            itype = 2
         else
            itype = 1
         end if
         write (iwr, 120) type(itype)
         call search(iblk,iunit)
         return
c
      end if
c
      nblk=nblk-1
      iblk=iblk+1
      if (nblk.ne.0) go to 402
      return 
c
10301 format(i8,11x,'not mainfile (or incomplete block)')
101   format(i8,10x,'endfile')
120   format(/29x,'the file is in ',a20,'format')
121   format(/29x,'the file is in ',a20,'format (user specified)')
c
      end
      subroutine ulist
      implicit REAL  (a-h,o-z)
      logical logg
      character *4 ai
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
      common/blkin/g(510),mword,mspace,blkspa(512)
      common/craypk/i205(1360)
_IF(linux)
      external fget
_ENDIF
      call setsto(numlab,0,i205)
      iunit =  idisc(ai,iblk)
      call inpi(nblk)
      logg=nblk.le.0
      call maintp(kk,iblk,nblk,iunit)
      if (kk.eq.0) return
      kk = kk + 1
402   call fget(g,nword,iunit)
      if(nword)33,44,33
44    write(iwr,112)
      if(logg)return
      goto 1
 33   go to (20,20,30,40),kk
 20   call spr2ei(iunit,iblk)
      go to 1
 30   call spr2ep(iunit,iblk)
      go to 1
 40   call spr2jk(iunit,iblk)
   1  iblk=iblk+1
      nblk=nblk-1
      if(nblk)402,404,402
404   return
112   format(/3x,'endfile block')
      end
      subroutine spr2ei(iunit,iblock)
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
INCLUDE(common/discc)
      common/craypk/integ(1360)
      common/blkin/g(510),mword,mspace,blkspa(512)
      dimension  f(4),ia(4),ja(4),ka(4),la(4)
c
      write(iwr,100)iblock,yed(iunit)
      n = 0
      if(mword)33,44,33
 44   write(iwr,112)
      go to 404
 33   continue
      call unpack(g(num2e+1),lab816,integ,numlab)
      iword=1
      do 3 m=1,mword
      n=n+1
      f(n)=g(m)
_IF(littleendian)
      ia(n) = integ(iword+1)
      ja(n) = integ(iword  )
      ka(n) = integ(iword+3)
      la(n) = integ(iword+2)
_ELSE
      ia(n) = integ(iword  )
      ja(n) = integ(iword+1)
      ka(n) = integ(iword+2)
      la(n) = integ(iword+3)
_ENDIF
      iword=iword+4
      if(n.lt.4 )goto 3
      write(iwr,101)(ia(n),ja(n),ka(n),la(n),f(n),n=1,4)
      n=0
3     continue
      if(n.ne.0 )write(iwr,101)(ia(m),ja(m),ka(m),la(m),f(m),m=1,n)
      write(iwr,102)mword
404   return
112   format(/3x,'endfile block')
102   format(/' no. of integrals =',i4)
101   format(4(1x,4i3,f16.9))
100   format(/1x,72('*')//45x,'list of block',i6,' from ',a4/
     *45x,27('-')//
     *4(3x,'i',2x,'j',2x,'k',2x,'l',6x,'g',9x)/
     *1x,115('+')/)
      end
      subroutine spr2ep(iunit,iblock)
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
INCLUDE(common/discc)
      common/craypk/ij205(2,340)
      common/blkin/g(510),mword,mspace,blkspa(512)
      dimension f(4),ia(4),ja(4)
      write(iwr,100)iblock,yed(iunit)
      n = 0
      if(mword)33,44,33
 44   write(iwr,112)
      go to 404
 33   continue
      call unpack(g(num2ep+1),lab1632,ij205,numlabp)
      do 3 m=1,mword
      n=n+1
      f(n)=g(m)
      ia(n)=ij205(1,m)
      ja(n)=ij205(2,m)
      if(n.lt.4 )goto 3
      write(iwr,101)(ia(n),ja(n),f(n),n=1,4)
      n=0
3     continue
      if(n.ne.0 )write(iwr,101)(ia(m),ja(m),f(m),m=1,n)
      write(iwr,102)mword
404   return
112   format(/3x,'endfile block')
102   format(/' no. of p-supermatrix elements =',i4)
101   format(4(1x,2i6,f16.9))
100   format(/1x,72('*')//45x,'list of block',i6,' from ',a4/
     *45x,27('-')//
     *4(5x,'ij',4x,'kl',6x,'p',9x)/
     *1x,115('+')/)
      end
      subroutine spr2jk(iunit,iblock)
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
INCLUDE(common/discc)
      common/craypk/ij205(2,204)
      common/blkin/g(510),mword,mspace,blkspa(512)
      dimension ia(4),ja(4),fp(4),fk(4)
      write(iwr,100)iblock,yed(iunit)
      n = 0
      if(mword)33,44,33
 44   write(iwr,112)
      go to 404
 33   continue
      labss = num2ejk+num2ejk+1
      call unpack(g(labss),lab1632,ij205,numlabjk)
      do 3 m=1,mword
      n=n+1
      fp(n)=g(m)
      fk(n)=g(num2ejk+m)
      ia(n)=ij205(1,m)
      ja(n)=ij205(2,m)
      if(n.lt.4 )goto 3
      write(iwr,101)(ia(n),ja(n),fp(n),fk(n),n=1,4)
      n=0
3     continue
      if(n.ne.0 )write(iwr,101)(ia(m),ja(m),fp(m),fk(m),m=1,n)
      write(iwr,102)mword
404    return
112   format(/3x,'endfile block')
102   format(/' no. of pk-supermatrix elements =',i4)
101   format(4(1x,2i5,2f10.6))
 100  format(/1x,72('*')//45x,'list of block',i6,' from ',a4/
     *45x,27('-')//
     *4(4x,'ij',3x,'kl',5x,'p', 9x,'k',4x)/
     *1x,123('+')/)
      end
_IFN(ibm,vax)
      subroutine umerge
      implicit REAL  (a-h,o-z)
      logical nogg
      character *4 la2,lend
INCLUDE(common/sizes)
INCLUDE(common/iofile)
      common/blkin/g1(340),gii1(170),mwrd1,mspac1,
     +             ijkl(680)
      common/bufb/g2(340),gii2(170),mwrd2,mspac2
      common/craypk/i1(1360)
      common/junk/i2(1360),ind(255)
INCLUDE(common/work)
INCLUDE(common/atmblk)
      common/disc/irep(5),nt(maxlfn)
      dimension ii1(2),ii2(2)
      equivalence (ii1(1),gii1(1)),(ii2(1),gii2(1))
_IF(linux)
      external fget
_ENDIF
      data lend/'end'/
      num2=idisc(la2,iblk2)
      mwrd2=0
      int44=1
      write(iwr,100)la2,iblk2
100   format(//' merge to ',a4,'starting at block',i7)
      iupp=iblk2
      call setsto(1360,0,i1)
      call setsto(255,-2000,ind)
c...   read orbital renumbering list
101   call input
      call inpa4(la2)
      if( la2.eq.lend)goto 103
      jrec=0
      call inpi(i)
      call inpi(j)
      call inpi(k)
      ji=j-i
      l=k+ji
      if(j.lt.i.or.i.le.0 .or.j.gt.255 .or.k.le.0 .or.l.gt.255 )call
     * caserr('invalid re-indexing parameter in merge')
      write(iwr,104)i,j,k,l
104    format(/' old basis functions',i4,' to',i4,' renumbered',i4,' to'
     *,i4)
      ji=ji+1
      if(nocat1(ind(i),ji,-2000).ne.0)call caserr
     * ('invalid re-indexing parameter in merge')
      call ibasgn(ji,k,1,ind(i))
      goto 101
103   continue
c     write(6,*) (ind(loop),loop=1,255)
      do 300 i=2,255
      k=ind(i)
      if(k)300,302,302
302   if(locat1(ind,i-1,k).ne.0)call caserr
     * ('invalid re-indexing parameter in merge')
300    continue
c...   process input file
       write(iwr,108)
108   format(//7x,'input file'//6x,'starting terminal'/
     *' lfn     block    block')
106   call input
      call inpa4(la2)
      if( la2.eq.lend)goto 107
      jrec=0
      num1=idisc(la2,iblk1)
      nogg=num1.eq.num2
      call inpi(nblk)
      write(iwr,400)la2,iblk1,nblk
400   format(1x,a4,2i9)
      nblk=iblk1-nblk
401   if(nblk)707,106,707
707   if(nogg.and.iblk1.ge.iblk2.and.iblk1.lt.iupp)call
     * caserr('conflict between input and output disk areas')
      call search(iblk1,num1)
      call fget(g1,nword,num1)
      if(nword)7600,106,7600
 7600 continue
      call unpack(g1(num2e+1),lab816,i1,numlab)
_IFN(cray)
       ind4 = 1
       do loop =1,mwrd1
_IF(littleendian)
        mi=i1(ind4+1)
        mj=i1(ind4  )
        mk=i1(ind4+3)
        ml=i1(ind4+2)
_ELSE
        mi=i1(ind4  )
        mj=i1(ind4+1)
        mk=i1(ind4+2)
        ml=i1(ind4+3)
_ENDIF
        i1(ind4  ) =  ind(mi)
        i1(ind4+1) =  ind(mj)
        i1(ind4+2) =  ind(mk)
        i1(ind4+3) =  ind(ml)
        ind4 = ind4 + 4
       enddo
_ELSE
       call gather(mwrd1,i1,i1,ind)
       call gather(mwrd1,j1,j1,ind)
       call gather(mwrd1,k1,k1,ind)
       call gather(mwrd1,l1,l1,ind)
_ENDIF
      int4=1
      do 200 kk=1,mwrd1
_IF(littleendian)
      mi=i1(int4+1)
      mj=i1(int4  )
      mk=i1(int4+3)
      ml=i1(int4+2)
_ELSE
      mi=i1(int4  )
      mj=i1(int4+1)
      mk=i1(int4+2)
      ml=i1(int4+3)
_ENDIF
      int4=int4+4
      if(mi+mj+mk+ml)200,10000,10000
10000 mwrd2=mwrd2+1
      g2(mwrd2)=g1(kk)
      i2(int44  )=mi
      i2(int44+1)=mj
      i2(int44+2)=mk
      i2(int44+3)=ml
      int44=int44+4
      if(mwrd2.lt.340)goto 200
      call search(iupp,num2)
      call pack(ii2,8,i2,1360)
c     call pak8x(i2,ii2)
      call put(g2,511,num2)
      mwrd2=0
      int44=1
      iupp=iupp+1
200   continue
      iblk1=iblk1+1
      nblk=nblk+1
      goto 401
 107  call search(iupp,num2)
      if(mwrd2.ne.0) then
c      call pak8x(i2,ii2)
       call pack(ii2,8,i2,1360)
       call put(g2,511,num2)
      endif
      call put(g2,0,num2)
      return
      end
_ENDIF
      function idisc(ai,iblk)
      implicit REAL  (a-h,o-z)
      character *(*) ai
      character *4 anam
      character *8 lb,lbpos,lapos,laneg,lstar
INCLUDE(common/sizes)
INCLUDE(common/work)
INCLUDE(common/discc)
       common/disc/irep(5),nt(maxlfn)
      data lbpos,lapos,laneg,lstar/'&','+','-','*'/
      call inpa4(ai)
      k=locatc(yed,maxlfn,ai)
      if(k.eq.0)call caserr('lfn not recognised')
      idisc=k
      if(nt(k).eq.0)call search(1,k)
      call inpa(lb)
      if(lb.ne.lstar) go to 4
      iblk = nt(k)
      call inpa(lb)
      if(lb.ne.laneg)goto 5
      call inpi(ic)
      iblk=iblk-ic
      goto 3
 5    if(lb.ne.lapos.and.lb.ne.lbpos)goto 6
      call inpi(ic)
      iblk=iblk+ic
      goto 3
6     jrec=jrec- 1
      return
4     jrec=jrec- 1
      call inpi(iblk)
3     call search(iblk,k)
      return
      end
_IF(cray)
      subroutine upack8(iii,i,kk)
      implicit REAL  (a-h,o-z)
      common/tran/mword(340),iword(340)
      dimension iii(*),i(*)
      mw=mword(kk)
      iw=iword(kk)
      i(1)=and(shiftr(iii(mw),iw+24),377b)
      i(2)=and(shiftr(iii(mw),iw+16),377b)
      i(3)=and(shiftr(iii(mw),iw+8 ),377b)
      i(4)=and(shiftr(iii(mw),iw   ),377b)
      return
      end
_ELSEIF(ibm,vax)
      subroutine upack8(iii,i,kk)
      implicit REAL  (a-h,o-z)
      logical *1 mij,mkl,i
      common/blkin/g(340),mij(680),mkl(680)
      dimension iii(*),i(*)
      il=kk+kk
      i(4)=mij(il-1)
      i(8)=mij(il  )
      i(12)=mkl(il-1)
      i(16)=mkl(il  )
      return
      end
_ELSE
      subroutine upack8(iii,i,kk)
      implicit REAL  (a-h,o-z)
      logical *1 iii,i
_IF(i8)
      dimension iii(*),i(8,*)
      k=(kk-1)*4
_IF(littleendian)
      i(1,1) = iii(k+2)
      i(1,2) = iii(k+1)
      i(1,3) = iii(k+4)
      i(1,4) = iii(k+3)
_ELSE
      i(8,1) = iii(k+1)
      i(8,2) = iii(k+2)
      i(8,3) = iii(k+3)
      i(8,4) = iii(k+4)
_ENDIF
_ELSE
      dimension iii(*),i(4,*)
      k=(kk-1)*4
_IF(littleendian)
      i(1,1) = iii(k+2)
      i(1,2) = iii(k+1)
      i(1,3) = iii(k+4)
      i(1,4) = iii(k+3)
_ELSE
      i(4,1) = iii(k+1)
      i(4,2) = iii(k+2)
      i(4,3) = iii(k+3)
      i(4,4) = iii(k+4)
_ENDIF
_ENDIF
      return
      end
_ENDIF
_IFN(cray,ibm,vax)
      subroutine pak8x(i2,ii2)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common/blkin/gsp(511),nsp(2),ij205(680)
INCLUDE(common/mapper)
      dimension i2(*),ii2(*)
      mword=ii2(341)
      int=1
      int4=1
      do 1 i=1,mword
      iti=i2(int    )
      jtj=i2(int+1)
      ktk=i2(int+2)
      ltl=i2(int+3)
      ii=max(iti,jtj)
      jj=min(iti,jtj)
      kk=max(ktk,ltl)
      ll=min(ktk,ltl)
      if((iky(ii)+jj).ge.(iky(kk)+ll))go to 6
      ij205(int4  )=ll+i4096(kk)
      ij205(int4+1)=jj+i4096(ii)
      go to 11
   6  ij205(int4  )=jj+i4096(ii)
      ij205(int4+1)=ll+i4096(kk)
   11 int4=int4+2
   1  int=int+1
      call pack(ii2,16,ij205,680)
      return
      end
      subroutine upack4(iii,i,kk)
      implicit REAL  (a-h,o-z)
      integer *2 iii,i
      dimension iii(*),i(2,*)
      k=(kk-1)*2+1
      do 1 loop=1,2
      i(2,loop)=iii(k)
  1   k=k+1
      return
      end
_ENDIF
_IF(parallel)
c
c** generic fgett (parallel)
c
      subroutine fgett(c,nword,iunit)
      implicit REAL  (a-h,p-w),integer(i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
INCLUDE(common/nodeio)
INCLUDE(common/disc)
c
      common/bufa/abc(512*maxlfn)
c
      dimension c(*)
c
      common/vinteg/q(1)
INCLUDE(common/maxlen)
_IF(64bitpointers)
      integer*8 iword
_ENDIF
c
      common /brdcst_stats/ ibrdcst(maxlfn), brdcst_l(maxlfn)
c
      isel = iunit
      irec=ipos(isel)
      nstart=(iunit-1)*512+1
cPS ipsc has fail code 3 here?
      if (irec.lt.1) call iofail(iunit,1)
c
      if (iwhere(iunit).eq.0 .or.
     +          iwhere(iunit).eq.3 ) then
c
c...   concurrent io on each node
c
         if (isync(iunit).eq.0) then
_IFN(charmm)
c...   asynchronous
            if (ids48(iunit).ge.0) then
              call iowt(ids48(iunit))
              ids48(iunit)=-1
            end if
            idr48(iunit) = iread(nam(iunit),abc(nstart),4096)
_ELSE
            call caserr('async i/o clashes with charmm')
_ENDIF
         end if
c
      else  if (opg_root().and.iwhere(iunit).eq.2) then
c
c...   concurrent io on node 0
c
c...   asynchronous
         if (isync(iunit).eq.0) then
_IFN(charmm)
            if (ids48(iunit).ge.0) then
              call iowt(ids48(iunit))
              ids48(iunit)=-1
            end if
            idr48(iunit) = iread(nam(iunit),abc(nstart),4096)
_ELSE
            call caserr('async i/o clashes with charmm')
_ENDIF
         end if
c
      end if
c
c     now the GET ...
c
_IF(ga)
      If( iwhere( isel ) .EQ. 6 .Or. iwhere( isel ) .EQ. 7 ) Then 
         Call get_ga( c, nword )
      Else
_ENDIF

      iunit = isel
      irec = ipos(iunit)
      nstart=(iunit-1)*512+1
c
      if (iwhere(iunit).eq.0 .or.
     +         iwhere(iunit).eq.3   ) then
c...   concurrent io -- same for all
         if (isync(iunit).eq.0) then
c...   asynchronous
            call iowt(idr48(iunit))
            idr48(iunit)=-1
         else
            call getcc(nam(isel),abc(nstart),ierrio)
            if(ierrio.ne.0)call ioerr('read',isel,' ')
         end if
      else if (iwhere(iunit).eq.2) then
         if (opg_root()) then
c        root has to get from cfs and send
          if (isync(iunit).eq.0) then
            call iowt(idr48(iunit))
            idr48(iunit)=-1
         else
            call getcc(nam(isel),abc(nstart),ierrio)
            if(ierrio.ne.0)call ioerr('read',isel,' ')
         end if
            if (oswed3(iunit)) then
c...        record received  send
              itypn = iunit*1000+irec
              call pg_brdcst(itypn,abc(nstart),4096,0)
             ibrdcst(iunit) = ibrdcst(iunit) + 1
             brdcst_l(iunit) = brdcst_l(iunit) + 4096.0d0
            endif
         else
c...    not a node root so receive
            if (oswed3(iunit)) then
            itypn = iunit*1000+irec
            call pg_brdcst(itypn,abc(nstart),4096,0)
           endif
         endif
      else if (iwhere(iunit).eq.4) then
c
c     read from node memory
c
         iword = (irec-1)*512+iqqoff(iunit)+1
         call upack2(q(iword+511),iibl,nword)
         if (nword.gt.512.or.nword.lt.0.
     *        or.iibl.ne.ipos(iunit)) then
            print *,' node ',minode,' **** memory error on unit ',iunit
            print *,' node ',minode,' **** block read was',iibl
            print *,' node ',minode,' **** position was  ',ipos(iunit)
            call caserr('error in node memory access')
         end if
         call dcopy(nword,q(iword),1,c,1)
         go to 200
c
      else if (iwhere(iunit).eq.5) then
       if (opg_root()) then
c     read from node memory (node 0)
c
         iword = (irec-1)*512+iqqoff(iunit)+1
         call dcopy(512,q(iword),1,abc(nstart),1)
         call upack2(q(iword+511),iibl,nword)
          if (nword.gt.512.or.nword.lt.0.
     *   or.iibl.ne.ipos(iunit)) then
        print *,' node ',minode,' **** memory error on unit ',iunit
        print *,' node ',minode,' **** block read was',iibl
        print *,' node ',minode,' **** position was  ',ipos(iunit)
          call caserr('error in node memory access')
          end if
          if(oswed3(iunit)) then
c...         record received  send
           itypn = iunit*1000+irec
           call pg_brdcst(itypn,abc(nstart),4096,0)
          endif
       else
c...    not a node root so receive
        if(oswed3(iunit)) then
          itypn = iunit*1000+irec
          call pg_brdcst(itypn,abc(nstart),4096,0)
        endif
       endif
      else
c...   host-io synchronous only
         call synget(abc(nstart),512,nam(iunit),irec)
      end if
c...
c...    received => check
c...
      call upack2(abc(iunit*512),iibl,nword)
      if (nword.gt.512.or.nword.lt.0.
     * or.iibl.ne.ipos(iunit)) then
         print *,'nword check',nword
         print *,' node ',minode,' **** error on unit ',iunit
         print *,' node ',minode,' **** block read was',iibl
         print *,' node ',minode,' **** position was  ',ipos(iunit)
         call caserr('i/o error detected')
      end if
      call dcopy(nword,abc(nstart),1,c,1)
c
 200  ipos(isel)=irec+1
c
_IF(ga)
      End If
_ENDIF
c
      return
      end
_ELSE
_IFN(cray,convex,alliant,hp700,hpux11,apollo,rs6000,sgi,sun,ksr)
      subroutine fgett(gin,m,iunit)
c....   if nothing better use effectively fget (e.g. vax/ibm,ipsc
      implicit REAL  (a-h,o-z)
      dimension gin(*)
      call find(iunit)
      call get(gin,m)
      return
      end
_ENDIF
_IF(alliant,hp700,hpux11,apollo,rs6000,sgi,sun,ksr)
      subroutine fgett(c,nword,iunit)
      implicit REAL (a-h,p-w),integer(i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF1(k)      integer *4 nchk, nnchk
c
c...   not critical fget 
c...   checksum-error returns nword=-99999
c
INCLUDE(common/sizes)
      dimension c(*),nchk(1024),nnchk(2)
c ... single-buffered  i/o
      common/bufa/abc(512)
      common/disc/isel,iselr ,iselw,irep,ichek,ipos(maxlfn),
     * nam(maxlfn)
INCLUDE(common/maxlen)
_IF(64bitpointers)
      integer*8 iword
_ENDIF
      common/vinteg/q(1)
      equivalence (abc(1),nchk(1)),(dum,nnchk(1))
c
      call find(iunit)
c
      irec=ipos(isel)
      if (irec.lt.1) call iofail(isel,1)
      if(omem(isel)) then
       iword = (irec-1)*512+iqqoff(isel)+1
       call dcopy(512,q(iword),1,c,1)
       dum = q(iword+511)
       nword = nnchk(2)
      else
c
c --- this is for the non multi-buffered streams
c
         call getcc(nam(isel),abc,ierrio)
         if(ierrio.ne.0) then
            nword = -99999
            return
         end if
c
c --- prepare to return results to the program
c
       nword=nchk(1024)
       call dcopy(512,abc(1),1,c,1)
      endif
      ipos(isel)=irec+1
      return
      end
_ENDIF
_IF(convex)
      subroutine fgett(ic,nword,iunit)
      implicit REAL  (a-h,o-z)
      integer *8 ibufa,igetm,iputm,kunkpb,junjpb
      integer *8 lunlpb,mask,mask0,l,lmask
      integer *8 packi8
      integer *8 ic
INCLUDE(common/sizes)
      dimension ic(*)
      common/bufnew/ibufa(512)
      common/disc/irep,incr,npb,npbsz,npbm1,ipos(maxlfn),
     * nam(maxlfn)
      common/discne/
     *mlen(maxlfn),length(maxlfn),iostat(maxlfn),
     *iobuff(maxlfn),itab(maxlfn),
     *istabf(maxbuf+2),ipribf(maxbuf),junibf(maxbuf),
     *jpbbf(maxbuf),junjpb(maxbuf),
     *ibfbas(maxbuf),igetm(maxbuf),iputm(maxbuf),
     *kunkpb,mbuff,lunx,latmx,lblx,lbfbax,lbuffx
      common/maskc/mask(64)
      data lmask/'8000000000000000'x /
      data mask0/'0'x /
c...
c... synchronous input routine
c... nword = -99999 suggests checksum error
c...
      lun=iunit
      lbl=ipos(lun)
      lpb=(lbl-1)/npbsz
c      lunlpb=insert(lpb,0,32,lun)
      lunlpb=packi8(lun,lpb)
      lat=lpb*npbsz
      latm=lbl-lat
      if(lunlpb.eq.kunkpb)goto 776
      kunkpb=lunlpb
      mbuff=locatz(junjpb,npb,lunlpb)
      if(mbuff)777,888,777
c... physical block not in buffers
888   mbuff=locat1(ipribf,npb,npbm1)
      igetm(mbuff)=mask0
      lbfbas=ibfbas(mbuff)
      call termbf
      jpbbf(mbuff)=lpb
      junibf(mbuff)=lun
      junjpb(mbuff)=lunlpb
      call revpri
      goto 333
c... physical block in buffer-check for put status
777   call revpri
776   lbfbas=ibfbas(mbuff)
      if(istabf(mbuff))666,444,444
666   mzero=0
      iat=lat
      l=iputm(mbuff)
      m=lbfbas
      call chekwr(lun)
      istabf(iobuff(lun))=0
3       if(l.eq.mask0)goto 4
       nzero=leadz(l)
      iat=iat+nzero
      m=(nzero+mzero)*512+m
      l=ishft(l,nzero)
       mzero=leadz(not(l))
      call chekwr(lun)
      call flushv(lun,ibufa(m+1),mzero,iat)
       l=ishft(l,mzero)
      iat=iat+mzero
      goto 3
4     if(length(lun).lt.iat)length(lun)=iat
      iobuff(lun)=mbuff
      istabf(mbuff)=2
444   l=ishft(igetm(mbuff),latm-1)
      if(iand(l,lmask).eq.lmask)goto 999
c... internal block missing
333   m=length(lun)-lat-npbsz
      iat=npbsz
       istabf(iobuff(lun))=0
      call chekwr(lun)
      if(m)21,20,20
21    iat=iat+m
      if(iat)1,1,20
1     call iofail(lun,1)
20    call fillv(lun,ibufa(lbfbas+1),iat,lat)
      iobuff(lun)=mbuff
      istabf(mbuff)=1
      igetm(mbuff)=mask(iat)
999    ipos(lun)=lbl+1
      if(istabf(mbuff).eq.1)call chekwr(lun)
      m=latm*512+lbfbas
      call vmov(ibufa(m-511),1,ic,1,512)
      call upaki8(ibufa(m),nword,iblok)
      if(iblok.ne.lbl) nword = -99999
      return
      end
_ENDIF
_IF(cray)
      subroutine fgett(ic,nword,iunit)
      implicit REAL  (a-h,p-w),integer  (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character  *4 (y)
c
c....   synchronous not so critical io
c....   nword = -99999 indicates wrong block-number
c
INCLUDE(common/sizes)
      common/bufnew/ibufa(512)
      common/disc/incr,npb,npbsz,irep,npbm1,ipos(maxlfn),
     * nam(maxlfn)
INCLUDE(common/discc)
      common/discne/i40(maxlfn),length(maxlfn),iostat(maxlfn),
     *iobuff(maxlfn),itab(maxlfn*40),
     *istabf(maxbuf+1),ipribf(maxbuf),junibf(maxbuf),
     *jpbbf(maxbuf),junjpb(maxbuf),
     *ibfbas(maxbuf),igetm(maxbuf),iputm(maxbuf),
     *mbuff,kunkpb,lun,l40,latm,lbl,lbfbas,lbuff
      dimension ic(*)
      lun=iunit
      lbl=ipos(lun)
      lpb=(lbl-1)/npbsz
      l40=i40(lun)
      lunlpb=shiftl(lun,32).or.lpb
      lat=lpb*npbsz
      latm=lbl-lat
      if(lunlpb.eq.kunkpb)goto 776
      kunkpb=lunlpb
      mbuff=locat(junjpb,lunlpb)
      if(mbuff)777,888,777
c... physical block not in buffers
888   mbuff=locat(ipribf,npbm1)
      igetm(mbuff)=0
      lbfbas=ibfbas(mbuff)
      call termbf
      jpbbf(mbuff)=lpb
      junibf(mbuff)=lun
      junjpb(mbuff)=lunlpb
      call revpri
      goto 333
c... physical block in buffer-check for put status
777   call revpri
776   lbfbas=ibfbas(mbuff)
      if(istabf(mbuff))666,444,444
666   mzero=0
      iat=lat
      l=iputm(mbuff)
      m=lbfbas
      call chekwr(itab(l40))
      if(irep)1,77,1
77    istabf(iobuff(lun))=0
      iostat(lun)=2
3       if(l)99,4,99
99     nzero=leadz(l)
      iat=iat+nzero
      m=(nzero+mzero)*512+m
      l=shiftl(l,nzero)
       mzero=leadz(compl(l))
      call chekwr(itab(l40))
      if(irep)1,5,1
1     call iofail(yed(lun),iostat(lun))
5     call flushw(itab(l40),ibufa(m+1),mzero,iat+1,lun)
       l=shiftl(l,mzero)
      iat=iat+mzero
      goto 3
4     if(length(lun).lt.iat)length(lun)=iat
      iobuff(lun)=mbuff
      istabf(mbuff)=2
444   l=shiftl(igetm(mbuff),latm-1)
      if(l)999,333,333
c... atmol block missing
333   m=length(lun)-lat-npbsz
      iat=npbsz
       istabf(iobuff(lun))=0
      call chekwr(itab(l40))
      if(irep)1,19,1
19     iostat(lun)=1
      if(m)21,20,20
21    iat=iat+m
      if(iat)1,1,20
20    call fillv(lun,itab(l40),ibufa(lbfbas+1),iat,lat+1)
      iobuff(lun)=mbuff
      istabf(mbuff)=1
      igetm(mbuff)=mask(iat)
999    ipos(lun)=lbl+1
      if(istabf(mbuff).eq.1) then
         call chekrd(itab(l40),latm)
         if(irep.ne.0) then
         call iofail(yed(lun),1)
         endif
      endif
      m=latm*512+lbfbas
      call fmove(ibufa(m-511),ic,512)
      mword = ibufa(m)
      iblok = mword.and.37777777777b
      nword=shiftr(mword,32)
      if(iblok.ne.lbl) nword = -99999
      return
      end
_ENDIF
_ENDIF
      subroutine uschk(iia)
      implicit REAL  (a-h,o-z)
      character *8 iib,iia
      character *4 ai
      character *8 text,type
      logical logg,nogg
      common/blkin/g(511),b,i(4)
INCLUDE(common/iofile)
INCLUDE(common/work)
      equivalence (g(511),m)
      dimension type(5)
      data type/'2e','p','psort','jk','pk'/
      data iib/'checksum'/
      data fac/1.0d-8/
      nbasis=0
      iunit=idisc(ai,iblk)
      do 601 loop=1,4
 601  i(loop)=0
      call inpi(nblk)
      logg=nblk.le.0
      call inpa(text)
      kk=min(locatc(type,5,text),4) +1
c
      if (kk.eq.1) then
         jrec = jrec - 1
         call maintp(kk,iblk,nblk,iunit)
         if (kk.eq.3) kk = 4
         kk = kk + 1  
         jrec = jrec - 1
      end if
c
      nogg=iia.eq.iib
      if(logg)goto 401
      write(iwr,101)iia,ai,iblk,nblk
101   format(//1x,a8,1x,a4,'from block',i7,' for',i7,' blocks')
      goto 702
401   write(iwr,100)iia,ai,iblk
100   format(//1x,a8,1x,a4,'from block',i7,' to endfile block')
702     if(nogg)goto 404
      call inpf(f1)
      call inpf(f2)
      if(f1.lt.fac)f1=5.0d0
      if(f2.lt.fac)f2=0.5d0
      call inpi(nbasis)
      if(nbasis.le.0.or.nbasis.gt.255) nbasis=0
      write(iwr,99)f1,f2
99    format(/' positive integral threshold=',f14.7//
     1' negative integral threshold=',f14.7)
      if(nbasis.gt.0) write(iwr,9998)nbasis
9998  format(/' nbasis = ',i6)
404   call fgett(g,nword,iunit)
      if(nword.le.511.and.nword.ge.0)go to 600
      write(iwr,102)iblk
102   format(' block',i7,' checksum error')
      goto 403
600   if(nword.ne.0)goto 700
      write(iwr,130)iblk
      if(logg)return
      goto 403
700   if(nogg)go to 403
      if(nword.ne.511.or.m.le.0.or.m.gt.340)goto 900
      go to (20,20,30,50,40),kk
 20   call usc2e(f1,f2,iblk)
      go to 403
 30   call uscp(f1,f2,iblk)
      go to 403
 50   call uscps(f1,f2,iblk,nbasis)
      go to 403
 40   call uscjk(f1,f2,iblk)
403   iblk=iblk+1
      nblk=nblk-1
      if(nblk)404,405,404
405   return
130   format(' block',i7,' endfile')
900   write(iwr,150)iblk
150   format(' block',i7,' not mainfile')
      goto 403
      end
      subroutine usc2e(f1,f2,iblk)
      implicit REAL  (a-h,o-z)
      common/blkin/g(340),gij(171),b,i(4)
INCLUDE(common/iofile)
      dimension iii(2)
      equivalence (iii(1),gij(1)),(gij(171),m)
      do 601 loop=1,4
 601  i(loop)=0
      do 11 kk=1,m
      c=g(kk)
      if(c)12,13,13
 12   if(c+f2)14,11,11
 13   if(c.le.f1)go to 11
14     call upack8(iii,i,kk)
      write(iwr,120)iblk,c,(i(loop),loop=1,4)
120   format(' 2e-block',i7,' g,i,j,k,l=',e20.10,4i7)
11    continue
      return
      end
      subroutine uscp(f1,f2,iblk)
      implicit REAL  (a-h,o-z)
_IF(ibm,vax)
      logical o340
      common/blkin/g(340),gij(171),b,i(2),o340
_ELSE
      common/blkin/g(340),gij(171),b,i(2)
_ENDIF
INCLUDE(common/iofile)
      dimension iii(2)
      equivalence (iii(1),gij(1)),(gij(171),m)
_IF1(iv)      o340=.true.
      do 11 kk=1,m
      c=g(kk)
      if(c)12,13,13
 12   if(c+f2)14,11,11
 13   if(c.le.f1)go to 11
14     call upack4(iii,i,kk)
      write(iwr,120)iblk,c,(i(loop),loop=1,2)
120   format(' p-block',i7,' g,ij,kl=',e20.10,2i7)
11    continue
      return
      end
      subroutine uscps(f1,f2,iblk,nbas)
      implicit REAL  (a-h,o-z)
_IF1(a)      integer *8 fiv11,i8temp,iij
_IF1(Gtpgbdrhs)      integer  fiv11,i8temp(2)
_IF1(x)      integer *8 fiv11,i8temp
_IF1(k)      integer fiv11,i8temp
_IF1(xk)      integer *2 iij
_IF1(iv)      integer fiv11
_IF1(iv)      integer *2 ij205,kl205
_IF1(iv)      dimension i8temp(2)
_IF1(xk)      common/blkin/g(340),iij(680),mword
_IFN1(ivxk)      common/blkin/g(340),gij(170),mword
_IFN1(iv)      common/craypk/ij205(340),kl205(340)
_IF1(iv)      common/blkin/g(340),ij205(340),kl205(340),mword
INCLUDE(common/iofile)
_IFN1(ivxk)      dimension iij(2),iballs(680)
_IF1(iv)      equivalence (r8temp,i8temp(1))
_IFN1(ivxk)      equivalence (iij(1),gij(1))
_IFN1(civ)      equivalence (i8temp,r8temp)
_IFN1(c)      data fiv11/511/
      if(mword.le.0) return
c
_IFN1(ivxk)      call unpack(iij,16,iballs,680)
_IFN1(iv)      iword = 1
_IFN1(iv)      do 19 i = 1,mword
_IFN1(ivxk)          ij205(i) = iballs(iword)
_IFN1(ivxk)          kl205(i) = iballs(iword+1)
_IF1(xk)          ij205(i) = iij(iword)
_IF1(xk)          kl205(i) = iij(iword+1)
_IFN1(iv)19        iword = iword + 2
      iwlo = 1
 10   continue
      nbas2=nbas*(nbas+1)/2
c
_IF1()cc_IF1(c)      nij = and(511,g(iwlo))
_IF1()cc_IFN1(c)      r8temp=g(iwlo)
_IF1()cc_IF1(xa)      nij=iand(fiv11,i8temp)
_IF1()cc_IF1(k)      nij=and(fiv11,i8temp)
_IF1()cc_IF1(ivbt)      nij=iand(fiv11,i8temp(2))
_IF1()cc_IF1(pgsdrh)      nij=and(fiv11,i8temp(2))
c
_IF(cray,t3d)
      nij = and(511,g(iwlo))
_ELSE
      r8temp=g(iwlo)
_IF(convex,ksr)
      nij=IAND64(fiv11,i8temp)       
_ELSEIF(littleendian)
      nij=IAND32(fiv11,i8temp(1))  
_ELSE
      nij=IAND32(fiv11,i8temp(2))
_ENDIF
_ENDIF
      ij = ij205(iwlo)
      iwhi = iwlo + nij - 1
      if(iwhi.gt.mword) call caserr('invalid length in block')
      if(ij.ne.ij205(iwhi)) call caserr('ij mismatch in block')
      if(nbas2.gt.0) then
      do 121 iw=iwlo,iwhi
      if(ij.le.0.or.ij.gt.nbas2.or.kl205(iw).le.0.
     * or.kl205(iw).gt.nbas2) then
      write(iwr,130)iblk,ij,kl205(iw)
130   format(' p-block',i7,' invalid ij,kl=',2i7)
      endif
121   continue
      endif
      do 11 iw=iwlo,iwhi
      c=g(iw)
      if(c)12,13,13
 12   if(c+f2)14,11,11
 13   if(c.le.f1)go to 11
 14   write(iwr,120)iblk,c,ij,kl205(iw)
120   format(' p-block',i7,' g,ij,kl=',e20.10,2i7)
11    continue
      iwlo = iwhi + 1
      if(iwlo.le.mword) goto 10
      return
      end
      subroutine uscjk(f1,f2,iblk)
      implicit REAL  (a-h,o-z)
_IF(ibm,vax)
      logical o340
      common/blkin/ga(204),gb(204),gij(103),b,i(2),o340
_ELSE
      common/blkin/ga(204),gb(204),gij(103),b,i(2)
_ENDIF
INCLUDE(common/iofile)
      dimension iii(2)
      equivalence (iii(1),gij(1)),(gij(103),m)
_IF1(iv)      o340=.false.
      do 11 kk=1,m
      c=dmax1(ga(kk),gb(kk))
      if(c)12,13,13
 12   if(c+f2)14,11,11
 13   if(c.le.f1)go to 11
14     call upack4(iii,i,kk)
      write(iwr,120)iblk,c,(i(loop),loop=1,2)
120   format(' j+k block',i7,' g,ij,kl=',e20.10,2i7)
11    continue
      return
      end
_IF(cray)
       subroutine upack4(iii,i,kk)
      implicit REAL  (a-h,p-w),integer  (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension i(*),iii(*)
      nw=(kk-1)/2+1
      if(mod(kk,2).eq.0)then
        iw=0
      else
        iw=32
      endif
      i(1)=and(shiftr(iii(nw),iw+16),177777b)
      i(2)=and(shiftr(iii(nw),iw   ),177777b)
       return
      end
      subroutine pak8x(i2,ii2)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common/blkin/gsp(511),nsp(2),ij205(680)
INCLUDE(common/mapper)
      dimension i2(*),ii2(*)
      mword=ii2(171)
      int=1
      int4=1
      do 1 i=1,mword
      iti=i2(int    )
      jtj=i2(int+1)
      ktk=i2(int+2)
      ltl=i2(int+3)
      ii=max(iti,jtj)
      jj=min(iti,jtj)
      kk=max(ktk,ltl)
      ll=min(ktk,ltl)
      if((iky(ii)+jj).ge.(iky(kk)+ll))go to 6
      ij205(int4  )=ll+i4096(kk)
      ij205(int4+1)=jj+i4096(ii)
      go to 11
   6  ij205(int4  )=jj+i4096(ii)
      ij205(int4+1)=ll+i4096(kk)
   11 int4=int4+2
   1  int=int+1
      call pack(ii2,16,ij205,680)
      return
      end
_ENDIF
c
c  punchfile - table to print at start of job step
c
      subroutine blktab(ostopr)
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/runlab)
INCLUDE(common/atmol3)
INCLUDE(common/blocks)
INCLUDE(common/infoa)
      dimension ybuf(10), ostop(60)
c
c---- write out formatted file for graphics and post-analysis
c   (some blocks are also written out during the calculation)
c
      o = .false.
      do 10 i = 1,LENPUN
 10      o = o .or. oblock(i)

      if(.not.o)return

      o0 = opg_root()
c
c  Handling of test runs : old keyword presented on punch
c  forces attempt to use old dumpfile - if not offered 
c  suppress data that we won't have
c
      if(ostopr)then
         if(.not. opunold)then
            do i = 1,60
               ostop(i)=.false.
            enddo
            ostop(1) = .true.
            ostop(3) = .true.
            ostop(4) = .true.
            ostop(7) = .true.
            ostop(11) = .true.
            ostop(14) = .true.
            ostop(20) = .true.
            ostop(24) = .true.
            otmp = .false.
            do i = 1,60
               if(oblock(i) .and. .not. ostop(i))then
                  otmp = .true.
                  oblock(i) = .false.
               endif
            enddo
            if(o0 .and. otmp)write(iwr,1005)
 1005  format(//,1x,'*** Warning - as job termination has been',
     &  ' requested some punchfile requests will be ignored ***'/)
         endif
      endif

      if((oblock(5).or.oblock(6).or.oblock(12)
     & .or.oblock(13)).and.nblsec.eq.0)then
c try and find the user suitable default vectors section(s)
         if(zruntp.eq.'scf     '.or.zruntp.eq.'optimize'.or.
     *      zruntp.eq.'saddle  '.or.zruntp.eq.'optxyz  '.or.
     *      zruntp.eq.'jorgense'.or.
     *      zruntp.eq.'gradient'.or.
     *      zruntp.eq.'force   '.or.
     *      zruntp.eq.'hessian '.or.
     *      zruntp.eq.'polariza'.or.
_IF(drf)
     *      zruntp.eq.'montec  '.or.
_ENDIF
     *      zruntp.eq.'prop    ')then
            if(zscftp.eq.'rhf')then
              nblsec = 1
              iblsec(1) = mouta
              if(moutb.ne.0)iblsec(1) = moutb
            else if(zscftp.eq.'uhf')then
              nblsec = 2
              iblsec(1) = mouta
              iblsec(2) = moutb
            else if(zscftp.eq.'gvb')then
              nblsec = 1
              iblsec(1) = moutb
            else
              call caserr
     *         ('automatic selection of vectors for punchfile failed')
           endif
         else
           call caserr
     *     ('automatic selection of vectors for punchfile failed')
         endif
      endif
      write(iwr,1010)
      if(o0 .and. oblock(PUN_JOB_TITLE))write(iwr,2014)
      if(o0 .and. oblock(PUN_RUNT))write(iwr,2007)
      if(o0 .and. oblock(PUN_SCF_TYPE))write(iwr,2020)
      if(o0 .and. oblock(PUN_COORD))write(iwr,2001)
      if(o0 .and. oblock(PUN_OPT_COORD))write(iwr,2002)
      if(o0 .and. oblock(PUN_START_COORD))write(iwr,2003)
      if(o0 .and. oblock(PUN_ATOM_CONN))write(iwr,2004)
      if(o0 .and. oblock(PUN_BASIS))write(iwr,2011)
      if(o0 .and. oblock(PUN_OVLP_MAT))write(iwr,2015)
      if(o0 .and. nblsec.ne.0)then
         do 15 i=1,10
         if(i.le.nblsec)then
            write(ybuf(i),1015)iblsec(i)
         else
            ybuf(i)=' '
         endif
 15   continue
         write(iwr,1020)ybuf
         write(iwr,1030)
         if(oblock(PUN_EIGV))write(iwr,2006)
         if(oblock(PUN_MO_OCC))write(iwr,2005)
         if(oblock(PUN_ORB_ENER))write(iwr,2012)
         if(oblock(PUN_SCF_ENER))write(iwr,2013)
      endif
      if(o0 .and. oblock(PUN_TOT_ENER))write(iwr,2030)
      if(o0 .and. oblock(PUN_ZMAT_HESS))write(iwr,2031)
      if(o0 .and. oblock(PUN_DIPOLE))write(iwr,2032)
      if(o0 .and. oblock(PUN_GVBPAIR))write(iwr,2008)
      if(o0 .and. oblock(PUN_FCMAT))write(iwr,2009)
      if(o0 .and. oblock(PUN_MULLIKEN))write(iwr,2017)
      if(o0 .and. oblock(PUN_LOWDIN))write(iwr,2018)
      if(o0 .and. oblock(PUN_SPIN_DENS))write(iwr,2019)
      if(o0 .and. oblock(PUN_VIB_MODES))write(iwr,2021)
      if(o0 .and. oblock(PUN_GRADIENTS))write(iwr,2023)
      if(o0 .and. oblock(PUN_TRANS_MAT))write(iwr,2024)
      if(o0 .and. oblock(PUN_POT_DERV_CHG))write(iwr,2025)
      if(o0 .and. oblock(PUN_VIBFREQ))write(iwr,2010)
      if(o0 .and. oblock(PUN_GRID_DATA))then
         do 16 i=1,10
         if(i.le.nblgri)then
            write(ybuf(i),1015)iblgri(i)
         else
            ybuf(i)=' '
         endif
 16      continue
         write(iwr,2016)ybuf
         if(oblock(PUN_GRID_SYMM))write(iwr,2026)
      endif
      if(o0 .and. oblock(PUN_2E_INT))then
         if(ntwoe.ne.0)then
            write(iwr,20221)itwoe,ntwoe
         else
            write(iwr,20222)itwoe
         endif
      endif
      if(o0 .and. oblock(PUN_HESSIAN))write(iwr,2027)
      if(o0 .and. oblock(PUN_MPOLE_ANAL))write(iwr,2028)
      if(o0 .and. oblock(PUN_DENS_MAT))write(iwr,2029)
      write(iwr,1035)
      return
c
 1000 format(/1x,'WARNING : no gvb data written to punchfile',
     &       ' *** this is not a GVB calculation ***')
 1010 format(1x,/,1x,105('*')/,1x,'*',39x,'punchfile items requested',
     &     39x,'*'/1x,105('*'))
 1015 format(i4)
 1020 format(1x,'* wavefunction information from dumpfile section(s) '
     &,10(1x,a4),2x,'*')
 1030 format(1x,'* comprising :',90x,'*')
 1035 format(1x,105('*'))
 2001 format(1x,'* coordinates (single point or last point)',62x,'*')
 2002 format(1x,'* coordinates at each optimisation step',65x,'*')
 2003 format(1x,'* starting coordinates',82x,'*')
 2004 format(1x,'* atom connectivity',85x,'*')
 2005 format(1x,'*       molecular orbital occupations',67x,'*')
 2006 format(1x,'*       eigenvectors',84x,'*')
 2007 format(1x,'* run type',94x,'*')
 2008 format(1x,'* gvb pair data',89x,'*')
 2009 format(1x,'* force constant matrix',81x,'*')
 2010 format(1x,'* vibrational frequencies',79x,'*')
 2011 format(1x,'* basis set',93x,'*')
 2012 format(1x,'*       orbital energies',80x,'*')
 2013 format(1x,'*       total scf energies',78x,'*')
 2014 format(1x,'* job title',93x,'*')
 2015 format(1x,'* overlap matrix',88x,'*')
 2016 format(1x,'* grid data from dumpfile section(s)',10(1x,a4),
     & 18x,'*')
 2017 format(1x,'* mulliken analysis',85x,'*')
 2018 format(1x,'* lowdin analysis',87x,'*')
 2019 format(1x,'* spin densities',88x,'*')
 2020 format(1x,'* scf type',94x,'*')
 2021 format(1x,'* normal coordinates for vibrational modes',62x,'*')
20221 format(1x,'* two electon integrals from block'
     & ,i5,' for',i7,' blocks',47x,'*')
20222 format(1x,'* two electon integrals from block'
     & ,i5,' to end of file',50x,'*')
 2023 format(1x,'* gradients',93x,'*')
 2024 format(1x,'* transformation matrix',81x,'*')
 2025 format(1x,'* potential derived charges',77x,'*')
 2026 format(1x,'* grid symmetry array',83x,'*')
 2027 format(1x,'* cartesian hessian matrix',78x,'*')
 2028 format(1x,'* distributed multipole analysis',72x,'*')
 2029 format(1x,'* density matrix',88x,'*')
 2030 format(1x,'* total energy',90x,'*')
 2031 format(1x,'* internal coordinate hessian matrix',68x,'*')
 2032 format(1x,'* dipole moment',89x,'*')
      end
_IF(xml)
c Write out table indicating what XML will be output (ala blktab)
      subroutine xml_table()
      implicit none
INCLUDE(common/iofile)
INCLUDE(common/blocks)
INCLUDE(common/xmlout)
      integer i
      logical opg_root,ochk
      character*80 xmltitle
c     
c     Only root should worry about outputting xml
      if (.not.opg_root())return

c     Check if we are punching anything
      if(.not.oxml)return

c     Write out head of xml table
      write(iwr,10)

 10   format(1x,/,1x,105('*')/,1x,'*',39x,'xml output items requested',
     &     38x,'*'/1x,105('*'))

c     Now each attribute that is supported
      if(oxml_control(PUN_COORD)) write(iwr,101)
 101  format(1x,'* coordinates (single point or last point)',62x,'*')
      if(oxml_control(PUN_OPT_COORD)) write(iwr,102)
 102  format(1x,'* coordinates at each optimisation step',65x,'*')
      if(oxml_control(PUN_START_COORD)) write(iwr,103)
 103  format(1x,'* starting coordinates',82x,'*')
      if(oxml_control(PUN_TOT_ENER)) write(iwr,104)
 104  format(1x,'* total energy',90x,'*')
      if(oxml_control(PUN_SCF_ENER)) write(iwr,113)
 113  format(1x,'* scf properties and parameters at each cycle',59x,'*')
      if(oxml_control(PUN_METADATA)) write(iwr,135)
 135  format(1x,'* Initial Metadata',86x,'*')
      if(oxml_control(PUN_INPUT_PARAM)) write(iwr,136)
 136  format(1x,'* Input parameters',86x,'*')

c     Write out end of xml table
      write(iwr,11)
 11   format(1x,105('*'))

      end
_ENDIF(xml)
c
c  Punchfile sections recovered from dumpfile at the end of 
c  the job phase
c
c   ostop  - true when the program termination was requested
c            output is limited here to structure, basis etc.
c
      subroutine blk(core)
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/runlab)
INCLUDE(common/atmol3)
INCLUDE(common/blocks)
_IF(xml)
INCLUDE(common/xmlout)
_ENDIF(xml)
INCLUDE(common/infoa)
      dimension core(*), dum(2)
c
c---- write out formatted file for graphics and post-analysis
c   (some blocks are also written out during the calculation)
c
      opun = .false.
      do i = 1,LENPUN
         opun = opun .or. oblock(i)
      enddo
      if(.not.opun) then
_IF(xml)
c     Only return if we're not writing any xml out
      if (.not. oxml ) return
_ELSE
         return
_ENDIF(xml)
      endif
c
c     Only write this out if we really are writing the punchfile
      if (opun) write(iwr,1010)
c
c  NB coords may get punched at start for 
c  single-point runtypes
c
      nav=lenwrd()
      if(oblock(PUN_ATOM_CONN))then
         i1 = igmem_alloc(1+(nat*nat-1)/nav)
         call blkcoo(core(i1))
         call gmem_free(i1)
      else
         call blkcoo(dum)
      endif

c 2 triangles
      l2 = num*(num+1)/2
      i1 = igmem_alloc(2*l2)
      call blkbas(core(i1))
      call gmem_free(i1)

      do 20 i=1,nblsec
         call blkvec(i,core)
 20   continue

      if(oblock(PUN_GVBPAIR))then
         if(zscftp.eq.'gvb')then
            do 30 i=1,nblsec
               if(iblsec(i).eq.moutb)call blkgvb(i)
 30         continue
         else
            write(iwr,1000)
         endif
      endif

      call blkener

      if(oblock(PUN_GRID_DATA))then

         do 25 i=1,nblgri
            call blkhdf(i,core)
 25      continue

      endif

      call blktwo

      call blkfcm(core)

      call blkden(zscftp,idaf,core)

      write(iwr,1040)
      return
c
 1000 format(/1x,'WARNING : no gvb data written to punchfile',
     &       ' *** this is not a GVB calculation ***')
 1010 format(1x,104('=')//55x,'formatted punchfile'//1x,104('='))
 1035 format(1x,105('*'))
 1040 format(1x,104('='))

      end
c
c  inital punch call - 
c
      subroutine blk11(core)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/symtry)
INCLUDE(common/machin)
INCLUDE(common/runlab)
INCLUDE(common/iofile)
      common/junk/ct(3,maxat)
INCLUDE(common/blocks)
_IF(xml)
INCLUDE(common/xmlout)
_ENDIF(xml)
      dimension core(*)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
c'
      REAL dum(2)
c for blkrun
      character*25 runt
      character*51 scftype
      character*80 title

      opun = .false.
      do i = 1,LENPUN
         opun = opun .or. oblock(i)
      enddo
      if(.not.opun) then
_IF(xml)
c     Only return if we're not writing any xml out
      if (.not. oxml ) return
_ELSE
         return
_ENDIF(xml)
      endif
c
c
c --- write data concerning run type etc
c
      call blkrun(.true.,runt,scftype,title)
c
c  for run types that do not change the coordinates
c  they are written out here. This makes sure they
c  precede gradients, energies etc.
c
      if(  zruntp .ne. 'optimize' .and.
     &     zruntp .ne. 'irc'      .and.
     &     zruntp .ne. 'jorgense' .and.
     &     zruntp .ne. 'optxyz'   .and.
     &     zruntp .ne. 'saddle') then

         nav=lenwrd()

         if(oblock(PUN_ATOM_CONN))then
            i1 = igmem_alloc(1+(nat*nat-1)/nav)
            call blkcoo(core(i1))
            call gmem_free(i1)
         else
            call blkcoo(dum)
         endif
         oblock(PUN_COORD)      = .false.
         oblock(PUN_ATOM_CONN) = .false.
_IF(xml)
         oxml_control(PUN_COORD)      = .false.
         oxml_control(PUN_ATOM_CONN) = .false.
_ENDIF(xml)
      endif
c
c take starting coordinates off dumpfile
c
_IF(xml)
      if(oblock(PUN_START_COORD).or.oxml_control(PUN_START_COORD))then
_ELSE
      if(oblock(PUN_START_COORD))then
_ENDIF(xml)
         call rdrec1(idum,idum,idum,idum,ct,ct,dum,dum,dum,ct,ct)
      endif
_IF(xml)
      if(oxml_control(PUN_START_COORD))then
         call xmlWriteCoords(ztitle,zaname,symz,ct,nat,0)
      endif
_ENDIF(xml)
      if(oblock(PUN_START_COORD))then
         if(opg_root())then
            if(iblfmt(3).eq.0)then
               write(nfblck,1010)nat
               do 100 i=1,nat
                  write(nfblck,1020)zaname(i),ct(1,i),ct(2,i),ct(3,i)
 100           continue
            else 
               write(nfblck,1010)nat,xslash
               do 101 i = 1,nat
                  write(nfblck,1021)zaname(i),ct(1,i),ct(2,i),ct(3,i)
 101           continue
            endif
         endif
      endif

      return
 1010 format('block = initial_coordinates records = ',i5,' unit = au',
     &     1x,a1,/,1x,'f_format = "(2x,a8,3(3x,f22.14))"')
 1020 format(2x,a8,3(3x,f12.7))
 1021 format(2x,a8,3(3x,f22.14))

      end

      subroutine blkcoo(icon)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
c     Writes out the geometry to the punchfile.
c     This includes:
c     - atomic coordinates
c     - point charge coordinates
c     - connectivity information
c
INCLUDE(common/sizes)
INCLUDE(common/symtry)
INCLUDE(common/machin)
INCLUDE(common/iofile)
INCLUDE(common/blocks)
_IF(xml)
INCLUDE(common/xmlout)
_ENDIF(xml)
INCLUDE(common/sector)
INCLUDE(common/mapper)
INCLUDE(common/coval)
INCLUDE(common/runlab)
INCLUDE(common/infoa)
INCLUDE(common/blur)
c
INCLUDE(common/drfopt) 
_IF(drf)
INCLUDE(../drf/comdrf/sizesrf)
INCLUDE(../drf/comdrf/drfpar) 
INCLUDE(../drf/comdrf/extinf) 
INCLUDE(../drf/comdrf/rad) 
c
_ENDIF
      common/junk/ct(3,maxat)
c
      dimension icon(2,*)
c
      data scale/1.1d0/
      data toler/0.5d0/

      logical opun,fmt_high
      integer fmtspec(2)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
c'
c take coordinates off dumpfile and punch if required
c
c     Check if we need to do owt
      opun=.false.
      if(oblock(PUN_COORD).or.oblock(PUN_ATOM_CONN))opun=.true.
      if (.not.opun) then
_IF(xml)
         if (.not.oxml_control(PUN_COORD)) return
_ELSE
         return      
_ENDIF(xml)
      endif

c     Read the coordinates off the dumpfile - I think all nodes must participate in this call
      call rdrec1(idum,idum,idum,idum,ct,ct,dum,dum,dum,ct,ct)

c     Non-root nodes can now return
      if (.not.opg_root()) return

_IF(xml)
c     Write out the coodinates to the xml file - currently ignore any bq/drf stuff
      call xmlWriteCoords(ztitle,zaname,symz,ct,nat,0)
_ENDIF

      if(oblock(PUN_COORD))then

c     Determine format
         if(iblfmt(1).eq.0)then
            fmt_high=.false.
         else
            fmt_high=.true.
         endif
c
c - to keep bq's separate
         nbq = 0
         do i=1,nat
            if(zaname(i)(1:2).eq."bq")nbq = nbq + 1
         enddo
c
         write(nfblck,1000)
c         write(nfblck,1010)nat-nbq
         if (fmt_high) then
            write(nfblck,1011)nat-nbq,xslash
         else
            write(nfblck,1010)nat-nbq,xslash
         endif

         do i=1,nat
            if(zaname(i)(1:2).ne."bq") then
               if(fmt_high) then
                  write(nfblck,1021)zaname(i),
     &                 ct(1,i),ct(2,i),ct(3,i)
               else
                  write(nfblck,1020)zaname(i),
     &                 ct(1,i),ct(2,i),ct(3,i)
               endif
            endif
         enddo
         if(nbq.ne.0)then 
            write(nfblck,1100)nbq
            do i=1,nat
               if(zaname(i)(1:2).eq."bq")then
c
c If the centre is blurred, use the blurred weight
c
                  chg = czan(i)
                  if(oblur .and. blexpo(i) .gt. 0.0d0)then
                     chg = blwght(i)
                  endif
                  if (fmt_high) then
                    write(nfblck,1111)zaname(i),ct(1,i),ct(2,i),
     &                    ct(3,i), chg
                  else
                    write(nfblck,1110)zaname(i),ct(1,i),ct(2,i),
     &                    ct(3,i), chg
                  endif

               endif
_IF(drf)
            enddo
         endif
         if (field .ne. " ") then
            nxt  = 0
            do i = 1, nxtpts
               if (nxcent(i)(1:2) .ne. "gr")nxt = nxt + 1
            enddo
            write(nfblck,1200)nxt,xslash
            do i = 1, nxtpts
               if (nxcent(i)(1:2) .ne. "gr") then
                  write(nfblck,1211) 
     &            nxcent(i), chrg(i), xpts(1,i), xpts(2,i), xpts(3,i),
     &            polars(i), radext(i)
C     &            atpol(i), radext(i)
Cjmht  not sure which of the above correct
               endif
            enddo
         endif
_ELSE
            enddo
         endif
_ENDIF
         call flushn(nfblck)
      endif
c     end of PUN_COORD block

c
c connectivity, excluding point charges
c
      if(oblock(PUN_ATOM_CONN))then
         ncon=0
         ix = 0
         do 130 i=1,nat
            if(zaname(i)(1:2).ne."bq")then
               ix = ix + 1
               izi=nint(czan(i))
               if(izi.le.0)goto 130
               jx = ix
               do 120 j=i+1,nat
                  if(zaname(j)(1:2).ne."bq")then
                     jx = jx + 1
                     izj=nint(czan(j))
                     if(izj.le.0)goto 120

                     rdif=scale*(cov(izi)+cov(izj))
     &                    - dsqrt((ct(1,j)-ct(1,i))**2
     &                    + (ct(2,j)-ct(2,i))**2 
     &                    + (ct(3,j)-ct(3,i))**2) + toler

                     if(rdif.gt.0.0d0)then
                        ncon=ncon+1
                        icon(1,ncon)=ix
                        icon(2,ncon)=jx
                     endif
                  endif
 120           continue
            endif
 130     continue
         if(ncon.gt.0)then
            write(nfblck,1030)ncon
            write(nfblck,1040)(icon(1,j),icon(2,j),j=1,ncon)
         else
            write(iwr,1050)
         endif
         call flushn(nfblck)
      endif
      return
c
 1000 format('block = fragment records = 0')
 1010 format('block = coordinates records = ',i5,' unit = au',
     & 1x,a1,/,1x,'f_format = "(2x,a8,3(3x,f12.7))"')
 1011 format('block = coordinates records = ',i5,' unit = au',
     & 1x,a1,/,1x,'f_format = "(2x,a8,3(3x,f22.14))"')
 1020 format(2x,a8,3(3x,f12.7))
 1021 format(2x,a8,3(3x,f22.14))
 1030 format('block = connectivity records = ',i4)
 1040 format(2i5)
 1050 format(1x,/' connectivity block not written - no short contacts')
 1100 format('block = point_charges records = ',i5,' unit = au',
     &     1x,a1,/,1x,'f_format = "(4(3x,f22.14))"')
c 1110 format(4(3x,f12.7))
c 1111 format(4(3x,f22.14))
 1110 format(2x,a8,3(3x,f12.7),f12.5)
 1111 format(2x,a8,3(3x,f20.12),f16.6)
_IF(drf)
 1200 format('block = external records = ',i5,' unit = au',
     &     1x,a1,/,1x,'f_format = "(a16,f12.6,3(f20.12),2(f16.8))"')
 1211 format(a16,f12.6,3(f20.12),2(f16.8))
_ENDIF
c
      end
c
      subroutine blkbas(wrk)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
cXML
c
c     Writes out the basis set to the punchfile.
c     This includes:
c     - the basis functions
c     - the overlap matrix
c
cXML
c
INCLUDE(common/sizes)
c
c  use /junk/, /junkc/ to hold information off dumpfile
c  to avoid over-writing infoa, basis commons in case of
c  further calculation steps
c
      common/junk/ex(mxprim),cs(mxprim),cp(mxprim),cd(mxprim),
     +     cf(mxprim),cg(mxprim),czan(maxat),c(3,maxat),
     +     kstart(mxshel),katom(mxshel),ktype(mxshel),kng(mxshel),
     +     kloc(mxshel),kmin(mxshel),kmax(mxshel),
     +     nshell,non,numorb,ndum,
     +     ns(maxat),ks(maxat),intyp(mxshel)
      common /junkc/zcom(19),ztitle(10),zaname(maxat)
c
INCLUDE(common/restri)
INCLUDE(common/symtry)
INCLUDE(common/machin)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/blocks)
INCLUDE(common/sector)
INCLUDE(common/mapper)
INCLUDE(common/coval)
      common/blkcore/corev(512),charge(10)
c
      dimension wrk(*)
      dimension jshell(5),o1e(6)
c
c     dimension ylabel(5)
c     data scale/1.1d0/
c
      data ntype/5/
c     data ylabel/'s','p','d','f','sp'/
      data jshell/ 1 , 3 , 6 ,10 ,  4 /
c
      mtype = 0
      call secget(isect(491),mtype,iblk00)
      iunit=numdu
      m1420=5*mxprim+maxat
      m110 =10+maxat
      call rdedx(ex,mxprim,iblk00,iunit)
      call reads(cs,m1420,iunit)
      call rdchrs(ztitle,m110,iunit)
      nav = lenwrd()
      call readis(kstart,mach(2)*nav,iunit)
c
      if(numorb.gt.maxorb.or.numorb.lt.0.or.
     +   non.gt.maxat.or.non.lt.1.or.
     +   nshell.gt.mxshel.or.nshell.lt.0)then
         write(6,*)non,nshell
         call caserr('problem on dumpfile')
      endif

c
c -- basis functions
c
c      if(oblock(11) .and. opg_root())then
      if(oblock(PUN_BASIS) .and. opg_root())then
c
c store shell structure
         kss=0
         do 10070 loop=1,non
            nss = 0
            do 10080 i=1,nshell
               if(katom(i).eq.loop) then
                  nss=nss+1
               endif
10080       continue
            ns(loop)=nss
            ks(loop)=kss+1
            kss=kss+nss
10070    continue
         
         do 20 loop=1,nshell
            ii=kmax(loop)-kmin(loop)+1
            do 10 i=1,ntype
               if(ii.eq.jshell(i)) then
                  intyp(loop) = i
               endif
 10         continue
 20     continue
c
c indx1 - atom type
c indx2 - shell type on atom
c indx3 - primitive in shell
c
c count entries required
c
         nrec=0
         do 50 iat = 1,non
            if(iat.ge.2)then
               do 30 j = 1,iat-1
                  if(zaname(j).eq.zaname(iat))goto 50
 30            continue
            endif
            ns2=ns(iat)
            if(ns2.eq.0)go to 50
            ns1 = ks(iat)
            ns2 = ns1+ns2-1
            do 40 ish = ns1,ns2
               nrec=nrec+kng(ish)
               if(intyp(ish).eq.5)nrec=nrec+kng(ish)
 40         continue
 50      continue
c
c write the data
c
         write(nfblck,1060)nrec
         indx1=1
         do 105 iat = 1,non
            if(iat.ge.2)then
               do 60 j = 1,iat-1
                  if(zaname(j).eq.zaname(iat))goto 105
 60            continue
            endif
            ns2=ns(iat)
            if(ns2.eq.0)go to 105
            ns1 = ks(iat)
            ns2 = ns1+ns2-1
            indx2=1
            do 90 ish = ns1,ns2
               i1 = kstart(ish)
               i2 = i1+kng(ish)-1
               ityp = intyp(ish)
               indx3=1
               do 70 ig = i1,i2
                  if(ityp.eq.1.or.ityp.eq.5)then
                     write(nfblck,1070)
     &               zaname(iat),indx1,' s',indx2,indx3,ex(ig),cs(ig)
                  else if(ityp.eq.2)then
                     write(nfblck,1070)
     &               zaname(iat),indx1,' p',indx2,indx3,ex(ig),cp(ig)
                  else if(ityp.eq.3)then
                     write(nfblck,1070)
     &               zaname(iat),indx1,' d',indx2,indx3,ex(ig),cd(ig)
                  else if(ityp.eq.4)then
                     write(nfblck,1070)
     &               zaname(iat),indx1,' f',indx2,indx3,ex(ig),cf(ig)
                  endif
                  indx3 = indx3+1
 70            continue
c
               if(ityp.eq.5)then
                  indx2=indx2+1
                  indx3=1
                  do 80 ig = i1,i2
                     write(nfblck,1070)
     &               zaname(iat),indx1,' p',indx2,indx3,ex(ig),cp(ig)
                     indx3=indx3+1
 80               continue
               endif
               indx2=indx2+1
 90         continue
            indx1=indx1+1
 105     continue
         call flushn(nfblck)
      endif
c
c  overlap matrix
c
c      if(oblock(15))then
      if(oblock(PUN_OVLP_MAT))then
         nc = 6
         nrec=numorb*(1+(numorb-1)/nc)
         o1e(1) = .true.
         do loop =2,6
          o1e(loop) = .false.
         enddo
         ne = 1+numorb*(numorb+1)/2
         call getmat(wrk,wrk(ne),wrk(ne),wrk(ne),wrk(ne),wrk(ne),
     &        charge,numorb,o1e,ionsec)
         if(opg_root())then
            write(nfblck,1080)nrec,numorb
            do 115 i = 1,numorb
 115        write(nfblck,1090)(wrk(iky(max(i,j))+min(i,j)),
     +              j=1,numorb)
            call flushn(nfblck)
         endif
      endif
      return
c
 1060 format('block = basis records =',i4)
 1070 format(a8,1x,i3,1x,a2,1x,i3,1x,i3,1x,2f15.6)
 1080 format('block = overlap records = ',i5,' elements = ',i3)
 1090 format(6f11.6)
      end


      subroutine blkfcm(rx)
c
c - read force constants from dumpfile and write to punchfile
c     
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character*8 (z), character*1 (x), character*4 (y)
INCLUDE(common/sizes)
INCLUDE(common/molsym)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
      common/miscop/qst(16,maxvar),qstt(31),fx(3*maxat)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/restri)
INCLUDE(common/cntl1)
      common/restrl/ociopt(2),omp2
      logical exist1,exist2
      logical found
      dimension rx(*)
INCLUDE(common/blocks)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
c
c      if(.not.oblock(27))return
      if(.not.oblock(PUN_HESSIAN))return
c ...
c     ----- evaluate some constants ----
c ...
      nvarx = nat*3
      nvarx2 = nvarx*nvarx
c
c     ----- grow memory for c ...fcmt -----
c
      i20 = igmem_alloc(nvarx2)
c
c     ----- restore the cartesian 2nd derivatives which is in
c           x(i20) -----
c
      call rdfcm(rx(i20),'blkfcm')
      if (iblfcm.eq.0) then
c
c     have failed to find anything
c
         write(iwr,*)'*** Warning: Force constants not found :',
     &        'punch request ignored ***'
         goto 50
      end if

      if(opg_root())then
         if(iblfmt(27).eq.0)then
            write(nfblck,1000)nvarx2
            do 20 i = 1,nvarx
               do 10 j = 1,nvarx
                  write(nfblck,1010)rx(i20+(i-1)*nvarx + (j-1))
 10            continue
 20         continue
         else
            write(nfblck,1000)nvarx2,xslash
            do 40 i = 1,nvarx
               do 30 j = 1,nvarx
                  write(nfblck,1011)rx(i20+(i-1)*nvarx + (j-1))
 30            continue
 40         continue
         endif
      endif
c ...
c     ----- return the fast memory -----
c ...
 50   call gmem_free(i20)
c
      return
 6010 format (/1x,'mp2 force constants restored from dumpfile')
 6020 format (/1x,'no mp2 force constants present')
 6030 format (/1x,'scf force constants restored from dumpfile')
 6050 format (/1x,'no scf force constants present')
 1000 format('block = cartesian_hessian records = ',i6,' unit = au',
     & 1x,a1,/,1x,'f_format = "(6e24.18)"')
 1010 format(f15.7)
 1011 format(e24.18)
      end
      subroutine blkhdf(index,q)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/machin)
INCLUDE(common/sector)
INCLUDE(common/blocks)
      dimension q(*)
      integer getind, itmp(3)
c
c grid definition parameters
c
      common/dfgrid/geom(12,mxgrid),gdata(5,mxgrid),igtype(mxgrid),
     &             igsect(mxgrid),nptot(mxgrid),npt(3,mxgrid),
     &             igdata(5,mxgrid),igstat(mxgrid),ngdata(mxgrid),
     &             ngrid
c
c data calculation parameters
c
      common/dfcalc/cdata(5,mxcalc),ictype(mxcalc),icsect(mxcalc),
     &            icgrid(mxcalc),icgsec(mxcalc),ndata(mxcalc),
     &            icstat(mxcalc),icdata(5,mxcalc),ncalc
c
c plot definition parameters
c
      common/dfplot/pdata(7,mxplot),iptype(mxplot),ipcalc(mxplot),
     &            ipcsec(mxplot),ipcont(mxplot),ncont(mxplot),
     &            ipdata(3,mxplot),nplot
c
c requests for restore of data from foreign dumpfiles
c
      common/dfrest/irestu(mxrest),irestb(mxrest),irests(mxrest),
     &              iresec(mxrest),nrest
c
c labels and titles
c
      common/cplot/zgridt(10,mxgrid),zgrid(mxgrid),
     &             zcalct(10,mxcalc),zcalc(mxcalc),
     &             zplott(10,mxplot),zplot(mxplot)
INCLUDE(common/symtry)
INCLUDE(common/transf)
      dimension tempi(3), tempi2(3), tempj(3), cnew(3)
      dimension tempd(6)
      equivalence (cnew(1),pnew)
      data itgrid,itcalc/50,51/
      data toler / 1.0d-6 /

_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
c
      i0 = igmem_alloc_all(nmax)
c
c ---- read grid of data off the dumpfile, and write
c      the data, together with a title, plane definition
c      and data description to the formatted file for graphics.
c
      isec=iblgri(index)
c
c  --- first determine if the user asked for grid or data
c
      call qsector(isec,ipos,iclass,ilen,'get')
      if(ipos.lt.1)then
         write(iwr,100) isec
 100     format(/1x,'problem with section ',i5,//)
         call caserr('attempt retrieve undefined dumpfile section')
      else if(iclass.eq.itgrid)then
         ogrid=.true.
      else if(iclass.eq.itcalc)then
         ogrid=.false.
      else
         write(iwr,101) isec, iclass
 101     format(/1x,'section ',i5,' is type ',i5,//)
         call caserr('dumpfile section is of wrong type')
      endif
c
      if(ogrid)then
         ier = 0
         i1 = i0
         call rgrsec(isec,igrid,idaf,ibl3d,q(i1),.true.,ier)
         ng = ngdata(igrid)
         it = igtype(igrid)
      else
         ier = 0
         call rcasec(isec,icalc,idaf,ibl3d,q(i0),.true.,ier)
c
         igrid = icgrid(icalc)
         i1 = i0+ndata(icalc)
c
         if(igrid.eq.0)then
            ng = 0
         else
            ng = ngdata(igrid)
            it = igtype(igrid)
         endif
c
         if(ng.ne.0)then
            if(icdata(5,icalc).eq.1)then
               write(iwr,*)'grid punch supressed - writing data only'
               it = -1
            else if(igsect(igrid).eq.0)then
               write(iwr,*)'no grid on dumpfile - writing data only'
               it = -1
            else
               ier = 0
               call rgrsec(igsect(igrid),igrid,idaf,ibl3d,
     &              q(i1),.true.,ier)
               ng = ngdata(igrid)
               it = igtype(igrid)
            endif
         endif
c        i2 = i1 + ng
      endif
c
c ---- screen for large values (outside format range)
c
      if (iblfmt(16).eq.1) then
         vmax = 9999999.99999999999999d0
         vmin = -999999.99999999999999d0
         oclip = .true.
      else if (iblfmt(16).eq.2) then
         oclip = .false.
      else
         oclip = .true.
         vmax = 9999.999999d0
         vmin = -999.999999d0
      endif
      if(oclip)then
         if(it.ne.-1 .and. it.ne.1 .and. it .ne. 2)then
c
c clip irregular grid coordinates
c
            do 11 i = 1,nptot(igrid)
               do 10 j = 1,3 
                  q(i1+3*(i-1)+(j-1)) = 
     &                 dmin1( q(i1+3*(i-1)+(j-1)),vmax)
                  q(i1+3*(i-1)+(j-1)) = 
     &                 dmax1( q(i1+3*(i-1)+(j-1)),vmin)
 10            continue
 11         continue
         endif
         if(.not.ogrid)then
            do 21 i = 1,nptot(igrid)
               q(i0+i-1) = dmin1( q(i0+i-1),vmax)
               q(i0+i-1) = dmax1( q(i0+i-1),vmin)
 21         continue
         endif
      endif
      if(opg_root())then

c
c ---- grid title
c
         write(nfblck,999)index
         if(ogrid)then
            write(nfblck,1000)index,(zgridt(i,igrid),i=1,10)
         else
            write(nfblck,1000)index,(zcalct(i,icalc),i=1,10)
         endif
         if(it.eq.1.or.it.eq.2)then
            sidex = dist(geom(1,igrid),geom(4,igrid))
            sidey = dist(geom(1,igrid),geom(7,igrid))
         endif
         if(it.eq.2)sidez = dist(geom(1,igrid),geom(10,igrid))
c
         if(it.eq.-1)then
         else if(it.eq.1)then
c 2D regular grid
            write(nfblck,1010)2,index
            write(nfblck,1020)npt(1,igrid),0.0d0,sidex,'xaxis'
            write(nfblck,1020)npt(2,igrid),0.0d0,sidey,'yaxis'
c
c ---- plane corners (ll, lr ul)
c
            write(nfblck,1030)2,index
            write(nfblck,1040)(geom(i,igrid),i=1,6)
            write(nfblck,1040)(geom(i,igrid),i=1,3),(geom(i,igrid),
     &           i=7,9)
         else if(it.eq.2)then
c 3D regular grid
            write(nfblck,1010)3,index
            write(nfblck,1020)npt(1,igrid),0.0d0,sidex,'xaxis'
            write(nfblck,1020)npt(2,igrid),0.0d0,sidey,'yaxis'
            write(nfblck,1020)npt(3,igrid),0.0d0,sidez,'zaxis'
            if(iblfmt(16).eq.0)then
               write(nfblck,1030)3,index
               write(nfblck,1040)(geom(i,igrid),i=1,6)
               write(nfblck,1040)(geom(i,igrid),i=1,3),(geom(i,igrid),
     &              i=7,9)
               write(nfblck,1040)(geom(i,igrid),i=1,3),(geom(i,igrid),
     &              i=10,12)
            else
               write(nfblck,1030)3,index,xslash
               write(nfblck,2061)(geom(i,igrid),i=1,6)
               write(nfblck,2061)(geom(i,igrid),i=1,3),(geom(i,igrid),
     &              i=7,9)
               write(nfblck,2061)(geom(i,igrid),i=1,3),(geom(i,igrid),
     &              i=10,12)
            endif
         else if(it.eq.3.or.it.eq.4.or.it.eq.6.or.
     &           it.eq.7.or.it.eq.8)then
c irregular grid
            if(iblfmt(16).eq.0)then
               write(nfblck,1060)nptot(igrid),index
            else if(iblfmt(16).eq.1)then
               write(nfblck,1060)nptot(igrid),index,xslash
            else 
               write(nfblck,1061)nptot(igrid),index,xslash
            endif
            do 30 i = 1,nptot(igrid)
               if(iblfmt(16).eq.0)then
                  write(nfblck,2060)(q(i1+3*(i-1)+(j-1)),j=1,3)
               else if(iblfmt(16).eq.1)then
                  write(nfblck,2061)(q(i1+3*(i-1)+(j-1)),j=1,3)
               else
                  write(nfblck,2062)(q(i1+3*(i-1)+(j-1)),j=1,3)
               endif
 30         continue
         else if(it.eq.5)then
c irregular grid which can be indexed for meshing
            if(iblfmt(16).eq.0)then
               write(nfblck,1060)nptot(igrid),index
            else if(iblfmt(16).eq.1)then
               write(nfblck,1060)nptot(igrid),index,xslash
            else 
               write(nfblck,1061)nptot(igrid),index,xslash
            endif
            do 35 i = 1,nptot(igrid)
               if(iblfmt(16).eq.0)then
                  write(nfblck,2060)(q(i1+3*(i-1)+(j-1)),j=1,3)
               else if(iblfmt(16).eq.1)then
                  write(nfblck,2061)(q(i1+3*(i-1)+(j-1)),j=1,3)
               else
                  write(nfblck,2062)(q(i1+3*(i-1)+(j-1)),j=1,3)
               endif
 35         continue
            write(nfblck,1070)nptot(igrid),index
            do 36 i = 1,nptot(igrid)
               do 37 j = 1,3
                  itmp(j) = getind(q(i1+3*(i-1)),
     &                 geom(1,igrid),geom(1+j*3,igrid),npt(j,igrid))
 37            continue
               write(nfblck,2070)(itmp(j),j=1,3)
 36         continue
         else
            write(iwr,*)'cant write grid of type',it
         endif
         if(oblock(26))then
c
c   grid symmetry data
c
            call setgrd(igrid,iwr)
            call ptgrp(0)
            write(nfblck,1100)nptot(igrid),index
            do 50 i = 1,nptot(igrid)
               call getpt(i,tempi(1),tempi(2),tempi(3),q(i1),1,idum)
               call lframe(tempi(1),tempi(2),tempi(3),
     &              tempi2(1),tempi2(2),tempi2(3))
c     write(6,95)i,tempi,tempi2
c     95         format(1x,i3,6f10.5)
               do 45 j = 1, i - 1
                  call getpt(j,tempj(1),tempj(2),tempj(3),q(i1),1,idum)
                  call lframe(tempj(1),tempj(2),tempj(3),
     &                 psmal, qsmal, rsmal)
                  do 43 it = 1 , nt
                     nn = 9*(it - 1)
                     call trans1(nn)
c     write(6,96)j,it,cnew
c     96               format(1x,2i5,3f10.5)
                     tester = dist(tempi2,cnew)
                     if(tester.lt.toler)then
                        write(nfblck,1110)j
                        goto 46
                     endif
 43               continue
 45            continue
               write(nfblck,1110)i
 46            continue
 50         continue
         endif
c
c data block
c
         if(ogrid)then
            write(nfblck,1050)0,index,0
         else
c
c   deduce whether scalar or vector data
c
            nel = ndata(icalc) / nptot(igrid)
            if(iblfmt(16).eq.0)then
               write(nfblck,1050)nptot(igrid),index,nel
            else if(iblfmt(16).eq.1)then
               write(nfblck,1050)nptot(igrid),index,nel,xslash
            else if(iblfmt(16).eq.2)then
               write(nfblck,1051)nptot(igrid),index,nel,xslash
            endif
            do 40 i = 1,nptot(igrid)
               if(iblfmt(16).eq.0)then
                  write(nfblck,2060)(q(i0+nel*(i-1)+(j-1)),j=1,nel)
               else if(iblfmt(16).eq.1)then
                  write(nfblck,2061)(q(i0+nel*(i-1)+(j-1)),j=1,nel)
               else
                  do j = 1,nel
                     tempd(j) = q(i0+nel*(i-1)+(j-1))
c avoid overflowing the 2 digit exponent
                     if(abs(tempd(j)).lt.1.0d-99)tempd(j) = 0.0
                     if(abs(tempd(j)).gt.1.0d+99)tempd(j) = 1.0d+99
                  enddo
                  write(nfblck,2062)(tempd(j),j=1,nel)
               endif
 40         continue
         endif
      endif

      call gmem_free(i0)

      return
c
 999  format('block = data records = 0 index = ',i3)
 1000 format('block = grid_title records = 1 index = ',i3,/,10a8)
 1010 format('block = grid_axes records = ',i3,' index = ',i3)
 1020 format(1x,i3,2(f10.5,1x),' 0  au ',a5)
 1030 format('block = grid_mapping records = ',i3,' index = ',i3,
     & 1x,a1,/,1x,'f_format = "(6(f21.13,1x))"')
 1040 format(6(f9.5,1x))
 1050 format('block = grid_data records = ',i8,' index = ',i3,
     &     ' elements = ',i3,
     & 1x,a1,/,1x,'f_format = "(6(f21.13,1x)"')
 1051 format('block = grid_data records = ',i8,' index = ',i3,
     &     ' elements = ',i3,
     & 1x,a1,/,1x,'f_format = "(6(1pe16.8))"')
 1060 format('block = grid_points elements = 3 records = ',i8,
     &       ' index = ',i3,
     & 1x,a1,/,1x,'f_format = "(6f22.14)"')
 1061 format('block = grid_points elements = 3 records = ',i8,
     &       ' index = ',i3,
     & 1x,a1,/,1x,'f_format = "(6(1pe16.8))"')
 1070 format('block = grid_indices elements = 3 records = ',i8,
     &     ' index = ',i3)
 1100 format('block = grid_symmetry records = ',i8,' index = ',i3)
 1110 format(1x,i8)
 2060 format(6(f10.5,1x))
 2061 format(6(f21.13,1x))
 2062 format(6(1pe16.8))
 2070 format(3i5)
      end
      function dist(a,b)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension a(3), b(3)
      dist = dsqrt((a(1)-b(1))*(a(1)-b(1)) +
     &     (a(2)-b(2))*(a(2)-b(2)) +
     &     (a(3)-b(3))*(a(3)-b(3)))
      return
      end
c
      integer function getind(p,s,e,n)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension p(3), s(3), e(3), v(3), t(3)
c - to back calculate the cell index for orthonormal grids only!
      do 10 i = 1,3
         v(i) = p(i) - s(i)
         t(i) = e(i) - s(i)
 10   continue
      an = n-1
      d2 = dist(e,s)
      d2 = d2*d2
      a = an*(v(1)*t(1) + v(2)*t(2) + v(3)*t(3))/d2
      getind = 1 + a
      return
      end
c
      subroutine blkgra(n,g)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/blocks)
INCLUDE(common/runlab)
      dimension g(3,*)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
      if(.not. opg_root())return

c - to keep bq's separate
      nbq = 0
      do i=1,n
         if(zaname(i)(1:2).eq."bq")nbq = nbq + 1
      enddo
      if(oblock(23))then
         if(iblfmt(23).eq.0)then
            write(nfblck,1000)n-nbq
            do 10 i = 1,n
               if(zaname(i)(1:2).ne."bq")
     &              write(nfblck,1010)g(1,i),g(2,i),g(3,i)
 10         continue
            if(nbq.ne.0)then
               write(nfblck,1020)nbq
               do 11 i = 1,n
                  if(zaname(i)(1:2).eq."bq")
     &                 write(nfblck,1010)g(1,i),g(2,i),g(3,i)
 11            continue
            endif
         else
            write(nfblck,1000)n-nbq,xslash
            do 12 i = 1,n
               if(zaname(i)(1:2).ne."bq")
     &              write(nfblck,1011)g(1,i),g(2,i),g(3,i)
 12         continue
            if(nbq.ne.0)then
               write(nfblck,1020)nbq,xslash
               do 13 i = 1,n
                  if(zaname(i)(1:2).eq."bq")
     &                 write(nfblck,1011)g(1,i),g(2,i),g(3,i)
 13            continue
            endif
         endif
      endif
      return
 1000 format('block = gradients records = ',i5,' unit = au',
     & 1x,a1,/,1x,'f_format = "(6f22.14)"')
 1010 format(2x,3f15.7)
 1011 format(2x,3f22.14)
 1020 format('block = bq_gradients records = ',i5,' unit = au',
     & 1x,a1,/,1x,'f_format = "(6f22.14)"')
      end
_IF(drf)
      subroutine blkegr(n,g)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/blocks)
INCLUDE(common/runlab)
      dimension g(3,*)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
      if(.not. opg_root())return

      if(oblock(23))then
         if(iblfmt(23).eq.0)then
            write(nfblck,1000)n
            do 10 i = 1,n
                 write(nfblck,1010)g(1,i),g(2,i),g(3,i)
 10         continue
         else
            write(nfblck,1000)n,xslash
            do 12 i = 1,n
                 write(nfblck,1011)g(1,i),g(2,i),g(3,i)
 12         continue
         endif
      endif
      return
 1000 format('block = ext_gradients records = ',i5,' unit = au',
     & 1x,a1,/,1x,'f_format = "(6f22.14)"')
 1010 format(2x,3f15.7)
 1011 format(2x,3f22.14)
      end
_ENDIF
      subroutine blkgvb(index)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/sector)
INCLUDE(common/machin)
INCLUDE(common/blocks)
INCLUDE(common/scfwfn)
INCLUDE(common/restri)
      dimension kcorb(2,12)
      data m23/23/
c
c ---- read the most recent set of gvb pair coefficients
c      and store on punchfile
c
      if (npair .eq. 0) then
         write(iwr,*)'no gvb coefficients written to punchfile'
         write(iwr,*)'*** npair = 0 ***'
         goto 999
      endif
c
c     ----- generate kcorb -----
c
      nopen=0
      if (nseto .ne. 0) then
      do 100 i = 1,nseto
         nop = no(i)
         nopen = nopen+nop
  100 continue
      endif
      nbase = nco+nopen
      do 110 kpair = 1,npair
         kcorb(1,kpair) = nbase+1
         kcorb(2,kpair) = nbase+2
         nbase = nbase+2
 110  continue
c
      call secget(isect(504),m23,k)
      k=k+lensec(mach(5))
      call rdedx(cicoef,mach(5),k,numdu)
c
      if(opg_root())then
         write(nfblck,1000)npair,index
         do 120 i = 1,npair
            i1=kcorb(1,i)
            i2=kcorb(2,i)
            write(nfblck,1010)i1,i2,cicoef(1,i),cicoef(2,i)
 120     continue
      endif

 999  return
c
 1000 format('block = gvb_coefficients records = ',i3,
     &                                 ' index = ',i3)
 1010 format(2i5,2f12.6)
      end
      subroutine blkrun( opunch, runt, scftype, title)
c     Determine the runtype, scftype and title. If the oprint variable
c     is true we write those out to the punchfile that have been selected
      implicit None
INCLUDE(common/sizes)
INCLUDE(common/runlab)
INCLUDE(common/blocks)
      character*25 runt,scft1,scft2
      character*51 scftype
      character*80 title
      logical opg_root,opunch

      if(.not. opg_root())return

c     Determine the runtype
      runt=zruntp
      if(runt.eq.'optimize'.or.
     &     runt.eq.'optxyz  '.or.
     &     runt.eq.'jorgense')then
         runt='geometry_optimisation'
      else if(runt.eq.'saddle')then
         runt='saddle_point_search'
      else if(runt.eq.'force')then
         runt='force_constants'
      else if(runt.eq.'analyse')then
         runt='analysis'
      else if(runt.eq.'scf'.or.
     &        runt.eq.'ci'.or.
     &        runt.eq.'tda'.or.
     &        runt.eq.'gf')then
         runt='single_point'
      endif
c     Puch it out if necessary
      if(oblock(PUN_RUNT).and.opunch)then
         write(nfblck,1000)runt
      endif
c  Determine the SCF-type
      scft1=zscftp
      scft2=' '
      if(zruntp.eq.'ci'.or.
     &     zruntp.eq.'gf'.or.
     &     zruntp.eq.'tda') scft2=zruntp
      if(scft1.eq.'casscf')scft1='mcscf'
      if(scft1.eq.'direct')scft1='rhf'
      scftype = scft1//' '//scft2
      if(oblock(PUN_SCF_TYPE).and.opunch)then
         if(scft2.ne.' ')then
            write(nfblck,1010)scft1,scft2
         else
            write(nfblck,1010)scft1
         endif
      endif
      if(oblock(PUN_JOB_TITLE).and.opunch)then
         write(nfblck,1020)ztitle
      endif
      write(title,'(10a8)')ztitle

 1000 format('block = calculation_type records = 1',/a25)
 1010 format('block = calculation_level records = 1',/a8:' plus',a8)
 1020 format('block = title records = 1',/10a8)
      return
      end
      subroutine blkupd(cupd)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
cXML
c
c     Writes out the new geometries to the punchfile during
c     the course of a geometry optimisation.
c     This includes:
c     - atomic/point-charge coordinates
c
cXML
c
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
INCLUDE(common/blocks)
      dimension cupd(3,maxat)

INCLUDE(common/indxsv)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
_IF(xml)
INCLUDE(common/xmlout)
_ENDIF(xml)
      if(.not. opg_root())return
c
_IF(xml)
c     This subroutine has been hijacked to also write out update xml coordinates
      if(oxml_control(PUN_OPT_COORD)) then
c        increment counter for the molecule
         indx_xml=indx_xml+1
         call xmlWriteCoords(ztitle,zaname,symz,cupd,nat,indx)
      endif
_ENDIF
c
c --- write set of coordinates to punchfile
c
      if(oblock(PUN_OPT_COORD))then
         indx=indx+1
         if(indx.eq.1)then
            write(nfblck,1000)
            if(iblfmt(2).eq.0)then
               write(nfblck,1010)indx,nat
            else
               write(nfblck,1010)indx,nat,xslash
            endif
         else

            if(iblfmt(2).eq.0)then
               write(nfblck,1011)indx,nat
            else
               write(nfblck,1011)indx,nat,xslash
            endif
         endif
         do 100 i=1,nat
            if(iblfmt(2).eq.0)then
               write(nfblck,1020)zaname(i),cupd(1,i),cupd(2,i),cupd(3,i)
            else
               write(nfblck,1021)zaname(i),cupd(1,i),cupd(2,i),cupd(3,i)
            endif
 100     continue
         call flushn(nfblck)
      endif
      return
 1000 format('block = fragment.sequence records = 0')
 1010 format('block = coordinates index = ',i3,
     &  ' records = ',i5,' unit = au',
     & 1x,a1,/,1x,'f_format = "(2x,a8,3(3x,f22.14))"')
 1011 format('block = update_coordinates index = ',i3,
     &  ' records = ',i5,' unit = au',
     & 1x,a1,/,1x,'f_format = "(2x,a8,3(3x,f22.14))"')
 1020 format(2x,a8,3(3x,f12.7))
 1021 format(2x,a8,3(3x,f22.14))

      end
      subroutine blkener
c     Writes out the total energy to the punchfile
c     Has also been hijacked to write to the xml file
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
INCLUDE(common/restri)
INCLUDE(common/sector)
INCLUDE(common/blocks)
INCLUDE(common/drfopt)
INCLUDE(common/sizes)
INCLUDE(common/runlab)
_IF(xml)
INCLUDE(common/xmlout)
_ENDIF(xml)
_IF(drf)
INCLUDE(../drf/comdrf/sizesrf)
INCLUDE(../drf/comdrf/rfene)
INCLUDE(../drf/comdrf/enrgci)
_ENDIF
      REAL array(10),energy
      logical opg_root
      external opg_root
      data m10,m16/10,16/

c     Only do this if requested
      if(.not.oblock(PUN_TOT_ENER)) then
_IF(xml)
         if (.not.oxml_control(PUN_TOT_ENER)) return
_ELSE
         return
_ENDIF(xml)
      endif

      call secget(isect(494),m16,iblk00)
      call rdedx(array,m10,iblk00,numdu)
_IF(drf)
      if (eci(1) .ne. 0.d0) then
        etot=eci(1)
      else
        etot = array(3)
      endif
c      if(oblock(30) .and. opg_root()) then
        if (field .ne. ' ') then
c          write(nfblck,1001)uens(1)
          energy = uens(1)
        else
c         write(nfblck,1001)array(3)
c          write(nfblck,1001)etot
          energy = etot
        endif
c      endif
_ELSE
      energy = array(3)
_ENDIF(drf)

      enuc = array(1)
      ehf = array(2)
      sz = array(4)
      s2 = array(5)
      
      if(oblock(PUN_TOT_ENER) .and. opg_root()) then
c         write(nfblck,1001)array(3)
         write(nfblck,1001)energy
      endif
 1001 format('block = total_energy records = 1',/,f15.8)
c
_IF(xml)
c     Write out final energies to xml file too
      if(oxml_control(PUN_TOT_ENER).and.opg_root()) then
         call xmlAddPropertyList1( "Final Energies" )

         call xmlAddProperty1("gamess-uk:nuclearEnergy"  )
         call xmlAddDPScalar( enuc )
         call xmlEndProperty()

         call xmlAddProperty1( "gamess-uk:electronicEnergy" )
         call xmlAddDPScalar( ehf )
         call xmlEndProperty()

         call xmlAddProperty1( "gamess-uk:totalEnergy" )
         call xmlAddDPScalar( energy )
         call xmlEndProperty()

         if (zscftp.eq.'uhf') then
            call xmlAddProperty1( "gamess-uk:spin-sz" )
            call xmlAddDPScalar( sz )
            call xmlEndProperty()
            call xmlAddProperty1( "gamess-uk:s-squared" )
            call xmlAddDPScalar( s2 )
            call xmlEndProperty()
         endif

         call xmlEndPropertyList()
      endif
_ENDIF
      end
cjmhtnew
      subroutine blkscfe(ElectronicEnergy,NuclearEnergy,TotalEnergy)
c     Write out the final SCF energies to the xml file
      implicit none
INCLUDE(common/blocks)
INCLUDE(common/xmlout)
      REAL ElectronicEnergy,NuclearEnergy,TotalEnergy
_IF(xml)
      if (oxml) then
         if(oxml_control(PUN_SCF_ENER)) then
            call xmlSCFFinalEnergies(ElectronicEnergy,
     +           NuclearEnergy,TotalEnergy)
         endif
      endif
_ENDIF(xml)
      end
      subroutine blkscfhead(ConvThresh, ConvIndex, Maxcyc, DmpCutOff,
     +     DiisOn, DiisOff)
c     Write out the header for the SCF module that contains the
c     parameters used for the following cycles
      implicit none
INCLUDE(common/blocks)
INCLUDE(common/xmlout)
      integer ConvThresh, ConvIndex, MaxCyc
      REAL DmpCutOff, DiisOn, DiisOff
_IF(xml)
      if (oxml) then
         if(oxml_control(PUN_SCF_ENER)) then
            call xmlWriteModuleSCF(ConvThresh,ConvIndex,Maxcyc,
     +           DmpCutOff,DiisOn,DiisOff)
         endif
      endif
_ENDIF(xml)
      end
      subroutine blkscfc(Iteration,TotalEnergy,ElectronicEnergy,
     +     Econv, Tester)
c     Write out the SCF energy (& associated information) on each
c     SCF cycle to the xml file
      implicit none
INCLUDE(common/blocks)
INCLUDE(common/xmlout)
      integer Iteration
      REAL TotalEnergy, ElectronicEnergy, Econv, Tester
_IF(xml)
      if (oxml) then
         if(oxml_control(PUN_SCF_ENER)) then
            call xmlWriteModuleSCFCycle(Iteration,TotalEnergy,
     +           ElectronicEnergy, Econv, Tester)
         endif
      endif
_ENDIF(xml)
      end
      subroutine blkdip(dip)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/blocks)
      dimension dip(3)
      if(oblock(32) .and.opg_root())then
         write(nfblck,1000)dip
      endif
 1000 format('block = dipole_moment records = 1',/,3f15.8)
      end

      subroutine blkden(zscftp,ifile,q)
      implicit none
INCLUDE(common/sizes)
INCLUDE(common/dump3)
INCLUDE(common/infoa)
INCLUDE(common/blocks)
      REAL q(*)
      character *8 zscftp, zrhf, zcas
      integer ifile
      integer l2, i1, i2, j, nc, nrec
      integer igmem_alloc
      logical opg_root
      data zrhf,zcas/'rhf','casscf'/

      if(oblock(29)) then
         l2 = (num*(num+1))/2
         i1 = igmem_alloc(l2)
         call rdedx(q(i1),l2,ibl3pa,ifile)
         if (zscftp.ne.zrhf.and.zscftp.ne.zcas) then
            i2 = igmem_alloc(l2)
            call rdedx(q(i2),l2,ibl3pb,ifile)
            call daxpy(l2,1.0d0,q(i2),1,q(i1),1)
            call gmem_free(i2)
         end if
         nc = 6
         nrec=(l2-1+nc)/nc
         if(opg_root())then
            write(nfblck,1040) nrec,l2
            write(nfblck,1050)(q(i1+j-1),j=1,l2)
         endif
         call gmem_free(i1)
      endif


 1040 format('block = density records = ',i5,' elements = ',i3)
 1050 format(6f11.6)
      end

      subroutine blkhes(fcmat,nvar)

      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/blocks)
      dimension fcmat(nvar*nvar)

      nvar2=nvar*nvar
      if(oblock(31) .and. opg_root()) then
         nc = 6
         nrec=(nvar2-1+nc)/nc
         write(nfblck,100) nrec,nvar2
         write(nfblck,200) (fcmat(i),i=1,nvar2)
      endif
100   format('block = update_hessian records = ',i5,' elements = ',i6)
200   format(6f8.4)
      end
      subroutine blkvec(index,q)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
cXML
c
c     Writes out the MO-vectors to the punchfile.
c     This includes:
c     - MO coefficients
c     - MO energies
c     - MO occupations
c
cXML
c
INCLUDE(common/sizes)
      parameter (mxorb1=maxorb+1)
INCLUDE(common/iofile)
INCLUDE(common/scfopt)
INCLUDE(common/sector)
      common/junkcXX/zcom(19),ztit(10)
      common/junkXX/ilifd(maxorb),ntrad(maxorb),itrad(mxorb3),
     *ctrad(mxorb3),deig(maxorb),dpop(mxorb1),
     *nba,new,ncol,jeig,jpop
INCLUDE(common/infoa)
INCLUDE(common/discc)
INCLUDE(common/machin)
INCLUDE(common/blocks)
INCLUDE(common/drfopt)
INCLUDE(common/harmon)
INCLUDE(common/mapper)
_IF(drf)
cdrf
INCLUDE(../drf/comdrf/sizesrf)
INCLUDE(../drf/comdrf/rfene)
INCLUDE(../drf/comdrf/enrgci)
_ENDIF
      dimension dum(maxorb)
      dimension q(*)
c
      data m3,m29/3,29/
c
c ---- read a set of vectors off the dumpfile, and write
c      the energies, occupations and eigenvectors to the
c      formatted file for graphics.
c
      numsec = iblsec(index)
      if(numsec.gt.350)call caserr(
     *'invalid section specified for punchfile vectors')
c
      write(iwr,990)numsec,iblkdu,yed(numdu),index
c
      call secget(numsec,m3,k)
      call rdchr(zcom(1),m29,k,numdu)
      call reads(deig,mach(8),numdu)
      k=k+1+lensec(mach(8))
c

c      write(6,*)'New = ',new
c      write(6,*)'Nba = ',nba
c      write(6,*)'Ncol = ',ncol
c      write(6,*)'Num = ',num
c      write(6,*)'Newbas0 = ',newbas0
c      write(6,*)'Newbas1 = ',newbas1
c      write(6,*)'Nsym0 = ',nsym0

      if(new.eq.0)new=num
      if(nba.eq.0)nba=num
      if(ncol.eq.0)ncol=num

      if(new.ne.nba)call caserr(
     &  'vector matrix on dumpfile is not square')

      if(new.ne.ncol)then
         write(iwr,*)
     &  'warning, vectors written to punchfile have unexpected length',
     &  new,ncol
      endif
c
c ---  test for use of wrong section of rohf..
c
      do 99 i = 1,ncol
         if(dpop(i).lt.0.0d0)then
            write(iwr,*)' dpop(i) is -ve - check you are not writing'
            write(iwr,*)' an gvb internal vectors section',i,dpop(i)
ccc            call caserr('-ve populations')
         endif
 99    continue
c
c ---  total scf energy
c
      etot=dpop(mxorb1)
_IF(drf)
c     etot = eci(1)
      if(oblock(13) .and. opg_root()) then
        if (field .ne. ' ') then
          write(nfblck,1000)index,uens(1)
        else
          write(nfblck,1000)index,etot
        endif
      endif
_ELSE
      if(oblock(13) .and. opg_root())write(nfblck,1000)index,etot
_ENDIF
c
c --- occupations
c
      if(oblock(5) .and. opg_root())then
         write(nfblck,1010)ncol,index
         do 100 i = 1,ncol
 100        write(nfblck,1030)dpop(i)
      endif
c
c --- eigenvalues
c
      if(oblock(12) .and. opg_root())then
         write(nfblck,1020)ncol,index
         do 200 i = 1,ncol
 200        write(nfblck,1030)deig(i)
      endif
c
c --- eigenvectors
c
      if(oblock(6))then
         nc = 6
         nrec=ncol*(1+(nba-1)/nc)

c     get data for adaption

         nw=nba*new
         itmp = igmem_alloc(nw)
         nav = lenwrd()

         call readis(ilifd,mach(9)*nav,numdu)
         call reads(q(itmp),nw,numdu)
cc         call tdown(qnew,ilifn,q,ilifq,nnn)
         call tdown(q(itmp),ilifq,q(itmp),ilifq,num)

         if(opg_root())then

c         m=0
c         do 310 i=1,ncol
c            call vclr(dum,1,nba)
c            do 300 j=1,nba
c               n=ntrad(j)
c               do 300 k=1,n
c                   l=ilifd(j)+k
c 300               dum(itrad(l))=ctrad(l)*q(itmp-1+m+j)+dum(itrad(l))
c            call dcopy(nba,dum(1),1,q(itmp+m),1)
c            m=m+nba
c 310     continue

         write(nfblck,1040)nrec,index,nba,ncol
         do 320 i = 1,ncol
 320        write(nfblck,2050)(q(itmp+(i-1)*nba+j-1),j=1,nba)
         endif
         call gmem_free(itmp)
      endif
 999  return
c
 990  format(/1x,'punchfile vectors restored from section',i4,
     *' of dumpfile starting at block',i6,' of ',a4,/
     *1x,'to be written to punchfile with index ',i3)
 1000 format('block = scf_energy records = 1 index = ',i3/,f15.8)
 1010 format('block = occupations records = ',i5,' index = ',i3)
 1020 format('block = eigenvalues records = ',i5,' index = ',i3)
 1030 format(f10.6)
 1040 format('block = vectors records = ',i5,' index = ',i3,
     &     ' elements = ',i3,' sets = ',i3)
 1050 format(6f11.6)
 2050 format(6f20.15)
      end
      subroutine blkvib(i,anor,freq)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
cXML
c
c     Writes out the vibrational modes.
c     This includes:
c     - the normal modes
c     - the corresponding frequencies
c
cXML
c
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
INCLUDE(common/iofile)
INCLUDE(common/blocks)
      dimension anor(*)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
      if(.not. opg_root())return

      if(oblock(10).or.oblock(21))then
c
c --- write a set of normal coordinates and frequencies to punchfile
c
         if(oblock(21))then
            if(iblfmt(21).eq.0)then
               write(nfblck,1010)i,nat
            else
               write(nfblck,1010)i,nat,xslash
            endif
            i1=0
            do 90 j=1,nat
               if(iblfmt(21).eq.0)then
                  write(nfblck,1020)zaname(j),(anor(i1+k),k=1,3)
               else
                  write(nfblck,1021)zaname(j),(anor(i1+k),k=1,3)
               endif
               i1=i1+3
 90         continue
         endif
         if(oblock(10))then
            if(iblfmt(10).eq.0)then
               write(nfblck,1030)i,freq
            else
               write(nfblck,1031)i,freq
            endif
         endif
      endif
      return
 1010 format('block = normal_coordinates index = ',i3,
     &     ' records = ' ,i5,
     & 1x,a1,/,1x,'f_format = "(2x,a8,3(3x,f12.7))"')
 1020 format(2x,a8,3(3x,f12.7))
 1021 format(2x,a8,3(3x,f22.14))
 1030 format('block = vibrational_frequency index = ',i3,
     &' records = 1 unit = cm**-1',/,f16.6)
 1031 format('block = vibrational_frequency index = ',i3,
     &' records = 1 unit = cm**-1',/,1x,'f_format = "(22.14)"',
     & /,f22.14)
      end
      subroutine blkir(i,ampir)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
INCLUDE(common/iofile)
INCLUDE(common/blocks)
      if(.not. opg_root())return
c
c --- write a infrared intensities to the punchfile
c
      if(oblock(33))then
         if(iblfmt(33).eq.0)then
            write(nfblck,1030)i,ampir
         else
            write(nfblck,1031)i,ampir
         endif
      endif
      return
 1030 format('block = infrared_intensity index = ',i3,
     &' records = 1 unit = km/mol',/,f16.6)
 1031 format('block = infrared_intensity index = ',i3,
     &' records = 1 unit = km/mol',/,1x,'f_format = "(22.14)"',
     & /,f22.14)
      end
      subroutine blkraman(i,raman)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
INCLUDE(common/iofile)
INCLUDE(common/blocks)
      if(.not. opg_root())return
c
c --- write a raman intensities to the punchfile
c
      if(oblock(34))then
         if(iblfmt(34).eq.0)then
            write(nfblck,1030)i,raman
         else
            write(nfblck,1031)i,raman
         endif
      endif
      return
 1030 format('block = raman_intensity index = ',i3,
     &' records = 1',/,f16.6)
 1031 format('block = raman_intensity index = ',i3,
     &' records = 1',/,1x,'f_format = "(22.14)"',
     & /,f22.14)
      end
      subroutine blktra(t,tx,ty,tz,igp,nax)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/blocks)
      dimension t(3,3)
      dimension zgrp(19)
      data zgrp /'c1','cs','ci','cn','s2n','cnh',
     + 'cnv' ,'dn'  ,'dnh' ,'dnd' ,'cinfv','dinfh','t'   ,
     + 'th'  ,'td'  ,'o'   ,'oh'  ,'i'   ,'ih'  /
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
      if(.not. opg_root())return

      if(oblock(24))then
         if(iblfmt(24).eq.0)then
            write(nfblck,1000)
            write(nfblck,1010)(t(i,1),i=1,3),tx
            write(nfblck,1010)(t(i,2),i=1,3),ty
            write(nfblck,1010)(t(i,3),i=1,3),tz
         else
            write(nfblck,1000)xslash
            write(nfblck,1011)(t(i,1),i=1,3),tx
            write(nfblck,1011)(t(i,2),i=1,3),ty
            write(nfblck,1011)(t(i,3),i=1,3),tz
         endif
         write(nfblck,1020)zgrp(igp),nax
      endif
 1000 format('block = tr_matrix records = 3',
     &     1x,a1,/,1x,'f_format = "(2x,4f22.14)"')
 1010 format(2x,4f15.7)
 1011 format(2x,4f22.14)  
 1020 format('block = point_group records = 1',/,1x,a8,2x,i2)
      return
      end
      subroutine blktwo
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/blkin/g(510),mword,mspace,f(2),ia(2),
     *ja(2),ka(2),la(2)
_IF(ibm,vax)
      common/craypk/i205(340),j205(340),k205(340),l205(340)
_ELSE
      common/craypk/i205(1360)
_ENDIF
INCLUDE(common/blocks)
INCLUDE(common/files)
INCLUDE(common/atmblk)
      common/disc/irep(5),nt(maxlfn)
_IF(linux)
      external fget
_ENDIF
c
c --- punch integrals from mainfile
c
      if(.not.oblock(22))return
c
      iunit = n2tape(1)
c
c --- count the integrals
c
      call search(itwoe,iunit)
      call setsto(numlab,0,i205)
      nblk=ntwoe
      nint=0
 10   call fget(g,nword,iunit)
      if(nword.eq.0)goto 20
      nint=nint+mword
      nblk=nblk-1
      if(nblk.ne.0)goto 10
c
c --- punch them
c
 20   call search(itwoe,iunit)
      nblk=ntwoe

      if(opg_root())write(nfblck,1000)nint
 30   call fget(g,nword,iunit)
      if(nword.eq.0)return
_IF(ibm,vax)
      call upak8v(g(num2e+1),i205)
_ELSE
      call unpack(g(num2e+1),lab816,i205,numlab)
      int4=1
_ENDIF
      do 40 iw=1,mword
         if(opg_root())write(nfblck,1010)
         write(nfblck,1010)
_IF(ibm,vax)
     &      i205(iw),j205(iw),k205(iw),l205(iw),g(iw)
_ELSE
     &      i205(int4),i205(int4+1),i205(int4+2),i205(int4+3),g(iw)
         int4=int4+4
_ENDIF
 40      continue
      nblk=nblk-1
      if(nblk.ne.0)goto 30
      return
 1000 format('block = two_electron_integrals records = ',i7)
 1010 format(4i4,f17.10)
      end
      subroutine intval(s,ii,oo)
c
c returns oo .true. if yy is a positive integer
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character s*(*)
      character*10 num
      data num /'0123456789'/
c
      lens = len(s)
      oo = .true.
      ii=0
c
c  locate first space
      i1=index(s,' ')
c
c move forward if not left justified
      if(i1.eq.1)then
         do while(s(i1:i1).eq.' ')
            i1 = i1 + 1
            if(i1.gt.lens)then
               oo = .false.
               i = 0
               return
            endif
         enddo
      endif
c
      if(i1.eq.0)i1=lens+1
      imult=1
      do 10 i=i1-1,1,-1
         j = index(num,s(i:i))
         if(j.eq.0)then
            if (i.eq.1.and.s(i:i).eq.'-') then
               ii = -ii
               return
            else if (i.eq.1.and.s(i:i).eq.'+') then
               return
            else
               oo=.false.
               return
            endif
         else
            ii=ii+imult*(j-1)
            imult=imult*10
         endif
 10      continue
      return
      end
      subroutine blkpdc(chg)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension chg(*)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/blocks)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
      if(.not. opg_root())return
c
c --- punch out pdc results
c
      if(oblock(25))then
         if(iblfmt(25).eq.0)then
            write(nfblck,1000)nat
            write(nfblck,1010)(chg(i),i=1,nat)
         else
            write(nfblck,1000)nat,xslash
            write(nfblck,1011)(chg(i),i=1,nat)
         endif
      endif
      return
 1000 format('block = potential_derived_charges records = ',i4,
     &     1x,a1,/,1x,'f_format = "(f22.14)"')
 1010 format(f10.6)
 1011 format(f22.14)
      end
      subroutine blkat(qm,ql,zel)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/blocks)
      dimension ql(*),qm(*)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
c
      if(.not. opg_root())return
c
c --- punch out mulliken and lowdin atomic
c     results
c
      if(oblock(17))then
         if(iblfmt(17).eq.0)then
            if(zel.eq.'   alpha')write(nfblck,1010)nat
            if(zel.eq.'    beta')write(nfblck,1030)nat
            if(zel.eq.'     all')write(nfblck,1050)nat
            if(zel.eq.'    spin')write(nfblck,1070)nat
            write(nfblck,1090)(qm(i),i=1,nat)
         else
            if(zel.eq.'   alpha')write(nfblck,1010)nat,xslash
            if(zel.eq.'    beta')write(nfblck,1030)nat,xslash
            if(zel.eq.'     all')write(nfblck,1050)nat,xslash
            if(zel.eq.'    spin')write(nfblck,1070)nat,xslash
            write(nfblck,1091)(qm(i),i=1,nat)
         endif
c compute atomic charges
         if(zel.eq.'     all')then
            if(iblfmt(17).eq.0)then
               write(nfblck,1100)nat
               write(nfblck,1090)(czan(i) - qm(i),i=1,nat)
            else
               write(nfblck,1100)nat,xslash
               write(nfblck,1091)(czan(i) - qm(i),i=1,nat)
            endif
         endif
      endif

      if(oblock(18))then
         if(iblfmt(18).eq.0)then
            if(zel.eq.'   alpha')write(nfblck,1020)nat
            if(zel.eq.'    beta')write(nfblck,1040)nat
            if(zel.eq.'     all')write(nfblck,1060)nat
            if(zel.eq.'    spin')write(nfblck,1080)nat
            write(nfblck,1090)(ql(i),i=1,nat)
         else
            if(zel.eq.'   alpha')write(nfblck,1020)nat,xslash
            if(zel.eq.'    beta')write(nfblck,1040)nat,xslash
            if(zel.eq.'     all')write(nfblck,1060)nat,xslash
            if(zel.eq.'    spin')write(nfblck,1080)nat,xslash
            write(nfblck,1091)(ql(i),i=1,nat)
         endif
c     compute atomic charges
         if(zel.eq.'     all')then
            if(iblfmt(18).eq.0)then
               write(nfblck,1110)nat
               write(nfblck,1090)(czan(i) - ql(i),i=1,nat)
            else
               write(nfblck,1110)nat,xslash
               write(nfblck,1091)(czan(i) - ql(i),i=1,nat)
            endif
         endif
      endif
      return
 1010 format('block = alpha_mulliken_atom_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1020 format('block = alpha_lowdin_atom_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1030 format('block = beta_mulliken_atom_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1040 format('block = beta_lowdin_atom_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1050 format('block = mulliken_atom_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1060 format('block = lowdin_atom_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1070 format('block = mulliken_atom_spin_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1080 format('block = lowdin_atom_spin_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1100 format('block = mulliken_atomic_charges records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1110 format('block = lowdin_atomic_charges records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1090 format(f10.6)
 1091 format(f22.14)
      end
      subroutine blkao(qm,ql,zel)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/blocks)
      dimension ql(*),qm(*)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
c
      if(.not. opg_root())return
c
c --- punch out mulliken and lowdin atomic
c     results
c
      if(oblock(17))then
         if(iblfmt(17).eq.0)then
            if(zel.eq.'   alpha')write(nfblck,1010)num
            if(zel.eq.'    beta')write(nfblck,1030)num
            if(zel.eq.'     all')write(nfblck,1050)num
            if(zel.eq.'    spin')write(nfblck,1070)num
            write(nfblck,1090)(qm(i),i=1,num)
         else
            if(zel.eq.'   alpha')write(nfblck,1010)num,xslash
            if(zel.eq.'    beta')write(nfblck,1030)num,xslash
            if(zel.eq.'     all')write(nfblck,1050)num,xslash
            if(zel.eq.'    spin')write(nfblck,1070)num,xslash
            write(nfblck,1091)(qm(i),i=1,num)
         endif
      endif
      
      if(oblock(18))then
         if(iblfmt(18).eq.0)then
            if(zel.eq.'   alpha')write(nfblck,1020)num
            if(zel.eq.'    beta')write(nfblck,1040)num
            if(zel.eq.'     all')write(nfblck,1060)num
            if(zel.eq.'    spin')write(nfblck,1080)num
            write(nfblck,1090)(ql(i),i=1,num)
         else
            if(zel.eq.'   alpha')write(nfblck,1020)num,xslash
            if(zel.eq.'    beta')write(nfblck,1040)num,xslash
            if(zel.eq.'     all')write(nfblck,1060)num,xslash
            if(zel.eq.'    spin')write(nfblck,1080)num,xslash
            write(nfblck,1091)(ql(i),i=1,num)
         endif
      endif
      return

 1010 format('block = alpha_mulliken_ao_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1020 format('block = alpha_lowdin_ao_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1030 format('block = beta_mulliken_ao_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1040 format('block = beta_lowdin_ao_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1050 format('block = mulliken_ao_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1060 format('block = lowdin_ao_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1070 format('block = mulliken_ao_spin_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1080 format('block = lowdin_ao_spin_populations records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1090 format(f10.6)
 1091 format(f22.14)
      end
**==blkspd.f
      subroutine blkspd(qs)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension qs(*)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/blocks)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF

      if(.not. opg_root())return
c
c --- punch out spin density at nucleus
c
      if(oblock(19))then
         if(iblfmt(19).eq.0)then
            write(nfblck,1010)nat
            write(nfblck,1020)(qs(i),i=1,nat)
         else
            write(nfblck,1010)nat,xslash
            write(nfblck,1021)(qs(i),i=1,nat)
         endif
      endif
      return
c
 1010 format('block = spin_densities records = ',i4,
     & 1x,a1,/,1x,'f_format = "(f22.14)"')
 1020 format(f10.6)
 1021 format(f22.14)
      end
**==blkdms.f
      subroutine blkdms(nsites,name,c,limit,radius)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/blocks)
      dimension  c(3,*), limit(*), radius(*)
      character*8 name(*)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
      if(.not. opg_root())return
c
c --- punch out sites for DMA expansion
c
      if(oblock(28))then
         if(iblfmt(28).eq.0)then
            write(nfblck,1010)nsites
            do 10 i = 1,nsites
            write(nfblck,1020)name(i),(c(j,i),j=1,3),limit(i),radius(i)
 10         continue
         else
            write(nfblck,1010)nsites,xslash
            do 20 i = 1,nsites
            write(nfblck,1021)name(i),(c(j,i),j=1,3),limit(i),radius(i)
 20         continue
         endif
      endif
      return
 1010 format('block = dma_sites records = ',i4,
     & 1x,a1,/,1x,'f_format = "(a8,2x,3f22.14,i4,f10.6)"')
 1020 format(a8,2x,3f10.6,i4,f10.6)
 1021 format(a8,2x,3f22.14,i4,f10.6)
      end
c
c   punch out all poles on a given site
c
      subroutine blkdma(q,lm, linear,isite)
      implicit REAL (a-h,o-z),integer  (i-n)
      logical linear, opg_root
      character*1 xslash
      dimension q(121)
INCLUDE(common/blocks)
_IF(doublebackslash)
      data xslash/'\\'/
_ELSE
      data xslash/'\'/
_ENDIF
c
      if(.not. opg_root())return
c
      if(oblock(28))then
         if (linear) then
c     write (iwr,6010) q(1) , (lq,k,q(k+1),k=1,lm)
            write(6,*)'no punch implemented for linear dma'
            return
         else
            ioff=0
            do 30 l = 0 , lm
               ll1 = l + l + 1
               if(iblfmt(28).eq.0)then
                  write(nfblck,1000)isite,l,ll1
               else
                  write(nfblck,1000)isite,l,ll1,xslash
               endif
               do k = 1,ll1
                  if(iblfmt(28).eq.0)then
                     write(nfblck,1020)q(ioff+k)
                  else
                     write(nfblck,1021)q(ioff+k)
                  endif
               enddo
               ioff = ioff + ll1
 30         continue
         end if
      endif
      return
 1000 format('block = dma_pole site = ',i4,' j = ',i2,' records = ',i4,
     &     1x,a1,/,1x,'f_format = "(e22.14)"')
 1020 format(e16.6)
 1021 format(e22.14)
      end
      subroutine blkerror(errstr,code)
c     Subroutine to write out the error code
c     Currently only used for xml, but could be extended to punchfile too
      implicit none
INCLUDE(common/blocks)
INCLUDE(common/xmlout)
      character*80 errstr
      integer code
      logical opg_root
      external opg_root
_IF(xml)
      if (opg_root().and.oxml) call xmlAddError(errstr,code)
_ENDIF(xml)
      return
      end
      character*2 function charge2element( charge )
cjmht Used in xmlWriteCoords
INCLUDE(common/periodic)
      REAL charge
      charge2element = zelem( int( charge ) )
      return
      end
**==copyfi.f
      subroutine copyfi
      implicit REAL  (a-h,o-z)
c
c     copy one file to another
c
INCLUDE(common/sizes)
      character *8 filev
      common/disc/isel,iselr,iselw,irep,ichek,ipos(maxlfn)
INCLUDE(common/iofile)
      character *4 nam
INCLUDE(common/discc)
      common /blkcore/blok(512),array(10)
      call inpa(filev)
      call inpi(ib1)
      if1 = 0
      do 20 j = 1 , maxlfn
         if (filev(1:4).eq.yed(j)) if1 = j
 20   continue
      if (if1.eq.0) go to 50
      call inpa(filev)
      call inpi(ib2)
      call inpi(nblock)
      if2 = 0
      do 30 j = 1 , maxlfn
         if (filev(1:4).eq.yed(j)) if2 = j
 30   continue
      if (if2.eq.0) go to 50
c  check data
      if (ib1.eq.0) go to 50
      if (ib2.eq.0) go to 50
c  position and copy
      call search(ib1,if1)
      call search(ib2,if2)
      if (nblock.eq.0) then
         nblock = 1000000
      end if
      icount = 0
 40   icount = icount + 1
      call find(if1)
      call get(blok,nw)
      call put(blok,nw,if2)
      if (nw.ne.0) then
         if (icount.lt.nblock) go to 40
      end if
      call clredx
      call whtps
      return
 50   write (iwr,*) if1 , if2 , ib1 , ib2 , nblock
      call caserr(' error in file specifications in copy')
c
      end
**==reor.f
      subroutine reor(q,nitems,num,iint)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      character *8 ztext,vect,onel,twoel,mos,stop,filev
      common/disc/isel,iselr,iselw,irep,ichek,ipos(maxlfn)
INCLUDE(common/discc)
      dimension iint(num),q(*)
      data vect,onel,twoel,mos/'vectors','onel','twoel','mos'/
      data stop/'end'/
      call inpa(filev)
      call inpi(ib1)
      do 20 i = 1 , maxlfn
         if (filev(1:4).eq.yed(i)) if1 = i
 20   continue
      call inpa(filev)
      call inpi(ib2)
      do 30 i = 1 , maxlfn
         if (filev(1:4).eq.yed(i)) if2 = i
 30   continue
      n = 0
 40   call input
      do 50 i = 1 , nitems
         n = n + 1
         call inpi(iint(n))
 50   continue
      if (n.lt.num) go to 40
 60   call input
      call inpa(ztext)
      if (ztext.eq.mos) then
         call reordv(q(1),q(1+num*num),ib1,if1,ib2,if2,iint)
         go to 60
      else if (ztext.eq.vect) then
         call reordv(q(1),q(1+num*num),ib1,if1,ib2,if2,iint)
         go to 60
      else if (ztext.eq.onel) then
         call reord1(q(1),q(1+num*num),ib1,if1,ib2,if2,iint)
         go to 60
      else if (ztext.eq.twoel) then
         call reordi(ib1,if1,ib2,if2,iint)
         go to 60
      else if (ztext.eq.stop) then
         return
      else
         call caserr(' unrecognised type in reorder directive')
         go to 60
      end if
      end
**==reord1.f
      subroutine reord1(a,b,ib1,if1,ib2,if2,iint)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
      dimension iint(*),a(*),b(*)
      len = num*(num+1)/2
      call rdedx(a,len,ib1,if1)
      ij = 0
      do 30 i = 1 , num
         do 20 j = 1 , i
            ij = ij + 1
            val = a(ij)
            i1 = iint(i)
            j1 = iint(j)
            if (j1.gt.i1) then
               ijnew = j1*(j1-1)/2 + i1
            else
               ijnew = i1*(i1-1)/2 + j1
            end if
            b(ijnew) = val
 20      continue
 30   continue
      call wrt3(b,len,ib2,if2)
      call clredx
      call whtps
      return
      end
**==reordi.f
      subroutine reordi(ib1,if1,ib2,if2,iint)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension iint(maxorb)
_IF(ibm,vax)
      common/craypk/i205(340),j205(340),k205(340),l205(340)
      common/sortpk/ij205(340),kl205(340)
_ELSE
      common/craypk/labs(1360)
_ENDIF
      common/blkin/yin(510),nword
INCLUDE(common/mapper)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
      data m0/0/
      if (if1.eq.if2) then
         write (iwr,6010) if1 , if2
         call caserr(' error ')
      end if
      call setsto(numlab,0,i205)
      ib = 0
      call search(ib2,if2)
      call search(ib1,if1)
 20   call find(if1)
      call get(yin,nw)
      if (nw.eq.m0) then
         if (ib.eq.0) then
            write (iwr,6020)
         else
            nword = 0
            call put(yin,m0,if2)
            write (iwr,6030) ib
         end if
         call clredx
         call whtps
         return
      else
_IF(ibm,vax)
      call upak8v(yin(num2e+1),i205)
_ELSE
      call unpack(yin(num2e+1),lab816,labs,numlab)
      int4=1
_ENDIF
         do 30 jjjj = 1 , nword
_IF(ibm,vax)
         i=i205(jjjj)
         j=j205(jjjj)
         k=k205(jjjj)
         l=l205(jjjj)
_ELSE
_IF(littleendian)
         i=labs(int4+1)
         j=labs(int4  )
         k=labs(int4+3)
         l=labs(int4+2)
_ELSE
         i=labs(int4  )
         j=labs(int4+1)
         k=labs(int4+2)
         l=labs(int4+3)
_ENDIF
_ENDIF
            i1 = iint(i)
            j1 = iint(j)
            k1 = iint(k)
            l1 = iint(l)
            if (j1.gt.i1) then
               iswop = i1
               i1 = j1
               j1 = iswop
            end if
            if (l1.gt.k1) then
               iswop = k1
               k1 = l1
               l1 = iswop
            end if
            if (k1*(k1-1)/2+l1.gt.i1*(i1-1)/2+j1) then
               iswop = i1
               i1 = k1
               k1 = iswop
               iswop = j1
               j1 = l1
               l1 = iswop
            end if
_IF(ibm,vax)
            ij205(jjjj) = j1 + i4096(i1)
            kl205(jjjj) = l1 + i4096(k1)
_ELSE
            labs(int4  ) = i1
            labs(int4+1) = j1
            labs(int4+2) = k1
            labs(int4+3) = l1
            int4 = int4 + 4
_ENDIF
 30      continue
_IF(ibm,vax)
         call pak4v(ij205,yin(num2e+1))
_ELSE
         call pack(yin(num2e+1),lab816,labs,numlab)
_ENDIF
         call put(yin,m511,if2)
         ib = ib + 1
         go to 20
      end if
 6010 format (//1x,'integral reordering ----- the two files must',
     +        ' not be same'/1x,'if1 =',i6,'   if2 =',i6)
 6020 format ('no integrals')
 6030 format ('blocks written to second file',i4)
      end
**==reordv.f
      subroutine reordv(va,vb,ib1,if1,ib2,if2,ivec)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/atmblk)
      common/blkin/blok(511)
      dimension ivec(*),va(num,num),vb(num,num)
      call search(ib1,if1)
      call search(ib2,if2)
      nsq = num*num
      if (if1.eq.if2 .and. ib1.eq.ib2) then
         call rdedx(va,nsq,ib1+mvadd,if1)
      else
c  copy mvadd blocks from if1 to if2
         do 20 ir = 1 , mvadd
            call find(if1)
            call get(blok,nw)
            call put(blok,nw,if2)
 20      continue
         call reads(va,nsq,if1)
      end if
      do 40 i = 1 , num
         do 30 j = 1 , num
            i1 = ivec(i)
            vb(i1,j) = va(i,j)
 30      continue
 40   continue
      if (if1.eq.if2 .and. ib1.eq.ib2) then
         call wrt3(vb,nsq,ib2+mvadd,if2)
      else
         call wrt3s(vb,nsq,if2)
      end if
      call clredx
      call whtps
      return
      end
c
c  AIMPAC interface code
c  Added P. Sherwood Sept 97
c  Assumes natural orbitals have already been generated
c  where required
c
      block data aimpac_data
      implicit none
INCLUDE(common/aimpac)
      data aimpac_unit/59/
      data write_aimpac /.false./
      data aimpac_file/"aimpac.wfn"/
c
c default section for orbitals, 0 means try and guess
c
      data aimpac_sec/0/
      end
c
c   ---- request AIMPAC output
c
      subroutine aimpac_request(file,sec)
      implicit none
      character file*(*)
      integer sec
INCLUDE(common/aimpac)
      if(file.ne." ".and.file.ne."off") aimpac_file=file
      if(sec .ne. 0)aimpac_sec=sec
      write_aimpac = .true.
      if (file.eq."off") then
         write_aimpac = .false.
      end if
      end
c
c -----  test if interface has been invoked 
c        (used to control virial calculation in SCF)
c
      logical function oaimpac()
      implicit none
INCLUDE(common/aimpac)
      oaimpac = write_aimpac
      end
c
c   ---- punch file for Bader's AIMPAC program
c
      subroutine aimpac(q)
      implicit none

INCLUDE(common/aimpac)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/iofile)
      REAL q(*)

      external igmem_alloc
      integer igmem_alloc

      external lenwrd
      integer lenwrd

      integer nav, itype, icent, expon, aic, vec, dum
      integer nprim
      integer i, kst, ken, jmin, jmax
      logical gtf
c
c --- check for user request
c
      if( .not. write_aimpac)return
c
c ---- set nprim - length of primitive expansion
c
      gtf=.false.
      nprim=0
      DO i = 1,nshell
         kst = kstart(i)
         ken = kst + kng(i) - 1
         jmin = kmin(i)
         jmax = kmax(i)
c        Aimpac currently can't deal with functions higher than F,
c        so ignore all functions above F
         if ( jmin .le. 21 ) then
            nprim = nprim + (jmax-jmin+1)*(ken-kst+1)
         else
            gtf=.true.
         endif
      enddo

c
c  ---- Warn if we have functions higher than F
c
      if ( gtf ) then
         write(iwr,10)
 10      format(/10x,65('!')/
     & 14x,'WARNING: Calculation contains functions higher than G!'/
     & 14x,'Functions above F will not be written to the AIMPAC file.'/
     & 14x,'The results may not be what you expected...'/
     & 10x,65('!')/)
      endif
c
c  ---- allocate scratch memory
c
      nav = lenwrd()
      itype = igmem_alloc( 1 + (nprim-1)/nav )
      icent = igmem_alloc( 1 + (nprim-1)/nav )
      expon = igmem_alloc( nprim )
      aic = igmem_alloc( nprim )
      vec = igmem_alloc( num*num )
      dum = igmem_alloc( nprim )

      call aimpac1(q,  q(itype), q(icent), q(expon), q(aic), 
     &     q(vec), q(dum), nprim)

      call gmem_free(dum)
      call gmem_free(vec)
      call gmem_free(aic)
      call gmem_free(expon)
      call gmem_free(icent)
      call gmem_free(itype)

      end

      subroutine aimpac1(core, itype, icent, expon, aic, vec, dum,
     &     nprim)
      implicit none

INCLUDE(common/sizes)
INCLUDE(common/aimpac)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
INCLUDE(common/iofile)
INCLUDE(common/nshel)
INCLUDE(common/periodic)
INCLUDE(common/sector)
INCLUDE(common/discc)
INCLUDE(common/scfopt)
INCLUDE(common/machin)
INCLUDE(common/atmol3)
INCLUDE(common/errcodes)
INCLUDE(common/tran)
INCLUDE(common/unocas)
INCLUDE(common/mapper)
INCLUDE(common/restri)
INCLUDE(common/restrl)
INCLUDE(common/harmon)

      REAL core(*), expon(*), aic(*), vec(num,num), dum(*)
      integer itype(*), icent(*), nprim

      character*8 zcom2, ztit2
      common/junkcXX/zcom2(19),ztit2(10)

      integer nba,new,ncol,jeig,jpop
      REAL etot1,deig,dpop
      common/junkXX/deig(maxorb),dpop(maxorb),etot1,
     &     nba,new,ncol,jeig,jpop

      REAL potnuc(10)
      common/blkin/potnuc

      external lenwrd, isubst
      integer lenwrd, isubst

      external opg_root
      logical opg_root

      integer l, i, j, k, jst, jen, mink, maxk, ii
      integer kst, ken, jmin, jmax
      integer m, maxocc, nw, nucz, nav, iblk34
      REAL znuc, fac(1+3+6+10+15)
      REAL etot2, etot3, ekin, vir2
      REAL dnel          ! number of electrons as obtained from 
                         ! orbital occupations
      logical oneg
      character *8 ztmp

      integer m3, m10, m16, m29
      integer p,n,ioff(1+3+6+10+15)


      integer iguk, iguk1

      REAL rt3, rt5, rt7, rt53, rt57, rt57drt3 
      parameter(rt3=1.7320508075689d0)
      parameter(rt5=2.2360679774998d0)
      parameter(rt7=2.64575131106459d0)
      parameter(rt53=rt5*rt3)
      parameter(rt57=rt5*rt7)
      parameter(rt57drt3=rt5*rt7/rt3)

      data m3,m10,m16,m29/3,10,16,29/

c     Data for fac derived from subroutine dipxyz in intega.m
c              ssssssss,pppppppp,dddddddddddddd,ffffffffffffffffff
      data fac/1*1.00d0,3*1.00d0,3*1.00d0,3*rt3,3*1.0d0,6*rt5,rt53
     1        ,3*1.00d0,6*rt7,3*rt57drt3,3*rt57/
c              gggggggggggggggggggggggggggggggg 

c     ioff is a mapping array for the ordering of basis functions
c     between GAMESS-UK & AIMPAC
c     GAMESS-UK ordering derived from subroutine bas_val in xc.m
c     AIMPAC ordering derived from extreme.f
c     GUK-F: x^3 y^3  z^3  x^2y x^2z xy^2 y^2z xz^2 yz^2 xyz
c     AIM-F: x^3 y^3  z^3  x^2y x^2z y^2z xy^2 xz^2 yz^2 xyz

c     GUK-G: x^4 y^4  z^4  x^3y   x^3z   y^3x y^3z z^3x  z^3y  x^2y^2 x^2z^2 y^2z^2 x^2yz  y^2xz z^2xy
c     AIM-G: ??? - TO DO - NOT SUPPORTED BY AIMPAC YET

      data ioff/
     s          1,
     p          1,2,3,
     d          1,2,3,4,5,6,
     f          1,2,3,4,5,7,6,8,9,10,
     g          1,11,15,2,3,6,12,7,14,4,5,13,8,9,10/

c
c  ----  open AIMPAC .wfn file
c
      if (opg_root()) write(iwr,9000) aimpac_file(1:40)
      open(file=aimpac_file,unit=aimpac_unit,form='formatted',
     &     status='unknown',err=9999)
c
c  ---- try and find the user suitable default vectors section
c
      ztmp = zscftp
      if(ztmp.eq.'rhf'.and.mp2)ztmp = 'mp2'
      if(ztmp.eq.'uhf'.and.mp2)ztmp = 'ump2'

      if (aimpac_sec .eq. 0)then

         if(zruntp.eq.'scf     '.or.zruntp.eq.'optimize'.or.
     *        zruntp.eq.'saddle  '.or.zruntp.eq.'optxyz  '.or.
     *        zruntp.eq.'jorgense'.or.
     *        zruntp.eq.'gradient'.or.
     *        zruntp.eq.'force   '.or.
     *        zruntp.eq.'hessian '.or.
     *        zruntp.eq.'prop    ')then
            if(ztmp.eq.'rhf')then
               aimpac_sec = mouta
            else if(ztmp.eq.'uhf' .or. ztmp .eq. 'mp2' 
     &              .or. ztmp .eq. 'ump2')then
               if(iuno.gt.0)then
                  aimpac_sec = iuno
               else
                  call caserr(
     & 'for AIMPAC interface use NATORB directive and specify'//
     & ' a dumpfile section')
               endif
            else if(ztmp.eq.'gvb')then
               aimpac_sec = mouta
               if(moutb.ne.0)aimpac_sec = moutb
            else
               goto 9998
            endif
         else
            goto 9998
         endif
      endif

c
c    fill -aic- (contraction coeffs), -itype-, -icent, -expon-
c
      l = 0
      do 130 i = 1,nshell
         jst = kstart(i)
         jen = jst + kng(i) - 1
         mink = kmin(i)
         maxk = kmax(i)
c        Ignore all functions above F
         if (mink .le. 21) then
            do 120 k = mink,maxk
               do 110 j = jst,jen
                  l = l + 1
                  icent(l) = katom(i)
                  itype(l) = k
                  expon(l) = ex(j)
                  if (k .eq. 1)                 aic(l) = cs(j)
                  if (k .ge. 2 .and. k .le. 4)  aic(l) = cp(j)
                  if (k .ge. 5 .and. k .le. 10) aic(l) = cd(j)
                  if (k .ge. 11 .and. k .le. 20) aic(l) = cf(j)
c                  if (k .ge. 21 .and. k .le. 35) aic(l) = cg(j)
 110           continue
 120        continue
         endif
 130  continue
      
c
c     obtain the natural orbitals of the wavefunction, and the
c     corresponding occupation numbers.
c     for rhf we also require the orbital energies.
c
c ---- read a set of vectors off the dumpfile
c
      if(opg_root())write(iwr,9010)aimpac_sec,iblkdu,yed(numdu)
c
cjmht Returns section k that dumpfile section aimpac_sec (of type m3)
cjmht starts at
      call secget(aimpac_sec,m3,k)
cjmht Pulls m29 words off section k into zcom2(1)
      call rdchr(zcom2(1),m29,k,numdu)
cjmht Pulls mach(8) words off the dumpfule into deig
      call reads(deig,mach(8),numdu)
c
c  new  - number of basis functions
c  nbas - 
c  ncol - number of vectors
c
      if(new.ne.nba)call caserr(
     &     'vector matrix on dumpfile is not square')

      dnel = 0.0d0
      do i = 1, ncol
        dnel = dnel + dpop(i)
      enddo
cjmht: test inapplicable for the harmonic case
      if(.not.oharm.and.new.ne.ncol)then
         if(opg_root())then
           write(iwr,'(1x,
     &  "*** WARNING: vectors written to punchfile have unexpected ",
     &  "length",2i8)')new,ncol
           write(iwr,*)
     &  '             the vectors will be padded with zeros in an ',
     &  'attempt to save the day'
           write(iwr,*)
     &  '             Please proceed with care.'
           write(iwr,*)
     &  '             Electrons counted from occupied orbs = ',dnel
           write(iwr,*)
     &  '             Total number of electrons from input = ',ne
           write(iwr,*)
     &  '             Number of alpha electrons from input = ',na
           write(iwr,*)
     &  '             Number of beta  electrons from input = ',nb
         endif
cc         goto 999
chvd     call caserr('new ne ncol')
chvd     lets try padding the vectors instead of bombing
      endif
c
c ---  test for use of wrong section of rohf..
c      NB warning may occur for mp2/uhf natural orbitals
c
      oneg = .false.
      do 99 i = 1,ncol
         if(dpop(i).lt.-1.0d-10)oneg = .true.
 99    continue

       if(oneg .and. opg_root())then
          write(iwr,*)' WARNING: Some orbital populations are -ve',
     &         ' - check you are not writing'
          write(iwr,*)' an gvb internal vectors section'
          write(iwr,*)'The populations are:'
          write(iwr,100)(dpop(j),j=1,nba)
 100      format(20f8.3)
ccc            call caserr('-ve populations')
       endif
c
c --- read eigenvectors and transform to AO basis
c
      nav = lenwrd()
cjmht Pull exactly mach(9) words of integer data into ilifc
      call readis(ilifc,mach(9)*nav,numdu)
      nw=nba*new
cjmht As above but not exact
      call reads(vec,nw,numdu)
cjmht Transform MO vecs in sym-adapted basis in vec to AO basis
cjmht in vec ilif(q/n) are the offsets
chvd begin
c
c     If the vectors matrix is not square pad it.
c
      if (ncol.lt.new) then
        call vclr(dpop(ncol+1),1,new-ncol)
        call vclr(vec(1,ncol+1),1,(new-ncol)*num)
      endif
c
chvd end
      call tdown(vec,ilifq,vec,ilifq,num)
c
c     ----- write everything out to wfnfil -----
c
      do i = 1, num
         if(dabs(dpop(i)) .gt. 1.0d-10)maxocc=i
      enddo
      if (opg_root()) then
         write(aimpac_unit,8010) (ztit2(i),i=1,10)
         write(aimpac_unit,8020) maxocc,nprim,nat
c
         do 600 i=1,nat
            nucz = isubst(zaname(i))
            znuc = nucz
            write(aimpac_unit,8030) zelem(nucz),i,i,
     &           c(1,i),c(2,i),c(3,i),znuc
 600     continue
c
         write(aimpac_unit,8040) (icent(i),i=1,nprim)
         write(aimpac_unit,8050) (itype(i),i=1,nprim)
         write(aimpac_unit,8060) (expon(i),i=1,nprim)
      end if
c
c     expand the natural orbitals in the ao basis
c     into the primitive representation
c
      do 640 ii = 1,maxocc
         l = 0
         m = 0
         do 630 i = 1,nshell
            kst = kstart(i)
            ken = kst + kng(i) - 1
            jmin = kmin(i)
            jmax = kmax(i)
c           Only write out functions < G
            if ( jmin .le. 21 ) then
               do 620 j = jmin,jmax
                  do 610 k = kst,ken
                     l = l + 1
c
c l indexes expanded primitive in aimpac ordering
c j denotes angular momentum index (f_1 = 11) also in aimpac ordering
c n denotes ao index in gamessuk ordering
c iguk is the smaller ang mom index  (f_1 = 1) in guk ordering
c iguk1 is the full ang mom index  (f_1 = 11) in guk ordering

                     if (jmin.ge.11) then
                        iguk = ioff(j)
                     else
                        iguk = j - jmin + 1
                     endif
                     iguk1 = iguk + jmin - 1
                     n = m + iguk 
                     dum(l) = vec(m+iguk,ii) * aic(l) * fac(iguk1)
c                     write(6,4440)i,j,k,l,iguk,iguk1,n,fac(iguk1)
c 4440                format(7i4,f7.3)
 610              continue
 620           continue
            endif
            m = m + (jmax - jmin) + 1
 630     continue

         if (opg_root()) then
            write(aimpac_unit,8070) ii,dpop(ii),deig(ii)
            write(aimpac_unit,8080) (dum(l),l=1,nprim)
         end if

  640 continue
c
c  SCF energy and virial
c
      call secget(isect(494),m16,iblk34)
      call rdedx(potnuc,m10,iblk34,numdu)

      if (opg_root()) then
         write(aimpac_unit,8090)
         etot2 = potnuc(3)
         ekin = potnuc(6)
c
c Not this tolerance is quite large as there is 1 SCF cycle
c difference between sect 494 and the final vectors, the latter
c are from the n-1th cycle.
c
         if(dabs(etot1-etot2).gt.1.0d-6)then
c
c energy stored on dumpfile section 494 doesn't match 
c that stored with the vectors
c
      write(iwr,*)'WARNING: The total energy stored on the dumpfile'
      write(iwr,*)'SCF section 494 does not match that stored with the'
      write(iwr,*)'nominated vectors section ',aimpac_sec
      write(iwr,*)'The version from the vectors section has been'
      write(iwr,*)'used, and the virial is not available'
      write(iwr,*)'E(section ',aimpac_sec,')',etot1,
     &     ' E(section 494) ',etot2
             etot3 = etot1
             vir2 = 0.0
         else
c
c SCF results are relevant
c
            etot3 = etot2
c
c Compute virial ration if possible
c
            if(dabs(ekin).lt.1.0d-10)then
      write(iwr,*)'WARNING: The kinetic energy was not available'
      write(iwr,*)'for this SCF type so the virial will be missing',
     &     ' from the .wfn file.'
               vir2 = 0.0d0
            else
               vir2 = -(etot2-ekin)/ekin
            endif
         endif
         write(aimpac_unit,8100) ztmp,etot,vir2
      end if
c
      close(unit=aimpac_unit)
      return

 9998 continue

      write(iwr,*)'For this runtype/scftype combination it was not'
      write(iwr,*)'possible to determine a default vectors section'
      write(iwr,*)'for output, please specify it explicitly, e.g.'
      write(iwr,*)'       savefile aimpac section <isect>'
      close(unit=aimpac_unit)
      call gamerr('could not determine vectors section for AIMPAC',
     &     ERR_NO_CODE, ERR_NO_CLASS, ERR_ASYNC, ERR_NO_SYS)
      return
c
 9999 continue
      call gamerr('failed to open AIMPAC wavefunction file for output',
     &     ERR_NO_CODE, ERR_NO_CLASS, ERR_ASYNC, ERR_NO_SYS)

      return
c
 9000 format(/1x,'An aimpac input file is being written to file ',a40)
 9010 format(/1x,'Vectors for AIMPAC were restored from section',i4,
     *' of dumpfile starting at block',i6,' of ',a4)
 8010 format(10a8)
 8020 format ('GAUSSIAN',12X,I3,' MOL ORBITALS',4X,I3,' PRIMITIVES',
     *        6X,I3,' NUCLEI')
 8030 format(A4,I4,4X,'(CENTRE',I3,')',1X,3F12.8,'  CHARGE =',F5.1)
 8040 format('CENTRE ASSIGNMENTS',2X,20I3)
 8050 format('TYPE ASSIGNMENTS',4X,20I3)
 8060 format('EXPONENTS',1X,1P,5E14.7)
 8070 format('MO',I3,21X,'OCC NO = ',F12.7,'  ORB. ENERGY =',F12.7 )
 8080 format(1P,5E16.8)
 8090 format('END DATA')
 8100 format(A8,' ENERGY =',F20.10,'   VIRIAL(-V/T)  =',F13.8)
      end
_IF(cyber205)
      subroutine upack8(iout,iii,iw)
      dimension iii(4),iout(*)
      data mask/x'ff'/
      if(iw.le.170)goto 1
      im=iout(iw-170)
      iii(1)=and(shift(im,8),mask)
      iii(2)=and(shift(im,16),mask)
      iii(3)=and(shift(im,24),mask)
      iii(4)=and(shift(im,32),mask)
      return
1     im=iout(iw)
      iii(1)=and(shift(im,40),mask)
      iii(2)=and(shift(im,48),mask)
      iii(3)=and(shift(im,56),mask)
      iii(4)=and(im,mask)
      return
      end
      subroutine fgett(ic,nword,iunit)
      implicit REAL  (a-h,o-z), integer(i-n)
      integer shiftl
      character *4 yed
INCLUDE(common/sizes)
      dimension ic(1)
      common/bufnew/ibufa(512)
INCLUDE(common/discc)
INCLUDE(common/iofile)
      common/messag/x(10),b(30)
      common/disc/irep,incr,npb,npbsz,npbm1,ipos(maxlfn),
     *nam(maxlfn*2)
      common/discne/
     *ipbpos(maxlfn),mlen(maxlfn),length(maxlfn),iostat(maxlfn),
     *iobuff(maxlfn),itab(maxlfn),
     *istabf(maxbuf),ipribf(maxbuf),junibf(maxbuf),
     *jpbbf(maxbuf),junjpb(maxbuf),
     *ibfbas(maxbuf),igetm(maxbuf),iputm(maxbuf),
     *mbuff,kunkpb,lunx,latmx,lblx,lbfbax,lbuffx,cinpbsz
      data lmask/x'8000000000000000'/
c...
c... synchronous input routine-does not look at checksum
c...
      lun=iunit
      lbl=ipos(lun)
      lpb=(lbl-1)*cinpbsz
      lunlpb=or(shift(lun,32),lpb)
      lat=lpb*npbsz
      latm=lbl-lat
      if(lunlpb.eq.kunkpb)goto 776
      kunkpb=lunlpb
      mbuff=locat1(junjpb,npb,lunlpb)
      if(mbuff)777,888,777
c... physical block not in buffers
888   mbuff=locat1(ipribf,npb,npbm1)
      igetm(mbuff)=0
      lbfbas=ibfbas(mbuff)
      call termbf
      jpbbf(mbuff)=lpb
      junibf(mbuff)=lun
      junjpb(mbuff)=lunlpb
      call revpri
      goto 333
c... physical block in buffer-check for put status
777   call revpri
776   lbfbas=ibfbas(mbuff)
      if(istabf(mbuff))666,444,444
666   mzero=0
      iat=lat
      l=iputm(mbuff)
      m=lbfbas
      call chekwr(lun)
3       if(l.eq.0)goto 4
       nzero=leadz(l)
      iat=iat+nzero
      m=(nzero+mzero)*512+m
      l=shift(l,nzero)
       mzero=lead1(l)
      call chekwr(lun)
      call flushv(lun,ibufa(m+1),mzero,iat)
       l=shiftl(l,mzero)
      iat=iat+mzero
      goto 3
4     if(length(lun).lt.iat)length(lun)=iat
444   l=shiftl(igetm(mbuff),latm-1)
      if(and(l,lmask).eq.lmask)goto 999
c... atmol block missing
333   m=length(lun)-lat-npbsz
      iat=npbsz
      call chekwr(lun)
      if(m)21,20,20
21    iat=iat+m
      if(iat)1,1,20
1     call iofail(yed(lun),1)
20    isil=itab(lun)
      if(ipbpos(lun).ne.lat)call q5setfit('flun=',isil,'bn=',lat)
      call q5read('flun=',isil,'buflen=',iat,'buffer=',
     *ibufa(lbfbas+1),'wait','status=',irep,'errmsg=',x,'errlen=',llll)
      ipbpos(lun)=lat+iat
      if(irep.eq.0.or.irep.eq.1416)goto 87654
      write(iwr,100)x
100   format(1x,10a8)
      call iofail(yed(lun),1)
87654 irep=0
      igetm(mbuff)=mask(iat)
999    ipos(lun)=lbl+1
      if(istabf(mbuff).eq.1)call chekwr(lun)
      m=latm*512+lbfbas
      call fmove(ibufa(m-511),ic,512)
      call upack2(ibufa(m),nword,iblok)
      if(iblok.ne.lbl) nword = -99999
      return
      end
_ENDIF
_IF(ibm,vax)
      subroutine spr2ei(iunit,iblock)
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
INCLUDE(common/discc)
      common/craypk/i205(340),j205(340),k205(340),l205(340)
      common/blkin/g(510),mword,mspace,f(4),ia(4),ja(4),ka(4),la(4)
      write(iwr,100)iblock,yed(iunit)
      n = 0
      if(mword)33,44,33
 44   write(iwr,112)
      go to 404
 33   continue
      call setsto(numlab,0,i205)
      call upak8v(g(num2e+1),i205)
      do 3 m=1,mword
      n=n+1
      f(n)=g(m)
      ia(n)=i205(m)
      ja(n)=j205(m)
      ka(n)=k205(m)
      la(n)=l205(m)
      if(n.lt.4 )goto 3
      write(iwr,101)(ia(n),ja(n),ka(n),la(n),f(n),n=1,4)
      n=0
3     continue
      if(n.ne.0 )write(iwr,101)(ia(m),ja(m),ka(m),la(m),f(m),m=1,n)
      write(iwr,102)mword
404   return
112   format(/3x,'endfile block')
102   format(/' no. of integrals =',i4)
101   format(4(1x,4i3,f16.9))
100   format(/1x,72('*')//45x,'list of block',i6,' from ',a4/
     *45x,27('-')//
     *4(3x,'i',2x,'j',2x,'k',2x,'l',6x,'g',9x)/
     *1x,115('+')/)
      end
      subroutine spr2ep(iunit,iblock)
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
INCLUDE(common/discc)
      common/craypk/ij205(340),kl205(340)
      common/blkin/g(510),mword,mspace,f(4),ia(4),ja(4)
      write(iwr,100)iblock,yed(iunit)
      n = 0
      if(mword)33,44,33
 44   write(iwr,112)
      go to 404
 33   continue
      call upak4v(g(num2ep+1),ij205)
      do 3 m=1,mword
      n=n+1
      f(n)=g(m)
      ia(n)=ij205(m)
      ja(n)=kl205(m)
      if(n.lt.4 )goto 3
      write(iwr,101)(ia(n),ja(n),f(n),n=1,4)
      n=0
3     continue
      if(n.ne.0 )write(iwr,101)(ia(m),ja(m),f(m),m=1,n)
      write(iwr,102)mword
404   return
112   format(/3x,'endfile block')
102   format(/' no. of p-supermatrix elements =',i4)
101   format(4(1x,2i6,f16.9))
100   format(/1x,72('*')//45x,'list of block',i6,' from ',a4/
     *45x,27('-')//
     *4(5x,'ij',4x,'kl',6x,'p',9x)/
     *1x,115('+')/)
      end
      subroutine spr2jk(iunit,iblock)
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
INCLUDE(common/discc)
      common/craypk/ij205(204),kl205(204)
      common/blkin/g(510),mword,mspace,ia(4),ja(4),fp(4),fk(4)
      write(iwr,100)iblock,yed(iunit)
      n = 0
      if(mword)33,44,33
 44   write(iwr,112)
      go to 404
 33   continue
      labss = num2ejk+num2ejk+1
      call upak6v(g(labss),ij205)
      do 3 m=1,mword
      n=n+1
      fp(n)=g(m)
      fk(n)=g(num2ejk+m)
      ia(n)=ij205(m)
      ja(n)=kl205(m)
      if(n.lt.4 )goto 3
      write(iwr,101)(ia(n),ja(n),fp(n),fk(n),n=1,4)
      n=0
3     continue
      if(n.ne.0 )write(iwr,101)(ia(m),ja(m),fp(m),fk(m),m=1,n)
      write(iwr,102)mword
404    return
112   format(/3x,'endfile block')
102   format(/' no. of pk-supermatrix elements =',i4)
101   format(4(1x,2i5,2f10.6))
 100  format(/1x,72('*')//45x,'list of block',i6,' from ',a4/
     *45x,27('-')//
     *4(4x,'ij',3x,'kl',5x,'p', 9x,'k',4x)/
     *1x,123('+')/)
      end
      subroutine upack4(iii,i,kk)
      implicit REAL  (a-h,o-z)
      integer *2 iii
      logical o340
      common/blkin/g(512),isp(2),o340
      dimension iii(*),i(2)
      i(1)=iii(kk    )
        if(o340) then
        i(2)=iii(kk+340)
        else
        i(2)=iii(kk+204)
        endif
      return
      end
      subroutine ucards
      implicit REAL  (a-h,o-z)
      logical logg
      character *4 ai
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
      common/blkin/g(510),mword,mspace,f(2),ia(2),ja(2),ka(2),la(2)
      common/craypk/i205(340),j205(340),k205(340),l205(340)
_IF(linux)
      external fget
_ENDIF
      iseq=0
      n=0
      call setsto(numlab,0,i205)
      iunit = idisc(ai,iblk)
      callinpi(nblk)
      logg=nblk.le. 0
      if(logg)goto 401
       write(iwr,102)ai,iblk
      else
       write(iwr,100)ai,iblk,nblk
      endif
      call  maintp(itype,iblk,nblk,iunit)
      if (itype.ne.1) call caserr('punch only for 2-electron mainfiles')
402   call fget(g,nword,iunit)
      if(nword)33,44,33
44    if(logg)return
      goto 404
   33 call upak8v(g(num2e+1),i205)
      do 3 iw=1,mword
      n=n+ 1
      f(n)=g(iw)
      ia(n)=i205(iw)
      ja(n)=j205(iw)
      ka(n)=k205(iw)
      la(n)=l205(iw)
      if(n.eq. 1)goto 3
      iseq=iseq+1
      write(ipu,101)iseq,n,(ia(k),ja(k),ka(k),la(k),f(k),k=1,n)
      n=0
3     continue
404   nblk=nblk-1
      if(nblk)402,2,402
2     if(n)10120,1,10120
10120 iseq=iseq+1
      write(ipu,101)iseq,n,ia(1),ja(1),ka(1),la(1),f(1)
1     write(iwr,110)iseq
      return
110   format(/i8,' cards punched')
101   format(i8,i2,2(4i4,f17.10))
102   format(//' punch ',a4,'from block',i7,' to endfile block')
100   format(//' punch ',a4,'from block',i7,' for',i7,' blocks')
      end
      subroutine pak8x(i2,ii2)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      common/blkin/gsp(511),nsp(2),ij205(340),kl205(340)
INCLUDE(common/mapper)
      dimension i2(*),ii2(*)
      mword=ii2(341)
      int=1
      do 1 i=1,mword
      iti=i2(int    )
      jtj=i2(int+340)
      ktk=i2(int+680)
      ltl=i2(int+1020)
      ii=max(iti,jtj)
      jj=min(iti,jtj)
      kk=max(ktk,ltl)
      ll=min(ktk,ltl)
      if((iky(ii)+jj).ge.(iky(kk)+ll))go to 6
      ij205(i)=ll+i4096(kk)
      kl205(i)=jj+i4096(ii)
      go to1
   6  ij205(i)=jj+i4096(ii)
      kl205(i)=ll+i4096(kk)
   1  int=int+1
      call pak4v(ij205,ii2)
      return
      end
      subroutine umerge
      implicit REAL  (a-h,o-z)
      logical nogg
      character *4 la2,lend
INCLUDE(common/sizes)
INCLUDE(common/iofile)
      common/blkin/g1(340),gii1(170),mwrd1,mspac1,
     +             ijkl(680)
      common/bufb/g2(340),gii2(170),mwrd2,mspac2
      common/craypk/i1(340),j1(340),k1(340),l1(340)
      common/junk/i2(340),j2(340),k2(340),l2(340),ind(255)
INCLUDE(common/work)
INCLUDE(common/atmblk)
      common/disc/irep(5),nt(maxlfn)
      dimension ii1(2),ii2(2)
      equivalence (ii1(1),gii1(1)),(ii2(1),gii2(1))
      data lend/'end'/
      num2=idisc(la2,iblk2)
      mwrd2=0
      write(iwr,100)la2,iblk2
100   format(//' merge to ',a4,'starting at block',i7)
      iupp=iblk2
      call setsto(1360,0,i1)
      call setsto(255,-2000,ind)
c...   read orbital renumbering list
101   call input
      call inpa4(la2)
      if( la2.eq.lend)goto 103
      jrec=0
      call inpi(i)
      call inpi(j)
      call inpi(k)
      ji=j-i
      l=k+ji
      if(j.lt.i.or.i.le.0 .or.j.gt.255 .or.k.le.0 .or.l.gt.255 )call
     * caserr('invalid re-indexing parameter in merge')
      write(iwr,104)i,j,k,l
104    format(/' old basis functions',i4,' to',i4,' renumbered',i4,' to'
     *,i4)
      ji=ji+1
      if(nocat1(ind(i),ji,-2000).ne.0)call caserr
     * ('invalid re-indexing parameter in merge')
      call ibasgn(ji,k,1,ind(i))
      goto 101
103    do 300 i=2,255
      k=ind(i)
        if(k)300,302,302
302   if(locat1(ind,i-1,k).ne.0)call caserr
     * ('invalid re-indexing parameter in merge')
300    continue
c...   process input file
       write(iwr,108)
108   format(//7x,'input file'//6x,'starting terminal'/
     *' lfn     block    block')
106   call input
      call inpa4(la2)
      if( la2.eq.lend)goto 107
      jrec=0
      num1=idisc(la2,iblk1)
      nogg=num1.eq.num2
      call inpi(nblk)
      write(iwr,400)la2,iblk1,nblk
400   format(1x,a4,2i9)
      nblk=iblk1-nblk
401   if(nblk)707,106,707
707   if(nogg.and.iblk1.ge.iblk2.and.iblk1.lt.iupp)call
     * caserr('conflict between input and output disk areas')
      call search(iblk1,num1)
      call fget(g1,nword,num1)
      if(nword)7600,106,7600
 7600 continue
      call upak8v(ii1,i1)
      call igthr(mwrd1,i1,i1,ind)
      call igthr(mwrd1,j1,j1,ind)
      call igthr(mwrd1,k1,k1,ind)
      call igthr(mwrd1,l1,l1,ind)
      do 200 kk=1,mwrd1
      mi=i1(kk)
      mj=j1(kk)
      mk=k1(kk)
      ml=l1(kk)
      if(mi+mj+mk+ml)200,10000,10000
10000 mwrd2=mwrd2+1
      g2(mwrd2)=g1(kk)
      i2(mwrd2)=mi
      j2(mwrd2)=mj
      k2(mwrd2)=mk
      l2(mwrd2)=ml
      if(mwrd2.lt.340)goto 200
      call search(iupp,num2)
      call pak8x(i2,ii2)
      call put(g2,511,num2)
      mwrd2=0
      iupp=iupp+1
200   continue
      iblk1=iblk1+1
      nblk=nblk+1
      goto 401
 107  call search(iupp,num2)
      if(mwrd2.ne.0) then
       call pak8x(i2,ii2)
       call put(g2,511,num2)
      endif
      call put(g2,0,num2)
      return
      end
_ENDIF
_IF(fps)
      subroutine fgett(ic,nword,iunit)
      implicit REAL  (a-h,o-z)
      word ibufa,igetm,iputm,kunkpb,junjpb
      word lunlpb,mask,mask0,l,lmask
c
c...  synvhronous no critical input
c...  nword = -99999 suggests checksum error
c
_IF(vaxh)
$insert 'sizes.for'
_ENDIF
_IF(vmh)
$insert sizes.for
_ENDIF
      dimension ic(*)
      common/bufnew/ibufa(512)
      common/disc/irep,incr,npb,npbsz,npbm1,ipos(maxlfn),
     *nam(maxlfn)
      common/discne/
     *mlen(maxlfn),length(maxlfn),iostat(maxlfn),
     *iobuff(maxlfn),itab(maxlfn),nstrip,
     *istabf(maxbuf+1),ipribf(maxbuf),junibf(maxbuf),
     *jpbbf(maxbuf),junjpb(maxbuf),
     *ibfbas(maxbuf),igetm(maxbuf),iputm(maxbuf),
     *mbuff,kunkpb,lunx,latmx,lblx,lbfbax,lbuffx
      common/maskc/mask(64)
      data lmask/z'8000000000000000'/
      data mask0/z'0'/
      lun=iunit
      lbl=ipos(lun)
      lpb=(lbl-1)/npbsz
      lunlpb=insert(lpb,0,32,lun)
      lat=lpb*npbsz
      latm=lbl-lat
      if(lunlpb.eq.kunkpb)goto 776
      kunkpb=lunlpb
      mbuff=locatz(junjpb,npb,lunlpb)
      if(mbuff)777,888,777
  888 mbuff=locat1(ipribf,npb,npbm1)
      igetm(mbuff)=mask0
      lbfbas=ibfbas(mbuff)
      call termbf
      jpbbf(mbuff)=lpb
      junibf(mbuff)=lun
      junjpb(mbuff)=lunlpb
      call revpri
      goto 333
  777 call revpri
  776 lbfbas=ibfbas(mbuff)
      if(istabf(mbuff))666,444,444
  666 mzero=0
      iat=lat
      l=iputm(mbuff)
      m=lbfbas
      call chekwr(lun)
      istabf(iobuff(lun))=0
  3   if(l.eq.mask0)goto 4
       nzero=leadz(l)
      iat=iat+nzero
      m=(nzero+mzero)*512+m
      l=shift(l,nzero)
       mzero=leadz(compl(l))
      call chekwr(lun)
      call flushv(lun,ibufa(m+1),mzero,iat)
       l=shift(l,mzero)
      iat=iat+mzero
      goto 3
  4   if(length(lun).lt.iat)length(lun)=iat
      iobuff(lun)=mbuff
      istabf(mbuff)=2
  444 l=shift(igetm(mbuff),latm-1)
      if(and(l,lmask).eq.lmask)goto 999
  333 m=length(lun)-lat-npbsz
      iat=npbsz
       istabf(iobuff(lun))=0
      call chekwr(lun)
      if(m)21,20,20
  21  iat=iat+m
      if(iat)1,1,20
  1   call iofail(lun,1)
  20  call fillv(lun,ibufa(lbfbas+1),iat,lat)
      iobuff(lun)=mbuff
      istabf(mbuff)=1
      igetm(mbuff)=mask(iat)
  999  ipos(lun)=lbl+1
      if(istabf(mbuff).eq.1)call chekwr(lun)
      m=latm*512+lbfbas
      call vmov(ibufa(m-511),1,ic,1,512)
      nword=extract(ibufa(m),0,32)
      iblok=extract(ibufa(m),32,32)
      if(iblok.ne.lbl) nword = -99999 
      return
      end
      subroutine upack4(iii,i,kk)
      implicit REAL  (a-h,p-w),integer  (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      word iii
      dimension i(*),iii(*)
      nw=(kk-1)/2+1
      if(mod(kk,2).eq.0)then
        iw=32
      else
        iw=0
      endif
      i(1)=extract(iii(nw),iw,   16)
      i(2)=extract(iii(nw),iw+16,16)
       return
      end
      subroutine pak2v(ijkl,iii)
      word iii,ijkl
      dimension iii(1),ijkl(1)
      int=1
      do 1 i=1,85
      iii(i)=insert(
     *       insert(extract(ijkl(int+3),32,16),32,16,
     *              extract(ijkl(int+2),32,16)), 0,32,
     *       insert(extract(ijkl(int+1),32,16),32,16,
     *              extract(ijkl(int),32,16) ) )
   1  int=int+4
      int=1
      do 2 i=86,170
      iii(i)=insert(
     *       insert(extract(ijkl(int+3),48,16),32,16,
     *              extract(ijkl(int+2),48,16)), 0,32,
     *       insert(extract(ijkl(int+1),48,16),32,16,
     *              extract(ijkl(int),48,16) ) )
   2  int=int+4
      return
      end
      subroutine upak2v(iii,ijkl)
      word iii,ijkl
      dimension iii(1),ijkl(1)
      int=1
      do 1 i=1,85
      ijkl(int  ) = insert ( extract(iii(i+85), 0,16), 32, 16,
     *                       extract(iii(i   ), 0,16) )
      ijkl(int+1) = insert ( extract(iii(i+85),16,16), 32, 16,
     *                       extract(iii(i   ),16,16) )
      ijkl(int+2) = insert ( extract(iii(i+85),32,16), 32, 16,
     *                       extract(iii(i   ),32,16) )
      ijkl(int+3) = insert ( extract(iii(i+85),48,16), 32, 16,
     *                       extract(iii(i   ),48,16) )
   1  int=int+4
      return
      end
      subroutine upack8(iii,i,kk)
      implicit REAL  (a-h,o-z)
      word iii
      common/tran/mword(340),iword(340)
      dimension iii(*),i(*)
      mw=mword(kk)
      iw=iword(kk)
      i(1)=extract(iii(mw   ),iw   ,8)
      i(2)=extract(iii(mw   ),iw+8 ,8)
      i(3)=extract(iii(mw+85),iw   ,8)
      i(4)=extract(iii(mw+85),iw+8, 8)
      return
      end
      subroutine pak8x(i2,ii2)
      implicit REAL  (a-h,o-z)
      word ii2
INCLUDE(common/sizes)
      common/blkin/gsp(511),nsp(2),
     *             ij205(340),kl205(340)
INCLUDE(common/mapper)
      dimension i2(*),ii2(*)
      mword=ii2(171)
      int=1
      int4=1
      do 1 i=1,mword
      iti=i2(int    )
      jtj=i2(int+340)
      ktk=i2(int+680)
      ltl=i2(int+1020)
      ii=max(iti,jtj)
      jj=min(iti,jtj)
      kk=max(ktk,ltl)
      ll=min(ktk,ltl)
      if((iky(ii)+jj).ge.(iky(kk)+ll))go to 6
      ij205(i)=ll+i4096(kk)
      kl205(i)=jj+i4096(ii)
      go to1
   6  ij205(i)=jj+i4096(ii)
      kl205(i)=ll+i4096(kk)
   1  int=int+1
      call pak4v(ij205,ii2)
      return
      end
_ENDIF
c
c ******************************************************
c ******************************************************
c             =   basis set optimization =
c ******************************************************
c ******************************************************
c
      subroutine mainbs(core,step,tol,prbas)
      implicit none
      REAL fetot,fmin,xmin,tol,step,core(*)
      logical prbas
      logical oresti,ostop,ostopr
      integer idum,CD_init,i
c
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/coptbas)
INCLUDE(common/iofile)
INCLUDE(common/restar)
c
INCLUDE(common/runlab)
c
c===
       call input
c     print *,'in start 1:oresti,ostop,ostopr'
c    +                  oresti,ostop,ostopr
c
       oresti = .false.
       ostop  = .false.
       ostopr = .false.
c
c     print *,'in start 2:oresti,ostop,ostopr'
c    +                  oresti,ostop,ostopr
       call start(core,oresti,ostop,ostopr)
c
       call mogues(core)
c
       if (.not.prbas) nprint = -5
       write(iwr,85)
c=============================================================
c
      print *,'--- zaname',(zaname(i),i=1,10)
c
       write(iwr,25)'kstart',('kstart(',i,')=',kstart(i),i=1,50)
       write(iwr,25)'katom',('katom(',i,')=',katom(i),i=1,50)
       write(iwr,25)'ktype',('ktype(',i,')=',ktype(i),i=1,99)      
       write(iwr,25)'kng   ',('kng(  ',i,')=',kng(i),i=1,99)      
       write(iwr,25)'kloc  ',('kloc( ',i,')=',kloc(i),i=1,99)      
       write(iwr,25)'kmin  ',('kmin( ',i,')=',kmin(i),i=1,99)      
       write(iwr,25)'kmax  ',('kmax( ',i,')=',kmax(i),i=1,99)      


 25    format(/,3('+'),a6,//(a6,i2,a2,i4),1x)
c=============================================================
c
c calculate beta, which is the parameter we want to optimise
c
       ipoint=0
       tod_bta=ex(outexp)/ex(outexp+1)
c      write(iwr,90)tod_bta
       tod_ax = tod_bta
c
       call bracket(step,core)
c
       write (iwr,100)
       write (iwr,200) tod_ax,tod_bx,tod_cx
       write (iwr,300) tod_fa,tod_fb,tod_fc
       write (iwr,401)
 80    format(72('-'))
 85    format(///,40x,'=== COMMENCE BASIS SET OPTIMIZATION ==='/)
 90    format(2x,'initial exponent ratio beta',f9.6,/)
 100   format(///33x,'--- minimum bracketed ---'/)
 200   format(33x,'ax bx cx  ',f9.6,
     +      2(/33x,10x,f9.6)/)
 300   format(33x,'fa fb fc  ',f12.7,
     +      2(/33x,10x,f12.7)/)
 401   format(33x,25('-'),/)
 402   format(33x,30('-'),/)
c
       call gsect(fmin,xmin,tol,core)
c
       write (iwr,500)
       write (iwr,600) xmin,tol,fmin,(i,ex(i),i=outexp+1,outexp+nexp)
       write (iwr,402)
 500   format(///33x,'--- optimization converged ---'/)
 600   format(36x,'min beta',5x,f9.6,/
     +        36x,'tol in beta',2x,f9.6,/
     +        36x,'min energy',3x,f12.7,/
     +        36x,'final exponents ',/,
     +        33x,30('-'),/,
     +        (36x,1x,i3,2x,d25.16),1x)
c
      return
      end
c
      subroutine bracket(step,core)
       implicit none
       REAL fetot,step,dzero,core(*),bbd
c
INCLUDE(common/coptbas)
INCLUDE(common/iofile)
c
       parameter(dzero=0.0d0)
c
c
       tod_bx = tod_ax + step
       tod_fa = fetot(tod_ax,core) 
       tod_fb = fetot(tod_bx,core)
       if(tod_fa.eq.tod_fb) 
     1  call caserr('accidental stationary point reached')
c
       if (tod_fa.lt.tod_fb) then
c
c reverse step and double the step
c
          step = - step
c
 10       tod_cx = tod_bx 
          tod_fc = tod_fb
          tod_bx = tod_ax
          tod_fb = tod_fa
          tod_ax = tod_bx + step
c
          tod_fa = fetot(tod_ax,core)
          if (tod_fa.gt.tod_fb) then
              plusmin = .false.
              return
          else
              go to 10
          end if
       end if
c       
 20    tod_cx = tod_bx + step
       tod_fc = fetot(tod_cx,core)
       if (tod_fc.gt.tod_fb) then
           plusmin = .true.
           return
       else
           tod_ax = tod_bx
           tod_fa = tod_fb
           tod_bx = tod_cx
           tod_fb = tod_fc
           go to 20
       end if
       end
       subroutine gsect(fmin,xmin,tol,core)
       implicit none
       REAL fetot,xmin,fmin,tol,R,C,core(*)
c
INCLUDE(common/coptbas)
c
        PARAMETER (R=.61803399,C=1.-R)
        REAL f1,f2,x0,x1,x2,x3
        x0=tod_ax
        x3=tod_cx
        if(plusmin)then
           x1=tod_bx
           x2=tod_bx+C*(tod_cx-tod_bx)
           f1=tod_fb
           f2=fetot(x2,core)
        else
           x2=tod_bx
           x1=tod_bx-C*(tod_bx-tod_ax)
           f1=fetot(x1,core)
           f2=tod_fb
        endif
c
 30     if(abs(x3-x0).gt.tol*(abs(x1)+abs(x2)))then 
            if(f2.lt.f1)then
                x0=x1
                x1=x2
                x2=R*x1+C*x3
                f1=f2
                f2=fetot(x2,core)
            else
                x3=x2
                x2=x1
                x1=R*x2+C*x0
                f2=f1
                f1=fetot(x1,core)
            endif
         go to 30
         end if
         if(f1.lt.f2)then
             fmin=f1
             xmin=x1
         else
             fmin=f2
             xmin=x2
         endif
         return
         END
c
       REAL function fetot(x,core)
       REAL x,core(*)
       REAL enuc,etotal
c local integers
       integer i,j,p
c
INCLUDE(common/ccpdft.hf77)
INCLUDE(common/restar)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/coptbas)
INCLUDE(common/iofile)
        common/scfblk/enuc,etotal
INCLUDE(common/dump3)
       logical opg_root
       integer idum
c
       call secdrp(ionsec)
c
       ipoint=ipoint+1
c
c      write(iwr,100)
       write(iwr,200)ipoint
       write(iwr,350)x
c
       write(iwr,300)
       write(iwr,50)
cc
       do j=0,juniq-1
          p = outexp + j*tnprim
          do i=1,nexp
             p = p + 1
             ex(p)=ex(p-1)/x
             write(iwr,400)p,ex(p)
          end do
       end do
       write(iwr,50)
c
c      write(iwr,'(/,"--- call to hfscf",/)')
c
_IF(ccpdft)
c  
c initialise CCP1 DFT module
c  
       idum = CD_init(core,iwr)
       if (ipoint.eq.1.and.opg_root().and.CD_active()) then
          call CD_print_joboptions(iwr)
       endif
_ENDIF
c
       call hfscf(core)
       fetot = etotal
c
c      write(iwr,500) fetot
c      write(iwr,100)
c
  50   format(34('-'))
 100   format(/72('-')/)
 200   format(///36x,'--- point',1x,i4,' ---',//)
 350   format(2x,'exponent ratio beta',2x,f9.6/)
 300   format(2x,'new exponents')
 400      format(2x,i3,3x,d25.16)
 500   format(2x,'total energy',2x,f12.7,/)
      return
      end
      subroutine ver_server(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/server.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
cc
cc end of single parameter optimization
cc
cccccccccccccccccccccccccccccccccccccccccccccccc
c  MULTI DIMENTIONAL BASIS OPTIMIZATION
cccccccccccccccccccccccccccccccccccccccccccccccc
       subroutine mainbm(dltbm,xtol,prbas,ofull,core)
       implicit none
       integer idum,CD_init
       integer psize,pstr,maxit
       parameter(psize=20,pstr=210,maxit=50)
       integer nangl(20),i,j,k
       logical oresti,ostop,ostopr,prbas,ofull
       logical term2,orst
       REAL core(*)
       REAL maxg,averg,maxxt,averxt,xtol
       REAL etot,etold,fetotm,dltbm,dftest,ddot,berr(psize)
       REAL p(psize),pold(psize),xt(psize)
       REAL grad(psize),gold(psize),gamm(psize),hinv(pstr)
INCLUDE(common/coptbm)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/iofile)
INCLUDE(common/restar)
c
cc initialization
       call input
       oresti = .false.
       ostop  = .false.
       ostopr = .false.
       call start(core,oresti,ostop,ostopr)
       call mogues(core)
       if (.not.prbas) nprint = -5
       orst = .false.
       term2 = .false.
       ofullf = ofull
c
       call sortb(ntot,angl,label)
       if(ntot.gt.20) call caserr('number of parameters bigger that 20')

c
       write(iwr,10)
 10    format(/30x,'=== COMMENCE BASIS SET OPTIMIZATION ===',
     + //2x,98("="),/2x,"= Please ensure sufficient convergence in", 
     +" energy (thresh 7) and integral accuracy (intgral high) =",
     + /2x,98("="),/1x)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      if(dltbm.gt.1.d-2) write(iwr,'(/" !!! WARNING: DELT bigger",
     +" than 0.01 causes insufficient gradient accuracy !!!",/1x)')
      if(dltbm.lt.1.d-3) write(iwr,'(/" !!! WARNING: DELT smaller",
     +" than 0.001 might cause numberical problems",
     +" or insufficient gradient accuracy !!!",/1x)')
      if(xtol.lt.1.d-4)  write(iwr,'(/" !!! WARNING:",
     +" XTOL smaller than 0.000225 is not reasonable",
     +" with numerical gradient!!!",/1x)')
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
cc initialize p()
      if (ofullf) then
         write(iwr,'(/" !!! WARNING: FULL option", 
     +       " is operational ONLY for atoms !!!",//1x)')
         call initpf(nshbas,ntot,p)
      else
         call initp(ntot,p)
      end if
c
c initialize hessian inverse
 103  continue
      do 20 i=1,(ntot*ntot+ntot)/2
 20      hinv(i)=0.d0
      do 21 i=1,ntot
         k=(i*i+i)/2
 21      hinv(k)=1.d0
c
c total energy at p()
      ipm = 0
      etot = fetotm(p,core)
c
c  gradient at p()
      call dgen(ntot,p,grad,gold,etot,dltbm,core,prbas)
c
c newton step (xt = -hinv*grad)
      call matvecb(ntot,xt,-1.d0,hinv,grad)
      call convch(ntot,xt,grad,maxxt,averxt,maxg,averg,xtol)
      do 22 i=1,ntot
 22      if(abs(grad(i)).lt.min(4.d0*xtol/9.d0,averg)) xt(i) = 0.d0
      call newp(ntot,xt,p)
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c     write(iwr,110)
c110  format(///20x,3x,'===      ITERATION SECTION      ===',//)
 101  ipm = ipm + 1
c     write(iwr,120)ipm
c120  format(/20x,3x,6x,'---   point',1x,i2,2x,'   ---',/)
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      etold = etot
      etot = fetotm(p,core)
      dftest=ddot(ntot,grad,1,xt,1)
      dftest=(etot-etold)/dftest
c
c check on energy convergence
      write(iwr,'(//,3x,"total energy",2x,f15.7)')etot
      write(iwr,100)etot-etold,dftest
 100  format(3x,'energy low.',3x,f15.7,
     +      /3x,'step test  ',3x,f15.7)
      if (dftest.lt.0.01d0) then
         write(iwr,'(//5x," !!! LARGE STEP!",
     +                  /5x," REVERSE AND RESTART ",//1x)')
         do 120 i=1,ntot
 120        xt(i)=-0.9d0*xt(i)
         if(ofullf) call intbet(nshbas,p)
         call newp(ntot,xt,p)
         go to 103
      end if
c
c generate new gradient
      call dcopy(ntot,grad,1,gold,1)
      call dgen(ntot,p,grad,gold,etot,dltbm,core,prbas)
      call convch(ntot,xt,grad,maxxt,averxt,maxg,averg,xtol)
      if(maxxt.lt.xtol.and.
     +    maxg.lt.(4.d0*xtol/9d0).and.
     +    averxt.lt.(2.d0*xtol/3.d0).and.
     +     averg.lt.(8.d0*xtol/27.d0)) term2 = .true.
      if(term2.or.ipm.eq.maxit) go to 102
c
c update hessian inverse
      do 130 i=1,ntot
 130     gamm(i)=grad(i)-gold(i) 
      call hupdat(ntot,xt,gamm,hinv)
c
c newton step
      call matvecb(ntot,xt,-1.d0,hinv,grad)
      orst=.false. 
      do 140 i=1,ntot
         if(abs(xt(i)).gt.0.4d0) then
            xt(i)= -grad(i)
            orst= .true.
         endif
 140     if(abs(grad(i)).lt.min(4.d0*xtol/9.d0,averg)) xt(i)=0.d0
      if(ofullf) call intbet(nshbas,p)
      call newp(ntot,xt,p)
      if(orst) then
         write(iwr,'(//5x," !!! LARGE STEP!",
     +"  INSUFFICINET GRADIENT ACCURACY OR HESSIAN (NEARLY) SINGULAR!",
     +/5x," !!! RESTARTING ... ")')
         go to 103
      endif
      go to 101
c
CCC ===  END ITERATION SECTION  === CCC
c
 102  continue
c
c   final prints section
      do 150 i=1,ntot
 150     grad(i) = 4.d0*xtol/9.d0
      call matvecb(ntot,berr,1.d0,hinv,grad)
      if(ipm.lt.maxit) write(iwr,50)
      if(ipm.eq.maxit) write(iwr,51)maxit
      if(.not.ofullf) write(iwr,60) (i,p(i),berr(i),i=1,ntot)
      call exppr(ntot,berr)
      write(iwr,70)xtol,etot,etot-etold
      write(iwr,80)
 50   format(////20x,'--- optimization converged ---',/)
 51   format(////30x,'--- no convergence ---',
     +       /20x,'maximal number of',i4,' iterations reached')
 60   format(//20x,2x,'final exponent ratios',10x,'error',
     +      //(20x,3x,i2,2x,f12.7,9x,f12.7),1x)
 70   format(/20x,2x,'xtol    ',1x,f15.7,
     +       /20x,2x,'tot. en.',1x,f15.7,
     +       /20x,2x,'en.conv.',1x,f15.7,/)
 80   format(20x,30('-'))
      return
      end
ccc
       REAL function fetotm(pex,core) 
       implicit none
       REAL pex(*),core(*)
       REAL enuc,etotal
       integer i,j,k,p
INCLUDE(common/sortbeta)
INCLUDE(common/coptbm)
INCLUDE(common/restar)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/iofile)
       common/scfblk/enuc,etotal
INCLUDE(common/dump3)
INCLUDE(common/infoa)
       logical opg_root,CD_active
       integer idum,CD_init
c
       call secdrp(ionsec)
c
       write(iwr,200)ipm
       write(iwr,300)
       write(iwr,50)
c
cc  modify the exp. corresponding to  
cc  the current beta()
c
       if(ofullf) go to 10
       do i=1,ntot
          do j=1,nexp(i)
             p = lexp(i,j)
             ex(p)=ex(p-1)/pex(i)
             write(iwr,400)p,ex(p)
          end do
       end do
       go to 20
c
 10    continue
       k = 0
       do i=1,ntot
          do j=1,nexp(i)
             k = k + 1
             p = lexp(i,j)
             ex(p)=inlexp(k)*pex(k)
             write(iwr,400)p,ex(p)
          end do
       end do
       go to 20
c
       write(iwr,50)
 20    continue
c
_IF(ccpdft)
c initialise CCP1 DFT module
       idum = CD_init(core,iwr)
       if (ipm.eq.0.and.opg_root().and.CD_active()) then
          call CD_print_joboptions(iwr)
       endif
_ENDIF
c
       call hfscf(core)
       fetotm = etotal
c
  50   format(34('-'))
 100   format(/72('-')/)
 200   format(///36x,'=== POINT',1x,i4,' ===',//)
 350   format(2x,'exponent ratio beta',2x,f9.6/)
 300   format(2x,'new exponents')
 400   format(2x,i3,3x,d25.16)
 500   format(2x,'total energy',2x,f12.7,/)
      return
      end
c
       REAL function fgrgen(pex,core,prbas) 
       implicit none
       REAL pex(*),core(*)
       REAL enuc,etotal
       integer i,j,k,p
INCLUDE(common/sortbeta)
INCLUDE(common/coptbm)
c
INCLUDE(common/restar)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/iofile)
       common/scfblk/enuc,etotal
INCLUDE(common/dump3)
INCLUDE(common/infoa)
       logical opg_root,prbas
       integer idum,CD_init
c
       call secdrp(ionsec)
c
       if (prbas) write(iwr,300)
       if (prbas) write(iwr,50)
c
cc  modify the exp. corresponding to the current beta()
       if(ofullf) go to 10
       do i=1,ntot
          do j=1,nexp(i)
             p = lexp(i,j)
             ex(p)=ex(p-1)/pex(i)
             if (prbas) write(iwr,400)p,ex(p)
          end do
       end do
       go to 20
c
 10    continue
       k = 0
       do i=1,ntot
          do j=1,nexp(i)
             k = k + 1
             p = lexp(i,j)
             ex(p)=inlexp(k)*pex(k)
             if (prbas) write(iwr,400)p,ex(p)
          end do
       end do
c
 20    continue
       if (prbas) write(iwr,50)
c
_IF(ccpdft)
c initialise CCP1 DFT module
       idum = CD_init(core,iwr)
_ENDIF
c
       call hfscf(core)
       fgrgen = etotal
c
  50   format(34('-'))
 100   format(/72('-')/)
 200   format(///36x,'--- point',1x,i4,' ---',//)
 300   format(//2x,'exponents in grad.gen.')
 350   format(2x,'exponent ratio beta',2x,f9.6/)
 400      format(2x,i3,3x,d25.16)
 500   format(2x,'total energy',2x,f12.7,/)
      return
      end
ccc
      subroutine newp(m,xt,x)
       implicit none
       integer j,m
       REAL xt(m),x(m)
INCLUDE(common/iofile)
c
       write(iwr,'(//6x,"--- Newton step in beta")')
       write(iwr,30)
 30    format(/2x,8x,'old beta',10x,'new beta',/)
       do 10 j=1,m
          write(iwr,20)j,x(j),x(j)+xt(j)
 10       x(j) = x(j) + xt(j)
 20       format(2x,i2,3x,2(f12.7,5x))
       return
       end
ccc
      subroutine hupdat(n,delta,gamm,h)
       implicit none
       integer i,j,k,l,n
       REAL  delta(n),gamm(n),h(*)
       REAL  hgamm(n)
ccccccccccccccccccccccccccccccc
       REAL  t1,t2,ddot
c  t1 = deltaT*gamma
c  t2 = gammaT*ho*gamma
ccccccccccccccccccccccccccccccc
INCLUDE(common/iofile)
       t1=ddot(n,delta,1,gamm,1)
       call matvecb(n,hgamm,1.d0,h,gamm)
       t2 = ddot(n,gamm,1,hgamm,1)
ccccccccccccccccccccccccccccccccccccccccccccccc
       if(t1.ge.t2) then
ccccccccccccccccccccccccccccccccccccccccccccccc
c if (t1.ge.t2) => formula (5)
c else => formula (1)
c see: (The Computer Journal Vol. 13, No. 3, 1970, 317)
ccccccccccccccccccccccccccccccccccccccccccccccc
c         write(iwr,'(//," === H updated with formula (5) === ",//1x)')
          t2 = (1.d0 + t2/t1)/t1
          t1 = 1.d0/t1
          k=0
          do 105 i=1,n
          do 105 j=1,i
             k=k+1
 105         h(k) = h(k) -
     +                t1*(delta(i)*hgamm(j)+hgamm(i)*delta(j)) +
     +                t2*delta(i)*delta(j)
       else
c         write(iwr,'(//" === H updated with formula (1) === ",//1x)')
          t1 = 1.d0/t1
          t2 = 1.d0/t2
          k=0
          do 101 i=1,n
          do 101 j=1,i
             k=k+1
 101         h(k)=h(k)+t1*delta(i)*delta(j)-t2*hgamm(i)*hgamm(j)
       endif
       return
       end
ccc
      subroutine matvecb(n,x,co,h,g)
c...   matvec renamed tp matvecb (basis) due to clash with drf (jvl)
       implicit none
       integer i,j,k,l,n
       REAL ht(n,n),g(n),x(n),h(*),co
INCLUDE(common/iofile)
c
        k=0
        do 10 i=1,n
        do 10 j=1,i
           k=k+1
           ht(i,j)=h(k)
 10        ht(j,i)=h(k)
c
        if(co.eq.-1d0) then
        write(iwr,'(/,30("="),
     +        "   Hessian inverse   ",30("="),//1x)')
        do 11 i=1,n,7
           write(iwr,'(10x,7(i4,10x))')(j,j=i,min(i+6,n))
        do 12 k=1,n
 12        write(iwr,'(i2,2x,7f14.8)')k,(ht(k,l),l=i,min(i+6,n))
 11     continue
        write(iwr,'(/81("="),/1x)')
        endif
c
        do 15 i=1,n
           x(i)=0.0d0
        do 15 j=1,n
 15        x(i)=x(i)+co*ht(j,i)*g(j)
       return
       end
ccc
      subroutine sortb(nt,agl,lbel)
       implicit none
       integer nt,nangl(10),minexp(10)
       integer ib,lb,lz,i,j,temp
       character*8 lbel(10),angtag(4)
       character*4 agl(10)
INCLUDE(common/sortbeta)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/iofile)
INCLUDE(common/runlab)
INCLUDE(common/infoa)
       data angtag/'s   ','p   ','d   ','f   '/
       data nangl/10*0/
       data minexp/10*0/
c
c=============================================================
c     print *,'zaname',(zaname(i),i=1,10)
c     print *,'ztag',(ztag(i),i=1,10)
c      write(iwr,25)'kstar',('kstar(',i,')=',kstart(i),i=1,50)
c      write(iwr,25)'katom',('katom(',i,')=',katom(i),i=1,50)
c      write(iwr,25)'ktype',('ktype(',i,')=',ktype(i),i=1,99)      
c      write(iwr,25)'kng   ',('kng(  ',i,')=',kng(i),i=1,99)      
c      write(iwr,25)'kloc  ',('kloc( ',i,')=',kloc(i),i=1,99)      
c      write(iwr,25)'kmin  ',('kmin( ',i,')=',kmin(i),i=1,99)      
c      write(iwr,25)'kmax  ',('kmax( ',i,')=',kmax(i),i=1,99)      
c25    format(/,3('+'),a6,//(a6,i2,a2,i4),1x)
c=============================================================
c
       do i=1,10
          nexp(i) = 0
       end do
       do i=1,10
         do j=1,10
          lexp(j,i) = 0
         end do
       end do
c
c sorting out the angular momentum
      do i=1,nt
         do j=1,4
            if(agl(i).eq.angtag(j)) then
               nangl(i)=j
             end if
         end do
      end do
c
      do lz=1,nat
         do ib=1,nt
            if (lbel(ib).eq.zaname(lz)) then
               do lb=1,nshell 
c
c atom number and angular momentum sreening
                  if (katom(lb).eq.lz.
     +            and.ktype(lb).eq.nangl(ib).
     +            and.kng(lb).eq.1) then
                     nexp(ib) = nexp(ib) + 1
                     lexp(ib,nexp(ib)) = kstart(lb)
                  end if   
               end do
            end if
         end do
      end do
c
c final screening for equal elements in lexp()
       do ib=1,nt
          do lb=1,nexp(ib)
             do lz=lb+1,nexp(ib)
 25             if (lexp(ib,lb).eq.lexp(ib,lz).
     +          and.lexp(ib,lb).ne.0) then
                   do i=lz,nexp(ib)
                      lexp(ib,i) = lexp(ib,i+1)
                   end do
                   minexp(ib) = minexp(ib) + 1
                   go to 25
                end if
              end do
          end do
          nexp(ib) = nexp(ib) - minexp(ib)
       end do
c      print *,'-- nexp ',(nexp(i),i=1,nt)
c      print *,'-- lexp ',((lexp(i,j),j=1,10),i=1,nt)
      return
      end
c
      subroutine initp(nt,p0)
       implicit none
       REAL p0(*)
INCLUDE(common/iofile)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
       integer i,j,p,nt
INCLUDE(common/sortbeta)
c
       write(iwr,401)
       do i=1,nt
          p0(i) = 0.0d0
          do j=1,nexp(i)
             p = lexp(i,j)
             p0(i)= p0(i) + ex(p-1)/ex(p)
             write(iwr,402)p,ex(p-1)/ex(p)
          end do
          p0(i) = p0(i)/nexp(i)
       end do
 401   format(/3x,'initial exponent ratios',/28('-'))
 402   format(2x,i3,3x,d25.16)
      return
      end
ccc
      subroutine intbet(nsh,p0)
       implicit none
       REAL p0(*)
INCLUDE(common/iofile)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/sortbeta)
       integer i,j,k,m,nsh
c
      k = 0
      do i=1,nsh
         do j=1,nexp(i)
            k = k + 1
            m = lexp(i,j)
            p0(k)= 1.0d0
            inlexp(k) = ex(m)
         end do
      end do
      return
      end
ccc
      subroutine initpf(nsh,nt,p0)
       implicit none
       REAL p0(*)
INCLUDE(common/iofile)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/sortbeta)
       integer i,j,k,p,nsh,nt
c
       nsh = nt
       nt = 0
       k = 0
       write(iwr,401)
       do i=1,nsh
          do j=1,nexp(i)
             nt = nt + 1
             k = k + 1
             p = lexp(i,j)
             p0(k)= 1.0d0
             inlexp(k) = ex(p)
             write(iwr,402)p,inlexp(k)
          end do
       end do
 401   format(/3x,'initial exponents ',/28('-'))
 402   format(2x,i3,3x,d25.16)
      return
      end
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
       subroutine dgen(n,x0,g,go,etot,dlt,core,prbas)
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c n - dimention; x0 - central point; g - gradient;
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
        implicit none
        integer i,j,n
        REAL core(*)
        REAL x0(n),dx0(n),g(n),go(n),step(n)
        REAL dlt,etot,fgrgen,fplus(n),fminus(n)
        external fgrgen
INCLUDE(common/iofile)
        logical prbas
c
       write(iwr,20)
 20    format(//5x,'--- commence gradient evaluation ',/)
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      do j=1,n
c
c step forward in j
         call dcopy(n,x0,1,dx0,1)
         dx0(j) = x0(j) + dlt
         step(j) = dx0(j) - x0(j)
         dx0(j) = x0(j) + step(j)
       write(iwr,30)j
 30    format(//5x,'--- step forward in ',i4,/)
         fplus(j) = fgrgen(dx0,core,prbas) 
c
c step backwards in j
         call dcopy(n,x0,1,dx0,1)
         dx0(j) = x0(j) - dlt
         step(j) = dx0(j) - x0(j)
         dx0(j) =  x0(j) + step(j)
       write(iwr,40)j
 40    format(//5x,'--- step backward in ',i4,/)
          fminus(j) = fgrgen(dx0,core,prbas)
       end do
c
c generate gradient using central formula
c g = (fplus + fminus)/2delta
c
       do i=1,n
          g(i) = fplus(i) - fminus(i)
          g(i) = -g(i)/(2.d0*step(i))
       end do
       write(iwr,50)
       do 41 j=1,n,7
          write(iwr,51)(i,i=j,min(j+6,n))
 41       write(iwr,60)(g(i),i=j,min(j+6,n))
       write(iwr,'(//3x,12("-"))')
 50    format(//,3x,'--- gradient',/1x)
 51    format(/,9x,7(i4,10x))
 60    format(3x,7f14.8)
      return
      end
ccc
      subroutine convch(n,x,g,mx,ax,mg,ag,xtol)
       implicit none
       integer i,j,k,n
       REAL x(n),g(n),mx,ax,mg,ag,xtol
INCLUDE(common/iofile)
c
       mx = abs(x(1))
       ax = abs(x(1))
       mg = abs(g(1))
       ag = abs(g(1))
       do 10 i=2,n
          ax = ax + abs(x(i))
          ag = ag + abs(g(i))
          if(abs(x(i)).gt.mx) mx = abs(x(i))
          if(abs(g(i)).gt.mg) mg = abs(g(i))
 10    continue
       ax = ax/dble(n)
       ag = ag/dble(n)
c
       write(iwr,100)mx,xtol,ax,2.d0*xtol/3.d0,
     +               mg,4.d0*xtol/9d0,ag,8.d0*xtol/27.d0
 100   format(//3x,"maximum step    ",2x,f10.7,
     +          2x,"conv.criterion",2x,f8.6,
     +         /3x,"average step    ",2x,f10.7,
     +          2x,"conv.criterion",2x,f8.6,
     +         /3x,"maximum gradient",2x,f10.7,
     +          2x,"conv.criterion",2x,f8.6,
     +         /3x,"average gradient",2x,f10.7,
     +          2x,"conv.criterion",2x,f8.6,/1x)
      return
      end
      subroutine exppr(n,err)
       implicit none
c
       REAL err(*)
       integer i,j,p,n
INCLUDE(common/sortbeta)
INCLUDE(common/iofile)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
c
       write(iwr,50)
       do i=1,n
          do j=1,nexp(i)
             p = lexp(i,j)
             write(iwr,60)p,ex(p),ex(p)*err(i)
          end do
       end do
c
 50   format(/20x,2x,'final exponents',16x,'error'/)
 60   format( 20x,2x,i3,2x,f12.6,9x,f12.6)
      return
      end
      subroutine sysmo_int(q)
      implicit REAL (a-h,o-z)
c
      dimension q(*)
INCLUDE(common/restar)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/iofile)
       common/scfblk/enuc,etotal
INCLUDE(common/dump3)
INCLUDE(common/infoa)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
INCLUDE(common/blur)
_ENDIF
      logical opg_root
      integer idum
      logical prbas
      logical oresti,ostop,ostopr,oterm,ofirt
c
c
cc initialization
c
      call input
      oresti = .false.
      ostop  = .false.
      oterm=.false.
      ofirt=.true.
      ostopr = .false.
      call start(q,oresti,ostop,ostopr)
      call blktab(ostopr)
      call chksiz(.false.)
c
c     call secdrp(ionsec)
_IF(ccpdft)
c  
c initialise CCP1 DFT module
c  
      idum = CD_init(q,iwr)
      if (CD_active().and.opg_root()) then
         call CD_print_joboptions(iwr)
      endif
_ENDIF
c
      nopk=1
      call mogues(q)
      call hfscf(q)
CMR ifdeffed sysmo...
_IF(sysmo)
c
c  now write sysmo files
c
      call sysmowrite(q)
_ENDIF
      return
      end

