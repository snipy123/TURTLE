_IF(hpux11)
c$HP$ OPTIMIZE ASSUME_NO_PARAMETERS_OVERLAPS OFF
_ENDIF
c     deck=util1
c ******************************************************
c ******************************************************
c             =   util1  =
c ******************************************************
c ******************************************************
      subroutine input
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c.... this routine reads a data card and scans it for non - space fields
c    the number of fields is stored in jump, the starting point of a
c    field in istrt(i) and the number of characters in that field
c    in inumb(i).
INCLUDE(common/workc)
INCLUDE(common/work)
INCLUDE(common/iofile)
INCLUDE(common/prints)
      dimension xchar(4),ncol(mxtoken),xcol(2),xprin(132)
      character*132 char2c
_IF1()     data xblnk,xstp,xcol,xtab/' ','.',':','/','	'/
_IF1()     data nchar,xchar/4,'*','?','>','<'/
_IF(doublebackslash)
      data xblnk,xstp,xcol,xtab/' ','.',':','\\','\t'/
_ELSE
      data xblnk,xstp,xcol,xtab/' ','.',':','\','	'/
_ENDIF
      data nchar,xchar/4,'#','?','>','<'/
      data xcomma,xequal/',','='/
c
      nline=nline+1
      if(nline.le.noline)go to 150
      if(oswit) call caserr2('unexpected end of data file')
 100  read(ird,'(a132)',end=300)char2
c
c     Replace any tab-characters with spaces to ensure proper detection
c     of white-space
c
      do i=1,len(char2)
         if (char2(i:i).eq.xtab) char2(i:i)=xblnk
      enddo
c
c     If the input is to be echoed to the output then print the input
c     line here.
c
      last = lstchr(char2)
      if (oecho.and.opg_root()) then
       do i = 1, last
        xprin(i) = char2(i:i)
       enddo
       write(iwr,400) (xprin(i),i=1,last)
 400   format(1x,'>>>>> ', 132a1)
      endif
      if (last.eq.0) goto 100
c
c     If this line is a comment then decide whether to print it or not
c     and subsequently skip to the next input line (i.e. go to 100).
c
      do i=1,nchar
         if(char2(1:1).eq.xchar(i))go to 110
      enddo
      go to 80
 110  char1(1:131)=char2(2:132)
      if(opg_root().and..not.oecho)write(iwr,90)char1
 90   format(/
     *' comment :-',1x,a79)
      go to 100
 80   k=jwidth
c
c     char2c preserves the case of input strings, this is required
c     for things such as file names which are case sensitive
c
      char2c = char2
      call lcase(char2(1:132))
c
      mark=0

      do 130 i=1,jwidth
        if(char2(i:i).ne.xcol(1).and.
     +     char2(i:i).ne.xcol(2)) go to 130
        mark=mark+1
        if (mark.gt.mxtoken) then
          call caserr("mxtoken exceeded, too many tokens on input line")
        endif
        ncol(mark)=i
 130  continue
      noline=1
      if(mark.ne.0)go to 140
      if (noline.gt.mxtoken) then
        call caserr("mxtoken exceeded, too many tokens on input line")
      endif
      nstart(noline)=1
      nend(noline)=jwidth
      go to 200
 140  i=ncol(mark)+1
      if(i.le.jwidth) then
       do j=i,jwidth
        if(char2(j:j).ne.xblnk) go to 170
       enddo
      endif
      k=ncol(mark)-1
      mark=mark-1
c
 170  noline=mark+1
      if (mark.ge.mxtoken) then
        call caserr("mxtoken exceeded, too many tokens on input line")
      endif
      nstart(1)=1
      do i=1,mark
        j=ncol(i)
        nend(i)=j-1
        nstart(i+1)=j+1
      enddo
      if (noline.gt.mxtoken) then
        call caserr("mxtoken exceeded, too many tokens on input line")
      endif
      nend(noline)=k
 200  nline=1
c
 150  jump=0
      jrec=0
      isw=0
      if (nline.gt.mxtoken) then
        call caserr("mxtoken exceeded, too many tokens on input line")
      endif
      nbegin=nstart(nline)
      nfini=nend  (nline)
      iwidth=nfini-nbegin+1
      char1(1:iwidth)=char2(nbegin:nfini)
      char1c(1:iwidth)=char2c(nbegin:nfini)
c
c...   allow comments preceeded by ! like fortran (surrounded by blanks)
c
      do i=iwidth-1,2,-1
         if (char1(i:i).eq.'!'.and.char2(i+1:i+1).eq.' '
     1                        .and.char2(i-1:i-1).eq.' ') then
            iwidth = i-1
            go to 101
         end if
      end do
101   continue
c
c     pad the line from the last character onwards with spaces
c
      j=iwidth+1
      if (j.lt.132) then
        do i=j,132
          char1c(i:i)=xblnk
          char1(i:i)=xblnk
        enddo
      endif
c
c     find all the space separated tokens
c
      do 40 i = 1,iwidth
        if(char1(i:i).eq.xblnk)go to 30
        if(char1(i:i).eq.xcomma)go to 30
        if(char1(i:i).eq.xequal)go to 30

        mark=ichar(char1(i:i))
        if(mark.eq.13)goto 30

        if (isw.le.0) then
          jump = jump +1
          if (jump.gt.mxtoken) then
            call caserr(
     +      "mxtoken exceeded, too many tokens on input line")
          endif
          istrt(jump) = i
          inumb(jump) = 0
          isw=1
        endif
        if (jump.gt.mxtoken) then
          call caserr("mxtoken exceeded, too many tokens on input line")
        endif
        inumb(jump) = inumb(jump) + 1
        go to 40
30      isw = 0
40    continue
      return
c
 300  oswit=.true.
      jump=0
      jrec=0
      return
      end
      subroutine errout(n)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/workc)
INCLUDE(common/work)
INCLUDE(common/iofile)
      data xpt,xstp/    '*','.'/
      jrec=-1
      write(iwr,50)char1
50    format(1x,a132)
      do 60 i=1,iwidth
60    char1(i:i)=xstp
      char1(n:n)=xpt
      write(iwr,50)char1
      return
      end
      subroutine outrec
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character *132 char
INCLUDE(common/workc)
INCLUDE(common/work)
INCLUDE(common/iofile)
c
      char=char1(1:iwidth)
      write(iwr,50)char
50    format(1x,a132)
      return
      end
      subroutine inpa(zguf)
c.... this routine examines the contents of char1  and extracts a
c    character string of 8 chars. this string is stored in iguf .
c    characters beyond the eighth in any field are ignored
c      dimension ibuf(8)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/workc)
INCLUDE(common/work)
      data xblnk/' '/
c
      jrec = jrec + 1
      zguf = xblnk
      if(jrec .gt. jump) return
      n = inumb(jrec)
      if(n.gt.8)n=8
      zguf = char1(istrt(jrec):istrt(jrec)+n-1)
c
      return
      end
      subroutine lcase(string)
      character*(*) string
c
c...  convert to lower case (use ascii table)
c
_IFN(ibm,cray)
      ll = len(string)
      do 125 i=1,ll
         mark = ichar(string(i:i))
         if (mark.ge.65.and.mark.le.90) string(i:i) = char(mark+32)
125   continue
_ENDIF
_IF(cray)
      ll = len(string)
      ma = ichar('A')
      mz = ichar('Z')
      md = ichar('a') - ichar('A')
      do 125 i=1,ll
        mark = ichar(string(i:i))
        if (mark.ge.ma.and.mark.le.mz) string(i:i) = char(mark+md)
125   continue
_ENDIF
c
      return
      end
      subroutine inpan(zguf)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*(*) zguf
INCLUDE(common/workc)
INCLUDE(common/work)
      data xblnk/' '/
      jrec = jrec + 1
      nguf=len(zguf)
      zguf = xblnk
      if(jrec .gt. jump) return
      n = inumb(jrec)
      if(n.gt.nguf)n=nguf
      zguf = char1(istrt(jrec):istrt(jrec)+n-1)
c
      return
      end
c
c inpan variant preserving input case
c
      subroutine inpanpc(zguf)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*(*) zguf
INCLUDE(common/workc)
INCLUDE(common/work)
      data xblnk/' '/
      jrec = jrec + 1
      nguf=len(zguf)
      zguf = xblnk
      if(jrec .gt. jump) return
      n = inumb(jrec)
      if(n.gt.nguf)n=nguf
      zguf = char1c(istrt(jrec):istrt(jrec)+n-1)
c
      return
      end
      subroutine inpa4(yguf)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/workc)
INCLUDE(common/work)
      data xblnk/' '/
      jrec = jrec + 1
      yguf = xblnk

      if(jrec .gt. jump) return
      n = inumb(jrec)
      if(n.gt.4)n=4
      yguf = char1(istrt(jrec):istrt(jrec)+n-1)
c
      return
      end
_IF(drf)
      subroutine inpal(zguf)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*(*) zguf
INCLUDE(common/workc)
INCLUDE(common/work)
      data xblnk/' '/
      jrec = jrec + 1
      nguf=len(zguf)
      zguf = xblnk
      if(jrec .gt. jump) return
c     n = inumb(jrec)
      n = inumb(jump)
      if(n.gt.nguf)n=nguf
      zguf = char1(istrt(jrec):istrt(jump)+n-1)
      jrec = jump 
c
      return
      end
      subroutine incon
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*8 idir,ivar
INCLUDE(../drf/comdrf/sizescon)
INCLUDE(common/connolly)
INCLUDE(common/work)
INCLUDE(../drf/comdrf/drfin)
INCLUDE(common/iofile)
c     common/drf_un/indstg,indstmn,indstmx,
c    1 inbndr,inbndl,ind,inrp
      dimension idir(4)
c
      data idir/'spdens','mxsurpts','mnsurpts','rprobe'/
c defaults
      d=1.0d0
      rp=1.0d0
cxxx  nmaxcon=0
cxxx  isurdens=.true.
      nmaxcon=200
      isurdens=.false.
      iminpoint=.false.
      isetden = 0
      isetmax = 0
10    if (jrec.ge.jump) goto 100
      call inpa(ivar)
      i=locatc(idir,4,ivar)
      if (i.eq.0) call caserr2(
     +    'unknown parameter in Connolly directive')
      goto(20,30,40,50) , i
20    call inpf(d)
      isurdens=.true.
      isetden = 1
      insp = 1
      go to 10
30    call inpi(nmaxcon)
      isetmax = 1
      go to 10
40    call inpi(nmincon)
      iminpoint=.true.
      go to 10
50    call inpf(rp)
      inrp = 1
      inpro = 1
      go to 10
100   continue
      if ((isetden .eq. 1) .and. (isetmax .eq. 1))
     + call caserr2
     + ('either specify surface point density OR maximum no. of points') 
      if (nmincon .ge. nmaxcon) then
        write(iwr,1001) nmaxcon
 1001   format(/,' Input error: you may not set mnsurpts >=',
     1  ' mxsurpts= ',i4)
        call caserr2('Connolly input error detected')
      endif
      return
      end 
      subroutine indiel(rfsurf)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*8 idir,ivar,surftyp,outdiel
      character*4 dielopt1, dielopt2
      character*10 rfsurf
INCLUDE(common/sizes)
INCLUDE(../drf/comdrf/sizescon)
INCLUDE(../drf/comdrf/drfpar)
INCLUDE(../drf/comdrf/drfbem)
INCLUDE(common/connolly)
INCLUDE(common/work)
INCLUDE(../drf/comdrf/drfin)
      dimension idir(14)
c
      data idir/'surface','solvent','dieltyp',
     1          'epsstat','epsopt','kappas','kappao',
     2          'sradius','bemlev','dielout','connolly',
     3          'juffer','solvrad','end'/
c defaults
      ibem=5
      rfsurf='connolly'
      solnam='x'
      eps1=1.0d0
      eps2=1.0d0
      kappa1=0.0d0
      kappa2=0.0d0
      itwoeps = 0
      ioponly = 0
      spherad = 1000.0d0
      levelo = 0
      ibemout = 0
      d=1.0d0
      rp=1.0d0
      solrad=-1.0d0
cxxx  nmaxcon=0
cxxx  isurdens=.true.
      nmaxcon=200
      isurdens=.false.
      isetden = 0
      isetmax = 0
      swidth = -1.0d0
      sdist = -1.0d0
      rprobej = 1.0d0
10    continue
      call input
      if (idrfout .ge. 1) call outrec
cxxxx if (jrec.ge.jump) goto 200
      call inpa(ivar)
      i=locatc(idir,14,ivar)
      if (i.eq.0) 
     1  call caserr2('unknown parameter in Dielectric directive')
      goto(20,30,40,50,60,70,80,90,100,110,120,130,140,150) , i
20    call inpa(surftyp)
      if (surftyp .eq. 'sphere') then
        ibem = 4
      elseif (surftyp .eq. 'juffer') then
        ibem = 3
        rfsurf = 'juffer'
      elseif (surftyp .eq. 'connolly') then
        ibem = 5
        rfsurf = 'connolly'
      else
        call caserr2('unknown option in Surface directive')
      endif
      go to 10
30    call inpan(solnam)
      go to 10
40    call inpa4(dielopt1)
      call inpa4(dielopt2)
      istat = 1
      ioptic = 0
      if ((dielopt1 .ne. 'stat') .and. (dielopt2 .ne. 'stat')) istat=0
      if ((dielopt1 .eq. 'opt') .or. (dielopt2 .eq. 'opt')) ioptic=1
      if ((istat .eq. 0) .and. (ioptic .eq. 1)) ioponly = 1
      if ((istat .eq. 1) .and. (ioptic .eq. 1)) itwoeps = 1
      go to 10
50    call inpf(eps1)
      if (eps1 .lt. 1.0d0) eps1=1.0d0
      go to 10
60    call inpf(eps2)
      if (eps2 .lt. 1.0d0) eps2=1.0d0
      go to 10
70    call inpf(kappa1)
      if (kappa1 .lt. 0.0d0) kappa1=0.0d0
      go to 10
80    call inpf(kappa2)
      if (kappa2 .lt. 0.0d0) kappa2=0.0d0
      go to 10
90    call inpf(spherad)
      insphr = 1
      go to 10
100    call inpi(levelo)
      go to 10
110    call inpa(outdiel)
       if (outdiel .eq. 'standard') then
         ibemout = 0
       elseif (outdiel .eq. 'some') then
         ibemout = 2
       elseif (outdiel .eq. 'moderate') then
         ibemout = 5
       elseif (outdiel .eq. 'extended') then
         ibemout = 10
       elseif (outdiel .eq. 'all') then
         ibemout = 100
       else
         call caserr2('unknown parameter in Dielout directive')
       endif
      go to 10
120    call incon
      go to 10
130    continue
 135   if (jrec.ge.jump) goto 136
         call inpa(outdiel)
       if (outdiel(1:7) .eq. 'cylwdth') then
         call inpf(swidth)
         insw = 1
       else if (outdiel(1:8) .eq. 'surfdist') then
         call inpf(sdist)
         insd = 1
       else if (outdiel(1:6) .eq. 'rprobe') then
         call inpf(rprobej)
         inprj = 1
       else
         call caserr2('unknown parameter in Juffer directive')
       endif
        go to 135
 136   continue
      go to 10
140   call inpf(solrad)
      insr = 1
      go to 10
150   continue
200   continue
      rprobe = rp
      if ((solnam .eq. 'x') .and. (solrad .lt. 0.0d0)) then
        solrad = 0.0d0
      endif
      if ((ioponly .eq. 1).and.(eps2 .ne. 1.0d0)) eps1 = eps2
      if ((ioponly .eq. 1).and.(kappa2 .ne. 0.0d0)) kappa1 = kappa2
      return
      end

      subroutine inmontec
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*8 idir,ivar
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(../drf/comdrf/sizesrf)
INCLUDE(../drf/comdrf/mcener)
INCLUDE(../drf/comdrf/mcinp)
INCLUDE(common/workc)
INCLUDE(common/work)
INCLUDE(../drf/comdrf/rota)
INCLUDE(../drf/comdrf/runpar)
INCLUDE(../drf/comdrf/drfpar)
INCLUDE(../drf/comdrf/clas)
INCLUDE(../drf/comdrf/drfbem)

c
c-----  namelist $montec input parameters                 default
c
c       imcout : printflag for mc+rf+bem method               0
c       iseed  : seed for random generator              1234567
c       imcst  : number of states in monte carlo calculation  1
c       (maximum 5; may be altered by setting mxst in drf/dimpar)
c       iguess(mxst) : guess option for different states      5*0
c          options:
c             0: use standard guess (current density etc..
c                present on da10) for state ist
c             1: read guess from da10, collected in previous
c                calculations according to rank number of
c                the state (this is the user's responsibility)
c       ***note***
c       this means that state number ist in the monte carlo was
c       given nset=ist in $guess in a separate calculation on
c       this state!!!!
c
c       gmdrf(mxst): dispersion scaling parameter gamdrf for
c                    different states                         5*gamdrf
c                    cf. gamdrf in rfin
c
c       nsamp  : number of samples                            1
c       nblock : number of blocks in each sample              1
c       nmoves : number of attempted moves in each block      1
c       ncheck : number of moves to check acceptance after    0
c                too low or too high an acceptance will lead
c                to the adaptation of darot and dtrans
c                ncheck = 0 means do not perform this check
c                ncheck < 100 or > 10000 will lead to a warning
c       ratmax : maximum acceptance ratio if ncheck > 0      .5
c       ratmin : minimum acceptance ratio if ncheck > 0      .5
c       darot  : maximum rotation step at beginning of run
c                (in radians)                                .15 (13.5 d
c       dtrans : maximum translation step at beginning of run
c                (in au)                                     .45
c       amxrot : maximum rotation step during run
c                (in radians) (if ncheck > 0)                 1. (90 deg
c       amxtrn : maximum translation step during run
c                (in au) (if ncheck > 0 and notrans = 0)      2.
c       amnrot : minimum rotation step during run
c                (in radians) (if ncheck > 0)                 .01 (0.9 d
c       amntrn : minimum translation step during run
c                (in au) (if ncheck > 0 and notrans = 0)      .001
c       temp   : temperature (k)                              298.15
c       excld  : exclusion distance (only when ibem .ne. 0)   7.3
c                (default is the value for water)
c       delmax : maximum energy drop in monte carlo step     -0.01 hartr
c       enmin  : minumum energy threshold                    -1.0d+10 h
c       (if the computed energy is lower, the move will be rejected)
c
c       the last two flags are ad-hoc measures to prevent spurious
c       configurations
c
      dimension idir(21)
      character*8 errmsg(3)
c
c     data gmdrf/5*-1.0d0/
      data errmsg /'program','stop in','inmontec'/
      data nsmax,nblmax,nmovmax /10,10,10000/
      data drotmax /1.0/
c     data iguess /5*0/
      data idir/'imcout','iseed','imcst','nsamp',
     1          'nblock','nmoves','drot','dtrans',
     2          'ncheck','ratmin','ratmax','amnrot',
     3          'amxrot','amntrn','amxtrn','excld',
     4          'outfor','gmdrf','delmax','enmin',
     5          'end'/
c defaults
      do i=1,mxst
         gmdrf(i) = -1.0d0
         iguess(i) = 0
      end do
      imcout=0
      iseed=1234567
      imcst=1
      nsamp=1
      nblock=1
      nmoves=1
      darot=0.15d0
      dtrans=0.45d0
      ncheck=0
      ratmin=0.4d0
      ratmax=0.5d0
      amnrot=0.01d0
      amxrot=1.0d0
      amntrn=0.001d0
      amxtrn=2.0d0
      excld=7.3d0
      outfor='shorsom none'
      delmax = -1.0d-02
      enmin = -1.0d10
c
      pi = 4.0d0*atan(1.0d0)
c
caleko
c  temp is set equal to the temperature specified in 
c  the DRF-input
c
      temp=temprt(1)
 10   continue
      call input
      if (idrfout.ge.1) call outrec
      call inpa(ivar)
      i=locatc(idir,21,ivar)
      if (i.eq.0)
     1  call caserr2('unknown parameter in Monte Carlo directive')
      goto(20,30,40,50,60,70,80,90,100,110,120,130,140,
     2     150,160,170,180,190,200,210,220),i
20    call inpi(imcout)
      goto 10
30    call inpi(iseed)
      goto 10
40    call inpi(imcst)
      do 45 j=1,imcst
        iguess(j)=0
45    continue
caleko
c
c Some of the options available in HONDO have been
c hard-set to their default:
c  iguess(i), i=1,mcst is 0, that is monte carlo
c guess is done according to the current density 
c present on record 16 of the da10.
c Not possible to use density of a previous calculation.
c
      goto 10 
50    call inpi(nsamp)
      goto 10
60    call inpi(nblock)
      goto 10
70    call inpi(nmoves)
      goto 10
80    call inpf(darot)
      goto 10
90    call inpf(dtrans)
      goto 10
100   call inpi(ncheck)
      goto 10
110   call inpf(ratmin)
      goto 10
120   call inpf(ratmax)
      goto 10
130   call inpf(amnrot)
      goto 10
140   call inpf(amxrot)
      goto 10
150   call inpf(amntrn)
      goto 10
160   call inpf(amxtrn)
      goto 10
170   call inpf(excld)
      goto 10
180   call inpa4(outfor(1:4))
      call inpa4(outfor(5:8))
      call inpa4(outfor(9:12))
      goto 10
190   do 11 j=1,imcst
        call inpf(gmdrf(j))
11    continue
      goto 10
200   call inpf(delmax)
      goto 10
210   call inpf(enmin)
      goto 10
220   continue
      
      if (nopes .eq. 0) then
c 1-----
c  -----  overrule some input for classical pes scan calculation
c
        nsamp = 1
        nblock = 1
        nmoves = numpes
        ncheck = 0
c 1-----
      endif
c
c-----  check whether input values are allowed
c
      if ((nsamp .le. 0) .or. (nsamp .gt. nsmax)) then
        write (iwr,1001) nsmax, nsamp
 1001   format(/' check input: ', i6,' > nsamp >0 ',
     1          ' nsamp given as: ', i6)
        call hnderr(3,errmsg)
      endif
c
      if ((nblock .le. 0) .or. (nblock .gt. nblmax)) then
        write (iwr,1002) nblmax, nblock
 1002   format(/' check input: ', i6,' > nblock >0 ',
     1          ' nblock given as: ', i6)
        call hnderr(3,errmsg)
      endif
c
      if ((nmoves .le. 0) .or. (nmoves .gt. nmovmax)) then
        write (iwr,1003) nmovmax, nmoves
 1003   format(/' check input: ', i6,' > nmoves >0 ',
     1          ' nmoves given as: ', i6)
        call hnderr(3,errmsg)
      endif
c
      if ((darot .lt. 0.0) .or. (darot .gt. drotmax)) then
        write (iwr,1004) drotmax, darot
 1004   format(/' check input: ', f8.4,' > darot >0.0 ',
     1          ' darot given as: ', f8.4)
        call hnderr(3,errmsg)
      endif
c
      if (temp .lt. 0.0) then
        write (iwr,1005) temp
 1005   format(/' check input:  temp >0.0 ',
     1          ' temp given as: ', f8.4)
        call hnderr(3,errmsg)
      endif
c
      if (imcst .gt. mxst) then
        write(iwr,1006) mxst
 1006   format(/,' check input: imcst exceeds mxst =',i2,/,
     1  ' mxst may be set in drf/dimpar')
        call hnderr(3,errmsg)
      endif
cc
      darot = pi*darot
c
      notrans = 1
      if (dtrans .ne. 0.0d0) notrans = 0
      norot = 1
      if (darot .ne. 0.0d0) norot = 0
c
      if (notrans .eq. 1) then
        if (norot .eq. 1) then
          write (iwr, 1011)
 1011     format (/,' this mc run is of little use, since both ',
     2    'rotation and translation of the groups is disallowed')
          call hnderr(3,errmsg)
        endif
        write (iwr, 1012)
 1012   format (/,' translation of the classical groups is disallowed')
      endif
c
      if (norot .eq. 1) then
        write (iwr, 1013)
 1013   format (/,' rotation of the classical groups is disallowed')
      endif
c
      if (ncheck .eq. 0) then
c 1-----
        write (iwr,1021)
 1021   format (/, ' the parameters darot and dtrans will not be ',
     2  'changed during the run')
c 1-----
      else
c 1-----
        write (iwr,1022) ncheck
 1022   format (/, ' the parameters darot and dtrans will be ',
     2  'reviewed and adapted during the run',/,
     3  ' this will be done every ',i6,' moves')
        if (ncheck .lt. 100) write (iwr,1023)
 1023   format
     2 (/, ' ncheck quite low for meaningful check on parameters')
        if (ncheck .gt. 100000) write (iwr,1024)
 1024   format
     2 (/, ' ncheck quite high for meaningful check on parameters')
c
        if (ratmin .gt. ratmax) then
          tempor = ratmin
          ratmin = ratmax
          ratmax = tempor
          write (iwr,1031)
 1031     format (/ ' parameters ratmin and ratmax interchanged !!')
        endif
c 1-----
      endif
c
      if ((ncheck .gt. 0) .and. (dtrans .gt. amxtrn)) then
        write (iwr,1041) amxtrn, dtrans
 1041   format(/' check input: amxtrn=', f8.4,' > dtrans',
     1          ' dtrans given as: ', f8.4)
        call hnderr(3,errmsg)
      endif
c
      if ((ncheck .gt. 0) .and. (darot .gt. amxrot)) then
        write (iwr,1051) amxrot, darot
 1051   format(/' check input: amxrot=', f8.4,' < darot ',
     1          ' darot given as: ', f8.4)
        call hnderr(3,errmsg)
      endif
c
      if ((ncheck .gt. 0) .and. (dtrans .lt. amntrn)) then
c 1-----
        if (notrans .eq. 0) then
          write (iwr,1061) amntrn, dtrans
 1061     format(/' check input: amntrn=', f8.4,' < dtrans',
     1          ' dtrans given as: ', f8.4)
          call hnderr(3,errmsg)
        else
c   2-----
c           set amntrn zero, to avoid faults in translation step
c           parameter updating in mcstepp
c
          amntrn = 0.0d0
        endif
c 1-----
      endif
c
      if ((ncheck .gt. 0) .and. (darot .lt. amnrot)) then
c 1-----
        if (norot .eq. 0) then
          write (iwr,1071) amnrot, darot
 1071     format(/' check input: amnrot=', f8.4,' < darot',
     1          ' darot given as: ', f8.4)
          call hnderr(3,errmsg)
        else
c   2-----
c         set amnrot zero, to avoid faults in rotation step
c         parameter updating in mcstepp
c
          amnrot = 0.0d0
        endif
c 1-----
      endif
c
c-----  set exclusion distance if boundary is present
c       if < 0.0 in input, look it up from solvent information
c
      if (notrans .eq. 0) then
        if (iclintr .ne. 1) then
          iclintr = 1
          write(iwr,1081)
 1081     format(/,' note: classical energy expression forced',
     1    ' to include repulsion because translation is allowed')
        endif
        if ((ibem .ne. 0 ).and.(excld .lt. 0.0d0)) call exclset(excld)
      endif
      continue
      return
      end
      subroutine addup(a,b,c,n)
c------
c      returns array c = a + b of length n
c------
      implicit REAL  (a-h,o-z),integer  (i-n)
c
      dimension a(n), b(n), c(n)
c
      do 100, i = 1, n
c 1-----
        c(i) = a(i) + b(i)
c 1-----
  100 continue
c
      return
      end

      subroutine transform(a,trvect,trmatr)
caleko  
c      This routine translates the coordinates in a
c      using the vector trvect and then rotates them
c      using matrix trmat. These are usually the 
c      standard symmetry-imposed operations of gamess.
c
      implicit REAL  (a-h,o-z),integer  (i-n)
INCLUDE(common/sizes)     
INCLUDE(../drf/comdrf/sizesrf)
INCLUDE(../drf/comdrf/extinf)
INCLUDE(common/iofile)
      dimension a(3), b(3) 
      dimension trvect(3), trmatr(3,3)
      do 100, i=1,3
        b(i)= a(i) + trvect(i)
 100  continue

      call tform2(trmatr,b,a)
      return
      end  
_ENDIF
      subroutine errors(n)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*23 msg
INCLUDE(common/workc)
INCLUDE(common/work)
      data msg /'atmol error number     '/
      if (n.eq.62) call caserr2('atmol i/o error (code 62)')
      write (msg(20:23),'(i4)') n
      nerr=n
      call caserr2(msg)
      return
      end

      subroutine caserr(log)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*(*) log
INCLUDE(common/errcodes)
c
_IF1(c)      call tracebk
      call gamerr(log,ERR_NO_CODE, ERR_NO_CLASS, ERR_ASYNC, ERR_NO_SYS)

      end

      subroutine caserr2(log)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*(*) log
INCLUDE(common/errcodes)
c
c  This version must only be called when it is known that
c  the error will occur on all nodes
c  calling it on a single node will cause the job to hang
c
_IF1(c)      call tracebk
      call gamerr(log,ERR_NO_CODE, ERR_NO_CLASS, ERR_SYNC, ERR_NO_SYS)

      end


      subroutine inpf (buf)
      implicit none
INCLUDE(common/workc)
INCLUDE(common/work)
      intrinsic dble
      integer i,j,i1,i2,ie,ie1,ie2,iexp,isign,ibuff
      logical orep
      character*1 xchar(15)
      data xchar /'0','1','2','3','4','5','6','7','8','9'
     1,'+','-','.','e','d'/
      REAL buf,ten
      data ten/10.0d0/
      buf=0.0d0
      jrec=jrec+1
      if (jrec.gt.jump) return
      i1=istrt(jrec)
      i2=i1+inumb(jrec)-1
      ie2=i2
c...  sign
      isign=1
      if (char1(i1:i1).eq.xchar(12))isign=-1
      if (char1(i1:i1).eq.xchar(12).or.
     +    char1(i1:i1).eq.xchar(11)) i1=i1+1
c...  exponent
      do 10 ie=i1,i2
      if (char1(ie:ie).eq.xchar(14) .or. 
     +    char1(ie:ie).eq.xchar(15)) go to 20
10    continue
      iexp=0
      go to 50
20    i2=ie-1
      iexp=1
      ie1=ie+1
      if (char1(ie1:ie1).eq.xchar(12))iexp=-1
      if (char1(ie1:ie1).eq.xchar(12).or.
     +    char1(ie1:ie1).eq.xchar(11))
     * ie1=ie1+1
      ibuff=0
      do 40 i=ie1,ie2
      do 30 j=1,10
      if (char1(i:i).eq.xchar(j)) go to 40
30    continue
      goto 100
40    ibuff=ibuff*10+j-1
      iexp=iexp*ibuff
c.... the number itself
 50   orep=.false.
      do 90 i=i1,i2
      if(char1(i:i).eq.xchar(13)) go to 80
      do 60 j=1,10
      if (char1(i:i).eq.xchar(j)) go to 70
60    continue
      goto 100
70    buf=buf*ten+ dfloat(j-1)
      go to 90
 80   if(orep)go to 100
      iexp=iexp+i-i2
      orep=.true.
90    continue
      buf = buf* dfloat(isign) * ten**iexp
      return
100   call errout(i)
      call caserr2
     * ('illegal character when reading floating point number')
      return
      end
      subroutine inpi(junke)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/workc)
INCLUDE(common/work)
      dimension xchar(12)
      data xchar /'0','1','2','3','4','5','6','7','8','9'
     1,'+','-'/
c.... subroutine for reading integers from the array char1,
c     starting at char1(istrt(jrec)) and going on for inumb(jrec))
c     elements. plus signs are ignored, the answer is accumulated
c     in jbuf and transferred to junke
      jbuf = 0
      jrec = jrec + 1
      if(jrec.gt.jump)go to 160
      n = inumb(jrec)
      ifact = 1
      ist=istrt(jrec)
      nstrt = ist + n - 1
      do 150 i = 1,n
      xtemp = char1(nstrt:nstrt)
      do 110 j=1,12
      if(xchar(j).eq.xtemp)go to 130
110   continue
120   call errout(nstrt)
      call caserr2('illegal character when reading integer')
130   if(j.lt.11)go to 140
      if(nstrt.ne.ist)go to 120
      if(j.ge.12)jbuf=-jbuf
      go to 160
140   jbuf=jbuf+(j-1)*ifact
      ifact = ifact * 10
150   nstrt=nstrt-1
160   junke=jbuf
      return
      end
c      subroutine inpwid(iwid)
c      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
c      implicit character *8 (z),character *1 (x)
c      implicit character *4 (y)
cINCLUDE(common/work)
cINCLUDE(common/iofile)
c      if((iwid.lt.1).or.(iwid.gt.132))call caserr2(
c     1 'illegal line width specified')
c      jwidth=iwid
c      write(iwr,10)jwidth
c10    format(///' input line width set to',i4,' characters')
c      return
c      end
      subroutine scann
      implicit REAL (a-h,o-z),integer(i-n)
INCLUDE(common/work)
1      if(jrec.lt.jump)goto 999
      call input
      goto 1
999   return
      end
      subroutine rinpi(i)
      implicit REAL (a-h,o-z),integer(i-n)
c     this subroutine reads an integer,
c     no matter how many cards it takes
       call scann
       call inpi(i)
      return
      end
      subroutine rchar(a)
      implicit REAL (a-h,o-z),integer(i-n)
c     this subroutine reads a word of text
c     no matter how many cards it takes
      character *8 a
       call scann
       call inpa(a)
      return
      end
      subroutine rinpf(f)
      implicit REAL (a-h,o-z),integer(i-n)
c     this subroutine reads an real,
c     no matter how many cards it takes
       call scann
       call inpf(f)
      return
      end
      function ytrunc(ztext)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*(*) ztext
_IF(absoft)
      character *4 ytrunc
_ENDIF
      ytrunc(1:4)=ztext(1:4)
      return
      end
      subroutine clenup
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      call clredx
      call whtps
      call shut
      return
      end
      subroutine wrt3(q,nword,iblk,num3)
c
c     this routine writes nword(s) of real data, commencing at
c     block iblk on unit num3, from the array q.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(*)
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call wrt3_ga( q, nword, iblk, num3 )
      Else
_ENDIF
      call search(iblk,num3)
      j=1
      k=nword
 20   if(k)30,30,10
 10   call put(q(j),min(k,511),num3)
      j=j+511
      k=k-511
      go to 20
30    return
_IF(ga)
      End If
_ENDIF
      end
      function iposun(iunit)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/disc)
      if(iunit.le.0.or.iunit.gt.maxlfn)
     + call caserr2('invalid positioning requested')
      iposun = ipos(iunit)
      return
      end
      subroutine rdedx(q,nword,iblk,num3)
c
c     this routine reads nwords of real data, commencing at
c     block iblk on unit num3 into the array q.
c     note that nword has to be exactly what lies on disk
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(*)
      logical opg_root
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
_ENDIF
      if (nword .eq. 0) return
_IF(ga)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call rdedx_ga( q, nword, iblk, num3 )
      Else
_ENDIF
      call search(iblk,num3)
      j=1
 20   if(j.gt.nword)go to 30
      call find(num3)
      call get(q(j),l)
      j=j+l
      go to 20
30    if(j-1.ne.nword) then
       write(6,*)
     + 'invalid no of words: requested,present = ', nword, j-1
       call caserr2('invalid number of words in rdedx')
      endif
      return
_IF(ga)
      End If
_ENDIF
      end
      subroutine rdedx_less(q,nword,iblk,num3)
c...   allow nword to be less than actually read (overflow)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(*)
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
_ENDIF
      if (nword .eq. 0) return
_IF(ga)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call rdedx_ga( q, nword, iblk, num3 )
      Else
_ENDIF
      call search(iblk,num3)
      j=1
 20   if(j.gt.nword)go to 30
      call find(num3)
      call get(q(j),l)
      j=j+l
      go to 20
30    return
_IF(ga)
      End If
_ENDIF
      end
      subroutine rdedx_prec(q,nword,iblk,num3)
c...   read precisely nword (use extra buffer to accomplish this)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(*)
      dimension qbuff(511)
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
_ENDIF
      if (nword .eq. 0) return
_IF(ga)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call rdedx_ga( q, nword, iblk, num3 )
      Else
_ENDIF
      call search(iblk,num3)
      j=1
 20   if(j.gt.nword)go to 30
      call find(num3)
      if (j+510.gt.nword) then
         call get(qbuff,l)
         l = min(l,nword-j+1)
         call dcopy(l,qbuff,1,q(j),1)
      else
         call get(q(j),l)
      end if
      j=j+l
      go to 20
30    return
_IF(ga)
      End If
_ENDIF
      end
      subroutine wrt3s(q ,nword,num3)
c
c     this routine writes nword(s) of real data, commencing at
c     the current position/block on unit num3, from the array q.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(*)
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call wrt3s_ga( q, nword, num3 )
      Else
_ENDIF
      j=1
      k=nword
20    if(k)30,30,10
10    call put( q(j),min(k,511),num3)
      j=j+511
      k=k-511
      go to 20
30     return
_IF(ga)
      End If
_ENDIF
       end
      subroutine reads(q,nword,num3)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(*)
INCLUDE(common/iofile)
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call reads_ga( q, nword, num3 )
      Else
_ENDIF
      j=1
10    if(j.gt.nword)go to 30
      call find(num3)
      call get(q(j),l)
      j=j+l
      go to 10
30    if(j-1.ne.nword) then
       write(iwr,*)
     + 'invalid no of words: requested,present = ', nword, j-1
       call caserr2('invalid number of words in reads')
      endif
      return
_IF(ga)
      End If
_ENDIF
      end
      subroutine readsx(q,nword,nreply,num3)
c
c...  called from dirctb ; the overflow of g is intentional
c...  and is accounted for in david1 (jvl,2000/vrs many moons ago)
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(*)
      j=1
10    if(j.gt.nword)go to 30
      call find(num3)
      call get(q(j),l)
      j=j+l
      go to 10
30    nreply=j-1
      return
      end

c-----------------------------------------------------------------------
c     DUMPFILE routines all concentrated HERE
c-----------------------------------------------------------------------
      subroutine qsector(mpos,ipos,iclass,ilen,op)
c
c...   query common sector - replacement of upack3  
c...   op = get or put
c...   it would be better to channel all operations on sector
c...   through an interface like this; but that is  bridge too far now
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sector)
       character*(*) op
c
      if (op.eq.'get') then
         if(mpos.lt.1.or.mpos.gt.508) then
             write(iwr,100) mpos
 100         format(/1x,'**************************',/
     *               1x,'problem with section ',i5,/
     *               1x,'**************************')
          call caserr2('attempting to use invalid dumpfile section get')
      end if
c
_IF(GIGA_DUMP) 
          ipos = apos(1,mpos)
          iclass = apos(2,mpos)
          ilen = apos(3,mpos)
_ELSE
          call upack3(apos(mpos),ipos,iclass,ilen)
_ENDIF
c
       else if (op.eq.'put') then
c
         orevis(1)=.false.
         if(mpos.lt.1.or.mpos.gt.508) then
             write(iwr,100) mpos
          call caserr2('attempting to use invalid dumpfile section put')
         end if
         if(iclass.lt.0.or.iclass.gt.2500) then
             write(iwr,101) mpos,iclass
 101         format(/1x,'*****************************************',/
     *               1x,'problem with section ',i5,' iclass ',i5,/
     *               1x,'*****************************************')
          call caserr2('attempting to use invalid dumpfile type (put)')
         end if
c
_IF(GIGA_DUMP) 
          apos(1,mpos) = ipos
          apos(2,mpos) = iclass
          apos(3,mpos) = ilen
_ELSE
_IF(bits8)
      call pack3(ipos,iclass,ilen,apos(mpos))
_ELSE
      apos(mpos)=pack3(ipos,iclass,ilen)
_ENDIF
_ENDIF
      else
         call caserr('wrong operation in qsector')
      end if
c
      return
      end
      subroutine secini(ibl,num)
c...   init dumpfile ; 0,0 => start afresh;
c      cf /sector/
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sector)
INCLUDE(common/iofile)
      data izero/0/
c
      nav = lenwrd()
_IF(GIGA_DUMP) 
      mhead = 508*3 
_ELSE
      mhead = 508 
_ENDIF
      orevis(1)=.true.
c
      if (ibl.eq.0.and.num.eq.0) then
         mhead = mhead * nav
         call setsto(mhead,izero,apos)
      else
         mhead = mhead + 2/nav
         numdu=num
         iblkdu=ibl
         call rdedx(apos,mhead,iblkdu,numdu)
      end if
c
      return
      end
      logical function sector_block(ibl,num)
c...   check if current (collection of) blocks qualify as dumpfile block
INCLUDE(common/sector)
_IF(GIGA_DUMP) 
      dimension aposs(3*508)
      equivalence (apos,aposs)
_ENDIF
c
      sector_block = .false.
      call search(ibl,num)
      call fgett(apos,nword,iunit)
c
_IF(GIGA_DUMP) 
c
      mhead = 508*3 + 2/lenwrd()
      if(nword.ne.511) return
      call fgett(aposs(511+1),nword,iunit)
      if(nword.ne.511) return
      call fgett(aposs(2*511+1),nword,iunit)
      if (nword+2*511.ne.mhead) return
_ELSE
      mhead = 508 + 2/lenwrd()
      if (nword.ne.mhead) return
_ENDIF
c
      if(maxc.gt.maxb.or.maxc.lt.1) return
      do   i=1,508 
         call qsector(i,m,itype,n,'get')
         if (m.gt.0) then
            if (n.eq.0.or.(m+n).gt.maxc.or.itype.eq.0) return 
         end if
      end do
c
      sector_block = .true.
c
      return
      end

      subroutine secinf(ibl,iunit,max,maxbb)
c...   return dumpfile info
      implicit none
      integer ibl,iunit,max,maxbb
INCLUDE(common/sector)
INCLUDE(common/iofile)
c
      ibl = iblkdu
      iunit = numdu
      max = iblkla
      maxbb = maxb
CMR   write(iwr,*) 'CMR secinf says: ',iblkdu,numdu,iblkla,maxb
c
      return
      end

      subroutine secsum
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/discc)
INCLUDE(common/sector)
       call secinf(iblkdu,numdu,iblkla,maxbb)
       write(iwr,600)yed(numdu),iblkdu,iblkla,maxb
 600   format(//' *summary of dumpfile on ',a4,' at block',i8/2h *,/
     * ' *current length=',i18,' blocks'/2h *,/
     * ' *maximum length=',i18,' blocks'/2h *,/
     * ' *section type   block  length')
      do i=1,508
         call qsector(i,ipos,iclass,ilen,'get')
         if(ipos .gt. 0) then
            m=iblkdu+ipos
            write(iwr,500)i,iclass,m,ilen
         endif
      end do
      return
 500  format(2h *,i7,i5,2i8)
      end
      subroutine secloc(mpos,oexist,iblock)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      call  secinf(iblkdu,idum,idum,idum)
      call qsector(mpos,ipos,iclass,ilen,'get')
       oexist=.false.
       if(ipos.gt.0) then
        oexist=.true.
        iblock=ipos+iblkdu
       endif
      return
      end
      subroutine secget(mpos,mtype,iblock)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
c
      call secinf(iblkdu,numdu,idum,idum)
      call qsector(mpos,ipos,iclass,ilen,'get')
c
       if(ipos.lt.1)then
       write(iwr,100) mpos,mtype,iblock
 100   format(/1x,'*********************',/
     *         1x,'problem with section ',/
     *         1x,'*********************',//
     *         1x,'mpos, mtype, block ',3(1x,i5)/)
       call secsum
       call caserr2('attempting to retrieve undefined dumpfile section')
       endif
       if(mtype.eq.0)mtype=iclass
       if(iclass.ne.mtype) then
       write(iwr,100) mpos,mtype,iblock
        call caserr2(
     * 'retrieved dumpfile section of wrong type')
       endif
       iblock=ipos+iblkdu
       call search(iblock,numdu)
      return
      end

      subroutine revind
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sector)
INCLUDE(common/iofile)
INCLUDE(common/utilc)

_IF(GFS)
CMR   apos patch, GFS needed here....
CMR   Diagnostic: Appending one word too much to apos sometimes breaks
CMR   on gfortran, producing 0's in ed3 header for maxb and iblka
CMR   Fix       : Use longer scratch array bpos, and explicitly equivalence ii
_IF(GIGA_DUMP)
      integer*8 bpos(3,509),ii(2)
      equivalence(ii(1),bpos(3,509))
      bpos(1:3,1:508)=apos(1:3,1:508)
_ELSE
      dimension bpos(509),ii(2)
      equivalence(ii(1),bpos(509))
      bpos(1:508)=apos(1:508)
_ENDIF
      ii(1)=maxb
      ii(2)=iblkla
CMR   write(*,*) 'inserted maxb and iblka',ii(1),ii(2)
CMR-  apos patch
_ENDIF
      
      if(orevis(1)) then
       call clredx
      else
       nav = lenwrd()
       call search(iblkdu,numdu)
_IF(GIGA_DUMP) 
       mhead = 508*3 + 2/nav
_ELSE
       mhead = 508 + 2/nav
_ENDIF
_IF(GFS)
       call wrt3s( bpos, mhead, numdu )
_ELSE
       call wrt3s( apos, mhead, numdu )
_ENDIF
       orevis(1)=.true.
       if (ooprnt) then
        write(iwr,10) 
10      format (/1x,'****** output index block of dumpfile ***')
       endif
      endif
      return
      end
      subroutine secput(mpos,mtype,length,iblock)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sector)
INCLUDE(common/iofile)
_IF(GIGA_DUMP) 
      parameter (maxdlen=2**26)
c...   biggest size for i*4
_ELSE
      parameter (maxdlen=16*65536)
_ENDIF
      call qsector(mpos,ipos,iclass,ilen,'get')
c
      if(ipos.le.0 .or. length.gt.ilen)then
c
c  create/expand
c
         if(ipos.gt.0)write(iwr,10) mpos
 10      format(/1x,'**** Warning ****'/
     *        1x,'**** Expanding section ',i5,' on the dumpfile')
c
         m=length+iblkla
         if(m.gt.maxb)call caserr2(
     *   'attempting to expand dumpfile beyond maximum allowed size')
          iblock=iblkdu+iblkla
         call qsector(mpos,iblkla,mtype,length,'put')
         iblkla=m
      else
         call qsector(mpos,ipos,mtype,ilen,'put')
         iblock=ipos+iblkdu
      endif
c
      if(length.gt.maxdlen.or.ipos.gt.maxdlen*16) then
c
         write(iwr,11) mpos,mtype,length
11       format(' trying dumpfile section mpos,mtype,length',3i10)
         call caserr2('dumpfile section-length overflow in secput')
      end if  

      call search(iblock,numdu)
c
      return
      end
      subroutine secdrp(mpos)
c Disable section mpos by setting iclass to zero (see sectst).
c AdM JvL 1991
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      call qsector(mpos,ipos,iclass,ilen,'get')
c
      if(ipos.gt.0) then
         iclass = 0
         call qsector(mpos,ipos,iclass,ilen,'put')
      endif
c
      return
      end
      subroutine sectst(mpos,iretrn)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      call qsector(mpos,ipos,iclass,ilen,'get')
c
      if(ipos.gt.0. and. iclass.gt.0) then
         iretrn=1
      else
         iretrn=0
      endif
c
      return
      end

      subroutine maxset
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
INCLUDE(common/sector)
      call inpi(maxb)
      if(maxb.lt.iblkla)call caserr('invalid dumpfile size specified')
      write(iwr,300)maxb
 300  format(/' maximum size of dumpfile now',i8,' blocks')
      orevis(1)=.false.
      return  
      end     

      subroutine sumvecs
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character*80 charv
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/scfopt)
      common/junkcXX/zcom(19),ztit(10)
INCLUDE(common/discc)
INCLUDE(common/machin)
c
      data m3,m29/3,29/
c
c ---- read a set of vectors off the dumpfile, and write
c      a summary to the output file
c
      call secinf(idum,numdu,idum,idum)
      write(iwr,100)
100   format(/1x,'*summary of vector sections'/1x,'*'/
     +        1x,'*section',4x,'type',6x,'created:',11x,'title:')
      do i = 1, 508
c
         call qsector(i,ipos,iclass,ilen,'get')
c
       if (ipos.gt.0) then
        if(iclass.eq.m3) then
c
          m=iblkdu + ipos
          call secget(i,m3,k)
          call rdchr(zcom,m29,k,numdu)
c
          j = 1
          do loop = 1,10
           charv(j:j+7) = ztit (loop)
           j = j + 8
          enddo
          last = lstchr(charv)
c
          write(iwr,200)i,zcom(5),zcom(3),zcom(2),charv(1:last)
200       format(1x,'*',i7,4x,a8,1x,a8,' on ', a6, 2x, a)
c
        endif
       endif
      enddo
c
      return
      end
c
c----------------------------------------------------------------------
c

      subroutine tfsqc(v,q,t,m,n,ndim)
c
c     ----- back transform the square matrix q with v -----
c     ----- t is scratch
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension v(ndim,*),q(ndim,*),t(ndim,*)
c
      nmm=ndim*m
      call vclr(t,1,nmm)
      call mxmb(q,1,ndim,v,1,ndim,t,1,ndim,n,m,m)
      call dcopy(nmm,t,1,v,1)
      return
      end
       subroutine mult1a(a,q,ilifq,ncore,h,iky,nbasis)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension a(*),q(*),h(*),ilifq(*),iky(*)
      dimension p(maxorb),r(maxorb)
c...   a=q(transpose) * h * q
c...   a and h stored in triangle form
      do 1 j=1,ncore
      mm=ilifq(j)
      p(1)=h(1)*q(mm+1)
      do 2 i=2,nbasis
      m=iky(i)
      call daxpy(i-1,q(mm+i),h(m+1),1,p,1)
      p(i)=ddot(i,h(m+1),1,q(mm+1),1)
 2    continue
      m=iky(j)
      do 1 i=1,j
      a(m+i)=ddot(nbasis,p,1,q(ilifq(i)+1),1)
 1    continue
      return
      end
       subroutine writel(p,newbas)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/prints)
INCLUDE(common/iofile)
       dimension p(*)
      ind(i,j)=max(i,j)*(max(i,j)-1)/2+min(i,j)
      m5=12
      if(oprint(20)) m5=8
      m=1
      n=m5
   6  if(newbas.lt.m)return
      if(n.gt.newbas)n=newbas
      if(.not.oprint(20))write(iwr,200)(i,i=m,n)
      if(oprint(20))write(iwr,100)(i,i=m,n)
100   format(//3x,8i14)
200   format(//12i9)
      write(iwr,101)
101   format(/)
      do 1 j=1,newbas
      if(oprint(20))write(iwr,102)j,(p(ind(i,j)),i=m,n)
      if(.not.oprint(20))write(iwr,202)j,(p(ind(i,j)),i=m,n)
 1    continue
102   format(7x,i3,8f14.7)
202   format(1x,i3,12f9.4)
      m=m+m5
      n=n+m5
      goto 6
      end
      function locatc(label,nf,itext)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character * (*) label,itext
      dimension label(*)
      do 1 i=1,nf
      if(label(i).eq.itext)go to 2
 1    continue
      locatc=0
      return
 2    locatc=i
      return
      end
      subroutine filprn(nfile,iblk,lblk,notape)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/discc)
      dimension iblk(*),lblk(*),notape(*)
      write(iwr,1)(yed(notape(i)),i=1,nfile)
      write(iwr,2)(iblk(i),i=1,nfile)
      write(iwr,3)(lblk(i),i=1,nfile)
1     format(/9x,'ddnames ',20(2x,a4))
2     format(' starting blocks',20i6)
3     format(' terminal blocks',20i6)
      return
      end
      subroutine prtri(d,n)
c
c     ----- print out a triangular matrix -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/iofile)
INCLUDE(common/runlab)
      dimension d(*),dd(12)
      mmax = 12
      if (oprint(20)) mmax=7
      imax = 0
  100 imin = imax+1
      imax = imax+mmax
      if (imax .gt. n) imax = n
      write (iwr,9008)
      if(oprint(20)) write (iwr,9028) (i,i = imin,imax)
      if(.not.oprint(20)) write (iwr,8028) (i,i = imin,imax)
      do 160 j = 1,n
      k = 0
      do 140 i = imin,imax
      k = k+1
      m = max(i,j)*(max(i,j)-1)/2 + min(i,j)
  140 dd(k) = d(m)
      if(oprint(20)) write (iwr,9048) j,(dd(i),i = 1,k)
      if(.not.oprint(20)) write (iwr,8048) j,(dd(i),i = 1,k)
  160 continue
      if (imax .lt. n) go to 100
      return
 9008 format(/)
 9028 format(6x,7(6x,i3,6x))
 9048 format(i5,1x,7f15.10)
 8028 format(6x,12(3x,i3,3x))
 8048 format(i5,1x,12f9.4)
      end
      subroutine prsq(v,m,n,ndim)
c
c     ----- print out a square matrix -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/prints)
INCLUDE(common/iofile)
      dimension v(ndim,*)
      max = 12
      if (oprint(20)) max=7
      imax = 0
  100 imin = imax+1
      imax = imax+max
      if (imax .gt. m) imax = m
      write (iwr,9008)
      if(.not. oprint(20)) write (iwr,8028) (i,i = imin,imax)
      if( oprint(20)) write (iwr,9028) (i,i = imin,imax)
      write (iwr,9008)
      do 120 j = 1,n
      if( oprint(20)) write (iwr,9048) j,(v(j,i),i = imin,imax)
      if(.not.oprint(20)) write (iwr,8048) j,(v(j,i),i = imin,imax)
120   continue
      if (imax .lt. m) go to 100
      return
 9008 format(1x)
 9028 format(6x,7(6x,i3,6x))
 9048 format(i5,1x,7f15.10)
 8028 format(6x,12(3x,i3,3x))
 8048 format(i5,1x,12f9.5)
      end
      subroutine trianc(r,a,mrowr,n)
      implicit REAL  (a-h,o-z)
      dimension r(mrowr,*),a(*)
c... convert from square r to lower triangle a
      k = 0
      do 30 i = 1 , n
         do 20 j = 1 , i
            k = k + 1
            a(k) = r(i,j)
 20      continue
 30   continue
      return
      end
      subroutine openda
c
c     ----- open a direct access file -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
c
c --- initialise the zero block
c
      call wrrec1(id,id,id,id,c,c,d,d,d,c,c)
      call revind
      return
      end
      subroutine closda
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
INCLUDE(common/machin)
INCLUDE(common/iofile)
      character*10 charwall
      cpu=cpulft(1)
      write(iwr,1)cpu,charwall()
 1    format(///
     *' end of  G A M E S S   program at ',f12.2,
     *' seconds',a10,' wall',/)
c
      oprintv = .true.
c
      call revind
      call secsum
      if (oprintv) call sumvecs
      call clenup
      call timout
      return
      end
      subroutine setscm(k)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
INCLUDE(common/segm)
c
c -----  core management routines for gamess
c
c --- this routine returns the address in k of the next scm block
c --- of core as an index in the array x
c
_IF1()ccc      call caserr2('setscm')
      k=ntotly+1
      return
      entry cmem(load)
c
c --- set load to the present core usage
c
      load=ntotly
      return
      entry setc(need)
_IF1()cccc      call caserr2('setc')
c
c --- update entries in the common/ovly/ header block
c --- and assign another block of core if necessary
c --- totla amount of core required is need
c --- if need is less than the current amount allocated
c --- then a section of core is deleted
c
 10   if(need.gt.nmaxly) goto 900
      if(need.gt.ntotly) goto 20
      if(need.eq.ntotly) goto 30
c
c --- current requirement is less than that allocated
c --- so delete the last section of core and try again
c
      if(icurly.eq.1) goto 30
      icurly=icurly-1
      ntotly=ntotly-isecly(icurly+1)
      if(opg_root().and.oprintm)
     +   write(iwr,*)'setc: freed to ',ntotly
      goto 10
c
c --- current requirement is greater than that allocated
c -- so add a block of core
c
 20   if(icurly.ge.100) goto 920
      icurly=icurly+1
      isecly(icurly)=need-ntotly
      ntotly=need
      if(opg_root().and.oprintm)
     +   write(iwr,*)'setc: allocated to',ntotly
      go to 30
 900  write(iwr,910) need,nmaxly
 910  format(//1x,'core management :- core overflow'/,
     1       ' need ',i10,'     got',i10,//)
      go to 930
 920  write(iwr,940)
 940  format(//1x,'core management :- too many sections'//)
 930  call caserr2('insufficient memory allocated')
c
c --- can keep the current allocation
c
 30   return
c
c ---eroor messages
c
      end
      function loccm()
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/segm)
      loccm=ntotly
      return
      end
      subroutine init_segm
      implicit none
INCLUDE(common/segm)
      integer loop
      icurly = 1
      ntotly = 0
      do 120 loop = 1 , 100
         isecly(loop) = 0
 120  continue
      end
      subroutine setlab
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character *3 char3,char3i
      character *4 bfnam
      character *1 atnam1
      character *2 atnam2
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/infoa)
INCLUDE(common/infob)
INCLUDE(common/runlab)
      dimension bfnam(35),atnam1(104),atnam2(104)
      data bfnam/
     + 's','x','y','z',
     + 'xx','yy','zz','xy','xz','yz',
     + 'xxx','yyy','zzz','xxy','xxz','xyy','yyz','xzz',
     + 'yzz','xyz',
     + 'xxxx','yyyy','zzzz','xxxy','xxxz','yyyx','yyyz',
     + 'zzzx','zzzy','xxyy','xxzz','yyzz','xxyz','yyxz',
     + 'zzxy' /
      data atnam1 /' ','h',
     +             'l','b',' ',' ',' ',' ',' ','n',
     +             'n','m','a','s',' ',' ','c','a',
     +             ' ','c','s','t',' ','c','m','f','c',
     +        'n','c','z','g','g','a','s','b','k',
     +             'r','s',' ','z','n','m','t','r','r',
     +        'p','a','c','i','s','s','t',' ','x',
     +'c','b','l','c','p','n','p','s','e','g','t',
     +'d','h','e','t','y','l','h','t',' ','r','o',
     +'i','p','a','h','t','p','b','p','a','r',
     +'f','r','a','t','p',' ','n','p','a','c','b',
     +'c','e','f','m','n','l',
     +             ' '/
c
      data atnam2 / 'h', 'e',
     +              'i', 'e', 'b', 'c', 'n', 'o', 'f', 'e',
     +              'a', 'g', 'l', 'i', 'p', 's', 'l', 'r',
     +              'k', 'a', 'c', 'i', 'v', 'r', 'n', 'e', 'o',
     +         'i', 'u', 'n', 'a', 'e', 's', 'e', 'r', 'r',
     +              'b', 'r', 'y', 'r', 'b', 'o', 'c', 'u', 'h',
     +         'd', 'g', 'd', 'n', 'n', 'b', 'e', 'i', 'e',
     + 's', 'a', 'a', 'e', 'r', 'd', 'm', 'm', 'u', 'd', 'b',
     + 'y', 'o', 'r', 'm', 'b', 'u', 'f', 'a', 'w', 'e', 's',
     + 'r', 't', 'u', 'g', 'l', 'b', 'i', 'o', 't', 'n',
     + 'r', 'a', 'c', 'h', 'a', 'u', 'p', 'u', 'm', 'm', 'k',
     + 'f', 's', 'm', 'd', 'o', 'w',
     +              ' '/
c
      n = 0
      do 100 ii = 1,nshell
      iat = katom(ii)
      cznuc = czanr(iat)
      j =  nint(cznuc)
      if (j .gt.103. or.j . eq. 0) j = 104
      mini = kmin(ii)
      maxi = kmax(ii)
      if(nat.ge.100) then
      do 110 i = mini,maxi
      n = n+1
      zbflab(n)(1:3)=char3i(iat)
      zbflab(n)(4:4)=atnam1(j)
      zbflab(n)(5:6)=atnam2(j)
      zbflab(n)(7:10)=bfnam(i)
  110 continue
      else
      do 120 i = mini,maxi
      n = n+1
      char3=char3i(iat)
      zbflab(n)(1:2)=char3(1:2)
      zbflab(n)(3:3)=atnam1(j)
      zbflab(n)(4:5)=atnam2(j)
      zbflab(n)(6:9)=bfnam (i)
      zbflab(n)(10:10)= ' '
  120 continue
      endif
  100 continue
      return
      end
      function char3i(i)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character *3 c,char3i
      character *1 digit(0:9)
      data c/' '/
      data digit/
     *'0','1','2','3','4','5','6','7','8','9'/
      num=iabs(i)
      char3i='   '
      l=3
      do 1 j=3,1,-1
      new=num/10
      n=num-10*new
      if(n.gt.0)l=j
      c(j:j)=digit(n)
 1    num=new
      goto (2,3,4),l
2     char3i(1:3) = c(1:3)
      go to 5
3     char3i(1:2) = c(2:3)
      go to 5
4     char3i(1:1) = c(3:3)
5     return
      end
      subroutine intr(core)
c
c     ----- calculate atom-atom distances -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
INCLUDE(common/phycon)
INCLUDE(common/structchk)
      dimension r(maxat)
c
      dimension core(*)
      data done/1.0d0/
c
c     write(6,*)'oprint',oprint(21)

      if (nat.eq.1)return
      if (oprint(21).and..not.ochkdst)return
      if (oprint(56)) then
       ipass = 1
       fac = done
       if(nprint.ne.-5)write (iwr,9028)
  100  continue
       max = 0
  120  min = max+1
       max = max+7
       if (max .gt. nat) max = nat
       if(nprint.ne.-5)write (iwr,9048)
       if(nprint.ne.-5)write (iwr,9068)(zaname(j),j= min,max)
       if(nprint.ne.-5)write (iwr,9048)
       do i = 1,nat
        do  j = min,max
        rr = (c(1,i)-c(1,j))**2+(c(2,i)-c(2,j))**2+(c(3,i)-c(3,j))**2
        r(j) = dsqrt(rr)*fac
        enddo
        if(nprint.ne.-5)write(iwr,9088)i,zaname(i),
     *  (r(j),j=min,max)
       enddo
       if (max .lt. nat) go to 120
       if (ipass .lt. 2) then
        ipass = 2
        fac = toang(1)
        if(nprint.ne.-5)write (iwr,9008)
        go to 100
        endif
      endif
c
      if (ochkdst) then
       if(lpseud.eq.0) then
        call struct_check(nat,c,czan,nuct,core)
       else
        call struct_check(nat,c,symz,nuct,core)
       endif
      endif
c
      if(nprint.ne.-5) then
       if(lpseud.eq.0) then
        call struct(nat,c,czan,nuct,core)
       else
        call struct(nat,c,symz,nuct,core)
       endif
      endif
c
      return
 9008 format(/40x,'internuclear distances (angs.)'/40x,30('-'))
 9028 format(/40x,'internuclear distances ( a.u.)'/40x,30('-'))
 9048 format(/)
 9068 format(17x,7(4x,a8,3x))
 9088 format(i3,2x,a8,2x,7f15.7)
      end
      subroutine timit(index)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
INCLUDE(common/timez)
      tim=cpulft(1)
      tx = tim-ti
      ti = tim
      if(index.eq.0.or.index.eq.3.or.index.eq.-5)return
      write(iwr,9008)tx,tim
 9008 format(/1x,33('-')/
     *'     elapsed time = ',f8.2,' secs'/
     *'     total time   = ',f8.2,' secs'/1x,33('-')/)
      return
      end
      subroutine texit(ncall,nrest)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/machin)
INCLUDE(common/restar)
INCLUDE(common/timez)
      call timit(ncall)
      if (tim .lt. timlim) return
      irest = nrest
      itask(mtask) = irest
      call revise
      return
      end
      subroutine gamgen
c        *****  computes and tabulates f0(x) to f5(x)           *****
c        *****  in range x = -0.24 to x = 26.4                  *****
c        *****  in units of x = 0.08                            *****
c        *****  used by the one electron routine auxg and by    *****
c        *****  the two electron integral routines              *****
c        *****  the table is generated only once for each entry *****
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
INCLUDE(common/restri)
      common/inttab/c(1000,6)
      dimension ppp(350)
      data pt184,pt5/ 0.184d0,0.50d0/
      data six,tenm7/6.0d0,1.0d-20 /
      data four,two,done/4.0d0,2.0d0,1.0d0/
c     data m22,mword/22,6000/
      data pt886/0.8862269254527d0/
      q=-done
      do 30 mm=1,6
      m=mm-1
      q=q+done
      qqq = -0.24d0
      do 20 i=1,340
      qqq = qqq+0.08d0
      a=q
c        *****  change limit of approximate solution.           *****
      if(qqq-15.0d0) 1,1,10
    1 a=a+pt5
      term=done/a
      ptlsum=term
      do 2 l=2,50
      a=a+done
      term=term*qqq/a
      ptlsum=ptlsum+term
      if( dabs(term/ptlsum)-tenm7)3,2,2
    2 continue
    3 ppp(i)=pt5*ptlsum* dexp(-qqq)
      go to 20
   10 b=a+pt5
      a=a-pt5
      approx=pt886/(dsqrt(qqq)*qqq**m)
      if(m.eq.0) go to 13
      do 12 l=1,m
      b=b-done
   12 approx=approx*b
   13 fimult=pt5* dexp(-qqq)/qqq
      fiprop=fimult/approx
      term=done
      ptlsum=term
      notrms=qqq
      notrms=notrms+m
      do 14 l=2,notrms
      term=term*a/qqq
      ptlsum=ptlsum+term
      if( dabs(term*fiprop/ptlsum)-tenm7)15,15,14
   14 a=a-done
   15 ppp(i)=approx-fimult*ptlsum
   20 continue
      do 30 i=1,333
      j=i+2
      c(i,mm)=ppp(j)
      c(i+333,mm)=ppp(j+1)-ppp(j)
      temp1=-two*ppp(j)+ppp(j+1)+ppp(j-1)
      temp2=six*ppp(j)-four*ppp(j+1)-four*ppp(j-1)+ppp(j-2)+ppp(j+2)
   30 c(i+666,mm) = (temp1-pt184*temp2)/six
c        *****  write out interpolation table                   *****
c      call secput(isect(502),m22,lensec(mword),iblk22)
c      call wrt3(c,mword,iblk22,idaf)
      return
      end
      subroutine wrrec1(n1,n2,n3,n4,b,d,d1,d2,d3,e,f)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension h(4*maxat*3+3+4)
INCLUDE(common/iofile)
INCLUDE(common/restri)
INCLUDE(common/infoa)
      dimension b(*),d(*),e(*),f(*),ih(2)
      equivalence (ih(1),h(1))
      data m15/15/
      nav = lenwrd()
      mxcen = nat * 3
      maxtot = mxcen*4+3
      call dcopy(mxcen,b,1,h,1)
      call dcopy(mxcen,d,1,h(  mxcen+1),1)
      call dcopy(mxcen,e,1,h(2*mxcen+1),1)
      call dcopy(mxcen,f,1,h(3*mxcen+1),1)
      itemp = 4*mxcen+1
      h(itemp  ) = d1
      h(itemp+1) = d2
      h(itemp+2) = d3
      imax = nav*maxtot
      ih(imax+1) = n1
      ih(imax+2) = n2
      ih(imax+3) = n3
      ih(imax+4) = n4
      mach4 = 12*nat +3 +4/nav
      call secput(isect(493),m15,lensec(mach4),iblk15)
      call wrt3(h,mach4,iblk15,idaf)
      return
      end
      subroutine rdrec1(n1,n2,n3,n4,b,d,d1,d2,d3,e,f)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension h(4*maxat*3+3+4)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/restri)
      dimension b(*),d(*),e(*),f(*),ih(2)
      equivalence (ih(1),h(1))
      data m15/15/
      nav = lenwrd()
      mach4 = 12*nat +3 +4/nav
      mxcen = nat * 3
      maxtot = mxcen*4+3
      call secget(isect(493),m15,iblk15)
      call rdedx(h,mach4,iblk15,idaf)
      call dcopy(mxcen,h,1,b,1)
      call dcopy(mxcen,h(  mxcen+1),1,d,1)
      call dcopy(mxcen,h(2*mxcen+1),1,e,1)
      call dcopy(mxcen,h(3*mxcen+1),1,f,1)
      itemp=4*mxcen+1
      d1 = h(itemp  )
      d2 = h(itemp+1)
      d3 = h(itemp+2)
      imax = nav*maxtot
      n1 = ih(imax+1)
      n2 = ih(imax+2)
      n3 = ih(imax+3)
      n4 = ih(imax+4)
      return
      end

      function lensec(nword)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
c
c     lensec returns the number of ATMOL blocks corresponding to nword 
c     words of data for all nword greater than zero. For nword equals 
c     zero it returns one.
c     Valid inputs are all non-negative integers.
c
c     Proof:
c
c     Define m = the block size which is 511 words
c
c     Assume n = i*m, i > 0 then
c     lensec = (i*m-1)/m+1
c            = i-1      +1
c            = i
c     Assume n = i*m+j, i >= 0 and 0 < j < m
c     lensec = (i*m+j-1)/m+1
c            = (i*m)/m+(j-1)/m+1
c            = i+1
c     Assume n = 0
c     lensec = -1/m+1
c            = 1
c
_IF(debug)
      if (nword.lt.0) call caserr2('function lensec: nword < 0')
_ENDIF
      lensec=(nword-1)/511+1
      return
      end

      function lenwrd()
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
_IF(cray,t3d,t3e,ksr,i8)
      parameter (nav = 1)
_ELSE
      parameter (nav = 2)
_ENDIF
      lenwrd = nav
      return
      end
      subroutine struct(n, c, az, nuct, bl)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      integer p
      dimension c(3,*),az(*),nuct(*)
      dimension bl(*)
      dimension v(8),m(4,8),ilifz(maxat)
INCLUDE(common/iofile)
INCLUDE(common/prints)
INCLUDE(common/runlab)
INCLUDE(common/coval)
      character*7 fnm
      character*6 snm
      data fnm,snm/"util1.m","struct"/
      data pi /3.14159265358979d0/
c  covalent radii (mostly from coulson & mcweeny) for atoms up to argon
c      data cov /0.57d0, 2.50d0,
c     * 2.53d0, 2.00d0, 1.53d0, 1.46d0, 1.42d0, 1.38d0, 1.34d0,3.00d0,
c     * 2.91d0, 2.69d0, 2.46d0, 2.23d0, 2.08d0, 1.93d0, 1.87d0,3.50d0,
c     * 85 * 3.0d0 /
      data done,two/1.0d0,2.0d0/
      data zsadd/'saddle'/
      data dsmall/10000.0d0/
c
c     ----- get core memory
c
      length=n*n
      i10 = igmem_alloc_inf(length,fnm,snm,'i10',IGMEM_DEBUG)
      ismall=0
      jsmall=0
c
      do 200 i=1,n
 200  ilifz(i)=(i-1)*n+i10-1
c
      scale = 1.0d0
      toler = 0.5d0
      if(zruntp.eq.zsadd)scale=two
      if(oprint(56)) scale =3.0d0
      call vclr(bl(i10),1,length)
      nm1=n-1
      do 21 i=1,nm1
      iz= nint(az(i))
      if(nuct(i).gt.3)go to 21
      covi=two
      if (iz .gt. 0 .and. iz .le. 100) covi=cov(iz)
      ip1=i+1
      do 20 j=ip1,n
      if(nuct(j).gt.3)go to 20
      ij=i+ilifz(j)
      bl(ij)=
     +  dsqrt((c(1,j)-c(1,i))**2+(c(2,j)-c(2,i))**2+(c(3,j)-c(3,i))**2)
      jz= nint(az(j))
      if (bl(ij).lt.dsmall) then
          ismall=i
          jsmall=j
          dsmall=bl(ij)
      endif
      covj=two
      if (jz .gt. 0 .and. jz .le. 100) covj=cov(jz)
      if (bl(ij) .gt. (covi+covj)*scale+toler) bl(ij)=-bl(ij)
      bl(j+ilifz(i))=bl(ij)
20    continue
21    continue
      write (iwr,1001)
 1001 format(//40x,31('=')/
     *40x,'bond lengths in bohr (angstrom)'/40x,31('='))
c
      max=7
      p=0
      do 30 i=1,nm1
      ip1=i+1
      do 30 j=ip1,n
      ij=i+ilifz(j)
      if (bl(ij) .le. 0.0d0) go to 30
      p=p+1
      if (p .le. max) go to 25
      call prtbuf(n,max,2, m, v)
      p=1
25    m(1,p)=i
      m(2,p)=j
      v(p)=bl(ij)
30    continue
      if (p .gt. 0) call prtbuf(n,p,2, m, v)
      if (p .eq. 0) write (iwr,1009)
1009  format (/5x,'--- none ---')
      if (dsmall.lt.0.5) then
          write(iwr,1200) ismall,jsmall,dsmall
      endif
 1200 format(//10x,55('+')/10x,
     *'WARNING: shortest bond length is smaller than 0.5 bohr!'/10x,
     *'atoms ',I5,2x,I5,F10.5/,10x,55('+'))
      write (iwr,1002)
1002  format (//40x,11('=')/40x,'bond angles'/40x,11('=')/)
c
      max=6
      p=0
      do 60 j=1,nm1
      do 50 i=1,n
      ij=i+ilifz(j)
      if (bl(ij) .le. 0.0d0.or. j .eq. i) go to 50
      jp1=j+1
      do 40 k=jp1,n
      ik=i+ilifz(k)
      jk=j+ilifz(k)
      if (bl(ik) .le. 0.0d0.or. k .eq. i) go to 40
      p=p+1
      if (p .le. max) go to 35
      call prtbuf(n,max,3, m, v)
      p=1
35    m(1,p)=j
      m(2,p)=i
      m(3,p)=k
      cosine=(bl(ij)**2+bl(ik)**2-bl(jk)**2)/(two*bl(ij)*bl(ik))
      if ( dabs(cosine) .gt. done) cosine= dsign(done,cosine)
      v(p)=(180.0d0/pi)*dacos(cosine)
40    continue
50    continue
60    continue
      if (p .gt. 0) call prtbuf(n,p,3, m, v)
      if (p .eq. 0) write (iwr,1009)
      write (iwr,1003)
1003  format (//40x,15('=')/40x,'dihedral angles'/40x,15('='))
c
      max=5
      p=0
      do 100 i=1,nm1
      ip1=i+1
      do 90 j=ip1,n
      ij=i+ilifz(j)
      if (bl(ij) .le. 0.0d0) go to 90
c  i and j are bonded.  construct unit vector from i to j.
      a=bl(ij)
      pij=(c(1,j)-c(1,i))/a
      qij=(c(2,j)-c(2,i))/a
      rij=(c(3,j)-c(3,i))/a
      do 80 k=1,n
      ik=i+ilifz(k)
      if (bl(ik) .le. 0.0d0.or. k .eq. i .or. k .eq. j) go to 80
c  i and k are bonded.  construct unit vector in jik plane, normal
c  to ij.
      pik=c(1,k)-c(1,i)
      qik=c(2,k)-c(2,i)
      rik=c(3,k)-c(3,i)
      dot=pik*pij + qik*qij + rik*rij
      pik=pik-dot*pij
      qik=qik-dot*qij
      rik=rik-dot*rij
      a=dsqrt(pik**2+qik**2+rik**2)
      if (a .lt. 1.0d-4) go to 80
      pik=pik/a
      qik=qik/a
      rik=rik/a
      do 70 l=1,n
      jl=j+ilifz(l)
      if (bl(jl) .le. 0.0d0.or. l .eq. i .or. l .eq. k) go to 70
c  j and l are bonded.  construct unit vector in ijl plane, normal
c  to ij.
      pjl=c(1,l)-c(1,j)
      qjl=c(2,l)-c(2,j)
      rjl=c(3,l)-c(3,j)
      dot=pjl*pij + qjl*qij + rjl*rij
      pjl=pjl-dot*pij
      qjl=qjl-dot*qij
      rjl=rjl-dot*rij
      a=dsqrt(pjl**2+qjl**2+rjl**2)
      if (a .lt. 1.0d-4) go to 80
      pjl=pjl/a
      qjl=qjl/a
      rjl=rjl/a
      p=p+1
      if (p .le. max) go to 65
      call prtbuf(n,max,4, m, v)
      p=1
65    m(1,p)=k
      m(2,p)=i
      m(3,p)=j
      m(4,p)=l
      cosine=pik*pjl+qik*qjl+rik*rjl
      sine=pij*(qjl*rik-rjl*qik)
     *   + qij*(rjl*pik-pjl*rik) + rij*(pjl*qik-qjl*pik)
      v(p)=(180.0d0/pi)* datan2(sine,cosine)
70    continue
80    continue
90    continue
100   continue
      if (p .gt. 0) call prtbuf(n,p,4, m, v)
      if (p .eq. 0) write (iwr,1009)
c
c     ----- reset core memory
c
      call gmem_free_inf(i10,fnm,snm,'i10')
      return
      end
      subroutine struct_check(n, c, az, nuct, bl)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      dimension c(3,*),az(*),nuct(*)
      dimension bl(*)
      dimension ilifz(maxat)
INCLUDE(common/iofile)
INCLUDE(common/prints)
INCLUDE(common/runlab)
INCLUDE(common/coval)
INCLUDE(common/structchk)
INCLUDE(common/phycon)
      character*7 fnm
      character*12 snm
      data fnm,snm/"util1.m","struct_check"/
c
      data two/2.0d0/
      data zsadd/'saddle'/
c
      if(zruntp.eq.zsadd) return
c
c     ----- get core memory
c
      length=n*n
      i10 = igmem_alloc_inf(length,fnm,snm,'i10',IGMEM_DEBUG)
      scale = 1.15d0
      toler = 0.5d0
      obond = .false.
      odiss = .false.
c
      do i=1,n
       ilifz(i)=(i-1)*n+i10-1
      enddo
c
      call vclr(bl(i10),1,length)
      nm1=n-1
      do i=1,nm1
      iz= nint(az(i))
      if(nuct(i).le.3)then
       covi=two
       if (iz .gt. 0 .and. iz .le. 100) covi=cov(iz)
       ip1=i+1
c
       do j=ip1,n
        if(nuct(j).le.3) then
         ij=i+ilifz(j)
         bl(ij)=
     +   dsqrt((c(1,j)-c(1,i))**2+(c(2,j)-c(2,i))**2+(c(3,j)-c(3,i))**2)
         jz= nint(az(j))
         covj=two
         if (jz .gt. 0 .and. jz .le. 100) covj=cov(jz)
         if (bl(ij) .gt. (covi+covj)*scale+toler) bl(ij)=-bl(ij)
         bl(j+ilifz(i))=bl(ij)
c
        endif
       enddo
c
      endif
      enddo
c
c
      if (opoint1) then
c
      nbond1=0
      do i=1,nm1
      ip1=i+1
       do j=ip1,n
       ij=i+ilifz(j)
       if (bl(ij) .gt. 0.0d0) then
        nbond1=nbond1+1
        if (nbond1.gt.mxbnd) then
         write(iwr,1002) nbond1
         go to 200
        endif
        mbond1(1,nbond1)=i
        mbond1(2,nbond1)=j
        vbond1(nbond1)=bl(ij) *toang(1)
       endif
       enddo
      enddo
c
      if(oprint(56)) then
       write (iwr,1001)
       write (iwr,1005)
       do i=1,nbond1
        write(iwr,1003) mbond1(1,i),mbond1(2,i),vbond1(i)
       enddo
       write(iwr,1004)
      endif

      else
c
c     all subsequent points
c
      if(oprint(56)) write (iwr,1001)
c
      nbond2=0
      do i=1,nm1
      ip1=i+1
       do j=ip1,n
       ij=i+ilifz(j)
       if (bl(ij) .gt. 0.0d0) then
        nbond2=nbond2+1
        if (nbond2 .gt. mxbnd) go to 250
         mbond2(1,nbond2)=i
         mbond2(2,nbond2)=j
         vbond2(nbond2)=bl(ij) *toang(1)
       endif
       enddo
      enddo
c
      if(oprint(56)) then
       do i=1,nbond2
        write(iwr,1003) mbond1(1,i),mbond1(2,i),vbond2(i)
       enddo
       write(iwr,1004)
      endif
c
c     now compare with the initial point
c
 250   continue
c
      mprint = 0
      do i=1,nbond1
       mb1 = mbond1(1,i)
       mb2 = mbond1(2,i)
       bl1 = vbond1(i)
c      note that the following check may not function
c      correctly given that nbond can fall to zero ..
c      use change in no. of bonds as a second test
       do j=1,nbond2
        if(mb1.eq.mbond2(1,j).and.mb2.eq.mbond2(2,j)) then
c       examine change in bond length
         if(vbond2(j).gt.scalel*bl1) then
c       trouble ?
         obond = .true.
         mprint = mprint + 1
         if(mprint.eq.1)write(iwr,1240)
c        limit printing to the 1st 20 occurrences
         if(mprint.le.20) then
          write(iwr,1250) mbond2(1,j), mbond2(2,j), vbond2(j)
         endif
         endif
        endif
       enddo
      enddo
c
      endif
c
 200  continue
c
      if (opoint1) then
       opoint1 = .false.
      else
       odiss = nbond1 .ne. nbond2. or. obond
       if (odiss) then
        write (iwr,1009) nbond1, nbond2
       else
       if (.not.obond) write (iwr,1010)
       endif
      endif
c
c     ----- reset core memory
c
      call gmem_free_inf(i10,fnm,snm,'i10')
c
c     should we terminate the optimization ?
c     two consecutive failures do the trick here
c
      ofatal = odiss.and.ofatal
      if (ofatal) then
       write(iwr,1006)
 1006  format(//
     +5x,'***************************************************'/
     +5x,'*** An analysis of two consective points in the ***'/
     +5x,'*** optimisation suggests the molecule is       ***'/
     +5x,'*** dissociating. If this appears unreasonable  ***'/
     +5x,'*** consider redefining the starting geometry   ***'/
     +5x,'*** and using a better starting Hessian.        ***'/
     +5x,'***************************************************'//)
       call caserr2('Molecule appears to be dissociating')
      else if(odiss) then
       ofatal = odiss
      endif
c
      return
c
 1002 format(/10x,' WARNING - maximum of ',i3,
     + ' bonds exceeded - distance checking impeded'/)
 1001 format(10x,60('=')/
     +  10x,'*** distance checking of bond lengths in operation'/
     +  10x,60('='))
 1005 format(10x,'*** First point'/10x,60('='))
 1003 format(21x,i5,2x,i5,3x,f10.5)
 1004 format(10x,60('='))
 1240 format(/10x,68('+'))
 1250 format(10x,'WARNING: bond may be dissociating! ',
     + ' atoms ',I4,2x,I4,1x,F10.5, 'angs.')
 1009 format(//5x,'*** apparent change in bonding detected '/ 
     +5x,'*** no. of bonds detected in starting geometry = ',i3/
     +5x,'*** no. of bonds detected in current geometry  = ',i3/)
 1010 format(/10x,'*** bond length tests validated ***')
      end
      subroutine prtbuf(nat,n,k, m, v)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension v(*),m(4,*)
INCLUDE(common/iofile)
INCLUDE(common/phycon)
      data xbra,xket/'(',')'/
c
      if(nat.le.99) then
      do 10 i=1,n
      do 10 j=2,k
10    if (m(j,i) .lt. 10) m(j,i)=-m(j,i)
c
      go to (20,20,30,40), k
c
20    write (iwr,1000) (m(1,i), m(2,i), v(i), i=1,n)
1000  format (//1x, 7(i2, '-', i2, f11.7, 2x))
      do 25 i=1,n
25    v(i)=v(i)*toang(1)
      write (iwr,1005) (xbra, v(i), xket, i=1,n)
1005  format (7(7x, a1, f9.7, a1))
      return
c
30    write (iwr,1010) (m(1,i), m(2,i), m(3,i), v(i), i=1,n)
1010  format(/1x,5(i2,2('-',i2),f12.6,2x),i2,2('-',i2),f12.6)
      return
c
40    write (iwr,1020) (m(1,i), m(2,i), m(3,i), m(4,i), v(i), i=1,n)
1020  format (/1x, 5(i2, 3('-', i2), f12.6, 2x))
c
      return
c
      elseif (nat.le.999) then
c
      do 15 i=1,n
      do 15 j=2,k
15    if (m(j,i) .lt. 100) m(j,i)=-m(j,i)
c
      go to (50,50,60,70), k
c
50    write (iwr,1001) (m(1,i), m(2,i), v(i), i=1,n)
1001    format (//1x, 7(i3, '-', i3, f9.5, 2x))
      do 55 i=1,n
55    v(i)=v(i)*toang(1)
      write (iwr,1006) (xbra, v(i), xket, i=1,n)
1006  format (7(9x, a1, f7.5, a1))
      return
c
60    write (iwr,1011) (m(1,i), m(2,i), m(3,i), v(i), i=1,n)
1011  format(/1x,5(i3,2('-',i3),f9.3,2x),i3,2('-',i3),f9.3)
      return
c
70    write (iwr,1021) (m(1,i), m(2,i), m(3,i), m(4,i), v(i), i=1,n)
1021  format (/1x, 5(i3, 3('-', i3), f8.2, 2x))
      return
      else
*     4 digit atom numbers
      do 115 i=1,n
      do 115 j=2,k
115   if (m(j,i) .lt. 1000) m(j,i)=-m(j,i)
c
      go to (150,150,160,170), k
c
150    write (iwr,1101) (m(1,i), m(2,i), v(i), i=1,n)
1101    format (//1x, 7(i4, '-', i4, f9.5, 2x))
      do 155 i=1,n
155    v(i)=v(i)*toang(1)
      write (iwr,1106) (xbra, v(i), xket, i=1,n)
1106  format (7(9x, a1, f7.5, a1))
      return
c
160    write (iwr,1111) (m(1,i), m(2,i), m(3,i), v(i), i=1,n)
1111  format(/1x,5(i4,2('-',i4),f9.3,2x),i4,2('-',i4),f9.3)
      return
c
170    write (iwr,1121) (m(1,i), m(2,i), m(3,i), m(4,i), v(i), i=1,n)
1121  format (/1x, 5(i4, 3('-', i4), f8.2, 2x))
      return
      endif
      end
      subroutine inlist(in,max,ival,ixc)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/work)
      dimension in(*)
      data zspace,zto/' ','to'/
c     i=0
 1    call inpa(ztest)
      if(ztest.eq.zspace)go to 2
      jrec=jrec-1
      call inpi(j)
      call inpa(ztest)
      if(ztest.ne.zto)go to 3
      call inpi(k)
      go to 4
 3    k=j
      jrec=jrec-1
 4    if(j.lt.1.or.k.lt.j.or.k.gt.max)call caserr2(
     *'invalid iteration count specified')
      do 5 l=j,k
      if(in(l).ne.ixc)in(l)=ival
 5    continue
      go to 1
 2    return
      end
      subroutine ngdiag(a,q,e,iky,n,ndim,jtype,threshs)
c      version of ligen using f02abf
c
c     note that this version always produces eigenvalues
c    is ascending order
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/overrule)
      dimension a(*),e(*),q(ndim,n),iky(*)
      dimension y(maxorb)
      logical jaco
      common/jacobc/jaco
      thresh = threshs
      if (i_global_diag.ne.-999) thresh = 10.0d0**(-i_global_diag*1.0d0)
c  
      if (jaco) then
         call jacob2(a,q,e,iky,n,ndim,jtype,thresh)
      else
         do 30 i = 1 , n
            do 20 j = 1 , i
               ij = iky(i) + j
               q(i,j) = a(ij)
               q(j,i) = a(ij)
 20         continue
 30      continue
         ifail = 0
         call f02abf(q,ndim,n,e,q,ndim,y,ifail)
      end if
      return
      end
      subroutine jacob2(a,q,e,iky,n,ndim,jtype,thresh)
c     original version of ligen (essentially jacobi routine)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension a(*),e(*),q(ndim,n),iky(*)
      dimension y(maxorb)
      data zero,one,half/0.0d0,1.0d0,0.5d0/
      data tenth/0.1d0/
      data m1/1/
      do 30 i = 1 , n
         do 20 j = 1 , n
            q(i,j) = zero
 20      continue
         q(i,i) = one
 30   continue
      if (n.eq.m1) then
         e(1) = a(1)
         return
      else
 40      te = zero
         do 60 i = 2 , n
            i1 = i - 1
            ikyi = iky(i)
            do 50 j = 1 , i1
               temp = dabs(a(j+ikyi))
               if (te.lt.temp) te = temp
 50         continue
 60      continue
         if (te.lt.thresh) then
            do 70 i = 1 , n
               e(i) = a(iky(i)+i)
 70         continue
            go to (140,170,200) , jtype
         else
            te = te*tenth
            do 130 i = 2 , n
               i1 = i - 1
               ip1 = i + m1
               ikyi = iky(i)
               itest = n - ip1
               ii = i + ikyi
               do 80 ir = 1 , n
                  y(ir) = q(ir,i)
 80            continue
               do 110 j = 1 , i1
                  ij = j + ikyi
                  vij = a(ij)
                  if (dabs(vij).ge.te) then
                     vii = a(ii)*half
                     j1 = j - 1
                     jp1 = j + m1
                     ikyj = iky(j)
                     jj = j + ikyj
                     vjj = a(jj)*half
                     temp = vii - vjj
                     tem = dsqrt(temp*temp+vij*vij)
                     if (temp.lt.0) then
                        tem = -tem
                     end if
                     cost = (temp+tem)/vij
                     sint = dsqrt(one/(one+cost*cost))
                     cost = cost*sint
                     temp = vii + vjj
                     a(ii) = temp + tem
                     a(jj) = temp - tem
                     a(ij) = zero
                     if (j1.gt.0) then
                        call drot(j1,a(ikyi+1),1,a(ikyj+1),1,cost,sint)
                     end if
                     if (i1.ge.jp1) then
                        do 90 k = jp1 , i1
                           jj = iky(k) + j
                           vij = a(k+ikyi)
                           a(k+ikyi) = vij*cost + a(jj)*sint
                           a(jj) = a(jj)*cost - vij*sint
 90                     continue
                     end if
                     if (itest.ge.0) then
                        do 100 k = ip1 , n
                           ij = iky(k) + i
                           jj = j + iky(k)
                           vij = a(ij)
                           a(ij) = vij*cost + a(jj)*sint
                           a(jj) = a(jj)*cost - vij*sint
 100                    continue
                     end if
                     call drot(n,y,1,q(1,j),1,cost,sint)
                  end if
 110           continue
               do 120 ir = 1 , n
                  q(ir,i) = y(ir)
 120           continue
 130        continue
            go to 40
         end if
      end if
c
c     sort eigenvalues into increasing order
 140  do 160 min = 1 , n
         jm = min
         em = e(min)
         do 150 j = min , n
            if (e(j).lt.em) then
               em = e(j)
               jm = j
            end if
 150     continue
         if (jm.ne.min) then
            temp = e(jm)
            e(jm) = e(min)
            e(min) = temp
            call dswap(n,q(1,jm),1,q(1,min),1)
         end if
 160  continue
      go to 200
c
c     sort into decreasing order
 170  do 190 max = 1 , n
         jm = max
         em = e(max)
         do 180 j = max , n
            if (e(j).gt.em) then
               jm = j
               em = e(j)
            end if
 180     continue
         if (jm.ne.max) then
            temp = e(jm)
            e(jm) = e(max)
            e(max) = temp
            call dswap(n,q(1,jm),1,q(1,max),1)
         end if
 190  continue
c
 200  return
      end
      subroutine gldiag(l0,ldum,l1,h,ib,eig,vector,ia,iop2)
c
c     ----- general calling  routine for giveis or ligen
c           ligen version -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/overrule)
      dimension vector(*),h(*),ib(*),eig(*),ia(*)
      do 10 i=1,l0
 10   ib(i)=(i-1)*ldum
      th=1.0d-15
      if (i_global_diag.ne.-999) th = 10.0d0**(-i_global_diag*1.0d0)
c  

      iop1=2
      call jacobi(h,ia,l0,vector,ib,l1,eig,iop1,iop2,th)
      return
      end
_IFN(unicos)
c
c  jacobi - general entry point (includes distributed data diagonaliser 
c           if available) 

      subroutine jacobi(a,iky,newbas,q,ilifq,nrow,e,iop1,
     *iop2,threshs)
_IF1(a)c with concurrency get incorrect results for more than 1 processor
_IF1(a)cvd$r noconcur
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)

INCLUDE(common/sizes)
INCLUDE(common/parcntl)
INCLUDE(common/timeperiods)

      dimension a(*),q(*),e(*),iky(*),ilifq(*)
      dimension ppp(2*maxorb),omask(maxorb),iipt(maxorb),
     +             ipt(maxorb)
_IF1(h)      common/scftim/tdiag,tmxmb(9)
INCLUDE(common/overrule)

      integer iskip, nn, ij, ji, k, i, j, ifail
      dimension w(10)
c
      ierr = 0
      thresh = threshs
      if (i_global_diag.ne.-999) thresh = 10.0d0**(-i_global_diag*1.0d0)
c  

      if(newbas .eq. 1)then

         e(1)=a(1)
         q(1)=1.0d0

      else
_IF(diag_parallel)
         if(nrow.ge.idpdiag)then
            if(newbas.ne.nrow) then
               if(opg_root()) write(6,*) 'newbas, nrow = ', 
     &   newbas, nrow
               call caserr2('** newbas.ne.nrow **') 
            endif

            if (iop1.eq.1) call caserr('pdiag only does iop.ne.1')
c
c parallel diagonaliser 
c
            call pg_synch(10203)

            if(ipdiagif .eq. IDIAG_GAWRAP)then
c
c pg_eig_solve calls peigs or scalapack through the GA interface
c
               call pg_eig_solve( nrow, a, q, e )

            elseif (ipdiagmode.eq.IDIAG_PEIGS) then
c
c unwrapped peigs requested 
c
_IF(peigs)
               call start_time_period(TP_PEIGS)
               call gms_pdiag(nrow, a, q, e, ierr)
               call end_time_period(TP_PEIGS)
_ELSE
              call 
     &  caserr('Peigs diag requested but not part of this build')
_ENDIF
            else
c
c unwrapped scalapack requested, needs newscf
c
_IF(_AND(newscf,scalapack))
c
                call pdiag_f90(nrow, a, q, e, ierr)
c
_ELSE
               write(iwr,*)
     &  'ScaLAPACK diags with F90 wrappers not available'
               write(iwr,*)
     &  'Include newscf and scalapack options in your build, or'
               write(iwr,*)'choose another option, either'
               write(iwr,*)'    parallel diag peigs    or'
               write(iwr,*)'    parallel diag gawrap '
               call caserr('Parallel diag config error')
_ENDIF
            endif

            if(ierr.ne.0)then
                write(6,*)'ierr=',ierr,' node=',ipg_nodeid()
                call caserr('jacobi: problem in parallel diag')
            endif

cjvl  why the stretch is here beats me, but now it is protected
       if (ilifq(2).ne.newbas.and.ilifq(1).eq.0.and.ilifq(2).lt.maxorb)
     &   call stretch(q,newbas,ilifq(2),ilifq,0)

c         call chk_ortho( nrow, q )
c
c construct diagonal triangle, A

            do i = 1 , nrow
               a(iky(i) + i) = e(i)
               do j = 1 , i-1
                  a(iky(i) + j) = 0.0d0
               enddo
            enddo
         else
_ENDIF
c
c  use serial jacobi code
c
            if(iop1.ne.1) then
               do  i=1,newbas
                  ilifi=ilifq(i)
                  call vclr(q(ilifi+1),1,nrow)
                  q(ilifi+i)=1.0d0
               enddo
            endif

 86         te=0.0d0
            do i=2,newbas
               i1=i-1
               ikyi=iky(i)
               do j=1,i1
                  temp= dabs(a(j+ikyi))
                  if(te.lt.temp)te=temp
               enddo
            enddo

            if(te.lt.thresh)goto 99
            te=te*0.1d0
_IFN1(v)      do 22 i=2,newbas
_IF1(v)      do 2 i=2,newbas
               i1=i-1
               ip1=i+1
               ikyi=iky(i)
               itest=newbas-ip1
               ii=i+ikyi
               ilifi=ilifq(i)
_IF1(v)       call dcopy(nrow,q(ilifi+1),1,ppp,1)
              do 22 j=1,i1
                 ij=j+ikyi
                 vij=a(ij)
                 if( dabs(vij) .lt. te) go to 22
                 vii=a(ii)*0.5d0
                 j1=j-1
                 jp1=j+1
                 ikyj=iky(j)
                 jj=j+ikyj
                 vjj=a(jj)*0.5d0
                 temp=vii-vjj
                 tem=dsqrt(temp*temp+vij*vij)

                 if(temp.lt.0.0d0) tem=-tem
                 cost=(temp+tem)/vij
                 sint=dsqrt(1.0d0/(1.0d0+cost*cost))
                 cost=cost*sint
                 temp=vii+vjj
                 a(ii)=temp+tem
                 a(jj)=temp-tem
                 a(ij)=0.0d0

                 if(j1.gt.0)then
_IFN1(v)            call drot(j1,a(ikyi+1),1,a(ikyj+1),1,cost,sint)
_IF1(v)             do 4 k=1,j1
_IF1(v)               jj=k+ikyj
_IF1(v)               vij=a(k+ikyi)
_IF1(v)               a(k+ikyi)=vij*cost+a(jj)*sint
_IF1(v)4              a(jj)=a(jj)*cost-vij*sint
                endif
                if(i1.ge.jp1)then
                   do k=jp1,i1
                      jj=iky(k)+j
                      vij=a(k+ikyi)
                      a(k+ikyi)=vij*cost+a(jj)*sint
                      a(jj)=a(jj)*cost-vij*sint
                   enddo
                endif
 5              if(itest.ge.0)then
                   do k=ip1,newbas
                      ij=iky(k)+i
                      jj=j+iky(k)
                      vij=a(ij)
                      a(ij)=vij*cost+a(jj)*sint
                      a(jj)=a(jj)*cost-vij*sint
                   enddo
                endif

_IF1(v)     j1=ilifq(j)
_IF1(v)      do 9 k=1,nrow
_IF1(v)      vjj=q(k+j1)
_IF1(v)      q(k+j1)=vjj*cost-ppp(k)*sint
_IF1(v)9     ppp(k)=ppp(k)*cost+vjj*sint
_IFN1(v)      call drot(nrow,q(ilifi+1),1,q(ilifq(j)+1),1,cost,sint)

 22            continue

_IF1(v)2      call dcopy(nrow,ppp(1),1,q(ilifi+1),1)
              goto 86
 99           continue
_IF(diag_parallel)
         endif
_ENDIF
         do 11 i=1,newbas
            omask(i)=.false.
            e(i)=a(iky(i)+i)
            iipt(i)=i/2
 11      continue

         goto (67,55,55,43),iop2
c... binary sort of e.values to increasing value sequence

 55      ipt(1)=1
         do 19 j=2,newbas
             ia=1
             ib=j-1
             test=e(j)
 53          irm1=ib-ia
             if(irm1)58,50,51
 51          ibp=ia+iipt(irm1)
             if(test.lt.e(ipt(ibp)))goto 52
c...  insert into high half
             ia=ibp+1
             goto 53
c... insert into low half
 52          jj=ib
             do 54 i=ibp,ib
                ipt(jj+1)=ipt(jj)
 54          jj=jj-1
             ib=ibp-1
             goto 53
c...  end point of search
 50          jj=ipt(ia)
             if(test.ge.e(jj))goto 57
             ipt(ia+1)=jj
 58          ipt(ia)=j
             goto 19
 57          ipt(ia+1)=j
 19       continue

          goto (67,68,69,43),iop2
c...   sort by decreasing e.value(invert order)
 69       itest=newbas+1
          ip1=iipt(newbas)
          do 41    i=1,ip1
             j=itest-i
             k=ipt(i)
             ipt(i)=ipt(j)
             ipt(j)=k
 41       continue
 68       do 20 i=1,newbas
             k=ipt(i)
             iipt(k)=i
             ppp(i)=e(k)
 20       continue
 59       continue
c
          call dcopy(newbas,ppp(1),1,e(1),1)
c...  iipt(i)=k   means column i is to move to posn k
c...   ipt(i)=k   means column k is to move to posn i
          call sortq(q,ilifq,iipt,newbas,nrow)
          go to 67
c
c ... locking requested
c
 43       do 31 j=1,newbas
             m=ilifq(j)
             temp=0.0d0
             do 32 i=1,newbas
                vij= dabs(q(i+m))
                if(vij.lt.temp.or.omask(i))goto 32
                temp=vij
                k=i
 32          continue
             iipt(j)=k
             omask(k)=.true.
             ppp(k)=e(j)
 31       continue
          goto 59

 67       continue
      endif
      return
      end
c
c utility routine for Peigs interface
c
      subroutine reconstitute_evecs( order, evecs)
      implicit none
c
      integer          order
      REAL evecs( 1:order * order )
c
      integer first_length, second_length
      integer second_start
c
      first_length  = order * ( order + 1 ) / 2
      second_length = order * ( order - 1 ) / 2
      second_start = first_length + 1
c
      call pg_dgop( 16467, evecs, first_length, '+' )
      call pg_dgop( 16467, evecs( second_start ), second_length,
     &  '+')
c
      end
c
c  Entry point for symmetrised jacobi
c
      subroutine jacobi_symm( a, iky, newbas, q, ilifq, nrow, e, iop1,
     *                       iop2, threshs, 
     +                       basis_symmetry, use_symmetry)
*
*  Version calling distributed data diagonliser and using
* symmetry to ensure the evecs do not become symmetry 
* contaminated.
*     
_IF1(a)c with concurrency get incorrect results for more than 1 processor
_IF1(a)cvd$r noconcur
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
*
      Integer basis_symmetry( 1:nrow )
      Logical use_symmetry
      Logical force_serial
*
*  Parameter for how much to shift diagonal elements in the
* Hamiltonian if using symmetry to help resolve symmetry
* contamination difficulties.
*
      REAL       shift
      Parameter( shift = 1.0d3 )
*
INCLUDE(common/sizes)
INCLUDE(common/parcntl)
INCLUDE(common/timeperiods)
INCLUDE(common/iofile)
INCLUDE(common/overrule)

      dimension a(*),q(*),e(*),iky(*),ilifq(*)

      dimension ppp(2*maxorb),omask(maxorb),iipt(maxorb),
     +     ipt(maxorb)
_IF1(h)      common/scftim/tdiag,tmxmb(9)

      integer  k, i, j

      Integer n_irreps, a_point( 1:maxorb ), q_point( 1:maxorb )
      Integer diag_order( 1:2, 1:8 )
      Integer size_diag, block_start

      If( newbas .NE. nrow ) Then
         Call caserr2( 'NEWBAS not equal to NROW in jacobi' )
      End If

      ierr = 0
      thresh = threshs
      if (i_global_diag.ne.-999) thresh = 10.0d0**(-i_global_diag*1.0d0)
c  

      dumtim=dclock()

      If( .Not. use_symmetry ) Then

c        If( opg_root() ) Then
c           Write( 6, * ) 'serial jacobi:', nrow
c        End If

         Call jacobi( a, iky, newbas, q, ilifq, nrow, e, iop1,
     *                iop2, thresh )
      Else

         n_irreps = 0
         Do i = 1, nrow
            n_irreps = Max( n_irreps, basis_symmetry( i ) )
         End Do
      
         Call classify_diags( nrow, basis_symmetry, 
     +                        n_irreps, diag_order )

         Call block_a( nrow, n_irreps, basis_symmetry, diag_order, 
     +                 ipt, a, a_point, q_point, q )

         Do i = 1, nrow * nrow
            q( i ) = 0.0d0
         End Do

         block_start = 1
         Do i = 1, n_irreps

            size_diag = diag_order( 2, i )

            if(size_diag.gt.0) then

               Do j = 1, size_diag
                  ipt ( j ) = a_point( block_start + j - 1 ) -
     +                 a_point( block_start ) 
                  iipt( j ) = ( j - 1 ) * size_diag 
               End Do

               Call jacobi( a( a_point( block_start ) ), ipt,
     +                       size_diag, 
     +                       q( q_point( block_start ) ), iipt,
     +                       size_diag,
     +                       e( block_start ),
     +                       iop1, 1, thresh )

               Call shift_evecs( nrow, size_diag, 
     +                        q, q_point( block_start ) )

               block_start = block_start + size_diag
            endif
         End Do

         Call restore_orig_symmetry( nrow, n_irreps, q, 
     +                               basis_symmetry, diag_order,
     +                               a )
*
c     
c     construct diagonal triangle, A
         
         do i = 1 , nrow
            a(iky(i) + i) = e(i)
            do j = 1 , i-1
               a(iky(i) + j) = 0.0d0
            enddo
         enddo

         do 11 i=1,newbas
            omask(i)=.false.
            e(i)=a(iky(i)+i)
            iipt(i)=i/2
 11      continue

         goto (67,55,55,43),iop2
c... binary sort of e.values to increasing value sequence
 55      ipt(1)=1
         do 19 j=2,newbas
            ia=1
            ib=j-1
            test=e(j)
 53         irm1=ib-ia
            if(irm1)58,50,51
 51         ibp=ia+iipt(irm1)
            if(test.lt.e(ipt(ibp)))goto 52
c...  insert into high half
            ia=ibp+1
            goto 53
c... insert into low half
 52         jj=ib
            do i=ibp,ib
               ipt(jj+1)=ipt(jj)
               jj=jj-1
            enddo
            ib=ibp-1
            goto 53
c...  end point of search
 50         jj=ipt(ia)
            if(test.ge.e(jj))goto 57
            ipt(ia+1)=jj
 58         ipt(ia)=j
            goto 19
 57         ipt(ia+1)=j
 19      continue
         goto (67,68,69,43),iop2
c...   sort by decreasing e.value(invert order)
 69      itest=newbas+1
         ip1=iipt(newbas)
         do i=1,ip1
            j=itest-i
            k=ipt(i)
            ipt(i)=ipt(j)
            ipt(j)=k
         enddo
 68      do i=1,newbas
            k=ipt(i)
            iipt(k)=i
            ppp(i)=e(k)
         enddo
 59      continue
c     
         call dcopy(newbas,ppp(1),1,e(1),1)
c...  iipt(i)=k   means column i is to move to posn k
c...   ipt(i)=k   means column k is to move to posn i
         if (ilifq(2).ne.newbas)call stretch(q,newbas,ilifq(2),
     1          ilifq,0)
         call sortq(q,ilifq,iipt,newbas,nrow)
         go to 67
c     
c     ... locking requested (vectors close packed dim newbas)
c     
 43      do j=1,newbas
            m = (j-1)*newbas
            temp=0.0d0
            do 32 i=1,newbas
               vij= dabs(q(i+m))
               if(vij.lt.temp.or.omask(i))goto 32
               temp=vij
               k=i
 32         continue
            iipt(j)=k
            omask(k)=.true.
            ppp(k)=e(j)
         enddo
         goto 59
 67      continue
      endif
      return
      end

      subroutine sortq(q,ilifq,iipt,newbas,nrow)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension q(*),ilifq(*),iipt(*)
      dimension ppp(2*maxorb),omask(maxorb)
      juse=1
      jnext=maxorb+1
_IF1(iv)      do 1 i=1,newbas
_IF1(iv)   1  omask(i)=.false.
_IFN1(ivf)      call setstl(newbas,.false.,omask)
_IF1(f)      call vfill(.false.,omask,1,newbas)
       do 21 i=1,newbas
      if(omask(i))goto 21
      j=i
      call dcopy(nrow,q(ilifq(j)+1),1,ppp(juse),1)
c...   start a permutation cycle
   23 m=iipt(j)
      ilifi=ilifq(m)
      call dcopy(nrow,q(ilifi+1),1,ppp(jnext),1)
      call dcopy(nrow,ppp(juse),1,q(ilifi+1),1)
      if(m.eq.i)goto 21
      juse=jnext
      jnext=maxorb+2-jnext
      omask(m)=.true.
      j=m
      goto 23
   21 continue
      return
      end
_ENDIF
_IF(unicos)
c
c   jacobi -  UNICOS version
c
      subroutine jacobi(a,iky,newb,q,ilifq,nrow,e,iop1,iop2,
     * threshs)
      implicit REAL  (a-h,o-z)
      logical mas
INCLUDE(common/sizes)
INCLUDE(common/overrule)
      dimension a(*),q(*),e(*),ilifq(*),iky(*)
      dimension mas(maxorb),x(maxorb),ipt(maxorb),iipt(maxorb)
      thresh = threshs
      if (i_global_diag.ne.-999) thresh = 10.0d0**(-i_global_diag*1.0d0)
c  
      call gather(newb,x,a,iky(2))
      if(iop1.eq.2) then
      do 44 i=1,newb
      ilifi=ilifq(i)
      call szero(q(ilifi+1),nrow)
   44 q(ilifi+i)=1.0d0
      endif
      if(newb.eq.1)goto 6667
      call diag(a,iky,newb,q,ilifq,nrow,x,thresh)
      goto (6667,5555,5555,4444),iop2
c... binary sort of e.values to increasing value sequence
5555  ipt(1)=1
      do 11 j=1,newb
11    iipt(j)=j/2
      do 19 j=2,newb
      ia=1
      ib=j-1
      test=x(j)
193   irm1=ib-ia
      if(irm1)198,190,191
191   ibp=ia+iipt(irm1)
      if(test.lt.x(ipt(ibp)))goto 192
c...  insert into high half
      ia=ibp+1
      goto 193
c... insert into low half
192   jj=ib
      do 194 i=ibp,ib
      ipt(jj+1)=ipt(jj)
194   jj=jj-1
      ib=ibp-1
      goto 193
c...  end point of search
190   jj=ipt(ia)
      if(test.ge.x(jj))goto 195
      ipt(ia+1)=jj
198   ipt(ia)=j
      goto 19
195    ipt(ia+1)=j
19     continue
       goto (6667,6668,6669,4444),iop2
c...   sort by decreasing e.value(invert order)
6669  itest=newb+1
      ip1=iipt(newb)
      do 10540 i=1,ip1
      j=itest-i
      k=ipt(i)
      ipt(i)=ipt(j)
10540 ipt(j)=k
6668  do 20 i=1,newb
      k=ipt(i)
20    iipt(k)=i
199   call scatter(newb,e,iipt,x)
c...  iipt(i)=k  :: means column i is to move to posn k
c...   ipt(i)=k  :: means column k is to move to posn i
      call sortq(q,ilifq,iipt,newb,nrow)
      return
c ... locking requested
4444  call setsto(newb,.false.,mas)
      do 31 j=1,newb
      m=ilifq(j)
      test=0.0
      do 32 i=1,newb
      vij=dabs(q(i+m))
      if(test.ge.vij.or.mas(i))goto 32
      test=vij
      k=i
32    continue
      iipt(j)=k
31    mas(k)=.true.
      goto 199
6667  call fmove(x,e,newb)
      return
      end
      subroutine diag(a,iky,newbas,q,ilifq,nrow,e,thresh)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      dimension a(*),q(*),ilifq(*),e(*),iky(*)
      dimension y(maxorb)
      nm1=newbas-1
      nvrs=iky(newbas)+newbas-2
c      write(6,9999)newbas,nvrs
c9999  format(' newbas,nvrs ',2i4)
      call scatt(nm1,0.0,a,iky(2))
20500 loop=idamax(nvrs,a(2),1)
      te=dabs(a(loop+1))
c20500 te=absmax(nvrs,0.0,a(2))
      if(te.lt.thresh)return
      te=te*0.3
      do 2 i=1,nm1
      i1=i-1
      ip1=i+1
      ikyi=iky(i)
      itest=newbas-i
      ilifi=ilifq(i)
      aii=e(i)
      call fmove(a(ikyi+1),y,i)
      call gather(itest,y(ip1),a(ip1),iky(ip1))
      do 22 j=ip1,newbas
      vij=y(j)
      avij=dabs(vij)
      if(avij.lt.te) go to 22
      vjj=e(j)
      j1=j-1
      jp1=j+1
      temp=aii-vjj
      if(avij.ge.(2.5d-4*dabs(temp)))goto 97531
c... determine rotation parameters (3rd order pert. theory)
      tem=vij/temp
      temp=tem*tem
      sint=tem-(1.5*tem*temp)
      cost=1.0-(temp*0.5)
      goto 86420
c... determine rotation parameters (rutishauser algorithm)
97531 temp=temp*0.5
      tem=vij/(dsqrt(temp*temp+vij*vij)+dabs(temp))
      cost=dsqrt(1.0/(tem*tem+1.0))
      if(temp)12345,54321,54321
12345 tem=-tem
54321 sint=cost*tem
86420 call srotv(nrow,q(ilifi+1),q(ilifq(j)+1),cost,sint)
      call srotv(j1,y,a(iky(j)+1),cost,sint)
      tem=tem*vij
      aii=aii+tem
      e(j)=vjj-tem
      y(j)=0.0
      call srotg(newbas-j,y(jp1),a(jp1),iky(jp1),cost,sint)
22    continue
      call fmove(y,a(ikyi+1),i1)
      call scatter(itest,a(ip1),iky(ip1),y(ip1))
2     e(i)=aii
      goto 20500
      end
      subroutine sortq(q,ilifq,iipt,newbas,nrow)
      implicit REAL  (a-h,o-z)
      logical mas
INCLUDE(common/sizes)
      dimension q(*),ilifq(*),iipt(*)
      dimension mas(maxorb)
      call setsto(newbas,.false.,mas)
      do 21 i=1,newbas
      if(mas(i))goto 21
      j=i
      ilifi=ilifq(i)
c...   start a permutation cycle
23    k=iipt(j)
      if(k.eq.i)goto 21
      call swapv(nrow,q(ilifi+1),q(ilifq(k)+1))
      mas(k)=.true.
      j=k
      goto 23
21    continue
      return
      end
c
c  symmetrised diag - UNICOS version
c
      subroutine jacobi_symm( a, iky, newbas, q, ilifq, nrow, e, iop1,
     *                       iop2, threshs, 
     +                       basis_symmetry, use_symmetry,
     +                       force_serial  )
*
*  Version using symmetry to ensure the evecs do not become symmetry 
*  contaminated.
*     
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
*
      Integer basis_symmetry( 1:nrow )
      Logical use_symmetry
      Logical force_serial
*
* Parameter for how much to shift diagonal elements in the
* Hamiltonian if using symmetry to help resolve symmetry
* contamination difficulties.
*
      REAL       shift
      Parameter( shift = 1.0d3 )
*
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/overrule)

      dimension a(*),q(*),e(*),iky(*),ilifq(*)

      logical mas
      REAL x
      dimension mas(maxorb),x(maxorb),ipt(maxorb),iipt(maxorb),
     +             ipt2(maxorb),iipt2(maxorb)

      integer  k, i, j

      Integer n_irreps, a_point( 1:maxorb ), q_point( 1:maxorb )
      Integer diag_order( 1:2, 1:8 )
      Integer size_diag, block_start

      thresh = threshs
      if (i_global_diag.ne.-999) thresh = 10.0d0**(-i_global_diag*1.0d0)
c  

      If( newbas .NE. nrow ) Then
         Call caserr2( 'NEWBAS not equal to NROW in jacobi' )
v      End If

      If( .Not. use_symmetry ) Then
         Call jacobi( a, iky, newbas, q, ilifq, nrow, e, iop1,
     *                iop2, thresh )

      Else

         n_irreps = 0
         Do i = 1, nrow
            n_irreps = Max( n_irreps, basis_symmetry( i ) )
         End Do

         Call classify_diags( nrow, basis_symmetry, 
     +                        n_irreps, diag_order )

         Call block_a( nrow, n_irreps, basis_symmetry, diag_order, 
     +                 ipt, a, a_point, q_point, q )

         Do i = 1, nrow * nrow
            q( i ) = 0.0d0
         End Do

         block_start = 1
         Do i = 1, n_irreps

            size_diag = diag_order( 2, i )

            if(size_diag.gt.0) then

            Do j = 1, size_diag
               ipt2( j ) = a_point( block_start + j - 1 ) -
     +                     a_point( block_start ) 
               iipt2( j ) = ( j - 1 ) * size_diag 
            End Do

            ipt2(size_diag + 1 ) = ipt2(size_diag) + size_diag
*
            Call jacobi( a( a_point( block_start ) ), ipt2,
     +                    size_diag, 
     +                    q( q_point( block_start ) ), iipt2,
     +                    size_diag,
     +                    e( block_start ),
     +                    iop1, 1, thresh )
*
*
            Call shift_evecs( nrow, size_diag, 
     +                        q, q_point( block_start ) )
*
            endif

            block_start = block_start + size_diag
*
         End Do
*
         Call restore_orig_symmetry( nrow, n_irreps, q, 
     +                               basis_symmetry, diag_order,
     +                               a )
*
c     
c     construct diagonal triangle, A
         do i = 1 , nrow
            a(iky(i) + i) = e(i)
            do j = 1 , i-1
               a(iky(i) + j) = 0.0d0
            enddo
         enddo

         do 11 i=1,newbas
            mas(i)=.false.
            e(i)=a(iky(i)+i)
            iipt(i)=i/2
 11      continue

         goto (67,55,55,43),iop2
_IFN1(c)c... binary sort of e.values to increasing value sequence

 55      ipt(1)=1
         do 19 j=2,newbas
            ia=1
            ib=j-1
            test=e(j)
 53         irm1=ib-ia
            if(irm1)58,50,51
 51         ibp=ia+iipt(irm1)
            if(test.lt.e(ipt(ibp)))goto 52
c...  insert into high half
            ia=ibp+1
            goto 53
c... insert into low half
 52         jj=ib
            do 54 i=ibp,ib
               ipt(jj+1)=ipt(jj)
 54            jj=jj-1
               ib=ibp-1
               goto 53
c...  end point of search
 50            jj=ipt(ia)
               if(test.ge.e(jj))goto 57
               ipt(ia+1)=jj
 58            ipt(ia)=j
               goto 19
 57            ipt(ia+1)=j
 19         continue

            goto (67,68,69,43),iop2
c...   sort by decreasing e.value(invert order)
 69         itest=newbas+1
            ip1=iipt(newbas)
            do 41    i=1,ip1
               j=itest-i
               k=ipt(i)
               ipt(i)=ipt(j)
               ipt(j)=k
 41         continue
 68         do 20 i=1,newbas
               k=ipt(i)
               iipt(k)=i
               x(i)=e(k)
 20         continue
 59         continue
c     
            call dcopy(newbas,x(1),1,e(1),1)
c...  iipt(i)=k   means column i is to move to posn k
c...   ipt(i)=k   means column k is to move to posn i
            if (ilifq(2).ne.newbas) call stretch(q,newbas,ilifq(2),
     1          ilifq,0)
            call sortq(q,ilifq,iipt,newbas,nrow)
            go to 67
c     
c     ... locking requested (vectors close packed dim newbas)
c     
 43         do 31 j=1,newbas
               m = (j-1)*newbas
               temp=0.0d0
               do 32 i=1,newbas
                  vij= dabs(q(i+m))
                  if(vij.lt.temp.or.mas(i))goto 32
                  temp=vij
                  k=i
 32            continue
               iipt(j)=k
               mas(k)=.true.
               x(k)=e(j)
 31         continue
            goto 59

 67         continue
         endif

         return
         end
c END UNICOS specific jacobi version
_ENDIF

      logical function odpdiag(idim)
      implicit none
      integer idim
INCLUDE(common/parcntl)
_IF(parallel_diag)
      odpdiag = (idim.ge.idpdiag)
_ELSE
      odpdiag = .false.
_ENDIF
      end

***************************************************************
*     
      Subroutine characterize_mo( n, n_vectors, vectors, symm_ao, 
     +                            n_irreps, symm_mo, error )
*     
*  Given a set of vectors VECTORS and the irreducible representations
* that the basis functions for the vectors span this routine will
* try to identify which of thos irreducible representations each
* of the vectors span.
*     
*  Input:
*  N         : The order of the vectors
*  N_VECTORS : The number of vectors
*  VECTORS   : The vectors
*  SYMM_AO   : The irreps of the basis functions
*     
*  Output:
*  N_IRREPS  : The number of different irreps spanned
*  SYMM_MO   : The irreps that the vectors span
*  ERROR     : Non-zero on failure.
*     
      Implicit None
*     
      Integer n
      Integer n_vectors
      REAL    vectors( 1:n, 1:n_vectors )
      Integer symm_ao( 1:n )
      Integer n_irreps
      Integer symm_mo( 1:n_vectors )
      Integer error
*     
*     In any vector a contribution from a vector of another
*     symmetry up to this value is tolerated. The value is chosen to
*     be consistant with that in the subroutine ANALMO.
*     
      REAL       symmetry_tolerance
      Parameter( symmetry_tolerance = 1.0d-3 )
*     
_IF(single)
      external isamax
      integer  isamax
_ELSE
      external idamax
      integer  idamax
_ENDIF
*     
      REAL    biggest_wrong_symm
      Integer symm_this_mo
      Integer count_irrep_ao( 1:8 )
      Integer count_irrep_mo( 1:8 )
c     Integer where_wrong
      Integer i, j
*     
*  Find out how many irreps are spanned by the vectors
*
      n_irreps = 0
      Do i = 1, n_vectors
         n_irreps = Max( n_irreps, symm_ao( i ) )
      End Do
*     
      error = 0
*     
      Do i = 1, n_vectors
*     
*     Find the biggest element of this vector and so the symmetry
*     of the corresponding basis function. If there is no symmetry
*     contamination this will be the symmetry of the vector.
*     
         symm_this_mo = symm_ao( idamax( n, vectors( 1, i ), 1 ) )
*     
*     Check for symmetry contamination.
*     
         biggest_wrong_symm = -1.0d0
*     
         Do j = 1, n
            If( symm_this_mo .NE. symm_ao( j ) ) Then
*               biggest_wrong_symm = Max( Abs( vectors( j, i ) ),
*     +                                   biggest_wrong_symm )
*               where_wrong = j
               If( Abs( vectors( j, i ) ) .GT. biggest_wrong_symm )Then
                  biggest_wrong_symm = Abs( vectors( j, i ) )
c                 where_wrong = j
               End If
            End If
         End Do
*     
         If( biggest_wrong_symm .GT. symmetry_tolerance ) Then
            error = 1
            Go To 10
         Else
            symm_mo( i ) = symm_this_mo
         End If
*     
      End Do
*     
 10   Continue
*
*  If we have the same number of vectors as basis functions
* check that the number of times each irrep is spanned
* by the vectors is the number of times it is spanned by
* the basis.
*
      If( error .EQ. 0 .And. n .EQ. n_vectors ) Then
*
         Do i = 1, n_irreps
            count_irrep_ao( i ) = 0
            count_irrep_mo( i ) = 0
         End Do
*
         Do i = 1, n
            count_irrep_ao( symm_ao( i ) ) = 
     +           count_irrep_ao( symm_ao( i ) ) + 1
            count_irrep_mo( symm_mo( i ) ) = 
     +           count_irrep_mo( symm_mo( i ) ) + 1
         End Do
*
         Do i = 1, n_irreps
            If( count_irrep_ao( i ) .NE. count_irrep_mo( i ) ) Then
               error = 2
            End If
         End Do
*
      End If
*
      End
*
***************************************************************
*     
*
***************************************************************
*
      Subroutine classify_diags( n, symmetry, n_irreps, diag_order )
*
*  This routine examines the symmetry label of each MO to
* find out the size of the diagonalization required for
* each irrep. It then orders the diag list ( in diag
* order ) so that the largest diag is done first, the
* second second etc.
*     
      Implicit None
*     
      Integer n
      Integer symmetry( 1:n )
      Integer n_irreps
      Integer diag_order( 1:2, 1:8 )
*     
      Integer count_irrep_ao( 1:8 )
      Integer this_count
      Integer i, j
*
      n_irreps = 0
      Do i = 1, n
         n_irreps = Max( n_irreps, symmetry( i ) )
      End Do
*
      Do i = 1, n_irreps
         count_irrep_ao( i ) = 0
      End do
*
*  Count how many AOs span each irrep and store that info
*
      Do i = 1, n
         count_irrep_ao( symmetry( i ) ) = 
     +        count_irrep_ao( symmetry( i ) ) + 1
      End Do
*
      Do i = 1, n_irreps
         diag_order( 1, i ) = i
         diag_order( 2, i ) = count_irrep_ao( i )
      End Do
*
*  Simple insertion sort in decreasing order of the
* size of the diag.
*
      Do j = 2, n_irreps
         this_count = diag_order( 2, j )
         Do i = j - 1, 1, -1
            If( diag_order( 2, i ) .GE. this_count ) Then
               Goto 10
            End If
            diag_order( 1, i + 1 ) = diag_order( 1, i )
            diag_order( 2, i + 1 ) = diag_order( 2, i )
         End Do
         i = 0
 10      diag_order( 1, i + 1 ) = j
         diag_order( 2, i + 1 ) = this_count
      End Do
*
      End
*
************************************************************************
*
      subroutine qmat_symm(q,s,v,e,scr,ia,l0,l1,l3,ndim,out,
     +                     isymmo, use_symmetry )
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)

      REAL q(*)
      Integer isymmo( 1:l1 )
      Logical use_symmetry

INCLUDE(common/gmempara)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/scra7)
INCLUDE(common/sizes)
INCLUDE(common/harmon)
INCLUDE(common/overrule)
INCLUDE(common/machin)
INCLUDE(common/runlab)
      common/craypk/mmmm(65),isymaos(maxorb),isymmos(maxorb)
      common/restri/jjfile(63),lds(508),isect(508),ldsect(508),
     + iacsct(508)
      Integer itab
      dimension ifreq(31)
      dimension s(*),v(ndim,*),e(*),scr(*),ia(*)
      character*7 fnm
      character*9 snm
      data fnm,snm/'util1.m','qmat_symm'/
      data m167,done,tol1,tol0 /167,1.0d0,1.0d-05,1.0d-07/
c
c...  allow specfied crit for dependency (10**-i_depen_check)
c...  (0 => no checking) ; i_depen_check in common/overrule/
c
      if (i_depen_check.ge.0) then
         tol0 = 10.0d0**(-1.0d0*i_depen_check)
         if (i_depen_check.eq.0) tol0 = 1.0d-20
      end if
c
c     ----- diagonalize overlap matrix -----
c
      if (out) then
       write (iwr,9008)
       call prtril(s,l1)
      endif
      len1=lensec(l1+1)
      l2=l1*(l1+1)/2
      lenv=len1+lensec(l2)
      call sectst(isecqm,itest)
      if(itest.eq.0) go to 300
      call secget(isecqm,m167,iblkv)
      call rdedx_prec(scr,1,iblkv,idaf)
      if(scr(1).ne.dfloat(l1)) go to 300
      call rdedx(scr,l1+1,iblkv,idaf)
      call dcopy(l1,scr(2),1,e,1)
      call reads(scr,l2,idaf)
      call vsub(s,1,scr,1,scr,1,l2)
      do i=1,l2
      if( dabs(scr(i)).gt.tol1) go to 300
      enddo
      call reads(v,l3,idaf)
      ibl3qs=iblkv+lenv
      l0=newbas0
      go to 400
300   lenq=lenv+lensec(l3)
      call secput(isecqm,m167,lenq,iblkv)
      call wrt3(s,l2,iblkv+len1,idaf)
c
      if (oharm) call comharm(s,'tri',isymmo)
      call gldiag_symm(newbas0,newbas0,newbas0,s,scr,e,v,ia,2, 
     +                 isymmo, use_symmetry )
      if (oharm) then
         nn = newbas1-newbas0
         call expharm(v,'vectors',scr)
c...     move real vectors to the end
         if (nn.ne.0) then
            do i=l0,1,-1
               e(i+nn) = e(i)
               call dcopy(ndim,v(1,i),1,v(1,i+nn),1)
            end do
            call vclr(v,1,ndim*nn)
            call vclr(e,1,nn)
         endif
      end if
c
      if (nprint .eq. 5) then
        write (iwr,9028)
        call prev(v,e,l1,l1,ndim)
      endif
c
c     ----- eliminate eigenvectors for which eigenvalue is less
c           than tol=tol0
c
c...     first make a frequency table of eigenvalues
      if (o_depen_print) then
         write(iwr,9052) (i,e(newbas1-newbas0+i),i=1,newbas0)
      end if 
      rb = log10(e(newbas1-newbas0+1))
      if (rb.lt.0.0d0) rb = rb - 1.0d0
      ib = rb
      ie = log10(e(newbas1))
      ib = max(ib,-20)
      ie = min(ie,10)
      do i=1,ie-ib+1
         ifreq(i) = 0
      end do
      do i=1,newbas0
         rrii = log10(e(i+newbas1-newbas0))
         if (rrii.lt.0.0d0) rrii = rrii - 1.0d0
         ii = rrii
         ii = max(ii,-20)
         ii = min(ii,10)
         ifreq(ii-ib+1) = ifreq(ii-ib+1) + 1
      end do
c
      dum = e(l1-newbas0+1)
      j = 0
      k = 0
      kk=0
      do 180 i = 1,l1
      if(e(i) .lt. tol1) then
      kk=kk+1
      endif
      if (e(i) .lt. tol0 .or. 
     1    i.le. (newbas1-newbas0+n_depen_check) ) go to 160
      j = j+1
      e(j) = done/  dsqrt(e(i))
      if (i.ne.j) call dcopy(l1,v(1,i),1,v(1,j),1)
      go to 180
  160 k = k+1
  180 continue
      l0 = l1-k
      if(kk.ne.l1-newbas0) write(iwr,9047) dum,kk-(l1-newbas0),tol1
      if (l0.ne.newbas0)   write (iwr,9048) dum,k-(l1-newbas0),tol0,
     1                                      n_depen_check,l0
c     if (zruntp.ne.'force') n_depen_check = 0
      if (kk.ne.l1-newbas0.or.l0.ne.newbas0) then
         ii = 0
         do i=ib,ie
            ii = max(ii,ifreq(i-ib+1))
         end do
c...     normalise on 80
         ii = ii/80 + 1
         write(iwr,9049) ii
         do i=ib,ie
            if (ifreq(i-ib+1).lt.ii) then
               if (ifreq(i-ib+1).gt.0) write(iwr,9053) i,ifreq(i-ib+1)
               if (ifreq(i-ib+1).eq.0) write(iwr,9053) i
            else
               write(iwr,9050) i,('#',j=1,ifreq(i-ib+1)/ii)
            end if
         end do
         write(iwr,9051)
9049     format(/' Frequency table of eigenvalues of S-matrix',
     1           ' (scaled by ',i3,')',/,1x,80('='))            
9050     format(i5,2x,80a1)
9051     format(1x,80('='),/1x)
9053     format(i5,2x,i1)
      end if
      if (l0.ne.newbas0) then
cjvl     if(l0.ne.newbas0)call caserr2('linear dependance detected')
         newbas0 = l0
         odepen = .true.
c...  get symmetry numbers right
         do i=1,8
            nsymh(i) = nsym0(i)
            nsym0(i) = 0
         end do
         nav = lenwrd()
         call secget(isect(490),51,iblk51)
_IFN1(civk)         call readi(mmmm,mach(13)*nav,iblk51,idaf)
_IF1(civk)         call rdedx(mmmm,mach(13),iblk51,idaf)
         do i=1,l0
            ibig=idamax(l1,v(1,i),1)
            ii=isymaos(ibig)
            nsym0(ii) = nsym0(ii) + 1 
         end do
c
c        print sabf definition again
c
         write (iwr,6100)
         do loop = 1 , 8
            if (nsym0(loop).gt.0) then
               write (iwr,6110) loop , nsym0(loop)
            end if
         end do
         write (iwr,6120)
 6100 format (/1x,30('=')/1x,'irrep  no. of symmetry adapted'/1x,
     +        '       basis functions'/1x,30('='))
 6110 format (1x,i3,i12)
 6120 format (1x,30('=')/)
c
      endif

c
c...  because l0 may differ from l1 generate a second ilif in ilifq0
      do i=1,l0
         ilifq0(i)=(i-1)*l0
      end do
c
c     ----- form canonical orthonormal orbitals -----
c
       do 200 j=1,l0
      call dscal(l1,e(j),v(1,j),1)
 200   continue
      scr(1)=dfloat(l1)
      call dcopy(l1,e,1,scr(2),1)
c     clear "non-existent" vectors
      if (l0.lt.l1) call vclr(v(1,l0+1),1,(l1-l0)*l1)
c
c     ----- write the canonical orbitals on ed7  -----
c
      call wrt3(scr,l1+1,iblkv,idaf)
      ibl3qs=iblkv+lenv
      call wrt3(v,l3,ibl3qs,idaf)
400   if (nprint .ne. 5) return
      write (iwr,9068)
      call prev(v,e,l0,l1,ndim)
      return
 9008 format(/,5x,14(1h-),/,5x,14hoverlap matrix,/,5x,14(1h-))
 9028 format(/,5x,17(1h-),/,5x,17heigenvectors of s,/,5x,17(1h-))
 9047 format(//
     b,' ############################################################',/
     2,' ###        possible linear dependence diagnosed          ###',/
     3,' ### Smallest eigenvalue of overlap matrix is', 1pe12.4,' ###',/
     4,' ### There are',i6,' eigenvalue(s) less than ', 1pe12.4,' ###',/
     c,' ############################################################')
 9048 format(//
     a,' ############################################################',/
     b,' ############################################################',/
     2,' ###        possible linear dependence diagnosed          ###',/
     3,' ### Smallest eigenvalue of overlap matrix is', 1pe12.4,' ###',/
     4,' ###',i5,' eigenvector(s) are eliminated (',1pe9.2,
     4 '/',i5,') ###',/
     5,' ### the number of canonical orbitals kept is',i6,'       ###',/
     6,' ###  Beware .... ONLY (not extensively) TESTED on SCF    ###',/
     c,' ############################################################',/
     d,' ############################################################'/)
 9052 format(//,' **the eigenvalues of the overlap matrix (numbered)**',
     1       /,(2x,5(i5,1x,1pe10.3)))
 9068 format(/,5x,30(1h-),/,5x,30hcanonical orthonormal orbitals,/, 5x,
     +     30(1h-))
      end
c
c support code for symmetry blocking of diagonalisation
c
      subroutine gldiag_symm(l0,ldum,l1,h,ib,eig,vector,ia,iop2,
     +                       isymmo, use_symmetry )
c
c     ----- general calling  routine for giveis or ligen
c           ligen version -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)

      Integer isymmo( 1:l0 )
      Logical use_symmetry, force_serial

INCLUDE(common/timeperiods)

INCLUDE(common/overrule)
      dimension vector(*),h(*),ib(*),eig(*),ia(*)
      do 10 i=1,l0
 10   ib(i)=(i-1)*ldum
c
c     WARNING: original setting of 1.0d-8 caused real problems 
c     in some high symmetry cases .. reset diaacc from
c     th=1.0d-08
c     the value below is that currently used in gldiag. This may be
c     rather aggressive for some basis sets ..
c
      th=1.0d-15
      if (i_global_diag.ne.-999) th = 10.0d0**(-i_global_diag*1.0d0)
c  
      iop1=2
      Call start_time_period( TP_DIAG )
      call jacobi_symm(h,ia,l0,vector,ib,l1,eig,iop1,iop2,th,
     +                 isymmo, use_symmetry)
      Call end_time_period( TP_DIAG )
      return
      end
*
***************************************************************
*
      Subroutine block_a( n, n_irreps, symmetry, diag_order, 
     +                    orbs_this_symm, a, a_point, q_point,
     +                    work )
*
*  Given the Hamiltonian in A which has been built from
* orbitals that span N_IRREPS irreps and a given orbital
* spans the irrep given by SYMMETRY this routine permutes
* the rows and columns of A such that it becomes block
* diagonal, and also provides pointers for the columns
* of A in the new ordering and where the columns of the
* evecs in the new ordering should go.
* WARNING: there be nasties 'round 'ere !
*
*  The ordering of the blocks in A is such that the
* block corresponding to irrep DIAG_ORDER( 1, 1 )
* of size DIAG_ORDER( 2, 1 ) comes first, then directly
* after that comes the block for DIAG_ORDER( 1, 2 )
* etc. The pointers to the columns of A point
* to the position down the column where the block
* starts ( i.e. leading zeros are ignored ). Similarly
* for the pointers for the evecs.
*
      Implicit None
*
      Integer n
      Integer n_irreps
      Integer symmetry( 1:n )
      Integer diag_order( 1:2, 1:8 )
      Integer orbs_this_symm( 1:n )
      REAL    a( 1: ( n * ( n + 1 ) ) / 2 )
      Integer a_point( 1:n )
      Integer q_point( 1:n )
      REAL    work( 1: ( n * ( n + 1 ) ) / 2 )
*
      Integer size_irrep, which_irrep
      Integer point
      Integer irrep_offset
      Integer column
      Integer a_orig_start
      Integer a_entries
      Integer i, j, k
*
*  Generate the pointers to the starts of the columns
* in the block decomposed A. 
*
      irrep_offset = 0
      column       = 1
*
      Do i = 1, n_irreps
         point = 1
         size_irrep = diag_order( 2, i )
         Do j = 1, size_irrep
            a_point( column ) = point + irrep_offset
            point  = point  + j
            column = column + 1
         End Do
         irrep_offset = irrep_offset + 
     +        ( size_irrep * ( size_irrep + 1 ) ) / 2
      End Do
*
*  Generate the pointers into the eigenvector
* array
*
      irrep_offset = 0
      column       = 1
      point        = 1
*
      Do i = 1, n_irreps
         size_irrep = diag_order( 2, i )
         Do j = 1, size_irrep
            q_point( column ) = point + irrep_offset
            point  = point  + n
            column = column + 1
         End Do
         irrep_offset = irrep_offset + size_irrep
      End Do
*
*  O.K., for each irrep in turn find the elements
* of each column that span that irrep and store
* in the correct order in the workspace.
*
      column    = 1
      a_entries = 0
*
      Do i = 1, n_irreps
*
         which_irrep = diag_order( 1, i )
         size_irrep  = diag_order( 2, i )
*
         point = 1
         Do j = 1, n
            If( symmetry( j ) .EQ. which_irrep ) Then
               orbs_this_symm( point ) = j
               point = point + 1
            End If
         End Do
*
         Do j = 1, size_irrep
            point        = a_point( column )
            a_orig_start = 
     +   ( orbs_this_symm( j ) * ( orbs_this_symm( j ) - 1 ) ) / 2 
            Do k = 1, j
               work( point ) = a( a_orig_start + orbs_this_symm( k ) )
               point         = point  + 1
               a_entries     = a_entries + 1
            End Do
            column = column + 1
         End Do
*
      End Do
*
*  Copy the resulting block diagonal Hamiltonian back into A
*
*
      Call dcopy(a_entries, work, 1, a, 1)
*
      End
*
***************************************************************
*
      Subroutine shift_evecs( n, n_irrep, q, q_point )
*
*  Both the serial and parallel diags assume that where
* the evecs should be stored is one contiguous block
* in memory. This is not true if the symmetry of the
* molecule is being used to block diagonalize
* the Hamiltonian. This routine rectifies this
* by shifting the evecs to the correct places and zeroing
* the parts which should be strictly zero by symmetry.  
*
      Implicit None
*
      Integer n
      Integer n_irrep
      REAL    q( 1:n * n )
      Integer q_point( 1:n_irrep )
*     
      Integer q_from, q_to
      Integer i, j
*
*  Have to be a little careful. Move in backwards
* order to avoid overwrites.
*
      q_from = q_point( 1 ) + n_irrep * n_irrep - 1
*
      Do i = n_irrep, 2, -1
         q_to = q_point( i ) + n_irrep - 1
         Do j = n_irrep, 1, -1
*
            q( q_to   ) = q( q_from )
            q( q_from ) = 0.0d0
*
            q_to   = q_to   - 1
            q_from = q_from - 1
*
         End Do
      End Do
*
      End
*
***************************************************************
*
      Subroutine restore_orig_symmetry( n, n_irreps, q, 
     +                                  basis_symmetry, diag_order,
     +                                  work )
*
*  This undoes the permutations used to turn the
* Hamiltonian into block diagonal symmetry and applies
* them to the evecs to ensure their symmetry is
* consistent with the symmetry of the orbitals
* used to build the Hamiltonian ( the permuting
* made the labelling sequence for the orbitals
* different ).
*
*  One complication is the lack of a n * n workspace
* array, we've only got n * ( n + 1 ) / 2. Hence we
* do it in two goes, n/2 columns at a time.
*
      Implicit None
*
      Integer n
      Integer n_irreps
      REAL    q( 1:n, 1:n )
      Integer basis_symmetry( 1:n )
      Integer diag_order( 1:2, 1:8 )
      REAL    work( 1:n, 1:( n + 1 ) / 2 )
*
      Integer offsets_symm( 1:8 )
      Integer n_shift_1, n_shift_2
      Integer i, j
*
*  First of all work out where in a given column each
* irrep starts.
*
      Do i = 1, n_irreps
         offsets_symm( i ) = 1
         j = 1
         Do While( diag_order( 1, j ) .NE. i )
            offsets_symm( i ) = offsets_symm( i ) + diag_order( 2, j )
            j = j + 1
         End Do
      End Do
*
*  Now do the two shifts.
*
      n_shift_1 = n / 2
      n_shift_2 = n - n / 2
*
      Call shift_to_orig_symmetry( n, n_shift_1, q, 
     +                             basis_symmetry,
     +                             offsets_symm, work )
      Call shift_to_orig_symmetry( n, n_shift_2, q( 1, n_shift_1 + 1 ), 
     +                             basis_symmetry,
     +                             offsets_symm, work )
*
      End
*
***************************************************************
*
      Subroutine shift_to_orig_symmetry( n, n_shift, q, basis_symmetry,
     +                                   offsets_symm, work )
*
*  Shifts a set of blocked by symmetry vectors back to the
* original ordering as described by BASIS_SYMMETRY.
*
      Integer n
      Integer n_shift
      REAL    q( 1:n, 1:n_shift )
      Integer basis_symmetry( 1:n )
      Integer offsets_symm( 1:8 )
      REAL    work( 1:n, 1:n_shift )
*
      Integer count_symm( 1:8 )
      Integer this_symm
      Integer which_row
      Integer i
*
      Do i = 1, 8
         count_symm( i ) = 0
      End Do
*
      Do i = 1, n
         this_symm = basis_symmetry( i )
         which_row = offsets_symm( this_symm ) + 
     +                 count_symm( this_symm )
         call dcopy(n_shift, q( which_row, 1 ), n, work( i, 1 ), n)
         count_symm( this_symm ) = count_symm( this_symm ) + 1
      End Do
*
      Call dcopy(n * n_shift, work, 1, q, 1)
*
      End

      subroutine symvec(q,isymao,isymmo,nbas,ncol,iblk)
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/mapper)
INCLUDE(common/machin)
      dimension q(*),isymmo(*),isymao(*)
c     nbsq=nbas*ncol (last vector is there; but zeroed)
      nbsq=nbas*nbas
      iblkv=iblk+1+lensec(mach(8))+lensec(mach(9))
      call rdedx(q,nbsq,iblkv,idaf)
      do 10 i=1,ncol
      ii=ilifq(i)
      do 40 j=1,nbas
      if( dabs(q(ii+j)).gt.1.0d-3)go to 50
 40   continue
 50   isymmo(i)=isymao(j)
 10   continue
      return
      end

      function jsubst(ztext)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension xchar(8)
      do 1 i=1,8
 1    xchar(i)=ztext(i:i)
      jsubst = isubst(xchar)
      return
      end
      subroutine gamgn2
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c        *****  computes and tabulates f0(x) to f5(x)           *****
c        *****  in range x = -0.15 to x = 19.9                  *****
c        *****  in units of x = 0.05                            *****
c
INCLUDE(common/iofile)
INCLUDE(common/restri)
      common/junk/c(1200,6)
      dimension qy(410)
      data pt184,pt5/ 0.184d0,0.50d0/
      data six,tenm7/6.0d0,1.0d-20 /
      data four,two,done/4.0d0,2.0d0,1.0d0 /
      data pt886/0.8862269254527d0 /
      data pt15,pt05/0.15d0,0.05d0/
      data m22,mword/22,7200/
      q=-done
      do 30 mm=1,6
      m=mm-1
      q=q+done
      qx = -pt15
      do 20 i=1,410
      qx = qx+pt05
      a=q
c        *****  change limit of approximate solution.           *****
      if(qx-15.0d0) 1,1,10
    1 a=a+pt5
      term=done/a
      ptlsum=term
      do 2 l=2,50
      a=a+done
      term=term*qx/a
      ptlsum=ptlsum+term
      if(dabs(term/ptlsum)-tenm7)3,2,2
    2 continue
    3 qy(i)=pt5*ptlsum*dexp(-qx)
      go to 20
   10 b=a+pt5
      a=a-pt5
      approx=pt886/(dsqrt(qx)*qx**m)
      if(m.eq.0) go to 13
      do 12 l=1,m
      b=b-done
   12 approx=approx*b
   13 fimult=pt5*dexp(-qx)/qx
      fiprop=fimult/approx
      term=done
      ptlsum=term
      notrms=qx
      notrms=notrms+m
      do 14 l=2,notrms
      term=term*a/qx
      ptlsum=ptlsum+term
      if(dabs(term*fiprop/ptlsum)-tenm7)15,15,14
   14 a=a-done
   15 qy(i)=approx-fimult*ptlsum
   20 continue
      do 30 i=1,400
      j=i+2
      c(i,mm)=qy(j)
      c(i+400,mm)=qy(j+1)-qy(j)
      temp1=-two*qy(j)+qy(j+1)+qy(j-1)
      temp2=six*qy(j)-four*qy(j+1)-four*qy(j-1)+qy(j-2)+qy(j+2)
   30 c(i+800,mm) = (temp1-pt184*temp2)/six
      call secput(isect(503),m22,lensec(mword),iblk22)
      call wrt3(c,mword,iblk22,idaf)
      return
      end
      subroutine qmat(q,s,v,e,scr,ia,l0,l1,l3,ndim,out)
      implicit REAL  (a-h,p-w),integer    (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/gmempara)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/scra7)
INCLUDE(common/sizes)
INCLUDE(common/harmon)
INCLUDE(common/runlab)
INCLUDE(common/overrule)
INCLUDE(common/machin)
      common/craypk/mmmm(65),isymaos(maxorb),isymmos(maxorb)
      common/restri/jjfile(63),lds(508),isect(508),ldsect(508),
     + iacsct(508)
      integer itab
      character*7 fnm
      character*4 snm
      data fnm,snm/'util1.m','qmat'/
      dimension q(*),s(*),v(ndim,*),e(*),scr(*),ia(*)
      data m167,done,tol1,tol0 /167,1.0d0,1.0d-05,1.0d-07/
c
c...  allow specfied crit for dependency (10**-i_depen_check)
c...  (0 => no checking) ; i_depen_check in common/overrule/
c
      if (i_depen_check.ge.0) then
         tol0 = 10.0d0**(-1.0d0*i_depen_check)
         if (i_depen_check.eq.0) tol0 = 1.0d-20
      end if
c
c     ----- diagonalize overlap matrix -----
c
      if (out) then
      write (iwr,9008)
      call prtril(s,l1)
      endif
      len1=lensec(l1+1)
      l2=l1*(l1+1)/2
      lenv=len1+lensec(l2)
      call sectst(isecqm,itest)
      if(itest.eq.0) go to 300
      call secget(isecqm,m167,iblkv)
      call rdedx(scr,l1+1,iblkv,idaf)
      if(scr(1).ne.dfloat(l1)) go to 300
      call dcopy(l1,scr(2),1,e,1)
      call reads(scr,l2,idaf)
      call vsub(s,1,scr,1,scr,1,l2)

      do 310 i=1,l2
      if( dabs(scr(i)).gt.tol1) go to 300
 310  continue
      call reads(v,l3,idaf)
      ibl3qs=iblkv+lenv
      l0=newbas0
      go to 400

300   lenq=lenv+lensec(l3)
      call secput(isecqm,m167,lenq,iblkv)
      call wrt3(s,l2,iblkv+len1,idaf)
c
      if (oharm) call comharm(s,'tri',scr)
      call gldiag(newbas0,newbas0,newbas0,s,scr,e,v,ia,2)
      if (oharm) then
         nn = newbas1-newbas0
         call expharm(v,'vectors',scr)
c...     move real vectors to the end
         do i=l0,1,-1
            e(i+nn) = e(i)
            call dcopy(ndim,v(1,i),1,v(1,i+nn),1)
         end do
         call vclr(v,1,ndim*nn)
         call vclr(e,1,nn)
      end if
c
      if (nprint .ne. 5) go to 120
      write (iwr,9028)
      call prev(v,e,l1,l1,ndim)
  120 continue
c
c     ----- eliminate eigenvectors for which eigenvalue is less
c           than tol=tol0
c
      if (o_depen_print) then
         write(iwr,9052) (i,e(newbas1-newbas0+i),i=1,newbas0)
      end if 
      dum = e(l1-newbas0+1)
      j = 0
      k = 0
      kk=0
      do 180 i = 1,l1
      if(e(i) .lt. tol1) then
      kk=kk+1
      endif
      if (e(i) .lt. tol0 .or. 
     1    i.le. (newbas1-newbas0+n_depen_check) ) go to 160
      j = j+1
      e(j) = done/  dsqrt(e(i))
      if (i.ne.j) call dcopy(l1,v(1,i),1,v(1,j),1)
      go to 180
  160 k = k+1
  180 continue
      l0 = l1-k
      if(kk.ne.l1-newbas0) write(iwr,9047) dum,kk-(l1-newbas0),tol1
      if (l0.ne.newbas0) then
         write (iwr,9048) dum,k-(l1-newbas0),tol0,n_depen_check,l0
cjvl     if(l0.ne.newbas0)call caserr2('linear dependance detected')
         newbas0 = l0
         odepen = .true.
c...  get symmetry numbers right
         do i=1,8
            nsymh(i) = nsym0(i)
            nsym0(i) = 0
         end do
         nav = lenwrd()
         call secget(isect(490),51,iblk51)
_IFN1(civfuk)         call readi(mmmm,mach(13)*nav,iblk51,idaf)
_IF1(civfuk)         call rdedx(mmmm,mach(13),iblk51,idaf)
         do i=1,l0
            ibig=idamax(l1,v(1,i),1)
            ii=isymaos(ibig)
            nsym0(ii) = nsym0(ii) + 1 
         end do
      end if
c     if (zruntp.ne.'force') n_depen_check = 0
c
c...  because l0 may differ from l1 generate a second ilif in ilifq0
c
      do i=1,l0
         ilifq0(i)=(i-1)*l0
      end do
c
c     ----- form canonical orthonormal orbitals -----
c
       do 200 j=1,l0
      call dscal(l1,e(j),v(1,j),1)
 200   continue
      scr(1)=dfloat(l1)
      call dcopy(l1,e,1,scr(2),1)
c     clear "non-existent" vectors
      if (l0.lt.l1) call vclr(v(1,l0+1),1,(l1-l0)*l1)
c
c     ----- write the canonical orbitals on ed7  -----
c
      call wrt3(scr,l1+1,iblkv,idaf)
      ibl3qs=iblkv+lenv
      call wrt3(v,l3,ibl3qs,idaf)
400   if (nprint .ne. 5) return
      write (iwr,9068)
      call prev(v,e,l0,l1,ndim)
      return
 9008 format(/,5x,14(1h-),/,5x,14hoverlap matrix,/,5x,14(1h-))
 9028 format(/,5x,17(1h-),/,5x,17heigenvectors of s,/,5x,17(1h-))
 9047 format(//
     b,' ############################################################',/
     2,' ###        possible linear dependence diagnosed          ###',/
     3,' ### Smallest eigenvalue of overlap matrix is', 1pe12.4,' ###',/
     4,' ### There are',i6,' eigenvalue(s) less than ', 1pe12.4,' ###',/
     c,' ############################################################')
 9048 format(//
     a,' ############################################################',/
     b,' ############################################################',/
     2,' ###        possible linear dependence diagnosed          ###',/
     3,' ### Smallest eigenvalue of overlap matrix is', 1pe12.4,' ###',/
     4,' ###',i5,' eigenvector(s) are eliminated (',1pe9.2,
     4 '/',i5,') ###',/
     5,' ### the number of canonical orbitals kept is',i6,'       ###',/
     6,' ###  Beware .... ONLY (not extensively) TESTED on SCF    ###',/
     c,' ############################################################',/
     d,' ############################################################'/)
 9052 format(//,' **the eigenvalues of the overlap matrix (numbered)**',
     1       /(2x,5(i5,1x,1pe10.3)))
 9068 format(/,5x,30(1h-),/,5x,30hcanonical orthonormal orbitals,/, 5x,
     +     30(1h-))
      end
      subroutine ortho1(q,s,v,t,ia,n,l0,l1,l2,l3,ndim)
c
c...  this routine in intimately linked with gamess (see rdedx)
c...  vectors in orthogonal basis return in v (complete orthogonal set)
c
c...  ia : iky (i*i-1)/1)
c...  n :  # vectors
c...  l0 : dimension of vectors in orthogonal basis
c...  l1 : dimension of vectors in non-orthogonal basis
c...  l2,l3 triangle/square dimensions corresponding to l1
c...  ndim first dimension of v and q arrays
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(ndim,*),s(*),v(ndim,*),t(*),ia(*)
INCLUDE(common/iofile)
INCLUDE(common/scra7)
c
      call rdedx(s,l2,ibl7st,num8)
      do 160 j = 1,n
      t(1)=s(1)*v(1,j)
      do 140 i=2,l1
      m=ia(i)
      call daxpy(i-1,v(i,j),s(m+1),1,t,1)
      t(i)=ddot(i,s(m+1),1,v(1,j),1)
 140  continue
      call dcopy(l1,t(1),1,v(1,j),1)
 160  continue
      call rdedx(q,l3,ibl3qs,idaf)
      do 200 j = 1,n
      do 180 i = 1,l0
      t(i) = ddot(l1,q(1,i),1,v(1,j),1)
  180 continue
      call dcopy(l0,t(1),1,v(1,j),1)
 200  continue
c
      call schmd(v,n,l0,ndim)
      return
      end
      subroutine schmd(v,m,n,ndim)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
      dimension v(ndim,*)
      data done,tol /1.0d0,1.0d-10/
      if (m .eq. 0) go to 180
c
c     ----- orthonormalize first -m- mo's -----
c
      do 160 i = 1,m
c
      dumi=done/dnrm2(n,v(1,i),1)
      call dscal(n,dumi,v(1,i),1)
c
      if (i .eq. m) go to 160
      i1 = i+1
      do 140 j = i1,m
      dum = -ddot(n,v(1,j),1,v(1,i),1)
      call daxpy(n,dum,v(1,i),1,v(1,j),1)
  140 continue
c
  160 continue
      if (m .eq. n) return
  180 continue
c
c     ----- get orthogonal space -----
c
      i = m
      j = 0
  200 i0 = i
      i = i+1
      if (i .gt. n) return
  220 j = j+1
      if (j .gt. n) go to 320
      call vclr(v(1,i),1,n)
      v(j,i) = done
c
      do 260 ii = 1,i0
      dum = -ddot(n,v(1,ii),1,v(1,i),1)
      call daxpy(n,dum,v(1,ii),1,v(1,i),1)
  260 continue
      dumi = ddot(n,v(1,i),1,v(1,i),1)
      if (  dabs(dumi) .lt. tol) go to 220
      dumi = done/ dsqrt(dumi)
      call dscal(n,dumi,v(1,i),1)
      go to 200
  320 write (iwr,9008) i0
      call caserr2('redundant vectors detected')
 9008 format(33h redundant set of vectors. stop. , i5,
     +     26h independant vectors found)
      return
      end
      subroutine  setz(v,d,e,l1,l2,l3)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension d(*),v(*),e(*)
      call vclr(e,1,l1)
      call vclr(d,1,l2)
      call vclr(v,1,l3)
      return
      end
      function tracep(a,b,n)
c
c     ----- trace of product of 2 symmetric matrices
c           -a- and -b- stored linearly -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension a(*),b(*)
      ltri=n*(n+1)/2
      t=ddot(ltri,a,1,b,1)
      t=t+t
      k=1
      do 1 i=1,n
      t=t-a(k)*b(k)
1     k=k+i+1
      tracep=t
      return
      end
      subroutine pusql(v,m,n,ndim)
c
c     ----- punch out a square matrix with ordering labels -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
      dimension v(ndim,*)
      do 120 j = 1,m
      ic = 0
      max = 0
  100 min = max+1
      max = max+5
      ic = ic+1
      if (max .gt. n) max = n
      write (ipu,9008) j,ic,(v(i,j),i = min,max)
      if (max .lt. n) go to 100
  120 continue
      return
 9008 format(i2,i3,5e15.8)
      end
c
c-----------------------------------------------------------------------
c
      subroutine prgeom(coord,chg,ztag,natoms,iwr)
      implicit none
      integer natoms, iwr
c     map80 maps the position of charge in the symz array (passed in as chg)
c     to those in the other atomic information arrays
      integer map80(natoms)
      REAL coord(3,natoms)
      REAL chg(natoms)
INCLUDE(common/prints)
INCLUDE(common/errcodes)
      character*8 ztag(natoms)
      integer nbqnop
c
c     ----- print the geometry of the molecule.
c
c     The format is chosen such that the printed result can be used
c     directly in an input file without requiring editing.
c
      integer i, j, l, isymz
c
      write(iwr,6000)
      nbqnop = 0
      do i=1,natoms
         if (.not. oprint(31) .or. (ztag(i)(1:2) .ne. 'bq'))then
            write(iwr,6010)(coord(j,i),j=1,3),chg(i),ztag(i)
         else
            nbqnop = nbqnop + 1
         endif
      enddo
      if (nbqnop .gt. 0)then
         write (iwr,6011) nbqnop
      endif
      write(iwr,6020)
c
 6000 format(9x,'x',14x,'y',14x,'z',12x,'chg',2x,'tag'/2x,60('='))
 6010 format(2x,3f15.7,1x,f7.2,2x,a8)
 6011 format(2x,'Output of ',i5,' BQ centres suppressed')
 6020 format(2x,60('='))
      end
c
c-----------------------------------------------------------------------
c
      subroutine prev(v,e,m,n,ndim)
c
c     ----- print out e and v-matrices
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/prints)
INCLUDE(common/runlab)
      dimension v(ndim,*),e(*)
      max = 10
      if (oprint(20)) max=7
      imax = 0
  100 imin = imax+1
      imax = imax+max
      if (imax .gt. m) imax = m
      write (iwr,9008)
      if(oprint(20)) go to 130
      write (iwr,8068) (e(i),i = imin,imax)
      write (iwr,9008)
      write (iwr,8028) (i,i = imin,imax)
      write (iwr,9008)
      do 150 j = 1,n
  150 write (iwr,8048) j,zbflab(j),(v(j,i),i = imin,imax)
      go to 140
130   write (iwr,9068) (e(i),i = imin,imax)
      write (iwr,9008)
      write (iwr,9028) (i,i = imin,imax)
      write (iwr,9008)
      do 120 j = 1,n
  120 write (iwr,9048) j,zbflab(j),(v(j,i),i = imin,imax)
 140  if (imax .lt. m) go to 100
      return
 9008 format(/)
 8028 format(17x,10(3x,i3,3x))
 8048 format(i5,2x,a10,10f9.4)
 8068 format(17x,10f9.4)
 9028 format(17x,12(6x,i3,6x))
 9048 format(i5,2x,a10,7f15.10)
 9068 format(17x,7f15.10)
      end
c
c-----------------------------------------------------------------------
c
      subroutine prevg(v,e,m,n,ndim)
c
c     ----- Print out the eigenvalues and eigenvectors of the g-matrix
c           alongside the variable labels from the z-matrix (if any).
c
c           This routine is used in formbgxz if the determinant of
c           the g-matrix is small to hopefully assist the user in 
c           redefining the z-matrix when problems with the g-matrix
c           inversion are suspected.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/prints)
INCLUDE(common/czmat)
INCLUDE(common/csubch)
INCLUDE(common/infoa)
      dimension v(ndim,*),e(*)
      max = 10
      imax = 0
  100 imin = imax+1
      imax = imax+max
      if (imax .gt. m) imax = m
      write (iwr,9008)
      write (iwr,8068) (e(i),i = imin,imax)
      write (iwr,9008)
      write (iwr,8028) (i,i = imin,imax)
      write (iwr,9008)
      if (nz.ge.2) then
         do 20 i = 2 , nz
            ibl = iabs(lbl(i))
            if (ibl.ne.0) then
              write (iwr,8048) i-1,zvar(ibl),(v(i-1,k),k = imin,imax)
            else
              write (iwr,8049) i-1,(v(i-1,k),k = imin,imax)
            end if
 20      continue
c
         if (nz.ge.3) then
            j = nz - 3
            do 30 i = 3 , nz
               ialpha = iabs(lalpha(i))
               if (ialpha.ne.0) then
                 write (iwr,8048) i+j,zvar(ialpha),(v(i+j,k),
     +                                            k = imin,imax)
               else
                 write (iwr,8049) i+j,(v(i+j,k),k = imin,imax)
               end if
 30         continue
c
            if (nz.ge.4) then
               j = nz + nz - 6
               do 40 i = 4 , nz
                  ibeta = iabs(lbeta(i))
                  if (ibeta.ne.0) then
                    write (iwr,8048) i+j,zvar(ibeta),(v(i+j,k),
     +                                              k = imin,imax)
                  else
                    write (iwr,8049) i+j,(v(i+j,k), k = imin,imax)
                  end if
 40            continue
            end if
         end if
      end if
      if (imax .lt. m) go to 100
      return
 9008 format(/)
 8028 format(17x,10(3x,i3,3x))
 8048 format(i5,2x,a10,10f9.4)
 8049 format(i5,12x,10f9.4)
 8068 format(17x,10f9.4)
      end
c
c-----------------------------------------------------------------------
c
      subroutine prtril(d,n)
c
c     ----- print out a triangular matrix with labels
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/iofile)
INCLUDE(common/runlab)
      dimension d(*),dd(10)
      mmax = 10
      if (oprint(20)) mmax=7
      imax = 0
  100 imin = imax+1
      imax = imax+mmax
      if (imax .gt. n) imax = n
      write (iwr,9008)
      if(.not.oprint(20)) write (iwr,8028) (zbflab(i),i = imin,imax)
      if( oprint(20)) write (iwr,9028) (zbflab(i),i = imin,imax)
      write (iwr,9008)
      do 160 j = 1,n
      k = 0
      do 140 i = imin,imax
      k = k+1
      m =max(i,j)*(max(i,j)-1)/2+min(i,j)
  140 dd(k) = d(m)
      if( oprint(20)) write (iwr,9048) j,zbflab(j),(dd(i),i = 1,k)
      if(.not.oprint(20)) write (iwr,8048) j,zbflab(j),(dd(i),i = 1,k)
  160 continue
      if (imax .lt. n) go to 100
      return
 9008 format(/)
 9028 format(17x,7(3x,a10,2x))
 9048 format(i5,2x,a10,7f15.10)
 8028 format(17x,10(1x,a8))
 8048 format(i5,2x,a10,10f9.4)
      end
      subroutine prsql(v,m,n,ndim)
c
c     ----- print out a square matrix with labels
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/prints)
INCLUDE(common/iofile)
INCLUDE(common/runlab)
      dimension v(ndim,*)
      max = 10
      if (oprint(20)) max=7
      imax = 0
  100 imin = imax+1
      imax = imax+max
      if (imax .gt. m) imax = m
      write (iwr,9008)
      if(oprint(20)) write (iwr,9028) (i,i = imin,imax)
      if(.not.oprint(20)) write (iwr,8028) (i,i = imin,imax)
      write (iwr,9008)
      do 120 j = 1,n
      if(oprint(20)) write (iwr,9048) j,zbflab(j),(v(j,i),i = imin,imax)
      if(.not.oprint(20)) write (iwr,8048) j,zbflab(j),(v(j,i),i =
     * imin, imax)
 120   continue
      if (imax .lt. m) go to 100
      return
 9008 format(1x)
 9028 format(17x,7(6x,i3,6x))
 9048 format(i5,2x,a10,7f15.10)
 8028 format(17x,10(3x,i3,3x))
 8048 format(i5,2x,a10,10f9.4)
      end
      subroutine getq(q,eig,pop,nbas,newb,mode,ieig,ipop,numd,zname)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter (mxorb1=maxorb+1)
      dimension q(*),eig(*),pop(*)
INCLUDE(common/iofile)
INCLUDE(common/scfopt)
INCLUDE(common/sector)
      common/junkc/zcom(19),ztit(10)
c      common/junk/ilifd(maxorb),ntrad(maxorb),itrad(mxorb3),
c     *ctrad(mxorb3)
      common/blkqio/deig(maxorb),dpop(mxorb1),
     *nba,new,ncol,jeig,jpop
INCLUDE(common/infoa)
INCLUDE(common/discc)
INCLUDE(common/machin)
INCLUDE(common/restar)
      data m3,m29/3,29/
      if(numd.gt.508)call caserr2(
     *'invalid section specified for vector input')

      if(nprint.ne.-5)write(iwr,100)zname,numd,iblkdu,yed(numdu)
100   format(/a7,'vectors restored from section',i4,
     *' of dumpfile starting at block',i6,' of ',a4)
      call secget(numd,m3,k)
      call rdchr(zcom(1),m29,k,numdu)
      call reads(deig,mach(8),numdu)
      k=k+1+lensec(mach(8))
      if(nprint.ne.-5)write(iwr,200)(zcom(7-i),i=1,6),ztit
c
      if(new.ne.ncol) then
c           (**harmonic**)
        ncol = new
      end if
c
      if(new.eq.ncol)go to 300
 310  call caserr2(
     *'vectors restored from dumpfile have incorrect format')
 300  nbas=nba
      newb=new
      ieig=jeig
      ipop=jpop
      call dcopy(ncol,dpop,1,pop,1)
      call dcopy(ncol,deig,1,eig,1)
      etot=dpop(mxorb1)
200   format(/' header block information :'/
     *' vectors created under acct. ',a8/1x,
     *a7,'vectors created by ',a8,'  program at ',
     *a8,' on ',a8,' in the job ',a8/
     *' with the title: ',10a8)
      if(mode.lt.3)go to 101
      if(num.lt.nbas.or.num.lt.newb)go to 310
      go to 500
 101  if(num.ne.nbas.or.num.ne.newb)go to 310
      if(mode.le.2)call ctrchk(k)
500   nw=nbas*newb
      k=k+lensec(mach(9))
      call rdedx(q,nw,k,numdu)
      return
      end
      subroutine putdev(q,iseco,ipos,ioff)
c
c      retrieve and store gamess q, eval and d
c
      implicit REAL  (a-h,o-z)
      character *8 grhf
INCLUDE(common/sizes)
      parameter (mxorb1=maxorb+1)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
      character *8 com,dtitle
      common/junkc/com(19),dtitle(10)
      logical iftran
      common/small/
     + ilifcs(maxorb),ntrans(maxorb),itrans(mxorb3),ctrans(mxorb3),
     + iftran,isp,
     + value(maxorb),occ(mxorb1),
     + nbasis,newbas,ncol,ivalue,iocc,ift
INCLUDE(common/machin)
INCLUDE(common/mapper)
INCLUDE(common/restrj)
INCLUDE(common/timez)
      logical lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis
      common/scfblk/en,etotal,ehf,sh1(2),sh2(2),gap1(2),gap2(2),
     &              d12,d13,d23,canna,cannb,cannc,fx,fy,fz,
     &              lfield,fixed,lex,ldam12,ldam13,ldam23,ldiis,
     &              ncyc,ischm,lock,maxit,nconv,npunch
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/atmblk)
INCLUDE(common/tran)
      dimension q(*),ioffs(2)
c
c allocate storage
c
      data m1,m19/1,19/
      data grhf/'grhf'/
c
      if (iacsct(isect(ipos  )).lt.0. or. 
     +    iacsct(isect(ipos+1)).lt.0. or. 
     +    iacsct(isect(ipos+2)).lt.0 ) return
c
      l3 = num*num

      if (scftyp.ne.grhf) then
         ilen = l3 + 2*nx
      else
         ilen = 2*l3 + nx + num
      end if

      i10 = igmem_alloc(ilen)
      i20 = i10 + l3
      i30 = i20 + nx
      if (scftyp.ne.grhf) then
c        last = i30 + nx
      else
         i40 = i30 + l3
c        last = i40 + num
      end if

      len = lensec(num)
      lenx = lensec(nx)
c
c     retrieve and store density matrix
c
      call secget(isect(497),m19,iblok)
      ioffs(1) = iblok
      ioffs(2) = iblok + len + lenx
      call rdedx(q(i20),nx,ioffs(ioff),ifild)
      if (scftyp.eq.grhf) then
         call rdedx(q(i30),nx,ioffs(ioff+1),ifild)
         call vadd(q(i20),1,q(i30),1,q(i20),1,nx)
      end if
c     store
      call secput(isect(ipos),ipos,lenx,iblkdc)
      lds(isect(ipos)) = nx
      call wrt3(q(i20),nx,iblkdc,ifild)
c
c     lagrangian for grhf cases
c
      if (scftyp.eq.grhf) then
         call putlag(q(i20),q(i10),q(i30),q(i40),num)
      end if
c
c     store vectors ( including a 'ctrans' block')
c
      nav = lenwrd()
      nprin = nprint
      nprint = -5
      call getq(q(i10),value,occ,nbasis,newbas,m1,m1,m1,iseco,scftyp)
      if (.not.otran) call tdown(q(i10),ilifq,q(i10),ilifq,num)
      nprint = nprin
c
      lenw = num*ncoorb
      lds(isect(ipos+1)) = lenw
      len = lensec(lenw) + mvadd
      call secput(isect(ipos+1),ipos+1,len,iblkdc)
      iftran = .true.
      ncol = ncoorb
      iocc = ncoorb
      ivalue = ncoorb
      m29 = 29
      call wrtc(com,m29,iblkdc,ifild)
      call wrt3s(value,mach(8),ifild)
      call wrt3is(ilifcs(1),mach(9)*nav,ifild)
      call wrt3s(q(i10),lenw,ifild)
c
c     store eigenvalues
c
      len = lensec(num)
      lds(isect(ipos+2)) = num
      call secput(isect(ipos+2),ipos+2,len,iblkdc)
      call wrt3(value,num,iblkdc,ifild)
c
      call gmem_free(i10)
      return
      end
      subroutine putgrd(eg)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/common)
INCLUDE(common/infoa)
c
      dimension eg(*)
c
c ----- store gradient on isect(14)
c
      if (iacsct(isect(14)). lt. 0) return
      nblock = lensec(maxat*3)
      lds(isect(14)) = maxat*3
      call secput(isect(14),14,nblock,iblok)
      call wrt3(eg,lds(isect(14)),iblok,ifild)
      return
      end
      subroutine putlag(d,v,e,dd,ndim)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
c
INCLUDE(common/restri)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/dm)
INCLUDE(common/infoa)
INCLUDE(common/scfwfn)
INCLUDE(common/mapper)
INCLUDE(common/cigrad)
INCLUDE(common/tran)
      dimension v(ndim,*),d(*),e(*),dd(*)
      data m20/20/
      data pt5/0.5d0/
c
      if(iacsct(isect(42)).lt.0) return
      l3 = num*num
c
      norb = nco + npair + npair
      if (nseto.gt.0) then
         do 20 i = 1 , nseto
            norb = norb + no(i)
 20      continue
      end if
      call rdedx(v,l3,ibl3qa,idaf)
      if (.not.otran) call tdown(v,ilifq,v,ilifq,num)
      l3orb = norb*norb
      call secget(iseclg,m20,iblk20)
      call rdedx(e,l3orb,iblk20,idaf)
c
c     ----- zero out weighted density array -----
c
      call vclr(d,1,nx)
c
c     ----- calculate -tr(ce(ct)sa) -----
c
c     ----- note that e(kl) is used exactly twice. divide by
c           two to get the values appropriate for the generalized
c           lagrangian multipliers -----
c
      do 70 i = 1 , num
c
c     ---calculate the half transform first -----
c
         kl = 0
         do 40 l = 1 , norb
            dd(l) = 0.0d0
            do 30 k = 1 , norb
               kl = kl + 1
               dd(l) = dd(l) - v(i,k)*e(kl)
 30         continue
 40      continue
         call dscal(norb,pt5,dd,1)
         do 60 j = 1 , num
            ij = iky(max(i,j)) + min(i,j)
            do 50 l = 1 , norb
               d(ij) = d(ij) + dd(l)*v(j,l)
 50         continue
 60      continue
 70   continue
c
      len = lensec(nx)
      m = 42
      call secput(isect(42),m,len,iblk42)
      call wrt3(d,nx,iblk42,idaf)
      lds(isect(42)) = nx
c
      return
      end
      subroutine putstv(q)
      implicit REAL  (a-h,o-z)
      logical o1e
INCLUDE(common/sizes)
c
INCLUDE(common/restri)
INCLUDE(common/restrj)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
      dimension o1e(6)
      dimension corev(512),array(6)
c
      dimension q(*)
c
      if (iacsct(isect(5)).lt.0.or.
     +    iacsct(isect(6)).lt.0 ) return
      l2 = num*(num+1)/2
      i10 = igmem_alloc(l2)
      i20 = igmem_alloc(l2)
      do loop =1,6
       o1e(loop) = .false.
      enddo
      o1e(1) = .true.
      o1e(3) = .true.
c
c ----- restore s,t,f from section 192 and store on dumpfile
c
      call getmat(q(i10),q(i10),q(i20),q(i10),q(i10),q(i10),
     +   array,num,o1e,ionsec)
c
c ----- store on isect(5) and isect(6)
c
      nblock = lensec(l2)
      lds(isect(5)) = l2
      call secput(isect(5),5,nblock,iblok)
      call wrt3(q(i10),l2,iblok,idaf)
c
      lds(isect(6)) = l2
      call secput(isect(6),6,nblock,iblok)
      call wrt3(q(i20),l2,iblok,idaf)
c
c ----- reset core
c
      call gmem_free(i20)
      call gmem_free(i10)
c
      return
      end
      subroutine copq_again(mpos)
c
c...  copy (vectors) section to  another section, to keep copies of orbitals
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
c
      dimension buf(512)
      character*(*) test
      logical off,oexist
      save mpos_again,maxpos_again,int_again,int,off
      data off/.true./
c
      if (off) return
c
      int = int + 1 
c
      entry copq_again2(mpos)
      if (off) return
c
      if ((int/int_again)*int_again.eq.int.or.int.eq.1) then
         if (mpos_again.gt.maxpos_again) return
c
         call secinf(iblkdu,numdu,idum,idum)
         call secloc(mpos,oexist,ibli)
         if (.not.oexist) call caserr('no section in copq_again')
         call qsector(mpos,idum,iclass,ilen,'get')
         call secput(mpos_again,iclass,ilen,iblo)
         do i=1,ilen
            call search(ibli,numdu)
            call get(buf,nw,numdu)
            ibli = ibli + 1
            call search(iblo,numdu)
            call put(buf,nw,numdu)
            iblo = iblo + 1
         end do
         write(iwr,'(a,i4,a,i4)') ' wrote vectors(copq) for point ',int,
     1                            ' to section ',mpos_again
         mpos_again = mpos_again + 1
      end if
c
      return      
c
      entry set_copq_again(test)
c
      if (test.eq.'on') then
         off = .false.
      else if (test.eq.'off') then
         off = .true.
      else if (test.eq.'init') then
         off = .false.
         call inpi(int_again)
         if (int_again.eq.0) int_again = 5
         call inpi(mpos_again)
         if (mpos_again.eq.0) mpos_again = 100
         call inpi(maxpos_again)
         if (maxpos_again.eq.0) maxpos_again = 200
c
         write(iwr,'(a,i4,a,a,i4,a,i4,a)') 
     1      ' *** write vectors(copq) every ',int_again,' point',
     2      ' starting with section ',mpos_again,' till ',maxpos_again,
     3      ' *** '
      else
         call caserr('wrong set_putq_again')
      end if
c
      return
      end
      subroutine putq(zcomm,ztit,eig,def,norb,norbn,ncolu,ieig,
     *ideff,q,mpos,iblkq)
c... standard e.vector outputting routine(+ header blocks)
c... allow VB/servec weird dimensioning
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension q(*),zcomm(*),ztit(*),eig(*),def(*)
INCLUDE(common/sector)
      common/junkc/zcom(19),ztitle(10)
      common/blkqio/value(maxorb),pop(maxorb),escf,
     *nbasis,newbas,ncol,ivalue,ipop
INCLUDE(common/machin)
INCLUDE(common/scfopt)
INCLUDE(common/tran)
      data m29/29/
       if(mpos.gt.508)call caserr2(
     *'invalid section specified for vector output')
      len1=lensec(mach(8))
      nbsq=norb*norb
      m3 = 3
c
      if (zcomm(5).eq.'vb'.or.zcomm(5).eq.'servec') then
         nbsq = norb*ncolu
         m3 = 33
      end if
c
      lenv=lensec(nbsq)
      len2=lensec(mach(9))
      j=len2+lenv+len1+1
      call secput(mpos,m3,j,iblk)
      iblkq=iblk+len2+len1+1
      escf=etot
      do 100 i=1,10
 100  ztitle(i)=ztit(i)
      do 200 i=1,19
 200  zcom(i)=zcomm(i)
      call dcopy(ncolu,eig,1,value,1)
      call dcopy(ncolu,def,1,pop,1)
      nbasis=norb
      newbas=norbn
      ncol=ncolu
      ivalue=ieig
      ipop=ideff
      call wrtc(zcom,m29,iblk,numdu)
c...    clear non-existent vectors abd populations and make e.v. large
      if(ncol.ne.norb.and.zcomm(5).ne.'vb'.and.zcomm(5).ne.'servec')then
         call vclr(q(ncol*norb+1),1,(norb-ncol)*norb)
         do i=ncol+1,norb
            value(i) = 9999900.0d0 + i*0.1d0
            pop(i) = 0.0d0
         end do
      end if
c
      call wrt3s(value(1),mach(8),numdu)
      nav = lenwrd()
      call wrt3is(ilifc(1),mach(9)*nav,numdu)
      call wrt3(q(1),nbsq,iblkq,numdu)
      call clredx
      call revind
      return
      end
      subroutine ctrchk(iblk)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/machin)
cfu      common/junk/ilifd(maxorb),ntrand(maxorb),itrand(mxorb3),
cfu     * ctrand(mxorb3),
cfu     *ilif(maxorb),ntr(maxorb),itr(mxorb3),ctr(mxorb3),of2
      common/blkctr/ilif(maxorb),ntr(maxorb),itr(mxorb3),ctr(mxorb3),of2
INCLUDE(common/tran)
INCLUDE(common/iofile)
INCLUDE(common/sector)
      equivalence (if1,otran),(if2,of2)
c
      nav = lenwrd()
      call readi(ilif,mach(9)*nav,iblk,numdu)
      if(if1.eq.if2)go to 2
      write(iwr,30)
 30   format(1x,' ***** inconsistent ctrans detected')
 3    call caserr2('retrieved eigenvectors are invalid')
 2    if(otran)return
      do 1 i=1,num
      ic=ilifc(i)
      n=ntran(i)
      if(ic.ne.ilif(i).or.n.ne.ntr(i)) then
       write(iwr,10) i, ilif(i), ntr(i), ic, n
 10   format(/' basis function ',i4,' ilif,ntr (input) = ',2i5/
     * 20x,' ilif,ntr (setup) = ',2i5)
       go to 3
      endif
      do 1 j=1,n
      if(itr(ic+j).ne.itran(ic+j)) then
       write(iwr,20) i,j, itr(ic+j), itran(ic+j)
  20   format(/' basis function ',i4, ' component ',i2,
     * ' input = ',i4,' setup = ',i4/)
      go to 3
      endif
 1    continue
      return
      end
      subroutine dmtx(d,v,p,ia,m,n,ndim)
_IF1(a)cvd$r noconcur
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension ia(*),d(*),v(ndim,*),p(*)
      data dzero /0.0d0/
      call vclr(d,1,ia(n+1))
      if(m.eq.0) return
      ii=0
      do 120 i = 1,n
      do 130 k = 1,m
      dum = p(k)*v(i,k)
      if(dum.ne.dzero) then
      call daxpy(i,dum,v(1,k),1,d(ii+1),1)
         endif
  130 continue
  120 ii=ii+i
      return
      end
      subroutine dmtxp(d,v,p,ia,m,n,ndim)
_IF1(a)cvd$r noconcur
      implicit REAL  (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension ia(*),d(*),v(ndim,*),p(*)
      data dzero /0.0d0/
      ltri = ia(n+1)
      call vclr(d,1,ltri)
      if(m.ne.0) then
         idum = iipsci()
         ii=0
         do 120 i = 1,n
            if(.not. oipsci())then
               do 130 k = 1,m
                  dum = p(k)*v(i,k)
                  if(dum.ne.dzero) then
                     call daxpy(i,dum,v(1,k),1,d(ii+1),1)
                  endif
 130           continue
            endif
            ii=ii+i
 120     continue
         call pg_dgop(1771,d,ltri,'+')
      endif
      return
      end

CMR   renamed function enuc for debugger namespace...
      function enucf(n,cz,c)
_IF1(a)c concurrency gives incorrect results
_IF1(a)cvd$r noconcur
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      logical indij,indji
INCLUDE(common/sizes)
INCLUDE(common/runlab)
INCLUDE(common/chgcc)
INCLUDE(common/repp)
INCLUDE(common/iofile)
INCLUDE(common/drfopt)
_IF(drf)
INCLUDE(../drf/comdrf/sizesrf)
INCLUDE(../drf/comdrf/drfpar)
INCLUDE(../drf/comdrf/rfene)
INCLUDE(../drf/comdrf/drfamb)
INCLUDE(../drf/comdrf/runpar)
_ENDIF
      dimension cz(*),c(3,*)
      data dzero /0.0d0/
      enuc = dzero
      enc  = dzero
_IF(vdw)
      call vdwaals_energy(enc)
_ENDIF
      enuc = enuc + enc
_IF(drf)
cdrf
cdrf  no amibiguous nuclei regarded here
cdrf  code can be found on the hondo8-file scfnew.f
      if ((n .eq. 1) .and. (field(:4) .ne. 'scf') 
     1 .and. (field(5:) .ne. 'scf')) then
          enucf=enuc
          return
      endif
_ELSE
       if (n .eq. 1) then
          enucf=enuc
          return
       endif
_ENDIF
c 
c if (indi)  core-core repulsion included here
c
      enc = dzero
      owarn = .false.
      do i = 2,n
         ni = i-1
         obqi = (omtslf .and. zaname(i)(1:2).eq.'bq')
         do  j = 1,ni
            obqj = (omtslf .and. zaname(j)(1:2).eq.'bq')
            if(.not. (obqi .and. obqj)) then
               rr = dzero
               do k = 1,3
                  rr = rr+(c(k,i)-c(k,j))**2
               enddo
               dsqrr=dsqrt(rr)
               if (indi) then
                 l  = 0
                 do k=1,npairs
                   indij = ichgat(i).eq.indx(k).and.ichgat(j).eq.jndx(k)
                   indji = ichgat(i).eq.jndx(k).and.ichgat(j).eq.indx(k)
                   if (indij.or.indji) l=k
                 enddo
                 if (l.ne.0)enc = enc + d(l)*dexp(-eta(l)*dsqrr)
               endif
               enuct = cz(i)*cz(j)/dsqrr
_IF(flucq)
C If FlucQ is active, add in this interaction to the FlucQ (CHARMM) arrays
               call fqqcor(i,j,enuct)
_ENDIF
               enuc = enuc+enuct
            else
               if(abs(cz(i)) .gt. 0.0001d0 .and. 
     &            abs(cz(j)) .gt. 0.0001d0)owarn = .true.
            endif
         enddo
      enddo
      enuc = enuc+enc
_IF(flucq)
C Signal that the nuclear term is now complete, to avoid recalculation
      call fqqcdn
_ENDIF
c
c informational messages (behaviour has changed in v 6.2)
c
      if(owarn)then
         write(iwr,100)
      else if (.not. omtslf)then
         write(iwr,101)
      endif
 100  format(//1x,'Nuclear energy has been computed in the presence',
     &     ' of a point charge field',/,
     &     1x,'Interaction between bq centres has been omitted.',
     &     ' To include it, include the class 1 directive BQBQ')
 101  format(1x,//'Nuclear energy includes self-energy of point ',
     &     'charge field')

_IF(drf)
cdrf-------------- unucrep contains vac-repulsion
      unucrep = enuc
cdrf----------------extension for inclusion of nuc-nuc-rep
      if (field(:4) .eq. 'scf') then
        enuc = enuc + extnuc(iactst)
        if (neqsta .eq. 1) enuc = enuc + ustanuc(iactst)
        if (neqrf .eq. 1) enuc = enuc + uneqnuc(iactst)
      endif
      if (field(5:) .eq. 'scf' .and. (iarfcal .eq. 0)) then
        enuc = enuc + snucext(iactst) +
     1                sextnuc(iactst)
      endif
      if ((field(5:) .eq. 'scf') .and. (iarfcal .eq. 0)) then
        enuc = enuc + scffact*snucnuc(iactst) 
      endif
cxxx  if ((field(:4) .eq. 'scf') .or. (field(5:) .eq. 'scf')) then
      if (field(:4) .eq. 'scf') then
        enuc = enuc + repmod(iactst)
      endif
cdrf------------------------
_ENDIF
      enucf=enuc
      return
      end

      function crnuc(n,cz,c,etmp)
_IF1(a)c concurrency gives incorrect results
_IF1(a)cvd$r noconcur
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
      dimension cz(*),c(3,*)
INCLUDE(common/runlab)
      data dzero /0.0d0/
      etmp = dzero
      crnuc = dzero
      if (n .eq. 1) return
      do 130 i = 2,n
         ni = i-1
         obqi = (zaname(i)(1:2).eq.'bq')
         do 120 j = 1,ni
            obqj = (zaname(j)(1:2).eq.'bq')
            if(obqi.and.obqj)goto 120
            rr = dzero
            do 100 k = 1,3
               rr = rr+(c(k,i)-c(k,j))**2
 100        continue
            e = cz(i)*cz(j)/dsqrt(rr)
            if(obqi.or.obqj)then
               e = e * 0.5d0
               etmp = etmp + e
            endif
            crnuc = crnuc + e
 120     continue
 130  continue
      write(iwr,160)crnuc
 160  format(1x,'    nuclear energy = ',f20.10)
      write(iwr,170)etmp
 170  format(1x,'    component from crystal field = ',f20.10)
      return
      end
      subroutine orfog(q,qp,b,c,iky,ilifq,newbas,nrow,iop)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension q(*),qp(*),b(*),c(*),iky(*),ilifq(*)
INCLUDE(common/sizes)
      dimension p(maxorb)
_IF1(h)      common/scftim/tdiag(2),torfog,tfock(7)
c... to orthogonalize the cols of q - result to qp
c... overlap matrix supplied in b - destroyed on exit
c... scratch triangle in c
c... iop=1 normal mode iop=2 qp set as if q was given as identity
c... qp can overwrite q
_IF1(h)      dumtim=dclock()
      top=dsqrt(1.0d0/b(1))
      b(1)=top
      do 1 i=2,newbas
      m=iky(i)
   1  c(m+1)=b(m+1)*top
      do 21 k=2,newbas
      m=iky(k)
      top=b(m+k)
      ll=k-1
      do 22 i=1,ll
       bot=c(m+i)
      p(i)=-bot
   22 top=top-bot*bot
      SAFMIN = DLAMCH( 'Safe minimum' )
      top = max(top,safmin)    !deal with division-by-zero -XJ
      top=dsqrt(1.0d0/top)
      b(m+k)=top
      n=k+1
       if(n.gt.newbas)goto 23
      do 24 l=n,newbas
      nsp=iky(l)
      c(nsp+k)=(ddot(ll,p,1,c(nsp+1),1)  +b(nsp+k))*top
   24 continue
   23 do 21 l=1,ll
      bot=0.0d0
      do 27   i=l,ll
   27 bot=p(i)*b(l+iky(i))+bot
   21 b(l+m)=bot*top
       goto (30,31),iop
   31    do 40 i=1,newbas
      m=ilifq(i)
      n=iky(i)
      do 40 j=1,nrow
      top=0.0d0
      if(j.le.i)top=b(n+j)
   40 qp(m+j)=top
      go to 50
   30 do 41 i=1,nrow
_IF1(c)      call gather(newbas,p,q(i+1),ilifq)
_IFN1(cf)      call dgthr(newbas,q(i+1),p,ilifq)
_IF1(f)      call viindx(q(i+1),ilifq,1,p,1,newbas)
      m=1
      do 41 j=1,newbas
       qp(i+ilifq(j))=ddot(j,b(m),1,p,1)
   41  m=m+j
_IFN1(h)   50 continue
_IF1(h)   50 torfog=torfog+(dclock()-dumtim)
      return
      end
       subroutine tranp(p1,p2)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension p1(*),p2(*)
      dimension ct1(mxorb3),it1(mxorb3)
INCLUDE(common/tran)
INCLUDE(common/mapper)
INCLUDE(common/infoa)
c
      l2=ikyp(num)
c
      if(otran)goto 100
      m=0
      do 1 i=1,num
      nt1=ntran(i)
      do 2 k=1,nt1
      l=k+ilifc(i)
      ct1(k)=ctran(l)
2     it1(k)=itran(l)
      do 1 j=1,i
      m=m+1
      p2(m)=0.0d0
      nt2=ntran(j)
      do 1 k=1,nt2
      kk=k+ilifc(j)
      l=itran(kk)
      do 1 ii=1,nt1
      ll=it1(ii)
      top=p1(iky(max(l,ll))+min(ll,l))
1     p2(m)=ct1(ii)*ctran(kk)*top+p2(m)
      return
 100  continue
      call dcopy(l2,p1(1),1,p2(1),1)
      return
      end
      subroutine ciexpr(kcorb,nconf,nham,ia,l1)
c
c     ----- update f, alpha, and beta matrices based on
c           the new ci coefficients -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/scfwfn)
      dimension ia(l1),kcorb(2,12),nconf(*)
      data dzero,two,tm6/0.0d0,2.0d0,1.0d-06/
      test = tm6
      nocio = 2
c
c     ----- normalize ci coefficients and update f -----
c
      do 140 kpair = 1,npair
      sum = ddot(nocio,cicoef(1,kpair),1,cicoef(1,kpair),1)
      if (sum .lt. test) sum = test
      sum = 1.0d0/dsqrt(sum)
      do 120 korb = 1,nocio
      cicoef(korb,kpair) = cicoef(korb,kpair)*sum
      kk = kcorb(korb,kpair)
      nx = nconf(kk)
  120 f(nx) = cicoef(korb,kpair)**2
  140 continue
c
c     ----- update alpha and beta -----
c
      do 180 kpair = 1,npair
      kone = kcorb(1,kpair)
      ktwo = kcorb(2,kpair)
      lo = nconf(kone)
      lt = nconf(ktwo)
      lolo = ia(lo)+lo
      lolt = ia(lt)+lo
      ltlt = ia(lt)+lt
      do 160 k = 1,nham
      lok = ia(max(lo,k))+min(lo,k)
      ltk = ia(max(lt,k))+min(lt,k)
      alpha(lok) = two*f(lo)*f(k)
      alpha(ltk) = two*f(lt)*f(k)
      beta(lok) = -f(lo)*f(k)
      beta(ltk) = -f(lt)*f(k)
  160 continue
      ann = cicoef(1,kpair)*cicoef(2,kpair)
      alpha(lolo) = f(lo)
      alpha(ltlt) = f(lt)
      beta(lolo) = dzero
      beta(ltlt) = dzero
      beta(lolt) = ann
      alpha(lolt) = dzero
  180 continue
      return
      end
      subroutine dengvb(trans,d,ifock,ia,l1)
c
c     ----- dengvb calculates the density matrix for all molecular
c            orbitals in the ifock'th fock operator -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/diisd/sta(270),iposa(24),stb(270),iposb(24),
     + ns(15),melsym(15),nconf(maxorb),msympr(maxorb),norb,nham,
     + nsytyp,nsos,
     + ti(25),e1i(25),asym,
     + cilow(12),jpair,kone,ktwo,kcorb(2,12),
     + iojk(49),ioham(25),iojkao(49)
      dimension ia(*),d(*),trans(l1,*)
      data dzero/0.0d0/
      call vclr(d,1,ia(l1+1))
      do 100 k = 1,norb
      nx = nconf(k)
      if (nx .ne. ifock) go to 100
      jbf = msympr(k)
      ij=1
      do 120 i=1,l1
      if(trans(i,jbf).ne.dzero)  then
      call daxpy(i,trans(i,jbf),trans(1,jbf),1,d(ij),1)
      endif
  120 ij=ij+i
  100 continue
      return
      end
      subroutine sto31g(ztext,ibasis,igauss)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension xng(6)
      data xng/
     *'1','2','3','4','5','6'/
      data yblnk,ydunn/' ','dunn' /
c
      ytext=ytrunc(ztext)
      if(ytext.eq.ydunn.or.ytext.eq.yblnk)go to 5
      xmg(1:1)=ztext(1:1)
      do 1 igauss=1,6
      if(xmg.eq.xng(igauss))go to 2
 1    continue
      call caserr2('invalid n specified in n-m1g keyword')
 2    xmg(1:1)=ztext(3:3)
      do 3 ibasis=2,3
      if(xmg.eq.xng(ibasis))go to 4
 3    continue
      call caserr2('invalid m specified in n-m1g')
 4    ibasis=ibasis-2
      return
 5    ibasis=3
c
      return
      end
      subroutine tdown(qnew,ilifn,q,ilifq,nnn)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension qnew(*),q(*),ilifn(*),ilifq(*)
      dimension dum(maxorb)
INCLUDE(common/tran)
INCLUDE(common/infoa)
c
      if(otran)go to 60008
      do 731 i=1,nnn
      m=ilifq(i)
      call vclr(dum,1,num)
      do 733 j=1,num
      n=ntran(j)
_IF1(x)c$dir scalar
_IF1(ct)cdir$ nextscalar
      do 733 k=1,n
      l=ilifc(j)    +k
733   dum(itran(l))=ctran(l)*q(m+j)+dum(itran(l))
      call dcopy(num,dum(1),1,qnew(ilifn(i)+1),1)
 731  continue
c 
60010 if (nnn.lt.num) then
c...    clear vectors that are extra
         do i=nnn+1,num
            call vclr(qnew(ilifn(i)+1),1,num)
         end do
      end if
c
      return
60008 do 60009 i=1,nnn
      call dcopy(num,q(ilifq(i)+1),1,qnew(ilifn(i)+1),1)
60009 continue
      return
      end

      subroutine wrt3i(ij,nword,iblk,num3)
c
c     this routine writes nword(s) of integer data, commencing at
c     block iblk on unit num3, from the array ij.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension ij(*)
_IFN(cray,ibm,vax,ksr)
INCLUDE(common/junkcc)
      dimension iq(1)
      equivalence (dchar(1),iq(1))
_ENDIF
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call wrt3i_ga( ij, nword, iblk, num3 )
      Else
_ENDIF
      call search(iblk,num3)
      j=1
      k=nword
 20   if(k)30,30,10
_IF(cray,ibm,vax,ksr,i8)
 10   call put(ij(j),min(k,511),num3)
      j=j+511
      k=k-511
_ELSE
 10   l=min(k,1022)
      do 40 loop=1,l
      iq(loop)=ij(j)
 40   j=j+1
      nout=lenint(l)
      call put(dchar(1),nout,num3)
      k=k-1022
_ENDIF
      go to 20
30    return
_IF(ga)
      End If
_ENDIF
      end
      subroutine readi(ij,nword,iblk,num3)
c
c     this routine reads nwords of integer data, commencing at
c     block iblk on unit num3 into the array ij.
c     note that nword has to be exactly what lies on disk
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension ij(*)
_IFN(cray,ibm,vax,ksr)
INCLUDE(common/junkcc)
      logical odd
      dimension iq(1)
      equivalence (iq(1),dchar(1))
_ENDIF
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call readi_ga( ij, nword, iblk, num3 )
      Else
_ENDIF
      call search(iblk,num3)
      j=1
_IF(cray,ibm,vax,ksr,i8)
 20   if(j.gt.nword)go to 30
      call find(num3)
      call get(ij(j),l)
      j=j+l
_ELSE
      nav = lenwrd()
      if(nav.eq.2 ) then
       odd = mod(nword,2).eq.1
      else
       odd = .false.
      endif
 20   if(j.gt.nword)go to 30
      call find(num3)
      call get(dchar(1),l)
      l=lenrel(l)
      if (odd) then
         do loop=1,l
          ij(j)=iq(loop)
          if (j.eq.nword) return
          j=j+1
         enddo
      else
         do loop=1,l
          ij(j)=iq(loop)
          j=j+1
         enddo
      endif
_ENDIF
      go to 20
30    if(j-1.ne.nword) then
       write(6,*)
     + 'invalid no of words: requested,present = ', nword, j-1
       call caserr2('invalid number of words in readi')
      endif
      return
_IF(ga)
      End If
_ENDIF
      end

_IFN(base_build)
_IF(i8drct)
      subroutine wrt3i8(ij,nword,iblk,num3)
c
c     this routine writes nword(s) of I8 data, commencing at
c     block iblk on unit num3, from the array ij.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer*8 ij
      dimension ij(*)
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call wrt3i8_ga( ij, nword, iblk, num3 )
      Else
_ENDIF
      call search(iblk,num3)
      j=1
      k=nword
 20   if(k)30,30,10
 10   call puti8(ij(j),min(k,511),num3)
      j=j+511
      k=k-511
      go to 20
30    return
_IF(ga)
      End If
_ENDIF
      end
      subroutine puti8(c,nword,iunit)
      implicit REAL (a-h,p-w),integer(i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      integer *8 c
      dimension c(*)
c ... atmol  i/o
      integer*8 abc
      common/bufa/abc(512)
      integer *8 ipack2, pack2
cfu      common/disc/isel,iselr ,iselw,irep,ichek,ipos(maxlfn),
cfu     *nam(maxlfn)
INCLUDE(common/disc)
      integer*8 q
      common/vinteg/q(1)
INCLUDE(common/maxlen)
INCLUDE(common/utilc)
INCLUDE(common/iofile)
c
      isel=iunit
      irec=ipos(isel)
      if(irec.lt.1) call iofail(iunit,2)
      ipos(isel)=irec+1
      if (ooprnt) then
       write(iwr,10) nword, iunit, irec
 10    format(1x,'**** puti8 ', i4,' words to unit', i3,
     +           ' at block',i5)
      endif   
      if(omem(iunit)) then
       iword = (irec-1)*512+iqqoff(iunit)+1
       ipack2 = pack2(irec,nword)
       q(iword+511)= ipack2
       do i=1,nword
        q(iword+i-1) = c(i)
       enddo
      else    
       do i =1,nword
        abc(i) = c(i)
       enddo
       ipack2 = pack2(irec,nword)
       abc(512)= ipack2
       call putcc(nam(isel),abc,ierrio)
       if(ierrio.ne.0)call ioerr('write',isel,' ')
      endif
      return
      end
      subroutine readi8(ij,nword,iblk,num3)
c
c     this routine reads nwords of I8 data, commencing at
c     block iblk on unit num3 into the array ij.
c     note that nword has to be exactly what lies on disk
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer*8 ij
      dimension ij(*)
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call readi8_ga( ij, nword, iblk, num3 )
      Else
_ENDIF
      call search(iblk,num3)
      j=1
 20   if(j.gt.nword)go to 30
      call find(num3)
      call geti8(ij(j),l)
      j=j+l
      go to 20
30    if(j-1.ne.nword) then
       write(6,*)
     + 'invalid no of words: requested,present = ', nword, j-1
       call caserr2('invalid number of words in readi8')
      endif
      return
_IF(ga)
      End If
_ENDIF
      end
      subroutine geti8(c,nword)
      implicit REAL (a-h,p-w),integer(i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer nchk(2)
INCLUDE(common/sizes)
      integer*8 c
      dimension c(*)
c ... single-buffered  i/o
      integer*8 abc
      common/bufa/abc(512)
      common/disc/isel,iselr ,iselw,irep,ichek,ipos(maxlfn),
     * nam(maxlfn)
INCLUDE(common/maxlen)
INCLUDE(common/iofile)
INCLUDE(common/utilc)
      integer*8 q
      common/vinteg/q(1)
c
      irec=ipos(isel)
      if (irec.lt.1) call iofail(isel,1)
      if (ooprnt) then
       write(iwr,10) isel, irec
 10    format(1x,'**** geti8 from unit', i3,
     +           ' at block',i5)
      endif
c
      if(omem(isel)) then
       iword = (irec-1)*512+iqqoff(isel)+1
       call upack2(q(iword+511),iibl,nword)
       do i=1,nword
        c(i) = q(iword+i-1)
       enddo
      else
c
c --- this is for the non multi-buffered streams
c
         call getcc(nam(isel),abc,ierrio)
         if(ierrio.ne.0)call ioerr('read',isel,' ')
c
c --- prepare to return results to the program
c
         call upack2(abc(512),iibl,nword)
         if (ooprnt) then
          write(iwr,20) iibl, nword
 20       format(/1x,'**** geti8: iblock,nword = ',
     +    2i6)
         endif
         do i =1,nword
          c(i) = abc(i)
         enddo
      endif
      ipos(isel)=irec+1
      return
      end
_ENDIF(i8drct)
_ENDIF(base_build)
      subroutine wrt3is(ij,nword,num3)
c
c     this routine writes nword(s) of integer data, commencing at
c     the current position/block on unit num3, from the array ij.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension ij(*)
_IFN(cray,ibm,vax,ksr)
INCLUDE(common/junkcc)
      dimension iq(1)
      equivalence (dchar(1),iq(1))
_ENDIF
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call wrt3is_ga( ij, nword, num3 )
      Else
_ENDIF
      j=1
      k=nword
 20   if(k)30,30,10
_IF(cray,ibm,vax,ksr,i8)
 10   call put(ij(j),min(k,511),num3)
      j=j+511
      k=k-511
_ELSE
 10   l=min(k,1022)
      do 40 loop=1,l
      iq(loop)=ij(j)
 40   j=j+1
      nout=lenint(l)
      call put(dchar(1),nout,num3)
      k=k-1022
_ENDIF
      go to 20
30     return
_IF(ga)
      End If
_ENDIF
       end
      subroutine readis(ij,nword,num3)
c
c     this routine reads nword(s) of integer data, commencing at
c     the current position/block on unit num3 into the array ij.
c     note that nword has to be exactly what lies on disk.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension ij(*)
_IFN(cray,ibm,vax,ksr)
      logical odd
INCLUDE(common/junkcc)
      dimension iq(1)
      equivalence (iq(1),dchar(1))
_ENDIF
_IF(ga)
INCLUDE(common/sizes)
INCLUDE(common/disc)
      If( iwhere( num3 ) .EQ. 6 .Or. iwhere( num3 ) .EQ. 7 ) Then 
         Call readis_ga( ij, nword, num3 )
      Else
_ENDIF
      j=1
_IF(cray,ibm,vax,ksr,i8)
 20   if(j.gt.nword)go to 30
      call find(num3)
      call get(ij(j),l)
      j=j+l
_ELSE
      nav = lenwrd()
      if(nav.eq.2 ) then
       odd = mod(nword,2).eq.1
      else
       odd = .false.
      endif
 20   if(j.gt.nword)go to 30
      call find(num3)
      call get(dchar(1),l)
      l=lenrel(l)
      if (odd) then
         do loop=1,l
          ij(j)=iq(loop)
          if (j.eq.nword) return
          j=j+1
         enddo
      else
         do loop=1,l
          ij(j)=iq(loop)
          j=j+1
         enddo
      endif
_ENDIF
      go to 20
 30   if(j-1.ne.nword) then
       write(6,*)
     + 'invalid no of words: requested,present = ', nword, j-1
       call caserr2('invalid number of words in readis')
      endif
      return
_IF(ga)
      End If
_ENDIF
      end

      subroutine restre
      implicit REAL  (a-h,o-z)
c ...
c ... restore restart section on dumpfile
c
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
      data m21/21/
c
      call secget(isect(501),m21,ibl3rs)
      call rdchr(title,ldsect(isect(501)),ibl3rs,idaf)
      call reads(cspace,lds(isect(501)),idaf)
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
c
      return
      end
      subroutine revise
      implicit REAL  (a-h,o-z)
c ...
c ... update restart section on dumpfile
c
INCLUDE(common/sizes)
INCLUDE(common/common)
INCLUDE(common/cndx40)
INCLUDE(common/cndx41)
c
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/machin)
INCLUDE(common/infoa)
      logical irspl
      common/junko/cspace(30),irspa(700),irspl(40),irspb(1590),
     *             irspc(40),irspd(296),irspe(8)
      data m21/21/
c
      len501=lensec(ldsect(isect(501))) + lensec(lds(isect(501)))
      call secput(isect(501),m21,len501,ibl3rs)
c
      call dcopy(len_restrr,gx,1,cspace,1)
_IF(cray)
      call fmove(nprint,irspa,len_restar)
      call fmove(ciopt,irspl,len_restrl)
      call fmove(jjfile,irspb,len_restri)
      call fmove(master,irspc,len_cndx40)
      call fmove(ncoorb,irspd,len_cndx41)
      call fmove(nat,irspe,len_infoa)
_ELSE
      call icopy(len_restar,nprint,1,irspa,1)
      call icopy(len_restrl,ciopt,1,irspl,1)
      call icopy(len_restri,jjfile,1,irspb,1)
      call icopy(len_cndx40,master,1,irspc,1)
      call icopy(len_cndx41,ncoorb,1,irspd,1)
      call icopy(len_infoa,nat,1,irspe,1)
_ENDIF
c
      call wrtc(title,ldsect(isect(501)),ibl3rs,idaf)
      call wrt3s(cspace,lds(isect(501)),idaf)
c...  check
      if (len_cndx41.gt.296) call caserr('common/cndx41 too big')
c
      return
      end
      function ispchk()
c
c     ----- check for nature of basis -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/junk/
     *kstart(mxshel),katom(mxshel),ktype(mxshel),
     *kng(mxshel),kloc(mxshel),kmin(mxshel),kmax(mxshel),nshell,non3(3)
INCLUDE(common/machin)
INCLUDE(common/iofile)
INCLUDE(common/restri)
INCLUDE(common/restrl)
c
      data mone/1/
c
      call secget(isect(491),mone,iblkv)
      m110=10+maxat
      m1420=mxprim*5+maxat
      len=lensec(mxprim)+lensec(m1420)+lensec(m110)
      ibl491 = iblkv + len
      nav = lenwrd()
      call readi(kstart,mach(2)*nav,ibl491,idaf)
c
      itype = 1
      opbas = .false.
      odbas = .false.
      ofbas = .false.
      ogbas = .false.
      do 100 loop = 1,nshell
      if (ktype(loop) .eq. 2) opbas = .true.
      if (ktype(loop) .eq. 3) odbas = .true.
      if (ktype(loop) .eq. 4) ofbas = .true.
      if (ktype(loop) .eq. 5) ogbas = .true.
  100 continue
      if (opbas) then
      itype = 2
      endif
      if (odbas) then
      itype = 3
      endif
      if (ofbas) then
      itype = 4
      endif
      if (ogbas) then
      itype = 5
      endif
      ispchk = itype
      return
      end
      function locats(ztext,ns,ytext)
      implicit REAL  (a-h,p-w),integer (i-n),logical (o)
      implicit character*8 (z),character*1 (x)
      implicit character*4 (y)
      character*(*) ztext,ytext
      dimension ztext(*)
      do 10 i = 1 , ns
            loop = i
            if( index(ztext(i),ytext) ) 10,10,20
  10  continue
      locats = 0
      return
  20  locats = loop
      return
      end
      subroutine linear(a,b,mdim,n)
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character*8 (z), character*1 (x), character*4 (y)
c
c places symmetric square array in a linear form
c
      dimension a(mdim,*),b(*)
      k = 1
      do 10 j = 1 , n
         do 20 i = 1 , j
            b(k) = a(i,j)
            k = k + 1
20    continue
10    continue
      return
      end
      subroutine squar(a,b,mdim,n,key)
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character*8 (z), character*1 (x), character*4 (y)
c
c     places linear array in square form
c     two parts ... key =
c     1  square array to be formed not symmetric
c     0  square array to be formed symmetric
c
      dimension a(*),b(mdim,*)
c
      if(key)1,3,1
c
c     ---- key=1  array not symmetric ----
c
    1 k=n*n
      do  10 j = 1 , n
          jx = n - j + 1
          do 20 i = 1 , n
             ix = n - i + 1
             b(ix,jx) = a(k)
             k = k - 1
20    continue
10    continue
      return
c
c     ---- key=0  array symmetric ----
c
    3 k = n * ( n + 1 ) / 2
      do  30 j = 1 , n
          jx = n - j + 1
          do 40 i = 1 , jx
             ix = jx - i + 1
             b(ix,jx) = a(k)
             k = k - 1
40    continue
30    continue
      do 50 j = 1 , n
         do 60 i = 1 , j
            b(j,i) = b(i,j)
60    continue
50    continue
      return
      end
      subroutine demoao(dmo, dao, coorb, t,nbasis,ncoorb,ndim)
c
c  transform density matrix from mo basis to ao basis
c
c  dmo density matrix in mo basis (triangular form)
c  dao array for density matrix in ao basis (triangular form)
c  coorb mo coefficients
c  t workspace
c  nbasis number of basis functions
c
      implicit REAL  (a-h,o-z)
      dimension dmo(*), dao(*), coorb(ndim,*), t(*)
c
      ij = 0
      do 60 j = 1 , nbasis
         t(1) = dmo(1)*coorb(j,1)
         kk = 1
         do 30 k = 2 , ncoorb
            x = 0.0d0
            km1 = k - 1
            do 20 l = 1 , km1
               x = x + dmo(kk+l)*coorb(j,l)
               t(l) = t(l) + dmo(kk+l)*coorb(j,k)
 20         continue
            t(k) = x + dmo(kk+k)*coorb(j,k)
            kk = kk + k
 30      continue
         do 50 i = 1 , j
            x = 0.0d0
            do 40 k = 1 , ncoorb
               x = x + coorb(i,k)*t(k)
 40         continue
            ij = ij + 1
            dao(ij) = x
 50      continue
 60   continue
      return
c
      end
      subroutine prtris(f,numscf,iw)
      implicit REAL  (a-h,o-z)
      dimension f(*)
INCLUDE(common/sizes)
INCLUDE(common/mapper)
      dimension n(8)
      mmax = 8
      imax = 0
 20   imin = imax + 1
      imax = imax + mmax
      if (imax.gt.numscf) imax = numscf
      write (iw,6010)
      write (iw,6020) (i,i=imin,imax)
      write (iw,6010)
      do 40 j = 1 , numscf
         nn = 0
         do 30 i = imin , imax
            nn = nn + 1
            n(nn) = iky(max(i,j)) + min(i,j)
 30      continue
         write (iw,6030) j , (f(n(i)),i=1,nn)
 40   continue
      if (imax.lt.numscf) go to 20
      return
 6010 format (/)
 6020 format (5x,8(6x,i3,6x))
 6030 format (i5,8f15.8)
      end
      function lenint(n)
      implicit REAL  (a-h,o-z)
c
c     lenint returns the number of reals corresponding to n integers
c     for all n greater than zero. For n equals zero it returns one.
c     Valid inputs are all non-negative integers.
c
c     Proof:
c
c     Define m = lenwrd() which means that m can be either 1 or 2.
c
c     Assume n = i*m, i > 0 then
c     lenint = (i*m-1)/m+1
c            = i-1      +1
c            = i
c     Assume n = i*m+j, i >= 0 and 0 < j < m
c     lenint = (i*m+j-1)/m+1
c            = (i*m)/m+(j-1)/m+1
c            = i+1
c     Assume n = 0
c     lenint = 0/m+1
c            = 1
c     
c     The max is required to handle the n=0 and m=1 case correctly.
c
_IF(debug)
      if (n.lt.0) call caserr2('function lenint: n =< 0')
_ENDIF
      lenint = max(n-1,0)/lenwrd()+1
      return
      end
      function lenrel(n)
c     lenrel is the number of integers corresponding to n reals
      implicit REAL  (a-h,o-z)
      lenrel = n*lenwrd()
      return
      end
      subroutine prsqm(w,nbasis,ncol,ndim,iw)
      implicit REAL  (a-h,o-z)
      dimension w(*)
      m = 1
      n = 6
 20   if (ncol.lt.m) return
      if (n.gt.ncol) n = ncol
      write (iw,6010) (i,i=m,n)
      write (iw,6020)
      do 30 j = 1 , nbasis
         write (iw,6030) j , (w(j+(i-1)*ndim),i=m,n)
 30   continue
      m = m + 6
      n = n + 6
      go to 20
 6010 format (/5x,6i12)
 6020 format (/)
 6030 format (i5,6f12.6)
      end
      subroutine squr(t,sq,n)
      implicit REAL  (a-h,o-z)
c     triangle to square
      dimension sq(2),t(2)
      ij = 0
      ii = 0
      do 30 i = 1 , n
         jj = 0
_IF1(ct)cdir$ ivdep
_IF1(a)cvd$  nodepck
_IF1(x)c$dir no_recurrence
         do 20 j = 1 , i
            ij = ij + 1
            sq(ii+j) = t(ij)
            sq(jj+i) = t(ij)
            jj = jj + n
 20      continue
         ii = ii + n
 30   continue
      return
      end
      subroutine archiv(option,iwrite)
      implicit REAL  (a-h,o-z)
************************************************************************
*
*   archiv positions the mopac archive file
*   on unit 12 - for data retrieval by gamess.
*   zmatrix, geometry  and vectors defined by option
*
************************************************************************
_IF1(c)      integer getenv
      character *(*) option
      character *10 string
      character*(132) filatt,zarch
      character *80 line
INCLUDE(common/work)
INCLUDE(common/iofile)
      data zarch/'archive'/
c
      iread = 12
      filatt = ' '
_IF(cray)
      ii = getenv(zarch,filatt)
      if(ii.ne.0)  filatt = zarch
_ELSEIF(vax)
      filatt = zarch
_ELSEIF(ipsc)
      filatt = '/cfs/wab/archive'
_ELSE
      call gtnv(zarch,filatt)
      if (filatt.eq.' ') filatt = zarch
      do loop = len(filatt),1,-1
        if(filatt(loop:loop).ne.' ') goto 30
      enddo
   30 continue
_ENDIF
c
      if (option.eq.'zmat') then
       string = 'zmatrix an'
       jrec = 0
      else if (option.eq.'vect') then
       string = 'vectors mo'
       jrec = 0
      else if (option.eq.'geom') then
       string = 'geometry m'
      else
       call caserr2('invalid request for archive data')
      endif
      irdd = 0
c
      close (iread)
      open(unit=iread,file=filatt,form='formatted',status='unknown')
      rewind iread
   10 read(iread,'(a80)',end=20,err=20)line
      irdd = irdd + 1
      if(index(line,string).eq.0) go to 10
      ird = iread
      return
   20 rewind iread
      write(iwrite,'(a)')' archive file missing or empty'
      call caserr2('requested archive file missing or empty')
      return
      end
_IF()
      subroutine needcm(length,need)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/segm)
INCLUDE(common/iofile)
      write(iwr,9007)
      if(length.gt.nmaxly)write (iwr,9008) length,need,nmaxly
 9008 format(
     *' number of words needed    ',i8/
     *' length of present overlay ',i8/
     *' number of words available ',i8///)
 9007  format(//)
      return
      end
_ENDIF
      subroutine ver_util1(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/util1.m,v $
     +     "/
      data revision /"$Revision: 6246 $"/
      data date /"$Date: 2011-10-31 23:16:26 +0100 (Mon, 31 Oct 2011) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
_IF(hpux11)
c$HP$ OPTIMIZE LEVEL3
_ENDIF
      subroutine check_feature(module)
c
c...  called to indicate whether a module can handle a feature, so that if one does
c...  not copy all features to an improved routine, one can make sure the user is warned.
c...  Initially set up for ZORA, which was not implemented in direct mode. Thus no ZORA was done
c...  which was easily missed.  
c
      parameter (nmodules=14,ncheck=2)
      character*(*) module
      character*10 modules(0:ncheck,nmodules),type(0:ncheck)
c     
INCLUDE(common/zorac)
INCLUDE(common/iofile)
      character*60 error
c
      data type   /'module',' zora ', 'general'/
      data modules/'denscf',   'all', ' '       ,
     2             'gvbitr',   'all', ' '       ,
     3             'rhfcld',   'all', ' '       ,
     4             'rhfclm',   'all', ' '       ,
     5             'drhfcl',   'atom',' '       ,
     6             'drhfcl_ga','atom',' '       ,
     7             'dscrf',    'atom',' '       ,
     8             'duhfop',   'atom',' '       ,
     9             'uhfop',    'all', ' '       ,
     x             'drhfgvb',  'atom',' '       ,
     1             'denscf_ga','all', ' '       ,
     2             'indx2t',   'all',' '       ,
     3             'corbls',   'atom',' '       ,
     4             'corbld',   'atomw',' '       /
c
c...   which module ?
c
_IFN(zora)
      ozora = .false.
_ENDIF
      do i=1,nmodules
         if (module.eq.modules(0,i)) go to 10
      end do
      error = module//' is not known in check_feature'
      call caserr(error)
c
10    imodule = i
c
      do icheck=1,ncheck
         if (modules(icheck,imodule).eq.' ') return 
         if (icheck.eq.1.and.ozora) then
c...        ZORA
            if (modules(icheck,imodule).eq.'all') return 
            if (modules(icheck,imodule).eq.'atom') then 
               if (nat_z.eq.0.or.oscalatz) then
                  error = module//
     1                  ' does not allow other than simple atomic ZORA'
                  call caserr(error)
               end if
            else if (modules(icheck,imodule).eq.'atomw') then 
               if (nat_z.eq.0.or.oscalatz) then
                  error = module//
     1                  ' does not allow other than simple atomic ZORA'
                  write(iwr,1)  error
1                 format(1x,/1x,75(1h*),/1x,a80,/1x,75(1H*))
               end if
            else if (modules(icheck,imodule).eq.'none') then 
               if (ozora) then
                  error = module//' does not allow for the use of ZORA'
                  if (ozora) call caserr(error)
               end if
            end if
         end if
      end do
c
      return
      end
