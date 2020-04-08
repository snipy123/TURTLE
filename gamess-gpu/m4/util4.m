c 
c  $Author: hvd $
c  $Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
c  $Locker:  $
c  $Revision: 6176 $
c  $Source: /c/qcg/cvs/psh/GAMESS-UK/m4/util4.m,v $
c  $State: Exp $
c  
c     deck=util4
c ******************************************************
c ******************************************************
c             =   util4  =
c ******************************************************
c ******************************************************
_IF1()c
_IF1()cPS - cray would seem to only machine using these??
_IF1()c
_IF1()c_IFN(3090vf,alliant,convex,titan,apollo,sun,sgi,ipsc,rs6000,dec,hp700,ksr)
_IF(cray,ibm,vax)
      subroutine mxmaa(a,mcola,mrowa,b,mcolb,mrowb,
     >     r,mcolr,mrowr, ncol,nlink,nrow)
      implicit REAL  (a-h,o-z)
      dimension a(*),b(*),r(*)
      ir=1
      do 1 i=1,nrow
      irr = ir
      do 2 j=1,ncol
      r(irr) = 0.0d0
 2    irr = irr + mcolr
 1    ir = ir + mrowr
      call mxmb (a,mcola,mrowa,b,mcolb,mrowb,
     >      r,mcolr,mrowr, ncol,nlink,nrow )
      return
      end
_IF(ibm,vax)
      subroutine mxmbn(a,mcola,mrowa,b,mcolb,mrowb,
     *r,mcolr,mrowr,ncol,nlink,nrow)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension r(*),a(*),b(*)
      ir=1
      ib=1
      do 1 j=1,nrow
      ibb=ib
      ia=1
      do 2 k=1,nlink
      fac=b(ibb)
      if(fac)4,22,4
   4  irr=ir
      iaa=ia
      do 3 i=1,ncol
       r(irr)=r(irr)-fac*a(iaa)
      irr=irr+mcolr
   3   iaa=iaa+mcola
   22   ibb=ibb+mcolb
   2  ia=ia+mrowa
      ir=ir+mrowr
   1  ib=ib+mrowb
      return
      end
      subroutine mxm(a,nar,b,nac,c,nbc)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension a(nar,nac),b(nac,nbc),c(nar,nbc)
      call szero(c,nar*nbc)
      call mxmb(a,1,nar,b,1,nac,c,1,nar,nar,nac,nbc)
      return
      end
_ENDIF
      subroutine mxms (a,mcola,mrowa,b,mcolb,mrowb,
     >     r,mcolr,mrowr, ncol,nlink,nrow)
      implicit REAL  (a-h,o-z)
      dimension a(*),b(*),r(*)
      data nhalf/7/
      ir=1
      do 1 i=1,nrow
      irr = ir
      do 2 j=1,ncol
      r(irr) = 0.0d0
2     irr = irr + mcolr
1     ir = ir + mrowr
c
c..  decide on mxm order
      ia=1
      ias=0
      do 3 i=1,nlink
      ias = ias + nonz(ncol,a(ia),mcola)
3     ia = ia + mrowa
      ias = ias * (nrow+nhalf)
      ib=1
      ibs=0
      do 4 i=1,nrow
      ibs = ibs + nonz(nlink,b(ib),mcolb)
4     ib=ib+mrowb
      ibs = ibs * (ncol+nhalf)
      if (ias-ibs) 10,20,20
10    call mxmb (b,mrowb,mcolb, a,mrowa,mcola, r,mrowr,mcolr,
     >           nrow,nlink,ncol)
      return
20    call mxmb (a,mcola,mrowa,b,mcolb,mrowb,
     >      r,mcolr,mrowr, ncol,nlink,nrow )
      return
      end
      subroutine mxmtt(a,aa,mcol,mrow,ne,nf,b)
      implicit REAL  (a-h,o-z),integer (i-n)
      dimension aa(*),a(*),b(*)
      m=0
      n=0
      do 1 loop=1,ne
      call mxmb(a,mcol,mrow,aa(n+1),mrow,1,b(m+1),1,1,loop,nf,1)
      m=m+loop
1     n=n+mcol
       return
      end
      subroutine mxmd(a,ia,ja,b,ib,jb,r,ir,jr,i,j,k)
      implicit REAL  (a-h,o-z),integer (i-n)
       dimension a(*),b(*),r(*)
_IF1(civ)      call szero(r,i*k)
_IFN1(civ)      call vclr(r,1,i*k)
       call mxmb(a,ia,ja,b,ib,jb,r,ir,jr,i,j,k)
      return
      end
_ENDIF
      subroutine writem(w,ilifq,newbas,nnn)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
INCLUDE(common/prints)
      dimension w(*),ilifq(*)
100   format(//3x,8i14)
200   format(//12i9)
101   format(/)
102   format(7x,i3,8f14.7)
202   format(1x,i3,12f9.4)
      m=1
      m5=12
      if(oprint(20))m5=8
      n=m5
2106   if(nnn.lt.m)return
       if(n.gt.nnn)n=nnn
      if(oprint(20))write(iwr,100)(i,i=m,n)
      if(.not.oprint(20))write(iwr,200)(i,i=m,n)
      write(iwr,101)
      do 2111 j=1,newbas
      if(oprint(20))write(iwr,102)j,(w(j+ilifq(i)),i=m,n)
      if(.not.oprint(20))write(iwr,202)j,(w(j+ilifq(i)),i=m,n)
2111  continue
      m=m+m5
      n=n+m5
      goto 2106
      end
      subroutine mcstop
      implicit REAL  (a-h,o-z)
INCLUDE(common/iofile)
INCLUDE(common/prnprn)
INCLUDE(common/jobopt)
      character*10 charwall
      if (mcprin) then
       dumt = seccpu()
       write(iwr,10) dumt ,charwall()
  10   format(/1x,79('=')/
     *   ' ** mcscf ***  end of calculation at time',f9.2,' seconds',
     +        a10,' wall')
      endif
      call revind
      call clredx
      call cormon
      if (mcacct.and.odebug(31) ) call accnt(' ',3)
      return
      end
c
c---- begin yet another memory management system -----------------------
c
c     It beggars belief but the routines below implement yet another
c     memory management system (we already have the old GAMESS stack
c     management system and the MA library under the gmem stuff, shared
c     memory segments and F90 allocations). To make matters worse it is
c     completely decoupled from the gmem routine in parallel.m even
c     though it does exactly the same stuff. I do not even dare ask for
c     the reasons behind this...
c
c     In the meantime I have discovered the reasons for this and they
c     are as I feared. If this memory management system is implemented 
c     on top of the gmem stuff the code stops working. Probably this is
c     because of I/O arrangements that require that two successively 
c     allocated memory chunks take up a contiguous section of memory. 
c     This is not the case with the gmem stuff because of the memory
c     guards. The reason for such a requirement could well be down to 
c     the block directed I/O which necessitates that small data
c     structures be packed together for the efficient use of disk space.
c
      function inicor(nmaxly)
      implicit REAL  (a-h,o-z)
c
c     Initialise the common block for the memory management system.
c     It
c     1. stores the number of words available
c     2. the conversion factor between real*8 and integers,
c     3. resets the maximum memory usage to zero (lmax and lmin)
c     4. sets the current memory usage to zero
c     Finally it returns the number of words available.
c
      common /mccore/ intrel,lword,ltop,lmax,lmin
c...  ibm r*8/i*4 ==> 2    cray,cyber-205  r*8/i*8 ==> 1
      intrel=lenwrd()
c
      lmax = 0
      lmin = 0
      lword = nmaxly
      ltop=0
      inicor = lword
      return
      end
c
c-----------------------------------------------------------------------
c
      function icorim ()
      implicit REAL  (a-h,o-z)
c
c     This function returns how many integers worth of memory are still
c     free.
c
      common /mccore/ intrel,lword,ltop,lmax,lmin
      icorim = (lword - ltop) * intrel
      return
      end
c
c-----------------------------------------------------------------------
c
      function  icorrm ()
      implicit REAL  (a-h,o-z)
c
c     This function returns how many real*8 worth of memory are still
c     free.
c
      common /mccore/ intrel,lword,ltop,lmax,lmin
      icorrm = lword - ltop
      return
      end
c
c-----------------------------------------------------------------------
c
      function icori (nwor)
      implicit REAL  (a-h,o-z)
c
c     This function allocates iabs(nwor) integers of memory. The index
c     returned is to be used in the integer representation of the
c     main memory array (iq).
c
c     Note that if 
c       nwor < 0 : lmin is updated to the maximum memory usage
c       nwor > 0 : lmax is updated to the maximum memory usage
c
      character*80 amsg
      character*9 areal,aint
      common /mccore/ intrel,lword,ltop,lmax,lmin
      data areal,aint /' reals',' integers'/
c
      amsg = ' '
      amsg(1:40) =
     +   'insufficient memory available - require  '
      amsg(57:64) = '  have  '
c
      nword = iabs(nwor)
      nw = (nword+intrel-1)/intrel
      mfr = lword - ltop
      if (nw .le. mfr) then
       icori = ltop*intrel+1
       ltop=ltop+nw
       if (nwor.lt.0) lmax = max(lmax,ltop)
       if (nwor.gt.0) lmin = max(lmin,ltop)
      else
       write (amsg(65:72),'(i8)') mfr
       write (amsg(41:48),'(i8)')nw
       amsg(49:56)=areal
       if (nw.ne.nword) amsg(49:56)=aint
       call caserr(amsg)
      endif
      return
      end
c
c-----------------------------------------------------------------------
c
      function icorr (nwor)
      implicit REAL  (a-h,o-z)
c
c     This function allocates iabs(nwor) real*8 of memory. The index
c     returned is to be used in the real*8 representation of the
c     main memory array (q).
c
c     Note that if 
c       nwor < 0 : lmin is updated to the maximum memory usage
c       nwor > 0 : lmax is updated to the maximum memory usage
c
      character*80 amsg
      character*9 areal,aint
      common /mccore/ intrel,lword,ltop,lmax,lmin
      data areal,aint /' reals',' integers'/
c
      amsg = ' '
      amsg(1:40) =
     +   'insufficient memory available - require  '
      amsg(59:64) = ' have '
c
      nword = iabs(nwor)
      nw = nword
      mfr = lword - ltop
      if (nw .le. mfr) then
       icorr = ltop+1
       ltop=ltop+nw
       if (nwor.lt.0) lmax = max(ltop,lmax)
       if (nwor.gt.0) lmin = max(ltop,lmin)
      else
       write (amsg(65:76),'(i12)') mfr
       write (amsg(41:50),'(i10)')nw
       amsg(51:58)=areal
       if (nw.ne.nword) amsg(51:58)=aint
       call caserr(amsg)
      endif
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine corlsi (iad)
      implicit REAL  (a-h,o-z)
c
c     This subroutine decreases the memory usage down to the level it
c     was at before the index at iad was allocated. In this subroutine
c     it is assumed that iad refers to an integer memory segment.
c
      common /mccore/ intrel,lword,ltop,lmax,lmin
      ltop = (iad-1)/intrel
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine corlsr (iad)
      implicit REAL  (a-h,o-z)
c
c     This subroutine decreases the memory usage down to the level it
c     was at before the index at iad was allocated. In this subroutine
c     it is assumed that iad refers to an real*8 memory segment.
c
      common /mccore/ intrel,lword,ltop,lmax,lmin
      ltop = iad - 1
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine cormon
      implicit REAL  (a-h,o-z)
c
c     This subroutine prints out information on the memory usage.
c     It still is not clear to me what the wacky distinction between
c     minimum and maximum memory usage is supposed to mean.
c
      common /mccore/ intrel,lword,ltop,lmax,lmin
INCLUDE(common/iofile)
INCLUDE(common/jobopt)
      if (mcprin) write (iwr,30) lmin,lword-lmin,lmax,
     +            lword-lmax
30    format(/1x,'minimal core            =',i8,
     +' real numbers (spare core =',i8,')'
     +     /' maximum core used       =',i8,
     +' real numbers (spare core =',i8,')')
      return
      end
c
c---- end yet another memory management system -------------------------
c
      subroutine trnsps (a,b,na,nb)
      implicit REAL  (a-h,o-z)
      dimension a(na,nb),b(nb,na)
      do 10 i=1,na
      do 10 j=1,nb
   10 b(j,i)=a(i,j)
      return
      end
      function inporb (word,irep,iclef,icode,isym,logsym)
      implicit REAL  (a-h,o-z)
      logical logsym
      character*3 codes
      character *8 word
      common /drtcoc/ codes(9)
      integer dela,delb,delele,virtul,occupd,valocc,rescor,resvir
     >       ,frozen,valvir,opensh,multi,speshl,multrf,valenc
     >       ,fzc,fzv,cor,vir,doc,uoc,alp,bet,spe
      common /drtcod/ ncodes,dela(9),delb(9),delele(9)
     1,               ntypes,virtul,occupd,valocc,rescor,resvir,frozen
     2,               valvir,opensh,multi,speshl,multrf,valenc
     3,   fzc, fzv, cor, vir, doc, uoc, alp, bet, spe
      character*1 ldigit(10),iprcnt,islash
      data ldigit/'0','1','2','3','4','5','6','7','8','9'/
      data iprcnt,islash /'%','/'/
      inporb=-1
      logsym=.true.
      isym=0
      if (word.eq.'end     ') return
      inporb=0
      ipos=1
      irep=0
10    do 20  n=1,10
      if (word(ipos:ipos).eq.ldigit(n)) goto 30
20    continue
      goto 40
30    irep=irep*10+n-1
      ipos=ipos+1
      goto 10
40    if (irep.eq.0) irep=1
      if(word(ipos:ipos).eq.iprcnt.or.word(ipos:ipos).eq.islash) goto 50
      iclef=1
      goto 60
50    if (word(ipos:ipos).eq.'/') iclef = multrf
      if (word(ipos:ipos).eq.'%') iclef = valenc
      ipos=ipos+1
60    continue
      ipos=ipos+3
      do 70 icode=1,ncodes
      if (word(ipos-3:ipos-1).eq.codes(icode)) goto 80
70    continue
      call caserr('error in processing orbital code')
80    continue
      do 90 n=1,10
      if (word(ipos:ipos).eq.ldigit(n)) goto 100
90    continue
      logsym=.false.
      return
100   isym=n-1
      return
      end
      subroutine outive (ip,ib,title)
      implicit REAL  (a-h,o-z)
      character*(*) title
INCLUDE(common/iofile)
      dimension ip(*)
      character*10 format
      data format /'(''0'',a000)'/
      write (format(7:9),'(i3)') 55+len(title)/2
      write(iwr,format) title
      m=1
      n=14
10    if (ib.lt.m) return
      n=min(n,ib)
      write(iwr,20) m,n,(ip    (i) ,i=m,n)
      m=m+14
      n=n+14
      goto 10
20    format(i5,'-',i3,14i8)
      end
      subroutine outsqv (q,idim,ia,ib,title)
      implicit REAL  (a-h,o-z)
      character*(*) title
INCLUDE(common/iofile)
      dimension q(idim,ib)
      character*14 format
      data format /'(/1x,a000,i4/)'/
      write (format(7:9),'(i3)') 55+len(title)/2
      do 20 m=1,ib
      write(iwr,format) title,m
20    write(iwr, 10)(q(i,m),i=1,ia)
10    format(1x,10f12.6)
      return
      end
      subroutine outsqr (q,idim,ia,ib,title)
      implicit REAL  (a-h,o-z)
      character*(*) title
INCLUDE(common/iofile)
      dimension q(idim,ib)
      character*10 format
      data format /'(''0'',a000)'/
      write (format(7:9),'(i3)') 55+len(title)/2
      write(iwr,format) title
      m=1
      n=8
10    if (ib.lt.m) return
      n=min(n,ib)
      write(iwr,30) (i,i=m,n)
      write(iwr,40)
      do 20 j=1,ia
      write(iwr,50) j,(q    (j,i) ,i=m,n)
20    continue
      m=m+8
      n=n+8
      goto 10
30    format(//3x,8i14)
40    format(/)
50    format(7x,i3,8f14.7)
      end
      subroutine outvec (p,ib,title)
      implicit REAL  (a-h,o-z)
      character*(*) title
INCLUDE(common/iofile)
      dimension p(*)
_IFN(convex,apollo,sgi,ipsc,rs6000,hp700,hpux11)
      character*10 format
      data format /'(''0'',a000)'/
      write (format(7:9),'(i3)') 55+len(title)/2
      write(iwr,format) title
_ENDIF
_IF(convex,apollo,sgi,ipsc,rs6000,hp700,hpux11)
      write(iwr,'(1h0,5x,a)') title(1:len(title))
_ENDIF
      m=1
      n=8
10    if (ib.lt.m) return
      n=min(n,ib)
      write(iwr,20) m,n,(p    (i) ,i=m,n)
      m=m+8
      n=n+8
      goto 10
20    format(i5,'-',i3,8f14.7)
      end
      subroutine accnt (anam,icode)
      implicit REAL  (a-h,o-z)
      character*8 aname,aname1,aname2,defnam,title,titleu
      character*(*) anam
INCLUDE(common/iofile)
      common /accntc/ aname1(20),aname2(20,10),defnam
      common /accnti/ icall1(20),icall2(20,10)
     2               ,iac(5,20,10),iacini(5),iacl(5),idate
     3               ,n1,n2(20),i1,i2
      dimension iacnow(5),iactot(5),iacto1(5),iacto2(5),actot(5)
      dimension actot1(5),title(5),titleu(5)
      data title/'     cpu','    disc','    tape','res unit',' elapsed'/
      datatitleu/'     ---','    ----','    ----','--------',' -------'/
      data max1,max2,naccnt /20,10,5/
      aname = anam
      if (icode.eq.0) goto 250
      if (aname.eq.'        ') aname = defnam
c..   close off current channel
      if (iaccnt(iacnow).ne.idate) iacnow(5)=iacnow(5) + 3600*24
      do 10 k=1,naccnt
10    iac (k,i1,i2) = iac (k,i1,i2) - iacl(k) + iacnow(k)
      goto (20,70,120), icode
c...  major channel begins
20    i2 = 1
      do 30 i1=1,n1
      if (aname.eq.aname1(i1)) goto 50
30    continue
      if (n1.eq.max1) call caserr('too many major channels')
      n1 = n1 + 1
      i1 = n1
      icall1(i1) = 0
      icall2(i1,1) = 0
      aname1(i1) = aname
      aname2(i1,i2) = defnam
      n2(i1) = 1
      do 40 k=1,naccnt
40    iac (k,i1,i2) = 0
50    do 60 k=1,naccnt
60    iacl(k) = iacnow(k)
      if (i1.gt.1) icall1(i1) = icall1(i1) + 1
      return
c...  minor channel begins
70    nn = n2(i1)
      do 80 i2=1,nn
      if (aname.eq.aname2(i1,i2)) goto 100
80    continue
      if (nn.eq.max2) call caserr('too many minor channels')
      n2(i1) = nn+1
      i2 = n2(i1)
      icall2(i1,i2) = 0
      aname2(i1,i2) = aname
      do 90 k=1,naccnt
90    iac(k,i1,i2) = 0
100   do 110 k=1,naccnt
110   iacl(k) = iacnow(k)
      if (i2.gt.1) icall2(i1,i2) = icall2(i1,i2) + 1
      return
c
c...  final processing if icode.eq.3
120   continue
c..   first get totals and eliminate functions not used
      k = 1
      do 140 kk=1,naccnt
      do 130 i1=1,n1
      nn = n2(i1)
      do 130 i2=1,nn
130   iac(k,i1,i2) = iac(kk,i1,i2)
      iacnow(k) = iacnow(kk)
      iacini(k) = iacini(kk)
      actot(k) =  dfloat(iacnow(k) - iacini(k))/100.0d0
      title(k) = title(kk)
      titleu(k) = titleu(kk)
      if (actot(k) .gt. 1.0d-6) k = k+1
140   continue
      nactmp = k-1
      write(iwr,150) (title(k),k=1,nactmp)
 150  format(//1x,104('*')//
     *       ' resource use information'
     1/      ' ------------------------'/
     2      /27x,'calls',4x,5(a8,7x)/)
      write(iwr,160) (titleu(k),k=1,nactmp)
160   format(27x,'-----',4x,5(a8,7x)/)
c
c...   summarise major channels
      do 230 i11=1,n1
      i1 = i11 + 1
      if (i11.eq.n1) i1 = 1
      nn = n2(i1)
      do 170 k=1,nactmp
      iactot(k)=0
      do 170 i2=1,nn
170   iactot(k) = iactot(k) + iac (k,i1,i2)
c..   normalise major totals to whole calc
      do 180 k=1,nactmp
      actot1(k) =  dfloat(iactot(k))
180   iactot(k) = actot1(k)/actot(k) + .5d0
      write(iwr,190) aname1(i1),icall1(i1),(iactot(k),k=1,nactmp)
190   format(' ',a8,18x,i5,4x,5(i7,'%',7x))
      do 220 i22=1,nn
      i2 = i22 + 1
      if (i22.eq.nn) i2 = 1
      do 200 k=1,nactmp
      iacto1(k) = 0
      if(actot1(k).gt.1d-6)iacto1(k) =
     1       ( dfloat(iac(k,i1,i2))/actot1(k))*100.0d0+.5d0
200   iacto2(k) =  dfloat(iac(k,i1,i2)) / actot(k)  + .5d0
      if (nn.gt.1) write(iwr,210) aname2(i1,i2),icall2(i1,i2)
     1              ,(iacto1(k),iacto2(k),k=1,nactmp)
210   format(11x,a8,8x,i5,4x,5(i3,'%,',i2,'%',7x))
220   continue
230   continue
      write(iwr,240) (actot(k),k=1,nactmp)
240   format(' totals:',21x,5 (f15.1) )
      return
c
c...  initialisation for icode.eq.0
250   n1=1
      i1=1
      n2(1)=1
      i2=1
      aname1(1)=aname
      aname2(1,1)=aname
      do 260 k=1,naccnt
260   iac(k,1,1) = 0.0d0
      idate = iaccnt(iacl)
      do 270 k=1,naccnt
270   iacini(k) = iacl(k)
      defnam = aname
      icall1(1) = 0
      icall2(1,1) = 0
      return
      end
      function iaccnt (iac)
      implicit REAL  (a-h,o-z)
      integer iac(5)
      iaccnt=0
      do 10 i=2,4
10    iac(i) = 0
      times=seccpu()
      iac(1) = times*100.0d0
      call walltime(timec)
      iac(5) = timec*100.0d0
      return
      end
      subroutine outtri (r,ia,title)
      implicit REAL  (a-h,o-z)
      character*(*) title
INCLUDE(common/iofile)
      dimension r(*),iwork(8)
      character*10 format
      data format /'(''0'',a000)'/
      ind(i,j) = max(i,j)*(max(i,j)-1)/2 + min(i,j)
      write (format(7:9),'(i3)') 55+len(title)/2
      write(iwr,format) title
      m=1
      n=8
10    if (ia.lt.m) return
      n=min(n,ia)
      write(iwr,40) (i,i=m,n)
      write(iwr,50)
      do 30 j=1,ia
      do 20 i=1,n-m+1
20    iwork(i) = ind(j,i+m-1)
      write(iwr,60) j,(r(iwork(i)),i=1,n-m+1)
30    continue
      m=m+8
      n=n+8
      goto 10
40    format(//3x,8i14)
50    format(/)
60    format(7x,i3,8f14.7)
      end
      subroutine orth (n,v,w)
      implicit REAL  (a-h,o-z)
      dimension v(*),w(*)
      ovlap = -ddot(n,v,1,w,1)
      call daxpy(n,ovlap,w,1,v,1)
      return
      end
      function nonz(n,a,incr)
      implicit REAL  (a-h,o-z)
      dimension a(*)
      nonz=0
      ii=1
      do 1 i=1,n
      if(a(ii).ne.0.0d0)nonz=nonz+1
   1  ii=ii+incr
      return
      end
      subroutine prisq(q,ipos,isym,np,string,nr)
      implicit REAL  (a-h,o-z)
      character*(*) string
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/multic)
INCLUDE(common/syminf)
      dimension ipos(8),q(*)
      write(iwr,5)string,nr
5      format(/' Operator    ',a8,i7)
       do 100 is=1,nirrr
       js=mults(is,isym)
       if(js.gt.is.and.np.ne.0) goto 100
       n=nsymm(is)
       m=nsymm(js)
       if(n.eq.0.or.m.eq.0) goto 100
       write(iwr,10)is,js
10     format(/1x,'block   ',i1,'.',i1)
       ia=ipos(is)-1-n
       do 20 i=1,n
       ia=ia+1
20     write(iwr,30)(q(ia+j*n),j=1,m)
30     format(1x,10f12.6)
100    continue
       return
       end
      subroutine intou (q,len)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/mcff)
      common /intbuf/ intpos,intfil,intmod,intnw,g(511)
      dimension q(*)
c      call outvec (q,len,'intout vector',13)
      iq=1
      left=len
      if (intpos.gt.0) goto 10
      intmod=-1
      call search (iblf,intfil)
      intpos=1
10    lnow=min(left,512-intpos)
      call fmove (q(iq),g(intpos),lnow)
      iq=iq+lnow
      intpos=intpos+lnow
      left=left-lnow
      if (intpos.lt.512) return
      call put (g,511,intfil)
      intpos=1
      if (left.gt.0) goto 10
      return
      end
      subroutine intend
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/mcff)
      common /intbuf/ intpos,intfil,intmod,intnw,g(511)
      if (intmod.ge.0) goto 20
      if (intpos.gt.1) call put (g,511,intfil)
      call put (g,0,intfil)
      intmod=0
      intpos=1
      return
20    if (intmod.eq.1) call get(g,intnw)
      return
      end
      subroutine intin (q,len)
_IF1()cjk
_IF1()cjk Bugfix for bug 94-3
_IF1()cjk Abort in MCSCF
_IF1()cjk two routines intin.f and intin2.f
_IF1()cjk Bug occurs 'cos call to caserr at label 40, even when there were no
_IF1()cjk more integrals to process in the file.  The 'fix' is crude as 
_IF1()cjk the test was simply removed.
_IF1()cjk
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/mcff)
      common /intbuf/ intpos,intfil,intmod,intnw,g(511)
      dimension q(*)
cjk
cjk      write(iwr,57) intpos,intfil,intmod,intnw
cjk57    format('enter intin',4i8)
      iq=1
      left=len
      if (intpos.gt.0) goto 30
      intpos=1
      call search (iblf,intfil)
      call find (intfil)
      call get (g,intnw)
      if (intnw.eq.0) call caserr('intin: 1 end of file reached')
      intnw=intnw+1
      if (intmod.eq.1) call find (intfil)
30    lnow=min(left,intnw-intpos)
cjk
cjk      write(iwr,*) iq,intpos,left,lnow,intnw,len
      call fmove (g(intpos),q(iq),lnow)
      iq = iq + lnow
      intpos=intpos+lnow
      left=left-lnow
      if (intpos.lt.intnw) goto 50
      if (intmod.eq.0) call find(intfil)
      call get(g,intnw)
cjk40    if (intnw.eq.0) call caserr('intin: 2 end of file reached')
      intnw=intnw+1
      if (intmod.eq.1) call find(intfil)
      intpos=1
      if (left.gt.0) go to 30
50    continue
c      call outvec (q,len,'intin vector',12)
      return
      end
      subroutine ver_util4(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/util4.m,v $
     +     "/
      data revision /"$Revision: 6176 $"/
      data date /"$Date: 2010-08-10 16:49:47 +0200 (Tue, 10 Aug 2010) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
