_IF(win95)
*$pragma aux delcc "!_" parm (value,reference,reference,reference)
*$pragma aux opencc "!_" parm (value,reference,reference,reference)
_ENDIF
c 
c  $Author: jmht $
c  $Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
c  $Locker:  $
c  $Revision: 5774 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/machci.m,v $
c  $State: Exp $
c  
_IF(cray,unicos)
      subroutine setbfa
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer unlink
      character *132 filatt
c
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
INCLUDE(common/utilc)
c
      common/blksiz/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsz680,
     * nsstat,nslen,nsmax,nsort(40)
      common/disc/ispz(3),irep
c
c     sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
c
      nsstat=0
c
      filatt='sort'
      inquire(file='sort',exist=oex)
      if (oex) then
       call vclose(nsort)
       ii = unlink('sort')
      endif
      call vopen(nsort,filatt,length)
      if(irep.ne.0)
     *call caserr('error creating/opening sort file')
c
      if(ooprnt)write(iwr,1)nsz512
1     format(/
     * ' sortfile allocated : blockfactor =',i5, ' words ')
c
      return
      end
      subroutine sttout
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksiz/nsz,nsz51(10),nsstat
     *,nslen,nsmax,nsort(40)
      common/bufb/buffer(1)
INCLUDE(common/stak)
      common/disc/ispz(3),irep
      ipos=iblock+1
      nsstat=nsstat+1
      call flushv(nsort,buffer,nsz,ipos,nsort(1))
      nslen=iblock+nsz
      if(irep.ne.0) then
       call caserr('error in writing to sortfile')
      endif
      return
      end
      subroutine stopbk
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/disc/ispz(3),irep
      common/blksiz/nsz(11),nsstat,
     *nslen,nsmax,nsort(40)
INCLUDE(common/stak)
      if(nsstat.eq.0)go to 2
      call chekwr(nsort)
      if(irep.eq.0)go to 1
      call caserr('i/o error on sortfile')
 1    nsstat=0
 2    if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine rdbak(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksiz/nsz,nsz51(10),nsstat
     *,nslen,nsmax,nsort(40)
      common/bufb/buffer(512)
      common/disc/ispz(3),irep
      ipos=iblock+1
      nsstat=nsstat+1
      call fillv(nsort(1),nsort,buffer,nsz,ipos)
      nslen=iblock+nsz
      if(irep.ne.0) then
       call caserr('input error on sortfile')
      endif
      return
      end
      subroutine closbf(idel)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer unlink
      common/blksiz/nsz(13),nsmax,nsort(40)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.gt.0) then
       call vclose(nsort)
       write(zunlnk,'(5hfort.,i2)')nsort(1)
       iii = unlink(zunlnk)
       if (ooprnt.and.iii.ne.0) write(iwr,44)zunlnk
 44    format(' *** error condition on unlink ***** ',a)
       inquire(file='sort',exist=oex)
       if (oex) ii = unlink('sort')
       if(ooprnt)write(iwr,1)
1      format(/ ' sortfile closed')
      end if
      nsmax = 0
      return
      end
      subroutine setbfb
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer unlink
      character *132 filatt
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
c
      common/blksi2/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax,
     + nsort(40)
      common/disc/ispz(3),irep
c
c     p-sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
c
      nsstat=0
c
      filatt='psort'
      inquire(file='psort',exist=oex)
      if (oex) ii = unlink('psort')
      call vopen(nsort,filatt,length)
      if(irep.ne.0)
     *call caserr('error creating/opening psort file')
c
      if(ooprnt)write(iwr,1)nsz512
1     format(/
     * ' p-sortfile allocated : blockfactor =',i5, ' words ')
c
      return
      end
      subroutine sttout2
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi2/nsz,nsz51(9),nsstat
     *,nslen ,nsmax,nsort(40)
      common/bufc/buffer(1)
      common/stak2/btri,mlow,nstack,iblock
      common/disc/ispz(3),irep
      ipos=iblock+1
      nsstat=nsstat+1
      call flushv(nsort,buffer,nsz,ipos,nsort(1))
      nslen=iblock+nsz
      if(irep.ne.0) then
       call caserr('error in writing to p-sortfile')
      endif
      return
      end
      subroutine stopbk2
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/disc/ispz(3),irep
      common/blksi2/nsz(10),nsstat
     *,nslen,nsmax ,nsort(40)
      common/stak2/btri,mlow(2),iblock
      if(nsstat.eq.0)go to 2
      call chekwr(nsort)
      if(irep.eq.0)go to 1
      call caserr('i/o error on p-sortfile')
 1    nsstat=0
 2    if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine rdbak2(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi2/nsz,nsz51(9),nsstat
     *,nslen,nsmax,nsort(40)
      common/bufc/buffer(512)
      common/disc/ispz(3),irep
      ipos=iblock+1
      nsstat=nsstat+1
      call fillv(nsort(1),nsort,buffer,nsz,ipos)
      nslen=iblock+nsz
      if(irep.ne.0) then
       call caserr('input error on p-sortfile')
      endif
      return
      end
      subroutine closbf2(idel)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer unlink
      common/blksi2/nsz(12),nsmax,nsort(40)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.gt.0) then
       call vclose(nsort)
       write(zunlnk,'(5hfort.,i2)')nsort(1)
       iii = unlink(zunlnk)
       if (ooprnt.and.iii.ne.0) write(iwr,44)zunlnk
 44    format(' *** error condition on unlink ***** ',a)
       inquire(file='psort',exist=oex)
       if (oex) ii = unlink('psort')
       if(ooprnt)write(iwr,1)
1      format(/' p-sortfile closed')
      endif
      nsmax = 0
      return
      end
      subroutine setbfc
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character *132 filatt
      integer getenv
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
c
      common/blksi3/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax,
     + nsort(40)
      common/disc/ispz(3),irep
c
c     table file settings
c
      nsz512=nsz*512
      nsz170=(nsz512-2)/3
      nsz85 =nsz170/2
      nszkl=nsz170+1
      nsz340=nsz170+nsz170
      nsz341=nsz340+1
      nsz510=nsz340+nsz170
      nsz342=nsz341+nsz85
      nszij=nsz340+1
c
      nsstat=0
c
      zname='table'
      ii = getenv(zname,filatt)
      if(ii.eq.0) filatt = zname
      call vopen(nsort,filatt,length)
      if(irep.ne.0)
     *call caserr('error creating/opening table file')
c
      if(ooprnt)write(iwr,1)nsz512
1     format(/
     * ' table-ci file allocated : blockfactor =',i5, ' words ')
c
      return
      end
      subroutine sttout3(jrec)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi3/nsz,nsz51(9),nsstat
     *,nslen ,nsmax,nsort(40)
      common/bufd/buffer(1)
      common/stak3/btri,mlow,nstack,iblock
      common/disc/ispz(3),irep
      ipos=jrec+1
      iblock=jrec
      nsstat=nsstat+1
      call flushv(nsort,buffer,nsz,ipos,nsort(1))
      nslen=iblock+nsz
      if(irep.ne.0) then
       call caserr('error in writing to tablefile')
      endif
      return
      end
      subroutine stopbk3
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/disc/ispz(3),irep
      common/blksi3/nsz(10),nsstat
     *,nslen,nsmax ,nsort(40)
      common/stak3/btri,mlow(2),iblock
      if(nsstat.eq.0)go to 2
      call chekwr(nsort)
      if(irep.eq.0)go to 1
      call caserr('i/o error on tablefile')
 1    nsstat=0
 2    if(nsmax.lt.nslen)nsmax=nslen
      return
      end
      subroutine rdbak3(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi3/nsz,nsz51(9),nsstat
     *,nslen,nsmax,nsort(40)
      common/bufd/buffer(512)
      common/disc/ispz(3),irep
      ipos=iblock+1
      nsstat=nsstat+1
      call fillv(nsort(1),nsort,buffer,nsz,ipos)
      nslen=iblock+nsz
      if(irep.ne.0) then
       call caserr('input error on tablefile')
      endif
      return
      end
      subroutine closbf3
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi3/nsz(12),nsmax,nsort(40)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.gt.0) then
       call vclose(nsort)
       write(zunlnk,'(5hfort.,i2)')nsort(1)
       iii = unlink(zunlnk)
       if (ooprnt.and.iii.ne.0) write(iwr,44)zunlnk
 44    format(' *** error condition on unlink ***** ',a)
      if(ooprnt)write(iwr,1)
1     format(/
     * ' ci-datafile closed')
      endif
      nsmax = 0
      return
      end
_ENDIF(cray,unicos)
_IF(ibm)
_IFN(fortio)
c ******************************************************
c             =   fortfpsa  =
c ******************************************************
c ******************************************************
      subroutine setbfa
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/bufb/aaaaaa
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
      common/blksiz/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsz680,
     * nsstat,nslen,nsmax
c
c     sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
c
      call setbf (aaaaaa,lenbl)
      if(ooprnt)write(iwr,1)lenbl
1     format(//
     * ' sortfile allocated : blocksize = ',i4, ' words')
      if(lenbl.ne.nsz51) call caserr(
     *'wrong block size specified for sortfile')
c
      return
      end
      subroutine sttout
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/stak)
      common/blksiz/nsz,nsz51(11),nslen
      call srtpt1(iblock)
      nslen=iblock+nsz
      return
      end
      subroutine setbfb
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/bufc/aaaaaa
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      common/blksi2/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax
c
c     sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
c
      call setbf2(aaaaaa,lenbl)
      if(ooprnt)write(iwr,1)lenbl
1     format(//
     * ' psortfile allocated : blocksize = ',i4, ' words')
      if(lenbl.ne.nsz51) call caserr(
     *'wrong block size specified for psortfile')
c
      return
      end
      subroutine sttout2
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/stak2/btri,mlow,nstack,iblock
      common/blksi2/nsz,nsz51(10),nslen
      call srtpt2(iblock)
      nslen=iblock+nsz
      return
      end
      subroutine stopbk
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksiz/nsz(12),nslen,nsmax
INCLUDE(common/stak)
      call srtst1
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine rdbak(iblock)
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksiz/nsz,nsz51(11),nslen
      common/bufb/buffer(512)
      call srtrd1(iblock)
      nslen=iblock+nsz
      return
      end
      subroutine stopbk2
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi2/nsz(11),nslen,nsmax
      common/stak2/btri,mlow(2),iblock
      call srtst2
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine rdbak2(iblock)
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi2/nsz,nsz51(10),nslen,nsmax
      common/bufc/buffer(512)
      call srtrd2(iblock)
      nslen=iblock+nsz
      return
      end
      subroutine setbfc
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/bufd/aaaaaa
c
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
c
      common/blksi3/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax
c
c     data file settings
c
      nsz51=nsz*512
      nsz170=(nsz51-2)/3
      nsz85=nsz170/2
      nsz340=nsz170+nsz170
      nsz512=nsz51*8
      nsz341=nsz340+1
      nsz510=nsz340+nsz170
      nsz342=nsz341+nsz85
      nszij =nsz340*4+1
      nszkl =(nsz340+nsz85)*4+1
c
      call setbf3(aaaaaa,lenbl)
      if(ooprnt)write(iwr,1)lenbl
1     format(//
     * ' datafile allocated : blocksize = ',i4, ' words')
      if(lenbl.ne.nsz51) call caserr(
     *'wrong block size specified for ci-datafile')
c
      return
      end
      subroutine sttout3(jrec)
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/stak3/btri,mlow,nstack,iblock
      common/blksi3/nsz,nsz51(10),nslen
      iblock=jrec
      call srtpt3(iblock)
      nslen=iblock+nsz
      return
      end
      subroutine stopbk3
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi3/nsz(11),nslen,nsmax
      common/stak3/btri,mlow(2),iblock
      call srtst3
      if(nsmax.lt.nslen)nsmax=nslen
      return
      end
      subroutine rdbak3(iblock)
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi3/nsz,nsz51(10),nslen,nsmax
      common/bufd/buffer(512)
      call srtrd3(iblock)
      nslen=iblock+nsz
      return
      end
_ENDIF(fortio)
_IF(fortio)
c ******************************************************
      subroutine setbfa
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      character *4  sort
      common/bufb/aaaaaa
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
      common/blksiz/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsz680,
     * nsstat,nslen,nsmax,nsort
      data sort/'sort'/
c
c     sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
c
      open(unit=nsort,access='direct',
     1 status='unknown',
     2 form='unformatted',recl=nsz512,
     3 file=sort)
      if(ooprnt)write(iwr,1)nsz51
1     format(//
     * ' sortfile allocated : blocksize = ',i4, ' words')
c     if(lenbl.ne.nsz51) call caserr(
c    *'wrong block size specified for sortfile')
c
      return
      end
      subroutine sttout
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
INCLUDE(common/sizes)
INCLUDE(common/stak)
      common/blksiz/nsz,nsz51(11),nslen ,nsmax,nsort
      common/bufb/buffer((m19040/4096)*512)
INCLUDE(common/iofile)
      iblout=iblock/nsz+1
      write(nsort,rec=iblout,err=300,iostat=ifail)buffer
      nslen=iblock+nsz
      if(ifail.ne.0) go to 300
      return
 300  write(iwr,301) iblout
 301  format(' **** sttout error, block = ',i4)
      end
      subroutine stopbk
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      common/blksiz/nsz(12),nslen,nsmax
INCLUDE(common/stak)
c     call srtst1
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine closbf(idel)
      implicit REAL  (a-h,o-z)
      common/blksiz/nsz(14),nsort
      close(unit=nsort)
      return
      end
      subroutine rdbak(iblock)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/blksiz/nsz,nscrap(11),nslen,msmax,nsort
      common/bufb/buffer((m19040/4096)*512)
INCLUDE(common/iofile)
      iblin=iblock/nsz+1
      read(nsort,rec=iblin,err=300,iostat=ifail)buffer
      return
 300  write(iwr,301)iblock
 301  format(' **** rdbak error : iblock = ',i5)
      nslen=iblock+nsz
      return
      end
      subroutine setbfb
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      character *4  sort
      common/bufc/aaaaaa(512)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
c
      common/blksi2/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax
     * , nsort
      data sort/'port'/
c
c     p-sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
c
      open(unit=nsort,access='direct',
     1 status='unknown',
     2 form='unformatted',recl=nsz512,
     3 file=sort)
      if(ooprnt)write(iwr,1)nsz51
1     format(//
     * ' p-sortfile allocated : blocksize = ',i4, ' words')
c     if(lenbl.ne.nsz51) call caserr(
c    *'wrong block size specified for sortfile')
c
      return
      end
      subroutine sttout2
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      common/stak2/btri,mlow,nstack,iblock
      common/blksi2/nsz,nsz51(10),nslen ,nsmax,nsort
      common/bufc/buffer(512)
INCLUDE(common/iofile)
      iblout=iblock/nsz+1
      write(nsort,rec=iblout,err=300,iostat=ifail)buffer
      nslen=iblock+nsz
      if(ifail.ne.0) go to 300
      return
 300  write(iwr,301) iblout
 301  format(' **** sttout2 error, block = ',i4)
      end
      subroutine stopbk2
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      common/blksi2/nsz(11),nslen,nsmax
      common/stak2/btri,mlow(2),iblock
c     call srtst1
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine closbf2(idel)
      implicit REAL  (a-h,o-z)
      common/blksi2/nsz(13),nsort
      close(unit=nsort)
      return
      end
      subroutine rdbak2(iblock)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi2/nsz,nscrap(10),nslen,msmax,nsort
      common/bufc/buffer(512)
INCLUDE(common/iofile)
      iblin=iblock/nsz+1
      read(nsort,rec=iblin,err=300,iostat=ifail)buffer
      return
 300  write(iwr,301)iblock
 301  format(' **** rdbak2 error : iblock = ',i5)
      nslen=iblock+nsz
      return
      end
      subroutine setbfc
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      character *4  sort
      common/bufd/aaaaaa(512)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
      common/blksi3/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax
     * , nsort
      data sort/'data'/
c
c     sort file settings
c
      nsz51=nsz*512
      nsz170=(nsz51-2)/3
      nsz85=nsz170/2
      nsz340=nsz170+nsz170
      nsz512=nsz51*8
      nsz341=nsz340+1
      nsz510=nsz340+nsz170
      nsz342=nsz341+nsz85
      nszij =nsz340*4+1
      nszkl =(nsz340+nsz85)*4+1
c
      open(unit=nsort,access='direct',
     1 status='unknown',
     2 form='unformatted',recl=nsz512,
     3 file=sort)
      if(ooprnt)write(iwr,1)nsz51
1     format(//
     * ' datafile allocated : blocksize = ',i4, ' words')
c     if(lenbl.ne.nsz51) call caserr(
c    *'wrong block size specified for sortfile')
c
      return
      end
      subroutine sttout3(jrec)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      common/stak3/btri,mlow,nstack,iblock
      common/blksi3/nsz,nsz51(10),nslen ,nsmax,nsort
      common/bufd/buffer(512)
INCLUDE(common/iofile)
      iblock=jrec
      iblout=iblock/nsz+1
      write(nsort,rec=iblout,err=300,iostat=ifail)buffer
      nslen=iblock+nsz
      if(ifail.ne.0) go to 300
      return
 300  write(iwr,301) iblout
 301  format(' **** sttout3 error, block = ',i4)
      end
      subroutine stopbk3
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      common/blksi3/nsz(11),nslen,nsmax
      common/stak3/btri,mlow(2),iblock
c     call srtst1
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine closbf3
      implicit REAL  (a-h,o-z)
      common/blksi3/nsz(13),nsort
      close(unit=nsort)
      return
      end
      subroutine rdbak3(iblock)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi3/nsz,nscrap(10),nslen,msmax,nsort
      common/bufd/buffer(512)
INCLUDE(common/iofile)
      iblin=iblock/nsz+1
      read(nsort,rec=iblin,err=300,iostat=ifail)buffer
      return
 300  write(iwr,301)iblock
 301  format(' **** rdbak3 error : iblock = ',i5)
      nslen=iblock+nsz
      return
      end
_ENDIF(fortio)
_ENDIF(ibm)
_IF(vax)
c ******************************************************
      subroutine setbfa
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      character *8  sort
      common/bufb/aaaaaa
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
      common/blksiz/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsz680,
     * nsstat,nslen,nsmax,nsort
      data sort/'sort.dat'/
c
c     sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
      nsz51=nsz512*2
c
      open(unit=nsort,access='direct',status='unknown',
     + err=300,
     + form='unformatted',recl=nsz51,file=sort,
     + initialsize=8000,extendsize=1000,blocksize=94*512,
     + buffercount=10)
      if(ooprnt)write(iwr,1)nsz51
1     format(//
     * ' sortfile allocated : blocksize = ',i4, ' words')
      return
 300  call caserr('error opening sortfile')
      return
      end
      subroutine setbfb
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      character *8  sort
      common/bufc/aaaaaa(512)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
      common/blksi2/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax
     * , nsort
      data sort/'port.dat'/
c
c     p-sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
      nsz51=nsz512*2
c
      open(unit=nsort,access='direct',status='unknown',
     + err=300,
     + form='unformatted',recl=nsz51,file=sort,
     + initialsize=8000,extendsize=1000,blocksize=94*512,
     + buffercount=10)
      if(ooprnt)write(iwr,1)nsz512
1     format(//
     * ' p-sortfile allocated : blocksize = ',i4, ' words')
      return
 300  call caserr('error opening p-sortfile')
      return
      end
      subroutine setbfc
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4  (y)
      character *8  table
      common/bufd/aaaaaa(512)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
      common/blksi3/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax
     * , nsort
      data table/'table.ci'/
c
c     table file settings
c
      nsz512=nsz*512
      nsz170=(nsz512-2)/3
      nsz85=nsz170/2
      nsz340=nsz170+nsz170
      nsz341=nsz340+1
      nsz510=nsz340+nsz170
      nsz342=nsz341+nsz85
      nszij =nsz340*4+1
      nszkl =(nsz340+nsz85)*4+1
      nsz51=nsz512*2
c
      open(unit=nsort,access='direct',status='unknown',
     + err=300,
     + form='unformatted',recl=nsz51,file=table,
     + initialsize=8000,extendsize=1000,blocksize=94*512,
     + buffercount=10)
      if(ooprnt)write(iwr,1)nsz512
1     format(//
     * ' tablefile allocated : blocksize = ',i4, ' words')
      return
 300  call caserr('error opening tablefile')
      return
      end
      subroutine closbf2(idel)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi2/nsz(12),nsmax,nsort
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.gt.0) then
       close(unit=nsort,status='delete')
       nsmax = 0
       if(ooprnt)write(iwr,1)
1      format(/
     * ' p-sortfile deleted')
      endif
      return
      end
      subroutine closbf3
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi3/nsz(12),nsmax,nsort
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.gt.0)
     +close(unit=nsort)
      if(ooprnt)write(iwr,1)
1     format(/
     * ' tablefile closed')
      return
      end
      subroutine closbf(idel)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksiz/nsz(13),nsmax,nsort
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.gt.0) then
       close(unit=nsort,status='delete')
       nsmax = 0
       if(ooprnt)write(iwr,1)
1      format(/
     * ' sortfile deleted')
      endif
      return
      end
      subroutine rdbak(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer bread
      common/blksiz/nsz,nsz512,nszz(9),nsstat
     *,nslen,nsmax,nsort
      common/bufb/buffer(5120)
      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on sortfile')
      endif
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine rdbak2(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer bread
      common/blksi2/nsz,nsz512,nszz(8),nsstat
     *,nslen,nsmax,nsort
      common/bufc/buffer(512)
      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on sortfile')
      endif
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine rdbak3(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer bread
      common/blksi3/nsz,nsz512,nszz(8),nsstat
     *,nslen,nsmax,nsort
      common/bufd/buffer(512)
      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on tablefile')
      endif
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine stopbk2
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer bwait
INCLUDE(common/iofile)
      common/blksi2/nsz(10),nsstat,
     *nslen,nsmax,nsort
      common/stak2/btri,mlow(2),iblock
      if(nsstat.ne.0) then
       irep=bwait(nsort,icnt)
       if(irep.ne.0) then
        write(iwr,3)icnt
 3      format(/1x,'wait error on p-sort :', i6,' words transferred')
        call caserr('wait error on p-sortfile')
       endif
      nsstat=0
      endif
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine stopbk3
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer bwait
INCLUDE(common/iofile)
      common/blksi3/nsz(10),nsstat,
     *nslen,nsmax,nsort
      common/stak3/btri,mlow(2),iblock
      if(nsstat.ne.0) then
       irep=bwait(nsort,icnt)
       if(irep.ne.0) then
        write(iwr,3)icnt
 3      format(/1x,'wait error on table :', i6,' words transferred')
        call caserr('wait error on tablefile')
       endif
       nsstat=0
      endif
      if(nsmax.lt.nslen)nsmax=nslen
      return
      end
      subroutine stopbk
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer bwait
INCLUDE(common/iofile)
      common/blksiz/nsz(11),nsstat,
     *nslen,nsmax,nsort
INCLUDE(common/stak)
      if(nsstat.gt.0) then
       irep=bwait(nsort,icnt)
       if(irep.ne.0) then
        write(iwr,3)icnt
 3      format(/1x,'wait error on sort :', i6,' words transferred')
        call caserr('wait error on sortfile')
       endif
       nsstat=0
      endif
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine sttout2
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
      integer bwrite
      common/blksi2/nsz,nsz512,nsz340(8),nsstat
     * ,nslen,nsmax,nsort
      common/bufc/buffer(1)
      common/stak2/btri,mlow,nstack,iblock
      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to p-sortfile')
      endif
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine sttout3(jrec)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
      integer bwrite
      common/blksi3/nsz,nsz512,nsz340(8),nsstat
     * ,nslen,nsmax,nsort
      common/bufd/buffer(1)
      common/stak3/btri,mlow,nstack,iblock
      iblock=jrec
      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to tablefile')
      endif
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine sttout
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
      integer bwrite
      common/blksiz/nsz,nsz512,nsz340(9),nsstat
     * ,nslen,nsmax,nsort
      common/bufb/buffer(1)
INCLUDE(common/stak)
      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to sortfile')
      endif
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      function bread(nsort,irec,buffer,nword)
      implicit REAL  (a-h,o-z)
      integer bread
      dimension buffer(nword)
c
c bread for the vax ... differs from convex aread
c currently no asynchronous I/O on vax of any form
c asynch I/O to be will be block addressable
c
      read(nsort,rec=irec,iostat=irep) buffer
      bread = irep
      return
      end
      function bwrite(nsort,irec,buffer,nword)
      implicit REAL  (a-h,o-z)
      integer bwrite
      dimension buffer(nword)
c
c bwrite for the vax ... differs from convex awrite
c
      write(nsort,rec=irec,iostat=irep) buffer
      bwrite = irep
      return
      end
      integer function bwait(nsort,nlen)
      implicit REAL  (a-h,o-z)
c
c bwait for the vax ... will act as asynchronous wait
c
      nlen = 0
      bwait = 0
      return
      end
_ENDIF(vax)
_IFN(cray,fps,cyber205,ibm,vax,ipsc)
_IFN(parallel)
      subroutine closbf2(idel)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IFN1(x)      character *1024 zsort,blank
_IF1(x)      character *44 zsort,blank
INCLUDE(common/blksiz2)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.ge.0) then
_IF(fortio)
       close(unit=nsort,status='delete')
       if(ooprnt)write(iwr,2)
       nsmax = -1
_ELSEIF(fcio)
       close(unit=nsort)
       if(ooprnt)write(iwr,1)
_ELSE
       call closecc(nsort)
       if(ooprnt)write(iwr,1)
       nsmax = -1
       call gtnv('psort',zsort)
       blank = ' '
       if(zsort.eq.blank) zsort = 'psort'
       call strtrm(zsort,length)
_IFN(vms)
       call delcc(zsort,length,ierrio)
_ELSE
       call delcc(%ref(zsort),length,ierrio)
_ENDIF
       if(ierrio.ne.0)call ioerr('delete',0,zsort)
       if(ooprnt)write(iwr,2)
_ENDIF
      endif
1     format(/1x,'*** p-sortfile closed')
_IFN(fcio)
2      format(/1x,'*** p-sortfile deleted')
_ENDIF
      return
      end
      subroutine closbf3
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi3/nsz(12),nsmax,nsort
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.gt.0)
_IF(fcio,fortio)
     *close(unit=nsort)
_ENDIF(fcio,fortio)
_IFN(fcio,fortio)
     *call closecc(nsort)
_ENDIF
      if(ooprnt)write(iwr,1)
1     format(/
     * ' tablefile closed')
      return
      end
      subroutine closbf(idel)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF1(x)      character *44 zsort,blank
_IFN1(x)      character *1024 zsort,blank
INCLUDE(common/blksiz)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.ge.0) then
_IF(fortio)
       close(unit=nsort,status='delete')
       nsmax = -1
       if(ooprnt)write(iwr,1)
1      format(/1x,'*** sortfile deleted')
_ELSEIF(fcio)
       close(unit=nsort)
       if(ooprnt)write(iwr,1)
1      format(/1x,'*** sortfile closed')
_ELSE
       call closecc(nsort)
       nsmax = -1
       call gtnv('sort',zsort)
       blank = ' '
       if(zsort.eq.blank) zsort = 'sort'
       call strtrm(zsort,length)
_IFN(vms)
       call delcc(zsort,length,ierrio)
_ELSE
       call delcc(%ref(zsort),length,ierrio)
_ENDIF
       if(ierrio.ne.0)call ioerr('delete',0,zsort)
       if(ooprnt) then
        write(iwr,1)
1       format(/1x,'*** sortfile closed')
        write(iwr,2)
2       format(/1x,'*** sortfile deleted')
       endif
_ENDIF
      endif
      return
      end
      subroutine rdbak(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio,fcio)
_IF1(x)      integer aread
_IFN1(x)      integer bread
_ENDIF(fortio,fcio)
INCLUDE(common/blksiz)
      common/bufb/buffer(5120)
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=aread(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      call srchcc(nsort,(iblock+1),ierrio)
      if(ierrio.ne.0)call ioerr('search',0,'sort')
      call getccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('read',0,'sort')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine rdbak2(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio,fcio)
_IF1(x)      integer aread
_IFN1(x)      integer bread
_ENDIF(fortio,fcio)
INCLUDE(common/blksiz2)
      common/bufc/buffer(512)
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=aread(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      call srchcc(nsort,(iblock+1),ierrio)
      if(ierrio.ne.0)call ioerr('search',0,'psort')
      call getccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('read',0,'psort')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine rdbak3(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio,fcio)
_IF(convex)
_     integer aread
_ELSE
      integer bread
_ENDIF
_ENDIF(fortio,fcio)
      common/blksi3/nsz,nsz512,nszz(8),nsstat
     *,nslen,nsmax,nsort
      common/bufd/buffer(512)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
_IF(fortio,fcio)
_IF(convex)
      ipos=iblock*512
      ipos=ipos*8
      irep=aread(nsort,ipos,buffer,nsz512*8)
_ELSE
      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
_ENDIF
      if(irep.ne.0) then
      call caserr('input error on tablefile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      if (ooprnt) then
       ibl = iblock + 1
       write(iwr,10) nsort, ibl
 10    format(1x,'**** get from table:', i3,
     +           ' at block',i5)
      endif
      call srchcc(nsort,(iblock+1),ierrio)
      if(ierrio.ne.0)call ioerr('search',0,'table')
      call getccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('read',0,'table')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine setbfa
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer aset
_ENDIF(fortio)
_IF1(x)      character *44 zsort,blank
_IFN1(x)      character *1024 zsort,blank
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/blksiz)
INCLUDE(common/atmblk)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
c
c     sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
      nsstat=0
c
_IFN(vms)
      call gtnv('sort',zsort)
      blank = ' '
      if(zsort.eq.blank) zsort = 'sort'
      call strtrm(zsort,length)
_ELSE
      call fgetenv(%ref('sort'),%ref(zsort))
      blank = ' '
      if(zsort.eq.blank) zsort = 'sort'
      zsort='sort'
      call strtrm(zsort,length)
_ENDIF
      irep = 0
      if (nsmax.lt.0) then
_IF(fcio)
_IFN1(civfu)       open(unit=nsort,file=zsort,status='unknown',iostat=irep,
_IF1(ats)     &  access='direct',disp='delete',recl=nsz512*8)
_IF1(xpgbdrh)     &  access='direct',recl=nsz512*8)
_ENDIF(fcio)
_IFN(fortio,fcio)
_IFN(vms)
       call opencc(zsort,length,nsort,ierrio)
_ELSE
       call opencc(%ref(zsort),length,nsort,ierrio)
_ENDIF
       if(ierrio.ne.0)call ioerr('open',0,zsort)
_ENDIF
_IF(fortio)
       open(unit=nsort,file=zsort,status='unknown')
_IF1(x)       irep=aset(nsort,1)
_ENDIF(fortio)
       if(irep.ne.0)
     * call caserr(
     * 'error creating/opening sort file')
       if(ooprnt)write(iwr,1)zsort(1:length),nsz
       nsmax = 0
      endif
c
      return
1     format(/
     * ' sortfile ',a,' allocated '/
     * '          : blockfactor =',i3, ' block(s) ')
      end
      subroutine setbfb
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer aset
_ENDIF(fortio)
_IF1(x)      character *44 zsort,blank
_IFN1(x)      character *1024 zsort,blank
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
INCLUDE(common/blksiz2)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
c
c     sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
      nsstat=0
c
_IFN(vms)
      call gtnv('psort',zsort)
      blank = ' '
      if(zsort.eq.blank) zsort = 'psort'
_ELSE
      call fgetenv(%ref('psort'),%ref(zsort))
      blank = ' '
      if(zsort.eq.blank) zsort = 'psort'
      zsort = 'psort'
_ENDIF
      call strtrm(zsort,length)
      irep=0
      if (nsmax.lt.0) then
_IF(fcio)
_IFN1(civfu)       open(unit=nsort,file=zsort,status='unknown',iostat=irep,
_IF1(ats)     &  access='direct',disp='delete',recl=nsz512*8)
_IF1(xpgbdrh)     &  access='direct',recl=nsz512*8)
_ENDIF(fcio)
_IFN(fortio,fcio)
_IFN(vms)
       call opencc(zsort,length,nsort,ierrio)
_ELSE
       call opencc(%REF(zsort),length,nsort,ierrio)
_ENDIF
       if(ierrio.ne.0)call ioerr('open',0,zsort)
_ENDIF
_IF(fortio)
       open(unit=nsort,file=zsort,status='unknown')
_IF1(x)       irep=aset(nsort,1)
_ENDIF(fortio)
       if(irep.ne.0)
     * call caserr(
     * 'error creating/opening p-sort file')
       if(ooprnt)write(iwr,1)zsort(1:length),nsz
       nsmax = 0
      endif
c
      return
1     format(/
     * ' p-sortfile ',a,' allocated '/
     * '          : blockfactor =',i3, ' block(s) ')
      end
      subroutine setbfc
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer aset
_ENDIF(fortio)
_IF1(x)      character *44 zsort,blank
_IFN1(x)      character *1024 zsort,blank
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      common/blksi3/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax,nsort
c
c     table file settings
c
      nsz512=nsz*512
      nsz170=(nsz512-2)/3
      nsz85 =nsz170/2
      nszkl=nsz170+1
      nsz340=nsz170+nsz170
      nsz341=nsz340+1
      nsz510=nsz340+nsz170
      nszij=nsz340+1
      nsz342=nsz341+nsz85
      nsstat=0
c
_IFN(vms)
      call gtnv('table',zsort)
      blank = ' '
      if(zsort.eq.blank) zsort = 'table'
      call strtrm(zsort,length)
_ELSE
      call fgetenv(%ref('table'),%ref(zsort))
      blank = ' '
      if(zsort.eq.blank) zsort = 'table'
      zsort = 'table'
      call strtrm(zsort,length)
_ENDIF
_IF(fcio)
_IFN1(civfu)      open(unit=nsort,file=zsort,status='unknown',iostat=irep,
_IF1(ats)     & access='direct',disp='delete',recl=nsz512*8)
_IF1(xpgbdrh)     & access='direct',recl=nsz512*8)
_ENDIF(fcio)
_IFN(fortio,fcio)
      irep=0
_IFN(vms)
      call opencc(zsort,length,nsort,ierrio)
_ELSE
      call opencc(%ref(zsort),length,nsort,ierrio)
_ENDIF
      if(ierrio.ne.0)call ioerr('open',0,zsort)
_ENDIF
_IF(fortio)
      open(unit=nsort,file=zsort,status='unknown')
_IF1(x)      irep=aset(nsort,1)
_ENDIF(fortio)
      if(irep.ne.0)
     *call caserr(
     *'error creating/opening table-ci file')
      if(ooprnt)write(iwr,1)zsort(1:length),nsz
1     format(/
     * ' table-ci file ',a,' allocated '/
     * '          : blockfactor =',i3, ' block(s) ')
c
      return
      end
      subroutine stopbk2
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer await
_ENDIF(fortio)
INCLUDE(common/iofile)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
INCLUDE(common/blksiz2)
      common/stak2/btri,mlow(2),iblock
      if(nsstat.eq.0)go to 2
_IF(fortio)
_IF1(x)      irep=await(nsort,icnt)
      if(irep.ne.0) then
      write(iwr,3)icnt
 3    format(/1x,'wait error on p-sort :', i6,' words transferred')
      call caserr('wait error on p-sortfile')
      endif
_ENDIF(fortio)
_IFN(fortio)
      irep = 0
_ENDIF
      nsstat=0
 2    if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine stopbk3
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF1(x)      integer await
INCLUDE(common/iofile)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
      common/blksi3/nsz(10),nsstat,
     *nslen,nsmax,nsort
      common/stak3/btri,mlow(2),iblock
      if(nsstat.eq.0)go to 2
_IF(fortio)
_IF1(x)      irep=await(nsort,icnt)
_IFN1(x)      irep = 0
      if(irep.ne.0) then
      write(iwr,3)icnt
 3    format(/1x,'wait error on table :', i6,' words transferred')
      call caserr('wait error on tablefile')
      endif
_ENDIF(fortio)
_IFN(fortio)
      irep = 0
_ENDIF
      nsstat=0
 2    if(nsmax.lt.nslen)nsmax=nslen
      return
      end
      subroutine stopbk
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer await
_ENDIF(fortio)
INCLUDE(common/iofile)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
INCLUDE(common/blksiz)
INCLUDE(common/stak)
      if(nsstat.eq.0)go to 2
_IF(fortio)
_IF1(x)      irep=await(nsort,icnt)
      if(irep.ne.0) then
      write(iwr,3)icnt
 3    format(/1x,'wait error on sort :', i6,' words transferred')
      call caserr('wait error on sortfile')
      endif
_ENDIF(fortio)
_IFN(fortio)
      irep = 0
_ENDIF
      nsstat=0
 2    if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine sttout2
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
_IF(fcio,fortio)
_IF1(x)      integer awrite
_IFN1(x)      integer bwrite
_ENDIF(fcio,fortio)
INCLUDE(common/blksiz2)
      common/bufc/buffer(1)
      common/stak2/btri,mlow,nstack,iblock
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=awrite(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to p-sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      if (iblock.ne.nslen) then
         call srchcc(nsort,(iblock+1),ierrio)
         if(ierrio.ne.0)call ioerr('search',0,'psort')
      endif
      call putccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('write',0,'psort')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine sttout3(jrec)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
_IF(fortio,fcio)
_IF1(x)      integer awrite
_IFN1(x)      integer bwrite
_ENDIF(fortio,fcio)
      common/blksi3/nsz,nsz512,nsz340(8),nsstat
     * ,nslen,nsmax,nsort
      common/bufd/buffer(1)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      common/stak3/btri,mlow,nstack,iblock
      iblock=jrec
_IF(fortio,fcio)
_IF(convex)
      ipos=iblock*512
      ipos=ipos*8
      irep=awrite(nsort,ipos,buffer,nsz512*8)
_ELSE
      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
_ENDIF
      if(irep.ne.0) then
      call caserr('error in writing to tablefile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      if (ooprnt) then
       ibl = iblock + 1
       write(iwr,10) nsort, ibl
 10    format(1x,'**** write to table:', i3,
     +           ' at block',i5)
      endif
      if (iblock.ne.nslen) then
         call srchcc(nsort,(iblock+1),ierrio)
         if(ierrio.ne.0)call ioerr('search',0,'table')
      endif
      call putccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('write',0,'table')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine sttout
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
_IF(fortio,fcio)
_IF1(x)      integer awrite
_IFN1(x)      integer bwrite
_ENDIF(fortio,fcio)
INCLUDE(common/blksiz)
      common/bufb/buffer(1)
INCLUDE(common/stak)
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=awrite(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      if (iblock.ne.nslen) then
         call srchcc(nsort,(iblock+1),ierrio)
         if(ierrio.ne.0)call ioerr('search',0,'sort')
      endif
      call putccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('write',0,'sort')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
_ENDIF
_IF(parallel)
      subroutine closbf2(idel)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
INCLUDE(common/blksiz2)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.ge.0) then
_IF(fortio)
       close(unit=nsort,status='delete')
       if(ooprnt)write(iwr,1)
1      format(/' p-sortfile deleted')
_ELSEIF(fcio)
       close(unit=nsort)
       if(ooprnt)write(iwr,1)
1      format(/' p-sortfile closed')
_ELSE
       call closecc(nsort)
       if(ooprnt)write(iwr,1)
1      format(/' p-sortfile closed')
       if(idel.ne.0) then
         zsort = 'psort'
         call strtrm(zsort,length)
         my = minode
         if (my.lt.10) then
           write(zsort(length+1:),'(i1)') my
           length = length + 1
         else if (my.lt.100) then
           write(zsort(length+1:),'(i2)') my
           length = length + 2
         else if (my.lt.1000) then
           write(zsort(length+1:),'(i3)') my
           length = length + 3
         end if
         call delcc(zsort,length,ierrio)
         if(ierrio.ne.0)call ioerr('delete',0,zsort)
         if(ooprnt)write(iwr,2)
2        format(/' p-sortfile deleted')
       endif
_ENDIF
      endif
      nsmax = -1
      return
      end
      subroutine closbf3
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi3/nsz(10),nsstat,
     *nslen,nsmax,nsort,nstid(2),oasync
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.gt.0) then
_IF(fortio,fcio)
       close(unit=nsort)
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
       call closecc(nsort)
_ENDIF
      if(ooprnt)write(iwr,1)
1     format(/
     * ' table file closed')
      endif
      nsmax = 0
      return
      end
      subroutine closbf(idel)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
INCLUDE(common/blksiz)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      if(nsmax.ge.0) then
_IF(fortio)
       close(unit=nsort,status='delete')
       if(ooprnt)write(iwr,2)
       nsmax = -1
_ELSEIF(fcio)
       close(unit=nsort)
       if(ooprnt)write(iwr,1)
_ELSE
       call closecc(nsort)
       if(ooprnt)write(iwr,1)
       if(idel.ne.0) then
        zsort = 'sort'
        call strtrm(zsort,length)
        my = minode
        if (my.lt.10) then
           write(zsort(length+1:),'(i1)') my
           length = length + 1
        else if (my.lt.100) then
           write(zsort(length+1:),'(i2)') my
           length = length + 2
        else if (my.lt.1000) then
           write(zsort(length+1:),'(i3)') my
           length = length + 3
        end if
        call delcc(zsort,length,ierrio)
        if(ierrio.ne.0)call ioerr('delete',0,zsort)
        if(ooprnt)write(iwr,2)
       endif
_ENDIF
      endif
1     format(/1x,'*** sortfile closed')
_IFN(fcio)
2     format(/1x,'*** sortfile deleted')
_ENDIF
      nsmax = -1
      return
      end
      subroutine rdbak(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio,fcio)
_IF1(x)      integer aread
_IFN1(x)      integer bread
_ENDIF(fortio,fcio)
INCLUDE(common/blksiz)
      common/bufb/buffer(512)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
c
      dumtim = dclock()
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=aread(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      call srchcc(nsort,(iblock+1),ierrio)
      if(ierrio.ne.0)call ioerr('search',0,'sort')
      call getccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('read',0,'sort')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
*     write(6,*)' rdbak, iblock, nslen ', iblock,nslen
      tgettm(7) = tgettm(7) + dclock() - dumtim
      return
      end
      subroutine rdbak2(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio,fcio)
_IF1(x)      integer aread
_IFN1(x)      integer bread
_ENDIF(fortio,fcio)
INCLUDE(common/blksiz2)
      common/bufc/buffer(512)
c
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=aread(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on p-sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      call srchcc(nsort,(iblock+1),ierrio)
      if(ierrio.ne.0)call ioerr('search',0,'psort')
      call getccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('read',0,'psort')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine rdbak3(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio,fcio)
_IF1(x)      integer aread
_IFN1(x)      integer bread
_ENDIF(fortio,fcio)
      common/blksi3/nsz,nsz512,nszz(8),nsstat
     *,nslen,nsmax,nsort,nstid(2),oasync
      common/bufd/buffer(512)
c
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=aread(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on tablefile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      call srchcc(nsort,(iblock+1),ierrio)
      if(ierrio.ne.0)call ioerr('search',0,'table')
      call getccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('read',0,'table')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine setbfa(inode)
c
c...   concurrent sortfile-io
c...   files start at 0 / sortfile starts at block
c
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer aset
_ENDIF(fortio)
_IF1(x)      character *44 zsort,blank
_IFN1(x)      character *1024 zsort,blank
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/blksiz)
INCLUDE(common/atmblk)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
c
c     sort file settings
c
      dumtim=dclock()
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
c
      nsstat=-1
c
      zsort = 'sort'
      call strtrm(zsort,length)
c
      my = inode
      if (my.lt.0) my = minode
c
      if (my.lt.10) then
         write(zsort(length+1:),'(i1)') my
         length = length + 1
      else if (my.lt.100) then
         write(zsort(length+1:),'(i2)') my
         length = length + 2
      else if (my.lt.1000) then
         write(zsort(length+1:),'(i3)') my
         length = length + 3
      end if
c
c...    open concurrent io  seperately for each node
c
      if (nsmax.lt.0) then
_IF(fcio)
_IFN1(civfu)       open(unit=nsort,file=zsort,status='unknown',iostat=irep,
_IF1(ats)     &  access='direct',disp='delete',recl=nsz512*8)
_IF1(xpgdrh)     &  access='direct',recl=nsz512*8)
_ENDIF(fcio)
_IFN(fortio,fcio)
       irep=0
       call opencc(zsort,length,nsort,ierrio)
       if(ierrio.ne.0)call ioerr('open',0,zsort)
_ENDIF
_IF(fortio)
       open(unit=nsort,file=zsort,status='unknown')
_IF1(x)       irep=aset(nsort,1)
_ENDIF(fortio)
       if(irep.ne.0) call caserr(
     * 'error creating/opening sort file')
       if(ooprnt)write(iwr,1)zsort(1:length),nsz
1      format(/
     *  ' sortfile ',a,' allocated '/
     *  '          : blockfactor =',i3, ' block(s) ')
       topen(7) = topen(7) + dclock() - dumtim
       nsmax = 0
      endif
c
      return
      end
      subroutine setbfb(inode)
c
c...   concurrent sortfile-io
c...   files start at 0 / sortfile starts at block
c
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer aset
_ENDIF(fortio)
_IF1(x)      character *44 zsort,blank
_IFN1(x)      character *1024 zsort,blank
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/blksiz2)
INCLUDE(common/atmblk)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
c
      dumtim=dclock()
c
c     p-sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
      nsstat=-1
c
      zsort = 'psort'
      call strtrm(zsort,length)
c
      my = inode
      if (my.lt.0) my = minode
c
      if (my.lt.10) then
         write(zsort(length+1:),'(i1)') my
         length = length + 1
      else if (my.lt.100) then
         write(zsort(length+1:),'(i2)') my
         length = length + 2
      else if (my.lt.1000) then
         write(zsort(length+1:),'(i3)') my
         length = length + 3
      end if
c
c...    open concurrent io  seperately for each node
c
      if (nsmax.lt.0) then
_IF(fcio)
_IFN1(civfu)       open(unit=nsort,file=zsort,status='unknown',iostat=irep,
_IF1(ats)     &  access='direct',disp='delete',recl=nsz512*8)
_IF1(xpgdrh)     &  access='direct',recl=nsz512*8)
_ENDIF(fcio)
_IFN(fortio,fcio)
       irep=0
       call opencc(zsort,length,nsort,ierrio)
       if(ierrio.ne.0)call ioerr('open',0,zsort)
_ENDIF
_IF(fortio)
       open(unit=nsort,file=zsort,status='unknown')
_IF1(x)       irep=aset(nsort,1)
_ENDIF(fortio)
       if(irep.ne.0) call caserr(
     * 'error creating/opening p-sortfile')
       if(ooprnt)write(iwr,1)zsort(1:length),nsz
1      format(/
     *  ' p-sortfile ',a,' allocated '/
     *  '          : blockfactor =',i3, ' block(s) ')
       topen(8) = topen(8) + dclock() - dumtim
       nsmax = 0
      endif
c
      return
      end
      subroutine setbfc(inode)
c
c...   concurrent table-ci IO
c...   files start at 0 / table file starts at block
c
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer aset
_ENDIF(fortio)
_IF1(x)      character *44 zsort,blank
_IFN1(x)      character *1024 zsort,blank
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      common/blksi3/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax,nsort,
     * nstid(2), oasync
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
c
      dumtim=dclock()
c
c     table-ci file settings
c
      nsz512=nsz*512
      nsz170=(nsz512-2)/3
      nsz85 =nsz170/2
      nszkl=nsz170+1
      nsz340=nsz170+nsz170
      nsz341=nsz340+1
      nsz510=nsz340+nsz170
      nszij=nsz340+1
      nsz342=nsz341+nsz85
      nsstat=-1
c
      zsort = 'table'
      call strtrm(zsort,length)
c
      my = inode
      if (my.lt.0) my = minode
c
      if (my.lt.10) then
         write(zsort(length+1:),'(i1)') my
         length = length + 1
      else if (my.lt.100) then
         write(zsort(length+1:),'(i2)') my
         length = length + 2
      else if (my.lt.1000) then
         write(zsort(length+1:),'(i3)') my
         length = length + 3
      end if
c
c...    open concurrent io  seperately for each node
c
      nsmax = 1
_IF(fcio)
_IFN1(civfu)      open(unit=nsort,file=zsort,status='unknown',iostat=irep,
_IF1(ats)     & access='direct',disp='delete',recl=nsz512*8)
_IF1(xpgdrh)     & access='direct',recl=nsz512*8)
_ENDIF(fcio)
_IFN(fortio,fcio)
      irep=0
      call opencc(zsort,length,nsort,ierrio)
      if(ierrio.ne.0)call ioerr('open',0,zsort)
_ENDIF
_IF(fortio)
      open(unit=nsort,file=zsort,status='unknown')
_IF1(x)      irep=aset(nsort,1)
_ENDIF(fortio)
      if(irep.ne.0) call caserr(
     *'error creating/opening table file')
      if(ooprnt)write(iwr,1)zsort(1:length),nsz
1     format(/
     * ' table file ',a,' allocated '/
     * '          : blockfactor =',i3, ' block(s) ')
      topen(9) = topen(9) + dclock() - dumtim
c
      return
      end
      subroutine stopbk2
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer await
_ENDIF(fortio)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
INCLUDE(common/iofile)
INCLUDE(common/blksiz2)
      common/stak2/btri,mlow(2),iblock
      if(nsstat.ge.0) then
_IF(fortio)
_IF1(x)      irep=await(nsort,icnt)
      if(irep.ne.0) then
      write(iwr,3)icnt
 3    format(/1x,'wait error on p-sort :', i6,' words transferred')
      call caserr('wait error on p-sortfile')
      endif
_ENDIF(fortio)
_IFN(fortio)
      irep = 0
_ENDIF
      nsstat=-1
      endif
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine stopbk3
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer await
_ENDIF(fortio)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
INCLUDE(common/iofile)
      common/blksi3/nsz(10),nsstat,
     *nslen,nsmax,nsort,nstid(2),oasync
      common/stak3/btri,mlow(2),iblock
      if(nsstat.ge.0) then
_IF(fortio)
_IF1(x)      irep=await(nsort,icnt)
      if(irep.ne.0) then
      write(iwr,3)icnt
 3    format(/1x,'wait error on p-sort :', i6,' words transferred')
      call caserr('wait error on p-sortfile')
      endif
_ENDIF(fortio)
_IFN(fortio)
      irep = 0
_ENDIF
      nsstat=-1
      endif
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine stopbk
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(fortio)
_IF1(x)      integer await
_ENDIF(fortio)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
INCLUDE(common/iofile)
INCLUDE(common/blksiz)
INCLUDE(common/stak)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
      dumtim = dclock()
      if(nsstat.ge.0) then
_IF(fortio)
_IF1(x)      irep=await(nsort,icnt)
      if(irep.ne.0) then
      write(iwr,3)icnt
 3    format(/1x,'wait error on sort :', i6,' words transferred')
      call caserr('wait error on sortfile')
      endif
_ENDIF(fortio)
_IFN(fortio)
      irep = 0
_ENDIF
      nsstat=-1
      endif
      if(nsmax.lt.iblock)nsmax=iblock
*     write(6,*)' stopbk, iblock, nsmax ', iblock,nsmax
      tfndtm(7) = tfndtm(7) + dclock() - dumtim
      return
      end
      subroutine sttout2
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
_IF(fortio,fcio)
_IF1(x)      integer awrite
_IFN1(x)      integer bwrite
_ENDIF(fortio,fcio)
INCLUDE(common/blksiz2)
      common/bufc/buffer(1)
      common/stak2/btri,mlow,nstack,iblock
c
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=awrite(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to p-sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      if (iblock.ne.nslen) then
         call srchcc(nsort,(iblock+1),ierrio)
         if(ierrio.ne.0)call ioerr('search',0,'psort')
      endif
      call putccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('write',0,'psort')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine sttout3(jrec)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
_IF(fortio,fcio)
_IF1(x)      integer awrite
_IFN1(x)      integer bwrite
_ENDIF(fortio,fcio)
      common/blksi3/nsz,nsz512,nsz340(8),nsstat
     * ,nslen,nsmax,nsort,nstid(2),oasync
      common/bufd/buffer(1)
      common/stak3/btri,mlow,nstack,iblock
c
      iblock=jrec
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=awrite(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to tablefile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      if (iblock.ne.nslen) then
         call srchcc(nsort,(iblock+1),ierrio)
         if(ierrio.ne.0)call ioerr('search',0,'table')
      endif
      call putccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('write',0,'table')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
      return
      end
      subroutine sttout
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
_IF(fortio,fcio)
_IF1(x)      integer awrite
_IFN1(x)      integer bwrite
_ENDIF(fortio,fcio)
      common/blksiz/nsz,nsz512,nsz340(9),nsstat
     * ,nslen,nsmax,nsort,nstid(2),oasync
      common/bufb/buffer(1)
INCLUDE(common/stak)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
c
      dumtim = dclock()
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=awrite(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      if (iblock.ne.nslen) then
         call srchcc(nsort,(iblock+1),ierrio)
         if(ierrio.ne.0)call ioerr('search',0,'sort')    
      endif
      call putccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('write',0,'sort')
_ENDIF
      nsstat=nsstat+1
      nslen=iblock+nsz
*     write(6,*)' sttout, iblock, nslen ', iblock,nslen
      tputtm(7) = tputtm(7) + dclock() - dumtim
      return
      end
_ENDIF(parallel)
_IF(fortio,fcio)
_IFN1(x)      integer function bread(nsort,irec,buffer,nword)
_IFN1(x)      implicit REAL  (a-h,o-z)
_IFN1(x)      dimension buffer(nword)
_IFN1(x)c
_IF1(a)c bread for the alliant ... differs from convex aread
_IF1(a)c currently no asynchronous I/O on alliant of any form
_IF1(a)c asynch I/O to be will be block addressable
_IFN1(x)c
_IFN1(x)      read(nsort,rec=irec,iostat=irep) buffer
_IFN1(x)      bread = irep
_IFN1(x)      return
_IFN1(x)      end
_IFN1(x)      integer function bwrite(nsort,irec,buffer,nword)
_IFN1(x)      implicit REAL  (a-h,o-z)
_IFN1(x)      dimension buffer(nword)
_IFN1(x)c
_IF1(a)c bwrite for the alliant ... differs from convex awrite
_IF1(a)c
_IFN1(x)      write(nsort,rec=irec,iostat=irep) buffer
_IFN1(x)      bwrite = irep
_IFN1(x)      return
_IFN1(x)      end
_ENDIF(fortio,fcio)
_ENDIF
_IF(ipsc) 
      subroutine closbf2(idel)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
_ENDIF(tools)
      common/blksi2/nsz(10),nsstat,
     *nslen,nsmax,nsort,nstid(2),oasync
INCLUDE(common/iofile)
INCLUDE(common/utilc)
_IF(ipsc)
      if (nsstat.ge.0.and.oasync)  then
       call iowait(nsstat)
       nsstat=-1
      endif
_ENDIF(ipsc)
      if(nsmax.ge.0) then
_IF(tools)
_IF(fortio)
       close(unit=nsort,status='delete')
_ENDIF(fortio)
_IF(fcio)
       close(unit=nsort)
_ENDIF(fcio)
_IFN(fortio,fcio)
       call closecc(nsort)
       zsort = 'psort'
      call strtrm(zsort,length)
c
      my = minode
c
      if (my.lt.10) then
         write(zsort(length+1:),'(i1)') my
         length = length + 1
      else if (my.lt.100) then
         write(zsort(length+1:),'(i2)') my
         length = length + 2
      else if (my.lt.1000) then
         write(zsort(length+1:),'(i3)') my
         length = length + 3
      end if
c      call delcc(zsort,length,ierrio)
c      if(ierrio.ne.0)call ioerr('delete',0,zsort)
_ENDIF
_ENDIF(tools)
_IF(ipsc)
      close(unit=nsort)
_ENDIF(ipsc)
      if(ooprnt)write(iwr,1)
1     format(/
_IF(fortio)
     * ' p-sortfile deleted')
_ENDIF(fortio)
_IFN(fortio)
     * ' p-sortfile closed')
_ENDIF
      nsmax = -1
      endif
      return
      end
      subroutine closbf3
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      common/blksi3/nsz(10),nsstat,
     *nslen,nsmax,nsort,nstid(2),oasync
INCLUDE(common/iofile)
INCLUDE(common/utilc)
_IF(ipsc)
      if (nsstat.ge.0.and.oasync)  then
       call iowait(nsstat)
       nsstat=-1
      endif
_ENDIF(ipsc)
      if(nsmax.gt.0) then
_IF(tools)
_IF(fortio,fcio)
       close(unit=nsort)
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
       call closecc(nsort)
_ENDIF
_ENDIF(tools)
_IF(ipsc)
      close(unit=nsort)
_ENDIF(ipsc)
      if(ooprnt)write(iwr,1)
1     format(/
     * ' table file closed')
      endif
      nsmax = 0
      return
      end
      subroutine closbf(idel)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
_ENDIF(tools)
      common/blksiz/nsz(11),nsstat,
     *nslen,nsmax,nsort,nstid(2),oasync
INCLUDE(common/iofile)
INCLUDE(common/utilc)
_IF(ipsc)
      if (nsstat.ge.0.and.oasync)  then
       call iowait(nsstat)
       nsstat=-1
      endif
_ENDIF(ipsc)
      if(nsmax.ge.0) then
_IF(tools)
_IF(fortio)
       close(unit=nsort,status='delete')
_ENDIF(fortio)
_IF(fcio)
       close(unit=nsort)
_ENDIF(fcio)
_IFN(fortio,fcio)
       call closecc(nsort)
       zsort = 'sort'
      call strtrm(zsort,length)
c
      my = minode
c
      if (my.lt.10) then
         write(zsort(length+1:),'(i1)') my
         length = length + 1
      else if (my.lt.100) then
         write(zsort(length+1:),'(i2)') my
         length = length + 2
      else if (my.lt.1000) then
         write(zsort(length+1:),'(i3)') my
         length = length + 3
      end if
c      call delcc(zsort,length,ierrio)
c      if(ierrio.ne.0)call ioerr('delete',0,zsort)
_ENDIF
_ENDIF(tools)
_IF(ipsc)
      close(unit=nsort)
_ENDIF(ipsc)
      if(ooprnt)write(iwr,1)
1     format(/
_IF(fortio)
     * ' sortfile deleted')
_ENDIF(fortio)
_IFN(fortio)
     * ' sortfile closed')
_ENDIF
      nsmax = -1
      endif
      return
      end
      subroutine rdbak(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      integer aread
_IFN1(x)      integer bread
_ENDIF(fortio,fcio)
_ENDIF(tools)
      common/blksiz/nsz,nsz512,nszz(9),nsstat
     *,nslen,nsmax,nsort,nstid(2),oasync
      common/bufb/buffer(512)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
c
      dumtim = dclock()
_IF(ipsc)
      irep = lseek(nsort,iblock*4096,0)
      if(oasync) then
       nsstat = iread(nsort,buffer,nsz*4096)
      else
       call cread(nsort,buffer,nsz*4096)
      endif
_ENDIF(ipsc)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=aread(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      call srchcc(nsort,(iblock+1),ierrio)
      if(ierrio.ne.0)call ioerr('search',0,'sort')
      call getccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('read',0,'sort')
_ENDIF
      nsstat=nsstat+1
_ENDIF(tools)
      nslen=iblock+nsz
*     write(6,*)' rdbak, iblock, nslen ', iblock,nslen
      tgettm(7) = tgettm(7) + dclock() - dumtim
      return
      end
      subroutine rdbak2(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      integer aread
_IFN1(x)      integer bread
_ENDIF(fortio,fcio)
_ENDIF(tools)
      common/blksi2/nsz,nsz512,nszz(8),nsstat
     *,nslen,nsmax,nsort,nstid(2),oasync
      common/bufc/buffer(512)
c
_IF(ipsc)
      irep = lseek(nsort,iblock*4096,0)
      if(oasync) then
       nsstat = iread(nsort,buffer,nsz*4096)
      else
       call cread(nsort,buffer,nsz*4096)
      endif
_ENDIF(ipsc)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=aread(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on p-sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      call srchcc(nsort,(iblock+1),ierrio)
      if(ierrio.ne.0)call ioerr('search',0,'psort')
      call getccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('read',0,'psort')
_ENDIF
      nsstat=nsstat+1
_ENDIF(tools)
      nslen=iblock+nsz
      return
      end
      subroutine rdbak3(iblock)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      integer aread
_IFN1(x)      integer bread
_ENDIF(fortio,fcio)
_ENDIF(tools)
      common/blksi3/nsz,nsz512,nszz(8),nsstat
     *,nslen,nsmax,nsort,nstid(2),oasync
      common/bufd/buffer(512)
c
_IF(ipsc)
      irep = lseek(nsort,iblock*4096,0)
      if(oasync) then
       nsstat = iread(nsort,buffer,nsz*4096)
      else
       call cread(nsort,buffer,nsz*4096)
      endif
_ENDIF(ipsc)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=aread(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep=bread(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('input error on tablefile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      call srchcc(nsort,(iblock+1),ierrio)
      if(ierrio.ne.0)call ioerr('search',0,'table')
      call getccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('read',0,'table')
_ENDIF
      nsstat=nsstat+1
_ENDIF(tools)
      nslen=iblock+nsz
      return
      end
      subroutine setbfa(inode)
c
c...   concurrent sortfile-io
c...   files start at 0 / sortfile starts at block
c
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
_IF(fortio)
_IF1(x)      integer aset
_ENDIF(fortio)
_ENDIF(tools)
_IF1(x)      character *44 zsort,blank
_IFN1(x)      character *1024 zsort,blank
INCLUDE(common/sizes)
      character *44 zname,zft,zzdir
      integer restrictvol,volist,defblk
      dimension volist(8),newlst(8)
INCLUDE(common/nodinf)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
_IF(ipsc)
INCLUDE(common/cfsinfo)
      character*44 zzdir
_ENDIF
      common/blksiz/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsz680,
     * nsstat,nslen,nsmax,nsort,
     * nstid(2), oasync
INCLUDE(common/atmblk)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
c
      data volist/0,1,2,3,4,5,6,7/,defblk/5000/
c
c     sort file settings
c
      dumtim=dclock()
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
      nsstat=-1
c
_IF(ipsc)
      call strtrm(zcfsdr,length)
      zzdir = '/cfs/'//zcfsdr(1:length)
      call strtrm(zzdir,length)
      length=length+1
      zzdir(length:length)='/'
      zsort=zzdir(1:length)//'sort'
_ELSE
      zsort = 'sort'
_ENDIF
      call strtrm(zsort,length)
c
      my = inode
      if (my.lt.0) my = minode
c
      if (my.lt.10) then
         write(zsort(length+1:),'(i1)') my
         length = length + 1
      else if (my.lt.100) then
         write(zsort(length+1:),'(i2)') my
         length = length + 2
      else if (my.lt.1000) then
         write(zsort(length+1:),'(i3)') my
         length = length + 3
      end if
c
c...    open concurrent io  seperately for each node
c
      irep = 0
      if (nsmax.lt.0) then
_IF(ipsc)
      numvol = restrictvol(-1,8,volist)
      if(numvol.lt.0) call caserr(
     + 'error detected in restrictvol')
      open(unit=nsort,file=zsort(1:length),
     *     form='unformatted',iostat=irep)
      if(irep.ne.0)
     *  call caserr('error creating/opening sort file')
      call setiomode(nsort,0)
        mbytes = defblk * 4096
        ibytes = lsize (nsort,mbytes,0)
        if(ibytes.lt.0) call caserr(
     +  'isize call aborted')
c
        numvol = restrictvol(nsort,-1,newlst)
        if(numvol.gt.0) then
         if (ooprnt) write(iwr,2000) 
     +    zsort(1:length),(newlst(loop),loop=1,numvol)
2000     format(1x,'sortfile ',a44/
     +          5x,'allocated to volumes ',8i6)
        else
         call caserr('error in restrictvol')
        end if
      irep = lseek(nsort,0,0)
      if (irep.ne.0) call caserr('error on 1st seek')
_ENDIF(ipsc)
_IF(tools)
_IF(fcio)
_IFN1(civfu)      open(unit=nsort,file=zsort,status='unknown',iostat=irep,
_IF1(ats)     & access='direct',disp='delete',recl=nsz512*8)
_IF1(xpgdrh)     & access='direct',recl=nsz512*8)
_ENDIF(fcio)
_IFN(fortio,fcio)
      irep=0
      call opencc(zsort,length,nsort,ierrio)
      if(ierrio.ne.0)call ioerr('open',0,zsort)
_ENDIF
_IF(fortio)
      open(unit=nsort,file=zsort,status='unknown')
_IF1(x)      irep=aset(nsort,1)
_ENDIF(fortio)
      if(irep.ne.0) call caserr(
     *'error creating/opening sort file')
_ENDIF(tools)
      if(ooprnt)write(iwr,1)zsort(1:length),nsz
1     format(/
     * ' sortfile ',a,' allocated '/
     * '          : blockfactor =',i3, ' block(s) ')
      topen(7) = topen(7) + dclock() - dumtim
      nsmax = 0
      endif
c
      return
      end
      subroutine setbfb(inode)
c
c...   concurrent sortfile-io
c...   files start at 0 / sortfile starts at block
c
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
_IF(fortio)
_IF1(x)      integer aset
_ENDIF(fortio)
_ENDIF(tools)
_IF1(x)      character *44 zsort,blank
_IFN1(x)      character *1024 zsort,blank
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
INCLUDE(common/atmblk)
_IF(ipsc)
INCLUDE(common/cfsinfo)
      character*44 zzdir
_ENDIF
      common/blksi2/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax,nsort,
     * nstid(2), oasync
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
c
      dumtim=dclock()
c
c     p-sort file settings
c
      call setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
      nsstat=-1
c
_IF(ipsc)
      call strtrm(zcfsdr,length)
      zzdir = '/cfs/'//zcfsdr(1:length)
      call strtrm(zzdir,length)
      length=length+1
      zzdir(length:length)='/'
      zsort=zzdir(1:length)//'psort'
_ELSE
      zsort = 'psort'
_ENDIF
      call strtrm(zsort,length)
c
      my = inode
      if (my.lt.0) my = minode
c
      if (my.lt.10) then
         write(zsort(length+1:),'(i1)') my
         length = length + 1
      else if (my.lt.100) then
         write(zsort(length+1:),'(i2)') my
         length = length + 2
      else if (my.lt.1000) then
         write(zsort(length+1:),'(i3)') my
         length = length + 3
      end if
c
c...    open concurrent io  seperately for each node
c
      if(nsmax.lt.0) then
_IF(ipsc)
      open(unit=nsort,file=zsort(1:length),
     *     form='unformatted',iostat=irep)
      if(irep.ne.0)
     *  call caserr('error creating/opening p-sortfile')
      call setiomode(nsort,0)
      irep = lseek(nsort,0,0)
      if (irep.ne.0) call caserr('error on 1st seek')
_ENDIF(ipsc)
_IF(tools)
_IF(fcio)
_IFN1(civfu)      open(unit=nsort,file=zsort,status='unknown',iostat=irep,
_IF1(ats)     & access='direct',disp='delete',recl=nsz512*8)
_IF1(xpgdrh)     & access='direct',recl=nsz512*8)
_ENDIF(fcio)
_IFN(fortio,fcio)
      irep=0
      call opencc(zsort,length,nsort,ierrio)
      if(ierrio.ne.0)call ioerr('open',0,zsort)
_ENDIF
_IF(fortio)
      open(unit=nsort,file=zsort,status='unknown')
_IF1(x)      irep=aset(nsort,1)
_ENDIF(fortio)
      if(irep.ne.0) call caserr(
     *'error creating/opening p-sortfile')
_ENDIF(tools)
      if(ooprnt)write(iwr,1)zsort(1:length),nsz
1     format(/
     * ' p-sortfile ',a,' allocated '/
     * '          : blockfactor =',i3, ' block(s) ')
      topen(8) = topen(8) + dclock() - dumtim
      nsmax = 0
      endif
c
      return
      end
      subroutine setbfc(inode)
c
c...   concurrent table-ci IO
c...   files start at 0 / table file starts at block
c
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
_IF(fortio)
_IF1(x)      integer aset
_ENDIF(fortio)
_ENDIF(tools)
_IF1(x)      character *44 zsort,blank
_IFN1(x)      character *1024 zsort,blank
INCLUDE(common/sizes)
INCLUDE(common/nodinf)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
_IF(ipsc)
INCLUDE(common/cfsinfo)
      character*44 zzdir
_ENDIF
      common/blksi3/nsz,nsz512,nsz340,nsz170,nsz85,
     * nszij,nszkl,nsz510,nsz341,nsz342,nsstat,nslen,nsmax,nsort,
     * nstid(2), oasync
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
c
      dumtim=dclock()
c
c     table-ci file settings
c
      nsz512=nsz*512
      nsz170=(nsz512-2)/3
      nsz85 =nsz170/2
      nszkl=nsz170+1
      nsz340=nsz170+nsz170
      nsz341=nsz340+1
      nsz510=nsz340+nsz170
      nszij=nsz340+1
      nsz342=nsz341+nsz85
      nsstat=-1
c
_IF(ipsc)
      call strtrm(zcfsdr,length)
      zzdir = '/cfs/'//zcfsdr(1:length)
      call strtrm(zzdir,length)
      length=length+1
      zzdir(length:length)='/'
      zsort=zzdir(1:length)//'table'
_ELSE
      zsort = 'table'
_ENDIF
      call strtrm(zsort,length)
c
      my = inode
      if (my.lt.0) my = minode
c
      if (my.lt.10) then
         write(zsort(length+1:),'(i1)') my
         length = length + 1
      else if (my.lt.100) then
         write(zsort(length+1:),'(i2)') my
         length = length + 2
      else if (my.lt.1000) then
         write(zsort(length+1:),'(i3)') my
         length = length + 3
      end if
c
c...    open concurrent io  seperately for each node
c
_IF(ipsc)
      open(unit=nsort,file=zsort(1:length),
     *     form='unformatted',iostat=irep)
      if(irep.ne.0)
     *  call caserr('error creating/opening table file')
      call setiomode(nsort,0)
      irep = lseek(nsort,0,0)
      if (irep.ne.0) call caserr('error on 1st seek')
_ENDIF(ipsc)
_IF(tools)
      nsmax = 1
_IF(fcio)
_IFN1(civfu)      open(unit=nsort,file=zsort,status='unknown',iostat=irep,
_IF1(ats)     & access='direct',disp='delete',recl=nsz512*8)
_IF1(xpgdrh)     & access='direct',recl=nsz512*8)
_ENDIF(fcio)
_IFN(fortio,fcio)
      irep=0
      call opencc(zsort,length,nsort,ierrio)
      if(ierrio.ne.0)call ioerr('open',0,zsort)
_ENDIF
_IF(fortio)
      open(unit=nsort,file=zsort,status='unknown')
_IF1(x)      irep=aset(nsort,1)
_ENDIF(fortio)
      if(irep.ne.0) call caserr(
     *'error creating/opening table file')
_ENDIF(tools)
      if(ooprnt)write(iwr,1)zsort(1:length),nsz
1     format(/
     * ' table file ',a,' allocated '/
     * '          : blockfactor =',i3, ' block(s) ')
      topen(9) = topen(9) + dclock() - dumtim
c
      return
      end
      subroutine stopbk2
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
_IF(fortio)
_IF1(x)      integer await
_ENDIF(fortio)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
_ENDIF(tools)
INCLUDE(common/iofile)
      common/blksi2/nsz(10),nsstat,
     *nslen,nsmax,nsort,nstid(2),oasync
      common/stak2/btri,mlow(2),iblock
_IF(ipsc)
      if (nsstat.ge.0.and.oasync)  then
       call iowait(nsstat)
       nsstat=-1
      endif
_ENDIF(ipsc)
_IF(tools)
      if(nsstat.ge.0) then
_IF(fortio)
_IF1(x)      irep=await(nsort,icnt)
      if(irep.ne.0) then
      write(iwr,3)icnt
 3    format(/1x,'wait error on p-sort :', i6,' words transferred')
      call caserr('wait error on p-sortfile')
      endif
_ENDIF(fortio)
_IFN(fortio)
      irep = 0
_ENDIF
      nsstat=-1
      endif
_ENDIF(tools)
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine stopbk3
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
_IF(fortio)
_IF1(x)      integer await
_ENDIF(fortio)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
_ENDIF(tools)
INCLUDE(common/iofile)
      common/blksi3/nsz(10),nsstat,
     *nslen,nsmax,nsort,nstid(2),oasync
      common/stak3/btri,mlow(2),iblock
_IF(ipsc)
      if (nsstat.ge.0.and.oasync)  then
       call iowait(nsstat)
       nsstat=-1
      endif
_ENDIF(ipsc)
_IF(tools)
      if(nsstat.ge.0) then
_IF(fortio)
_IF1(x)      irep=await(nsort,icnt)
      if(irep.ne.0) then
      write(iwr,3)icnt
 3    format(/1x,'wait error on p-sort :', i6,' words transferred')
      call caserr('wait error on p-sortfile')
      endif
_ENDIF(fortio)
_IFN(fortio)
      irep = 0
_ENDIF
      nsstat=-1
      endif
_ENDIF(tools)
      if(nsmax.lt.iblock)nsmax=iblock
      return
      end
      subroutine stopbk
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(tools)
_IF(fortio)
_IF1(x)      integer await
_ENDIF(fortio)
_IFN(fortio,fcio)
      common/disc/ispz(3),irep
_ENDIF
_ENDIF(tools)
INCLUDE(common/iofile)
      common/blksiz/nsz(11),nsstat,
     *nslen,nsmax,nsort,nstid(2),oasync
INCLUDE(common/stak)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
      dumtim = dclock()
_IF(ipsc)
      if (nsstat.ge.0.and.oasync)  then
       call iowait(nsstat)
       nsstat=-1
      endif
_ENDIF(ipsc)
_IF(tools)
      if(nsstat.ge.0) then
_IF(fortio)
_IF1(x)      irep=await(nsort,icnt)
      if(irep.ne.0) then
      write(iwr,3)icnt
 3    format(/1x,'wait error on sort :', i6,' words transferred')
      call caserr('wait error on sortfile')
      endif
_ENDIF(fortio)
_IFN(fortio)
      irep = 0
_ENDIF
      nsstat=-1
      endif
_ENDIF(tools)
      if(nsmax.lt.iblock)nsmax=iblock
*     write(6,*)' stopbk, iblock, nsmax ', iblock,nsmax
      tfndtm(7) = tfndtm(7) + dclock() - dumtim
      return
      end
      subroutine sttout2
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      integer awrite
_IFN1(x)      integer bwrite
_ENDIF(fortio,fcio)
_ENDIF(tools)
      common/blksi2/nsz,nsz512,nsz340(8),nsstat
     * ,nslen,nsmax,nsort,nstid(2),oasync
      common/bufc/buffer(1)
      common/stak2/btri,mlow,nstack,iblock
c
_IF(ipsc)
      if(oasync) then
       nsstat = iwrite(nsort,buffer,nsz*4096)
      else
       call cwrite(nsort,buffer,nsz*4096)
      endif
_ENDIF(ipsc)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=awrite(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to p-sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      if (iblock.ne.nslen) then
         call srchcc(nsort,(iblock+1),ierrio)
         if(ierrio.ne.0)call ioerr('search',0,'psort')
      endif
      call putccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('write',0,'psort')
_ENDIF
      nsstat=nsstat+1
_ENDIF(tools)
      nslen=iblock+nsz
      return
      end
      subroutine sttout3(jrec)
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      integer awrite
_IFN1(x)      integer bwrite
_ENDIF(fortio,fcio)
_ENDIF(tools)
      common/blksi3/nsz,nsz512,nsz340(8),nsstat
     * ,nslen,nsmax,nsort,nstid(2),oasync
      common/bufd/buffer(1)
      common/stak3/btri,mlow,nstack,iblock
c
      iblock=jrec
      irep = lseek(nsort,iblock*4096,0)
_IF(ipsc)
      if(oasync) then
       nsstat = iwrite(nsort,buffer,nsz*4096)
      else
       call cwrite(nsort,buffer,nsz*4096)
      endif
_ENDIF(ipsc)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=awrite(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to tablefile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      if (iblock.ne.nslen) then
         call srchcc(nsort,(iblock+1),ierrio)
         if(ierrio.ne.0)call ioerr('search',0,'table') 
      endif
      call putccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('write',0,'table')          
_ENDIF
      nsstat=nsstat+1
_ENDIF(tools)
      nslen=iblock+nsz
      return
      end
      subroutine sttout
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4(y)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      integer awrite
_IFN1(x)      integer bwrite
_ENDIF(fortio,fcio)
_ENDIF(tools)
      common/blksiz/nsz,nsz512,nsz340(9),nsstat
     * ,nslen,nsmax,nsort,nstid(2),oasync
      common/bufb/buffer(1)
INCLUDE(common/stak)
      common/nodtim/ tgoptm,topen(10),tfndtm(10),tgettm(10),tputtm(10)
c
      dumtim = dclock()
_IF(ipsc)
*     irep = lseek(nsort,iblock*4096,0)
      if(oasync) then
       nsstat = iwrite(nsort,buffer,nsz*4096)
      else
       call cwrite(nsort,buffer,nsz*4096)
      endif
_ENDIF(ipsc)
_IF(tools)
_IF(fortio,fcio)
_IF1(x)      ipos=iblock*512
_IF1(x)      ipos=ipos*8
_IF1(x)      irep=awrite(nsort,ipos,buffer,nsz512*8)
_IFN1(x)      irep = bwrite(nsort,iblock/nsz+1,buffer,nsz512)
      if(irep.ne.0) then
      call caserr('error in writing to sortfile')
      endif
_ENDIF(fortio,fcio)
_IFN(fortio,fcio)
      if (iblock.ne.nslen)then
         call srchcc(nsort,(iblock+1),ierrio)
         if(ierrio.ne.0)call ioerr('search',0,'sort')
      endif
      call putccn(nsort,buffer,nsz,ierrio)
      if(ierrio.ne.0)call ioerr('write',0,'sort')
_ENDIF
      nsstat=nsstat+1
_ENDIF(tools)
      nslen=iblock+nsz
*     write(6,*)' sttout, iblock, nslen ', iblock,nslen
      tputtm(7) = tputtm(7) + dclock() - dumtim
      return
      end
_ENDIF(ipsc) 
      subroutine setsrtp(nsz,o255i,
     +  nsz512,nsz340,nsz170,nsz85,nszij,nszkl,
     +  nsz510,nsz341,nsz342,nsz680)
c
c     sort file settings 
c
      implicit REAL  (a-h,p-w),integer  (i-n),logical   (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      integer nsz,nsz512,nsz340,nsz170,nsz85,nszij,nszkl
      integer nsz510,nsz341,nsz342,nsz680
      logical o255i
c
_IF(ibm)
      nsz51=nsz*512
      nsz170=(nsz51-2)/3
      nsz85=nsz170/2
      nsz340=nsz170+nsz170
      nsz512=nsz51*8
      nsz341=nsz340+1
      nsz510=nsz340+nsz170
      nsz342=nsz341+nsz85
      nszij =nsz340*4+1
      nszkl =(nsz340+nsz85)*4+1
_ELSEIF(vax)
      nsz512=nsz*512
      nsz170=(nsz512-2)/3
      nsz85=nsz170/2
      nsz340=nsz170+nsz170
      nsz680=nsz340+nsz340
      nsz341=nsz340+1
      nsz510=nsz340+nsz170
      nsz342=nsz341+nsz85
      nszij =nsz340*4+1
      nszkl =(nsz340+nsz85)*4+1
_ELSE
      nsz512=nsz*512
      if (o255i) then
       nsz170=(nsz512-2)/3
       nsz85 =nsz170/2
       nszkl=nsz170+1
       nsz340=nsz170+nsz170
       nsz680=nsz340+nsz340
       nsz341=nsz340+1
       nsz510=nsz340+nsz170
       nszij=nsz340+1
       nsz342=nsz341+nsz85
      else    
       nsz340=(nsz512-2)/2
       nsz680=nsz340+nsz340
       nsz341=nsz340+1
      endif   
_ENDIF
c
      return  
      end 
      subroutine ver_machci(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/machci.m,v $
     +     "/
      data revision /"$Revision: 5774 $"/
      data date /"$Date: 2008-12-05 00:26:07 +0100 (Fri, 05 Dec 2008) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
