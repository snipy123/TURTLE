c     deck=optim
c ******************************************************
c ******************************************************
c             =   optim  =
c ******************************************************
c ******************************************************
c
      subroutine bfsmin(cx,en0,g,hesx,cz,exx,gxx,n,ny,ifail,ioutp,
     + core,cxm,gz,fkp,lines,iwr)
c
c ------ this is the driving routine for the bfs minimum search
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension cx(n),g(n),hesx(n,n),cz(n,n)
      dimension fkp(4,*),lines(4,*)
      dimension exx(200,*),gxx(200,*)
      dimension cxm(*)
      dimension gz(*)
INCLUDE(common/prints)
INCLUDE(common/cntl1)
INCLUDE(common/cntl2)
_IF(taskfarm)
INCLUDE(common/taskfarm)
_ENDIF
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
_ENDIF
      common/miscop/cmin1(maxvar),cmin2(maxvar),
     1     coefb(maxvar),coefc(maxvar),coefd(maxvar),coefe(maxvar),
     *     tangsp(4,maxvar),
     2gx1(maxvar),gx2(maxvar),cx1(maxvar),cx2(maxvar)
     3,cy(maxvar),del(maxvar)
     4,cp1,cp2,cp3,ff1,ff2,ff3,gg1,gg2,gg3
      dimension core(*)
      external sfun1
      data yno,yes/'no','yes'/
      grad = 0.0d0
      likeep = lintyp
      call mnter(en0,grad,g,n,2,1,fkp,lines,iwr)
      nftotl = 1
      nls = 0
      ismax = 0
      f = en0
      ifail = 1
      if (n.lt.1) go to 100
      if (mnls.lt.1) go to 100

c
c ----- energy and gradients for the first point should already be known
c
c ----- initialise z
c
      ifail = 0
      sqrtgg=dnrm2(n,g,1)
c
c
c ---- now we must work in x-space
c ---- get ready to update the hessian (invert it)
c ---- first diagonalise it and check all roots are positive
c
      if (sqrtgg.ge.stol*0.01d0) then
         if (oprint(44)) then
            if (ioutp.ne.0) write (ioutp,6010)
            do 20 i = 1 , n
               if (ioutp.ne.0) write (ioutp,6020) (hesx(i,j),j=1,n)
 20         continue
         end if
         ineg = 0
         ireord = 0
         call inveig(hesx,hesx,ny,cxm,eigmin,eigmax,ineg,ireord,iwr)
c
c ----- transform coordinates and gradients to z space
c
 30      stol1 = stol
         stol2 = stol*0.66666666d0
         stol3 = stol*0.25d0
         stol4 = stol*0.16666666d0
         call dcopy(ny,g,1,gz,1)
         call dcopy(ny,cx,1,cy,1)
         gts = 0.0d0
         do 40 i = 1 , ny
            dx = -ddot(ny,hesx(1,i),1,gz,1)
            if (dabs(dx).gt.gts) gts = dabs(dx)
            del(i) = dx
 40      continue
         scale = 1.0d0
         if (gts.gt.stepmx) scale = stepmx/gts
         gts = 0.0d0
         do 50 i = 1 , ny
            del(i) = del(i)*scale
            dx = del(i)
            gts = gts + dx*gz(i)
 50      continue
         if (oprint(44)) then
            if (ioutp.ne.0) write (ioutp,6040)
            do 60 k = 1 , ny
               if (ioutp.ne.0) write (ioutp,6030) (hesx(i,k),i=1,ny)
 60         continue
         end if
         if (ioutp.ne.0) then
            write (ioutp,6050) (gz(k),k=1,ny)
            write (ioutp,6060) (del(k),k=1,ny)
            write (ioutp,6070) (cy(k),k=1,ny)
         end if
c
c
c ---- commence a line search in x-space
c
         dxmax = 0.0d0
         dxrms = 0.0d0
         gxmax = 0.0d0
         gxrms = 0.0d0
         do 70 i = 1 , n
            dx = dabs(del(i))
            gx = dabs(g(i))
            if (dx.gt.dxmax) dxmax = dx
            if (gx.gt.gxmax) gxmax = gx
            dxrms = dxrms + dx*dx
            gxrms = gxrms + gx*gx
 70      continue
         dxrms = dsqrt(dxrms)/n
         gxrms = dsqrt(gxrms)/n
         ool1 = dxmax.lt.stol1
         ool2 = dxrms.lt.stol2
         ool3 = gxmax.lt.stol3
         ool4 = gxrms.lt.stol4
         yout1 = yno
         yout2 = yno
         yout3 = yno
         yout4 = yno
         if (ool1) yout1 = yes
         if (ool2) yout2 = yes
         if (ool3) yout3 = yes
         if (ool4) yout4 = yes
         if (ioutp.ne.0) write (ioutp,6080) dxmax , stol1 , yout1 ,
     +                          dxrms , stol2 , yout2 , gxmax , stol3 ,
     +                          yout3 , gxrms , stol4 , yout4
         elow = ddot(n,del,1,g,1)
         if (ioutp.ne.0) write (ioutp,6090) elow
         lintyp = likeep
         if (dabs(elow).lt.5.0d-6) lintyp = 1
         alpha = 0.0d0
         step = 1.0d0
         esth = 1.0d0
         if (.not.(ool1 .and. ool2 .and. ool3 .and. ool4)) then
_IF(ccpdft)
            if (CD_active()) then
               ierror = CD_jfit_init1()
               if (ierror.ne.0) then
                  write(iwr,600)ierror
                  call caserr2('Out of memory')
               endif
            endif
 600        format('*** Need ',i10,' more words to store fitting ',
     +             'coefficients and Schwarz tables in core')
_ENDIF
            if (lintyp.eq.0) call linesf(f,alpha,step,gts,esth,cx,g,cz,
     +          exx,gxx,ny,n,sfun1,ifail,ioutp,core,fkp,lines,iwr)
            if (lintyp.ne.0) call linesg(f,alpha,step,gts,esth,cx,g,cz,
     +          exx,gxx,ny,n,sfun1,ifail,ioutp,core,fkp,lines,iwr)
_IF(ccpdft)
            if (CD_active()) then
               ierror = CD_jfit_clean1()
               if (ierror.ne.0) then
                  call caserr2(
     +           'Memory failure in bfsmin:CD_jfit_clean1')
               endif
            endif
_ENDIF
            en0 = f
            if (ifail.ne.0) return
c
c ---- update the hessian in x-space
c
            ineg = 0
            call updateh(cy,cx,gz,g,hesx,cz,cxm,ny,ineg,ifail,iwr)
            nls = nls + 1
            call monit(nls,hesx,ny,ioutp,core)
            if (ifail.ne.0) then
c
c ---- updateh failed so restart calc with a 'unit' hessian
c
               do 90 i = 1 , ny
                  do 80 j = 1 , ny
                     hesx(i,j) = 0.0d0
 80               continue
                  hesx(i,i) = 1.0d0
 90            continue
               nls = nls + 1
               call monit(nls,hesx,ny,ioutp,core)
            end if
            call dcopy(ny,cx,1,cy,1)
            call dcopy(ny,g,1,gz,1)
            if (nls.lt.mnls) go to 30
            iterat = iterat - 1
            ifail = 1
            write (iwr,6100)
_IF(taskfarm)
            itaskret = 1
_ENDIF
            return
         end if
      end if
      write (iwr,6110)
      return
 100  ifail = 1
      write (iwr,6120)
_IF(taskfarm)
      itaskret = 1
_ENDIF
      return
 6010 format (/1x,'current hessian')
 6020 format (8(1x,e14.7))
 6030 format (6(1x,e14.7))
 6040 format (//1x,'inverse hessian in x-space')
 6050 format (/1x,'gradients in x-space'/6(1x,e14.7))
 6060 format (/1x,'step in x-space'/6(1x,e14.7))
 6070 format (/1x,'current position in x-space'/8(1x,e14.7))
 6080 format (/20x,'information on convergence'/20x,
     +        '=========================='//5x,'    maximum step',f14.8,
     +        2x,'convergence? ',f14.8,1x,a4/5x,'    average step',
     +        f14.8,2x,'convergence? ',f14.8,1x,a4/5x,
     +        'maximum gradient',f14.8,2x,'convergence? ',f14.8,1x,
     +        a4/5x,'average gradient',f14.8,2x,'convergence? ',f14.8,
     +        1x,a4)
 6090 format (/5x,'estimated energy lowering',e20.10)
 6100 format (//1x,
     +        'optimisation terminating as line search count exceeded')
 6110 format (//40x,22('*')/40x,'optimization converged'/40x,22('*')/)
 6120 format (//1x,'too many line searches or insufficient variables'///
     +        )
      end
      subroutine calcfg(iflag,n,c,f,g,cc,gg,ioutp,core,fkp,lines)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/restar)
INCLUDE(common/prints)
INCLUDE(common/iofile)
INCLUDE(common/cntl1)
INCLUDE(common/cntl2)
      character*10 charwall
      dimension ctwo(maxvar),fkp(4,*),lines(4,*)
      dimension cc(200,*),gg(200,*),core(*)
      dimension c(n),g(n)
      data m1,mm1/1,-1/
      if (iflag.eq.8) go to 70
      if (iflag.ne.9) then
         call dcopy(n,c(1),1,ctwo(1),1)
         if (iflag.eq.3) then
            jj = jpoint - 1
            if (igrec(jj).eq.-1) then
               call grad(g,core)
               if (irest.le.0) then
                  jj = jpoint - 1
                  do 20 i = 1 , n
                     gg(jj,i) = g(i)
 20               continue
                  ig(jj) = 1
                  igrec(jj) = 1
                  call mindum(cc,gg,n)
                  go to 80
               else
                  igrec(jpoint-1) = 0
                  write (iwr,6010)
                  go to 70
               end if
            else
c
c     read old gradients
c
               do 30 i = 1 , n
                  g(i) = gg(jj,i)
 30            continue
               ig(jj) = 1
               call mindum(cc,gg,n)
               go to 80
            end if
         else if (jpoint.le.jm) then
            if (ierec(jpoint).eq.-1.or.
c  allow for non-converged SCF on previous point (irest=3)
     +          ierec(jpoint).eq. 0) then
               write (iwr,6080) jpoint , cpulft(1) ,charwall()
               oprint(24) = .false.
               ioutp = iwr
c
c     calculate the energy for next point
c
               call newpt(n,c,f,mm1,ioutp,core)
               en(jpoint) = f
               do 40 i = 1 , n
                  cc(jpoint,i) = ctwo(i)
 40            continue
               if (irest.le.0) then
                  ierec(jpoint) = 1
                  jpoint = jpoint + 1
                  if (.not.oprint(43)) nprint = -5
                  call mindum(cc,gg,n)
                  go to 80
               else
                  ierec(jpoint) = 0
                  if (irest.gt.1) then
                     write (iwr,6020)
                     call blkerror(
     +'Optimization terminating due to incomplete scf', 0 )
                  endif
                  if (irest.eq.1) then
                     write (iwr,6030)
                     call blkerror(
     +'Optimization terminating due to incomplete 2e-integrals', 0 )
                  endif
                  go to 70
               end if
            else
               if (oprint(24)) ioutp = 0
               if (ioutp.ne.0) write (ioutp,6040) jpoint
               call newpt(n,c,f,m1,ioutp,core)
c
c  check that parameter values on dumpfile agree with those required by
c
               do 50 i = 1 , n
                  if (dabs(ctwo(i)-cc(jpoint,i)).gt.
     +                0.005d0*dabs(ctwo(i))) go to 60
 50            continue
               f = en(jpoint)
               jpoint = jpoint + 1
               return
            end if
         else
            write (iwr,6070)
            go to 70
         end if
      else
         jpoint = 1
         return
      end if
 60   write (iwr,6060)
 70   cpu = cpulft(1)
      write (iwr,6050) cpu ,charwall()
c
c  write all the parameter values and corresponding energies to dumpfile
c
      call mindum(cc,gg,n)
      if (imnter.ne.0) call mnter(temp,temp,g,n,0,ityp,fkp,lines,iwr)
      if (iflag.ne.8 .or. irest.ne.0) then
         itask(mtask) = irest
c ... update restart section on dumpfile
         call revise
c
c punch out any data from the dumpfile
c
         call blk(core)
         call ioupdate
         call closda
         call clenup2
         call pg_end(1)
      end if
 80   return
 6010 format (/
     +        ' ** optimization terminating due to incomplete gradients'
     +        //)
 6020 format (/' ** optimization terminating due to incomplete scf'//)
 6030 format (/
     +     ' ** optimization terminating due to incomplete 2e-integrals'
     +     //)
 6040 format (//1x,104('=')//1x,15('*')/' old calculation  -  point ',
     +        i2/1x,15('*'))
 6050 format (//' end of optimization at ',f10.2,' seconds',
     +            a10,' wall'/)
 6060 format (
     + ' ***** parameter error *****'//
     + ' ***** input-zmatrix in restart .ne. original input z-matrix')
 6070 format (//2x,'***** max. no. calculations - in calcfg')
 6080 format (///1x,104('=')//10x,15('*')
     +        /' commence new calculation  -  point ',i3,' at ',f10.2,
     +        ' seconds',a10,' wall'/10x,15('*'))
      end
_EXTRACT(deriv,hp800)
      subroutine deriv(pool0,pool1,delvar,d1vold,d1var,d2var,
     +                cold,exx,gxx,g,ioutp,core,fkp,lines,
     +                ndim,iout)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension exx(*),gxx(200,*),core(*),fkp(4,*),lines(4,*)
      dimension pool0(*),pool1(*),delvar(*),d1var(*)
      dimension d2var(*),d1vold(*),cold(*),g(*)
INCLUDE(common/cntl1)
INCLUDE(common/fpinfo)
      equivalence (fplus, f1(1)), (fminus,f1(2))
      data dzero,done,two/0.d0,1.d0,2.d0/
c
c     *  initialize the counters used by deriv.
c
      nstep = 0
      indfx = 1
      sign = done
 20   pool0(indfx) = pool1(indfx) + delvar(indfx)*sign
      dinc = delvar(indfx)*sign
      write (iout,6030) indfx , pool1(indfx) , dinc , pool0(indfx)
c
c     *  nstep is incremented by the sum of modef and one.  if modef is
c     *  dzero, nstep = 1,2,3,...,2*n, where n is the number of vari
c     *  ables being optimized.  if modef is one, nstep = 2,4,... .
c     *  derivative(s) are only calculated when nstep is even.  thus,
c     *  when modef is one, derivatives are calculated every cycle.  the
c     *  appropriate formulae are used to compensate for the missing
c     *  values of the function that is being optimized.
c
      nstep = nstep + modef + 1
c
c     *  routine calcfg is called to obtain the value of the function
c
c     ..........
      call calcfg(0,ndim,pool0,energy,g,exx,gxx,ioutp,core,fkp,lines)
      call mnter(energy,0.0d0,d1var,nvarf,1,14+modef,fkp,lines,iout)
      ffp = energy
      modulo = mod(nstep,2)
      if (modulo.ne.0) then
c
c     *  change the value of isig so that the variable will be decre
c     *  mented next time.
c
         fplus = ffp
         sign = -done
         go to 20
      else
c
c     *  check the value of modef to determine which derivative(s) are
c     *  to be calculated this time.
c
         if (modef.ne.0) then
c
c     *  modef=1, only the first derivative will be calculated.  it will
c     *  be corrected by the the existing second derivative.  also,
c     *  the value of the old first derivative will be saved in the
c     *  array d1vold.
c
            fplus = ffp
            d1vold(indfx) = d1var(indfx)
            d1var(indfx) = (fplus-fzero)/delvar(indfx) - d2var(indfx)
     +                     *delvar(indfx)/two
         else
c
c     *  modef=0, both the first and second derivatives are to be calc
c     *  ulated.
            fminus = ffp
            if (dabs(d2var(indfx)).gt.dzero) then
             scale = dsqrt(d2var(indfx))
             if (dabs(d1var(indfx)).gt.dzero) then
              d1vold(indfx) = d1var(indfx)*scale
             endif
            else
             d1vold(indfx) = dzero 
            endif
            d1var(indfx) = (fplus-fminus)/(delvar(indfx)+delvar(indfx))
            d2var(indfx) = (fplus+fminus-(fzero+fzero))
     +                     /(delvar(indfx)*delvar(indfx))
            d1vold(indfx) = d1vold(indfx)/dsqrt(d2var(indfx))
c
c     *  if the second derivative is negative, it indicates that the
c     *  function is tending toward a maximum rather than a minimum.
c     *  if this is the case, this program can no longer handle the
c     *  situation.  a call to pchout in error mode is made.  this
c     *  will provide error termination with a dump (to cards) of the
c     *  available restart information.
c
            if (d2var(indfx).le.dzero) call caserr2(
     +          'fletcher powell algorithm is heading for a maximum')
         end if
c
c     *  set isig back to the value for incrementing in case it has
c     *  been changed, and increment indfx.
c     *  also, restore the original value of the variable from
c     *  pool1 to pool0
c

         sign = done
         pool0(indfx) = pool1(indfx)
         indfx = indfx + 1
c
c     *  now compare indfx against the value of nvarf.  if indfx is
c     *  greater than nvarf the calculation of derivatives is done for
c     *  now.
c
         if (indfx.le.nvarf) go to 20
         write (iout,6010)
         do 30 i = 1 , nvarf
            write (iout,6020) i , d1var(i) , d2var(i)
 30      continue
c
c     *  are the forces below threshold at this point??
c
         call fptest(pool1,cold,d1var,iout)
         return
      end if
 6010 format(/2x,62('=')/
     +  4x,'variable',4x,'first derivative',13x,'second derivative'/
     +  2x,62('='))
 6020 format(2x,i10,e20.10,10x,e20.10)
 6030 format(/1x,'**FP**  in deriv, variable ',i3,
     + ' incremented:  was ',e20.10/
     +        1x,'**FP**  stepped by ',e20.10,' and is now ',e20.10,'.')
      end
_ENDEXTRACT
_EXTRACT(eigen,mips4)
_IF(hpux11)
c$HP$ OPTIMIZE ASSUME_NO_PARAMETERS_OVERLAPS OFF
_ENDIF
      subroutine eigen (a,m,n,d,vec,e,if)
      implicit REAL  (a-h,p-x),integer   (i-n),logical    (o)
      implicit character *8 (z)
      implicit character *4 (y)
      dimension a(m,m), d(m), vec(m,m)
      dimension e(m)
_IF(c90,convex)
      eps = x02ajf(dum)
      tol = x02ajf(dum)
_ELSEIF(j90)
      eps = x02aaf(dum)
      tol = x02ajf(dum)
_ELSE
      eps = x02aaf(dum)
      tol = x02adf(dum)
_ENDIF
      if (n.eq.1) then
         d(1) = a(1,1)
         vec(1,1) = 1.0d0
      else
         do 30 i = 1 , n
c     householder's reduction
c     simulation of loop do 150 i=n,2,(-1)
            do 20 j = 1 , i
               vec(i,j) = a(i,j)
 20         continue
 30      continue
         do 120 ni = 2 , n
            ii = n + 2 - ni
            do 110 i = ii , ii
               l = i - 2
               h = 0.0d0
               g = vec(i,i-1)
               if (l.gt.0) then
                  do 40 k = 1 , l
                     h = h + vec(i,k)**2
 40               continue
                  s = h + g*g
                  if (s.lt.tol) then
                     h = 0.0d0
                  else if (h.gt.0) then
                     l = l + 1
                     f = g
                     g = dsqrt(s)
                     if (f.gt.0) then
                        g = -g
                     end if
                     h = s - f*g
                     vec(i,i-1) = f - g
                     f = 0.0d0
                     do 70 j = 1 , l
                        vec(j,i) = vec(i,j)/h
                        s = 0.0d0
                        do 50 k = 1 , j
                           s = s + vec(j,k)*vec(i,k)
 50                     continue
                        j1 = j + 1
                        if (j1.le.l) then
                           do 60 k = j1 , l
                              s = s + vec(k,j)*vec(i,k)
 60                        continue
                        end if
                        e(j) = s/h
                        f = f + s*vec(j,i)
 70                  continue
                     f = f/(h+h)
                     do 80 j = 1 , l
                        e(j) = e(j) - f*vec(i,j)
 80                  continue
                     do 100 j = 1 , l
                        f = vec(i,j)
                        s = e(j)
                        do 90 k = 1 , j
                           vec(j,k) = vec(j,k) - f*e(k) - vec(i,k)*s
 90                     continue
 100                 continue
                  end if
               end if
c     accumulation of transformation matrices
               d(i) = h
               e(i-1) = g
 110        continue
 120     continue
         d(1) = vec(1,1)
         vec(1,1) = 1.0d0
         do 170 i = 2 , n
            l = i - 1
            if (d(i).gt.0) then
               do 150 j = 1 , l
                  s = 0.0d0
                  do 130 k = 1 , l
                     s = s + vec(i,k)*vec(k,j)
 130              continue
                  do 140 k = 1 , l
                     vec(k,j) = vec(k,j) - s*vec(k,i)
 140              continue
 150           continue
            end if
            d(i) = vec(i,i)
            vec(i,i) = 1.0d0
            do 160 j = 1 , l
c     diagonalization of the tridiagonal matrix
               vec(i,j) = 0.0d0
               vec(j,i) = 0.0d0
 160        continue
 170     continue
         b = 0.0d0
         f = 0.0d0
         e(n) = 0.0d0
         do 250 l = 1 , n
c     test for splitting
            h = eps*(dabs(d(l))+dabs(e(l)))
            if (h.gt.b) b = h
            do 180 j = l , n
c     test for convergence
               if (dabs(e(j)).le.b) go to 190
 180        continue
 190        if (j.eq.l) then
               d(l) = d(l) + f
            else
 200           p = (d(l+1)-d(l))*0.5d0/e(l)
               r = dsqrt(p*p+1.0d0)
               if (p.lt.0) then
                  p = p - r
               else
                  p = p + r
               end if
               h = d(l) - e(l)/p
               do 210 i = l , n
c     qr transformation
                  d(i) = d(i) - h
 210           continue
               f = f + h
               p = d(j)
c     simulation of loop do 330 i=j-1,l,(-1)
               c = 1.0d0
               s = 0.0d0
               j1 = j - 1
               do 240 ni = l , j1
                  ii = l + j1 - ni
                  do 230 i = ii , ii
c     protection against underflow of exponents
                     g = c*e(i)
                     h = c*p
                     if (dabs(p).lt.dabs(e(i))) then
                        c = p/e(i)
                        r = dsqrt(c*c+1.0d0)
                        e(i+1) = s*e(i)*r
                        s = 1.0d0/r
                        c = c/r
                     else
                        c = e(i)/p
                        r = dsqrt(c*c+1.0d0)
                        e(i+1) = s*p*r
                        s = c/r
                        c = 1.0d0/r
                     end if
                     p = c*d(i) - s*g
                     d(i+1) = h + s*(c*g+s*d(i))
                     do 220 k = 1 , n
                        h = vec(k,i+1)
                        vec(k,i+1) = vec(k,i)*s + h*c
                        vec(k,i) = vec(k,i)*c - h*s
 220                 continue
 230              continue
 240           continue
               e(l) = s*p
c     convergence
               d(l) = c*p
               if (dabs(e(l)).gt.b) go to 200
c     ordering of eigenvalues
               d(l) = d(l) + f
            end if
 250     continue
         if (if.lt.1) then
            ni = n - 1
            do 280 i = 1 , ni
               k = i
               p = d(i)
               j1 = i + 1
               do 260 j = j1 , n
                  if (d(j).lt.p) then
                     k = j
                     p = d(j)
                  end if
 260           continue
               if (k.ne.i) then
                  d(k) = d(i)
                  d(i) = p
                  do 270 j = 1 , n
                     p = vec(j,i)
                     vec(j,i) = vec(j,k)
                     vec(j,k) = p
 270              continue
               end if
c     special treatment of case n = 1
 280        continue
         end if
      end if
      return
      end
_IF(hpux11)
c$HP$ OPTIMIZE ASSUME_NO_PARAMETERS_OVERLAPS ON
_ENDIF
_ENDEXTRACT
      subroutine estm(hes,p,nvar)
c
c ----- guess diagonal second derivative information
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension hes(nvar,nvar),p(*)
      dimension aa(4,4),irow(108),angst(maxvar),isave(maxnz)
      common/czmat/ianz(maxnz),iz(maxnz,4),bl(maxnz),alpha(maxnz),
     1     beta(maxnz),lbl(maxnz),lalpha(maxnz),lbeta(maxnz),nz,nvarr
INCLUDE(common/csubst)
      common/miscop/qst(12,maxvar),cx1(maxvar),cx2(maxvar)
INCLUDE(common/phycon)
      equivalence (angst(1),cx1(1)) , (isave(1),cx2(1))
      data a2/4.00d0/
c...   1-3 is like Gaussian; row/column 4 are fantasy
      data aa/-0.129d0, 0.186d0, 0.349d0, 0.5d0,
     1         0.186d0, 0.574d0, 0.805d0, 0.9d0,
     2         0.349d0, 0.805d0, 1.094d0, 1.2d0,
     3         0.5d0  , 0.9d0  , 1.2d0  , 1.3d0/
      data b2/1.00d0/
      data irow/2*1,8*2,8*3,90*4/
      data hartre/4.259814d0/
      do 20 i = 1 , nz
         if (ianz(i).gt.108) then
            return
         end if
 20   continue
      a = a2
c
c ---- nb if we could work out the type of basis (minimal etc)
c ---- then we could set a and b properly
c
      b = b2
      do 30 i = 1 , nvar
         hes(i,i) = 0.0d0
         angst(i) = p(i)
         if (nrep(i,lbl,nz).ne.0) angst(i) = angst(i)*toang(1)
 30   continue
      if (nz.ge.2) then
         do 40 i = 2 , nz
            iv = iabs(lbl(i))
            if (iv.ne.0) then

               if(iz(i,1) .lt.0)then
c
c for a cartesian-defined atom assume FC is 1
c
                  if (intvec(iv).eq.0) hes(iv,iv) = hes(iv,iv) + 1.0d0
               else
                  iatno = ianz(i)
                  ia = irow(iatno)
                  if (iatno.lt.1) ia = 1
                  jatom = iz(i,1)
                  jatno = ianz(jatom)
                  ib = irow(jatno)
*     if (jatno.lt.1) ib = 1
*     above line causes problems as jatom can equal  -1
                  if (jatno.lt.1.or.jatom.le.0) ib = 1
                  if (intvec(iv).eq.0) hes(iv,iv) = hes(iv,iv)
     +                 + a/((angst(iv)-aa(ia,ib))**3)
               end if
            end if
 40      continue
      endif
      if (nz.ge.3) then
         do 50 i = 3 , nz
            iv = iabs(lalpha(i))
            if (iv.ne.0) then
               if(iz(i,1) .lt.0)then
                  if (intvec(iv).eq.0) hes(iv,iv) = hes(iv,iv) + 1.0d0
               else
                  if (intvec(iv).eq.0) hes(iv,iv) = hes(iv,iv) + b
               end if
            end if
 50      continue
      endif
      if (nz.ge.4) then
         do 60 i = 4 , nz
            iv = iabs(lbeta(i))
            if (iv.ne.0) then
               if(iz(i,1) .lt.0)then
                  if (intvec(iv).eq.0) hes(iv,iv) = hes(iv,iv) + 1.0d0
               else
                  if (intvec(iv).eq.0) hes(iv,iv) = hes(iv,iv) + b
               endif
            end if
 60      continue
      end if

      constr = toang(1)**2/hartre
      conbnd = 1.0d0/hartre
      call setsto(maxnz,0,isave)
      nsave = 0
      if (nz.ge.2) then
         do 70 i = 2 , nz
            iv = iabs(lbl(i))
            if(iz(i,1) .ge.0 .and. 
     +           iv.ne.0 .and. nrep(iv,isave,nsave).eq.0) then
               nsave = nsave + 1
               isave(nsave) = iv
               if (intvec(iv).eq.0) hes(iv,iv) = hes(iv,iv)*constr
            end if
 70      continue
         call setsto(nsave,0,isave)
         nsave = 0
      endif
      if (nz.ge.3) then
         do 80 i = 3 , nz
            iv = iabs(lalpha(i))
            if(iz(i,1) .ge.0 .and.
     +           iv.ne.0 .and. nrep(iv,isave,nsave).eq.0) then
               nsave = nsave + 1
               isave(nsave) = iv
               if (intvec(iv).eq.0) hes(iv,iv) = hes(iv,iv)*conbnd
            end if
 80      continue
      endif
      if (nz.ge.4) then
         do 90 i = 4 , nz
            iv = iabs(lbeta(i))
            if(iz(i,1) .ge.0 .and.
     +           iv.ne.0 .and. nrep(iv,isave,nsave).eq.0) then
               nsave = nsave + 1
               isave(nsave) = iv
               if (intvec(iv).eq.0) hes(iv,iv) = hes(iv,iv)*conbnd
            end if
 90      continue
      end if

      return
      end
      subroutine fcint(natoms,idump,maxnz,nz,ianz,iz,bl,
     +                 alpha,beta,lbl,lalpha,lbeta,nvar,fx,fc,
     +                 frcnst,core,iout)
      implicit REAL  (a-h,o-z)
c
c     this routine takes a set of cartesian forces and force
c     constants and a z-matrix and converts the force constants
c     to z-matrix variables.  the cartesian force constants in
c     fc are converted to internal coordinates in fc and the
c     force.
c
INCLUDE(common/gmempara)
      character*7 fnm
      character*5 snm
      data fnm,snm/'optim.m','fcint'/
      dimension fx(*), core(*), lbl(*), fc(*), bl(*), iz(*),
     $    lalpha(*), lbeta(*), frcnst(*), ianz(*), alpha(*), beta(*)
c
      if (idump.gt.0) write (iout,6010)
      if (idump.gt.0) call matpri(fx,3,natoms,3,natoms,iout)
      if (idump.gt.0) write (iout,6020)
      if (idump.gt.0) call ltoutd(natoms*3,fc,1)
c
c     take cartesian second derivatives in fc and forces in
c     fx.  convert to internal second derivatives in fc.
      nparm = max(3*nz-6,1)
c

c      i1 = igmem_alloc_inf(3*nz*(2+3*nz),fnm,snm,'i1',IGMEM_DEBUG)
c      i111 = i1
c                        i1=   ftmp1(3*nz)
c      i2 = i1 + 3*nz
c                        i2=   ftmp2(3*nz)
c      i3 = i2 + 3*nz
c                        i3=   fftmp(3*nz*3*nz)
c      last = i3 + 3*nz*3*nz 
c

      i1 = igmem_alloc_inf(3*nz,fnm,snm,'i1',IGMEM_DEBUG)
      i2 = igmem_alloc_inf(3*nz,fnm,snm,'i2',IGMEM_DEBUG)
      i3 = igmem_alloc_inf(3*nz*3*nz,fnm,snm,'i3',IGMEM_DEBUG)

      call trnfff(maxnz,nz,ianz,iz,bl,alpha,beta,natoms,nparm,fx,fc,
     +            core(i1),core(i2),core(i3),core,idump,iout)

      call gmem_free_inf(i3,fnm,snm,'i3')
      call gmem_free_inf(i2,fnm,snm,'i2')
      call gmem_free_inf(i1,fnm,snm,'i1')

      if (nparm.eq.0) return
      if (idump.gt.0) write (iout,6030)
      if (idump.gt.0) call ltoutd(nparm,fc,1)
      i1 = igmem_alloc_inf(nparm,fnm,snm,'i1_2',IGMEM_DEBUG)
      i2 = igmem_alloc_inf(nvar,fnm,snm,'i2_2',IGMEM_DEBUG)
      i3 = igmem_alloc_inf(nparm*nvar,fnm,snm,'i3_2',IGMEM_DEBUG)
      call putff(nz,lbl,lalpha,lbeta,nparm,nvar,fc,frcnst,core(i1),
     +           core(i2),core(i3),idump,iout)
c
c ----- reset core
c
      call gmem_free_inf(i3,fnm,snm,'i3_2')
      call gmem_free_inf(i2,fnm,snm,'i2_2')
      call gmem_free_inf(i1,fnm,snm,'i1_2')

      return
 6010 format (' fcint: cartesian first derivatives:')
 6020 format (' fcint: cartesian force constants:')
 6030 format (' fcint: force constants in internal coordinates:')
      end
      subroutine fcmed3(hes,rx,ndim,idump,form)
c
      implicit REAL  (a-h,p-w), integer (i-n), logical (o)
      implicit character*8 (z), character*1 (x), character*4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
c
c     ----- routine to transform the cartesian second derivative to
c           second derivative in internal coordinates
c           the first derivatives are stored in eg (internal coord.)
c           the second derivatives are restored from
c           the dumpfile, and returned in hes.
c
c     if form = 'xyz' the cartesian hessian is returned in hess 
c     if the section is 489 the force constant are in zmatrix-variable-form
c
INCLUDE(common/molsym)
      common/reord2/iordd(maxat)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
      common/miscop/qst(16,maxvar),qstt(31),fx(3*maxat)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/phycon)
INCLUDE(common/restri)
INCLUDE(common/cntl1)
      common/restrl/ociopt(2),omp2
      logical exist1,exist2
      character*7 fnm
      character*6 snm
      data fnm,snm/'optim.m','fcmed3'/
      dimension rx(*),hes(ndim,*)
      character*(*) form
c ...
c     ----- evaluate some constants ----
c ...
c     nparm = 3*nz - 6
      l1 = 3*nz
      nvarx = nat*3
      nvarx2 = nvarx*nvarx
      nparmx2 = l1*l1
c
c     ----- grow memory for c ...fcmt -----
c

c      i20 = igmem_alloc_inf(nvarx2 +  nvar*(nvar+1)/2 + nvarx2)
c
c      i30 = i20 + nvarx2
c      i40 = i30 + nvar*(nvar+1)/2
c      last = i40 + nvarx2
c      length = last - i20

      

      i20 = igmem_alloc_inf(nvarx2,fnm,snm,'i20',IGMEM_DEBUG)
      if (form.ne.'xyz') then
         i30 = igmem_alloc_inf(nvar*(nvar+1)/2,fnm,snm,'i30',
     &                         IGMEM_DEBUG)
cpsh
         i40 = igmem_alloc_inf(max(nvarx2,nparmx2),fnm,snm,'i40',
     &                         IGMEM_DEBUG)
      end if
c ...
c     ----- restore the cartesian 2nd derivatives which is in
c           x(i20) -----
c     --- or get z-matrix hessian directly in hes
c
      call rdfcm(rx(i20),'fcmed3')
      if (isecfcm.eq.489) then
         call dcopy(nvar*nvar,rx(i20),1,hes,1)
         go to 100
      end if
c
      if (idump.gt.0) call prsq(rx(i20),nvarx,nvarx,nvarx)
c
      if (form.eq.'xyz') then
         call dcopy(nvarx2,rx(i20),1,hes,1)
         call gmem_free_inf(i20,fnm,snm,'i20')
         return
      end if

      call linear(rx(i20),rx(i20),nvarx,nvarx)
      call rotff(nat,tr,rx(i20),rx(i20))
      call reordd(nat,iordd,rx(i20),rx(i40))
      call fcint(nat,idump,maxnz,nz,ianz,iz,bl,alpha,beta,lbl,
     +           lalpha,lbeta,nvar,fx,rx(i40),rx(i30),rx,iwr)
c ...
c     ----- write out the second derivative matrix -----
c ...
      call squar(rx(i30),rx(i40),nvar,nvar,0)
      call dcopy(nvar*nvar,rx(i40),1,hes,1)
100   if (idump.gt.0) call prsq(hes,nvar,nvar,nvar)
c ...
c     ----- return the fast memory -----
c ...
      call gmem_free_inf(i40,fnm,snm,'i40')
      call gmem_free_inf(i30,fnm,snm,'i30')
      call gmem_free_inf(i20,fnm,snm,'i20')
c
      return
      end
      subroutine rdfcm(vec,call)
c
c     read cartesian force constant matrix from somewhere
c     is now always triggered by fcmin call - see there
c
      implicit REAL  (a-h,o-z)
      dimension vec(*)
      logical exist1,exist2
      character*(*) call
INCLUDE(common/sizes)
INCLUDE(common/infoa)
c
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/cntl1)
INCLUDE(common/czmat)
      character*8 text,text2
c
      nat3 = nat*3
c
c    fcm are read from another dumpfile
c
      if (.not.unit7.and.ifcm.ne.0) then
         if (isecfcm.eq.46) then
            text = '   scf  '
         else if (isecfcm.eq.110) then
            text = '   mp2  '
         else if (isecfcm.eq.489) then
            text = 'optimise'
         else
            text = ' '
         end if
         text2 = ' '
         if (isecfcm.eq.489) then
            call rdedx(vec,nvar*nvar,iblfcm,ifcm)
         else
            call rdedx(vec,nat3*nat3,iblfcm,ifcm)
         end if
         if (ifcm.ne.ifild) text2 = 'foreign '
         write (iwr,6070) text,text2
         return
      end if
c
c     check if are read in on fortran unit 7
c
      if (unit7) then
         rewind ipu
         do 20 i = 1 , nat
            i1 = (i-1)*3*nat3
            i2 = i1 + nat3
            i3 = i2 + nat3
            read (ipu,6010) (vec(i1+j),vec(i2+j),vec(i3+j),j=1,nat3)
 20      continue
         write (iwr,6060)
         unit7 = .false.
         return
      end if
c
c      look on usual place on dumpfile
c
      call fcmin('rdfcm')
c
      if (iblfcm.ne.0) then
         call rdedx(vec,lds(isect(46)),iblfcm,ifcm)
         return
      end if
c
c     have failed to find anything
c
      iblfcm = 0
      if (call.ne.'blkfcm') call caserr(' no force constants provided')
c
c        format is same as 'punch' option produces
c
6010  format (1x,3e20.12)
6060  format(/1x,'force constants restored from punch stream')
6070  format(/1x,a8,' force constants restored from ',a8,'dumpfile')
      return
      end
      subroutine fcmout(fc,nc,iw)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
      dimension fc(nc,*),yclab(3)
      data yclab /'   x','   y','   z'/
      write (iw,6070)
      maxn = 0
 20   minn = maxn + 1
      maxn = maxn + 3
      if (maxn.gt.nat) maxn = nat
      write (iw,6010)
      write (iw,6020) (n,n=minn,maxn)
      write (iw,6010)
      write (iw,6030) (zaname(n),n=minn,maxn)
      write (iw,6010)
      write (iw,6040) ((yclab(m),m=1,3),n=minn,maxn)
      write (iw,6010)
      j0 = 3*(minn-1) + 1
      j1 = 3*maxn
      do 30 iat = 1 , nat
         i0 = 3*(iat-1)
         write (iw,6050) iat , zaname(iat) , yclab(1) ,
     +                   (fc(i0+1,j),j=j0,j1)
         write (iw,6060) yclab(2) , (fc(i0+2,j),j=j0,j1)
         write (iw,6060) yclab(3) , (fc(i0+3,j),j=j0,j1)
 30   continue
      if (maxn.lt.nat) go to 20
      return
 6010 format (/)
 6020 format (20x,3(16x,i3,17x))
 6030 format (20x,3(13x,a8,2x,13x))
 6040 format (20x,3(3x,a4,8x,a4,8x,a4,5x))
 6050 format (i3,3x,a8,2x,a4,9f12.8)
 6060 format (16x,a4,9f12.8)
 6070 format (/1x,104('=')//10x,43('=')/10x,
     +        'symmetrized cartesian force',' constant matrix'/10x,
     +        43('='))
      end
      subroutine fgmtrx(core,vec,fc,a,e,rm,ia,b,ncoord)
c
c     ----- subroutine constructs an effective wilson -fg- matrix
c           by introducing mass dependence into the potential force
c           constant matrix.  the normal modes and spectroscopic
c           frequencies are then evaluated.                     -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/phycon)
      common/miscop/p(maxat*3),g(maxat*3),f,p0(maxat*3),g0(maxat*3),f0
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
INCLUDE(common/runopt)
      character*7 fnm
      character*6 snm
      data fnm,snm/'optim.m','fgmtrx'/
      dimension core(*)
      dimension yclab(3),ia(*),vec(ncoord,*),e(*),rm(*),b(*)
      dimension fc(*),a(*)
      data yclab /'   x','   y','   z'/
      data tfact /2.6436411815482d+07/
      nnc = (ncoord*(ncoord+1))/2
c
c ---- set core pointers
c

      i10 = igmem_alloc_inf(nnc + 2*ncoord*ncoord,fnm,snm,'i10',
     &                      IGMEM_DEBUG)
      i20 = i10 + nnc
      i30 = i20 + ncoord*ncoord
c     last = i30 + ncoord*ncoord
c     length = last - i10

      do 20 i = 1 , ncoord
         ia(i) = (i*(i-1))/2
 20   continue
      do 40 i = 1 , ncoord
         do 30 j = 1 , i
            fc(ia(i)+j) = vec(i,j)
 30      continue
 40   continue
c
c     ----- diagonalize cartesian force matrix -----
c
      call dcopy(nnc,fc,1,a,1)
      call gldiag(ncoord,ncoord,ncoord,a,b,e,vec,ia,2)
      write (iwr,6010)
      max = 0
 50   min = max + 1
      max = max + 9
      if (max.gt.ncoord) max = ncoord
      write (iwr,6020)
      write (iwr,6030) (j,j=min,max)
      write (iwr,6020)
      write (iwr,6040) (e(j),j=min,max)
      write (iwr,6020)
      do 60 iat = 1 , nat
         i0 = 3*(iat-1)
         write (iwr,6050) iat , zaname(iat) , yclab(1) ,
     +                   (vec(i0+1,j),j=min,max)
         write (iwr,6060) yclab(2) , (vec(i0+2,j),j=min,max)
         write (iwr,6060) yclab(3) , (vec(i0+3,j),j=min,max)
 60   continue
      if (max.lt.ncoord) go to 50
      ncall = 1
c
c     ----- create full force matrix with mass weighted transformation -
c
 70   call rams(rm,ncall,ncode)
      if (ncode.ne.0) then

         call gmem_free_inf(i10,fnm,snm,'i10')
         return
      else
c
c ----- to force revised vibrational analysis
c
         if (zruntp.ne.'force') then
            do 90 i = 1 , ncoord
               do 80 j = 1 , i
                  ij = ia(i) + j
                  a(ij) = rm(i)*fc(ij)*rm(j)
 80            continue
 90         continue
c
c     ----- get normal modes and frequencies -----
c
            call gldiag(ncoord,ncoord,ncoord,a,b,e,vec,ia,2)
c
c     ----- convert frequencies to inverse cm -----
c
            do 100 i = 1 , ncoord
               e(i) = dsqrt(dabs(tfact*e(i)))
 100        continue
c
c     ----- construct mass wieghted displacement vectors
c           and renormalize them -----
c
            do 110 i = 1 , ncoord
_IFN1(civu)               call vmul(vec(1,i),1,rm,1,vec(1,i),1,ncoord)
_IF1(civ)            do 1 j = 1,ncoord
_IF1(civ)    1       vec(j,i) = vec(j,i)*rm(j)
_IF1(u)            call vvtv(ncoord,vec(1,i),vec(1,i),rm)
 110        continue
            do 120 j = 1 , ncoord
               dum=1.0d0/dnrm2(ncoord,vec(1,j),1)
               call dscal(ncoord,dum,vec(1,j),1)
 120        continue
            write (iwr,6070)
            max = 0
 130        min = max + 1
            max = max + 9
            if (max.gt.ncoord) max = ncoord
            write (iwr,6020)
            write (iwr,6030) (j,j=min,max)
            write (iwr,6020)
            write (iwr,6040) (e(j),j=min,max)
            write (iwr,6020)
            do 140 iat = 1 , nat
               i0 = 3*(iat-1)
               write (iwr,6050) iat , zaname(iat) , yclab(1) ,
     +                         (vec(i0+1,j),j=min,max)
               write (iwr,6060) yclab(2) , (vec(i0+2,j),j=min,max)
               write (iwr,6060) yclab(3) , (vec(i0+3,j),j=min,max)
 140        continue
            if (max.lt.ncoord) go to 130
         end if
      end if
      call dcopy(nnc,fc,1,core(i10),1)
      call vibfrq(nat,mul,ia,p0,ncoord,core(i10),rm,core(i20),core(i30),
     +            vec,b,a,e,toang,iwr)
      ncall = ncall + 1
      go to 70
 6010 format (/10x,47('=')/10x,'eigenvectors of cartesian',
     +        ' force constant matrix'/10x,47('='))
 6020 format (/)
 6030 format (20x,9(4x,i3,5x))
 6040 format (20x,9g12.5)
 6050 format (i3,3x,a8,2x,a4,9f12.8)
 6060 format (16x,a4,9f12.8)
 6070 format (/10x,40('=')/10x,
     +        'normal modes and vibrational frequencies'/10x,40('='))
      end
      subroutine forcx (core)
c
c     ----- subroutine calculates the force constant matrix
c           by differencing the gradient of the potential
c           energy function.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/restar)
INCLUDE(common/restri)
INCLUDE(common/runlab)
INCLUDE(common/infoa)
      common/miscop/p(maxat*3),g(maxat*3),ff,
     +             p0(maxat*3),g0(maxat*3),f0,oskip(maxat)
INCLUDE(common/funct)
INCLUDE(common/vibrtn)
INCLUDE(common/timez)
INCLUDE(common/symtry)
INCLUDE(common/foropt)
INCLUDE(common/scfwfn)
INCLUDE(common/machin)
INCLUDE(common/tran)
      character*7 fnm
      character*5 snm
      data fnm,snm/'optim.m','forxc'/
      dimension core(*)
      dimension d(2)
      data m17,m23/17,23/
      data m24/24/
      data zuhf/'uhf'/
c
c ----- allocate gradient section on dumpfile
c
      nav = lenwrd()
      l3 = num*num
      len3 = lensec(l3)
      lenc = lensec(mach(9))
      nxyz = 3*nat
      nc2 = nxyz*nxyz
      isize = lensec(nc2) + lensec(mach(7))
      call secput(isect(495),m17,isize,ibl3g)
c
      ibl3hs = ibl3g + lensec(mach(7))
      if (nvib.ne.1 .and. nvib.ne.2)
     +    call caserr2('invalid point difference formula in force')
      d(1) = vibsiz
      d(2) = -vibsiz
      write (iwr,6010) nvib , vibsiz
c
c     ----- find which atom will effectively vibrate -----
c
      call vibrat(oskip)
      call rdrec1(ivib,idum,idum,idum,p,p,dum,dum,dum,p,p)
      orstrt = itask(mtask).gt. - 1 .and. ivib.gt.0
      if (.not.orstrt) then
c     ----- fresh start; evaluate function at minimum
c           initialize force constant matrix to zero. -----
c
         icoord = 0
         ivib = 0
         iatom = 0
         enrgy = 0.0d0
         ff = 0.0d0
         f0 = 0.0d0
         call vclr(egrad,1,nxyz)
         call vclr(g,1,nxyz)
         call dcopy(nxyz,c(1,1),1,p(1),1)
c
c ----- allow for /ctrans/ information
c ----- store both 'ctrans' and tdown'ed vectors
         isize = len3*4 + lenc
c
c
c ----- allocate zero order vector section
c
         call secput(isect(498),m24,isize,iblkv0)
         call valfor(core)

         call secget(isect(504),m23,iblk23)
c
c     ----- force original guess on /scfwfn/ -----
c
         call rdedx(cicoef,mach(5),iblk23,idaf)
         f0 = ff
         call dcopy(nxyz,g,1,g0,1)
         call dcopy(nxyz,p,1,p0,1)
         call wrrec1(ivib,iatom,icoord,nvib,g0,p0,f0,vibsiz,ff,g,p)
         if (tim.ge.timlim) return
c
c     ----- calculate force constant matrix -----
c
         call setfcm(nxyz,icoord,g,ivib,core)
         ivib = 1
      else
         call rdrec1(ivib,iatom,icoord,mvib,g0,p0,f0,vibsiz,ff,g,p)
c
c     ----- check for a restart run -----
c
         if (ivib.le.nvib) go to 70
         go to 80
      end if
 20   if (ivib.gt.nvib) then
         do 30 iatom = 1 , nat
            if (.not.oskip(iatom)) go to 40
 30      continue
 40      icoord = 1
         call wrrec1(ivib,iatom,icoord,nvib,g0,p0,f0,vibsiz,ff,g,p)
c
c ---- now restore ground state /ctrans/ information + vectors
c
         itemp = igmem_alloc_inf(l3,fnm,snm,'itemp',IGMEM_NORMAL)
         call secget(isect(498),m24,iblkv0)
         call readi(ilifc(1),mach(9)*nav,iblkv0,idaf)
         iblkv = iblkv0 + lenc
         call rdedx(core(itemp),l3,iblkv,idaf)
         iblkc = ibl3qa - lenc
         call wrt3i(ilifc(1),mach(9)*nav,iblkc,idaf)
         call wrt3(core(itemp),l3,ibl3qa,idaf)
         if (zscftp.eq.zuhf) then
            iblkv = iblkv + len3 + len3
            call rdedx(core(itemp),l3,iblkv,idaf)
            iblkc = ibl3qb - lenc
            call wrt3i(ilifc(1),mach(9)*nav,iblkc,idaf)
            call wrt3(core(itemp),l3,ibl3qb,idaf)
         end if
         call gmem_free_inf(itemp,fnm,snm,'itemp')
         go to 80
      else
         iatom = 1
      end if
 50   if (iatom.gt.nat) then
         ivib = ivib + 1
         go to 20
      else if (oskip(iatom)) then
         iatom = iatom + 1
         go to 50
      else
         icoord = 1
      end if
 60   if (icoord.gt.3) then
         iatom = iatom + 1
         go to 50
      end if
 70   n = 3*(iatom-1) + icoord
      call dcopy(nxyz,p0,1,p,1)
      call dcopy(nxyz,p,1,c(1,1),1)
      p(n) = p0(n) + d(ivib)
      c(icoord,iatom) = p(n)
      call wrrec1(ivib,iatom,icoord,nvib,g0,p0,f0,vibsiz,ff,g,p)
      ntsave = nt
      nt = 1
      call valfor(core)

      nt = ntsave
      if (irest.ne.0 .and. tim.ge.timlim) return
      call setfcm(nxyz,n,g,ivib,core)
      icoord = icoord + 1
      go to 60
c
c     ----- symmetrize force constant matrix -----
c     ----- print force constant matrix -----
c
c     ----- convert to mass weighted coordinates and
c           calculate normal modes and spectroscopic frequencies .
c
 80   continue
c
      call symfcm(core,nprint)
      return
 6010 format (//40x,33('*')/40x,'force constant matrix calculation'/40x,
     +        33('*')//1x,'-',i1,
     +        '-  point difference formula'//' step size = ',f10.5)
      end
      subroutine forend(a,nc,nprint,ip)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension a(nc,*)
      if (nprint.ne.7) return
      do 30 i = 1 , nc
         ic = 0
         max = 0
 20      min = max + 1
         max = max + 5
         ic = ic + 1
         if (max.gt.nc) max = nc
         write (ip,6010) i , ic , (a(i,j),j=min,max)
         if (max.lt.nc) go to 20
 30   continue
      return
 6010 format (i2,i3,5f15.8)
      end
      subroutine fpmain(ci,energ,pool0,h,pool1,exx,gxx,n,
     1           ifail,ioutp,core,delvar,cold,d1var,d2var,d1vold,
     2           fkp,lines,mdone,mtwo,d1doth,d2doth,nprino,iout)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      REAL  mdone,mtwo
INCLUDE(common/sizes)
      dimension core(*),gradg(maxvar)
      dimension mdone(n,n),mtwo(n,n),d1doth(n),d2doth(n)
      dimension pool0(*),pool1(*),delvar(*),cold(*),d1var(*)
      dimension d2var(*),d1vold(*),ci(*)
      dimension exx(200,*),gxx(200,*),h(n,n),fkp(4,*),lines(4,*)
INCLUDE(common/cntl1)
INCLUDE(common/fpinfo)
INCLUDE(common/restar)
      data dzero/0.d0/
      ocnvrg = .false.
      grad = 0.0d0
      ismax = 0
      ifail = 0
      nls = 0
      nftotl = 1
      ffp = energ
      nvarf = n
      do 20 i = 1 , nvarf
         pool0(i) = ci(i)
         d2var(i) = dzero
 20   continue
      call initfp(pool0,pool1,delvar,iout)
      call mnter(energ,grad,ci,nvarf,2,1,fkp,lines,iout)
      fzero = ffp
      k = 0
      modef = 0
      call deriv(pool0,pool1,delvar,d1vold,d1var,d2var,cold,exx,gxx,
     +           gradg,
     +           ioutp,core,fkp,lines,n,iout)
      if(ocnvrg) go to 50
 30   call look(pool0,pool1,d1var,d2var,h,ci,exx,gxx,ioutp,core,fkp,
     +          gradg,lines,n,iout)
      fzero = ffp
      k = k + 1
      nls = nls + 1
      if (nls.ge.mnls) then
         write (iout,6010)
         ifail = 1
         return
      else
         call getrms(pool0,pool1,delvar,d1vold,d1var,d2var,cold,h,
     +             exx,gxx,gradg,ioutp,core,fkp,lines,mdone,mtwo,
     +             d1doth,
     +             d2doth,n,iout)
         if(ocnvrg) go to 50
c
c     *  set up for re-entry into look.  back-transform pool1 and
c     *  d1var into x-space.
c
         do 40 i = 1 , nvarf
            sqrtd2 = dsqrt(d2var(i))
            pool1(i) = pool1(i)/sqrtd2
            d1var(i) = d1var(i)*sqrtd2
 40      continue
         go to 30
      end if
 50   continue
*
* Added to make sure the last energy and coordinates are the minimum
*
c     reset print flag for final ci run
c
      nprint = nprino
      call calcfg(0,n,pool0,energy,gradg,exx,gxx,ioutp,core,
     +            fkp,lines)
      call mnter(energy,0.0d0,d1var,nvarf,1,18,fkp,lines,iout)
      call dcopy(nvarf,pool0,1,ci,1)
      return
 6010 format (/1x,'too many line searches')
      end
      subroutine fptest(pool1,cold,d1var,iout)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension pool1(*),d1var(*),cold(*)
INCLUDE(common/cntl1)
INCLUDE(common/fpinfo)
c
c     *  convergence checks
c
      ocnvrg = .false.
      rmsf = rmsfp(d1var,pool1,cold,nvarf,1)
      write (iout,6010) k , rmsf
      if (rmsf.le.stol) then
         ocnvrg = .true.
         write (iout,6020) k
      end if
      return
 6010 format(/1x,'**FP** at step',i3,' the rms force is ',f8.5,
     +        ' hartree / bohr or / radian')
 6020 format(//1x,44('=')/
     +         1x,'= fletcher-powell optimization terminated  ='/
     +         1x,'= forces below threshold after',i3,' steps    ='/
     +         1x,44('='))
      end
      subroutine getrms(pool0,pool1,delvar,deltab,d1var,
     1                 d2var,deltaz,h,exx,gxx,g,ioutp,
     2                 core,fkp,lines
     3                ,mdone,mtwo,d1doth,hdotd1,ndim,iout)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      REAL  mdone,mtwo
      dimension exx(*),gxx(200,*),core(*),fkp(4,*),lines(4,*)
      dimension pool0(*),pool1(*),delvar(*),d1var(*)
      dimension deltab(*),deltaz(*),d2var(*)
      dimension h(ndim,ndim),mdone(ndim,ndim),mtwo(ndim,ndim)
      dimension d1doth(ndim),hdotd1(ndim),g(*)
INCLUDE(common/cntl1)
INCLUDE(common/fpinfo)
      data dzero,done,rmshi,rmslo/0.d0,1.d0,.16d0,.0010d0/
      do 20 i = 1 , nvarf
         deltaz(i) = pool1(i)
         pool1(i) = pool0(i)
 20   continue
      modef = 1
c
c     *  calculate second derivatives if the rms displacement
c     *  is not between rmslo and rmshi.  if it is too low no progress
c     *  is being made, probably due to bad derivatives and we're at
c     *  at the bottom.  if it is too high we've gdone too far to
c     *  assume that the second derivatives have remained constant.
c
      km1 = k - 1
      rmsd = rmsfp(d1var,pool1,deltaz,nvarf,2)
      write (iout,6030) km1 , k , rmsd
      if (rmsd.lt.rmslo .or. rmsd.gt.rmshi) modef = 0
      if (modef.eq.0) write (iout,6040)
      if (modef.ne.0) write (iout,6050)
      call deriv(pool0,pool1,delvar,deltab,d1var,d2var,deltaz,exx,gxx,
     +           g,ioutp,core,fkp,lines,ndim,iout)
      if (ocnvrg) return
c
c     *  transform pool1 and d1var to ci-space and then evaluate
c     *  deltaz and deltab.
c
      do 30 i = 1 , nvarf
         sqrtd2 = dsqrt(d2var(i))
         pool1(i) = pool1(i)*sqrtd2
         deltaz(i) = deltaz(i)*sqrtd2
         d1var(i) = d1var(i)/sqrtd2
         deltaz(i) = pool1(i) - deltaz(i)
         deltab(i) = d1var(i) - deltab(i)
 30   continue
c
c     *  check to see if this is the first cycle.  if it is, then the
c     *  initial h-matrix must be formed.
c
      if (k.eq.1) then
c
c     *  form the initial h-matrix. (the identity matrix.)
c
         do 50 i = 1 , nvarf
            do 40 j = 1 , nvarf
               h(i,j) = dzero
 40         continue
            h(i,i) = done
 50      continue
      end if
c
c     *  initialize d1doth and hdotd1.
c
      call vclr(hdotd1,1,nvarf)
      call vclr(d1doth,1,nvarf)
c
c     *  now, evaluate d1doth and hdotd1.
c
      do 70 i = 1 , nvarf
         do 60 j = 1 , nvarf
            hdotd1(i) = hdotd1(i) + (h(i,j)*deltab(j))
            d1doth(i) = d1doth(i) + (h(i,j)*deltab(j))
 60      continue
 70   continue
c
c     *  now, evaluate ddotd1 and hbar.
c
      ddotd1 = dzero
      hbar = dzero
      do 80 i = 1 , nvarf
         ddotd1 = ddotd1 + (deltaz(i)*deltab(i))
         hbar = hbar + (deltab(i)*hdotd1(i))
 80   continue
c
c     *  now, put all the information together and evaluate the
c     *  corrective matrices mdone and mtwo and combine themn with
c     *  the old value of h to get h(k+1).
c
      do 100 i = 1 , nvarf
         do 90 j = 1 , nvarf
            mdone(i,j) = (deltaz(i)*deltaz(j))/ddotd1
            mtwo(i,j) = (-hdotd1(i)*d1doth(j))/hbar
            h(i,j) = h(i,j) + mdone(i,j) + mtwo(i,j)
 90      continue
 100  continue
      write (iout,6010) k , ddotd1 , hbar
      write (iout,6020)
      call prsq(h,ndim,ndim,ndim)
      return
 6010 format (1x,'**FP** at step ',i6,' ddotd1 = ',e20.10,
     + ' and hbar = ',e20.10,' ****')
 6020 format (/7x,'********'/
     +         7x,'h-matrix'/
     +         7x,'********'/)
 6030 format (/1x,'**FP** the rms displacement from step',i3,' to',i3,
     + ' is ',f8.5)
 6040 format (1x,'**FP** compute first and second derivatives ****')
 6050 format (1x,'**FP** compute first derivatives ****')
      end
      subroutine grad (g,a)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      dimension g(*),a(*)
      common/restrl/ociopt,ocifor,omp2
      common/reord2/iordd(maxat)
INCLUDE(common/cndx41)
INCLUDE(common/restar)
INCLUDE(common/molsym)
INCLUDE(common/runlab)
INCLUDE(common/phycon)
INCLUDE(common/iofile)
      common/miscop/qst(16,maxvar),qstt(9),
     *title(16),etot,enuc,qx(3),qtot
     *, f(maxat*3),fi(maxvar),nt,ia(maxat)
INCLUDE(common/infoa)
INCLUDE(common/infob)
INCLUDE(common/funct)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
_IF(rpagrad)
INCLUDE(common/rpadcom)
_ENDIF
      character*7 fnm
      character*4 snm
      data fnm,snm/"optim.m","grad"/
c
c ----- ntota holds total no. of atoms including non z-matrix atoms
c
      ntota = nat
      nek = 3*ntota
      call vclr(egrad,1,nek)
c
      if (omp2 .or. mp3) then
         call grmp23(a,egrad)
_IF(rpagrad)
      else if (orpagrad) then
         call drpadr_g(a)
_ENDIF
      else
         call hfgrad(zscftp,a)
      end if
      if (irest.ne.0) return
c
c ----- only interested in first nt gradients
c
c      now transform gradients to z matrix space
c
      write (iwr,6020)
c
c ----- rotate coordinates back and translate
c
      call rotf(nt,tr,egrad,egrad)
      call rotf(nt,tr,c,cat)
      do 20 k = 1 , nt
         cnew(k,1) = cat(1,k) - trx
         cnew(k,2) = cat(2,k) - try
         cnew(k,3) = cat(3,k) - trz
 20   continue
c
c ----- now based on matching coordinates reorder the
c ----- gradients so as to match up with the z-matrix atoms
c
      do 50 i = 1 , nt
         ik = (i-1)*3
         do 30 j = 1 , nt
            jj = j
            jk = (j-1)*3
c
            dot = (cnew(i,1)-f(jk+1))**2 + (cnew(i,2)-f(jk+2))
     +            **2 + (cnew(i,3)-f(jk+3))**2
            if (dabs(dot).lt.1.0d-8) go to 40
 30      continue
         write (iwr,6010) cnew(i,1) , cnew(i,2) , cnew(i,3)
         call caserr2('error detected in gradient transformation')
 40      iordd(jj) = i
         cat(1,jj) = egrad(ik+1)
         cat(2,jj) = egrad(ik+2)
         cat(3,jj) = egrad(ik+3)
 50   continue
      k = 0
      do 60 j = 1 , nt
         f(k+1) = cat(1,j)
         f(k+2) = cat(2,j)
         f(k+3) = cat(3,j)
         k = k + 3
 60   continue
      nparm = 3*nz - 6
      nparm = max(nparm,1)
      idump = 0
c
c ----- assign storage
c

      i10 = igmem_alloc_inf(nparm*nparm,fnm,snm,'g',IGMEM_DEBUG)
      i20 = igmem_alloc_inf(nparm*4*3,fnm,snm,'b',IGMEM_DEBUG)
      i30 = igmem_alloc_inf(nparm*4,fnm,snm,'ib',IGMEM_DEBUG)
      i40 = igmem_alloc_inf(nz*5,fnm,snm,'cxm',IGMEM_DEBUG)
      i50 = igmem_alloc_inf(nz*3,fnm,snm,'cz',IGMEM_DEBUG)
      i60 = igmem_alloc_inf(nt*3,fnm,snm,'cc',IGMEM_DEBUG)
_IFN1(c)      mmax0 = max(nparm,nz)
_IF1(c)c     allow for use of minv rather than minvrt (2*nparm for ll array)
_IF1(c)      mmax0 = max(2*nparm,nz)
      i70 = igmem_alloc_inf(mmax0,fnm,snm,'ll',IGMEM_DEBUG)
      i80 = igmem_alloc_inf(nparm,fnm,snm,'mm',IGMEM_DEBUG)
c - these next 2 were wrong
      i90 = igmem_alloc_inf(nparm,fnm,snm,'igcart',IGMEM_DEBUG)
      i100 = igmem_alloc_inf(mmax0,fnm,snm,'gcart',IGMEM_DEBUG)
      igcpy = igmem_alloc_inf(nparm*(nparm+1)/2,fnm,snm,'gcpy',
     +                        IGMEM_DEBUG)
      igvec = igmem_alloc_inf(nparm*nparm,fnm,snm,'gvec',IGMEM_DEBUG)
      igeig = igmem_alloc_inf(nparm,fnm,snm,'geig',IGMEM_DEBUG)
c
      call mkigcart(maxnz,nz,iz,a(i90),a(i100),nparmz)
c
c     mixed zmatrix/cartesian addition
c
      call formbgxz(maxnz,nz,ianz,iz,bl,alpha,beta,nparm,nparmz,a(i20),
     +      a(i30),a(i10),a(i100),a(i90),a(igcpy),a(igvec),a(igeig),
     +      a(i40),a(i50),a(i60),a(i70),a(i80),idump,ifail)
c
      call gmem_free_inf(igeig,fnm,snm,'geig')
      call gmem_free_inf(igvec,fnm,snm,'gvec')
      call gmem_free_inf(igcpy,fnm,snm,'gcpy')

cc      call ma_summarize_allocated_blocks

c
c ----- output ..
c              a(i20)  -- b matrix  .. 3*4*nparm
c              a(i30)  -- integer part of b-matrix .. 4*nparm
c              a(i10)  -- g-matrix ... nparm*nparm
c
c ----- transform to internal coordinates
c
      call tranfxz(nparm,nparmz,nz,ianz,f,egrad,a(i30),a(i20),
     +             a(i10),a(i100),a(i90),a(i40))

cc      call ma_summarize_allocated_blocks
c
c
c ----- print out internal forces
c
      write (iwr,6020)
c
      call fzprntxz(maxnz,nz,ianz,iz,egrad,iwr)
c
c ----- transform to variable space
c
      call putf(nz,lbl,lalpha,lbeta,nvar,egrad,g,idump)
      call dcopy(nvar,g,1,fi,1)
c
c ----- reset core
c
      call gmem_free_inf(i100,fnm,snm,'gcart')
      call gmem_free_inf(i90,fnm,snm,'igcart')
      call gmem_free_inf(i80,fnm,snm,'mm')
      call gmem_free_inf(i70,fnm,snm,'ll')
      call gmem_free_inf(i60,fnm,snm,'cc')
      call gmem_free_inf(i50,fnm,snm,'cz')
      call gmem_free_inf(i40,fnm,snm,'cxm')
      call gmem_free_inf(i30,fnm,snm,'ib')
      call gmem_free_inf(i20,fnm,snm,'b')
      call gmem_free_inf(i10,fnm,snm,'g')

      return
 6010 format (//1x,'error in grad .... coordinates mismatch'/1x,3e20.10)
 6020 format (//)
      end
      subroutine initfp(pool0,pool1,delvar,iout)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension pool0(*),pool1(*),delvar(*)
INCLUDE(common/cntl1)
INCLUDE(common/fpinfo)
INCLUDE(common/czmat)
INCLUDE(common/csubst)
INCLUDE(common/phycon)
      data delstr,delbnd/0.01d0,1.0d0/
      data done,f45/1.d0,45.d0/
      if (nvarf.le.0 .or. nvarf.gt.30) then
         write (iout,6010) nvarf
         call caserr2('too many variables for minimisation')
      end if
c     init some variables.
c
      do 20 i = 1 , nvarf
         pool0(i) = values(i)
         pool1(i) = values(i)
 20   continue
c
c     set the step sizes.
c
      antoau = done/toang(1)
      torad = datan(done)/f45
      do 50 i = 1 , nvarf
         do 30 j = 2 , nz
            if (iabs(lbl(j)).eq.i) then
               delvar(i) = delstr*antoau
               if (intvec(i).ne.0) delvar(i) = fpvec(i)*antoau
               go to 50
            end if
 30      continue
         do 40 j = 3 , nz
            if (iabs(lalpha(j)).eq.i .or. iabs(lbeta(j)).eq.i) then
               delvar(i) = delbnd*torad
               if (intvec(i).ne.0) delvar(i) = fpvec(i)*torad
               go to 50
            end if
 40      continue
         call caserr2('error in fletcher powell optimisation')
 50   continue
      return
 6010 format (' nvar invalid range in fletcher powell, nvar= ',i10)
      end
      subroutine inveig(hes,vec,n,eig,eigmin,eigmax,ineg,ird,iout)
c
c ----- inverts hes by diagonalisation
c ----- the inverse matrix is allowed ineg negative roots
c ----- if more than ineg are found then the smallest
c ----- absolute eigen values are changed to their absolute value.
c ----- further more the absolute values must lie in the range
c ----- eigmin,eigmax.
c ----- hes and vec can be called with the same address
c ----- entry diaeig is the same but no inversion is done
c        ird=0  eigenvalues are in 2nd derivative order
c        ird=1  eigenvalues are for inverse matrix so reorder
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension hes(n,n),eig(*),vec(n,n)
      common/blkin/tmp(1)
      ientry = 1
      go to 20
      entry diaeig(hes,vec,n,eig,eigmin,eigmax,ineg,ird,iout)
      ientry = 2
 20   if = 0
      call eigen(hes,n,n,eig,vec,tmp,if)
      if (ird.ne.0) then
c
c   how many -ve roots?
c
         nneg = 0
         do 30 i = 1 , n
            if (eig(i).gt.0.0d0) go to 40
            nneg = nneg + 1
 30      continue
 40      npos = n - nneg
c
c    invert order of -ve roots
c
         no2 = nneg/2
         m = nneg + 1
         if (no2.gt.0) then
            do 50 i = 1 , no2
               m = m - 1
               t = eig(i)
               eig(i) = eig(m)
               eig(m) = t
_IF1(uv)            do 150 j=1,n
_IF1(uv)            t=vec(j,i)
_IF1(uv)            vec(j,i)=vec(j,m)
_IF1(uv)            vec(j,m)=t
_IF1(uv)  150       continue
_IFN1(uv)             call dswap(n,vec(1,i),1,vec(1,m),1)
 50         continue
         end if
c
c    invert order of +ve roots
c
         no2 = npos/2
         m = n + 1
         i = nneg
         if (no2.gt.0) then
            do 60 ii = 1 , no2
               m = m - 1
               i = i + 1
               t = eig(i)
               eig(i) = eig(m)
               eig(m) = t
_IF1(uv)               do 160 j=1,n
_IF1(uv)               t=vec(j,i)
_IF1(uv)               vec(j,i)=vec(j,m)
_IF1(uv)  160          vec(j,m)=t
_IFN1(uv)               call dswap(n,vec(1,i),1,vec(1,m),1)
 60         continue
         end if
      end if
c
c ---- test eigen values
c
c     icont = 0
c
      if (ineg.ge.0) then
         do 70 i = 1 , n
            rx = eig(i)
            rd = dabs(eig(i))
            if (eig(i).lt.0.0d0 .and. i.gt.ineg) eig(i) = rd
            if (dabs(eig(i)).gt.eigmax) eig(i) = dsign(eigmax,eig(i))
            if (dabs(eig(i)).lt.eigmin) eig(i) = dsign(eigmin,eig(i))
            if (rx.ne.eig(i)) then
               write (iout,6010) i , rx , eig(i)
            end if
 70      continue
      end if
c
c ---- now in invert
c
      if (ientry.eq.1) then
         do 80 i = 1 , n
            eig(i) = 1.0d0/eig(i)
 80      continue
      end if
      do 120 i = 1 , n
         do 100 j = i , n
            rx = 0.0d0
            do 90 k = 1 , n
               rx = rx + vec(i,k)*vec(j,k)*eig(k)
 90         continue
            tmp(j) = rx
 100     continue
         do 110 j = i , n
            hes(i,j) = tmp(j)
 110     continue
 120  continue
      do 140 i = 1 , n
         do 130 j = 1 , i
            hes(i,j) = hes(j,i)
 130     continue
 140  continue
      return
 6010 format (1x,'inveig....root ',i3,1x,e14.7,
     +        ' has been constrained  ',e14.7)
      end
      subroutine linesf(f,p,step,grad,esth,c,g,hes,exx,gxx,nvar,nhes,
     * func,ifail,ioutp,core,fkp,lines,iout)
c
c ---- this routine performs the line search for a minimum
c ---  function in f(x)
c ---- f   is the function value
c ---- x   is the parameter value
c ---- step is the estimated step
c ---- grad is the gradient of f(x)
c ---- esth is the estimated hessian of f(x)
c ---- c    are the current variable values
c ---- g    are the gradients of the variables
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      external func
INCLUDE(common/sizes)
      parameter (mxvar2 = maxvar+maxvar)
      parameter (mvar10 = maxvar*10    )
      dimension c(*),g(*),hes(nvar,nvar),core(*)
      dimension fkp(4,*),lines(4,*)
      dimension exx(200,*),gxx(200,*)
      dimension tx(3),tf(3),tg(3)
INCLUDE(common/prints)
INCLUDE(common/cntl1)
_IF(taskfarm)
INCLUDE(common/taskfarm)
_ENDIF
      common/miscop/qst(mvar10),gx1(maxvar),gx2(maxvar),cx1(maxvar),
     *cx2(maxvar),sfun2c(mxvar2),p1,p2,p3,f1,f2,f3,g1,g2,g3
      equivalence (p1,tx(1)) , (f1,tf(1)) , (g1,tg(1))
      folx = f
      tolx = dabs(step)*acc
      pb1 = p
      fb1 = f
      sgn1 = step/dabs(step)
      pb2 = sgn1*1.0d13
      fb2 = 1.0d13
      ityp = ismax + 2
      ikp1 = nls + 1
c     nhalf = 0
c     cutoff = 1.0d-12
      nstep = 0
      ifail = 0
      f1 = f
      p1 = p
      g1 = grad
      do 20 k = 1 , nhes
         cx1(k) = c(k)
         cx2(k) = c(k)
         gx1(k) = g(k)
         gx2(k) = g(k)
 20   continue
c
c ---- since we don't know any better take the suggested step
c
      if (ioutp.ne.0) write (ioutp,6040) ikp1 , nstep , nftotl , p1 ,
     +                       f1 , g1
      p2 = p + step
      call func(0,nhes,p2,f2,g2,c,g,hes,exx,gxx,ioutp,core,fkp,lines)
      p4 = p2
      f4 = f2
      call mnter(f4,p2,g,nhes,1,ityp,fkp,lines,iout)
      nftotl = nftotl + 1
      if (nftotl.ge.jm) then
         write (iout,6010)
         ifail = 1
         return
      else
         if (oprint(44) .and. ioutp.ne.0) write (ioutp,6020) p1 , p2 , 
     +       f1 , f2 , g1
         aa = (-g1*(p1-p2)+f1-f2)/(p1*p1-p2*p2-2.0d0*p1*(p1-p2))
         bb = g1 - 2.0d0*aa*p1
         cc = f1 - aa*p1*p1 - bb*p1
         if (oprint(44) .and. ioutp.ne.0) write (ioutp,6030) 
     +       aa , bb , cc
         nstep = nstep + 1
         g2 = 2.0d0*aa*p2 + bb
         if (ioutp.ne.0) write (ioutp,6040) ikp1 , nstep , nftotl , p2 ,
     +                          f2 , g2
         if (f2.gt.fb1) pb2 = p2
         if (f2.gt.fb1) fb2 = f2
c
c ----- quadratic has wrong curvature
c
         if (aa.gt.0.0d0) then
            cmin = -bb/(aa+aa)
            ityp = ismax + 2
c
c ----- check that the step is not too long
c
            if (dabs(g2/grad).lt.acc) go to 90
            if ((cmin-p1)/step.gt.2.0d0) cmin = p1 + 2.0d0*step
         else
            if (f2.ge.f1) step = step*0.5d0
            if (f2.lt.f1) step = 2.0d0*step
            cmin = p1 + step
c
c    ----- prevent atoms clashing during search for maximum
c
            ityp = 6
c
            if (ismax.eq.1 .and. lqstyp.ge.3 .and. nls.gt.0 .and.
     +          f4.lt.folx) go to 90
         end if
      end if
      p3 = cmin
      if (sgn1.le.0.0d0 .or. p3.le.pb1 .or. p3.ge.pb2) then
c
c ---- quadratic interpolation outside the bounds
c
         if (sgn1.ge.0.0d0 .or. p3.ge.pb1 .or. p3.le.pb2) then
            step = step*0.5d0
            p3 = p1 + step
            ityp = 7
         end if
      end if
c
c ----- calculate the 3rd function value
c
      call func(0,nhes,p3,f3,g3,c,g,hes,exx,gxx,ioutp,core,fkp,lines)
      nftotl = nftotl + 1
      if (f3.gt.fb1 .and. f3.lt.fb2) pb2 = p3
      if (f3.gt.fb1 .and. f3.lt.fb2) fb2 = f3
      p4 = p3
      f4 = f3
c
c ----- order the points so that x1<x2<x3
c
      call mnter(f4,p4,g,nhes,1,ityp,fkp,lines,iout)
 30   do 50 k = 1 , 2
         kp1 = k + 1
         do 40 l = kp1 , 3
            if (sgn1.le.0.0d0 .or. tx(k).ge.tx(l)) then
               if (sgn1.ge.0.0d0 .or. tx(k).lt.tx(l)) then
                  t = tx(k)
                  tx(k) = tx(l)
                  tx(l) = t
                  t = tf(k)
                  tf(k) = tf(l)
                  tf(l) = t
                  t = tg(k)
                  tg(k) = tg(l)
                  tg(l) = t
               end if
            end if
c
c ---- reset bounds
c
 40      continue
 50   continue
      if (f3.gt.f2 .and. f3.lt.fb2) pb2 = p3
      if (f3.gt.f2 .and. f3.lt.fb2) fb2 = f3
      if (f1.gt.f2 .and. f1.lt.fb1) pb1 = p1
      if (f1.gt.f2 .and. f1.lt.fb1) fb1 = f1
      if (ioutp.ne.0) write (ioutp,6050) pb1 , fb1 , pb2 , fb2
      if (oprint(44) .and. ioutp.ne.0) write (ioutp,6060) p1 , p2 , p3 ,
     +    f1 , f2 , f3
      aa = ((f1-f2)*(p2-p3)-(f2-f3)*(p1-p2))/((p1-p3)*(p2-p3)*(p1-p2))
      bb = (f1-f2)/(p1-p2) - aa*(p1+p2)
      cc = f1 - aa*p1*p1 - bb*p1
      if (oprint(44) .and. ioutp.ne.0) write (ioutp,6030) aa , bb , cc
      nstep = nstep + 1
      g4 = 2.0d0*aa*p4 + bb
      if (ioutp.ne.0) write (ioutp,6040) ikp1 , nstep , nftotl , p4 ,
     +                       f4 , g4
c
c ----- quadratic fit no good
c
      if (aa.gt.0.0d0) then
         cmin = -bb/(aa+aa)
         ityp = ismax + 2
c
c ----- check that the step is not too long
c
         if (dabs(g4/grad).lt.acc) go to 90
      else
         step = p3 - p1
         cmin = p3 + (p3-p1)
c
c     ----- prevent atoms clashing during search for maximum
c
         ityp = 6
         if (ismax.eq.1 .and. lqstyp.ge.3 .and. nls.gt.0 .and.
     +       f4.lt.folx) go to 90
      end if
c
c ----- check on possible alternative convergence
c
      if ((cmin-p4)/step.gt.2.0d0) cmin = p4 + 2.0d0*step
c
c ----- may need to increase the step size
c
      if (f4.lt.folx .and. dabs(p4-cmin).lt.tolx) go to 90
      if ((cmin-p4)/step.gt.1.0d0) step = cmin - p4
      p4 = cmin
      if (sgn1.le.0.0d0 .or. p4.le.pb1 .or. p4.ge.pb2) then
c
c ---- quadratic interpolation useless as outside bounds
c
         if (sgn1.ge.0.0d0 .or. p4.ge.pb1 .or. p4.le.pb2) then
            p4 = p2
            f4 = f2
            call func(3,nhes,p4,f4,g4,c,g,hes,exx,gxx,ioutp,core,fkp,
     +                lines)
            call mnter(f4,p4,g,nhes,3,ityp,fkp,lines,iout)
            g2 = g4
            if (dabs(g2/grad).lt.acc) go to 90
            if (g4*grad.gt.0.0d0) pb1 = p4
            if (g4*grad.gt.0.0d0) fb1 = f4
            if (g4*grad.le.0.0d0) pb2 = p4
            if (g4*grad.le.0.0d0) fb2 = f4
            p4 = (pb1+pb2)*0.5d0
            ityp = 7
         end if
      end if
c
c ---- calculate the 4th function value
c
      call func(0,nhes,p4,f4,g4,c,g,hes,exx,gxx,ioutp,core,fkp,lines)
      call mnter(f4,p4,g,nhes,1,ityp,fkp,lines,iout)
c
c ---- now we have 4 function and need to get rid of one
c ---- how            ???
c ---- does x4 lie between x1 and x2 ?
c
      nftotl = nftotl + 1
      if (p4.le.p1 .or. p4.ge.p2) then
c
c ---- does x4 lie between x2 and x3
c
         if (p4.ge.p1 .or. p4.le.p2) then
            if (p4.gt.p2 .and. p4.lt.p3) go to 70
c
c ---- check that it does lie beyond x1,x2,x3
c
            if (p4.lt.p2 .and. p4.gt.p3) go to 70
            if (p4.gt.p1 .and. p4.gt.p2 .and. p4.gt.p3) go to 70
c
c ---- linear search is having problems]]]]
c
            if (p4.lt.p1 .and. p4.lt.p2 .and. p4.lt.p3) go to 70
            write (iout,6070)
            ifail = 1
_IF(taskfarm)
            itaskret = 1
_ENDIF
c
c ----- a succesful search
c
            return
         end if
      end if
      if (f4.gt.f2) go to 80
 60   p3 = p4
      f3 = f4
c
c ---- x4 lies between x2 and x3
c ---- or we are extrapolating...
c
      g3 = g4
      go to 30
 70   if (f4.gt.f2) go to 60
 80   p1 = p4
      f1 = f4
c
c ----- failure in linear search
c
      g1 = g4
      go to 30
 90   p = p4
      f = f4
      call func(3,nhes,p,f,grad,c,g,hes,exx,gxx,ioutp,core,fkp,lines)
      call mnter(f,p,g,nhes,3,ityp,fkp,lines,iout)
      esth = 2.0d0*aa
      if (ioutp.ne.0) write (ioutp,6080) f , p , grad , esth
      return
 6010 format (//1x,'too many function evaluations'//)
 6020 format (/1x,'quadratic fit to the following'/1x,'x1, x2,    ',
     +        2(1x,e14.7)/1x,'f1, f2,    ',2(1x,e14.7)/1x,'g1,        ',
     +        2(1x,e14.7))
 6030 format (/1x,'linear search....quadratic fit a*x*x + b*x +c',
     +        3(1x,e14.7))
c
c ----- check that second derivative is correct
c
 6040 format (/1x,'linear search ',i2,' function call ',2i4,' step ',
     +        e14.7,1x,'function ',e14.7,' approximate derivative ',
     +        e14.7)
c
c ----- fit a quadratic function to just the function values
c
 6050 format (/1x,'current bounds are:',4e20.10)
 6060 format (/1x,'quadratic fit to the following'/1x,'x1, x2, x3,',
     +        3(1x,e14.7)/1x,'f1, f2, f3,',3(1x,e14.7))
 6070 format (//1x,'=================================================='/
     +        'linear search....negative step, curvature all wrong'/1x,
     +        '=================================================='//)
 6080 format (/1x,25('=')/1x,'linear search....complete....f= ',e14.7,
     +        ' x= ',e14.7,' gradx= ',e14.7,' esth= ',e14.7/1x,25('='))
      end
      subroutine linesg(f,p,step,grad,esth,c,g,hes,exx,gxx,nvar,nhes,
     * func,ifail,ioutp,core,fkp,lines,iout)
c ---- this routine performs the line search for a minimum
c ---  function in f(x)
c ---- f   is the function value
c ---- x   is the parameter value
c ---- step is the estimated step
c ---- grad is the gradient of f(x)
c ---- esth is the estimated hessian of f(x)
c ---- c    are the current variable values
c ---- g    are the gradients of the variables
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      external func
INCLUDE(common/sizes)
      dimension c(*),g(*),hes(nvar,nvar),core(*)
      dimension fkp(4,*),lines(4,*)
      dimension exx(200,*),gxx(200,*)
INCLUDE(common/cntl1)
_IF(taskfarm)
INCLUDE(common/taskfarm)
_ENDIF
      common/miscop/cmin1(maxvar),cmin2(maxvar),
     1     coefb(maxvar),coefc(maxvar),coefd(maxvar),coefe(maxvar)
     2 ,tangen(4,maxvar),gx1(maxvar),gx2(maxvar),cx1(maxvar),cx2(maxvar)
     3,sfun2c(2,maxvar),p1,p2,p3,f1,f2,f3,g1,g2,g3
c
c ----- make sure the initial gradient is -ve
c
      folx = f
      tolx = dabs(step)*acc
      ityp = ismax + 2
      ikp1 = nls + 1
      pgrad = 1.0d0
      if (grad.gt.0.0d0) pgrad = -1.0d0
      gradx = grad*pgrad
      nhalf = 0
      nstep = 0
      ifail = 0
c     cutoff = 1.0d-12
      f1 = f
      f2 = f
      p1 = p
      p2 = p
      g1 = gradx
      g2 = gradx
      do 20 k = 1 , nhes
         cx1(k) = c(k)
         cx2(k) = c(k)
         gx1(k) = g(k)
         gx2(k) = g(k)
 20   continue
c
c ---- since we don't know any better take the suggested step
c
      if (ioutp.ne.0) write (ioutp,6010) ikp1 , nstep , nftotl , p1 ,
     +                       f1 , g1
      p3 = p + step
 30   call func(0,nhes,p3,f3,g3,c,g,hes,exx,gxx,ioutp,core,fkp,lines)
      nftotl = nftotl + 1
      if (nftotl.ge.jm) go to 60
      call func(3,nhes,p3,f3,g3,c,g,hes,exx,gxx,ioutp,core,fkp,lines)
      call mnter(f3,p3,g,nhes,2,ityp,fkp,lines,iout)
      g3 = g3*pgrad
      nstep = nstep + 1
      if (ioutp.ne.0) write (ioutp,6010) ikp1 , nstep , nftotl , p3 ,
     +                       f3 , g3
      if (dabs(g3/gradx).le.acc) go to 50
      if (isadle.ne.1) then
         if (ismax.eq.1) then
c
c ----- for saddle check we are not falling off the ridge
c
            if (g3.le.0.0d0) then
               call testan(c,g,test,nhes,iflag,ifail,ioutp,iout)
               if (ifail.ne.0) return
c
c ---- might have known it....try a quadratic fit
c
               if (iflag.ne.0) go to 50
            end if
         end if
      end if
      p2 = p3
      f2 = f3
      g2 = g3
 40   ityp = ismax + 2
      hs = g2 - g1
c
c ---- check the 2nd derivative
c
      aa = 0.5d0*hs/(p2-p1)
      if (hs.ge.0.0d0) then
         bb = g1 - 2.0d0*aa*p1
         cmin = -bb*0.5d0/aa
         scale = (p1-cmin)/(p1-p2)
         if (scale.gt.2.0d0) cmin = p1 - 2.0d0*(p1-p2)
         p3 = cmin
         call func(0,nhes,p3,f3,g3,c,g,hes,exx,gxx,ioutp,core,fkp,lines)
         nftotl = nftotl + 1
         if (nftotl.ge.jm) go to 60
         call func(3,nhes,p3,f3,g3,c,g,hes,exx,gxx,ioutp,core,fkp,lines)
         call mnter(f3,p3,g,nhes,2,ityp,fkp,lines,iout)
         g3 = g3*pgrad
         nstep = nstep + 1
         if (ioutp.ne.0) write (ioutp,6010) ikp1 , nstep , nftotl , p3 ,
     +                          f3 , g3
c
c ----- check for alternative convergence criteria
c
         if (dabs(g3/gradx).le.acc) go to 50
         if (f3.lt.folx .and. dabs(step).lt.tolx) go to 50
         if (isadle.ne.1) then
            if (ismax.eq.1) then
c
c ----- for saddle check we are not falling off the ridge
c
               if (g3.le.0.0d0) then
                  call testan(c,g,test,nhes,iflag,ifail,ioutp,iout)
                  if (ifail.ne.0) return
c
c ----- we can discard a point. but we want to
c ----- keep a bracket on the minimum. if poss
c
                  if (iflag.ne.0) go to 50
               end if
            end if
         end if
      else
         ityp = 6
c
c ----- replace point 1 with the latest point
c
         p3 = p1 + (p2-p1)*3.0d0
         f1 = f2
         g1 = g2
         p1 = p2
         write (ioutp,6020)
         nhalf = nhalf + 1
         if (nhalf.lt.4) go to 30
         write (ioutp,6030)
         ifail = 1
         write (iout,6040)
         ifail = 1
_IF(taskfarm)
         itaskret = 1
_ENDIF
c
c ----- a succesful search
c
         return
      end if
      if (g3.gt.0.0d0) then
         if (g2.le.0.0d0) then
c
c ----- point 1 can be replaced point 2
c
            if (g2.ge.g1) then
               f1 = f2
               g1 = g2
               p1 = p2
            end if
         end if
         f2 = f3
         g2 = g3
         p2 = p3
c
c ----- failure in linear search
c
         step = p2 - p1
c
c ----- discard point 1
c
      else if (g2.lt.0.0d0 .and. g2.gt.g1) then
         f1 = f2
         g1 = g2
         p1 = p2
         f2 = f3
         g2 = g3
         p2 = p3
c
c ----- discard point 2
c
         step = p2 - p1
      else
         f1 = f3
         g1 = g3
         p1 = p3
c
c ---- have to exchange points 1 and 2  and   2 and 3
c
         step = p2 - p1
      end if
      go to 40
 50   g1 = g1*pgrad
      g2 = g2*pgrad
      g3 = g3*pgrad
      gradx = gradx*pgrad
      esth = (g3-gradx)/(p3-p)
      step = p3 - p
      f = f3
      p = p3
      grad = g3
      if (ioutp.ne.0) write (ioutp,6050) f , p , grad , esth
c
c ---- interchange x1 and x2
c
      if (dabs(p1-p3).lt.dabs(p2-p3)) then
         t = p1
         p1 = p2
         p2 = t
         t = f1
         f1 = f2
         f2 = t
         t = g1
         g1 = g2
         g2 = t
      end if
      return
 60   write (iout,6060)
      ifail = 1
      return
c
c ---- if we are optimistic test now for convergence
c
 6010 format (/1x,'linear search ',i2,' function call ',2i4,' step ',
     +        e14.7,1x,'function ',e14.7,' gradient ',e14.7)
 6020 format (//1x,
     +        '*** warning - i''m  afraid i am doubling the step length'
     +        /'               because the 2nd derivative is negative'/)
 6030 format (/1x,
     +        '*** warning - i can''t find a turning point along here'//
     +        )
 6040 format (//1x,'=================================================='/
     +        'linear seach....negative step, curvature all wrong'/1x,
     +        '=================================================='//)
c
c ----- reorganise x1,x2,x3 etc. so that they are in order
c
 6050 format (/1x,25('=')/1x,'linear search....complete....f= ',e14.7,
     +        ' x= ',e14.7,' gradx= ',e14.7,' esth= ',e14.7/1x,25('='))
 6060 format (//1x,'too many function evaluations'//)
      end
      subroutine look(pool0,pool1,d1var,d2var,h,ci,exx,gxx,ioutp,
     1                core,fkp,g,lines,ndim,iout)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension exx(*),gxx(200,*),core(*),fkp(4,*),lines(4,*)
      dimension pool0(*),pool1(*),d1var(*),d2var(*),h(ndim,ndim),ci(*)
      dimension g(*)
INCLUDE(common/prints)
INCLUDE(common/cntl1)
INCLUDE(common/fpinfo)
      data done,two/1.d0,2.d0/
c
c     *  first entry... transform first derivatives and pool1 to
c     *  ci-space.
c
      do 20 i = 1 , nvarf
         sqrtd2 = dsqrt(d2var(i))
         d1var(i) = d1var(i)/sqrtd2
         pool1(i) = pool1(i)*sqrtd2
 20   continue
c
c     *  set the increment counter lamba.
c
      lamba = 1
c
c     *  if this is the first fletcher-powell cycle, h has not been
c     *  formed, and is assumed to be i (the identity matrix).
c
      if (k.ne.0) then
c
c     *  h-matrix is available.  set ci(i)=-h(i,j)*d1var(i).
c     *  but first, it is necessary to zero the array ci.
c
         call vclr(ci,1,nvarf)
c
c     *  then, carry out the actual scaler product of h(i,j) and the
c     *  derivatives.
c
         do 40 i = 1 , nvarf
            do 30 j = 1 , nvarf
               ci(i) = ci(i) - (h(i,j)*d1var(j))
 30         continue
 40      continue
      else
c
c     *  if k=1, however, simply set ci equal to -1.*d1var.
c
         do 50 i = 1 , nvarf
            ci(i) = -d1var(i)
 50      continue
      end if
c
c     *  now, set up pool0 (in ci-space) according to ci.
c
 60   rlamba = dfloat(lamba)
      do 70 i = 1 , nvarf
         pool0(i) = pool1(i) + rlamba*ci(i)
 70   continue
c
c     *  back transform pool0 into x-space and call value.
c
      do 80 i = 1 , nvarf
         pool0(i) = pool0(i)/(dsqrt(d2var(i)))
 80   continue
      call calcfg(0,ndim,pool0,energy,g,exx,gxx,ioutp,core,fkp,lines)
      call mnter(energy,rlamba,d1var,nvarf,2,16,fkp,lines,iout)
      ffp = energy
c
c     *  get the value of the function from common/fpinfo/ and
c     *  pack it into the function save array according to the
c     *  value of lamba.
c
      f1(lamba) = ffp
c
c     *  increment lamba.
c
      lamba = lamba + 1
      if (lamba.le.2) go to 60
c
c     *  conduct a parabolic fit to determine alphf.
c
      alphf = done - (f1(2)-fzero)/(two*(f1(2)+fzero-two*f1(1)))
      write (iout,6010) alphf
c
c     *  set up pool0 according to alphf from pool1.
c
      do 90 i = 1 , nvarf
         pool0(i) = pool1(i) + alphf*ci(i)
 90   continue
c
c     *  back transform pool1 and pool0.
c
      do 100 i = 1 , nvarf
         sqrtd2 = dsqrt(d2var(i))
         pool0(i) = pool0(i)/sqrtd2
         pool1(i) = pool1(i)/sqrtd2
 100  continue
c
c     *  call value to get the fzero.
c
c
      call calcfg(0,ndim,pool0,energy,g,exx,gxx,ioutp,core,fkp,lines)
      call mnter(energy,alphf,d1var,nvarf,2,17,fkp,lines,iout)
      ffp = energy
      return
 6010 format (/1x,'**FP** after extrapolation, alpha = ',e20.10)
      end
      subroutine ltout(iout,n,a,key)
      implicit REAL  (a-h,o-z)
c
c     working precision routine to print out the lower triangular part
c     of a symmetric matrix stored in compressed lower triangular form.
c
c        n         dimension of matrix.
c        a         array to be printed.
c        key       0 ... suppress elements with absolute values less
c                        than thresh (see data statement).
c                  1 ... print complete matrix.
c
      dimension a(*), s(9)
      data thresh/1.0d-6/, zero/0.0d0/, numcol/5/
      lind(i,j) = (max(i,j)*(max(i,j)-1)/2) + min(i,j)
c
      istart = 1
 20   if (istart.gt.n) return
      iend = min(istart+numcol-1,n)
      write (iout,6010) (ir,ir=istart,iend)
      do 40 irow = istart , n
         irange = min(irow-istart+1,numcol)
         call dcopy(irange,a(lind(irow,istart)),1,s,1)
         do 30 ir = 1 , irange
            if (key.eq.0 .and. dabs(s(ir)).lt.thresh) s(ir) = zero
 30      continue
         write (iout,6020) irow , (s(ir),ir=1,irange)
 40   continue
      istart = istart + numcol
      go to 20
 6010 format (5(11x,i3))
 6020 format (i4,9d14.6)
      end
      subroutine ltoutd(n,a,key)
      implicit REAL  (a-h,o-z)
c
c     symmetric matrix output routine ... see ltout for details.
c
      dimension a(*)
INCLUDE(common/iofile)
      call ltout(iwr,n,a,key)
      return
      end
      subroutine makdx(p,q,nc,a)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/gmempara)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/segm)
      character*7 fnm
      character*5 snm
      data fnm,snm/'optim.m','makdx'/
      dimension p(*),q(*),a(*)
      data dzero /0.0d0/
      nc2 = (nc*(nc+1))/2
c
c     ----- get core memory -----
c
      i10 = igmem_alloc_inf(nc2,fnm,snm,'i10',IGMEM_DEBUG)

      call rdedx(a(i10),nc2,ibl3hs,idaf)
      do 30 i = 1 , nc
         dum = dzero
         do 20 j = 1 , nc
            ii = max(i,j)
            jj = min(i,j)
            ij = (ii*(ii-1))/2 + jj + i10 - 1
            dum = dum + a(ij)*p(j)
 20      continue
         q(i) = dum
 30   continue
c
c     ----- reset core memory -----
c
      call gmem_free_inf(i10,fnm,snm,'i10')
      return
      end
      subroutine matpri(x,m,n,mm,nn,iout)
      implicit REAL  (a-h,o-z)
c
c     matrix print routine.
c
      dimension x(m,n)
c
      ilower = 1
 20   if (ilower.gt.nn) return
      iupper = min(ilower+4,nn)
      write (iout,6010) (j,j=ilower,iupper)
      do 30 i = 1 , mm
         write (iout,6020) i , (x(i,j),j=ilower,iupper)
 30   continue
      ilower = iupper + 1
      go to 20
 6010 format (8(10x,i3))
 6020 format (i4,8d13.6)
      end
      subroutine mindum(cx,gg,nvar)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/machin)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/cntl1)
INCLUDE(common/cntl2)
c
      dimension cx(200,*),gg(200,*)
      call wrt3(accd,mach(1),ibl3op,idaf)
      iblm2 = ibl3op + lensec(mach(1))
      call wrt3(en,mach(10),iblm2,idaf)
      iblm3 = iblm2 + lensec(mach(10))
      mword = 200*nvar
      nvarb = lensec(mword)
      call wrt3(cx,mword,iblm3,idaf)
c
      iblm4 = iblm3 + nvarb
      call wrt3(gg,mword,iblm4,idaf)
c     revise restart block also
      itask(mtask) = irest
      call revise
c
      return
      end
      subroutine minit(hes)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      parameter (mvar10 = maxvar*10)
INCLUDE(common/seerch)
INCLUDE(common/restar)
INCLUDE(common/restri)
INCLUDE(common/restrj)
INCLUDE(common/prints)
INCLUDE(common/prnprn)
INCLUDE(common/cntl1)
INCLUDE(common/cntl2)
INCLUDE(common/machin)
INCLUDE(common/restrl)
INCLUDE(common/discc)
      common /miscop/cmin1(maxvar),cmin2(maxvar),
     +      coefb(maxvar),coefc(maxvar),coefd(maxvar),coefe(maxvar),
     +      coefsp(mvar10),spppp(31),fspa(maxat*3),
     +      fspaa(maxvar),nt,ia(maxat)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
INCLUDE(common/cndx41)
      common/czmat/ianz(maxnz),iz(maxnz,4),bl(maxnz),alpha(maxnz)
     *,beta(maxnz),lbl(maxnz),lalpha(maxnz),lbeta(maxnz),nz,nvar
INCLUDE(common/csubst)
      common/memlb/iamhes
INCLUDE(common/modj)
INCLUDE(common/structchk)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
_ENDIF
      character*7 fnm
      character*5 snm
      data fnm,snm/'optim.m','minit'/
      common/hmat/o_hmat
      dimension accu(6),zcas(3)
      dimension hes(*)
       equivalence (accu(1),acc)
      data m80/80/
      data zprop,zcas/'prop','casscf','mcscf','vb'/
      data m17/17/
      natoms = nat
      nprino = nprint
      go to (20,40,30,50,60,70) , isadle
 20   write (iwr,6100)
      go to 80
 30   write (iwr,6110)
      go to 80
 40   write (iwr,6120)
      go to 80
 50   write (iwr,6130)
      go to 80
 60   write (iwr,6140)
      go to 80
 70   write (iwr,6150)
c
 80   if (nvar.lt.1 .or. nvar.gt.maxvar) then
         call caserr2('invalid number of variables in z-matrix.')
      end if
 90   if (nvar.eq.1 .and. (isadle.eq.3 .or. isadle.eq.5)) then
         call caserr2('invalid number of variables in z-matrix.')
         go to 90
      else
c
         ioutp = iwr
         if (maxat.lt.nat) call caserr2(
     +               'invalid number of atoms in optimisation')
         do 100 i = 1 , 200
            ierec(i) = -1
            igrec(i) = -1
 100     continue
c
c     ------- allocate storage
c
         n = nvar
         nvar2 = n*n
         nvar60 = nvar*200
         nvarb = lensec(nvar60)
         nvarh = lensec(nvar2)
         lenh = lensec(mach(1)) + lensec(mach(10)) + nvarb + nvarb

         i10=0
         i20 = i10 + nvar2
         i30 = i20 + nvar2
         i40 = i30 + nvar2
         i50 = i40 + nvar60
         iix = i50 + nvar60
         iig = iix + maxvar
         isp1 = iig + maxvar
         isp2 = isp1 + maxvar
         isp3 = isp2 + maxvar
         isp4 = isp3 + maxvar
         isp5 = isp4 + maxvar
         if (isadle.gt.3) then
            isp6 = isp5 + maxvar
            imon1 = isp6 + maxvar
         else
            imon1 = isp5 + maxvar
         end if
         imon2 = imon1 + 800
         last = imon2 + 800
         if (isadle.eq.2) then
            ifp1 = last
            ifp2 = ifp1 + nvar2
            ifp3 = ifp2 + nvar2
            ifp4 = ifp3 + nvar
            last = ifp4 + nvar
         end if
         length = last - i10

         i10 = igmem_alloc_inf(length,fnm,snm,'i10',IGMEM_DEBUG)
         i20 = i10 + nvar2
         i30 = i20 + nvar2
         i40 = i30 + nvar2
         i50 = i40 + nvar60
         iix = i50 + nvar60
         iig = iix + maxvar
         isp1 = iig + maxvar
         isp2 = isp1 + maxvar
         isp3 = isp2 + maxvar
         isp4 = isp3 + maxvar
         isp5 = isp4 + maxvar
         if (isadle.gt.3) then
            isp6 = isp5 + maxvar
            imon1 = isp6 + maxvar
         else
            imon1 = isp5 + maxvar
         end if
         imon2 = imon1 + 800
         last = imon2 + 800
         if (isadle.eq.2) then
            ifp1 = last
            ifp2 = ifp1 + nvar2
            ifp3 = ifp2 + nvar2
            ifp4 = ifp3 + nvar
            last = ifp4 + nvar
         end if

         ii = iix - 1
         do 110 i = 1 , n
            cmin1(i) = cmin10(i)
            cmin2(i) = cmin20(i)
            hes(ii+i) = values(i)
 110     continue
c
c.... nnalytical hessians read elsewhere
c ... maybe hessian is to be generated by mechanics
         if (oamhes) then
            call model(hes,hes,6)
c ... in present, crude, form of program hessian
c     is generated in hes(iamhes). tidy this up later!
            call dcopy(nvar2,hes(iamhes+3*nz),1,hes(i10),1)
         else
c ... use diagonal hessian in the absence of anything better.
            call vclr(hes(i10),1,nvar2)
            ii = i10 - 1
            do 120 i = 1 , n
               hes(ii+i) = 1.0d0
               ii = ii + nvar
 120        continue
            call estm(hes(i10),hes(iix),n)
            do 130 i = 1 , n
               ii = (i-1)*n + i - 1 + i10
               if (dabs(fpvec(i)).gt.1.0d-4) hes(ii) = fpvec(i)
 130        continue
         end if
c        ik = 1
         i = 3*natoms
         i = lensec(i*i) + lensec(mach(7))
c
c ----- allocate gradient section on dumpfile
c
         call secput(isect(495),m17,i,ibl3g)
         ibl3hs = ibl3g + lensec(mach(7))
c
c ----- check for a restart run
c
         orest = itask(mtask).ne.-1
         if (orest) then
c
c  input control and other parameters from dumpfile - section 489
c
            call rdedx(accd,mach(1),ibl3op,idaf)
            ibl = ibl3op + lensec(mach(1))
            call rdedx(en,mach(10),ibl,idaf)
            ibl = ibl + lensec(mach(10))
            call rdedx(hes(i40),nvar60,ibl,idaf)
            ibl = ibl + nvarb
            call rdedx(hes(i50),nvar60,ibl,idaf)
c
            do 140 i = 1 , 6
               accu(i) = accd(i,1)
 140        continue
c  casscf or mcscf 
            otmp = .not.orege.or. (zscftp.ne.zcas(1) .and.
     +             zscftp.ne.zcas(2) .and. zscftp.ne.zcas(3))
            if (.not.otmp) then
               if (irest.gt.3) then
c
c ----- modify gradient restart in case of =rege= to permit
c       regeneration of 2-pdm file
c
                  jpoint = jpoint - 1
                  ierec(jpoint) = -1
                  irest = 0
               end if
            end if
_IF(parallel)
c
c  direct-mp2 gradients
c
            if (mp2) then
c  did the previous job dump in the energy or 
c  gradients (cant use irest ..)
              jtmp = 0
              if (ierec(jpoint).eq.0) then
                jtmp = jpoint 
              endif
              if (igrec(jpoint-1).eq.0) then
                jtmp = jpoint - 1
                igrec(jpoint-1) = -1
              endif
              if (jtmp.eq.0) then
c   the previous job neither dumped in the scf or
c   gradient ... presumably it had converged, so set jtmp to jpoint ...
                jtmp = jpoint
              endif
              ierec(jtmp) = -1
              irest = 0
            else
c  scf optimisations
              otmp = .not.orgall
              if (.not.otmp) then
c  did the previous job dump in the energy or 
c  gradients (cant use irest ..)
                jtmp = 0
                if (ierec(jpoint).eq.0) then
                  jtmp = jpoint 
                endif
                if (igrec(jpoint-1).eq.0) then
                  jtmp = jpoint - 1
                  igrec(jpoint-1) = -1
                endif
                if (jtmp.eq.0) then
c   the previous job neither dumped in the scf or
c   gradient ... presumably it had converged, so set
c   jtmp to jpoint ...
                  jtmp = jpoint
                endif
                ierec(jtmp) = -1
                irest = 0
              endif
            endif
_ENDIF
c
         else
c
c ----- allocate minit restart section on dumpfile
c
            len = lenh + nvarh + nvarh
            call secput(isect(489),m80,len,ibl3op)

            iterat = 0
            do 150 i = 1 , 6
               accd(i,1) = accin(i)
               accu(i) = accin(i)
 150        continue
         end if
      end if
c
c  print out control parameters - unit 6
c
      if (isadle.le.3) then
         write (iwr,6160) n , jm , mnls
         if (lintyp.eq.0) write (iwr,6010)
         if (lintyp.eq.1) write (iwr,6020)
         write (iwr,6170) (accin(i),i=1,3)
         if (isadle.eq.3) then
            if (lqstyp.eq.5) write (iwr,6030)
            if (lqstyp.eq.6) write (iwr,6040)
            write (iwr,6050) (accin(i),i=4,6)
            if (lqstyp.eq.4) then
               write (iwr,6180)
               write (iwr,6190)
               write (iwr,6210) (cmin1(i),i=1,n)
               write (iwr,6200)
               write (iwr,6210) (cmin2(i),i=1,n)
            end if
            if (iupcod.eq.0) write (iwr,6250)
            if (iupcod.eq.1) write (iwr,6220)
            if (iupcod.eq.2) write (iwr,6230)
            if (iupcod.eq.3) write (iwr,6240)
            write (iwr,6060)
         end if
      end if
      nt = natoms
      ifail = 0
c
c     imnter is flag for mnter in calcfg
c
      imnter = 0
c
c  call optimization procedures
c
_IF(ccpdft)
      if (CD_active()) then
         ierror = CD_jfit_init1()
         if (ierror.ne.0) then
            write(iwr,600)ierror
            call caserr2('Out of memory in incore coulomb fit')
         endif
      endif
 600  format('*** Need ',i10,' more words to store fitting ',
     +       'coefficients and Schwarz tables in core')
_ENDIF
      call calcfg(9,n,hes(iix),f,hes(iig),hes(i40),hes(i50),ioutp,hes,
     +            hes(imon1),hes(imon2))
      call calcfg(0,n,hes(iix),f,hes(iig),hes(i40),hes(i50),ioutp,hes,
     +            hes(imon1),hes(imon2))
      if (isadle.ne.2) call calcfg(3,n,hes(iix),f,hes(iig),hes(i40),
     +                             hes(i50),ioutp,hes,hes(imon1),
     +                             hes(imon2))
_IF(ccpdft)
      if (CD_active()) then
         ierror = CD_jfit_clean1()
         if (ierror.ne.0) then
             call caserr2('Memory problem detected in CD_jfit_clean1')
         endif
      endif
_ENDIF
c
      if (ofcm) then
c
c ----- analytic second derivative matrix to be restored from dumpfile
c
         if (orest) then
c...       for a restart optimise or restart saddle
            call rdedx(hes(i10),nvar2,ibl3op+lenh+nvarh,idaf)
         else
            call vclr(hes(i10),1,nvar2)
            idump = 0
            if (oprint(44)) idump = 2
            call fcmed3(hes(i10),hes,nvar,idump,'zmat')
            call wrt3(hes(i10),nvar2,ibl3op+lenh+nvarh,idaf)
         end if
      else
c
c ---- enter routine for calculating bits of the hessian
c
         call star(hes(i10),hes(i40),hes(i50),hes(iix),f,hes(iig),n,
     +             ioutp,hes,hes(imon1),hes(imon2))
      end if
      if(o_hmat) then
	call read_fcm(hes(i10),hes(i30),nvar,'sqr')
      endif
c
      if (.not.oprint(27) .and. ioutp.ne.0) then
         call dcopy(nvar2,hes(i10),1,hes(i30),1)
      end if
      ineg = 0
      imnter = 1
      if (isadle.eq.3) ineg = 1
      if (isadle.ge.4) ineg = -1
      t1 = 0.0d0
      t2 = 1.0d14
      ireord = 0
      call diaeig(hes(i10),hes(i20),n,coefb,t1,t2,ineg,ireord,iwr)
      if (isadle.ge.4) then
         call dcopy(n,coefb,1,hes(isp6),1)
      end if
      call blkhes(hes(i30),n)
      if (ioutp.gt.0) then
         if (oprint(27)) then
            write (ioutp,6070)
            write (ioutp,6080) (coefb(k),k=1,n)
         else
            write (ioutp,6090)
            call pre(hes(i30),coefb,n,n,n,iwr)
         end if
      end if
      call wrt3(hes(i10),nvar2,lenh+ibl3op,idaf)
      go to (170,180,160,190,190,190) , isadle
 160  ny = n - 1
      call saddleopt(hes(iix),f,hes(iig),hes(i10),hes(i20),hes(i40),
     +            hes(i50),n,ny,ifail,ioutp,hes,hes(isp1),hes(isp2),
     +            hes(isp3),hes(isp4),hes(isp5),hes(imon1),hes(imon2),
     +            iwr)
      go to 200
 170  call bfsmin(hes(iix),f,hes(iig),hes(i10),hes(i20),hes(i40),
     +            hes(i50),n,n,ifail,ioutp,hes,hes(isp2),
     +            hes(isp5),hes(imon1),hes(imon2),iwr)
      go to 200
 180  call fpmain(hes(iix),f,hes(iig),hes(i10),hes(i20),hes(i40),
     +            hes(i50),n,ifail,ioutp,hes,hes(isp1),hes(isp2),
     +            hes(isp3),hes(isp4),hes(isp5),hes(imon1),hes(imon2),
     +            hes(ifp1),hes(ifp2),hes(ifp3),hes(ifp4),nprino,iwr)
      go to 200
 190  call optjs(hes,hes(i10),hes(i20),hes(i40),hes(i50),hes(iix),
     +           hes(iig),hes(isp1),hes(isp2),hes(isp3),hes(isp4),
     +           hes(isp5),hes(isp6),hes(imon1),hes(imon2),nprino)
      go to 210
 200  iflag = 8
      call calcfg(iflag,n,hes(iix),f,hes(iig),hes(i40),hes(i50),ioutp,
     +            hes,hes(imon1),hes(imon2))
      nprint = nprino
      if (ifail.ne.0) then
         if (.not.oprint(44)) then
            zruntp = zprop
            go to 210
         end if
      end if
      write (iwr,6260)
      if(oprn(28)) call anamom(hes)
c
c     now suppress distance checking as optimisation complete
c
      ochkdst = .false.
      call intr(hes)
      call newpt(n,hes(iix),f,0,ioutp,hes)
      call optend(hes,nprint)
      zruntp = zprop
c
c     ------- reset core
c
 210  continue

      call gmem_free_inf(i10,fnm,snm,'i10')
c
      return
 6010 format (/1x,'use function evaluation only for line searches')
 6020 format (/1x,'use function+gradient evaluation for line searches')
 6030 format (/1x,'miller optimisation requested -- search for maximum')
 6040 format (/1x,
     +        'miller optimisation requested -- no search for maximum')
 6050 format (/1x,
     +         'tolerance for checking that the gradient along the'/
     +      1x,'initial search direction is still close to zero',f11.6/
     +      1x,'tolerance for checking that the step along the qst'/
     +      1x,'is not too large                               ',f11.6/
     +      1x,'size for step along tangent                    ',f11.6)
 6060 format (/)
 6070 format (/20x,37('=')/20x,
     +        'eigen values of force constant matrix'/20x,37('=')/)
 6080 format (1x,10f12.6)
 6090 format (//40x,21('=')/40x,'force constant matrix'/40x,21('=')/)
 6100 format (//40x,21('*')/40x,'geometry optimization'/40x,21('*'))
 6110 format (//40x,25('*')/40x,'saddle point optimization'/40x,25('*'))
 6120 format (//40x,28('*')/40x,'geometry optimisation --- fp'/40x,
     +        28('*'))
 6130 format (//40x,56('*')/40x,
     +        'geometry optimisation --- jorgenson & simons ( minimum )'
     +        /40x,56('*'))
 6140 format (//40x,55('*')/40x,
     +        'geometry optimisation --- jorgenson & simons ( saddle )'/
     +        40x,55('*'))
 6150 format (//40x,55('*')/40x,
     +        'geometry optimisation --- jorgenson & simons ( branch )'/
     +        40x,55('*'))
 6160 format (/' number of parameters       ',
     +        i3/' max. no. of calculations   ',
     +        i3/' max. no. of iterations     ',i3)
 6170 format (/' input control parameters'/1x,25('=')
     +        /' line search termination criterion         ',
     +        f11.6/' parameter convergence precision           ',
     +        f11.6/' line search restriction distance          ',
     +        f11.6)
 6180 format (/' two reference minima (ic space) : '/)
 6190 format (' min. no. 1'/1x,10('='))
c
 6200 format (/' min. no. 2'/1x,10('='))
 6210 format (/1x,10f11.6)
 6220 format (/' update of inverse hessian using bfgs method')
 6230 format (/' update of inverse hessian using murtagh sargent method'
     +        )
 6240 format (/' update of inverse hessian using modified powell method'
     +        )
 6250 format (/' update of inverse hessian using default methods')
 6260 format (//40x,22('*')/40x,'geometry of last point'/40x,22('*')/)
      end
      subroutine mnter(f,grad,g,n,jcall,ityp,fkp,lines,iout)
c
c ------ this routine monitors the progress of the optimisation
c ------ at the end of the run the routine call be asked to
c ------ dump the acquired information to provide a summary
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension g(n)
      dimension lines(4,*),fkp(4,*)
c
c ------ ityp  =1  initialisation call after first function and gradient
c ------       =2  linear search for minimum
c ------       =3  linear search for maximum
c ------       =4  step along the tangent
c
c ------ jcall =0  for output of the information
c ------       =1  if only a function evaluation
c ------       =2  if function and gradient evaluation
c ------       =3  if only gradient calculated
c
c
INCLUDE(common/cntl1)
      character*24 yout(18)
      data yout/'     Initialisation     ',
     1          'Line search for minimum ',
     2          'Line search for maximum ',
     3          'Step along tangent      ',
     4          'Bad start reinitialise  ',
     5          '1d-search bad curvature ',
     6          '1d-search outside bounds',
     7          'Miller  step to ridge   ',
     8          'Miller  restricted opt. ',
     9          'Miller  ridge step      ',
     a          'Miller  valley step     ',
     1          'Miller  climbing step   ',
     2          'Miller  newton raphson  ',
     3          'FP- 1st derivatives     ',
     4          'FP- 1st & 2nd derivative',
     5          'FP- linear search       ',
     6          'FP- end  of 1-D search  ',
     7          'FP- OPTIMISATION END    '/
      data yblnk,ystar/' ','*'/
      if (jcall.eq.0) then
c
c ---- now write it all out
c
         write (iout,6020)
         do 20 i = 1 , nentry
            j = lines(2,i)
            ytmp = yblnk
            if (j.eq.3) ytmp = ystar
            write (iout,6010) lines(1,i) , lines(3,i) , lines(4,i) ,
     +                        fkp(1,i) , fkp(2,i) , fkp(4,i) , fkp(3,i)
     +                        , yout(j) , ytmp
 20      continue
         write (iout,6030)
         return
      else
         if (ityp.le.1) then
c
c ---- initialise
c
            grms(1) = 0.0d0
            grms(2) = 0.0d0
            nentry = 0
            lines(1,1) = 0
            lines(3,1) = 1
            lines(4,1) = 1
         end if
         nentry = nentry + 1
         if (jcall.eq.3) nentry = nentry - 1
         if (nentry.gt.200) return
         if (jcall.ne.1) then
            grms(1) = 0.0d0
            grms(2) = 0.0d0
            do 30 k = 1 , n
               if (dabs(g(k)).gt.grms(2)) grms(2) = dabs(g(k))
               grms(1) = grms(1) + g(k)*g(k)
 30         continue
            grms(1) = dsqrt(grms(1))/n
         end if
         fkp(1,nentry) = f
         if (ismax.eq.1) fkp(1,nentry) = -f
         fkp(2,nentry) = grad
         fkp(3,nentry) = grms(1)
         fkp(4,nentry) = grms(2)
         lines(2,nentry) = ityp
         if (nentry.eq.1) return
         lines(1,nentry) = nls + 1
         lines(3,nentry) = lines(3,nentry-1) + 1
         lines(4,nentry) = lines(4,nentry-1)
         if (jcall.gt.1 .and. ityp.lt.14) lines(4,nentry)
     +       = lines(4,nentry) + 1
         return
      end if
 6010 format (1x,3(1x,i8),e20.10,3(1x,e12.5),2x,a24,a4)
 6020 format ('1'/1x,113('=')//25x,'s u m m a r y   o f   ',
     +        's e a r c h     i n f o r m a t i o n'//1x,113('=')/1x,
     +        '  line   ',' function',' gradient',6x,'function value',
     +        5x,'position',9x,'gmax',9x,'grms',9x,'comments'/1x,
     +        'searches ','    calls',4x,'calls'/1x,113('='))
 6030 format (1x,113('='))
      end
      subroutine mofi(natoms,c,amass,cmc,pmom,pvec)
c
c     compute the principal moments of inertia.
c     units are amu-bohr**2
c
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension c(3*natoms), amass(natoms), pmom(3), pvec(9)
      dimension cmc(3), t(6)
c
INCLUDE(common/sizes)
INCLUDE(common/mapper)
c
      data dzero/0.0d0/
c
c     c    : the atomic coordinates
c     amass: the atomic masses
c     cmc  : the centre of mass coordinates
c     pmom : the moments of inertia
c     pvec : the coordinates
c
c     compute the position of the center of mass and translate
c     it to the origin.
c
      cmc(1) = dzero
      cmc(2) = dzero
      cmc(3) = dzero
c
      totwt = dzero
      do 20 iat = 1 , natoms
         iaind = 3*(iat-1)
         wt = amass(iat)
         totwt = totwt + wt
         cmc(1) = cmc(1) + wt*c(1+iaind)
         cmc(2) = cmc(2) + wt*c(2+iaind)
         cmc(3) = cmc(3) + wt*c(3+iaind)
 20   continue
c
      cmc(1) = cmc(1)/totwt
      cmc(2) = cmc(2)/totwt
      cmc(3) = cmc(3)/totwt
c
c     compute the principal moments.
c
      do 30 i = 1 , 6
         t(i) = dzero
 30   continue
c
      iat3 = 0
      do 40 iat = 1 , natoms
         wt = amass(iat)
         dumx = c(1+iat3) - cmc(1)
         dumy = c(2+iat3) - cmc(2)
         dumz = c(3+iat3) - cmc(3)
         t(1) = t(1) + wt*(dumy*dumy+dumz*dumz)
         t(3) = t(3) + wt*(dumx*dumx+dumz*dumz)
         t(6) = t(6) + wt*(dumx*dumx+dumy*dumy)
         t(2) = t(2) - wt*dumx*dumy
         t(4) = t(4) - wt*dumx*dumz
         t(5) = t(5) - wt*dumy*dumz
         iat3 = iat3 + 3
 40   continue
      id = 3
      th = 1.0d-15
      call ngdiag(t,pvec,pmom,iky,id,id,0,th)
c
      return
      end
      subroutine monit(nlset,hes,n,ioutp,hest)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      dimension hes(*),tmp(maxvar),hest(*)
INCLUDE(common/restar)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/prints)
INCLUDE(common/machin)
INCLUDE(common/cntl2)
INCLUDE(common/csubst)
INCLUDE(common/cntl1)
      character*7 fnm
      character*5 snm
      data fnm,snm/'optim.m','monit'/
      dimension accu(6)
      equivalence (accu(1),acc)
      nn = n*n
c
      call fiddle_hes(hes,n*n,'monit')
c
c     ----- allocate core
c
      i10 = igmem_alloc_inf(2*nn,fnm,snm,'i10',IGMEM_DEBUG)

      call dcopy(nn,hes(1),1,hest(i10),1)
      ineg = -1
      t1 = 0.0d0
      t2 = 1.0d14
      ireord = 1
      call inveig(hest(i10),hest(i10+nn),n,tmp,t1,t2,ineg,ireord,iwr)
c
c ... load diagonal elements of hessian
      ii = i10 - 1
      do 20 i = 1 , n
         fpvec(i) = hest(ii+i)
         ii = ii + n
 20   continue
c
      call blkhes(hest(i10),n)
      if (ioutp.ne.0) then
         if (oprint(27)) then
            write (ioutp,6060)
            write (ioutp,6050) (tmp(i),i=1,n)
         else
            write (ioutp,6040)
            call pre(hest(i10),tmp,n,n,n,iwr)
         end if
c
c print eigenvector for lowest eigenvalue
c
         write (ioutp,6010)
         write (ioutp,6050) (hest(i10+nn-1+j),j=1,n)
c
      end if
      i = lensec(n*200)
      ibl = i + i + lensec(mach(1)) + lensec(mach(10)) + ibl3op
      call wrt3(hest(i10),nn,ibl,idaf)
      iter = nlset
      iter1 = iter + 1
      if (iter.gt.iterat) then
         do 30 i = 1 , 6
            accu(i) = accin(i)
            accd(i,iter1) = accu(i)
 30      continue
         iterat = iter
      else if (iter1.ge.iterch) then
         do 40 i = 1 , 6
            accu(i) = accin(i)
            accd(i,iter1) = accu(i)
 40      continue
         do 50 i = jpoint , 200
            ierec(i) = -1
            igrec(i) = -1
 50      continue
         irest = 0
      else
         do 60 i = 1 , 6
            accu(i) = accd(i,iter1)
 60      continue
      end if
      if (ioutp.ne.0) write (ioutp,6020) iter1 , (accu(i),i=1,3)
      if (isadle.eq.3) then
         if (ioutp.ne.0) write (ioutp,6030) (accu(i),i=4,6)
      end if
c
c     ------- reset core
c
      call gmem_free_inf(i10,fnm,snm,'i10')

      return
 6010 format (/20x,18('-')/20x,'lowest eigenvector'/20x,18('-'),/)
 6020 format (/1x,104('*')//' control parameters for line search no.',
     +        i3/1x,41('=')
     +        /' line search termination criterion             ',
     +        f11.6/' parameter convergence precision               ',
     +        f11.6/' line search termination restriction distance  ',
     +        f11.6/)
 6030 format (' tolerance on gradient along search direction  ',
     +        f11.6/' qst step size restriction                     ',
     +        f11.6/' tangent step size                             ',
     +        f11.6/)
 6040 format (/40x,21('=')/40x,'force constant matrix'/40x,21('='))
 6050 format (1x,10f12.6)
 6060 format (/20x,37('=')/20x,
     +        'eigen values of force constant matrix'/20x,37('=')/)
      end
      subroutine fiddle_hes(hes,n,mode)
c
c...  fiddle withe hessian; save hessian and allow restoring 
c...  every now and then, if one assumes it is screwed
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension hes(n)
      character*(*) mode
c
INCLUDE(common/iofile)
INCLUDE(common/scra7)
INCLUDE(common/fiddle_hesc)
c
      if (ifreq_h.eq.987654) return
      if (mode.eq.'once'.and.icall_h.ne.0) return
c
      icall_h = icall_h + 1
c
      if (icall_h.eq.1) then
         khes7_h = ibl7la
         call wrt3(hes,n,khes7_h,num8)
         ibl7la = iposun(num8)
         write(iwr,'(a)') '     *** (inverse) hessian saved ***'
         return
      end if
c
      if (mod(icall_h,ifreq_h).eq.0) then
         call rdedx(hes,n,khes7_h,num8)
         write(iwr,'(a)') '     *** (inverse) hessian reset ***'
      end if
c
      return
      end
      subroutine mulmat(hesx,hesy,hes,n,n1)
c
c -----   hesy =  zt( hesx ) z
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension hesx(n,n),hesy(n1,n1),hes(n,n1)
      common/blkin/t(1)
      do 40 i = 1 , n1
         do 20 j = 1 , n
            t(j) = ddot(n,hesx(1,j),1,hes(1,i),1)
 20      continue
         do 30 l = 1 , n1
            hesy(l,i) = ddot(n,t,1,hes(1,l),1)
 30      continue
 40   continue
      return
      end
      subroutine newpt(nq,q,fv,iflag,ioutp,core)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      dimension q(*),core(*)
INCLUDE(common/restar)
      common/restrl/ociopt,ocifor,omp2
INCLUDE(common/restrj)
INCLUDE(common/cndx41)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/infob)
INCLUDE(common/molsym)
INCLUDE(common/phycon)
      common/miscop/qst(16,maxvar),qqst(9),
     *title(16),etot,enuc,qx(3),qtot
     *, f(maxat*3),fi(maxvar),nt,ia(maxat)
INCLUDE(common/infoa)
INCLUDE(common/funct)
INCLUDE(common/csubch)
      common/czmat/ianz(maxnz),iz(maxnz,4),bl(maxnz),alpha(maxnz),
     * beta(maxnz),lbl(maxnz),lalpha(maxnz),lbeta(maxnz),nz,nvar
INCLUDE(common/csubst)
INCLUDE(common/runlab)
INCLUDE(common/modj)
INCLUDE(common/datgue)
      common/bufb/zdone(maxvar)
INCLUDE(common/fpinfo)
_IF(rpagrad)
INCLUDE(common/rpadcom)
_ENDIF
INCLUDE(common/structchk)
INCLUDE(common/harmon)
INCLUDE(common/fccwfn)
      character*7 fnm
      character*5 snm
c
      data fnm,snm/"optim.m","newpt"/
      data dum,idum/0.0d0,0/
c
c...   new point reset newbas0
      newbas0 = newbash
c
      call dcopy(nq,q(1),1,values(1),1)
      call subvar(bl,alpha,beta,lbl,lalpha,lbeta,nz,nvar)
      call sprintxz(maxnz,nz,ianz,iz,bl,alpha,beta,toang(1),ioutp)
c
c ---- write out the values and names of the variables
c
      pi = dacos(0.0d0)*2.0d0
      write (iwr,6020)
      i = 0
      idone = 0
      do 30 kk = 1 , 3
         do 20 j = 1 , nz
            if (kk.eq.1 .and. lbl(j).ne.0) then
               i = iabs(lbl(j))
               ytype = 'angs'
               const = toang(1)
               if (locatc(zdone,idone,zvar(i)).eq.0) then
                  idone = idone + 1
                  zdone(idone) = zvar(i)
                  if (o_var_high) then
                     write (iwr,6031) zvar(i) , values(i)*const , 
     +                                fpvec(i)
                   else
                     write (iwr,6030) zvar(i) , values(i)*const , 
     +                                fpvec(i)
                   end if
               end if
            else if (kk.eq.2 .and. lalpha(j).ne.0) then
               i = iabs(lalpha(j))
	       if(iz(j,1).lt.0) then
		 ytype='angs'
		 const = toang(1)
	       else
                 ytype = 'degs'
                 const = 180.0d0/pi
	       endif
               if (locatc(zdone,idone,zvar(i)).eq.0) then
                  idone = idone + 1
                  zdone(idone) = zvar(i)
                  if (o_var_high) then
                     write (iwr,6031) zvar(i) , values(i)*const , 
     +                                fpvec(i)
                  else    
                     write (iwr,6030) zvar(i) , values(i)*const , 
     +                                fpvec(i)
                  end if
               end if
            else if (kk.eq.3 .and. lbeta(j).ne.0) then
               i = iabs(lbeta(j))
	       if(iz(j,1).lt.0) then
		 ytype='angs'
		 const = toang(1)
	       else
                 ytype = 'degs'
                 const = 180.0d0/pi
               endif
               if (locatc(zdone,idone,zvar(i)).eq.0) then
                  idone = idone + 1
                  zdone(idone) = zvar(i)
                  if (o_var_high) then
                     write (iwr,6031) zvar(i) , values(i)*const , 
     +                                fpvec(i)
                  else
                     write (iwr,6030) zvar(i) , values(i)*const , 
     +                                 fpvec(i)
                  end if
               end if
            end if
 20      continue
 30   continue
      write (iwr,6010)

      i10 = igmem_alloc_inf(maxat*3 + 5*nz,fnm,snm,"i10",IGMEM_DEBUG)
      i20 = i10 + maxat*3
      i21 = i20 + nz
      i22 = i21 + nz
      i23 = i22 + nz
      i24 = i23 + nz
c     last = i24 + nz

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
      kk = 0
      do 60 i = 1 , ntota
         czan(i) = czann(i)
         zaname(i) = ztag(i)
         c(1,i) = c(1,i) - trx
         c(2,i) = c(2,i) - try
         c(3,i) = c(3,i) - trz
         f(kk+1) = c(1,i)
         f(kk+2) = c(2,i)
         f(kk+3) = c(3,i)
         kk = kk + 3
 60   continue
      otest = .true.
      call stocxz(maxnz,nz,ianz,iz,bl,alpha,beta,otest,nt,ia,c,core(i10)
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
     +  'error detected in converting z-matrix to cartesian coordinates'
     +  )
      iold = igroup
      zoldg = zgroup
      jold = jaxis
      call symm(ioutp,core)
      if (iold.ne.igroup .or. jold.ne.jaxis) then
         write (iwr,6040) zoldg , jold , zgroup , jaxis
         call caserr2('point group change during optimisation')
      end if
      do 80 i = 1 , ntota
         m80 = map80(i)
         zaname(m80) = ztag(i)
         c(1,m80) = cnew(i,1)
         c(2,m80) = cnew(i,2)
         c(3,m80) = cnew(i,3)
         czan(m80) = czann(i)
 80   continue
      ntp1 = nt + 1
      if (nt.lt.ntota) then
         kk = nt*3
         do 90 i = ntp1 , ntota
            m80 = map80(i)
            c(1,m80) = f(kk+1) + trx
            c(2,m80) = f(kk+2) + try
            c(3,m80) = f(kk+3) + trz
            kk = kk + 3
 90      continue
         do 110 i = 2 , 3
            im1 = i - 1
            do 100 j = 1 , im1
               t = tr(i,j)
               tr(i,j) = tr(j,i)
               tr(j,i) = t
 100        continue
 110     continue
         ntmp = ntota - nt
         call rotf(ntmp,tr,c(1,ntp1),c(1,ntp1))
         do 130 i = 2 , 3
            im1 = i - 1
            do 120 j = 1 , im1
               t = tr(i,j)
               tr(i,j) = tr(j,i)
               tr(j,i) = t
 120        continue
 130     continue
      end if
      ntot3 = ntota*3
      call dcopy(ntot3,core(i10),1,f(1),1)

      call gmem_free_inf(i10,fnm,snm,"i10")
c
c     check on geometry and bond distances if requested
c
      if (ochkdst) then
       call intr(core)
      endif
c
      if (oalway) then
c...     generate new mo's for each point
         call mogues(core)
      end if
c
      if (iflag.ne.0) then
         if (iflag.ne.1) then
            call putzm(1,iseczz)
            etot = 0.0d0
            if (omodel) then
c ...
c     calculate mechanics enery, if required.
c ...
               enrgy = 0.0d0
               call model(core,core,2)
               etot = enrgy
            end if
            if (.not.opass1) then
             if (irest.eq.0) call secdrp(ionsec)
            endif
c 
            if (omp2 .or. mp3) then
               if (irest .eq. 0) mprest = 0
               call emp23(core,enrgy)
            else if (omas) then
               call masscf(core,enrgy)
            else if(ocifp) then
               call citran(core)
_IF(rpagrad)
            else if(orpagrad) then
c              orpaenrgy=.true.
c              orpaegrad=.false.
               call drpadr_e(core)
_ENDIF
            else
               call hfscf(core)
            end if
            etot = etot + enrgy
            if (omodel) write (iwr,6050) etot
            fv = etot
         end if
         call wrrec1(idum,idum,idum,idum,c,c,dum,dum,dum,c,c)
c *** if required, punch out coordinates at this point
         call blkupd(c)
         return
      else
         write (iwr,6060)
         call prgeom(c,czanr,zaname,nat,iwr)
         return
      end if
 6010 format (1x,
     +'==============================================='/)
 6020 format (/1x,
     +'==============================================='/1x,
     +'variable',11x,'value',9x,7x,'hessian'/1x,
     +'===============================================')
c6030 format (1x,a8,2x,f14.7,1x,a4,2x,f14.6)
c6030 format (1x,a8,2x,f14.7,1x,'hessian',1x,f14.6,' (',a4,')')
 6030 format (1x,a8,2x,f14.7,1x,'hessian',1x,f14.6)
 6031 format (1x,a8,2x,f24.16,1x,'hessian',1x,f14.6)
 6040 format (//1x,'**** change in point group ****'//5x,2(5x,a8,i6)/)
 6050 format (20x,'Total energy',5x,f16.10/)
 6060 format (/40x,19('=')/40x,'nuclear coordinates'/40x,19('=')/)
      end
      subroutine norout(a,eig,mndim,mdim,iout)
c
c     frequency and normal coordinate output routine.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension a(mndim),eig(mdim)
      dimension temp(30)
_IF1()      dimension t(5)
INCLUDE(common/runlab)
c ----------------------------------------------------------------------
      ndim = mndim/mdim
c                  number of columns in a row.
      nc = 9
c                  initialize some stuff.
      min = 1
      max = mdim
      ifin = 0
c
c -   formatted file for graphics:
c
c     If the runtype is HESSIAN or INFRARED then the normal modes
c     will be written out in subroutine iranal.
c
      if (zruntp.ne.'hessian'.and.zruntp.ne.'infrared') then
         do i = 1,mdim
            call blkvib(i,a(1+(i-1)*ndim) ,eig(i))
         enddo
      endif
c
      ifin = 0
c                  print heading.
      write (iout,6010)
c                  top of loop.
 20   max1 = min + nc - 1
c                  is this last pass thru loop?
      if (max.le.max1) then
         max1 = max
         ifin = 1
      end if
c                  print integer column numbers.
      write (iout,6050) (i,i=min,max1)
      write (iout,6020) (eig(i),i=min,max1)
      write (iout,6030)
c                  top of loop printing rows.
      do 40 i = 1 , ndim
         n = max1 - min + 1
         iatom = (i-1)/3 + 1
         do 30 j = 1 , n
            ind = ndim*(min+j-2) + i
            temp(j) = a(ind)
 30      continue
         write (iout,6040) i , iatom , zaname(iatom) , (temp(j),j=1,n)
 40   continue
      min = min + nc
      if (ifin.ne.1) go to 20
      return
c ----------------------------------------------------------------------
 6010 format (//10x,64('=')/10x,
     +        'harmonic frequencies (cm**-1) and normalised normal',
     +        ' coordinates'/10x,64('='))
 6020 format (/1x,11('=')/1x,'frequencies ----',6x,10f10.4)
 6030 format (1x,11('=')//1x,'coord atom element '/1x,18('='))
 6040 format (1x,i3,4x,i2,2x,a8,3x,10f10.5)
 6050 format (//18x,10i10)
      end
      function nrep(item,list,length)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension list(*)
      ltest = iabs(item)
      nrep = 0
      do 20 i = 1 , length
         if (ltest.eq.iabs(list(i))) nrep = nrep + 1
 20   continue
      return
      end
      subroutine optend(q,nprint)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
      parameter (mxorb1 = maxorb+1)
      common/dims/kk1,kk2,kk3,kk4,kk5,kk6,kk7,kk8,kk9
     * , kk10,kk11,kk12
INCLUDE(common/iofile)
INCLUDE(common/restri)
INCLUDE(common/prints)
INCLUDE(common/infoa)
INCLUDE(common/runlab)
      common/blkorbs/eig(maxorb),pop(mxorb1),nba,new,ncoll,
     * jeig,jocc,ipad
      common/junkc/zcomm(29)
INCLUDE(common/machin)
INCLUDE(common/atmol3)
INCLUDE(common/segm)
INCLUDE(common/mapper)
      common/multic/radius(40),irad(25),ncoremc,nact,jrad(5),
     +              nfreez,krad(13),itype(maxorb),lrad(11+mcfzc),isecn
INCLUDE(common/natorb)
INCLUDE(common/harmon)
INCLUDE(common/restrj)
INCLUDE(common/zorac)
c
      character*7 fnm
      character*6 snm
      data fnm,snm/'optim.m','optend'/
      dimension zcas(3),q(*),cbuf(6),ibuf(6),kkbuf(12)
      equivalence (kkbuf(1),kk1)
      data zuhf,zgrhf,zgvb/'uhf','grhf','gvb'/
      data zcas/'casscf','mcscf','vb'/
      data m3,m29,m10,m16/3,29,10,16/
c
      l0 = newbas0
      l1 = num
      l2 = (num*(num+1))/2
      l3 = num*num
c     decide on high or low format for vector print
      if (oprint(20).or.opark) then
       lprnt = l1
      else
       lprnt = na
       if (zscftp.eq.zcas(2)) lprnt = nfreez+ncoremc+nact
       lprnt = min(lprnt+5,l0)
      endif
      nav = lenwrd()
c
      nwf = mach(8)
      nwctr = mach(9)
      if (zscftp.eq.zcas(1)) then
         nw = 12/nav
         call secget(moutb,m3,iblvec)
         iblvec = iblvec + lensec(l1*l1) + lensec(nwctr) + lensec(nwf)
     +            + 1
         call readi(kkbuf,nw*nav,iblvec,idaf)
      end if
c
c     ----- set pointers for partitioning of core -----
c
      length = max(10,l3+3*l1)
      if (zscftp.eq.zcas(1))length = max(length,kk3)
      i10 = igmem_alloc_inf(length,fnm,snm,'i10',IGMEM_DEBUG)
      i20 = i10 + l3
      i30 = i20 + l1
      i40 = i30 + l1
c     i50 = i40 + l1
c
      write (iwr,6110) (ztitle(i),i=1,10)
      call secget(isect(494),m16,iblk16)
      call rdedx(q(i10),m10,iblk16,idaf)
      enuc = q(1-1+i10)
      ehf = q(2-1+i10)
      etot = q(3-1+i10)
      sz = q(4-1+i10)
      s2 = q(5-1+i10)
      write (iwr,6040) enuc , ehf , etot
      if (zscftp.eq.zuhf.and.(.not.oso.and.ozora)) write (iwr,6100) sz
     + , s2
      ipass = 1
      mout = mouta
      if (zscftp.eq.zgvb .or. zscftp.eq.zgrhf .or. zscftp.eq.zcas(1)
     +    .or. zscftp.eq.zcas(2)) then
         if (moutb.gt.0) mout = moutb
      end if
      if (zscftp.eq.zcas(2).and.isecn.ne.0) mout = isecn
      if (zscftp.eq.zuhf) write (iwr,6050)
      if (ispacg.gt.0) mout = ispacg
 20   call secget(mout,m3,iblvec)
      call rdchr(zcomm(1),m29,iblvec,idaf)
      call reads(eig,nwf,idaf)
c     ncol = ncoll
      call dcopy(l1,eig(1),1,q(i30),1)
      call dcopy(l1,pop(1),1,q(i40),1)
      iblvec = iblvec + lensec(nwctr) + lensec(nwf) + 1
      call rdedx(q(i10),l3,iblvec,idaf)
      if (zscftp.ne.zcas(3)) then
        call analmo(q(i10),q(i30),q(i40),ilifq,l0,l1)
      end if
      call tdown(q(i10),ilifq,q(i10),ilifq,l0)
      write(iwr,6061) mout
6061  format(/,' vectors restored from section',i4)                                     
      if (oprint(50)) then
       if(ispacg.gt.0.or.zscftp.eq.zcas(3).or.zscftp.eq.zcas(2)) then
         write (iwr,6120)
         call prev(q(i10),q(i40),lprnt,l1,l1)
       else
         write (iwr,6060)
         call prev(q(i10),q(i30),lprnt,l1,l1)
       endif
      endif
      if (nprint.eq.7) call pusql(q(i10),l0,l1,l1)
      if (oprint(46)) then
         call rdedx(q(i10),l3,iblvec,idaf)
         write (iwr,6010)
         call prsq(q(i10),lprnt,l1,l1)
      end if
      if (zscftp.eq.zuhf) then
         if (ipass.ne.2) then
            ipass = 2
            mout = moutb
            if (.not.oprint(20)) lprnt = min(nb+5,l1)
            write (iwr,6070)
            go to 20
         end if
      end if
c
      if (zscftp.eq.zcas(1)) then
c
c     now print ci coefficients
c
         iblvec = iblvec + 1 + lensec(l1*l1)
     +            + (lensec(kk3)+lensec(kk8)+lensec(kk9))*(kk12-1)
         call rdedx(q(i10),kk3,iblvec,idaf)
         write (iwr,6020)
         l = 0
         do 30 i = 1 , kk3
            if (dabs(q(i10-1+i)).ge.ciprnt) then
               l = l + 1
               ibuf(l) = i
               cbuf(l) = q(i10-1+i)
               if (l.ge.6) then
                  write (iwr,6030) (ibuf(l),cbuf(l),l=1,6)
                  l = 0
               end if
            end if
 30      continue
         if (l.ne.0) write (iwr,6030) (ibuf(i),cbuf(i),i=1,l)
      end if
      if (nprint.eq.7) then
         do 40 iat = 1 , nat
            write (ipu,6080) zaname(iat) , czan(iat) , (c(i,iat),i=1,3)
 40      continue
         do 50 iat = 1 , nat
            write (ipu,6090) (c(i,iat),i=1,3)
 50      continue
      end if
c
c     ----- reset core memory -----
c
      call gmem_free_inf(i10,fnm,snm,'i10')
      return
 6010 format (//10x,44('=')/10x,
     +        'molecular orbitals -- symmetry adapted basis'/10x,44('=')
     +        //)
 6020 format (/1x,104('=')//40x,'ci coefficients'/40x,15('=')/)
 6030 format (6(i4,f12.6,5x))
 6040 format (/
     +    21x,'nuclear energy    = ',f20.12/
     +    21x,'electronic energy = ',f20.12/
     +    21x,'total energy      = ',f20.12)
 6050 format (//10x,9('*')/10x,'alpha set'/10x,9('*')/)
 6060 format (/10x,18('=')/10x,'molecular orbitals'/10x,18('='))
 6120 format (/10x,25('=')/10x,'spinfree natural orbitals'/10x,25('='))
 6070 format (//10x,8('*')/10x,'beta set'/10x,8('*')/)
 6080 format (a8,2x,f5.0,3f20.10)
 6090 format (15x,3(f19.9,','))
 6100 format (///10x,17('=')/10x,'spin sz   = ',f5.3/10x,'s-squared = ',
     +        f5.3/10x,17('='))
 6110 format (//1x,104('=')//25x,10a8/25x,80('=')/)
      end
      subroutine optx(core)
c
c     minimization of the energy by varying the geometry
c     of the molecule using murtagh and sargent algorithm
c
c     this is an updating routine which successively
c     generates the hessian matrix (i.e. the inverse of the
c     matrix of second derivatives) after a successful one
c     dimensional search.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/machin)
INCLUDE(common/cntl1)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/restar)
INCLUDE(common/restri)
INCLUDE(common/runlab)
INCLUDE(common/infoa)
      common/miscop/p(maxat*3),g(maxat*3),dx(maxat*3),func,
     +              alpha,cz(maxat*3),q(maxat*3),cc,gnrm
INCLUDE(common/funct)
INCLUDE(common/seerch)
INCLUDE(common/timez)
INCLUDE(common/copt)
INCLUDE(common/prnprn)
INCLUDE(common/prints)
INCLUDE(common/runopt)
INCLUDE(common/structchk)
_IF(charmm)
INCLUDE(common/chmgms)
_ENDIF
_IF(drf)
      common/nottwi/obeen,obeen2,obeen3,obeen4
INCLUDE(../drf/comdrf/drfpar)
INCLUDE(common/drfopt)
_ENDIF
      dimension core(*)
      data done/1.0d0/
      data m17/17/
      data zgrad/'gradient'/
      data zirc /'irc'/
      orset = .false.
      nprino = nprint
      tolg = rcvopt
      if (zruntp.eq.zirc)  icode = 4
_IF(drf)
cahv
      irepeat = -1
cahv
_ENDIF
cjk
      if (icode.ne.4) then
        write (iwr,6070) tolg , jm , accin(3)
        if ( iupcod .ne. 2 ) then
           write(iwr,6071)
        else
           write(iwr,6072)
        endif
      endif
      bigg0 = 0.0d0
      bigg = 0.0d0
      npts = -1
c
c ----- allocate gradient section on dumpfile
c

      ncoord = 3*nat
      nc2 = ncoord*ncoord
      if (zruntp.eq.zgrad) then
         nc2 = 0
      endif
      isize = lensec(nc2) + lensec(mach(7))
      call secput(isect(495),m17,isize,ibl3g)
      ibl3hs = ibl3g + lensec(mach(7))
c
c     ----- check for a restart run -----
c
      call rdrec1(nserch,idum,idum,idum,p,p,dum,dum,dum,p,p)
      orstrt = itask(mtask).gt. - 1.d0 .and. nserch.gt.0
      if (orstrt) go to 30
c
c     ----- fresh start, evaluate first gradient -----
c
      nserch = 0
      enrgy = 0.0d0
      func = 0.0d0
_IF(drf)
      if (oreact) then
        func0 = 1.0d10
      else
        func0 = 0.0d0
      endif
_ELSE
      func0 = 0.0d0
_ENDIF

      call vclr(dx,1,ncoord)
      call vclr(egrad,1,ncoord)
      call dcopy(ncoord,c(1,1),1,p,1)
      call vclr(g,1,ncoord)
      gs0 = 0.0d0
      call valopt(core)

_IF(drf)
cahv
      obeen  = .false.
      obeen3 = .false.
      obeen4 = .false.
      ixwtvr = 1
      ixomga = 1
cahv
_ENDIF
      if(icode.eq.4) return


c
c Set any gradients to zero for atoms not being optimised
c
      do 800 iat = 1,nat
      if(zopti(iat).eq.'no') then
          g((iat-1)*3+1)=0.0d0
          g((iat-1)*3+2)=0.0d0
          g((iat-1)*3+3)=0.0d0
      endif
 800  continue

      gnrm = dnrm2(ncoord,g,1)
      alpha = 0.0d0
      iupdat = 0
      icode = 2

_IF1(v)      bigg = 0.0d0
_IF1(v)      do 1 i = 1,ncoord
_IF1(v)      dum =  dabs(g(i))
_IF1(v)      if (dum .gt. bigg) bigg = dum
_IF1(v)    1 continue
_IF1(u)      bigg=absmax(ncoord,0.0d0,g)
_IF1(f)      call maxmgv(g,1,bigg,loop,ncoord)
_IFN1(fuv)      i=idamax(ncoord,g,1)
_IFN1(fuv)      bigg=dabs(g(i))


c-dbg f

c
c     ----- save restart data -----
c

      call wrrec1(nserch,npts,iupdat,icode,p,g,func0,gs0,alpha,dx,p)
      if (tim.ge.timlim) return
      if (bigg.le.tolg) icode = 3
      if (zruntp.eq.zgrad) icode = 3
      go to 40
 20   alpha = done
_IF(drf)
      if (irepeat .eq. 1) then
        alpha = -alpha
      endif
_ENDIF

      call makdx(g,dx,ncoord,core)
c
c     ----- symmetrize displacement vector -----
c
      call symdr(dx,core)
c
c     ----- search for a minimum in the -dx- direction -----
c
 30   call smsl(tolg,bigg,orstrt,orset,core)
      if (irest.ne.0 .and. tim.ge.timlim) return
      if (nserch.gt.mnls .or. npts.gt.jm) then
         write (iwr,6020)
         icode = 3
      end if
_IF(drf)
      if ((icode .eq. 2) .and. (irepeat .eq. 1)) then
        write (iwr,6020)
        icode = 3
      endif
_ENDIF
 40   dfunc = func - func0

c
c     ----- print update data -----
c
      if(icode.ne.4) then

       write (iwr,6030) nserch , iupdat , npts , func , gnrm , alpha ,
     +                icode , func0 , dfunc

_IF(charmm)
       if(.not. onoatpr)then
_ENDIF
       write (iwr,6040)
       nbqnop = 0
       do 50 iat = 1 , nat
       n = 3*(iat-1)
       if (.not. oprint(31) .or. (zaname(iat)(1:2) .ne. 'bq'))then
          if(zopti(iat).ne.'no') write (iwr,6050) iat ,
     +      zaname(iat),czan(iat) , (p(n+i),i=1,3) ,   (g(n+i),i=1,3)
       else
         nbqnop = nbqnop + 1
       endif
 50    continue
      if (nbqnop .gt. 0)then
         write (iwr,6051) nbqnop
      endif
_IF(charmm)
       endif
_ENDIF
       write (iwr,6060) bigg , tolg , bigg0

      endif
      bigg0 = bigg
      iupdat = iupdat + 1
      nserch = nserch + 1
      if (icode.lt.2) then
c
c     ----- update hessian matrix -----
c
cjk         call seta1(cz,cc,ncoord,core)
cjk Pass through the change in gradient in q
cjk and the step in cz
cjk
         call seta1(q,cz,cc,ncoord,core)
_IF(drf)
         irepeat = 0
_ENDIF
         go to 20
      else if (icode.eq.2) then
c
c     ----- start search -----
c
         icode = 1
         iupdat = 1
         call seta0(ncoord,core)
_IF(drf)
         irepeat = irepeat + 1
_ENDIF
         go to 20
      else if (icode.eq.4) then
         write(iwr,6011)
         return
      else
c
c     ----- end of run -----
c
         nprint = nprino
         write (iwr,6010)
         if(oprn(28)) call anamom(core)
c
c     now suppress distance checking as optimisation complete
c
         ochkdst = .false.
         call intr(core)
         call optend(core,nprint)
c
c     ----- wavefunction properties -----
c
         zruntp = 'prop'
         return
      end if
 6010 format (//1x,104('=')/)
 6011 format (/10x,'Gradient evaluation for IRC finished')
 6020 format (/40x,27('*')/40x,'minimisation not converging'/40x,27('*')
     +        /)
 6030 format (/10x,'nserch  update   npts       func            ',
     +        'gnorm',8x,'  alpha   icode'/10x,i5,i8,i7,f17.8,f15.8,
     +        f14.5,i5//15x,'previous energy',f17.8/15x,
     +        '    convergence',f17.8)
 6040 format (1x,113('*')//30x,'coordinates (bohr)',32x,
     +        'gradient (hartree/bohr)'/8x,'atom     znuc',7x,'x',13x,
     +        'y',13x,'z',20x,'x',13x,'y',13x,'z'/1x,113('*')/)
 6050 format (i3,2x,a8,2x,f6.1,3f14.7,8x,3f14.7)
 6051 format (5x,'Output of ',i5,' BQ centres suppressed')
 6060 format (1x,113('*')//32x,'largest component of gradient ',f14.7,
     +        ' ( tolg = ',f14.7,' )'/32x,
     +        'previous largest component    ',f14.7)
 6070 format (40x,21('*')/40x,'geometry optimization'/40x,21('*')
     +        //' convergence threshold on gradient   = ',
     +        f10.5/' maximum number of calculations      = ',
     +        i10/' restriction distance on coordinates = ',f10.5)
 6071 format (' Updating hessian with BFGS ')
 6072 format (' Updating hessian with Murtagh Sargent ')
      end
      subroutine pre(v,e,m,n,ndim,iw)
c
c     ----- print out e and v-matrices
c     ----- without row-labels
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/prints)
      dimension v(ndim,*),e(*)
      max = 12
      if (oprint(20)) max = 7
      imax = 0
 20   imin = imax + 1
      imax = imax + max
      if (imax.gt.m) imax = m
      write (iw,6010)
      if (oprint(20)) then
         write (iw,6070) (e(i),i=imin,imax)
         write (iw,6010)
         write (iw,6050) (i,i=imin,imax)
         write (iw,6010)
         do 30 j = 1 , n
            write (iw,6060) j , (v(j,i),i=imin,imax)
 30      continue
      else
         write (iw,6040) (e(i),i=imin,imax)
         write (iw,6010)
         write (iw,6020) (i,i=imin,imax)
         write (iw,6010)
         do 40 j = 1 , n
            write (iw,6030) j , (v(j,i),i=imin,imax)
 40      continue
      end if
      if (imax.lt.m) go to 20
      return
 6010 format (/)
 6020 format (15x,12(3x,i3,3x))
 6030 format (i5,10x,12f9.4)
 6040 format (15x,12f9.4)
 6050 format (15x,12(6x,i3,6x))
 6060 format (i5,10x,7f15.10)
 6070 format (15x,7f15.10)
      end
      subroutine putff(nz,lbl,lalpha,lbeta,nparm,nvar,ffx,frcnst,
     $                 ftmp1,ftmp2,fftmp,iprint,iout)
c
c     routine to transform second-derivatives over internal
c     coordinates to second-derivatives over actual z-matriz
c     variables.
c
c     arguments:
c
c     nz     ... number of rows in z-matrix.
c     lbl    ... z-matrix mapping array for bl.
c     lalpha ... z-matrix mapping array for alpha.
c     lbeta  ... z-matrix mapping array for beta.
c     nparm  ... number of z-matrix degrees of freedom.
c     nvar   ... number of actual variables.
c     ffx    ... input matrix of second derivatives (lower
c                triangle.)
c     frcnst ... output matrix of second derivatives over
c                actual variables.
c     ftmp1  ... scratch vector of length (nparm).
c     ftmp2  ... scratch vector of length (nvar).
c     fftmp  ... scratch vector of length (nparm*nvar).
c
      implicit REAL  (a-h,o-z)
      dimension lbl(*),lalpha(*),lbeta(*),ffx(*),frcnst(*)
      dimension ftmp1(*),ftmp2(*),fftmp(*)
c     data zero/0.d0/
c
c     statement function for linear indexing.
      lind(i,j) = (i*(i-1))/2 + j
c
c     clear the output array.
      nvartt = (nvar*(nvar+1))/2
      call vclr(frcnst,1,nvartt)
c
      do 50 i = 1 , nparm
         do 20 j = 1 , i
            ij = lind(i,j)
            ftmp1(j) = ffx(ij)
 20      continue
         do 30 j = i , nparm
            ij = lind(j,i)
            ftmp1(j) = ffx(ij)
 30      continue
         call putf(nz,lbl,lalpha,lbeta,nvar,ftmp1,ftmp2,iprint-1)
         do 40 j = 1 , nvar
            ij = i + nparm*(j-1)
            fftmp(ij) = ftmp2(j)
 40      continue
 50   continue
c
      do 70 i = 1 , nvar
         ii = nparm*(i-1)
         call putf(nz,lbl,lalpha,lbeta,nvar,fftmp(ii+1),ftmp2,
     +             iprint-1)
         do 60 j = 1 , i
            ij = lind(i,j)
            frcnst(ij) = frcnst(ij) + ftmp2(j)
 60      continue
 70   continue
c
c     possibly print frcnst.
      if (iprint.gt.0) then
         write (iout,6010)
         call ltoutd(nvar,frcnst,1)
      end if
c
      return
 6010 format (' from putff, contents of frcnst ')
      end
      subroutine quartc(cx,v,g,n,cordm,ioutp,iout)
c
c ---- this routine fits a polynomial to the qst
c ---  x     is the current position
c ---  v     is the principal direction (negative eigenfunction of hessi
c ---  g     is the gradient
c ---  n     is the dimension of the problem
c ---  cordm is the resulting projection on to the chord
c ---
c ---  lqstyp defines the analytical form of the qst
c ---         =1 a linear function joining current position and a minimu
c ---         =2 a quadratic function joining x and minima
c ---         =3 a quartic function joining x and minima, the 2nd deriv
c ---            at x being the same as if were a quadratic
c ---         =4 a quartic function joining x and minima, the 2nd deriv
c ---            at x is taken to be 0.0
c --- for quartic functions the derivative at x is taken to be +/- the
c --- principal direction (eigen vector of the hessian)
c
c
c ----- fits a polynomial polynomial to the qst
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension cx(*),v(*),g(*)
INCLUDE(common/cntl1)
      common/miscop/cmin1(maxvar),cmin2(maxvar),
     1     coefb(maxvar),coefc(maxvar),coefd(maxvar),coefe(maxvar)
     2,s(maxvar),tans(maxvar),cxm(maxvar),princp(maxvar)
c
c ----- first fit a quadratic
c
      icount = 0
 20   do 30 k = 1 , n
         s(k) = cmin2(k) - cmin1(k)
         cxm(k) = cx(k) - cmin1(k)
 30   continue
      ss = ddot(n,s,1,s,1)
      cordm = ddot(n,cxm,1,s,1)/ss
      if (lqstyp.eq.1) then
c
c --- fit a linear function through x and a minimum
c
         do 40 k = 1 , n
            coefb(k) = (cx(k)-cmin1(k))/cordm
            coefe(k) = (cx(k)-cmin2(k))/(1.0d0-cordm)
 40      continue
c
c --- check that the gradient along the line has the right sign
c
         grad1 = ddot(n,coefb,1,g,1)
         grad2 = ddot(n,coefe,1,g,1)
         if (ioutp.ne.0) write (ioutp,6010) grad1 , grad2
         if (grad1.ge.grad2) then
c
c --- the direction has a -ve gradient so choose the other solution
c --- this is achieved by swapping minima
c
            icount = icount + 1
            if (icount.ge.2) then
               write (iout,6020)
               call caserr2('error in linear qst generation')
            else
               if (ioutp.ne.0) write (ioutp,6030)
_IF1(uv)               do 90 k = 1,n
_IF1(uv)               t = cmin1(k)
_IF1(uv)               cmin1(k) = cmin2(k)
_IF1(uv)               cmin2(k) = t
_IF1(uv)   90          continue
_IFN1(uv)               call dswap(n,cmin1,1,cmin2,1)
               go to 20
            end if
         end if
      else
         do 50 k = 1 , n
            pk = cx(k)
            coefd(k) = 0.0d0
            coefe(k) = 0.0d0
            coefc(k) = (pk-(1.0d0-cordm)*cmin1(k)-cordm*cmin2(k))
     +                 /(cordm*(cordm-1.0d0))
            coefb(k) = s(k) - coefc(k)
            tans(k) = coefb(k) + 2.0d0*cordm*coefc(k)
 50      continue
         if (lqstyp.eq.2) return
c
c ----- work out dot product with desired direction
c
         d = ddot(n,tans,1,v,1)
         if (dabs(d).lt.1.0d-12) return
         d = d/dabs(d)
         dd = dabs(ddot(n,v,1,s,1))/ss
         if (dabs(dd).lt.1.0d-12) return
c
c ----- change search direction if necessary
c
         d = d*dd
         do 60 k = 1 , n
            tans(k) = v(k)/d
 60      continue
c
c ----- now generate the polynomial
c
         if (cordm.lt.0.0d0) return
         if (cordm.gt.1.0d0) return
         r = cordm
         r2 = r*r
         r3 = r2*r
         do 70 k = 1 , n
            q1 = cmin1(k)
            q2 = cx(k)
            q3 = cmin2(k)
            g2 = tans(k)
c
c ---- work out the quartic coeficients
c
            h2 = 0.0d0
            if (lqstyp.eq.3) h2 = 2.0d0*coefc(k)
            e = (r3*(q3-g2-(q1+h2*(1.0d0-2.0d0*r)))-(q2-(q1-h2*r2)-g2*r)
     +          *(3.0d0*r2-3.0d0*r+1.0d0))
     +          /(r3*(3.0d0*r2-r3-3.0d0*r+1.0d0))
            d = ((q2-(q1-h2*r2)-g2*r)-3.0d0*e*r3*r)/r3
            c = h2 - 3.0d0*d*r - 6.0d0*e*r2
            b = q3 - q1 - c - d - e
            coefe(k) = e
            coefd(k) = d
            coefc(k) = c
            coefb(k) = b
            tans(k) = b + 2.0d0*c*r + 3.0d0*d*r2 + 4.0d0*e*r3
 70      continue
         return
      end if
      call vclr(coefc,1,n)
      call vclr(coefd,1,n)
      call vclr(coefe,1,n)
      call dcopy(n,coefb,1,tans,1)
      return
 6010 format (/1x,'quartc...gradients ',2e20.10)
 6020 format (//1x,'error in linear qst generation'//)
 6030 format (//1x,'swapping xmin1 and xmin2'//)
      end
      subroutine rams(rm,ncall,ncode)
c
c     ----- construct the -g- matrix.
c
c  version to use new atomic mass vector storage routines
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/runlab)
INCLUDE(common/work)
      dimension rm(*),amass(maxat)
      data done /1.0d0/

      if(ncall .gt. mass_numvec())then
        ncode = 1
        return
      endif     
      do i = 1,nat
        amass(i) = amass_get(ncall,i)

        if (amass(i).le.0.0d0) then
           write (iwr,6010)
           ncode = 1
           return
        end if
      enddo

      write (iwr,6020)
      do 40 iat = 1 , nat
         write (iwr,6030) iat , zaname(iat) , amass(iat)
 40   continue
      k = 0
      do 60 iat = 1 , nat
         dum = done/dsqrt(amass(iat))
         do 50 j = 1 , 3
            k = k + 1
            rm(k) = dum
 50      continue
 60   continue
      ncode = 0
      return

 6010 format (' *** zero isotope mass encountered  ***')
 6020 format (/10x,21('=')/10x,'atomic weights (a.u.)'/10x,21('=')/)
 6030 format (i5,5x,a8,2x,f15.5)
      end
      subroutine reordd(natoms,iordd,ffxin,ffxout)
      implicit REAL  (a-h,o-z)
c
c     routine to reorder the second derivative matrix (stored
c     in lower triangular form)
c
c     arguments:
c
c     natoms ... number of atoms.
c     iordd ... atom reordering array
c     ffxin  ... input array of second-derivatives.
c     ffxout ... output array
c
      dimension ffxin(*), iordd(*), ffxout(*), t(3,3)
      lind(i,j) = ((max(i,j)*(max(i,j)-1)/2)+min(i,j))
c
c
c     loop over all atoms.
c
      do 70 iat = 1 , natoms
         iord = 3*(iordd(iat)-1)
         i = 3*(iat-1)
         do 60 jat = 1 , iat
            j = 3*(jat-1)
            jord = 3*(iordd(jat)-1)
c
c             pluck out the current (3*3) matrix.
c
            do 30 k = 1 , 3
               do 20 l = 1 , 3
                  loc = lind(k+i,l+j)
                  t(k,l) = ffxin(loc)
 20            continue
 30         continue
c
c             pack the matrix back into ffx.
c
            do 50 k = 1 , 3
               do 40 l = 1 , 3
                  loc = lind(k+iord,l+jord)
                  ffxout(loc) = t(k,l)
 40            continue
 50         continue
 60      continue
 70   continue
      return
      end
      function rmsfp(d1var,pool1,cold,nvar,mode)
c
c     compute the root mean square force or displacement for a
c     fletcher-powell geometry optimization.
c
c     if mode=1 calculate the rms force
c
c     if mode=2 calculate the rms displacement between points.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension pool1(*),cold(*),d1var(*)
      data dzero/0.d0/
c
c     branch on mode.
c
      go to (20,30) , mode
c
c     calculate the rms force.
c
 20   sum = ddot(nvar,d1var,1,d1var,1)
      var = dfloat(nvar)
      rmsfp = dsqrt(sum/var)
      return
c
c     compute the rms displacement.
c
 30   sum = dzero
      do 40 i = 1 , nvar
         diff = pool1(nvar) - cold(nvar)
         sum = sum + diff*diff
 40   continue
      var = dfloat(nvar)
      rmsfp = dsqrt(sum/var)
      return
      end
      subroutine rootsb(g,h,step2,al0,alb,aub,fm,fmp,fmpp,
     *                  dv,dvp,dvpp,n,ioutp,iout)
c
c    solve miller equations
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension g(*),h(*)
INCLUDE(common/prints)
      stepmx = dsqrt(step2)
      if (oprint(44) .and. ioutp.ne.0) write (ioutp,6010) stepmx , 
     +     alb , aub
      al = al0
      ic = 0
 20   ic = ic + 1
      if (al.gt.aub) al = (alb+aub)*0.5d0
      if (al.lt.alb) al = (alb+aub)*0.5d0
      if (ic.le.25) then
         fm = 0.0d0
         fmp = 0.0d0
         fmpp = 0.0d0
         dv1 = 0.0d0
         dv2 = 0.0d0
         dv3 = 0.0d0
         do 30 k = 1 , n
            at1 = al - h(k)
            at2 = at1*at1
            at3 = at2*at1
            at4 = at2*at2
            if (at4.lt.1.0d-30) go to 40
            g2 = g(k)*g(k)
            fm = fm + g2/at2
            fmp = fmp - g2/at3
            fmpp = fmpp + g2/at4
            dv1 = dv1 + h(k)*g2/at2
            dv2 = dv2 + h(k)*g2/at3
            dv3 = dv3 + h(k)*g2/at4
 30      continue
         fmp = fmp + fmp
         fmpp = fmpp*6.0d0
         dv = al*fm - 0.5d0*dv1
         dvp = fm + al*fmp + dv2
         dvpp = fmp + al*fmpp - 3.0d0*dv3
         if (fmp.gt.0.0d0 .and. fm.gt.step2) aub = al
         if (fmp.gt.0.0d0 .and. fm.lt.step2) alb = al
         if (fmp.lt.0.0d0 .and. fm.gt.step2) alb = al
         if (fmp.lt.0.0d0 .and. fm.lt.step2) aub = al
         dl = (step2-fm)/fmp
         if (oprint(44) .and. ioutp.ne.0) write (ioutp,6020) ic , al , 
     +       fm , fmp , dl
         if (dabs(dl).ge.1.0d-8) then
            al = al + dl
            go to 20
         end if
      end if
      al0 = al
      return
 40   write (iout,6030)
      al0 = 0.0d0
      return
 6010 format (/1x,'root finding for the trust region',f14.6/1x,
     +        'lower bound to root ',f14.6/1x,'upper bound to root ',
     +        f14.6/1x,10x,'lambda',4x,'del squared',5x,'1st deriv',10x,
     +        'step')
 6020 format (1x,i3,4f14.6)
 6030 format (//1x,'numerical problems in rootsb'//)
      end
      subroutine rootsc(g,h,alamb,stepmx,ityp,jtyp,n,ioutp,iout)
c
c        finds the roots of miller's equations....
c         j.c.p. 75 (1981) 2800
c
c    g....the gradients in metric space
c    h....the hessian in metric space (diagonal)
c alamb...the solution (an effective shift parameter)
c stepmx..the restricted size step
c ityp....1 for a minimum search
c         2 for a saddle point search
c jtyp....the type of step to be taken (see mnter)
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/prints)
      dimension g(*), h(*)
      alb = h(1)
      aub = h(2)
c
c      find a minimum in the function
c
      step2 = stepmx*stepmx
      if (oprint(44) .and. ioutp.ne.0) write (ioutp,6010) h(1) , h(2)
      ic = 0
      al = (alb+aub)*0.5d0
c
c       find the minimum of the miller equations
c
      past = al
 20   ic = ic + 1
      if (ic.gt.30) go to 70
      if (al.gt.aub) al = aub - (aub-past)*0.5d0
      if (al.lt.alb) al = alb - (alb-past)*0.5d0
      past = al
      fm = 0.0d0
      fmp = 0.0d0
      fmpp = 0.0d0
      dv1 = 0.0d0
      dv2 = 0.0d0
      dv3 = 0.0d0
      do 30 k = 1 , n
         at1 = al - h(k)
         at2 = at1*at1
         at3 = at2*at1
         at4 = at2*at2
         if (at4.lt.1.0d-30) go to 70
         g2 = g(k)*g(k)
         fm = fm + g2/at2
         fmp = fmp - g2/at3
         fmpp = fmpp + g2/at4
         dv1 = dv1 + h(k)*g2/at2
         dv2 = dv2 + h(k)*g2/at3
         dv3 = dv3 + h(k)*g2/at4
 30   continue
      fmp = fmp + fmp
      fmpp = fmpp*6.0d0
      dv = al*fm - 0.5d0*dv1
      dvp = fm + al*fmp + dv2
      dvpp = fmp + al*fmpp - 3.0d0*dv3
      dl = -fmp/fmpp
      if (oprint(44) .and. ioutp.ne.0) write (ioutp,6020) al , fm , 
     +    fmp , fmpp
      if (fmp.gt.0.0d0) aub = al
      if (fmp.lt.0.0d0) alb = al
      al = al + dl
      if (dabs(dl).gt.1.0d-10) go to 20
      al0 = al
      fm0 = fm
      fmp0 = fmp
      fmpp0 = fmpp
      dv0 = dv
      dvp0 = dvp
      dvpp0 = dvpp
      if (ioutp.ne.0) write (ioutp,6030) fm0 , fmp0 , fmpp0 , dv0 ,
     +                       dvp0 , dvpp0
      if (oprint(44)) then
         nstep = 200
         dl = (aub-alb)/(nstep+1)
         al = aub + dl
         do 50 i = 1 , nstep
            fm = 0.0d0
            dv1 = 0.0d0
            dv2 = 0.0d0
            dv3 = 0.0d0
            do 40 k = 1 , n
               at1 = al - h(k)
               at2 = at1*at1
               at3 = at2*at1
               at4 = at2*at2
               if (at4.ge.1.0d-30) then
                  g2 = g(k)*g(k)
                  fm = fm + g2/at2
                  dv1 = dv1 + h(k)*g2/at2
                  dv2 = dv2 + h(k)*g2/at3
                  dv3 = dv3 + h(k)*g2/at4
               end if
 40         continue
            dv = al*fm - 0.5d0*dv1
            dvp = fm + al*fmp + dv2
            dvpp = fmp + al*fmpp - 3.0d0*dv3
            if (oprint(44) .and. ioutp.ne.0) write (ioutp,6040) i , al ,
     +          fm , dv , dvp , dvpp
            al = al + dl
 50      continue
      end if
c
c          does one take the minimum possible value??
c
      jtyp = 8
c
c         set up for a minimisation case
c
      if (fm0.gt.step2) go to 60
      alb = -5.0d0*h(n)
      aub = 0.0d0
      al = -1.0d0
      jtyp = 9
c
c     set up for saddle point...is there a -ve e-value?
c
      if (ityp.ne.1) then
c
c    set up for a ridge step
c
         if (h(1).gt.0.0d0) then
c
c      find 3 possible solutions to this problem
c
            jtyp = 12
            al1 = h(1)
            au1 = al0
            a1 = (al1+au1)*0.5d0
            call rootsb(g,h,step2,a1,al1,au1,f1,f1p,f1pp,d1,d1p,d1pp,n,
     +                  ioutp,iout)
            al2 = al0
            au2 = h(2)
            a2 = (al2+au2)*0.5d0
            call rootsb(g,h,step2,a2,al2,au2,f2,f2p,f2pp,d2,d2p,d2pp,n,
     +                  ioutp,iout)
            al3 = h(2)
            au3 = 5.0d0*h(n)
            a3 = al3 + dabs(h(1)-h(2))*0.01d0
            call rootsb(g,h,step2,a3,al3,au3,f3,f3p,f3pp,d3,d3p,d3pp,n,
     +                  ioutp,iout)
            if (ioutp.ne.0) write (ioutp,6050) a1 , d1 , d1p , d1pp ,
     +                             a2 , d2 , d2p , d2pp , a3 , d3 ,
     +                             d3p , d3pp
            al0 = a1
            if (d2.gt.0.0d0 .and. d2.lt.d1 .and. d2.lt.d3) al0 = a2
c
c      find a solution of the equations
c
            if (d3.gt.0.0d0 .and. d3.lt.d1 .and. d3.lt.d2) al0 = a3
            go to 60
         else
            alb = al0
            aub = h(2)
            al = (alb+aub)*0.5d0
            jtyp = 10
c
c       set up for a step along the valley
c
            if (dvpp0.ge.0.0d0) then
               alb = h(1)
               aub = al0
               al = (alb+aub)*0.5d0
c
c     all e-values +ve so climb out of minimum
c
               jtyp = 11
            end if
         end if
      end if
c
c    hurray..the root is found ..
c
      call rootsb(g,h,step2,al,alb,aub,fm,fmp,fmpp,dv,dvp,dvpp,
     +            n,ioutp,iout)
      al0 = al
 60   alamb = al0
      return
c
c        numerical problems....
c
 70   write (iout,6060)
      alamb = 0.0d0
      return
 6010 format (/1x,'iterative solution of miller s equations',1x,
     +        2f20.10/1x,9x,'lambda',4x,'del squared',1x,
     +        '1st derivative',1x,'2nd derivative')
 6020 format (1x,4f15.7)
 6030 format (//1x,'miller function del squared ',3e20.10/1x,
     +        'miller function del v       ',3e20.10)
 6040 format (1x,i3,5f14.6)
 6050 format (/1x,'climbing out of a valley'/1x,46x,5x,'1st deriv',5x,
     +        '2nd deriv'/1x,'lambda 1 ',f14.7,' delta v ',3f14.6/1x,
     +        'lambda 2 ',f14.7,' delta v ',3f14.6/1x,'lambda 3 ',f14.7,
     +        ' delta v ',3f14.6)
 6060 format (//1x,'numerical problems in rootsc'//)
      end
      subroutine rotf(natoms,tr,fin,fout)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
      dimension tr(3,3),fin(*),fout(*)
      do 20 iat = 1 , natoms
         i = 3*(iat-1)
         tx = tr(1,1)*fin(i+1) + tr(2,1)*fin(i+2) + tr(3,1)*fin(i+3)
         ty = tr(1,2)*fin(i+1) + tr(2,2)*fin(i+2) + tr(3,2)*fin(i+3)
         tz = tr(1,3)*fin(i+1) + tr(2,3)*fin(i+2) + tr(3,3)*fin(i+3)
         fout(i+1) = tx
         fout(i+2) = ty
         fout(i+3) = tz
 20   continue
      return
      end
      subroutine rotff(natoms,tr,ffxin,ffxout)
      implicit REAL  (a-h,o-z)
c
c     routine to rotate the second derivative matrix (stored
c     in lower triangular form) from one axis system to another.
c
c     arguments:
c
c     natoms ... number of atoms.
c     tr     ... (3 by 3) rotation matrix.
c     ffxin  ... input array of second-derivatives.
c     ffxout ... output array, can be same as input array.
c
      dimension ffxin(*), tr(3,3), ffxout(*), t(3,3), t1(3,3)
      data zero/0.d0/
      lind(i,j) = ((max(i,j)*(max(i,j)-1)/2)+min(i,j))
c
c
c     loop over all atoms.
c
      do 130 iat = 1 , natoms
         i = 3*(iat-1)
         do 120 jat = 1 , iat
            j = 3*(jat-1)
c
c             pluck out the current (3*3) matrix.
c
            do 30 k = 1 , 3
               do 20 l = 1 , 3
                  loc = lind(k+i,l+j)
                  t(k,l) = ffxin(loc)
 20            continue
 30         continue
c
c             transform by tr.
c
            do 60 k = 1 , 3
               do 50 l = 1 , 3
                  t1(k,l) = zero
                  do 40 m = 1 , 3
                     t1(k,l) = t1(k,l) + tr(m,l)*t(k,m)
 40               continue
 50            continue
 60         continue
            do 90 l = 1 , 3
               do 80 k = 1 , 3
                  t(k,l) = zero
                  do 70 m = 1 , 3
                     t(k,l) = t(k,l) + tr(m,k)*t1(m,l)
 70               continue
 80            continue
 90         continue
c
c             pack the matrix back into ffx.
c
            do 110 k = 1 , 3
               do 100 l = 1 , 3
                  loc = lind(k+i,l+j)
                  ffxout(loc) = t(k,l)
 100           continue
 110        continue
 120     continue
 130  continue
      return
      end
      subroutine saddleopt(cx,en0,g,hesx,cz,exx,gxx,n,ny,ifail,ioutp,
     *core,pold,hdiag,gz,gama,tan2,fkp,lines,iwr)
c
c ------ this is the driving routine for the saddle point search
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension cx(n),g(n),hesx(n,n),hes(2,2),cz(n,n)
      dimension fkp(4,*),lines(4,*)
      dimension core(*)
      dimension exx(200,*),gxx(200,*)
      dimension pold(*),hdiag(*)
      dimension gz(*),gama(*),tan2(*)
INCLUDE(common/prints)
INCLUDE(common/cntl1)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
_ENDIF
      common/miscop/cmin1(maxvar),cmin2(maxvar),
     1     coefb(maxvar),coefc(maxvar),coefd(maxvar),coefe(maxvar)
     2,      s(maxvar),tans(maxvar),cxm(maxvar),princp(maxvar),
     3gx1(maxvar),gx2(maxvar),cx1(maxvar),cx2(maxvar)
     4,cy(maxvar),del(maxvar)
     5,px1,px2,px3,ff1,ff2,ff3,gg1,gg2,gg3,ener(22)
      external sfun1,sfun2,sfun3,sfun4
      data yno,yes/'no','yes'/
      hk = stepmx
      iterzx = 0
      likeep = lintyp
      omillr = .false.
      opold = .false.
      if (lqstyp.ge.5) omillr = .true.
      osrcmx = .true.
      if (lqstyp.eq.6) osrcmx = .false.
      if (omillr) lqstyp = 4
      cordmx = 0.0d0
      lqkeep = lqstyp
      if (lqstyp.gt.2) lqstyp = 2
      grad = 0.0d0
      call mnter(en0,grad,g,n,2,1,fkp,lines,iwr)
      nls = 0
      hesmax = -0.4d0
      f = en0
      ifail = 2
      do 20 k = 1 , n
         princp(k) = cmin2(k) - cmin1(k)
         if (dabs(princp(k)).gt.cordmx) cordmx = dabs(princp(k))
 20   continue
      ncount = 0
      do 30 i = 1 , n
         if (dabs(cz(i,1)).ge.1.0d-9) then
            ncount = ncount + 1
         end if
 30   continue
      if (ncount.gt.1) then
c
c     if the lowest root of the hessian has more
c     than one componentin it, use original lqstyp
c
         lqstyp = lqkeep
c
         call dcopy(n,cz(1,1),1,princp(1),1)
      end if
      if (dabs(cordmx).lt.1.0d-4) cordmx = 5.0d0*stepmx
      cordmx = stepmx/cordmx
      if (n.lt.1) go to 370
c
c ----- energy and gradients for the first point should already be known
c
      if (mnls.lt.1) go to 370
      ifail = 0
c
c ----- search for a maximum so change sign of energy and gradients
c
      nftotl = 1
 40   iterz = 0
c
c ----- scale principal direction so as to give correct step to min.
c
      sqrtgg=dnrm2(n,g,1)
      if (sqrtgg.lt.stol*0.001d0) go to 360

      if(lqstyp.eq.4)then
         d1 = ddot(n,princp,1,g,1)
         call mulmat(hesx,hes,princp,n,1)
         d1 = -d1/hes(1,1)
         delmx = 0.0d0
         do 50 k = 1 , n
            pold(k) = princp(k)*d1
            if (dabs(pold(k)).gt.delmx) delmx = dabs(pold(k))
            princp(k) = pold(k)
 50      continue
         opold = .true.
      else 
         delmx = 0.0d0
      endif

      if (delmx.lt.stepmx*0.01d0 .and. omillr) go to 270
c
c
c ----- try a quartic fit through the minima and the current point
c
      if (.not.osrcmx) go to 270
      call quartc(cx,princp,g,n,cordm,ioutp,iwr)
c
c ----- keep a copy of current position for convergence testing
c
      f = -f
      do 60 k = 1 , n
         g(k) = -g(k)
 60   continue
c
c ----- check that cordm lies between 0 and 1
c
      if (cordm.ge.0.0d0 .and. cordm.le.1.0d0) then
c
c ----- now set up for search for a maximum
c
         if (ioutp.ne.0) write (ioutp,6010)
         if (oprint(44)) then
            if (ioutp.ne.0) then
               write (ioutp,6020) (princp(k),k=1,n)
               write (ioutp,6030) (cmin1(k),k=1,n)
               write (ioutp,6040) (coefb(k),k=1,n)
               write (ioutp,6050) (coefc(k),k=1,n)
               write (ioutp,6060) (coefd(k),k=1,n)
               write (ioutp,6070) (coefe(k),k=1,n)
               write (ioutp,6090)
               do 70 i = 1 , n
                  write (ioutp,6080) (hesx(i,j),j=1,n)
 70            continue
            end if
         end if
         tanorm = ddot(n,tans,1,tans,1)
         gts = ddot(n,g,1,tans,1)
         call mulmat(hesx,hes,tans,n,1)
         esth1 = -hes(1,1)
         if (esth1.le.0.0d0) esth1 = -hesmax
         do 80 i = 1 , n
            cxm(i) = 2.0d0*coefc(i) + 6.0d0*cordm*coefd(i)
     +               + 12.0d0*cordm*cordm*coefe(i)
 80      continue
         esth2 = ddot(n,g,1,cxm,1)
         esth = esth1 + esth2
         if (esth.le.0.0d0) esth = 0.4d0
         step = -gts/esth
         if (dabs(step).gt.cordmx) step = cordmx*step/dabs(step)
         if (ioutp.ne.0) write (ioutp,6100) esth1 , esth2 , esth , gts ,
     +                          tanorm , cordm , step
c
c ----- check bounds on the step
c
         if (step+cordm.gt.1.0d0) step = (1-cordm)*0.4d0
         if (step+cordm.lt.0.0d0) step = -cordm*0.4d0
         ineg = 1
         ireord = 0
c
c ----- invert hessian here ready for update later
c
         call inveig(hesx,hesx,n,cxm,eigmin,eigmax,ineg,ireord,iwr)
c
c
c ----- work out the x-space convergence parameters
c
         dxrms = 0.0d0
         dxmax = 0.0d0
         gxrms = 0.0d0
         gxmax = 0.0d0
         do 100 i = 1 , n
            dx = 0.0d0
            do 90 j = 1 , n
               dx = dx - g(j)*hesx(j,i)
 90         continue
            gxrms = gxrms + g(i)*g(i)
            dxrms = dxrms + dx*dx
            if (dabs(g(i)).gt.gxmax) gxmax = dabs(g(i))
            if (dabs(dx).gt.dxmax) dxmax = dabs(dx)
 100     continue
         dxrms = dsqrt(dxrms)/n
         gxrms = dsqrt(gxrms)/n
         stol1 = stol
         stol2 = stol*0.6666666d0
         stol3 = stol*0.25d0
         stol4 = stol*0.1666666d0
         oolx1 = dxmax.lt.stol1
         oolx2 = dxrms.lt.stol2
         oolx3 = gxmax.lt.stol3
         oolx4 = gxrms.lt.stol4
         yout1 = yno
         yout2 = yno
         yout3 = yno
         yout4 = yno
         if (oolx1) yout1 = yes
         if (oolx2) yout2 = yes
         if (oolx3) yout3 = yes
         if (oolx4) yout4 = yes
         if (ioutp.ne.0) write (ioutp,6110) dxmax , stol1 , yout1 ,
     +                          dxrms , stol2 , yout2 , gxmax , stol3 ,
     +                          yout3 , gxrms , stol4 , yout4
c
c
c ----- overall convergence tests
c
         if (oolx1 .and. oolx2 .and. oolx3 .and. oolx4) go to 360
         cord = cordm
         ismax = 1
         elow = step*gts
         lintyp = likeep
         if (dabs(elow).lt.5.0d-6) lintyp = 1
         if (ioutp.ne.0) write (ioutp,6120) elow
_IF(ccpdft)
         if (CD_active()) then
            ierror = CD_jfit_init1()
            if (ierror.ne.0) then
               write(iwr,600)ierror
               call caserr2('Out of memory')
            endif
         endif
 600     format('*** Need ',i10,' more words to store fitting ',
     +          'coefficients and Schwarz tables in core')
_ENDIF
         if (lintyp.eq.0) call linesf(f,cord,step,gts,esth,cx,g,hesx,
     +                                exx,gxx,n,n,sfun3,ifail,ioutp,
     +                                core,fkp,lines,iwr)
         if (lintyp.ne.0) call linesg(f,cord,step,gts,esth,cx,g,hesx,
     +                                exx,gxx,n,n,sfun3,ifail,ioutp,
     +                                core,fkp,lines,iwr)
_IF(ccpdft)
         if (CD_active()) then
            ierror = CD_jfit_clean1()
            if (ierror.ne.0) then
               call caserr2('Memory failure in saddle:CD_jfit_clean1')
            endif
         endif
_ENDIF
         ismax = 0
         nls = nls + 1
         en0 = -f
         if (nls.ge.mnls) go to 370
         if (ifail.ne.0) return
         f = -f
         do 110 k = 1 , n
            gx1(k) = -gx1(k)
            gx2(k) = -gx2(k)
            g(k) = -g(k)
 110     continue
c
c ----- work out the new tangent  (based on last 2 points of search)
c
         do 120 k = 1 , n
            b = coefb(k)
            c = coefc(k)*2.0d0
            d = coefd(k)*3.0d0
            e = coefe(k)*4.0d0
            tans(k) = b + c*cordm + d*cordm*cordm + e*cordm*cordm*cordm
            tan2(k) = b + c*cord + d*cord*cord + e*cord*cord*cord
 120     continue
         if (oprint(44)) then
            if (ioutp.ne.0) write (ioutp,6130) (tans(k),k=1,n)
            if (ioutp.ne.0) write (ioutp,6140) (tan2(k),k=1,n)
         end if
         tanorm = ddot(n,tan2,1,tan2,1)
         tnor = dsqrt(tanorm)
c
c ----- update hessian along quartic
c
         do 130 i = 1 , n
            cxm(i) = 2.0d0*coefc(i) + 6.0d0*cordm*coefd(i)
     +               + 12.0d0*cordm*cordm*coefe(i)
 130     continue
         esth2 = -ddot(n,g,1,cxm,1)
         hesmax = esth - esth2
         hesmax = -hesmax/tanorm
         if (oprint(44) .and. ioutp.ne.0) write (ioutp,6150) hesmax
         if (hesmax.gt.0.0d0) hesmax = -0.4d0
c
c ---- if the tangents are not colinear or nearly then the
c ---- directions will not be conjugate to the quartic
c
c        gg = ddot(n,g,1,g,1)
_IFN1(u)         cos12 = ddot(n,tans,1,tan2,1)
_IFN1(u)     +           /dsqrt(ddot(n,tans,1,tans,1)*ddot(n,tan2,1,tan2,1))
c
_IF1(u)         cos12 = vecsum(tans,tan2,n)
         ineg = 1
c
c ---- update inverse hessian from last
c ---- two points in the maximum search
c
         call updateh(cx2,cx,gx2,g,hesx,cz,cxm,n,ineg,ifail,iwr)
         if (ifail.ne.0) return
         call monit(nls,hesx,n,ioutp,core)
         if (omillr) then
            ineg = 1
            t2 = -1.0d20
            t1 = 1.0d20
            ireord = 1
            call diaeig(hesx,cz,n,hdiag,t2,t1,ineg,ireord,iwr)
            go to 280
         else
            if (cos12.gt.0.999999999d0) cos12 = 0.999999999d0
            sin12 = dsqrt(1.0d0-cos12*cos12)
            oolx1 = sin12.le.tolstp
            yout1 = yes
            if (oolx1) yout1 = yno
            if (ioutp.ne.0) write (ioutp,6160) sin12 , tolstp , yout1
c
c ---- we moved too far along the chord so calcuate a new point
c
            if (.not.(oolx1)) then
               if (ioutp.ne.0) write (ioutp,6170)
               do 140 i = 1 , n
                  cxm(i) = cx(i) - cx2(i)
 140           continue
               direc = ddot(n,cxm,1,tan2,1)
               direc = direc/dabs(direc)
_IFN1(u)               anorm = dnrm2(n,cxm,1)
_IF1(u)               anorm=vecsum(cxm,cxm,n)
_IF1(u)               anorm=dsqrt(anorm)
               anorm = direc*tanstp*anorm/tnor
               do 150 i = 1 , n
                  cx1(i) = cx(i)
                  gx1(i) = g(i)
                  cx2(i) = cx(i) + anorm*tan2(i)
 150           continue
_IF(ccpdft)
               if (CD_active()) then
                  ierror = CD_jfit_init1()
                  if (ierror.ne.0) then
                     write(iwr,600)ierror
                     call caserr2('Out of memory in incore coulomb fit')
                  endif
               endif
_ENDIF
               call calcfg(0,n,cx2,f2,gx2,exx,gxx,ioutp,core,fkp,lines)
               call calcfg(3,n,cx2,f2,gx2,exx,gxx,ioutp,core,fkp,lines)
_IF(ccpdft)
               if (CD_active()) then
                  ierror = CD_jfit_clean1()
                  if (ierror.ne.0) then
                     call caserr2(
     +                    'Memory problem detected in CD_jfit_clean1')
                  endif
               endif
_ENDIF
               call mnter(f2,grad,gx2,n,2,4,fkp,lines,iwr)
               nftotl = nftotl + 1
               ineg = 1
               call updateh(cx2,cx1,gx2,gx1,hesx,cz,cxm,n,ineg,ifail,
     +                     iwr)
               if (ifail.ne.0) return
c
c ----- come through here only if its time to search for a minimum
c
               call monit(nls,hesx,n,ioutp,core)
            end if
            if (iterzx.ge.0) lqstyp = lqkeep
c
c ----- generate new z-directions by diagonalisation
c
            iterzx = iterzx + 1
            ineg = 1
            t1 = 1.0d20
            t2 = -1.0d20
            ireord = 1
            call diaeig(hesx,cz,n,hdiag,t2,t1,ineg,ireord,iwr)
 160        if (ioutp.ne.0) write (ioutp,6180)
            do 170 i = 1 , n
               princp(i) = cz(i,1)
 170        continue
            ph = hdiag(1)
            ing = 1
            jp = 0
            do 190 j = 1 , ny
               jp = jp + 1
               if (jp.eq.ing) jp = jp + 1
               if (ioutp.ne.0) write (ioutp,6080) (cz(i,jp),i=1,n)
               hdiag(j) = hdiag(jp)
               do 180 i = 1 , n
                  cz(i,j) = cz(i,jp)
 180           continue
 190        continue
            pd = ddot(n,princp,1,g,1)
            do 200 i = 1 , n
               princp(i) = -pd*ph*princp(i)
 200        continue
            if (ioutp.ne.0) write (ioutp,6190)
c
c ----- now we must work in z-space
c ----- transform gradients to z space
c
            do 210 j = 1 , ny
               gz(j) = ddot(n,cz(1,j),1,g,1)
 210        continue
c
c ----- make a current copy of position and gradient in x-space
c
            call dcopy(n,g,1,gama,1)
c
c ----- form trial step in z-space
c
            call dcopy(n,cx,1,cy,1)
            gts = 0.0d0
            do 220 i = 1 , ny
               del(i) = -hdiag(i)*gz(i)
               if (dabs(del(i)).gt.gts) gts = dabs(del(i))
 220        continue
            scale = 1.0d0
            if (gts.gt.hk) scale = hk/gts
            gts = 0.0d0
            do 230 i = 1 , ny
               del(i) = del(i)*scale
               dx = del(i)
               if (dabs(dx).gt.dxmax) dxmax = dabs(dx)
               dxrms = dx*dx
               gts = gts + dx*gz(i)
 230        continue
            if (oprint(44)) then
               if (ioutp.ne.0) write (ioutp,6200) (gz(k),k=1,ny)
               if (ioutp.ne.0) write (ioutp,6210) (del(k),k=1,ny)
            end if
            if (ioutp.ne.0) write (ioutp,6220) (cy(k),k=1,n)
            if (ioutp.ne.0) write (ioutp,6230) (gama(k),k=1,n)
c
c ----- work out the z-space convergence parameters
c
            dzrms = 0.0d0
            dzmax = 0.0d0
            gzrms = 0.0d0
            gzmax = 0.0d0
            gz(n) = 0.0d0
            do 240 i = 1 , ny
               dz = del(i)
               gzrms = gzrms + gz(i)*gz(i)
               dzrms = dzrms + dz*dz
               if (dabs(gz(i)).gt.gzmax) gzmax = dabs(gz(i))
               if (dabs(dz).gt.dzmax) dzmax = dabs(dz)
 240        continue
            dzrms = dsqrt(dzrms)/ny
            gzrms = dsqrt(gzrms)/ny
            stol1 = stol
            stol2 = stol*0.6666666d0
            stol3 = stol*0.25d0
            stol4 = stol*0.1666666d0
            oolz1 = dzmax.lt.stol1
            oolz2 = dzrms.lt.stol2
            oolz3 = gzmax.lt.stol3
            oolz4 = gzrms.lt.stol4
            yout1 = yno
            yout2 = yno
            yout3 = yno
            yout4 = yno
            if (oolz1) yout1 = yes
            if (oolz2) yout2 = yes
            if (oolz3) yout3 = yes
            if (oolz4) yout4 = yes
            if (ioutp.ne.0) write (ioutp,6240) dzmax , stol1 , yout1 ,
     +                             dzrms , stol2 , yout2 , gzmax ,
     +                             stol3 , yout3 , gzrms , stol4 , yout4
            elow = ddot(ny,del,1,gz,1)
            if (ioutp.ne.0) write (ioutp,6250) elow
            lintyp = likeep
            if (dabs(elow).lt.5.0d-6) lintyp = 1
c
c ---- test for z-space convergence
c
            if (.not.(oolz1 .and. oolz2 .and. oolz3 .and. oolz4)) then
               alpha = 0.0d0
               step = 1.0d0
               esth = 1.0d0
               ismax = 0
c
c ---- commence a line search in z-space
c
_IF(ccpdft)
               if (CD_active()) then
                  ierror = CD_jfit_init1()
                  if (ierror.ne.0) then
                     write(iwr,600)ierror
                     call caserr2('Out of memory')
                  endif
               endif
_ENDIF
               if (lintyp.eq.0) call linesf(f,alpha,step,gts,esth,cx,g,
     +             cz,exx,gxx,ny,n,sfun2,ifail,ioutp,core,fkp,
     +             lines,iwr)
               if (lintyp.ne.0) call linesg(f,alpha,step,gts,esth,cx,g,
     +             cz,exx,gxx,ny,n,sfun2,ifail,ioutp,core,fkp,
     +             lines,iwr)
_IF(ccpdft)
               if (CD_active()) then
                  ierror = CD_jfit_clean1()
                  if (ierror.ne.0) then
                     call caserr2(
     +                    'Memory failure in saddle:CD_jfit_clean1')
                  endif
               endif
_ENDIF
               nls = nls + 1
               en0 = f
               if (nls.ge.mnls) go to 370
               if (ifail.ne.0) return
               iterz = iterz + 1
c
c    z-space convergence tests
c
               if (.not.(oolz1 .and. oolz2 .and. oolz3 .and. oolz4))
     +             then
c
c ----- update hessian in x-space
c
                 ineg = 0
                 call updateh(cy,cx,gama,g,hesx,cz,gx2,n,ineg,ifail,iwr)
                 if (ifail.ne.0) return
c
c
c ----- could test here for failure in update and reset hessian
c
c ---- at this point we might still have to go back and calculate
c ---- a better maximum position
c
                  call monit(nls,hesx,n,ioutp,core)
                  ineg = 1
                  t1 = 1.0d20
                  t2 = -1.0d20
                  ireord = 1
                  call diaeig(hesx,cz,n,hdiag,t2,t1,ineg,ireord,iwr)
                  if (opold) then
                  test = ddot(n,pold,1,cz(1,1),1)/dnrm2(n,pold,1)
                  test = 1.0d0 - dabs(test)
                  endif
                  if (ioutp.ne.0.and.opold) write (ioutp,6260) test
                  if (test.le.tolmax.and.opold) then
                     call testan(cx,g,test,n,iflag,ifail,ioutp,iwr)
                     if (ifail.ne.0) return
                     if (iflag.eq.0) go to 160
                     if (omillr) go to 280
                  end if
               end if
            end if
         end if
      else
         if (cordm.lt.0.0d0) cordm = -cordm
c
c ----- generate a new point and try all over again
c
         if (cordm.gt.1.0d0) cordm = 2.0d0 - cordm
         do 250 k = 1 , n
            cx(k) = cmin1(k) + coefb(k)*cordm + coefc(k)*cordm*cordm
 250     continue
         if (ioutp.ne.0) write (ioutp,6270) cordm
_IF(ccpdft)
         if (CD_active()) then
            ierror = CD_jfit_init1()
            if (ierror.ne.0) then
               write(iwr,600)ierror
               call caserr2('Out of memory in incore coulomb fit')
            endif
         endif
c600     format('*** Need ',i10,' more words to store fitting ',
c    +          'coefficients and Schwarz tables in core')
_ENDIF
         call calcfg(0,n,cx,f,g,exx,gxx,ioutp,core,fkp,lines)
         call calcfg(3,n,cx,f,g,exx,gxx,ioutp,core,fkp,lines)
_IF(ccpdft)
         if (CD_active()) then
            ierror = CD_jfit_clean1()
            if (ierror.ne.0) then
               call caserr2('Memory problem detected in CD_jfit_clean1')
            endif
         endif
_ENDIF
         grad = 0.0d0
         call mnter(f,grad,g,n,2,5,fkp,lines,iwr)
         nftotl = nftotl + 1
         lqstyp = 2
         go to 40
      end if
c
c ---- failing off the saddle ridge so go back and calculate max
c
      ineg = 1
      t1 = 1.0d20
      t2 = -1.0d20
      ireord = 1
      call inveig(hesx,cz,n,cxm,t2,t1,ineg,ireord,iwr)
c
c ----- lowest eigenvector is the principal direction
c
      do 260 k = 1 , n
         princp(k) = cz(k,1)
 260  continue
      go to 40
c
c        miller's method for finding a maximum
c
 270  ineg = 1
      t2 = eigmin
      t1 = eigmax
      ireord = 0
      call inveig(hesx,cz,n,hdiag,t2,t1,ineg,ireord,iwr)
 280  do 290 k = 1 , n
         hdiag(k) = 1.0d0/hdiag(k)
 290  continue
      delmx = 0.0d0
      do 310 j = 1 , n
         gama(j) = g(j)
         cy(j) = cx(j)
         gj = 0.0d0
         do 300 i = 1 , n
            gj = gj + cz(i,j)*g(i)
 300     continue
         ddd = dabs(gj/hdiag(j))
         delmx = delmx + ddd*ddd
         gz(j) = gj
 310  continue
      delmx = dsqrt(delmx)
      alamb = 0.0d0
      jtyp = 13
      if (delmx.gt.hk .or. hdiag(1).gt.0.0d0)
     +    call rootsc(gz,hdiag,alamb,hk,2,jtyp,n,ioutp,iwr)
c
c     work out the modified newton raphson step
c
      do 320 i = 1 , n
         del(i) = gz(i)/(alamb-hdiag(i))
 320  continue
      gts = dnrm2(n,del,1)
      scale = 1.0d0
      if (gts.gt.hk) scale = hk/gts
      gts = 0.0d0
      do 330 i = 1 , n
         del(i) = del(i)*scale
         gts = gts + del(i)*gz(i)
 330  continue
      if (oprint(44)) then
         if (ioutp.ne.0) write (ioutp,6200) (gz(k),k=1,n)
         if (ioutp.ne.0) write (ioutp,6210) (del(k),k=1,n)
      end if
      if (ioutp.ne.0) write (ioutp,6220) (cy(k),k=1,n)
      if (ioutp.ne.0) write (ioutp,6230) (g(k),k=1,n)
      dzrms = 0.0d0
      dzmax = 0.0d0
      gzrms = 0.0d0
      gzmax = 0.0d0
      do 340 i = 1 , n
         dz = del(i)
         gzrms = gzrms + gz(i)*gz(i)
         dzrms = dzrms + dz*dz
         if (dabs(gz(i)).gt.gzmax) gzmax = dabs(gz(i))
         if (dabs(dz).gt.dzmax) dzmax = dabs(dz)
 340  continue
      dzrms = dsqrt(dzrms)/n
      gzrms = dsqrt(gzrms)/n
      stol1 = stol
      stol2 = stol*0.6666666d0
      stol3 = stol*0.25d0
      stol4 = stol*0.1666666d0
      oolz1 = dzmax.lt.stol1
      oolz2 = dzrms.lt.stol2
      oolz3 = gzmax.lt.stol3
      oolz4 = gzrms.lt.stol4
      yout1 = yno
      yout2 = yno
      yout3 = yno
      yout4 = yno
      if (oolz1) yout1 = yes
      if (oolz2) yout2 = yes
      if (oolz3) yout3 = yes
      if (oolz4) yout4 = yes
      if (ioutp.ne.0) write (ioutp,6280) alamb , dzmax , stol1 , yout1 ,
     +                       dzrms , stol2 , yout2 , gzmax , stol3 ,
     +                       yout3 , gzrms , stol4 , yout4
      elow = ddot(n,del,1,gz,1)
      if (ioutp.ne.0) write (ioutp,6250) elow
      lintyp = likeep
c
c       test for z-space convergence
c
      if (dabs(elow).lt.5.0d-6) lintyp = 1
c
c    if al is +ve then search for a maximum
c    if al is -ve then take a newton raphson step but don't search
c
c
      if (.not.(oolz1 .and. oolz2 .and. oolz3 .and. oolz4)) then
         eold = en0
         ismax = 0
_IF(ccpdft)
         if (CD_active()) then
            ierror = CD_jfit_init1()
            if (ierror.ne.0) then
               write(iwr,600)ierror
               call caserr2('Out of memory')
            endif
         endif
c600     format('*** Need ',i10,' more words to store fitting ',
c    +          'coefficients and Schwarz tables in core')
_ENDIF
         call sfun4(0,n,1.0d0,f,grad,cx,g,cz,exx,gxx,ioutp,core,fkp,
     +              lines)
         call sfun4(3,n,1.0d0,f,grad,cx,g,cz,exx,gxx,ioutp,core,fkp,
     +              lines)
_IF(ccpdft)
         if (CD_active()) then
            ierror = CD_jfit_clean1()
            if (ierror.ne.0) then
               call caserr2('Memory failure in saddle:CD_jfit_clean1')
            endif
         endif
_ENDIF
         grad = 0.0d0
         call mnter(f,grad,g,n,2,jtyp,fkp,lines,iwr)
         nls = nls + 1
         if (nls.ge.mnls) go to 370
c
c       monitor the effectiveness of the current trust region
c
         deltae = f - en0
         ratio = 1.0d0
         if (dabs(elow).ge.1.0d-6 .or. dabs(deltae).ge.1.0d-6) then
            ratio = deltae/elow
            if (dabs(ratio).gt.1.0d0) ratio = 1.0d0/ratio
            if (ratio.lt.0.25d0) hk = hk*0.5d0
            if (ratio.gt.0.75d0) hk = hk*dsqrt(2.0d0)
            if (hk.gt.stepmx) hk = stepmx
            if (hk.lt.0.005d0) hk = 0.005d0
            if (ratio.le.0.0d0) then
c
c          hessian is predicting the wrong sign
c
               do 350 k = 1 , n
                  cx1(k) = cy(k)
                  gx1(k) = gama(k)
 350           continue
            end if
            write (iwr,6290) ratio , hk
         end if
         en0 = f
         ineg = 1
c             save first inverse hessian 
            call fiddle_hes(hesx,n*n,'once')
c
         call updateh(cy,cx,gama,g,hesx,cz,gx2,n,ineg,ifail,iwr)
         if (ifail.ne.0) return
         call monit(nls,hesx,n,ioutp,core)
         ineg = 1
         t2 = -1.0d20
         t1 = 1.0d20
         ireord = 1
         call diaeig(hesx,cz,n,hdiag,t2,t1,ineg,ireord,iwr)
         if (ratio.le.0.0d0) then
c
c   if ratio is -ve then the hessian is very poor
c   so ignore the step it has just made and use the
c   new trust region
c
            call dcopy(n,gx1,1,g,1)
            call dcopy(n,cx1,1,cx,1)
c
c           search for a maximum along millers direction
c
            en0 = eold
         end if
         go to 280
      end if
 360  write (iwr,6300)
      return
 370  ifail = 1
      write (iwr,6310)
      return
 6010 format (//1x,'********** search for maximum **********'/)
 6020 format (/1x,'principal direction'/8(1x,e14.7))
 6030 format (/1x,'qst-------constant terms'/8(1x,e14.7))
 6040 format (/1x,'qst-------linear terms'/8(1x,e14.7))
 6050 format (/1x,'qst-------quadratic terms'/8(1x,e14.7))
 6060 format (/1x,'qst-------cubic terms'/8(1x,e14.7))
 6070 format (/1x,'qst-------quartic terms'/8(1x,e14.7))
 6080 format (8(1x,e14.7))
 6090 format (/1x,'current x-space hessian')
 6100 format (/1x,'starting linear search for maximum:'/1x,
     +        'hessian terms: coordinate ',e14.7/1x,
     +        '               polynomial ',e14.7/1x,
     +        '               total      ',e14.7/1x,
     +        'gradient wrt to chord     ',e14.7/1x,
     +        'tangent normalisation     ',e14.7/1x,
     +        'current position on chord ',e14.7/1x,
     +        'estimated step along chord',e14.7)
 6110 format (/20x,'information on x-space minimisation'/20x,
     +        '==================================='//5x,
     +        '    maximum step',f14.8,2x,'convergence? ',f14.8,1x,
     +        a4/5x,'    average step',f14.8,2x,'convergence? ',f14.8,
     +        1x,a4/5x,'maximum gradient',f14.8,2x,'convergence? ',
     +        f14.8,1x,a4/5x,'average gradient',f14.8,2x,
     +        'convergence? ',f14.8,1x,a4)
 6120 format (/1x,'estimated energy lowering ',e20.10)
 6130 format (/1x,'old tangent to qst'/8(1x,e14.7))
 6140 format (/1x,'new tangent to qst'/8(1x,e14.7))
 6150 format (/1x,'hesmax= ',e20.10)
 6160 format (/1x,'sine of angle between tangents to qst ',e14.7,
     +        ' tolstp is ',e14.7,' do i step along tangent? ',a4)
c
c ---- step along the tangent and update
c
 6170 format (//1x,'sorry about this, but because of the large',1x,
     +        'step along the quartic the program will'/1x,
     +        'take a step tanstp*(last step length)',' along tangent',
     +        e14.7//)
 6180 format (/1x,'new conjugate directions')
 6190 format (//1x,'********** search for minimum *********'//)
 6200 format (/1x,'gradients in z-space'/8(1x,e14.7))
 6210 format (/1x,'step in z-space'/8(1x,e14.7))
 6220 format (/1x,'current position in x-space'/8(1x,e14.7))
 6230 format (/1x,'current gradients in x-space'/8(1x,e14.7))
 6240 format (//20x,'information on z-subspace minimisation'/20x,
     +        '======================================'//5x,
     +        '    maximum step',f14.8,2x,'convergence? ',f14.8,1x,
     +        a4/5x,'    average step',f14.8,2x,'convergence? ',f14.8,
     +        1x,a4/5x,'maximum gradient',f14.8,2x,'convergence? ',
     +        f14.8,1x,a4/5x,'average gradient',f14.8,2x,
     +        'convergence? ',f14.8,1x,a4)
 6250 format (/5x,'estimated lowering this step ',e20.10)
 6260 format (/1x,'test on dot product of principal directions ',e20.10)
 6270 format (//1x,'bad starting point ... didn''t lie between',1x,
     +        'minima ',f14.7)
 6280 format (//20x,'information for miller optimisation','  (lambda=',
     +        f15.7,')'/20x,'==================================='//5x,
     +        '    maximum step',f14.8,2x,'convergence?  ',f14.8,1x,
     +        a4/5x,'    average step',f14.8,2x,'convergence?  ',f14.8,
     +        1x,a4/5x,'maximum gradient',f14.8,2x,'convergence?  ',
     +        f14.8,1x,a4/5x,'average gradient',f14.8,2x,
     +        'convergence?  ',f14.8,1x,a4)
 6290 format (/1x,'energy ratio for the current step is ',f7.3/1x,
     +        'trust region for the next step is ',f14.7)
 6300 format (//40x,22('*')/40x,'optimization converged'/40x,22('*')/)
 6310 format (//1x,'too many line searches or not enough variables'//)
      end
      subroutine seta0(nc,a)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/segm)
INCLUDE(common/mapper)
INCLUDE(common/cntl1)
      common/hmat/o_hmat
      character*7 fnm
      character*5 snm
      data fnm,snm/'optim.m','seta0'/
      dimension a(*)
      nc2 = (nc*(nc+1))/2
c
c     ----- get core memory -----
c
      if(o_hmat) then
c..    read hessian (from input)
        i10 = igmem_alloc_inf(nc*nc*2,fnm,snm,'i10',IGMEM_DEBUG)
	call read_fcm(a(i10),a(i10+nc*nc),nc,'tri')
      else if(ofcm) then
        i10 = igmem_alloc_inf(nc*nc,fnm,snm,'i10',IGMEM_DEBUG)
        call fcmed3(a(i10),a,nc,0,'xyz')
        call triangle(a(i10),a(i10),nc)
      else
c..     unit hessian
        i10 = igmem_alloc_inf(nc2,fnm,snm,'i10',IGMEM_DEBUG)
        ij = i10 - 1
        call vclr(a(i10),1,nc2)
        do  i = 1 , nc
           a(ij+ikyp(i)) = 1.0d0
        end do
c
      end if
c
      call wrt3(a(i10),nc2,ibl3hs,idaf)
c
c     ----- reset core memory -----
c
      call gmem_free_inf(i10,fnm,snm,'i10')

      return
      end
_IF1()cjk      subroutine seta1(cz,c,nc,a)
      subroutine seta1(gamma,del,cc,nc,a)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/segm)
INCLUDE(common/mapper)
INCLUDE(common/seerch)
cjk      dimension cz(*),a(*)
      character*7 fnm
      character*5 snm
      data fnm,snm/'optim.m','seta1'/
      dimension gamma(*),del(*),a(*)
      nc2 = (nc*(nc+1))/2
c
c     ----- get core memory -----
c
      i10 = igmem_alloc_inf(nc2,fnm,snm,'i10',IGMEM_DEBUG)
      i20 = igmem_alloc_inf(nc,fnm,snm,'i20',IGMEM_DEBUG)

_IF1()cjk Big Bug (what happened to i10?)
      call rdedx(a(i10),nc2,ibl3hs,idaf)
cjk
      if ( iupcod .ne. 2) then 
c
c ----- bfgs update
c
       d1 = ddot(nc,del,1,gamma,1)
       if (dabs(d1).lt.1.0d-22) d1 = 1.0d0
         d2 = 0.0d0
         do 190 i = 1 , nc
            d3 = 0.0d0
            do 180 j = 1 , nc
               if ( i .ge. j ) then
                  ij = i10 + iky(i)+j-1
               else
                  ij = i10 + iky(j)+i-1
               endif
               d3 = d3 + a(ij)*gamma(j)
 180        continue
            a(i20 - 1 + i) = d3
            d2 = d2 + d3*gamma(i)
 190     continue
         d2 = 1.0d0 + d2/d1
         do 210 i = 1 , nc
            ii = i20 +i -1
            do 200 j = 1 , i
               ij = i10 + iky(i)+j-1
               jj = i20 +j -1
               ii = i20 +i -1
               a(ij) = a(ij) -
     +               (del(i)*a(jj)+a(ii)*del(j)-d2*del(i)*del(j))/d1     
 200        continue
 210     continue

      else
cjk
cjk  Original MS update
cjk
       ij = i10
       do 20 i = 1, nc
         dum = del(i)/cc
         if (dum.ne.0.0d0) then
            call daxpy(i,dum,del,1,a(ij),1)
         end if
         ij = ij + i
 20    continue
      endif

      call wrt3(a(i10),nc2,ibl3hs,idaf)
c
c     ----- reset core memory -----
c
      call gmem_free_inf(i20,fnm,snm,'i20')
      call gmem_free_inf(i10,fnm,snm,'i10')

      return
      end
      subroutine setfcm(nc,ic,g,ncall,a)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/gmempara)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/segm)
      character*7 fnm
      character*6 snm
      data fnm,snm/'optim.m','setfcm'/
      dimension g(*),a(*)
c
c     ----- get core memory -----
c
      nc2 = nc*nc

      i10 = igmem_alloc_inf(nc2,fnm,snm,'i10',IGMEM_DEBUG)

      if (ncall.gt.0) then
         call rdedx(a(i10),nc2,ibl3hs,idaf)
         if (ncall.gt.1) then
            j = (ic-1)*nc + i10
            call vsub(a(j),1,g,1,a(j),1,nc)
         else
            call dcopy(nc,g,1,a((ic-1)*nc+i10),1)
         end if
      else
         call vclr(a(i10),1,nc2)
      end if
      call wrt3(a(i10),nc2,ibl3hs,idaf)
c
c     ----- reset core memory -----
c
      call gmem_free_inf(i10,fnm,snm,'i10')
      return
      end
      subroutine sfun1(iflag,n,p,f,g,pc,gc,hes,exx,gxx,ioutp,core,
     * fkp,lines)
c
c ----- searches along a linear path defined by del and y
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/miscop/qst(14,maxvar),path(maxvar),del(maxvar)
      dimension pc(n),fkp(4,*),lines(4,*),gc(n),hes(*),core(*)
      dimension exx(200,*),gxx(200,*)
c
c ---- work out the new coordinates
c
      call vsma(del,1,p,path,1,pc,1,n)
      call calcfg(iflag,n,pc,f,gc,exx,gxx,ioutp,core,fkp,lines)
      if (iflag.eq.0) return
c
c ---- work out the gradient wrt parameter x
c
      g = ddot(n,gc,1,del,1)
      return
      end
_EXTRACT(sfun2,mips4)
      subroutine sfun2(iflag,n,p,f,g,pc,gc,hes,exx,gxx,ioutp,core,
     * fkp,lines)
c
c ----- searches along a linear path defined by del and y
c ----- search is performed in z-space, but y is in x-space
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      common/miscop/qst(14,maxvar),path(maxvar),del(maxvar)
      dimension pc(n),fkp(4,*),lines(4,*),gc(n),hes(*)
      dimension exx(200,*),gxx(200,*),core(*)
c
c ---- transfer coordinates to x-space
c
      np1 = n
      nm1 = n - 1
      do 30 i = 1 , np1
         dum = 0.0d0
         do 20 j = 1 , nm1
            ij = (j-1)*np1 + i
            dum = dum + hes(ij)*del(j)*p
 20      continue
         pc(i) = dum + path(i)
 30   continue
      call calcfg(iflag,n,pc,f,gc,exx,gxx,ioutp,core,fkp,lines)
c
      if (iflag.eq.0) return
c
c ---- now  gradients to z-space and gradient wrt x
c
      g = 0.0d0
      do 50 i = 1 , nm1
         dum = 0.0d0
         do 40 j = 1 , np1
            ij = (i-1)*np1 + j
            dum = dum + hes(ij)*gc(j)
 40      continue
         g = g + dum*del(i)
 50   continue
      return
      end
_ENDEXTRACT
      subroutine sfun3(iflag,n,p,f,g,pc,gc,hes,exx,gxx,ioutp,core,
     * fkp,lines)
c
c ----- searches along a quartic path as given in /qst/
c ----- f(x) is the function
c ----- g(x) is its gradient
c ----- xc and gc are the coordinates and gradients of the variables
c ----- z  is the z-matrix
c ----- this routine is only called when looking for a maximum
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension pc(n),fkp(4,*),lines(4,*),gc(n),hes(*),core(*)
      dimension exx(200,*),gxx(200,*)
      common/miscop/cmin1(maxvar),cmin2(maxvar),
     1     coefb(maxvar),coefc(maxvar),coefd(maxvar),coefe(maxvar)
c
c ---- work out the new coordinates
c
      do 20 k = 1 , n
         b = coefb(k)
         c = coefc(k)
         d = coefd(k)
         e = coefe(k)
         pc(k) = cmin1(k) + b*p + c*p*p + d*p*p*p + e*p*p*p*p
 20   continue
      call calcfg(iflag,n,pc,f,gc,exx,gxx,ioutp,core,fkp,lines)
      if (iflag.eq.0) f = -f
      if (iflag.eq.0) return
      do 30 k = 1 , n
         gc(k) = -gc(k)
 30   continue
c
c ---- what is the gradient along the line
c
      g = 0.0d0
      do 40 k = 1 , n
         b = coefb(k)
         c = coefc(k)*2.0d0
         d = coefd(k)*3.0d0
         e = coefe(k)*4.0d0
         g = g + gc(k)*(b+c*p+d*p*p+e*p*p*p)
 40   continue
      return
      end
_EXTRACT(sfun4,mips4)
      subroutine sfun4(iflag,n,p,f,g,pc,gc,hes,exx,gxx,ioutp,core,
     * fkp,lines)
c
c    searches along a linear path defined by del and y
c    the search is performed in z-space, although y is defined in x-spac
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/cntl1)
      common/miscop/qst(14,maxvar),path(maxvar),del(maxvar)
      dimension pc(n),fkp(4,*),lines(4,*),gc(n),hes(*)
      dimension gxx(200,*),exx(200,*),core(*)
c
c       transfer coordinates to x-space
c
      do 30 i = 1 , n
         dum = 0.0d0
         do 20 j = 1 , n
            ij = (j-1)*n + i
            dum = dum + hes(ij)*del(j)*p
 20      continue
         pc(i) = dum + path(i)
 30   continue
      call calcfg(iflag,n,pc,f,gc,exx,gxx,ioutp,core,fkp,lines)
      if (iflag.eq.0 .and. ismax.ne.0) f = -f
      if (iflag.eq.0) return
c
c       now gradients to z-space and gradient w.r.t. x
c
      g = 0.0d0
      if (ismax.ne.0) then
         do 40 i = 1 , n
            gc(i) = -gc(i)
 40      continue
      end if
      do 60 i = 1 , n
         dum = 0.0d0
         do 50 j = 1 , n
            ij = (i-1)*n + j
            dum = dum + hes(ij)*gc(j)
 50      continue
         g = g + dum*del(i)
 60   continue
      return
      end
_ENDEXTRACT
      subroutine smsl(tolg,bigg,orstrt,orset,core)
c
c     ----- set up arrays to update hessian matrix
c           by performing a one dimensional search.  -----
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/restar)
INCLUDE(common/infoa)
      common/miscop/p(maxat*3),g(maxat*3),dx(maxat*3),func,
     +              alpha,cz(maxat*3),
     +              q(maxat*3),cc,gnrm,p0(maxat*3),g0(maxat*3)
INCLUDE(common/seerch)
INCLUDE(common/timez)
INCLUDE(common/cntl1)
INCLUDE(common/runopt)
_IF(drf)
      common/nottwi/obeen,obeen2,obeen3,obeen4
INCLUDE(../drf/comdrf/drfpar)
_ENDIF
      dimension core(*)
_IF1(v)      data dzero/0.0d0/
      data two /2.0d0/
      data alphl,teps,deltp,tolc /1.0d-02,1.0d-05,1.0d-08,1.0d-02/
cjk
cjk  Keep track of the number of bisections and or linear searches
cjk
      nbisect = 0
      eps = deltp
      deltpm = -deltp
      if (.not.orstrt) then
c
c     ----- normal start -----
c
         if (.not.(orset)) then
            call dcopy(ncoord,p,1,p0,1)
            call dcopy(ncoord,g,1,g0,1)
            func0 = func
         end if
         orset = .false.
         gs0 = ddot(ncoord,g0,1,dx,1)
         alph = alpha
c
c     ----- check for large changes in the coords scale to avoid
c     any steps which may be too large. j.kendrick ici july 1981
c
_IF1(v)      dmx=0.0d0
_IF1(v)      do 1 i=1,ncoord
_IF1(v)      if( dabs(dx(i)).le.dmx) goto 1
_IF1(v)      dmx= dabs(dx(i))
_IF1(v)    1 continue
_IF1(u)      dmx=absmax(ncoord,0.0d0,dx)
_IF1(f)      call maxmgv(dx,1,dmx,loop,ncoord)
_IFN1(fuv)      i=idamax(ncoord,dx,1)
_IFN1(fuv)      dmx=dabs(dx(i))
         alph1 = 1.0d0
         if (dmx.gt.accin(3)) alph1 = accin(3)/dmx
cjk
cjk Scale the actual step rather than alpha
cjk
         do 19 k = 1, ncoord
 19      dx(k) = alph1*dx(k)
      else
c
c     ----- get restart data if necessary -----
c
         call rdrec1(nserch,npts,iupdat,icode,p0,g0,func0,gs0,alph,dx,p)
         call dcopy(ncoord,p,1,c(1,1),1)
         go to 30
      end if
 20   continue
cjk      if (alph.gt.alph1) alph = alph1
cjk      alph1 = alph + alph1
c
c     ----- search along -dx-direction. -----
c
      alphm = -alph
      call vsma(dx,1,alphm,p0,1,p,1,ncoord)
c
c     ----- save coordinates + displacement vector + daf directory -----
c
      call dcopy(ncoord,p,1,c(1,1),1)
      call wrrec1(nserch,npts,iupdat,icode,p0,g0,func0,gs0,alph,dx,p)
c
c     ----- call function evaluation -----
c
 30   call valopt(core)
_IF(drf)
cdrf
      obeen  = .false.
      obeen3 = .false.
      obeen4 = .false.
      ixwtvr = 1
      ixomga = 1
cdrf
_ENDIF
c
c  have to set fixed parts of the gradient to zero
c
      do 35 iat = 1, nat
         if(zopti(iat).eq.'no') then
            g((iat-1)*3+1)=0.0d0
            g((iat-1)*3+2)=0.0d0
            g((iat-1)*3+3)=0.0d0
         endif
 35   continue
c
c     ----- this is no longer a restart job.
c           reset *rstart* and *irest*      -----
c
      orstrt = .false.
      if (irest.ne.0 .and. tim.ge.timlim) return
      irest = 0
      if (func.lt.func0.or.lintyp.eq.1) then
         gnrm = dnrm2(ncoord,g,1)
         test = eps*gs0*alph - teps
         diff = func0 - func
         if (diff.ge.test.or.lintyp.eq.1) then
c
c     ----- successful search -----
c
_IF1(v)            bigg = dzero
_IF1(v)            do 2 i = 1,ncoord
_IF1(v)            dum =  dabs(g(i))
_IF1(v)            if (dum .gt. bigg) bigg = dum
_IF1(v) 2          continue
_IF1(u)            bigg=absmax(ncoord,0.0d0,g)
_IF1(f)            call maxmgv(g,1,bigg,loop,ncoord)
_IFN1(fuv)            i=idamax(ncoord,g,1)
_IFN1(fuv)            bigg=dabs(g(i))
            if (bigg.le.tolg) then
               icode = 3
               alpha = alph
               write (iwr,6020)
               return
            else
               alpha = alph
               call vsub(g,1,g0,1,q,1,ncoord)
cjk
               if ( iupcod .ne.2 ) then
cjk
cjk BFGS update, calculate delta and return 
cjk
                 call vsub(p,1,p0,1,cz,1,ncoord)
                 icode = 1
                 return
               else 
cjk
cjk Original Murtagh Sargent update
cjk
                 call makdx(q,cz,ncoord,core)
                 do 40 i = 1 , ncoord
                    cz(i) = -(cz(i)+alph*dx(i))
 40              continue
                 cc = ddot(ncoord,q,1,cz,1)
                 dumt = ddot(ncoord,cz,1,g0,1)/cc
                 dum2 = ddot(ncoord,cz,1,cz,1)
                 dz = tolc*dum2
                 icode = 1
                 if (dabs(cc).ge.dz .and. dumt.le.deltpm) return
                 icode = 2
                 return
               endif
            end if
         end if
      end if
c
c     ----- quadratic fit to get new step size -----
c
      nbisect = nbisect + 1
      if(nbisect .ge. lqstyp) then
        goto 60
      end if
      alphold = alph
_IF(drf)
      if (alph .lt. 0.d00) alph = -alph
      alph = gs0*alph**2/(two*(gs0*alph+func-func0))
      if (alphold .lt. 0.d00) alph = -alph
      if (abs(alph).gt.alphl) go to 20
_ELSE
      alph = gs0*alph**2/(two*(gs0*alph+func-func0))
      if (alph.gt.alphl) go to 20
_ENDIF
cjk
cjk Bisection (a bit smaller step)
cjk
      alph = 0.2d0 * alphold 
      goto 20
cjk
 60   write (iwr,6010)
      icode = 2
      orset = .true.
      alpha = alph
      call dcopy(ncoord,p0,1,p,1)
      call dcopy(ncoord,g0,1,g,1)
      func = func0
      return
 6010 format (10x,20('='),' too many steps without lower energy',
     +        20('=')/30x,
     +        ' reset -a (hessian) - matrix to unity'/
     +        ' take old coordinates and try again'/)
cjvl  6010 format (10x,20('='),' alpha too small ',20('=')/30x,
cjvl     +        ' reset -a- matrix to unity'/)
 6020 format (//40x,22('*')/40x,'optimization converged'/40x,22('*')/)
      end
      subroutine star(hes,exx,gxx,p,energ,g,n,ioutp,core,fkp,lines)
c
c ----- works out the 2nd derivative matrix numerically
c ----- switches for the variables  for which this is done
c ----- are held in intvec
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension hes(n,n),p(*),g(*),core(*),fkp(4,*),lines(4,*)
      dimension exx(200,*),gxx(200,*)
      dimension stardl(maxvar)
INCLUDE(common/csubst)
INCLUDE(common/foropt)
INCLUDE(common/iofile)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
_ENDIF
      common/miscop/qst(10,maxvar),gx1(maxvar),gx2(maxvar),cx1(maxvar),
     * cx2(maxvar)
      character*10 charwall
      data icalce,icalcf /
     1         2,     3/
      nvar = n
      do 20 k = 1 , nvar
         if (intvec(k).ne.0) go to 30
 20   continue
      return
c
c ---- energ suplied for the first point
c
 30   istep = 0
      cpul = cpulft(1)
      if (ioutp.ne.0) write (ioutp,6010) cpul ,charwall()
      e0 = energ
      do 40 i = 1 , nvar
         cx1(i) = p(i)
         gx1(i) = g(i)
         if (dabs(hes(i,i)).lt.1.0d-5) then
c
c           No user input available to direct the right cause
c           of action, so do what the code always has done
c
            stardl(i) = -dsign(g(i),hes(i,i))
c
         else
c
c           Do a Newton-Raphson type step. I.e. if the Hessian is
c           positive search in the direction opposite to the gradient,
c           if the Hessian is negative search in the direction of
c           the gradient.
c
            stardl(i) = -g(i)/hes(i,i)
c
         endif
         if (dabs(stardl(i)).gt.0.2d0) stardl(i)
     +        =dsign(0.2d0,stardl(i))
         if (dabs(stardl(i)).lt.vibsiz) stardl(i)
     +        = dsign(vibsiz,stardl(i))
 40   continue
 50   istep = istep + 1
      if (istep.gt.nvar) then
         do 70 i = 1 , nvar
            do 60 j = 1 , i
               t = hes(i,j)
               if (dabs(hes(j,i)).gt.dabs(t)) t = hes(j,i)
               hes(j,i) = t
               hes(i,j) = t
 60         continue
            p(i) = cx1(i)
            g(i) = gx1(i)
 70      continue
         energ = e0
         cpul = cpulft(1)
         if (ioutp.ne.0) write (ioutp,6020) cpul ,charwall()
         return
      else
         if ((intvec(istep).eq.icalce) .or. (intvec(istep).eq.icalcf))
     +       then
            p(istep) = p(istep) + stardl(istep)
_IF(ccpdft)
            if (CD_active()) then
               ierror = CD_jfit_init1()
               if (ierror.ne.0) then
                  write(iwr,600)ierror
                  call caserr2('Out of memory in incore coulomb fit')
               endif
            endif
 600        format('*** Need ',i10,' more words to store fitting ',
     +             'coefficients and Schwarz tables in core')
_ENDIF
            call calcfg(0,nvar,p,energ,g,exx,gxx,ioutp,core,fkp,lines)
            if (intvec(istep).eq.icalcf) then
              call calcfg(3,nvar,p,energ,g,exx,gxx,ioutp,core,fkp,lines)
            endif
_IF(ccpdft)
            if (CD_active()) then
               ierror = CD_jfit_clean1()
               if (ierror.ne.0) then
                  call caserr2(
     +                 'Memory problem detected in CD_jfit_clean1')
               endif
            endif
_ENDIF
            stardl(istep) = p(istep) - cx1(istep)
            p(istep) = cx1(istep)
            if (intvec(istep).eq.icalcf) then
               do 80 i = 1 , nvar
                  hes(i,istep) = (g(i)-gx1(i))/stardl(istep)
 80            continue
            end if
            if (intvec(istep).eq.icalce) then
               hes(istep,istep) = 2.0d0*((energ-e0)/stardl(istep)-gx1(
     +                            istep))/stardl(istep)
            end if
         end if
         go to 50
      end if
 6010 format (/1x,104('=')//
     +     ' commence numerical evaluation of 2nd derivative matrix at '
     +     ,f10.2,' seconds',a10,' wall')
 6020 format (//' numerical evaluation of 2nd derivative matrix',
     +        ' complete at ',f10.2,' seconds',a10,' wall'//)
      end
      subroutine symdr(dr,ict)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/iofile)
INCLUDE(common/infoa)
INCLUDE(common/symtry)
      common/junk/ptr(3,144)
      character*7 fnm
      character*5 snm
      data fnm,snm/'optim.m','symdr'/
      dimension dr(3,*),ict(*)
      data dzero,done /0.0d0,1.0d0/
      if (nt.eq.1) return
c
c     ----- get core memory
c
      nav = lenwrd()

      i10 = igmem_alloc_inf(nw196(6),fnm,snm,'i10',IGMEM_DEBUG)
      ioff = (i10-1)*nav
c
c     ----- read in tranformation matrices of coordinates. -----
c
      call rdedx(ptr,nw196(1),ibl196(1),idaf)
c
c     ----- read in table of atoms vs. symmetry -----
c
      call readi(ict(ioff+1),nw196(6)*nav,ibl196(6),idaf)
c
c     ----- symmetryze displacement vector -----
c
      do 90 ic = 1 , nat
         ico = ioff + ic
         do 50 it = 1 , nt
            if (ict(ico+ilisoc(it)).gt.ic) go to 90
 50      continue
         dx = dzero
         dy = dzero
         dz = dzero
         do 60 it = 1 , nt
            icnu = ict(ico+ilisoc(it))
            dxp = dr(1,icnu)
            dyp = dr(2,icnu)
            dzp = dr(3,icnu)
            n = 3*(it-1)
            dx = dx + dxp*ptr(1,n+1) + dyp*ptr(2,n+1) + dzp*ptr(3,n+1)
            dy = dy + dxp*ptr(1,n+2) + dyp*ptr(2,n+2) + dzp*ptr(3,n+2)
            dz = dz + dxp*ptr(1,n+3) + dyp*ptr(2,n+3) + dzp*ptr(3,n+3)
 60      continue
         dr(1,ic) = dx
         dr(2,ic) = dy
         dr(3,ic) = dz
         do 80 it = 1 , nt
            icnu = ict(ico+ilisoc(it))
            if (icnu.ne.ic) then
               if (it.ne.nt) then
                  it1 = it + 1
                  do 70 jt = it1 , nt
                     if (ict(ico+ilisoc(jt)).eq.icnu) go to 80
 70               continue
               end if
               jt = invt(it)
               n = 3*(jt-1)
               dxp = dx*ptr(1,n+1) + dy*ptr(2,n+1) + dz*ptr(3,n+1)
               dyp = dx*ptr(1,n+2) + dy*ptr(2,n+2) + dz*ptr(3,n+2)
               dzp = dx*ptr(1,n+3) + dy*ptr(2,n+3) + dz*ptr(3,n+3)
               dr(1,icnu) = dxp
               dr(2,icnu) = dyp
               dr(3,icnu) = dzp
            end if
 80      continue
 90   continue
      dum = done/dfloat(nt)
      do 110 n = 1 , nat
         do 100 i = 1 , 3
            dr(i,n) = dr(i,n)*dum
 100     continue
 110  continue
c
c     ----- reset core memory
c
      call gmem_free_inf(i10,fnm,snm,'i10')

      return
      end
      subroutine symfcm(a,nprint)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/infoa)
INCLUDE(common/symtry)
INCLUDE(common/foropt)
      common/miscop/p1(maxat*3),g1(maxat*3),f1,p00(maxat*3),
     +              g00(maxat*3),f00
INCLUDE(common/segm)
      common/junk/ ptr(3,144),q(3,3),v(3)
INCLUDE(common/restri)
      character*7 fnm
      character*6 snm
      data fnm,snm/'optim.m','symfcm'/
      dimension a(*)
c     data dzero,two /0.0d0,2.0d0/
      ncoord = 3*nat
c
c     ----- get core memory -----
c
      i10 = igmem_alloc_inf( (ncoord*(ncoord+1)) + ncoord*ncoord +
     &  12*ncoord  + nat*nat + nw196(6), fnm,snm,'i10',IGMEM_DEBUG )
      i20 = i10 + ncoord*ncoord
      i30 = i20 + (ncoord*(ncoord+1))/2
      i40 = i30 + (ncoord*(ncoord+1))/2
      i50 = i40 + ncoord
      i60 = i50 + ncoord
      i70 = i60 + ncoord
      i80 = i70 + 9*ncoord
c
      i90 = i80 + nat*nat
c
c     last = i90 + nw196(6)
c
c     ----- read in tranformation matrices of coordinates. -----
c
      call rdedx(ptr,nw196(1),ibl196(1),idaf)
c
      call symfcmm(a(i10),a(i80),a(i90),ncoord)
c
c     ----- convert to mass weighted coordinates and calculate
c           normal modes and vibrational frequencies -----
c
      call forend(a(i10),ncoord,nprint,ipu)
      call fgmtrx(a,a(i10),a(i20),a(i30),a(i40),a(i50),a(i60),a(i70),
     +            ncoord)
c
c     ----- reset core memory -----
c
      call gmem_free_inf(i10, fnm,snm,'i10')
      return
      end
c
      subroutine symfcmm(a,oskip,ict,ncoord)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/infoa)
INCLUDE(common/symtry)
INCLUDE(common/foropt)
      common/miscop/p1(maxat*3),g1(maxat*3),f1,p00(maxat*3),
     +              g00(maxat*3),f00
INCLUDE(common/segm)
      common/junk/ ptr(3,144),q(3,3),v(3)
INCLUDE(common/restri)
INCLUDE(common/runopt)
      dimension oskip(nat,*),ict(*),a(*)
      data dzero,two /0.0d0,2.0d0/
c
      ncoord = 3*nat
      nc2 = ncoord*ncoord
      nav = lenwrd()
c     ----- read in table- atoms versus symmetry operations.
c
      call readi(ict,nw196(6)*nav,ibl196(6),idaf)
c
c     ----- check which block of the -fcm- has been computed -----
c
      do 60 jat = 1 , nat
         do 50 iat = 1 , nat
            oskip(iat,jat) = .false.
 50      continue
 60   continue
      do 90 jat = 1 , nat
         do 70 it = 1 , nt
            if (ict(jat+ilisoc(it)).gt.jat) go to 90
 70      continue
         do 80 iat = 1 , nat
            oskip(iat,jat) = .true.
 80      continue
 90   continue
c
c     ----- symmetrize -fcm- -----
c
      call rdedx(a,nc2,ibl3hs,idaf)
      if (nvib.ne.2) then
         jj = 1
         do 100 j = 1 , ncoord
            call vsub(a(jj),1,g00,1,a(jj),1,ncoord)
            jj = jj + ncoord
 100     continue
      end if
      dum = 1.0d0/(vibsiz*nvib)
c
      call dscal(nc2,dum,a,1)
      if (nt.ne.1) then
         do 250 iat = 1 , nat
            do 240 jat = 1 , nat
               if (.not.(oskip(iat,jat))) then
                  do 230 it = 1 , nt
                     kat = ict(iat+ilisoc(it))
                     lat = ict(jat+ilisoc(it))
                     if (oskip(kat,lat)) then
                        n = 3*(it-1)
                        loci = 3*(iat-1)
                        locj = 3*(jat-1)
                        lock = 3*(kat-1)
                        locl = 3*(lat-1)
                        do 120 l = 1 , 3
                           ll = (locl+l-1)*ncoord
                           do 110 k = 1 , 3
                              kk = lock + k
                              q(k,l) = a(kk+ll)
 110                       continue
 120                    continue
                        do 160 k = 1 , 3
                           do 140 l = 1 , 3
                              dum = dzero
                              do 130 m = 1 , 3
                                 dum = dum + q(k,m)*ptr(m,n+l)
 130                          continue
                              v(l) = dum
 140                       continue
                           do 150 l = 1 , 3
                              q(k,l) = v(l)
 150                       continue
 160                    continue
                        do 200 l = 1 , 3
                           do 180 k = 1 , 3
                              dum = dzero
                              do 170 m = 1 , 3
                                 dum = dum + ptr(m,n+k)*q(m,l)
 170                          continue
                              v(k) = dum
 180                       continue
                           do 190 k = 1 , 3
                              q(k,l) = v(k)
 190                       continue
 200                    continue
                        do 220 l = 1 , 3
                           ll = (locj+l-1)*ncoord
                           do 210 k = 1 , 3
                              kk = loci + k
                              a(kk+ll) = q(k,l)
 210                       continue
 220                    continue
                        oskip(iat,jat) = .true.
                        go to 240
                     end if
 230              continue
               end if
 240        continue
c
 250     continue
      end if
c
      do 270 i = 1 , ncoord
         do 260 j = 1 , i
            ij = i + (j-1)*ncoord
            ji = j + (i-1)*ncoord
            diff = (a(ij)-a(ji))/two
            sum = (a(ij)+a(ji))/two
            a(ji) = diff
            a(ij) = sum
 260     continue
 270  continue
c
c... for frozen atoms in hessian
c
      big = 1000000.0d0
      do j=1,nat
         if (zopti(j).eq.'no') then
            do k=1,ncoord
               do jc=(j-1)*3+1,j*3
                   a(k+(jc-1)*ncoord) = 0.0d0
                   a(jc+(k-1)*ncoord) = 0.0d0
                   if (jc.eq.k) a(jc+(k-1)*ncoord) = big
               end do
            end do
         end if
      end do
c
c     ----- print and punch force constant matrix -----
c
      idim=lensec(nc2)
      call secput(isect(46),22,idim,iblk46)
      write(iwr,9000) isect(46)
9000  format(/10x,'writing hessian to dumpfile section ',i3)
      call wrt3(a,nc2,iblk46,idaf)
c
c ---- update index header block
c
      call revind
c
      call fcmout(a,ncoord,iwr)
c
      return
      end
      function symnum(oline)
c
c     provide the calling routine with the rotational symmetry number
c     of the molecule.  a table look up is done based upon the point
c     group of the molecule.  see s. w. benson, "thermochemical
c     kinetics, 2nd ed.", wiley, new york, 1976, p49.
c     in addition, the logical variable linear is set true if the
c     molecular point group is d*h or c*v.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension xpg1(19),xpg2(19),xpg(3),xnum(10)
c     dimension num(10)
INCLUDE(common/molsym)
INCLUDE(common/runlab)
      data xpg1 /'c','c','c','c','s','c','c','d','d','d','c',
     1          'd','t','t','t','o','o','i','i'/
      data xpg2 /'1','s','i','n','n','n','n','n','n','n','*',
     1          '*',' ','h','d',' ','h',' ','h'/
      data done,two,twelve,f24/1.0d0,2.0d0,12.0d0,24.0d0/
      data xnum/'0','1','2','3','4','5','6','7','8','9'/
c
c     determine the symmetry number.
c
      xpg(1) = xpg1(igrp80)
      xpg(2) = xpg2(igrp80)
      if (xpg(2).eq.xpg2(4)) xpg(2) = xnum(jaxis)
      symnum = done
      oline = xpg(2).eq.xpg2(11)
cjvl    minimum rotation number 1   (routine symnum)
      n = max(jaxis,1)
cjvl
c
c     ci, cs, cn, cnh, cnv.
c
      if (xpg(1).ne.xpg1(1)) then
c
c     dn, dnh, dnd.
c
         if (xpg(1).eq.xpg1(8)) then
            symnum = two*dfloat(n)
            if (oline) symnum = two
c
c     sn.
c
         else if (xpg(1).ne.xpg1(5)) then
c
c     t, td, o, oh.
c
            if (xpg(1).eq.xpg1(13)) symnum = twelve
            if (xpg(1).eq.xpg1(16)) symnum = f24
         else
            symnum = dfloat(n)/two
         end if
      else if (.not.(oline .or. xpg(2).eq.xpg1(19) .or. xpg(2)
     +         .eq.xpg1(5))) then
         symnum = dfloat(n)
      end if
      return
      end
      subroutine testan(cx,g,test,n,iflag,ifail,ioutp,iout)
c
c ----- checks to see if the current point has moved off the
c ----- ridge of the saddle
c       s will hold the vector xmin2-xmin1
c       tans will hold the tangent direction
c       g must contain the current gradient
c       xm is a scratch array
c       test is the normalised projection of the gradient onto tans
c       iflag is 0 if test le tolstp   otherwise 1
c       ifail is set to 1 if the cord is outside bounds
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension cx(*),g(*)
      common/miscop/cmin1(maxvar),cmin2(maxvar),
     1     coefb(maxvar),coefc(maxvar),coefd(maxvar),coefe(maxvar)
     2,s(maxvar),tans(maxvar),cxm(maxvar),princp(maxvar)
INCLUDE(common/cntl1)
      iflag = 0
      ifail = 0
      call quartc(cx,princp,g,n,cordm,ioutp,iout)
      if (cordm.ge.0.0d0 .and. cordm.le.1.0d0) then
         gtan = ddot(n,tans,1,g,1)
         tanorm = ddot(n,tans,1,tans,1)
         test = gtan*gtan/(ddot(n,g,1,g,1)*tanorm)
         if (ioutp.ne.0) write (ioutp,6010) test , tolmax
         if (test.gt.tolmax) iflag = 1
         return
      else
         write (ioutp,6020) cordm
         ifail = 1
         return
      end if
 6010 format (/1x,'test for moving off the ridge ',e14.7,1x,
     +        'tolmax is ',e14.7)
 6020 format (/1x,'** warning - chord on quadratic is outside limits',
     +        f20.10)
      end
      subroutine thermo(natoms,ia,c,multip,amass,freq,nimag,
     +                  phycon,iout)
c
c     given the structure of a molecule and its normal mode vibrational
c     frequencies this routine uses standard statistical mechanical
c     formulas for an ideal gas (in the canonical ensemble, see,
c     for example, d. a. mcquarrie, "statistical thermodynamics",
c     harper & row, new york, 1973, chapters 5, 6, and 8) to compute
c     the entropy, heat capacity, and internal energy.
c
c     the si system of units is used internally.  conversion to units
c     more familiar to most chemists is made for output.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/runopt)
      common/miscop/sp(4,maxat*3),spp,ehf,
     +       vtemp(maxat*3), evibn(20), cvibn(20), svibn(20), pmom(3),
     +       pvec(9),cmc(3)
c
c
c     amass:   atomic weights, in amu.
c     cmc :    centre of mass coordinates.
c     pmom:    principal moments of inertia, in amu-bohr**2 and
c              in ascending order.
c     freq:    vibrational frequencies, in hz and in ascending
c              order starting with the first real value.
c     vtemp:   vibrational temperatures, in kelvin.
c     evibn:   contribution to e from the vibration n.
c     cvibn:   contribution to cv from the vibration n.
c     svibn:   contribution to s from the vibration n.
c
      dimension ia(*), amass(*), freq(*), c(*), phycon(10)
c     tstd:    standard temperature, in kelvin.
c     pstd:    standard pressure, in pascals.
c
      data tstd   /298.15d0/
      data pstd   /1.01325d+05/
c
      data dzero,pt2,half,done,donpt5/0.0d0,0.2d0,0.5d0,1.0d0,1.5d0/
      data two,twopt5,four,eight,akilo/2.0d0,2.5d0,4.0d0,8.0d0,1000.0d0/
      data thresh/900.0d0/
c
      if (zfrozen.eq.'yes') return
c
c
c     tokg:    kilograms per amu.
c     boltz:   boltzman constant, in joules per kelvin.
c     planck:  planck constant, in joule-seconds.
c     avog:    avogadro constant, in mol**(-1).
c     jpcal:   joules per calorie.
c     tomet:   metres per bohr.
c     hartre:  joules per hartree.
c
      tokg = phycon(2)
      boltz = phycon(10)
      planck = phycon(4)
      avog = phycon(5)
      rjpcal = phycon(6)
      tomet = phycon(7)
      hartre = phycon(8)
c
c     compute the gas constant, pi, pi**2, and e.
c     compute the conversion factors cal per joule and kcal per joule.
c
      gas = avog*boltz
      pi = four*datan(done)
      pipi = pi*pi
      e = dexp(done)
      tocal = done/rjpcal
      tokcal = tocal/akilo
c
c     print the temperature and pressure.  code for inputing t and p
c     would be put here.  note that the units of p are pascals.
c
      t = tstd
      p = pstd
      patm = p/pstd
      write (iout,6010)
      write (iout,6030) t , patm
      rt = gas*t
c
c     compute and print the molecular mass in amu, then convert to
c     kilograms.
c
_IF1(v)      weight = dzero
_IF1(v)      do 1 iat=1,natoms
_IF1(v)   1  weight = weight + amass(iat)
_IF1(u)      weight=sumup(amass,natoms)
_IF1(f)      call sve(amass,1,weight,natoms)
_IFN1(fuv)      weight=dsum(natoms,amass,1)
      write (iout,6020) weight
      weight = weight*tokg
c
c     trap non-unit multiplicities.
c
      if (multip.ne.1) write (iout,6040)
c
c     compute contributions due to translation:
c        etran-- internal energy
c        ctran-- constant v heat capacity
c        stran-- entropy
c
      dum1 = boltz*t
      dum2 = (two*pi)**donpt5
      arg = dum1**donpt5/planck
      arg = (arg/p)*(dum1/planck)
      arg = arg*dum2*(weight/planck)
      arg = arg*dsqrt(weight)*e**twopt5
      stran = gas*dlog(arg)
      etran = donpt5*rt
      ctran = donpt5*gas
c
c     compute contributions due to electronic motion:
c        it is assumed that the first electronic excitation energy
c        is much greater than kt and that the ground state has a
c        degeneracy of one.  under these conditions the electronic
c        partition function can be considered to be unity.  the
c        ground electronic state is taken to be the zero of
c        electronic energy.
c
c
c     for monatomics print and return.
c
      if (natoms.gt.1) then
c
c     compute contributions due to rotation.
c
c
c     compute the principal moments of inertia, get the rotational
c     symmetry number, see if the molecule is linear, and compute
c     the rotational temperatures.  note the imbedded conversion
c     of the moments to si units.
c
         call mofi(natoms,c,amass,cmc,pmom,pvec)
         write (iout,6260) (pmom(i),i=1,3)
         sn = symnum(oline)
         write (iout,6060) sn
         oline = omol_is_linear(pmom)
         con = planck/(boltz*eight*pipi)
         con = (con/tokg)*(planck/(tomet*tomet))
         if (oline) then
c
            rtemp = con/pmom(3)
            if (rtemp.lt.pt2) write (iout,6070)
            write (iout,6090) rtemp
         else
            rtemp1 = con/pmom(1)
            rtemp2 = con/pmom(2)
            rtemp3 = con/pmom(3)
c
            if (rtemp1.lt.pt2) write (iout,6070)
            write (iout,6080) rtemp1 , rtemp2 , rtemp3
         end if
c
c         erot-- rotational contribution to internal energy.
c         crot-- rotational contribution to cv.
c         srot-- rotational contribution to entropy.
c
         if (oline) then
c
            erot = rt
            crot = gas
            arg = (t/rtemp)*(e/sn)
            srot = gas*dlog(arg)
         else
            erot = donpt5*rt
            crot = donpt5*gas
            arg = dsqrt(pi*e*e*e)/sn
            dum = (t/rtemp1)*(t/rtemp2)*(t/rtemp3)
            arg = arg*dsqrt(dum)
            srot = gas*dlog(arg)
         end if
c
c     compute contributions due to vibration.
c
c
c     compute vibrational temperatures and zero point vibrational
c     energy.  only real frequencies are included in the analysis.
c
         ndof = 3*natoms - 6 - nimag
         if (nimag.ne.0) write (iout,6250) nimag
         if (oline) ndof = ndof + 1
         con = planck/boltz
         ezpe = dzero
         do 20 i = 1 , ndof
            vtemp(i) = freq(i)*con
            ezpe = ezpe + freq(i)
 20      continue
         ezpe = half*planck*ezpe
         ezj = ezpe*avog
         ezkc = ezpe*tokcal*avog
         ezau = ezpe/hartre
         write (iout,6100) ezj , ezkc , ezau
c
c     compute the number of vibrations for which more than 5: of an
c     assembly of molecules would exist in vibrational excited states.
c     special printing for these modes is done to allow the user to
c     easily take internal rotations into account.  the criterion
c     corresponds roughly to a low frequency of 1.9(10**13) hz, or
c     625 cm**(-1), or a vibrational temperature of 900 k.
c
         lofreq = 0
         do 30 i = 1 , ndof
            if (vtemp(i).lt.thresh) lofreq = lofreq + 1
 30      continue
         if (lofreq.ne.0) write (iout,6110) lofreq,thresh
c
         itop = min(ndof,5)
         write (iout,6120) (vtemp(i),i=1,itop)
         if (ndof.le.5) write (iout,6130)
         itop = min(ndof,10)
         if (ndof.gt.5) write (iout,6130) (vtemp(i),i=6,itop)
         if (ndof.gt.10) write (iout,6140) (vtemp(i),i=11,ndof)
c
c     compute:
c        evib-- the vibrational component of the internal energy.
c        cvib-- the vibrational component of the heat capacity.
c        svib-- the vibrational component of the entropy.
c
         evib = dzero
         cvib = dzero
         svib = dzero
         do 40 i = 1 , ndof
c
c     compute some common factors.
c
            tovt = vtemp(i)/t
            etovt = dexp(tovt)
            em1 = etovt - done
c
c     compute contributions due to the i'th vibration.
c     for the low frequency modes these are stored.
c     for all modes they are added into the total.
c
            econt = tovt*(half+done/em1)
            ccont = etovt*(tovt/em1)**2
            scont = tovt/em1 - dlog(done-done/etovt)
            if (lofreq.ge.i) then
               evibn(i) = econt*rt
               cvibn(i) = ccont*gas
               svibn(i) = scont*gas
            end if
c
            evib = evib + econt
            cvib = cvib + ccont
            svib = svib + scont
c
c     the units are now:
c         e-- joules/mol
c         c-- joules/mol-kelvin
c         s-- joules/mol-kelvin
c
 40      continue
         evib = evib*rt
         cvib = cvib*gas
         svib = svib*gas
         etot = etran + erot + evib
         ctot = ctran + crot + cvib
         stot = stran + srot + svib
c
c     print the thermal correction to the total energy in hartree
c
         esum = etot/avog/hartre
         write (iout,6270) esum
c
         write (iout,6150)
         write (iout,6160)
         write (iout,6200) etot , ctot , stot
         write (iout,6210) etran , ctran , stran
         write (iout,6220) erot , crot , srot
         write (iout,6230) evib , cvib , svib
         write (iout,6180)
         if (lofreq.ne.0) then
            write(iout,'(a)') 
     +      ' contributions from the low frequency vibrations '
            do 50 i = 1 , lofreq
               write (iout,6240) i , evibn(i) , cvibn(i) , svibn(i)
 50         continue
         end if
c
c     convert to the following and print
c         e-- kcal/mol
c         c-- cal/mol-kelvin
c         s-- cal/mol-kelvin
c
         etran = etran*tokcal
         ctran = ctran*tocal
         stran = stran*tocal
         erot = erot*tokcal
         crot = crot*tocal
         srot = srot*tocal
         evib = evib*tokcal
         cvib = cvib*tocal
         svib = svib*tocal
         etot = etran + erot + evib
         ctot = ctran + crot + cvib
         stot = stran + srot + svib
         if (lofreq.ne.0) then
            do 60 i = 1 , lofreq
               evibn(i) = evibn(i)*tokcal
               cvibn(i) = cvibn(i)*tocal
               svibn(i) = svibn(i)*tocal
 60         continue
         end if
c
         write (iout,6150)
         write (iout,6170)
         write (iout,6200) etot , ctot , stot
         write (iout,6210) etran , ctran , stran
         write (iout,6220) erot , crot , srot
         write (iout,6230) evib , cvib , svib
         write (iout,6180)
         if (lofreq.ne.0) then
            write(iout,'(a)') 
     +      ' contributions from the low frequency vibrations '
            do 70 i = 1 , lofreq
               write (iout,6240) i , evibn(i) , cvibn(i) , svibn(i)
 70         continue
         end if
c
         write (iout,6190)
c
         return
      else
         s = stran*tocal
         e = etran*tokcal
         cv = ctran*tocal
         write (iout,6050) etran , e , stran , s , ctran , cv
         return
      end if
c
 6010 format (//1x,104('=')//40x,23('*')/40x,
     +        'thermochemical analysis'/40x,23('*')/)
 6020 format (/1x,'molecular mass (principal isotopes) ',f11.5,' amu')
 6030 format (/1x,'temperature ',f9.3,' kelvin'/1x,'pressure    ',f9.5,
     +        ' atm')
 6040 format (/1x,'warning-- assumptions made about the electronic ',
     +        'partition function'/1x,
     +        '          are not valid for multiplets|')
 6050 format (/1x,'internal energy:   ',f10.3,' joule/mol',9x,f10.3,
     +        ' kcal/mol'/1x,'entropy:           ',f10.3,' joule/k-mol',
     +        7x,f10.3,' cal/k-mol'/1x,'heat capacity cv:  ',f10.3,
     +        ' joule/k-mol',7x,f10.3,' cal/k-mol')
 6060 format (/1x,'rotational symmetry number ',f3.0)
 6070 format (/1x,'warning-- assumption of classical behavior for ',
     +        'rotation'/1x,'          may cause significant error')
 6080 format (/1x,'rotational temperatures (kelvin) ',3f12.5)
 6090 format (/1x,'rotational temperature (kelvin) ',f12.5)
 6100 format (/
     +        ' zero point vibrational energy ',f12.1,' (joules/mol)'
     +        ,/1x,30x,f12.5,' (kcal/mol)'/1x,30x,f12.7,
     +        ' (hartree/particle)')
 6110 format (//1x,'warning-- ',i3,' modes are below the threshold ',
     +        f7.3,/,11x,'explicit consideration of these',
     +        ' degrees ','of freedom as '/1x,
     +        '          vibrations may cause significant error')
 6120 format (/1x,'vibrational temperatures: ',5f9.2)
 6130 format (1x,9x,'(kelvin)',9x,5f9.2)
 6140 format (1x,26x,5f9.2)
 6150 format (//1x,72('=')/21x,'internal',5x,'constant pressure',7x,
     +        'entropy'/21x,'energy',9x,'heat capacity'/1x,72('='))
 6160 format (21x,'joules/mol',5x,'joules/mol-kelvin',3x,
     +        'joules/mol-kelvin'/1x,72('='))
 6170 format (22x,'kcal/mol',5x,'cal/mol-kelvin',4x,'cal/mol-kelvin'/1x,
     +        72('='))
 6180 format (1x,72('='))
 6190 format (/1x,104('='))
 6200 format (1x,'total',10x,3(4x,f11.3,4x))
 6210 format (1x,'translational',2x,3(4x,f11.3,4x))
 6220 format (1x,'rotational',5x,3(4x,f11.3,4x))
 6230 format (1x,'vibrational',4x,3(4x,f11.3,4x))
 6240 format (1x,'vibration',i3,3x,3(4x,f11.3,4x))
 6250 format (1x,i3,' imaginary frequencies ignored')
 6260 format (/1x,'principal moments of inertia (nucleii only) in ',
     +        'atomic units:'/1x,5x,3f12.4)
 6270 format (//1x,'thermal energy correction to total energy: ',f12.7,
     +        ' (hartree/particle)')
      end
      subroutine trnfff(maxnz,nz,ianz,iz,bl,alpha,beta,natoms,nparm,
     +                  fx,ffx,ftmp1,ftmp2,fftmp,core,idump,iout)
      implicit REAL  (a-h,o-z)
c
c     routine to transform a matrix of second derivatives over
c     cartesian coordinates to second derivatives over internal
c     coordintes.
c     this routine is to be used in conjunction with tranf.
c
c     arguments:
c
c     maxnz  ... leading dimension of z-matrix.
c     nz     ... number of rows in z-matrix.
c     ianz   ... integer atomic numbers for the z-matrix.
c     iz     ... integer connectivity information.
c     bl     ... bondlengths.
c     alpha  ... first angles.
c     beta   ... second angles.
c     nparm  ... number of z-matrix degrees of freedom.
c     fx     ... input vector containing first derivatives over
c                cartesian coordinates.
c     ffx    ... input array contaning second derivatives over
c                cartesian coordinates.
c                at end, contains second derivatives over
c                internal coordinates.
c                beware||  this means that ffx must be allocated to
c                          hold the greater of nat3tt and nparmtt.
c     ftmp1  ... scratch vector of length (3*nz).
c     ftmp2  ... scratch vector of length 3*nz
c     fftmp  ... scratch vector of length (3*nz*nparm).
c     core   ... work space.
c     idump  ... dump flag.
c
c     this routine needs the following space in core
c       1.  ib     ... integer b-matrix, length 4*nparm.
c       2.  b      ... b-matrix                 12*nparm.
c       3.  g      ... g-matrix                 nparm**2.
c       4.  xm     ... scr for formbg           5*nz
c       5.  cc     ... scr for formbg           3*natoms (use nz).
c       6.  cz     ... scr for formbg           3*nz.
c       7.  rll    ... scr for formbg           nparm
c       8.  rmm    ... scr for formbg           nparm
c
INCLUDE(common/gmempara)
      dimension ianz(*),iz(maxnz,4),bl(*),alpha(*),beta(*)
      dimension fx(*),ffx(*),ftmp1(*),ftmp2(*),fftmp(*),core(*)
      character*7 fnm
      character*6 snm
      data fnm,snm/'optim.m','trnfff'/
c     data zero/0.d0/
      data pt5,del1/.5d0,.00001d0/
c
c     statement function for linear indexing.
      lind(i,j) = (i*(i-1))/2 + j
c
c     ******************************************************************
c     initialization.
c     ******************************************************************
      nat3 = natoms*3
      nz3 = 3*nz
c
c     allocate space in core for formbg.
c
c                               ib            (4*nz3)
      i1 = igmem_alloc_inf(4*nz3,fnm,snm,'ib',IGMEM_DEBUG)
c                               b             (4*3*nz3)
      i2 = igmem_alloc_inf(3*4*nz3,fnm,snm,'b',IGMEM_DEBUG)
c                               g             (nz3*nz3)
      i3 = igmem_alloc_inf(nz3*nz3,fnm,snm,'g',IGMEM_DEBUG)
c                               cxm           (nz*6) 
      i4 = igmem_alloc_inf(6*nz,fnm,snm,'cxm',IGMEM_DEBUG)
c                               cz            (3*nz)
      i5 = igmem_alloc_inf(3*nz,fnm,snm,'cz',IGMEM_DEBUG)
c                               cc            (3*nz)
      i6 = igmem_alloc_inf(3*nz,fnm,snm,'cc',IGMEM_DEBUG)
c                               ll            (3*nz)
c     ... but allow for minv usage on the cray i.e. double ll 
c
      i7 = igmem_alloc_inf(2*nz3,fnm,snm,'ll',IGMEM_DEBUG)
c                               mm            (3*nz)
      i8 = igmem_alloc_inf(3*nz,fnm,snm,'mm',IGMEM_DEBUG)
c                               igcart        (3*nz)
      i9 = igmem_alloc_inf(3*nz,fnm,snm,'igcart',IGMEM_DEBUG)
c                               gcart    and ibuff(nz) 
      i10 = igmem_alloc_inf(3*nz,fnm,snm,'gcart',IGMEM_DEBUG)
c
      igcpy = igmem_alloc_inf(nparm*(nparm+1)/2,fnm,snm,'gcpy',
     +                        IGMEM_DEBUG)
      igvec = igmem_alloc_inf(nparm*nparm,fnm,snm,'gvec',IGMEM_DEBUG)
      igeig = igmem_alloc_inf(nparm,fnm,snm,'geig',IGMEM_DEBUG)
c
c     obtain initial ib,b,g matrix.
c
      call mkigcart(maxnz,nz,iz,core(i9),core(i10),nparmz)
c                               igcart   ibuff(nz)
c
      call formbgxz(maxnz,nz,ianz,iz,bl,alpha,beta,nparm,nparmz,
     + core(i2),core(i1),core(i3),core(i10),core(i9),
c       b         ib       g       gcart     igcart  
     + core(igcpy),core(igvec),core(igeig),
c       gcpy         gvec        geig
     + core(i4),core(i5),core(i6),core(i7),core(i8),idump,ifail)
c         cxm      cz     cc          ll      mm
c
      if (nparm.ge.1) then
         nnprm = (nparm*(nparm+1))/2
c
c     transform the input matrix.
c
c     transform first suffix, storing the result in fftmp.
         do 50 i = 1 , nat3
            do 20 j = 1 , i
               ij = lind(i,j)
               ftmp1(j) = ffx(ij)
 20         continue
            do 30 j = i , nat3
               ij = lind(j,i)
               ftmp1(j) = ffx(ij)
 30         continue
	    call tranfxz(nparm,nparmz,nz,ianz,ftmp1,ftmp2,core(i1),
c                                              fx     f    ib
     +               core(i2),core(i3),core(i10),core(i9),core(i7))
c                        b     g        gcart      igcart    ll


            do 40 j = 1 , nparm
               ij = i + nat3*(j-1)
               fftmp(ij) = ftmp2(j)
 40         continue

 50      continue
c

c     transform second suffix, storing the result back into ffx.

         call vclr(ffx,1,nnprm)

         do 80 i = 1 , nparm
            ii = nat3*(i-1)
	    call tranfxz(nparm,nparmz,nz,ianz,fftmp(ii+1),ftmp2,
c                                                 fx        f
     +        core(i1),core(i2),core(i3),core(i10),core(i9),core(i7))
c               ib      b         g       gcart    igcart    ll


            do 60 j = 1 , i
               ij = lind(i,j)
               ffx(ij) = ffx(ij) + ftmp2(j)
 60         continue
            do 70 j = i , nparm
               ij = lind(j,i)
               ffx(ij) = ffx(ij) + ftmp2(j)
 70         continue
 80      continue

         if (idump.ge.2) write (iout,6010)
         if (idump.ge.2) call ltoutd(nparm,ffx,1)
c
c     determine effect of differentiating the coordinate transformation.
c     this is done by numerically differentiating the transformation and
c     need only be done if the cartesian first derivatives are large
c     enough to matter (within the estimated accuracy of the numerical
c     differentiation.
c
         fxsq = ddot(nat3,fx,1,fx,1)
         if (fxsq.ge.(del1**4)) then
c
c     loop over the number of z-matrix degrees of freedom.
c
            iparm = 0
            lim = 3*nz - 6
c           idump1 = max(idump-1,0)
            do 120 i = 1 , lim
c     determine what to increment.
               if (i.le.(nz-1)) then
                  ipz = i + 1
                  jpz = 1
                  del = del1
               else if (i.gt.(2*nz-3)) then
                  ipz = i - 2*nz + 6
                  jpz = 3
                  del = del1
               else
                  ipz = i - nz + 3
                  jpz = 2
                  del = del1
               end if
               if (iz(ipz,1).gt.0) then
                  iparm = iparm + 1
c
c     determine step up.
                  call zmmodg(bl,alpha,beta,ipz,jpz,+del)

		  call formbgxz(maxnz,nz,ianz,iz,bl,alpha,beta,nparm,
     +                 nparmz,core(i2),core(i1),core(i3),core(i10),
c                                b       ib      g       gcart
     +                 core(i9),core(igcpy),core(igvec),core(igeig),
c                       igcart    gcpy        gvec        geig
     +                 core(i4),core(i5),core(i6),core(i7),
c                        cxm      cz       cc      ll
     +                 core(i8),idump,ifail)
c                       mm

		  call tranfxz(nparm,nparmz,nz,ianz,fx,ftmp1,core(i1),
c                                                   fx   f     ib
     +                  core(i2),core(i3),core(i10),core(i9),core(i7))
c                          b      g        gcart     igcart    ll

c
c     determine step back.
                  
		  call zmmodg(bl,alpha,beta,ipz,jpz,-del-del)
		  call formbgxz(maxnz,nz,ianz,iz,bl,alpha,beta,nparm,
     +                 nparmz,core(i2),core(i1),core(i3),core(i10),
     +                 core(i9),core(igcpy),core(igvec),core(igeig),
     +                 core(i4),core(i5),core(i6),core(i7),
     +                 core(i8),idump,ifail)
                  call tranfxz(nparm,nparmz,nz,ianz,fx,ftmp2,core(i1),
     +                 core(i2),core(i3),core(i10),core(i9),core(i7))
c
c     restore modified z-matrix element to its original state.
                  call zmmodg(bl,alpha,beta,ipz,jpz,+del)
c
c     compute derivatives.
                  do 90 j = 1 , nparm
                     ftmp1(j) = (ftmp1(j)-ftmp2(j))/(del1+del1)
 90               continue
c
c     add contributions into ffx.
                  do 100 j = 1 , iparm
                     ij = lind(iparm,j)
                     ffx(ij) = ffx(ij) - ftmp1(j)
 100              continue
                  do 110 j = iparm , nparm
                     ij = lind(j,iparm)
                     ffx(ij) = ffx(ij) - ftmp1(j)
 110              continue
               end if
 120        continue
         end if
c
         call dscal(nnprm,pt5,ffx,1)
      end if
c
c ----- reset core
c
      call gmem_free_inf(igeig,fnm,snm,'geig')
      call gmem_free_inf(igvec,fnm,snm,'gvec')
      call gmem_free_inf(igcpy,fnm,snm,'gcpy')
      call gmem_free_inf(i10,fnm,snm,'gcart')
      call gmem_free_inf(i9,fnm,snm,'igcart')
      call gmem_free_inf(i8,fnm,snm,'mm')
      call gmem_free_inf(i7,fnm,snm,'ll')
      call gmem_free_inf(i6,fnm,snm,'cc')
      call gmem_free_inf(i5,fnm,snm,'cz')
      call gmem_free_inf(i4,fnm,snm,'cxm')
      call gmem_free_inf(i3,fnm,snm,'g')
      call gmem_free_inf(i2,fnm,snm,'b')
      call gmem_free_inf(i1,fnm,snm,'ib')

      return
 6010 format (' direct internal force constants in trnfff:')
      end
      subroutine updateh(p0,p1,g0,g1,b,hes,dum,n,ineg,ifail,iout)
c
c ----- update using bfsg formula
c ----- x0 and x1 are poimts 1 and2
c ----- g0 and g1 are their gradients
c ----- b is the current inverse hessian
c ----- x is a scratch array
c ----- ineg indicates if their are any negative eigenvalues in hess
c
c ----- x0,g0,are overwritten
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
      dimension p0(n),p1(n),g0(n),g1(n),b(n,n),dum(n)
      dimension hes(n,n)
      common/junk/pp(maxvar),gp(maxvar)
INCLUDE(common/seerch)
      ifail = 0
      d1 = 0.0d0
      do 20 k = 1 , n
         p0(k) = p1(k) - p0(k)
         g0(k) = g1(k) - g0(k)
         d1 = d1 + p0(k)*g0(k)
 20   continue
      if (iupcod.ne.1) then
         if (iupcod.eq.2) go to 230
         if (iupcod.eq.3) then
c
c ----- powell update see jorgsen paper mcscf theory jcp (1982) 77 vol11
c
c
c ----- modify powell update to cope with scaling
c ----- this version of the update corresponds to
c ----- a least squares change in the metric
c
            eigmin = -1.0d20
            eigmax = +1.0d20
            inegt = -1
c
c ----- we shold have the eigen values and eignevectors
c
            ireord = 0
            call diaeig(b,hes,n,dum,eigmin,eigmax,inegt,ireord,iout)
c
c ----- transform hessian to psuedo unit metric
c
            do 40 i = 1 , n
               do 30 j = 1 , i
                  b(i,j) = 0.0d0
                  b(j,i) = 0.0d0
 30            continue
               b(i,i) = dum(i)/dabs(dum(i))
 40         continue
c
c ----- transform coordinates and gradients to metric space
c
            do 50 i = 1 , n
               dum(i) = dsqrt(dabs(dum(i)))
 50         continue
            do 70 i = 1 , n
               sumx = 0.0d0
               sumg = 0.0d0
               do 60 j = 1 , n
                  sumx = sumx + hes(j,i)*p0(j)/dum(i)
                  sumg = sumg + hes(j,i)*g0(j)*dum(i)
 60            continue
               pp(i) = sumx
               gp(i) = sumg
 70         continue
            call dcopy(n,gp,1,g0,1)
            call dcopy(n,pp,1,p0,1)
            call dcopy(n,dum,1,gp,1)
c
c ----- now update the hessian in this metric space
c
            gtg = 1.0d0/ddot(n,g0,1,g0,1)
            do 80 i = 1 , n
               dum(i) = p0(i) - ddot(n,b(1,i),1,g0,1)
 80         continue
            dtg = gtg*ddot(n,dum,1,g0,1)
            do 100 i = 1 , n
               do 90 j = 1 , n
                  b(j,i) = b(j,i)
     +                     + gtg*(dum(i)*g0(j)+dum(j)*g0(i)-dtg*g0(i)
     +                     *g0(j))
 90            continue
 100        continue
c
c ----- now transform back to real space
c
            do 120 i = 1 , n
               do 110 j = 1 , i
                  b(i,j) = b(i,j)*gp(i)*gp(j)
                  b(j,i) = b(i,j)
                  t = hes(i,j)
                  hes(i,j) = hes(j,i)
                  hes(j,i) = t
 110           continue
 120        continue
            do 150 i = 1 , n
               do 130 j = 1 , n
                  pp(j) = ddot(n,b(1,j),1,hes(1,i),1)
 130           continue
               do 140 l = i , n
                  hes(l,i) = ddot(n,pp,1,hes(1,l),1)
 140           continue
 150        continue
c
c ----- move hessian back into b and symmetrise
c
            do 170 i = 1 , n
               do 160 j = i , n
                  b(j,i) = hes(j,i)
                  b(i,j) = hes(j,i)
 160           continue
 170        continue
            return
         else if (ineg.ge.1) then
            go to 230
         end if
      end if
c
c ----- bfsg update
c
      if (dabs(d1).gt.1.0d-22) then
         d2 = 0.0d0
         do 190 i = 1 , n
            d3 = 0.0d0
            do 180 j = 1 , n
               d3 = d3 + b(i,j)*g0(j)
 180        continue
            dum(i) = d3
            d2 = d2 + d3*g0(i)
 190     continue
         d2 = 1.0d0 + d2/d1
         do 210 i = 1 , n
            do 200 j = 1 , n
               b(i,j) = b(i,j)
     +                  - (p0(i)*dum(j)+dum(i)*p0(j)-d2*p0(i)*p0(j))/d1
 200        continue
 210     continue
         return
      end if
 220  write (iout,6010) d1
      return
c
c ----- murtagh and sargent rank one update for negative d eigenvalues
c
 230  do 240 i = 1 , n
         p0(i) = p0(i) - ddot(n,b(1,i),1,g0,1)
 240  continue
      ck = ddot(n,p0,1,g0,1)
      if (dabs(ck).lt.1.0d-22) go to 220
      ck = 1.0d0/ck
      do 250 i = 1 , n
         sum = ck*p0(i)
         call daxpy(n,sum,p0,1,b(1,i),1)
 250  continue
      return
 6010 format (/1x,'**** problem in update denominator ****',e20.10)
      end
      subroutine valfor (core)
c
c     calculate energy + gradient with respect to
c     nuclear coordinates.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/tran)
INCLUDE(common/machin)
INCLUDE(common/iofile)
INCLUDE(common/dump3)
INCLUDE(common/restar)
      common/restrl/ociopt,ocifor,omp2,ogr(12),
     +omcscf,oforce,oci,ocart(32)
INCLUDE(common/cndx41)
      common/scfblk/enuc,etotal,ehfock,sh1(17),osh1(7),ish1(6)
INCLUDE(common/atmol3)
INCLUDE(common/restrj)
INCLUDE(common/restri)
INCLUDE(common/segm)
      common/maxlen/maxq
INCLUDE(common/cigrad)
INCLUDE(common/prints)
INCLUDE(common/mapper)
INCLUDE(common/timez)
INCLUDE(common/funct)
INCLUDE(common/infoa)
INCLUDE(common/infob)
      common/miscop/p(maxat*3),g(maxat*3),ff,p0(maxat*3),
     +             g0(maxat*3),f0
INCLUDE(common/vibrtn)
INCLUDE(common/runlab)
INCLUDE(common/symtry)
INCLUDE(common/scfwfn)
INCLUDE(common/cslosc)
INCLUDE(common/datgue)
INCLUDE(common/nshel)
INCLUDE(common/fccwfn)
c
      common/blkcore/corev(512),array(10)
      character*10 charwall
      dimension core(*),zcas(3),o1e(6)
      character*7 fnm
      character*6 snm
      data fnm,snm/'optim.m','valfor'/
      data tolg /1.0d-08/
      data dzero /0.0d0/
      data ono/.false./
c     data oyes/.true./
      data zuhf,zcas/'uhf','casscf','mcscf','vb'/
c     data zgrhf,zgvb/'grhf','gvb'/
      data m1,m10,m13,m16/1,10,13,16/
      data m24/24/
c
      inull = igmem_null()
      call preharm
      nav = lenwrd()
      l3 = num*num
      len3 = lensec(l3)
      len9 = lensec(mach(9))
      cpu = cpulft(1)
      write (iwr,6050)
      write (iwr,6060) cpu ,charwall()
      write (iwr,6070) iatom , icoord , ivib
      call prgeom(c,czanr,zaname,nat,iwr)
c
c     ----- special print option if iatom.gt.0
c
      if (.not.oprint(43) .and. iatom.gt.0) nprint = -5
      if (nprint.ne.-5) write (iwr,6050)
      call intr(core)
c
c     ----- calculate energy -----
c
      if (.not.(.not.orege .or. zscftp.ne.zcas(1))) then
         irest = 0
      end if
      if (.not.otran .and. ivib.gt.0) then
c
c ----- adaption . compute storage requirements
c

         i20 = 0
         i21 = i20 + mxgaus
         i22 = i21 + mxgaus
         i23 = i22 + mxprms*num
         i24 = i23 + mxprms*num
         i25 = i24 + (7*maxat+1)/nav
         i26 = i25 + (3*num+1)/nav
         i27 = i26 + (3*num+1)/nav
         i28 = i27 + (3*num+1)/nav
         i29 = i28 + (8*num+1)/nav
         i31 = i29 + (8*num+1)/nav
         max2 = i31 + (num+1)/nav
         last = max2
         length = last - i20

         i20 = igmem_alloc_inf(length,fnm,snm,'i20',IGMEM_DEBUG)
         i21 = i20 + mxgaus
         i22 = i21 + mxgaus
         i23 = i22 + mxprms*num
         i24 = i23 + mxprms*num
         i25 = i24 + (7*maxat+1)/nav
         i26 = i25 + (3*num+1)/nav
         i27 = i26 + (3*num+1)/nav
         i28 = i27 + (3*num+1)/nav
         i29 = i28 + (8*num+1)/nav
         i31 = i29 + (8*num+1)/nav
         max2 = i31 + (num+1)/nav
         last = max2
         length = last - i20

         call adapt(core(i20),core(i21),core(i22),core(i23),core(i24),
     +              core(i25),core(i26),core(i27),core(i28),core(i29),
     +              core(i31),num)

         call gmem_free_inf(i20,fnm,snm,'i20')

      end if
c
c     ----- reset symmetry to c1 if this is a casscf run
c           or a gvb run with npair .ne. 0 ,or user requested
c
      ntsave = nt
      if (npair.ne.0 .or. zscftp.eq.zcas(1) .or. zscftp.eq.zcas(2) .or.
     +     zscftp.eq.zcas(3) .or. offsym) then
       nt = 1
       iofsym = 1
      endif
      enrgy = dzero
      timscf = 0.0d0
c
      if (.not.(opass1)) then
c
c     ----- 1e- integrals -----
c
         if (irest.lt.1) then
            call standv(0,core)
            call putstv(core)
            if (.not.otran .and. ivib.gt.0) then

               itemp = igmem_alloc_inf(l3,fnm,snm,'itemp',IGMEM_NORMAL)

               o1e(1) = .true.
               do loop =2,6
                o1e(loop) = .false.
               enddo
               call getmat(core(itemp),core(itemp),core(itemp),
     +                     core(itemp),core(itemp),core(itemp),
     +                     array,num,o1e,ionsec)

               call anorm(core(itemp),core)
c      transfer vectors to sabf
               call secget(isect(498),m24,iblkc)
               iblkv = iblkc + len9 + len3
c
c     ----- read zeroth point mo's from section 498 of dumpfile  ---
c
               call rdedx(core(itemp),l3,iblkv,idaf)
               call tback(core(itemp),ilifq,core(itemp),ilifq,num)
c
c === now update /ctrans/ info on vectors section
c
               iblkc = ibl3qa - len9
               call wrt3i(ilifc(1),mach(9)*nav,iblkc,idaf)
               call wrt3(core(itemp),l3,ibl3qa,idaf)
               if (zscftp.eq.zuhf) then
                  iblkv = iblkv + len3 + len3
                  call rdedx(core(itemp),l3,iblkv,idaf)
                  call tback(core(itemp),ilifq,core(itemp),ilifq,num)
                  iblkc = ibl3qb - len9
                  call wrt3i(ilifc(1),mach(9)*nav,iblkc,idaf)
                  call wrt3(core(itemp),l3,ibl3qb,idaf)
               end if

               call gmem_free_inf(itemp,fnm,snm,'itemp')
            end if
         end if
         if (tim.ge.timlim) go to 30
      end if
      ionsv = 1
c
c     ----- 2e-integrals -----
c
      if (omp2 .or. mp3 .or. oci .or. omcscf) nopk = 1
      if (.not.(opass2 .or. odscf)) then
c        open = zscftp.eq.zuhf .or. zscftp.eq.zgvb .or.
c    +          zscftp.eq.zgrhf .or. na.ne.nb
c        opandk = nopk.ne.1 .and. open
         if (irest.le.1) then
            iprefa = igmem_alloc_inf(nshell*(nshell+1)/2,fnm,snm,
     +                               "prefac",IGMEM_DEBUG)
            call rdmake(core(iprefa))
            call jandk(zscftp,core,core(inull),core(inull),core(inull),
     +                 core(inull),core(inull),core(iprefa),core(inull))
            call gmem_free_inf(iprefa,fnm,snm,"prefac")
         endif
         if (tim.ge.timlim) go to 30
      else
       if (opass2) then
          call checkinteg(nopk,nopkr,iofsym,iofrst)
      end if
      end if
c
c     ----- symmetry adaption
c
      if (zscftp.eq.zcas(1) .or. zscftp.eq.zcas(2)) then
         if (opass4) then
            if (zscftp.eq.zcas(1) .or. zscftp.eq.zcas(2)) nt = ntsave
         else
            if (irest.le.2) call adapti(core,ono)
            if (tim.ge.timlim) go to 30
c
            if (zscftp.eq.zcas(1) .or. zscftp.eq.zcas(2)) nt = ntsave
         end if
      end if
c
      if (oalway) then
c...     generate new mo's for each point
         call mogues(core)
      end if
c
c
c     ----- scf -----
c
      if (irest.le.4) then
         t1 = cpulft(1)
         call hfscf(core)

         call putdev(core,mouta,7,1)
         if (zscftp.eq.zuhf) call putdev(core,moutb,10,2)
c
         call secget(isect(494),m16,iblk16)
         call rdedx(array,m10,iblk16,idaf)
         enuc = array(1)
         ehfock = array(2)
         etotal = array(3)
c
         call secget(isect(13),m13,iblok)
         call wrt3(enuc,lds(isect(13)),iblok,idaf)
         timscf  = cpulft(1) - t1
      endif
      opass1 = ono
      opass2 = ono
      opass3 = ono
      opass4 = ono
 30   nt = ntsave
c
      orege = .false.
      ff = enrgy
      if (irest.gt.4) then
         call secget(isect(494),m16,iblk16)
         call rdedx(array,m10,iblk16,idaf)
         enuc = array(1)
         ehfock = array(2)
         enrgy = array(3)
         ff = enrgy
         go to 50
      else
         if (irest.le.0) go to 50
         if (irest.eq.1) write (iwr,6010)
         if (irest.gt.1) write (iwr,6020)
      end if
 40   cpu = cpulft(1)
      write (iwr,6030) cpu ,charwall()
      tim = timlim + 0.5d0
      go to 70
 50   continue
_IF(mp2_parallel)
      if (omp2 .or. mp3) then
         if (irest .eq. 0) mprest = 0
         call emp23(core,enrgy)
         irest = 0
_ELSE
      if (omp2 .or. mp3) then
         mprest = max(1,mprest)
         call revise
         if (cpulft(0).lt.timscf) go to 40
c
         ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',IGMEM_DEBUG)
         mmaxq = maxq
         maxq = mword
c
         call mptran(core(ibase))
         if (.not.omp2) then
            call gmem_free_inf(ibase,fnm,snm,'ibase')
            call uhfmp3(core,core)
            ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',
     +                                  IGMEM_DEBUG)
         else if (zscftp.ne.'rhf') then
            call gmem_free_inf(ibase,fnm,snm,'ibase')
            call uhfmp2(core,core)
            ibase = igmem_alloc_all_inf(mword,fnm,snm,'ibase',
     +                                  IGMEM_DEBUG)
         else
            call mp2eng(core(ibase),ncore,nvr)
         end if
         array(1) = enuc
         array(2) = ehfock
         array(3) = etotal
         array(4) = 0.0d0
         array(5) = 0.0d0
         call secput(isect(494),m16,m1,iblk16)
         call wrt3(array,m10,iblk16,idaf)
         mprest = 3
c
c ====  this restart needs attention ====
c
         irest = 0
         enrgy = etotal
c
c     ----- reset core allocation
c
         call gmem_free_inf(ibase,fnm,snm,'ibase')
         maxq = mmaxq
_ENDIF
      end if
_IF(masscf)
      if (omas) then
       call masscf(core,enrgy)
      endif
_ENDIF
c
c    read energy from dumpfile
c
      call secget(isect(13),m13,isec13)
      call rdedx(enuc,lds(isect(13)),isec13,idaf)
      enrgy = etotal
      call revise
c
c     ----- calculate gradient -----
c
      call vclr(egrad,1,nxyz)
      if (omp2 .or. mp3) then
         call grmp23(core,egrad)
      else
         call hfgrad(zscftp,core)
      end if
      do 60 i = 1 , nxyz
         if (dabs(egrad(i)).lt.tolg) egrad(i) = 0.0d0
 60   continue
      call dcopy(nxyz,c(1,1),1,p,1)
      call dcopy(nxyz,egrad,1,g,1)
      if (irest.gt.0) then
         write (iwr,6040)
         go to 40
      end if
c
 70   if (ivib.le.0) then
c
c     ----- write zeroth point mo's in section 498 of dumpfile  ---
c     ----- together with /ctrans/information
c
         call secget(isect(498),m24,iblkc)
         iblkv0 = iblkc + len9
         call wrt3i(ilifc,mach(9)*nav,iblkc,idaf)

         itemp = igmem_alloc_inf(l3,fnm,snm,'itemp2',IGMEM_NORMAL)

         call rdedx(core(itemp),l3,ibl3qa,idaf)
         call wrt3(core(itemp),l3,iblkv0,idaf)
         call tdown(core(itemp),ilifq,core(itemp),ilifq,num)
         call wrt3s(core(itemp),l3,idaf)
         if (zscftp.eq.zuhf) then
            iblkv1 = iblkv0 + len3 + len3
            call rdedx(core(itemp),l3,ibl3qb,idaf)
            call wrt3(core(itemp),l3,iblkv1,idaf)
            call tdown(core(itemp),ilifq,core(itemp),ilifq,num)
            call wrt3s(core(itemp),l3,idaf)
         end if

         call gmem_free_inf(itemp,fnm,snm,'itemp2')
      end if

      return
 6010 format (//1x,'force constant evaluation',
     +        ' terminating due to incomplete 2e integrals')
 6020 format (//1x,'force constant evaluation',
     +        ' terminating due to incomplete scf')
 6030 format (//1x,'end of force constant evaluation at ',f10.2,
     +        ' seconds',a10,' wall')
 6040 format (//1x,
     +        'force constant evaluation terminating due to incomplete '
     +        ,'gradients')
c
 6050 format (/1x,104('='))
 6060 format (//' commence scf/gradient treatment at ',f10.2,
     +        ' seconds',a10,' wall'//)
 6070 format (//'    atom',i3/40x,19('=')/'   coord',i3,29x,
     +        'nuclear coordinates'/40x,19('=')/'     vib',i3/)
      end
      subroutine valopt(core)
c
c     ----- calculate energy + gradient with respect to
c          nuclear coordinates.
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/iofile)
      common/restrl/ociopt,ocifor,omp2
INCLUDE(common/cndx41)
INCLUDE(common/restar)
INCLUDE(common/restri)
INCLUDE(common/restrj)
INCLUDE(common/prints)
INCLUDE(common/runlab)
INCLUDE(common/timez)
INCLUDE(common/funct)
INCLUDE(common/infoa)
INCLUDE(common/infob)
INCLUDE(common/datgue)
      common/miscop/p(maxat*3),g(maxat*3),dx(maxat*3),func,alpha,
     +             cz(maxat*3),q(maxat*3),cc,gnrm
INCLUDE(common/seerch)
INCLUDE(common/cntl1)
INCLUDE(common/phycon)
INCLUDE(common/drfopt)
_IF(ccpdft)
INCLUDE(common/ccpdft.hf77)
_ENDIF
_IF(charmm)
INCLUDE(common/chmgms)
_ENDIF
_IF(drf)
cdrf
INCLUDE(../drf/comdrf/sizesrf)
INCLUDE(../drf/comdrf/drfpar)
INCLUDE(../drf/comdrf/drfbem)
INCLUDE(../drf/comdrf/rfene)
INCLUDE(../drf/comdrf/runpar)
      logical odrf
cdrf
_ENDIF
INCLUDE(common/fccwfn)
c
      dimension array(10),core(*),zcas(2)
      character*10 charwall
      data tolg /1.0d-08/
      data zcas/'casscf','mcscf'/
      data m10,m16/10,16/
_IF(drf)
c
      odrf = field .ne. ' '
c
_ENDIF
      npts = npts + 1
      cpu = cpulft(1)
      write (iwr,6050)
      write (iwr,6040) cpu ,charwall()
      write (iwr,6060) nserch , npts
_IF(charmm)
      if(.not. onoatpr)then
_ENDIF
      call prgeom(c,czanr,zaname,nat,iwr)
_IF(charmm)
      endif
_ENDIF
c
c formatted file for graphics
c
      call blkupd(c)
c
c     ----- special print option if npts.gt.0 -----
c
      if (.not.oprint(43) .and. npts.gt.0) nprint = -5
      if (icode.eq.4) nprint = -5
      if (nprint.ne.-5) write (iwr,6050)
      if (icode.ne.4)  call intr(core)
      if (.not.(.not.orege .or. zscftp.ne.zcas(1))) then
         irest = 0
      end if
      call putzm(1,iseczz)
c
      if (oalway) then
c...     generate new mo's for each point
         call mogues(core)
      end if
c
c     ----- calculate energy -----
c
      if (omp2 .or. mp3) then
         if (irest .eq. 0) mprest = 0
         call emp23(core,enrgy)
      else if(omas) then
         call masscf(core,enrgy)
      else
_IF(ccpdft)
         if (CD_active()) then
            ierror = CD_jfit_init1()
            if (ierror.ne.0) then
               write(iwr,600)ierror
               call caserr2('memory error in incore coulomb fit')
            endif
         endif
 600     format('*** Need ',i10,' more words to store fitting ',
     +          'coefficients and Schwarz tables in core')
_ENDIF
         call hfscf(core)
      end if

_IF(drf)
cahv
      if (odrf) then
cdrf-----------------------------------------------------
        ist=iactst
c
c      -----  analyse rf contributions
c
        ieps = 0
        call arfanal(ieps,unucrep,
     1 eoneel(ist),ekin(ist),enua(ist),etwoel(ist),
     1 uqm(ist),uscf(ist),snucnuc(ist),selel(ist),snua(ist),stwoel(ist),
     2 smolnuc(ist),smolel(ist),snucmol(ist),selmol(ist),smolmol(ist),
     3 suqm(ist),upolqm(ist),uneqnuc(ist),uneqel(ist),uneqqm(ist),
     4 ustanuc(ist),ustael(ist),ustaqm(ist),uclase,uclasd,uclasr,uclas,
     5 suclas,upolcl,uneqcl,ustacl,extnuc(ist),extel(ist),sextnuc(ist),
     6 sextel(ist),sextmol(ist),selext(ist),snucext(ist),smolext(ist),
     7 stotnuc(ist),stotel(ist),stotmol(ist),stotext(ist),stabtot(ist),
     8 uelst(ist),suint(ist),uint(ist),udisp(ist),rdisp(ist),
     9 repmod(ist),upoleq(ist),ucstst(ist),ucstpl(ist),uneq(ist),
     1 usta(ist),upolneq(ist),ustaneq(ist),uens(ist),uclasg,uclaseg,
     2 uclasdg,uclasrg,suclasg,upolclg,uneqclg,ustaclg,extnucg(1,ist),
     3 extelg(1,ist),sxtnucg(1,ist),sextelg(1,ist),sxtmolg(1,ist),
     4 selextg(1,ist),snucxtg(1,ist),smolxtg(1,ist),stotxtg(1,ist),
     5 uelstg(1,ist),suintg(1,ist),uintg(1,ist),repmodg(1,ist),core)
c
        if (itwoeps .eq. 1) then
          ieps = 1
        call arfanal(ieps,unucrepo,
     1 eoneelo(ist),ekino(ist),enuao(ist),etwoelo(ist),
     1 uqm(ist),uscfo(ist),snucno(ist),selel(ist),snuao(ist),
     1 stwoelo(ist),
     2 smolno(ist),smolelo(ist),snucmo(ist),selmolo(ist),smolmo(ist),
     3 suqmo(ist),upolqmo(ist),uneqno(ist),uneqelo(ist),uneqqmo(ist),
     4 ustano(ist),ustaelo(ist),ustaqmo(ist),uclaseo,uclasdo,
     4 uclasro,uclaso,
     5 suclaso,upolclo,uneqclo,ustaclo,extnuco(ist),extelo(ist),
     5 sextno(ist),
     6 sextelo(ist),sextmo(ist),selexto(ist),snucexo(ist),smolexo(ist),
     7 stotno(ist),stotelo(ist),stotmo(ist),stotexo(ist),stabto(ist),
     8 uelsto(ist),suinto(ist),uinto(ist),udisp(ist),rdispo(ist),
     9 repmo(ist),upoleqo(ist),ucststo(ist),ucstplo(ist),uneqo(ist),
     1 ustao(ist),upolno(ist),ustano(ist),uens(ist),uclasgo,uclasego,
     2 uclasdgo,uclasrgo,suclsog,uplclog,uneqclgo,ustaclgo,
     2 extnucgo(1,ist),
     3 extelgo(1,ist),sextnog(1,ist),sxtelog(1,ist),sextmog(1,ist),
     4 selxtog(1,ist),sncexog(1,ist),smlexog(1,ist),sttexog(1,ist),
     5 uelstgo(1,ist),suintog(1,ist),uintgo(1,ist),repmodgo(1,ist),
     5 core)
c
        endif
c
        call drfout
      endif
cahv
c
      if (field .ne. ' ') then
      func = uens(iactst)
      else
      func = enrgy
      endif
_ELSE
      func = enrgy
_ENDIF
      orege = .false.
      if (irest.gt.4) then
         call secget(isect(494),m16,iblk16)
         call rdedx(array,m10,iblk16,idaf)
c        en = array(1)
c        ehf = array(2)
         enrgy = array(3)
_IF(drf)
         if (field .ne. ' ') then
            func = uens(iactst)
         else
            func = enrgy
         endif
_ELSE
         func = enrgy
_ENDIF
         go to 40
      else
         if (irest.le.0) go to 40
         if (irest.eq.1) write (iwr,6010)
         if (irest.gt.1) write (iwr,6020)
      end if
 30   cpu = cpulft(1)
      write (iwr,6030) cpu ,charwall()
      tim = timlim + 0.5d0
_IF(ccpdft)
      if (CD_active()) then
         ierror = CD_jfit_clean1()
         if (ierror.ne.0) then
            call caserr2('clean error in incore coulomb fit')
         endif
      endif
_ENDIF
      return
c
c ignore +ve energies in charmm case
c
_IF(charmm)
 40   continue
_ELSE
 40   if (func.ge.func0.and.lintyp.eq.0) then
      write(iwr,*)'func rises, return without gradient!!'
_IF(ccpdft)
         if (CD_active()) then
            ierror = CD_jfit_clean1()
            if (ierror.ne.0) then
               call caserr2('clean error in incore coulomb fit')
            endif
         endif
_ENDIF
         return
      endif
_ENDIF

c
c     ----- calculate gradient -----
c
      call vclr(egrad,1,ncoord)
      if (omp2 .or. mp3) then
         call grmp23(core,egrad)
      else
         call hfgrad(zscftp,core)
_IF(ccpdft)
         if (CD_active()) then
            ierror = CD_jfit_clean1()
            if (ierror.ne.0) then
               call caserr2('clean error in incore coulomb fit')
            endif
         endif
_ENDIF
      end if
      do 50 i = 1 , ncoord
         if (dabs(egrad(i)).lt.tolg) egrad(i) = 0.0d0
         g(i) = egrad(i)
 50   continue
      call dcopy(ncoord,c(1,1),1,p,1)
      if (irest.le.0) return
      write (iwr,6080)
      go to 30
 6010 format (//1x,
     +        'optimisation terminating due to incomplete 2e integrals')
 6020 format (//1x,'optimisation terminating due to incomplete scf')
 6030 format (/' end of optimisation at ',f10.2,' seconds',a10,' wall')
 6040 format (/' commence scf/gradient treatment at ',f10.2,' seconds',
     +           a10,' wall'/)
 6050 format (//1x,104('='))
 6060 format (' search',i3/40x,19('*')/' point ',i3,30x,
     +        'nuclear coordinates'/40x,19('*')/)
c6075 format (2x,60('='))
 6080 format (//1x,
     +        'optimisation terminating due to incomplete gradients')
      end
      subroutine vibfrq(natoms,multip,ia,c,nat3,ffx,
     $                  atmass,arthog,vv,vecout,trialv,e2,eig,
     $                  phycon,iwr)
c
c***********************************************************************
c     routine to perform a frequency analysis, given the cartesian
c     second derivatives.
c
c     arguments:
c
c     natoms ... number of atoms.
c     ia     ... mapping vector for a lower triangle
c     c      ... coordinate array, stored (x,y,z) for each atom.
c     nat3   ... set to 3*natoms in the calling program, needed
c                here for dimensioning.
c     ffx    ... second derivative matrix (lower triangular).
c     atmass ... scratch vector of length natoms.
c     orthog ... scratch matrix of size (nat3*nat3).
c     vv     ... scratch vector of size (nat3*nat3).
c     vecout ... scratch vector of size (nat3*nat3).
c     trialv ... scratch vector of size (nat3).
c     e2     ... scratch vector of size (3*nat3).
c     eig    ... scratch vector of length (nat3).
c     phycon ... system vector of physical constants
c***********************************************************************
c
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
c
      dimension ia(*),c(*),ffx(*),phycon(9)
      dimension atmass(*),arthog(nat3,nat3),vv(9),vecout(*),
     $          trialv(*),e2(*),eig(*)
      dimension cmcoor(3),secmom(3,3),scmom(6)
      dimension pmom(3)
c
INCLUDE(common/sizes)
INCLUDE(common/mapper)
c
      data done,four/1.0d0,4.0d0/
      data ten5,ten18 /1.d05,1.d18/
      data cutoff/1.d-12/
c
c     avog:    avogadro constant, in mol**-1
c     slight:  speed of light, in cm/sec
c     hartre:  joules per hartree
c     toang:   bohrs per angstrom
c
      avog = phycon(5)
      slight = phycon(9)
      hartre = phycon(8)
      toang = phycon(1)
c
c     factor:  converts frequencies to wavenumbers.
c     conver:  converts force constants in atomic units to
c              mdyn/angstrom**2
c
      pi = dacos(-done) ! four*datan(done)
      factor = (ten5/(four*pi*pi))*(avog/slight/slight)
      conver = (ten18*hartre)/(toang*toang)
      oline = .false.
c
c     change units of second derivatives to mdyn/ang
c
      nat3tt = (nat3*(nat3+1))/2
c
c     convert to mass weighted force constants.
c     also calculate centre-of-mass coordinates and
c     find second mass moments.
c
      call dscal(nat3tt,conver,ffx,1)
      totmas = 0.0d0
      do 50 i = 1 , nat3
         do 40 j = 1 , nat3
            arthog(i,j) = 0.0d0
 40      continue
 50   continue
c
      do 60 i = 1 , natoms
         k = (i-1)*3 + 1
         atmass(i) = 1.0d0/(atmass(k)*atmass(k))
 60   continue
      ind = 0
      do 80 i = 1 , nat3
         iatom = (i-1)/3 + 1
         iaind = 3*(iatom-1)
         amassi = atmass(iatom)
         icoor = i - 3*((i-1)/3)
         do 70 j = 1 , i
            jatom = (j-1)/3 + 1
            jaind = 3*(jatom-1)
            amassj = atmass(jatom)
            jcoor = j - 3*((j-1)/3)
            ind = ia(i) + j
            amasst = amassi*amassj
            ffx(ind) = ffx(ind)/dsqrt(amasst)
 70      continue
 80   continue
c
c     find principal moments of inertia
c
      call mofi(natoms,c,atmass,cmcoor,pmom,vv)
      write (iwr,6010)
      write (iwr,6020) (pmom(i),i=1,3)
      oline = omol_is_linear(pmom)
c
c     set up coordinate vectors for translation and rotation about
c     principal axes of inertia.  these vectors will be orthogonal.
c
      ntrro = 6
      if (oline) ntrro = 5
      do 140 i = 1 , natoms
         iaind = 3*(i-1)
         amassi = atmass(i)
         sqrtmi = dsqrt(amassi)
         cx = c(1+iaind) - cmcoor(1)
         cy = c(2+iaind) - cmcoor(2)
         cz = c(3+iaind) - cmcoor(3)
         cxp = cx*vv(1) + cy*vv(2) + cz*vv(3)
         cyp = cx*vv(4) + cy*vv(5) + cz*vv(6)
         czp = cx*vv(7) + cy*vv(8) + cz*vv(9)
         k = 3*(i-1)
         arthog(k+1,1) = sqrtmi
         arthog(k+2,2) = sqrtmi
         arthog(k+3,3) = sqrtmi
         arthog(k+1,4) = (cyp*vv(7)-czp*vv(4))*sqrtmi
         arthog(k+2,4) = (cyp*vv(8)-czp*vv(5))*sqrtmi
         arthog(k+3,4) = (cyp*vv(9)-czp*vv(6))*sqrtmi
         arthog(k+1,5) = (czp*vv(1)-cxp*vv(7))*sqrtmi
         arthog(k+2,5) = (czp*vv(2)-cxp*vv(8))*sqrtmi
         arthog(k+3,5) = (czp*vv(3)-cxp*vv(9))*sqrtmi
         arthog(k+1,6) = (cxp*vv(4)-cyp*vv(1))*sqrtmi
         arthog(k+2,6) = (cxp*vv(5)-cyp*vv(2))*sqrtmi
         arthog(k+3,6) = (cxp*vv(6)-cyp*vv(3))*sqrtmi
 140  continue
c
c     If the molecule is linear we need to remove the rotation around
c     the axis of the molecule. This is done by selecting the rotation
c     vector with the smallest norm and removing that one.
c     This approach works independent of the orientation of the molecule
c     and does not require an additional cutoff. The introduction of an
c     additional cutoff is undesirable because it might conflict with
c     the tolerance for the detection of the molecule being linear.
c
      if (oline) then
         dumr = ddot(nat3,arthog(1,4),1,arthog(1,4),1)
         idum = 4
         do i = 5, 6
            dumx = ddot(nat3,arthog(1,i),1,arthog(1,i),1)
            if (dumx.lt.dumr) then
               dumr = dumx
               idum = i
            endif
         enddo
         do j = 1 , nat3
            arthog(j,idum) = arthog(j,6)
            arthog(j,6) = 0.0d0
         enddo
      endif
c
c     Now normalise all translational and rotational modes.
c
      do 160 i = 1 , ntrro
         dumx = ddot(nat3,arthog(1,i),1,arthog(1,i),1)
         if (dumx.gt.cutoff) then
            dumx = done/dsqrt(dumx)
            call dscal(nat3,dumx,arthog(1,i),1)
         else
            call vclr(arthog(1,i),1,nat3)
         endif
 160  continue
c
c     construct nat3-ntrro other orthogonal vectors.
c
      ntrrop = ntrro + 1
      nvib = nat3 - ntrro
c
      ind = ntrro
      do 190 i = 1 , nat3
         icycle = 0
         call vclr(trialv,1,nat3)
         trialv(i) = done
c
c        Orthonormalise using repeated modified 
c        Gramm-Schmidt (see e.g. Golub and van Loan,
c        "Matrix computations")
c
 175     do 170 k = 1 , ind
            dumx = -ddot(nat3,arthog(1,k),1,trialv,1)
            call daxpy(nat3,dumx,arthog(1,k),1,trialv,1)
 170     continue
         icycle = icycle + 1
         dumx = ddot(nat3,trialv,1,trialv,1)
         if (dumx.ge.cutoff) then
            dumx = done/dsqrt(dumx)
            do j = 1 , nat3
               trialv(j) = dumx*trialv(j)
            enddo
            if (dumx.le.0.5d0.and.icycle.le.2) goto 175
            ind = ind + 1
            do 180 j = 1 , nat3
               arthog(j,ind) = trialv(j)
 180        continue
            if (ind.eq.nat3) go to 200
         end if
 190  continue
c
c     transform force constant matrix to these vibrational coords.
c
 200  indvv = 0
      do 230 j = 1 , nat3
c     pluck the j-th column from ffx.
         call dcopy(j,ffx(ia(j)+1),1,trialv,1)
         do 210 i = j , nat3
            ind = ia(i) + j
            trialv(i) = ffx(ind)
 210     continue
c     loop over rows.
         do 220 i = ntrrop , nat3
c     contract one element.
c     pack into output matrix.
            dumx = ddot(nat3,arthog(1,i),1,trialv,1)
            indvv = indvv + 1
            vv(indvv) = dumx
 220     continue
 230  continue
c     transform the other suffix, and pack back into ffx.
      ind = 0
      do 260 i = ntrrop , nat3
         jlim = i - ntrrop + 1
c     contract one element.
         do 250 j = 1 , jlim
            dumx = 0.0d0
            do 240 k = 1 , nat3
               jk = j + nvib*(k-1)
               dumx = dumx + arthog(k,i)*vv(jk)
 240        continue
c     pack element back into ffx (now dimension is nvib*nvib).
            ind = ind + 1
            ffx(ind) = dumx
 250     continue
 260  continue
c
c     diagonalise and get the eigenvalues lambda
c     lambda=4*pi**2*nu**2
c     where nu=vibrational frequency.
c
chvd  call gldiag(nvib,nvib,nvib,ffx,vecout,eig,vv,ia,2)
      th=1.0d-15
      call ngdiag(ffx,vv,eig,iky,nvib,nvib,0,th)
c
c     convert nu to cm-1 and print out.
c
      nimag = 0
      do 270 i = 1 , nvib
         dumx = eig(i)*factor
         if (dumx.lt.0.0d0) then
            nimag = nimag + 1
            eig(i) = -dsqrt(-dumx)
         else
            eig(i) = dsqrt(dumx)
         end if
 270  continue
c
      if (nimag.gt.0) write (iwr,6030) nimag
c
c     mass conversion factors for normal coordinates
      do 280 i = 1 , natoms
         atmass(i) = done/dsqrt(atmass(i))
 280  continue
      ind = 0
      indout = 0
      do 320 i = 1 , nvib
         dumy = 0.0d0
         do 300 k = 1 , nat3
            dumx = 0.0d0
            do 290 j = 1 , nvib
               dumx = dumx + arthog(k,ntrro+j)*vv(ind+j)
 290        continue
            kat = (k-1)/3 + 1
            dumx = dumx*atmass(kat)
            dumy = dumy + dumx**2
            trialv(k) = dumx
 300     continue
         dumy = done/dsqrt(dumy)
         do 310 k = 1 , nat3
            vecout(indout+k) = dumy*trialv(k)
            dumx = vecout(indout+k)
c           kk = indout + k
 310     continue
         indout = indout + nat3
         ind = ind + nvib
 320  continue
c
c
c     write out values
      mn = nvib*nat3
      call norout(vecout,eig,mn,nvib,iwr)
c
c
c     compute some thermochemical quantities.
c
      call dscal(nvib,slight,eig,1)
      do 330 i = 1 , natoms
         atmass(i) = 1.0d0/atmass(i)**2
 330  continue
      call thermo(natoms,ia,c,multip,atmass,eig(nimag+1),nimag,
     +            phycon,iwr)
c
c
      return
 6010 format (/10x,42('=')/10x,
     +        'principal second moments of inertia (a.u.)'/10x,42('=')/)
 6020 format (/11x,3f12.4/)
 6030 format (/' ****** ',i2,' imaginary frequencies (negative signs)',
     +        ' ******')
      end
      subroutine vibrat(oskip)
      implicit REAL  (a-h,p-w),integer   (i-n),logical    (o)
      implicit character *8 (z),character *1 (x)
      implicit character *4 (y)
INCLUDE(common/sizes)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/symtry)
INCLUDE(common/runopt)
      common/junk/isoc(1)
c
c     ----- read in table  atoms vs. symmetry -----
c
      dimension oskip(*)
      nav = lenwrd()
      call readi(isoc,nw196(6)*nav,ibl196(6),idaf)
      do 20 iat = 1 , nat
         oskip(iat) = .true.
 20   continue
      do 50 iat = 1 , nat
         do 40 it = 1 , nt
            if (isoc(iat+ilisoc(it)).gt.iat) go to 50
 40      continue
         oskip(iat) = .false.
 50   continue
c
c...  atoms fixed in input
c
      do j=1,nat
         if (zopti(j).eq.'no') oskip(j) = .true.
      end do  
c
      return
      end
      subroutine zmmodg(bl,alpha,beta,ipz,jpz,del)
      implicit REAL  (a-h,o-z)
      dimension bl(*),alpha(*),beta(*)
      go to (20,30,40) , jpz
 20   bl(ipz) = bl(ipz) + del
      go to 50
 30   alpha(ipz) = alpha(ipz) + del
      go to 50
 40   beta(ipz) = beta(ipz) + del
 50   return
      end
      subroutine anamom(q)
c
c  ------------------------------------------------
c    analysis of moment of inertia etc
c  ------------------------------------------------
c
      implicit REAL  (a-h,o-z)
      logical oprn
INCLUDE(common/sizes)
INCLUDE(common/gmempara)
INCLUDE(common/infoa)
INCLUDE(common/iofile)
INCLUDE(common/restar)
      character*7 fnm
      character*6 snm
      data fnm,snm/'optim.m','anamom'/
      dimension q(*)
c
c  loop over isotopic substitution patterns
c
c     print control
      oprn = nprint.ne.-5
c
      nmv = mass_numvec()
      length = nat *4
      i10 = igmem_alloc_inf(length,fnm,snm,'i10',IGMEM_DEBUG)

      do imv=1,nmv
         
         if(nmv.ne.1)then
             write(iwr,100)imv
 100         format(/,1x,'Considering set of nuclear masses no.',i4,/)
         endif
         call rotcon(q(i10), q(nat+i10), q(2*nat+i10), q(3*nat+i10), 
     +               nat,oprn,imv)
      enddo
c
      call gmem_free_inf(i10,fnm,snm,'i10')
c
      return
      end
      subroutine rotcon(x,y,z,w,natom,lprn,imv)
      implicit REAL  (a-h,o-z)
      logical lprn
      character*8 ztmp, zmass_nuclab
INCLUDE(common/sizes)
c
c    works out rotational constants
c
      common/vib104/para,wave,const,cycl,conv
c
INCLUDE(common/infoa)
INCLUDE(common/common)
INCLUDE(common/iofile)
INCLUDE(common/phycon)
c
      dimension x(natom),y(natom),z(natom),w(natom)
c
c     data ph,bk,avn / 6.626176d+00 , 1.380662d+00 , 6.022045d+00 /
c     data cl,temp / 2.99792458d+00 , 300.0d+00 /
c     data pi / 3.1415926536d+00 /
      data temp / 300.0d+00 /
c
c     data he,ev / 4.359813653d+00 , 1.6021892d+00 /
c     data aln / 2.3025850930d+00 /
c     data nred / 10 /
c
      pi  = dacos(-1.0d0)
      ph  = toang(4)*1.0d34
      bk  = toang(10)*1.0d23
      avn = toang(5)*1.0d-23
      cl  = toang(9)*1.0d-10
c   physical constants
      para = 1.0d+00/avn
      wave = 1.0d+04*dsqrt(avn)/(2.0d+00*pi*cl)
      const = 1.0d+02*(ph*avn)/(8.0d+00*pi*pi*cl)
      cycl = 1.0d+06*(ph*avn)/(8.0d+00*pi*pi)
      conv = 1.0d-01*(ph*cl)/(2.0d+00*bk*temp)
c
c
      natom = nat
      if(lprn) write (iwr,6010)
      do 20 i = 1 , natom
         x(i) = c(1,i)
         y(i) = c(2,i)
         z(i) = c(3,i)
         w(i) = amass_get(imv,i)
         ztmp = zmass_nuclab(imv,i)
         if(lprn) write (iwr,6020) i , x(i) , y(i) , z(i) , ztmp, w(i)
 20   continue
      write (iwr,6030)
      do 30 i = 1 , natom
         x(i) = x(i)*toang(1)
         y(i) = y(i)*toang(1)
         z(i) = z(i)*toang(1)
         ztmp = zmass_nuclab(imv,i)
         write (iwr,6020) i , x(i) , y(i) , z(i) , ztmp, w(i)
 30   continue
      call prmomc(x,y,z,w,natom,lprn,iwr)
      return
 6010 format (//
     +  30x,'************************'/
     +  30x,'molecular geometry (a.u.)'/
     +  30x,'************************'//
     +  5x,'atom',13x,' x',18x,' y',18x,' z',13x,
     +  'nucleus  atomic weight'/)
 6020 format (2x,i7,5x,3f20.10,2x,a8,f15.10)
 6030 format (//
     +  30x,'*****************************'/
     +  30x,'molecular geometry (angstrom)'/
     +  30x,'*****************************'//
     +  5x,'atom',13x,' x',18x,' y',18x,' z',13x,
     +  'nucleus  atomic weight'/)
      end
      subroutine prmomc(x,y,z,w,natom,lprn,iwr)
      implicit REAL  (a-h,o-z)
      logical lprn
      dimension t(6),pr(3),eg(3,3),wrk(3)
      dimension x(natom),y(natom),z(natom),w(natom)
      common/vib104/para,wave,const,cycl,conv
      data zero / 0.0d+00 /
c
c   the calculation of center of mass
      sumw = zero
      sumwx = zero
      sumwy = zero
      sumwz = zero
      do 20 i = 1 , natom
         sumw = sumw + w(i)
         sumwx = sumwx + w(i)*x(i)
         sumwy = sumwy + w(i)*y(i)
         sumwz = sumwz + w(i)*z(i)
 20   continue
      cmx = sumwx/sumw
      cmy = sumwy/sumw
      cmz = sumwz/sumw
      if(lprn) write (iwr,6010) cmx , cmy , cmz
c   the cartesian coordinates w.r.t. center of mass
      if(lprn) write (iwr,6020)
      do 30 i = 1 , natom
         x(i) = x(i) - cmx
         y(i) = y(i) - cmy
         z(i) = z(i) - cmz
         if(lprn) write (iwr,6030) i , x(i) , y(i) , z(i) , w(i)
 30   continue
c
c   the calculation of inertia tensor
      do 40 i = 1 , 6
         t(i) = zero
 40   continue
      do 50 i = 1 , natom
         t(1) = t(1) + w(i)*(y(i)**2+z(i)**2)
         t(3) = t(3) + w(i)*(z(i)**2+x(i)**2)
         t(6) = t(6) + w(i)*(x(i)**2+y(i)**2)
         t(2) = t(2) - w(i)*x(i)*y(i)
         t(4) = t(4) - w(i)*z(i)*x(i)
         t(5) = t(5) - w(i)*y(i)*z(i)
 50   continue
c
      if(lprn) then
       write (iwr,6040)
       call prtris(t,3,6)
      endif
c
c   the calculation of principal moments of inertia
c
      i = 0
      do 70 j = 1 , 3
         do 60 k = 1 , j
            i = i + 1
            eg(j,k) = t(i)
            eg(k,j) = t(i)
 60      continue
 70   continue
      ifail = 0
      call f02abf(eg,3,3,pr,eg,3,wrk,ifail)
      if(lprn) write (iwr,6050)
      do 80 i = 1 , 3
         if (dabs(pr(i)).lt.1.0d-8) then
            pr(i) = 0.0d0
            pa = 0.0d0
            pb = 0.0d0
            pc = 0.0d0
         else
            pa = pr(i)*para
            pb = const/pr(i)
            pc = cycl/pr(i)
         end if
         if(lprn) write (iwr,6060) i , pr(i) , pa , pb , pc
 80   continue
      if(lprn) then
       write (iwr,6070)
       call prsqm(eg,3,3,3,iwr)
      endif
      return
 6010 format (/30x,'**************'/
     +         30x,'center of mass'/
     +         30x,'**************'//
     +       18x,' cmx',11x,' cmy',11x,' cmz'//12x,3(5x,f10.7)/)
 6020 format (/20x,'*******************************************'/
     +         20x,'cartesian coordinates w.r.t. center of mass'/
     +         20x,'*******************************************'//
     + 5x,' no.',11x,' x',13x,' y',13x,' z',13x,'weight'/)
 6030 format (2x,i7,5x,4f15.7)
 6040 format (/20x,'**************'/
     +         20x,'inertia tensor'/
     +         20x,'**************'/)
 6050 format (/30x,'****************************'/
     +         30x,'principal moments of inertia'/
     +         30x,'****************************'//
     +           2x,' no.',7x,
     +        ' in amu.a+2',7x,' in g.cm+2',8x,' in cm-1',10x,
     +        ' in mhz'/31x,' (*d+39)'/)
 6060 format (2x,i2,3x,4e18.5)
 6070 format (/ 20x,'*****************************'/
     +          20x,'eigenvector of inertia tensor'/
     +          20x,'*****************************')
      end
c
c-----------------------------------------------------------------------
c
      logical function omol_is_linear(pmom)
      implicit none
c
c     This function establishes whether a molecule is linear. 
c     It provides a single unified way of doing this based on the
c     detected symmetry and the moments of inertia. Most importantly
c     it ensures a single criterion to be used with the moments of
c     inertia.
c
c     Parameter:
c
      REAL linearity_tolerance ! cutoff for linear molecules 
      parameter(linearity_tolerance=1.0d-1)
c
c     Input:
c
      REAL pmom(3) ! The moments of inertia
c
c     Local:
c
      REAL sn
c
c     Functions:
c 
      REAL symnum   ! function checking linearity against point group
      logical oline ! is the molecule linear?
c
      sn = symnum(oline)
      if (.not.oline) then
         oline = (dabs(pmom(1)).lt.linearity_tolerance).and.
     &           (dabs(pmom(2)-pmom(3)).lt.linearity_tolerance)
      endif
      omol_is_linear = oline
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine ver_optim(s,r,d)
      character*80 source
      character*30 revision
      character*60 date
      character s*(*), r*(*), d*(*)
      data source /
     +     "$Source: /c/qcg/cvs/psh/GAMESS-UK/m4/optim.m,v $
     +     "/
      data revision /"$Revision: 6231 $"/
      data date /"$Date: 2011-03-29 16:16:48 +0200 (Tue, 29 Mar 2011) $
     +     "/
      s=source(9:)
      r=revision(11:)
      d=date(7:)
      return
      end
