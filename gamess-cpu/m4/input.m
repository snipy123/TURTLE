_IF(win95)
*$pragma aux prpnam "!_" parm(value,reference,value,reference,reference)
_ENDIF
      subroutine active(nact,iact,oflag,ochek)
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/work)
      dimension ond(maxorb)
      dimension iact(*)
c
      data yend,yto/'end','to'/
c
      nact = 0
_IF1(cu)      call setsto(maxorb,.false.,ond)
_IFN1(cuf)      call setstl(maxorb,.false.,ond)
_IF1(f)      call vfill(.false.,ond,1,maxorb)
      if (ochek) then
         call input
      end if
 20   call inpa4(ytest)
      if (jrec.le.jump) then
         if (ytest.eq.yend) then
            if (oflag) return
            if (nact.lt.1) call caserr2(
     +                     'invalid number of active orbitals')
c
            return
         else
            jrec = jrec - 1
            call inpi(m)
            n = m
            call inpa4(ytest)
            if (ytest.ne.yto) then
               jrec = jrec - 1
            else
               call inpi(n)
            end if
         end if
      else if (ochek) then
         call input
         go to 20
      end if
      if (n.lt.1 .or. m.lt.1 .or. n.gt.maxorb)
     +   call caserr2('invalid orbital specified in active directive')
      do 30 i = m , n
         nact = nact + 1
         if (ond(i)) call caserr2(
     +            'orbital doubly defined in active directive')
         if (nact.gt.maxorb)
     +       call caserr2('invalid number of active orbitals')
         ond(i) = .true.
         iact(nact) = i
 30   continue
      go to 20
c
      end
      function arccos(aa)
      implicit REAL  (a-h,o-z)
      a = aa
      if (a.gt.1.0d0) a = 1.0d0
      if (a.lt.-1.0d0) a = -1.0d0
      arccos = dacos(a)
      return
      end
      subroutine bend(noint,i,j,k,b,ib,c)
c
c        adapted from the normal coordinate analysis program of
c        schachtschneider, shell development .
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension b(3,4,2),ib(4,2),c(*)
      dimension rji(3),rjk(3),eji(3),ejk(3)
c
      data dzero/0.d0/,done/1.d0/
c
      iaind = 3*(i-1)
      jaind = 3*(j-1)
      kaind = 3*(k-1)
      ib(1,noint) = i
      ib(2,noint) = j
      ib(3,noint) = k
      djisq = dzero
      djksq = dzero
      do 20 m = 1 , 3
         rji(m) = c(m+iaind) - c(m+jaind)
         rjk(m) = c(m+kaind) - c(m+jaind)
         djisq = djisq + rji(m)**2
         djksq = djksq + rjk(m)**2
 20   continue
      dji = dsqrt(djisq)
      djk = dsqrt(djksq)
      dotj = dzero
      do 30 m = 1 , 3
         eji(m) = rji(m)/dji
         ejk(m) = rjk(m)/djk
         dotj = dotj + eji(m)*ejk(m)
 30   continue
      dum = done-dotj**2
      if (dum.lt.dzero) dum = dzero
      sinj = dsqrt(dum)
      if (sinj.lt.1.0d-20) then
         do 40 m = 1 , 3
            b(m,3,noint) = 0.0d0
            b(m,1,noint) = 0.0d0
            b(m,2,noint) = 0.0d0
 40      continue
         return
      else
         do 50 m = 1 , 3
            b(m,3,noint) = ((dotj*ejk(m)-eji(m)))/(djk*sinj)
            b(m,1,noint) = ((dotj*eji(m)-ejk(m)))/(dji*sinj)
            b(m,2,noint) = -b(m,1,noint) - b(m,3,noint)
 50      continue
c
         return
      end if
c
      end
      subroutine bondin(number,c,az,s3,mxbnds,icon,ifrag,ncon,scale)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer s3
c
INCLUDE(common/sizes)
INCLUDE(common/iofile)
c
      character*8 atlet,atlet2
      common /bufb/atlet(maxat),atlet2(maxat)
      dimension    icon(s3,mxbnds),ifrag(*),ncon(s3)
c
c calculate the bonding in a molecule given only its coordinates
c and the atomic number
c watch out for separate units; make up a bond for them (jvl,2000)
c ifrag is used for this (this is icon2(s3,mxbnds)) clear it after
c
      dimension c(3,*),az(*)
INCLUDE(common/coval)
      data dtwo/2.0d0/
c     data done/1.0d0/
c     scale = 1.1d0
      if (scale.ne.1.1d0) write(iwr,*) 'for bonding determination ',
     1                    'criterion is scaled by ',scale
      ntime = 0
c
c zero arrays
c
      call setsto(s3,0,ncon)
      call setsto(s3*mxbnds,0,icon)
      do 30 i = 1 , number
         iz = nint(az(i))
         covi = dtwo
         if (iz.gt.0 ) covi = cov(iz)
         do 20 j = 1 , number
            if (i.ne.j) then
               blij =  dsqrt((c(1,j)-c(1,i))**2+
     +                 (c(2,j)-c(2,i))**2+(c(3,j)-c(3,i))**2)
               jz = nint(az(j))
               covj = dtwo
               if (jz.gt.0 ) covj = cov(jz)
               if (ncon(i).lt.mxbnds .and. blij.lt.(covi+covj)*scale)
     +             then
                  ncon(i) = ncon(i) + 1
                  icon(i,ncon(i)) = j
               end if
            end if
 20      continue
 30   continue
c	
c	correction for non-bonded atoms, ajb 28/9/95 (removed now)
c       corrected for case of non-bonded fragments (jvl/00) 
c
c...    divide molecule in connected fragments
c
40    kfrag = 0
      call setsto(s3*mxbnds,0,ifrag)
      do i=1,number
        if (ifrag(i).eq.0) then
          do j=1,ncon(i)
            if (ifrag(icon(i,j)).ne.0) then
              ifrag(i) = ifrag(icon(i,j))
              go to 50
            end if
          end do
          kfrag = kfrag + 1
          ifrag(i) = kfrag
        end if
50      ifragi = ifrag(i)
        do j=1,ncon(i)
          if (ifrag(icon(i,j)).ne.ifragi) then
            if (ifrag(icon(i,j)).eq.0) then
              ifrag(icon(i,j)) = ifragi
            else
              ifragj = ifrag(icon(i,j))
              ifragk = min(ifragj,ifragi) 
              do k = 1,number
                if (ifrag(k).eq.ifragi.or.ifrag(k).eq.ifragj) 
     1             ifrag(k) = ifragk
              end do
            end if
          end if
        end do
      end do
c
c...   compress  fragment numbering
c
60    nfrag = 0
      do i=1,number
        nfrag = max(nfrag,ifrag(i))
      end do
      do k=1,nfrag
        do i=1,number
          if (ifrag(i).eq.k) go to 70
        end do
c...      found a non-existent fragment number
        do i = 1,number
          if (ifrag(i).gt.k) ifrag(i) = ifrag(i) - 1
        end do
        go to 60
70      continue
      end do
c
c...  if we have more fragments link the first two by closest connection
c
       ntime = ntime + 1
       if (nfrag.gt.1.and.ntime.eq.1.or.ntime.gt.10) write(iwr,1) nfrag
1      format(1x,i5,' fragments will be artifically linked')
c
      if (nfrag.gt.1) then
        dist=1.0d50
        iat = 0
        do i=1,number
          if (ifrag(i).eq.1) then
            do j=1,number
              if (ifrag(j).eq.2) then
                blij =  dsqrt((c(1,j)-c(1,i))**2+
     +                        (c(2,j)-c(2,i))**2+(c(3,j)-c(3,i))**2)
                if (blij.le.dist) then
                  iat = i
                  jat = j
                  dist = blij
                end if
              end if
            end do
          end if
        end do
c 
        if (iat.eq.0) call caserr2('huge distance in bondin')
c
        ncon(iat) = ncon(iat) + 1
        icon(iat,ncon(iat)) = jat
        ncon(jat) = ncon(jat) + 1
        icon(jat,ncon(jat)) = iat
c...  check again on seperate fragments
        go to 40            
      end if
c
      call setsto(s3*mxbnds,0,ifrag)
      return
      end
      subroutine calcin(pop,iconf,aocc)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
c
c trans. dens. input - only for one graph at the moment
c was done just in the way to function as soon as possible
c
      common/tmdata/iwanted,imultcoor,isymcoor,ianticoor,integcoor,
     +              otran,isp4(2)
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
      common/dfclc2/cscal(mxcalc),iblkp(mxcalc)
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
     &               iresec(mxrest),nrest
c
c labels and titles
c
      common/cplot/zgridt(10,mxgrid),zgrid(mxgrid),
     &             zcalct(10,mxcalc),zcalc(mxcalc),
     &             zplott(10,mxplot),zplot(mxplot)
c the job sequence
      integer stype(mxstp), arg(mxstp)
      common/route/stype,arg,nstep,istep
c
INCLUDE(common/iofile)
INCLUDE(common/scra7)
INCLUDE(common/discc)
INCLUDE(common/work)
INCLUDE(common/workc)
c for zaname
INCLUDE(common/runlab)
c
INCLUDE(common/infoa)
c
      dimension pop(*), iconf(*), aocc(*)
      data zblank/'        '/
      data zuntit/'untitled'/

      if(ncalc.eq.mxcalc)call caserr2
     &     ('too many graphics calculations defined')
      ncalc = ncalc + 1
      nstep = nstep+1
      stype(nstep) = 2
      arg(nstep) = ncalc
c
c set defaults
c
      icsect(ncalc) = 0
      ictype(ncalc) = -1
      icstat(ncalc) = 0
      iblkp(ncalc) = -1
      cscal(ncalc) = 1.0d0
      nconf = 0
      npop = 0
      nvdw = 0
      oocc = .false.
      oscal= .false.
      otran=.false.
      iwanted=0
      imultcoor=0
      isymcoor=0
      ianticoor=0
      integcoor=0
c
      nav = lenwrd()
c
c use most recent grid
c
      icgrid(ncalc) = ngrid
      icgsec(ncalc) = 0
c
      do 5 i = 1,10
         zcalct(i,ncalc) = zblank
 5    continue
      zcalct(1,ncalc) = zuntit
      write(zcalc(ncalc),'(i8)')ncalc
c
      if(jump.eq.2)call inpa(zcalc(ncalc))
 10   call input
      call inpa(ztest)
      ytest=ytrunc(ztest)
      if(ytest.eq.'titl')then
c
_IF1()c
_IF1()c don't convert to uppercase or lowercase - the title should
_IF1()c not be just simple text, but should allow for TeX
_IF1()c to make later use of plotting utilities 
_IF1()c
_IF1()c         call input
_IF1()c         k = 1
_IF1()c         do 20 i = 1 , 10
_IF1()c            zcalct(i,ncalc) = char1(k:k+7)
_IF1()c            k = k + 8
_IF1()c 20      continue
_IF1()c
          read(ird,'(10a8)')(zcalct(i,ncalc),i=1,10)
c
c
      else if(ytest.eq.'type')then
         if(ictype(ncalc).ne.-1)
     &        call caserr2('multiple calculation type specification')
         call inpa4(ytest)
         if(ytest.eq.'dens'.or.ytest.eq.'tran')then
            ictype(ncalc)=1
            if(ytest.eq.'tran') then
            otran=.true.
c iwanted is number of MRDCI (or RPA) root stored in itmfile
c saved in tm.f or in RPA program by C. Fuchs
c
c the transition density can by (anti)symetrized along given axis
c multiplied by coordinate and/or integrated over coordinate
c perpendicular to plane of 2D grid
c not all combinations are allowed, but this is not checked here
c
      call inpi(iwanted)
800   call inpa(zztest)
      yytest=ytrunc(zztest)
      if(yytest.ne.'    ') then
        if(yytest.eq.'xmul') then
          imultcoor=1
          goto 800
        endif
        if(yytest.eq.'ymul') then
          imultcoor=2
          goto 800
        endif
        if(yytest.eq.'zmul') then
          imultcoor=3
          goto 800
        endif
        if(yytest.eq.'xsym') then
          isymcoor=1
          goto 800
        endif
        if(yytest.eq.'ysym') then
          isymcoor=2
          goto 800
        endif
        if(yytest.eq.'zsym') then
          isymcoor=3
          goto 800
        endif
        if(yytest.eq.'xant') then
          ianticoor=1
          goto 800
        endif
        if(yytest.eq.'yant') then
          ianticoor=2
          goto 800
        endif
        if(yytest.eq.'zant') then
          ianticoor=3
          goto 800
        endif
        if(yytest.eq.'xint') then
          integcoor=1
          goto 800
        endif
        if(yytest.eq.'yint') then
          integcoor=2
          goto 800
        endif
        if(yytest.eq.'zint') then
          integcoor=3
          goto 800
        endif
        write(iwr,*)' calcin: tran: unknown subdirective: ',zztest
        call caserr2('unrecognized subdirective after type tran')
      endif
c     endif
            endif
         else if(ytest.eq.'mo  ')then
            ictype(ncalc)=2
            call inpi(icdata(1,ncalc))
         else if(ytest.eq.'atom')then
            ictype(ncalc)=3
         else if(ytest.eq.'pote')then
            ictype(ncalc)=4
         else if(ytest.eq.'grad')then
            call inpa4(ytest)
            if(ytest.eq.'dens')then
               ictype(ncalc)=5
            else if(ytest.eq.'vdw ')then
               ictype(ncalc)=11
            else if(ytest.eq.'lvdw')then
               ictype(ncalc)=12
            else if(ytest.eq.'mo  ')then
               ictype(ncalc)=6
               call inpi(icdata(1,ncalc))
            else
               call caserr2('invalid subkeyword for grad')
            endif
         else if(ytest.eq.'vdw ')then
c van der waals function
            ictype(ncalc)=9
         else if(ytest.eq.'lvdw')then
c log of van der waals function
            ictype(ncalc)=10
         else if(ytest.eq.'comb')then
c
c comb [ed3 1 ] 1 scale
c
            ictype(ncalc)=7
            call inpa(ztest)
            ytest = ytrunc(ztest)
            l = locatc(yed,maxlfn,ytest)
            if (l.eq.0)then
               jrec = jrec - 1
               icdata(1,ncalc)=idaf
               icdata(2,ncalc)=ibl3d
               call inpi(icdata(3,ncalc))
            else
               icdata(1,ncalc) = l
               call inpi(icdata(2,ncalc))
               call inpi(icdata(3,ncalc))
            endif
            call inpf(cdata(1,ncalc))
         else if(ytest.eq.'chec')then
            ictype(ncalc)=-1
         else
            call caserr2('invalid calculation type')
         endif
c
c
      else if(ytest.eq.'sect')then
         call inpi(icsect(ncalc))
      else if(ytest.eq.'sfac')then
         call inpf(cscal(ncalc))
         oscal=.true.
      else if(ytest.eq.'prin')then
         icdata(1,ncalc) = 1
      else if(ytest.eq.'nozr')then
cTWK     Drop nuclear contribution to electrostatic potential
         icdata(2,ncalc) = 1
      else if(ytest.eq.'nopg')then
         icdata(5,ncalc) = 1
      else if(ytest.eq.'conf')then
 90      call input
         call inpa(ztest)
         ytest = ytrunc(ztest)
         if (ytest.ne.'end ')then
            nconf = nconf + 1
            jrec = jrec - 1
            call inpa(ztest)
            iconf(nconf) = locatc(zaname,nat,ztest)
            if(iconf(nconf).eq.0)call caserr2
     &           ('invalid tag on config data line')
            jump1 = jump - 1
            if (jump1.le.0) call caserr2
     +           ('invalid syntax for config data line')
            do 100 i = 1 , jump1
               npop = npop + 1
               call inpf(pop(npop))
 100        continue
         else
            goto 10
         endif
         goto 90
      else if(ytest.eq.'radi')then
         fac = 1.0d0
         if(jump.eq.2)then
            call inpa(ztest)
            ytest = ytrunc(ztest)
            if(ytest.eq.'angs')then
               fac=1.889726664d0
            else if(ytest.ne.'a.u.'.and.ytest.ne.'au')then
               call caserr2('invalid unit on radii directive')
            endif
         else if (jump.ne.1) then
            call caserr2('invalid radii directive')
         endif
 120     call input
         call inpa(ztest)
         ytest = ytrunc(ztest)
         if (ytest.ne.'end ')then
            nvdw = nvdw + 1
            jrec = jrec - 1
            call inpa(ztest)
            iconf(nvdw) = locatc(zaname,nat,ztest)
            if(iconf(nvdw).eq.0)call caserr2
     &           ('invalid tag on radii data line')
            jump1 = jump - 1
            if (jump1.le.0) call caserr2
     +           ('invalid syntax for radii data line')
            call inpf(pop(nvdw))
            pop(nvdw)=pop(nvdw)*fac
         else
            goto 10
         endif
         goto 120
      else if(ytest.eq.'occd')then
         call vclr(aocc,1,maxorb)
         call popd(aocc,num)
         oocc = .true.
      else
c
c save mo population data on scratchfile
c            
         if(oocc)then
            if(ictype(ncalc).eq.9.or.ictype(ncalc).eq.10)
     &       call caserr2('occdef data incompatible with calc. type')
            iblk = ibl7la
            call wrt3(aocc,num,iblk,num8)
            ibl7la = ibl7la + lensec(num)
            iblkp(ncalc)=iblk
         endif
c
c save ao population data on scratchfile
c
         if(nconf.ne.0)then
            if(ictype(ncalc).ne.3)
     & call caserr2('atomic pop. data incompatible with calc. type')
            iblk = ibl7la
            nw = (nconf-1)/nav + 1
            call wrt3(pop,npop,iblk,num8)
            call wrt3s(iconf,nw,num8)
            ibl7la = ibl7la + lensec(npop) + lensec(nw)
            icdata(2,ncalc)=nconf
            icdata(3,ncalc)=npop
            icdata(4,ncalc)=iblk
         endif
c
c save vdw data on scratchfile
c            
         if(nvdw.ne.0)then
            if(ictype(ncalc).ne.9.and.ictype(ncalc).ne.10)
     & call caserr2('radii data incompatible with calc. type')
            iblk = ibl7la
            nw = (nvdw-1)/nav + 1
            call wrt3(pop,nvdw,iblk,num8)
            call wrt3s(iconf,nw,num8)
            ibl7la = ibl7la + lensec(nvdw) + lensec(nw)
            icdata(1,ncalc)=nvdw
            icdata(2,ncalc)=iblk
         endif
c
c  set scale factor for potentials (see also surfin)
c
         if(.not.oscal.and.ictype(ncalc).eq.4)cscal(ncalc)=627.707d0
c
         jrec = jrec - 1
         return
      endif
      goto 10
      end
      function caltyp(index,imo)
      character caltyp*12
      if(index.eq.1)then
         caltyp = 'density     '
      else if(index.eq.2)then
         caltyp = 'mo          '
         write(caltyp(3:5),'(i3)')imo
      else if(index.eq.3)then
         caltyp = 'atom diff   '
      else if(index.eq.4)then
         caltyp = 'potential   '
      else if(index.eq.5)then
         caltyp = 'density grad'
      else if(index.eq.6)then
         caltyp = 'mo     grad '
         write(caltyp(3:5),'(i3)')imo
      else if(index.eq.7)then
         caltyp = 'combination'
      else if(index.eq.8)then
         caltyp = 'difference  '
      else if(index.eq.9)then
         caltyp = 'v.d. waals  '
      else if(index.eq.10)then
         caltyp = 'log vdw     '
      else if(index.eq.11)then
         caltyp = 'grad vdw    '
      else if(index.eq.12)then
         caltyp = 'grad log vdw'
      else if(index.eq.-1)then
         caltyp = 'grid list   '
      else
         call caserr2('bad calculation type in caltyp')
      endif
      return
      end
      subroutine center(maxap3,natoms,a,atmchg,v)
c
c     calculate the position of the center of charge and return it
c     in v.
c     when total charge=0, abs(chg) is used 
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension a(maxap3,3), atmchg(*), v(*)
c
      data dzero/0.0d0/
      data small/1.0d-6/
c
      do 20 i = 1 , 3
         v(i) = dzero
 20   continue
c
      ctot = 0.0d0
      do 25 iat = 1 , natoms
         ctot = ctot + atmchg(iat)
 25   continue
      oabs=(dabs(ctot).lt.small)
c
      totwt = dzero
      do 30 iat = 1 , natoms
         wt = atmchg(iat)
         if(oabs)wt = dabs(wt)
         totwt = totwt + wt
         v(1) = v(1) + wt*a(iat,1)
         v(2) = v(2) + wt*a(iat,2)
         v(3) = v(3) + wt*a(iat,3)
 30   continue
c
      v(1) = v(1)/totwt
      v(2) = v(2)/totwt
      v(3) = v(3)/totwt
      return
      end
      subroutine chekpp(maxap3,a,b,d,natoms,numatm,t)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      character *1 xrotax
INCLUDE(common/sizes)
c
c this routine compares the current orientation of the molecule
c with that of the previous point in a geometry optimization
c the axis are aligned with those of the previous point
c using the sum of distances**2 between the corresponding atoms
c in the two points as criterion.
c 
c the symmetry operations for the point group, as generated
c by ptgrp are used, together with rotations of 90 degrees
c about the cartesian axes
c the latter are required to cover the possibility that
c
c * two axes at 90 which are not symmetry related have been
c   swapped over
c
c * the direction of a Cn axis with respect to the molecule
c   has changed
      dimension a(maxap3,3),b(maxap3,3),t(3,3),d(maxap3,3)
c
INCLUDE(common/molsym)
INCLUDE(common/iofile)
INCLUDE(common/symtry)
INCLUDE(common/transf)
INCLUDE(common/frame)
c
      dimension xrotax(3)
      data dzero,done,two,four,small/0.0d0,1.0d0,2.0d0,4.0d0,1.0d-10/
      data xrotax/'x','y','z'/
c
      halfpi = two * datan(done)
      twopi = halfpi * four
c
      if ((prmoms(1)+prmoms(2)+prmoms(3)).ge.dzero) then
         distm = sumdst(maxap3,a,aprev,natoms)
         otran = .false.
         iaxm = 0
         itm = 0
c set up transformation tables
         call ptgrp(0)
         do 45 iax = 1,3
            theta = dzero
            do 44 iang = 1,3 
               theta = theta + halfpi
               call rotate(maxap3,a,d,numatm,t,iax,theta)
               do 43 it = 1 , nt
                  nn = 9*(it - 1)
                  do 50 i = 1,numatm
                     call lframe(d(i,1),d(i,2),d(i,3),
     &                      psmal, qsmal, rsmal )
                     call trans1(nn)
                     call rot
                     b(i,1) = pp
                     b(i,2) = qp
                     b(i,3) = rp
 50               continue
                  distr = sumdst(maxap3,b,aprev,natoms)
                  if(distr + small. le. distm) then
                     otran = .true.
                     iaxm = iax
                     thetam = theta
                     itm = it
                     distm = distr
                  endif
 43            continue
 44         continue
 45      continue
c         
         if (otran) then
            call rotate(maxap3,a,d,numatm,t,iaxm,thetam)
            nn = 9*(itm - 1)
            do 150 i = 1,numatm
               call lframe(d(i,1),d(i,2),d(i,3),
     &                  psmal, qsmal, rsmal )
               call trans1(nn)
               call rot
c               
               a(i,1) = pp
               a(i,2) = qp
               a(i,3) = rp
 150        continue
            if (iaxm.ne.0.and.itm.ne.1) then
               write(iwr,6010)itm,nint(360.0d0*thetam/twopi),
     +                        xrotax(iaxm)
            else if (iaxm.ne.0) then
               write(iwr,6011)nint(360.0d0*thetam/twopi),xrotax(iaxm)
            else
               write(iwr,6012)itm
            endif
         endif
      endif
c     
      call dcopy(3*maxap3,a,1,aprev,1)
c
      return
 6010 format (11x,60('*'),/11x,'a transformation of the molecule (',i2,
     +     ') together with a',/11x,'rotation of ',i3,
     +     ' degrees around the ',a1,' axis has been performed',/11x,
     +     'in order to align the axes',
     +     ' with those of the previous point',/11x,60('*'))
 6011 format (11x,60('*'),/11x,'a rotation of ',i3,
     +     ' degrees around the ',a1,' axis has been performed',/11x,
     +     'in order to align the axes',
     +     ' with those of the previous point',/11x,60('*'))
 6012 format (11x,60('*'),/11x,'a transformation of the molecule (',i2,
     +     ') has been performed',
     +     'in order to align the axes',
     +     ' with those of the previous point',/11x,60('*'))
      end
      subroutine chgmlt (icharg,multip,onel)
c
c
c ----------------------------------------------------------------------
c          this routine checks to be sure that the charge and
c     multiplicity specified are possible in the specified molecule.
c     systems with an even number of electrons, for instance, cannot
c     have an even multiplicity.
c ----------------------------------------------------------------------
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/czmat)
c
c                  first, compute the total nuclear charge.
c
      isum = 0
      do 20 i = 1 , nz
         if (ianz(i).gt.0) isum = isum + ianz(i)
 20   continue
c
c                  now, use this and the net electronic charge to
c                  compute the number of electrons.
c
      isum = isum - icharg
c
c                  then make sure that the parity of the result differs
c                  from the parity of the multiplicity.
c                  only perform this check if the total number
c                  of electrons has NOT been defined by elec directive
c
      if (.not.onel. and. mod(isum,2).eq.mod(multip,2)) then
         write (iwr,6010)
         write (iwr,6020) isum
         write (iwr,6030) (ianz(i),i=1,nz)
         call caserr2('inconsistent charge and mult specified')
c
         return
      else
         return
      end if
 6010 format ('  the specified charge and multiplicity are impossible',
     +        ' in this molecule.')
 6020 format (' the sum of atomic numbers is',i3,', nz is',i3)
 6030 format ('  atomic number vector:',20i3)
c
c                  print an error message and abort.
c
      end
      subroutine cirset(maxap3,natoms,a,atmchg,ixyz,nset,npop,
     $                  aset,numset)
c
c     a "circular-set" of atoms is hereby defined as those atoms
c     lying in a plane which have the same atomic number and
c     which are equidistant from some reference axis perpindicular
c     to the plane.  a proper rotation axis generates a circular-set
c     of atoms.
c
c     this routine searches for circular-sets of atoms.
c     ixyz is the cartesian reference axis.
c     nset(i) gives the number of the set which atom i belongs to.
c     set 0 is defined as the set of on-axis atoms.
c     npop(j) is the number of atoms in set j.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3), nset(*), npop(*), aset(maxap3,3), atmchg(*)
c
      data dzero/0.0d0/
c
      i2 = 1 + mod(ixyz,3)
      i3 = 1 + mod(i2,3)
c
c     aset(i,1):  atmchg(i) and a flag.
c     aset(i,2):  the projection of the i'th atom on the reference
c                 axis.
c     aset(i,3):  its distance from the reference axis.
c
      do 20 iat = 1 , natoms
         aset(iat,1) = atmchg(iat)
         aset(iat,2) = a(iat,ixyz)
         q2 = a(iat,i2)
         q3 = a(iat,i3)
         aset(iat,3) = dsqrt(q2*q2+q3*q3)
 20   continue
c
c     define set 0.
c
      do 30 iat = 1 , natoms
         if (dabs(aset(iat,3)).le.toler) then
            nset(iat) = 0
            aset(iat,1) = dzero
         end if
 30   continue
c
c     find the remaining sets.
c
      iattop = natoms - 1
      iset = 0
      do 50 iat = 1 , iattop
         if (aset(iat,1).ne.dzero) then
            iset = iset + 1
            nset(iat) = iset
            npop(iset) = 1
            an = aset(iat,1)
            ap = aset(iat,2)
            ad = aset(iat,3)
            aset(iat,1) = dzero
            j1 = iat + 1
            do 40 jat = j1 , natoms
               if (dabs(aset(jat,1)-an).le.toler2 .and. 
     +             dabs(aset(jat,2)-ap).le.toler .and. 
     +             dabs(aset(jat,3)-ad).le.toler) then
                  nset(jat) = iset
                  npop(iset) = npop(iset) + 1
                  aset(jat,1) = dzero
               end if
 40         continue
         end if
 50   continue
      numset = iset
c
c     restore aset(i,1).
c
      call dcopy(natoms,atmchg,1,aset(1,1),1)
      return
      end
      subroutine equiv(maxap3,a,b,atmchg,natoms,itst)
c
c     itst is set to 1 if the two molecular orientations in a and
c     in b are equivalent.  otherwise itst is set to 0.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3), b(maxap3,3), atmchg(*)
c
      do 40 iat = 1 , natoms
         do 30 jat = 1 , natoms
            if (dabs(atmchg(iat)-atmchg(jat)).le.toler2) then
               do 20 ixyz = 1 , 3
                  test = a(iat,ixyz) - b(jat,ixyz)
                  if (dabs(test).gt.toler) go to 30
 20            continue
               go to 40
            end if
 30      continue
         itst = 0
         return
 40   continue
      itst = 1
      return
      end
      subroutine fcmin(call)
      implicit REAL  (a-h,o-z)
c
c      fcm directive
c      fcm : read from current dumfile (pref mp2)
c      fcm ed4  : read from ed4 which starts at block 1
c      fcm ed4 5 : read from ed4 which starts at block 5
c      fcm ed3 block 5 : read from ed3 block 5 (you know where fcm is)
c      fcm unit7 : read from unit7
c      add mp2,scf or optimise for hessians from those
c      optimise is the hessian as gathered during the optimisation (or saddle)
c      .. as the latter is in a differenf format the section is remembered ..
c
INCLUDE(common/sizes)
INCLUDE(common/discc)
INCLUDE(common/work)
INCLUDE(common/iofile)
INCLUDE(common/cntl1)
INCLUDE(common/restrl)
INCLUDE(common/restar)
INCLUDE(common/restrz)
INCLUDE(common/restri)
INCLUDE(common/machin)
INCLUDE(common/czmat)
      character*(*) call
c
      logical exist
      character*8 filev,ztest,ztype
      dimension isecf(3)
c
      call secinf(iblk3,num3,dum,dum)
      ifcm = num3
      iblkfm =iblk3
      ofcm = .true.
      unit7 = .false.
      if (call.eq.'rdfcm') go to 50
c
      call inpa(filev)
      ifcm = -1
      if (filev.eq.'unit7') then
         unit7 = .true.
         return
      else if (filev.eq.' ') then
         ifcm = num3
         iblkf = iblk3
      else
         do i = 1 , maxlfn
            if (filev(1:4).eq.yed(i)) ifcm = i
         end do
         if (ifcm.lt.0) call caserr2('illegal unit in fcm directive')
         call inpa(ztest)
         if (ztest(1:4).eq.'bloc') then
            call inpi(iblfcm)
         else
            jrec = jrec - 1
            call inpi(iblkfm)
            if (iblkfm.le.0) iblkfm = 1
         end if
      end if
c
      call inpa(ztype)
c
c...  decide which section we require
c
50    isecf(2) = 0
      isecf(3) = 0
      if (ztype(1:3).eq.'mp2') then
         isecf(1) = 110
      else if (ztype(1:3).eq.'scf') then
         isecf(1) = 46
      else if (ztype(1:4).eq.'opti') then
         isecf(1) = 489
      else if (call.eq.'rdfcm') then
         ifcm = num3
         iblfcm = iblk3
         if (mp2) then
            isecf(1) = 110
            isecf(2) = 46
         else
            isecf(1) = 46
            isecf(2) = 110
         end if
         isecf(3) = 0
      else
c..      standard choice
         isecf(1) = 110
         isecf(2) = 46
         isecf(3) = 489
      end if
c
      call revind
      if (ifcm.ne.num3.or.iblkfm.ne.iblk3) call secini(iblkfm,ifcm)
c
c...  check for existing sections
c
      do i=1,3
         if (isecf(i).ne.0) then
            call secloc(isect(isecf(i)),exist,iblfcm)
            isecfcm = isecf(i)
            if (exist) go to 100
         end if
      end do
      if (call.eq.'rdfcm') then
         iblfcm = 0
         return
      else
         call caserr2('requested force constant matrix not present')
      end if
c
100   if (call.eq.'rdfcm') then
         if (i.eq.2) then
            if (isecf(1).eq.110) write(iwr,6130)
            if (isecf(1).eq.46)  write(iwr,6150)
         end if
         if (isecf(i).eq.110) write(iwr,6120)
         if (isecf(i).eq.46)  write(iwr,6140)
6120     format(/1x,'mp2 force constants restored from dumpfile')
6130     format(/1x,'no mp2 force constants present')
6140     format(/1x,'scf force constants restored from dumpfile')
6150     format(/1x,'no scf force constants present')
      else
         if (isecf(i).eq.110) write(iwr,6010)
         if (isecf(i).eq.46)  write(iwr,6020)
         if (isecf(i).eq.489) then 
            write(iwr,6030)
            iblfcm = iblfcm + lensec(mach(1)) + lensec(mach(10)) + 
     *                        2*lensec(nvar*200)
         end if
6010     format(/1x,'*****  using mp2 force constants *****'/)
6020     format(/1x,' ***** using scf force constants *****'/)
6030     format(/1x,' ***** using force constants from optimise *****'/)
      end if
c
      if (ifcm.ne.num3.or.iblkfm.ne.iblk3) call secini(iblk3,num3)
c
      return
      end
      subroutine filein(nfile,notape)
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension notape(*)
INCLUDE(common/sizes)
INCLUDE(common/work)
INCLUDE(common/discc)
c
      nfile = jump - 1
      if (nfile.le.0) call caserr2(
     +  'a file directive has invalid syntax')
      do 20 i = 1 , nfile
         call inpa4(ytest)
         isel = locatc(yed,maxlfn,ytest)
         if (isel.eq.0) then
            call caserr2('invalid ddname in a file directive')
         end if
         notape(i) = isel
 20   continue
c
      return
      end
      subroutine filmem(nfile,notape,maxset)
c
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension notape(*)
INCLUDE(common/sizes)
INCLUDE(common/work)
INCLUDE(common/discc)
      character*8 ztest,zz
c
c     first check if the block count has been specified
c
      call inpa4(ytest)
      notape(1) = 3
      isel = locatc(yed,maxlfn,ytest)
      i1 = jump
      if (isel.eq.0) then
       jrec = jrec - 1
       call inpa(ztest)
       call strtrm(ztest,ll)
       if (ztest(ll:ll).eq.'b') then
          if (ztest(ll-1:ll-1).eq.'m') then
             mul = 1000/4
          else if (ztest(ll-1:ll-1).eq.'g') then
             mul = 1000000/4
          else
             call caserr2('unknown unit in memory specification')
          end if
          zz = '        '
          zz(11-ll:) = ztest(1:ll-2)
          read(zz,'(i8)') maxset
          maxset = maxset*mul
       else
          jrec = jrec - 1
          call inpi(maxset)
       end if
       if(maxset.lt.0) maxset = 0
       i1 = i1 - 1
      else
       jrec = jrec - 1
      endif
      nfile = i1 - 1
c
      if (nfile.gt.1) then
       do 20 i = 2 , nfile
          call inpa4(ytest)
          isel = locatc(yed,maxlfn,ytest)
          if (isel.eq.0.or.isel.eq.3) then
             call caserr2('invalid ddname used with memory keyword')
          end if
          notape(i) = isel
 20    continue
      endif
c
      return
      end
      subroutine findc2(maxap3,a,b,aset,npop,nset,atmchg,natoms,itst)
c
c     this routine tests for a set of norder c2 axes perpindicular
c     to the principal (cartesian z assumed) symmetry axis.  if
c     found, one of the c2 axes is left coincident with the y
c     cartesian axis.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3), nset(*) , npop(*), aset(maxap3,3)
      dimension t(3,3),b(maxap3,3),atmchg(*)
c
      data half,done,two/0.5d0,1.0d0,2.0d0/
c
      numatm = natoms + 3
      halfpi = two*datan(done)
      pi = two*halfpi
c
      call cirset(maxap3,natoms,a,atmchg,3,nset,npop,aset,numset)
c
c     look for circular-sets in the xy plane.  a c2 axis must pass
c     through the point midway between any atom in the set and one
c     other atom in the set.
c
c     iattop = natoms - 1
c
      do 50 iset = 1 , numset
         do 20 iat = 1 , natoms
            if (nset(iat).eq.iset) go to 30
 20      continue
         go to 50
 30      if (dabs(aset(iat,2)).le.toler) then
            j1 = iat + 1
            do 40 jat = j1 , natoms
               if (nset(jat).eq.iset) then
                  p = (a(iat,1)+a(jat,1))*half
                  q = (a(iat,2)+a(jat,2))*half
                  theta = halfpi
                  if (dabs(q).gt.toler) theta = -datan(p/q)
                  call rotate(maxap3,a,b,numatm,t,3,theta)
                  call rotate(maxap3,b,aset,natoms,t,2,pi)
                  call equiv(maxap3,b,aset,atmchg,natoms,itst)
                  if (itst.ne.0) then
                     call movez(maxap3,b,a,numatm)
                     return
                  end if
               end if
 40         continue
         end if
 50   continue
c
c     pick an atom in one of the circular sets not in the xy plane.
c     a c2 axis must bisect the angle formed by the projection of the
c     reference atom in the xy plane and the projection of an atom
c     in the set opposed to the reference set.
c
      call cirset(maxap3,natoms,a,atmchg,3,nset,npop,aset,numset)
c     do 160 iset=1,numset
      iset = 1
      do 60 iat = 1 , natoms
         if (nset(iat).eq.iset) go to 70
 60   continue
      itst = 0
      return
 70   proi = aset(iat,2)
      ani = aset(iat,1)
      disi = aset(iat,3)
c     goto 180
c 160 continue
c     itst = 0
c     return
c 180 ri = a(iat,1)
      ri = a(iat,1)
      qi = a(iat,2)
      j1 = iset + 1
      do 100 jset = j1 , numset
         do 80 jat = 1 , natoms
            if (nset(jat).eq.jset) go to 90
 80      continue
         itst = 0
         return
 90      if (dabs(proi+aset(jat,2)).le.toler .and. dabs(ani-aset(jat,1))
     +       .le.toler2 .and. dabs(disi-aset(jat,3)).le.toler) go to 110
 100  continue
      itst = 0
      return
 110  do 120 jat = 1 , natoms
         if (nset(jat).eq.jset) then
            p = (ri+a(jat,1))*half
            q = (qi+a(jat,2))*half
            theta = halfpi
            if (dabs(q).gt.toler2) theta = -datan(p/q)
            call rotate(maxap3,a,b,numatm,t,3,theta)
            call rotate(maxap3,b,aset,natoms,t,2,pi)
            call equiv(maxap3,b,aset,atmchg,natoms,itst)
            if (itst.ne.0) then
               call movez(maxap3,b,a,numatm)
               return
            end if
         end if
 120  continue
      itst = 0
      return
      end
_EXTRACT(findcn,_AND(hp800,i8))
      subroutine findcn(maxap3,natoms,a,b,d,atmchg,npop,nset,ixyz,
     *norder)
c
c     this routine finds the highest order proper axis which is
c     coincident with cartesian axis ixyz.
c
c     an axis of order n will produce a number of "circular-sets" of
c     equivalent atoms (circular-set is more fully defined in
c     routine cirset).  furthermore, the population of each of
c     these sets must be an integer multiple of n.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension npop(*),a(maxap3,3),b(maxap3,3),d(maxap3,3)
      dimension atmchg(*) ,nset(*)
      dimension t(3,3)
c
      data done,eight/1.0d0,8.0d0/
c
      twopi = eight*datan(done)
c
c     cirset determines the populations of all circular sets which
c     are present.
c
      call cirset(maxap3,natoms,a,atmchg,ixyz,nset,npop,d,numset)
      maxmul = 1
      do 20 i = 1 , numset
         maxmul = max(maxmul,npop(i))
 20   continue
      do 40 i = 1 , maxmul
c
c     test the common multiples of the elements of npop in descending
c     order as possible orders for an axis of symetry.
c
         multst = maxmul - i + 1
         do 30 j = 1 , numset
            if (mod(npop(j),multst).ne.0) go to 40
 30      continue
         theta = twopi/dfloat(multst)
         call rotate(maxap3,a,b,natoms,t,ixyz,theta)
         call equiv(maxap3,a,b,atmchg,natoms,itst)
         if (itst.ne.0) then
            norder = multst
            return
         end if
 40   continue
      norder = 1
      return
      end
_ENDEXTRACT
      subroutine findv(maxap3,a,b,d,natoms,npop,nset,atmchg,itst)
c
c     this routine tests for a set of norder vertical planes.  it
c     is assumed that the principal axis is aligned with the
c     the cartesian z axis.  if a set of planes is found, it leaves
c     one of them coincident with the yz cartesian plane.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3), nset(*),b(maxap3,3),d(maxap3,3)
      dimension t(3,3),atmchg(*) , npop(*)
c
      data half,done,two/0.5d0,1.0d0,2.0d0/
c
      numatm = natoms + 3
      halfpi = two*datan(done)
c
c     look for a circular-set of atoms.  a vertical mirror must
c     pass through the point midway between any atom in the set
c     and one other atom in the set.
c
      call cirset(maxap3,natoms,a,atmchg,3,nset,npop,d,numset)
c
      iset = 1
      iattop = natoms - 1
      do 20 iat = 1 , iattop
         if (nset(iat).eq.iset) go to 30
 20   continue
      itst = 0
      return
 30   j1 = iat + 1
      do 40 jat = j1 , natoms
         if (nset(jat).eq.iset) then
            setx = (a(iat,1)+a(jat,1))*half
            sety = (a(iat,2)+a(jat,2))*half
            if (dabs(setx).le.toler .and. dabs(sety).le.toler) then
               setx = half*a(jat,1)
               sety = half*a(jat,2)
            end if
            theta = halfpi
            if (dabs(sety).gt.toler) theta = -datan(setx/sety)
            call rotate(maxap3,a,b,numatm,t,3,theta)
            call reflct(maxap3,b,d,natoms,t,1)
            call equiv(maxap3,b,d,atmchg,natoms,itst)
            if (itst.ne.0) then
               call movez(maxap3,b,a,numatm)
               itst = 1
               return
            end if
         end if
 40   continue
      itst = 0
      return
      end
      subroutine formbg(maxnz,nz,ianz,iz,bl,alpha,beta,nparm,
     $                  b,ib,g,
     $                  cxm,cz,cc,ll,mm,idump)
c
c
c
c***********************************************************************
c     given a z-matrix, this routine will form the wilson b and g
c     matrices.  these may be subsequently used to transform
c     cartesian first derivatives to internal coordinates.
c
c     arguments:
c
c     maxnz  ... leading dimension of z-matrix.
c     nz     ... number of entries in the z-matrix.
c     ianz   ... vector of length nz containing integer atomic
c                numbers.
c     iz     ... integer connectivity matrix of dimension
c                (maxnz*4).
c     bl     ... vector of length nz containing bond-lengths.
c     alpha  ... vector of length nz containing first angles.
c     beta   ... vector of length nz containing second angles.
c     nparm  ... number of degrees of freedom (3*nz-6).
c     b      ... output b-matrix (3*4*nparm).
c     ib     ... integer portion of b-matrix (4*nparm).
c     g      ... output g-matrix (nparm*nparm).
c     xm     ... scratch array of length (nz*5).
c     cz     ... scratch array of length (3*nz).
c     cc     ... scratch array of length (3*natoms).
c     ll     ... integer scratch array of
c                length  max(nparm,nz).
c     mm     ... integer scratch array of length (nparm).
c     idump  ... dump flag.
c***********************************************************************
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/iofile)
      dimension ianz(*),iz(maxnz,*),bl(*),alpha(*),beta(*)
      dimension b(3,4,nparm),ib(4,nparm),g(*)
      dimension cxm(nz,*),cz(*),cc(*),ll(*),mm(*)
c
      data dzero/0.d0/,done/1.d0/
      data cutoff/1.0d-30/
c
c     ******************************************************************
c     initialization.
c     ******************************************************************
c     determine the full coordinate list (dummies included), given
c     the z-matrix.
c
      call stocxz(maxnz,nz,ianz,iz,bl,alpha,beta,.false.,nattmp,ll,cc,
     +       cz,cxm(1,1),cxm(1,2),cxm(1,3),cxm(1,4),cxm(1,5),iwr,oerro)
c
c     prepare xm.
c
      do 30 i = 1 , nz
         do 20 j = 1 , 3
            cxm(i,j) = done
 20      continue
 30   continue
      cxm(1,1) = dzero
      cxm(1,2) = dzero
      cxm(1,3) = dzero
      cxm(2,1) = dzero
      cxm(2,2) = dzero
      cxm(3,2) = dzero
c
c     ******************************************************************
c     form the b-matrix.
c     ******************************************************************
c
      do 60 i = 1 , nparm
         do 50 k = 1 , 4
            ib(k,i) = 0
            do 40 j = 1 , 3
               b(j,k,i) = dzero
 40         continue
 50      continue
 60   continue
c
c     loop over all rows of the z-matrix.
c
      do 130 i = 2 , nz
c
c     bond stretch.
c
         call str(i-1,i,iz(i,1),b,ib,cz)
         if (bl(i).lt.dzero) then
            do 80 j = 1 , 3
               do 70 k = 1 , 2
                  b(j,k,i-1) = -b(j,k,i-1)
 70            continue
 80         continue
         end if
c
         if (i.gt.2) then
            iparm = nz - 3 + i
c
c     angle bend  (alpha).
c
            call bend(iparm,i,iz(i,1),iz(i,2),b,ib,cz)
            if (alpha(i).lt.dzero) then
               do 100 j = 1 , 3
                  do 90 k = 1 , 3
                     b(j,k,iparm) = -b(j,k,iparm)
 90               continue
 100           continue
            end if
c
            if (i.gt.3) then
               iparm = nz + nz - 6 + i
               if (iz(i,4).eq.0) then
c
c     torsion  (beta).
c
                  call tors(iparm,i,iz(i,1),iz(i,2),iz(i,3),b,ib,cz)
               else
c
c     angle bend  (beta).
c
                  call bend(iparm,i,iz(i,1),iz(i,3),b,ib,cz)
                  if (beta(i).lt.dzero) then
                     do 120 j = 1 , 3
                        do 110 k = 1 , 3
                           b(j,k,iparm) = -b(j,k,iparm)
 110                    continue
 120                 continue
                  end if
               end if
            end if
         end if
c
 130  continue
c
c     apply mask to b.
c
      do 160 i = 1 , nparm
         do 150 i1 = 1 , 4
            ibi = ib(i1,i)
            if (ibi.ne.0) then
               do 140 l = 1 , 3
                  b(l,i1,i) = b(l,i1,i)*cxm(ibi,l)
 140           continue
            end if
 150     continue
 160  continue
c
c     possibly print the b and ib.
c
      if (idump.gt.1) then
         write (iwr,6020)
         call imatout(ib,4,nparm,4,nparm)
         write (iwr,6030)
         call matout(b,12,nparm,12,nparm)
      end if
c
c     ******************************************************************
c     form g-matrix.
c     ******************************************************************
c
_IF1(c)cdir$ list
_IF1(c)cdir$ novector
      do 210 i = 1 , nparm
         do 200 j = 1 , i
            r = dzero
            do 190 i1 = 1 , 4
               ibi = ib(i1,i)
               if (ibi.ne.0) then
                  do 180 j1 = 1 , 4
                     if (ibi.eq.ib(j1,j)) then
                        do 170 l = 1 , 3
                           r = r + b(l,i1,i)*b(l,j1,j)
 170                    continue
                     end if
 180              continue
               end if
 190        continue
            in = j + nparm*(i-1)
            g(in) = r
            in = i + nparm*(j-1)
            g(in) = r
 200     continue
 210  continue
_IF1(c)cdir$ vector
_IF1(c)cdir$ nolist
c
c     possibly print the g-matrix.
c
      if (idump.gt.1) then
         write (iwr,6040)
         call matout(g,nparm,nparm,nparm,nparm)
      end if
c
c     form fi=g(-1)*b*fx
c
_IFN1(c)      call minvrt(g,nparm,r,ll,mm)
_IF1(c)      call minv(g,nparm,nparm,ll,r,1.0d-100,0,1)
c
c     possibly print g**(-1).
c
      if (idump.gt.1) then
         write (iwr,6050)
c
c     call error(613)   dummied jvl nov86  advice mfg
c
         call matout(g,nparm,nparm,nparm,nparm)
      end if
      if (dabs(r).le.cutoff) write (iwr,6010) r
      return
c
 6010 format ('  ***** warning *****'/
     +        '  g-matrix is almost singular in formbg,  det=',
     +        e20.13/'  check z-matrix variables for linear dependance '
     +        /'  *******************'//)
 6020 format ('  ib matrix')
 6030 format ('  b matrix')
 6040 format ('  g matrix')
 6050 format ('  g-inverse')
c
      end
      subroutine formbgxz(maxnz,nz,ianz,iz,bl,alpha,beta,nparm,nparmz,
     $                  b,ib,g,gcart,igcart,gdum,gvec,geig,
     $                  cxm,cz,cc,ll,mm,idump,ifail)
c
c
c
c***********************************************************************
c     given a z-matrix, this routine will form the wilson b and g
c     matrices.  these may be subsequently used to transform
c     cartesian first derivatives to internal coordinates.
c
c     arguments:                                   Z-atom        X-atom
c
c     maxnz  ... leading dimension of z-matrix.
c     nz     ... number of entries in the z-matrix.
c     ianz   ... vector of length nz containing 
c                integer atomic numbers.
c     iz     ... integer connectivity matrix of 
c                dimension (maxnz*4).
c     bl     ... vector of length nz containing    bond-lengths.    Z
c     alpha  ... vector of length nz containing    first angles.    X
c     beta   ... vector of length nz containing    second angles.   Y
c     nparm  ... number of degrees of freedom (3*nz-6).
c     b      ... output b-matrix (3*4*nparm).
c     ib     ... integer portion of b-matrix (4*nparm).
c     g      ... output g-matrix (nparm*nparm).
c     xm     ... scratch array of length (nz*5).
c     cz     ... scratch array of length (3*nz).
c     cc     ... scratch array of length (3*natoms).
c     ll     ... integer scratch array of
c                length  max(nparm,nz).
c     mm     ... integer scratch array of length (nparm).
c     idump  ... dump flag.
c***********************************************************************
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/iofile)
      dimension ianz(*),iz(maxnz,*),bl(*),alpha(*),beta(*)
      dimension b(3,4,nparm),ib(4,nparm),g(*),gcart(*),igcart(*)
      dimension gdum(*),gvec(*),geig(*)
      dimension cxm(nz,*),cz(*),cc(*),ll(*),mm(*)
c
      dimension iky(maxnz),ilifq(maxnz)
c
      data dzero/0.d0/,done/1.d0/
      data cutoff/1.0d-30/

c
 2001 format('  ***** warning *****'/
     $       '  g-matrix is almost singular in formbgxz,  det=',e20.13/
     $       '  check z-matrix variables for linear dependance '/
     $       '  *******************'//)
 2003 format('  ib matrix')
 2004 format('  b matrix')
 2005 format('  g matrix')
 2006 format('  g-inverse')
c

      ocart(i) = iz(i,1) .lt. 0
c
c     ******************************************************************
c     initialization.
c     ******************************************************************
c     determine the full coordinate list (dummies included), given
c     the z-matrix.
c

      ifail = 0

      call stocxz(maxnz,nz,ianz,iz,bl,alpha,beta,.false.,
     $          nattmp,ll,cc,cz,cxm(1,1),cxm(1,2),cxm(1,3),cxm(1,4),
     $          cxm(1,5),iwr,oerro)
c
c     prepare xm.
c
      do 10 i=1,nz
      do 10 j=1,3
   10 cxm(i,j)=done
      cxm(1,1)=dzero
      cxm(1,2)=dzero
      cxm(1,3)=dzero
      cxm(2,1)=dzero
      cxm(2,2)=dzero
      cxm(3,2)=dzero

cc      write(6,*)'cartesian coordinates'
cc      do i=1,nz
cc         write(6,'(1x,i3,3f10.4)')ianz(i),(cz(3*(i-1)+j),j=1,3)
cc      enddo
c
c     ******************************************************************
c     form the b-matrix.
c     ******************************************************************
c
      do i=1,nparm
         do  k=1,4
            ib(k,i)=0
            do  j=1,3
               b(j,k,i)=dzero
            enddo
         enddo
      enddo
c
c     loop over all rows of the z-matrix.
c


      do i=2,nz

         if(ocart(i))then
c
c    cartesian atom
c            
            iparm = i-1
            ib(1,iparm) = i
            b(3,1,iparm) = 1.0d0

            if(i.ge.3)then
               iparm=nz-3+i
               ib(1,iparm) = i
               b(1,1,iparm) = 1.0d0
            endif

            if(i.ge.4)then
               iparm=nz+nz-6+i
               ib(1,iparm) = i
               b(2,1,iparm) = 1.0d0
            endif

         else
c
c     bond stretch.
c
         call str(i-1,i,iz(i,1),b,ib,cz)
         if(bl(i).lt.dzero) then
            do j=1,3
               do k=1,2
                  b(j,k,i-1)=-b(j,k,i-1)
               enddo
            enddo
         endif
c
         if(i.le.2) go to 20
         iparm=nz-3+i
c
c     angle bend  (alpha).
c
         call bend(iparm,i,iz(i,1),iz(i,2),b,ib,cz)
         if(alpha(i).lt.dzero) then
            do j=1,3
               do k=1,3
                  b(j,k,iparm)=-b(j,k,iparm)
               enddo
            enddo
         endif

         if(i.le.3) go to 20

         iparm=nz+nz-6+i
         if(iz(i,4).eq.0) then
c
c     torsion  (beta).
c
            call tors(iparm,i,iz(i,1),iz(i,2),iz(i,3),b,ib,cz)
         else
c
c     angle bend  (beta).
c
            call bend(iparm,i,iz(i,1),iz(i,3),b,ib,cz)
            if(beta(i).lt.dzero)then
               do j=1,3
                  do k=1,3
                     b(j,k,iparm)=-b(j,k,iparm)
                  enddo
               enddo
            endif
         endif
 20      continue
      endif
      enddo

      if(idump.gt.2)then
         write(iwr,*)'before mask'
         write(iwr,2003)
CC         call imatout(ib,4,nparm,4,nparm)
         write(iwr,2004)
         call matout(b,12,nparm,12,nparm)
      endif

c
c     apply mask to b.
c
      do i=1,nparm
         do i1=1,4
            ibi=ib(i1,i)
            if(ibi.ne.0)then
               do l=1,3
                  b(l,i1,i)=b(l,i1,i)*cxm(ibi,l)
               enddo
            endif
         enddo
      enddo
c
c     possibly print the b and ib.
c


      if(idump.gt.1)then
         write(iwr,2003)
CC         call imatout(ib,4,nparm,4,nparm)
         write(iwr,2004)
         call matout(b,12,nparm,12,nparm)
      endif
c
c     ******************************************************************
c     form g-matrix.
c     ******************************************************************
c
      do i=1,nparm
         do j=1,i
            r=dzero
            do i1=1,4
               ibi=ib(i1,i)
               if(ibi.ne.0) then
                  do j1=1,4
                     if(ibi.eq.ib(j1,j)) then
                        do l=1,3
                           r=r+b(l,i1,i)*b(l,j1,j)
                        enddo
                     endif
                  enddo
               endif
            enddo
            if( (igcart(i).ne.-1).and.
     &           (igcart(j).ne.-1)) then
c
c store in dense part
c
               in=igcart(j)+nparmz*(igcart(i)-1)
               g(in)=r
               in=igcart(i)+nparmz*(igcart(j)-1)
               g(in)=r

            else if (i .eq. j) then
c
c diagonal cartesian part 
c
               gcart(i) = r
            else
               if(r.gt.1.0d-10)then
                  write(6,*)'reject g',i,j,r
                  ifail = 1
               endif
            endif
         enddo
      enddo

      if(ifail.eq.1)return
c
c     store g-matrix for possible analysis
c
      do i = 1, nparmz
        iky(i)   = i*(i-1)/2
        ilifq(i) = (i-1)*nparmz
        do j = 1, i
          gdum(iky(i)+j) = g(ilifq(i)+j)
        enddo
      enddo
c
c     possibly print the g-matrix.
c
      if(idump.gt.1)then
         write(iwr,2005)
         call matout(g,nparm,nparm,nparm,nparm)
      endif
c
c     form fi=g(-1)*b*fx
c

c
c     invert simple cartesian (diagonal) part
c
      do i = 1,nparm
         if(igcart(i).eq.-1)then
            gcart(i) = 1.0d0 / gcart(i)
         endif
      enddo
c
c     invert the internal coordinate part
c
      r = 1.0d0
      if(nparmz.gt.0)then
         call minvrt(g,nparmz,r,ll,mm)
      endif
c
c     possibly print g**(-1).
c
      if(idump.gt.1)then
         write(iwr,2006)
         call matout(g,nparmz,nparmz,nparmz,nparmz)
      endif
c
c     jacobi may ne parallel => all must do this
c
      if(dabs(r) .le. cutoff)then
        write(iwr,2001)r
        call jacobi(gdum,iky,nparmz,gvec,ilifq,nparmz,geig,2,2,1.0d-10)
        ncol = min(10,nparmz)
        call prevg(gvec,geig,ncol,nparmz,nparmz)
      endif
c
      return
c
      end
      subroutine frecky
      implicit REAL  (a-h,o-z)
c     process frequency directive
INCLUDE(common/work)
INCLUDE(common/iofile)
INCLUDE(common/rtdata)
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
c
INCLUDE(common/qercmx)
INCLUDE(common/qercom)
      dimension ac6(6)
      character *8 ztext,ac6
      data ac6/'c6','c7','c8','c9','c10','cn'/
      data pi/3.14159265358979d0/
c
      call inpi(nfreq)
      ifreq = 0
      nfreq = min(nfreq,30)
      call inpi(npole)
      call inpi(ic6)
      nc6 = 0
      if (ic6.eq.0) go to 120
      call inpi(nc6)
      nc6 = min(nc6,nfreq)
      if (ic6.eq.1) nc6 = min(nc6,18)
      ng2 = nc6/2
      nc6 = ng2*2
      call inpf(w0)
      call vclr(freq,1,nc6)
      write (iwr,6010) nc6 , ic6 , w0
      go to (20,40) , ic6
c...  gauss-legendre using omega=w0 (1+t)/(1-t)
 20   do 30 i1 = 1 , ng2
         i2 = nc6 + 1 - i1
         zz = dsqrt(rlow(i1+ipoint(ng2)))
         freq(i1) = -(w0*(1.0d0-zz)/(1.0d0+zz))**2
         freq(i2) = -(w0*(1.0d0+zz)/(1.0d0-zz))**2
 30   continue
      go to 60
c
c...  meath method - midpoint formula with omega=w0 tan t
 40   do 50 i = 1 , nc6
         freq(i) = -(w0*dtan(dfloat(2*i-1)*pi/(dfloat(4*nc6))))**2
 50   continue
c
 60   if (jump.le.6) go to 120
c
c
      write (iwr,6020)
      do 70 n = 1 , 30
         oc6(n) = .false.
 70   continue
c
c
 80   call inpa(ztext)
      do 90 m = 1 , 5
         if (ztext.eq.ac6(m)) then
            oc6(m+5) = .true.
            write (iwr,6030) ac6(m)
            go to 110
         end if
 90   continue
      if (ztext.eq.ac6(6)) then
         call inpi(nc6min)
         call inpi(nc6max)
         do 100 nn = nc6min , nc6max
            oc6(nn) = .true.
 100     continue
      end if
 110  if (jrec.lt.jump) go to 80
c
c
 120  i = nc6
 130  if (i.lt.nfreq) then
         call input
         do 140 j = 1 , jump
            i = i + 1
            call inpf(freq(i))
 140     continue
         go to 130
      else
         write (iwr,6040) nfreq , npole , (freq(j),j=1,nfreq)
         return
      end if
 6010 format (/1x,'first',i3,' frequencies to be taken at',
     +        ' quadrature points using formula number',
     +        i3/' with a transformation factor of',f20.7,' hartree')
 6020 format (//1x,'dispersion coefficients')
 6030 format (10x,a4)
 6040 format (//1x,'number of freqencies',i5/1x,'number of poles ',
     +        i5//1x,'squares of frequencies'/(5x,6f16.8))
      end
      subroutine fzprnt(maxnz,nz,ianz,iz,f,iout)
c
c
c***********************************************************************
c     routine to print the internal coordinate forces in a
c     z-matrix like manner.  this routine produces output very
c     similar to zprint, but differs in the
c     following:  1. formats produce more significant figures;
c     2. knows how to get forces from a single linear array.
c
c     arguments:
c
c     maxnz  ... maximum number of z-cards.
c     nz     ... number of lines in the z-matrix.
c
c     ianz   ... array of length nz containing the atomic numbers
c                of the nz centers.
c     iz     ... the integer connectivity information associated
c                with the z-matrix.
c     f      ... array containing the internal-coordinate forces,
c                stored in the same arrangement that variables
c                are numbered in a z-matrix.
c     iout   ... fortran logical unit to receive the output.
c***********************************************************************
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character * 2 iel
c
      dimension ianz(*),iz(maxnz,*),f(*)
      dimension iel(105)
c
      data iel/'x ', 'bq',
     $         'h ', 'he',
     $         'li', 'be', 'b ', 'c ', 'n ', 'o ', 'f ', 'ne',
     $         'na', 'mg', 'al', 'si', 'p ', 's ', 'cl', 'ar',
     $         'k ', 'ca',
     $                     'sc', 'ti', 'v ', 'cr', 'mn',
     $                     'fe', 'co', 'ni', 'cu', 'zn',
     $                     'ga', 'ge', 'as', 'se', 'br', 'kr',
     $ 'rb','sr','y ','zr','nb','mo','tc','ru','rh','pd','ag','cd',
     $ 'in','sn','sb','te','i ','xe','cs','ba','la','ce','pr','nd',
     $ 'pm','sm','eu','gd','tb','dy','ho','er','tm','yb','lu','hf',
     $ 'ta','w ','re','os','ir','pt','au','hg','tl','pb','bi','po',
     $ 'at','rn','fr','ra','ac','th','pa','u ','np','pu','am','cm',
     $ 'bk','cf','es','fm','md','no','lw'   /
c
c
c
      write (iout,6020)
      write (iout,6030)
      write (iout,6010)
c
c                                     first card.
      idx = ianz(1) + 2
      if (ianz(1).lt.0) then
         icent = 0
         write (iout,6050) iel(idx)
      else
         icent = 1
         write (iout,6040) icent , iel(idx)
      end if
      if (nz.ne.1) then
c
c                                     second card.
         np1 = 1
         idx = ianz(2) + 2
         if (ianz(2).lt.0) then
            write (iout,6070) iel(idx) , iz(2,1) , f(1) , np1
         else
            icent = icent + 1
            write (iout,6060) icent , iel(idx) , iz(2,1) , f(1) , np1
         end if
c
c                                      third card.
         if (nz.ne.2) then
            np1 = 2
            np2 = nz
            idx = ianz(3) + 2
            if (ianz(3).lt.0) then
               write (iout,6090) iel(idx) , iz(3,1) , f(2) , np1 ,
     +                           iz(3,2) , f(nz) , np2
            else
               icent = icent + 1
               write (iout,6080) icent , iel(idx) , iz(3,1) , f(2) ,
     +                           np1 , iz(3,2) , f(nz) , np2
            end if
c
c                                       cards 4 through nz.
            if (nz.ne.3) then
               do 20 icard = 4 , nz
                  np1 = icard - 1
                  np2 = nz + icard - 3
                  np3 = nz*2 + icard - 6
                  idx = ianz(icard) + 2
                  if (ianz(icard).lt.0) then
                     write (iout,6110) iel(idx) , iz(icard,1) , f(np1) ,
     +                                 np1 , iz(icard,2) , f(np2) ,
     +                                 np2 , iz(icard,3) , f(np3) ,
     +                                 np3 , iz(icard,4)
                  else
                     icent = icent + 1
                     write (iout,6100) icent , iel(idx) , iz(icard,1) ,
     +                                 f(np1) , np1 , iz(icard,2) ,
     +                                 f(np2) , np2 , iz(icard,3) ,
     +                                 f(np3) , np3 , iz(icard,4)
                  end if
 20            continue
            end if
         end if
      end if
      write (iout,6020)
c
c     return to caller.
c
      return
 6010 format (1x,72('-'))
 6020 format (1x,72('='))
 6030 format (20x,'internal coordinate forces (hartrees/bohr or ',
     +        '/radian)'/1x,'cent atom n1',6x,'length',6x,'n2',6x,
     +        'alpha',7x,'n3',7x,'beta',7x,' j')
 6040 format (1x,i2,3x,a2)
 6050 format (1x,5x,a2)
 6060 format (1x,i2,3x,a2,2x,i3,1x,f10.6,' (',i3,')')
 6070 format (1x,5x,a2,2x,i3,1x,f10.6,' (',i3,')')
 6080 format (1x,i2,3x,a2,2x,i3,1x,f10.6,' (',i3,')',1x,i2,1x,f10.6,
     +        ' (',i3,')')
 6090 format (1x,5x,a2,2x,i3,1x,f10.6,' (',i3,')',1x,i2,1x,f10.6,' (',
     +        i3,')')
 6100 format (1x,i2,3x,a2,2x,i3,1x,f10.6,' (',i3,')',1x,i2,1x,f10.6,
     +        ' (',i3,')',1x,i2,1x,f10.6,' (',i3,')',i3)
 6110 format (1x,5x,a2,2x,i3,1x,f10.6,' (',i3,')',1x,i2,1x,f10.6,' (',
     +        i3,')',1x,i2,1x,f10.6,' (',i3,')',i3)
c
      end
      subroutine fzprntxz(maxnz,nz,ianz,iz,f,iout)
c
c
c***********************************************************************
c     routine to print the internal coordinate forces in a
c     z-matrix like manner.  this routine produces output very
c     similar to its kissin' cousin zprint, but differs in the
c     following:  1. formats produce more significant figures;
c     2. knows how to get forces from a single linear array.
c
c     arguments:
c
c     maxnz  ... maximum number of z-cards.
c     nz     ... number of lines in the z-matrix.
c
c     ianz   ... array of length nz containing the atomic numbers
c                of the nz centers.
c     iz     ... the integer connectivity information associated
c                with the z-matrix.
c     f      ... array containing the internal-coordinate forces,
c                stored in the same arrangement that variables
c                are numbered in a z-matrix.
c     iout   ... fortran logical unit to receive the output.
c***********************************************************************
c
      implicit REAL (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character * 2 iel
c
      dimension ianz(*),iz(maxnz,*),f(*)
      dimension iel(105)
c
      data iel/'x ', 'bq',
     $         'h ', 'he',
     $         'li', 'be', 'b ', 'c ', 'n ', 'o ', 'f ', 'ne',
     $         'na', 'mg', 'al', 'si', 'p ', 's ', 'cl', 'ar',
     $         'k ', 'ca',
     $                     'sc', 'ti', 'v ', 'cr', 'mn',
     $                     'fe', 'co', 'ni', 'cu', 'zn',
     $                     'ga', 'ge', 'as', 'se', 'br', 'kr',
     $ 'rb','sr','y ','zr','nb','mo','tc','ru','rh','pd','ag','cd',
     $ 'in','sn','sb','te','i ','xe','cs','ba','la','ce','pr','nd',
     $ 'pm','sm','eu','gd','tb','dy','ho','er','tm','yb','lu','hf',
     $ 'ta','w ','re','os','ir','pt','au','hg','tl','pb','bi','po',
     $ 'at','rn','fr','ra','ac','th','pa','u ','np','pu','am','cm',
     $ 'bk','cf','es','fm','md','no','lw'   /

 1040 format(1x,72('-'))
 1060 format(1x,72('='))
 1050 format(20x,'internal coordinate forces (hartrees/bohr or ',
     $              '/radian)'
     $      /1x,'cent atom  n1',6x,'length',7x,'n2',6x,'alpha',8x,'n3',
     $          7x,'beta',7x,' j')
 1110 format(1x,i3,3x,a2)
 1120 format(1x,   6x,a2)
 1210 format(1x,i3,3x,a2,2x,i3,1x,f10.6,' (',i4,')')
 1220 format(1x,   6x,a2,2x,i3,1x,f10.6,' (',i4,')')
 1310 format(1x,i3,3x,a2,2x,i3,1x,f10.6,' (',i4,')',
     $       1x,i3,1x,f10.6,' (',i4,')')
 1320 format(1x,   6x,a2,2x,i3,1x,f10.6,' (',i4,')',
     $       1x,i3,1x,f10.6,' (',i4,')')
 1410 format(1x,i3,3x,a2,2x,i3,1x,f10.6,' (',i4,')',
     $       1x,i3,1x,f10.6,' (',i4,')',1x,i3,1x,f10.6,' (',i4,')',
     $       i3)
 1420 format(1x,   6x,a2,2x,i3,1x,f10.6,' (',i4,')',
     $       1x,i3,1x,f10.6,' (',i4,')',1x,i3,1x,f10.6,' (',i4,')',
     $       i3)

 1510 format(1x,i3,3x,a2,
     &     2x,'  x',1x,f10.6,' (',i4,')',
     &     1x,'  y',1x,f10.6,' (',i4,')',
     &     1x,'  z',1x,f10.6,' (',i4,')')

 1520 format(1x,   6x,a2,
     &     2x,'  x',1x,f10.6,' (',i4,')',
     $     1x,'  y',1x,f10.6,' (',i4,')',
     &     1x,'  z',1x,f10.6,' (',i4,')')
c
      ocart(i) = iz(i,1) .lt. 0
c
      write (iout,1060)
      write (iout,1050)
      write (iout,1040)
c
c                                     first card.
      idx = ianz(1) + 2
      if (ianz(1) .ge. 0) then
         icent = 1
         if(ocart(1))then
            write(iout,1510) icent, iel(idx), 
     &           0.0, 0, 0.0 ,0 ,0.0, 0
         else
            write (iout,1110) icent,iel(idx)
         endif
      else
         icent = 0
         if(ocart(1))then
            write(iout,1520)        iel(idx), 
     &           0.0, 0, 0.0 ,0 ,0.0, 0
         else
            write (iout,1120)       iel(idx)
         endif
      endif
      if (nz .eq. 1) goto 225
c
c                                     second card.
      np1 = 1
      idx = ianz(2) + 2
      if (ianz(2) .ge. 0) then
         icent = icent + 1
         if(ocart(2))then
            write(iout,1510) icent, iel(idx), 
     &           0.0, 0, 0.0 ,0 ,f(1), np1
         else
            write (iout,1210) icent,iel(idx),iz(2,1),f(1),np1
         endif
      else
         if(ocart(2))then
            write(iout,1520)        iel(idx), 
     &           0.0, 0, 0.0 ,0 ,f(1), np1
         else
            write (iout,1220)       iel(idx),iz(2,1),f(1),np1
         endif
      endif
c
c                                      third card.
      if (nz .eq. 2) goto 225
      np1 = 2
      np2 = nz
      idx = ianz(3) + 2
      if (ianz(3) .ge. 0) then
         icent = icent + 1

         if(ocart(3))then
            write(iout,1510) icent, iel(idx), 
     &           f(nz), np2, 0.0 ,0 ,f(2), np1
         else
            write (iout,1310) icent,iel(idx),iz(3,1),f(2),np1,iz(3,2),
     $           f(nz),np2
         endif

      else
         if(ocart(3))then
            write(iout,1520)        iel(idx), 
     &           f(nz), np2, 0.0 ,0 ,f(2), np1
         else
            write (iout,1320)       iel(idx),iz(3,1),f(2),np1,iz(3,2),
     $           f(nz),np2
         endif
      endif
c
c                                       cards 4 through nz.
      if (nz .eq. 3) goto 225
      do 200 icard=4,nz
         np1 = icard - 1
         np2 = nz + icard - 3
         np3 = nz*2 + icard - 6
         idx = ianz(icard) + 2
         if (ianz(icard) .ge. 0) then
            icent = icent + 1
            if(ocart(icard))then
               write(iout,1510)icent, iel(idx), 
     &              f(np2), np2, f(np3) ,np3 ,f(np1), np1
            else
               write (iout,1410) icent,iel(idx),
     &              iz(icard,1),f(np1),np1,
     $              iz(icard,2),f(np2),np2,
     &              iz(icard,3),f(np3),np3,
     &              iz(icard,4)
            endif
         else
            if(ocart(icard))then
               write(iout,1520)        iel(idx), 
     &              f(np2), np2, f(np3) ,np3 ,f(np1), np1
            else
               write (iout,1420)       iel(idx),
     &              iz(icard,1),f(np1),np1,
     $              iz(icard,2),f(np2),np2,
     &              iz(icard,3),f(np3),np3,
     &              iz(icard,4)
            endif
         endif
  200    continue


  225 continue
      write (iout,1060)
c
c     return to caller.
c
      return
c
      end
      subroutine genpo
      implicit REAL  (a-h,o-z)
c
INCLUDE(common/tdhf)
INCLUDE(common/tdhfx)
INCLUDE(common/crnamx)
INCLUDE(common/crnams)
c
      character *8 ztext,spher,end,blank
      data spher/'spherica'/
      data end/'end'/,blank/' '/
c
      ogen = .true.
      do 80  i = 1,50
      pnames(i) = blank
      ipsec(i) = 0
      ipang(i) = 0
80    opskip(i) = .true.
      call inpa(ztext)
      npa = 0
      if (ztext.eq.spher) then
c
c
c     'spherical' perturbations
c
         ospher = .true.
         do 20 i = 1 , 24
            opskip(i) = .true.
            pnames(i) = pnams(i)
            ipang(i) = iangs(i)
 20      continue
         go to 60
      else
c
c     cartesian perturbations
c
         do 30 i = 1 , 37
            pnames(i) = pnamc(i)
            ipang(i) = iangc(i)
            opskip(i) = .true.
 30      continue
      end if
c
c
 40   call input
      call inpa(ztext)
      if (ztext.eq.end) return
      call inpi(iscp)
      call inpi(ianp)
c
      do 50 i = 1 , 37
         if (ztext.eq.pnamc(i)) then
            if (iscp.eq.0 .and. i.le.9) iscp = i + 21
            if (iscp.eq.0 .and. i.gt.9) iscp = i + 52
            opskip(i) = .false.
            npa = npa + 1
            ipsec(i) = iscp
            go to 40
         end if
 50   continue
      npa = npa + 1
      opskip(npa) = .false.
      pnames(npa) = ztext
      ipang(npa) = ianp
      ipsec(npa) = iscp
      go to 40
c
c
c
 60   call input
      call inpa(ztext)
      if (ztext.eq.end) return
      call inpi(iscp)
      call inpi(ianp)
c
c
      do 70 i = 1 , 24
         if (ztext.eq.pnams(i)) then
            npa = npa + 1
            opskip(i) = .false.
            ipsec(i) = iscp
            go to 60
         end if
 70   continue
      npa = npa + 1
      opskip(npa) = .false.
      pnames(npa) = ztext
      ipang(npa) = ianp
      ipsec(npa) = iscp
      go to 60
      end
      subroutine getb(xto,lento,xbb,nbb)
c
c
c     --- extracts a string from xbb (cursor nbb) and
c     --- puts it into xto the length is returned in lento
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension xto(*),xbb(*),xword(3)
      data xword/' ','-',','/
      lento = 0
 20   nbb = nbb + 1
      xchr = xbb(nbb)
      do 30 i = 1 , 3
         if (xchr.eq.xword(i)) go to 40
 30   continue
      lento = lento + 1
      xto(lento) = xchr
      go to 20
 40   return
c
      end
      subroutine getzm(core,isecz)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
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
      data m100/100/
c
c ... retrieve z-matrix section isecz
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
       call secget(isecz,m100,iblkz)
       nav = lenwrd()
c
       call rdchr(zsymm,nw8,iblkz,idaf)
       call readis(ianz,nw1*nav,idaf)
       if(mtask.eq.4.or.mtask.eq.5) then
          call reads(values,nw2,idaf)
          iblock = iblkz + lensec(nw1) + 2*lensec(nw2) + lensec(nw8)
       else
          iblock = iblkz + lensec(nw1) + lensec(nw2) + lensec(nw8)
          call rdedx(values,nw2,iblock,idaf)
          iblock = iblock + lensec(nw2)
       endif
       call rdchr(zvar,nw3,iblock,idaf)
       call readis(nat,nw4*nav,idaf)
       call readis(nonsym,nw5*nav,idaf)
       call reads(tr,nw6,idaf)
       call reads(toang(1),nw7,idaf)
c
      if (.not.ozmat.or.mtask.eq.6) return
      call subvar(bl,alpha,beta,lbl,lalpha,lbeta,nz,nvar)
      call trcart
      call subvar(bl,alpha,beta,lbl,lalpha,lbeta,nz,nvar)
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
      if (oerr) call caserr2(
     + 'error detected in converting z-matrix to cartesian coordinates')
      iold = igroup
      zoldg = zgroup
      jold = jaxis
      call symm(iwr,core)
      if (iold.ne.igroup .or. jold.ne.jaxis) then
         write (iwr,6040) zoldg , jold , zgroup , jaxis
         call caserr2('point group change detected')
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
      subroutine ggeom(
     * s3,mxbnds,
     * dist,csalpa,csbta,csgma,dcord,dcord2,dcord3,
     * am,coord2,ipath,n,nmats1)
c
      implicit REAL  (a-h,p-z),integer   (i-n)
      integer s3
c
INCLUDE(common/sizes)
c
      character*8 atlet,atlet2
      common /bufb/atlet(maxat),atlet2(maxat)
      dimension   dist(s3,15,3),csalpa(s3,15,3),
     -            csbta(s3,15,3),csgma(s3,15,3),
     -            dcord(3,s3),dcord2(3,s3),dcord3(3,s3),
     -            am(3,s3,15),coord2(3,s3),
     -            ipath(s3,15,mxbnds),n(s3)
      logical rotatz
      logical rotaty
c
c
c
c
c     this routine will determine the geometric parameters for
c     each atom in the molecule. these parameters are:
c
c          1. am(1,i,j) : the distance between atoms i and ipath(i,j,2)
c             where ipath(i,j,2) is the second atom along the jth
c             path from the ith atom
c
c          2. am(2,i,j) : the angle formed by the vectors ipath(i,j,2):
c             i and ipath(i,j,4):ipath(i,j,3) where ipath(i,j,3)
c             is the third atom along the jth acceptable path from
c             the ith atom and ipath(i,j,4) is the fourth atom along
c             the jth acceptable pathway from the ith atom.
c
c          3. am(3,i,j) : the dihedral angle,or torsional angle,formed
c             by the vectors ipath(i,j,2):i and ipath(i,j,3):ipath(
c             i,j,4) along the jth acceptable pathway.
c
c
c
c
c     direction cosines will be used to determine the bond angles
c       and dihedral angles in the molecule. for each atom i there
c       exists n(i) acceptable pathways as determined by the geo
c       metric constraints in the nddo and mindo/3 programs. for a
c       description of the analytical formulas used in this subroutine
c       see the crc standard table of mathematics,the 25th edition.
c
c
c
c
c     definition of the new terms used in this subroutine
c
c       dist(i,j,1) : the distance between the ith atom and the atom
c                     specified ipath(i,j,2)
c
c       dist(i,j,2) : the distance between the atoms ipath(i,j,2)
c                     and ipath(i,j,3)
c
c       dist(i,j,3) : the distance between the atoms ipath(i,j,3)
c                     and ipath(i,j,4)
c
c      csalpa(i,j,1) : cosine of the angle between the vector
c                         i:ipath(i,j,2) and the x-axis for the
c                         jth acceptable pathway.
c      csalpa(i,j,2) :  cosine of the angle between the vector
c                         ipath(i,j,3):ipath(i,j,2) and the x-axis.
c
c      csalpa(i,j,3) :  cosine of the angle between the vector
c                         ipath(i,j,4):ipath(i,j,3) and the x-axis.
c
c
c
c
      dacos(a) = arccos(a)
c     pi = dacos(0.0d0)*2.0d0
      do 30 i = 4 , nmats1
         do 20 j = 1 , n(i)
            dist(i,j,1) = ((coord2(1,i)-coord2(1,ipath(i,j,2)))**2+(
     +                    coord2(2,i)-coord2(2,ipath(i,j,2)))
     +                    **2+(coord2(3,i)-coord2(3,ipath(i,j,2)))**2)
     +                    **.50d00
c
            dist(i,j,2) = ((coord2(1,ipath(i,j,2))-coord2(1,ipath(i,j,3)
     +                    ))
     +                    **2+(coord2(2,ipath(i,j,2))-coord2(2,ipath(i,
     +                    j,3)))
     +                    **2+(coord2(3,ipath(i,j,2))-coord2(3,ipath(i,
     +                    j,3)))**2)**.50d00
c
            dist(i,j,3) = ((coord2(1,ipath(i,j,3))-coord2(1,ipath(i,j,4)
     +                    ))
     +                    **2+(coord2(2,ipath(i,j,3))-coord2(2,ipath(i,
     +                    j,4)))
     +                    **2+(coord2(3,ipath(i,j,3))-coord2(3,ipath(i,
     +                    j,4)))**2)**.50d00
c
            csalpa(i,j,1) = (coord2(1,i)-coord2(1,ipath(i,j,2)))
     +                      /dist(i,j,1)
            csbta(i,j,1) = (coord2(2,i)-coord2(2,ipath(i,j,2)))
     +                     /dist(i,j,1)
            csgma(i,j,1) = (coord2(3,i)-coord2(3,ipath(i,j,2)))
     +                     /dist(i,j,1)
c
            csalpa(i,j,2) = (coord2(1,ipath(i,j,3))-coord2(1,ipath(i,j,2
     +                      )))/dist(i,j,2)
            csbta(i,j,2) = (coord2(2,ipath(i,j,3))-coord2(2,ipath(i,j,2)
     +                     ))/dist(i,j,2)
            csgma(i,j,2) = (coord2(3,ipath(i,j,3))-coord2(3,ipath(i,j,2)
     +                     ))/dist(i,j,2)
c
            csalpa(i,j,3) = (coord2(1,ipath(i,j,4))-coord2(1,ipath(i,j,3
     +                      )))/dist(i,j,3)
            csbta(i,j,3) = (coord2(2,ipath(i,j,4))-coord2(2,ipath(i,j,3)
     +                     ))/dist(i,j,3)
            csgma(i,j,3) = (coord2(3,ipath(i,j,4))-coord2(3,ipath(i,j,3)
     +                     ))/dist(i,j,3)
c
            am(1,i,j) = dist(i,j,1)
            am(2,i,j) = (dacos(csalpa(i,j,1)*csalpa(i,j,2)+csbta(i,j,1)*
     +                  csbta(i,j,2)+csgma(i,j,1)*csgma(i,j,2)))
c
c
c     calculate the midpoint of the vector whose axis we shall
c       look down
c
            xm = (coord2(1,ipath(i,j,2))+coord2(1,ipath(i,j,3)))/2.0d0
            ym = (coord2(2,ipath(i,j,2))+coord2(2,ipath(i,j,3)))/2.0d0
            zm = (coord2(3,ipath(i,j,2))+coord2(3,ipath(i,j,3)))/2.0d0
c
c     translate the vector ipath(i,j,2):ipath(i,j,3) to the origin.
c       the coordinates of the endpoints of this vector are now
c
            dcord(1,ipath(i,j,2)) = coord2(1,ipath(i,j,2)) - xm
            dcord(2,ipath(i,j,2)) = coord2(2,ipath(i,j,2)) - ym
            dcord(3,ipath(i,j,2)) = coord2(3,ipath(i,j,2)) - zm
c
            dcord(1,ipath(i,j,3)) = coord2(1,ipath(i,j,3)) - xm
            dcord(2,ipath(i,j,3)) = coord2(2,ipath(i,j,3)) - ym
            dcord(3,ipath(i,j,3)) = coord2(3,ipath(i,j,3)) - zm
c
c
c     make this vector coplanar with the xy plane and colinear
c       with the x-axis. to determine how much ti rotate the vec
c       tor about the z-axis,project the vector onto the xy
c       plane.
c     the arccosine function will give values of alpha and gamma
c       between 0 and 180 degrees. to determine if the vector should
c       be positively or negatively rotated about the proper
c       axis it is necessary to determine which quadrant in the
c       appropiate plane the vector is in.
c
            if (dcord(1,ipath(i,j,2)).eq.0 .and. dcord(2,ipath(i,j,2))
     +          .eq.0) then
               prj = 0.0d0
               alpha = 0.0d0
            else
               prj = ((dcord(1,ipath(i,j,2)))**2+
     +                (dcord(2,ipath(i,j,2)))**2)**.50d0
               alpha = dacos(dcord(1,ipath(i,j,2))/prj)
            end if
c
c     rotate this vector plus or minus alpha degress about the z
c       axis.
c
            if (dcord(2,ipath(i,j,2)).lt.0) then
             dcord(1,ipath(i,j,2)) = dcord(1,ipath(i,j,2))*dcos(-alpha)
     +                             + dcord(2,ipath(i,j,2))*dsin(-alpha)
             dcord(2,ipath(i,j,2)) = dcord(2,ipath(i,j,2))*dcos(-alpha)
     +                             - dcord(1,ipath(i,j,2))*dsin(-alpha)
             rotatz = .false.
            else
             dcord(1,ipath(i,j,2)) = dcord(1,ipath(i,j,2))*dcos(alpha)
     +                             + dcord(2,ipath(i,j,2))*dsin(alpha)
             dcord(2,ipath(i,j,2)) = dcord(2,ipath(i,j,2))*dcos(alpha)
     +                             - dcord(1,ipath(i,j,2))*dsin(alpha)
             rotatz = .true.
            end if
c
c
c     to determine how much to rotate about the y-axis project the
c       vector onto the xz plane.
c
            if (dcord(1,ipath(i,j,2)).eq.0 .and. dcord(3,ipath(i,j,2))
     +          .eq.0) then
               prj = 0.0d0
               gamma = 0.0d0
            else
               prj = ((dcord(1,ipath(i,j,2)))**2+(dcord(3,ipath(i,j,2)))
     +               **2)**.50d0
               gamma = dacos(dcord(1,ipath(i,j,2))/prj)
               if (dcord(3,ipath(i,j,2)).gt.0) then
                  rotaty = .false.
               else
                  rotaty = .true.
               end if
            end if
c
c
c
c
c     rotate + - alpha degrees about the z-axis to make the
c       vector coplanar with the xz plane and rotate  + - gamma
c       degrees about the y-axis to make it colinear with the
c       x-axis.
c     note : these operations don't really need to be performed
c            we only need to calculate alpha and gamma so that the
c            vectors ipath(i,j,1):ipath(i,j,2) and ipath(i,j,3):
c            ipath(i,j,4) will be attached to ipath(i,j,2):ipath
c            (i,j,3);that is if we had actually rotated the vector
c            serving as the bond axis.
c
c     bring ipath(i,j,1):ipath(i,j,2) and ipath(i,j,3):ipath(i,j,4)
c       to the origin. have the points ipath(i,j,2) and ipath
c       (i,j,3) at the origin.
c
c
            dcord(1,ipath(i,j,1)) = coord2(1,ipath(i,j,1))
     +                              - coord2(1,ipath(i,j,2))
            dcord(2,ipath(i,j,1)) = coord2(2,ipath(i,j,1))
     +                              - coord2(2,ipath(i,j,2))
            dcord(3,ipath(i,j,1)) = coord2(3,ipath(i,j,1))
     +                              - coord2(3,ipath(i,j,2))
c
            dcord(1,ipath(i,j,4)) = coord2(1,ipath(i,j,4))
     +                              - coord2(1,ipath(i,j,3))
            dcord(2,ipath(i,j,4)) = coord2(2,ipath(i,j,4))
     +                              - coord2(2,ipath(i,j,3))
            dcord(3,ipath(i,j,4)) = coord2(3,ipath(i,j,4))
     +                              - coord2(3,ipath(i,j,3))
c
c
c     operate on these new vectors with the rotation operator.
c       rotate in the same manner the ipath(i,j,2):ipath(i,j,3)
c       was operated on.
c
c     rotate plus or minus alpha degrees about the z-axis
c       positive alpha will rotate the vector clockwise around the
c       z-axis if looking down the z-axis from the positive end.
c
            if (rotatz) then
             dcord2(1,ipath(i,j,1)) = dcord(1,ipath(i,j,1))*dcos(alpha)
     +                                  + dcord(2,ipath(i,j,1))
     +                                  *dsin(alpha)
             dcord2(2,ipath(i,j,1)) = dcord(2,ipath(i,j,1))*dcos(alpha)
     +                                  - dcord(1,ipath(i,j,1))
     +                                  *dsin(alpha)
             dcord2(3,ipath(i,j,1)) = dcord(3,ipath(i,j,1))
c
             dcord2(1,ipath(i,j,4)) = dcord(1,ipath(i,j,4))*dcos(alpha)
     +                                  + dcord(2,ipath(i,j,4))
     +                                  *dsin(alpha)
             dcord2(2,ipath(i,j,4)) = dcord(2,ipath(i,j,4))*dcos(alpha)
     +                                  - dcord(1,ipath(i,j,4))
     +                                  *dsin(alpha)
             dcord2(3,ipath(i,j,4)) = dcord(3,ipath(i,j,4))
            else
               dcord2(1,ipath(i,j,1)) = dcord(1,ipath(i,j,1))
     +                                  *dcos(-alpha)
     +                                  + dcord(2,ipath(i,j,1))
     +                                  *dsin(-alpha)
               dcord2(2,ipath(i,j,1)) = dcord(2,ipath(i,j,1))
     +                                  *dcos(-alpha)
     +                                  - dcord(1,ipath(i,j,1))
     +                                  *dsin(-alpha)
               dcord2(3,ipath(i,j,1)) = dcord(3,ipath(i,j,1))
c
               dcord2(1,ipath(i,j,4)) = dcord(1,ipath(i,j,4))
     +                                  *dcos(-alpha)
     +                                  + dcord(2,ipath(i,j,4))
     +                                  *dsin(-alpha)
               dcord2(2,ipath(i,j,4)) = dcord(2,ipath(i,j,4))
     +                                  *dcos(-alpha)
     +                                  - dcord(1,ipath(i,j,4))
     +                                  *dsin(-alpha)
               dcord2(3,ipath(i,j,4)) = dcord(3,ipath(i,j,4))
            end if
c
c
c     rotate   minus gamma degrees about the y axis
c
            if (rotaty) then
               dcord3(1,ipath(i,j,1)) = dcord2(1,ipath(i,j,1))
     +                                  *dcos(gamma)
     +                                  - dcord2(3,ipath(i,j,1))
     +                                  *dsin(gamma)
               dcord3(3,ipath(i,j,1)) = dcord2(3,ipath(i,j,1))
     +                                  *dcos(gamma)
     +                                  + dcord2(1,ipath(i,j,1))
     +                                  *dsin(gamma)
               dcord3(2,ipath(i,j,1)) = dcord2(2,ipath(i,j,1))
c
               dcord3(1,ipath(i,j,4)) = dcord2(1,ipath(i,j,4))
     +                                  *dcos(gamma)
     +                                  - dcord2(3,ipath(i,j,4))
     +                                  *dsin(gamma)
               dcord3(3,ipath(i,j,4)) = dcord2(3,ipath(i,j,4))
     +                                  *dcos(gamma)
     +                                  + dcord2(1,ipath(i,j,4))
     +                                  *dsin(gamma)
               dcord3(2,ipath(i,j,4)) = dcord2(2,ipath(i,j,4))
            else
               dcord3(1,ipath(i,j,1)) = dcord2(1,ipath(i,j,1))
     +                                  *dcos(-gamma)
     +                                  - dcord2(3,ipath(i,j,1))
     +                                  *dsin(-gamma)
               dcord3(3,ipath(i,j,1)) = dcord2(3,ipath(i,j,1))
     +                                  *dcos(-gamma)
     +                                  + dcord2(1,ipath(i,j,1))
     +                                  *dsin(-gamma)
               dcord3(2,ipath(i,j,1)) = dcord2(2,ipath(i,j,1))
c
               dcord3(1,ipath(i,j,4)) = dcord2(1,ipath(i,j,4))
     +                                  *dcos(-gamma)
     +                                  - dcord2(3,ipath(i,j,4))
     +                                  *dsin(-gamma)
               dcord3(3,ipath(i,j,4)) = dcord2(3,ipath(i,j,4))
     +                                  *dcos(-gamma)
     +                                  + dcord2(1,ipath(i,j,4))
     +                                  *dsin(-gamma)
               dcord3(2,ipath(i,j,4)) = dcord2(2,ipath(i,j,4))
            end if
c
c
c     project these new vectors onto the yz plane
c
            dcord3(1,ipath(i,j,1)) = 0.0d0
            dcord3(1,ipath(i,j,4)) = 0.0d0
c
c     determine the angle between these two vectors;use direction
c       cosines again.
c
            prjyz4 = ((dcord3(2,ipath(i,j,4)))
     +               **2+(dcord3(3,ipath(i,j,4)))**2)**.50d0
            prjyz1 = ((dcord3(2,ipath(i,j,1)))
     +               **2+(dcord3(3,ipath(i,j,1)))**2)**.50d0
            csbta1 = dcord3(2,ipath(i,j,1))/prjyz1
            csbta2 = dcord3(2,ipath(i,j,4))/prjyz4
            csgma1 = dcord3(3,ipath(i,j,1))/prjyz1
            csgma2 = dcord3(3,ipath(i,j,4))/prjyz4
c
c
            am(3,i,j) = dacos(csbta1*csbta2+csgma1*csgma2)
c
c
c     the sense of the dihedral angle will be defined as follows:
c       am(3,i,j) is between -180 and +180 degrees. am(3,i,j) is
c       greater than zero if you must rotate the vector specified
c       by atom i into atom ipath(i,j,4) in a clockwise manner.
c
c      to detremine the proper sign of the dihedral angle rotate
c       both vectors about the x-axis till the vector specified
c       by atom i is on the positive z-axis; recall that we are in
c       the yz plane.
c     if the vector specified by the ith atom is a quadrant in the
c       yz plane where the y coordinate is positive then we would
c       want to rotate minus theta degrees about the x-axis. if
c       the y coordinate is negative then we would want to rotate
c       a positive theta degrees about the x-axis  so that this
c       vector will be along the positive z-axis.
c
c
            theta = dacos(dcord3(3,ipath(i,j,1))/prjyz1)
            if (dcord3(2,ipath(i,j,1)).gt.0) then
               dcord3(2,ipath(i,j,1)) = dcord3(2,ipath(i,j,1))
     +                                  *dcos(-theta)
     +                                  + dcord3(3,ipath(i,j,1))
     +                                  *dsin(-theta)
               dcord3(3,ipath(i,j,1)) = dcord3(3,ipath(i,j,1))
     +                                  *dcos(-theta)
     +                                  - dcord3(3,ipath(i,j,1))
     +                                  *dsin(-theta)
c
               dcord3(2,ipath(i,j,4)) = dcord3(2,ipath(i,j,4))
     +                                  *dcos(-theta)
     +                                  + dcord3(3,ipath(i,j,4))
     +                                  *dsin(-theta)
               dcord3(3,ipath(i,j,4)) = dcord3(3,ipath(i,j,4))
     +                                  *dcos(-theta)
     +                                  - dcord3(2,ipath(i,j,4))
     +                                  *dsin(-theta)
            else
               dcord3(2,ipath(i,j,1)) = dcord3(2,ipath(i,j,1))
     +                                  *dcos(theta)
     +                                  + dcord3(3,ipath(i,j,1))
     +                                  *dsin(theta)
               dcord3(3,ipath(i,j,1)) = dcord3(3,ipath(i,j,1))
     +                                  *dcos(theta)
     +                                  - dcord3(3,ipath(i,j,1))
     +                                  *dsin(theta)
c
               dcord3(2,ipath(i,j,4)) = dcord3(2,ipath(i,j,4))
     +                                  *dcos(theta)
     +                                  + dcord3(3,ipath(i,j,4))
     +                                  *dsin(theta)
               dcord3(3,ipath(i,j,4)) = dcord3(3,ipath(i,j,4))
     +                                  *dcos(theta)
     +                                  - dcord3(2,ipath(i,j,4))
     +                                  *dsin(theta)
            end if
c
            if (dcord3(2,ipath(i,j,4)).lt.0.0d0) am(3,i,j) = -am(3,i,j)
c
 20      continue
 30   continue
      return
      end
      subroutine grhfin(readin,output,iw)
c
c    data input for grhf
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      logical readin,output
      logical ind
      character *4 je,ito,iend
      character *8 test
      dimension je(6),i11(11)
INCLUDE(common/work)
INCLUDE(common/ghfblk)
      common/small/ind(maxorb)
INCLUDE(common/infoa)
      data i11/0,11,22,33,44,55,66,77,88,99,110/
      data je/'shif','damp','je','ke','jc','kc'/
      data ito,iend/'to','end'/
      data halfng/-0.5d0/
      if (readin) then
         do 20 i = 1 , maxorb
            iactiv(i) = 0
            ind(i) = .false.
 20      continue
         do 30 i = 1 , 121
            damgen(i) = 1.0d0
 30      continue
         do 50 i = 1 , 11
            shfgen(i11(i)+i) = 0.0d0
            im1 = i - 1
            do 40 j = 1 , im1
               shfgen(i11(i)+j) = 1.0d0
               shfgen(i11(j)+i) = 1.0d0
 40         continue
 50      continue
         do 60 i = 1 , 495
            fjk(i) = 0.0d0
 60      continue
         do 70 i = 1 , 22
            nbshel(i) = 0
 70      continue
         nact = 0
         njk = 0
 80      call input
         call inpa(test)
         nsi = 0
         ilfshl(njk+1) = nact
         if (test(1:4).eq.iend) then
c..   construct virtual shell
            if (njk.lt.1 .or. njk.gt.10)
     +          call caserr2('error in shells directive')
            njk1 = njk + 1
            k = nact
            do 90 i = 1 , num
               if (.not.(ind(i))) then
                  nsi = nsi + 1
                  k = k + 1
                  iactiv(k) = i
               end if
 90         continue
            nbshel(njk1) = nsi
c... read in one-electron energy factors
            call input
            do 100 k = 1 , njk
               if (jrec.eq.jump) call input
               call inpf(fjk(k))
 100        continue
c...  generate default 2-electron energy expression and
c...  canonicalization parameters
            do 120 k = 1 , njk1
               m = i11(k)
               bot = fjk(k)
               do 110 l = 1 , njk1
                  n = i11(l)
                  top = fjk(l)*bot*0.5d0
                  erga(l+m) = top
                  top = top*halfng
                  ergb(l+m) = top
 110           continue
 120        continue
            do 130 ix = 1 , njk
               fcan(ix) = 2.0d0
 130        continue
            fcan(njk1) = 2.0d0
            do 150 j = 1 , njk1
               do 140 i = 1 , njk
                  cana(j+i11(i)) = fjk(i)
                  canb(j+i11(i)) = -0.5d0*fjk(i)
 140           continue
 150        continue
         else
            jrec = jrec - 1
 160        if (jrec.eq.jump) then
               if (nsi.lt.1) call caserr2(
     +      ' error in shells directive')
               njk = njk + 1
               nbshel(njk) = nsi
               go to 80
            else
               call inpi(m)
               n = m
               call inpa(test)
               if (test(1:4).ne.ito) then
                  jrec = jrec - 1
               else
                  call inpi(n)
               end if
               if (m.lt.1 .or. m.gt.n)
     +             call caserr2(
     +           'error in shells directive')
               do 170 i = m , n
                  if (ind(i)) call caserr2(
     +           'orbital given twice')
                  nact = nact + 1
                  ind(i) = .true.
                  iactiv(nact) = i
                  nsi = nsi + 1
 170           continue
               go to 160
            end if
         end if
c.. read in overriding j,k energy expression and
c... canonicalization parameters
c... and damp factors and level shifters
 180     call input
         call inpa(test)
         if (test(1:4).eq.iend) then
            do 190 i = 1 , 121
               shfgen(i) = shfgen(i)*0.5d0
 190        continue
            go to 280
         else
            call inpi(i)
            call inpi(j)
            call inpf(top)
            if (j.lt.1 .or. j.gt.njk1 .or. i.lt.1 .or. i.gt.njk1)
     +          call caserr2('error in shells directive')
            m = i11(i) + j
            n = i11(j) + i
            do 200 k = 1 , 6
               if (je(k).eq.test(1:4)) go to 210
 200        continue
            call caserr2('error in shells directive')
         end if
 210     go to (220,230,240,250,260,270) , k
c... level shift sub-parameter
 220     shfgen(m) = top
         shfgen(n) = top
         go to 180
c... damp sub-parameter
 230     damgen(m) = top
         damgen(n) = top
         go to 180
c.. jesub-parameter
 240     erga(m) = top
         erga(n) = top
         if (i.eq.njk1) call caserr2('error in shells directive')
         if (j.eq.njk1) call caserr2('error in shells directive')
         go to 180
c.. kesub-parameter
 250     ergb(m) = top
         ergb(n) = top
         if (i.eq.njk1) call caserr2('error in shells directive')
         if (j.eq.njk1) call caserr2('error in shells directive')
         go to 180
 260     cana(n) = top
         if (j.eq.njk1) call caserr2('error in shells directive')
         go to 180
 270     canb(n) = top
         if (j.eq.njk1) call caserr2('error in shells directive')
         go to 180
      end if
 280  if (output) then
c.. write out energy expression parameters
         write (iw,6010)
         write (iw,6020)
         do 290 k = 1 , njk1
            nsi = nbshel(k)
            if (nsi.gt.0) then
               i = ilfshl(k)
               write (iw,6030) k
               write (iw,6040) (iactiv(m+i),m=1,nsi)
            end if
 290     continue
         write (iw,6050)
         write (iw,6060) (fjk(k),k=1,njk)
         write (iw,6070)
         ndim = 11
         call prsqm(erga,njk,njk,ndim,iw)
         write (iw,6080)
         call prsqm(ergb,njk,njk,ndim,iw)
c.. write out canonicalizations
         write (iw,6090)
         call prsqm(cana,njk1,njk1,ndim,iw)
         write (iw,6100)
         call prsqm(canb,njk1,njk1,ndim,iw)
c... write out damp factors
         write (iw,6110)
         call prsqm(damgen,njk1,njk1,ndim,iw)
c... write out level shifters
         write (iw,6120)
         call prsqm(shfgen,njk1,njk1,ndim,iw)
      end if
      return
 6010 format (/1x,'parameters for generalised scf program'/)
 6020 format (//30x,'shell structure'/30x,15('*'))
 6030 format (/20x,'mos in shell',i3/20x,15('-'))
 6040 format (20x,20i4)
 6050 format (//30x,'1-electron energy expression parameters'/30x,
     +        39('*'))
 6060 format (/10x,8f14.7)
 6070 format (//30x,'coulomb energy expression parameters'/30x,36('*')
     +        )
 6080 format (//30x,'exchange energy expression parameters'/30x,
     +        37('*'))
 6090 format (//30x,'coulomb canonicalization parameters'/30x,35('*'))
 6100 format (//30x,'exchange canonicalization parameters'/30x,36('*')
     +        )
 6110 format (//30x,'damp factors'/30x,12('*'))
 6120 format (//30x,'level shifters'/30x,14('*'))
      end
      subroutine gridin(q,nq)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
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
     &               iresec(mxrest),nrest
c
c labels and titles
c
      common/cplot/zgridt(10,mxgrid),zgrid(mxgrid),
     &             zcalct(10,mxcalc),zcalc(mxcalc),
     &             zplott(10,mxplot),zplot(mxplot)
c the job sequence
      integer stype(mxstp), arg(mxstp)
      common/route/stype,arg,nstep,istep
c
INCLUDE(common/iofile)
INCLUDE(common/scra7)
INCLUDE(common/work)
INCLUDE(common/discc)
INCLUDE(common/workc)
INCLUDE(common/phycon)
      dimension q(*)
c
c local variables
c
      dimension vo(3),vx(3),vy(3),vz(3)
c
      data zblank/'        '/
      data zuntit/'untitled'/
c...    to allow grid specification in angstrom
      conv = 1.0d0
c
c grid types
c
      if(ngrid.eq.mxgrid)call caserr2('too many grids defined')
      ngrid = ngrid+1
c
c we classify the job types cont and wrap
c as distinct (they imply restore operations) so we set to 2 and 7 later
c
      nstep = nstep+1
      stype(nstep) = 1
      arg(nstep) = ngrid
c
c set defaults
c
      igsect(ngrid)=0
      igtype(ngrid)=1
      igstat(ngrid)=0
      ngdata(ngrid)=0

      npt(1,ngrid)=30
      npt(2,ngrid)=30
      npt(3,ngrid)=30

      do 5 i = 1,10
         zgridt(i,ngrid) = zblank
 5    continue
      zgridt(1,ngrid) = zuntit
      write(zgrid(ngrid),'(i8)')ngrid
c
      sx = 10.0d0
      sy = 10.0d0
      sz = 10.0d0
      vo(1) = 0.0d0
      vo(2) = 0.0d0
      vo(3) = 0.0d0
      vx(1) = 1.0d0
      vx(2) = 0.0d0
      vx(3) = 0.0d0
      vy(1) = 0.0d0
      vy(2) = 1.0d0
      vy(3) = 0.0d0
c
      if (jump.ge.2) then
        ii = 0
8       call inpa(ztest)
        if ((ztest(1:4).eq.'angs'.or.ztest(1:4).eq.'bohr'.or.
     #       ztest(1:2).eq.'au').and.ii.eq.0) then
          conv = 1.0d0
          if (ztest(1:4).eq.'angs') conv = 1.0d0/toang(1)
          ii = 1
        else 
           zgrid(ngrid) = ztest
        end if
        if (jrec.le.jump) go to 8 
      end if
c
 10   call input
      call inpa(ztest)
      ytest=ytrunc(ztest)
      if(ytest.eq.'titl')then
_IF1()c        call input
_IF1()c        k = 1
_IF1()c        do 20 i = 1 , 10
_IF1()c           zgridt(i,ngrid) = char1(k:k+7)
_IF1()c           k = k + 8
c20      continue
c
c don't convert to uppercase or lowercase - the title should
c not be just simple text, but allow for TeX characters
c to make later use of plotting utilities 
c
          read(ird,'(10a8)')(zgridt(i,ngrid),i=1,10)
c
      else if(ytest.eq.'poin')then
         call inpi(npt(1,ngrid))
         if(jump.gt.2)then
            call inpi(npt(2,ngrid))
         else
            npt(2,ngrid) = npt(1,ngrid)
         endif
         if(jump.gt.3)then
            call inpi(npt(3,ngrid))
         else
            npt(3,ngrid) = npt(1,ngrid)
         endif
      else if(ytest.eq.'type')then
         call inpa4(ytest)
         if(ytest.eq.'2d')then
            igtype(ngrid)=1
         else if(ytest.eq.'3d')then
            igtype(ngrid)=2
         else if(ytest.eq.'sphe')then
            oer=.false.
            igtype(ngrid)=3
c set integer flag to vary type
            igdata(1,ngrid)=1
            if(jump.ge.3)then
               call inpa(ztest)
               ytest=ytrunc(ztest)
               if(jump.eq.3.and.ytest.eq.'rand')then
                  igdata(1,ngrid)=1
               else if(jump.eq.4.and.ytest.eq.'symm')then
                  igdata(1,ngrid)=2
                  call inpi(igdata(2,ngrid))
               else
                  oer=.true.
               endif
            endif
            if(oer)then
               write(iwr,1000)
               call caserr2('bad type sphere directive')
            endif
c
c  for irregular grids, cards - values follow - spool to ed7
c
         else if(ytest.eq.'card')then
            igtype(ngrid)=4
            call inpi(nptot(ngrid))
            nw = nptot(ngrid)*3
            if(nw.gt.nq)call caserr2(
     +      'not enough core to read grid')
            ii = 0
            do 30 i = 1,nptot(ngrid)
               read(ird,*)(q(ii+j),j=1,3)
               do j=1,3
                  q(ii+j) = q(ii+j) * conv
               end do
               ii = ii+3
 30         continue
            iblk = ibl7la
            call wrt3(q,nw,iblk,num8)
            ibl7la = ibl7la + lensec(nw)
            igdata(1,ngrid)=iblk
c
c  contour an existing dataset
c
         else if(ytest.eq.'cont')then
            oer = .false.
            igtype(ngrid)=5
            igdata(1,ngrid)=0
            if(jump.gt.4)then
               oer=.true.
            else
               call inpf(gdata(1,ngrid))
               if(jump.eq.4)then
                  call inpa(ztest)
                  ytest = ytrunc(ztest)
                  if(ytest.eq.'noch')then
                     igdata(1,ngrid)=1
                  else if(ytest.ne.'chec')then
                     oer=.true.
                  endif
               endif
            endif
            if(oer)then
               write(iwr,1010)
               call caserr2('bad type contour directive')
            endif
c
c generate an isodensity contour
c
         else if(ytest.eq.'wrap')then
            igtype(ngrid)=6
            call inpf(gdata(1,ngrid))
         else if(ytest.eq.'atom')then
            igtype(ngrid)=7
         else if(ytest.eq.'sele')then
            igtype(ngrid)=8
            oer = .false.
            if(jump.gt.5)then
               oer=.true.
            else
               call inpf(gdata(1,ngrid))
               call inpf(gdata(2,ngrid))
               if(gdata(1,ngrid).gt.gdata(2,ngrid))
     &         call caserr2(
     &         'low value .gt. high value on type sele directive')
               if(jump.eq.5)then
                  call inpa(ztest)
                  ytest = ytrunc(ztest)
                  if(ytest.eq.'noch')then
                     igdata(1,ngrid)=1
                  else if(ytest.ne.'chec')then
                     oer=.true.
                  endif
               endif
            endif
            if(oer)then
               write(iwr,1020)
               call caserr2('bad type sele directive')
            endif
         else
            call caserr2('bad grid type keyword')
         endif
      else if(ytest.eq.'x')then
         do 40 i = 1,3
            call inpf(vx(i))
            vx(i) = vx(i) * conv
 40         continue
      else if(ytest.eq.'y')then
         do 50 i = 1,3
            call inpf(vy(i))
            vy(i) = vy(i) * conv
 50      continue
      else if(ytest.eq.'orig')then
         do 60 i = 1,3
            call inpf(vo(i))
            vo(i) = vo(i) * conv
 60      continue
      else if(ytest.eq.'size')then
         call inpf(sx)
         sx = sx * conv
         if(jump.gt.2)then
            call inpf(sy)
            sy = sy * conv
         else
            sy = sx
         endif
         if(jump.gt.3)then
            call inpf(sz)
            sz = sz * conv
         else
            sz = sx
         endif
      else if(ytest.eq.'sect')then
         call inpi(igsect(ngrid))
      else
c
c finish up
c set up plane point counts for regular grids
c
         if(igtype(ngrid).eq.1)then
            nptot(ngrid)=npt(1,ngrid)*npt(2,ngrid)
            sz = 0.0d0
         else if(igtype(ngrid).eq.2)then
            nptot(ngrid)=npt(1,ngrid)*npt(2,ngrid)*npt(3,ngrid)
         endif
c
c geometrical information
c
         if(igtype(ngrid).eq.1.or.igtype(ngrid).eq.2)then
            call vcrossprod(vz,vx,vy)
            call normal(vx)
            call normal(vz)
            call vcrossprod(vy,vz,vx)
            sx = sx*0.5d0
            sy = sy*0.5d0
            sz = sz*0.5d0
c   set geom  to corners of plane in case of 2d and 3d
            do 70 i = 1,3
               geom(i,ngrid)  =vo(i)-sx*vx(i)-sy*vy(i)-sz*vz(i)
               geom(i+3,ngrid)=vo(i)+sx*vx(i)-sy*vy(i)-sz*vz(i)
               geom(i+6,ngrid)=vo(i)-sx*vx(i)+sy*vy(i)-sz*vz(i)
               geom(i+9,ngrid)=vo(i)-sx*vx(i)-sy*vy(i)+sz*vz(i)
 70         continue
         else if(igtype(ngrid).eq.3)then
c    set geom  to origin for sphere
            do 80 i = 1,3
               geom(i,ngrid) =vo(i)
 80         continue
c     sphere radius
            gdata(1,ngrid) = sx
         endif
         jrec = jrec - 1
         return
      endif
      goto 10
c     the new coordinates are returned in cnew,
 1000 format(1x,'error on type directive - type sphere may be ',
     &     'followed by one of the keywords symm or rand',/,1x,
     &     'symm must be followed by an integer denoting ',
     &     'order of axial rotation symmetry to preserve',/,1x,
     &     'use the size directive to set the sphere radius')
 1010 format(1x,'error on type directive - type contour must be ',
     &     'followed by the ',
     &     /,1x,'contour height. This may optionally followed by one ',
     &     'of the strings check',
     &     /,1x,'or nocheck to request or suppress the check on the ',
     &     'contour touching the',
     &     /,1x,'edge of the 3d grid, check is the default')
 1020 format(1x,'error on type directive - type select must be ',
     &     'followed by lower ',
     &     /,1x,'and upper data limits. These may optionally ',
     &     'be followed by one of the strings check',
     &     /,1x,'or nocheck to request or suppress the check on the ',
     &     'selected points lying on the',
     &     /,1x,'edge of the 3d grid, check is the default')
      end
      subroutine gvbavg(nham)
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/scfwfn)
INCLUDE(common/mapper)
      data dzero,done,two/0.0d0,1.0d0,2.0d0/
c
      ncore1 = ncores + 1
      if (ncores.gt.0) then
c
c ----- setup a and b matrices for average state calculation
c
c ----- core electron coupling
c
         f(1) = done
         alpha(1) = two
         beta(1) = -done
c
c ----- core-open shell coupling
c
      end if
      loopk = 1
      do 20 k = ncore1 , nham
         f(k) = noe(loopk)/(two*no(loopk))
         loopk = loopk + 1
 20   continue
      if (ncores.gt.0) then
         do 30 k = 2 , nham
            k1 = iky(k) + 1
            alpha(k1) = f(k) + f(k)
            beta(k1) = -f(k)
 30      continue
      end if
c
c ----- open-open coupling
c
      loopj = 1
      do 50 j = ncore1 , nham
         jj = ikyp(j)
         norbj = no(loopj)
         nej = noe(loopj)
         nbj = max(nej-norbj,0)
         naj = nej - nbj
         if (norbj.ne.1) then
            alpha(jj) = (nej*(nej-1)-two*nbj)/(two*norbj*(norbj-1))
            beta(jj) = -(naj*(naj-1)+nbj*(nbj-1))/(two*norbj*(norbj-1))
         else if (nbj.ne.1) then
            alpha(jj) = dzero
            beta(jj) = dzero
         else
            alpha(jj) = two
            beta(jj) = -done
         end if
c
         jm1 = j - 1
         if (jm1.ge.ncore1) then
            loopk = 1
            do 40 k = ncore1 , jm1
               kj = iky(j) + k
               nei = noe(loopk)
               norbi = no(loopk)
               nbi = max(nei-norbi,0)
               nai = nei - nbi
               alpha(kj) = two*f(k)*f(j)
               beta(kj) = -(naj*nai+nbi*nbj)/(two*norbj*norbi)
               loopk = loopk + 1
 40         continue
         end if
c
c
         loopj = loopj + 1
 50   continue
c
      return
c
      end
      subroutine gvbin
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension zsigm(3),zsigp(3),zdelt(3)
      dimension  nt(10)
c
c     ----- read in the input data necesary for the gvb module -----
c
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/scfopt)
INCLUDE(common/scfwfn)
INCLUDE(common/runlab)
INCLUDE(common/mapper)
INCLUDE(common/datbas)
      common/blkin/kcorb(2,12),nconf(maxorb)
      data done,two,pt5/1.0d0,2.0d0,0.5d0/
      data zavg/'average'/
      data four,third/4.0d0,0.3333333333d0/
c
c      data for default gvb open shell modules
c
      data zblank/'    '/
      data pt25,pt75,pt1,pt2,pt3,pt4/0.25d0,0.75d0,0.1d0,0.2d0,0.3d0,
     *0.4d0/
      data pt55,pt65,pt7,pt8,pt95,pt125,pt16/0.55d0,0.65d0,0.7d0,0.8d0,
     *                       0.95d0,1.25d0,1.6d0/
      data zdname/'d'/
      data zsigm/'sig-','sigma-','sigm'/
      data zsigp/'sig+','sigma+','sigp'/
      data zdelt/'delt','del','delta'/
      l1 = num
c
c     ----- set up some upper limits -----
c
      write (iwr,6030)
c
      nhamx = 25
      nsetmx = 10
      npairx = 12
c
c     zero f,alpha,beta
c
      nhamx2 = iky(nhamx+1)
      call vclr(alpha,1,nhamx2)
      call vclr(beta,1,nhamx2)
      call vclr(f,1,nhamx)
c
      if (old) then
c
c     ----- read in description of wavefunction  in terms of
c           nco = number of core orbitals
c           nseto = number of open shell sets
c           npair = number of pairs
c           ifab = switch for overriding internal coupling
c                  coefficients
c                                                -----
c
         write (iwr,6030)
         call input
         call inpi(nco)
         call inpi(nseto)
         call inpi(npair)
         call inpi(ifab)
         call inpi(ifolow)
         norb = nco
         nopen = 0
         call setsto(nsetmx,0,no)
         if (nseto.gt.0) then
            call input
            do 20 i = 1 , nseto
               call inpi(no(i))
               nop = no(i)
               nopen = nopen + nop
               norb = norb + nop
 20         continue
c
         end if
c
         if (npair.gt.0) then
            norb = norb + npair + npair
         end if
         go to 70
      else
c
         nnnn = ne - nope - npair - npair
         nco = nnnn/2
         if (nco*2.ne.nnnn)
     +   call caserr2('error detected in processing scftype data')
      end if
      norb = nco + nopen + npair + npair
      if (nset.ne.nseto) then
c
c ... set up no(i) array for the (pi)(pi*) systems which
c ... must be treated as 4 rather than 2 sets of open shells
c
         it = 0
         do 50 i = 1 , nset
            it = it + 1
            nt(it) = no(i)/2
            it = it + 1
            nt(it) = no(i)/2
 50      continue
c
         if (it.ne.nseto) then
            call caserr2('error detected in processing scftype data')
         else
            do 60 i = 1 , nseto
               no(i) = nt(i)
 60         continue
         end if
      end if
c
c     ----- calculate the number of fock operators = nham -----
c
 70   ncores = 0
      if (nco.ne.0) ncores = 1
      ncore1 = ncores + 1
      ncore2 = ncores + 2
      nham = ncores + npair + npair + nseto
      write (iwr,6040) norb , nco , npair , nseto , (no(i),i=1,nseto)
      if (ifolow.ne.0) write (iwr,6050)
      if (nco.ne.0) write (iwr,6060) (i,i=1,nco)
c
      nbase = nco
      if (nseto.ne.0) then
         write (iwr,6070)
         do 80 i = 1 , nseto
            nopl = nbase + 1
            noph = nbase + no(i)
            write (iwr,6080) i , (j,j=nopl,noph)
            nbase = nbase + no(i)
 80      continue
c
      end if
c
      if (npair.ne.0) then
         ic = 0
         write (iwr,6090)
         do 90 i = 1 , npair
            norb1 = nbase + 1
            norb2 = nbase + 2
            write (iwr,6100) i , norb1 , norb2
            nbase = nbase + 2
 90      continue
c
      end if
c
c     ----- set up default parameters -----
c
      if (norb.le.l1 .and. nham.le.nhamx .and. nseto.le.nsetmx .and.
     +    npair.le.npairx) then
c
         do 110 j = 1 , nham
            f(j) = pt5
            do 100 k = 1 , nham
               jj = iky(j) + k
               alpha(jj) = 0.0d0
               beta(jj) = 0.0d0
 100        continue
 110     continue
c
         if (nco.gt.0) then
            do 120 j = 1 , nham
               j1 = iky(j) + 1
               alpha(j1) = done
               beta(j1) = -pt5
 120        continue
c
            alpha(1) = two
            beta(1) = -done
            f(1) = done
         end if
         if (old .and. (ifab.ne.0)) then
c
c     ----- read in ci coef and coupling parameters -----
c
            if (npair.gt.0) then
               do 130 kpair = 1 , npair
                  call input
                  call inpf(cicoef(1,kpair))
                  call inpf(cicoef(2,kpair))
 130           continue
c
            end if
c
            if (ifab.ge.2) then
               call input
               do 140 j = 1 , nham
                  call inpf(f(j))
 140           continue
               if (ifab.ge.3) then
                  ij = 0
                  do 170 j = 1 , nham
                     call input
                     do 150 i = 1 , j
                        call inpf(alpha(ij+i))
 150                 continue
                     call input
                     do 160 i = 1 , j
                        call inpf(beta(ij+i))
 160                 continue
                     ij = ij + j
 170              continue
               end if
            end if
            go to 460
         else
c
c     ----- set up default parameters -----
            ci1 = 0.95d0
            ci2 = -0.05d0
            sq = ci1*ci1 + ci2*ci2
            sq = dsqrt(sq)
            ci1 = ci1/sq
            ci2 = ci2/sq
            if (npair.gt.0) then
               do 180 i = 1 , npair
                  cicoef(1,i) = ci1
                  cicoef(2,i) = ci2
 180           continue
c
            end if
c
            if (zstate.eq.zavg) then
               call gvbavg(nham)
               write (iwr,6010)
               go to 460
            else if (old .and. (mul.gt.1)) then
c
c     ----- high spin states   half closed shell       -----
c
               nope = ne - nco - nco - npair - npair
               if (mul.gt.nope) go to 430
               write (iwr,6120) mul , nseto
               call caserr2('error detected in processing scftype data')
            else
c
c     ----- closed shell singlet - no new parameters -----
c
               if (nseto.eq.0) go to 460
               if (old) go to 410
c
c      gvb open shell options
c
               if (no(1).eq.1 .and. no(2).eq.1 .and. noe(1).eq.1 .and.
     +             noe(2).eq.1 .and. mul.eq.1) go to 410
c
               if (nset.ne.nseto) go to 360
               do 190 i = 1 , nseto
                  fnn = (dfloat(noe(i))/dfloat(no(i)))*pt5
                  f(i+ncores) = fnn
 190           continue
               if (ncores.gt.0) then
                  do 200 i = 1 , nseto
                     j = i + 1
                     ift = iky(j) + 1
                     fnn = f(j)
                     if (fnn.ne.pt5) then
                        alpha(ift) = fnn*two
                        beta(ift) = -fnn
                     end if
 200              continue
               end if
               fnn = 0.0d0
               do 210 j = 1 , nseto
                  i = j + ncores
                  fnn = fnn + f(i)
 210           continue
c
               tes = pt5*nseto
               if ((fnn.eq.tes) .and. (mul.gt.nope)) go to 430
               if (nseto.gt.1) then
c
c ... ***** grhf *****
c
                  if (nseto.gt.2) go to 360
c
c ... (sigma)(pi)n states
c     set up coupling parameters for sigma shell
c
                  do 220 i = 1 , 2
                     if (no(i).eq.1) go to 300
 220              continue
                  go to 310
               else
c
c .... **** serhf ****
c
                  if (noe(1).eq.1) go to 460
c
                  i22 = ikyp(ncore1)
c
c ... 3 electrons
                  if (no(1).gt.2) then
                     if (no(1).gt.3) then
c
c ----- atomic configs d1-d9 .. high spin ..
c
                        noe1 = noe(1)
                        if (noe1.gt.5) noe1 = 10 - noe1
                        if (mul.ne.(noe1+1)) then
                           call caserr2(
     +                       'error detected in processing scftype data'
     +                       )
                        else
                           noe1 = noe(1)
                           go to (460,230,240,250,430,260,270,280,290) ,
     +                            noe1
                        end if
                     else if ((noe(1).eq.2) .and. (mul.eq.3)) then
                        alpha(i22) = f(ncore1)/two
c
c ... 2 electrons triplet coupled
c
                        beta(i22) = -f(ncore1)/two
                        go to 460
                     else if (noe(1).eq.5) then
                        alpha(i22) = done + third
c
c ... 5 electrons
c
                        beta(i22) = -two*third
                        go to 460
                     else if ((noe(1).eq.4) .and. (mul.eq.3)) then
c
c ... 4 electrons triplet coupled
c
                        alpha(i22) = 5.0d0/6.0d0
                        beta(i22) = -pt5
                        go to 460
                     else if (zstate.eq.zblank) then
                        call caserr2(
     +        'state parameter of open directive must be specified')
                     else
                        if (noe(1).lt.3) then
c
c ... 2 electrons singlet coupled : s,a, or d
c
                           if (zstate.eq.zdname) then
                              alpha(i22) = pt1
                              beta(i22) = f(ncore1)*pt1
                           else
                              beta(i22) = f(ncore1)
                           end if
                        else if (noe(1).eq.3) then
c
c ... 3 electrons ...d or p
c
                           if (zstate.eq.zdname) then
                              alpha(i22) = pt4
                              beta(i22) = -pt2
                           else
                              alpha(i22) = third
                           end if
c
c ... 4 electrons singlet coupled s,a, or d
c
                        else if (zstate.eq.zdname) then
                           alpha(i22) = 23.0d0/30.0d0
                           beta(i22) = -pt3
                         else
                          alpha(i22) = 2.0d0/3.0d0
                          beta (i22) = 0.0d0
                        end if
                        go to 460
                     end if
c
                  else if (noe(1).eq.2) then
c
c ... 2 electrons...sig+,delt, or gamm singlet states
c
                     if (zstate.eq.zblank) then
                        call caserr2(
     +        'state parameter of open directive must be specified')
                     else
                        if (zstate.eq.zsigp(1) .or. zstate.eq.zsigp(2)
     +                      .or. zstate.eq.zsigp(3)) then
c
c ... open shells comprising 3 orbitals:
c ... isolate those 2,3, or 4 electron states for which
c ... stat must be specified:
c
                           beta(i22) = pt5
                        else
                           alpha(i22) = pt25
                        end if
                        go to 460
                     end if
                  else
                     alpha(i22) = done
                     beta(i22) = -pt5
                     go to 460
                  end if
               end if
            end if
         end if
      else
         write (iwr,6110)
         call caserr2('error detected in processing scftype data')
      end if
c
c     d2 or d3
 230  alpha(i22) = f(2)*pt25
      beta(i22) = -f(2)*pt25
      go to 460
 240  alpha(i22) = pt3*pt5
      beta(i22) = -pt3*pt5
      go to 460
c
c     d4
 250  alpha(i22) = pt3
      beta(i22) = -pt3
      go to 460
c
c     d6
 260  alpha(i22) = pt7
      beta(i22) = -pt5
      go to 460
c
c     d7
 270  alpha(i22) = pt95
      beta(i22) = -pt55
      go to 460
c
c     d8
 280  alpha(i22) = pt125
      beta(i22) = -pt65
      go to 460
c
c     d9
 290  alpha(i22) = pt16
      beta(i22) = -pt8
      go to 460
 300  i = i + ncores
      ias = ikyp(i)
      alpha(ias) = pt5
      beta(ias) = -pt5
c
c ... set up coupling parameters for pi shell depending on occupancy
c
 310  do 320 j = 1 , 2
         if (no(j).ne.1) then
            if (noe(j).lt.2) go to 330
            if (noe(j).eq.2) go to 350
            go to 340
         end if
 320  continue
c
c ... (sigma)(pi) ... 1,3 pi
c
 330  j = j + ncores
      iap = min(i,j) + iky(max(i,j))
      alpha(iap) = pt25
      if (mul.eq.1) beta(iap) = pt25
      if (mul.eq.3) beta(iap) = -pt25
      go to 460
c
c ... (sigma)(pi)3 ... 1,3 pi
c
 340  j = j + ncores
      iaj = ikyp(j)
      iap = min(i,j) + iky(max(i,j))
      alpha(iaj) = done
      beta(iaj) = -pt5
      alpha(iap) = pt75
      if (mul.eq.3) beta(iap) = -pt5
      go to 460
c
c ... (sigma)(pi)2 ... sig+,sig-, or delt states
c
 350  if (zstate.eq.zblank) then
         call caserr2(
     +       'state parameter of open directive must be specified')
      else
         j = j + ncores
         iaj = ikyp(j)
         iap = min(i,j) + iky(max(i,j))
         alpha(iap) = pt5
         if (zstate.eq.zsigm(1) .or. zstate.eq.zsigm(2) .or.
     +       zstate.eq.zsigm(3)) then
            beta(iap) = pt25
            alpha(iaj) = pt5
            beta(iaj) = -pt5
         else
            beta(iap) = -pt25
            if (zstate.eq.zsigp(1) .or. zstate.eq.zsigp(2) .or.
     +          zstate.eq.zsigp(3)) beta(iaj) = pt5
            if (zstate.eq.zdelt(1) .or. zstate.eq.zdelt(2) .or.
     +          zstate.eq.zdelt(3)) alpha(iaj) = pt25
         end if
         go to 460
      end if
c
c .....(pi)n(pi)m n,m=1,3
c
 360  if (nseto.ne.4) then
         call caserr2(
     +        'state parameter of open directive must be specified')
      else if (zstate.eq.zblank) then
         call caserr2(
     +        'state parameter of open directive must be specified')
      else
         do 380 i = 1 , nset
c
c ... set up alpha, beta and j values from no(i) and noe(i)
c
            it = 2*i - 1
            fnn = (dfloat(noe(i))/dfloat(no(it)))/four
            is = it + ncores
            do 370 loop = 1 , 2
               f(is) = fnn
               if (nco.gt.0) then
                  ifs = iky(is) + 1
                  alpha(ifs) = fnn*2
                  beta(ifs) = -fnn
               end if
               is = is + 1
 370        continue
 380     continue
c
c ... set up coupling parameters for each (pi)x (pi)y pair
c
         it = ncores
         do 400 i = 1 , nset
            if (noe(i).eq.1) then
               it = it + 2
            else
               if (noe(i).ne.3) go to 30
               do 390 k = 1 , 2
                  it = it + 1
                  is = ikyp(it)
                  alpha(is) = done
                  beta(is) = -pt5
 390           continue
               is = is - 1
c
               alpha(is) = done
               beta(is) = -pt5
            end if
 400     continue
c
c ... pick up coulomb and exchange parameters from data statements
c
         ia1 = 0
         ia2 = 0
         if (zstate.eq.zsigp(1) .or. zstate.eq.zsigp(2) .or.
     +       zstate.eq.zsigp(3)) ia1 = 1
         if (zstate.eq.zsigm(1) .or. zstate.eq.zsigm(2) .or.
     +       zstate.eq.zsigm(3)) ia1 = 2
         if (zstate.eq.zdelt(1) .or. zstate.eq.zdelt(2) .or.
     +       zstate.eq.zdelt(3)) ia1 = 3
         if (mul.eq.1) ia2 = 2
         if (mul.eq.3) ia2 = 1
         i = (ia1-1)*2 + ia2
         if (ia1.eq.0 .or. ia2.eq.0) go to 30
         ncore3 = ncore2 + 1
         ncore4 = ncore3 + 1
         ia1 = iky(ncore3) + ncore1
         ia2 = iky(ncore3) + ncore2
         ia3 = iky(ncore4) + ncore1
         ia4 = iky(ncore4) + ncore2
         if (noe(1).eq.1 .and. noe(2).eq.1) then
c
c ... (pi)(pi)
c
            alpha(ia1) = c11al(i)
            alpha(ia2) = c11al(i+6)
            beta(ia1) = c11be(i)
            beta(ia2) = c11be(i+6)
         else if (noe(1).eq.3 .and. noe(2).eq.3) then
c
c ... (pi)3(pi)3
c
            alpha(ia1) = c33al(i)
            alpha(ia2) = c33al(i+6)
            beta(ia1) = c33be(i)
            beta(ia2) = c33be(i+6)
         else
c
c ... (pi)3(pi)1
c
            alpha(ia1) = c31al(i)
            alpha(ia2) = c31al(i+6)
            beta(ia1) = c31be(i)
            beta(ia2) = c31be(i+6)
         end if
         alpha(ia3) = alpha(ia2)
         alpha(ia4) = alpha(ia1)
         beta(ia3) = beta(ia2)
         beta(ia4) = beta(ia1)
         go to 460
      end if
c
c
c     ----- open shell singlet -----
c
 410  if (nseto.ne.2) then
c
         write (iwr,6120) mul , nseto
         call caserr2('error detected in processing scftype data')
      else
         do 420 i = ncore1 , ncore2
            in = ikyp(i)
            alpha(in) = pt5
            beta(in) = -pt5
 420     continue
         i23 = iky(ncore2) + ncore1
         alpha(i23) = pt5
         beta(i23) = pt5
         go to 460
      end if
c
 430  do 450 i = 1 , nseto
         in = i + ncores
         do 440 j = 1 , i
            jn = j + ncores
            ij = iky(in) + jn
            alpha(ij) = pt5
            beta(ij) = -pt5
 440     continue
c
c
 450  continue
c
c     ----- generate nconf -----
c
 460  if (nco.ne.0) then
         call setsto(nco,1,nconf)
      end if
      ic = 0
      if (nseto.ne.0) then
         nbase = ncores
         do 470 i = 1 , nseto
            nop = no(i)
            call setsto(nop,nbase+1,nconf(ic+nco+1))
            nbase = nbase + 1
            ic = ic + nop
 470     continue
c
      end if
c
      if (npair.ne.0) then
         np2 = npair + npair
         do 480 i = 1 , np2
            nconf(i+nco+ic) = ncores + nseto + i
 480     continue
c
      end if
c
c     ----- generate kcorb -----
c
      if (npair.ne.0) then
         nbase = nco + ic
         do 490 kpair = 1 , npair
            kcorb(1,kpair) = nbase + 1
            kcorb(2,kpair) = nbase + 2
            nbase = nbase + 2
 490     continue
      end if
c
c
c     ----- normalize ci coefficient and update alpha and beta -----
c
      if (npair.ne.0) call ciexpr(kcorb,nconf,nham,iky,l1)
c
c     ----- print the coupling parameters -----
c
      write (iwr,6130)
      write (iwr,6140)
      do 500 i = 1 , nham
         write (iwr,6150) i , f(i)
 500  continue
c
      write (iwr,6160)
      call prtri(alpha,nham)
      write (iwr,6170)
      call prtri(beta,nham)
      if (npair.gt.0) then
         write (iwr,6180)
         nbase = nco + nopen
         do 510 kpair = 1 , npair
            write (iwr,6190) kpair , cicoef(1,kpair) , cicoef(2,kpair)
 510     continue
c
      end if
      write (iwr,6020)
      return
 30   call caserr2('error detected in processing open data')
      return
 6010 format (/1x,'average energy expression used')
 6020 format (/)
 6030 format (/10x,25('*')/10x,'grhf-gvb input parameters'/10x,25('*')/)
 6040 format (10x,'norb     =',i5,/,10x,'nco      =',i5,/,10x,
     +        'npair    =',i5,/,10x,'nseto    =',i5,/,10x,'no       =',
     +        10i5,40(/,20x,10i5))
 6050 format (/10x,'switch off configuration locking')
 6060 format (/10x,13('-')/10x,'core orbitals'/10x,13('-')/40(/5x,10i5))
 6070 format (/10x,19('-')/10x,'open shell orbitals'/10x,19('-')/)
 6080 format (/10x,'set ',i5,' =',4x,10i5,40(/,20x,10i5))
 6090 format (/10x,'pair orbitals'/)
 6100 format (/10x,'pair ',i5,' orbs ',i5,i5)
 6110 format (/10x,' limits exceeded - stop')
 6120 format (//10x,'no default couplings for  mult =',i5,' nseto = ',
     +        i5)
 6130 format (/10x,28('-')/10x,'grhf-gvb coupling parameters'/10x,
     +        28('-'))
 6140 format (/10x,'f coefficients'/10x,14('-')/)
 6150 format (i5,f15.10)
 6160 format (/10x,'a coupling coefficients'/10x,23('-'))
 6170 format (/10x,'b coupling coefficients'/10x,23('-'))
 6180 format (/10x,'natural orbital coefficients'//10x,'n.o. ',15x,
     +        'coefficients'/)
 6190 format (10x,i3,5x,f15.10,2x,f15.10)
      end
      subroutine gvbrhf(output)
c
c    convert gvb data to input for grhf
c
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      logical output
      dimension i11(11)
INCLUDE(common/mapper)
INCLUDE(common/scfwfn)
INCLUDE(common/ghfblk)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
      data i11/0,11,22,33,44,55,66,77,88,99,110/
      do 20 i = 1 , maxorb
         iactiv(i) = 0
 20   continue
      do 30 i = 1 , 121
         damgen(i) = 1.0d0
 30   continue
      do 50 i = 1 , 11
         shfgen(i11(i)+i) = 0.0d0
         im1 = i - 1
         do 40 j = 1 , im1
            shfgen(i11(i)+j) = 1.0d0
            shfgen(i11(j)+i) = 1.0d0
 40      continue
 50   continue
      do 60 i = 1 , 495
         fjk(i) = 0.0d0
 60   continue
      do 70 i = 1 , 22
         nbshel(i) = 0
 70   continue
      nact = 0
      njk = 0
      ilfshl(1) = 0
      nham = ncores + nseto
      if (nco.gt.0) then
         do 80 loop = 1 , nco
            nact = nact + 1
            iactiv(nact) = loop
 80      continue
         njk = njk + 1
         ilfshl(njk+1) = nact
         nbshel(njk) = nact
      end if
      if (nseto.ne.0) then
         nsi = nco
         do 100 loop = 1 , nseto
            nop = no(loop)
            njk = njk + 1
            nbshel(njk) = nop
            do 90 moop = 1 , nop
               nact = nact + 1
               iactiv(nact) = nsi + 1
               nsi = nsi + 1
 90         continue
            ilfshl(njk+1) = nact
 100     continue
      end if
      if (nsi.lt.1) call caserr2('error in shells directive')
c..   construct virtual shell
      if (njk.lt.1 .or. njk.gt.10 .or. njk.ne.nham)
     +    call caserr2('error in shells directive')
      njk1 = njk + 1
      k = nact
      do 110 loop = nact + 1 , num
         iactiv(loop) = loop
 110  continue
      nbshel(njk1) = num - nact
c... set  one-electron energy factors
      do 120 loop = 1 , njk
         fjk(loop) = f(loop) + f(loop)
 120  continue
c...  set 2-electron energy expression and
c...  canonicalization parameters
      do 140 k = 1 , njk1
         m = i11(k)
         do 130 l = 1 , njk1
c           n = i11(l)
            kl = min(k,l) + iky(max(k,l))
            erga(l+m) = alpha(kl)
            ergb(l+m) = beta(kl)
 130     continue
 140  continue
      do 150 ix = 1 , njk
         fcan(ix) = 2.0d0
 150  continue
      fcan(njk1) = 2.0d0
      do 170 j = 1 , njk1
         do 160 i = 1 , njk
            cana(j+i11(i)) = fjk(i)
            canb(j+i11(i)) = -0.5d0*fjk(i)
 160     continue
 170  continue
      if (output) then
c.. write out energy expression parameters
         write (iwr,6010)
         write (iwr,6020)
         do 180 k = 1 , njk1
            nsi = nbshel(k)
            if (nsi.gt.0) then
               i = ilfshl(k)
               write (iwr,6030) k
               write (iwr,6040) (iactiv(m+i),m=1,nsi)
            end if
 180     continue
         write (iwr,6050)
         write (iwr,6060) (fjk(k),k=1,njk)
         write (iwr,6070)
         ndim = 11
         call prsqm(erga,njk,njk,ndim,iwr)
         write (iwr,6080)
         call prsqm(ergb,njk,njk,ndim,iwr)
c.. write out canonicalizations
         write (iwr,6090)
         call prsqm(cana,njk1,njk1,ndim,iwr)
         write (iwr,6100)
         call prsqm(canb,njk1,njk1,ndim,iwr)
      end if
      return
 6010 format (/1x,'parameters for generalised scf program'/1x,
     +        '**************************************'/)
 6020 format (/30x,'shell structure'/30x,15('*'))
 6030 format (/20x,'mos in shell',i3/20x,15('-'))
 6040 format (20x,20i4)
 6050 format (/30x,'1-electron energy expression parameters'/30x,39('-')
     +        )
 6060 format (/10x,8f14.7)
 6070 format (/30x,'coulomb energy expression parameters'/30x,36('-'))
 6080 format (/30x,'exchange energy expression parameters'/30x,37('-'))
 6090 format (/30x,'coulomb canonicalization parameters'/30x,35('-'))
 6100 format (/30x,'exchange canonicalization parameters'/30x,36('-'))
      end
      subroutine inpstr(xstr,len,if1)
c
c
c     --- moves a string from /work/
c     --- compatable with free format input routines
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension xstr(*)
INCLUDE(common/work)
INCLUDE(common/workc)
      data xblnk/' '/
      if1 = 0
      jrec = jrec + 1
      len = 0
      xstr(1) = xblnk
      if (jrec.gt.jump) return
      len = inumb(jrec)
      is = istrt(jrec)
      do 20 i = 1 , len
         xstr(i) = char1(is:is+len-1)
         is = is + 1
 20   continue
      if (oalph(xstr,len)) if1 = 1
      return
      end
      subroutine invect(orest)
c
c     This subroutine processes the vectors directive.
c     The procedure is slightly tricky in that the steps are performed
c     in the following order:
c
c     1. We process the options associated with the mode for the 
c        vectors input
c     2. Rewind to early on the line
c     3. Process the actual mode for the vectors input
c
c     E.g.:
c
c         vectors cards free
c
c     we fist process "free" then rewind to process "cards".
c     The above example allows the specification of the guess orbitals
c     on standard input. The "free" option switches to reading the
c     orbitals in in free format. The input detailing the orbitals
c     should follow the "enter" directive, and is read by the subroutine
c     readmo.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/discc)
      common/linkmc/irrr(10),icang,ntimes
INCLUDE(common/prints)
INCLUDE(common/runlab)
INCLUDE(common/atmol3)
INCLUDE(common/datgue)
INCLUDE(common/work)
INCLUDE(common/infoa)
INCLUDE(common/scfopt)
INCLUDE(common/iofile)
INCLUDE(common/errcodes)
INCLUDE(common/zorac)
c
      dimension zscf(6)
      parameter (nvec=12)
      dimension zvect(nvec+1),yvect(nvec)
      character*80 string
c
      data oyes,ono/.true.,.false./
      data yprin/'prin'/,ycano/'cano'/,yunor/'unor'/,yfree/'free'/
      data ymop/'mopa'/,ystop/'stop'/,yalways/'alwa'/
      data zscf/'rhf','uhf','gvb','grhf','casscf','mcscf'/
      data zvect/'minguess','extguess','hcore','getq','extra',
     *'alphas','cards','nogen','atoms','atdens','atorbs',
     *'mcards','mosaved'/
      data yvect/'ming','extg','hcor','getq','extr','alph','card',
     *'noge','atom','atde','ator','mcar'/
      data yend,yto/'end','to'/
      data yspdf/'spdf'/ 
c
      natconf = 0
      natdiff = 0
      uhfatom = .false.
      isecat = -1
      oatcon = ono
      oground = ono
      odiff = ono
      oexc = ono
      ovprnt = ono
      ovcano = ono
      ovcfre = ono
      osemi = ono
      ostopm = ono
      oalway = ono
      isunor = 0
      icang = 0
      i = 1
c
c     Step 1. First we process the various options and set associated
c             logicals.
c
 20   continue
      call inpa(ztext)
      ytext = ytrunc(ztext)
      if (ytext.eq.yprin) then
         ovprnt = oyes
      else if (ytext.eq.yalways) then
         oalway = oyes
      else if (ytext.eq.ycano) then
         ovcano = oyes
         icang = 1
      else if (ytext.eq.yunor) then
         call inpi(isunor)
         i = i + 1
      else if (ytext.eq.yfree) then
         ovcfre = oyes
      else if (ytext.eq.ymop) then
         osemi = oyes
      else if (ytext.eq.ystop) then
         ostopm = oyes
c      else if (ytext.eq.'grou') then
      else if (ytext.eq.'diff') then
         odiff = oyes
         call inpa(zztext)
         yytext = ytrunc(zztext)
         if ( yytext .eq. 'grou' ) then
           oground = oyes
         else if ( yytext(1:4) .eq. 'exci' ) then
           oexc = oyes
         else if ( yytext .eq. ' ' ) then
           call caserr('no state specification, use ground or excited')
         end if
      else if (ytext.eq.'spec'.or.ytext.eq.'conf') then
c...     flag to read atomic configurations and other stuff on next cards
         oatcon = oyes
      else if (ytext.eq.'sect') then
         call inpi(isecat)
         if (isecat.eq.-1) call caserr2('illegal section on atorbs')
      else if (ytext.eq.'uhf') then
         uhfatom = .true.
      end if
      i = i + 1
      if(i.le.jump)goto 20
c
c     Step 2. Now rewind to the beginning of the vectors directive
c             and truncate the line removing the options we have 
c             processed already.
c
      jrec = 0
      if (odiff) jump = jump - 1
      if (oatcon) jump = jump - 1
      if (isecat.ne.-1) jump = jump - 2
      if (ovprnt) jump = jump - 1
      if (ovcano) jump = jump - 1
      if (ovcfre) jump = jump - 1
      if (osemi) jump = jump - 1
      if (ostopm) jump = jump - 1
      if (isunor.ne.0) jump = jump - 2
c
c     Step 3. Process the actually mode of inputting the vectors.
c
      call inpa(ztext)
      call inpa(ztext)
      oprint(45) = ono
      if (ovprnt) oprint(45) = oyes
      ii = locatc(yvect,nvec,ytrunc(ztext))
c
c     Now we are done with the input line. So continue executing the
c     actions required with this input if any.
c
c...   atdens/atorbs => atoms, remember in oatdo (.f.==dens/.t.=orb)
      if (ii.ge.9.and.ii.le.11) then
         oatdo = .false.
         if (ii.eq.11) oatdo = .true.
         ii = 9
         if (oatcon) then
31          call input
            call inpa(ztext)
            if (ztext.ne.'end') then
c...           check for occurence of atom
               do j=1,nat 
                  if (ztext.eq.ztag(j)) go to 32
               end do
               call caserr(' atom specfied not found ')
32             natconf = natconf + 1
               if (natconf.gt.nnatconf) 
     +         call caserr2('too many atomic configs in atoms')
               zatconf(natconf) = ztext
               string_ch(1,natconf) = ' '
               string_ch(2,natconf) = ' '
               do i=1,4
                  do j=1,2
                     spinat(j,i,natconf) = 0.0d0
                  end do
               end do
               chargat(natconf) = 0.0d0
               nonrel(natconf) = .false.
               forcat(natconf) = .false.
               iconc = 0
33             call inpan(string)
               if (string(1:4).eq.'conf') then
                  iconc = 1
                  ll = 0
               else if (string(1:4).eq.'dcon'.or.
     1                  string(1:4).eq.'dens') then
                  iconc = 2
                  ll = 0
               else if (string(1:4).eq.'spin') then
                  iconc = 0
                  if (.not.uhfatom) call caserr('spin for rhf')
                  call inpa4(ytext)
                  if (ytext.ne.yend) then
                     iati = index(yspdf,ytext(1:1))
                     call inpf(spinat(1,iati,natconf))
                     call inpf(spinat(2,iati,natconf))
                     go to 33
                  end if
               else if (string(1:4).eq.'char') then
                  iconc = 0
                  call inpf(chargat(natconf))
               else if (string.eq.' ') then
                  if (string_ch(2,natconf).eq.' ')
     1                string_ch(2,natconf) = string_ch(1,natconf)
                  go to 31
               else if (string(1:4).eq.'nonr'
     1              .or.string(1:4).eq.'nore') then
                  iconc = 0
                  if ( icoul_z.ne.2) call caserr
     1                    ('nonrelativistic atoms only for atomic zora')
                  nonrel(natconf) = .true.
               else if (string(1:4).eq.'forc') then
c...              force settings for this atom (for e.g. zora)
                  iconc = 0
                  forcat(natconf) = .true.
               else 
                  if (iconc.eq.0) call caserr2(
     +               'missing directive (eg. charge, conf, dens)')
                  call strtrm(string,length)
                  call addstring
     +                  (string_ch(iconc,natconf),ll,string(1:length))
               end if
               go to  33
            end if
         end if
         if ( odiff ) then
41         call input
           call inpa(zytext)
cmarcin           print *,'zytext odiff: ',zytext
           if ( oground ) then
cmarcin             print *,'ground'
             goto 444
           else if ( oexc ) then
cmarcin             print *,'oexc'
cmarcin             print *,'zytext: ',zytext
             if (zytext.ne.'end') then
c...  check for occurence of atom
               do j=1,nat 
                 if (zytext.eq.ztag(j)) go to 42
               end do
               call caserr(' atom specfied not found ')
42             natdiff = natdiff + 1
               if (natdiff.gt.natdiff) 
     +         call caserr2('too many atomic configs in atoms')
               zatdiff(natdiff) = zytext
               string_ch(1,natdiff) = ' '
               string_ch(2,natdiff) = ' '
43             call inpan(zstring)
cmarcin               print *,'zstring: ',zstring
               if ( zstring .eq. ' ' ) then
                 go to 41
               else
                 zatstate(natdiff) = zstring(1:2)
cmarcin                 print *,'zatstate: ',zatstate(natdiff)
                 goto 43
               end if
             end if
             do ij=1,nat
               do ijj=1,natdiff
cmarcin                 print *,'zaname: ',zaname(ij)
cmarcin                 print *,'zatdiff: ',zatdiff(ijj)
                 if ( zaname(ij) .eq. zatdiff(ijj) ) then
                   iatstates(ij) = 1
                 else
                   iatstates(ij) = 0
                 end if
               end do
             end do
           end if
444        continue
         end if
cmarcin         write(iwr,'(2x,a,10I3)') 'iatstates: ',(iatstates(j),j=1,nat)
      end if
c
      if (ii.eq.0) then
         ii = nvec + 1
      end if
      if (ii.ne.7) then
       if(isunor.ne.0)call caserr2(
     &   'unorth option only available with vectors cards')
       if(ovcfre)call caserr2(
     &   'free option only available with vectors cards')
       if(osemi)call caserr2(
     &   'mopac option only available with vectors cards')
       if(ostopm)call caserr2(
     &   'stop option only available with vectors cards')
      endif
      if (oground.and.ii.ne.9)
     &   call caserr2('ground  option only for atoms')
      zguess = zvect(ii)
cmarcin      print *,'ii: ',ii
      go to (40,50,160,70,70,130,160,120,160,160,160,160,110) , ii
 40   if (.not.oming) go to 60
      call inpf(scaleg)
      go to 160
 50   if (oextg) then
         call inpf(scaleg)
         go to 160
      end if
c
c ... ok, looks as though the basis specified rules out
c ... the minguess/extguess option .. reset to atoms/hcore
c ... depending on zscftp
c
 60   if (zscftp.eq.zscf(1)) then
         zguess = zvect(9)
      else
         zguess = zvect(3)
      end if
      go to 160
 70   ipass = 1
 80   call inpa4(ytext)
      numg(ipass) = locatc(yed,maxlfn,ytext)
      call inpi(i)
      if (i.lt.1) call caserr2(
     +              'invalid block specified in vectors directive'
     +              )
      iblk3g(ipass) = i
      call inpi(i)
      if (i.le.0 .or. i.gt.204)
     +    call caserr2('invalid dumpfile section specified')
      isecg(ipass) = i
      ipass = ipass + 1
      if (zscftp.eq.zscf(2)) then
         if (ipass.le.2) then
            if (jump.ne.5) go to 80
            numg(2) = numg(1)
            iblk3g(2) = iblk3g(1)
            isecg(2) = isecg(1)
         end if
      end if
      if (ii.eq.4) go to 160
      mextra = 0
      call input
 90   call inpa4(ytest)
      if (jrec.gt.jump) then
         call input
         go to 90
      else
         if (ytest.eq.yend) go to 160
         jrec = jrec - 1
         call inpi(m)
         n = m
         call inpa4(ytest)
         if (ytest.ne.yto) then
            jrec = jrec - 1
         else
            call inpi(n)
         end if
         if (n.lt.m .or. m.lt.1 .or. n.gt.num) call caserr2(
     +       'illegal parameter detected in extra directive')
         do 100 i = m , n
            mextra = mextra + 1
            next(mextra) = i
 100     continue
         go to 90
      end if
 110  if(.not.orest) then
         call gamerr('attempting to restore vectors in startup job',
     &        ERR_NO_CODE, ERR_INCOMPREHENSIBLE, ERR_SYNC, ERR_NO_SYS)
      endif
      jrec = jrec - 1
      call inpi(mina)
      onoor = .false.
      call inpa4(ytest)
      if (ytest.eq.'noor') then
         onoor = .true.
      else
         jrec = jrec - 1
      end if
      call inpi(minb)
      call inpa4(ytest)
      if (ytest.eq.'noor') onoor = .true.
      go to 160
 120  if (jump.lt.3) call caserr2(
     +  'no vectors section specified in nogen option')
      call inpi(mina)
      go to 160
 130  n = 0
      m = 1
 140  call input
      if (jump.eq.0) go to 140
      n = n + jump
      if (n.gt.num) n = num
      do 150 i = m , n
         call inpf(top)
         alphas(i) = -top
 150  continue
      m = m + jump
      if (m.lt.num) go to 140
      write (iwr,6020)
      write (iwr,6010) (alphas(i),i=1,num)
 160  return
 6010 format (/10x,8f14.7)
 6020 format (/40x,' input diagonal fock matrix elements')
      end
      subroutine addstring(string,length,str)
c
c...  add str to the string string
c
      character*(*) string,str
      integer length
      if (length.eq.0) then
         string = str
      else
         string = string(1:length)//str
      end if
      length = length + len(str)
      return
      end
      subroutine inversion(maxap3,a,b,natoms,t)
c
c     the coordinates of the natoms in a are inverted through the
c     origin using the transformation matrix t.  the inverted
c     coordinates are returned in b.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension t(3,*),a(maxap3,3),b(maxap3,3)
c
      data dzero,done/0.0d0, 1.0d0/
c
      do 30 i = 1 , 3
         do 20 j = 1 , 3
            t(i,j) = dzero
 20      continue
 30   continue
      t(1,1) = -done
      t(2,2) = -done
      t(3,3) = -done
      call tform(maxap3,t,a,b,natoms)
      return
      end
      function irkey(maxap3,natoms,a,atmchg,nset,npop,aset)
c
c     the "key atom" in a symmetric top molecule is hereby defined to
c     be the lowest numbered atom in the first circular-set.  the
c     first circular-set is that set which is nearest the cartesian
c     xy plane.  if two sets are in the same plane then the inner
c     one takes precedence and the lower atomic numbered one takes
c     precedence next.  if two sets are equidistant from the xy
c     plane, the one with a positive projection on the z-axis takes
c     precedence.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension nset(1), aset(maxap3,3), a(maxap3,3), atmchg(*)
      dimension npop(*)
c
      data dzero/0.0d0/
c
      call cirset(maxap3,natoms,a,atmchg,3,nset,npop,aset,numset)
      iset = 99
      do 20 jat = 1 , natoms
         jset = nset(jat)
         p = aset(jat,2)
         if (jset.ne.0 .and. jset.ne.iset) then
            if (iset.ne.99) then
c
               test = dabs(small) - dabs(p)
               if (dabs(test).le.toler) then
                  test = p - small
                  if (dabs(test).le.toler) then
                     test = aset(iat,3) - aset(jat,3)
                     if (dabs(test).le.toler) then
                        test = aset(iat,1) - aset(jat,1)
                     end if
                  end if
               end if
               if (test.ge.dzero) then
                  iset = jset
                  small = p
                  iat = jat
               end if
            else
               iset = jset
               iat = jat
               small = p
            end if
         end if
 20   continue
      irkey = iat
      return
      end
      function irnax(maxap3,a,natoms,atmchg,dis)
c
c     return the number of the cartesian axes which passes through
c     the greatest number of atoms.  if there is no one axis which
c     passes through more atoms than the other two then return the
c     number of the axes which passes through the largest number
c     of bonds.  if this is not decisive return a zero.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3), atmchg(1) ,dis(1)
      dimension cutoff(10), iclass(18), ix(4)
c
      data cutoff/0.89d0, 1.73d0, 2.91d0, 1.25d0, 2.53d0, 1.70d0, 1.66d0
     $,2.4d0,            2.04d0, 2.53d0/
      data iclass/1,1,2,2,3,3,3,3,3,3,4,4,4,4,4,4,4,4/
      data ix/0,1,3,6/
      data dzero,done/0.0d0,1.0d0/
c
      nx = 0
      ny = 0
      nz = 0
c
c     determine the number of atoms on each axis.
c
      do 20 iat = 1 , natoms
         setx = a(iat,1)*a(iat,1)
         sety = a(iat,2)*a(iat,2)
         setz = a(iat,3)*a(iat,3)
         dx = dsqrt(sety+setz)
         dy = dsqrt(setx+setz)
         dz = dsqrt(setx+sety)
         if (dabs(dx).lt.toler) nx = nx + 1
         if (dabs(dy).lt.toler) ny = ny + 1
         if (dabs(dz).lt.toler) nz = nz + 1
 20   continue
c
c     is any one count larger than the other two?
c
      if (nz.lt.ny) then
         if (ny.lt.nx) then
         else if (ny.eq.nx) then
            go to 30
         else
            irnax = 2
            return
         end if
      else if (nz.eq.ny) then
         if (nx.le.nz) go to 30
      else if (nz.lt.nx) then
      else if (nz.eq.nx) then
         go to 30
      else
         irnax = 3
         return
      end if
      irnax = 1
      return
c
c     determine the number of bonds cut by each cartesian axis.
c     the criteria are:
c     1-- the axis and the line connecting atoms a and b must
c         intersect.
c     2-- the distance between a and b must be less than some
c         cutoff.  in order to establish reasonable cutoffs
c         the atoms have been classified:
c            class     atoms
c             h         h, he
c             a1        li, be
c             a2        b, c, n, o, f, ne
c             b         na, mg, al, si, p, s, cl, ar
c         these four classes of atoms produce ten types of bonds.
c         the cutoff is 20: greater than the average standard
c         model bond length for the individual bonds of a given
c         type except for a1-a2 bonds where the cutoff is 10:
c         greater than the maximum standard model bond length of
c         that type.
c
c     calculate an interatomic distance matrix.
c
c
c     ----- allocate core for dis
c
 30   continue

      i10 = igmem_alloc(natoms*natoms)
c
      idx = i10 - 1
      nx = 0
      ny = 0
      nz = 0
      do 50 iat = 1 , natoms
         px1 = a(iat,1)
         py1 = a(iat,2)
         pz1 = a(iat,3)
         do 40 jat = 1 , iat
            idx = idx + 1
            dis(idx) = 
     +    dsqrt((px1-a(jat,1))**2+(py1-a(jat,2))**2+(pz1-a(jat,3))**2)
 40      continue
 50   continue
c
c     zero the entries in dis that are larger than the appropriate
c     bond distance cutoff.
c
      idx = i10 - 1
      do 70 jat = 1 , natoms
c changed AdM:
         jan = min(nint(atmchg(jat)),18)
c        jan = idint(atmchg(jat)+toler2)
         jjdx = iclass(jan)
         jdx = ix(jjdx)
         do 60 kat = 1 , jat
c changed AdM:
            kan = min(nint(atmchg(kat)),18)
c           kan = idint(atmchg(kat)+toler2)
            kkdx = iclass(kan)
            kdx = jdx + kkdx
            if (kkdx.gt.jjdx) kdx = ix(kkdx) + jjdx
            idx = idx + 1
            if (dis(idx).gt.cutoff(kdx)) dis(idx) = dzero
 60      continue
 70   continue
c
c     for each pair of bonded atoms determine which axis the bond
c     intersects.
c
      idx = i10 - 1
      do 130 iat = 1 , natoms
         do 120 jat = 1 , iat
            idx = idx + 1
            if (dabs(dis(idx)).ge.toler2) then
               do 110 i1 = 1 , 3
                  i2 = 1 + mod(i1,3)
                  i3 = 1 + mod(i2,3)
                  qa2 = a(iat,i2)
                  qa3 = a(iat,i3)
                  qb2 = a(jat,i2)
                  qb3 = a(jat,i3)
c
c     reject on-axis atoms.
c
                  tst1 = dsqrt(qa2*qa2+qa3*qa3)
                  if (tst1.lt.toler) go to 110
                  tst2 = dsqrt(qb2*qb2+qb3*qb3)
                  if (tst2.lt.toler) go to 110
c
c     does the i1 axis intersect the line defined by iat and jat?
c     (see crc math tables, 20th ed., p 365)
c
                  tst1 = qa3*(qa2-qb2)
                  tst2 = qa2*(qa3-qb3)
                  if (dabs(tst1-tst2).gt.toler2) go to 110
c
c     is the point of intersection between the atoms?
c
                  if (dabs(qa2).lt.toler .and. dabs(qb2).lt.toler) then
                     tst2 = dsign(done,qa3) + dsign(done,qb3)
                     if (tst2.ne.dzero) go to 110
                     go to (80,90,100) , i1
                  else
                     tst1 = dsign(done,qa2) + dsign(done,qb2)
                     if (tst1.ne.dzero) go to 110
c
c     increment the appropriate counter.
c
                     go to (80,90,100) , i1
                  end if
 80               nx = nx + 1
                  go to 110
 90               ny = ny + 1
                  go to 110
 100              nz = nz + 1
c
 110           continue
            end if
 120     continue
 130  continue
c
c     pick the biggest count, if any, and return.
c
      if (nz.lt.ny) then
         if (ny.lt.nx) then
            irnax = 1
         else if (ny.eq.nx) then
            irnax = 0
         else
            irnax = 2
         end if
      else if (nz.eq.ny) then
         if (nx.le.nz) then
            irnax = 0
         else
            irnax = 1
         end if
      else if (nz.lt.nx) then
         irnax = 1
      else if (nz.eq.nx) then
         irnax = 0
      else
         irnax = 3
      end if
c
c     ----- reset core
c
      call gmem_free(i10)

      return
      end
c     ****f* input/isubst
c
c     NAME
c
c       isubst - a function to establish the atomic number of a centre
c
c     SYNOPSIS
c
c       integer function isubst(xchar)
c
c     ARGUMENTS
c
c       xchar  - (input) a character*1 array that holds the label of a
c                centre
c       isubst - (output) the atomic number of the centre
c
c     FUNCTION
c
c       The function takes the label of a centre and returns the atomic
c       number. The label consists of the chemical symbol (1 or 2 
c       characters) potentially followed by a number. Examples are
c       H, H1, Na, Na2, etc. Additional "chemical symbols" are BQ and
c       X to denote ghost centres and dummy centres. The function 
c       scans the first characters of the label until an element
c       identification is reached and then return the corresponding
c       atomic number. For ghost centres and dummy centres the values
c       0 and -1 are returned.
c
c     SOURCE
c
      function isubst(xchar)
c ----------------------------------------------------------------------
c          a routine to return the atomic number of a center.  the
c     name if the center is given as a character string in "xchar".  the
c     returned value of this function is the atomic number.
c ----------------------------------------------------------------------
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension xchar(*)
      dimension xkey(2,107),isub(107),leni(107)
c
      data ni/107/
      data xkey/'h',' ','h','e',
     1 'l','i','b','e','b',' ','c',' ','n',' ','o',' ','f',' ','n','e',
     2 'n','a','m','g','a','l','s','i','p',' ','s',' ','c','l','a','r',
     3 'k',' ','c','a',
     + 's','c','t','i','v',' ','c','r','m','n','f','e','c','o','n','i',
     + 'c','u','z','n','g','a','g','e','a','s','s','e','b','r','k','r',
     4 'r','b','s','r',
     + 'y',' ','z','r','n','b','m','o','t','c','r','u','r','h','p','d',
     + 'a','g','c','d','i','n','s','n','s','b','t','e','i',' ','x','e',
     5 'c','s','b','a','l','a','c','e','p','r','n','d','p','m','s','m',
     + 'e','u','g','d','t','b','d','y','h','o','e','r','t','m','y','b',
     + 'l','u','h','f','t','a','w',' ','r','e','o','s','i','r','p','t',
     + 'a','u','h','g','t','l','p','b','b','i','p','o','a','t','r','n',
     6 'f','r','r','a','a','c','t','h','p','a','u',' ','n','p','p','u',
     + 'a','m','c','m','b','k','c','f','e','s','f','m','m','d','n','o',
     + 'l','w',
     $ 'b','q','-',' ','x',' ','q',' '/
      data leni/1,2,
     1  2,2,1,1,1,1,1,2,
     2  2,2,2,2,1,1,2,2,
     3  1,2,
     +  2,2,1,2,2,2,2,2,
     +  2,2,2,2,2,2,2,2,
     4  2,2,
     +  1,2,2,2,2,2,2,2,
     +  2,2,2,2,2,2,1,2,
     5  2,2,2,2,2,2,2,2,
     +  2,2,2,2,2,2,2,2,
     +  2,2,2,1,2,2,2,2,
     +  2,2,2,2,2,2,2,2,
     6  2,2,2,2,2,1,2,2,
     +  2,2,2,2,2,2,2,2,
     +  2,
     $  2,1,1,1/
      data isub/1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,
     $  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
     $  41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,
     $  61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,
     $  81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,
     $  101,102,103,
     $  0,-1,-1,-1/
      do 40 j = 1 , 2
         nchrs = iabs(j-3)
         do 30 i = 1 , ni
            nch = max(nchrs,leni(i))
            isave = i
            do 20 k = 1 , nch
               if (xchar(k).ne.xkey(k,i)) go to 30
 20         continue
            go to 50
 30      continue
 40   continue
      isubst = -10
      return
 50   isubst = isub(isave)
      return
c
      end
c     ******
      subroutine lframe(p,q,r,ps,qs,rs)
c
c
c
c     calculate the coordinates (xs,ys,zs) of a point in the local
c     frame given the coordinates (x,y,z) in the master frame
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/frame)
      ps = u1*(p-p0) + u2*(q-q0) + u3*(r-r0)
      qs = v1*(p-p0) + v2*(q-q0) + v3*(r-r0)
      rs = w1*(p-p0) + w2*(q-q0) + w3*(r-r0)
      return
      end
      function lsubst(xnam,n,xstr,len)
c
c ----------------------------------------------------------------------
c          a routine to return the sequential number of the center
c     whose name is in "str" (a hollerith string of length "len").
c     the list of known names in the delimited string "namcnt", and
c     there are "n" of these names.
c ----------------------------------------------------------------------
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension xnam(*),xstr(*),xtstr(20)
INCLUDE(common/iofile)
c
c                        initialize and loop over names.
c
      ncur = 0
      ians=0
      do 30 i = 1 , n
c
c                        get the next name from the list and see
c                        if it matches the supplied name.
c
         call getb(xtstr,lent,xnam,ncur)
         if (len.eq.lent) then
            do 20 j = 1 , len
               if (xtstr(j).ne.xstr(j)) go to 30
 20         continue
c           now check that centre has not been defined more than once.
            if(ians.ne.0) write(iwr,100) (xstr(jj),jj=1,len)
            ians = i
            go to 30
         end if
c
c                        center is not found.
 30   continue
      if(ians.eq.0) then
       lsubst = -10
      else
       lsubst = ians
      endif
      return
c
100   format('WARNING this centre has been defined more than once: ',
     +8a1)
c
      end
      subroutine matout(p,m,n,mm,nn)
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
      dimension p(m,n)
      iflg = 1
      ilower = 1
 20   iupper = ilower + 5
      if (iupper.ge.nn) then
         iupper = nn
         iflg = 0
      end if
      write (iwr,6010) (j,j=ilower,iupper)
      do 30 i = 1 , mm
         write (iwr,6020) i , (p(i,j),j=ilower,iupper)
 30   continue
      if (iflg.eq.1) then
         ilower = iupper + 1
         go to 20
      else
         return
      end if
 6010 format (9(11x,i3))
 6020 format (1x,i3,9e14.6)
c
      end

      subroutine imatout(p,m,n,mm,nn)
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
      integer p
      dimension p(m,n)
      iflg = 1
      ilower = 1
 20   iupper = ilower + 5
      if (iupper.ge.nn) then
         iupper = nn
         iflg = 0
      end if
      write (iwr,6010) (j,j=ilower,iupper)
      do 30 i = 1 , mm
         write (iwr,6020) i , (p(i,j),j=ilower,iupper)
 30   continue
      if (iflg.eq.1) then
         ilower = iupper + 1
         go to 20
      else
         return
      end if
 6010 format (9(11x,i3))
 6020 format (1x,i3,9i12)
c
      end


      subroutine mechin
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
c
INCLUDE(common/modj)
INCLUDE(common/modmin)
INCLUDE(common/moda)
INCLUDE(common/modf)
INCLUDE(common/modmd)
INCLUDE(common/mod2d)
INCLUDE(common/nbterm)
INCLUDE(common/prints)
INCLUDE(common/runlab)
INCLUDE(common/restar)
INCLUDE(common/restrj)
INCLUDE(common/machin)
INCLUDE(common/atmol3)
      common/junkc/ylab(26),ztype(35),zlist(100),zcentg(100),
     * ztagc(100),zhead(496),ztda(113)
INCLUDE(common/work)
INCLUDE(common/direc)
INCLUDE(common/phycon)
c
      dimension ymech(17)
      dimension zform(3),znonb(2),zunit(3),zdiel(2)
      dimension zforce(9),zdynam(10)
c
      data zcent /'central'/
      data zform /'formatte','unformat','pdb'/
      data znonb /'atoms','residues'/
      data zunit /'a.u.','au','angstrom'/
      data zdiel /'distance','constant'/
      data zforce/'all','omit',
     *            'hbonds','bonds','hangles','angles',
     *            'hdihedra','dihedral','nonbonde'/
      data zdynam/'maxwelli','tape','periodic','box',
     *            'temperat','pressure','timestep',
     *            'rectangu','monoclin','off'/
      data oyes/.true./
c     data ono/.false./
c     data zend,zto/'end','to'/
      data ymech/
     &'cycl','dyna','fina','mech','topo','nonb','diel',
     *'forc','impr','pair','vsca','esca','cutt','seco',
     *'chan','init','subs'/
      data zblank /' '/
      data yend/'end'/
      data zoff/'off'/
 20   call input
      call inpa(ztest)
      ytest = ytrunc(ztest)
      ii = locatc(ymech,17,ytest)
      if (ii.gt.0) then
         go to (30,40,130,140,150,160,170,180,190,200,210,220,230,260,
     +          270,280,290) , ii
      else
         jrec = jrec - 1
         ii = locatc(ydd(101),limit2,ytest)
         if (ii.ne.0) then
            return
         else
            call caserr2(
     +       'unrecognised directive or invalid directive sequence')
         end if
      end if
c.... go to proper place
c
c     input directives for modelling routines
c ...
c      cycle  <imcyc>
c ...
 30   if (jump.ge.2) then
c max number of cycles in mechanics optimisation.
         call inpi(imcyc)
         if (imcyc.gt.9999) imcyc = 9999
         nstlim = imcyc
      end if
      go to 20
c ...
c                                 dynamics.
c     the input following this directive refers to molecular dynamics.
c ...
 40   call inpa(ztest)
      if (ztest.ne.zblank) then
         ytest = ytrunc(ztest)
         if (ytest.eq.yend) go to 20
         iloc = locats(zdynam,7,ytest)
         if (iloc.lt.1) then
            call caserr2('invalid subdirective of dynamics directive')
         end if
         go to (120,50,60,70,90,100,110) , iloc
c ...     tape <formatted, unformatted>
 50      init = 1
c ...     the initial velocities for the md are read from a tape.
         if (jump.eq.2) go to 40
c ...     what format are these velocities in?
         call inpa4(ytest)
         iloc = locats(zform,2,ytest)
         if (iloc.lt.1) then
            call caserr2('invalid format specification')
         else if (iloc.eq.1) then
            go to 40
c                       err  ,form ,unfor
c ...     unformatted
         else if (iloc.gt.2) then
            call caserr2('invalid format specification')
         else
            ntx = 1
            go to 40
         end if
c ... periodic
 60      call inpa(ztest)
         if (ztest.ne.zblank) then
            iloc = locats(zdynam(8),3,ytrunc(ztest))
            if (iloc.le.0) call caserr2(
     +                  'invalid subparameter of periodic directive')
            if (iloc.lt.2) go to 20
            if (iloc.eq.2) then
c ... rectangular box. default. ( 1 )
c ... monoclinic box <bbeta>
               ntb = 1
               call inpa(ztest)
               if (ztest.ne.zblank) then
                  jrec = jrec - 1
                  call inpf(alpha)
                  if (dabs(alpha).gt.0.0d0) bbeta = dabs(alpha)
               end if
            else
c ...  off. no periodicity.
               ntb = 0
            end if
         end if
         go to 40
c ... box <box1><box2><box3> "units"
 70      if (jump.ge.5) then
            call inpf(box(1))
            call inpf(box(2))
            call inpf(box(3))
            call inpa4(ytest)
         else if (jump.eq.4) then
            call inpf(box(1))
            call inpf(box(2))
            box(3) = box(2)
            call inpa4(ytest)
         else if (jump.eq.3) then
            call inpf(box(1))
            box(2) = box(1)
            box(3) = box(2)
            call inpa4(ytest)
         else if (jump.eq.1) then
            call inpf(box(1))
            box(2) = box(1)
c default units.
            box(3) = box(2)
            go to 40
         end if
         iloc = locats(zunit,3,ytest)
         if (iloc.le.0) call caserr2(
     +                'invalid units specified on box subdirective')
         go to (80,80,40) , iloc
c ... assume working in angstroms for the moment.
 80      box(1) = box(1)*toang(1)
         box(2) = box(2)*toang(1)
         box(3) = box(3)*toang(1)
         go to 40
c ... temperature <tempo><tautp>
 90      if (opress) then
            call caserr2(
     +               'either const. temp or const. press , not both')
         else if (jump.ge.3) then
c expressed in kelvin.
            call inpf(tempo)
            call inpf(tautp)
            if ((tempo.lt.0.0d0) .or. (tautp.lt.0.0d0)) then
               call caserr2('temperature and coupling must be > zero')
            else
               otemp = oyes
               go to 40
            end if
         else
            call inpf(alpha)
            if (alpha.lt.0.0d0) then
               call caserr2('temperature and coupling must be > zero')
            else if (alpha.gt.1.0d0) then
               tempo = alpha
            else
               tautp = alpha
            end if
         end if
         otemp = oyes
         go to 40
c ... pressure <press>
 100     if (otemp) then
            call caserr2(
     +               'either const. temp or const. press , not both')
         else
            if (jump.ge.2) call inpf(press)
            if (press.lt.0.0d0)
     +          call caserr2('invalid pressure specified')
            opress = oyes
            go to 40
         end if
c ... timestep (picoseconds)
 110     if (jump.ge.2) call inpf(tims)
         if (tims.le.0.0d0) call caserr2('invalid timestep specified')
      else
         call input
      end if
      go to 40
c ...
c     maxwell <tempi>
c ...
 120  if (jump.ge.2) then
         call inpf(tempi)
         if (tempi.lt.0.0d0)
     +       call caserr2('invalid temperature for initial v dist')
      end if
      go to 20
c ...
c      final <form, unform, pdb>
c ...
 130  call inpa4(ytest)
      iloc = locats(zform,3,ytest)
      if (iloc.lt.1) then
         call caserr2('invalid format specification')
      else if (iloc.ne.1) then
         if (iloc.gt.2) then
            ntxo = 2
         else
c ... final or restart coords. are written in binary form.
            ntxo = 1
         end if
      end if
      go to 20
c ...
c      mech <imod>
c ...
c intermediate output during mechanics minimisation.
 140  call inpi(ntpr)
      ntpr = iabs(ntpr)
      mdpr = ntpr
      go to 20
c ...
c     topology <form, unform>
c ...
 150  call inpa4(ytest)
      iloc = locats(zform,3,ytest)
      if (iloc.lt.1) then
         call caserr2('invalid format specification')
      else if (iloc.eq.1) then
c ...                 formatted topology file.
         kform = 1
      end if
      go to 20
c ...
c nonbonded <<<atoms,<residue,residue><residue,atoms>>
c ...
c no parameters. hard way to use defaults.
 160  if (jump.ge.2) then
         call inpa4(ytest)
         iloc = locats(znonb,2,ytest)
         if (iloc.lt.1) then
            call caserr2('invalid parameter for nonbonded directive')
         else if (iloc.eq.1) then
c ... atoms ( iloc = 1 )
            ntn = 1
         else
c ... residue ( iloc = 2 ) ( = residue residue )
            ntn = 2
            if (jump.ge.3) then
               call inpa4(ytest)
c ... is this a subparameter of the residue subparameter?
               iloc = locats(znonb,2,ytest)
               if (iloc.lt.1) then
                  call caserr2(
     +                  'invalid parameter for nonbonded directive')
               else if (iloc.eq.1) then
c ... residue atoms ( default ) ( iloc = 1 )
                  ntn = 3
               else
c ... residue residue
                  ntn = 2
               end if
            end if
         end if
      end if
      go to 20
c ...
c     dielectric <dist,const<diel>>
c ...
 170  if (jump.ge.2) then
         call inpa4(ytest)
         iloc = locats(zdiel,2,ytest)
         if (iloc.lt.1) then
            call caserr2('invalid type of dielectric constant given')
         else if (iloc.eq.1) then
            go to 20
         end if
c ... constant dielectric function.
         idiel = 1
         if (jump.gt.2) call inpf(dielc)
         if (dielc.lt.0.0d0)
     +       call caserr2('invalid dielectric constant specified')
      end if
      go to 20
c ...
c     force <all,omit<bond,angle,dihedral,nonb,h>>
c ...
c the hard way.
 180  if (jump.ge.2) then
         call inpa4(ytest)
         iloc = locats(zforce,2,ytest)
         if (iloc.lt.1) then
c ... error
            call caserr2('invalid parameter on force directive')
         else if (iloc.ne.1) then
c ... omitting some interactions during force evaluation.
c     lets see which ones.
            call inpa4(ytest)
            iloc = locats(zforce(3),7,ytest)
c ... in the absence of anything better to do
c     h-bond interactions are omitted.
            if (iloc.eq.0) then
               ntf = 2
            else
               ntf = iloc
            end if
         end if
      end if
      go to 20
c ...
c         impdih improper dihedral driver flag. not used.
c ...
 190  call inpi(ntid)
      go to 20
c ...
c             pairlist <<off,nsnb>>
c ...
 200  if (jump.ge.2) then
         call inpa(ztest)
         if (ztest.ne.zoff) then
            jrec = jrec - 1
            call inpi(nsnb)
            go to 20
         end if
         ntnb = 0
      end if
      go to 20
c ...
c     vscale <svdw14>
c ...
 210  if (jump.ge.2) then
         call inpf(scnb)
         if (scnb.le.0.0d0) call caserr2(
     +                  'invalid scale factor for 14 vdw interactions')
      end if
      go to 20
c ...
c     escale <sele14>
c ...
 220  if (jump.ge.2) then
         call inpf(scee)
         if (scee.le.0.0d0) call caserr2(
     +              'invalid scale factor for 14 elec. interactions')
      end if
      go to 20
c ...
c     cuttol <cutoff <a.u.,au,angs>>>
c ...
 230  call inpf(cut)
      if (cut.lt.0.0d0) call caserr2(
     +                 'invalid cutoff distance for n.b. interactions')
c ... what are the units specified?
      if (jump.gt.2) then
         call inpa4(ytest)
         iloc = locats(zunit,3,ytest) + 1
         go to (250,240,240,20) , iloc
      end if
c ... no units specified assume a.u.
c ... atomic units. convert ( for the moment ) into angstroms.
 240  cut = cut*toang(1)
      go to 20
c ... error.
 250  call caserr2('invalid unit specification for cutoff distance')
c ... second <central>
 260  call inpa4(ytest)
      iloc = index(zcent,ytest)
      if (iloc.gt.0) isw = 1
      go to 20
c ...
c     change <off> modify charges of ab initio atoms
c     using input from mapping directive.
c ...
 270  call inpa(ztest)
      if (ztest.ne.zoff) ocharg = .true.
      go to 20
c ...
c     initial <form,unform> format of initial coordinates.
c ....
 280  call inpa4(ytest)
      iloc = locats(zform,2,ytest)
      if (iloc.gt.1) then
c ...  unformatted initial coordinates.
         ntx = 1
      end if
      go to 20
c ...
c   substitute : the input matrix is to be updated from the
c   mechanics coordinates.
c ...
 290  osubs = .true.
      go to 20
      end
      subroutine mkigcart(maxnz,nz,iz,igcart,ibuff,nparmz)
c
c     note the extravagent use of arguments ......
c     subroutine mkigcart(maxnz,nz,ianz,iz,bl,alpha,beta,igcart,
c    &     ibuff,nparm,nparmz,conver,iout)
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
c     dimension ianz(*), bl(*), alpha(*), beta(*)
      dimension iz(maxnz,4), igcart(*),ibuff(*)
c
c flag those atoms that are either zatoms, or are 
c referenced by the zatoms
c
      do i = 1,nz
         ibuff(i) = 0
      enddo
      do i = 1,nz
         if(iz(i,1) .ne. -1)then
            ibuff(i) = 1
            if(i.ge.2 .and. iz(i,1) .gt. 0)ibuff(iz(i,1)) = 1
            if(i.ge.3 .and. iz(i,2) .gt. 0)ibuff(iz(i,2)) = 1
            if(i.ge.4 .and. iz(i,3) .gt. 0)ibuff(iz(i,3)) = 1
         endif
      enddo

c
c now build icart array
c
      icount = 0
      nparmz = 0
      do i = 2,nz
         icount = icount + 1
         igcart(icount) = -1
         if(ibuff(i) .eq. 1)then
            nparmz = nparmz + 1
            igcart(icount) = nparmz
         endif
      enddo
      do i = 3,nz
         icount = icount + 1
         igcart(icount) = -1
         if(ibuff(i) .eq. 1)then
            nparmz = nparmz + 1
            igcart(icount) = nparmz
         endif
      enddo
      do i = 4,nz
         icount = icount + 1
         igcart(icount) = -1
         if(ibuff(i) .eq. 1)then
            nparmz = nparmz + 1
            igcart(icount) = nparmz
         endif
      enddo

      return
      end
      subroutine movez(maxap3,a,b,n)
c
c     move n sets of coordinates from a to b
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension a(maxap3,3),b(maxap3,3)
c
      do 30 j = 1 , 3
         do 20 i = 1 , n
            b(i,j) = a(i,j)
 20      continue
 30   continue
      return
      end
      subroutine mulinp(zact,num)
c
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/work/jrec,jump
      dimension ond(maxorb)
      dimension zact(*)
c
      nact = 0
      do 10 i =1,num
 10   zact(i) = 'other'
c
_IF1(cu)      call setsto(maxorb,.false.,ond)
_IFN1(cuf)      call setstl(maxorb,.false.,ond)
_IF1(f)      call vfill(.false.,ond,1,maxorb)
 50   call input
      call inpa(ztest)
      if (ztest.eq.'end') go to 40
 20   call inpi(m)
      if (m.eq.0) go to 50
      n = m
      call inpa4(ytest)
      if (ytest.ne.'to') then
         jrec = jrec - 1
      else
         call inpi(n)
      end if
      if (n.lt.1 .or. m.lt.1 .or. n.gt.num)
     +    call caserr2('invalid function specified in mullik directive')
      do 30 i = m , n
         nact = nact + 1
         if (ond(i)) call caserr2(
     +              'orbital doubly defined in mullik directive')
         if (nact.gt.num)
     +       call caserr2('invalid number of orbitals')
         ond(i) = .true.
         zact(i) = ztest
 30   continue
      go to 20
 40    if (nact.lt.1) call caserr2(
     +'invalid number of functions specified in mullik')
c
      return
      end
      subroutine normal(a)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension a(3)
      r = a(1)*a(1)+a(2)*a(2)+a(3)*a(3)
      r = dsqrt(r)
      if(r.eq.0.0d0)call caserr2('attempt to normalise null vector')
      a(1) = a(1)/r
      a(2) = a(2)/r
      a(3) = a(3)/r
      return
      end
      subroutine nosign(xstr,len,isgn)
c
c ----------------------------------------------------------------------
c          a routine to look for a leading minus sign in a string.
c     the string (of length "len") is in "str".  if a minus is found,
c     then this is removed from the string ("str" and "len" are updated
c     accordingly).  if no sign is found, then "isgn" is returned
c     +1, if a minus is found, then it is returned -1.
c ----------------------------------------------------------------------
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension xstr(*)
      data xmin/'-'/
c
c                        get the first character in the string, and
c                        see if it's a minus.
c
      isgn = 1
      if (xstr(1).ne.xmin) return
c
c                        copy the characters of the string down,
c                        and set value of isgn.
      isgn = -1
      len = len - 1
      i = 1
      j = 0
 20   if (j.gt.len) then
         return
      else
         i = i + 1
         j = j + 1
         xstr(j) = xstr(i)
         go to 20
      end if
c
      end
      function oalph(xchr,numb)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension xalp(26),xchr(1)
c
c     ---- checks to see if the character is alphabetic
c          first look for leading +/- .. if present
c          check on 2nd character (if there that is)
c
      data xalp/'a','b','c','d','e','f','g','h','i','j','k','l',
     1          'm','n','o','p','q','r','s','t','u','v','w','x',
     2          'y','z'/
       data xplus,xmin/'+','-'/
      oalph = .true.
      ich = 1
      if (xchr(1).eq.xplus .or. xchr(1).eq.xmin) then
         if (numb.eq.1) return
         ich = ich + 1
      end if
      do 20 i = 1 , 26
         if (xchr(ich).eq.xalp(i)) return
 20   continue
      oalph = .false.
      return
      end
      subroutine onelec(ione)
      implicit REAL  (a-h,o-z)
INCLUDE(common/iofile)
      dimension ione(*),mone(12)
INCLUDE(common/work)
      character *8 core,mone,ztest
      data core/'core'/
      data mone/'fock','s','t+v','x','y','z',
     1   'xx','yy','zz','xy','xz','yz'/
c
c  onelec directive
c
      write (iwr,6010)
      if (jump.eq.1) call caserr2('error in onelec directive')
      do 20 i = 1 , 12
         ione(i) = 0
 20   continue
      do 40 i = 2 , jump
         call inpa(ztest)
         do 30 j = 1 , 12
            if (ztest.eq.mone(j)) then
               write (iwr,6020) ztest
               ione(j) = 1
               go to 40
            end if
 30      continue
         if (ztest.eq.core) ione(1) = 2
         write (iwr,6020) ztest
         ione(1) = 2
 40   continue
c     iontrn = 1
      return
 6010 format (' 1-electron integrals to be transformed'/)
 6020 format (10x,a8)
      end
      subroutine paths(
     * s3,mxbnds,
     * iposna,iposnb,iposnc,
     * icon2,ipath,n,neigh1,iconv2,nmats1)
      implicit REAL  (a-h,o-z)
INCLUDE(common/sizes)
      integer s3
c
c
      character*8 atlet,atlet2
      common /bufb/atlet(maxat),atlet2(maxat)
      dimension   iposna(s3,5),iposnb(s3,10),iposnc(s3,10),
     -       ipath(s3,15, mxbnds),icon2(s3,mxbnds),
     -            n(s3),
     -            neigh1(s3),iconv2(s3)
c
c     this routine will determine the candidates for
c       the na(i),nb(i),and nc(i) geometric parameters.
c
      do 20 i = 1 , 4
         iposna(i,1) = 0
         iposnb(i,1) = 0
         iposnc(i,1) = 0
 20   continue
      iposna(2,1) = 1
      iposna(3,1) = 2
      iposna(4,1) = 3
      iposnb(3,1) = 1
      iposnb(4,1) = 2
      iposnc(4,1) = 1
      do 120 i = 5 , nmats1
         n(i) = 0
         nna = 0
         nnb = 0
         nnc = 0
         if (iconv2(i).eq.0) then
            k = mxbnds
         else
            k = neigh1(iconv2(i))
         end if
         do 30 j = 1 , k
            m = icon2(i,j)
            if (m.lt.i .and. m.ne.0) then
               nna = nna + 1
               iposna(i,nna) = m
            end if
 30      continue
         if (nna.eq.0) then
            write (6,6010) i
            go to 130
         else
c
c
c      we now have the possible candidates for na(i) where
c      i is the number of the atom
c
c
            do 50 jj = 1 , nna
               nnb2 = 0
               if (iconv2(iposna(i,jj)).eq.0) then
                  k = mxbnds
               else
                  k = neigh1(iconv2(iposna(i,jj)))
               end if
               do 40 j = 1 , k
                  m = icon2(iposna(i,jj),j)
                  if (m.lt.i .and. m.ne.0 .and. m.ne.iposna(i,1) .and.
     +                m.ne.iposna(i,2) .and. m.ne.iposna(i,3) .and.
     +                m.ne.iposna(i,4) .and. m.ne.iposna(i,5)) then
                     nnb = nnb + 1
                     nnb2 = nnb2 + 1
                     iposnb(i,nnb) = m
                  end if
                  if (j.eq.k .and. nnb.eq.0) iposna(i,jj) = 0
 40            continue
 50         continue
            if (nnb.eq.0) then
               write (6,6020) i
               go to 130
            else
c
c
c      we now have the possible candidates for nb(i)
c      now look at possibilities for nc(i)
c
c
               do 70 jjj = 1 , nnb
                  nnc2 = 0
                  if (iconv2(iposnb(i,jjj)).eq.0) then
                     k = mxbnds
                  else
                     k = neigh1(iconv2(iposnb(i,jjj)))
                  end if
                  do 60 j = 1 , k
                     m = icon2(iposnb(i,jjj),j)
                     if (m.lt.i .and. m.ne.0 .and. m.ne.iposnb(i,1)
     +                   .and. m.ne.iposnb(i,2) .and. m.ne.iposnb(i,3)
     +                   .and. m.ne.iposnb(i,4) .and. m.ne.iposna(i,1)
     +                   .and. m.ne.iposna(i,2) .and. m.ne.iposna(i,3)
     +                   .and. m.ne.iposna(i,4) .and. m.ne.iposna(i,5)
     +                   .and. m.ne.iposnb(i,5)) then
                        nnc = nnc + 1
                        nnc2 = nnc2 + 1
                        iposnc(i,nnc) = m
                     end if
                     if (j.eq.k .and. nnc2.eq.0) iposnb(i,jjj) = 0
 60               continue
 70            continue
               if (nnc.eq.0) then
                  write (6,6030) i
                  go to 130
               else
c
c
c
c     determine the various paths in the molecule for acceptable
c      values for the geometric parameters
c
c
                  do 110 l = 1 , nnc
                     kancel = 0
                     if (l.gt.1) then
                        do 80 la = 1 , l - 1
                           if (iposnc(i,la).eq.iposnc(i,l)) kancel = 1
 80                     continue
                     end if
                     if (iposnc(i,l).ne.0 .and. kancel.eq.0) then
                        do 100 l1 = 1 , nnb
                           if (iposnb(i,l1).ne.0 .and.
     +                         (iposnb(i,l1).eq.icon2(iposnc(i,l),1)
     +                         .or. iposnb(i,l1).eq.icon2(iposnc(i,l),2)
     +                         .or. iposnb(i,l1).eq.icon2(iposnc(i,l),3)
     +                         .or. iposnb(i,l1).eq.icon2(iposnc(i,l),4)
     +                         )) then
                              do 90 l2 = 1 , nna
                                 if (iposna(i,l2).ne.0 .and.
     +                               (iposna(i,l2)
     +                               .eq.icon2(iposnb(i,l1),1) .or.
     +                               iposna(i,l2)
     +                               .eq.icon2(iposnb(i,l1),2) .or.
     +                               iposna(i,l2)
     +                               .eq.icon2(iposnb(i,l1),3) .or.
     +                               iposna(i,l2)
     +                               .eq.icon2(iposnb(i,l1),4))) then
                                    n(i) = n(i) + 1
                                    ipath(i,n(i),1) = i
                                    ipath(i,n(i),2) = iposna(i,l2)
                                    ipath(i,n(i),3) = iposnb(i,l1)
                                    ipath(i,n(i),4) = iposnc(i,l)
                                 end if
 90                           continue
                           end if
 100                    continue
                     end if
 110              continue
               end if
            end if
         end if
 120  continue
      return
c
c error return
c
 130  call caserr2('error occured in z-matrix path generation')
      return
c
c
c
c
 6010 format (2x,'unable to determine na(',i3,')',/)
 6020 format (2x,'unable to determine nb(',i3,')',/)
 6030 format (2x,'unable to determine nc(',i3,')',/)
      end
      subroutine phyfil
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/phycon)
c
c
c     these data were taken from
c     pure and applied chemistry, 51, 1 (1979) unless noted otherwise
c
c     CRC Handbook 1990-1991 (page 1-2) Bohr-to-Angstrom
c
c                                         angstroms per bohr
c        1 Bohr = 0.529177249(24) Angstrom
c
c     This change is documented in CODATA Bulletin Number 63,
c     November 1986, "The 1986 Adjustment of the Fundamental Physical
c     Constants", a Report of the CODATA Task Group on Fundamental
c     Physical Constants published by Pergamon Press.
c
c
      data fbohr  /0.529177249d0/
c                                         kilograms per atomic mass unit
      data tokg   /1.6605655d-27/
c                                         electrostatic units (esu)
c                                            per electron charge
c                                            pure appl. chem.,
c                                            2, 717 (1973)
      data toe    /4.803242d-10/
c                                         planck constant, joule-seconds
      data planck /6.626176d-34/
c                                         avogadro constant
      data avog   /6.022045d+23/
c                                         joules per calorie
      data rjpcal /4.184d0/
c                                         metres per bohr
      data tomet  /5.29177249d-11/
c                                         joules per hartre
      data hartre /4.359814d-18/
c                                         speed of light, cm sec(-1)
      data slight /2.99792458d+10/
c                                         boltzman constant, joules per
c                                            kelvin
      data boltz  /1.380662d-23/
c
c
c
c
      toang(1) = fbohr
      toang(2) = tokg
      toang(3) = toe
      toang(4) = planck
      toang(5) = avog
      toang(6) = rjpcal
      toang(7) = tomet
      toang(8) = hartre
      toang(9) = slight
      toang(10) = boltz
      return
c
      end
      subroutine plotin(core,ncore)
c
c
c     this is data input routine for graphical analysis
c     primitive checking only
c
c directives fall into 3 classes
c
c    grid definition mode - starts with gdef
c
c        gdef  [<grid-id>]
c        type  <2d | 3d | contour | sphere | cards>
c        points   <gx> [<gy> [<gz>]]
c        x  <x> <y> <z>
c        y  <x> <y> <z>
c        origin <x>  <y>  <z>
c        size  <x> [<y> [<z]]
c
c    calcmode - starts with calc
c
c        calc [<calc-id>]
c        occdef   ** not yet
c        config   ** not yet
c        type  ( dens | ampl | atom | pote | mo <imo> | diff)
c
c    plotmode - starts with plot
c        the rest
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
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
     &               iresec(mxrest),nrest
c
c labels and titles
c
      common/cplot/zgridt(10,mxgrid),zgrid(mxgrid),
     &             zcalct(10,mxcalc),zcalc(mxcalc),
     &             zplott(10,mxplot),zplot(mxplot)
c the job sequence
      integer stype(mxstp), arg(mxstp)
      common/route/stype,arg,nstep,istep
      parameter (max2=maxorb+maxorb)
c
INCLUDE(common/direc)
INCLUDE(common/machin)
      common/junkc/
     *ylabel(26),ztype(831),zcont(100),z1(15),zname(15),zbuff(10)
INCLUDE(common/discc)
INCLUDE(common/work)
INCLUDE(common/workc)
      dimension core(*)
c
c     default settings
c
      nplot = 0
      ngrid = 0
      ncalc = 0
      nrest = 0
c
c     nav = lenwrd()
c
c routing steps
      nstep = 0
c
      do 5 i = 1,mxgrid
         do 51 j = 1,5
            igdata(j,i)=0
 51      gdata(j,i)=0.0d0
 5    zgrid(i)=' '
      do 6 i = 1,mxcalc
         do 61 j = 1,5
            icdata(j,i)=0
 61      cdata(j,i)=0.0d0
 6    zcalc(i)=' '
      do 7 i = 1,mxplot
         do 71 j = 1,3
 71      ipdata(j,i)=0
         do 72 j=1,7
 72      pdata(j,i)=0.0d0
 7    zplot(i)=' '
c
c output wavefunction stuff
c
c     now input valid graphics data
c     terminated by =type2= directive
c
      call input
 30   call inpa(ztest)
      ytest=ytrunc(ztest)

      if(nstep.eq.mxstp)call caserr2('too may graphics steps')

      if(ytest.eq.'gdef')then
         call gridin(core,ncore)
      else if(ytest.eq.'calc')then
         call calcin(core,core(maxorb),core(maxorb*2))
      else if(ytest.eq.'plot')then
         call plotin2(core)
      else if(ytest.eq.'surf')then
c
c property on isovalue surface (driver for gdef and calc)
c
         call surfin
         call input
      else if(ytest.eq.'rest')then
         nstep = nstep+1
         if(nrest.gt.mxrest)call caserr2('too many grid restores')
         nrest=nrest+1
         arg(nstep)=nrest
         call inpa(ztest)
         ytest=ytrunc(ztest)
         if(ytest.eq.'grid')then
            stype(nstep)=4
         else if(ytest.eq.'calc'.or.ytest.eq.'data')then
            stype(nstep)=5
         else
            call caserr2('bad restore keyword')
         endif
         call inpa(ztest)
         ytest = ytrunc(ztest)
         l = locatc(yed,maxlfn,ytest)
         if (l.eq.0)call caserr2('illegal dumpfile name')
         irestu(nrest) = l
         call inpi(irestb(nrest))
         call inpi(irests(nrest))
         call input
      else
c
c     data input complete
c
         ytest = ytrunc(ztest)
c
c     check for valid 2nd phase directive
c
         i = locatc(ydd(101),limit2,ytest)
c
         if (i.ne.0) then
            jrec = jrec - 1
            return
         else
            call caserr2(
     +           'unrecognised directive or faulty directive ordering')
         end if
      end if
      goto 30
      end
      subroutine plotin2(cval)
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
c input processor for plot requests
c
INCLUDE(common/sizes)
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
      common/tmdata/isp2(5),otrand,norbs,msptm
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
     &               iresec(mxrest),nrest
c
c labels and titles
c
      common/cplot/zgridt(10,mxgrid),zgrid(mxgrid),
     &             zcalct(10,mxcalc),zcalc(mxcalc),
     &             zplott(10,mxplot),zplot(mxplot)
c the job sequence
      integer stype(mxstp), arg(mxstp)
      common/route/stype,arg,nstep,istep
c
INCLUDE(common/iofile)
INCLUDE(common/scra7)
INCLUDE(common/work)
INCLUDE(common/workc)
      dimension cval(*)
      dimension rhotot(14),rhotra(12),rhodif(12),rhomo(12),rhopot(12)
      data zspace,zend/' ','end'/
      data zblank/'        '/
c
c GAMESS default contour heights
c
      data rhopot/
     *210.0d0,180.0d0,150.0d0,120.0d0,90.0d0,75.0d0,
     * 60.0d0, 40.0d0, 20.0d0, 10.0d0, 5.0d0, 2.0d0/
      data rhotot/
     *64.7837d0,16.1959d0,4.0490d0,1.0122d0,.5061d0,
     * 0.2531d0, 0.1265d0,0.0633d0,0.0316d0,0.0158d0,
     * 0.0079d0, 0.0040d0,0.0020d0,0.0010d0/
      data rhomo/
     *1.0d0,0.5d0,0.25d0,0.125d0,0.0625d0,
     *0.03125d0,0.01562d0,0.00781d0,0.00391d0,
     *0.00195d0,0.00098d0,0.00049d0/
      data rhodif/
     *0.86910d0,0.43455d0,0.21727d0,0.10864d0,
     *0.05432d0,0.02716d0,0.01358d0,0.00697d0,
     *0.00339d0,0.00170d0,0.00085d0,0.00042d0/
      data rhotra/
     + 2.0d-3,1.0d-3,8.0d-4,4.0d-4,3.0d-4,2.0d-4,1.0d-4,8.0d-5,
     + 4.0d-5,2.0d-5,1.0d-5,5.0d-6/
c     data yp1,yp2,yp3/' p1',' p2',' p3'/
      data zuntit/'untitled'/
c
      if(nplot.eq.mxplot)call caserr2('too many plots defined')
      nplot = nplot + 1
      nstep = nstep+1
      stype(nstep) = 3
      arg(nstep) = nplot
c
c set defaults
c
      iptype(nplot)=0
c
      ocont = .false.
      nc=0
c
      scamax = 0.7d0
      scamin = -0.7d0
      facmax = 1.2d0
      facmin = 1.2d0
      dist3d = 10.0d0
      anga = 30.0d0
      angb = 30.0d0
c
c use most recent calc
c
      ipcalc(nplot) = ncalc
c
      do 5 i = 1,10
         zplott(i,nplot) = zblank
 5    continue
      zplott(1,nplot) = zuntit
      write(zplot(nplot),'(i8)')nplot
c
      if(jump.eq.2)call inpa(zplot(nplot))
 10   call input
      call inpa(ztest)
      ytest=ytrunc(ztest)
      if(ytest.eq.'titl')then
_IF1()c        call input
_IF1()c        k = 1
_IF1()c        do 20 i = 1 , 10
_IF1()c           zplott(i,nplot) = char1(k:k+7)
_IF1()c           k = k + 8
_IF1()c20      continue
c
          read(ird,'(10a8)')(zplott(i,nplot),i=1,10)
c
      else if(ytest.eq.'type')then
         call inpa4(ytest)
         if(ytest.eq.'line')then
            iptype(nplot)=1
            ocont = .true.
         else if(ytest.eq.'cont')then
            iptype(nplot)=2
            ocont = .true.
         else if(ytest.eq.'surf')then
            iptype(nplot)=3
         endif
      else if(ytest.eq.'cont')then
 180     call input
 190     call inpa(ztest)
         if (ztest.eq.zend) then
            if (nplot.le.0)
     +           call caserr2('invalid number of contours specified')
         else
            if (ztest.eq.zspace) go to 180
            jrec = jrec - 1
            nc = nc + 1
            call inpf(cval(nc))
            go to 190
         end if
      else if(ytest.eq.'view')then
c
c     view
c
         if (jump.ne.4) call caserr2(
     +       'syntax of view directive in error')
         call inpf(anga)
         call inpf(angb)
         call inpf(dist3d)
      else if(ytest.eq.'scal')then
c
c     scale
c
         if (jump.ne.5)call caserr2(
     +       'syntax of scale directive in error')
         call inpf(scamax)
         call inpf(facmax)
         call inpf(scamin)
         call inpf(facmin)
      else
c
c check for silly choices
c
         ict = ictype(ipcalc(nplot))

         if(ict.eq.5)then
            call caserr2('vector field may not be plotted')
         else if(ict.eq.-1)then
            call caserr2('grd check calcn cant be plotted')
         endif
c
c default contouring heights
c
         if(ocont.and.nc.eq.0)then
            if(ict.eq.1)then
               if(otrand) then
               nc = 25
               do 880 i = 1 , 12
                  top = rhotra(i)
                  cval(i) = top
                  cval(26-i) = -top
 880            continue
               cval(13) = 0.0d0
               else
c density
               nc = 14
               do 30 j = 1 , nc
                  cval(j) = rhotot(j)
 30            continue
               endif
            elseif(ict.eq.2)then
c mo
               nc = 25
               do 60 i = 1 , 12
                  top = rhomo(i)
                  cval(i) = top
                  cval(26-i) = -top
 60            continue
               cval(13) = 0.0d0
            else if(ict.eq.3)then
c atom difference
               nc = 25
               do 80 i = 1 , 12
                  top = rhodif(i)
                  cval(i) = top
                  cval(26-i) = -top
 80            continue
               cval(13) = 0.0d0
            else if(ict.eq.4)then
               nc = 25
               do 100 i = 1 , 12
                  top = rhopot(i)
                  cval(i) = top
                  cval(26-i) = -top
 100           continue
               cval(13) = 0.0d0
            else
               call caserr2
     &        ('no default contours available for requested data type')
            endif
         endif
c
c put contour list on ed7
c
         if(nc.ne.0)then
            iblk = ibl7la
            call wrt3(cval,nc,iblk,num8)
            ibl7la = ibl7la + lensec(nc)
            ipcont(nplot)=iblk
         endif
         ncont(nplot) = nc
c
         pdata(1,nplot)=scamax
         pdata(2,nplot)=scamin
         pdata(3,nplot)=facmax
         pdata(4,nplot)=facmin
         pdata(5,nplot)=anga
         pdata(6,nplot)=angb
         pdata(7,nplot)=dist3d
         jrec = jrec - 1
         return
      endif
      goto 10
      end
      subroutine popd(frocc,nomx)
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension frocc(*)
INCLUDE(common/work)
      data zspace,zend,zto/' ','end','to'/
      iorb = 0
 20   continue
      call input
      call inpa(zparam)
      if (zparam.eq.zend) then
c
         if (iorb.le.0) call caserr2(
     +        'no orbitals nominated by occdef directive')
c
         return
      else
         jrec = 0
         call inpf(param)
 30      call inpa(ztest)
c 
         if (ztest.eq.zspace) then
            goto 20
         else
            jrec = jrec - 1
            call inpi(k)
            call inpa(ztest)
            if (ztest.ne.zto) then
               jrec = jrec - 1
               l = k
            else
               call inpi(l)
            end if
            if (k.lt.1 .or. l.lt.k .or. l.gt.nomx) 
     +           call caserr2(
     +          'invalid orbital specified in occdef directive')
            loop = l - k + 1
            iorb = iorb + loop
_IFN1(cuiv)            call vfill(param,frocc(k),1,loop)
_IF1(cu)            call setsto(loop,param,frocc(k))
_IF1(iv)            call setstr(loop,param,frocc(k))
            go to 30
         end if
      end if
c
      end
      subroutine print(n1,n2)
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
INCLUDE(common/symtry)
      common/junk/t(432)
      dimension nn(48)
      dimension tt(3,3,48)
      equivalence(t(1),tt(1,1,1))
      imax = n1 - 1
 20   imin = imax + 1
      imax = imax + 4
      if (imax.gt.n2) imax = n2
      nj = 9*n1 - 8
      do 50 j = 1 , 3
         ni = 0
         do 30 i = imin , imax
            nn(i) = nj + ni
            ni = ni + 9
 30      continue
         do 40 i = imin , imax
            write (iwr,6010) t(nn(i)) , t(nn(i)+1) , t(nn(i)+2)
 40      continue
         nj = nj + 3
 50   continue
      write (iwr,6020)
      if (imax.lt.n2) go to 20
       write(iwr,*)
     +  'ptgrp - group operations in the following range generated:',
     +   n1,n2
       write(iwr,*)
       do 60 it=n1,n2
       write(iwr,900) it,it
       do 70 i=1,3
       write(iwr,901) (tt(j,i,it),j=1,3)
 70    continue
       write(iwr,*)
 60    continue
      return
 6010 format (4x,4(3f10.5,' *'))
 6020 format (/)
 900   format(1x,'Operation no.',i3,
     + ' with respect to the local frame -  t(j,i,',i2,
     + '); j is column index, i is row index')
 901   format(1x,3f16.8)
      end
      subroutine ptgrp(ipr)
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter (maxgro=48)
INCLUDE(common/prints)
INCLUDE(common/fsymas)
INCLUDE(common/atmol3)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/symtry)
INCLUDE(common/transf)
INCLUDE(common/frame)
INCLUDE(common/molsym)
c
c  matrices of group elements, transf. of cartesian p,d,f,g functions
c  432=3*3*48 - t(3,3,48)
c  trans(9*(r-1)) --- new(i)=old(j)*t(j,i,r)
c
      common/junk/t(3*3*maxgro),ptr(3,3*maxgro),
     +            dtr(6,6*maxgro),ftr(10,10*maxgro),gtr(15,15*maxgro)
INCLUDE(common/runlab)
      dimension zgrp(19),zdrc(2)
      data zgrp /'c1','cs','ci','cn','s2n','cnh',
     + 'cnv' ,'dn'  ,'dnh' ,'dnd' ,'cinfv','dinfh','t'   ,
     + 'th'  ,'td'  ,'o'   ,'oh'  ,'i'   ,'ih'  /
      data zdrc /'normal' ,'parallel'/
      data dzero,pt5,done,three /0.0d0,0.5d0,1.0d0,3.0d0/
      data tol /1.0d-10/
      data pi2 /6.28318530717958d0/
c
      nprino = nprint
      iprint = ipr
      if(iprint.ge.2)nprint = 1
      if (oprint(48)) then
         nprint = 1
         iprint = 2
      endif
c
      indmx = locatc(zgrp,19,zgroup)
      if (indmx.eq.0) then
         indmx = 20
      end if
      if (iprint.ge.1)then
         write (iwr,6030) zgroup , jaxis
         write (iwr,6010) (symtag(i),i=1,9) , zsymm
      endif
      if (indmx.gt.19) then
         call caserr2('illegal point group specified')
      end if
 20   if (indmx.ne.18 .and. indmx.ne.19) then
         if (indmx.le.3) go to 90
         if (indmx.eq.11 .or. indmx.eq.12) go to 90
c
c     define local frame
c     read in principal axis   ( 1 card )
c     read in x-local axis   ( 1 card )
c     default option - local frame identical to master frame
c
         p0 = symtag(1)
         q0 = symtag(2)
         r0 = symtag(3)
         p1 = symtag(4)
         q1 = symtag(5)
         r1 = symtag(6)
         rho = dsqrt((p1-p0)**2+(q1-q0)**2+(r1-r0)**2)
         if (rho.gt.tol) then
            p2 = symtag(7)
            q2 = symtag(8)
            r2 = symtag(9)
            zdirec = zsymm
         else
            p0 = dzero
            q0 = dzero
            r0 = dzero
            p1 = dzero
            q1 = dzero
            q2 = dzero
            r2 = dzero
            r1 = done
            p2 = done
            zdirec = zdrc(2)
            rho = done
         end if
         if (zdirec.ne.zdrc(1)) zdirec = zdrc(2)
         w1 = (p1-p0)/rho
         w2 = (q1-q0)/rho
         w3 = (r1-r0)/rho
         ww = w1*w1 + w2*w2 + w3*w3
         p02 = p2 - p0
         q02 = q2 - q0
         r02 = r2 - r0
         rho = (w1*p02+w2*q02+w3*r02)/ww
         dum = rho*w1
         p0 = p0 + dum
         p02 = p02 - dum
         dum = rho*w2
         q0 = q0 + dum
         q02 = q02 - dum
         dum = rho*w3
         r0 = r0 + dum
         r02 = r02 - dum
         uu = (p02*p02+q02*q02+r02*r02)
         u = dsqrt(uu)
         u1 = p02/u
         u2 = q02/u
         u3 = r02/u
         v3 = w1*u2 - w2*u1
         v2 = w3*u1 - w1*u3
         v1 = w2*u3 - w3*u2
         if (zdirec.ne.zdrc(2)) then
            dum = u1
            u1 = v1
            v1 = -dum
            dum = u2
            u2 = v2
            v2 = -dum
            dum = u3
            u3 = v3
            v3 = -dum
         end if
         if (nprint.ge.2) then
            write (iwr,6040) p0 , q0 , r0 , u1 , v1 , w1 , 
     +                       u2 , v2 , w2 , u3 , v3 , w3
         end if
         if (indmx.ge.13) go to 90
c
c     rotation about principal axis
c
         nn = 0
         n = jaxis
         alpha = dzero
         alph = pi2/dfloat(n)
 30      nn = nn + 1
         if (nn.gt.n) then
c
c     end of group 4
c
            nt = n
            ii = 9*nt
            if (nprint.ge.2) then
               write (iwr,6050)
               n1 = 1
               n2 = jaxis
               call print(n1,n2)
            end if
            if (indmx.eq.4) go to 170
            if (indmx.eq.5) go to 150
            if (indmx.eq.7) then
c
c     group 7
c     sigma-v is the (x-z) plane of local frame
c
               nn = 0
 40            nn = nn + 1
               if (nn.gt.nt) then
                  nt = nt + nt
                  ii = 9*nt
c
c     end of group 7
c
                  if (nprint.ge.2) then
                     write (iwr,6090)
                     n1 = n2 + 1
                     n2 = n2 + jaxis
                     call print(n1,n2)
                  end if
                  go to 170
               else
                  i = ii + 9*(nn-1)
                  t(i+1) = t(i+1-ii)
                  t(i+2) = -t(i+2-ii)
                  t(i+3) = t(i+3-ii)
                  t(i+4) = t(i+4-ii)
                  t(i+5) = -t(i+5-ii)
                  t(i+6) = t(i+6-ii)
                  t(i+7) = t(i+7-ii)
                  t(i+8) = -t(i+8-ii)
                  t(i+9) = t(i+9-ii)
                  go to 40
               end if
            else if (indmx.ne.6 .and. indmx.ne.9) then
               nn = 0
            else
c
c     sigma-h plane  equation (z=0) in local frame
c
               nn = 0
 50            nn = nn + 1
               if (nn.gt.nt) then
                  nt = nt + nt
                  ii = 9*nt
                  if (nprint.ge.2) then
                     write (iwr,6060)
                     n1 = n2 + 1
                     n2 = n2 + jaxis
                     call print(n1,n2)
                  end if
c
c     end of group 6
c
                  if (indmx.eq.6) go to 170
c
c     one cp2 axis is the x-axis of the local frame
c     group 8 , 9 ,10
c
                  nn = 0
               else
c
c     group 6 0r 9
c
                  i = ii + 9*(nn-1)
                  do 60 j = 1 , 8
                     t(i+j) = t(i+j-ii)
 60               continue
                  t(i+9) = -t(i+9-ii)
                  go to 50
               end if
            end if
         else
            cosa = dcos(alpha)
            sina = dsin(alpha)
            i = 9*(nn-1)
            t(i+1) = cosa
            t(i+5) = cosa
            t(i+2) = -sina
            t(i+4) = sina
            t(i+3) = dzero
            t(i+6) = dzero
            t(i+7) = dzero
            t(i+8) = dzero
            t(i+9) = done
            alpha = alpha + alph
            go to 30
         end if
      else
         call caserr2('illegal point group specified')
         go to 20
      end if
 70   nn = nn + 1
      if (nn.gt.nt) then
         nt = nt + nt
         ii = 9*nt
         if (nprint.ge.2) then
            write (iwr,6070)
            n1 = n2 + 1
            n2 = n2 + jaxis
            call print(n1,n2)
            if (indmx.eq.9) then
               write (iwr,6130)
               n1 = n2 + 1
               n2 = n2 + jaxis
               call print(n1,n2)
            end if
         end if
c
c     end of group 8 and 9
c
         if (indmx.ne.8 .and. indmx.ne.9) then
c
c     dnd group . equation of plane sigma-d is -
c     sin(alph/4)*x-cos(alph/4)*y=0
c     the x-axis is the cp2 axis.
c
c     group 10
c
            beta = pt5*alph
            cosa = dcos(beta)
            sina = dsin(beta)
            nn = 0
 80         nn = nn + 1
            if (nn.gt.nt) then
               nt = nt + nt
               ii = 9*nt
               if (nprint.ge.2) then
                  write (iwr,6080)
                  n1 = n2 + 1
                  n2 = n2 + jaxis
                  call print(n1,n2)
                  write (iwr,6140)
                  n1 = n2 + 1
                  n2 = n2 + jaxis
                  call print(n1,n2)
               end if
            else
               i = ii + 9*(nn-1)
               t(i+1) = cosa*t(i+1-ii) + sina*t(i+2-ii)
               t(i+2) = sina*t(i+1-ii) - cosa*t(i+2-ii)
               t(i+3) = t(i+3-ii)
               t(i+4) = cosa*t(i+4-ii) + sina*t(i+5-ii)
               t(i+5) = sina*t(i+4-ii) - cosa*t(i+5-ii)
               t(i+6) = t(i+6-ii)
               t(i+7) = cosa*t(i+7-ii) + sina*t(i+8-ii)
               t(i+8) = sina*t(i+7-ii) - cosa*t(i+8-ii)
               t(i+9) = t(i+9-ii)
               go to 80
            end if
         end if
      else
         i = ii + 9*(nn-1)
         t(i+1) = t(i+1-ii)
         t(i+2) = -t(i+2-ii)
         t(i+3) = -t(i+3-ii)
         t(i+4) = t(i+4-ii)
         t(i+5) = -t(i+5-ii)
         t(i+6) = -t(i+6-ii)
         t(i+7) = t(i+7-ii)
         t(i+8) = -t(i+8-ii)
         t(i+9) = -t(i+9-ii)
         go to 70
      end if
      go to 170
 90   t(1) = done
      t(5) = done
      t(9) = done
      t(2) = dzero
      t(3) = dzero
      t(4) = dzero
      t(6) = dzero
      t(7) = dzero
      t(8) = dzero
      if (indmx.eq.1) then
         nt = 1
         p0 = dzero
         q0 = dzero
         r0 = dzero
         u1 = done
         v2 = done
         w3 = done
         u2 = dzero
         u3 = dzero
         v1 = dzero
         v3 = dzero
         w1 = dzero
         w2 = dzero
         go to 170
      else if (indmx.eq.2) then
c
c     cs symmetry group
c     the 3 points 1,2,3 define sigma-h plane
c
         p1 = symtag(1)
         q1 = symtag(2)
         r1 = symtag(3)
         p2 = symtag(4)
         q2 = symtag(5)
         r2 = symtag(6)
         rho = (p2-p1)**2 + (q2-q1)**2 + (r2-r1)**2
         if (rho.gt.tol) then
c
            p3 = symtag(7)
            q3 = symtag(8)
            r3 = symtag(9)
         else
c
c     default option - plane is the (x,y) plane
c
            p1 = dzero
            q1 = dzero
            r1 = dzero
            q2 = dzero
            r2 = dzero
            p3 = dzero
            r3 = dzero
            p2 = done
            q3 = done
         end if
         nt = 2
         w1 = (q2-q1)*(r3-r1) - (q3-q1)*(r2-r1)
         w2 = (r2-r1)*(p3-p1) - (r3-r1)*(p2-p1)
         w3 = (p2-p1)*(q3-q1) - (p3-p1)*(q2-q1)
         rho = dsqrt(w1*w1+w2*w2+w3*w3)
         w1 = w1/rho
         w2 = w2/rho
         w3 = w3/rho
         u1 = p2 - p1
         u2 = q2 - q1
         u3 = r2 - r1
         rho = dsqrt(u1*u1+u2*u2+u3*u3)
         u1 = u1/rho
         u2 = u2/rho
         u3 = u3/rho
         v1 = w2*u3 - w3*u2
         v2 = w3*u1 - w1*u3
         v3 = w1*u2 - w2*u1
         p0 = p1
         q0 = q1
         r0 = r1
         t(10) = done
         t(14) = done
         t(18) = -done
         t(11) = dzero
         t(12) = dzero
         t(13) = dzero
         t(15) = dzero
         t(16) = dzero
         t(17) = dzero
         if (nprint.ge.2) then
            write (iwr,6110) w1 , w2 , w3
            write (iwr,6120) u1 , v1 , w1 , u2 , v2 , w2 , u3 , v3 , w3
         end if
         go to 170
      else if (indmx.eq.3) then
c
c     ci symmetry group
c     center of inversion is (x0,y0,z0)
c
         p0 = symtag(1)
         q0 = symtag(2)
         r0 = symtag(3)
         if (nprint.ge.2) write (iwr,6100) p0 , q0 , r0
         t(10) = -done
         t(14) = -done
         t(18) = -done
         t(11) = dzero
         t(12) = dzero
         t(13) = dzero
         t(15) = dzero
         t(16) = dzero
         t(17) = dzero
         nt = 2
         u1 = done
         v2 = done
         w3 = done
         u2 = dzero
         u3 = dzero
         v1 = dzero
         v3 = dzero
         w1 = dzero
         w2 = dzero
         go to 170
      else if (indmx.eq.11 .or. indmx.eq.12) then
         write (iwr,6020)
         call caserr2(
     +   'invalid point group specified for linear molecule')
      else
c
c     t group and others containing a subgroup t -
c     local x,y,z are the c2 axes
c
         do 100 i = 10 , 36
            t(i) = dzero
 100     continue
         t(10) = done
         t(23) = done
         t(36) = done
         t(14) = -done
         t(18) = -done
         t(19) = -done
         t(27) = -done
         t(28) = -done
         t(32) = -done
         do 110 ii = 5 , 12
            i = 9*(ii-1)
            j = 9*(ii-5)
            t(i+1) = t(j+7)
            t(i+2) = t(j+8)
            t(i+3) = t(j+9)
            t(i+4) = t(j+1)
            t(i+5) = t(j+2)
            t(i+6) = t(j+3)
            t(i+7) = t(j+4)
            t(i+8) = t(j+5)
            t(i+9) = t(j+6)
 110     continue
         nt = 12
         if (indmx.ne.13) then
            if (indmx.eq.14) then
c
c     th group
c     expand group by taking direct product with ci
c
               i = 9*nt
               do 120 j = 1 , i
                  t(j+i) = -t(j)
 120           continue
               nt = nt + nt
            else
               if (indmx.eq.15) then
c
c     td group is direct product of t and a reflection in a
c     plane ( equation of the plane   x=y  )
c
                  sign = done
               else
c
c     octahedral group is direct product of t and a c4 rotation
c     about z axis
c
                  sign = -done
               end if
               do 130 ii = 13 , 24
                  i = 9*(ii-1)
                  j = 9*(ii-13)
                  t(i+1) = t(j+4)*sign
                  t(i+2) = t(j+5)*sign
                  t(i+3) = t(j+6)*sign
                  t(i+4) = t(j+1)
                  t(i+5) = t(j+2)
                  t(i+6) = t(j+3)
                  t(i+7) = t(j+7)
                  t(i+8) = t(j+8)
                  t(i+9) = t(j+9)
 130           continue
               nt = 24
               if (indmx.eq.17) then
c
c     oh group is direct product of o and ci
c
                  i = 9*nt
                  do 140 j = 1 , i
                     t(j+i) = -t(j)
 140              continue
                  nt = 48
               end if
            end if
         end if
         go to 170
      end if
 150  nn = 0
      beta = pt5*alph
      cosb = dcos(beta)
      sinb = dsin(beta)
 160  nn = nn + 1
      if (nn.gt.nt) then
         nt = nt + nt
         ii = 9*nt
         if (nprint.ge.2) then
            write (iwr,6150)
            n1 = n2 + 1
            n2 = n2 + jaxis
            call print(n1,n2)
         end if
      else
c
c     s2n group
c     the plane of symmetry for the improper rotation
c     is the (x,y) plane of the local frame
c
         i = ii + 9*(nn-1)
         t(i+1) = cosb*t(i+1-ii) + sinb*t(i+2-ii)
         t(i+2) = -sinb*t(i+1-ii) + cosb*t(i+2-ii)
         t(i+3) = -t(i+3-ii)
         t(i+4) = cosb*t(i+4-ii) + sinb*t(i+5-ii)
         t(i+5) = -sinb*t(i+4-ii) + cosb*t(i+5-ii)
         t(i+6) = -t(i+6-ii)
         t(i+7) = cosb*t(i+7-ii) + sinb*t(i+8-ii)
         t(i+8) = -sinb*t(i+7-ii) + cosb*t(i+8-ii)
         t(i+9) = -t(i+9-ii)
         go to 160
      end if
c
c
c
c     find the inverse transformations
c
 170  do 190 itr = 1 , nt
         nn = 9*(itr-1)
         do 180 it = 1 , nt
            ii = 9*(it-1)
            test = t(nn+1)*t(ii+1) + t(nn+2)*t(ii+4) + t(nn+3)*t(ii+7)
     +             + t(nn+4)*t(ii+2) + t(nn+5)*t(ii+5) + t(nn+6)*t(ii+8)
     +             + t(nn+7)*t(ii+3) + t(nn+8)*t(ii+6) + t(nn+9)*t(ii+9)
     +             - three
            if (dabs(test).le.tol) then
               invt(itr) = it
               go to 190
            end if
c
 180     continue
c
 190  continue
c
c
c     ----- generate transformation matrices for p, d, basis functions -
c
      call spdtr
      nprint = nprino
      return
 6010 format (' symmetry points :'//' point 1 : ',3f12.7/' point 2 : ',
     +        3f12.7/' point 3 : ',3f12.7//' directional parameter - ',
     +        a8/)
 6020 format (' linear molecule , point group is cinfv or dinfh ',/,
     +        ' please use group cnv or dnh...')
 6030 format (/1x,104('-')//40x,18('*')/40x,'molecular symmetry'/40x,
     +        18('*')//' molecular point group    ',
     +        a8/' order of principal axis  ',i2/)
 6040 format (/,' the origin of the local frame is at x =  ',f10.5,
     +        ' y = ',f10.5,' z = ',f10.5,/,
     +        ' direcor cosines of the new axes ,'/,34x,3(5x,f10.5),/,
     +        34x,3(5x,f10.5),/,34x,3(5x,f10.5))
 6050 format ('  rotations about principal axis')
 6060 format (' sigma-h followed by rotations')
 6070 format (' c2 followed by rotations ')
 6080 format (' sigma-d followed by rotations')
 6090 format (' sigma-v followed by rotations')
 6100 format (/,10x,' center of symmetry at x = ',f10.5,' y = ',f10.5,
     +        ' z = ',f10.5)
 6110 format (/,' plane of symmetry defined by its normal u = ',f10.5,
     +        ' v = ',f10.5,' w = ',f10.5)
 6120 format (/,10x,3f15.9,/,10x,3f15.9,/,10x,3f15.9)
 6130 format (' c2 followed by sigma-h followed by rotations')
 6140 format (' sigma-d followed by c2 followed by rotations')
 6150 format (' s2n rotation followed by rotations')
      end
      subroutine ptgrp2(maxap3,a,atmchg,natoms,iprint,idump,
     $         mgroup,naxis,trvec,nosyme,core)
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
c
c     given the coordinates, c, and the atomic numbers or masses,
c     atmchg, of the natoms atoms in a molecule, determine the point
c     group and impose a standard orientation in cartesian space.  the
c     coordinates of the re-oriented molecule are returned in a and
c     the schonflies symbol for the point group is placed in ngrp.
c     b and d are scratch coordinate arrays while iprint and idump
c     are print switches.
c
c
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter (maxat2 = maxat+maxat)
INCLUDE(common/iofile)
      common/junk/c(maxat,3),b(maxat3,3),d(maxat3,3),
     *npop(maxat2),nset(maxat2),t(3,3),v(3)
c
INCLUDE(common/tol)
INCLUDE(common/molsym)
      dimension a(maxap3,3)
      dimension atmchg(*),  trvec(3)
      dimension core(*)
      dimension prmom(3), praxes(3,3)
c
      data dzero,done,two,four /0.0d0, 1.0d0, 2.0d0, 4.0d0/
c
      piovr4 = datan(done)
      pi = four*piovr4
      halfpi = two*piovr4
c
c     add three dummy atoms to trace the rotations of the molecule.
c
      numatm = natoms + 3
      do 20 iat = 1 , natoms
         a(iat,1) = c(iat,1)
         a(iat,2) = c(iat,2)
         a(iat,3) = c(iat,3)
 20   continue
      do 40 iat = 1 , 3
         do 30 ixyz = 1 , 3
            a(natoms+iat,ixyz) = dzero
 30      continue
 40   continue
      a(natoms+1,1) = done
      a(natoms+2,2) = done
      a(natoms+3,3) = done
c
c     all symmetry elements must pass through the molecules charge
c     center.  translate the molecule so that this unique point is
c     at the origin of the fixed cartesian coordinate system.
c
      call center(maxap3,natoms,a,atmchg,trvec)
      trvec(1) = -trvec(1)
      trvec(2) = -trvec(2)
      trvec(3) = -trvec(3)
      if (iprint.ne.0) write (iwr,6010) (trvec(i),i=1,3)
      do 50 iat = 1 , natoms
         a(iat,1) = a(iat,1) + trvec(1)
         a(iat,2) = a(iat,2) + trvec(2)
         a(iat,3) = a(iat,3) + trvec(3)
 50   continue
c
c     calculate the principal moments and axes of charge.
c
      call secmom(maxap3,natoms,a,atmchg,prmom,praxes)
      if (iprint.ne.0) write (iwr,6020) (prmom(i),i=1,3) ,
     +                        ((praxes(j,i),i=1,3),j=1,3)
c
c     if the first moment is zero and the other two are equal,
c     the molecule is linear.
c
      tol3=toler2
      if(isymtl.ne.0)then
         tol3 = 10.0d0**(-isymtl)*dabs(prmom(1) + prmom(2) + prmom(3))
      endif
c
      if (dabs(prmom(1)).gt.tol3 .or. dabs(prmom(3)-prmom(2)).gt.tol3)
     +    then
c
c     classify the molecule as being a either a spherical top (itop=3),
c     a symmetric top (itop=2), or an asymmetric top(itop=1).  each
c     type of top will be handled seperately.
c
         if (idump.ne.0) write (iwr,6040)
         itop = 0
         tst1 = prmom(2) - prmom(3)
         tst2 = prmom(1) - prmom(3)
         tst3 = prmom(1) - prmom(2)
         if (dabs(tst1).lt.tol3) itop = itop + 1
         if (dabs(tst2).lt.tol3) itop = itop + 1
         if (dabs(tst3).lt.tol3) itop = itop + 1
         if (itop.ne.3) itop = itop + 1
         go to (60,140,150) , itop
      else
c
c     place the molecule on the z axis and distinguish between
c     d*h and c*v.
c
         if (idump.ne.0) write (iwr,6030)
         call putt(maxap3,a,b,t,praxes(1,1),numatm,3)
         call qraxis(maxap3,a,b,natoms,atmchg,3)
         call reflct(maxap3,a,b,natoms,t,3)
         call equiv(maxap3,a,b,atmchg,natoms,itst)
c
c ----- strictly d*h ... treat as d2h for gamess
c
         if (itst.eq.0) then
c
c ----- strictly cinfv ... treat as c2v for gamess
c
            mgroup = 11
            naxis = 2
         else
            mgroup = 12
            naxis = 2
         end if
         go to 190
      end if
c
c     *------------------------*
c      asymmetric top molecules
c     *------------------------*
c
c     these molecules can have no axes of order greater than 2.  thus
c     the possible point groups are:  d2h, d2, c2v, c2h, c2, ci, cs,
c     and c1.
c
c     align the principal axes with the cartesian axes.
c
 60   if (idump.ne.0) write (iwr,6050)
      call putt(maxap3,a,b,t,praxes(1,3),numatm,3)
      call qraxis(maxap3,a,b,natoms,atmchg,3)
      call secmom(maxap3,natoms,a,atmchg,prmom,praxes)
      theta = halfpi
      if (dabs(praxes(2,2)).gt.toler2)
     +    theta = -datan(praxes(1,2)/praxes(2,2))
      call rotate(maxap3,a,b,numatm,t,3,theta)
      call movez(maxap3,b,a,numatm)
      call qraxis(maxap3,a,b,natoms,atmchg,2)
      call qrptst(maxap3,a,natoms,ixyz)
      if (ixyz.ne.0) call qrplan(maxap3,a,b,atmchg,numatm,prmom,praxes,
     +                           ixyz)
c
c     test z and y for c2.
c         if both are c2 then test for an inversion center.
c              if yes then d2h.
c              if no  then d2.
c         if only z is c2 go to 200.
c         if only y is c2, rotate y to z and go to 200.
c         if neither is c2, test x for c2.
c              if yes then rotate x to z and go to 200.
c              in no  then continue at 150.
c
      call rotate(maxap3,a,b,natoms,t,3,pi)
      call equiv(maxap3,a,b,atmchg,natoms,iztst)
      call rotate(maxap3,a,b,natoms,t,2,pi)
      call equiv(maxap3,a,b,atmchg,natoms,iytst)
      itst = 2*iztst + iytst + 1
      go to (90,80,130,70) , itst
c
c     the molecule is either d2 or d2h.
c
 70   call inversion(maxap3,a,b,natoms,t)
      call equiv(maxap3,a,b,atmchg,natoms,itst)
      mgroup = 8
      naxis = 2
      if (itst.ne.0) then
         mgroup = 9
         call qrd2h(maxap3,a,b,natoms,atmchg,core)
      end if
      go to 190
c
c     the y axis is c2 but the z axis is not.
c
 80   call rotate(maxap3,a,b,numatm,t,1,halfpi)
      call qraxis(maxap3,b,a,natoms,atmchg,3)
      call qrplan(maxap3,b,a,atmchg,numatm,prmom,praxes,3)
      call movez(maxap3,b,a,numatm)
      go to 130
c
c     neither y nor z axes are c2.  check x.
c
 90   call rotate(maxap3,a,b,natoms,t,1,pi)
      call equiv(maxap3,a,b,atmchg,natoms,itst)
      if (itst.eq.0) then
c
c     an asymmetric top molecule has no c2 axes.  the remaining
c     possibilities are cs, ci, and c1.  if cs, the symmetry plane
c     is made coincident with the xy plane.
c
         call inversion(maxap3,a,b,natoms,t)
         call equiv(maxap3,a,b,atmchg,natoms,itst)
         if (itst.eq.0) then
c
            do 100 i = 1 , 3
               v(i) = dzero
 100        continue
            do 110 ixyz = 1 , 3
               call reflct(maxap3,a,b,natoms,t,ixyz)
               call equiv(maxap3,a,b,atmchg,natoms,itst)
               if (itst.ne.0) then
                  v(ixyz) = done
                  call putt(maxap3,a,b,t,v,numatm,3)
                  call qraxis(maxap3,a,b,natoms,atmchg,3)
                  call qrplan(maxap3,a,b,atmchg,numatm,prmom,praxes,3)
                  go to 120
               end if
 110        continue
c
            mgroup = 1
         else
            mgroup = 3
         end if
         go to 190
      else
         call rotate(maxap3,a,b,numatm,t,2,halfpi)
         call qraxis(maxap3,b,a,natoms,atmchg,3)
         call qrplan(maxap3,b,a,atmchg,numatm,prmom,praxes,3)
         call movez(maxap3,b,a,numatm)
         go to 130
      end if
c
 120  mgroup = 2
      call qrcn(maxap3,a,b,d,d,atmchg,npop,nset,natoms,idump)
      go to 190
c
 130  call reflct(maxap3,a,b,natoms,t,3)
      call equiv(maxap3,a,b,atmchg,natoms,itst)
      if (itst.eq.0) then
c
         call reflct(maxap3,a,b,natoms,t,2)
         call equiv(maxap3,a,b,atmchg,natoms,itst)
         if (itst.eq.0) then
c
            mgroup = 4
            naxis = 2
            call qrcn(maxap3,a,b,d,d,atmchg,npop,nset,natoms,idump)
         else
            mgroup = 7
            naxis = 2
            call qrc2v(maxap3,a,b,natoms,atmchg)
         end if
      else
         mgroup = 6
         naxis = 2
         call qrcn(maxap3,a,b,d,d,atmchg,npop,nset,natoms,idump)
      end if
      go to 190
c
c     *-----------------------*
c      symmetric top molecules
c     *-----------------------*
c
c     these molecules can belong to any axial point group, thus
c     only the cubic point groups (t, td, th, o, oh, i, ih) are
c     impossible.  however, execpt in rare cases the unique axis
c     is a rotation axis of order 3 or greater.  this routine is not
c     coded to identify the point group of these rare species.
c
c     align the unique axis with the z axis.
c
 140  if (idump.ne.0) write (iwr,6060)
      if (dabs(tst1).lt.tol3) ixyz = 1
      if (dabs(tst2).lt.tol3) ixyz = 2
      if (dabs(tst3).lt.tol3) ixyz = 3
c
c     entry point for accidental spherical top
c
 301  continue
c
      call putt(maxap3,a,b,t,praxes(1,ixyz),numatm,3)
      call qraxis(maxap3,a,b,natoms,atmchg,3)
c
c     test z for cn.
c         if n>1 then goto 330.
c         else quit.
c
      call findcn(maxap3,natoms,a,b,d,atmchg,npop,nset,3,norder)
      if (norder.gt.1) then
c
c     the unique axis in a symmetric top molecule is a proper rotation
c     axis or order norder and is aligned with the cartesian z axis.
c
c     test z for s2n.
c         if no then continue.
c         else test for n dihedral planes.
c             if yes  then dnd.
c             if no   then s2n.
c     test for n c2 axes in the xy plane.
c         if no then continue at 400.
c         else test for a horizontal plane.
c             if yes  then dnh.
c             if no   then dn.
c
         theta = pi/norder
         call rotate(maxap3,a,b,natoms,t,3,theta)
         call reflct(maxap3,b,d,natoms,t,3)
         call equiv(maxap3,a,d,atmchg,natoms,itst)
         if (itst.eq.0) then
c
            call findc2(maxap3,a,b,d,npop,nset,atmchg,natoms,itst)
            if (itst.eq.0) then
c
c     for a symmetric top molecule the possible point groups
c     have been limited to cnv, cnh, and cn.
c
               call findv(maxap3,a,b,d,natoms,npop,nset,atmchg,itst)
               if (itst.eq.0) then
c
                  call reflct(maxap3,a,b,natoms,t,3)
                  call equiv(maxap3,a,b,atmchg,natoms,itst)
                  mgroup = 4
                  naxis = norder
                  if (itst.ne.0) mgroup = 6
                  call qrcn(maxap3,a,b,d,d,atmchg,npop,nset,natoms,
     +                      idump)
               else
                  mgroup = 7
                  naxis = norder
                  call qrdn(maxap3,a,b,d,atmchg,npop,nset,natoms,norder,
     +                      idump)
                  if (norder.eq.2) call qrc2v(maxap3,a,b,natoms,atmchg)
               end if
            else
               call reflct(maxap3,a,b,natoms,t,3)
               call equiv(maxap3,a,b,atmchg,natoms,itst)
               if (itst.eq.0) then
c
                  mgroup = 8
                  naxis = norder
                  call qrdn(maxap3,a,b,d,atmchg,npop,nset,natoms,norder,
     +                      idump)
               else
                  mgroup = 9
                  naxis = norder
                  call qrdn(maxap3,a,b,d,atmchg,npop,nset,natoms,norder,
     +                      idump)
                  if (norder.eq.2) call qrd2h(maxap3,a,b,natoms,atmchg,
     +                core)
               end if
            end if
         else
            call findv(maxap3,a,b,d,natoms,npop,nset,atmchg,itst)
            if (itst.eq.0) then
c
               mgroup = 5
               naxis = norder
               call qrcn(maxap3,a,b,d,d,atmchg,npop,nset,natoms,idump)
            else
               mgroup = 10
               naxis = norder
               call qrdn(maxap3,a,b,d,atmchg,npop,nset,natoms,norder,
     +                   idump)
            end if
         end if
      else
         nosyme = 1
         write (iwr,6090)
      end if
      go to 190
c
c     *-----------------------*
c      spherical top molecules
c     *-----------------------*
c
c     only the cubic point groups: t, td, th, o, oh, i, and, ih are
c     possible.  no provision is made in the subsequent code for the
c     the possibility that a spherical top molecule may belong to any
c     other point group.
c
c     find the highest order proper rotation axis and align it with
c     the z-axis.
c
 150  if (iprint.ne.0) write (iwr,6070)
      call sphere(maxap3,natoms,a,b,d,atmchg,nset,npop,norder,idump)
      if (norder.ne.0) then
         ihop = norder - 2
         go to (160,170,180) , ihop
      else
         write (iwr,6080)
         nosyme = 1
         go to 190
      end if
c
c     a spherical top molecule has a two-fold axis aligned with
c     z and is t, td, or th.
c
c     test for a center of inversion.
c         if yes then th.
c         else test for a vertical plane.
c             if yes then td.
c             else t.
c
 160  call inversion(maxap3,a,b,natoms,t)
      call equiv(maxap3,a,b,atmchg,natoms,itst)
      if (itst.eq.0) then
c
         call findv(maxap3,a,b,d,natoms,npop,nset,atmchg,itst)
         mgroup = 13
         if (itst.ne.0) then
            mgroup = 15
            call rotate(maxap3,a,b,numatm,t,3,piovr4)
            call movez(maxap3,b,a,numatm)
         end if
      else
         mgroup = 14
      end if
      call qrdn(maxap3,a,b,d,atmchg,npop,nset,natoms,2,idump)
      go to 190
c
c     a spherical top molecule has a four-fold axis aligned with z and
c     is either o or oh.
c
c     test for a center of inversion.
c         if yes then oh.
c         else o.
c
 170  call inversion(maxap3,a,b,natoms,t)
      call equiv(maxap3,a,b,atmchg,natoms,itst)
      mgroup = 16
      if (itst.ne.0) mgroup = 17
c try S8 - this could be d4d accidental - o is very rare group
      if (mgroup.eq.16) then
      call rotate(maxap3,a,b,natoms,t,3,piovr4)
      call reflct(maxap3,b,d,natoms,t,3)
      call equiv(maxap3,a,d,atmchg,natoms,itst)
      if(itst.eq.1) then
      write(iwr,6085) 
      ixyz=3
      goto 301
      endif
      endif
c
      call qrdn(maxap3,a,b,d,atmchg,npop,nset,natoms,2,idump)
      go to 190
c
c     a spherical top molecule has a five-fold axis aligned with z and
c     is either i or ih.
c
c     test for a center of inversion.
c         if yes then ih.
c         else i.
c
 180  call inversion(maxap3,a,b,natoms,t)
      call equiv(maxap3,a,b,atmchg,natoms,itst)
      mgroup = 18
      if (itst.ne.0) then
         mgroup = 19
         call qrdn(maxap3,a,b,d,atmchg,npop,nset,natoms,2,idump)
      else
         call qrcn(maxap3,a,b,d,d,atmchg,npop,nset,natoms,idump)
      end if
c
c   exit.
c   if requested, calculate and print the moments of charge for the
c   reoriented molecule.
c
 190  continue
c
c   check coordinates against old points
      call chekpp(maxap3,a,b,d,natoms,numatm,t)
c
      call secmom(maxap3,natoms,a,atmchg,prmom,praxes)
      do 2010 loop=1,3
 2010 prmoms(loop)=prmom(loop)
      if (iprint.ne.0) write (iwr,6020) (prmom(i),i=1,3) ,
     +                        ((praxes(j,i),i=1,3),j=1,3)
      return
c
 6010 format (1x,'ptgrp-- translation vector:',3f12.6)
 6020 format (1x,'ptgrp-- principal moments and axes of charge:'/1x,
     +        '        moments:',3e14.7,/1x,'        axes   :',
     +        3f14.6/17x,3f14.6/17x,3f14.6)
 6030 format (1x,'ptgrp-- the molecule is linear')
 6040 format (1x,'ptgrp-- the molecule is not linear')
 6050 format (1x,'ptgrp-- the molecule is an asymmetric top')
 6060 format (1x,'ptgrp-- the molecule is a symmetric top')
 6070 format (1x,'ptgrp-- the molecule is a spherical top')
 6080 format (1x,'ptgrp-- the molecule is an accidental spherical top',
     +        /1x,'ptgrp-- symmetry turned off')
 6085 format(/1x,
     + 'ptgrp2 -- warning: the molecule is probably D4d but'/1x,
     + 'accidentally a spherical top'/1x,
     + 'ptgrp2 -- trying to handle as symmetrical top, but if you '/1x,
     + 'have problems, better to change the tolerance '/1x,
     + '(second parameter after symm) or perturb the geometry'/)
 6090 format (1x,'ptgrp-- the molecule is an accidental symmetric top',
     +        /1x,'ptgrp-- symmetry turned off')
      end
      subroutine putb(xstr,lenin,xbb,nbb)
c
c
c     --- copies a string from instr into ibb
c     --- length of string is lenin and current
c     --- cursor in ibb is at nbb
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension xstr(*),xbb(*)
      in = 0
      do 20 i = 1 , lenin
         in = in + 1
         nbb = nbb + 1
         xbb(nbb) = xstr(in)
 20   continue
      return
c
      end
      subroutine putf(nz,lbl,lalpha,lbeta,nvar,f,force,iprint)
c
c
c***********************************************************************
c     routine to add force contributions over internal coordinates
c     into the vector over actual variables.
c***********************************************************************
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
      dimension lbl(*),lalpha(*),lbeta(*),f(*),force(*)
c
      call vclr(force,1,nvar)
      if (nz.ge.2) then
         do 20 i = 2 , nz
            ibl = iabs(lbl(i))
            if (ibl.ne.0) then
               dx = f(i-1)
               if (lbl(i).lt.0) dx = -dx
               force(ibl) = force(ibl) + dx
            end if
 20      continue
c
         if (nz.ge.3) then
            j = nz - 3
            do 30 i = 3 , nz
               ialpha = iabs(lalpha(i))
               if (ialpha.ne.0) then
                  dx = f(i+j)
                  if (lalpha(i).lt.0) dx = -dx
                  force(ialpha) = force(ialpha) + dx
               end if
 30         continue
c
            if (nz.ge.4) then
               j = nz + nz - 6
               do 40 i = 4 , nz
                  ibeta = iabs(lbeta(i))
                  if (ibeta.ne.0) then
                     dx = f(i+j)
                     if (lbeta(i).lt.0) dx = -dx
                     force(ibeta) = force(ibeta) + dx
                  end if
 40            continue
            end if
         end if
      end if
c
      if (iprint.gt.0) then
         write (iwr,6010)
         write (iwr,6020) (i,force(i),i=1,nvar)
      end if
      return
 6010 format (' from putf, contents of force:')
 6020 format (1x,i3,e20.10)
c
      end
c
c-----------------------------------------------------------------------
c
      subroutine getf(nz,lbl,lalpha,lbeta,nvar,f,force,iprint)
c
c
c***********************************************************************
c     inverse of putf (as far as possible, in practice some values
c     will not be substituted back)
c***********************************************************************
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
      dimension lbl(*),lalpha(*),lbeta(*),f(*),force(*)
c
      call vclr(f,1,3*nz)
      if (nz.ge.2) then
         do 20 i = 2 , nz
            ibl = iabs(lbl(i))
            if (ibl.ne.0) then
               dx = force(ibl)
               if (lbl(i).lt.0) dx = -dx
               f(i-1) = dx
            end if
 20      continue
c
         if (nz.ge.3) then
            j = nz - 3
            do 30 i = 3 , nz
               ialpha = iabs(lalpha(i))
               if (ialpha.ne.0) then
                  dx = force(ialpha)
                  if (lalpha(i).lt.0) dx = -dx
                  f(i+j) = dx
               end if
 30         continue
c
            if (nz.ge.4) then
               j = nz + nz - 6
               do 40 i = 4 , nz
                  ibeta = iabs(lbeta(i))
                  if (ibeta.ne.0) then
                     dx = force(ibeta)
                     if (lbeta(i).lt.0) dx = -dx
                     f(i+j) = dx
                  end if
 40            continue
            end if
         end if
      end if
c
      if (iprint.gt.0) then
         write (iwr,6010)
         write (iwr,6020) (i,force(i),i=1,nvar)
      end if
      return
 6010 format (' from get, contents of force:')
 6020 format (1x,i3,e20.10)
c
      end
c
c-----------------------------------------------------------------------
c
      subroutine putt(maxap3,a,b,t,v,natoms,ixyz)
c
c     the n sets of coordinates in a are rotated so that the point
c     specified by v is placed on the ixyz axis.  the axis of rotation
c     is given by the vector product of v with the unit vector defining
c     the axis ixyz.  the angle of rotation is given by the appropriate
c     direction cosine.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension v(*), t(3,*)
      dimension t1(3,3), a(maxap3,3), b(maxap3,3)
c
      data done /1.0d0/
c
c     define the axes i1, i2, and i3 where i1=ixyz:
c            i1:  x  z  y
c            i2:  y  x  z
c            i3:  z  y  x
c     the projections on these (i1, i2, i3) are v1, v2, and v3.
c
      i1 = ixyz
      i2 = 1 + mod(i1,3)
      i3 = 1 + mod(i2,3)
      v1 = v(i1)
      v2 = v(i2)
      v3 = v(i3)
      vnorm = dsqrt(v1*v1+v2*v2+v3*v3)
      if (dabs(dabs(v1)-vnorm).lt.toler) return
c
c    compute the direction cosines and some common factors.
c
      alph = v1/vnorm
      beta = v2/vnorm
      gamm = v3/vnorm
      v2v2 = v2*v2
      v3v3 = v3*v3
      v2233 = done/(v2v2+v3v3)
c
c     form the transformation matrix in the i1, i2, i3 coordinates.
c     this matrix will place the point (v1,v2,v3) on the pos've i1 axis.
c
      t1(1,1) = alph
      t1(1,2) = beta
      t1(1,3) = gamm
      t1(2,1) = -t1(1,2)
      t1(3,1) = -t1(1,3)
      t1(2,3) = v2*v3*(alph-done)*v2233
      t1(3,2) = t1(2,3)
      t1(2,2) = (v2v2*alph+v3v3)*v2233
      t1(3,3) = (v3v3*alph+v2v2)*v2233
c
c     transform to the original coordinate system.
c
      t(i1,i1) = t1(1,1)
      t(i1,i2) = t1(1,2)
      t(i1,i3) = t1(1,3)
      t(i2,i1) = t1(2,1)
      t(i2,i2) = t1(2,2)
      t(i2,i3) = t1(2,3)
      t(i3,i1) = t1(3,1)
      t(i3,i2) = t1(3,2)
      t(i3,i3) = t1(3,3)
c
c     carry out the rotation.
c
      call tform(maxap3,t,a,b,natoms)
      call movez(maxap3,b,a,natoms)
      return
      end
      function qr3mom(maxap3,a,atmchg,natoms,ixyz)
c
c     this function returns the value of the third moment of charge
c     along the ixyz cartesian axis.  note that the distance used in
c     computing the moment is not as usually defined.  rather than
c     being the perpindicular distance from the axis to the point it
c     is the projection of the point onto the reference axis.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension a(maxap3,3), atmchg(*)
c
      data dzero/0.0d0/
c
      qr3mom = dzero
      do 20 iat = 1 , natoms
         qr3mom = qr3mom + atmchg(iat)*a(iat,ixyz)**3
 20   continue
      return
      end
      subroutine putzm(icall,isecz)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
INCLUDE(common/phycon)
INCLUDE(common/runlab)
INCLUDE(common/infob)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
INCLUDE(common/csubch)
INCLUDE(common/molsym)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/restri)
c
      data m100/100/
c
c ... output z-matrix section isecz
c
      if(iacsct(isecz).lt.0) return
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
       len100 = lensec(nw1) + 2*lensec(nw2) + lensec(nw3) + lensec(nw4)
     +        + lensec(nw5) + lensec(nw6) + lensec(nw7) + lensec(nw8)
c
       call secput(isecz,m100,len100,iblkz)
c
       call wrtc(zsymm,nw8,iblkz,idaf)
       call wrt3s(ianz,nw1,idaf)
       if(icall.eq.0) then
          call wrt3s(values,nw2,idaf)
          call wrt3s(values,nw2,idaf)
       else
          iblock = iblkz + lensec(nw8) + lensec(nw1) + lensec(nw2)
          call wrt3(values,nw2,iblock,idaf)
       endif
       call wrtcs(zvar,nw3,idaf)
       call wrt3s(nat,nw4,idaf)
       call wrt3s(nonsym,nw5,idaf)
       call wrt3s(tr,nw6,idaf)
       call wrt3s(toang,nw7,idaf)
c
      return
      end
      subroutine qraxis(maxap3,a,b,natoms,atmchg,ixyz)
c
c     an axis of rotation or a principal axis may be aligned with a
c     cartesian axis in one of two ways.  this routine decides which
c     way by successivly applying the following three tests:
c     1-- the third moment of charge should be positive,
c     2-- the sum of the projections of the atomic coordinates on
c         the axis should be positive, and
c     3-- the first atom with a non-zero projection on the axis
c         should have a positive projection on the axis.
c     if rotation is neccessary in order to meet one of these criteria
c     it shall be a 180 degree rotation about the axis defined below:
c           reference      axis of
c             axis         rotation
c              x              y
c              y              z
c              z              x
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3),b(maxap3,3),atmchg(*)
      dimension t(3,3)
c
      data dzero,done,four/0.0d0,1.0d0,4.0d0/
c
      pi = four*datan(done)
c
c     test the third moment.
c
      test = qr3mom(maxap3,a,atmchg,natoms,ixyz)
      if (dabs(test).lt.toler) then
c
c     test the sum of the projections of the atomic coordinates on
c     the ixyz axis.
c
         test = ddot(natoms,a(1,ixyz),1,a(1,ixyz),1)
         if (dabs(test).lt.toler) then
c
c     find the first atom with a non-zero projection on the axis.
c
            do 20 iat = 1 , natoms
               test = a(iat,ixyz)
               if (dabs(test).gt.toler) go to 30
 20         continue
            return
         else
            if (test.gt.dzero) return
            go to 40
         end if
      else
         if (test.gt.dzero) return
         go to 40
      end if
 30   if (test.gt.dzero) return
c
c     carry out the neccessary rotation.
c
 40   i2 = 1 + mod(ixyz,3)
      numatm = natoms + 3
      call rotate(maxap3,a,b,numatm,t,i2,pi)
      call movez(maxap3,b,a,numatm)
      return
      end
      subroutine qrc2v(maxap3,a,b,natoms,atmchg)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3), atmchg(*),b(maxap3,3)
      dimension t(3,3), e(3)
c
      data done,two/1.0d0,2.0d0/
      data heavy/2.d0/
c
      halfpi = two*datan(done)
      numatm = natoms + 3
c
c     test for planarity.
c
      call qrptst(maxap3,a,natoms,ixyz)
      if (ixyz.eq.2) then
c
         call qryz(maxap3,a,b,natoms,atmchg,ixyz)
         return
      else if (ixyz.eq.1) then
c
c    the molecule is planar and in the yz plane.
c
         call qrplan(maxap3,a,b,atmchg,natoms+3,e,t,1)
         return
      else
c
c     the molecule is non-planar.  compare the number of atoms in
c     the two mirror planes.
c
         numyz = 0
         numxz = 0
         do 20 iat = 1 , natoms
            setx = a(iat,1)
            sety = a(iat,2)
            sxyxy = dsqrt(setx*setx+sety*sety)
            if (sxyxy.ge.toler) then
               if (dabs(setx).lt.toler) numyz = numyz + 1
               if (dabs(sety).lt.toler) numxz = numxz + 1
            end if
 20      continue
         if (numyz.lt.numxz) then
         else if (numyz.eq.numxz) then
c
c     compare the number of heavy atoms in the two mirror planes.
c
            numyz = 0
            numxz = 0
            do 30 iat = 1 , natoms
               if (atmchg(iat).gt.heavy) then
                  setx = a(iat,1)
                  sety = a(iat,2)
                  sxyxy = dsqrt(setx*setx+sety*sety)
                  if (sxyxy.ge.toler) then
                     if (dabs(setx).lt.toler) numyz = numyz + 1
                     if (dabs(sety).lt.toler) numxz = numxz + 1
                  end if
               end if
 30         continue
            if (numyz.lt.numxz) then
            else if (numyz.eq.numxz) then
c
c    the molecule is planar and in the yz plane.
c
               do 40 iat = 1 , natoms
                  setx = a(iat,1)
                  sety = a(iat,2)
                  sxyxy = dsqrt(setx*setx+sety*sety)
                  if (sxyxy.ge.toler) then
                     if (dabs(setx).lt.toler) go to 60
                     if (dabs(sety).lt.toler) go to 50
                  end if
 40            continue
               call qrplan(maxap3,a,b,atmchg,numatm,e,t,3)
               return
            else
               go to 60
            end if
         else
            go to 60
         end if
      end if
 50   call rotate(maxap3,a,b,numatm,t,3,halfpi)
      call movez(maxap3,b,a,numatm)
c
 60   call qraxis(maxap3,b,a,natoms,atmchg,2)
      return
      end
      subroutine qrcn(maxap3,a,b,d,aset,atmchg,npop,nset,natoms,idump)
c
c     this routine orients molecules in the groups cs, cn, sn, cnh,
c     and i.  these point groups have one uniquely defined axis which
c     is coincident with the z cartesian axis.  rotation about this
c     axis, however, does not change the position of any symmetry
c     elements.  thus, this routine rotates the molecule about the
c     z-axis so as to maximize the number of pairs of heavy (non-
c     hydrogen) atoms which are parallel to the y axis.  if there is
c     only one heavy atom or if there is no orientation in which
c     more than one heavy atom pair can be aligned with y, then the
c     key atom as defined in function subroutine orkey is put in the
c     yz plane so as to give it a positive y coordinate.  if two or
c     more orientations give the same number of "bonds" parallel to y
c     then the one which maximizes the y coordinate of the key atom
c     is selected.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
c
      parameter (maxat2=maxat+maxat)
      parameter (maxat4=maxat2+maxat2)
      parameter (maxat8=maxat4+maxat4)
c
INCLUDE(common/iofile)
      common/junk/ccc1(maxat,3),ccc2(maxat3,3),ccc3(maxat3,3),
     * npopc(maxat,4),tspace(12),msett(maxat8),
     * angmat(1275),savang(40)
INCLUDE(common/tol)
c
      dimension a(maxap3,3), b(maxap3,3), d(maxap3,3), atmchg(*)
      dimension t(3,3),aset(maxap3,3)
      dimension npop(*), nset(*)
c
      data maxhvy/50/, msav/40/
      data heavy/2.d0/
      data dzero,done,two,flag/0.0d0,1.0d0,2.0d0,100.d0/
c
      numatm = natoms + 3
      halfpi = two*datan(done)
      pi = two*halfpi
      key = irkey(maxap3,natoms,a,atmchg,nset,npop,aset)
      if (idump.ne.0) write (iwr,6010) key
c
c     calculate the angles of rotation neccessary to align each heavy
c     atom pair with y.
c
      nhvy = 0
      idx = 0
      i2 = maxhvy*(maxhvy+1)/2
      call vclr(angmat,1,i2)
      do 30 iat = 1 , natoms
         if (atmchg(iat).gt.heavy) then
            setx1 = a(iat,1)
            sety1 = a(iat,2)
            j2 = iat - 1
            nhvy = nhvy + 1
            if (nhvy.ne.1) then
               if (nhvy.le.maxhvy) then
                  do 20 jat = 1 , j2
                     if (atmchg(jat).gt.heavy) then
                        idx = idx + 1
                        setx = a(jat,1) - setx1
                        sety = a(jat,2) - sety1
                        theta = halfpi
                        if(dabs(sety).gt.toler)theta = -datan(setx/sety)
                        angmat(idx) = theta
                     end if
 20               continue
               else
                  write (iwr,6010) maxhvy
                  go to 40
               end if
            end if
         end if
 30   continue
c
c     which angle occurs most frequently?
c
 40   if (nhvy.eq.1) go to 80
      if (nhvy.gt.2) then
         i2 = nhvy*(nhvy-1)/2
         nmax = 0
         nsav = 0
         do 60 i = 1 , i2
            curang = angmat(i)
            if (curang.ne.flag) then
               j1 = i + 1
               ncur = 1
               if (j1.le.i2) then
                  do 50 j = j1 , i2
                     if (dabs(curang-angmat(j)).le.toler2) then
                        ncur = ncur + 1
                        angmat(j) = flag
                     end if
 50               continue
               end if
               if (nmax.lt.ncur) then
                  nsav = 1
                  savang(1) = curang
                  nmax = ncur
               else if (nmax.eq.ncur) then
                  nsav = nsav + 1
                  if (nsav.le.msav) then
                     savang(nsav) = curang
                  end if
               end if
            end if
 60      continue
         if (nmax.eq.1) go to 80
      else
         savang(1) = angmat(1)
         nsav = 1
      end if
c     if nsav is one then a unique orientation has been selected.
c     rotate the molecule and return.
c
      if (nsav.gt.1) then
c
c     find which of several orientations maximizes the y-coordinate of
c     the key atom.  for zero or equal y values the x-coordinate is
c     tested.
c
         d(1,1) = a(key,1)
         d(1,2) = a(key,2)
         d(1,3) = a(key,3)
         call rotate(maxap3,d,b,1,t,3,savang(1))
         bestx = b(1,1)
         besty = b(1,2)
         ibest = 1
         if (nsav.gt.msav) nsav = msav
         do 70 i = 2 , nsav
            call rotate(maxap3,d,b,1,t,3,savang(i))
            if (dabs(dabs(besty)-dabs(b(1,2))).ge.toler) then
               if (dabs(besty).ge.toler .or. dabs(b(1,2)).ge.toler) then
                  if (besty.le.b(1,2)) then
                     ibest = i
                     besty = b(1,2)
                     bestx = b(1,1)
                  end if
                  go to 70
               end if
            end if
            if (dabs(dabs(bestx)-dabs(b(1,1))).ge.toler) then
               if (bestx.le.b(1,1)) then
                  ibest = i
                  bestx = b(1,1)
                  besty = b(1,2)
               end if
            end if
 70      continue
c
         call rotate(maxap3,a,b,numatm,t,3,savang(ibest))
         call movez(maxap3,b,a,numatm)
         return
      else
         call rotate(maxap3,a,b,numatm,t,3,savang(1))
         call movez(maxap3,b,a,numatm)
         call qraxis(maxap3,a,b,natoms,atmchg,2)
         return
      end if
c
c     no orientation aligns more than one heavy atom pair with y.
c
 80   theta = halfpi
      setx = a(key,1)
      sety = a(key,2)
      if (dabs(sety).gt.toler) theta = -datan(setx/sety)
      call rotate(maxap3,a,b,numatm,t,3,theta)
      if (b(key,2).gt.dzero) then
         call movez(maxap3,b,a,numatm)
      else
         call rotate(maxap3,b,a,numatm,t,3,pi)
      end if
c
c     planar molecules contained in the xy plane have not been
c     completely specified.
c
      call qrptst(maxap3,a,natoms,ixyz)
      if (ixyz.eq.3) call qraxis(maxap3,a,b,natoms,atmchg,1)
      return
c
 6010 format (1x,'qrcn-- key atom ',i3)
      end
      subroutine qrd2h(maxap3,a,b,natoms,atmchg,core)
c
c     following mullikens's recommendation --jcp, 23, 1997 (1955)--,
c     planar d2h molecules are oriented with:
c     1-- the molecular plane coincident with the yz cartesian plane.
c     2-- the z axis such that it passes through the greatest number
c         of atoms or the greatest number of bonds if the atom
c         criterion is not decisive.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension t(3,3),a(maxap3,3),b(maxap3,3),atmchg(*)
      dimension core(*)
c
      data done,two/1.0d0,2.0d0/
c
c     test for planarity.
c
      call qrptst(maxap3,a,natoms,ixyz)
      if (ixyz.eq.0) return
      if (ixyz.ne.1) then
c
c     put the molecule in the yz plane.
c
         call qryz(maxap3,a,b,natoms,atmchg,ixyz)
      end if
c
c     find the axis which should be z and reorient the molecule
c     if necessary.
c
      itst = irnax(maxap3,a,natoms,atmchg,core)
      if (itst.ne.2) return
      numatm = natoms + 3
      halfpi = two*datan(done)
      pi = two*halfpi
      call rotate(maxap3,a,b,numatm,t,1,-halfpi)
      call rotate(maxap3,b,a,numatm,t,3,-pi)
      return
      end
      subroutine qrdn(maxap3,a,b,aset,atmchg,npop,
     $                nset,natoms,norder,idump)
c
c     this routine orients symmetric top molecules in the point
c     groups dn, dnd, dnh, and cnv.  in dn and dnh molecules a
c     c2 axis is coincident with the cartesian y axis.  in dnd and
c     c2v molecules there is a vertical plane coincident with the
c     yz plane.  the molecule is rotated by pi/norder about
c     the z axis until one of the following occurs:
c     1-- the projection of the key atom on the y axis is a maximum.
c     2-- if two orientations give the greatest projection on y, the
c         one where the key atom has a positive x coordinate is chosen.
c     spherical top molecules in the point groups t, td, th, o, oh,
c      and ih are also oriented here.  the proper axis has already been
c      oriented with z.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
INCLUDE(common/iofile)
c
      dimension a(maxap3,3), b(maxap3,3), aset(maxap3,3)
      dimension t(3,3), atmchg(*), npop(*), nset(*)
c
      data dzero,done,four/0.0d0,1.0d0,4.0d0/
c
      pi = four*datan(done)
      numatm = natoms + 3
      theta = pi/norder
      key = irkey(maxap3,natoms,a,atmchg,nset,npop,aset)
      if (idump.ne.0) write (iwr,6010) key
      curpy = a(key,2)
      curpx = a(key,1)
c
c     rotate the molecule so that the key atom has a positive
c     y coordinate.
c
      if (curpy.le.dzero) then
         call rotate(maxap3,a,b,numatm,t,3,pi)
         call movez(maxap3,b,a,numatm)
         curpx = a(key,1)
         curpy = a(key,2)
      end if
c
c     search for the maximum curpy.
c
      itry = 0
      direct = -dsign(done,curpx)
 20   phi = direct*theta
      call rotate(maxap3,a,b,numatm,t,3,phi)
      itry = itry + 1
      if (dabs(curpy-b(key,2)).lt.toler) then
         if (b(key,1).ge.dzero) then
            call movez(maxap3,b,a,numatm)
         end if
      else if (curpy.gt.b(key,2)) then
         if (itry.le.1) then
            direct = -direct
            go to 20
         end if
      else
         call movez(maxap3,b,a,numatm)
         curpy = a(key,2)
         if (dabs(a(key,1)).ge.toler) go to 20
      end if
c
c     planar molecules contained in the xy plane have not been
c     completely specified.
c
      call qrptst(maxap3,a,natoms,ixyz)
      if (ixyz.eq.3) call qraxis(maxap3,a,b,natoms,atmchg,1)
      return
c
 6010 format (1x,'qrdn-- key atom:',i3)
      end
      subroutine qrplan(maxap3,a,b,atmchg,numatm,prmom,praxes,ixyz)
c
c
c     rotate the molecule about cartesian axis ixyz such that the
c     principal axis corresponding to the higher in-plane moment
c     is coincident with the higher priority in-plane cartesian
c     axis (the priority of cartesian axes is z > y > x).
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension prmom(*), praxes(3,*)
      dimension t(3,3), a(maxap3,3), b(maxap3,3), atmchg(*)
c
      data done,two/1.0d0,2.0d0/
c
      halfpi = two*datan(done)
      natoms = numatm - 3
      call secmom(maxap3,natoms,a,atmchg,prmom,praxes)
c
c     this orientation scheme applys only to asymmetric top molecules.
c
      tol3=toler2
      if(isymtl.ne.0)then
         tol3 = 10.0d0**(-isymtl)*dabs(prmom(1) + prmom(2) + prmom(3))
      endif
      itop = 0
      tst1 = prmom(2) - prmom(3)
      tst2 = prmom(1) - prmom(3)
      tst3 = prmom(1) - prmom(2)
      if (dabs(tst1).lt.tol3) itop = itop + 1
      if (dabs(tst2).lt.tol3) itop = itop + 1
      if (dabs(tst3).lt.tol3) itop = itop + 1
      if (itop.ne.3) itop = itop + 1
      if (itop.ne.1) return
c
      i2 = 1 + mod(ixyz,3)
      i3 = 1 + mod(i2,3)
c
      go to (20,30,40) , ixyz
 20   v2 = praxes(2,3)
c
      v3 = praxes(3,3)
      go to 50
 30   v2 = praxes(1,3)
      v3 = praxes(3,3)
      go to 50
 40   v2 = praxes(1,2)
      v3 = praxes(2,2)
 50   if (dabs(v2).ge.toler) then
         theta = halfpi
         if (dabs(v3).gt.toler) theta = datan(v2/v3)
         call rotate(maxap3,a,b,numatm,t,ixyz,theta)
         call movez(maxap3,b,a,numatm)
      end if
c
c     orient the axes properly.  it is assumed that the ixyz axis is
c     properly oriented and its orientation will not be changed.
c
      call qrptst(maxap3,a,natoms,izyx)
      if (izyx.eq.0) then
c
c     planar molecules ... plane perpindicular to ixyz.
c
         iax = 3
         if (ixyz.eq.3) iax = 2
         call qraxis(maxap3,a,b,natoms,atmchg,iax)
         if (ixyz.eq.2) call qraxis(maxap3,a,b,natoms,atmchg,2)
         return
      else if (izyx.ne.ixyz) then
c
c     planar molecules ... ixyz included in the plane.
c
         iax = i2
         if (i2.eq.izyx) iax = i3
         call qraxis(maxap3,a,b,natoms,atmchg,iax)
         return
      else
         call qraxis(maxap3,a,b,natoms,atmchg,i3)
         call qraxis(maxap3,a,b,natoms,atmchg,i2)
         return
      end if
c
      end
      subroutine qrptst(maxap3,a,natoms,ixyz)
c
c     if the molecule whose coordinates are in a is not planar or
c     is not contained in a cartesian plane, ixyz is set to zero.
c     otherwise it signifies the cartesian axis perpindicular to
c     the molecular plane.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3)
c
      do 30 jxyz = 1 , 3
         do 20 iat = 1 , natoms
            if (dabs(a(iat,jxyz)).gt.toler) go to 30
 20      continue
         ixyz = jxyz
         return
 30   continue
      ixyz = 0
      return
      end
      subroutine qryz(maxap3,a,b,natoms,atmchg,ixyz)
c
c     the plane of a planar molecule is in the xy(ixyz=3) or
c     xz(ixyz=2) planes.  rotate it so that the molecular plane
c     is coincident with the yz cartesian plane.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension t(3,3), e(3), a(maxap3,3), b(maxap3,3), atmchg(*)
c
      data done,two/1.0d0,2.0d0/
c
      numatm = natoms + 3
      halfpi = two*datan(done)
      go to (20,30,40) , ixyz
c
 20   call qrplan(maxap3,a,b,atmchg,numatm,e,t,1)
      return
c
 30   call rotate(maxap3,a,b,numatm,t,3,halfpi)
      call movez(maxap3,b,a,numatm)
      call qrplan(maxap3,a,b,atmchg,numatm,e,t,1)
      return
c
 40   call rotate(maxap3,a,b,numatm,t,2,halfpi)
      call movez(maxap3,b,a,numatm)
      call qrplan(maxap3,a,b,atmchg,numatm,e,t,1)
      return
c
      end
      subroutine rdgeom
c
c     read geometry input
c
c      input:    data on cards in the input deck.
c                options in iop as outlined above.
c      output:   all geometrical output is in atomic units
c                (bohrs/radians).
c                /zmat/ consists of eight arrays dimensioned to hold the
c                       data from up to 50 z-matrix cards and two
c                       variables containing counters.
c                       ianz-   atomic numbers
c                       iz-     connectivity data
c                       bl-     bond lengths
c                       alpha-  valence angles
c                       beta-   dihedral or second valence angle
c                       lbl-    an array used to map from the array of
c                               variable values in /zsubst/ to the array
c                               bl in /zmat/.  for lbl(n)=0, no
c                               substitution is required to get bl(n):
c                               it already contains the proper value.
c                               for lbl(n)=i, bl(n)=values(i); for
c                               lbl(n)=-i, bl(n)=-values(i).
c                      lalpha-  analagous to lbl for alpha.
c                      lbeta-   analagous to lbl for beta.
c                      nz-      the number of cards in the z-matrix.
c                      nvar-    the number of variables, equal to the
c                               number of symbols defined in the
c                               variables section of the input.
c                /zsubst/ contains the data in the variables section of
c                         the input.
c                      anames-  alphanumeric names of the variables.
c                               (limited to 8 characters in the current
c                                vax version).
c                      values-  the corresponding numeric values.  these
c                               will be altered in the course of
c                               geometry optimizations and potential
c                               surface scans.
c                      intvec-  an array of the integer values following
c                               the symbol and value on a line in the
c                               variables section.
c                      fpvec-   a corresponding array containing the
c                               floating point number.  the use of these
c                               two vectors depends upon the route.
c
c
c1
c     a description of the means of specifying the nuclear coordinates
c     follows.
c
c1geometry
c1z-matrix
c
c      z-matrix specification section.
c
c          this section is  always  required.   it  specifies  the
c     nuclear  positions.
c     the input is free-format    ;  the several  items  on
c     each card may be separated by blanks.
c
c          the data cards are used to  specify  the  relative
c     positions of the nuclei.  most of these will be real nuclei,
c     used later in the molecular orbital  computation.   however,
c     it  is  frequently  useful to introduce "dummy nuclei" which
c     help specify the  geometry  but  are  ignored  subsequently.
c     their use will become clear in examples given below.
c
c          each   nucleus   (including   dummies)   is    numbered
c     sequentially  and specified on a single card.  (this data is
c     referred to as the z-matrix).  thus, the nature and location
c     of  the n-th nucleus is specified on the (n+1)th card in the
c     section in terms of the positions of the previously  defined
c     nuclei 1,2,...(n-1).
c
c          the information about the n-th nucleus is contained  in
c     up to eight separated items on the card:
c
c                element, n1, length, n2, angle, n3 twist, j
c
c     each of these items is now discussed.
c
c          "element" specifies the chemical nature of the nucleus.
c     it  may  consist  of just the chemical symbol such as "h" or
c     "c" for of carbon.  alternatively, it may be an alphanumeric
c     string   beginning   with   the  chemical  symbol,  followed
c     immediately by a secondary identifying integer.  thus,  "c5"
c     can  be  used to specify a carbon nucleus, identified as the
c     fifth carbon in the molecule.  this is sometimes  convenient
c     in  following conventional chemical numbering.  dummy nuclei
c     are denoted by the symbols "x" or "-".  the  item  "element"
c     is  required  for  every  nucleus.   for  the  first nucleus
c     specified (n=1), it is the only item on the card.
c
c          "n1" specifies the  (previously  defined)  nucleus  for
c     which  the  internuclear length r(n,n1) will be given.  this
c     item may be either an integer (the value of n1 <  n)  or  an
c     alphanumeric  string.   in  the latter case, the string must
c     match the "element" field of a previous z-matrix card.
c
c          "length" is the internuclear length r(n,n1).  this  may
c     be either a positive floating point number giving the length
c     in  angstroms  or  an  alphanumeric   string   (maximum   16
c     characters).   in the latter case, the length is represented
c     by a "variable" for which  a  value  will  be  specified  in
c     section 4.  use of variables in the z-matrix is essential if
c     optimization is to be carried out.  however, they  can  also
c     be  used  in single-point runs.  the items "n1" and "length"
c     are required for all nuclei after the first.  for the second
c     nucleus, only "element", "n1", and "length" are required.
c
c          "n2" specifies the nucleus for which  the  internuclear
c     angle  theta(n,n1,n2)  will  be given.  again this may be an
c     integer (the value of n2 <  n)  or  an  alphanumeric  string
c     which  matches  a  previous "element" entry.  note that "n1"
c     and "n2" must represent different nuclei.
c
c          "angle" is the internuclear angle theta(n,n1,n2).  this
c     may  be  a floating point number giving the angle in degrees
c     or an alphanumeric string representing a variable.  "n2" and
c     "angle"  are  required for all nuclei after the second.  for
c     the third nucleus, only "element", "n1", "length", "n2", and
c     "angle" are rquired.
c
c          "n3".  the significance of "n3" and "twist" depends  on
c     the value of the last item "j".  if j=0, or is omitted, "n3"
c     specifies th nucleus for  which  the  internuclear  dihedral
c     angle,  phi(n,n1,n2,n3)  will  be  given;   as with "n1" and
c     "n2", this  may  be  either  an  integer  (n3  <  n)  or  an
c     alphanumeric string matching a previous "element" entry.
c
c          "twist" (if j=0) is  the  internuclear  dihedral  angle
c     phi(n,n1,n2,n3).  again, this may be a floating point number
c     giving the  angle  in  degrees  or  an  alphanumeric  string
c     representing  a  variable  (or  a  variable  preceeded  by a
c     negative sign).  the dihedral angle is defined as the  angle
c     (-180.0  <  phi  <= +180.0) between the planes (n,n1,n2) and
c     (n1,n2,n3).  the sign is positive if  the  movement  of  the
c     directed   vector   (n1-->n)  towards  the  directed  vector
c     (n2-->n3) involves a righthanded screw motion.
c
c          "j".  the above descriptions of "n3" and "twist"  apply
c     if  the  item "j" is zero or absent.  although it is usually
c     possible to specify the nucleus n by a bond length,  a  bond
c     angle,  and  a  dihedral  angle,  it is sometimes simpler to
c     replace th dihedral angle by a second bond angle.   this  is
c     called for by using j = +1 or -1.
c
c          "n3".  if "j" is +1 or -1, "n3" specifies  the  nucleus
c     for which the second internuclear angle chi(n,n1,n3) will be
c     given.  as usual, this may be either an integer (n3 < n)  or
c     an  alphanumeric  string  representing  a previously defined
c     nucleus.
c
c          "twist".  if "j" is +1 or -1, then this item gives  the
c     value  for  the  second internuclear angle chi(n,n1,n3).  as
c     before, this may be either a floating point number (value in
c     degrees) or an alphanumeric string representing a variable.
c
c          "j".  in the event of specification by two internuclear
c     angles  theta, chi, there will be two possible positions for
c     the nucleus n.  this is fixed by the sign of "j".  thus j=+1
c     if the triple vector product:
c
c          (n1-->n) .  ((n1-->n2) x (n1-->n3))  is  positive,  and
c     j=-1 if the product is negative.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
      common/junk/scr(1)
INCLUDE(common/infoa)
INCLUDE(common/infob)
INCLUDE(common/runlab)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
INCLUDE(common/csubch)
INCLUDE(common/phycon)
INCLUDE(common/prints)
c
c      ---   get the z matrix
c
      call sget(toang(1),ifau)
c
c      ---   substitute the variables into the z matrix
c
      call subvar(bl,alpha,beta,lbl,lalpha,lbeta,nz,nvar)
      call trcart
      call subvar(bl,alpha,beta,lbl,lalpha,lbeta,nz,nvar)
c
c     ---    print out the completed z - matrix
c
      call sprintxz(maxnz,nz,ianz,iz,bl,alpha,beta,toang(1),iwr)
c
c    --- check charge and multiplicity (suppressed 2/96)
c
c     call chgmlt(ich,mul,onel)
c
c    --- convert z-matrix to cartesians
c
      n1 = 1
      n2 = n1 + nz
      n3 = n2 + nz
      n4 = n3 + nz
      n5 = n4 + nz
      n6 = n5 + nz
      otest = .true.
      call stocxz(maxnz,nz,ianz,iz,bl,alpha,beta,otest,natom,imass,c,
     + scr(n6),scr(n1),scr(n2),scr(n3),scr(n4),scr(n5),iwr,oerro)
      if (oerro) call caserr2(
     +           'fatal error detected in z-matrix algorithm')
c
c     --- load up the array holding the charges
c
c
c ----- load up text strings characterising atoms .. no dummies
c
      j = 0
      do 20 i = 1 , nz
         if (ianz(i).ge.0) then
            j = j + 1
            zaname(j) = zaname(i)
            czan(j) = czan(i)
         end if
 20   continue
c
c     ---- now reorder those atoms which were defined as coordinates
c     ---- so that no gaps occur in the list because of dummy atoms
c
      j = natom
      nzp1 = nz + 1
      if (nzp1.le.nat) then
         do 30 i = nzp1 , nat
            j = j + 1
            imass(j) = imass(i)
            zaname(j) = zaname(i)
            czan(j) = czan(i)
c
c
            c(1,j) = c(1,i)
            c(2,j) = c(2,i)
            c(3,j) = c(3,i)
 30      continue
      end if
c
c      --- now set the total number of atoms
c
      nat = j
c
c      --- probably a good idea to print the coordinates out
c      --- after printing it would be best to rotate to the
c      --- symmetry axes if neccessary
c
c
c store contents of czan in symz and czanr
c
      call dcopy(nat,czan,1,symz,1)
      call dcopy(nat,czan,1,czanr,1)
      write (iwr,6010)
      nbqnop = 0 
      do 40 i = 1 , nat
         if (.not. oprint(31) .or. (zaname(i)(1:2) .ne. 'bq'))then
            write (iwr,6020) i , zaname(i) , (c(j,i),j=1,3)
         else
            nbqnop = nbqnop + 1
         endif
 40   continue
      if (nbqnop .gt. 0)then
         write (iwr,6021) nbqnop
      endif
      write (iwr,6030)
      return
 6010 format (/30x,'coordinates (a.u.) - prior to orientation'/1x,
     +        72('-')/17x,'atom',16x,'x',14x,'y',14x,'z'/)
 6020 format (11x,i4,2x,a8,2x,3f15.6)
 6021 format (12x,i5,' bq centres not printed')
 6030 format (/1x,72('-')/)
c
      end
      subroutine readat(q,omopac)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension yopt(4),ytype(8),yau(4)
      character *3 char3i
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/phycon)
INCLUDE(common/infoa)
INCLUDE(common/infob)
INCLUDE(common/iofile)
INCLUDE(common/work)
      common/junkc/ylab(26),ztype(335)
INCLUDE(common/runlab)
INCLUDE(common/prints)
_IF(ccpdft)
INCLUDE(common/blur)
_ENDIF
_IF(xml)
INCLUDE(common/xmlin)
_ENDIF
INCLUDE(common/runopt)
      character*7 fnm
      character*6 snm
      data fnm,snm/"input.m","readat"/
      dimension q(*),ztit(103)
      data zblank /' '      /
      data yiang,yiangs/'ang','angs'/
      data yau/'au','a.u.','aus','bohr'/
c     data dzero/0.0d0/
      data done/1.0d0/
      data yend,ystop,yfini,yexit/'end','stop','fini','exit'/
c     data yzgen/'zgen'/
      data yopt/'all','bond','angl','tors'/
      data ztit/
     $         'h ', 'he',
     $         'li', 'be', 'b ', 'c ', 'n ', 'o ', 'f ', 'ne',
     $         'na', 'mg', 'al', 'si', 'p ', 's ', 'cl', 'ar',
     $         'k ', 'ca',
     $                     'sc', 'ti', 'v ', 'cr', 'mn',
     $                     'fe', 'co', 'ni', 'cu', 'zn',
     $                     'ga', 'ge', 'as', 'se', 'br', 'kr',
     $ 'rb','sr','y ','zr','nb','mo','tc','ru','rh','pd','ag','cd',
     $ 'in','sn','sb','te','i ','xe','cs','ba','la','ce','pr','nd',
     $ 'pm','sm','eu','gd','tb','dy','ho','er','tm','yb','lu','hf',
     $ 'ta','w ','re','os','ir','pt','au','hg','tl','pb','bi','po',
     $ 'at','rn','fr','ra','ac','th','pa','u ','np','pu','am','cm',
     $ 'bk','cf','es','fm','md','no','lw'   /
c
c read in the rest of the line to see if it is
c necessary to generate a z-matrix
c
      scale_geo = 1.1
      ozmat = .false.
      onwchem = .false.
      ntype = 0
      jrec = jrec - 1
20    if (jrec.le.jump-1) then
c     do 20 i = jrec , jump-1
         call inpa(ztest)
         ytest = ytrunc(ztest)
         if (ytest.eq.'nwch') then
          onwchem = .true.
         else if (ytest.eq.'unit') then
c
         else if (ytest.eq.'mopa') then
          ifau = 1
         else if (locatc(yopt,4,ytest).gt.0) then
            ozmat = .true.
            ntype = ntype + 1
            ytype(ntype) = ytest
         else if (ytest.eq.yiang .or. ytest.eq.yiangs) then
            ifau = 1
         else if (locatc(yau,4,ytest).gt.0) then
            ifau = 0
         else if (ytest.eq.'scal') then
            call inpf(scale_geo)
         else
            call inpi(iseczz)
         end if
         go to 20
       end if
c
c check on units required
c
      tobohr = done
      if (ifau.eq.1) tobohr = done/toang(1)
      nonsym = 0
 30   call input
      call inpa(ztest)
      ytest = ytrunc(ztest)
      if (ytest.ne.yend .and. ytest.ne.yfini .and. ytest.ne.ystop .and.
     +     ytest.ne.yexit) then
         jrec = 0
         if (onwchem) then
            call inpa(zatom)
            call inpf(cznuc)
            call inpf(p)
            call inpf(qq)
            call inpf(r)
         else
            call inpf(p)
            call inpf(qq)
            call inpf(r)
            if (omopac) then
               call inpa(zatom)
               ztagg = ztit(jsubst(zatom))
               ktype = locatc(ztit,103,ztagg)
               cznuc = dfloat(ktype)
            else
               call inpf(cznuc)
               call inpa(zatom)
            endif
         endif
         call inpa(zopt)
_IF(ccpdft)
         blexpo(nonsym+1) = -1.0d0
         blwght(nonsym+1) =  0.0d0
_ENDIF
         if(zopt(1:4).eq.'blur')then
_IF(ccpdft)
            oblur = .true.
            call inpf(blexpo(nonsym+1))
            blwght(nonsym+1) = cznuc
            cznuc = 0.0d0
            call inpa(zopt)
_ELSE
            call caserr2('blur not available - configure with DFT')
_ENDIF
         endif
         if(zopt(1:2).eq.'no') zopt='no'
         if(zopt.ne.' '.and.zopt.ne.'no'.and.zopt.ne.'yes') 
     +        jrec=jrec-1
         if(zopt.ne.'no') zopt='yes'
         if(jrec.lt.jump)then
            call inpf(amas0)
            ordmas = .true.
         else
            ordmas = .false.
         endif
         nonsym = nonsym + 1
         nat = nonsym
         if (nonsym.gt.maxat) then
            write(iwr,*)'the current number of atoms is ',nonsym
            write(iwr,*)'the maximum number of atoms is ',maxat
            call caserr2('invalid number of nuclei specified')
         end if
      else if (nonsym.le.0) then
         write(iwr,*)'the current number of atoms is ',nonsym
         write(iwr,*)'valid numbers of atoms are [',1,' ..',maxat,']'
         call caserr2('invalid number of nuclei specified')
      else
c
c  ************* all atoms read in **********
_IF(xml)
c
c Replace atoms as loaded from input by XML source if requested
c
         write(6,*)'XML TEST',ixfcoord
         if(ixfcoord .ne. 0)then

            call readxml_getcoords(nat,cat,ztag)
            nonsym = nat
            zopt = 'no'

            write(6,*)'returned nat=',nat
            do i = 1,nat
               write(6,*)ztag(i),cat(1,i),cat(2,i),cat(3,i)
               ! check needed
               cat(1,i) = cat(1,i)*tobohr
               cat(2,i) = cat(2,i)*tobohr
               cat(3,i) = cat(3,i)*tobohr

               c(1,i) = cat(1,i)
               c(2,i) = cat(2,i)
               c(3,i) = cat(3,i)

               ztmp = ztag(i)
               call lcase(ztmp)
               ztag(i) = ztmp

               zaname(i) = ztag(i)

               cznuc = isubst(ztmp)
               czann(i) = cznuc
               symz(i) = cznuc
               czan(i) = cznuc
               imass(i) = nint(cznuc)
               zopti(i)=zopt
            enddo
         endif
_ENDIF
         if (nonsym.eq.1) return
c     
c     sf 'fix' for crystalfield calculation
c     sf        ... allow two bq's at same place 
c     ps -  generalise to non-xfield case
c     
         do 50 i = 2 , nonsym
            c1 = cat(1,i)
            c2 = cat(2,i)
            c3 = cat(3,i)
            zatom = ztag(i)
            obqi = (ztag(i)(1:2).eq.'bq')
            ii = i - 1
            do 40 j = 1 , ii
               obqj = (ztag(j)(1:2).eq.'bq')
               if (.not. (obqi .and. obqj))then
                  rij = (cat(1,j)-c1)**2 + (cat(2,j)-c2)**2 + 
     +                 (cat(3,j)-c3)**2
                  if (dsqrt(rij).lt.1.0d-6) then 
                   write(iwr,6080) ztag(i),c1,c2,c3,
     +                             ztag(j),cat(1,j),cat(2,j),cat(3,j)
                   call caserr2(
     +             'two centres have identical coordinates')
                  end if
               end if
 40         continue
 50      continue
*     
*     Print the coordinates out
*     
         write(iwr,6040)
         nbqnop = 0
         do 60 i = 1,nonsym
            if (.not. oprint(31) .or. (ztag(i)(1:2) .ne. 'bq'))then
            if(zopti(i).eq.'yes') then
               write(iwr,6050)i,ztag(i),(cat(j,i),j=1,3)
            else
               write(iwr,6060)i,ztag(i),(cat(j,i),j=1,3)
            endif
            else
              nbqnop = nbqnop + 1
            endif
 60      continue
      if (nbqnop .gt. 0)then
         write (iwr,6061) nbqnop
      endif
         write(iwr,6070)
         if (ozmat) then
*     
*     Generate z-matrix if necessary
*     
            write (iwr,6010)
            write (iwr,6020) (ytype(k),k=1,ntype)
c     
            mxbnds = 8
            nonn = nonsym + 3
            non3 = nonn*3
            non153 = non3*15
c     determine memory offsets
            i10 = 0
            i20 = i10 + non153
            i30 = 120 + non153
            i40 = i30 + non153
            i50 = i40 + non153
            i60 = i50 + non3
            i70 = i60 + non3
            i80 = i70 + non3
            i90 = i80 + non153
            i100 = i90 + non3
            i120 = i100 + non3
            i130 = i120 + nonn*5
            i140 = i130 + nonn*10
            i150 = i140 + nonn*10
            i160 = i150 + nonn*mxbnds
            i170 = i160 + nonn*mxbnds
            i180 = i170 + nonn*mxbnds
            i190 = i180 + nonn*mxbnds*15
            i200 = i190 + nonn
            i230 = i200 + nonn
            i240 = i230 + non3
            i250 = i240 + nonn
            i270 = i250 + nonn
            i280 = i270 + nonn
            i290 = i280 + nonn
            last = i290 + nonn
c     
c     allocate memory and determine offsets
c     
            i10 = igmem_alloc_inf(last,fnm,snm,'i10',IGMEM_DEBUG)
            i20 = i10 + non153
            i30 = 120 + non153
            i40 = i30 + non153
            i50 = i40 + non153
            i60 = i50 + non3
            i70 = i60 + non3
            i80 = i70 + non3
            i90 = i80 + non153
            i100 = i90 + non3
            i120 = i100 + non3
            i130 = i120 + nonn*5
            i140 = i130 + nonn*10
            i150 = i140 + nonn*10
            i160 = i150 + nonn*mxbnds
            i170 = i160 + nonn*mxbnds
            i180 = i170 + nonn*mxbnds
            i190 = i180 + nonn*mxbnds*15
            i200 = i190 + nonn
            i230 = i200 + nonn
            i240 = i230 + non3
            i250 = i240 + nonn
            i270 = i250 + nonn
            i280 = i270 + nonn
            i290 = i280 + nonn
            last = i290 + nonn
            call zgen(nonsym,cat,czann,ztag,ytype,ntype,nonn,mxbnds,
     +           q(i10),q(i20),q(i30),q(i40),q(i50),q(i60),q(i70),
     +           q(i80),q(i90),q(i100),q(i120),q(i130),q(i140),
     +           q(i150),q(i160),q(i170),q(i180),q(i190),q(i200),
     +           q(i230),q(i240),q(i250),
     +           q(i270),q(i280),q(i290),scale_geo)
c     
c     free memory
c     
            call gmem_free_inf(i10,fnm,snm,'i10')
         end if
         return
      end if
      cat(1,nonsym) = p*tobohr
      cat(2,nonsym) = qq*tobohr
      cat(3,nonsym) = r*tobohr
      c(1,nonsym) = p*tobohr
      c(2,nonsym) = qq*tobohr
      c(3,nonsym) = r*tobohr
      czann(nonsym) = cznuc
      symz(nonsym) = cznuc
      czan(nonsym) = cznuc
      czanr(nonsym) = cznuc
      imass(nonsym) = nint(cznuc)
      zopti(nonsym)=zopt
      if (zatom.ne.zblank) then
         ztag(nonsym) = zatom
         zaname(nonsym) = zatom
      else 
         ztag(nonsym) = char3i(nonsym)
         zaname(nonsym) = ztag(nonsym)
      end if
c
c-weights
c
c it is now only necessary to store the atomic mass if 
c it differs from the default generated from the atomic
c symbol
c
      if (ordmas) then
         call mass_editvec(1,nonsym,-2,amas0)
c      else
c         nucz = idint(cznuc+0.001d0)
c         if (nucz.le.0 .or. nucz.gt.54) then
c            amass(nonsym) = dzero
c         else
c             amass(nonsym) = ams(nucz)
c         end if
      end if
c
c-weights end
c
      go to 30
 6010 format (//1x,'============================='/1x,
     +        'automatic z-matrix generation'/1x,
     +        '============================='/)
 6020 format ('optimisation options:- ',8(1x,a4))
 6040 format(/
     +30x,'coordinates (a.u.) - prior to orientation'/
     +1x,72('-')/
     +17x,'atom',16x,'x',14x,'y',14x,'z'/)
 6050 format(11x,i4,2x,a8,2x,3f15.6,1x,'optimise')
 6060 format(11x,i4,2x,a8,2x,3f15.6,1x,'        ')
 6061 format (12x,i5,' bq centres not printed')
 6070 format(/1x,72('-')/ )
 6080 format(/,' The following centers (not bq) are colliding ',
     +       2(/,5x,a8,2x,3f18.8) )
      end
      subroutine rdchar(isuccess,zgroup,naxis,norder,nir,iir,
     +  ipointer,zlabir,chars)
c
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter(maxireps=20)
c
      dimension iir(maxireps), ipointer(maxireps), zlabir(maxireps), 
     +     chars(maxireps*maxireps)
c
c
c  THE POINTER FROM GAMESS NUMBERING OF GROUP ELEMENTS TO COLUMNS OF
c  CHARACTER TABLES IS NOT PRESENT EVERYWHERE - MUST BE FOUND AND ADDED
c  OTHERWISE THE SYMASSIGN FOR THAT GROUPS DOES NOT WORK
c
c
c the group character tables follow - this code was machine generated
c
c the variables ygroupname contain description of classes of conj. 
c elements and are not used - they are for easier orientation and 
c maybe somebody else could use them
c
c
      integer ic1
      REAL chc1
c     character*10 yc1
      character*4 yrc1
      parameter(nc1=1)
      dimension ic1(4), chc1(1,1), yrc1(1)
c     dimension yc1(1)
c
c
      integer ic1h
      REAL chc1h
c     character*10 yc1h
      character*4 yrc1h
      parameter(nc1h=2)
      dimension ic1h(6), chc1h(2,2), yrc1h(2)
c     dimension yc1h(2)
c
c
c
      integer ic2
      REAL chc2
c     character*10 yc2
      character*4 yrc2
      parameter(nc2=2)
      dimension ic2(6), chc2(2,2), yrc2(2)
c     dimension yc2(2)
c
c
      integer ic2h
      REAL chc2h
c     character*10 yc2h
      character*4 yrc2h
      parameter(nc2h=4)
      dimension ic2h(10), chc2h(4,4), yrc2h(4)
c     dimension yc2h(4)
c
c
      integer ic2v
      REAL chc2v
c     character*10 yc2v
      character*4 yrc2v
      parameter(nc2v=4)
      dimension ic2v(10), chc2v(4,4), yrc2v(4)
c     dimension yc2v(4)
c
c
      integer ic3
      REAL chc3
c     character*10 yc3
      character*4 yrc3
      parameter(nc3=3)
      dimension ic3(8), chc3(3,3), yrc3(3)
c     dimension yc3(3)
c
c
      integer ic3h
      REAL chc3h
c     character*10 yc3h
      character*4 yrc3h
      parameter(nc3h=6)
      dimension ic3h(14), chc3h(6,6), yrc3h(6)
c     dimension yc3h(6)
c
c
      integer ic3v
      REAL chc3v
c     character*10 yc3v
      character*4 yrc3v
      parameter(nc3v=3)
      dimension ic3v(8), chc3v(3,3), yrc3v(3)
c     dimension yc3v(3)
c
c
      integer ic4
      REAL chc4
c     character*10 yc4
      character*4 yrc4
      parameter(nc4=4)
      dimension ic4(10), chc4(4,4), yrc4(4)
c     dimension yc4(4)
c
c
      integer ic4h
      REAL chc4h
c     character*10 yc4h
      character*4 yrc4h
      parameter(nc4h=8)
      dimension ic4h(18), chc4h(8,8), yrc4h(8)
c     dimension yc4h(8)
c
c
      integer ic4v
      REAL chc4v
c     character*10 yc4v
      character*4 yrc4v
      parameter(nc4v=5)
      dimension ic4v(12), chc4v(5,5), yrc4v(5)
c     dimension yc4v(5)
c
c
      integer ic5
      REAL chc5
c     character*10 yc5
      character*4 yrc5
      parameter(nc5=5)
      dimension ic5(12), chc5(5,5), yrc5(5)
c     dimension yc5(5)
c
c
      integer ic5h
      REAL chc5h
c     character*10 yc5h
      character*4 yrc5h
      parameter(nc5h=10)
      dimension ic5h(22), chc5h(10,10), yrc5h(10)
c     dimension yc5h(10)
c
c
      integer ic5v
      REAL chc5v
c     character*10 yc5v
      character*4 yrc5v
      parameter(nc5v=4)
      dimension ic5v(10), chc5v(4,4), yrc5v(4)
c     dimension yc5v(4)
c
      integer ic6
      REAL chc6
c     character*10 yc6
      character*4 yrc6
      parameter(nc6=6)
      dimension ic6(14), chc6(6,6), yrc6(6)
c     dimension yc6(6)
c
c
      integer ic6h
      REAL chc6h
c     character*10 yc6h
      character*4 yrc6h
      parameter(nc6h=12)
      dimension ic6h(26), chc6h(12,12), yrc6h(12)
c     dimension yc6h(12)
c
c
      integer ic6v
      REAL chc6v
c     character*10 yc6v
      character*4 yrc6v
      parameter(nc6v=6)
      dimension ic6v(14), chc6v(6,6), yrc6v(6)
c     dimension yc6v(6)
c
c
      integer ic7
      REAL chc7
c     character*10 yc7
      character*4 yrc7
      parameter(nc7=7)
      dimension ic7(16), chc7(7,7), yrc7(7)
c     dimension yc7(7)
c
c
      integer ic7v
      REAL chc7v
c     character*10 yc7v
      character*4 yrc7v
      parameter(nc7v=5)
      dimension ic7v(12), chc7v(5,5), yrc7v(5)
c     dimension yc7v(5)
c
c
      integer ic8
      REAL chc8
c     character*10 yc8
      character*4 yrc8
      parameter(nc8=8)
      dimension ic8(18), chc8(8,8), yrc8(8)
c     dimension yc8(8)
c
c
      integer ici
      REAL chci
c     character*10 yci
      character*4 yrci
      parameter(nci=2)
      dimension ici(6), chci(2,2), yrci(2)
c     dimension yci(2)
c
c
      integer ics
      REAL chcs
c     character*10 ycs
      character*4 yrcs
      parameter(ncs=2)
      dimension ics(6), chcs(2,2), yrcs(2)
c     dimension ycs(2)
c
c
      integer id2
      REAL chd2
c     character*10 yd2
      character*4 yrd2
      parameter(nd2=4)
      dimension id2(10), chd2(4,4), yrd2(4)
c     dimension yd2(4)
c
c
      integer id2d
      REAL chd2d
c     character*10 yd2d
      character*4 yrd2d
      parameter(nd2d=5)
      dimension id2d(12), chd2d(5,5), yrd2d(5)
c     dimension yd2d(5)
c
c
      integer id2h
      REAL chd2h
c     character*10 yd2h
      character*4 yrd2h
      parameter(nd2h=8)
      dimension id2h(18), chd2h(8,8), yrd2h(8)
c     dimension yd2h(8)
c
c
      integer id3
      REAL chd3
c     character*10 yd3
      character*4 yrd3
      parameter(nd3=3)
      dimension id3(8), chd3(3,3), yrd3(3)
c     dimension yd3(3)
c
c
      integer id3d
      REAL chd3d
c     character*10 yd3d
      character*4 yrd3d
      parameter(nd3d=6)
      dimension id3d(14), chd3d(6,6), yrd3d(6)
c     dimension yd3d(6)
c
c
      integer id3h
      REAL chd3h
c     character*10 yd3h
      character*4 yrd3h
      parameter(nd3h=6)
      dimension id3h(14), chd3h(6,6), yrd3h(6)
c     dimension yd3h(6)
c
c
      integer id4
      REAL chd4
c     character*10 yd4
      character*4 yrd4
      parameter(nd4=5)
      dimension id4(12), chd4(5,5), yrd4(5)
c     dimension yd4(5)
c
c
      integer id4d
      REAL chd4d
c     character*10 yd4d
      character*4 yrd4d
      parameter(nd4d=7)
      dimension id4d(16), chd4d(7,7), yrd4d(7)
c     dimension yd4d(7)
c
c
      integer id4h
      REAL chd4h
c     character*10 yd4h
      character*4 yrd4h
      parameter(nd4h=10)
      dimension id4h(22), chd4h(10,10), yrd4h(10)
c     dimension yd4h(10)
c
c
      integer id5
      REAL chd5
c     character*10 yd5
      character*4 yrd5
      parameter(nd5=4)
      dimension id5(10), chd5(4,4), yrd5(4)
c     dimension yd5(4)
c
c
      integer id5d
      REAL chd5d
c     character*10 yd5d
      character*4 yrd5d
      parameter(nd5d=8)
      dimension id5d(18), chd5d(8,8), yrd5d(8)
c     dimension yd5d(8)
c
c
      integer id5h
      REAL chd5h
c     character*10 yd5h
      character*4 yrd5h
      parameter(nd5h=8)
      dimension id5h(18), chd5h(8,8), yrd5h(8)
c     dimension yd5h(8)
c
      integer id6
      REAL chd6
c     character*10 yd6
      character*4 yrd6
      parameter(nd6=6)
      dimension id6(14), chd6(6,6), yrd6(6)
c     dimension yd6(6)
c
c
      integer id6d
      REAL chd6d
c     character*10 yd6d
      character*4 yrd6d
      parameter(nd6d=9)
      dimension id6d(20), chd6d(9,9), yrd6d(9)
c     dimension yd6d(9)
c
      integer id6h
      REAL chd6h
c     character*10 yd6h
      character*4 yrd6h
      parameter(nd6h=12)
      dimension id6h(26), chd6h(12,12), yrd6h(12)
c     dimension yd6h(12)
c
      integer id8
      REAL chd8
c     character*10 yd8
      character*4 yrd8
      parameter(nd8=7)
      dimension id8(16), chd8(7,7), yrd8(7)
c     dimension yd8(7)
c
      integer id8h
      REAL chd8h
c     character*10 yd8h
      character*4 yrd8h
      parameter(nd8h=14)
      dimension id8h(30), chd8h(14,14), yrd8h(14)
c     dimension yd8h(14)
c
      integer ii
      REAL chi
c     character*10 yi
      character*4 yri
      parameter(ni=5)
      dimension ii(12), chi(5,5), yri(5)
c     dimension yi(5)
c
      integer iih
      REAL chih
c     character*10 yih
      character*4 yrih
      parameter(nih=10)
      dimension iih(22), chih(10,10), yrih(10)
c     dimension yih(10)
c
      integer io
      REAL cho
c     character*10 yo
      character*4 yro
      parameter(no=5)
      dimension io(12), cho(5,5), yro(5)
c     dimension yo(5)
c
      integer ioh
      REAL choh
c     character*10 yoh
      character*4 yroh
      parameter(noh=10)
      dimension ioh(22), choh(10,10), yroh(10)
c     dimension yoh(10)
c
      integer is2
      REAL chs2
c     character*10 ys2
      character*4 yrs2
      parameter(ns2=2)
      dimension is2(6), chs2(2,2), yrs2(2)
c     dimension ys2(2)
c
      integer is4
      REAL chs4
c     character*10 ys4
      character*4 yrs4
      parameter(ns4=4)
      dimension is4(10), chs4(4,4), yrs4(4)
c     dimension ys4(4)
c
c
      integer is6
      REAL chs6
c     character*10 ys6
      character*4 yrs6
      parameter(ns6=6)
      dimension is6(14), chs6(6,6), yrs6(6)
c     dimension ys6(6)
c
      integer is8
      REAL chs8
c     character*10 ys8
      character*4 yrs8
      parameter(ns8=8)
      dimension is8(18), chs8(8,8), yrs8(8)
c     dimension ys8(8)
c
      integer it
      REAL cht
c     character*10 yt
      character*4 yrt
      parameter(nt=4)
      dimension it(10), cht(4,4), yrt(4)
c     dimension yt(4)
c
      integer itd
      REAL chtd
c     character*10 ytd
      character*4 yrtd
      parameter(ntd=5)
      dimension itd(12), chtd(5,5), yrtd(5)
c     dimension ytd(5)
c
      integer ith
      REAL chth
c     character*10 yth
      character*4 yrth
      parameter(nth=8)
      dimension ith(18), chth(8,8), yrth(8)
c     dimension yth(8

      data ic1/1,1,1
     +             ,1/
      data yrc1/'a'/
c     data yc1/'e'/
      data chc1/
     + 1.000/
c
      data ic1h/2,2,1,1
     +             ,1,2/
      data yrc1h/'a''','a'''''/
c     data yc1h/'e','si.h'/
      data chc1h/
     + 1.000, 1.000,
     + 1.000,-1.000/
c

      data ic2/2,2,1,1
     +             ,1,2/
      data yrc2/'a','b'/
c     data yc2/'e','c2'/
      data chc2/
     + 1.000, 1.000,
     + 1.000,-1.000/
c
      data ic2h/4,4,1,1,1,1
     +             ,1,2,3,4/
      data yrc2h/'ag','au','bg','bu'/
c     data yc2h/'e','c2','si.h','i'/
      data chc2h/
     + 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000,-1.000,-1.000,
     + 1.000,-1.000,-1.000, 1.000,
     + 1.000,-1.000, 1.000,-1.000/
c
      data ic2v/4,4,1,1,1,1
     +             ,1,2,4,3/
      data yrc2v/'a1','a2','b1','b2'/
c     data yc2v/'e','c2','si.v','si.v'''/
      data chc2v/
     + 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000,-1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000,
     + 1.000,-1.000,-1.000, 1.000/
c
      data ic3/3,3,1,1,1
     +             ,1,2,3/
      data yrc3/'a','e+','e-'/
c     data yc3/'e','c3','c3**2'/
      data chc3/
     + 1.000, 1.000, 1.000,
     + 1.000,-0.500,-0.500,
     + 0.000, 0.866,-0.866/
c
      data ic3h/6,6,1,1,1,1,1,1
     +             ,1,2,3,4,5,6/
      data yrc3h/'a''','e''+','e''-','a"','e"+','e"-'/
c     data yc3h/'e','c3','c3**2','si.h','s3','s3**5'/
      data chc3h/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000,-0.500,-0.500, 1.000,-0.500,-0.500,
     + 0.000, 0.866,-0.866, 0.000, 0.866,-0.866,
     + 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,
     + 1.000,-0.500,-0.500,-1.000, 0.500, 0.500,
     + 0.000, 0.866,-0.866, 0.000,-0.866, 0.866/
c
      data ic3v/3,6,1,2,3
     +             ,1,2,4/
      data yrc3v/'a1','a2','e'/
c     data yc3v/'e','c3','si.v'/
      data chc3v/
     + 1.000, 1.000, 1.000,
     + 1.000, 1.000,-1.000,
     + 2.000,-1.000, 0.000/
c
      data ic4/4,4,1,1,1,1
     +             ,1,2,3,4/
      data yrc4/'a','b','e+','e-'/
c     data yc4/'e','c4','c2','c4**3'/
      data chc4/
     + 1.000, 1.000, 1.000, 1.000,
     + 1.000,-1.000, 1.000,-1.000,
     + 1.000, 0.000,-1.000, 0.000,
     + 0.000, 1.000, 0.000,-1.000/
c
      data ic4h/8,8,1,1,1,1,1,1,1,1
     +             ,0,0,0,0,0,0,0,0/
      data yrc4h/'ag','bg','eg+','eg-','au','bu','eu+','eu-'/
c     data yc4h/'e','c4','c2','c4**3','i','s4**3','si.h','s4'/
      data chc4h/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000,-1.000,
     + 1.000, 0.000,-1.000, 0.000, 1.000, 0.000,-1.000, 0.000,
     + 0.000, 1.000, 0.000,-1.000, 0.000, 1.000, 0.000,-1.000,
     + 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000,-1.000, 1.000,-1.000, 1.000,
     + 1.000, 0.000,-1.000, 0.000,-1.000, 0.000, 1.000, 0.000,
     + 0.000, 1.000, 0.000,-1.000, 0.000,-1.000, 0.000, 1.000/
c
      data ic4v/5,8,1,1,2,2,2
     +             ,1,3,2,5,6/
      data yrc4v/'a1','a2','b1','b2','e'/
c     data yc4v/'e','c2','c4','si.v','si.d'/
      data chc4v/
     + 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000,
     + 1.000, 1.000,-1.000, 1.000,-1.000,
     + 1.000, 1.000,-1.000,-1.000, 1.000,
     + 2.000,-2.000, 0.000, 0.000, 0.000/
c
      data ic5/5,5,1,1,1,1,1
     +             ,1,2,3,4,5/
      data yrc5/'a','e1+','e1-','e2+','e2-'/
c     data yc5/'e','c5','c5**2','c5**3','c5**4'/
      data chc5/
     + 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 0.309,-0.809,-0.809, 0.309,
     + 0.000, 0.951, 0.588,-0.588,-0.951,
     + 1.000,-0.809, 0.309, 0.309,-0.809,
     + 0.000, 0.588,-0.951, 0.951,-0.588/
c
      data ic5h/10,10,1,1,1,1,1,1,1,1,1,1
     +             ,0,0,0,0,0,0,0,0,0,0/
      data yrc5h/'a''','e1''+','e1''-','e2''+','e2''-','a"',
     +           'e1"+','e1"-','e2"+','e2"-'/
c     data yc5h/'e','c5','c5**2','c5**3','c5**4','si.h','s5',
c    +           's5**7','s5**3','s5**9'/
      data chc5h/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 
     + 1.000, 1.000, 1.000, 0.309,-0.809,-0.809, 0.309, 1.000, 
     + 0.309,-0.809,-0.809, 0.309,
     + 0.000, 0.951, 0.588,-0.588,-0.951, 0.000, 0.951, 0.588,
     +-0.588,-0.951,
     + 1.000,-0.809, 0.309, 0.309,-0.809, 1.000,-0.809, 0.309, 
     + 0.309,-0.809,
     + 0.000, 0.588,-0.951, 0.951,-0.588, 0.000, 0.588,-0.951, 
     + 0.951,-0.588,
     + 1.000, 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,
     +-1.000,-1.000,
     + 1.000, 0.309,-0.809,-0.809, 0.309,-1.000,-0.309, 0.809, 
     + 0.809,-0.309,
     + 0.000, 0.951, 0.588,-0.588,-0.951, 0.000,-0.951,-0.588, 
     + 0.588, 0.951,
     + 1.000,-0.809, 0.309, 0.309,-0.809,-1.000, 0.809,-0.309,
     +-0.309, 0.809,
     + 0.000, 0.588,-0.951, 0.951,-0.588, 0.000,-0.588, 0.951,
     +-0.951, 0.588/
c
      data ic5v/4,10,1,2,2,5
     +             ,1,2,3,6/
      data yrc5v/'a1','a2','e1','e2'/
c     data yc5v/'e','c5','c5^2','si.v'/
      data chc5v/
     + 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000,-1.000,
     + 2.000, 0.618,-1.618, 0.000,
     + 2.000,-1.618, 0.618, 0.000/
c
      data ic6/6,6,1,1,1,1,1,1
     +             ,1,2,3,4,5,6/
      data yrc6/'a','b','e1+','e1-','e2+','e2-'/
c     data yc6/'e','c6','c3','c2','c3**2','c6**5'/
      data chc6/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000,
     + 1.000, 0.500,-0.500,-1.000,-0.500, 0.500,
     + 0.000, 0.866, 0.866, 0.000,-0.866,-0.866,
     + 1.000,-0.500,-0.500, 1.000,-0.500,-0.500,
     + 0.000, 0.866,-0.866, 0.000, 0.866,-0.866/
c
      data ic6h/12,12,1,1,1,1,1,1,1,1,1,1,1,1
     +             ,0,0,0,0,0,0,0,0,0,0,0,0/
      data yrc6h/'ag','bg','e1g+','e1g-','e2g+','e2g-','au',
     +           'bu','e1u+','e1u-','e2u+','e2u-'/
c     data yc6h/'e','c6','c3','c2','c3**2','c6**5','i',
c    +          's3**5','s6**5','si.h','s6','s3'/
      data chc6h/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 
     + 1.000, 1.000, 1.000, 1.000, 1.000,-1.000, 1.000,-1.000, 
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000,-1.000,
     + 1.000, 0.500,-0.500,-1.000,-0.500, 0.500, 1.000, 0.500,
     +-0.500,-1.000,-0.500, 0.500, 0.000, 0.866, 0.866, 0.000,
     +-0.866,-0.866, 0.000, 0.866, 0.866, 0.000,-0.866,-0.866,
     + 1.000,-0.500,-0.500, 1.000,-0.500,-0.500, 1.000,-0.500,
     +-0.500, 1.000,-0.500,-0.500, 0.000, 0.866,-0.866, 0.000, 
     + 0.866,-0.866, 0.000, 0.866,-0.866, 0.000, 0.866,-0.866,
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,
     +-1.000,-1.000,-1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 
     + 1.000,-1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000,
     + 1.000, 0.500,-0.500,-1.000,-0.500, 0.500,-1.000,-0.500, 
     + 0.500, 1.000, 0.500,-0.500, 0.000, 0.866, 0.866, 0.000,
     +-0.866,-0.866, 0.000,-0.866,-0.866, 0.000, 0.866, 0.866,
     + 1.000,-0.500,-0.500, 1.000,-0.500,-0.500,-1.000, 0.500, 
     + 0.500,-1.000, 0.500, 0.500, 0.000, 0.866,-0.866, 0.000, 
     + 0.866,-0.866, 0.000,-0.866, 0.866, 0.000,-0.866, 0.866/
c
      data ic6v/6,12,1,1,2,2,3,3
     +             ,1,4,3,2,7,10/
      data yrc6v/'a1','a2','b1','b2','e1','e2'/
c     data yc6v/'e','c2','c3','c6','si.v','si.d'/
      data chc6v/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000,-1.000, 1.000,
     + 2.000,-2.000,-1.000, 1.000, 0.000, 0.000,
     + 2.000, 2.000,-1.000,-1.000, 0.000, 0.000/
c
      data ic7/7,7,1,1,1,1,1,1,1
     +             ,1,2,3,4,5,6,7/
      data yrc7/'a','e1+','e1-','e2+','e2-','e3+','e3-'/
c     data yc7/'e','c7','c7','c7','c7**3','c7**3','c7**5'/
      data chc7/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 0.623,-0.223,-0.901,-0.901,-0.223, 0.623,
     + 0.000, 0.782, 0.975,-0.434, 0.434,-0.975,-0.782,
     + 1.000,-0.223,-0.901, 0.623, 0.623,-0.901,-0.223,
     + 0.000, 0.975, 0.434,-0.782, 0.782,-0.434,-0.975,
     + 1.000,-0.901, 0.623,-0.223,-0.223, 0.623,-0.901,
     + 0.000,-0.434,-0.782, 0.975,-0.975, 0.782, 0.434/
c
      data ic7v/5,14,1,2,2,2,7
     +             ,0,0,0,0,0/
      data yrc7v/'a1','a2','e1','e2','e3'/
c     data yc7v/'e','c7','c7^2','c7^3','si.v'/
      data chc7v/
     + 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000, 1.000,-1.000,
     + 2.000, 1.245,-0.445,-1.802, 0.000,
     + 2.000,-0.445,-1.802, 1.245, 0.000,
     + 2.000,-1.802, 1.245,-0.445, 0.000/
c
      data ic8/8,8,1,1,1,1,1,1,1,1
     +             ,1,2,3,5,7,4,6,8/
      data yrc8/'a','b','e1+','e1-','e2+','e2-','e3+','e3-'/
c     data yc8/'e','c8','c4','c2','c4**3','c8**3','c8**5','c8**7'/
      data chc8/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000,-1.000, 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,
     + 1.000, 0.707, 0.000,-1.000, 0.000,-0.707,-0.707, 0.707,
     + 0.000, 0.000, 1.000, 0.000,-1.000, 0.000, 0.000, 0.000,
     + 1.000, 0.000,-1.000, 1.000,-1.000, 0.000, 0.000, 0.000,
     + 0.000, 1.000, 0.000, 0.000, 0.000,-1.000, 1.000,-1.000,
     + 1.000,-0.707, 0.000,-1.000, 0.000, 0.707, 0.707,-0.707,
     + 0.000, 0.000, 1.000, 0.000,-1.000, 0.000, 0.000, 0.000/
c
      data ici/2,2,1,1
     +             ,1,2/
      data yrci/'ag','au'/
c     data yci/'e','i=s2'/
      data chci/
     + 1.000, 1.000,
     + 1.000,-1.000/
c
      data ics/2,2,1,1
     +             ,1,2/
      data yrcs/'a''','a'''''/
c     data ycs/'e','si.h'/
      data chcs/
     + 1.000, 1.000,
     + 1.000,-1.000/
c
      data id2/4,4,1,1,1,1
     +             ,1,2,3,4/
      data yrd2/'a1','b1','b2','b3'/
c     data yd2/'e','c2z','c2y','c2x'/
      data chd2/
     + 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000,-1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000,
     + 1.000,-1.000,-1.000, 1.000/
c
      data id2d/5,8,1,1,2,2,2
     +             ,1,2,7,3,5/
      data yrd2d/'a1','a2','b1','b2','e'/
c     data yd2d/'e','c2','s4','c2''','si.d'/
      data chd2d/
     + 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000,
     + 1.000, 1.000,-1.000, 1.000,-1.000,
     + 1.000, 1.000,-1.000,-1.000, 1.000,
     + 2.000,-2.000, 0.000, 0.000, 0.000/
c
      data id2h/8,8,1,1,1,1,1,1,1,1
     +             ,1,2,5,6,4,3,8,7/
      data yrd2h/'ag','au','b1g','b1u','b2g','b2u','b3g','b3u'/
c     data yd2h/'e','c2z','c2y','c2x','i','si.xy','si.xz','si.yz'/
      data chd2h/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,-1.000,
     + 1.000, 1.000,-1.000,-1.000, 1.000, 1.000,-1.000,-1.000,
     + 1.000, 1.000,-1.000,-1.000,-1.000,-1.000, 1.000, 1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000,-1.000, 1.000,-1.000, 1.000,
     + 1.000,-1.000,-1.000, 1.000, 1.000,-1.000,-1.000, 1.000,
     + 1.000,-1.000,-1.000, 1.000,-1.000, 1.000, 1.000,-1.000/
c
      data id3/3,6,1,2,3
     +             ,0,0,0/
      data yrd3/'a1','a2','e'/
c     data yd3/'e','c3','c2'/
      data chd3/
     + 1.000, 1.000, 1.000,
     + 1.000, 1.000,-1.000,
     + 2.000,-1.000, 0.000/
c
      data id3d/6,12,1,2,3,1,2,3
     +             ,0,0,0,0,0,0/
      data yrd3d/'a1g','a1u','a2g','a2u','eg','eu'/
c     data yd3d/'e','c3','c2','i','s6','si.d'/
      data chd3d/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,
     + 1.000, 1.000,-1.000, 1.000, 1.000,-1.000,
     + 1.000, 1.000,-1.000,-1.000,-1.000, 1.000,
     + 2.000,-1.000, 0.000, 2.000,-1.000, 0.000,
     + 2.000,-1.000, 0.000,-2.000, 1.000, 0.000/
c
      data id3h/6,12,1,1,2,2,3,3
     +             ,1,4,2,5,7,10/
      data yrd3h/'a1''','a1"','a2''','a2"','e''','e"'/
c     data yd3h/'e','si.h','c3','s3','c2','si.v'/
      data chd3h/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000,
     + 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000,-1.000, 1.000,
     + 2.000, 2.000,-1.000,-1.000, 0.000, 0.000,
     + 2.000,-2.000,-1.000, 1.000, 0.000, 0.000/
c
      data id4/5,8,1,2,1,2,2
     +             ,1,2,3,5,6/
      data yrd4/'a1','a2','b1','b2','e'/
c     data yd4/'e','c4','c2','c2''','c2"'/
      data chd4/
     + 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000,
     + 1.000,-1.000, 1.000, 1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,
     + 2.000, 0.000,-2.000, 0.000, 0.000/
c
      data id4d/7,16,1,1,2,2,2,4,4
     +             ,1,3,2,13,15,5,9/
      data yrd4d/'a1','a2','b1','b2','e1','e2','e3'/
c     data yd4d/'e','c2','c4','s8','s8**3','c2''','si.d'/
      data chd4d/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000, 1.000,-1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000,-1.000, 1.000,
     + 2.000,-2.000, 0.000, 1.414,-1.414, 0.000, 0.000,
     + 2.000, 2.000,-2.000, 0.000, 0.000, 0.000, 0.000,
     + 2.000,-2.000, 0.000,-1.414, 1.414, 0.000, 0.000/
c
      data id4h/10,16,1,1,2,2,2,1,1,2,2,2
     +             ,1,3,2,9,10,7,5,6,13,14/
      data yrd4h/'a1g','a1u','a2g','a2u','b1g','b1u','b2g','b2u',
     +           'eg','eu'/
c     data yd4h/'e','c2','c4','c2''','c2''''','i','si.h','s4',
c    +           'si.v','si.d'/
      data chd4h/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,-1.000,
     +-1.000,-1.000,-1.000,-1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000, 1.000, 1.000, 1.000,
     +-1.000,-1.000, 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,
     +-1.000,-1.000, 1.000, 1.000,
     + 1.000, 1.000,-1.000, 1.000,-1.000, 1.000, 1.000,-1.000, 
     + 1.000,-1.000,
     + 1.000, 1.000,-1.000, 1.000,-1.000,-1.000,-1.000, 1.000,
     +-1.000, 1.000,
     + 1.000, 1.000,-1.000,-1.000, 1.000, 1.000, 1.000,-1.000,
     +-1.000, 1.000,
     + 1.000, 1.000,-1.000,-1.000, 1.000,-1.000,-1.000, 1.000, 
     + 1.000,-1.000,
     + 2.000,-2.000, 0.000, 0.000, 0.000, 2.000,-2.000, 0.000, 
     + 0.000, 0.000,
     + 2.000,-2.000, 0.000, 0.000, 0.000,-2.000, 2.000, 0.000, 
     + 0.000, 0.000/
c
      data id5/4,10,1,2,2,5
     +             ,0,0,0,0/
      data yrd5/'a1','a2','e1','e2'/
c     data yd5/'e','c5','c5**2','c2'/
      data chd5/
     + 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000,-1.000,
     + 2.000, 0.618,-1.618, 0.000,
     + 2.000,-1.618, 0.618, 0.000/
c
      data id5d/8,20,1,2,2,5,1,2,2,5
     +             ,1,2,3,6,19,16,18,11/
      data yrd5d/'a1g','a1u','a2g','a2u','e1g','e1u','e2g','e2u'/
c     data yd5d/'e','c5','c5**2','c2','i','s10','s10**3','si.d'/
      data chd5d/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,-1.000,
     + 1.000, 1.000, 1.000,-1.000, 1.000, 1.000, 1.000,-1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,-1.000, 1.000,
     + 2.000, 0.618,-1.618, 0.000, 2.000,-1.618, 0.618, 0.000,
     + 2.000, 0.618,-1.618, 0.000,-2.000, 1.618,-0.618, 0.000,
     + 2.000,-1.618, 0.618, 0.000, 2.000, 0.618,-1.618, 0.000,
     + 2.000,-1.618, 0.618, 0.000,-2.000,-0.618, 1.618, 0.000/
c
      data id5h/8,20,1,2,2,5,1,2,2,5
     +             ,1,2,3,11,6,7,8,16/
      data yrd5h/'a1''','a1"','a2''','a2"','e1''','e1"','e2''','e2"'/
c     data yd5h/'e','c5','c5**2','c2','si.h','s5','s5**3','si.v'/
      data chd5h/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,-1.000,
     + 1.000, 1.000, 1.000,-1.000, 1.000, 1.000, 1.000,-1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,-1.000, 1.000,
     + 2.000, 0.618,-1.618, 0.000, 2.000, 0.618,-1.618, 0.000,
     + 2.000, 0.618,-1.618, 0.000,-2.000,-0.618, 1.618, 0.000,
     + 2.000,-1.618, 0.618, 0.000, 2.000,-1.618, 0.618, 0.000,
     + 2.000,-1.618, 0.618, 0.000,-2.000, 1.618,-0.618, 0.000/
c
      data id6/6,12,1,2,2,1,3,3
     +             ,0,0,0,0,0,0/
      data yrd6/'a1','a2','b1','b2','e1','e2'/
c     data yd6/'e','c6','c3','c2','c2''','c2"'/
      data chd6/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000,-1.000, 1.000,
     + 2.000, 1.000,-1.000,-2.000, 0.000, 0.000,
     + 2.000,-1.000,-1.000, 2.000, 0.000, 0.000/
c
      data id6d/9,24,1,2,2,2,2,2,1,6,6
     +             ,0,0,0,0,0,0,0,0,0/
      data yrd6d/'a1','a2','b1','b2','e1','e2','e3','e4','e5'/
c     data yd6d/'e','s12','c6','s4','c3','s12**5','c2','c2''','si.d'/
      data chd6d/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000, 1.000,-1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000,
     + 2.000, 1.732, 1.000, 0.000,-1.000,-1.732,-2.000, 0.000, 0.000,
     + 2.000, 1.000,-1.000,-2.000,-1.000, 1.000, 2.000, 0.000, 0.000,
     + 2.000, 0.000,-2.000, 0.000, 2.000, 0.000,-2.000, 0.000, 0.000,
     + 2.000,-1.000,-1.000, 2.000,-1.000,-1.000, 2.000, 0.000, 0.000,
     + 2.000,-1.732, 1.000, 0.000,-1.000, 1.732,-2.000, 0.000, 0.000/
c
      data id6h/12,24,1,1,2,2,3,3,1,1,2,2,3,3
     +             ,1,4,3,2,13,16,10,7,8,9,22,19/
      data yrd6h/'a1g','a1u','a2g','a2u','b1g','b1u','b2g',
     +           'b2u','e1g','e1u','e2g','e2u'/
c     data yd6h/'e','c2','c3','c6','c2''','c2''''','i','si.h',
c    +          's6','s3','si.d','si.v'/
      data chd6h/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 
     + 1.000, 1.000,-1.000,-1.000,-1.000,-1.000,-1.000,-1.000,
     + 1.000, 1.000, 1.000, 1.000,-1.000,-1.000, 1.000, 1.000, 
     + 1.000, 1.000,-1.000,-1.000, 1.000, 1.000, 1.000, 1.000,
     +-1.000,-1.000,-1.000,-1.000,-1.000,-1.000, 1.000, 1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 
     + 1.000,-1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000,
     + 1.000,-1.000, 1.000,-1.000,-1.000, 1.000, 1.000,-1.000, 
     + 1.000,-1.000,-1.000, 1.000, 1.000,-1.000, 1.000,-1.000,
     +-1.000, 1.000,-1.000, 1.000,-1.000, 1.000, 1.000,-1.000,
     + 2.000,-2.000,-1.000, 1.000, 0.000, 0.000, 2.000,-2.000,
     +-1.000, 1.000, 0.000, 0.000, 2.000,-2.000,-1.000, 1.000, 
     + 0.000, 0.000,-2.000, 2.000, 1.000,-1.000, 0.000, 0.000,
     + 2.000, 2.000,-1.000,-1.000, 0.000, 0.000, 2.000, 2.000,
     +-1.000,-1.000, 0.000, 0.000, 2.000, 2.000,-1.000,-1.000, 
     + 0.000, 0.000,-2.000,-2.000, 1.000, 1.000, 0.000, 0.000/
c
      data id8/7,16,1,2,2,2,1,4,4
     +             ,0,0,0,0,0,0,0/
      data yrd8/'a1','a2','b1','b2','e1','e2','e3'/
c     data yd8/'e','c8','c8**3','c4','c2','c2''','c2"'/
      data chd8/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,
     + 1.000,-1.000,-1.000, 1.000, 1.000, 1.000,-1.000,
     + 1.000,-1.000,-1.000, 1.000, 1.000,-1.000, 1.000,
     + 2.000, 1.414,-1.414, 0.000,-2.000, 0.000, 0.000,
     + 2.000, 0.000, 0.000,-2.000, 2.000, 0.000, 0.000,
     + 2.000,-1.414, 1.414, 0.000,-2.000, 0.000, 0.000/
c
      data id8h/14,32,1,2,2,2,1,4,4,1,2,2,2,1,4,4
     +             ,0,0,0,0,0,0,0,0,0,0,0,0,0,0/
      data yrd8h/'a1g','a2g','b1g','b2g','e1g','e2g','e3g',
     +           'a1u','a2u','b1u','b2u','e1u','e2u','e3u'/
c     data yd8h/'e','c8','c8**3','c4','c2','c2''','c2"','i',
c    +          's8','s8**3','s4','si.h','si.d','si.v'/
      data chd8h/
     + 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 
     + 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,-1.0,-1.0, 1.0, 1.0, 1.0, 
     + 1.0, 1.0,-1.0,-1.0, 1.0,-1.0,-1.0, 1.0, 1.0, 1.0,-1.0, 1.0,
     +-1.0,-1.0, 1.0, 1.0, 1.0,-1.0, 1.0,-1.0,-1.0, 1.0, 1.0,-1.0, 
     + 1.0, 1.0,-1.0,-1.0, 1.0, 1.0,-1.0, 1.0, 2.0, 1.414,-1.414,
     + 0.0,-2.00, 0.00, 0.00, 2.00, 1.414,-1.414, 0.00,-2.00, 0.00, 
     + 0.00, 2.00, 0.00, 0.00,-2.00, 2.00, 0.00, 0.00, 2.00, 0.00, 
     + 0.00,-2.00, 2.00, 0.00, 0.00, 2.00,-1.414, 1.414, 0.00,-2.00, 
     + 0.00, 0.00, 2.00,-1.414, 1.414, 0.00,-2.00, 0.00, 0.00,
     + 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00,-1.00,-1.00,-1.00,
     +-1.00,-1.00,-1.00,-1.00, 1.00, 1.00, 1.00, 1.00, 1.00,-1.00,
     +-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, 1.00, 1.00, 1.00,-1.00,
     +-1.00, 1.00, 1.00, 1.00,-1.00,-1.00, 1.00, 1.00,-1.00,-1.00,
     +-1.00, 1.00, 1.00,-1.00,-1.00, 1.00, 1.00,-1.00, 1.00,-1.00, 
     + 1.00, 1.00,-1.00,-1.00, 1.00,-1.00, 2.00, 1.414,-1.414,0.00,
     +-2.00, 0.00, 0.00,-2.00,-1.414, 1.414, 0.00, 2.00, 0.00, 0.00,
     + 2.00, 0.00, 0.00,-2.00, 2.00, 0.00, 0.00,-2.00, 0.00, 0.00, 
     + 2.00,-2.00, 0.00, 0.00, 2.00,-1.414, 1.414, 0.00,-2.00, 
     + 0.00, 0.00,-2.00, 1.414,-1.414, 0.00, 2.00, 0.00, 0.00/
c
      data ii/5,60,1,12,12,20,15
     +             ,0,0,0,0,0/
      data yri/'a','t1','t2','g','h'/
c     data yi/'e','c5','c5^2','c3','c2'/
      data chi/
     + 1.000, 1.000, 1.000, 1.000, 1.000,
     + 3.000, 1.618,-0.618, 0.000,-1.000,
     + 3.000,-0.618, 1.618, 0.000,-1.000,
     + 4.000,-1.000,-1.000, 1.000, 0.000,
     + 5.000, 0.000, 0.000,-1.000, 1.000/
c
c
      data iih/10,120,1,12,12,20,15,1,12,12,20,15
     +             ,0,0,0,0,0,0,0,0,0,0/
      data yrih/'ag','t1g','t2g','gg','hg','au','t1u','t2u','gu','hu'/
c     data yih/'e','c5','c5^2','c3','c2','i','s10','s10^3','s6','sigma'/
      data chih/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 
     + 1.000, 1.000, 3.000, 1.618,-0.618, 0.000,-1.000, 3.000, 
     + 1.618,-0.618, 0.000,-1.000,
     + 3.000,-0.618, 1.618, 0.000,-1.000, 3.000,-0.618, 1.618, 
     + 0.000,-1.000, 4.000,-1.000,-1.000, 1.000, 0.000, 4.000,
     +-1.000,-1.000, 1.000, 0.000,
     + 5.000, 0.000, 0.000,-1.000, 1.000, 5.000, 0.000, 0.000,
     +-1.000, 1.000,
     + 1.000, 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,
     +-1.000,-1.000,
     + 3.000, 1.618,-0.618, 0.000,-1.000,-3.000,-1.618, 0.618, 
     + 0.000, 1.000,
     + 3.000,-0.618, 1.618, 0.000,-1.000,-3.000, 0.618,-1.618, 
     + 0.000, 1.000,
     + 4.000,-1.000,-1.000, 1.000, 0.000,-4.000, 1.000, 1.000,
     +-1.000, 0.000,
     + 5.000, 0.000, 0.000,-1.000, 1.000,-5.000, 0.000, 0.000, 
     + 1.000,-1.000/
c
      data io/5,24,1,8,3,6,6
     +             ,0,0,0,0,0/
      data yro/'a1','a2','e','t1','t2'/
c     data yo/'e','c3','c2','c2''','c4'/
      data cho/
     + 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000,
     + 2.000,-1.000, 2.000, 0.000, 0.000,
     + 3.000, 0.000,-1.000,-1.000, 1.000,
     + 3.000, 0.000,-1.000, 1.000,-1.000/
c
      data ioh/10,48,1,8,3,6,6,1,8,3,6,6
     +             ,1,5,2,14,13,25,29,26,38,37/
      data yroh/'a1g','a1u','a2g','a2u','eg','eu','t1g','t1u',
     +          't2g','t2u'/
c     data yoh/'e','c3','c2','c2''','c4','i','s6','si.h',
c    +         'si.d','s4'/
      data choh/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,-1.000,
     +-1.000,-1.000,-1.000,-1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000, 1.000, 1.000, 1.000,
     +-1.000,-1.000, 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,
     +-1.000,-1.000, 1.000, 1.000,
     + 2.000,-1.000, 2.000, 0.000, 0.000, 2.000,-1.000, 2.000, 
     + 0.000, 0.000, 2.000,-1.000, 2.000, 0.000, 0.000,-2.000, 
     + 1.000,-2.000, 0.000, 0.000,
     + 3.000, 0.000,-1.000,-1.000, 1.000, 3.000, 0.000,-1.000,
     +-1.000, 1.000,
     + 3.000, 0.000,-1.000,-1.000, 1.000,-3.000, 0.000, 1.000, 
     + 1.000,-1.000,
     + 3.000, 0.000,-1.000, 1.000,-1.000, 3.000, 0.000,-1.000, 
     + 1.000,-1.000,
     + 3.000, 0.000,-1.000, 1.000,-1.000,-3.000, 0.000, 1.000,
     +-1.000, 1.000/
c
      data is2/2,2,1,1
     +             ,1,2/
      data yrs2/'ag','au'/
c     data ys2/'e','i=s2'/
      data chs2/
     + 1.000, 1.000,
     + 1.000,-1.000/
c
      data is4/4,4,1,1,1,1
     +             ,0,0,0,0/
      data yrs4/'a','b','e+','e-'/
c     data ys4/'e','s4','c2','s4**3'/
      data chs4/
     + 1.000, 1.000, 1.000, 1.000,
     + 1.000,-1.000, 1.000,-1.000,
     + 1.000, 0.000,-1.000, 0.000,
     + 0.000, 1.000, 0.000,-1.000/
c
      data is6/6,6,1,1,1,1,1,1
     +             ,0,0,0,0,0,0/
      data yrs6/'ag','au','eg+','eg-','eu+','eu-'/
c     data ys6/'e','c3','c3**2','i','s6','s6**5'/
      data chs6/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,
     + 1.000,-0.500,-0.500, 1.000,-0.500,-0.500,
     + 0.000, 1.732,-1.732, 0.000,-1.732, 1.732,
     + 1.000,-0.500,-0.500,-1.000, 0.500, 0.500,
     + 0.000, 1.732,-1.732, 0.000, 1.732,-1.732/
c
      data is8/8,8,1,1,1,1,1,1,1,1
     +             ,0,0,0,0,0,0,0,0/
      data yrs8/'a','b','e1+','e1-','e2+','e2-','e3+','e3-'/
c     data ys8/'e','s8','c4','s8**3','c2','s8**5','c4**3','s8**7'/
      data chs8/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000,-1.000, 1.000,-1.000, 1.000,-1.000, 1.000,-1.000,
     + 1.000, 0.707, 0.000,-0.707,-1.000,-0.707, 0.000, 0.707,
     + 0.000, 0.000, 1.000, 0.000, 0.000, 0.000,-1.000, 0.000,
     + 1.000, 0.000,-1.000, 0.000, 1.000, 0.000,-1.000, 0.000,
     + 0.000, 1.000, 0.000,-1.000, 0.000, 1.000, 0.000,-1.000,
     + 1.000,-0.707, 0.000, 0.707,-1.000, 0.707, 0.000,-0.707,
     + 0.000, 0.000,-1.000, 0.000, 0.000, 0.000, 1.000, 0.000/
c
      data it/4,12,1,4,4,3
     +             ,0,0,0,0/
      data yrt/'a','e+','e-','t'/
c     data yt/'e','c3','c3^2','c2'/
      data cht/
     + 1.000, 1.000, 1.000, 1.000,
     + 1.000,-0.500,-0.500, 1.000,
     + 0.000, 0.866,-0.866, 0.000,
     + 3.000, 0.000, 0.000,-1.000/
c
      data itd/5,24,1,8,3,6,6
     +             ,1,5,2,13,14/
      data yrtd/'a1','a2','e','t1','t2'/
c     data ytd/'e','c3','c2','si.d','s4'/
      data chtd/
     + 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000, 1.000, 1.000,-1.000,-1.000,
     + 2.000,-1.000, 2.000, 0.000, 0.000,
     + 3.000, 0.000,-1.000,-1.000, 1.000,
     + 3.000, 0.000,-1.000, 1.000,-1.000/
c
      data ith/8,24,1,4,4,3,1,4,4,3
     +             ,0,0,0,0,0,0,0,0/
      data yrth/'ag','eg+','eg-','tg','au','eu+','eu-','tu'/
c     data yth/'e','c3','c3^2','c2','i','s6^5','s6','si.h'/
      data chth/
     + 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,
     + 1.000,-0.500,-0.500, 1.000, 1.000,-0.500,-0.500, 1.000,
     + 0.000, 0.866,-0.866, 0.000, 0.000, 0.866,-0.866, 0.000,
     + 3.000, 0.000, 0.000,-1.000, 3.000, 0.000, 0.000,-1.000,
     + 1.000, 1.000, 1.000, 1.000,-1.000,-1.000,-1.000,-1.000,
     + 1.000,-0.500,-0.500, 1.000,-1.000, 0.500, 0.500,-1.000,
     + 0.000, 0.866,-0.866, 0.000, 0.000,-0.866, 0.866, 0.000,
     + 3.000, 0.000, 0.000,-1.000,-3.000, 0.000, 0.000, 1.000/
c
c here is beginning of instructions - also machine generated
c
_IFN(vms)
      call prpnam(zname,8,zgroup,8,naxis)
_ELSE
      call prpnam(%ref(zname),8,%ref(zgroup),8,naxis)
_ENDIF
      ipointer(1)=0
c
c
      if(zname.eq.'c1') then
      k=0
      nir=nc1
      norder=ic1(2)
      do i=1,nir
      iir(i)=ic1(i+2)
      ipointer(i)=ic1(i+2+nir)
      zlabir(i)=yrc1(i)
      do j=1,nir
      k=k+1
      chars(k)=chc1(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c1h') then
      k=0
      nir=nc1h
      norder=ic1h(2)
      do i=1,nir
      iir(i)=ic1h(i+2)
      ipointer(i)=ic1h(i+2+nir)
      zlabir(i)=yrc1h(i)
      do j=1,nir
      k=k+1
      chars(k)=chc1h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c2') then
      k=0
      nir=nc2
      norder=ic2(2)
      do i=1,nir
      iir(i)=ic2(i+2)
      ipointer(i)=ic2(i+2+nir)
      zlabir(i)=yrc2(i)
      do j=1,nir
      k=k+1
      chars(k)=chc2(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c2h') then
      k=0
      nir=nc2h
      norder=ic2h(2)
      do i=1,nir
      iir(i)=ic2h(i+2)
      ipointer(i)=ic2h(i+2+nir)
      zlabir(i)=yrc2h(i)
      do j=1,nir
      k=k+1
      chars(k)=chc2h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c2v') then
      k=0
      nir=nc2v
      norder=ic2v(2)
      do i=1,nir
      iir(i)=ic2v(i+2)
      ipointer(i)=ic2v(i+2+nir)
      zlabir(i)=yrc2v(i)
      do j=1,nir
      k=k+1
      chars(k)=chc2v(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c3') then
      k=0
      nir=nc3
      norder=ic3(2)
      do i=1,nir
      iir(i)=ic3(i+2)
      ipointer(i)=ic3(i+2+nir)
      zlabir(i)=yrc3(i)
      do j=1,nir
      k=k+1
      chars(k)=chc3(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c3h') then
      k=0
      nir=nc3h
      norder=ic3h(2)
      do i=1,nir
      iir(i)=ic3h(i+2)
      ipointer(i)=ic3h(i+2+nir)
      zlabir(i)=yrc3h(i)
      do j=1,nir
      k=k+1
      chars(k)=chc3h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c3v') then
      k=0
      nir=nc3v
      norder=ic3v(2)
      do i=1,nir
      iir(i)=ic3v(i+2)
      ipointer(i)=ic3v(i+2+nir)
      zlabir(i)=yrc3v(i)
      do j=1,nir
      k=k+1
      chars(k)=chc3v(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c4') then
      k=0
      nir=nc4
      norder=ic4(2)
      do i=1,nir
      iir(i)=ic4(i+2)
      ipointer(i)=ic4(i+2+nir)
      zlabir(i)=yrc4(i)
      do j=1,nir
      k=k+1
      chars(k)=chc4(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c4h') then
      k=0
      nir=nc4h
      norder=ic4h(2)
      do i=1,nir
      iir(i)=ic4h(i+2)
      ipointer(i)=ic4h(i+2+nir)
      zlabir(i)=yrc4h(i)
      do j=1,nir
      k=k+1
      chars(k)=chc4h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c4v') then
      k=0
      nir=nc4v
      norder=ic4v(2)
      do i=1,nir
      iir(i)=ic4v(i+2)
      ipointer(i)=ic4v(i+2+nir)
      zlabir(i)=yrc4v(i)
      do j=1,nir
      k=k+1
      chars(k)=chc4v(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c5') then
      k=0
      nir=nc5
      norder=ic5(2)
      do i=1,nir
      iir(i)=ic5(i+2)
      ipointer(i)=ic5(i+2+nir)
      zlabir(i)=yrc5(i)
      do j=1,nir
      k=k+1
      chars(k)=chc5(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c5h') then
      k=0
      nir=nc5h
      norder=ic5h(2)
      do i=1,nir
      iir(i)=ic5h(i+2)
      ipointer(i)=ic5h(i+2+nir)
      zlabir(i)=yrc5h(i)
      do j=1,nir
      k=k+1
      chars(k)=chc5h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c5v') then
      k=0
      nir=nc5v
      norder=ic5v(2)
      do i=1,nir
      iir(i)=ic5v(i+2)
      ipointer(i)=ic5v(i+2+nir)
      zlabir(i)=yrc5v(i)
      do j=1,nir
      k=k+1
      chars(k)=chc5v(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c6') then
      k=0
      nir=nc6
      norder=ic6(2)
      do i=1,nir
      iir(i)=ic6(i+2)
      ipointer(i)=ic6(i+2+nir)
      zlabir(i)=yrc6(i)
      do j=1,nir
      k=k+1
      chars(k)=chc6(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c6h') then
      k=0
      nir=nc6h
      norder=ic6h(2)
      do i=1,nir
      iir(i)=ic6h(i+2)
      ipointer(i)=ic6h(i+2+nir)
      zlabir(i)=yrc6h(i)
      do j=1,nir
      k=k+1
      chars(k)=chc6h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c6v') then
      k=0
      nir=nc6v
      norder=ic6v(2)
      do i=1,nir
      iir(i)=ic6v(i+2)
      ipointer(i)=ic6v(i+2+nir)
      zlabir(i)=yrc6v(i)
      do j=1,nir
      k=k+1
      chars(k)=chc6v(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c7') then
      k=0
      nir=nc7
      norder=ic7(2)
      do i=1,nir
      iir(i)=ic7(i+2)
      ipointer(i)=ic7(i+2+nir)
      zlabir(i)=yrc7(i)
      do j=1,nir
      k=k+1
      chars(k)=chc7(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c7v') then
      k=0
      nir=nc7v
      norder=ic7v(2)
      do i=1,nir
      iir(i)=ic7v(i+2)
      ipointer(i)=ic7v(i+2+nir)
      zlabir(i)=yrc7v(i)
      do j=1,nir
      k=k+1
      chars(k)=chc7v(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'c8') then
      k=0
      nir=nc8
      norder=ic8(2)
      do i=1,nir
      iir(i)=ic8(i+2)
      ipointer(i)=ic8(i+2+nir)
      zlabir(i)=yrc8(i)
      do j=1,nir
      k=k+1
      chars(k)=chc8(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'ci') then
      k=0
      nir=nci
      norder=ici(2)
      do i=1,nir
      iir(i)=ici(i+2)
      ipointer(i)=ici(i+2+nir)
      zlabir(i)=yrci(i)
      do j=1,nir
      k=k+1
      chars(k)=chci(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'cs') then
      k=0
      nir=ncs
      norder=ics(2)
      do i=1,nir
      iir(i)=ics(i+2)
      ipointer(i)=ics(i+2+nir)
      zlabir(i)=yrcs(i)
      do j=1,nir
      k=k+1
      chars(k)=chcs(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d2') then
      k=0
      nir=nd2
      norder=id2(2)
      do i=1,nir
      iir(i)=id2(i+2)
      ipointer(i)=id2(i+2+nir)
      zlabir(i)=yrd2(i)
      do j=1,nir
      k=k+1
      chars(k)=chd2(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d2d') then
      k=0
      nir=nd2d
      norder=id2d(2)
      do i=1,nir
      iir(i)=id2d(i+2)
      ipointer(i)=id2d(i+2+nir)
      zlabir(i)=yrd2d(i)
      do j=1,nir
      k=k+1
      chars(k)=chd2d(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d2h') then
      k=0
      nir=nd2h
      norder=id2h(2)
      do i=1,nir
      iir(i)=id2h(i+2)
      ipointer(i)=id2h(i+2+nir)
      zlabir(i)=yrd2h(i)
      do j=1,nir
      k=k+1
      chars(k)=chd2h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d3') then
      k=0
      nir=nd3
      norder=id3(2)
      do i=1,nir
      iir(i)=id3(i+2)
      ipointer(i)=id3(i+2+nir)
      zlabir(i)=yrd3(i)
      do j=1,nir
      k=k+1
      chars(k)=chd3(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d3d') then
      k=0
      nir=nd3d
      norder=id3d(2)
      do i=1,nir
      iir(i)=id3d(i+2)
      ipointer(i)=id3d(i+2+nir)
      zlabir(i)=yrd3d(i)
      do j=1,nir
      k=k+1
      chars(k)=chd3d(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d3h') then
      k=0
      nir=nd3h
      norder=id3h(2)
      do i=1,nir
      iir(i)=id3h(i+2)
      ipointer(i)=id3h(i+2+nir)
      zlabir(i)=yrd3h(i)
      do j=1,nir
      k=k+1
      chars(k)=chd3h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d4') then
      k=0
      nir=nd4
      norder=id4(2)
      do i=1,nir
      iir(i)=id4(i+2)
      ipointer(i)=id4(i+2+nir)
      zlabir(i)=yrd4(i)
      do j=1,nir
      k=k+1
      chars(k)=chd4(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d4d') then
      k=0
      nir=nd4d
      norder=id4d(2)
      do i=1,nir
      iir(i)=id4d(i+2)
      ipointer(i)=id4d(i+2+nir)
      zlabir(i)=yrd4d(i)
      do j=1,nir
      k=k+1
      chars(k)=chd4d(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d4h') then
      k=0
      nir=nd4h
      norder=id4h(2)
      do i=1,nir
      iir(i)=id4h(i+2)
      ipointer(i)=id4h(i+2+nir)
      zlabir(i)=yrd4h(i)
      do j=1,nir
      k=k+1
      chars(k)=chd4h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d5') then
      k=0
      nir=nd5
      norder=id5(2)
      do i=1,nir
      iir(i)=id5(i+2)
      ipointer(i)=id5(i+2+nir)
      zlabir(i)=yrd5(i)
      do j=1,nir
      k=k+1
      chars(k)=chd5(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d5d') then
      k=0
      nir=nd5d
      norder=id5d(2)
      do i=1,nir
      iir(i)=id5d(i+2)
      ipointer(i)=id5d(i+2+nir)
      zlabir(i)=yrd5d(i)
      do j=1,nir
      k=k+1
      chars(k)=chd5d(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d5h') then
      k=0
      nir=nd5h
      norder=id5h(2)
      do i=1,nir
      iir(i)=id5h(i+2)
      ipointer(i)=id5h(i+2+nir)
      zlabir(i)=yrd5h(i)
      do j=1,nir
      k=k+1
      chars(k)=chd5h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d6') then
      k=0
      nir=nd6
      norder=id6(2)
      do i=1,nir
      iir(i)=id6(i+2)
      ipointer(i)=id6(i+2+nir)
      zlabir(i)=yrd6(i)
      do j=1,nir
      k=k+1
      chars(k)=chd6(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d6d') then
      k=0
      nir=nd6d
      norder=id6d(2)
      do i=1,nir
      iir(i)=id6d(i+2)
      ipointer(i)=id6d(i+2+nir)
      zlabir(i)=yrd6d(i)
      do j=1,nir
      k=k+1
      chars(k)=chd6d(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d6h') then
      k=0
      nir=nd6h
      norder=id6h(2)
      do i=1,nir
      iir(i)=id6h(i+2)
      ipointer(i)=id6h(i+2+nir)
      zlabir(i)=yrd6h(i)
      do j=1,nir
      k=k+1
      chars(k)=chd6h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d8') then
      k=0
      nir=nd8
      norder=id8(2)
      do i=1,nir
      iir(i)=id8(i+2)
      ipointer(i)=id8(i+2+nir)
      zlabir(i)=yrd8(i)
      do j=1,nir
      k=k+1
      chars(k)=chd8(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'d8h') then
      k=0
      nir=nd8h
      norder=id8h(2)
      do i=1,nir
      iir(i)=id8h(i+2)
      ipointer(i)=id8h(i+2+nir)
      zlabir(i)=yrd8h(i)
      do j=1,nir
      k=k+1
      chars(k)=chd8h(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'i') then
      k=0
      nir=ni
      norder=ii(2)
      do i=1,nir
      iir(i)=ii(i+2)
      ipointer(i)=ii(i+2+nir)
      zlabir(i)=yri(i)
      do j=1,nir
      k=k+1
      chars(k)=chi(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'ih') then
      k=0
      nir=nih
      norder=iih(2)
      do i=1,nir
      iir(i)=iih(i+2)
      ipointer(i)=iih(i+2+nir)
      zlabir(i)=yrih(i)
      do j=1,nir
      k=k+1
      chars(k)=chih(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'o') then
      k=0
      nir=no
      norder=io(2)
      do i=1,nir
      iir(i)=io(i+2)
      ipointer(i)=io(i+2+nir)
      zlabir(i)=yro(i)
      do j=1,nir
      k=k+1
      chars(k)=cho(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'oh') then
      k=0
      nir=noh
      norder=ioh(2)
      do i=1,nir
      iir(i)=ioh(i+2)
      ipointer(i)=ioh(i+2+nir)
      zlabir(i)=yroh(i)
      do j=1,nir
      k=k+1
      chars(k)=choh(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'s2') then
      k=0
      nir=ns2
      norder=is2(2)
      do i=1,nir
      iir(i)=is2(i+2)
      ipointer(i)=is2(i+2+nir)
      zlabir(i)=yrs2(i)
      do j=1,nir
      k=k+1
      chars(k)=chs2(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'s4') then
      k=0
      nir=ns4
      norder=is4(2)
      do i=1,nir
      iir(i)=is4(i+2)
      ipointer(i)=is4(i+2+nir)
      zlabir(i)=yrs4(i)
      do j=1,nir
      k=k+1
      chars(k)=chs4(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'s6') then
      k=0
      nir=ns6
      norder=is6(2)
      do i=1,nir
      iir(i)=is6(i+2)
      ipointer(i)=is6(i+2+nir)
      zlabir(i)=yrs6(i)
      do j=1,nir
      k=k+1
      chars(k)=chs6(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'s8') then
      k=0
      nir=ns8
      norder=is8(2)
      do i=1,nir
      iir(i)=is8(i+2)
      ipointer(i)=is8(i+2+nir)
      zlabir(i)=yrs8(i)
      do j=1,nir
      k=k+1
      chars(k)=chs8(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'t') then
      k=0
      nir=nt
      norder=it(2)
      do i=1,nir
      iir(i)=it(i+2)
      ipointer(i)=it(i+2+nir)
      zlabir(i)=yrt(i)
      do j=1,nir
      k=k+1
      chars(k)=cht(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'td') then
      k=0
      nir=ntd
      norder=itd(2)
      do i=1,nir
      iir(i)=itd(i+2)
      ipointer(i)=itd(i+2+nir)
      zlabir(i)=yrtd(i)
      do j=1,nir
      k=k+1
      chars(k)=chtd(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
      if(zname.eq.'th') then
      k=0
      nir=nth
      norder=ith(2)
      do i=1,nir
      iir(i)=ith(i+2)
      ipointer(i)=ith(i+2+nir)
      zlabir(i)=yrth(i)
      do j=1,nir
      k=k+1
      chars(k)=chth(j,i)
      enddo
      enddo
      goto 10
      endif
c
c
c here it will come if group was not recognized
c
      isuccess=0
      return
10    continue
      isuccess=1
      if(ipointer(1).eq.0) isuccess=0
      return
      end
      subroutine rdcoords(isymb,xname,ncur,xsymb,nsb,ytest)
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      logical endflg
c
INCLUDE(common/sizes)
INCLUDE(common/work)
INCLUDE(common/iofile)
INCLUDE(common/czmat)
INCLUDE(common/runlab)
INCLUDE(common/infoa)
      dimension xdummy1(20),xdummy2(20),xdummy3(20)
      dimension xstr(8),xname(*),xsymb(*)
      dimension yvar(8)
c
      data yvar/'vari','cons','cart','end','char','inte','coor',' '/
      data xblnk/' '/,xcom/','/
c
      endflg=.true.
20    do 30 i = 1 , 8
         xstr(i) = xblnk
30    continue
      call input
      call inpa4(ytest)
      i = locatc(yvar,7,ytest)
      if (i.gt.0) then
         return
      else
         call outrec
         jrec = jrec - 1
         call inpa(ztest)
         jrec = jrec - 1
         call inpstr(xstr,len,if1)
         if (len.gt.8) call caserr2('centre name in z-matrix too long')
c
c                        append this to the list (namcnt).
c
         call putb(xstr,len,xname,ncur)
         ncur = ncur + 1
         xname(ncur) = xcom
c
c                        print it out.
c
         nz = nz + 1
         zaname(nz) = ztest
         iz(nz,1) = -1
c
c                        get atomic number of center.
c
         ianz(nz) = isubst(xstr)
         czan(nz) = dfloat(ianz(nz))
         if (ianz(nz).eq.-10) then
            write(*,*)'Unrecognized atom label "',xstr,'" !!!'
            call caserr2("Unrecognized atom label")
         end if
c
c     trap for too many cards.
c
            if (nz.gt.maxnz) call caserr2(
     +          'maximum no. of permitted z-matrix cards exceeded')
c
c
	    lenxdm1=0
	    lenxdm2=0
	    lenxdm3=0
            call sparm(alpha(nz),lalpha(nz),xdummy1,lenxdm1,i_symb)
            call sparm(beta(nz),lbeta(nz),xdummy2,lenxdm2,i_symb)
            call sparm(bl(nz),lbl(nz),xdummy3,lenxdm3,isymb)
	    if(nz.gt.1) then
              do 50 i=1,lenxdm3
	        nsb=nsb+1
50            xsymb(nsb)=xdummy3(i)
            else if(lenxdm3.gt.2) then
	        write(iwr,100) (xdummy3(ii),ii=1,lenxdm3-1)
	        call caserr2('invalid coordinate variable')
            endif
	    if(nz.gt.2) then
	      do 51 i=1,lenxdm1
		nsb=nsb+1
51            xsymb(nsb) = xdummy1(i)
            else if(lenxdm1.gt.2) then
	        write(iwr,100) (xdummy1(ii),ii=1,lenxdm1-1)
	        call caserr2('invalid coordinate variable')
            endif
	    if(nz.gt.3) then
	      do 52 i=1,lenxdm2
		nsb=nsb+1
52            xsymb(nsb) = xdummy2(i)
            else if(lenxdm2.gt.2) then
	      write(iwr,100) (xdummy2(ii),ii=1,lenxdm2-1)
	      call caserr2('invalid coordinate variable')
            endif
c
            if (ianz(nz).eq.0) then
c...         possibly read charge of dummy like coordinates directive does
               call inpf(czan(nz))
               ianz(nz) = int(czan(nz))
            endif

	 goto 20
      endif
100   format('This coordinate must be input as a constant: ',20a1)
      end
      subroutine read_fcm(hes,scr,nvar,shape)
c
c...  returns square (for optim) or triangle (for optx)
c...  shape = 'sqr' or 'tri'
c...  see write_fcm
c

      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension hes(nvar,nvar),scr(*)

INCLUDE(common/iofile)
INCLUDE(common/sizes)
      common/hmat/o_hmat,ihess,o_tri,o_lab
      dimension rar(9)
      character*(*) shape

      write(iwr,*)
      if (o_lab) then
         write(iwr,102)
      else
         if (.not.o_tri) write(iwr,100) 
         if (o_tri) write(iwr,101) 
      end if
      rewind(ihess)
      if (o_lab) then
         call vclr(hes,1,nvar*nvar)
1        read(ihess) iat,jat,rar
         if (iat.ne.0) then
            kk = 1
            do i=(iat-1)*3+1,(iat-1)*3+3
             do j=(jat-1)*3+1,(jat-1)*3+3
              hes(i,j) = rar(kk)
              hes(j,i) = rar(kk)
              kk = kk + 1
             end do
            end do
            go to 1
         else
            if (shape.eq.'tri') call triangle(hes,hes,nvar)
         end if
c        
      else if (o_tri) then
c...     matrix read is triangular
         nn = nvar*(nvar+1)/2
         do i=1,nn
            read(ihess) scr(i)
         end do
         if (shape.eq.'tri') then
            call dcopy(nn,scr,1,hes,1)
         else
            call square(hes,scr,nvar,nvar)
         end if
      else
c...     matrix read is square
         nn = nvar*nvar
         do i=1,nn
            read(ihess) scr(i)
         end do
         if (shape.eq.'tri') then
            call triangle(scr,hes,nvar)
         else
            call dcopy(nn,scr,1,hes,1)
         end if
      end if
c
      close(ihess)
c
100   format(" square Hessian matrix read from input file")
101   format(" triangular Hessian matrix read from input file")
102   format(" atom-labeled Hessian matrix read from input file")

      end
      subroutine reflct(maxap3,a,b,natoms,t,ixyz)
c
c     the coordinates of the natoms in a are reflected in a plane
c     perpindicular to cartesian axis ixyz using the transformation
c     matrix t.  the reflected coordinates are returned in b.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension t(3,*), a(maxap3,3), b(maxap3,3)
c
      data dzero,done/0.0d0, 1.0d0/
c
      do 30 i = 1 , 3
         do 20 j = 1 , 3
            t(i,j) = dzero
 20      continue
         t(i,i) = done
 30   continue
      t(ixyz,ixyz) = -done
      call tform(maxap3,t,a,b,natoms)
      return
      end
      subroutine reinit
      implicit REAL  (a-h,o-z)
INCLUDE(common/common)
INCLUDE(common/cndx41)
      mprest = 0
      mpflag = 0
      icflag = 0
      irest2 = 0
      irest3 = 0
      irest4 = 0
      irest5 = 0
      irest6 = 0
      irestp = 0
      mcrest = 0
      irest = 0
      return
      end
      subroutine renum
     *(s3,mxbnds,
     * cxoord,coord2,icon,icon2,icon1,iconv,iconv1,
     * neigh,neigh1,iconv2,numats,nmats1)
      implicit REAL  (a-h,o-z)
      integer s3
c
INCLUDE(common/sizes)
c
      character*8 atlet,atlet2
      common /bufb/atlet(maxat),atlet2(maxat)
      dimension   cxoord(3,s3),coord2(3,s3),
     -            icon(s3,mxbnds),icon2(s3,mxbnds),
     -            icon1(s3,mxbnds),
     -            iconv(s3),iconv1(s3),
     -            neigh(s3),neigh1(s3),iconv2(s3)
c
c
c     this routine will renumber the molecule. atom number one
c       will be changed to number four while a dummy atom,number
c       three will be attached to atom four;atoms two and one will
c       also be dummy atoms where three is attached to two and one
c       is attached to two. all the other atoms in the molecule will
c       be renumbered according to the following scheme: let's assume
c       that each atom is bonded to four other atoms for the sake
c       of discussion. atom four will then be bonded to atoms numbered
c       five,six,seven,and eight;it's already bonded to atom three.
c       atom five will then be bonded to atoms nine,ten,and eleven.
c       atom six will be bonded to atoms twelve,thirteen,and four
c       teen. and so the bonding scheme goes on. this scheme will
c       insure that there exist three other atoms such that the
c       geometric parameters can be determined for
c       given any random numbering scheme supplied
c       by an equally random user.
c
c
c
c
c         definition of terms used in this subroutine
c
c           1. neigh(i) : the number of atoms bonded to the ith atom
c
c           2. iconv(i) : the new number for the ith atom in the
c                         original bonding scheme
c
c           3. iconv1(i) : the new number for the ith atom in the
c                          shifted numbering scheme. the shifted
c                          scheme is where the ith atom in the orig
c                          inal bonding scheme is now the i+3 atom;
c                          this makes room for the three dummy atoms.
c
c           4. iconv2(i) : the atom number for the ith atom in the
c                          renumbered molecule  in the shifted
c                          molecule. for example,if the atom is
c                          number eight in the renumberd molecule
c                          then iconv2(8) will tell me what the
c                          number of that atom was in the shifted
c                          molecule.
c
c           5. icon(i,j) : the j other atoms that atom i was bonded
c                          to in the chemlab supplied molecule.
c
c           6. icon1(i,j) : the j other atoms that atom i was bonded
c                           to in the shifted molecule.
c
c           7. icon2(i,j) : the j other atoms that atom i in the new
c                           bonding scheme is attached to.
c
c
c
      do i = 1, s3
        iconv(i)  = 0
        iconv1(i) = 0
        iconv2(i) = 0
      enddo
      iconv2(4) = 4
      iconv1(4) = 4
      iconv(1) = 4
c
c     determine the number of bonds to each atom
c
      do 30 i = 1 , numats
         neigh(i) = 0
         do 20 j = 1 , mxbnds
            if (icon(i,j).ne.0) neigh(i) = neigh(i) + 1
 20      continue
 30   continue
c
c
c     shift all the atoms to accomodate the three dummy atoms-atoms
c     one through three.
c
      do 50 i = 1 , numats
         neigh1(i+3) = neigh(i)
         do 40 j = 1 , mxbnds
            if (icon(i,j).eq.0) then
              icon1(i+3,j) = 0
            else
              icon1(i+3,j) = icon(i,j) + 3
            endif
 40      continue
 50   continue
c
c     there are now numats plus three atoms in the molecule
c
      nmats1 = numats + 3
c
c
c     attach a dummy atom to atom four
c
      icon1(4,neigh1(4)+1) = 3
      icon2(4,neigh1(4)+1) = 3
c
c
c     since atom four is unique in that it may be bonded to five
c     other atoms do it's assignments separately.
c
      l = 5
      do 60 j = 1 , neigh1(4)
         icon2(4,j) = l
         l = l + 1
 60   continue
c
c
c     how were the atoms converted?
c
      do 70 j = 1 , neigh1(4)
         iconv(icon(1,j)) = icon2(4,j)
         iconv1(icon1(4,j)) = icon2(4,j)
         iconv2(icon2(4,j)) = icon1(4,j)
 70   continue
c
      do 90 j = 1 , neigh1(4)
         k = icon1(4,j)
         do 80 j1 = 1 , neigh1(k)
            if (icon1(k,j1).eq.4) icon2(iconv1(k),j1) = 4
 80      continue
 90   continue
c
c
c
c     now renumber the rest of the molecule
c
      do 150 i = 5 , nmats1
         do 140 j = 1 , neigh1(iconv2(i))
            if (icon2(i,j).eq.0 .and. iconv1(icon1(iconv2(i),j)).eq.0)
     +          then
               icon2(i,j) = l
               iconv1(icon1(iconv2(i),j)) = l
               iconv(icon(iconv2(i)-3,j)) = l
               iconv2(l) = icon1(iconv2(i),j)
               do 120 j1 = 1 , neigh1(iconv2(l))
                  if (icon1(iconv2(l),j1).eq.iconv2(i)) then
                     icon2(l,j1) = i
                     do 110 i2 = 5 , nmats1
                        do 100 j2 = 1 , neigh1(i2)
                           if (icon1(i2,j2).eq.iconv2(l) .and.
     +                         iconv1(i2).ne.0) icon2(iconv1(i2),j2) = l
 100                    continue
 110                 continue
                     go to 130
                  end if
 120           continue
 130           l = l + 1
            else
               if (iconv1(icon1(iconv2(i),j)).ne.0) icon2(i,j)
     +             = iconv1(icon1(iconv2(i),j))
            end if
 140     continue
 150  continue
c
c
c     recall that atom four now has one extra bond-the one to the
c       dummy atom
      neigh1(4) = neigh1(4) + 1
c
c
c     redefine the atom letters and coordinates
c
      do 160 i = 4 , nmats1
         coord2(1,i) = cxoord(1,iconv2(i)-3)
         coord2(2,i) = cxoord(2,iconv2(i)-3)
         coord2(3,i) = cxoord(3,iconv2(i)-3)
         atlet2(i) = atlet(iconv2(i)-3)
 160  continue
      return
      end
      subroutine rest1
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
INCLUDE(common/iofile)
      common/junk/csi(mxprim),cpi(mxprim),cdi(mxprim),
     *             cfi(mxprim),cgi(mxprim),cznuc(maxat)
INCLUDE(common/restri)
      data m1/1/
c
      call secget(isect(491),m1,ibl491)
c
      nav = lenwrd()
c
      m1420 = 5*mxprim + maxat
      m110 = 10 + maxat
      call rdedx(ex,mxprim,ibl491,idaf)
      call reads(csi,m1420,idaf)
      call rdchrs(ztitle,m110,idaf)
      call readis(kstart,mach(2)*nav,idaf)
c
c  move to restored area
c
      call dcopy(5*mxprim,csi,1,cs,1)
      call dcopy(maxat,cznuc,1,czan,1)
      if(nat.ne.non.or.num.ne.numorb)
     +  call caserr2('invalid parameters in restart section')
      nx = numorb*(numorb+1)/2
c
      return
      end
      subroutine rest2
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/machin)
INCLUDE(common/symtry)
INCLUDE(common/runlab)
      common/junkc/ylabel(26)
INCLUDE(common/iofile)
      common/junk/
     & bb(12*maxat),dd(3),ibcd(4),ns(maxat),ks(maxat)
INCLUDE(common/restri)
INCLUDE(common/harmon)
INCLUDE(common/prints)
_IF(charmm)
INCLUDE(common/chmgms)
_ENDIF
      data m15/15/
      call secget(isect(493),m15,iblk15)
c
      if (numorb.gt.maxorb .or. numorb.lt.1 .or. nat.gt.maxat .or.
     +    nat.lt.1 .or. nshell.gt.mxshel .or. nshell.lt.1) then
         write (iwr,6010)
         return
      end if
      nav = lenwrd()
      nat3 = nat * 3
      mach4 = 4 * nat3 +3 +4/nav
      ioff = 3 * nat3 + 1
      call rdedx(bb,mach4,iblk15,idaf)
      call dcopy(nat3,bb(ioff),1,c,1)
      kss = 0
      do 30 loop = 1 , nat
         nss = 0
         do 20 i = 1 , nshell
            if (katom(i).eq.loop) then
               nss = nss + 1
            end if
 20      continue
         ns(loop) = nss
         ks(loop) = kss + 1
         kss = kss + nss
 30   continue
c
c
      call preharm
c
      if (.not.oharm) write (iwr,6020) ztitle , nshell , num , ne , 
     + ich , mul, na, nb ,nat
      if (oharm) write (iwr,6021) ztitle,nshell,num,newbas0,ne,ich ,
     + mul, na, nb ,nat

_IF(charmm)
      if(.not. onoatpr)then
_ENDIF
      write (iwr,6030)
      nbqnop = 0
      do 40 iat = 1 , nat
        if (.not. oprint(31) .or. (zaname(iat)(1:2) .ne. 'bq'))then
        write (iwr,6040) zaname(iat) , czan(iat) , c(1,iat) , c(2,iat) ,
     +                    c(3,iat) , ns(iat)
        else
           nbqnop = nbqnop + 1
        endif
 40   continue
      if (nbqnop .gt. 0)then
         write (iwr,6041) nbqnop
      endif

_IF(charmm)
      endif
_ENDIF
      write (iwr,6050)
      return
 6010 format (//' section 491 overwritten')
 6020 format (//' case : ',10a8//' total number of shells',15x,
     +        i5/' total number of basis functions',6x,i5/
     +           ' number of electrons',18x,i5/
     +           ' charge of molecule',19x,i5/
     +           ' state multiplicity',19x,i5/
     +           ' number of occupied orbitals (alpha)',2x,i5/
     +           ' number of occupied orbitals (beta )',2x,i5/
     +           ' total number of atoms',16x,i5/)
 6021 format (//' case : ',10a8//' total number of shells',15x,
     +        i5/' total number of basis functions',6x,i5,
     +        6x,' harmonic ',i6,/
     +           ' number of electrons',18x,i5/
     +           ' charge of molecule',19x,i5/
     +           ' state multiplicity',19x,i5/
     +           ' number of occupied orbitals (alpha)',2x,i5/
     +           ' number of occupied orbitals (beta )',2x,i5/
     +           ' total number of atoms',16x,i5/)
 6030 format (/1x,104('-')//40x,18('*')/40x,'Molecular geometry'/40x,
     +        18('*')//9x,79('*')/9x,'*',77x,'*'/9x,'*',5x,'atom',3x,
     +        'atomic',16x,'coordinates',17x,'number of',6x,'*'/9x,'*',
     +        12x,'charge',7x,'x',13x,'y',14x,'z',7x,'shells',9x,'*'/9x,
     +        '*',77x,'*'/9x,79('*'))
 6040 format (9x,'*',77x,'*'/9x,'*',77x,'*'/9x,'*',4x,a8,f5.1,
     +        3(f12.7,3x),i5,10x,'*')
 6041 format (9x,'*   Output of ',i5,' BQ centres suppressed',/9x,'*',
     +        77x,'*')
 6050 format (9x,'*',77x,'*'/9x,79('*')//40x,19('*')/40x,
     +        'molecular basis set'/40x,19('*')///40x,30('=')/40x,
     +        'contracted primitive functions'/40x,30('=')//1x,'atom',
     +        8x,'shell',3x,'type',2x,'prim',7x,'exponents',12x,
     +        'contraction coefficients'/1x,113('='))
      end
      subroutine rest3(isoc)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/restar)
INCLUDE(common/prints)
INCLUDE(common/phycon)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/nshel)
INCLUDE(common/symtry)
INCLUDE(common/machin)
INCLUDE(common/runlab)
      common/junk/bb(3*maxat,4),bbb(3),ibcd(4),
     * ns(maxat),ks(maxat),intyp(mxshel),imap(mxprim)
INCLUDE(common/restri)
      dimension isoc(*),jshell(6),ylabel(6)
      data ntype/6/
      data ylabel/'s','p','d','f','g','sp'/
      data jshell/ 1 , 3 , 6 ,10 ,15,  4 /
      data m18/18/
      data pi32/5.56832799683170d0/
      data pt75/0.75d0/
      data dzero,pt5/0.0d0,0.5d0/
c     data sqrt3 /1.73205080756888d0/
c     data sqrt5 /2.23606797749979d+00/
      data toll/1.0d-10/
      data pt187,pt6562 /1.875d0,6.5625d0/
c
c     generate equivalent centers
c     set table ( centers versus transformations )
c
c     process section 196
c
      nav = lenwrd()
c
      call secget(isect(496),m18,iblk18)
      nwnt = 134
      call readi(invt,nwnt,iblk18,idaf)
      mword1 = (nshell*nt-1)/nav+1
      ibl1 = lensec(mword1)
      mword2 = (nat*nt-1)/nav+1
c     ibl2 = lensec(mword2)
      ibl3 = lensec(1728)
      ibl4 = lensec(4800)
      ibl5 = lensec(10800)
c
      nw196(1) = 432
      nw196(2) = 1728
      nw196(3) = 4800
      nw196(4) = 10800
      nw196(5) = mword1
      nw196(6) = mword2
c
c     len196 = 2 + ibl1 + ibl2 + ibl3 + ibl4 + ibl5
c
      ibl196(1) = iblk18 + 1
      ibl196(2) = ibl196(1) + 1
      ibl196(3) = ibl196(2) + ibl3
      ibl196(4) = ibl196(3) + ibl4
      ibl196(5) = ibl196(4) + ibl5
      ibl196(6) = ibl196(5) + ibl1
c
c   ----- read -isoc-  -
c
      call readi(isoc,nw196(6)*nav,ibl196(6),idaf)
c
      do 30 loop = 1 , nshell
         ii = kmax(loop) - kmin(loop) + 1
         do 20 i = 1 , ntype
            if (ii.eq.jshell(i)) then
               intyp(loop) = i
            end if
 20      continue
 30   continue
c
      do 130 iat = 1 , nat
         do 50 it = 1 , nt
            if (isoc(iat+ilisoc(it)).gt.iat) go to 130
 50      continue
         ns2 = ns(iat)
         if (ns2.ne.0) then
            write (iwr,6040) zaname(iat)
            ns1 = ks(iat)
            ns2 = ns1 + ns2 - 1
            do 120 ish = ns1 , ns2
               write (iwr,6020)
               i1 = kstart(ish)
               i2 = i1 + kng(ish) - 1
               ityp = intyp(ish)
               do 110 ig = i1 , i2
                  go to (60,70,80,90,100,105) , ityp
 60               c1 = cs(ig)
                  write (iwr,6010) ish , ylabel(ityp) , ig , ex(ig) , c1
                  go to 110
 70               c1 = cp(ig)
                  write (iwr,6010) ish , ylabel(ityp) , ig , ex(ig) , c1
                  go to 110
 80               c1 = cd(ig)
                  write (iwr,6010) ish , ylabel(ityp) , ig , ex(ig) , c1
                  go to 110
 90               c1 = cf(ig)
                  write (iwr,6010) ish , ylabel(ityp) , ig , ex(ig) , c1
                  go to 110
 100              c1 = cg(ig)
                  write (iwr,6010) ish , ylabel(ityp) , ig , ex(ig) , c1
                  go to 110
 105              c1 = cs(ig)
                  c3 = cp(ig)
                  write (iwr,6030) ish , ylabel(ityp) , ig , ex(ig) ,
     +                            c1 , c3
 110           continue
 120        continue
         end if
 130  continue
c
      call build_nuct(nat,ns,zaname,czan,nuct)
      call setlab
c
c *** now normalise
c
c     onormf = normf.ne.1
      onormp = normp.ne.1
      do 150 loop = 1 , nshell
         k1 = kstart(loop)
         imap(k1) = 0
150   continue
      do 160 loop = 1 , nshell
         k1 = kstart(loop)
         k2 = k1 + kng(loop) - 1
         if (imap(k1).eq.0) then
            imap(k1) = loop
            if (onormp) then
               do 170 ig = k1 , k2
                  ee = ex(ig) + ex(ig)
                  facs = pi32/(ee*dsqrt(ee))
                  facp = pt5*facs/ee
                  facd = pt75*facs/(ee*ee)
                  facf = pt187*facs/(ee**3)
                  facg = pt6562*facs/(ee**4)
                  cs(ig) = cs(ig)/dsqrt(facs)
                  cp(ig) = cp(ig)/dsqrt(facp)
                  cd(ig) = cd(ig)/dsqrt(facd)
                  cf(ig) = cf(ig)/dsqrt(facf)
                  cg(ig) = cg(ig)/dsqrt(facg)
 170           continue
            end if
            if (normf.ne.1) then
               facs = dzero
               facp = dzero
               facd = dzero
               facf = dzero
               facg = dzero
               do 180 ig = k1 , k2
                  do 190 jg = k1 , ig
                     ee = ex(ig) + ex(jg)
                     fac = ee*dsqrt(ee)
                     dums = cs(ig)*cs(jg)/fac
                     dump = pt5*cp(ig)*cp(jg)/(ee*fac)
                     dumd = pt75*cd(ig)*cd(jg)/(ee**2*fac)
                     dumf = pt187*cf(ig)*cf(jg)/(ee**3*fac)
                     dumg = pt6562*cg(ig)*cg(jg)/(ee**4*fac)
                     if (ig.ne.jg) then
                        dums = dums + dums
                        dump = dump + dump
                        dumd = dumd + dumd
                        dumf = dumf + dumf
                        dumg = dumg + dumg
                     end if
                     facs = facs + dums
                     facp = facp + dump
                     facd = facd + dumd
                     facf = facf + dumf
                     facg = facg + dumg
 190              continue
 180           continue
               do 200 ig = k1 , k2
                  if (facs.gt.toll) cs(ig) = cs(ig)/dsqrt(facs*pi32)
                  if (facp.gt.toll) cp(ig) = cp(ig)/dsqrt(facp*pi32)
                  if (facd.gt.toll) cd(ig) = cd(ig)/dsqrt(facd*pi32)
                  if (facf.gt.toll) cf(ig) = cf(ig)/dsqrt(facf*pi32)
                  if (facg.gt.toll) cg(ig) = cg(ig)/dsqrt(facg*pi32)
 200           continue
            end if
         end if
 160  continue
      write (iwr,6050)
      return
 6010 format (15x,i3,3x,a4,3x,i3,1x,2f15.6)
 6020 format (/)
 6030 format (15x,i3,3x,a4,3x,i3,1x,3f15.6)
 6040 format (/1x,a8)
 6050 format (/1x,113('='))
      end
      subroutine restore(orest,ynamed)
c
c     setup restart information
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
c
INCLUDE(common/direc)
INCLUDE(common/runlab)
INCLUDE(common/restar)
INCLUDE(common/restrj)
INCLUDE(common/machin)
INCLUDE(common/atmol3)
INCLUDE(common/work)
INCLUDE(common/iofile)
c
      lcoord = 1
      call inpa(ztext)
      orest = .true.
      ytext = ytrunc(ztext)
      ltask = locatc(yrunt,mxtask,ytext)
      if (ytext.eq.'nono') then
         orege = .false.
         irestt = 3
         write(iwr,*) '** nono - react to bypass like serial **'
      end if
c
c ... check for alternative names or 'new' specification
c ... optxyz/oldopt
c
      if (ltask.eq.0) then
         if (ytext.eq.'oldo') then
            ltask = 6
         else if (ytext.eq.'new') then
            lcoord = 0
         else if (ytext.eq.'geom') then
            lcoord = 2
         end if
      end if
      call filec(ynamed,ibl3d,idaf,irep)
      if (irep.ne.0) call caserr2(
     +          'dumpfile has been incorrectly assigned')
      call secini(ibl3d,idaf)
      call restre
      write (iwr,6010) ibl3d , ynamed
      nprint = 0
      if (ltask.ne.0) then
         write (iwr,6020) zrunt(ltask)
         irest = itask(ltask)
         if (ltask.ne.mtask) call caserr2(
     +       'restart task specified is not compatible with dumpfile')
         if (mtask.eq.4 .or. mtask.eq.5) lcoord = 0
_IF(parallel)
         irestt = 9
         if (jump.eq.3) then
          call inpa4(ytext)
          if (ytext.eq.'fine'.or.ytext.eq.'off') then
            orege = .false.
            orgall = .false.
            irestt = 3
          endif
         endif
_ELSE
         if (jump.eq.3) then
          call inpa4(ytext)
          orege = .true.
          irestt = 3
          if (ytext.eq.'dirt'.or.ytext.eq.'cour') then
           orgall = .true.
           irestt = 9
          endif
         endif
_ENDIF
         if (.not.orege) go to 20
         if (irest.le.irestt) irest = 0
      else
         call setsto(mxtask,-1,itask)
         irest = 0
         irest5 = 0
      end if
c
c ---- new task to be defined under =runtyp=
c
      ist = 1
      jst = 1
      kst = 1
      lst = 1
      nrec = 1
      omaxb = .false.
      if (orege) then
chvd     reset local to fix problem with c2010_a in parallel runs
         local = 0
         mfilep = 1
         m2file = 1
         call setsto(20,-1,m2blk(1))
         if (orgall) then
           write (iwr,6070)
         else
           write (iwr,6030)
         endif
      else
         local = 0
         normf = 0
         normp = 0
chvd     nopk = 0
         itol = 20
         icut = 9
         call setsto(mxtask,-1,itask)
      end if
 20   if (lcoord.eq.0) write (iwr,6040)
      if (lcoord.ge.1) write (iwr,6050)
      write (iwr,6060) irest
c
      return
 6010 format (/1x,21('-')/1x,'this is a restart job'/1x,21('-')
     +        /' **** control information retrieved from dumpfile at ',
     +        'block ',i5,' on ',a4)
 6020 format (' **** restart task ---- ',a8)
 6030 format (/1x,34('-')/1x,'integral files will be regenerated'/1x,
     +        34('-'))
 6070 format (/1x,35('-')/1x,'all restart data will be regenerated'/1x,
     +        35('-'))
 6040 format (/1x,45('-')
     +        /' atomic coordinates as specified in data input'/1x,
     +        45('-'))
 6050 format (/1x,41('-')/' atomic coordinates restored from dumpfile'/1
     +        x,41('-'))
 6060 format (/' **** restart mode ',i4)
      end
_IF(charmm)
      subroutine charmm_restart(orest,ynamed)
c
c     setup restart information
c      - CHARMM version
c        there is no restart directive present
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
c
INCLUDE(common/direc)
INCLUDE(common/runlab)
INCLUDE(common/restar)
INCLUDE(common/restrj)
INCLUDE(common/machin)
INCLUDE(common/atmol3)
INCLUDE(common/work)
INCLUDE(common/iofile)
INCLUDE(common/sector)
c
      dimension zscf(10)

      data zscf/'rhf','uhf','gvb','grhf','casscf','mcscf','multi',
     &          'direct','mp2','mp3'/

      lcoord = 0
c      call inpa(ztext)
      orest = .true.
c      ytext = ytrunc(ztext)
c      ltask = locatc(yrunt,mxtask,ytext)

      ltask = 0

      call filec(ynamed,ibl3d,idaf,irep)
      if (irep.ne.0) call caserr2(
     +          'dumpfile has been incorrectly assigned')
      call secini(ibl3d,idaf)
      call restre
      write (iwr,6010) ibl3d , ynamed
      nprint = 0

      call setsto(mxtask,-1,itask)
      irest = 0
      irest5 = 0
c
c ---- new task to be defined under =runtyp=
c
      ist = 1
      jst = 1
      kst = 1
      lst = 1
      nrec = 1
      omaxb = .false.

      local = 0
      normf = 0
      normp = 0
chvd     nopk = 0
      itol = 20
      icut = 9
      write (iwr,6060) irest
c
      return
 6010 format (/1x,21('-')/1x,'this is a restart job'/1x,21('-')
     +        /' **** control information retrieved from dumpfile at ',
     +        'block ',i5,' on ',a4)
 6020 format (' **** restart task ---- ',a8)
 6030 format (/1x,34('-')/1x,'integral files will be regenerated'/1x,
     +        34('-'))
 6070 format (/1x,35('-')/1x,'all restart data will be regenerated'/1x,
     +        35('-'))
 6040 format (/1x,45('-')
     +        /' atomic coordinates as specified in data input'/1x,
     +        45('-'))
 6050 format (/1x,45('-')/' atomic coordinates restored from dumpfile'/1
     +        x,41('-'))
 6060 format (/' **** restart mode ',i4)
      end
_ENDIF
      subroutine rntype(jrun)
c
c     read in runtype specification
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
c
INCLUDE(common/fpinfo)
INCLUDE(common/prnprn)
INCLUDE(common/modj)
INCLUDE(common/direc)
INCLUDE(common/runlab)
INCLUDE(common/restar)
INCLUDE(common/restrj)
INCLUDE(common/infob)
INCLUDE(common/machin)
INCLUDE(common/atmol3)
INCLUDE(common/work)
INCLUDE(common/dump3)
INCLUDE(common/foropt)
INCLUDE(common/cntl1)
INCLUDE(common/modmin)
INCLUDE(common/restri)
      common/restrl/ocifor(16),oforce,odumm(33)
INCLUDE(common/discc)
INCLUDE(common/cndx41)
INCLUDE(common/crnamx)
INCLUDE(common/tdhfx)
INCLUDE(common/tdhf)
INCLUDE(common/mp2grd)
      logical scalar
      common /rpaoptions/ scalar
INCLUDE(common/secd_pointers)
INCLUDE(common/structchk)
INCLUDE(common/ccpdft.hf77)
      dimension zmodt(8)
      data zblank/' '/,m80/80/
      data zmodt /'mechanic','quantum ','dynamics','hybrid  ',
     *            'fp      ','jorgens ','fcm'     , 'ci'   /
c
      scalar = .true.
      omem2nd = .true.
      omem2nd_ga = .false.
c
      call inpa(ztest)
      ytest = ytrunc(ztest)
      jrun = locatc(yrunt,mxtask,ytest)
      if (jrun.eq.0) then
c ... allow for alternative names
c ... optxyz/oldopt
c ... hessian/secder
         if (ytest.eq.'oldo') then
         jrun = 6
         else if (ytest.eq.'secd') then
         jrun = 24
         else
         go to 80
         endif
      endif
      zruntp = zrunt(jrun)
      go to(170,170,170,150,100, 90, 90,190,170,170,
_IF(rpagrad)
     +      170,170, 80,160, 30,170,170,170,176,176,
_ELSE
     +      170,170, 80,160, 30,170,170,170, 80, 80,
_ENDIF
     +      170, 20,170,200, 70, 70, 40, 30,170,170,
     +      180,170,210,220,170,170,170,170,170,170,
     +      170,175,170,170,170,170,170,170,170,170) , jrun
c
c ... response
c
175   call inpa(ztest)
      if (ztest.eq.'rpa') then
       call inpa(ztest)
       if (ztest.eq.'direct') then
        odirpa = .true.
       else
        orpa = .true.
       endif
       call rpinit
      else if (ztest.eq.'dirrpa'. or. ztest.eq.'direct') then
       odirpa = .true.
       call rpinit
      else if (ztest.eq.'mclr') then
       omclr = .true.
       call lrinit
      else if (ztest.eq.zblank) then
       orpa = .true.
       call rpinit
      else
       call caserr2('invalid response type specified')
      endif
      go to 230
_IF(rpagrad)
c
c ... RPA gradients
c
c ... We have to initialise the RPA stuff at this point
c
176   continue
      omem2nd = .false.
      call inpa(ztest)
      if (ztest.eq.'direct') then
        odirpa = .true.
        call inpa(ztest)
      else
        orpa = .true.
      endif
177   ytest = ytrunc(ztest)
      if      (ytest.eq.'vect') then
         scalar = .false.
      else if (ytest.eq.'sepa') then
         opg_pertbns_sep = .true.
      else if (ytest.eq.'disk') then
         omem2nd = .false.
      else if (ytest.eq.'memo') then
         omem2nd = .true.
      else if (ytest.eq.'ga') then
         omem2nd = .true.
         omem2nd_ga = .true.
      else if (ytest.eq.'    ') then
         goto 178
      else
         call caserr2('invalid runtype option specified')
      endif
      call inpa(ztest)
      goto 177
178   continue
      do i = 1, 6
       iof2nd(i) = 0
      enddo
      nopk = 1
      oprn(23) = .true.
      oprn(24) = .true.
      if(odirec(24)) irest5 = 0
      call rpinit
      call rpdinit
      go to 230
_ENDIF
c
c ... hyperpolarizability
c
180   ipol = 1
      nopk = 1
      intg76 = 3
      oprn(26) = .true.
      go to 230
c
c ... polarizability
c
 20   ipol = 1
_IF(parallel)
      call caserr2("parallel polarizabilities not implemented yet")
_ENDIF
      oprn(26) = .true.
 201  call inpa(ztest)
      ytest = ytrunc(ztest)
      if (ytest.eq.'vect') scalar = .false.
      if (ytest.eq.'sepa') opg_pertbns_sep = .true.
      if (ytest.eq.'disk') omem2nd = .false.
      if (ytest.eq.'memo') omem2nd = .true.
      if (ytest.eq.'ga')   omem2nd = .true.
      if (ytest.eq.'ga')   omem2nd_ga = .true.
      if (ytest.ne.'    ')go to 201
      do i = 1, 6
       iof2nd(i) = 0
      enddo
      nopk = 1
      go to 230
c
c ... integral or intensity
c
 30   if (ztest.eq.'integral') then
         jrun = 15
      else
         jrun = 28
      end if
      zruntp = zrunt(jrun)
      go to 230
c
c ... magnetisability
c
 40   npstar = 0
      np = 6
      npa = 6
      do 50 i = 7 , 50
         opskip(i) = .true.
         ipsec(i) = 0
 50   continue
      do 60 i = 1 , 6
         opskip(i) = .false.
         pnames(i) = pnamc(i+34)
         ipsec(i) = 286 + i
 60   continue
      ipsec(4) = 284
      ipsec(5) = 285
      ipsec(6) = 286
      npole = 0
      nfreq = 0
      oprn(25) = .true.
      oprn(26) = .true.
      oprn(27) = .true.
      nopk = 1
      intg76 = 3
      go to 170
c
c ... hessian/secder
c
 200  call inpa(ztest)
      ierror = CD_gradquad(.true.)
      ytest = ytrunc(ztest)
      if (ytest.eq.'vect') scalar = .false.
      if (ytest.eq.'sepa') opg_pertbns_sep = .true.
      if (ytest.eq.'disk') omem2nd = .false.
      if (ytest.eq.'memo') omem2nd = .true.
      if (ytest.eq.'ga')   omem2nd = .true.
      if (ytest.eq.'ga')   omem2nd_ga = .true.
      if (ytest.ne.'    ')go to 200
      do i = 1, 6
       iof2nd(i) = 0
      enddo
      nopk = 1
_IF(secd_parallel)
c
c force -> high accuracy
c
      intg76 = 0
_ELSE
      intg76 = 3
_ENDIF
      oprn(23) = .true.
      oprn(24) = .true.
      if(odirec(24)) irest5 = 0
      go to 230
c
c ... raman
c
 210  nopk = 1
      intg76 = 3
      oprn(23) = .true.
      oprn(25) = .true.
      oprn(26) = .true.
      go to 170
c
c ...infrared
c
 220  call inpa(ztest)
      ierror = CD_gradquad(.true.)
      ytest = ytrunc(ztest)
      if (ytest.eq.'vect') scalar = .false.
      if (ytest.eq.'sepa') opg_pertbns_sep = .true.
      if (ytest.eq.'disk') omem2nd = .false.
      if (ytest.eq.'memo') omem2nd = .true.
      if (ytest.eq.'ga')   omem2nd = .true.
      if (ytest.eq.'ga')   omem2nd_ga = .true.
      if (ytest.ne.'    ')go to 220
      do i = 1, 6
       iof2nd(i) = 0
      enddo
      nopk = 1
_IF(secd_parallel)
c
c force -> high accuracy
c
      intg76 = 0
_ELSE
      intg76 = 3
_ENDIF
      oprn(23) = .true.
      oprn(25) = .true.
      oprn(26) = .true.
      go to 170
c
c ... dipder/polder
c
 70   nopk = 1
      intg76 = 3
      go to 240
 80   call caserr2('invalid runtype option')
c ...             runtype optxyz <mech,quan,dyn,hyb> <nopt><ropt>
c ...             runtype gradient <nopt><ropt>
c ...             runtype force <nopt><ropt>
 190  oforce = .true.
      ierror = CD_gradquad(.true.)
 90   continue
      call inpa(ztest)
      if (ztest.eq.zblank) go to 170
      ytest = ytrunc(ztest)
c
      if (ytest.eq.'chec'.or.ytest.eq.'diss'.or.
     +    ytest.eq.'dist') then
       ochkdst = .true.
       go to 90
      endif
c
c ... is this a mechanics - directive or a number ?
      iloc = locats(zmodt,7,ytest)
      if (iloc.lt.1) then
         jrec = jrec - 1
c ...             runtype optxyz [mech,quan,dyn,hyb,..,..,fcm] <nopt><ropt>
      else if (iloc.eq.7) then
         call fcmin('runtype')
         go to 170
      else if (.not.omapp) then
         call caserr2('ab initio -> mechanics mapping vector omitted')
      else
         ntmin = mod(iloc,4)
         if (jump.lt.4) go to 100
      end if
      call inpi(nopt)
      if ((jump-jrec).ge.1) then
         call inpf(ropt)
         if (dabs(ropt).gt.0.0d0) vibsiz = ropt
      end if
      if (nopt.ne.0) nvib = nopt
      go to 170
c
c ... optimize
c
 100  if (.not.(ozmat)) then
         call caserr2(
     +'z-matrix must be used in geometry and saddle point optimisation')
      end if
      accin(5) = 0.0d0
      accin(4) = 0.0d0
      accin(6) = 0.0d0
c ... may arrive here form runtype optimise or
c ...                      runtype saddle   or
c ...                      runtype branch
 120  if (itask(jrun).ne.-1) then
         call secget(isect(489),m80,ibl3op)
      end if
c ... runtype optimise <mech,quan,dyna,hybr,fp,jorg,fcm,ci><ed4 i>   or
c ... runtype saddle   <mech,quan,dyna,hybr,fp,jorg,fcm><ed4 i>   or
c ... runtype branch   <ed4 i>
      if (jump.eq.2) go to 170
 130  call inpa(ztest)
      if (ztest.eq.zblank) go to 170
      ytest = ytrunc(ztest)
c
      if (ytest.eq.'chec'.or.ytest.eq.'diss'.or.
     +    ytest.eq.'dist') then
       ochkdst = .true.
       go to 130
      endif
c
      iloc = locats(zmodt,8,ytest)
      if (iloc.eq.0 .or. iloc.eq.7) then
c ...                     runtype <optimise,saddle> ed4 i or
c ...                     runtype <optimise,saddle> model
c ...                     runtype <optimise,saddle> fcm
         if (ytest.eq.'mode') then
c ... use mechanics to generate hessian matrix.
            oamhes = .true.
         else 
c ... restore second derivative matrix
c ... hessian matrix may reside on a foreign dumpfile.
            if (ytest.ne.'fcm') jrec = jrec - 1
            call fcmin('runtype')
         end if
         go to 170
      else if (iloc.lt.5) then
c ...           mechanics options.   1<= iloc <=4
         if (jrun.eq.14) call caserr2(
     +  'cant study branching point with mechanics yet')
         if (.not.omapp) then
          call caserr2('ab initio -> mechanics mapping vector omitted')
         else
            ntmin = mod(iloc,4)
            go to 130
         end if
      else if (iloc.ne.5.and.iloc.ne.8) then
c ...                     runtype optimise jorg <ed4 i> or
c ...                     runtype saddle   jorg <ed4 i>
c                         isadle = 4  --->  minimum
c                         isadle = 5  --->  saddle
c ...
         if (jrun.eq.5) then
            isadle = 4
         else if (jrun.eq.4) then
            isadle = 5
         end if
         go to 130
      end if
c ... iloc=5 or iloc =8
c ... runtype optimise fp    fletcher - powell optimisation.
c     or runtype optimise ci   f-p optimistion with CI wavefunction
      if (jrun.ne.5) call caserr2(
     +        ' fp option only available for runtype optimise')
      isadle = 2
      if(iloc.eq.8) ocifp = .true.
      go to 130
c ...                   runtype saddle <jorg> <ed4 i>
 150  if (.not.ozmat) then
         call caserr2(
     +'z-matrix must be used in geometry and saddle point optimisation')
      else
         isadle = 3
         lqstyp = 6
         go to 120
      end if
c ...          runtype branch <ed4 i> ( implicit jorgenson & simons)
 160  call caserr2(
     +   'searching for branching points is not available yet.'
     +            )
      if (.not.ozmat) then
         call caserr2(
     +'z-matrix must be used in geometry and saddle point optimisation')
      else
         isadle = 6
         go to 120
      end if
 240  do 250 loop = 22,27
 250  oprn(loop) = .true.
 230  oprn(40) = .true.
 170  return
      end
      subroutine rot
c
c
c     calculate the coordinates (pp,qp,rp) of a point in the master
c     frame given the coordinates (pnew,qnew,rnew) in the local frame
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/transf)
INCLUDE(common/frame)
      pp = p0 + u1*pnew + v1*qnew + w1*rnew
      qp = q0 + u2*pnew + v2*qnew + w2*rnew
      rp = r0 + u3*pnew + v3*qnew + w3*rnew
      return
      end
      subroutine rotate(maxap3,a,b,natoms,t,ixyz,theta)
c
c     the coordinates of the natoms in a are rotated counterclockwise
c     by an angle theta around the cartesian axis ixyz using the
c     transformation matrix t.  the rotated coordinates are returned
c     in b.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension t(3,*), a(maxap3,3), b(maxap3,3)
c
      data dzero,done/0.0d0, 1.0d0/
c
      i1 = ixyz
      i2 = 1 + mod(i1,3)
      i3 = 1 + mod(i2,3)
      s = dsin(theta)
      c = dcos(theta)
      t(i1,i1) = done
      t(i1,i2) = dzero
      t(i1,i3) = dzero
      t(i2,i1) = dzero
      t(i2,i2) = c
      t(i2,i3) = s
      t(i3,i1) = dzero
      t(i3,i2) = -s
      t(i3,i3) = c
      call tform(maxap3,t,a,b,natoms)
      return
      end
      subroutine rstart(core,orest,ynamed)
c
c     setup restart information to continue prior processing
c     assuming no zmat/geom or basis information in input file
c     restoring key information from dumpfile sections
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
c
INCLUDE(common/direc)
INCLUDE(common/phycon)
INCLUDE(common/runlab)
INCLUDE(common/cntl1)
INCLUDE(common/restar)
INCLUDE(common/restrj)
INCLUDE(common/restri)
INCLUDE(common/machin)
INCLUDE(common/atmol3)
INCLUDE(common/work)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/infob)
INCLUDE(common/ccpdft.hf77)
      dimension core(*)
      data m80/80/
c
      lcoord = 1
c
      orest = .true.
c
      call inpa(ztext)
      ytext = ytrunc(ztext)
_IF(parallel)
      if (ytext.eq.'fine'.or.ytext.eq.'off') then
        orege = .false.
        orgall = .false.
      else if (ytext.eq.'rege'.or.ytext.eq.'cour'.or.
     +         ytext.eq.'dirt') then
        orege = .true.
        orgall = .true.
      else
        jrec = jrec - 1
      endif
_ELSE
      if (ytext.eq.'rege') then
        orege = .true.
      else if (ytext.eq.'cour'.or.ytext.eq.'dirt') then
        orege = .true.
        orgall = .true.
      else
        jrec = jrec - 1
      endif
_ENDIF
      call inpi(iii)
      if(iii.ne.0) iseczz = iii
c
      call filec(ynamed,ibl3d,idaf,irep)
      if (irep.ne.0) call caserr2(
     +      'dumpfile has been incorrectly assigned')
      call secini(ibl3d,idaf)
      call restre
      write (iwr,6010) ibl3d , ynamed
      nprint = 0
      write (iwr,6020) zrunt(mtask)
      irest = itask(mtask)
      ltask = mtask
      if (orege) then
c
c ---- settings for regenerate
c
         irestt = 3
         if (orgall) irestt = 9
         if (irest.le.irestt) irest = 0
         ist = 1
         jst = 1
         kst = 1
         lst = 1
         nrec = 1
         omaxb = .false.
         mfilep = 1
         m2file = 1
         call setsto(20,-1,m2blk(1))
         if (orgall) then
           write (iwr,6060)
         else
           write (iwr,6030)
         endif
      end if
      write (iwr,6040)
      write (iwr,6050) irest
c
      call rest1
      call rest2
      call rest3(core)
      call getzm(core,iseczz)
      ytext = ytrunc(zruntp)
      ltask = locatc(yrunt,mxtask,ytext)
      if (ltask.ne.mtask) call caserr2(
     +  'restart task specified is not compatible with dumpfile')
      if (mtask.eq.4 .or. mtask.eq.5) lcoord = 0
      jrun = mtask
      go to (170,170,170,150,100,90,90,85,170,170,170,170,
     +  80,160,170,170,170,80,80,80,170,170,170,70,70,70,170,
     + 170,170,170,170,170,170,180,170,170,170,170,170,170,
     + 170,170,170,170,170,170,170,170,170,170) , jrun
c
c ... hessian
c
 70   nopk = 1
      ierror = CD_gradquad(.true.)
      intg76 = 3
      go to 170
 80   call caserr2('invalid runtype option')
c ...             runtype optxyz <mech,quan,dyn,hyb> <nopt><ropt>
c ...             runtype gradient <nopt><ropt>
c ...             runtype force <nopt><ropt>
 85   continue
      ierror = CD_gradquad(.true.)
 90   continue
c ...must define vibsiz and nvib etc
      go to 170
c ...             runtype infrared
 180  continue
      ierror = CD_gradquad(.true.)
      go to 170
c
c ... optimize
c
 100  if (.not.(ozmat)) then
         call caserr2(
     + 'z-matrix must be used in geometry and saddle point optimisation'
     + )
      end if
      accin(5) = 0.0d0
      accin(4) = 0.0d0
      accin(6) = 0.0d0
c ... may arrive here form runtype optimise or
c ...                      runtype saddle   or
c ...                      runtype branch
 120  call secget(isect(489),m80,ibl3op)
c ... runtype optimise <mech,quan,dyna,hybr,fp,jorg><ed4 i>   or
c ... runtype saddle   <mech,quan,dyna,hybr,fp,jorg><ed4 i>   or
c ... runtype branch   <ed4 i>
       go to 170
 150  if (.not.ozmat) then
         call caserr2(
     + 'z-matrix must be used in geometry and saddle point optimisation'
     + )
      else
         isadle = 3
         lqstyp = 6
         go to 120
      end if
c ...          runtype branch <ed4 i> ( implicit jorgenson & simons)
 160  call caserr2(
     + 'searching for branching points is not available yet.')
 170  return
c
 6010 format (/1x,21('-')/1x,'this is a restart job'/1x,21('-')
     +        /' **** control information retrieved from dumpfile at ',
     +        'block ',i5,' on ',a4)
 6020 format (' **** restart task ---- ',a8)
 6030 format (/1x,34('-')/1x,'integral files will be regenerated'/1x,
     +        34('-'))
 6060 format (/1x,35('-')/1x,'all restart data will be regenerated'/1x,
     +        35('-'))
 6040 format (/1x,45('-')/' atomic coordinates restored from dumpfile'/1
     +        x,41('-'))
 6050 format (/' **** restart mode ',i4)
      end

chitachi
      block data savefdata
      logical ofiles(2)
      common/fsave/ofiles
      data ofiles/.false.,.false./
      end

      subroutine savef
      implicit none
INCLUDE(common/errcodes)
INCLUDE(common/work)
      character*8 ztext
      character*4 files(2)
      logical ofiles(2)
      common/fsave/ofiles

      character*132 file
      character*4 ytext
      integer isec(2),itmp
      logical onumb

      integer nf, i

      external locatc
      integer locatc

      data files/'tdm ','hess'/
      data nf/2/

      call inpa(ztext)
      i=locatc(files,nf,ztext)
      ytext = ztext
      if(ytext.eq.'aimp')then
c
c request for aimpac file
c         
         isec(1)=0
         isec(2)=0
         file=" "

         do while ((jump-jrec).ge.1)
            call inpa4(ytext)
            if(ytext.eq."file")then
               call inpanpc(file)
            else if(ytext.eq."sect")then
               call inpi(isec(1))
               call inpa4(ytext)
               call intval(ytext,itmp,onumb)
               if(onumb)then
                  isec(2) = itmp
               else
                  jrec = jrec-1
               endif
            else
               call gamerr(
     &        'unrecognised keyword on savefile aimpac directive',
     &        ERR_NO_CODE, ERR_INCOMPREHENSIBLE, ERR_SYNC, ERR_NO_SYS)
            endif
         enddo
         call aimpac_request(file,isec)
      else if (i.gt.0) then
         ofiles(i)=.true.
      else
         call gamerr(
     &        'unrecognised keyword on savefile directive',
     &        ERR_NO_CODE, ERR_INCOMPREHENSIBLE, ERR_SYNC, ERR_NO_SYS)
      endif
      end

      subroutine scentr(iz,xnam,nz)
c
c ----------------------------------------------------------------------
c          a routine to read (via "ff" routines) a center specification
c     from a z-matrix card.  this specification may be either an
c     integer (the sequential number of a previous z-matrix card),
c     or the name of a previously defined center.  "iz" is returned
c     as the sequential number of the center being referenced.
c     "namcnt" is a delimited hollerith string containing the names
c     of the centers.  "nz"  is the sequential number of the curent
c     z-matrix card.
c ----------------------------------------------------------------------
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
      dimension xstr(40),xnam(*)
c
INCLUDE(common/work)
c
c                  get whatever is in the line.
c
      call inpstr(xstr,len,if1)
      if (if1.ne.1) then
c
c                  found integer.
c
         jrec = jrec - 1
         call inpi(iz)
         return
      else if (len.gt.8) then
c
c                  center name is too long.
c
         write (iwr,6010) xstr
         call caserr2('invalid centre name in z-matrix')
         return
      else
         iz = lsubst(xnam,nz-1,xstr,len)
	 if(iz.lt.0) then
	    write(iwr,6020) (xstr(jj),jj=1,len)
	    call caserr2('invalid centre specified in z-matrix')
	 endif
         return
      end if
 6010 format ('  center name is to long.',1x,10a1)
 6020 format('invalid centre specified, centre not found: ',8a1)
c
      end
      subroutine incanon
c
c...  process input for canonicalisation  of natural orbitals
c...  on the 'natorb' card (more cards perhaps)
c...  cano isec  'print' 'perm' set/occ (y/n) to1 (y/n) to2 .. (y/n) end
c...  the sets are from low to high (integers) 
c...  the occs are from high to low (reals) 
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/runlab)
INCLUDE(common/work)
INCLUDE(common/canon_nat)
c
      ns_canon = 0
c
      call inpi(isec_canon)
c
1     call inpa4(ytest)
      if (ytest.eq.'prin') then
         opr_canon = .true.
         go to 1
      else if (ytest.eq.'occ') then
         if (o_canon) call caserr2('canon error')
         oset_canon = .false.
         o_canon = .true.
         go to 1
      else if (ytest.eq.'set') then
         if (o_canon) call caserr2('canon error')
         oset_canon = .true.
         o_canon = .true.
         go to 1
      else if (ytest.eq.'perm') then
         call caserr2('permutation not yet implemented')
      end if
c
      jrec = jrec - 1
      if (.not.o_canon) call caserr2('canon subdirective error')
      dum = 99999.0d0
      idum = 0
c
2     ns_canon = ns_canon + 1
      if (ns_canon.gt.10) call caserr2('to many sets in canonicalise')
      call inpa4(ytest)
      if (ytest.eq.'y') then
         iync(ns_canon) = 1
      else if (ytest.eq.'n') then
         iync(ns_canon) = 0
      else
         call caserr2('canon input error')
      end if
c
3     call inpa4(ytest)
      if (ytest.eq.'end') then
         ns_canon = ns_canon - 1
         return
      else if (ytest.eq.' ') then
         call input
         go to 3
      else
         jrec = jrec - 1
      end if
c
      if (oset_canon) then
         call inpi(isetc(ns_canon))
         if (isetc(ns_canon).le.idum) call caserr2('unordered canon')
         idum = isetc(ns_canon)
      else
         call inpf(aoccc(ns_canon))
         if (aoccc(ns_canon).ge.dum) call caserr2('unordered canon')
         dum = aoccc(ns_canon)
      end if
c
      go to 2
c
      return 
      end
_EXTRACT(secion,hp800)
      subroutine secion
c
      implicit REAL  (a-h,o-z)
      logical orjct1,orjct2
      character *8 ztype,zonel,ztext,zp
INCLUDE(common/work)
INCLUDE(common/restri)
c
      dimension ztype(40)
      dimension zonel(11)
      data ztype/
     1   'symmetry','geometry','basis','options','t+v','overlap',
     2   'density','vectors','eigval','scf','gradient','optimize',
     3   'hessian',
     4   'force','fcm','fock','mos','denpert','schlegel','denab',
     5   'lagrange','k','mapie','den2','hessian','        ','impt',
     6   'symorb','frequenc',10*'        ','end'/
      data zonel/'s','t+v','x','y','z','xx','yy','zz','xy','xz','yz'/
      orjct1(i) = i.le.310 .or. i.ge.390
      orjct2(i) = (i.ge.201 .and. i.le.300) .or. i.ge.390
c
c
 20   call input
      call inpa(ztext)
      do 30 i = 1 , 40
         if (ztext.eq.ztype(i)) go to 40
 30   continue
      call caserr2('error in sections command')
 40   go to (50,60,70,80,90,100,110,120,130,140,150,160,170,180,190,200,
     +       210,240,270,280,290,300,310,320,330,20,340,350,360,20,20,
     +       20,20,20,20,20,20,20,20,370) , i
 50   call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(1) = is
         go to 20
      end if
 60   call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(2) = is
         go to 20
      end if
 70   call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(3) = is
         go to 20
      end if
 80   call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(4) = is
         go to 20
      end if
 90   call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(5) = is
         go to 20
      end if
 100  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(6) = is
         go to 20
      end if
 110  call inpi(is)
      call inpi(it)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else if (orjct2(it)) then
         call caserr2('invalid section number')
      else
         if (it.eq.0) it = 210
         isect(7) = is
         isect(10) = it
         call inpi(it)
         if (orjct2(it)) then
            call caserr2('invalid section number')
         else
            if (it.eq.0) it = 241
            isect(41) = it
            go to 20
         end if
      end if
 120  call inpi(is)
      call inpi(it)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else if (orjct2(it)) then
         call caserr2('invalid section number')
      else
         isect(8) = is
         isect(11) = it
         go to 20
      end if
 130  call inpi(is)
      call inpi(it)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else if (orjct2(it)) then
         call caserr2('invalid section number')
      else
         if (it.eq.0) it = 212
         isect(9) = is
         isect(12) = it
         go to 20
      end if
 140  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(13) = is
         go to 20
      end if
 150  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(14) = is
         go to 20
      end if
 160  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(15) = is
         go to 20
      end if
 170  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(16) = is
         go to 20
      end if
 180  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(17) = is
         go to 20
      end if
 190  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(18) = is
         go to 20
      end if
 200  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(19) = is
         go to 20
      end if
 210  call inpa(zp)
      do 220 i = 1 , 11
         if (zp.eq.zonel(i)) go to 230
 220  continue
      call caserr2('invalid one-electron property in section')
 230  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(19+i) = is
         if (jrec.gt.jump) go to 20
         go to 210
      end if
 240  call inpa(zp)
      do 250 i = 3 , 11
         if (zp.eq.zonel(i)) go to 260
 250  continue
      call caserr2('invalid one-electron property in section')
 260  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(28+i) = is
         if (jrec.gt.jump) go to 20
         go to 240
      end if
 270  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(40) = is
         go to 20
      end if
 280  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(41) = is
         go to 20
      end if
 290  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(42) = is
         go to 20
      end if
 300  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(43) = is
         go to 20
      end if
 310  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(44) = is
         go to 20
      end if
 320  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(45) = is
         go to 20
      end if
 330  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(46) = is
         go to 20
      end if
 340  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(47) = is
         call inpi(is)
         if (orjct2(is)) then
            call caserr2('invalid section number')
         else
            isect(48) = is
            call inpi(is)
            if (orjct2(is)) then
               call caserr2('invalid section number')
            else
               if (is.eq.0) is = 249
               isect(49) = is
               call inpi(is)
               if (orjct2(is)) then
                  call caserr2('invalid section number')
               else
                  if (is.eq.0) is = 294
                  isect(94) = is
                  call inpi(is)
                  if (orjct2(is)) then
                     call caserr2('invalid section number')
                  else
                     if (is.eq.0) is = 295
                     isect(95) = is
                     call inpi(is)
                     if (orjct2(is)) then
                        call caserr2('invalid section number')
                     else
                        if (is.eq.0) is = 296
                        isect(96) = is
                        call inpi(is)
                        if (orjct2(is)) then
                           call caserr2('invalid section number')
                        else
                           if (is.eq.0) is = 297
                           isect(97) = is
                           call inpi(is)
                           if (orjct2(is)) then
                              call caserr2('invalid section number')
                           else
                              if (is.eq.0) is = 298
                              isect(98) = is
                              call inpi(is)
                              if (orjct2(is)) then
                                 call caserr2('invalid section number')
                              else
                                 if (is.eq.0) is = 299
                                 isect(99) = is
                                 go to 20
                              end if
                           end if
                        end if
                     end if
                  end if
               end if
            end if
         end if
      end if
 350  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(51) = is
         go to 20
      end if
 360  call inpi(is)
      if (orjct1(is)) then
         call caserr2('invalid section number')
      else
         isect(52) = is
         go to 20
      end if
c
c
 370  return
      end
_ENDEXTRACT
      subroutine setsym(ian,ztag,chg,symz,natoms,itype,tchg)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
c
      dimension ian(*), ztag(*), chg(*), symz(*), itype(*), tchg(*)
      data toler / 1.0d-8 /
c
c    setup the symz array to reflect the equivalence of
c    the centres
c
      dch = 0.01d0
      ntypes = 0
      do 10 i = 1, natoms
         itype(i) = 0
 10   continue
c
      do 30 i = 1, natoms
         if(itype(i).eq.0)then
            ntypes = ntypes + 1
            itype(i) = ntypes
            tchg(ntypes) = chg(i)
c
c  find equivalences 
c
            do 20 j = i + 1,natoms
               if((itype(j).eq.0).and.
     &              (ian(i).eq.ian(j)).and.
     &              (dabs(chg(i)-chg(j)).lt.toler).and.
     &              (ztag(i).eq.ztag(j)))
     &              itype(j) = itype(i)
 20         continue
         endif
 30      continue
c
c  modify real charges as required
c
c  1) Charges must not equal zero 
c     (zero charges effectively are being ignored)
c
      do i=1, ntypes
         if (dabs(tchg(i)).lt.toler) then
            if (tchg(i).lt.0.0d0) then
               tchg(i)=tchg(i)-dch
            else
               tchg(i)=tchg(i)+dch
            endif
         endif
      enddo
c
c  2) Make sure that different types of center have a different
c     charge, so that they distinguishable.
c
      do 60 i = 2, ntypes
 40      oredo = .false.
         do 50 j = 1, i - 1
            if(.not.oredo.and.dabs(tchg(j)-tchg(i)).lt.toler)then
               if (tchg(i).lt.0.0d0) then
                  tchg(i) = tchg(i) - dch
               else
                  tchg(i) = tchg(i) + dch
               endif
               oredo = .true.
            endif
 50      continue
         if (oredo) goto 40
 60   continue
c
c assign charges
c
      do 70 i = 1,natoms
         symz(i) = tchg(itype(i))
 70   continue
      return
      end
      subroutine secmom(maxap3,natoms,a,atmchg,eigval,eigvec)
c
c     compute the principal second moments of charge and axes of
c     charge for the natoms whose coordinates are in a and
c     atomic numbers are in atmchg.
c
c     abs(chg) used for consistency with center when
c     total charge is zero (ps)
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension a(maxap3,3), atmchg(*), eigval(*), eigvec(*)
      dimension t(6), e(9),ie2(18)
_IF1(a)      dimension dum(3,3)
c
      data dzero/0.0d0/
      data small/1.0d-6/
c
      do 20 i = 1 , 6
         t(i) = dzero
         ie2(i) = i*(i-1)/2
 20   continue
c
      ctot = 0.0d0
      do 25 iat = 1 , natoms
         ctot = ctot + atmchg(iat)
 25   continue
      oabs=(dabs(ctot).lt.small)
c
      do 30 iat = 1 , natoms
         an = atmchg(iat)
         if(oabs)an=dabs(an)
         setx = a(iat,1)
         sety = a(iat,2)
         setz = a(iat,3)
         t(1) = t(1) + an*(sety*sety+setz*setz)
         t(3) = t(3) + an*(setx*setx+setz*setz)
         t(6) = t(6) + an*(setx*setx+sety*sety)
         t(2) = t(2) - an*setx*sety
         t(4) = t(4) - an*setx*setz
         t(5) = t(5) - an*sety*setz
 30   continue
_IF(alliant)
c
c === alliant errors around here, try call to eigen instead
c
      ndim=3
      if=0
      lm=0
      do 1020 loop=1,ndim
      do 1020 moop=1,loop
      lm=lm+1
      dum(loop,moop) = t(lm)
1020  dum(moop,loop) = t(lm)
      call eigen(dum,ndim,ndim,eigval,eigvec,e,if)
c
_ELSE
      call gldiag(3,3,3,t,e,eigval,eigvec,ie2,2)
_ENDIF
      return
      end
      subroutine sget (toang, iunits)
c
c
c      read the up to 3 geometry input sections and fill /zmat/ and
c      /zsubst/.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/work)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
INCLUDE(common/csubch)
INCLUDE(common/iofile)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
c
      parameter ( mxsym8 = 8*maxnz+1)
      parameter ( mxsym4 = maxvar*8+1)
      parameter ( mxvar8 = maxvar*8+1)
      common/junk/xsymb(mxsym4),xstr(24),xnamv(mxvar8),xnamc(mxsym8)
c     - this junk is strictly local in this routine -
c
      dimension ytp1(5),ytp2(6)
      data ytp1/'vari','cons','coor','end','char'/
      data ytp2/'    ','type','hess','mini','angs','degs'/
      data xblank/' '/,xcom/','/
      data dzero/0.0d0/
      data done/1.0d0/, f45/45.d0/
c
c
c                                        read z-matrix section.
c                                        upon return from zsymb:
c                                         nsymb: total number of symbols
c
c                                         lbl, lalpha, lbeta:
c                                                1 for integer
c                                                2 for floating point
c                                                3 for symbol
c                                               -3 for -symbol
c
      nvar = 0
      do 30 i = 1 , maxnz
         lbl(i) = 0
         lalpha(i) = 0
         lbeta(i) = 0
         intvec(i) = 0
         fpvec(i) = dzero
         bl(i) = dzero
         alpha(i) = dzero
         beta(i) = dzero
         do 20 j = 1 , 4
            iz(i,j) = 0
 20      continue
 30   continue
      call ssymb(nsymb,xsymb,xnamc,ytest)
c
c                                        scan for integers as z-matrix
c                                        parameters and convert the
c                                        code used for constants.
c
      ok = .true.
      iatom = nz
      do 40 i = 1 , nz
chvd     czan(i) = dfloat(ianz(i))
         if (lbl(i).eq.2) lbl(i) = 0
         if (lalpha(i).eq.2) lalpha(i) = 0
         if (lbeta(i).eq.2) lbeta(i) = 0
         if (lbl(i).eq.1 .or. lalpha(i).eq.1 .or. lbeta(i).eq.1) then
            ok = .false.
            write (iwr,6010) i
         end if
 40   continue
      if (.not.ok) call caserr2('invalid parameters on z-matrix card')
c
c                                        only 0 and +/- 3 remains in
c                                        lbl, lalpha, lbeta.  unless
c                                        there are no symbols convert
c                                        these to +/- 3000 so that they
c                                        won't be confused as pointers
c                                        to variable 3.
c
      if (nsymb.ne.0) write (iwr,6040)
      do 50 i = 1 , nz
         lbl(i) = lbl(i)*1000
         lalpha(i) = lalpha(i)*1000
         lbeta(i) = lbeta(i)*1000
 50   continue
      ncursr = 0
c
c...  process the keyword last read by ssymb.
c
      i = locatc(ytp1,5,ytest)
      if (i.ne.0) then
         go to (60,140,170,220,200) , i
         go to 170
      end if
c
c                                       process variables section.
c
      write (iwr,6020)
 60   call input
      call inpa4(ytest)
      i = locatc(ytp1,5,ytest)
      if (i.ne.0) then
         go to (70,140,170,220,200) , i
         go to 170
      end if
 70   nvar = nvar + 1
c
c                                       top of loop over variables.
c
      if (nvar.gt.maxvar) then
         call caserr2(
     +        'maximum no. of permitted variables exceeded in z-matrix'
     +        )
      end if
      jrec = jrec - 1
c
c                                       read in name, value, integer,
c                                        floating point.
c            get variable name.
c
      call inpa(zname)
      jrec = jrec - 1
      do 80 i = 1 , 8
         xstr(i) = xblank
 80   continue
      call inpstr(xstr,lent,if1)
      if (lent.eq.0) nvar = nvar - 1
      if (lent.eq.0) go to 140
c
c                  pack the name into "anames".
c
      call putb(xstr,lent,xnamv,ncursr)
      ncursr = ncursr + 1
      xnamv(ncursr) = xcom
c
c                  get the value.
c
      call inpf(values(nvar))
      zvar(nvar) = zname
c
      i = locatc(zvar,nvar-1,zname)
      if (i.ne.0) then
         write(iwr,81) zname,i
81       format(/1x,'*** variable ',a8,' also at position',i5,' ***',
     1          /1x,'           ***   check zmatrix   ***')
         call caserr('variable doubling in zmatrix')
      end if
c     ov0 = .false.
c     fpvec(nvar)=0.4
      cmin10(nvar) = values(nvar)
      cmin20(nvar) = values(nvar)
 90   call inpa4(ytest)
      i = locatc(ytp2,6,ytest)
      if (i.eq.0) go to 90
      go to (130,100,110,120,110,110) , i
c
c  type
c
 100  call inpi(intvec(nvar))
c     if (intvec(nvar).ne.0) ov0 = .true.
      go to 90
c
c  hessian (also accept angs/degs)
c
 110  call inpf(fpvec(nvar))
      go to 90
 120  call inpf(cmin10(nvar))
      call inpf(cmin20(nvar))
      go to 90
 130  write (iwr,6050) zname , values(nvar) , intvec(nvar) ,
     +                  fpvec(nvar) , cmin10(nvar) , cmin20(nvar)
c
c                                      look for matches in the z-matrix.
c
      call smatch(ok,xsymb,xstr,lent,values(nvar),.true.,nsymb)
c
      if (ok) go to 60
c
c                                        end of variables section.
c                                        process constants section if
c                                        undefined symbols remain.
c
      call caserr2('symbol not found in z-matrix')
 140  write (iwr,6030)
 150  call input
      call inpa4(ytest)
      i = locatc(ytp1,5,ytest)
      if (i.ne.0) then
         go to (70,140,170,220,200) , i
      else
         if (nsymb.eq.0) go to 60
c
c                                        top of loop over constants.
c
c                                        read in name and value.
c
         jrec = jrec - 1
         call inpa(zname)
         jrec = jrec - 1
         do 160 i = 1 , 8
            xstr(i) = xblank
 160     continue
         call inpstr(xstr,lent,if1)
         call inpf(fp)
         write (iwr,6050) zname , fp
c
c
c                                        search for matches in the
c                                        z-matrix.
c
         call smatch(ok,xsymb,xstr,lent,fp,.false.,nsymb)
c
         if (ok) go to 150
         call caserr2('symbol not found in z-matrix')
         go to 140
      end if
c
c --- coordinates are read in here
c
 170  iatom = nz
      write (iwr,6060)
 180  call input
      call inpa4(ytest)
      i = locatc(ytp1,5,ytest)
      if (i.ne.0) then
         go to (70,140,170,220,200) , i
         go to 170
      else
         jrec = jrec - 1
         iatom = iatom + 1
         call inpa(ztest)
         zaname(iatom) = ztest
         jrec = jrec - 1
         do 190 i = 1 , 8
            xstr(i) = xblank
 190     continue
         call inpstr(xstr,len,if1)
         iat1 = isubst(xstr)
         if (iat1.eq.-10) then
            jrec = jrec - 1
            call inpi(imass(iatom))
         else
            imass(iatom) = iat1
         end if
         call inpf(c(1,iatom))
         call inpf(c(2,iatom))
         call inpf(c(3,iatom))
         call inpf(czan(iatom))
c
c ---- read in charges here
c
         write (iwr,6070) ztest , imass(iatom) , c(1,iatom) , 
     +          c(2,iatom) , c(3,iatom) , czan(iatom)
         go to 180
      end if
 200  write (iwr,6080)
 210  call input
      call inpa4(ytest)
      i = locatc(ytp1,5,ytest)
      if (i.ne.0) then
c
c                                         end of loop over constants.
c                                         insure that all symbols have
c                                         been defined.
c
         go to (70,140,170,220,200) , i
         go to 170
      else
         jrec = jrec - 1
         call inpa(ztest)
         call inpf(chgii)
         i = locatc(zaname,iatom,ztest)
         if (i.eq.0) call caserr2('error in charges - invalid label')
         czan(i) = chgii
         write (iwr,6090) ztest , chgii
c
c..       set other centers with the same name
c
215      j = i
         i = locatc(zaname(j+1),iatom-j,ztest) + j
         if (i.eq.j) go to 210
         czan(i) = chgii
         go to 215
      end if
c
c  ---  set iunits up here
c
 220  nat = iatom
      if (iunits.ne.3) then
         tobohr = done
         torad = done
         if (iunits.eq.1 .or. iunits.eq.2) tobohr = done/toang
         if (iunits.le.1) torad = datan(done)/f45
         do 230 i = 1 , nz
	    if(iz(i,1).lt.0) then
c             test for cartesian atom
              bl(i) = bl(i)*tobohr
	      alpha(i) = alpha(i)*tobohr
	      beta(i) = beta(i)*tobohr
	    else
	      bl(i) = bl(i)*tobohr
	      alpha(i) = alpha(i)*torad
	      beta(i) = beta(i)*torad
	    endif
 230     continue
         if (nvar.ne.0) then
            do 250 i = 1 , nvar
               con = torad
               do 240 j = 1 , nz
                  if (iabs(lbl(j)).eq.i) con = tobohr
 240           continue
	       do 241 j=1,nz
		 if(iabs(lalpha(j)).eq.i) then
		   if(iz(j,1).lt.0) con=tobohr
		 endif
		 if(iabs(lbeta(j)).eq.i) then
		   if(iz(j,1).lt.0) con=tobohr
	         endif
c      test for cartesian atom
 241           continue
               values(i) = values(i)*con
               cmin10(i) = cmin10(i)*con
               cmin20(i) = cmin20(i)*con
 250        continue
         end if
         nzp1 = nz + 1
         if (nzp1.le.iatom) then
            do 260 i = nzp1 , iatom
               c(1,i) = c(1,i)*tobohr
               c(2,i) = c(2,i)*tobohr
               c(3,i) = c(3,i)*tobohr
 260        continue
         end if
      end if
      return
c
 6010 format (/1x,'integer parameters encountered on z-matrix card ',i3)
 6020 format (1x,72('-')/30x,'variables'/1x,72('-'))
 6030 format (1x,72('-')/30x,'constants'/1x,72('-'))
 6040 format (/1x,72('=')/,1x,'name',12x,'input',2x,'type',5x,'hessian',
     +        9x,'minima'/,17x,'value',23x,'-1-',9x,'-2-')
 6050 format (1x,a8,1x,f12.6,2x,i4,3f12.6)
 6060 format (1x,72('-')/30x,'coordinates and charges'/1x,72('-'))
 6070 format (1x,a8,1x,i2,1x,3(f12.6,1x),2x,f12.6)
 6080 format (1x,72('-')/33x,'charges'/1x,72('-'))
 6090 format (1x,a8,1x,f12.6)
c
      end
      subroutine smatch(ok,xsymb,xname,len,value,ofvar,nsymb)
c
c
c ----------------------------------------------------------------------
c          a routine to search for a match in the symbolic z-matrix
c     for the symbol "symbol" (length "lensmb").  the calling routine
c     has read the symbol and its value;  this routine does all of
c     the necessary processing of the data.  the arguments are:
c
c          ok ....... a logical flag returned to indicate whether the
c               name was found in the z-matrix.
c          symbls ... a delimited hollerith string containing the
c               names of the symbols encountered in the z-matrix.
c          name ..... the name of the variable to be matched.
c          len ...... the number of characters in "name".
c          value  ... the value of the parameter.
c          ifvar .... a logical variable indicating whether this
c               parameter is a variable of a contstant:
c               t/f --- variable/constant.
c          nsymb .... number of symbols remaining in the z-matrix.
c               this is decremented by this routine as symbols are
c               matched.
c ----------------------------------------------------------------------
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension xsymb(*),xname(*)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
INCLUDE(common/csubch)
c
      dimension xstr(40)
      ncur = 0
      ok = .false.
c
c                  loop over z-matrix cards searching for a match
c                  for "symbol".  on each card, look to see whether
c                  any of the parameters match.
c
      do 70 i = 2 , nz
c
c                  check the bond length.
c
c            get the string from "symbols".
c
         call getb(xstr,lenstr,xsymb,ncur)
c
c            does it match?
c
         if (lenstr.eq.len) then
c
c            matched.  do necessary processing.
c
            do 20 j = 1 , len
               if (xstr(j).ne.xname(j)) go to 30
 20         continue
            ok = .true.
            nsymb = nsymb - 1
            if (ofvar) lbl(i) = isign(nvar,lbl(i))
            if (.not.(ofvar)) then
               bl(i) = value
               if (lbl(i).lt.0) bl(i) = -bl(i)
               lbl(i) = 0
            end if
         end if
c
c                  check bond angle.
c
c            get the string from "symbols".
c
 30      if (i.eq.2) go to 70
         call getb(xstr,lenstr,xsymb,ncur)
c
c            does it match?
c
         if (lenstr.eq.len) then
            do 40 j = 1 , len
               if (xstr(j).ne.xname(j)) go to 50
 40         continue
c
c            matched.  do necessary processing.
c
            ok = .true.
            nsymb = nsymb - 1
            if (ofvar) lalpha(i) = isign(nvar,lalpha(i))
            if (.not.(ofvar)) then
               alpha(i) = value
               if (lalpha(i).lt.0) alpha(i) = -value
               lalpha(i) = 0
            end if
         end if
c
c                  check last angle.
c
c            get the string from "symbols".
c
 50      if (i.ne.3) then
            call getb(xstr,lenstr,xsymb,ncur)
c
c            does it match?
c
            if (lenstr.eq.len) then
               do 60 j = 1 , len
                  if (xstr(j).ne.xname(j)) go to 70
 60            continue
c
c            matched.  do necessary processing.
c
               ok = .true.
               nsymb = nsymb - 1
               if (ofvar) lbeta(i) = isign(nvar,lbeta(i))
               if (.not.(ofvar)) then
                  beta(i) = value
                  if (lbeta(i).lt.0) beta(i) = -value
                  lbeta(i) = 0
               end if
            end if
         end if
 70   continue
c
      if (.not.ok) call caserr2('symbol not found in z-matrix')
      return
c
      end
      subroutine sparm(c,lx,xsymb,nsb,isymb)
c
c ----------------------------------------------------------------------
c          a routine to read a z-matrix parameter (variable or
c     floating point number).  uses the "ff" routines.  if a
c     constant is found, this is stored into "x", ans "lx" is set
c     to 2.  in this case, a name of "0" is stored into "symbls".
c
c          if a name (string) is found, then this name is appended
c     to "symbls", and "isymb" is incremented.  "x" is set to zero,
c     and "lx" is set to 3 (or -3 if "-name" is found).
c
c          this routine also calls the z-matrix output routine for
c     each parameter read in.
c ----------------------------------------------------------------------
      implicit none
      character*1 xstr(20),xsymb(*)
INCLUDE(common/work)
      REAL dzero,fp,c
      data dzero/0.0d0/
      character*1 xhash,xcom
      data xhash,xcom/'#',','/
      integer len,if1,isgn,isymb,nsb,lx
      call inpstr(xstr,len,if1)
      if (if1.eq.1) then
c
c                  found a name.
c
         call nosign(xstr,len,isgn)
         call putb(xstr,len,xsymb,nsb)
         nsb = nsb + 1
         xsymb(nsb) = xcom
         c = dzero
         lx = 3*isgn
         isymb = isymb + 1
         return
      else
c
c                  found real number.
c
         jrec = jrec - 1
         call inpf(fp)
         lx = 2
c
c            put a phony parameter name into "symbls".
c
         nsb = nsb + 1
         xsymb(nsb) = xhash
         nsb = nsb + 1
         xsymb(nsb) = xcom
         c = fp
         return
      end if
c
      end
      subroutine spdtr
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/iofile)
INCLUDE(common/restar)
INCLUDE(common/symtry)
INCLUDE(common/transf)
INCLUDE(common/frame)
      common/junk/trmat(432),ptr(3,144),dtr(6,288)
     *                  ,ftr(10,480),gtr(15,720)
      dimension ypname(3),ydname(6),yfname(10)
      dimension ygname(15)
      data ypname /'x'  ,'y'  ,'z'  /
      data ydname /'xx' ,'yy' ,'zz' ,'xy' ,'xz' ,'yz' /
      data yfname / 'xxx','yyy','zzz','xxy','xxz','yyx','yyz',
     2             'zzx','zzy','xyz'/
      data ygname/ 'xxxx','yyyy','zzzz','xxxy','xxxz','yyyx','yyyz',
     1             'zzzx','zzzy','xxyy','xxzz','yyzz','xxyz','yyxz',
     2             'zzxy'/
      data sqrt3 /1.73205080756888d0/
      data done /1.0d0/
      data sqrt5 /2.23606797749979d+00/
      data sqrt7 /2.64575131106459d+00/
c
c     ----- calculate transforms of p d f and g functions
c           for all symmetry operations.
c
      p = p0 + done
      q = q0
      r = r0
      call lframe(p,q,r,ps,qs,rs)
      psmal = ps
      qsmal = qs
      rsmal = rs
      do 20 it = 1 , nt
         nn = 9*(it-1)
         call trans1(nn)
         call rot
         n = 3*(it-1)
         ptr(1,n+1) = pp - p0
         ptr(2,n+1) = qp - q0
         ptr(3,n+1) = rp - r0
 20   continue
c
      p = p0
      q = q0 + done
      r = r0
      call lframe(p,q,r,ps,qs,rs)
      psmal = ps
      qsmal = qs
      rsmal = rs
      do 30 it = 1 , nt
         nn = 9*(it-1)
         call trans1(nn)
         call rot
         n = 3*(it-1)
         ptr(1,n+2) = pp - p0
         ptr(2,n+2) = qp - q0
         ptr(3,n+2) = rp - r0
 30   continue
c
      p = p0
      q = q0
      r = r0 + done
      call lframe(p,q,r,ps,qs,rs)
      psmal = ps
      qsmal = qs
      rsmal = rs
      do 40 it = 1 , nt
         nn = 9*(it-1)
         call trans1(nn)
         call rot
         n = 3*(it-1)
         ptr(1,n+3) = pp - p0
         ptr(2,n+3) = qp - q0
         ptr(3,n+3) = rp - r0
 40   continue
c
      do 250 it = 1 , nt
         np = 3*(it-1)
         nd = 6*(it-1)
         nf = 10*(it-1)
         ng = 15*(it-1)
         do 120 i = 1 , 6
            go to (50,60,70,80,90,100) , i
 50         j = 1
            k = 1
            go to 1100
 60         j = 2
            k = 2
            go to 1100
 70         j = 3
            k = 3
            go to 1100
 80         j = 1
            k = 2
            go to 1100
 90         j = 1
            k = 3
            go to 1100
 100        j = 2
            k = 3
 1100       dtr(1,nd+i) = ptr(1,np+j)*ptr(1,np+k)
            dtr(2,nd+i) = ptr(2,np+j)*ptr(2,np+k)
            dtr(3,nd+i) = ptr(3,np+j)*ptr(3,np+k)
            dtr(4,nd+i) = ptr(1,np+j)*ptr(2,np+k) + ptr(2,np+j)
     +                    *ptr(1,np+k)
            dtr(5,nd+i) = ptr(1,np+j)*ptr(3,np+k) + ptr(3,np+j)
     +                    *ptr(1,np+k)
            dtr(6,nd+i) = ptr(2,np+j)*ptr(3,np+k) + ptr(3,np+j)
     +                    *ptr(2,np+k)
 120     continue
c
c     -f-
c
         do 240 i = 1 , 10
            go to (130,140,150,160,170,180,190,200,210,220) , i
 130        j = 1
            k = 1
            go to 230
 140        j = 2
            k = 2
            go to 230
 150        j = 3
            k = 3
            go to 230
 160        j = 1
            k = 2
            go to 230
 170        j = 1
            k = 3
            go to 230
 180        j = 2
            k = 1
            go to 230
 190        j = 2
            k = 3
            go to 230
 200        j = 3
            k = 1
            go to 230
 210        j = 3
            k = 2
            go to 230
 220        j = 4
            k = 3
 230        ftr(1,nf+i) = dtr(1,nd+j)*ptr(1,np+k)
            ftr(2,nf+i) = dtr(2,nd+j)*ptr(2,np+k)
            ftr(3,nf+i) = dtr(3,nd+j)*ptr(3,np+k)
            ftr(4,nf+i) = dtr(1,nd+j)*ptr(2,np+k) + dtr(4,nd+j)
     +                    *ptr(1,np+k)
            ftr(5,nf+i) = dtr(1,nd+j)*ptr(3,np+k) + dtr(5,nd+j)
     +                    *ptr(1,np+k)
            ftr(6,nf+i) = dtr(2,nd+j)*ptr(1,np+k) + dtr(4,nd+j)
     +                    *ptr(2,np+k)
            ftr(7,nf+i) = dtr(2,nd+j)*ptr(3,np+k) + dtr(6,nd+j)
     +                    *ptr(2,np+k)
            ftr(8,nf+i) = dtr(3,nd+j)*ptr(1,np+k) + dtr(5,nd+j)
     +                    *ptr(3,np+k)
            ftr(9,nf+i) = dtr(3,nd+j)*ptr(2,np+k) + dtr(6,nd+j)
     +                    *ptr(3,np+k)
            ftr(10,nf+i) = dtr(4,nd+j)*ptr(3,np+k) + dtr(5,nd+j)
     +                     *ptr(2,np+k) + dtr(6,nd+j)*ptr(1,np+k)
 240     continue
c
c     -g-
c
      do 119 i=1,15
      go to (103,104,105,106,107,108,109,110,111,112,
     1       113,114,115,116,117),i
  103 j=1
      k=1
      go to 118
  104 j=2
      k=2
      go to 118
  105 j=3
      k=3
      go to 118
  106 j=1
      k=2
      go to 118
  107 j=1
      k=3
      go to 118
  108 j=2
      k=1
      go to 118
  109 j=2
      k=3
      go to 118
  110 j=3
      k=1
      go to 118
  111 j=3
      k=2
      go to 118
  112 j=4
      k=2
      go to 118
  113 j=5
      k=3
      go to 118
  114 j=7
      k=3
      go to 118
  115 j=4
      k=3
      go to 118
  116 j=6
      k=3
      go to 118
  117 j=8
      k=2
  118 gtr( 1,ng+i)=ftr( 1,nf+j)*ptr(1,np+k)
      gtr( 2,ng+i)=ftr( 2,nf+j)*ptr(2,np+k)
      gtr( 3,ng+i)=ftr( 3,nf+j)*ptr(3,np+k)
      gtr( 4,ng+i)=ftr( 1,nf+j)*ptr(2,np+k)
     1            +ftr( 4,nf+j)*ptr(1,np+k)
      gtr( 5,ng+i)=ftr( 1,nf+j)*ptr(3,np+k)
     1            +ftr( 5,nf+j)*ptr(1,np+k)
      gtr( 6,ng+i)=ftr( 2,nf+j)*ptr(1,np+k)
     1            +ftr( 6,nf+j)*ptr(2,np+k)
      gtr( 7,ng+i)=ftr( 2,nf+j)*ptr(3,np+k)
     1            +ftr( 7,nf+j)*ptr(2,np+k)
      gtr( 8,ng+i)=ftr( 3,nf+j)*ptr(1,np+k)
     1            +ftr( 8,nf+j)*ptr(3,np+k)
      gtr( 9,ng+i)=ftr( 3,nf+j)*ptr(2,np+k)
     1            +ftr( 9,nf+j)*ptr(3,np+k)
      gtr(10,ng+i)=ftr( 4,nf+j)*ptr(2,np+k)
     1            +ftr( 6,nf+j)*ptr(1,np+k)
      gtr(11,ng+i)=ftr( 5,nf+j)*ptr(3,np+k)
     1            +ftr( 8,nf+j)*ptr(1,np+k)
      gtr(12,ng+i)=ftr( 7,nf+j)*ptr(3,np+k)
     1            +ftr( 9,nf+j)*ptr(2,np+k)
      gtr(13,ng+i)=ftr( 4,nf+j)*ptr(3,np+k)
     1            +ftr( 5,nf+j)*ptr(2,np+k)
     2            +ftr(10,nf+j)*ptr(1,np+k)
      gtr(14,ng+i)=ftr( 6,nf+j)*ptr(3,np+k)
     1            +ftr( 7,nf+j)*ptr(1,np+k)
     2            +ftr(10,nf+j)*ptr(2,np+k)
      gtr(15,ng+i)=ftr( 8,nf+j)*ptr(2,np+k)
     1            +ftr( 9,nf+j)*ptr(1,np+k)
     2            +ftr(10,nf+j)*ptr(3,np+k)
  119 continue
c
 250  continue
c
      if (normf.ne.1 .or. normp.ne.1) then
         do 280 it = 1 , nt
            nd = 6*(it-1)
            nf = 10*(it-1)
            ng = 15*(it-1)
            do 260 i = 1 , 6
               if (i.gt.3) then
                  dtr(1,nd+i) = dtr(1,nd+i)*sqrt3
                  dtr(2,nd+i) = dtr(2,nd+i)*sqrt3
                  dtr(3,nd+i) = dtr(3,nd+i)*sqrt3
               else
                  dtr(4,nd+i) = dtr(4,nd+i)/sqrt3
                  dtr(5,nd+i) = dtr(5,nd+i)/sqrt3
                  dtr(6,nd+i) = dtr(6,nd+i)/sqrt3
               end if
 260        continue
c
c
c     -f-
c
            do 270 i = 1 , 10
               if (i.le.3) then
                  ftr(4,nf+i) = ftr(4,nf+i)/sqrt5
                  ftr(5,nf+i) = ftr(5,nf+i)/sqrt5
                  ftr(6,nf+i) = ftr(6,nf+i)/sqrt5
                  ftr(7,nf+i) = ftr(7,nf+i)/sqrt5
                  ftr(8,nf+i) = ftr(8,nf+i)/sqrt5
                  ftr(9,nf+i) = ftr(9,nf+i)/sqrt5
                  ftr(10,nf+i) = ftr(10,nf+i)/(sqrt5*sqrt3)
               else if (i.gt.9) then
                  ftr(1,nf+i) = ftr(1,nf+i)*sqrt5*sqrt3
                  ftr(2,nf+i) = ftr(2,nf+i)*sqrt5*sqrt3
                  ftr(3,nf+i) = ftr(3,nf+i)*sqrt5*sqrt3
                  ftr(4,nf+i) = ftr(4,nf+i)*sqrt3
                  ftr(5,nf+i) = ftr(5,nf+i)*sqrt3
                  ftr(6,nf+i) = ftr(6,nf+i)*sqrt3
                  ftr(7,nf+i) = ftr(7,nf+i)*sqrt3
                  ftr(8,nf+i) = ftr(8,nf+i)*sqrt3
                  ftr(9,nf+i) = ftr(9,nf+i)*sqrt3
               else
                  ftr(1,nf+i) = ftr(1,nf+i)*sqrt5
                  ftr(2,nf+i) = ftr(2,nf+i)*sqrt5
                  ftr(3,nf+i) = ftr(3,nf+i)*sqrt5
                  ftr(10,nf+i) = ftr(10,nf+i)/sqrt3
               end if
 270        continue
c
c     -g-
c
      do 129 i=1,15
      if(i.gt.3) go to 126
      gtr( 4,ng+i)=gtr( 4,ng+i)/sqrt7
      gtr( 5,ng+i)=gtr( 5,ng+i)/sqrt7
      gtr( 6,ng+i)=gtr( 6,ng+i)/sqrt7
      gtr( 7,ng+i)=gtr( 7,ng+i)/sqrt7
      gtr( 8,ng+i)=gtr( 8,ng+i)/sqrt7
      gtr( 9,ng+i)=gtr( 9,ng+i)/sqrt7
      gtr(10,ng+i)=gtr(10,ng+i)*sqrt3/(sqrt5*sqrt7)
      gtr(11,ng+i)=gtr(11,ng+i)*sqrt3/(sqrt5*sqrt7)
      gtr(12,ng+i)=gtr(12,ng+i)*sqrt3/(sqrt5*sqrt7)
      gtr(13,ng+i)=gtr(13,ng+i)/(sqrt5*sqrt7)
      gtr(14,ng+i)=gtr(14,ng+i)/(sqrt5*sqrt7)
      gtr(15,ng+i)=gtr(15,ng+i)/(sqrt5*sqrt7)
      go to 129
  126 if(i.gt.9) go to 127
      gtr( 1,ng+i)=gtr( 1,ng+i)*sqrt7
      gtr( 2,ng+i)=gtr( 2,ng+i)*sqrt7
      gtr( 3,ng+i)=gtr( 3,ng+i)*sqrt7
      gtr(10,ng+i)=gtr(10,ng+i)*sqrt3/sqrt5
      gtr(11,ng+i)=gtr(11,ng+i)*sqrt3/sqrt5
      gtr(12,ng+i)=gtr(12,ng+i)*sqrt3/sqrt5
      gtr(13,ng+i)=gtr(13,ng+i)/sqrt5
      gtr(14,ng+i)=gtr(14,ng+i)/sqrt5
      gtr(15,ng+i)=gtr(15,ng+i)/sqrt5
      go to 129
  127 if(i.gt.12) go to 128
      gtr( 1,ng+i)=gtr( 1,ng+i)*sqrt7*sqrt5/sqrt3
      gtr( 2,ng+i)=gtr( 2,ng+i)*sqrt7*sqrt5/sqrt3
      gtr( 3,ng+i)=gtr( 3,ng+i)*sqrt7*sqrt5/sqrt3
      gtr( 4,ng+i)=gtr( 4,ng+i)*sqrt5/sqrt3
      gtr( 5,ng+i)=gtr( 5,ng+i)*sqrt5/sqrt3
      gtr( 6,ng+i)=gtr( 6,ng+i)*sqrt5/sqrt3
      gtr( 7,ng+i)=gtr( 7,ng+i)*sqrt5/sqrt3
      gtr( 8,ng+i)=gtr( 8,ng+i)*sqrt5/sqrt3
      gtr( 9,ng+i)=gtr( 9,ng+i)*sqrt5/sqrt3
      gtr(13,ng+i)=gtr(13,ng+i)/sqrt3
      gtr(14,ng+i)=gtr(14,ng+i)/sqrt3
      gtr(15,ng+i)=gtr(15,ng+i)/sqrt3
      go to 129
  128 gtr( 1,ng+i)=gtr( 1,ng+i)*sqrt7*sqrt5
      gtr( 2,ng+i)=gtr( 2,ng+i)*sqrt7*sqrt5
      gtr( 3,ng+i)=gtr( 3,ng+i)*sqrt7*sqrt5
      gtr( 4,ng+i)=gtr( 4,ng+i)*sqrt5
      gtr( 5,ng+i)=gtr( 5,ng+i)*sqrt5
      gtr( 6,ng+i)=gtr( 6,ng+i)*sqrt5
      gtr( 7,ng+i)=gtr( 7,ng+i)*sqrt5
      gtr( 8,ng+i)=gtr( 8,ng+i)*sqrt5
      gtr( 9,ng+i)=gtr( 9,ng+i)*sqrt5
      gtr(10,ng+i)=gtr(10,ng+i)*sqrt3
      gtr(11,ng+i)=gtr(11,ng+i)*sqrt3
      gtr(12,ng+i)=gtr(12,ng+i)*sqrt3
  129 continue
 280     continue
      end if
c
c
c     ----- print matrices if nprint.eq.5 -----
c
      if (nprint.eq.1) then
         write (iwr,6020)
         do 320 it = 1 , nt
            write (iwr,6050)
            write (iwr,6060) it
            np = 3*(it-1)
            write (iwr,6030) (ypname(j),j=1,3)
            write (iwr,6070)
            do 290 i = 1 , 3
               write (iwr,6040) ypname(i) , (ptr(i,np+j),j=1,3)
 290        continue
            write (iwr,6010)
            nd = 6*(it-1)
            write (iwr,6030) (ydname(j),j=1,6)
            write (iwr,6070)
            do 300 i = 1 , 6
               write (iwr,6040) ydname(i) , (dtr(i,nd+j),j=1,6)
 300        continue
            write (iwr,6010)
            nf = 10*(it-1)
            write (iwr,6030) (yfname(j),j=1,10)
            write (iwr,6070)
            do 310 i = 1 , 10
               write (iwr,6040) yfname(i) , (ftr(i,nf+j),j=1,10)
 310        continue
            write (iwr,6010)
            ng=15*(it-1)
            jmax=0
  253       jmin=jmax+1
            jmax=jmax+10
            if(jmax.gt.15) jmax=15
            write (iwr,6030) (ygname(j),j=jmin,jmax)
            write (iwr,6070)
            do 254 i=1,15
  254          write (iwr,6040) ygname(i),(gtr(i,ng+j),j=jmin,jmax)
            write (iwr,6070)
            if (jmax.lt.15) go to 253
            write (iwr,6010)
c
 320     continue
      end if
c
      return
c
 6010 format (//)
 6020 format (/' transformation of the basis functions'/)
 6030 format (8x,10(3x,a4,3x))
 6040 format (2x,a4,2x,10f10.6)
 6050 format ('0')
 6060 format (/21x,'transformation number',i4,/)
 6070 format (/)
      end
      subroutine sphere(maxap3,natoms,a,b,d,atmchg,nset,
     $                  npop,norder,idump)
c
c     this routine is called for spherical top molecules.
c     it has two primary functions:
c     1--  the highest order proper rotation axis is found and its
c          value placed in norder.
c          the possibilities are:
c          5 for the point groups ih, i
c          4 for the point groups oh, o
c          3 for the point groups td, t, th
c     2--  the molecule's gross orientation is fixed as follows:
c          t, td, th  the three mutually perpindicular c2 axes are
c                     aligned with the cartesian axes so as to max-
c                     imize the z-coordinate of the key atom (defined
c                     below).
c          o, oh      the three mutually perpindicular c4 axes are
c                     aligned with the cartesian axes so as to max-
c                     imize the z-coordiante of the key atom.
c          i, ih      on of the six c5 axes is aligned with the
c                     catesian z-axis so as to maximize the z-coord-
c                     inate of the key atom.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
INCLUDE(common/iofile)
c
      dimension a(maxap3,3), b(maxap3,3), d(maxap3,3), atmchg(*),
     $          npop(*), nset(*)
      dimension centr(3), save(3), save2(3), t(3,3)
c
      data dzero,half,done,two/0.0d0,0.5d0,1.0d0,2.0d0/
c
      norder = 0
      numatm = natoms + 3
      halfpi = two*datan(done)
      pi = two*halfpi
c
c     find the spherical sets.
c
      call sphset(maxap3,natoms,a,atmchg,nset,npop,d,numset)
c
c     find the key atom -- the lowest numbered atom in the first
c     spherical set, where the sperical sets have been ordered
c     in sphset.
c
      key = natoms
      itop = npop(1)
      do 20 i = 1 , itop
         key = min(key,nset(i))
 20   continue
      if (idump.ne.0) write (iwr,6010) key
c
c     define the smallest spherical set.  axes will be searched for
c     within thes set.
c
      ioff = 0
      moff = 0
      mpop1 = natoms
      do 30 iset = 1 , numset
         mpop2 = min(mpop1,npop(iset))
         if (mpop2.ne.mpop1) then
            mpop1 = mpop2
c           mset = iset
            moff = ioff
         end if
         ioff = ioff + npop(iset)
 30   continue
c
c     pick three atoms from the set selected above.
c
      num3 = 0
      i2 = mpop1 - 2
      j2 = mpop1 - 1
      do 80 i = 1 , i2
         iat = nset(moff+i)
         j1 = i + 1
         do 70 j = j1 , j2
            jat = nset(moff+j)
            k1 = j + 1
            do 60 k = k1 , mpop1
               kat = nset(moff+k)
c
c     has a 4- or 5-fold axis been found in a previous triplet of atoms?
c        if yes  then branch to 120
c        else    search for 4- and 5-fold axes.
c
               if (norder.le.3) then
                  call movez(maxap3,a,d,numatm)
                  call tstc5(maxap3,d,b,natoms,atmchg,iat,jat,kat,centr,
     +                       itst)
                  if (itst.eq.0) then
c
                     call movez(maxap3,a,d,numatm)
                     call tstc4(maxap3,d,b,natoms,atmchg,iat,jat,kat,
     +                          centr,itst)
                     if (itst.eq.0) then
c
c     no axes have been found or num3 3-fold axis have been found.
c     test for a 3-fold axis
c       if no  then get 3 new atoms
c       else   test num3
c                if zero  then set norder, save centr in save, continue
c                if  one  then save cnetr in save2, continue
c                if  two  then continue
c       continue the search
c
                        if (num3.eq.2) go to 60
                        call movez(maxap3,a,d,numatm)
                        call tstc3(maxap3,d,b,natoms,atmchg,iat,jat,kat,
     +                             centr,itst)
                        if (itst.eq.0) go to 60
                        ihop = num3 + 1
                        go to (40,50) , ihop
                     else
                        norder = 4
                        call movez(maxap3,d,a,numatm)
                        go to 60
                     end if
                  else
                     norder = 5
                     savez = dabs(d(key,3))
                     save(1) = centr(1)
                     save(2) = centr(2)
                     save(3) = centr(3)
                     go to 60
                  end if
c
               else if (norder.eq.4) then
c
c     one 4-fold axis has already been found.
c     test the current atoms for a second 4-fold axis
c       if no  then continue the search
c       else   rotate about z to align the new c4 with y and branch
c              to 180
c
                  call movez(maxap3,a,d,numatm)
                  call tstc4(maxap3,d,b,natoms,atmchg,iat,jat,kat,centr,
     +                       itst)
                  if (itst.eq.0) go to 60
                  if (dabs(centr(3)).gt.toler) go to 60
                  setx = centr(1)
                  sety = centr(2)
                  theta = halfpi
                  if (dabs(sety).gt.toler) theta = datan(-setx/sety)
                  call rotate(maxap3,d,a,numatm,t,3,theta)
                  go to 90
               else
c
c     one 5-fold axis has already been found.
c     test the current atom triplet for a 5-fold axis
c       if no  then continue the search
c       else   is the z-coordinate of the key atom > savez?
c                 if yes  then save it
c                 else    continue the search
c
                  call movez(maxap3,a,d,numatm)
                  call tstc5(maxap3,d,b,natoms,atmchg,iat,jat,kat,centr,
     +                       itst)
                  if (itst.ne.0) then
                     curz = dabs(d(key,3))
                     if (dabs(curz-savez).ge.toler) then
                        if (savez.le.curz) then
                           savez = curz
                           save(1) = centr(1)
                           save(2) = centr(2)
                           save(3) = centr(3)
                        end if
                     end if
                  end if
                  go to 60
               end if
 40            norder = 3
               num3 = 1
               save(1) = centr(1)
               save(2) = centr(2)
               save(3) = centr(3)
               go to 60
 50            num3 = 2
               save2(1) = centr(1)
               save2(2) = centr(2)
               save2(3) = centr(3)
c
 60         continue
 70      continue
 80   continue
c
c     branch on the value of the highest order axis.  return if no
c     axis was found.
c
 90   if (norder.eq.0) return
      ihop = norder - 2
      go to (100,110,140) , ihop
c
c     norder = 3, point groups t, td, th.
c     vectors coincident with two of the 3-fold axes are in save and
c     save2.  align the c2 which bisects these with z.
c
 100  centr(1) = half*(save(1)+save2(1))
      centr(2) = half*(save(2)+save2(2))
      centr(3) = half*(save(3)+save2(3))
      call putt(maxap3,a,b,t,centr,numatm,3)
      b(1,1) = save(1)
      b(1,2) = save(2)
      b(1,3) = save(3)
      b(2,1) = save2(1)
      b(2,2) = save2(2)
      b(2,3) = save2(3)
      call putt(maxap3,b,d,t,centr,2,3)
      save(1) = b(1,1)
      save(2) = b(1,2)
      save(3) = b(1,3)
      save2(1) = b(2,1)
      save2(2) = b(2,2)
      save2(3) = b(2,3)
c
c     find a second c2 and align it with y.
c
      setx = half*(save(1)-save2(2))
      sety = half*(save(2)+save2(1))
      theta = halfpi
      if (dabs(sety).gt.toler) theta = datan(setx/sety)
      call rotate(maxap3,a,b,numatm,t,3,theta)
c
c     put that c2 on z which will maximize the z-coordinate of the
c     key atom.
c
      call movez(maxap3,b,a,numatm)
c
c     norder = 4, point groups o, oh.
c     the three c4 axes are aligned with the cartesian axes.  align that
c      c4 with z that will maximize the z-coordinate of the key atom.
c
 110  setx = a(key,1)
      sety = a(key,2)
      setz = a(key,3)
      cmax = dabs(setz)
      ixyz = 3
      do 120 i = 1 , 2
         tst = dabs(a(key,i))
         if (dabs(tst-cmax).ge.toler) then
            if (cmax.le.tst) then
               ixyz = i
               cmax = tst
            end if
         end if
 120  continue
      if (ixyz.ne.3) then
         ixyz = iabs(ixyz-2) + 1
         call rotate(maxap3,a,b,numatm,t,ixyz,halfpi)
         call movez(maxap3,b,a,numatm)
      end if
 130  if (a(key,3).gt.dzero) return
      call rotate(maxap3,a,b,numatm,t,1,pi)
      call movez(maxap3,b,a,numatm)
      return
c
c     norder = 5, point groups i, ih.
c     the c5 axis to be aligned with z is indicated by save.
c
 140  call putt(maxap3,a,b,t,save,numatm,3)
      go to 130
c
 6010 format (1x,'sphere-- key atom',i4)
      end
      subroutine sphset(maxap3,natoms,a,atmchg,nset,npop,aset,numset)
c
c     a "spherical-set" of atoms is hereby defined as consisting of
c     those atoms which have the same atomic number and which are
c     equidistant from the molecules charge center.  any atoms in a
c     molecule which are equivalent by symmetry must belong to the
c     same spherical-set.
c
c     this routine searches for spherical-sets of atoms.
c     nset(i)    gives the number of the atom in each set where the
c                boundrys between sets can be determined from npop.
c                the list is sorted in terms of increasing distance
c                from the origin and secondarily in terms of
c                increasing atomic number.
c     npop(j)    is the number of atoms in set j.
c     init(j)    is the number of the first atom in set j.
c     aset(i,1)  is atmchg(i) and is also used as a flag.
c     aset(i,2)  is the distance of the i'th atom from the origin.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
c
      parameter (maxat2=maxat+maxat)
      parameter (maxat4=maxat2+maxat2)
INCLUDE(common/tol)
      common/junk/ccc1(maxat,3),ccc2(maxat3,3),ccc3(maxat3,3),
     * npopc(maxat4),tspace(12),
     * mset(maxat2),mpop(maxat2),init(maxat2),idx(maxat2)
c
      dimension a(maxap3,3),atmchg(1),npop(1),nset(1),aset(maxap3,3)
c
      data dzero/0.0d0/
      do 20 iat = 1 , natoms
         aset(iat,1) = atmchg(iat)
c
c     fill aset.
c
         aset(iat,2) = dsqrt(a(iat,1)**2+a(iat,2)**2+a(iat,3)**2)
 20   continue
c
c     flag any atoms at the origin.
c
      do 30 iat = 1 , natoms
         if (dabs(aset(iat,2)).lt.toler) aset(iat,1) = dzero
 30   continue
c
c     fill mset and mpop.
c
      iattop = natoms - 1
      ic = 0
      iset = 0
      do 50 iat = 1 , iattop
         if (aset(iat,1).ne.dzero) then
            ic = ic + 1
            iset = iset + 1
            mpop(iset) = 1
            mset(ic) = iat
            init(iset) = iat
            j1 = iat + 1
            do 40 jat = j1 , natoms
               if (aset(jat,1).ne.dzero) then
                  if (dabs(aset(jat,2)-aset(iat,2)).le.toler) then
                     ic = ic + 1
                     mpop(iset) = mpop(iset) + 1
                     mset(ic) = jat
                     aset(jat,1) = dzero
                  end if
               end if
 40         continue
         end if
 50   continue
      numset = iset
c
c     ictop = ic
c
c     sort the list in terms of increasing distance from the origin.
c     if more than on set is at the same distance place the lower
c     atomic numbered one first.
c
c     the proper ordering is first extablished in idx.
c
      do 60 i = 1 , numset
         idx(i) = i
 60   continue
      if (numset.ne.1) then
         i = 0
 70      i = i + 1
         j = idx(i)
         iat = init(j)
         curd = aset(iat,2)
         curz = aset(iat,1)
         k1 = i + 1
         do 80 k = k1 , numset
            l = idx(k)
            jat = init(l)
            if (dabs(curd-aset(jat,2)).gt.toler) then
               if (curd.lt.aset(jat,2)) go to 80
            else if (curz.lt.aset(jat,1)) then
               go to 80
            end if
            idx(i) = l
            idx(k) = j
            iat = init(l)
            curd = aset(iat,2)
            curz = aset(iat,1)
 80      continue
         if (i.lt.numset-1) go to 70
      end if
c
c     move the data from mset and mpop to nset and npop using the
c     order stored in idx.
c
      ic = 0
      do 110 iset = 1 , numset
         jset = idx(iset)
         npop(iset) = mpop(jset)
         num = npop(iset)
         jc = 0
         if (jset.ne.1) then
            j2 = jset - 1
            do 90 j = 1 , j2
               jc = jc + mpop(j)
 90         continue
         end if
         do 100 i = 1 , num
            ic = ic + 1
            nset(ic) = mset(jc+i)
 100     continue
 110  continue
      return
      end
      subroutine sprint(maxnz,nz,ianz,iz,bl,alpha,beta,conver,iout)
c
c      z-matrix printing routine.
c      converts from internal (bohr/radian) units to external
c      (angstrom/degree) units locally for printing using conver.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character * 2 iel
c
c
      dimension ianz(*), bl(*), alpha(*), beta(*)
      dimension iz(maxnz,4)
      dimension iel(105)
      data done,f45/1.0d0, 45.0d0/
c
c      note that lower case letters are used in the atomic symbols
c      and in some of the format statements in hollereith strings.
c
      data iel/'x ', 'bq',
     $         'h ', 'he',
     $         'li', 'be', 'b ', 'c ', 'n ', 'o ', 'f ', 'ne',
     $         'na', 'mg', 'al', 'si', 'p ', 's ', 'cl', 'ar',
     $         'k ', 'ca',
     $                     'sc', 'ti', 'v ', 'cr', 'mn',
     $                     'fe', 'co', 'ni', 'cu', 'zn',
     $                     'ga', 'ge', 'as', 'se', 'br', 'kr',
     $ 'rb','sr','y ','zr','nb','mo','tc','ru','rh','pd','ag','cd',
     $ 'in','sn','sb','te','i ','xe','cs','ba','la','ce','pr','nd',
     $ 'pm','sm','eu','gd','tb','dy','ho','er','tm','yb','lu','hf',
     $ 'ta','w ','re','os','ir','pt','au','hg','tl','pb','bi','po',
     $ 'at','rn','fr','ra','ac','th','pa','u ','np','pu','am','cm',
     $ 'bk','cf','es','fm','md','no','lw'   /
c
c
      todeg = f45/datan(done)
c
c     print the heading.
c
      if (iout.ne.0) write (iout,6020)
      if (iout.ne.0) write (iout,6030)
      if (iout.ne.0) write (iout,6040)
      if (iout.ne.0) write (iout,6050)
      if (iout.ne.0) write (iout,6010)
c
c     first card of z-matrix.
c
      icard = 1
      idx = ianz(1) + 2
      if (ianz(1).lt.0) then
         icent = 0
         if (iout.ne.0) write (iout,6070) icard , iel(idx)
      else
         icent = 1
         if (iout.ne.0) write (iout,6060) icard , icent , iel(idx)
      end if
c
c     second card of the z-matrix.
c
      if (nz.ne.1) then
         np1 = 1
         icard = 2
         idx = ianz(2) + 2
         pbl = bl(2)*conver
         if (ianz(2).lt.0) then
            if (iout.ne.0) write (iout,6090) icard , iel(idx) , iz(2,1)
     +                            , pbl , np1
         else
            icent = icent + 1
            if (iout.ne.0) write (iout,6080) icard , icent , iel(idx) ,
     +                            iz(2,1) , pbl , np1
         end if
         if (nz.ne.2) then
c
c     third card.
c
            np1 = 2
            np2 = nz
            icard = 3
            idx = ianz(3) + 2
            pbl = bl(3)*conver
            pa = alpha(3)*todeg
            if (ianz(3).lt.0) then
               if (iout.ne.0) write (iout,6110) icard , iel(idx) ,
     +                               iz(3,1) , pbl , np1 , iz(3,2) ,
     +                               pa , np2
            else
               icent = icent + 1
               if (iout.ne.0) write (iout,6100) icard , icent , iel(idx)
     +                               , iz(3,1) , pbl , np1 , iz(3,2) ,
     +                               pa , np2
            end if
c
c     cards 4 through nz.
c
            if (nz.ne.3) then
               do 20 icard = 4 , nz
                  np1 = icard - 1
                  np2 = nz + icard - 3
                  np3 = nz*2 + icard - 6
                  idx = ianz(icard) + 2
                  pbl = bl(icard)*conver
                  pa = alpha(icard)*todeg
                  pb = beta(icard)*todeg
                  if (ianz(icard).lt.0) then
                     if (iout.ne.0) write (iout,6130) icard , iel(idx) ,
     +                   iz(icard,1) , pbl , np1 , iz(icard,2) , pa ,
     +                   np2 , iz(icard,3) , pb , np3 , iz(icard,4)
                  else
                     icent = icent + 1
                     if (iout.ne.0) write (iout,6120) icard , icent ,
     +                   iel(idx) , iz(icard,1) , pbl , np1 ,
     +                   iz(icard,2) , pa , np2 , iz(icard,3) , pb ,
     +                   np3 , iz(icard,4)
                  end if
 20            continue
            end if
         end if
      end if
c
c     print the trailer.
c
      if (iout.ne.0) write (iout,6030)
      return
 6010 format (1x,72('-'))
c
 6020 format (/)
 6030 format (1x,72('='))
 6040 format (1x,24x,'z-matrix (angstroms and degrees)')
 6050 format (1x,'cd cent atom  n1',6x,'length',6x,'n2',5x,'alpha',6x,
     +        'n3',6x,'beta',7x,'j')
 6060 format (1x,i2,2x,i2,3x,a2)
 6070 format (1x,i2,7x,a2)
 6080 format (1x,i2,2x,i2,3x,a2,3x,i2,2x,f9.6,' (',i3,')')
 6090 format (1x,i2,7x,a2,3x,i2,2x,f9.6,' (',i3,')')
 6100 format (1x,i2,2x,i2,3x,a2,3x,i2,2x,f9.6,' (',i3,') ',i2,1x,f8.3,
     +        ' (',i3,')')
 6110 format (1x,i2,7x,a2,3x,i2,2x,f9.6,' (',i3,') ',i2,1x,f8.3,' (',i3,
     +        ')')
 6120 format (1x,i2,2x,i2,3x,a2,3x,i2,2x,f9.6,' (',i3,') ',i2,1x,f8.3,
     +        ' (',i3,') ',i2,1x,f8.3,' (',i3,') ',i2)
 6130 format (1x,i2,7x,a2,3x,i2,2x,f9.6,' (',i3,') ',i2,1x,f8.3,' (',i3,
     +        ') ',i2,1x,f8.3,' (',i3,') ',i2)
c
      end
      subroutine sprintxz(maxnz,nz,ianz,iz,bl,alpha,beta,conver,iout)
c
c      z-matrix printing routine.
c      converts from internal (bohr/radian) units to external
c      (angstrom/degree) units locally for printing using conver.
c
      implicit REAL (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      character * 2 iel
      logical ocart
c
      dimension ianz(*), bl(*), alpha(*), beta(*)
      dimension iz(maxnz,4)
      dimension iel(105)
      data done,f45/1.0d0, 45.0d0/
c
c      note that lower case letters are used in the atomic symbols
c      and in some of the format statements in hollereith strings.
c
      data iel/'x ', 'bq',
     $         'h ', 'he',
     $         'li', 'be', 'b ', 'c ', 'n ', 'o ', 'f ', 'ne',
     $         'na', 'mg', 'al', 'si', 'p ', 's ', 'cl', 'ar',
     $         'k ', 'ca',
     $                     'sc', 'ti', 'v ', 'cr', 'mn',
     $                     'fe', 'co', 'ni', 'cu', 'zn',
     $                     'ga', 'ge', 'as', 'se', 'br', 'kr',
     $ 'rb','sr','y ','zr','nb','mo','tc','ru','rh','pd','ag','cd',
     $ 'in','sn','sb','te','i ','xe','cs','ba','la','ce','pr','nd',
     $ 'pm','sm','eu','gd','tb','dy','ho','er','tm','yb','lu','hf',
     $ 'ta','w ','re','os','ir','pt','au','hg','tl','pb','bi','po',
     $ 'at','rn','fr','ra','ac','th','pa','u ','np','pu','am','cm',
     $ 'bk','cf','es','fm','md','no','lw'   /
c
 1000 format(1x,72('-'))
 1001 format(/ )
 1002 format(1x,72('='))
 1010 format(1x,24x,'z-matrix (angstroms and degrees)')
 1020 format(1x,' cd cent  atom  n1', 7x,'length',6x,'n2',5x,'alpha',
     $          7x,'n3',6x,'beta',8x,'j')
 2110 format(1x,i3,2x,i3,3x,a2)
 2120 format(1x,i3,      8x,a2)
 2210 format(1x,i3,2x,i3,3x,a2,2x,i3,2x,f9.6,' (',i4,')')
 2220 format(1x,i3,      8x,a2,2x,i3,2x,f9.6,' (',i4,')')
 2310 format(1x,i3,2x,i3,3x,a2,2x,i3,2x,f9.6,' (',i4,') ',
     $          i3,1x,f8.3,' (',i4,')')
 2320 format(1x,i3,      8x,a2,2x,i3,2x,f9.6,' (',i4,') ',
     $          i3,1x,f8.3,' (',i4,')')
 2410 format(1x,i3,2x,i3,3x,a2,2x,i3,2x,f9.6,' (',i4,') ',
     $          i3,1x,f8.3,' (',i4,') ',i3,1x,f8.3,' (',i4,') '
     $        , i3)
 2420 format(1x,i3,      8x,a2,2x,i3,2x,f9.6,' (',i4,') ',
     $          i3,1x,f8.3,' (',i4,') ',i3,1x,f8.3,' (',i4,') '
     $       ,  i3)

 2500 format(1x,i3,2x,i3,3x,a2,2x,
     &     '  x',3x,f8.3,' (',i4,') ',
     $     '  y',1x,f8.3,' (',i4,') ',
     &     '  z',1x,f8.3,' (',i4,') ')
 2510 format(1x,i3,8x,      a2,2x,
     &     '  x',3x,f8.3,' (',i4,') ',
     $     '  y',1x,f8.3,' (',i4,') ',
     &     '  z',1x,f8.3,' (',i4,') ')
c
c

      todeg = f45 / datan(done)
c
c     print the heading.
c
      if(iout.ne.0)write(iout,1001)
      if(iout.ne.0)write(iout,1002)
      if(iout.ne.0)write(iout,1010)
      if(iout.ne.0)write(iout,1020)
      if(iout.ne.0)write(iout,1000)
c
c     first card of z-matrix.
c
      icard = 1
      idx   = ianz(1) + 2
      ocart = (iz(1,1) .lt.0)

      if (ianz(1) .ge. 0) then
         icent = 1
         if(iout.ne.0)then
            if(ocart)then
               write(iout,2500) icard, icent, iel(idx), 
     &              0.0, 0, 0.0 ,0 ,0.0, 0
            else
               write(iout,2110) icard,icent,iel(idx)
            endif
         endif
      else
         icent = 0
         if(iout.ne.0)then

            if(ocart)then
               write(iout,2510) icard,      iel(idx), 
     &              0.0, 0, 0.0 ,0 ,0.0, 0
            else
               write(iout,2120) icard,      iel(idx)
            endif
         endif
      endif
c
c     second card of the z-matrix.
c
      if (nz .eq. 1) goto 500

      np1   = 1
      icard = 2
      ocart = (iz(2,1) .lt.0)
      idx   = ianz(2) + 2
      pbl   = bl(2) * conver
      if (ianz(2) .ge. 0) then
         icent = icent + 1
         if(iout.ne.0)then
            if(ocart)then
	       pa    = alpha(icard) * conver
	       pb    = beta(icard)  * conver
               write(iout,2500) icard,icent,iel(idx),
     &              pa,0,pb,0,pbl,np1
            else
               write(iout,2210) icard,icent,iel(idx),iz(2,1),pbl,np1
            endif
         endif
      else
         if(iout.ne.0)then
            if(ocart)then
               write(iout,2510) icard,     iel(idx),
     &              0.0,0,0.0,0,pbl,np1
            else
               write(iout,2220) icard,      iel(idx),iz(2,1),pbl,np1
            endif
         endif
      endif
c
c     third card.
c
      if (nz .eq. 2) goto 500
      np1   = 2
      np2   = nz
      icard = 3
      idx   = ianz(3) + 2
      ocart = (iz(3,1) .lt.0)
      pbl   = bl(3) * conver
      if(ocart)then
         pa    = alpha(3) * conver
      else
         pa    = alpha(3) * todeg
      endif
      if (ianz(3) .ge. 0) then
         icent = icent + 1
         if(iout.ne.0)then
            if(ocart)then
               write(iout,2500) icard,icent,iel(idx),
     &              pa,np2,0.0,0,pbl,np1
            else
               write(iout,2310) icard,icent,iel(idx),iz(3,1),pbl,
     $              np1,iz(3,2),pa,np2
            endif
         endif
      else
         if(iout.ne.0)then
            if(ocart)then
               write(iout,2510) icard,     iel(idx),
     &              pa,np2,0.0,0,pbl,np1
            else
               write(iout,2320) icard,      iel(idx),iz(3,1),pbl,
     $              np1,iz(3,2),pa,np2
            endif
         endif
      endif
c
c     cards 4 through nz.
c
      if (nz .eq. 3) goto 500
      do icard=4,nz
         np1   = icard - 1
         np2   = nz + icard - 3
         np3   = nz*2 + icard - 6
         idx   = ianz(icard) + 2
         ocart = (iz(icard,1) .lt.0)

         pbl   = bl(icard) * conver
         if(ocart)then
            pa    = alpha(icard) * conver
            pb    = beta(icard)  * conver
         else
            pa    = alpha(icard) * todeg
            pb    = beta(icard)  * todeg
         endif

         if (ianz(icard) .ge. 0) then
            icent = icent + 1
            if(iout.ne.0)then

               if(ocart)then
                  write(iout,2500) icard,icent,iel(idx),
     &                 pa,np2,pb,np3,pbl,np1
               else
                  write(iout,2410) icard,icent,iel(idx),iz(icard,1),
     &                 pbl,np1,iz(icard,2),
     &                 pa,np2,iz(icard,3),
     &                 pb,np3,iz(icard,4)
               endif
            endif
         else
            if(iout.ne.0)then
               if(ocart)then
                  write(iout,2510) icard,    iel(idx),
     &                 pa,np2,pb,np3,pbl,np1
               else
                  write(iout,2420) icard,    iel(idx),iz(icard,1),
     &                 pbl,np1,iz(icard,2),
     &                 pa,np2,iz(icard,3),
     &                 pb,np3,iz(icard,4)
               endif
            endif
         endif

      enddo
c
c     print the trailer.
c
  500 continue
      if(iout.ne.0)write(iout,1002)
      return
c
      end
      subroutine squash(string,n)
      character*(*) string
      integer n,len,iskip
      logical odoub
      odoub = .false.
      do 10 i = 1,n
         if(string(i:i).ne.' ')then
            odoub = .false.
            len = n
         else
            if(odoub)string(i:i) = '!'
            odoub = .true.
         endif
 10   continue
      iskip = 0
      do 20 i = 1,len
         if(string(i:i).eq.'!')then
            iskip = iskip + 1
         else
            string(i-iskip:i-iskip) = string(i:i)
         endif
 20   continue
      string(len-iskip:)=' '
      return
      end
      subroutine ssymb (isymb,xsymb,xname,ylast)
c
c
      implicit none
      external isubst,locatc
      integer isubst,locatc
      integer i,isymb,nsb,ncur,len,if1
INCLUDE(common/sizes)
c
      character*8 ztest
      character*1 xsymb(*),xstr(8),xname(*)
INCLUDE(common/runlab)
INCLUDE(common/work)
INCLUDE(common/iofile)
INCLUDE(common/czmat)
INCLUDE(common/infoa)
c
      character*4 yvar(8),ylast
      character*1 xblnk,xcom
      data yvar/'vari','cons','cart','end','char','coor','inte',' '/
      data xblnk/' '/,xcom/','/
c
c     initialize the free-field input routine, the output routine,
c     and some flags.
c
c...  ylast returns the last read keyword. This is needed for 
c...  decend processing of the keywords by the calling subroutine.
c
      write (iwr,6010)
      nz = 0
      isymb = 0
      nsb = 0
      ncur = 0
c
c     here is the top of the loop for reading z-matrix cards.
c     -------------------------------------------------------
 20   continue
c
      call input
c
c                        get name of this center. make sure it's legal.
c
      call inpa4(ylast)
      do 30 i = 1 , 8
         xstr(i) = xblnk
 30   continue
 40   i = locatc(yvar,8,ylast)
      if(i.eq.3) then
         call rdcoords(isymb,xname,ncur,xsymb,nsb,ylast)
         goto 40
      else if (i.eq.7) then
         goto 20
      else if (i.gt.0) then
         return
      else
         call outrec
         jrec = jrec - 1
         call inpa(ztest)
         jrec = jrec - 1
         call inpstr(xstr,len,if1)
         if (len.gt.8) call caserr2('centre name in z-matrix too long')
c
c                        append this to the list (namcnt).
c
         call putb(xstr,len,xname,ncur)
         ncur = ncur + 1
         xname(ncur) = xcom
c
c                        print it out.
c
         nz = nz + 1
         zaname(nz) = ztest
c
c                        get atomic number of center.
c
         ianz(nz) = isubst(xstr)
         czan(nz) = dfloat(ianz(nz))
         if (nz.ne.1) then
c
c     trap for too many cards.
c
            if (nz.gt.maxnz) call caserr2(
     +          'maximum no. of permitted z-matrix cards exceeded')
c
c                        get the name of the center to which this
c                        is attached.
c
            call scentr(iz(nz,1),xname,nz)
c
c                        get the bond length.
c
            call sparm(bl(nz),lbl(nz),xsymb,nsb,isymb)
            if (nz.ge.3) then
c
c                        get name of third center.
c
               call scentr(iz(nz,2),xname,nz)
c
c                        get the internuclear angle.
c
               call sparm(alpha(nz),lalpha(nz),xsymb,nsb,isymb)
               if (nz.ge.4) then
c
c                        get the fourth center.
c
                  call scentr(iz(nz,3),xname,nz)
c
c                        get the last angle.
c
                  call sparm(beta(nz),lbeta(nz),xsymb,nsb,isymb)
c
c                        get the last integer.
c
c
c                        exit.
c
                  call inpi(iz(nz,4))
               end if
            end if
         end if
c
chvd     These few lines allow the charge of a BQ center to be specified
c        in the z-matrix. If present it should be the last item on card
c        which mean that itype should be specified as well.
c
         if (ianz(nz).eq.0) then
            if (jrec.lt.jump) then
               call inpf(czan(nz))
            endif
         endif
chvd
         go to 20
      end if
 6010 format (/1x,104('-')//40x,17('*')/40x,'symbolic z-matrix'/40x,
     +        17('*')//1x,72('-')/30x,'input z-matrix'/1x,72('-')/)
c
      end
      subroutine stoc(maxnz,nz,ianz,iz,bl,alph,bet,ottest,
     $                natoms,ian,c,cz,a,b,d,alpha,beta,iout,oerror)
c
c
c
c
c***********************************************************************
c     routine to compute the cartesian coordinates, given the
c     z-matrix.  this routine returns coordinates both with,
c     and without the dummy atoms.
c
c     arguments:
c
c     maxnz  ... maximum number of lines in z-matrix.
c     nz     ... number of lines in the z-matrix.
c     ianz   ... the atomic numbers of the z-matrix centers.
c     iz     ... the integer components of the z-matrix.
c     bl     ... the bond-lengths from the z-matrix.
c     alph   ... the bone-angles from the z-matrix.  these angles
c                must be in radians.
c     bet    ... the dihedral angles from the z-matrix.  like
c                alph, these angles must also be in radians.
c     ttest  ... logical flag to enable testing for tetrahedral angles.
c                this feature is useful in obtaining exact tetrahedral
c                angles.  if any are found and this flag is set "true",
c                then exact values are used and a message is printed
c                indicating how many angles were changed.  the values
c                in alph and/or bet are updated.
c     natoms ... number of atoms (dummies removed), computed by this
c                routine.
c     ian    ... vector of length natoms, will receive atomic
c                numbers with dummies compressed out.
c     c      ... coordinates, dummies compressed out.  stored
c                (x,y,z) for each atom.
c     cz     ... same as c, but with dummies still in.
c                the atomic number list, with dummies intact,
c                can be obtained from ianz.
c     a      ... scratch vector of length nz.
c     b      ... scratch vector of length nz.
c     d      ... scratch vector of length nz.
c     alpha  ... scratch vector of length nz.
c     beta   ... scratch vector of length nz.
c     iout   ... the logical unit number of the list output device.  if
c                iout=0 then such output will be supressed.
c     error  ... a logical variable set to true if ztoc is unable to
c                complete its task.  diagnostic messages will be printed
c                unless iout=0.
c
c     this routine is dimension free, in the sense that any
c     restrictions are imposed by the calling routine.
c
c     ztoc calls utilities vec and vcrossprod for miscellaneous
c     vector operations.
c***********************************************************************
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension ianz(*),iz(maxnz,4),bl(*),alpha(*),beta(*),ian(*),
     $          c(*),cz(*),a(*),b(*),d(*),alph(*),bet(*)
      dimension u1(3),u2(3),u3(3),u4(3),vj(3),vp(3),v3(3)
c
      data dzero/0.0d0/,done/1.0d0/,two/2.0d0/
      data tenm5/1.0d-5/,tenm6/1.0d-6/
      data f180/180.0d0/,four/4.0d0/
      data tenm10/1.0d-10/
      data tetdat/109.471d0/, toldat/0.001d0/, three/3.d0/
c
      otest(ccc) = dabs(ccc-tettst).lt.tettol
c
c
c     check for potential overflow.
c
      if (nz.le.maxnz) then
         oerror = .false.
         if (nz.ge.2) then
            do 20 i = 2 , nz
               if (i.gt.3) then
                  if (iabs(iz(i,4)).gt.1) then
                     oerror = .true.
                     if (iout.ne.0) write (iout,6020) i
                  end if
               end if
               if (iz(i,1).ge.i .or. iz(i,2).ge.i .or. iz(i,3).ge.i)
     +             then
                  oerror = .true.
                  if (iout.ne.0) write (iout,6030) i
               end if
               if (i.gt.2) then
                  if (i.gt.3) then
                     if (iz(i,1).eq.iz(i,2) .or. iz(i,1).eq.iz(i,3) .or.
     +                   iz(i,2).eq.iz(i,3)) then
                        oerror = .true.
                        if (iout.ne.0) write (iout,6040) i
                     end if
                  else if (iz(i,1).eq.iz(i,2)) then
                     oerror = .true.
                     if (iout.ne.0) write (iout,6040) i
                  end if
               end if
 20         continue
            if (oerror) return
         end if
         pi = four*datan(done)
         torad = pi/f180
c
c     set up for laundering tetrahedral angles.
c     this feature is only invoked when test=.true..
c
         tetang = dacos(-done/three)
         tettst = tetdat*torad
         tettol = toldat*torad
c
c     zero temporary coordinate array cz
c
         nz3 = 3*nz
         call vclr(cz,1,nz3)
c
c     move angles to local arrays and optionally test for
c     tetrahedral angles
c     test alpha for out of range 0 to 180 degrees
c     test for negative bond lengths.
c
         numtet = 0
         do 30 i = 1 , nz
            alpha(i) = alph(i)
            beta(i) = bet(i)
            if (bl(i).le.dzero .and. i.ne.1) then
               oerror = .true.
               write (iout,6070) i
            end if
            if (.not.(i.le.2 .or. (alpha(i).ge.dzero .and. alpha(i).le.
     +          pi))) then
               oerror = .true.
               if (iout.ne.0) write (iout,6060) i
            end if
            if (ottest) then
               if (otest(alpha(i))) then
                  alpha(i) = tetang
                  alph(i) = tetang
                  numtet = numtet + 1
               end if
               if (otest(beta(i))) then
                  beta(i) = tetang
                  bet(i) = tetang
                  numtet = numtet + 1
               end if
               if (iz(i,4).ne.0 .and. i.gt.3) then
                  if (beta(i).lt.dzero .or. beta(i).gt.pi) then
                     oerror = .true.
                     if (iout.ne.0) write (iout,6080) i
                  end if
               end if
            end if
 30      continue
         if ((numtet.ne.0) .and. (iout.ne.0)) write (iout,6090) numtet
         if (oerror) return
c
c     z-coordinate, atom 2.
c
         cz(6) = bl(2)
         if (nz.ge.3) then
c
c     x-coordinate, center 3.
c
            cz(7) = bl(3)*dsin(alpha(3))
            if (iz(3,1).ne.1) then
c
c     z-coordinate on center 3 as a function of z-coordinate, center 2.
c
               cz(9) = cz(6) - bl(3)*dcos(alpha(3))
            else
c
c     z-coordinate, center 3.
c
               cz(9) = bl(3)*dcos(alpha(3))
            end if
c
c     beware of linear molecule.
c
            if (nz.ge.4) then
               do 40 i = 4 , nz
                  ind3 = (i-1)*3
                  if (dabs(cz(1+ind3-3)).ge.tenm5) go to 50
                  cz(1+ind3) = bl(i)*dsin(alpha(i))
                  itemp = (iz(i,1)-1)*3
                  jtemp = (iz(i,2)-1)*3
                  cz(3+ind3) = cz(3+itemp) - bl(i)*dcos(alpha(i))
     +                         *dsign(done,cz(3+itemp)-cz(3+jtemp))
 40            continue
 50            k = i
               if (k.le.nz) then
                  do 100 j = k , nz
                     jnd3 = (j-1)*3
                     dcaj = dcos(alpha(j))
                     dsaj = dsin(alpha(j))
                     dcbj = dcos(beta(j))
                     dsbj = dsin(beta(j))
                     if (iz(j,4).eq.0) then
                        call vec(tenm6,ovec,u1,cz,iz(j,2),iz(j,3))
                        if (.not.ovec) then
                           call vec(tenm6,ovec,u2,cz,iz(j,1),iz(j,2))
                           if (.not.ovec) then
                              call vcrossprod(vp,u1,u2)
                              arg = done -
     +                              (u1(1)*u2(1)+u1(2)*u2(2)+u1(3)*u2(3)
     +                              )**2
                              if (arg.ge.dzero) then
                                 r = dsqrt(arg)
                                 if (r.ge.tenm6) then
                                    do 60 i = 1 , 3
                                       u3(i) = vp(i)/r
 60                                 continue
                                    call vcrossprod(u4,u3,u2)
                                    do 70 i = 1 , 3
                                       vj(i) = bl(j)
     +                                    *(-u2(i)*dcaj+u4(i)*dsaj*dcbj+
     +                                    u3(i)*dsaj*dsbj)
                                       itemp = (iz(j,1)-1)*3
                                       cz(i+jnd3) = vj(i) + cz(i+itemp)
 70                                 continue
                                    go to 100
                                 else
                                    oerror = .true.
                                    if (iout.ne.0) write (iout,6050) j
                                    return
                                 end if
                              else
                                 oerror = .true.
                                 if (iout.ne.0) write (iout,6050) j
                                 return
                              end if
                           else
                              oerror = .true.
                              if (iout.ne.0) write (iout,6050) j
                              return
                           end if
                        else
                           oerror = .true.
                           if (iout.ne.0) write (iout,6050) j
                           return
                        end if
                     else if (iabs(iz(j,4)).ne.1) then
                        call vec(tenm6,ovec,u1,cz,iz(j,1),iz(j,3))
                        if (.not.ovec) then
                           call vec(tenm6,ovec,u2,cz,iz(j,2),iz(j,1))
                           if (.not.ovec) then
                              czeta = -
     +                                (u1(1)*u2(1)+u1(2)*u2(2)+u1(3)*u2(
     +                                3))
                              call vcrossprod(v3,u1,u2)
                    v3mag = dsqrt(v3(1)*v3(1)+v3(2)*v3(2)+ v3(3)*v3(3))
                              denom = done - czeta**2
                              if (dabs(denom).gt.tenm6) then
                                 a(j) = v3mag*dcbj/denom
                                 arg = (done-dcaj*dcaj-a(j)*dcbj*v3mag)
     +                                 /denom
                                 if (arg.ge.dzero) then
                                    b(j) = dsqrt(arg)
                                    if (iz(j,4).ne.2) then
                                       b(j) = -b(j)
                                    end if
                                    d(j) = b(j)*czeta + dcaj
                                    do 80 i = 1 , 3
                                       u3(i) = b(j)*u1(i) + d(j)*u2(i)
     +                                    + a(j)*v3(i)
                                       vj(i) = bl(j)*u3(i)
                                       itemp = (iz(j,1)-1)*3
                                       cz(i+jnd3) = vj(i) + cz(i+itemp)
 80                                 continue
                                    go to 100
                                 else
                                    oerror = .true.
                                    if (iout.ne.0) write (iout,6050) j
                                    return
                                 end if
                              else
                                 oerror = .true.
                                 if (iout.ne.0) write (iout,6050) j
                                 return
                              end if
                           else
                              oerror = .true.
                              if (iout.ne.0) write (iout,6050) j
                              return
                           end if
                        else
                           oerror = .true.
                           if (iout.ne.0) write (iout,6050) j
                           return
                        end if
                     else
                        call vec(tenm6,ovec,u1,cz,iz(j,1),iz(j,3))
                        if (.not.ovec) then
                           call vec(tenm6,ovec,u2,cz,iz(j,2),iz(j,1))
                           if (.not.ovec) then
                              czeta = -
     +                                (u1(1)*u2(1)+u1(2)*u2(2)+u1(3)*u2(
     +                                3))
                              denom = done - czeta**2
                              if (dabs(denom).ge.tenm6) then
                                 a(j) = (-dcbj+czeta*dcaj)/denom
                                 b(j) = (dcaj-czeta*dcbj)/denom
                                 r = dzero
                                 gamma = pi/two
                                 if (dabs(czeta).ge.tenm6) then
                                    if (czeta.lt.dzero) r = pi
                                    if (denom.ge.dzero) then
                                  gamma = datan(dsqrt(denom)/czeta) + r
                                    else
                                       oerror = .true.
                                       if (iout.ne.0) write (iout,6050)
     +                                    i
                                       return
                                    end if
                                 end if
                              else
                                 oerror = .true.
                                 if (iout.ne.0) write (iout,6050) j
                                 return
                              end if
                           else
                              oerror = .true.
                              if (iout.ne.0) write (iout,6050) j
                              return
                           end if
                        else
                           oerror = .true.
                           if (iout.ne.0) write (iout,6050) j
                           return
                        end if
                     end if
                     d(j) = dzero
                     if (dabs(gamma+alpha(j)+beta(j)-two*pi).ge.tenm6)
     +                   then
                        arg = (done+a(j)*dcbj-b(j)*dcaj)/denom
                        if (arg.ge.dzero) then
                           d(j) = dfloat(iz(j,4))*dsqrt(arg)
                        else
                           oerror = .true.
                           if (iout.ne.0) write (iout,6050) j
                           return
                        end if
                     end if
                     call vcrossprod(v3,u1,u2)
                     do 90 i = 1 , 3
                        u3(i) = a(j)*u1(i) + b(j)*u2(i) + d(j)*v3(i)
                        vj(i) = bl(j)*u3(i)
                        itemp = (iz(j,1)-1)*3
                        cz(i+jnd3) = vj(i) + cz(i+itemp)
 90                  continue
 100              continue
               end if
            end if
         end if
c
c     eliminate dummy atoms.  dummy atoms are characterized by
c     negative atomic numbers.  ghost atoms have zero atomic
c     numbers.  ghost atoms are not eliminated.
c
         natoms = 0
         iaind = 0
         naind = 0
         do 110 i = 1 , nz
            if (ianz(i).ge.0) then
               natoms = natoms + 1
               ian(natoms) = ianz(i)
               c(1+naind) = cz(1+iaind)
               c(2+naind) = cz(2+iaind)
               c(3+naind) = cz(3+iaind)
               naind = naind + 3
            end if
            iaind = iaind + 3
 110     continue
c
c     'tidy' up the coordinates.
c
         nat3 = 3*natoms
         do 120 i = 1 , nat3
            if (dabs(c(i)).le.tenm10) then
               c(i) = dzero
            end if
 120     continue
         return
      else
         oerror = .true.
         write (iout,6010) nz , maxnz
         return
      end if
c
 6010 format (1x,i7,' z-matrix cards is greater than the maximum of ',
     +        i4,' in subroutine stoc')
 6020 format (1x,'error on z-matrix card number ',i4/1x,
     +        'invalid beta angle type (z4)')
 6030 format (1x,'error on z-matrix card number ',i4/1x,
     +        'reference made to an undefined center')
 6040 format (1x,'error on z-matrix card number ',i4/1x,
     +        'multiple references to a center on the same card')
 6050 format (1x,'error on z-matrix card number ',i4/1x,
     +        'incipient floating point error detected')
 6060 format (1x,'error on z-matrix card number ',i4/1x,
     +        'angle alpha is outside the valid range of 0 to 180')
 6070 format (1x,'error on z-matrix card number ',i4/1x,
     +        'negative bond length')
 6080 format (1x,'error on z-matrix card number ',i4/1x,
     +        'angle beta is outside the valid range of 0 to 180')
 6090 format (1x,i3,' tetrahedral angles replaced')
c
      end
      subroutine stocxz(maxnz,nz,ianz,iz,bl,alph,bet,ottest,
     $                natoms,ian,c,cz,a,b,d,alpha,beta,iout,oerror)
c
c***********************************************************************
c     routine to compute the cartesian coordinates, given the
c     z-matrix.  this routine returns coordinates both with,
c     and without the dummy atoms.
c
c     arguments:
c
c     maxnz  ... maximum number of lines in z-matrix.
c     nz     ... number of lines in the z-matrix.
c     ianz   ... the atomic numbers of the z-matrix centers.
c     iz     ... the integer components of the z-matrix.
c     bl     ... the bond-lengths from the z-matrix.
c     alph   ... the bone-angles from the z-matrix.  these angles
c                must be in radians.
c     bet    ... the dihedral angles from the z-matrix.  like
c                alph, these angles must also be in radians.
c     ttest  ... logical flag to enable testing for tetrahedral angles.
c                this feature is useful in obtaining exact tetrahedral
c                angles.  if any are found and this flag is set "true",
c                then exact values are used and a message is printed
c                indicating how many angles were changed.  the values
c                in alph and/or bet are updated.
c     natoms ... number of atoms (dummies removed), computed by this
c                routine.
c     ian    ... vector of length natoms, will receive atomic
c                numbers with dummies compressed out.
c     c      ... coordinates, dummies compressed out.  stored
c                (x,y,z) for each atom.
c     cz     ... same as c, but with dummies still in.
c                the atomic number list, with dummies intact,
c                can be obtained from ianz.
c     a      ... scratch vector of length nz.
c     b      ... scratch vector of length nz.
c     d      ... scratch vector of length nz.
c     alpha  ... scratch vector of length nz.
c     beta   ... scratch vector of length nz.
c     iout   ... the logical unit number of the list output device.  if
c                iout=0 then such output will be supressed.
c     error  ... a logical variable set to true if ztoc is unable to
c                complete its task.  diagnostic messages will be printed
c                unless iout=0.
c
c     this routine is dimension free, in the sense that any
c     restrictions are imposed by the calling routine.
c
c     ztoc calls utilities vec and vcrossprod for miscellaneous
c     vector operations.
c***********************************************************************
c
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension ianz(*),iz(maxnz,4),bl(*),alpha(*),beta(*),ian(*),
     $          c(*),cz(*),a(*),b(*),d(*),alph(*),bet(*)
      dimension u1(3),u2(3),u3(3),u4(3),vj(3),vp(3),v3(3)
c
      data dzero/0.0d0/,done/1.0d0/,two/2.0d0/
      data tenm5/1.0d-5/,tenm6/1.0d-6/
      data f180/180.0d0/,four/4.0d0/
      data tenm10/1.0d-10/
      data tetdat/109.471d0/, toldat/0.001d0/, three/3.d0/
c
 1000 format(1x,i7,' z-matrix cards is greater than the maximum of ',
     &     i4,' in subroutine stoc')
 1010 format(1x,'error on z-matrix card number ',i4
     $      /1x,'invalid beta angle type (z4)')
 1020 format(1x,'error on z-matrix card number ',i4
     $      /1x,'reference made to an undefined center')
 1030 format(1x,'error on z-matrix card number ',i4
     $      /1x,'multiple references to a center on the same card')
 1040 format(1x,'error on z-matrix card number ',i4
     $      /1x,'incipient floating point error detected')
 1050 format(1x,'error on z-matrix card number ',i4
     $      /1x,'angle alpha is outside the valid range of 0 to 180')
 1060 format(1x,'error on z-matrix card number ',i4
     $      /1x,'negative bond length')
 1070 format(1x,'error on z-matrix card number ',i4
     $      /1x,'angle beta is outside the valid range of 0 to 180')
 2001 format(1x,i3,' tetrahedral angles replaced')
c
      otest(ccc) =  dabs(ccc-tettst) .lt. tettol
      ocart(i) = iz(i,1) .lt. 0
c
c
c     check for potential overflow.
c
      if (nz .le. maxnz) goto 5
         oerror = .true.
         write (iout,1000) nz,maxnz
         return
    5 continue
      oerror = .false.

      do i=2,nz
c
c  ignore  cartesian atoms
c
         if(.not. ocart(i))then
            if (i .gt. 3  .and. iabs(iz(i,4)) .gt. 1) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1010) i
            endif

            if ( iz(i,1).ge.i .or. 
     &           iz(i,2).ge.i .or.
     &           iz(i,3).ge.i) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1020) i
            endif

            if (i .gt. 2) then
               if (i .le. 3) then
                  if (iz(i,1) .eq. iz(i,2)) then
                     oerror = .true.
                     if (iout .ne. 0) write (iout,1030) i
                  endif
               else
                  if ( iz(i,1) .eq. iz(i,2)  .or.
     $                 iz(i,1) .eq. iz(i,3)  .or.
     $                 iz(i,2) .eq. iz(i,3)) then
                     oerror = .true.
                     if (iout .ne. 0) write (iout,1030) i
                  endif
               endif
            endif
         endif
      enddo
      if (oerror) return


      pi=four* datan(done)
      torad=pi/f180
c
c     set up for laundering tetrahedral angles.
c     this feature is only invoked when test=.true..
c
      tetang = dacos(-done/three)
      tettst = tetdat * torad
      tettol = toldat * torad
c
c     zero temporary coordinate array cz
c
      nz3=3*nz
      call vclr(cz,1,nz3)
c
c     move angles to local arrays and optionally test for
c     tetrahedral angles
c     test alpha for out of range 0 to 180 degrees
c     test for negative bond lengths.
c
      numtet = 0
      do i=1,nz
         if(ocart(i)) then
            alpha(i) = 0.0d0
            beta(i)  = 0.0d0
         else
            alpha(i) = alph(i)
            beta(i)  = bet(i)
            if (bl(i).le.dzero .and. i.ne.1) then
               oerror = .true.
               write (iout,1060) i
            endif
            if(i.gt.2.and.(alpha(i).lt.dzero.or.alpha(i).gt.pi)) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1050) i
            endif
            if (ottest ) then
               if (otest(alpha(i))) then
                  alpha(i) = tetang
                  alph(i)  = tetang
                  numtet = numtet + 1
               endif
               if (otest(beta(i))) then
                  beta(i) = tetang
                  bet(i)  = tetang
                  numtet = numtet + 1
               endif
               if (iz(i,4).ne.0 .and. i.gt.3 .and.
     &              (beta(i).lt.dzero .or. beta(i).gt.pi)) then
                  oerror = .true.
                  if (iout .ne. 0) write (iout,1070) i
               endif
            endif
         endif
      enddo
      if( (numtet.ne.0) .and. (iout.ne.0) ) write(iout,2001)numtet
      if (oerror) return
c
c     z-coordinate, atom 2.
c
      cz(6)=bl(2)
      if(nz.lt.3)go to 260
c
c  center 3.
c
      i=3
      if(ocart(i))then
         cz(7)=alph(3)
         cz(9)=bl(3)
      else
         cz(7)=bl(3)* dsin(alpha(3))
         if(iz(3,1).eq.1)then
c
c     z-coordinate, center 3.
c
            cz(9)=bl(3)* dcos(alpha(3))
         else
c
c     z-coordinate on center 3 as a function of z-coordinate, center 2.
c
            cz(9)=cz(6)-bl(3)* dcos(alpha(3))
         endif
      endif
c
c     beware of linear molecule.
c
      if(nz.lt.4)go to 260

      do 80 i=4,nz
         ind3=(i-1)*3
         if( dabs(cz(1+ind3-3)).ge.tenm5 .or. ocart(i))go to 90
         cz(1+ind3)=bl(i)* dsin(alpha(i))
         itemp=(iz(i,1)-1)*3
         jtemp=(iz(i,2)-1)*3
         cz(3+ind3)=cz(3+itemp)-bl(i)* dcos(alpha(i))*
     $        dsign(done,cz(3+itemp)-cz(3+jtemp))
 80   continue

 90   k=i
      if(k.gt.nz)go to 260
c
c  >>>>>>>>>>>>>>>>>>>>>>  main atom loop
c
      do 250 j=k,nz

         jnd3=(j-1)*3
         dcaj= dcos(alpha(j))
         dsaj= dsin(alpha(j))
         dcbj= dcos(beta(j))
         dsbj= dsin(beta(j))

         if(ocart(j))then 

            cz(3+jnd3)=bl(j)
            cz(1+jnd3)=alph(j)
            cz(2+jnd3)=bet(j)
            
         else if(iz(j,4) .eq.0 )then 
         
            call vec(tenm6,ovec,u1,cz,iz(j,2),iz(j,3))
            if (ovec) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            call vec(tenm6,ovec,u2,cz,iz(j,1),iz(j,2))
            if (ovec) then
               oerror = .true.
               write(6,*)'trap 112',j
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            call vcrossprod(vp,u1,u2)
            arg = done - (u1(1)*u2(1)+u1(2)*u2(2)+u1(3)*u2(3))**2
            if (arg .lt. dzero) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            r = dsqrt(arg)
            if (r .lt. tenm6) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            do  i=1,3
               u3(i)=vp(i)/r
            enddo
            call vcrossprod(u4,u3,u2)
            do i=1,3
               vj(i)=bl(j)*
     &              (-u2(i)*dcaj+u4(i)*dsaj*dcbj+u3(i)*dsaj*dsbj)
               itemp=(iz(j,1)-1)*3
               cz(i+jnd3)=vj(i)+cz(i+itemp)
            enddo
c
         else if (iabs(iz(j,4)).eq.1) then
c 135     if(iabs(iz(j,4))-1)210,140,210
            call vec(tenm6,ovec,u1,cz,iz(j,1),iz(j,3))
            if (ovec) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            call vec(tenm6,ovec,u2,cz,iz(j,2),iz(j,1))
            if (ovec) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            czeta=-(u1(1)*u2(1)+u1(2)*u2(2)+u1(3)*u2(3))
            denom = done - czeta ** 2
            if ( dabs(denom) .lt. tenm6) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            a(j)=(-dcbj+czeta*dcaj)/denom
            b(j)=(dcaj-czeta*dcbj)/denom
            r=dzero
            gamma=pi/two
            if ( dabs(czeta) .ge. tenm6) then
               if (czeta .lt. dzero) r = pi
               if (denom .lt. dzero) then
                  oerror = .true.
                  if (iout .ne. 0) write (iout,1040) j
                  return
               endif
               gamma=datan(dsqrt(denom)/czeta)+r
            endif
            d(j)=dzero
            if( dabs(gamma+alpha(j)+beta(j)-two*pi)-tenm6)190,180,180
 180        arg = (done + a(j)*dcbj - b(j)*dcaj)  /  denom
            if (arg .lt. dzero) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            d(j) =  dble(iz(j,4)) * dsqrt(arg)
 190        call vcrossprod(v3,u1,u2)
            do i=1,3
               u3(i)=a(j)*u1(i)+b(j)*u2(i)+d(j)*v3(i)
               vj(i)=bl(j)*u3(i)
               itemp=(iz(j,1)-1)*3
               cz(i+jnd3)=vj(i)+cz(i+itemp)
            enddo
c
         else

            call vec(tenm6,ovec,u1,cz,iz(j,1),iz(j,3))
            if ( ovec) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            call vec(tenm6,ovec,u2,cz,iz(j,2),iz(j,1))
            if (ovec) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            czeta=-(u1(1)*u2(1)+u1(2)*u2(2)+u1(3)*u2(3))
            call vcrossprod(v3,u1,u2)
            v3mag = dsqrt(v3(1)*v3(1)+v3(2)*v3(2)+v3(3)*v3(3))
            denom = done - czeta**2
            if ( dabs(denom) .le. tenm6) then
               oerror = .true.
               write(6,*)'trap 213',j
               if (iout .ne. 0) write(iout,1040) i
               return
            endif
            a(j) = v3mag*dcbj / denom
            arg = (done-dcaj*dcaj-a(j)*dcbj*v3mag) / denom
            if (arg .lt. dzero) then
               oerror = .true.
               if (iout .ne. 0) write (iout,1040) j
               return
            endif
            b(j) = dsqrt(arg)
            if(iz(j,4)-2)220,230,220
 220        b(j)=-b(j)
 230        d(j)=b(j)*czeta+dcaj
            do  i=1,3
               u3(i)=b(j)*u1(i)+d(j)*u2(i)+a(j)*v3(i)
               vj(i)=bl(j)*u3(i)
               itemp=(iz(j,1)-1)*3
               cz(i+jnd3)=vj(i)+cz(i+itemp)
            enddo
         endif

 250  continue
c
c     eliminate dummy atoms.  dummy atoms are characterized by
c     negative atomic numbers.  ghost atoms have zero atomic
c     numbers.  ghost atoms are not eliminated.
c
 260  natoms=0
      iaind=0
      naind=0
      do i=1,nz
         if(ianz(i).ge.0)then
            natoms=natoms+1
            ian(natoms)=ianz(i)
            c(1+naind)=cz(1+iaind)
            c(2+naind)=cz(2+iaind)
            c(3+naind)=cz(3+iaind)
            naind=naind+3
         endif
         iaind=iaind+3
      enddo
c
c     'tidy' up the coordinates.
c
      nat3=3*natoms
      do i=1,nat3
         if( dabs(c(i)).le.tenm10)c(i)=dzero
      enddo
      return
c
      end
      subroutine str(noint,i,j,b,ib,c)
c
c        adapted from the normal coordinate analysis program of
c        schachtschneider, shell development .
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension b(3,4,2),ib(4,*),c(*)
      dimension rij(3)
c
      data dzero/0.d0/
c
      iaind = 3*(i-1)
      jaind = 3*(j-1)
      ib(1,noint) = i
      ib(2,noint) = j
      dijsq = dzero
      do 20 m = 1 , 3
         rij(m) = c(m+jaind) - c(m+iaind)
         dijsq = dijsq + rij(m)**2
 20   continue
      do 30 m = 1 , 3
         b(m,1,noint) = -rij(m)/dsqrt(dijsq)
         b(m,2,noint) = -b(m,1,noint)
 30   continue
      return
c
      end
      subroutine strt2( string, length)
c
c     called by:
c     calls to:
c
      implicit REAL  (a-h,o-z)
      character*(*)  string
      character*80 s
      length = len(string)
      l = 0
      s = ' '
      do 20 i = 1 , length
         if (string(i:i).ne.' ') then
            l = l + 1
            s(l:l) = string(i:i)
         end if
 20   continue
      length = l
      string = s
      return
      end
      subroutine subvar(bl,alpha,beta,lbl,lalpha,lbeta,nz,nvar)
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
c
      dimension bl(*),alpha(*),beta(*)
      dimension lbl(*),lalpha(*),lbeta(*)
c
INCLUDE(common/iofile)
INCLUDE(common/csubst)
c
      data done/1.0d0/
c
      if (nvar.eq.0) return
      do 20 i = 1 , nz
         j = i
         if (lbl(i).ne.0) then
            idx = iabs(lbl(i))
            if (idx.gt.nvar) go to 30
            sign = done
            if (lbl(i).lt.0) sign = -done
            bl(i) = sign*values(idx)
         end if
         if (lalpha(i).ne.0) then
            idx = iabs(lalpha(i))
            if (idx.gt.nvar) go to 30
            sign = done
            if (lalpha(i).lt.0) sign = -done
            alpha(i) = sign*values(idx)
         end if
         if (lbeta(i).ne.0) then
            idx = iabs(lbeta(i))
            if (idx.gt.nvar) go to 30
            sign = done
            if (lbeta(i).lt.0) sign = -done
            beta(i) = sign*values(idx)
         end if
 20   continue
      return
 30   write (iwr,6010) idx , j , nvar
      call caserr2('invalid z-matrix specification')
      return
 6010 format (//1x,'variable index of ',i4,' on card ',i3,
     +        ' out of range.  nvar= ',i3)
c
      end
      function sumdst(maxap3,a,b,natoms)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      dimension a(maxap3,3),b(maxap3,3)
      dist = 0.0d0
      do 20 iat = 1 , natoms
         dist = dist + (a(iat,1)-b(iat,1))**2 + (a(iat,2)-b(iat,2))
     +          **2 + (a(iat,3)-b(iat,3))**2
 20   continue
      sumdst = dist
      return
      end
      subroutine surfin
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
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
      common/dfclc2/cscal(mxcalc),iblkp(mxcalc)
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
     &               iresec(mxrest),nrest
c
c labels and titles
c
      common/cplot/zgridt(10,mxgrid),zgrid(mxgrid),
     &             zcalct(10,mxcalc),zcalc(mxcalc),
     &             zplott(10,mxplot),zplot(mxplot)
c the job sequence
      integer stype(mxstp), arg(mxstp)
      common/route/stype,arg,nstep,istep
c
INCLUDE(common/iofile)
INCLUDE(common/work)
      character*80 title
      character *12 caltyp, type1, type2
c
      imof=-1
      ibp=-1
      nvdw=-1
      ivdw=-1
c
c check validity of data field to contour
c
      ig = ngrid
      ic = ncalc
      if(igtype(ig).ne.2)call caserr2(
     +        'data for surf must be on 3D grid')
c
      ictf = ictype(ncalc)
      if(ictf.eq.2)imof=icdata(1,ncalc)
c
      call inpa4(ytest)
      if(ytest.eq.'dens')then
         ict=1
      else if(ytest.eq.'mo  ')then
         ict=2
         call inpi(imo)
      else if(ytest.eq.'atom')then
         ict=3
      else if(ytest.eq.'pote')then
         ict=4
      else if(ytest.eq.'vdw ')then
c van der waals function
         ict=9
      else if(ytest.eq.'lvdw')then
c log of van der waals function
         ict=10
      else
         call caserr2('invalid property for surf')
      endif
      call inpi(isect)
      write(iwr,*)'Dumpfile sections for surf start at',isect
c
c determine gradient type
c
      ograd = .true.
      if(ictf.eq.1)then
         ictg = 5
      else if(ictf.eq.2)then
         ictg = 6
      else if(ictf.eq.9)then
         ictg = 11
      else if(ictf.eq.10)then
         ictg = 12
      else
         write(iwr,*)'No gradient field available for surf'
         ograd = .false.
      endif
      if(ictf.eq.1.or.ictf.eq.2)then
         ibp=iblkp(ncalc)
      else if(ictf.eq.9.or.ictf.eq.10)then
         nvdw=icdata(1,ncalc)
         ivdw=icdata(1,ncalc)
      endif
      nsurf = jump - jrec
c
c check density is restorable
c
      if(nsurf.gt.1.and.icsect(ic).eq.0)call caserr2
     &     ('3D data for surface must be saved to dumpfile')
c
      i = 1
      if(ograd)i = 2
      if(ncalc+i*nsurf.ge.mxcalc)call caserr2
     &     ('too many graphics calculations defined')
      if(ngrid+nsurf.ge.mxgrid)call caserr2
     &     ('too many graphics grids defined')
      if(nrest+nsurf.ge.mxrest)call caserr2
     &     ('too many graphics restores defined')
      if(nstep+(i+2)*nsurf-1.ge.mxstp)call caserr2
     &     ('too many graphics steps defined')
c
      do 100 isurf = 1,nsurf
         call inpf(clev)

         ngrid = ngrid + 1
         nstep = nstep+1
         stype(nstep) = 1
         arg(nstep) = ngrid

         igsect(ngrid)=isect
         isect = isect+1
         igtype(ngrid)=5
         igstat(ngrid)=0
         gdata(1,ngrid) = clev
         type1 = caltyp(ictf,imof)
         write(title,1000)type1,clev
 1000    format('contour grid for ',a12,'=',f8.3)
         call squash(title,80)
         do i = 1,10
            zgridt(i,ngrid) = title((i-1)*8+1:(i-1)*8+8)
         enddo
         write(zgrid(ngrid),'(i8)')ngrid
c
         if(ograd)then
            ncalc = ncalc + 1
            nstep = nstep+1
            stype(nstep) = 2
            arg(nstep) = ncalc
            icsect(ncalc)=isect
            icgrid(ncalc)=ngrid
            iblkp(ncalc)=-1
            isect = isect + 1
            ictype(ncalc)=ictg
            if(imof.ne.-1)icdata(1,ncalc) = imof
            if(ibp.ne.-1)iblkp(ncalc) = ibp
            if(nvdw.ne.-1)icdata(1,ncalc) = nvdw
            if(ivdw.ne.-1)icdata(2,ncalc) = ivdw
            icstat(ncalc)=0
            type1 = caltyp(ictg,imof)
            type2 = caltyp(ictf,imof)
            write(title,1010)type1,type2,clev
            call squash(title,80)
            do i = 1,10
               zcalct(i,ncalc) = title((i-1)*8+1:(i-1)*8+8)
            enddo
            write(zcalc(ncalc),'(i8)')ncalc
            cscal(ncalc)=1.0d0
c grid punch suppressed
            icdata(5,ncalc)=1
         endif

         ncalc = ncalc + 1
         nstep = nstep + 1
         stype(nstep) = 2
         arg(nstep) = ncalc
         icsect(ncalc)=isect
         isect = isect + 1
         ictype(ncalc)=ict
         if(imo.ne.0)icdata(1,ncalc) = imo
         icstat(ncalc)=0
         icgrid(ncalc)=ngrid
         iblkp(ncalc)=-1
         cscal(ncalc)=1.0d0
         if(ict.eq.4)cscal(ncalc)=627.707d0
         type1 = caltyp(ict,imo)
         type2 = caltyp(ictf,imof)
         write(title,1010)type1,type2,clev
 1010    format(a12,'@',a12,'=',f12.6)
         call squash(title,80)
         do i = 1,10
            zcalct(i,ncalc) = title((i-1)*8+1:(i-1)*8+8)
         enddo
         write(zcalc(ncalc),'(i8)')ncalc
         if(isurf.ne.nsurf)then
            nstep = nstep+1
            nrest = nrest+1
            stype(nstep)=5
            arg(nstep)=nrest
            irestu(nrest)=idaf
            irestb(nrest)=ibl3d
            irests(nrest)=icsect(ic)
            iresec(nrest)=0
         endif
 100  continue
      return
      end
      subroutine symass(vectors,energies,electrons,core)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
c  this program recognizes only pure s p d f and g type shells
c  and composite sp shells
c
INCLUDE(common/sizes)
c
      character *8 realc
      integer realn
      parameter(isymtp=99)
      dimension realc(maxorb),realn(maxorb)
      dimension vectors(*),energies(*),electrons(*),core(*)
INCLUDE(common/nshel)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/restri)
INCLUDE(common/fsymas)
c
c...   check if section for symmetry assignment (408)
c...   if not (e.g. noprint in previous job) then not
c
      call sectst(iscsym,ireturn)
      if (ireturn.eq.0) return
c
      nav = lenwrd()
c
      call symas2(ok,realn,realc,vectors,energies,
     +           electrons,core,num,nat,nshell,nav)
c newly included
c     save results of the symmetry assignment into ed3
      isymsc = isect(499)
      call secput(isymsc,isymtp,1+lensec((num-1)/nav+1)
     +                               +lensec(num),iblnum)
      if (ok) then
         iok = 0
      else
         iok = 1
      end if
      call wrt3i(iok,1,iblnum,idaf)
      call wrt3is(realn,num,idaf)
      call wrtcs(realc,num,idaf)
c
c
      return
      end
      subroutine symas2(ok,realn,realc,vectors,energies,
     +           electrons,core,num,nat,nshell,nav)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
INCLUDE(common/harmon)
      parameter(maxireps=20)
      parameter (maxgro=48)
c
      character *8 realc
      integer realn
      dimension realc(*),realn(*),core(*)
      dimension vectors(*),energies(*),electrons(*)
c
      common/junkc/zlabir(maxireps)
      common/junk/ temp(maxorb),ptr(3,3*maxgro),
     +    dtr(6,6*maxgro),ftr(10,10*maxgro),gtr(15,15*maxgro)
      common /bufb/ chars(maxireps*maxireps),iptr(maxorb),
     + iptr2(maxorb),
     + kloc(mxshel),katom(mxshel),ktype(mxshel),
     + iir(maxireps),ipointer(maxireps)
c
c     these arrays are now transferred to dynamic memory
c
c     dimension iat(maxat,maxgro),newsh(mxshel,maxgro)
c     dimension vectors2(maxorb*maxorb),energies2(maxorb),
c    +          electrons2(maxorb)
INCLUDE(common/iofile)
INCLUDE(common/fsymas)
c
c     allocate temporary arrays for symass
c
c     i10 .. vectors2    num*num
c     i20 .. energies2   num
c     i30 .. electrons2  num
c     i40 .. iat         nat*maxgro
c     i50 .. newsh       nshell*maxgro
c     i60 .. smat0       num*(num+1)/2
c     i70 .. smat        num*num
c     i80 .. wmat        num*num
c     i90 .. tmp         num*num
c
      ilen =  num * num                      ! i10
     +      + num                            ! i20
     +      + num                            ! i30
     +      + (nat * maxgro -1)/nav + 1      ! i40
     +      + (nshell * maxgro -1)/nav + 1   ! i50
     +      + num * (num+1)/2                ! i60
     +      + num * num                      ! i70
     +      + num * num                      ! i80
     +      + num * num                      ! i90

      i10 = igmem_alloc(ilen)
      i20 = i10 + num * num
      i30 = i20 + num
      i40 = i30 + num
      i50 = i40 + (nat * maxgro -1)/nav + 1
      i60 = i50 + (nshell * maxgro -1)/nav + 1
      i70 = i60 + num * (num+1)/2
      i80 = i70 + num * num
      i90 = i80 + num * num
      last = i90 + num * num

      length = last - i10
      if(length .ne. ilen)call caserr2('mem size error')
c
      call symrdi(ok,zgroup,naxis,index,ptr,dtr,ftr,gtr,nat,
     +    nshell,nbasf,norder,kloc,katom,ktype,core(i40),core(i50))
c
      if (nbasf.ne.num) call caserr2('basis count error in symass')
      if(index.le.0 .or. index.ge.20)then
        write(iwr,*)' symass: Sorry, unknown group index ',index
        ok=.false.
      endif
      if(index.eq.11 .or. index.eq.12)then
        write(iwr,*)' symass: Sorry, no infinite groups.'
        ok=.false.
      endif
      if(.not.ok) go to 100
c
c     save vectors, if running in gamess!
c
      call symsvq(iscsym,nat,nshell,nbasf,norder,
     +   vectors,energies,electrons)
c
c
      call rdchar(iok,zgroup,naxis,norder,nir,iir,ipointer,
     +             zlabir,chars)
      if(iok.eq.0) then
        write(iwr,*)' symass: Sorry, no information about this group'
        ok=.false.
        go to 100
      endif
c
c energies must be sorted!
c
      call dcopy(nbasf,energies,1,core(i20),1)
      nbsf=newbas0
      call symsrt(nbsf,core(i20),iptr,iptr2)
      osorted=.true.
      do 801,i=1,newbas0
      if(iptr(i).ne.i)osorted=.false.
801   continue
c
      if(osorted) then
      call symana(osubgroup,ok,degecr,
     +     ptr,dtr,ftr,gtr,nshell,nbasf,norder,kloc,ktype,
     +     core(i50),core(i60),core(i70),core(i80),core(i90),
     +     vectors,energies,electrons,realc,
     +     realn,nir,iir,ipointer,zlabir,chars,omydbg,
     +     .false.,.false.,.true.)
      else
c
      write(iwr,*)
      write(iwr,*)
     + ' NOTE: energy levels were not in order, and will be reordered' 
      write(iwr,*)
     + ' before the symmetry assignment. Note that the sorted orbitals'
      write(iwr,*)
     + ' are used only locally in the assignment, so that this'
      write(iwr,*)
     + ' operation has no influence on subsequent calculations.'
      write(iwr,*)
      do 999,i=1,newbas0
      core(i20-1+i)=energies(iptr(i))
999   continue
      if(omydbg) then
       write(iwr,*)' Permutation of energy levels follows:'
       write(iwr,*)' ====================================='
       write(iwr,*)
       write(iwr,*)'     new level  <= old level  (energy)'
       write(iwr,*)
       write(iwr,804) (i,iptr(i),core(i20-1+i),i=1,newbas0)
804    format(10x,i4,'  <=',i4,f16.8)
       write(iwr,*)
      endif
      call symrst(newbas0,nbasf,iptr,electrons,core(i30),
     *            vectors,core(i10))
c
      call symana(osubgroup,ok,degecr,
     +     ptr,dtr,ftr,gtr,nshell,nbasf,norder,kloc,ktype,
     +     core(i50),core(i60),core(i70),core(i80),core(i90),
     +     core(i10),core(i20),core(i30),realc,
     +     realn,nir,iir,ipointer,zlabir,chars,omydbg,.false.,
     +     .false.,.true.)
      endif
c
c
      if(ok)then
        write(iwr,878)
 878    format(1x,'Symmetry assignment was successfull.')
      else
       if(osubgroup)then
        write(iwr,887)
 887   format(/1x,
     + 'WARNING: Symmetry assignment was only partially successfull:'/
     + 1x,'Either:-'/
     + 1x,'(i)   the geometry is very close to a more symmetrical',
     +    ' structure'/ 
     + 1x,'(ii)  the symmetry has been intentionally decreased,'/
     + 1x,'(iii) too high a threshold (degecr) has been used, or '/
     + 1x,'(iv)  random degeneracy may have occured'/)
       else
        write(iwr,886)
 886    format(/
     + 1x,'ERROR: Symmetry assignment was NOT successfull!!!'/
     + 1x,'Maybe you have used too low a threshold (degecr)'/
     + 1x,'or scf results were not ok.'/)
       endif
      endif
c     write(iwr,*)
      write(iwr,888) degecr
c     write(iwr,889) cpulft(1)-time0
888   format(1x,'Degeneracy criterium used was ',e8.3,' a.u.')
c889  format(' CPU time consumed: ',f8.4,' s')
c     write(iwr,*)
c     write(iwr,*)
c
c     reset memory
c
 100  continue
      call gmem_free(i10)
c
      return
      end
      subroutine symsvq(isecs,nat,nshell,num,norder,
     +  vectors,energies,electrons)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
INCLUDE(common/iofile)
c
      dimension vectors(num,num), energies(num), electrons(num)
c
      data m101/101/
c
c ... append vectors etc to symmetry section isecs
c
      nav = lenwrd()
c
      nw1 = 2
      nw2 = (3*nshell+5)/nav+1
      nw3 = (nat*norder-1)/nav+1
      nw4 = (nshell*norder-1)/nav+1
      nw5 = num * num
      nw6 = num
      nw7 = num
c
       len101 = lensec(nw1) + lensec(nw2) + lensec(nw3) + lensec(nw4)
c
       call secget(isecs,m101,iblks)
c
       iblk = iblks + len101
       call wrt3(vectors,nw5,iblk,idaf)
       call wrt3s(energies,nw6,idaf)
       call wrt3s(electrons,nw7,idaf)
c
      return
      end
      subroutine symrst(l0,nbasf,iptr,electrons,electrons2,vectors,
     +  vectors2)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension iptr(nbasf),electrons(nbasf),electrons2(nbasf),
     +          vectors(nbasf,nbasf),vectors2(nbasf,nbasf)
c
      do 802,i=1,l0
802   electrons2(i)=electrons(iptr(i))
      do 803,i=1,l0
c vectors(ao,mo)
      do 803,j=1,nbasf
      vectors2(j,i)=vectors(j,iptr(i))
803   continue
      return
      end
      subroutine symrdi(ok,zgroup,naxis,index,ptr,dtr,ftr,gtr,
     +  nat,nshell,nbasf,norder,kloc,katom,ktype,iat,newsh)
c
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter (maxgro=48)
      parameter(ishthr=100)
      dimension ptr(3,3*maxgro),
     +      dtr(6,6*maxgro),ftr(10,10*maxgro),gtr(15,15*maxgro)
      dimension kloc(mxshel),katom(mxshel),ktype(mxshel),
     +      iat(nat,maxgro),newsh(nshell,maxgro)
INCLUDE(common/iofile)
INCLUDE(common/fsymas)
c
      call getsym (iscsym,zgroup,index,naxis,natom,nshells,
     + nbasf,norder,kloc,katom,ktype,iat,newsh,ptr,dtr,ftr,gtr,
     + nat,nshell)

      owrong=.false.
c     here check ktype
      do 103,i=1,nshell
      if(ktype(i).le.0) then
        owrong=.true.
      else
        if(ktype(i).gt.5 .and. ktype(i).ne.ishthr+1) owrong=.true.
      endif
103   continue
      if(owrong) then
       write(iwr,*) 'error in symass: unknown shell type detected'
       write(iwr,*) 'unknown shell type, run with "noprint symass"'
       ok=.false.
       return
      endif
c
      ok=.true.
      return
      end
      function ishsym(iang)
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      parameter(ishthr=100)
INCLUDE(common/fsymas)
INCLUDE(common/iofile)
c
c   iang==1 ->s 2->p,...
c   combinations with repetition from 3 elements
c   binomial(3+k-1/k)
      if(iang.lt.ishthr) then
      ishsym=iang*(iang+1)/2
      else
c find what type of shell it is
      if(iang.eq.ishthr+1) then
      ishsym=4
      else
      write(iwr,*) 'error in symass: unknown shell type detected',iang
      if(oingam) then
      call caserr2('unknown shell type, run with "noprint symass"')
      else
      stop
      endif
      endif
      endif
      return
      end
      subroutine symana(osubgroup,ok,degecr,
     +  ptr,dtr,ftr,gtr,nshell,nbasf,norder,kloc,ktype,
     +  newsh,smat0,smat,wmat,tmp,
     +  vectors,energies,electrons,realc,realn,nir,iir,
     +  ipointer,zlabir,chars,ofullpri,opall,otest,onew)
c
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      parameter (maxireps=20)
      parameter (maxgro=48)
c
c
c      core orbs can be "degenerate" !
      parameter (epschi=1.0d-2,maxdege=30)
c formal ktype for composed shells
      parameter (ishthr=100)
c     when changed, change also data zireps !
c     full debug option
c
      character *8 realc
      integer realn
      dimension realc(*),realn(*),zlabir(*)
      dimension vectors(nbasf,*),energies(*),electrons(*)
      dimension smat0(*), smat(*), wmat(*), tmp(nbasf,*)
      dimension ptr(3,3*maxgro),
     +   dtr(6,6*maxgro),ftr(10,10*maxgro),gtr(15,15*maxgro),
     +   chars(nir,*)
      dimension kloc(*),ktype(*),
     * newsh(nshell,maxgro),iir(*),ipointer(*)
c
INCLUDE(common/scra7)
INCLUDE(common/harmon)
      common/junk2/ freqirep(maxireps), chi(maxireps), 
     +  gmat(maxdege*maxdege), ginvmat(maxdege*maxdege), 
     +  umat(maxdege*maxdege),ishell(maxorb),
     +  idecomp(maxdege,maxorb),idecpoint(0:maxdege,maxorb),
     +  ircounter(maxireps), iunknowcount(maxdege),
     +  ifreq(maxireps),idegeneracy(maxorb), locgroup(maxorb),
_IF1(c)     +  idum1(maxdege+1)
_IFN1(c)     +  idum1(maxdege+1),idum2(maxdege+1)
INCLUDE(common/iofile)
      dimension zireps(maxdege)
      data zireps/'a?','e?','t?','g?','h? d?','???','f?',
     + '???','???','???','???','???','???','???','???','???',
     + '???','???','???','???','???','???','???','???','???',
     +  '???','???','???','???','???'/
      data ev/27.21165d0/
c
c     read the overlap matrix
c
      if(onew) then
       call rdedx(smat0,nbasf*(nbasf+1)/2,ibl7s,num8)
       call square(smat,smat0,nbasf,nbasf)
c      if(opall) call symmpr('matrix S',smat,nbasf,nbasf,iwr)
c precalculate matrix W=V'S, change to lib call later
c
       call vclr(wmat,1,nbasf*nbasf)
       do i=1,newbas0
        do j=1,nbasf
          do k=1,nbasf
          wmat(i+(j-1)*nbasf)= wmat(i+(j-1)*nbasf)+vectors(k,i)*
     +                         smat(k+(j-1)*nbasf)
          enddo
        enddo
       enddo
c      if(opall) call symmpr('matrix W',wmat,nbasf,nbasf,iwr)
      endif
c     initialization
      do i=1,nir
       ircounter(i)=1
      enddo
      do  i=1,nbasf
       realn(i)=0
       realc(i)='        '
       locgroup(i)=0
      enddo
c     number of energy levels
      igroupcount=0
      do i=1,nshell
      n=kloc(i)
        do j=0,ishsym(ktype(i))-1
         ishell(n+j)=i
        enddo
      enddo
      do j=1,maxdege
       iunknowcount(j)=1
      enddo
      ok=.true.
      osubgroup=.false.
      owasfatal=.false.
c
c  first go through the energy scale and search for degenerate orbitals
c
      if(ofullpri) write(iwr,2903)
c
      i=1
c     here begins the main loop
2002  etemp=energies(i)
      j=0
2001  if (i+j+1.le.newbas0 .and. 
     +                    dabs(energies(i+j+1)-etemp).lt.degecr) then
        j=j+1
        goto 2001
      endif
      idege=j+1
      if(idege.gt.maxdege)then
         write(iwr,885)
 885     format(/
     + ' ERROR - too high degeneracy found, perhaps the degecr is '/
     + ' too high or file with energies was overwriten!'/)
         write(iwr,*)' symass aborted!'
         ok=.false.
         return
      endif
      igroupcount=igroupcount+1
      idegeneracy(igroupcount)=idege
      locgroup(igroupcount)=i
c
c
c      now lets analyze this level of degenerate MOs
c
c     just for test Bnew=V'SV=1 - otherwise can be omitted and relied on B=1
       if(onew) then
       if(otest) then
        do ia=1,nbasf
         do ib=0,idege
          tmp(ia,ib+1)=0.0d0
          do ibeta=1,nbasf
          tmp(ia,ib+1)=tmp(ia,ib+1)+smat(ia+(ibeta-1)*nbasf)*
     +                 vectors(ibeta,i+ib)
          enddo
         enddo
        enddo
        do j=1,idege
         do k=0,idege-1
         gmat(j+k*idege)=0.0d0
          do  ibeta=1,nbasf
          gmat(j+k*idege)=gmat(j+k*idege)+vectors(ibeta,i+j-1)*
     +                    tmp(ibeta,k+1)
          enddo
         enddo
        enddo
       endif
       else
c this matrix must be symmetrical
        do k=0,idege-1
         do j=1,k+1
c                       old          do 2003, j=1,idege
         gmat(j+k*idege)=0.0d0
          do  ibeta=1,nbasf
           gmat(j+k*idege)=gmat(j+k*idege)+vectors(ibeta,i+k)*
     +                     vectors(ibeta,i+j-1)
          enddo
c fill the other triangle
         if(j-1.lt.k) gmat(1+k+(j-1)*idege)=gmat(j+k*idege)
         enddo
        enddo
       endif
c
       if(opall.and.(otest.or.(.not.onew))) 
     +     call symmpr('matrix B',gmat,idege,idege,iwr)
c
c
       if(otest.or.(.not.onew)) then
_IF1()c      calculate inverse matrix using math advantage library
_IF1()       call rmfuin(gmat,idege,idege,1d-12,idum1,ginvmat,idege,ierr)
       call dcopy(idege*idege,gmat,1,ginvmat,1)
_IF1(c)       call minv(ginvmat,idege,idege,idum1,deter,1.0d-20,0,1)
_IFN1(c)       call minvrt(ginvmat,idege,deter,idum1,idum2)
       ierr = 0
       if(dabs(deter).lt.1.0d-7)  ierr = 1
       if(opall) call symmpr
     +   ('inverse of matrix B',ginvmat,idege,idege,iwr)
       if(ierr.ne.0)then
         write(iwr,884)
 884  format(/
     +  ' ERROR in character calculation - singular matrix!'/
     +  ' Maybe the file with vectors was overwritten or scf'/
     +  ' did not converge.')
         write(iwr,*)' symass aborted!'
         ok=.false.
         return
       endif
       endif
c
c   now compute characters for all classes of equivalent group elements
c
      do 2004, j=1,nir
      it=ipointer(j)
c     first form transf matrix
c
      do 2006, l=0,idege-1
      do 2006, k=1,idege
      gmat(k+l*idege)=0.0d0
c this two were loops for each element, the following are for matrix
c multiplication
c the first is over all basis functions, the second
c uses the fact that one symmetry operation transforms one shell only
c on linear comb. from shell located in one atom and therefore
c the summation goes only over size of the shell
c
      do 2006, n=1,nbasf
c
c
      m=newsh(ishell(n),it)
      ml=kloc(m)
      n0=1+n-kloc(ishell(n))
      kt= ktype(m)
c is executed idege**2 *nbasf times
      is=ishsym(kt)
      do 2006, m0= 1,is
      m=ml+m0-1
c simple spdfg shells
      if(kt.eq.1) dd=1d0
      if(kt.eq.2) dd=ptr(m0,n0+is*(it-1))
      if(kt.eq.3) dd=dtr(m0,n0+is*(it-1))
      if(kt.eq.4) dd=ftr(m0,n0+is*(it-1))
      if(kt.eq.5) dd=gtr(m0,n0+is*(it-1))
c composed sp shell
      if(kt.eq.ishthr+1) then
      if(m0.eq.1) then
        if(n0.eq.1) then
        dd=1d0
        else
        dd=0.0d0
        endif
      else
c       p and something        
        if(n0.eq.1) then
        dd=0.0d0
        else
        dd=ptr(m0-1,n0-1+3*(it-1))
        endif
      endif
      endif
c
c
c calculates G= C'D(R)C matrix, element of D(R) is dd
c
c new method is Gnew=C'SD(R)C a Bnew=1
c then U=G and some multiplications are saved
c
      if(onew) then
       gmat(k+l*idege)=gmat(k+l*idege)+ dd*wmat(i+k-1+(n-1)*nbasf)*
     +                 vectors(m,i+l)
      else
       gmat(k+l*idege)=gmat(k+l*idege)+ dd*vectors(n,i+k-1)*
     +                 vectors(m,i+l)
      endif
c
c vectors(ao,mo)
c
c
2006  continue
c
       if(opall) then
       write(iwr,*)
       write(iwr,*) 'operation no. ', j
       write(iwr,*) 
       call symmpr('matrix G',gmat,idege,idege,iwr)
       endif
c
c     calc umat
c
      if(.not.onew) then
_IF1()c     matrix multiplication from math. advantage library
_IF1()      call rmmul(ginvmat,gmat,umat,idege,idege,idege)
      call mxm(ginvmat,idege,gmat,idege,umat,idege)
      if(opall) call symmpr('matrix U',umat,idege,idege,iwr)
c
c
c     now calc. trace of umat (in fact we don't need the whole U, but
c     all this stuff takes negligible time, so that we called
c     full multiplication routine)
c
      endif
c
      chi(j)=0.0d0
      if(onew) then
        do  k=1,idege
        chi(j)=chi(j)+gmat(k+(k-1)*idege)
        enddo
      else
        do 2005, k=1,idege
2005    chi(j)=chi(j)+umat(k+(k-1)*idege)
      endif
2004  continue
c     end of loop for classes of group
c
c     use characters to determine irrep using the usual formula
c
      if(ofullpri) 
     +     write(iwr,2902)i,i+idege-1,(chi(j),j=1,nir)
2902  format(' MO ',i3,' -',i3,5x,24f7.3)
2903  format(//1x,55('=')/
     + ' Calculated characters of MOs and their decompositions:'
     + /1x,55('=')/)
c
c
c     check if idege corresponds with the char. of identity
c     i am not sure how it will behave in the case of groups with 
c     complex chars!
      if(dabs(chi(1)-idege).gt.epschi) then
        write(iwr,883)
 883    format(/' ERROR in symass:'/
     +          ' character of identity is not equal to degeneracy!!!')
        ok=.false.
        owasfatal=.true.
      endif
c
c
      idecpoint(0,igroupcount)=0
      ofatal=.false.
c    calculate for all irreps
      do 2007,j=1,nir
      freqirep(j)=0.0d0
c   sum over classes of conj. elements
      do 2008,k=1,nir
2008  freqirep(j)= freqirep(j)+ chi(k)*iir(k)*chars(k,j)
      freqirep(j) = freqirep(j)/norder
c
      f=dnint(freqirep(j))
      ifreq(j)=nint(freqirep(j))
      if((dabs(f-freqirep(j)).gt.epschi).or.(freqirep(j).le.-epschi)) 
     +  ofatal=.true.
      if(ifreq(j).gt.0) then
        do 2100, k=1,ifreq(j)
        idecpoint(idecpoint(0,igroupcount)+k,igroupcount)=j
2100    continue
        idecpoint(0,igroupcount)= idecpoint(0,igroupcount)+ifreq(j)
      endif
2007  continue
c     end of loop for ireps
      if(idecpoint(0,igroupcount).le.0) ofatal=.true.
      if(idecpoint(0,igroupcount).gt.1) osubgroup=.true.
      if(osubgroup) ok=.false.
      if(ofullpri) write(iwr,2920)(freqirep(j), zlabir(j),j=1,nir)
2920  format('   decomposition:',24(f5.2,1x,a4))
      if(ofatal) then
        ok=.false.
        owasfatal=.true.
        if(ofullpri) then
           write(iwr,882)
 882       format(/
     +    ' Serious error during decomposition of this representation!')
        else
           return
        endif
      endif
      if(ofullpri.or.owasfatal)write(iwr,*)
c
c     find name of that irrep and increment counter of orbitals 
c     of this sym.
c
      if(.not.ofatal) then
        if(idecpoint(0,igroupcount).eq.1) then
         irfound=idecpoint(1,igroupcount)
         do j=i,i+idege-1
          realn(j)=ircounter(irfound)
          realc(j)=zlabir(irfound)
         enddo
         idecomp(1,igroupcount)=ircounter(irfound)
         ircounter(irfound)=ircounter(irfound)+1
        else
c            case of subgroup
         do k=1,idecpoint(0,igroupcount)
          j=idecpoint(k,igroupcount)
          idecomp(k,igroupcount)=ircounter(j)
          ircounter(j)=ircounter(j)+1
         enddo
         do j=i,i+idege-1
          realn(j)=iunknowcount(idege)
          realc(j)=zireps(idege)
         enddo
        iunknowcount(idege)=iunknowcount(idege)+1
        endif
      endif
c
c
c---------------------------------------------------------------------
c     end of i loop over energy levels
      i=i+idege
      if(i.le.newbas0) goto 2002
c---------------------------------------------------------------------
      if(ofullpri.or.owasfatal) write(iwr,2017)
2017  format(1x,79('=')/)
c
c     analyze problems
c
      if(owasfatal) then
        ok=.false.
        osubgroup=.false.
       endif
c
c     write results
c
      if(osubgroup) then
      write(iwr,2941)
      do i=1,igroupcount
      li=locgroup(i)
      id=idegeneracy(i)
      ele=0.0d0
       do j=0,id-1
        ele=ele+ electrons(li+j)
       enddo
      energev = energies(li) * ev
      write(iwr,2931) i,li,li+id-1,realn(li),realc(li),
     +   energies(li),energev,id,ele,(idecomp(k,i),
     +   zlabir(idecpoint(k,i)),
     +   k=1,idecpoint(0,i))
      enddo
c
2931  format(i5,4x,i3,' -',i3,4x,i3,1x,a6,f16.8,f16.4,
     +       6x,i2,7x,f12.6,4x,
     +       8(i3,1x,a4))
c
2941  format(/1x,115('=')/31x,'SYMMETRY ASSIGNMENT'/1x,115('=')/
     *' E level    m.o.     symmetry           orbital',
     +'         orbital  degeneracy  occupancy       decomposition'/
     *'                                  energy (a.u.)',
     +'    energy (e.v)'/ 1x,115('='))
c
      write(iwr,2942)
2942  format(1x,115('=')//)
      else
      write(iwr,2911)
      do i=1,igroupcount
      li=locgroup(i)
      id=idegeneracy(i)
      ele=0.0d0
       do j=0,id-1
        ele=ele+ electrons(li+j)
       enddo
      energev = energies(li) * ev
      write(iwr,2901) i,li,li+id-1,realn(li),realc(li),
     +                   energies(li),energev,id,ele
      enddo
c
2901  format(i5,4x,i3,' -',i3,4x,i3,1x,a6,f16.8,f16.4,
     +       6x,i2,4x,f12.6)
c
2911  format(/1x,86('=')/31x,'SYMMETRY ASSIGNMENT'/1x,86('=')/
     *' E level    m.o.     symmetry           orbital',
     +'         orbital  degeneracy  occupancy'/
     *'                                  energy (a.u.)',
     +'    energy (e.v)'/ 1x,86('='))
c
      write(iwr,2912)
2912  format(1x,86('=')/)
      endif
c

      write(iwr,2951)(ircounter(j)-1,zlabir(j),j=1,nir)
2951  format(1x,75('-')/15x,
     + 'Number of orbitals belonging to irreps of this group'/
     + 1x,75('-')/1x,30(i3,1x,a5))
      write(iwr,2952)
2952  format(1x,75('-')/)
c
c
      return
      end
      subroutine symmpr(tit,ma,ii,jj,iwr)
      integer ii,jj,i,j
      REAL ma
      dimension ma(jj,ii)
      character tit*(*)
      write(iwr,*)
      write(iwr,*) tit
      write(iwr,*)
      do i=1,ii
      write(iwr,10)(ma(j,i),j=1,jj)
      enddo
10    format(30f12.7)
      return
      end
      subroutine symsrt(newbas,e,ipt,iipt)
      implicit REAL (a-h,o-z), integer (i-n)
      dimension e(newbas),ipt(newbas),iipt(newbas)
c
      do 11 i=1,newbas
   11 iipt(i)=i/2
c... binary sort of e.values to increasing value sequence
      ipt(1)=1
      do 19 j=2,newbas
      ia=1
      ib=j-1
      test=e(j)
   53 irm1=ib-ia
      if(irm1)58,50,51
   51 ibp=ia+iipt(irm1)
      if(test.lt.e(ipt(ibp)))goto 52
c...  insert into high half
      ia=ibp+1
      goto 53
c... insert into low half
   52 jj=ib
      do 54 i=ibp,ib
      ipt(jj+1)=ipt(jj)
   54 jj=jj-1
      ib=ibp-1
      goto 53
c...  end point of search
   50 jj=ipt(ia)
      if(test.ge.e(jj))goto 57
      ipt(ia+1)=jj
   58 ipt(ia)=j
      goto 19
   57  ipt(ia+1)=j
   19  continue
      return
      end
      subroutine putsym(isecs,nat,nshell,num,norder,
     +  kloc,katom,ktype,ict,newsh,natmax,nshmax)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
INCLUDE(common/runlab)
INCLUDE(common/molsym)
INCLUDE(common/iofile)
      common/blkin/iput(3*mxshel+6),jput(1022)
c
      dimension kloc(*),katom(*),ktype(*),ict(natmax,*),
     +          newsh(nshmax,*)
c
      data m101,m511/101,511/
c
c ... output symmetry information to section isecs
c
      nav = lenwrd()
c
      nw1 = 2
      nw2 = (3*nshell+5)/nav+1
      nw3 = (nat*norder-1)/nav+1
      nw4 = (nshell*norder-1)/nav+1
      nw5 = num * num
      nw6 = num
      nw7 = num
c
       len101 = lensec(nw1) + lensec(nw2) + lensec(nw3) + lensec(nw4)
     +                      + lensec(nw5) + lensec(nw6) + lensec(nw7)
c
       call secput(isecs,m101,len101,iblks)
c
       call wrtc(zsymm,nw1,iblks,idaf)
c
      iput(1) = indmx
      iput(2) = jaxis
      iput(3) = nat
      iput(4) = nshell
      iput(5) = num
      iput(6) = norder
      i6 = 6
      do 10 i = 1,nshell
       iput(i6+1) = kloc(i)
       iput(i6+2) = katom(i)
       iput(i6+3) = ktype(i)
       i6 = i6 + 3
 10   continue
       call wrt3s(iput,nw2,idaf)
c
      i6 = 0
      nbuff = m511 * nav
      do 20 i = 1,norder
      do 20 j = 1,nat
       i6 = i6 + 1
       jput(i6) = ict(j,i)
       if(i6.ge.nbuff) then
        call wrt3s(jput,m511,idaf)
        i6 = 0
       endif
 20   continue
      if(i6.gt.0) call wrt3s(jput,m511,idaf)
c
      i6 = 0
      do 30 i = 1,norder
      do 30 j = 1,nshell
       i6 = i6 + 1
       jput(i6) = newsh(j,i)
       if(i6.ge.nbuff) then
        call wrt3s(jput,m511,idaf)
        i6 = 0
       endif
 30   continue
      if(i6.gt.0) call wrt3s(jput,m511,idaf)
c
      return
      end
      subroutine getsym(isecs,zgroup,index,naxis,natom,
     +  nshells,nbasf,norder,
     +  kloc,katom,ktype,iat,newsh,ptr,dtr,ftr,gtr,nat,
     +  nshell)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
INCLUDE(common/iofile)
      common/blkin/iget(3*mxshel+6),jget(1022)
INCLUDE(common/symtry)
INCLUDE(common/restrl)
c
      dimension kloc(*),katom(*),ktype(*),iat(nat,*),
     +          newsh(nshell,*),zsymm(2),ptr(3,*),dtr(6,*),
     +          ftr(10,*),gtr(15,*)
c
      data m101,m511/101,511/
c
c ... retrieve symmetry information from section isecs
c
      nav = lenwrd()
      nbuff = m511 * nav
c
      nw1 = 2
      nw2 = (3*nshell+5)/nav+1
c
      call secget(isecs,m101,iblks)
c
      call rdchr(zsymm,nw1,iblks,idaf)
      zgroup = zsymm(2)
c
      call readis(iget,nw2*nav,idaf)
      index = iget(1) 
      naxis = iget(2) 
      natom = iget(3)
      nshells = iget(4) 
      nbasf = iget(5) 
      norder = iget(6) 
      i6 = 6
      do 10 i = 1,nshell
       kloc(i) = iget(i6+1)
       katom(i) = iget(i6+2) 
       ktype(i) = iget(i6+3)
       i6 = i6 + 3
 10   continue
c
      call readis(jget,nbuff,idaf)
      i6 = 0
      do 20 i = 1,norder
      do 20 j = 1,nat
       i6 = i6 + 1
       iat(j,i) = jget(i6) 
       if(i6.ge.nbuff) then
        call readis(jget,nbuff,idaf)
        i6 = 0
       endif
 20   continue
c
      i6 = 0
      call readis(jget,nbuff,idaf)
      do 30 i = 1,norder
      do 30 j = 1,nshell
       i6 = i6 + 1
       newsh(j,i) = jget(i6)
       if(i6.ge.nbuff) then
        call readis(jget,nbuff,idaf)
        i6 = 0
       endif
 30   continue
c
c   now read in transformation matrices for s,p,d,f,g basis functions.
c
      call rdedx(ptr,nw196(1),ibl196(1),idaf)
      if (odbas) call rdedx(dtr,nw196(2),ibl196(2),idaf)
      if (ofbas) call rdedx(ftr,nw196(3),ibl196(3),idaf)
      if (ogbas) call rdedx(gtr,nw196(4),ibl196(4),idaf)
c
      return
      end
      subroutine symm(ioutp,core)
c
c     this is the main driver for the symmetry package.
c
c     given the coordinates and atomic numbers (or any other
c     identifying feature such as atomic weights) this package
c     determines:
c        1--  the molecule's point group.
c        2--  the standard orientation of the molecule in cartesian
c             space.
c        3--  the molecule's framework group.
c        4--  a permutation list over atoms.
c        5--  the 3x3 rotation matrices for the operations of the group.
c
c     ian is used to determine the atomic symbols which are placed
c     in the stoichimetry and framework group strings.  the floating
c     point array, atmchg, which normally contains atomic numbers
c     but in some applications may contain massed, is used for
c     determining the point group and orienting the molecule.
c
c     the many routines are in alphabetical order in the source file
c     except for the mainline routines symm, ptgrp, oper, fwgrp, and
c     omega which appear at the beginning.  below is given a brief
c     description of the subroutines included.  routines are grouped
c     together according to the mainline routine with which they're
c     associated.  general utility routines are described with symm.
c
c
c     symm  ...  the main driver routine.  initialization is done here
c                and the mainline routines ptgrp, oper, fwgrp and omega
c                are called.
c
c        invert  ...  inverts the molecule through the origin and return
c                     the transformation matrix.
c        movez   ...  transfers coordinates from one array to another.
c        num     ...  does numeric to hollereith conversion.
c        numer   ...  form a number from the hollerith digits in ngrp.
c        print   ...  debug coordinate printing.
c        put     ...  rotate the molecule so as to put an arbitrary give
c                     point on one of the cartesian axes.
c        reflect ...  relects the molecule through one of the three
c                     cartesian planes and returns the transformation
c                     matrix.
c        rotate  ...  rotates the molecule through a given angle about
c                     one of the cartesian axes and returns the
c                     transformation matrix.
c        tform   ...  transform the coordinates given the 3x3
c                     transformation matrix.
c
c     ptgrp ...  determines the point group of the molecule and imposes
c                a standard orientation in cartesian space.
c
c        center  ...  determine the coordinates of the center of charge.
c        cirset  ...  search for circular sets of atoms.
c        equiv   ...  test two sets of coordinates for equivalence.
c        findc2  ...  search for a set of c2 axes perpindicular to the
c                     principal symmetry axis.
c        findcn  ...  determine the order of the principal rotation axis
c                     in a symmetric top molecule.
c        findv   ...  search for a vertical mirror plane.
c        or3mom  ...  calculate the third moment of charge.
c        oraxis  ...  fix the alignment of a smmetry axis with a
c                     cartesian axis.
c        orc2v   ...  orient planar c2v molecules.
c        orcn    ...  orient cs, cn, cnh, sn, and i molecules.
c        ord2h   ...  orient planar d2h molecules.
c        ordn    ...  orient dn, dnd, dnh, cnv, t, td, th, o, and oh
c                     molecules.
c        ordoc   ...  a dummy routine outlining the orientation
c                     conventions.
c        orkey   ...  determine the key atom in a symmetric top.
c        ornax   ...  determine which cartesian axis passes through the
c                     greatest number of atoms or bonds.
c        orplan  ...  orient the molecule in a cartesian plane.
c        orptst  ...  determine if a molecule is contained in a cartesia
c                     plane and which one if it is.
c        oryz    ...  put a planar molecule in the yz plane and orient
c                     it.
c        secmom  ...  calculate the principal second moments and axes of
c                     charge.
c        sphere  ...  determine if a spherical top molecule is
c                     tetrahedral, octahedral, or icosahedral and do som
c                     preliminary orientation.
c        sphset  ...  search for spherical sets of atoms.
c        triang  ...  given three atoms, detrmine the sides and angles
c                     of the triangle that they form.
c        tstc3   ...  do three given atoms define a c3 rotation axis?
c        tstc4   ...  do three given atoms define a c4 rotation axis?
c        tstc5   ...  do three given atoms define a c5 rotation axis?
c
c
c     omega ... edit and output the symmetry information, transform
c               the coordinates, monitor the nosym flag
c               in ilsw and the point group during optimizations.
c
c        noones  ...  removes the ones in stoichiometric formulas
c                     for printing, e.g. c1h4 ==> ch4.
c        fixrep  ...  in the case that omega decides to to rotate the
c                     coordinates to the standard orientation, this
c                     routine is called to back-transform the
c                     symmetry operations stored in /repcom/ by
c                     "filrep".
c        mul3x3  ...  a routine to do a 3x3 matrix multiplication.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      common/atmol3o/osim1,osim2
INCLUDE(common/prints)
INCLUDE(common/tol)
INCLUDE(common/runlab)
INCLUDE(common/phycon)
INCLUDE(common/infoa)
INCLUDE(common/infob)
INCLUDE(common/molsym)
INCLUDE(common/atmol3)
INCLUDE(common/zorac)
_IF(drf)
INCLUDE(../drf/comdrf/trnsf)
_ENDIF
      common/junk/cscr(maxat,3),cscr1(maxat3,3),cscr2(maxat3,3)
c
      dimension zgrp(19),groupc(171),zgrpt(19)
_IF(drf)
      dimension temp(3)
_ELSE
      dimension trvec(3),temp(3)
_ENDIF
      dimension core(*)
c
c  old transformation matrix to be used
c
      common/oldtr/trold(3,3),trano(3),igpold,naxold,osetor
c
c
c     maxap3 ...  three plus the number of atoms that the program is
c                 dimesnioned for.
c
c
c     to change the number of atoms that this program is dimensioned for
c     to max:
c       change maxap3 to max+3
c       dimension c(max,3)
c       dimension                cscr1(maxap3,3),cscr2(maxap3)
c
      character*7 fnm
      character*4 snm
      data fnm,snm/"input.m","symm"/
      data zanorm/'normal'/
      data zgrpt/
     *' ',' ',17*'parallel'/
      data groupc/
     *9*0.0d0,9*0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0,
     *5*0.0d0,1.0d0,0.0d0,1.0d0,0.0d0/
      data zgrp/
     *'c1','cs','ci','cn','s2n','cnh',
     *'cnv','dn','dnh','dnd','cinfv','dinfh','t',
     *'th','td','o','oh','i','ih'/
c
c     check for user set nosym.
c     check for spin-orbit as well, requiring nosym - XJ
      if (oso.and.nosymm.ne.1) call caserr('Spin-orbit requires nosym')
      if (nosymm.ne.0 .and. ioutp.ne.0) write (ioutp,6030)
c
c
c     initialize ngrp, toler, and tol.  toler is a constant which is the
c     smallest distance in angstroms which will be considered finite.
c     toler2 is a constant which is used for comparing non-coordinate
c     quantities for zero (such as the difference between principal
c     moments of charge) and as a cutoff for the values of cartesian
c     coordinates in omega (if c(iat,ixyz) .lt. tol then c(iat,ixyz)
c     = zero).
c
c iprint in this routines is made by ipri symm
c symm directive should work with exception of change of
c group type and naxis, which is overwritten by ptgrp2
c it could be useful - if there is mistake in symmetry points, it can be
c repaired without having to recompile all the routines
c
c
      naxis = 0
      maxap3 = maxat3
      do 30 i = 1 , 3
         do 20 j = 1 , 3
            tr(j,i) = 0.0d0
 20      continue
 30   continue
      tr(1,1) = 1.0d0
      tr(2,2) = 1.0d0
      tr(3,3) = 1.0d0
      trx = 0.0d0
      try = 0.0d0
      trz = 0.0d0
c
c     copy the input vector of cartesian coordinates to the internal
c     array.
c
      call dcopy(nat,symz,1,czann,1)
c
      do 50 i = 1 , nat
         do 40 j = 1 , 3
            cscr(i,j) = c(j,i)
 40      continue
 50   continue

      if (nat.gt.1) then
c
c  set up the symz array, to incoporate modifications for
c  inequivalent centres with the same charge but different 
c  labels.
c
         i10 = igmem_alloc_inf(nat,fnm,snm,"i10",IGMEM_DEBUG)
         i20 = igmem_alloc_inf(nat,fnm,snm,"i20",IGMEM_DEBUG)
c         
         call setsym(imass,zaname,czann,symz,nat,core(i10),core(i20))
c
         call gmem_free_inf(i20,fnm,snm,"i20")
         call gmem_free_inf(i10,fnm,snm,"i10")
c
c     determine the point group and standard orientation.
c     the new coordinates are returned in cnew,
c     and the translation vector in trvec.  the final rotation 
c     matrix is the last three "atoms" in cnew.
c
         if (nosymm.eq.0) then
c
            iprint = 0
c           if (oprint(48) .and. nprint.ne.-5) iprint = 1
c           oprint(48) = .false.
************
            if (oprint(48) ) iprint = 1
************
c
            call ptgrp2(maxap3,cnew,symz,nat,iprint,iprint,
     +                  igroup,naxis,trvec,nosymm,core)
c
c ---- igrp80 is used for vibrational thermochemistry
c ---- if cinfv or dinfh then set c2v / d2h for games
c ---- symmetry routines
c
            igrp80 = igroup
            if (igrp80.eq.11) igroup = 7
            if (igrp80.eq.12) igroup = 9 
            if (igrp80.eq.19) then
c     
               igroup = 10
               naxis = 5
            end if
            do 100 i = 1 , 3
               do 90 j = 1 , 3
                  tr(j,i) = cnew(nat+i,j)
 90            continue
 100        continue
            trx = trvec(1)
            try = trvec(2)
            trz = trvec(3)
            if(osetor)then
c
c  impose a pre-determined orientation matrix
c
               write(ioutp,*)'symm - using predefined orientation'
               if(igroup.ne.igpold.or.naxold.ne.naxis)then
                  write(ioutp,6015)
     &                zgrp(igpold),naxold,zgrp(igroup),naxis
                  call caserr2
     &                ('point gp must match that on orient directive')
               endif
               trx = trano(1)
               try = trano(2)
               trz = trano(3)
               call dcopy(9,trold,1,tr,1)
               do 108 i = 1 , nat
                  do 102 j = 1 , 3
                     temp(j) = cscr(i,j) + trano(j)
 102              continue
                  do 106 j = 1 , 3
                     cnew(i,j)=0.0d0
                     do 104 k = 1 , 3
                        cnew(i,j) = cnew(i,j) + temp(k)*tr(j,k)
 104                 continue
 106              continue
 108           continue
            endif
         endif
      end if
_IF(drf)
caleko 
c
            do 1000 i = 1 , 3
               do 900 j = 1 , 3
                  trmatr(j,i) = tr(j,i)
 900            continue
 1000        continue
c
caleko
_ENDIF
      if(nat.eq.1.or.nosymm.eq.1)then
         if (nat.eq.1.and.ioutp.ne.0) write (ioutp,6020)
c
c     copy the cartesian coordinates to the g80 array in nosym mode
c
         igroup = 1
         nosymm = 1
         do 130 i = 1 , nat
            do 120 j = 1 , 3
               cnew(i,j) = cscr(i,j)
 120        continue
 130     continue
c
c  set a unit matrix for the transformation
c
         do 150 i = 1 , 3
            do 140 j = 1 , 3
               tr(j,i) = 0.0d0
 140        continue
            tr(i,i) = 1.0d0
 150     continue
         trx = 0.0d0
         try = 0.0d0
         trz = 0.0d0
      endif
c
c ---- punch out transformation info if required
c
      call blktra(tr,trx,try,trz,igroup,naxis)
c
c ----- now setup all distinct centres for games
c
c      don't overwrite symmetry parameters from input
c
c
      zgroup = zgrp(igroup)
      jaxis = naxis
      ii = (igroup-1)*9
      if(.not.osim1) then
         do 180 i=1,6
         symtag(i) = groupc(ii+i)
 180     continue
      endif
      if(.not.osim2) then
         do 190 i=7,9
         symtag(i) = groupc(ii+i)
 190     continue
         zsymm = zgrpt(igroup)
      endif
c
      if (igroup.eq.10.and.(.not.osim2)) then
         if (mod(jaxis,2).ne.0) then
            zsymm = zanorm
         else
c ... special d4d, d6d and d8d was not tested, maybe 
c     will require pi/12 and pi/16
           if(jaxis.eq.4) then
c                  cos and sin pi/8
            symtag(7)=0.9238795325113d0
            symtag(8)=0.3826834323651d0
           else
            symtag(7) = 1.0d0
           endif
         end if
      end if
c
      nonsym = 0
      do 160 i = 1 , nat
         symz(i) = czann(i)
         if (imass(i).ge.1000) imass(i) = imass(i) - 1000
 160  continue
      do 170 i = 1 , nat
         nonsym = nonsym + 1
c
c-weights
c no longer store default masses here
c         amass(nonsym) = 0.0d0
         ztag(nonsym) = zaname(i)
         cat(1,nonsym) = cnew(i,1)
         cat(2,nonsym) = cnew(i,2)
         cat(3,nonsym) = cnew(i,3)
         czann(nonsym) = czan(i)
c        ia = idint(czan(i)+0.001d0)

c-weights end
c         if (ia.gt.0 .and. ia.lt.55) amass(nonsym) = ams(ia)

 170  continue
      return
c
 6015 format (1x,'symm-- point group from orient directive ',a8,
     +     ', old order of axis',i3,/,8x,
     +     'new point group ',a8,', new order of axis',i3)
 6020 format (1x,'symm--  symmetry turned off for atomic calculation')
 6030 format (1x,'symm--  symmetry turned off by external request'//)
c
      end
      subroutine symtab(iso,nshels,ict,natoms)
      implicit REAL (a-h,o-z)
INCLUDE(common/sizes)
INCLUDE(common/nshel)
INCLUDE(common/infoa)
INCLUDE(common/symtry)
INCLUDE(common/iofile)
      common/junk/ptr(3,144)
c
INCLUDE(common/common)
c
      dimension iso(nshels,*),ict(natoms,*)
      dimension indica(maxat)
      if (nt.eq.1) return
      call rdedx(ptr,nw196(1),ibl196(1),idaf)
      nav = lenwrd()
      call readi(iso,nw196(5)*nav,ibl196(5),idaf)
c
c     ----- set transformation table: atoms versus symmetry operations.
c
      do 70 ii = 1 , nshell
         ic = katom(ii)
         do 60 it = 1 , nt
            id = iso(ii,it)
            ict(ic,it) = katom(id)
 60      continue
 70   continue
 
      write(iwr,80)(i,i=1,nat)
 80   format(/'TRANSFORMATION TABLE (rows = symmetry operations,',
     ?        ' columns = atoms)'//5x,100i5)
      write(iwr,90)
90    format(50('-'))
      do 120 j=1,nt
      write(iwr,100)j,(ict(i,j),i=1,nat)
100   format(i2,' | ',100i5)
120   continue
c
      do 200 iat = 1 , nat
         indica(iat) = 1
200   continue
      do 220 iat = 1 , nat
         if (indica(iat) .eq. 1) then
            do 210 it = 2 , nt
               if (ict(iat,it) .gt. iat) indica(ict(iat,it)) = 0
210         continue
         end if
220   continue
      write (iwr,230)
230   format (/'LIST OF SYMMETRY UNIQUE ATOMS:'/)
      do 250 iat = 1 , nat
         if (indica(iat) .eq. 1) then
            write (iwr,240) iat
240         format ('Atom ',i4)
         end if
250   continue
      return
      end
      subroutine tform(maxap3,t,a,b,n)
c
c     t is the 3x3 transformation matrix which is used to transform
c     the n coordinates in a to those in b.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension t(3,*), a(maxap3,3), b(maxap3,3)
c
      do 20 iat = 1 , n
         b(iat,1) = t(1,1)*a(iat,1) + t(1,2)*a(iat,2) + t(1,3)*a(iat,3)
         b(iat,2) = t(2,1)*a(iat,1) + t(2,2)*a(iat,2) + t(2,3)*a(iat,3)
         b(iat,3) = t(3,1)*a(iat,1) + t(3,2)*a(iat,2) + t(3,3)*a(iat,3)
 20   continue
      return
      end
_IF(drf)
      subroutine tform2(t,a,b)
c
c     t is the 3x3 transformation matrix which is used to transform
c     the coordinates in a to those in b.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension t(3,3), a(3), b(3)
c
         b(1) = t(1,1)*a(1) + t(1,2)*a(2) + t(1,3)*a(3)
         b(2) = t(2,1)*a(1) + t(2,2)*a(2) + t(2,3)*a(3)
         b(3) = t(3,1)*a(1) + t(3,2)*a(2) + t(3,3)*a(3)
      return
      end
_ENDIF
      subroutine tors(noint,i,j,k,l,b,ib,c)
c
c        adapted from the normal coordinate analysis program of
c        schachtschneider, shell development .
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension b(3,4,*),ib(4,*),c(*)
      dimension rij(3),rjk(3),rkl(3),eij(3),ejk(3),ekl(3),cr1(3),cr2(3)
c
      data dzero/0.d0/,done/1.d0/
c
      iaind = 3*(i-1)
      jaind = 3*(j-1)
      kaind = 3*(k-1)
      laind = 3*(l-1)
      ib(1,noint) = i
      ib(2,noint) = j
      ib(3,noint) = k
      ib(4,noint) = l
      dijsq = dzero
      djksq = dzero
      dklsq = dzero
      do 20 m = 1 , 3
         rij(m) = c(m+jaind) - c(m+iaind)
         dijsq = dijsq + rij(m)**2
         rjk(m) = c(m+kaind) - c(m+jaind)
         djksq = djksq + rjk(m)**2
         rkl(m) = c(m+laind) - c(m+kaind)
         dklsq = dklsq + rkl(m)**2
 20   continue
      dij = dsqrt(dijsq)
      djk = dsqrt(djksq)
      dkl = dsqrt(dklsq)
      do 30 m = 1 , 3
         eij(m) = rij(m)/dij
         ejk(m) = rjk(m)/djk
         ekl(m) = rkl(m)/dkl
 30   continue
      cr1(1) = eij(2)*ejk(3) - eij(3)*ejk(2)
      cr1(2) = eij(3)*ejk(1) - eij(1)*ejk(3)
      cr1(3) = eij(1)*ejk(2) - eij(2)*ejk(1)
      cr2(1) = ejk(2)*ekl(3) - ejk(3)*ekl(2)
      cr2(2) = ejk(3)*ekl(1) - ejk(1)*ekl(3)
      cr2(3) = ejk(1)*ekl(2) - ejk(2)*ekl(1)
      dotpj = -(eij(1)*ejk(1)+eij(2)*ejk(2)+eij(3)*ejk(3))
      dotpk = -(ejk(1)*ekl(1)+ejk(2)*ekl(2)+ejk(3)*ekl(3))
      sinpj = dsqrt(done-dotpj**2)
      sinpk = dsqrt(done-dotpk**2)
      do 40 m = 1 , 3
         smi = 0.0d0
         if (sinpj.gt.1.0d-20) smi = -cr1(m)/(dij*sinpj*sinpj)
         b(m,1,noint) = smi
         f1 = 0.0d0
         f2 = 0.0d0
         if (sinpj.gt.1.0d-20) f1 = (cr1(m)*(djk-dij*dotpj))
     +                              /(djk*dij*sinpj*sinpj)
         if (sinpk.gt.1.0d-20) f2 = (dotpk*cr2(m))/(djk*sinpk*sinpk)
         smj = f1 - f2
         b(m,2,noint) = smj
         sml = 0.0d0
         if (sinpk.gt.1.0d-20) sml = cr2(m)/(dkl*sinpk*sinpk)
         b(m,4,noint) = sml
         b(m,3,noint) = (-smi-smj-sml)
 40   continue
      return
c
      end
      subroutine tranatm(x,y,z,tr)
c
      implicit REAL (a-h,p-z),integer (i-n),logical    (o)
c
      dimension tr(3,4), c(3)


      do 1 i=1,3
	c(i) = tr(i,1)*x + tr(i,2)*y + tr(i,3)*z
1     c(i) = c(i) - tr(i,4)
      x = c(1)
      y = c(2)
      z = c(3)

      end
      subroutine tranf(nparm,nz,ianz,fx,f,ib,b,g,ll)
c
c
c
c***********************************************************************
c     routine to transform cartesian first derivatives to
c     derivatives over internal coordinates.
c
c     arguments:
c
c     nparm  ... number of z-matrix degrees of freedom (3*nz-6).
c     nz     ... number of rows in the z-matrix.
c     ianz   ... integer atomic numbers of z-matrix elements.
c     fx     ... input vector (length 3*natoms) containing
c                cartesian derivatives.
c     f      ... output vector of length nparm containing
c                derivatives over internal coordinates.
c     ib     ... integer b-matrix as produced by formbg.
c     b      ... b-matrix as produced by formbg.
c     g      ... g-matrix produced by formbg.
c     ll     ... scratch vector of length nz.
c***********************************************************************
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension ianz(*),fx(*),f(*),ib(4,nparm),b(3,4,nparm),g(*),ll(*)
c
      data dzero/0.d0/
c
      call vclr(f,1,nparm)
      ii = 1
_IF1(c)cdir$ list
_IF1(c)cdir$ novector
      do 20 i = 1 , nz
         ll(i) = 0
         if (ianz(i).ne.-1) then
            ll(i) = ii
            ii = ii + 1
         end if
 20   continue
      do 70 i = 1 , nparm
         ii = nparm*(i-1)
         r = dzero
         do 40 k1 = 1 , 4
            k = ib(k1,i)
            if (k.eq.0) go to 50
            k = ll(k)
            if (k.ne.0) then
               k = 3*(k-1)
               do 30 l = 1 , 3
                  r = r + b(l,k1,i)*fx(k+l)
 30            continue
            end if
 40      continue
 50      do 60 j = 1 , nparm
            f(j) = f(j) + g(ii+j)*r
 60      continue
 70   continue
_IF1(c)cdir$ vector
_IF1(c)cdir$ nolist
      return
c
      end
      subroutine tranfxz(nparm,nparmz,nz,ianz,fx,f,ib,b,
     &     g,gcart,igcart,ll)
c
c
c
c***********************************************************************
c     routine to transform cartesian first derivatives to
c     derivatives over internal coordinates.
c
c     arguments:
c
c     nparm  ... number of z-matrix degrees of freedom (3*nz-6).
c     nz     ... number of rows in the z-matrix.
c     ianz   ... integer atomic numbers of z-matrix elements.
c     fx     ... input vector (length 3*natoms) containing
c                cartesian derivatives.
c     f      ... output vector of length nparm containing
c                derivatives over internal coordinates.
c     ib     ... integer b-matrix as produced by formbg.
c     b      ... b-matrix as produced by formbg.
c     g      ... g-matrix produced by formbg.
c     ll     ... scratch vector of length nz.
c***********************************************************************
c
      implicit REAL (a-h,p-w),integer (i-n),logical (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension ianz(*),fx(*),f(*),ib(4,nparm),b(3,4,nparm),g(*),
     &     gcart(*),igcart(*),ll(*)
c
      data dzero/0.d0/
c
c      write(6,*)'cart forces'
c      do i=1,nz
c         write(6,999)(fx(3*(i-1)+j),j=1,3)
c 999     format(1x,3f12.5)
c      enddo

      call vclr(f,1,nparm)
      ii=1
      do 45 i=1,nz
         ll(i)=0
         if(ianz(i).ne.-1) then
            ll(i)=ii
            ii=ii+1
         endif
 45   continue

      do 60 i=1,nparm
         ii=nparm*(i-1)
         r=dzero
         do 55 k1=1,4
            k=ib(k1,i)
            if(k.eq.0) go to 65
            k=ll(k)
            if(k.eq.0) go to 55
            k=3*(k-1)

            do 50 l=1,3
               r=r+b(l,k1,i)*fx(k+l)
 50         continue
 55      continue
 65      continue

         if( (igcart(i).ne.-1))then
            do 70 j=1,nparm
               if((igcart(j).ne.-1)) then
                  in=igcart(j)+nparmz*(igcart(i)-1)
                  f(j)=f(j)+g(in)*r
               endif
 70         continue
         else
            f(i) = r*gcart(i)
         endif

 60   continue
      return
c
      end
      subroutine trans1(nn)
c
c
c      calculate the coordinates (xnew,ynew,znew) of the transform
c      of the point (xold,yold,zold) under the transformation t
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/transf)
      common/junk/t(432)
      pnew = psmal*t(nn+1) + qsmal*t(nn+2) + rsmal*t(nn+3)
      qnew = psmal*t(nn+4) + qsmal*t(nn+5) + rsmal*t(nn+6)
      rnew = psmal*t(nn+7) + qsmal*t(nn+8) + rsmal*t(nn+9)
      return
      end
      subroutine triang(maxap3,a,i,j,k,alp,bet,gam,dij,dik,djk)
c
c     given the atomic coordinates in a and the three atoms i, j, and k
c     find:
c       1-- the distances defined by the locations of the three atoms,
c           dij, dik, and djk.
c       2-- the angles defined by the location of the three atoms,
c           alp    k.i.j
c           bet    i.j.k
c           gam    j.k.i
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension a(maxap3,3)
c
      setxi = a(i,1)
      setyi = a(i,2)
      setzi = a(i,3)
      setxj = a(j,1)
      setyj = a(j,2)
      setzj = a(j,3)
      setxk = a(k,1)
      setyk = a(k,2)
      setzk = a(k,3)
      dij = dsqrt((setxi-setxj)**2+(setyi-setyj)**2+(setzi-setzj)**2)
      dik = dsqrt((setxi-setxk)**2+(setyi-setyk)**2+(setzi-setzk)**2)
      djk = dsqrt((setxj-setxk)**2+(setyj-setyk)**2+(setzj-setzk)**2)
      dotjk = (setxj-setxi)*(setxk-setxi) + (setyj-setyi)*(setyk-setyi)
     +        + (setzj-setzi)*(setzk-setzi)
      dotik = (setxi-setxj)*(setxk-setxj) + (setyi-setyj)*(setyk-setyj)
     +        + (setzi-setzj)*(setzk-setzj)
      dotij = (setxi-setxk)*(setxj-setxk) + (setyi-setyk)*(setyj-setyk)
     +        + (setzi-setzk)*(setzj-setzk)
      alp = dacos(dotjk/(dij*dik))
      bet = dacos(dotik/(dij*djk))
      gam = dacos(dotij/(dik*djk))
      return
      end
      subroutine trcart
      implicit REAL (a-h,p-w),integer (i-n),logical  (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension p1(3), p2(3), p3(3), p4(3), tr(3,4)
c
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/czmat)
INCLUDE(common/runlab)
INCLUDE(common/csubch)
INCLUDE(common/phycon)
c
INCLUDE(common/infoa)
INCLUDE(common/infob)
c
      data vsmall/1.0d-12/
      data small/1.0d-8/

c     x  -----   alpha, y  -----   beta,   z  -----   bl

c     The general approach is to 
c     1. substitute the variables (see subroutine subvar)
c     2. transform the z-matrix (cartesian coordinates only)
c     3. adjust the values and l-values so that the signs 
c        are handled through the l-values and the values are positive
c     4. read out the actual values (see subroutine xyzvar)
c     5. substitute the variables again with the new values 
c        (see subroutine subvar again)
c
      itran_var=0
      n_cart=0
      do 50 i=1,nz
        if(iz(i,1).lt.0) then
	  n_cart=n_cart+1
          itran_var = itran_var + 
     &         iabs(lalpha(i))+iabs(lbeta(i))+iabs(lbl(i))
	endif
50    continue
      if(n_cart.eq.0) return
      if(nz.eq.1) return
      p1(1) = alpha(2) - alpha(1)
      p1(2) = beta(2) - beta(1)
      p1(3) = bl(2) - bl(1)
      if(nz.eq.2) then
        if(iz(1,1).lt.0.and.abs(alpha(1))+abs(beta(1))+
     +    abs(bl(1)).gt.vsmall) then
	  write(iwr,*)
     +    'When using cartesians to input the first atom of a diatomic'
	  write(iwr,*)
     +    'molecule, the coordinates must be specified: 0.0,0.0,0.0'
          call caserr2('atom 1 not correctly centred')
	  return
	endif
	if(iz(2,1).lt.0.and.
     +    abs(alpha(2)).gt.vsmall.and.abs(beta(2)).gt.vsmall) then
	  write(iwr,*) 
     +  'When using cartesian input for the second atom of a diatomic'
          write(iwr,*) 
     +  'molecule, the coordinates must be specified: 0.0,0.0,z'
	  call caserr2('atom 2 not correctly positioned')
	  return
	endif
      endif
      call normal(p1)
      if(bl(1).gt.vsmall.or.alpha(1).gt.vsmall.or.
     +      beta(1).gt.vsmall) then
c           non-centred origin
        write(iwr,*)
	write(iwr,200) 
        write(iwr,*)
      else if(alpha(2).gt.vsmall.or.beta(2).gt.vsmall) then
        write(iwr,*)
	write(iwr,200) 
        write(iwr,*)
      else if(beta(3).gt.vsmall) then
c       third atom not aligned
        write(iwr,*)
	write(iwr,200) 
        write(iwr,*)
      else 
	if(n_cart.gt.2) then
c	  no need for cartesian transformation
          write(iwr,*)
          write(iwr,*) 'no need to realign cartesian atoms'
	  write(iwr,*)
	endif
	return
      endif

      do 1 i=3,nz
	if(iz(i,1).lt.0) then
          p2(1) = alpha(i) - alpha(1)
          p2(2) = beta(i) - beta(1)
          p2(3) = bl(i) - bl(1)
          call vcrossprod(p3,p1,p2)
          dprod=0.0d0
          do 2 j=1,3
2         dprod = dprod+p3(j)*p3(j)
          if(dprod.gt.vsmall) goto 3
        endif
1     continue
3     call vcrossprod(p3,p1,p2)
      call normal(p3)
      call vcrossprod(p4,p1,p3)
      call normal(p4)
      do 10 i=1,3
10    p4(i) = -p4(i)

      tr(1,1) = p4(1)
      tr(1,2) = p4(2)
      tr(1,3) = p4(3)
      tr(1,4) = 0.0d0
      tr(2,1) = p3(1)
      tr(2,2) = p3(2)
      tr(2,3) = p3(3)
      tr(2,4) = 0.0d0
      tr(3,1) = p1(1)
      tr(3,2) = p1(2)
      tr(3,3) = p1(3)
      tr(3,4) = 0.0d0

c      write(6,*)'transformation matrix'
c      write(6,*)(tr(1,i),i=1,4)
c      write(6,*)(tr(2,i),i=1,4)
c      write(6,*)(tr(3,i),i=1,4)

      call tranatm(alpha(1),beta(1),bl(1),tr) 

      tr(1,4) = alpha(1)
      tr(2,4) = beta(1)
      tr(3,4) = bl(1)

c translation of first atom

      alpha(1) = alpha(1)-tr(1,4)
      beta(1) = beta(1) - tr(2,4)
      bl(1) = bl(1)-tr(3,4)

      if(itran_var.gt.0) then
	write(iwr,300) 
	write(iwr,301)
	write(iwr,302)
	write(iwr,301)
      endif

      do 5 i=2,nz
         if(iz(i,1).lt.0) then
	    coord_x = alpha(i)*toang(1)
	    coord_y = beta(i)*toang(1)
	    coord_z = bl(i)*toang(1)
            call tranatm(alpha(i),beta(i),bl(i),tr)
c
c           Now we try to adapt the values such that the value of the
c           variable is always positive and the sign is always handled
c           through the corresponding l-component.
c
            if (alpha(i).lt.0.0d0) then
c
c              the value of alpha is negative in the transformed 
c              z-matrix
c
               if (lalpha(i).lt.0) then
c
c                 and the minus sign is already dealt with in lalpha
c                 then store the positive of the alpha.
c
                  alpha(i) = -alpha(i)
c
               else if (lalpha(i).gt.0) then
c
c                 and the minus sign is not accounted for in lalpha then
c                 store the positive of the alpha and store the minus
c                 sign in lalpha
c
                  lalpha(i) = -lalpha(i)
                  alpha(i)  = -alpha(i)
c
               endif
            else if (alpha(i).gt.0.0d0) then
c
c              the value of alpha is positive in the transformed 
c              z-matrix
c
               if (lalpha(i).lt.0) then
c
c                 but lalpha specifies a minus sign then remove the 
c                 sign from lalpha
c
                  lalpha(i) = -lalpha(i)
c
               else if (lalpha(i).gt.0) then
               endif
            endif
c
c           the above follows similarly for beta and bl
c
            if (beta(i).lt.0.0d0) then
               if (lbeta(i).lt.0) then
                  beta(i) = -beta(i)
               else if (lbeta(i).gt.0) then
                  lbeta(i) = -lbeta(i)
                  beta(i)  = -beta(i)
               endif
            else if (beta(i).gt.0.0d0) then
               if (lbeta(i).lt.0) then
                  lbeta(i) = -lbeta(i)
               else if (lbeta(i).gt.0) then
               endif
            endif
            if (bl(i).lt.0.0d0) then
               if (lbl(i).lt.0) then
                  bl(i) = -bl(i)
               else if (lbl(i).gt.0) then
                  lbl(i) = -lbl(i)
                  bl(i)  = -bl(i)
               endif
            else if (bl(i).gt.0.0d0) then
               if (lbl(i).lt.0) then
                  lbl(i) = -lbl(i)
               else if (lbl(i).gt.0) then
               endif
            endif
c
	    if(lalpha(i).ne.0) then
               write(iwr,305) zvar(iabs(lalpha(i))),coord_x,alpha(i)*
     +              toang(1)
            endif
	    if(lbeta(i).ne.0)  then
               write(iwr,305) zvar(iabs(lbeta(i))),coord_y,beta(i)*
     +              toang(1)
            endif
	    if(lbl(i).ne.0) then
               write(iwr,305) zvar(iabs(lbl(i))),coord_z,bl(i)*toang(1)
            endif

cc           write(6,*)'after tran',i,alpha(i),beta(i),bl(i)

        endif
 5    continue

      if(itran_var .gt. 0)write(iwr,301)
c
c     Check that each variable has only one value.
c     Note also that one variables can be used for 
c     - multiple centres
c     - multiple coordinates
c
      do 6 i=2,nz
         if(iz(i,1).lt.0) then
	    if(lalpha(i).ne.0) then
               do 7 j=i+1,nz
                  if(iabs(lalpha(j)).eq.iabs(lalpha(i))) then
                     if(abs(alpha(i)-alpha(j)).gt.small) then
                        write(iwr,310) zvar(iabs(lalpha(i)))
                        write(iwr,311) 'x'
                        write(iwr,312) 
                        call caserr2('invalid variable')
                     endif
                  endif
 7             continue
               do j=2,nz
                  if(iabs(lbeta(j)).eq.iabs(lalpha(i))) then
                     if(abs(alpha(i)-beta(j)).gt.small) then
                        write(iwr,313) zvar(iabs(lalpha(i)))
                        call caserr2('invalid variable')
                     endif
                  endif
                  if(iabs(lbl(j)).eq.iabs(lalpha(i))) then
                     if(abs(alpha(i)-bl(j)).gt.small) then
                        write(iwr,313) zvar(iabs(lalpha(i)))
                        call caserr2('invalid variable')
                     endif
                  endif
               enddo
            endif
	    if(lbeta(i).ne.0) then
               do 8 j=i+1,nz
                  if(iabs(lbeta(j)).eq.iabs(lbeta(i))) then
                     if(abs(beta(i)-beta(j)).gt.small) then
                        write(iwr,310) zvar(iabs(lbeta(i)))
                        write(iwr,311) 'y'
                        write(iwr,312)
                        call caserr2('invalid variable')
                     endif
                  endif
 8             continue
               do j=2,nz
                  if(iabs(lbl(j)).eq.iabs(lbeta(i))) then
                     if(abs(beta(i)-bl(j)).gt.small) then
                        write(iwr,313) zvar(iabs(lbeta(i)))
                        call caserr2('invalid variable')
                     endif
                  endif
               enddo
            endif
         endif
         if(lbl(i).ne.0) then
            do 9 j=i+1,nz
               if(iabs(lbl(j)).eq.iabs(lbl(i))) then
		  if(abs(bl(i)-bl(j)).gt.small) then
                     write(iwr,310) zvar(iabs(lbl(i)))
                     write(iwr,311) 'z'
                     write(iwr,312)
                     call caserr2('invalid variable')
		  endif
               endif
 9          continue
         endif
 6    continue

      call xyzvar

200   format(' Realigning cartesian atoms')
300   format(' The following cartesian variables have been transformed')
301   format('-----------------------------------')
302   format('Variable     Old Value    New Value')
305   format(3x,a8,f8.3,5x,f8.3)
310   format('The cartesian variable *** ',a8,' ***  has been used for 2
     + centres')
311   format('A rotation of the cartesian centres has resulted in the ',
     +a1,' coordinates')
312   format('having different values. This variable is invalid.')
313   format('The cartesian variable *** ',a8,' ***  has been used for 2
     + coordinates'/
     +       'A rotation of the cartesian centres has resulted in the co
     +ordinates'/
     +       'having different values. This variable is invalid.')

      end
      subroutine tstc3(maxap3,a,b,natoms,atmchg,iat,jat,kat,
     $                 centr,itst)
c
c     are the three atoms iat, jat, and kat interchangeable via a
c     3-fold rotation?
c        if no  itst=0, return
c        if yes itst=1, align c3 with z, return
c     centr is the point of intersection of the c3 axis with the
c     plane defined by the 3 atoms.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3), centr(*)
      dimension t(3,3), b(maxap3,3), atmchg(*)
c
      data half,done,two,three,eight/0.5d0,1.0d0,2.0d0,3.0d0,8.0d0/
c
      numatm = natoms + 3
      itst = 0
      phi3 = (eight/three)*datan(done)
      theta3 = half*phi3
      fact3 = two/three
c
c     get the angles and sides of the triangle defined by the three
c     atoms.
c
      call triang(maxap3,a,iat,jat,kat,alpha,beta,gamma,dij,dik,djk)
c
c     do the three points form an equilateral triangle?  it is only
c     necessary to check to see if one angle is 60 degrees and that
c     two sides are equal.
c
      if(dabs(alpha-theta3).gt.toler.or.dabs(dij-dik).gt.toler)return
      px = half*(a(jat,1)+a(kat,1))
      py = half*(a(jat,2)+a(kat,2))
      pz = half*(a(jat,3)+a(kat,3))
      centr(1) = a(iat,1) + fact3*(px-a(iat,1))
      centr(2) = a(iat,2) + fact3*(py-a(iat,2))
      centr(3) = a(iat,3) + fact3*(pz-a(iat,3))
      call putt(maxap3,a,b,t,centr,numatm,3)
      call rotate(maxap3,a,b,natoms,t,3,phi3)
      call equiv(maxap3,a,b,atmchg,natoms,itst)
      return
      end
      subroutine tstc4(maxap3,a,b,natoms,atmchg,iat,jat,kat,
     $                 centr,itst)
c
c     are the three atoms iat, jat, and kat interchangeable via a
c     4-fold rotation?
c        if no  itst=0, return
c        if yes itst=1, align c4 with z, return
c     centr is the point of intersection of the c4 axis with the
c     plane defined by the 3 atoms.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3), centr(*)
      dimension t(3,3), b(maxap3,3), atmchg(*)
c
      data half,done,two/0.5d0,1.0d0,2.0d0/
c
      numatm = natoms + 3
      itst = 0
      halfpi = two*datan(done)
c
c     get the angles and sides of the triangle defined by the three
c     atoms.
c
      call triang(maxap3,a,iat,jat,kat,alpha,beta,gamma,dij,dik,djk)
c
c     are any of these angles equal to 90 degrees (i.e. the internal
c     angle of a square) and thus possibly equivalent by a
c     4-fold axis of symmetry?
c     are two of the sides of the triangle of equal length?
c
      if (dabs(alpha-halfpi).le.toler .and. dabs(dij-dik).le.toler) then
         centr(1) = half*(a(jat,1)+a(kat,1))
         centr(2) = half*(a(jat,2)+a(kat,2))
         centr(3) = half*(a(jat,3)+a(kat,3))
c
      else if (dabs(beta-halfpi).gt.toler .or. dabs(dij-djk).gt.toler)
     +         then
c
         if (dabs(gamma-halfpi).gt.toler .or. dabs(dik-djk).gt.toler)
     +       return
         centr(1) = half*(a(iat,1)+a(jat,1))
         centr(2) = half*(a(iat,2)+a(jat,2))
         centr(3) = half*(a(iat,3)+a(jat,3))
      else
         centr(1) = half*(a(iat,1)+a(kat,1))
         centr(2) = half*(a(iat,2)+a(kat,2))
         centr(3) = half*(a(iat,3)+a(kat,3))
      end if
c
      call putt(maxap3,a,b,t,centr,numatm,3)
      call rotate(maxap3,a,b,natoms,t,3,halfpi)
      call equiv(maxap3,a,b,atmchg,natoms,itst)
      return
      end
      subroutine tstc5(maxap3,a,b,natoms,atmchg,iat,jat,kat,
     $                 centr,itst)
c
c     are the three atoms iat, jat, and kat interchangeable via a
c     5-fold rotation?
c        if no  itst=0, return
c        if yes itst=1, align c5 with z, return
c     centr is the point of intersection of the c5 axis with the
c     plane defined by the 3 atoms.
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/tol)
c
      dimension a(maxap3,3), centr(*)
      dimension t(3,3), b(maxap3,3), atmchg(*)
c
      data half,pt8,done,donep6/0.5d0,0.8d0,1.0d0,1.6d0/
      data two,twopt4/2.0d0,2.4d0/
c
      numatm = natoms + 3
      itst = 0
      piovr4 = datan(done)
      phi5 = donep6*piovr4
      theta5 = twopt4*piovr4
      fact5 = done/(two*dsin(pt8*piovr4)**2)
c
c     get the angles and sides of the triangle defined by the three
c     atoms.
c
      call triang(maxap3,a,iat,jat,kat,alpha,beta,gamma,dij,dik,djk)
c
c     are any of these angles equal to 108 degrees (i.e. the internal
c     angle of a regular pentagon) and thus possibly equivalent by a
c     5-fold axis of symmetry?
c     are two of the sides of the triangle of equal length?
c
      if (dabs(alpha-theta5).le.toler .and. dabs(dij-dik).le.toler) then
         px = half*(a(jat,1)+a(kat,1))
         py = half*(a(jat,2)+a(kat,2))
         pz = half*(a(jat,3)+a(kat,3))
         centr(1) = a(iat,1) + fact5*(px-a(iat,1))
         centr(2) = a(iat,2) + fact5*(py-a(iat,2))
         centr(3) = a(iat,3) + fact5*(pz-a(iat,3))
c
      else if (dabs(beta-theta5).gt.toler .or. dabs(dij-djk).gt.toler)
     +         then
c
         if (dabs(gamma-theta5).gt.toler .or. dabs(dik-djk).gt.toler)
     +       return
         px = half*(a(iat,1)+a(jat,1))
         py = half*(a(iat,2)+a(jat,2))
         pz = half*(a(iat,3)+a(jat,3))
         centr(1) = a(kat,1) + fact5*(px-a(kat,1))
         centr(2) = a(kat,2) + fact5*(py-a(kat,2))
         centr(3) = a(kat,3) + fact5*(pz-a(kat,3))
      else
         px = half*(a(iat,1)+a(kat,1))
         py = half*(a(iat,2)+a(kat,2))
         pz = half*(a(iat,3)+a(kat,3))
         centr(1) = a(jat,1) + fact5*(px-a(jat,1))
         centr(2) = a(jat,2) + fact5*(py-a(jat,2))
         centr(3) = a(jat,3) + fact5*(pz-a(jat,3))
      end if
c
      call putt(maxap3,a,b,t,centr,numatm,3)
      call rotate(maxap3,a,b,natoms,t,3,phi5)
      call equiv(maxap3,a,b,atmchg,natoms,itst)
      return
      end
      subroutine vec(small,ohoh,u,c,j,k)
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension c(*),r(3),u(3)
c
      data dzero/0.0d0/
c
      jtemp = (j-1)*3
      ktemp = (k-1)*3
      r2 = dzero
      do 20 i = 1 , 3
         r(i) = c(i+jtemp) - c(i+ktemp)
         r2 = r2 + r(i)*r(i)
 20   continue
      r2 = dsqrt(r2)
      ohoh = r2.lt.small
      if (ohoh) return
      do 30 i = 1 , 3
         u(i) = r(i)/r2
 30   continue
      return
c
      end
      subroutine vcrossprod(vp,p,q)
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension vp(*),p(*),q(*)
c
c     --- evaluate the cross product of x and y
c
      vp(1) = p(2)*q(3) - p(3)*q(2)
      vp(2) = p(3)*q(1) - p(1)*q(3)
      vp(3) = p(1)*q(2) - p(2)*q(1)
      return
c
      end
      subroutine write_fcm

      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
c     made a bit more elegant (??) and fit for optxyz (jvl,2000)
c     can read both triangular and square hessians
c     also added labeled hessian reading (i,j, 3*3) 
c       for Center for Molecular Design (Janssen), Vosselaer, Belgium (2000)
c     also reads fiddle options if need be
c

INCLUDE(common/sizes)
INCLUDE(common/czmat)
INCLUDE(common/work)
INCLUDE(common/iofile)
INCLUDE(common/runlab)
INCLUDE(common/infoa)
INCLUDE(common/fiddle_hesc)
      common/hmat/o_hmat,ihess,o_tri,o_lab
      dimension rar(9)
c
      call inpa4(ytest)
c
      if (ytest.eq.'refr') then
         call inpi(ifreq_h)
         return
      end if
c
      nvart = nvar
      if (nvar.eq.0.and.zruntp.eq.'optxyz') nvart = nat*3
      if (nvart.eq.0) call caserr2('trying to read 0-dim hessian')
c
      ihess=99
      open(unit=ihess,form='unformatted',status='scratch')
      o_hmat = .true.
      icount=0
      o_lab = .false.
c
      nvar2 = 0
      if (ytest.eq."tri") then
         o_tri = .true.
         nvar2 = nvart*(nvart+1)/2
      else if (ytest.eq."sqr") then
         o_tri = .false.
         nvar2 = nvart*nvart
      else if (ytest.eq."labe".or.ytest.eq."cmd") then
         o_lab = .true.
      else if (ytest.ne." ") then
         call caserr2('unrecognized hmat option')
      end if
c
      call input
1      call rchar(ztest)
       if (ztest.eq."end") go to 2
          jrec = jrec - 1
       if (o_lab) then
          call rinpi(iat)
          call rinpi(jat)
          if (iat.gt.nat.or.jat.gt.nat) 
     1       call caserr2('too many atoms in labelled hessian')
          do i=1,9
             call rinpf(rar(i))
          end do
          write(ihess) iat,jat,rar
       else
         call rinpf(rnum)
         write(ihess) rnum
         icount = icount + 1
       end if
      go to 1
c
2     if (o_lab) then
         write(ihess) 0,0,rar
         return
      end if
c
      if (nvar2.eq.0) then
         if (icount.eq.nvart*nvart) then
            o_tri = .false.
         else if (icount.eq.nvart*(nvart+1)/2) then
            o_tri = .true.
         else
            write(iwr,100) icount,nvart*nvart,nvart*(nvart+1)/2,nvart
100         format(' got ',i9,' hessian elements',/,
     1             ' expected ',i9,' or ',i9,' for dimension ',i5)
            call caserr2('Wrong number of elements in Hessian')
         end if
      else
	 if (icount.ne.nvar2) then
            write(iwr,101) icount,nvar2,nvart
101         format(' got ',i9,' hessian elements',/,
     1             ' expected ',i9,' for dimension ',i5)
            call caserr2('Wrong number of elements in Hessian')
         end if
      end if
c
      end
      subroutine zfil(s3,mxbnds,scr,am,ipath,iopt,nmats1)
c
c     this routine will create symbol table that is compatible with
c     the gamess program.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer s3
INCLUDE(common/sizes)
c
c
INCLUDE(common/phycon)
      character*8 atlet,atlet2
      common /bufb/atlet(maxat),atlet2(maxat)
      dimension    scr(*),am  (3,s3,15),
     -            ipath(s3,15,mxbnds),iopt(3,s3)
c
INCLUDE(common/infoa)
INCLUDE(common/infob)
INCLUDE(common/runlab)
INCLUDE(common/csubch)
INCLUDE(common/iofile)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
INCLUDE(common/prints)
      character*1 sym2(3)
      character*4 sym1
      data sym2/'b','a','p'/
      data dzero/0.0d0/
c
c     zero those bits of the z-matrix which are not used in the first 3
c     atoms
c
      do 30 j = 1 , 4
         do 20 k = 1 , 3
            iopt(k,j) = 0
 20      continue
 30   continue
      iopt(2,5) = 0
      iopt(3,5) = 0
      iopt(3,6) = 0
      nvar = 0
      do 50 i = 1 , maxnz
         lbl(i) = 0
         lalpha(i) = 0
         lbeta(i) = 0
         intvec(i) = 0
         fpvec(i) = dzero
         bl(i) = dzero
         alpha(i) = dzero
         beta(i) = dzero
         do 40 j = 1 , 4
            iz(i,j) = 0
 40      continue
 50   continue
c
c     generate the z-matrix table entries
c
      nvar = 0
      nz = nmats1
      do 70 i = 1 , nz
         if (atlet2(i).eq.'dm') atlet2(i) = 'x'
         write (sym1,'(i3)') i
         call strt2(sym1,length)
         zaname(i) = atlet2(i)
         ianz(i) = isubst(zaname(i))
         czan(i) = dfloat(ianz(i))
         jmax = 3
         if (i.eq.1) jmax = 0
         if (i.eq.2) jmax = 1
         if (i.eq.3) jmax = 2
         do 60 k = 1 , jmax
            if (iopt(k,i).ne.0) then
               nvar = nvar + 1
               zvar(nvar) = sym2(k)//sym1
               values(nvar) = am(k,i,1)
               cmin10(nvar) = values(nvar)
               cmin20(nvar) = values(nvar)
               intvec(nvar) = 0
               fpvec(nvar) = 1.0d0
               itemp = nvar
            else
               itemp = 0
            end if
            iz(i,k) = ipath(i,1,k+1)
            if (k.eq.1) then
               bl(i) = am(k,i,1)
               lbl(i) = itemp
            end if
            if (k.eq.2) then
               alpha(i) = am(k,i,1)
               lalpha(i) = itemp
            end if
            if (k.eq.3) then
               beta(i) = am(k,i,1)
               lbeta(i) = itemp
            end if
 60      continue
 70   continue
      call subvar(bl,alpha,beta,lbl,lalpha,lbeta,nz,nvar)
      call sprintxz(maxnz,nz,ianz,iz,bl,alpha,beta,toang(1),iwr)
c     call chgmlt(ich,mul,onel)
c
c ---- write out the values and names of the variables
c
      pi = dacos(0.0d0)*2.0d0
      write (iwr,6010)
      i = 0
      do 90 k = 1 , 3
         do 80 j = 1 , nz
            if (k.eq.1 .and. lbl(j).gt.0) then
               i = lbl(j)
               ytype = 'angs'
               const = toang(1)
               write (iwr,6020) zvar(i) , values(i)*const , ytype ,
     +                           fpvec(i)
            else if (k.eq.2 .and. lalpha(j).gt.0) then
               i = lalpha(j)
               ytype = 'degs'
               const = 180.0d0/pi
               write (iwr,6020) zvar(i) , values(i)*const , ytype ,
     +                           fpvec(i)
            else if (k.eq.3 .and. lbeta(j).gt.0) then
               i = lbeta(j)
               ytype = 'degs'
               const = 180.0d0/pi
               write (iwr,6020) zvar(i) , values(i)*const , ytype ,
     +                           fpvec(i)
            end if
 80      continue
 90   continue
      n1 = 1
      n2 = n1 + nz
      n3 = n2 + nz
      n4 = n3 + nz
      n5 = n4 + nz
      n6 = n5 + nz
      otest = .true.
      call stocxz(maxnz,nz,ianz,iz,bl,alpha,beta,otest,natom,imass,c,
     +      scr(n6),scr(n1),scr(n2),scr(n3),scr(n4),scr(n5),iwr,oerro)
      if (oerro) call caserr2(
     +             'fatal error detected in z-matrix specification')
      j = 0
      do 100 i = 1 , nz
         if (ianz(i).ge.0) then
            j = j + 1
            zaname(j) = zaname(i)
            czan(j) = czan(i)
         end if
 100  continue
      nat = natom
c store contents of czan in symz and czanr
      call dcopy(nat,czan,1,symz,1)
      call dcopy(nat,czan,1,czanr,1)
      write (iwr,6030)
      nbqnop = 0
      do 110 i = 1 , nat
         if (.not. oprint(31) .or. (zaname(i)(1:2) .ne. 'bq'))then
         write (iwr,6040) i , zaname(i) , (c(j,i),j=1,3)
         else
           nbqnop = nbqnop + 1
        endif
 110  continue
      if (nbqnop .gt. 0)then
         write (iwr,6041) nbqnop
      endif
      write (iwr,6050)
      return
 6010 format (/1x,'----------------------------------------------'/1x,
     +        'variable',11x,'value',9x,5x,'hessian'/1x,
     +        '----------------------------------------------')
 6020 format (1x,a8,2x,f14.7,1x,a4,2x,f14.6)
 6030 format (/30x,'coordinates (a.u.) - prior to orientation'/1x,
     +        72('-')/17x,'atom',16x,'x',14x,'y',14x,'z'/)
 6040 format (12x,i3,2x,a8,2x,3f15.6)
 6041 format (12x,i5,' bq centres not printed')
 6050 format (/1x,72('-')/)
      end
      subroutine zgen(number,c,az,zlabs,ytype,ntype,
     * s3,mxbnds,
     * dist,csalpa,csbta,csgma,dcord,dcord2,dcord3,
     * am,cxoord,coord2,iposna,iposnb,iposnc,
     * icon,icon2,icon1,ipath,ncon,n,iopt,iconv,iconv1,
     * neigh,neigh1,iconv2,scale_geo)
c
c     it looks as though the arguments IATTYP, IBOND1, QX and NAT
c     are not used ...
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      integer s3
      dimension c(3,*),az(*)
      dimension ytype(ntype)
      dimension zlabs(number)
INCLUDE(common/sizes)
c
c
INCLUDE(common/phycon)
      character*8 atlet,atlet2
      common /bufb/atlet(maxat),atlet2(maxat)
      dimension   dist(s3,15,3),csalpa(s3,15,3),
     -            csbta(s3,15,3),csgma(s3,15,3),
     -            dcord(3,s3),dcord2(3,s3),dcord3(3,s3),
     -            am(3,s3,15),cxoord(3,s3),coord2(3,s3),
     -            iposna(s3,5),iposnb(s3,10),iposnc(s3,10),
     -            icon(s3,mxbnds),icon2(s3,mxbnds),
     -            icon1(s3,mxbnds),
     -            ipath(s3,15,mxbnds),ncon(s3),
     -            n(s3),iopt(3,s3),
     -            iconv(s3),iconv1(s3),
     -            neigh(s3),neigh1(s3),iconv2(s3)
      pi = dacos(0.0d0)*2.0d0
      numats = number
c
c     put bonding info into icon
c
      call bondin(number,c,az,s3,mxbnds,icon,icon2,ncon,scale_geo)
c
c     copy labels into a temporary file
c
      do 20 i = 1 , number
         atlet(i) = zlabs(i)
 20   continue
c
c     copy coordinates
c
      call dcopy(3*number,c,1,cxoord,1)
c
c     prepare common blocks with initialization info
c
      icon2(1,1) = 2
      icon2(2,1) = 1
      icon2(2,2) = 3
      icon2(3,1) = 2
      icon2(3,2) = 4
      neigh1(1) = 1
      neigh1(2) = 2
      neigh1(3) = 2
      iconv(4) = 4
      iconv2(4) = 4
      atlet2(1) = 'dm'
      atlet2(2) = 'dm'
      atlet2(3) = 'dm'
      am(1,1,1) = 0.0d0
      am(2,1,1) = 0.0d0
      am(3,1,1) = 0.0d0
      am(1,2,1) = 1.0d0
      am(2,2,1) = 0.0d0
      am(3,2,1) = 0.0d0
      am(1,3,1) = 1.0d0
      am(2,3,1) = pi*0.5d0
      am(3,3,1) = 0.0d0
      n(1) = 1
      n(2) = 1
      n(3) = 1
      n(4) = 1
      coord2(1,1) = 0.0d0
      coord2(2,1) = 0.0d0
      coord2(3,1) = 0.0d0
      coord2(1,2) = 1.0d0
      coord2(2,2) = 0.0d0
      coord2(3,2) = 0.0d0
      coord2(1,3) = 1.0d-12
      coord2(2,3) = 1.0d0
      coord2(3,3) = 0.0d0
      ipath(1,1,1) = 1
      ipath(2,1,1) = 2
      ipath(2,1,2) = 1
      ipath(3,1,1) = 3
      ipath(3,1,2) = 2
      ipath(3,1,3) = 1
      ipath(4,1,1) = 4
      ipath(4,1,2) = 3
      ipath(4,1,3) = 2
      ipath(4,1,4) = 1
c
c     prepare for z matrix generation
c
c
c         1. a(1,i) : the distance between atom i and
c            an atom specified by na(i)
c
c         2. a(2,i) : the angle made by atom i and atoms
c            na(i) and nb(i)
c
c         3. a(3,i) : the dihedral angle formed by the vectors
c            atom i: na(i) and nb(i):nc(i)
c
c     renumber the molecule
c
      call renum(s3,mxbnds,cxoord,coord2,icon,icon2,icon1,iconv,iconv1,
     +           neigh,neigh1,iconv2,numats,nmats1)
c
c     determine the candidates for the geometric parameters na(i),
c     nb(i),nc(i)
c
      call paths(s3,mxbnds,iposna,iposnb,iposnc,icon2,ipath,n,neigh1,
     +           iconv2,nmats1)
c
c     determine the geometric parameters a(1,i),a(2,i),and a(3,i)
c
      call ggeom(s3,mxbnds,dist,csalpa,csbta,csgma,dcord,dcord2,dcord3,
     +           am,coord2,ipath,n,nmats1)
c
      nvar = 0
      do 80 k = 1 , ntype
         if (ytype(k).eq.'all') then
c
c           optimize all the geometric parameters
c
            nvar = 0
            do 40 i = 1 , nmats1
               do 30 j = 1 , 3
                  nvar = nvar + 1
                  iopt(j,i) = 1
 30            continue
 40         continue
         else if (ytype(k).eq.'bond') then
c
c           optimize all the bond lengths
c
            do 50 i = 1 , nmats1
               nvar = nvar + 1
               iopt(1,i) = 1
 50         continue
         else if (ytype(k).eq.'angl') then
c
c           optimize all bond angles
c
            do 60 i = 1 , nmats1
               nvar = nvar + 1
               iopt(2,i) = 1
 60         continue
         else if (ytype(k).eq.'tors') then
c
c           optimize all torsion angles
c
            do 70 i = 1 , nmats1
               nvar = nvar + 1
               iopt(3,i) = 1
 70         continue
         end if
 80   continue
c
c     generate zmatrix symbols
c
      call zfil(s3,mxbnds,dist,am,ipath,iopt,nmats1)
      return
      end
      subroutine xyzvar
c
      implicit REAL (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
INCLUDE(common/sizes)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
c
      do 10  i=1,nz
	if(iz(i,1).lt.0) then
	  if(lbl(i).ne.0)    values(iabs(lbl(i)))    = bl(i)
	  if(lalpha(i).ne.0) values(iabs(lalpha(i))) = alpha(i)
	  if(lbeta(i).ne.0)  values(iabs(lbeta(i)))  = beta(i)
	endif
10    continue
      return
      end	
      subroutine build_nuct(nat,ns,zaname,czan,nuct)
      implicit none
c
c     Classify centres into the following categories
c
c     atom (nuct = 1)
c        all centres with charges equal to or greater than one
c        and basis functions
c     magic (nuct = 2)
c        all bq-centres and all centres with charges less than one 
c        and basis functions (the latter centres cause problems in the 
c        atomscf as they would not have any electrons).
c     ghost (nuct = 3)
c        all centres without a charge but with basis functions
c     point charges (nuct = 4)
c        all centres with a charge but without basis functions
c     dummies (or null) (nuct = 5)
c        all centres without a charge and without basis functions
c
c     Input:
c
c        nat   : number of centres
c        ns    : number of shells on each centre
c        zaname: atom tags as specified in the geometry
c        czan  : charge on each centre
c
      integer nat
      integer ns(nat)
      character *8 zaname(nat)
      REAL czan(nat)
c
c     Output:
c
      integer nuct(nat)
c
      integer i, ichg, ns1
      REAL chg
      REAL toll
      parameter(toll=1.0d-10)
c
      do i = 1, nat
         nuct(i) = 1
         chg = czan(i)
         ns1 = ns(i)
         ichg=int(chg+0.5d0)
         if (ns1.eq.0) then
            if (dabs(chg).le.toll) then
               nuct(i) = 5
            else
               nuct(i) = 4
            endif
         else
            if (dabs(chg).le.toll) then
               nuct(i) = 3
            else if (chg.le.1.0d0-toll) then
               nuct(i) = 2
            endif
         endif
         if (zaname(i)(1:2).eq.'bq') then
            nuct(i) = 2
         endif
      enddo
      end
      subroutine ver_input(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/input.m,v $
     +     "/
      data revision /"$Revision: 6299 $"/
      data date /"$Date: 2014-10-06 16:33:14 +0200 (Mon, 06 Oct 2014) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
